-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_QUERYCONTEXT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_QUERYCONTEXT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_QUERYCONTEXT.'
	drop function dbo.fn_cc_QUERYCONTEXT
	print '**** Creating function dbo.fn_cc_QUERYCONTEXT...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_QUERYCONTEXT]') and xtype='U')
begin
	select * 
	into CCImport_QUERYCONTEXT 
	from QUERYCONTEXT
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_QUERYCONTEXT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_QUERYCONTEXT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the QUERYCONTEXT table
-- CALLED BY :	ip_CopyConfigQUERYCONTEXT
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
	 null as 'Imported Contextid',
	 null as 'Imported Contextname',
	 null as 'Imported Procedurename',
	 null as 'Imported Notes',
	 null as 'Imported Filterxslttodb',
	 null as 'Imported Filterxsltfromdb',
'D' as '-',
	 C.CONTEXTID as 'Contextid',
	 C.CONTEXTNAME as 'Contextname',
	 C.PROCEDURENAME as 'Procedurename',
	 C.NOTES as 'Notes',
	 C.FILTERXSLTTODB as 'Filterxslttodb',
	 C.FILTERXSLTFROMDB as 'Filterxsltfromdb'
from CCImport_QUERYCONTEXT I 
	right join QUERYCONTEXT C on( C.CONTEXTID=I.CONTEXTID)
where I.CONTEXTID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CONTEXTID,
	 I.CONTEXTNAME,
	 I.PROCEDURENAME,
	 I.NOTES,
	 I.FILTERXSLTTODB,
	 I.FILTERXSLTFROMDB,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_QUERYCONTEXT I 
	left join QUERYCONTEXT C on( C.CONTEXTID=I.CONTEXTID)
where C.CONTEXTID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CONTEXTID,
	 I.CONTEXTNAME,
	 I.PROCEDURENAME,
	 I.NOTES,
	 I.FILTERXSLTTODB,
	 I.FILTERXSLTFROMDB,
'U',
	 C.CONTEXTID,
	 C.CONTEXTNAME,
	 C.PROCEDURENAME,
	 C.NOTES,
	 C.FILTERXSLTTODB,
	 C.FILTERXSLTFROMDB
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

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_QUERYCONTEXT]') and xtype='U')
begin
	drop table CCImport_QUERYCONTEXT 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_QUERYCONTEXT  to public
go
