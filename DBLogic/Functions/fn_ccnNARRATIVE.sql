-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnNARRATIVE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnNARRATIVE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnNARRATIVE.'
	drop function dbo.fn_ccnNARRATIVE
	print '**** Creating function dbo.fn_ccnNARRATIVE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_NARRATIVE]') and xtype='U')
begin
	select * 
	into CCImport_NARRATIVE 
	from NARRATIVE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnNARRATIVE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnNARRATIVE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the NARRATIVE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	8 as TRIPNO, 'NARRATIVE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_NARRATIVE I 
	right join NARRATIVE C on( C.NARRATIVENO=I.NARRATIVENO)
where I.NARRATIVENO is null
UNION ALL 
select	8, 'NARRATIVE', 0, count(*), 0, 0
from CCImport_NARRATIVE I 
	left join NARRATIVE C on( C.NARRATIVENO=I.NARRATIVENO)
where C.NARRATIVENO is null
UNION ALL 
 select	8, 'NARRATIVE', 0, 0, count(*), 0
from CCImport_NARRATIVE I 
	join NARRATIVE C	on ( C.NARRATIVENO=I.NARRATIVENO)
where 	( I.NARRATIVECODE <>  C.NARRATIVECODE OR (I.NARRATIVECODE is null and C.NARRATIVECODE is not null) 
OR (I.NARRATIVECODE is not null and C.NARRATIVECODE is null))
	OR 	( I.NARRATIVETITLE <>  C.NARRATIVETITLE OR (I.NARRATIVETITLE is null and C.NARRATIVETITLE is not null) 
OR (I.NARRATIVETITLE is not null and C.NARRATIVETITLE is null))
	OR 	( replace(CAST(I.NARRATIVETEXT as NVARCHAR(MAX)),char(10),char(13)+char(10)) <>  CAST(C.NARRATIVETEXT as NVARCHAR(MAX)) OR (I.NARRATIVETEXT is null and C.NARRATIVETEXT is not null) 
OR (I.NARRATIVETEXT is not null and C.NARRATIVETEXT is null))
UNION ALL 
 select	8, 'NARRATIVE', 0, 0, 0, count(*)
from CCImport_NARRATIVE I 
join NARRATIVE C	on( C.NARRATIVENO=I.NARRATIVENO)
where ( I.NARRATIVECODE =  C.NARRATIVECODE OR (I.NARRATIVECODE is null and C.NARRATIVECODE is null))
and ( I.NARRATIVETITLE =  C.NARRATIVETITLE OR (I.NARRATIVETITLE is null and C.NARRATIVETITLE is null))
and ( replace(CAST(I.NARRATIVETEXT as NVARCHAR(MAX)),char(10),char(13)+char(10)) =  CAST(C.NARRATIVETEXT as NVARCHAR(MAX)) OR (I.NARRATIVETEXT is null and C.NARRATIVETEXT is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_NARRATIVE]') and xtype='U')
begin
	drop table CCImport_NARRATIVE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnNARRATIVE  to public
go
