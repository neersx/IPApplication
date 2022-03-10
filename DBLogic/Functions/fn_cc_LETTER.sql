-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_LETTER
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_LETTER]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_LETTER.'
	drop function dbo.fn_cc_LETTER
	print '**** Creating function dbo.fn_cc_LETTER...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_LETTER]') and xtype='U')
begin
	select * 
	into CCImport_LETTER 
	from LETTER
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_LETTER
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_LETTER
-- VERSION :	2
-- DESCRIPTION:	The SELECT to display of imported data for the LETTER table
-- CALLED BY :	ip_CopyConfigLETTER
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
-- 03 Apr 2017	MF	71020	2	New columns added.
--
As 
Return
select	1 as 'Switch',
	'X' as 'Match',
	'D' as 'Imported -',
	 null as 'Imported Letterno',
	 null as 'Imported Lettername',
	 null as 'Imported Documentcode',
	 null as 'Imported Correspondtype',
	 null as 'Imported Copiesallowedflag',
	 null as 'Imported Coveringletter',
	 null as 'Imported Extracopies',
	 null as 'Imported Multicaseflag',
	 null as 'Imported Macro',
	 null as 'Imported Singlecaseletterno',
	 null as 'Imported Instructiontype',
	 null as 'Imported Envelope',
	 null as 'Imported Countrycode',
	 null as 'Imported Deliveryid',
	 null as 'Imported Propertytype',
	 null as 'Imported Holdflag',
	 null as 'Imported Notes',
	 null as 'Imported Documenttype',
	 null as 'Imported Usedby',
	 null as 'Imported Forprimecasesonly',
	 null as 'Imported Generateasansi',
	 null as 'Imported Addattachmentflag',
	 null as 'Imported Activitytype',
	 null as 'Imported Activitycategory',
	 null as 'Imported Entrypointtype',
	 null as 'Imported Sourcefile',
	 null as 'Imported Externalusage',
	 null as 'Imported Deliverletter',
	 null as 'Imported Docitemmailbox',
	 null as 'Imported Docitemsubject',
	 null as 'Imported Docitembody',
	 null as 'Imported Protectedflag',
	'D' as '-',
	 C.LETTERNO as 'Letterno',
	 C.LETTERNAME as 'Lettername',
	 C.DOCUMENTCODE as 'Documentcode',
	 C.CORRESPONDTYPE as 'Correspondtype',
	 C.COPIESALLOWEDFLAG as 'Copiesallowedflag',
	 C.COVERINGLETTER as 'Coveringletter',
	 C.EXTRACOPIES as 'Extracopies',
	 C.MULTICASEFLAG as 'Multicaseflag',
	 C.MACRO as 'Macro',
	 C.SINGLECASELETTERNO as 'Singlecaseletterno',
	 C.INSTRUCTIONTYPE as 'Instructiontype',
	 C.ENVELOPE as 'Envelope',
	 C.COUNTRYCODE as 'Countrycode',
	 C.DELIVERYID as 'Deliveryid',
	 C.PROPERTYTYPE as 'Propertytype',
	 C.HOLDFLAG as 'Holdflag',
	 C.NOTES as 'Notes',
	 C.DOCUMENTTYPE as 'Documenttype',
	 C.USEDBY as 'Usedby',
	 C.FORPRIMECASESONLY as 'Forprimecasesonly',
	 C.GENERATEASANSI as 'Generateasansi',
	 C.ADDATTACHMENTFLAG as 'Addattachmentflag',
	 C.ACTIVITYTYPE as 'Activitytype',
	 C.ACTIVITYCATEGORY as 'Activitycategory',
	 C.ENTRYPOINTTYPE as 'Entrypointtype',
	 C.SOURCEFILE as 'Sourcefile',
	 C.EXTERNALUSAGE as 'Externalusage',
	 C.DELIVERLETTER as 'Deliverletter',
	 C.DOCITEMMAILBOX as 'Docitemmailbox',
	 C.DOCITEMSUBJECT as 'Docitemsubject',
	 C.DOCITEMBODY as 'Docitembody',
	 C.PROTECTEDFLAG as 'Protectedflag'
