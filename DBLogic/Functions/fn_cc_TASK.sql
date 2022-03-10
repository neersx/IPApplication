-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_TASK
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_TASK]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_TASK.'
	drop function dbo.fn_cc_TASK
	print '**** Creating function dbo.fn_cc_TASK...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TASK]') and xtype='U')
begin
	select * 
	into CCImport_TASK 
	from TASK
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_TASK
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_TASK
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TASK table
-- CALLED BY :	ip_CopyConfigTASK
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
	 null as 'Imported Taskid',
	 null as 'Imported Taskname',
	 null as 'Imported Description',
	 null as 'Imported Canimpersonate',
'D' as '-',
	 C.TASKID as 'Taskid',
	 C.TASKNAME as 'Taskname',
	 C.DESCRIPTION as 'Description',
	 C.CANIMPERSONATE as 'Canimpersonate'
from CCImport_TASK I 
	right join TASK C on( C.TASKID=I.TASKID)
where I.TASKID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.TASKID,
	 I.TASKNAME,
	 I.DESCRIPTION,
	 I.CANIMPERSONATE,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_TASK I 
	left join TASK C on( C.TASKID=I.TASKID)
where C.TASKID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.TASKID,
	 I.TASKNAME,
	 I.DESCRIPTION,
	 I.CANIMPERSONATE,
'U',
	 C.TASKID,
	 C.TASKNAME,
	 C.DESCRIPTION,
	 C.CANIMPERSONATE
from CCImport_TASK I 
	join TASK C	on ( C.TASKID=I.TASKID)
where 	(replace( I.TASKNAME,char(10),char(13)+char(10)) <>  C.TASKNAME)
	OR 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.CANIMPERSONATE <>  C.CANIMPERSONATE)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TASK]') and xtype='U')
begin
	drop table CCImport_TASK 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_TASK  to public
go
