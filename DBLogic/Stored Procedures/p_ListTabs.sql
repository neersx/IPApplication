---------------------------------------------------------------------------------------------
-- Creation of dbo.p_ListTabs
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[p_ListTabs]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.p_ListTabs.'
	drop procedure [dbo].[p_ListTabs]
	Print '**** Creating Stored Procedure dbo.p_ListTabs...'
	Print ''
End
go

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.p_ListTabs
(
	@pnUserIdentityId	int 		= null,
    	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE :	p_ListTabs
-- VERSION :	16
-- DESCRIPTION: Get the tabs for IdentityID if there is any data; if there is no data then get the tabs for 
-- 		the DefaultPortalID attached to the users's Role; if still no data then get any tabs that are
-- 		attached to neither an IdentityID nor a PortalID.  

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 19/06/2002	AWF			Cater for the hierarchy of searching i.e. user specified tabs/default user tabs/anonymous user
-- 03/03/2004	TM	RFC914	5	Modify the process for selecting portal data to return is as follows:
--					  	1) If there is any data defined for the IdentityID, only that data 
--						   is returned.
--					  	2) If there is any data defined for the DefaultPortalID attached to 
--						   the users’s Role, only that data is returned.
--						3) Any data that is attached to neither an IdentityID nor a PortalID.	
-- 17 Jun 2004	TM	RFC1499	6	Modify the logic to retrieve the tablist as the following:
--						1) If there is any data defined for the IdentityID (i.e. on the PortalTabConfiguration table), only that data is returned.
--						2) If there is any data defined for the DefaultPortalID attached to the user (i.e. new DefaultPortalId column on the UserIdentity table), only that data is returned.
--						3) Any data that is attached to neither an IdentityID nor a PortalID.
-- 21 Jun 2004	TM	RFC915	7	Remove all references to PortalTabConfiguration, implementing the new columns 
--					on PortalTab instead.
-- 30 Jun 2004	TM	RFC915	8	Only show the tabs that contain web parts the user has access to.
-- 15 Sep 2004	JEK	RFC886	9	Implement translation.
-- 14 Oct 2004	TM	RFC1898	10	Modify calls to the fn_PermissionsGranted to include 'CanSelect = 1' as a 'join' or 'where' condition. 
-- 15 May 2005	JEK	RFC2508	11	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 28 May 2005	JEK	RFC2642	12	Move tab selection to a derived table, and translation of tab name and exists clause into outer SQL.
-- 13 Jul 2006	SW	RFC3828	13	Pass getdate() to fn_Permission..
-- 09 Oct 2007	JCLG	RFC5664	13	Add CSSCLASSNAME
-- 10 Oct 2007	SW	RFC5426 14	Display only 1 set of tabs, default or user's.
-- 30 Apr 2008	JCLG	RFC6487	15	Get tabs only from default configuration when IdentityId is null
-- 05 Jul 2017	MF	50827	16	Change supplied by Adri from Novagraaf, to improve performance by loading a temporary table with the 
--					modules the user hase access to.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

create table #TEMPPERMGRANT (
		MODULEID	int	NOT NULL,
		CanSelect	bit	NOT NULL,
					primary key (MODULEID)
		)
	
Declare	@nErrorCode	int
Declare @sSQLString 	nvarchar(max)
Declare @sLookupCulture	nvarchar(10)
Declare	@dtToday	datetime
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @dtToday = getdate()

-- Initialise variables
Set @nErrorCode = 0


--	Populate the temporary table #TEMPPERMGRANT 
--	with ModulePermissions
if	@nErrorCode = 0
begin
	set	@sSQLString = "
	insert	into #TEMPPERMGRANT(MODULEID,CanSelect)
	select	PF.ObjectIntegerKey,PF.CanSelect
	from	dbo.fn_PermissionsGranted(@pnUserIdentityId, 'MODULE', null, null, @dtToday) PF"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnUserIdentityId	int,
				  @dtToday		datetime',
				  @pnUserIdentityId	= @pnUserIdentityId,
				  @dtToday		= @dtToday
end

-- Get the Tabs list for IdentityID if there is any data; if there is no data then get the tabs for 
-- the DefaultPortalID attached to the users's Role; if still no data then get any tabs that are
-- attached to neither an IdentityID nor a PortalID.  
-- Use #TEMPPERMGRANT instead of dbo.fn_PermissionsGranted(@pnUserIdentityId, 'MODULE', null, null, @dtToday)

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select 	"+dbo.fn_SqlTranslatedColumn('PORTALTAB','TABNAME',null,'D',@sLookupCulture,@pbCalledFromCentura)+ " as TABNAME,
		D.TABID, 
		D.CSSCLASSNAME,
		D.TABSEQUENCE
	from	(Select  distinct
			coalesce(CUSER.TABNAME, CDEF.TABNAME, CNULL.TABNAME) as TABNAME,
			coalesce(CUSER.TABNAME_TID, CDEF.TABNAME_TID, CNULL.TABNAME_TID) as TABNAME_TID,
			coalesce(CUSER.TABID, CDEF.TABID, CNULL.TABID) as TABID,
			coalesce(CUSER.CSSCLASSNAME, CDEF.CSSCLASSNAME, CNULL.CSSCLASSNAME) as CSSCLASSNAME,
			coalesce(CUSER.TABSEQUENCE, CDEF.TABSEQUENCE, CNULL.TABSEQUENCE) as TABSEQUENCE
		from	PORTALTAB C
		-- Get any data defined for the IdentityID
		left join PORTALTAB CUSER	on (CUSER.IDENTITYID = @pnUserIdentityId) 
		-- Get any data defined for the DefaultPortalID attached to the users's Role
		left join USERIDENTITY U	on (U.IDENTITYID = @pnUserIdentityId)
		left join PORTALTAB CDEF	on (CDEF.PORTALID = U.DEFAULTPORTALID and CDEF.IDENTITYID is null) 	
		-- Get any data that is attached to neither an IdentityID nor a PortalID
		left join PORTALTAB CNULL	on (CNULL.IDENTITYID is null
						and CNULL.PORTALID is  null) ) D
	-- Only show the tabs that contain web parts the user has access to.
	where exists (  Select 1
		        from MODULECONFIGURATION MC			
			join #TEMPPERMGRANT PF
				on (PF.MODULEID = MC.MODULEID
				and PF.CanSelect = 1)
			where MC.TABID = D.TABID)
	order by D.TABSEQUENCE"	

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnUserIdentityId	int,
				  @dtToday		datetime',
				  @pnUserIdentityId	= @pnUserIdentityId,
				  @dtToday		= @dtToday
End

Return @nErrorCode
GO



SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

Grant exec on dbo.p_ListTabs to public
GO
