-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ta_ListRemittanceAdviceDetails
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ta_ListRemittanceAdviceDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ta_ListRemittanceAdviceDetails.'
	drop procedure dbo.ta_ListRemittanceAdviceDetails
end
print '**** Creating procedure dbo.ta_ListRemittanceAdviceDetails...'
print ''
go 

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ta_ListRemittanceAdviceDetails
(
	@pnRowCount					int	output,
	@pnUserIdentityId			int		= null,	-- Included for use by .NET
	@psCulture					nvarchar(10)	= null, -- The language in which output is to be expressed
	@pnEntityNo					int,			-- The NameNo of Entity from which manual payment was made
	@pnTransNo					int,			-- The TransNo resulting from manual payment
	@prsTableName				nvarchar(254),
	@pbReleaseFundAsPrePayment	smallint,
	@pbDebug					smallint	= 0
)
AS
-- PROCEDURE :	ta_ListRemittanceAdviceDetails
-- VERSION :	6
-- COPYRIGHT:	Copyright 1993 - 2008 CPA Software Solutions (Australia) Pty Limited
-- SCOPE:	TA
-- DESCRIPTION:	Get the Remittance Advice details of a payment or Transfer.
--		The procedure is used by Release Funds in the Trust Accounting module.
-- CALLED BY :	Centura

-- MODIFICTIONS :
-- Date         Who  	SQA#	Version  Change
-- ------------ ----	---- 	-------- ------------------------------------------- 
-- 01/04/2008	JS	10105	1	Created based on ap_ListRemittanceAdviceDetails.
-- 09/11/2009	DL	17798	2	Corrected the recipient of the cheque.
-- 10/02/2011	DL	19239	3	Fixed bug incorrect recipient when release fund to debtor.
-- 10/1/2014	DL	21637	4	Cheque printing should print the Payee on the cheque not the Debtor Name
-- 27/02/2014	DL	21508	5	Change variables and temp table columns that reference namecode to 20 characters
-- 02 Nov 2015	vql	R53910	6	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
Set CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode			int,
	@nTotalPaymentAmt		Decimal(11,2),
	@sTotalPaymentAmtInWords	nVarchar(254),
	@sSQLString				nVarChar(4000),
	@sProcAmountToWords		nVarChar (128),
	@sSQLString2			nvarchar(4000)

Set @nTotalPaymentAmt=null
Set @sTotalPaymentAmtInWords=null
Set @sSQLString=null

If (@pnEntityNo is not null) and (@pnTransNo is not null)
Begin
	Set @nErrorCode = 0
End
Else
Begin
	Set @nErrorCode = -1
End

If @nErrorCode = 0
Begin
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
			INVOICEDESCRIPTION	nvarchar(254)	collate database_default
		)	"

	exec @nErrorCode=sp_executesql @sSQLString

	If @pbDebug = 1
		print @sSQLString
end

