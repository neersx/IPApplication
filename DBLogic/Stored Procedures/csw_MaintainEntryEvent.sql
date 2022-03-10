-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_MaintainEntryEvent
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_MaintainEntryEvent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_MaintainEntryEvent.'
	Drop procedure [dbo].[csw_MaintainEntryEvent]
End
Print '**** Creating Stored Procedure dbo.csw_MaintainEntryEvent...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.csw_MaintainEntryEvent
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnCriteriaKey			int,		
	@pnEntryNumber	 		smallint,
	@psActionKey			nvarchar(2),
	@pnCaseKey			int,
	@pnEventKey			int,
	@pnEventCycle			smallint,
	@pdtEventDueDate		datetime	= null,
	@pdtEventDate			datetime	= null,
	@pbIsStopPolicing		bit		= null,
	@pnPeriodDuration		smallint	= null,
	@psPeriodTypeKey		nchar(1)	= null,
	@pnEventTextType		smallint	= null,
	@ptEventText			nvarchar(max)	= null,
	@pbIsNew			bit		= null,
	@pnPolicingBatchNo		int 		= null,
	@pnDueDateRespKey		int		= null,
	@pdtLastModifiedDate            datetime        = null,
	@pbOldIsStopPolicing		bit		= null	
)
as
-- PROCEDURE:	csw_MaintainEntryEvent
-- VERSION:	14
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Maintain events against an entry.  Model after cs_UpdateEntryEvent that was used by Inprostart.

-- MODIFICATIONS :
-- Date		Who		Change		Version	Description
-- -----------	-------		------		-------	----------------------------------------------- 
-- 11 Nov 2008	SF		RFC3329		1	Procedure created
-- 03 Dec 2008	SF		RFC7384		2	@pbIsStopPolicing is not a parameter for procedure csw_InsertCaseEventB
-- 04 Dec 2008	SF		RFC7384		3	@pbIsStopPolicing is not a parameter for procedure csw_UpdateCaseEvent
-- 14 Feb 2011	AT		RFC10034	4	Enabled @pbIsStopPolicing parameter.
-- 16 Aug 2011	JC		RFC11136	5	Pass @pnPolicingBatchNo to csw_UpdateCaseEvent.
-- 23 Sep 2011	AT		RFC11332	6	Removed duplicate @pbIsPolicingBatchNoInUse parameter.
-- 26 Sep 2011	AT		RFC11332	7	Fixed parameters passed to update other event.
-- 06 Feb 2012	SF		RFC11900	8	Pass @pnPolicingBatchNo when updating case event - this RFC is to merge RFC11136 and RFC11132
-- 07 May 2012	SF		RFC12264	9	Pass @pbIsPolicingBatchNoInUse only once when updating case event.
-- 09 Apr 2014  MS              R31303          10      Pass LastModifiedDate for csw_UpdateCaseEvent
-- 11 Nov 2014	MF		R40781		11	When a shadow Event is being created the EventDueDate should be cleared if an EventDate exists.
-- 02 Mar 2015	MS		R43203		12	Added EventTextType parameter
-- 29 Sep 2016	MF		69013		13	Change ntext to nvarchar(max).
-- 23 Nov 2016	DV		R62369		13	Remove concurrency check when updating case events
-- 13 Mar 2019	DV		DR26323		14	Fixed issue where DueDateResp field was not visible even when configured

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString	nvarchar(max)
declare @nOtherEventKey int
	
