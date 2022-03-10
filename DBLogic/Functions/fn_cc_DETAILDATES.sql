-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_DETAILDATES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_DETAILDATES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_DETAILDATES.'
	drop function dbo.fn_cc_DETAILDATES
	print '**** Creating function dbo.fn_cc_DETAILDATES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_DETAILDATES]') and xtype='U')
begin
	select * 
	into CCImport_DETAILDATES 
	from DETAILDATES
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_DETAILDATES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_DETAILDATES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the DETAILDATES table
-- CALLED BY :	ip_CopyConfigDETAILDATES
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
	 null as 'Imported Entrynumber',
	 null as 'Imported Eventno',
	 null as 'Imported Othereventno',
	 null as 'Imported Defaultflag',
	 null as 'Imported Eventattribute',
	 null as 'Imported Dueattribute',
	 null as 'Imported Policingattribute',
	 null as 'Imported Periodattribute',
	 null as 'Imported Ovreventattribute',
	 null as 'Imported Ovrdueattribute',
	 null as 'Imported Journalattribute',
	 null as 'Imported Displaysequence',
	 null as 'Imported Inherited',
	 null as 'Imported Duedaterespattribute',
'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.ENTRYNUMBER as 'Entrynumber',
	 C.EVENTNO as 'Eventno',
	 C.OTHEREVENTNO as 'Othereventno',
	 C.DEFAULTFLAG as 'Defaultflag',
	 C.EVENTATTRIBUTE as 'Eventattribute',
	 C.DUEATTRIBUTE as 'Dueattribute',
	 C.POLICINGATTRIBUTE as 'Policingattribute',
	 C.PERIODATTRIBUTE as 'Periodattribute',
	 C.OVREVENTATTRIBUTE as 'Ovreventattribute',
	 C.OVRDUEATTRIBUTE as 'Ovrdueattribute',
	 C.JOURNALATTRIBUTE as 'Journalattribute',
	 C.DISPLAYSEQUENCE as 'Displaysequence',
	 C.INHERITED as 'Inherited',
	 C.DUEDATERESPATTRIBUTE as 'Duedaterespattribute'
from CCImport_DETAILDATES I 
	right join DETAILDATES C on( C.CRITERIANO=I.CRITERIANO
and  C.ENTRYNUMBER=I.ENTRYNUMBER
and  C.EVENTNO=I.EVENTNO)
where I.CRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.ENTRYNUMBER,
	 I.EVENTNO,
	 I.OTHEREVENTNO,
	 I.DEFAULTFLAG,
	 I.EVENTATTRIBUTE,
	 I.DUEATTRIBUTE,
	 I.POLICINGATTRIBUTE,
	 I.PERIODATTRIBUTE,
	 I.OVREVENTATTRIBUTE,
	 I.OVRDUEATTRIBUTE,
	 I.JOURNALATTRIBUTE,
	 I.DISPLAYSEQUENCE,
	 I.INHERITED,
	 I.DUEDATERESPATTRIBUTE,
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
	 null
from CCImport_DETAILDATES I 
	left join DETAILDATES C on( C.CRITERIANO=I.CRITERIANO
and  C.ENTRYNUMBER=I.ENTRYNUMBER
and  C.EVENTNO=I.EVENTNO)
where C.CRITERIANO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIANO,
	 I.ENTRYNUMBER,
	 I.EVENTNO,
	 I.OTHEREVENTNO,
	 I.DEFAULTFLAG,
	 I.EVENTATTRIBUTE,
	 I.DUEATTRIBUTE,
	 I.POLICINGATTRIBUTE,
	 I.PERIODATTRIBUTE,
	 I.OVREVENTATTRIBUTE,
	 I.OVRDUEATTRIBUTE,
	 I.JOURNALATTRIBUTE,
	 I.DISPLAYSEQUENCE,
	 I.INHERITED,
	 I.DUEDATERESPATTRIBUTE,
