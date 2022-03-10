-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnVALIDCATEGORY
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnVALIDCATEGORY]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnVALIDCATEGORY.'
	drop function dbo.fn_ccnVALIDCATEGORY
	print '**** Creating function dbo.fn_ccnVALIDCATEGORY...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDCATEGORY]') and xtype='U')
begin
	select * 
	into CCImport_VALIDCATEGORY 
	from VALIDCATEGORY
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnVALIDCATEGORY
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnVALIDCATEGORY
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the VALIDCATEGORY table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	3 as TRIPNO, 'VALIDCATEGORY' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_VALIDCATEGORY I 
	right join VALIDCATEGORY C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.CASETYPE=I.CASETYPE
and  C.CASECATEGORY=I.CASECATEGORY)
where I.COUNTRYCODE is null
UNION ALL 
select	3, 'VALIDCATEGORY', 0, count(*), 0, 0
from CCImport_VALIDCATEGORY I 
	left join VALIDCATEGORY C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.CASETYPE=I.CASETYPE
and  C.CASECATEGORY=I.CASECATEGORY)
where C.COUNTRYCODE is null
UNION ALL 
 select	3, 'VALIDCATEGORY', 0, 0, count(*), 0
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
UNION ALL 
 select	3, 'VALIDCATEGORY', 0, 0, 0, count(*)
from CCImport_VALIDCATEGORY I 
join VALIDCATEGORY C	on( C.COUNTRYCODE=I.COUNTRYCODE
and C.PROPERTYTYPE=I.PROPERTYTYPE
and C.CASETYPE=I.CASETYPE
and C.CASECATEGORY=I.CASECATEGORY)
where ( I.CASECATEGORYDESC =  C.CASECATEGORYDESC OR (I.CASECATEGORYDESC is null and C.CASECATEGORYDESC is null))
and ( I.PROPERTYEVENTNO =  C.PROPERTYEVENTNO OR (I.PROPERTYEVENTNO is null and C.PROPERTYEVENTNO is null))
and ( I.MULTICLASSPROPERTYAPP =  C.MULTICLASSPROPERTYAPP OR (I.MULTICLASSPROPERTYAPP is null and C.MULTICLASSPROPERTYAPP is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDCATEGORY]') and xtype='U')
begin
	drop table CCImport_VALIDCATEGORY 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnVALIDCATEGORY  to public
go
