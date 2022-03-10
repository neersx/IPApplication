-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wpw_AdjustWIP
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[wpw_AdjustWIP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop Stored Procedure  dbo.wpw_AdjustWIP.'
	drop procedure dbo.wpw_AdjustWIP
End
print '**** Creating Stored Procedure dbo.wpw_AdjustWIP...'
print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.wpw_AdjustWIP
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbCalledFromCentura		bit		= 0,
	
	-- Old WIP Details
	@pnEntityKey			int,
	@pnTransKey			int,
	@pnWIPSeqKey			int,
	@pdtLogDateTimeStamp		datetime	= null,	-- this should be passed in for concurrency, but old WIP may not have it.
	
	-- Adjustments
	@pnRequestedByStaffKey	int,
	@pdtAdjustmentDate	datetime,
	@pnAdjustmentType	int = null,		-- Pass null if narrative adjustment only.
	@psReasonCode		nvarchar(2) = null,	-- reason is not required for narrative change.
	@pnNewLocalValue	decimal(12,2) = null,
	@pnNewForeignValue	decimal(12,2) = null,
	@pnNewCaseKey		int = null,
	@pnNewDebtorKey		int = null,
	@pnNewStaffKey		int = null,
	@pnNewQuotationKey	int = null,
	@pnNewProductKey	int = null,
	@pnNewNarrativeKey	int = null,
	@psNewDebitNoteText	nvarchar(max) = null,
	@psNewActivityKey	nvarchar(6) = null,	-- New WIP Code.
	@pdtNewTotalTime	datetime = null,	-- Time used in calculation of WIP
	@pnNewTotalUnits	int	 = null,
	@pnNewChargeOutRate	decimal(11,2)= null,	-- Charge out rate used in calculation of WIP
	@pbIsAdjustWipToZero	bit	= 0,		-- used for when deleting diary and adjusting wip to zero
	@pbCalledFromTimeSheet	bit	= 0,
        @pnNewEntityKey         int     = null,
	@pnNewTransKey		int	= null output	-- used for activity and case transfer in timesheet
)		
-- PROCEDURE :	wpw_AdjustWIP
-- VERSION :	22
-- DESCRIPTION:	Make adjustment(s) to a WIP Item.
-- CALLED BY :	Inprotech Web

-- MODIFICTIONS :
-- Date		Who	Number		Version	Change
-- ------------	-------	------		-------	----------------------------------------------- 
-- 29 Sep 2011	AT	RFC9012		1	Procedure created.
-- 30 Oct 2012	LP	RFC12876	2	Always set WorkInProgress totals regardless of Adjustment type.
-- 29 Nov 2012	vql	RFC12805	3	Incorrect transaction date on WIP adjustment (redo - merge issue).
-- 29 Nov 2012	vql	RFC12814	4	Incorrect Case Profit Centre on WIP Adjustment (redo - merge issue).
-- 08 Jan 2013	vql	RFC12924	5	GL Journal not being created (WorkHist not set correctly).
-- 22 Jan 2013	vql	RFC13108	6	Details missing on WIP Adjustments records.
-- 24 Jan 2013	AT	RFC13108	7	Only full transfer should copy time and qty columns. All transfers should copy cost calcuations.
-- 12 Mar 2013	KR	RFC12878	8	Fixed where the verification no is not copied to work history.
-- 17 Jul 2013	vql	DR-136		9	Allow transfer of case wips.
-- 01 Oct 2013  MS      DR-144          10      Handled debtor transfer wip for split wip multi debtor
-- 02 Sep 2015	DL	R50927		11	Case WIP Transfer incorrectly updating Control Totals hence causing Rollover errors
-- 01 Apr 2016	MF	R59860		12	Failing when narrative is being changed and there is no narrative on the WIP row to start with.
-- 19 May 2016	LP	R48511		13	Allow Time and Units to be updated, e.g. when posted time is adjusted.
-- 17 Oct 2016	vql	R63850		14	Allow Activity to be adjusted.
-- 21 Sep 2017  MS      R70640		15      Use @pnNewTransKey for associated disocunt items transfer
-- 14 Feb 2018  MS      R73247		16      Remove BillingDiscountFlag setting in wp_PostWip call
-- 06 Mar 2018  AK      R73620		17      Passed @pdtAdjustmentDate to calculate POSTPERIOD
-- 17 Mar 2018  AK      R73620		18      used @nWipPostPeriod to get original POSTPERIOD of a wip
-- 23 Jul 2018  MS      R74466      19      Set DiscountFlag and Profit Centre for wip items
-- 18 Sep 2018  MS      DR43059     20      Implemented Entity Transfer logic
-- 06 Sep 2019  AK      DR44770     21      logig updated to keep original transactiondate
-- 20 Sep 2019  KT      DR46178     22      Checked Site control value before creating GL Journal

as

SET CONCAT_NULL_YIELDS_NULL OFF

-- This must be off if the procedure does multiple inserts/updates/deletes (For concurrency checking).
SET NOCOUNT OFF

Declare @sSQLString		nvarchar(max)
Declare @nErrorCode		int
Declare @sLookupCulture	nvarchar(10)
Declare @sAlertXML		nvarchar(1000)
Declare @nRowCount		int
Declare @bDebug			bit
Declare @nGLJournalCreation	int
Declare @nPostPeriod		int
Declare @nWipPostPeriod		int
Declare @nOldDebtorKey		int
Declare @nLocalAdjustment	decimal(12,2)
Declare @nForeignAdjustment	decimal(12,2)
Declare @nMovementClass		int
Declare @nTotalLocal		decimal(12,2)
Declare @nTotalForeign		decimal(12,2)
Declare @nTotalLocalCost	decimal(12,2)
Declare @nTotalForeignCost	decimal(12,2)
Declare @nTotalCostCalculation1	decimal(12,2)
Declare @nTotalCostCalculation2	decimal(12,2)
Declare @dtTotalTimeAdjustment	datetime
Declare @nTotalUnitsAdjustment	int
Declare @nNewChargeOutRate	decimal(11,2)
Declare @nHistoryLineNo		int
Declare @nResult		int
Declare @nEntityKey             int

Set @bDebug = 0
Set @nRowCount = 0
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
-- Insert new Transaction Header
-- Insert into TRANSADJUSTMENT
-- FCDBAdjustmentTransaction.cfDBPost()
-- Insert new WORKINPROGRESS
-- Insert new WORKHISTORY
-- Adjust down WORKHISTORY
-- Remove old WORKHISTORY
-- Adjust Control Total

Declare @nNewTransKey int
Declare @dtTransDate datetime
Declare @bIsSplitMultiDebtor bit
Declare @bIsSplitWip	bit
Declare @bIsDiscount	bit

Set @dtTransDate = getdate() 

If @nErrorCode=0
Begin		
	Set @sSQLString=
	"Select @bIsSplitMultiDebtor = COLBOOLEAN
	from SITECONTROL 	
	where CONTROLID = 'WIP Split Multi Debtor'"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bIsSplitMultiDebtor	bit	OUTPUT',
				  @bIsSplitMultiDebtor	= @bIsSplitMultiDebtor	OUTPUT
End

-- Perform concurrency check
If @nErrorCode = 0 and not exists (select * from WORKINPROGRESS
				WHERE ENTITYNO = @pnEntityKey
				and	TRANSNO = @pnTransKey
				and	WIPSEQNO = @pnWIPSeqKey
				and	(LOGDATETIMESTAMP = @pdtLogDateTimeStamp or (LOGDATETIMESTAMP IS NULL AND @pdtLogDateTimeStamp IS NULL)))
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('AC29', 'WIP Item has been changed or removed. Please reload the WIP item and try again.',
    							null, null, null, null, null)
  			RAISERROR(@sAlertXML, 14, 1)
  			Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0 and
	exists (select * from WORKINPROGRESS
		WHERE ENTITYNO = @pnEntityKey
		and	TRANSNO = @pnTransKey
		and	WIPSEQNO = @pnWIPSeqKey
		and (NARRATIVENO != @pnNewNarrativeKey
			OR(NARRATIVENO is null and @pnNewNarrativeKey is not null)
			OR coalesce(SHORTNARRATIVE,LONGNARRATIVE,'') not like coalesce(@psNewDebitNoteText,'')))
