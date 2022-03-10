-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateDateLastChange
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateDateLastChange]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateDateLastChange.'
	Drop procedure [dbo].[csw_UpdateDateLastChange]
End
Print '**** Creating Stored Procedure dbo.csw_UpdateDateLastChange...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_UpdateDateLastChange
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int		-- Mandatory
)
as
-- PROCEDURE:	csw_UpdateDateLastChange
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update Date of Last Change event for the case.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28 Oct 2011	SF	R10553	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @dtCurrentDate	datetime

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	exec @nErrorCode = dbo.ip_GetCurrentDate
		@pdtCurrentDate		= @dtCurrentDate output, 	
		@pnUserIdentityId	= @pnUserIdentityId,            
		@psDateType		= 'A' 				
End

If @nErrorCode = 0
Begin
	exec @nErrorCode = dbo.csw_MaintainEventDate
		@pnUserIdentityId	= @pnUserIdentityId,            
		@pnCaseKey		= @pnCaseKey,
		@pnEventKey		= -14, --(Date Last Changed)
		@pnCycle		= 1,
		@pdtEventDate		= @dtCurrentDate,
		@pbIsPolicedEvent	= 0
End


Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateDateLastChange to public
GO
