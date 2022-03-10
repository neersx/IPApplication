-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ts_UpdateDiary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ts_UpdateDiary.'
	Drop procedure [dbo].[ts_UpdateDiary]
End
Print '**** Creating Stored Procedure dbo.ts_UpdateDiary...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.ts_UpdateDiary
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnStaffKey		int,		-- Mandatory		
	@pnEntryNo		int,		-- Mandatory
	@pdtStartDateTime	datetime	= null,
	@pdtFinishDateTime	datetime	= null,
	@pnNameKey		int		= null,
	@pnCaseKey		int		= null,
	@psActivityKey		nvarchar(6)	= null,
	@pnElapsedMinutes	int		= null,
	@pnTotalUnits		smallint	= null,
	@pnUnitsPerHour		smallint	= null,
	@pnChargeOutRate	decimal(10,2)	= null,
	@pnLocalValue		decimal(10,2)	= null,
	@pnLocalDiscount	decimal(10,2)	= null,
	@pnCostCalculation1	decimal(11,2)	= null,
	@pnCostCalculation2	decimal(11,2)	= null,
	@psForeignCurrencyCode	nvarchar(3)	= null,
	@pnExchangeRate		decimal(11,4)	= null,
	@pnForeignValue		decimal(11,2)	= null,
	@pnForeignDiscount	decimal(11,2)	= null,
	@pnMinutesCarriedForward int		= null,
	@pnParentEntryNo	int		= null,
	@pnNarrativeKey		smallint	= null,
	@ptNarrative		ntext		= null,
	@psNotes		nvarchar(254)	= null,
	@pnProductKey		int		= null,
	@pnEntityNo		int		= null,
	@pnTransNo		int		= null,
	@pnWipSeqNo		smallint	= null,
	@pnIsTimer		decimal(1,0)	= null,
	@pnMarginNo		int		= null,
	@pdtOldStartDateTime	datetime	= null,
	@pdtOldFinishDateTime	datetime	= null,
	@pnOldNameKey		int		= null,
	@pnOldCaseKey		int		= null,
	@psOldActivityKey	nvarchar(6)	= null,
	@pnOldElapsedMinutes	int		= null,
	@pnOldTotalUnits	smallint	= null,
	@pnOldUnitsPerHour	smallint	= null,
	@pnOldChargeOutRate	decimal(10,2)	= null,
	@pnOldLocalValue	decimal(10,2)	= null,
	@pnOldLocalDiscount	decimal(10,2)	= null,
	@pnOldCostCalculation1	decimal(11,2)	= null,
	@pnOldCostCalculation2	decimal(11,2)	= null,
	@psOldForeignCurrencyCode nvarchar(3)	= null,
	@pnOldExchangeRate	decimal(11,4)	= null,
	@pnOldForeignValue	decimal(11,2)	= null,
	@pnOldForeignDiscount	decimal(11,2)	= null,
	@pnOldMinutesCarriedForward int		= null,
	@pnOldParentEntryNo	int		= null,
	@pnOldNarrativeKey	smallint	= null,
	@ptOldNarrative		ntext		= null,
	@psOldNotes		nvarchar(254)	= null,
	@pnOldProductKey	int		= null,
	@pnOldEntityNo		int		= null,
	@pnOldTransNo		int		= null,
	@pnOldWipSeqNo		smallint	= null,
	@pnOldIsTimer		decimal(1,0)	= null,
	@pnOldMarginNo		int		= null
)
-- PROCEDURE:	ts_UpdateDiary
-- VERSION:	7
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION: Update a Timesheet Entry if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 14 Mar 2005  TM	RFC2379	1	Procedure created. 
-- 21 Jun 2005	TM	RFC1100	2	Rename TimesheetData to TimeEntryData. Remove DaySummary datatable. Implement  
--					new IsTimer column. Change TotalTime to ElapsedMinutes, TimeCarriedForward to
--					MinutesCarriedForward. Add processing for continued entries.
-- 23 Jun 2005	TM	RFC1100	3	Give an error if the row has been continued by a timer.
-- 23 Dec 2005	TM	RFC3354	4	Store short Narrative in local variable.
-- 30 Oct 2006	LP	RFC4592	5	Update Date component of StartTime and FinishTime for contributing entries in
--					a continued chain
-- 25 Mar 2009	MS	RFC7130	6	Add new parameter MarginNo and set it in the DIARY table.
-- 20 Oct 2015  MS      R53933  7       Changed size from decimal(8,4) to decimal(11,4) for rate cols