Begin
	If @bDebug = 1
	Begin
		print 'Updating Debit Note Text'
		print 'Culture is ' + @sLookupCulture
	End

	Declare @nTID int
	-- Just update the debit note text and narrative. No transaction required.
	if @nErrorCode = 0 
		and @sLookupCulture is not null and @psNewDebitNoteText is not null
	Begin
		
		If @bDebug = 1
		Begin
			print 'Updating DebitNoteText with translation'
			print 'Culture is ' + @sLookupCulture
		End 
		
		Set @sSQLString = "
			Select @nTID = NARRATIVE_TID
			FROM WORKINPROGRESS
			WHERE ENTITYNO = @pnEntityKey
			and	TRANSNO = @pnTransKey
			and	WIPSEQNO = @pnWIPSeqKey"
		
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@nTID		int output,
				@pnEntityKey	int,
				@pnTransKey	int,
				@pnWIPSeqKey	int',
				@nTID = @nTID output,
				@pnEntityKey = @pnEntityKey,
				@pnTransKey = @pnTransKey,
				@pnWIPSeqKey = @pnWIPSeqKey
		
		exec @nErrorCode = dbo.ipn_UpdateTranslatedText
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @sLookupCulture,
			@psTableName		= "WORKINPROGRESS",	-- Mandatory
			@psTIDColumnName	= "NARRATIVE_TID",	-- Mandatory
			@psText			= @psNewDebitNoteText,
			@pnTID			= @nTID
	End
	Else if @nErrorCode = 0
	Begin
		If @bDebug = 1
		Begin
			print 'Updating DebitNoteText without translation'
		End 
		
		Set @sSQLString = "
			update WORKINPROGRESS SET NARRATIVENO = @pnNewNarrativeKey,
			SHORTNARRATIVE = CASE WHEN LEN(@psNewDebitNoteText) > 254 THEN NULL ELSE @psNewDebitNoteText END,
			LONGNARRATIVE = CASE WHEN LEN(@psNewDebitNoteText) > 254 THEN @psNewDebitNoteText ELSE NULL END
			WHERE ENTITYNO = @pnEntityKey
			and	TRANSNO = @pnTransKey
			and	WIPSEQNO = @pnWIPSeqKey"
		
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnNewNarrativeKey	int,
				@psNewDebitNoteText	nvarchar(max),
				@pnEntityKey		int,
				@pnTransKey		int,
				@pnWIPSeqKey		int',
				@pnNewNarrativeKey = @pnNewNarrativeKey,
				@psNewDebitNoteText = @psNewDebitNoteText,
				@pnEntityKey = @pnEntityKey,
				@pnTransKey = @pnTransKey,
				@pnWIPSeqKey = @pnWIPSeqKey
	End
	
	if @nErrorCode = 0 and 
		@sLookupCulture is not null and @psNewDebitNoteText is not null
	Begin

		Set @sSQLString = "
			Select @nTID = NARRATIVE_TID
			FROM WORKHISTORY
			WHERE ENTITYNO = @pnEntityKey
			and	TRANSNO = @pnTransKey
			and	WIPSEQNO = @pnWIPSeqKey"
		
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@nTID		int output,
				@pnEntityKey	int,
				@pnTransKey	int,
				@pnWIPSeqKey	int',
				@nTID = @nTID output,
				@pnEntityKey = @pnEntityKey,
				@pnTransKey = @pnTransKey,
				@pnWIPSeqKey = @pnWIPSeqKey
		
		exec @nErrorCode = dbo.ipn_UpdateTranslatedText
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @sLookupCulture,
			@psTableName		= "WORKHISTORY",	-- Mandatory
			@psTIDColumnName	= "NARRATIVE_TID",	-- Mandatory
			@psText			= @psNewDebitNoteText,
			@pnTID			= @nTID
	End
	Else if @nErrorCode = 0
	Begin
		update WORKHISTORY SET NARRATIVENO = @pnNewNarrativeKey,
		SHORTNARRATIVE = CASE WHEN LEN(@psNewDebitNoteText) > 254 THEN NULL ELSE @psNewDebitNoteText END,
		LONGNARRATIVE = CASE WHEN LEN(@psNewDebitNoteText) > 254 THEN @psNewDebitNoteText ELSE NULL END
		WHERE ENTITYNO = @pnEntityKey
		and	TRANSNO = @pnTransKey
		and	WIPSEQNO = @pnWIPSeqKey
	End
	
	If @pnAdjustmentType is null
	Begin
		-- Quit from the proc.
		Return @nErrorCode
	End
End

If (@pnAdjustmentType not in (1000,1001,1008))
Begin
	-- The amounts are not relevant here so clear them.
	Set @pnNewLocalValue = null
	Set @pnNewForeignValue = null
End

Set @nEntityKey = CASE WHEN @pnAdjustmentType = 600 THEN @pnNewEntityKey ELSE @pnEntityKey END

-- Get a new Transaction Key
If @nErrorCode = 0
Begin
	Exec @nErrorCode = dbo.ip_GetLastInternalCode
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@psTable		= N'TRANSACTIONHEADER',
			@pnLastInternalCode	= @nNewTransKey OUTPUT
	
	if (@bDebug = 1)
	Begin
		print 'New Trans Key is: ' + cast(@nNewTransKey as nvarchar(13))
	End
End

If (@nErrorCode = 0)
Begin
	Set @sSQLString = "
		Select @nGLJournalCreation = COLINTEGER
		From SITECONTROL
		Where CONTROLID = 'GL Journal Creation'"

	exec	@nErrorCode = sp_executesql @sSQLString,
					N'@nGLJournalCreation	int 			OUTPUT',
					@nGLJournalCreation = @nGLJournalCreation	OUTPUT
					
	if (@bDebug = 1)
	Begin
		print 'GL Journal Creation is: ' + cast(@nGLJournalCreation as nvarchar(13))
	End
End

If @nErrorCode = 0
Begin
	-- validate the transaction date and get the post period.
	exec @nErrorCode = dbo.acw_ValidateTransactionDate
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,
				@pbCalledFromCentura	= @pbCalledFromCentura,
				@pdtItemDate		= @pdtAdjustmentDate,
				@pnModule		= 1,
				@pbIgnoreWarnings	= 1,
				@pnPeriodId		= @nPostPeriod output
	if (@bDebug = 1)
	Begin
		print 'Validated Trans Date'
	End
End

