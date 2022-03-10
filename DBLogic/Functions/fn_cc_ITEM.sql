-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_ITEM
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_ITEM]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_ITEM.'
	drop function dbo.fn_cc_ITEM
	print '**** Creating function dbo.fn_cc_ITEM...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ITEM]') and xtype='U')
begin
	select * 
	into CCImport_ITEM 
	from ITEM
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_ITEM
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_ITEM
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ITEM table
-- CALLED BY :	ip_CopyConfigITEM
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
	 null as 'Imported Item_id',
	 null as 'Imported Item_name',
	 null as 'Imported Sql_query',
	 null as 'Imported Item_description',
	 null as 'Imported Created_by',
	 null as 'Imported Date_created',
	 null as 'Imported Date_updated',
	 null as 'Imported Item_type',
	 null as 'Imported Entry_point_usage',
	 null as 'Imported Sql_describe',
	 null as 'Imported Sql_into',
'D' as '-',
	 C.ITEM_ID as 'Item_id',
	 C.ITEM_NAME as 'Item_name',
	 CAST(C.SQL_QUERY AS NVARCHAR(4000)) as 'Sql_query',
	 C.ITEM_DESCRIPTION as 'Item_description',
	 C.CREATED_BY as 'Created_by',
	 C.DATE_CREATED as 'Date_created',
	 C.DATE_UPDATED as 'Date_updated',
	 C.ITEM_TYPE as 'Item_type',
	 C.ENTRY_POINT_USAGE as 'Entry_point_usage',
	 C.SQL_DESCRIBE as 'Sql_describe',
	 C.SQL_INTO as 'Sql_into'
from CCImport_ITEM I 
	right join ITEM C on( C.ITEM_ID=I.ITEM_ID)
where I.ITEM_ID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.ITEM_ID,
	 I.ITEM_NAME,
	 CAST(I.SQL_QUERY AS NVARCHAR(4000)),
	 I.ITEM_DESCRIPTION,
	 I.CREATED_BY,
	 I.DATE_CREATED,
	 I.DATE_UPDATED,
	 I.ITEM_TYPE,
	 I.ENTRY_POINT_USAGE,
	 I.SQL_DESCRIBE,
	 I.SQL_INTO,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_ITEM I 
	left join ITEM C on( C.ITEM_ID=I.ITEM_ID)
where C.ITEM_ID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.ITEM_ID,
	 I.ITEM_NAME,
	 CAST(I.SQL_QUERY AS NVARCHAR(4000)),
	 I.ITEM_DESCRIPTION,
	 I.CREATED_BY,
	 I.DATE_CREATED,
	 I.DATE_UPDATED,
	 I.ITEM_TYPE,
	 I.ENTRY_POINT_USAGE,
	 I.SQL_DESCRIBE,
	 I.SQL_INTO,
'U',
	 C.ITEM_ID,
	 C.ITEM_NAME,
	 CAST(C.SQL_QUERY AS NVARCHAR(4000)),
	 C.ITEM_DESCRIPTION,
	 C.CREATED_BY,
	 C.DATE_CREATED,
	 C.DATE_UPDATED,
	 C.ITEM_TYPE,
	 C.ENTRY_POINT_USAGE,
	 C.SQL_DESCRIBE,
	 C.SQL_INTO
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

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ITEM]') and xtype='U')
begin
	drop table CCImport_ITEM 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_ITEM  to public
go
