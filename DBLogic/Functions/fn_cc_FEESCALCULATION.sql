-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_FEESCALCULATION
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_FEESCALCULATION]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_FEESCALCULATION.'
	drop function dbo.fn_cc_FEESCALCULATION
	print '**** Creating function dbo.fn_cc_FEESCALCULATION...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_FEESCALCULATION]') and xtype='U')
begin
	select * 
	into CCImport_FEESCALCULATION 
	from FEESCALCULATION
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_FEESCALCULATION
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_FEESCALCULATION
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the FEESCALCULATION table
-- CALLED BY :	ip_CopyConfigFEESCALCULATION
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
	 null as 'Imported Uniqueid',
	 null as 'Imported Agent',
	 null as 'Imported Debtortype',
	 null as 'Imported Debtor',
	 null as 'Imported Cyclenumber',
	 null as 'Imported Validfromdate',
	 null as 'Imported Debitnote',
	 null as 'Imported Coveringletter',
	 null as 'Imported Generatecharges',
	 null as 'Imported Feetype',
	 null as 'Imported Ipofficefeeflag',
	 null as 'Imported Disbcurrency',
	 null as 'Imported Disbtaxcode',
	 null as 'Imported Disbnarrative',
	 null as 'Imported Disbwipcode',
	 null as 'Imported Disbbasefee',
	 null as 'Imported Disbminfeeflag',
	 null as 'Imported Disbvariablefee',
	 null as 'Imported Disbaddpercentage',
	 null as 'Imported Disbunitsize',
	 null as 'Imported Disbbaseunits',
	 null as 'Imported Servicecurrency',
	 null as 'Imported Servtaxcode',
	 null as 'Imported Servicenarrative',
	 null as 'Imported Servwipcode',
	 null as 'Imported Servbasefee',
	 null as 'Imported Servminfeeflag',
	 null as 'Imported Servvariablefee',
	 null as 'Imported Servaddpercentage',
	 null as 'Imported Servdisbpercentage',
	 null as 'Imported Servunitsize',
	 null as 'Imported Servbaseunits',
	 null as 'Imported Inherited',
	 null as 'Imported Parametersource',
	 null as 'Imported Disbmaxunits',
	 null as 'Imported Servmaxunits',
	 null as 'Imported Disbemployeeno',
	 null as 'Imported Servemployeeno',
	 null as 'Imported Varbasefee',
	 null as 'Imported Varbaseunits',
	 null as 'Imported Varvariablefee',
	 null as 'Imported Varunitsize',
	 null as 'Imported Varmaxunits',
	 null as 'Imported Varminfeeflag',
	 null as 'Imported Writeupreason',
	 null as 'Imported Varwipcode',
	 null as 'Imported Varfeeapplies',
	 null as 'Imported Owner',
	 null as 'Imported Instructor',
	 null as 'Imported Productcode',
	 null as 'Imported Parametersource2',
	 null as 'Imported Feetype2',
	 null as 'Imported Fromeventno',
	 null as 'Imported Disbstaffnametype',
	 null as 'Imported Servstaffnametype',
	 null as 'Imported Disbdiscfeeflag',
	 null as 'Imported Servdiscfeeflag',
