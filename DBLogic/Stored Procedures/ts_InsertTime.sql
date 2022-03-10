-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ts_InsertTime]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ts_InsertTime.'
	Drop procedure [dbo].[ts_InsertTime]
End
Print '**** Creating Stored Procedure dbo.ts_InsertTime...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.ts_InsertTime
(
	@pnEntryNo		int = null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnStaffKey		int,		-- Mandatory	
	@pdtStartDateTime	datetime	= null,
	@pdtFinishDateTime	datetime	= null,
	@pnNameKey		int		= null,
	@pnCaseKey		int		= null,
	@psActivityKey		nvarchar(6)	= null,
	@pnTotalUnits		smallint	= null,
	@pdtTotalTime		datetime = null,
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
	@pdtTimeCarriedForward datetime	= null,
	@pnParentEntryNo	int		= null,
	@pnNarrativeKey		smallint	= null,
	@ptNarrative		ntext		= null,
	@psNotes		nvarchar(254)	= null,
	@pnProductKey		int		= null,
	@pnIsTimer		decimal(1,0)	= null,
	@pnMarginNo		int		= null,
	@pnFileLocationKey	int	= null
)
-- PROCEDURE:	ts_InsertTime
-- VERSION:	14
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Create a new Timesheet Entry.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 21 Sep 2010  SF	RFC9717	1	Procedure created. Migrated from ts_InsertDiary
-- 07 Mar 2011	SF	RFC9871	2	Add support to save File Location
-- 25 Mar 2011	SF	RFC9871	3	Signature for csw_InsertFileLocation has changed.
-- 29 Mar 2011	SF	RFC9871	4	When Moved must not be null
-- 11 May 2011	SF	RFC9367	5	Empty File Location should not be saved if there were previous file location saved against the case
-- 06 Jul 2011	SF	RFC10911 6	Allow continuation of row with not start and finish time
-- 04 Nov 2011	ASH	R11460	7	Cast integer columns as nvarchar(11) data type.
-- 15 Jul 2014	AT	R13213	8	Add validation check for parent being posted.
-- 19 Jan 2015	MS	R42621	9	Set IsTimer = 0 for contniued entry
-- 20 Oct 2015  MS      R53933  10      Changed size from decimal(8,4) to decimal(11,4) for rate cols
-- 03 Jul 2018	LP	R72410	11	Verify Total Units is correct before saving the time entry.
-- 10 Jul 2018	LP	R72410	12	Consider seconds in units calculation where specified by site control.
-- 06-Aug-2018	LP	R74541	13	Return error as XML.
-- 30-Oct-2018	LP	DR-45006 14	Verify continued entries have TimeCarriedForward specified. Move check before changing DIARY table.

AS

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON


Declare @nErrorCode		int
Declare @sSQLString		nvarchar(4000)
Declare @sAlertXML 		nvarchar(400)

Declare @bLongFlag		bit


Declare @dtParentFinishTime	datetime
Declare @bIsFinalRow		bit
Declare @dtWhenMoved		datetime
Declare @nOldFileLocationKey	int
declare @dLastEntryMinutes	decimal
declare @dAccumulatedMinutes	decimal
declare @dUnitsPerHour		decimal
declare @nVerifiedUnits		decimal
declare @sMessageString		nvarchar(400)
declare @bSecInUnitsCalc		bit
declare @nSeconds			decimal
declare @nAccumulatedSeconds		decimal

-- Initialise variables
Set @nErrorCode 	= 0
Set @bIsFinalRow	= 0

-- Is the Narrative long text?
If (datalength(@ptNarrative) <= 508)
or datalength(@ptNarrative) is null
Begin
	Set @bLongFlag = 0
End
Else
Begin
	Set @bLongFlag = 1
End

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

-- Generate the next available EntryNo from Diary where EmployeeNo = StaffKey.  
-- If there is none, use zero.
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select @pnEntryNo = max(ENTRYNO)+1
	from   DIARY
	where  EMPLOYEENO = @pnStaffKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnEntryNo	int		OUTPUT,
					  @pnStaffKey	int',
					  @pnEntryNo	= @pnEntryNo	OUTPUT,
					  @pnStaffKey	= @pnStaffKey
End

-- Set @pnEntryNo to 0 when entering particular employee for the first time.
If @nErrorCode = 0
Begin
	Set @pnEntryNo = ISNULL(@pnEntryNo, 0)
End

