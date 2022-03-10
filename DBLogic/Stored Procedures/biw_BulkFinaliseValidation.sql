-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_BulkFinaliseValidation] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_BulkFinaliseValidation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_BulkFinaliseValidation].'
	drop procedure dbo.[biw_BulkFinaliseValidation]
end
print '**** Creating procedure dbo.[biw_BulkFinaliseValidation]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go
SET CONCAT_NULL_YIELDS_NULL OFF
go 

create procedure dbo.[biw_BulkFinaliseValidation]
				@pnUserIdentityId	int,		-- Mandatory
				@psCulture		nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@ptXMLSelectedOpenItems	ntext,		-- Mandatory - Selected WIP items.
				@pbDebug		bit		= 0
as
-- PROCEDURE :	biw_BulkFinaliseValidation
-- VERSION :	9
-- DESCRIPTION:	A procedure that credits the selected bill.
--
-- COPYRIGHT:	Copyright 1993 - 2010 CPA Global Software Solutions Australia Pty Limited
-- MODIFICATION
-- Date			Who		RFC			Version Description
-- -----------	-------	------		------- ----------------------------------------------- 
-- 09/08/2010		KR		RFC9087			1	Procedure created
-- 01/09/2010		KR		RFC9087			2	Added validation for already finalised items
-- 07/10/2010		KR		RFC100387		3	Added ItemDate to the select list for ValidationErrors
-- 01/11/2010		KR		RFC9909			4	Modified alert id AC137 to AC139
-- 09/02/2012		KR		RFC11656		5	ItemDate missing from @tblValidationErrors when AC121 error occurs
-- 07/11/2012		AK		RFC12544		6	Prevent finalize if bill date is future date
-- 12/11/2012		AK		RFC12544		7	Removed check to Prevent finalize if bill date is future date
-- 21/10/2014		MS		RFC13719		8	Removed BillCheckBeforeFinalisationLogic and AC119 check and moved it to code
-- 10/06/2015		KR		R44648			9	Added validation logic to prevent finalising if applied credit item is locked

Set nocount on
declare @nErrorCode int
declare @tblSelectedOpenItems table (ENTITYKEY int, TRANSACTIONKEY int, 
					OPENITEMNO nvarchar(24) collate database_default null)
declare @tblValidationErrors table (ERRORCODE nvarchar(10) collate database_default null, 
					ERRORMESSAGE nvarchar(500) collate database_default null, 
					ENTITYKEY int, 
					TRANSACTIONKEY int, 
					ITEMDATE datetime,
					OPENITEMNO nvarchar(24) collate database_default null,
					CONFIRM bit, 
					ERROR bit )

declare @tblOpenItemCaseList table (OPENITEMNO nvarchar(24) collate database_default null,
				    CASEKEY int, CASEREFERENCE nvarchar(60) collate database_default null)

declare @sSQLString nvarchar(2000)
declare @sRowPattern nvarchar(256)
declare @nSelectedOpenItemRowCount int
Declare @idoc int 

Declare @sOpenItemNo nvarchar(10)
declare @nEntityKey int
declare @nTransactionKey int


Set @nErrorCode = 0

	Begin Transaction

