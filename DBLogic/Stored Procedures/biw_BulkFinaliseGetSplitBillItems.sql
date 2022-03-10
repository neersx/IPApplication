-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_BulkFinaliseGetSplitBillItems] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_BulkFinaliseGetSplitBillItems]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_BulkFinaliseGetSplitBillItems].'
	drop procedure dbo.[biw_BulkFinaliseGetSplitBillItems]
end
print '**** Creating procedure dbo.[biw_BulkFinaliseGetSplitBillItems]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go
SET CONCAT_NULL_YIELDS_NULL OFF
go 

create procedure dbo.[biw_BulkFinaliseGetSplitBillItems]
				@pnUserIdentityId	int,		-- Mandatory
				@psCulture		nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@ptXMLSelectedOpenItems	ntext,		-- Mandatory - Selected WIP items.
				@pbDebug		bit		= 0
as
-- PROCEDURE :	biw_BulkFinaliseGetSplitBillItems
-- VERSION :	3
-- DESCRIPTION:	A procedure that credits the selected bill.
--
-- COPYRIGHT:	Copyright 1993 - 2010 CPA Global Software Solutions Australia Pty Limited
-- MODIFICATION
-- Date		Who	RFC	Version	Description
-- -----------	-------	-------	------- ---------------------------------------------- 
-- 09/08/2010	DV	R110508	1	Procedure created
-- 02 Nov 2015	vql	R53910	2	Adjust formatted names logic (DR-15543).
-- 14 May 2018  MS      R74092  3       Return AccEntityNo in the resut set

Set nocount on
declare @nErrorCode int
declare @sBillCheckBeforeFinalise nchar(1)
declare @tblSelectedOpenItems table (ENTITYKEY int, TRANSACTIONKEY int, 
					OPENITEMNO nvarchar(24) collate database_default null)

declare @sSQLString nvarchar(2000)
declare @sRowPattern nvarchar(256)
declare @nSelectedOpenItemRowCount int
Declare @idoc int 

Declare @sOpenItemNo nvarchar(10)
declare @nEntityKey int
declare @nTransactionKey int

Set @nErrorCode = 0

If (datalength(@ptXMLSelectedOpenItems) > 0)
and @nErrorCode = 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLSelectedOpenItems

	-- 1) Retrieve the selected wip items using element-centric mapping (implement 
	--    Case Insensitive searching)
	
	Set @sRowPattern = "//biw_BulkFinaliseGetSplitBillItems/OpenItemGroup/OpenItem"
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
	
	SELECT O.ACCTDEBTORNO as DebtorKey, O.LOCALVALUE as BillAmount, O.ITEMENTITYNO as ItemEntityNo,
	O.ITEMTRANSNO as ItemTransNo, O.OPENITEMNO as OpenItemNo, 
	dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as DebtorName,
        O.ACCTENTITYNO as AcctEntityNo
	FROM OPENITEM O
	JOIN @tblSelectedOpenItems T on ( T.ENTITYKEY = O.ITEMENTITYNO
				  and T.TRANSACTIONKEY = O.ITEMTRANSNO				 
				  and O.STATUS = 0
				  and O.LOCKIDENTITYID is null
				  and O.ITEMTYPE in (510, 511))
        JOIN NAME N on (N.NAMENO = O.ACCTDEBTORNO)				  
	
End

return @nErrorCode
go

grant execute on dbo.[biw_BulkFinaliseGetSplitBillItems]  to public
go
