-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ap_ProcessPaymentPlan
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ap_ProcessPaymentPlan]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ap_ProcessPaymentPlan.'
	Drop procedure [dbo].[ap_ProcessPaymentPlan]
End
Print '**** Creating Stored Procedure dbo.ap_ProcessPaymentPlan...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ap_ProcessPaymentPlan
(
	@pnUserIdentityId		int		= null,
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura 		tinyint 	= 0,
	@pbDebugFlag	 		tinyint 	= 0,
	@psBankHistoryReference		nvarchar(30)	= null,
	@pnBankCharges			decimal(9,2)	= null,
	@psBankHistoryDescription	nvarchar(254)	= null,
	@pnEFTFileFormat		int		= null,
	@psEFTFilePathAndName		nvarchar(254)	= null,
	@pnPlanId			int,
	@psTableName			nvarchar(32),
	@psUserId			nvarchar(30),
	@pnEmployeeNo			int,
	@pdtPaymentDate			datetime
)
as
-- PROCEDURE:	ap_ProcessPaymentPlan
-- VERSION:	21
-- SCOPE:	InPro
-- DESCRIPTION:	Called from Centura to process a payment plan in Accounts Payable
-- COPYRIGHT: 	Copyright 1993 - 2012 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 29-Sept-2003 CR	8816	1.00	Procedure created
-- 09-Dec-2003	CR	8817	1.01	Fixed Single Withdrawal and exchange variance bugs
-- 10-Dec-2003	CR	8817	1.02	Fixed more bugs
-- 12-Dec-2003	CR	8817	1.03	Added additional checks for employee no and Cash Bank amount
--					To Bank History Bank Amount.
-- 12-Dec-2003	CR	8817	1.04	Instead of retrieving EmployeeNo here this and the 
--					User Id are now passed in.
-- 15-Dec-2003	CR	8816	1.05	Changed where fnConvertCurrency is called - if being 
--					used in another equation don't convert until the end result 
--					has been derived.
-- 23-Jan-2004	CR	9558	1.06	Fixed the setting of the Exchange Rate for Creditor History rows.
-- 28-Feb-2004	SS	9297	1.07	Incorporated bank rate.
-- 01-Mar-2004	CR	9558	1.08	Modified to incorporate remainder calculations in the remittance.
-- 28-Apr-2004	CR	8784	9	Extended to include saving of EFT File data.
--					Fixed bug where the consume CASHHISTORY row was being recorded with the 
--					wrong movement class and command id.
-- 14-Oct-2004	CR	10081	10	Extended to record the F/X Dealer Reference on the CASHITEM.
-- 22-Oct-2004	CR	10081	11	Fixed bugs
-- 23-Mar-2005	CR	10146	12	Logic to unlock CREDITORITEMs and update the DATEPROCESSED for the plan 
--					will be removed. This will now be done as a part of posting.	
-- 03-Jun-2005	CR	10146	13	Fixed bugs with Exchange Variance.
-- 16-Nov-2005	vql	9704	14	When updating TRANSACTIONHEADER table insert @pnUserIdentityId.
-- 13-Oct-2006	CR	11936	15	Extended to include payment date and to standardise RAISERROR logic.
-- 16-Oct-2008	CR	10514	16	Extended to cater for Cash Accounting
-- 05-Jun-2009	AC	15555	17	Set up SWIFT Instruction Codes in Inprotech.  e.g. CHQB, HOLD, PHON etc.
-- 10 Sep 2009	CR	SQA8819	18	Updated joins to CREDITORITEM and CREDITORHISTORY to cater for
--								Unallocated Payments recorded using the Credit Card method 
--								(i.e. two Creditor Items created with the same TransId)
-- 28-Dec-2009	CR	18320	19	Extended to include PaymentDate as a parameter
-- 16 May 2012	CR	16196	20	Consolidate System Defined Payment Methods - update references.
-- 28 Nov 2013	DL	21641	21	Bulk Payment is very slow when producing payments or finalising a payment plan


/*-- for Debugging

SET QUOTED_IDENTIFIER OFF
SET ANSI_NULLS ON

Declare	@pnUserIdentityId	int,
	@psCulture		nvarchar(10),
	@psReference		nvarchar(30),
	@pnBankCharges		decimal(9,2),
	@psDescription		nvarchar(254),
	@pnPlanId		int,
	@psTableName		nvarchar(32)

SET @pnPlanId = 1
SET @psTableName = '##TEMPPP1CHRISTINE'
*/

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 			int,
--	@nEmployeeNo			int,
	@nSequenceNo			int,
	@nEntityNo			int,
	@nTransNo			int,
	@nAcctEntityNo			int,
	@nAcctCreditorNo		int,
	@sItemCurrency			nvarchar(3),
	@nPaymentMethod			int,
	@nBankDraft			int,
	@sSQLString			nvarchar(4000),
	@nTranCountStart 		int,
	@nTotalBankAmount		decimal(11,2),
	@nTotalCashBankAmount		decimal(11,2),
	@nTotalPaymentAmount		decimal(11,2),  -- in currency of the payment - only necessary if the payment is not in local currency
	@nTotalLocalPaymentAmount	decimal(11,2),
	@nTotalLocalCreditorHistory	decimal(11,2),
	@nRemainder			decimal(11,2),
	@nExchRateType			tinyint,
	@sAlertXML			nvarchar(400)

Set @nErrorCode = 0
Set @nSequenceNo = NULL
-- Set @nEmployeeNo = NULL
Set @nBankDraft = -2


Set @nTranCountStart = @@TranCount

BEGIN TRANSACTION

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
		PRINT '*** Determine if the Bank Rate should be used ***'
		Select @nExchRateType
	End
End

If @nErrorCode = 0
Begin
	Set @sSQLString="Select @nPaymentMethod = PAYMENTMETHOD
	from PAYMENTPLAN
	where PLANID = @pnPlanId"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nPaymentMethod		int	OUTPUT,
					@pnPlanId			int',
					@nPaymentMethod=@nPaymentMethod		OUTPUT,
					@pnPlanId=@pnPlanId

	If @pbDebugFlag = 1
	Begin
		print '*** Payment Method Retrieved ***'
		-- Print @sSQLString
		Select @nPaymentMethod as PAYMENTMETHOD, @nErrorCode as ERRORCODE
	End
End


/* SQA10146 - No longer required.
If @nErrorCode = 0
Begin
	if (@nPaymentMethod = -11)
	Begin
		EXEC @nErrorCode = dbo.ap_ProducePlanPayments @pnUserIdentityId, @psCulture, 0, @pbDebugFlag, @psTableName, @pnPlanId
	End

End
*/

If @nErrorCode = 0
Begin
	Set @sSQLString=" 
	Select @nSequenceNo=min(SEQUENCE)
	from " + @psTableName + "
	where SEQUENCE is not null"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nSequenceNo			int	OUTPUT',
					@nSequenceNo=@nSequenceNo		OUTPUT

End

