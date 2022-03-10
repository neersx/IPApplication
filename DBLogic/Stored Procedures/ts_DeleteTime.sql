-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ts_DeleteTime]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ts_DeleteTime.'
	Drop procedure [dbo].[ts_DeleteTime]
End
Print '**** Creating Stored Procedure dbo.ts_DeleteTime...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.ts_DeleteTime
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnStaffKey		int,		-- Mandatory		
	@pnEntryNo		int,		-- Mandatory
	@pdtLastModified datetime = null
)
-- PROCEDURE:	ts_DeleteTime
-- VERSION:		5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION: Deletes a Timesheet Entry if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 25 Mar 2011	SF	R9871	1	Procedure created, based on ts_DeleteDiary.
-- 13 Mar 2011	SF	R9871	2	Update continue chain even if it is a timer. Called when a timer is cancelled.
-- 12 Jan 2012	SF	R11791	3	Incorrect derivation of parent time carried forward
-- 16 Sep 2013	AT	DR-1024	4	Moved value recalculation for parent entry to C#.
-- 20 Oct 2015  MS      R53933  5      Changed size from decimal(8,4) to decimal(11,4) for ExchRate cols

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

Declare @tOldNarrative				nvarchar(max)
Declare @nOldParentEntryNo			int
Declare @nOldIsTimer				decimal(1,0)

Declare @dtOldStartDateTime		datetime
Declare @dtOldFinishDateTime		datetime
Declare @nOldNameKey			int
Declare @nOldCaseKey			int
Declare @sOldActivityKey		nvarchar(6)
Declare @nOldProductKey			int

-- Initialise variables
Set @nErrorCode 	= 0
Set @bIsTimerContinued	= 0

If @nErrorCode = 0
Begin
	-- get details of the row o
	Set @sSQLString = "
	Select @tOldNarrative = ISNULL(D.LONGNARRATIVE, D.SHORTNARRATIVE),
		   @dtOldTimeCarriedForward = D.TIMECARRIEDFORWARD,
		   @nOldParentEntryNo =  D.PARENTENTRYNO,
		   @nOldIsTimer	= isnull(D.ISTIMER,0),
		   @dtOldStartDateTime = D.STARTTIME,
		   @dtOldFinishDateTime = D.FINISHTIME,
		   @nOldNameKey = D.NAMENO,
		   @nOldCaseKey = D.CASEID,
		   @sOldActivityKey = D.ACTIVITY,
		   -- Product information should only be populated if the Product 
		   -- Recorded on WIP site control is turned on
		   @nOldProductKey = 
			CASE	WHEN SCP.COLBOOLEAN = 1
			   THEN D.PRODUCTCODE	
			   ELSE NULL
			END
	from   DIARY D
	left join SITECONTROL SCP	on (SCP.CONTROLID = 'Product Recorded on WIP')
	where  EMPLOYEENO = @pnStaffKey
	and    ENTRYNO = @pnEntryNo"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@tOldNarrative				nvarchar(max)		OUTPUT,
					  @dtOldTimeCarriedForward		datetime			OUTPUT,
					  @nOldParentEntryNo			int					OUTPUT,
					  @nOldIsTimer					decimal(1,0)		OUTPUT,
					  @dtOldStartDateTime			datetime			OUTPUT,
					  @dtOldFinishDateTime			datetime			OUTPUT,
					  @nOldNameKey					int					OUTPUT,
					  @nOldCaseKey					int					OUTPUT,
					  @sOldActivityKey				nvarchar(6)			OUTPUT,
					  @nOldProductKey				int					OUTPUT,
					  @pnStaffKey		int,
					  @pnEntryNo		int',
					  @tOldNarrative					= @tOldNarrative				OUTPUT,
					  @dtOldTimeCarriedForward		= @dtOldTimeCarriedForward	OUTPUT,
					  @nOldParentEntryNo				= @nOldParentEntryNo			OUTPUT,
					  @nOldIsTimer						= @nOldIsTimer					OUTPUT,
					  @dtOldStartDateTime				= @dtOldStartDateTime			OUTPUT,
					  @dtOldFinishDateTime				= @dtOldFinishDateTime			OUTPUT,
					  @nOldNameKey						= @nOldNameKey					OUTPUT,
					  @nOldCaseKey						= @nOldCaseKey					OUTPUT,
					  @sOldActivityKey					= @sOldActivityKey				OUTPUT,
					  @nOldProductKey					= @nOldProductKey				OUTPUT,
					  @pnStaffKey		= @pnStaffKey,
					  @pnEntryNo		= @pnEntryNo
End


If  @nErrorCode = 0
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
If (datalength(@tOldNarrative) <= 508)
or datalength(@tOldNarrative) is null
Begin
	Set @bOldLongFlag = 0
	Set @sOldShortNarrative = CAST(@tOldNarrative as nvarchar(254))
End
Else
Begin
	Set @bOldLongFlag = 1
End

-- Remove from continued chain if this row is part 
If @nErrorCode = 0
and @nOldParentEntryNo is not null 
Begin
	If @nErrorCode = 0 
	Begin
		Set @sSQLString = "
		Select  @dtParentTotalTime = CASE WHEN (FINISHTIME is null and STARTTIME is null) THEN NULL 
						  ELSE convert(datetime, '1899-01-01 ' + substring(convert(nvarchar(25), (ISNULL(FINISHTIME,0) - ISNULL(STARTTIME,0)), 120), 12, 12), 120)			
					     END
		from DIARY
		where  EMPLOYEENO = @pnStaffKey
		and    ENTRYNO = @nOldParentEntryNo"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@dtParentTotalTime		datetime		output,
						  @pnStaffKey			int,
						  @nOldParentEntryNo		int',
						  @dtParentTotalTime		= @dtParentTotalTime	output,
						  @pnStaffKey			= @pnStaffKey,
						  @nOldParentEntryNo		= @nOldParentEntryNo

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
			and    ENTRYNO = @nOldParentEntryNo"
		
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@dtParentTimeCarriedForward	datetime,
							  @dtParentTotalTime		datetime,
							  @pnStaffKey			int,
							  @nOldParentEntryNo		int',
							  @dtParentTimeCarriedForward	= @dtParentTimeCarriedForward,
							  @dtParentTotalTime		= @dtParentTotalTime,
							  @pnStaffKey			= @pnStaffKey,
							  @nOldParentEntryNo		= @nOldParentEntryNo
		End
	End
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "	
	Delete 
	from  DIARY 
	where   EMPLOYEENO	= @pnStaffKey
	and     ENTRYNO		= @pnEntryNo		
	and 	LOGDATETIMESTAMP = @pdtLastModified"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnStaffKey		int,
					  @pnEntryNo		int,
					  @pdtLastModified	datetime',					  
					  @pnStaffKey		= @pnStaffKey,
					  @pnEntryNo		= @pnEntryNo,
					  @pdtLastModified	= @pdtLastModified			 
End


Return @nErrorCode
GO

Grant execute on dbo.ts_DeleteTime to public
GO

