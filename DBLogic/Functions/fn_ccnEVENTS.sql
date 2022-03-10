-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnEVENTS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnEVENTS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnEVENTS.'
	drop function dbo.fn_ccnEVENTS
	print '**** Creating function dbo.fn_ccnEVENTS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTS]') and xtype='U')
begin
	select * 
	into CCImport_EVENTS 
	from EVENTS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnEVENTS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnEVENTS
-- VERSION :	2
-- DESCRIPTION:	The SELECT to display of imported data for the EVENTS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
-- 29 Apr 2019	MF	DR-41987 2	New Columns.
--
As 
Return
select	2 as TRIPNO, 'EVENTS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_EVENTS I 
	right join EVENTS C on( C.EVENTNO=I.EVENTNO)
where I.EVENTNO is null
UNION ALL 
select	2, 'EVENTS', 0, count(*), 0, 0
from CCImport_EVENTS I 
	left join EVENTS C on( C.EVENTNO=I.EVENTNO)
where C.EVENTNO is null
UNION ALL 
 select	2, 'EVENTS', 0, 0, count(*), 0
from CCImport_EVENTS I 
	join EVENTS C	on ( C.EVENTNO=I.EVENTNO)
where 	( I.EVENTCODE <>  C.EVENTCODE OR (I.EVENTCODE is null and C.EVENTCODE is not null) 
OR (I.EVENTCODE is not null and C.EVENTCODE is null))
	OR 	( I.EVENTDESCRIPTION <>  C.EVENTDESCRIPTION OR (I.EVENTDESCRIPTION is null and C.EVENTDESCRIPTION is not null) 
OR (I.EVENTDESCRIPTION is not null and C.EVENTDESCRIPTION is null))
	OR 	( I.NUMCYCLESALLOWED <>  C.NUMCYCLESALLOWED OR (I.NUMCYCLESALLOWED is null and C.NUMCYCLESALLOWED is not null) 
OR (I.NUMCYCLESALLOWED is not null and C.NUMCYCLESALLOWED is null))
	OR 	( I.IMPORTANCELEVEL <>  C.IMPORTANCELEVEL OR (I.IMPORTANCELEVEL is null and C.IMPORTANCELEVEL is not null) 
OR (I.IMPORTANCELEVEL is not null and C.IMPORTANCELEVEL is null))
	OR 	( I.CONTROLLINGACTION <>  C.CONTROLLINGACTION OR (I.CONTROLLINGACTION is null and C.CONTROLLINGACTION is not null) 
OR (I.CONTROLLINGACTION is not null and C.CONTROLLINGACTION is null))
	OR 	(replace( I.DEFINITION,char(10),char(13)+char(10)) <>  C.DEFINITION OR (I.DEFINITION is null and C.DEFINITION is not null) 
OR (I.DEFINITION is not null and C.DEFINITION is null))
	OR 	( I.CLIENTIMPLEVEL <>  C.CLIENTIMPLEVEL OR (I.CLIENTIMPLEVEL is null and C.CLIENTIMPLEVEL is not null) 
OR (I.CLIENTIMPLEVEL is not null and C.CLIENTIMPLEVEL is null))
	OR 	( I.CATEGORYID <>  C.CATEGORYID OR (I.CATEGORYID is null and C.CATEGORYID is not null) 
OR (I.CATEGORYID is not null and C.CATEGORYID is null))
	OR 	( I.PROFILEREFNO <>  C.PROFILEREFNO OR (I.PROFILEREFNO is null and C.PROFILEREFNO is not null) 
OR (I.PROFILEREFNO is not null and C.PROFILEREFNO is null))
	OR 	( I.RECALCEVENTDATE <>  C.RECALCEVENTDATE OR (I.RECALCEVENTDATE is null and C.RECALCEVENTDATE is not null) 
OR (I.RECALCEVENTDATE is not null and C.RECALCEVENTDATE is null))
	OR 	( I.DRAFTEVENTNO <>  C.DRAFTEVENTNO OR (I.DRAFTEVENTNO is null and C.DRAFTEVENTNO is not null) 
OR (I.DRAFTEVENTNO is not null and C.DRAFTEVENTNO is null))
	OR 	( I.EVENTGROUP <>  C.EVENTGROUP OR (I.EVENTGROUP is null and C.EVENTGROUP is not null) 
OR (I.EVENTGROUP is not null and C.EVENTGROUP is null))
	OR 	( I.ACCOUNTINGEVENTFLAG <>  C.ACCOUNTINGEVENTFLAG OR (I.ACCOUNTINGEVENTFLAG is null and C.ACCOUNTINGEVENTFLAG is not null) 
OR (I.ACCOUNTINGEVENTFLAG is not null and C.ACCOUNTINGEVENTFLAG is null))
	OR 	( I.POLICINGIMMEDIATE <>  C.POLICINGIMMEDIATE)
	OR 	( I.SUPPRESSCALCULATION <>  C.SUPPRESSCALCULATION OR (I.SUPPRESSCALCULATION is null and C.SUPPRESSCALCULATION is not null) 
OR (I.SUPPRESSCALCULATION is not null and C.SUPPRESSCALCULATION is null))
	OR 	( I.NOTEGROUP <>  C.NOTEGROUP OR (I.NOTEGROUP is null and C.NOTEGROUP is not null) 
OR (I.NOTEGROUP is not null and C.NOTEGROUP is null))
	OR 	( I.NOTESSHAREDACROSSCYCLES <>  C.NOTESSHAREDACROSSCYCLES OR (I.NOTESSHAREDACROSSCYCLES is null and C.NOTESSHAREDACROSSCYCLES is not null) 
OR (I.NOTESSHAREDACROSSCYCLES is not null and C.NOTESSHAREDACROSSCYCLES is null))
UNION ALL 
 select	2, 'EVENTS', 0, 0, 0, count(*)