-- Process the current payment
While @nSequenceNo is not null
and   @nErrorCode = 0
Begin
	If @pbDebugFlag = 1
	Begin
		 print '*** Min sequenceNo Retrieved ***'
		Select @nSequenceNo AS SEQUENCENO, @nErrorCode as ERRORCODE
	End

	If @nErrorCode = 0
	Begin

		Set @sSQLString = "Select @nEntityNo=ENTITYNO, @nAcctEntityNo=ACCTENTITYNO, 
		@nAcctCreditorNo=ACCTNAMENO, @sItemCurrency = ITEMCURRENCY
		from " + @psTableName + "
		where SEQUENCE = @nSequenceNo"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nEntityNo		int		OUTPUT,
						@nAcctEntityNo		int		OUTPUT,
						@nAcctCreditorNo	int		OUTPUT,
						@sItemCurrency		nvarchar(3)	OUTPUT,
						@nSequenceNo		int',
						@nEntityNo=@nEntityNo			OUTPUT,
						@nAcctEntityNo=@nAcctEntityNo		OUTPUT,
						@nAcctCreditorNo=@nAcctCreditorNo	OUTPUT,
						@sItemCurrency=@sItemCurrency		OUTPUT,
						@nSequenceNo=@nSequenceNo
		

		If @pbDebugFlag = 1
		Begin
			Print '*** Retrieve key info for current payment row ***'
			-- Print @sSQLString
			Select @nEntityNo as ENTITYNO, @nAcctEntityNo as ACCTENTITYNO, 
				@nAcctCreditorNo as ACCTNAMENO, @sItemCurrency as ITEMCURRENCY
		End
		
	End


	If @nErrorCode = 0
	Begin
		Set @sSQLString="Update  LASTINTERNALCODE 
		set INTERNALSEQUENCE = INTERNALSEQUENCE + 1 
		where TABLENAME = N'TRANSACTIONHEADER'"
		
		exec @nErrorCode=sp_executesql @sSQLString
	
		If @pbDebugFlag = 1
		Begin
			print '*** LASTINTERNALCODE updated ***'
			-- Print @sSQLString
			Select @nErrorCode as ERRORCODE
		End
		
	End


	If @nErrorCode = 0
	Begin
		Set @sSQLString="Select @nTransNo = INTERNALSEQUENCE  
				from LASTINTERNALCODE 
				where TABLENAME = N'TRANSACTIONHEADER'"
		
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nTransNo	int	OUTPUT',
						@nTransNo=@nTransNo	OUTPUT
		If @pbDebugFlag = 1
		Begin
			Print '*** Get the TransNo from LASTINTERNALCODE to be used on the TRANSACTIONHEADER added ***'
			-- Print @sSQLString
			Select @nTransNo AS TRANSNO, @nErrorCode as ERRORCODE
		End
	End


	If @nErrorCode = 0
	Begin
