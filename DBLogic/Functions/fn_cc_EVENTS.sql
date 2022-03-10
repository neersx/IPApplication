-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_EVENTS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_EVENTS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_EVENTS.'
	drop function dbo.fn_cc_EVENTS
	print '**** Creating function dbo.fn_cc_EVENTS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
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


CREATE FUNCTION dbo.fn_cc_EVENTS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_EVENTS
-- VERSION :	2
-- DESCRIPTION:	The SELECT to display of imported data for the EVENTS table
-- CALLED BY :	ip_CopyConfigEVENTS
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
-- 04 Oct 2016	MF	64418	2	New columns
--
As 
Return
select	1 as 'Switch',
	'X' as 'Match',
	'D' as 'Imported -',
	 null as 'Imported Eventno',
	 null as 'Imported Eventcode',
	 null as 'Imported Eventdescription',
	 null as 'Imported Numcyclesallowed',
	 null as 'Imported Importancelevel',
	 null as 'Imported Controllingaction',
	 null as 'Imported Definition',
	 null as 'Imported Clientimplevel',
	 null as 'Imported Categoryid',
	 null as 'Imported Profilerefno',
	 null as 'Imported Recalceventdate',
	 null as 'Imported Drafteventno',
	 null as 'Imported Eventgroup',
	 null as 'Imported Accountingeventflag',
	 null as 'Imported Policingimmediate',
	 null as 'Imported Suppresscalculation',
	 null as 'Imported Notegroup',
	 null as 'Imported Notessharedacrosscycles',
'D' as '-',
	 C.EVENTNO as 'Eventno',
	 C.EVENTCODE as 'Eventcode',
	 C.EVENTDESCRIPTION as 'Eventdescription',
	 C.NUMCYCLESALLOWED as 'Numcyclesallowed',
	 C.IMPORTANCELEVEL as 'Importancelevel',
	 C.CONTROLLINGACTION as 'Controllingaction',
	 C.DEFINITION as 'Definition',
	 C.CLIENTIMPLEVEL as 'Clientimplevel',
	 C.CATEGORYID as 'Categoryid',
	 C.PROFILEREFNO as 'Profilerefno',
	 C.RECALCEVENTDATE as 'Recalceventdate',
	 C.DRAFTEVENTNO as 'Drafteventno',
	 C.EVENTGROUP as 'Eventgroup',
	 C.ACCOUNTINGEVENTFLAG as 'Accountingeventflag',
	 C.POLICINGIMMEDIATE as 'Policingimmediate',
	 C.SUPPRESSCALCULATION as 'Suppresscalculation',
	 C.NOTEGROUP as 'Notegroup',
	 C.NOTESSHAREDACROSSCYCLES as 'Notessharedacrosscycles'
from CCImport_EVENTS I 
	right join EVENTS C on( C.EVENTNO=I.EVENTNO)
where I.EVENTNO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.EVENTNO,
	 I.EVENTCODE,
	 I.EVENTDESCRIPTION,
	 I.NUMCYCLESALLOWED,
	 I.IMPORTANCELEVEL,
	 I.CONTROLLINGACTION,
	 I.DEFINITION,
	 I.CLIENTIMPLEVEL,
	 I.CATEGORYID,
	 I.PROFILEREFNO,
	 I.RECALCEVENTDATE,
	 I.DRAFTEVENTNO,
	 I.EVENTGROUP,
	 I.ACCOUNTINGEVENTFLAG,
	 I.POLICINGIMMEDIATE,
	 I.SUPPRESSCALCULATION,
	 I.NOTEGROUP,
	 I.NOTESSHAREDACROSSCYCLES,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_EVENTS I 
	left join EVENTS C on( C.EVENTNO=I.EVENTNO)
where C.EVENTNO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.EVENTNO,
	 I.EVENTCODE,
	 I.EVENTDESCRIPTION,
	 I.NUMCYCLESALLOWED,
	 I.IMPORTANCELEVEL,
	 I.CONTROLLINGACTION,
	 I.DEFINITION,
	 I.CLIENTIMPLEVEL,
	 I.CATEGORYID,
	 I.PROFILEREFNO,
	 I.RECALCEVENTDATE,
	 I.DRAFTEVENTNO,
	 I.EVENTGROUP,
	 I.ACCOUNTINGEVENTFLAG,
	 I.POLICINGIMMEDIATE,
	 I.SUPPRESSCALCULATION,
	 I.NOTEGROUP,
	 I.NOTESSHAREDACROSSCYCLES,
'U',
	 C.EVENTNO,
	 C.EVENTCODE,
	 C.EVENTDESCRIPTION,
	 C.NUMCYCLESALLOWED,
	 C.IMPORTANCELEVEL,
	 C.CONTROLLINGACTION,
	 C.DEFINITION,
	 C.CLIENTIMPLEVEL,
	 C.CATEGORYID,
	 C.PROFILEREFNO,
	 C.RECALCEVENTDATE,
	 C.DRAFTEVENTNO,
	 C.EVENTGROUP,
	 C.ACCOUNTINGEVENTFLAG,
	 C.POLICINGIMMEDIATE,
	 C.SUPPRESSCALCULATION,
	 C.NOTEGROUP,
	 C.NOTESSHAREDACROSSCYCLES
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

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTS]') and xtype='U')
begin
	drop table CCImport_EVENTS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_EVENTS  to public
go
