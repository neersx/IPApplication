-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_AddModuleToConfiguration
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_AddModuleToConfiguration]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_AddModuleToConfiguration.'
	Drop procedure [dbo].[ua_AddModuleToConfiguration]
End
Print '**** Creating Stored Procedure dbo.ua_AddModuleToConfiguration...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.ua_AddModuleToConfiguration
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnIdentityKey		int		= null,
	@pnPortalKey		int		= null,
	@pnModuleKey		int		-- Mandatory
)
as
-- PROCEDURE:	ua_AddModuleToConfiguration
-- VERSION:	6
-- DESCRIPTION:	This procedure adds the web part to the portal or user configuration.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 18 Aug 2004	TM	RFC1500	1	Procedure created
-- 23 Aug 2004	TM	RFC1500	2	Get the @sTabName once for both portal and user-specific configurations. 
-- 24 Nov 2004	TM	RFC2030	3	Create a RowsPerPage portal setting for the ModuleConfiguration if there is 
--					a RowsPerpage setting for the module being inserted.					
-- 25 Nov 2004 	TM	RFC2030	4	PortalSetting should have either a ModuleID or a ModuleConfigID - not both.
-- 09 Apr 2008	SF	RFC6355	5	Explicitly restricting insertion of PortalSetting to 1 row only
-- 31 Jan 2012  MS      R11786  6       Added @pnIdentityKey parameter to ua_InsertModuleConfiguration stored procedure call

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

Declare @nTabSequence		tinyint
Declare @sTabName		nvarchar(256)
Declare @nTabKey		int
Declare @nConfigurationKey	int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select @sTabName = M.TITLE
	from MODULE  M		
	where M.MODULEID = @pnModuleKey"  

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@sTabName		nvarchar(50)	output,
				  @pnIdentityKey	int,
				  @pnModuleKey		int',
				  @sTabName		= @sTabName	output,
				  @pnIdentityKey	= @pnIdentityKey,
				  @pnModuleKey		= @pnModuleKey 
End

-- Add web part to portal configuration
If @nErrorCode = 0
and @pnPortalKey is not null
Begin
	-- Get the next available tab sequence for PortalID
	Set @sSQLString = " 
	Set  	@nTabSequence 	= ISNULL((Select isnull(max(TABSEQUENCE),0)+1
					 from PORTALTAB
					 where PORTALID = @pnPortalKey), 1)" 
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nTabSequence		tinyint		output,
					  @pnPortalKey		int,
					  @pnModuleKey		int',
					  @nTabSequence		= @nTabSequence output,
					  @pnPortalKey		= @pnPortalKey,
					  @pnModuleKey		= @pnModuleKey 

	-- Add new tab
	If @nErrorCode = 0
	Begin		
		exec @nErrorCode = dbo.ua_InsertPortalTab
			@pnTabKey		= @nTabKey	output,	
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,			
			@psTabName		= @sTabName,
			@pnIdentityKey		= null,
			@pnTabSequence 		= @nTabSequence,
			@pnPortalKey		= @pnPortalKey,
			@pbPublishKey		= 0		
	End					  

	-- Add web part to tab
	If @nErrorCode = 0
	Begin		
		exec @nErrorCode = dbo.ua_InsertModuleConfiguration
			@pnConfigurationKey	= @nConfigurationKey	output,
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,			
			@pnTabKey		= @nTabKey,
			@pnModuleKey		= @pnModuleKey,
			@pnModuleSequence 	= 1,
			@psPanelLocation	= 'TopPane',
			@pbPublishKey		= 0,
			@pnIdentityKey		= null		
	End	

	-- Create a RowsPerPage portal setting for the ModuleConfiguration if there is
	-- a RowsPerpage setting for the module being inserted:
	If @nErrorCode = 0
	Begin	
		Set @sSQLString = " 
		Insert into PORTALSETTING (MODULEID, MODULECONFIGID, IDENTITYID, SETTINGNAME, SETTINGVALUE)
		Select top 1 null, @nConfigurationKey, PS.IDENTITYID, PS.SETTINGNAME, PS.SETTINGVALUE 
		from PORTALSETTING PS		
		where PS.MODULEID = @pnModuleKey
		and   PS.SETTINGNAME = 'RowsPerPage'"  

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@nConfigurationKey	int,
					  @pnModuleKey		int',
					  @nConfigurationKey	= @nConfigurationKey,
					  @pnModuleKey		= @pnModuleKey 
	End
End

-- Add web part to user-specific configuration
If @nErrorCode = 0
and @pnIdentityKey is not null
Begin
	-- Reset the @nTabKey
	Set @nTabKey = null
	
	-- Get the next available tab sequence for IdentityID.
	Set @sSQLString = " 
	Set  	@nTabSequence 	= ISNULL((Select isnull(max(TABSEQUENCE),0)+1
					 from PORTALTAB
					 where IDENTITYID = @pnIdentityKey), 1)" 
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nTabSequence		tinyint		output,
					  @pnIdentityKey	int,
					  @pnModuleKey		int',
					  @nTabSequence		= @nTabSequence output,
					  @pnIdentityKey	= @pnIdentityKey,
					  @pnModuleKey		= @pnModuleKey 	

	-- Add new tab
	If @nErrorCode = 0
	Begin		
		exec @nErrorCode = dbo.ua_InsertPortalTab
			@pnTabKey		= @nTabKey	output,	
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,			
			@psTabName		= @sTabName,
			@pnIdentityKey		= @pnIdentityKey,
			@pnTabSequence 		= @nTabSequence,
			@pnPortalKey		= null,
			@pbPublishKey		= 0		
	End					  

	-- Add web part to tab
	If @nErrorCode = 0
	Begin		
		exec @nErrorCode = dbo.ua_InsertModuleConfiguration
			@pnConfigurationKey	= @nConfigurationKey	output,
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,			
			@pnTabKey		= @nTabKey,
			@pnModuleKey		= @pnModuleKey,
			@pnModuleSequence 	= 1,
			@psPanelLocation	= 'TopPane',
			@pbPublishKey		= 0,
			@pnIdentityKey		= @pnIdentityKey		
	End	

	-- Create a RowsPerPage portal setting for the ModuleConfiguration if there is
	-- a RowsPerpage setting for the module being inserted:
	If @nErrorCode = 0
	Begin	
		Set @sSQLString = " 
		Insert into PORTALSETTING (MODULEID, MODULECONFIGID, IDENTITYID, SETTINGNAME, SETTINGVALUE)
		Select top 1 null, @nConfigurationKey, PS.IDENTITYID, PS.SETTINGNAME, PS.SETTINGVALUE 
		from PORTALSETTING PS		
		where PS.MODULEID = @pnModuleKey
		and   PS.SETTINGNAME = 'RowsPerPage'"  

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@nConfigurationKey	int,
					  @pnModuleKey		int',
					  @nConfigurationKey	= @nConfigurationKey,
					  @pnModuleKey		= @pnModuleKey
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ua_AddModuleToConfiguration to public
GO