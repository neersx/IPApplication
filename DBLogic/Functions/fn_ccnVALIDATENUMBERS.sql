-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnVALIDATENUMBERS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnVALIDATENUMBERS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnVALIDATENUMBERS.'
	drop function dbo.fn_ccnVALIDATENUMBERS
	print '**** Creating function dbo.fn_ccnVALIDATENUMBERS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDATENUMBERS]') and xtype='U')
begin
	select * 
	into CCImport_VALIDATENUMBERS 
	from VALIDATENUMBERS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnVALIDATENUMBERS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnVALIDATENUMBERS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the VALIDATENUMBERS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	4 as TRIPNO, 'VALIDATENUMBERS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_VALIDATENUMBERS I 
	right join VALIDATENUMBERS C on( C.VALIDATIONID=I.VALIDATIONID)
where I.VALIDATIONID is null
UNION ALL 
select	4, 'VALIDATENUMBERS', 0, count(*), 0, 0
from CCImport_VALIDATENUMBERS I 
	left join VALIDATENUMBERS C on( C.VALIDATIONID=I.VALIDATIONID)
where C.VALIDATIONID is null
UNION ALL 
 select	4, 'VALIDATENUMBERS', 0, 0, count(*), 0
from CCImport_VALIDATENUMBERS I 
	join VALIDATENUMBERS C	on ( C.VALIDATIONID=I.VALIDATIONID)
where 	( I.COUNTRYCODE <>  C.COUNTRYCODE)
	OR 	( I.PROPERTYTYPE <>  C.PROPERTYTYPE)
	OR 	( I.NUMBERTYPE <>  C.NUMBERTYPE)
	OR 	( I.VALIDFROM <>  C.VALIDFROM OR (I.VALIDFROM is null and C.VALIDFROM is not null) 
OR (I.VALIDFROM is not null and C.VALIDFROM is null))
	OR 	(replace( I.PATTERN,char(10),char(13)+char(10)) <>  C.PATTERN)
	OR 	( I.WARNINGFLAG <>  C.WARNINGFLAG)
	OR 	(replace( I.ERRORMESSAGE,char(10),char(13)+char(10)) <>  C.ERRORMESSAGE)
	OR 	( I.VALIDATINGSPID <>  C.VALIDATINGSPID OR (I.VALIDATINGSPID is null and C.VALIDATINGSPID is not null) 
OR (I.VALIDATINGSPID is not null and C.VALIDATINGSPID is null))
	OR 	( I.CASETYPE <>  C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is not null) 
OR (I.CASETYPE is not null and C.CASETYPE is null))
	OR 	( I.CASECATEGORY <>  C.CASECATEGORY OR (I.CASECATEGORY is null and C.CASECATEGORY is not null) 
OR (I.CASECATEGORY is not null and C.CASECATEGORY is null))
	OR 	( I.SUBTYPE <>  C.SUBTYPE OR (I.SUBTYPE is null and C.SUBTYPE is not null) 
OR (I.SUBTYPE is not null and C.SUBTYPE is null))
UNION ALL 
 select	4, 'VALIDATENUMBERS', 0, 0, 0, count(*)
from CCImport_VALIDATENUMBERS I 
join VALIDATENUMBERS C	on( C.VALIDATIONID=I.VALIDATIONID)
where ( I.COUNTRYCODE =  C.COUNTRYCODE)
and ( I.PROPERTYTYPE =  C.PROPERTYTYPE)
and ( I.NUMBERTYPE =  C.NUMBERTYPE)
and ( I.VALIDFROM =  C.VALIDFROM OR (I.VALIDFROM is null and C.VALIDFROM is null))
and (replace( I.PATTERN,char(10),char(13)+char(10)) =  C.PATTERN)
and ( I.WARNINGFLAG =  C.WARNINGFLAG)
and (replace( I.ERRORMESSAGE,char(10),char(13)+char(10)) =  C.ERRORMESSAGE)
and ( I.VALIDATINGSPID =  C.VALIDATINGSPID OR (I.VALIDATINGSPID is null and C.VALIDATINGSPID is null))
and ( I.CASETYPE =  C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is null))
and ( I.CASECATEGORY =  C.CASECATEGORY OR (I.CASECATEGORY is null and C.CASECATEGORY is null))
and ( I.SUBTYPE =  C.SUBTYPE OR (I.SUBTYPE is null and C.SUBTYPE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDATENUMBERS]') and xtype='U')
begin
	drop table CCImport_VALIDATENUMBERS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnVALIDATENUMBERS  to public
go
