-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnDATATOPIC
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnDATATOPIC]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnDATATOPIC.'
	drop function dbo.fn_ccnDATATOPIC
	print '**** Creating function dbo.fn_ccnDATATOPIC...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_DATATOPIC]') and xtype='U')
begin
	select * 
	into CCImport_DATATOPIC 
	from DATATOPIC
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnDATATOPIC
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnDATATOPIC
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the DATATOPIC table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'DATATOPIC' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_DATATOPIC I 
	right join DATATOPIC C on( C.TOPICID=I.TOPICID)
where I.TOPICID is null
UNION ALL 
select	6, 'DATATOPIC', 0, count(*), 0, 0
from CCImport_DATATOPIC I 
	left join DATATOPIC C on( C.TOPICID=I.TOPICID)
where C.TOPICID is null
UNION ALL 
 select	6, 'DATATOPIC', 0, 0, count(*), 0
from CCImport_DATATOPIC I 
	join DATATOPIC C	on ( C.TOPICID=I.TOPICID)
where 	( I.TOPICNAME <>  C.TOPICNAME)
	OR 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.ISEXTERNAL <>  C.ISEXTERNAL)
	OR 	( I.ISINTERNAL <>  C.ISINTERNAL)
UNION ALL 
 select	6, 'DATATOPIC', 0, 0, 0, count(*)
from CCImport_DATATOPIC I 
join DATATOPIC C	on( C.TOPICID=I.TOPICID)
where ( I.TOPICNAME =  C.TOPICNAME)
and (replace( I.DESCRIPTION,char(10),char(13)+char(10)) =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))
and ( I.ISEXTERNAL =  C.ISEXTERNAL)
and ( I.ISINTERNAL =  C.ISINTERNAL)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DATATOPIC]') and xtype='U')
begin
	drop table CCImport_DATATOPIC 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnDATATOPIC  to public
go
