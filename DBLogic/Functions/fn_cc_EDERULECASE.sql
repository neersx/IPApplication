-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_EDERULECASE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_EDERULECASE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_EDERULECASE.'
	drop function dbo.fn_cc_EDERULECASE
	print '**** Creating function dbo.fn_cc_EDERULECASE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_EDERULECASE]') and xtype='U')
begin
	select * 
	into CCImport_EDERULECASE 
	from EDERULECASE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_EDERULECASE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_EDERULECASE
-- VERSION :	2
-- DESCRIPTION:	The SELECT to display of imported data for the EDERULECASE table
-- CALLED BY :	ip_CopyConfigEDERULECASE
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
-- 03 Apr 2017	MF	71020	2	New columns added.
--
As 
Return
select	1 as 'Switch',
	'X' as 'Match',
	'D' as 'Imported -',
	 null as 'Imported Criteriano',
	 null as 'Imported Wholecase',
	 null as 'Imported Casetype',
	 null as 'Imported Propertytype',
	 null as 'Imported Country',
	 null as 'Imported Category',
	 null as 'Imported Subtype',
	 null as 'Imported Basis',
	 null as 'Imported Entitysize',
	 null as 'Imported Numberofclaims',
	 null as 'Imported Numberofdesigns',
	 null as 'Imported Numberofyearsext',
	 null as 'Imported Stoppayreason',
	 null as 'Imported Shorttitle',
	 null as 'Imported Classes',
	 null as 'Imported Designatedcountries',
	 null as 'Imported Typeofmark',
	'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.WHOLECASE as 'Wholecase',
	 C.CASETYPE as 'Casetype',
	 C.PROPERTYTYPE as 'Propertytype',
	 C.COUNTRY as 'Country',
	 C.CATEGORY as 'Category',
	 C.SUBTYPE as 'Subtype',
	 C.BASIS as 'Basis',
	 C.ENTITYSIZE as 'Entitysize',
	 C.NUMBEROFCLAIMS as 'Numberofclaims',
	 C.NUMBEROFDESIGNS as 'Numberofdesigns',
	 C.NUMBEROFYEARSEXT as 'Numberofyearsext',
	 C.STOPPAYREASON as 'Stoppayreason',
	 C.SHORTTITLE as 'Shorttitle',
	 C.CLASSES as 'Classes',
	 C.DESIGNATEDCOUNTRIES as 'Designatedcountries',
	 C.TYPEOFMARK as 'Typeofmark'
from CCImport_EDERULECASE I 
	right join EDERULECASE C on( C.CRITERIANO=I.CRITERIANO)
where I.CRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.WHOLECASE,
	 I.CASETYPE,
	 I.PROPERTYTYPE,
	 I.COUNTRY,
	 I.CATEGORY,
	 I.SUBTYPE,
	 I.BASIS,
	 I.ENTITYSIZE,
	 I.NUMBEROFCLAIMS,
	 I.NUMBEROFDESIGNS,
	 I.NUMBEROFYEARSEXT,
	 I.STOPPAYREASON,
	 I.SHORTTITLE,
	 I.CLASSES,
	 I.DESIGNATEDCOUNTRIES,
	 I.TYPEOFMARK,
	'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_EDERULECASE I 
	left join EDERULECASE C on( C.CRITERIANO=I.CRITERIANO)
where C.CRITERIANO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIANO,
	 I.WHOLECASE,
	 I.CASETYPE,
	 I.PROPERTYTYPE,
	 I.COUNTRY,
	 I.CATEGORY,
	 I.SUBTYPE,
	 I.BASIS,
	 I.ENTITYSIZE,
	 I.NUMBEROFCLAIMS,
	 I.NUMBEROFDESIGNS,
	 I.NUMBEROFYEARSEXT,
	 I.STOPPAYREASON,
	 I.SHORTTITLE,
	 I.CLASSES,
	 I.DESIGNATEDCOUNTRIES,
	 I.TYPEOFMARK,
	'U',
	 C.CRITERIANO,
	 C.WHOLECASE,
	 C.CASETYPE,
	 C.PROPERTYTYPE,
	 C.COUNTRY,
	 C.CATEGORY,
	 C.SUBTYPE,
	 C.BASIS,
	 C.ENTITYSIZE,
	 C.NUMBEROFCLAIMS,
	 C.NUMBEROFDESIGNS,
	 C.NUMBEROFYEARSEXT,
	 C.STOPPAYREASON,
	 C.SHORTTITLE,
	 C.CLASSES,
	 C.DESIGNATEDCOUNTRIES,
	 C.TYPEOFMARK
