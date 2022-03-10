-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnLETTER
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnLETTER]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnLETTER.'
	drop function dbo.fn_ccnLETTER
	print '**** Creating function dbo.fn_ccnLETTER...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_LETTER]') and xtype='U')
begin
	select * 
	into CCImport_LETTER 
	from LETTER
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnLETTER
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnLETTER
-- VERSION :	2
-- DESCRIPTION:	The SELECT to display of imported data for the LETTER table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
-- 11 Apr 2017	MF	71020	2	New columns added.
--
As 
Return
select	10 as TRIPNO, 'LETTER' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_LETTER I 
	right join LETTER C on( C.LETTERNO=I.LETTERNO)
where I.LETTERNO is null
UNION ALL 
select	10, 'LETTER', 0, count(*), 0, 0
from CCImport_LETTER I 
	left join LETTER C on( C.LETTERNO=I.LETTERNO)
where C.LETTERNO is null
UNION ALL 
 select	10, 'LETTER', 0, 0, count(*), 0
from CCImport_LETTER I 
	join LETTER C	on ( C.LETTERNO=I.LETTERNO)
where 	(replace( I.LETTERNAME,char(10),char(13)+char(10)) <>  C.LETTERNAME OR (I.LETTERNAME is null and C.LETTERNAME is not null) 
OR (I.LETTERNAME is not null and C.LETTERNAME is null))
	OR 	( I.DOCUMENTCODE <>  C.DOCUMENTCODE OR (I.DOCUMENTCODE is null and C.DOCUMENTCODE is not null) 
OR (I.DOCUMENTCODE is not null and C.DOCUMENTCODE is null))
	OR 	( I.CORRESPONDTYPE <>  C.CORRESPONDTYPE OR (I.CORRESPONDTYPE is null and C.CORRESPONDTYPE is not null) 
OR (I.CORRESPONDTYPE is not null and C.CORRESPONDTYPE is null))
	OR 	( I.COPIESALLOWEDFLAG <>  C.COPIESALLOWEDFLAG OR (I.COPIESALLOWEDFLAG is null and C.COPIESALLOWEDFLAG is not null) 
OR (I.COPIESALLOWEDFLAG is not null and C.COPIESALLOWEDFLAG is null))
	OR 	( I.COVERINGLETTER <>  C.COVERINGLETTER OR (I.COVERINGLETTER is null and C.COVERINGLETTER is not null) 
OR (I.COVERINGLETTER is not null and C.COVERINGLETTER is null))
	OR 	( I.EXTRACOPIES <>  C.EXTRACOPIES OR (I.EXTRACOPIES is null and C.EXTRACOPIES is not null) 
OR (I.EXTRACOPIES is not null and C.EXTRACOPIES is null))
	OR 	( I.MULTICASEFLAG <>  C.MULTICASEFLAG OR (I.MULTICASEFLAG is null and C.MULTICASEFLAG is not null) 
OR (I.MULTICASEFLAG is not null and C.MULTICASEFLAG is null))
	OR 	(replace( I.MACRO,char(10),char(13)+char(10)) <>  C.MACRO OR (I.MACRO is null and C.MACRO is not null) 
OR (I.MACRO is not null and C.MACRO is null))
	OR 	( I.SINGLECASELETTERNO <>  C.SINGLECASELETTERNO OR (I.SINGLECASELETTERNO is null and C.SINGLECASELETTERNO is not null) 
OR (I.SINGLECASELETTERNO is not null and C.SINGLECASELETTERNO is null))
	OR 	( I.INSTRUCTIONTYPE <>  C.INSTRUCTIONTYPE OR (I.INSTRUCTIONTYPE is null and C.INSTRUCTIONTYPE is not null) 
OR (I.INSTRUCTIONTYPE is not null and C.INSTRUCTIONTYPE is null))
	OR 	( I.ENVELOPE <>  C.ENVELOPE OR (I.ENVELOPE is null and C.ENVELOPE is not null) 
OR (I.ENVELOPE is not null and C.ENVELOPE is null))
	OR 	( I.COUNTRYCODE <>  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is not null) 
