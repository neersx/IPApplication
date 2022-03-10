-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_SCREENCONTROL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_SCREENCONTROL]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_SCREENCONTROL.'
	drop function dbo.fn_cc_SCREENCONTROL
	print '**** Creating function dbo.fn_cc_SCREENCONTROL...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_SCREENCONTROL]') and xtype='U')
begin
	select * 
	into CCImport_SCREENCONTROL 
	from SCREENCONTROL
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_SCREENCONTROL
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_SCREENCONTROL
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the SCREENCONTROL table
-- CALLED BY :	ip_CopyConfigSCREENCONTROL
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
	 null as 'Imported Criteriano',
	 null as 'Imported Screenname',
	 null as 'Imported Screenid',
	 null as 'Imported Entrynumber',
	 null as 'Imported Screentitle',
	 null as 'Imported Displaysequence',
	 null as 'Imported Checklisttype',
	 null as 'Imported Texttype',
	 null as 'Imported Nametype',
	 null as 'Imported Namegroup',
	 null as 'Imported Flagnumber',
	 null as 'Imported Createaction',
	 null as 'Imported Relationship',
	 null as 'Imported Inherited',
	 null as 'Imported Profilename',
	 null as 'Imported Screentip',
	 null as 'Imported Mandatoryflag',
	 null as 'Imported Genericparameter',
'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.SCREENNAME as 'Screenname',
	 C.SCREENID as 'Screenid',
	 C.ENTRYNUMBER as 'Entrynumber',
	 C.SCREENTITLE as 'Screentitle',
	 C.DISPLAYSEQUENCE as 'Displaysequence',
	 C.CHECKLISTTYPE as 'Checklisttype',
	 C.TEXTTYPE as 'Texttype',
	 C.NAMETYPE as 'Nametype',
	 C.NAMEGROUP as 'Namegroup',
	 C.FLAGNUMBER as 'Flagnumber',
	 C.CREATEACTION as 'Createaction',
	 C.RELATIONSHIP as 'Relationship',
	 C.INHERITED as 'Inherited',
	 C.PROFILENAME as 'Profilename',
	 C.SCREENTIP as 'Screentip',
	 C.MANDATORYFLAG as 'Mandatoryflag',
	 C.GENERICPARAMETER as 'Genericparameter'
from CCImport_SCREENCONTROL I 
	right join SCREENCONTROL C on( C.CRITERIANO=I.CRITERIANO
and  C.SCREENNAME=I.SCREENNAME
and  C.SCREENID=I.SCREENID)
where I.CRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.SCREENNAME,
	 I.SCREENID,
	 I.ENTRYNUMBER,
	 I.SCREENTITLE,
	 I.DISPLAYSEQUENCE,
	 I.CHECKLISTTYPE,
	 I.TEXTTYPE,
	 I.NAMETYPE,
	 I.NAMEGROUP,
	 I.FLAGNUMBER,
	 I.CREATEACTION,
	 I.RELATIONSHIP,
	 I.INHERITED,
	 I.PROFILENAME,
	 I.SCREENTIP,
	 I.MANDATORYFLAG,
	 I.GENERICPARAMETER,
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
	 null
from CCImport_SCREENCONTROL I 
	left join SCREENCONTROL C on( C.CRITERIANO=I.CRITERIANO
and  C.SCREENNAME=I.SCREENNAME
and  C.SCREENID=I.SCREENID)
where C.CRITERIANO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIANO,
	 I.SCREENNAME,
	 I.SCREENID,
	 I.ENTRYNUMBER,
	 I.SCREENTITLE,
	 I.DISPLAYSEQUENCE,
	 I.CHECKLISTTYPE,
	 I.TEXTTYPE,
	 I.NAMETYPE,
	 I.NAMEGROUP,
	 I.FLAGNUMBER,
	 I.CREATEACTION,
	 I.RELATIONSHIP,
	 I.INHERITED,
	 I.PROFILENAME,
	 I.SCREENTIP,
	 I.MANDATORYFLAG,
	 I.GENERICPARAMETER,
