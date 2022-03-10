-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_ROLE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_ROLE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_ROLE.'
	drop function dbo.fn_cc_ROLE
	print '**** Creating function dbo.fn_cc_ROLE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ROLE]') and xtype='U')
begin
	select * 
	into CCImport_ROLE 
	from ROLE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_ROLE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_ROLE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ROLE table
-- CALLED BY :	ip_CopyConfigROLE
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
	 null as 'Imported Rolename',
	 null as 'Imported Description',
	 null as 'Imported Isexternal',
	 null as 'Imported Defaultportalid',
	 null as 'Imported Isprotected',
'D' as '-',
	 C.ROLENAME as 'Rolename',
	 C.DESCRIPTION as 'Description',
	 C.ISEXTERNAL as 'Isexternal',
	 C.DEFAULTPORTALID as 'Defaultportalid',
	 C.ISPROTECTED as 'Isprotected'
from CCImport_ROLE I 
	right join ROLE C on( C.ROLEID=I.ROLEID)
where I.ROLEID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.ROLENAME,
	 I.DESCRIPTION,
	 I.ISEXTERNAL,
	 I.DEFAULTPORTALID,
	 I.ISPROTECTED,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_ROLE I 
	left join ROLE C on( C.ROLEID=I.ROLEID)
where C.ROLEID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.ROLENAME,
	 I.DESCRIPTION,
	 I.ISEXTERNAL,
	 I.DEFAULTPORTALID,
	 I.ISPROTECTED,
'U',
	 C.ROLENAME,
	 C.DESCRIPTION,
	 C.ISEXTERNAL,
	 C.DEFAULTPORTALID,
	 C.ISPROTECTED
from CCImport_ROLE I 
	join ROLE C	on ( C.ROLEID=I.ROLEID)
where 	(replace( I.ROLENAME,char(10),char(13)+char(10)) <>  C.ROLENAME OR (I.ROLENAME is null and C.ROLENAME is not null) 
OR (I.ROLENAME is not null and C.ROLENAME is null))
	OR 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.ISEXTERNAL <>  C.ISEXTERNAL OR (I.ISEXTERNAL is null and C.ISEXTERNAL is not null) 
OR (I.ISEXTERNAL is not null and C.ISEXTERNAL is null))
	OR 	( I.DEFAULTPORTALID <>  C.DEFAULTPORTALID OR (I.DEFAULTPORTALID is null and C.DEFAULTPORTALID is not null) 
OR (I.DEFAULTPORTALID is not null and C.DEFAULTPORTALID is null))
	OR 	( I.ISPROTECTED <>  C.ISPROTECTED)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ROLE]') and xtype='U')
begin
	drop table CCImport_ROLE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_ROLE  to public
go
