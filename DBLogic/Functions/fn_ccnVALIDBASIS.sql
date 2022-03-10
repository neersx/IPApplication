-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnVALIDBASIS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnVALIDBASIS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnVALIDBASIS.'
	drop function dbo.fn_ccnVALIDBASIS
	print '**** Creating function dbo.fn_ccnVALIDBASIS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDBASIS]') and xtype='U')
begin
	select * 
	into CCImport_VALIDBASIS 
	from VALIDBASIS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnVALIDBASIS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnVALIDBASIS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the VALIDBASIS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	3 as TRIPNO, 'VALIDBASIS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_VALIDBASIS I 
	right join VALIDBASIS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.BASIS=I.BASIS)
where I.COUNTRYCODE is null
UNION ALL 
select	3, 'VALIDBASIS', 0, count(*), 0, 0
from CCImport_VALIDBASIS I 
	left join VALIDBASIS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.BASIS=I.BASIS)
where C.COUNTRYCODE is null
UNION ALL 
 select	3, 'VALIDBASIS', 0, 0, count(*), 0
from CCImport_VALIDBASIS I 
	join VALIDBASIS C	on ( C.COUNTRYCODE=I.COUNTRYCODE
	and C.PROPERTYTYPE=I.PROPERTYTYPE
	and C.BASIS=I.BASIS)
where 	( I.BASISDESCRIPTION <>  C.BASISDESCRIPTION OR (I.BASISDESCRIPTION is null and C.BASISDESCRIPTION is not null) 
OR (I.BASISDESCRIPTION is not null and C.BASISDESCRIPTION is null))
UNION ALL 
 select	3, 'VALIDBASIS', 0, 0, 0, count(*)
from CCImport_VALIDBASIS I 
join VALIDBASIS C	on( C.COUNTRYCODE=I.COUNTRYCODE
and C.PROPERTYTYPE=I.PROPERTYTYPE
and C.BASIS=I.BASIS)
where ( I.BASISDESCRIPTION =  C.BASISDESCRIPTION OR (I.BASISDESCRIPTION is null and C.BASISDESCRIPTION is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDBASIS]') and xtype='U')
begin
	drop table CCImport_VALIDBASIS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnVALIDBASIS  to public
go
