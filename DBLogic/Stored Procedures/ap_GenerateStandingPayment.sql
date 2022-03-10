-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ap_GenerateStandingPayment
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ap_GenerateStandingPayment]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ap_GenerateStandingPayment.'
	Drop procedure [dbo].[ap_GenerateStandingPayment]
End
Print '**** Creating Stored Procedure dbo.ap_GenerateStandingPayment...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ap_GenerateStandingPayment
(
	@pnEntityNo		int		OUTPUT,
	@pnTransNo		int		OUTPUT,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnTemplateNo		int,		-- Mandatory
	@psUserId		nvarchar(30),	-- Mandatory
	@pnEmployeeNo		int,		-- Mandatory
	@pbCalledFromCentura	bit		= 0,
	@pbDebugFlag		tinyint		= 0,
	@psEFTFilePathAndName	nvarchar(254)	= null
)
as
-- PROCEDURE:	ap_GenerateStandingPayment
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions Australia Pty Limited
-- DESCRIPTION:	Generate an Account Payable Manual Payment from details entered for a standing payment transaction.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------		
-- 27 June 2010	CR	10311	1	Procedure created
-- 31 Aug 2010	DL	10311	2	- Handle bank charges.  
--					- If payment/bank/local currency are not the same, use local amount for validating Cr/Dr balance.
-- 22 May 2012	CR	16196	3	Consolidated System Defined Payment Methods
-- 20 Oct 2015  MS      R53933  4       Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE column

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode			int
declare	@sSQLString			nvarchar(4000)
declare	@nTranCountStart 		int
declare	@sAlertXML			nvarchar(400)
declare	@nAcctEntityNo			int
declare	@nAcctCreditorNo		int
declare	@dtTransDate			datetime
declare @dtCurrentDateTime		datetime
Declare @nPostPeriod			int
declare	@sReference			nvarchar(20)
declare	@sDescription			nvarchar(254)
declare	@nPaymentMethod			int
declare	@nCreditCard			int
declare @nBankDraft			int
declare	@nBankCharges			decimal(11,2)
declare	@nSumJournalLineAmt		decimal(11,2)
declare @nTotalPaymentAmt		decimal(11,2)
declare	@nTotalBankAmt			decimal(11,2)
declare	@nTotalCashBankAmt		decimal(11,2)
declare @nTotalLocalPaymentAmt		decimal(11,2)
declare @nTotalLocalTaxAmt		decimal(11,2)
declare	@nTotalLocalTaxableAmt		decimal(11,2)
declare	@nExchRateType			tinyint
declare	@nCreditorNameNo		int
declare	@sPaymentCurrency		nvarchar(3)
declare	@sBankCurrency			nvarchar(3)
declare	@sLocalCurrency			nvarchar(3)
declare	@nEFTFileFormat			int
declare	@sEFTFilePath			nvarchar(254)
declare	@sEFTFilePathAndName		nvarchar(254)
declare @nPaymentTerm			int
declare @nPeriod			int
declare @sPeriodType			nchar(1)
declare @dtItemDueDate			datetime
declare @sPaymentRef			nvarchar(20)


-- Initialise variables
Set @nErrorCode = 0
Set @nCreditorNameNo = NULL
Set @sPaymentCurrency = NULL
set @nCreditCard = -3
set @nBankDraft = -2


Set @nTranCountStart = @@TranCount

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select @nExchRateType = SI.COLBOOLEAN
	from SITECONTROL SI
	where SI.CONTROLID = 'Bank Rate In Use'"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@nExchRateType	tinyint	OUTPUT',
					@nExchRateType=@nExchRateType	OUTPUT

	If @nExchRateType <> 1
	Begin
		--Bank Rate is not in use so use Buy Rate
		Set @nExchRateType = 2
	End

	-- For Debugging
	If @pbDebugFlag = 1
	Begin
		PRINT '-- *** Determine if the Bank Rate should be used ***'
		Select @nExchRateType
	End
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
	PRINT '-- *** Retrieve the Local Currency ***'
	Select @sLocalCurrency
End

If @nErrorCode = 0
Begin

	Set @sSQLString = "SELECT @pnEntityNo = ENTITYNO, @nAcctEntityNo = ENTITYNO, 
	@dtTransDate = NEXTDUEDATE, @sReference = REFERENCE, @sDescription = DESCRIPTION
	FROM STANDINGTEMPLT
	WHERE TEMPLATENO = @pnTemplateNo"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnEntityNo		int		OUTPUT,
					@nAcctEntityNo		int		OUTPUT,
					@dtTransDate		datetime	OUTPUT,
					@sReference		nvarchar(20)	OUTPUT,
					@sDescription		nvarchar(254)	OUTPUT,
					@pnTemplateNo 		int',
					@pnEntityNo		=@pnEntityNo	OUTPUT,
					@nAcctEntityNo		=@nAcctEntityNo	OUTPUT,
					@dtTransDate		=@dtTransDate	OUTPUT,
					@sReference		=@sReference	OUTPUT,
					@sDescription		=@sDescription	OUTPUT,
					@pnTemplateNo		=@pnTemplateNo
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select @sBankCurrency = BA.CURRENCY,
	@sPaymentCurrency = PAYMENTCURRENCY, 
	@nPaymentMethod = STP.PAYMENTMETHOD,
	@nAcctCreditorNo = STP.ACCTNAMENO,
	@nCreditorNameNo = STP.ACCTCREDITORNO,
	@nEFTFileFormat = STP.EFTFILEFORMAT,
	@nBankCharges = STP.BANKCHARGES
	From STANDINGTEMPLTPAY STP
	LEFT Join  	BANKACCOUNT BA	on (BA.ACCOUNTOWNER = STP.ACCOUNTOWNER
					and BA.BANKNAMENO = STP.BANKNAMENO
					and BA.SEQUENCENO = STP.BANKSEQUENCENO)
	Where STP.TEMPLATENO = @pnTemplateNo"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@sBankCurrency		nvarchar(3)	OUTPUT,
				@sPaymentCurrency		nvarchar(3)	OUTPUT,
				@nPaymentMethod			int		OUTPUT,
				@nAcctCreditorNo		int		OUTPUT,
				@nCreditorNameNo		int		OUTPUT,
				@nEFTFileFormat			int		OUTPUT, 
				@nBankCharges			decimal(11,2)	OUTPUT,
				@pnTemplateNo 			int',
				@sBankCurrency=@sBankCurrency			OUTPUT,
				@sPaymentCurrency=@sPaymentCurrency		OUTPUT,
				@nPaymentMethod=@nPaymentMethod			OUTPUT,
				@nAcctCreditorNo=@nAcctCreditorNo		OUTPUT,
				@nCreditorNameNo=@nCreditorNameNo		OUTPUT,
				@nEFTFileFormat=@nEFTFileFormat			OUTPUT,
				@nBankCharges=@nBankCharges			OUTPUT,
				@pnTemplateNo=@pnTemplateNo

	-- For Debugging
	If @pbDebugFlag = 1
	Begin
		PRINT '-- *** Retrieve Payment details ***'
		Select @sBankCurrency as BANKCURRENCY, 
				@nPaymentMethod	as PAYMENTMETHOD,
				@nAcctCreditorNo as ACCOUNTOWNER,
				@nCreditorNameNo as ACCTCREDITORNO,
				@nEFTFileFormat	as EFTFILEFORMAT, 
				@nBankCharges as BANKCHARGES,
				@pnTemplateNo as TEMPLATENO, 
				@nErrorCode as ERRORCODE
	End
End

-- Get item posting period
If @nErrorCode = 0
Begin
	Select @nPostPeriod = dbo.fn_GetPostPeriod(@dtTransDate, 8),  -- 8=AP
	@dtCurrentDateTime = GETDATE()

	Set @nErrorCode=@@Error
End

If @pbDebugFlag = 1
Begin
	PRINT '-- *** Retrieve the Post Period to use ***'
	Select @nPostPeriod, @dtCurrentDateTime
End



BEGIN TRANSACTION

If @nErrorCode = 0
Begin
	Set @sSQLString="Update LASTINTERNALCODE 
	set INTERNALSEQUENCE = INTERNALSEQUENCE + 1 
	where TABLENAME = N'TRANSACTIONHEADER'"
	
	exec @nErrorCode=sp_executesql @sSQLString

	If @pbDebugFlag = 1
	Begin
		PRINT '-- *** LASTINTERNALCODE updated ***'
		Print @sSQLString
		Select @nErrorCode as ERRORCODE
	End
	
End


If @nErrorCode = 0
Begin
	Set @sSQLString="Select @pnTransNo = INTERNALSEQUENCE  
			from LASTINTERNALCODE 
			where TABLENAME = N'TRANSACTIONHEADER'"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTransNo	int	OUTPUT',
					@pnTransNo=@pnTransNo	OUTPUT
	If @pbDebugFlag = 1
	Begin
		PRINT '-- *** Get the TransNo from LASTINTERNALCODE to be used on the TRANSACTIONHEADER added ***'
		Print @sSQLString
		Select @pnTransNo AS TRANSNO, @nErrorCode as ERRORCODE
	End
