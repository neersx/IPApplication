-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnDATAVALIDATION
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnDATAVALIDATION]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnDATAVALIDATION.'
	drop function dbo.fn_ccnDATAVALIDATION
	print '**** Creating function dbo.fn_ccnDATAVALIDATION...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_DATAVALIDATION]') and xtype='U')
begin
	select * 
	into CCImport_DATAVALIDATION 
	from DATAVALIDATION
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnDATAVALIDATION
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnDATAVALIDATION
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the DATAVALIDATION table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'DATAVALIDATION' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_DATAVALIDATION I 
	right join DATAVALIDATION C on( C.VALIDATIONID=I.VALIDATIONID)
where I.VALIDATIONID is null
UNION ALL 
select	5, 'DATAVALIDATION', 0, count(*), 0, 0
from CCImport_DATAVALIDATION I 
	left join DATAVALIDATION C on( C.VALIDATIONID=I.VALIDATIONID)
where C.VALIDATIONID is null
UNION ALL 
 select	5, 'DATAVALIDATION', 0, 0, count(*), 0
from CCImport_DATAVALIDATION I 
	join DATAVALIDATION C	on ( C.VALIDATIONID=I.VALIDATIONID)
where 	( I.INUSEFLAG <>  C.INUSEFLAG)
	OR 	( I.DEFERREDFLAG <>  C.DEFERREDFLAG)
	OR 	( I.OFFICEID <>  C.OFFICEID OR (I.OFFICEID is null and C.OFFICEID is not null) 
OR (I.OFFICEID is not null and C.OFFICEID is null))
	OR 	( I.FUNCTIONALAREA <>  C.FUNCTIONALAREA OR (I.FUNCTIONALAREA is null and C.FUNCTIONALAREA is not null) 
OR (I.FUNCTIONALAREA is not null and C.FUNCTIONALAREA is null))
	OR 	( I.CASETYPE <>  C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is not null) 
OR (I.CASETYPE is not null and C.CASETYPE is null))
	OR 	( I.COUNTRYCODE <>  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is not null) 
OR (I.COUNTRYCODE is not null and C.COUNTRYCODE is null))
	OR 	( I.PROPERTYTYPE <>  C.PROPERTYTYPE OR (I.PROPERTYTYPE is null and C.PROPERTYTYPE is not null) 
OR (I.PROPERTYTYPE is not null and C.PROPERTYTYPE is null))
	OR 	( I.CASECATEGORY <>  C.CASECATEGORY OR (I.CASECATEGORY is null and C.CASECATEGORY is not null) 
OR (I.CASECATEGORY is not null and C.CASECATEGORY is null))
	OR 	( I.SUBTYPE <>  C.SUBTYPE OR (I.SUBTYPE is null and C.SUBTYPE is not null) 
OR (I.SUBTYPE is not null and C.SUBTYPE is null))
	OR 	( I.BASIS <>  C.BASIS OR (I.BASIS is null and C.BASIS is not null) 
OR (I.BASIS is not null and C.BASIS is null))
	OR 	( I.EVENTNO <>  C.EVENTNO OR (I.EVENTNO is null and C.EVENTNO is not null) 
OR (I.EVENTNO is not null and C.EVENTNO is null))
	OR 	( I.EVENTDATEFLAG <>  C.EVENTDATEFLAG OR (I.EVENTDATEFLAG is null and C.EVENTDATEFLAG is not null) 
OR (I.EVENTDATEFLAG is not null and C.EVENTDATEFLAG is null))
	OR 	( I.STATUSFLAG <>  C.STATUSFLAG OR (I.STATUSFLAG is null and C.STATUSFLAG is not null) 
OR (I.STATUSFLAG is not null and C.STATUSFLAG is null))
	OR 	( I.FAMILYNO <>  C.FAMILYNO OR (I.FAMILYNO is null and C.FAMILYNO is not null) 
OR (I.FAMILYNO is not null and C.FAMILYNO is null))
	OR 	( I.LOCALCLIENTFLAG <>  C.LOCALCLIENTFLAG OR (I.LOCALCLIENTFLAG is null and C.LOCALCLIENTFLAG is not null) 
OR (I.LOCALCLIENTFLAG is not null and C.LOCALCLIENTFLAG is null))
	OR 	( I.USEDASFLAG <>  C.USEDASFLAG OR (I.USEDASFLAG is null and C.USEDASFLAG is not null) 
OR (I.USEDASFLAG is not null and C.USEDASFLAG is null))
	OR 	( I.SUPPLIERFLAG <>  C.SUPPLIERFLAG OR (I.SUPPLIERFLAG is null and C.SUPPLIERFLAG is not null) 
OR (I.SUPPLIERFLAG is not null and C.SUPPLIERFLAG is null))
	OR 	( I.CATEGORY <>  C.CATEGORY OR (I.CATEGORY is null and C.CATEGORY is not null) 
OR (I.CATEGORY is not null and C.CATEGORY is null))
	OR 	( I.NAMENO <>  C.NAMENO OR (I.NAMENO is null and C.NAMENO is not null) 
OR (I.NAMENO is not null and C.NAMENO is null))
	OR 	( I.NAMETYPE <>  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is not null) 
