-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnTASK
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnTASK]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnTASK.'
	drop function dbo.fn_ccnTASK
	print '**** Creating function dbo.fn_ccnTASK...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TASK]') and xtype='U')
begin
	select * 
	into CCImport_TASK 
	from TASK
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnTASK
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnTASK
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TASK table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'TASK' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_TASK I 
	right join TASK C on( C.TASKID=I.TASKID)
where I.TASKID is null
UNION ALL 
select	6, 'TASK', 0, count(*), 0, 0
from CCImport_TASK I 
	left join TASK C on( C.TASKID=I.TASKID)
where C.TASKID is null
UNION ALL 
 select	6, 'TASK', 0, 0, count(*), 0
from CCImport_TASK I 
	join TASK C	on ( C.TASKID=I.TASKID)
where 	(replace( I.TASKNAME,char(10),char(13)+char(10)) <>  C.TASKNAME)
	OR 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.CANIMPERSONATE <>  C.CANIMPERSONATE)
UNION ALL 
 select	6, 'TASK', 0, 0, 0, count(*)
from CCImport_TASK I 
join TASK C	on( C.TASKID=I.TASKID)
where (replace( I.TASKNAME,char(10),char(13)+char(10)) =  C.TASKNAME)
and (replace( I.DESCRIPTION,char(10),char(13)+char(10)) =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))
and ( I.CANIMPERSONATE =  C.CANIMPERSONATE)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TASK]') and xtype='U')
begin
	drop table CCImport_TASK 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnTASK  to public
go
