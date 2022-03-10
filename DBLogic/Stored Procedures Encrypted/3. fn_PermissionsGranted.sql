-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_PermissionsGranted
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_PermissionsGranted') and xtype='IF')
Begin
	Print '**** Drop Function dbo.fn_PermissionsGranted'
	Drop function [dbo].[fn_PermissionsGranted]
End
Print '**** Creating Function dbo.fn_PermissionsGranted...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_PermissionsGranted
(	
	@pnIdentityKey 		int,				-- the key of the user who's permissions are required
	@psObjectTable 		nvarchar(30),			-- the type of object; e.g. TASK
	@pnObjectIntegerKey 	int 	     	= null, 	-- Optional
	@psObjectStringKey 	nvarchar(30) 	= null,		-- Optional
	@pdtToday		datetime
) 
RETURNS TABLE
With ENCRYPTION
AS
-- Function :	fn_PermissionsGranted
-- VERSION :	10
-- DESCRIPTION:	Assesses and returns the permissions for a particular object/objects for a user
--		who's permissions are required (i.e. the user's writes to perform Select, Update,
--		Delete, Insert, Execute for the particular Task). 
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16 Jun 2004	TM	RFC1085	1	Function created
-- 17 Jun 2004	MF		2	Improved performance	
-- 22 Jun 2004	TM	RFC1085	3	Add new IsMandatory column.
-- 15 Nov 2004	TM	RFC869	4	Implement a full join to fn_ValidObjects to suppress objects 
--					that are not licensed to the user.
-- 17 Nov 2004	JEK	RFC869	5	Fix ambiguous column references.
-- 22 Nov 2004	JEK	RFC869	6	Make this function encrypted because it depends on an encrypted function.
-- 01 Dec 2004	JEK	RFC2079	7	Include InternalUse/External use in join to fn_ValidObjects.
-- 24 Feb 2005	TM	RFC2369	8	Add 'collate database_default' to the join on the ObjectStringKey column
--					of the fn_ValidObjects.
-- 02 Sep 2005 	TM	RFC2952	9	Update the comments.
-- 12 Jul 2006	SW	RFC3828	10	Add new param @pdtToday

-- NOTE: If the function is changed, the corresponding fn_PermissionsGrantedName function needs to be changed.

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
	from IDENTITYROLES IR
	join USERIDENTITY UI	on (UI.IDENTITYID = IR.IDENTITYID)
	join PERMISSIONS P	on (P.LEVELKEY=IR.ROLEID
		           	and P.LEVELTABLE = 'ROLE')
	join dbo.fn_ValidObjects(@pnIdentityKey, @psObjectTable, @pdtToday) VO 
				on ((VO.ObjectIntegerKey = P.OBJECTINTEGERKEY or
				     VO.ObjectStringKey collate database_default = P.OBJECTSTRINGKEY)
				-- Use ExternalUse objects for external users
				-- and InternalUse objects for internal users
				and (VO.InternalUse = ~UI.ISEXTERNALUSER or
				     VO.ExternalUse = UI.ISEXTERNALUSER))								
	where IR.IDENTITYID = @pnIdentityKey
	and   P.OBJECTTABLE = @psObjectTable
	and  (P.OBJECTINTEGERKEY = @pnObjectIntegerKey or @pnObjectIntegerKey is null)
	and  (P.OBJECTSTRINGKEY  = @psObjectStringKey  or @psObjectStringKey is null)
	group by P.OBJECTINTEGERKEY,P.OBJECTSTRINGKEY
GO

Grant REFERENCES, SELECT on dbo.fn_PermissionsGranted to public
GO
