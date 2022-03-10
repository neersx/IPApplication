-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dw_DeleteDocketData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[dw_DeleteDocketData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dw_DeleteDocketData.'
	Drop procedure [dbo].[dw_DeleteDocketData]
End
Print '**** Creating Stored Procedure dbo.dw_DeleteDocketData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.dw_DeleteDocketData
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey 		int,	        -- Mandatory
	@pbIsAdHocDate		bit             = 0,
	@pdtAlertSequence	datetime        = null,
	@pnStaffKey		int             = null,
	@pnDueEventKey		int             = null,
	@pnDueCycle		int             = null,
	@pdtDueDate		datetime        = null,
	@pnOccurredEventKey 	int             = null,
	@pnOccurredCycle	int             = null,
	@pdtOccurredDate 	datetime        = null,
	@pnPolicingBatchNo	int             = null
)
as
-- PROCEDURE:	dw_DeleteDocketData
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete an event or an adhoc date.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15 JAN 2008	SF	RFC5708	1	Procedure created
-- 09 APR 2014  MS  R31303  2   Added LastModifiedDate to csw_UpdateCaseEvent call
-- 23 Nov 2016	DV	R62369	3	Remove concurrency check when updating case events    

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @nCycle int
declare @nEventKey int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	-- Delete AdHoc Date
	If @pbIsAdHocDate = 1
	Begin		
		exec @nErrorCode = ipw_DeleteAdHocDateByKey
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@pnNameKey		= @pnStaffKey,
			@pdtDateCreated		= @pdtAlertSequence		
	End	
	Else
	Begin
		-- delete the case event by removing both dates
		Set @nCycle = case when @pnDueEventKey is not null then @pnDueCycle else @pnOccurredCycle end
		Set @nEventKey = isnull(@pnDueEventKey, @pnOccurredEventKey)
    
                If @nErrorCode = 0
                Begin
		        exec @nErrorCode = dbo.csw_UpdateCaseEvent
			        @pnUserIdentityId		= @pnUserIdentityId,
			        @psCulture			= @psCulture,		
			        @pbCalledFromCentura	        = @pbCalledFromCentura,
			        @pnCaseKey			= @pnCaseKey,
			        @pnEventKey			= @nEventKey,
			        @pnEventCycle			= @nCycle,
			        @pdtEventDate			= null,
			        @pdtEventDueDate		= null,
			        @pnPolicingBatchNo		= @pnPolicingBatchNo,
			        @pbIsEventKeyInUse		= 1,
			        @pbIsEventCycleInUse	        = 1,
			        @pbIsEventDateInUse		= 1,
			        @pbIsEventDueDateInUse	        = 1	
		End	
	End
End

Return @nErrorCode
GO

Grant execute on dbo.dw_DeleteDocketData to public
GO
