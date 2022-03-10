-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_INSTRUCTIONS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_INSTRUCTIONS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_INSTRUCTIONS.'
	drop function dbo.fn_cc_INSTRUCTIONS
	print '**** Creating function dbo.fn_cc_INSTRUCTIONS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_INSTRUCTIONS]') and xtype='U')
begin
	select * 
	into CCImport_INSTRUCTIONS 
	from INSTRUCTIONS
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_INSTRUCTIONS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_INSTRUCTIONS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the INSTRUCTIONS table
-- CALLED BY :	ip_CopyConfigINSTRUCTIONS
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
	 null as 'Imported Instructioncode',
	 null as 'Imported Instructiontype',
	 null as 'Imported Description',
'D' as '-',
	 C.INSTRUCTIONCODE as 'Instructioncode',
	 C.INSTRUCTIONTYPE as 'Instructiontype',
	 C.DESCRIPTION as 'Description'
from CCImport_INSTRUCTIONS I 
	right join INSTRUCTIONS C on( C.INSTRUCTIONCODE=I.INSTRUCTIONCODE)
where I.INSTRUCTIONCODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.INSTRUCTIONCODE,
	 I.INSTRUCTIONTYPE,
	 I.DESCRIPTION,
'I',
	 null ,
	 null ,
	 null
from CCImport_INSTRUCTIONS I 
	left join INSTRUCTIONS C on( C.INSTRUCTIONCODE=I.INSTRUCTIONCODE)
where C.INSTRUCTIONCODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.INSTRUCTIONCODE,
	 I.INSTRUCTIONTYPE,
	 I.DESCRIPTION,
'U',
	 C.INSTRUCTIONCODE,
	 C.INSTRUCTIONTYPE,
	 C.DESCRIPTION
from CCImport_INSTRUCTIONS I 
	join INSTRUCTIONS C	on ( C.INSTRUCTIONCODE=I.INSTRUCTIONCODE)
where 	( I.INSTRUCTIONTYPE <>  C.INSTRUCTIONTYPE OR (I.INSTRUCTIONTYPE is null and C.INSTRUCTIONTYPE is not null) 
OR (I.INSTRUCTIONTYPE is not null and C.INSTRUCTIONTYPE is null))
	OR 	( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_INSTRUCTIONS]') and xtype='U')
begin
	drop table CCImport_INSTRUCTIONS 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_INSTRUCTIONS  to public
go
