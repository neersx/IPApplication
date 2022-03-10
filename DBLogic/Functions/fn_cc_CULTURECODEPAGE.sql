-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_CULTURECODEPAGE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_CULTURECODEPAGE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_CULTURECODEPAGE.'
	drop function dbo.fn_cc_CULTURECODEPAGE
	print '**** Creating function dbo.fn_cc_CULTURECODEPAGE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_CULTURECODEPAGE]') and xtype='U')
begin
	select * 
	into CCImport_CULTURECODEPAGE 
	from CULTURECODEPAGE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_CULTURECODEPAGE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_CULTURECODEPAGE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CULTURECODEPAGE table
-- CALLED BY :	ip_CopyConfigCULTURECODEPAGE
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
	 null as 'Imported Codepage',
	 null as 'Imported Culture',
'D' as '-',
	 C.CODEPAGE as 'Codepage',
	 C.CULTURE as 'Culture'
from CCImport_CULTURECODEPAGE I 
	right join CULTURECODEPAGE C on( C.CODEPAGE=I.CODEPAGE
and  C.CULTURE=I.CULTURE)
where I.CODEPAGE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CODEPAGE,
	 I.CULTURE,
'I',
	 null ,
	 null
from CCImport_CULTURECODEPAGE I 
	left join CULTURECODEPAGE C on( C.CODEPAGE=I.CODEPAGE
and  C.CULTURE=I.CULTURE)
where C.CODEPAGE is null

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CULTURECODEPAGE]') and xtype='U')
begin
	drop table CCImport_CULTURECODEPAGE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_CULTURECODEPAGE  to public
go
