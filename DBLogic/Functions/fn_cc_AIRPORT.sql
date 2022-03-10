-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_AIRPORT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_AIRPORT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_AIRPORT.'
	drop function dbo.fn_cc_AIRPORT
	print '**** Creating function dbo.fn_cc_AIRPORT...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_AIRPORT]') and xtype='U')
begin
	select * 
	into CCImport_AIRPORT 
	from AIRPORT
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_AIRPORT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_AIRPORT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the AIRPORT table
-- CALLED BY :	ip_CopyConfigAIRPORT
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	1 as 'Switch',
	'X' as 'Match',
	'D' as 'Imported -',
	 null as 'Imported Airportcode',
	 null as 'Imported Airportname',
	 null as 'Imported Countrycode',
	 null as 'Imported State',
	 null as 'Imported City',
'D' as '-',
	 C.AIRPORTCODE as 'Airportcode',
	 C.AIRPORTNAME as 'Airportname',
	 C.COUNTRYCODE as 'Countrycode',
	 C.STATE as 'State',
	 C.CITY as 'City'
from CCImport_AIRPORT I 
	right join AIRPORT C on( C.AIRPORTCODE=I.AIRPORTCODE)
where I.AIRPORTCODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.AIRPORTCODE,
	 I.AIRPORTNAME,
	 I.COUNTRYCODE,
	 I.STATE,
	 I.CITY,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_AIRPORT I 
	left join AIRPORT C on( C.AIRPORTCODE=I.AIRPORTCODE)
where C.AIRPORTCODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.AIRPORTCODE,
	 I.AIRPORTNAME,
	 I.COUNTRYCODE,
	 I.STATE,
	 I.CITY,
'U',
	 C.AIRPORTCODE,
	 C.AIRPORTNAME,
	 C.COUNTRYCODE,
	 C.STATE,
	 C.CITY
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

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_AIRPORT]') and xtype='U')
begin
	drop table CCImport_AIRPORT 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_AIRPORT  to public
go
