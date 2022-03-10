-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteOrModifyWindowModuleUser
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteOrModifyWindowModuleUser]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteOrModifyWindowModuleUser.'
	Drop procedure [dbo].[ipw_DeleteOrModifyWindowModuleUser]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteOrModifyWindowModuleUser...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ipw_DeleteOrModifyWindowModuleUser]
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnIdentityKey	int,	-- Mandatory
	@pbDeleteWindowModuleUser	bit 		= 0		
)
AS
-- PROCEDURE:	ipw_DeleteOrModifyWindowModuleUser
-- VERSION:	2
-- DESCRIPTION:	Delete or modify the Window Module user.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 04-Mar-2010	PS	RFC100135	1	Procedure created
-- 04-Mar-2011	DV	RFC10138	2	Fixed issue where the user was not getting deleted due to reference constraint

-- set server options
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Declare variables
Declare	@nErrorCode		int
Declare @sSQLString				nvarchar(4000)

-- initialise variables	
Set @nErrorCode			= 0

If @nErrorCode = 0 
Begin
	if @pbDeleteWindowModuleUser = 0
	Begin
		Set @sSQLString = "
		Update USERS
		Set IDENTITYID = null
		Where IDENTITYID = @pnIdentityKey"
		exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnIdentityKey		int',
				  @pnIdentityKey	= @pnIdentityKey		 
	End
	Else
	Begin
		Set @sSQLString = "DELETE REPORTS where 
	                       USERID = (SELECT USERID from USERS 
						   where IDENTITYID = @pnIdentityKey)"	                           
        exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnIdentityKey		int',
			  @pnIdentityKey	= @pnIdentityKey 
		
		If @nErrorCode = 0 
        Begin
			Set @sSQLString = "DELETE IRALLOCATION where 
	                           USERID = (SELECT USERID from USERS 
							   where IDENTITYID = @pnIdentityKey)"	                           
	        exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnIdentityKey		int',
				  @pnIdentityKey	= @pnIdentityKey 		  
				  
		End

		If @nErrorCode = 0 
        Begin
			Set @sSQLString = "
			Delete From USERS
			Where IDENTITYID = @pnIdentityKey"	
			exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnIdentityKey		int',
					  @pnIdentityKey	= @pnIdentityKey
		End
	End
	
End

RETURN @nErrorCode
GO

Grant execute on dbo.ipw_DeleteOrModifyWindowModuleUser to public
GO