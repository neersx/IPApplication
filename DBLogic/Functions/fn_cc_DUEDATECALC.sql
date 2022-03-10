-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_DUEDATECALC
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_DUEDATECALC]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_DUEDATECALC.'
	drop function dbo.fn_cc_DUEDATECALC
	print '**** Creating function dbo.fn_cc_DUEDATECALC...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_DUEDATECALC]') and xtype='U')
begin
	select * 
	into CCImport_DUEDATECALC 
	from DUEDATECALC
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_DUEDATECALC
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_DUEDATECALC
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the DUEDATECALC table
-- CALLED BY :	ip_CopyConfigDUEDATECALC
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
	 null as 'Imported Sequence',
	 null as 'Imported Cyclenumber',
	 null as 'Imported Countrycode',
	 null as 'Imported Fromevent',
	 null as 'Imported Relativecycle',
	 null as 'Imported Operator',
	 null as 'Imported Deadlineperiod',
	 null as 'Imported Periodtype',
	 null as 'Imported Eventdateflag',
	 null as 'Imported Adjustment',
	 null as 'Imported Mustexist',
	 null as 'Imported Comparison',
	 null as 'Imported Compareevent',
	 null as 'Imported Workday',
	 null as 'Imported Message2flag',
	 null as 'Imported Suppressreminders',
	 null as 'Imported Overrideletter',
	 null as 'Imported Inherited',
	 null as 'Imported Compareeventflag',
	 null as 'Imported Comparecycle',
	 null as 'Imported Comparerelationship',
	 null as 'Imported Comparedate',
	 null as 'Imported Comparesystemdate',
'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.EVENTNO as 'Eventno',
	 C.SEQUENCE as 'Sequence',
	 C.CYCLENUMBER as 'Cyclenumber',
	 C.COUNTRYCODE as 'Countrycode',
	 C.FROMEVENT as 'Fromevent',
	 C.RELATIVECYCLE as 'Relativecycle',
	 C.OPERATOR as 'Operator',
	 C.DEADLINEPERIOD as 'Deadlineperiod',
	 C.PERIODTYPE as 'Periodtype',
	 C.EVENTDATEFLAG as 'Eventdateflag',
	 C.ADJUSTMENT as 'Adjustment',
	 C.MUSTEXIST as 'Mustexist',
	 C.COMPARISON as 'Comparison',
	 C.COMPAREEVENT as 'Compareevent',
	 C.WORKDAY as 'Workday',
	 C.MESSAGE2FLAG as 'Message2flag',
	 C.SUPPRESSREMINDERS as 'Suppressreminders',
	 C.OVERRIDELETTER as 'Overrideletter',
	 C.INHERITED as 'Inherited',
	 C.COMPAREEVENTFLAG as 'Compareeventflag',
	 C.COMPARECYCLE as 'Comparecycle',
	 C.COMPARERELATIONSHIP as 'Comparerelationship',
	 C.COMPAREDATE as 'Comparedate',
	 C.COMPARESYSTEMDATE as 'Comparesystemdate'
from CCImport_DUEDATECALC I 
	right join DUEDATECALC C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO
and  C.SEQUENCE=I.SEQUENCE)
where I.CRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.EVENTNO,
	 I.SEQUENCE,
	 I.CYCLENUMBER,
	 I.COUNTRYCODE,
	 I.FROMEVENT,
	 I.RELATIVECYCLE,
	 I.OPERATOR,
	 I.DEADLINEPERIOD,
	 I.PERIODTYPE,
	 I.EVENTDATEFLAG,
	 I.ADJUSTMENT,
	 I.MUSTEXIST,
	 I.COMPARISON,
	 I.COMPAREEVENT,
	 I.WORKDAY,
	 I.MESSAGE2FLAG,
	 I.SUPPRESSREMINDERS,
	 I.OVERRIDELETTER,
	 I.INHERITED,
	 I.COMPAREEVENTFLAG,
	 I.COMPARECYCLE,
	 I.COMPARERELATIONSHIP,
	 I.COMPAREDATE,
	 I.COMPARESYSTEMDATE,
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
	 null
