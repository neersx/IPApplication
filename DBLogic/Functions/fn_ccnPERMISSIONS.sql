-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnPERMISSIONS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnPERMISSIONS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnPERMISSIONS.'
	drop function dbo.fn_ccnPERMISSIONS
	print '**** Creating function dbo.fn_ccnPERMISSIONS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PERMISSIONS]') and xtype='U')
begin
	select * 
	into CCImport_PERMISSIONS 
	from PERMISSIONS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnPERMISSIONS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnPERMISSIONS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PERMISSIONS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'PERMISSIONS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_PERMISSIONS I 
	right join PERMISSIONS C on( C.PERMISSIONID=I.PERMISSIONID)
where I.PERMISSIONID is null
UNION ALL 
select	6, 'PERMISSIONS', 0, count(*), 0, 0
from CCImport_PERMISSIONS I 
	left join PERMISSIONS C on( C.PERMISSIONID=I.PERMISSIONID)
where C.PERMISSIONID is null
UNION ALL 
 select	6, 'PERMISSIONS', 0, 0, count(*), 0
from CCImport_PERMISSIONS I 
	join PERMISSIONS C	on ( C.PERMISSIONID=I.PERMISSIONID)
where 	( I.OBJECTTABLE <>  C.OBJECTTABLE)
	OR 	( I.OBJECTINTEGERKEY <>  C.OBJECTINTEGERKEY OR (I.OBJECTINTEGERKEY is null and C.OBJECTINTEGERKEY is not null) 
OR (I.OBJECTINTEGERKEY is not null and C.OBJECTINTEGERKEY is null))
	OR 	( I.OBJECTSTRINGKEY <>  C.OBJECTSTRINGKEY OR (I.OBJECTSTRINGKEY is null and C.OBJECTSTRINGKEY is not null) 
OR (I.OBJECTSTRINGKEY is not null and C.OBJECTSTRINGKEY is null))
	OR 	( I.LEVELTABLE <>  C.LEVELTABLE OR (I.LEVELTABLE is null and C.LEVELTABLE is not null) 
OR (I.LEVELTABLE is not null and C.LEVELTABLE is null))
	OR 	( I.LEVELKEY <>  C.LEVELKEY OR (I.LEVELKEY is null and C.LEVELKEY is not null) 
OR (I.LEVELKEY is not null and C.LEVELKEY is null))
	OR 	( I.GRANTPERMISSION <>  C.GRANTPERMISSION)
	OR 	( I.DENYPERMISSION <>  C.DENYPERMISSION)
UNION ALL 
 select	6, 'PERMISSIONS', 0, 0, 0, count(*)
from CCImport_PERMISSIONS I 
join PERMISSIONS C	on( C.PERMISSIONID=I.PERMISSIONID)
where ( I.OBJECTTABLE =  C.OBJECTTABLE)
and ( I.OBJECTINTEGERKEY =  C.OBJECTINTEGERKEY OR (I.OBJECTINTEGERKEY is null and C.OBJECTINTEGERKEY is null))
and ( I.OBJECTSTRINGKEY =  C.OBJECTSTRINGKEY OR (I.OBJECTSTRINGKEY is null and C.OBJECTSTRINGKEY is null))
and ( I.LEVELTABLE =  C.LEVELTABLE OR (I.LEVELTABLE is null and C.LEVELTABLE is null))
and ( I.LEVELKEY =  C.LEVELKEY OR (I.LEVELKEY is null and C.LEVELKEY is null))
and ( I.GRANTPERMISSION =  C.GRANTPERMISSION)
and ( I.DENYPERMISSION =  C.DENYPERMISSION)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PERMISSIONS]') and xtype='U')
begin
	drop table CCImport_PERMISSIONS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnPERMISSIONS  to public
go
