-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[p_ListModuleConfigSettings]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.p_ListModuleConfigSettings.'
	Drop procedure [dbo].[p_ListModuleConfigSettings]
End
Print '**** Creating Stored Procedure dbo.p_ListModuleConfigSettings...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.p_ListModuleConfigSettings
(
	@pnUserIdentityId	int 		= null,
    	@psCulture		nvarchar(10) 	= null,
    	@pnTabID		int 		= null
)
AS

-- PROCEDURE:	p_ListModuleConfigSettings
-- VERSION:	8
-- DESCRIPTION:	A procedure to return all the settings that match the CONFIGURATIONIDs for the user.
--		If no tab is provided or the requested tabID doesnt exist then CONFIGURATIONIDs for all tabs are returned.	
--		The process for selecting portal data to return is as follows:
--		1) If there is any data defined for the IdentityID, only that data is returned.
--		2) If there is any data defined for the DefaultPortalID attached to the users?s Role, 
--		   only that data is returned.
--		3) Any data that is attached to neither an IdentityID nor a PortalID.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 27 Jul 2004	TM	RFC1201	1	Procedure created
-- 05 Oct 2004	TM	RFC1785	2	Improve performance
-- 05 Oct 2004	TM	RFC1785	3	Improve performance
-- 11 Oct 2004	TM	RFC1785	4	Replace table ariable with the 'Derived Table' approach to improve performance.
-- 14 Oct 2004	TM	RFC1898	5	Modify calls to the fn_PermissionsGranted to include 'CanSelect = 1' as a 'join' 
--					or 'where' condition. 
-- 13 Jul 2006	SW	RFC3828	6	Pass getdate() to fn_Permission..
-- 04 Dec 2009	MF	RFC8700	7	Performance problem logging in for some users resulting in a time out.
-- 11 Jan 2010	SF	RFC8700	8	Case sensitivity error

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

--Local variables
Declare	@nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @dtToday	datetime

-- Initialise variables
Set @nErrorCode = 0
Set @dtToday = getdate()

Begin
	Set @sSQLString = "
		Select	PS.MODULECONFIGID	as 'ConfigurationKey',
			PS.SETTINGNAME		as 'SettingName',
			PS.SETTINGVALUE		as 'SettingValue' 
		from PORTALSETTING PS 
		join MODULECONFIGURATION MC	on (MC.CONFIGURATIONID = PS.MODULECONFIGID)
		-- Only those web parts that the user currently has access to will be shown.
		join dbo.fn_PermissionsGranted(@pnUserIdentityId, 'MODULE', null, null, @dtToday) PF
						on (PF.ObjectIntegerKey = MC.MODULEID
						and PF.CanSelect = 1)		
		-- Get the ModuleConfigurations for IdentityID if there is any data; if there is no data then 
		-- get the ModuleConfigurations for the DefaultPortalID attached to the user; if still no data 
		-- then get any ModuleConfigurations that are attached to neither an IdentityID nor a PortalID:
		join (	Select CUSER.TABID
			from PORTALTAB CUSER
			where CUSER.IDENTITYID=@pnUserIdentityId
			UNION ALL
			Select CDEF.TABID
			from USERIDENTITY U
			join PORTALTAB CDEF 		on (CDEF.PORTALID=U.DEFAULTPORTALID)
			left join PORTALTAB CUSER	on (CUSER.IDENTITYID=U.IDENTITYID)
			where U.IDENTITYID=@pnUserIdentityId
			and CUSER.IDENTITYID is null
			UNION ALL
			Select CNULL.TABID
			from PORTALTAB CNULL
			     join USERIDENTITY U	on (U.IDENTITYID    =@pnUserIdentityId)
			left join PORTALTAB CUSER	on (CUSER.IDENTITYID=U.IDENTITYID)
			left join PORTALTAB CDEF	on (CDEF.PORTALID   =U.DEFAULTPORTALID)
			where CNULL.IDENTITYID is null
			and CNULL.PORTALID     is null
			and CUSER.IDENTITYID   is null
			and CDEF.PORTALID      is null) Tabs on (Tabs.TABID = MC.TABID)"

		-- If the requested tabID exists then include @pnTabID in the where clause. 
		If @pnTabID  is not null
		and exists(select * from MODULECONFIGURATION where TABID = @pnTabID) 
		Begin
			Set @sSQLString = @sSQLString + char(10) + "		and MC.TABID = @pnTabID"
			
			Set @nErrorCode = @@Error 
		End					
End

If @nErrorCode = 0
Begin
	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnUserIdentityId	int,
				  @pnTabID 		int,
				  @dtToday		datetime',
				  @pnUserIdentityId	= @pnUserIdentityId,
				  @pnTabID		= @pnTabID,
				  @dtToday		= @dtToday
End

Return @nErrorCode

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

Grant exec on dbo.p_ListModuleConfigSettings to public
GO
