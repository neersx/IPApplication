-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ap_PlanRecordJournal
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ap_PlanRecordJournal]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ap_PlanRecordJournal.'
	Drop procedure [dbo].[ap_PlanRecordJournal]
End
Print '**** Creating Stored Procedure dbo.ap_PlanRecordJournal...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ap_PlanRecordJournal
(
	@pnUserIdentityId	int		= null,
	@psCulture		nvarchar(10) 	= null,
	@pbDebugFlag		tinyint 	= 0,
	@pnEntityNo		int,		-- Mandatory
	@pnTransNo		int,		-- Mandatory		
	@pnPlanId		int,		-- Mandatory
	@pnBankDraft		decimal(1,0),	-- Mandatory
	@pnEmployeeNo		int		-- Mandatory
)
as
-- PROCEDURE:	ap_PlanRecordJournal
-- VERSION:	11
-- SCOPE:	InPro
-- DESCRIPTION:	Record the GL Journal for the payment plan currently being processed
--		NOTE:Should only be called after the RecordWithdrawal procedure has been executed 
--		and the Bank, Cash and Creditor History recorded
-- COPYRIGHT:	Copyright 1993 - 2008 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date			Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 NOV 2003	CR	8816	1.00	Procedure created
-- 09-Dec-2003	CR	8817	1.01	Fixed Single Withdrawal and exchange variance bugs
-- 10-Dec-2003	CR	8817	1.02	Fixed more bugs
-- 18-Dec-2003	CR	8817	1.03	Added IsActive Validation
-- 19-Jan-2004	SS	8855	1.04	Implemented foreign currency ledger journals
-- 20-Feb-2004	CR	9558	1.05	Removed unnecesary select statement that was causing an SQL error bug.
-- 23-July-2004	MB	9735	2	Default Accounting
-- 16-Nov-2005	vql	9704	3	When updating LEDGERJOURNAL table insert @pnUserIdentityId.
-- 16-Oct-2008	CR	10514	4	Extended to cater for Cash Accounting
-- 19-Oct-2010	DL	18895	5	Post sale tax to GL journal for Cash Accounting
-- 13-Jul-2011	DL	R10830	6	Specify collation default in temp table.
-- 20-Dec-2013	DL	21636	7	For Cash Accounting use expense journal lines created by the purchase instead of the creditor's expense account.
-- 10-Sep-2014	vql	38784	8	Made changes to accommodate credit notes in the bulk payment
-- 15-Sep-2014	vql	38784	9	Extended changes to accommodate credit notes in the bulk payment for various methods
-- 20 Oct 2015  MS      R53933   10      Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols
-- 02 Nov 2015	vql	R53910	11	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode			int,
	@sSQLString			nvarchar(400),
	@nBankLedgerAcct		int,
	@nBankChargesLedgerAcct		int,
	@nPayableLedgerAcct		int,
	@nExchLossLedgerAcct		int,
	@nExchGainLedgerAcct		int,
	@nPayableSusLedgerAcct		int,
	@sBankProfitCentre		nvarchar(6),
	@sBankChargesProfitCentre	nvarchar(6),
	@sPayableProfitCentre		nvarchar(6),
	@sPayableSusProfitCentre	nvarchar(6),
	@sExchLossProfitCentre		nvarchar(6),
	@sExchGainProfitCentre		nvarchar(6),
	@nSumAmount			decimal(11,2),
	@sMessage			nvarchar(250),
	@nRowCount			int,
	@bCashAccounting		tinyint,
	@nTaxLedgerAcct			int,
	@sTaxProfitCentre		nvarchar(6)

declare @tbLEDGERJOURNALLINE 	table (
	SEQNO	 		int 		identity,
	ENTITYNO 		int 		NOT NULL,
	TRANSNO 		int 		NOT NULL,
	PROFITCENTRECODE 	nvarchar(6)	collate database_default NULL,
	ACCOUNTID 		int 		NOT NULL,
	LOCALAMOUNT 		decimal(11, 2)	NOT NULL,
	FOREIGNAMOUNT		decimal(11, 2),
	CURRENCY		nvarchar(6)	collate database_default,
	EXCHRATE		decimal(11, 4),
	NOTES 			nvarchar(254)	collate database_default NULL,
	ACCTENTITYNO 		int 		NOT NULL ) 

declare @tbTAXES	table(
	LOCALTAX	decimal(11, 2),
	FOREIGNTAX	decimal(11, 2),
	ITEMENTITYNO	int,
	ITEMTRANSNO	int,
	REFENTITYNO	int,
	REFTRANSNO	int)
	

-- Initialise variables
Set @nErrorCode = 0

Set @nBankLedgerAcct = NULL
Set @sBankProfitCentre = NULL
Set @nBankChargesLedgerAcct = NULL 
Set @sBankChargesProfitCentre = NULL
Set @nPayableLedgerAcct = NULL 
Set @sPayableProfitCentre = NULL
Set @nExchLossLedgerAcct = NULL
Set @sExchLossProfitCentre = NULL
Set @nExchGainLedgerAcct = NULL
Set @sExchGainProfitCentre = NULL
Set @nTaxLedgerAcct = NULL
Set @sTaxProfitCentre = NULL


/*
Number: IDC_CONTROL_ACCT_TYPE_BANK=8701
Number: IDC_CONTROL_ACCT_TYPE_AP=8702
Number: IDC_CONTROL_ACCT_TYPE_EG=8703
Number: IDC_CONTROL_ACCT_TYPE_EL=8704
Number: IDC_CONTROL_ACCT_TYPE_BANKCHARGE=8705
Number: IDC_CONTROL_ACCT_TYPE_TAX=8706
Number: IDC_CONTROL_ACCT_TYPE_RETEARN=8707
Number: IDC_CONTROL_ACCT_TYPE_AR=8708

NOTE: Unlike Manual Payments there isn't anywhere for the user to set CASHITEM.DESCRIPTION so
this is NOT included in the Notes of the Journal.
It is however possible to set a BANKHISTORY.REFERENCE and BANKHISTORY.DESCRIPTION (Bank Draft - single withdrawal) 
- so where applicable this IS included in the Notes of the Journal.
*/

If @nErrorCode = 0
Begin	
	-- Function: _cfRetrieveForBankCtrlType
	SELECT @nBankLedgerAcct = DA.ACCOUNTID, @sBankProfitCentre = DA.PROFITCENTRECODE
	from PAYMENTPLANDEFACCT DA
	join LEDGERACCOUNT LA	ON (LA.ACCOUNTID = DA.ACCOUNTID)
	join PAYMENTPLAN PP on (DA.PLANID = PP.PLANID) 
	Where 
		PP.PLANID = @pnPlanId
	and 	DA.CONTROLACCTYPEID =  8701
	and 	LA.ISACTIVE = 1
	Set @nRowCount = @@RowCount
	Set @nErrorCode = @@Error
	if @nRowCount	= 0 and @nErrorCode = 0
	Begin
		select @nBankLedgerAcct = DA.ACCOUNTID, @sBankProfitCentre = DA.PROFITCENTRECODE
		from fn_GetDefaultAccount (@pnPlanId) DA where  DA.CONTROLACCTYPEID =  8701
		Set @nErrorCode = @@Error
	End

	If @pbDebugFlag = 1
	Begin
		Print '*** Retrieve For Bank Ctrl Type ***'
		Select @nErrorCode as ERRORCODE, @nBankLedgerAcct as BANKACCOUNTID, @sBankProfitCentre as BANKPROFITCENTRECODE
	End
End

If @nErrorCode = 0
Begin
	-- Function: _cfRetrieveForBankChrgCtrlType
	SELECT @nBankChargesLedgerAcct = DA.ACCOUNTID, @sBankChargesProfitCentre = DA.PROFITCENTRECODE
	from PAYMENTPLANDEFACCT DA
	join LEDGERACCOUNT LA	ON (LA.ACCOUNTID = DA.ACCOUNTID)
	join PAYMENTPLAN PP on (DA.PLANID = PP.PLANID) 
	Where PP.PLANID = @pnPlanId 
	and DA.CONTROLACCTYPEID =  8705
	and LA.ISACTIVE = 1

	Set @nRowCount = @@RowCount
	Set @nErrorCode = @@Error
	if @nRowCount	= 0 and @nErrorCode = 0
	Begin
		select @nBankChargesLedgerAcct = DA.ACCOUNTID, @sBankChargesProfitCentre = DA.PROFITCENTRECODE
		from fn_GetDefaultAccount (@pnPlanId) DA where  DA.CONTROLACCTYPEID =  8705
		Set @nErrorCode = @@Error
	End
	
	If @pbDebugFlag = 1
	Begin
		Print '*** Retrieve For Bank Charges Ctrl Type ***'
		Select @nErrorCode as ERRORCODE, @nBankChargesLedgerAcct as BANKCHRACCOUNTID, @sBankChargesProfitCentre as BANKCHRPROFITCENTRECODE
	End
End

If @nErrorCode = 0
Begin
	-- Function: _cfRetrieveForAPCtrlType
	SELECT @nPayableLedgerAcct = DA.ACCOUNTID, @sPayableProfitCentre = DA.PROFITCENTRECODE
	from PAYMENTPLANDEFACCT DA
	join LEDGERACCOUNT LA	ON (LA.ACCOUNTID = DA.ACCOUNTID)
	join PAYMENTPLAN PP on (DA.PLANID = PP.PLANID) 
	Where PP.PLANID = @pnPlanId 
	and DA.CONTROLACCTYPEID =  8702
	and LA.ISACTIVE = 1

	Set @nRowCount = @@RowCount	
	Set @nErrorCode = @@Error
	if @nRowCount	= 0 and @nErrorCode = 0
	Begin
		select @nPayableLedgerAcct = DA.ACCOUNTID, @sPayableProfitCentre = DA.PROFITCENTRECODE
		from fn_GetDefaultAccount (@pnPlanId) DA where  DA.CONTROLACCTYPEID =  8702
		Set @nErrorCode = @@Error
	End

	If @pbDebugFlag = 1
	Begin
		Print '*** Retrieve For Accounts Payable Ctrl Type ***'
		Select @nErrorCode as ERRORCODE, @nPayableLedgerAcct AS APACCOUNTID, @sPayableProfitCentre as APPROFITCENTRECODE
	End
End


