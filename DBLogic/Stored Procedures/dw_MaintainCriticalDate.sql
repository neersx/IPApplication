-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dw_MaintainCriticalDate
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[dw_MaintainCriticalDate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dw_MaintainCriticalDate.'
	Drop procedure [dbo].[dw_MaintainCriticalDate]
End
Print '**** Creating Stored Procedure dbo.dw_MaintainCriticalDate...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.dw_MaintainCriticalDate
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura	        bit		= 0,
	@psRowKey			nvarchar(15)    = null,
	@pnCaseKey			int             = null,
	@pdtDate			datetime        = null,
	@psOfficialNumber		nvarchar(36)    = null,
	@psNumberTypeCode		nvarchar(3)     = null,
	@psCountryKey			nvarchar(3)     = null,
	@pnEventKey			int             = null,
	@pbIsPriorityEvent		bit             = null,
	@pdtOldDate			datetime        = null,
	@psOldOfficialNumber	        nvarchar(36)    = null,
	@psOldCountryKey		nvarchar(3)     = null,
	@pnOldEventKey			int             = null,
	@pnPolicingBatchNo		int             = null
)
as
-- PROCEDURE:	dw_MaintainCriticalDate
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Used by WorkBenches to save critical dates section of the Docketing Wizard.  Logic derived from C/S Docket Wizard.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 4 JAN 2008	SF	5708	1	Procedure created
-- 09 APR 2014  MS  R31303  2   Added LastModifiedDate to csw_UpdateCaseEvent call 
-- 23 Nov 2016	DV	R62369	3	Remove concurrency check when updating case events 

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)
declare @dtOrigEventDate datetime
declare @dtOrigDueDate datetime

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	-- priority event requires special processing
	if @pbIsPriorityEvent = 1	
	Begin
		-- takes care of all priority event maintenance, including add/insert/update of related cases, case events, and policing
		exec csw_MaintainPriorityEvent
			@pnUserIdentityId		= @pnUserIdentityId,
			@psCulture			= @psCulture,
			@pbCalledFromCentura	        = @pbCalledFromCentura,
			@psRowKey			= @psRowKey,
			@pnCaseKey			= @pnCaseKey,
			@pdtDate			= @pdtDate,
			@psOfficialNumber		= @psOfficialNumber,
			@psCountryKey			= @psCountryKey,
			@pnEventKey			= @pnEventKey,
			@pbIsPriorityEvent		= 1,
			@pdtOldDate			= @pdtOldDate,
			@psOldOfficialNumber	        = @psOldOfficialNumber,
			@psOldCountryKey		= @psOldCountryKey,
			@pnOldEventKey			= @pnOldEventKey,
			@pnPolicingBatchNo		= @pnPolicingBatchNo
	End	
	Else	
	Begin
		-- only perform work if things have changed.
		If not (@pdtDate = @pdtOldDate and @psCountryKey = @psOldCountryKey and @psOfficialNumber = @psOldOfficialNumber)
		Begin
			-- process all other critical dates.
			Set @sSQLString = "
				Select 	@dtOrigEventDate = EVENTDATE,
					@dtOrigDueDate = EVENTDUEDATE
				from CASEEVENT CE
				where CE.CASEID = @pnCaseKey 
				and CE.EVENTNO = @pnEventKey 
				and CE.CYCLE = 1"
			
			exec @nErrorCode = sp_executesql @sSQLString,
							N'@dtOrigEventDate	        datetime        output,
								@dtOrigDueDate	        datetime        output,
								@pnCaseKey		int,
								@pnEventKey		int',
								@dtOrigEventDate	= @dtOrigEventDate      output, 
								@dtOrigDueDate 		= @dtOrigDueDate        output,
								@pnCaseKey		= @pnCaseKey,
								@pnEventKey		= @pnEventKey
			
			If @nErrorCode = 0
			Begin
				If (@dtOrigEventDate is not null or @dtOrigDueDate is not null) -- either one exists
				Begin
					-- update case event
					exec @nErrorCode = dbo.csw_UpdateCaseEvent
							@pnUserIdentityId		= @pnUserIdentityId,
							@psCulture			= @psCulture,
							@pnCaseKey			= @pnCaseKey,
							@pnPolicingBatchNo		= @pnPolicingBatchNo,
							@pnEventKey			= @pnEventKey,
							@pnEventCycle			= 1,
							@pdtEventDate			= @pdtDate,
							@pdtEventDueDate		= @dtOrigDueDate,
							@pbIsEventKeyInUse		= 1,
							@pbIsEventCycleInUse		= 1,
							@pbIsEventDateInUse		= 1,	
							@pbIsEventDueDateInUse		= 1
				End
				Else
				Begin
					-- insert case event
					exec @nErrorCode = dbo.csw_InsertCaseEvent
							@pnUserIdentityId		= @pnUserIdentityId,
							@psCulture			= @psCulture,
							@pnCaseKey			= @pnCaseKey,
							@pnPolicingBatchNo		= @pnPolicingBatchNo,
							@pnEventKey			= @pnEventKey,
							@pnCycle			= 1,
							@pdtEventDate			= @pdtDate,
							@pbIsPolicedEvent		= 1
				End
			End
		End
		
		-- update official numbers
		If @nErrorCode =0
		and @psNumberTypeCode is not null
		and @psNumberTypeCode in ('A','P','C','R')
		Begin
			-- the takes care of delete, update and add, as well as to set current official number
			exec @nErrorCode = dbo.cs_MaintainOfficialNumber
					@pnUserIdentityId			= @pnUserIdentityId,
					@psCulture				= @psCulture,
					@pnCaseKey				= @pnCaseKey,
					@psNumberTypeKey			= @psNumberTypeCode,
					@psOfficialNumber			= @psOfficialNumber,
					@psOldOfficialNumber 			= @psOldOfficialNumber
		End
	End
End


Return @nErrorCode
GO

Grant execute on dbo.dw_MaintainCriticalDate to public
GO
