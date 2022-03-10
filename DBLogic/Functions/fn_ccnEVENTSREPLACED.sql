-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnEVENTSREPLACED
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnEVENTSREPLACED]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnEVENTSREPLACED.'
	drop function dbo.fn_ccnEVENTSREPLACED
	print '**** Creating function dbo.fn_ccnEVENTSREPLACED...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTSREPLACED]') and xtype='U')
begin
	select * 
	into CCImport_EVENTSREPLACED 
	from EVENTSREPLACED
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnEVENTSREPLACED
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnEVENTSREPLACED
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the EVENTSREPLACED table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'EVENTSREPLACED' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_EVENTSREPLACED I 
	right join EVENTSREPLACED C on( C.OLDEVENTNO=I.OLDEVENTNO)
where I.OLDEVENTNO is null
UNION ALL 
select	5, 'EVENTSREPLACED', 0, count(*), 0, 0
from CCImport_EVENTSREPLACED I 
	left join EVENTSREPLACED C on( C.OLDEVENTNO=I.OLDEVENTNO)
where C.OLDEVENTNO is null
UNION ALL 
 select	5, 'EVENTSREPLACED', 0, 0, count(*), 0
from CCImport_EVENTSREPLACED I 
	join EVENTSREPLACED C	on ( C.OLDEVENTNO=I.OLDEVENTNO)
where 	( I.EVENTNO <>  C.EVENTNO OR (I.EVENTNO is null and C.EVENTNO is not null) 
OR (I.EVENTNO is not null and C.EVENTNO is null))
UNION ALL 
 select	5, 'EVENTSREPLACED', 0, 0, 0, count(*)
from CCImport_EVENTSREPLACED I 
join EVENTSREPLACED C	on( C.OLDEVENTNO=I.OLDEVENTNO)
where ( I.EVENTNO =  C.EVENTNO OR (I.EVENTNO is null and C.EVENTNO is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTSREPLACED]') and xtype='U')
begin
	drop table CCImport_EVENTSREPLACED 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnEVENTSREPLACED  to public
go