'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.UNIQUEID as 'Uniqueid',
	 C.AGENT as 'Agent',
	 C.DEBTORTYPE as 'Debtortype',
	 C.DEBTOR as 'Debtor',
	 C.CYCLENUMBER as 'Cyclenumber',
	 C.VALIDFROMDATE as 'Validfromdate',
	 C.DEBITNOTE as 'Debitnote',
	 C.COVERINGLETTER as 'Coveringletter',
	 C.GENERATECHARGES as 'Generatecharges',
	 C.FEETYPE as 'Feetype',
	 C.IPOFFICEFEEFLAG as 'Ipofficefeeflag',
	 C.DISBCURRENCY as 'Disbcurrency',
	 C.DISBTAXCODE as 'Disbtaxcode',
	 C.DISBNARRATIVE as 'Disbnarrative',
	 C.DISBWIPCODE as 'Disbwipcode',
	 C.DISBBASEFEE as 'Disbbasefee',
	 C.DISBMINFEEFLAG as 'Disbminfeeflag',
	 C.DISBVARIABLEFEE as 'Disbvariablefee',
	 C.DISBADDPERCENTAGE as 'Disbaddpercentage',
	 C.DISBUNITSIZE as 'Disbunitsize',
	 C.DISBBASEUNITS as 'Disbbaseunits',
	 C.SERVICECURRENCY as 'Servicecurrency',
	 C.SERVTAXCODE as 'Servtaxcode',
	 C.SERVICENARRATIVE as 'Servicenarrative',
	 C.SERVWIPCODE as 'Servwipcode',
	 C.SERVBASEFEE as 'Servbasefee',
	 C.SERVMINFEEFLAG as 'Servminfeeflag',
	 C.SERVVARIABLEFEE as 'Servvariablefee',
	 C.SERVADDPERCENTAGE as 'Servaddpercentage',
	 C.SERVDISBPERCENTAGE as 'Servdisbpercentage',
	 C.SERVUNITSIZE as 'Servunitsize',
	 C.SERVBASEUNITS as 'Servbaseunits',
	 C.INHERITED as 'Inherited',
	 C.PARAMETERSOURCE as 'Parametersource',
	 C.DISBMAXUNITS as 'Disbmaxunits',
	 C.SERVMAXUNITS as 'Servmaxunits',
	 C.DISBEMPLOYEENO as 'Disbemployeeno',
	 C.SERVEMPLOYEENO as 'Servemployeeno',
	 C.VARBASEFEE as 'Varbasefee',
	 C.VARBASEUNITS as 'Varbaseunits',
	 C.VARVARIABLEFEE as 'Varvariablefee',
	 C.VARUNITSIZE as 'Varunitsize',
	 C.VARMAXUNITS as 'Varmaxunits',
	 C.VARMINFEEFLAG as 'Varminfeeflag',
	 C.WRITEUPREASON as 'Writeupreason',
	 C.VARWIPCODE as 'Varwipcode',
	 C.VARFEEAPPLIES as 'Varfeeapplies',
	 C.OWNER as 'Owner',
	 C.INSTRUCTOR as 'Instructor',
	 C.PRODUCTCODE as 'Productcode',
	 C.PARAMETERSOURCE2 as 'Parametersource2',
	 C.FEETYPE2 as 'Feetype2',
	 C.FROMEVENTNO as 'Fromeventno',
	 C.DISBSTAFFNAMETYPE as 'Disbstaffnametype',
	 C.SERVSTAFFNAMETYPE as 'Servstaffnametype',
	 C.DISBDISCFEEFLAG as 'Disbdiscfeeflag',
	 C.SERVDISCFEEFLAG as 'Servdiscfeeflag'
from CCImport_FEESCALCULATION I 
	right join FEESCALCULATION C on( C.CRITERIANO=I.CRITERIANO
and  C.UNIQUEID=I.UNIQUEID)
where I.CRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.UNIQUEID,
	 I.AGENT,
	 I.DEBTORTYPE,
	 I.DEBTOR,
	 I.CYCLENUMBER,
	 I.VALIDFROMDATE,
	 I.DEBITNOTE,
	 I.COVERINGLETTER,
	 I.GENERATECHARGES,
	 I.FEETYPE,
	 I.IPOFFICEFEEFLAG,
	 I.DISBCURRENCY,
	 I.DISBTAXCODE,
	 I.DISBNARRATIVE,
	 I.DISBWIPCODE,
	 I.DISBBASEFEE,
	 I.DISBMINFEEFLAG,
	 I.DISBVARIABLEFEE,
	 I.DISBADDPERCENTAGE,
	 I.DISBUNITSIZE,
	 I.DISBBASEUNITS,
	 I.SERVICECURRENCY,
	 I.SERVTAXCODE,
	 I.SERVICENARRATIVE,
	 I.SERVWIPCODE,
	 I.SERVBASEFEE,
	 I.SERVMINFEEFLAG,
	 I.SERVVARIABLEFEE,
	 I.SERVADDPERCENTAGE,
	 I.SERVDISBPERCENTAGE,
	 I.SERVUNITSIZE,
	 I.SERVBASEUNITS,
	 I.INHERITED,
	 I.PARAMETERSOURCE,
	 I.DISBMAXUNITS,
	 I.SERVMAXUNITS,
	 I.DISBEMPLOYEENO,
	 I.SERVEMPLOYEENO,
	 I.VARBASEFEE,
	 I.VARBASEUNITS,
	 I.VARVARIABLEFEE,
	 I.VARUNITSIZE,
	 I.VARMAXUNITS,
	 I.VARMINFEEFLAG,
	 I.WRITEUPREASON,
	 I.VARWIPCODE,
	 I.VARFEEAPPLIES,
	 I.OWNER,
	 I.INSTRUCTOR,
	 I.PRODUCTCODE,
	 I.PARAMETERSOURCE2,
	 I.FEETYPE2,
	 I.FROMEVENTNO,
	 I.DISBSTAFFNAMETYPE,
	 I.SERVSTAFFNAMETYPE,
	 I.DISBDISCFEEFLAG,
	 I.SERVDISCFEEFLAG,
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
	 null
