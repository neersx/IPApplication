-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_SUBJECTAREATABLES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_SUBJECTAREATABLES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_SUBJECTAREATABLES.'
	drop function dbo.fn_cc_SUBJECTAREATABLES
	print '**** Creating function dbo.fn_cc_SUBJECTAREATABLES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_SUBJECTAREATABLES]') and xtype='U')
begin
	select * 
	into CCImport_SUBJECTAREATABLES 
	from SUBJECTAREATABLES
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_SUBJECTAREATABLES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_SUBJECTAREATABLES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the SUBJECTAREATABLES table
-- CALLED BY :	ip_CopyConfigSUBJECTAREATABLES
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
	 null as 'Imported Tablename',
	 null as 'Imported Depth',
'D' as '-',
	 C.SUBJECTAREANO as 'Subjectareano',
	 C.TABLENAME as 'Tablename',
	 C.DEPTH as 'Depth'
from CCImport_SUBJECTAREATABLES I 
	right join SUBJECTAREATABLES C on( C.SUBJECTAREANO=I.SUBJECTAREANO
and  C.TABLENAME=I.TABLENAME)
where I.SUBJECTAREANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.SUBJECTAREANO,
	 I.TABLENAME,
	 I.DEPTH,
'I',
	 null ,
	 null ,
	 null
from CCImport_SUBJECTAREATABLES I 
	left join SUBJECTAREATABLES C on( C.SUBJECTAREANO=I.SUBJECTAREANO
and  C.TABLENAME=I.TABLENAME)
where C.SUBJECTAREANO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.SUBJECTAREANO,
	 I.TABLENAME,
	 I.DEPTH,
'U',
	 C.SUBJECTAREANO,
	 C.TABLENAME,
	 C.DEPTH
from CCImport_SUBJECTAREATABLES I 
	join SUBJECTAREATABLES C	on ( C.SUBJECTAREANO=I.SUBJECTAREANO
	and C.TABLENAME=I.TABLENAME)
where 	( I.DEPTH <>  C.DEPTH)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_SUBJECTAREATABLES]') and xtype='U')
begin
	drop table CCImport_SUBJECTAREATABLES 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_SUBJECTAREATABLES  to public
go
