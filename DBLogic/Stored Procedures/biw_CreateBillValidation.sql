-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_CreateBillValidation] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_CreateBillValidation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_CreateBillValidation].'
	drop procedure dbo.[biw_CreateBillValidation]
end
print '**** Creating procedure dbo.[biw_CreateBillValidation]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go
SET CONCAT_NULL_YIELDS_NULL OFF
go 

create procedure dbo.[biw_CreateBillValidation]
				@pnUserIdentityId	int,		-- Mandatory
				@psCulture		nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@ptXMLSelectedWipItems	ntext,		-- Mandatory - Selected WIP items.
				@pbSingleBill		bit		= 1,
				@pbDebug		bit		= 0
as
-- PROCEDURE :	biw_CreateBillValidation
-- VERSION :	7
-- DESCRIPTION:	A procedure to validate WIP items for billing purposes.
--
-- COPYRIGHT:	Copyright 1993 - 2010 CPA Global Software Solutions Australia Pty Limited
-- MODIFICATION
-- Date		Who	RFC		Version Description
-- -----------	-------	------		------- ----------------------------------------------- 
-- 01/04/2010	KR	RFC8306		1	Procedure created
-- 01/09/2010	KR	RFC9080		2	Fixes issues with the error message when the debor is null
-- 18/10/2011	KR	RFC10844	3	Return IRN as well for display purposes.
-- 06/02/2013	vql	RFC12904	4	Remove multi-debtor single bill restriction
-- 20/12/2013	vql	RFC28150	5	Validate selections on WIP Overview window involving allocated debtors
-- 09/06/2015	vql	RFC28051	6	Do not allow debtor only wip for different debtors
-- 24/10/2017	AK	R72645	        7	Make compatible with case sensitive server with case insensitive database.

Set nocount on
declare @nErrorCode int
declare @nDebtorKey int
declare @nTransactionKey int
declare @nWipSequenceKey int
declare @sInternalCaseType nchar(1)
declare @tblSelectedWipItems table (DEBTORKEY int, CASEKEY int, PREVENTBILLING bit, ALLOCATEDDEBTORKEY int)
declare @tblValidationErrors table (ERRORCODE nvarchar(10) collate database_default null, ERRORMESSAGE nvarchar(256) collate database_default null, DEBTORKEY int, CASEKEY int, IRN nvarchar(60) )
declare @sSQLString nvarchar(2000)
declare @sRowPattern nvarchar(256)
declare @nSelectedWipItemRowCount int
declare @bWIPSplitDebtor bit
declare @nNumberOfDebtors int
Declare @idoc int 

Set @nErrorCode = 0

If (@nErrorCode = 0)
Begin

	if (@pbDebug = 1)
		select '-- get site control values'
	
	Set @sSQLString = "
	Select @sInternalCaseType = COLCHARACTER
	From SITECONTROL
	Where CONTROLID = 'Case Type Internal'"
	
	exec	@nErrorCode = sp_executesql @sSQLString,
		N'@sInternalCaseType	nchar(1) 			OUTPUT',
		@sInternalCaseType = @sInternalCaseType			OUTPUT
End

If (@nErrorCode = 0)
Begin
	Set @sSQLString = "
	Select @bWIPSplitDebtor = COLBOOLEAN
	From SITECONTROL
	Where CONTROLID like 'WIP Split Multi Debtor'"
	
	exec	@nErrorCode = sp_executesql @sSQLString,
		N'@bWIPSplitDebtor	bit 			OUTPUT',
		@bWIPSplitDebtor = @bWIPSplitDebtor			OUTPUT
End

