-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_EVENTCONTROL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_EVENTCONTROL]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_EVENTCONTROL.'
	drop function dbo.fn_cc_EVENTCONTROL
	print '**** Creating function dbo.fn_cc_EVENTCONTROL...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTCONTROL]') and xtype='U')
begin
	select * 
	into CCImport_EVENTCONTROL 
	from EVENTCONTROL
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_EVENTCONTROL
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_EVENTCONTROL
-- VERSION :	2
-- DESCRIPTION:	The SELECT to display of imported data for the EVENTCONTROL table
-- CALLED BY :	ip_CopyConfigEVENTCONTROL
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
-- 01 May 2017	MF	71205	2	Add new column RENEWALSTATUS
--
As 
Return
select	1 as 'Switch',
	'X' as 'Match',
	'D' as 'Imported -',
	 null as 'Imported Criteriano',
	 null as 'Imported Eventno',
	 null as 'Imported Eventdescription',
	 null as 'Imported Displaysequence',
	 null as 'Imported Parentcriteriano',
	 null as 'Imported Parenteventno',
	 null as 'Imported Numcyclesallowed',
	 null as 'Imported Importancelevel',
	 null as 'Imported Whichduedate',
	 null as 'Imported Compareboolean',
	 null as 'Imported Checkcountryflag',
	 null as 'Imported Saveduedate',
	 null as 'Imported Statuscode',
	 null as 'Imported Specialfunction',
	 null as 'Imported Initialfee',
	 null as 'Imported Payfeecode',
	 null as 'Imported Createaction',
	 null as 'Imported Statusdesc',
	 null as 'Imported Closeaction',
	 null as 'Imported Updatefromevent',
	 null as 'Imported Fromrelationship',
	 null as 'Imported Fromancestor',
	 null as 'Imported Updatemanually',
	 null as 'Imported Adjustment',
	 null as 'Imported Documentno',
	 null as 'Imported Noofdocs',
	 null as 'Imported Mandatorydocs',
	 null as 'Imported Notes',
	 null as 'Imported Inherited',
	 null as 'Imported Instructiontype',
	 null as 'Imported Flagnumber',
	 null as 'Imported Setthirdpartyon',
	 null as 'Imported Relativecycle',
	 null as 'Imported Createcycle',
	 null as 'Imported Estimateflag',
	 null as 'Imported Extendperiod',
	 null as 'Imported Extendperiodtype',
	 null as 'Imported Initialfee2',
	 null as 'Imported Payfeecode2',
	 null as 'Imported Estimateflag2',
	 null as 'Imported Ptadelay',
	 null as 'Imported Setthirdpartyoff',
	 null as 'Imported Receivingcycleflag',
	 null as 'Imported Recalceventdate',
	 null as 'Imported Changenametype',
	 null as 'Imported Copyfromnametype',
	 null as 'Imported Copytonametype',
	 null as 'Imported Delcopyfromname',
	 null as 'Imported Casetype',
	 null as 'Imported Countrycode',
	 null as 'Imported Countrycodeisthiscase',
	 null as 'Imported Propertytype',
	 null as 'Imported Propertytypeisthiscase',
	 null as 'Imported Casecategory',
	 null as 'Imported Categoryisthiscase',
	 null as 'Imported Subtype',
	 null as 'Imported Subtypeisthiscase',
	 null as 'Imported Basis',
	 null as 'Imported Basisisthiscase',
	 null as 'Imported Directpayflag',
	 null as 'Imported Directpayflag2',
	 null as 'Imported Officeid',
	 null as 'Imported Officeidisthiscase',
	 null as 'Imported Duedaterespnametype',
	 null as 'Imported Duedaterespnameno',
	 null as 'Imported Loadnumbertype',
	 null as 'Imported Suppresscalculation',
	 null as 'Imported Renewalstatus',
	'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.EVENTNO as 'Eventno',
	 C.EVENTDESCRIPTION as 'Eventdescription',
	 C.DISPLAYSEQUENCE as 'Displaysequence',
	 C.PARENTCRITERIANO as 'Parentcriteriano',
	 C.PARENTEVENTNO as 'Parenteventno',
	 C.NUMCYCLESALLOWED as 'Numcyclesallowed',
	 C.IMPORTANCELEVEL as 'Importancelevel',
	 C.WHICHDUEDATE as 'Whichduedate',
	 C.COMPAREBOOLEAN as 'Compareboolean',
	 C.CHECKCOUNTRYFLAG as 'Checkcountryflag',
	 C.SAVEDUEDATE as 'Saveduedate',
	 C.STATUSCODE as 'Statuscode',
	 C.SPECIALFUNCTION as 'Specialfunction',
	 C.INITIALFEE as 'Initialfee',
	 C.PAYFEECODE as 'Payfeecode',
	 C.CREATEACTION as 'Createaction',
	 C.STATUSDESC as 'Statusdesc',
	 C.CLOSEACTION as 'Closeaction',
	 C.UPDATEFROMEVENT as 'Updatefromevent',
	 C.FROMRELATIONSHIP as 'Fromrelationship',
	 C.FROMANCESTOR as 'Fromancestor',
	 C.UPDATEMANUALLY as 'Updatemanually',
	 C.ADJUSTMENT as 'Adjustment',
	 C.DOCUMENTNO as 'Documentno',
	 C.NOOFDOCS as 'Noofdocs',
	 C.MANDATORYDOCS as 'Mandatorydocs',
	 CAST(C.NOTES AS NVARCHAR(4000)) as 'Notes',
	 C.INHERITED as 'Inherited',
	 C.INSTRUCTIONTYPE as 'Instructiontype',
	 C.FLAGNUMBER as 'Flagnumber',
	 C.SETTHIRDPARTYON as 'Setthirdpartyon',
	 C.RELATIVECYCLE as 'Relativecycle',
	 C.CREATECYCLE as 'Createcycle',
	 C.ESTIMATEFLAG as 'Estimateflag',
	 C.EXTENDPERIOD as 'Extendperiod',
	 C.EXTENDPERIODTYPE as 'Extendperiodtype',
	 C.INITIALFEE2 as 'Initialfee2',
	 C.PAYFEECODE2 as 'Payfeecode2',
	 C.ESTIMATEFLAG2 as 'Estimateflag2',
	 C.PTADELAY as 'Ptadelay',
	 C.SETTHIRDPARTYOFF as 'Setthirdpartyoff',
	 C.RECEIVINGCYCLEFLAG as 'Receivingcycleflag',
	 C.RECALCEVENTDATE as 'Recalceventdate',
	 C.CHANGENAMETYPE as 'Changenametype',
	 C.COPYFROMNAMETYPE as 'Copyfromnametype',
	 C.COPYTONAMETYPE as 'Copytonametype',
	 C.DELCOPYFROMNAME as 'Delcopyfromname',
	 C.CASETYPE as 'Casetype',
	 C.COUNTRYCODE as 'Countrycode',
	 C.COUNTRYCODEISTHISCASE as 'Countrycodeisthiscase',
	 C.PROPERTYTYPE as 'Propertytype',
	 C.PROPERTYTYPEISTHISCASE as 'Propertytypeisthiscase',
	 C.CASECATEGORY as 'Casecategory',
	 C.CATEGORYISTHISCASE as 'Categoryisthiscase',
	 C.SUBTYPE as 'Subtype',
	 C.SUBTYPEISTHISCASE as 'Subtypeisthiscase',
	 C.BASIS as 'Basis',
	 C.BASISISTHISCASE as 'Basisisthiscase',
	 C.DIRECTPAYFLAG as 'Directpayflag',
	 C.DIRECTPAYFLAG2 as 'Directpayflag2',
	 C.OFFICEID as 'Officeid',
	 C.OFFICEIDISTHISCASE as 'Officeidisthiscase',
	 C.DUEDATERESPNAMETYPE as 'Duedaterespnametype',
	 C.DUEDATERESPNAMENO as 'Duedaterespnameno',
	 C.LOADNUMBERTYPE as 'Loadnumbertype',
	 C.SUPPRESSCALCULATION as 'Suppresscalculation',
	 C.RENEWALSTATUS as 'Renewalstatus'
