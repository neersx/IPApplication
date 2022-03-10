-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ap_PlanRecordWithdrawal
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ap_PlanRecordWithdrawal]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ap_PlanRecordWithdrawal.'
	Drop procedure [dbo].[ap_PlanRecordWithdrawal]
End
Print '**** Creating Stored Procedure dbo.ap_PlanRecordWithdrawal...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ap_PlanRecordWithdrawal
(
	@pnTransNo		int		= null output,
	@pnUserIdentityId	int		= null,
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura 	tinyint 	= 0,
	@pbDebugFlag		tinyint		= 0,
	@pnEntityNo		int		= null,
	@psReference		nvarchar(30)	= null,
	@pnBankCharges		decimal(9,2)	= null,
	@psDescription		nvarchar(254)	= null,
	@pnPlanId		int,		-- Mandatory
	@pnEmployeeNo		int,		-- Mandatory
	@psUserId		nvarchar(30),	-- Mandatory
	@pdtPaymentDate			datetime	= null
)
as
-- PROCEDURE:	ap_PlanRecordWithdrawal
-- VERSION:	12
-- SCOPE:	InPro
-- DESCRIPTION:	Used to record the Bank History for a withdrawal (payment)
--		NOTE: Must only be called after the associated Cash Item/s has been recorded.
-- COPYRIGHT:	Copyright 1993 - 2009 CPA Software Solutions Australia Pty Ltd
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 21 NOV 2003	CR	8816	1.00	Procedure created
-- 09-Dec-2003	CR	8817	1.01	Fixed Single Withdrawal for Bank Drafts
-- 12-Dec-2003	CR	8817	1.02	Instead of retrieving EmployeeNo here this and the 
--					User Id are now passed in.
-- 15-Dec-2003	CR	8816	1.03	Changed where fnConvertCurrency is called - if being 
--					used in another equation don't convert until the end result 
--					has been derived.
-- 17-Dec-2003	CR	8817	1.04	Fixed updating of Local Charges and Net
-- 29-Jan-2004	CR	9558	1.05	Removed CI.REFERENCE from the group by clause.
-- 04-Feb-2004	CR	9558	1.06	Changed setting of LOCALEXCHANGERATE to be NULL for Bank Drafts 
--					where the bank currency is the same as the local currency
-- 18-Feb-2004	SS	9297	1.07	Incorporated Bank Rate.
-- 02-Jul-2004	CR	10082	8	Changed the MovementClass and Commandid used to 2 AS MOVEMENTCLASS, 3 AS COMMANDID
-- 02-June-2005	CR	10146	9	Changed the logic for when the payment method is NOT Bank Draft
--					to set REFERENCE to the corresponding CASHITEM.ITEMREFNO
-- 17-Nov-2005	vql	9704	10	When updating TRANSACTIONHEADER table insert @pnUserIdentityId.
-- 28-Dec-2009	CR	18320	11	Extended to include PaymentDate as a parameter
-- 20 Oct 2015  MS      R53933  12      Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE col

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int,
	@nBankDraft		decimal(1,0),
	@sBankCurrency		nvarchar(3),
	@sLocalCurrency		nvarchar(3),
	@sSQLString		nvarchar(400),
	@nExchRateType		tinyint

-- Initialise variables
Set @nErrorCode = 0

If @pdtPaymentDate is NULL
	Set @pdtPaymentDate = GETDATE()

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select @sBankCurrency = BA.CURRENCY
	From BANKACCOUNT BA
	Join PAYMENTPLAN PP 	on (BA.ACCOUNTOWNER = PP.ENTITYNO
				and	BA.BANKNAMENO = PP.BANKNAMENO
				and	BA.SEQUENCENO = PP.BANKSEQUENCENO)
	Where PP.PLANID = @pnPlanId"

	exec @nErrorCode = sp_executesql @sSQLString,	N'@sBankCurrency	nvarchar(3) OUTPUT,
							@pnPlanId		int',
							@sBankCurrency		OUTPUT,
							@pnPlanId

	If @pbDebugFlag = 1
	Begin
		print '*** Retrieve the Currency of the Bank ***'
		print @sSQLString
		Select @sBankCurrency as BANKCURRENCY, @nErrorCode as ERRORCODE
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

	-- For Debugging
	If @pbDebugFlag = 1
	Begin
		PRINT '*** Retrieve the Local Currency ***'
		Select @sLocalCurrency
	End
