-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dw_UpdateDocketData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[dw_UpdateDocketData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dw_UpdateDocketData.'
	Drop procedure [dbo].[dw_UpdateDocketData]
End
Print '**** Creating Stored Procedure dbo.dw_UpdateDocketData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.dw_UpdateDocketData
(
	@pnUserIdentityId	        int,		-- Mandatory
	@psCulture		        nvarchar(10) 	= null,
	@pbCalledFromCentura	        bit		= 0,
	@psRowKey 		        nvarchar(50)    = null,
	@pnCaseKey 		        int             = null,
	@pnDueEventKey		        int             = null,
	@pnDueCycle		        int             = null,
	@psEventDueDescription	        nvarchar(254)   = null,
	@pdtDueDate		        datetime        = null,
	@pnStaffKey		        int             = null,
	@pnOccurredEventKey 	        int             = null,
	@pnOccurredCycle	        int             = null,
	@psOccurredEventDescription     nvarchar(254)   = null,
	@pdtOccurredDate 		datetime        = null,
	@pnSendMethodKey		int             = null,
	@pdtSendDate			datetime        = null,
	@pdtReceiptDate			datetime        = null,
	@psReference			nvarchar(50)    = null,
	@pdtAlertSequence		datetime        = null,
	@pbIsAdHocDate			bit             = null,
	@pnDisplayOrder			int             = null,
	@pnOldDueEventKey		int             = null,
	@pnOldDueCycle			int             = null,
	@psOldEventDueDescription       nvarchar(254)   = null,
	@pdtOldDueDate			datetime        = null,
	@pnOldStaffKey			int             = null,
	@pnOldOccurredEventKey	        int             = null,
	@pnOldOccurredCycle		int             = null,
	@psOldOccurredEventDescription  nvarchar(254)   = null,
	@pdtOldOccurredDate		datetime        = null,
	@pnOldSendMethodKey		int             = null,
	@pdtOldSendDate			datetime        = null,
	@pdtOldReceiptDate		datetime        = null,
	@psOldReference			nvarchar(50)    = null,
	@pdtOldAlertSequence	        datetime        = null,
	@pnOldDisplayOrder		int             = null,	
	@pnPolicingBatchNo		int             = null
)
as
-- PROCEDURE:	dw_UpdateDocketData
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Used by WorkBenches to save docketing wizard data.  Logic derived from C/S Docket Wizard.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 4  JAN 2008	SF	5708	1	Procedure created
-- 19 JAN 2010	KR	100053	2	added @pnOldNameKey to the call to ipw_UpdateAdHocDate	
-- 09 APR 2014  MS  R31303  3   Added LastModifiedDate to csw_UpdateCaseEvent call 
-- 23 Nov 2016	DV	R62369	4	Remove concurrency check when updating case events
-- 27 Dec 2016	MS	R70131	5	Fix concurrency issue by passing EmployeeFlag etc.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)
declare @sAdHocReference nvarchar(20)
declare @nOccurredReasonKey int
declare @dtDeleteDate datetime
declare @dtStopRemindersDate datetime
declare @nRepeatIntervalMonths int
declare @nMonthsLead int
declare @nRepeatIntervalDays int
declare @nDaysLead int
declare @nSequenceNo int
declare @bIsElectronicReminder bit
declare @sEmailSubject nvarchar(100)
declare @sImportanceLevel nvarchar(2)
declare @nDisplayOrder int
declare @nEventKey int
declare @nEventCycle int
declare @dtLastModfifiedDate datetime
declare @bIsEmployee		bit	
declare	@bIsSignatory		bit
declare	@bIsCriticalList	bit
declare	@sNameType			nvarchar(3)
declare	@sRelationship		nvarchar(3)
			
