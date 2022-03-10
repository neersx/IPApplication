-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_EDERULECASEEVENT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_EDERULECASEEVENT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_EDERULECASEEVENT.'
	drop function dbo.fn_cc_EDERULECASEEVENT
	print '**** Creating function dbo.fn_cc_EDERULECASEEVENT...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
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


CREATE FUNCTION dbo.fn_cc_EDERULECASEEVENT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_EDERULECASEEVENT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the EDERULECASEEVENT table
-- CALLED BY :	ip_CopyConfigEDERULECASEEVENT
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
	 null as 'Imported Criteriano',
	 null as 'Imported Eventno',
	 null as 'Imported Eventdate',
	 null as 'Imported Eventduedate',
	 null as 'Imported Eventtext',
'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.EVENTNO as 'Eventno',
	 C.EVENTDATE as 'Eventdate',
	 C.EVENTDUEDATE as 'Eventduedate',
	 C.EVENTTEXT as 'Eventtext'
from CCImport_EDERULECASEEVENT I 
	right join EDERULECASEEVENT C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO)
where I.CRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.EVENTNO,
	 I.EVENTDATE,
	 I.EVENTDUEDATE,
	 I.EVENTTEXT,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_EDERULECASEEVENT I 
	left join EDERULECASEEVENT C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO)
where C.CRITERIANO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIANO,
	 I.EVENTNO,
	 I.EVENTDATE,
	 I.EVENTDUEDATE,
	 I.EVENTTEXT,
'U',
	 C.CRITERIANO,
	 C.EVENTNO,
	 C.EVENTDATE,
	 C.EVENTDUEDATE,
	 C.EVENTTEXT
from CCImport_EDERULECASEEVENT I 
	join EDERULECASEEVENT C	on ( C.CRITERIANO=I.CRITERIANO
	and C.EVENTNO=I.EVENTNO)
where 	( I.EVENTDATE <>  C.EVENTDATE OR (I.EVENTDATE is null and C.EVENTDATE is not null) 
OR (I.EVENTDATE is not null and C.EVENTDATE is null))
	OR 	( I.EVENTDUEDATE <>  C.EVENTDUEDATE OR (I.EVENTDUEDATE is null and C.EVENTDUEDATE is not null) 
OR (I.EVENTDUEDATE is not null and C.EVENTDUEDATE is null))
	OR 	( I.EVENTTEXT <>  C.EVENTTEXT OR (I.EVENTTEXT is null and C.EVENTTEXT is not null) 
OR (I.EVENTTEXT is not null and C.EVENTTEXT is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EDERULECASEEVENT]') and xtype='U')
begin
	drop table CCImport_EDERULECASEEVENT 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_EDERULECASEEVENT  to public
go

