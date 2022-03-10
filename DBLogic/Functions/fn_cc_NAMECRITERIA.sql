-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_NAMECRITERIA
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_NAMECRITERIA]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_NAMECRITERIA.'
	drop function dbo.fn_cc_NAMECRITERIA
	print '**** Creating function dbo.fn_cc_NAMECRITERIA...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_NAMECRITERIA]') and xtype='U')
begin
	select * 
	into CCImport_NAMECRITERIA 
	from NAMECRITERIA
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_NAMECRITERIA
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_NAMECRITERIA
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the NAMECRITERIA table
-- CALLED BY :	ip_CopyConfigNAMECRITERIA
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
	 null as 'Imported Namecriteriano',
	 null as 'Imported Purposecode',
	 null as 'Imported Programid',
	 null as 'Imported Usedasflag',
	 null as 'Imported Supplierflag',
	 null as 'Imported Dataunknown',
	 null as 'Imported Countrycode',
	 null as 'Imported Localclientflag',
	 null as 'Imported Category',
	 null as 'Imported Nametype',
	 null as 'Imported Userdefinedrule',
	 null as 'Imported Ruleinuse',
	 null as 'Imported Description',
	 null as 'Imported Relationship',
	 null as 'Imported Profileid',
'D' as '-',
	 C.NAMECRITERIANO as 'Namecriteriano',
	 C.PURPOSECODE as 'Purposecode',
	 C.PROGRAMID as 'Programid',
	 C.USEDASFLAG as 'Usedasflag',
	 C.SUPPLIERFLAG as 'Supplierflag',
	 C.DATAUNKNOWN as 'Dataunknown',
	 C.COUNTRYCODE as 'Countrycode',
	 C.LOCALCLIENTFLAG as 'Localclientflag',
	 C.CATEGORY as 'Category',
	 C.NAMETYPE as 'Nametype',
	 C.USERDEFINEDRULE as 'Userdefinedrule',
	 C.RULEINUSE as 'Ruleinuse',
	 C.DESCRIPTION as 'Description',
	 C.RELATIONSHIP as 'Relationship',
	 C.PROFILEID as 'Profileid'
from CCImport_NAMECRITERIA I 
	right join NAMECRITERIA C on( C.NAMECRITERIANO=I.NAMECRITERIANO)
where I.NAMECRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.NAMECRITERIANO,
	 I.PURPOSECODE,
	 I.PROGRAMID,
	 I.USEDASFLAG,
	 I.SUPPLIERFLAG,
	 I.DATAUNKNOWN,
	 I.COUNTRYCODE,
	 I.LOCALCLIENTFLAG,
	 I.CATEGORY,
	 I.NAMETYPE,
	 I.USERDEFINEDRULE,
	 I.RULEINUSE,
	 I.DESCRIPTION,
	 I.RELATIONSHIP,
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
	 null
from CCImport_NAMECRITERIA I 
	left join NAMECRITERIA C on( C.NAMECRITERIANO=I.NAMECRITERIANO)
where C.NAMECRITERIANO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.NAMECRITERIANO,
	 I.PURPOSECODE,
	 I.PROGRAMID,
	 I.USEDASFLAG,
	 I.SUPPLIERFLAG,
	 I.DATAUNKNOWN,
	 I.COUNTRYCODE,
	 I.LOCALCLIENTFLAG,
	 I.CATEGORY,
	 I.NAMETYPE,
	 I.USERDEFINEDRULE,
	 I.RULEINUSE,
	 I.DESCRIPTION,
	 I.RELATIONSHIP,
	 I.PROFILEID,
'U',
	 C.NAMECRITERIANO,
	 C.PURPOSECODE,
	 C.PROGRAMID,
	 C.USEDASFLAG,
	 C.SUPPLIERFLAG,
	 C.DATAUNKNOWN,
	 C.COUNTRYCODE,
	 C.LOCALCLIENTFLAG,
	 C.CATEGORY,
	 C.NAMETYPE,
	 C.USERDEFINEDRULE,
	 C.RULEINUSE,
	 C.DESCRIPTION,
	 C.RELATIONSHIP,
	 C.PROFILEID
from CCImport_NAMECRITERIA I 
	join NAMECRITERIA C	on ( C.NAMECRITERIANO=I.NAMECRITERIANO)
where 	( I.PURPOSECODE <>  C.PURPOSECODE)
	OR 	( I.PROGRAMID <>  C.PROGRAMID OR (I.PROGRAMID is null and C.PROGRAMID is not null) 
OR (I.PROGRAMID is not null and C.PROGRAMID is null))
	OR 	( I.USEDASFLAG <>  C.USEDASFLAG OR (I.USEDASFLAG is null and C.USEDASFLAG is not null) 
OR (I.USEDASFLAG is not null and C.USEDASFLAG is null))
	OR 	( I.SUPPLIERFLAG <>  C.SUPPLIERFLAG OR (I.SUPPLIERFLAG is null and C.SUPPLIERFLAG is not null) 
OR (I.SUPPLIERFLAG is not null and C.SUPPLIERFLAG is null))
	OR 	( I.DATAUNKNOWN <>  C.DATAUNKNOWN)
	OR 	( I.COUNTRYCODE <>  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is not null) 
OR (I.COUNTRYCODE is not null and C.COUNTRYCODE is null))
	OR 	( I.LOCALCLIENTFLAG <>  C.LOCALCLIENTFLAG OR (I.LOCALCLIENTFLAG is null and C.LOCALCLIENTFLAG is not null) 
OR (I.LOCALCLIENTFLAG is not null and C.LOCALCLIENTFLAG is null))
	OR 	( I.CATEGORY <>  C.CATEGORY OR (I.CATEGORY is null and C.CATEGORY is not null) 
OR (I.CATEGORY is not null and C.CATEGORY is null))
	OR 	( I.NAMETYPE <>  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is not null) 
OR (I.NAMETYPE is not null and C.NAMETYPE is null))
	OR 	( I.USERDEFINEDRULE <>  C.USERDEFINEDRULE)
	OR 	( I.RULEINUSE <>  C.RULEINUSE)
	OR 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.RELATIONSHIP <>  C.RELATIONSHIP OR (I.RELATIONSHIP is null and C.RELATIONSHIP is not null) 
OR (I.RELATIONSHIP is not null and C.RELATIONSHIP is null))
	OR 	( I.PROFILEID <>  C.PROFILEID OR (I.PROFILEID is null and C.PROFILEID is not null) 
OR (I.PROFILEID is not null and C.PROFILEID is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_NAMECRITERIA]') and xtype='U')
begin
	drop table CCImport_NAMECRITERIA 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_NAMECRITERIA  to public
go
