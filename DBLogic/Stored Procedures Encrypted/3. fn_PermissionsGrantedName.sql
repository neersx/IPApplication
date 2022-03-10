-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_PermissionsGrantedName
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_PermissionsGrantedName') and xtype='IF')
Begin
	Print '**** Drop Function dbo.fn_PermissionsGrantedName'
	Drop function [dbo].[fn_PermissionsGrantedName]
End
Print '**** Creating Function dbo.fn_PermissionsGrantedName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_PermissionsGrantedName
(	
	@pnNameKey		int,				-- the name for whom the user licenses are to be checked.  Mandatory.
	@psObjectTable 		nvarchar(30),			-- the type of object; e.g. TASK
	@pnObjectIntegerKey 	int 	     	= null, 	-- Optional
	@psObjectStringKey 	nvarchar(30) 	= null,		-- Optional
	@pdtToday		datetime
) 
RETURNS TABLE
With ENCRYPTION
AS
-- Function :	fn_PermissionsGrantedName
-- VERSION :	3
-- DESCRIPTION:	Extracts a list of list of distinct licensed objects for the supplied name.
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 02 Sep 2005	TM	RFC2952	1	Function created
-- 05 Sep 2005	TM	RFC2952	2	Add an IdentityKey to the fn_ValidObjectsName join.
-- 12 Jul 2006	SW	RFC3828	3	Add new param @pdtToday

-- NOTE: If the function is changed, the corresponding fn_PermissionsGranted function needs to be changed.

RETURN
	select 	UI.IDENTITYID as IdentityKey, 
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
	join USERIDENTITY UI	on (UI.NAMENO = @pnNameKey
				and UI.IDENTITYID = IR.IDENTITYID)
	join PERMISSIONS P	on (P.LEVELKEY=IR.ROLEID
		           	and P.LEVELTABLE = 'ROLE')
	join dbo.fn_ValidObjectsName(@pnNameKey, @psObjectTable, @pdtToday) VO 
				on  (VO.IdentityKey = UI.IDENTITYID
				and (VO.ObjectIntegerKey = P.OBJECTINTEGERKEY or
				     VO.ObjectStringKey collate database_default = P.OBJECTSTRINGKEY)
				-- Use ExternalUse objects for external users
				-- and InternalUse objects for internal users
				and (VO.InternalUse = ~UI.ISEXTERNALUSER or
				     VO.ExternalUse = UI.ISEXTERNALUSER))								
	where IR.IDENTITYID = UI.IDENTITYID
	and   P.OBJECTTABLE = @psObjectTable
	and  (P.OBJECTINTEGERKEY = @pnObjectIntegerKey or @pnObjectIntegerKey is null)
	and  (P.OBJECTSTRINGKEY  = @psObjectStringKey  or @psObjectStringKey is null)
	group by P.OBJECTINTEGERKEY,P.OBJECTSTRINGKEY, UI.IDENTITYID
GO

Grant REFERENCES, SELECT on dbo.fn_PermissionsGrantedName to public
GO