from CCImport_EVENTCONTROL I 
	right join EVENTCONTROL C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO)
where I.CRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.EVENTNO,
	 I.EVENTDESCRIPTION,
	 I.DISPLAYSEQUENCE,
	 I.PARENTCRITERIANO,
	 I.PARENTEVENTNO,
	 I.NUMCYCLESALLOWED,
	 I.IMPORTANCELEVEL,
	 I.WHICHDUEDATE,
	 I.COMPAREBOOLEAN,
	 I.CHECKCOUNTRYFLAG,
	 I.SAVEDUEDATE,
	 I.STATUSCODE,
	 I.SPECIALFUNCTION,
	 I.INITIALFEE,
	 I.PAYFEECODE,
	 I.CREATEACTION,
	 I.STATUSDESC,
	 I.CLOSEACTION,
	 I.UPDATEFROMEVENT,
	 I.FROMRELATIONSHIP,
	 I.FROMANCESTOR,
	 I.UPDATEMANUALLY,
	 I.ADJUSTMENT,
	 I.DOCUMENTNO,
	 I.NOOFDOCS,
	 I.MANDATORYDOCS,
	 CAST(I.NOTES AS NVARCHAR(4000)),
	 I.INHERITED,
	 I.INSTRUCTIONTYPE,
	 I.FLAGNUMBER,
	 I.SETTHIRDPARTYON,
	 I.RELATIVECYCLE,
	 I.CREATECYCLE,
	 I.ESTIMATEFLAG,
	 I.EXTENDPERIOD,
	 I.EXTENDPERIODTYPE,
	 I.INITIALFEE2,
	 I.PAYFEECODE2,
	 I.ESTIMATEFLAG2,
	 I.PTADELAY,
	 I.SETTHIRDPARTYOFF,
	 I.RECEIVINGCYCLEFLAG,
	 I.RECALCEVENTDATE,
	 I.CHANGENAMETYPE,
	 I.COPYFROMNAMETYPE,
	 I.COPYTONAMETYPE,
	 I.DELCOPYFROMNAME,
	 I.CASETYPE,
	 I.COUNTRYCODE,
	 I.COUNTRYCODEISTHISCASE,
	 I.PROPERTYTYPE,
	 I.PROPERTYTYPEISTHISCASE,
	 I.CASECATEGORY,
	 I.CATEGORYISTHISCASE,
	 I.SUBTYPE,
	 I.SUBTYPEISTHISCASE,
	 I.BASIS,
	 I.BASISISTHISCASE,
	 I.DIRECTPAYFLAG,
	 I.DIRECTPAYFLAG2,
	 I.OFFICEID,
	 I.OFFICEIDISTHISCASE,
	 I.DUEDATERESPNAMETYPE,
	 I.DUEDATERESPNAMENO,
	 I.LOADNUMBERTYPE,
	 I.SUPPRESSCALCULATION,
	 I.RENEWALSTATUS,
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
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_EVENTCONTROL I 
	left join EVENTCONTROL C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO)
