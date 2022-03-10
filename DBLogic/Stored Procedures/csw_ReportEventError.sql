-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ReportEventError
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ReportEventError]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ReportEventError.'
	Drop procedure [dbo].[csw_ReportEventError]
End
Print '**** Creating Stored Procedure dbo.csw_ReportEventError...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ReportEventError
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pnCaseKey				int, 			-- Mandatory
	@pnErrorEventKey		int,			-- Mandatory
	@pnCycle				smallint,	
	@pnImportBatchNo		int,
	@pnTransactionNo		int,
	@pbOnHold				bit				= null,	-- When not null, indicates that the policing request is to be placed on hold. If null, the On Hold status is determined from the @pnPolicingBatchNo.
	@pbCalledFromCentura	bit				= 0
	
)
as
-- PROCEDURE:	csw_ReportEventError
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	If Event exists for the case, updates the CASEEVENT else insert new CASEEVENT,  
--				updates IMPORTJOURNAL and insert POLICING.					

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 23 Nov 2009	NG		RFC8098	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode				int
declare @sSQLString				nvarchar(4000)
declare @sEventText				nvarchar(254)
declare @sRejectReason			nvarchar(254)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	
	Select @sRejectReason = REJECTREASON 
	from IMPORTJOURNAL 
	where IMPORTBATCHNO = @pnImportBatchNo and 
		TRANSACTIONNO = @pnTransactionNo and CASEID = @pnCaseKey
	
	If exists (select 1 from CASEEVENT where CASEID = @pnCaseKey and CYCLE = @pnCycle and EVENTNO = @pnErrorEventKey)
	-- Update Case Event
	Begin
		Update CASEEVENT
		Set EVENTDATE = getdate(),
			EVENTTEXT = @sRejectReason,
			IMPORTBATCHNO = @pnImportBatchNo
		where 	CASEID = @pnCaseKey and CYCLE = @pnCycle and EVENTNO = @pnErrorEventKey		
	End
	
	Else
	--- Insert Case Event
	Begin
		exec @nErrorCode = dbo.csw_InsertCaseEvent
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,	
				@pnCaseKey		= @pnCaseKey,			
				@pnEventKey		= @pnErrorEventKey,		
				@pnCycle		= @pnCycle,
				@pbOnHold		= @pbOnHold
	End

	--- Update Import Journal
	If exists (select 1 from IMPORTJOURNAL where IMPORTBATCHNO = @pnImportBatchNo and CASEID = @pnCaseKey 
				and TRANSACTIONNO = @pnTransactionNo)
	Begin
		Update IMPORTJOURNAL
		Set ERROREVENTNO = @pnErrorEventKey
		where IMPORTBATCHNO = @pnImportBatchNo 
			and CASEID = @pnCaseKey 
			and TRANSACTIONNO = @pnTransactionNo
	End

	If @nErrorCode = 0
	Begin
		exec @nErrorCode = ipw_InsertPolicing
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture 		= @psCulture,
			@pnCaseKey 		= @pnCaseKey,
			@pnEventKey		= @pnErrorEventKey,
			@pnCycle		= @pnCycle,
			@pnTypeOfRequest	= 3,
			@pbOnHold		= @pbOnHold
	End
	
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ReportEventError to public
GO
