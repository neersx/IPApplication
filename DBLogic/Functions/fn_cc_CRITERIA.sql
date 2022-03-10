-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_CRITERIA
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_CRITERIA]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_CRITERIA.'
	drop function dbo.fn_cc_CRITERIA
	print '**** Creating function dbo.fn_cc_CRITERIA...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_CRITERIA]') and xtype='U')
begin
	select * 
	into CCImport_CRITERIA 
	from CRITERIA
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_CRITERIA
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_CRITERIA
-- VERSION :	2
-- DESCRIPTION:	The SELECT to display of imported data for the CRITERIA table
-- CALLED BY :	ip_CopyConfigCRITERIA
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
-- 22 Jul 2013	DL	S21395	2	Add CRITERIA.NEWSUBTYPE
--
As 
Return
select	1 as 'Switch',
	'X' as 'Match',
	'D' as 'Imported -',
	 null as 'Imported Criteriano',
	 null as 'Imported Purposecode',
	 null as 'Imported Casetype',
	 null as 'Imported Action',
	 null as 'Imported Checklisttype',
	 null as 'Imported Programid',
	 null as 'Imported Propertytype',
	 null as 'Imported Propertyunknown',
	 null as 'Imported Countrycode',
	 null as 'Imported Countryunknown',
	 null as 'Imported Casecategory',
	 null as 'Imported Categoryunknown',
	 null as 'Imported Subtype',
	 null as 'Imported Subtypeunknown',
	 null as 'Imported Basis',
	 null as 'Imported Registeredusers',
	 null as 'Imported Localclientflag',
	 null as 'Imported Tablecode',
	 null as 'Imported Rateno',
	 null as 'Imported Dateofact',
	 null as 'Imported Userdefinedrule',
	 null as 'Imported Ruleinuse',
	 null as 'Imported Startdetailentry',
	 null as 'Imported Parentcriteria',
	 null as 'Imported Belongstogroup',
	 null as 'Imported Description',
	 null as 'Imported Typeofmark',
	 null as 'Imported Renewaltype',
	 null as 'Imported Caseofficeid',
	 null as 'Imported Linktitle',
	 null as 'Imported Linkdescription',
	 null as 'Imported Docitemid',
	 null as 'Imported Url',
	 null as 'Imported Ispublic',
	 null as 'Imported Groupid',
	 null as 'Imported Productcode',
	 null as 'Imported Newcasetype',
	 null as 'Imported Newcountrycode',
	 null as 'Imported Newpropertytype',
	 null as 'Imported Newcasecategory',
	 null as 'Imported Newsubtype',
	 null as 'Imported Profilename',
	 null as 'Imported Systemid',
	 null as 'Imported Dataextractid',
	 null as 'Imported Ruletype',
	 null as 'Imported Requesttype',
	 null as 'Imported Datasourcetype',
	 null as 'Imported Datasourcenameno',
	 null as 'Imported Renewalstatus',
	 null as 'Imported Statuscode',
	 null as 'Imported Profileid',
