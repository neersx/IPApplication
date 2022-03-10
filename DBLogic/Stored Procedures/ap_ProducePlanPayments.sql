-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ap_ProducePlanPayments
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ap_ProducePlanPayments]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ap_ProducePlanPayments.'
	Drop procedure [dbo].[ap_ProducePlanPayments]
End
Print '**** Creating Stored Procedure dbo.ap_ProducePlanPayments...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ap_ProducePlanPayments
(
	@pnUserIdentityId	int		= null,
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura 	tinyint 	= 0,
	@pbDebugFlag	 	tinyint 	= 0,
	@prsTableName		nvarchar(32),
	@pnPlanId		int
)
as
-- PROCEDURE:	ap_ProducePlanPayments
-- VERSION:	13
-- COPYRIGHT: 	Copyright 1993 - 2009 CPA Software Solutions (Australia) Pty Limited
-- SCOPE:	InPro
-- DESCRIPTION:	Called from Centura or the ProcessPaymentPlan stored procedure 
--		to produce payments required to process a payment plan in Accounts Payable

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 29 Sept 2003 CR	8816	1.00	Procedure created
-- 09-Dec-2003	CR	8817	1.01	Fixed Single Withdrawal and exchange variance bugs
-- 10-Dec-2003	CR	8817	1.02	Fixed more bugs
-- 12-Dec-2003	CR	8817	1.03	Added additional check to exclude 0 value payments
-- 15-Dec-2003	CR	8816	1.04	Changed where fnConvertCurrency is called - if being 
--					used in another equation don't convert until the end result 
--					has been derived.
-- 06-Feb-2004	CR	9558	1.05	Fixed a few coding style issues.
-- 18-Feb-2004	SS	9297	1.06	Incorporated bank rate.
-- 14-May-2004	CR	8784	7	Added comments and updated details.
-- 14-Oct-2004	CR	10081	8	Added F/X Dealer Reference.
-- 23-Mar-2005	CR	10146	9	Logic to populate the global temporary table created will be updated 
--					to populate from CASHITEM when the status of the payment plan is draft.
-- 16-Oct-2008	CR	10514	10	Extended to cater for Cash Accounting.
-- 29-May-2009	AC	15555	11	Set up SWIFT Instruction Codes in Inprotech.  e.g. CHQB, HOLD, PHON etc.
-- 10 Sep 2009	CR	SQA8819	12	Updated joins to CREDITORITEM and CREDITORHISTORY to cater for
--								Unallocated Payments recorded using the Credit Card method 
--								(i.e. two Creditor Items created with the same TransId)
-- 20 Oct 2015  MS      R53933  13      Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols

/*-- for Debugging
SET QUOTED_IDENTIFIER OFF
SET ANSI_NULLS ON
Declare @prsTableName		nvarchar(32),
	@pnUserIdentityId	int,
	@psCulture		nvarchar(10),
	@pbCalledFromCentura 	tinyint,
	@pbDebugFlag	 	tinyint,
	@pnPlanId		int

Set @pnPlanId = 2
Set @prsTableName = '##TEMPPP2CHRISTINE' 
Set @pbDebugFlag = 1
*/

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF


Declare 
	@nErrorCode 		int,
	@sOfficeCulture		nvarchar(10),
	@sSQLString		nvarchar(4000),
	@nCreditorNameNo	int,
	@sCurrencyCode		nvarchar(3),
	@sBankCurrency		nvarchar(3),
	@sLocalCurrency		nvarchar(3),
	@nExchRateType		tinyint

Set @nErrorCode = 0
Set @nCreditorNameNo = NULL
Set @sCurrencyCode = NULL

--Set @sTableName =  @prsTableName + CONVERT(varchar(220), NEWID())
--Set @prsTableName= REPLACE (@sTableName, '-', '')

--Append Plan Id to the end of temporary table name.
--Set @prsTableName = RTRIM(@prsTableName + CONVERT(nvarchar(12), @pnPlanId))

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select @sBankCurrency = BA.CURRENCY
	From BANKACCOUNT BA
	Join PAYMENTPLAN PP 	on (BA.ACCOUNTOWNER = PP.ENTITYNO
				and	BA.BANKNAMENO = PP.BANKNAMENO
				and	BA.SEQUENCENO = PP.BANKSEQUENCENO)
	Where PP.PLANID = @pnPlanId"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@sBankCurrency		nvarchar(3)	OUTPUT,
				@pnPlanId 			int',
				@sBankCurrency=@sBankCurrency			OUTPUT,
				@pnPlanId=@pnPlanId
