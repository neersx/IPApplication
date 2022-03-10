-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_EVENTCONTROLREQEVE_
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_EVENTCONTROLREQEVE_]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_EVENTCONTROLREQEVE_.'
	drop function dbo.fn_cc_EVENTCONTROLREQEVE_
	print '**** Creating function dbo.fn_cc_EVENTCONTROLREQEVE_...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
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


CREATE FUNCTION dbo.fn_cc_EVENTCONTROLREQEVE_
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_EVENTCONTROLREQEVE_
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the EVENTCONTROLREQEVENT table
-- CALLED BY :	ip_CopyConfigEVENTCONTROLREQEVE_
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
	 null as 'Imported Reqeventno',
	 null as 'Imported Inherited',
'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.EVENTNO as 'Eventno',
	 C.REQEVENTNO as 'Reqeventno',
	 C.INHERITED as 'Inherited'
from CCImport_EVENTCONTROLREQEVENT I 
	right join EVENTCONTROLREQEVENT C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO
and  C.REQEVENTNO=I.REQEVENTNO)
where I.CRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.EVENTNO,
	 I.REQEVENTNO,
	 I.INHERITED,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_EVENTCONTROLREQEVENT I 
	left join EVENTCONTROLREQEVENT C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO
and  C.REQEVENTNO=I.REQEVENTNO)
where C.CRITERIANO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIANO,
	 I.EVENTNO,
	 I.REQEVENTNO,
	 I.INHERITED,
'U',
	 C.CRITERIANO,
	 C.EVENTNO,
	 C.REQEVENTNO,
	 C.INHERITED
from CCImport_EVENTCONTROLREQEVENT I 
	join EVENTCONTROLREQEVENT C	on ( C.CRITERIANO=I.CRITERIANO
	and C.EVENTNO=I.EVENTNO
	and C.REQEVENTNO=I.REQEVENTNO)
where 	( I.INHERITED <>  C.INHERITED)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTCONTROLREQEVENT]') and xtype='U')
begin
	drop table CCImport_EVENTCONTROLREQEVENT 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_EVENTCONTROLREQEVE_  to public
go

