-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteUserProfile
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteUserProfile]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteUserProfile.'
	Drop procedure [dbo].[ipw_DeleteUserProfile]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteUserProfile...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_DeleteUserProfile
(
	@pnUserIdentityId	int,		
	@psCulture		nvarchar(10) 	= null,
	@pnProfileKey           int,
	@psOldProfileName       nvarchar(50)    = null,
	@psOldDescription       nvarchar(254)   = null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_DeleteUserProfile
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Deletes an existing user profile record.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------		------	-------	----------------------------------------------- 
-- 09 Sep 2009	LP	RFC8047		1	Procedure created
-- 26 Jul 2010	DV	RFC100308	2	Add additional check for DESCRIPTION if it is null initially

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString     nvarchar(4000)
declare @sAlertXML    nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Delete from PROFILES
	where PROFILEID = @pnProfileKey
	and PROFILENAME = @psOldProfileName
	and (DESCRIPTION = @psOldDescription 
		or (DESCRIPTION is null and @psOldDescription is null))
	"
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnProfileKey	int,
					  @psOldProfileName nvarchar(50),
					  @psOldDescription nvarchar(254)',
					  @pnProfileKey	= @pnProfileKey,
					  @psOldProfileName = @psOldProfileName,
					  @psOldDescription = @psOldDescription
End

If @nErrorCode != 0
Begin
        Set @sAlertXML = dbo.fn_GetAlertXML(null, 'The user profile cannot be deleted as it is currently being used.',
		null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteUserProfile to public
GO