If (datalength(@ptXMLSelectedWipItems) > 0)
and @nErrorCode = 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLSelectedWipItems

	-- 1) Retrieve the selected wip items using element-centric mapping (implement 
	--    Case Insensitive searching)
	
	Set @sRowPattern = "//biw_BillValidation/OpenItemGroup/OpenItem"
		Insert into @tblSelectedWipItems(DEBTORKEY,CASEKEY,ALLOCATEDDEBTORKEY)
		Select	*
		from	OPENXML (@idoc, @sRowPattern, 2)
		WITH (
		      DebtorKey			int		'DebtorKey/text()',
		      CaseKey			int		'CaseKey/text()',
		      AllocatedDebtorKey	int		'AllocatedDebtorKey/text()'
		     )
		Set @nSelectedWipItemRowCount = @@RowCount
	
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	--check if the Case Status of the bill prevents billing and throw and error message and de-select the item in the WIP Overview
	Update  T Set T.PREVENTBILLING = 1 
	from @tblSelectedWipItems T
	Join CASES C on (C.CASEID = T.CASEKEY)
	join STATUS CS on (C.STATUSCODE = CS.STATUSCODE and CS.PREVENTBILLING = 1)
	
	If exists( Select * from @tblSelectedWipItems where PREVENTBILLING = 1 )
	Begin
		Insert into @tblValidationErrors(ERRORCODE, ERRORMESSAGE, DEBTORKEY, CASEKEY, IRN)
		Select 'AC113', 'Cannot be billed because the status of the case does not allow this type of financial transaction.',
			DEBTORKEY, CASEKEY, C.IRN 
			from @tblSelectedWipItems  T
			Join CASES C on (C.CASEID = T.CASEKEY ) 
			where PREVENTBILLING = 1
	End
	
	If exists( Select * from @tblSelectedWipItems where DEBTORKEY is null )
	Begin
		--Select * from @tblSelectedWipItems where DEBTORKEY is null
		Insert into @tblValidationErrors(ERRORCODE, ERRORMESSAGE, DEBTORKEY, CASEKEY, IRN)
		Select 'AC138', 'Cannot be billed because the case has no debtors.',
			DEBTORKEY, CASEKEY, C.IRN 
			from @tblSelectedWipItems T
			Join CASES C on (C.CASEID = T.CASEKEY)
			where DEBTORKEY is null
	End
			
	
	If ( @pbSingleBill = 1)	
	Begin
		-- check if there is more than one debtor involved.  if so, throw an error message and stop billing process
		If (( Select count(distinct DEBTORKEY)
			from @tblSelectedWipItems 
			where CASEKEY is null ) > 1)
		Begin
			Insert into @tblValidationErrors(ERRORCODE, ERRORMESSAGE)
			values('AC114', 'This is not a valid selection.  Only a single Debtor may be selected.  Please correct the data and re-submit.')
		End	

		-- check if both case related and debtor only wip items are selected.  if so, throw and error message and stop the billing process.
		if exists (select *
			from  @tblSelectedWipItems
			Where CASEKEY is not null)
		Begin
			if exists (select *
			from @tblSelectedWipItems
			Where CASEKEY is null)
			Begin
				Insert into @tblValidationErrors(ERRORCODE, ERRORMESSAGE)
				values('AC115', 'This is not a valid selection.  Either Case(s) or a Debtor may be selected, but not both.  Please correct the data and re-submit.')
			End
		End
		
		-- check if a combination of both internal and external items have been cases have been selected.  If so, throw an error message.
		if (@sInternalCaseType is not null or @sInternalCaseType != '')
		Begin
			if exists (select *
			from @tblSelectedWipItems T
			Join CASES C on (C.CASEID = T.CASEKEY and C.CASETYPE = @sInternalCaseType ))
			Begin
				if exists (select *
				from  @tblSelectedWipItems T
				Join CASES C on (C.CASEID = T.CASEKEY and C.CASETYPE != @sInternalCaseType ))
				Begin
					Insert into @tblValidationErrors(ERRORCODE, ERRORMESSAGE)
					values('AC116', 'This is not a valid selection.  A combination of internal and external Cases was selected.  Please correct the data and re-submit.')
				End
			End
		End
		
		-- check if debtor allocated WIP is included in the selection, the WIP must be allocated to the same debtor.
		if (@bWIPSplitDebtor = 1)
		begin
			select @nNumberOfDebtors = count(distinct ALLOCATEDDEBTORKEY)
			from @tblSelectedWipItems T
			where ALLOCATEDDEBTORKEY is not null
						
			if (@nNumberOfDebtors > 1)
			begin
				Insert into @tblValidationErrors(ERRORCODE, ERRORMESSAGE)
				values('AC219', 'This is not a valid selection. If debtor-allocated WIP is included in the selection, it cannot be allocated to different debtors.')
			end
			
			If ( ( select count(distinct CN.NAMENO)
					from @tblSelectedWipItems T
					Join CASENAME CN on (T.CASEKEY = CN.CASEID and CN.NAMETYPE = 'D')
					Where CN.EXPIRYDATE is null ) > 1)
			Begin
				Insert into @tblValidationErrors(ERRORCODE, ERRORMESSAGE)
				values('AC114', 'This is not a valid selection.  Only a single Debtor may be selected.  Please correct the data and re-submit.')
			End			
		end
	End
		
	Select ERRORCODE as ErrorCode, ERRORMESSAGE as ErrorMessage, IRN as CaseReference from @tblValidationErrors	
	
End


return @nErrorCode
go

grant execute on dbo.[biw_CreateBillValidation]  to public
go
