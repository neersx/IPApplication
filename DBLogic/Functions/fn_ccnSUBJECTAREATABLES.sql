-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnSUBJECTAREATABLES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnSUBJECTAREATABLES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnSUBJECTAREATABLES.'
	drop function dbo.fn_ccnSUBJECTAREATABLES
	print '**** Creating function dbo.fn_ccnSUBJECTAREATABLES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_SUBJECTAREATABLES]') and xtype='U')
begin
	select * 
	into CCImport_SUBJECTAREATABLES 
	from SUBJECTAREATABLES
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnSUBJECTAREATABLES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnSUBJECTAREATABLES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the SUBJECTAREATABLES table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'SUBJECTAREATABLES' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_SUBJECTAREATABLES I 
	right join SUBJECTAREATABLES C on( C.SUBJECTAREANO=I.SUBJECTAREANO
and  C.TABLENAME=I.TABLENAME)
where I.SUBJECTAREANO is null
UNION ALL 
select	5, 'SUBJECTAREATABLES', 0, count(*), 0, 0
from CCImport_SUBJECTAREATABLES I 
	left join SUBJECTAREATABLES C on( C.SUBJECTAREANO=I.SUBJECTAREANO
and  C.TABLENAME=I.TABLENAME)
where C.SUBJECTAREANO is null
UNION ALL 
 select	5, 'SUBJECTAREATABLES', 0, 0, count(*), 0
from CCImport_SUBJECTAREATABLES I 
	join SUBJECTAREATABLES C	on ( C.SUBJECTAREANO=I.SUBJECTAREANO
	and C.TABLENAME=I.TABLENAME)
where 	( I.DEPTH <>  C.DEPTH)
UNION ALL 
 select	5, 'SUBJECTAREATABLES', 0, 0, 0, count(*)
from CCImport_SUBJECTAREATABLES I 
join SUBJECTAREATABLES C	on( C.SUBJECTAREANO=I.SUBJECTAREANO
and C.TABLENAME=I.TABLENAME)
where ( I.DEPTH =  C.DEPTH)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_SUBJECTAREATABLES]') and xtype='U')
begin
	drop table CCImport_SUBJECTAREATABLES 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnSUBJECTAREATABLES  to public
go
