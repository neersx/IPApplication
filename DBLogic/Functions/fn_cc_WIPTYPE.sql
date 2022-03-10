-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_WIPTYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_WIPTYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_WIPTYPE.'
	drop function dbo.fn_cc_WIPTYPE
	print '**** Creating function dbo.fn_cc_WIPTYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_WIPTYPE]') and xtype='U')
begin
	select * 
	into CCImport_WIPTYPE 
	from WIPTYPE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_WIPTYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_WIPTYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the WIPTYPE table
-- CALLED BY :	ip_CopyConfigWIPTYPE
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
	 null as 'Imported Wiptypeid',
	 null as 'Imported Categorycode',
	 null as 'Imported Description',
	 null as 'Imported Consolidate',
	 null as 'Imported Wiptypesort',
	 null as 'Imported Recordassocdetails',
	 null as 'Imported Exchscheduleid',
	 null as 'Imported Writedownpriority',
	 null as 'Imported Writeupallowed',
'D' as '-',
	 C.WIPTYPEID as 'Wiptypeid',
	 C.CATEGORYCODE as 'Categorycode',
	 C.DESCRIPTION as 'Description',
	 C.CONSOLIDATE as 'Consolidate',
	 C.WIPTYPESORT as 'Wiptypesort',
	 C.RECORDASSOCDETAILS as 'Recordassocdetails',
	 C.EXCHSCHEDULEID as 'Exchscheduleid',
	 C.WRITEDOWNPRIORITY as 'Writedownpriority',
	 C.WRITEUPALLOWED as 'Writeupallowed'
from CCImport_WIPTYPE I 
	right join WIPTYPE C on( C.WIPTYPEID=I.WIPTYPEID)
where I.WIPTYPEID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.WIPTYPEID,
	 I.CATEGORYCODE,
	 I.DESCRIPTION,
	 I.CONSOLIDATE,
	 I.WIPTYPESORT,
	 I.RECORDASSOCDETAILS,
	 I.EXCHSCHEDULEID,
	 I.WRITEDOWNPRIORITY,
	 I.WRITEUPALLOWED,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_WIPTYPE I 
	left join WIPTYPE C on( C.WIPTYPEID=I.WIPTYPEID)
where C.WIPTYPEID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.WIPTYPEID,
	 I.CATEGORYCODE,
	 I.DESCRIPTION,
	 I.CONSOLIDATE,
	 I.WIPTYPESORT,
	 I.RECORDASSOCDETAILS,
	 I.EXCHSCHEDULEID,
	 I.WRITEDOWNPRIORITY,
	 I.WRITEUPALLOWED,
'U',
	 C.WIPTYPEID,
	 C.CATEGORYCODE,
	 C.DESCRIPTION,
	 C.CONSOLIDATE,
	 C.WIPTYPESORT,
	 C.RECORDASSOCDETAILS,
	 C.EXCHSCHEDULEID,
	 C.WRITEDOWNPRIORITY,
	 C.WRITEUPALLOWED
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

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_WIPTYPE]') and xtype='U')
begin
	drop table CCImport_WIPTYPE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_WIPTYPE  to public
go
