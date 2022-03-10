-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnPORTAL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnPORTAL]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnPORTAL.'
	drop function dbo.fn_ccnPORTAL
	print '**** Creating function dbo.fn_ccnPORTAL...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PORTAL]') and xtype='U')
begin
	select * 
	into CCImport_PORTAL 
	from PORTAL
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnPORTAL
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnPORTAL
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PORTAL table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'PORTAL' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_PORTAL I 
	right join PORTAL C on( C.PORTALID=I.PORTALID)
where I.PORTALID is null
UNION ALL 
select	6, 'PORTAL', 0, count(*), 0, 0
from CCImport_PORTAL I 
	left join PORTAL C on( C.PORTALID=I.PORTALID)
where C.PORTALID is null
UNION ALL 
 select	6, 'PORTAL', 0, 0, count(*), 0
from CCImport_PORTAL I 
	join PORTAL C	on ( C.PORTALID=I.PORTALID)
where 	( I.NAME <>  C.NAME)
	OR 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.ISEXTERNAL <>  C.ISEXTERNAL)
UNION ALL 
 select	6, 'PORTAL', 0, 0, 0, count(*)
from CCImport_PORTAL I 
join PORTAL C	on( C.PORTALID=I.PORTALID)
where ( I.NAME =  C.NAME)
and (replace( I.DESCRIPTION,char(10),char(13)+char(10)) =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))
and ( I.ISEXTERNAL =  C.ISEXTERNAL)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PORTAL]') and xtype='U')
begin
	drop table CCImport_PORTAL 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnPORTAL  to public
go