from CCImport_EVENTS I 
join EVENTS C	on( C.EVENTNO=I.EVENTNO)
where ( I.EVENTCODE =  C.EVENTCODE OR (I.EVENTCODE is null and C.EVENTCODE is null))
and ( I.EVENTDESCRIPTION =  C.EVENTDESCRIPTION OR (I.EVENTDESCRIPTION is null and C.EVENTDESCRIPTION is null))
and ( I.NUMCYCLESALLOWED =  C.NUMCYCLESALLOWED OR (I.NUMCYCLESALLOWED is null and C.NUMCYCLESALLOWED is null))
and ( I.IMPORTANCELEVEL =  C.IMPORTANCELEVEL OR (I.IMPORTANCELEVEL is null and C.IMPORTANCELEVEL is null))
and ( I.CONTROLLINGACTION =  C.CONTROLLINGACTION OR (I.CONTROLLINGACTION is null and C.CONTROLLINGACTION is null))
and (replace( I.DEFINITION,char(10),char(13)+char(10)) =  C.DEFINITION OR (I.DEFINITION is null and C.DEFINITION is null))
and ( I.CLIENTIMPLEVEL =  C.CLIENTIMPLEVEL OR (I.CLIENTIMPLEVEL is null and C.CLIENTIMPLEVEL is null))
and ( I.CATEGORYID =  C.CATEGORYID OR (I.CATEGORYID is null and C.CATEGORYID is null))
and ( I.PROFILEREFNO =  C.PROFILEREFNO OR (I.PROFILEREFNO is null and C.PROFILEREFNO is null))
and ( I.RECALCEVENTDATE =  C.RECALCEVENTDATE OR (I.RECALCEVENTDATE is null and C.RECALCEVENTDATE is null))
and ( I.DRAFTEVENTNO =  C.DRAFTEVENTNO OR (I.DRAFTEVENTNO is null and C.DRAFTEVENTNO is null))
and ( I.EVENTGROUP =  C.EVENTGROUP OR (I.EVENTGROUP is null and C.EVENTGROUP is null))
and ( I.ACCOUNTINGEVENTFLAG =  C.ACCOUNTINGEVENTFLAG OR (I.ACCOUNTINGEVENTFLAG is null and C.ACCOUNTINGEVENTFLAG is null))
and ( I.POLICINGIMMEDIATE       =  C.POLICINGIMMEDIATE)
and ( I.SUPPRESSCALCULATION     =  C.SUPPRESSCALCULATION     OR (I.SUPPRESSCALCULATION     is null and C.SUPPRESSCALCULATION     is null))
and ( I.NOTEGROUP               =  C.NOTEGROUP               OR (I.NOTEGROUP               is null and C.NOTEGROUP               is null))
and ( I.NOTESSHAREDACROSSCYCLES =  C.NOTESSHAREDACROSSCYCLES OR (I.NOTESSHAREDACROSSCYCLES is null and C.NOTESSHAREDACROSSCYCLES is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTS]') and xtype='U')
begin
	drop table CCImport_EVENTS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnEVENTS  to public
go
