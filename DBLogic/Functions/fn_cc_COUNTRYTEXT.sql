-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_COUNTRYTEXT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_COUNTRYTEXT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_COUNTRYTEXT.'
	drop function dbo.fn_cc_COUNTRYTEXT
	print '**** Creating function dbo.fn_cc_COUNTRYTEXT...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
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


CREATE FUNCTION dbo.fn_cc_COUNTRYTEXT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_COUNTRYTEXT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the COUNTRYTEXT table
-- CALLED BY :	ip_CopyConfigCOUNTRYTEXT
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
	 null as 'Imported Textid',
	 null as 'Imported Sequence',
	 null as 'Imported Propertytype',
	 null as 'Imported Modifieddate',
	 null as 'Imported Language',
	 null as 'Imported Useflag',
	 null as 'Imported Countrytext',
'D' as '-',
	 C.COUNTRYCODE as 'Countrycode',
	 C.TEXTID as 'Textid',
	 C.SEQUENCE as 'Sequence',
	 C.PROPERTYTYPE as 'Propertytype',
	 C.MODIFIEDDATE as 'Modifieddate',
	 C.LANGUAGE as 'Language',
	 C.USEFLAG as 'Useflag',
	 CAST(C.COUNTRYTEXT AS NVARCHAR(4000)) as 'Countrytext'
from CCImport_COUNTRYTEXT I 
	right join COUNTRYTEXT C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.TEXTID=I.TEXTID
and  C.SEQUENCE=I.SEQUENCE)
where I.COUNTRYCODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.COUNTRYCODE,
	 I.TEXTID,
	 I.SEQUENCE,
	 I.PROPERTYTYPE,
	 I.MODIFIEDDATE,
	 I.LANGUAGE,
	 I.USEFLAG,
	 CAST(I.COUNTRYTEXT AS NVARCHAR(4000)),
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_COUNTRYTEXT I 
	left join COUNTRYTEXT C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.TEXTID=I.TEXTID
and  C.SEQUENCE=I.SEQUENCE)
where C.COUNTRYCODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.COUNTRYCODE,
	 I.TEXTID,
	 I.SEQUENCE,
	 I.PROPERTYTYPE,
	 I.MODIFIEDDATE,
	 I.LANGUAGE,
	 I.USEFLAG,
	 CAST(I.COUNTRYTEXT AS NVARCHAR(4000)),
'U',
	 C.COUNTRYCODE,
	 C.TEXTID,
	 C.SEQUENCE,
	 C.PROPERTYTYPE,
	 C.MODIFIEDDATE,
	 C.LANGUAGE,
	 C.USEFLAG,
	 CAST(C.COUNTRYTEXT AS NVARCHAR(4000))
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

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_COUNTRYTEXT]') and xtype='U')
begin
	drop table CCImport_COUNTRYTEXT 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_COUNTRYTEXT  to public
go