End

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
	If @pnTransNo is NULL
	Begin
		If @pbDebugFlag = 1
		Begin
			print '*** Single withdrawal required ***'
		End

		If @nErrorCode = 0
		Begin
			Set @sSQLString="Update  LASTINTERNALCODE 
			set INTERNALSEQUENCE = INTERNALSEQUENCE + 1 
			where TABLENAME = N'TRANSACTIONHEADER'"
		
			exec @nErrorCode=sp_executesql @sSQLString
	
			If @pbDebugFlag = 1
			Begin
				print '*** LASTINTERNALCODE UPDATED ***'
				print @sSQLString
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
				Print '*** Get the TransNo from LASTINTERNALCODE to be used on the TRANSACTIONHEADER added ***'
				Print @sSQLString
				Select @pnTransNo AS TRANSNO, @nErrorCode as ERRORCODE
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
			values (@pnTransNo, @pnEntityNo, 999,
			@pnEmployeeNo, CURRENT_TIMESTAMP, NULL,
			NULL, NULL, 8, 
			0, dbo.fn_DateOnly(@pdtPaymentDate), 704, @psUserId, @pnUserIdentityId)"

			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnTransNo 	int,
							@pnEntityNo 	int,
							@pnEmployeeNo	int,
							@pdtPaymentDate datetime,
							@psUserId	nvarchar(30),
							@pnUserIdentityId int',
							@pnTransNo,
							@pnEntityNo,
							@pnEmployeeNo,
							@pdtPaymentDate, 
							@psUserId,
							@pnUserIdentityId = @pnUserIdentityId	

			If @pbDebugFlag = 1
			Begin
				Print '*** TRANSACTIONHEADER added for the withdrawal ***'
				Print @sSQLString
				Select @nErrorCode as ERRORCODE, @pnEntityNo as ENTITYNO, @pnTransNo as TRANSNO
			End
		End		
		Set @nBankDraft = 1
	End
	Else
	Begin
		Set @nBankDraft = 0
	End
End

If @nErrorCode = 0
Begin
	If @nBankDraft = 1
	Begin
		Insert into BANKHISTORY(ENTITYNO, BANKNAMENO, SEQUENCENO, HISTORYLINENO, TRANSDATE, 
		POSTDATE, POSTPERIOD, PAYMENTMETHOD, WITHDRAWALCHEQUENO, TRANSTYPE, 
		MOVEMENTCLASS, COMMANDID, REFENTITYNO, REFTRANSNO, STATUS, DESCRIPTION, ASSOCLINENO, 
		PAYMENTCURRENCY, PAYMENTAMOUNT, 
		BANKEXCHANGERATE, BANKAMOUNT, BANKCHARGES, BANKNET, 
		LOCALAMOUNT, LOCALCHARGES, LOCALEXCHANGERATE, LOCALNET, 
		BANKCATEGORY, REFERENCE, ISRECONCILED, GLMOVEMENTNO)

		Select  CI.ENTITYNO, CI.BANKNAMENO, CI.SEQUENCENO, ISNULL((MAX(BH.HISTORYLINENO) + 1),1) AS HISTORYLINENO, CI.ITEMDATE, 
		CI.POSTDATE, CI.POSTPERIOD, CI.ITEMTYPE, NULL AS WITHDRAWALCHEQUENO, 704, 
		2 AS MOVEMENTCLASS, 3 AS COMMANDID, @pnEntityNo, @pnTransNo, CI.STATUS, @psDescription, 
		NULL AS ASSOCIATEDLINENO, NULL AS PAYMENTCURRENCY, NULL AS PAYMENTAMOUNT, 
		NULL AS BANKEXCHANGERATE, SUM(CI.BANKAMOUNT), ISNULL(@pnBankCharges, 0), (SUM(CI.BANKAMOUNT)-ISNULL(@pnBankCharges, 0)) AS BANKNET, 
		SUM(CI.LOCALAMOUNT) AS LOCALAMOUNT, 
		convert( decimal(11,2), dbo.fn_ConvertCurrency(@sBankCurrency, NULL, ISNULL(@pnBankCharges, 0), @nExchRateType)) AS LOCALCHARGES,
		CASE WHEN (@sBankCurrency = @sLocalCurrency) THEN NULL ELSE
			convert( decimal(11,4), (SUM(CI.BANKAMOUNT) / SUM(CI.LOCALAMOUNT)), 0)
		End AS LOCALEXCHANGERATE, 
		convert( decimal(11,2), (SUM(CI.LOCALAMOUNT) - ISNULL(dbo.fn_ConvertCurrency(@sBankCurrency, NULL, @pnBankCharges, @nExchRateType), 0)) ) AS LOCALNET,
		NULL AS BANKCATEGORY, @psReference AS REFERENCE, 0 AS ISRECONCILED, NULL AS GLMOVEMENTNO
		
		from CASHITEM CI
