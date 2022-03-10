-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_TAXRATESCOUNTRY
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_TAXRATESCOUNTRY]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_TAXRATESCOUNTRY.'
	drop function dbo.fn_cc_TAXRATESCOUNTRY
	print '**** Creating function dbo.fn_cc_TAXRATESCOUNTRY...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TAXRATESCOUNTRY]') and xtype='U')
begin
	select * 
	into CCImport_TAXRATESCOUNTRY 
	from TAXRATESCOUNTRY
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_TAXRATESCOUNTRY
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_TAXRATESCOUNTRY
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TAXRATESCOUNTRY table
-- CALLED BY :	ip_CopyConfigTAXRATESCOUNTRY
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
	 null as 'Imported Taxcode',
	 null as 'Imported Countrycode',
	 null as 'Imported Rate',
	 null as 'Imported State',
	 null as 'Imported Harmonised',
	 null as 'Imported Taxontax',
	 null as 'Imported Effectivedate',
'D' as '-',
	 C.TAXCODE as 'Taxcode',
	 C.COUNTRYCODE as 'Countrycode',
	 C.RATE as 'Rate',
	 C.STATE as 'State',
	 C.HARMONISED as 'Harmonised',
	 C.TAXONTAX as 'Taxontax',
	 C.EFFECTIVEDATE as 'Effectivedate'
from CCImport_TAXRATESCOUNTRY I 
	right join TAXRATESCOUNTRY C on( C.TAXRATESCOUNTRYID=I.TAXRATESCOUNTRYID)
where I.TAXRATESCOUNTRYID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.TAXCODE,
	 I.COUNTRYCODE,
	 I.RATE,
	 I.STATE,
	 I.HARMONISED,
	 I.TAXONTAX,
	 I.EFFECTIVEDATE,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_TAXRATESCOUNTRY I 
	left join TAXRATESCOUNTRY C on( C.TAXRATESCOUNTRYID=I.TAXRATESCOUNTRYID)
where C.TAXRATESCOUNTRYID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.TAXCODE,
	 I.COUNTRYCODE,
	 I.RATE,
	 I.STATE,
	 I.HARMONISED,
	 I.TAXONTAX,
	 I.EFFECTIVEDATE,
'U',
	 C.TAXCODE,
	 C.COUNTRYCODE,
	 C.RATE,
	 C.STATE,
	 C.HARMONISED,
	 C.TAXONTAX,
	 C.EFFECTIVEDATE
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

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TAXRATESCOUNTRY]') and xtype='U')
begin
	drop table CCImport_TAXRATESCOUNTRY 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_TAXRATESCOUNTRY  to public
go
