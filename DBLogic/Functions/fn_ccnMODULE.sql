-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnMODULE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnMODULE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnMODULE.'
	drop function dbo.fn_ccnMODULE
	print '**** Creating function dbo.fn_ccnMODULE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_MODULE]') and xtype='U')
begin
	select * 
	into CCImport_MODULE 
	from MODULE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnMODULE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnMODULE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the MODULE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'MODULE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_MODULE I 
	right join MODULE C on( C.MODULEID=I.MODULEID)
where I.MODULEID is null
UNION ALL 
select	6, 'MODULE', 0, count(*), 0, 0
from CCImport_MODULE I 
	left join MODULE C on( C.MODULEID=I.MODULEID)
where C.MODULEID is null
UNION ALL 
 select	6, 'MODULE', 0, 0, count(*), 0
from CCImport_MODULE I 
	join MODULE C	on ( C.MODULEID=I.MODULEID)
where 	( I.MODULEDEFID <>  C.MODULEDEFID)
	OR 	(replace( I.TITLE,char(10),char(13)+char(10)) <>  C.TITLE OR (I.TITLE is null and C.TITLE is not null) 
OR (I.TITLE is not null and C.TITLE is null))
	OR 	( I.CACHETIME <>  C.CACHETIME)
	OR 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
UNION ALL 
 select	6, 'MODULE', 0, 0, 0, count(*)
from CCImport_MODULE I 
join MODULE C	on( C.MODULEID=I.MODULEID)
where ( I.MODULEDEFID =  C.MODULEDEFID)
and (replace( I.TITLE,char(10),char(13)+char(10)) =  C.TITLE OR (I.TITLE is null and C.TITLE is null))
and ( I.CACHETIME =  C.CACHETIME)
and (replace( I.DESCRIPTION,char(10),char(13)+char(10)) =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_MODULE]') and xtype='U')
begin
	drop table CCImport_MODULE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnMODULE  to public
go