-- dbo.fn_GetUser()
		Set @sSQLString="
		Insert into TRANSACTIONHEADER 
		(TRANSNO, ENTITYNO, BATCHNO,
		EMPLOYEENO, ENTRYDATE, GLSTATUS,
		TRANPOSTDATE, TRANPOSTPERIOD, SOURCE,
		TRANSTATUS, TRANSDATE, TRANSTYPE, USERID, IDENTITYID) 
		values (@nTransNo, @nEntityNo, 999,
		@pnEmployeeNo, CURRENT_TIMESTAMP, NULL,
		NULL, NULL, 8, 
		0, dbo.fn_DateOnly(@pdtPaymentDate), 704, @psUserId, @pnUserIdentityId)"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nTransNo 	int,
						@nEntityNo 	int,
						@pnEmployeeNo	int,
						@pdtPaymentDate datetime,
						@psUserId	nvarchar(30),
						@pnUserIdentityId int',
						@nTransNo,
						@nEntityNo,
						@pnEmployeeNo,
						@pdtPaymentDate,
						@psUserId,
						@pnUserIdentityId = @pnUserIdentityId	

		If @pbDebugFlag = 1
		Begin
			Print '*** TRANSACTIONHEADER added for the payment ***'
			-- Print @sSQLString
			Select @nErrorCode as ERRORCODE
			Select * from TRANSACTIONHEADER WHERE TRANSNO = @nTransNo
		End
	End	


	
	If @nErrorCode = 0
	Begin
		-- 15555
		Set @sSQLString="Insert Into CASHITEM(ENTITYNO, BANKNAMENO, SEQUENCENO, TRANSENTITYNO, TRANSNO, 
		ITEMDATE, DESCRIPTION, STATUS, ITEMTYPE, POSTDATE, 
		POSTPERIOD, CLOSEPOSTDATE, CLOSEPOSTPERIOD, TRADER, 
		ACCTENTITYNO, ACCTNAMENO, BANKEDBYENTITYNO, BANKEDBYTRANSNO, 
		BANKCATEGORY, ITEMBANKBRANCHNO, ITEMREFNO, ITEMBANKNAME, ITEMBANKBRANCH, 
		CREDITCARDTYPE, CARDEXPIRYDATE, 
		PAYMENTCURRENCY, PAYMENTAMOUNT, BANKEXCHANGERATE, 
		BANKAMOUNT, BANKCHARGES, BANKNET, 
		DISSECTIONCURRENCY, DISSECTIONAMOUNT, DISSECTIONUNALLOC, DISSECTIONEXCHANGE, 
		LOCALAMOUNT, LOCALCHARGES, LOCALEXCHANGERATE, LOCALNET, LOCALUNALLOCATED, 
		BANKOPERATIONCODE, DETAILSOFCHARGES, FXDEALERREF, EFTFILEFORMAT, EFTPAYMENTFILE,INSTRUCTIONCODE)
		Select TTP.ENTITYNO, TTP.BANKNAMENO, TTP.BANKSEQUENCENO, @nEntityNo AS TRANSENTITYNO, @nTransNo AS TRANSNO, 
		dbo.fn_DateOnly(@pdtPaymentDate) AS ITEMDATE, TTP.[DESCRIPTION], 0 AS STATUS, TTP.ITEMTYPE, NULL AS POSTDATE, 
		NULL AS POSTPERIOD, { ts '9999-12-31 00:00:00.000' }AS CLOSEPOSTDATE, '999999' AS CLOSEPOSTPERIOD, TTP.TRADER, TTP.ACCTENTITYNO, 
		TTP.ACCTNAMENO, NULL AS BANKEDBYENTITYNO, NULL AS BANKEDBYTRANSNO, 
		NULL AS BANKCATEGORY, NULL AS ITEMBANKBRANCHNO, TTP.ITEMREFNO, NULL AS ITEMBANKNAME, NULL AS ITEMBANKBRANCH, 
		NULL AS CREDITCARDTYPE, NULL AS CARDEXPIRYDATE, 
		TTP.PAYMENTCURRENCY, TTP.PAYMENTAMOUNT, TTP.BANKEXCHANGERATE, 
		TTP.BANKAMOUNT, TTP.BANKCHARGES, TTP.BANKNET, 
		TTP.DISSECTIONCURRENCY, TTP.DISSECTIONAMOUNT, TTP.DISSECTIONUNALLOC, TTP.DISSECTIONEXCHANGE, 
		TTP.LOCALAMOUNT, TTP.LOCALCHARGES, TTP.LOCALEXCHANGERATE, TTP.LOCALNET, TTP.LOCALUNALLOCATED, 
		TTP.BANKOPERATIONCODE, TTP.DETAILSOFCHARGES, TTP.FXDEALERREF, @pnEFTFileFormat, @psEFTFilePathAndName,INSTRUCTIONCODE
		from " + @psTableName + " TTP
		where TTP.SEQUENCE = @nSequenceNo"
		
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nEntityNo 		int,
						@nTransNo		int,
						@pdtPaymentDate		datetime,
						@pnEFTFileFormat	int,
						@psEFTFilePathAndName	nvarchar(254),
						@psTableName		nvarchar(32),
						@nSequenceNo		int',
						@nEntityNo,
						@nTransNo,
						@pdtPaymentDate,
						@pnEFTFileFormat,
						@psEFTFilePathAndName,
						@psTableName,
						@nSequenceNo

		
		If @pbDebugFlag = 1
		Begin
			PRINT '*** CASHITEM row added for the Payment ***'
			Select * from CASHITEM 
			WHERE TRANSNO = @nTransNo
			-- Print @sSQLString
			Select @nErrorCode as ERRORCODE, @nTransNo as TRANSNO
		End

	End

	If @nErrorCode = 0
	Begin
		Set @sSQLString="Select @nTotalPaymentAmount = ABS(ISNULL( ISNULL(PAYMENTAMOUNT, BANKAMOUNT), 1)), 
		@nTotalLocalPaymentAmount = ABS(LOCALAMOUNT)
		from CASHITEM
		WHERE TRANSENTITYNO = @nEntityNo
		AND TRANSNO = @nTransNo"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nTotalPaymentAmount		decimal(11,2)	OUTPUT, 
						@nTotalLocalPaymentAmount	decimal(11,2)	OUTPUT, 
						@nEntityNo 			int,
						@nTransNo			int',
						@nTotalPaymentAmount=@nTotalPaymentAmount		OUTPUT, 
						@nTotalLocalPaymentAmount=@nTotalLocalPaymentAmount	OUTPUT, 
						@nEntityNo=@nEntityNo,
						@nTransNo=@nTransNo


		If @pbDebugFlag = 1
		Begin
			PRINT '*** TOTAL PAYMENTAMOUNT ***'
			-- Print @sSQLString
			Select @nErrorCode as ERRORCODE, @nTotalPaymentAmount AS TOTALPAYMENT, @nTotalLocalPaymentAmount AS TOTALLOCALPAYMENT
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
	
		where CI.TRANSENTITYNO = @nEntityNo
		and CI.TRANSNO = @nTransNo"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nEntityNo	int,
						@nTransNo	int',
						@nEntityNo,
						@nTransNo

		If @pbDebugFlag = 1
		Begin
			Print '*** CASHHISTORY row added for the Payment ***'
			Select * from CASHHISTORY WHERE TRANSNO = @nTransNo
			Select @nErrorCode as ERRORCODE, @nTransNo as TRANSNO
		End
	
	End
	
		
	If @nErrorCode = 0
	Begin
		If (@nPaymentMethod <> @nBankDraft)
		Begin
			EXEC @nErrorCode = ap_PlanRecordWithdrawal	@nTransNo OUTPUT, @pnUserIdentityId, @psCulture, @pbCalledFromCentura, @pbDebugFlag, @nEntityNo, 
									@psBankHistoryReference, @pnBankCharges, @psBankHistoryDescription, @pnPlanId, 
									@pnEmployeeNo, @psUserId, @pdtPaymentDate


			If @pbDebugFlag = 1
			Begin
				Print '*** BANKHISTORY row for the withdrawal per payment ***'
				Select @nErrorCode as ERRORCODE, @nEntityNo AS ENTITYNO, @nTransNo AS TRANSNO
			End
		End
	End
	
	If @nErrorCode = 0
	Begin
		If @sItemCurrency IS NULL
		Begin
		
			If @pbDebugFlag = 1
			Begin
				Print '*** Item Currency is NULL ***'	
			End		
			INSERT INTO CREDITORHISTORY (ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTCREDITORNO, 
			HISTORYLINENO, DOCUMENTREF, TRANSDATE, 
			POSTDATE, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS, COMMANDID, ITEMPRETAXVALUE, LOCALTAXAMT, LOCALVALUE, EXCHVARIANCE, FOREIGNTAXAMT, 
			FOREIGNTRANVALUE, REFENTITYNO, REFTRANSNO, LOCALBALANCE, FOREIGNBALANCE, FORCEDPAYOUT, CURRENCY, EXCHRATE, STATUS, ASSOCLINENO, 
			ITEMIMPACT, DESCRIPTION, LONGDESCRIPTION, GLMOVEMENTNO, GLSTATUS) 
			Select CH.ITEMENTITYNO, CH.ITEMTRANSNO, CH.ACCTENTITYNO, CH.ACCTCREDITORNO,
			max(CH.HISTORYLINENO)+1 AS HISTORYLINENO, CH.DOCUMENTREF, dbo.fn_DateOnly(@pdtPaymentDate) AS TRANSDATE, 
			NULL AS POSTDATE, NULL AS POSTPERIOD, 704 AS TRANSTYPE, 2 AS MOVEMENTCLASS, 3 AS COMMANDID, 
			0 AS ITEMPRETAXVALUE, 0 AS LOCALTAXAMT, 
-- 			it has already been established that CH.CURRENCY IS NULL
--			convert( decimal(11,2), dbo.fn_ConvertCurrency(CH.CURRENCY, NULL, SUM(PPD.PAYMENTAMOUNT), @nExchRateType))*-1 AS LOCALVALUE, 
			(PPD.PAYMENTAMOUNT*-1) AS LOCALVALUE, 
			dbo.fn_CalcExchangeVariance( CH.LOCALBALANCE,
				CH.FOREIGNBALANCE,
				CH.EXCHRATE,
				CH.CURRENCY,
				convert( decimal(11,2), dbo.fn_ConvertCurrency(CH.CURRENCY, NULL, SUM(PPD.PAYMENTAMOUNT), @nExchRateType)),
				CASE WHEN CH.CURRENCY IS NULL THEN NULL ELSE PPD.PAYMENTAMOUNT END,
				C.BUYRATE,
				CH.CURRENCY,
				0) AS EXCHVARIANCE, 
			CASE WHEN CH.CURRENCY IS NULL THEN NULL ELSE 0 END AS FOREIGNTAXAMT, 
-- 			it has already been established that CH.CURRENCY IS NULL
--			CASE WHEN CH.CURRENCY IS NULL THEN NULL ELSE (SUM(PPD.PAYMENTAMOUNT) * -1) END AS FOREIGNTRANVALUE,
			NULL AS FOREIGNTRANVALUE,
			@nEntityNo AS REFENTITYNO, @nTransNo AS REFTRANSNO, 