from CCImport_FEESCALCULATION I 
	left join FEESCALCULATION C on( C.CRITERIANO=I.CRITERIANO
and  C.UNIQUEID=I.UNIQUEID)
where C.CRITERIANO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIANO,
	 I.UNIQUEID,
	 I.AGENT,
	 I.DEBTORTYPE,
	 I.DEBTOR,
	 I.CYCLENUMBER,
	 I.VALIDFROMDATE,
	 I.DEBITNOTE,
	 I.COVERINGLETTER,
	 I.GENERATECHARGES,
	 I.FEETYPE,
	 I.IPOFFICEFEEFLAG,
	 I.DISBCURRENCY,
	 I.DISBTAXCODE,
	 I.DISBNARRATIVE,
	 I.DISBWIPCODE,
	 I.DISBBASEFEE,
	 I.DISBMINFEEFLAG,
	 I.DISBVARIABLEFEE,
	 I.DISBADDPERCENTAGE,
	 I.DISBUNITSIZE,
	 I.DISBBASEUNITS,
	 I.SERVICECURRENCY,
	 I.SERVTAXCODE,
	 I.SERVICENARRATIVE,
	 I.SERVWIPCODE,
	 I.SERVBASEFEE,
	 I.SERVMINFEEFLAG,
	 I.SERVVARIABLEFEE,
	 I.SERVADDPERCENTAGE,
	 I.SERVDISBPERCENTAGE,
	 I.SERVUNITSIZE,
	 I.SERVBASEUNITS,
	 I.INHERITED,
	 I.PARAMETERSOURCE,
	 I.DISBMAXUNITS,
	 I.SERVMAXUNITS,
	 I.DISBEMPLOYEENO,
	 I.SERVEMPLOYEENO,
	 I.VARBASEFEE,
	 I.VARBASEUNITS,
	 I.VARVARIABLEFEE,
	 I.VARUNITSIZE,
	 I.VARMAXUNITS,
	 I.VARMINFEEFLAG,
	 I.WRITEUPREASON,
	 I.VARWIPCODE,
	 I.VARFEEAPPLIES,
	 I.OWNER,
	 I.INSTRUCTOR,
	 I.PRODUCTCODE,
	 I.PARAMETERSOURCE2,
	 I.FEETYPE2,
	 I.FROMEVENTNO,
	 I.DISBSTAFFNAMETYPE,
	 I.SERVSTAFFNAMETYPE,
	 I.DISBDISCFEEFLAG,
	 I.SERVDISCFEEFLAG,
