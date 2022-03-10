-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wpw_SplitWIP
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wpw_SplitWIP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wpw_SplitWIP.' 
	drop procedure dbo.wpw_SplitWIP
	print '**** Creating procedure dbo.wpw_SplitWIP...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.wpw_SplitWIP
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbCalledFromCentura	bit		= 0,	-- Indicates that Centura called the stored procedure
	@pnEntityKey		int,			-- Original WIP being split
	@pnTransKey		int,			-- Original WIP being split
	@pnWIPSeqKey		int,			-- Original WIP being split
	@pnStaffKey		int,			-- the staff member to split the WIP to
	@pnCaseKey		int		= null,	-- the case key to split the WIP to
	@pnNameKey		int		= null,	-- the debtor key to split the WIP to
	@pnNarrativeKey		int		= null,	-- the narrative for splitted WIP
	@psDebitNoteText	nvarchar(max)	= null, -- the narrative text for splitted WIP
	@psProfitCentreCode	nvarchar(6)	= null, -- the profit center code for splitted WIP
	@psReasonCode		nvarchar(2),		-- Split WIP Reason
	@pnLocalSplit		decimal(12,2),		-- the local split amount
	@pnForeignSplit		decimal(12,2)	= null,	-- the foreign split amount
	@pnSplitPercentage	decimal(5,2)	= null,	-- split percentage
	@pbAdjustOriginalWIP	bit		= 0,	-- set to true for the last split.
	@pdtLogDateTimeStamp	datetime	= null,	-- LOGDATETIMESTAMP of the original wip item
	@pnAppendToTransKey	int		= null	Output,	-- The new 1008 split transaction key
	@pnNewWipSeqKey		int		= null	Output  -- The new wip sequence key
)
-- PROCEDURE :	wpw_SplitWIP
-- VERSION :	15
-- DESCRIPTION:	Process a split of a WIP Items.
--		Note - draft wip items are not splittable. They should just be unselected and added again as necessary.
--		This procedure will be called over and over for each split transaction.
-- CALLED BY :	Billing Wizard

-- MODIFICTIONS :
-- Date		Who	Number		Version	Details
-- -----------	---	-------		-------	-------------------------------------
-- 27-Oct-2010	AT	RFC8354		1	Procedure Created.
-- 22-Jul-2011	KR	RFC11007	2	Fixed issues with split bill when changing name of the staff and not spliting
-- 06-Oct-2011	AT	RFC11392	3	Fixed issues updating control totals.
--						Amended solution for 11007 by deriving @pnAppendToTransKey for single staff split.
--						Added GL Journal processing for split transaction.
--						Perform Staff WIP Transfer instead of WIP Split for single staff split.
-- 01-Apr-2013	MS	RFC9011		4	Added parameters for CaseKey, NameKey, NarrativeKey, DebitNoteText and ProfitCenter.
--						Return wp_PostWIP select in table variable
--						Return transKey, WipseqKey as output parameters	
-- 01-Apr-2013  MS	RFC9011		5	Added VerificationNumber in WORKHISTORY table insert for adjusting Original WIP Item
-- 03-Apr-2013  MS	RFC9011		6	Added LogDateTimeStamp of original wip item for checking original wip item not modified 
--						Displayed alert if original wip item doesn't get deleted
--						Total time and units for last item is calculated as Original item - sum of splitted items
-- 08-Apr-2013  MS	RFC9011		7	Return TransKey, WipSeqKey as output parameters from wp_PostWip
-- 17-Apr-2013	AT	RFC9011		8	Fixed movement class for credit wip splits.
--						Remove time against trans date.
--						Fixed proportional splitting of units over-allocating.
-- 09-Oct-2013	AT	R27484		9	Fixed profit centre reallocation from billing wizard.
-- 23-Oct-2013  MS	R26273		10	Handle multi debtor scenarios for split wip
-- 10-Feb-2015  MS	R30327		11	Added @pnSplitPercentage as input parameter and passed it to 
-- 10-Nov-2015	AT	R54318		12	Allocate remainder value for COST values instead of apportioning.
-- 17-Apr-2018	MS	R57086		13	used original transdate for splitpwip.
-- 06-Aug-2018	LP	R74733		14	Set SuppressPostToGL to TRUE when calling wp_PostWIP.
-- 04-Sep-2019  MS      DR51324         15      Set MovementClass and CommandId for new rows

