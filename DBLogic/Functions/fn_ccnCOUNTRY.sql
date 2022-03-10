-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnCOUNTRY
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnCOUNTRY]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnCOUNTRY.'
	drop function dbo.fn_ccnCOUNTRY
	print '**** Creating function dbo.fn_ccnCOUNTRY...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_COUNTRY]') and xtype='U')
begin
	select * 
	into CCImport_COUNTRY 
	from COUNTRY
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnCOUNTRY
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnCOUNTRY
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the COUNTRY table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	4 as TRIPNO, 'COUNTRY' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_COUNTRY I 
	right join COUNTRY C on( C.COUNTRYCODE=I.COUNTRYCODE)
where I.COUNTRYCODE is null
UNION ALL 
select	4, 'COUNTRY', 0, count(*), 0, 0
from CCImport_COUNTRY I 
	left join COUNTRY C on( C.COUNTRYCODE=I.COUNTRYCODE)
where C.COUNTRYCODE is null
UNION ALL 
 select	4, 'COUNTRY', 0, 0, count(*), 0
from CCImport_COUNTRY I 
	join COUNTRY C	on ( C.COUNTRYCODE=I.COUNTRYCODE)
where 	( I.ALTERNATECODE <>  C.ALTERNATECODE OR (I.ALTERNATECODE is null and C.ALTERNATECODE is not null) 
OR (I.ALTERNATECODE is not null and C.ALTERNATECODE is null))
	OR 	( I.COUNTRY <>  C.COUNTRY OR (I.COUNTRY is null and C.COUNTRY is not null) 
OR (I.COUNTRY is not null and C.COUNTRY is null))
	OR 	( I.INFORMALNAME <>  C.INFORMALNAME OR (I.INFORMALNAME is null and C.INFORMALNAME is not null) 
OR (I.INFORMALNAME is not null and C.INFORMALNAME is null))
	OR 	( I.COUNTRYABBREV <>  C.COUNTRYABBREV OR (I.COUNTRYABBREV is null and C.COUNTRYABBREV is not null) 
OR (I.COUNTRYABBREV is not null and C.COUNTRYABBREV is null))
	OR 	( I.COUNTRYADJECTIVE <>  C.COUNTRYADJECTIVE OR (I.COUNTRYADJECTIVE is null and C.COUNTRYADJECTIVE is not null) 
OR (I.COUNTRYADJECTIVE is not null and C.COUNTRYADJECTIVE is null))
	OR 	( I.RECORDTYPE <>  C.RECORDTYPE OR (I.RECORDTYPE is null and C.RECORDTYPE is not null) 
OR (I.RECORDTYPE is not null and C.RECORDTYPE is null))
	OR 	( I.ISD <>  C.ISD OR (I.ISD is null and C.ISD is not null) 
OR (I.ISD is not null and C.ISD is null))
	OR 	( I.STATELITERAL <>  C.STATELITERAL OR (I.STATELITERAL is null and C.STATELITERAL is not null) 
OR (I.STATELITERAL is not null and C.STATELITERAL is null))
	OR 	( I.POSTCODELITERAL <>  C.POSTCODELITERAL OR (I.POSTCODELITERAL is null and C.POSTCODELITERAL is not null) 
OR (I.POSTCODELITERAL is not null and C.POSTCODELITERAL is null))
	OR 	( I.POSTCODEFIRST <>  C.POSTCODEFIRST OR (I.POSTCODEFIRST is null and C.POSTCODEFIRST is not null) 
OR (I.POSTCODEFIRST is not null and C.POSTCODEFIRST is null))
	OR 	( I.WORKDAYFLAG <>  C.WORKDAYFLAG OR (I.WORKDAYFLAG is null and C.WORKDAYFLAG is not null) 
OR (I.WORKDAYFLAG is not null and C.WORKDAYFLAG is null))
	OR 	( I.DATECOMMENCED <>  C.DATECOMMENCED OR (I.DATECOMMENCED is null and C.DATECOMMENCED is not null) 
OR (I.DATECOMMENCED is not null and C.DATECOMMENCED is null))
	OR 	( I.DATECEASED <>  C.DATECEASED OR (I.DATECEASED is null and C.DATECEASED is not null) 
OR (I.DATECEASED is not null and C.DATECEASED is null))
	OR 	(replace( I.NOTES,char(10),char(13)+char(10)) <>  C.NOTES OR (I.NOTES is null and C.NOTES is not null) 
OR (I.NOTES is not null and C.NOTES is null))
	OR 	( I.STATEABBREVIATED <>  C.STATEABBREVIATED OR (I.STATEABBREVIATED is null and C.STATEABBREVIATED is not null) 
OR (I.STATEABBREVIATED is not null and C.STATEABBREVIATED is null))
	OR 	( I.ALLMEMBERSFLAG <>  C.ALLMEMBERSFLAG)
	OR 	( I.NAMESTYLE <>  C.NAMESTYLE OR (I.NAMESTYLE is null and C.NAMESTYLE is not null) 
OR (I.NAMESTYLE is not null and C.NAMESTYLE is null))
	OR 	( I.ADDRESSSTYLE <>  C.ADDRESSSTYLE OR (I.ADDRESSSTYLE is null and C.ADDRESSSTYLE is not null) 
OR (I.ADDRESSSTYLE is not null and C.ADDRESSSTYLE is null))
	OR 	( I.DEFAULTTAXCODE <>  C.DEFAULTTAXCODE OR (I.DEFAULTTAXCODE is null and C.DEFAULTTAXCODE is not null) 
OR (I.DEFAULTTAXCODE is not null and C.DEFAULTTAXCODE is null))
	OR 	( I.REQUIREEXEMPTTAXNO <>  C.REQUIREEXEMPTTAXNO OR (I.REQUIREEXEMPTTAXNO is null and C.REQUIREEXEMPTTAXNO is not null) 
OR (I.REQUIREEXEMPTTAXNO is not null and C.REQUIREEXEMPTTAXNO is null))
	OR 	( I.DEFAULTCURRENCY <>  C.DEFAULTCURRENCY OR (I.DEFAULTCURRENCY is null and C.DEFAULTCURRENCY is not null) 
OR (I.DEFAULTCURRENCY is not null and C.DEFAULTCURRENCY is null))
	OR 	( I.POSTCODESEARCHCODE <>  C.POSTCODESEARCHCODE OR (I.POSTCODESEARCHCODE is null and C.POSTCODESEARCHCODE is not null) 
OR (I.POSTCODESEARCHCODE is not null and C.POSTCODESEARCHCODE is null))
	OR 	( I.POSTCODEAUTOFLAG <>  C.POSTCODEAUTOFLAG OR (I.POSTCODEAUTOFLAG is null and C.POSTCODEAUTOFLAG is not null) 
OR (I.POSTCODEAUTOFLAG is not null and C.POSTCODEAUTOFLAG is null))
	OR 	( I.POSTALNAME <>  C.POSTALNAME OR (I.POSTALNAME is null and C.POSTALNAME is not null) 
OR (I.POSTALNAME is not null and C.POSTALNAME is null))
	OR 	( I.PRIORARTFLAG <>  C.PRIORARTFLAG OR (I.PRIORARTFLAG is null and C.PRIORARTFLAG is not null) 
OR (I.PRIORARTFLAG is not null and C.PRIORARTFLAG is null))
UNION ALL 
 select	4, 'COUNTRY', 0, 0, 0, count(*)
