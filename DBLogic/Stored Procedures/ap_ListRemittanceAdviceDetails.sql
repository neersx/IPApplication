-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ap_ListRemittanceAdviceDetails
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ap_ListRemittanceAdviceDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ap_ListRemittanceAdviceDetails.'
	drop procedure dbo.ap_ListRemittanceAdviceDetails
end
print '**** Creating procedure dbo.ap_ListRemittanceAdviceDetails...'
print ''
go 

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ap_ListRemittanceAdviceDetails
(
	@pnRowCount			int output,
	@pnUserIdentityId		int		= null,	-- Included for use by .NET
	@psCulture			nvarchar(10)	= null, -- The language in which output is to be expressed
	@pbIsPaymentRun			bit		= 0,	-- Mandatory. Indicate if bulk payment run (1) or manual payment (0) occurred
	@pnPlanId			int		= null,	-- The PlanId of the bulk payment run.			
	@pnEntityNo			int,			-- The NameNo of Entity from which manual payment was made
	@pnTransNo			int,			-- The TransNo resulting from manual payment
	@prsTableName			nvarchar(254),
	@pbIsClientRefund		bit		= 0,	-- SQA17310 Mandatory.  Indicate that remittance is for client refund transaction.
	@pbDebug			bit		= 0
)
AS
-- PROCEDURE :	ap_ListRemittanceAdviceDetails
-- VERSION :	32
-- COPYRIGHT:	Copyright 1993 - 2012 CPA Software Solutions Australia Pty Limited
-- SCOPE:	AP
-- DESCRIPTION:	Get the Remittance Advice details of a payment.
--		The procedure is used by Manual and Bulk Payments in the Accounts Payable module.
-- CALLED BY :	Centura

-- MODIFICTIONS :
-- Date         Who  	SQA#	Version  	Change
-- ------------ ----	---- 	-------- 	------------------------------------------- 
-- 12/09/2003	SS	8783	1		Procedure created
-- 16/10/2003	SS	9182	2		Modified Order By clause in final SQL statement.
-- 29/10/2003	SS	9353	3		Modified to improve performance.
-- 07/11/2003	SS	9182	4		Added Group By clause to prevent duplicate rows.
-- 13/11/2003	SS	9353	5		Modified to use correct data types when executing SQL.
-- 14/11/2003	SS	9353	6		Removed Group By clause and modified Where clause for @pnPlanId as Group By suppresses valid rows.
-- 16/12/2003	SF	8839	7		reviewed logic for determining the Invoice amount and the Tax amount
-- 20/02/2004	SS	8857	8		Modified length of currency columns from 4 to 3.
-- 15/06/2003	CR	10059	9		Added Payment Date to the details returned.
-- 05/08/2004	AB	8035	10		Add collate database_default to temp table definitons.
-- 08/10/2004	CR	9584	11		Updated to cater for Credit Card Payments
-- 15/04/2005	CR	11272	12		include the return of the Invoice Description (long or short).
-- 18/04/2005	MB	11272	13		Put result into the supplied temporary table
-- 15/06/2005	AT	11426	14		Fixed bug with multiple fax numbers.
-- 20/06/2005	MB	11381	15		Change the way to output total amounts in words
-- 23/06/2005	MB	11381	16		Bug fixing
-- 03/11/2006	AT	13739	17		Remittance advice showing incorrect foreign amounts for bulk payments.
-- 30/10/2007	KR	15463	18		Remittance advice showing duplicate items for bulk payments.
-- 10/12/2007	CR	15722	19		Fixed where clause to only refer to PPD when printing a bulk payment.
-- 04/02/2009	AC	17283	20		Incorrect amounts shown for manual payments on payment advice
-- 09/09/2009	CR	8819	21		Exclude Unallocated Payments from Credit Card logic
-- 04/12/2009	CR	18241	22		Fix display of Invoice Amount and Tax.
-- 07/01/2010	DL	17310	23		List payment against debtor credit items.
-- 04/03/2010	DL	11346	24		Ensure the temp table @prsTableName is dropped before creating it
-- 13/04/2010	CR	18620	25		Added TotalTaxAmt and TotalInvoiceAmt calculations
-- 22/06/2011	DL	18909	26		Invoice and Tax amount for Credit Note should be negative
-- 26/08/2011	DL	19869	27		Incorrect Remittance Advice on Client Refund transaction
-- 16/05/2012	CR	16196	28		Consolidate System Defined Payment Methods - update references.
-- 15/04/2013	DV	R13270	29		Increase the length of nvarchar to 11 when casting or declaring integer
-- 30/08/2013	DL	21508	30		Extend PURCHSUPPLIERNAMECODE and SUPPLIERNAMECODE to 20 chars to match name.namecode
-- 21/07/2014	DL	R37381  31		Applying Credits as part of GBP manual payment returns an error in Accounts Payable
-- 02/11/2015	vql	R53910	32		Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode			int,		-- A variable to hold @@Error
	@nNameNo			int,		-- A variable to hold the NameNo of the Supplier
	@nTotalPaymentAmt		Decimal(11,2),
	@sTotalPaymentAmtInWords	nVarchar(254),
	@sMailingLabel			nVarchar(254),
	@sSQLString			nVarChar(4000),
	@sSelect			nVarChar(4000),
	@sFrom				nVarChar(4000),
	@sProcAmountToWords		nVarChar (128),
	@nIsClientRefund		bit

Set @nNameNo=null
Set @nTotalPaymentAmt=null
Set @sTotalPaymentAmtInWords=null
Set @sMailingLabel=null
Set @sSQLString=null

