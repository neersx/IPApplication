-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_EVENTSREPLACED
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_EVENTSREPLACED]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_EVENTSREPLACED.'
	drop function dbo.fn_cc_EVENTSREPLACED
	print '**** Creating function dbo.fn_cc_EVENTSREPLACED...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
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


CREATE FUNCTION dbo.fn_cc_EVENTSREPLACED
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_EVENTSREPLACED
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the EVENTSREPLACED table
-- CALLED BY :	ip_CopyConfigEVENTSREPLACED
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
	 null as 'Imported Oldeventno',
	 null as 'Imported Eventno',
'D' as '-',
	 C.OLDEVENTNO as 'Oldeventno',
	 C.EVENTNO as 'Eventno'
from CCImport_EVENTSREPLACED I 
	right join EVENTSREPLACED C on( C.OLDEVENTNO=I.OLDEVENTNO)
where I.OLDEVENTNO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.OLDEVENTNO,
	 I.EVENTNO,
'I',
	 null ,
	 null
from CCImport_EVENTSREPLACED I 
	left join EVENTSREPLACED C on( C.OLDEVENTNO=I.OLDEVENTNO)
where C.OLDEVENTNO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.OLDEVENTNO,
	 I.EVENTNO,
'U',
	 C.OLDEVENTNO,
	 C.EVENTNO
from CCImport_EVENTSREPLACED I 
	join EVENTSREPLACED C	on ( C.OLDEVENTNO=I.OLDEVENTNO)
where 	( I.EVENTNO <>  C.EVENTNO OR (I.EVENTNO is null and C.EVENTNO is not null) 
OR (I.EVENTNO is not null and C.EVENTNO is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTSREPLACED]') and xtype='U')
begin
	drop table CCImport_EVENTSREPLACED 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_EVENTSREPLACED  to public
go

