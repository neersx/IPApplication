-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_GetDebitNotes] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_GetDebitNotes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_GetDebitNotes].'
	drop procedure dbo.[biw_GetDebitNotes]
end
print '**** Creating procedure dbo.[biw_GetDebitNotes]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[biw_GetDebitNotes]
				@pnUserIdentityId		int,		-- Mandatory
				@psCulture				nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@pnItemEntityNo		int,
				@pnItemTransNo		int,
				@psMergeXMLKeys		nvarchar(max) = null
				
as
-- PROCEDURE :	biw_GetDebitNotes
-- VERSION :	7
-- DESCRIPTION:	A procedure that returns all of the debit items from an open item.
--
-- COPYRIGHT:	Copyright 1993 - 2012 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC		Version Description
-- -----------	-------	---------------	------- ----------------------------------------------- 
-- 22/10/2009	AT	RFC3605		1	Procedure created
-- 14/05/2010	AT	RFC9092		2	Return Local Value instead of Local Balance.
-- 08/12/2010	AT	RFC9915		3	Supress return of available credits if raising a credit note.
-- 29/04/2011	AT	RFC7956		4	Process merging items to return all applicable credits.
-- 11/07/2012	AT	RFC12466	5	Return ForeignTaxAmt.
-- 02 Nov 2015	vql	R53910		6	Adjust formatted names logic (DR-15543).
-- 27 May 2019  MS      DR45655         7       Added columns ForeignTaxableAmount, ForeignTaxAmount and Currency in OpenItemTax resultset

set nocount on

Declare		@ErrorCode	int
Declare		@nRowCount	int
Declare		@sSQLString	nvarchar(4000)

Set @ErrorCode = 0

If @ErrorCode = 0
Begin

	Set @sSQLString = "select 
	D.NAMENO as 'DebtorNameNo', 
	dbo.fn_FormatNameUsingNameNo(D.NAMENO, null) as 'DebtorName',
	O.OPENITEMNO as 'OpenItemNo',
	O.BILLPERCENTAGE as 'BillPercentage',
	O.STATUS as 'Status',
	O.LOCALVALUE as 'LocalValue',
	O.LOCALBALANCE AS 'LocalBalance',
	O.CURRENCY as 'Currency',
	O.FOREIGNVALUE as 'ForeignValue',
	O.FOREIGNBALANCE as 'ForeignBalance',
	O.EXCHRATE as 'ExchRate',
	AC.TotalCreditBalance as 'CreditsAvailable',
	O.BILLPRINTEDFLAG as 'PrintedFlag',
	O.LOCALORIGTAKENUP as 'LocalTakenUp',
	O.FOREIGNORIGTAKENUP as 'ForeignTakenUp',
	O.EXCHVARIANCE as 'ExchVariance',
	O.FOREIGNTAXAMT as 'ForeignTaxAmt',
	O.LOGDATETIMESTAMP as 'LogDateTimeStamp'
	From OPENITEM O
	Join NAME D on (D.NAMENO = O.ACCTDEBTORNO)
	Left Join (SELECT 
		sum(CASE WHEN OIC.CASEID IS NULL THEN OICRED.LOCALBALANCE ELSE OIC.LOCALBALANCE END) * -1 TotalCreditBalance, 
		sum(CASE WHEN OIC.CASEID IS NULL THEN OICRED.LOCALVALUE ELSE OIC.LOCALVALUE END) * -1 as TotalCreditValue,
		OICRED.ACCTENTITYNO, OICRED.ACCTDEBTORNO
		From OPENITEM OI
		Join OPENITEM OICRED on (OICRED.ACCTENTITYNO = OI.ACCTENTITYNO
					and OICRED.ACCTDEBTORNO = OI.ACCTDEBTORNO)
		Join DEBTOR_ITEM_TYPE DIT ON (DIT.ITEM_TYPE_ID = OICRED.ITEMTYPE)
		Left join OPENITEMCASE OIC ON ( OICRED.ITEMENTITYNO = OIC.ITEMENTITYNO and
						  OICRED.ITEMTRANSNO = OIC.ITEMTRANSNO and
						  OICRED.ACCTENTITYNO = OIC.ACCTENTITYNO and
						  OICRED.ACCTDEBTORNO = OIC.ACCTDEBTORNO
						  )
		WHERE OI.ITEMENTITYNO = @pnItemEntityNo
		and OI.ITEMTRANSNO = @pnItemTransNo
		and DIT.TAKEUPONBILL = 1
		and OICRED.STATUS NOT IN (0, 2, 9) -- not draft, locked or rev
		and (OIC.CASEID IS NULL 
			or OIC.CASEID IN (
				SELECT DISTINCT WIP.CASEID 
				FROM BILLEDITEM BI
				JOIN WORKINPROGRESS WIP on (WIP.ENTITYNO = BI.WIPENTITYNO
							and WIP.TRANSNO = BI.WIPTRANSNO
							and WIP.WIPSEQNO = BI.WIPSEQNO)
				WHERE BI.ITEMENTITYNO = @pnItemEntityNo
				and BI.ITEMTRANSNO = @pnItemTransNo)
			)
		GROUP BY OICRED.ACCTENTITYNO, OICRED.ACCTDEBTORNO) as AC on (AC.ACCTENTITYNO = O.ACCTENTITYNO and AC.ACCTDEBTORNO = O.ACCTDEBTORNO)
	WHERE ITEMENTITYNO = @pnItemEntityNo
	AND ITEMTRANSNO = @pnItemTransNo
	order by O.OPENITEMNO
	"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnItemTransNo	int,
				  @pnItemEntityNo	int',
				  @pnItemTransNo=@pnItemTransNo,
				  @pnItemEntityNo=@pnItemEntityNo