--Bulk Payment Run
If (@pbIsPaymentRun = 1) and (@pnPlanId is not null)
Begin
	Set @nErrorCode = 0
End
--Manual Payment
Else If (@pbIsPaymentRun = 0) and (@pnEntityNo is not null) and (@pnTransNo is not null)
Begin
	Set @nErrorCode = 0
End
Else
Begin
	Set @nErrorCode = -1
End


-- SQA11346 ensure the temp table name does not exist before creating it
If @nErrorCode = 0
Begin
	if exists(select 1 from tempdb.dbo.sysobjects where name = @prsTableName)
	Begin
		Set @sSQLString = "drop table " + @prsTableName
		exec @nErrorCode=sp_executesql @sSQLString

	End
End


If @nErrorCode = 0
Begin
	-- Create Temptable
	Set @sSQLString = "CREATE TABLE " + @prsTableName + " (
			ENTITYNO		int		not null,
			TRANSNO			int		not null,
			NAMENO			int		not null,
			SUPPLIER		nVarchar(254)	collate database_default not null,
			PAYEE			nVarchar(254)	collate database_default ,
			PAYMENTDATE		DateTime	not null,
			PAYMENTREF		nVarchar(30)	collate database_default ,
			PAYMENTDESC		nVarchar(254)	collate database_default ,
			PAYMETHOD		nVarchar(30)	collate database_default not null,
			PAYMENTCURRENCY		nVarchar(3)	collate database_default not null,
			TOTALPAYMENTAMT		Decimal(11,2)	not null,
			INVOICEDATE		DateTime,
			INVOICEREF		nVarchar(40)	collate database_default ,
			INVOICECURRENCY		nVarchar(3)	collate database_default ,
			INVOICEAMOUNT		Decimal(11,2),
			TAXAMOUNT		Decimal(11,2),
			PAYMENTAMOUNT		Decimal(11,2),
			TOTALPAYMENTAMTINWORDS	nVarchar(254)	collate database_default ,
			MAILINGLABEL		nVarchar(254)	collate database_default ,
			SUPPLIERNAMECODE	nVarchar(20)	collate database_default ,
			SUPPLIERFAXNO		nVarchar(65)	collate database_default ,
			SUPPLIERACCOUNTNUMBER	nVarchar(30)	collate database_default ,
			PURCHASESUPPLIER	nVarChar(254)	collate database_default ,
			PURCHSUPPLIERNAMECODE	nVarchar(20)	collate database_default ,
			INVOICEDESCRIPTION	nvarchar(254)	collate database_default ,
			TOTALINVOICEAMT		Decimal(11,2),
			TOTALTAXAMT		Decimal(11,2)
		)	"

	If @pbDebug=1
	Begin
		PRINT char(10)+ '--	CREATE TEMPTABLE'
		PRINT  @sSQLString
	End

	exec @nErrorCode=sp_executesql @sSQLString

end

-- Ensure the client refund flag is set correctly in order to extract the right information
If @pbIsClientRefund = 0
Begin
	Select @pbIsClientRefund = 1 
	from TRANSACTIONHEADER 
	where ENTITYNO = @pnEntityNo 
	and TRANSNO = @pnTransNo 
	and TRANSTYPE = 714
End