-- Validate continuation
If @nErrorCode = 0
and @pnParentEntryNo is not null -- This row is part of a chain
Begin
	-- Verify the TimeCarriedForward has been specified
	If @pdtTimeCarriedForward is null
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('AC31', 'An unexpected error occured and we are unable to save the continued time. Time Carried Forward has not been specified.',
			null, null, null, null, null)
		RAISERROR(@sAlertXML, 12, 1)
		Set @nErrorCode = @@ERROR
	End

	If @nErrorCode = 0 
	Begin
		-- Locate FinishTime for Diary row for ParentEntryNo and StaffKey:
		Set @sSQLString = "
		Select @dtParentFinishTime = FINISHTIME
		from   DIARY
		where  EMPLOYEENO = @pnStaffKey
		and    ENTRYNO = @pnParentEntryNo"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@dtParentFinishTime	datetime		OUTPUT,
						  @pnStaffKey		int,
						  @pnParentEntryNo	int',
						  @dtParentFinishTime	= @dtParentFinishTime	OUTPUT,
						  @pnStaffKey		= @pnStaffKey,
						  @pnParentEntryNo	= @pnParentEntryNo
	End

	-- Start Time cannot be prior to Finish Time of previous row in the chain:
	If @nErrorCode = 0 
	and dbo.fn_DateOnly(@pdtStartDateTime) <> @pdtStartDateTime /* unless this new entry is without STARTTIME (unit only time) */
	and @dtParentFinishTime > @pdtStartDateTime
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('AC6', 'This entry cannot start before the continued row finished.',
			null, null, null, null, null)
		RAISERROR(@sAlertXML, 12, 1)
		Set @nErrorCode = @@ERROR
	End
	
	-- Is the parent row is the final row in the chain?
	If @nErrorCode = 0 
	Begin
		Set @sSQLString = "
		Select @bIsFinalRow = 1
		from   DIARY
		where  EMPLOYEENO = @pnStaffKey
		and    PARENTENTRYNO = @pnParentEntryNo"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@bIsFinalRow		bit		OUTPUT,
						  @pnStaffKey		int,
						  @pnParentEntryNo	int',
						  @bIsFinalRow		= @bIsFinalRow	OUTPUT,
						  @pnStaffKey		= @pnStaffKey,
						  @pnParentEntryNo	= @pnParentEntryNo
	End
	
	-- If there are any Diary rows for StaffKey that already 
	-- point to ParentEntryNo produce a user error:
	If  @bIsFinalRow = 1
	and @nErrorCode = 0
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('AC3', 'An entry cannot be continued twice. Please check your timers.',
			null, null, null, null, null)
		RAISERROR(@sAlertXML, 12, 1)
		Set @nErrorCode = @@ERROR
	End
	
	-- Parent cannot be posted when continuing an entry:
	If @nErrorCode = 0 
	and exists (select * from DIARY 
			where EMPLOYEENO = @pnStaffKey and ENTRYNO = @pnParentEntryNo
			AND WIPENTITYNO IS NOT NULL AND TRANSNO IS NOT NULL)
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('AC142', 'Could not save continued entry because the parent entry has been posted.',
			null, null, null, null, null)
		RAISERROR(@sAlertXML, 12, 1)
		Set @nErrorCode = @@ERROR
	End

	-- Add to continued chain

	-- Is this row is part of a chain and is not a timer:
	If @nErrorCode = 0
	Begin
		-- Reset previous final row: Clear any data that should only be 
		-- populated for the final row in the chain.  
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

		-- Ensure basic details are the same for the chain
		If @nErrorCode = 0
		Begin
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
				@pnProductKey		= @pnProductKey
		End		
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
	Set @sSQLString = "	
	insert into DIARY (
		EMPLOYEENO,
		ENTRYNO,
		ACTIVITY,
		CASEID,
		NAMENO,
		STARTTIME,
		FINISHTIME,
		TOTALTIME,
		TOTALUNITS,
		TIMECARRIEDFORWARD,
		UNITSPERHOUR,
		TIMEVALUE,
		CHARGEOUTRATE,
		NOTES,
		NARRATIVENO,
		SHORTNARRATIVE,
		LONGNARRATIVE,
		DISCOUNTVALUE,
		FOREIGNCURRENCY,
		FOREIGNVALUE,
		EXCHRATE,
		FOREIGNDISCOUNT,
		PARENTENTRYNO,
		COSTCALCULATION1,
		COSTCALCULATION2,
		PRODUCTCODE,
		ISTIMER,
		MARGINNO		
		)
	values (@pnStaffKey,
		@pnEntryNo,
		@psActivityKey,
		@pnCaseKey,
		CASE WHEN @pnCaseKey is null THEN @pnNameKey ELSE NULL END,
		@pdtStartDateTime,
		@pdtFinishDateTime,
		@pdtTotalTime,
		@pnTotalUnits,
		@pdtTimeCarriedForward,
		@pnUnitsPerHour,
		@pnLocalValue,
		@pnChargeOutRate,
		@psNotes,
		@pnNarrativeKey,
		CASE WHEN @bLongFlag = 1 THEN NULL ELSE CAST(@ptNarrative as nvarchar(254)) END,
		CASE WHEN @bLongFlag = 1 THEN @ptNarrative ELSE NULL END,
		@pnLocalDiscount,
		@psForeignCurrencyCode,
		@pnForeignValue,
		@pnExchangeRate,
		@pnForeignDiscount,
		@pnParentEntryNo,
		@pnCostCalculation1,
		@pnCostCalculation2,
		@pnProductKey,
		@pnIsTimer,
		@pnMarginNo)"

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
					  @pnLocalDiscount	decimal(10,2),
					  @psForeignCurrencyCode nvarchar(3),
					  @pnForeignValue	decimal(11,2),
					  @pnExchangeRate	decimal(11,4),
					  @pnForeignDiscount	decimal(11,2),
					  @pnParentEntryNo	int,
					  @pnCostCalculation1	decimal(11,2),
					  @pnCostCalculation2	decimal(11,2),
					  @pnProductKey		int,
					  @pnIsTimer		decimal(1,0),
					  @pnMarginNo		int',					  
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
					  @pnLocalDiscount	= @pnLocalDiscount,
					  @psForeignCurrencyCode= @psForeignCurrencyCode,
					  @pnForeignValue	= @pnForeignValue,
					  @pnExchangeRate	= @pnExchangeRate,
					  @pnForeignDiscount	= @pnForeignDiscount,
					  @pnParentEntryNo	= @pnParentEntryNo,
					  @pnCostCalculation1	= @pnCostCalculation1,
					  @pnCostCalculation2	= @pnCostCalculation2,
					  @pnProductKey		= @pnProductKey,
					  @pnIsTimer		= @pnIsTimer,
					  @pnMarginNo		= @pnMarginNo  				  					 

	-- Publish generated EntryNo sub key 
	Select @pnEntryNo as EntryNo
End


Return @nErrorCode
GO

Grant execute on dbo.ts_InsertTime to public
GO