where C.CRITERIANO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIANO,
	 I.EVENTNO,
	 I.EVENTDESCRIPTION,
	 I.DISPLAYSEQUENCE,
	 I.PARENTCRITERIANO,
	 I.PARENTEVENTNO,
	 I.NUMCYCLESALLOWED,
	 I.IMPORTANCELEVEL,
	 I.WHICHDUEDATE,
	 I.COMPAREBOOLEAN,
	 I.CHECKCOUNTRYFLAG,
	 I.SAVEDUEDATE,
	 I.STATUSCODE,
	 I.SPECIALFUNCTION,
	 I.INITIALFEE,
	 I.PAYFEECODE,
	 I.CREATEACTION,
	 I.STATUSDESC,
	 I.CLOSEACTION,
	 I.UPDATEFROMEVENT,
	 I.FROMRELATIONSHIP,
	 I.FROMANCESTOR,
	 I.UPDATEMANUALLY,
	 I.ADJUSTMENT,
	 I.DOCUMENTNO,
	 I.NOOFDOCS,
	 I.MANDATORYDOCS,
	 CAST(I.NOTES AS NVARCHAR(4000)),
	 I.INHERITED,
	 I.INSTRUCTIONTYPE,
	 I.FLAGNUMBER,
	 I.SETTHIRDPARTYON,
	 I.RELATIVECYCLE,
	 I.CREATECYCLE,
	 I.ESTIMATEFLAG,
	 I.EXTENDPERIOD,
	 I.EXTENDPERIODTYPE,
	 I.INITIALFEE2,
	 I.PAYFEECODE2,
	 I.ESTIMATEFLAG2,
	 I.PTADELAY,
	 I.SETTHIRDPARTYOFF,
	 I.RECEIVINGCYCLEFLAG,
	 I.RECALCEVENTDATE,
	 I.CHANGENAMETYPE,
	 I.COPYFROMNAMETYPE,
	 I.COPYTONAMETYPE,
	 I.DELCOPYFROMNAME,
	 I.CASETYPE,
	 I.COUNTRYCODE,
	 I.COUNTRYCODEISTHISCASE,
	 I.PROPERTYTYPE,
	 I.PROPERTYTYPEISTHISCASE,
	 I.CASECATEGORY,
	 I.CATEGORYISTHISCASE,
	 I.SUBTYPE,
	 I.SUBTYPEISTHISCASE,
	 I.BASIS,
	 I.BASISISTHISCASE,
	 I.DIRECTPAYFLAG,
	 I.DIRECTPAYFLAG2,
	 I.OFFICEID,
	 I.OFFICEIDISTHISCASE,
	 I.DUEDATERESPNAMETYPE,
	 I.DUEDATERESPNAMENO,
	 I.LOADNUMBERTYPE,
	 I.SUPPRESSCALCULATION,
	 I.RENEWALSTATUS,
	'U',
	 C.CRITERIANO,
	 C.EVENTNO,
	 C.EVENTDESCRIPTION,
	 C.DISPLAYSEQUENCE,
	 C.PARENTCRITERIANO,
	 C.PARENTEVENTNO,
	 C.NUMCYCLESALLOWED,
	 C.IMPORTANCELEVEL,
	 C.WHICHDUEDATE,
	 C.COMPAREBOOLEAN,
	 C.CHECKCOUNTRYFLAG,
	 C.SAVEDUEDATE,
	 C.STATUSCODE,
	 C.SPECIALFUNCTION,
	 C.INITIALFEE,
	 C.PAYFEECODE,
	 C.CREATEACTION,
	 C.STATUSDESC,
	 C.CLOSEACTION,
	 C.UPDATEFROMEVENT,
	 C.FROMRELATIONSHIP,
	 C.FROMANCESTOR,
	 C.UPDATEMANUALLY,
	 C.ADJUSTMENT,
	 C.DOCUMENTNO,
	 C.NOOFDOCS,
	 C.MANDATORYDOCS,
	 CAST(C.NOTES AS NVARCHAR(4000)),
	 C.INHERITED,
	 C.INSTRUCTIONTYPE,
	 C.FLAGNUMBER,
	 C.SETTHIRDPARTYON,
	 C.RELATIVECYCLE,
	 C.CREATECYCLE,
	 C.ESTIMATEFLAG,
	 C.EXTENDPERIOD,
	 C.EXTENDPERIODTYPE,
	 C.INITIALFEE2,
	 C.PAYFEECODE2,
	 C.ESTIMATEFLAG2,
	 C.PTADELAY,
	 C.SETTHIRDPARTYOFF,
	 C.RECEIVINGCYCLEFLAG,
	 C.RECALCEVENTDATE,
	 C.CHANGENAMETYPE,
	 C.COPYFROMNAMETYPE,
	 C.COPYTONAMETYPE,
	 C.DELCOPYFROMNAME,
	 C.CASETYPE,
	 C.COUNTRYCODE,
	 C.COUNTRYCODEISTHISCASE,
	 C.PROPERTYTYPE,
	 C.PROPERTYTYPEISTHISCASE,
	 C.CASECATEGORY,
	 C.CATEGORYISTHISCASE,
	 C.SUBTYPE,
	 C.SUBTYPEISTHISCASE,
	 C.BASIS,
	 C.BASISISTHISCASE,
	 C.DIRECTPAYFLAG,
	 C.DIRECTPAYFLAG2,
	 C.OFFICEID,
	 C.OFFICEIDISTHISCASE,
	 C.DUEDATERESPNAMETYPE,
	 C.DUEDATERESPNAMENO,
	 C.LOADNUMBERTYPE,
	 C.SUPPRESSCALCULATION,
	 C.RENEWALSTATUS