-- SQAO17310 extracts remittance details for client refund
If (@nErrorCode = 0 and @pbIsClientRefund = 1)
Begin
	-- insert payments from cash into temporary table
	Set @sSelect="INSERT INTO " + @prsTableName + " 
			Select CI.TRANSENTITYNO, CI.TRANSNO, N.NAMENO, dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) AS DEBTOR,"
			-- 19869 Show payment ref "CI.ITEMREFNO" instead invoice ref "OI.OPENITEMNO as PAYMENTREF" 			
			-- +char(10)+"CI.TRADER AS PAYEE, CI.ITEMDATE as PAYMENTDATE, OI.OPENITEMNO as PAYMENTREF, OI.REFERENCETEXT as PAYMENTDESC, PM.PAYMENTDESCRIPTION as PAYMETHOD,"
			+char(10)+"CI.TRADER AS PAYEE, CI.ITEMDATE as PAYMENTDATE, CI.ITEMREFNO as PAYMENTREF, OI.REFERENCETEXT as PAYMENTDESC, PM.PAYMENTDESCRIPTION as PAYMETHOD,"

			-- PAYMENTCURRENCY
			+char(10)+"Case when CI.PAYMENTCURRENCY is not null then CI.PAYMENTCURRENCY"
			+char(10)+"when CI.DISSECTIONCURRENCY is not null then CI.DISSECTIONCURRENCY"
			+char(10)+"else Convert(nVarchar(3), SI.COLCHARACTER) end AS PAYMENTCURRENCY,"

			-- TOTALPAYMENTAMT
			+char(10)+"ABS(Case when CI.PAYMENTAMOUNT is not null then (CI.PAYMENTAMOUNT * -1)"
			+char(10)+"when CI.DISSECTIONAMOUNT is not null then (CI.DISSECTIONAMOUNT * -1)"
			+char(10)+"	else (CI.LOCALAMOUNT *-1) end) AS TOTALPAYMENTAMT," 

			-- 19869 use OI.OPENITEMNO as INVOICEREF instead of null as INVOICEREF
			--+char(10)+"OI.ITEMDATE as INVOICEDATE, null as INVOICEREF, null as INVOICECURRENCY, null as INVOICEAMOUNT,"
			+char(10)+"OI.ITEMDATE as INVOICEDATE, OI.OPENITEMNO as INVOICEREF, null as INVOICECURRENCY, null as INVOICEAMOUNT,"
			+char(10)+"null as TAXAMOUNT, "
			+char(10)+"Case when DH.CURRENCY is not null then DH.FOREIGNTRANVALUE else DH.LOCALVALUE end as PAYMENTAMOUNT,"

			+char(10)+"null as TOTALPAYMENTAMTINWORDS, dbo.fn_GetMailingLabel(N.NAMENO, 'PAY') as MAILINGLABEL, N.NAMECODE, "
			+char(10)+"dbo.fn_FormatTelecom(1902, TC.ISD, TC.AREACODE, TC.TELECOMNUMBER, TC.EXTENSION),"
			-- 19869 use OI.REFERENCETEXT as INVOICEDESCRIPTION in stead of null in the 3rd last column
			+char(10)+"null, null, null, OI.REFERENCETEXT as INVOICEDESCRIPTION, null,null"

	Set @sFrom = nChar(10) + "from CASHITEM CI"
			+char(10)+"join NAME N	on (N.NAMENO = CI.ACCTNAMENO)"
			+char(10)+"join DEBTORHISTORY DH ON DH.REFTRANSNO = CI.TRANSNO"
			-- 19869 ADD JOIN "AND OI.ACCTDEBTORNO = DH.ACCTDEBTORNO"
			+char(10)+"join OPENITEM OI ON OI.ITEMTRANSNO = DH.ITEMTRANSNO AND OI.ACCTDEBTORNO = DH.ACCTDEBTORNO"

			+char(10)+"left join (SELECT NT.NAMENO, T.ISD, T.AREACODE, T.TELECOMNUMBER, T.EXTENSION"
			+char(10)+"FROM NAME NT	"
			+char(10)+"join TELECOMMUNICATION T	on (T.TELECODE = NT.FAX"
			+char(10)+"AND T.TELECOMTYPE = 1902)) TC"
			+char(10)+"On (TC.NAMENO = N.NAMENO)"

			+char(10)+"join PAYMENTMETHODS PM	on (PM.PAYMENTMETHOD = CI.ITEMTYPE)"
			+char(10)+"join SITECONTROL SI		on (SI.CONTROLID = 'CURRENCY')"

	-- Where clause
	Set @sFrom = @sFrom + nChar(10) + 
		"where CI.TRANSENTITYNO = " + CAST(@pnEntityNo as nvarchar(11)) 
		+char(10)+ "and CI.TRANSNO = " + CAST(@pnTransNo as nvarchar(11))

	If @pbDebug=1
	Begin
		PRINT char(10)+ '-- insert payments from debtorhistory into temporary table - single transaction'
		PRINT  @sSelect			
		PRINT  @sFrom
	End
		
	exec (@sSelect + @sFrom)

	Set @nErrorCode = @@Error
	Set @pnRowCount = @@RowCount
End


