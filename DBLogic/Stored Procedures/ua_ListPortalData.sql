-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_ListPortalData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_ListPortalData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_ListPortalData.'
	Drop procedure [dbo].[ua_ListPortalData]
End
Print '**** Creating Stored Procedure dbo.ua_ListPortalData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ua_ListPortalData
(
	@pbIsNewConfiguration	bit		= null OUTPUT,	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnIdentityKey		int		= null,
	@pnPortalKey		int		= null
)
as
-- PROCEDURE:	ua_ListPortalData
-- VERSION:	14
-- DESCRIPTION:	Populates the PortalData and MyPortalData datasets. 

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 22 Jun 2004	TM	RFC915	1	Procedure created
-- 14 Jul 2004	TM	RFC916	2	The ModuleConfiguration table is populated with modules that the IdentityKey 
--					has access to. The PortalTab table is populated for portal tabs where there 
--					are modules present.
-- 17 Sep 2004	TM	RFC916	3	For an individual filter the ConfigurationSetting so that they only include 
--					modules returned in the earlier result set.
-- 05 Oct 2004	TM	RFC1785	4	Improve performance.
-- 11 Oct 2004	TM	RFC1785	5	Use @tblTabs table variable in the PortalTab result set. Correct the tabs 
--					extraction logic.
-- 14 Oct 2004	TM	RFC1898	6	Modify calls to the fn_PermissionsGranted to include 'CanSelect = 1' 
--					as a 'join' or 'where' condition. 
-- 16 Nov 2004	TM	RFC869	7	When a PortalKey has been provided, restrict the ModuleConfiguration and 
--					ConfigurationSetting result sets via a full join to fn_ValidObjects to web 
--					parts that are licensed to the firm.
-- 19 Nov 2004	TM	RFC869	8	Improve performance.
-- 01 Dec 2004	JEK	RFC2079	9	Include InternalUse/External use in join to fn_ValidObjects.
-- 12 Jul 2006	SW	RFC3828	10	Pass getdate() to fn_Permission..
-- 2 Dec 2008	SF	RFC7380	11	Filter out user specific configuration data when portal key is provided.
-- 27 Apr 10	DL	18642	12	Change non-integer constant in order by clause.
--					Note: this change will ensure SQL Server Upgrade Advisor will not 
--					display warning message from this stored procedure due to use of non-integer constant in the order by clause.
-- 03 Sep 2015	DV	R50260	13	Add null check on ModuleConfiguration also when getting default settings
-- 29 Dec 2017  DV	R73211	14	Return IsReadOnly for Module settings based on Maintain Custom Content Access task security


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)

Declare @tblTabs 	table ( TabId 	int)
Declare @nRowCount 	int
Declare @dtToday	datetime
declare @bCanMaintainCustomContentAccess bit

declare @tblValidModules table (TABID		int,
				TABNAME		nvarchar(50)	collate database_default,
				TABSEQUENCE	tinyint,
				PORTALID	int,
				IDENTITYID	int,
				CONFIGURATIONID	int,
			        MODULEID 	int,			        
				MODULETITLE	nvarchar(254)	collate database_default,
				MODDESCRIPTION	nvarchar(254)	collate database_default,
				PANELLOCATION	nvarchar(50)	collate database_default,
				MODULESEQUENCE	int)
-- Initialise variables
Set @nErrorCode = 0
Set @dtToday = getdate()
SET @bCanMaintainCustomContentAccess = 0

If @nErrorCode = 0
Begin
Set @sSQLString = "Select @bCanMaintainCustomContentAccess = 1
	from dbo.fn_PermissionsGranted(@pnUserIdentityId, 'TASK', 273, null, @dtToday) PG
	where PG.CanExecute = 1"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@bCanMaintainCustomContentAccess	bit				OUTPUT,
					  @pnUserIdentityId		int,
					  @dtToday datetime',
					  @bCanMaintainCustomContentAccess	= @bCanMaintainCustomContentAccess	OUTPUT,
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @dtToday = @dtToday
End