from CCImport_EVENTCONTROL I 
	join EVENTCONTROL C	on ( C.CRITERIANO=I.CRITERIANO
	and C.EVENTNO=I.EVENTNO)
where 	( I.EVENTNO <>  C.EVENTNO)
	OR 	( I.EVENTDESCRIPTION <>  C.EVENTDESCRIPTION OR (I.EVENTDESCRIPTION is null and C.EVENTDESCRIPTION is not null) 
OR (I.EVENTDESCRIPTION is not null and C.EVENTDESCRIPTION is null))
	OR 	( I.PARENTCRITERIANO <>  C.PARENTCRITERIANO OR (I.PARENTCRITERIANO is null and C.PARENTCRITERIANO is not null) 
OR (I.PARENTCRITERIANO is not null and C.PARENTCRITERIANO is null))
	OR 	( I.PARENTEVENTNO <>  C.PARENTEVENTNO OR (I.PARENTEVENTNO is null and C.PARENTEVENTNO is not null) 
OR (I.PARENTEVENTNO is not null and C.PARENTEVENTNO is null))
	OR 	( I.NUMCYCLESALLOWED <>  C.NUMCYCLESALLOWED OR (I.NUMCYCLESALLOWED is null and C.NUMCYCLESALLOWED is not null) 
OR (I.NUMCYCLESALLOWED is not null and C.NUMCYCLESALLOWED is null))
	OR 	( I.IMPORTANCELEVEL <>  C.IMPORTANCELEVEL OR (I.IMPORTANCELEVEL is null and C.IMPORTANCELEVEL is not null) 
OR (I.IMPORTANCELEVEL is not null and C.IMPORTANCELEVEL is null))
	OR 	( I.WHICHDUEDATE <>  C.WHICHDUEDATE OR (I.WHICHDUEDATE is null and C.WHICHDUEDATE is not null) 
OR (I.WHICHDUEDATE is not null and C.WHICHDUEDATE is null))
	OR 	( I.COMPAREBOOLEAN <>  C.COMPAREBOOLEAN OR (I.COMPAREBOOLEAN is null and C.COMPAREBOOLEAN is not null) 
OR (I.COMPAREBOOLEAN is not null and C.COMPAREBOOLEAN is null))
	OR 	( I.CHECKCOUNTRYFLAG <>  C.CHECKCOUNTRYFLAG OR (I.CHECKCOUNTRYFLAG is null and C.CHECKCOUNTRYFLAG is not null) 
OR (I.CHECKCOUNTRYFLAG is not null and C.CHECKCOUNTRYFLAG is null))
	OR 	( I.SAVEDUEDATE <>  C.SAVEDUEDATE OR (I.SAVEDUEDATE is null and C.SAVEDUEDATE is not null) 
OR (I.SAVEDUEDATE is not null and C.SAVEDUEDATE is null))
	OR 	( I.STATUSCODE <>  C.STATUSCODE OR (I.STATUSCODE is null and C.STATUSCODE is not null) 
OR (I.STATUSCODE is not null and C.STATUSCODE is null))
	OR 	( I.SPECIALFUNCTION <>  C.SPECIALFUNCTION OR (I.SPECIALFUNCTION is null and C.SPECIALFUNCTION is not null) 
OR (I.SPECIALFUNCTION is not null and C.SPECIALFUNCTION is null))
	OR 	( I.INITIALFEE <>  C.INITIALFEE OR (I.INITIALFEE is null and C.INITIALFEE is not null) 
OR (I.INITIALFEE is not null and C.INITIALFEE is null))
	OR 	( I.PAYFEECODE <>  C.PAYFEECODE OR (I.PAYFEECODE is null and C.PAYFEECODE is not null) 
OR (I.PAYFEECODE is not null and C.PAYFEECODE is null))
	OR 	( I.CREATEACTION <>  C.CREATEACTION OR (I.CREATEACTION is null and C.CREATEACTION is not null) 
OR (I.CREATEACTION is not null and C.CREATEACTION is null))
	OR 	( I.STATUSDESC <>  C.STATUSDESC OR (I.STATUSDESC is null and C.STATUSDESC is not null) 
OR (I.STATUSDESC is not null and C.STATUSDESC is null))
	OR 	( I.CLOSEACTION <>  C.CLOSEACTION OR (I.CLOSEACTION is null and C.CLOSEACTION is not null) 
OR (I.CLOSEACTION is not null and C.CLOSEACTION is null))
	OR 	( I.UPDATEFROMEVENT <>  C.UPDATEFROMEVENT OR (I.UPDATEFROMEVENT is null and C.UPDATEFROMEVENT is not null) 
OR (I.UPDATEFROMEVENT is not null and C.UPDATEFROMEVENT is null))
	OR 	( I.FROMRELATIONSHIP <>  C.FROMRELATIONSHIP OR (I.FROMRELATIONSHIP is null and C.FROMRELATIONSHIP is not null) 
OR (I.FROMRELATIONSHIP is not null and C.FROMRELATIONSHIP is null))
	OR 	( I.FROMANCESTOR <>  C.FROMANCESTOR OR (I.FROMANCESTOR is null and C.FROMANCESTOR is not null) 
OR (I.FROMANCESTOR is not null and C.FROMANCESTOR is null))
	OR 	( I.UPDATEMANUALLY <>  C.UPDATEMANUALLY OR (I.UPDATEMANUALLY is null and C.UPDATEMANUALLY is not null) 
OR (I.UPDATEMANUALLY is not null and C.UPDATEMANUALLY is null))
	OR 	( I.ADJUSTMENT <>  C.ADJUSTMENT OR (I.ADJUSTMENT is null and C.ADJUSTMENT is not null) 
OR (I.ADJUSTMENT is not null and C.ADJUSTMENT is null))
	OR 	( I.DOCUMENTNO <>  C.DOCUMENTNO OR (I.DOCUMENTNO is null and C.DOCUMENTNO is not null) 
OR (I.DOCUMENTNO is not null and C.DOCUMENTNO is null))
	OR 	( I.NOOFDOCS <>  C.NOOFDOCS OR (I.NOOFDOCS is null and C.NOOFDOCS is not null) 
OR (I.NOOFDOCS is not null and C.NOOFDOCS is null))
	OR 	( I.MANDATORYDOCS <>  C.MANDATORYDOCS OR (I.MANDATORYDOCS is null and C.MANDATORYDOCS is not null) 
OR (I.MANDATORYDOCS is not null and C.MANDATORYDOCS is null))
	OR 	( replace(CAST(I.NOTES as NVARCHAR(MAX)),char(10),char(13)+char(10)) <>  CAST(C.NOTES as NVARCHAR(MAX)) OR (I.NOTES is null and C.NOTES is not null) 
OR (I.NOTES is not null and C.NOTES is null))
	OR 	( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null) 
