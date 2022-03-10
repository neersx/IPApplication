-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ts_UpdateTime]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ts_UpdateTime.'
	Drop procedure [dbo].[ts_UpdateTime]
End
Print '**** Creating Stored Procedure dbo.ts_UpdateTime...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.ts_UpdateTime
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnStaffKey		int,		-- Mandatory		
	@pnEntryNo		int,		-- Mandatory
	@pdtStartDateTime	datetime	= null,
	@pdtFinishDateTime	datetime	= null,
	@pdtNewEntryDate	datetime	= null,
	@pnNameKey		int		= null,
	@pnCaseKey		int		= null,
	@psActivityKey		nvarchar(6)	= null,
	@pdtTimeCarriedForward datetime = null,
	@pdtTotalTime		datetime = null,
	--@pnElapsedMinutes	int		= null,
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
	@pnFileLocationKey	int		= null,
	@pdtLogDateTimeStamp	datetime	= null	output
)
-- PROCEDURE:	ts_UpdateTime
-- VERSION:	14
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION: Update a Timesheet Entry if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 20 Sep 2009	SF	RFC9717	1	Migrated from ts_UpdateDiary for Silverlight Time Entry
-- 07 Mar 2011	SF	RFC9871	2	Add support to save File Location
-- 25 Mar 2011	SF	RFC9871	3	Signature for csw_InsertFileLocation has changed.
-- 29 Mar 2011	SF	RFC9871	4	When Moved must not be null
-- 02 May 2011	SF	RFC9871	5	Clear timer when Finish Time is not null
-- 11 May 2011	SF	RFC9367	6	Empty File Location should not be saved if there were previous file location saved against the case
-- 04 Nov 2011	ASH	RFC11460 7	Cast integer columns as nvarchar(11) data type. 
-- 14 Nov 2012	AK	RFC10648 8	Added logic to update StartDateTime and EndDateTime with NewEntryDate if change explicitly. 
-- 13 Jan 2015	MS	RFC42621 9	Set @pdtLogDateTimeStamp as output variable        
-- 20 Oct 2015  MS      R53933  10      Changed size from decimal(8,4) to decimal(11,4) for rate cols       
-- 03 Jul 2018	LP	R72410	11	Verify Total Units is correct before saving the time entry.
-- 10 Jul 2018	LP	R72410	12	Consider seconds in units calculation where specified by site control.
-- 06-Aug-2018	LP	R74541	13	Return error as XML.
-- 02-Nov-2018	LP	DR-45006 14	Verify Total units before updating DIARY table.


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

Declare @dtWhenMoved		datetime
Declare @nOldFileLocationKey int	

Declare @dtEntryDate			datetime
declare @dLastEntryMinutes		decimal
declare @dAccumulatedMinutes		decimal
declare @dUnitsPerHour			decimal
declare @nVerifiedUnits			decimal
declare @sMessageString			nvarchar(400)
declare @bSecInUnitsCalc		bit
declare @nSeconds			decimal
declare @nAccumulatedSeconds		decimal

-- Initialise variables
Set @nErrorCode 	= 0

-- RFC72410: Ensure the Total Units is correctly derived as: (Total Time + Accumulated Time) / (60 / Units Per Hour)

