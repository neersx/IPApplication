-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_INSTRUCTIONLABEL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_INSTRUCTIONLABEL]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_INSTRUCTIONLABEL.'
	drop function dbo.fn_cc_INSTRUCTIONLABEL
	print '**** Creating function dbo.fn_cc_INSTRUCTIONLABEL...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_INSTRUCTIONLABEL]') and xtype='U')
begin
	select * 
	into CCImport_INSTRUCTIONLABEL 
	from INSTRUCTIONLABEL
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_INSTRUCTIONLABEL
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_INSTRUCTIONLABEL
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the INSTRUCTIONLABEL table
-- CALLED BY :	ip_CopyConfigINSTRUCTIONLABEL
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
	 null as 'Imported Flagnumber',
	 null as 'Imported Flagliteral',
'D' as '-',
	 C.INSTRUCTIONTYPE as 'Instructiontype',
	 C.FLAGNUMBER as 'Flagnumber',
	 C.FLAGLITERAL as 'Flagliteral'
from CCImport_INSTRUCTIONLABEL I 
	right join INSTRUCTIONLABEL C on( C.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE
and  C.FLAGNUMBER=I.FLAGNUMBER)
where I.INSTRUCTIONTYPE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.INSTRUCTIONTYPE,
	 I.FLAGNUMBER,
	 I.FLAGLITERAL,
'I',
	 null ,
	 null ,
	 null
from CCImport_INSTRUCTIONLABEL I 
	left join INSTRUCTIONLABEL C on( C.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE
and  C.FLAGNUMBER=I.FLAGNUMBER)
where C.INSTRUCTIONTYPE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.INSTRUCTIONTYPE,
	 I.FLAGNUMBER,
	 I.FLAGLITERAL,
'U',
	 C.INSTRUCTIONTYPE,
	 C.FLAGNUMBER,
	 C.FLAGLITERAL
from CCImport_INSTRUCTIONLABEL I 
	join INSTRUCTIONLABEL C	on ( C.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE
	and C.FLAGNUMBER=I.FLAGNUMBER)
where 	( I.FLAGLITERAL <>  C.FLAGLITERAL OR (I.FLAGLITERAL is null and C.FLAGLITERAL is not null) 
OR (I.FLAGLITERAL is not null and C.FLAGLITERAL is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_INSTRUCTIONLABEL]') and xtype='U')
begin
	drop table CCImport_INSTRUCTIONLABEL 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_INSTRUCTIONLABEL  to public
go