OR (I.NAMETYPE is not null and C.NAMETYPE is null))
	OR 	( I.INSTRUCTIONTYPE <>  C.INSTRUCTIONTYPE OR (I.INSTRUCTIONTYPE is null and C.INSTRUCTIONTYPE is not null) 
OR (I.INSTRUCTIONTYPE is not null and C.INSTRUCTIONTYPE is null))
	OR 	( I.FLAGNUMBER <>  C.FLAGNUMBER OR (I.FLAGNUMBER is null and C.FLAGNUMBER is not null) 
OR (I.FLAGNUMBER is not null and C.FLAGNUMBER is null))
	OR 	( I.COLUMNNAME <>  C.COLUMNNAME OR (I.COLUMNNAME is null and C.COLUMNNAME is not null) 
OR (I.COLUMNNAME is not null and C.COLUMNNAME is null))
	OR 	(replace( I.RULEDESCRIPTION,char(10),char(13)+char(10)) <>  C.RULEDESCRIPTION OR (I.RULEDESCRIPTION is null and C.RULEDESCRIPTION is not null) 
OR (I.RULEDESCRIPTION is not null and C.RULEDESCRIPTION is null))
	OR 	( I.ITEM_ID <>  C.ITEM_ID OR (I.ITEM_ID is null and C.ITEM_ID is not null) 
OR (I.ITEM_ID is not null and C.ITEM_ID is null))
	OR 	( I.ROLEID <>  C.ROLEID OR (I.ROLEID is null and C.ROLEID is not null) 
OR (I.ROLEID is not null and C.ROLEID is null))
	OR 	( I.PROGRAMCONTEXT <>  C.PROGRAMCONTEXT OR (I.PROGRAMCONTEXT is null and C.PROGRAMCONTEXT is not null) 
OR (I.PROGRAMCONTEXT is not null and C.PROGRAMCONTEXT is null))
	OR 	( I.WARNINGFLAG <>  C.WARNINGFLAG OR (I.WARNINGFLAG is null and C.WARNINGFLAG is not null) 
OR (I.WARNINGFLAG is not null and C.WARNINGFLAG is null))
	OR 	( I.DISPLAYMESSAGE <>  C.DISPLAYMESSAGE OR (I.DISPLAYMESSAGE is null and C.DISPLAYMESSAGE is not null) 
OR (I.DISPLAYMESSAGE is not null and C.DISPLAYMESSAGE is null))
	OR 	( I.NOTES <>  C.NOTES OR (I.NOTES is null and C.NOTES is not null) 
OR (I.NOTES is not null and C.NOTES is null))
	OR 	( I.NOTCASETYPE <>  C.NOTCASETYPE OR (I.NOTCASETYPE is null and C.NOTCASETYPE is not null) 
OR (I.NOTCASETYPE is not null and C.NOTCASETYPE is null))
	OR 	( I.NOTCOUNTRYCODE <>  C.NOTCOUNTRYCODE OR (I.NOTCOUNTRYCODE is null and C.NOTCOUNTRYCODE is not null) 
OR (I.NOTCOUNTRYCODE is not null and C.NOTCOUNTRYCODE is null))
	OR 	( I.NOTPROPERTYTYPE <>  C.NOTPROPERTYTYPE OR (I.NOTPROPERTYTYPE is null and C.NOTPROPERTYTYPE is not null) 
OR (I.NOTPROPERTYTYPE is not null and C.NOTPROPERTYTYPE is null))
	OR 	( I.NOTCASECATEGORY <>  C.NOTCASECATEGORY OR (I.NOTCASECATEGORY is null and C.NOTCASECATEGORY is not null) 
OR (I.NOTCASECATEGORY is not null and C.NOTCASECATEGORY is null))
	OR 	( I.NOTSUBTYPE <>  C.NOTSUBTYPE OR (I.NOTSUBTYPE is null and C.NOTSUBTYPE is not null) 
OR (I.NOTSUBTYPE is not null and C.NOTSUBTYPE is null))
	OR 	( I.NOTBASIS <>  C.NOTBASIS OR (I.NOTBASIS is null and C.NOTBASIS is not null) 
OR (I.NOTBASIS is not null and C.NOTBASIS is null))
UNION ALL 
 select	5, 'DATAVALIDATION', 0, 0, 0, count(*)
