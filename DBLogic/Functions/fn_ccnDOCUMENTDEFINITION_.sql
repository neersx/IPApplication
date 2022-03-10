-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnDOCUMENTDEFINITION_
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnDOCUMENTDEFINITION_]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnDOCUMENTDEFINITION_.'
	drop function dbo.fn_ccnDOCUMENTDEFINITION_
	print '**** Creating function dbo.fn_ccnDOCUMENTDEFINITION_...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_DOCUMENTDEFINITIONACTINGAS]') and xtype='U')
begin
	select * 
	into CCImport_DOCUMENTDEFINITIONACTINGAS 
	from DOCUMENTDEFINITIONACTINGAS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnDOCUMENTDEFINITION_
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnDOCUMENTDEFINITION_
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the DOCUMENTDEFINITIONACTINGAS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'DOCUMENTDEFINITIONACTINGAS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_DOCUMENTDEFINITIONACTINGAS I 
	right join DOCUMENTDEFINITIONACTINGAS C on( C.DOCUMENTDEFID=I.DOCUMENTDEFID
and  C.NAMETYPE=I.NAMETYPE)
where I.DOCUMENTDEFID is null
UNION ALL 
select	6, 'DOCUMENTDEFINITIONACTINGAS', 0, count(*), 0, 0
from CCImport_DOCUMENTDEFINITIONACTINGAS I 
	left join DOCUMENTDEFINITIONACTINGAS C on( C.DOCUMENTDEFID=I.DOCUMENTDEFID
and  C.NAMETYPE=I.NAMETYPE)
where C.DOCUMENTDEFID is null
UNION ALL 
 select	6, 'DOCUMENTDEFINITIONACTINGAS', 0, 0, 0, count(*)
from CCImport_DOCUMENTDEFINITIONACTINGAS I 
join DOCUMENTDEFINITIONACTINGAS C	on( C.DOCUMENTDEFID=I.DOCUMENTDEFID
and C.NAMETYPE=I.NAMETYPE)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DOCUMENTDEFINITIONACTINGAS]') and xtype='U')
begin
	drop table CCImport_DOCUMENTDEFINITIONACTINGAS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnDOCUMENTDEFINITION_  to public
go
