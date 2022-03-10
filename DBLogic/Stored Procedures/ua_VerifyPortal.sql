-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_VerifyPortal
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_VerifyPortal]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_VerifyPortal.'
	Drop procedure [dbo].[ua_VerifyPortal]
End
Print '**** Creating Stored Procedure dbo.ua_VerifyPortal...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ua_VerifyPortal
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnIdentityKey		int		= null,
	@pnPortalKey		int		= null
)
as
-- PROCEDURE:	ua_VerifyPortal
-- VERSION:	3
-- DESCRIPTION:	This procedure ensures that the data applied to the database is valid before  
--		it is committed. It receives either PortalKey or IdentityKey.
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 29 Jun 2004	TM	RFC915	1	Procedure created
-- 08 Nov 2004	TM	RFC1979	2	Test for mandatory web parts in the default portal configuration.
-- 13 Jul 2006	SW	RFC3828	3	Pass getdate() to fn_Permission..

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

Declare @sAlertXML 		nvarchar(400)

Declare @nIdentityKey		int -- The key of the user tested on mandatory modules when the PortalKey is provided.

-- Set to 1 when either Web part is mandatory for one or more users of the portal configuration
-- or when web part must be included in supplied user's configuration. 
Declare @bIsModuleRequired	bit  
Declare @sModuleTitle		nvarchar(256)
Declare @bHasPersonalConfig	bit	-- Set to true if the use has personal configuration.
Declare @nDefaultPortalId	int
Declare @dtToday		datetime

-- Initialise variables
Set @nErrorCode 		= 0
Set @bHasPersonalConfig		= 0
Set @dtToday			= getdate()

-- If PortalKey is provided, locate all the users that implement this portal.
If @pnPortalKey is not null
and @nErrorCode = 0
Begin
	-- Extract the first user that has provided portal configuration. 
	Set @sSQLString = "		
	Select @nIdentityKey = min(IDENTITYID)
	from USERIDENTITY
	where DEFAULTPORTALID = @pnPortalKey"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@nIdentityKey	int		OUTPUT,
				  @pnPortalKey	int',
				  @nIdentityKey	= @nIdentityKey	OUTPUT,
				  @pnPortalKey	= @pnPortalKey

	-- Loop through each user that has provided portal configuration and check if there are
	-- mandatory modules in for this users that are not included in their portals.
	While @nIdentityKey is not null
	and @nErrorCode = 0
	Begin
		-- Does use have personal configuration?		
		Set @sSQLString = "
		Select  @bHasPersonalConfig 	= CASE WHEN P.IDENTITYID is not null THEN 1 ELSE 0 END			
		from	USERIDENTITY UI
		left join PORTALTAB P	on (P.IDENTITYID = UI.IDENTITYID)
		where   UI.IDENTITYID = @nIdentityKey"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@bHasPersonalConfig	bit			OUTPUT,
					  @nIdentityKey		int',
					  @bHasPersonalConfig	= @bHasPersonalConfig	OUTPUT,
					  @nIdentityKey		= @nIdentityKey		

		If @bHasPersonalConfig = 1
		and @nErrorCode = 0
		Begin
			-- Set @bIsModuleRequired to 1 when web part must be included 
			-- in user's personal configuration. 
			Set @sSQLString = "				
			Select  @bIsModuleRequired 	= 1,
				@sModuleTitle		= M.TITLE
			from dbo.fn_PermissionsGranted(@nIdentityKey, 'MODULE', null, null, @dtToday) PF
			join MODULE M 			on (M.MODULEID = PF.ObjectIntegerKey)
			where PF.IsMandatory = 1
			and not exists (Select 1
					from PORTALTAB PT		
					join MODULECONFIGURATION MC 	on (MC.TABID = PT.TABID)
					where PT.IDENTITYID = @nIdentityKey
					and   MC.MODULEID = PF.ObjectIntegerKey)"
	
			exec @nErrorCode=sp_executesql @sSQLString,
					N'@bIsModuleRequired	bit			OUTPUT,
					  @sModuleTitle		nvarchar(256)		OUTPUT,
					  @nIdentityKey		int,
					  @dtToday		datetime',
					  @bIsModuleRequired	= @bIsModuleRequired	OUTPUT,
					  @sModuleTitle		= @sModuleTitle		OUTPUT,
					  @nIdentityKey		= @nIdentityKey,
					  @dtToday		= @dtToday
		End
		Else 
		-- User does not have a personal configuration
		If @nErrorCode = 0
		Begin
			-- Set @bIsModuleRequired to 1 when Web part is mandatory for 
			-- users's default portal configuration			
			Set @sSQLString = "				
			Select  @bIsModuleRequired 	= 1,
				@sModuleTitle		= M.TITLE
			from dbo.fn_PermissionsGranted(@nIdentityKey, 'MODULE', null, null, @dtToday) PF
			join MODULE M 			on (M.MODULEID = PF.ObjectIntegerKey)			
			where PF.IsMandatory = 1
			and not exists (Select 1
					from PORTALTAB PT		
					join MODULECONFIGURATION MC 	on (MC.TABID = PT.TABID)
					where PT.PORTALID = @pnPortalKey
					and   MC.MODULEID = PF.ObjectIntegerKey)"
			
			exec @nErrorCode=sp_executesql @sSQLString,
					N'@bIsModuleRequired	bit			OUTPUT,
					  @sModuleTitle		nvarchar(256)		OUTPUT,
					  @nIdentityKey		int,
					  @pnPortalKey		int,
					  @dtToday		datetime',
					  @bIsModuleRequired	= @bIsModuleRequired	OUTPUT,
					  @sModuleTitle		= @sModuleTitle		OUTPUT,
					  @nIdentityKey		= @nIdentityKey,
					  @pnPortalKey		= @pnPortalKey,
					  @dtToday		= @dtToday
		End		

		-- If module is mandatory for the user but was not included in user's portal
		-- configuration then raise an error:
		If @nErrorCode = 0 
		and @bIsModuleRequired = 1 
		Begin
			Set @sAlertXML = dbo.fn_GetAlertXML('IP37', 'Web part {0} is mandatory for one or more users of the portal configuration.',
				@sModuleTitle, null, null, null, null)
			RAISERROR(@sAlertXML, 12, 1)
			Set @nErrorCode = @@ERROR			
		End

		-- Extract the next user if there is any which has provided portal configuration.
		If @nErrorCode = 0 
		Begin
			Set @sSQLString = "	
			Select @nIdentityKey = min(IDENTITYID)
			from USERIDENTITY
			where DEFAULTPORTALID = @pnPortalKey
			and   IDENTITYID > @nIdentityKey"

			exec @nErrorCode=sp_executesql @sSQLString,
					N'@nIdentityKey	int		OUTPUT,
					  @pnPortalKey	int',
					  @nIdentityKey	= @nIdentityKey	OUTPUT,
					  @pnPortalKey	= @pnPortalKey
		End
	End	