from CCImport_EDERULECASE I 
	join EDERULECASE C	on ( C.CRITERIANO=I.CRITERIANO)
where 	( I.WHOLECASE <>  C.WHOLECASE OR (I.WHOLECASE is null and C.WHOLECASE is not null) 
OR (I.WHOLECASE is not null and C.WHOLECASE is null))
	OR 	( I.CASETYPE <>  C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is not null) 
OR (I.CASETYPE is not null and C.CASETYPE is null))
	OR 	( I.PROPERTYTYPE <>  C.PROPERTYTYPE OR (I.PROPERTYTYPE is null and C.PROPERTYTYPE is not null) 
OR (I.PROPERTYTYPE is not null and C.PROPERTYTYPE is null))
	OR 	( I.COUNTRY <>  C.COUNTRY OR (I.COUNTRY is null and C.COUNTRY is not null) 
OR (I.COUNTRY is not null and C.COUNTRY is null))
	OR 	( I.CATEGORY <>  C.CATEGORY OR (I.CATEGORY is null and C.CATEGORY is not null) 
OR (I.CATEGORY is not null and C.CATEGORY is null))
	OR 	( I.SUBTYPE <>  C.SUBTYPE OR (I.SUBTYPE is null and C.SUBTYPE is not null) 
OR (I.SUBTYPE is not null and C.SUBTYPE is null))
	OR 	( I.BASIS <>  C.BASIS OR (I.BASIS is null and C.BASIS is not null) 
OR (I.BASIS is not null and C.BASIS is null))
	OR 	( I.ENTITYSIZE <>  C.ENTITYSIZE OR (I.ENTITYSIZE is null and C.ENTITYSIZE is not null) 
OR (I.ENTITYSIZE is not null and C.ENTITYSIZE is null))
	OR 	( I.NUMBEROFCLAIMS <>  C.NUMBEROFCLAIMS OR (I.NUMBEROFCLAIMS is null and C.NUMBEROFCLAIMS is not null) 
OR (I.NUMBEROFCLAIMS is not null and C.NUMBEROFCLAIMS is null))
	OR 	( I.NUMBEROFDESIGNS <>  C.NUMBEROFDESIGNS OR (I.NUMBEROFDESIGNS is null and C.NUMBEROFDESIGNS is not null) 
OR (I.NUMBEROFDESIGNS is not null and C.NUMBEROFDESIGNS is null))
	OR 	( I.NUMBEROFYEARSEXT <>  C.NUMBEROFYEARSEXT OR (I.NUMBEROFYEARSEXT is null and C.NUMBEROFYEARSEXT is not null) 
OR (I.NUMBEROFYEARSEXT is not null and C.NUMBEROFYEARSEXT is null))
	OR 	( I.STOPPAYREASON <>  C.STOPPAYREASON OR (I.STOPPAYREASON is null and C.STOPPAYREASON is not null) 
OR (I.STOPPAYREASON is not null and C.STOPPAYREASON is null))
	OR 	( I.SHORTTITLE <>  C.SHORTTITLE OR (I.SHORTTITLE is null and C.SHORTTITLE is not null) 
OR (I.SHORTTITLE is not null and C.SHORTTITLE is null))
	OR 	( I.CLASSES <>  C.CLASSES OR (I.CLASSES is null and C.CLASSES is not null) 
OR (I.CLASSES is not null and C.CLASSES is null))
	OR 	( I.DESIGNATEDCOUNTRIES <>  C.DESIGNATEDCOUNTRIES OR (I.DESIGNATEDCOUNTRIES is null and C.DESIGNATEDCOUNTRIES is not null) 
OR (I.DESIGNATEDCOUNTRIES is not null and C.DESIGNATEDCOUNTRIES is null))
	OR 	( I.TYPEOFMARK <>  C.TYPEOFMARK OR (I.TYPEOFMARK is null and C.TYPEOFMARK is not null) 
OR (I.TYPEOFMARK is not null and C.TYPEOFMARK is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EDERULECASE]') and xtype='U')
begin
	drop table CCImport_EDERULECASE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_EDERULECASE  to public
go

