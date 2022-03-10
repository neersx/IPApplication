-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnROLE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnROLE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnROLE.'
	drop function dbo.fn_ccnROLE
	print '**** Creating function dbo.fn_ccnROLE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ROLE]') and xtype='U')
begin
	select * 
	into CCImport_ROLE 
	from ROLE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnROLE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnROLE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ROLE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'ROLE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_ROLE I 
	right join ROLE C on( C.ROLEID=I.ROLEID)
where I.ROLEID is null
UNION ALL 
select	6, 'ROLE', 0, count(*), 0, 0
from CCImport_ROLE I 
	left join ROLE C on( C.ROLEID=I.ROLEID)
where C.ROLEID is null
UNION ALL 
 select	6, 'ROLE', 0, 0, count(*), 0
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
UNION ALL 
 select	6, 'ROLE', 0, 0, 0, count(*)
from CCImport_ROLE I 
join ROLE C	on( C.ROLEID=I.ROLEID)
where (replace( I.ROLENAME,char(10),char(13)+char(10)) =  C.ROLENAME OR (I.ROLENAME is null and C.ROLENAME is null))
and (replace( I.DESCRIPTION,char(10),char(13)+char(10)) =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))
and ( I.ISEXTERNAL =  C.ISEXTERNAL OR (I.ISEXTERNAL is null and C.ISEXTERNAL is null))
and ( I.DEFAULTPORTALID =  C.DEFAULTPORTALID OR (I.DEFAULTPORTALID is null and C.DEFAULTPORTALID is null))
and ( I.ISPROTECTED =  C.ISPROTECTED)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ROLE]') and xtype='U')
begin
	drop table CCImport_ROLE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnROLE  to public
go