AS

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON


Declare @nErrorCode			int
Declare @sSQLString			nvarchar(4000)
Declare @sAlertXML 			nvarchar(400)
Declare @bIsTimerContinued		bit
Declare @bLongFlag			bit
Declare @bOldLongFlag			bit
Declare @nEntryNo			int
Declare @sShortNarrative		nvarchar(254)
Declare @sOldShortNarrative		nvarchar(254)

Declare @dtTotalTime			datetime
Declare	@dtTimeCarriedForward		datetime
Declare @dtOldTotalTime			datetime
Declare	@dtOldTimeCarriedForward 	datetime
Declare @dtEntryDate			datetime

-- Initialise variables
Set @nErrorCode 	= 0

If @nErrorCode = 0
Begin
	-- Is the row continued by a timer?
	Set @sSQLString = "
	Select @bIsTimerContinued = 1
	from   DIARY
	where  EMPLOYEENO = @pnStaffKey
	and    PARENTENTRYNO = @pnEntryNo"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@bIsTimerContinued	bit			OUTPUT,
					  @pnStaffKey		int,
					  @pnEntryNo		int',
					  @bIsTimerContinued	= @bIsTimerContinued	OUTPUT,
					  @pnStaffKey		= @pnStaffKey,
					  @pnEntryNo		= @pnEntryNo

	-- Give an error if the row is continued by a timer:
	If @nErrorCode = 0 
	and @bIsTimerContinued = 1
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('AC11', 'This entry cannot be modified because it has been continued. Please check your timers.',
			null, null, null, null, null)
		RAISERROR(@sAlertXML, 12, 1)
		Set @nErrorCode = @@ERROR
	End
End

-- Is the Narrative long text?
If (datalength(@ptNarrative) <= 508)
or datalength(@ptNarrative) is null
Begin
	Set @bLongFlag = 0
	Set @sShortNarrative = CAST(@ptNarrative as nvarchar(254))
End
Else
Begin
	Set @bLongFlag = 1
End

-- Is the old Narrative long text?
If (datalength(@ptOldNarrative) <= 508)
or datalength(@ptOldNarrative) is null
Begin
	Set @bOldLongFlag = 0
	Set @sOldShortNarrative = CAST(@ptOldNarrative as nvarchar(254))
End
Else
Begin
	Set @bOldLongFlag = 1
End

-- Convert @pnElapsedMinutes and @pnMinutesCarriedForward and their old values to the datetime datatype:
If @nErrorCode = 0
Begin
	If @pnElapsedMinutes is not null
	Begin
		Set @dtTotalTime = convert(datetime, '1899-01-01 ' + cast(@pnElapsedMinutes/60 as varchar(10)) + ':' + cast(@pnElapsedMinutes%60 as varchar(10)), 120)
	End

	If @pnMinutesCarriedForward is not null
	Begin
		Set @dtTimeCarriedForward = convert(datetime, '1899-01-01 ' + cast(@pnMinutesCarriedForward/60 as varchar(10)) + ':' + cast(@pnMinutesCarriedForward%60 as varchar(10)), 120)
	End

	If @pnOldElapsedMinutes is not null
	Begin
		Set @dtOldTotalTime = convert(datetime, '1899-01-01 ' + cast(@pnOldElapsedMinutes/60 as varchar(10)) + ':' + cast(@pnOldElapsedMinutes%60 as varchar(10)), 120)
	End

	If @pnOldMinutesCarriedForward is not null
	Begin
		Set @dtOldTimeCarriedForward = convert(datetime, '1899-01-01 ' + cast(@pnOldMinutesCarriedForward/60 as varchar(10)) + ':' + cast(@pnOldMinutesCarriedForward%60 as varchar(10)), 120)
	End
End

