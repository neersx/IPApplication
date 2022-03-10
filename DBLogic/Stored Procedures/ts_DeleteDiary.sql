-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ts_DeleteDiary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ts_DeleteDiary.'
	Drop procedure [dbo].[ts_DeleteDiary]
End
Print '**** Creating Stored Procedure dbo.ts_DeleteDiary...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.ts_DeleteDiary
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnStaffKey		int,		-- Mandatory		
	@pnEntryNo		int,		-- Mandatory
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
	@pnOldIsTimer		decimal(1,0)	= null
)
-- PROCEDURE:	ts_DeleteDiary
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION: Deletes a Timesheet Entry if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 14 Mar 2005  TM	RFC2379	1	Procedure created. 
-- 21 Jun 2005	TM	RFC1100	2	Rename TimesheetData to TimeEntryData. Remove DaySummary datatable. Implement  
--					new IsTimer column. Change TotalTime to ElapsedMinutes, TimeCarriedForward to
--					MinutesCarriedForward. Add processing for continued entries.
-- 22 Jun 2005	TM	RFC1100	3	Correct the parent time calculation logic. Give an error if the row has been
--					continued by a timer.
-- 29 Jun 2005	TM	RFC1100	4	When converting datetime values to minutes set the minutes value to null if 
--					the datetime value is null instead of setting it to 0.
-- 04 Jan 2006	TM	RFC3354	5	Store short Narrative in local variable.
-- 20 Oct 2015  MS      R53933  6       Changed size from decimal(8,4) to decimal(11,4) for rate cols

AS

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON


Declare @nErrorCode			int
Declare @sSQLString			nvarchar(4000)
Declare @sAlertXML 			nvarchar(400)
Declare @bOldLongFlag			bit
Declare @sOldShortNarrative		nvarchar(254)
Declare @nEntryNo			int
Declare @bIsTimerContinued		bit

Declare @dtOldTotalTime			datetime
Declare	@dtOldTimeCarriedForward 	datetime

Declare @dtParentTotalTime		datetime
Declare	@dtParentTimeCarriedForward 	datetime
Declare @dtParentHours			datetime
Declare @nParentTotalUnits		smallint				
Declare @nParentUnitsPerHour		smallint
Declare @nParentChargeOutRate		decimal(10,2)	
Declare @nParentLocalValue		decimal(11,2)
Declare @nParentForeignValue		decimal(11,2)
Declare @sParentForeignCurrencyCode	nvarchar(3)
Declare @nParentExchangeRate		decimal(11,4)
Declare @nParentLocalDiscount		decimal(11,2)
Declare	@nParentForeignDiscount		decimal(11,2)
Declare @nParentCostCalculation1	decimal(11,2)
Declare @nParentCostCalculation2	decimal(11,2)

Declare @dtTransactionDate		datetime

-- Initialise variables
Set @nErrorCode 	= 0
Set @bIsTimerContinued	= 0

If  @nErrorCode = 0
and @pnOldIsTimer = 0
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
		Set @sAlertXML = dbo.fn_GetAlertXML('AC10', 'This entry cannot be deleted because it has been continued. Please check your timers.',
			null, null, null, null, null)
		RAISERROR(@sAlertXML, 12, 1)
		Set @nErrorCode = @@ERROR
	End
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
	If @pnOldElapsedMinutes is not null
	Begin
		Set @dtOldTotalTime = convert(datetime, '1899-01-01 ' + cast(@pnOldElapsedMinutes/60 as varchar(10)) + ':' + cast(@pnOldElapsedMinutes%60 as varchar(10)), 120)
	End

	If @pnOldMinutesCarriedForward is not null
	Begin
		Set @dtOldTimeCarriedForward = convert(datetime, '1899-01-01 ' + cast(@pnOldMinutesCarriedForward/60 as varchar(10)) + ':' + cast(@pnOldMinutesCarriedForward%60 as varchar(10)), 120)
	End
End