-- 			it has already been established that CH.CURRENCY IS NOT NULL
--			convert( decimal(11,2), (CH.LOCALBALANCE - dbo.fn_ConvertCurrency(CH.CURRENCY, NULL, SUM(PPD.PAYMENTAMOUNT), @nExchRateType))) AS LOCALBALANCE, 
--			CASE WHEN CH.CURRENCY IS NULL THEN NULL ELSE (CH.FOREIGNBALANCE - PPD.PAYMENTAMOUNT) END AS FOREIGNBALANCE, 
--			(CH.LOCALBALANCE - PPD.PAYMENTAMOUNT) AS LOCALBALANCE, 
			LOCALBALANCE, 
			NULL AS FOREIGNBALANCE, 
			0 AS FORCEDPAYOUT, CH.CURRENCY, 
--C.BUYRATE precondition of posting is that the exchange rate recorded here is the same as the Item
			CH.EXCHRATE, 0 AS STATUS, NULL AS ASSOCLINENO, 
			NULL AS ITEMIMPACT, NULL AS DESCRIPTION, NULL AS LONGDESCRIPTION, NULL AS GLMOVEMENTNO, NULL AS GLSTATUS
		
			from PAYMENTPLANDETAIL PPD
			join CREDITORHISTORY CH	on (PPD.ITEMENTITYNO = CH.ITEMENTITYNO
						and PPD.ITEMTRANSNO = CH.ITEMTRANSNO
						and PPD.ACCTENTITYNO = CH.ACCTENTITYNO
						and PPD.ACCTCREDITORNO = CH.ACCTCREDITORNO)
			left join CURRENCY C		on (C.CURRENCY = CH.CURRENCY)
	
			where PPD.PLANID = @pnPlanId  
			and CH.ACCTENTITYNO = @nAcctEntityNo 
			and CH.ACCTCREDITORNO = @nAcctCreditorNo
			and CH.CURRENCY IS NULL
			and CH.HISTORYLINENO = (Select MAX(CRH2.HISTORYLINENO)
								from CREDITORHISTORY CRH2
								where CH.ITEMENTITYNO = CRH2.ITEMENTITYNO 
								and CH.ITEMTRANSNO = CRH2.ITEMTRANSNO
								and CH.ACCTENTITYNO = CRH2.ACCTENTITYNO
								and CH.ACCTCREDITORNO = CRH2.ACCTCREDITORNO)
	
			group by CH.ACCTENTITYNO, CH.ACCTCREDITORNO, CH.ITEMENTITYNO, CH.ITEMTRANSNO, 
			CH.DOCUMENTREF, PPD.PAYMENTAMOUNT, CH.CURRENCY, CH.EXCHRATE,
			CH.LOCALBALANCE, CH.ITEMIMPACT, CH.DESCRIPTION, C.BUYRATE, CH.FOREIGNBALANCE     
		
			order by CH.ACCTENTITYNO, CH.ACCTCREDITORNO, CH.ITEMENTITYNO
		End
		Else
		Begin

			If @pbDebugFlag = 1
			Begin
				Print '*** Item Currency is NOT NULL ***'	
				Select @sItemCurrency as ITEMCURRENCY
			End

			INSERT INTO CREDITORHISTORY (ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTCREDITORNO, 
			HISTORYLINENO, DOCUMENTREF, TRANSDATE, 
			POSTDATE, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS, COMMANDID, ITEMPRETAXVALUE, LOCALTAXAMT, LOCALVALUE, EXCHVARIANCE, FOREIGNTAXAMT, 
			FOREIGNTRANVALUE, REFENTITYNO, REFTRANSNO, LOCALBALANCE, FOREIGNBALANCE, FORCEDPAYOUT, CURRENCY, EXCHRATE, STATUS, ASSOCLINENO, 
			ITEMIMPACT, DESCRIPTION, LONGDESCRIPTION, GLMOVEMENTNO, GLSTATUS) 
			Select CH.ITEMENTITYNO, CH.ITEMTRANSNO, CH.ACCTENTITYNO, CH.ACCTCREDITORNO,
			max(CH.HISTORYLINENO)+1 AS HISTORYLINENO, CH.DOCUMENTREF, dbo.fn_DateOnly(@pdtPaymentDate) AS TRANSDATE, 
			NULL AS POSTDATE, NULL AS POSTPERIOD, 704 AS TRANSTYPE, 2 AS MOVEMENTCLASS, 3 AS COMMANDID, 
			0 AS ITEMPRETAXVALUE, 0 AS LOCALTAXAMT, 
			convert( decimal(11,2), ((PPD.PAYMENTAMOUNT / ISNULL( @nTotalPaymentAmount, 1) ) * @nTotalLocalPaymentAmount))*-1 AS LOCALVALUE, 
			dbo.fn_CalcExchangeVariance( CH.LOCALBALANCE,
					CH.FOREIGNBALANCE,
					CH.EXCHRATE,
					CH.CURRENCY,
					convert( decimal(11,2), ((PPD.PAYMENTAMOUNT / ISNULL( @nTotalPaymentAmount, 1) ) * @nTotalLocalPaymentAmount)),
					PPD.PAYMENTAMOUNT,
					convert( decimal(11,2), (PPD.PAYMENTAMOUNT/((PPD.PAYMENTAMOUNT / ISNULL( @nTotalPaymentAmount, 1) ) * @nTotalLocalPaymentAmount))),
					CH.CURRENCY,
					0) AS EXCHVARIANCE, 
-- 			it has already been established that CH.CURRENCY IS NOT NULL
--			CASE WHEN CH.CURRENCY IS NULL THEN NULL ELSE 0 END AS FOREIGNTAXAMT, 
--			CASE WHEN CH.CURRENCY IS NULL THEN NULL ELSE (PPD.PAYMENTAMOUNT * -1) END AS FOREIGNTRANVALUE,
			0 AS FOREIGNTAXAMT, 
			(PPD.PAYMENTAMOUNT * -1) AS FOREIGNTRANVALUE,
			@nEntityNo AS REFENTITYNO, @nTransNo AS REFTRANSNO, 
			-- Note because the payment currency will always equal the item currency for payment plans
			-- there is no need at this stage to implemented the other proportional calculations used in 
			-- the Centura code e.g. Manual Payment and AR ((PPD.PAYMENTAMOUNT / ISNULL( @nTotalPaymentAmount, 1) ) * CH.LOCALVALUE)
--			convert( decimal(11,2), (CH.LOCALBALANCE - ((PPD.PAYMENTAMOUNT / ISNULL( @nTotalPaymentAmount, 1) ) * @nTotalLocalPaymentAmount))) AS LOCALBALANCE, 
--			CASE WHEN CH.CURRENCY IS NULL THEN NULL ELSE (CH.FOREIGNBALANCE - PPD.PAYMENTAMOUNT) END AS FOREIGNBALANCE, 
			CH.LOCALBALANCE, CH.FOREIGNBALANCE,
			0 AS FORCEDPAYOUT, CH.CURRENCY, 
