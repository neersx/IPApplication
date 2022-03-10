-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_PERMISSIONS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_PERMISSIONS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_PERMISSIONS.'
	drop function dbo.fn_cc_PERMISSIONS
	print '**** Creating function dbo.fn_cc_PERMISSIONS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PERMISSIONS]') and xtype='U')
begin
	select * 
	into CCImport_PERMISSIONS 
	from PERMISSIONS
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_PERMISSIONS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_PERMISSIONS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PERMISSIONS table
-- CALLED BY :	ip_CopyConfigPERMISSIONS
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	1 as 'Switch',
	'X' as 'Match',
	'D' as 'Imported -',
	 null as 'Imported Objecttable',
	 null as 'Imported Objectintegerkey',
	 null as 'Imported Objectstringkey',
	 null as 'Imported Leveltable',
	 null as 'Imported Levelkey',
	 null as 'Imported Grantpermission',
	 null as 'Imported Denypermission',
'D' as '-',
	 C.OBJECTTABLE as 'Objecttable',
	 C.OBJECTINTEGERKEY as 'Objectintegerkey',
	 C.OBJECTSTRINGKEY as 'Objectstringkey',
	 C.LEVELTABLE as 'Leveltable',
	 C.LEVELKEY as 'Levelkey',
	 C.GRANTPERMISSION as 'Grantpermission',
	 C.DENYPERMISSION as 'Denypermission'
from CCImport_PERMISSIONS I 
	right join PERMISSIONS C on( C.PERMISSIONID=I.PERMISSIONID)
where I.PERMISSIONID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.OBJECTTABLE,
	 I.OBJECTINTEGERKEY,
	 I.OBJECTSTRINGKEY,
	 I.LEVELTABLE,
	 I.LEVELKEY,
	 I.GRANTPERMISSION,
	 I.DENYPERMISSION,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_PERMISSIONS I 
	left join PERMISSIONS C on( C.PERMISSIONID=I.PERMISSIONID)
where C.PERMISSIONID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.OBJECTTABLE,
	 I.OBJECTINTEGERKEY,
	 I.OBJECTSTRINGKEY,
	 I.LEVELTABLE,
	 I.LEVELKEY,
	 I.GRANTPERMISSION,
	 I.DENYPERMISSION,
'U',
	 C.OBJECTTABLE,
	 C.OBJECTINTEGERKEY,
	 C.OBJECTSTRINGKEY,
	 C.LEVELTABLE,
	 C.LEVELKEY,
	 C.GRANTPERMISSION,
	 C.DENYPERMISSION
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

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PERMISSIONS]') and xtype='U')
begin
	drop table CCImport_PERMISSIONS 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_PERMISSIONS  to public
go