-- SQAO17310 only execute if not processing client refund
If (@nErrorCode = 0) and (@pbIsClientRefund = 0)
Begin
	-- insert payments from cash into temporary table
	Set @sSelect="INSERT INTO " + @prsTableName + " 
			Select CI.TRANSENTITYNO, CI.TRANSNO, N.NAMENO, dbo.fn_FormatNameUsingNameNo(N.NAMENO, null),"
			+char(10)+"CI.TRADER, CI.ITEMDATE, CI.ITEMREFNO, CI.[DESCRIPTION], PM.PAYMENTDESCRIPTION,"
			+char(10)+"Case when CI.PAYMENTCURRENCY is not null then CI.PAYMENTCURRENCY"
			+char(10)+"when CI.DISSECTIONCURRENCY is not null then CI.DISSECTIONCURRENCY"
			+char(10)+"else Convert(nVarchar(3), SI.COLCHARACTER) end AS PAYMENTCURRENCY,"
			+char(10)+"ABS(Case when CI.PAYMENTAMOUNT is not null then (CI.PAYMENTAMOUNT * -1)"
			+char(10)+"when CI.DISSECTIONAMOUNT is not null then (CI.DISSECTIONAMOUNT * -1)"
			+char(10)+"	else (CI.LOCALAMOUNT *-1) end) AS TOTALPAYMENT, CRI.ITEMDATE, CRI.DOCUMENTREF, CRI.CURRENCY,"
				-- Foreign Payment of invoice in the same currency.
				-- Invoice Cur = Payment Cur (and NOT Local) <> Bank Cur
	Set @sSelect= @sSelect+char(10)+"ABS(Case when CH.ITEMTRANSNO = CH.REFTRANSNO THEN NULL"
			+char(10)+"when (CI.PAYMENTCURRENCY is not null) and (CI.PAYMENTCURRENCY = CRI.CURRENCY) then CRI.FOREIGNVALUE"
					-- Local payment of a local invoice using a Foreign Bank Account.
					-- Invoice Cur = Payment Cur (and Local) <> Bank Cur
	Set @sSelect = @sSelect +char(10)+"when (CI.PAYMENTCURRENCY is not null) and (CI.PAYMENTCURRENCY = ISNULL(CRI.CURRENCY, SI.COLCHARACTER)) then CRI.LOCALVALUE"
					-- Foreign payment of invoice in different currency. 
					-- Dissection currency would equal payment currency if payment currency is not null
					-- and is not local.
					-- Invoice Cur (Not Local) = Payment Cur = Bank Cur
	Set @sSelect = @sSelect +char(10)+"when (CI.DISSECTIONCURRENCY is not null) and (CI.DISSECTIONCURRENCY = CRI.CURRENCY) then CRI.FOREIGNVALUE"
					-- Invoice Cur <> Payment Cur = Bank Cur (Not Local)
					-- Invoice Cur <> Payment Cur (not local) <> Bank Cur
					-- else
					-- Invoice Cur (Local) = Payment Cur = Bank Cur 
	Set @sSelect = @sSelect +char(10)+"when CI.DISSECTIONCURRENCY is not null then Round((CRI.LOCALVALUE * CI.DISSECTIONEXCHANGE), 2)"
			+char(10)+"else CRI.LOCALVALUE end) 
			* (case when CRI.ITEMTYPE = 7802 THEN -1 ELSE 1 end ) AS INVOICEAMOUNT,"
			

			+char(10)+"ABS(Case when (CI.PAYMENTCURRENCY is not null) and (CI.PAYMENTCURRENCY = CRI.CURRENCY) then ISNULL(Round((TAX.TAXAMOUNT * CI.DISSECTIONEXCHANGE), 2), CRI.FOREIGNTAXAMT)"
			+char(10)+"	when (CI.PAYMENTCURRENCY is not null) and (CI.PAYMENTCURRENCY = ISNULL(CRI.CURRENCY, SI.COLCHARACTER)) then ISNULL(TAX.TAXAMOUNT, CRI.LOCALTAXAMOUNT)"
	Set @sSelect = @sSelect +char(10)+"when (CI.DISSECTIONCURRENCY is not null) and (CI.DISSECTIONCURRENCY = CRI.CURRENCY) then ISNULL(Round((TAX.TAXAMOUNT * CI.DISSECTIONEXCHANGE), 2), CRI.FOREIGNTAXAMT)"
			+char(10)+"when CI.DISSECTIONCURRENCY is not null then ISNULL(Round((TAX.TAXAMOUNT * CI.DISSECTIONEXCHANGE), 2), Round((CRI.LOCALTAXAMOUNT * CI.DISSECTIONEXCHANGE), 2))"
			+char(10)+"else ISNULL(TAX.TAXAMOUNT, CRI.LOCALTAXAMOUNT) end) 
			* (case when CRI.ITEMTYPE = 7802 THEN -1 ELSE 1 end ) AS TAXAMOUNT,"

	-- Payment Amount of invoice/s paid
	If @pnPlanId is not null
	Begin
		-- If we're doing a bulk payment, just get the payment amount from PAYMENTPLANDETAIL.
		Set @sSelect= @sSelect + "
			PPDT.PAYMENTAMOUNT,"
	End
	Else
	Begin
		Set @sSelect = @sSelect +char(10)+"Case When (CI.PAYMENTCURRENCY is not null) and (CRI.DOCUMENTREF is not null) then "
			+char(10)+"Case When CI.PAYMENTCURRENCY = CH.CURRENCY	Then CH.FOREIGNTRANVALUE * -1"
			+char(10)+"Else Round((((CH.LOCALVALUE + CH.EXCHVARIANCE)/CI.LOCALAMOUNT) * CI.PAYMENTAMOUNT * -1), 2) End"
			+char(10)+"When (CI.DISSECTIONCURRENCY is not null) and (CRI.DOCUMENTREF is not null) 	then "
			+char(10)+"Case When CI.DISSECTIONCURRENCY = CH.CURRENCY Then CH.FOREIGNTRANVALUE * -1"
			+char(10)+"Else Round((((CH.LOCALVALUE + CH.EXCHVARIANCE)/CI.LOCALAMOUNT) * CI.DISSECTIONAMOUNT * -1), 2) End"
			+char(10)+"When (CRI.ITEMENTITYNO is not null) and (CRI.DOCUMENTREF is not null) then (CH.LOCALVALUE * -1)"
			+char(10)+"When CI.PAYMENTCURRENCY is not null then (CI.PAYMENTAMOUNT * -1)"
			+char(10)+"When CI.DISSECTIONCURRENCY is not null then (CI.DISSECTIONAMOUNT * -1) Else (CI.LOCALAMOUNT * -1) End AS PAYMENTAMOUNT,"
	End
	Set @sSelect = @sSelect +char(10)+"null, dbo.fn_GetMailingLabel(N.NAMENO, 'PAY'), N.NAMECODE, "
			+char(10)+"dbo.fn_FormatTelecom(1902, TC.ISD, TC.AREACODE, TC.TELECOMNUMBER, TC.EXTENSION),"
			+char(10)+"ED.SUPPLIERACCOUNTNO, PURN.NAME, PURN.NAMECODE, CRI.DESCRIPTION, null, null"
	Set @sFrom = nChar(10) + "from CASHITEM CI"
			+char(10)+"join NAME N	on (N.NAMENO = CI.ACCTNAMENO)"
			+char(10)+"left join (SELECT NT.NAMENO, T.ISD, T.AREACODE, T.TELECOMNUMBER, T.EXTENSION"
			+char(10)+"FROM NAME NT	"
			+char(10)+"join TELECOMMUNICATION T	on (T.TELECODE = NT.FAX"
			+char(10)+"AND T.TELECOMTYPE = 1902)) TC"
			+char(10)+"On (TC.NAMENO = N.NAMENO)"
			+char(10)+"left join CRENTITYDETAIL ED	on (ED.NAMENO = N.NAMENO "
			+char(10)+"and ED.ENTITYNAMENO = CI.ACCTENTITYNO)"
			+char(10)+"left join CREDITORHISTORY CH	on (CH.REFENTITYNO = CI.TRANSENTITYNO"
			+char(10)+"and CH.REFTRANSNO = CI.TRANSNO)"
			+char(10)+"left join CREDITORITEM CRI	on (CRI.ITEMENTITYNO = CH.ITEMENTITYNO"
			+char(10)+"and CRI.ITEMTRANSNO = CH.ITEMTRANSNO"
			+char(10)+"and CRI.ACCTCREDITORNO = CH.ACCTCREDITORNO"
			+char(10)+"and CRI.DOCUMENTREF = CH.DOCUMENTREF)"
			+char(10)+"left join (SELECT sum(ISNULL(TPH.TAXAMOUNT, 0)) AS TAXAMOUNT, ITEMENTITYNO, ITEMTRANSNO"
			+char(10)+"FROM TAXPAIDHISTORY TPH"
			+char(10)+"JOIN CASHITEM	ON (CASHITEM.TRANSENTITYNO = TPH.ITEMENTITYNO"
			+char(10)+"and CASHITEM.TRANSNO = TPH.ITEMTRANSNO)"
			+char(10)+"GROUP BY ITEMENTITYNO, ITEMTRANSNO) AS TAX	ON (CI.TRANSENTITYNO = TAX.ITEMENTITYNO"
			+char(10)+"AND CI.TRANSNO = TAX.ITEMTRANSNO)"
			+char(10)+"left join NAME PURN		on (PURN.NAMENO = CH.ACCTCREDITORNO)"
			+char(10)+"join PAYMENTMETHODS PM	on (PM.PAYMENTMETHOD = CI.ITEMTYPE)"
			+char(10)+"join SITECONTROL SI		on (SI.CONTROLID = 'CURRENCY')"


	If (@pnPlanId is not null)
	Begin
	-- Add a join to PAYMENTPLANDETAIL
		Set @sFrom = @sFrom +char(10)+"join PAYMENTPLANDETAIL PPDT 	on (PPDT.ITEMENTITYNO = CRI.ITEMENTITYNO"
			+char(10)+"				and PPDT.ITEMTRANSNO = CRI.ITEMTRANSNO"
			+char(10)+"				and PPDT.ACCTENTITYNO = CRI.ACCTENTITYNO"
			+char(10)+"				and PPDT.ACCTCREDITORNO = CRI.ACCTCREDITORNO)"
	--Where clause
		Set @sFrom = @sFrom + nChar(10) +
				"where CI.TRANSENTITYNO = (Select distinct PP.ENTITYNO from PAYMENTPLAN PP where PP.PLANID = " + CAST(@pnPlanId as nvarchar(11)) + ")"
			+char(10)+"	and CI.TRANSNO in (Select distinct PPD.REFTRANSNO from PAYMENTPLANDETAIL PPD where PPD.PLANID = " + CAST(@pnPlanId as nvarchar(11)) + " )"
			+char(10)+"	and PPDT.PLANID = " + CAST(@pnPlanId as nvarchar(11))

		If @pbDebug=1
		Begin
			PRINT char(10)+ '-- insert payments from cash into temporary table - Payment Plan'
			PRINT  @sSelect			
			PRINT  @sFrom
		End

		exec (@sSelect + @sFrom)
	End
	Else If (@pnEntityNo is not null) and (@pnTransNo is not null)
	Begin
		Set @sFrom = @sFrom + nChar(10) + 
			"where CI.TRANSENTITYNO = " + CAST(@pnEntityNo as nvarchar(11)) + "
			and CI.TRANSNO = " + CAST(@pnTransNo as nvarchar(11))

		If @pbDebug=1
		Begin
			PRINT char(10)+ '-- insert payments from cash into temporary table - single transaction'
			PRINT  @sSelect			
			PRINT  @sFrom
		End
		
		exec (@sSelect + @sFrom)
	End

	Set @nErrorCode = @@Error
	Set @pnRowCount = @@RowCount