'U',
	 C.CRITERIANO,
	 C.UNIQUEID,
	 C.AGENT,
	 C.DEBTORTYPE,
	 C.DEBTOR,
	 C.CYCLENUMBER,
	 C.VALIDFROMDATE,
	 C.DEBITNOTE,
	 C.COVERINGLETTER,
	 C.GENERATECHARGES,
	 C.FEETYPE,
	 C.IPOFFICEFEEFLAG,
	 C.DISBCURRENCY,
	 C.DISBTAXCODE,
	 C.DISBNARRATIVE,
	 C.DISBWIPCODE,
	 C.DISBBASEFEE,
	 C.DISBMINFEEFLAG,
	 C.DISBVARIABLEFEE,
	 C.DISBADDPERCENTAGE,
	 C.DISBUNITSIZE,
	 C.DISBBASEUNITS,
	 C.SERVICECURRENCY,
	 C.SERVTAXCODE,
	 C.SERVICENARRATIVE,
	 C.SERVWIPCODE,
	 C.SERVBASEFEE,
	 C.SERVMINFEEFLAG,
	 C.SERVVARIABLEFEE,
	 C.SERVADDPERCENTAGE,
	 C.SERVDISBPERCENTAGE,
	 C.SERVUNITSIZE,
	 C.SERVBASEUNITS,
	 C.INHERITED,
	 C.PARAMETERSOURCE,
	 C.DISBMAXUNITS,
	 C.SERVMAXUNITS,
	 C.DISBEMPLOYEENO,
	 C.SERVEMPLOYEENO,
	 C.VARBASEFEE,
	 C.VARBASEUNITS,
	 C.VARVARIABLEFEE,
	 C.VARUNITSIZE,
	 C.VARMAXUNITS,
	 C.VARMINFEEFLAG,
	 C.WRITEUPREASON,
	 C.VARWIPCODE,
	 C.VARFEEAPPLIES,
	 C.OWNER,
	 C.INSTRUCTOR,
	 C.PRODUCTCODE,
	 C.PARAMETERSOURCE2,
	 C.FEETYPE2,
	 C.FROMEVENTNO,
	 C.DISBSTAFFNAMETYPE,
	 C.SERVSTAFFNAMETYPE,
	 C.DISBDISCFEEFLAG,
	 C.SERVDISCFEEFLAG
from CCImport_FEESCALCULATION I 
	join FEESCALCULATION C	on ( C.CRITERIANO=I.CRITERIANO
	and C.UNIQUEID=I.UNIQUEID)
