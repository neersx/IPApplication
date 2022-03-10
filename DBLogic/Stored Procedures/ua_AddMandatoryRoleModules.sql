-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_AddMandatoryRoleModules
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_AddMandatoryRoleModules]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_AddMandatoryRoleModules.'
	Drop procedure [dbo].[ua_AddMandatoryRoleModules]
End
Print '**** Creating Stored Procedure dbo.ua_AddMandatoryRoleModules...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.ua_AddMandatoryRoleModules
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnRoleKey		int		-- Mandatory
)
as
-- PROCEDURE:	ua_AddMandatoryRoleModules
-- VERSION:	4
-- DESCRIPTION:	This procedure checks across all the users that might be affected by a change 
--		in the mandatory permissions for the role. If there is a mandatory web part 
--		missing from any portal or user configuration, add the web part to the affected 
--		configuration.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 18 Aug 2004	TM	RFC1500	1	Procedure created
-- 23 Aug 2004	TM	RFC1500	2	Extract and store the user's default portal id and the HasPersonalConfig flag
--					in the @tblAffectedUsers table variable. Remove unnecessary UserIdentity table
--					when checking whether the mandatory module is present in the user's default 
--					portal configuration. 
-- 13 Jul 2006	SW	RFC3828	3	Pass getdate() to fn_Permission..
-- 03 Dec 2007	vql	RFC5909	4	Change RoleKey and DocumentDefId from smallint to int.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

Declare @tblAffectedUsers	table(	AffectedUserID		int,
					UsersDefaultPortal	int,
					HasPersonalConfig	bit)

Declare @tblAffectedModules	table(	AffectedModuleID	int)
Declare @nCurrentUser		int
Declare @nUsersDefaultPortal	int	-- The default portal of the user
Declare @nCurrentModule		int
Declare @bHasPersonalConfig	bit	-- Set to 1 if the user has a personal configuration
Declare @dtToday		datetime

-- Initialise variables
Set @nErrorCode 		= 0
Set @dtToday			= getdate()

-- Located affected users and their configuration details (Role is attached to the user)
If @nErrorCode = 0
Begin
	Insert into @tblAffectedUsers (AffectedUserID, UsersDefaultPortal, HasPersonalConfig) 
	Select distinct IR.IDENTITYID, UI.DEFAULTPORTALID, CAST(PT.IDENTITYID as bit)  
	from IDENTITYROLES IR 
	join USERIDENTITY UI	on (UI.IDENTITYID = IR.IDENTITYID)
	left join PORTALTAB PT	on (PT.IDENTITYID = IR.IDENTITYID)   
	where ROLEID = @pnRoleKey					  

	Set @nErrorCode	= @@Error
End

If @nErrorCode = 0
Begin
	-- Get the first affected user id from the table variable: 
	Select @nCurrentUser = min(AffectedUserID)
	from @tblAffectedUsers	

	While @nCurrentUser is not null	
	and @nErrorCode = 0
	Begin		
		-- Clean the table from the previous data
		Delete from @tblAffectedModules
		
		-- Locate affected modules:
		Insert into @tblAffectedModules (AffectedModuleID) 
		select  ObjectIntegerKey 
		from dbo.fn_PermissionsGranted (@nCurrentUser, 'MODULE', NULL, NULL, @dtToday)
		where IsMandatory = 1 
	
		Set @nErrorCode = @@Error
	
		If @nErrorCode = 0
		Begin
			Select 	@nUsersDefaultPortal    = UsersDefaultPortal,
				@bHasPersonalConfig	= HasPersonalConfig
			from @tblAffectedUsers
			where AffectedUserID = @nCurrentUser		
	
			-- Get the first affected module id from the table variable: 
			Select @nCurrentModule = min(AffectedModuleID)
			from @tblAffectedModules
		End 
		
		While @nCurrentModule is not null
		and @nErrorCode = 0
		Begin 	
			-- If the web part is mandatory web part that is not implemented in 
			-- default configuration then add web part to portal configuration:
			If not exists ( select 1 
					from PORTALTAB T 	  
					join MODULECONFIGURATION M on (M.TABID = T.TABID)
					where T.PORTALID = @nUsersDefaultPortal
					and   M.MODULEID = @nCurrentModule)			
			Begin
				-- Add web part to portal configuration
				exec @nErrorCode = dbo.ua_AddModuleToConfiguration					
					@pnUserIdentityId	= @pnUserIdentityId,
					@psCulture		= @psCulture,	
					@pnIdentityKey		= null,
					@pnPortalKey		= @nUsersDefaultPortal,
					@pnModuleKey		= @nCurrentModule									
			End
	
			-- If the user has a personal configuration and a mandatory web part is 
			-- not present already then add web part to user-specific configuration. 
			If @bHasPersonalConfig = 1
			and not exists (select 1
					from PORTALTAB T
					join MODULECONFIGURATION M on (M.TABID = T.TABID)
					where T.IDENTITYID = @nCurrentUser 
					and M.MODULEID = @nCurrentModule)
			Begin
				-- Add web parts to personal configuration
				exec @nErrorCode = dbo.ua_AddModuleToConfiguration					
					@pnUserIdentityId	= @pnUserIdentityId,
					@psCulture		= @psCulture,	
					@pnIdentityKey		= @nCurrentUser,
					@pnPortalKey		= null,
					@pnModuleKey		= @nCurrentModule
			End
	
			-- Get the next affected module id from the table variable: 
			Select @nCurrentModule = min(AffectedModuleID)
			from @tblAffectedModules
			where AffectedModuleID > @nCurrentModule
		End	
		
		-- Get the next affected user id from the table variable: 
		Select @nCurrentUser = min(AffectedUserID)
		from @tblAffectedUsers
		where AffectedUserID > @nCurrentUser		
	End	
End			


Return @nErrorCode
GO

Grant execute on dbo.ua_AddMandatoryRoleModules to public
GO