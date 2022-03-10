-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnDOCUMENT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnDOCUMENT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnDOCUMENT.'
	drop function dbo.fn_ccnDOCUMENT
	print '**** Creating function dbo.fn_ccnDOCUMENT...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_DOCUMENT]') and xtype='U')
begin
	select * 
	into CCImport_DOCUMENT 
	from DOCUMENT
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnDOCUMENT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnDOCUMENT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the DOCUMENT table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'DOCUMENT' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_DOCUMENT I 
	right join DOCUMENT C on( C.DOCUMENTNO=I.DOCUMENTNO)
where I.DOCUMENTNO is null
UNION ALL 
select	5, 'DOCUMENT', 0, count(*), 0, 0
from CCImport_DOCUMENT I 
	left join DOCUMENT C on( C.DOCUMENTNO=I.DOCUMENTNO)
where C.DOCUMENTNO is null
UNION ALL 
 select	5, 'DOCUMENT', 0, 0, count(*), 0
from CCImport_DOCUMENT I 
	join DOCUMENT C	on ( C.DOCUMENTNO=I.DOCUMENTNO)
where 	( I.DOCDESCRIPTION <>  C.DOCDESCRIPTION OR (I.DOCDESCRIPTION is null and C.DOCDESCRIPTION is not null) 
OR (I.DOCDESCRIPTION is not null and C.DOCDESCRIPTION is null))
UNION ALL 
 select	5, 'DOCUMENT', 0, 0, 0, count(*)
from CCImport_DOCUMENT I 
join DOCUMENT C	on( C.DOCUMENTNO=I.DOCUMENTNO)
where ( I.DOCDESCRIPTION =  C.DOCDESCRIPTION OR (I.DOCDESCRIPTION is null and C.DOCDESCRIPTION is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DOCUMENT]') and xtype='U')
begin
	drop table CCImport_DOCUMENT 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnDOCUMENT  to public
go
