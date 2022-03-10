-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_PROFILEPROGRAM
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_PROFILEPROGRAM]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_PROFILEPROGRAM.'
	drop function dbo.fn_cc_PROFILEPROGRAM
	print '**** Creating function dbo.fn_cc_PROFILEPROGRAM...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PROFILEPROGRAM]') and xtype='U')
begin
	select * 
	into CCImport_PROFILEPROGRAM 
	from PROFILEPROGRAM
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_PROFILEPROGRAM
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_PROFILEPROGRAM
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PROFILEPROGRAM table
-- CALLED BY :	ip_CopyConfigPROFILEPROGRAM
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
	 null as 'Imported Profileid',
	 null as 'Imported Programid',
'D' as '-',
	 C.PROFILEID as 'Profileid',
	 C.PROGRAMID as 'Programid'
from CCImport_PROFILEPROGRAM I 
	right join PROFILEPROGRAM C on( C.PROFILEID=I.PROFILEID
and  C.PROGRAMID=I.PROGRAMID)
where I.PROFILEID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.PROFILEID,
	 I.PROGRAMID,
'I',
	 null ,
	 null
from CCImport_PROFILEPROGRAM I 
	left join PROFILEPROGRAM C on( C.PROFILEID=I.PROFILEID
and  C.PROGRAMID=I.PROGRAMID)
where C.PROFILEID is null

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PROFILEPROGRAM]') and xtype='U')
begin
	drop table CCImport_PROFILEPROGRAM 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_PROFILEPROGRAM  to public
go
