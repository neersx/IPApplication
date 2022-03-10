-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_VALIDCATEGORY
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_VALIDCATEGORY]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_VALIDCATEGORY.'
	drop function dbo.fn_cc_VALIDCATEGORY
	print '**** Creating function dbo.fn_cc_VALIDCATEGORY...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDCATEGORY]') and xtype='U')
begin
	select * 
	into CCImport_VALIDCATEGORY 
	from VALIDCATEGORY
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_VALIDCATEGORY
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_VALIDCATEGORY
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the VALIDCATEGORY table
-- CALLED BY :	ip_CopyConfigVALIDCATEGORY
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
	 null as 'Imported Countrycode',
	 null as 'Imported Propertytype',
	 null as 'Imported Casetype',
	 null as 'Imported Casecategory',
	 null as 'Imported Casecategorydesc',
	 null as 'Imported Propertyeventno',
	 null as 'Imported Multiclasspropertyapp',
'D' as '-',
	 C.COUNTRYCODE as 'Countrycode',
	 C.PROPERTYTYPE as 'Propertytype',
	 C.CASETYPE as 'Casetype',
	 C.CASECATEGORY as 'Casecategory',
	 C.CASECATEGORYDESC as 'Casecategorydesc',
	 C.PROPERTYEVENTNO as 'Propertyeventno',
	 C.MULTICLASSPROPERTYAPP as 'Multiclasspropertyapp'
from CCImport_VALIDCATEGORY I 
	right join VALIDCATEGORY C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.CASETYPE=I.CASETYPE
and  C.CASECATEGORY=I.CASECATEGORY)
where I.COUNTRYCODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.COUNTRYCODE,
	 I.PROPERTYTYPE,
	 I.CASETYPE,
	 I.CASECATEGORY,
	 I.CASECATEGORYDESC,
	 I.PROPERTYEVENTNO,
	 I.MULTICLASSPROPERTYAPP,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_VALIDCATEGORY I 
	left join VALIDCATEGORY C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.CASETYPE=I.CASETYPE
and  C.CASECATEGORY=I.CASECATEGORY)
where C.COUNTRYCODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.COUNTRYCODE,
	 I.PROPERTYTYPE,
	 I.CASETYPE,
	 I.CASECATEGORY,
	 I.CASECATEGORYDESC,
	 I.PROPERTYEVENTNO,
	 I.MULTICLASSPROPERTYAPP,
'U',
	 C.COUNTRYCODE,
	 C.PROPERTYTYPE,
	 C.CASETYPE,
	 C.CASECATEGORY,
	 C.CASECATEGORYDESC,
	 C.PROPERTYEVENTNO,
	 C.MULTICLASSPROPERTYAPP
from CCImport_VALIDCATEGORY I 
	join VALIDCATEGORY C	on ( C.COUNTRYCODE=I.COUNTRYCODE
	and C.PROPERTYTYPE=I.PROPERTYTYPE
	and C.CASETYPE=I.CASETYPE
	and C.CASECATEGORY=I.CASECATEGORY)
where 	( I.CASECATEGORYDESC <>  C.CASECATEGORYDESC OR (I.CASECATEGORYDESC is null and C.CASECATEGORYDESC is not null) 
OR (I.CASECATEGORYDESC is not null and C.CASECATEGORYDESC is null))
	OR 	( I.PROPERTYEVENTNO <>  C.PROPERTYEVENTNO OR (I.PROPERTYEVENTNO is null and C.PROPERTYEVENTNO is not null) 
OR (I.PROPERTYEVENTNO is not null and C.PROPERTYEVENTNO is null))
	OR 	( I.MULTICLASSPROPERTYAPP <>  C.MULTICLASSPROPERTYAPP OR (I.MULTICLASSPROPERTYAPP is null and C.MULTICLASSPROPERTYAPP is not null) 
OR (I.MULTICLASSPROPERTYAPP is not null and C.MULTICLASSPROPERTYAPP is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDCATEGORY]') and xtype='U')
begin
	drop table CCImport_VALIDCATEGORY 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_VALIDCATEGORY  to public
go
