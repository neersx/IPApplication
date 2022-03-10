-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_REMINDERS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_REMINDERS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_REMINDERS.'
	drop function dbo.fn_cc_REMINDERS
	print '**** Creating function dbo.fn_cc_REMINDERS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_REMINDERS]') and xtype='U')
begin
	select * 
	into CCImport_REMINDERS 
	from REMINDERS
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_REMINDERS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_REMINDERS
-- VERSION :	2
-- DESCRIPTION:	The SELECT to display of imported data for the REMINDERS table
-- CALLED BY :	ip_CopyConfigREMINDERS
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
-- 03 Apr 2017	MF	71020	2	New columns added.
--
As 
Return
select	1 as 'Switch',
	'X' as 'Match',
	'D' as 'Imported -',
	 null as 'Imported Criteriano',
	 null as 'Imported Eventno',
	 null as 'Imported Reminderno',
	 null as 'Imported Periodtype',
	 null as 'Imported Leadtime',
	 null as 'Imported Frequency',
	 null as 'Imported Stoptime',
	 null as 'Imported Updateevent',
	 null as 'Imported Letterno',
	 null as 'Imported Checkoverride',
	 null as 'Imported Maxletters',
	 null as 'Imported Letterfee',
	 null as 'Imported Payfeecode',
	 null as 'Imported Employeeflag',
	 null as 'Imported Signatoryflag',
	 null as 'Imported Instructorflag',
	 null as 'Imported Criticalflag',
	 null as 'Imported Remindemployee',
	 null as 'Imported Usemessage1',
	 null as 'Imported Message1',
	 null as 'Imported Message2',
	 null as 'Imported Inherited',
	 null as 'Imported Nametype',
	 null as 'Imported Sendelectronically',
	 null as 'Imported Emailsubject',
	 null as 'Imported Estimateflag',
	 null as 'Imported Freqperiodtype',
	 null as 'Imported Stoptimeperiodtype',
	 null as 'Imported Directpayflag',
	 null as 'Imported Relationship',
	 null as 'Imported Extendednametype',
	'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.EVENTNO as 'Eventno',
	 C.REMINDERNO as 'Reminderno',
	 C.PERIODTYPE as 'Periodtype',
	 C.LEADTIME as 'Leadtime',
	 C.FREQUENCY as 'Frequency',
	 C.STOPTIME as 'Stoptime',
	 C.UPDATEEVENT as 'Updateevent',
	 C.LETTERNO as 'Letterno',
	 C.CHECKOVERRIDE as 'Checkoverride',
	 C.MAXLETTERS as 'Maxletters',
	 C.LETTERFEE as 'Letterfee',
	 C.PAYFEECODE as 'Payfeecode',
	 C.EMPLOYEEFLAG as 'Employeeflag',
	 C.SIGNATORYFLAG as 'Signatoryflag',
	 C.INSTRUCTORFLAG as 'Instructorflag',
	 C.CRITICALFLAG as 'Criticalflag',
	 C.REMINDEMPLOYEE as 'Remindemployee',
	 C.USEMESSAGE1 as 'Usemessage1',
	 CAST(C.MESSAGE1 AS NVARCHAR(4000)) as 'Message1',
	 CAST(C.MESSAGE2 AS NVARCHAR(4000)) as 'Message2',
	 C.INHERITED as 'Inherited',
	 C.NAMETYPE as 'Nametype',
	 C.SENDELECTRONICALLY as 'Sendelectronically',
	 C.EMAILSUBJECT as 'Emailsubject',
	 C.ESTIMATEFLAG as 'Estimateflag',
	 C.FREQPERIODTYPE as 'Freqperiodtype',
	 C.STOPTIMEPERIODTYPE as 'Stoptimeperiodtype',
	 C.DIRECTPAYFLAG as 'Directpayflag',
	 C.RELATIONSHIP as 'Relationship',
	 C.EXTENDEDNAMETYPE as 'Extendednametype'