from CCImport_COUNTRY I 
join COUNTRY C	on( C.COUNTRYCODE=I.COUNTRYCODE)
where ( I.ALTERNATECODE =  C.ALTERNATECODE OR (I.ALTERNATECODE is null and C.ALTERNATECODE is null))
and ( I.COUNTRY =  C.COUNTRY OR (I.COUNTRY is null and C.COUNTRY is null))
and ( I.INFORMALNAME =  C.INFORMALNAME OR (I.INFORMALNAME is null and C.INFORMALNAME is null))
and ( I.COUNTRYABBREV =  C.COUNTRYABBREV OR (I.COUNTRYABBREV is null and C.COUNTRYABBREV is null))
and ( I.COUNTRYADJECTIVE =  C.COUNTRYADJECTIVE OR (I.COUNTRYADJECTIVE is null and C.COUNTRYADJECTIVE is null))
and ( I.RECORDTYPE =  C.RECORDTYPE OR (I.RECORDTYPE is null and C.RECORDTYPE is null))
and ( I.ISD =  C.ISD OR (I.ISD is null and C.ISD is null))
and ( I.STATELITERAL =  C.STATELITERAL OR (I.STATELITERAL is null and C.STATELITERAL is null))
and ( I.POSTCODELITERAL =  C.POSTCODELITERAL OR (I.POSTCODELITERAL is null and C.POSTCODELITERAL is null))
and ( I.POSTCODEFIRST =  C.POSTCODEFIRST OR (I.POSTCODEFIRST is null and C.POSTCODEFIRST is null))
and ( I.WORKDAYFLAG =  C.WORKDAYFLAG OR (I.WORKDAYFLAG is null and C.WORKDAYFLAG is null))
and ( I.DATECOMMENCED =  C.DATECOMMENCED OR (I.DATECOMMENCED is null and C.DATECOMMENCED is null))
and ( I.DATECEASED =  C.DATECEASED OR (I.DATECEASED is null and C.DATECEASED is null))
and (replace( I.NOTES,char(10),char(13)+char(10)) =  C.NOTES OR (I.NOTES is null and C.NOTES is null))
and ( I.STATEABBREVIATED =  C.STATEABBREVIATED OR (I.STATEABBREVIATED is null and C.STATEABBREVIATED is null))
and ( I.ALLMEMBERSFLAG =  C.ALLMEMBERSFLAG)
and ( I.NAMESTYLE =  C.NAMESTYLE OR (I.NAMESTYLE is null and C.NAMESTYLE is null))
and ( I.ADDRESSSTYLE =  C.ADDRESSSTYLE OR (I.ADDRESSSTYLE is null and C.ADDRESSSTYLE is null))
and ( I.DEFAULTTAXCODE =  C.DEFAULTTAXCODE OR (I.DEFAULTTAXCODE is null and C.DEFAULTTAXCODE is null))
and ( I.REQUIREEXEMPTTAXNO =  C.REQUIREEXEMPTTAXNO OR (I.REQUIREEXEMPTTAXNO is null and C.REQUIREEXEMPTTAXNO is null))
and ( I.DEFAULTCURRENCY =  C.DEFAULTCURRENCY OR (I.DEFAULTCURRENCY is null and C.DEFAULTCURRENCY is null))
and ( I.POSTCODESEARCHCODE =  C.POSTCODESEARCHCODE OR (I.POSTCODESEARCHCODE is null and C.POSTCODESEARCHCODE is null))
and ( I.POSTCODEAUTOFLAG =  C.POSTCODEAUTOFLAG OR (I.POSTCODEAUTOFLAG is null and C.POSTCODEAUTOFLAG is null))
and ( I.POSTALNAME =  C.POSTALNAME OR (I.POSTALNAME is null and C.POSTALNAME is null))
and ( I.PRIORARTFLAG =  C.PRIORARTFLAG OR (I.PRIORARTFLAG is null and C.PRIORARTFLAG is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_COUNTRY]') and xtype='U')
begin
	drop table CCImport_COUNTRY 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnCOUNTRY  to public
go