-- Get wip details
If @nErrorCode = 0
Begin

	Set @sSQLString = 'SELECT @nOldDebtorKey = ACCTCLIENTNO,
		@nLocalAdjustment = isnull(@pnNewLocalValue,0) - BALANCE,
		@nForeignAdjustment = isnull(@pnNewForeignValue,0) - FOREIGNBALANCE,
		@nTotalLocal = BALANCE,
		@nTotalForeign = FOREIGNBALANCE,
		@nTotalLocalCost = LOCALCOST,
		@nTotalForeignCost = FOREIGNCOST,
		@nTotalCostCalculation1 = COSTCALCULATION1,
		@nTotalCostCalculation2 = COSTCALCULATION2,
		@dtTotalTimeAdjustment = case when (@pbIsAdjustWipToZero = 1) then TOTALTIME
					 else convert(datetime, substring(dbo.fn_DateDiff(TOTALTIME, isnull(@pdtNewTotalTime,TOTALTIME)), 12, 9)) end,
		@nTotalUnitsAdjustment = isnull(@pnNewTotalUnits,0) - TOTALUNITS,
		@nNewChargeOutRate = isnull(@pnNewChargeOutRate,CHARGEOUTRATE),
		@bIsDiscount = case when DISCOUNTFLAG = 1 then 1 else 0 end
		FROM WORKINPROGRESS
		WHERE ENTITYNO = @pnEntityKey
		AND TRANSNO = @pnTransKey
		AND WIPSEQNO = @pnWIPSeqKey'
			
	exec @nErrorCode = sp_executesql @sSQLString,
				N'@nOldDebtorKey	int output,
				@nLocalAdjustment	decimal(12,2) output,
				@nForeignAdjustment	decimal(12,2) output,				
				@nTotalLocal		decimal(12,2) output,
				@nTotalForeign		decimal(12,2) output,
				@nTotalLocalCost	decimal(12,2) output,
				@nTotalForeignCost	decimal(12,2) output,
				@nTotalCostCalculation1	decimal(12,2) output,
				@nTotalCostCalculation2	decimal(12,2) output,
				@nTotalUnitsAdjustment  int output,
				@dtTotalTimeAdjustment	datetime output,
				@nNewChargeOutRate	decimal(11,2) output,
				@bIsDiscount		bit output,
				@pnNewLocalValue	decimal(12,2),
				@pnNewForeignValue	decimal(12,2),
				@pnNewChargeOutRate	decimal(11,2),
				@pnEntityKey		int,
				@pnTransKey		int,
				@pnWIPSeqKey		int,
				@pdtNewTotalTime	datetime,
				@pnNewTotalUnits	int,
				@pbIsAdjustWipToZero	bit',				
				@nOldDebtorKey = @nOldDebtorKey output,
				@nLocalAdjustment = @nLocalAdjustment output,
				@nForeignAdjustment = @nForeignAdjustment output,
				@nTotalLocal		=  @nTotalLocal output,
				@nTotalForeign		=  @nTotalForeign output,
				@nTotalLocalCost	=  @nTotalLocalCost output,
				@nTotalForeignCost	=  @nTotalForeignCost output,
				@nTotalCostCalculation1	=  @nTotalCostCalculation1 output,
				@nTotalCostCalculation2	=  @nTotalCostCalculation2 output,
				@dtTotalTimeAdjustment	= @dtTotalTimeAdjustment output,
				@nTotalUnitsAdjustment	= @nTotalUnitsAdjustment output,
				@nNewChargeOutRate	= @nNewChargeOutRate output,
				@bIsDiscount		= @bIsDiscount output,
				@pnNewLocalValue	= @pnNewLocalValue,
				@pnNewForeignValue	= @pnNewForeignValue,
				@pnNewChargeOutRate	= @pnNewChargeOutRate,
				@pnEntityKey		=  @pnEntityKey,
				@pnTransKey		=  @pnTransKey,
				@pnWIPSeqKey		=  @pnWIPSeqKey,
				@pdtNewTotalTime	= @pdtNewTotalTime,
				@pnNewTotalUnits	= @pnNewTotalUnits,
				@pbIsAdjustWipToZero	= @pbIsAdjustWipToZero
				
	if @nLocalAdjustment <= 0
	Begin
		Set @nMovementClass = 5
	End
	Else
	Begin
		Set @nMovementClass = 4
	End

	if CAST(@dtTotalTimeAdjustment AS time) = '00:00:00'
	Begin
		Set @dtTotalTimeAdjustment = NULL
	End	
	
	if (@bDebug = 1)
	Begin
		print 'Calculated Local Adjustment: ' + cast(@nLocalAdjustment as nvarchar(15))
		print 'Calculated Foreign Adjustment: ' + cast(@nForeignAdjustment as nvarchar(15))
		print 'Movement Class: ' + cast(@nMovementClass as nvarchar(13))
	End
End

If @nErrorCode = 0
Begin
	if (@bDebug = 1)
	Begin
		print 'Inserting Transaction Header'
	End
	-- Source = 2 (Time and Billing)
	-- TransStatus = 1 (active)

	Set @sSQLString = "
	INSERT INTO TRANSACTIONHEADER (ENTITYNO, TRANSNO, TRANSDATE, TRANSTYPE,
	BATCHNO, EMPLOYEENO, USERID, ENTRYDATE, 
	SOURCE, TRANSTATUS, GLSTATUS, TRANPOSTPERIOD, TRANPOSTDATE, IDENTITYID)

	SELECT @nEntityKey, @nNewTransKey, @pdtAdjustmentDate, @pnAdjustmentType,
	null, @pnRequestedByStaffKey, system_user, @dtTransDate,
	2, 1, case when @nGLJournalCreation is not null then 0 end, @nPostPeriod, @dtTransDate, @pnUserIdentityId"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@nEntityKey		int,
				@nNewTransKey		int,
				@pdtAdjustmentDate	datetime,
				@pnAdjustmentType	int,
				@pnRequestedByStaffKey	int,
				@nGLJournalCreation	int,
				@nPostPeriod		int,
				@dtTransDate		datetime,
				@pnUserIdentityId	int',
				@nEntityKey = @nEntityKey,
				@nNewTransKey = @nNewTransKey,
				@pdtAdjustmentDate = @pdtAdjustmentDate,
				@pnAdjustmentType = @pnAdjustmentType,
				@pnRequestedByStaffKey = @pnRequestedByStaffKey,
				@nGLJournalCreation = @nGLJournalCreation,
				@nPostPeriod = @nPostPeriod,
				@dtTransDate = @dtTransDate,
				@pnUserIdentityId = @pnUserIdentityId

End

-- Insert TRANSADJUSTMENT
If @nErrorCode = 0
Begin
	if (@bDebug = 1)
	Begin
		print 'Inserting Transaction Adjustment'
	End
	
	Set @sSQLString = "
		insert into TRANSADJUSTMENT
		(ENTITYNO, TRANSNO, POSTDATE, TRANSVALUE, 
		TOWIPCODE, TOCASEID, TOFAMILY, TOEMPLOYEENO, TOACCTENTITYNO, TOACCTNAMENO, TOPRODUCTCODE,
		REASONCODE, 
		ADJENTITYNO, ADJTRANSNO, ADJSEQNO, ADJACCTENTITYNO, ADJACCTDEBTORNO, STATUS,
		APPLYTOENTITYNO, APPLYTOTRANSNO, APPLYTOSEQNO,
		FOREIGNCURRENCY, FOREIGNTRANSVALUE)

		select @nEntityKey, @nNewTransKey, @dtTransDate, @pnNewLocalValue,
		@psNewActivityKey, @pnNewCaseKey, null, @pnNewStaffKey, @pnNewEntityKey, @pnNewDebtorKey, @pnNewProductKey,
		@psReasonCode,
		W.ENTITYNO, W.TRANSNO, W.WIPSEQNO, W.ACCTENTITYNO, W.ACCTCLIENTNO, 1,
		NULL, NULL, NULL, -- ONLY APPLICABLE FOR CREDIT WIP TRANSFERS
		W.FOREIGNCURRENCY, @pnNewForeignValue
		FROM WORKINPROGRESS W
		WHERE	W.ENTITYNO = @pnEntityKey
		and	W.TRANSNO = @pnTransKey
		and	W.WIPSEQNO = @pnWIPSeqKey"
	
	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnEntityKey		int, 
				@nNewTransKey		int, 
				@dtTransDate		datetime, 
				@pnNewLocalValue	decimal(12,2),
				@pnNewCaseKey		int,
				@pnNewStaffKey	int,
				@pnNewDebtorKey		int, 
				@pnNewProductKey	int,
				@psReasonCode		nvarchar(2),
				@pnNewForeignValue	decimal(12,2),
				@pnTransKey		int,
				@pnWIPSeqKey		int,
				@psNewActivityKey	nvarchar(6),
                                @pnNewEntityKey         int,
                                @nEntityKey             int',
				@pnEntityKey = @pnEntityKey, 
				@nNewTransKey = @nNewTransKey,
				@dtTransDate = @dtTransDate,
				@pnNewLocalValue = @pnNewLocalValue,
				@pnNewCaseKey = @pnNewCaseKey,
				@pnNewStaffKey = @pnNewStaffKey,
				@pnNewDebtorKey = @pnNewDebtorKey,
				@pnNewProductKey = @pnNewProductKey,
				@psReasonCode = @psReasonCode,
				@pnNewForeignValue = @pnNewForeignValue,
				@pnTransKey = @pnTransKey,
				@pnWIPSeqKey = @pnWIPSeqKey,
				@psNewActivityKey = @psNewActivityKey,
                                @pnNewEntityKey = @pnNewEntityKey,
                                @nEntityKey     = @nEntityKey
