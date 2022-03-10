-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnROLETOPICS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnROLETOPICS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnROLETOPICS.'
	drop function dbo.fn_ccnROLETOPICS
	print '**** Creating function dbo.fn_ccnROLETOPICS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ROLETOPICS]') and xtype='U')
begin
	select * 
	into CCImport_ROLETOPICS 
	from ROLETOPICS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnROLETOPICS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnROLETOPICS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ROLETOPICS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'ROLETOPICS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_ROLETOPICS I 
	right join ROLETOPICS C on( C.ROLEID=I.ROLEID
and  C.TOPICID=I.TOPICID)
where I.ROLEID is null
UNION ALL 
select	6, 'ROLETOPICS', 0, count(*), 0, 0
from CCImport_ROLETOPICS I 
	left join ROLETOPICS C on( C.ROLEID=I.ROLEID
and  C.TOPICID=I.TOPICID)
where C.ROLEID is null
UNION ALL 
 select	6, 'ROLETOPICS', 0, 0, 0, count(*)
from CCImport_ROLETOPICS I 
join ROLETOPICS C	on( C.ROLEID=I.ROLEID
and C.TOPICID=I.TOPICID)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ROLETOPICS]') and xtype='U')
begin
	drop table CCImport_ROLETOPICS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnROLETOPICS  to public
go