--C.BUYRATE precondition of posting is that the exchange rate recorded here is the same as the Item
			CH.EXCHRATE, 0 AS STATUS, NULL AS ASSOCLINENO, 
			NULL AS ITEMIMPACT, NULL AS DESCRIPTION, NULL AS LONGDESCRIPTION, NULL AS GLMOVEMENTNO, NULL AS GLSTATUS
		
			from PAYMENTPLANDETAIL PPD
			join CREDITORHISTORY CH	on (PPD.ITEMENTITYNO = CH.ITEMENTITYNO
						and PPD.ITEMTRANSNO = CH.ITEMTRANSNO
						and PPD.ACCTENTITYNO = CH.ACCTENTITYNO
						and PPD.ACCTCREDITORNO = CH.ACCTCREDITORNO)
			left join CURRENCY C		on (C.CURRENCY = CH.CURRENCY)
	
			where PPD.PLANID = @pnPlanId  
			and CH.ACCTENTITYNO = @nAcctEntityNo 
			and CH.ACCTCREDITORNO = @nAcctCreditorNo
			and CH.CURRENCY = @sItemCurrency
			and CH.HISTORYLINENO = (Select MAX(CRH2.HISTORYLINENO)
								from CREDITORHISTORY CRH2
								where CH.ITEMENTITYNO = CRH2.ITEMENTITYNO 
								and CH.ITEMTRANSNO = CRH2.ITEMTRANSNO
								and CH.ACCTENTITYNO = CRH2.ACCTENTITYNO
								and CH.ACCTCREDITORNO = CRH2.ACCTCREDITORNO)
	
			group by CH.ACCTENTITYNO, CH.ACCTCREDITORNO, CH.ITEMENTITYNO, CH.ITEMTRANSNO, 
			CH.DOCUMENTREF, PPD.PAYMENTAMOUNT, CH.CURRENCY, CH.EXCHRATE,
			CH.LOCALBALANCE, CH.ITEMIMPACT, CH.DESCRIPTION, C.BUYRATE, CH.FOREIGNBALANCE, CH.LOCALVALUE     
		
			order by CH.ACCTENTITYNO, CH.ACCTCREDITORNO, CH.ITEMENTITYNO
		End

		Set @nErrorCode = @@Error

		If @pbDebugFlag = 1
		begin
			Print '*** proportional calculation for allocated amounts ***'
			SELECT (( PPD.PAYMENTAMOUNT / ISNULL( @nTotalPaymentAmount, 1) ) * @nTotalLocalPaymentAmount ) AS LOCALVALUE, 
			CH.LOCALVALUE, CH.EXCHVARIANCE
			from PAYMENTPLANDETAIL PPD
			join CREDITORHISTORY CH	on (PPD.ITEMENTITYNO = CH.ITEMENTITYNO
						and PPD.ITEMTRANSNO = CH.ITEMTRANSNO
						and PPD.ACCTENTITYNO = CH.ACCTENTITYNO
						and PPD.ACCTCREDITORNO = CH.ACCTCREDITORNO)
			where PPD.PLANID = @pnPlanId  
			and CH.ACCTENTITYNO = @nAcctEntityNo	 
			and CH.ACCTCREDITORNO = @nAcctCreditorNo
			and CH.CURRENCY = @sItemCurrency
			and CH.HISTORYLINENO = (Select MAX(CRH2.HISTORYLINENO)
								from CREDITORHISTORY CRH2
								where CH.ITEMENTITYNO = CRH2.ITEMENTITYNO 
								and CH.ITEMTRANSNO = CRH2.ITEMTRANSNO
								and CH.ACCTENTITYNO = CRH2.ACCTENTITYNO
								and CH.ACCTCREDITORNO = CRH2.ACCTCREDITORNO)
	
			order by CH.ACCTENTITYNO, CH.ACCTCREDITORNO, CH.ITEMENTITYNO

			Select @nErrorCode AS ERRORCODE

		End

	End

	If @nErrorCode = 0
	Begin
		Set @sSQLString="Update CREDITORHISTORY
		set LOCALVALUE = (CH.LOCALVALUE - CH.EXCHVARIANCE), 
		LOCALBALANCE = (CH.LOCALBALANCE - CH.LOCALVALUE + CH.EXCHVARIANCE), 
		FOREIGNBALANCE = CASE WHEN CH.CURRENCY IS NULL THEN NULL ELSE (CH.FOREIGNBALANCE - CH.FOREIGNTRANVALUE) END

		from CREDITORHISTORY CH	
		where CH.REFENTITYNO = @nEntityNo
		and CH.REFTRANSNO = @nTransNo" 

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nEntityNo 	int,
						@nTransNo	int',
						@nEntityNo,
						@nTransNo

	End

	If @pbDebugFlag = 1
	begin
		Print '*** CREDITORHISTORY updated - Transaction value + variance = original input value ***'
		Select CH.LOCALVALUE, CH.EXCHVARIANCE 
		from CREDITORHISTORY CH
		where CH.REFENTITYNO = @nEntityNo
		and CH.REFTRANSNO = @nTransNo 

		Print '*** CREDITORHISTORY row added for the remittance - before remainder ***'
		Select * 
		from CREDITORHISTORY CH	 
		where CH.REFENTITYNO = @nEntityNo
		and CH.REFTRANSNO = @nTransNo

		
		Select SUM(CH.LOCALVALUE + CH.EXCHVARIANCE) AS SUMLOCALCREDITORHISTORY, 
		@nTotalLocalPaymentAmount AS TOTALLOCALPAYMENT,
		(ABS(SUM(CH.LOCALVALUE + CH.EXCHVARIANCE)) - @nTotalLocalPaymentAmount) AS REMAINDER
		from PAYMENTPLANDETAIL PPD
		join CREDITORHISTORY CH	on (PPD.ITEMENTITYNO = CH.ITEMENTITYNO
					and PPD.ITEMTRANSNO = CH.ITEMTRANSNO
					and PPD.ACCTENTITYNO = CH.ACCTENTITYNO
					and PPD.ACCTCREDITORNO = CH.ACCTCREDITORNO)	
		where PPD.PLANID = @pnPlanId  
		and CH.ACCTENTITYNO = @nAcctEntityNo	 
		and CH.ACCTCREDITORNO = @nAcctCreditorNo
		and CH.CURRENCY = @sItemCurrency
		and CH.HISTORYLINENO = (Select MAX(CRH2.HISTORYLINENO)
							from CREDITORHISTORY CRH2
							where CH.ITEMENTITYNO = CRH2.ITEMENTITYNO 
							and CH.ITEMTRANSNO = CRH2.ITEMTRANSNO
							and CH.ACCTENTITYNO = CRH2.ACCTENTITYNO
							and CH.ACCTCREDITORNO = CRH2.ACCTCREDITORNO)
		Select @nErrorCode AS ERRORCODE
	End


	-- ** CALCULATE ANY REMAINDER. IF ANY ADD TO LAST ITEM INCLUDED
	If @nErrorCode = 0
	Begin
		Set @sSQLString="Select @nTotalLocalCreditorHistory = (ABS(SUM(CH.LOCALVALUE + CH.EXCHVARIANCE)))
		from CREDITORHISTORY CH	
		where CH.REFENTITYNO = @nEntityNo
		and CH.REFTRANSNO = @nTransNo"
		
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nTotalLocalCreditorHistory	decimal(11,2)		OUTPUT, 
						@nEntityNo 			int,
						@nTransNo			int',
						@nTotalLocalCreditorHistory=@nTotalLocalCreditorHistory	OUTPUT, 
						@nEntityNo=@nEntityNo,
						@nTransNo=@nTransNo

	End

	If @nErrorCode = 0 AND (@nTotalLocalCreditorHistory <> @nTotalLocalPaymentAmount)
	Begin
		Set @sSQLString="Update CREDITORHISTORY
		set EXCHVARIANCE =  CH.EXCHVARIANCE + (@nTotalLocalCreditorHistory - @nTotalLocalPaymentAmount),
		LOCALBALANCE = (CH.LOCALBALANCE - CH.LOCALVALUE + (CH.EXCHVARIANCE + (@nTotalLocalCreditorHistory - @nTotalLocalPaymentAmount))), 
		FOREIGNBALANCE = CASE WHEN CH.CURRENCY IS NULL THEN NULL ELSE (CH.FOREIGNBALANCE - CH.FOREIGNTRANVALUE) END
		from CREDITORHISTORY CH
		where CH.REFENTITYNO = @nEntityNo
		and CH.REFTRANSNO = @nTransNo
		and CH.ITEMTRANSNO = 	(Select MAX(CH2.ITEMTRANSNO)
					from CREDITORHISTORY CH2	
					where CH2.REFENTITYNO = @nEntityNo
					and CH2.REFTRANSNO = @nTransNo)"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nTotalLocalCreditorHistory		decimal(11,2), 
						@nTotalLocalPaymentAmount	decimal(11,2), 
						@nEntityNo 			int,
						@nTransNo			int',
						@nTotalLocalCreditorHistory, 
						@nTotalLocalPaymentAmount=@nTotalLocalPaymentAmount, 
						@nEntityNo=@nEntityNo,
						@nTransNo=@nTransNo

	End

	If @pbDebugFlag = 1
	begin
		Print '*** CREDITORHISTORY updated - Transaction value + variance = original input value ***'
		Select CH.LOCALVALUE, CH.EXCHVARIANCE 
		from CREDITORHISTORY CH	
		where CH.REFENTITYNO = @nEntityNo
		and CH.REFTRANSNO = @nTransNo 

		Print '*** CREDITORHISTORY row added for the remittance ***'
		Select * 
		from CREDITORHISTORY CH	
		where CH.REFENTITYNO = @nEntityNo
		and CH.REFTRANSNO = @nTransNo

		
		Select SUM(CH.LOCALVALUE + CH.EXCHVARIANCE) AS SUMLOCALCREDITORHISTORY, 
		@nTotalLocalPaymentAmount AS TOTALLOCALPAYMENT 
		from CREDITORHISTORY CH	
		where CH.ACCTENTITYNO = @nAcctEntityNo	 
		and CH.ACCTCREDITORNO = @nAcctCreditorNo
		and CH.CURRENCY = @sItemCurrency
		and CH.HISTORYLINENO = (Select MAX(CRH2.HISTORYLINENO)
							from CREDITORHISTORY CRH2
							where CH.ITEMENTITYNO = CRH2.ITEMENTITYNO 
							and CH.ITEMTRANSNO = CRH2.ITEMTRANSNO
							and CH.ACCTENTITYNO = CRH2.ACCTENTITYNO
							and CH.ACCTCREDITORNO = CRH2.ACCTCREDITORNO)
		Select @nErrorCode AS ERRORCODE
	End

	If @nErrorCode = 0
	Begin
	
		INSERT INTO CASHHISTORY(ENTITYNO, BANKNAMENO, SEQUENCENO, TRANSENTITYNO, TRANSNO, 
		HISTORYLINENO, TRANSDATE, POSTDATE, POSTPERIOD, TRANSTYPE, 
		MOVEMENTCLASS, COMMANDID, REFENTITYNO, 
		REFTRANSNO, STATUS, DESCRIPTION, ASSOCIATEDLINENO, ITEMREFNO, ACCTENTITYNO, ACCTNAMENO, GLACCOUNTCODE, 
		DISSECTIONCURRENCY, FOREIGNAMOUNT, DISSECTIONEXCHANGE, LOCALAMOUNT, ITEMIMPACT, GLMOVEMENTNO)
		SELECT  CI.ENTITYNO, CI.BANKNAMENO, CI.SEQUENCENO, CI.TRANSENTITYNO, CI.TRANSNO,
		MAX(CASHHISTORY.HISTORYLINENO) + 1 AS HISTORYLINENO, CI.ITEMDATE, CI.POSTDATE, CI.POSTPERIOD, TH.TRANSTYPE, 
		2 AS MOVEMENTCLASS, 3 AS COMMANDID, CI.TRANSENTITYNO, 
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
	
		WHERE CI.TRANSENTITYNO = @nEntityNo
		AND CI.TRANSNO = @nTransNo
	
		GROUP BY CI.ENTITYNO, CI.BANKNAMENO, CI.SEQUENCENO, CI.TRANSENTITYNO, 
		CI.TRANSNO, CI.ITEMDATE, CI.POSTDATE, CI.POSTPERIOD, 
		TH.TRANSTYPE, CI.TRANSENTITYNO, CI.TRANSNO, CI.STATUS, 
		CI.DESCRIPTION, CI.ITEMREFNO, CI.ACCTENTITYNO, CI.ACCTNAMENO, 
		CI.LOCALAMOUNT, CI.DISSECTIONCURRENCY, CI.DISSECTIONAMOUNT, CI.DISSECTIONEXCHANGE   
		
		ORDER BY CI.ACCTENTITYNO, CI.ACCTNAMENO, CI.TRANSENTITYNO

		Set @nErrorCode = @@Error

		If @pbDebugFlag = 1
		Begin
			Print '*** CASHHISTORY added for the remittance ***'
			Select @nErrorCode as ERRORCODE
		End

	End


	If @nErrorCode = 0
	Begin
		Set @sSQLString="
		UPDATE PAYMENTPLANDETAIL
		SET REFENTITYNO = @nEntityNo, 
		REFTRANSNO = @nTransNo 
		FROM PAYMENTPLANDETAIL PPD
		join CREDITORHISTORY CH	on (PPD.ITEMENTITYNO = CH.ITEMENTITYNO
					and PPD.ITEMTRANSNO = CH.ITEMTRANSNO
					and PPD.ACCTENTITYNO = CH.ACCTENTITYNO
					and PPD.ACCTCREDITORNO = CH.ACCTCREDITORNO)
		where PPD.PLANID = @pnPlanId
		and CH.REFENTITYNO = @nEntityNo
		and CH.REFTRANSNO = @nTransNo"
		
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nEntityNo 		int,
						@nTransNo		int,
						@pnPlanId		int',
						@nEntityNo,
						@nTransNo,
						@pnPlanId


		If @pbDebugFlag = 1
		Begin
			Print '*** Update Payment Plan Details as Processed ***'
			SELECT * 
			FROM PAYMENTPLANDETAIL PPD
			join CREDITORHISTORY CH	on (PPD.ITEMENTITYNO = CH.ITEMENTITYNO
						and PPD.ITEMTRANSNO = CH.ITEMTRANSNO
						and PPD.ACCTENTITYNO = CH.ACCTENTITYNO
						and PPD.ACCTCREDITORNO = CH.ACCTCREDITORNO)
			where PPD.PLANID = @pnPlanId
			and CH.REFENTITYNO = @nEntityNo
			and CH.REFTRANSNO = @nTransNo

			-- Print @sSQLString
			Select @nErrorCode as ERRORCODE
		End
	End
		
	If @nErrorCode = 0
	Begin
		-- Done here as this relies on Creditor, Cash and Bank History being recorded for the currency conversion
		-- Journal figures must be in local currency
		If (@nPaymentMethod <> @nBankDraft)
		Begin
			EXEC @nErrorCode = ap_PlanRecordJournal	@pnUserIdentityId, @psCulture, @pbDebugFlag, @nEntityNo, 
								@nTransNo, @pnPlanId, 0, @pnEmployeeNo
	
			If @pbDebugFlag = 1
			Begin
				Print '*** Record Journal per payment ***'
				Select @nErrorCode as ERRORCODE, @nEntityNo AS ENTITYNO, @nTransNo AS TRANSNO
			End
		End
	End
	
	If @nErrorCode = 0
	Begin
		-- SQA10514 Update the Payment in the temporary table with the TransId of the Ledger Journal
		Set @sSQLString=" 
		UPDATE " + @psTableName + "
		SET	JOURNALENTITYNO = @nEntityNo,
			JOURNALTRANSNO = @nTransNo	 
		where SEQUENCE = @nSequenceNo"


