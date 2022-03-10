-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnEDERULECASEEVENT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnEDERULECASEEVENT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnEDERULECASEEVENT.'
	drop function dbo.fn_ccnEDERULECASEEVENT
	print '**** Creating function dbo.fn_ccnEDERULECASEEVENT...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_EDERULECASEEVENT]') and xtype='U')
begin
	select * 
	into CCImport_EDERULECASEEVENT 
	from EDERULECASEEVENT
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnEDERULECASEEVENT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnEDERULECASEEVENT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the EDERULECASEEVENT table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	9 as TRIPNO, 'EDERULECASEEVENT' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_EDERULECASEEVENT I 
	right join EDERULECASEEVENT C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO)
where I.CRITERIANO is null
UNION ALL 
select	9, 'EDERULECASEEVENT', 0, count(*), 0, 0
from CCImport_EDERULECASEEVENT I 
	left join EDERULECASEEVENT C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO)
where C.CRITERIANO is null
UNION ALL 
 select	9, 'EDERULECASEEVENT', 0, 0, count(*), 0
from CCImport_EDERULECASEEVENT I 
	join EDERULECASEEVENT C	on ( C.CRITERIANO=I.CRITERIANO
	and C.EVENTNO=I.EVENTNO)
where 	( I.EVENTDATE <>  C.EVENTDATE OR (I.EVENTDATE is null and C.EVENTDATE is not null) 
OR (I.EVENTDATE is not null and C.EVENTDATE is null))
	OR 	( I.EVENTDUEDATE <>  C.EVENTDUEDATE OR (I.EVENTDUEDATE is null and C.EVENTDUEDATE is not null) 
OR (I.EVENTDUEDATE is not null and C.EVENTDUEDATE is null))
	OR 	( I.EVENTTEXT <>  C.EVENTTEXT OR (I.EVENTTEXT is null and C.EVENTTEXT is not null) 
OR (I.EVENTTEXT is not null and C.EVENTTEXT is null))
UNION ALL 
 select	9, 'EDERULECASEEVENT', 0, 0, 0, count(*)
from CCImport_EDERULECASEEVENT I 
join EDERULECASEEVENT C	on( C.CRITERIANO=I.CRITERIANO
and C.EVENTNO=I.EVENTNO)
where ( I.EVENTDATE =  C.EVENTDATE OR (I.EVENTDATE is null and C.EVENTDATE is null))
and ( I.EVENTDUEDATE =  C.EVENTDUEDATE OR (I.EVENTDUEDATE is null and C.EVENTDUEDATE is null))
and ( I.EVENTTEXT =  C.EVENTTEXT OR (I.EVENTTEXT is null and C.EVENTTEXT is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EDERULECASEEVENT]') and xtype='U')
begin
	drop table CCImport_EDERULECASEEVENT 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnEDERULECASEEVENT  to public
go
