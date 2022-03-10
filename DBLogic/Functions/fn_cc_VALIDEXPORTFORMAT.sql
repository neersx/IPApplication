-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_VALIDEXPORTFORMAT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_VALIDEXPORTFORMAT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_VALIDEXPORTFORMAT.'
	drop function dbo.fn_cc_VALIDEXPORTFORMAT
	print '**** Creating function dbo.fn_cc_VALIDEXPORTFORMAT...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDEXPORTFORMAT]') and xtype='U')
begin
	select * 
	into CCImport_VALIDEXPORTFORMAT 
	from VALIDEXPORTFORMAT
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_VALIDEXPORTFORMAT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_VALIDEXPORTFORMAT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the VALIDEXPORTFORMAT table
-- CALLED BY :	ip_CopyConfigVALIDEXPORTFORMAT
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
	 null as 'Imported Documentdefid',
	 null as 'Imported Formatid',
	 null as 'Imported Isdefault',
'D' as '-',
	 C.DOCUMENTDEFID as 'Documentdefid',
	 C.FORMATID as 'Formatid',
	 C.ISDEFAULT as 'Isdefault'
from CCImport_VALIDEXPORTFORMAT I 
	right join VALIDEXPORTFORMAT C on( C.DOCUMENTDEFID=I.DOCUMENTDEFID
and  C.FORMATID=I.FORMATID)
where I.DOCUMENTDEFID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.DOCUMENTDEFID,
	 I.FORMATID,
	 I.ISDEFAULT,
'I',
	 null ,
	 null ,
	 null
from CCImport_VALIDEXPORTFORMAT I 
	left join VALIDEXPORTFORMAT C on( C.DOCUMENTDEFID=I.DOCUMENTDEFID
and  C.FORMATID=I.FORMATID)
where C.DOCUMENTDEFID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.DOCUMENTDEFID,
	 I.FORMATID,
	 I.ISDEFAULT,
'U',
	 C.DOCUMENTDEFID,
	 C.FORMATID,
	 C.ISDEFAULT
from CCImport_VALIDEXPORTFORMAT I 
	join VALIDEXPORTFORMAT C	on ( C.DOCUMENTDEFID=I.DOCUMENTDEFID
	and C.FORMATID=I.FORMATID)
where 	( I.ISDEFAULT <>  C.ISDEFAULT)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDEXPORTFORMAT]') and xtype='U')
begin
	drop table CCImport_VALIDEXPORTFORMAT 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_VALIDEXPORTFORMAT  to public
go
