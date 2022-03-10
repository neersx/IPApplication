-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_TABCONTROL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_TABCONTROL]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_TABCONTROL.'
	drop function dbo.fn_cc_TABCONTROL
	print '**** Creating function dbo.fn_cc_TABCONTROL...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TABCONTROL]') and xtype='U')
begin
	select * 
	into CCImport_TABCONTROL 
	from TABCONTROL
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_TABCONTROL
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_TABCONTROL
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TABCONTROL table
-- CALLED BY :	ip_CopyConfigTABCONTROL
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
	 null as 'Imported Windowcontrolno',
	 null as 'Imported Tabname',
	 null as 'Imported Displaysequence',
	 null as 'Imported Tabtitle',
	 null as 'Imported Isinherited',
'D' as '-',
	 C.WINDOWCONTROLNO as 'Windowcontrolno',
	 C.TABNAME as 'Tabname',
	 C.DISPLAYSEQUENCE as 'Displaysequence',
	 C.TABTITLE as 'Tabtitle',
	 C.ISINHERITED as 'Isinherited'
from CCImport_TABCONTROL I 
	right join TABCONTROL C on( C.TABCONTROLNO=I.TABCONTROLNO)
where I.TABCONTROLNO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.WINDOWCONTROLNO,
	 I.TABNAME,
	 I.DISPLAYSEQUENCE,
	 I.TABTITLE,
	 I.ISINHERITED,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_TABCONTROL I 
	left join TABCONTROL C on( C.TABCONTROLNO=I.TABCONTROLNO)
where C.TABCONTROLNO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.WINDOWCONTROLNO,
	 I.TABNAME,
	 I.DISPLAYSEQUENCE,
	 I.TABTITLE,
	 I.ISINHERITED,
'U',
	 C.WINDOWCONTROLNO,
	 C.TABNAME,
	 C.DISPLAYSEQUENCE,
	 C.TABTITLE,
	 C.ISINHERITED
from CCImport_TABCONTROL I 
	join TABCONTROL C	on ( C.TABCONTROLNO=I.TABCONTROLNO)
where 	( I.WINDOWCONTROLNO <>  C.WINDOWCONTROLNO)
	OR 	( I.TABNAME <>  C.TABNAME)
	OR 	( I.DISPLAYSEQUENCE <>  C.DISPLAYSEQUENCE)
	OR 	(replace( I.TABTITLE,char(10),char(13)+char(10)) <>  C.TABTITLE OR (I.TABTITLE is null and C.TABTITLE is not null) 
OR (I.TABTITLE is not null and C.TABTITLE is null))
	OR 	( I.ISINHERITED <>  C.ISINHERITED)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TABCONTROL]') and xtype='U')
begin
	drop table CCImport_TABCONTROL 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_TABCONTROL  to public
go
