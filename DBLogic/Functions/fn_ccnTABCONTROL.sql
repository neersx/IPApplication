-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnTABCONTROL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnTABCONTROL]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnTABCONTROL.'
	drop function dbo.fn_ccnTABCONTROL
	print '**** Creating function dbo.fn_ccnTABCONTROL...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TABCONTROL]') and xtype='U')
begin
	select * 
	into CCImport_TABCONTROL 
	from TABCONTROL
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnTABCONTROL
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnTABCONTROL
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TABCONTROL table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'TABCONTROL' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_TABCONTROL I 
	right join TABCONTROL C on( C.TABCONTROLNO=I.TABCONTROLNO)
where I.TABCONTROLNO is null
UNION ALL 
select	6, 'TABCONTROL', 0, count(*), 0, 0
from CCImport_TABCONTROL I 
	left join TABCONTROL C on( C.TABCONTROLNO=I.TABCONTROLNO)
where C.TABCONTROLNO is null
UNION ALL 
 select	6, 'TABCONTROL', 0, 0, count(*), 0
from CCImport_TABCONTROL I 
	join TABCONTROL C	on ( C.TABCONTROLNO=I.TABCONTROLNO)
where 	( I.WINDOWCONTROLNO <>  C.WINDOWCONTROLNO)
	OR 	( I.TABNAME <>  C.TABNAME)
	OR 	( I.DISPLAYSEQUENCE <>  C.DISPLAYSEQUENCE)
	OR 	(replace( I.TABTITLE,char(10),char(13)+char(10)) <>  C.TABTITLE OR (I.TABTITLE is null and C.TABTITLE is not null) 
OR (I.TABTITLE is not null and C.TABTITLE is null))
	OR 	( I.ISINHERITED <>  C.ISINHERITED)
UNION ALL 
 select	6, 'TABCONTROL', 0, 0, 0, count(*)
from CCImport_TABCONTROL I 
join TABCONTROL C	on( C.TABCONTROLNO=I.TABCONTROLNO)
where ( I.WINDOWCONTROLNO =  C.WINDOWCONTROLNO)
and ( I.TABNAME =  C.TABNAME)
and ( I.DISPLAYSEQUENCE =  C.DISPLAYSEQUENCE)
and (replace( I.TABTITLE,char(10),char(13)+char(10)) =  C.TABTITLE OR (I.TABTITLE is null and C.TABTITLE is null))
and ( I.ISINHERITED =  C.ISINHERITED)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TABCONTROL]') and xtype='U')
begin
	drop table CCImport_TABCONTROL 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnTABCONTROL  to public
go
