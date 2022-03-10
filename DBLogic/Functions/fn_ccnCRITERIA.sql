-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnCRITERIA
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnCRITERIA]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnCRITERIA.'
	drop function dbo.fn_ccnCRITERIA
	print '**** Creating function dbo.fn_ccnCRITERIA...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
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


CREATE FUNCTION dbo.fn_ccnCRITERIA
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnCRITERIA
-- VERSION :	2
-- DESCRIPTION:	The SELECT to display of imported data for the CRITERIA table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
-- 22 Jul 2013	DL	S21395	2	Add CRITERIA.NEWSUBTYPE
--
As 
Return
select	5 as TRIPNO, 'CRITERIA' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_CRITERIA I 
	right join CRITERIA C on( C.CRITERIANO=I.CRITERIANO)
where I.CRITERIANO is null
UNION ALL 
select	5, 'CRITERIA', 0, count(*), 0, 0
from CCImport_CRITERIA I 
	left join CRITERIA C on( C.CRITERIANO=I.CRITERIANO)
where C.CRITERIANO is null
UNION ALL 
 select	5, 'CRITERIA', 0, 0, count(*), 0
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
UNION ALL 
 select	5, 'CRITERIA', 0, 0, 0, count(*)
from CCImport_CRITERIA I 
join CRITERIA C	on( C.CRITERIANO=I.CRITERIANO)
where ( I.PURPOSECODE =  C.PURPOSECODE OR (I.PURPOSECODE is null and C.PURPOSECODE is null))
and ( I.CASETYPE =  C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is null))
and ( I.ACTION =  C.ACTION OR (I.ACTION is null and C.ACTION is null))
and ( I.CHECKLISTTYPE =  C.CHECKLISTTYPE OR (I.CHECKLISTTYPE is null and C.CHECKLISTTYPE is null))
and ( I.PROGRAMID =  C.PROGRAMID OR (I.PROGRAMID is null and C.PROGRAMID is null))
and ( I.PROPERTYTYPE =  C.PROPERTYTYPE OR (I.PROPERTYTYPE is null and C.PROPERTYTYPE is null))
and ( I.PROPERTYUNKNOWN =  C.PROPERTYUNKNOWN OR (I.PROPERTYUNKNOWN is null and C.PROPERTYUNKNOWN is null))
and ( I.COUNTRYCODE =  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is null))
and ( I.COUNTRYUNKNOWN =  C.COUNTRYUNKNOWN OR (I.COUNTRYUNKNOWN is null and C.COUNTRYUNKNOWN is null))
and ( I.CASECATEGORY =  C.CASECATEGORY OR (I.CASECATEGORY is null and C.CASECATEGORY is null))
and ( I.CATEGORYUNKNOWN =  C.CATEGORYUNKNOWN OR (I.CATEGORYUNKNOWN is null and C.CATEGORYUNKNOWN is null))
and ( I.SUBTYPE =  C.SUBTYPE OR (I.SUBTYPE is null and C.SUBTYPE is null))
and ( I.SUBTYPEUNKNOWN =  C.SUBTYPEUNKNOWN OR (I.SUBTYPEUNKNOWN is null and C.SUBTYPEUNKNOWN is null))
and ( I.BASIS =  C.BASIS OR (I.BASIS is null and C.BASIS is null))
and ( I.REGISTEREDUSERS =  C.REGISTEREDUSERS OR (I.REGISTEREDUSERS is null and C.REGISTEREDUSERS is null))
and ( I.LOCALCLIENTFLAG =  C.LOCALCLIENTFLAG OR (I.LOCALCLIENTFLAG is null and C.LOCALCLIENTFLAG is null))
and ( I.TABLECODE =  C.TABLECODE OR (I.TABLECODE is null and C.TABLECODE is null))
and ( I.RATENO =  C.RATENO OR (I.RATENO is null and C.RATENO is null))
and ( I.DATEOFACT =  C.DATEOFACT OR (I.DATEOFACT is null and C.DATEOFACT is null))
and ( I.USERDEFINEDRULE =  C.USERDEFINEDRULE OR (I.USERDEFINEDRULE is null and C.USERDEFINEDRULE is null))
and ( I.RULEINUSE =  C.RULEINUSE OR (I.RULEINUSE is null and C.RULEINUSE is null))
and ( I.STARTDETAILENTRY =  C.STARTDETAILENTRY OR (I.STARTDETAILENTRY is null and C.STARTDETAILENTRY is null))
and ( I.PARENTCRITERIA =  C.PARENTCRITERIA OR (I.PARENTCRITERIA is null and C.PARENTCRITERIA is null))
and ( I.BELONGSTOGROUP =  C.BELONGSTOGROUP OR (I.BELONGSTOGROUP is null and C.BELONGSTOGROUP is null))
and (replace( I.DESCRIPTION,char(10),char(13)+char(10)) =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))
and ( I.TYPEOFMARK =  C.TYPEOFMARK OR (I.TYPEOFMARK is null and C.TYPEOFMARK is null))
and ( I.RENEWALTYPE =  C.RENEWALTYPE OR (I.RENEWALTYPE is null and C.RENEWALTYPE is null))
and ( I.CASEOFFICEID =  C.CASEOFFICEID OR (I.CASEOFFICEID is null and C.CASEOFFICEID is null))
and ( I.LINKTITLE =  C.LINKTITLE OR (I.LINKTITLE is null and C.LINKTITLE is null))
and (replace( I.LINKDESCRIPTION,char(10),char(13)+char(10)) =  C.LINKDESCRIPTION OR (I.LINKDESCRIPTION is null and C.LINKDESCRIPTION is null))
and ( I.DOCITEMID =  C.DOCITEMID OR (I.DOCITEMID is null and C.DOCITEMID is null))
and (replace( I.URL,char(10),char(13)+char(10)) =  C.URL OR (I.URL is null and C.URL is null))
and ( I.ISPUBLIC =  C.ISPUBLIC)
and ( I.GROUPID =  C.GROUPID OR (I.GROUPID is null and C.GROUPID is null))
and ( I.PRODUCTCODE =  C.PRODUCTCODE OR (I.PRODUCTCODE is null and C.PRODUCTCODE is null))
and ( I.NEWCASETYPE =  C.NEWCASETYPE OR (I.NEWCASETYPE is null and C.NEWCASETYPE is null))
and ( I.NEWCOUNTRYCODE =  C.NEWCOUNTRYCODE OR (I.NEWCOUNTRYCODE is null and C.NEWCOUNTRYCODE is null))
and ( I.NEWPROPERTYTYPE =  C.NEWPROPERTYTYPE OR (I.NEWPROPERTYTYPE is null and C.NEWPROPERTYTYPE is null))
and ( I.NEWCASECATEGORY =  C.NEWCASECATEGORY OR (I.NEWCASECATEGORY is null and C.NEWCASECATEGORY is null))
and ( I.NEWSUBTYPE =  C.NEWSUBTYPE OR (I.NEWSUBTYPE is null and C.NEWSUBTYPE is null))
and ( I.PROFILENAME =  C.PROFILENAME OR (I.PROFILENAME is null and C.PROFILENAME is null))
and ( I.SYSTEMID =  C.SYSTEMID OR (I.SYSTEMID is null and C.SYSTEMID is null))
and ( I.DATAEXTRACTID =  C.DATAEXTRACTID OR (I.DATAEXTRACTID is null and C.DATAEXTRACTID is null))
and ( I.RULETYPE =  C.RULETYPE OR (I.RULETYPE is null and C.RULETYPE is null))
and ( I.REQUESTTYPE =  C.REQUESTTYPE OR (I.REQUESTTYPE is null and C.REQUESTTYPE is null))
and ( I.DATASOURCETYPE =  C.DATASOURCETYPE OR (I.DATASOURCETYPE is null and C.DATASOURCETYPE is null))
and ( I.DATASOURCENAMENO =  C.DATASOURCENAMENO OR (I.DATASOURCENAMENO is null and C.DATASOURCENAMENO is null))
and ( I.RENEWALSTATUS =  C.RENEWALSTATUS OR (I.RENEWALSTATUS is null and C.RENEWALSTATUS is null))
and ( I.STATUSCODE =  C.STATUSCODE OR (I.STATUSCODE is null and C.STATUSCODE is null))
and ( I.PROFILEID =  C.PROFILEID OR (I.PROFILEID is null and C.PROFILEID is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CRITERIA]') and xtype='U')
begin
	drop table CCImport_CRITERIA 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnCRITERIA  to public
go
