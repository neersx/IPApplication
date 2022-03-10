-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnCRITERIA_ITEMS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnCRITERIA_ITEMS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnCRITERIA_ITEMS.'
	drop function dbo.fn_ccnCRITERIA_ITEMS
	print '**** Creating function dbo.fn_ccnCRITERIA_ITEMS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_CRITERIA_ITEMS]') and xtype='U')
begin
	select * 
	into CCImport_CRITERIA_ITEMS 
	from CRITERIA_ITEMS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnCRITERIA_ITEMS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnCRITERIA_ITEMS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CRITERIA_ITEMS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'CRITERIA_ITEMS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_CRITERIA_ITEMS I 
	right join CRITERIA_ITEMS C on( C.CRITERIA_ID=I.CRITERIA_ID)
where I.CRITERIA_ID is null
UNION ALL 
select	5, 'CRITERIA_ITEMS', 0, count(*), 0, 0
from CCImport_CRITERIA_ITEMS I 
	left join CRITERIA_ITEMS C on( C.CRITERIA_ID=I.CRITERIA_ID)
where C.CRITERIA_ID is null
UNION ALL 
 select	5, 'CRITERIA_ITEMS', 0, 0, count(*), 0
from CCImport_CRITERIA_ITEMS I 
	join CRITERIA_ITEMS C	on ( C.CRITERIA_ID=I.CRITERIA_ID)
where 	( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( replace(CAST(I.QUERY as NVARCHAR(MAX)),char(10),char(13)+char(10)) <>  CAST(C.QUERY as NVARCHAR(MAX)) OR (I.QUERY is null and C.QUERY is not null) 
OR (I.QUERY is not null and C.QUERY is null))
	OR 	( I.CELL1 <>  C.CELL1 OR (I.CELL1 is null and C.CELL1 is not null) 
OR (I.CELL1 is not null and C.CELL1 is null))
	OR 	( I.LITERAL1 <>  C.LITERAL1 OR (I.LITERAL1 is null and C.LITERAL1 is not null) 
OR (I.LITERAL1 is not null and C.LITERAL1 is null))
	OR 	( I.CELL2 <>  C.CELL2 OR (I.CELL2 is null and C.CELL2 is not null) 
OR (I.CELL2 is not null and C.CELL2 is null))
	OR 	( I.LITERAL2 <>  C.LITERAL2 OR (I.LITERAL2 is null and C.LITERAL2 is not null) 
OR (I.LITERAL2 is not null and C.LITERAL2 is null))
	OR 	( I.CELL3 <>  C.CELL3 OR (I.CELL3 is null and C.CELL3 is not null) 
OR (I.CELL3 is not null and C.CELL3 is null))
	OR 	( I.LITERAL3 <>  C.LITERAL3 OR (I.LITERAL3 is null and C.LITERAL3 is not null) 
OR (I.LITERAL3 is not null and C.LITERAL3 is null))
	OR 	( I.CELL4 <>  C.CELL4 OR (I.CELL4 is null and C.CELL4 is not null) 
OR (I.CELL4 is not null and C.CELL4 is null))
	OR 	( I.LITERAL4 <>  C.LITERAL4 OR (I.LITERAL4 is null and C.LITERAL4 is not null) 
OR (I.LITERAL4 is not null and C.LITERAL4 is null))
	OR 	( I.CELL5 <>  C.CELL5 OR (I.CELL5 is null and C.CELL5 is not null) 
OR (I.CELL5 is not null and C.CELL5 is null))
	OR 	( I.LITERAL5 <>  C.LITERAL5 OR (I.LITERAL5 is null and C.LITERAL5 is not null) 
OR (I.LITERAL5 is not null and C.LITERAL5 is null))
	OR 	( I.CELL6 <>  C.CELL6 OR (I.CELL6 is null and C.CELL6 is not null) 
OR (I.CELL6 is not null and C.CELL6 is null))
	OR 	( I.LITERAL6 <>  C.LITERAL6 OR (I.LITERAL6 is null and C.LITERAL6 is not null) 
OR (I.LITERAL6 is not null and C.LITERAL6 is null))
	OR 	( I.BACKLINK <>  C.BACKLINK OR (I.BACKLINK is null and C.BACKLINK is not null) 
OR (I.BACKLINK is not null and C.BACKLINK is null))
UNION ALL 
 select	5, 'CRITERIA_ITEMS', 0, 0, 0, count(*)
from CCImport_CRITERIA_ITEMS I 
join CRITERIA_ITEMS C	on( C.CRITERIA_ID=I.CRITERIA_ID)
where ( I.DESCRIPTION =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))
and ( replace(CAST(I.QUERY as NVARCHAR(MAX)),char(10),char(13)+char(10)) =  CAST(C.QUERY as NVARCHAR(MAX)) OR (I.QUERY is null and C.QUERY is null))
and ( I.CELL1 =  C.CELL1 OR (I.CELL1 is null and C.CELL1 is null))
and ( I.LITERAL1 =  C.LITERAL1 OR (I.LITERAL1 is null and C.LITERAL1 is null))
and ( I.CELL2 =  C.CELL2 OR (I.CELL2 is null and C.CELL2 is null))
and ( I.LITERAL2 =  C.LITERAL2 OR (I.LITERAL2 is null and C.LITERAL2 is null))
and ( I.CELL3 =  C.CELL3 OR (I.CELL3 is null and C.CELL3 is null))
and ( I.LITERAL3 =  C.LITERAL3 OR (I.LITERAL3 is null and C.LITERAL3 is null))
and ( I.CELL4 =  C.CELL4 OR (I.CELL4 is null and C.CELL4 is null))
and ( I.LITERAL4 =  C.LITERAL4 OR (I.LITERAL4 is null and C.LITERAL4 is null))
and ( I.CELL5 =  C.CELL5 OR (I.CELL5 is null and C.CELL5 is null))
and ( I.LITERAL5 =  C.LITERAL5 OR (I.LITERAL5 is null and C.LITERAL5 is null))
and ( I.CELL6 =  C.CELL6 OR (I.CELL6 is null and C.CELL6 is null))
and ( I.LITERAL6 =  C.LITERAL6 OR (I.LITERAL6 is null and C.LITERAL6 is null))
and ( I.BACKLINK =  C.BACKLINK OR (I.BACKLINK is null and C.BACKLINK is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CRITERIA_ITEMS]') and xtype='U')
begin
	drop table CCImport_CRITERIA_ITEMS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnCRITERIA_ITEMS  to public
go