If @nErrorCode = 0
Begin
	--Function: _cfRetriveForExchgLossCtrlType
	SELECT @nExchLossLedgerAcct = DA.ACCOUNTID, @sExchLossProfitCentre = DA.PROFITCENTRECODE
	from PAYMENTPLANDEFACCT DA
	join LEDGERACCOUNT LA	ON (LA.ACCOUNTID = DA.ACCOUNTID)
	join PAYMENTPLAN PP on (DA.PLANID = PP.PLANID) 
	Where PP.PLANID = @pnPlanId
	and DA.CONTROLACCTYPEID =  8704
	and LA.ISACTIVE = 1
	
	Set @nRowCount = @@RowCount
	Set @nErrorCode = @@Error
	if @nRowCount	= 0 and @nErrorCode = 0
	Begin
		select @nExchLossLedgerAcct = DA.ACCOUNTID, @sExchLossProfitCentre = DA.PROFITCENTRECODE
		from fn_GetDefaultAccount (@pnPlanId) DA where  DA.CONTROLACCTYPEID =  8704
		Set @nErrorCode = @@Error
	End

	If @pbDebugFlag = 1
	Begin
		Print '*** Retrieve For Exchange Loss Ctrl Type ***'
		Select @nErrorCode as ERRORCODE, @nExchLossLedgerAcct as EXCHLOSSACCOUNTID, @sExchLossProfitCentre as EXCHLOSSPROFITCENTRECODE
	End
End

If @nErrorCode = 0
Begin
	--Function: _cfRetrieveForExchgGainCtrlType
	SELECT @nExchGainLedgerAcct = DA.ACCOUNTID, @sExchGainProfitCentre = DA.PROFITCENTRECODE
	from PAYMENTPLANDEFACCT DA
	join LEDGERACCOUNT LA	ON (LA.ACCOUNTID = DA.ACCOUNTID)
	join PAYMENTPLAN PP on (DA.PLANID = PP.PLANID) 
	Where PP.PLANID = @pnPlanId
	and DA.CONTROLACCTYPEID =  8703
	and LA.ISACTIVE = 1
	

	Set @nRowCount = @@RowCount
	Set @nErrorCode = @@Error
	if @nRowCount	= 0 and @nErrorCode = 0
	Begin
		select @nExchGainLedgerAcct = DA.ACCOUNTID, @sExchGainProfitCentre = DA.PROFITCENTRECODE
		from fn_GetDefaultAccount (@pnPlanId) DA where  DA.CONTROLACCTYPEID =  8703
		Set @nErrorCode = @@Error
	End

	If @pbDebugFlag = 1
	Begin
		Print '*** Retrieve For Exchange Gain Ctrl Type ***'
		Select @nErrorCode as ERRORCODE, @nExchGainLedgerAcct as EXCHGAINACCOUNTID, @sExchGainProfitCentre AS EXCHGAINPROFITCENTRECODE
	End
End

If @nErrorCode = 0
Begin
	If @nBankLedgerAcct IS NULL OR @sBankProfitCentre IS NULL OR
		@nBankChargesLedgerAcct IS NULL OR @sBankChargesProfitCentre IS NULL OR
		@nPayableLedgerAcct IS NULL OR @sPayableProfitCentre IS NULL OR
		@nExchLossLedgerAcct IS NULL OR @sExchLossProfitCentre IS NULL OR
		@nExchGainLedgerAcct IS NULL OR @sExchGainProfitCentre IS NULL
	Begin
		Set @sMessage = 'One or more of the default accounts required is no longer available'
		RAISERROR(@sMessage, 16, 1)
		Set @nErrorCode = @@Error
	
		If @pbDebugFlag = 1
		Begin
			Print '*** Default Accounts missing ***'
			print @nErrorCode
		End
	End
End

-- retrieve the site control for Cash Accounting
If @nErrorCode = 0
Begin
	Set @sSQLString = "Select @bCashAccounting = SI.COLBOOLEAN
	from SITECONTROL SI	
	where SI.CONTROLID = 'Cash Accounting'"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@bCashAccounting		tinyint	OUTPUT',
				@bCashAccounting=@bCashAccounting	OUTPUT
End


-- Retrieve Accounts Payable Suspense Ctrl Type and Tax for Cash Accounting
If @bCashAccounting = 1
Begin
	If @nErrorCode = 0
	Begin
		SELECT @nPayableSusLedgerAcct = DA.ACCOUNTID, @sPayableSusProfitCentre = DA.PROFITCENTRECODE
		from PAYMENTPLANDEFACCT DA
		join LEDGERACCOUNT LA	ON (LA.ACCOUNTID = DA.ACCOUNTID)
		join PAYMENTPLAN PP	on (DA.PLANID = PP.PLANID) 
		Where PP.PLANID = @pnPlanId 
		and DA.CONTROLACCTYPEID =  8713
		and LA.ISACTIVE = 1
	
		Set @nRowCount = @@RowCount	
		Set @nErrorCode = @@Error
		if @nRowCount	= 0 and @nErrorCode = 0
		Begin
			select @nPayableSusLedgerAcct = DA.ACCOUNTID, @sPayableSusProfitCentre = DA.PROFITCENTRECODE
			from fn_GetDefaultAccount (@pnPlanId) DA 
			where  DA.CONTROLACCTYPEID =  8713
			Set @nErrorCode = @@Error
		End
	
		If @pbDebugFlag = 1
		Begin
			Print '*** Retrieve For Accounts Payable Suspense Ctrl Type ***'
			Select @nErrorCode as ERRORCODE, @nPayableSusLedgerAcct AS APACCOUNTID, @sPayableSusProfitCentre as APPROFITCENTRECODE
		End
	End

	-- SQA18895 Retrieve default account for TAX
	If @nErrorCode = 0
	Begin
		SELECT @nTaxLedgerAcct = DA.ACCOUNTID, @sTaxProfitCentre = DA.PROFITCENTRECODE
		from PAYMENTPLANDEFACCT DA
		join LEDGERACCOUNT LA	ON (LA.ACCOUNTID = DA.ACCOUNTID)
		join PAYMENTPLAN PP	on (DA.PLANID = PP.PLANID) 
		Where PP.PLANID = @pnPlanId 
		and DA.CONTROLACCTYPEID =  8706
		and LA.ISACTIVE = 1
	
		Set @nRowCount = @@RowCount	
		Set @nErrorCode = @@Error
		if @nRowCount	= 0 and @nErrorCode = 0
		Begin
			select @nTaxLedgerAcct = DA.ACCOUNTID, @sTaxProfitCentre = DA.PROFITCENTRECODE
			from fn_GetDefaultAccount (@pnPlanId) DA 
			where  DA.CONTROLACCTYPEID =  8706
			Set @nErrorCode = @@Error
		End
	
		If @pbDebugFlag = 1
		Begin
			Print '*** Retrieve For Tax Ctrl Type ***'
			Select @nErrorCode as ERRORCODE, @nTaxLedgerAcct AS APACCOUNTID, @sTaxProfitCentre as APPROFITCENTRECODE
		End
	End
End


