-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnCULTURE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnCULTURE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnCULTURE.'
	drop function dbo.fn_ccnCULTURE
	print '**** Creating function dbo.fn_ccnCULTURE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_CULTURE]') and xtype='U')
begin

	select * 
	into CCImport_CULTURE 
	from CULTURE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnCULTURE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnCULTURE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CULTURE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	4 as TRIPNO, 'CULTURE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_CULTURE I 
	right join CULTURE C on( C.CULTURE=I.CULTURE)
where I.CULTURE is null
UNION ALL 
select	4, 'CULTURE', 0, count(*), 0, 0
from CCImport_CULTURE I 
	left join CULTURE C on( C.CULTURE=I.CULTURE)
where C.CULTURE is null
UNION ALL 
 select	4, 'CULTURE', 0, 0, count(*), 0
from CCImport_CULTURE I 
	join CULTURE C	on ( C.CULTURE=I.CULTURE)
where 	( I.DESCRIPTION <>  C.DESCRIPTION)
	OR 	( I.ISTRANSLATED <>  C.ISTRANSLATED)
UNION ALL 
 select	4, 'CULTURE', 0, 0, 0, count(*)
from CCImport_CULTURE I 
join CULTURE C	on( C.CULTURE=I.CULTURE)
where ( I.DESCRIPTION =  C.DESCRIPTION)
and ( I.ISTRANSLATED =  C.ISTRANSLATED)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CULTURE]') and xtype='U')
begin
	drop table CCImport_CULTURE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnCULTURE  to public
go