If @nErrorCode = 0
Begin
	select @bSecInUnitsCalc = ISNULL(COLBOOLEAN, 0)
	from SITECONTROL 
	where CONTROLID = 'Consider Secs in Units Calc.'
	
	set @nVerifiedUnits = 0
	set @dUnitsPerHour = CAST((60 / @pnUnitsPerHour) as decimal(10,2))
	set @dLastEntryMinutes = CAST(DATEDIFF(mi, CONVERT(VARCHAR(10), @pdtTotalTime, 112), @pdtTotalTime) as decimal(10,2))
	set @dAccumulatedMinutes = CAST(DATEDIFF(mi, CONVERT(VARCHAR(10), @pdtTimeCarriedForward, 112), @pdtTimeCarriedForward) as decimal(10,2))
	set @nAccumulatedSeconds = DATEDIFF(SECOND, CONVERT(VARCHAR(10), @pdtTimeCarriedForward, 112), @pdtTimeCarriedForward)
	set @nSeconds = DATEDIFF(SECOND, CONVERT(VARCHAR(10), @pdtTotalTime, 112), @pdtTotalTime) + ISNULL(@nAccumulatedSeconds, 0)
	
	if (@dLastEntryMinutes + ISNULL(@dAccumulatedMinutes, 0) > 0)
	Begin
		If (@bSecInUnitsCalc = 0)
		Begin
			set @nVerifiedUnits = CEILING((@dLastEntryMinutes + ISNULL(@dAccumulatedMinutes, 0))/@dUnitsPerHour)
		End Else
		Begin			
			set @nVerifiedUnits = CEILING(@nSeconds/(60 * @dUnitsPerHour))
		End
	End Else
	Begin
		if (@bSecInUnitsCalc = 1)
		Begin
			If (@nSeconds > 0 and @nSeconds < 60)
			begin
				set @nVerifiedUnits = 1
			End Else If (@nSeconds > 60)
			Begin
				set @nVerifiedUnits = CEILING(@nSeconds/(60 * @dUnitsPerHour))
			End
		End Else
		Begin
			if (@nSeconds >= 60)
			Begin
				set @nVerifiedUnits = 1		
			End
		End
	End
		
	if (@nVerifiedUnits <> @pnTotalUnits)	
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('AC30', N'Time recording failed due to incorrect Total Units. Please re-enter the time.'
			+char(13)+char(10)+'Expected Total Units: {0}'
			+char(13)+char(10)+'Actual Total Units: {1}',
			convert(nvarchar(10), @nVerifiedUnits), convert(nvarchar(10), @pnTotalUnits), null, null, null)
		RAISERROR(@sAlertXML, 12, 1)		
		Set @nErrorCode = @@ERROR
	End			
End

If @nErrorCode = 0
and @pnCaseKey is not null
Begin
	
	Set @sSQLString = "
	Select  
		@nOldFileLocationKey = CL.FILELOCATION,
		@dtWhenMoved = getdate()			
		from CASELOCATION CL
		left join (	select	CASEID, 
					MAX( convert(nvarchar(24),WHENMOVED, 21)+cast(CASEID as nvarchar(11)) ) as [DATE]
					from CASELOCATION CLMAX
					group by CASEID	
					) LASTMODIFIED	on (LASTMODIFIED.CASEID = @pnCaseKey)
		where CL.CASEID = @pnCaseKey
			and ( (convert(nvarchar(24),CL.WHENMOVED, 21)+cast(CL.CASEID as nvarchar(11))) = LASTMODIFIED.[DATE]
															or LASTMODIFIED.[DATE] is null )
		"
		
		exec @nErrorCode = sp_executesql @sSQLString,
						N'@nOldFileLocationKey 	int				output,
						  @dtWhenMoved			datetime		output,
						  @pnCaseKey			int',
						  @nOldFileLocationKey	= @nOldFileLocationKey output,
						  @dtWhenMoved			= @dtWhenMoved output,
						  @pnCaseKey			= @pnCaseKey

	If @nErrorCode = 0
	and @nOldFileLocationKey <> @pnFileLocationKey
	and ((@nOldFileLocationKey is not null and @pnFileLocationKey is not null) or
		(@nOldFileLocationKey is null and @pnFileLocationKey is not null))
	Begin	
		
		If (@dtWhenMoved is null)
		Begin
			Set @dtWhenMoved = GETDATE()
		End
		
		exec @nErrorCode = csw_InsertFileLocation
				@pnUserIdentityId		= @pnUserIdentityId,		-- Mandatory
				@psCulture				= @psCulture,
				@pbCalledFromCentura	= 0,
				@pnCaseKey				= @pnCaseKey,		
				@pdtWhenMoved			= @dtWhenMoved,	
				@pnFileLocationKey		= @pnFileLocationKey
	End
End

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

