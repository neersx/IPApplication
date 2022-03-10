-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnQUERYCONTEXT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnQUERYCONTEXT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnQUERYCONTEXT.'
	drop function dbo.fn_ccnQUERYCONTEXT
	print '**** Creating function dbo.fn_ccnQUERYCONTEXT...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_QUERYCONTEXT]') and xtype='U')
begin
	select * 
	into CCImport_QUERYCONTEXT 
	from QUERYCONTEXT
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnQUERYCONTEXT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnQUERYCONTEXT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the QUERYCONTEXT table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'QUERYCONTEXT' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_QUERYCONTEXT I 
	right join QUERYCONTEXT C on( C.CONTEXTID=I.CONTEXTID)
where I.CONTEXTID is null
UNION ALL 
select	6, 'QUERYCONTEXT', 0, count(*), 0, 0
from CCImport_QUERYCONTEXT I 
	left join QUERYCONTEXT C on( C.CONTEXTID=I.CONTEXTID)
where C.CONTEXTID is null
UNION ALL 
 select	6, 'QUERYCONTEXT', 0, 0, count(*), 0
from CCImport_QUERYCONTEXT I 
	join QUERYCONTEXT C	on ( C.CONTEXTID=I.CONTEXTID)
where 	( I.CONTEXTNAME <>  C.CONTEXTNAME)
	OR 	( I.PROCEDURENAME <>  C.PROCEDURENAME)
	OR 	(replace( I.NOTES,char(10),char(13)+char(10)) <>  C.NOTES OR (I.NOTES is null and C.NOTES is not null) 
OR (I.NOTES is not null and C.NOTES is null))
	OR 	(replace( I.FILTERXSLTTODB,char(10),char(13)+char(10)) <>  C.FILTERXSLTTODB OR (I.FILTERXSLTTODB is null and C.FILTERXSLTTODB is not null) 
OR (I.FILTERXSLTTODB is not null and C.FILTERXSLTTODB is null))
	OR 	(replace( I.FILTERXSLTFROMDB,char(10),char(13)+char(10)) <>  C.FILTERXSLTFROMDB OR (I.FILTERXSLTFROMDB is null and C.FILTERXSLTFROMDB is not null) 
OR (I.FILTERXSLTFROMDB is not null and C.FILTERXSLTFROMDB is null))
UNION ALL 
 select	6, 'QUERYCONTEXT', 0, 0, 0, count(*)
from CCImport_QUERYCONTEXT I 
join QUERYCONTEXT C	on( C.CONTEXTID=I.CONTEXTID)
where ( I.CONTEXTNAME =  C.CONTEXTNAME)
and ( I.PROCEDURENAME =  C.PROCEDURENAME)
and (replace( I.NOTES,char(10),char(13)+char(10)) =  C.NOTES OR (I.NOTES is null and C.NOTES is null))
and (replace( I.FILTERXSLTTODB,char(10),char(13)+char(10)) =  C.FILTERXSLTTODB OR (I.FILTERXSLTTODB is null and C.FILTERXSLTTODB is null))
and (replace( I.FILTERXSLTFROMDB,char(10),char(13)+char(10)) =  C.FILTERXSLTFROMDB OR (I.FILTERXSLTFROMDB is null and C.FILTERXSLTFROMDB is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_QUERYCONTEXT]') and xtype='U')
begin
	drop table CCImport_QUERYCONTEXT 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnQUERYCONTEXT  to public
go
