-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnTITLES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnTITLES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnTITLES.'
	drop function dbo.fn_ccnTITLES
	print '**** Creating function dbo.fn_ccnTITLES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TITLES]') and xtype='U')
begin
	select * 
	into CCImport_TITLES 
	from TITLES
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnTITLES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnTITLES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TITLES table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'TITLES' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_TITLES I 
	right join TITLES C on( C.TITLE=I.TITLE)
where I.TITLE is null
UNION ALL 
select	2, 'TITLES', 0, count(*), 0, 0
from CCImport_TITLES I 
	left join TITLES C on( C.TITLE=I.TITLE)
where C.TITLE is null
UNION ALL 
 select	2, 'TITLES', 0, 0, count(*), 0
from CCImport_TITLES I 
	join TITLES C	on ( C.TITLE=I.TITLE)
where 	( I.FULLTITLE <>  C.FULLTITLE OR (I.FULLTITLE is null and C.FULLTITLE is not null) 
OR (I.FULLTITLE is not null and C.FULLTITLE is null))
	OR 	( I.GENDERFLAG <>  C.GENDERFLAG OR (I.GENDERFLAG is null and C.GENDERFLAG is not null) 
OR (I.GENDERFLAG is not null and C.GENDERFLAG is null))
	OR 	( I.DEFAULTFLAG <>  C.DEFAULTFLAG OR (I.DEFAULTFLAG is null and C.DEFAULTFLAG is not null) 
OR (I.DEFAULTFLAG is not null and C.DEFAULTFLAG is null))
UNION ALL 
 select	2, 'TITLES', 0, 0, 0, count(*)
from CCImport_TITLES I 
join TITLES C	on( C.TITLE=I.TITLE)
where ( I.FULLTITLE =  C.FULLTITLE OR (I.FULLTITLE is null and C.FULLTITLE is null))
and ( I.GENDERFLAG =  C.GENDERFLAG OR (I.GENDERFLAG is null and C.GENDERFLAG is null))
and ( I.DEFAULTFLAG =  C.DEFAULTFLAG OR (I.DEFAULTFLAG is null and C.DEFAULTFLAG is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TITLES]') and xtype='U')
begin
	drop table CCImport_TITLES 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnTITLES  to public
go

