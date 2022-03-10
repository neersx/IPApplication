-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_WINDOWCONTROL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_WINDOWCONTROL]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_WINDOWCONTROL.'
	drop function dbo.fn_cc_WINDOWCONTROL
	print '**** Creating function dbo.fn_cc_WINDOWCONTROL...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_WINDOWCONTROL]') and xtype='U')
begin
	select * 
	into CCImport_WINDOWCONTROL 
	from WINDOWCONTROL
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_WINDOWCONTROL
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_WINDOWCONTROL
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the WINDOWCONTROL table
-- CALLED BY :	ip_CopyConfigWINDOWCONTROL
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
	 null as 'Imported Criteriano',
	 null as 'Imported Namecriteriano',
	 null as 'Imported Windowname',
	 null as 'Imported Isexternal',
	 null as 'Imported Displaysequence',
	 null as 'Imported Windowtitle',
	 null as 'Imported Windowshorttitle',
	 null as 'Imported Entrynumber',
	 null as 'Imported Theme',
	 null as 'Imported Isinherited',
'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.NAMECRITERIANO as 'Namecriteriano',
	 C.WINDOWNAME as 'Windowname',
	 C.ISEXTERNAL as 'Isexternal',
	 C.DISPLAYSEQUENCE as 'Displaysequence',
	 C.WINDOWTITLE as 'Windowtitle',
	 C.WINDOWSHORTTITLE as 'Windowshorttitle',
	 C.ENTRYNUMBER as 'Entrynumber',
	 C.THEME as 'Theme',
	 C.ISINHERITED as 'Isinherited'
from CCImport_WINDOWCONTROL I 
	right join WINDOWCONTROL C on( C.WINDOWCONTROLNO=I.WINDOWCONTROLNO)
where I.WINDOWCONTROLNO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.NAMECRITERIANO,
	 I.WINDOWNAME,
	 I.ISEXTERNAL,
	 I.DISPLAYSEQUENCE,
	 I.WINDOWTITLE,
	 I.WINDOWSHORTTITLE,
	 I.ENTRYNUMBER,
	 I.THEME,
	 I.ISINHERITED,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_WINDOWCONTROL I 
	left join WINDOWCONTROL C on( C.WINDOWCONTROLNO=I.WINDOWCONTROLNO)
where C.WINDOWCONTROLNO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIANO,
	 I.NAMECRITERIANO,
	 I.WINDOWNAME,
	 I.ISEXTERNAL,
	 I.DISPLAYSEQUENCE,
	 I.WINDOWTITLE,
	 I.WINDOWSHORTTITLE,
	 I.ENTRYNUMBER,
	 I.THEME,
	 I.ISINHERITED,
'U',
	 C.CRITERIANO,
	 C.NAMECRITERIANO,
	 C.WINDOWNAME,
	 C.ISEXTERNAL,
	 C.DISPLAYSEQUENCE,
	 C.WINDOWTITLE,
	 C.WINDOWSHORTTITLE,
	 C.ENTRYNUMBER,
	 C.THEME,
	 C.ISINHERITED
from CCImport_WINDOWCONTROL I 
	join WINDOWCONTROL C	on ( C.WINDOWCONTROLNO=I.WINDOWCONTROLNO)
where 	( I.CRITERIANO <>  C.CRITERIANO OR (I.CRITERIANO is null and C.CRITERIANO is not null) 
OR (I.CRITERIANO is not null and C.CRITERIANO is null))
	OR 	( I.NAMECRITERIANO <>  C.NAMECRITERIANO OR (I.NAMECRITERIANO is null and C.NAMECRITERIANO is not null) 
OR (I.NAMECRITERIANO is not null and C.NAMECRITERIANO is null))
	OR 	( I.WINDOWNAME <>  C.WINDOWNAME)
	OR 	( I.ISEXTERNAL <>  C.ISEXTERNAL)
	OR 	( I.DISPLAYSEQUENCE <>  C.DISPLAYSEQUENCE OR (I.DISPLAYSEQUENCE is null and C.DISPLAYSEQUENCE is not null) 
OR (I.DISPLAYSEQUENCE is not null and C.DISPLAYSEQUENCE is null))
	OR 	(replace( I.WINDOWTITLE,char(10),char(13)+char(10)) <>  C.WINDOWTITLE OR (I.WINDOWTITLE is null and C.WINDOWTITLE is not null) 
OR (I.WINDOWTITLE is not null and C.WINDOWTITLE is null))
	OR 	(replace( I.WINDOWSHORTTITLE,char(10),char(13)+char(10)) <>  C.WINDOWSHORTTITLE OR (I.WINDOWSHORTTITLE is null and C.WINDOWSHORTTITLE is not null) 
OR (I.WINDOWSHORTTITLE is not null and C.WINDOWSHORTTITLE is null))
	OR 	( I.ENTRYNUMBER <>  C.ENTRYNUMBER OR (I.ENTRYNUMBER is null and C.ENTRYNUMBER is not null) 
OR (I.ENTRYNUMBER is not null and C.ENTRYNUMBER is null))
	OR 	( I.THEME <>  C.THEME OR (I.THEME is null and C.THEME is not null) 
OR (I.THEME is not null and C.THEME is null))
	OR 	( I.ISINHERITED <>  C.ISINHERITED)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_WINDOWCONTROL]') and xtype='U')
begin
	drop table CCImport_WINDOWCONTROL 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_WINDOWCONTROL  to public
go
