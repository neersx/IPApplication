-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnMAPSCENARIO
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnMAPSCENARIO]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnMAPSCENARIO.'
	drop function dbo.fn_ccnMAPSCENARIO
	print '**** Creating function dbo.fn_ccnMAPSCENARIO...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_MAPSCENARIO]') and xtype='U')
begin
	select * 
	into CCImport_MAPSCENARIO 
	from MAPSCENARIO
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnMAPSCENARIO
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnMAPSCENARIO
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the MAPSCENARIO table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	9 as TRIPNO, 'MAPSCENARIO' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_MAPSCENARIO I 
	right join MAPSCENARIO C on( C.SCENARIOID=I.SCENARIOID)
where I.SCENARIOID is null
UNION ALL 
select	9, 'MAPSCENARIO', 0, count(*), 0, 0
from CCImport_MAPSCENARIO I 
	left join MAPSCENARIO C on( C.SCENARIOID=I.SCENARIOID)
where C.SCENARIOID is null
UNION ALL 
 select	9, 'MAPSCENARIO', 0, 0, count(*), 0
from CCImport_MAPSCENARIO I 
	join MAPSCENARIO C	on ( C.SCENARIOID=I.SCENARIOID)
where 	( I.SYSTEMID <>  C.SYSTEMID)
	OR 	( I.STRUCTUREID <>  C.STRUCTUREID)
	OR 	( I.SCHEMEID <>  C.SCHEMEID OR (I.SCHEMEID is null and C.SCHEMEID is not null) 
OR (I.SCHEMEID is not null and C.SCHEMEID is null))
	OR 	( I.IGNOREUNMAPPED <>  C.IGNOREUNMAPPED)
UNION ALL 
 select	9, 'MAPSCENARIO', 0, 0, 0, count(*)
from CCImport_MAPSCENARIO I 
join MAPSCENARIO C	on( C.SCENARIOID=I.SCENARIOID)
where ( I.SYSTEMID =  C.SYSTEMID)
and ( I.STRUCTUREID =  C.STRUCTUREID)
and ( I.SCHEMEID =  C.SCHEMEID OR (I.SCHEMEID is null and C.SCHEMEID is null))
and ( I.IGNOREUNMAPPED =  C.IGNOREUNMAPPED)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_MAPSCENARIO]') and xtype='U')
begin
	drop table CCImport_MAPSCENARIO 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnMAPSCENARIO  to public
go
