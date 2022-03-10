-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_PermissionData 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_PermissionData ') and xtype='TF')
Begin
	Print '**** Drop Function dbo.fn_PermissionData '
	Drop function [dbo].[fn_PermissionData ]
End
Print '**** Creating Function dbo.fn_PermissionData ...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_PermissionData 
(	
	@psLevelTable		nvarchar(30)	= null,	-- to the level at which the permissions were granted; e.g. ROLE
	@pnLevelKey		int		= null,
	@psObjectTable		nvarchar(30),	-- Mandatory. The type of object; e.g. TASK
	@pnObjectIntegerKey	int		= null,
	@psObjectStringKey	nvarchar(30)	= null,
	@pdtToday		datetime
) 
RETURNS @tbPermissions TABLE
   (
        LevelTable		nvarchar(30)	collate database_default NULL,
        LevelKey		int		NULL,
        ObjectTable		nvarchar(30)	collate database_default NOT NULL,
	ObjectIntegerKey	int 		NULL,
	ObjectStringKey		int		NULL,
	SelectPermission	tinyint		NULL,
	MandatoryPermission	tinyint		NULL,
	InsertPermission	tinyint		NULL,
	UpdatePermission	tinyint		NULL,
	DeletePermission	tinyint		NULL,
	ExecutePermission	tinyint		NULL
		unique(LevelTable,LevelKey,ObjectTable,ObjectIntegerKey,ObjectStringKey)
   )
With ENCRYPTION
-- Function :	fn_PermissionData 
-- VERSION :	12
-- DESCRIPTION:	Populates the PermissionData dataset.
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 23 Jun 2004	TM	RFC1500	1	Function created
-- 28 Jun 2004	TM	RFC1500	2	Remove group/sum.
-- 27 Sep 2004	JEK	RFC886	6	Implement collate database_default.
-- 15 Nov 2004	TM	RFC869	7	Implement a full join to fn_ValidObjects to suppress objects 
--					that are not licensed to the firm.
-- 22 Nov 2004	JEK	RFC869	8	Make this function encrypted because it depends on an encrypted function.
-- 01 Dec 2004	JEK	RFC2079	9	Include InternalUse/ExternalUse in join to fn_ValidObjects.
-- 24 Feb 2004	TM	RFC2369	10	Add 'collate database_default' to the join on the ObjectStringKey column
--					of the fn_ValidObjects.
-- 12 Jul 2006	SW	RFC3828	11	Add new param @pdtToday
-- 30 Nov 2006	JEK	RFC4755 12	Add unique constraint for performance.