End


If @nErrorCode = 0
Begin
	Set @sPaymentRef = convert(nvarchar,@pnTransNo) + 'SP'

	If @pbDebugFlag = 1
	Begin
		PRINT '-- *** Payment Ref to be used ***'
		Select @sPaymentRef AS PAYMENTREF, @nErrorCode as ERRORCODE
	End		
End

If @nErrorCode = 0
Begin
	Set @sSQLString="
	Insert into TRANSACTIONHEADER 
	(TRANSNO, ENTITYNO, BATCHNO, EMPLOYEENO, ENTRYDATE, GLSTATUS,
	TRANPOSTDATE, TRANPOSTPERIOD, SOURCE,
	TRANSTATUS, TRANSDATE, TRANSTYPE, USERID, IDENTITYID) 
	values (@pnTransNo, @pnEntityNo, NULL, @pnEmployeeNo, CURRENT_TIMESTAMP, NULL,
	NULL, NULL, 8, 
	0, dbo.fn_DateOnly(@dtTransDate), 702, @psUserId, @pnUserIdentityId)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTransNo 		int,
					@pnEntityNo 		int,
					@pnEmployeeNo		int,
					@dtTransDate		datetime,
					@psUserId		nvarchar(30),
					@pnUserIdentityId	int',
					@pnTransNo,
					@pnEntityNo,
					@pnEmployeeNo,
					@dtTransDate,
					@psUserId,
					@pnUserIdentityId

	If @pbDebugFlag = 1
	Begin
		PRINT '-- *** TRANSACTIONHEADER added for the payment ***'
		Print @sSQLString
		Select @nErrorCode as ERRORCODE
		Select * from TRANSACTIONHEADER WHERE TRANSNO = @pnTransNo
	End
End	

/* TODO -- CREDIT CARD PROCESSING - CREDITORITEM, CREDITORHISTORY */
If @nErrorCode = 0 AND ( @nPaymentMethod = @nCreditCard )
Begin
	If @pbDebugFlag = 1
	Begin
		PRINT '-- *** Process Credit Card payment method ***'
	End

	If @nErrorCode = 0
	Begin
		-- SQA10311DL Create new Account if the supplier's account does not exist.
		-- Note: This step is necessary as CASHHISTORY / CREDITORITEM is referencing this table. 
		If not exists (SELECT 1 FROM ACCOUNT WHERE NAMENO = @nCreditorNameNo AND ENTITYNO = @pnEntityNo)
		Begin	
			INSERT into ACCOUNT (NAMENO, ENTITYNO, BALANCE,  CRBALANCE) 
			VALUES (@nCreditorNameNo, @pnEntityNo, 0, 0)
			Set @nErrorCode = @@ERROR
		End
	End	


	Set @sSQLString="Select @nPaymentTerm = PAYMENTTERMNO	
	FROM STANDINGTEMPLTPAY
	WHERE TEMPLATENO = @pnTemplateNo"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nPaymentTerm	int		OUTPUT,
					@pnTemplateNo 	int',
					@nPaymentTerm	= @nPaymentTerm	OUTPUT,
					@pnTemplateNo	= @pnTemplateNo

	-- If payment term specified determine due date.
	If @nErrorCode = 0 and (@nPaymentTerm IS NOT NULL)
	Begin
		Set @sSQLString = "Select @nPeriod = FREQUENCY, @sPeriodType = PERIODTYPE
		from FREQUENCY	
		where FREQUENCYTYPE = 1 
		and FREQUENCYNO = @nPaymentTerm"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@nPeriod	int		OUTPUT,
					@sPeriodType	nvarchar(1)	OUTPUT,
					@nPaymentTerm	int',
					@nPeriod 	= @nPeriod	OUTPUT,
					@sPeriodType 	= @sPeriodType	OUTPUT,
					@nPaymentTerm	= @nPaymentTerm


		-- determine what the ItemDueDate should be based on the Payment Term specified
		If @nErrorCode = 0
		Begin
			If @sPeriodType = 'D'
			Begin
				Set @dtItemDueDate = DATEADD(day, @nPeriod, @dtTransDate )
			End
			If @sPeriodType = 'W'
			Begin
				Set @dtItemDueDate = DATEADD(Week, @nPeriod, @dtTransDate )
			End
			Else If @sPeriodType = 'M'
			Begin
				Set @dtItemDueDate = DATEADD(Month, @nPeriod, @dtTransDate )
			End
			Else If @sPeriodType = 'Y'
			Begin
				Set @dtItemDueDate = DATEADD(Year, @nPeriod, @dtTransDate )
			End
		End

		-- For Debugging
		If (@nErrorCode = 0) AND (@pbDebugFlag = 1)
		Begin
			PRINT '-- *** Details of Payment Term Specified ***'
			select @nPeriod AS FREQUENCY, @sPeriodType AS PERIODTYPE, @dtItemDueDate AS ITEMDUEDATE, @dtTransDate AS TRANSDATE
		End
	End

	Set @sSQLString="INSERT INTO CREDITORITEM
        (ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTCREDITORNO, DOCUMENTREF, 
	ITEMDATE, ITEMDUEDATE,
	POSTDATE, POSTPERIOD, CLOSEPOSTDATE, CLOSEPOSTPERIOD, 
	ITEMTYPE, EXCHVARIANCE, CURRENCY,
	LOCALPRETAXVALUE
	,LOCALVALUE
	,LOCALTAXAMOUNT
	,FOREIGNVALUE
	,FOREIGNTAXAMT,
	[STATUS], [DESCRIPTION], LONGDESCRIPTION, RESTRICTIONID, RESTNREASONCODE)
	
	Select @pnEntityNo AS TRANSENTITYNO, @pnTransNo AS TRANSNO, @nAcctEntityNo, STP.ACCTCREDITORNO, @sPaymentRef,
	dbo.fn_DateOnly(@dtTransDate) AS ITEMDATE, dbo.fn_DateOnly(@dtItemDueDate) AS ITEMDUEDATE, 
	NULL AS POSTDATE, NULL AS POSTPERIOD, { ts '9999-12-31 00:00:00.000' } AS CLOSEPOSTDATE, '999999' AS CLOSEPOSTPERIOD, 
	7801, 0 AS EXCHVARIANCE, Case when (STP.PAYMENTCURRENCY <> @sLocalCurrency) then STP.PAYMENTCURRENCY else NULL end AS CURRENCY, 

	-- 10311DL ensure 0 is recorded instead of null so that it will not fail pre-condition test
	Case when (STP.PAYMENTCURRENCY <> @sLocalCurrency) then 
		isnull(convert( decimal(11,2), dbo.fn_ConvertCurrency(STP.PAYMENTCURRENCY, NULL, SUM(STT.TAXABLEAMOUNT), @nExchRateType)), 0.00) 
	else
		ISNULL(SUM(STT.TAXABLEAMOUNT), 0.00)
	End AS LOCALPRETAXVALUE,

	Case when (STP.PAYMENTCURRENCY <> @sLocalCurrency)  then 
		convert( decimal(11,2), dbo.fn_ConvertCurrency(STP.PAYMENTCURRENCY, NULL, STP.PAYMENTAMOUNT, @nExchRateType)) 
	else
		STP.PAYMENTAMOUNT
	End AS LOCALVALUE,

	-- 10311DL ensure 0 is recorded instead of null so that it will not fail pre-condition test
	Case when (STP.PAYMENTCURRENCY <> @sLocalCurrency) then 
		isnull(convert( decimal(11,2), dbo.fn_ConvertCurrency(STP.PAYMENTCURRENCY, NULL, SUM(STT.TAXAMOUNT), @nExchRateType)), 0.00) 
	else
		ISNULL(SUM(STT.TAXAMOUNT), 0.00)
	End AS LOCALTAXAMOUNT,
	
	Case when (STP.PAYMENTCURRENCY <> @sLocalCurrency) then 
		STP.PAYMENTAMOUNT
	else
		NULL
	End AS FOREIGNVALUE,

	-- 10311DL ensure 0 is recorded instead of null so that it will not fail pre-condition test
	Case when (STP.PAYMENTCURRENCY <> @sLocalCurrency) then 
		isnull(SUM(STT.TAXAMOUNT), 0.00)
	else
		0.00
	End AS FOREIGNTAXAMT,
	0 AS STATUS, @sDescription, NULL, STP.RESTRICTIONID, STP.RESTNREASONCODE 
	from STANDINGTEMPLTPAY STP
	LEFT JOIN STANDINGTEMPLTTAX STT on (STT.TEMPLATENO = STP.TEMPLATENO)
	where STP.TEMPLATENO = @pnTemplateNo
	GROUP BY STP.TEMPLATENO, STP.ACCTCREDITORNO, STP.PAYMENTCURRENCY, 
	STT.TAXABLEAMOUNT, STP.PAYMENTAMOUNT, STT.TAXAMOUNT, 
	STP.RESTRICTIONID, STP.RESTNREASONCODE"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnEntityNo 		int,
					@pnTransNo		int,
					@nAcctEntityNo		int,
					@sPaymentRef		nvarchar(20),
					@dtTransDate		datetime,
					@dtItemDueDate		datetime,
					@sLocalCurrency		nvarchar(3),
					@nExchRateType		int,
					@sDescription		nvarchar(254),
					@pnTemplateNo		int',
					@pnEntityNo,
					@pnTransNo,
					@nAcctEntityNo,
					@sPaymentRef,
					@dtTransDate,
					@dtItemDueDate,
					@sLocalCurrency,
					@nExchRateType,
					@sDescription,	
					@pnTemplateNo

	If @pbDebugFlag = 1
	Begin
		PRINT '-- ** Insert CREDITORITEM **'
		print @sSQLString
	End

	If @nErrorCode = 0
	Begin
		Set @sSQLString = "Update CREDITORITEM
		SET 	EXCHRATE = 
				Case when CURRENCY <> @sLocalCurrency 
				then
					convert( decimal(11,4), (FOREIGNVALUE / LOCALVALUE))
				else
					NULL
				End,
			LOCALBALANCE = LOCALVALUE,
			FOREIGNBALANCE = FOREIGNVALUE
		WHERE ITEMENTITYNO = @pnEntityNo 
		AND ITEMTRANSNO = @pnTransNo"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@sLocalCurrency	nvarchar(3),
					@pnEntityNo 		int,
					@pnTransNo		int',
					@sLocalCurrency,
					@pnEntityNo,
					@pnTransNo
	End

	Set @sSQLString="INSERT INTO CREDITORHISTORY
        (ITEMENTITYNO,ITEMTRANSNO,ACCTENTITYNO,ACCTCREDITORNO,HISTORYLINENO,DOCUMENTREF,
	TRANSDATE,POSTDATE,POSTPERIOD,TRANSTYPE,MOVEMENTCLASS,COMMANDID,ITEMPRETAXVALUE,
	LOCALTAXAMT,LOCALVALUE,EXCHVARIANCE,FOREIGNTAXAMT,FOREIGNTRANVALUE,REFENTITYNO,
	REFTRANSNO,LOCALBALANCE,FOREIGNBALANCE,FORCEDPAYOUT,CURRENCY,EXCHRATE,[STATUS],
	ASSOCLINENO,ITEMIMPACT,[DESCRIPTION],LONGDESCRIPTION,GLMOVEMENTNO,GLSTATUS,REMITTANCENAMENO)
	SELECT ITEMENTITYNO,ITEMTRANSNO,ACCTENTITYNO,ACCTCREDITORNO,1,DOCUMENTREF,
	ITEMDATE,POSTDATE,POSTPERIOD,712,1,1,LOCALPRETAXVALUE,
	LOCALTAXAMOUNT,LOCALVALUE,EXCHVARIANCE,FOREIGNTAXAMT,FOREIGNVALUE,ITEMENTITYNO, 
	ITEMTRANSNO,LOCALBALANCE,FOREIGNBALANCE,0,CURRENCY,EXCHRATE,[STATUS],
	NULL,1,[DESCRIPTION],LONGDESCRIPTION,NULL,NULL,@nAcctCreditorNo
      	FROM CREDITORITEM CI
	WHERE CI.ITEMENTITYNO = @pnEntityNo
	AND CI.ITEMTRANSNO = @pnTransNo"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnEntityNo 		int,
					@pnTransNo 		int,
					@nAcctCreditorNo	int',
					@pnEntityNo,
					@pnTransNo,
					@nAcctCreditorNo
	
	If @pbDebugFlag = 1
	Begin
		PRINT '-- ** Insert CREDITORHISTORY **'
		print @sSQLString
	End

	If @nErrorCode = 0
	Begin
		Set @sSQLString="Select @nTotalPaymentAmt = ABS(FOREIGNVALUE), 
		@nTotalLocalPaymentAmt = ABS(LOCALVALUE)
		from CREDITORITEM
		WHERE ITEMENTITYNO = @pnEntityNo
		AND ITEMTRANSNO = @pnTransNo"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nTotalPaymentAmt	decimal(11,2)	OUTPUT, 
						@nTotalLocalPaymentAmt	decimal(11,2)	OUTPUT, 
						@pnEntityNo 		int,
						@pnTransNo		int',
						@nTotalPaymentAmt	= @nTotalPaymentAmt		OUTPUT, 
						@nTotalLocalPaymentAmt	= @nTotalLocalPaymentAmt	OUTPUT, 
						@pnEntityNo		= @pnEntityNo,
						@pnTransNo		= @pnTransNo

		If @pbDebugFlag = 1
		Begin
			PRINT '-- *** TOTAL PAYMENTAMOUNT ***'
			Select @nErrorCode as ERRORCODE, @nTotalPaymentAmt AS TOTALPAYMENT, @nTotalLocalPaymentAmt AS TOTALLOCALPAYMENT
		End

	End	
					
	If @pbDebugFlag = 1
	Begin
		PRINT '-- *** Credit Card Purchase recorded ***'
		Select @nErrorCode AS ERRORCODE
		SELECT * 
		FROM CREDITORITEM
		WHERE ITEMENTITYNO = @pnEntityNo
		AND ITEMTRANSNO = @pnTransNo

		SELECT * 
		FROM CREDITORHISTORY
		WHERE ITEMENTITYNO = @pnEntityNo
		AND ITEMTRANSNO = @pnTransNo
	End
