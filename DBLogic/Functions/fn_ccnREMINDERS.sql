-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnREMINDERS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnREMINDERS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnREMINDERS.'
	drop function dbo.fn_ccnREMINDERS
	print '**** Creating function dbo.fn_ccnREMINDERS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_REMINDERS]') and xtype='U')
begin
	select * 
	into CCImport_REMINDERS 
	from REMINDERS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnREMINDERS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnREMINDERS
-- VERSION :	2
-- DESCRIPTION:	The SELECT to display of imported data for the REMINDERS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
-- 11 Apr 2017	MF	71020	2	New columns added.
--
As 
Return
select	5 as TRIPNO, 'REMINDERS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_REMINDERS I 
	right join REMINDERS C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO
and  C.REMINDERNO=I.REMINDERNO)
where I.CRITERIANO is null
UNION ALL 
select	5, 'REMINDERS', 0, count(*), 0, 0
from CCImport_REMINDERS I 
	left join REMINDERS C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO
and  C.REMINDERNO=I.REMINDERNO)
where C.CRITERIANO is null
UNION ALL 
 select	5, 'REMINDERS', 0, 0, count(*), 0
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
UNION ALL 
 select	5, 'REMINDERS', 0, 0, 0, count(*)
from CCImport_REMINDERS I 
join REMINDERS C	on( C.CRITERIANO=I.CRITERIANO
and C.EVENTNO=I.EVENTNO
and C.REMINDERNO=I.REMINDERNO)
where ( I.PERIODTYPE =  C.PERIODTYPE OR (I.PERIODTYPE is null and C.PERIODTYPE is null))
and ( I.LEADTIME =  C.LEADTIME OR (I.LEADTIME is null and C.LEADTIME is null))
and ( I.FREQUENCY =  C.FREQUENCY OR (I.FREQUENCY is null and C.FREQUENCY is null))
and ( I.STOPTIME =  C.STOPTIME OR (I.STOPTIME is null and C.STOPTIME is null))
and ( I.UPDATEEVENT =  C.UPDATEEVENT OR (I.UPDATEEVENT is null and C.UPDATEEVENT is null))
and ( I.LETTERNO =  C.LETTERNO OR (I.LETTERNO is null and C.LETTERNO is null))
and ( I.CHECKOVERRIDE =  C.CHECKOVERRIDE OR (I.CHECKOVERRIDE is null and C.CHECKOVERRIDE is null))
and ( I.MAXLETTERS =  C.MAXLETTERS OR (I.MAXLETTERS is null and C.MAXLETTERS is null))
and ( I.LETTERFEE =  C.LETTERFEE OR (I.LETTERFEE is null and C.LETTERFEE is null))
and ( I.PAYFEECODE =  C.PAYFEECODE OR (I.PAYFEECODE is null and C.PAYFEECODE is null))
and ( I.EMPLOYEEFLAG =  C.EMPLOYEEFLAG OR (I.EMPLOYEEFLAG is null and C.EMPLOYEEFLAG is null))
and ( I.SIGNATORYFLAG =  C.SIGNATORYFLAG OR (I.SIGNATORYFLAG is null and C.SIGNATORYFLAG is null))
and ( I.INSTRUCTORFLAG =  C.INSTRUCTORFLAG OR (I.INSTRUCTORFLAG is null and C.INSTRUCTORFLAG is null))
and ( I.CRITICALFLAG =  C.CRITICALFLAG OR (I.CRITICALFLAG is null and C.CRITICALFLAG is null))
and ( I.REMINDEMPLOYEE =  C.REMINDEMPLOYEE OR (I.REMINDEMPLOYEE is null and C.REMINDEMPLOYEE is null))
and ( I.USEMESSAGE1 =  C.USEMESSAGE1 OR (I.USEMESSAGE1 is null and C.USEMESSAGE1 is null))
and ( replace(CAST(I.MESSAGE1 as NVARCHAR(MAX)),char(10),char(13)+char(10)) =  CAST(C.MESSAGE1 as NVARCHAR(MAX)) OR (I.MESSAGE1 is null and C.MESSAGE1 is null))
and ( replace(CAST(I.MESSAGE2 as NVARCHAR(MAX)),char(10),char(13)+char(10)) =  CAST(C.MESSAGE2 as NVARCHAR(MAX)) OR (I.MESSAGE2 is null and C.MESSAGE2 is null))
and ( I.INHERITED =  C.INHERITED OR (I.INHERITED is null and C.INHERITED is null))
and ( I.NAMETYPE =  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is null))
and ( I.SENDELECTRONICALLY =  C.SENDELECTRONICALLY OR (I.SENDELECTRONICALLY is null and C.SENDELECTRONICALLY is null))
and ( I.EMAILSUBJECT =  C.EMAILSUBJECT OR (I.EMAILSUBJECT is null and C.EMAILSUBJECT is null))
and ( I.ESTIMATEFLAG =  C.ESTIMATEFLAG OR (I.ESTIMATEFLAG is null and C.ESTIMATEFLAG is null))
and ( I.FREQPERIODTYPE =  C.FREQPERIODTYPE OR (I.FREQPERIODTYPE is null and C.FREQPERIODTYPE is null))
and ( I.STOPTIMEPERIODTYPE =  C.STOPTIMEPERIODTYPE OR (I.STOPTIMEPERIODTYPE is null and C.STOPTIMEPERIODTYPE is null))
and ( I.DIRECTPAYFLAG =  C.DIRECTPAYFLAG OR (I.DIRECTPAYFLAG is null and C.DIRECTPAYFLAG is null))
and ( I.RELATIONSHIP =  C.RELATIONSHIP OR (I.RELATIONSHIP is null and C.RELATIONSHIP is null))
and ( I.EXTENDEDNAMETYPE = C.EXTENDEDNAMETYPE OR (I.EXTENDEDNAMETYPE is null and C.EXTENDEDNAMETYPE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_REMINDERS]') and xtype='U')
begin
	drop table CCImport_REMINDERS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnREMINDERS  to public
go
