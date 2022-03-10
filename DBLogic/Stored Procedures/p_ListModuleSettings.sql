-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[p_ListModuleSettings]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.p_ListModuleSettings.'
	Drop procedure [dbo].[p_ListModuleSettings]
End
Print '**** Creating Stored Procedure dbo.p_ListModuleSettings...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.p_ListModuleSettings
(
	@pnUserIdentityId	int 		= null,
    	@psCulture		nvarchar(10) 	= null,
    	@pnTabID		int 		= null
)
AS

-- PROCEDURE:	p_ListModuleSettings
-- VERSION:	4
-- DESCRIPTION:	A procedure to return all the settings that match the MODULEIDs for the user.
--		If no tab is provided or the requested tabID doesnt exist then MODULEIDs for all tabs are returned.	
--		The process for selecting portal data to return is as follows:
--		1) If there is any data defined for the IdentityID, only that data is returned.
--		2) If there is any data defined for the DefaultPortalID attached to the users’s Role, 
--		   only that data is returned.
--		3) Any data that is attached to neither an IdentityID nor a PortalID.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 02 Nov 2004	TM	RFC390	1	Procedure created
-- 13 Jul 2006	SW	RFC3828	2	Pass getdate() to fn_Permission..
-- 04 Dec 2009	MF	RFC8700	3	Performance problem logging in for some users resulting in a time out.
-- 11 Jan 2010	SF	RFC8700	4	Case sensitivity error

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

--Local variables
Declare	@nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @dtToday	datetime

-- Initialise variables
Set @nErrorCode	= 0
Set @dtToday	= getdate()

Begin
	Set @sSQLString = "
		Select	PS.MODULEID		as 'ModuleKey',
			PS.SETTINGNAME		as 'SettingName',
			PS.SETTINGVALUE		as 'SettingValue' 
		from PORTALSETTING PS 
		join MODULECONFIGURATION MC	on (MC.MODULEID = PS.MODULEID)
		-- Only those web parts that the user currently has access to will be shown.
		join dbo.fn_PermissionsGranted(@pnUserIdentityId, 'MODULE', null, null, @dtToday) PF
						on (PF.ObjectIntegerKey = MC.MODULEID
						and PF.CanSelect = 1)		
		-- Get the ModuleIds for IdentityID if there is any data; if there is no data then 
		-- get the ModuleIds for the DefaultPortalID attached to the user; if still no data 
		-- then get any ModuleIds that are attached to neither an IdentityID nor a PortalID:
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

Grant exec on dbo.p_ListModuleSettings to public
GO