-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
begin
	If @pbIsNew = 1
	begin

		exec @nErrorCode = csw_InsertCaseEventB
				@pnUserIdentityId		= @pnUserIdentityId,
				@psCulture			= @psCulture,
				@pnCaseKey			= @pnCaseKey,
				@pnEventKey			= @pnEventKey,
				@pnEventCycle			= @pnEventCycle,	
				@pdtEventDueDate		= @pdtEventDueDate,
				@pdtEventDate			= @pdtEventDate,
				@pnPeriod			= @pnPeriodDuration,
				@psPeriodTypeKey		= @psPeriodTypeKey,
				@pnEventTextType		= @pnEventTextType,
				@ptEventText			= @ptEventText,
				@psCreatedByActionCode		= @psActionKey,
				@pnCreatedByCriteriaKey		= @pnCriteriaKey,
				@pnPolicingBatchNo		= @pnPolicingBatchNo,
				@pbIsStopPolicing		= @pbIsStopPolicing,
				@pnStaffKey				= @pnDueDateRespKey,
				@pbIsEventKeyInUse		= 1,
				@pbIsEventCycleInUse		= 1,
				@pbIsEventDateInUse		= 1,
				@pbIsEventDueDateInUse		= 1,
				@pbIsEventTextInUse		= 1,
				@pbIsPeriodInUse		= 1,
				@pbIsPeriodTypeKeyInUse 	= 1,
				@pbIsCreatedByActionCodeInUse	= 1,
				@pbIsCreatedByCriteriaKeyInUse	= 1,
				@pbIsPolicingBatchNoInUse	= 1,
				@pbIsStopPolicingInUse		= 1,
				@pbIsStaffKeyInUse			= 1

	end
	Else
	begin		
		If @nErrorCode = 0
		begin	
			exec @nErrorCode = csw_UpdateCaseEvent
				@pnUserIdentityId		= @pnUserIdentityId,
				@psCulture			= @psCulture,
				@pnCaseKey			= @pnCaseKey,
				@pnEventKey			= @pnEventKey,
				@pnEventCycle			= @pnEventCycle,
				@pdtEventDueDate		= @pdtEventDueDate,
				@pdtEventDate			= @pdtEventDate,
				@pnEventTextType		= @pnEventTextType,
				@ptEventText			= @ptEventText,
				@pnPeriod			= @pnPeriodDuration,
				@psPeriodTypeKey		= @psPeriodTypeKey,
				@psCreatedByActionCode		= @psActionKey,
				@pnCreatedByCriteriaKey		= @pnCriteriaKey,
				@pbIsStopPolicing		= @pbIsStopPolicing,
				@pnPolicingBatchNo		= @pnPolicingBatchNo,
				@pbOldIsStopPolicing		= @pbOldIsStopPolicing,
				@pbIsEventKeyInUse		= 1,
				@pbIsEventCycleInUse		= 1,
				@pbIsEventDateInUse		= 1,
				@pbIsEventDueDateInUse		= 1,
				@pbIsEventTextInUse		= 1,
				@pbIsPeriodInUse		= 1,
				@pbIsPeriodTypeKeyInUse 	= 1,
				@pbIsCreatedByActionCodeInUse	= 1,
				@pbIsCreatedByCriteriaKeyInUse	= 1,
				@pbIsPolicingBatchNoInUse	= 1,
				@pbIsStopPolicingInUse		= 1,
				@pbIsDueDateRespKeyInUse	= 1,
				@pnDueDateRespKey			= @pnDueDateRespKey
		end		
	end

	If @nErrorCode = 0
	begin
		Select 	@nOtherEventKey = OTHEREVENTNO
		from	DETAILDATES
		where	CRITERIANO = @pnCriteriaKey
		and	ENTRYNUMBER = @pnEntryNumber
		and	EVENTNO = @pnEventKey

		Set @nErrorCode = @@ERROR
	end

	If @nErrorCode = 0
	and @nOtherEventKey is not null
	begin
		If not exists
			(Select 1 from CASEEVENT
			where 	CASEID = @pnCaseKey
			and	EVENTNO = @nOtherEventKey
			and	CYCLE = @pnEventCycle)
		begin	
			-------------------------------
			-- Clear out the due date if an
			-- EventDate is being supplied.
			-------------------------------
			If  @pdtEventDate    is not null
			and @pdtEventDueDate is not null
				Set @pdtEventDueDate=NULL
				
			exec @nErrorCode = csw_InsertCaseEventB
				@pnUserIdentityId		= @pnUserIdentityId,
				@psCulture			= @psCulture,
				@pnCaseKey			= @pnCaseKey,
				@pnEventKey			= @nOtherEventKey,
				@pnEventCycle			= @pnEventCycle,	
				@pdtEventDueDate		= @pdtEventDueDate,
				@pdtEventDate			= @pdtEventDate,
				@pnPeriod			= @pnPeriodDuration,
				@psPeriodTypeKey		= @psPeriodTypeKey,
				@pnEventTextType		= @pnEventTextType,
				@ptEventText			= @ptEventText,
				@psCreatedByActionCode		= @psActionKey,
				@pnCreatedByCriteriaKey		= @pnCriteriaKey,
				@pnPolicingBatchNo		= @pnPolicingBatchNo,
				@pbIsStopPolicing		= @pbIsStopPolicing,
				@pnStaffKey				= @pnDueDateRespKey,
				@pbIsEventKeyInUse		= 1,
				@pbIsEventCycleInUse		= 1,
				@pbIsEventDateInUse		= 1,
				@pbIsEventDueDateInUse		= 1,
				@pbIsEventTextInUse		= 1,
				@pbIsPeriodInUse		= 1,
				@pbIsPeriodTypeKeyInUse 	= 1,
				@pbIsCreatedByActionCodeInUse	= 1,
				@pbIsCreatedByCriteriaKeyInUse	= 1,
				@pbIsPolicingBatchNoInUse	= 1,
				@pbIsStopPolicingInUse		= 1,
				@pbIsStaffKeyInUse			=1
		end
		Else
		begin			
			exec @nErrorCode = csw_UpdateCaseEvent
				@pnUserIdentityId		= @pnUserIdentityId,
				@psCulture			= @psCulture,
				@pnCaseKey			= @pnCaseKey,
				@pnEventKey			= @nOtherEventKey,
				@pnEventCycle			= @pnEventCycle,
				@pdtEventDueDate		= @pdtEventDueDate,
				@pdtEventDate			= @pdtEventDate,
				@pbIsEventKeyInUse		= 1,
				@pbIsEventCycleInUse		= 1,
				@pbIsEventDateInUse		= 1,
				@pbIsEventDueDateInUse		= 1,
				@pbIsEventTextInUse		= 0,
				@pbIsPeriodInUse		= 0,
				@pbIsPeriodTypeKeyInUse 	= 0,
				@pbIsCreatedByActionCodeInUse	= 0,
				@pbIsCreatedByCriteriaKeyInUse	= 0,
				@pbIsPolicingBatchNoInUse	= 0,
				@pbIsStopPolicingInUse		= 0
		end

	end
end

Return @nErrorCode
GO

Grant execute on dbo.csw_MaintainEntryEvent to public
GO