End

-- SQAO17310 only execute if not processing client refund
If (@nErrorCode = 0 and @pbIsClientRefund = 0)
Begin
	--insert credit card payments into temporary table
	Set @sSelect ="INSERT INTO " + @prsTableName 
	+char(10)+"Select CRIPAY.ITEMENTITYNO, CRIPAY.ITEMTRANSNO, CRIPAYN.NAMENO, "
	+char(10)+"dbo.fn_FormatNameUsingNameNo(CRIPAYN.NAMENO, null),"
	+char(10)+"null, CRIPAY.ITEMDATE, CRIPAY.DOCUMENTREF, CRIPAY.[DESCRIPTION],"
	+char(10)+"PM.PAYMENTDESCRIPTION,"
	+char(10)+"Case when CRIPAY.CURRENCY is not null then CRIPAY.CURRENCY"
	+char(10)+"else Convert(nVarchar(3), SI.COLCHARACTER) end AS PAYMENTCURRENCY,"
	+char(10)+"ABS(Case when CRIPAY.CURRENCY is not null then (CRIPAY.FOREIGNVALUE * -1)"
	+char(10)+"else (CRIPAY.LOCALVALUE * -1) end) AS TOTALPAYMENT, CRI.ITEMDATE, CRI.DOCUMENTREF, CRI.CURRENCY,"
		-- Foreign Payment of invoice in the same currency.
		-- Invoice Cur = Payment Cur (and NOT Local)
	Set @sSelect = @sSelect
	+char(10)+"ABS(Case when CH.ITEMTRANSNO = CH.REFTRANSNO THEN NULL"
	+char(10)+"when ((CRIPAY.CURRENCY is not null) and (CRIPAY.CURRENCY = CRI.CURRENCY)) then CRI.FOREIGNVALUE"
		-- Local payment of a local invoice using a Foreign Bank Account.
		-- Invoice Cur = Payment Cur (and Local) 
	Set @sSelect = @sSelect 
	+char(10)+"when ((CRIPAY.CURRENCY is not null) and (CRIPAY.CURRENCY = ISNULL(CRI.CURRENCY, SI.COLCHARACTER))) then CRI.LOCALVALUE"
		-- Foreign Payment of invoice in different currency.
		-- Invoice Cur = Payment Cur (and NOT Local)
		-- else
		-- Invoice Cur (Local) = Payment Cur
	Set @sSelect = @sSelect 
	+char(10)+"when (CRIPAY.CURRENCY is not null) then Round((CRI.LOCALVALUE * CRIPAY.EXCHRATE), 2)"
	+char(10)+"else CRI.LOCALVALUE end) 
	* (case when CRI.ITEMTYPE = 7802 THEN -1 ELSE 1 end ) AS INVOICEAMOUNT,"
	
		-- Tax Amount of invoice in the same currency as the payment.
	Set @sSelect = @sSelect 
	+char(10)+"ABS(Case when ((CRIPAY.CURRENCY is not null) and (CRIPAY.CURRENCY = CRI.CURRENCY)) then ISNULL(Round((TAX.TAXAMOUNT * CRIPAY.EXCHRATE), 2) , CRI.FOREIGNTAXAMT)"
	+char(10)+"when ((CRIPAY.CURRENCY is not null) and (CRIPAY.CURRENCY = ISNULL(CRI.CURRENCY, SI.COLCHARACTER))) then ISNULL(TAX.TAXAMOUNT, CRI.LOCALTAXAMOUNT)"
	+char(10)+"when (CRIPAY.CURRENCY is not null) then ISNULL(Round((TAX.TAXAMOUNT * CRIPAY.EXCHRATE), 2) , Round((CRI.LOCALTAXAMOUNT * CRIPAY.EXCHRATE), 2))"
	+char(10)+"else ISNULL(TAX.TAXAMOUNT, CRI.LOCALTAXAMOUNT) end) 
	* (case when CRI.ITEMTYPE = 7802 THEN -1 ELSE 1 end ) AS TAXAMOUNT,"
	
	-- Payment Amount of invoice/s paid
	If @pnPlanId is not null
	Begin
		-- If we're doing a bulk payment, just get the payment amount from PAYMENTPLANDETAIL.
		Set @sSelect = @sSelect +char(10)+"PPDT.PAYMENTAMOUNT,"
	End
	Else
	Begin
		-- refer to CRIPAY when payment is for an account
		Set @sSelect = @sSelect 
		+char(10)+"Case when (CRIPAY.CURRENCY is not null) and (CRI.DOCUMENTREF is not null) then "
		+char(10)+"Round((((CH.LOCALVALUE + CH.EXCHVARIANCE)/CRIPAY.LOCALVALUE) * CRIPAY.FOREIGNVALUE * -1), 2)"
		+char(10)+"when (CRI.ITEMENTITYNO is not null) and (CRI.DOCUMENTREF is not null) then (CH.LOCALVALUE * -1)"
		+char(10)+"when (CRIPAY.CURRENCY is not null) and (CRIPAY.DOCUMENTREF is not null) then CRIPAY.FOREIGNVALUE"
		+char(10)+"else CRIPAY.LOCALVALUE end AS PAYMENTAMOUNT,"
	End

	Set @sSelect = @sSelect
		+char(10)+"null, dbo.fn_GetMailingLabel(CRIPAYN.NAMENO, 'PAY'), CRIPAYN.NAMECODE, "
		+char(10)+"dbo.fn_FormatTelecom(1902, TC.ISD, TC.AREACODE, TC.TELECOMNUMBER, TC.EXTENSION),"
		+char(10)+"ED.SUPPLIERACCOUNTNO, PURN.NAME, PURN.NAMECODE, CRI.DESCRIPTION, null, null"
		-- Purchase created as a result of the Credit Card payment
	Set @sFrom = nChar(10) + "from CREDITORITEM CRIPAY"
		-- History of items paid by the Credit Card payment OR resulting unallocated payments
		+char(10)+"left join CREDITORHISTORY CH	on (CH.REFENTITYNO = CRIPAY.ITEMENTITYNO"
		+char(10)+"				and CH.REFTRANSNO = CRIPAY.ITEMTRANSNO"
		+char(10)+"				and CH.MOVEMENTCLASS <> 1 AND CH.COMMANDID <> 1)"
		-- History for item CREATED by the Credit Card payment
		+char(10)+"left join CREDITORHISTORY PAYCH	on (PAYCH.REFENTITYNO = CRIPAY.ITEMENTITYNO"
		+char(10)+"				and PAYCH.REFTRANSNO = CRIPAY.ITEMTRANSNO"
		+char(10)+"				and PAYCH.MOVEMENTCLASS = 1 and PAYCH.COMMANDID = 1)"
		+char(10)+"left join NAME CRIPAYN		on (CRIPAYN.NAMENO = PAYCH.REMITTANCENAMENO)"
		+char(10)+"left join"
		+char(10)+"(SELECT NT.NAMENO, T.ISD, T.AREACODE, T.TELECOMNUMBER, T.EXTENSION"
		+char(10)+"FROM NAME NT"
		+char(10)+"join TELECOMMUNICATION T	on (T.TELECODE = NT.FAX"
		+char(10)+"				and T.TELECOMTYPE = 1902)) TC"
		+char(10)+"	On (TC.NAMENO = CRIPAYN.NAMENO)"
		+char(10)+"left join CRENTITYDETAIL ED	on (ED.NAMENO = CRIPAYN.NAMENO"
		+char(10)+"				and ED.ENTITYNAMENO = CH.ACCTENTITYNO)"
		-- Existing items paid by credit card payment
		+char(10)+"left join CREDITORITEM CRI	on (CRI.ITEMENTITYNO = CH.ITEMENTITYNO"
		+char(10)+"				and CRI.ITEMTRANSNO = CH.ITEMTRANSNO"
		+char(10)+"				and CRI.ACCTCREDITORNO = CH.ACCTCREDITORNO"
		+char(10)+"				and CRI.DOCUMENTREF = CH.DOCUMENTREF)"
		-- Tax recorded for a Payment of an account
		+char(10)+"left join (SELECT sum(ISNULL(TPH.TAXAMOUNT, 0)) AS TAXAMOUNT, TPH.ITEMENTITYNO, TPH.ITEMTRANSNO"
		+char(10)+"		FROM TAXPAIDHISTORY TPH"
		+char(10)+"		JOIN CREDITORITEM	ON (CREDITORITEM.ITEMENTITYNO = TPH.ITEMENTITYNO"
		+char(10)+"						and CREDITORITEM.ITEMTRANSNO = TPH.ITEMTRANSNO)"
		+char(10)+"		GROUP BY TPH.ITEMENTITYNO, TPH.ITEMTRANSNO) AS TAX	ON (CRIPAY.ITEMENTITYNO = TAX.ITEMENTITYNO"
		+char(10)+"												AND CRIPAY.ITEMTRANSNO = TAX.ITEMTRANSNO)"
		+char(10)+"left join NAME PURN		on (PURN.NAMENO = CRI.ACCTCREDITORNO)"
		+char(10)+"join PAYMENTMETHODS PM	on (PM.PAYMENTMETHOD = -3)" -- credit card payment
		+char(10)+"join SITECONTROL SI		on (SI.CONTROLID = 'CURRENCY')"

	If (@pnPlanId is not null)
	Begin
	-- Add a join to PAYMENTPLANDETAIL
		Set @sFrom = @sFrom
		+char(10)+"join PAYMENTPLANDETAIL PPDT 	on (PPDT.ITEMENTITYNO = CRI.ITEMENTITYNO"
		+char(10)+"				and PPDT.ITEMTRANSNO = CRI.ITEMTRANSNO)"
	End

	--Where clause
	Set @sFrom=@sFrom + nChar(10) + 
	"where CRIPAY.ITEMENTITYNO = @pnEntityNo "
	+char(10)+"and CRIPAY.ITEMTRANSNO = @pnTransNo "
	+char(10)+"and CRIPAY.ITEMTYPE = 7801"


	If (@pnPlanId is not null)
	Begin
		Set @sFrom=@sFrom + nChar(10) + 
		"and PPDT.PLANID = @pnPlanId "
	End

	If @pbDebug=1
	Begin
		PRINT nChar(10) + '--	insert credit card payments into temporary table'
		PRINT  @sSelect
		PRINT @sFrom
	End

