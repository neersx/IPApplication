-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnWINDOWCONTROL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnWINDOWCONTROL]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnWINDOWCONTROL.'
	drop function dbo.fn_ccnWINDOWCONTROL
	print '**** Creating function dbo.fn_ccnWINDOWCONTROL...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_WINDOWCONTROL]') and xtype='U')
begin
	select * 
	into CCImport_WINDOWCONTROL 
	from WINDOWCONTROL
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnWINDOWCONTROL
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnWINDOWCONTROL
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the WINDOWCONTROL table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'WINDOWCONTROL' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_WINDOWCONTROL I 
	right join WINDOWCONTROL C on( C.WINDOWCONTROLNO=I.WINDOWCONTROLNO)
where I.WINDOWCONTROLNO is null
UNION ALL 
select	6, 'WINDOWCONTROL', 0, count(*), 0, 0
from CCImport_WINDOWCONTROL I 
	left join WINDOWCONTROL C on( C.WINDOWCONTROLNO=I.WINDOWCONTROLNO)
where C.WINDOWCONTROLNO is null
UNION ALL 
 select	6, 'WINDOWCONTROL', 0, 0, count(*), 0
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
UNION ALL 
 select	6, 'WINDOWCONTROL', 0, 0, 0, count(*)
from CCImport_WINDOWCONTROL I 
join WINDOWCONTROL C	on( C.WINDOWCONTROLNO=I.WINDOWCONTROLNO)
where ( I.CRITERIANO =  C.CRITERIANO OR (I.CRITERIANO is null and C.CRITERIANO is null))
and ( I.NAMECRITERIANO =  C.NAMECRITERIANO OR (I.NAMECRITERIANO is null and C.NAMECRITERIANO is null))
and ( I.WINDOWNAME =  C.WINDOWNAME)
and ( I.ISEXTERNAL =  C.ISEXTERNAL)
and ( I.DISPLAYSEQUENCE =  C.DISPLAYSEQUENCE OR (I.DISPLAYSEQUENCE is null and C.DISPLAYSEQUENCE is null))
and (replace( I.WINDOWTITLE,char(10),char(13)+char(10)) =  C.WINDOWTITLE OR (I.WINDOWTITLE is null and C.WINDOWTITLE is null))
and (replace( I.WINDOWSHORTTITLE,char(10),char(13)+char(10)) =  C.WINDOWSHORTTITLE OR (I.WINDOWSHORTTITLE is null and C.WINDOWSHORTTITLE is null))
and ( I.ENTRYNUMBER =  C.ENTRYNUMBER OR (I.ENTRYNUMBER is null and C.ENTRYNUMBER is null))
and ( I.THEME =  C.THEME OR (I.THEME is null and C.THEME is null))
and ( I.ISINHERITED =  C.ISINHERITED)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_WINDOWCONTROL]') and xtype='U')
begin
	drop table CCImport_WINDOWCONTROL 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnWINDOWCONTROL  to public
go
