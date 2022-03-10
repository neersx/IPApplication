-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_APPLICATIONBASIS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_APPLICATIONBASIS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_APPLICATIONBASIS.'
	drop function dbo.fn_cc_APPLICATIONBASIS
	print '**** Creating function dbo.fn_cc_APPLICATIONBASIS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_APPLICATIONBASIS]') and xtype='U')
begin
	select * 
	into CCImport_APPLICATIONBASIS 
	from APPLICATIONBASIS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_APPLICATIONBASIS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_APPLICATIONBASIS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the APPLICATIONBASIS table
-- CALLED BY :	ip_CopyConfigAPPLICATIONBASIS
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
	 null as 'Imported Basis',
	 null as 'Imported Basisdescription',
	 null as 'Imported Convention',
'D' as '-',
	 C.BASIS as 'Basis',
	 C.BASISDESCRIPTION as 'Basisdescription',
	 C.CONVENTION as 'Convention'
from CCImport_APPLICATIONBASIS I 
	right join APPLICATIONBASIS C on( C.BASIS=I.BASIS)
where I.BASIS is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.BASIS,
	 I.BASISDESCRIPTION,
	 I.CONVENTION,
'I',
	 null ,
	 null ,
	 null
from CCImport_APPLICATIONBASIS I 
	left join APPLICATIONBASIS C on( C.BASIS=I.BASIS)
where C.BASIS is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.BASIS,
	 I.BASISDESCRIPTION,
	 I.CONVENTION,
'U',
	 C.BASIS,
	 C.BASISDESCRIPTION,
	 C.CONVENTION
from CCImport_APPLICATIONBASIS I 
	join APPLICATIONBASIS C	on ( C.BASIS=I.BASIS)
where 	( I.BASISDESCRIPTION <>  C.BASISDESCRIPTION OR (I.BASISDESCRIPTION is null and C.BASISDESCRIPTION is not null) 
OR (I.BASISDESCRIPTION is not null and C.BASISDESCRIPTION is null))
	OR 	( I.CONVENTION <>  C.CONVENTION OR (I.CONVENTION is null and C.CONVENTION is not null) 
OR (I.CONVENTION is not null and C.CONVENTION is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_APPLICATIONBASIS]') and xtype='U')
begin
	drop table CCImport_APPLICATIONBASIS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_APPLICATIONBASIS  to public
go