OR (I.INHERITED is not null and C.INHERITED is null))
	OR 	( I.INSTRUCTIONTYPE <>  C.INSTRUCTIONTYPE OR (I.INSTRUCTIONTYPE is null and C.INSTRUCTIONTYPE is not null) 
OR (I.INSTRUCTIONTYPE is not null and C.INSTRUCTIONTYPE is null))
	OR 	( I.FLAGNUMBER <>  C.FLAGNUMBER OR (I.FLAGNUMBER is null and C.FLAGNUMBER is not null) 
OR (I.FLAGNUMBER is not null and C.FLAGNUMBER is null))
	OR 	( I.SETTHIRDPARTYON <>  C.SETTHIRDPARTYON OR (I.SETTHIRDPARTYON is null and C.SETTHIRDPARTYON is not null) 
OR (I.SETTHIRDPARTYON is not null and C.SETTHIRDPARTYON is null))
	OR 	( I.RELATIVECYCLE <>  C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is not null) 
OR (I.RELATIVECYCLE is not null and C.RELATIVECYCLE is null))
	OR 	( I.CREATECYCLE <>  C.CREATECYCLE OR (I.CREATECYCLE is null and C.CREATECYCLE is not null) 
OR (I.CREATECYCLE is not null and C.CREATECYCLE is null))
	OR 	( I.ESTIMATEFLAG <>  C.ESTIMATEFLAG OR (I.ESTIMATEFLAG is null and C.ESTIMATEFLAG is not null) 
OR (I.ESTIMATEFLAG is not null and C.ESTIMATEFLAG is null))
	OR 	( I.EXTENDPERIOD <>  C.EXTENDPERIOD OR (I.EXTENDPERIOD is null and C.EXTENDPERIOD is not null) 
OR (I.EXTENDPERIOD is not null and C.EXTENDPERIOD is null))
	OR 	( I.EXTENDPERIODTYPE <>  C.EXTENDPERIODTYPE OR (I.EXTENDPERIODTYPE is null and C.EXTENDPERIODTYPE is not null) 
OR (I.EXTENDPERIODTYPE is not null and C.EXTENDPERIODTYPE is null))
	OR 	( I.INITIALFEE2 <>  C.INITIALFEE2 OR (I.INITIALFEE2 is null and C.INITIALFEE2 is not null) 
OR (I.INITIALFEE2 is not null and C.INITIALFEE2 is null))
	OR 	( I.PAYFEECODE2 <>  C.PAYFEECODE2 OR (I.PAYFEECODE2 is null and C.PAYFEECODE2 is not null) 
OR (I.PAYFEECODE2 is not null and C.PAYFEECODE2 is null))
	OR 	( I.ESTIMATEFLAG2 <>  C.ESTIMATEFLAG2 OR (I.ESTIMATEFLAG2 is null and C.ESTIMATEFLAG2 is not null) 
OR (I.ESTIMATEFLAG2 is not null and C.ESTIMATEFLAG2 is null))
	OR 	( I.PTADELAY <>  C.PTADELAY OR (I.PTADELAY is null and C.PTADELAY is not null) 
OR (I.PTADELAY is not null and C.PTADELAY is null))
	OR 	( I.SETTHIRDPARTYOFF <>  C.SETTHIRDPARTYOFF OR (I.SETTHIRDPARTYOFF is null and C.SETTHIRDPARTYOFF is not null) 
OR (I.SETTHIRDPARTYOFF is not null and C.SETTHIRDPARTYOFF is null))
	OR 	( I.RECEIVINGCYCLEFLAG <>  C.RECEIVINGCYCLEFLAG OR (I.RECEIVINGCYCLEFLAG is null and C.RECEIVINGCYCLEFLAG is not null) 
OR (I.RECEIVINGCYCLEFLAG is not null and C.RECEIVINGCYCLEFLAG is null))
	OR 	( I.RECALCEVENTDATE <>  C.RECALCEVENTDATE OR (I.RECALCEVENTDATE is null and C.RECALCEVENTDATE is not null) 
OR (I.RECALCEVENTDATE is not null and C.RECALCEVENTDATE is null))
	OR 	( I.CHANGENAMETYPE <>  C.CHANGENAMETYPE OR (I.CHANGENAMETYPE is null and C.CHANGENAMETYPE is not null) 
OR (I.CHANGENAMETYPE is not null and C.CHANGENAMETYPE is null))
	OR 	( I.COPYFROMNAMETYPE <>  C.COPYFROMNAMETYPE OR (I.COPYFROMNAMETYPE is null and C.COPYFROMNAMETYPE is not null) 
OR (I.COPYFROMNAMETYPE is not null and C.COPYFROMNAMETYPE is null))
	OR 	( I.COPYTONAMETYPE <>  C.COPYTONAMETYPE OR (I.COPYTONAMETYPE is null and C.COPYTONAMETYPE is not null) 
OR (I.COPYTONAMETYPE is not null and C.COPYTONAMETYPE is null))
	OR 	( I.DELCOPYFROMNAME <>  C.DELCOPYFROMNAME OR (I.DELCOPYFROMNAME is null and C.DELCOPYFROMNAME is not null) 
OR (I.DELCOPYFROMNAME is not null and C.DELCOPYFROMNAME is null))
	OR 	( I.CASETYPE <>  C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is not null) 