where 	( I.AGENT <>  C.AGENT OR (I.AGENT is null and C.AGENT is not null) 
OR (I.AGENT is not null and C.AGENT is null))
	OR 	( I.DEBTORTYPE <>  C.DEBTORTYPE OR (I.DEBTORTYPE is null and C.DEBTORTYPE is not null) 
OR (I.DEBTORTYPE is not null and C.DEBTORTYPE is null))
	OR 	( I.DEBTOR <>  C.DEBTOR OR (I.DEBTOR is null and C.DEBTOR is not null) 
OR (I.DEBTOR is not null and C.DEBTOR is null))
	OR 	( I.CYCLENUMBER <>  C.CYCLENUMBER OR (I.CYCLENUMBER is null and C.CYCLENUMBER is not null) 
OR (I.CYCLENUMBER is not null and C.CYCLENUMBER is null))
	OR 	( I.VALIDFROMDATE <>  C.VALIDFROMDATE OR (I.VALIDFROMDATE is null and C.VALIDFROMDATE is not null) 
OR (I.VALIDFROMDATE is not null and C.VALIDFROMDATE is null))
	OR 	( I.DEBITNOTE <>  C.DEBITNOTE OR (I.DEBITNOTE is null and C.DEBITNOTE is not null) 
OR (I.DEBITNOTE is not null and C.DEBITNOTE is null))
	OR 	( I.COVERINGLETTER <>  C.COVERINGLETTER OR (I.COVERINGLETTER is null and C.COVERINGLETTER is not null) 
OR (I.COVERINGLETTER is not null and C.COVERINGLETTER is null))
	OR 	( I.GENERATECHARGES <>  C.GENERATECHARGES OR (I.GENERATECHARGES is null and C.GENERATECHARGES is not null) 
OR (I.GENERATECHARGES is not null and C.GENERATECHARGES is null))
	OR 	( I.FEETYPE <>  C.FEETYPE OR (I.FEETYPE is null and C.FEETYPE is not null) 
OR (I.FEETYPE is not null and C.FEETYPE is null))
	OR 	( I.IPOFFICEFEEFLAG <>  C.IPOFFICEFEEFLAG OR (I.IPOFFICEFEEFLAG is null and C.IPOFFICEFEEFLAG is not null) 
OR (I.IPOFFICEFEEFLAG is not null and C.IPOFFICEFEEFLAG is null))
	OR 	( I.DISBCURRENCY <>  C.DISBCURRENCY OR (I.DISBCURRENCY is null and C.DISBCURRENCY is not null) 
OR (I.DISBCURRENCY is not null and C.DISBCURRENCY is null))
	OR 	( I.DISBTAXCODE <>  C.DISBTAXCODE OR (I.DISBTAXCODE is null and C.DISBTAXCODE is not null) 
OR (I.DISBTAXCODE is not null and C.DISBTAXCODE is null))
	OR 	( I.DISBNARRATIVE <>  C.DISBNARRATIVE OR (I.DISBNARRATIVE is null and C.DISBNARRATIVE is not null) 
OR (I.DISBNARRATIVE is not null and C.DISBNARRATIVE is null))
	OR 	( I.DISBWIPCODE <>  C.DISBWIPCODE OR (I.DISBWIPCODE is null and C.DISBWIPCODE is not null) 
OR (I.DISBWIPCODE is not null and C.DISBWIPCODE is null))
	OR 	( I.DISBBASEFEE <>  C.DISBBASEFEE OR (I.DISBBASEFEE is null and C.DISBBASEFEE is not null) 
OR (I.DISBBASEFEE is not null and C.DISBBASEFEE is null))
	OR 	( I.DISBMINFEEFLAG <>  C.DISBMINFEEFLAG OR (I.DISBMINFEEFLAG is null and C.DISBMINFEEFLAG is not null) 
OR (I.DISBMINFEEFLAG is not null and C.DISBMINFEEFLAG is null))
	OR 	( I.DISBVARIABLEFEE <>  C.DISBVARIABLEFEE OR (I.DISBVARIABLEFEE is null and C.DISBVARIABLEFEE is not null) 
OR (I.DISBVARIABLEFEE is not null and C.DISBVARIABLEFEE is null))
	OR 	( I.DISBADDPERCENTAGE <>  C.DISBADDPERCENTAGE OR (I.DISBADDPERCENTAGE is null and C.DISBADDPERCENTAGE is not null) 
OR (I.DISBADDPERCENTAGE is not null and C.DISBADDPERCENTAGE is null))
	OR 	( I.DISBUNITSIZE <>  C.DISBUNITSIZE OR (I.DISBUNITSIZE is null and C.DISBUNITSIZE is not null) 
OR (I.DISBUNITSIZE is not null and C.DISBUNITSIZE is null))
	OR 	( I.DISBBASEUNITS <>  C.DISBBASEUNITS OR (I.DISBBASEUNITS is null and C.DISBBASEUNITS is not null) 
OR (I.DISBBASEUNITS is not null and C.DISBBASEUNITS is null))
	OR 	( I.SERVICECURRENCY <>  C.SERVICECURRENCY OR (I.SERVICECURRENCY is null and C.SERVICECURRENCY is not null) 
OR (I.SERVICECURRENCY is not null and C.SERVICECURRENCY is null))
	OR 	( I.SERVTAXCODE <>  C.SERVTAXCODE OR (I.SERVTAXCODE is null and C.SERVTAXCODE is not null) 
OR (I.SERVTAXCODE is not null and C.SERVTAXCODE is null))
	OR 	( I.SERVICENARRATIVE <>  C.SERVICENARRATIVE OR (I.SERVICENARRATIVE is null and C.SERVICENARRATIVE is not null) 
OR (I.SERVICENARRATIVE is not null and C.SERVICENARRATIVE is null))
	OR 	( I.SERVWIPCODE <>  C.SERVWIPCODE OR (I.SERVWIPCODE is null and C.SERVWIPCODE is not null) 
OR (I.SERVWIPCODE is not null and C.SERVWIPCODE is null))
	OR 	( I.SERVBASEFEE <>  C.SERVBASEFEE OR (I.SERVBASEFEE is null and C.SERVBASEFEE is not null) 
OR (I.SERVBASEFEE is not null and C.SERVBASEFEE is null))
	OR 	( I.SERVMINFEEFLAG <>  C.SERVMINFEEFLAG OR (I.SERVMINFEEFLAG is null and C.SERVMINFEEFLAG is not null) 
OR (I.SERVMINFEEFLAG is not null and C.SERVMINFEEFLAG is null))
	OR 	( I.SERVVARIABLEFEE <>  C.SERVVARIABLEFEE OR (I.SERVVARIABLEFEE is null and C.SERVVARIABLEFEE is not null) 
OR (I.SERVVARIABLEFEE is not null and C.SERVVARIABLEFEE is null))
	OR 	( I.SERVADDPERCENTAGE <>  C.SERVADDPERCENTAGE OR (I.SERVADDPERCENTAGE is null and C.SERVADDPERCENTAGE is not null) 
OR (I.SERVADDPERCENTAGE is not null and C.SERVADDPERCENTAGE is null))
	OR 	( I.SERVDISBPERCENTAGE <>  C.SERVDISBPERCENTAGE OR (I.SERVDISBPERCENTAGE is null and C.SERVDISBPERCENTAGE is not null) 
OR (I.SERVDISBPERCENTAGE is not null and C.SERVDISBPERCENTAGE is null))
	OR 	( I.SERVUNITSIZE <>  C.SERVUNITSIZE OR (I.SERVUNITSIZE is null and C.SERVUNITSIZE is not null) 
OR (I.SERVUNITSIZE is not null and C.SERVUNITSIZE is null))
	OR 	( I.SERVBASEUNITS <>  C.SERVBASEUNITS OR (I.SERVBASEUNITS is null and C.SERVBASEUNITS is not null) 
OR (I.SERVBASEUNITS is not null and C.SERVBASEUNITS is null))
	OR 	( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null) 