--	exec (@sSelect + @sFrom)
	Set @sSQLString = @sSelect + @sFrom
	exec sp_executesql @sSQLString,
			N'@pnEntityNo	int,
			  @pnTransNo	int,
			  @pnPlanId	int',	
			  @pnEntityNo	= @pnEntityNo,
			  @pnTransNo 	= @pnTransNo,
			  @pnPlanId	= @pnPlanId


	Select @nErrorCode = @@Error,  @pnRowCount = @@RowCount

	If @pbDebug=1
	Begin
		select @nErrorCode as ERRORCODE, @pnRowCount AS PROCROWCOUNT
	End
End

-- 11381 MB
If @nErrorCode = 0 and (@pnPlanId is not null)
Begin	
	Select @sProcAmountToWords = PROCAMOUNTTOWORDS 
	from BANKACCOUNT B join PAYMENTPLAN P
		on (B.ACCOUNTOWNER = P.ENTITYNO and
		B.BANKNAMENO = P.BANKNAMENO and 
		B.SEQUENCENO = P.BANKSEQUENCENO )
	where P.PLANID = @pnPlanId

	Set @nErrorCode = @@Error
End

If @nErrorCode = 0 and (@pnPlanId is null)
Begin
	Select @sProcAmountToWords = B.PROCAMOUNTTOWORDS 
	from BANKACCOUNT B join CASHITEM P
		on (B.ACCOUNTOWNER = P.ENTITYNO and
		B.BANKNAMENO = P.BANKNAMENO and 
		B.SEQUENCENO = P.SEQUENCENO )
	where P.TRANSENTITYNO = @pnEntityNo 
		and P.TRANSNO = @pnTransNo

	Set @nErrorCode = @@Error

	If @pbDebug=1
	Begin
		select @nErrorCode as ERRORCODE, @sProcAmountToWords AS PROCAMTTOWORDS
	End
