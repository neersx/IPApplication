-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnCHARGERATES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnCHARGERATES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnCHARGERATES.'
	drop function dbo.fn_ccnCHARGERATES
	print '**** Creating function dbo.fn_ccnCHARGERATES...'
	print ''
end
go

SET NOCOUNT ON
go


-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_CHARGERATES]') and xtype='U')
begin
	select * 
	into CCImport_CHARGERATES 
	from CHARGERATES
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnCHARGERATES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnCHARGERATES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CHARGERATES table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	8 as TRIPNO, 'CHARGERATES' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_CHARGERATES I 
	right join CHARGERATES C on( C.CHARGETYPENO=I.CHARGETYPENO
and  C.RATENO=I.RATENO
and  C.SEQUENCENO=I.SEQUENCENO)
where I.CHARGETYPENO is null
UNION ALL 
select	8, 'CHARGERATES', 0, count(*), 0, 0
from CCImport_CHARGERATES I 
	left join CHARGERATES C on( C.CHARGETYPENO=I.CHARGETYPENO
and  C.RATENO=I.RATENO
and  C.SEQUENCENO=I.SEQUENCENO)
where C.CHARGETYPENO is null
UNION ALL 
 select	8, 'CHARGERATES', 0, 0, count(*), 0
from CCImport_CHARGERATES I 
	join CHARGERATES C	on ( C.CHARGETYPENO=I.CHARGETYPENO
	and C.RATENO=I.RATENO
	and C.SEQUENCENO=I.SEQUENCENO)
where 	( I.CASETYPE <>  C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is not null) 
OR (I.CASETYPE is not null and C.CASETYPE is null))
	OR 	( I.CASECATEGORY <>  C.CASECATEGORY OR (I.CASECATEGORY is null and C.CASECATEGORY is not null) 
OR (I.CASECATEGORY is not null and C.CASECATEGORY is null))
	OR 	( I.PROPERTYTYPE <>  C.PROPERTYTYPE OR (I.PROPERTYTYPE is null and C.PROPERTYTYPE is not null) 
OR (I.PROPERTYTYPE is not null and C.PROPERTYTYPE is null))
	OR 	( I.COUNTRYCODE <>  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is not null) 
OR (I.COUNTRYCODE is not null and C.COUNTRYCODE is null))
	OR 	( I.SUBTYPE <>  C.SUBTYPE OR (I.SUBTYPE is null and C.SUBTYPE is not null) 
OR (I.SUBTYPE is not null and C.SUBTYPE is null))
	OR 	( I.INSTRUCTIONTYPE <>  C.INSTRUCTIONTYPE OR (I.INSTRUCTIONTYPE is null and C.INSTRUCTIONTYPE is not null) 
OR (I.INSTRUCTIONTYPE is not null and C.INSTRUCTIONTYPE is null))
	OR 	( I.FLAGNUMBER <>  C.FLAGNUMBER OR (I.FLAGNUMBER is null and C.FLAGNUMBER is not null) 
OR (I.FLAGNUMBER is not null and C.FLAGNUMBER is null))
UNION ALL 
 select	8, 'CHARGERATES', 0, 0, 0, count(*)
from CCImport_CHARGERATES I 
join CHARGERATES C	on( C.CHARGETYPENO=I.CHARGETYPENO
and C.RATENO=I.RATENO
and C.SEQUENCENO=I.SEQUENCENO)
where ( I.CASETYPE =  C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is null))
and ( I.CASECATEGORY =  C.CASECATEGORY OR (I.CASECATEGORY is null and C.CASECATEGORY is null))
and ( I.PROPERTYTYPE =  C.PROPERTYTYPE OR (I.PROPERTYTYPE is null and C.PROPERTYTYPE is null))
and ( I.COUNTRYCODE =  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is null))
and ( I.SUBTYPE =  C.SUBTYPE OR (I.SUBTYPE is null and C.SUBTYPE is null))
and ( I.INSTRUCTIONTYPE =  C.INSTRUCTIONTYPE OR (I.INSTRUCTIONTYPE is null and C.INSTRUCTIONTYPE is null))
and ( I.FLAGNUMBER =  C.FLAGNUMBER OR (I.FLAGNUMBER is null and C.FLAGNUMBER is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CHARGERATES]') and xtype='U')
begin
	drop table CCImport_CHARGERATES 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnCHARGERATES  to public
go

