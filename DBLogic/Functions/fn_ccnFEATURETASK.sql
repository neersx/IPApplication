-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnFEATURETASK
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnFEATURETASK]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnFEATURETASK.'
	drop function dbo.fn_ccnFEATURETASK
	print '**** Creating function dbo.fn_ccnFEATURETASK...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_FEATURETASK]') and xtype='U')
begin
	select * 
	into CCImport_FEATURETASK 
	from FEATURETASK
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnFEATURETASK
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnFEATURETASK
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the FEATURETASK table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'FEATURETASK' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_FEATURETASK I 
	right join FEATURETASK C on( C.FEATUREID=I.FEATUREID
and  C.TASKID=I.TASKID)
where I.FEATUREID is null
UNION ALL 
select	6, 'FEATURETASK', 0, count(*), 0, 0
from CCImport_FEATURETASK I 
	left join FEATURETASK C on( C.FEATUREID=I.FEATUREID
and  C.TASKID=I.TASKID)
where C.FEATUREID is null
UNION ALL 
 select	6, 'FEATURETASK', 0, 0, 0, count(*)
from CCImport_FEATURETASK I 
join FEATURETASK C	on( C.FEATUREID=I.FEATUREID
and C.TASKID=I.TASKID)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_FEATURETASK]') and xtype='U')
begin
	drop table CCImport_FEATURETASK 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnFEATURETASK  to public
go