/*		Set @sSQLString="
		UPDATE PAYMENTPLANDETAIL
		SET JOURNALENTITYNO = @nEntityNo, 
		JOURNALTRANSNO = @nTransNo 
		FROM PAYMENTPLANDETAIL PPD
		join CREDITORHISTORY CH	on (PPD.ITEMENTITYNO = CH.ITEMENTITYNO
					and PPD.ITEMTRANSNO = CH.ITEMTRANSNO
					and PPD.ACCTENTITYNO = CH.ACCTENTITYNO
					and PPD.ACCTCREDITORNO = CH.ACCTCREDITORNO)
		where PPD.PLANID = @pnPlanId
		and CH.REFENTITYNO = @nEntityNo
		and CH.REFTRANSNO = @nTransNo"
		
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nEntityNo 		int,
						@nTransNo		int,
						@pnPlanId		int',
						@nEntityNo,
						@nTransNo,
						@pnPlanId
*/

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nEntityNo 		int,
						@nTransNo		int,
						@nSequenceNo		int',
						@nEntityNo,
						@nTransNo,
						@nSequenceNo


		If @pbDebugFlag = 1
		Begin
			Print '*** Update Produced Payment Details with Journal TransId ***'
			Print @sSQLString
			Select @nEntityNo AS JOURNALENTITYNO,@nTransNo AS JOURNALTRANSNO, @nSequenceNo AS SEQUENCE
		End
	End


