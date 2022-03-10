-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnCOUNTRYTEXT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnCOUNTRYTEXT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnCOUNTRYTEXT.'
	drop function dbo.fn_ccnCOUNTRYTEXT
	print '**** Creating function dbo.fn_ccnCOUNTRYTEXT...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_COUNTRYTEXT]') and xtype='U')
begin
	select * 
	into CCImport_COUNTRYTEXT 
	from COUNTRYTEXT
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnCOUNTRYTEXT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnCOUNTRYTEXT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the COUNTRYTEXT table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	4 as TRIPNO, 'COUNTRYTEXT' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_COUNTRYTEXT I 
	right join COUNTRYTEXT C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.TEXTID=I.TEXTID
and  C.SEQUENCE=I.SEQUENCE)
where I.COUNTRYCODE is null
UNION ALL 
select	4, 'COUNTRYTEXT', 0, count(*), 0, 0
from CCImport_COUNTRYTEXT I 
	left join COUNTRYTEXT C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.TEXTID=I.TEXTID
and  C.SEQUENCE=I.SEQUENCE)
where C.COUNTRYCODE is null
UNION ALL 
 select	4, 'COUNTRYTEXT', 0, 0, count(*), 0
from CCImport_COUNTRYTEXT I 
	join COUNTRYTEXT C	on ( C.COUNTRYCODE=I.COUNTRYCODE
	and C.TEXTID=I.TEXTID
	and C.SEQUENCE=I.SEQUENCE)
where 	( I.PROPERTYTYPE <>  C.PROPERTYTYPE OR (I.PROPERTYTYPE is null and C.PROPERTYTYPE is not null) 
OR (I.PROPERTYTYPE is not null and C.PROPERTYTYPE is null))
	OR 	( I.MODIFIEDDATE <>  C.MODIFIEDDATE OR (I.MODIFIEDDATE is null and C.MODIFIEDDATE is not null) 
OR (I.MODIFIEDDATE is not null and C.MODIFIEDDATE is null))
	OR 	( I.LANGUAGE <>  C.LANGUAGE OR (I.LANGUAGE is null and C.LANGUAGE is not null) 
OR (I.LANGUAGE is not null and C.LANGUAGE is null))
	OR 	( I.USEFLAG <>  C.USEFLAG OR (I.USEFLAG is null and C.USEFLAG is not null) 
OR (I.USEFLAG is not null and C.USEFLAG is null))
	OR 	( replace(CAST(I.COUNTRYTEXT as NVARCHAR(MAX)),char(10),char(13)+char(10)) <>  CAST(C.COUNTRYTEXT as NVARCHAR(MAX)) OR (I.COUNTRYTEXT is null and C.COUNTRYTEXT is not null) 
OR (I.COUNTRYTEXT is not null and C.COUNTRYTEXT is null))
UNION ALL 
 select	4, 'COUNTRYTEXT', 0, 0, 0, count(*)
from CCImport_COUNTRYTEXT I 
join COUNTRYTEXT C	on( C.COUNTRYCODE=I.COUNTRYCODE
and C.TEXTID=I.TEXTID
and C.SEQUENCE=I.SEQUENCE)
where ( I.PROPERTYTYPE =  C.PROPERTYTYPE OR (I.PROPERTYTYPE is null and C.PROPERTYTYPE is null))
and ( I.MODIFIEDDATE =  C.MODIFIEDDATE OR (I.MODIFIEDDATE is null and C.MODIFIEDDATE is null))
and ( I.LANGUAGE =  C.LANGUAGE OR (I.LANGUAGE is null and C.LANGUAGE is null))
and ( I.USEFLAG =  C.USEFLAG OR (I.USEFLAG is null and C.USEFLAG is null))
and ( replace(CAST(I.COUNTRYTEXT as NVARCHAR(MAX)),char(10),char(13)+char(10)) =  CAST(C.COUNTRYTEXT as NVARCHAR(MAX)) OR (I.COUNTRYTEXT is null and C.COUNTRYTEXT is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_COUNTRYTEXT]') and xtype='U')
begin
	drop table CCImport_COUNTRYTEXT 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnCOUNTRYTEXT  to public
go