-- Populating PortalData
If @pnPortalKey is not null
Begin
	-- When a PortalKey has been provided, restrict the ModuleConfiguration and 
	-- ConfigurationSetting result sets to web parts that are licensed to the firm.
	If @nErrorCode = 0
	Begin
		Insert into @tblValidModules (TABID, TABNAME, TABSEQUENCE, PORTALID, IDENTITYID, CONFIGURATIONID, 
					      MODULEID, MODULETITLE, MODDESCRIPTION, PANELLOCATION, MODULESEQUENCE)
		Select  PT.TABID, PT.TABNAME, PT.TABSEQUENCE, PT.PORTALID, PT.IDENTITYID, MC.CONFIGURATIONID,
			MC.MODULEID, M.TITLE, M.DESCRIPTION, MC.PANELLOCATION, MC.MODULESEQUENCE
		from PORTAL P
		join PORTALTAB PT		on (P.PORTALID = PT.PORTALID)
		join MODULECONFIGURATION MC 	on (MC.TABID = PT.TABID)
		join dbo.fn_ValidObjects(null, 'MODULE', @dtToday) VO
						on (VO.ObjectIntegerKey = MC.MODULEID
						-- Use ExternalUse objects for external users
						-- and InternalUse objects for internal users
						and (VO.InternalUse = ~P.ISEXTERNAL or
						     VO.ExternalUse = P.ISEXTERNAL))	
		join MODULE M			on (M.MODULEID = MC.MODULEID)
		where P.PORTALID = @pnPortalKey 

		Set @nErrorCode = @@Error
	End

	-- Portal result set
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Select  PORTALID	as 'PortalKey',
			NAME		as 'PortalName',
			DESCRIPTION	as 'Description',
			ISEXTERNAL 	as 'IsExternal'
		from PORTAL
		where PORTALID = @pnPortalKey"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnPortalKey	int',
						  @pnPortalKey	= @pnPortalKey
	End
	
	-- PortalTab result set
	If @nErrorCode = 0
	Begin
		Select  DISTINCT
			VM.TABID		as 'TabKey',
			VM.TABNAME		as 'TabName',
			VM.TABSEQUENCE	as 'TabSequence',
			VM.PORTALID 	as 'PortalKey',
			VM.IDENTITYID	as 'IdentityKey'
		from @tblValidModules VM
		join PORTALTAB PT on (PT.TABID = VM.TABID
							-- Since the portal is not for a specific user, 
							-- user-specific data cannot be selected.
							and PT.IDENTITYID is null)
		order by VM.TABSEQUENCE	
	End
	
	-- ModuleConfiguration result set
	If @nErrorCode = 0
	Begin
		Select  VM.CONFIGURATIONID	as 'ConfigurationKey',
			VM.TABID		as 'TabKey',
			VM.MODULEID	as 'ModuleKey',
			VM.MODULETITLE 	as 'Title',
			VM.MODDESCRIPTION	as 'Description',
			VM.PANELLOCATION	as 'PanelLocation',
			VM.MODULESEQUENCE	as 'ModuleSequence'
		from @tblValidModules VM		      	
		join MODULECONFIGURATION MC on (MC.CONFIGURATIONID = VM.CONFIGURATIONID
							-- Since the portal is not for a specific user, 
							-- user-specific data cannot be selected.
							and MC.IDENTITYID is null)		
		order by VM.PANELLOCATION, VM.MODULESEQUENCE

		Set @nErrorCode = @@Error	
	End
	
	-- ConfigurationSetting result set
	If @nErrorCode = 0
	Begin
		Select  PS.SETTINGID		as 'SettingKey',
			PS.MODULECONFIGID	as 'ConfigurationKey',
			PS.SETTINGNAME		as 'SettingName',
			PS.SETTINGVALUE 	as 'SettingValue',
			cast((CASE WHEN PS.SETTINGNAME = 'ParentAccessAllowed' and @bCanMaintainCustomContentAccess = 0 THEN  1 ELSE 0 END) as bit) as 'IsReadOnly'
		from @tblValidModules MC
		join PORTALSETTING PS		on (PS.MODULECONFIGID = MC.CONFIGURATIONID
						-- Since the portal is not for a specific user, 
						-- user-specific data cannot be selected.
						and PS.IDENTITYID is null and MC.IDENTITYID is null)		
		order by PS.MODULECONFIGID, PS.SETTINGNAME	
		
		Set @nErrorCode = @@Error
	End
End

-- Populating MyPortalData 

