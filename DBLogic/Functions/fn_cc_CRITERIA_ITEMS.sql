-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_CRITERIA_ITEMS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_CRITERIA_ITEMS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_CRITERIA_ITEMS.'
	drop function dbo.fn_cc_CRITERIA_ITEMS
	print '**** Creating function dbo.fn_cc_CRITERIA_ITEMS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
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


CREATE FUNCTION dbo.fn_cc_CRITERIA_ITEMS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_CRITERIA_ITEMS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CRITERIA_ITEMS table
-- CALLED BY :	ip_CopyConfigCRITERIA_ITEMS
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
	 null as 'Imported Criteria_id',
	 null as 'Imported Description',
	 null as 'Imported Query',
	 null as 'Imported Cell1',
	 null as 'Imported Literal1',
	 null as 'Imported Cell2',
	 null as 'Imported Literal2',
	 null as 'Imported Cell3',
	 null as 'Imported Literal3',
	 null as 'Imported Cell4',
	 null as 'Imported Literal4',
	 null as 'Imported Cell5',
	 null as 'Imported Literal5',
	 null as 'Imported Cell6',
	 null as 'Imported Literal6',
	 null as 'Imported Backlink',
'D' as '-',
	 C.CRITERIA_ID as 'Criteria_id',
	 C.DESCRIPTION as 'Description',
	 CAST(C.QUERY AS NVARCHAR(4000)) as 'Query',
	 C.CELL1 as 'Cell1',
	 C.LITERAL1 as 'Literal1',
	 C.CELL2 as 'Cell2',
	 C.LITERAL2 as 'Literal2',
	 C.CELL3 as 'Cell3',
	 C.LITERAL3 as 'Literal3',
	 C.CELL4 as 'Cell4',
	 C.LITERAL4 as 'Literal4',
	 C.CELL5 as 'Cell5',
	 C.LITERAL5 as 'Literal5',
	 C.CELL6 as 'Cell6',
	 C.LITERAL6 as 'Literal6',
	 C.BACKLINK as 'Backlink'
from CCImport_CRITERIA_ITEMS I 
	right join CRITERIA_ITEMS C on( C.CRITERIA_ID=I.CRITERIA_ID)
where I.CRITERIA_ID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIA_ID,
	 I.DESCRIPTION,
	 CAST(I.QUERY AS NVARCHAR(4000)),
	 I.CELL1,
	 I.LITERAL1,
	 I.CELL2,
	 I.LITERAL2,
	 I.CELL3,
	 I.LITERAL3,
	 I.CELL4,
	 I.LITERAL4,
	 I.CELL5,
	 I.LITERAL5,
	 I.CELL6,
	 I.LITERAL6,
	 I.BACKLINK,
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
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_CRITERIA_ITEMS I 
	left join CRITERIA_ITEMS C on( C.CRITERIA_ID=I.CRITERIA_ID)
where C.CRITERIA_ID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIA_ID,
	 I.DESCRIPTION,
	 CAST(I.QUERY AS NVARCHAR(4000)),
	 I.CELL1,
	 I.LITERAL1,
	 I.CELL2,
	 I.LITERAL2,
	 I.CELL3,
	 I.LITERAL3,
	 I.CELL4,
	 I.LITERAL4,
	 I.CELL5,
	 I.LITERAL5,
	 I.CELL6,
	 I.LITERAL6,
	 I.BACKLINK,
'U',
	 C.CRITERIA_ID,
	 C.DESCRIPTION,
	 CAST(C.QUERY AS NVARCHAR(4000)),
	 C.CELL1,
	 C.LITERAL1,
	 C.CELL2,
	 C.LITERAL2,
	 C.CELL3,
	 C.LITERAL3,
	 C.CELL4,
	 C.LITERAL4,
	 C.CELL5,
	 C.LITERAL5,
	 C.CELL6,
	 C.LITERAL6,
	 C.BACKLINK
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

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CRITERIA_ITEMS]') and xtype='U')
begin
	drop table CCImport_CRITERIA_ITEMS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_CRITERIA_ITEMS  to public
go

