-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnTMCLASS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnTMCLASS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnTMCLASS.'
	drop function dbo.fn_ccnTMCLASS
	print '**** Creating function dbo.fn_ccnTMCLASS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TMCLASS]') and xtype='U')
begin
	select * 
	into CCImport_TMCLASS 
	from TMCLASS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnTMCLASS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnTMCLASS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TMCLASS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'TMCLASS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_TMCLASS I 
	right join TMCLASS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.CLASS=I.CLASS
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.SEQUENCENO=I.SEQUENCENO)
where I.COUNTRYCODE is null
UNION ALL 
select	2, 'TMCLASS', 0, count(*), 0, 0
from CCImport_TMCLASS I 
	left join TMCLASS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.CLASS=I.CLASS
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.SEQUENCENO=I.SEQUENCENO)
where C.COUNTRYCODE is null
UNION ALL 
 select	2, 'TMCLASS', 0, 0, count(*), 0
from CCImport_TMCLASS I 
	join TMCLASS C	on ( C.COUNTRYCODE=I.COUNTRYCODE
	and C.CLASS=I.CLASS
	and C.PROPERTYTYPE=I.PROPERTYTYPE
	and C.SEQUENCENO=I.SEQUENCENO)
where 	( I.EFFECTIVEDATE <>  C.EFFECTIVEDATE OR (I.EFFECTIVEDATE is null and C.EFFECTIVEDATE is not null) 
OR (I.EFFECTIVEDATE is not null and C.EFFECTIVEDATE is null))
	OR 	( I.GOODSSERVICES <>  C.GOODSSERVICES OR (I.GOODSSERVICES is null and C.GOODSSERVICES is not null) 
OR (I.GOODSSERVICES is not null and C.GOODSSERVICES is null))
	OR 	(replace( I.INTERNATIONALCLASS,char(10),char(13)+char(10)) <>  C.INTERNATIONALCLASS OR (I.INTERNATIONALCLASS is null and C.INTERNATIONALCLASS is not null) 
OR (I.INTERNATIONALCLASS is not null and C.INTERNATIONALCLASS is null))
	OR 	(replace( I.ASSOCIATEDCLASSES,char(10),char(13)+char(10)) <>  C.ASSOCIATEDCLASSES OR (I.ASSOCIATEDCLASSES is null and C.ASSOCIATEDCLASSES is not null) 
OR (I.ASSOCIATEDCLASSES is not null and C.ASSOCIATEDCLASSES is null))
	OR 	( replace(CAST(I.CLASSHEADING as NVARCHAR(MAX)),char(10),char(13)+char(10)) <>  CAST(C.CLASSHEADING as NVARCHAR(MAX)) OR (I.CLASSHEADING is null and C.CLASSHEADING is not null) 
OR (I.CLASSHEADING is not null and C.CLASSHEADING is null))
	OR 	( replace(CAST(I.CLASSNOTES as NVARCHAR(MAX)),char(10),char(13)+char(10)) <>  CAST(C.CLASSNOTES as NVARCHAR(MAX)) OR (I.CLASSNOTES is null and C.CLASSNOTES is not null) 
OR (I.CLASSNOTES is not null and C.CLASSNOTES is null))
	OR 	( I.SUBCLASS <>  C.SUBCLASS OR (I.SUBCLASS is null and C.SUBCLASS is not null) 
OR (I.SUBCLASS is not null and C.SUBCLASS is null))
UNION ALL 
 select	2, 'TMCLASS', 0, 0, 0, count(*)
from CCImport_TMCLASS I 
join TMCLASS C	on( C.COUNTRYCODE=I.COUNTRYCODE
and C.CLASS=I.CLASS
and C.PROPERTYTYPE=I.PROPERTYTYPE
and C.SEQUENCENO=I.SEQUENCENO)
where ( I.EFFECTIVEDATE =  C.EFFECTIVEDATE OR (I.EFFECTIVEDATE is null and C.EFFECTIVEDATE is null))
and ( I.GOODSSERVICES =  C.GOODSSERVICES OR (I.GOODSSERVICES is null and C.GOODSSERVICES is null))
and (replace( I.INTERNATIONALCLASS,char(10),char(13)+char(10)) =  C.INTERNATIONALCLASS OR (I.INTERNATIONALCLASS is null and C.INTERNATIONALCLASS is null))
and (replace( I.ASSOCIATEDCLASSES,char(10),char(13)+char(10)) =  C.ASSOCIATEDCLASSES OR (I.ASSOCIATEDCLASSES is null and C.ASSOCIATEDCLASSES is null))
and ( replace(CAST(I.CLASSHEADING as NVARCHAR(MAX)),char(10),char(13)+char(10)) =  CAST(C.CLASSHEADING as NVARCHAR(MAX)) OR (I.CLASSHEADING is null and C.CLASSHEADING is null))
and ( replace(CAST(I.CLASSNOTES as NVARCHAR(MAX)),char(10),char(13)+char(10)) =  CAST(C.CLASSNOTES as NVARCHAR(MAX)) OR (I.CLASSNOTES is null and C.CLASSNOTES is null))
and ( I.SUBCLASS =  C.SUBCLASS OR (I.SUBCLASS is null and C.SUBCLASS is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TMCLASS]') and xtype='U')
begin
	drop table CCImport_TMCLASS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnTMCLASS  to public
go
