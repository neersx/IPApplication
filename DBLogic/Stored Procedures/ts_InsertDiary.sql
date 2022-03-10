-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ts_InsertDiary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ts_InsertDiary.'
	Drop procedure [dbo].[ts_InsertDiary]
End
Print '**** Creating Stored Procedure dbo.ts_InsertDiary...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ts_InsertDiary
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnStaffKey		int,		-- Mandatory		
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
	@pnMinutesCarriedForward int	= null,
	@pnParentEntryNo	int		= null,
	@pnNarrativeKey		smallint	= null,
	@ptNarrative		ntext		= null,
	@psNotes		nvarchar(254)	= null,
	@pnProductKey		int		= null,
	@pnIsTimer		decimal(1,0)	= null,
	@pnMarginNo		int		= null
)
-- PROCEDURE:	ts_InsertDiary
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Create a new Timesheet Entry.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 14 Mar 2005  TM	RFC2379	1	Procedure created. 
-- 20 Jun 2005	TM	RFC1100	2	Rename TimesheetData to TimeEntryData. Remove DaySummary datatable. Implement  
--					new IsTimer column. Change TotalTime to ElapsedMinutes, TimeCarriedForward to
--					MinutesCarriedForward. Add processing for continued entries.
-- 22 Jun 2005	TM	RFC1100	3	Change the error message.
-- 29 Jun 2005	TM	RFC2765	4	Set @nEntryNo to 0 when entering particular employee for the first time.
-- 25 Mar 2008	MS	RFC7130	5	New parameter @pnMarginNo will be added to store MarginNo for the time entry.
-- 20 Oct 2015  MS      R53933  6       Changed size from decimal(8,4) to decimal(11,4) for rate cols

AS

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON


Declare @nErrorCode		int
Declare @sSQLString		nvarchar(4000)
declare @sAlertXML 		nvarchar(400)

Declare @bLongFlag		bit
Declare @nEntryNo		int

Declare @dtTotalTime		datetime
Declare	@dtTimeCarriedForward	datetime

Declare @dtParentFinishTime	datetime
Declare @bIsFinalRow		bit

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

-- Convert @pnElapsedMinutes and @pnMinutesCarriedForward to the datetime datatype:
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
End

-- Generate the next available EntryNo from Diary where EmployeeNo = StaffKey.  
-- If there is none, use zero.
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select @nEntryNo = max(ENTRYNO)+1
	from   DIARY
	where  EMPLOYEENO = @pnStaffKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nEntryNo	int		OUTPUT,
					  @pnStaffKey	int',
					  @nEntryNo	= @nEntryNo	OUTPUT,
					  @pnStaffKey	= @pnStaffKey
End

-- Set @nEntryNo to 0 when entering particular employee for the first time.
If @nErrorCode = 0
Begin
	Set @nEntryNo = ISNULL(@nEntryNo, 0)
End

-- Validate continuation
If @nErrorCode = 0
and @pnParentEntryNo is not null -- This row is part of a chain
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

	-- Start Time cannot be prior to Finish Time of previous row in the chain:
	If @nErrorCode = 0 
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

	-- Add to continued chain

	-- Is this row is part of a chain and is not a timer:
	If @pnIsTimer = 0
	and @nErrorCode = 0
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
			MARGINNO		= NULL
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
		@nEntryNo,
		@psActivityKey,
		@pnCaseKey,
		CASE WHEN @pnCaseKey is null THEN @pnNameKey ELSE NULL END,
		@pdtStartDateTime,
		@pdtFinishDateTime,
		@dtTotalTime,
		@pnTotalUnits,
		@dtTimeCarriedForward,
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
					  @nEntryNo		int,
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
					  @nEntryNo		= @nEntryNo,
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
	Select @nEntryNo as EntryNo
End


Return @nErrorCode
GO

Grant execute on dbo.ts_InsertDiary to public
GO

