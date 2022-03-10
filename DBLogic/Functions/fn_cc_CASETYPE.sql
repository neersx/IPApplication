-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_CASETYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_CASETYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_CASETYPE.'
	drop function dbo.fn_cc_CASETYPE
	print '**** Creating function dbo.fn_cc_CASETYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_CASETYPE]') and xtype='U')
begin
	select * 
	into CCImport_CASETYPE 
	from CASETYPE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_CASETYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_CASETYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CASETYPE table
-- CALLED BY :	ip_CopyConfigCASETYPE
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
	 null as 'Imported Casetype',
	 null as 'Imported Casetypedesc',
	 null as 'Imported Actualcasetype',
	 null as 'Imported Crmonly',
	 null as 'Imported Kottexttype',
	 null as 'Imported Program',
'D' as '-',
	 C.CASETYPE as 'Casetype',
	 C.CASETYPEDESC as 'Casetypedesc',
	 C.ACTUALCASETYPE as 'Actualcasetype',
	 C.CRMONLY as 'Crmonly',
	 C.KOTTEXTTYPE as 'Kottexttype',
	 C.PROGRAM as 'Program'
from CCImport_CASETYPE I 
	right join CASETYPE C on( C.CASETYPE=I.CASETYPE)
where I.CASETYPE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CASETYPE,
	 I.CASETYPEDESC,
	 I.ACTUALCASETYPE,
	 I.CRMONLY,
	 I.KOTTEXTTYPE,
	 I.PROGRAM,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_CASETYPE I 
	left join CASETYPE C on( C.CASETYPE=I.CASETYPE)
where C.CASETYPE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CASETYPE,
	 I.CASETYPEDESC,
	 I.ACTUALCASETYPE,
	 I.CRMONLY,
	 I.KOTTEXTTYPE,
	 I.PROGRAM,
'U',
	 C.CASETYPE,
	 C.CASETYPEDESC,
	 C.ACTUALCASETYPE,
	 C.CRMONLY,
	 C.KOTTEXTTYPE,
	 C.PROGRAM
from CCImport_CASETYPE I 
	join CASETYPE C	on ( C.CASETYPE=I.CASETYPE)
where 	( I.CASETYPEDESC <>  C.CASETYPEDESC OR (I.CASETYPEDESC is null and C.CASETYPEDESC is not null) 
OR (I.CASETYPEDESC is not null and C.CASETYPEDESC is null))
	OR 	( I.ACTUALCASETYPE <>  C.ACTUALCASETYPE OR (I.ACTUALCASETYPE is null and C.ACTUALCASETYPE is not null) 
OR (I.ACTUALCASETYPE is not null and C.ACTUALCASETYPE is null))
	OR 	( I.CRMONLY <>  C.CRMONLY OR (I.CRMONLY is null and C.CRMONLY is not null) 
OR (I.CRMONLY is not null and C.CRMONLY is null))
	OR 	( I.KOTTEXTTYPE <>  C.KOTTEXTTYPE OR (I.KOTTEXTTYPE is null and C.KOTTEXTTYPE is not null) 
OR (I.KOTTEXTTYPE is not null and C.KOTTEXTTYPE is null))
	OR 	( I.PROGRAM <>  C.PROGRAM OR (I.PROGRAM is null and C.PROGRAM is not null) 
OR (I.PROGRAM is not null and C.PROGRAM is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CASETYPE]') and xtype='U')
begin
	drop table CCImport_CASETYPE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_CASETYPE  to public
go
