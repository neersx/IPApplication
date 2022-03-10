-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_DeletePortalTab
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_DeletePortalTab]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_DeletePortalTab.'
	Drop procedure [dbo].[ua_DeletePortalTab]
End
Print '**** Creating Stored Procedure dbo.ua_DeletePortalTab...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ua_DeletePortalTab
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnTabKey		int,		-- Mandatory
	@psOldTabName		nvarchar(50)	= null,		
	@pnOldIdentityKey	int		= null,
	@pnOldTabSequence 	tinyint		= null,
	@pnOldPortalKey		int		= null
	
)
as
-- PROCEDURE:	ua_DeletePortalTab
-- VERSION:	3
-- DESCRIPTION:	Delete a portal tab if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 23 Jun 2004	TM	RFC915	1	Procedure created
-- 26 Nov 2004 	TM	RFC2052	2	If there are any ModuleConfiguration rows remaining for the tab, 
--					call ua_DeleteModuleConfiguration for each of them.
-- 04 Nov 2011	SF	R11502	3	Clear child links before deleting the portal tab

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode		int
declare @sSQLString 		nvarchar(4000)
declare @nConfigurationKey	int
declare @nOldModuleKey		int
declare @nOldModuleSequence	int
declare @nOldPannelLocation	nvarchar(50)

-- Initialise variables
Set @nErrorCode 		= 0

-- Delete hidden modules
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select @nConfigurationKey = min(CONFIGURATIONID)
	from MODULECONFIGURATION
	where TABID = @pnTabKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nConfigurationKey	int			output,
					  @pnTabKey		int',					
					  @nConfigurationKey	= @nConfigurationKey	output,
					  @pnTabKey		= @pnTabKey

	-- If there are any ModuleConfiguration rows remaining for the tab, 
	-- call ua_DeleteModuleConfiguration for each of them.
	
	While @nConfigurationKey is not null
	and @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Select  @nOldModuleKey 		= MODULEID,
			@nOldModuleSequence	= MODULESEQUENCE,
			@nOldPannelLocation	= PANELLOCATION
		from MODULECONFIGURATION
		where CONFIGURATIONID = @nConfigurationKey"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@nOldModuleKey	int		output,					
					  @nOldModuleSequence	int		output,
					  @nOldPannelLocation	nvarchar(50)	output,
					  @nConfigurationKey	int',					
					  @nOldModuleKey	= @nOldModuleKey		output,	
					  @nOldModuleSequence	= @nOldModuleSequence	output,
					  @nOldPannelLocation	= @nOldPannelLocation	output,
					  @nConfigurationKey	= @nConfigurationKey
		
		exec @nErrorCode = dbo.ua_DeleteModuleConfiguration
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,
				@pnConfigurationKey	= @nConfigurationKey,
				@pnOldTabKey		= @pnTabKey, 
				@pnOldModuleKey		= @nOldModuleKey,
				@pnOldModuleSequence 	= @nOldModuleSequence,
				@pnOldPannelLocation	= @nOldPannelLocation

	
		-- Extract the next remaining configurations if there are any left		
		Set @sSQLString = "
		Select @nConfigurationKey = min(CONFIGURATIONID)
		from MODULECONFIGURATION
		where TABID = @pnTabKey
		and   CONFIGURATIONID > @nConfigurationKey"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nConfigurationKey	int			output,
						  @pnTabKey		int',					
						  @nConfigurationKey	= @nConfigurationKey	output,
						  @pnTabKey		= @pnTabKey
	End				
End

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
		Update PT
		Set PT.PARENTTABID = null
    		from PORTALTAB PTPARENT
    		join PORTALTAB PT on (PT.PARENTTABID = PTPARENT.TABID)
    		where PTPARENT.TABID = @pnTabKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTabKey		int',
					  @pnTabKey		= @pnTabKey
End

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	delete PORTALTAB
	where   TABID 		= @pnTabKey
	and     TABNAME	 	= @psOldTabName		
	and	IDENTITYID 	= @pnOldIdentityKey
	and 	TABSEQUENCE	= @pnOldTabSequence
	and 	PORTALID	= @pnOldPortalKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTabKey		int,
					  @psOldTabName		nvarchar(50),					
					  @pnOldIdentityKey	int,
					  @pnOldTabSequence	tinyint,
					  @pnOldPortalKey	int',
					  @pnTabKey		= @pnTabKey,
					  @psOldTabName		= @psOldTabName,	
					  @pnOldIdentityKey	= @pnOldIdentityKey,					  
					  @pnOldTabSequence	= @pnOldTabSequence,
					  @pnOldPortalKey	= @pnOldPortalKey
End

Return @nErrorCode
GO

Grant execute on dbo.ua_DeletePortalTab to public
GO