-- If there is an existing user-specific configuration, this is returned. If there is none, 
-- the user’s default configuration is extracted and adjusted ready to insert as a new 
-- user-specific configuration. An output parameter @pbIsNewConfiguration is used to 
-- communicate the status.	
Else if @pnIdentityKey is not null
Begin
	-- An existing user-specific configuration is extracted as the follow:
	-- 1) Extracted from the PortalTab and ModuleConfiguration tables which have 
	--    the supplied IdentityKey.

	-- The PortalTab and ModuleConfguration tables for a new user-specific configuration 
	-- are populated as follows:
	-- 2) All the data for the user’s default portal configuration. This is located using 
	--    UserIdentity.DefaultPortalId.
	-- 3) If not found, any data with neither IdentityID nor PortalID.

	Insert into @tblTabs
	select C.TABID 
	from PORTALTAB C	
	where C.IDENTITYID = @pnIdentityKey
	
	Select  @nErrorCode = @@Error,
		@nRowCount = @@RowCount
	
	If @nRowCount = 0
	and @nErrorCode = 0
	Begin
		Insert into @tblTabs
		select C.TABID 
		from USERIDENTITY U
		join PORTALTAB C on (C.PORTALID = U.DEFAULTPORTALID)
		where U.IDENTITYID = @pnIdentityKey
		
		Select  @nErrorCode = @@Error,
			@nRowCount = @@RowCount	
	End
	
	If @nRowCount = 0
	and @nErrorCode = 0
	Begin
		Insert into @tblTabs
		select C.TABID 
		from PORTALTAB C	
		where C.IDENTITYID is null
		and C.PORTALID is  null	
		
		Select  @nErrorCode = @@Error,
			@nRowCount = @@RowCount	
	End


	-- User result set
	If @nErrorCode = 0
	Begin	
		Select @pnIdentityKey as 'IdentityKey'
	End
	
	-- PortalTab result set
	If @nErrorCode = 0
	Begin
		Select  TAB.TabId	as 'TabKey',
			C.TABNAME	as 'TabName',
			C.TABSEQUENCE   as 'TabSequence',
			C.PORTALID      as 'PortalKey',
			@pnIdentityKey 	as 'IdentityKey'
		from	@tblTabs TAB
		join PORTALTAB C 	on (C.TABID = TAB.TabId)
		-- Only show the tabs that contain web parts the user has access to.
		where exists (  Select 1
			        from MODULECONFIGURATION MC			
				join dbo.fn_PermissionsGranted(@pnIdentityKey, 'MODULE', null, null, @dtToday) PF
						on (PF.ObjectIntegerKey = MC.MODULEID
						and PF.CanSelect = 1)
				where MC.TABID = TAB.TabId)
-- SQA18642 Change non-integer constant 'TabSequence' with proper name
		order by [TabSequence]
	End
	
	-- ModuleConfiguration result set
	If @nErrorCode = 0
	Begin
		Select  MC.CONFIGURATIONID 	as 'ConfigurationKey',
			MC.TABID 		as 'TabKey',
			MC.MODULEID		as 'ModuleKey',
			M.TITLE 		as 'Title',
			M.DESCRIPTION 		as 'Description',
			MC.PANELLOCATION 	as 'PanelLocation',
			MC.MODULESEQUENCE	as 'ModuleSequence'
		from MODULECONFIGURATION MC
		-- Only those web parts that the user currently has access to will be shown.
		join dbo.fn_PermissionsGranted(@pnIdentityKey, 'MODULE', null, null, @dtToday) PF
						on (PF.ObjectIntegerKey = MC.MODULEID
						and PF.CanSelect = 1)
		join MODULE M 			on (M.MODULEID = MC.MODULEID)
		join @tblTabs TAB		on (TAB.TabId = MC.TABID)
-- SQA18642 Change non-integer constant 'PanelLocation', 'ModuleSequence' with proper column name
		order by [PanelLocation], [ModuleSequence]	
	End
	
	-- ConfigurationSetting result set
	If @nErrorCode = 0
	Begin
		Select  PS.SETTINGID		as 'SettingKey',
			PS.MODULECONFIGID	as 'ConfigurationKey',
			PS.SETTINGNAME		as 'SettingName',
			PS.SETTINGVALUE 	as 'SettingValue',
			cast((CASE WHEN PS.SETTINGNAME = 'ParentAccessAllowed' and @bCanMaintainCustomContentAccess = 0 THEN  1 ELSE 0 END) as bit) as 'IsReadOnly'
		from PORTALSETTING PS
		join  MODULECONFIGURATION MC	on (MC.CONFIGURATIONID = PS.MODULECONFIGID)
		-- Only those web parts that the user currently has access to will be shown.
		join dbo.fn_PermissionsGranted(@pnIdentityKey, 'MODULE', null, null, @dtToday) PF
						on (PF.ObjectIntegerKey = MC.MODULEID
						and PF.CanSelect = 1)
		join @tblTabs TAB		on (TAB.TabId = MC.TABID)	
		-- The entire configuration is user-specific
		and PS.IDENTITYID is null
-- SQA18642 Change non-integer constant ('ConfigurationKey', 'SettingName') with proper column name
		order by [ConfigurationKey], [SettingName]	
	End

	-- If there is an existing user-specific configuration, set @pbIsNewConfiguration to 0.
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Select  @pbIsNewConfiguration = 0
		from PORTALTAB P
		join MODULECONFIGURATION MC 	on (MC.TABID = P.TABID)
		where P.IDENTITYID = @pnIdentityKey"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pbIsNewConfiguration bit			OUTPUT,
						  @pnIdentityKey	int',
						  @pbIsNewConfiguration = @pbIsNewConfiguration OUTPUT,
						  @pnIdentityKey	= @pnIdentityKey
	
	End

	-- If @pbIsNewConfiguration was not set to 0 then there is no user-specific configuration
	-- so set @pbIsNewConfiguration to 1.
	If @nErrorCode = 0
	Begin
		Set @pbIsNewConfiguration = ISNULL(@pbIsNewConfiguration,1)			
	End
	
End

Return @nErrorCode
GO

Grant execute on dbo.ua_ListPortalData to public
GO
