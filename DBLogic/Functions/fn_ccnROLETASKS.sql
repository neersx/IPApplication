-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnROLETASKS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnROLETASKS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnROLETASKS.'
	drop function dbo.fn_ccnROLETASKS
	print '**** Creating function dbo.fn_ccnROLETASKS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ROLETASKS]') and xtype='U')
begin
	select * 
	into CCImport_ROLETASKS 
	from ROLETASKS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnROLETASKS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnROLETASKS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ROLETASKS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'ROLETASKS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_ROLETASKS I 
	right join ROLETASKS C on( C.ROLEID=I.ROLEID
and  C.TASKID=I.TASKID)
where I.ROLEID is null
UNION ALL 
select	6, 'ROLETASKS', 0, count(*), 0, 0
from CCImport_ROLETASKS I 
	left join ROLETASKS C on( C.ROLEID=I.ROLEID
and  C.TASKID=I.TASKID)
where C.ROLEID is null
UNION ALL 
 select	6, 'ROLETASKS', 0, 0, 0, count(*)
from CCImport_ROLETASKS I 
join ROLETASKS C	on( C.ROLEID=I.ROLEID
and C.TASKID=I.TASKID)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ROLETASKS]') and xtype='U')
begin
	drop table CCImport_ROLETASKS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnROLETASKS  to public
go