AS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @sSQLString		nvarchar(Max)
declare @sAlertXML		nvarchar(400)

Declare @nTimeInMinutes         int
Declare @nHistoryLineNo         int
Declare @bIsStaffTransfer	bit

-- Declare the list of params for wp_PostWIP
Declare @dtTransDate		datetime
Declare @nTransactionType	int
Declare @nWIPToNameNo		int
Declare @nWIPToCaseId		int
Declare @nEmployeeNo		int
Declare @nAssociateNo		int

Declare @sInvoiceNumber	        nvarchar(20)
Declare @sVerificationNumber	nvarchar(20)
Declare @nRateNo		int
Declare @sWIPCode		nvarchar(6)
Declare @dtTotalTime		datetime
Declare @nTotalUnits		int
Declare @nUnitsPerHour		smallint
Declare @nChargeOutRate	        decimal(11,2)
Declare @nLocalValue		decimal(11,2)
Declare @nForeignValue		decimal(11,2)

Declare @sForeignCurrency	nvarchar(3)
Declare @nExchangeRate		decimal(11,4)
Declare @nQuotationNo		int

Declare @nLocalCost		decimal(11,2)
Declare @nForeignCost		decimal(11,2)
Declare @nCostCalculation1	decimal(11,2)
Declare @nCostCalculation2	decimal(11,2)
Declare @nProductCode		int
Declare @bGeneratedInAdvance	bit
Declare @nNarrativeNo		int
Declare @sNarrative		nvarchar(max)
Declare @nMarginNo		int
Declare @sProfitCentreCode	nvarchar(6)
Declare @dtLogDateTimeStamp	datetime
Declare @delRowCount		int
Declare @bIsSplitMultiDebtor    bit
Declare @nOriginalCaseKey	int
Declare @bIsSplitWip		bit
Declare @bIsMultiDebtorCase	bit
Declare @bIsDiscount	        bit

Set @nErrorCode = 0
Set @bIsStaffTransfer = 0
Set @bIsMultiDebtorCase = 0

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

-- We're splitting the entire value on the first round.
If (@nErrorCode = 0 and @pbAdjustOriginalWIP = 1 and @pnAppendToTransKey is null)
Begin		
	-- This is actually a staff transfer transaction
	Set @bIsStaffTransfer = 1
End

If @nErrorCode = 0
Begin
	Select 
	@dtTransDate		= dbo.fn_DateOnly(W.TRANSDATE),
	@nTransactionType	= case when @bIsStaffTransfer = 1 then 1002 else 1008 end,
	@nWIPToNameNo		= W.ACCTCLIENTNO,
	@nWIPToCaseId		= W.CASEID,
	@nAssociateNo		= W.ASSOCIATENO,
	@sInvoiceNumber		= W.INVOICENUMBER,
	@sVerificationNumber	= W.VERIFICATIONNUMBER,
	@nRateNo		= W.RATENO,
	@sWIPCode		= W.WIPCODE,
	@dtTotalTime		= W.TOTALTIME,
	@nTotalUnits		= W.TOTALUNITS,
	@nUnitsPerHour		= W.UNITSPERHOUR,
	@nChargeOutRate		= W.CHARGEOUTRATE,
	@nLocalValue		= W.LOCALVALUE,
	@nForeignValue		= W.FOREIGNVALUE,
	@sForeignCurrency	= W.FOREIGNCURRENCY,
	@nExchangeRate		= W.EXCHRATE,
	@nQuotationNo		= W.QUOTATIONNO,
	@nLocalCost		= W.LOCALCOST,
	@nForeignCost		= W.FOREIGNCOST,
	@nCostCalculation1	= W.COSTCALCULATION1,
	@nCostCalculation2	= W.COSTCALCULATION2,
	@nProductCode		= W.PRODUCTCODE,
	@bGeneratedInAdvance	= W.GENERATEDINADVANCE,
	@nNarrativeNo		= W.NARRATIVENO,
	@sNarrative		= ISNULL(W.LONGNARRATIVE, W.SHORTNARRATIVE),
	@nMarginNo		= W.MARGINNO,
	@sProfitCentreCode	= W.EMPPROFITCENTRE,
	@dtLogDateTimeStamp	= LOGDATETIMESTAMP,
        @bIsDiscount            = CASE WHEN W.DISCOUNTFLAG = 1 THEN 1 ELSE 0 END
	from WORKINPROGRESS W
	WHERE W.ENTITYNO = @pnEntityKey
	and W.TRANSNO = @pnTransKey
	and W.WIPSEQNO = @pnWIPSeqKey

	Set @nErrorCode = @@Error
	Set @nOriginalCaseKey = @nWIPToCaseId