-- Update continued chain if this row is part of the chain:
If  @nErrorCode = 0
and @pnParentEntryNo is not null
Begin
	-- Reset previous final row if finalising a timer. Clear any data 
	-- that should only be populated for the final row in the chain.
	If @nErrorCode = 0
	and @pnOldIsTimer = 1
	Begin
		Set @sSQLString = "
		Update DIARY 
		Set     TOTALTIME		= NULL,
			TIMEVALUE		= NULL,
			DISCOUNTVALUE		= NULL,
			TOTALUNITS		= NULL,
			FOREIGNCURRENCY		= NULL,
			EXCHRATE		= NULL,
			FOREIGNVALUE		= NULL,
			FOREIGNDISCOUNT		= NULL,
			TIMECARRIEDFORWARD	= NULL,
			COSTCALCULATION1	= NULL,
			COSTCALCULATION2	= NULL,
			MARGINNO		= NULL
		where   EMPLOYEENO 		= @pnStaffKey
		and     ENTRYNO 		= @pnParentEntryNo"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnStaffKey		int,
						  @pnParentEntryNo	int',
						  @pnStaffKey		= @pnStaffKey,
						  @pnParentEntryNo	= @pnParentEntryNo
	End
	
	-- Ensure basic details are the same for the chain
	If @nErrorCode = 0
	and (@pnNameKey		<> @pnOldNameKey
	 or  @pnCaseKey		<> @pnOldCaseKey
	 or  @psActivityKey	<> @psOldActivityKey
	 or  @pnNarrativeKey	<> @pnOldNarrativeKey
	 or  @pnProductKey	<> @pnOldProductKey
	 or  DATEDIFF(day,@pdtStartDateTime,@pdtOldStartDateTime)<> 0
	 or  DATEDIFF(day,@pdtFinishDateTime,@pdtOldFinishDateTime)<> 0
	 or  dbo.fn_IsNtextEqual(@ptNarrative, @ptOldNarrative) <> 1)
	Begin
		Set @dtEntryDate = dbo.fn_DateOnly(@pdtStartDateTime)

		exec @nErrorCode=dbo.ts_UpdateContinuedChain		
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@pnStaffKey		= @pnStaffKey,
			@pnStartEntryNo		= @pnParentEntryNo,
			@pnNameKey		= @pnNameKey,
			@pnCaseKey		= @pnCaseKey,
			@psActivityKey		= @psActivityKey,
			@pnNarrativeKey		= @pnNarrativeKey,
			@ptNarrative		= @ptNarrative,
			@pnProductKey		= @pnProductKey,
			@pdtEntryDate		= @dtEntryDate
	End			
End