End

-- return transno for timesheet to group wip items together.
If (@bIsDiscount = 1 and @pnAdjustmentType not in (1000,1001,1008)) and @pnNewTransKey is not null
begin
	Set @nNewTransKey = @pnNewTransKey
end
Set @pnNewTransKey = @nNewTransKey

-- if debit/credit adjust or Split WIP Transfer
-- Single sided post (xfPostSingleSided)
-- Post the adjustment under the same transaction.
-- Otherwise
-- Adjust down the old value and create new WIP under a new Transaction.
if (@nErrorCode = 0 and @pnAdjustmentType not in (1000,1001,1008))
Begin				
	if (@bDebug = 1)
	Begin
		print 'Adjusting WORKINPROGRESS by: ' + cast(@nLocalAdjustment as nvarchar(13))
	End
		
	Set @sSQLString = 'UPDATE WORKINPROGRESS
		SET	BALANCE = BALANCE + @nLocalAdjustment,
			FOREIGNBALANCE = FOREIGNBALANCE + @nForeignAdjustment
		WHERE ENTITYNO = @pnEntityKey
		and TRANSNO = @pnTransKey
		and WIPSEQNO = @pnWIPSeqKey'
			
		
	exec @nErrorCode=sp_executesql @sSQLString,
		N'@nLocalAdjustment	decimal(12,2),
		@nForeignAdjustment	decimal(12,2),
		@pnEntityKey		int,
		@pnTransKey		int,
		@pnWIPSeqKey		int',
		@nLocalAdjustment	=  @nLocalAdjustment,
		@nForeignAdjustment	=  @nForeignAdjustment,
		@pnEntityKey		=  @pnEntityKey,
		@pnTransKey		=  @pnTransKey,
		@pnWIPSeqKey		=  @pnWIPSeqKey
End


-- if debtor transfer, check that the account exists before updating account
if @nErrorCode = 0 and (@pnAdjustmentType = 1004) and (@bIsSplitMultiDebtor = 0 or @nOldDebtorKey is not null)
Begin
	if (@bDebug = 1)
	Begin
		print 'Debtor Transfer detected'
	End
	
	-- Adjust the old debtor
	if (@nOldDebtorKey is null or @pnNewDebtorKey is null)
	Begin
		-- Old WIP item must be debtor related and New debtor key must be provided
		Set @sAlertXML = dbo.fn_GetAlertXML('AC28', 'Debtor WIP transfer cannot be performed against case related WIP.',
		    						null, null, null, null, null)
		  		RAISERROR(@sAlertXML, 14, 1)
		  		Set @nErrorCode = @@ERROR
	End
	
	-- Ensure the account exists for referrential integrity
	If (@nErrorCode = 0)
	Begin
		exec @nErrorCode = dbo.acw_UpdateAccount
			@pnUserIdentityId = @pnUserIdentityId,
			@psCulture = @psCulture,
			@pbCalledFromCentura = @pbCalledFromCentura,
			@pnEntityKey = @pnEntityKey,
			@pnNameKey = @nOldDebtorKey,
			@pnDRAdjustment = 0,
			@pnCRAdjustment = 0
	End
End

If @nErrorCode = 0
Begin
	if (@bDebug = 1)
	Begin
		print 'Get next history line number'
	End
	
	-- Get the next history line number for the work history row
	Set @sSQLString = 'Select @nHistoryLineNo = max(HISTORYLINENO) + 1
			from WORKHISTORY
			WHERE ENTITYNO = @pnEntityKey
			and TRANSNO = @pnTransKey
			and WIPSEQNO = @pnWIPSeqKey'
	
	exec @nErrorCode=sp_executesql @sSQLString,
		N'@nHistoryLineNo	int output,
		@pnEntityKey		int,
		@pnTransKey		int,
		@pnWIPSeqKey		int',
		@nHistoryLineNo		=  @nHistoryLineNo output,
		@pnEntityKey		=  @pnEntityKey,
		@pnTransKey		=  @pnTransKey,
		@pnWIPSeqKey		=  @pnWIPSeqKey
End