/*
		left join PAYMENTPLANDETAIL PPD	on (PPD.REFENTITYNO = CI.TRANSENTITYNO
						and PPD.REFTRANSNO = CI.TRANSNO)
*/
		-- do this because there may not already be a bank history row added for the current bank account
		left join BANKHISTORY BH	on (CI.ENTITYNO = BH.ENTITYNO 
						and CI.BANKNAMENO = BH.BANKNAMENO 
						and CI.SEQUENCENO = BH.SEQUENCENO
						and BH.HISTORYLINENO = (Select MAX(BH2.HISTORYLINENO)
									from BANKHISTORY BH2
									where CI.ENTITYNO = BH2.ENTITYNO 
									and CI.BANKNAMENO = BH2.BANKNAMENO 
									and CI.SEQUENCENO = BH2.SEQUENCENO))

		where CI.TRANSNO IN (SELECT DISTINCT(PPD.REFTRANSNO)
				FROM PAYMENTPLANDETAIL PPD
				WHERE PPD.PLANID = @pnPlanId)

		group by CI.ENTITYNO, CI.BANKNAMENO, CI.SEQUENCENO, CI.ITEMTYPE, CI.STATUS, 
		CI.ITEMDATE, CI.POSTDATE, CI.POSTPERIOD

		Set @nErrorCode = @@Error

		If @pbDebugFlag = 1
		Begin
			Print '*** Insert Bank History row for the single withdrawal ***'
			Select @nErrorCode as ERRORCODE, 
			BH.ENTITYNO, BH.BANKNAMENO, BH.SEQUENCENO, BH.HISTORYLINENO, REFTRANSNO, REFENTITYNO 
			from BANKHISTORY BH	
			where BH.REFENTITYNO = @pnEntityNo
			and BH.REFTRANSNO = @pnTransNo
		End

		If @nErrorCode = 0
		Begin
			Set @sSQLString = "Update CASHITEM
					Set BANKEDBYENTITYNO = @pnEntityNo,
					BANKEDBYTRANSNO = @pnTransNo
					from CASHITEM CI	
					join PAYMENTPLANDETAIL PPD	on (PPD.REFENTITYNO = CI.TRANSENTITYNO
									and PPD.REFTRANSNO = CI.TRANSNO)

					where PPD.PLANID = @pnPlanId"

			exec @nErrorCode = sp_executesql @sSQLString,	N'@pnEntityNo	int,
								@pnTransNo		int,
								@pnPlanId		int',
								@pnEntityNo,
								@pnTransNo,
								@pnPlanId

			If @pbDebugFlag = 1
			Begin
				print '*** Update Cash Item Rows for the Bank Draft ***'
				print @sSQLString
				Select @pnTransNo AS TRANSNO, @pnEntityNo AS ENTITYNO, @nErrorCode as ERRORCODE
			End
					
		End
	End
	Else 
	Begin	
		Insert into BANKHISTORY(ENTITYNO, BANKNAMENO, SEQUENCENO, HISTORYLINENO, TRANSDATE, 
		POSTDATE, POSTPERIOD, PAYMENTMETHOD, WITHDRAWALCHEQUENO, TRANSTYPE, 
		MOVEMENTCLASS, COMMANDID, REFENTITYNO, REFTRANSNO, STATUS, DESCRIPTION, ASSOCLINENO, 
		PAYMENTCURRENCY, PAYMENTAMOUNT, 
		BANKEXCHANGERATE, BANKAMOUNT, BANKCHARGES, BANKNET, 
		LOCALAMOUNT, LOCALCHARGES, LOCALEXCHANGERATE, LOCALNET, 
		BANKCATEGORY, REFERENCE, ISRECONCILED, GLMOVEMENTNO)
		
		Select  CI.ENTITYNO, CI.BANKNAMENO, CI.SEQUENCENO, ISNULL((MAX(BH.HISTORYLINENO) + 1),1) AS HISTORYLINENO, CI.ITEMDATE, 
		CI.POSTDATE, CI.POSTPERIOD, CI.ITEMTYPE, CI.ITEMREFNO AS WITHDRAWALCHEQUENO, 704, 
		2 AS MOVEMENTCLASS, 3 AS COMMANDID, @pnEntityNo, @pnTransNo, CI.STATUS, 
		CI.DESCRIPTION, 
		NULL AS ASSOCIATEDLINENO, CI.PAYMENTCURRENCY, CI.PAYMENTAMOUNT, 
		CI.BANKEXCHANGERATE, CI.BANKAMOUNT, CI.BANKCHARGES, CI.BANKNET, 
		CI.LOCALAMOUNT, CI.LOCALCHARGES, CI.LOCALEXCHANGERATE, CI.LOCALNET, 
		NULL AS BANKCATEGORY, ISNULL(@psReference, CI.ITEMREFNO) AS REFERENCE, 0 AS ISRECONCILED, NULL AS GLMOVEMENTNO
		from CASHITEM CI
		-- do this because there may not already be a bank history row added for the current bank account
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
		CI.LOCALEXCHANGERATE, CI.LOCALNET, CI.ITEMREFNO

		Set @nErrorCode = @@Error

		If @pbDebugFlag = 1
		Begin
			Print '*** Insert Bank History row for the current payment ***'
			Select @nErrorCode as ERRORCODE, 
			BH.ENTITYNO, BH.BANKNAMENO, BH.SEQUENCENO, BH.HISTORYLINENO, REFTRANSNO, REFENTITYNO 
			from BANKHISTORY BH	
			where BH.REFENTITYNO = @pnEntityNo
			and BH.REFTRANSNO = @pnTransNo
		End
			

		If @nErrorCode = 0
		Begin
			Set @sSQLString = "Update CASHITEM
					Set BANKEDBYENTITYNO = @pnEntityNo,
					BANKEDBYTRANSNO = @pnTransNo
					where TRANSENTITYNO = @pnEntityNo
					and TRANSNO = @pnTransNo"

			exec @nErrorCode = sp_executesql @sSQLString,	N'@pnEntityNo	int,
								@pnTransNo		int,
								@pnPlanId		int',
								@pnEntityNo,
								@pnTransNo,
								@pnPlanId

			If @pbDebugFlag = 1
			Begin
				print '*** Update Cash Item Rows for the current payment ***'
				print @sSQLString
				Select @pnTransNo AS TRANSNO, @pnEntityNo AS ENTITYNO, @nErrorCode as ERRORCODE
			End
					
		End
		
	End
	
End

If @pbDebugFlag = 1
Begin
	print '*** Cash Item Rows Banked ***'
	SELECT * 
	FROM CASHITEM
	WHERE BANKEDBYENTITYNO = @pnEntityNo
	and BANKEDBYTRANSNO = @pnTransNo
End

Return @nErrorCode
GO

Grant execute on dbo.ap_PlanRecordWithdrawal to public
GO