-- Clear Timer
If @nErrorCode = 0
Begin	
	Set @pnIsTimer = 0
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "	
	Update  DIARY 
	Set	ACTIVITY	= @psActivityKey,
		CASEID		= @pnCaseKey,
		NAMENO		= CASE WHEN @pnCaseKey is null THEN @pnNameKey ELSE NULL END,
		STARTTIME	= @pdtStartDateTime,
		FINISHTIME	= @pdtFinishDateTime,
		TOTALTIME	= @dtTotalTime,
		TOTALUNITS	= @pnTotalUnits,
		TIMECARRIEDFORWARD = @dtTimeCarriedForward,
		UNITSPERHOUR	= @pnUnitsPerHour,
		TIMEVALUE	= @pnLocalValue,
		CHARGEOUTRATE	= @pnChargeOutRate,
		NOTES		= @psNotes,
		NARRATIVENO	= @pnNarrativeKey,
		SHORTNARRATIVE	= CASE WHEN @bLongFlag = 1 THEN NULL ELSE @sShortNarrative END,
		LONGNARRATIVE	= CASE WHEN @bLongFlag = 1 THEN @ptNarrative ELSE NULL END,
		DISCOUNTVALUE	= @pnLocalDiscount,
		FOREIGNCURRENCY = @psForeignCurrencyCode,
		FOREIGNVALUE	= @pnForeignValue,
		EXCHRATE	= @pnExchangeRate,
		FOREIGNDISCOUNT	= @pnForeignDiscount,
		PARENTENTRYNO	= @pnParentEntryNo,
		COSTCALCULATION1= @pnCostCalculation1,
		COSTCALCULATION2= @pnCostCalculation2,
		PRODUCTCODE	= @pnProductKey,
		WIPENTITYNO	= @pnEntityNo,
		TRANSNO		= @pnTransNo,
		WIPSEQNO	= @pnWipSeqNo,
		ISTIMER		= @pnIsTimer,
		MARGINNO	= @pnMarginNo
	where   EMPLOYEENO	= @pnStaffKey
	and     ENTRYNO		= @pnEntryNo		
	and 	ACTIVITY	= @psOldActivityKey
	and	CASEID		= @pnOldCaseKey
	and	NAMENO		= @pnOldNameKey
	and	STARTTIME	= @pdtOldStartDateTime
	and	FINISHTIME	= @pdtOldFinishDateTime
	and	TOTALTIME	= @dtOldTotalTime
	and	TOTALUNITS	= @pnOldTotalUnits
	and	TIMECARRIEDFORWARD = @dtOldTimeCarriedForward
	and	UNITSPERHOUR	= @pnOldUnitsPerHour
	and	TIMEVALUE	= @pnOldLocalValue
	and	CHARGEOUTRATE	= @pnOldChargeOutRate
	and	NOTES		= @psOldNotes
	and	NARRATIVENO	= @pnOldNarrativeKey
	and	DISCOUNTVALUE	= @pnOldLocalDiscount
	and	FOREIGNCURRENCY = @psOldForeignCurrencyCode
	and	FOREIGNVALUE	= @pnOldForeignValue
	and	EXCHRATE	= @pnOldExchangeRate
	and	FOREIGNDISCOUNT	= @pnOldForeignDiscount
	and	PARENTENTRYNO	= @pnOldParentEntryNo
	and	COSTCALCULATION1= @pnOldCostCalculation1
	and	COSTCALCULATION2= @pnOldCostCalculation2
	and	PRODUCTCODE	= @pnOldProductKey
	and	WIPENTITYNO	= @pnOldEntityNo
	and 	TRANSNO		= @pnOldTransNo
	and	WIPSEQNO	= @pnOldWipSeqNo
	and	ISTIMER		= @pnOldIsTimer
	and	MARGINNO	= @pnOldMarginNo"

	If @bOldLongFlag = 1
	Begin
		-- Use the fn_IsNtextEqual() function to compare ntext strings
		Set @sSQLString = @sSQLString + char(10) + "
		and dbo.fn_IsNtextEqual(LONGNARRATIVE, @ptOldNarrative) = 1"
	End
	Else Begin
		Set @sSQLString = @sSQLString + char(10) + "
		and SHORTNARRATIVE = @sOldShortNarrative"
	End	

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnStaffKey		int,
					  @pnEntryNo		int,
					  @psActivityKey	nvarchar(6),
					  @pnCaseKey		int,
					  @pnNameKey		int,
					  @pdtStartDateTime	datetime,
					  @pdtFinishDateTime	datetime,
					  @dtTotalTime		datetime,
					  @pnTotalUnits		smallint,
					  @dtTimeCarriedForward datetime,
					  @pnUnitsPerHour	smallint,
					  @pnLocalValue		decimal(10,2),
					  @pnChargeOutRate	decimal(10,2),
					  @psNotes		nvarchar(254),
					  @bLongFlag		bit,
					  @pnNarrativeKey	smallint,
					  @ptNarrative		ntext,
					  @sShortNarrative	nvarchar(254),
					  @pnLocalDiscount	decimal(10,2),
					  @psForeignCurrencyCode nvarchar(3),
					  @pnForeignValue	decimal(11,2),
					  @pnExchangeRate	decimal(11,4),
					  @pnForeignDiscount	decimal(11,2),
					  @pnParentEntryNo	int,
					  @pnCostCalculation1	decimal(11,2),
					  @pnCostCalculation2	decimal(11,2),
					  @pnProductKey		int,
					  @pnEntityNo		int,
					  @pnTransNo 		int,
					  @pnWipSeqNo		smallint, 
					  @pnIsTimer		decimal(1,0),
					  @pnMarginNo		int,
					  @psOldActivityKey	nvarchar(6),
					  @pnOldCaseKey		int,
					  @pnOldNameKey		int,
					  @pdtOldStartDateTime	datetime,
					  @pdtOldFinishDateTime	datetime,
					  @dtOldTotalTime	datetime,
					  @pnOldTotalUnits	smallint,
					  @dtOldTimeCarriedForward datetime,
					  @pnOldUnitsPerHour	smallint,
					  @pnOldLocalValue	decimal(10,2),
					  @pnOldChargeOutRate	decimal(10,2),
					  @psOldNotes		nvarchar(254),
					  @pnOldNarrativeKey	smallint,
					  @ptOldNarrative	ntext,
					  @sOldShortNarrative	nvarchar(254),
					  @pnOldLocalDiscount	decimal(10,2),
					  @psOldForeignCurrencyCode nvarchar(3),
					  @pnOldForeignValue	decimal(11,2),
					  @pnOldExchangeRate	decimal(11,4),
					  @pnOldForeignDiscount	decimal(11,2),
					  @pnOldParentEntryNo	int,
					  @pnOldCostCalculation1 decimal(11,2),
					  @pnOldCostCalculation2 decimal(11,2),
					  @pnOldProductKey	int,
					  @pnOldEntityNo	int,
					  @pnOldTransNo 	int,
					  @pnOldWipSeqNo	smallint,
					  @pnOldIsTimer		decimal(1,0),
					  @pnOldMarginNo	int',					  
					  @pnStaffKey		= @pnStaffKey,
					  @pnEntryNo		= @pnEntryNo,
					  @psActivityKey	= @psActivityKey,
					  @pnCaseKey		= @pnCaseKey,
					  @pnNameKey		= @pnNameKey,
					  @pdtStartDateTime	= @pdtStartDateTime,
					  @pdtFinishDateTime	= @pdtFinishDateTime,
					  @dtTotalTime		= @dtTotalTime,
					  @pnTotalUnits		= @pnTotalUnits,
					  @dtTimeCarriedForward = @dtTimeCarriedForward,
					  @pnUnitsPerHour	= @pnUnitsPerHour,
					  @pnLocalValue 	= @pnLocalValue,
					  @pnChargeOutRate 	= @pnChargeOutRate,
					  @psNotes		= @psNotes,
					  @bLongFlag		= @bLongFlag,
					  @pnNarrativeKey	= @pnNarrativeKey,
					  @ptNarrative		= @ptNarrative,
					  @sShortNarrative	= @sShortNarrative,
					  @pnLocalDiscount	= @pnLocalDiscount,
					  @psForeignCurrencyCode= @psForeignCurrencyCode,
					  @pnForeignValue	= @pnForeignValue,
					  @pnExchangeRate	= @pnExchangeRate,
					  @pnForeignDiscount	= @pnForeignDiscount,
					  @pnParentEntryNo	= @pnParentEntryNo,
					  @pnCostCalculation1	= @pnCostCalculation1,
					  @pnCostCalculation2	= @pnCostCalculation2,
					  @pnProductKey		= @pnProductKey,
					  @pnEntityNo		= @pnEntityNo,
					  @pnTransNo 		= @pnTransNo,
					  @pnWipSeqNo		= @pnWipSeqNo, 
					  @pnIsTimer		= @pnIsTimer,
					  @pnMarginNo		= @pnMarginNo,
					  @psOldActivityKey	= @psOldActivityKey,
					  @pnOldCaseKey		= @pnOldCaseKey,
					  @pnOldNameKey		= @pnOldNameKey,
					  @pdtOldStartDateTime	= @pdtOldStartDateTime,
					  @pdtOldFinishDateTime	= @pdtOldFinishDateTime,
					  @dtOldTotalTime	= @dtOldTotalTime,
					  @pnOldTotalUnits	= @pnOldTotalUnits,
					  @dtOldTimeCarriedForward = @dtOldTimeCarriedForward,
					  @pnOldUnitsPerHour	= @pnOldUnitsPerHour,
					  @pnOldLocalValue 	= @pnOldLocalValue,
					  @pnOldChargeOutRate 	= @pnOldChargeOutRate,
					  @psOldNotes		= @psOldNotes,
					  @pnOldNarrativeKey	= @pnOldNarrativeKey,
					  @ptOldNarrative	= @ptOldNarrative,
					  @sOldShortNarrative	= @sOldShortNarrative,
					  @pnOldLocalDiscount	= @pnOldLocalDiscount,
					  @psOldForeignCurrencyCode = @psOldForeignCurrencyCode,
					  @pnOldForeignValue	= @pnOldForeignValue,
					  @pnOldExchangeRate	= @pnOldExchangeRate,
					  @pnOldForeignDiscount	= @pnOldForeignDiscount,
					  @pnOldParentEntryNo	= @pnOldParentEntryNo,
					  @pnOldCostCalculation1= @pnOldCostCalculation1,
					  @pnOldCostCalculation2= @pnOldCostCalculation2,
					  @pnOldProductKey	= @pnOldProductKey,
					  @pnOldEntityNo	= @pnOldEntityNo,
					  @pnOldTransNo 	= @pnOldTransNo,
					  @pnOldWipSeqNo	= @pnOldWipSeqNo,
					  @pnOldIsTimer		= @pnOldIsTimer,
					  @pnOldMarginNo	= @pnOldMarginNo  					 
End


Return @nErrorCode
GO

Grant execute on dbo.ts_UpdateDiary to public
GO