End

-- If IdentityKey is provided, find out if there is a web part 
-- that must be included in the user's configuration.
If @pnIdentityKey is not null
and @nErrorCode = 0
Begin
	-- Does use have personal configuration?		
	Set @sSQLString = "
	Select  @bHasPersonalConfig 	= CASE WHEN P.IDENTITYID is not null THEN 1 ELSE 0 END,
		@nDefaultPortalId	= UI.DEFAULTPORTALID
	from	USERIDENTITY UI
	left join PORTALTAB P	on (P.IDENTITYID = UI.IDENTITYID)
	where   UI.IDENTITYID = @pnIdentityKey"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@bHasPersonalConfig	bit			OUTPUT,
				  @nDefaultPortalId	int			OUTPUT,
				  @pnIdentityKey	int',
				  @bHasPersonalConfig	= @bHasPersonalConfig	OUTPUT,
				  @nDefaultPortalId	= @nDefaultPortalId	OUTPUT,
				  @pnIdentityKey	= @pnIdentityKey	

	If @bHasPersonalConfig = 1
	and @nErrorCode = 0
	Begin
		-- Set @bIsModuleRequired to 1 when web part must be included 
		-- in user's personal configuration. 
		Set @sSQLString = "				
		Select  @bIsModuleRequired 	= 1,
			@sModuleTitle		= M.TITLE
		from dbo.fn_PermissionsGranted(@pnIdentityKey, 'MODULE', null, null, @dtToday) PF
		join MODULE M 			on (M.MODULEID = PF.ObjectIntegerKey)
		where PF.IsMandatory = 1
		and not exists (Select 1
				from PORTALTAB PT		
				join MODULECONFIGURATION MC 	on (MC.TABID = PT.TABID)
				where PT.IDENTITYID = @pnIdentityKey
				and   MC.MODULEID = PF.ObjectIntegerKey)"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@bIsModuleRequired	bit			OUTPUT,
				  @sModuleTitle		nvarchar(256)		OUTPUT,
				  @pnIdentityKey	int,
				  @dtToday		datetime',
				  @bIsModuleRequired	= @bIsModuleRequired	OUTPUT,
				  @sModuleTitle		= @sModuleTitle		OUTPUT,
				  @pnIdentityKey	= @pnIdentityKey,
				  @dtToday		= @dtToday
	End
	Else 
	-- User does not have a personal configuration
	If @nErrorCode = 0
	Begin
		-- Set @bIsModuleRequired to 1 when Web part is mandatory for 
		-- users's default portal configuration			
		Set @sSQLString = "				
		Select  @bIsModuleRequired 	= 1,
			@sModuleTitle		= M.TITLE
		from dbo.fn_PermissionsGranted(@pnIdentityKey, 'MODULE', null, null, @dtToday) PF
		join MODULE M 			on (M.MODULEID = PF.ObjectIntegerKey)			
		where PF.IsMandatory = 1
		and not exists (Select 1
				from PORTALTAB PT		
				join MODULECONFIGURATION MC 	on (MC.TABID = PT.TABID)
				where PT.PORTALID = @nDefaultPortalId
				and   MC.MODULEID = PF.ObjectIntegerKey)"
		
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@bIsModuleRequired	bit			OUTPUT,
				  @sModuleTitle		nvarchar(256)		OUTPUT,
				  @pnIdentityKey	int,
				  @nDefaultPortalId	int,
				  @dtToday		datetime',
				  @bIsModuleRequired	= @bIsModuleRequired	OUTPUT,
				  @sModuleTitle		= @sModuleTitle		OUTPUT,
				  @pnIdentityKey	= @pnIdentityKey,
				  @nDefaultPortalId	= @nDefaultPortalId,
				  @dtToday		= @dtToday
	End		

	-- If module is mandatory for the user but was not included in user's portal
	-- configuration then raise an error:
	If @nErrorCode = 0 
	and @bIsModuleRequired = 1 
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('IP38', 'Web part {0} must be included in your configuration.',
			@sModuleTitle, null, null, null, null)
		RAISERROR(@sAlertXML, 12, 1)
		Set @nErrorCode = @@ERROR
	End		
End

Return @nErrorCode
GO

Grant execute on dbo.ua_VerifyPortal to public
GO
