-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnVALIDRELATIONSHIPS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnVALIDRELATIONSHIPS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnVALIDRELATIONSHIPS.'
	drop function dbo.fn_ccnVALIDRELATIONSHIPS
	print '**** Creating function dbo.fn_ccnVALIDRELATIONSHIPS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDRELATIONSHIPS]') and xtype='U')
begin
	select * 
	into CCImport_VALIDRELATIONSHIPS 
	from VALIDRELATIONSHIPS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnVALIDRELATIONSHIPS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnVALIDRELATIONSHIPS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the VALIDRELATIONSHIPS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	3 as TRIPNO, 'VALIDRELATIONSHIPS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_VALIDRELATIONSHIPS I 
	right join VALIDRELATIONSHIPS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.RELATIONSHIP=I.RELATIONSHIP)
where I.COUNTRYCODE is null
UNION ALL 
select	3, 'VALIDRELATIONSHIPS', 0, count(*), 0, 0
from CCImport_VALIDRELATIONSHIPS I 
	left join VALIDRELATIONSHIPS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.RELATIONSHIP=I.RELATIONSHIP)
where C.COUNTRYCODE is null
UNION ALL 
 select	3, 'VALIDRELATIONSHIPS', 0, 0, count(*), 0
from CCImport_VALIDRELATIONSHIPS I 
	join VALIDRELATIONSHIPS C	on ( C.COUNTRYCODE=I.COUNTRYCODE
	and C.PROPERTYTYPE=I.PROPERTYTYPE
	and C.RELATIONSHIP=I.RELATIONSHIP)
where 	( I.RECIPRELATIONSHIP <>  C.RECIPRELATIONSHIP OR (I.RECIPRELATIONSHIP is null and C.RECIPRELATIONSHIP is not null) 
OR (I.RECIPRELATIONSHIP is not null and C.RECIPRELATIONSHIP is null))
UNION ALL 
 select	3, 'VALIDRELATIONSHIPS', 0, 0, 0, count(*)
from CCImport_VALIDRELATIONSHIPS I 
join VALIDRELATIONSHIPS C	on( C.COUNTRYCODE=I.COUNTRYCODE
and C.PROPERTYTYPE=I.PROPERTYTYPE
and C.RELATIONSHIP=I.RELATIONSHIP)
where ( I.RECIPRELATIONSHIP =  C.RECIPRELATIONSHIP OR (I.RECIPRELATIONSHIP is null and C.RECIPRELATIONSHIP is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDRELATIONSHIPS]') and xtype='U')
begin
	drop table CCImport_VALIDRELATIONSHIPS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnVALIDRELATIONSHIPS  to public
go
