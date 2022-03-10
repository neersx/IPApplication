-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_INSTRUCTIONFLAG
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_INSTRUCTIONFLAG]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_INSTRUCTIONFLAG.'
	drop function dbo.fn_cc_INSTRUCTIONFLAG
	print '**** Creating function dbo.fn_cc_INSTRUCTIONFLAG...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_INSTRUCTIONFLAG]') and xtype='U')
begin
	select * 
	into CCImport_INSTRUCTIONFLAG 
	from INSTRUCTIONFLAG
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_INSTRUCTIONFLAG
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_INSTRUCTIONFLAG
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the INSTRUCTIONFLAG table
-- CALLED BY :	ip_CopyConfigINSTRUCTIONFLAG
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
	 null as 'Imported Flagnumber',
	 null as 'Imported Instructionflag',
'D' as '-',
	 C.INSTRUCTIONCODE as 'Instructioncode',
	 C.FLAGNUMBER as 'Flagnumber',
	 C.INSTRUCTIONFLAG as 'Instructionflag'
from CCImport_INSTRUCTIONFLAG I 
	right join INSTRUCTIONFLAG C on( C.INSTRUCTIONCODE=I.INSTRUCTIONCODE
and  C.FLAGNUMBER=I.FLAGNUMBER)
where I.INSTRUCTIONCODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.INSTRUCTIONCODE,
	 I.FLAGNUMBER,
	 I.INSTRUCTIONFLAG,
'I',
	 null ,
	 null ,
	 null
from CCImport_INSTRUCTIONFLAG I 
	left join INSTRUCTIONFLAG C on( C.INSTRUCTIONCODE=I.INSTRUCTIONCODE
and  C.FLAGNUMBER=I.FLAGNUMBER)
where C.INSTRUCTIONCODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.INSTRUCTIONCODE,
	 I.FLAGNUMBER,
	 I.INSTRUCTIONFLAG,
'U',
	 C.INSTRUCTIONCODE,
	 C.FLAGNUMBER,
	 C.INSTRUCTIONFLAG
from CCImport_INSTRUCTIONFLAG I 
	join INSTRUCTIONFLAG C	on ( C.INSTRUCTIONCODE=I.INSTRUCTIONCODE
	and C.FLAGNUMBER=I.FLAGNUMBER)
where 	( I.INSTRUCTIONFLAG <>  C.INSTRUCTIONFLAG OR (I.INSTRUCTIONFLAG is null and C.INSTRUCTIONFLAG is not null) 
OR (I.INSTRUCTIONFLAG is not null and C.INSTRUCTIONFLAG is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_INSTRUCTIONFLAG]') and xtype='U')
begin
	drop table CCImport_INSTRUCTIONFLAG 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_INSTRUCTIONFLAG  to public
go
