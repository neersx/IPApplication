-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteFunctionSecurityRule
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteFunctionSecurityRule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteFunctionSecurityRule.'
	Drop procedure [dbo].[ipw_DeleteFunctionSecurityRule]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteFunctionSecurityRule...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_DeleteFunctionSecurityRule
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnFunctionType		int,		-- Mandatory
	@pnSequenceNo		int	-- Mandatory
)
as
-- PROCEDURE:	ipw_DeleteFunctionSecurityRule
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Deletes Function Security Rule

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Dec 2009	NG		RFC8631	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	
	Set @sSQLString = " 
		Delete	FUNCTIONSECURITY
		Where	FUNCTIONTYPE	= @pnFunctionType		
		and	SEQUENCENO	= @pnSequenceNo"

	Exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnFunctionType	int,
			  @pnSequenceNo		int',
			  @pnFunctionType	= @pnFunctionType,
			  @pnSequenceNo	= @pnSequenceNo

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteFunctionSecurityRule to public
GO
