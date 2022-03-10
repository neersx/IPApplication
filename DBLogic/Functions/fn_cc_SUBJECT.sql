-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_SUBJECT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_SUBJECT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_SUBJECT.'
	drop function dbo.fn_cc_SUBJECT
	print '**** Creating function dbo.fn_cc_SUBJECT...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_SUBJECT]') and xtype='U')
begin
	select * 
	into CCImport_SUBJECT 
	from SUBJECT
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_SUBJECT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_SUBJECT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the SUBJECT table
-- CALLED BY :	ip_CopyConfigSUBJECT
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
	 null as 'Imported Subjectcode',
	 null as 'Imported Subjectname',
'D' as '-',
	 C.SUBJECTCODE as 'Subjectcode',
	 C.SUBJECTNAME as 'Subjectname'
from CCImport_SUBJECT I 
	right join SUBJECT C on( C.SUBJECTCODE=I.SUBJECTCODE)
where I.SUBJECTCODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.SUBJECTCODE,
	 I.SUBJECTNAME,
'I',
	 null ,
	 null
from CCImport_SUBJECT I 
	left join SUBJECT C on( C.SUBJECTCODE=I.SUBJECTCODE)
where C.SUBJECTCODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.SUBJECTCODE,
	 I.SUBJECTNAME,
'U',
	 C.SUBJECTCODE,
	 C.SUBJECTNAME
from CCImport_SUBJECT I 
	join SUBJECT C	on ( C.SUBJECTCODE=I.SUBJECTCODE)
where 	( I.SUBJECTNAME <>  C.SUBJECTNAME)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_SUBJECT]') and xtype='U')
begin
	drop table CCImport_SUBJECT 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_SUBJECT  to public
go