'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.PURPOSECODE as 'Purposecode',
	 C.CASETYPE as 'Casetype',
	 C.ACTION as 'Action',
	 C.CHECKLISTTYPE as 'Checklisttype',
	 C.PROGRAMID as 'Programid',
	 C.PROPERTYTYPE as 'Propertytype',
	 C.PROPERTYUNKNOWN as 'Propertyunknown',
	 C.COUNTRYCODE as 'Countrycode',
	 C.COUNTRYUNKNOWN as 'Countryunknown',
	 C.CASECATEGORY as 'Casecategory',
	 C.CATEGORYUNKNOWN as 'Categoryunknown',
	 C.SUBTYPE as 'Subtype',
	 C.SUBTYPEUNKNOWN as 'Subtypeunknown',
	 C.BASIS as 'Basis',
	 C.REGISTEREDUSERS as 'Registeredusers',
	 C.LOCALCLIENTFLAG as 'Localclientflag',
	 C.TABLECODE as 'Tablecode',
	 C.RATENO as 'Rateno',
	 C.DATEOFACT as 'Dateofact',
	 C.USERDEFINEDRULE as 'Userdefinedrule',
	 C.RULEINUSE as 'Ruleinuse',
	 C.STARTDETAILENTRY as 'Startdetailentry',
	 C.PARENTCRITERIA as 'Parentcriteria',
	 C.BELONGSTOGROUP as 'Belongstogroup',
	 C.DESCRIPTION as 'Description',
	 C.TYPEOFMARK as 'Typeofmark',
	 C.RENEWALTYPE as 'Renewaltype',
	 C.CASEOFFICEID as 'Caseofficeid',
	 C.LINKTITLE as 'Linktitle',
	 C.LINKDESCRIPTION as 'Linkdescription',
	 C.DOCITEMID as 'Docitemid',
	 C.URL as 'Url',
	 C.ISPUBLIC as 'Ispublic',
	 C.GROUPID as 'Groupid',
	 C.PRODUCTCODE as 'Productcode',
	 C.NEWCASETYPE as 'Newcasetype',
	 C.NEWCOUNTRYCODE as 'Newcountrycode',
	 C.NEWPROPERTYTYPE as 'Newpropertytype',
	 C.NEWCASECATEGORY as 'Newcasecategory',
	 C.NEWSUBTYPE as 'Newsubtype',
	 C.PROFILENAME as 'Profilename',
	 C.SYSTEMID as 'Systemid',
	 C.DATAEXTRACTID as 'Dataextractid',
	 C.RULETYPE as 'Ruletype',
	 C.REQUESTTYPE as 'Requesttype',
	 C.DATASOURCETYPE as 'Datasourcetype',
	 C.DATASOURCENAMENO as 'Datasourcenameno',
	 C.RENEWALSTATUS as 'Renewalstatus',
	 C.STATUSCODE as 'Statuscode',
	 C.PROFILEID as 'Profileid'
from CCImport_CRITERIA I 
	right join CRITERIA C on( C.CRITERIANO=I.CRITERIANO)
where I.CRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.PURPOSECODE,
	 I.CASETYPE,
	 I.ACTION,
	 I.CHECKLISTTYPE,
	 I.PROGRAMID,
	 I.PROPERTYTYPE,
	 I.PROPERTYUNKNOWN,
	 I.COUNTRYCODE,
	 I.COUNTRYUNKNOWN,
	 I.CASECATEGORY,
	 I.CATEGORYUNKNOWN,
	 I.SUBTYPE,
	 I.SUBTYPEUNKNOWN,
	 I.BASIS,
	 I.REGISTEREDUSERS,
	 I.LOCALCLIENTFLAG,
	 I.TABLECODE,
	 I.RATENO,
	 I.DATEOFACT,
	 I.USERDEFINEDRULE,
	 I.RULEINUSE,
	 I.STARTDETAILENTRY,
	 I.PARENTCRITERIA,
	 I.BELONGSTOGROUP,
	 I.DESCRIPTION,
	 I.TYPEOFMARK,
	 I.RENEWALTYPE,
	 I.CASEOFFICEID,
	 I.LINKTITLE,
	 I.LINKDESCRIPTION,
	 I.DOCITEMID,
	 I.URL,
	 I.ISPUBLIC,
	 I.GROUPID,
	 I.PRODUCTCODE,
	 I.NEWCASETYPE,
	 I.NEWCOUNTRYCODE,
	 I.NEWPROPERTYTYPE,
	 I.NEWCASECATEGORY,
	 I.NEWSUBTYPE,
	 I.PROFILENAME,
	 I.SYSTEMID,
	 I.DATAEXTRACTID,
	 I.RULETYPE,
	 I.REQUESTTYPE,
	 I.DATASOURCETYPE,
	 I.DATASOURCENAMENO,
	 I.RENEWALSTATUS,
	 I.STATUSCODE,
	 I.PROFILEID,
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
from CCImport_CRITERIA I 
	left join CRITERIA C on( C.CRITERIANO=I.CRITERIANO)