End




If @nErrorCode = 0 and @sProcAmountToWords is not null
Begin
	-- Update temporary table with the total payment amount in words
	Set @sSQLString = "Select @nTotalPaymentAmt=min(TOTALPAYMENTAMT)
			  from " + @prsTableName + " 
			  where TOTALPAYMENTAMT is not null"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@nTotalPaymentAmt	Decimal(11,2)		OUTPUT,
				@prsTableName		nvarchar(254)',
				@nTotalPaymentAmt	= @nTotalPaymentAmt	OUTPUT,
				@prsTableName		= @prsTableName

	If @pbDebug=1
	Begin
		PRINT char(10)+ '--	Convert total payment amount to amount in words - select Total Payment Amount'
		PRINT  @sSQLString
	End	

	While (@nTotalPaymentAmt is not null) and (@nErrorCode = 0)
	Begin


		Set @sSQLString = 'exec ' +   @sProcAmountToWords + ' @pnUserIdentityId, @psCulture, 0, @nTotalPaymentAmt, @sTotalPaymentAmtInWords output'

		Exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnUserIdentityId		int,
			@psCulture			nvarchar(10),
			@nTotalPaymentAmt		decimal(16,2),
			@sTotalPaymentAmtInWords	nvarchar(254) output',
			@pnUserIdentityId		= @pnUserIdentityId,
			@psCulture 			= @psCulture,
			@nTotalPaymentAmt		= @nTotalPaymentAmt,
			@sTotalPaymentAmtInWords	= @sTotalPaymentAmtInWords output

