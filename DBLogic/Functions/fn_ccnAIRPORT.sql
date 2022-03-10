-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnAIRPORT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnAIRPORT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnAIRPORT.'
	drop function dbo.fn_ccnAIRPORT
	print '**** Creating function dbo.fn_ccnAIRPORT...'
	print ''
end
go

SET NOCOUNT ON
GO

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_AIRPORT]') and xtype='U')
begin
	select * 
	into CCImport_AIRPORT 
	from AIRPORT
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnAIRPORT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnAIRPORT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the AIRPORT table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	4 as TRIPNO, 'AIRPORT' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_AIRPORT I 
	right join AIRPORT C on( C.AIRPORTCODE=I.AIRPORTCODE)
where I.AIRPORTCODE is null
UNION ALL 
select	4, 'AIRPORT', 0, count(*), 0, 0
from CCImport_AIRPORT I 
	left join AIRPORT C on( C.AIRPORTCODE=I.AIRPORTCODE)
where C.AIRPORTCODE is null
UNION ALL 
 select	4, 'AIRPORT', 0, 0, count(*), 0
from CCImport_AIRPORT I 
	join AIRPORT C	on ( C.AIRPORTCODE=I.AIRPORTCODE)
where 	( I.AIRPORTNAME <>  C.AIRPORTNAME OR (I.AIRPORTNAME is null and C.AIRPORTNAME is not null) 
OR (I.AIRPORTNAME is not null and C.AIRPORTNAME is null))
	OR 	( I.COUNTRYCODE <>  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is not null) 
OR (I.COUNTRYCODE is not null and C.COUNTRYCODE is null))
	OR 	( I.STATE <>  C.STATE OR (I.STATE is null and C.STATE is not null) 
OR (I.STATE is not null and C.STATE is null))
	OR 	( I.CITY <>  C.CITY OR (I.CITY is null and C.CITY is not null) 
OR (I.CITY is not null and C.CITY is null))
UNION ALL 
 select	4, 'AIRPORT', 0, 0, 0, count(*)
from CCImport_AIRPORT I 
join AIRPORT C	on( C.AIRPORTCODE=I.AIRPORTCODE)
where ( I.AIRPORTNAME =  C.AIRPORTNAME OR (I.AIRPORTNAME is null and C.AIRPORTNAME is null))
and ( I.COUNTRYCODE =  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is null))
and ( I.STATE =  C.STATE OR (I.STATE is null and C.STATE is null))
and ( I.CITY =  C.CITY OR (I.CITY is null and C.CITY is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_AIRPORT]') and xtype='U')
begin
	drop table CCImport_AIRPORT 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnAIRPORT  to public
go