where C.CRITERIANO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIANO,
	 I.PURPOSECODE,
	 I.CASETYPE,
	 I.ACTION,
	 I.CHECKLISTTYPE,
	 I.PROGRAMID,
	 I.PROPERTYTYPE,
	 I.PROPERTYUNKNOWN,
	 I.COUNTRYCODE,
	 I.COUNTRYUNKNOWN,
	 I.CASECATEGORY,
	 I.CATEGORYUNKNOWN,
	 I.SUBTYPE,
	 I.SUBTYPEUNKNOWN,
	 I.BASIS,
	 I.REGISTEREDUSERS,
	 I.LOCALCLIENTFLAG,
	 I.TABLECODE,
	 I.RATENO,
	 I.DATEOFACT,
	 I.USERDEFINEDRULE,
	 I.RULEINUSE,
	 I.STARTDETAILENTRY,
	 I.PARENTCRITERIA,
	 I.BELONGSTOGROUP,
	 I.DESCRIPTION,
	 I.TYPEOFMARK,
	 I.RENEWALTYPE,
	 I.CASEOFFICEID,
	 I.LINKTITLE,
	 I.LINKDESCRIPTION,
	 I.DOCITEMID,
	 I.URL,
	 I.ISPUBLIC,
	 I.GROUPID,
	 I.PRODUCTCODE,
	 I.NEWCASETYPE,
	 I.NEWCOUNTRYCODE,
	 I.NEWPROPERTYTYPE,
	 I.NEWCASECATEGORY,
	 I.NEWSUBTYPE,
	 I.PROFILENAME,
	 I.SYSTEMID,
	 I.DATAEXTRACTID,
	 I.RULETYPE,
	 I.REQUESTTYPE,
	 I.DATASOURCETYPE,
	 I.DATASOURCENAMENO,
	 I.RENEWALSTATUS,
	 I.STATUSCODE,
	 I.PROFILEID,
'U',
	 C.CRITERIANO,
	 C.PURPOSECODE,
	 C.CASETYPE,
	 C.ACTION,
	 C.CHECKLISTTYPE,
	 C.PROGRAMID,
	 C.PROPERTYTYPE,
	 C.PROPERTYUNKNOWN,
	 C.COUNTRYCODE,
	 C.COUNTRYUNKNOWN,
	 C.CASECATEGORY,
	 C.CATEGORYUNKNOWN,
	 C.SUBTYPE,
	 C.SUBTYPEUNKNOWN,
	 C.BASIS,
	 C.REGISTEREDUSERS,
	 C.LOCALCLIENTFLAG,
	 C.TABLECODE,
	 C.RATENO,
	 C.DATEOFACT,
	 C.USERDEFINEDRULE,
	 C.RULEINUSE,
	 C.STARTDETAILENTRY,
	 C.PARENTCRITERIA,
	 C.BELONGSTOGROUP,
	 C.DESCRIPTION,
	 C.TYPEOFMARK,
	 C.RENEWALTYPE,
	 C.CASEOFFICEID,
	 C.LINKTITLE,
	 C.LINKDESCRIPTION,
	 C.DOCITEMID,
	 C.URL,
	 C.ISPUBLIC,
	 C.GROUPID,
	 C.PRODUCTCODE,
	 C.NEWCASETYPE,
	 C.NEWCOUNTRYCODE,
	 C.NEWPROPERTYTYPE,
	 C.NEWCASECATEGORY,
	 C.NEWSUBTYPE,
	 C.PROFILENAME,
	 C.SYSTEMID,
	 C.DATAEXTRACTID,
	 C.RULETYPE,
	 C.REQUESTTYPE,
	 C.DATASOURCETYPE,
	 C.DATASOURCENAMENO,
	 C.RENEWALSTATUS,
	 C.STATUSCODE,
	 C.PROFILEID