If @pnBankDraft = 1
Begin	
	If @pbDebugFlag = 1
	Begin
		Print '*** Details for a Bank Draft ***'
	End

	-- SQA21636 - Only add Payable row if NOT Cash Accounting because we are no longer use Suspense account in Cash Accounting
	If @nErrorCode = 0 and 	@bCashAccounting <> 1
	Begin
		-- Journal line is in the currency of the item.
		Insert into @tbLEDGERJOURNALLINE(ENTITYNO, TRANSNO, PROFITCENTRECODE, 
		ACCOUNTID, LOCALAMOUNT, FOREIGNAMOUNT, CURRENCY, EXCHRATE, ACCTENTITYNO, NOTES)
		select @pnEntityNo, @pnTransNo, @sPayableProfitCentre,
		@nPayableLedgerAcct, CH.LOCALVALUE*-1, CH.FOREIGNTRANVALUE*-1,
		CH.CURRENCY, CH.EXCHRATE, @pnEntityNo, 
		Case when CI.ITEMREFNO is not null then 'Payment ' + CI.ITEMREFNO
			end + ' ' +
		dbo.fn_FormatNameUsingNameNo(PAY.NAMENO, null) + 
		Case when PAY.NAMECODE is not null then ' {' + PAY.NAMECODE + '}'
			end + 
		Case when CH.DOCUMENTREF is not null then ' Invoice ' + CH.DOCUMENTREF
			end 
		from CREDITORHISTORY CH
		LEFT JOIN CASHITEM CI	ON (CI.TRANSENTITYNO = CH.REFENTITYNO
					AND CI.TRANSNO = CH.REFTRANSNO)
		LEFT JOIN NAME PAY	ON (CI.ACCTNAMENO = PAY.NAMENO)
		WHERE CH.REFTRANSNO IN (SELECT PPD.REFTRANSNO
					FROM PAYMENTPLANDETAIL PPD
					where PPD.PLANID = @pnPlanId)
		and (ABS(CH.LOCALVALUE)) <> 0
		
		Set	@nErrorCode = @@Error
		
		If @pbDebugFlag = 1
		Begin
			Print '*** Add Payable rows - Debit Accounts Payable ***'
			select @pnEntityNo AS JOURNALENTITYNO, @pnTransNo AS JOURNALTRANSNO, @sPayableProfitCentre AS PROFITCENTRE,
			@nPayableLedgerAcct AS LEDGERACCOUNT, (ABS(CH.LOCALVALUE)) AS LOCALAMOUNT, (ABS(CH.FOREIGNTRANVALUE)) AS FOREIGNAMOUNT,
			CH.CURRENCY, CH.EXCHRATE, CH.REFENTITYNO, CH.REFTRANSNO, 
			Case when CI.ITEMREFNO is not null then 'Payment ' + CI.ITEMREFNO
				end + ' ' +
			dbo.fn_FormatNameUsingNameNo(PAY.NAMENO, null) + 
			Case when PAY.NAMECODE is not null then ' {' + PAY.NAMECODE + '}'
				end + 
			Case when CH.DOCUMENTREF is not null then ' Invoice ' + CH.DOCUMENTREF
				end 
			from CREDITORHISTORY CH
			LEFT JOIN CASHITEM CI	ON (CI.TRANSENTITYNO = CH.REFENTITYNO
						AND CI.TRANSNO = CH.REFTRANSNO)
			LEFT JOIN NAME PAY	ON (CI.ACCTNAMENO = PAY.NAMENO)
			WHERE CH.REFTRANSNO IN (SELECT PPD.REFTRANSNO
						FROM PAYMENTPLANDETAIL PPD
						where PPD.PLANID = @pnPlanId)
			and (ABS(CH.LOCALVALUE)) <> 0
			
			Select @nErrorCode as ERRORCODE
		End
	End
		
	If @nErrorCode = 0
	Begin
		-- If variance is negative, debit loss account.
		-- Variance is always recorded in local currency.
		Insert into @tbLEDGERJOURNALLINE(ENTITYNO, TRANSNO, PROFITCENTRECODE, 
		ACCOUNTID, LOCALAMOUNT, FOREIGNAMOUNT, CURRENCY, EXCHRATE, ACCTENTITYNO)
		select @pnEntityNo, @pnTransNo, @sExchLossProfitCentre,
		@nExchLossLedgerAcct, (ABS(SUM (CH.EXCHVARIANCE))), NULL, NULL, NULL, @pnEntityNo
		from CREDITORHISTORY CH
		WHERE CH.REFTRANSNO IN (SELECT PPD.REFTRANSNO
					FROM PAYMENTPLANDETAIL PPD
					where PPD.PLANID = @pnPlanId)
		and CH.EXCHVARIANCE < 0
		GROUP BY CH.REFENTITYNO, CH.REFTRANSNO

		Set	@nErrorCode = @@Error

		If @pbDebugFlag = 1
		Begin
			Print '*** Add Exchange Loss rows - Debit Exchange Loss ***'
			select @pnEntityNo, @pnTransNo, @sExchLossProfitCentre,
			@nExchLossLedgerAcct, (ABS(SUM (CH.EXCHVARIANCE))), NULL, NULL, NULL, @pnEntityNo
			from CREDITORHISTORY CH
			WHERE CH.REFTRANSNO IN (SELECT PPD.REFTRANSNO
						FROM PAYMENTPLANDETAIL PPD
						where PPD.PLANID = @pnPlanId)
			and CH.EXCHVARIANCE < 0
			GROUP BY CH.REFENTITYNO, CH.REFTRANSNO

			Select @nErrorCode as ERRORCODE
		End
	End


	If @nErrorCode = 0
	Begin
		-- If variance is positive, credit gain account.
		-- Variance is always recorded in local currency.
		Insert into @tbLEDGERJOURNALLINE(ENTITYNO, TRANSNO, PROFITCENTRECODE, 
		ACCOUNTID, LOCALAMOUNT, FOREIGNAMOUNT, CURRENCY, EXCHRATE, ACCTENTITYNO)
		select @pnEntityNo, @pnTransNo, @sExchGainProfitCentre,
		@nExchGainLedgerAcct, (ABS(SUM(CH.EXCHVARIANCE))*-1), NULL, NULL, NULL, @pnEntityNo
		from CREDITORHISTORY CH
		WHERE CH.REFTRANSNO IN (SELECT PPD.REFTRANSNO
					FROM PAYMENTPLANDETAIL PPD
					where PPD.PLANID = @pnPlanId)
		and CH.EXCHVARIANCE > 0
		GROUP BY CH.REFENTITYNO, CH.REFTRANSNO
		
		Set	@nErrorCode = @@Error

		If @pbDebugFlag = 1
		Begin
			Print '*** Add Exchange Gain rows - Credit Exchange Gain ***'
			select @pnEntityNo, @pnTransNo, @sExchGainProfitCentre,
			@nExchGainLedgerAcct, (ABS(SUM(CH.EXCHVARIANCE))*-1), NULL, NULL, NULL, @pnEntityNo
			from CREDITORHISTORY CH
			WHERE CH.REFTRANSNO IN (SELECT PPD.REFTRANSNO
						FROM PAYMENTPLANDETAIL PPD
						where PPD.PLANID = @pnPlanId)
			and CH.EXCHVARIANCE > 0
			GROUP BY CH.REFENTITYNO, CH.REFTRANSNO

			Select @nErrorCode as ERRORCODE

		End
	End	

	-- Do Extra accounting required for Cash Accounting. 
	-- i.e. CR Suspense Account DR Expense
	If @bCashAccounting = 1
	Begin 
		-- sqa21636 suspense account no longer required for cash accounting
		-- 18895 Calculate payment Tax
		If @nErrorCode = 0
		Begin
			insert into @tbTAXES (LOCALTAX, FOREIGNTAX, ITEMENTITYNO, ITEMTRANSNO, REFENTITYNO, REFTRANSNO)						
			Select isnull((CH.LOCALVALUE * CI.LOCALTAXAMOUNT/CI.LOCALVALUE)*-1, 0),
			isnull((CH.FOREIGNTRANVALUE * CI.FOREIGNTAXAMT / CI.FOREIGNVALUE)*-1, 0), CH.ITEMENTITYNO, CH.ITEMTRANSNO, CH.REFENTITYNO, ch.REFTRANSNO
			from CREDITORHISTORY CH
			JOIN CREDITORITEM CI ON (CI.ITEMENTITYNO = CH.ITEMENTITYNO
									AND CI.ITEMTRANSNO = CH.ITEMTRANSNO)
			JOIN PAYMENTPLANDETAIL PPD 	ON (PPD.ITEMENTITYNO = CH.ITEMENTITYNO
							AND PPD.ITEMTRANSNO = CH.ITEMTRANSNO
							AND PPD.REFENTITYNO = CH.REFENTITYNO
							AND PPD.REFTRANSNO = CH.REFTRANSNO)
			WHERE PPD.PLANID = @pnPlanId
			and (ABS(CH.LOCALVALUE)) <> 0
			and ((ABS(CI.LOCALTAXAMOUNT)) <> 0
			or (ABS(CI.FOREIGNTAXAMT)) <> 0)
			
			Set	@nErrorCode = @@Error
			
			If @pbDebugFlag = 1
			Begin
				Print '*** Find tax amounts ***'
				
				Select isnull((CH.LOCALVALUE * CI.LOCALTAXAMOUNT/CI.LOCALVALUE)*-1, 0),
				isnull((CH.FOREIGNTRANVALUE * CI.FOREIGNTAXAMT / CI.FOREIGNVALUE)*-1, 0), CH.ITEMENTITYNO, CH.ITEMTRANSNO, CH.REFENTITYNO, ch.REFTRANSNO
				from CREDITORHISTORY CH
				JOIN CREDITORITEM CI ON (CI.ITEMENTITYNO = CH.ITEMENTITYNO
										AND CI.ITEMTRANSNO = CH.ITEMTRANSNO)
				JOIN PAYMENTPLANDETAIL PPD 	ON (PPD.ITEMENTITYNO = CH.ITEMENTITYNO
								AND PPD.ITEMTRANSNO = CH.ITEMTRANSNO
								AND PPD.REFENTITYNO = CH.REFENTITYNO
								AND PPD.REFTRANSNO = CH.REFTRANSNO)
				WHERE PPD.PLANID = @pnPlanId
				and (ABS(CH.LOCALVALUE)) <> 0
				and ((ABS(CI.LOCALTAXAMOUNT)) <> 0
				or (ABS(CI.FOREIGNTAXAMT)) <> 0)
			End			
		End

		-- Add Payable rows - Debit Expense Account
		-- sqa21636 use expense journal lines created during purchase as default expense journal lines
		-- 18895 Deduct sale Tax from the payment amount
		If @nErrorCode = 0
		Begin
			--Record in the currency of the item.
			Insert into @tbLEDGERJOURNALLINE(ENTITYNO, TRANSNO, PROFITCENTRECODE, 
			ACCOUNTID, LOCALAMOUNT, FOREIGNAMOUNT, CURRENCY, EXCHRATE, ACCTENTITYNO, NOTES)
			
			select 	@pnEntityNo, @pnTransNo, 
			-- Get profitcentre and account from expensejournalline created by the purchase if there are multiple expense journal lines.
			-- Otherwise use the profitcentre saved in the paymentplandetail which is derived from the supplier's expense account or user entered.
			Case when EJL2.EXPENSELINECOUNT > 1 then EJL.PROFITCENTRECODE else PPD.PROFITCENTRECODE end ProfitCentreCode,
			Case when EJL2.EXPENSELINECOUNT > 1 then EJL.ACCOUNTID else PPD.ACCOUNTID end AccountId, 
			
			-- LocalAmount - if exist multiple expense journal created by the purchase then use it. 
			-- Also handle partial payment by prorata and rounding error by adding the difference to the first journal line 
			Case when EJL2.EXPENSELINECOUNT > 1 
					then 
						round( (CH.LOCALVALUE / CRI.LOCALVALUE)*-1 * EJL.LOCALAMOUNT, 2) - round( abs(EJL.LOCALAMOUNT / CRI.LOCALVALUE) * isnull(T.LOCALTAX, 0), 2) + isnull(TEMP.ADJ_LOCAL, 0)
					else 
						(CH.LOCALVALUE)*-1 -  isnull(T.LOCALTAX, 0) 
			end LOCALAMOUNT, 
			
			-- ForeignAmount - if exist multiple expense journal created by the purchase then use it. 
			-- Also handle partial payment by prorata and rounding error by adding the difference to the first journal line 
			Case when CH.CURRENCY IS NOT NULL AND ISNULL(CH.FOREIGNTRANVALUE,0) <> 0 
			then 
				Case when EJL2.EXPENSELINECOUNT > 1 
					then
						round( (CH.FOREIGNTRANVALUE / CRI.FOREIGNVALUE)*-1 * EJL.FOREIGNAMOUNT, 2)  - round( abs(EJL.FOREIGNAMOUNT / CRI.FOREIGNVALUE) * isnull(T.FOREIGNTAX, 0), 2) + isnull(TEMP.ADJ_FOREIGN, 0)
					else	
						(CH.FOREIGNTRANVALUE)*-1 - isnull(T.FOREIGNTAX, 0) 
				end 
			end FOREIGNAMOUNT, 
			
			CH.CURRENCY, CH.EXCHRATE, @pnEntityNo,
			Case when CI.ITEMREFNO is not null then 'Payment ' + CI.ITEMREFNO
				end + ' ' +
			dbo.fn_FormatNameUsingNameNo(PAY.NAMENO, null) + 
			Case when PAY.NAMECODE is not null then ' {' + PAY.NAMECODE + '}'
				end + 
			Case when CH.DOCUMENTREF is not null then ' Invoice ' + CH.DOCUMENTREF
				end 
			from CREDITORHISTORY CH
			left join @tbTAXES T on (T.ITEMENTITYNO = CH.ITEMENTITYNO
						and T.ITEMTRANSNO = CH.ITEMTRANSNO
						and T.REFENTITYNO = CH.REFENTITYNO
						and T.REFTRANSNO = CH.REFTRANSNO)
			LEFT JOIN CASHITEM CI		ON (CI.TRANSENTITYNO = CH.REFENTITYNO
							AND CI.TRANSNO = CH.REFTRANSNO)
			LEFT JOIN NAME PAY		ON (CI.ACCTNAMENO = PAY.NAMENO)
			join PAYMENTPLANDETAIL PPD 	ON (PPD.ITEMENTITYNO = CH.ITEMENTITYNO
							AND PPD.ITEMTRANSNO = CH.ITEMTRANSNO
							AND PPD.REFENTITYNO = CH.REFENTITYNO
							AND PPD.REFTRANSNO = CH.REFTRANSNO)
			LEFT JOIN EXPENSEJOURNALLINE EJL ON EJL.ENTITYNO = PPD.ITEMENTITYNO 
							AND EJL.TRANSNO = PPD.ITEMTRANSNO

			JOIN CREDITORITEM CRI ON CRI.ITEMENTITYNO = PPD.ITEMENTITYNO
						AND CRI.ITEMTRANSNO = PPD.ITEMTRANSNO						

			-- Count the number of expense journal lines associated with the purchase
			LEFT JOIN (SELECT EX.ENTITYNO, EX.TRANSNO, COUNT(*) EXPENSELINECOUNT
				FROM EXPENSEJOURNALLINE EX
				LEFT JOIN CREDITORITEM CI ON CI.ITEMENTITYNO = EX.ENTITYNO
							AND CI.ITEMTRANSNO = EX.TRANSNO
				GROUP BY EX.ENTITYNO, EX.TRANSNO ) EJL2 ON EJL2.ENTITYNO = PPD.ITEMENTITYNO 
									AND EJL2.TRANSNO = PPD.ITEMTRANSNO

			-- Calculate rounding adjustment to be added to the first journal line
			LEFT JOIN (SELECT EJL2.TRANSNO, EJL2.ENTITYNO,  min(EJL2.SEQNO) as SEQNO,
				       MAX(ABS(CH2.FOREIGNTRANVALUE)) - SUM( ABS(Round( CH2.FOREIGNTRANVALUE / CI.FOREIGNVALUE * EJL2.FOREIGNAMOUNT, 2))) ADJ_FOREIGN,
				       MAX(ABS(CH2.LOCALVALUE)) - SUM( ABS(Round(CH2.LOCALVALUE / CI.LOCALVALUE * EJL2.LOCALAMOUNT, 2))) ADJ_LOCAL
				FROM CREDITORHISTORY CH2  
				join PAYMENTPLANDETAIL PPD2 	ON (PPD2.ITEMENTITYNO = CH2.ITEMENTITYNO
								AND PPD2.ITEMTRANSNO = CH2.ITEMTRANSNO
								AND PPD2.REFENTITYNO = CH2.REFENTITYNO
								AND PPD2.REFTRANSNO = CH2.REFTRANSNO)
				JOIN CREDITORITEM CI		ON CI.ITEMENTITYNO = PPD2.ITEMENTITYNO
								AND CI.ITEMTRANSNO = PPD2.ITEMTRANSNO
				JOIN EXPENSEJOURNALLINE EJL2 ON EJL2.ENTITYNO = PPD2.ITEMENTITYNO 
								AND EJL2.TRANSNO = PPD2.ITEMTRANSNO
				WHERE PPD2.PLANID = @pnPlanId
				GROUP BY EJL2.TRANSNO, EJL2.ENTITYNO)  TEMP  ON TEMP.ENTITYNO = EJL.ENTITYNO
									AND TEMP.TRANSNO = EJL.TRANSNO
									AND TEMP.SEQNO = EJL.SEQNO
									

			WHERE PPD.PLANID = @pnPlanId
			and (ABS(CH.LOCALVALUE)) <> 0
			
			Set	@nErrorCode = @@Error
			
			If @pbDebugFlag = 1
			Begin
				Print '*** Add Payable rows - Debit Expense Account ***'
				select 	@pnEntityNo, @pnTransNo, 
				-- Get profitcentre and account from expensejournalline created by the purchase if there are multiple expense journal lines.
				-- Otherwise use the profitcentre saved in the paymentplandetail which is derived from the supplier's expense account or user entered.
				Case when EJL2.EXPENSELINECOUNT > 1 then EJL.PROFITCENTRECODE else PPD.PROFITCENTRECODE end ProfitCentreCode,
				Case when EJL2.EXPENSELINECOUNT > 1 then EJL.ACCOUNTID else PPD.ACCOUNTID end AccountId, 
				
				-- LocalAmount - if exist multiple expense journal created by the purchase then use it. 
				-- Also handle partial payment by prorata and rounding error by adding the difference to the first journal line 
				Case when EJL2.EXPENSELINECOUNT > 1 
						then 
							round( (CH.LOCALVALUE / CRI.LOCALVALUE)*-1 * EJL.LOCALAMOUNT, 2) - round( abs(EJL.LOCALAMOUNT / CRI.LOCALVALUE) * isnull(T.LOCALTAX, 0), 2) + isnull(TEMP.ADJ_LOCAL, 0)
						else 
							(CH.LOCALVALUE)*-1 -  isnull(T.LOCALTAX, 0) 
				end LOCALAMOUNT, 
				
				-- ForeignAmount - if exist multiple expense journal created by the purchase then use it. 
				-- Also handle partial payment by prorata and rounding error by adding the difference to the first journal line 
				Case when CH.CURRENCY IS NOT NULL AND ISNULL(CH.FOREIGNTRANVALUE,0) <> 0 
				then 
					Case when EJL2.EXPENSELINECOUNT > 1 
						then
							round( (CH.FOREIGNTRANVALUE / CRI.FOREIGNVALUE)*-1 * EJL.FOREIGNAMOUNT, 2)  - round( abs(EJL.FOREIGNAMOUNT / CRI.FOREIGNVALUE) * isnull(T.FOREIGNTAX, 0), 2) + isnull(TEMP.ADJ_FOREIGN, 0)
						else	
							(CH.FOREIGNTRANVALUE)*-1 - isnull(T.FOREIGNTAX, 0) 
					end 
				end FOREIGNAMOUNT, 
				
				CH.CURRENCY, CH.EXCHRATE, @pnEntityNo,
				Case when CI.ITEMREFNO is not null then 'Payment ' + CI.ITEMREFNO
					end + ' ' +
				dbo.fn_FormatNameUsingNameNo(PAY.NAMENO, null) + 
				Case when PAY.NAMECODE is not null then ' {' + PAY.NAMECODE + '}'
					end + 
				Case when CH.DOCUMENTREF is not null then ' Invoice ' + CH.DOCUMENTREF
					end 
				from CREDITORHISTORY CH
				left join @tbTAXES T on (T.ITEMENTITYNO = CH.ITEMENTITYNO
							and T.ITEMTRANSNO = CH.ITEMTRANSNO
							and T.REFENTITYNO = CH.REFENTITYNO
							and T.REFTRANSNO = CH.REFTRANSNO)
				LEFT JOIN CASHITEM CI		ON (CI.TRANSENTITYNO = CH.REFENTITYNO
								AND CI.TRANSNO = CH.REFTRANSNO)
				LEFT JOIN NAME PAY		ON (CI.ACCTNAMENO = PAY.NAMENO)
				join PAYMENTPLANDETAIL PPD 	ON (PPD.ITEMENTITYNO = CH.ITEMENTITYNO
								AND PPD.ITEMTRANSNO = CH.ITEMTRANSNO
								AND PPD.REFENTITYNO = CH.REFENTITYNO
								AND PPD.REFTRANSNO = CH.REFTRANSNO)
				LEFT JOIN EXPENSEJOURNALLINE EJL ON EJL.ENTITYNO = PPD.ITEMENTITYNO 
								AND EJL.TRANSNO = PPD.ITEMTRANSNO

				JOIN CREDITORITEM CRI ON CRI.ITEMENTITYNO = PPD.ITEMENTITYNO
							AND CRI.ITEMTRANSNO = PPD.ITEMTRANSNO						

				-- Count the number of expense journal lines associated with the purchase
				LEFT JOIN (SELECT EX.ENTITYNO, EX.TRANSNO, COUNT(*) EXPENSELINECOUNT
					FROM EXPENSEJOURNALLINE EX
					LEFT JOIN CREDITORITEM CI ON CI.ITEMENTITYNO = EX.ENTITYNO
								AND CI.ITEMTRANSNO = EX.TRANSNO
					GROUP BY EX.ENTITYNO, EX.TRANSNO ) EJL2 ON EJL2.ENTITYNO = PPD.ITEMENTITYNO 
										AND EJL2.TRANSNO = PPD.ITEMTRANSNO

				-- Calculate rounding adjustment to be added to the first journal line
				LEFT JOIN (SELECT EJL2.TRANSNO, EJL2.ENTITYNO,  min(EJL2.SEQNO) as SEQNO,
					       MAX(ABS(CH2.FOREIGNTRANVALUE)) - SUM( ABS(Round( CH2.FOREIGNTRANVALUE / CI.FOREIGNVALUE * EJL2.FOREIGNAMOUNT, 2))) ADJ_FOREIGN,
					       MAX(ABS(CH2.LOCALVALUE)) - SUM( ABS(Round(CH2.LOCALVALUE / CI.LOCALVALUE * EJL2.LOCALAMOUNT, 2))) ADJ_LOCAL
					FROM CREDITORHISTORY CH2  
					join PAYMENTPLANDETAIL PPD2 	ON (PPD2.ITEMENTITYNO = CH2.ITEMENTITYNO
									AND PPD2.ITEMTRANSNO = CH2.ITEMTRANSNO
									AND PPD2.REFENTITYNO = CH2.REFENTITYNO
									AND PPD2.REFTRANSNO = CH2.REFTRANSNO)
					JOIN CREDITORITEM CI		ON CI.ITEMENTITYNO = PPD2.ITEMENTITYNO
									AND CI.ITEMTRANSNO = PPD2.ITEMTRANSNO
					JOIN EXPENSEJOURNALLINE EJL2 ON EJL2.ENTITYNO = PPD2.ITEMENTITYNO 
									AND EJL2.TRANSNO = PPD2.ITEMTRANSNO
					WHERE PPD2.PLANID = @pnPlanId
					GROUP BY EJL2.TRANSNO, EJL2.ENTITYNO)  TEMP  ON TEMP.ENTITYNO = EJL.ENTITYNO
										AND TEMP.TRANSNO = EJL.TRANSNO
										AND TEMP.SEQNO = EJL.SEQNO
										

				WHERE PPD.PLANID = @pnPlanId
				and (ABS(CH.LOCALVALUE)) <> 0
			End
		End


		-- 18895 Debit Tax account
		If @nErrorCode = 0 and exists (select * from @tbTAXES)
		Begin
			Insert into @tbLEDGERJOURNALLINE(ENTITYNO, TRANSNO, PROFITCENTRECODE, 
			ACCOUNTID, LOCALAMOUNT, FOREIGNAMOUNT, CURRENCY, EXCHRATE, ACCTENTITYNO, NOTES)
			
			select @pnEntityNo, @pnTransNo, @sTaxProfitCentre,
			@nTaxLedgerAcct, 
			T.LOCALTAX, case when CH.CURRENCY is null and T.FOREIGNTAX = 0 then null else T.FOREIGNTAX end,
			CH.CURRENCY, CH.EXCHRATE, @pnEntityNo,
			Case when CI.ITEMREFNO is not null then 'Payment ' + CI.ITEMREFNO
				end + ' ' +
			dbo.fn_FormatNameUsingNameNo(PAY.NAMENO, null) + 
			Case when PAY.NAMECODE is not null then ' {' + PAY.NAMECODE + '}'
				end + 
			Case when CH.DOCUMENTREF is not null then ' Invoice ' + CH.DOCUMENTREF
				end
			from CREDITORHISTORY CH
			left join @tbTAXES T on (T.ITEMENTITYNO = CH.ITEMENTITYNO
						and T.ITEMTRANSNO = CH.ITEMTRANSNO
						and T.REFENTITYNO = CH.REFENTITYNO
						and T.REFTRANSNO = CH.REFTRANSNO)			
			LEFT JOIN CASHITEM CI	ON (CI.TRANSENTITYNO = CH.REFENTITYNO
						AND CI.TRANSNO = CH.REFTRANSNO)
			LEFT JOIN NAME PAY	ON (CI.ACCTNAMENO = PAY.NAMENO)
			JOIN PAYMENTPLANDETAIL PPD 	ON (PPD.ITEMENTITYNO = CH.ITEMENTITYNO
							AND PPD.ITEMTRANSNO = CH.ITEMTRANSNO
							AND PPD.REFENTITYNO = CH.REFENTITYNO
							AND PPD.REFTRANSNO = CH.REFTRANSNO)
			WHERE PPD.PLANID = @pnPlanId
			and (ABS(CH.LOCALVALUE)) <> 0
			and ( T.LOCALTAX <> 0 or T.FOREIGNTAX <> 0 )
			
			Set	@nErrorCode = @@Error
			
			If @pbDebugFlag = 1
			Begin
				Print '*** Add Payable rows - Debit Tax Account ***'
				select @pnEntityNo, @pnTransNo, @sTaxProfitCentre,
				@nTaxLedgerAcct, 
				T.LOCALTAX, case when CH.CURRENCY is null and T.FOREIGNTAX = 0 then null else T.FOREIGNTAX end,
				CH.CURRENCY, CH.EXCHRATE, @pnEntityNo,
				Case when CI.ITEMREFNO is not null then 'Payment ' + CI.ITEMREFNO
					end + ' ' +
				dbo.fn_FormatNameUsingNameNo(PAY.NAMENO, null) + 
				Case when PAY.NAMECODE is not null then ' {' + PAY.NAMECODE + '}'
					end + 
				Case when CH.DOCUMENTREF is not null then ' Invoice ' + CH.DOCUMENTREF
					end
				from CREDITORHISTORY CH
				left join @tbTAXES T on (T.ITEMENTITYNO = CH.ITEMENTITYNO
							and T.ITEMTRANSNO = CH.ITEMTRANSNO
							and T.REFENTITYNO = CH.REFENTITYNO
							and T.REFTRANSNO = CH.REFTRANSNO)			
				LEFT JOIN CASHITEM CI	ON (CI.TRANSENTITYNO = CH.REFENTITYNO
							AND CI.TRANSNO = CH.REFTRANSNO)
				LEFT JOIN NAME PAY	ON (CI.ACCTNAMENO = PAY.NAMENO)
				JOIN PAYMENTPLANDETAIL PPD 	ON (PPD.ITEMENTITYNO = CH.ITEMENTITYNO
								AND PPD.ITEMTRANSNO = CH.ITEMTRANSNO
								AND PPD.REFENTITYNO = CH.REFENTITYNO
								AND PPD.REFTRANSNO = CH.REFTRANSNO)
				WHERE PPD.PLANID = @pnPlanId
				and (ABS(CH.LOCALVALUE)) <> 0
				
				Set	@nErrorCode = @@Error
			End
		End
	End
