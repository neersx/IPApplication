-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnTAXRATESCOUNTRY
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnTAXRATESCOUNTRY]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnTAXRATESCOUNTRY.'
	drop function dbo.fn_ccnTAXRATESCOUNTRY
	print '**** Creating function dbo.fn_ccnTAXRATESCOUNTRY...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TAXRATESCOUNTRY]') and xtype='U')
begin
	select * 
	into CCImport_TAXRATESCOUNTRY 
	from TAXRATESCOUNTRY
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnTAXRATESCOUNTRY
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnTAXRATESCOUNTRY
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TAXRATESCOUNTRY table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	8 as TRIPNO, 'TAXRATESCOUNTRY' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_TAXRATESCOUNTRY I 
	right join TAXRATESCOUNTRY C on( C.TAXRATESCOUNTRYID=I.TAXRATESCOUNTRYID)
where I.TAXRATESCOUNTRYID is null
UNION ALL 
select	8, 'TAXRATESCOUNTRY', 0, count(*), 0, 0
from CCImport_TAXRATESCOUNTRY I 
	left join TAXRATESCOUNTRY C on( C.TAXRATESCOUNTRYID=I.TAXRATESCOUNTRYID)
where C.TAXRATESCOUNTRYID is null
UNION ALL 
 select	8, 'TAXRATESCOUNTRY', 0, 0, count(*), 0
from CCImport_TAXRATESCOUNTRY I 
	join TAXRATESCOUNTRY C	on ( C.TAXRATESCOUNTRYID=I.TAXRATESCOUNTRYID)
where 	( I.TAXCODE <>  C.TAXCODE)
	OR 	( I.COUNTRYCODE <>  C.COUNTRYCODE)
	OR 	( I.RATE <>  C.RATE OR (I.RATE is null and C.RATE is not null) 
OR (I.RATE is not null and C.RATE is null))
	OR 	( I.STATE <>  C.STATE OR (I.STATE is null and C.STATE is not null) 
OR (I.STATE is not null and C.STATE is null))
	OR 	( I.HARMONISED <>  C.HARMONISED OR (I.HARMONISED is null and C.HARMONISED is not null) 
OR (I.HARMONISED is not null and C.HARMONISED is null))
	OR 	( I.TAXONTAX <>  C.TAXONTAX OR (I.TAXONTAX is null and C.TAXONTAX is not null) 
OR (I.TAXONTAX is not null and C.TAXONTAX is null))
	OR 	( I.EFFECTIVEDATE <>  C.EFFECTIVEDATE OR (I.EFFECTIVEDATE is null and C.EFFECTIVEDATE is not null) 
OR (I.EFFECTIVEDATE is not null and C.EFFECTIVEDATE is null))
UNION ALL 
 select	8, 'TAXRATESCOUNTRY', 0, 0, 0, count(*)
from CCImport_TAXRATESCOUNTRY I 
join TAXRATESCOUNTRY C	on( C.TAXRATESCOUNTRYID=I.TAXRATESCOUNTRYID)
where ( I.TAXCODE =  C.TAXCODE)
and ( I.COUNTRYCODE =  C.COUNTRYCODE)
and ( I.RATE =  C.RATE OR (I.RATE is null and C.RATE is null))
and ( I.STATE =  C.STATE OR (I.STATE is null and C.STATE is null))
and ( I.HARMONISED =  C.HARMONISED OR (I.HARMONISED is null and C.HARMONISED is null))
and ( I.TAXONTAX =  C.TAXONTAX OR (I.TAXONTAX is null and C.TAXONTAX is null))
and ( I.EFFECTIVEDATE =  C.EFFECTIVEDATE OR (I.EFFECTIVEDATE is null and C.EFFECTIVEDATE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TAXRATESCOUNTRY]') and xtype='U')
begin
	drop table CCImport_TAXRATESCOUNTRY 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnTAXRATESCOUNTRY  to public
go
