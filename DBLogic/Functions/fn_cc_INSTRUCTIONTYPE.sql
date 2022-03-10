-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_INSTRUCTIONTYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_INSTRUCTIONTYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_INSTRUCTIONTYPE.'
	drop function dbo.fn_cc_INSTRUCTIONTYPE
	print '**** Creating function dbo.fn_cc_INSTRUCTIONTYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_INSTRUCTIONTYPE]') and xtype='U')
begin
	select * 
	into CCImport_INSTRUCTIONTYPE 
	from INSTRUCTIONTYPE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_INSTRUCTIONTYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_INSTRUCTIONTYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the INSTRUCTIONTYPE table
-- CALLED BY :	ip_CopyConfigINSTRUCTIONTYPE
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
	 null as 'Imported Instructiontype',
	 null as 'Imported Nametype',
	 null as 'Imported Instrtypedesc',
	 null as 'Imported Restrictedbytype',
'D' as '-',
	 C.INSTRUCTIONTYPE as 'Instructiontype',
	 C.NAMETYPE as 'Nametype',
	 C.INSTRTYPEDESC as 'Instrtypedesc',
	 C.RESTRICTEDBYTYPE as 'Restrictedbytype'
from CCImport_INSTRUCTIONTYPE I 
	right join INSTRUCTIONTYPE C on( C.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE)
where I.INSTRUCTIONTYPE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.INSTRUCTIONTYPE,
	 I.NAMETYPE,
	 I.INSTRTYPEDESC,
	 I.RESTRICTEDBYTYPE,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_INSTRUCTIONTYPE I 
	left join INSTRUCTIONTYPE C on( C.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE)
where C.INSTRUCTIONTYPE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.INSTRUCTIONTYPE,
	 I.NAMETYPE,
	 I.INSTRTYPEDESC,
	 I.RESTRICTEDBYTYPE,
'U',
	 C.INSTRUCTIONTYPE,
	 C.NAMETYPE,
	 C.INSTRTYPEDESC,
	 C.RESTRICTEDBYTYPE
from CCImport_INSTRUCTIONTYPE I 
	join INSTRUCTIONTYPE C	on ( C.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE)
where 	( I.NAMETYPE <>  C.NAMETYPE)
	OR 	( I.INSTRTYPEDESC <>  C.INSTRTYPEDESC OR (I.INSTRTYPEDESC is null and C.INSTRTYPEDESC is not null) 
OR (I.INSTRTYPEDESC is not null and C.INSTRTYPEDESC is null))
	OR 	( I.RESTRICTEDBYTYPE <>  C.RESTRICTEDBYTYPE OR (I.RESTRICTEDBYTYPE is null and C.RESTRICTEDBYTYPE is not null) 
OR (I.RESTRICTEDBYTYPE is not null and C.RESTRICTEDBYTYPE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_INSTRUCTIONTYPE]') and xtype='U')
begin
	drop table CCImport_INSTRUCTIONTYPE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_INSTRUCTIONTYPE  to public
go
