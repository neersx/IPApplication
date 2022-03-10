-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_DOCUMENT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_DOCUMENT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_DOCUMENT.'
	drop function dbo.fn_cc_DOCUMENT
	print '**** Creating function dbo.fn_cc_DOCUMENT...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_DOCUMENT]') and xtype='U')
begin
	select * 
	into CCImport_DOCUMENT 
	from DOCUMENT
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_DOCUMENT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_DOCUMENT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the DOCUMENT table
-- CALLED BY :	ip_CopyConfigDOCUMENT
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
	 null as 'Imported Documentno',
	 null as 'Imported Docdescription',
'D' as '-',
	 C.DOCUMENTNO as 'Documentno',
	 C.DOCDESCRIPTION as 'Docdescription'
from CCImport_DOCUMENT I 
	right join DOCUMENT C on( C.DOCUMENTNO=I.DOCUMENTNO)
where I.DOCUMENTNO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.DOCUMENTNO,
	 I.DOCDESCRIPTION,
'I',
	 null ,
	 null
from CCImport_DOCUMENT I 
	left join DOCUMENT C on( C.DOCUMENTNO=I.DOCUMENTNO)
where C.DOCUMENTNO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.DOCUMENTNO,
	 I.DOCDESCRIPTION,
'U',
	 C.DOCUMENTNO,
	 C.DOCDESCRIPTION
from CCImport_DOCUMENT I 
	join DOCUMENT C	on ( C.DOCUMENTNO=I.DOCUMENTNO)
where 	( I.DOCDESCRIPTION <>  C.DOCDESCRIPTION OR (I.DOCDESCRIPTION is null and C.DOCDESCRIPTION is not null) 
OR (I.DOCDESCRIPTION is not null and C.DOCDESCRIPTION is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DOCUMENT]') and xtype='U')
begin
	drop table CCImport_DOCUMENT 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_DOCUMENT  to public
go
