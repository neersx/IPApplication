-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnITEM
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnITEM]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnITEM.'
	drop function dbo.fn_ccnITEM
	print '**** Creating function dbo.fn_ccnITEM...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ITEM]') and xtype='U')
begin
	select * 
	into CCImport_ITEM 
	from ITEM
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnITEM
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnITEM
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ITEM table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	10 as TRIPNO, 'ITEM' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_ITEM I 
	right join ITEM C on( C.ITEM_ID=I.ITEM_ID)
where I.ITEM_ID is null
UNION ALL 
select	10, 'ITEM', 0, count(*), 0, 0
from CCImport_ITEM I 
	left join ITEM C on( C.ITEM_ID=I.ITEM_ID)
where C.ITEM_ID is null
UNION ALL 
 select	10, 'ITEM', 0, 0, count(*), 0
from CCImport_ITEM I 
	join ITEM C	on ( C.ITEM_ID=I.ITEM_ID)
where 	( I.ITEM_NAME <>  C.ITEM_NAME)
	OR 	( replace(CAST(I.SQL_QUERY as NVARCHAR(MAX)),char(10),char(13)+char(10)) <>  CAST(C.SQL_QUERY as NVARCHAR(MAX)))
	OR 	(replace( I.ITEM_DESCRIPTION,char(10),char(13)+char(10)) <>  C.ITEM_DESCRIPTION)
	OR 	( I.CREATED_BY <>  C.CREATED_BY OR (I.CREATED_BY is null and C.CREATED_BY is not null) 
OR (I.CREATED_BY is not null and C.CREATED_BY is null))
	OR 	( I.DATE_CREATED <>  C.DATE_CREATED OR (I.DATE_CREATED is null and C.DATE_CREATED is not null) 
OR (I.DATE_CREATED is not null and C.DATE_CREATED is null))
	OR 	( I.DATE_UPDATED <>  C.DATE_UPDATED OR (I.DATE_UPDATED is null and C.DATE_UPDATED is not null) 
OR (I.DATE_UPDATED is not null and C.DATE_UPDATED is null))
	OR 	( I.ITEM_TYPE <>  C.ITEM_TYPE OR (I.ITEM_TYPE is null and C.ITEM_TYPE is not null) 
OR (I.ITEM_TYPE is not null and C.ITEM_TYPE is null))
	OR 	( I.ENTRY_POINT_USAGE <>  C.ENTRY_POINT_USAGE OR (I.ENTRY_POINT_USAGE is null and C.ENTRY_POINT_USAGE is not null) 
OR (I.ENTRY_POINT_USAGE is not null and C.ENTRY_POINT_USAGE is null))
	OR 	(replace( I.SQL_DESCRIBE,char(10),char(13)+char(10)) <>  C.SQL_DESCRIBE OR (I.SQL_DESCRIBE is null and C.SQL_DESCRIBE is not null) 
OR (I.SQL_DESCRIBE is not null and C.SQL_DESCRIBE is null))
	OR 	(replace( I.SQL_INTO,char(10),char(13)+char(10)) <>  C.SQL_INTO OR (I.SQL_INTO is null and C.SQL_INTO is not null) 
OR (I.SQL_INTO is not null and C.SQL_INTO is null))
UNION ALL 
 select	10, 'ITEM', 0, 0, 0, count(*)
from CCImport_ITEM I 
join ITEM C	on( C.ITEM_ID=I.ITEM_ID)
where ( I.ITEM_NAME =  C.ITEM_NAME)
and ( replace(CAST(I.SQL_QUERY as NVARCHAR(MAX)),char(10),char(13)+char(10)) =  CAST(C.SQL_QUERY as NVARCHAR(MAX)))
and (replace( I.ITEM_DESCRIPTION,char(10),char(13)+char(10)) =  C.ITEM_DESCRIPTION)
and ( I.CREATED_BY =  C.CREATED_BY OR (I.CREATED_BY is null and C.CREATED_BY is null))
and ( I.DATE_CREATED =  C.DATE_CREATED OR (I.DATE_CREATED is null and C.DATE_CREATED is null))
and ( I.DATE_UPDATED =  C.DATE_UPDATED OR (I.DATE_UPDATED is null and C.DATE_UPDATED is null))
and ( I.ITEM_TYPE =  C.ITEM_TYPE OR (I.ITEM_TYPE is null and C.ITEM_TYPE is null))
and ( I.ENTRY_POINT_USAGE =  C.ENTRY_POINT_USAGE OR (I.ENTRY_POINT_USAGE is null and C.ENTRY_POINT_USAGE is null))
and (replace( I.SQL_DESCRIBE,char(10),char(13)+char(10)) =  C.SQL_DESCRIBE OR (I.SQL_DESCRIBE is null and C.SQL_DESCRIBE is null))
and (replace( I.SQL_INTO,char(10),char(13)+char(10)) =  C.SQL_INTO OR (I.SQL_INTO is null and C.SQL_INTO is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ITEM]') and xtype='U')
begin
	drop table CCImport_ITEM 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnITEM  to public
go