AS
BEGIN

	-- Depending on the type of object being managed, only certain permissions are relevant. 
	-- Each XxxPermission field may take the following values:
	--    null - permissions are not applicable for particular objects.
	--    0    – revoked permissions. 
	--    1    – granted permissions.
        --    2    – denied permissions.
	insert into @tbPermissions (LevelTable, LevelKey, ObjectTable, ObjectIntegerKey, ObjectStringKey,SelectPermission,
				    MandatoryPermission, InsertPermission, UpdatePermission, DeletePermission, ExecutePermission)
	select 	P.LEVELTABLE 		as LevelTable,
		P.LEVELKEY 		as LevelKey,
		P.OBJECTTABLE 		as ObjectTable,
		P.OBJECTINTEGERKEY 	as ObjectIntegerKey, 
		P.OBJECTSTRINGKEY  	as ObjectStringKey,		
		CASE WHEN  ISNULL(PRULE.GRANTPERMISSION,PDFLT.GRANTPERMISSION)&1 = 0 		     
		     THEN  NULL		    
		     WHEN  P.DENYPERMISSION&1=1
		     THEN  2 		   
		     ELSE  cast(P.GRANTPERMISSION&1 as bit)
		END			 as SelectPermission,

		CASE WHEN  ISNULL(PRULE.GRANTPERMISSION,PDFLT.GRANTPERMISSION)&64 = 0
		     THEN  NULL
		     WHEN  P.DENYPERMISSION&64 = 64
		     THEN  2 
		     ELSE  cast(P.GRANTPERMISSION&64 as bit)
		END			 as MandatoryPermission,

		CASE WHEN  ISNULL(PRULE.GRANTPERMISSION,PDFLT.GRANTPERMISSION)&8 = 0 
		     THEN  NULL
		     WHEN  P.DENYPERMISSION&8 = 8
		     THEN  2 
		     ELSE  cast(P.GRANTPERMISSION&8 as bit)     
		END			as InsertPermission,			
		
		CASE WHEN  ISNULL(PRULE.GRANTPERMISSION,PDFLT.GRANTPERMISSION)&2 = 0 
		     THEN  NULL
		     WHEN  P.DENYPERMISSION&2 = 2
		     THEN  2 
		     ELSE  cast(P.GRANTPERMISSION&2 as bit)     
		END			as UpdatePermission,			

		CASE WHEN  ISNULL(PRULE.GRANTPERMISSION,PDFLT.GRANTPERMISSION)&16 = 0 
		     THEN  NULL
		     WHEN  P.DENYPERMISSION&16 = 16
		     THEN  2 
		     ELSE  cast(P.GRANTPERMISSION&16 as bit)	     
		END			as DeletePermission,	

		CASE WHEN  ISNULL(PRULE.GRANTPERMISSION,PDFLT.GRANTPERMISSION)&32 = 0 
		     THEN  NULL
		     WHEN  P.DENYPERMISSION&32 = 32
		     THEN  2 
		     ELSE  cast(P.GRANTPERMISSION&32 as bit)	     
		END			as ExecutePermission
	
	from PERMISSIONS P
	join ROLE R			on (R.ROLEID = P.LEVELKEY
					AND P.LEVELTABLE = 'ROLE')
	join dbo.fn_ValidObjects(null, @psObjectTable, @pdtToday) VO
					on ((VO.ObjectIntegerKey = P.OBJECTINTEGERKEY or
					     VO.ObjectStringKey collate database_default = P.OBJECTSTRINGKEY)
					-- Use ExternalUse objects for external roles
					-- and InternalUse objects for internal roles
					and (VO.InternalUse = ~R.ISEXTERNAL or
					     VO.ExternalUse = R.ISEXTERNAL or
					     R.ISEXTERNAL IS NULL))
	left join PERMISSIONS PRULE 	on  (PRULE.OBJECTTABLE = P.OBJECTTABLE
					and (PRULE.OBJECTINTEGERKEY = P.OBJECTINTEGERKEY
					 or  PRULE.OBJECTSTRINGKEY  = P.OBJECTSTRINGKEY)
					and  PRULE.LEVELTABLE is null
					and  PRULE.LEVELKEY is null)
	left join PERMISSIONS PDFLT	on  (PDFLT.OBJECTTABLE = P.OBJECTTABLE
					and  PDFLT.OBJECTINTEGERKEY is null
					and  PDFLT.OBJECTSTRINGKEY is null
					and  PDFLT.LEVELTABLE is null
					and  PDFLT.LEVELKEY is null) 
	where P.LEVELTABLE is not null
	and   P.LEVELKEY is not null	
	and  (P.LEVELTABLE 	 = @psLevelTable       or @psLevelTable is null)
	and  (P.LEVELKEY 	 = @pnLevelKey         or @pnLevelKey is null)
	and  (P.OBJECTTABLE      = @psObjectTable      or @psObjectTable is null)
	and  (P.OBJECTINTEGERKEY = @pnObjectIntegerKey or @pnObjectIntegerKey is null)
	and  (P.OBJECTSTRINGKEY  = @psObjectStringKey  or @psObjectStringKey is null)
	order by LevelTable, LevelKey, ObjectTable, ObjectIntegerKey, ObjectStringKey

	Return
End
GO

Grant REFERENCES, SELECT on dbo.fn_PermissionData  to public
GO
