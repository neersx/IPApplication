-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnDUEDATECALC
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnDUEDATECALC]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnDUEDATECALC.'
	drop function dbo.fn_ccnDUEDATECALC
	print '**** Creating function dbo.fn_ccnDUEDATECALC...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
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


CREATE FUNCTION dbo.fn_ccnDUEDATECALC
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnDUEDATECALC
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the DUEDATECALC table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'DUEDATECALC' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_DUEDATECALC I 
	right join DUEDATECALC C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO
and  C.SEQUENCE=I.SEQUENCE)
where I.CRITERIANO is null
UNION ALL 
select	5, 'DUEDATECALC', 0, count(*), 0, 0
from CCImport_DUEDATECALC I 
	left join DUEDATECALC C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO
and  C.SEQUENCE=I.SEQUENCE)
where C.CRITERIANO is null
UNION ALL 
 select	5, 'DUEDATECALC', 0, 0, count(*), 0
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
UNION ALL 
 select	5, 'DUEDATECALC', 0, 0, 0, count(*)
from CCImport_DUEDATECALC I 
join DUEDATECALC C	on( C.CRITERIANO=I.CRITERIANO
and C.EVENTNO=I.EVENTNO
and C.SEQUENCE=I.SEQUENCE)
where ( I.CYCLENUMBER =  C.CYCLENUMBER OR (I.CYCLENUMBER is null and C.CYCLENUMBER is null))
and ( I.COUNTRYCODE =  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is null))
and ( I.FROMEVENT =  C.FROMEVENT OR (I.FROMEVENT is null and C.FROMEVENT is null))
and ( I.RELATIVECYCLE =  C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is null))
and ( I.OPERATOR =  C.OPERATOR OR (I.OPERATOR is null and C.OPERATOR is null))
and ( I.DEADLINEPERIOD =  C.DEADLINEPERIOD OR (I.DEADLINEPERIOD is null and C.DEADLINEPERIOD is null))
and ( I.PERIODTYPE =  C.PERIODTYPE OR (I.PERIODTYPE is null and C.PERIODTYPE is null))
and ( I.EVENTDATEFLAG =  C.EVENTDATEFLAG OR (I.EVENTDATEFLAG is null and C.EVENTDATEFLAG is null))
and ( I.ADJUSTMENT =  C.ADJUSTMENT OR (I.ADJUSTMENT is null and C.ADJUSTMENT is null))
and ( I.MUSTEXIST =  C.MUSTEXIST OR (I.MUSTEXIST is null and C.MUSTEXIST is null))
and ( I.COMPARISON =  C.COMPARISON OR (I.COMPARISON is null and C.COMPARISON is null))
and ( I.COMPAREEVENT =  C.COMPAREEVENT OR (I.COMPAREEVENT is null and C.COMPAREEVENT is null))
and ( I.WORKDAY =  C.WORKDAY OR (I.WORKDAY is null and C.WORKDAY is null))
and ( I.MESSAGE2FLAG =  C.MESSAGE2FLAG OR (I.MESSAGE2FLAG is null and C.MESSAGE2FLAG is null))
and ( I.SUPPRESSREMINDERS =  C.SUPPRESSREMINDERS OR (I.SUPPRESSREMINDERS is null and C.SUPPRESSREMINDERS is null))
and ( I.OVERRIDELETTER =  C.OVERRIDELETTER OR (I.OVERRIDELETTER is null and C.OVERRIDELETTER is null))
and ( I.INHERITED =  C.INHERITED OR (I.INHERITED is null and C.INHERITED is null))
and ( I.COMPAREEVENTFLAG =  C.COMPAREEVENTFLAG OR (I.COMPAREEVENTFLAG is null and C.COMPAREEVENTFLAG is null))
and ( I.COMPARECYCLE =  C.COMPARECYCLE OR (I.COMPARECYCLE is null and C.COMPARECYCLE is null))
and ( I.COMPARERELATIONSHIP =  C.COMPARERELATIONSHIP OR (I.COMPARERELATIONSHIP is null and C.COMPARERELATIONSHIP is null))
and ( I.COMPAREDATE =  C.COMPAREDATE OR (I.COMPAREDATE is null and C.COMPAREDATE is null))
and ( I.COMPARESYSTEMDATE =  C.COMPARESYSTEMDATE OR (I.COMPARESYSTEMDATE is null and C.COMPARESYSTEMDATE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DUEDATECALC]') and xtype='U')
begin
	drop table CCImport_DUEDATECALC 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnDUEDATECALC  to public
go