--		exec @nErrorCode=ap_ConvertNumberToDollarWords @pnUserIdentityId, @psCulture, 0, @nTotalPaymentAmt, @sTotalPaymentAmtInWords output
		
		If @pbDebug=1
		Begin
			PRINT char(10)+ '--	Execute specified stored procedure to derive amount in words'
			PRINT  @sSQLString
		End	

		If (@nErrorCode=0)
		Begin
			Set @sSQLString="Update " + @prsTableName + " 
					set TOTALPAYMENTAMTINWORDS = @sTotalPaymentAmtInWords
					where TOTALPAYMENTAMT = @nTotalPaymentAmt"

			exec @nErrorCode=sp_executesql @sSQLString,
						N'@prsTableName			nvarchar(254),
						  @sTotalPaymentAmtInWords	nvarchar(254),
						  @nTotalPaymentAmt		Decimal(11,2)',
						  @prsTableName			= @prsTableName,
						  @sTotalPaymentAmtInWords	= @sTotalPaymentAmtInWords,
						  @nTotalPaymentAmt	  	= @nTotalPaymentAmt
			
			If @pbDebug=1
			Begin
				PRINT char(10)+ '--	Update temporary table with the total payment amount in words'
				PRINT  @sSQLString
			End						
		End

		-- Now get the next total payment amount
		Set @sSQLString="Select @nTotalPaymentAmtOUT=min(TOTALPAYMENTAMT)
				from " + @prsTableName + " 
				where TOTALPAYMENTAMT > @nTotalPaymentAmt"
		
		If @pbDebug=1
		Begin
			PRINT char(10)+ '-- Get the next total payment amount'
			PRINT  @sSQLString
		End

		Exec @nErrorCode=sp_executesql @sSQLString,
					N'@nTotalPaymentAmtOUT	Decimal(11,2)		OUTPUT,
					  @prsTableName		nvarchar(254),
					  @nTotalPaymentAmt	Decimal(11,2)',
					  @nTotalPaymentAmtOUT	= @nTotalPaymentAmt	OUTPUT,
					  @prsTableName		= @prsTableName,
					  @nTotalPaymentAmt   	= @nTotalPaymentAmt
			
	End
	
	Set @nErrorCode = @@Error					
	Set @pnRowCount = @@Rowcount 
End


If (@nErrorCode=0)
Begin
	Set @sSQLString="Update " + @prsTableName + " 
			set TOTALINVOICEAMT = TOT.TOTALINVOICEAMOUNT,
			TOTALTAXAMT = TOT.TOTALTAXAMOUNT
			FROM (SELECT SUM(ISNULL(INVOICEAMOUNT, 0)) AS TOTALINVOICEAMOUNT, SUM(ISNULL(TAXAMOUNT,0)) AS TOTALTAXAMOUNT
			FROM " + @prsTableName + " ) AS TOT"

	exec @nErrorCode=sp_executesql @sSQLString
	
	If @pbDebug=1
	Begin
		PRINT char(10)+ '--	Update temporary table with the total invoice and tax amounts'
		PRINT  @sSQLString
	End						
End


If @pbDebug=1
Begin
	--Procedure output
	Set @sSQLString = "Select ENTITYNO, TRANSNO, NAMENO, 
			SUPPLIER, PAYEE, 
			ISNULL(INVOICEDATE, PAYMENTDATE) as 'ITEMDATE',
			PAYMENTDATE as 'PAYMENTDATE',
			ISNULL(INVOICEREF, PAYMENTREF) as 'REFERENCE', 
			PAYMENTDESC, PAYMETHOD, PAYMENTCURRENCY, 
			INVOICEAMOUNT, TAXAMOUNT, PAYMENTAMOUNT, 
			TOTALPAYMENTAMT, TOTALPAYMENTAMTINWORDS, MAILINGLABEL,
			SUPPLIERNAMECODE, SUPPLIERFAXNO, SUPPLIERACCOUNTNUMBER,
			PAYMENTREF, PURCHASESUPPLIER, PURCHSUPPLIERNAMECODE, INVOICEDESCRIPTION,
			TOTALINVOICEAMT, TOTALTAXAMT	
			from " + @prsTableName + " 
			order by ENTITYNO, NAMENO"

	PRINT char(10)+ '-- Output'
	PRINT  @sSQLString

	exec sp_executesql @sSQLString

	PRINT char(10)+ '-- Drop table ' + @prsTableName 
End

RETURN @nErrorCode	
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.ap_ListRemittanceAdviceDetails to public
go