'U',
	 C.CRITERIANO,
	 C.ENTRYNUMBER,
	 C.EVENTNO,
	 C.OTHEREVENTNO,
	 C.DEFAULTFLAG,
	 C.EVENTATTRIBUTE,
	 C.DUEATTRIBUTE,
	 C.POLICINGATTRIBUTE,
	 C.PERIODATTRIBUTE,
	 C.OVREVENTATTRIBUTE,
	 C.OVRDUEATTRIBUTE,
	 C.JOURNALATTRIBUTE,
	 C.DISPLAYSEQUENCE,
	 C.INHERITED,
	 C.DUEDATERESPATTRIBUTE
from CCImport_DETAILDATES I 
	join DETAILDATES C	on ( C.CRITERIANO=I.CRITERIANO
	and C.ENTRYNUMBER=I.ENTRYNUMBER
	and C.EVENTNO=I.EVENTNO)
where 	( I.OTHEREVENTNO <>  C.OTHEREVENTNO OR (I.OTHEREVENTNO is null and C.OTHEREVENTNO is not null) 
OR (I.OTHEREVENTNO is not null and C.OTHEREVENTNO is null))
	OR 	( I.DEFAULTFLAG <>  C.DEFAULTFLAG OR (I.DEFAULTFLAG is null and C.DEFAULTFLAG is not null) 
OR (I.DEFAULTFLAG is not null and C.DEFAULTFLAG is null))
	OR 	( I.EVENTATTRIBUTE <>  C.EVENTATTRIBUTE OR (I.EVENTATTRIBUTE is null and C.EVENTATTRIBUTE is not null) 
OR (I.EVENTATTRIBUTE is not null and C.EVENTATTRIBUTE is null))
	OR 	( I.DUEATTRIBUTE <>  C.DUEATTRIBUTE OR (I.DUEATTRIBUTE is null and C.DUEATTRIBUTE is not null) 
OR (I.DUEATTRIBUTE is not null and C.DUEATTRIBUTE is null))
	OR 	( I.POLICINGATTRIBUTE <>  C.POLICINGATTRIBUTE OR (I.POLICINGATTRIBUTE is null and C.POLICINGATTRIBUTE is not null) 
OR (I.POLICINGATTRIBUTE is not null and C.POLICINGATTRIBUTE is null))
	OR 	( I.PERIODATTRIBUTE <>  C.PERIODATTRIBUTE OR (I.PERIODATTRIBUTE is null and C.PERIODATTRIBUTE is not null) 
OR (I.PERIODATTRIBUTE is not null and C.PERIODATTRIBUTE is null))
	OR 	( I.OVREVENTATTRIBUTE <>  C.OVREVENTATTRIBUTE OR (I.OVREVENTATTRIBUTE is null and C.OVREVENTATTRIBUTE is not null) 
OR (I.OVREVENTATTRIBUTE is not null and C.OVREVENTATTRIBUTE is null))
	OR 	( I.OVRDUEATTRIBUTE <>  C.OVRDUEATTRIBUTE OR (I.OVRDUEATTRIBUTE is null and C.OVRDUEATTRIBUTE is not null) 
OR (I.OVRDUEATTRIBUTE is not null and C.OVRDUEATTRIBUTE is null))
	OR 	( I.JOURNALATTRIBUTE <>  C.JOURNALATTRIBUTE OR (I.JOURNALATTRIBUTE is null and C.JOURNALATTRIBUTE is not null) 
OR (I.JOURNALATTRIBUTE is not null and C.JOURNALATTRIBUTE is null))
	OR 	( I.DISPLAYSEQUENCE <>  C.DISPLAYSEQUENCE OR (I.DISPLAYSEQUENCE is null and C.DISPLAYSEQUENCE is not null) 
OR (I.DISPLAYSEQUENCE is not null and C.DISPLAYSEQUENCE is null))
	OR 	( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null) 
OR (I.INHERITED is not null and C.INHERITED is null))
	OR 	( I.DUEDATERESPATTRIBUTE <>  C.DUEDATERESPATTRIBUTE OR (I.DUEDATERESPATTRIBUTE is null and C.DUEDATERESPATTRIBUTE is not null) 
OR (I.DUEDATERESPATTRIBUTE is not null and C.DUEDATERESPATTRIBUTE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DETAILDATES]') and xtype='U')
begin
	drop table CCImport_DETAILDATES 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_DETAILDATES  to public
go
