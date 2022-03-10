-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnNAMECRITERIA
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnNAMECRITERIA]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnNAMECRITERIA.'
	drop function dbo.fn_ccnNAMECRITERIA
	print '**** Creating function dbo.fn_ccnNAMECRITERIA...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_NAMECRITERIA]') and xtype='U')
begin
	select * 
	into CCImport_NAMECRITERIA 
	from NAMECRITERIA
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnNAMECRITERIA
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnNAMECRITERIA
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the NAMECRITERIA table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'NAMECRITERIA' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_NAMECRITERIA I 
	right join NAMECRITERIA C on( C.NAMECRITERIANO=I.NAMECRITERIANO)
where I.NAMECRITERIANO is null
UNION ALL 
select	5, 'NAMECRITERIA', 0, count(*), 0, 0
from CCImport_NAMECRITERIA I 
	left join NAMECRITERIA C on( C.NAMECRITERIANO=I.NAMECRITERIANO)
where C.NAMECRITERIANO is null
UNION ALL 
 select	5, 'NAMECRITERIA', 0, 0, count(*), 0
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
UNION ALL 
 select	5, 'NAMECRITERIA', 0, 0, 0, count(*)
from CCImport_NAMECRITERIA I 
join NAMECRITERIA C	on( C.NAMECRITERIANO=I.NAMECRITERIANO)
where ( I.PURPOSECODE =  C.PURPOSECODE)
and ( I.PROGRAMID =  C.PROGRAMID OR (I.PROGRAMID is null and C.PROGRAMID is null))
and ( I.USEDASFLAG =  C.USEDASFLAG OR (I.USEDASFLAG is null and C.USEDASFLAG is null))
and ( I.SUPPLIERFLAG =  C.SUPPLIERFLAG OR (I.SUPPLIERFLAG is null and C.SUPPLIERFLAG is null))
and ( I.DATAUNKNOWN =  C.DATAUNKNOWN)
and ( I.COUNTRYCODE =  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is null))
and ( I.LOCALCLIENTFLAG =  C.LOCALCLIENTFLAG OR (I.LOCALCLIENTFLAG is null and C.LOCALCLIENTFLAG is null))
and ( I.CATEGORY =  C.CATEGORY OR (I.CATEGORY is null and C.CATEGORY is null))
and ( I.NAMETYPE =  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is null))
and ( I.USERDEFINEDRULE =  C.USERDEFINEDRULE)
and ( I.RULEINUSE =  C.RULEINUSE)
and (replace( I.DESCRIPTION,char(10),char(13)+char(10)) =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))
and ( I.RELATIONSHIP =  C.RELATIONSHIP OR (I.RELATIONSHIP is null and C.RELATIONSHIP is null))
and ( I.PROFILEID =  C.PROFILEID OR (I.PROFILEID is null and C.PROFILEID is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_NAMECRITERIA]') and xtype='U')
begin
	drop table CCImport_NAMECRITERIA 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnNAMECRITERIA  to public
go