OR (I.CASETYPE is not null and C.CASETYPE is null))
	OR 	( I.COUNTRYCODE <>  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is not null) 
OR (I.COUNTRYCODE is not null and C.COUNTRYCODE is null))
	OR 	( I.COUNTRYCODEISTHISCASE <>  C.COUNTRYCODEISTHISCASE OR (I.COUNTRYCODEISTHISCASE is null and C.COUNTRYCODEISTHISCASE is not null) 
OR (I.COUNTRYCODEISTHISCASE is not null and C.COUNTRYCODEISTHISCASE is null))
	OR 	( I.PROPERTYTYPE <>  C.PROPERTYTYPE OR (I.PROPERTYTYPE is null and C.PROPERTYTYPE is not null) 
OR (I.PROPERTYTYPE is not null and C.PROPERTYTYPE is null))
	OR 	( I.PROPERTYTYPEISTHISCASE <>  C.PROPERTYTYPEISTHISCASE OR (I.PROPERTYTYPEISTHISCASE is null and C.PROPERTYTYPEISTHISCASE is not null) 
OR (I.PROPERTYTYPEISTHISCASE is not null and C.PROPERTYTYPEISTHISCASE is null))
	OR 	( I.CASECATEGORY <>  C.CASECATEGORY OR (I.CASECATEGORY is null and C.CASECATEGORY is not null) 
OR (I.CASECATEGORY is not null and C.CASECATEGORY is null))
	OR 	( I.CATEGORYISTHISCASE <>  C.CATEGORYISTHISCASE OR (I.CATEGORYISTHISCASE is null and C.CATEGORYISTHISCASE is not null) 
OR (I.CATEGORYISTHISCASE is not null and C.CATEGORYISTHISCASE is null))
	OR 	( I.SUBTYPE <>  C.SUBTYPE OR (I.SUBTYPE is null and C.SUBTYPE is not null) 
OR (I.SUBTYPE is not null and C.SUBTYPE is null))
	OR 	( I.SUBTYPEISTHISCASE <>  C.SUBTYPEISTHISCASE OR (I.SUBTYPEISTHISCASE is null and C.SUBTYPEISTHISCASE is not null) 
OR (I.SUBTYPEISTHISCASE is not null and C.SUBTYPEISTHISCASE is null))
	OR 	( I.BASIS <>  C.BASIS OR (I.BASIS is null and C.BASIS is not null) 
OR (I.BASIS is not null and C.BASIS is null))
	OR 	( I.BASISISTHISCASE <>  C.BASISISTHISCASE OR (I.BASISISTHISCASE is null and C.BASISISTHISCASE is not null) 
OR (I.BASISISTHISCASE is not null and C.BASISISTHISCASE is null))
	OR 	( I.DIRECTPAYFLAG <>  C.DIRECTPAYFLAG OR (I.DIRECTPAYFLAG is null and C.DIRECTPAYFLAG is not null) 
OR (I.DIRECTPAYFLAG is not null and C.DIRECTPAYFLAG is null))
	OR 	( I.DIRECTPAYFLAG2 <>  C.DIRECTPAYFLAG2 OR (I.DIRECTPAYFLAG2 is null and C.DIRECTPAYFLAG2 is not null) 
OR (I.DIRECTPAYFLAG2 is not null and C.DIRECTPAYFLAG2 is null))
	OR 	( I.OFFICEID <>  C.OFFICEID OR (I.OFFICEID is null and C.OFFICEID is not null) 
OR (I.OFFICEID is not null and C.OFFICEID is null))
	OR 	( I.OFFICEIDISTHISCASE <>  C.OFFICEIDISTHISCASE OR (I.OFFICEIDISTHISCASE is null and C.OFFICEIDISTHISCASE is not null) 
OR (I.OFFICEIDISTHISCASE is not null and C.OFFICEIDISTHISCASE is null))
	OR 	( I.DUEDATERESPNAMETYPE <>  C.DUEDATERESPNAMETYPE OR (I.DUEDATERESPNAMETYPE is null and C.DUEDATERESPNAMETYPE is not null) 
OR (I.DUEDATERESPNAMETYPE is not null and C.DUEDATERESPNAMETYPE is null))
	OR 	( I.DUEDATERESPNAMENO <>  C.DUEDATERESPNAMENO OR (I.DUEDATERESPNAMENO is null and C.DUEDATERESPNAMENO is not null) 
OR (I.DUEDATERESPNAMENO is not null and C.DUEDATERESPNAMENO is null))
	OR 	( I.LOADNUMBERTYPE <>  C.LOADNUMBERTYPE OR (I.LOADNUMBERTYPE is null and C.LOADNUMBERTYPE is not null) 
OR (I.LOADNUMBERTYPE is not null and C.LOADNUMBERTYPE is null))
	OR 	( I.SUPPRESSCALCULATION <>  C.SUPPRESSCALCULATION OR (I.SUPPRESSCALCULATION is null and C.SUPPRESSCALCULATION is not null) 
OR (I.SUPPRESSCALCULATION is not null and C.SUPPRESSCALCULATION is null))
	OR 	( I.RENEWALSTATUS <>  C.RENEWALSTATUS OR (I.RENEWALSTATUS is null and C.RENEWALSTATUS is not null) 
OR (I.RENEWALSTATUS is not null and C.RENEWALSTATUS is null))
/* DISPLAYSEQUENCE : column intentionally excluded from comparison display but will be updated if different. */

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTCONTROL]') and xtype='U')
begin
	drop table CCImport_EVENTCONTROL 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_EVENTCONTROL  to public
go