End
Else If @nErrorCode = 0
Begin

	If @pbDebugFlag = 1
	Begin
		PRINT '-- *** Process other payment methods ***'
	End


	If @nErrorCode = 0
	Begin
		-- SQA10311DL Create new Account if the supplier's account does not exist.
		-- Note: This step is necessary as CASHHISTORY is referencing this table. 
		If not exists (SELECT 1 FROM ACCOUNT WHERE NAMENO = @nAcctCreditorNo AND ENTITYNO = @pnEntityNo)
		Begin	
			INSERT into ACCOUNT (NAMENO, ENTITYNO, BALANCE,  CRBALANCE) 
			VALUES (@nAcctCreditorNo, @pnEntityNo, 0, 0)
			Set @nErrorCode = @@ERROR
		End
	End	


	
	If @nErrorCode = 0
	Begin
		Set @sSQLString="Insert Into CASHITEM(ENTITYNO, BANKNAMENO, SEQUENCENO, TRANSENTITYNO, TRANSNO, 
		ITEMDATE, DESCRIPTION, STATUS, ITEMTYPE, POSTDATE, 
		POSTPERIOD, CLOSEPOSTDATE, CLOSEPOSTPERIOD, TRADER, 
		ACCTENTITYNO, ACCTNAMENO, BANKEDBYENTITYNO, BANKEDBYTRANSNO, 
		BANKCATEGORY, ITEMBANKBRANCHNO, ITEMREFNO, ITEMBANKNAME, ITEMBANKBRANCH, 
		CREDITCARDTYPE, CARDEXPIRYDATE, PAYMENTCURRENCY, PAYMENTAMOUNT,
		BANKEXCHANGERATE, BANKAMOUNT, BANKCHARGES, BANKNET,
		BANKOPERATIONCODE, DETAILSOFCHARGES, FXDEALERREF, EFTFILEFORMAT, EFTPAYMENTFILE,INSTRUCTIONCODE)
		
		Select STP.ACCOUNTOWNER, STP.BANKNAMENO, STP.BANKSEQUENCENO, @pnEntityNo AS TRANSENTITYNO, @pnTransNo AS TRANSNO, 
		dbo.fn_DateOnly(@dtTransDate) AS ITEMDATE, @sDescription, 0 AS STATUS, STP.PAYMENTMETHOD, NULL AS POSTDATE, 
		NULL AS POSTPERIOD, { ts '9999-12-31 00:00:00.000' } AS CLOSEPOSTDATE, '999999' AS CLOSEPOSTPERIOD, 
		ISNULL(C.CHEQUEPAYEE, CN.NAME+CASE WHEN CN.FIRSTNAME is not NULL THEN ', '+CN.FIRSTNAME END) AS TRADER, 
		@nAcctEntityNo, STP.ACCTNAMENO, @pnEntityNo AS BANKEDBYENTITYNO, @pnTransNo AS BANKEDBYTRANSNO, 
		NULL AS BANKCATEGORY, NULL AS ITEMBANKBRANCHNO, @sPaymentRef AS ITEMREFNO, NULL AS ITEMBANKNAME, NULL AS ITEMBANKBRANCH, 
		NULL AS CREDITCARDTYPE, NULL AS CARDEXPIRYDATE, 
		CASE WHEN ISNULL(STP.PAYMENTCURRENCY,@sLocalCurrency) = @sBankCurrency THEN NULL ELSE ISNULL(STP.PAYMENTCURRENCY,@sLocalCurrency) END AS PAYMENTCURRENCY, 
		CASE WHEN ISNULL(STP.PAYMENTCURRENCY,@sLocalCurrency) = @sBankCurrency THEN NULL ELSE (STP.PAYMENTAMOUNT*-1) END AS PAYMENTAMOUNT, 
		CASE WHEN ISNULL(STP.PAYMENTCURRENCY,@sLocalCurrency) = @sBankCurrency THEN NULL ELSE 
			convert( decimal(11,4), ( STP.PAYMENTAMOUNT / 
			dbo.fn_ConvertCurrency(STP.PAYMENTCURRENCY, @sBankCurrency, STP.PAYMENTAMOUNT, @nExchRateType)) ) 
		END AS BANKEXCHANGERATE, 
		convert( decimal(11,2), dbo.fn_ConvertCurrency(STP.PAYMENTCURRENCY, @sBankCurrency, STP.PAYMENTAMOUNT, @nExchRateType) )*-1 AS BANKAMOUNT, ISNULL(STP.BANKCHARGES, 0),
		convert( decimal(11,2), dbo.fn_ConvertCurrency(STP.PAYMENTCURRENCY, @sBankCurrency, STP.PAYMENTAMOUNT, @nExchRateType)*-1 - ISNULL(STP.BANKCHARGES, 0))AS BANKNET,
		STP.BANKOPERATIONCODE, STP.DETAILSOFCHARGES, NULL, STP.EFTFILEFORMAT, @psEFTFilePathAndName, STP.INSTRUCTIONCODE
		from STANDINGTEMPLTPAY STP
		INNER JOIN CREDITOR C	ON (C.NAMENO = STP.ACCTNAMENO)
		INNER JOIN NAME CN	ON (CN.NAMENO = C.NAMENO)		-- Creditor name
		where STP.TEMPLATENO = @pnTemplateNo"
		
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnEntityNo 		int,
						@pnTransNo		int,
						@dtTransDate		datetime,
						@sDescription		nvarchar(254),
						@nAcctEntityNo		int,
						@sPaymentRef		nvarchar(20),
						@sLocalCurrency		nvarchar(3),
						@sBankCurrency		nvarchar(3),
						@nExchRateType		tinyint,
						@psEFTFilePathAndName	nvarchar(254),
						@pnTemplateNo		int',
						@pnEntityNo,
						@pnTransNo,
						@dtTransDate,
						@sDescription,
						@nAcctEntityNo,
						@sPaymentRef,
						@sLocalCurrency,
						@sBankCurrency,
						@nExchRateType,
						@psEFTFilePathAndName,
						@pnTemplateNo
		
		If @pbDebugFlag = 1
		Begin
			PRINT '-- *** CASHITEM row added for the Payment ***'
			Print @sSQLString

			Select * from CASHITEM 
			WHERE TRANSNO = @pnTransNo
			Select @nErrorCode as ERRORCODE, @pnTransNo as TRANSNO
		End
	End
	
	
	-- Update Local and Dissection details of the standing payment
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "Update CASHITEM 
		SET LOCALAMOUNT =	
			Case when (@sBankCurrency = @sLocalCurrency)
			then
				BANKAMOUNT
			else
				Case when PAYMENTCURRENCY IS NOT NULL 
				then 
					convert( decimal(11,2), dbo.fn_ConvertCurrency(PAYMENTCURRENCY, NULL, PAYMENTAMOUNT, @nExchRateType)) 
				else
					Case when (@sBankCurrency <> @sLocalCurrency)
					then
						convert( decimal(11,2), dbo.fn_ConvertCurrency(@sBankCurrency, NULL, BANKAMOUNT, @nExchRateType)) 
					else
						BANKAMOUNT
					End
				End
			End
		WHERE TRANSENTITYNO = @pnEntityNo 
		AND TRANSNO = @pnTransNo"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@sBankCurrency	nvarchar(3),
					@sLocalCurrency		nvarchar(3),
					@nExchRateType		tinyint,
					@pnEntityNo 		int,
					@pnTransNo		int',
					@sBankCurrency,
					@sLocalCurrency,
					@nExchRateType,
					@pnEntityNo,
					@pnTransNo
	End

	If @nErrorCode = 0
	Begin
		Set @sSQLString = "Update CASHITEM
		SET 	LOCALEXCHANGERATE = 
				Case when @sBankCurrency <> @sLocalCurrency 
				then
					convert( decimal(11,4), (BANKAMOUNT / LOCALAMOUNT))
				else
					NULL
				End,
			LOCALUNALLOCATED = LOCALAMOUNT
		WHERE TRANSENTITYNO = @pnEntityNo 
		AND TRANSNO = @pnTransNo"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@sBankCurrency	nvarchar(3),
					@sLocalCurrency		nvarchar(3),
					@pnEntityNo 		int,
					@pnTransNo		int',
					@sBankCurrency,
					@sLocalCurrency,
					@pnEntityNo,
					@pnTransNo
	End

	If @nErrorCode = 0
	Begin
		Set @sSQLString = "Update CASHITEM 
		SET LOCALCHARGES = Case when LOCALEXCHANGERATE IS NULL
				then
					BANKCHARGES
				else
					ISNULL((BANKCHARGES / LOCALEXCHANGERATE), 0)
				End
		WHERE TRANSENTITYNO = @pnEntityNo 
		AND TRANSNO = @pnTransNo"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnEntityNo	int,
					@pnTransNo	int',
					@pnEntityNo,
					@pnTransNo
	End

	If @nErrorCode = 0
	Begin
		Set @sSQLString = "Update CASHITEM
		SET LOCALNET = LOCALAMOUNT - LOCALCHARGES
		WHERE TRANSENTITYNO = @pnEntityNo 
		AND TRANSNO = @pnTransNo"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@sBankCurrency	nvarchar(3),
					@sLocalCurrency		nvarchar(3),
					@pnEntityNo 		int,
					@pnTransNo		int',
					@sBankCurrency,
					@sLocalCurrency,
					@pnEntityNo,
					@pnTransNo
	End

	If @nErrorCode = 0
	Begin

		Set @sSQLString = "Update CASHITEM
		set DISSECTIONCURRENCY = 
			Case when PAYMENTCURRENCY <> @sLocalCurrency 
			then PAYMENTCURRENCY
			else
				CASE WHEN @sBankCurrency <> @sLocalCurrency 
				then
					@sBankCurrency
				Else
					NULL
				End
			End,
		DISSECTIONAMOUNT = 
			Case when PAYMENTCURRENCY <> @sLocalCurrency 
			then PAYMENTAMOUNT
			else
				CASE WHEN @sBankCurrency <> @sLocalCurrency 
				then
					BANKAMOUNT
				Else
					NULL
				End
			End,
		DISSECTIONUNALLOC = 
			Case when PAYMENTCURRENCY <> @sLocalCurrency 
			then PAYMENTAMOUNT
			else
				CASE WHEN @sBankCurrency <> @sLocalCurrency 
				then
					BANKAMOUNT
				Else
					NULL
				End
			End
		WHERE TRANSENTITYNO = @pnEntityNo 
		AND TRANSNO = @pnTransNo"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@sLocalCurrency	nvarchar(3),
					@sBankCurrency		nvarchar(3),
					@pnEntityNo 		int,
					@pnTransNo		int',
					@sLocalCurrency,
					@sBankCurrency,
					@pnEntityNo,
					@pnTransNo
	End

	If @nErrorCode = 0
	Begin

		Set @sSQLString = "Update CASHITEM 
		set DISSECTIONEXCHANGE = 
			Case when DISSECTIONCURRENCY IS NULL
			then 
				NULL
			else
				convert( decimal(11,4), (DISSECTIONAMOUNT/LOCALAMOUNT))
			End
		WHERE TRANSENTITYNO = @pnEntityNo 
		AND TRANSNO = @pnTransNo"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnEntityNo 		int,
					@pnTransNo		int',
					@pnEntityNo,
					@pnTransNo
	End


	If @nErrorCode = 0
	Begin
		Set @sSQLString="Select @nTotalPaymentAmt = ABS(ISNULL(Case when PAYMENTCURRENCY <> @sLocalCurrency 
			then PAYMENTAMOUNT
			else
				NULL
			End, Case when @sBankCurrency <> @sLocalCurrency 
			then BANKAMOUNT
			else
				NULL
			End)), 
		@nTotalLocalPaymentAmt = ABS(LOCALAMOUNT)
		from CASHITEM
		WHERE TRANSENTITYNO = @pnEntityNo
		AND TRANSNO = @pnTransNo"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nTotalPaymentAmt	decimal(11,2)	OUTPUT, 
						@nTotalLocalPaymentAmt	decimal(11,2)	OUTPUT, 
						@sLocalCurrency		nvarchar(3),
						@sBankCurrency		nvarchar(3),
						@pnEntityNo 		int,
						@pnTransNo		int',
						@nTotalPaymentAmt	= @nTotalPaymentAmt		OUTPUT, 
						@nTotalLocalPaymentAmt	= @nTotalLocalPaymentAmt	OUTPUT, 
						@sLocalCurrency		= @sLocalCurrency,
						@sBankCurrency		= @sBankCurrency,
						@pnEntityNo		= @pnEntityNo,
						@pnTransNo		= @pnTransNo

		If @pbDebugFlag = 1
		Begin
			PRINT '-- *** TOTAL PAYMENTAMOUNT ***'
			Select @nErrorCode as ERRORCODE, @nTotalPaymentAmt AS TOTALPAYMENT, @nTotalLocalPaymentAmt AS TOTALLOCALPAYMENT
		End

	End
		

	If @nErrorCode = 0
	Begin
		Set @sSQLString="Insert into CASHHISTORY(ENTITYNO, BANKNAMENO, SEQUENCENO, TRANSENTITYNO, TRANSNO, 
		HISTORYLINENO, TRANSDATE, POSTDATE, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS, COMMANDID, 
		REFENTITYNO, REFTRANSNO, STATUS, DESCRIPTION, ASSOCIATEDLINENO, ITEMREFNO, ACCTENTITYNO, 
		ACCTNAMENO, GLACCOUNTCODE, DISSECTIONCURRENCY, FOREIGNAMOUNT, 
		DISSECTIONEXCHANGE, LOCALAMOUNT, ITEMIMPACT, GLMOVEMENTNO)
		select  CI.ENTITYNO, CI.BANKNAMENO, CI.SEQUENCENO, CI.TRANSENTITYNO, CI.TRANSNO,
		1 AS HISTORYLINENO, CI.ITEMDATE, CI.POSTDATE, CI.POSTPERIOD, TH.TRANSTYPE, 1 AS MOVEMENTCLASS, 1 AS COMMANDID, 
		CI.TRANSENTITYNO, CI.TRANSNO, CI.STATUS, CI.DESCRIPTION, NULL AS ASSOCIATEDLINENO, CI.ITEMREFNO, CI.ACCTENTITYNO, 
		CI.ACCTNAMENO, NULL AS GLACCOUNTCODE, CI.DISSECTIONCURRENCY AS DISSECTIONCURRENCY, CI.DISSECTIONAMOUNT AS FOREIGNAMOUNT, 
		CI.DISSECTIONEXCHANGE AS DISSECTIONEXCHANGE, CI.LOCALAMOUNT, 1 AS ITEMIMPACT, NULL AS GLMOVEMENTNO  
		from CASHITEM CI
		join TRANSACTIONHEADER TH	on (TH.ENTITYNO = CI.TRANSENTITYNO 
						and TH.TRANSNO = CI.TRANSNO)
		where CI.TRANSENTITYNO = @pnEntityNo
		and CI.TRANSNO = @pnTransNo"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnEntityNo	int,
						@pnTransNo	int',
						@pnEntityNo,
						@pnTransNo

		If @pbDebugFlag = 1
		Begin
			PRINT '-- *** CASHHISTORY row added for the Payment ***'
			Print @sSQLString

			Select * from CASHHISTORY WHERE TRANSNO = @pnTransNo
			Select @nErrorCode as ERRORCODE, @pnTransNo as TRANSNO
		End

	End

	If @nErrorCode = 0 AND 
	( (@nBankCharges IS NOT NULL) AND (@nBankCharges <> 0) ) AND
	( (@nPaymentMethod <> @nCreditCard) AND (@nPaymentMethod <> @nBankDraft) )
	Begin
		INSERT INTO CASHHISTORY(ENTITYNO, BANKNAMENO, SEQUENCENO, TRANSENTITYNO, TRANSNO, 
		HISTORYLINENO, TRANSDATE, POSTDATE, POSTPERIOD, TRANSTYPE, 
		MOVEMENTCLASS, COMMANDID, REFENTITYNO, 
		REFTRANSNO, STATUS, DESCRIPTION, ASSOCIATEDLINENO, ITEMREFNO, ACCTENTITYNO, ACCTNAMENO, GLACCOUNTCODE, 
		DISSECTIONCURRENCY, FOREIGNAMOUNT, DISSECTIONEXCHANGE, LOCALAMOUNT, ITEMIMPACT, GLMOVEMENTNO)
		SELECT  CI.ENTITYNO, CI.BANKNAMENO, CI.SEQUENCENO, CI.TRANSENTITYNO, CI.TRANSNO,
		MAX(CASHHISTORY.HISTORYLINENO) + 1 AS HISTORYLINENO, CI.ITEMDATE, CI.POSTDATE, CI.POSTPERIOD, TH.TRANSTYPE, 
		9 AS MOVEMENTCLASS, 7 AS COMMANDID, CI.TRANSENTITYNO, 
		CI.TRANSNO, CI.STATUS, CI.DESCRIPTION, NULL AS ASSOCIATEDLINENO, CI.ITEMREFNO, CI.ACCTENTITYNO, CI.ACCTNAMENO, 
		NULL AS GLACCOUNTCODE, 
		CI.DISSECTIONCURRENCY AS DISSECTIONCURRENCY, 
		case when CI.DISSECTIONCURRENCY is NOT NULL then CI.BANKCHARGES else null end AS FOREIGNAMOUNT, 
		CI.DISSECTIONEXCHANGE AS DISSECTIONEXCHANGE, (CI.LOCALCHARGES), NULL AS ITEMIMPACT, NULL AS GLMOVEMENTNO

		from CASHITEM CI
		JOIN TRANSACTIONHEADER TH 	on (TH.ENTITYNO = CI.TRANSENTITYNO 
						and TH.TRANSNO = CI.TRANSNO)
		JOIN CASHHISTORY 		on (CASHHISTORY.TRANSENTITYNO = CI.TRANSENTITYNO 
						and CASHHISTORY.TRANSNO = CI.TRANSNO)

		WHERE CI.TRANSENTITYNO = @pnEntityNo
		AND CI.TRANSNO = @pnTransNo

		GROUP BY CI.ENTITYNO, CI.BANKNAMENO, CI.SEQUENCENO, CI.TRANSENTITYNO, CI.TRANSNO,
		CI.ITEMDATE, CI.POSTDATE, CI.POSTPERIOD, TH.TRANSTYPE, 
		CI.TRANSNO, CI.STATUS, CI.DESCRIPTION, CI.ITEMREFNO, CI.ACCTENTITYNO, CI.ACCTNAMENO, 
		CI.BANKCHARGES, CI.DISSECTIONEXCHANGE, CI.LOCALCHARGES, CI.DISSECTIONCURRENCY

		ORDER BY CI.ACCTENTITYNO, CI.ACCTNAMENO, CI.TRANSENTITYNO

		Set @nErrorCode = @@Error

		If @pbDebugFlag = 1
		Begin
			PRINT '-- *** CASHHISTORY added for the remittance ***'
			Select @nErrorCode as ERRORCODE
		End
	End

	If @nErrorCode = 0
	Begin
		-- Payment of an Account is a GLDebit movement
		INSERT INTO CASHHISTORY(ENTITYNO, BANKNAMENO, SEQUENCENO, TRANSENTITYNO, TRANSNO, 
		HISTORYLINENO, TRANSDATE, POSTDATE, POSTPERIOD, TRANSTYPE, 
		MOVEMENTCLASS, COMMANDID, REFENTITYNO, 
		REFTRANSNO, STATUS, DESCRIPTION, ASSOCIATEDLINENO, ITEMREFNO, ACCTENTITYNO, ACCTNAMENO, GLACCOUNTCODE, 
		DISSECTIONCURRENCY, FOREIGNAMOUNT, DISSECTIONEXCHANGE, LOCALAMOUNT, ITEMIMPACT, GLMOVEMENTNO)
		SELECT  CI.ENTITYNO, CI.BANKNAMENO, CI.SEQUENCENO, CI.TRANSENTITYNO, CI.TRANSNO,
		MAX(CASHHISTORY.HISTORYLINENO) + 1 AS HISTORYLINENO, CI.ITEMDATE, CI.POSTDATE, CI.POSTPERIOD, TH.TRANSTYPE, 
		4 AS MOVEMENTCLASS, 5 AS COMMANDID, CI.TRANSENTITYNO, 
		CI.TRANSNO, CI.STATUS, CI.DESCRIPTION, NULL AS ASSOCIATEDLINENO, CI.ITEMREFNO, CI.ACCTENTITYNO, CI.ACCTNAMENO, 
		NULL AS GLACCOUNTCODE, 
		CI.DISSECTIONCURRENCY AS DISSECTIONCURRENCY, (CI.DISSECTIONAMOUNT *-1) AS FOREIGNAMOUNT, 
		CI.DISSECTIONEXCHANGE AS DISSECTIONEXCHANGE, 
		(CI.LOCALAMOUNT *-1), NULL AS ITEMIMPACT, NULL AS GLMOVEMENTNO

		from CASHITEM CI
		JOIN TRANSACTIONHEADER TH 	on (TH.ENTITYNO = CI.TRANSENTITYNO 
						and TH.TRANSNO = CI.TRANSNO)
		JOIN CASHHISTORY 		on (CASHHISTORY.TRANSENTITYNO = CI.TRANSENTITYNO 
						and CASHHISTORY.TRANSNO = CI.TRANSNO)

		WHERE CI.TRANSENTITYNO = @pnEntityNo
		AND CI.TRANSNO = @pnTransNo

		GROUP BY CI.ENTITYNO, CI.BANKNAMENO, CI.SEQUENCENO, CI.TRANSENTITYNO, 
		CI.TRANSNO, CI.ITEMDATE, CI.POSTDATE, CI.POSTPERIOD, 
		TH.TRANSTYPE, CI.TRANSENTITYNO, CI.TRANSNO, CI.STATUS, 
		CI.DESCRIPTION, CI.ITEMREFNO, CI.ACCTENTITYNO, CI.ACCTNAMENO, 
		CI.LOCALAMOUNT, CI.DISSECTIONCURRENCY, CI.DISSECTIONAMOUNT, CI.DISSECTIONEXCHANGE   
		
		ORDER BY CI.ACCTENTITYNO, CI.ACCTNAMENO, CI.TRANSENTITYNO

		Set @nErrorCode = @@Error

		If @pbDebugFlag = 1
		Begin
			PRINT '-- *** CASHHISTORY added for the remittance ***'
			Select @nErrorCode as ERRORCODE
		End
	End

	If @nErrorCode = 0
	Begin
		-- do this because there may not already be a bank history row added for the current bank account
		Set @sSQLString="Insert into BANKHISTORY(ENTITYNO, BANKNAMENO, SEQUENCENO, HISTORYLINENO, TRANSDATE, 
		POSTDATE, POSTPERIOD, PAYMENTMETHOD, WITHDRAWALCHEQUENO, TRANSTYPE, 
		MOVEMENTCLASS, COMMANDID, REFENTITYNO, REFTRANSNO, STATUS, DESCRIPTION, ASSOCLINENO, 
		PAYMENTCURRENCY, PAYMENTAMOUNT, 
		BANKEXCHANGERATE, BANKAMOUNT, BANKCHARGES, BANKNET, 
		LOCALAMOUNT, LOCALCHARGES, LOCALEXCHANGERATE, LOCALNET, 
		BANKCATEGORY, REFERENCE, ISRECONCILED, GLMOVEMENTNO)
		
		Select  CI.ENTITYNO, CI.BANKNAMENO, CI.SEQUENCENO, ISNULL((MAX(BH.HISTORYLINENO) + 1),1) AS HISTORYLINENO, CI.ITEMDATE, 
		CI.POSTDATE, CI.POSTPERIOD, CI.ITEMTYPE, NULL AS WITHDRAWALCHEQUENO, 702, 
		2 AS MOVEMENTCLASS, 3 AS COMMANDID, @pnEntityNo, @pnTransNo, CI.STATUS, 
		CI.DESCRIPTION, 
		NULL AS ASSOCIATEDLINENO, CI.PAYMENTCURRENCY, CI.PAYMENTAMOUNT, 
		CI.BANKEXCHANGERATE, CI.BANKAMOUNT, CI.BANKCHARGES, CI.BANKNET, 
		CI.LOCALAMOUNT, CI.LOCALCHARGES, CI.LOCALEXCHANGERATE, CI.LOCALNET, 
		NULL AS BANKCATEGORY, CI.ITEMREFNO AS REFERENCE, 0 AS ISRECONCILED, NULL AS GLMOVEMENTNO
		from CASHITEM CI
		left join BANKHISTORY BH	on (CI.ENTITYNO = BH.ENTITYNO 
						and CI.BANKNAMENO = BH.BANKNAMENO 
						and CI.SEQUENCENO = BH.SEQUENCENO
						and BH.HISTORYLINENO = (Select MAX(BH2.HISTORYLINENO)
									from BANKHISTORY BH2
									where CI.ENTITYNO = BH2.ENTITYNO 
									and CI.BANKNAMENO = BH2.BANKNAMENO 
									and CI.SEQUENCENO = BH2.SEQUENCENO))

		where CI.TRANSENTITYNO = @pnEntityNo
		and CI.TRANSNO = @pnTransNo

		group by CI.ENTITYNO, CI.BANKNAMENO, CI.SEQUENCENO, CI.TRANSENTITYNO, CI.TRANSNO, CI.STATUS, CI.ITEMTYPE, 
		CI.ITEMDATE, CI.POSTDATE, CI.POSTPERIOD, CI.DESCRIPTION, CI.PAYMENTCURRENCY, CI.PAYMENTAMOUNT, 
		CI.BANKEXCHANGERATE, CI.BANKAMOUNT, CI.BANKCHARGES, CI.BANKNET, CI.LOCALAMOUNT, CI.LOCALCHARGES, 
		CI.LOCALEXCHANGERATE, CI.LOCALNET, CI.ITEMREFNO"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnEntityNo		int,
						@pnTransNo		int',
						@pnEntityNo,
						@pnTransNo


		If @pbDebugFlag = 1
		Begin
			PRINT '-- *** Insert Bank History row for the payment ***'
			Print @sSQLString

			Select @nErrorCode as ERRORCODE, 
			BH.ENTITYNO, BH.BANKNAMENO, BH.SEQUENCENO, BH.HISTORYLINENO, REFTRANSNO, REFENTITYNO 
			from BANKHISTORY BH	
			where BH.REFENTITYNO = @pnEntityNo
			and BH.REFTRANSNO = @pnTransNo
		End
	End

	If @nErrorCode = 0
	Begin
 		Set @sSQLString="Select @nTotalCashBankAmt = SUM(BANKAMOUNT)
		FROM CASHITEM 
		where TRANSENTITYNO = @pnEntityNo 
		AND TRANSNO = @pnTransNo"
		
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nTotalCashBankAmt	decimal(11,2)		OUTPUT,
						@pnEntityNo		int,
						@pnTransNo		int',
						@nTotalCashBankAmt	= @nTotalCashBankAmt	OUTPUT,
						@pnEntityNo		= @pnEntityNo,
						@pnTransNo		= @pnTransNo
	End

	If @nErrorCode = 0
	Begin
		Set @sSQLString="Select @nTotalBankAmt = SUM(BANKAMOUNT)
		from BANKHISTORY 
		where REFENTITYNO = @pnEntityNo 
		and REFTRANSNO = @pnTransNo"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nTotalBankAmt	decimal(11,2)		OUTPUT,
						@pnEntityNo		int,
						@pnTransNo		int',
						@nTotalBankAmt		= @nTotalBankAmt	OUTPUT,
						@pnEntityNo		= @pnEntityNo,
						@pnTransNo		= @pnTransNo

		If @pbDebugFlag = 1
		Begin
			PRINT '-- *** validate CASHITEMS ***'
			print ''
			PRINT '-- *** CASHITEMS ADDED ***'
			Select *
			FROM CASHITEM CI
			where CI.TRANSENTITYNO = @pnEntityNo 
			AND CI.TRANSNO = @pnTransNo

			PRINT '-- *** BANK HISTORY ADDED ***'
			Select *
			from BANKHISTORY BH
			where BH.REFENTITYNO = @pnEntityNo
			AND BH.REFTRANSNO = @pnTransNo
		
			PRINT '-- *** Total Bank Amounts Added ***'
			Select @nTotalCashBankAmt as TOTALCASHBANKAMT, @nTotalBankAmt as TOTALBANKAMT
		End

		If (@nTotalCashBankAmt IS NULL) OR (@nTotalBankAmt IS NULL) OR (@nTotalCashBankAmt <> @nTotalBankAmt)
		Begin
			
			Set @sAlertXML = dbo.fn_GetAlertXML('AC18', 'The Bank Amounts of the Cash Items added do not reconcile to the Bank History row/s added.',
    							null, null, null, null, null)
  			RAISERROR(@sAlertXML, 14, 1)
  			Set @nErrorCode = @@ERROR
		End	
	End