End
Else 	
Begin	
	If @pbDebugFlag = 1
	Begin
		Print '*** Details for an individual payment ***'
	End

	-- SQA21636 - Only add Payable row if NOT Cash Accounting because we are no longer use Suspense account in Cash Accounting
	If @nErrorCode = 0 and 	@bCashAccounting <> 1
	Begin
		--Record in the currency of the item.
		Insert into @tbLEDGERJOURNALLINE(ENTITYNO, TRANSNO, PROFITCENTRECODE, 
		ACCOUNTID, LOCALAMOUNT, FOREIGNAMOUNT, CURRENCY, EXCHRATE, ACCTENTITYNO, NOTES)
		select @pnEntityNo, @pnTransNo, @sPayableProfitCentre,
		@nPayableLedgerAcct, CH.LOCALVALUE*-1, CH.FOREIGNTRANVALUE*-1,
		CH.CURRENCY, CH.EXCHRATE, @pnEntityNo,
		Case when CI.ITEMREFNO is not null then 'Payment ' + CI.ITEMREFNO
			end + ' ' +
		dbo.fn_FormatNameUsingNameNo(PAY.NAMENO, null) + 
		Case when PAY.NAMECODE is not null then ' {' + PAY.NAMECODE + '}'
			end + 
		Case when CH.DOCUMENTREF is not null then ' Invoice ' + CH.DOCUMENTREF
			end 
		from CREDITORHISTORY CH
		LEFT JOIN CASHITEM CI	ON (CI.TRANSENTITYNO = CH.REFENTITYNO
					AND CI.TRANSNO = CH.REFTRANSNO)
		LEFT JOIN NAME PAY	ON (CI.ACCTNAMENO = PAY.NAMENO)
		where CH.REFENTITYNO = @pnEntityNo
		and CH.REFTRANSNO = @pnTransNo
		and ABS(CH.LOCALVALUE) <> 0

		Set	@nErrorCode = @@Error

		If @pbDebugFlag = 1
		Begin
			Print '*** Add Payable rows - Debit Accounts Payable ***'
			select @pnEntityNo, @pnTransNo, @sPayableProfitCentre,
			@nPayableLedgerAcct, CH.LOCALVALUE*-1, CH.FOREIGNTRANVALUE*-1,
			CH.CURRENCY, CH.EXCHRATE, @pnEntityNo,
			Case when CI.ITEMREFNO is not null then 'Payment ' + CI.ITEMREFNO
				end + ' ' +
			dbo.fn_FormatNameUsingNameNo(PAY.NAMENO, null) + 
			Case when PAY.NAMECODE is not null then ' {' + PAY.NAMECODE + '}'
				end + 
			Case when CH.DOCUMENTREF is not null then ' Invoice ' + CH.DOCUMENTREF
				end 
			from CREDITORHISTORY CH
			LEFT JOIN CASHITEM CI	ON (CI.TRANSENTITYNO = CH.REFENTITYNO
						AND CI.TRANSNO = CH.REFTRANSNO)
			LEFT JOIN NAME PAY	ON (CI.ACCTNAMENO = PAY.NAMENO)
			where CH.REFENTITYNO = @pnEntityNo
			and CH.REFTRANSNO = @pnTransNo
			and ABS(CH.LOCALVALUE) <> 0
			
			Select @nErrorCode as ERRORCODE
		End
	End

		
	If @nErrorCode = 0
	Begin
		-- If variance is negative, debit loss account.
		-- Variance is always recorded in local currency.
		Insert into @tbLEDGERJOURNALLINE(ENTITYNO, TRANSNO, PROFITCENTRECODE, 
		ACCOUNTID, LOCALAMOUNT, FOREIGNAMOUNT, CURRENCY, EXCHRATE, ACCTENTITYNO)
		select @pnEntityNo, @pnTransNo, @sExchLossProfitCentre,
		@nExchLossLedgerAcct, (ABS(SUM(CH.EXCHVARIANCE))), NULL, NULL, NULL, @pnEntityNo
		from CREDITORHISTORY CH
		where CH.REFENTITYNO = @pnEntityNo
		and CH.REFTRANSNO = @pnTransNo
		and CH.EXCHVARIANCE < 0
		GROUP BY CH.REFENTITYNO, CH.REFTRANSNO

		Set	@nErrorCode = @@Error

		If @pbDebugFlag = 1
		Begin
			Print '*** Add Exchange Loss rows - Debit Exchange Loss ***'
			select @pnEntityNo, @pnTransNo, @sExchLossProfitCentre,
			@nExchLossLedgerAcct, (ABS(SUM (CH.EXCHVARIANCE))), NULL, NULL, NULL, @pnEntityNo
			from CREDITORHISTORY CH
			where CH.REFENTITYNO = @pnEntityNo
			and CH.REFTRANSNO = @pnTransNo
			and CH.EXCHVARIANCE < 0
			GROUP BY CH.REFENTITYNO, CH.REFTRANSNO

			Select @nErrorCode as ERRORCODE
		End
	End

	If @nErrorCode = 0
	Begin
		-- If variance is positive, credit gain account.
		-- Variance is always recorded in local currency.
		Insert into @tbLEDGERJOURNALLINE(ENTITYNO, TRANSNO, PROFITCENTRECODE, 
		ACCOUNTID, LOCALAMOUNT, FOREIGNAMOUNT, CURRENCY, EXCHRATE, ACCTENTITYNO)
		select @pnEntityNo, @pnTransNo, @sExchGainProfitCentre,
		@nExchGainLedgerAcct, (ABS(SUM (CH.EXCHVARIANCE))*-1), NULL, NULL, NULL, @pnEntityNo
		from CREDITORHISTORY CH
		where CH.REFENTITYNO = @pnEntityNo
		and CH.REFTRANSNO = @pnTransNo
		and CH.EXCHVARIANCE > 0
		GROUP BY CH.REFENTITYNO, CH.REFTRANSNO

		Set	@nErrorCode = @@Error

		If @pbDebugFlag = 1
		Begin
			Print '*** Add Exchange Gain rows - Credit Exchange Gain ***'
			select @pnEntityNo, @pnTransNo, @sExchGainProfitCentre,
			@nExchGainLedgerAcct, (ABS(SUM (CH.EXCHVARIANCE))*-1), NULL, NULL, NULL, @pnEntityNo
			from CREDITORHISTORY CH
			where CH.REFENTITYNO = @pnEntityNo
			and CH.REFTRANSNO = @pnTransNo
			and CH.EXCHVARIANCE > 0
			GROUP BY CH.REFENTITYNO, CH.REFTRANSNO

			Select @nErrorCode as ERRORCODE

		End
	End

	-- Do Extra accounting required for Cash Accounting. 
	-- i.e. CR Suspense Account, DR Expense
	If @bCashAccounting = 1
	Begin 		
		-- 18895 Calculate payment Tax
		If @nErrorCode = 0
		Begin	
			delete from @tbTAXES
		
			insert into @tbTAXES (LOCALTAX, FOREIGNTAX, ITEMENTITYNO, ITEMTRANSNO, REFENTITYNO, REFTRANSNO)
			Select  isnull(CH.LOCALVALUE * CRI.LOCALTAXAMOUNT/CRI.LOCALVALUE, 0)*-1,
			isnull(CH.FOREIGNTRANVALUE * CRI.FOREIGNTAXAMT / CRI.FOREIGNVALUE, 0)*-1, CH.ITEMENTITYNO, CH.ITEMTRANSNO, CH.REFENTITYNO, CH.REFTRANSNO
			from CREDITORHISTORY CH
			JOIN CREDITORITEM CRI ON (CRI.ITEMENTITYNO = CH.ITEMENTITYNO
									AND CRI.ITEMTRANSNO = CH.ITEMTRANSNO)
			LEFT JOIN CASHITEM CI		ON (CI.TRANSENTITYNO = CH.REFENTITYNO
							AND CI.TRANSNO = CH.REFTRANSNO)
			LEFT JOIN NAME PAY		ON (CI.ACCTNAMENO = PAY.NAMENO)
			join PAYMENTPLANDETAIL PPD 	ON (PPD.ITEMENTITYNO = CH.ITEMENTITYNO
							AND PPD.ITEMTRANSNO = CH.ITEMTRANSNO
							AND PPD.REFENTITYNO = CH.REFENTITYNO
							AND PPD.REFTRANSNO = CH.REFTRANSNO)
			where CH.REFENTITYNO = @pnEntityNo
			and CH.REFTRANSNO = @pnTransNo
			and PPD.PLANID = @pnPlanId
			and ABS(CH.LOCALVALUE) <> 0
			and ((ABS(CRI.LOCALTAXAMOUNT)) <> 0
			or (ABS(CRI.FOREIGNTAXAMT)) <> 0)

			Set	@nErrorCode = @@Error
			
			If @pbDebugFlag = 1
			Begin
				Print '*** Find tax amounts ***'
				
				Select  isnull(CH.LOCALVALUE * CRI.LOCALTAXAMOUNT/CRI.LOCALVALUE, 0)*-1,
				isnull(CH.FOREIGNTRANVALUE * CRI.FOREIGNTAXAMT / CRI.FOREIGNVALUE, 0)*-1, CH.ITEMENTITYNO, CH.ITEMTRANSNO, CH.REFENTITYNO, CH.REFTRANSNO
				from CREDITORHISTORY CH
				JOIN CREDITORITEM CRI ON (CRI.ITEMENTITYNO = CH.ITEMENTITYNO
										AND CRI.ITEMTRANSNO = CH.ITEMTRANSNO)
				LEFT JOIN CASHITEM CI		ON (CI.TRANSENTITYNO = CH.REFENTITYNO
								AND CI.TRANSNO = CH.REFTRANSNO)
				LEFT JOIN NAME PAY		ON (CI.ACCTNAMENO = PAY.NAMENO)
				join PAYMENTPLANDETAIL PPD 	ON (PPD.ITEMENTITYNO = CH.ITEMENTITYNO
								AND PPD.ITEMTRANSNO = CH.ITEMTRANSNO
								AND PPD.REFENTITYNO = CH.REFENTITYNO
								AND PPD.REFTRANSNO = CH.REFTRANSNO)
				where CH.REFENTITYNO = @pnEntityNo
				and CH.REFTRANSNO = @pnTransNo
				and PPD.PLANID = @pnPlanId
				and ABS(CH.LOCALVALUE) <> 0
				and ((ABS(CRI.LOCALTAXAMOUNT)) <> 0
				or (ABS(CRI.FOREIGNTAXAMT)) <> 0)	
			End
		End
				
		-- sqa21636 use expense journal lines created during purchase as default expense journal lines
		-- Add Payable rows - Debit Expense Account
		-- 18895 Deduct sale Tax from the payment amount
		If @nErrorCode = 0
		Begin
			--Record in the currency of the item.
			Insert into @tbLEDGERJOURNALLINE(ENTITYNO, TRANSNO, PROFITCENTRECODE, 
			ACCOUNTID, LOCALAMOUNT, FOREIGNAMOUNT, CURRENCY, EXCHRATE, ACCTENTITYNO, NOTES)
			
			select 	@pnEntityNo, @pnTransNo, 
			-- Get profitcentre and account from expensejournalline created by the purchase if there are multiple expense journal lines.
			-- Otherwise use the profitcentre saved in the paymentplandetail which is derived from the supplier's expense account or user entered.
			Case when EJL2.EXPENSELINECOUNT > 1 then EJL.PROFITCENTRECODE else PPD.PROFITCENTRECODE end ProfitCentreCode,
			Case when EJL2.EXPENSELINECOUNT > 1 then EJL.ACCOUNTID else PPD.ACCOUNTID end AccountId, 
			
			-- LocalAmount - if exist multiple expense journal created by the purchase then use it. 
			-- Also handle partial payment by prorata and rounding error by adding the difference to the first journal line 
			Case when EJL2.EXPENSELINECOUNT > 1 
					then 
						round( (CH.LOCALVALUE / CRI.LOCALVALUE)*-1 * EJL.LOCALAMOUNT, 2) - round( abs(EJL.LOCALAMOUNT / CRI.LOCALVALUE) * isnull(T.LOCALTAX, 0), 2) + isnull(TEMP.ADJ_LOCAL, 0)
					else 
						(CH.LOCALVALUE)*-1 -  isnull(T.LOCALTAX, 0) 
			end LOCALAMOUNT, 
			
			-- ForeignAmount - if exist multiple expense journal created by the purchase then use it. 
			-- Also handle partial payment by prorata and rounding error by adding the difference to the first journal line 
			Case when CH.CURRENCY IS NOT NULL AND ISNULL(CH.FOREIGNTRANVALUE,0) <> 0 
			then 
				Case when EJL2.EXPENSELINECOUNT > 1 
					then
						round( (CH.FOREIGNTRANVALUE / CRI.FOREIGNVALUE)*-1 * EJL.FOREIGNAMOUNT, 2)  - round( abs(EJL.FOREIGNAMOUNT / CRI.FOREIGNVALUE) * isnull(T.FOREIGNTAX, 0), 2) + isnull(TEMP.ADJ_FOREIGN, 0)
					else	
						(CH.FOREIGNTRANVALUE)*-1 - isnull(T.FOREIGNTAX, 0) 
				end 
			end FOREIGNAMOUNT, 
			
			CH.CURRENCY, CH.EXCHRATE, @pnEntityNo,
			Case when CI.ITEMREFNO is not null then 'Payment ' + CI.ITEMREFNO
				end + ' ' +
			dbo.fn_FormatNameUsingNameNo(PAY.NAMENO, null) + 
			Case when PAY.NAMECODE is not null then ' {' + PAY.NAMECODE + '}'
				end + 
			Case when CH.DOCUMENTREF is not null then ' Invoice ' + CH.DOCUMENTREF
				end 
			from CREDITORHISTORY CH
			left join @tbTAXES T		ON (T.ITEMENTITYNO = CH.ITEMENTITYNO
							AND T.ITEMTRANSNO = CH.ITEMTRANSNO
							AND T.REFENTITYNO = CH.REFENTITYNO
							AND T.REFTRANSNO = CH.REFTRANSNO)
			LEFT JOIN CASHITEM CI		ON (CI.TRANSENTITYNO = CH.REFENTITYNO
							AND CI.TRANSNO = CH.REFTRANSNO)
			LEFT JOIN NAME PAY		ON (CI.ACCTNAMENO = PAY.NAMENO)
			join PAYMENTPLANDETAIL PPD 	ON (PPD.ITEMENTITYNO = CH.ITEMENTITYNO
							AND PPD.ITEMTRANSNO = CH.ITEMTRANSNO
							AND PPD.REFENTITYNO = CH.REFENTITYNO
							AND PPD.REFTRANSNO = CH.REFTRANSNO)
			LEFT JOIN EXPENSEJOURNALLINE EJL ON EJL.ENTITYNO = PPD.ITEMENTITYNO 
							AND EJL.TRANSNO = PPD.ITEMTRANSNO

			JOIN CREDITORITEM CRI ON CRI.ITEMENTITYNO = PPD.ITEMENTITYNO
						AND CRI.ITEMTRANSNO = PPD.ITEMTRANSNO						

			-- Count the number of expense journal lines associated with the purchase
			-- if exist multiple expense journal created by the purchase then use the ledger account and profit centre from these expense journal lines
			LEFT JOIN (SELECT EX.ENTITYNO, EX.TRANSNO, COUNT(*) EXPENSELINECOUNT
				FROM EXPENSEJOURNALLINE EX
				LEFT JOIN CREDITORITEM CI ON CI.ITEMENTITYNO = EX.ENTITYNO
							AND CI.ITEMTRANSNO = EX.TRANSNO
				GROUP BY EX.ENTITYNO, EX.TRANSNO ) EJL2 ON EJL2.ENTITYNO = PPD.ITEMENTITYNO 
									AND EJL2.TRANSNO = PPD.ITEMTRANSNO

			-- Calculate rounding adjustment to be added to the first journal line
			LEFT JOIN (SELECT EJL2.TRANSNO, EJL2.ENTITYNO,  min(EJL2.SEQNO) as SEQNO,
				       MAX(ABS(CH2.FOREIGNTRANVALUE)) - SUM( ABS(Round( CH2.FOREIGNTRANVALUE / CI.FOREIGNVALUE * EJL2.FOREIGNAMOUNT, 2))) ADJ_FOREIGN,
				       MAX(ABS(CH2.LOCALVALUE)) - SUM( ABS(Round(CH2.LOCALVALUE / CI.LOCALVALUE * EJL2.LOCALAMOUNT, 2))) ADJ_LOCAL
				FROM CREDITORHISTORY CH2  
				join PAYMENTPLANDETAIL PPD2 	ON (PPD2.ITEMENTITYNO = CH2.ITEMENTITYNO
								AND PPD2.ITEMTRANSNO = CH2.ITEMTRANSNO
								AND PPD2.REFENTITYNO = CH2.REFENTITYNO
								AND PPD2.REFTRANSNO = CH2.REFTRANSNO)
				JOIN CREDITORITEM CI		ON CI.ITEMENTITYNO = PPD2.ITEMENTITYNO
								AND CI.ITEMTRANSNO = PPD2.ITEMTRANSNO
				JOIN EXPENSEJOURNALLINE EJL2 ON EJL2.ENTITYNO = PPD2.ITEMENTITYNO 
								AND EJL2.TRANSNO = PPD2.ITEMTRANSNO
				WHERE PPD2.PLANID = @pnPlanId
				GROUP BY EJL2.TRANSNO, EJL2.ENTITYNO)  TEMP  ON TEMP.ENTITYNO = EJL.ENTITYNO
									AND TEMP.TRANSNO = EJL.TRANSNO
									AND TEMP.SEQNO = EJL.SEQNO
			where CH.REFENTITYNO =  @pnEntityNo
			and CH.REFTRANSNO =  @pnTransNo
			and PPD.PLANID = @pnPlanId
			and ABS(CH.LOCALVALUE) <> 0
			
			Set	@nErrorCode = @@Error

			If @pbDebugFlag = 1
			Begin
				Print '*** Add Payable rows - Debit Expense Account ***'

				select 	@pnEntityNo, @pnTransNo, 
				-- Get profitcentre and account from expensejournalline created by the purchase if there are multiple expense journal lines.
				-- Otherwise use the profitcentre saved in the paymentplandetail which is derived from the supplier's expense account or user entered.
				Case when EJL2.EXPENSELINECOUNT > 1 then EJL.PROFITCENTRECODE else PPD.PROFITCENTRECODE end ProfitCentreCode,
				Case when EJL2.EXPENSELINECOUNT > 1 then EJL.ACCOUNTID else PPD.ACCOUNTID end AccountId, 
				
				-- LocalAmount - if exist multiple expense journal created by the purchase then use it. 
				-- Also handle partial payment by prorata and rounding error by adding the difference to the first journal line 
				Case when EJL2.EXPENSELINECOUNT > 1 
						then 
							round( (CH.LOCALVALUE / CRI.LOCALVALUE)*-1 * EJL.LOCALAMOUNT, 2) - round( abs(EJL.LOCALAMOUNT / CRI.LOCALVALUE) * isnull(T.LOCALTAX, 0), 2) + isnull(TEMP.ADJ_LOCAL, 0)
						else 
							(CH.LOCALVALUE)*-1 -  isnull(T.LOCALTAX, 0) 
				end LOCALAMOUNT, 
				
				-- ForeignAmount - if exist multiple expense journal created by the purchase then use it. 
				-- Also handle partial payment by prorata and rounding error by adding the difference to the first journal line 
				Case when CH.CURRENCY IS NOT NULL AND ISNULL(CH.FOREIGNTRANVALUE,0) <> 0 
				then 
					Case when EJL2.EXPENSELINECOUNT > 1 
						then
							round( (CH.FOREIGNTRANVALUE / CRI.FOREIGNVALUE)*-1 * EJL.FOREIGNAMOUNT, 2)  - round( abs(EJL.FOREIGNAMOUNT / CRI.FOREIGNVALUE) * isnull(T.FOREIGNTAX, 0), 2) + isnull(TEMP.ADJ_FOREIGN, 0)
						else	
							(CH.FOREIGNTRANVALUE)*-1 - isnull(T.FOREIGNTAX, 0) 
					end 
				end FOREIGNAMOUNT, 
				
				CH.CURRENCY, CH.EXCHRATE, @pnEntityNo,
				Case when CI.ITEMREFNO is not null then 'Payment ' + CI.ITEMREFNO
					end + ' ' +
				dbo.fn_FormatNameUsingNameNo(PAY.NAMENO, null) + 
				Case when PAY.NAMECODE is not null then ' {' + PAY.NAMECODE + '}'
					end + 
				Case when CH.DOCUMENTREF is not null then ' Invoice ' + CH.DOCUMENTREF
					end 
				from CREDITORHISTORY CH
				left join @tbTAXES T		ON (T.ITEMENTITYNO = CH.ITEMENTITYNO
								AND T.ITEMTRANSNO = CH.ITEMTRANSNO
								AND T.REFENTITYNO = CH.REFENTITYNO
								AND T.REFTRANSNO = CH.REFTRANSNO)
				LEFT JOIN CASHITEM CI		ON (CI.TRANSENTITYNO = CH.REFENTITYNO
								AND CI.TRANSNO = CH.REFTRANSNO)
				LEFT JOIN NAME PAY		ON (CI.ACCTNAMENO = PAY.NAMENO)
				join PAYMENTPLANDETAIL PPD 	ON (PPD.ITEMENTITYNO = CH.ITEMENTITYNO
								AND PPD.ITEMTRANSNO = CH.ITEMTRANSNO
								AND PPD.REFENTITYNO = CH.REFENTITYNO
								AND PPD.REFTRANSNO = CH.REFTRANSNO)
				LEFT JOIN EXPENSEJOURNALLINE EJL ON EJL.ENTITYNO = PPD.ITEMENTITYNO 
								AND EJL.TRANSNO = PPD.ITEMTRANSNO

				JOIN CREDITORITEM CRI ON CRI.ITEMENTITYNO = PPD.ITEMENTITYNO
							AND CRI.ITEMTRANSNO = PPD.ITEMTRANSNO						

				-- Count the number of expense journal lines associated with the purchase
				-- if exist multiple expense journal created by the purchase then use the ledger account and profit centre from these expense journal lines
				LEFT JOIN (SELECT EX.ENTITYNO, EX.TRANSNO, COUNT(*) EXPENSELINECOUNT
					FROM EXPENSEJOURNALLINE EX
					LEFT JOIN CREDITORITEM CI ON CI.ITEMENTITYNO = EX.ENTITYNO
								AND CI.ITEMTRANSNO = EX.TRANSNO
					GROUP BY EX.ENTITYNO, EX.TRANSNO ) EJL2 ON EJL2.ENTITYNO = PPD.ITEMENTITYNO 
										AND EJL2.TRANSNO = PPD.ITEMTRANSNO

				-- Calculate rounding adjustment to be added to the first journal line
				LEFT JOIN (SELECT EJL2.TRANSNO, EJL2.ENTITYNO,  min(EJL2.SEQNO) as SEQNO,
					       MAX(ABS(CH2.FOREIGNTRANVALUE)) - SUM( ABS(Round( CH2.FOREIGNTRANVALUE / CI.FOREIGNVALUE * EJL2.FOREIGNAMOUNT, 2))) ADJ_FOREIGN,
					       MAX(ABS(CH2.LOCALVALUE)) - SUM( ABS(Round(CH2.LOCALVALUE / CI.LOCALVALUE * EJL2.LOCALAMOUNT, 2))) ADJ_LOCAL
					FROM CREDITORHISTORY CH2  
					join PAYMENTPLANDETAIL PPD2 	ON (PPD2.ITEMENTITYNO = CH2.ITEMENTITYNO
									AND PPD2.ITEMTRANSNO = CH2.ITEMTRANSNO
									AND PPD2.REFENTITYNO = CH2.REFENTITYNO
									AND PPD2.REFTRANSNO = CH2.REFTRANSNO)
					JOIN CREDITORITEM CI		ON CI.ITEMENTITYNO = PPD2.ITEMENTITYNO
									AND CI.ITEMTRANSNO = PPD2.ITEMTRANSNO
					JOIN EXPENSEJOURNALLINE EJL2 ON EJL2.ENTITYNO = PPD2.ITEMENTITYNO 
									AND EJL2.TRANSNO = PPD2.ITEMTRANSNO
					WHERE PPD2.PLANID = @pnPlanId
					GROUP BY EJL2.TRANSNO, EJL2.ENTITYNO)  TEMP  ON TEMP.ENTITYNO = EJL.ENTITYNO
										AND TEMP.TRANSNO = EJL.TRANSNO
										AND TEMP.SEQNO = EJL.SEQNO
				where CH.REFENTITYNO =  @pnEntityNo
				and CH.REFTRANSNO =  @pnTransNo
				and PPD.PLANID = @pnPlanId
				and ABS(CH.LOCALVALUE) <> 0

				Select @nErrorCode as ERRORCODE
			End
			
		End


		-- SQA21636 only record tax journal line if exist non-zero tax amount.
		-- 18895 Debit Tax Account
		If @nErrorCode = 0 
		Begin
			--Record in the currency of the item.
			Insert into @tbLEDGERJOURNALLINE(ENTITYNO, TRANSNO, PROFITCENTRECODE, 
			ACCOUNTID, LOCALAMOUNT, FOREIGNAMOUNT, CURRENCY, EXCHRATE, ACCTENTITYNO, NOTES)
			
			select @pnEntityNo, @pnTransNo, @sTaxProfitCentre,
			@nTaxLedgerAcct, T.LOCALTAX, case when CH.CURRENCY is null and T.FOREIGNTAX = 0 then null else T.FOREIGNTAX end, 
			CH.CURRENCY, CH.EXCHRATE, @pnEntityNo,
			Case when CI.ITEMREFNO is not null then 'Payment ' + CI.ITEMREFNO
				end + ' ' +
			dbo.fn_FormatNameUsingNameNo(PAY.NAMENO, null) + 
			Case when PAY.NAMECODE is not null then ' {' + PAY.NAMECODE + '}'
				end + 
			Case when CH.DOCUMENTREF is not null then ' Invoice ' + CH.DOCUMENTREF
				end 
			from CREDITORHISTORY CH
			left join @tbTAXES T		ON (T.ITEMENTITYNO = CH.ITEMENTITYNO
							AND T.ITEMTRANSNO = CH.ITEMTRANSNO
							AND T.REFENTITYNO = CH.REFENTITYNO
							AND T.REFTRANSNO = CH.REFTRANSNO)
			LEFT JOIN CASHITEM CI		ON (CI.TRANSENTITYNO = CH.REFENTITYNO
							AND CI.TRANSNO = CH.REFTRANSNO)
			LEFT JOIN NAME PAY		ON (CI.ACCTNAMENO = PAY.NAMENO)
			join PAYMENTPLANDETAIL PPD 	ON (PPD.ITEMENTITYNO = CH.ITEMENTITYNO
							AND PPD.ITEMTRANSNO = CH.ITEMTRANSNO
							AND PPD.REFENTITYNO = CH.REFENTITYNO
							AND PPD.REFTRANSNO = CH.REFTRANSNO)
			where CH.REFENTITYNO = @pnEntityNo
			and CH.REFTRANSNO = @pnTransNo
			and PPD.PLANID = @pnPlanId
			and ABS(CH.LOCALVALUE) <> 0
			and ( T.LOCALTAX <> 0 or T.FOREIGNTAX <> 0 )
	
			Set	@nErrorCode = @@Error
	
			If @pbDebugFlag = 1
			Begin
				Print '*** Add Payable rows - Debit Tax Account ***'
				select @pnEntityNo, @pnTransNo, @sTaxProfitCentre,
				@nTaxLedgerAcct, T.LOCALTAX, case when CH.CURRENCY is null and T.FOREIGNTAX = 0 then null else T.FOREIGNTAX end, 
				CH.CURRENCY, CH.EXCHRATE, @pnEntityNo,
				Case when CI.ITEMREFNO is not null then 'Payment ' + CI.ITEMREFNO
					end + ' ' +
				dbo.fn_FormatNameUsingNameNo(PAY.NAMENO, null) + 
				Case when PAY.NAMECODE is not null then ' {' + PAY.NAMECODE + '}'
					end + 
				Case when CH.DOCUMENTREF is not null then ' Invoice ' + CH.DOCUMENTREF
					end 
				from CREDITORHISTORY CH
				left join @tbTAXES T		ON (T.ITEMENTITYNO = CH.ITEMENTITYNO
								AND T.ITEMTRANSNO = CH.ITEMTRANSNO
								AND T.REFENTITYNO = CH.REFENTITYNO
								AND T.REFTRANSNO = CH.REFTRANSNO)
				LEFT JOIN CASHITEM CI		ON (CI.TRANSENTITYNO = CH.REFENTITYNO
								AND CI.TRANSNO = CH.REFTRANSNO)
				LEFT JOIN NAME PAY		ON (CI.ACCTNAMENO = PAY.NAMENO)
				join PAYMENTPLANDETAIL PPD 	ON (PPD.ITEMENTITYNO = CH.ITEMENTITYNO
								AND PPD.ITEMTRANSNO = CH.ITEMTRANSNO
								AND PPD.REFENTITYNO = CH.REFENTITYNO
								AND PPD.REFTRANSNO = CH.REFTRANSNO)
				where CH.REFENTITYNO = @pnEntityNo
				and CH.REFTRANSNO = @pnTransNo
				and PPD.PLANID = @pnPlanId
				and ABS(CH.LOCALVALUE) <> 0
				and ( T.LOCALTAX <> 0 or T.FOREIGNTAX <> 0 )
				
				Select @nErrorCode as ERRORCODE
			End
		End
	End