'U',
	 C.CRITERIANO,
	 C.SCREENNAME,
	 C.SCREENID,
	 C.ENTRYNUMBER,
	 C.SCREENTITLE,
	 C.DISPLAYSEQUENCE,
	 C.CHECKLISTTYPE,
	 C.TEXTTYPE,
	 C.NAMETYPE,
	 C.NAMEGROUP,
	 C.FLAGNUMBER,
	 C.CREATEACTION,
	 C.RELATIONSHIP,
	 C.INHERITED,
	 C.PROFILENAME,
	 C.SCREENTIP,
	 C.MANDATORYFLAG,
	 C.GENERICPARAMETER
from CCImport_SCREENCONTROL I 
	join SCREENCONTROL C	on ( C.CRITERIANO=I.CRITERIANO
	and C.SCREENNAME=I.SCREENNAME
	and C.SCREENID=I.SCREENID)
where 	( I.ENTRYNUMBER <>  C.ENTRYNUMBER OR (I.ENTRYNUMBER is null and C.ENTRYNUMBER is not null) 
OR (I.ENTRYNUMBER is not null and C.ENTRYNUMBER is null))
	OR 	( I.SCREENTITLE <>  C.SCREENTITLE OR (I.SCREENTITLE is null and C.SCREENTITLE is not null) 
OR (I.SCREENTITLE is not null and C.SCREENTITLE is null))
	OR 	( I.DISPLAYSEQUENCE <>  C.DISPLAYSEQUENCE OR (I.DISPLAYSEQUENCE is null and C.DISPLAYSEQUENCE is not null) 
OR (I.DISPLAYSEQUENCE is not null and C.DISPLAYSEQUENCE is null))
	OR 	( I.CHECKLISTTYPE <>  C.CHECKLISTTYPE OR (I.CHECKLISTTYPE is null and C.CHECKLISTTYPE is not null) 
OR (I.CHECKLISTTYPE is not null and C.CHECKLISTTYPE is null))
	OR 	( I.TEXTTYPE <>  C.TEXTTYPE OR (I.TEXTTYPE is null and C.TEXTTYPE is not null) 
OR (I.TEXTTYPE is not null and C.TEXTTYPE is null))
	OR 	( I.NAMETYPE <>  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is not null) 
OR (I.NAMETYPE is not null and C.NAMETYPE is null))
	OR 	( I.NAMEGROUP <>  C.NAMEGROUP OR (I.NAMEGROUP is null and C.NAMEGROUP is not null) 
OR (I.NAMEGROUP is not null and C.NAMEGROUP is null))
	OR 	( I.FLAGNUMBER <>  C.FLAGNUMBER OR (I.FLAGNUMBER is null and C.FLAGNUMBER is not null) 
OR (I.FLAGNUMBER is not null and C.FLAGNUMBER is null))
	OR 	( I.CREATEACTION <>  C.CREATEACTION OR (I.CREATEACTION is null and C.CREATEACTION is not null) 
OR (I.CREATEACTION is not null and C.CREATEACTION is null))
	OR 	( I.RELATIONSHIP <>  C.RELATIONSHIP OR (I.RELATIONSHIP is null and C.RELATIONSHIP is not null) 
OR (I.RELATIONSHIP is not null and C.RELATIONSHIP is null))
	OR 	( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null) 
OR (I.INHERITED is not null and C.INHERITED is null))
	OR 	( I.PROFILENAME <>  C.PROFILENAME OR (I.PROFILENAME is null and C.PROFILENAME is not null) 
OR (I.PROFILENAME is not null and C.PROFILENAME is null))
	OR 	(replace( I.SCREENTIP,char(10),char(13)+char(10)) <>  C.SCREENTIP OR (I.SCREENTIP is null and C.SCREENTIP is not null) 
OR (I.SCREENTIP is not null and C.SCREENTIP is null))
	OR 	( I.MANDATORYFLAG <>  C.MANDATORYFLAG OR (I.MANDATORYFLAG is null and C.MANDATORYFLAG is not null) 
OR (I.MANDATORYFLAG is not null and C.MANDATORYFLAG is null))
	OR 	(replace( I.GENERICPARAMETER,char(10),char(13)+char(10)) <>  C.GENERICPARAMETER OR (I.GENERICPARAMETER is null and C.GENERICPARAMETER is not null) 
OR (I.GENERICPARAMETER is not null and C.GENERICPARAMETER is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_SCREENCONTROL]') and xtype='U')
begin
	drop table CCImport_SCREENCONTROL 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_SCREENCONTROL  to public
go
