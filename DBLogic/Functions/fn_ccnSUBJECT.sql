-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnSUBJECT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnSUBJECT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnSUBJECT.'
	drop function dbo.fn_ccnSUBJECT
	print '**** Creating function dbo.fn_ccnSUBJECT...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_SUBJECT]') and xtype='U')
begin
	select * 
	into CCImport_SUBJECT 
	from SUBJECT
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnSUBJECT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnSUBJECT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the SUBJECT table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'SUBJECT' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_SUBJECT I 
	right join SUBJECT C on( C.SUBJECTCODE=I.SUBJECTCODE)
where I.SUBJECTCODE is null
UNION ALL 
select	5, 'SUBJECT', 0, count(*), 0, 0
from CCImport_SUBJECT I 
	left join SUBJECT C on( C.SUBJECTCODE=I.SUBJECTCODE)
where C.SUBJECTCODE is null
UNION ALL 
 select	5, 'SUBJECT', 0, 0, count(*), 0
from CCImport_SUBJECT I 
	join SUBJECT C	on ( C.SUBJECTCODE=I.SUBJECTCODE)
where 	( I.SUBJECTNAME <>  C.SUBJECTNAME)
UNION ALL 
 select	5, 'SUBJECT', 0, 0, 0, count(*)
from CCImport_SUBJECT I 
join SUBJECT C	on( C.SUBJECTCODE=I.SUBJECTCODE)
where ( I.SUBJECTNAME =  C.SUBJECTNAME)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_SUBJECT]') and xtype='U')
begin
	drop table CCImport_SUBJECT 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnSUBJECT  to public
go
