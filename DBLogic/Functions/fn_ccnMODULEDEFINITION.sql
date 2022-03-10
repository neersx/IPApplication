-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnMODULEDEFINITION
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnMODULEDEFINITION]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnMODULEDEFINITION.'
	drop function dbo.fn_ccnMODULEDEFINITION
	print '**** Creating function dbo.fn_ccnMODULEDEFINITION...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_MODULEDEFINITION]') and xtype='U')
begin
	select * 
	into CCImport_MODULEDEFINITION 
	from MODULEDEFINITION
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnMODULEDEFINITION
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnMODULEDEFINITION
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the MODULEDEFINITION table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'MODULEDEFINITION' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_MODULEDEFINITION I 
	right join MODULEDEFINITION C on( C.MODULEDEFID=I.MODULEDEFID)
where I.MODULEDEFID is null
UNION ALL 
select	6, 'MODULEDEFINITION', 0, count(*), 0, 0
from CCImport_MODULEDEFINITION I 
	left join MODULEDEFINITION C on( C.MODULEDEFID=I.MODULEDEFID)
where C.MODULEDEFID is null
UNION ALL 
 select	6, 'MODULEDEFINITION', 0, 0, count(*), 0
from CCImport_MODULEDEFINITION I 
	join MODULEDEFINITION C	on ( C.MODULEDEFID=I.MODULEDEFID)
where 	( I.NAME <>  C.NAME)
	OR 	(replace( I.DESKTOPSRC,char(10),char(13)+char(10)) <>  C.DESKTOPSRC OR (I.DESKTOPSRC is null and C.DESKTOPSRC is not null) 
OR (I.DESKTOPSRC is not null and C.DESKTOPSRC is null))
	OR 	(replace( I.MOBILESRC,char(10),char(13)+char(10)) <>  C.MOBILESRC OR (I.MOBILESRC is null and C.MOBILESRC is not null) 
OR (I.MOBILESRC is not null and C.MOBILESRC is null))
UNION ALL 
 select	6, 'MODULEDEFINITION', 0, 0, 0, count(*)
from CCImport_MODULEDEFINITION I 
join MODULEDEFINITION C	on( C.MODULEDEFID=I.MODULEDEFID)
where ( I.NAME =  C.NAME)
and (replace( I.DESKTOPSRC,char(10),char(13)+char(10)) =  C.DESKTOPSRC OR (I.DESKTOPSRC is null and C.DESKTOPSRC is null))
and (replace( I.MOBILESRC,char(10),char(13)+char(10)) =  C.MOBILESRC OR (I.MOBILESRC is null and C.MOBILESRC is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_MODULEDEFINITION]') and xtype='U')
begin
	drop table CCImport_MODULEDEFINITION 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnMODULEDEFINITION  to public
go
