-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnSUBJECTAREA
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnSUBJECTAREA]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnSUBJECTAREA.'
	drop function dbo.fn_ccnSUBJECTAREA
	print '**** Creating function dbo.fn_ccnSUBJECTAREA...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_SUBJECTAREA]') and xtype='U')
begin
	select * 
	into CCImport_SUBJECTAREA 
	from SUBJECTAREA
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnSUBJECTAREA
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnSUBJECTAREA
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the SUBJECTAREA table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'SUBJECTAREA' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_SUBJECTAREA I 
	right join SUBJECTAREA C on( C.SUBJECTAREANO=I.SUBJECTAREANO)
where I.SUBJECTAREANO is null
UNION ALL 
select	5, 'SUBJECTAREA', 0, count(*), 0, 0
from CCImport_SUBJECTAREA I 
	left join SUBJECTAREA C on( C.SUBJECTAREANO=I.SUBJECTAREANO)
where C.SUBJECTAREANO is null
UNION ALL 
 select	5, 'SUBJECTAREA', 0, 0, count(*), 0
from CCImport_SUBJECTAREA I 
	join SUBJECTAREA C	on ( C.SUBJECTAREANO=I.SUBJECTAREANO)
where 	( I.PARENTTABLE <>  C.PARENTTABLE OR (I.PARENTTABLE is null and C.PARENTTABLE is not null) 
OR (I.PARENTTABLE is not null and C.PARENTTABLE is null))
	OR 	(replace( I.SUBJECTAREADESC,char(10),char(13)+char(10)) <>  C.SUBJECTAREADESC)
UNION ALL 
 select	5, 'SUBJECTAREA', 0, 0, 0, count(*)
from CCImport_SUBJECTAREA I 
join SUBJECTAREA C	on( C.SUBJECTAREANO=I.SUBJECTAREANO)
where ( I.PARENTTABLE =  C.PARENTTABLE OR (I.PARENTTABLE is null and C.PARENTTABLE is null))
and (replace( I.SUBJECTAREADESC,char(10),char(13)+char(10)) =  C.SUBJECTAREADESC)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_SUBJECTAREA]') and xtype='U')
begin
	drop table CCImport_SUBJECTAREA 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnSUBJECTAREA  to public
go
