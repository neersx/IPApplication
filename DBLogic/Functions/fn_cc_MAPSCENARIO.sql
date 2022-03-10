-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_MAPSCENARIO
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_MAPSCENARIO]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_MAPSCENARIO.'
	drop function dbo.fn_cc_MAPSCENARIO
	print '**** Creating function dbo.fn_cc_MAPSCENARIO...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_MAPSCENARIO]') and xtype='U')
begin
	select * 
	into CCImport_MAPSCENARIO 
	from MAPSCENARIO
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_MAPSCENARIO
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_MAPSCENARIO
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the MAPSCENARIO table
-- CALLED BY :	ip_CopyConfigMAPSCENARIO
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
	 null as 'Imported Systemid',
	 null as 'Imported Structureid',
	 null as 'Imported Schemeid',
	 null as 'Imported Ignoreunmapped',
'D' as '-',
	 C.SYSTEMID as 'Systemid',
	 C.STRUCTUREID as 'Structureid',
	 C.SCHEMEID as 'Schemeid',
	 C.IGNOREUNMAPPED as 'Ignoreunmapped'
from CCImport_MAPSCENARIO I 
	right join MAPSCENARIO C on( C.SCENARIOID=I.SCENARIOID)
where I.SCENARIOID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.SYSTEMID,
	 I.STRUCTUREID,
	 I.SCHEMEID,
	 I.IGNOREUNMAPPED,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_MAPSCENARIO I 
	left join MAPSCENARIO C on( C.SCENARIOID=I.SCENARIOID)
where C.SCENARIOID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.SYSTEMID,
	 I.STRUCTUREID,
	 I.SCHEMEID,
	 I.IGNOREUNMAPPED,
'U',
	 C.SYSTEMID,
	 C.STRUCTUREID,
	 C.SCHEMEID,
	 C.IGNOREUNMAPPED
from CCImport_MAPSCENARIO I 
	join MAPSCENARIO C	on ( C.SCENARIOID=I.SCENARIOID)
where 	( I.SYSTEMID <>  C.SYSTEMID)
	OR 	( I.STRUCTUREID <>  C.STRUCTUREID)
	OR 	( I.SCHEMEID <>  C.SCHEMEID OR (I.SCHEMEID is null and C.SCHEMEID is not null) 
OR (I.SCHEMEID is not null and C.SCHEMEID is null))
	OR 	( I.IGNOREUNMAPPED <>  C.IGNOREUNMAPPED)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_MAPSCENARIO]') and xtype='U')
begin
	drop table CCImport_MAPSCENARIO 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_MAPSCENARIO  to public
go
