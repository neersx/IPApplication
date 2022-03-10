SET QUOTED_IDENTIFIER OFF
GO

-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[p_ListModules]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.p_ListModules.'
	Drop procedure [dbo].[p_ListModules]
End
Print '**** Creating Stored Procedure dbo.p_ListModules...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.p_ListModules
(
	@pnUserIdentityId	int 		= null,
    	@psCulture		nvarchar(10) 	= null,
    	@pnTabID		int 		= null,
	@pbCalledFromCentura	bit		= 0
)
AS

-- PROCEDURE:	p_ListModules
-- VERSION:	21
-- SCOPE:	CPA.net
-- DESCRIPTION:	A procedure to return the modules for a given tab.
--		If no tab is provided or the requested tabID doesnt exist then modules for all tabs are returned.	
--		The process for selecting portal data to return is as follows:
--		1) If there is any data defined for the IdentityID, only that data is returned.
--		2) If there is any data defined for the DefaultPortalID attached to the users’s Role, 
--		   only that data is returned.
--		3) Any data that is attached to neither an IdentityID nor a PortalID.


-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 11 Nov 2002	JB		4	Now returns rows where the IdentityId is null 
-- 					if there are no ModuleConfiguration rows for the @pnUserIdentityId
-- 21 Feb 2003	JEK		5	RFC70 implement fn_TranslateText()
-- 13 Oct 2003	TM		6	RFC524 List Modules not returning data for other tabs.
--					Default the @pnTabID to NULL instead of 0. Return modules
--					for all the tabs if @pnTabID is null or the requested tabID 
--					does not exists. 
-- 12 Dec 2003	AWF		7	Remove Print (debug) statements
-- 03 Mar 2004	TM	RFC914	8	Modify the process for selecting portal data to return is as follows:
--					  	1) If there is any data defined for the IdentityID, only that data 
--						   is returned.
--					  	2) If there is any data defined for the DefaultPortalID attached to 
--						   the users’s Role, only that data is returned.
--						3) Any data that is attached to neither an IdentityID nor a PortalID.
-- 17 Jun 2004	TM	RFC1499	9	Modify the logic to retrieve modules for the first tab as the following:
--						1) If there is any data defined for the IdentityID (i.e. on the ModuleConfiguration table), only that data is returned.
--						2) If there is any data defined for the DefaultPortalID attached to the user (i.e. new DefaultPortalId column on the UserIdentity table), only that data is returned.
--						3) Any data that is attached to neither an IdentityID nor a PortalID.
-- 21 Jun 2004	TM	RFC915	10	Modify the logic not to use ModuleConfiguration.IdentityID or 
--					ModuleConfiguration.PortalID. The ModuleConfiguration table should be
--					accessed via TabID only.
-- 30 Jun 2004	TM	RFC915	11	Only those web parts that the user currently has access to will be shown.
-- 26 Jul 2004	TM	RFC1201	12 	Add new MODULECONFIGURATION.CONFIGURATIONID column.
-- 09 Sep 2004	JEK	RFC1695	13	Implement new version of translation.
-- 05 Oct 2004	TM	RFC1785	14	Improve performance
-- 11 Oct 2004	TM	RFC1785	15	Replace table ariable with the 'Derived Table' approach to improve performance.
-- 14 Oct 2004	TM	RFC1898	16	Modify calls to the fn_PermissionsGranted to include 'CanSelect = 1' as a 'join' or 'where' condition. 
-- 15 May 2005	JEK	RFC2508	17	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 13 Jul 2006	SW	RFC3828	18	Pass getdate() to fn_Permission..
-- 04 Dec 2009	MF	RFC8700	19	Performance problem logging in for some users resulting in a time out.
-- 11 Jan 2010	SF	RFC8700	20	Case sensitivity error
-- 16 Dec 2010  DV      RFC9855 21      Add a condition to check for IDENTITYID on the join with MODULECONFGURATION

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

--Local variables
Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)
Declare @dtToday		datetime

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
set @dtToday = getdate()

-- Initialise variables
Set @nErrorCode = 0

-- Get the modules for IdentityID if there is any data; if there is no data then get the modules for 
-- the DefaultPortalID attached to the user; if still no data then get any modules that are
-- attached to neither an IdentityID nor a PortalID.    
Begin
	Set @sSQLString = "
		Select	MC.MODULEID 		as MODULEID,"+char(10)+
"			MC.TABID		as TABID,"+char(10)+
"			MC.MODULESEQUENCE 	as MODULESEQUENCE,"+char(10)+	
"			MC.PANELLOCATION 	as PANELLOCATION,"+char(10)+
"			"+dbo.fn_SqlTranslatedColumn('MODULE','TITLE',null,'M',@sLookupCulture,@pbCalledFromCentura)+" as TITLE,"+char(10)+
"			M.CACHETIME,"+char(10)+
"			D.DESKTOPSRC,"+char(10)+
"			MC.CONFIGURATIONID"+char(10)+
"		from MODULECONFIGURATION MC"+char(10)+



		-- Only those web parts that the user currently has access to will be shown.
"		join dbo.fn_PermissionsGranted(@pnUserIdentityId, 'MODULE', null, null, @dtToday) PF"+char(10)+
"						on (PF.ObjectIntegerKey = MC.MODULEID"+char(10)+
"						and PF.CanSelect = 1)"+char(10)+
"		join MODULE M 			on (M.MODULEID = MC.MODULEID)"+char(10)+
"		join MODULEDEFINITION D 	on (D.MODULEDEFID = M.MODULEDEFID)"+char(10)+
"		join (	Select CUSER.TABID"+char(10)+
"			from PORTALTAB CUSER"+char(10)+
"			where CUSER.IDENTITYID=@pnUserIdentityId"+char(10)+
"			UNION ALL"+char(10)+
"			Select CDEF.TABID"+char(10)+
"			from USERIDENTITY U"+char(10)+
"			join PORTALTAB CDEF 		on (CDEF.PORTALID=U.DEFAULTPORTALID)"+char(10)+
"			left join PORTALTAB CUSER	on (CUSER.IDENTITYID=U.IDENTITYID)"+char(10)+
"			where U.IDENTITYID=@pnUserIdentityId"+char(10)+
"			and CUSER.IDENTITYID is null"+char(10)+
"			UNION ALL"+char(10)+
"			Select CNULL.TABID"+char(10)+
"			from PORTALTAB CNULL"+char(10)+
"			     join USERIDENTITY U	on (U.IDENTITYID    =@pnUserIdentityId)"+char(10)+
"			left join PORTALTAB CUSER	on (CUSER.IDENTITYID=U.IDENTITYID)"+char(10)+
"			left join PORTALTAB CDEF	on (CDEF.PORTALID   =U.DEFAULTPORTALID)"+char(10)+
"			where CNULL.IDENTITYID is null"+char(10)+
"			and CNULL.PORTALID     is null"+char(10)+
"			and CUSER.IDENTITYID   is null"+char(10)+
"			and CDEF.PORTALID      is null) Tabs on (Tabs.TABID = MC.TABID and (MC.IDENTITYID is null or MC.IDENTITYID = @pnUserIdentityId))"
	
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
	Set @sSQLString = @sSQLString + char(10) + "		order by MC.PANELLOCATION,"
				      + char(10) + "	     		 MC.MODULESEQUENCE"

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

Grant exec on dbo.p_ListModules to public
GO
