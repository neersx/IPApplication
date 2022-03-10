-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnNARRATIVERULE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnNARRATIVERULE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnNARRATIVERULE.'
	drop function dbo.fn_ccnNARRATIVERULE
	print '**** Creating function dbo.fn_ccnNARRATIVERULE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_NARRATIVERULE]') and xtype='U')
begin
	select * 
	into CCImport_NARRATIVERULE 
	from NARRATIVERULE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnNARRATIVERULE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnNARRATIVERULE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the NARRATIVERULE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	8 as TRIPNO, 'NARRATIVERULE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_NARRATIVERULE I 
	right join NARRATIVERULE C on( C.NARRATIVERULENO=I.NARRATIVERULENO)
where I.NARRATIVERULENO is null
UNION ALL 
select	8, 'NARRATIVERULE', 0, count(*), 0, 0
from CCImport_NARRATIVERULE I 
	left join NARRATIVERULE C on( C.NARRATIVERULENO=I.NARRATIVERULENO)
where C.NARRATIVERULENO is null
UNION ALL 
 select	8, 'NARRATIVERULE', 0, 0, count(*), 0
from CCImport_NARRATIVERULE I 
	join NARRATIVERULE C	on ( C.NARRATIVERULENO=I.NARRATIVERULENO)
where 	( I.NARRATIVENO <>  C.NARRATIVENO)
	OR 	( I.WIPCODE <>  C.WIPCODE)
	OR 	( I.EMPLOYEENO <>  C.EMPLOYEENO OR (I.EMPLOYEENO is null and C.EMPLOYEENO is not null) 
OR (I.EMPLOYEENO is not null and C.EMPLOYEENO is null))
	OR 	( I.CASETYPE <>  C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is not null) 
OR (I.CASETYPE is not null and C.CASETYPE is null))
	OR 	( I.PROPERTYTYPE <>  C.PROPERTYTYPE OR (I.PROPERTYTYPE is null and C.PROPERTYTYPE is not null) 
OR (I.PROPERTYTYPE is not null and C.PROPERTYTYPE is null))
	OR 	( I.CASECATEGORY <>  C.CASECATEGORY OR (I.CASECATEGORY is null and C.CASECATEGORY is not null) 
OR (I.CASECATEGORY is not null and C.CASECATEGORY is null))
	OR 	( I.SUBTYPE <>  C.SUBTYPE OR (I.SUBTYPE is null and C.SUBTYPE is not null) 
OR (I.SUBTYPE is not null and C.SUBTYPE is null))
	OR 	( I.TYPEOFMARK <>  C.TYPEOFMARK OR (I.TYPEOFMARK is null and C.TYPEOFMARK is not null) 
OR (I.TYPEOFMARK is not null and C.TYPEOFMARK is null))
	OR 	( I.COUNTRYCODE <>  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is not null) 
OR (I.COUNTRYCODE is not null and C.COUNTRYCODE is null))
	OR 	( I.LOCALCOUNTRYFLAG <>  C.LOCALCOUNTRYFLAG OR (I.LOCALCOUNTRYFLAG is null and C.LOCALCOUNTRYFLAG is not null) 
OR (I.LOCALCOUNTRYFLAG is not null and C.LOCALCOUNTRYFLAG is null))
	OR 	( I.FOREIGNCOUNTRYFLAG <>  C.FOREIGNCOUNTRYFLAG OR (I.FOREIGNCOUNTRYFLAG is null and C.FOREIGNCOUNTRYFLAG is not null) 
OR (I.FOREIGNCOUNTRYFLAG is not null and C.FOREIGNCOUNTRYFLAG is null))
	OR 	( I.DEBTORNO <>  C.DEBTORNO OR (I.DEBTORNO is null and C.DEBTORNO is not null) 
OR (I.DEBTORNO is not null and C.DEBTORNO is null))
UNION ALL 
 select	8, 'NARRATIVERULE', 0, 0, 0, count(*)
from CCImport_NARRATIVERULE I 
join NARRATIVERULE C	on( C.NARRATIVERULENO=I.NARRATIVERULENO)
where ( I.NARRATIVENO =  C.NARRATIVENO)
and ( I.WIPCODE =  C.WIPCODE)
and ( I.EMPLOYEENO =  C.EMPLOYEENO OR (I.EMPLOYEENO is null and C.EMPLOYEENO is null))
and ( I.CASETYPE =  C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is null))
and ( I.PROPERTYTYPE =  C.PROPERTYTYPE OR (I.PROPERTYTYPE is null and C.PROPERTYTYPE is null))
and ( I.CASECATEGORY =  C.CASECATEGORY OR (I.CASECATEGORY is null and C.CASECATEGORY is null))
and ( I.SUBTYPE =  C.SUBTYPE OR (I.SUBTYPE is null and C.SUBTYPE is null))
and ( I.TYPEOFMARK =  C.TYPEOFMARK OR (I.TYPEOFMARK is null and C.TYPEOFMARK is null))
and ( I.COUNTRYCODE =  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is null))
and ( I.LOCALCOUNTRYFLAG =  C.LOCALCOUNTRYFLAG OR (I.LOCALCOUNTRYFLAG is null and C.LOCALCOUNTRYFLAG is null))
and ( I.FOREIGNCOUNTRYFLAG =  C.FOREIGNCOUNTRYFLAG OR (I.FOREIGNCOUNTRYFLAG is null and C.FOREIGNCOUNTRYFLAG is null))
and ( I.DEBTORNO =  C.DEBTORNO OR (I.DEBTORNO is null and C.DEBTORNO is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_NARRATIVERULE]') and xtype='U')
begin
	drop table CCImport_NARRATIVERULE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnNARRATIVERULE  to public
go