from CCImport_DUEDATECALC I 
	left join DUEDATECALC C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO
and  C.SEQUENCE=I.SEQUENCE)
where C.CRITERIANO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIANO,
	 I.EVENTNO,
	 I.SEQUENCE,
	 I.CYCLENUMBER,
	 I.COUNTRYCODE,
	 I.FROMEVENT,
	 I.RELATIVECYCLE,
	 I.OPERATOR,
	 I.DEADLINEPERIOD,
	 I.PERIODTYPE,
	 I.EVENTDATEFLAG,
	 I.ADJUSTMENT,
	 I.MUSTEXIST,
	 I.COMPARISON,
	 I.COMPAREEVENT,
	 I.WORKDAY,
	 I.MESSAGE2FLAG,
	 I.SUPPRESSREMINDERS,
	 I.OVERRIDELETTER,
	 I.INHERITED,
	 I.COMPAREEVENTFLAG,
	 I.COMPARECYCLE,
	 I.COMPARERELATIONSHIP,
	 I.COMPAREDATE,
	 I.COMPARESYSTEMDATE,
'U',
	 C.CRITERIANO,
	 C.EVENTNO,
	 C.SEQUENCE,
	 C.CYCLENUMBER,
	 C.COUNTRYCODE,
	 C.FROMEVENT,
	 C.RELATIVECYCLE,
	 C.OPERATOR,
	 C.DEADLINEPERIOD,
	 C.PERIODTYPE,
	 C.EVENTDATEFLAG,
	 C.ADJUSTMENT,
	 C.MUSTEXIST,
	 C.COMPARISON,
	 C.COMPAREEVENT,
	 C.WORKDAY,
	 C.MESSAGE2FLAG,
	 C.SUPPRESSREMINDERS,
	 C.OVERRIDELETTER,
	 C.INHERITED,
	 C.COMPAREEVENTFLAG,
	 C.COMPARECYCLE,
	 C.COMPARERELATIONSHIP,
	 C.COMPAREDATE,
	 C.COMPARESYSTEMDATE
from CCImport_DUEDATECALC I 
	join DUEDATECALC C	on ( C.CRITERIANO=I.CRITERIANO
	and C.EVENTNO=I.EVENTNO
	and C.SEQUENCE=I.SEQUENCE)
where 	( I.CYCLENUMBER <>  C.CYCLENUMBER OR (I.CYCLENUMBER is null and C.CYCLENUMBER is not null) 
OR (I.CYCLENUMBER is not null and C.CYCLENUMBER is null))
	OR 	( I.COUNTRYCODE <>  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is not null) 
OR (I.COUNTRYCODE is not null and C.COUNTRYCODE is null))
	OR 	( I.FROMEVENT <>  C.FROMEVENT OR (I.FROMEVENT is null and C.FROMEVENT is not null) 
OR (I.FROMEVENT is not null and C.FROMEVENT is null))
	OR 	( I.RELATIVECYCLE <>  C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is not null) 