from CCImport_CRITERIA I 
	join CRITERIA C	on ( C.CRITERIANO=I.CRITERIANO)
where 	( I.PURPOSECODE <>  C.PURPOSECODE OR (I.PURPOSECODE is null and C.PURPOSECODE is not null) 
OR (I.PURPOSECODE is not null and C.PURPOSECODE is null))
	OR 	( I.CASETYPE <>  C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is not null) 
OR (I.CASETYPE is not null and C.CASETYPE is null))
	OR 	( I.ACTION <>  C.ACTION OR (I.ACTION is null and C.ACTION is not null) 
OR (I.ACTION is not null and C.ACTION is null))
	OR 	( I.CHECKLISTTYPE <>  C.CHECKLISTTYPE OR (I.CHECKLISTTYPE is null and C.CHECKLISTTYPE is not null) 
OR (I.CHECKLISTTYPE is not null and C.CHECKLISTTYPE is null))
	OR 	( I.PROGRAMID <>  C.PROGRAMID OR (I.PROGRAMID is null and C.PROGRAMID is not null) 
OR (I.PROGRAMID is not null and C.PROGRAMID is null))
	OR 	( I.PROPERTYTYPE <>  C.PROPERTYTYPE OR (I.PROPERTYTYPE is null and C.PROPERTYTYPE is not null) 
OR (I.PROPERTYTYPE is not null and C.PROPERTYTYPE is null))
	OR 	( I.PROPERTYUNKNOWN <>  C.PROPERTYUNKNOWN OR (I.PROPERTYUNKNOWN is null and C.PROPERTYUNKNOWN is not null) 
OR (I.PROPERTYUNKNOWN is not null and C.PROPERTYUNKNOWN is null))
	OR 	( I.COUNTRYCODE <>  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is not null) 
OR (I.COUNTRYCODE is not null and C.COUNTRYCODE is null))
	OR 	( I.COUNTRYUNKNOWN <>  C.COUNTRYUNKNOWN OR (I.COUNTRYUNKNOWN is null and C.COUNTRYUNKNOWN is not null) 
OR (I.COUNTRYUNKNOWN is not null and C.COUNTRYUNKNOWN is null))
	OR 	( I.CASECATEGORY <>  C.CASECATEGORY OR (I.CASECATEGORY is null and C.CASECATEGORY is not null) 
OR (I.CASECATEGORY is not null and C.CASECATEGORY is null))
	OR 	( I.CATEGORYUNKNOWN <>  C.CATEGORYUNKNOWN OR (I.CATEGORYUNKNOWN is null and C.CATEGORYUNKNOWN is not null) 
OR (I.CATEGORYUNKNOWN is not null and C.CATEGORYUNKNOWN is null))
	OR 	( I.SUBTYPE <>  C.SUBTYPE OR (I.SUBTYPE is null and C.SUBTYPE is not null) 
OR (I.SUBTYPE is not null and C.SUBTYPE is null))
	OR 	( I.SUBTYPEUNKNOWN <>  C.SUBTYPEUNKNOWN OR (I.SUBTYPEUNKNOWN is null and C.SUBTYPEUNKNOWN is not null) 
OR (I.SUBTYPEUNKNOWN is not null and C.SUBTYPEUNKNOWN is null))
	OR 	( I.BASIS <>  C.BASIS OR (I.BASIS is null and C.BASIS is not null) 
OR (I.BASIS is not null and C.BASIS is null))
	OR 	( I.REGISTEREDUSERS <>  C.REGISTEREDUSERS OR (I.REGISTEREDUSERS is null and C.REGISTEREDUSERS is not null) 
OR (I.REGISTEREDUSERS is not null and C.REGISTEREDUSERS is null))
	OR 	( I.LOCALCLIENTFLAG <>  C.LOCALCLIENTFLAG OR (I.LOCALCLIENTFLAG is null and C.LOCALCLIENTFLAG is not null) 
OR (I.LOCALCLIENTFLAG is not null and C.LOCALCLIENTFLAG is null))
	OR 	( I.TABLECODE <>  C.TABLECODE OR (I.TABLECODE is null and C.TABLECODE is not null) 
OR (I.TABLECODE is not null and C.TABLECODE is null))
	OR 	( I.RATENO <>  C.RATENO OR (I.RATENO is null and C.RATENO is not null) 
OR (I.RATENO is not null and C.RATENO is null))
	OR 	( I.DATEOFACT <>  C.DATEOFACT OR (I.DATEOFACT is null and C.DATEOFACT is not null) 
OR (I.DATEOFACT is not null and C.DATEOFACT is null))
	OR 	( I.USERDEFINEDRULE <>  C.USERDEFINEDRULE OR (I.USERDEFINEDRULE is null and C.USERDEFINEDRULE is not null) 
OR (I.USERDEFINEDRULE is not null and C.USERDEFINEDRULE is null))
	OR 	( I.RULEINUSE <>  C.RULEINUSE OR (I.RULEINUSE is null and C.RULEINUSE is not null) 
OR (I.RULEINUSE is not null and C.RULEINUSE is null))
	OR 	( I.STARTDETAILENTRY <>  C.STARTDETAILENTRY OR (I.STARTDETAILENTRY is null and C.STARTDETAILENTRY is not null) 
OR (I.STARTDETAILENTRY is not null and C.STARTDETAILENTRY is null))
	OR 	( I.PARENTCRITERIA <>  C.PARENTCRITERIA OR (I.PARENTCRITERIA is null and C.PARENTCRITERIA is not null) 
OR (I.PARENTCRITERIA is not null and C.PARENTCRITERIA is null))
	OR 	( I.BELONGSTOGROUP <>  C.BELONGSTOGROUP OR (I.BELONGSTOGROUP is null and C.BELONGSTOGROUP is not null) 
OR (I.BELONGSTOGROUP is not null and C.BELONGSTOGROUP is null))
	OR 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.TYPEOFMARK <>  C.TYPEOFMARK OR (I.TYPEOFMARK is null and C.TYPEOFMARK is not null) 