End

-- Don't return tax information if merging bills.
If @ErrorCode = 0 and @psMergeXMLKeys is null
Begin
	Set @sSQLString  = "select
		O.OPENITEMNO as 'OpenItemNo',
		OIT.ACCTDEBTORNO as 'DebtorNameNo',
		OIT.TAXCODE as 'TaxCode',
		T.DESCRIPTION as 'TaxDescription',
		OIT.TAXRATE as 'TaxRate',
		OIT.TAXABLEAMOUNT as 'TaxableAmount',
		OIT.TAXAMOUNT as 'TaxAmount',
                OIT.FOREIGNTAXABLEAMOUNT as 'ForeignTaxableAmount',
                OIT.FOREIGNTAXAMOUNT as 'ForeignTaxAmount',
                OIT.CURRENCY as 'Currency'
		From OPENITEMTAX OIT
		join OPENITEM O on (OIT.ITEMENTITYNO = O.ITEMENTITYNO
							and OIT.ITEMTRANSNO = O.ITEMTRANSNO
							and OIT.ACCTENTITYNO = O.ACCTENTITYNO
							and OIT.ACCTDEBTORNO = O.ACCTDEBTORNO)
		join TAXRATES T on (T.TAXCODE = OIT.TAXCODE)
		WHERE OIT.ITEMENTITYNO = @pnItemEntityNo
		AND OIT.ITEMTRANSNO = @pnItemTransNo"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnItemTransNo	int,
					  @pnItemEntityNo	int',
					  @pnItemTransNo=@pnItemTransNo,
					  @pnItemEntityNo=@pnItemEntityNo
End
Else if @ErrorCode = 0
Begin
	-- return empty rowset
	Select 1 where 1=0
End

-- Only return credits if its NOT a credit note.
If (@ErrorCode = 0 and
	not exists (select * from OPENITEM WHERE ITEMENTITYNO = @pnItemEntityNo AND ITEMTRANSNO = @pnItemTransNo AND ITEMTYPE IN (511,514)))
Begin
	exec @ErrorCode = biw_GetBillCredits @pnUserIdentityId = @pnUserIdentityId,
			@psCulture = @psCulture,
			@pbCalledFromCentura = @pbCalledFromCentura,
			@pnItemEntityNo	= @pnItemEntityNo,
			@pnItemTransNo = @pnItemTransNo,
			@psCaseKeyCSVList = null,
			@psDebtorKeyList = null,
			@psMergeXMLKeys = @psMergeXMLKeys
End

return @ErrorCode
go

grant execute on dbo.[biw_GetDebitNotes]  to public
go
