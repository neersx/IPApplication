-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnGROUPMEMBERS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnGROUPMEMBERS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnGROUPMEMBERS.'
	drop function dbo.fn_ccnGROUPMEMBERS
	print '**** Creating function dbo.fn_ccnGROUPMEMBERS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_GROUPMEMBERS]') and xtype='U')
begin
	select * 
	into CCImport_GROUPMEMBERS 
	from GROUPMEMBERS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnGROUPMEMBERS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnGROUPMEMBERS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the GROUPMEMBERS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'GROUPMEMBERS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_GROUPMEMBERS I 
	right join GROUPMEMBERS C on( C.NAMEGROUP=I.NAMEGROUP
and  C.NAMETYPE=I.NAMETYPE)
where I.NAMEGROUP is null
UNION ALL 
select	2, 'GROUPMEMBERS', 0, count(*), 0, 0
from CCImport_GROUPMEMBERS I 
	left join GROUPMEMBERS C on( C.NAMEGROUP=I.NAMEGROUP
and  C.NAMETYPE=I.NAMETYPE)
where C.NAMEGROUP is null
UNION ALL 
 select	2, 'GROUPMEMBERS', 0, 0, 0, count(*)
from CCImport_GROUPMEMBERS I 
join GROUPMEMBERS C	on( C.NAMEGROUP=I.NAMEGROUP
and C.NAMETYPE=I.NAMETYPE)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_GROUPMEMBERS]') and xtype='U')
begin
	drop table CCImport_GROUPMEMBERS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnGROUPMEMBERS  to public
go
