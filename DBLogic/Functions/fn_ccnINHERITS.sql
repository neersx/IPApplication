-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnINHERITS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnINHERITS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnINHERITS.'
	drop function dbo.fn_ccnINHERITS
	print '**** Creating function dbo.fn_ccnINHERITS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_INHERITS]') and xtype='U')
begin
	select * 
	into CCImport_INHERITS 
	from INHERITS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnINHERITS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnINHERITS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the INHERITS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'INHERITS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_INHERITS I 
	right join INHERITS C on( C.CRITERIANO=I.CRITERIANO
and  C.FROMCRITERIA=I.FROMCRITERIA)
where I.CRITERIANO is null
UNION ALL 
select	5, 'INHERITS', 0, count(*), 0, 0
from CCImport_INHERITS I 
	left join INHERITS C on( C.CRITERIANO=I.CRITERIANO
and  C.FROMCRITERIA=I.FROMCRITERIA)
where C.CRITERIANO is null
UNION ALL 
 select	5, 'INHERITS', 0, 0, 0, count(*)
from CCImport_INHERITS I 
join INHERITS C	on( C.CRITERIANO=I.CRITERIANO
and C.FROMCRITERIA=I.FROMCRITERIA)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_INHERITS]') and xtype='U')
begin
	drop table CCImport_INHERITS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnINHERITS  to public
go