If @nErrorCode = 0
Begin
	if (@bDebug = 1)
	Begin
		print 'Adjust original WORKHISTORY'
	End

	Set @sSQLString = 'Insert into WORKHISTORY
		(ENTITYNO, TRANSNO, WIPSEQNO, HISTORYLINENO, 
		TRANSDATE, POSTDATE, TRANSTYPE, POSTPERIOD,
		RATENO, WIPCODE, CASEID, 
		ACCTENTITYNO, ACCTCLIENTNO, EMPLOYEENO, ASSOCIATENO, INVOICENUMBER,  
		TOTALTIME, TOTALUNITS, UNITSPERHOUR, CHARGEOUTRATE, 
		FOREIGNCURRENCY, FOREIGNTRANVALUE, 
		EXCHRATE, 
		LOCALTRANSVALUE, COSTCALCULATION1, COSTCALCULATION2, 
		MARGINNO, REFENTITYNO, REFTRANSNO, 
		EMPPROFITCENTRE, EMPFAMILYNO, EMPOFFICECODE, 
		NARRATIVENO, SHORTNARRATIVE, LONGNARRATIVE, 
		STATUS, QUOTATIONNO, PRODUCTCODE,
		DISCOUNTFLAG, GENERATEDINADVANCE,
		VARIABLEFEEAMT,VARIABLEFEETYPE,VARIABLEFEECURR,
		FEECRITERIANO,FEEUNIQUEID,LOCALCOST,FOREIGNCOST,
		ENTEREDQUANTITY,
		MOVEMENTCLASS, COMMANDID, ITEMIMPACT, MARGINFLAG, REASONCODE,
		TRANSFERDETAIL, CASEPROFITCENTRE, VERIFICATIONNUMBER)
	select 	W.ENTITYNO,
		W.TRANSNO, 
		W.WIPSEQNO,
		@nHistoryLineNo	as HistoryLineNo,
		@pdtAdjustmentDate,
		T.TRANPOSTDATE,
		T.TRANSTYPE,
		T.TRANPOSTPERIOD,
		W.RATENO,
		W.WIPCODE,
		W.CASEID,
		W.ACCTENTITYNO,
		W.ACCTCLIENTNO,
		W.EMPLOYEENO,
		W.ASSOCIATENO,
		W.INVOICENUMBER,
		@dtTotalTimeAdjustment,
		@nTotalUnitsAdjustment,
		NULL, --W.UNITSPERHOUR,
		NULL, --W.CHARGEOUTRATE,
		W.FOREIGNCURRENCY,
		
		CASE WHEN W.FOREIGNCURRENCY IS NOT NULL 
		THEN @nForeignAdjustment
		ELSE NULL END,
		
		W.EXCHRATE,
		
		@nLocalAdjustment,
		
		-- only include cost calculation when writing off the item
		case when @nLocalAdjustment is null or isnull(@pnNewLocalValue,0) = 0 then
			@nTotalCostCalculation1 * -1
		else
			@nTotalCostCalculation1
		end,
		case when @nLocalAdjustment is null or isnull(@pnNewLocalValue,0) = 0 then
			@nTotalCostCalculation2 * -1
		else
			@nTotalCostCalculation2
		end,
		W.MARGINNO,
		T.ENTITYNO,
		T.TRANSNO,
		W.EMPPROFITCENTRE,
		W.EMPFAMILYNO,
		W.EMPOFFICECODE, 
		W.NARRATIVENO,
		W.SHORTNARRATIVE,
		W.LONGNARRATIVE,
		1,
		W.QUOTATIONNO,
		W.PRODUCTCODE,
		ISNULL(W.DISCOUNTFLAG, 0),
		W.GENERATEDINADVANCE,
		W.VARIABLEFEEAMT,
		W.VARIABLEFEETYPE,
		W.VARIABLEFEECURR,
		W.FEECRITERIANO,
		W.FEEUNIQUEID,
		-- Only include cost values for a full adjustment
		CASE WHEN isnull(@pnNewLocalValue,0) = 0 THEN @nTotalLocalCost * -1 ELSE NULL END,
		CASE WHEN isnull(@pnNewForeignValue,0) = 0 THEN @nTotalForeignCost * -1 ELSE NULL END,
		NULL, --ENTEREDQUANTITY,
		case when isnull(@pnNewLocalValue,0) < W.LOCALVALUE then
			5 -- ADJUST DOWN MOVEMENTCLASS
		else
			4 -- ADJUST UP MOVEMENTCLASS
		end, 
				
		case when isnull(@pnNewLocalValue,0) < W.LOCALVALUE then
			6 -- ADJUST DOWN COMMANDID
		else
			5 -- ADJUST UP COMMANDID
		end,
		NULL, -- ITEM IMPACT
		W.MARGINFLAG,
		@psReasonCode,
		CASE
		WHEN @pnAdjustmentType = 1002 then @pnNewStaffKey
		WHEN @pnAdjustmentType = 1003 then @pnNewCaseKey
		WHEN @pnAdjustmentType = 1004 then @pnNewDebtorKey
		WHEN @pnAdjustmentType = 1005 then @pnNewQuotationKey
                WHEN @pnAdjustmentType = 600 then @pnNewEntityKey
		WHEN @pnAdjustmentType = 1007 then @pnNewProductKey
		ELSE null
		END,
		C.PROFITCENTRECODE,
		W.VERIFICATIONNUMBER
	from 	TRANSACTIONHEADER T	
		join WORKINPROGRESS W on (W.ENTITYNO = @pnEntityKey and W.TRANSNO = @pnTransKey and W.WIPSEQNO = @pnWIPSeqKey)
		left join CASES C on (C.CASEID = W.CASEID)
	where	T.TRANSNO  = @nNewTransKey
        and     T.ENTITYNO = @nEntityKey'
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'@nHistoryLineNo	int,
			@pdtAdjustmentDate	datetime,			
			@pnAdjustmentType	int,
			@nForeignAdjustment	decimal(12,2),
			@nLocalAdjustment	decimal(12,2),
			@pnNewLocalValue	decimal(12,2),
			@pnNewForeignValue	decimal(12,2),
			@psReasonCode		nvarchar(2),
			@pnNewStaffKey		int,
			@pnNewCaseKey		int,
			@pnNewDebtorKey		int,
			@pnNewQuotationKey	int,
			@pnNewProductKey	int,
			@nTotalLocalCost	decimal(12,2),
			@nTotalForeignCost	decimal(12,2),
			@nTotalCostCalculation1	decimal(12,2),
			@nTotalCostCalculation2	decimal(12,2),
			@nNewTransKey		int,
			@pnEntityKey		int,
			@pnTransKey		int,
			@pnWIPSeqKey		int,
			@dtTotalTimeAdjustment	datetime,
			@nTotalUnitsAdjustment	int,
                        @pnNewEntityKey         int,
                        @nEntityKey             int',
			@nHistoryLineNo		= @nHistoryLineNo,	
			@pdtAdjustmentDate	= @pdtAdjustmentDate,				
			@pnAdjustmentType	= @pnAdjustmentType,
			@nForeignAdjustment	= @nForeignAdjustment,
			@nLocalAdjustment	= @nLocalAdjustment,
			@pnNewLocalValue	= @pnNewLocalValue,
			@pnNewForeignValue	= @pnNewForeignValue,
			@psReasonCode		= @psReasonCode,
			@pnNewStaffKey		= @pnNewStaffKey,
			@pnNewCaseKey		= @pnNewCaseKey,
			@pnNewDebtorKey		= @pnNewDebtorKey,
			@pnNewQuotationKey	= @pnNewQuotationKey,
			@pnNewProductKey	= @pnNewProductKey,
			@nTotalLocalCost	= @nTotalLocalCost,
			@nTotalForeignCost	= @nTotalForeignCost,
			@nTotalCostCalculation1	= @nTotalCostCalculation1,
			@nTotalCostCalculation2	= @nTotalCostCalculation2,
			@nNewTransKey		= @nNewTransKey,
			@pnEntityKey		= @pnEntityKey,
			@pnTransKey		= @pnTransKey,
			@pnWIPSeqKey		= @pnWIPSeqKey,
			@dtTotalTimeAdjustment	= @dtTotalTimeAdjustment,
			@nTotalUnitsAdjustment	= @nTotalUnitsAdjustment,
                        @pnNewEntityKey         = @pnNewEntityKey,
                        @nEntityKey             = @nEntityKey
	
End	


If @nErrorCode = 0
Begin
	if (@bDebug = 1)
	Begin
		print 'Update Control Total'
		
		SELECT 'ORIGINAL CONTROL TOTALS'
		SELECT * FROM CONTROLTOTAL WHERE LEDGER = 1
			AND TYPE = @pnAdjustmentType 
			and PERIODID = @nPostPeriod
	End
	
	exec @nErrorCode = dbo.acw_UpdateControlTotal
		@pnUserIdentityId = @pnUserIdentityId,
		@psCulture = @psCulture,
		@pbCalledFromCentura = @pbCalledFromCentura,
		@pnLedger = 1, -- WIP Ledger
		@pnCategory	= @nMovementClass,
		@pnType		= @pnAdjustmentType,
		@pnPeriodId	= @nPostPeriod,
		@pnEntityNo	= @pnEntityKey,
		@pnAmountToAdd	= @nLocalAdjustment
		
	if (@bDebug = 1)
	Begin
		print 'Update Control Total'
		
		SELECT 'CONTROL TOTALS AFTER ADJUSTMENT'
		SELECT * FROM CONTROLTOTAL WHERE LEDGER = 1
			AND TYPE = @pnAdjustmentType 
			and PERIODID = @nPostPeriod
	End
End
	
-- Update WIP for an adjustment
If @nErrorCode = 0 and @pnAdjustmentType in (1000,1001,1008)
Begin
	if (@bDebug = 1)
	Begin
		print 'Update WORKINROGRESS Balance'
	End
	
	Set @sSQLString = 'Update W
	Set W.BALANCE = W.BALANCE + @nLocalAdjustment,
	W.CHARGEOUTRATE = @nNewChargeOutRate,
	W.FOREIGNBALANCE = CASE WHEN W.FOREIGNCURRENCY IS NOT NULL THEN W.FOREIGNBALANCE + @nForeignAdjustment ELSE W.FOREIGNBALANCE END'

	if @pdtNewTotalTime is not null
	Begin
		Set @sSQLString = @sSQLString + ',' +char(10)+'W.TOTALTIME = @pdtNewTotalTime'
	End
	if @pnNewTotalUnits is not null
	Begin
		Set @sSQLString = @sSQLString + ',' +char(10)+'W.TOTALUNITS = @pnNewTotalUnits'
	End

	Set @sSQLString = @sSQLString +char(10)+ 
	'from WORKINPROGRESS W
	WHERE	W.ENTITYNO = @pnEntityKey
	and	W.TRANSNO = @pnTransKey
	and	W.WIPSEQNO = @pnWIPSeqKey'
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'@nLocalAdjustment	decimal(12,2),
			@nForeignAdjustment	decimal(12,2),
			@nNewChargeOutRate	decimal(11,2),
			@pnEntityKey		int,
			@pnTransKey		int,
			@pnWIPSeqKey		int,
			@pdtNewTotalTime	datetime,
			@pnNewTotalUnits	int',
			@nLocalAdjustment	= @nLocalAdjustment,
			@nForeignAdjustment	= @nForeignAdjustment,
			@nNewChargeOutRate	= @nNewChargeOutRate,
			@pnEntityKey		= @pnEntityKey,
			@pnTransKey		= @pnTransKey,
			@pnWIPSeqKey		= @pnWIPSeqKey,
			@pdtNewTotalTime	= @pdtNewTotalTime,
			@pnNewTotalUnits	= @pnNewTotalUnits
