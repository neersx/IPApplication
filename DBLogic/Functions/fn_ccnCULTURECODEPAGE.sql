-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnCULTURECODEPAGE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnCULTURECODEPAGE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnCULTURECODEPAGE.'
	drop function dbo.fn_ccnCULTURECODEPAGE
	print '**** Creating function dbo.fn_ccnCULTURECODEPAGE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_CULTURECODEPAGE]') and xtype='U')
begin
	select * 
	into CCImport_CULTURECODEPAGE 
	from CULTURECODEPAGE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnCULTURECODEPAGE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnCULTURECODEPAGE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CULTURECODEPAGE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	4 as TRIPNO, 'CULTURECODEPAGE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_CULTURECODEPAGE I 
	right join CULTURECODEPAGE C on( C.CODEPAGE=I.CODEPAGE
and  C.CULTURE=I.CULTURE)
where I.CODEPAGE is null
UNION ALL 
select	4, 'CULTURECODEPAGE', 0, count(*), 0, 0
from CCImport_CULTURECODEPAGE I 
	left join CULTURECODEPAGE C on( C.CODEPAGE=I.CODEPAGE
and  C.CULTURE=I.CULTURE)
where C.CODEPAGE is null
UNION ALL 
 select	4, 'CULTURECODEPAGE', 0, 0, 0, count(*)
from CCImport_CULTURECODEPAGE I 
join CULTURECODEPAGE C	on( C.CODEPAGE=I.CODEPAGE
and C.CULTURE=I.CULTURE)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CULTURECODEPAGE]') and xtype='U')
begin
	drop table CCImport_CULTURECODEPAGE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnCULTURECODEPAGE  to public
go