If (datalength(@ptXMLSelectedOpenItems) > 0)
and @nErrorCode = 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLSelectedOpenItems

	-- 1) Retrieve the selected wip items using element-centric mapping (implement 
	--    Case Insensitive searching)
	
	Set @sRowPattern = "//biw_BulkFinaliseValidation/OpenItemGroup/OpenItem"
		Insert into @tblSelectedOpenItems(ENTITYKEY,TRANSACTIONKEY, OPENITEMNO)
		Select	*
		from	OPENXML (@idoc, @sRowPattern, 2)
		WITH (
		      EntityKey			int		'EntityKey/text()',
		      TransactionKey		int		'TransactionKey/text()',
		      OpenItemNo		nvarchar(10)	'OpenItemKey/text()'
		     )
		Set @nSelectedOpenItemRowCount = @@RowCount
	
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	
	-- populate the case list of the open item
	
	DECLARE CursorSelectedOpenItems CURSOR READ_ONLY FORWARD_ONLY LOCAL FOR 
	SELECT ENTITYKEY,TRANSACTIONKEY, OPENITEMNO FROM @tblSelectedOpenItems 

	OPEN CursorSelectedOpenItems 
	FETCH NEXT FROM CursorSelectedOpenItems INTO @nEntityKey, @nTransactionKey, @sOpenItemNo 

	WHILE @@FETCH_STATUS <> -1 
	BEGIN 
		Insert into @tblOpenItemCaseList(OPENITEMNO, CASEKEY, CASEREFERENCE)
		SELECT OP.OPENITEMNO, W.CASEID, C.IRN 
		from WORKINPROGRESS W
		Join CASES C on (W.CASEID = C.CASEID)
		join BILLEDITEM BI on (BI.WIPENTITYNO = W.ENTITYNO  
				     and   BI.WIPTRANSNO = W.TRANSNO
				     and   BI.WIPSEQNO = W.WIPSEQNO)
		join OPENITEM OP on   (OP.ITEMENTITYNO = BI.ENTITYNO 
					 and OP.ITEMTRANSNO = BI.TRANSNO)
		where 
		OP.ITEMENTITYNO = @nEntityKey and OP.ITEMTRANSNO = @nTransactionKey and OP.OPENITEMNO = @sOpenItemNo
		and OP.ITEMTYPE in (510, 513)
		and W.CASEID is not null

	FETCH NEXT FROM CursorSelectedOpenItems INTO @nEntityKey, @nTransactionKey, @sOpenItemNo
	END 
	CLOSE CursorSelectedOpenItems 
	DEALLOCATE CursorSelectedOpenItems
	
	if exists(select * from OPENITEM O 
	Join @tblSelectedOpenItems T on (T.OPENITEMNO = O.OPENITEMNO 
					  and T.ENTITYKEY = O.ITEMENTITYNO
					  and T.TRANSACTIONKEY = O.ITEMTRANSNO)
	Where LOCKIDENTITYID is not null)
	Begin
		-- open item is locked and cannot be finalised.
		Insert into @tblValidationErrors(ERRORCODE, ERRORMESSAGE, ERROR, CONFIRM, 
						ENTITYKEY, TRANSACTIONKEY,OPENITEMNO, ITEMDATE)
		Select 'AC120', 'Item is currently locked by another user.', 1, 0,
			T.ENTITYKEY, T.TRANSACTIONKEY, T.OPENITEMNO, O.ITEMDATE
		From @tblSelectedOpenItems T
		Join OPENITEM O on (T.OPENITEMNO = O.OPENITEMNO 
				  and T.ENTITYKEY = O.ITEMENTITYNO
				  and T.TRANSACTIONKEY = O.ITEMTRANSNO
				  and O.LOCKIDENTITYID is not null)
	End
	
	if exists(select * from @tblSelectedOpenItems T
	where T.OPENITEMNO not in (select OPENITEMNO from OPENITEM))
	Begin
		-- open item is locked and cannot be finalised.
		Insert into @tblValidationErrors(ERRORCODE, ERRORMESSAGE, ERROR, CONFIRM, 
						ENTITYKEY, TRANSACTIONKEY,OPENITEMNO)
		Select distinct 'AC136', 'Open Item could not be found. Item has been modified or is already finalised.', 1, 0,
			T.ENTITYKEY, T.TRANSACTIONKEY, T.OPENITEMNO
		From @tblSelectedOpenItems T
		where T.OPENITEMNO not in (select OPENITEMNO from OPENITEM)
		
	End
	
	if exists(select * from OPENITEM O 
	Join @tblSelectedOpenItems T on (T.OPENITEMNO = O.OPENITEMNO 
					  and T.ENTITYKEY = O.ITEMENTITYNO
					  and T.TRANSACTIONKEY = O.ITEMTRANSNO)
	Where ITEMTYPE not in(510, 511) and LOCKIDENTITYID is null)
	Begin
		-- the bill has already been finalised
		Insert into @tblValidationErrors(ERRORCODE, ERRORMESSAGE, CONFIRM, ERROR, 
						ENTITYKEY, TRANSACTIONKEY, OPENITEMNO, ITEMDATE)
		Select 'AC139', 'The item selected is not a debit or credit note.', 0, 1,
				T.ENTITYKEY, T.TRANSACTIONKEY, T.OPENITEMNO, O.ITEMDATE
		From @tblSelectedOpenItems T
		Join OPENITEM O on (T.OPENITEMNO = O.OPENITEMNO 
				  and T.ENTITYKEY = O.ITEMENTITYNO
				  and T.TRANSACTIONKEY = O.ITEMTRANSNO
				  and O.ITEMTYPE not in(510, 511)
				  and O.LOCKIDENTITYID is null)
	End
	
	if exists(select * from OPENITEM O 
	Join @tblSelectedOpenItems T on (T.OPENITEMNO = O.OPENITEMNO 
					  and T.ENTITYKEY = O.ITEMENTITYNO
					  and T.TRANSACTIONKEY = O.ITEMTRANSNO)
	Where STATUS != 0 and LOCKIDENTITYID is null and ITEMTYPE in (510, 511))
	Begin
		-- the bill has already been finalised
		Insert into @tblValidationErrors(ERRORCODE, ERRORMESSAGE, CONFIRM, ERROR, 
						ENTITYKEY, TRANSACTIONKEY, OPENITEMNO, ITEMDATE)
		Select 'AC125', 'The item has already been finalised.', 0, 1,
				T.ENTITYKEY, T.TRANSACTIONKEY, T.OPENITEMNO, O.ITEMDATE
		From @tblSelectedOpenItems T
		Join OPENITEM O on (T.OPENITEMNO = O.OPENITEMNO 
				  and T.ENTITYKEY = O.ITEMENTITYNO
				  and T.TRANSACTIONKEY = O.ITEMTRANSNO
				  and O.STATUS != 0
				  and O.LOCKIDENTITYID is null 
				  and O.ITEMTYPE in (510, 511))
	End	
	If exists (select * from BILLEDCREDIT BC
			Join OPENITEM OI on (OI.ITEMENTITYNO = CRITEMENTITYNO
							and OI.ITEMTRANSNO = CRITEMTRANSNO
							and OI.ACCTENTITYNO = CRACCTENTITYNO
							and OI.ACCTDEBTORNO = CRACCTDEBTORNO)
			Join @tblSelectedOpenItems T on (T.OPENITEMNO = OI.OPENITEMNO 
						  and T.ENTITYKEY = OI.ITEMENTITYNO
						  and T.TRANSACTIONKEY = OI.ITEMTRANSNO)
			Where
			OI.LOCKIDENTITYID is not null)
	Begin
		Insert into @tblValidationErrors(ERRORCODE, ERRORMESSAGE, CONFIRM, ERROR, 
						ENTITYKEY, TRANSACTIONKEY, OPENITEMNO, ITEMDATE)
		Select 'AC221', 'One or more of the credit items choosen has been locked by another process and cannot be applied. Remove the credit item before proceeding.', 0, 1,
				T.ENTITYKEY, T.TRANSACTIONKEY, T.OPENITEMNO, O.ITEMDATE
		From @tblSelectedOpenItems T
		Join OPENITEM O on (T.OPENITEMNO = O.OPENITEMNO 
				  and T.ENTITYKEY = O.ITEMENTITYNO
				  and T.TRANSACTIONKEY = O.ITEMTRANSNO
				  and O.STATUS != 0
				  and O.LOCKIDENTITYID is not null)				  
		Join BILLEDCREDIT BC on (O.ITEMENTITYNO = CRITEMENTITYNO
					and O.ITEMTRANSNO = CRITEMTRANSNO
					and O.ACCTENTITYNO = CRACCTENTITYNO
					and O.ACCTDEBTORNO = CRACCTDEBTORNO)
	End

	
	Set @nErrorCode=@@Error	
	-- commit the transaction
	If (@nErrorCode = 0)
		commit transaction
	Else
		rollback transaction
	
	Select ERRORCODE as ErrorCode, ERRORMESSAGE as ErrorMessage, ERROR as IsError, CONFIRM as IsConfirmationRequired, 
	ENTITYKEY as EntityKey, TRANSACTIONKEY as TransactionKey, OPENITEMNO as OpenItemNo, ITEMDATE as ItemDate from @tblValidationErrors	
	
	Select distinct OPENITEMNO as OpenItemNo, CASEKEY as CaseKey, CASEREFERENCE as CaseReference from @tblOpenItemCaseList
End


return @nErrorCode
go

grant execute on dbo.[biw_BulkFinaliseValidation]  to public
go
