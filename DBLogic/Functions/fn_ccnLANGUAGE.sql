-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnLANGUAGE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnLANGUAGE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnLANGUAGE.'
	drop function dbo.fn_ccnLANGUAGE
	print '**** Creating function dbo.fn_ccnLANGUAGE...'
	print ''
end
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_LANGUAGE]') and xtype='U')
begin
	select * 
	into CCImport_LANGUAGE 
	from LANGUAGE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnLANGUAGE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnLANGUAGE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the LANGUAGE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	4 as TRIPNO, 'LANGUAGE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_LANGUAGE I 
	right join LANGUAGE C on( C.LANGUAGE_CODE=I.LANGUAGE_CODE)
where I.LANGUAGE_CODE is null
UNION ALL 
select	4, 'LANGUAGE', 0, count(*), 0, 0
from CCImport_LANGUAGE I 
	left join LANGUAGE C on( C.LANGUAGE_CODE=I.LANGUAGE_CODE)
where C.LANGUAGE_CODE is null
UNION ALL 
 select	4, 'LANGUAGE', 0, 0, count(*), 0
from CCImport_LANGUAGE I 
	join LANGUAGE C	on ( C.LANGUAGE_CODE=I.LANGUAGE_CODE)
where 	( I.LANGUAGE <>  C.LANGUAGE)
UNION ALL 
 select	4, 'LANGUAGE', 0, 0, 0, count(*)
from CCImport_LANGUAGE I 
join LANGUAGE C	on( C.LANGUAGE_CODE=I.LANGUAGE_CODE)
where ( I.LANGUAGE =  C.LANGUAGE)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_LANGUAGE]') and xtype='U')
begin
	drop table CCImport_LANGUAGE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnLANGUAGE  to public
go
