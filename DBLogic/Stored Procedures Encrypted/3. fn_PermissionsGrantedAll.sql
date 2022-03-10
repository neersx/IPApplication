-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_PermissionsGrantedAll
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_PermissionsGrantedAll') and xtype='IF')
Begin
	Print '**** Drop Function dbo.fn_PermissionsGrantedAll'
	Drop function [dbo].[fn_PermissionsGrantedAll]
End
Print '**** Creating Function dbo.fn_PermissionsGrantedAll...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_PermissionsGrantedAll
(	
	@psObjectTable 		nvarchar(30)	= null,		-- the type of object; e.g. TASK
	@pnObjectIntegerKey 	int 	     	= null, 	-- Optional
	@psObjectStringKey 	nvarchar(30) 	= null,		-- Optional
	@pdtToday		datetime
) 
RETURNS TABLE
With ENCRYPTION
AS
-- Function :	fn_PermissionsGrantedAll
-- VERSION :	1
-- DESCRIPTION:	Assesses and returns the permissions for a particular object/objects for 
--		all users in the system (i.e. the user's rights to perform Select, Update,
--		Delete, Insert, Execute).
--
--		If information is required for a single user, use fn_PermissionsGranted() instead.
--
--		Since fn_ValidObjects requires a fixed IdentityKey, this is achieved by
--		assessing permissions for the user and then checking against the valid objects
--		for the user to assess licensing.
--
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 10 Aug 2006	JEK	RFC3828	1	Function created

RETURN
	select 	IR.IDENTITYID as IdentityKey,
		P.OBJECTTABLE as ObjectTable,
		P.OBJECTINTEGERKEY as ObjectIntegerKey, 
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
	join dbo.fn_ValidObjectsAll(@psObjectTable, @pdtToday) VO
				on (VO.IdentityKey = UI.IDENTITYID 
				and VO.ObjectTable collate database_default =P.OBJECTTABLE
				and (VO.ObjectIntegerKey = P.OBJECTINTEGERKEY or
				     VO.ObjectStringKey collate database_default = P.OBJECTSTRINGKEY)
				   )			
	where UI.ISVALIDWORKBENCH=1
	and  (P.OBJECTTABLE = @psObjectTable or @psObjectTable is null)
	and  (P.OBJECTINTEGERKEY = @pnObjectIntegerKey or @pnObjectIntegerKey is null)
	and  (P.OBJECTSTRINGKEY  = @psObjectStringKey  or @psObjectStringKey is null)
	group by IR.IDENTITYID, P.OBJECTTABLE, P.OBJECTINTEGERKEY,P.OBJECTSTRINGKEY
GO

Grant REFERENCES, SELECT on dbo.fn_PermissionsGrantedAll to public
GO
