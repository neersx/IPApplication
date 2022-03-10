-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_PermissionsForLevel
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_PermissionsForLevel') and xtype='IF')
Begin
	Print '**** Drop Function dbo.fn_PermissionsForLevel'
	Drop function [dbo].[fn_PermissionsForLevel]
End
Print '**** Creating Function dbo.fn_PermissionsForLevel...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_PermissionsForLevel
(	
	@psLevelTable 		nvarchar(30),		-- the level the permissions are held; e.g. ROLE
	@psLevelKeys 	 	nvarchar(254)   = null,	-- a comma separated list of level keys.
	@psObjectTable 		nvarchar(30),		-- the type of object; e.g. MODULE
	@pnObjectIntegerKey 	int 	     	= null, 
	@psObjectStringKey 	nvarchar(30) 	= null,
	@pdtToday		datetime
) 
RETURNS TABLE
With ENCRYPTION
AS
-- Function :	fn_PermissionsForLevel
-- VERSION :	7
-- DESCRIPTION:	Assesses and returns returns the object permissions for a specific set of roles.  
--		Used in the portal pick list filtering.
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 11 Aug 2004	TM	RFC1500	1	Function created
-- 15 Nov 2004	TM	RFC869	2	Implement a full join to fn_ValidObjects to suppress objects
--					that are not licensed to the firm.
-- 17 Nov 2004	JEK	RFC869	3	Fix ambiguous column references.
-- 22 Nov 2004	JEK	RFC869	4	Make this function encrypted because it depends on an encrypted function.
-- 01 Dec 2004	JEK	RFC2079	5	Include InternalUse/External use in join to fn_ValidObjects.
-- 24 Feb 2005	TM	RFC2369	6	Add 'collate database_default' to the join on the ObjectStringKey column
--					of the fn_ValidObjects.
-- 12 Jul 2006	SW	RFC3828	7	Add new param @pdtToday


RETURN

	select 	P.OBJECTINTEGERKEY as ObjectIntegerKey, 
		P.OBJECTSTRINGKEY  as ObjectStringKey,
		cast(SUM(CASE WHEN(P.GRANTPERMISSION&1=1)   THEN 1 ELSE 0 END) as bit) &
		~cast(SUM(CASE WHEN(P.DENYPERMISSION&1=1)   THEN 1 ELSE 0 END) as bit) as CanSelect,

		cast(SUM(CASE WHEN(P.GRANTPERMISSION&64=64)   THEN 1 ELSE 0 END) as bit) &
		~cast(SUM(CASE WHEN(P.DENYPERMISSION&64=64)   THEN 1 ELSE 0 END) as bit) as IsMandatory,
	
		cast(SUM(CASE WHEN(P.GRANTPERMISSION&8=8)   THEN 1 ELSE 0 END) as bit) &
		~cast(SUM(CASE WHEN(P.DENYPERMISSION&8=8)   THEN 1 ELSE 0 END) as bit) as CanInsert,
	
		cast(SUM(CASE WHEN(P.GRANTPERMISSION&2=2)   THEN 1 ELSE 0 END) as bit) &
		~cast(SUM(CASE WHEN(P.DENYPERMISSION&2=2)   THEN 1 ELSE 0 END) as bit) as CanUpdate,
	
		cast(SUM(CASE WHEN(P.GRANTPERMISSION&16=16) THEN 1 ELSE 0 END) as bit) &
		~cast(SUM(CASE WHEN(P.DENYPERMISSION&16=16) THEN 1 ELSE 0 END) as bit) as CanDelete,
	
		cast(SUM(CASE WHEN(P.GRANTPERMISSION&32=32) THEN 1 ELSE 0 END) as bit) &
		~cast(SUM(CASE WHEN(P.DENYPERMISSION&32=32) THEN 1 ELSE 0 END) as bit) as CanExecute
	from PERMISSIONS P
	join ROLE R		on (R.ROLEID = P.LEVELKEY
				AND P.LEVELTABLE = 'ROLE')
	join dbo.fn_ValidObjects(NULL, @psObjectTable, @pdtToday) VO 
				on ((VO.ObjectIntegerKey = P.OBJECTINTEGERKEY or
				     VO.ObjectStringKey collate database_default = P.OBJECTSTRINGKEY)
				-- Use ExternalUse objects for external roles
				-- and InternalUse objects for internal roles
				and (VO.InternalUse = ~R.ISEXTERNAL or
				     VO.ExternalUse = R.ISEXTERNAL or
				     R.ISEXTERNAL IS NULL))
	where P.LEVELTABLE = @psLevelTable
	and P.OBJECTTABLE = @psObjectTable
	and  (P.OBJECTINTEGERKEY = @pnObjectIntegerKey or @pnObjectIntegerKey is null)
	and  (P.OBJECTSTRINGKEY  = @psObjectStringKey  or @psObjectStringKey is null)
	and  (@psLevelKeys is null 
	 or exists (	Select 1
			from dbo.fn_Tokenise(@psLevelKeys, ',') LK
			where LK.Parameter = P.LEVELKEY))
	group by P.OBJECTINTEGERKEY,P.OBJECTSTRINGKEY
GO

Grant REFERENCES, SELECT on dbo.fn_PermissionsForLevel to public
GO