-- ##TEMPPLANPAYMENTS
	-- Now get the next row
	If @nErrorCode = 0
	Begin
		Set @sSQLString=" 
		Select @nSequenceNoOUT=min(SEQUENCE)
		from " + @psTableName + "
		where SEQUENCE > @nSequenceNo"
	
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@nSequenceNoOUT	int		OUTPUT,
				@nSequenceNo		int',
				@nSequenceNoOUT=@nSequenceNo		OUTPUT,
				@nSequenceNo=@nSequenceNo	
		/*	
		If @pbDebugFlag = 1
		Begin
			print '*** Now get the next row. ***'	
			-- Print @sSQLString
			Select @nSequenceNo as SEQUENCE, @nErrorCode as ERRORCODE
		End
		*/
	End
End

If @nErrorCode = 0
Begin
	If @pbDebugFlag = 1
	Begin
		PRINT '				*** PROCESSING OF ITEM PAYMENTS COMPLETE ***'
		PRINT ''		
		PRINT '*** CREDITORHISTORY rows added ***'
		Select *
		from CREDITORHISTORY CH
		WHERE CH.REFTRANSNO IN (SELECT PPD.REFTRANSNO
					FROM PAYMENTPLANDETAIL PPD
					where PPD.PLANID = @pnPlanId)
		and (ABS(CH.LOCALVALUE)) <> 0

		PRINT '*** PAYMENTPLANDETAIL rows updated ***'
		SELECT *
		FROM PAYMENTPLANDETAIL PPD
		where PPD.PLANID = @pnPlanId

	End
End

If @nErrorCode = 0
Begin
	
	If (@nPaymentMethod = @nBankDraft)
	Begin
		Set @nTransNo = NULL
		EXEC @nErrorCode = ap_PlanRecordWithdrawal	@nTransNo OUTPUT, @pnUserIdentityId, @psCulture, @pbCalledFromCentura, @pbDebugFlag, @nEntityNo, 
									@psBankHistoryReference, @pnBankCharges, @psBankHistoryDescription, @pnPlanId, 
									@pnEmployeeNo, @psUserId, @pdtPaymentDate

		If @pbDebugFlag = 1
		Begin
			Print '*** BANKHISTORY row for the withdrawal of a Bank Draft ***'
			Select @nErrorCode as ERRORCODE, @nEntityNo AS ENTITYNO, @nTransNo AS TRANSNO
		End
		
		-- Done here as this relies on Creditor, Cash and Bank History being recorded for the currency conversion
		-- Journal figures must be in local currency
		If @nErrorCode = 0
		Begin
			
			exec @nErrorCode =  ap_PlanRecordJournal	@pnUserIdentityId, @psCulture, @pbDebugFlag, @nEntityNo, 
									@nTransNo, @pnPlanId, 1, @pnEmployeeNo

			If @pbDebugFlag = 1
			Begin
				Print '*** Record Journal for the withdrawal ***'
				Select @nErrorCode as ERRORCODE, @nEntityNo AS ENTITYNO, @nTransNo AS TRANSNO
			End
		End

		If @nErrorCode = 0
		Begin
			-- SQA10514 Update the Payment in the temporary table with the TransId of the Ledger Journal
			Set @sSQLString=" 
			UPDATE " + @psTableName + "
			SET	JOURNALENTITYNO = @nEntityNo,
				JOURNALTRANSNO = @nTransNo"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@nEntityNo 		int,
							@nTransNo		int',
							@nEntityNo,
							@nTransNo
		
/*			Set @sSQLString="
			UPDATE PAYMENTPLANDETAIL
			SET JOURNALENTITYNO = @nEntityNo, 
			JOURNALTRANSNO = @nTransNo 
			FROM PAYMENTPLANDETAIL PPD
			where PPD.PLANID = @pnPlanId"
			
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@nEntityNo 		int,
							@nTransNo		int,
							@pnPlanId		int',
							@nEntityNo,
							@nTransNo,
							@pnPlanId
*/

			If @pbDebugFlag = 1
			Begin
				Print '*** Update Produced Payment Details with Journal TransId ***'
				Print @sSQLString
				Select @nEntityNo AS JOURNALENTITYNO,@nTransNo AS JOURNALTRANSNO
			End
		End

	End
End

If @nErrorCode = 0
Begin
 	Set @sSQLString="Select @nTotalCashBankAmount = SUM(CI.BANKAMOUNT)
	FROM CASHITEM CI
	where CI.TRANSNO IN (SELECT DISTINCT(PPD.REFTRANSNO)
				FROM PAYMENTPLANDETAIL PPD
				WHERE PPD.PLANID = @pnPlanId)"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nTotalCashBankAmount	decimal(11,2)		OUTPUT,
					@pnPlanId		int',
					@nTotalCashBankAmount=@nTotalCashBankAmount	OUTPUT,
					@pnPlanId=@pnPlanId