End

If @nErrorCode = 0
Begin
	if exists (select *  
		FROM STANDINGTEMPLTTAX
		WHERE TEMPLATENO = @pnTemplateNo)
	Begin
		If @pbDebugFlag = 1
		Begin
			PRINT '-- *** Add Tax Paid Item ***'
		End

		/*
		Case when (CURRENCY IS NOT NULL) AND (CURRENCY <> @sLocalCurrency) then
			convert( decimal(11,2), dbo.fn_ConvertCurrency(CURRENCY, NULL, TAXABLEAMOUNT, @nExchRateType))  
		else
			TAXABLEAMOUNT
		End AS TAXABLEAMOUNT, 
		Case when CURRENCY IS NOT NULL then
			convert( decimal(11,2), dbo.fn_ConvertCurrency(CURRENCY, NULL, TAXAMOUNT, @nExchRateType))  
		else
			TAXAMOUNT
		End AS TAXAMOUNT
		*/

		Set @sSQLString="INSERT INTO TAXPAIDITEM
		(ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTCREDITORNO, 
		TAXCODE, COUNTRYCODE, TAXRATE, TAXABLEAMOUNT, TAXAMOUNT)
		select @pnEntityNo, @pnTransNo, @nAcctEntityNo, 
		Case When ( @nPaymentMethod = @nCreditCard ) then 
			@nCreditorNameNo	
		else @nAcctCreditorNo end, 
		TAXCODE, COUNTRYCODE, TAXRATE,
		Case when (CURRENCY IS NOT NULL) AND (CURRENCY <> @sLocalCurrency) then
			(TAXABLEAMOUNT/@nTotalPaymentAmt * @nTotalLocalPaymentAmt)
		else
			TAXABLEAMOUNT
		End AS TAXABLEAMOUNT, 
		Case when CURRENCY IS NOT NULL then
			(TAXAMOUNT/@nTotalPaymentAmt * @nTotalLocalPaymentAmt) 
		else
			TAXAMOUNT
		End AS TAXAMOUNT
		from STANDINGTEMPLTTAX
		where TEMPLATENO = @pnTemplateNo"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnEntityNo		int,
						@pnTransNo		int,
						@nAcctEntityNo		int,
						@nPaymentMethod		int,
						@nCreditCard		int,
						@nCreditorNameNo	int,
						@nAcctCreditorNo	int,
						@sLocalCurrency		nvarchar(3),
						@nTotalPaymentAmt	decimal(11,2),
						@nTotalLocalPaymentAmt	decimal(11,2),
						@pnTemplateNo 		int',
						@pnEntityNo,
						@pnTransNo,
						@nAcctEntityNo,
						@nPaymentMethod,
						@nCreditCard,
						@nCreditorNameNo,
						@nAcctCreditorNo,
						@sLocalCurrency,
						@nTotalPaymentAmt,
						@nTotalLocalPaymentAmt,
						@pnTemplateNo 

		If @pbDebugFlag = 1
		Begin
			Print @sSQLString
		End

	
		If @nErrorCode = 0
		Begin
			If @pbDebugFlag = 1
			Begin
				PRINT '-- *** Add Tax Paid History ***'
			End
	
			Set @sSQLString="INSERT INTO TAXPAIDHISTORY
			(ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTCREDITORNO, HISTORYLINENO, 
			TAXCODE, COUNTRYCODE, TAXRATE, TAXABLEAMOUNT, TAXAMOUNT, 
			REFENTITYNO, REFTRANSNO)
			select @pnEntityNo, @pnTransNo, @nAcctEntityNo, 
			Case When ( @nPaymentMethod = @nCreditCard ) then 
				@nCreditorNameNo	
			else @nAcctCreditorNo end, 
			ISNULL((MAX(TPH.HISTORYLINENO) + 1),1) AS HISTORYLINENO,
			STT.TAXCODE, STT.COUNTRYCODE, STT.TAXRATE, 
			Case when (STT.CURRENCY IS NOT NULL) AND (STT.CURRENCY <> @sLocalCurrency) then
				(STT.TAXABLEAMOUNT/@nTotalPaymentAmt * @nTotalLocalPaymentAmt)
			else
				STT.TAXABLEAMOUNT
			End AS TAXABLEAMOUNT, 
			Case when STT.CURRENCY IS NOT NULL then
				(STT.TAXAMOUNT/@nTotalPaymentAmt * @nTotalLocalPaymentAmt) 
			else
				STT.TAXAMOUNT
			End AS TAXAMOUNT,
			@pnEntityNo, @pnTransNo
			from STANDINGTEMPLTTAX	STT
			left join TAXPAIDHISTORY TPH	on (TPH.ITEMENTITYNO = @pnEntityNo 
							and TPH.ITEMTRANSNO = @pnTransNo 
							and TPH.ACCTENTITYNO = @nAcctEntityNo
							and TPH.ACCTCREDITORNO = @nAcctCreditorNo
							and TPH.HISTORYLINENO = (Select MAX(TPH2.HISTORYLINENO)
										from TAXPAIDHISTORY TPH2
										where TPH2.ITEMENTITYNO = TPH.ITEMENTITYNO 
										and TPH2.ITEMTRANSNO = TPH.ITEMTRANSNO
										and TPH2.ACCTENTITYNO = TPH.ACCTENTITYNO 
										and TPH2.ACCTCREDITORNO = TPH.ACCTCREDITORNO ))
			where TEMPLATENO = @pnTemplateNo
			GROUP BY STT.TAXCODE, STT.COUNTRYCODE, STT.TAXRATE, 
			STT.CURRENCY, STT.TAXABLEAMOUNT, STT.TAXAMOUNT
			ORDER BY STT.TAXCODE, STT.COUNTRYCODE, STT.TAXRATE, 
			STT.CURRENCY"

			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnEntityNo		int,
							@pnTransNo		int,
							@nAcctEntityNo		int,
							@nPaymentMethod		int,
							@nCreditCard		int,
							@nCreditorNameNo	int,
							@nAcctCreditorNo	int,
							@sLocalCurrency		nvarchar(3),
							@nTotalPaymentAmt	decimal(11,2),
							@nTotalLocalPaymentAmt	decimal(11,2),
							@pnTemplateNo 		int',
							@pnEntityNo,
							@pnTransNo,
							@nAcctEntityNo,
							@nPaymentMethod,
							@nCreditCard,
							@nCreditorNameNo,
							@nAcctCreditorNo,
							@sLocalCurrency,
							@nTotalPaymentAmt,
							@nTotalLocalPaymentAmt,
							@pnTemplateNo
			If @pbDebugFlag = 1
			Begin
				Print @sSQLString
			End

		End
	End	 