OR (I.TYPEOFMARK is not null and C.TYPEOFMARK is null))
	OR 	( I.RENEWALTYPE <>  C.RENEWALTYPE OR (I.RENEWALTYPE is null and C.RENEWALTYPE is not null) 
OR (I.RENEWALTYPE is not null and C.RENEWALTYPE is null))
	OR 	( I.CASEOFFICEID <>  C.CASEOFFICEID OR (I.CASEOFFICEID is null and C.CASEOFFICEID is not null) 
OR (I.CASEOFFICEID is not null and C.CASEOFFICEID is null))
	OR 	( I.LINKTITLE <>  C.LINKTITLE OR (I.LINKTITLE is null and C.LINKTITLE is not null) 
OR (I.LINKTITLE is not null and C.LINKTITLE is null))
	OR 	(replace( I.LINKDESCRIPTION,char(10),char(13)+char(10)) <>  C.LINKDESCRIPTION OR (I.LINKDESCRIPTION is null and C.LINKDESCRIPTION is not null) 
OR (I.LINKDESCRIPTION is not null and C.LINKDESCRIPTION is null))
	OR 	( I.DOCITEMID <>  C.DOCITEMID OR (I.DOCITEMID is null and C.DOCITEMID is not null) 
OR (I.DOCITEMID is not null and C.DOCITEMID is null))
	OR 	(replace( I.URL,char(10),char(13)+char(10)) <>  C.URL OR (I.URL is null and C.URL is not null) 
OR (I.URL is not null and C.URL is null))
	OR 	( I.ISPUBLIC <>  C.ISPUBLIC)
	OR 	( I.GROUPID <>  C.GROUPID OR (I.GROUPID is null and C.GROUPID is not null) 
OR (I.GROUPID is not null and C.GROUPID is null))
	OR 	( I.PRODUCTCODE <>  C.PRODUCTCODE OR (I.PRODUCTCODE is null and C.PRODUCTCODE is not null) 
OR (I.PRODUCTCODE is not null and C.PRODUCTCODE is null))
	OR 	( I.NEWCASETYPE <>  C.NEWCASETYPE OR (I.NEWCASETYPE is null and C.NEWCASETYPE is not null) 
OR (I.NEWCASETYPE is not null and C.NEWCASETYPE is null))
	OR 	( I.NEWCOUNTRYCODE <>  C.NEWCOUNTRYCODE OR (I.NEWCOUNTRYCODE is null and C.NEWCOUNTRYCODE is not null) 
OR (I.NEWCOUNTRYCODE is not null and C.NEWCOUNTRYCODE is null))
	OR 	( I.NEWPROPERTYTYPE <>  C.NEWPROPERTYTYPE OR (I.NEWPROPERTYTYPE is null and C.NEWPROPERTYTYPE is not null) 
OR (I.NEWPROPERTYTYPE is not null and C.NEWPROPERTYTYPE is null))
	OR 	( I.NEWCASECATEGORY <>  C.NEWCASECATEGORY OR (I.NEWCASECATEGORY is null and C.NEWCASECATEGORY is not null) 
OR (I.NEWCASECATEGORY is not null and C.NEWCASECATEGORY is null))
	OR 	( I.NEWSUBTYPE <>  C.NEWSUBTYPE OR (I.NEWSUBTYPE is null and C.NEWSUBTYPE is not null) 
OR (I.NEWSUBTYPE is not null and C.NEWSUBTYPE is null))
	OR 	( I.PROFILENAME <>  C.PROFILENAME OR (I.PROFILENAME is null and C.PROFILENAME is not null) 
OR (I.PROFILENAME is not null and C.PROFILENAME is null))
	OR 	( I.SYSTEMID <>  C.SYSTEMID OR (I.SYSTEMID is null and C.SYSTEMID is not null) 
OR (I.SYSTEMID is not null and C.SYSTEMID is null))
	OR 	( I.DATAEXTRACTID <>  C.DATAEXTRACTID OR (I.DATAEXTRACTID is null and C.DATAEXTRACTID is not null) 
OR (I.DATAEXTRACTID is not null and C.DATAEXTRACTID is null))
	OR 	( I.RULETYPE <>  C.RULETYPE OR (I.RULETYPE is null and C.RULETYPE is not null) 
OR (I.RULETYPE is not null and C.RULETYPE is null))
	OR 	( I.REQUESTTYPE <>  C.REQUESTTYPE OR (I.REQUESTTYPE is null and C.REQUESTTYPE is not null) 
OR (I.REQUESTTYPE is not null and C.REQUESTTYPE is null))
	OR 	( I.DATASOURCETYPE <>  C.DATASOURCETYPE OR (I.DATASOURCETYPE is null and C.DATASOURCETYPE is not null) 
OR (I.DATASOURCETYPE is not null and C.DATASOURCETYPE is null))
	OR 	( I.DATASOURCENAMENO <>  C.DATASOURCENAMENO OR (I.DATASOURCENAMENO is null and C.DATASOURCENAMENO is not null) 
OR (I.DATASOURCENAMENO is not null and C.DATASOURCENAMENO is null))
	OR 	( I.RENEWALSTATUS <>  C.RENEWALSTATUS OR (I.RENEWALSTATUS is null and C.RENEWALSTATUS is not null) 
OR (I.RENEWALSTATUS is not null and C.RENEWALSTATUS is null))
	OR 	( I.STATUSCODE <>  C.STATUSCODE OR (I.STATUSCODE is null and C.STATUSCODE is not null) 
OR (I.STATUSCODE is not null and C.STATUSCODE is null))
	OR 	( I.PROFILEID <>  C.PROFILEID OR (I.PROFILEID is null and C.PROFILEID is not null) 
OR (I.PROFILEID is not null and C.PROFILEID is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CRITERIA]') and xtype='U')
begin
	drop table CCImport_CRITERIA 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_CRITERIA  to public
go