OR (I.COUNTRYCODE is not null and C.COUNTRYCODE is null))
	OR 	( I.DELIVERYID <>  C.DELIVERYID OR (I.DELIVERYID is null and C.DELIVERYID is not null) 
OR (I.DELIVERYID is not null and C.DELIVERYID is null))
	OR 	( I.PROPERTYTYPE <>  C.PROPERTYTYPE OR (I.PROPERTYTYPE is null and C.PROPERTYTYPE is not null) 
OR (I.PROPERTYTYPE is not null and C.PROPERTYTYPE is null))
	OR 	( I.HOLDFLAG <>  C.HOLDFLAG OR (I.HOLDFLAG is null and C.HOLDFLAG is not null) 
OR (I.HOLDFLAG is not null and C.HOLDFLAG is null))
	OR 	(replace( I.NOTES,char(10),char(13)+char(10)) <>  C.NOTES OR (I.NOTES is null and C.NOTES is not null) 
OR (I.NOTES is not null and C.NOTES is null))
	OR 	( I.DOCUMENTTYPE <>  C.DOCUMENTTYPE)
	OR 	( I.USEDBY <>  C.USEDBY)
	OR 	( I.FORPRIMECASESONLY <>  C.FORPRIMECASESONLY)
	OR 	( I.GENERATEASANSI <>  C.GENERATEASANSI OR (I.GENERATEASANSI is null and C.GENERATEASANSI is not null) 
OR (I.GENERATEASANSI is not null and C.GENERATEASANSI is null))
	OR 	( I.ADDATTACHMENTFLAG <>  C.ADDATTACHMENTFLAG OR (I.ADDATTACHMENTFLAG is null and C.ADDATTACHMENTFLAG is not null) 
OR (I.ADDATTACHMENTFLAG is not null and C.ADDATTACHMENTFLAG is null))
	OR 	( I.ACTIVITYTYPE <>  C.ACTIVITYTYPE OR (I.ACTIVITYTYPE is null and C.ACTIVITYTYPE is not null) 
OR (I.ACTIVITYTYPE is not null and C.ACTIVITYTYPE is null))
	OR 	( I.ACTIVITYCATEGORY <>  C.ACTIVITYCATEGORY OR (I.ACTIVITYCATEGORY is null and C.ACTIVITYCATEGORY is not null) 
OR (I.ACTIVITYCATEGORY is not null and C.ACTIVITYCATEGORY is null))
	OR 	( I.ENTRYPOINTTYPE <>  C.ENTRYPOINTTYPE OR (I.ENTRYPOINTTYPE is null and C.ENTRYPOINTTYPE is not null) 
OR (I.ENTRYPOINTTYPE is not null and C.ENTRYPOINTTYPE is null))
	OR 	(replace( I.SOURCEFILE,char(10),char(13)+char(10)) <>  C.SOURCEFILE OR (I.SOURCEFILE is null and C.SOURCEFILE is not null) 
OR (I.SOURCEFILE is not null and C.SOURCEFILE is null))
	OR 	( I.EXTERNALUSAGE <>  C.EXTERNALUSAGE)
	OR 	( I.DELIVERLETTER <>  C.DELIVERLETTER OR (I.DELIVERLETTER is null and C.DELIVERLETTER is not null) 
OR (I.DELIVERLETTER is not null and C.DELIVERLETTER is null))
	OR 	( I.DOCITEMMAILBOX <>  C.DOCITEMMAILBOX OR (I.DOCITEMMAILBOX is null and C.DOCITEMMAILBOX is not null) 
OR (I.DOCITEMMAILBOX is not null and C.DOCITEMMAILBOX is null))
	OR 	( I.DOCITEMSUBJECT <>  C.DOCITEMSUBJECT OR (I.DOCITEMSUBJECT is null and C.DOCITEMSUBJECT is not null) 
OR (I.DOCITEMSUBJECT is not null and C.DOCITEMSUBJECT is null))
	OR 	( I.DOCITEMBODY <>  C.DOCITEMBODY OR (I.DOCITEMBODY is null and C.DOCITEMBODY is not null) 
OR (I.DOCITEMBODY is not null and C.DOCITEMBODY is null))
	OR 	( I.PROTECTEDFLAG <>  C.PROTECTEDFLAG OR (I.PROTECTEDFLAG is null and C.PROTECTEDFLAG is not null) 
OR (I.PROTECTEDFLAG is not null and C.PROTECTEDFLAG is null))
UNION ALL 
 select	10, 'LETTER', 0, 0, 0, count(*)
