-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnFEESCALCULATION
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnFEESCALCULATION]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnFEESCALCULATION.'
	drop function dbo.fn_ccnFEESCALCULATION
	print '**** Creating function dbo.fn_ccnFEESCALCULATION...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
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


CREATE FUNCTION dbo.fn_ccnFEESCALCULATION
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnFEESCALCULATION
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the FEESCALCULATION table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'FEESCALCULATION' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_FEESCALCULATION I 
	right join FEESCALCULATION C on( C.CRITERIANO=I.CRITERIANO
and  C.UNIQUEID=I.UNIQUEID)
where I.CRITERIANO is null
UNION ALL 
select	5, 'FEESCALCULATION', 0, count(*), 0, 0
from CCImport_FEESCALCULATION I 
	left join FEESCALCULATION C on( C.CRITERIANO=I.CRITERIANO
and  C.UNIQUEID=I.UNIQUEID)
where C.CRITERIANO is null
UNION ALL 
 select	5, 'FEESCALCULATION', 0, 0, count(*), 0
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
UNION ALL 
 select	5, 'FEESCALCULATION', 0, 0, 0, count(*)
from CCImport_FEESCALCULATION I 
join FEESCALCULATION C	on( C.CRITERIANO=I.CRITERIANO
and C.UNIQUEID=I.UNIQUEID)
where ( I.AGENT =  C.AGENT OR (I.AGENT is null and C.AGENT is null))
and ( I.DEBTORTYPE =  C.DEBTORTYPE OR (I.DEBTORTYPE is null and C.DEBTORTYPE is null))
and ( I.DEBTOR =  C.DEBTOR OR (I.DEBTOR is null and C.DEBTOR is null))
and ( I.CYCLENUMBER =  C.CYCLENUMBER OR (I.CYCLENUMBER is null and C.CYCLENUMBER is null))
and ( I.VALIDFROMDATE =  C.VALIDFROMDATE OR (I.VALIDFROMDATE is null and C.VALIDFROMDATE is null))
and ( I.DEBITNOTE =  C.DEBITNOTE OR (I.DEBITNOTE is null and C.DEBITNOTE is null))
and ( I.COVERINGLETTER =  C.COVERINGLETTER OR (I.COVERINGLETTER is null and C.COVERINGLETTER is null))
and ( I.GENERATECHARGES =  C.GENERATECHARGES OR (I.GENERATECHARGES is null and C.GENERATECHARGES is null))
and ( I.FEETYPE =  C.FEETYPE OR (I.FEETYPE is null and C.FEETYPE is null))
and ( I.IPOFFICEFEEFLAG =  C.IPOFFICEFEEFLAG OR (I.IPOFFICEFEEFLAG is null and C.IPOFFICEFEEFLAG is null))
and ( I.DISBCURRENCY =  C.DISBCURRENCY OR (I.DISBCURRENCY is null and C.DISBCURRENCY is null))
and ( I.DISBTAXCODE =  C.DISBTAXCODE OR (I.DISBTAXCODE is null and C.DISBTAXCODE is null))
and ( I.DISBNARRATIVE =  C.DISBNARRATIVE OR (I.DISBNARRATIVE is null and C.DISBNARRATIVE is null))
and ( I.DISBWIPCODE =  C.DISBWIPCODE OR (I.DISBWIPCODE is null and C.DISBWIPCODE is null))
and ( I.DISBBASEFEE =  C.DISBBASEFEE OR (I.DISBBASEFEE is null and C.DISBBASEFEE is null))
and ( I.DISBMINFEEFLAG =  C.DISBMINFEEFLAG OR (I.DISBMINFEEFLAG is null and C.DISBMINFEEFLAG is null))
and ( I.DISBVARIABLEFEE =  C.DISBVARIABLEFEE OR (I.DISBVARIABLEFEE is null and C.DISBVARIABLEFEE is null))
and ( I.DISBADDPERCENTAGE =  C.DISBADDPERCENTAGE OR (I.DISBADDPERCENTAGE is null and C.DISBADDPERCENTAGE is null))
and ( I.DISBUNITSIZE =  C.DISBUNITSIZE OR (I.DISBUNITSIZE is null and C.DISBUNITSIZE is null))
and ( I.DISBBASEUNITS =  C.DISBBASEUNITS OR (I.DISBBASEUNITS is null and C.DISBBASEUNITS is null))
and ( I.SERVICECURRENCY =  C.SERVICECURRENCY OR (I.SERVICECURRENCY is null and C.SERVICECURRENCY is null))
and ( I.SERVTAXCODE =  C.SERVTAXCODE OR (I.SERVTAXCODE is null and C.SERVTAXCODE is null))
and ( I.SERVICENARRATIVE =  C.SERVICENARRATIVE OR (I.SERVICENARRATIVE is null and C.SERVICENARRATIVE is null))
and ( I.SERVWIPCODE =  C.SERVWIPCODE OR (I.SERVWIPCODE is null and C.SERVWIPCODE is null))
and ( I.SERVBASEFEE =  C.SERVBASEFEE OR (I.SERVBASEFEE is null and C.SERVBASEFEE is null))
and ( I.SERVMINFEEFLAG =  C.SERVMINFEEFLAG OR (I.SERVMINFEEFLAG is null and C.SERVMINFEEFLAG is null))
and ( I.SERVVARIABLEFEE =  C.SERVVARIABLEFEE OR (I.SERVVARIABLEFEE is null and C.SERVVARIABLEFEE is null))
and ( I.SERVADDPERCENTAGE =  C.SERVADDPERCENTAGE OR (I.SERVADDPERCENTAGE is null and C.SERVADDPERCENTAGE is null))
and ( I.SERVDISBPERCENTAGE =  C.SERVDISBPERCENTAGE OR (I.SERVDISBPERCENTAGE is null and C.SERVDISBPERCENTAGE is null))
and ( I.SERVUNITSIZE =  C.SERVUNITSIZE OR (I.SERVUNITSIZE is null and C.SERVUNITSIZE is null))
and ( I.SERVBASEUNITS =  C.SERVBASEUNITS OR (I.SERVBASEUNITS is null and C.SERVBASEUNITS is null))
and ( I.INHERITED =  C.INHERITED OR (I.INHERITED is null and C.INHERITED is null))
and ( I.PARAMETERSOURCE =  C.PARAMETERSOURCE OR (I.PARAMETERSOURCE is null and C.PARAMETERSOURCE is null))
and ( I.DISBMAXUNITS =  C.DISBMAXUNITS OR (I.DISBMAXUNITS is null and C.DISBMAXUNITS is null))
and ( I.SERVMAXUNITS =  C.SERVMAXUNITS OR (I.SERVMAXUNITS is null and C.SERVMAXUNITS is null))
and ( I.DISBEMPLOYEENO =  C.DISBEMPLOYEENO OR (I.DISBEMPLOYEENO is null and C.DISBEMPLOYEENO is null))
and ( I.SERVEMPLOYEENO =  C.SERVEMPLOYEENO OR (I.SERVEMPLOYEENO is null and C.SERVEMPLOYEENO is null))
and ( I.VARBASEFEE =  C.VARBASEFEE OR (I.VARBASEFEE is null and C.VARBASEFEE is null))
and ( I.VARBASEUNITS =  C.VARBASEUNITS OR (I.VARBASEUNITS is null and C.VARBASEUNITS is null))
and ( I.VARVARIABLEFEE =  C.VARVARIABLEFEE OR (I.VARVARIABLEFEE is null and C.VARVARIABLEFEE is null))
and ( I.VARUNITSIZE =  C.VARUNITSIZE OR (I.VARUNITSIZE is null and C.VARUNITSIZE is null))
and ( I.VARMAXUNITS =  C.VARMAXUNITS OR (I.VARMAXUNITS is null and C.VARMAXUNITS is null))
and ( I.VARMINFEEFLAG =  C.VARMINFEEFLAG OR (I.VARMINFEEFLAG is null and C.VARMINFEEFLAG is null))
and ( I.WRITEUPREASON =  C.WRITEUPREASON OR (I.WRITEUPREASON is null and C.WRITEUPREASON is null))
and ( I.VARWIPCODE =  C.VARWIPCODE OR (I.VARWIPCODE is null and C.VARWIPCODE is null))
and ( I.VARFEEAPPLIES =  C.VARFEEAPPLIES OR (I.VARFEEAPPLIES is null and C.VARFEEAPPLIES is null))
and ( I.OWNER =  C.OWNER OR (I.OWNER is null and C.OWNER is null))
and ( I.INSTRUCTOR =  C.INSTRUCTOR OR (I.INSTRUCTOR is null and C.INSTRUCTOR is null))
and ( I.PRODUCTCODE =  C.PRODUCTCODE OR (I.PRODUCTCODE is null and C.PRODUCTCODE is null))
and ( I.PARAMETERSOURCE2 =  C.PARAMETERSOURCE2 OR (I.PARAMETERSOURCE2 is null and C.PARAMETERSOURCE2 is null))
and ( I.FEETYPE2 =  C.FEETYPE2 OR (I.FEETYPE2 is null and C.FEETYPE2 is null))
and ( I.FROMEVENTNO =  C.FROMEVENTNO OR (I.FROMEVENTNO is null and C.FROMEVENTNO is null))
and ( I.DISBSTAFFNAMETYPE =  C.DISBSTAFFNAMETYPE OR (I.DISBSTAFFNAMETYPE is null and C.DISBSTAFFNAMETYPE is null))
and ( I.SERVSTAFFNAMETYPE =  C.SERVSTAFFNAMETYPE OR (I.SERVSTAFFNAMETYPE is null and C.SERVSTAFFNAMETYPE is null))
and ( I.DISBDISCFEEFLAG =  C.DISBDISCFEEFLAG OR (I.DISBDISCFEEFLAG is null and C.DISBDISCFEEFLAG is null))
and ( I.SERVDISCFEEFLAG =  C.SERVDISCFEEFLAG OR (I.SERVDISCFEEFLAG is null and C.SERVDISCFEEFLAG is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_FEESCALCULATION]') and xtype='U')
begin
	drop table CCImport_FEESCALCULATION 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnFEESCALCULATION  to public
go