-- Remove from continued chain if this row is part 
-- of a chain and is not a timer:
If @nErrorCode = 0
and @pnOldParentEntryNo is not null 
and @pnOldIsTimer = 0
Begin
	If @nErrorCode = 0 
	Begin
		Set @sSQLString = "
		Select  @dtParentTotalTime = CASE WHEN (FINISHTIME is null and STARTTIME is null) THEN NULL 
						  ELSE convert(datetime, '1899-01-01 ' + substring(convert(nvarchar(25), (ISNULL(FINISHTIME,0) - ISNULL(STARTTIME,0)), 120), 12, 12), 120)			
					     END
		from DIARY
		where  EMPLOYEENO = @pnStaffKey
		and    ENTRYNO = @pnOldParentEntryNo"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@dtParentTotalTime		datetime		output,
						  @pnStaffKey			int,
						  @pnOldParentEntryNo		int',
						  @dtParentTotalTime		= @dtParentTotalTime	output,
						  @pnStaffKey			= @pnStaffKey,
						  @pnOldParentEntryNo		= @pnOldParentEntryNo

		If @nErrorCode = 0 
		Begin
			-- Recalculate parent time carried forward:
			Set @dtParentTimeCarriedForward = CASE WHEN (@dtOldTimeCarriedForward is null and @dtParentTotalTime is null) THEN NULL
							       ELSE  convert(datetime, '1899-01-01 ' + substring(convert(nvarchar(25), (ISNULL(@dtOldTimeCarriedForward,0) - ISNULL(@dtParentTotalTime,0)), 120), 12, 12), 120)  	
							  END

			If @dtParentTimeCarriedForward = '1899-01-01 00:00:00.000'
			Begin
				Set @dtParentTimeCarriedForward = null
			End
		End		
		
		If @nErrorCode = 0 
		Begin		
			Set @sSQLString = "
			Update DIARY					
			Set    TIMECARRIEDFORWARD = @dtParentTimeCarriedForward,
			       TOTALTIME = @dtParentTotalTime
			where  EMPLOYEENO = @pnStaffKey
			and    ENTRYNO = @pnOldParentEntryNo"
		
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@dtParentTimeCarriedForward	datetime,
							  @dtParentTotalTime		datetime,
							  @pnStaffKey			int,
							  @pnOldParentEntryNo		int',
							  @dtParentTimeCarriedForward	= @dtParentTimeCarriedForward,
							  @dtParentTotalTime		= @dtParentTotalTime,
							  @pnStaffKey			= @pnStaffKey,
							  @pnOldParentEntryNo		= @pnOldParentEntryNo
		End
	End

	-- Recost parent
	If @nErrorCode = 0 
	Begin	
		-- Prepare parameters to call wp_GetWipCost:
		If @pdtOldStartDateTime is not null
		Begin
			Set @dtTransactionDate = convert(datetime, convert(char(10),convert(datetime,@pdtOldStartDateTime,120),120), 120)
		End

		Set @pnOldNameKey = CASE WHEN @pnOldCaseKey is null THEN @pnOldNameKey ELSE NULL END

		If @dtParentTotalTime is not null
		or @dtParentTimeCarriedForward is not null
		Begin
			Set @dtParentHours = convert(datetime, '1899-01-01 ' + substring(convert(nvarchar(25), (ISNULL(@dtParentTotalTime,0) + ISNULL(@dtParentTimeCarriedForward,0)), 120), 12, 12), 120) 			 
		End

		exec @nErrorCode = wp_GetWipCost 
			@pnUserIdentityId	= @pnUserIdentityId,
			@pdtTransactionDate	= @dtTransactionDate,
			@pnStaffKey		= @pnStaffKey,
			@pnNameKey		= @pnOldNameKey,
			@pnCaseKey		= @pnOldCaseKey,
			@psWipCode		= @psOldActivityKey,
			@pnProductKey		= @pnOldProductKey,
			@pdtHours		= @dtParentHours,
			@pbMarginRequired	= 1,
			@pnTimeUnits		= @nParentTotalUnits 		output,
			@pnUnitsPerHour		= @nParentUnitsPerHour		output,	
			@pnChargeOutRate	= @nParentChargeOutRate		output,				
			@pnLocalValue		= @nParentLocalValue		output,
			@pnForeignValue		= @nParentForeignValue		output,
			@psCurrencyCode		= @sParentForeignCurrencyCode	output,
			@pnExchangeRate		= @nParentExchangeRate		output,
			@pnLocalDiscount	= @nParentLocalDiscount		output,
			@pnForeignDiscount	= @nParentForeignDiscount	output,
			@pnLocalCost1		= @nParentCostCalculation1	output,
			@pnLocalCost2		= @nParentCostCalculation2	output			
	End

	-- Update parent row
	If @nErrorCode = 0 
	Begin	
		Set @sSQLString = "
		Update DIARY 
		Set     TIMEVALUE		= @nParentLocalValue,
			DISCOUNTVALUE		= @nParentLocalDiscount,
			TOTALUNITS		= @nParentTotalUnits,
			FOREIGNCURRENCY		= @sParentForeignCurrencyCode,
			EXCHRATE		= @nParentExchangeRate,
			FOREIGNVALUE		= @nParentForeignValue,
			FOREIGNDISCOUNT		= @nParentForeignDiscount,
			COSTCALCULATION1	= @nParentCostCalculation1,
			COSTCALCULATION2	= @nParentCostCalculation2,
			UNITSPERHOUR		= @nParentUnitsPerHour,
			CHARGEOUTRATE		= @nParentChargeOutRate,
			TIMECARRIEDFORWARD	= @dtParentTimeCarriedForward
		where   EMPLOYEENO 		= @pnStaffKey
		and     ENTRYNO 		= @pnOldParentEntryNo"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nParentTotalUnits		smallint,
						  @nParentUnitsPerHour		smallint,
						  @nParentChargeOutRate		decimal(10,2),
						  @nParentLocalValue		decimal(11,2),
						  @nParentForeignValue		decimal(11,2),
						  @sParentForeignCurrencyCode	nvarchar(3),
						  @nParentExchangeRate		decimal(11,4),
						  @nParentLocalDiscount		decimal(11,2),
						  @nParentForeignDiscount	decimal(11,2),
						  @nParentCostCalculation1	decimal(11,2),
						  @nParentCostCalculation2	decimal(11,2),
						  @dtParentTimeCarriedForward	datetime,
						  @pnStaffKey			int,
						  @pnOldParentEntryNo		int',
						  @nParentTotalUnits		= @nParentTotalUnits,
						  @nParentUnitsPerHour		= @nParentUnitsPerHour,
						  @nParentChargeOutRate		= @nParentChargeOutRate,
						  @nParentLocalValue		= @nParentLocalValue,
						  @nParentForeignValue		= @nParentForeignValue,
						  @sParentForeignCurrencyCode	= @sParentForeignCurrencyCode,
						  @nParentExchangeRate		= @nParentExchangeRate,
						  @nParentLocalDiscount		= @nParentLocalDiscount,
						  @nParentForeignDiscount	= @nParentForeignDiscount,
						  @nParentCostCalculation1	= @nParentCostCalculation1,
						  @nParentCostCalculation2	= @nParentCostCalculation2,
						  @dtParentTimeCarriedForward	= @dtParentTimeCarriedForward,
						  @pnStaffKey			= @pnStaffKey,
						  @pnOldParentEntryNo		= @pnOldParentEntryNo		
	End
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "	
	Delete 
	from  DIARY 
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
	and 	ISTIMER		= @pnOldIsTimer"

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
					  @pnOldIsTimer		decimal(1,0)',					  
					  @pnStaffKey		= @pnStaffKey,
					  @pnEntryNo		= @pnEntryNo,
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
					  @pnOldIsTimer		= @pnOldIsTimer	  					 
End


Return @nErrorCode
GO

Grant execute on dbo.ts_DeleteDiary to public
GO