End

-- whether this is run for a single payment or a payment plan 
-- there will only be one Bank History row to refer to
-- Add Bank Account row
If @nErrorCode = 0
Begin
	--Record in the currency of the bank account
	Insert into @tbLEDGERJOURNALLINE(ENTITYNO, TRANSNO, PROFITCENTRECODE, 
	ACCOUNTID, LOCALAMOUNT, FOREIGNAMOUNT, CURRENCY, EXCHRATE, ACCTENTITYNO, NOTES)
	select @pnEntityNo, @pnTransNo, @sBankProfitCentre,
	@nBankLedgerAcct, (ABS(BH.LOCALNET)*-1), 
	Case when BA.CURRENCY = SC.COLCHARACTER THEN NULL
	     ELSE (ABS(BH.BANKNET)*-1)
	END,
	Case when BA.CURRENCY = SC.COLCHARACTER THEN NULL
	     ELSE BA.CURRENCY 
	END, 
	Case when BA.CURRENCY = SC.COLCHARACTER THEN NULL
	     ELSE BH.LOCALEXCHANGERATE
	END, 
	@pnEntityNo, 
	Case when BH.REFERENCE is not null then 'Reference ' + BH.REFERENCE
		end + 
	Case when BH.DESCRIPTION is not null then CHAR(13)+CHAR(10)+ BH.DESCRIPTION
		end
	from BANKHISTORY BH
	join BANKACCOUNT BA on (BA.ACCOUNTOWNER = BH.ENTITYNO
				and BA.BANKNAMENO = BH.BANKNAMENO
				and BA.SEQUENCENO = BH.SEQUENCENO)
	join SITECONTROL SC on (SC.CONTROLID = 'CURRENCY')
	where BH.REFENTITYNO = @pnEntityNo
	and BH.REFTRANSNO = @pnTransNo
	and (ABS(BH.LOCALNET)*-1) <> 0

	Set	@nErrorCode = @@Error

	If @pbDebugFlag = 1
	Begin
		Print '*** Add Bank row - Credit Bank ***'
		select @pnEntityNo, @pnTransNo, @sBankProfitCentre,
		@nBankLedgerAcct, (ABS(BH.LOCALNET)*-1), 
		Case when BA.CURRENCY = SC.COLCHARACTER THEN NULL
		     ELSE (ABS(BH.BANKNET)*-1)
		END,
		Case when BA.CURRENCY = SC.COLCHARACTER THEN NULL
		     ELSE BA.CURRENCY 
		END, 
		Case when BA.CURRENCY = SC.COLCHARACTER THEN NULL
		     ELSE BH.LOCALEXCHANGERATE
		END, 
		@pnEntityNo, 
		Case when BH.REFERENCE is not null then 'Reference ' + BH.REFERENCE
			end + 
		Case when BH.DESCRIPTION is not null then CHAR(13)+CHAR(10)+ BH.DESCRIPTION
			end
		from BANKHISTORY BH
		join BANKACCOUNT BA on (BA.ACCOUNTOWNER = BH.ENTITYNO
					and BA.BANKNAMENO = BH.BANKNAMENO
					and BA.SEQUENCENO = BH.SEQUENCENO)
		join SITECONTROL SC on (SC.CONTROLID = 'CURRENCY')
		where BH.REFENTITYNO = @pnEntityNo
		and BH.REFTRANSNO = @pnTransNo
		and (ABS(BH.LOCALNET)*-1) <> 0

		select * from BANKHISTORY
		Where REFENTITYNO = @pnEntityNo
		and REFTRANSNO = @pnTransNo

		Select @nErrorCode as ERRORCODE
	End