If (@nErrorCode = 0)
Begin
	--insert payments from cash into temporary table
	-- sqa21637 changed N.NAME to CI.TRADER to allow override payee to be displayed on cheque
	Set @sSQLString="INSERT INTO " + @prsTableName + " 
			Select CI.TRANSENTITYNO, CI.TRANSNO, N.NAMENO, 
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, null),
			CI.TRADER, CI.ITEMDATE, CI.ITEMREFNO, CI.[DESCRIPTION],
			PM.PAYMENTDESCRIPTION,			
			Case 	when CI.PAYMENTCURRENCY is not null then CI.PAYMENTCURRENCY
				when CI.DISSECTIONCURRENCY is not null then CI.DISSECTIONCURRENCY
				else Convert(nVarchar(3), SI.COLCHARACTER)
			end,
			Case	when CI.PAYMENTAMOUNT is not null then (CI.PAYMENTAMOUNT * -1)
				when CI.DISSECTIONAMOUNT is not null then (CI.DISSECTIONAMOUNT * -1)
				else (CI.LOCALAMOUNT *-1)
			end,
			TI.ITEMDATE, TI.ITEMNO,
			TI.CURRENCY,"
				-- Foreign Payment of invoice in the same currency.
				-- Invoice Cur = Payment Cur (and NOT Local) <> Bank Cur
	Set @sSQLString= @sSQLString + "
			Case	when (CI.PAYMENTCURRENCY is not null) and (CI.PAYMENTCURRENCY = TI.CURRENCY) then 
					TI.FOREIGNVALUE"
					-- Local payment of a local invoice using a Foreign Bank Account.
					-- Invoice Cur = Payment Cur (and Local) <> Bank Cur
	Set @sSQLString= @sSQLString + "
				when (CI.PAYMENTCURRENCY is not null) and (CI.PAYMENTCURRENCY = ISNULL(TI.CURRENCY, SI.COLCHARACTER)) then
				     	TI.LOCALVALUE"
					-- Foreign payment of invoice in different currency. 
					-- Dissection currency would equal payment currency if payment currency is not null
					-- and is not local.
					-- Invoice Cur (Not Local) = Payment Cur = Bank Cur
	Set @sSQLString= @sSQLString + "
				when (CI.DISSECTIONCURRENCY is not null) and (CI.DISSECTIONCURRENCY = TI.CURRENCY) then 
					TI.FOREIGNVALUE"
					-- Invoice Cur <> Payment Cur = Bank Cur (Not Local)
					-- Invoice Cur <> Payment Cur (not local) <> Bank Cur
	Set @sSQLString= @sSQLString + "
				when CI.DISSECTIONCURRENCY is not null then 
					Round((TI.LOCALVALUE * CI.DISSECTIONEXCHANGE), 2)
				else
					-- Invoice Cur (Local) = Payment Cur = Bank Cur 
					TI.LOCALVALUE 
			end,
			convert( decimal(11,2), 0.0 ),"

	-- Payment Amount of invoice/s paid
	Set @sSQLString= @sSQLString + "
			Case when (CI.PAYMENTCURRENCY is not null) and (TI.ITEMNO is not null) then 
				Round((((TH.LOCALVALUE + TH.EXCHVARIANCE)/CI.LOCALAMOUNT) * CI.PAYMENTAMOUNT * -1), 2)
			     when (CI.DISSECTIONCURRENCY is not null) and (TI.ITEMNO is not null) then 
				Round((((TH.LOCALVALUE + TH.EXCHVARIANCE)/CI.LOCALAMOUNT) * CI.DISSECTIONAMOUNT * -1), 2)
			     when (TI.ITEMENTITYNO is not null) and (TI.ITEMNO is not null) then 
				(TH.LOCALVALUE * -1)
			     when CI.PAYMENTCURRENCY is not null then 
				(CI.PAYMENTAMOUNT * -1)
			     when CI.DISSECTIONCURRENCY is not null then 
				(CI.DISSECTIONAMOUNT * -1)
			     else 
				(CI.LOCALAMOUNT * -1)
			end,"

	If @pbReleaseFundAsPrePayment = 1
		-- SQA17798 release paymnet to the entity's account
		set @sSQLString2 = "join NAME N on (N.NAMENO = CI.ENTITYNO) " + char(13) + char(10) 
	else
		-- SQA19239  release payment to a selected client
		set @sSQLString2 = "join NAME N on (N.NAMENO = CI.ACCTNAMENO) " + char(13) + char(10) 

	Set @sSQLString= @sSQLString + "
			null, dbo.fn_GetMailingLabel(N.NAMENO, 'SMT'),
			N.NAMECODE, 
			dbo.fn_FormatTelecom(1902, TC.ISD, TC.AREACODE, TC.TELECOMNUMBER, TC.EXTENSION),
			ED.SUPPLIERACCOUNTNO,
			PURN.NAME, PURN.NAMECODE, 
			TI.DESCRIPTION
			
			from CASHITEM CI " + @sSQLString2 + "
			
			left join 
				(	SELECT NT.NAMENO, T.ISD, T.AREACODE, T.TELECOMNUMBER, T.EXTENSION
					FROM NAME NT	
					join TELECOMMUNICATION T	on (T.TELECODE = NT.FAX
										AND T.TELECOMTYPE = 1902)) TC
				On (TC.NAMENO = N.NAMENO)
			left join CRENTITYDETAIL ED	on (ED.NAMENO = N.NAMENO 
							and ED.ENTITYNAMENO = CI.ACCTENTITYNO)
			left join TRUSTHISTORY TH	on (TH.REFENTITYNO = CI.TRANSENTITYNO
							and TH.REFTRANSNO = CI.TRANSNO)
			left join TRUSTITEM TI		on (TI.ITEMENTITYNO = TH.ITEMENTITYNO 
							and TI.ITEMTRANSNO = TH.ITEMTRANSNO)
			left join NAME PURN		on (PURN.NAMENO = TH.TACCTNAMENO)
			join PAYMENTMETHODS PM		on (PM.PAYMENTMETHOD = CI.ITEMTYPE)
			join SITECONTROL SI		on (SI.CONTROLID = 'CURRENCY')"

	Set @sSQLString=@sSQLString + nChar(10) + 
		"where CI.TRANSENTITYNO = @pnEntityNo
		and CI.TRANSNO = @pnTransNo"

	exec sp_executesql @sSQLString,
		N'@prsTableName	nvarchar(254),
		  @pnEntityNo	int,
		  @pnTransNo	int',
		  @prsTableName,	
		  @pnEntityNo,
		  @pnTransNo

	If @pbDebug = 1
		print @sSQLString

	Set @nErrorCode = @@Error
	Set @pnRowCount = @@RowCount
End

If @nErrorCode = 0
Begin
	Select @sProcAmountToWords = B.PROCAMOUNTTOWORDS 
	from BANKACCOUNT B join CASHITEM P
		on (B.ACCOUNTOWNER = P.ENTITYNO and
		B.BANKNAMENO = P.BANKNAMENO and 
		B.SEQUENCENO = P.SEQUENCENO )
	where P.TRANSENTITYNO = @pnEntityNo 
		and P.TRANSNO = @pnTransNo

	Set @nErrorCode = @@Error
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

	If @pbDebug = 1
		print @sSQLString


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
		
	If @pbDebug = 1
		print @sSQLString


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


			If @pbDebug = 1
				print @sSQLString
		End

		-- Now get the next total payment amount
		Set @sSQLString="Select @nTotalPaymentAmtOUT=min(TOTALPAYMENTAMT)
				from " + @prsTableName + " 
				where TOTALPAYMENTAMT > @nTotalPaymentAmt"
		
		Exec @nErrorCode=sp_executesql @sSQLString,
					N'@nTotalPaymentAmtOUT	Decimal(11,2)		OUTPUT,
					  @prsTableName		nvarchar(254),
					  @nTotalPaymentAmt	Decimal(11,2)',
					  @nTotalPaymentAmtOUT	= @nTotalPaymentAmt	OUTPUT,
					  @prsTableName		= @prsTableName,
					  @nTotalPaymentAmt   	= @nTotalPaymentAmt

		If @pbDebug = 1
			print @sSQLString

	End

	
	Set @nErrorCode = @@Error					
	Set @pnRowCount = @@Rowcount 
End

RETURN @nErrorCode	
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.ta_ListRemittanceAdviceDetails to public
go
