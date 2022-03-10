-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_MODULEDEFINITION
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_MODULEDEFINITION]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_MODULEDEFINITION.'
	drop function dbo.fn_cc_MODULEDEFINITION
	print '**** Creating function dbo.fn_cc_MODULEDEFINITION...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_MODULEDEFINITION]') and xtype='U')
begin
	select * 
	into CCImport_MODULEDEFINITION 
	from MODULEDEFINITION
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_MODULEDEFINITION
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_MODULEDEFINITION
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the MODULEDEFINITION table
-- CALLED BY :	ip_CopyConfigMODULEDEFINITION
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
	 null as 'Imported Name',
	 null as 'Imported Desktopsrc',
	 null as 'Imported Mobilesrc',
'D' as '-',
	 C.NAME as 'Name',
	 C.DESKTOPSRC as 'Desktopsrc',
	 C.MOBILESRC as 'Mobilesrc'
from CCImport_MODULEDEFINITION I 
	right join MODULEDEFINITION C on( C.MODULEDEFID=I.MODULEDEFID)
where I.MODULEDEFID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.NAME,
	 I.DESKTOPSRC,
	 I.MOBILESRC,
'I',
	 null ,
	 null ,
	 null
from CCImport_MODULEDEFINITION I 
	left join MODULEDEFINITION C on( C.MODULEDEFID=I.MODULEDEFID)
where C.MODULEDEFID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.NAME,
	 I.DESKTOPSRC,
	 I.MOBILESRC,
'U',
	 C.NAME,
	 C.DESKTOPSRC,
	 C.MOBILESRC
from CCImport_MODULEDEFINITION I 
	join MODULEDEFINITION C	on ( C.MODULEDEFID=I.MODULEDEFID)
where 	( I.NAME <>  C.NAME)
	OR 	(replace( I.DESKTOPSRC,char(10),char(13)+char(10)) <>  C.DESKTOPSRC OR (I.DESKTOPSRC is null and C.DESKTOPSRC is not null) 
OR (I.DESKTOPSRC is not null and C.DESKTOPSRC is null))
	OR 	(replace( I.MOBILESRC,char(10),char(13)+char(10)) <>  C.MOBILESRC OR (I.MOBILESRC is null and C.MOBILESRC is not null) 
OR (I.MOBILESRC is not null and C.MOBILESRC is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_MODULEDEFINITION]') and xtype='U')
begin
	drop table CCImport_MODULEDEFINITION 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_MODULEDEFINITION  to public
go
