-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xml_CopyConfigExport
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[xml_CopyConfigExport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.xml_CopyConfigExport.'
	drop procedure dbo.xml_CopyConfigExport
	print '**** Creating procedure dbo.xml_CopyConfigExport...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
go

CREATE PROCEDURE [dbo].[xml_CopyConfigExport]
-- no params for complete current set of rules
	
AS

-- PROCEDURE :	xml_CopyConfigExport
-- VERSION :	18
-- DESCRIPTION:	Extract specified data from the database 
-- 		as XML to match the CopyConfigImport.xsd 
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 24 Jan 2012	AvdA		1	Procedure created based on v 16 of xml_RulesExport
-- 22 May 2012	AvdA		2	Regenerated XML statements, handle very long fields with white space as cdata
-- 31 Jul 2012	AvdA		3	Regenerated XML statements, handle very short fields with white space as cdata
--  7 Sep 2012	AvdA		4	Remove TABLEATTRIBUTES, include regenned TABLECODES (column change)
--  3 Oct 2012	AvdA		5	Include genned GROUPMEMBERS
-- 09 Oct 2012  DH		6	Added Policing insert
-- 11 Jun 2013	MF	S21404	7	New column SUPPRESSCALCULATION for EVENTS and EVENTCONTROL tables.
-- 23 Jul 2013	DL	S21395	8	New column NEWSUBTYPE for CRITERIA table.
-- 02 Oct 2014	MF	32711	9	Add copy functionality for TOPICCONTROLFILTER	
-- 19 Dec 2014	AK	14192	10	Removed STATUSSEQUENCE references
-- 04 Oct 2016	MF	64418	11	New columns NOTEGROUP and NOTESSHAREDACROSCYCLES for EVENTS.	
-- 03 Apr 2017	MF	71020	12	New columns added.
-- 01 May 2017	MF	71205	13	New columns added.
-- 29 Apr 2019	MF	DR-41987 13	New Columns.
-- 29 Apr 2019	MF	DR-41987 14	New Column. NAMETYPE.NATIONALITYFLAG
-- 21 Aug 2019	MF	DR-42774 15	Added PROGRAM table.
-- 21 Aug 2019	MF	DR-36783 16	Added FORMFIELDS table
-- 21 Aug 2019	MF	DR-51238 16	Added CONFIGURATIONITEMGROUP table
-- 06 Dec 2019	MF	DR-28833 17	Added EVENTTEXTTYPE table
-- 19 Dec 2019	MF	DR-55248 18	Looks like a merge problem.  Reimplemented NAMETYPE.NATIONALITYFLAG.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare @nErrorCode	int
declare	@sSQLString	nvarchar(max)

Set @nErrorCode=0

-- Generated code only below this line until next - do not edit
---------------------------------------------------------------------

if @nErrorCode = 0
begin
	select '<Acct_trans_type>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
TRANS_TYPE_ID as [ACCT_TRANS_TYPE!1!ACCT_TRANS_TYPE_Trans_type_id!element],
DESCRIPTION as [ACCT_TRANS_TYPE!1!ACCT_TRANS_TYPE_Description!element],
USED_BY as [ACCT_TRANS_TYPE!1!ACCT_TRANS_TYPE_Used_by!element],
REVERSE_TRANS_TYPE as [ACCT_TRANS_TYPE!1!ACCT_TRANS_TYPE_Reverse_trans_type!element]
FROM ACCT_TRANS_TYPE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Acct_trans_type>'
end

if @nErrorCode = 0
begin
	select '<Actions>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
ACTION as [ACTIONS!1!ACTIONS_Action!cdata],
ACTIONNAME as [ACTIONS!1!ACTIONS_Actionname!element],
NUMCYCLESALLOWED as [ACTIONS!1!ACTIONS_Numcyclesallowed!element],
ACTIONTYPEFLAG as [ACTIONS!1!ACTIONS_Actiontypeflag!element],
IMPORTANCELEVEL as [ACTIONS!1!ACTIONS_Importancelevel!cdata]
FROM ACTIONS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Actions>'
end

if @nErrorCode = 0
begin
	select '<Adjustment>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
ADJUSTMENT as [ADJUSTMENT!1!ADJUSTMENT_Adjustment!element],
ADJUSTMENTDESC as [ADJUSTMENT!1!ADJUSTMENT_Adjustmentdesc!element],
ADJUSTDAY as [ADJUSTMENT!1!ADJUSTMENT_Adjustday!element],
ADJUSTMONTH as [ADJUSTMENT!1!ADJUSTMENT_Adjustmonth!element],
ADJUSTYEAR as [ADJUSTMENT!1!ADJUSTMENT_Adjustyear!element],
ADJUSTAMOUNT as [ADJUSTMENT!1!ADJUSTMENT_Adjustamount!element],
PERIODTYPE as [ADJUSTMENT!1!ADJUSTMENT_Periodtype!element]
FROM ADJUSTMENT
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Adjustment>'
end

if @nErrorCode = 0
begin
	select '<Airport>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
AIRPORTCODE as [AIRPORT!1!AIRPORT_Airportcode!element],
AIRPORTNAME as [AIRPORT!1!AIRPORT_Airportname!element],
COUNTRYCODE as [AIRPORT!1!AIRPORT_Countrycode!cdata],
STATE as [AIRPORT!1!AIRPORT_State!element],
CITY as [AIRPORT!1!AIRPORT_City!element]
FROM AIRPORT
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Airport>'
end

if @nErrorCode = 0
begin
	select '<Alerttemplate>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
ALERTTEMPLATECODE as [ALERTTEMPLATE!1!ALERTTEMPLATE_Alerttemplatecode!element],
ALERTMESSAGE as [ALERTTEMPLATE!1!ALERTTEMPLATE_Alertmessage!cdata],
EMAILSUBJECT as [ALERTTEMPLATE!1!ALERTTEMPLATE_Emailsubject!element],
SENDELECTRONICALLY as [ALERTTEMPLATE!1!ALERTTEMPLATE_Sendelectronically!element],
IMPORTANCELEVEL as [ALERTTEMPLATE!1!ALERTTEMPLATE_Importancelevel!cdata],
DAYSLEAD as [ALERTTEMPLATE!1!ALERTTEMPLATE_Dayslead!element],
DAILYFREQUENCY as [ALERTTEMPLATE!1!ALERTTEMPLATE_Dailyfrequency!element],
MONTHSLEAD as [ALERTTEMPLATE!1!ALERTTEMPLATE_Monthslead!element],
MONTHLYFREQUENCY as [ALERTTEMPLATE!1!ALERTTEMPLATE_Monthlyfrequency!element],
STOPALERT as [ALERTTEMPLATE!1!ALERTTEMPLATE_Stopalert!element],
DELETEALERT as [ALERTTEMPLATE!1!ALERTTEMPLATE_Deletealert!element],
EMPLOYEEFLAG as [ALERTTEMPLATE!1!ALERTTEMPLATE_Employeeflag!element],
CRITICALFLAG as [ALERTTEMPLATE!1!ALERTTEMPLATE_Criticalflag!element],
SIGNATORYFLAG as [ALERTTEMPLATE!1!ALERTTEMPLATE_Signatoryflag!element],
NAMETYPE as [ALERTTEMPLATE!1!ALERTTEMPLATE_Nametype!cdata],
RELATIONSHIP as [ALERTTEMPLATE!1!ALERTTEMPLATE_Relationship!cdata],
EMPLOYEENO as [ALERTTEMPLATE!1!ALERTTEMPLATE_Employeeno!element]
FROM ALERTTEMPLATE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Alerttemplate>'
end

if @nErrorCode = 0
begin
	select '<Aliastype>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
ALIASTYPE as [ALIASTYPE!1!ALIASTYPE_Aliastype!cdata],
ALIASDESCRIPTION as [ALIASTYPE!1!ALIASTYPE_Aliasdescription!element],
MUSTBEUNIQUE as [ALIASTYPE!1!ALIASTYPE_Mustbeunique!element]
FROM ALIASTYPE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Aliastype>'
end

if @nErrorCode = 0
begin
	select '<Analysiscode>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CODEID as [ANALYSISCODE!1!ANALYSISCODE_Codeid!element],
CODE as [ANALYSISCODE!1!ANALYSISCODE_Code!element],
DESCRIPTION as [ANALYSISCODE!1!ANALYSISCODE_Description!element],
TYPEID as [ANALYSISCODE!1!ANALYSISCODE_Typeid!element]
FROM ANALYSISCODE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Analysiscode>'
end

if @nErrorCode = 0
begin
	select '<Applicationbasis>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
BASIS as [APPLICATIONBASIS!1!APPLICATIONBASIS_Basis!cdata],
BASISDESCRIPTION as [APPLICATIONBASIS!1!APPLICATIONBASIS_Basisdescription!element],
CONVENTION as [APPLICATIONBASIS!1!APPLICATIONBASIS_Convention!element]
FROM APPLICATIONBASIS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Applicationbasis>'
end

if @nErrorCode = 0
begin
	select '<Attributes>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
ATTRIBUTEID as [ATTRIBUTES!1!ATTRIBUTES_Attributeid!element],
ATTRIBUTENAME as [ATTRIBUTES!1!ATTRIBUTES_Attributename!element],
DATATYPE as [ATTRIBUTES!1!ATTRIBUTES_Datatype!element],
TABLENAME as [ATTRIBUTES!1!ATTRIBUTES_Tablename!element],
FILTERVALUE as [ATTRIBUTES!1!ATTRIBUTES_Filtervalue!cdata]
FROM ATTRIBUTES
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Attributes>'
end

if @nErrorCode = 0
begin
	select '<B2belement>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
ELEMENTID as [B2BELEMENT!1!B2BELEMENT_Elementid!element],
COUNTRY as [B2BELEMENT!1!B2BELEMENT_Country!cdata],
SETTINGID as [B2BELEMENT!1!B2BELEMENT_Settingid!element],
ELEMENTNAME as [B2BELEMENT!1!B2BELEMENT_Elementname!element],
VALUE as [B2BELEMENT!1!B2BELEMENT_Value!element],
INUSE as [B2BELEMENT!1!B2BELEMENT_Inuse!element],
DESCRIPTION as [B2BELEMENT!1!B2BELEMENT_Description!cdata]
FROM B2BELEMENT
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</B2belement>'
end

if @nErrorCode = 0
begin
	select '<B2btaskevent>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
PACKAGETYPE as [B2BTASKEVENT!1!B2BTASKEVENT_Packagetype!element],
TASKTYPE as [B2BTASKEVENT!1!B2BTASKEVENT_Tasktype!element],
EVENTNO as [B2BTASKEVENT!1!B2BTASKEVENT_Eventno!element],
TASKORDER as [B2BTASKEVENT!1!B2BTASKEVENT_Taskorder!element],
AUTOMATICFLAG as [B2BTASKEVENT!1!B2BTASKEVENT_Automaticflag!element],
FINALFLAG as [B2BTASKEVENT!1!B2BTASKEVENT_Finalflag!element],
RETROEVENTNO as [B2BTASKEVENT!1!B2BTASKEVENT_Retroeventno!element],
PROMPT as [B2BTASKEVENT!1!B2BTASKEVENT_Prompt!cdata],
COLLECTFILE as [B2BTASKEVENT!1!B2BTASKEVENT_Collectfile!cdata],
IMPORTMETHODNO as [B2BTASKEVENT!1!B2BTASKEVENT_Importmethodno!element],
XMLINSTRUCTION as [B2BTASKEVENT!1!B2BTASKEVENT_Xmlinstruction!cdata],
LETTERNO as [B2BTASKEVENT!1!B2BTASKEVENT_Letterno!element]
FROM B2BTASKEVENT
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</B2btaskevent>'
end

if @nErrorCode = 0
begin
	select '<Businessfunction>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
FUNCTIONTYPE as [BUSINESSFUNCTION!1!BUSINESSFUNCTION_Functiontype!element],
DESCRIPTION as [BUSINESSFUNCTION!1!BUSINESSFUNCTION_Description!element],
OWNERALLOWED as [BUSINESSFUNCTION!1!BUSINESSFUNCTION_Ownerallowed!element],
PRIVILEGESALLOWED as [BUSINESSFUNCTION!1!BUSINESSFUNCTION_Privilegesallowed!element]
FROM BUSINESSFUNCTION
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Businessfunction>'
end

if @nErrorCode = 0
begin
	select '<Businessrulecontrol>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
BUSINESSRULENO as [BUSINESSRULECONTROL!1!BUSINESSRULECONTROL_Businessruleno!element],
TOPICCONTROLNO as [BUSINESSRULECONTROL!1!BUSINESSRULECONTROL_Topiccontrolno!element],
RULETYPE as [BUSINESSRULECONTROL!1!BUSINESSRULECONTROL_Ruletype!element],
SEQUENCE as [BUSINESSRULECONTROL!1!BUSINESSRULECONTROL_Sequence!element],
VALUE as [BUSINESSRULECONTROL!1!BUSINESSRULECONTROL_Value!cdata],
ISINHERITED as [BUSINESSRULECONTROL!1!BUSINESSRULECONTROL_Isinherited!element]
FROM BUSINESSRULECONTROL
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Businessrulecontrol>'
end

if @nErrorCode = 0
begin
	select '<Casecategory>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CASETYPE as [CASECATEGORY!1!CASECATEGORY_Casetype!cdata],
CASECATEGORY as [CASECATEGORY!1!CASECATEGORY_Casecategory!cdata],
CASECATEGORYDESC as [CASECATEGORY!1!CASECATEGORY_Casecategorydesc!element],
CONVENTIONLITERAL as [CASECATEGORY!1!CASECATEGORY_Conventionliteral!element]
FROM CASECATEGORY
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Casecategory>'
end

if @nErrorCode = 0
begin
	select '<Caserelation>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
RELATIONSHIP as [CASERELATION!1!CASERELATION_Relationship!cdata],
EVENTNO as [CASERELATION!1!CASERELATION_Eventno!element],
EARLIESTDATEFLAG as [CASERELATION!1!CASERELATION_Earliestdateflag!element],
SHOWFLAG as [CASERELATION!1!CASERELATION_Showflag!element],
RELATIONSHIPDESC as [CASERELATION!1!CASERELATION_Relationshipdesc!element],
POINTERTOPARENT as [CASERELATION!1!CASERELATION_Pointertoparent!element],
DISPLAYEVENTONLY as [CASERELATION!1!CASERELATION_Displayeventonly!element],
FROMEVENTNO as [CASERELATION!1!CASERELATION_Fromeventno!element],
DISPLAYEVENTNO as [CASERELATION!1!CASERELATION_Displayeventno!element],
PRIORARTFLAG as [CASERELATION!1!CASERELATION_Priorartflag!element]
FROM CASERELATION
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Caserelation>'
end

if @nErrorCode = 0
begin
	select '<Casetype>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CASETYPE as [CASETYPE!1!CASETYPE_Casetype!cdata],
CASETYPEDESC as [CASETYPE!1!CASETYPE_Casetypedesc!element],
ACTUALCASETYPE as [CASETYPE!1!CASETYPE_Actualcasetype!cdata],
CRMONLY as [CASETYPE!1!CASETYPE_Crmonly!element],
KOTTEXTTYPE as [CASETYPE!1!CASETYPE_Kottexttype!cdata],
PROGRAM as [CASETYPE!1!CASETYPE_Program!element]
FROM CASETYPE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Casetype>'
end

if @nErrorCode = 0
begin
	select '<Chargerates>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CHARGETYPENO as [CHARGERATES!1!CHARGERATES_Chargetypeno!element],
RATENO as [CHARGERATES!1!CHARGERATES_Rateno!element],
SEQUENCENO as [CHARGERATES!1!CHARGERATES_Sequenceno!element],
CASETYPE as [CHARGERATES!1!CHARGERATES_Casetype!cdata],
CASECATEGORY as [CHARGERATES!1!CHARGERATES_Casecategory!cdata],
PROPERTYTYPE as [CHARGERATES!1!CHARGERATES_Propertytype!cdata],
COUNTRYCODE as [CHARGERATES!1!CHARGERATES_Countrycode!cdata],
SUBTYPE as [CHARGERATES!1!CHARGERATES_Subtype!cdata],
INSTRUCTIONTYPE as [CHARGERATES!1!CHARGERATES_Instructiontype!cdata],
FLAGNUMBER as [CHARGERATES!1!CHARGERATES_Flagnumber!element]
FROM CHARGERATES
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Chargerates>'
end

if @nErrorCode = 0
begin
	select '<Chargetype>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CHARGETYPENO as [CHARGETYPE!1!CHARGETYPE_Chargetypeno!element],
CHARGEDESC as [CHARGETYPE!1!CHARGETYPE_Chargedesc!element],
USEDASFLAG as [CHARGETYPE!1!CHARGETYPE_Usedasflag!element],
CHARGEDUEEVENT as [CHARGETYPE!1!CHARGETYPE_Chargedueevent!element],
CHARGEINCURREDEVENT as [CHARGETYPE!1!CHARGETYPE_Chargeincurredevent!element],
PUBLICFLAG as [CHARGETYPE!1!CHARGETYPE_Publicflag!element]
FROM CHARGETYPE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Chargetype>'
end

if @nErrorCode = 0
begin
	select '<Checklistitem>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [CHECKLISTITEM!1!CHECKLISTITEM_Criteriano!element],
QUESTIONNO as [CHECKLISTITEM!1!CHECKLISTITEM_Questionno!element],
SEQUENCENO as [CHECKLISTITEM!1!CHECKLISTITEM_Sequenceno!element],
QUESTION as [CHECKLISTITEM!1!CHECKLISTITEM_Question!element],
YESNOREQUIRED as [CHECKLISTITEM!1!CHECKLISTITEM_Yesnorequired!element],
COUNTREQUIRED as [CHECKLISTITEM!1!CHECKLISTITEM_Countrequired!element],
PERIODTYPEREQUIRED as [CHECKLISTITEM!1!CHECKLISTITEM_Periodtyperequired!element],
AMOUNTREQUIRED as [CHECKLISTITEM!1!CHECKLISTITEM_Amountrequired!element],
DATEREQUIRED as [CHECKLISTITEM!1!CHECKLISTITEM_Daterequired!element],
EMPLOYEEREQUIRED as [CHECKLISTITEM!1!CHECKLISTITEM_Employeerequired!element],
TEXTREQUIRED as [CHECKLISTITEM!1!CHECKLISTITEM_Textrequired!element],
PAYFEECODE as [CHECKLISTITEM!1!CHECKLISTITEM_Payfeecode!cdata],
UPDATEEVENTNO as [CHECKLISTITEM!1!CHECKLISTITEM_Updateeventno!element],
DUEDATEFLAG as [CHECKLISTITEM!1!CHECKLISTITEM_Duedateflag!element],
YESRATENO as [CHECKLISTITEM!1!CHECKLISTITEM_Yesrateno!element],
NORATENO as [CHECKLISTITEM!1!CHECKLISTITEM_Norateno!element],
YESCHECKLISTTYPE as [CHECKLISTITEM!1!CHECKLISTITEM_Yeschecklisttype!element],
NOCHECKLISTTYPE as [CHECKLISTITEM!1!CHECKLISTITEM_Nochecklisttype!element],
INHERITED as [CHECKLISTITEM!1!CHECKLISTITEM_Inherited!element],
NODUEDATEFLAG as [CHECKLISTITEM!1!CHECKLISTITEM_Noduedateflag!element],
NOEVENTNO as [CHECKLISTITEM!1!CHECKLISTITEM_Noeventno!element],
ESTIMATEFLAG as [CHECKLISTITEM!1!CHECKLISTITEM_Estimateflag!element],
DIRECTPAYFLAG as [CHECKLISTITEM!1!CHECKLISTITEM_Directpayflag!element],
SOURCEQUESTION as [CHECKLISTITEM!1!CHECKLISTITEM_Sourcequestion!element],
ANSWERSOURCEYES as [CHECKLISTITEM!1!CHECKLISTITEM_Answersourceyes!element],
ANSWERSOURCENO as [CHECKLISTITEM!1!CHECKLISTITEM_Answersourceno!element]
FROM CHECKLISTITEM
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Checklistitem>'
end

if @nErrorCode = 0
begin
	select '<Checklistletter>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [CHECKLISTLETTER!1!CHECKLISTLETTER_Criteriano!element],
LETTERNO as [CHECKLISTLETTER!1!CHECKLISTLETTER_Letterno!element],
QUESTIONNO as [CHECKLISTLETTER!1!CHECKLISTLETTER_Questionno!element],
REQUIREDANSWER as [CHECKLISTLETTER!1!CHECKLISTLETTER_Requiredanswer!element],
INHERITED as [CHECKLISTLETTER!1!CHECKLISTLETTER_Inherited!element]
FROM CHECKLISTLETTER
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Checklistletter>'
end

if @nErrorCode = 0
begin
	select '<Checklists>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CHECKLISTTYPE as [CHECKLISTS!1!CHECKLISTS_Checklisttype!element],
CHECKLISTDESC as [CHECKLISTS!1!CHECKLISTS_Checklistdesc!element],
CHECKLISTTYPEFLAG as [CHECKLISTS!1!CHECKLISTS_Checklisttypeflag!element]
FROM CHECKLISTS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Checklists>'
end

if @nErrorCode = 0
begin
	select '<Configurationitem>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CONFIGITEMID as [CONFIGURATIONITEM!1!CONFIGURATIONITEM_Configitemid!element],
TASKID as [CONFIGURATIONITEM!1!CONFIGURATIONITEM_Taskid!element],
CONTEXTID as [CONFIGURATIONITEM!1!CONFIGURATIONITEM_Contextid!element],
TITLE as [CONFIGURATIONITEM!1!CONFIGURATIONITEM_Title!cdata],
DESCRIPTION as [CONFIGURATIONITEM!1!CONFIGURATIONITEM_Description!cdata],
GENERICPARAM as [CONFIGURATIONITEM!1!CONFIGURATIONITEM_Genericparam!element],
GROUPID as [CONFIGURATIONITEM!1!CONFIGURATIONITEM_Groupid!element],
URL as [CONFIGURATIONITEM!1!CONFIGURATIONITEM_Url!element]
FROM CONFIGURATIONITEM
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Configurationitem>'
end

if @nErrorCode = 0
begin
	select '<Configurationitemgroup>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
ID as [CONFIGURATIONITEMGROUP!1!CONFIGURATIONITEMGROUP_Id!element],
TITLE as [CONFIGURATIONITEMGROUP!1!CONFIGURATIONITEMGROUP_Title!cdata],
DESCRIPTION as [CONFIGURATIONITEMGROUP!1!CONFIGURATIONITEMGROUP_Description!cdata],
URL as [CONFIGURATIONITEMGROUP!1!CONFIGURATIONITEMGROUP_Url!element]
FROM CONFIGURATIONITEMGROUP
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Configurationitemgroup>'
end

if @nErrorCode = 0
begin
	select '<Copyprofile>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
PROFILENAME as [COPYPROFILE!1!COPYPROFILE_Profilename!element],
SEQUENCENO as [COPYPROFILE!1!COPYPROFILE_Sequenceno!element],
COPYAREA as [COPYPROFILE!1!COPYPROFILE_Copyarea!element],
CHARACTERKEY as [COPYPROFILE!1!COPYPROFILE_Characterkey!cdata],
NUMERICKEY as [COPYPROFILE!1!COPYPROFILE_Numerickey!element],
REPLACEMENTDATA as [COPYPROFILE!1!COPYPROFILE_Replacementdata!cdata],
PROTECTCOPY as [COPYPROFILE!1!COPYPROFILE_Protectcopy!element],
STOPCOPY as [COPYPROFILE!1!COPYPROFILE_Stopcopy!element],
CRMONLY as [COPYPROFILE!1!COPYPROFILE_Crmonly!element]
FROM COPYPROFILE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Copyprofile>'
end

if @nErrorCode = 0
begin
	select '<Correspondto>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CORRESPONDTYPE as [CORRESPONDTO!1!CORRESPONDTO_Correspondtype!element],
DESCRIPTION as [CORRESPONDTO!1!CORRESPONDTO_Description!element],
NAMETYPE as [CORRESPONDTO!1!CORRESPONDTO_Nametype!cdata],
COPIESTO as [CORRESPONDTO!1!CORRESPONDTO_Copiesto!cdata]
FROM CORRESPONDTO
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Correspondto>'
end

if @nErrorCode = 0
begin
	select '<Country>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
COUNTRYCODE as [COUNTRY!1!COUNTRY_Countrycode!cdata],
ALTERNATECODE as [COUNTRY!1!COUNTRY_Alternatecode!cdata],
COUNTRY as [COUNTRY!1!COUNTRY_Country!element],
INFORMALNAME as [COUNTRY!1!COUNTRY_Informalname!element],
COUNTRYABBREV as [COUNTRY!1!COUNTRY_Countryabbrev!element],
COUNTRYADJECTIVE as [COUNTRY!1!COUNTRY_Countryadjective!element],
RECORDTYPE as [COUNTRY!1!COUNTRY_Recordtype!cdata],
ISD as [COUNTRY!1!COUNTRY_Isd!element],
STATELITERAL as [COUNTRY!1!COUNTRY_Stateliteral!element],
POSTCODELITERAL as [COUNTRY!1!COUNTRY_Postcodeliteral!element],
POSTCODEFIRST as [COUNTRY!1!COUNTRY_Postcodefirst!element],
WORKDAYFLAG as [COUNTRY!1!COUNTRY_Workdayflag!element],
DATECOMMENCED as [COUNTRY!1!COUNTRY_Datecommenced!element],
DATECEASED as [COUNTRY!1!COUNTRY_Dateceased!element],
NOTES as [COUNTRY!1!COUNTRY_Notes!cdata],
STATEABBREVIATED as [COUNTRY!1!COUNTRY_Stateabbreviated!element],
ALLMEMBERSFLAG as [COUNTRY!1!COUNTRY_Allmembersflag!element],
NAMESTYLE as [COUNTRY!1!COUNTRY_Namestyle!element],
ADDRESSSTYLE as [COUNTRY!1!COUNTRY_Addressstyle!element],
DEFAULTTAXCODE as [COUNTRY!1!COUNTRY_Defaulttaxcode!cdata],
REQUIREEXEMPTTAXNO as [COUNTRY!1!COUNTRY_Requireexempttaxno!element],
DEFAULTCURRENCY as [COUNTRY!1!COUNTRY_Defaultcurrency!cdata],
POSTCODESEARCHCODE as [COUNTRY!1!COUNTRY_Postcodesearchcode!element],
POSTCODEAUTOFLAG as [COUNTRY!1!COUNTRY_Postcodeautoflag!element],
POSTALNAME as [COUNTRY!1!COUNTRY_Postalname!element],
PRIORARTFLAG as [COUNTRY!1!COUNTRY_Priorartflag!element]
FROM COUNTRY
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Country>'
end

if @nErrorCode = 0
begin
	select '<Countryflags>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
COUNTRYCODE as [COUNTRYFLAGS!1!COUNTRYFLAGS_Countrycode!cdata],
FLAGNUMBER as [COUNTRYFLAGS!1!COUNTRYFLAGS_Flagnumber!element],
FLAGNAME as [COUNTRYFLAGS!1!COUNTRYFLAGS_Flagname!element],
NATIONALALLOWED as [COUNTRYFLAGS!1!COUNTRYFLAGS_Nationalallowed!element],
RESTRICTREMOVALFLG as [COUNTRYFLAGS!1!COUNTRYFLAGS_Restrictremovalflg!element],
PROFILENAME as [COUNTRYFLAGS!1!COUNTRYFLAGS_Profilename!element],
STATUS as [COUNTRYFLAGS!1!COUNTRYFLAGS_Status!element]
FROM COUNTRYFLAGS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Countryflags>'
end

if @nErrorCode = 0
begin
	select '<Countrygroup>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
TREATYCODE as [COUNTRYGROUP!1!COUNTRYGROUP_Treatycode!cdata],
MEMBERCOUNTRY as [COUNTRYGROUP!1!COUNTRYGROUP_Membercountry!cdata],
DATECOMMENCED as [COUNTRYGROUP!1!COUNTRYGROUP_Datecommenced!element],
DATECEASED as [COUNTRYGROUP!1!COUNTRYGROUP_Dateceased!element],
ASSOCIATEMEMBER as [COUNTRYGROUP!1!COUNTRYGROUP_Associatemember!element],
DEFAULTFLAG as [COUNTRYGROUP!1!COUNTRYGROUP_Defaultflag!element],
PREVENTNATPHASE as [COUNTRYGROUP!1!COUNTRYGROUP_Preventnatphase!element],
FULLMEMBERDATE as [COUNTRYGROUP!1!COUNTRYGROUP_Fullmemberdate!element]
FROM COUNTRYGROUP
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Countrygroup>'
end

if @nErrorCode = 0
begin
	select '<Countrytext>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
COUNTRYCODE as [COUNTRYTEXT!1!COUNTRYTEXT_Countrycode!cdata],
TEXTID as [COUNTRYTEXT!1!COUNTRYTEXT_Textid!element],
SEQUENCE as [COUNTRYTEXT!1!COUNTRYTEXT_Sequence!element],
PROPERTYTYPE as [COUNTRYTEXT!1!COUNTRYTEXT_Propertytype!cdata],
MODIFIEDDATE as [COUNTRYTEXT!1!COUNTRYTEXT_Modifieddate!element],
LANGUAGE as [COUNTRYTEXT!1!COUNTRYTEXT_Language!element],
USEFLAG as [COUNTRYTEXT!1!COUNTRYTEXT_Useflag!element],
COUNTRYTEXT as [COUNTRYTEXT!1!COUNTRYTEXT_Countrytext!cdata]
FROM COUNTRYTEXT
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Countrytext>'
end

if @nErrorCode = 0
begin
	select '<Cpaeventcode>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CPAEVENTCODE as [CPAEVENTCODE!1!CPAEVENTCODE_Cpaeventcode!cdata],
DESCRIPTION as [CPAEVENTCODE!1!CPAEVENTCODE_Description!element],
CASEEVENTNO as [CPAEVENTCODE!1!CPAEVENTCODE_Caseeventno!element]
FROM CPAEVENTCODE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Cpaeventcode>'
end

if @nErrorCode = 0
begin
	select '<Cpanarrative>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CPANARRATIVE as [CPANARRATIVE!1!CPANARRATIVE_Cpanarrative!element],
CASEEVENTNO as [CPANARRATIVE!1!CPANARRATIVE_Caseeventno!element],
EXCLUDEFLAG as [CPANARRATIVE!1!CPANARRATIVE_Excludeflag!element],
NARRATIVEDESC as [CPANARRATIVE!1!CPANARRATIVE_Narrativedesc!cdata]
FROM CPANARRATIVE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Cpanarrative>'
end

if @nErrorCode = 0
begin
	select '<Criteria>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [CRITERIA!1!CRITERIA_Criteriano!element],
PURPOSECODE as [CRITERIA!1!CRITERIA_Purposecode!cdata],
CASETYPE as [CRITERIA!1!CRITERIA_Casetype!cdata],
ACTION as [CRITERIA!1!CRITERIA_Action!cdata],
CHECKLISTTYPE as [CRITERIA!1!CRITERIA_Checklisttype!element],
PROGRAMID as [CRITERIA!1!CRITERIA_Programid!element],
PROPERTYTYPE as [CRITERIA!1!CRITERIA_Propertytype!cdata],
PROPERTYUNKNOWN as [CRITERIA!1!CRITERIA_Propertyunknown!element],
COUNTRYCODE as [CRITERIA!1!CRITERIA_Countrycode!cdata],
COUNTRYUNKNOWN as [CRITERIA!1!CRITERIA_Countryunknown!element],
CASECATEGORY as [CRITERIA!1!CRITERIA_Casecategory!cdata],
CATEGORYUNKNOWN as [CRITERIA!1!CRITERIA_Categoryunknown!element],
SUBTYPE as [CRITERIA!1!CRITERIA_Subtype!cdata],
SUBTYPEUNKNOWN as [CRITERIA!1!CRITERIA_Subtypeunknown!element],
BASIS as [CRITERIA!1!CRITERIA_Basis!cdata],
REGISTEREDUSERS as [CRITERIA!1!CRITERIA_Registeredusers!cdata],
LOCALCLIENTFLAG as [CRITERIA!1!CRITERIA_Localclientflag!element],
TABLECODE as [CRITERIA!1!CRITERIA_Tablecode!element],
RATENO as [CRITERIA!1!CRITERIA_Rateno!element],
DATEOFACT as [CRITERIA!1!CRITERIA_Dateofact!element],
USERDEFINEDRULE as [CRITERIA!1!CRITERIA_Userdefinedrule!element],
RULEINUSE as [CRITERIA!1!CRITERIA_Ruleinuse!element],
STARTDETAILENTRY as [CRITERIA!1!CRITERIA_Startdetailentry!element],
PARENTCRITERIA as [CRITERIA!1!CRITERIA_Parentcriteria!element],
BELONGSTOGROUP as [CRITERIA!1!CRITERIA_Belongstogroup!element],
DESCRIPTION as [CRITERIA!1!CRITERIA_Description!cdata],
TYPEOFMARK as [CRITERIA!1!CRITERIA_Typeofmark!element],
RENEWALTYPE as [CRITERIA!1!CRITERIA_Renewaltype!element],
CASEOFFICEID as [CRITERIA!1!CRITERIA_Caseofficeid!element],
LINKTITLE as [CRITERIA!1!CRITERIA_Linktitle!element],
LINKDESCRIPTION as [CRITERIA!1!CRITERIA_Linkdescription!cdata],
DOCITEMID as [CRITERIA!1!CRITERIA_Docitemid!element],
URL as [CRITERIA!1!CRITERIA_Url!cdata],
ISPUBLIC as [CRITERIA!1!CRITERIA_Ispublic!element],
GROUPID as [CRITERIA!1!CRITERIA_Groupid!element],
PRODUCTCODE as [CRITERIA!1!CRITERIA_Productcode!element],
NEWCASETYPE as [CRITERIA!1!CRITERIA_Newcasetype!cdata],
NEWCOUNTRYCODE as [CRITERIA!1!CRITERIA_Newcountrycode!cdata],
NEWPROPERTYTYPE as [CRITERIA!1!CRITERIA_Newpropertytype!cdata],
NEWCASECATEGORY as [CRITERIA!1!CRITERIA_Newcasecategory!cdata],
NEWSUBTYPE as  [CRITERIA!1!CRITERIA_Newsubtype!cdata],
PROFILENAME as [CRITERIA!1!CRITERIA_Profilename!element],
SYSTEMID as [CRITERIA!1!CRITERIA_Systemid!element],
DATAEXTRACTID as [CRITERIA!1!CRITERIA_Dataextractid!element],
RULETYPE as [CRITERIA!1!CRITERIA_Ruletype!element],
REQUESTTYPE as [CRITERIA!1!CRITERIA_Requesttype!element],
DATASOURCETYPE as [CRITERIA!1!CRITERIA_Datasourcetype!element],
DATASOURCENAMENO as [CRITERIA!1!CRITERIA_Datasourcenameno!element],
RENEWALSTATUS as [CRITERIA!1!CRITERIA_Renewalstatus!element],
STATUSCODE as [CRITERIA!1!CRITERIA_Statuscode!element],
PROFILEID as [CRITERIA!1!CRITERIA_Profileid!element]
FROM CRITERIA
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Criteria>'
end

if @nErrorCode = 0
begin
	select '<Criteria_items>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIA_ID as [CRITERIA_ITEMS!1!CRITERIA_ITEMS_Criteria_id!element],
DESCRIPTION as [CRITERIA_ITEMS!1!CRITERIA_ITEMS_Description!element],
QUERY as [CRITERIA_ITEMS!1!CRITERIA_ITEMS_Query!cdata],
CELL1 as [CRITERIA_ITEMS!1!CRITERIA_ITEMS_Cell1!element],
LITERAL1 as [CRITERIA_ITEMS!1!CRITERIA_ITEMS_Literal1!element],
CELL2 as [CRITERIA_ITEMS!1!CRITERIA_ITEMS_Cell2!element],
LITERAL2 as [CRITERIA_ITEMS!1!CRITERIA_ITEMS_Literal2!element],
CELL3 as [CRITERIA_ITEMS!1!CRITERIA_ITEMS_Cell3!element],
LITERAL3 as [CRITERIA_ITEMS!1!CRITERIA_ITEMS_Literal3!element],
CELL4 as [CRITERIA_ITEMS!1!CRITERIA_ITEMS_Cell4!element],
LITERAL4 as [CRITERIA_ITEMS!1!CRITERIA_ITEMS_Literal4!element],
CELL5 as [CRITERIA_ITEMS!1!CRITERIA_ITEMS_Cell5!element],
LITERAL5 as [CRITERIA_ITEMS!1!CRITERIA_ITEMS_Literal5!element],
CELL6 as [CRITERIA_ITEMS!1!CRITERIA_ITEMS_Cell6!element],
LITERAL6 as [CRITERIA_ITEMS!1!CRITERIA_ITEMS_Literal6!element],
BACKLINK as [CRITERIA_ITEMS!1!CRITERIA_ITEMS_Backlink!element]
FROM CRITERIA_ITEMS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Criteria_items>'
end

if @nErrorCode = 0
begin
	select '<Criteriachanges>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
WHENREQUESTED as [CRITERIACHANGES!1!CRITERIACHANGES_Whenrequested!element],
SQLUSER as [CRITERIACHANGES!1!CRITERIACHANGES_Sqluser!element],
CRITERIANO as [CRITERIACHANGES!1!CRITERIACHANGES_Criteriano!element],
EVENTNO as [CRITERIACHANGES!1!CRITERIACHANGES_Eventno!element],
OLDCRITERIANO as [CRITERIACHANGES!1!CRITERIACHANGES_Oldcriteriano!element],
NEWCRITERIANO as [CRITERIACHANGES!1!CRITERIACHANGES_Newcriteriano!element],
PROCESSED as [CRITERIACHANGES!1!CRITERIACHANGES_Processed!element],
WHENOCCURRED as [CRITERIACHANGES!1!CRITERIACHANGES_Whenoccurred!element],
IDENTITYID as [CRITERIACHANGES!1!CRITERIACHANGES_Identityid!element]
FROM CRITERIACHANGES
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Criteriachanges>'
end

if @nErrorCode = 0
begin
	select '<Culture>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CULTURE as [CULTURE!1!CULTURE_Culture!element],
DESCRIPTION as [CULTURE!1!CULTURE_Description!element],
ISTRANSLATED as [CULTURE!1!CULTURE_Istranslated!element]
FROM CULTURE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Culture>'
end

if @nErrorCode = 0
begin
	select '<Culturecodepage>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CODEPAGE as [CULTURECODEPAGE!1!CULTURECODEPAGE_Codepage!element],
CULTURE as [CULTURECODEPAGE!1!CULTURECODEPAGE_Culture!element]
FROM CULTURECODEPAGE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Culturecodepage>'
end

if @nErrorCode = 0
begin
	select '<Datasource>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
DATASOURCEID as [DATASOURCE!1!DATASOURCE_Datasourceid!element],
SYSTEMID as [DATASOURCE!1!DATASOURCE_Systemid!element],
SOURCENAMENO as [DATASOURCE!1!DATASOURCE_Sourcenameno!element],
ISPROTECTED as [DATASOURCE!1!DATASOURCE_Isprotected!element],
DATASOURCECODE as [DATASOURCE!1!DATASOURCE_Datasourcecode!element]
FROM DATASOURCE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Datasource>'
end

if @nErrorCode = 0
begin
	select '<Datatopic>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
TOPICID as [DATATOPIC!1!DATATOPIC_Topicid!element],
TOPICNAME as [DATATOPIC!1!DATATOPIC_Topicname!element],
DESCRIPTION as [DATATOPIC!1!DATATOPIC_Description!cdata],
ISEXTERNAL as [DATATOPIC!1!DATATOPIC_Isexternal!element],
ISINTERNAL as [DATATOPIC!1!DATATOPIC_Isinternal!element]
FROM DATATOPIC
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Datatopic>'
end

if @nErrorCode = 0
begin
	select '<Datavalidation>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
VALIDATIONID as [DATAVALIDATION!1!DATAVALIDATION_Validationid!element],
INUSEFLAG as [DATAVALIDATION!1!DATAVALIDATION_Inuseflag!element],
DEFERREDFLAG as [DATAVALIDATION!1!DATAVALIDATION_Deferredflag!element],
OFFICEID as [DATAVALIDATION!1!DATAVALIDATION_Officeid!element],
FUNCTIONALAREA as [DATAVALIDATION!1!DATAVALIDATION_Functionalarea!cdata],
CASETYPE as [DATAVALIDATION!1!DATAVALIDATION_Casetype!cdata],
COUNTRYCODE as [DATAVALIDATION!1!DATAVALIDATION_Countrycode!cdata],
PROPERTYTYPE as [DATAVALIDATION!1!DATAVALIDATION_Propertytype!cdata],
CASECATEGORY as [DATAVALIDATION!1!DATAVALIDATION_Casecategory!cdata],
SUBTYPE as [DATAVALIDATION!1!DATAVALIDATION_Subtype!cdata],
BASIS as [DATAVALIDATION!1!DATAVALIDATION_Basis!cdata],
EVENTNO as [DATAVALIDATION!1!DATAVALIDATION_Eventno!element],
EVENTDATEFLAG as [DATAVALIDATION!1!DATAVALIDATION_Eventdateflag!element],
STATUSFLAG as [DATAVALIDATION!1!DATAVALIDATION_Statusflag!element],
FAMILYNO as [DATAVALIDATION!1!DATAVALIDATION_Familyno!element],
LOCALCLIENTFLAG as [DATAVALIDATION!1!DATAVALIDATION_Localclientflag!element],
USEDASFLAG as [DATAVALIDATION!1!DATAVALIDATION_Usedasflag!element],
SUPPLIERFLAG as [DATAVALIDATION!1!DATAVALIDATION_Supplierflag!element],
CATEGORY as [DATAVALIDATION!1!DATAVALIDATION_Category!element],
NAMENO as [DATAVALIDATION!1!DATAVALIDATION_Nameno!element],
NAMETYPE as [DATAVALIDATION!1!DATAVALIDATION_Nametype!cdata],
INSTRUCTIONTYPE as [DATAVALIDATION!1!DATAVALIDATION_Instructiontype!cdata],
FLAGNUMBER as [DATAVALIDATION!1!DATAVALIDATION_Flagnumber!element],
COLUMNNAME as [DATAVALIDATION!1!DATAVALIDATION_Columnname!element],
RULEDESCRIPTION as [DATAVALIDATION!1!DATAVALIDATION_Ruledescription!cdata],
ITEM_ID as [DATAVALIDATION!1!DATAVALIDATION_Item_id!element],
ROLEID as [DATAVALIDATION!1!DATAVALIDATION_Roleid!element],
PROGRAMCONTEXT as [DATAVALIDATION!1!DATAVALIDATION_Programcontext!element],
WARNINGFLAG as [DATAVALIDATION!1!DATAVALIDATION_Warningflag!element],
DISPLAYMESSAGE as [DATAVALIDATION!1!DATAVALIDATION_Displaymessage!cdata],
NOTES as [DATAVALIDATION!1!DATAVALIDATION_Notes!cdata],
NOTCASETYPE as [DATAVALIDATION!1!DATAVALIDATION_Notcasetype!element],
NOTCOUNTRYCODE as [DATAVALIDATION!1!DATAVALIDATION_Notcountrycode!element],
NOTPROPERTYTYPE as [DATAVALIDATION!1!DATAVALIDATION_Notpropertytype!element],
NOTCASECATEGORY as [DATAVALIDATION!1!DATAVALIDATION_Notcasecategory!element],
NOTSUBTYPE as [DATAVALIDATION!1!DATAVALIDATION_Notsubtype!element],
NOTBASIS as [DATAVALIDATION!1!DATAVALIDATION_Notbasis!element]
FROM DATAVALIDATION
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Datavalidation>'
end

if @nErrorCode = 0
begin
	select '<Dataview>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
VIEWID as [DATAVIEW!1!DATAVIEW_Viewid!element],
CATEGORY as [DATAVIEW!1!DATAVIEW_Category!element],
TITLE as [DATAVIEW!1!DATAVIEW_Title!element],
DESCRIPTION as [DATAVIEW!1!DATAVIEW_Description!cdata],
IDENTITYID as [DATAVIEW!1!DATAVIEW_Identityid!element],
STYLE as [DATAVIEW!1!DATAVIEW_Style!element],
SORTID as [DATAVIEW!1!DATAVIEW_Sortid!element],
FILTERID as [DATAVIEW!1!DATAVIEW_Filterid!element],
FORMATID as [DATAVIEW!1!DATAVIEW_Formatid!element]
FROM DATAVIEW
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Dataview>'
end

if @nErrorCode = 0
begin
	select '<Dateslogic>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [DATESLOGIC!1!DATESLOGIC_Criteriano!element],
EVENTNO as [DATESLOGIC!1!DATESLOGIC_Eventno!element],
SEQUENCENO as [DATESLOGIC!1!DATESLOGIC_Sequenceno!element],
DATETYPE as [DATESLOGIC!1!DATESLOGIC_Datetype!element],
OPERATOR as [DATESLOGIC!1!DATESLOGIC_Operator!cdata],
COMPAREEVENT as [DATESLOGIC!1!DATESLOGIC_Compareevent!element],
MUSTEXIST as [DATESLOGIC!1!DATESLOGIC_Mustexist!element],
RELATIVECYCLE as [DATESLOGIC!1!DATESLOGIC_Relativecycle!element],
COMPAREDATETYPE as [DATESLOGIC!1!DATESLOGIC_Comparedatetype!element],
CASERELATIONSHIP as [DATESLOGIC!1!DATESLOGIC_Caserelationship!cdata],
DISPLAYERRORFLAG as [DATESLOGIC!1!DATESLOGIC_Displayerrorflag!element],
ERRORMESSAGE as [DATESLOGIC!1!DATESLOGIC_Errormessage!cdata],
INHERITED as [DATESLOGIC!1!DATESLOGIC_Inherited!element]
FROM DATESLOGIC
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Dateslogic>'
end

if @nErrorCode = 0
begin
	select '<Debtor_item_type>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
ITEM_TYPE_ID as [DEBTOR_ITEM_TYPE!1!DEBTOR_ITEM_TYPE_Item_type_id!element],
ABBREVIATION as [DEBTOR_ITEM_TYPE!1!DEBTOR_ITEM_TYPE_Abbreviation!cdata],
DESCRIPTION as [DEBTOR_ITEM_TYPE!1!DEBTOR_ITEM_TYPE_Description!element],
USEDBYBILLING as [DEBTOR_ITEM_TYPE!1!DEBTOR_ITEM_TYPE_Usedbybilling!element],
INTERNAL as [DEBTOR_ITEM_TYPE!1!DEBTOR_ITEM_TYPE_Internal!element],
TAKEUPONBILL as [DEBTOR_ITEM_TYPE!1!DEBTOR_ITEM_TYPE_Takeuponbill!element],
CASHITEMFLAG as [DEBTOR_ITEM_TYPE!1!DEBTOR_ITEM_TYPE_Cashitemflag!element],
EVENTNO as [DEBTOR_ITEM_TYPE!1!DEBTOR_ITEM_TYPE_Eventno!element]
FROM DEBTOR_ITEM_TYPE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Debtor_item_type>'
end

if @nErrorCode = 0
begin
	select '<Debtorstatus>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
BADDEBTOR as [DEBTORSTATUS!1!DEBTORSTATUS_Baddebtor!element],
DEBTORSTATUS as [DEBTORSTATUS!1!DEBTORSTATUS_Debtorstatus!element],
ACTIONFLAG as [DEBTORSTATUS!1!DEBTORSTATUS_Actionflag!element],
CLEARPASSWORD as [DEBTORSTATUS!1!DEBTORSTATUS_Clearpassword!element]
FROM DEBTORSTATUS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Debtorstatus>'
end

if @nErrorCode = 0
begin
	select '<Deliverymethod>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
DELIVERYID as [DELIVERYMETHOD!1!DELIVERYMETHOD_Deliveryid!element],
DELIVERYTYPE as [DELIVERYMETHOD!1!DELIVERYMETHOD_Deliverytype!element],
DESCRIPTION as [DELIVERYMETHOD!1!DELIVERYMETHOD_Description!cdata],
MACRO as [DELIVERYMETHOD!1!DELIVERYMETHOD_Macro!cdata],
FILEDESTINATION as [DELIVERYMETHOD!1!DELIVERYMETHOD_Filedestination!cdata],
RESOURCENO as [DELIVERYMETHOD!1!DELIVERYMETHOD_Resourceno!element],
DESTINATIONSP as [DELIVERYMETHOD!1!DELIVERYMETHOD_Destinationsp!element],
DIGITALCERTIFICATE as [DELIVERYMETHOD!1!DELIVERYMETHOD_Digitalcertificate!cdata],
EMAILSP as [DELIVERYMETHOD!1!DELIVERYMETHOD_Emailsp!element],
NAMETYPE as [DELIVERYMETHOD!1!DELIVERYMETHOD_Nametype!cdata]
FROM DELIVERYMETHOD
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Deliverymethod>'
end

if @nErrorCode = 0
begin
	select '<Detailcontrol>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [DETAILCONTROL!1!DETAILCONTROL_Criteriano!element],
ENTRYNUMBER as [DETAILCONTROL!1!DETAILCONTROL_Entrynumber!element],
ENTRYDESC as [DETAILCONTROL!1!DETAILCONTROL_Entrydesc!element],
TAKEOVERFLAG as [DETAILCONTROL!1!DETAILCONTROL_Takeoverflag!element],
DISPLAYSEQUENCE as [DETAILCONTROL!1!DETAILCONTROL_Displaysequence!element],
STATUSCODE as [DETAILCONTROL!1!DETAILCONTROL_Statuscode!element],
RENEWALSTATUS as [DETAILCONTROL!1!DETAILCONTROL_Renewalstatus!element],
FILELOCATION as [DETAILCONTROL!1!DETAILCONTROL_Filelocation!element],
NUMBERTYPE as [DETAILCONTROL!1!DETAILCONTROL_Numbertype!cdata],
ATLEAST1FLAG as [DETAILCONTROL!1!DETAILCONTROL_Atleast1flag!element],
USERINSTRUCTION as [DETAILCONTROL!1!DETAILCONTROL_Userinstruction!cdata],
INHERITED as [DETAILCONTROL!1!DETAILCONTROL_Inherited!element],
ENTRYCODE as [DETAILCONTROL!1!DETAILCONTROL_Entrycode!element],
CHARGEGENERATION as [DETAILCONTROL!1!DETAILCONTROL_Chargegeneration!element],
DISPLAYEVENTNO as [DETAILCONTROL!1!DETAILCONTROL_Displayeventno!element],
HIDEEVENTNO as [DETAILCONTROL!1!DETAILCONTROL_Hideeventno!element],
DIMEVENTNO as [DETAILCONTROL!1!DETAILCONTROL_Dimeventno!element],
SHOWTABS as [DETAILCONTROL!1!DETAILCONTROL_Showtabs!element],
SHOWMENUS as [DETAILCONTROL!1!DETAILCONTROL_Showmenus!element],
SHOWTOOLBAR as [DETAILCONTROL!1!DETAILCONTROL_Showtoolbar!element],
PARENTCRITERIANO as [DETAILCONTROL!1!DETAILCONTROL_Parentcriteriano!element],
PARENTENTRYNUMBER as [DETAILCONTROL!1!DETAILCONTROL_Parententrynumber!element],
POLICINGIMMEDIATE as [DETAILCONTROL!1!DETAILCONTROL_Policingimmediate!element],
ISSEPARATOR as [DETAILCONTROL!1!DETAILCONTROL_Isseparator!element]
FROM DETAILCONTROL
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Detailcontrol>'
end

if @nErrorCode = 0
begin
	select '<Detaildates>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [DETAILDATES!1!DETAILDATES_Criteriano!element],
ENTRYNUMBER as [DETAILDATES!1!DETAILDATES_Entrynumber!element],
EVENTNO as [DETAILDATES!1!DETAILDATES_Eventno!element],
OTHEREVENTNO as [DETAILDATES!1!DETAILDATES_Othereventno!element],
DEFAULTFLAG as [DETAILDATES!1!DETAILDATES_Defaultflag!element],
EVENTATTRIBUTE as [DETAILDATES!1!DETAILDATES_Eventattribute!element],
DUEATTRIBUTE as [DETAILDATES!1!DETAILDATES_Dueattribute!element],
POLICINGATTRIBUTE as [DETAILDATES!1!DETAILDATES_Policingattribute!element],
PERIODATTRIBUTE as [DETAILDATES!1!DETAILDATES_Periodattribute!element],
OVREVENTATTRIBUTE as [DETAILDATES!1!DETAILDATES_Ovreventattribute!element],
OVRDUEATTRIBUTE as [DETAILDATES!1!DETAILDATES_Ovrdueattribute!element],
JOURNALATTRIBUTE as [DETAILDATES!1!DETAILDATES_Journalattribute!element],
DISPLAYSEQUENCE as [DETAILDATES!1!DETAILDATES_Displaysequence!element],
INHERITED as [DETAILDATES!1!DETAILDATES_Inherited!element],
DUEDATERESPATTRIBUTE as [DETAILDATES!1!DETAILDATES_Duedaterespattribute!element]
FROM DETAILDATES
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Detaildates>'
end

if @nErrorCode = 0
begin
	select '<Detailletters>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [DETAILLETTERS!1!DETAILLETTERS_Criteriano!element],
ENTRYNUMBER as [DETAILLETTERS!1!DETAILLETTERS_Entrynumber!element],
LETTERNO as [DETAILLETTERS!1!DETAILLETTERS_Letterno!element],
MANDATORYFLAG as [DETAILLETTERS!1!DETAILLETTERS_Mandatoryflag!element],
DELIVERYMETHODFLAG as [DETAILLETTERS!1!DETAILLETTERS_Deliverymethodflag!element],
INHERITED as [DETAILLETTERS!1!DETAILLETTERS_Inherited!element]
FROM DETAILLETTERS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Detailletters>'
end

if @nErrorCode = 0
begin
	select '<Document>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
DOCUMENTNO as [DOCUMENT!1!DOCUMENT_Documentno!element],
DOCDESCRIPTION as [DOCUMENT!1!DOCUMENT_Docdescription!element]
FROM DOCUMENT
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Document>'
end

if @nErrorCode = 0
begin
	select '<Documentdefinition>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
DOCUMENTDEFID as [DOCUMENTDEFINITION!1!DOCUMENTDEFINITION_Documentdefid!element],
LETTERNO as [DOCUMENTDEFINITION!1!DOCUMENTDEFINITION_Letterno!element],
NAME as [DOCUMENTDEFINITION!1!DOCUMENTDEFINITION_Name!element],
DESCRIPTION as [DOCUMENTDEFINITION!1!DOCUMENTDEFINITION_Description!cdata],
CANFILTERCASES as [DOCUMENTDEFINITION!1!DOCUMENTDEFINITION_Canfiltercases!element],
CANFILTEREVENTS as [DOCUMENTDEFINITION!1!DOCUMENTDEFINITION_Canfilterevents!element],
SENDERREQUESTTYPE as [DOCUMENTDEFINITION!1!DOCUMENTDEFINITION_Senderrequesttype!element]
FROM DOCUMENTDEFINITION
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Documentdefinition>'
end

if @nErrorCode = 0
begin
	select '<Documentdefinitionactingas>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
DOCUMENTDEFID as [DOCUMENTDEFINITIONACTINGAS!1!DOCUMENTDEFINITIONACTINGAS_Documentdefid!element],
NAMETYPE as [DOCUMENTDEFINITIONACTINGAS!1!DOCUMENTDEFINITIONACTINGAS_Nametype!cdata]
FROM DOCUMENTDEFINITIONACTINGAS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Documentdefinitionactingas>'
end

if @nErrorCode = 0
begin
	select '<Duedatecalc>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [DUEDATECALC!1!DUEDATECALC_Criteriano!element],
EVENTNO as [DUEDATECALC!1!DUEDATECALC_Eventno!element],
SEQUENCE as [DUEDATECALC!1!DUEDATECALC_Sequence!element],
CYCLENUMBER as [DUEDATECALC!1!DUEDATECALC_Cyclenumber!element],
COUNTRYCODE as [DUEDATECALC!1!DUEDATECALC_Countrycode!cdata],
FROMEVENT as [DUEDATECALC!1!DUEDATECALC_Fromevent!element],
RELATIVECYCLE as [DUEDATECALC!1!DUEDATECALC_Relativecycle!element],
OPERATOR as [DUEDATECALC!1!DUEDATECALC_Operator!cdata],
DEADLINEPERIOD as [DUEDATECALC!1!DUEDATECALC_Deadlineperiod!element],
PERIODTYPE as [DUEDATECALC!1!DUEDATECALC_Periodtype!cdata],
EVENTDATEFLAG as [DUEDATECALC!1!DUEDATECALC_Eventdateflag!element],
ADJUSTMENT as [DUEDATECALC!1!DUEDATECALC_Adjustment!element],
MUSTEXIST as [DUEDATECALC!1!DUEDATECALC_Mustexist!element],
COMPARISON as [DUEDATECALC!1!DUEDATECALC_Comparison!cdata],
COMPAREEVENT as [DUEDATECALC!1!DUEDATECALC_Compareevent!element],
WORKDAY as [DUEDATECALC!1!DUEDATECALC_Workday!element],
MESSAGE2FLAG as [DUEDATECALC!1!DUEDATECALC_Message2flag!element],
SUPPRESSREMINDERS as [DUEDATECALC!1!DUEDATECALC_Suppressreminders!element],
OVERRIDELETTER as [DUEDATECALC!1!DUEDATECALC_Overrideletter!element],
INHERITED as [DUEDATECALC!1!DUEDATECALC_Inherited!element],
COMPAREEVENTFLAG as [DUEDATECALC!1!DUEDATECALC_Compareeventflag!element],
COMPARECYCLE as [DUEDATECALC!1!DUEDATECALC_Comparecycle!element],
COMPARERELATIONSHIP as [DUEDATECALC!1!DUEDATECALC_Comparerelationship!cdata],
COMPAREDATE as [DUEDATECALC!1!DUEDATECALC_Comparedate!element],
COMPARESYSTEMDATE as [DUEDATECALC!1!DUEDATECALC_Comparesystemdate!element]
FROM DUEDATECALC
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Duedatecalc>'
end

if @nErrorCode = 0
begin
	select '<Ederequesttype>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
REQUESTTYPECODE as [EDEREQUESTTYPE!1!EDEREQUESTTYPE_Requesttypecode!element],
REQUESTTYPENAME as [EDEREQUESTTYPE!1!EDEREQUESTTYPE_Requesttypename!cdata],
REQUESTORNAMETYPE as [EDEREQUESTTYPE!1!EDEREQUESTTYPE_Requestornametype!cdata],
TRANSACTIONREASONNO as [EDEREQUESTTYPE!1!EDEREQUESTTYPE_Transactionreasonno!element],
UPDATEEVENTNO as [EDEREQUESTTYPE!1!EDEREQUESTTYPE_Updateeventno!element],
POLICINGNOTREQUIRED as [EDEREQUESTTYPE!1!EDEREQUESTTYPE_Policingnotrequired!element],
OUTPUTNOTREQUIRED as [EDEREQUESTTYPE!1!EDEREQUESTTYPE_Outputnotrequired!element]
FROM EDEREQUESTTYPE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Ederequesttype>'
end

if @nErrorCode = 0
begin
	select '<Ederulecase>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [EDERULECASE!1!EDERULECASE_Criteriano!element],
WHOLECASE as [EDERULECASE!1!EDERULECASE_Wholecase!element],
CASETYPE as [EDERULECASE!1!EDERULECASE_Casetype!element],
PROPERTYTYPE as [EDERULECASE!1!EDERULECASE_Propertytype!element],
COUNTRY as [EDERULECASE!1!EDERULECASE_Country!element],
CATEGORY as [EDERULECASE!1!EDERULECASE_Category!element],
SUBTYPE as [EDERULECASE!1!EDERULECASE_Subtype!element],
BASIS as [EDERULECASE!1!EDERULECASE_Basis!element],
ENTITYSIZE as [EDERULECASE!1!EDERULECASE_Entitysize!element],
NUMBEROFCLAIMS as [EDERULECASE!1!EDERULECASE_Numberofclaims!element],
NUMBEROFDESIGNS as [EDERULECASE!1!EDERULECASE_Numberofdesigns!element],
NUMBEROFYEARSEXT as [EDERULECASE!1!EDERULECASE_Numberofyearsext!element],
STOPPAYREASON as [EDERULECASE!1!EDERULECASE_Stoppayreason!element],
SHORTTITLE as [EDERULECASE!1!EDERULECASE_Shorttitle!element],
CLASSES as [EDERULECASE!1!EDERULECASE_Classes!element],
DESIGNATEDCOUNTRIES as [EDERULECASE!1!EDERULECASE_Designatedcountries!element],
TYPEOFMARK as [EDERULECASE!1!EDERULECASE_Typeofmark!element]
FROM EDERULECASE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Ederulecase>'
end

if @nErrorCode = 0
begin
	select '<Ederulecaseevent>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [EDERULECASEEVENT!1!EDERULECASEEVENT_Criteriano!element],
EVENTNO as [EDERULECASEEVENT!1!EDERULECASEEVENT_Eventno!element],
EVENTDATE as [EDERULECASEEVENT!1!EDERULECASEEVENT_Eventdate!element],
EVENTDUEDATE as [EDERULECASEEVENT!1!EDERULECASEEVENT_Eventduedate!element],
EVENTTEXT as [EDERULECASEEVENT!1!EDERULECASEEVENT_Eventtext!element]
FROM EDERULECASEEVENT
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Ederulecaseevent>'
end

if @nErrorCode = 0
begin
	select '<Ederulecasename>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [EDERULECASENAME!1!EDERULECASENAME_Criteriano!element],
NAMETYPE as [EDERULECASENAME!1!EDERULECASENAME_Nametype!cdata],
NAMENO as [EDERULECASENAME!1!EDERULECASENAME_Nameno!element],
REFERENCENO as [EDERULECASENAME!1!EDERULECASENAME_Referenceno!element],
CORRESPONDNAME as [EDERULECASENAME!1!EDERULECASENAME_Correspondname!element]
FROM EDERULECASENAME
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Ederulecasename>'
end

if @nErrorCode = 0
begin
	select '<Ederulecasetext>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [EDERULECASETEXT!1!EDERULECASETEXT_Criteriano!element],
TEXTTYPE as [EDERULECASETEXT!1!EDERULECASETEXT_Texttype!cdata],
TEXT as [EDERULECASETEXT!1!EDERULECASETEXT_Text!element]
FROM EDERULECASETEXT
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Ederulecasetext>'
end

if @nErrorCode = 0
begin
	select '<Ederuleofficialnumber>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [EDERULEOFFICIALNUMBER!1!EDERULEOFFICIALNUMBER_Criteriano!element],
NUMBERTYPE as [EDERULEOFFICIALNUMBER!1!EDERULEOFFICIALNUMBER_Numbertype!cdata],
OFFICIALNUMBER as [EDERULEOFFICIALNUMBER!1!EDERULEOFFICIALNUMBER_Officialnumber!element]
FROM EDERULEOFFICIALNUMBER
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Ederuleofficialnumber>'
end

if @nErrorCode = 0
begin
	select '<Ederulerelatedcase>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [EDERULERELATEDCASE!1!EDERULERELATEDCASE_Criteriano!element],
RELATIONSHIP as [EDERULERELATEDCASE!1!EDERULERELATEDCASE_Relationship!cdata],
OFFICIALNUMBER as [EDERULERELATEDCASE!1!EDERULERELATEDCASE_Officialnumber!element],
PRIORITYDATE as [EDERULERELATEDCASE!1!EDERULERELATEDCASE_Prioritydate!element]
FROM EDERULERELATEDCASE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Ederulerelatedcase>'
end

if @nErrorCode = 0
begin
	select '<Element>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
ELEMENTNO as [ELEMENT!1!ELEMENT_Elementno!element],
ELEMENT as [ELEMENT!1!ELEMENT_Element!element],
ELEMENTCODE as [ELEMENT!1!ELEMENT_Elementcode!element],
EDITATTRIBUTE as [ELEMENT!1!ELEMENT_Editattribute!cdata]
FROM ELEMENT
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Element>'
end

if @nErrorCode = 0
begin
	select '<Elementcontrol>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
ELEMENTCONTROLNO as [ELEMENTCONTROL!1!ELEMENTCONTROL_Elementcontrolno!element],
TOPICCONTROLNO as [ELEMENTCONTROL!1!ELEMENTCONTROL_Topiccontrolno!element],
ELEMENTNAME as [ELEMENTCONTROL!1!ELEMENTCONTROL_Elementname!element],
SHORTLABEL as [ELEMENTCONTROL!1!ELEMENTCONTROL_Shortlabel!cdata],
FULLLABEL as [ELEMENTCONTROL!1!ELEMENTCONTROL_Fulllabel!cdata],
BUTTON as [ELEMENTCONTROL!1!ELEMENTCONTROL_Button!cdata],
TOOLTIP as [ELEMENTCONTROL!1!ELEMENTCONTROL_Tooltip!cdata],
LINK as [ELEMENTCONTROL!1!ELEMENTCONTROL_Link!cdata],
LITERAL as [ELEMENTCONTROL!1!ELEMENTCONTROL_Literal!cdata],
DEFAULTVALUE as [ELEMENTCONTROL!1!ELEMENTCONTROL_Defaultvalue!cdata],
ISHIDDEN as [ELEMENTCONTROL!1!ELEMENTCONTROL_Ishidden!element],
ISMANDATORY as [ELEMENTCONTROL!1!ELEMENTCONTROL_Ismandatory!element],
ISREADONLY as [ELEMENTCONTROL!1!ELEMENTCONTROL_Isreadonly!element],
ISINHERITED as [ELEMENTCONTROL!1!ELEMENTCONTROL_Isinherited!element],
FILTERNAME as [ELEMENTCONTROL!1!ELEMENTCONTROL_Filtername!element],
FILTERVALUE as [ELEMENTCONTROL!1!ELEMENTCONTROL_Filtervalue!cdata]
FROM ELEMENTCONTROL
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Elementcontrol>'
end

if @nErrorCode = 0
begin
	select '<Encodedvalue>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CODEID as [ENCODEDVALUE!1!ENCODEDVALUE_Codeid!element],
SCHEMEID as [ENCODEDVALUE!1!ENCODEDVALUE_Schemeid!element],
STRUCTUREID as [ENCODEDVALUE!1!ENCODEDVALUE_Structureid!element],
CODE as [ENCODEDVALUE!1!ENCODEDVALUE_Code!element],
DESCRIPTION as [ENCODEDVALUE!1!ENCODEDVALUE_Description!cdata],
OUTBOUNDVALUE as [ENCODEDVALUE!1!ENCODEDVALUE_Outboundvalue!element]
FROM ENCODEDVALUE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Encodedvalue>'
end

if @nErrorCode = 0
begin
	select '<Encodingscheme>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
SCHEMEID as [ENCODINGSCHEME!1!ENCODINGSCHEME_Schemeid!element],
SCHEMECODE as [ENCODINGSCHEME!1!ENCODINGSCHEME_Schemecode!element],
SCHEMENAME as [ENCODINGSCHEME!1!ENCODINGSCHEME_Schemename!element],
SCHEMEDESCRIPTION as [ENCODINGSCHEME!1!ENCODINGSCHEME_Schemedescription!cdata],
ISPROTECTED as [ENCODINGSCHEME!1!ENCODINGSCHEME_Isprotected!element]
FROM ENCODINGSCHEME
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Encodingscheme>'
end

if @nErrorCode = 0
begin
	select '<Encodingstructure>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
SCHEMEID as [ENCODINGSTRUCTURE!1!ENCODINGSTRUCTURE_Schemeid!element],
STRUCTUREID as [ENCODINGSTRUCTURE!1!ENCODINGSTRUCTURE_Structureid!element],
NAME as [ENCODINGSTRUCTURE!1!ENCODINGSTRUCTURE_Name!element],
DESCRIPTION as [ENCODINGSTRUCTURE!1!ENCODINGSTRUCTURE_Description!cdata]
FROM ENCODINGSTRUCTURE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Encodingstructure>'
end

if @nErrorCode = 0
begin
	select '<Eventcategory>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CATEGORYID as [EVENTCATEGORY!1!EVENTCATEGORY_Categoryid!element],
CATEGORYNAME as [EVENTCATEGORY!1!EVENTCATEGORY_Categoryname!element],
DESCRIPTION as [EVENTCATEGORY!1!EVENTCATEGORY_Description!cdata],
ICONIMAGEID as [EVENTCATEGORY!1!EVENTCATEGORY_Iconimageid!element]
FROM EVENTCATEGORY
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Eventcategory>'
end

if @nErrorCode = 0
begin
	select '<Eventcontrol>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [EVENTCONTROL!1!EVENTCONTROL_Criteriano!element],
EVENTNO as [EVENTCONTROL!1!EVENTCONTROL_Eventno!element],
EVENTDESCRIPTION as [EVENTCONTROL!1!EVENTCONTROL_Eventdescription!element],
DISPLAYSEQUENCE as [EVENTCONTROL!1!EVENTCONTROL_Displaysequence!element],
PARENTCRITERIANO as [EVENTCONTROL!1!EVENTCONTROL_Parentcriteriano!element],
PARENTEVENTNO as [EVENTCONTROL!1!EVENTCONTROL_Parenteventno!element],
NUMCYCLESALLOWED as [EVENTCONTROL!1!EVENTCONTROL_Numcyclesallowed!element],
IMPORTANCELEVEL as [EVENTCONTROL!1!EVENTCONTROL_Importancelevel!cdata],
WHICHDUEDATE as [EVENTCONTROL!1!EVENTCONTROL_Whichduedate!cdata],
COMPAREBOOLEAN as [EVENTCONTROL!1!EVENTCONTROL_Compareboolean!element],
CHECKCOUNTRYFLAG as [EVENTCONTROL!1!EVENTCONTROL_Checkcountryflag!element],
SAVEDUEDATE as [EVENTCONTROL!1!EVENTCONTROL_Saveduedate!element],
STATUSCODE as [EVENTCONTROL!1!EVENTCONTROL_Statuscode!element],
SPECIALFUNCTION as [EVENTCONTROL!1!EVENTCONTROL_Specialfunction!cdata],
INITIALFEE as [EVENTCONTROL!1!EVENTCONTROL_Initialfee!element],
PAYFEECODE as [EVENTCONTROL!1!EVENTCONTROL_Payfeecode!cdata],
CREATEACTION as [EVENTCONTROL!1!EVENTCONTROL_Createaction!cdata],
STATUSDESC as [EVENTCONTROL!1!EVENTCONTROL_Statusdesc!element],
CLOSEACTION as [EVENTCONTROL!1!EVENTCONTROL_Closeaction!cdata],
UPDATEFROMEVENT as [EVENTCONTROL!1!EVENTCONTROL_Updatefromevent!element],
FROMRELATIONSHIP as [EVENTCONTROL!1!EVENTCONTROL_Fromrelationship!cdata],
FROMANCESTOR as [EVENTCONTROL!1!EVENTCONTROL_Fromancestor!element],
UPDATEMANUALLY as [EVENTCONTROL!1!EVENTCONTROL_Updatemanually!element],
ADJUSTMENT as [EVENTCONTROL!1!EVENTCONTROL_Adjustment!element],
DOCUMENTNO as [EVENTCONTROL!1!EVENTCONTROL_Documentno!element],
NOOFDOCS as [EVENTCONTROL!1!EVENTCONTROL_Noofdocs!element],
MANDATORYDOCS as [EVENTCONTROL!1!EVENTCONTROL_Mandatorydocs!element],
NOTES as [EVENTCONTROL!1!EVENTCONTROL_Notes!cdata],
INHERITED as [EVENTCONTROL!1!EVENTCONTROL_Inherited!element],
INSTRUCTIONTYPE as [EVENTCONTROL!1!EVENTCONTROL_Instructiontype!cdata],
FLAGNUMBER as [EVENTCONTROL!1!EVENTCONTROL_Flagnumber!element],
SETTHIRDPARTYON as [EVENTCONTROL!1!EVENTCONTROL_Setthirdpartyon!element],
RELATIVECYCLE as [EVENTCONTROL!1!EVENTCONTROL_Relativecycle!element],
CREATECYCLE as [EVENTCONTROL!1!EVENTCONTROL_Createcycle!element],
ESTIMATEFLAG as [EVENTCONTROL!1!EVENTCONTROL_Estimateflag!element],
EXTENDPERIOD as [EVENTCONTROL!1!EVENTCONTROL_Extendperiod!element],
EXTENDPERIODTYPE as [EVENTCONTROL!1!EVENTCONTROL_Extendperiodtype!cdata],
INITIALFEE2 as [EVENTCONTROL!1!EVENTCONTROL_Initialfee2!element],
PAYFEECODE2 as [EVENTCONTROL!1!EVENTCONTROL_Payfeecode2!cdata],
ESTIMATEFLAG2 as [EVENTCONTROL!1!EVENTCONTROL_Estimateflag2!element],
PTADELAY as [EVENTCONTROL!1!EVENTCONTROL_Ptadelay!element],
SETTHIRDPARTYOFF as [EVENTCONTROL!1!EVENTCONTROL_Setthirdpartyoff!element],
RECEIVINGCYCLEFLAG as [EVENTCONTROL!1!EVENTCONTROL_Receivingcycleflag!element],
RECALCEVENTDATE as [EVENTCONTROL!1!EVENTCONTROL_Recalceventdate!element],
CHANGENAMETYPE as [EVENTCONTROL!1!EVENTCONTROL_Changenametype!cdata],
COPYFROMNAMETYPE as [EVENTCONTROL!1!EVENTCONTROL_Copyfromnametype!cdata],
COPYTONAMETYPE as [EVENTCONTROL!1!EVENTCONTROL_Copytonametype!cdata],
DELCOPYFROMNAME as [EVENTCONTROL!1!EVENTCONTROL_Delcopyfromname!element],
CASETYPE as [EVENTCONTROL!1!EVENTCONTROL_Casetype!cdata],
COUNTRYCODE as [EVENTCONTROL!1!EVENTCONTROL_Countrycode!cdata],
COUNTRYCODEISTHISCASE as [EVENTCONTROL!1!EVENTCONTROL_Countrycodeisthiscase!element],
PROPERTYTYPE as [EVENTCONTROL!1!EVENTCONTROL_Propertytype!cdata],
PROPERTYTYPEISTHISCASE as [EVENTCONTROL!1!EVENTCONTROL_Propertytypeisthiscase!element],
CASECATEGORY as [EVENTCONTROL!1!EVENTCONTROL_Casecategory!cdata],
CATEGORYISTHISCASE as [EVENTCONTROL!1!EVENTCONTROL_Categoryisthiscase!element],
SUBTYPE as [EVENTCONTROL!1!EVENTCONTROL_Subtype!cdata],
SUBTYPEISTHISCASE as [EVENTCONTROL!1!EVENTCONTROL_Subtypeisthiscase!element],
BASIS as [EVENTCONTROL!1!EVENTCONTROL_Basis!cdata],
BASISISTHISCASE as [EVENTCONTROL!1!EVENTCONTROL_Basisisthiscase!element],
DIRECTPAYFLAG as [EVENTCONTROL!1!EVENTCONTROL_Directpayflag!element],
DIRECTPAYFLAG2 as [EVENTCONTROL!1!EVENTCONTROL_Directpayflag2!element],
OFFICEID as [EVENTCONTROL!1!EVENTCONTROL_Officeid!element],
OFFICEIDISTHISCASE as [EVENTCONTROL!1!EVENTCONTROL_Officeidisthiscase!element],
DUEDATERESPNAMETYPE as [EVENTCONTROL!1!EVENTCONTROL_Duedaterespnametype!cdata],
DUEDATERESPNAMENO as [EVENTCONTROL!1!EVENTCONTROL_Duedaterespnameno!element],
LOADNUMBERTYPE as [EVENTCONTROL!1!EVENTCONTROL_Loadnumbertype!cdata],
SUPPRESSCALCULATION as [EVENTCONTROL!1!EVENTCONTROL_Suppresscalculation!element],
RENEWALSTATUS as [EVENTCONTROL!1!EVENTCONTROL_Renewalstatus!element]
FROM EVENTCONTROL
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Eventcontrol>'
end

if @nErrorCode = 0
begin
	select '<Eventcontrolnamemap>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [EVENTCONTROLNAMEMAP!1!EVENTCONTROLNAMEMAP_Criteriano!element],
EVENTNO as [EVENTCONTROLNAMEMAP!1!EVENTCONTROLNAMEMAP_Eventno!element],
SEQUENCENO as [EVENTCONTROLNAMEMAP!1!EVENTCONTROLNAMEMAP_Sequenceno!element],
APPLICABLENAMETYPE as [EVENTCONTROLNAMEMAP!1!EVENTCONTROLNAMEMAP_Applicablenametype!cdata],
SUBSTITUTENAMETYPE as [EVENTCONTROLNAMEMAP!1!EVENTCONTROLNAMEMAP_Substitutenametype!cdata],
MUSTEXIST as [EVENTCONTROLNAMEMAP!1!EVENTCONTROLNAMEMAP_Mustexist!element],
INHERITED as [EVENTCONTROLNAMEMAP!1!EVENTCONTROLNAMEMAP_Inherited!element]
FROM EVENTCONTROLNAMEMAP
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Eventcontrolnamemap>'
end

if @nErrorCode = 0
begin
	select '<Eventcontrolreqevent>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [EVENTCONTROLREQEVENT!1!EVENTCONTROLREQEVENT_Criteriano!element],
EVENTNO as [EVENTCONTROLREQEVENT!1!EVENTCONTROLREQEVENT_Eventno!element],
REQEVENTNO as [EVENTCONTROLREQEVENT!1!EVENTCONTROLREQEVENT_Reqeventno!element],
INHERITED as [EVENTCONTROLREQEVENT!1!EVENTCONTROLREQEVENT_Inherited!element]
FROM EVENTCONTROLREQEVENT
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Eventcontrolreqevent>'
end

if @nErrorCode = 0
begin
	select '<Events>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
EVENTNO as [EVENTS!1!EVENTS_Eventno!element],
EVENTCODE as [EVENTS!1!EVENTS_Eventcode!element],
EVENTDESCRIPTION as [EVENTS!1!EVENTS_Eventdescription!element],
NUMCYCLESALLOWED as [EVENTS!1!EVENTS_Numcyclesallowed!element],
IMPORTANCELEVEL as [EVENTS!1!EVENTS_Importancelevel!cdata],
CONTROLLINGACTION as [EVENTS!1!EVENTS_Controllingaction!cdata],
DEFINITION as [EVENTS!1!EVENTS_Definition!cdata],
CLIENTIMPLEVEL as [EVENTS!1!EVENTS_Clientimplevel!cdata],
CATEGORYID as [EVENTS!1!EVENTS_Categoryid!element],
PROFILEREFNO as [EVENTS!1!EVENTS_Profilerefno!element],
RECALCEVENTDATE as [EVENTS!1!EVENTS_Recalceventdate!element],
DRAFTEVENTNO as [EVENTS!1!EVENTS_Drafteventno!element],
EVENTGROUP as [EVENTS!1!EVENTS_Eventgroup!element],
ACCOUNTINGEVENTFLAG as [EVENTS!1!EVENTS_Accountingeventflag!element],
POLICINGIMMEDIATE as [EVENTS!1!EVENTS_Policingimmediate!element],
SUPPRESSCALCULATION as [EVENTS!1!EVENTS_Suppresscalculation!element],
NOTEGROUP as [EVENTS!1!EVENTS_Notegroup!element],
NOTESSHAREDACROSSCYCLES as [EVENTS!1!EVENTS_Notessharedacrosscycles!element]
FROM EVENTS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Events>'
end

if @nErrorCode = 0
begin
	select '<Eventsreplaced>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
OLDEVENTNO as [EVENTSREPLACED!1!EVENTSREPLACED_Oldeventno!element],
EVENTNO as [EVENTSREPLACED!1!EVENTSREPLACED_Eventno!element]
FROM EVENTSREPLACED
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Eventsreplaced>'
end

if @nErrorCode = 0
begin
	select '<Eventtexttype>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
EVENTTEXTTYPEID as [EVENTTEXTTYPE!1!EVENTTEXTTYPE_Eventtexttypeid!element],
DESCRIPTION     as [EVENTTEXTTYPE!1!EVENTTEXTTYPE_Description!element],
ISEXTERNAL      as [EVENTTEXTTYPE!1!EVENTTEXTTYPE_Isexternal!element],
SHARINGALLOWED  as [EVENTTEXTTYPE!1!EVENTTEXTTYPE_Sharingallowed!element]
FROM EVENTTEXTTYPE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Eventtexttype>'
end

if @nErrorCode = 0
begin
	select '<Eventupdateprofile>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
PROFILEREFNO as [EVENTUPDATEPROFILE!1!EVENTUPDATEPROFILE_Profilerefno!element],
DESCRIPTION as [EVENTUPDATEPROFILE!1!EVENTUPDATEPROFILE_Description!element],
EVENT1NO as [EVENTUPDATEPROFILE!1!EVENTUPDATEPROFILE_Event1no!element],
EVENT1TEXT as [EVENTUPDATEPROFILE!1!EVENTUPDATEPROFILE_Event1text!element],
EVENT2NO as [EVENTUPDATEPROFILE!1!EVENTUPDATEPROFILE_Event2no!element],
EVENT2TEXT as [EVENTUPDATEPROFILE!1!EVENTUPDATEPROFILE_Event2text!element],
NAMETYPE as [EVENTUPDATEPROFILE!1!EVENTUPDATEPROFILE_Nametype!cdata]
FROM EVENTUPDATEPROFILE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Eventupdateprofile>'
end

if @nErrorCode = 0
begin
	select '<Externalsystem>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
SYSTEMID as [EXTERNALSYSTEM!1!EXTERNALSYSTEM_Systemid!element],
SYSTEMNAME as [EXTERNALSYSTEM!1!EXTERNALSYSTEM_Systemname!element],
SYSTEMCODE as [EXTERNALSYSTEM!1!EXTERNALSYSTEM_Systemcode!element],
DATAEXTRACTID as [EXTERNALSYSTEM!1!EXTERNALSYSTEM_Dataextractid!element]
FROM EXTERNALSYSTEM
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Externalsystem>'
end

if @nErrorCode = 0
begin
	select '<Feature>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
FEATUREID as [FEATURE!1!FEATURE_Featureid!element],
FEATURENAME as [FEATURE!1!FEATURE_Featurename!element],
CATEGORYID as [FEATURE!1!FEATURE_Categoryid!element],
ISEXTERNAL as [FEATURE!1!FEATURE_Isexternal!element],
ISINTERNAL as [FEATURE!1!FEATURE_Isinternal!element]
FROM FEATURE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Feature>'
end

if @nErrorCode = 0
begin
	select '<Featuremodule>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
FEATUREID as [FEATUREMODULE!1!FEATUREMODULE_Featureid!element],
MODULEID as [FEATUREMODULE!1!FEATUREMODULE_Moduleid!element]
FROM FEATUREMODULE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Featuremodule>'
end

if @nErrorCode = 0
begin
	select '<Featuretask>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
FEATUREID as [FEATURETASK!1!FEATURETASK_Featureid!element],
TASKID as [FEATURETASK!1!FEATURETASK_Taskid!element]
FROM FEATURETASK
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Featuretask>'
end

if @nErrorCode = 0
begin
	select '<Feescalcalt>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [FEESCALCALT!1!FEESCALCALT_Criteriano!element],
UNIQUEID as [FEESCALCALT!1!FEESCALCALT_Uniqueid!element],
COMPONENTTYPE as [FEESCALCALT!1!FEESCALCALT_Componenttype!element],
SUPPLEMENTNO as [FEESCALCALT!1!FEESCALCALT_Supplementno!element],
PROCEDURENAME as [FEESCALCALT!1!FEESCALCALT_Procedurename!element],
DESCRIPTION as [FEESCALCALT!1!FEESCALCALT_Description!element],
COUNTRYCODE as [FEESCALCALT!1!FEESCALCALT_Countrycode!cdata],
SUPPNUMERICVALUE as [FEESCALCALT!1!FEESCALCALT_Suppnumericvalue!element]
FROM FEESCALCALT
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Feescalcalt>'
end

if @nErrorCode = 0
begin
	select '<Feescalculation>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [FEESCALCULATION!1!FEESCALCULATION_Criteriano!element],
UNIQUEID as [FEESCALCULATION!1!FEESCALCULATION_Uniqueid!element],
AGENT as [FEESCALCULATION!1!FEESCALCULATION_Agent!element],
DEBTORTYPE as [FEESCALCULATION!1!FEESCALCULATION_Debtortype!element],
DEBTOR as [FEESCALCULATION!1!FEESCALCULATION_Debtor!element],
CYCLENUMBER as [FEESCALCULATION!1!FEESCALCULATION_Cyclenumber!element],
VALIDFROMDATE as [FEESCALCULATION!1!FEESCALCULATION_Validfromdate!element],
DEBITNOTE as [FEESCALCULATION!1!FEESCALCULATION_Debitnote!element],
COVERINGLETTER as [FEESCALCULATION!1!FEESCALCULATION_Coveringletter!element],
GENERATECHARGES as [FEESCALCULATION!1!FEESCALCULATION_Generatecharges!element],
FEETYPE as [FEESCALCULATION!1!FEESCALCULATION_Feetype!element],
IPOFFICEFEEFLAG as [FEESCALCULATION!1!FEESCALCULATION_Ipofficefeeflag!element],
DISBCURRENCY as [FEESCALCULATION!1!FEESCALCULATION_Disbcurrency!cdata],
DISBTAXCODE as [FEESCALCULATION!1!FEESCALCULATION_Disbtaxcode!cdata],
DISBNARRATIVE as [FEESCALCULATION!1!FEESCALCULATION_Disbnarrative!element],
DISBWIPCODE as [FEESCALCULATION!1!FEESCALCULATION_Disbwipcode!element],
DISBBASEFEE as [FEESCALCULATION!1!FEESCALCULATION_Disbbasefee!element],
DISBMINFEEFLAG as [FEESCALCULATION!1!FEESCALCULATION_Disbminfeeflag!element],
DISBVARIABLEFEE as [FEESCALCULATION!1!FEESCALCULATION_Disbvariablefee!element],
DISBADDPERCENTAGE as [FEESCALCULATION!1!FEESCALCULATION_Disbaddpercentage!element],
DISBUNITSIZE as [FEESCALCULATION!1!FEESCALCULATION_Disbunitsize!element],
DISBBASEUNITS as [FEESCALCULATION!1!FEESCALCULATION_Disbbaseunits!element],
SERVICECURRENCY as [FEESCALCULATION!1!FEESCALCULATION_Servicecurrency!cdata],
SERVTAXCODE as [FEESCALCULATION!1!FEESCALCULATION_Servtaxcode!cdata],
SERVICENARRATIVE as [FEESCALCULATION!1!FEESCALCULATION_Servicenarrative!element],
SERVWIPCODE as [FEESCALCULATION!1!FEESCALCULATION_Servwipcode!element],
SERVBASEFEE as [FEESCALCULATION!1!FEESCALCULATION_Servbasefee!element],
SERVMINFEEFLAG as [FEESCALCULATION!1!FEESCALCULATION_Servminfeeflag!element],
SERVVARIABLEFEE as [FEESCALCULATION!1!FEESCALCULATION_Servvariablefee!element],
SERVADDPERCENTAGE as [FEESCALCULATION!1!FEESCALCULATION_Servaddpercentage!element],
SERVDISBPERCENTAGE as [FEESCALCULATION!1!FEESCALCULATION_Servdisbpercentage!element],
SERVUNITSIZE as [FEESCALCULATION!1!FEESCALCULATION_Servunitsize!element],
SERVBASEUNITS as [FEESCALCULATION!1!FEESCALCULATION_Servbaseunits!element],
INHERITED as [FEESCALCULATION!1!FEESCALCULATION_Inherited!element],
PARAMETERSOURCE as [FEESCALCULATION!1!FEESCALCULATION_Parametersource!element],
DISBMAXUNITS as [FEESCALCULATION!1!FEESCALCULATION_Disbmaxunits!element],
SERVMAXUNITS as [FEESCALCULATION!1!FEESCALCULATION_Servmaxunits!element],
DISBEMPLOYEENO as [FEESCALCULATION!1!FEESCALCULATION_Disbemployeeno!element],
SERVEMPLOYEENO as [FEESCALCULATION!1!FEESCALCULATION_Servemployeeno!element],
VARBASEFEE as [FEESCALCULATION!1!FEESCALCULATION_Varbasefee!element],
VARBASEUNITS as [FEESCALCULATION!1!FEESCALCULATION_Varbaseunits!element],
VARVARIABLEFEE as [FEESCALCULATION!1!FEESCALCULATION_Varvariablefee!element],
VARUNITSIZE as [FEESCALCULATION!1!FEESCALCULATION_Varunitsize!element],
VARMAXUNITS as [FEESCALCULATION!1!FEESCALCULATION_Varmaxunits!element],
VARMINFEEFLAG as [FEESCALCULATION!1!FEESCALCULATION_Varminfeeflag!element],
WRITEUPREASON as [FEESCALCULATION!1!FEESCALCULATION_Writeupreason!cdata],
VARWIPCODE as [FEESCALCULATION!1!FEESCALCULATION_Varwipcode!element],
VARFEEAPPLIES as [FEESCALCULATION!1!FEESCALCULATION_Varfeeapplies!element],
OWNER as [FEESCALCULATION!1!FEESCALCULATION_Owner!element],
INSTRUCTOR as [FEESCALCULATION!1!FEESCALCULATION_Instructor!element],
PRODUCTCODE as [FEESCALCULATION!1!FEESCALCULATION_Productcode!element],
PARAMETERSOURCE2 as [FEESCALCULATION!1!FEESCALCULATION_Parametersource2!element],
FEETYPE2 as [FEESCALCULATION!1!FEESCALCULATION_Feetype2!element],
FROMEVENTNO as [FEESCALCULATION!1!FEESCALCULATION_Fromeventno!element],
DISBSTAFFNAMETYPE as [FEESCALCULATION!1!FEESCALCULATION_Disbstaffnametype!cdata],
SERVSTAFFNAMETYPE as [FEESCALCULATION!1!FEESCALCULATION_Servstaffnametype!cdata],
DISBDISCFEEFLAG as [FEESCALCULATION!1!FEESCALCULATION_Disbdiscfeeflag!element],
SERVDISCFEEFLAG as [FEESCALCULATION!1!FEESCALCULATION_Servdiscfeeflag!element]
FROM FEESCALCULATION
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Feescalculation>'
end

if @nErrorCode = 0
begin
	select '<Feetypes>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
FEETYPE as [FEETYPES!1!FEETYPES_Feetype!element],
FEENAME as [FEETYPES!1!FEETYPES_Feename!element],
REPORTFORMAT as [FEETYPES!1!FEETYPES_Reportformat!cdata],
RATENO as [FEETYPES!1!FEETYPES_Rateno!element],
WIPCODE as [FEETYPES!1!FEETYPES_Wipcode!element],
ACCOUNTOWNER as [FEETYPES!1!FEETYPES_Accountowner!element],
BANKNAMENO as [FEETYPES!1!FEETYPES_Banknameno!element],
ACCOUNTSEQUENCENO as [FEETYPES!1!FEETYPES_Accountsequenceno!element]
FROM FEETYPES
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Feetypes>'
end

if @nErrorCode = 0
begin
	select '<Fieldcontrol>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [FIELDCONTROL!1!FIELDCONTROL_Criteriano!element],
SCREENNAME as [FIELDCONTROL!1!FIELDCONTROL_Screenname!element],
SCREENID as [FIELDCONTROL!1!FIELDCONTROL_Screenid!element],
FIELDNAME as [FIELDCONTROL!1!FIELDCONTROL_Fieldname!element],
ATTRIBUTES as [FIELDCONTROL!1!FIELDCONTROL_Attributes!element],
FIELDLITERAL as [FIELDCONTROL!1!FIELDCONTROL_Fieldliteral!element],
INHERITED as [FIELDCONTROL!1!FIELDCONTROL_Inherited!element]
FROM FIELDCONTROL
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Fieldcontrol>'
end

if @nErrorCode = 0
begin
	select '<Filelocationoffice>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
FILELOCATIONID as [FILELOCATIONOFFICE!1!FILELOCATIONOFFICE_Filelocationid!element],
OFFICEID as [FILELOCATIONOFFICE!1!FILELOCATIONOFFICE_Officeid!element]
FROM FILELOCATIONOFFICE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Filelocationoffice>'
end

if @nErrorCode = 0
begin
	select '<Formfields>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
DOCUMENTNO as [FORMFIELDS!1!FORMFIELDS_Documentno!element],
FIELDNAME as [FORMFIELDS!1!FORMFIELDS_Fieldname!element],
FIELDTYPE as [FORMFIELDS!1!FORMFIELDS_Fieldtype!element],
ITEM_ID as [FORMFIELDS!1!FORMFIELDS_Item_id!element],
FIELDDESCRIPTION as [FORMFIELDS!1!FORMFIELDS_Fielddescription!element],
ITEMPARAMETER as [FORMFIELDS!1!FORMFIELDS_Itemparameter!element],
RESULTSEPARATOR as [FORMFIELDS!1!FORMFIELDS_Resultseparator!element]
FROM FORMFIELDS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Formfields>'
end

if @nErrorCode = 0
begin
	select '<Frequency>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
FREQUENCYNO as [FREQUENCY!1!FREQUENCY_Frequencyno!element],
DESCRIPTION as [FREQUENCY!1!FREQUENCY_Description!element],
FREQUENCY as [FREQUENCY!1!FREQUENCY_Frequency!element],
PERIODTYPE as [FREQUENCY!1!FREQUENCY_Periodtype!cdata],
FREQUENCYTYPE as [FREQUENCY!1!FREQUENCY_Frequencytype!element]
FROM FREQUENCY
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Frequency>'
end

if @nErrorCode = 0
begin
	select '<Groupmembers>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
NAMEGROUP as [GROUPMEMBERS!1!GROUPMEMBERS_Namegroup!element],
NAMETYPE as [GROUPMEMBERS!1!GROUPMEMBERS_Nametype!cdata]
FROM GROUPMEMBERS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Groupmembers>'
end

if @nErrorCode = 0
begin
	select '<Groups>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
GROUP_CODE as [GROUPS!1!GROUPS_Group_code!element],
GROUP_NAME as [GROUPS!1!GROUPS_Group_name!element]
FROM GROUPS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Groups>'
end

if @nErrorCode = 0
begin
	select '<Holidays>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
COUNTRYCODE as [HOLIDAYS!1!HOLIDAYS_Countrycode!cdata],
HOLIDAYDATE as [HOLIDAYS!1!HOLIDAYS_Holidaydate!element],
HOLIDAYNAME as [HOLIDAYS!1!HOLIDAYS_Holidayname!element]
FROM HOLIDAYS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Holidays>'
end

if @nErrorCode = 0
begin
	select '<Importance>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
IMPORTANCELEVEL as [IMPORTANCE!1!IMPORTANCE_Importancelevel!cdata],
IMPORTANCEDESC as [IMPORTANCE!1!IMPORTANCE_Importancedesc!element]
FROM IMPORTANCE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Importance>'
end

if @nErrorCode = 0
begin
	select '<Inherits>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [INHERITS!1!INHERITS_Criteriano!element],
FROMCRITERIA as [INHERITS!1!INHERITS_Fromcriteria!element]
FROM INHERITS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Inherits>'
end

if @nErrorCode = 0
begin
	select '<Instructionflag>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
INSTRUCTIONCODE as [INSTRUCTIONFLAG!1!INSTRUCTIONFLAG_Instructioncode!element],
FLAGNUMBER as [INSTRUCTIONFLAG!1!INSTRUCTIONFLAG_Flagnumber!element],
INSTRUCTIONFLAG as [INSTRUCTIONFLAG!1!INSTRUCTIONFLAG_Instructionflag!element]
FROM INSTRUCTIONFLAG
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Instructionflag>'
end

if @nErrorCode = 0
begin
	select '<Instructionlabel>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
INSTRUCTIONTYPE as [INSTRUCTIONLABEL!1!INSTRUCTIONLABEL_Instructiontype!cdata],
FLAGNUMBER as [INSTRUCTIONLABEL!1!INSTRUCTIONLABEL_Flagnumber!element],
FLAGLITERAL as [INSTRUCTIONLABEL!1!INSTRUCTIONLABEL_Flagliteral!element]
FROM INSTRUCTIONLABEL
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Instructionlabel>'
end

if @nErrorCode = 0
begin
	select '<Instructions>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
INSTRUCTIONCODE as [INSTRUCTIONS!1!INSTRUCTIONS_Instructioncode!element],
INSTRUCTIONTYPE as [INSTRUCTIONS!1!INSTRUCTIONS_Instructiontype!cdata],
DESCRIPTION as [INSTRUCTIONS!1!INSTRUCTIONS_Description!element]
FROM INSTRUCTIONS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Instructions>'
end

if @nErrorCode = 0
begin
	select '<Instructiontype>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
INSTRUCTIONTYPE as [INSTRUCTIONTYPE!1!INSTRUCTIONTYPE_Instructiontype!cdata],
NAMETYPE as [INSTRUCTIONTYPE!1!INSTRUCTIONTYPE_Nametype!cdata],
INSTRTYPEDESC as [INSTRUCTIONTYPE!1!INSTRUCTIONTYPE_Instrtypedesc!element],
RESTRICTEDBYTYPE as [INSTRUCTIONTYPE!1!INSTRUCTIONTYPE_Restrictedbytype!cdata]
FROM INSTRUCTIONTYPE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Instructiontype>'
end

if @nErrorCode = 0
begin
	select '<Irformat>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [IRFORMAT!1!IRFORMAT_Criteriano!element],
SEGMENT1 as [IRFORMAT!1!IRFORMAT_Segment1!element],
SEGMENT2 as [IRFORMAT!1!IRFORMAT_Segment2!element],
SEGMENT3 as [IRFORMAT!1!IRFORMAT_Segment3!element],
SEGMENT4 as [IRFORMAT!1!IRFORMAT_Segment4!element],
SEGMENT5 as [IRFORMAT!1!IRFORMAT_Segment5!element],
INSTRUCTORFLAG as [IRFORMAT!1!IRFORMAT_Instructorflag!element],
OWNERFLAG as [IRFORMAT!1!IRFORMAT_Ownerflag!element],
STAFFFLAG as [IRFORMAT!1!IRFORMAT_Staffflag!element],
FAMILYFLAG as [IRFORMAT!1!IRFORMAT_Familyflag!element],
SEGMENT6 as [IRFORMAT!1!IRFORMAT_Segment6!element],
SEGMENT7 as [IRFORMAT!1!IRFORMAT_Segment7!element],
SEGMENT8 as [IRFORMAT!1!IRFORMAT_Segment8!element],
SEGMENT9 as [IRFORMAT!1!IRFORMAT_Segment9!element],
SEGMENT1CODE as [IRFORMAT!1!IRFORMAT_Segment1code!element],
SEGMENT2CODE as [IRFORMAT!1!IRFORMAT_Segment2code!element],
SEGMENT3CODE as [IRFORMAT!1!IRFORMAT_Segment3code!element],
SEGMENT4CODE as [IRFORMAT!1!IRFORMAT_Segment4code!element],
SEGMENT5CODE as [IRFORMAT!1!IRFORMAT_Segment5code!element],
SEGMENT6CODE as [IRFORMAT!1!IRFORMAT_Segment6code!element],
SEGMENT7CODE as [IRFORMAT!1!IRFORMAT_Segment7code!element],
SEGMENT8CODE as [IRFORMAT!1!IRFORMAT_Segment8code!element],
SEGMENT9CODE as [IRFORMAT!1!IRFORMAT_Segment9code!element]
FROM IRFORMAT
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Irformat>'
end

if @nErrorCode = 0
begin
	select '<Item>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
ITEM_ID as [ITEM!1!ITEM_Item_id!element],
ITEM_NAME as [ITEM!1!ITEM_Item_name!element],
SQL_QUERY as [ITEM!1!ITEM_Sql_query!cdata],
ITEM_DESCRIPTION as [ITEM!1!ITEM_Item_description!cdata],
CREATED_BY as [ITEM!1!ITEM_Created_by!element],
DATE_CREATED as [ITEM!1!ITEM_Date_created!element],
DATE_UPDATED as [ITEM!1!ITEM_Date_updated!element],
ITEM_TYPE as [ITEM!1!ITEM_Item_type!element],
ENTRY_POINT_USAGE as [ITEM!1!ITEM_Entry_point_usage!element],
SQL_DESCRIBE as [ITEM!1!ITEM_Sql_describe!cdata],
SQL_INTO as [ITEM!1!ITEM_Sql_into!cdata]
FROM ITEM
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Item>'
end

if @nErrorCode = 0
begin
	select '<Item_group>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
GROUP_CODE as [ITEM_GROUP!1!ITEM_GROUP_Group_code!element],
ITEM_ID as [ITEM_GROUP!1!ITEM_GROUP_Item_id!element]
FROM ITEM_GROUP
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Item_group>'
end

if @nErrorCode = 0
begin
	select '<Item_note>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
ITEM_ID as [ITEM_NOTE!1!ITEM_NOTE_Item_id!element],
ITEM_NOTES as [ITEM_NOTE!1!ITEM_NOTE_Item_notes!cdata]
FROM ITEM_NOTE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Item_note>'
end

if @nErrorCode = 0
begin
	select '<Language>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
LANGUAGE_CODE as [LANGUAGE!1!LANGUAGE_Language_code!element],
LANGUAGE as [LANGUAGE!1!LANGUAGE_Language!element]
FROM LANGUAGE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Language>'
end

if @nErrorCode = 0
begin
	select '<Letter>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
LETTERNO as [LETTER!1!LETTER_Letterno!element],
LETTERNAME as [LETTER!1!LETTER_Lettername!cdata],
DOCUMENTCODE as [LETTER!1!LETTER_Documentcode!element],
CORRESPONDTYPE as [LETTER!1!LETTER_Correspondtype!element],
COPIESALLOWEDFLAG as [LETTER!1!LETTER_Copiesallowedflag!element],
COVERINGLETTER as [LETTER!1!LETTER_Coveringletter!element],
EXTRACOPIES as [LETTER!1!LETTER_Extracopies!element],
MULTICASEFLAG as [LETTER!1!LETTER_Multicaseflag!element],
MACRO as [LETTER!1!LETTER_Macro!cdata],
SINGLECASELETTERNO as [LETTER!1!LETTER_Singlecaseletterno!element],
INSTRUCTIONTYPE as [LETTER!1!LETTER_Instructiontype!cdata],
ENVELOPE as [LETTER!1!LETTER_Envelope!element],
COUNTRYCODE as [LETTER!1!LETTER_Countrycode!cdata],
DELIVERYID as [LETTER!1!LETTER_Deliveryid!element],
PROPERTYTYPE as [LETTER!1!LETTER_Propertytype!cdata],
HOLDFLAG as [LETTER!1!LETTER_Holdflag!element],
NOTES as [LETTER!1!LETTER_Notes!cdata],
DOCUMENTTYPE as [LETTER!1!LETTER_Documenttype!element],
USEDBY as [LETTER!1!LETTER_Usedby!element],
FORPRIMECASESONLY as [LETTER!1!LETTER_Forprimecasesonly!element],
GENERATEASANSI as [LETTER!1!LETTER_Generateasansi!element],
ADDATTACHMENTFLAG as [LETTER!1!LETTER_Addattachmentflag!element],
ACTIVITYTYPE as [LETTER!1!LETTER_Activitytype!element],
ACTIVITYCATEGORY as [LETTER!1!LETTER_Activitycategory!element],
ENTRYPOINTTYPE as [LETTER!1!LETTER_Entrypointtype!element],
SOURCEFILE as [LETTER!1!LETTER_Sourcefile!cdata],
EXTERNALUSAGE as [LETTER!1!LETTER_Externalusage!element],
DELIVERLETTER as [LETTER!1!LETTER_Deliverletter!element],
DOCITEMMAILBOX as [LETTER!1!LETTER_Docitemmailbox!element],
DOCITEMSUBJECT as [LETTER!1!LETTER_Docitemsubject!element],
DOCITEMBODY as [LETTER!1!LETTER_Docitembody!element],
PROTECTEDFLAG as [LETTER!1!LETTER_Protectedflag!element]
FROM LETTER
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Letter>'
end

if @nErrorCode = 0
begin
	select '<Mapping>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
ENTRYID as [MAPPING!1!MAPPING_Entryid!element],
STRUCTUREID as [MAPPING!1!MAPPING_Structureid!element],
DATASOURCEID as [MAPPING!1!MAPPING_Datasourceid!element],
INPUTCODE as [MAPPING!1!MAPPING_Inputcode!element],
INPUTDESCRIPTION as [MAPPING!1!MAPPING_Inputdescription!cdata],
INPUTCODEID as [MAPPING!1!MAPPING_Inputcodeid!element],
OUTPUTCODEID as [MAPPING!1!MAPPING_Outputcodeid!element],
OUTPUTVALUE as [MAPPING!1!MAPPING_Outputvalue!element],
ISNOTAPPLICABLE as [MAPPING!1!MAPPING_Isnotapplicable!element]
FROM MAPPING
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Mapping>'
end

if @nErrorCode = 0
begin
	select '<Mapscenario>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
SCENARIOID as [MAPSCENARIO!1!MAPSCENARIO_Scenarioid!element],
SYSTEMID as [MAPSCENARIO!1!MAPSCENARIO_Systemid!element],
STRUCTUREID as [MAPSCENARIO!1!MAPSCENARIO_Structureid!element],
SCHEMEID as [MAPSCENARIO!1!MAPSCENARIO_Schemeid!element],
IGNOREUNMAPPED as [MAPSCENARIO!1!MAPSCENARIO_Ignoreunmapped!element]
FROM MAPSCENARIO
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Mapscenario>'
end

if @nErrorCode = 0
begin
	select '<Mapstructure>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
STRUCTUREID as [MAPSTRUCTURE!1!MAPSTRUCTURE_Structureid!element],
STRUCTURENAME as [MAPSTRUCTURE!1!MAPSTRUCTURE_Structurename!element],
TABLENAME as [MAPSTRUCTURE!1!MAPSTRUCTURE_Tablename!element],
KEYCOLUMNAME as [MAPSTRUCTURE!1!MAPSTRUCTURE_Keycolumname!element],
CODECOLUMNNAME as [MAPSTRUCTURE!1!MAPSTRUCTURE_Codecolumnname!element],
DESCCOLUMNNAME as [MAPSTRUCTURE!1!MAPSTRUCTURE_Desccolumnname!element],
SEARCHCONTEXTID as [MAPSTRUCTURE!1!MAPSTRUCTURE_Searchcontextid!element]
FROM MAPSTRUCTURE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Mapstructure>'
end

if @nErrorCode = 0
begin
	select '<Module>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
MODULEID as [MODULE!1!MODULE_Moduleid!element],
MODULEDEFID as [MODULE!1!MODULE_Moduledefid!element],
TITLE as [MODULE!1!MODULE_Title!cdata],
CACHETIME as [MODULE!1!MODULE_Cachetime!element],
DESCRIPTION as [MODULE!1!MODULE_Description!cdata]
FROM MODULE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Module>'
end

if @nErrorCode = 0
begin
	select '<Moduleconfiguration>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CONFIGURATIONID as [MODULECONFIGURATION!1!MODULECONFIGURATION_Configurationid!element],
IDENTITYID as [MODULECONFIGURATION!1!MODULECONFIGURATION_Identityid!element],
TABID as [MODULECONFIGURATION!1!MODULECONFIGURATION_Tabid!element],
MODULEID as [MODULECONFIGURATION!1!MODULECONFIGURATION_Moduleid!element],
MODULESEQUENCE as [MODULECONFIGURATION!1!MODULECONFIGURATION_Modulesequence!element],
PANELLOCATION as [MODULECONFIGURATION!1!MODULECONFIGURATION_Panellocation!element],
PORTALID as [MODULECONFIGURATION!1!MODULECONFIGURATION_Portalid!element]
FROM MODULECONFIGURATION
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Moduleconfiguration>'
end

if @nErrorCode = 0
begin
	select '<Moduledefinition>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
MODULEDEFID as [MODULEDEFINITION!1!MODULEDEFINITION_Moduledefid!element],
NAME as [MODULEDEFINITION!1!MODULEDEFINITION_Name!element],
DESKTOPSRC as [MODULEDEFINITION!1!MODULEDEFINITION_Desktopsrc!cdata],
MOBILESRC as [MODULEDEFINITION!1!MODULEDEFINITION_Mobilesrc!cdata]
FROM MODULEDEFINITION
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Moduledefinition>'
end

if @nErrorCode = 0
begin
	select '<Namecriteria>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
PURPOSECODE as [NAMECRITERIA!1!NAMECRITERIA_Purposecode!cdata],
PROGRAMID as [NAMECRITERIA!1!NAMECRITERIA_Programid!element],
USEDASFLAG as [NAMECRITERIA!1!NAMECRITERIA_Usedasflag!element],
SUPPLIERFLAG as [NAMECRITERIA!1!NAMECRITERIA_Supplierflag!element],
DATAUNKNOWN as [NAMECRITERIA!1!NAMECRITERIA_Dataunknown!element],
COUNTRYCODE as [NAMECRITERIA!1!NAMECRITERIA_Countrycode!cdata],
LOCALCLIENTFLAG as [NAMECRITERIA!1!NAMECRITERIA_Localclientflag!element],
CATEGORY as [NAMECRITERIA!1!NAMECRITERIA_Category!element],
NAMETYPE as [NAMECRITERIA!1!NAMECRITERIA_Nametype!cdata],
USERDEFINEDRULE as [NAMECRITERIA!1!NAMECRITERIA_Userdefinedrule!element],
RULEINUSE as [NAMECRITERIA!1!NAMECRITERIA_Ruleinuse!element],
DESCRIPTION as [NAMECRITERIA!1!NAMECRITERIA_Description!cdata],
RELATIONSHIP as [NAMECRITERIA!1!NAMECRITERIA_Relationship!cdata],
NAMECRITERIANO as [NAMECRITERIA!1!NAMECRITERIA_Namecriteriano!element],
PROFILEID as [NAMECRITERIA!1!NAMECRITERIA_Profileid!element]
FROM NAMECRITERIA
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Namecriteria>'
end

if @nErrorCode = 0
begin
	select '<Namecriteriainherits>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
NAMECRITERIANO as [NAMECRITERIAINHERITS!1!NAMECRITERIAINHERITS_Namecriteriano!element],
FROMNAMECRITERIANO as [NAMECRITERIAINHERITS!1!NAMECRITERIAINHERITS_Fromnamecriteriano!element]
FROM NAMECRITERIAINHERITS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Namecriteriainherits>'
end

if @nErrorCode = 0
begin
	select '<Namegroups>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
NAMEGROUP as [NAMEGROUPS!1!NAMEGROUPS_Namegroup!element],
GROUPDESCRIPTION as [NAMEGROUPS!1!NAMEGROUPS_Groupdescription!element]
FROM NAMEGROUPS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Namegroups>'
end

if @nErrorCode = 0
begin
	select '<Namerelation>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
RELATIONSHIP as [NAMERELATION!1!NAMERELATION_Relationship!cdata],
RELATIONDESCR as [NAMERELATION!1!NAMERELATION_Relationdescr!element],
REVERSEDESCR as [NAMERELATION!1!NAMERELATION_Reversedescr!element],
SHOWFLAG as [NAMERELATION!1!NAMERELATION_Showflag!element],
USEDBYNAMETYPE as [NAMERELATION!1!NAMERELATION_Usedbynametype!element],
CRMONLY as [NAMERELATION!1!NAMERELATION_Crmonly!element],
ETHICALWALL as [NAMERELATION!1!NAMERELATION_Ethicalwall!element]
FROM NAMERELATION
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Namerelation>'
end

if @nErrorCode = 0
begin
	select '<Nametype>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
NAMETYPE as [NAMETYPE!1!NAMETYPE_Nametype!cdata],
DESCRIPTION as [NAMETYPE!1!NAMETYPE_Description!element],
PATHNAMETYPE as [NAMETYPE!1!NAMETYPE_Pathnametype!cdata],
PATHRELATIONSHIP as [NAMETYPE!1!NAMETYPE_Pathrelationship!cdata],
HIERARCHYFLAG as [NAMETYPE!1!NAMETYPE_Hierarchyflag!element],
MANDATORYFLAG as [NAMETYPE!1!NAMETYPE_Mandatoryflag!element],
KEEPSTREETFLAG as [NAMETYPE!1!NAMETYPE_Keepstreetflag!element],
COLUMNFLAGS as [NAMETYPE!1!NAMETYPE_Columnflags!element],
MAXIMUMALLOWED as [NAMETYPE!1!NAMETYPE_Maximumallowed!element],
PICKLISTFLAGS as [NAMETYPE!1!NAMETYPE_Picklistflags!element],
SHOWNAMECODE as [NAMETYPE!1!NAMETYPE_Shownamecode!element],
DEFAULTNAMENO as [NAMETYPE!1!NAMETYPE_Defaultnameno!element],
NAMERESTRICTFLAG as [NAMETYPE!1!NAMETYPE_Namerestrictflag!element],
CHANGEEVENTNO as [NAMETYPE!1!NAMETYPE_Changeeventno!element],
FUTURENAMETYPE as [NAMETYPE!1!NAMETYPE_Futurenametype!cdata],
USEHOMENAMEREL as [NAMETYPE!1!NAMETYPE_Usehomenamerel!element],
UPDATEFROMPARENT as [NAMETYPE!1!NAMETYPE_Updatefromparent!element],
OLDNAMETYPE as [NAMETYPE!1!NAMETYPE_Oldnametype!cdata],
BULKENTRYFLAG as [NAMETYPE!1!NAMETYPE_Bulkentryflag!element],
NAMETYPEID as [NAMETYPE!1!NAMETYPE_Nametypeid!element],
KOTTEXTTYPE as [NAMETYPE!1!NAMETYPE_Kottexttype!cdata],
PROGRAM as [NAMETYPE!1!NAMETYPE_Program!element],
ETHICALWALL as [NAMETYPE!1!NAMETYPE_Ethicalwall!element],
PRIORITYORDER as [NAMETYPE!1!NAMETYPE_Priorityorder!element],
NATIONALITYFLAG as [NAMETYPE!1!NAMETYPE_Nationalityflag!element]
FROM NAMETYPE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Nametype>'
end

if @nErrorCode = 0
begin
	select '<Narrative>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
NARRATIVENO as [NARRATIVE!1!NARRATIVE_Narrativeno!element],
NARRATIVECODE as [NARRATIVE!1!NARRATIVE_Narrativecode!element],
NARRATIVETITLE as [NARRATIVE!1!NARRATIVE_Narrativetitle!element],
NARRATIVETEXT as [NARRATIVE!1!NARRATIVE_Narrativetext!cdata]
FROM NARRATIVE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Narrative>'
end

if @nErrorCode = 0
begin
	select '<Narrativerule>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
NARRATIVERULENO as [NARRATIVERULE!1!NARRATIVERULE_Narrativeruleno!element],
NARRATIVENO as [NARRATIVERULE!1!NARRATIVERULE_Narrativeno!element],
WIPCODE as [NARRATIVERULE!1!NARRATIVERULE_Wipcode!element],
EMPLOYEENO as [NARRATIVERULE!1!NARRATIVERULE_Employeeno!element],
CASETYPE as [NARRATIVERULE!1!NARRATIVERULE_Casetype!cdata],
PROPERTYTYPE as [NARRATIVERULE!1!NARRATIVERULE_Propertytype!cdata],
CASECATEGORY as [NARRATIVERULE!1!NARRATIVERULE_Casecategory!cdata],
SUBTYPE as [NARRATIVERULE!1!NARRATIVERULE_Subtype!cdata],
TYPEOFMARK as [NARRATIVERULE!1!NARRATIVERULE_Typeofmark!element],
COUNTRYCODE as [NARRATIVERULE!1!NARRATIVERULE_Countrycode!cdata],
LOCALCOUNTRYFLAG as [NARRATIVERULE!1!NARRATIVERULE_Localcountryflag!element],
FOREIGNCOUNTRYFLAG as [NARRATIVERULE!1!NARRATIVERULE_Foreigncountryflag!element],
DEBTORNO as [NARRATIVERULE!1!NARRATIVERULE_Debtorno!element]
FROM NARRATIVERULE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Narrativerule>'
end

if @nErrorCode = 0
begin
	select '<Numbertypes>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
NUMBERTYPE as [NUMBERTYPES!1!NUMBERTYPES_Numbertype!cdata],
DESCRIPTION as [NUMBERTYPES!1!NUMBERTYPES_Description!element],
RELATEDEVENTNO as [NUMBERTYPES!1!NUMBERTYPES_Relatedeventno!element],
ISSUEDBYIPOFFICE as [NUMBERTYPES!1!NUMBERTYPES_Issuedbyipoffice!element],
DISPLAYPRIORITY as [NUMBERTYPES!1!NUMBERTYPES_Displaypriority!element]
FROM NUMBERTYPES
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Numbertypes>'
end

if @nErrorCode = 0
begin
	select '<Office>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
OFFICEID as [OFFICE!1!OFFICE_Officeid!element],
DESCRIPTION as [OFFICE!1!OFFICE_Description!element],
USERCODE as [OFFICE!1!OFFICE_Usercode!element],
COUNTRYCODE as [OFFICE!1!OFFICE_Countrycode!cdata],
LANGUAGECODE as [OFFICE!1!OFFICE_Languagecode!element],
CPACODE as [OFFICE!1!OFFICE_Cpacode!cdata],
RESOURCENO as [OFFICE!1!OFFICE_Resourceno!element],
ITEMNOPREFIX as [OFFICE!1!OFFICE_Itemnoprefix!cdata],
ITEMNOFROM as [OFFICE!1!OFFICE_Itemnofrom!element],
ITEMNOTO as [OFFICE!1!OFFICE_Itemnoto!element],
LASTITEMNO as [OFFICE!1!OFFICE_Lastitemno!element],
REGION as [OFFICE!1!OFFICE_Region!element],
ORGNAMENO as [OFFICE!1!OFFICE_Orgnameno!element],
IRNCODE as [OFFICE!1!OFFICE_Irncode!cdata]
FROM OFFICE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Office>'
end

if @nErrorCode = 0
begin
	select '<Paymentmethods>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
PAYMENTMETHOD as [PAYMENTMETHODS!1!PAYMENTMETHODS_Paymentmethod!element],
PAYMENTDESCRIPTION as [PAYMENTMETHODS!1!PAYMENTMETHODS_Paymentdescription!element],
PRESENTPHYSICALLY as [PAYMENTMETHODS!1!PAYMENTMETHODS_Presentphysically!element],
USEDBY as [PAYMENTMETHODS!1!PAYMENTMETHODS_Usedby!element]
FROM PAYMENTMETHODS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Paymentmethods>'
end

if @nErrorCode = 0
begin
	select '<Permissions>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
PERMISSIONID as [PERMISSIONS!1!PERMISSIONS_Permissionid!element],
OBJECTTABLE as [PERMISSIONS!1!PERMISSIONS_Objecttable!element],
OBJECTINTEGERKEY as [PERMISSIONS!1!PERMISSIONS_Objectintegerkey!element],
OBJECTSTRINGKEY as [PERMISSIONS!1!PERMISSIONS_Objectstringkey!element],
LEVELTABLE as [PERMISSIONS!1!PERMISSIONS_Leveltable!element],
LEVELKEY as [PERMISSIONS!1!PERMISSIONS_Levelkey!element],
GRANTPERMISSION as [PERMISSIONS!1!PERMISSIONS_Grantpermission!element],
DENYPERMISSION as [PERMISSIONS!1!PERMISSIONS_Denypermission!element]
FROM PERMISSIONS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Permissions>'
end

if @nErrorCode = 0
begin
	select '<Portal>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
PORTALID as [PORTAL!1!PORTAL_Portalid!element],
NAME as [PORTAL!1!PORTAL_Name!element],
DESCRIPTION as [PORTAL!1!PORTAL_Description!cdata],
ISEXTERNAL as [PORTAL!1!PORTAL_Isexternal!element]
FROM PORTAL
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Portal>'
end

if @nErrorCode = 0
begin
	select '<Portalmenu>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
MENUID as [PORTALMENU!1!PORTALMENU_Menuid!element],
ANONYMOUSUSER as [PORTALMENU!1!PORTALMENU_Anonymoususer!element],
HEADER as [PORTALMENU!1!PORTALMENU_Header!element],
PARENTID as [PORTALMENU!1!PORTALMENU_Parentid!element],
LABEL as [PORTALMENU!1!PORTALMENU_Label!cdata],
SEQUENCE as [PORTALMENU!1!PORTALMENU_Sequence!element],
IDENTITYID as [PORTALMENU!1!PORTALMENU_Identityid!element],
OVERRIDDEN as [PORTALMENU!1!PORTALMENU_Overridden!element],
TASKID as [PORTALMENU!1!PORTALMENU_Taskid!element],
HREF as [PORTALMENU!1!PORTALMENU_Href!cdata],
VIEWID as [PORTALMENU!1!PORTALMENU_Viewid!element]
FROM PORTALMENU
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Portalmenu>'
end

if @nErrorCode = 0
begin
	select '<Portalsetting>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
SETTINGID as [PORTALSETTING!1!PORTALSETTING_Settingid!element],
MODULEID as [PORTALSETTING!1!PORTALSETTING_Moduleid!element],
MODULECONFIGID as [PORTALSETTING!1!PORTALSETTING_Moduleconfigid!element],
IDENTITYID as [PORTALSETTING!1!PORTALSETTING_Identityid!element],
SETTINGNAME as [PORTALSETTING!1!PORTALSETTING_Settingname!element],
SETTINGVALUE as [PORTALSETTING!1!PORTALSETTING_Settingvalue!cdata]
FROM PORTALSETTING
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Portalsetting>'
end

if @nErrorCode = 0
begin
	select '<Portaltab>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
TABID as [PORTALTAB!1!PORTALTAB_Tabid!element],
TABNAME as [PORTALTAB!1!PORTALTAB_Tabname!element],
IDENTITYID as [PORTALTAB!1!PORTALTAB_Identityid!element],
TABSEQUENCE as [PORTALTAB!1!PORTALTAB_Tabsequence!element],
PORTALID as [PORTALTAB!1!PORTALTAB_Portalid!element],
CSSCLASSNAME as [PORTALTAB!1!PORTALTAB_Cssclassname!element],
CANRENAME as [PORTALTAB!1!PORTALTAB_Canrename!element],
CANDELETE as [PORTALTAB!1!PORTALTAB_Candelete!element],
PARENTTABID as [PORTALTAB!1!PORTALTAB_Parenttabid!element]
FROM PORTALTAB
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Portaltab>'
end

if @nErrorCode = 0
begin
	select '<Portaltabconfiguration>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CONFIGURATIONID as [PORTALTABCONFIGURATION!1!PORTALTABCONFIGURATION_Configurationid!element],
IDENTITYID as [PORTALTABCONFIGURATION!1!PORTALTABCONFIGURATION_Identityid!element],
TABID as [PORTALTABCONFIGURATION!1!PORTALTABCONFIGURATION_Tabid!element],
TABSEQUENCE as [PORTALTABCONFIGURATION!1!PORTALTABCONFIGURATION_Tabsequence!element],
PORTALID as [PORTALTABCONFIGURATION!1!PORTALTABCONFIGURATION_Portalid!element]
FROM PORTALTABCONFIGURATION
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Portaltabconfiguration>'
end

if @nErrorCode = 0
begin
	select '<Profileattributes>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
PROFILEID as [PROFILEATTRIBUTES!1!PROFILEATTRIBUTES_Profileid!element],
ATTRIBUTEID as [PROFILEATTRIBUTES!1!PROFILEATTRIBUTES_Attributeid!element],
ATTRIBUTEVALUE as [PROFILEATTRIBUTES!1!PROFILEATTRIBUTES_Attributevalue!cdata]
FROM PROFILEATTRIBUTES
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Profileattributes>'
end

if @nErrorCode = 0
begin
	select '<Profileprogram>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
PROFILEID as [PROFILEPROGRAM!1!PROFILEPROGRAM_Profileid!element],
PROGRAMID as [PROFILEPROGRAM!1!PROFILEPROGRAM_Programid!element]
FROM PROFILEPROGRAM
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Profileprogram>'
end

if @nErrorCode = 0
begin
	select '<Profiles>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
PROFILEID as [PROFILES!1!PROFILES_Profileid!element],
PROFILENAME as [PROFILES!1!PROFILES_Profilename!element],
DESCRIPTION as [PROFILES!1!PROFILES_Description!cdata]
FROM PROFILES
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Profiles>'
end

if @nErrorCode = 0
begin
	select '<Profitcentre>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
PROFITCENTRECODE as [PROFITCENTRE!1!PROFITCENTRE_Profitcentrecode!element],
ENTITYNO as [PROFITCENTRE!1!PROFITCENTRE_Entityno!element],
DESCRIPTION as [PROFITCENTRE!1!PROFITCENTRE_Description!element],
INCLUDEONLYWIP as [PROFITCENTRE!1!PROFITCENTRE_Includeonlywip!cdata]
FROM PROFITCENTRE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Profitcentre>'
end

if @nErrorCode = 0
begin
	select '<Profitcentrerule>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
ANALYSISCODE as [PROFITCENTRERULE!1!PROFITCENTRERULE_Analysiscode!element],
PROFITCENTRECODE as [PROFITCENTRERULE!1!PROFITCENTRERULE_Profitcentrecode!element]
FROM PROFITCENTRERULE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Profitcentrerule>'
end

if @nErrorCode = 0
begin
	select '<Program>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
PROGRAMID as [PROGRAM!1!PROGRAM_Programid!element],
PROGRAMNAME as [PROGRAM!1!PROGRAM_Programname!element],
PARENTPROGRAM as [PROGRAM!1!PROGRAM_Parentprogram!element],
PROGRAMGROUP as [PROGRAM!1!PROGRAM_Programgroup!element]
FROM PROGRAM
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Program>'
end

if @nErrorCode = 0
begin
	select '<Propertytype>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
PROPERTYTYPE as [PROPERTYTYPE!1!PROPERTYTYPE_Propertytype!cdata],
PROPERTYNAME as [PROPERTYTYPE!1!PROPERTYTYPE_Propertyname!element],
ALLOWSUBCLASS as [PROPERTYTYPE!1!PROPERTYTYPE_Allowsubclass!element],
CRMONLY as [PROPERTYTYPE!1!PROPERTYTYPE_Crmonly!element]
FROM PROPERTYTYPE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Propertytype>'
end

if @nErrorCode = 0
begin
	select '<Protectcodes>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
PROTECTKEY as [PROTECTCODES!1!PROTECTCODES_Protectkey!element],
TABLECODE as [PROTECTCODES!1!PROTECTCODES_Tablecode!element],
TABLETYPE as [PROTECTCODES!1!PROTECTCODES_Tabletype!element],
EVENTNO as [PROTECTCODES!1!PROTECTCODES_Eventno!element],
CASERELATIONSHIP as [PROTECTCODES!1!PROTECTCODES_Caserelationship!cdata],
NAMERELATIONSHIP as [PROTECTCODES!1!PROTECTCODES_Namerelationship!cdata],
NUMBERTYPE as [PROTECTCODES!1!PROTECTCODES_Numbertype!cdata],
CASETYPE as [PROTECTCODES!1!PROTECTCODES_Casetype!cdata],
NAMETYPE as [PROTECTCODES!1!PROTECTCODES_Nametype!cdata],
ADJUSTMENT as [PROTECTCODES!1!PROTECTCODES_Adjustment!element],
TEXTTYPE as [PROTECTCODES!1!PROTECTCODES_Texttype!cdata],
FAMILY as [PROTECTCODES!1!PROTECTCODES_Family!element]
FROM PROTECTCODES
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Protectcodes>'
end

if @nErrorCode = 0
begin
	select '<Quantitysource>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
QUANTITYSOURCEID as [QUANTITYSOURCE!1!QUANTITYSOURCE_Quantitysourceid!element],
SOURCE as [QUANTITYSOURCE!1!QUANTITYSOURCE_Source!element],
FROMEVENTNO as [QUANTITYSOURCE!1!QUANTITYSOURCE_Fromeventno!element],
UNTILEVENTNO as [QUANTITYSOURCE!1!QUANTITYSOURCE_Untileventno!element],
PERIODTYPE as [QUANTITYSOURCE!1!QUANTITYSOURCE_Periodtype!cdata]
FROM QUANTITYSOURCE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Quantitysource>'
end

if @nErrorCode = 0
begin
	select '<Querycontext>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CONTEXTID as [QUERYCONTEXT!1!QUERYCONTEXT_Contextid!element],
CONTEXTNAME as [QUERYCONTEXT!1!QUERYCONTEXT_Contextname!element],
PROCEDURENAME as [QUERYCONTEXT!1!QUERYCONTEXT_Procedurename!element],
NOTES as [QUERYCONTEXT!1!QUERYCONTEXT_Notes!cdata],
FILTERXSLTTODB as [QUERYCONTEXT!1!QUERYCONTEXT_Filterxslttodb!cdata],
FILTERXSLTFROMDB as [QUERYCONTEXT!1!QUERYCONTEXT_Filterxsltfromdb!cdata]
FROM QUERYCONTEXT
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Querycontext>'
end

if @nErrorCode = 0
begin
	select '<Querydataitem>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
DATAITEMID as [QUERYDATAITEM!1!QUERYDATAITEM_Dataitemid!element],
PROCEDURENAME as [QUERYDATAITEM!1!QUERYDATAITEM_Procedurename!element],
PROCEDUREITEMID as [QUERYDATAITEM!1!QUERYDATAITEM_Procedureitemid!element],
QUALIFIERTYPE as [QUERYDATAITEM!1!QUERYDATAITEM_Qualifiertype!element],
SORTDIRECTION as [QUERYDATAITEM!1!QUERYDATAITEM_Sortdirection!cdata],
DESCRIPTION as [QUERYDATAITEM!1!QUERYDATAITEM_Description!cdata],
ISMULTIRESULT as [QUERYDATAITEM!1!QUERYDATAITEM_Ismultiresult!element],
DATAFORMATID as [QUERYDATAITEM!1!QUERYDATAITEM_Dataformatid!element],
DECIMALPLACES as [QUERYDATAITEM!1!QUERYDATAITEM_Decimalplaces!element],
FORMATITEMID as [QUERYDATAITEM!1!QUERYDATAITEM_Formatitemid!element],
FILTERNODENAME as [QUERYDATAITEM!1!QUERYDATAITEM_Filternodename!element],
ISAGGREGATE as [QUERYDATAITEM!1!QUERYDATAITEM_Isaggregate!element]
FROM QUERYDATAITEM
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Querydataitem>'
end

if @nErrorCode = 0
begin
	select '<Question>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
QUESTIONNO as [QUESTION!1!QUESTION_Questionno!element],
IMPORTANCELEVEL as [QUESTION!1!QUESTION_Importancelevel!cdata],
QUESTIONCODE as [QUESTION!1!QUESTION_Questioncode!element],
QUESTION as [QUESTION!1!QUESTION_Question!element],
YESNOREQUIRED as [QUESTION!1!QUESTION_Yesnorequired!element],
COUNTREQUIRED as [QUESTION!1!QUESTION_Countrequired!element],
PERIODTYPEREQUIRED as [QUESTION!1!QUESTION_Periodtyperequired!element],
AMOUNTREQUIRED as [QUESTION!1!QUESTION_Amountrequired!element],
EMPLOYEEREQUIRED as [QUESTION!1!QUESTION_Employeerequired!element],
TEXTREQUIRED as [QUESTION!1!QUESTION_Textrequired!element],
TABLETYPE as [QUESTION!1!QUESTION_Tabletype!element]
FROM QUESTION
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Question>'
end

if @nErrorCode = 0
begin
	select '<Rates>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
RATENO as [RATES!1!RATES_Rateno!element],
RATEDESC as [RATES!1!RATES_Ratedesc!element],
RATETYPE as [RATES!1!RATES_Ratetype!element],
USETYPEOFMARK as [RATES!1!RATES_Usetypeofmark!element],
RATENOSORT as [RATES!1!RATES_Ratenosort!element],
CALCLABEL1 as [RATES!1!RATES_Calclabel1!element],
CALCLABEL2 as [RATES!1!RATES_Calclabel2!element],
ACTION as [RATES!1!RATES_Action!cdata],
AGENTNAMETYPE as [RATES!1!RATES_Agentnametype!cdata]
FROM RATES
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Rates>'
end

if @nErrorCode = 0
begin
	select '<Reason>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
REASONCODE as [REASON!1!REASON_Reasoncode!cdata],
DESCRIPTION as [REASON!1!REASON_Description!element],
USED_BY as [REASON!1!REASON_Used_by!element],
SHOWONDEBITNOTE as [REASON!1!REASON_Showondebitnote!element],
ISPROTECTED as [REASON!1!REASON_Isprotected!element]
FROM REASON
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Reason>'
end

if @nErrorCode = 0
begin
	select '<Recordalelement>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
RECORDALELEMENTNO as [RECORDALELEMENT!1!RECORDALELEMENT_Recordalelementno!element],
RECORDALTYPENO as [RECORDALELEMENT!1!RECORDALELEMENT_Recordaltypeno!element],
ELEMENTNO as [RECORDALELEMENT!1!RECORDALELEMENT_Elementno!element],
ELEMENTLABEL as [RECORDALELEMENT!1!RECORDALELEMENT_Elementlabel!element],
NAMETYPE as [RECORDALELEMENT!1!RECORDALELEMENT_Nametype!cdata],
EDITATTRIBUTE as [RECORDALELEMENT!1!RECORDALELEMENT_Editattribute!cdata]
FROM RECORDALELEMENT
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Recordalelement>'
end

if @nErrorCode = 0
begin
	select '<Recordaltype>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
RECORDALTYPENO as [RECORDALTYPE!1!RECORDALTYPE_Recordaltypeno!element],
RECORDALTYPE as [RECORDALTYPE!1!RECORDALTYPE_Recordaltype!element],
REQUESTEVENTNO as [RECORDALTYPE!1!RECORDALTYPE_Requesteventno!element],
REQUESTACTION as [RECORDALTYPE!1!RECORDALTYPE_Requestaction!cdata],
RECORDEVENTNO as [RECORDALTYPE!1!RECORDALTYPE_Recordeventno!element],
RECORDACTION as [RECORDALTYPE!1!RECORDALTYPE_Recordaction!cdata]
FROM RECORDALTYPE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Recordaltype>'
end

if @nErrorCode = 0
begin
	select '<Recordtype>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
RECORDTYPE as [RECORDTYPE!1!RECORDTYPE_Recordtype!cdata],
RECORDTYPEDESC as [RECORDTYPE!1!RECORDTYPE_Recordtypedesc!element]
FROM RECORDTYPE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Recordtype>'
end

if @nErrorCode = 0
begin
	select '<Relatedevents>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [RELATEDEVENTS!1!RELATEDEVENTS_Criteriano!element],
EVENTNO as [RELATEDEVENTS!1!RELATEDEVENTS_Eventno!element],
RELATEDNO as [RELATEDEVENTS!1!RELATEDEVENTS_Relatedno!element],
RELATEDEVENT as [RELATEDEVENTS!1!RELATEDEVENTS_Relatedevent!element],
CLEAREVENT as [RELATEDEVENTS!1!RELATEDEVENTS_Clearevent!element],
CLEARDUE as [RELATEDEVENTS!1!RELATEDEVENTS_Cleardue!element],
SATISFYEVENT as [RELATEDEVENTS!1!RELATEDEVENTS_Satisfyevent!element],
UPDATEEVENT as [RELATEDEVENTS!1!RELATEDEVENTS_Updateevent!element],
CREATENEXTCYCLE as [RELATEDEVENTS!1!RELATEDEVENTS_Createnextcycle!element],
ADJUSTMENT as [RELATEDEVENTS!1!RELATEDEVENTS_Adjustment!element],
INHERITED as [RELATEDEVENTS!1!RELATEDEVENTS_Inherited!element],
RELATIVECYCLE as [RELATEDEVENTS!1!RELATEDEVENTS_Relativecycle!element],
CLEAREVENTONDUECHANGE as [RELATEDEVENTS!1!RELATEDEVENTS_Cleareventonduechange!element],
CLEARDUEONDUECHANGE as [RELATEDEVENTS!1!RELATEDEVENTS_Cleardueonduechange!element]
FROM RELATEDEVENTS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Relatedevents>'
end

if @nErrorCode = 0
begin
	select '<Reminders>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [REMINDERS!1!REMINDERS_Criteriano!element],
EVENTNO as [REMINDERS!1!REMINDERS_Eventno!element],
REMINDERNO as [REMINDERS!1!REMINDERS_Reminderno!element],
PERIODTYPE as [REMINDERS!1!REMINDERS_Periodtype!cdata],
LEADTIME as [REMINDERS!1!REMINDERS_Leadtime!element],
FREQUENCY as [REMINDERS!1!REMINDERS_Frequency!element],
STOPTIME as [REMINDERS!1!REMINDERS_Stoptime!element],
UPDATEEVENT as [REMINDERS!1!REMINDERS_Updateevent!element],
LETTERNO as [REMINDERS!1!REMINDERS_Letterno!element],
CHECKOVERRIDE as [REMINDERS!1!REMINDERS_Checkoverride!element],
MAXLETTERS as [REMINDERS!1!REMINDERS_Maxletters!element],
LETTERFEE as [REMINDERS!1!REMINDERS_Letterfee!element],
PAYFEECODE as [REMINDERS!1!REMINDERS_Payfeecode!cdata],
EMPLOYEEFLAG as [REMINDERS!1!REMINDERS_Employeeflag!element],
SIGNATORYFLAG as [REMINDERS!1!REMINDERS_Signatoryflag!element],
INSTRUCTORFLAG as [REMINDERS!1!REMINDERS_Instructorflag!element],
CRITICALFLAG as [REMINDERS!1!REMINDERS_Criticalflag!element],
REMINDEMPLOYEE as [REMINDERS!1!REMINDERS_Remindemployee!element],
USEMESSAGE1 as [REMINDERS!1!REMINDERS_Usemessage1!element],
MESSAGE1 as [REMINDERS!1!REMINDERS_Message1!cdata],
MESSAGE2 as [REMINDERS!1!REMINDERS_Message2!cdata],
INHERITED as [REMINDERS!1!REMINDERS_Inherited!element],
NAMETYPE as [REMINDERS!1!REMINDERS_Nametype!cdata],
SENDELECTRONICALLY as [REMINDERS!1!REMINDERS_Sendelectronically!element],
EMAILSUBJECT as [REMINDERS!1!REMINDERS_Emailsubject!element],
ESTIMATEFLAG as [REMINDERS!1!REMINDERS_Estimateflag!element],
FREQPERIODTYPE as [REMINDERS!1!REMINDERS_Freqperiodtype!cdata],
STOPTIMEPERIODTYPE as [REMINDERS!1!REMINDERS_Stoptimeperiodtype!cdata],
DIRECTPAYFLAG as [REMINDERS!1!REMINDERS_Directpayflag!element],
RELATIONSHIP as [REMINDERS!1!REMINDERS_Relationship!cdata],
EXTENDEDNAMETYPE as [REMINDERS!1!REMINDERS_Extendednametype!cdata]
FROM REMINDERS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Reminders>'
end

if @nErrorCode = 0
begin
	select '<Reqattributes>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [REQATTRIBUTES!1!REQATTRIBUTES_Criteriano!element],
TABLETYPE as [REQATTRIBUTES!1!REQATTRIBUTES_Tabletype!element]
FROM REQATTRIBUTES
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Reqattributes>'
end

if @nErrorCode = 0
begin
	select '<Resource>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
RESOURCENO as [RESOURCE!1!RESOURCE_Resourceno!element],
TYPE as [RESOURCE!1!RESOURCE_Type!element],
DESCRIPTION as [RESOURCE!1!RESOURCE_Description!cdata],
RESOURCE as [RESOURCE!1!RESOURCE_Resource!cdata],
DRIVER as [RESOURCE!1!RESOURCE_Driver!cdata],
PORT as [RESOURCE!1!RESOURCE_Port!cdata]
FROM RESOURCE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Resource>'
end

if @nErrorCode = 0
begin
	select '<Role>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
ROLEID as [ROLE!1!ROLE_Roleid!element],
ROLENAME as [ROLE!1!ROLE_Rolename!cdata],
DESCRIPTION as [ROLE!1!ROLE_Description!cdata],
ISEXTERNAL as [ROLE!1!ROLE_Isexternal!element],
DEFAULTPORTALID as [ROLE!1!ROLE_Defaultportalid!element],
ISPROTECTED as [ROLE!1!ROLE_Isprotected!element]
FROM ROLE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Role>'
end

if @nErrorCode = 0
begin
	select '<Rolescontrol>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [ROLESCONTROL!1!ROLESCONTROL_Criteriano!element],
ENTRYNUMBER as [ROLESCONTROL!1!ROLESCONTROL_Entrynumber!element],
ROLEID as [ROLESCONTROL!1!ROLESCONTROL_Roleid!element],
INHERITED as [ROLESCONTROL!1!ROLESCONTROL_Inherited!element]
FROM ROLESCONTROL
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Rolescontrol>'
end

if @nErrorCode = 0
begin
	select '<Roletasks>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
ROLEID as [ROLETASKS!1!ROLETASKS_Roleid!element],
TASKID as [ROLETASKS!1!ROLETASKS_Taskid!element]
FROM ROLETASKS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Roletasks>'
end

if @nErrorCode = 0
begin
	select '<Roletopics>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
ROLEID as [ROLETOPICS!1!ROLETOPICS_Roleid!element],
TOPICID as [ROLETOPICS!1!ROLETOPICS_Topicid!element]
FROM ROLETOPICS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Roletopics>'
end

if @nErrorCode = 0
begin
	select '<Screencontrol>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CRITERIANO as [SCREENCONTROL!1!SCREENCONTROL_Criteriano!element],
SCREENNAME as [SCREENCONTROL!1!SCREENCONTROL_Screenname!element],
SCREENID as [SCREENCONTROL!1!SCREENCONTROL_Screenid!element],
ENTRYNUMBER as [SCREENCONTROL!1!SCREENCONTROL_Entrynumber!element],
SCREENTITLE as [SCREENCONTROL!1!SCREENCONTROL_Screentitle!element],
DISPLAYSEQUENCE as [SCREENCONTROL!1!SCREENCONTROL_Displaysequence!element],
CHECKLISTTYPE as [SCREENCONTROL!1!SCREENCONTROL_Checklisttype!element],
TEXTTYPE as [SCREENCONTROL!1!SCREENCONTROL_Texttype!cdata],
NAMETYPE as [SCREENCONTROL!1!SCREENCONTROL_Nametype!cdata],
NAMEGROUP as [SCREENCONTROL!1!SCREENCONTROL_Namegroup!element],
FLAGNUMBER as [SCREENCONTROL!1!SCREENCONTROL_Flagnumber!element],
CREATEACTION as [SCREENCONTROL!1!SCREENCONTROL_Createaction!cdata],
RELATIONSHIP as [SCREENCONTROL!1!SCREENCONTROL_Relationship!cdata],
INHERITED as [SCREENCONTROL!1!SCREENCONTROL_Inherited!element],
PROFILENAME as [SCREENCONTROL!1!SCREENCONTROL_Profilename!element],
SCREENTIP as [SCREENCONTROL!1!SCREENCONTROL_Screentip!cdata],
MANDATORYFLAG as [SCREENCONTROL!1!SCREENCONTROL_Mandatoryflag!element],
GENERICPARAMETER as [SCREENCONTROL!1!SCREENCONTROL_Genericparameter!cdata]
FROM SCREENCONTROL
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Screencontrol>'
end

if @nErrorCode = 0
begin
	select '<Screens>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
SCREENNAME as [SCREENS!1!SCREENS_Screenname!element],
SCREENTITLE as [SCREENS!1!SCREENS_Screentitle!element],
SCREENTYPE as [SCREENS!1!SCREENS_Screentype!cdata],
SCREENIMAGE as [SCREENS!1!SCREENS_Screenimage!cdata]
FROM SCREENS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Screens>'
end

if @nErrorCode = 0
begin
	select '<Selectiontypes>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
PARENTTABLE as [SELECTIONTYPES!1!SELECTIONTYPES_Parenttable!element],
TABLETYPE as [SELECTIONTYPES!1!SELECTIONTYPES_Tabletype!element],
MINIMUMALLOWED as [SELECTIONTYPES!1!SELECTIONTYPES_Minimumallowed!element],
MAXIMUMALLOWED as [SELECTIONTYPES!1!SELECTIONTYPES_Maximumallowed!element],
MODIFYBYSERVICE as [SELECTIONTYPES!1!SELECTIONTYPES_Modifybyservice!element]
FROM SELECTIONTYPES
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Selectiontypes>'
end

if @nErrorCode = 0
begin
	select '<State>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
COUNTRYCODE as [STATE!1!STATE_Countrycode!cdata],
STATE as [STATE!1!STATE_State!element],
STATENAME as [STATE!1!STATE_Statename!element]
FROM STATE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</State>'
end

if @nErrorCode = 0
begin
	select '<Status>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
STATUSCODE as [STATUS!1!STATUS_Statuscode!element],
DISPLAYSEQUENCE as [STATUS!1!STATUS_Displaysequence!element],
USERSTATUSCODE as [STATUS!1!STATUS_Userstatuscode!element],
INTERNALDESC as [STATUS!1!STATUS_Internaldesc!element],
EXTERNALDESC as [STATUS!1!STATUS_Externaldesc!element],
LIVEFLAG as [STATUS!1!STATUS_Liveflag!element],
REGISTEREDFLAG as [STATUS!1!STATUS_Registeredflag!element],
RENEWALFLAG as [STATUS!1!STATUS_Renewalflag!element],
POLICERENEWALS as [STATUS!1!STATUS_Policerenewals!element],
POLICEEXAM as [STATUS!1!STATUS_Policeexam!element],
POLICEOTHERACTIONS as [STATUS!1!STATUS_Policeotheractions!element],
LETTERSALLOWED as [STATUS!1!STATUS_Lettersallowed!element],
CHARGESALLOWED as [STATUS!1!STATUS_Chargesallowed!element],
REMINDERSALLOWED as [STATUS!1!STATUS_Remindersallowed!element],
CONFIRMATIONREQ as [STATUS!1!STATUS_Confirmationreq!element],
STOPPAYREASON as [STATUS!1!STATUS_Stoppayreason!cdata],
PREVENTWIP as [STATUS!1!STATUS_Preventwip!element],
PREVENTBILLING as [STATUS!1!STATUS_Preventbilling!element],
PREVENTPREPAYMENT as [STATUS!1!STATUS_Preventprepayment!element],
PRIORARTFLAG as [STATUS!1!STATUS_Priorartflag!element]
FROM STATUS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Status>'
end

if @nErrorCode = 0
begin
	select '<Statuscasetype>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CASETYPE as [STATUSCASETYPE!1!STATUSCASETYPE_Casetype!cdata],
STATUSCODE as [STATUSCASETYPE!1!STATUSCASETYPE_Statuscode!element]
FROM STATUSCASETYPE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Statuscasetype>'
end

if @nErrorCode = 0
begin
	select '<Subject>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
SUBJECTCODE as [SUBJECT!1!SUBJECT_Subjectcode!element],
SUBJECTNAME as [SUBJECT!1!SUBJECT_Subjectname!element]
FROM SUBJECT
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Subject>'
end

if @nErrorCode = 0
begin
	select '<Subjectarea>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
SUBJECTAREANO as [SUBJECTAREA!1!SUBJECTAREA_Subjectareano!element],
PARENTTABLE as [SUBJECTAREA!1!SUBJECTAREA_Parenttable!element],
SUBJECTAREADESC as [SUBJECTAREA!1!SUBJECTAREA_Subjectareadesc!cdata]
FROM SUBJECTAREA
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Subjectarea>'
end

if @nErrorCode = 0
begin
	select '<Subjectareatables>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
SUBJECTAREANO as [SUBJECTAREATABLES!1!SUBJECTAREATABLES_Subjectareano!element],
TABLENAME as [SUBJECTAREATABLES!1!SUBJECTAREATABLES_Tablename!element],
DEPTH as [SUBJECTAREATABLES!1!SUBJECTAREATABLES_Depth!element]
FROM SUBJECTAREATABLES
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Subjectareatables>'
end

if @nErrorCode = 0
begin
	select '<Subtype>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
SUBTYPE as [SUBTYPE!1!SUBTYPE_Subtype!cdata],
SUBTYPEDESC as [SUBTYPE!1!SUBTYPE_Subtypedesc!element]
FROM SUBTYPE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Subtype>'
end

if @nErrorCode = 0
begin
	select '<Tabcontrol>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
TABCONTROLNO as [TABCONTROL!1!TABCONTROL_Tabcontrolno!element],
WINDOWCONTROLNO as [TABCONTROL!1!TABCONTROL_Windowcontrolno!element],
TABNAME as [TABCONTROL!1!TABCONTROL_Tabname!element],
DISPLAYSEQUENCE as [TABCONTROL!1!TABCONTROL_Displaysequence!element],
TABTITLE as [TABCONTROL!1!TABCONTROL_Tabtitle!cdata],
ISINHERITED as [TABCONTROL!1!TABCONTROL_Isinherited!element]
FROM TABCONTROL
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Tabcontrol>'
end

if @nErrorCode = 0
begin
	select '<Tablecodes>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
TABLECODE as [TABLECODES!1!TABLECODES_Tablecode!element],
TABLETYPE as [TABLECODES!1!TABLECODES_Tabletype!element],
DESCRIPTION as [TABLECODES!1!TABLECODES_Description!cdata],
USERCODE as [TABLECODES!1!TABLECODES_Usercode!element],
BOOLEANFLAG as [TABLECODES!1!TABLECODES_Booleanflag!element]
FROM TABLECODES
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Tablecodes>'
end

if @nErrorCode = 0
begin
	select '<Tabletype>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
TABLETYPE as [TABLETYPE!1!TABLETYPE_Tabletype!element],
TABLENAME as [TABLETYPE!1!TABLETYPE_Tablename!element],
MODIFIABLE as [TABLETYPE!1!TABLETYPE_Modifiable!element],
ACTIVITYFLAG as [TABLETYPE!1!TABLETYPE_Activityflag!element],
DATABASETABLE as [TABLETYPE!1!TABLETYPE_Databasetable!element]
FROM TABLETYPE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Tabletype>'
end

if @nErrorCode = 0
begin
	select '<Task>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
TASKID as [TASK!1!TASK_Taskid!element],
TASKNAME as [TASK!1!TASK_Taskname!cdata],
DESCRIPTION as [TASK!1!TASK_Description!cdata],
CANIMPERSONATE as [TASK!1!TASK_Canimpersonate!element]
FROM TASK
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Task>'
end

if @nErrorCode = 0
begin
	select '<Taxratescountry>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
TAXCODE as [TAXRATESCOUNTRY!1!TAXRATESCOUNTRY_Taxcode!cdata],
COUNTRYCODE as [TAXRATESCOUNTRY!1!TAXRATESCOUNTRY_Countrycode!cdata],
RATE as [TAXRATESCOUNTRY!1!TAXRATESCOUNTRY_Rate!element],
TAXRATESCOUNTRYID as [TAXRATESCOUNTRY!1!TAXRATESCOUNTRY_Taxratescountryid!element],
STATE as [TAXRATESCOUNTRY!1!TAXRATESCOUNTRY_State!element],
HARMONISED as [TAXRATESCOUNTRY!1!TAXRATESCOUNTRY_Harmonised!element],
TAXONTAX as [TAXRATESCOUNTRY!1!TAXRATESCOUNTRY_Taxontax!element],
EFFECTIVEDATE as [TAXRATESCOUNTRY!1!TAXRATESCOUNTRY_Effectivedate!element]
FROM TAXRATESCOUNTRY
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Taxratescountry>'
end

if @nErrorCode = 0
begin
	select '<Texttype>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
TEXTTYPE as [TEXTTYPE!1!TEXTTYPE_Texttype!cdata],
TEXTDESCRIPTION as [TEXTTYPE!1!TEXTTYPE_Textdescription!element],
USEDBYFLAG as [TEXTTYPE!1!TEXTTYPE_Usedbyflag!element]
FROM TEXTTYPE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Texttype>'
end

if @nErrorCode = 0
begin
	select '<Titles>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
TITLE as [TITLES!1!TITLES_Title!element],
FULLTITLE as [TITLES!1!TITLES_Fulltitle!element],
GENDERFLAG as [TITLES!1!TITLES_Genderflag!cdata],
DEFAULTFLAG as [TITLES!1!TITLES_Defaultflag!element]
FROM TITLES
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Titles>'
end

if @nErrorCode = 0
begin
	select '<Tmclass>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
COUNTRYCODE as [TMCLASS!1!TMCLASS_Countrycode!cdata],
CLASS as [TMCLASS!1!TMCLASS_Class!element],
PROPERTYTYPE as [TMCLASS!1!TMCLASS_Propertytype!cdata],
SEQUENCENO as [TMCLASS!1!TMCLASS_Sequenceno!element],
EFFECTIVEDATE as [TMCLASS!1!TMCLASS_Effectivedate!element],
GOODSSERVICES as [TMCLASS!1!TMCLASS_Goodsservices!cdata],
INTERNATIONALCLASS as [TMCLASS!1!TMCLASS_Internationalclass!cdata],
ASSOCIATEDCLASSES as [TMCLASS!1!TMCLASS_Associatedclasses!cdata],
CLASSHEADING as [TMCLASS!1!TMCLASS_Classheading!cdata],
CLASSNOTES as [TMCLASS!1!TMCLASS_Classnotes!cdata],
SUBCLASS as [TMCLASS!1!TMCLASS_Subclass!element]
FROM TMCLASS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Tmclass>'
end

if @nErrorCode = 0
begin
	select '<Topiccontrol>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
TOPICCONTROLNO as [TOPICCONTROL!1!TOPICCONTROL_Topiccontrolno!element],
WINDOWCONTROLNO as [TOPICCONTROL!1!TOPICCONTROL_Windowcontrolno!element],
TOPICNAME as [TOPICCONTROL!1!TOPICCONTROL_Topicname!element],
TOPICSUFFIX as [TOPICCONTROL!1!TOPICCONTROL_Topicsuffix!element],
ROWPOSITION as [TOPICCONTROL!1!TOPICCONTROL_Rowposition!element],
COLPOSITION as [TOPICCONTROL!1!TOPICCONTROL_Colposition!element],
TABCONTROLNO as [TOPICCONTROL!1!TOPICCONTROL_Tabcontrolno!element],
TOPICTITLE as [TOPICCONTROL!1!TOPICCONTROL_Topictitle!cdata],
TOPICSHORTTITLE as [TOPICCONTROL!1!TOPICCONTROL_Topicshorttitle!cdata],
TOPICDESCRIPTION as [TOPICCONTROL!1!TOPICCONTROL_Topicdescription!cdata],
DISPLAYDESCRIPTION as [TOPICCONTROL!1!TOPICCONTROL_Displaydescription!element],
SCREENTIP as [TOPICCONTROL!1!TOPICCONTROL_Screentip!cdata],
ISHIDDEN as [TOPICCONTROL!1!TOPICCONTROL_Ishidden!element],
ISMANDATORY as [TOPICCONTROL!1!TOPICCONTROL_Ismandatory!element],
ISINHERITED as [TOPICCONTROL!1!TOPICCONTROL_Isinherited!element],
FILTERNAME as [TOPICCONTROL!1!TOPICCONTROL_Filtername!element],
FILTERVALUE as [TOPICCONTROL!1!TOPICCONTROL_Filtervalue!cdata]
FROM TOPICCONTROL
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Topiccontrol>'
end

if @nErrorCode = 0
begin
	select '<Topiccontrolfilter>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
TOPICCONTROLFILTERNO as [TOPICCONTROLFILTER!1!TOPICCONTROLFILTER_Topiccontrolfilterno!element],
TOPICCONTROLNO as [TOPICCONTROLFILTER!1!TOPICCONTROLFILTER_Topiccontrolno!element],
FILTERNAME as [TOPICCONTROLFILTER!1!TOPICCONTROLFILTER_Filtername!element],
FILTERVALUE as [TOPICCONTROLFILTER!1!TOPICCONTROLFILTER_Filtervalue!cdata]
FROM TOPICCONTROLFILTER
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Topiccontrolfilter>'
end

if @nErrorCode = 0
begin
	select '<Topicdataitems>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
TOPICID as [TOPICDATAITEMS!1!TOPICDATAITEMS_Topicid!element],
DATAITEMID as [TOPICDATAITEMS!1!TOPICDATAITEMS_Dataitemid!element]
FROM TOPICDATAITEMS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Topicdataitems>'
end

if @nErrorCode = 0
begin
	select '<Topicdefaultsettings>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
DEFAULTSETTINGNO as [TOPICDEFAULTSETTINGS!1!TOPICDEFAULTSETTINGS_Defaultsettingno!element],
CRITERIANO as [TOPICDEFAULTSETTINGS!1!TOPICDEFAULTSETTINGS_Criteriano!element],
NAMECRITERIANO as [TOPICDEFAULTSETTINGS!1!TOPICDEFAULTSETTINGS_Namecriteriano!element],
TOPICNAME as [TOPICDEFAULTSETTINGS!1!TOPICDEFAULTSETTINGS_Topicname!element],
FILTERNAME as [TOPICDEFAULTSETTINGS!1!TOPICDEFAULTSETTINGS_Filtername!element],
FILTERVALUE as [TOPICDEFAULTSETTINGS!1!TOPICDEFAULTSETTINGS_Filtervalue!cdata],
ISINHERITED as [TOPICDEFAULTSETTINGS!1!TOPICDEFAULTSETTINGS_Isinherited!element]
FROM TOPICDEFAULTSETTINGS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Topicdefaultsettings>'
end

if @nErrorCode = 0
begin
	select '<Topics>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
TOPICNAME as [TOPICS!1!TOPICS_Topicname!element],
TOPICTYPE as [TOPICS!1!TOPICS_Topictype!element]
FROM TOPICS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Topics>'
end

if @nErrorCode = 0
begin
	select '<Topicusage>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
TOPICNAME as [TOPICUSAGE!1!TOPICUSAGE_Topicname!element],
TOPICTITLE as [TOPICUSAGE!1!TOPICUSAGE_Topictitle!element],
TYPE as [TOPICUSAGE!1!TOPICUSAGE_Type!element]
FROM TOPICUSAGE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Topicusage>'
end

if @nErrorCode = 0
begin
	select '<Transactionreason>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
TRANSACTIONREASONNO as [TRANSACTIONREASON!1!TRANSACTIONREASON_Transactionreasonno!element],
DESCRIPTION as [TRANSACTIONREASON!1!TRANSACTIONREASON_Description!cdata],
INTERNALFLAG as [TRANSACTIONREASON!1!TRANSACTIONREASON_Internalflag!element]
FROM TRANSACTIONREASON
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Transactionreason>'
end

if @nErrorCode = 0
begin
	select '<Validactdates>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
COUNTRYCODE as [VALIDACTDATES!1!VALIDACTDATES_Countrycode!cdata],
PROPERTYTYPE as [VALIDACTDATES!1!VALIDACTDATES_Propertytype!cdata],
DATEOFACT as [VALIDACTDATES!1!VALIDACTDATES_Dateofact!element],
SEQUENCENO as [VALIDACTDATES!1!VALIDACTDATES_Sequenceno!element],
RETROSPECTIVEACTIO as [VALIDACTDATES!1!VALIDACTDATES_Retrospectiveactio!cdata],
ACTEVENTNO as [VALIDACTDATES!1!VALIDACTDATES_Acteventno!element],
RETROEVENTNO as [VALIDACTDATES!1!VALIDACTDATES_Retroeventno!element]
FROM VALIDACTDATES
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Validactdates>'
end

if @nErrorCode = 0
begin
	select '<Validaction>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
COUNTRYCODE as [VALIDACTION!1!VALIDACTION_Countrycode!cdata],
PROPERTYTYPE as [VALIDACTION!1!VALIDACTION_Propertytype!cdata],
CASETYPE as [VALIDACTION!1!VALIDACTION_Casetype!cdata],
ACTION as [VALIDACTION!1!VALIDACTION_Action!cdata],
ACTIONNAME as [VALIDACTION!1!VALIDACTION_Actionname!element],
ACTEVENTNO as [VALIDACTION!1!VALIDACTION_Acteventno!element],
RETROEVENTNO as [VALIDACTION!1!VALIDACTION_Retroeventno!element],
DISPLAYSEQUENCE as [VALIDACTION!1!VALIDACTION_Displaysequence!element]
FROM VALIDACTION
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Validaction>'
end

if @nErrorCode = 0
begin
	select '<Validatenumbers>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
VALIDATIONID as [VALIDATENUMBERS!1!VALIDATENUMBERS_Validationid!element],
COUNTRYCODE as [VALIDATENUMBERS!1!VALIDATENUMBERS_Countrycode!cdata],
PROPERTYTYPE as [VALIDATENUMBERS!1!VALIDATENUMBERS_Propertytype!cdata],
NUMBERTYPE as [VALIDATENUMBERS!1!VALIDATENUMBERS_Numbertype!cdata],
VALIDFROM as [VALIDATENUMBERS!1!VALIDATENUMBERS_Validfrom!element],
PATTERN as [VALIDATENUMBERS!1!VALIDATENUMBERS_Pattern!cdata],
WARNINGFLAG as [VALIDATENUMBERS!1!VALIDATENUMBERS_Warningflag!element],
ERRORMESSAGE as [VALIDATENUMBERS!1!VALIDATENUMBERS_Errormessage!cdata],
VALIDATINGSPID as [VALIDATENUMBERS!1!VALIDATENUMBERS_Validatingspid!element],
CASETYPE as [VALIDATENUMBERS!1!VALIDATENUMBERS_Casetype!cdata],
CASECATEGORY as [VALIDATENUMBERS!1!VALIDATENUMBERS_Casecategory!cdata],
SUBTYPE as [VALIDATENUMBERS!1!VALIDATENUMBERS_Subtype!cdata]
FROM VALIDATENUMBERS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Validatenumbers>'
end

if @nErrorCode = 0
begin
	select '<Validbasis>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
COUNTRYCODE as [VALIDBASIS!1!VALIDBASIS_Countrycode!cdata],
PROPERTYTYPE as [VALIDBASIS!1!VALIDBASIS_Propertytype!cdata],
BASIS as [VALIDBASIS!1!VALIDBASIS_Basis!cdata],
BASISDESCRIPTION as [VALIDBASIS!1!VALIDBASIS_Basisdescription!element]
FROM VALIDBASIS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Validbasis>'
end

if @nErrorCode = 0
begin
	select '<Validbasisex>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
COUNTRYCODE as [VALIDBASISEX!1!VALIDBASISEX_Countrycode!cdata],
PROPERTYTYPE as [VALIDBASISEX!1!VALIDBASISEX_Propertytype!cdata],
CASECATEGORY as [VALIDBASISEX!1!VALIDBASISEX_Casecategory!cdata],
CASETYPE as [VALIDBASISEX!1!VALIDBASISEX_Casetype!cdata],
BASIS as [VALIDBASISEX!1!VALIDBASISEX_Basis!cdata]
FROM VALIDBASISEX
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Validbasisex>'
end

if @nErrorCode = 0
begin
	select '<Validcategory>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
COUNTRYCODE as [VALIDCATEGORY!1!VALIDCATEGORY_Countrycode!cdata],
PROPERTYTYPE as [VALIDCATEGORY!1!VALIDCATEGORY_Propertytype!cdata],
CASETYPE as [VALIDCATEGORY!1!VALIDCATEGORY_Casetype!cdata],
CASECATEGORY as [VALIDCATEGORY!1!VALIDCATEGORY_Casecategory!cdata],
CASECATEGORYDESC as [VALIDCATEGORY!1!VALIDCATEGORY_Casecategorydesc!element],
PROPERTYEVENTNO as [VALIDCATEGORY!1!VALIDCATEGORY_Propertyeventno!element],
MULTICLASSPROPERTYAPP as [VALIDCATEGORY!1!VALIDCATEGORY_Multiclasspropertyapp!element]
FROM VALIDCATEGORY
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Validcategory>'
end

if @nErrorCode = 0
begin
	select '<Validchecklists>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
COUNTRYCODE as [VALIDCHECKLISTS!1!VALIDCHECKLISTS_Countrycode!cdata],
PROPERTYTYPE as [VALIDCHECKLISTS!1!VALIDCHECKLISTS_Propertytype!cdata],
CASETYPE as [VALIDCHECKLISTS!1!VALIDCHECKLISTS_Casetype!cdata],
CHECKLISTTYPE as [VALIDCHECKLISTS!1!VALIDCHECKLISTS_Checklisttype!element],
CHECKLISTDESC as [VALIDCHECKLISTS!1!VALIDCHECKLISTS_Checklistdesc!element]
FROM VALIDCHECKLISTS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Validchecklists>'
end

if @nErrorCode = 0
begin
	select '<Validexportformat>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
DOCUMENTDEFID as [VALIDEXPORTFORMAT!1!VALIDEXPORTFORMAT_Documentdefid!element],
FORMATID as [VALIDEXPORTFORMAT!1!VALIDEXPORTFORMAT_Formatid!element],
ISDEFAULT as [VALIDEXPORTFORMAT!1!VALIDEXPORTFORMAT_Isdefault!element]
FROM VALIDEXPORTFORMAT
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Validexportformat>'
end

if @nErrorCode = 0
begin
	select '<Validproperty>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
COUNTRYCODE as [VALIDPROPERTY!1!VALIDPROPERTY_Countrycode!cdata],
PROPERTYTYPE as [VALIDPROPERTY!1!VALIDPROPERTY_Propertytype!cdata],
PROPERTYNAME as [VALIDPROPERTY!1!VALIDPROPERTY_Propertyname!element],
OFFSET as [VALIDPROPERTY!1!VALIDPROPERTY_Offset!element],
CYCLEOFFSET as [VALIDPROPERTY!1!VALIDPROPERTY_Cycleoffset!element],
ANNUITYTYPE as [VALIDPROPERTY!1!VALIDPROPERTY_Annuitytype!element]
FROM VALIDPROPERTY
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Validproperty>'
end

if @nErrorCode = 0
begin
	select '<Validrelationships>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
COUNTRYCODE as [VALIDRELATIONSHIPS!1!VALIDRELATIONSHIPS_Countrycode!cdata],
PROPERTYTYPE as [VALIDRELATIONSHIPS!1!VALIDRELATIONSHIPS_Propertytype!cdata],
RELATIONSHIP as [VALIDRELATIONSHIPS!1!VALIDRELATIONSHIPS_Relationship!cdata],
RECIPRELATIONSHIP as [VALIDRELATIONSHIPS!1!VALIDRELATIONSHIPS_Reciprelationship!cdata]
FROM VALIDRELATIONSHIPS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Validrelationships>'
end

if @nErrorCode = 0
begin
	select '<Validstatus>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
COUNTRYCODE as [VALIDSTATUS!1!VALIDSTATUS_Countrycode!cdata],
PROPERTYTYPE as [VALIDSTATUS!1!VALIDSTATUS_Propertytype!cdata],
CASETYPE as [VALIDSTATUS!1!VALIDSTATUS_Casetype!cdata],
STATUSCODE as [VALIDSTATUS!1!VALIDSTATUS_Statuscode!element]
FROM VALIDSTATUS
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Validstatus>'
end

if @nErrorCode = 0
begin
	select '<Validsubtype>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
COUNTRYCODE as [VALIDSUBTYPE!1!VALIDSUBTYPE_Countrycode!cdata],
PROPERTYTYPE as [VALIDSUBTYPE!1!VALIDSUBTYPE_Propertytype!cdata],
CASETYPE as [VALIDSUBTYPE!1!VALIDSUBTYPE_Casetype!cdata],
CASECATEGORY as [VALIDSUBTYPE!1!VALIDSUBTYPE_Casecategory!cdata],
SUBTYPE as [VALIDSUBTYPE!1!VALIDSUBTYPE_Subtype!cdata],
SUBTYPEDESC as [VALIDSUBTYPE!1!VALIDSUBTYPE_Subtypedesc!element]
FROM VALIDSUBTYPE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Validsubtype>'
end

if @nErrorCode = 0
begin
	select '<Validtablecodes>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
VALIDTABLECODEID as [VALIDTABLECODES!1!VALIDTABLECODES_Validtablecodeid!element],
TABLECODE as [VALIDTABLECODES!1!VALIDTABLECODES_Tablecode!element],
VALIDTABLECODE as [VALIDTABLECODES!1!VALIDTABLECODES_Validtablecode!element],
VALIDTABLETYPE as [VALIDTABLECODES!1!VALIDTABLECODES_Validtabletype!element]
FROM VALIDTABLECODES
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Validtablecodes>'
end

if @nErrorCode = 0
begin
	select '<Windowcontrol>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
WINDOWCONTROLNO as [WINDOWCONTROL!1!WINDOWCONTROL_Windowcontrolno!element],
CRITERIANO as [WINDOWCONTROL!1!WINDOWCONTROL_Criteriano!element],
NAMECRITERIANO as [WINDOWCONTROL!1!WINDOWCONTROL_Namecriteriano!element],
WINDOWNAME as [WINDOWCONTROL!1!WINDOWCONTROL_Windowname!element],
ISEXTERNAL as [WINDOWCONTROL!1!WINDOWCONTROL_Isexternal!element],
DISPLAYSEQUENCE as [WINDOWCONTROL!1!WINDOWCONTROL_Displaysequence!element],
WINDOWTITLE as [WINDOWCONTROL!1!WINDOWCONTROL_Windowtitle!cdata],
WINDOWSHORTTITLE as [WINDOWCONTROL!1!WINDOWCONTROL_Windowshorttitle!cdata],
ENTRYNUMBER as [WINDOWCONTROL!1!WINDOWCONTROL_Entrynumber!element],
THEME as [WINDOWCONTROL!1!WINDOWCONTROL_Theme!element],
ISINHERITED as [WINDOWCONTROL!1!WINDOWCONTROL_Isinherited!element]
FROM WINDOWCONTROL
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Windowcontrol>'
end

if @nErrorCode = 0
begin
	select '<Wipattribute>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
WIPATTRIBUTE as [WIPATTRIBUTE!1!WIPATTRIBUTE_Wipattribute!element],
DESCRIPTION as [WIPATTRIBUTE!1!WIPATTRIBUTE_Description!element]
FROM WIPATTRIBUTE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Wipattribute>'
end

if @nErrorCode = 0
begin
	select '<Wipcategory>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
CATEGORYCODE as [WIPCATEGORY!1!WIPCATEGORY_Categorycode!cdata],
DESCRIPTION as [WIPCATEGORY!1!WIPCATEGORY_Description!element],
CATEGORYSORT as [WIPCATEGORY!1!WIPCATEGORY_Categorysort!element],
HISTORICALEXCHRATE as [WIPCATEGORY!1!WIPCATEGORY_Historicalexchrate!element]
FROM WIPCATEGORY
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Wipcategory>'
end

if @nErrorCode = 0
begin
	select '<Wiptemplate>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
WIPCODE as [WIPTEMPLATE!1!WIPTEMPLATE_Wipcode!element],
CASETYPE as [WIPTEMPLATE!1!WIPTEMPLATE_Casetype!cdata],
COUNTRYCODE as [WIPTEMPLATE!1!WIPTEMPLATE_Countrycode!cdata],
PROPERTYTYPE as [WIPTEMPLATE!1!WIPTEMPLATE_Propertytype!cdata],
ACTION as [WIPTEMPLATE!1!WIPTEMPLATE_Action!cdata],
WIPTYPEID as [WIPTEMPLATE!1!WIPTEMPLATE_Wiptypeid!element],
DESCRIPTION as [WIPTEMPLATE!1!WIPTEMPLATE_Description!element],
WIPATTRIBUTE as [WIPTEMPLATE!1!WIPTEMPLATE_Wipattribute!element],
CONSOLIDATE as [WIPTEMPLATE!1!WIPTEMPLATE_Consolidate!element],
TAXCODE as [WIPTEMPLATE!1!WIPTEMPLATE_Taxcode!cdata],
ENTERCREDITWIP as [WIPTEMPLATE!1!WIPTEMPLATE_Entercreditwip!element],
REINSTATEWIP as [WIPTEMPLATE!1!WIPTEMPLATE_Reinstatewip!element],
NARRATIVENO as [WIPTEMPLATE!1!WIPTEMPLATE_Narrativeno!element],
WIPCODESORT as [WIPTEMPLATE!1!WIPTEMPLATE_Wipcodesort!element],
USEDBY as [WIPTEMPLATE!1!WIPTEMPLATE_Usedby!element],
TOLERANCEPERCENT as [WIPTEMPLATE!1!WIPTEMPLATE_Tolerancepercent!element],
TOLERANCEAMT as [WIPTEMPLATE!1!WIPTEMPLATE_Toleranceamt!element],
CREDITWIPCODE as [WIPTEMPLATE!1!WIPTEMPLATE_Creditwipcode!element],
RENEWALFLAG as [WIPTEMPLATE!1!WIPTEMPLATE_Renewalflag!element],
STATETAXCODE as [WIPTEMPLATE!1!WIPTEMPLATE_Statetaxcode!cdata],
NOTINUSEFLAG as [WIPTEMPLATE!1!WIPTEMPLATE_Notinuseflag!element],
ENFORCEWIPATTRFLAG as [WIPTEMPLATE!1!WIPTEMPLATE_Enforcewipattrflag!element],
PREVENTWRITEDOWNFLAG as [WIPTEMPLATE!1!WIPTEMPLATE_Preventwritedownflag!element]
FROM WIPTEMPLATE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Wiptemplate>'
end

if @nErrorCode = 0
begin
	select '<Wiptype>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
WIPTYPEID as [WIPTYPE!1!WIPTYPE_Wiptypeid!element],
CATEGORYCODE as [WIPTYPE!1!WIPTYPE_Categorycode!cdata],
DESCRIPTION as [WIPTYPE!1!WIPTYPE_Description!element],
CONSOLIDATE as [WIPTYPE!1!WIPTYPE_Consolidate!element],
WIPTYPESORT as [WIPTYPE!1!WIPTYPE_Wiptypesort!element],
RECORDASSOCDETAILS as [WIPTYPE!1!WIPTYPE_Recordassocdetails!element],
EXCHSCHEDULEID as [WIPTYPE!1!WIPTYPE_Exchscheduleid!element],
WRITEDOWNPRIORITY as [WIPTYPE!1!WIPTYPE_Writedownpriority!element],
WRITEUPALLOWED as [WIPTYPE!1!WIPTYPE_Writeupallowed!element]
FROM WIPTYPE
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Wiptype>'
end

----------------------------------------------------------------------------------------------
-- End of generated code section

--Non generated policing request extract
if @nErrorCode = 0
begin
	select '<Policing>'
	set @sSQLString ="
SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
DATEENTERED as [POLICING!1!POLICING_Dateentered!element],
POLICINGSEQNO as [POLICING!1!POLICING_Policingseqno!element],
POLICINGNAME as [POLICING!1!POLICING_Policingname!element],
SYSGENERATEDFLAG as [POLICING!1!POLICING_Sysgeneratedflag!element],
ONHOLDFLAG as [POLICING!1!POLICING_Onholdflag!element],
IRN as [POLICING!1!POLICING_Irn!element],
PROPERTYTYPE as [POLICING!1!POLICING_Propertytype!cdata],
COUNTRYCODE as [POLICING!1!POLICING_Countrycode!cdata],
DATEOFACT as [POLICING!1!POLICING_Dateofact!element],
ACTION as [POLICING!1!POLICING_Action!cdata],
EVENTNO as [POLICING!1!POLICING_Eventno!element],
NAMETYPE as [POLICING!1!POLICING_Nametype!cdata],
NAMENO as [POLICING!1!POLICING_Nameno!element],
CASETYPE as [POLICING!1!POLICING_Casetype!cdata],
CASECATEGORY as [POLICING!1!POLICING_Casecategory!cdata],
SUBTYPE as [POLICING!1!POLICING_Subtype!cdata],
FROMDATE as [POLICING!1!POLICING_Fromdate!element],
UNTILDATE as [POLICING!1!POLICING_Untildate!element],
NOOFDAYS as [POLICING!1!POLICING_Noofdays!element],
LETTERDATE as [POLICING!1!POLICING_Letterdate!element],
CRITICALONLYFLAG as [POLICING!1!POLICING_Criticalonlyflag!element],
CRITLETTERSFLAG as [POLICING!1!POLICING_Critlettersflag!element],
CRITREMINDFLAG as [POLICING!1!POLICING_Critremindflag!element],
UPDATEFLAG as [POLICING!1!POLICING_Updateflag!element],
REMINDERFLAG as [POLICING!1!POLICING_Reminderflag!element],
ADHOCFLAG as [POLICING!1!POLICING_Adhocflag!element],
CRITERIAFLAG as [POLICING!1!POLICING_Criteriaflag!element],
DUEDATEFLAG as [POLICING!1!POLICING_Duedateflag!element],
CALCREMINDERFLAG as [POLICING!1!POLICING_Calcreminderflag!element],
EXCLUDEPROPERTY as [POLICING!1!POLICING_Excludeproperty!element],
EXCLUDECOUNTRY as [POLICING!1!POLICING_Excludecountry!element],
EXCLUDEACTION as [POLICING!1!POLICING_Excludeaction!element],
EMPLOYEENO as [POLICING!1!POLICING_Employeeno!element],
CASEID as [POLICING!1!POLICING_Caseid!element],
CRITERIANO as [POLICING!1!POLICING_Criteriano!element],
CYCLE as [POLICING!1!POLICING_Cycle!element],
TYPEOFREQUEST as [POLICING!1!POLICING_Typeofrequest!element],
COUNTRYFLAGS as [POLICING!1!POLICING_Countryflags!element],
FLAGSETON as [POLICING!1!POLICING_Flagseton!element],
SQLUSER as [POLICING!1!POLICING_Sqluser!element],
DUEDATEONLYFLAG as [POLICING!1!POLICING_Duedateonlyflag!element],
LETTERFLAG as [POLICING!1!POLICING_Letterflag!element],
BATCHNO as [POLICING!1!POLICING_Batchno!element],
IDENTITYID as [POLICING!1!POLICING_Identityid!element],
ADHOCNAMENO as [POLICING!1!POLICING_Adhocnameno!element],
ADHOCDATECREATED as [POLICING!1!POLICING_Adhocdatecreated!element],
RECALCEVENTDATE as [POLICING!1!POLICING_Recalceventdate!element],
CASEOFFICEID as [POLICING!1!POLICING_Caseofficeid!cdata],
SCHEDULEDDATETIME as [POLICING!1!POLICING_Scheduleddatetime!element],
PENDING as [POLICING!1!POLICING_Pending!element],
SPIDINPROGRESS as [POLICING!1!POLICING_Spidinprogress!element],
EMAILFLAG as [POLICING!1!POLICING_Emailflag!element],
NOTES as [POLICING!1!POLICING_Notes!element]
FROM POLICING
WHERE POLICINGNAME like (select CASE WHEN (ISNULL(COLCHARACTER, '')) = '' THEN NULL ELSE COLCHARACTER+'%' END
                         from SITECONTROL 
                         where CONTROLID = 'Copy Config Policing') 
ORDER BY TAG
FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Policing>'
end
 
RETURN @nErrorCode

go

grant execute on dbo.xml_CopyConfigExport  to public
go

