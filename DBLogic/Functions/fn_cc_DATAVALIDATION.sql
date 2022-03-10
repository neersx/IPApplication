-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_DATAVALIDATION
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_DATAVALIDATION]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_DATAVALIDATION.'
	drop function dbo.fn_cc_DATAVALIDATION
	print '**** Creating function dbo.fn_cc_DATAVALIDATION...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
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


CREATE FUNCTION dbo.fn_cc_DATAVALIDATION
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_DATAVALIDATION
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the DATAVALIDATION table
-- CALLED BY :	ip_CopyConfigDATAVALIDATION
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
	 null as 'Imported Inuseflag',
	 null as 'Imported Deferredflag',
	 null as 'Imported Officeid',
	 null as 'Imported Functionalarea',
	 null as 'Imported Casetype',
	 null as 'Imported Countrycode',
	 null as 'Imported Propertytype',
	 null as 'Imported Casecategory',
	 null as 'Imported Subtype',
	 null as 'Imported Basis',
	 null as 'Imported Eventno',
	 null as 'Imported Eventdateflag',
	 null as 'Imported Statusflag',
	 null as 'Imported Familyno',
	 null as 'Imported Localclientflag',
	 null as 'Imported Usedasflag',
	 null as 'Imported Supplierflag',
	 null as 'Imported Category',
	 null as 'Imported Nameno',
	 null as 'Imported Nametype',
	 null as 'Imported Instructiontype',
	 null as 'Imported Flagnumber',
	 null as 'Imported Columnname',
	 null as 'Imported Ruledescription',
	 null as 'Imported Item_id',
	 null as 'Imported Roleid',
	 null as 'Imported Programcontext',
	 null as 'Imported Warningflag',
	 null as 'Imported Displaymessage',
	 null as 'Imported Notes',
	 null as 'Imported Notcasetype',
	 null as 'Imported Notcountrycode',
	 null as 'Imported Notpropertytype',
	 null as 'Imported Notcasecategory',
	 null as 'Imported Notsubtype',
	 null as 'Imported Notbasis',
'D' as '-',
	 C.INUSEFLAG as 'Inuseflag',
	 C.DEFERREDFLAG as 'Deferredflag',
	 C.OFFICEID as 'Officeid',
	 C.FUNCTIONALAREA as 'Functionalarea',
	 C.CASETYPE as 'Casetype',
	 C.COUNTRYCODE as 'Countrycode',
	 C.PROPERTYTYPE as 'Propertytype',
	 C.CASECATEGORY as 'Casecategory',
	 C.SUBTYPE as 'Subtype',
	 C.BASIS as 'Basis',
	 C.EVENTNO as 'Eventno',
	 C.EVENTDATEFLAG as 'Eventdateflag',
	 C.STATUSFLAG as 'Statusflag',
	 C.FAMILYNO as 'Familyno',
	 C.LOCALCLIENTFLAG as 'Localclientflag',
	 C.USEDASFLAG as 'Usedasflag',
	 C.SUPPLIERFLAG as 'Supplierflag',
	 C.CATEGORY as 'Category',
	 C.NAMENO as 'Nameno',
	 C.NAMETYPE as 'Nametype',
	 C.INSTRUCTIONTYPE as 'Instructiontype',
	 C.FLAGNUMBER as 'Flagnumber',
	 C.COLUMNNAME as 'Columnname',
	 C.RULEDESCRIPTION as 'Ruledescription',
	 C.ITEM_ID as 'Item_id',
	 C.ROLEID as 'Roleid',
	 C.PROGRAMCONTEXT as 'Programcontext',
	 C.WARNINGFLAG as 'Warningflag',
	 C.DISPLAYMESSAGE as 'Displaymessage',
	 C.NOTES as 'Notes',
	 C.NOTCASETYPE as 'Notcasetype',
	 C.NOTCOUNTRYCODE as 'Notcountrycode',
	 C.NOTPROPERTYTYPE as 'Notpropertytype',
	 C.NOTCASECATEGORY as 'Notcasecategory',
	 C.NOTSUBTYPE as 'Notsubtype',
	 C.NOTBASIS as 'Notbasis'
from CCImport_DATAVALIDATION I 
	right join DATAVALIDATION C on( C.VALIDATIONID=I.VALIDATIONID)
