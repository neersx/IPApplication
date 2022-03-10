-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_LoadCaseInstructAllowedAsync
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_LoadCaseInstructAllowedAsync]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_LoadCaseInstructAllowedAsync.'
	Drop procedure [dbo].[ipw_LoadCaseInstructAllowedAsync]
End
Print '**** Creating Stored Procedure dbo.ipw_LoadCaseInstructAllowedAsync...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_LoadCaseInstructAllowedAsync
(	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseId		int		= null,		-- Case to be loaded
	@pnDefinitionId		int		= null,		-- Specific definition to be loaded
	@psTableName		nvarchar(50) 	= null,		-- Name of table listing Cases (CASEID) to be loaded
	@pbClearExisting	bit		= 0	
)
as
-- PROCEDURE:	ipw_LoadCaseInstructAllowedAsync
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This stored proc runs asynchronously and calls ip_CaseInstructionLoadManager and
--				ip_LoadCaseInstructAllowed stored procs.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 01 Sep 2009	DV		RFC7050		1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int

-- Initialise variables
Set @nErrorCode = 0

If  @nErrorCode = 0
Begin
 	Exec @nErrorCode = [dbo].[ip_CaseInstructionLoadManager]		
			@pnUserIdentityId	= @pnUserIdentityId,
			@pnDefinitionKey		= @pnDefinitionId,
			@pbBlock		= 1
End

If  @nErrorCode = 0
Begin
 	Exec @nErrorCode = [dbo].[ip_LoadCaseInstructAllowed]		
			@pnCaseId	= @pnCaseId,
			@pnDefinitionId		= @pnDefinitionId,
			@psTableName		= @psTableName,
			@pbClearExisting = @pbClearExisting

End

If  @nErrorCode = 0
Begin
 	Exec @nErrorCode = [dbo].[ip_CaseInstructionLoadManager]		
			@pnUserIdentityId	= @pnUserIdentityId,
			@pnDefinitionKey		= @pnDefinitionId,
			@pbBlock		= 0
End
		
Return @nErrorCode

GO

Grant execute on dbo.ipw_LoadCaseInstructAllowedAsync to public
GO
