-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_LANGUAGE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_LANGUAGE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_LANGUAGE.'
	drop function dbo.fn_cc_LANGUAGE
	print '**** Creating function dbo.fn_cc_LANGUAGE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_LANGUAGE]') and xtype='U')
begin
	select * 
	into CCImport_LANGUAGE 
	from LANGUAGE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_LANGUAGE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_LANGUAGE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the LANGUAGE table
-- CALLED BY :	ip_CopyConfigLANGUAGE
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
	 null as 'Imported Language_code',
	 null as 'Imported Language',
'D' as '-',
	 C.LANGUAGE_CODE as 'Language_code',
	 C.LANGUAGE as 'Language'
from CCImport_LANGUAGE I 
	right join LANGUAGE C on( C.LANGUAGE_CODE=I.LANGUAGE_CODE)
where I.LANGUAGE_CODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.LANGUAGE_CODE,
	 I.LANGUAGE,
'I',
	 null ,
	 null
from CCImport_LANGUAGE I 
	left join LANGUAGE C on( C.LANGUAGE_CODE=I.LANGUAGE_CODE)
where C.LANGUAGE_CODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.LANGUAGE_CODE,
	 I.LANGUAGE,
'U',
	 C.LANGUAGE_CODE,
	 C.LANGUAGE
from CCImport_LANGUAGE I 
	join LANGUAGE C	on ( C.LANGUAGE_CODE=I.LANGUAGE_CODE)
where 	( I.LANGUAGE <>  C.LANGUAGE)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_LANGUAGE]') and xtype='U')
begin
	drop table CCImport_LANGUAGE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_LANGUAGE  to public
go
