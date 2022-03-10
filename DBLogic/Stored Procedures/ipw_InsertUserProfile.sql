-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertUserProfile
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertUserProfile]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertUserProfile.'
	Drop procedure [dbo].[ipw_InsertUserProfile]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertUserProfile...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_InsertUserProfile
(
	@pnProfileKey		int		= null output,
	@pnUserIdentityId	int,		
	@psCulture		nvarchar(10) 	= null,
	@psProfileName          nvarchar(50),
	@psDescription          nvarchar(254)   = null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_InsertUserProfile
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Create a new user profile record.
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 09 Sep 2009  LP	RFC8047	1	Procedure created
-- 15 Dec 2009  ASH RFC100089 2 Implement validations.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString     nvarchar(4000)
declare @sAlertXML		nvarchar(400)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
if not exists(Select 1 From PROFILES where PROFILENAME=@psProfileName)
Begin
	Set @sSQLString = "
	INSERT INTO PROFILES(PROFILENAME,DESCRIPTION)
	values (@psProfileName, @psDescription)
	
	Set @pnProfileKey = SCOPE_IDENTITY()
	"
	exec @nErrorCode = sp_executesql @sSQLString,
		        N'@pnProfileKey         int output,
		        @psProfileName          nvarchar(50),
		        @psDescription          nvarchar(254)',
		        @pnProfileKey           = @pnProfileKey,
		        @psProfileName          = @psProfileName,
		        @psDescription          = @psDescription
	
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

Grant execute on dbo.ipw_InsertUserProfile to public
GO
