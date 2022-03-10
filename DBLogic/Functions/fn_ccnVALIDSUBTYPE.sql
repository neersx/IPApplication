-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnVALIDSUBTYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnVALIDSUBTYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnVALIDSUBTYPE.'
	drop function dbo.fn_ccnVALIDSUBTYPE
	print '**** Creating function dbo.fn_ccnVALIDSUBTYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDSUBTYPE]') and xtype='U')
begin
	select * 
	into CCImport_VALIDSUBTYPE 
	from VALIDSUBTYPE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnVALIDSUBTYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnVALIDSUBTYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the VALIDSUBTYPE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	3 as TRIPNO, 'VALIDSUBTYPE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_VALIDSUBTYPE I 
	right join VALIDSUBTYPE C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.CASETYPE=I.CASETYPE
and  C.CASECATEGORY=I.CASECATEGORY
and  C.SUBTYPE=I.SUBTYPE)
where I.COUNTRYCODE is null
UNION ALL 
select	3, 'VALIDSUBTYPE', 0, count(*), 0, 0
from CCImport_VALIDSUBTYPE I 
	left join VALIDSUBTYPE C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.CASETYPE=I.CASETYPE
and  C.CASECATEGORY=I.CASECATEGORY
and  C.SUBTYPE=I.SUBTYPE)
where C.COUNTRYCODE is null
UNION ALL 
 select	3, 'VALIDSUBTYPE', 0, 0, count(*), 0
from CCImport_VALIDSUBTYPE I 
	join VALIDSUBTYPE C	on ( C.COUNTRYCODE=I.COUNTRYCODE
	and C.PROPERTYTYPE=I.PROPERTYTYPE
	and C.CASETYPE=I.CASETYPE
	and C.CASECATEGORY=I.CASECATEGORY
	and C.SUBTYPE=I.SUBTYPE)
where 	( I.SUBTYPEDESC <>  C.SUBTYPEDESC OR (I.SUBTYPEDESC is null and C.SUBTYPEDESC is not null) 
OR (I.SUBTYPEDESC is not null and C.SUBTYPEDESC is null))
UNION ALL 
 select	3, 'VALIDSUBTYPE', 0, 0, 0, count(*)
from CCImport_VALIDSUBTYPE I 
join VALIDSUBTYPE C	on( C.COUNTRYCODE=I.COUNTRYCODE
and C.PROPERTYTYPE=I.PROPERTYTYPE
and C.CASETYPE=I.CASETYPE
and C.CASECATEGORY=I.CASECATEGORY
and C.SUBTYPE=I.SUBTYPE)
where ( I.SUBTYPEDESC =  C.SUBTYPEDESC OR (I.SUBTYPEDESC is null and C.SUBTYPEDESC is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDSUBTYPE]') and xtype='U')
begin
	drop table CCImport_VALIDSUBTYPE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnVALIDSUBTYPE  to public
go