-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	If @pbIsAdHocDate = 1
	Begin
		If @pnOldStaffKey <> @pnStaffKey 
		Begin
			-- delete old, create new.
			exec @nErrorCode = ipw_DeleteAdHocDateByKey
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,
				@pnNameKey		= @pnOldStaffKey,
				@pdtDateCreated		= @pdtAlertSequence		
				
			If @nErrorCode = 0
			Begin
				exec @nErrorCode = ipw_InsertAdHocDate
					@pnUserIdentityId	= @pnUserIdentityId,
					@psCulture		= @psCulture,
					@pnNameKey		= @pnStaffKey,
					@pnCaseKey		= @pnCaseKey,
					@psAdHocMessage		= @psEventDueDescription,
					@pdtDueDate		= @pdtDueDate, 	
					@pdtDateOccurred	= @pdtOccurredDate,
					@pbIsElectronicReminder = 0,
					@pnDisplayOrder		= @pnDisplayOrder,
					@pnPolicingBatchNo	= @pnPolicingBatchNo
			End
		End
		Else
		Begin
			-- the update proc insists on updating everything, so it has to be brought back.
			Set @sSQLString = "Select 
				@sAdHocReference 		= REFERENCE,
				@nOccurredReasonKey 		= ISNULL(OCCURREDFLAG,0),
				@dtDeleteDate 			= DELETEDATE,
				@dtStopRemindersDate 		= STOPREMINDERSDATE,
				@nRepeatIntervalMonths		= MONTHLYFREQUENCY,
				@nMonthsLead 			= MONTHSLEAD,
				@nRepeatIntervalDays 		= DAILYFREQUENCY,
				@nDaysLead 			= DAYSLEAD,
				@nSequenceNo 			= SEQUENCENO,
				@bIsElectronicReminder 		= SENDELECTRONICALLY,
				@sEmailSubject 			= EMAILSUBJECT,
				@sImportanceLevel 		= IMPORTANCELEVEL,
				@nDisplayOrder			= DISPLAYORDER,
				@bIsEmployee			= EMPLOYEEFLAG,
				@bIsSignatory			= SIGNATORYFLAG,
				@bIsCriticalList		= CRITICALFLAG,
				@sNameType				= NAMETYPE,
				@sRelationship			= RELATIONSHIP
				FROM ALERT
				where 	EMPLOYEENO 		= @pnStaffKey
				and 	ALERTSEQ		= @pdtAlertSequence"
						
			exec @nErrorCode=sp_executesql @sSQLString,
				N'@sAdHocReference nvarchar(20) output,
					@nOccurredReasonKey int output,
					@dtDeleteDate datetime output,
					@dtStopRemindersDate datetime output,
					@nRepeatIntervalMonths int output,
					@nMonthsLead int output,
					@nRepeatIntervalDays int output,
					@nDaysLead int output,
					@nSequenceNo int output,
					@bIsElectronicReminder bit output,
					@sEmailSubject nvarchar(100) output,
					@sImportanceLevel nvarchar(2) output,
					@nDisplayOrder int output,
					@bIsEmployee bit output,
					@bIsSignatory bit	output,
					@bIsCriticalList bit output,
					@sNameType nvarchar(3) output,
					@sRelationship nvarchar(3) output,
					@pnStaffKey int,
					@pdtAlertSequence datetime',
					@sAdHocReference = @sAdHocReference output,
					@nOccurredReasonKey = @nOccurredReasonKey output,
					@dtDeleteDate = @dtDeleteDate output,
					@dtStopRemindersDate = @dtStopRemindersDate output,
					@nRepeatIntervalMonths = @nRepeatIntervalMonths output,
					@nMonthsLead = @nMonthsLead output,
					@nRepeatIntervalDays = @nRepeatIntervalDays output,
					@nDaysLead = @nDaysLead output,
					@nSequenceNo = @nSequenceNo output,
					@bIsElectronicReminder = @bIsElectronicReminder output,
					@sEmailSubject = @sEmailSubject output,
					@sImportanceLevel = @sImportanceLevel output,
					@nDisplayOrder = @nDisplayOrder output,
					@bIsEmployee = @bIsEmployee output,
					@bIsSignatory = @bIsSignatory output,
					@bIsCriticalList = @bIsCriticalList output,
					@sNameType = @sNameType output,
					@sRelationship = @sRelationship output,
					@pnStaffKey = @pnStaffKey,
					@pdtAlertSequence = @pdtAlertSequence
					
			If @nErrorCode = 0
			Begin
				exec @nErrorCode = dbo.ipw_UpdateAdHocDate
					@pnUserIdentityId	        = @pnUserIdentityId,
					@psCulture			= @psCulture,
					@pnNameKey			= @pnStaffKey,
					@pnCaseKey			= @pnCaseKey,
					@pdtDateCreated		        = @pdtAlertSequence,
					@psAdHocMessage		        = @psEventDueDescription,
					@pdtDueDate			= @pdtDueDate, 	
					@pdtDateOccurred	        = @pdtOccurredDate,
					
					@psAdHocReference		= @sAdHocReference,
					@pnOccurredReasonKey	        = @nOccurredReasonKey,
					@pdtDeleteDate			= @dtDeleteDate,
					@pdtStopRemindersDate	        = @dtStopRemindersDate,
					@pnDaysLead			= @nDaysLead,
					@pnRepeatIntervalDays	        = @nRepeatIntervalDays,
					@pnMonthsLead			= @nMonthsLead,
					@pnRepeatIntervalMonths         = @nRepeatIntervalMonths,
					@pnSequenceNo			= @nSequenceNo,
					@pbIsElectronicReminder         = @bIsElectronicReminder,
					@psEmailSubject			= @sEmailSubject,
					@psImportanceLevel		= @sImportanceLevel,
					@pnDisplayOrder			= @pnDisplayOrder,
					
					@psOldAdHocMessage		= @psOldEventDueDescription,
					@pdtOldDueDate			= @pdtOldDueDate, 	
					@pdtOldDateOccurred		= @pdtOldOccurredDate,
					@pnOldNameKey			= @pnOldStaffKey,						
					@pnOldCaseKey			= @pnCaseKey,
					
					@pnOldOccurredReasonKey 	= @nOccurredReasonKey,
					@pdtOldDeleteDate 		= @dtDeleteDate,
					@pdtOldStopRemindersDate	= @dtStopRemindersDate,
					@pnOldRepeatIntervalMonths	= @nRepeatIntervalMonths,
					@pnOldMonthsLead		= @nMonthsLead,
					@pnOldRepeatIntervalDays	= @nRepeatIntervalDays,
					@pnOldDaysLead			= @nDaysLead,
					@pnOldSequenceNo		= @nSequenceNo,
					@pbOldIsElectronicReminder	= @bIsElectronicReminder,
					@psOldEmailSubject		= @sEmailSubject,
					@psOldImportanceLevel		= @sImportanceLevel,
					@pnOldDisplayOrder		= @nDisplayOrder,
					@pbOldIsEmployee		= @bIsEmployee,
					@pbOldIsSignatory		= @bIsSignatory,
					@pbOldIsCriticalList	= @bIsCriticalList,
					@psOldNameType			= @sNameType,
					@psOldRelationship		= @sRelationship,
					@pnPolicingBatchNo	    = @pnPolicingBatchNo
			End	
		End
	End
	Else
	Begin
		-- update case event -- due event / occurred event
		Set @nEventKey = isnull(@pnDueEventKey, @pnOccurredEventKey)		
		Set @nEventCycle = case when @pnDueEventKey is null then @pnOccurredCycle else @pnDueCycle end
		
		If @nErrorCode = 0
                Begin
		        exec @nErrorCode = dbo.csw_UpdateCaseEvent
			        @pnUserIdentityId	= @pnUserIdentityId,
			        @psCulture		= @psCulture,
			        @pbCalledFromCentura    = @pbCalledFromCentura,
			        @pnCaseKey		= @pnCaseKey,
			        @pnEventKey		= @nEventKey,
			        @pnEventCycle		= @nEventCycle,
			        @pdtEventDate		= @pdtOccurredDate,
			        @pdtEventDueDate	= @pdtDueDate,
			        @pnSendMethodKey	= @pnSendMethodKey,
			        @pdtSendDate		= @pdtSendDate,
			        @pdtReceiptDate		= @pdtReceiptDate,
			        @psReference		= @psReference,
			        @pnStaffKey		= @pnStaffKey,
			        @pnDisplayOrder		= @pnDisplayOrder,
			        @pnPolicingBatchNo	= @pnPolicingBatchNo,
			        @pbIsEventKeyInUse	= 1,
			        @pbIsEventCycleInUse 	= 1,
			        @pbIsEventDateInUse	= 1,
			        @pbIsEventDueDateInUse	= 1,
			        @pbIsSendMethodKeyInUse	= 1,
			        @pbIsSendDateInUse	= 1,
			        @pbIsReceiptDateInUse	= 1,
			        @pbIsReferenceInUse	= 1,
			        @pbIsStaffKeyInUse	= 1,
			        @pbIsDisplayOrderInUse	= 1
                End
	End
End

Return @nErrorCode
GO

Grant execute on dbo.dw_UpdateDocketData to public
GO