from CCImport_LETTER I 
	right join LETTER C on( C.LETTERNO=I.LETTERNO)
where I.LETTERNO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.LETTERNO,
	 I.LETTERNAME,
	 I.DOCUMENTCODE,
	 I.CORRESPONDTYPE,
	 I.COPIESALLOWEDFLAG,
	 I.COVERINGLETTER,
	 I.EXTRACOPIES,
	 I.MULTICASEFLAG,
	 I.MACRO,
	 I.SINGLECASELETTERNO,
	 I.INSTRUCTIONTYPE,
	 I.ENVELOPE,
	 I.COUNTRYCODE,
	 I.DELIVERYID,
	 I.PROPERTYTYPE,
	 I.HOLDFLAG,
	 I.NOTES,
	 I.DOCUMENTTYPE,
	 I.USEDBY,
	 I.FORPRIMECASESONLY,
	 I.GENERATEASANSI,
	 I.ADDATTACHMENTFLAG,
	 I.ACTIVITYTYPE,
	 I.ACTIVITYCATEGORY,
	 I.ENTRYPOINTTYPE,
	 I.SOURCEFILE,
	 I.EXTERNALUSAGE,
	 I.DELIVERLETTER,
	 I.DOCITEMMAILBOX,
	 I.DOCITEMSUBJECT,
	 I.DOCITEMBODY,
	 I.PROTECTEDFLAG,
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
	 null
from CCImport_LETTER I 
	left join LETTER C on( C.LETTERNO=I.LETTERNO)
where C.LETTERNO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.LETTERNO,
	 I.LETTERNAME,
	 I.DOCUMENTCODE,
	 I.CORRESPONDTYPE,
	 I.COPIESALLOWEDFLAG,
	 I.COVERINGLETTER,
	 I.EXTRACOPIES,
	 I.MULTICASEFLAG,
	 I.MACRO,
	 I.SINGLECASELETTERNO,
	 I.INSTRUCTIONTYPE,
	 I.ENVELOPE,
	 I.COUNTRYCODE,
	 I.DELIVERYID,
	 I.PROPERTYTYPE,
	 I.HOLDFLAG,
	 I.NOTES,
	 I.DOCUMENTTYPE,
	 I.USEDBY,
	 I.FORPRIMECASESONLY,
	 I.GENERATEASANSI,
	 I.ADDATTACHMENTFLAG,
	 I.ACTIVITYTYPE,
	 I.ACTIVITYCATEGORY,
	 I.ENTRYPOINTTYPE,
	 I.SOURCEFILE,
	 I.EXTERNALUSAGE,
	 I.DELIVERLETTER,
	 I.DOCITEMMAILBOX,
	 I.DOCITEMSUBJECT,
	 I.DOCITEMBODY,
	 I.PROTECTEDFLAG,
	'U',
	 C.LETTERNO,
	 C.LETTERNAME,
	 C.DOCUMENTCODE,
	 C.CORRESPONDTYPE,
	 C.COPIESALLOWEDFLAG,
	 C.COVERINGLETTER,
	 C.EXTRACOPIES,
	 C.MULTICASEFLAG,
	 C.MACRO,
	 C.SINGLECASELETTERNO,
	 C.INSTRUCTIONTYPE,
	 C.ENVELOPE,
	 C.COUNTRYCODE,
	 C.DELIVERYID,
	 C.PROPERTYTYPE,
	 C.HOLDFLAG,
	 C.NOTES,
	 C.DOCUMENTTYPE,
	 C.USEDBY,
	 C.FORPRIMECASESONLY,
	 C.GENERATEASANSI,
	 C.ADDATTACHMENTFLAG,
	 C.ACTIVITYTYPE,
	 C.ACTIVITYCATEGORY,
	 C.ENTRYPOINTTYPE,
	 C.SOURCEFILE,
	 C.EXTERNALUSAGE,
	 C.DELIVERLETTER,
	 C.DOCITEMMAILBOX,
	 C.DOCITEMSUBJECT,
	 C.DOCITEMBODY,
	 C.PROTECTEDFLAG
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

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_LETTER]') and xtype='U')
begin
	drop table CCImport_LETTER 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_LETTER  to public
go