where I.VALIDATIONID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.INUSEFLAG,
	 I.DEFERREDFLAG,
	 I.OFFICEID,
	 I.FUNCTIONALAREA,
	 I.CASETYPE,
	 I.COUNTRYCODE,
	 I.PROPERTYTYPE,
	 I.CASECATEGORY,
	 I.SUBTYPE,
	 I.BASIS,
	 I.EVENTNO,
	 I.EVENTDATEFLAG,
	 I.STATUSFLAG,
	 I.FAMILYNO,
	 I.LOCALCLIENTFLAG,
	 I.USEDASFLAG,
	 I.SUPPLIERFLAG,
	 I.CATEGORY,
	 I.NAMENO,
	 I.NAMETYPE,
	 I.INSTRUCTIONTYPE,
	 I.FLAGNUMBER,
	 I.COLUMNNAME,
	 I.RULEDESCRIPTION,
	 I.ITEM_ID,
	 I.ROLEID,
	 I.PROGRAMCONTEXT,
	 I.WARNINGFLAG,
	 I.DISPLAYMESSAGE,
	 I.NOTES,
	 I.NOTCASETYPE,
	 I.NOTCOUNTRYCODE,
	 I.NOTPROPERTYTYPE,
	 I.NOTCASECATEGORY,
	 I.NOTSUBTYPE,
	 I.NOTBASIS,
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
	 null ,
	 null ,
	 null ,
	 null
from CCImport_DATAVALIDATION I 
	left join DATAVALIDATION C on( C.VALIDATIONID=I.VALIDATIONID)
where C.VALIDATIONID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.INUSEFLAG,
	 I.DEFERREDFLAG,
	 I.OFFICEID,
	 I.FUNCTIONALAREA,
	 I.CASETYPE,
	 I.COUNTRYCODE,
	 I.PROPERTYTYPE,
	 I.CASECATEGORY,
	 I.SUBTYPE,
	 I.BASIS,
	 I.EVENTNO,
	 I.EVENTDATEFLAG,
	 I.STATUSFLAG,
	 I.FAMILYNO,
	 I.LOCALCLIENTFLAG,
	 I.USEDASFLAG,
	 I.SUPPLIERFLAG,
	 I.CATEGORY,
	 I.NAMENO,
	 I.NAMETYPE,
	 I.INSTRUCTIONTYPE,
	 I.FLAGNUMBER,
	 I.COLUMNNAME,
	 I.RULEDESCRIPTION,
	 I.ITEM_ID,
	 I.ROLEID,
	 I.PROGRAMCONTEXT,
	 I.WARNINGFLAG,
	 I.DISPLAYMESSAGE,
	 I.NOTES,
	 I.NOTCASETYPE,
	 I.NOTCOUNTRYCODE,
	 I.NOTPROPERTYTYPE,
	 I.NOTCASECATEGORY,
	 I.NOTSUBTYPE,
	 I.NOTBASIS,
'U',
	 C.INUSEFLAG,
	 C.DEFERREDFLAG,
	 C.OFFICEID,
	 C.FUNCTIONALAREA,
	 C.CASETYPE,
	 C.COUNTRYCODE,
	 C.PROPERTYTYPE,
	 C.CASECATEGORY,
	 C.SUBTYPE,
	 C.BASIS,
	 C.EVENTNO,
	 C.EVENTDATEFLAG,
	 C.STATUSFLAG,
	 C.FAMILYNO,
	 C.LOCALCLIENTFLAG,
	 C.USEDASFLAG,
	 C.SUPPLIERFLAG,
	 C.CATEGORY,
	 C.NAMENO,
	 C.NAMETYPE,
	 C.INSTRUCTIONTYPE,
	 C.FLAGNUMBER,
	 C.COLUMNNAME,
	 C.RULEDESCRIPTION,
	 C.ITEM_ID,
	 C.ROLEID,
	 C.PROGRAMCONTEXT,
	 C.WARNINGFLAG,
	 C.DISPLAYMESSAGE,
	 C.NOTES,
	 C.NOTCASETYPE,
	 C.NOTCOUNTRYCODE,
	 C.NOTPROPERTYTYPE,
	 C.NOTCASECATEGORY,
	 C.NOTSUBTYPE,
	 C.NOTBASIS
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

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DATAVALIDATION]') and xtype='U')
begin
	drop table CCImport_DATAVALIDATION 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_DATAVALIDATION  to public
go
