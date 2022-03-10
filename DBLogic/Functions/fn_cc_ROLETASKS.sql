-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_ROLETASKS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_ROLETASKS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_ROLETASKS.'
	drop function dbo.fn_cc_ROLETASKS
	print '**** Creating function dbo.fn_cc_ROLETASKS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ROLETASKS]') and xtype='U')
begin
	select * 
	into CCImport_ROLETASKS 
	from ROLETASKS
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_ROLETASKS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_ROLETASKS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ROLETASKS table
-- CALLED BY :	ip_CopyConfigROLETASKS
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
	 null as 'Imported Roleid',
	 null as 'Imported Taskid',
'D' as '-',
	 C.ROLEID as 'Roleid',
	 C.TASKID as 'Taskid'
from CCImport_ROLETASKS I 
	right join ROLETASKS C on( C.ROLEID=I.ROLEID
and  C.TASKID=I.TASKID)
where I.ROLEID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.ROLEID,
	 I.TASKID,
'I',
	 null ,
	 null
from CCImport_ROLETASKS I 
	left join ROLETASKS C on( C.ROLEID=I.ROLEID
and  C.TASKID=I.TASKID)
where C.ROLEID is null

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ROLETASKS]') and xtype='U')
begin
	drop table CCImport_ROLETASKS 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_ROLETASKS  to public
go
