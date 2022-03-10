-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnSCREENCONTROL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnSCREENCONTROL]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnSCREENCONTROL.'
	drop function dbo.fn_ccnSCREENCONTROL
	print '**** Creating function dbo.fn_ccnSCREENCONTROL...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_SCREENCONTROL]') and xtype='U')
begin
	select * 
	into CCImport_SCREENCONTROL 
	from SCREENCONTROL
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnSCREENCONTROL
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnSCREENCONTROL
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the SCREENCONTROL table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'SCREENCONTROL' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_SCREENCONTROL I 
	right join SCREENCONTROL C on( C.CRITERIANO=I.CRITERIANO
and  C.SCREENNAME=I.SCREENNAME
and  C.SCREENID=I.SCREENID)
where I.CRITERIANO is null
UNION ALL 
select	5, 'SCREENCONTROL', 0, count(*), 0, 0
from CCImport_SCREENCONTROL I 
	left join SCREENCONTROL C on( C.CRITERIANO=I.CRITERIANO
and  C.SCREENNAME=I.SCREENNAME
and  C.SCREENID=I.SCREENID)
where C.CRITERIANO is null
UNION ALL 
 select	5, 'SCREENCONTROL', 0, 0, count(*), 0
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
UNION ALL 
 select	5, 'SCREENCONTROL', 0, 0, 0, count(*)
from CCImport_SCREENCONTROL I 
join SCREENCONTROL C	on( C.CRITERIANO=I.CRITERIANO
and C.SCREENNAME=I.SCREENNAME
and C.SCREENID=I.SCREENID)
where ( I.ENTRYNUMBER =  C.ENTRYNUMBER OR (I.ENTRYNUMBER is null and C.ENTRYNUMBER is null))
and ( I.SCREENTITLE =  C.SCREENTITLE OR (I.SCREENTITLE is null and C.SCREENTITLE is null))
and ( I.DISPLAYSEQUENCE =  C.DISPLAYSEQUENCE OR (I.DISPLAYSEQUENCE is null and C.DISPLAYSEQUENCE is null))
and ( I.CHECKLISTTYPE =  C.CHECKLISTTYPE OR (I.CHECKLISTTYPE is null and C.CHECKLISTTYPE is null))
and ( I.TEXTTYPE =  C.TEXTTYPE OR (I.TEXTTYPE is null and C.TEXTTYPE is null))
and ( I.NAMETYPE =  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is null))
and ( I.NAMEGROUP =  C.NAMEGROUP OR (I.NAMEGROUP is null and C.NAMEGROUP is null))
and ( I.FLAGNUMBER =  C.FLAGNUMBER OR (I.FLAGNUMBER is null and C.FLAGNUMBER is null))
and ( I.CREATEACTION =  C.CREATEACTION OR (I.CREATEACTION is null and C.CREATEACTION is null))
and ( I.RELATIONSHIP =  C.RELATIONSHIP OR (I.RELATIONSHIP is null and C.RELATIONSHIP is null))
and ( I.INHERITED =  C.INHERITED OR (I.INHERITED is null and C.INHERITED is null))
and ( I.PROFILENAME =  C.PROFILENAME OR (I.PROFILENAME is null and C.PROFILENAME is null))
and (replace( I.SCREENTIP,char(10),char(13)+char(10)) =  C.SCREENTIP OR (I.SCREENTIP is null and C.SCREENTIP is null))
and ( I.MANDATORYFLAG =  C.MANDATORYFLAG OR (I.MANDATORYFLAG is null and C.MANDATORYFLAG is null))
and (replace( I.GENERICPARAMETER,char(10),char(13)+char(10)) =  C.GENERICPARAMETER OR (I.GENERICPARAMETER is null and C.GENERICPARAMETER is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_SCREENCONTROL]') and xtype='U')
begin
	drop table CCImport_SCREENCONTROL 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnSCREENCONTROL  to public
go