from CCImport_DATAVALIDATION I 
join DATAVALIDATION C	on( C.VALIDATIONID=I.VALIDATIONID)
where ( I.INUSEFLAG =  C.INUSEFLAG)
and ( I.DEFERREDFLAG =  C.DEFERREDFLAG)
and ( I.OFFICEID =  C.OFFICEID OR (I.OFFICEID is null and C.OFFICEID is null))
and ( I.FUNCTIONALAREA =  C.FUNCTIONALAREA OR (I.FUNCTIONALAREA is null and C.FUNCTIONALAREA is null))
and ( I.CASETYPE =  C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is null))
and ( I.COUNTRYCODE =  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is null))
and ( I.PROPERTYTYPE =  C.PROPERTYTYPE OR (I.PROPERTYTYPE is null and C.PROPERTYTYPE is null))
and ( I.CASECATEGORY =  C.CASECATEGORY OR (I.CASECATEGORY is null and C.CASECATEGORY is null))
and ( I.SUBTYPE =  C.SUBTYPE OR (I.SUBTYPE is null and C.SUBTYPE is null))
and ( I.BASIS =  C.BASIS OR (I.BASIS is null and C.BASIS is null))
and ( I.EVENTNO =  C.EVENTNO OR (I.EVENTNO is null and C.EVENTNO is null))
and ( I.EVENTDATEFLAG =  C.EVENTDATEFLAG OR (I.EVENTDATEFLAG is null and C.EVENTDATEFLAG is null))
and ( I.STATUSFLAG =  C.STATUSFLAG OR (I.STATUSFLAG is null and C.STATUSFLAG is null))
and ( I.FAMILYNO =  C.FAMILYNO OR (I.FAMILYNO is null and C.FAMILYNO is null))
and ( I.LOCALCLIENTFLAG =  C.LOCALCLIENTFLAG OR (I.LOCALCLIENTFLAG is null and C.LOCALCLIENTFLAG is null))
and ( I.USEDASFLAG =  C.USEDASFLAG OR (I.USEDASFLAG is null and C.USEDASFLAG is null))
and ( I.SUPPLIERFLAG =  C.SUPPLIERFLAG OR (I.SUPPLIERFLAG is null and C.SUPPLIERFLAG is null))
and ( I.CATEGORY =  C.CATEGORY OR (I.CATEGORY is null and C.CATEGORY is null))
and ( I.NAMENO =  C.NAMENO OR (I.NAMENO is null and C.NAMENO is null))
and ( I.NAMETYPE =  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is null))
and ( I.INSTRUCTIONTYPE =  C.INSTRUCTIONTYPE OR (I.INSTRUCTIONTYPE is null and C.INSTRUCTIONTYPE is null))
and ( I.FLAGNUMBER =  C.FLAGNUMBER OR (I.FLAGNUMBER is null and C.FLAGNUMBER is null))
and ( I.COLUMNNAME =  C.COLUMNNAME OR (I.COLUMNNAME is null and C.COLUMNNAME is null))
and (replace( I.RULEDESCRIPTION,char(10),char(13)+char(10)) =  C.RULEDESCRIPTION OR (I.RULEDESCRIPTION is null and C.RULEDESCRIPTION is null))
and ( I.ITEM_ID =  C.ITEM_ID OR (I.ITEM_ID is null and C.ITEM_ID is null))
and ( I.ROLEID =  C.ROLEID OR (I.ROLEID is null and C.ROLEID is null))
and ( I.PROGRAMCONTEXT =  C.PROGRAMCONTEXT OR (I.PROGRAMCONTEXT is null and C.PROGRAMCONTEXT is null))
and ( I.WARNINGFLAG =  C.WARNINGFLAG OR (I.WARNINGFLAG is null and C.WARNINGFLAG is null))
and ( I.DISPLAYMESSAGE =  C.DISPLAYMESSAGE OR (I.DISPLAYMESSAGE is null and C.DISPLAYMESSAGE is null))
and ( I.NOTES =  C.NOTES OR (I.NOTES is null and C.NOTES is null))
and ( I.NOTCASETYPE =  C.NOTCASETYPE OR (I.NOTCASETYPE is null and C.NOTCASETYPE is null))
and ( I.NOTCOUNTRYCODE =  C.NOTCOUNTRYCODE OR (I.NOTCOUNTRYCODE is null and C.NOTCOUNTRYCODE is null))
and ( I.NOTPROPERTYTYPE =  C.NOTPROPERTYTYPE OR (I.NOTPROPERTYTYPE is null and C.NOTPROPERTYTYPE is null))
and ( I.NOTCASECATEGORY =  C.NOTCASECATEGORY OR (I.NOTCASECATEGORY is null and C.NOTCASECATEGORY is null))
and ( I.NOTSUBTYPE =  C.NOTSUBTYPE OR (I.NOTSUBTYPE is null and C.NOTSUBTYPE is null))
and ( I.NOTBASIS =  C.NOTBASIS OR (I.NOTBASIS is null and C.NOTBASIS is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DATAVALIDATION]') and xtype='U')
begin
	drop table CCImport_DATAVALIDATION 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnDATAVALIDATION  to public
go