End

-- For Debugging
If @pbDebugFlag = 1
Begin
	PRINT '*** Retrieve the Currency of the Bank ***'
	Select @sBankCurrency
End


If @nErrorCode = 0
Begin
	Set @sSQLString = "Select @sLocalCurrency = SI.COLCHARACTER
	from SITECONTROL SI	
	where SI.CONTROLID = 'CURRENCY'"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@sLocalCurrency		nvarchar(3)	OUTPUT',
				@sLocalCurrency=@sLocalCurrency			OUTPUT
End

-- For Debugging
If @pbDebugFlag = 1
Begin
	PRINT '*** Retrieve the Local Currency ***'
	Select @sLocalCurrency
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select @nExchRateType = SI.COLBOOLEAN
	from SITECONTROL SI
	where SI.CONTROLID = 'Bank Rate In Use'"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@nExchRateType	tinyint	OUTPUT',
				@nExchRateType=@nExchRateType	OUTPUT

	If @nExchRateType <> 1
	Begin
		-- Bank Rate is not in use so use Buy Rate
		Set @nExchRateType = 2
	End
End

--For Debugging
If @pbDebugFlag = 1
Begin
	PRINT '*** Determine if the Bank Rate should be used ***'
	Select @nExchRateType
End

If @nErrorCode = 0
Begin
	-- 15555
	Set @sSQLString = "CREATE TABLE " + @prsTableName + " (
		SEQUENCE 		int 		identity,
		ENTITYNO 		int 		NOT NULL,
		BANKNAMENO 		int 		NOT NULL,
		BANKSEQUENCENO 		int 		NOT NULL,
		DESCRIPTION 		nvarchar(254) 	collate database_default NULL,
		ITEMTYPE 		int 		NOT NULL,
		TRADER 			nvarchar(254) 	collate database_default NULL,
		ACCTENTITYNO 		int 		NULL,
		ACCTNAMENO 		int 		NULL,
		ITEMREFNO 		nvarchar(30) 	collate database_default NULL,
		ITEMCURRENCY		nvarchar(3)	collate database_default NULL,
		PAYMENTCURRENCY 	nvarchar(3) 	collate database_default NULL,
		PAYMENTAMOUNT 		decimal(13, 2) 	NULL,
		BANKEXCHANGERATE 	decimal(11, 4) 	NULL,
		BANKAMOUNT 		decimal(13, 2) 	NULL,
		BANKCHARGES 		decimal(9, 2) 	NULL,
		BANKNET 		decimal(13, 2) 	NULL,
		DISSECTIONCURRENCY 	varchar(3) 	NULL,
		DISSECTIONAMOUNT 	decimal(13, 2) 	NULL,
		DISSECTIONUNALLOC 	decimal(13, 2) 	NULL,
		DISSECTIONEXCHANGE 	decimal(11, 4) 	NULL,
		LOCALAMOUNT 		decimal(13, 2) 	NULL,
		LOCALCHARGES 		decimal(9, 2) 	NULL,
		LOCALEXCHANGERATE 	decimal(11, 4) 	NULL,
		LOCALNET 		decimal(13, 2) 	NULL,
		LOCALUNALLOCATED 	decimal(13, 2) 	NULL,
		BANKOPERATIONCODE	int		NULL,
		DETAILSOFCHARGES	int		NULL,
		FXDEALERREF		nvarchar (16)	collate database_default NULL,
		EFTFILEFORMAT		int		NULL,
		EFTPAYMENTFILE		nvarchar(254)	collate database_default NULL,
		JOURNALENTITYNO		int		NULL,
		JOURNALTRANSNO		int		NULL,
		INSTRUCTIONCODE		INT		NULL)"

	exec @nErrorCode=sp_executesql @sSQLString

end

-- For Debugging
If @pbDebugFlag = 1
Begin
	PRINT 'Table Created'
	select @sSQLString
	Set @sSQLString = "SELECT * FROM " + @prsTableName
	exec @nErrorCode=sp_executesql @sSQLString
End