End


If (@nErrorCode = 0)
Begin
	if (@bDebug = 1)
	Begin
		print 'Delete fully consumed WIP'
	End
	-- Delete fully consumed WIP
	Set @sSQLString = "Delete W
		from WORKINPROGRESS W
		WHERE	W.ENTITYNO = @pnEntityKey
		and	W.TRANSNO = @pnTransKey
		and	W.WIPSEQNO = @pnWIPSeqKey
		and	W.BALANCE = 0"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnEntityKey	int,
				  @pnTransKey	int,
				  @pnWIPSeqKey	int',
				  @pnEntityKey = @pnEntityKey,
				  @pnTransKey = @pnTransKey,
				  @pnWIPSeqKey = @pnWIPSeqKey
End

if (@nErrorCode = 0
	and @pnAdjustmentType not in (1000,1001,1008))
Begin
	if (@bDebug = 1)
	Begin
		print 'Get values from old WIP item to generate transfer WIP Item'
	End
	
	-- Add new WIP item for transferred item
	-- Get values from old WIP item.
        declare @nWIPToNameNo		int		-- the debtor
	declare @nWIPToCaseId		int		-- the case
	declare @nEmployeeNo		int		-- Staff member recorded with WIP
	declare @nAssociateNo		int		-- NameNo of Associate who generated charge being disbursed
	
	declare @sInvoiceNumber		nvarchar(20)		-- Incoming invoice number being disbursed
	declare @sVerificationNumber	nvarchar(20)	
	declare @nRateNo		int		-- The RateNo for WIP generated by a rate calculation
	declare @sWIPCode		nvarchar(6)	-- Mandatory	
	declare @dtTotalTime		datetime	-- Time used in calculation of WIP
	declare @nTotalUnits		int		-- Time as units used in calculation of WIP
	declare @nUnitsPerHour		smallint	-- Number of units that fit into one hour
	declare @nChargeOutRate		decimal(11,2)	
	declare @pnLocalValue		decimal(11,2)		-- Mandatory	-- Value of WIP
	declare @pnForeignValue		decimal(11,2)		-- Value of WIP in foreign currency
	
	declare @sForeignCurrency	nvarchar(3)
	declare @nExchangeRate		decimal(11,4)	-- Exchange rate between home currency and Foreign Currency
	declare @nDiscountValue		decimal(11,2)		-- Calculated discount in local currency as positive number	
	declare @nForeignDiscount	decimal(11,2)	-- Calculated discount in foreign currency as positive number
	declare @nVariableFeeAmt	decimal(11,2)	-- Amount recorded as the variable fee
	declare @nVariableFeeType	smallint	
	declare @sVariableCurrency	nvarchar(6)	-- Currency of variable fee
	declare @nFeeCriteriaNo		int			-- Criteria used to calculate fee
	declare @nFeeUniqueId		int		-- Identifies Fee Calculation row used in calculation
	declare @nQuotationNo		int
	declare @nEnteredQuantity	int		-- A quantity used in calculation of of the WIP value
	declare @nProductCode		int		
	declare @bGeneratedInAdvance	bit		
	declare @nNarrativeNo		int		-- Pointer to saved narrative
	declare @sNarrative		nvarchar(max)		-- Free format text to be saved with WIP
 	declare @sFeeType		nvarchar(6)	-- Indicates the type of IP Office fee being paid
	
	declare @nBaseFeeAmount		decimal(11,2)	-- Base fee being paid
	declare @nAdditionalFee		decimal(11,2)	-- Component of fee calculated from @nQuantityInCalc
	declare @sFeeTaxCode		nvarchar(3)	-- Tax code associated with Fee.
	declare @nFeeTaxAmount		decimal(11,2)	-- Tax amount of the Fee
 	declare @nAgeOfCase		smallint	-- The annuity number of Case being paid for inclusion on Fee List
	declare @nMarginNo		int		-- The margin identity for the applied Margin

	declare @bIsCreditWIP		bit		
	declare @sReasonCode		nvarchar(2)	

	declare @sProtocolNo		nvarchar(20)	-- Protocol Key
	declare @sProtocolDateString	nvarchar(15)	-- Protocol Date String

	declare @dtWIPTransDate		datetime  
        declare @sProfitCentre          nvarchar(6)      
        
	Set @sSQLString = 'Select @nWIPToNameNo = ACCTCLIENTNO,
	@nWIPToCaseId = CASEID,
	@nEmployeeNo = EMPLOYEENO,
	@nAssociateNo = ASSOCIATENO,
	@sInvoiceNumber	= INVOICENUMBER,
	@sVerificationNumber = VERIFICATIONNUMBER,
	@nRateNo = RATENO,
	@sWIPCode = WIPCODE,	
	@dtTotalTime = TOTALTIME,
	@nTotalUnits = TOTALUNITS,
	@nUnitsPerHour = UNITSPERHOUR,
	@nChargeOutRate = CHARGEOUTRATE,
	@sForeignCurrency	= FOREIGNCURRENCY,	
	@nExchangeRate = EXCHRATE,
	@nVariableFeeAmt = VARIABLEFEEAMT,
	@nVariableFeeType = VARIABLEFEETYPE,
	@sVariableCurrency = VARIABLEFEECURR,
	@nFeeCriteriaNo	= FEECRITERIANO,
	@nFeeUniqueId = FEEUNIQUEID,
	@nQuotationNo = QUOTATIONNO,
	@nEnteredQuantity = ENTEREDQUANTITY,
	@nProductCode = PRODUCTCODE,
	@bGeneratedInAdvance = GENERATEDINADVANCE,
	@nNarrativeNo = NARRATIVENO,
	@sNarrative = ISNULL(SHORTNARRATIVE,LONGNARRATIVE),
	@nMarginNo = MARGINNO,
	@sProtocolNo = PROTOCOLNO,
	@sProtocolDateString = PROTOCOLDATE,
	@dtWIPTransDate = TRANSDATE,
        @sProfitCentre = EMPPROFITCENTRE
	from WORKHISTORY  
	WHERE	ENTITYNO = @pnEntityKey
	and	TRANSNO = @pnTransKey
	and	WIPSEQNO = @pnWIPSeqKey
	and	ITEMIMPACT = 1'


	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnEntityKey	int,
				  @pnTransKey	int,
				  @pnWIPSeqKey	int,
				@nWIPToNameNo		int output,
				@nWIPToCaseId		int output,
				@nEmployeeNo		int output,
				@nAssociateNo		int output,
				@sInvoiceNumber		nvarchar(20) output,
				@sVerificationNumber	nvarchar(20) output,
				@nRateNo		int output,
				@sWIPCode		nvarchar(6) output,
				@dtTotalTime		datetime output,
				@nTotalUnits		int output,
				@nUnitsPerHour		smallint output,
				@nChargeOutRate		decimal(11,2) output,
				@sForeignCurrency	nvarchar(3) output,
				@nExchangeRate		decimal(11,4) output,
				@nVariableFeeAmt	decimal(11,2) output,
				@nVariableFeeType	smallint output,
				@sVariableCurrency	nvarchar(6) output,
				@nFeeCriteriaNo		int output,
				@nFeeUniqueId		int output,
				@nQuotationNo		int output,
				@nEnteredQuantity	int output,
				@nProductCode		int output,
				@bGeneratedInAdvance	bit output,
				@nNarrativeNo		int output,
				@sNarrative		nvarchar(max) output,
				@nMarginNo		int output,
				@sProtocolNo		nvarchar(20) output,
				@sProtocolDateString	nvarchar(15) output,
				@dtWIPTransDate		datetime output,
                                @sProfitCentre          nvarchar(6)     output',
				@pnEntityKey		= @pnEntityKey,
				@pnTransKey		= @pnTransKey,
				@pnWIPSeqKey		= @pnWIPSeqKey,
				@nWIPToNameNo		= @nWIPToNameNo output,
				@nWIPToCaseId		= @nWIPToCaseId output,
				@nEmployeeNo		= @nEmployeeNo output,
				@nAssociateNo		= @nAssociateNo output,
				@sInvoiceNumber		= @sInvoiceNumber output,
				@sVerificationNumber	= @sVerificationNumber output,
				@nRateNo		= @nRateNo output,
				@sWIPCode		= @sWIPCode output,
				@dtTotalTime		= @dtTotalTime output,
				@nTotalUnits		= @nTotalUnits output,
				@nUnitsPerHour		= @nUnitsPerHour output,
				@nChargeOutRate		= @nChargeOutRate output,
				@sForeignCurrency	= @sForeignCurrency output,
				@nExchangeRate		= @nExchangeRate output,
				@nVariableFeeAmt	= @nVariableFeeAmt output,
				@nVariableFeeType	= @nVariableFeeType output,
				@sVariableCurrency	= @sVariableCurrency output,
				@nFeeCriteriaNo		= @nFeeCriteriaNo output,
				@nFeeUniqueId		= @nFeeUniqueId output,
				@nQuotationNo		= @nQuotationNo output,
				@nEnteredQuantity	= @nEnteredQuantity output,
				@nProductCode		= @nProductCode output,
				@bGeneratedInAdvance	= @bGeneratedInAdvance output,
				@nNarrativeNo		= @nNarrativeNo output,
				@sNarrative		= @sNarrative output,
				@nMarginNo		= @nMarginNo output,
				@sProtocolNo		= @sProtocolNo output,
				@sProtocolDateString	= @sProtocolDateString output,
				@dtWIPTransDate		= @dtWIPTransDate output,
                                @sProfitCentre          = @sProfitCentre  output				
		
		--retain some old WIP information to be used later
		declare @nOldWIPToNameNo	int		-- the debtor
		declare @nOldWIPToCaseId	int		-- the case
		declare @nOldEmployeeNo		int		-- Staff member recorded with WIP
		declare @nOldProductCode	int		-- Protocol Key
		declare @nOldWIPCode		nvarchar(6)	-- WIP/Activity Code
		
		Set @nOldWIPToNameNo = @nWIPToNameNo
		Set @nOldWIPToCaseId = @nWIPToCaseId
		Set @nOldEmployeeNo = @nEmployeeNo
		Set @nOldProductCode = @nProductCode
		Set @nOldWIPCode = @sWIPCode
			
	        Set @bIsSplitWip = Case WHEN @pnAdjustmentType = 1003 THEN 0 ELSE @bIsSplitMultiDebtor End

        -- Override the old value with the new transfer value
        If @pnAdjustmentType = 1002
        Begin
		Set @nEmployeeNo = @pnNewStaffKey

                Set @sSQLString = 'Select @sProfitCentre = PROFITCENTRECODE from EMPLOYEE where EMPLOYEENO = @pnNewStaffKey'
                exec @nErrorCode=sp_executesql @sSQLString, 
				N'@sProfitCentre	nvarchar(6) output,
                                  @pnNewStaffKey        int',
                                  @sProfitCentre        = @sProfitCentre output,
                                  @pnNewStaffKey        = @pnNewStaffKey

	End
        Else If @pnAdjustmentType = 1003
        Begin
		Set @nWIPToCaseId = @pnNewCaseKey
		if @psNewActivityKey is not null
		begin
			set @sWIPCode = @psNewActivityKey
		end
        End
        Else if @pnAdjustmentType = 1004
        Begin
		Set @nWIPToNameNo = @pnNewDebtorKey
        End
        Else if @pnAdjustmentType = 1005
        Begin
		Set @nQuotationNo = @pnNewQuotationKey
        End
        Else if @pnAdjustmentType = 1007
        Begin
		Set @nProductCode = @pnNewProductKey
	End
	Else if @pnAdjustmentType = 1010
        Begin
		set @sWIPCode = @psNewActivityKey
	End

	If @pdtNewTotalTime is not null and @pnNewTotalUnits is not null
	Begin
		Set @dtTotalTime = @pdtNewTotalTime
		Set @nTotalUnits = @pnNewTotalUnits
	End 
	
	If @nErrorCode = 0
	Begin
	
		if (@bDebug = 1)
		Begin
			print 'Post the transfer WIP item.'
		End
		Exec @nErrorCode = dbo.wp_PostWIP
			@pnUserIdentityId	= @pnUserIdentityId,		-- Mandatory
			@psCulture		= @psCulture,
			@pbCalledFromCentura	= @pbCalledFromCentura,
			@pnEntityKey		= @nEntityKey,			-- Mandatory	   Entity WIP is recorded against
			@pdtTransDate		= @pdtAdjustmentDate,		-- Mandatory	   Date of transaction
			@pnTransactionType	= @pnAdjustmentType,		-- Default to WIP recording

			@pnWIPToNameNo		= @nWIPToNameNo,		-- Mandatory	
			@pnWIPToCaseId		= @nWIPToCaseId,		-- For WIP recorded against Case, if null then WIP is recorded against Name
			@pnEmployeeNo		= @nEmployeeNo,			-- Staff member recorded with WIP
			@pnAssociateNo		= @nAssociateNo,		-- NameNo of Associate who generated charge being disbursed
			
			@psInvoiceNumber	= @sInvoiceNumber,		-- Incoming invoice number being disbursed
			@psVerificationNumber	= @sVerificationNumber,
			@pnRateNo		= @nRateNo,			-- The RateNo for WIP generated by a rate calculation
			@psWIPCode		= @sWIPCode,			-- Mandatory	
			@pdtTotalTime		= @dtTotalTime,		-- Time used in calculation of WIP
			@pnTotalUnits		= @nTotalUnits,		-- Time as units used in calculation of WIP
			@pnUnitsPerHour		= @nUnitsPerHour,		-- Number of units that fit into one hour
			@pnChargeOutRate	= @nChargeOutRate,		-- Charge out rate for time based charges
			@pnLocalValue		= @nTotalLocal,		-- Mandatory	-- Value of WIP
			@pnForeignValue		= @nTotalForeign,		-- Value of WIP in foreign currency
			
			@psForeignCurrency	= @sForeignCurrency,		-- Currency of Foreign Value
			@pnExchangeRate		= @nExchangeRate,		-- Exchange rate between home currency and Foreign Currency
			@pnDiscountValue	= null,		-- Calculated discount in local currency as positive number	
			@pnForeignDiscount	= null,		-- Calculated discount in foreign currency as positive number
			@pnVariableFeeAmt	= @nVariableFeeAmt,		-- Amount recorded as the variable fee
			@pnVariableFeeType	= @nVariableFeeType,
			@psVariableCurrency	= @sVariableCurrency,		-- Currency of variable fee
			@pnFeeCriteriaNo	= @nFeeCriteriaNo,		-- Criteria used to calculate fee
			@pnFeeUniqueId		= @nFeeUniqueId,		-- Identifies Fee Calculation row used in calculation
			@pnQuotationNo		= @nQuotationNo,
			
			@pnLocalCost		= @nTotalLocalCost,		-- Cost value of WIP raised in local currency
			@pnForeignCost		= @nTotalForeignCost,		-- Cost value of WIP raised in foreign currency
			@pnCostCalculation1	= @nTotalCostCalculation1,		-- Cost of WIP using cost rate 1 method
			@pnCostCalculation2	= @nTotalCostCalculation2,		-- Cost of WUP using cost rate 2 method
			@pnEnteredQuantity	= @nEnteredQuantity,		-- A quantity used in calculation of of the WIP value
			@pnProductCode		= @nProductCode,
			@pbGeneratedInAdvance	= @bGeneratedInAdvance,
			@pnNarrativeNo		= @pnNewNarrativeKey,		-- Pointer to saved narrative
			@psNarrative		= @psNewDebitNoteText,		-- Free format text to be saved with WIP
			
 			@psFeeType		= @sFeeType,		-- Indicates the type of IP Office fee being paid
			@pnBaseFeeAmount	= @nBaseFeeAmount,		-- Base fee being paid
			@pnAdditionalFee	= @nAdditionalFee,		-- Component of fee calculated from @pnQuantityInCalc
			@psFeeTaxCode		= @sFeeTaxCode,		-- Tax code associated with Fee.
			@pnFeeTaxAmount		= @nFeeTaxAmount,		-- Tax amount of the Fee
 			@pnAgeOfCase		= @nAgeOfCase,		-- The annuity number of Case being paid for inclusion on Fee List
			@pnMarginNo		= @nMarginNo,		-- The margin identity for the applied Margin
			@pnDebugFlag		= 0,			--0=off,1=trace execution,2=dump data
			@pbDraftWIP		= 0,		--0=process normal WIP 1=process draft WIP from billing
			@pnItemTransNo		= @nNewTransKey,		-- Item TransNo of the open item for draft WIP.
			@bIsCreditWIP		= 0,
			@pbSeparateMarginFlag		= 0,	-- Margin to be stored as seperate WIP Item
			@pnLocalMargin			= null,	-- Margin amount
			@pnForeignMargin		= null,	-- Forign Margin Amount
			@pnDiscountForMargin		= null,	-- Calculated discount for margin in local currency as positive number	
			@pnForeignDiscountForMargin	= null,	-- Calculated discount for margin in foreig
			@psReasonCode			= @psReasonCode,
			@pbReturnWIPKey			= 0,
			@pbSuppressCommit		= 1,	-- Supress commit/rollback transaction processing
			@pbSuppressPostToGL		= 1,	-- Override Post to GL site control
			@psProtocolNo			= @sProtocolNo,	-- Protocol Key
			@psProtocolDateString		= @sProtocolDateString, -- Protocol Date String
                        @psProfitCentreCode             = @sProfitCentre,
			@pbIsSplitWip			= @bIsSplitWip
	End
	
	If @nErrorCode = 0 and @dtWIPTransDate is not null
	Begin
		-- validate the transaction date and get the post period.
		exec @nErrorCode = dbo.acw_ValidateTransactionDate
					@pnUserIdentityId	= @pnUserIdentityId,
					@psCulture		= @psCulture,
					@pbCalledFromCentura	= @pbCalledFromCentura,
					@pdtItemDate		= @dtWIPTransDate,
					@pnModule		= 1,
					@pbIgnoreWarnings	= 1,
					@pnPeriodId		= @nWipPostPeriod output
		if (@bDebug = 1)
		Begin
			print 'Validated Trans Date'
		End
	End

	If @nErrorCode = 0
	Begin
		-- Adjust WorkHistory Trans. Date
		-- Adjust Workhistory WIP adjustment details
		UPDATE W
		SET TRANSDATE = @dtWIPTransDate,
		POSTPERIOD = @nWipPostPeriod,
		TRANSFERDETAIL = 
		CASE
		WHEN @pnAdjustmentType = 1002 then @nOldEmployeeNo
		WHEN @pnAdjustmentType = 1003 then @nOldWIPToCaseId
		WHEN @pnAdjustmentType = 1004 then @nOldWIPToNameNo
                WHEN @pnAdjustmentType = 600 then @pnEntityKey
		WHEN @pnAdjustmentType = 1007 then @nOldProductCode
		ELSE null
		END,
		MOVEMENTCLASS = case when LOCALTRANSVALUE > 0 
		then 4
		else 5 end,
		COMMANDID = case when LOCALTRANSVALUE > 0
		then 9
		else 10 end,
		DISCOUNTFLAG = case when LOCALTRANSVALUE > 0
		then 0
		else 1 end,
		EMPPROFITCENTRE = E.PROFITCENTRECODE
		from WORKHISTORY W
		left join EMPLOYEE E on (E.EMPLOYEENO = W.EMPLOYEENO)
		WHERE ENTITYNO = @nEntityKey
		and	TRANSNO = @nNewTransKey
		and	WIPSEQNO = 1
	End
	
	If @nErrorCode = 0
	Begin
		-- Adjust WIP Trans. Date
		UPDATE WORKINPROGRESS 
		SET TRANSDATE = @dtWIPTransDate,
                    DISCOUNTFLAG = @bIsDiscount
		WHERE ENTITYNO = @nEntityKey
		and	TRANSNO = @nNewTransKey
		and	WIPSEQNO = 1
	End
	

	-- R50927 Calculate the controltotal of the wip transfer
	If @nErrorCode = 0
	Begin
		Select @nLocalAdjustment = ISNULL(LOCALTRANSVALUE,0),
		@nMovementClass = MOVEMENTCLASS
		From WORKHISTORY
		Where ENTITYNO = @nEntityKey
		AND TRANSNO = @nNewTransKey
		AND WIPSEQNO = 1
		Set @nErrorCode = @@ERROR

		If @nErrorCode = 0
		Begin
			-- Call this procedure to insert/update controltotal as appropriate
			exec @nErrorCode = dbo.acw_UpdateControlTotal
				@pnUserIdentityId = @pnUserIdentityId,
				@psCulture = @psCulture,
				@pbCalledFromCentura = @pbCalledFromCentura,
				@pnLedger = 1, -- WIP Ledger
				@pnCategory	= @nMovementClass,
				@pnType		= @pnAdjustmentType,
				@pnPeriodId	= @nPostPeriod,
				@pnEntityNo	= @nEntityKey,
				@pnAmountToAdd	= @nLocalAdjustment
		End
	End
	
	
	If (@nErrorCode = 0 and @nGLJournalCreation = 1)
	Begin
		exec @nErrorCode = dbo.fi_CreateAndPostJournals
		  @pnResult = @nResult OUTPUT,
		  @pnUserIdentityId = @pnUserIdentityId,
		  @psCulture = @psCulture,
		  @pbCalledFromCentura = @pbCalledFromCentura,
		  @pnEntityNo = @nEntityKey,
		  @pnTransNo = @nNewTransKey,
		  @pnDesignation = 1,
		  @pbIncProcessedNoJournal = 0	
	End