End

-- Add Bank Charges row
If @nErrorCode = 0
Begin
	--Record in the currency of the bank account.
	Insert into @tbLEDGERJOURNALLINE(ENTITYNO, TRANSNO, PROFITCENTRECODE, 
	ACCOUNTID, LOCALAMOUNT, FOREIGNAMOUNT, CURRENCY, EXCHRATE, ACCTENTITYNO, NOTES)
	select @pnEntityNo, @pnTransNo, @sBankChargesProfitCentre,
	@nBankChargesLedgerAcct, (ABS(BH.LOCALCHARGES)), 
	Case when BA.CURRENCY = SC.COLCHARACTER THEN NULL
	     ELSE ABS(BH.BANKCHARGES)
	END,
	Case when BA.CURRENCY = SC.COLCHARACTER THEN NULL
	     ELSE BA.CURRENCY 
	END, 
	Case when BA.CURRENCY = SC.COLCHARACTER THEN NULL
	     ELSE BH.LOCALEXCHANGERATE 
	END, 
	@pnEntityNo, 
	Case when BH.REFERENCE is not null then 'Reference ' + BH.REFERENCE
		end + 
	Case when BH.DESCRIPTION is not null then CHAR(13)+CHAR(10)+ BH.DESCRIPTION
		end
	from BANKHISTORY BH
	join BANKACCOUNT BA on (BA.ACCOUNTOWNER = BH.ENTITYNO
				and BA.BANKNAMENO = BH.BANKNAMENO
				and BA.SEQUENCENO = BH.SEQUENCENO)
	join SITECONTROL SC on (SC.CONTROLID = 'CURRENCY')
	where BH.REFENTITYNO = @pnEntityNo
	and BH.REFTRANSNO = @pnTransNo
	and (ABS(BH.LOCALCHARGES)) <> 0
	
	Set	@nErrorCode = @@Error

	If @pbDebugFlag = 1
	Begin
		Print '*** Add Bank Charges row - Debit Bank Charges ***'
		select @pnEntityNo, @pnTransNo, @sBankChargesProfitCentre,
		@nBankChargesLedgerAcct, (ABS(BH.LOCALCHARGES)), 
		Case when BA.CURRENCY = SC.COLCHARACTER THEN NULL
		     ELSE ABS(BH.BANKCHARGES)
		END,
		Case when BA.CURRENCY = SC.COLCHARACTER THEN NULL
		     ELSE BA.CURRENCY 
		END, 
		Case when BA.CURRENCY = SC.COLCHARACTER THEN NULL
		     ELSE BH.LOCALEXCHANGERATE
		END, 
		@pnEntityNo, 
		Case when BH.REFERENCE is not null then 'Reference ' + BH.REFERENCE
			end + 
		Case when BH.DESCRIPTION is not null then CHAR(13)+CHAR(10)+ BH.DESCRIPTION
			end
		from BANKHISTORY BH
		join BANKACCOUNT BA on (BA.ACCOUNTOWNER = BH.ENTITYNO
					and BA.BANKNAMENO = BH.BANKNAMENO
					and BA.SEQUENCENO = BH.SEQUENCENO)
		join SITECONTROL SC on (SC.CONTROLID = 'CURRENCY')
		where BH.REFENTITYNO = @pnEntityNo
		and BH.REFTRANSNO = @pnTransNo
		and (ABS(BH.LOCALCHARGES)) <> 0

		select * from BANKHISTORY
		Where REFENTITYNO = @pnEntityNo
		and REFTRANSNO = @pnTransNo

		Select @nErrorCode as ERRORCODE
	End
