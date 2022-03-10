-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_SUBJECTAREA
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_SUBJECTAREA]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_SUBJECTAREA.'
	drop function dbo.fn_cc_SUBJECTAREA
	print '**** Creating function dbo.fn_cc_SUBJECTAREA...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_SUBJECTAREA]') and xtype='U')
begin
	select * 
	into CCImport_SUBJECTAREA 
	from SUBJECTAREA
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_SUBJECTAREA
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_SUBJECTAREA
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the SUBJECTAREA table
-- CALLED BY :	ip_CopyConfigSUBJECTAREA
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
	 null as 'Imported Subjectareano',
	 null as 'Imported Parenttable',
	 null as 'Imported Subjectareadesc',
'D' as '-',
	 C.SUBJECTAREANO as 'Subjectareano',
	 C.PARENTTABLE as 'Parenttable',
	 C.SUBJECTAREADESC as 'Subjectareadesc'
from CCImport_SUBJECTAREA I 
	right join SUBJECTAREA C on( C.SUBJECTAREANO=I.SUBJECTAREANO)
where I.SUBJECTAREANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.SUBJECTAREANO,
	 I.PARENTTABLE,
	 I.SUBJECTAREADESC,
'I',
	 null ,
	 null ,
	 null
from CCImport_SUBJECTAREA I 
	left join SUBJECTAREA C on( C.SUBJECTAREANO=I.SUBJECTAREANO)
where C.SUBJECTAREANO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.SUBJECTAREANO,
	 I.PARENTTABLE,
	 I.SUBJECTAREADESC,
'U',
	 C.SUBJECTAREANO,
	 C.PARENTTABLE,
	 C.SUBJECTAREADESC
from CCImport_SUBJECTAREA I 
	join SUBJECTAREA C	on ( C.SUBJECTAREANO=I.SUBJECTAREANO)
where 	( I.PARENTTABLE <>  C.PARENTTABLE OR (I.PARENTTABLE is null and C.PARENTTABLE is not null) 
OR (I.PARENTTABLE is not null and C.PARENTTABLE is null))
	OR 	(replace( I.SUBJECTAREADESC,char(10),char(13)+char(10)) <>  C.SUBJECTAREADESC)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_SUBJECTAREA]') and xtype='U')
begin
	drop table CCImport_SUBJECTAREA 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_SUBJECTAREA  to public
go
