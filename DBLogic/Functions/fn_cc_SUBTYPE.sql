-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_SUBTYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_SUBTYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_SUBTYPE.'
	drop function dbo.fn_cc_SUBTYPE
	print '**** Creating function dbo.fn_cc_SUBTYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_SUBTYPE]') and xtype='U')
begin
	select * 
	into CCImport_SUBTYPE 
	from SUBTYPE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_SUBTYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_SUBTYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the SUBTYPE table
-- CALLED BY :	ip_CopyConfigSUBTYPE
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
	 null as 'Imported Subtype',
	 null as 'Imported Subtypedesc',
'D' as '-',
	 C.SUBTYPE as 'Subtype',
	 C.SUBTYPEDESC as 'Subtypedesc'
from CCImport_SUBTYPE I 
	right join SUBTYPE C on( C.SUBTYPE=I.SUBTYPE)
where I.SUBTYPE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.SUBTYPE,
	 I.SUBTYPEDESC,
'I',
	 null ,
	 null
from CCImport_SUBTYPE I 
	left join SUBTYPE C on( C.SUBTYPE=I.SUBTYPE)
where C.SUBTYPE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.SUBTYPE,
	 I.SUBTYPEDESC,
'U',
	 C.SUBTYPE,
	 C.SUBTYPEDESC
from CCImport_SUBTYPE I 
	join SUBTYPE C	on ( C.SUBTYPE=I.SUBTYPE)
where 	( I.SUBTYPEDESC <>  C.SUBTYPEDESC OR (I.SUBTYPEDESC is null and C.SUBTYPEDESC is not null) 
OR (I.SUBTYPEDESC is not null and C.SUBTYPEDESC is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_SUBTYPE]') and xtype='U')
begin
	drop table CCImport_SUBTYPE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_SUBTYPE  to public
go