End

If @nErrorCode = 0
Begin
	Select @nSumAmount = SUM(LOCALAMOUNT)
	From @tbLEDGERJOURNALLINE
	
	Select	@nErrorCode = @@Error

	If @pbDebugFlag = 1
	Begin
		print '*** Total amount should equal 0 ***'
		Select @nErrorCode AS ERRORCODE, @nSumAmount AS SUMLOCALDEBITSCREDITS
		Select * from @tbLEDGERJOURNALLINE
	End
End

If @nErrorCode = 0
Begin
	If (@nSumAmount = 0)
	Begin
		If @pbDebugFlag = 1
		Begin
			Print '*** Add Ledger Journal ***'
		End

		Insert into LEDGERJOURNAL(ENTITYNO, TRANSNO, USERID, DESCRIPTION, REFERENCE, 
		REFENTITYNO, REFTRANSNO, STATUS, IDENTITYID)
		select @pnEntityNo, @pnTransNo, dbo.fn_GetUser(), PP.PLANNAME, NULL, 
		NULL, NULL, 0, @pnUserIdentityId
		from PAYMENTPLAN PP
		where PP.PLANID = @pnPlanId
		
		Set	@nErrorCode = @@Error
		
		If @nErrorCode = 0
		Begin
			If @pbDebugFlag = 1
			Begin
				Print '*** Add Ledger Lines ***'
			End
	
			Insert into LEDGERJOURNALLINE(ENTITYNO, TRANSNO, SEQNO, PROFITCENTRECODE, 
				ACCOUNTID, LOCALAMOUNT, FOREIGNAMOUNT, CURRENCY, EXCHRATE, NOTES, 
				ACCTENTITYNO)
			select ENTITYNO, TRANSNO, SEQNO, PROFITCENTRECODE, 
				ACCOUNTID, LOCALAMOUNT, FOREIGNAMOUNT, CURRENCY, EXCHRATE, NOTES, 
				ACCTENTITYNO
			from @tbLEDGERJOURNALLINE
		
			Set	@nErrorCode = @@Error
		End
	End
	Else
	Begin
		Set @sMessage = 'The total debit value must match the total credit value for the journal.'
		RAISERROR(@sMessage, 16, 1)
		Set @nErrorCode = @@Error

		If @pbDebugFlag = 1
		Begin
			Print '*** Journal is invalid ***'
			print @nErrorCode
		End
	End
End

If @pbDebugFlag = 1
Begin
	print 'being returned'
	print @nErrorCode
End

Return @nErrorCode
GO

Grant execute on dbo.ap_PlanRecordJournal to public
GO