End
	

If @nErrorCode = 0
Begin

	If @pbDebugFlag = 1
	Begin
		PRINT '-- *** Ledger Journal ***'
	End

	-- DL Use local amount for validating the ledger balance
	--Set @sSQLString="Select @nSumJournalLineAmt = Case when (@sPaymentCurrency IS NOT NULL) AND (@sPaymentCurrency <> @sLocalCurrency) then
	--			SUM(FOREIGNAMOUNT) 
	--		else
	--			SUM(LOCALAMOUNT)
	--		end
	--From STANDINGTEMPLTLINE
	--WHERE TEMPLATENO = @pnTemplateNo"
	Set @sSQLString="Select @nSumJournalLineAmt = SUM(LOCALAMOUNT)
	From STANDINGTEMPLTLINE
	WHERE TEMPLATENO = @pnTemplateNo"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@nSumJournalLineAmt	decimal(11,2)	OUTPUT,
				@sPaymentCurrency	nvarchar(3),
				@sLocalCurrency		nvarchar(3),
				@pnTemplateNo		int',
				@nSumJournalLineAmt			OUTPUT,
				@sPaymentCurrency,
				@sLocalCurrency,	
				@pnTemplateNo

	If @pbDebugFlag = 1
	Begin
		PRINT '-- *** Total amount should equal 0 ***'
		Select @nErrorCode AS ERRORCODE, @nSumJournalLineAmt AS SUMDEBITSCREDITS
		PRINT ''
		PRINT '-- *** STANDINGTEMPLTLINE ***' 	 	
		Select * from STANDINGTEMPLTLINE WHERE TEMPLATENO = @pnTemplateNo
	End