/*
PAYMENTCURRENCY		= currency available for financial transactions.  
				NULL IF SAME AS BANK

PAYMENTAMOUNT 		= The amount transferred in the Payment currency.
   				NULL IF SAME AS BANK

BANKEXCHANGERATE 	= The exchange rate used for the payment.
				NULL IF SAME AS BANK
				e.g. 374.00/550.91 (PAYMENTAMOUNT/BANKAMOUNT)  
				Bank Amount * Bank Rate = Payment Amount.				

BANKAMOUNT 		= The Payment Amount expressed in Bank Currency. 
				The Payment Amount expressed in Bank Currency.  
				Note that this is exclusive of charges.  
				Proves Bank Amount on Bank History. (Cash Ledger).	

BANKCHARGES 		= Any charges subtracted from the Bank Amount in Bank currency.
				Any charges subtracted from the Bank Amount before deposit to the account.  
				In Bank Currency.  Used to justify the difference between the amount deposited to the 
				Bank, and the amount dissected (i.e. the intersection between the Bank and Cash Ledgers).  
				Required for automatic dissection of bank charges.

BANKNET 		= The total amount transferred in/out of the account in Bank currency
				The actual amount transferred in/out of the account in Bank currency; 
				i.e. inclusive of charges.  Proof of Bank History (Bank Ledger).  
				Bank Amount - Bank Charges = Bank Net.


When the payments are drafted for the first time BANKCHARGES will always be zero so the BANKNET will equal BANKAMOUNT.

*/

