-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_CollectDataForBulkBilling] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_CollectDataForBulkBilling]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_CollectDataForBulkBilling].'
	drop procedure dbo.[biw_CollectDataForBulkBilling]
end
print '**** Creating procedure dbo.[biw_CollectDataForBulkBilling]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go
SET CONCAT_NULL_YIELDS_NULL OFF
go 

create procedure dbo.[biw_CollectDataForBulkBilling]
				@pnUserIdentityId	int,		-- Mandatory
				@psCulture		nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@ptXMLSelectedItems	ntext,		-- Mandatory - Selected items.
				@pbUseRenewalDebtor	bit		= 0,
				@pbDebug		bit		= 0
as
-- PROCEDURE :	biw_CollectDataForBulkBilling
-- VERSION :	4
-- DESCRIPTION:	A procedure to gather data required for bulk billing.
--
-- COPYRIGHT:	Copyright 1993 - 2010 CPA Global Software Solutions Australia Pty Limited
-- MODIFICATION
-- Date			Who	RFC	Version	Description
-- -----------		-------	------	-------	----------------------------------------------- 
-- 07/07/2010		KR	RFC8306	1	Procedure created
-- 02/08/2011		DV	R100508	2	Added Debtor Name and Case Ref to be returned
-- 21/09/2012		DL	R12763	3	Fix collation error by adding 'collate database_default' to character based columns in temp table definition.
-- 02 Nov 2015		vql	R53910	4	Adjust formatted names logic (DR-15543).


Set nocount on
declare @nErrorCode int
declare @nDebtorKey int
declare @sInternalCaseType nchar(1)
declare @tblSelectedItems table (
		DEBTORKEY int, 
		DEBTORNAME nvarchar(200) collate database_default, 
		CASEKEY int, 
		CASEREF nvarchar(30) collate database_default, 
		OWNERKEY int, 
		CONSOLIDATION int, 
		BILLPERCENTAGE int, 
		INTERNAL bit, 
		PREVENTBILLING bit)

declare @tblValidationErrors table (
		ERRORCODE nvarchar(10) collate database_default null, 
		ERRORMESSAGE nvarchar(256) collate database_default null, 
		DEBTORKEY int, 
		CASEKEY int )
declare @sSQLString nvarchar(2000)
declare @sRowPattern nvarchar(256)
declare @nSelectedItemRowCount int
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


If (datalength(@ptXMLSelectedItems) > 0 and @nErrorCode = 0)
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLSelectedItems

	-- 1) Retrieve the selected wip items using element-centric mapping (implement 
	--    Case Insensitive searching)
	
	Set @sRowPattern = "//biw_BulkBilling/SelectedItemGroup/SelectedItem"
		Insert into @tblSelectedItems(DEBTORKEY,CASEKEY)
		Select	*
		from	OPENXML (@idoc, @sRowPattern, 2)
		WITH (
		      DebtorKey			int		'DebtorKey/text()',
		      CaseKey			int		'CaseKey/text()'
		     )
		Set @nSelectedItemRowCount = @@RowCount
	
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	--check if the Case Status of the bill prevents billing and throw and error message and de-select the item in the WIP Overview
	Update  T Set T.PREVENTBILLING = 1 
	from @tblSelectedItems T
	Join CASES C on (C.CASEID = T.CASEKEY)
	join STATUS CS on (C.STATUSCODE = CS.STATUSCODE and CS.PREVENTBILLING = 1)
	SELECT @nErrorCode = @@ERROR
	
	If (@nErrorCode = 0)
	Begin
	
		If (@pbUseRenewalDebtor = 1)
		Begin
			UPDATE T
			SET DEBTORKEY = CND.NAMENO,
			BILLPERCENTAGE = CND.BILLPERCENTAGE
			FROM  @tblSelectedItems T
			JOIN CASENAME CND on (CND.CASEID = T.CASEKEY
			AND CND.NAMETYPE = 'Z'
			AND CND.SEQUENCE = (	SELECT MIN(CND2.SEQUENCE)
						FROM CASENAME CND2
						WHERE CND2.CASEID = CND.CASEID
						AND   CND2.NAMETYPE=CND.NAMETYPE) )
			SELECT @nErrorCode = @@ERROR
			
			
		End
		Else
		Begin
			If (@nErrorCode = 0)
			Begin
			
				UPDATE T
				SET 
				BILLPERCENTAGE = CND.BILLPERCENTAGE
				FROM  @tblSelectedItems T
				JOIN CASENAME CND on (CND.CASEID = T.CASEKEY
				AND CND.NAMETYPE = 'D'
				AND CND.SEQUENCE = (	SELECT MIN(CND2.SEQUENCE)
							FROM CASENAME CND2
							WHERE CND2.CASEID = CND.CASEID
							AND   CND2.NAMETYPE=CND.NAMETYPE) )
				where T.CASEKEY is not null
				
				UPDATE @tblSelectedItems
				SET BILLPERCENTAGE = 100
				where CASEKEY is null
				
				SELECT @nErrorCode = @@ERROR
				
			End						
		End
		
		If (@nErrorCode = 0)
		Begin	
			UPDATE T
			SET CONSOLIDATION = (SELECT DISTINCT IPN.CONSOLIDATION )
			FROM  
			@tblSelectedItems  T
			Join IPNAME IPN on (T.DEBTORKEY = IPN.NAMENO)
			
			SELECT @nErrorCode = @@ERROR
		End
		
		If (@nErrorCode = 0)
		Begin
			UPDATE T
			SET OWNERKEY = (SELECT DISTINCT CNO.NAMENO )
			FROM  
			@tblSelectedItems T
			Join CASENAME CNO on (CNO.CASEID = T.CASEKEY
			AND CNO.NAMETYPE = 'O'
			AND CNO.SEQUENCE = (	SELECT MIN(CNO2.SEQUENCE)
						FROM CASENAME CNO2
						WHERE CNO2.CASEID = CNO.CASEID
						AND   CNO2.NAMETYPE=CNO.NAMETYPE))
			SELECT @nErrorCode = @@ERROR
		End
	End
	
	
	
	Select SI.DEBTORKEY as DebtorKey, SI.CASEKEY as CaseKey, SI.OWNERKEY as OwnerKey, SI.CONSOLIDATION as Consolidation, 
	C.IRN as CaseRef, dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as DebtorName,
	SI.BILLPERCENTAGE as BillPercentage, SI.INTERNAL as Internal, SI.PREVENTBILLING as PreventBilling
	From @tblSelectedItems SI 
	Left JOIN CASES C on (C.CASEID = SI.CASEKEY) 
	Join NAME N on (N.NAMENO = SI.DEBTORKEY)
End


return @nErrorCode
go

grant execute on dbo.[biw_CollectDataForBulkBilling]  to public
go
