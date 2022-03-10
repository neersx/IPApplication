-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnMAPSTRUCTURE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnMAPSTRUCTURE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnMAPSTRUCTURE.'
	drop function dbo.fn_ccnMAPSTRUCTURE
	print '**** Creating function dbo.fn_ccnMAPSTRUCTURE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_MAPSTRUCTURE]') and xtype='U')
begin
	select * 
	into CCImport_MAPSTRUCTURE 
	from MAPSTRUCTURE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnMAPSTRUCTURE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnMAPSTRUCTURE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the MAPSTRUCTURE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	9 as TRIPNO, 'MAPSTRUCTURE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_MAPSTRUCTURE I 
	right join MAPSTRUCTURE C on( C.STRUCTUREID=I.STRUCTUREID)
where I.STRUCTUREID is null
UNION ALL 
select	9, 'MAPSTRUCTURE', 0, count(*), 0, 0
from CCImport_MAPSTRUCTURE I 
	left join MAPSTRUCTURE C on( C.STRUCTUREID=I.STRUCTUREID)
where C.STRUCTUREID is null
UNION ALL 
 select	9, 'MAPSTRUCTURE', 0, 0, count(*), 0
from CCImport_MAPSTRUCTURE I 
	join MAPSTRUCTURE C	on ( C.STRUCTUREID=I.STRUCTUREID)
where 	( I.STRUCTURENAME <>  C.STRUCTURENAME)
	OR 	( I.TABLENAME <>  C.TABLENAME)
	OR 	( I.KEYCOLUMNAME <>  C.KEYCOLUMNAME)
	OR 	( I.CODECOLUMNNAME <>  C.CODECOLUMNNAME OR (I.CODECOLUMNNAME is null and C.CODECOLUMNNAME is not null) 
OR (I.CODECOLUMNNAME is not null and C.CODECOLUMNNAME is null))
	OR 	( I.DESCCOLUMNNAME <>  C.DESCCOLUMNNAME OR (I.DESCCOLUMNNAME is null and C.DESCCOLUMNNAME is not null) 
OR (I.DESCCOLUMNNAME is not null and C.DESCCOLUMNNAME is null))
	OR 	( I.SEARCHCONTEXTID <>  C.SEARCHCONTEXTID OR (I.SEARCHCONTEXTID is null and C.SEARCHCONTEXTID is not null) 
OR (I.SEARCHCONTEXTID is not null and C.SEARCHCONTEXTID is null))
UNION ALL 
 select	9, 'MAPSTRUCTURE', 0, 0, 0, count(*)
from CCImport_MAPSTRUCTURE I 
join MAPSTRUCTURE C	on( C.STRUCTUREID=I.STRUCTUREID)
where ( I.STRUCTURENAME =  C.STRUCTURENAME)
and ( I.TABLENAME =  C.TABLENAME)
and ( I.KEYCOLUMNAME =  C.KEYCOLUMNAME)
and ( I.CODECOLUMNNAME =  C.CODECOLUMNNAME OR (I.CODECOLUMNNAME is null and C.CODECOLUMNNAME is null))
and ( I.DESCCOLUMNNAME =  C.DESCCOLUMNNAME OR (I.DESCCOLUMNNAME is null and C.DESCCOLUMNNAME is null))
and ( I.SEARCHCONTEXTID =  C.SEARCHCONTEXTID OR (I.SEARCHCONTEXTID is null and C.SEARCHCONTEXTID is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_MAPSTRUCTURE]') and xtype='U')
begin
	drop table CCImport_MAPSTRUCTURE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnMAPSTRUCTURE  to public
go
