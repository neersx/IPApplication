-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_DOCUMENTDEFINITION_
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_DOCUMENTDEFINITION_]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_DOCUMENTDEFINITION_.'
	drop function dbo.fn_cc_DOCUMENTDEFINITION_
	print '**** Creating function dbo.fn_cc_DOCUMENTDEFINITION_...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_DOCUMENTDEFINITIONACTINGAS]') and xtype='U')
begin
	select * 
	into CCImport_DOCUMENTDEFINITIONACTINGAS 
	from DOCUMENTDEFINITIONACTINGAS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_DOCUMENTDEFINITION_
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_DOCUMENTDEFINITION_
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the DOCUMENTDEFINITIONACTINGAS table
-- CALLED BY :	ip_CopyConfigDOCUMENTDEFINITION_
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
	 null as 'Imported Nametype',
'D' as '-',
	 C.DOCUMENTDEFID as 'Documentdefid',
	 C.NAMETYPE as 'Nametype'
from CCImport_DOCUMENTDEFINITIONACTINGAS I 
	right join DOCUMENTDEFINITIONACTINGAS C on( C.DOCUMENTDEFID=I.DOCUMENTDEFID
and  C.NAMETYPE=I.NAMETYPE)
where I.DOCUMENTDEFID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.DOCUMENTDEFID,
	 I.NAMETYPE,
'I',
	 null ,
	 null
from CCImport_DOCUMENTDEFINITIONACTINGAS I 
	left join DOCUMENTDEFINITIONACTINGAS C on( C.DOCUMENTDEFID=I.DOCUMENTDEFID
and  C.NAMETYPE=I.NAMETYPE)
where C.DOCUMENTDEFID is null

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DOCUMENTDEFINITIONACTINGAS]') and xtype='U')
begin
	drop table CCImport_DOCUMENTDEFINITIONACTINGAS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_DOCUMENTDEFINITION_  to public
go