-- Update continued chain if this row is part of the chain:
If  @nErrorCode = 0
and @pnParentEntryNo is not null
Begin
	-- Reset previous final row if finalising a timer. Clear any data 
	-- that should only be populated for the final row in the chain.
	If @nErrorCode = 0
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
			MARGINNO		= NULL,
			ISTIMER			= 0
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
	and (@pdtNewEntryDate is null
	and exists (
		select 1 
		from DIARY
		where	EMPLOYEENO = @pnStaffKey
		and		ENTRYNO = @pnEntryNo
		and		LOGDATETIMESTAMP = @pdtLogDateTimeStamp
		and		(
				NAMENO <> @pnNameKey
			or	CASEID <> @pnCaseKey
			or	ACTIVITY <> @psActivityKey
			or	NARRATIVENO <> @pnNarrativeKey
			or	DATEDIFF(day,@pdtStartDateTime, STARTTIME)<> 0
			or  DATEDIFF(day,@pdtFinishDateTime,FINISHTIME)<> 0
			or  dbo.fn_IsNtextEqual(@ptNarrative, DIARY.LONGNARRATIVE) <> 1
		)))
	or (@pdtNewEntryDate is not null
	and exists (
		select 1 
		from DIARY
		where	EMPLOYEENO = @pnStaffKey
		and		ENTRYNO = @pnEntryNo
		and		LOGDATETIMESTAMP = @pdtLogDateTimeStamp
		and		(
				NAMENO <> @pnNameKey
			or	CASEID <> @pnCaseKey
			or	ACTIVITY <> @psActivityKey
			or	NARRATIVENO <> @pnNarrativeKey
			or  dbo.fn_IsNtextEqual(@ptNarrative, DIARY.LONGNARRATIVE) <> 1
		))
	)
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
and (DATEPART(HOUR, @pdtFinishDateTime) <> 0
and DATEPART(MINUTE, @pdtFinishDateTime) <> 0)
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
		TOTALTIME	= @pdtTotalTime,
		TOTALUNITS	= @pnTotalUnits,
		TIMECARRIEDFORWARD = @pdtTimeCarriedForward,
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
	and		LOGDATETIMESTAMP = @pdtLogDateTimeStamp"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnStaffKey		int,
					  @pnEntryNo		int,
					  @psActivityKey	nvarchar(6),
					  @pnCaseKey		int,
					  @pnNameKey		int,
					  @pdtStartDateTime	datetime,
					  @pdtFinishDateTime	datetime,
					  @pdtTotalTime		datetime,
					  @pnTotalUnits		smallint,
					  @pdtTimeCarriedForward datetime,
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
					  @pdtLogDateTimeStamp	datetime',					  
					  @pnStaffKey		= @pnStaffKey,
					  @pnEntryNo		= @pnEntryNo,
					  @psActivityKey	= @psActivityKey,
					  @pnCaseKey		= @pnCaseKey,
					  @pnNameKey		= @pnNameKey,
					  @pdtStartDateTime	= @pdtStartDateTime,
					  @pdtFinishDateTime	= @pdtFinishDateTime,
					  @pdtTotalTime		= @pdtTotalTime,
					  @pnTotalUnits		= @pnTotalUnits,
					  @pdtTimeCarriedForward = @pdtTimeCarriedForward,
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
					  @pdtLogDateTimeStamp = @pdtLogDateTimeStamp
					  
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select @pdtLogDateTimeStamp = LOGDATETIMESTAMP
			From DIARY
			WHERE EMPLOYEENO	= @pnStaffKey
			and     ENTRYNO		= @pnEntryNo"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnStaffKey		int,
			  @pnEntryNo		int,
			  @pdtLogDateTimeStamp	datetime output',
			  @pnStaffKey		= @pnStaffKey,
			  @pnEntryNo		= @pnEntryNo,
			  @pdtLogDateTimeStamp  = @pdtLogDateTimeStamp	output
End

Return @nErrorCode
GO

Grant execute on dbo.ts_UpdateTime to public
GO