from CCImport_REMINDERS I 
	right join REMINDERS C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO
and  C.REMINDERNO=I.REMINDERNO)
where I.CRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.EVENTNO,
	 I.REMINDERNO,
	 I.PERIODTYPE,
	 I.LEADTIME,
	 I.FREQUENCY,
	 I.STOPTIME,
	 I.UPDATEEVENT,
	 I.LETTERNO,
	 I.CHECKOVERRIDE,
	 I.MAXLETTERS,
	 I.LETTERFEE,
	 I.PAYFEECODE,
	 I.EMPLOYEEFLAG,
	 I.SIGNATORYFLAG,
	 I.INSTRUCTORFLAG,
	 I.CRITICALFLAG,
	 I.REMINDEMPLOYEE,
	 I.USEMESSAGE1,
	 CAST(I.MESSAGE1 AS NVARCHAR(4000)),
	 CAST(I.MESSAGE2 AS NVARCHAR(4000)),
	 I.INHERITED,
	 I.NAMETYPE,
	 I.SENDELECTRONICALLY,
	 I.EMAILSUBJECT,
	 I.ESTIMATEFLAG,
	 I.FREQPERIODTYPE,
	 I.STOPTIMEPERIODTYPE,
	 I.DIRECTPAYFLAG,
	 I.RELATIONSHIP,
	 I.EXTENDEDNAMETYPE,
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
from CCImport_REMINDERS I 
	left join REMINDERS C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO
and  C.REMINDERNO=I.REMINDERNO)
where C.CRITERIANO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIANO,
	 I.EVENTNO,
	 I.REMINDERNO,
	 I.PERIODTYPE,
	 I.LEADTIME,
	 I.FREQUENCY,
	 I.STOPTIME,
	 I.UPDATEEVENT,
	 I.LETTERNO,
	 I.CHECKOVERRIDE,
	 I.MAXLETTERS,
	 I.LETTERFEE,
	 I.PAYFEECODE,
	 I.EMPLOYEEFLAG,
	 I.SIGNATORYFLAG,
	 I.INSTRUCTORFLAG,
	 I.CRITICALFLAG,
	 I.REMINDEMPLOYEE,
	 I.USEMESSAGE1,
	 CAST(I.MESSAGE1 AS NVARCHAR(4000)),
	 CAST(I.MESSAGE2 AS NVARCHAR(4000)),
	 I.INHERITED,
	 I.NAMETYPE,
	 I.SENDELECTRONICALLY,
	 I.EMAILSUBJECT,
	 I.ESTIMATEFLAG,
	 I.FREQPERIODTYPE,
	 I.STOPTIMEPERIODTYPE,
	 I.DIRECTPAYFLAG,
	 I.RELATIONSHIP,
	 I.EXTENDEDNAMETYPE,
	'U',
	 C.CRITERIANO,
	 C.EVENTNO,
	 C.REMINDERNO,
	 C.PERIODTYPE,
	 C.LEADTIME,
	 C.FREQUENCY,
	 C.STOPTIME,
	 C.UPDATEEVENT,
	 C.LETTERNO,
	 C.CHECKOVERRIDE,
	 C.MAXLETTERS,
	 C.LETTERFEE,
	 C.PAYFEECODE,
	 C.EMPLOYEEFLAG,
	 C.SIGNATORYFLAG,
	 C.INSTRUCTORFLAG,
	 C.CRITICALFLAG,
	 C.REMINDEMPLOYEE,
	 C.USEMESSAGE1,
	 CAST(C.MESSAGE1 AS NVARCHAR(4000)),
	 CAST(C.MESSAGE2 AS NVARCHAR(4000)),
	 C.INHERITED,
	 C.NAMETYPE,
	 C.SENDELECTRONICALLY,
	 C.EMAILSUBJECT,
	 C.ESTIMATEFLAG,
	 C.FREQPERIODTYPE,
	 C.STOPTIMEPERIODTYPE,
	 C.DIRECTPAYFLAG,
	 C.RELATIONSHIP,
	 C.EXTENDEDNAMETYPE
