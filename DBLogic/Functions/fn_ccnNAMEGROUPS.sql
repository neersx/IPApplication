-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnNAMEGROUPS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnNAMEGROUPS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnNAMEGROUPS.'
	drop function dbo.fn_ccnNAMEGROUPS
	print '**** Creating function dbo.fn_ccnNAMEGROUPS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_NAMEGROUPS]') and xtype='U')
begin
	select * 
	into CCImport_NAMEGROUPS 
	from NAMEGROUPS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnNAMEGROUPS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnNAMEGROUPS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the NAMEGROUPS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'NAMEGROUPS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_NAMEGROUPS I 
	right join NAMEGROUPS C on( C.NAMEGROUP=I.NAMEGROUP)
where I.NAMEGROUP is null
UNION ALL 
select	2, 'NAMEGROUPS', 0, count(*), 0, 0
from CCImport_NAMEGROUPS I 
	left join NAMEGROUPS C on( C.NAMEGROUP=I.NAMEGROUP)
where C.NAMEGROUP is null
UNION ALL 
 select	2, 'NAMEGROUPS', 0, 0, count(*), 0
from CCImport_NAMEGROUPS I 
	join NAMEGROUPS C	on ( C.NAMEGROUP=I.NAMEGROUP)
where 	( I.GROUPDESCRIPTION <>  C.GROUPDESCRIPTION OR (I.GROUPDESCRIPTION is null and C.GROUPDESCRIPTION is not null) 
OR (I.GROUPDESCRIPTION is not null and C.GROUPDESCRIPTION is null))
UNION ALL 
 select	2, 'NAMEGROUPS', 0, 0, 0, count(*)
from CCImport_NAMEGROUPS I 
join NAMEGROUPS C	on( C.NAMEGROUP=I.NAMEGROUP)
where ( I.GROUPDESCRIPTION =  C.GROUPDESCRIPTION OR (I.GROUPDESCRIPTION is null and C.GROUPDESCRIPTION is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_NAMEGROUPS]') and xtype='U')
begin
	drop table CCImport_NAMEGROUPS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnNAMEGROUPS  to public
go
