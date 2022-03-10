-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_PermissionRule 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_PermissionRule ') and xtype='TF')
Begin
	Print '**** Drop Function dbo.fn_PermissionRule '
	Drop function [dbo].[fn_PermissionRule ]
End
Print '**** Creating Function dbo.fn_PermissionRule ...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_PermissionRule 
(	
	@psObjectTable		nvarchar(30)	= null,	-- the type of object; e.g. TASK
	@pnObjectIntegerKey	int		= null,
	@psObjectStringKey	nvarchar(30)	= null
) 
RETURNS @tbPermissions TABLE
   (
        ObjectTable		nvarchar(30)	collate database_default NOT NULL,
	ObjectIntegerKey	int 		NULL,
	ObjectStringKey		int		NULL,
	SelectPermission	tinyint		NULL,
	MandatoryPermission	tinyint		NULL,
	InsertPermission	tinyint		NULL,
	UpdatePermission	tinyint		NULL,
	DeletePermission	tinyint		NULL,
	ExecutePermission	tinyint		NULL
		unique(ObjectTable, ObjectIntegerKey, ObjectStringKey)
   )
-- Function :	fn_PermissionRule 
-- VERSION :	5
-- DESCRIPTION:	Returns permission rules information for an Object (e.g. Task, Module, DataTopic). 
-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Aug 2004	TM	RFC1500		1	Function created
-- 23 Aug 2004	TM	RFC1500		2	Return 0 for not applicable and 1 for applicable permissions.
--						Remove unnecessary self-joins. 
-- 27 Sep 2004	JEK	RFC886		3	Implement collate database_default.
-- 30 Nov 2006	JEK	RFC4755		4	Add unique contraint on table for performance.
-- 31 Oct 2018	vql	DR-45102	5	remove control characters from functions.

AS
BEGIN

	-- Depending on the type of object being managed, only certain permissions are relevant. 
	-- Each XxxPermission field may take the following values:
	--    0    - permission is not applicable. 
	--    1    - permission is applicable.

     	insert into @tbPermissions (ObjectTable, ObjectIntegerKey, ObjectStringKey,SelectPermission, MandatoryPermission, 
					InsertPermission, UpdatePermission, DeletePermission, ExecutePermission)
	select 	P.OBJECTTABLE 				as ObjectTable,
		P.OBJECTINTEGERKEY 			as ObjectIntegerKey, 
		P.OBJECTSTRINGKEY  			as ObjectStringKey,		
		cast(P.GRANTPERMISSION&1 as bit)	as SelectPermission,
		cast(P.GRANTPERMISSION&64 as bit)	as MandatoryPermission,
		cast(P.GRANTPERMISSION&8 as bit)	as InsertPermission,			
		cast(P.GRANTPERMISSION&2 as bit)  	as UpdatePermission,			
		cast(P.GRANTPERMISSION&16 as bit)	as DeletePermission,	
		cast(P.GRANTPERMISSION&32 as bit)	as ExecutePermission	
	from PERMISSIONS P	
	where P.LEVELTABLE is null
	and   P.LEVELKEY is null	
	and  (P.OBJECTTABLE      = @psObjectTable      or @psObjectTable is null)
	and  (P.OBJECTINTEGERKEY = @pnObjectIntegerKey or @pnObjectIntegerKey is null)
	and  (P.OBJECTSTRINGKEY  = @psObjectStringKey  or @psObjectStringKey is null)
	order by ObjectTable, ObjectIntegerKey, ObjectStringKey

	Return
End
GO

Grant REFERENCES, SELECT on dbo.fn_PermissionRule  to public
GO