from CCImport_REMINDERS I 
	join REMINDERS C	on ( C.CRITERIANO=I.CRITERIANO
	and C.EVENTNO=I.EVENTNO
	and C.REMINDERNO=I.REMINDERNO)
where 	( I.PERIODTYPE <>  C.PERIODTYPE OR (I.PERIODTYPE is null and C.PERIODTYPE is not null) 
OR (I.PERIODTYPE is not null and C.PERIODTYPE is null))
	OR 	( I.LEADTIME <>  C.LEADTIME OR (I.LEADTIME is null and C.LEADTIME is not null) 
OR (I.LEADTIME is not null and C.LEADTIME is null))
	OR 	( I.FREQUENCY <>  C.FREQUENCY OR (I.FREQUENCY is null and C.FREQUENCY is not null) 
OR (I.FREQUENCY is not null and C.FREQUENCY is null))
	OR 	( I.STOPTIME <>  C.STOPTIME OR (I.STOPTIME is null and C.STOPTIME is not null) 
OR (I.STOPTIME is not null and C.STOPTIME is null))
	OR 	( I.UPDATEEVENT <>  C.UPDATEEVENT OR (I.UPDATEEVENT is null and C.UPDATEEVENT is not null) 
OR (I.UPDATEEVENT is not null and C.UPDATEEVENT is null))
	OR 	( I.LETTERNO <>  C.LETTERNO OR (I.LETTERNO is null and C.LETTERNO is not null) 
OR (I.LETTERNO is not null and C.LETTERNO is null))
	OR 	( I.CHECKOVERRIDE <>  C.CHECKOVERRIDE OR (I.CHECKOVERRIDE is null and C.CHECKOVERRIDE is not null) 
OR (I.CHECKOVERRIDE is not null and C.CHECKOVERRIDE is null))
	OR 	( I.MAXLETTERS <>  C.MAXLETTERS OR (I.MAXLETTERS is null and C.MAXLETTERS is not null) 
OR (I.MAXLETTERS is not null and C.MAXLETTERS is null))
	OR 	( I.LETTERFEE <>  C.LETTERFEE OR (I.LETTERFEE is null and C.LETTERFEE is not null) 
OR (I.LETTERFEE is not null and C.LETTERFEE is null))
	OR 	( I.PAYFEECODE <>  C.PAYFEECODE OR (I.PAYFEECODE is null and C.PAYFEECODE is not null) 
OR (I.PAYFEECODE is not null and C.PAYFEECODE is null))
	OR 	( I.EMPLOYEEFLAG <>  C.EMPLOYEEFLAG OR (I.EMPLOYEEFLAG is null and C.EMPLOYEEFLAG is not null) 
OR (I.EMPLOYEEFLAG is not null and C.EMPLOYEEFLAG is null))
	OR 	( I.SIGNATORYFLAG <>  C.SIGNATORYFLAG OR (I.SIGNATORYFLAG is null and C.SIGNATORYFLAG is not null) 
OR (I.SIGNATORYFLAG is not null and C.SIGNATORYFLAG is null))
	OR 	( I.INSTRUCTORFLAG <>  C.INSTRUCTORFLAG OR (I.INSTRUCTORFLAG is null and C.INSTRUCTORFLAG is not null) 
OR (I.INSTRUCTORFLAG is not null and C.INSTRUCTORFLAG is null))
	OR 	( I.CRITICALFLAG <>  C.CRITICALFLAG OR (I.CRITICALFLAG is null and C.CRITICALFLAG is not null) 
OR (I.CRITICALFLAG is not null and C.CRITICALFLAG is null))
	OR 	( I.REMINDEMPLOYEE <>  C.REMINDEMPLOYEE OR (I.REMINDEMPLOYEE is null and C.REMINDEMPLOYEE is not null) 
OR (I.REMINDEMPLOYEE is not null and C.REMINDEMPLOYEE is null))
	OR 	( I.USEMESSAGE1 <>  C.USEMESSAGE1 OR (I.USEMESSAGE1 is null and C.USEMESSAGE1 is not null) 
OR (I.USEMESSAGE1 is not null and C.USEMESSAGE1 is null))
	OR 	( replace(CAST(I.MESSAGE1 as NVARCHAR(MAX)),char(10),char(13)+char(10)) <>  CAST(C.MESSAGE1 as NVARCHAR(MAX)) OR (I.MESSAGE1 is null and C.MESSAGE1 is not null) 
OR (I.MESSAGE1 is not null and C.MESSAGE1 is null))
	OR 	( replace(CAST(I.MESSAGE2 as NVARCHAR(MAX)),char(10),char(13)+char(10)) <>  CAST(C.MESSAGE2 as NVARCHAR(MAX)) OR (I.MESSAGE2 is null and C.MESSAGE2 is not null) 
OR (I.MESSAGE2 is not null and C.MESSAGE2 is null))
	OR 	( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null) 