OR (I.INHERITED is not null and C.INHERITED is null))
	OR 	( I.PARAMETERSOURCE <>  C.PARAMETERSOURCE OR (I.PARAMETERSOURCE is null and C.PARAMETERSOURCE is not null) 
OR (I.PARAMETERSOURCE is not null and C.PARAMETERSOURCE is null))
	OR 	( I.DISBMAXUNITS <>  C.DISBMAXUNITS OR (I.DISBMAXUNITS is null and C.DISBMAXUNITS is not null) 
OR (I.DISBMAXUNITS is not null and C.DISBMAXUNITS is null))
	OR 	( I.SERVMAXUNITS <>  C.SERVMAXUNITS OR (I.SERVMAXUNITS is null and C.SERVMAXUNITS is not null) 
OR (I.SERVMAXUNITS is not null and C.SERVMAXUNITS is null))
	OR 	( I.DISBEMPLOYEENO <>  C.DISBEMPLOYEENO OR (I.DISBEMPLOYEENO is null and C.DISBEMPLOYEENO is not null) 
OR (I.DISBEMPLOYEENO is not null and C.DISBEMPLOYEENO is null))
	OR 	( I.SERVEMPLOYEENO <>  C.SERVEMPLOYEENO OR (I.SERVEMPLOYEENO is null and C.SERVEMPLOYEENO is not null) 
OR (I.SERVEMPLOYEENO is not null and C.SERVEMPLOYEENO is null))
	OR 	( I.VARBASEFEE <>  C.VARBASEFEE OR (I.VARBASEFEE is null and C.VARBASEFEE is not null) 
OR (I.VARBASEFEE is not null and C.VARBASEFEE is null))
	OR 	( I.VARBASEUNITS <>  C.VARBASEUNITS OR (I.VARBASEUNITS is null and C.VARBASEUNITS is not null) 
OR (I.VARBASEUNITS is not null and C.VARBASEUNITS is null))
	OR 	( I.VARVARIABLEFEE <>  C.VARVARIABLEFEE OR (I.VARVARIABLEFEE is null and C.VARVARIABLEFEE is not null) 
OR (I.VARVARIABLEFEE is not null and C.VARVARIABLEFEE is null))
	OR 	( I.VARUNITSIZE <>  C.VARUNITSIZE OR (I.VARUNITSIZE is null and C.VARUNITSIZE is not null) 
OR (I.VARUNITSIZE is not null and C.VARUNITSIZE is null))
	OR 	( I.VARMAXUNITS <>  C.VARMAXUNITS OR (I.VARMAXUNITS is null and C.VARMAXUNITS is not null) 
OR (I.VARMAXUNITS is not null and C.VARMAXUNITS is null))
	OR 	( I.VARMINFEEFLAG <>  C.VARMINFEEFLAG OR (I.VARMINFEEFLAG is null and C.VARMINFEEFLAG is not null) 
OR (I.VARMINFEEFLAG is not null and C.VARMINFEEFLAG is null))
	OR 	( I.WRITEUPREASON <>  C.WRITEUPREASON OR (I.WRITEUPREASON is null and C.WRITEUPREASON is not null) 
OR (I.WRITEUPREASON is not null and C.WRITEUPREASON is null))
	OR 	( I.VARWIPCODE <>  C.VARWIPCODE OR (I.VARWIPCODE is null and C.VARWIPCODE is not null) 
OR (I.VARWIPCODE is not null and C.VARWIPCODE is null))
	OR 	( I.VARFEEAPPLIES <>  C.VARFEEAPPLIES OR (I.VARFEEAPPLIES is null and C.VARFEEAPPLIES is not null) 
OR (I.VARFEEAPPLIES is not null and C.VARFEEAPPLIES is null))
	OR 	( I.OWNER <>  C.OWNER OR (I.OWNER is null and C.OWNER is not null) 
OR (I.OWNER is not null and C.OWNER is null))
	OR 	( I.INSTRUCTOR <>  C.INSTRUCTOR OR (I.INSTRUCTOR is null and C.INSTRUCTOR is not null) 
OR (I.INSTRUCTOR is not null and C.INSTRUCTOR is null))
	OR 	( I.PRODUCTCODE <>  C.PRODUCTCODE OR (I.PRODUCTCODE is null and C.PRODUCTCODE is not null) 
OR (I.PRODUCTCODE is not null and C.PRODUCTCODE is null))
	OR 	( I.PARAMETERSOURCE2 <>  C.PARAMETERSOURCE2 OR (I.PARAMETERSOURCE2 is null and C.PARAMETERSOURCE2 is not null) 
OR (I.PARAMETERSOURCE2 is not null and C.PARAMETERSOURCE2 is null))
	OR 	( I.FEETYPE2 <>  C.FEETYPE2 OR (I.FEETYPE2 is null and C.FEETYPE2 is not null) 
OR (I.FEETYPE2 is not null and C.FEETYPE2 is null))
	OR 	( I.FROMEVENTNO <>  C.FROMEVENTNO OR (I.FROMEVENTNO is null and C.FROMEVENTNO is not null) 
OR (I.FROMEVENTNO is not null and C.FROMEVENTNO is null))
	OR 	( I.DISBSTAFFNAMETYPE <>  C.DISBSTAFFNAMETYPE OR (I.DISBSTAFFNAMETYPE is null and C.DISBSTAFFNAMETYPE is not null) 
OR (I.DISBSTAFFNAMETYPE is not null and C.DISBSTAFFNAMETYPE is null))
	OR 	( I.SERVSTAFFNAMETYPE <>  C.SERVSTAFFNAMETYPE OR (I.SERVSTAFFNAMETYPE is null and C.SERVSTAFFNAMETYPE is not null) 
OR (I.SERVSTAFFNAMETYPE is not null and C.SERVSTAFFNAMETYPE is null))
	OR 	( I.DISBDISCFEEFLAG <>  C.DISBDISCFEEFLAG OR (I.DISBDISCFEEFLAG is null and C.DISBDISCFEEFLAG is not null) 
OR (I.DISBDISCFEEFLAG is not null and C.DISBDISCFEEFLAG is null))
	OR 	( I.SERVDISCFEEFLAG <>  C.SERVDISCFEEFLAG OR (I.SERVDISCFEEFLAG is null and C.SERVDISCFEEFLAG is not null) 
OR (I.SERVDISCFEEFLAG is not null and C.SERVDISCFEEFLAG is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_FEESCALCULATION]') and xtype='U')
begin
	drop table CCImport_FEESCALCULATION 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_FEESCALCULATION  to public
go
