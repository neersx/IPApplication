-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_RECORDTYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_RECORDTYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_RECORDTYPE.'
	drop function dbo.fn_cc_RECORDTYPE
	print '**** Creating function dbo.fn_cc_RECORDTYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_RECORDTYPE]') and xtype='U')
begin
	select * 
	into CCImport_RECORDTYPE 
	from RECORDTYPE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_RECORDTYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_RECORDTYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the RECORDTYPE table
-- CALLED BY :	ip_CopyConfigRECORDTYPE
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
	 null as 'Imported Recordtype',
	 null as 'Imported Recordtypedesc',
'D' as '-',
	 C.RECORDTYPE as 'Recordtype',
	 C.RECORDTYPEDESC as 'Recordtypedesc'
from CCImport_RECORDTYPE I 
	right join RECORDTYPE C on( C.RECORDTYPE=I.RECORDTYPE)
where I.RECORDTYPE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.RECORDTYPE,
	 I.RECORDTYPEDESC,
'I',
	 null ,
	 null
from CCImport_RECORDTYPE I 
	left join RECORDTYPE C on( C.RECORDTYPE=I.RECORDTYPE)
where C.RECORDTYPE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.RECORDTYPE,
	 I.RECORDTYPEDESC,
'U',
	 C.RECORDTYPE,
	 C.RECORDTYPEDESC
from CCImport_RECORDTYPE I 
	join RECORDTYPE C	on ( C.RECORDTYPE=I.RECORDTYPE)
where 	( I.RECORDTYPEDESC <>  C.RECORDTYPEDESC)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_RECORDTYPE]') and xtype='U')
begin
	drop table CCImport_RECORDTYPE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_RECORDTYPE  to public
go