OR (I.INHERITED is not null and C.INHERITED is null))
	OR 	( I.NAMETYPE <>  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is not null) 
OR (I.NAMETYPE is not null and C.NAMETYPE is null))
	OR 	( I.SENDELECTRONICALLY <>  C.SENDELECTRONICALLY OR (I.SENDELECTRONICALLY is null and C.SENDELECTRONICALLY is not null) 
OR (I.SENDELECTRONICALLY is not null and C.SENDELECTRONICALLY is null))
	OR 	( I.EMAILSUBJECT <>  C.EMAILSUBJECT OR (I.EMAILSUBJECT is null and C.EMAILSUBJECT is not null) 
OR (I.EMAILSUBJECT is not null and C.EMAILSUBJECT is null))
	OR 	( I.ESTIMATEFLAG <>  C.ESTIMATEFLAG OR (I.ESTIMATEFLAG is null and C.ESTIMATEFLAG is not null) 
OR (I.ESTIMATEFLAG is not null and C.ESTIMATEFLAG is null))
	OR 	( I.FREQPERIODTYPE <>  C.FREQPERIODTYPE OR (I.FREQPERIODTYPE is null and C.FREQPERIODTYPE is not null) 
OR (I.FREQPERIODTYPE is not null and C.FREQPERIODTYPE is null))
	OR 	( I.STOPTIMEPERIODTYPE <>  C.STOPTIMEPERIODTYPE OR (I.STOPTIMEPERIODTYPE is null and C.STOPTIMEPERIODTYPE is not null) 
OR (I.STOPTIMEPERIODTYPE is not null and C.STOPTIMEPERIODTYPE is null))
	OR 	( I.DIRECTPAYFLAG <>  C.DIRECTPAYFLAG OR (I.DIRECTPAYFLAG is null and C.DIRECTPAYFLAG is not null) 
OR (I.DIRECTPAYFLAG is not null and C.DIRECTPAYFLAG is null))
	OR 	( I.RELATIONSHIP <>  C.RELATIONSHIP OR (I.RELATIONSHIP is null and C.RELATIONSHIP is not null) 
OR (I.RELATIONSHIP is not null and C.RELATIONSHIP is null))
	OR 	( I.EXTENDEDNAMETYPE <>  C.EXTENDEDNAMETYPE OR (I.EXTENDEDNAMETYPE is null and C.EXTENDEDNAMETYPE is not null) 
OR (I.EXTENDEDNAMETYPE is not null and C.EXTENDEDNAMETYPE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_REMINDERS]') and xtype='U')
begin
	drop table CCImport_REMINDERS 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_REMINDERS  to public
go