End

If @nErrorCode = 0
Begin
	-- sqa21641 rearrange the query to improve performance on large DB
	--Set @sSQLString="Select @nTotalBankAmount = SUM(BH.BANKAMOUNT)
	--from BANKHISTORY BH
	--where BH.REFTRANSNO IN (SELECT DISTINCT(BANKEDBYTRANSNO)
	--			FROM CASHITEM CI
	--			join PAYMENTPLANDETAIL PPD	on (PPD.REFENTITYNO = CI.TRANSENTITYNO
	--							and PPD.REFTRANSNO = CI.TRANSNO)
	--			WHERE PPD.PLANID = @pnPlanId)"

	Set @sSQLString="Select @nTotalBankAmount = SUM(BH.BANKAMOUNT)
		from (SELECT DISTINCT CI.BANKEDBYTRANSNO, CI.BANKEDBYENTITYNO   
			FROM PAYMENTPLANDETAIL PPD
			join CASHITEM CI	on (CI.TRANSENTITYNO= PPD.REFENTITYNO
						and CI.TRANSNO      = PPD.REFTRANSNO)
			WHERE PPD.PLANID = @pnPlanId) CASH
		join BANKHISTORY BH	on (BH.REFENTITYNO=CASH.BANKEDBYENTITYNO
					and BH.REFTRANSNO =CASH.BANKEDBYTRANSNO)"
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nTotalBankAmount	decimal(11,2)		OUTPUT,
					@pnPlanId		int',
					@nTotalBankAmount=@nTotalBankAmount		OUTPUT,
					@pnPlanId=@pnPlanId

	If @pbDebugFlag = 1
	Begin
		print '*** validate CASHITEMS ***'
		print ''
		print '*** CASHITEMS ADDED ***'
		Select *
		FROM CASHITEM CI
		where CI.TRANSNO IN (SELECT DISTINCT(PPD.REFTRANSNO)
					FROM PAYMENTPLANDETAIL PPD
					WHERE PPD.PLANID = @pnPlanId)

		PRINT '*** BANK HISTORY ADDED ***'
		Select *
		from BANKHISTORY BH
		where BH.REFTRANSNO IN (SELECT DISTINCT(BANKEDBYTRANSNO)
					FROM CASHITEM CI
					join PAYMENTPLANDETAIL PPD	on (PPD.REFENTITYNO = CI.TRANSENTITYNO
									and PPD.REFTRANSNO = CI.TRANSNO)
					WHERE PPD.PLANID = @pnPlanId)
	
		print '*** Total Bank Amounts Added ***'
		Select @nTotalCashBankAmount as TOTALCASHBANKAMOUNT, @nTotalBankAmount as TOTALBANKAMOUNT
	End

	If (@nTotalCashBankAmount IS NULL) OR (@nTotalBankAmount IS NULL) OR (@nTotalCashBankAmount <> @nTotalBankAmount)
	Begin
		
		Set @sAlertXML = dbo.fn_GetAlertXML('AC18', 'The Bank Amounts of the Cash Items added do not reconcile to the Bank History row/s added.',
    						null, null, null, null, null)
  		RAISERROR(@sAlertXML, 14, 1)
  		Set @nErrorCode = @@ERROR
	End	
End

/* SQA10146 - no longer required. Now done as part of the posting
If @nErrorCode = 0
Begin
	Set @sSQLString="UPDATE PAYMENTPLAN
	SET DATEPROCESSED = dbo.fn_DateOnly(GETDATE())
	WHERE PLANID = @pnPlanId"
			
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnPlanId		int',
							@pnPlanId
	If @pbDebugFlag = 1
	Begin
		PRINT '*** Update PAYMENTPLAN as processed ***'
		-- Print @sSQLString
		SELECT @nErrorCode AS ERRORCODE
	End
End

If @nErrorCode = 0
Begin
	Set @sSQLString="UPDATE CREDITORITEM
	SET STATUS = 1
	WHERE EXISTS (SELECT * 
		FROM PAYMENTPLANDETAIL PPD
		WHERE PPD.ITEMENTITYNO = CREDITORITEM.ITEMENTITYNO AND
			PPD.ITEMTRANSNO = CREDITORITEM.ITEMTRANSNO AND
			PPD.PLANID = @pnPlanId)"
			
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnPlanId		int',
							@pnPlanId
	
	If @pbDebugFlag = 1
	Begin
		PRINT '*** Unlock CREDITORITEMS ***'
		-- Print @sSQLString
		SELECT @nErrorCode as ERRRORCODE
	End
End
*/

If @@TranCount > @nTranCountStart
Begin
	If @nErrorCode = 0
	Begin	
		If @pbDebugFlag = 1
		Begin
			print '*** payment plan details ***'
			SELECT * FROM PAYMENTPLANDETAIL
			WHERE PLANID = @pnPlanId

			print '*** creditor history ***'
			SELECT * FROM CREDITORHISTORY CH
			join PAYMENTPLANDETAIL PPD	on (PPD.REFENTITYNO = CH.REFENTITYNO
							and PPD.REFTRANSNO = CH.REFTRANSNO)
			WHERE PPD.PLANID = @pnPlanId

			print '*** Creditor item ***'
			SELECT * FROM CREDITORITEM CI
			join PAYMENTPLANDETAIL PPD	on (PPD.ITEMENTITYNO = CI.ITEMENTITYNO
							and PPD.ITEMTRANSNO = CI.ITEMTRANSNO
							and PPD.ACCTENTITYNO = CI.ACCTENTITYNO
							and PPD.ACCTCREDITORNO = CI.ACCTCREDITORNO)
			WHERE PPD.PLANID = @pnPlanId
			
			print '*** Cash history ***'
			SELECT * FROM CASHHISTORY CH
			join PAYMENTPLANDETAIL PPD	on (PPD.REFENTITYNO = CH.REFENTITYNO
							and PPD.REFTRANSNO = CH.REFTRANSNO)
			WHERE PPD.PLANID = @pnPlanId
			
			print '*** Cash item ***'
			SELECT * FROM CASHITEM CI
			join PAYMENTPLANDETAIL PPD	on (PPD.REFENTITYNO = CI.ENTITYNO
							and PPD.REFTRANSNO = CI.TRANSNO)
			WHERE PPD.PLANID = @pnPlanId

			ROLLBACK TRANSACTION
			print '*** Transaction Rolled Back NO ERRORS occurred ***'

--			print '*** Transaction Committed ***'
		End
		Else
		Begin
			COMMIT TRANSACTION
		End
	End
	Else begin
		ROLLBACK TRANSACTION
		
		If @pbDebugFlag = 1
			print '*** Transaction Rolled Back ***'
	End
End

/*
If @pbCalledFromCentura = 1
	Select @nErrorCode as ERRORCODE
*/
Return @nErrorCode
GO

Grant execute on dbo.ap_ProcessPaymentPlan to public
GO
