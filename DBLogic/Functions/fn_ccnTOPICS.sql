-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnTOPICS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnTOPICS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnTOPICS.'
	drop function dbo.fn_ccnTOPICS
	print '**** Creating function dbo.fn_ccnTOPICS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TOPICS]') and xtype='U')
begin
	select * 
	into CCImport_TOPICS 
	from TOPICS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnTOPICS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnTOPICS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TOPICS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'TOPICS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_TOPICS I 
	right join TOPICS C on( C.TOPICNAME=I.TOPICNAME
and  C.TOPICTYPE=I.TOPICTYPE)
where I.TOPICNAME is null
UNION ALL 
select	6, 'TOPICS', 0, count(*), 0, 0
from CCImport_TOPICS I 
	left join TOPICS C on( C.TOPICNAME=I.TOPICNAME
and  C.TOPICTYPE=I.TOPICTYPE)
where C.TOPICNAME is null
UNION ALL 
 select	6, 'TOPICS', 0, 0, 0, count(*)
from CCImport_TOPICS I 
join TOPICS C	on( C.TOPICNAME=I.TOPICNAME
and C.TOPICTYPE=I.TOPICTYPE)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TOPICS]') and xtype='U')
begin
	drop table CCImport_TOPICS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnTOPICS  to public
go
