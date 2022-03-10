-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateUserProfile
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateUserProfile]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateUserProfile.'
	Drop procedure [dbo].[ipw_UpdateUserProfile]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateUserProfile...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_UpdateUserProfile
(
	@pnUserIdentityId	int,		
	@psCulture		nvarchar(10) 	= null,
	@pnProfileKey           int,
	@psProfileName          nvarchar(50),
	@psDescription          nvarchar(254)   = null,
	@psOldProfileName       nvarchar(50),
	@psOldDescription       nvarchar(254)   = null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_UpdateUserProfile
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Updates information about existing user profiles.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 09 Sep 2009	LP	RFC8047	1	Procedure created
-- 12 Nov 2009  ASH RFC100089 2 Set ANSI_NULL OFF to allow the comparison of null values.
-- 15 Dec 2009  ASH RFC100089 3 Implement validations.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON


declare	@nErrorCode	int
declare @sSQLString     nvarchar(4000)
declare @sAlertXML		nvarchar(400)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
   and (@psProfileName <> @psOldProfileName or
	@psDescription <> @psOldDescription
    )
Begin
if not exists(Select 1 From PROFILES where PROFILENAME=@psProfileName) or (@psProfileName = @psOldProfileName)
Begin

	Set @sSQLString = " 
	update 	PROFILES
	set	PROFILENAME 	 = @psProfileName, 
		DESCRIPTION	 = @psDescription 		
	where	PROFILEID	 = @pnProfileKey
	and	PROFILENAME 	 = @psOldProfileName
	and	DESCRIPTION	 = @psOldDescription"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnProfileKey	        int,
					  @psProfileName        nvarchar(50),
					  @psDescription        nvarchar(254),
					  @psOldProfileName     nvarchar(50),
					  @psOldDescription     nvarchar(254)',
					  @pnProfileKey	= @pnProfileKey,
					  @psProfileName = @psProfileName,
					  @psDescription = @psDescription,
					  @psOldProfileName = @psOldProfileName,
					  @psOldDescription = @psOldDescription
					 
End
Else
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('IP100', 'The Profile Name already exists.', null, null, null, null, null)
	RAISERROR(@sAlertXML, 12, 1)
	Set @nErrorCode = 1	
End
End
Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateUserProfile to public
GO