End

If @nErrorCode = 0
Begin
	If (@nSumJournalLineAmt = 0)
	Begin
		If @pbDebugFlag = 1
		Begin
			PRINT '-- *** Add Ledger Journal ***'
		End

		Set @sSQLString="Insert into LEDGERJOURNAL(ENTITYNO, TRANSNO, USERID, DESCRIPTION, REFERENCE, 
		REFENTITYNO, REFTRANSNO, STATUS, IDENTITYID)
		select @pnEntityNo, @pnTransNo, dbo.fn_GetUser(), ST.DESCRIPTION, @sPaymentRef, 
		NULL, NULL, 0, @pnUserIdentityId
		from STANDINGTEMPLT ST
		where ST.TEMPLATENO = @pnTemplateNo"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnEntityNo		int,
						@sPaymentRef		nvarchar(20), 
						@pnTransNo		int,
						@pnUserIdentityId	int,
						@pnTemplateNo 		int',
						@pnEntityNo,
						@sPaymentRef,
						@pnTransNo,
						@pnUserIdentityId,
						@pnTemplateNo
	
		If @nErrorCode = 0
		Begin
			If @pbDebugFlag = 1
			Begin
				PRINT '-- *** Add Ledger Lines ***'
			End
	
			/*Case when CURRENCY IS NOT NULL AND (FOREIGNAMOUNT IS NOT NULL) AND (FOREIGNAMOUNT <> 0) then
				convert( decimal(11,2), dbo.fn_ConvertCurrency(CURRENCY, NULL, FOREIGNAMOUNT, @nExchRateType))  
			else
				LOCALAMOUNT
			End AS LOCALAMOUNT*/

			Set @sSQLString="Insert into LEDGERJOURNALLINE(ENTITYNO, TRANSNO, SEQNO, PROFITCENTRECODE, 
			ACCOUNTID, 
			LOCALAMOUNT, 
			FOREIGNAMOUNT, CURRENCY, EXCHRATE, NOTES, ACCTENTITYNO)
			select @pnEntityNo, @pnTransNo, SEQNO, PROFITCENTRECODE, 
				ACCOUNTID, 
			Case when (CURRENCY IS NOT NULL) AND (CURRENCY <> @sLocalCurrency) AND (CURRENCY = @sPaymentCurrency) then
				(FOREIGNAMOUNT/ABS(@nTotalPaymentAmt) * ABS(@nTotalLocalPaymentAmt))
			else
				Case when (CURRENCY IS NOT NULL) AND (CURRENCY <> @sLocalCurrency) AND (CURRENCY = @sBankCurrency) then
					(FOREIGNAMOUNT/ABS(@nTotalBankAmt) * ABS(@nTotalLocalPaymentAmt))
				else
					LOCALAMOUNT
				End 
			End AS LOCALAMOUNT, 
			FOREIGNAMOUNT, CURRENCY,  
			
			Case when (CURRENCY IS NOT NULL) AND (CURRENCY <> @sLocalCurrency) AND (CURRENCY = @sPaymentCurrency) then
				convert( decimal(11,4), (FOREIGNAMOUNT/(FOREIGNAMOUNT/ABS(@nTotalPaymentAmt) * ABS(@nTotalLocalPaymentAmt))))
			else
				Case when (CURRENCY IS NOT NULL) AND (CURRENCY <> @sLocalCurrency) AND (CURRENCY = @sBankCurrency) then
					convert( decimal(11,4), (FOREIGNAMOUNT/(FOREIGNAMOUNT/ABS(@nTotalBankAmt) * ABS(@nTotalLocalPaymentAmt))))
				else
					convert( decimal(11,4), (FOREIGNAMOUNT/LOCALAMOUNT))
				End 
			End AS EXCHRATE,
			NOTES + '' + @sPaymentRef, @nAcctEntityNo
			from STANDINGTEMPLTLINE
			where TEMPLATENO = @pnTemplateNo"

			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnEntityNo		int,
							@pnTransNo		int,
							@sLocalCurrency		nvarchar(3),
							@sPaymentCurrency	nvarchar(3),
							@nTotalPaymentAmt	decimal(11,2),
							@nTotalLocalPaymentAmt	decimal(11,2),
							@sBankCurrency		nvarchar(3),
							@nTotalBankAmt		decimal(11,2),
							@sPaymentRef		nvarchar(20),
							@nAcctEntityNo		int,
							@pnTemplateNo 		int',
							@pnEntityNo,
							@pnTransNo,
							@sLocalCurrency,
							@sPaymentCurrency,
							@nTotalPaymentAmt,
							@nTotalLocalPaymentAmt,
							@sBankCurrency,
							@nTotalBankAmt,
							@sPaymentRef,
							@nAcctEntityNo,
							@pnTemplateNo
		End
	End
	Else
	Begin

		Set @sAlertXML = dbo.fn_GetAlertXML('AC19', 'The total debit value must match the total credit value for the journal.',
					null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR

		If @pbDebugFlag = 1
		Begin
			PRINT '-- *** Journal is invalid ***'
			print @nErrorCode
		End
	End
End

If @nErrorCode = 0
Begin
	Set @sSQLString="Select @nSumJournalLineAmt = SUM(LOCALAMOUNT)
	From LEDGERJOURNALLINE
	WHERE ENTITYNO = @pnEntityNo
	AND TRANSNO = @pnTransNo"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@nSumJournalLineAmt	decimal(11,2)	OUTPUT,
				@pnEntityNo		int,
				@pnTransNo		int',
				@nSumJournalLineAmt			OUTPUT,
				@pnTransNo,
				@pnEntityNo		

	If @pbDebugFlag = 1
	Begin
		PRINT '-- *** Total amount should equal 0 ***'
		Select @nErrorCode AS ERRORCODE, @nSumJournalLineAmt AS SUMDEBITSCREDITS
		PRINT ''
		PRINT '-- *** LEDGERJOURNALLINE ***'
		Select * from LEDGERJOURNALLINE WHERE ENTITYNO = @pnEntityNo AND TRANSNO = @pnTransNo
	End
End

If @nErrorCode = 0
Begin
	If (@nSumJournalLineAmt <> 0)
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('AC19', 'The total debit value must match the total credit value for the journal.',
					null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR

		If @pbDebugFlag = 1
		Begin
			PRINT '-- *** Journal is invalid ***'
			Select @nErrorCode AS ERRORCODE, @nSumJournalLineAmt AS SUMDEBITSCREDITS
		End
	End
End

If @@TranCount > @nTranCountStart
Begin
	If @nErrorCode = 0
	Begin	
		If @pbDebugFlag = 1
		Begin
			PRINT '-- *** template payment details ***'
			SELECT * FROM STANDINGTEMPLTPAY
			WHERE TEMPLATENO = @pnTemplateNo
			
			PRINT '-- *** template payment tax details ***'
			SELECT * FROM STANDINGTEMPLTTAX
			WHERE TEMPLATENO = @pnTemplateNo
			
			PRINT '-- *** DETAILS TO BE SAVED ***'
			PRINT '-- *** TRANSACTIONHEADER ***'
			SELECT * 
			FROM TRANSACTIONHEADER
			WHERE TRANSNO = @pnTransNo
			
			If ( @nPaymentMethod = @nCreditCard )
			Begin
				PRINT '-- *** CREDITORITEM ***'
				SELECT * 
				FROM CREDITORITEM
				WHERE ITEMTRANSNO = @pnTransNo -- Credit Card Payments

				PRINT 'CREDITORHISTORY'
				SELECT * 
				FROM CREDITORHISTORY
				WHERE ITEMTRANSNO = @pnTransNo -- Credit Card Payments
			End
			Else
			Begin
				PRINT '-- *** CASHITEM ***'
				SELECT * 
				FROM CASHITEM CI
				WHERE CI.TRANSNO = @pnTransNo
				
				PRINT '-- *** CASHHISTORY ***'
				SELECT * 
				FROM CASHHISTORY CH
				WHERE CH.TRANSNO = @pnTransNo

				PRINT '-- *** BANKHISTORY ***'
				SELECT * 
				FROM BANKHISTORY
				WHERE REFTRANSNO = @pnTransNo
			End

			PRINT '-- ** TAXPAIDITEM **'
			SELECT *
			FROM TAXPAIDITEM
			WHERE ITEMTRANSNO = @pnTransNo

			PRINT '-- ** TAXPAIDHISTORY ***'
			SELECT * 
			FROM TAXPAIDHISTORY
			WHERE ITEMTRANSNO = @pnTransNo

			PRINT '-- *** LEDGERJOURNAL ***'
			SELECT * 
			FROM LEDGERJOURNAL
			WHERE TRANSNO = @pnTransNo

			PRINT '-- ** LEDGERJOURNALLINE ***'
			SELECT *
			FROM LEDGERJOURNALLINE
			WHERE TRANSNO = @pnTransNo
			
			ROLLBACK TRANSACTION
			PRINT '-- *** Transaction Rolled Back NO ERRORS occurred ***'

		End
		Else
		Begin
			COMMIT TRANSACTION
		End
	End
	Else 
	begin
		ROLLBACK TRANSACTION
		
		If @pbDebugFlag = 1
			PRINT '-- *** Transaction Rolled Back ***'
	End
End


If @pbCalledFromCentura = 1
Begin
	Select @pnEntityNo as EntityNo, @pnTransNo as TransNo
End

Return @nErrorCode
GO

Grant execute on dbo.ap_GenerateStandingPayment to public
GO