OR (I.RELATIVECYCLE is not null and C.RELATIVECYCLE is null))
	OR 	( I.OPERATOR <>  C.OPERATOR OR (I.OPERATOR is null and C.OPERATOR is not null) 
OR (I.OPERATOR is not null and C.OPERATOR is null))
	OR 	( I.DEADLINEPERIOD <>  C.DEADLINEPERIOD OR (I.DEADLINEPERIOD is null and C.DEADLINEPERIOD is not null) 
OR (I.DEADLINEPERIOD is not null and C.DEADLINEPERIOD is null))
	OR 	( I.PERIODTYPE <>  C.PERIODTYPE OR (I.PERIODTYPE is null and C.PERIODTYPE is not null) 
OR (I.PERIODTYPE is not null and C.PERIODTYPE is null))
	OR 	( I.EVENTDATEFLAG <>  C.EVENTDATEFLAG OR (I.EVENTDATEFLAG is null and C.EVENTDATEFLAG is not null) 
OR (I.EVENTDATEFLAG is not null and C.EVENTDATEFLAG is null))
	OR 	( I.ADJUSTMENT <>  C.ADJUSTMENT OR (I.ADJUSTMENT is null and C.ADJUSTMENT is not null) 
OR (I.ADJUSTMENT is not null and C.ADJUSTMENT is null))
	OR 	( I.MUSTEXIST <>  C.MUSTEXIST OR (I.MUSTEXIST is null and C.MUSTEXIST is not null) 
OR (I.MUSTEXIST is not null and C.MUSTEXIST is null))
	OR 	( I.COMPARISON <>  C.COMPARISON OR (I.COMPARISON is null and C.COMPARISON is not null) 
OR (I.COMPARISON is not null and C.COMPARISON is null))
	OR 	( I.COMPAREEVENT <>  C.COMPAREEVENT OR (I.COMPAREEVENT is null and C.COMPAREEVENT is not null) 
OR (I.COMPAREEVENT is not null and C.COMPAREEVENT is null))
	OR 	( I.WORKDAY <>  C.WORKDAY OR (I.WORKDAY is null and C.WORKDAY is not null) 
OR (I.WORKDAY is not null and C.WORKDAY is null))
	OR 	( I.MESSAGE2FLAG <>  C.MESSAGE2FLAG OR (I.MESSAGE2FLAG is null and C.MESSAGE2FLAG is not null) 
OR (I.MESSAGE2FLAG is not null and C.MESSAGE2FLAG is null))
	OR 	( I.SUPPRESSREMINDERS <>  C.SUPPRESSREMINDERS OR (I.SUPPRESSREMINDERS is null and C.SUPPRESSREMINDERS is not null) 
OR (I.SUPPRESSREMINDERS is not null and C.SUPPRESSREMINDERS is null))
	OR 	( I.OVERRIDELETTER <>  C.OVERRIDELETTER OR (I.OVERRIDELETTER is null and C.OVERRIDELETTER is not null) 
OR (I.OVERRIDELETTER is not null and C.OVERRIDELETTER is null))
	OR 	( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null) 
OR (I.INHERITED is not null and C.INHERITED is null))
	OR 	( I.COMPAREEVENTFLAG <>  C.COMPAREEVENTFLAG OR (I.COMPAREEVENTFLAG is null and C.COMPAREEVENTFLAG is not null) 
OR (I.COMPAREEVENTFLAG is not null and C.COMPAREEVENTFLAG is null))
	OR 	( I.COMPARECYCLE <>  C.COMPARECYCLE OR (I.COMPARECYCLE is null and C.COMPARECYCLE is not null) 
OR (I.COMPARECYCLE is not null and C.COMPARECYCLE is null))
	OR 	( I.COMPARERELATIONSHIP <>  C.COMPARERELATIONSHIP OR (I.COMPARERELATIONSHIP is null and C.COMPARERELATIONSHIP is not null) 
OR (I.COMPARERELATIONSHIP is not null and C.COMPARERELATIONSHIP is null))
	OR 	( I.COMPAREDATE <>  C.COMPAREDATE OR (I.COMPAREDATE is null and C.COMPAREDATE is not null) 
OR (I.COMPAREDATE is not null and C.COMPAREDATE is null))
	OR 	( I.COMPARESYSTEMDATE <>  C.COMPARESYSTEMDATE OR (I.COMPARESYSTEMDATE is null and C.COMPARESYSTEMDATE is not null) 
OR (I.COMPARESYSTEMDATE is not null and C.COMPARESYSTEMDATE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DUEDATECALC]') and xtype='U')
begin
	drop table CCImport_DUEDATECALC 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_DUEDATECALC  to public
go

