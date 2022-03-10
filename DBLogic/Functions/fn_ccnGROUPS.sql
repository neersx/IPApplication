-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnGROUPS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnGROUPS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnGROUPS.'
	drop function dbo.fn_ccnGROUPS
	print '**** Creating function dbo.fn_ccnGROUPS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_GROUPS]') and xtype='U')
begin
	select * 
	into CCImport_GROUPS 
	from GROUPS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnGROUPS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnGROUPS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the GROUPS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	10 as TRIPNO, 'GROUPS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_GROUPS I 
	right join GROUPS C on( C.GROUP_CODE=I.GROUP_CODE)
where I.GROUP_CODE is null
UNION ALL 
select	10, 'GROUPS', 0, count(*), 0, 0
from CCImport_GROUPS I 
	left join GROUPS C on( C.GROUP_CODE=I.GROUP_CODE)
where C.GROUP_CODE is null
UNION ALL 
 select	10, 'GROUPS', 0, 0, count(*), 0
from CCImport_GROUPS I 
	join GROUPS C	on ( C.GROUP_CODE=I.GROUP_CODE)
where 	( I.GROUP_NAME <>  C.GROUP_NAME)
UNION ALL 
 select	10, 'GROUPS', 0, 0, 0, count(*)
from CCImport_GROUPS I 
join GROUPS C	on( C.GROUP_CODE=I.GROUP_CODE)
where ( I.GROUP_NAME =  C.GROUP_NAME)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_GROUPS]') and xtype='U')
begin
	drop table CCImport_GROUPS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnGROUPS  to public
go