If @nErrorCode = 0
Begin

	-- For Debugging
	If @pbDebugFlag = 1
	Begin
		print 'Check for existing CASHITEMS'
		select * 
		FROM CASHITEM CI
		JOIN PAYMENTPLANDETAIL PPD 	ON (PPD.REFENTITYNO = CI.TRANSENTITYNO
						AND PPD.REFTRANSNO = CI.TRANSNO)
		where PPD.PLANID = @pnPlanId
	End


	-- copy the existing payments from the CASHITEM table
	if exists 	(select * 
			FROM CASHITEM CI
			JOIN PAYMENTPLANDETAIL PPD 	ON (PPD.REFENTITYNO = CI.TRANSENTITYNO
							AND PPD.REFTRANSNO = CI.TRANSNO)
			where PPD.PLANID = @pnPlanId)
	Begin

		-- For Debugging
		If @pbDebugFlag = 1
		Begin
			print 'Existing CASHITEMS found'
		End
		-- 15555
		Set @sSQLString = "Insert into " + @prsTableName + "
		(ENTITYNO, BANKNAMENO, BANKSEQUENCENO, DESCRIPTION, ITEMTYPE, TRADER, 
		ACCTENTITYNO, ACCTNAMENO, ITEMREFNO, 
		ITEMCURRENCY, 
		PAYMENTCURRENCY, PAYMENTAMOUNT, 
		BANKEXCHANGERATE, BANKAMOUNT, BANKCHARGES, BANKNET, 
		DISSECTIONCURRENCY, DISSECTIONAMOUNT, DISSECTIONUNALLOC, DISSECTIONEXCHANGE, 
		LOCALAMOUNT, LOCALCHARGES, LOCALEXCHANGERATE, LOCALNET, LOCALUNALLOCATED, 
		BANKOPERATIONCODE, DETAILSOFCHARGES, FXDEALERREF, EFTFILEFORMAT, EFTPAYMENTFILE,INSTRUCTIONCODE)
	
		Select CI.ENTITYNO, CI.BANKNAMENO, CI.SEQUENCENO, CI.DESCRIPTION, CI.ITEMTYPE, CI.TRADER, 
		CI.ACCTENTITYNO, CI.ACCTNAMENO, CI.ITEMREFNO, 
		CASE WHEN ISNULL(CI.PAYMENTCURRENCY,@sBankCurrency) = @sLocalCurrency THEN NULL ELSE ISNULL(CI.PAYMENTCURRENCY,@sBankCurrency) END AS ITEMCURRENCY,
		CI.PAYMENTCURRENCY, CI.PAYMENTAMOUNT, 
		CI.BANKEXCHANGERATE, CI.BANKAMOUNT, CI.BANKCHARGES, CI.BANKNET,
		CI.DISSECTIONCURRENCY, CI.DISSECTIONAMOUNT, CI.DISSECTIONUNALLOC, CI.DISSECTIONEXCHANGE,
		CI.LOCALAMOUNT, CI.LOCALCHARGES, CI.LOCALEXCHANGERATE, CI.LOCALNET, CI.LOCALUNALLOCATED, 
		CI.BANKOPERATIONCODE, CI.DETAILSOFCHARGES, CI.FXDEALERREF, CI.EFTFILEFORMAT, CI.EFTPAYMENTFILE, CI.INSTRUCTIONCODE
		
		from PAYMENTPLANDETAIL PPD	
		INNER JOIN CASHITEM CI			ON (CI.TRANSENTITYNO = PPD.REFENTITYNO AND
							    CI.TRANSNO = PPD.REFTRANSNO)
		where PPD.PLANID = @pnPlanId
		
		group by PPD.PLANID, CI.ENTITYNO, CI.BANKNAMENO, CI.SEQUENCENO, CI.DESCRIPTION, CI.ITEMTYPE, 
		CI.TRADER, CI.ACCTENTITYNO, CI.ACCTNAMENO, CI.ITEMREFNO, 
		CI.PAYMENTCURRENCY, CI.PAYMENTAMOUNT, CI.BANKEXCHANGERATE, CI.BANKAMOUNT, CI.BANKCHARGES, CI.BANKNET,
		CI.DISSECTIONCURRENCY, CI.DISSECTIONAMOUNT, CI.DISSECTIONUNALLOC, CI.DISSECTIONEXCHANGE,
		CI.LOCALAMOUNT, CI.LOCALCHARGES, CI.LOCALEXCHANGERATE, CI.LOCALNET, CI.LOCALUNALLOCATED, 
		CI.BANKOPERATIONCODE, CI.DETAILSOFCHARGES, CI.FXDEALERREF, CI.EFTFILEFORMAT, CI.EFTPAYMENTFILE,CI.INSTRUCTIONCODE"
	
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@prsTableName			nvarchar(116),
					@sBankCurrency			nvarchar(3),
					@sLocalCurrency			nvarchar(3),
					@pnPlanId 			int',
					@prsTableName,
					@sBankCurrency,
					@sLocalCurrency,
					@pnPlanId



		-- SQA10514
		If @nErrorCode = 0
		Begin

			Set @sSQLString=" 
			UPDATE " + @prsTableName + "
			SET	JOURNALENTITYNO = BH.REFENTITYNO,
				JOURNALTRANSNO = BH.REFTRANSNO
			from PAYMENTPLANDETAIL PPD	
			INNER JOIN CASHITEM CI	ON (CI.TRANSENTITYNO = PPD.REFENTITYNO AND
						    CI.TRANSNO = PPD.REFTRANSNO)
			join 	BANKHISTORY BH	ON (BH.REFENTITYNO = CI.BANKEDBYENTITYNO
						AND BH.REFTRANSNO = CI.BANKEDBYTRANSNO)			
			where PPD.PLANID = @pnPlanId"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@prsTableName			nvarchar(116),
						@pnPlanId 			int',
						@prsTableName,
						@pnPlanId
			
	 		-- For Debugging
			If @pbDebugFlag = 1
			Begin
				print 'Existing LEDGERJOURNALs found'
				print @sSQLString
			End
		End
	End
	Else
	-- derive the payments from the payment details specified for the current payment plan
	Begin
		-- For Debugging
		If @pbDebugFlag = 1
		Begin
			print 'Payments to be made will be derived'
		End

		If @nErrorCode = 0
		Begin
			Set @sSQLString = "Insert into " + @prsTableName + "
			(ENTITYNO, BANKNAMENO, BANKSEQUENCENO, [DESCRIPTION], ITEMTYPE, 
			TRADER, 
			ACCTENTITYNO, ACCTNAMENO, ITEMREFNO, ITEMCURRENCY,
			PAYMENTCURRENCY, PAYMENTAMOUNT, 
			BANKEXCHANGERATE, 
			BANKAMOUNT, BANKCHARGES,
			BANKNET)
		
			Select PP.ENTITYNO, PP.BANKNAMENO, PP.BANKSEQUENCENO, NULL, PP.PAYMENTMETHOD, 
			ISNULL(C.CHEQUEPAYEE, CN.NAME+CASE WHEN CN.FIRSTNAME is not NULL THEN ', '+CN.FIRSTNAME END) AS TRADER, 
			CI.ACCTENTITYNO, CI.ACCTCREDITORNO, NULL, CI.CURRENCY,
			CASE WHEN ISNULL(CI.CURRENCY,@sLocalCurrency) = @sBankCurrency THEN NULL ELSE ISNULL(CI.CURRENCY,@sLocalCurrency) END AS PAYMENTCURRENCY, 
			CASE WHEN ISNULL(CI.CURRENCY,@sLocalCurrency) = @sBankCurrency THEN NULL ELSE (SUM(PPD.PAYMENTAMOUNT)*-1) END AS PAYMENTAMOUNT, 
			CASE WHEN ISNULL(CI.CURRENCY,@sLocalCurrency) = @sBankCurrency THEN NULL ELSE 
				convert( decimal(11,4), ( SUM(PPD.PAYMENTAMOUNT) / 
				dbo.fn_ConvertCurrency(CI.CURRENCY, @sBankCurrency, SUM(PPD.PAYMENTAMOUNT), @nExchRateType)) ) 
			END AS BANKEXCHANGERATE, 
			convert( decimal(11,2), dbo.fn_ConvertCurrency(CI.CURRENCY, @sBankCurrency, SUM(PPD.PAYMENTAMOUNT), @nExchRateType) )*-1 AS BANKAMOUNT, 0,
			convert( decimal(11,2), dbo.fn_ConvertCurrency(CI.CURRENCY, @sBankCurrency, SUM(PPD.PAYMENTAMOUNT), @nExchRateType) )*-1 AS BANKNET
		
			from PAYMENTPLAN PP 
			INNER JOIN PAYMENTPLANDETAIL PPD	ON (PPD.PLANID = PP.PLANID)
			INNER JOIN CREDITORITEM CI		ON (CI.ITEMENTITYNO = PPD.ITEMENTITYNO AND
								    CI.ITEMTRANSNO = PPD.ITEMTRANSNO AND
									CI.ACCTENTITYNO = PPD.ACCTENTITYNO AND
									CI.ACCTCREDITORNO = PPD.ACCTCREDITORNO)
			INNER JOIN CREDITOR C			ON (C.NAMENO = PPD.ACCTCREDITORNO)
			INNER JOIN NAME CN			ON (CN.NAMENO = C.NAMENO)					-- Creditor name
						
			where PP.PLANID = @pnPlanId
			and PPD.PAYMENTAMOUNT <> 0
			
			group by PP.PLANID, CI.CURRENCY, CI.ACCTCREDITORNO, CI.ACCTENTITYNO, CI.ITEMENTITYNO, 
			PP.ENTITYNO, PP.BANKNAMENO, PP.BANKSEQUENCENO, PP.PAYMENTMETHOD, C.CHEQUEPAYEE, CN.NAME, CN.FIRSTNAME
			order by CN.NAME+CASE WHEN CN.FIRSTNAME is not NULL THEN ', '+CN.FIRSTNAME END, CI.ACCTCREDITORNO, CI.CURRENCY, CI.ACCTENTITYNO, CI.ITEMENTITYNO"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@prsTableName			nvarchar(116),
						@sLocalCurrency			nvarchar(3),
						@sBankCurrency			nvarchar(3),
						@pnPlanId 			int,
						@nExchRateType			tinyint',
						@prsTableName,
						@sLocalCurrency,
						@sBankCurrency,
						@pnPlanId,
						@nExchRateType
		End
		-- Ensure this is only done when deriving payments for the first time.
		-- DROP TABLE ##TEMPPP2CHRISTINE
		If @nErrorCode = 0
		Begin
			exec @nErrorCode=ap_UpdateLocalDissectionDetails @pnUserIdentityId, @psCulture, @pnPlanId, @prsTableName
		End

		-- For Debugging
		If @pbDebugFlag = 1
		Begin
			Print 'Data Updated'
			Set @sSQLString = "SELECT * FROM " + @prsTableName
			exec @nErrorCode=sp_executesql @sSQLString
		End
	End
End


-- For Debugging
If @pbDebugFlag = 1
Begin
	Print 'Data Inserted'
	select @sSQLString
	Set @sSQLString = "SELECT * FROM " + @prsTableName
	exec @nErrorCode=sp_executesql @sSQLString
End


/*If @pbCalledFromCentura = 1
Begin
	Select @nErrorCode
End
*/

Return @nErrorCode

GO

Grant execute on dbo.ap_ProducePlanPayments to public
GO