End

if @nErrorCode = 0 and @pdtLogDateTimeStamp <> @dtLogDateTimeStamp
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('AC29', 'The WIP item has been changed or removed. Please reload the WIP item and try again.',
						NULL, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0 and @pnNameKey is not null
Begin
	Set @nNarrativeNo	= @pnNarrativeKey
	Set @sNarrative		= @psDebitNoteText

	If (@pnCaseKey is null) or (@pnCaseKey is not null and @pnCaseKey <> @nOriginalCaseKey) 
	Begin
		Set @nWIPToCaseId	= @pnCaseKey
		Set @nWIPToNameNo	= @pnNameKey		
	End
End

If @nErrorCode = 0 and @psProfitCentreCode is not null and @psProfitCentreCode != ""
Begin
	Set @sProfitCentreCode	= @psProfitCentreCode
End

If (@nErrorCode = 0)
Begin
	If @pbAdjustOriginalWIP = 1 and @pnAppendToTransKey is not null
	Begin
		Set @sSQLString = 'Select @nTimeInMinutes = (datepart(n, @dtTotalTime) + (datepart(hh, @dtTotalTime) * 60)) 
						- SUM(datepart(n, TOTALTIME) + (datepart(hh, TOTALTIME) * 60)),
					  @nTotalUnits = @nTotalUnits - SUM(TOTALUNITS),
					  @nLocalCost = @nLocalCost - SUM(LOCALCOST),
					  @nForeignCost = @nForeignCost - SUM(FOREIGNCOST),
					  @nCostCalculation1 = @nCostCalculation1 - SUM(COSTCALCULATION1),
					  @nCostCalculation2 = @nCostCalculation2 - SUM(COSTCALCULATION2)
					From WORKINPROGRESS
					where ENTITYNO = @pnEntityKey 
					and TRANSNO = @pnAppendToTransKey
					group by ENTITYNO, TRANSNO'

		Exec @nErrorCode=sp_executesql @sSQLString, 
					N'@nTotalUnits		int		output,
					  @nTimeInMinutes	int		output,
					  @nLocalCost		decimal(11,2)	output,
					  @nForeignCost		decimal(11,2)	output,
					  @nCostCalculation1	decimal(11,2)	output,
					  @nCostCalculation2	decimal(11,2)	output,
					  @dtTotalTime		datetime,				  
					  @pnEntityKey		int,
					  @pnAppendToTransKey	int',
					  @nTotalUnits		= @nTotalUnits	output,
					  @nTimeInMinutes	= @nTimeInMinutes output,
					  @nLocalCost		= @nLocalCost output,
					  @nForeignCost		= @nForeignCost output,
					  @nCostCalculation1	= @nCostCalculation1 output,
					  @nCostCalculation2	= @nCostCalculation2 output,
					  @dtTotalTime		= @dtTotalTime,
					  @pnEntityKey		= @pnEntityKey,
					  @pnAppendToTransKey	= @pnAppendToTransKey
	End
	Else 
	Begin
		-- Proportion these values to the split amount.
		Set @nLocalCost = @nLocalCost * (@pnLocalSplit / @nLocalValue)
		Set @nForeignCost = @nForeignCost * (@pnForeignSplit / @nForeignValue)
		Set @nCostCalculation1 = @nCostCalculation1 * (@pnLocalSplit / @nLocalValue)
		Set @nCostCalculation2 = @nCostCalculation2 * (@pnLocalSplit / @nLocalValue)

		Select @nTimeInMinutes = round((datepart(n, @dtTotalTime) + (datepart(hh, @dtTotalTime) * 60))
					* (@pnLocalSplit / @nLocalValue),0)

		-- The proportioned unit allocation can round up and over-allocate in some instances. Check that we don't over-allocate.
		Declare @nTotalAllocatedUnits int
		Set @nTotalAllocatedUnits = 0
		If (@pnAppendToTransKey is not null)
		Begin
			select @nTotalAllocatedUnits = SUM(TOTALUNITS)
			From WORKINPROGRESS
			where ENTITYNO = @pnEntityKey
			and TRANSNO = @pnAppendToTransKey
			group by ENTITYNO, TRANSNO
		End
		
		Declare @nProportionedUnits int
		Set @nProportionedUnits = Round(@nTotalUnits * (@pnLocalSplit / @nLocalValue), 0)
		
		if (@nTotalAllocatedUnits + @nProportionedUnits) <= @nTotalUnits
			Set @nTotalUnits = @nProportionedUnits
		Else
			Set @nTotalUnits = @nTotalUnits - @nTotalAllocatedUnits
	End

	Set @dtTotalTime = dateadd(minute, @nTimeInMinutes, 0)
End

If @nErrorCode = 0 and @bIsSplitMultiDebtor = 1
Begin
	Set @sSQLString = "Select @bIsMultiDebtorCase = CASE WHEN count(NAMENO) > 1 THEN 1 ELSE 0 END 
			from CASENAME 
			Where CASEID = @nWIPToCaseId
			AND NAMETYPE = 'D'"

	Exec @nErrorCode=sp_executesql @sSQLString, 
			N'@bIsMultiDebtorCase	bit			output,
			  @nWIPToCaseId		int',
			  @bIsMultiDebtorCase	= @bIsMultiDebtorCase	output,
			  @nWIPToCaseId		= @nWIPToCaseId
End

If (@nErrorCode = 0)
Begin
	Set @bIsSplitWip = CASE WHEN @nWIPToCaseId = @nOriginalCaseKey and ISNULL(@bIsMultiDebtorCase,0) = 1 THEN @bIsSplitMultiDebtor ELSE 0 END

	exec dbo.wp_PostWIP
		@pnUserIdentityId	= @pnUserIdentityId,		-- Mandatory
		@psCulture		= @psCulture,
		@pbCalledFromCentura	= @pbCalledFromCentura,
		@pnEntityKey		= @pnEntityKey,		        -- Mandatory	   Entity WIP is recorded against
		@pdtTransDate		= @dtTransDate,	                -- Mandatory	   Date of transaction
		@pnTransactionType	= @nTransactionType,		-- Default to WIP recording
		@pnWIPToNameNo		= @nWIPToNameNo,		-- Mandatory	
		@pnWIPToCaseId		= @nWIPToCaseId,		-- For WIP recorded against Case, if null then WIP is recorded against Name
		@pnEmployeeNo		= @pnStaffKey,		        -- Staff member recorded with WIP
		@pnAssociateNo		= @nAssociateNo,		-- NameNo of Associate who generated charge being disbursed
		
		@psInvoiceNumber	= @sInvoiceNumber,		-- Incoming invoice number being disbursed
		@psVerificationNumber	= @sVerificationNumber,
		@pnRateNo		= @nRateNo,		        -- The RateNo for WIP generated by a rate calculation
		@psWIPCode		= @sWIPCode,	                -- Mandatory	
		@pdtTotalTime		= @dtTotalTime,		        -- Time used in calculation of WIP
		@pnTotalUnits		= @nTotalUnits,		        -- Time as units used in calculation of WIP
		@pnUnitsPerHour		= @nUnitsPerHour,		-- Number of units that fit into one hour
		@pnChargeOutRate	= @nChargeOutRate,		-- Charge out rate for time based charges
		@pnLocalValue		= @pnLocalSplit,	        -- Mandatory	-- Value of WIP
		@pnForeignValue		= @pnForeignSplit,		-- Value of WIP in foreign currency
		
		@psForeignCurrency	= @sForeignCurrency,		-- Currency of Foreign Value
		@pnExchangeRate		= @nExchangeRate,		-- Exchange rate between home currency and Foreign Currency
		@pnDiscountValue	= null,		                -- Calculated discount in local currency as positive number	
		@pnForeignDiscount	= null,		                -- Calculated discount in foreign currency as positive number
		@pnVariableFeeAmt	= null,		                -- Amount recorded as the variable fee
		@pnVariableFeeType	= null,
		@psVariableCurrency	= null,		                -- Currency of variable fee
		@pnFeeCriteriaNo	= null,		                -- Criteria used to calculate fee
		@pnFeeUniqueId		= null,		                -- Identifies Fee Calculation row used in calculation
		@pnQuotationNo		= @nQuotationNo,
		
		@pnLocalCost		= @nLocalCost,		        -- Cost value of WIP raised in local currency
		@pnForeignCost		= @nForeignCost,		-- Cost value of WIP raised in foreign currency
		@pnCostCalculation1	= @nCostCalculation1,		-- Cost of WIP using cost rate 1 method
		@pnCostCalculation2	= @nCostCalculation2,		-- Cost of WUP using cost rate 2 method
		@pnEnteredQuantity	= null,
		@pnProductCode		= @nProductCode,
		@pbGeneratedInAdvance	= @bGeneratedInAdvance,
		@pnNarrativeNo		= @nNarrativeNo,		-- Pointer to saved narrative
		@psNarrative		= @sNarrative,		        -- Free format text to be saved with WIP
 		@psFeeType		= null,		                -- Indicates the type of IP Office fee being paid
		
		@pnBaseFeeAmount	=0,		                -- Base fee being paid
		@pnAdditionalFee	=0,		                -- Component of fee calculated from @pnQuantityInCalc
		@psFeeTaxCode		=null,		                -- Tax code associated with Fee.
		@pnFeeTaxAmount		=0,		                -- Tax amount of the Fee
 		@pnAgeOfCase		= null,		                -- The annuity number of Case being paid for inclusion on Fee List
		@pnMarginNo		= null,		                -- The margin identity for the applied Margin
		@pnDebugFlag		= 0,		                --0=off,1=trace execution,2=dump data
		@pbDraftWIP		= 0,		                --0=process normal WIP 1=process draft WIP from billing
		@pnItemTransNo		= @pnAppendToTransKey,		-- Item TransNo of the open item for draft WIP.
		@bIsCreditWIP		= 0,
		@pbSeparateMarginFlag	= 0,	                        -- Margin to be stored as seperate WIP Item
		@pnLocalMargin		= null,	                        -- Margin amount
		@pnForeignMargin	= null,	                        -- Forign Margin Amount
		@pnDiscountForMargin	= null,	                        -- Calculated discount for margin in local currency as positive number	
		@pnForeignDiscountForMargin	= null,	                -- Calculated discount for margin in foreign
		@psReasonCode           = @psReasonCode,
		@pbReturnWIPKey		= 1,                            -- Return WIP Key to the caller
		@psProfitCentreCode	= @sProfitCentreCode,	        -- Profit center used for WIP
		@pbIsSplitWip           = @bIsSplitWip,  
		@pnSplitPercentage      = @pnSplitPercentage,
		@pbSuppressPostToGL	= 1,				-- RFC74733: Posting to GL for the last wip item is handled by this SP	        
		@pnNewTransKey		= @pnAppendToTransKey		output, -- the trans no for the inserted wip item
		@pnNewWipSeqKey		= @pnNewWipSeqKey		output -- the seq no of the inserted wip item
		

		Select @nErrorCode = @@ERROR
End

-- once the split is complete, write down the old wip by the total split amount.
If (@nErrorCode = 0 and @pbAdjustOriginalWIP = 1)
Begin
	if (@pnAppendToTransKey is null)
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('AC141', 'An error has occured attempting to insert the Split WIP transaction.',
						NULL, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR
	End
	
	Declare @nTotalLocal decimal(12,2)
	Declare @nTotalForeign decimal(12,2)
	Declare @nTotalLocalCost decimal(12,2)
	Declare @nTotalForeignCost decimal(12,2)
	Declare @nControlTotal decimal(12,2)
	Declare @nPostPeriod	int
	Declare @dtPostDate	datetime
	Declare @nGLJournalCreation	int
	Declare @nResult int
	Declare @nMovementClass int
	Declare @nCommandId int	
	
	If @nErrorCode = 0
	begin
		Set @sSQLString = 'Select @nPostPeriod = TRANPOSTPERIOD,
			@dtPostDate = TRANPOSTDATE
			FROM TRANSACTIONHEADER
			WHERE ENTITYNO = @pnEntityKey
			AND TRANSNO = @pnAppendToTransKey'
			
		Exec @nErrorCode=sp_executesql @sSQLString, 
					N'@nPostPeriod		int output,
					  @dtPostDate		datetime output,
					  @pnEntityKey		int,
					  @pnAppendToTransKey	int',
					  @nPostPeriod		= @nPostPeriod output,
					  @dtPostDate		= @dtPostDate output,
					  @pnEntityKey		= @pnEntityKey,
					  @pnAppendToTransKey	= @pnAppendToTransKey
	End

	If @nErrorCode = 0
	begin
		Set @sSQLString = 'select 
			@nTotalLocal = sum(ISNULL(LOCALVALUE,0)) * -1,
			@nTotalForeign = sum(ISNULL(FOREIGNVALUE,0)) * -1,
			@nTotalLocalCost = sum(ISNULL(LOCALCOST,0)) * -1,
			@nTotalForeignCost = sum(ISNULL(FOREIGNCOST,0)) * -1
			FROM WORKINPROGRESS
			WHERE ENTITYNO = @pnEntityKey
			AND TRANSNO = @pnAppendToTransKey
			GROUP BY ENTITYNO, TRANSNO'
		
		Exec @nErrorCode=sp_executesql @sSQLString, 
					N'@nTotalLocal		decimal(12,2) output,
					  @nTotalForeign	decimal(12,2) output,
					  @nTotalLocalCost	decimal(12,2) output,
					  @nTotalForeignCost	decimal(12,2) output,
					  @pnEntityKey		int,
					  @pnAppendToTransKey	int',
					  @nTotalLocal		= @nTotalLocal output,
					  @nTotalForeign	= @nTotalForeign output,
					  @nTotalLocalCost	= @nTotalLocalCost output,
					  @nTotalForeignCost	= @nTotalForeignCost output,
					  @pnEntityKey		= @pnEntityKey,
					  @pnAppendToTransKey	= @pnAppendToTransKey
	End	
	
	if @nTotalLocal > 0
	Begin
		Set @nMovementClass = 4
		Set @nCommandId = 5
	End
	else
	Begin
		Set @nMovementClass = 5
		Set @nCommandId = 6
	End

	-- Write down the old WIP.
	If @nErrorCode = 0
	Begin
		Set @sSQLString = 'UPDATE WORKINPROGRESS
		SET	BALANCE = BALANCE + @nTotalLocal,
			FOREIGNBALANCE = FOREIGNBALANCE + @nTotalForeign
		WHERE ENTITYNO = @pnEntityKey
		and TRANSNO = @pnTransKey
		and WIPSEQNO = @pnWIPSeqKey'

		Exec @nErrorCode=sp_executesql @sSQLString, 
					N'@nTotalLocal	decimal(12,2),
					@nTotalForeign	decimal(12,2),
					@pnEntityKey	int,
					@pnTransKey	int,
					@pnWIPSeqKey	int',
					@nTotalLocal	= @nTotalLocal,
					@nTotalForeign	= @nTotalForeign,
					@pnEntityKey	= @pnEntityKey,
					@pnTransKey	= @pnTransKey,
					@pnWIPSeqKey	= @pnWIPSeqKey
	End
				
	-- Get the next history line number for the work history row
	If @nErrorCode = 0
	Begin
		Set @sSQLString = 'Select @nHistoryLineNo = max(HISTORYLINENO) + 1
			from WORKHISTORY
			WHERE ENTITYNO = @pnEntityKey
			and TRANSNO = @pnTransKey
			and WIPSEQNO = @pnWIPSeqKey'
			
		Exec @nErrorCode=sp_executesql @sSQLString, 
					N'@nHistoryLineNo int OUTPUT,
					@pnEntityKey	int,
					@pnTransKey	int,
					@pnWIPSeqKey	int',
					@nHistoryLineNo	= @nHistoryLineNo OUTPUT,
					@pnEntityKey	= @pnEntityKey,
					@pnTransKey	= @pnTransKey,
					@pnWIPSeqKey	= @pnWIPSeqKey
	End
	
	-- Adjust Down the original item
	If @nErrorCode = 0
	Begin
		Set @sSQLString = 'Insert into WORKHISTORY
			(ENTITYNO, TRANSNO, WIPSEQNO, HISTORYLINENO, 
			TRANSDATE, POSTDATE, TRANSTYPE, POSTPERIOD,
			RATENO, WIPCODE, CASEID, 
			ACCTENTITYNO, ACCTCLIENTNO, EMPLOYEENO, ASSOCIATENO, INVOICENUMBER,  
			TOTALTIME, TOTALUNITS, UNITSPERHOUR, 
			CHARGEOUTRATE, FOREIGNCURRENCY, FOREIGNTRANVALUE, 
			EXCHRATE, LOCALTRANSVALUE, COSTCALCULATION1, 
			COSTCALCULATION2, MARGINNO, REFENTITYNO, REFTRANSNO, 
			EMPPROFITCENTRE, EMPFAMILYNO, EMPOFFICECODE, 
			NARRATIVENO, SHORTNARRATIVE, LONGNARRATIVE, 
			STATUS, QUOTATIONNO, PRODUCTCODE,
			DISCOUNTFLAG, GENERATEDINADVANCE,
			VARIABLEFEEAMT,VARIABLEFEETYPE,VARIABLEFEECURR,
			FEECRITERIANO,FEEUNIQUEID,LOCALCOST,FOREIGNCOST,
			ENTEREDQUANTITY,VERIFICATIONNUMBER,
			MOVEMENTCLASS, COMMANDID, ITEMIMPACT, MARGINFLAG, REASONCODE )
			
			select 	W.ENTITYNO,
			W.TRANSNO, 
			W.WIPSEQNO,
			@nHistoryLineNo	as HistoryLineNo,
			W.TRANSDATE,
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
			W.TOTALTIME,
			W.TOTALUNITS,
			W.UNITSPERHOUR,
			W.CHARGEOUTRATE,
			W.FOREIGNCURRENCY,
			CASE WHEN W.FOREIGNCURRENCY IS NOT NULL THEN @nTotalForeign ELSE NULL END,
			W.EXCHRATE,
			@nTotalLocal,
			W.COSTCALCULATION1 * -1,
			W.COSTCALCULATION2 * -1,
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
			W.DISCOUNTFLAG,
			W.GENERATEDINADVANCE,
			W.VARIABLEFEEAMT,
			W.VARIABLEFEETYPE,
			W.VARIABLEFEECURR,
			W.FEECRITERIANO,
			W.FEEUNIQUEID,
			@nTotalLocalCost,
			@nTotalForeignCost,
			ENTEREDQUANTITY,
			W.VERIFICATIONNUMBER,
			@nMovementClass,
			@nCommandId,
			NULL, -- ITEM IMPACT
			W.MARGINFLAG,
			@psReasonCode
			from TRANSACTIONHEADER T, WORKINPROGRESS W
			where	T.TRANSNO  = @pnAppendToTransKey
			and	T.ENTITYNO = @pnEntityKey
			and	W.ENTITYNO = @pnEntityKey
			and	W.TRANSNO = @pnTransKey
			and	W.WIPSEQNO = @pnWIPSeqKey'
					
		Exec @nErrorCode=sp_executesql @sSQLString, 
					N'@nHistoryLineNo	int,
					@nTotalForeign		decimal(12,2),
					@nTotalLocal		decimal(12,2),
					@nTotalLocalCost	decimal(12,2),
					@nTotalForeignCost	decimal(12,2),
					@psReasonCode		nvarchar(2),
					@pnAppendToTransKey	int,
					@pnEntityKey		int,
					@pnTransKey			int,
					@pnWIPSeqKey		int,
					@nMovementClass		int,
					@nCommandId			int',
					@nHistoryLineNo		= @nHistoryLineNo,
					@nTotalForeign		= @nTotalForeign,
					@nTotalLocal		= @nTotalLocal,
					@nTotalLocalCost	= @nTotalLocalCost,
					@nTotalForeignCost	= @nTotalForeignCost,
					@psReasonCode		= @psReasonCode,
					@pnAppendToTransKey	= @pnAppendToTransKey,
					@pnEntityKey		= @pnEntityKey,
					@pnTransKey			= @pnTransKey,
					@pnWIPSeqKey		= @pnWIPSeqKey,
					@nMovementClass		= @nMovementClass,
					@nCommandId			= @nCommandId
					
	End		

	-- delete used wip
	If @nErrorCode = 0
	Begin
		Set @sSQLString = 'DELETE WORKINPROGRESS
			WHERE ENTITYNO = @pnEntityKey
			and TRANSNO = @pnTransKey
			and WIPSEQNO = @pnWIPSeqKey
			and (BALANCE = 0 or BALANCE is null)'
			
		Exec @nErrorCode=sp_executesql @sSQLString, 
					N'@pnEntityKey		int,
					@pnTransKey		int,
					@pnWIPSeqKey		int',
					@pnEntityKey		= @pnEntityKey,
					@pnTransKey		= @pnTransKey,
					@pnWIPSeqKey		= @pnWIPSeqKey	

		select @delRowCount = @@ROWCOUNT
	End

	If @nErrorCode = 0 and @delRowCount = 0
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('AC213', 'Could not save split. The original WIP item value was not fully allocated.',
							NULL, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR
	End

        If @nErrorCode = 0
	Begin
		-- Adjust WorkHistory Trans. Date
		-- Adjust Workhistory WIP adjustment details
		UPDATE W
		SET 
		MOVEMENTCLASS = case when LOCALTRANSVALUE > 0 then 4 else 5 end,
		COMMANDID = case when LOCALTRANSVALUE > 0 then 9 else 10 end,
		DISCOUNTFLAG = @bIsDiscount
		from WORKHISTORY W
		left join EMPLOYEE E on (E.EMPLOYEENO = W.EMPLOYEENO)
		WHERE ENTITYNO = @pnEntityKey
		and	TRANSNO = @pnAppendToTransKey
		and	WIPSEQNO = @pnWIPSeqKey
	End
		
	-- Calculate the total of the adjustment
	If @nErrorCode = 0
	Begin
		-- Insert Control Total for the Adjust Down Work History.
		Set @sSQLString = "select @nControlTotal = sum(ISNULL(LOCALTRANSVALUE,0))
					FROM WORKHISTORY
					WHERE REFENTITYNO = @pnEntityKey
					AND REFTRANSNO = @pnAppendToTransKey
					AND MOVEMENTCLASS = @nMovementClass"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnEntityKey	int,
				  @pnAppendToTransKey	int,
				  @nMovementClass int,
				  @nControlTotal	decimal(12,2) OUTPUT',
				  @pnEntityKey = @pnEntityKey,
				  @pnAppendToTransKey = @pnAppendToTransKey,
				  @nMovementClass = @nMovementClass,
				  @nControlTotal = @nControlTotal OUTPUT
	End

	If @nErrorCode = 0
	Begin
		-- Call this procedure to insert/update as appropriate
		exec @nErrorCode = dbo.acw_UpdateControlTotal
			@pnUserIdentityId = @pnUserIdentityId,
			@psCulture	= @psCulture,
			@pbCalledFromCentura = @pbCalledFromCentura,
			@pnLedger	= 1,
			@pnCategory	= @nMovementClass,
			@pnType	= @nTransactionType,
			@pnPeriodId	= @nPostPeriod,
			@pnEntityNo	= @pnEntityKey,
			@pnAmountToAdd	= @nControlTotal
	End
	
	-- Execute the GL processing for the Split if necessary
	If (@nErrorCode = 0)
	Begin
		Set @sSQLString = "
			Select @nGLJournalCreation = isnull(COLINTEGER,0)
			From SITECONTROL
			Where CONTROLID = 'GL Journal Creation'"

		exec	@nErrorCode = sp_executesql @sSQLString,
						N'@nGLJournalCreation	int 			OUTPUT',
						@nGLJournalCreation = @nGLJournalCreation	OUTPUT
	End

	If (@nErrorCode = 0 and @nGLJournalCreation = 1)
	Begin			
		exec @nErrorCode = dbo.fi_CreateAndPostJournals
		  @pnResult = @nResult OUTPUT,
		  @pnUserIdentityId = @pnUserIdentityId,
		  @psCulture = @psCulture,
		  @pbCalledFromCentura = @pbCalledFromCentura,
		  @pnEntityNo = @pnEntityKey,
		  @pnTransNo = @pnAppendToTransKey,
		  @pnDesignation = 1,
		  @pbIncProcessedNoJournal = 1
	End
End

RETURN @nErrorCode
go

grant execute on dbo.wpw_SplitWIP  to public
go