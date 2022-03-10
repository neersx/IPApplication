-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_AddPortalModules
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_AddPortalModules]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_AddPortalModules.'
	Drop procedure [dbo].[ua_AddPortalModules]
End
Print '**** Creating Stored Procedure dbo.ua_AddPortalModules...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ua_AddPortalModules
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnTabKey		int,		-- Mandatory
	@psModuleKeys		nvarchar(500),	-- Mandatory	-- ModuleKeys contains a list of ModuleKey separated by a coma. This list is sorted in descendant.
	@pnBeforeModuleKey	int		= null,		-- Optionally contains the Before ModuleKey 
	@pnAfterModuleKey	int		= null		-- Optionally contains the After ModuleKey
)
as
-- PROCEDURE:	ua_AddPortalModules
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert 1 or more modules for a portal before the @pnBeforeModuleKey or after the 
--		@pnAfterModuleKey depends on what is passed in.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 Nov 2007	SW	RFC5535	1	Procedure created
-- 05 Feb 2008	SW	RFC6099	2	Bug fix
-- 17 Dec 2009	PA	RFC8568	3	Bug fix related to adding web part after another web part

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(4000)
declare @nKeyPos	int
declare @sPanelLoc	nvarchar(50)
declare @nNoOfItem	int

-- Initialise variables
Set @nErrorCode = 0
Set @sPanelLoc = 'TopPane'

-- Find out the new TABID if it is copied from default.
If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select @pnTabKey = T.TABID
		from PORTALTAB T
		join PORTALTAB D on (D.TABNAME = T.TABNAME)
		where D.TABID = @pnTabKey
		and T.IDENTITYID = @pnUserIdentityId 
		"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTabKey		int			OUTPUT,
					  @pnUserIdentityId	int',
					  @pnTabKey		= @pnTabKey		OUTPUT,
					  @pnUserIdentityId	= @pnUserIdentityId
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select @nKeyPos = MODULESEQUENCE + 
					Case when @pnAfterModuleKey is not null
					then 1
					else 0
					End
							
		from MODULECONFIGURATION
		where TABID = @pnTabKey
		and MODULEID = ISNULL(@pnBeforeModuleKey, @pnAfterModuleKey)
		"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTabKey		int,
					  @nKeyPos		int			OUTPUT,					  
					  @pnBeforeModuleKey	int,
					  @pnAfterModuleKey	int',
					  @pnTabKey		= @pnTabKey,
					  @nKeyPos		= @nKeyPos		OUTPUT,					  
					  @pnBeforeModuleKey	= @pnBeforeModuleKey,
					  @pnAfterModuleKey	= @pnAfterModuleKey
 
	Set @nKeyPos = ISNULL(@nKeyPos, 0)
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select @sPanelLoc = PANELLOCATION  
		from MODULECONFIGURATION
		where TABID = @pnTabKey
		and MODULEID = ISNULL(@pnBeforeModuleKey, @pnAfterModuleKey)
		"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTabKey		int,
					  @sPanelLoc		nvarchar(50)			OUTPUT,					  
					  @pnBeforeModuleKey	int,
					  @pnAfterModuleKey	int',
					  @pnTabKey		= @pnTabKey,
					  @sPanelLoc		= @sPanelLoc		OUTPUT,					  
					  @pnBeforeModuleKey	= @pnBeforeModuleKey,
					  @pnAfterModuleKey	= @pnAfterModuleKey
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select @nNoOfItem = count(*)	
		from dbo.fn_Tokenise(@psModuleKeys, null)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nNoOfItem		int			OUTPUT,					  
					  @psModuleKeys		nvarchar(500)',
					  @nNoOfItem		= @nNoOfItem		OUTPUT,					  
					  @psModuleKeys		= @psModuleKeys
End

-- Increment the MODULESEQUENCE of any modules >= @nKeyPos to make room.
If @nErrorCode = 0
Begin
	Set @sSQLString = "
			Update MODULECONFIGURATION
			Set MODULESEQUENCE = MODULESEQUENCE + @nNoOfItem
			where TABID = @pnTabKey
			and MODULESEQUENCE >= @nKeyPos"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTabKey		int,
					  @nKeyPos		int,
					  @nNoOfItem		int',
					  @pnTabKey		= @pnTabKey,
					  @nKeyPos		= @nKeyPos,
					  @nNoOfItem		= @nNoOfItem
	
End

-- Insert new modules and increment the MODULESEQUENCE accordingly
If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Insert into MODULECONFIGURATION (IDENTITYID, TABID, MODULEID, MODULESEQUENCE, PANELLOCATION)
		select @pnUserIdentityId, @pnTabKey, [Parameter], InsertOrder + @nKeyPos - 1, @sPanelLoc
		from dbo.fn_Tokenise(@psModuleKeys, null)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					  @pnTabKey		int,
					  @psModuleKeys		nvarchar(500),
					  @nKeyPos		int,
					  @sPanelLoc		nvarchar(50)',
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @pnTabKey		= @pnTabKey,
					  @psModuleKeys		= @psModuleKeys,
					  @nKeyPos		= @nKeyPos,
					  @sPanelLoc	= @sPanelLoc
End

Return @nErrorCode
GO

Grant execute on dbo.ua_AddPortalModules to public
GO