from CCImport_LETTER I 
join LETTER C	on( C.LETTERNO=I.LETTERNO)
where (replace( I.LETTERNAME,char(10),char(13)+char(10)) =  C.LETTERNAME OR (I.LETTERNAME is null and C.LETTERNAME is null))
and ( I.DOCUMENTCODE =  C.DOCUMENTCODE OR (I.DOCUMENTCODE is null and C.DOCUMENTCODE is null))
and ( I.CORRESPONDTYPE =  C.CORRESPONDTYPE OR (I.CORRESPONDTYPE is null and C.CORRESPONDTYPE is null))
and ( I.COPIESALLOWEDFLAG =  C.COPIESALLOWEDFLAG OR (I.COPIESALLOWEDFLAG is null and C.COPIESALLOWEDFLAG is null))
and ( I.COVERINGLETTER =  C.COVERINGLETTER OR (I.COVERINGLETTER is null and C.COVERINGLETTER is null))
and ( I.EXTRACOPIES =  C.EXTRACOPIES OR (I.EXTRACOPIES is null and C.EXTRACOPIES is null))
and ( I.MULTICASEFLAG =  C.MULTICASEFLAG OR (I.MULTICASEFLAG is null and C.MULTICASEFLAG is null))
and (replace( I.MACRO,char(10),char(13)+char(10)) =  C.MACRO OR (I.MACRO is null and C.MACRO is null))
and ( I.SINGLECASELETTERNO =  C.SINGLECASELETTERNO OR (I.SINGLECASELETTERNO is null and C.SINGLECASELETTERNO is null))
and ( I.INSTRUCTIONTYPE =  C.INSTRUCTIONTYPE OR (I.INSTRUCTIONTYPE is null and C.INSTRUCTIONTYPE is null))
and ( I.ENVELOPE =  C.ENVELOPE OR (I.ENVELOPE is null and C.ENVELOPE is null))
and ( I.COUNTRYCODE =  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is null))
and ( I.DELIVERYID =  C.DELIVERYID OR (I.DELIVERYID is null and C.DELIVERYID is null))
and ( I.PROPERTYTYPE =  C.PROPERTYTYPE OR (I.PROPERTYTYPE is null and C.PROPERTYTYPE is null))
and ( I.HOLDFLAG =  C.HOLDFLAG OR (I.HOLDFLAG is null and C.HOLDFLAG is null))
and (replace( I.NOTES,char(10),char(13)+char(10)) =  C.NOTES OR (I.NOTES is null and C.NOTES is null))
and ( I.DOCUMENTTYPE =  C.DOCUMENTTYPE)
and ( I.USEDBY =  C.USEDBY)
and ( I.FORPRIMECASESONLY =  C.FORPRIMECASESONLY)
and ( I.GENERATEASANSI =  C.GENERATEASANSI OR (I.GENERATEASANSI is null and C.GENERATEASANSI is null))
and ( I.ADDATTACHMENTFLAG =  C.ADDATTACHMENTFLAG OR (I.ADDATTACHMENTFLAG is null and C.ADDATTACHMENTFLAG is null))
and ( I.ACTIVITYTYPE =  C.ACTIVITYTYPE OR (I.ACTIVITYTYPE is null and C.ACTIVITYTYPE is null))
and ( I.ACTIVITYCATEGORY =  C.ACTIVITYCATEGORY OR (I.ACTIVITYCATEGORY is null and C.ACTIVITYCATEGORY is null))
and ( I.ENTRYPOINTTYPE =  C.ENTRYPOINTTYPE OR (I.ENTRYPOINTTYPE is null and C.ENTRYPOINTTYPE is null))
and (replace( I.SOURCEFILE,char(10),char(13)+char(10)) =  C.SOURCEFILE OR (I.SOURCEFILE is null and C.SOURCEFILE is null))
and ( I.EXTERNALUSAGE =  C.EXTERNALUSAGE)
and ( I.DELIVERLETTER =  C.DELIVERLETTER OR (I.DELIVERLETTER is null and C.DELIVERLETTER is null))
and ( I.DOCITEMMAILBOX =  C.DOCITEMMAILBOX OR (I.DOCITEMMAILBOX is null and C.DOCITEMMAILBOX is null))
and ( I.DOCITEMSUBJECT =  C.DOCITEMSUBJECT OR (I.DOCITEMSUBJECT is null and C.DOCITEMSUBJECT is null))
and ( I.DOCITEMBODY =  C.DOCITEMBODY OR (I.DOCITEMBODY is null and C.DOCITEMBODY is null))
and ( I.PROTECTEDFLAG =  C.PROTECTEDFLAG OR (I.PROTECTEDFLAG is null and C.PROTECTEDFLAG is  null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_LETTER]') and xtype='U')
begin
	drop table CCImport_LETTER 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnLETTER  to public
go
