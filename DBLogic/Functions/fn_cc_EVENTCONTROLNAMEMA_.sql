-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_EVENTCONTROLNAMEMA_
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_EVENTCONTROLNAMEMA_]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_EVENTCONTROLNAMEMA_.'
	drop function dbo.fn_cc_EVENTCONTROLNAMEMA_
	print '**** Creating function dbo.fn_cc_EVENTCONTROLNAMEMA_...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTCONTROLNAMEMAP]') and xtype='U')
begin
	select * 
	into CCImport_EVENTCONTROLNAMEMAP 
	from EVENTCONTROLNAMEMAP
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_EVENTCONTROLNAMEMA_
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_EVENTCONTROLNAMEMA_
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the EVENTCONTROLNAMEMAP table
-- CALLED BY :	ip_CopyConfigEVENTCONTROLNAMEMA_
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
	 null as 'Imported Sequenceno',
	 null as 'Imported Applicablenametype',
	 null as 'Imported Substitutenametype',
	 null as 'Imported Mustexist',
	 null as 'Imported Inherited',
'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.EVENTNO as 'Eventno',
	 C.SEQUENCENO as 'Sequenceno',
	 C.APPLICABLENAMETYPE as 'Applicablenametype',
	 C.SUBSTITUTENAMETYPE as 'Substitutenametype',
	 C.MUSTEXIST as 'Mustexist',
	 C.INHERITED as 'Inherited'
from CCImport_EVENTCONTROLNAMEMAP I 
	right join EVENTCONTROLNAMEMAP C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO
and  C.SEQUENCENO=I.SEQUENCENO)
where I.CRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.EVENTNO,
	 I.SEQUENCENO,
	 I.APPLICABLENAMETYPE,
	 I.SUBSTITUTENAMETYPE,
	 I.MUSTEXIST,
	 I.INHERITED,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_EVENTCONTROLNAMEMAP I 
	left join EVENTCONTROLNAMEMAP C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO
and  C.SEQUENCENO=I.SEQUENCENO)
where C.CRITERIANO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIANO,
	 I.EVENTNO,
	 I.SEQUENCENO,
	 I.APPLICABLENAMETYPE,
	 I.SUBSTITUTENAMETYPE,
	 I.MUSTEXIST,
	 I.INHERITED,
'U',
	 C.CRITERIANO,
	 C.EVENTNO,
	 C.SEQUENCENO,
	 C.APPLICABLENAMETYPE,
	 C.SUBSTITUTENAMETYPE,
	 C.MUSTEXIST,
	 C.INHERITED
from CCImport_EVENTCONTROLNAMEMAP I 
	join EVENTCONTROLNAMEMAP C	on ( C.CRITERIANO=I.CRITERIANO
	and C.EVENTNO=I.EVENTNO
	and C.SEQUENCENO=I.SEQUENCENO)
where 	( I.APPLICABLENAMETYPE <>  C.APPLICABLENAMETYPE)
	OR 	( I.SUBSTITUTENAMETYPE <>  C.SUBSTITUTENAMETYPE)
	OR 	( I.MUSTEXIST <>  C.MUSTEXIST OR (I.MUSTEXIST is null and C.MUSTEXIST is not null) 
OR (I.MUSTEXIST is not null and C.MUSTEXIST is null))
	OR 	( I.INHERITED <>  C.INHERITED)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTCONTROLNAMEMAP]') and xtype='U')
begin
	drop table CCImport_EVENTCONTROLNAMEMAP 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_EVENTCONTROLNAMEMA_  to public
go
