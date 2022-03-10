-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dw_InsertDocketData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[dw_InsertDocketData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dw_InsertDocketData.'
	Drop procedure [dbo].[dw_InsertDocketData]
End
Print '**** Creating Stored Procedure dbo.dw_InsertDocketData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.dw_InsertDocketData
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey 				int,	-- Mandatory
	@pbIsAdHocDate			bit = 0,
	@pnDueEventKey			int = null,
	@pnDueCycle				int = null,
	@psEventDueDescription	nvarchar(254) = null,
	@pdtDueDate				datetime = null,
	@pnStaffKey				int = null,
	@pnOccurredEventKey 	int = null,
	@pnOccurredCycle		int = null,
	@psOccurredEventDescription nvarchar(254) = null,
	@pdtOccurredDate 		datetime = null,
	@pnSendMethodKey		int = null,
	@pdtSendDate			datetime = null,
	@pdtReceiptDate			datetime = null,
	@psReference			nvarchar(50) = null,
	@pnDisplayOrder			int = null,
	@pnPolicingBatchNo		int = null
)
as
-- PROCEDURE:	dw_InsertDocketData
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Used by WorkBenches to save docketing wizard data.  Logic derived from C/S Docket Wizard.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 4 JAN 2008	SF	5708	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @nEventKey int
declare @nEventCycle int
declare @bInsertBoth bit
-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin	
	
	-- Insert New AdHoc Date
	If @pbIsAdHocDate = 1
	Begin
		exec @nErrorCode = ipw_InsertAdHocDate
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture			= @psCulture,
			@pnNameKey			= @pnStaffKey,
			@pnCaseKey			= @pnCaseKey,
			@psAdHocMessage		= @psEventDueDescription,
			@pdtDueDate			= @pdtDueDate, 	
			@pdtDateOccurred	= @pdtOccurredDate,
			@pbIsElectronicReminder = 0,
			@pnDisplayOrder		= @pnDisplayOrder,
			@pnPolicingBatchNo	= @pnPolicingBatchNo
	End
	Else -- Insert New Event
	Begin 	
	
		-- if @pnOccurredEventKey is provided, insert occurred event
		-- if @pnDueEventKey is provided, insert due event
		-- if both provided and not the same, insert both
		Set @bInsertBoth = 0
		If (@pnOccurredEventKey is not null and @pnDueEventKey is null)
			or (@pnOccurredEventKey = @pnDueEventKey) 
		Begin
				Set @nEventKey = @pnOccurredEventKey
				Set	@nEventCycle = isnull(@pnOccurredCycle,1)
		End
		Else If (@pnDueEventKey is not null and @pnOccurredEventKey is null)
			or (@pnDueEventKey = @pnOccurredEventKey) 
		Begin
				Set @nEventKey = @pnDueEventKey
				Set	@nEventCycle = isnull(@pnDueCycle,1)
		End
		Else
		Begin
			Set @bInsertBoth = 1
		End
			
		If @bInsertBoth = 0
		Begin
			exec @nErrorCode = csw_InsertCaseEvent
					@pnUserIdentityId		= @pnUserIdentityId,
					@psCulture			= @psCulture,
					@pnCaseKey			= @pnCaseKey,
					@pnEventKey			= @nEventKey,
					@pnCycle			= @nEventCycle,
					@pdtEventDueDate	= @pdtDueDate,
					@pdtEventDate		= @pdtOccurredDate,
					@pnSendMethodKey	= @pnSendMethodKey,
					@pdtSendDate		= @pdtSendDate,
					@pdtReceiptDate		= @pdtReceiptDate,
					@psReference		= @psReference,
					@pbIsPolicedEvent	= 1,
					@pnPolicingBatchNo	= @pnPolicingBatchNo,
					@pnStaffKey			= @pnStaffKey,
					@pnDisplayOrder		= @pnDisplayOrder
		End
		Else
		Begin		
			exec @nErrorCode = csw_InsertCaseEvent
					@pnUserIdentityId		= @pnUserIdentityId,
					@psCulture				= @psCulture,
					@pnCaseKey				= @pnCaseKey,
					@pnEventKey				= @pnOccurredEventKey,
					@pnCycle				= @pnOccurredCycle,
					@pdtEventDueDate		= @pdtDueDate,
					@pdtEventDate			= @pdtOccurredDate,
					@pnSendMethodKey	= @pnSendMethodKey,
					@pdtSendDate		= @pdtSendDate,
					@pdtReceiptDate		= @pdtReceiptDate,
					@psReference		= @psReference,
					@pbIsPolicedEvent		= 1,
					@pnPolicingBatchNo		= @pnPolicingBatchNo,
					@pnStaffKey				= @pnStaffKey,
					@pnDisplayOrder			= @pnDisplayOrder
			
			If @nErrorCode = 0
			Begin
				exec @nErrorCode = csw_InsertCaseEvent
					@pnUserIdentityId		= @pnUserIdentityId,
					@psCulture				= @psCulture,
					@pnCaseKey				= @pnCaseKey,
					@pnEventKey				= @nEventKey,
					@pnCycle				= @nEventCycle,
					@pdtEventDueDate		= @pdtDueDate,
					@pdtEventDate			= @pdtOccurredDate,
					@pnSendMethodKey		= @pnSendMethodKey,
					@pdtSendDate			= @pdtSendDate,
					@pdtReceiptDate			= @pdtReceiptDate,
					@psReference			= @psReference,
					@pbIsPolicedEvent		= 1,
					@pnPolicingBatchNo		= @pnPolicingBatchNo,
					@pnStaffKey				= @pnStaffKey,
					@pnDisplayOrder			= @pnDisplayOrder
			End
		End
	End			
End

Return @nErrorCode
GO

Grant execute on dbo.dw_InsertDocketData to public
GO
