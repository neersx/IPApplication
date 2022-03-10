-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_TMCLASS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_TMCLASS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_TMCLASS.'
	drop function dbo.fn_cc_TMCLASS
	print '**** Creating function dbo.fn_cc_TMCLASS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TMCLASS]') and xtype='U')
begin
	select * 
	into CCImport_TMCLASS 
	from TMCLASS
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_TMCLASS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_TMCLASS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TMCLASS table
-- CALLED BY :	ip_CopyConfigTMCLASS
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
	 null as 'Imported Countrycode',
	 null as 'Imported Class',
	 null as 'Imported Propertytype',
	 null as 'Imported Sequenceno',
	 null as 'Imported Effectivedate',
	 null as 'Imported Goodsservices',
	 null as 'Imported Internationalclass',
	 null as 'Imported Associatedclasses',
	 null as 'Imported Classheading',
	 null as 'Imported Classnotes',
	 null as 'Imported Subclass',
'D' as '-',
	 C.COUNTRYCODE as 'Countrycode',
	 C.CLASS as 'Class',
	 C.PROPERTYTYPE as 'Propertytype',
	 C.SEQUENCENO as 'Sequenceno',
	 C.EFFECTIVEDATE as 'Effectivedate',
	 C.GOODSSERVICES as 'Goodsservices',
	 C.INTERNATIONALCLASS as 'Internationalclass',
	 C.ASSOCIATEDCLASSES as 'Associatedclasses',
	 CAST(C.CLASSHEADING AS NVARCHAR(4000)) as 'Classheading',
	 CAST(C.CLASSNOTES AS NVARCHAR(4000)) as 'Classnotes',
	 C.SUBCLASS as 'Subclass'
from CCImport_TMCLASS I 
	right join TMCLASS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.CLASS=I.CLASS
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.SEQUENCENO=I.SEQUENCENO)
where I.COUNTRYCODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.COUNTRYCODE,
	 I.CLASS,
	 I.PROPERTYTYPE,
	 I.SEQUENCENO,
	 I.EFFECTIVEDATE,
	 I.GOODSSERVICES,
	 I.INTERNATIONALCLASS,
	 I.ASSOCIATEDCLASSES,
	 CAST(I.CLASSHEADING AS NVARCHAR(4000)),
	 CAST(I.CLASSNOTES AS NVARCHAR(4000)),
	 I.SUBCLASS,
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
	 null
from CCImport_TMCLASS I 
	left join TMCLASS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.CLASS=I.CLASS
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.SEQUENCENO=I.SEQUENCENO)
where C.COUNTRYCODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.COUNTRYCODE,
	 I.CLASS,
	 I.PROPERTYTYPE,
	 I.SEQUENCENO,
	 I.EFFECTIVEDATE,
	 I.GOODSSERVICES,
	 I.INTERNATIONALCLASS,
	 I.ASSOCIATEDCLASSES,
	 CAST(I.CLASSHEADING AS NVARCHAR(4000)),
	 CAST(I.CLASSNOTES AS NVARCHAR(4000)),
	 I.SUBCLASS,
'U',
	 C.COUNTRYCODE,
	 C.CLASS,
	 C.PROPERTYTYPE,
	 C.SEQUENCENO,
	 C.EFFECTIVEDATE,
	 C.GOODSSERVICES,
	 C.INTERNATIONALCLASS,
	 C.ASSOCIATEDCLASSES,
	 CAST(C.CLASSHEADING AS NVARCHAR(4000)),
	 CAST(C.CLASSNOTES AS NVARCHAR(4000)),
	 C.SUBCLASS
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

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TMCLASS]') and xtype='U')
begin
	drop table CCImport_TMCLASS 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_TMCLASS  to public
go
