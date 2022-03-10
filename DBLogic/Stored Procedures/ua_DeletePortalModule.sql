-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_DeletePortalModule
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_DeletePortalModule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_DeletePortalModule.'
	Drop procedure [dbo].[ua_DeletePortalModule]
End
Print '**** Creating Stored Procedure dbo.ua_DeletePortalModule...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ua_DeletePortalModule
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnTabKey		int,		-- Mandatory
	@pnModuleKey		int		-- Mandatory	
)
as
-- PROCEDURE:	ua_DeletePortalModule
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete module from a portal

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 Nov 2007	SW	RFC5535	1	Procedure created
-- 16 Sep 2012  MS      R12650  2       If default portal module is deleted, then copy the default tabs and modules 
--                                      and then delete the required module

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)
declare @nKeyPos	int

-- Initialise variables
Set @nErrorCode = 0

-- Make a duplicate set of tabs if necessary
If @nErrorCode = 0 
and not exists (Select 1 from MODULECONFIGURATION 
                        where IDENTITYID = @pnUserIdentityId 
                        and MODULEID = @pnModuleKey
                        and TABID = @pnTabKey)
Begin
	exec @nErrorCode = ua_CopyPortalTab @pnUserIdentityId, @psCulture
		
	-- Find out the new TABID if it is copied from default.
        If @nErrorCode = 0
        Begin
	        Set @sSQLString = "
		        Select @pnTabKey = T.TABID
		        from PORTALTAB T
		        join PORTALTAB D on (D.TABNAME = T.TABNAME)
		        where D.TABID = @pnTabKey
		        and T.IDENTITYID = @pnUserIdentityId"

	        exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTabKey		int			OUTPUT,
					  @pnUserIdentityId	int',
					  @pnTabKey		= @pnTabKey		OUTPUT,
					  @pnUserIdentityId	= @pnUserIdentityId
        End
End

-- Find out the position of the module
If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select @nKeyPos = MODULESEQUENCE 	
		from MODULECONFIGURATION
		where TABID = @pnTabKey
		and MODULEID = @pnModuleKey
		"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTabKey		int,
					  @nKeyPos		int			OUTPUT,					  
					  @pnModuleKey		int',
					  @pnTabKey		= @pnTabKey,
					  @nKeyPos		= @nKeyPos		OUTPUT,					  
					  @pnModuleKey		= @pnModuleKey
End

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
			Delete from MODULECONFIGURATION
			where TABID = @pnTabKey
			and MODULEID = @pnModuleKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTabKey		int,
					  @pnModuleKey	int',
					  @pnTabKey		= @pnTabKey,
					  @pnModuleKey	= @pnModuleKey
	
End

-- Tidy up the MODULESEQUENCE of any modules >= @pnModuleKey
If @nErrorCode = 0
Begin
	Set @sSQLString = "
			Update MODULECONFIGURATION
			Set MODULESEQUENCE = MODULESEQUENCE - 1
			where TABID = @pnTabKey
			and MODULESEQUENCE > @nKeyPos"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTabKey		int,
					  @nKeyPos		int',
					  @pnTabKey		= @pnTabKey,
					  @nKeyPos		= @nKeyPos
	
End


Return @nErrorCode
GO

Grant execute on dbo.ua_DeletePortalModule to public
GO