End
Else
Begin
	-- Otherwise, transaction completed. Post to GL if necessary.
	If (@nGLJournalCreation = 1)
	Begin
		If (@bDebug = 1)
		Begin
			Print 'Process GL Interface'
		End
		
		exec @nErrorCode = dbo.fi_CreateAndPostJournals
		  @pnResult = @nResult OUTPUT,
		  @pnUserIdentityId = @pnUserIdentityId,
		  @psCulture = @psCulture,
		  @pbCalledFromCentura = @pbCalledFromCentura,
		  @pnEntityNo = @nEntityKey,
		  @pnTransNo = @nNewTransKey,
		  @pnDesignation = 1,
		  @pbIncProcessedNoJournal = 0
	End
End

If @bDebug = 1
Begin
	SELECT 'TRANSACTIONHEADER'
	SELECT * FROM TRANSACTIONHEADER WHERE TRANSNO = @nNewTransKey
	SELECT 'TRANSADJUSTMENT'
	SELECT * FROM TRANSADJUSTMENT WHERE TRANSNO = @nNewTransKey
	SELECT 'WORKHISTORY'
	Select * from WORKHISTORY WHERE REFTRANSNO = @nNewTransKey
	SELECT 'OLD WORKINPROGRESS'
	SELECT * FROM WORKINPROGRESS WHERE TRANSNO = @pnTransKey AND WIPSEQNO = @pnWIPSeqKey
	SELECT 'NEW WORKINPROGRESS'
	SELECT * FROM WORKINPROGRESS WHERE TRANSNO = @nNewTransKey
	SELECT 'FINAL CONTROL TOTALS'
	SELECT * FROM CONTROLTOTAL WHERE LEDGER = 1 AND TYPE = @pnAdjustmentType and PERIODID = @nPostPeriod
	select 'GLJOURNAL ROWS'
	SELECT * FROM GLJOURNAL WHERE TRANSNO = @nNewTransKey
	select 'GLJOURNALLINE ROWS'
	SELECT * FROM GLJOURNALLINE WHERE TRANSNO = @nNewTransKey
End


RETURN @nErrorCode
GO

Grant execute on dbo.wpw_AdjustWIP  to public
GO