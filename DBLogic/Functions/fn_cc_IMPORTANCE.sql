-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_IMPORTANCE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_IMPORTANCE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_IMPORTANCE.'
	drop function dbo.fn_cc_IMPORTANCE
	print '**** Creating function dbo.fn_cc_IMPORTANCE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_IMPORTANCE]') and xtype='U')
begin
	select * 
	into CCImport_IMPORTANCE 
	from IMPORTANCE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_IMPORTANCE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_IMPORTANCE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the IMPORTANCE table
-- CALLED BY :	ip_CopyConfigIMPORTANCE
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
	 null as 'Imported Importancelevel',
	 null as 'Imported Importancedesc',
'D' as '-',
	 C.IMPORTANCELEVEL as 'Importancelevel',
	 C.IMPORTANCEDESC as 'Importancedesc'
from CCImport_IMPORTANCE I 
	right join IMPORTANCE C on( C.IMPORTANCELEVEL=I.IMPORTANCELEVEL)
where I.IMPORTANCELEVEL is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.IMPORTANCELEVEL,
	 I.IMPORTANCEDESC,
'I',
	 null ,
	 null
from CCImport_IMPORTANCE I 
	left join IMPORTANCE C on( C.IMPORTANCELEVEL=I.IMPORTANCELEVEL)
where C.IMPORTANCELEVEL is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.IMPORTANCELEVEL,
	 I.IMPORTANCEDESC,
'U',
	 C.IMPORTANCELEVEL,
	 C.IMPORTANCEDESC
from CCImport_IMPORTANCE I 
	join IMPORTANCE C	on ( C.IMPORTANCELEVEL=I.IMPORTANCELEVEL)
where 	( I.IMPORTANCEDESC <>  C.IMPORTANCEDESC OR (I.IMPORTANCEDESC is null and C.IMPORTANCEDESC is not null) 
OR (I.IMPORTANCEDESC is not null and C.IMPORTANCEDESC is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_IMPORTANCE]') and xtype='U')
begin
	drop table CCImport_IMPORTANCE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_IMPORTANCE  to public
go
