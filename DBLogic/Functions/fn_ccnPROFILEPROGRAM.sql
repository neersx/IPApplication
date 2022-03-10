-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnPROFILEPROGRAM
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnPROFILEPROGRAM]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnPROFILEPROGRAM.'
	drop function dbo.fn_ccnPROFILEPROGRAM
	print '**** Creating function dbo.fn_ccnPROFILEPROGRAM...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PROFILEPROGRAM]') and xtype='U')
begin
	select * 
	into CCImport_PROFILEPROGRAM 
	from PROFILEPROGRAM
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnPROFILEPROGRAM
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnPROFILEPROGRAM
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PROFILEPROGRAM table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'PROFILEPROGRAM' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_PROFILEPROGRAM I 
	right join PROFILEPROGRAM C on( C.PROFILEID=I.PROFILEID
and  C.PROGRAMID=I.PROGRAMID)
where I.PROFILEID is null
UNION ALL 
select	6, 'PROFILEPROGRAM', 0, count(*), 0, 0
from CCImport_PROFILEPROGRAM I 
	left join PROFILEPROGRAM C on( C.PROFILEID=I.PROFILEID
and  C.PROGRAMID=I.PROGRAMID)
where C.PROFILEID is null
UNION ALL 
 select	6, 'PROFILEPROGRAM', 0, 0, 0, count(*)
from CCImport_PROFILEPROGRAM I 
join PROFILEPROGRAM C	on( C.PROFILEID=I.PROFILEID
and C.PROGRAMID=I.PROGRAMID)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PROFILEPROGRAM]') and xtype='U')
begin
	drop table CCImport_PROFILEPROGRAM 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnPROFILEPROGRAM  to public
go
