-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnWIPTYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnWIPTYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnWIPTYPE.'
	drop function dbo.fn_ccnWIPTYPE
	print '**** Creating function dbo.fn_ccnWIPTYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_WIPTYPE]') and xtype='U')
begin
	select * 
	into CCImport_WIPTYPE 
	from WIPTYPE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnWIPTYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnWIPTYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the WIPTYPE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	8 as TRIPNO, 'WIPTYPE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_WIPTYPE I 
	right join WIPTYPE C on( C.WIPTYPEID=I.WIPTYPEID)
where I.WIPTYPEID is null
UNION ALL 
select	8, 'WIPTYPE', 0, count(*), 0, 0
from CCImport_WIPTYPE I 
	left join WIPTYPE C on( C.WIPTYPEID=I.WIPTYPEID)
where C.WIPTYPEID is null
UNION ALL 
 select	8, 'WIPTYPE', 0, 0, count(*), 0
from CCImport_WIPTYPE I 
	join WIPTYPE C	on ( C.WIPTYPEID=I.WIPTYPEID)
where 	( I.CATEGORYCODE <>  C.CATEGORYCODE OR (I.CATEGORYCODE is null and C.CATEGORYCODE is not null) 
OR (I.CATEGORYCODE is not null and C.CATEGORYCODE is null))
	OR 	( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.CONSOLIDATE <>  C.CONSOLIDATE OR (I.CONSOLIDATE is null and C.CONSOLIDATE is not null) 
OR (I.CONSOLIDATE is not null and C.CONSOLIDATE is null))
	OR 	( I.WIPTYPESORT <>  C.WIPTYPESORT OR (I.WIPTYPESORT is null and C.WIPTYPESORT is not null) 
OR (I.WIPTYPESORT is not null and C.WIPTYPESORT is null))
	OR 	( I.RECORDASSOCDETAILS <>  C.RECORDASSOCDETAILS)
	OR 	( I.EXCHSCHEDULEID <>  C.EXCHSCHEDULEID OR (I.EXCHSCHEDULEID is null and C.EXCHSCHEDULEID is not null) 
OR (I.EXCHSCHEDULEID is not null and C.EXCHSCHEDULEID is null))
	OR 	( I.WRITEDOWNPRIORITY <>  C.WRITEDOWNPRIORITY OR (I.WRITEDOWNPRIORITY is null and C.WRITEDOWNPRIORITY is not null) 
OR (I.WRITEDOWNPRIORITY is not null and C.WRITEDOWNPRIORITY is null))
	OR 	( I.WRITEUPALLOWED <>  C.WRITEUPALLOWED OR (I.WRITEUPALLOWED is null and C.WRITEUPALLOWED is not null) 
OR (I.WRITEUPALLOWED is not null and C.WRITEUPALLOWED is null))
UNION ALL 
 select	8, 'WIPTYPE', 0, 0, 0, count(*)
from CCImport_WIPTYPE I 
join WIPTYPE C	on( C.WIPTYPEID=I.WIPTYPEID)
where ( I.CATEGORYCODE =  C.CATEGORYCODE OR (I.CATEGORYCODE is null and C.CATEGORYCODE is null))
and ( I.DESCRIPTION =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))
and ( I.CONSOLIDATE =  C.CONSOLIDATE OR (I.CONSOLIDATE is null and C.CONSOLIDATE is null))
and ( I.WIPTYPESORT =  C.WIPTYPESORT OR (I.WIPTYPESORT is null and C.WIPTYPESORT is null))
and ( I.RECORDASSOCDETAILS =  C.RECORDASSOCDETAILS)
and ( I.EXCHSCHEDULEID =  C.EXCHSCHEDULEID OR (I.EXCHSCHEDULEID is null and C.EXCHSCHEDULEID is null))
and ( I.WRITEDOWNPRIORITY =  C.WRITEDOWNPRIORITY OR (I.WRITEDOWNPRIORITY is null and C.WRITEDOWNPRIORITY is null))
and ( I.WRITEUPALLOWED =  C.WRITEUPALLOWED OR (I.WRITEUPALLOWED is null and C.WRITEUPALLOWED is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_WIPTYPE]') and xtype='U')
begin
	drop table CCImport_WIPTYPE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnWIPTYPE  to public
go

