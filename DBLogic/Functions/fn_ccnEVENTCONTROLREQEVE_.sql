-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnEVENTCONTROLREQEVE_
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnEVENTCONTROLREQEVE_]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnEVENTCONTROLREQEVE_.'
	drop function dbo.fn_ccnEVENTCONTROLREQEVE_
	print '**** Creating function dbo.fn_ccnEVENTCONTROLREQEVE_...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTCONTROLREQEVENT]') and xtype='U')
begin
	select * 
	into CCImport_EVENTCONTROLREQEVENT 
	from EVENTCONTROLREQEVENT
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnEVENTCONTROLREQEVE_
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnEVENTCONTROLREQEVE_
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the EVENTCONTROLREQEVENT table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'EVENTCONTROLREQEVENT' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_EVENTCONTROLREQEVENT I 
	right join EVENTCONTROLREQEVENT C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO
and  C.REQEVENTNO=I.REQEVENTNO)
where I.CRITERIANO is null
UNION ALL 
select	5, 'EVENTCONTROLREQEVENT', 0, count(*), 0, 0
from CCImport_EVENTCONTROLREQEVENT I 
	left join EVENTCONTROLREQEVENT C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO
and  C.REQEVENTNO=I.REQEVENTNO)
where C.CRITERIANO is null
UNION ALL 
 select	5, 'EVENTCONTROLREQEVENT', 0, 0, count(*), 0
from CCImport_EVENTCONTROLREQEVENT I 
	join EVENTCONTROLREQEVENT C	on ( C.CRITERIANO=I.CRITERIANO
	and C.EVENTNO=I.EVENTNO
	and C.REQEVENTNO=I.REQEVENTNO)
where 	( I.INHERITED <>  C.INHERITED)
UNION ALL 
 select	5, 'EVENTCONTROLREQEVENT', 0, 0, 0, count(*)
from CCImport_EVENTCONTROLREQEVENT I 
join EVENTCONTROLREQEVENT C	on( C.CRITERIANO=I.CRITERIANO
and C.EVENTNO=I.EVENTNO
and C.REQEVENTNO=I.REQEVENTNO)
where ( I.INHERITED =  C.INHERITED)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTCONTROLREQEVENT]') and xtype='U')
begin
	drop table CCImport_EVENTCONTROLREQEVENT 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnEVENTCONTROLREQEVE_  to public
go
