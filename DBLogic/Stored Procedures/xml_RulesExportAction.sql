-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xml_RulesExportAction
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[xml_RulesExportAction]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.xml_RulesExportAction.'
	drop procedure dbo.xml_RulesExportAction
	print '**** Creating procedure dbo.xml_RulesExportAction...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
go

CREATE PROCEDURE dbo.xml_RulesExportAction
(
				@psActions			nvarchar(500)	= '~1,~2',	-- Comma separated list of Actions whose rules will be exported.
				@pbContent	bit		= 0		-- 1 = LUS specific variations eg. including "CPA Law Update Service" SiteControl
)
AS

-- PROCEDURE :	xml_RulesExportAction
-- VERSION :	25
-- DESCRIPTION:	Extract specified data from the database 
-- 		as XML to match the LawImport.xsd 
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 27 Apr 2004	AvdA		1	Procedure created
-- 12 Jul 2004	MF		2	Restrict extraction of data to only items related to CPA Law Care rules.
-- 29 Jul 2004	MF	10225	3	Ensure all referenced Events and Actions are exported.
-- 04 Oct 2005	MF	11934	4	Ensure all referenced Actions are exported.
-- 21 Feb 2006	MF	11934	5	Revisit to correct syntax error
-- 06 Mar 2006	MF	11942	6	New columns added to VALIDPROPERTY
-- 24 Oct 2006	MF	13466	7	Export INSTRUCTIONTYPE and INSTRUCTIONLABEL
-- 06 Nov 2006	MF	13769	8	Export Relationships referred to by Data Comparison rules.
-- 21 Feb 2007	MF	14398	9	Export RECALCEVENTDATE in the EVENTS and EVENTCONTROL tables
-- 21 May 2007	MF	13936	10	Generate a datetime stamp at the time of extraction of the rules
--					which will be imported into a special SITECONTROL as a record of the
--					last rules imported.
-- 16 Aug 2007	MF	15018	11	Export TABLEATTRIBUTES associated with Country
-- 25 Mar 2008	MF	16144	12	Export EVENTNO referenced by NUMBERTYPES.RELATEDEVENTNO
-- 11 Sep 2008	MF	16899	13	Export new columns RELATEDEVENTS.CLEAREVENTONDUECHANGE and
--					CLEARDUEONDUECHANGE
-- 16 Apr 2009	MF	17472	14	Export new column COUNTRYGROUP.PREVENTNATPHASE
-- 17 Apr 2009	MF	16955	15	Export new columns on DUEDATECALC table for COMPARERELATIONSHIP,  COMPAREDATE,  COMPARESYSTEMDATE
-- 17 Apr 2009	MF	16548	16	Export new columns on CASERELATION table for FROMEVENTNO,  DISPLAYEVENTNO
-- 28 Jan 2011	MF	19371	17	Only export TABLETYPE rows that are explicitly referenced by the exported laws.
-- 25 Oct 2011	MF	20074	18	Created from xml_RulesExport to allow Action to be passed as a parameter.
-- 26 Oct 2011	AvdA	20074	19	Parameter tweak.
-- 11 Jun 2013	MF	S21404	20	New column SUPPRESSCALCULATION for EVENTS and EVENTCONTROL tables.
-- 19 May 2014	MF	R34532	21	Extract all Events with a negative EventNo rather than just those referenced by a connection to ~1 and ~2 actions.
-- 17 Jun 2015	MF	R48767	22	Extraction of VALIDACTION should be restricted to the Law Update Service Actions.  Currently any Action that has 
--					been referenced as a Retrospective Action in the VALIDACT table is also being extracted.
-- 22 Aug 2016	MF	65602	23	New columns ADJUSTAMOUNT, PERIODTYPE on the ADJUSTMENT table.
-- 03 Jan 2017	MF	70323	24	New column FULLMEMBERDATE on COUNTRYGROUP.
-- 01 May 2017	MF	71205	13	New columns added to DETAILCONTROL and EVENTCONTROL.


-----------------------------------------------------------------
-- List of the tables extracted and the basis for being extracted
-----------------------------------------------------------------
-- ACTIONS
-- Referenced by delivered law criteria
-- Referenced by ValidActDates

-- ADJUSTMENT
-- Referenced by delivered law criteria

-- APPLICATIONBASIS
-- Referenced by delivered law criteria

-- CASECATEGORY
-- Referenced by delivered law criteria

-- CASERELATION
-- Referenced by delivered law criteria

-- COUNTRY
-- All countries

-- COUNTRYFLAGS
-- All country flags

-- COUNTRYGROUP
-- All country groups

-- COUNTRYTEXT
-- All country text

-- CRITERIA
-- For the actions in parameter @psActions

-- DATESLOGIC
-- Referenced by delivered law criteria

-- DETAILCONTROL
-- Referenced by delivered law criteria

-- DETAILDATES
-- Referenced by delivered law criteria

-- DETAILLETTERS
-- Referenced by delivered law criteria

-- DUEDATECALC
-- Referenced by delivered law criteria

-- EVENTCONTROL
-- Referenced by delivered law criteria

-- EVENTS
-- That have a negative EventNo

-- INHERITS
-- Referenced by delivered law criteria

-- INSTRUCTIONLABEL
-- Referenced by delivered law criteria

-- INSTRUCTIONTYPE
-- Referenced by delivered law criteria

-- ITEM
-- All doc items

-- LETTER
-- Referenced by delivered law criteria

-- NUMBERTYPES
-- All Number Types

-- PROPERTYTYPE
-- Referenced by delivered law criteria
-- Referenced by Vlid Property

-- RELATEDEVENTS
-- Referenced by delivered law criteria

-- REMINDERS
-- Referenced by delivered law criteria

-- STATE
-- All States

-- STATUS
-- Referenced by delivered law criteria

-- SUBTYPE
-- Referenced by delivered law criteria

-- TABLEATTRIBUTES
-- Referenced by COUNTRY

-- TABLECODES
-- Referenced by delivered law criteria
-- AddressStyle, NameStyle referenced by Country
-- ValidatingSPID from ValidateNumbers
-- TextId, Language from CountryText
-- TableCode from TableAtrributes

-- TABLETYPE
-- All table type

-- TMCLASS
-- All TM Class

-- VALIDACTDATES
-- All Valid Act Dates

-- VALIDACTION
-- Referenced by delivered law criteria
-- Restrospective Action from Valid Act Dates

-- VALIDATENUMBERS
-- All Validate numbers

-- VALIDBASIS
-- All Valid basis

-- VALIDCATEGORY
-- Referenced by delivered law criteria

-- VALIDPROPERTY
-- All Valid property

-- VALIDRELATIONSHIPS
-- Referenced by delivered law criteria

-- VALIDSTATUS
-- Referenced by delivered law criteria

-- VALIDSUBTYPE
-- Referenced by delivered law criteria
-----------------------------------------------------------------

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare @nErrorCode	int
declare	@sSQLString	nvarchar(4000)

Set @nErrorCode=0

-- The Actions are to be converted to a comma
-- separated list of values wrapped in quotes
If @nErrorCode=0
Begin
	select @psActions=dbo.fn_WrapQuotes(@psActions, 1, 0)
End

if @nErrorCode = 0
begin
	select '<Actions>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	A.ACTION as [ACTIONS!1!ACTIONS_Action!element],
	A.ACTIONNAME as [ACTIONS!1!ACTIONS_Actionname!element],
	A.NUMCYCLESALLOWED as [ACTIONS!1!ACTIONS_Numcyclesallowed!element],
	A.ACTIONTYPEFLAG as [ACTIONS!1!ACTIONS_Actiontypeflag!element]
	FROM ACTIONS A
	JOIN (	SELECT ACTION
		FROM ACTIONS
		WHERE ACTION in ("+@psActions+")
		UNION
		SELECT RETROSPECTIVEACTIO
		FROM VALIDACTDATES
		WHERE RETROSPECTIVEACTIO is not null
		UNION
		SELECT EC.CLOSEACTION
		FROM CRITERIA C
		join EVENTCONTROL EC on (EC.CRITERIANO=C.CRITERIANO)
		WHERE C.ACTION in ("+@psActions+") 
		and EC.CLOSEACTION is not null
		UNION
		SELECT EC.CREATEACTION
		FROM CRITERIA C
		join EVENTCONTROL EC on (EC.CRITERIANO=C.CRITERIANO)
		WHERE C.ACTION in ("+@psActions+") 
		and EC.CREATEACTION is not null) X	on (X.ACTION=A.ACTION)
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Actions>'
end
 
if @nErrorCode = 0
begin
	select '<Adjustment>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	A.ADJUSTMENT as [ADJUSTMENT!1!ADJUSTMENT_Adjustment!element],
	A.ADJUSTMENTDESC as [ADJUSTMENT!1!ADJUSTMENT_Adjustmentdesc!element],
	A.ADJUSTDAY as [ADJUSTMENT!1!ADJUSTMENT_Adjustday!element],
	A.ADJUSTMONTH as [ADJUSTMENT!1!ADJUSTMENT_Adjustmonth!element],
	A.ADJUSTYEAR as [ADJUSTMENT!1!ADJUSTMENT_Adjustyear!element],
	A.ADJUSTAMOUNT as [ADJUSTMENT!1!ADJUSTMENT_Adjustamount!element],
	A.PERIODTYPE as [ADJUSTMENT!1!ADJUSTMENT_Periodtype!element]
	FROM ADJUSTMENT A
	JOIN (	SELECT EC.ADJUSTMENT
		FROM CRITERIA C
		JOIN EVENTCONTROL EC	on (EC.CRITERIANO=C.CRITERIANO)
		WHERE C.ACTION in ("+@psActions+")
		AND EC.ADJUSTMENT is not null
		UNION
		SELECT DD.ADJUSTMENT
		FROM CRITERIA C
		JOIN DUEDATECALC DD	on (DD.CRITERIANO=C.CRITERIANO)
		WHERE C.ACTION in ("+@psActions+")
		AND DD.ADJUSTMENT is not null ) X	on (X.ADJUSTMENT=A.ADJUSTMENT)
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Adjustment>'
end


if @nErrorCode = 0
begin
	select '<Applicationbasis>'
	set @sSQLString =
	"SELECT DISTINCT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	A.BASIS as [APPLICATIONBASIS!1!APPLICATIONBASIS_Basis!element],
	A.BASISDESCRIPTION as [APPLICATIONBASIS!1!APPLICATIONBASIS_Basisdescription!element],
	A.CONVENTION as [APPLICATIONBASIS!1!APPLICATIONBASIS_Convention!element]
	FROM CRITERIA C
	JOIN APPLICATIONBASIS A on (A.BASIS=C.BASIS)
	WHERE C.ACTION in ("+@psActions+")
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Applicationbasis>'
end

if @nErrorCode = 0
begin
	select '<Casecategory>'
	set @sSQLString =
	"SELECT DISTINCT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	CC.CASETYPE as [CASECATEGORY!1!CASECATEGORY_Casetype!element],
	CC.CASECATEGORY as [CASECATEGORY!1!CASECATEGORY_Casecategory!element],
	CC.CASECATEGORYDESC as [CASECATEGORY!1!CASECATEGORY_Casecategorydesc!element],
	CC.CONVENTIONLITERAL as [CASECATEGORY!1!CASECATEGORY_Conventionliteral!element]
	FROM CRITERIA C
	JOIN CASECATEGORY CC	on (CC.CASETYPE=C.CASETYPE
				and CC.CASECATEGORY=C.CASECATEGORY)
	WHERE C.ACTION in ("+@psActions+")
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Casecategory>'
end
if @nErrorCode = 0
begin
	select '<Caserelation>'
	set @sSQLString =
	"SELECT DISTINCT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	CR.RELATIONSHIP as [CASERELATION!1!CASERELATION_Relationship!element],
	CR.EVENTNO as [CASERELATION!1!CASERELATION_Eventno!element],
	CR.FROMEVENTNO as [CASERELATION!1!CASERELATION_Fromeventno!element],
	CR.DISPLAYEVENTNO as [CASERELATION!1!CASERELATION_Displayeventno!element],
	CR.EARLIESTDATEFLAG as [CASERELATION!1!CASERELATION_Earliestdateflag!element],
	CR.SHOWFLAG as [CASERELATION!1!CASERELATION_Showflag!element],
	CR.RELATIONSHIPDESC as [CASERELATION!1!CASERELATION_Relationshipdesc!element],
	CR.POINTERTOPARENT as [CASERELATION!1!CASERELATION_Pointertoparent!element]
	FROM CASERELATION CR
	join (	Select CR.RELATIONSHIP
		FROM CRITERIA C
		JOIN EVENTCONTROL EC	on (EC.CRITERIANO=C.CRITERIANO)
		JOIN CASERELATION CR	on (CR.RELATIONSHIP=EC.FROMRELATIONSHIP)
		WHERE C.ACTION in ("+@psActions+")
		UNION
		Select VR.RECIPRELATIONSHIP
		FROM CRITERIA C
		JOIN EVENTCONTROL EC		on (EC.CRITERIANO=C.CRITERIANO)
		JOIN VALIDRELATIONSHIPS VR	on (VR.RELATIONSHIP=EC.FROMRELATIONSHIP)
		WHERE C.ACTION in ("+@psActions+")
		and VR.RECIPRELATIONSHIP is not null
		UNION
		Select CR.RELATIONSHIP
		FROM CRITERIA C
		JOIN DUEDATECALC DD	on (DD.CRITERIANO=C.CRITERIANO)
		JOIN CASERELATION CR	on (CR.RELATIONSHIP=DD.COMPARERELATIONSHIP)
		WHERE C.ACTION in ("+@psActions+")
		UNION
		Select VR.RECIPRELATIONSHIP
		FROM CRITERIA C
		JOIN DUEDATECALC DD		on (DD.CRITERIANO=C.CRITERIANO)
		JOIN VALIDRELATIONSHIPS VR	on (VR.RELATIONSHIP=DD.COMPARERELATIONSHIP)
		WHERE C.ACTION in ("+@psActions+")
		and VR.RECIPRELATIONSHIP is not null
		UNION
		Select CR.RELATIONSHIP
		FROM CRITERIA C
		JOIN DATESLOGIC DL	on (DL.CRITERIANO=C.CRITERIANO)
		JOIN CASERELATION CR	on (CR.RELATIONSHIP=DL.CASERELATIONSHIP)
		WHERE C.ACTION in ("+@psActions+")
		UNION
		Select VR.RECIPRELATIONSHIP
		FROM CRITERIA C
		JOIN DATESLOGIC DL		on (DL.CRITERIANO=C.CRITERIANO)
		JOIN VALIDRELATIONSHIPS VR	on (VR.RELATIONSHIP=DL.CASERELATIONSHIP)
		WHERE C.ACTION in ("+@psActions+")
		and VR.RECIPRELATIONSHIP is not null) X	on (X.RELATIONSHIP=CR.RELATIONSHIP)
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Caserelation>'
end
/***************
if @nErrorCode = 0
begin
	select '<Checklistitem>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
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
	PAYFEECODE as [CHECKLISTITEM!1!CHECKLISTITEM_Payfeecode!element],
	UPDATEEVENTNO as [CHECKLISTITEM!1!CHECKLISTITEM_Updateeventno!element],
	DUEDATEFLAG as [CHECKLISTITEM!1!CHECKLISTITEM_Duedateflag!element],
	YESRATENO as [CHECKLISTITEM!1!CHECKLISTITEM_Yesrateno!element],
	NORATENO as [CHECKLISTITEM!1!CHECKLISTITEM_Norateno!element],
	YESCHECKLISTTYPE as [CHECKLISTITEM!1!CHECKLISTITEM_Yeschecklisttype!element],
	NOCHECKLISTTYPE as [CHECKLISTITEM!1!CHECKLISTITEM_Nochecklisttype!element],
	INHERITED as [CHECKLISTITEM!1!CHECKLISTITEM_Inherited!element],
	NODUEDATEFLAG as [CHECKLISTITEM!1!CHECKLISTITEM_Noduedateflag!element],
	NOEVENTNO as [CHECKLISTITEM!1!CHECKLISTITEM_Noeventno!element],
	ESTIMATEFLAG as [CHECKLISTITEM!1!CHECKLISTITEM_Estimateflag!element]
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
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
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
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
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
***************************/
if @nErrorCode = 0
begin
	select '<Country>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	CN.COUNTRYCODE as [COUNTRY!1!COUNTRY_Countrycode!element],
	CN.ALTERNATECODE as [COUNTRY!1!COUNTRY_Alternatecode!element],
	CN.COUNTRY as [COUNTRY!1!COUNTRY_Country!element],
	CN.INFORMALNAME as [COUNTRY!1!COUNTRY_Informalname!element],
	CN.COUNTRYABBREV as [COUNTRY!1!COUNTRY_Countryabbrev!element],
	CN.COUNTRYADJECTIVE as [COUNTRY!1!COUNTRY_Countryadjective!element],
	CN.RECORDTYPE as [COUNTRY!1!COUNTRY_Recordtype!element],
	CN.ISD as [COUNTRY!1!COUNTRY_Isd!element],
	CN.STATELITERAL as [COUNTRY!1!COUNTRY_Stateliteral!element],
	CN.POSTCODELITERAL as [COUNTRY!1!COUNTRY_Postcodeliteral!element],
	CN.POSTCODEFIRST as [COUNTRY!1!COUNTRY_Postcodefirst!element],
	CN.WORKDAYFLAG as [COUNTRY!1!COUNTRY_Workdayflag!element],
	CN.DATECOMMENCED as [COUNTRY!1!COUNTRY_Datecommenced!element],
	CN.DATECEASED as [COUNTRY!1!COUNTRY_Dateceased!element],
	CN.NOTES as [COUNTRY!1!COUNTRY_Notes!element],
	CN.STATEABBREVIATED as [COUNTRY!1!COUNTRY_Stateabbreviated!element],
	CN.ALLMEMBERSFLAG as [COUNTRY!1!COUNTRY_Allmembersflag!element],
	CN.NAMESTYLE as [COUNTRY!1!COUNTRY_Namestyle!element],
	CN.ADDRESSSTYLE as [COUNTRY!1!COUNTRY_Addressstyle!element],
	CN.DEFAULTTAXCODE as [COUNTRY!1!COUNTRY_Defaulttaxcode!element],
	CN.REQUIREEXEMPTTAXNO as [COUNTRY!1!COUNTRY_Requireexempttaxno!element],
	CN.DEFAULTCURRENCY as [COUNTRY!1!COUNTRY_Defaultcurrency!element],
	CN.POSTCODESEARCHCODE as [COUNTRY!1!COUNTRY_Postcodesearchcode!element],
	CN.POSTCODEAUTOFLAG as [COUNTRY!1!COUNTRY_Postcodeautoflag!element]
	FROM COUNTRY CN
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Country>'
end

if @nErrorCode = 0
begin
	select '<Countryflags>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	COUNTRYCODE as [COUNTRYFLAGS!1!COUNTRYFLAGS_Countrycode!element],
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
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	TREATYCODE as [COUNTRYGROUP!1!COUNTRYGROUP_Treatycode!element],
	MEMBERCOUNTRY as [COUNTRYGROUP!1!COUNTRYGROUP_Membercountry!element],
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
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	COUNTRYCODE as [COUNTRYTEXT!1!COUNTRYTEXT_Countrycode!element],
	TEXTID as [COUNTRYTEXT!1!COUNTRYTEXT_Textid!element],
	SEQUENCE as [COUNTRYTEXT!1!COUNTRYTEXT_Sequence!element],
	PROPERTYTYPE as [COUNTRYTEXT!1!COUNTRYTEXT_Propertytype!element],
	MODIFIEDDATE as [COUNTRYTEXT!1!COUNTRYTEXT_Modifieddate!element],
	LANGUAGE as [COUNTRYTEXT!1!COUNTRYTEXT_Language!element],
	USEFLAG as [COUNTRYTEXT!1!COUNTRYTEXT_Useflag!element],
	COUNTRYTEXT as [COUNTRYTEXT!1!COUNTRYTEXT_Countrytext!element]
	FROM COUNTRYTEXT
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Countrytext>'
end
if @nErrorCode = 0
begin
	select '<Criteria>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	CRITERIANO as [CRITERIA!1!CRITERIA_Criteriano!element],
	PURPOSECODE as [CRITERIA!1!CRITERIA_Purposecode!element],
	CASETYPE as [CRITERIA!1!CRITERIA_Casetype!element],
	ACTION as [CRITERIA!1!CRITERIA_Action!element],
	CHECKLISTTYPE as [CRITERIA!1!CRITERIA_Checklisttype!element],
	PROGRAMID as [CRITERIA!1!CRITERIA_Programid!element],
	PROPERTYTYPE as [CRITERIA!1!CRITERIA_Propertytype!element],
	PROPERTYUNKNOWN as [CRITERIA!1!CRITERIA_Propertyunknown!element],
	COUNTRYCODE as [CRITERIA!1!CRITERIA_Countrycode!element],
	COUNTRYUNKNOWN as [CRITERIA!1!CRITERIA_Countryunknown!element],
	CASECATEGORY as [CRITERIA!1!CRITERIA_Casecategory!element],
	CATEGORYUNKNOWN as [CRITERIA!1!CRITERIA_Categoryunknown!element],
	SUBTYPE as [CRITERIA!1!CRITERIA_Subtype!element],
	SUBTYPEUNKNOWN as [CRITERIA!1!CRITERIA_Subtypeunknown!element],
	BASIS as [CRITERIA!1!CRITERIA_Basis!element],
	REGISTEREDUSERS as [CRITERIA!1!CRITERIA_Registeredusers!element],
	LOCALCLIENTFLAG as [CRITERIA!1!CRITERIA_Localclientflag!element],
	TABLECODE as [CRITERIA!1!CRITERIA_Tablecode!element],
	RATENO as [CRITERIA!1!CRITERIA_Rateno!element],
	DATEOFACT as [CRITERIA!1!CRITERIA_Dateofact!element],
	USERDEFINEDRULE as [CRITERIA!1!CRITERIA_Userdefinedrule!element],
	RULEINUSE as [CRITERIA!1!CRITERIA_Ruleinuse!element],
	STARTDETAILENTRY as [CRITERIA!1!CRITERIA_Startdetailentry!element],
	PARENTCRITERIA as [CRITERIA!1!CRITERIA_Parentcriteria!element],
	BELONGSTOGROUP as [CRITERIA!1!CRITERIA_Belongstogroup!element],
	DESCRIPTION as [CRITERIA!1!CRITERIA_Description!element],
	TYPEOFMARK as [CRITERIA!1!CRITERIA_Typeofmark!element],
	RENEWALTYPE as [CRITERIA!1!CRITERIA_Renewaltype!element],
	CASEOFFICEID as [CRITERIA!1!CRITERIA_Caseofficeid!element]
	FROM CRITERIA
	WHERE ACTION in ("+@psActions+")
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Criteria>'
end
if @nErrorCode = 0
begin
	select '<Dateslogic>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	D.CRITERIANO as [DATESLOGIC!1!DATESLOGIC_Criteriano!element],
	D.EVENTNO as [DATESLOGIC!1!DATESLOGIC_Eventno!element],
	D.SEQUENCENO as [DATESLOGIC!1!DATESLOGIC_Sequenceno!element],
	D.DATETYPE as [DATESLOGIC!1!DATESLOGIC_Datetype!element],
	D.OPERATOR as [DATESLOGIC!1!DATESLOGIC_Operator!element],
	D.COMPAREEVENT as [DATESLOGIC!1!DATESLOGIC_Compareevent!element],
	D.MUSTEXIST as [DATESLOGIC!1!DATESLOGIC_Mustexist!element],
	D.RELATIVECYCLE as [DATESLOGIC!1!DATESLOGIC_Relativecycle!element],
	D.COMPAREDATETYPE as [DATESLOGIC!1!DATESLOGIC_Comparedatetype!element],
	D.CASERELATIONSHIP as [DATESLOGIC!1!DATESLOGIC_Caserelationship!element],
	D.DISPLAYERRORFLAG as [DATESLOGIC!1!DATESLOGIC_Displayerrorflag!element],
	D.ERRORMESSAGE as [DATESLOGIC!1!DATESLOGIC_Errormessage!element],
	D.INHERITED as [DATESLOGIC!1!DATESLOGIC_Inherited!element]
	FROM CRITERIA C
	JOIN DATESLOGIC D	on (D.CRITERIANO=C.CRITERIANO)
	WHERE C.ACTION in ("+@psActions+")
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Dateslogic>'
end
if @nErrorCode = 0
begin
	select '<Detailcontrol>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	D.CRITERIANO as [DETAILCONTROL!1!DETAILCONTROL_Criteriano!element],
	D.ENTRYNUMBER as [DETAILCONTROL!1!DETAILCONTROL_Entrynumber!element],
	D.ENTRYDESC as [DETAILCONTROL!1!DETAILCONTROL_Entrydesc!element],
	D.TAKEOVERFLAG as [DETAILCONTROL!1!DETAILCONTROL_Takeoverflag!element],
	D.DISPLAYSEQUENCE as [DETAILCONTROL!1!DETAILCONTROL_Displaysequence!element],
	D.STATUSCODE as [DETAILCONTROL!1!DETAILCONTROL_Statuscode!element],
	D.RENEWALSTATUS as [DETAILCONTROL!1!DETAILCONTROL_Renewalstatus!element],
	D.FILELOCATION as [DETAILCONTROL!1!DETAILCONTROL_Filelocation!element],
	D.NUMBERTYPE as [DETAILCONTROL!1!DETAILCONTROL_Numbertype!element],
	D.ATLEAST1FLAG as [DETAILCONTROL!1!DETAILCONTROL_Atleast1flag!element],
	D.USERINSTRUCTION as [DETAILCONTROL!1!DETAILCONTROL_Userinstruction!element],
	D.INHERITED as [DETAILCONTROL!1!DETAILCONTROL_Inherited!element],
	D.ENTRYCODE as [DETAILCONTROL!1!DETAILCONTROL_Entrycode!element],
	D.CHARGEGENERATION as [DETAILCONTROL!1!DETAILCONTROL_Chargegeneration!element],
	D.DISPLAYEVENTNO as [DETAILCONTROL!1!DETAILCONTROL_Displayeventno!element],
	D.HIDEEVENTNO as [DETAILCONTROL!1!DETAILCONTROL_Hideeventno!element],
	D.DIMEVENTNO as [DETAILCONTROL!1!DETAILCONTROL_Dimeventno!element],
	D.SHOWTABS as [DETAILCONTROL!1!DETAILCONTROL_Showtabs!element],
	D.SHOWMENUS as [DETAILCONTROL!1!DETAILCONTROL_Showmenus!element],
	D.SHOWTOOLBAR as [DETAILCONTROL!1!DETAILCONTROL_Showtoolbar!element],
	D.ISSEPARATOR as [DETAILCONTROL!1!DETAILCONTROL_Isseparator!element]
	FROM CRITERIA C
	JOIN DETAILCONTROL D	on (D.CRITERIANO=C.CRITERIANO)
	WHERE C.ACTION in ("+@psActions+")
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Detailcontrol>'
end
 
if @nErrorCode = 0
begin
	select '<Detaildates>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	D.CRITERIANO as [DETAILDATES!1!DETAILDATES_Criteriano!element],
	D.ENTRYNUMBER as [DETAILDATES!1!DETAILDATES_Entrynumber!element],
	D.EVENTNO as [DETAILDATES!1!DETAILDATES_Eventno!element],
	D.OTHEREVENTNO as [DETAILDATES!1!DETAILDATES_Othereventno!element],
	D.DEFAULTFLAG as [DETAILDATES!1!DETAILDATES_Defaultflag!element],
	D.EVENTATTRIBUTE as [DETAILDATES!1!DETAILDATES_Eventattribute!element],
	D.DUEATTRIBUTE as [DETAILDATES!1!DETAILDATES_Dueattribute!element],
	D.POLICINGATTRIBUTE as [DETAILDATES!1!DETAILDATES_Policingattribute!element],
	D.PERIODATTRIBUTE as [DETAILDATES!1!DETAILDATES_Periodattribute!element],
	D.OVREVENTATTRIBUTE as [DETAILDATES!1!DETAILDATES_Ovreventattribute!element],
	D.OVRDUEATTRIBUTE as [DETAILDATES!1!DETAILDATES_Ovrdueattribute!element],
	D.JOURNALATTRIBUTE as [DETAILDATES!1!DETAILDATES_Journalattribute!element],
	D.DISPLAYSEQUENCE as [DETAILDATES!1!DETAILDATES_Displaysequence!element],
	D.INHERITED as [DETAILDATES!1!DETAILDATES_Inherited!element]
	FROM CRITERIA C
	JOIN DETAILDATES D	on (D.CRITERIANO=C.CRITERIANO)
	WHERE C.ACTION in ("+@psActions+")
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Detaildates>'
end
 
if @nErrorCode = 0
begin
	select '<Detailletters>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	D.CRITERIANO as [DETAILLETTERS!1!DETAILLETTERS_Criteriano!element],
	D.ENTRYNUMBER as [DETAILLETTERS!1!DETAILLETTERS_Entrynumber!element],
	D.LETTERNO as [DETAILLETTERS!1!DETAILLETTERS_Letterno!element],
	D.MANDATORYFLAG as [DETAILLETTERS!1!DETAILLETTERS_Mandatoryflag!element],
	D.DELIVERYMETHODFLAG as [DETAILLETTERS!1!DETAILLETTERS_Deliverymethodflag!element],
	D.INHERITED as [DETAILLETTERS!1!DETAILLETTERS_Inherited!element]
	FROM CRITERIA C
	JOIN DETAILLETTERS D	on (D.CRITERIANO=C.CRITERIANO)
	WHERE C.ACTION in ("+@psActions+")
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Detailletters>'
end
if @nErrorCode = 0
begin
	select '<Duedatecalc>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	D.CRITERIANO as [DUEDATECALC!1!DUEDATECALC_Criteriano!element],
	D.EVENTNO as [DUEDATECALC!1!DUEDATECALC_Eventno!element],
	D.SEQUENCE as [DUEDATECALC!1!DUEDATECALC_Sequence!element],
	D.CYCLENUMBER as [DUEDATECALC!1!DUEDATECALC_Cyclenumber!element],
	D.COUNTRYCODE as [DUEDATECALC!1!DUEDATECALC_Countrycode!element],
	D.FROMEVENT as [DUEDATECALC!1!DUEDATECALC_Fromevent!element],
	D.RELATIVECYCLE as [DUEDATECALC!1!DUEDATECALC_Relativecycle!element],
	D.OPERATOR as [DUEDATECALC!1!DUEDATECALC_Operator!element],
	D.DEADLINEPERIOD as [DUEDATECALC!1!DUEDATECALC_Deadlineperiod!element],
	D.PERIODTYPE as [DUEDATECALC!1!DUEDATECALC_Periodtype!element],
	D.EVENTDATEFLAG as [DUEDATECALC!1!DUEDATECALC_Eventdateflag!element],
	D.ADJUSTMENT as [DUEDATECALC!1!DUEDATECALC_Adjustment!element],
	D.MUSTEXIST as [DUEDATECALC!1!DUEDATECALC_Mustexist!element],
	D.COMPARISON as [DUEDATECALC!1!DUEDATECALC_Comparison!element],
	D.COMPAREEVENT as [DUEDATECALC!1!DUEDATECALC_Compareevent!element],
	D.WORKDAY as [DUEDATECALC!1!DUEDATECALC_Workday!element],
	D.MESSAGE2FLAG as [DUEDATECALC!1!DUEDATECALC_Message2flag!element],
	D.SUPPRESSREMINDERS as [DUEDATECALC!1!DUEDATECALC_Suppressreminders!element],
	D.OVERRIDELETTER as [DUEDATECALC!1!DUEDATECALC_Overrideletter!element],
	D.INHERITED as [DUEDATECALC!1!DUEDATECALC_Inherited!element],
	D.COMPAREEVENTFLAG as [DUEDATECALC!1!DUEDATECALC_Compareeventflag!element],
	D.COMPARECYCLE as [DUEDATECALC!1!DUEDATECALC_Comparecycle!element],
	D.COMPARERELATIONSHIP as [DUEDATECALC!1!DUEDATECALC_Comparerelationship!element],
	D.COMPAREDATE as [DUEDATECALC!1!DUEDATECALC_Comparedate!element],
	D.COMPARESYSTEMDATE as [DUEDATECALC!1!DUEDATECALC_Comparesystemdate!element]
	FROM CRITERIA C
	JOIN DUEDATECALC D	on (D.CRITERIANO=C.CRITERIANO)
	WHERE C.ACTION in ("+@psActions+")
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Duedatecalc>'
end
if @nErrorCode = 0
begin
	select '<Eventcontrol>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	E.CRITERIANO as [EVENTCONTROL!1!EVENTCONTROL_Criteriano!element],
	E.EVENTNO as [EVENTCONTROL!1!EVENTCONTROL_Eventno!element],
	E.EVENTDESCRIPTION as [EVENTCONTROL!1!EVENTCONTROL_Eventdescription!element],
	E.DISPLAYSEQUENCE as [EVENTCONTROL!1!EVENTCONTROL_Displaysequence!element],
	E.PARENTCRITERIANO as [EVENTCONTROL!1!EVENTCONTROL_Parentcriteriano!element],
	E.PARENTEVENTNO as [EVENTCONTROL!1!EVENTCONTROL_Parenteventno!element],
	E.NUMCYCLESALLOWED as [EVENTCONTROL!1!EVENTCONTROL_Numcyclesallowed!element],
	E.IMPORTANCELEVEL as [EVENTCONTROL!1!EVENTCONTROL_Importancelevel!element],
	E.WHICHDUEDATE as [EVENTCONTROL!1!EVENTCONTROL_Whichduedate!element],
	E.COMPAREBOOLEAN as [EVENTCONTROL!1!EVENTCONTROL_Compareboolean!element],
	E.CHECKCOUNTRYFLAG as [EVENTCONTROL!1!EVENTCONTROL_Checkcountryflag!element],
	E.SAVEDUEDATE as [EVENTCONTROL!1!EVENTCONTROL_Saveduedate!element],
	E.STATUSCODE as [EVENTCONTROL!1!EVENTCONTROL_Statuscode!element],
	E.SPECIALFUNCTION as [EVENTCONTROL!1!EVENTCONTROL_Specialfunction!element],
	E.INITIALFEE as [EVENTCONTROL!1!EVENTCONTROL_Initialfee!element],
	E.PAYFEECODE as [EVENTCONTROL!1!EVENTCONTROL_Payfeecode!element],
	E.CREATEACTION as [EVENTCONTROL!1!EVENTCONTROL_Createaction!element],
	E.STATUSDESC as [EVENTCONTROL!1!EVENTCONTROL_Statusdesc!element],
	E.CLOSEACTION as [EVENTCONTROL!1!EVENTCONTROL_Closeaction!element],
	E.UPDATEFROMEVENT as [EVENTCONTROL!1!EVENTCONTROL_Updatefromevent!element],
	E.FROMRELATIONSHIP as [EVENTCONTROL!1!EVENTCONTROL_Fromrelationship!element],
	E.FROMANCESTOR as [EVENTCONTROL!1!EVENTCONTROL_Fromancestor!element],
	E.UPDATEMANUALLY as [EVENTCONTROL!1!EVENTCONTROL_Updatemanually!element],
	E.ADJUSTMENT as [EVENTCONTROL!1!EVENTCONTROL_Adjustment!element],
	E.DOCUMENTNO as [EVENTCONTROL!1!EVENTCONTROL_Documentno!element],
	E.NOOFDOCS as [EVENTCONTROL!1!EVENTCONTROL_Noofdocs!element],
	E.MANDATORYDOCS as [EVENTCONTROL!1!EVENTCONTROL_Mandatorydocs!element],
	E.NOTES as [EVENTCONTROL!1!EVENTCONTROL_Notes!element],
	E.INHERITED as [EVENTCONTROL!1!EVENTCONTROL_Inherited!element],
	E.INSTRUCTIONTYPE as [EVENTCONTROL!1!EVENTCONTROL_Instructiontype!element],
	E.FLAGNUMBER as [EVENTCONTROL!1!EVENTCONTROL_Flagnumber!element],
	E.SETTHIRDPARTYON as [EVENTCONTROL!1!EVENTCONTROL_Setthirdpartyon!element],
	E.RELATIVECYCLE as [EVENTCONTROL!1!EVENTCONTROL_Relativecycle!element],
	E.CREATECYCLE as [EVENTCONTROL!1!EVENTCONTROL_Createcycle!element],
	E.ESTIMATEFLAG as [EVENTCONTROL!1!EVENTCONTROL_Estimateflag!element],
	E.EXTENDPERIOD as [EVENTCONTROL!1!EVENTCONTROL_Extendperiod!element],
	E.EXTENDPERIODTYPE as [EVENTCONTROL!1!EVENTCONTROL_Extendperiodtype!element],
	E.INITIALFEE2 as [EVENTCONTROL!1!EVENTCONTROL_Initialfee2!element],
	E.PAYFEECODE2 as [EVENTCONTROL!1!EVENTCONTROL_Payfeecode2!element],
	E.ESTIMATEFLAG2 as [EVENTCONTROL!1!EVENTCONTROL_Estimateflag2!element],
	E.PTADELAY as [EVENTCONTROL!1!EVENTCONTROL_Ptadelay!element],
	E.RECALCEVENTDATE as [EVENTCONTROL!1!EVENTCONTROL_Recalceventdate!element],
	E.SUPPRESSCALCULATION as [EVENTCONTROL!1!EVENTCONTROL_Suppresscalculation!element],
	E.RENEWALSTATUS as [EVENTCONTROL!1!EVENTCONTROL_Renewalstatus!element]
	FROM CRITERIA C
	JOIN EVENTCONTROL E	on (E.CRITERIANO=C.CRITERIANO)
	WHERE C.ACTION in ("+@psActions+")
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Eventcontrol>'
end
if @nErrorCode = 0
begin
	select '<Events>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	E.EVENTNO as [EVENTS!1!EVENTS_Eventno!element],
	E.EVENTCODE as [EVENTS!1!EVENTS_Eventcode!element],
	E.EVENTDESCRIPTION as [EVENTS!1!EVENTS_Eventdescription!element],
	E.NUMCYCLESALLOWED as [EVENTS!1!EVENTS_Numcyclesallowed!element],
	E.IMPORTANCELEVEL as [EVENTS!1!EVENTS_Importancelevel!element],
	E.CONTROLLINGACTION as [EVENTS!1!EVENTS_Controllingaction!element],
	E.DEFINITION as [EVENTS!1!EVENTS_Definition!element],
	E.CLIENTIMPLEVEL as [EVENTS!1!EVENTS_Clientimplevel!element],
	E.RECALCEVENTDATE as [EVENTS!1!EVENTS_Recalceventdate!element],
	E.SUPPRESSCALCULATION as [EVENTS!1!EVENTS_Suppresscalculation!element]
	FROM EVENTS E
	WHERE E.EVENTNO<0	-- Extract where EVENTNO is negative as these are CPA delivered
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Events>'
end
if @nErrorCode = 0
begin
	select '<Inherits>'
	set @sSQLString =
	"SELECT DISTINCT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	I.CRITERIANO as [INHERITS!1!INHERITS_Criteriano!element],
	I.FROMCRITERIA as [INHERITS!1!INHERITS_Fromcriteria!element]
	FROM INHERITS I 
	JOIN CRITERIA C	on (C.CRITERIANO=I.CRITERIANO
			and C.ACTION in ("+@psActions+"))
	JOIN CRITERIA P	on (P.CRITERIANO=I.FROMCRITERIA
			and P.ACTION in ("+@psActions+"))
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Inherits>'
end
if @nErrorCode = 0
begin
	select '<InstructionLabel>'
	set @sSQLString =
	"SELECT DISTINCT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	I.INSTRUCTIONTYPE as [INSTRUCTIONLABEL!1!INSTRUCTIONLABEL_Instructiontype!element],
	I.FLAGNUMBER as [INSTRUCTIONLABEL!1!INSTRUCTIONLABEL_Flagnumber!element],
	I.FLAGLITERAL as [INSTRUCTIONLABEL!1!INSTRUCTIONLABEL_Flagliteral!element]
	FROM INSTRUCTIONLABEL I 
	JOIN EVENTCONTROL EC on (EC.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE
			     and EC.FLAGNUMBER=I.FLAGNUMBER)
	JOIN CRITERIA C	on (C.CRITERIANO=EC.CRITERIANO
			and C.ACTION in ("+@psActions+"))
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</InstructionLabel>'
end
if @nErrorCode = 0
begin
	select '<InstructionType>'
	set @sSQLString =
	"SELECT DISTINCT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	I.INSTRUCTIONTYPE as [INSTRUCTIONTYPE!1!INSTRUCTIONTYPE_Instructiontype!element],
	I.NAMETYPE as [INSTRUCTIONTYPE!1!INSTRUCTIONTYPE_Nametype!element],
	I.INSTRTYPEDESC as [INSTRUCTIONTYPE!1!INSTRUCTIONTYPE_Instrtypedesc!element],
	I.RESTRICTEDBYTYPE as [INSTRUCTIONTYPE!1!INSTRUCTIONTYPE_Restrictedbytype!element]
	FROM INSTRUCTIONTYPE I 
	JOIN EVENTCONTROL EC on (EC.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE)
	JOIN CRITERIA C	on (C.CRITERIANO=EC.CRITERIANO
			and C.ACTION in ("+@psActions+"))
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</InstructionType>'
end
if @nErrorCode = 0
begin
	select '<Item>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	ITEM_ID as [ITEM!1!ITEM_Item_id!element],
	ITEM_NAME as [ITEM!1!ITEM_Item_name!element],
	SQL_QUERY as [ITEM!1!ITEM_Sql_query!element],
	ITEM_DESCRIPTION as [ITEM!1!ITEM_Item_description!element],
	CREATED_BY as [ITEM!1!ITEM_Created_by!element],
	DATE_CREATED as [ITEM!1!ITEM_Date_created!element],
	DATE_UPDATED as [ITEM!1!ITEM_Date_updated!element],
	ITEM_TYPE as [ITEM!1!ITEM_Item_type!element],
	ENTRY_POINT_USAGE as [ITEM!1!ITEM_Entry_point_usage!element],
	SQL_DESCRIBE as [ITEM!1!ITEM_Sql_describe!element],
	SQL_INTO as [ITEM!1!ITEM_Sql_into!element]
	FROM ITEM
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Item>'
end
if @nErrorCode = 0
begin
	select '<Letter>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	L.LETTERNO as [LETTER!1!LETTER_Letterno!element],
	L.LETTERNAME as [LETTER!1!LETTER_Lettername!element],
	L.DOCUMENTCODE as [LETTER!1!LETTER_Documentcode!element],
	L.CORRESPONDTYPE as [LETTER!1!LETTER_Correspondtype!element],
	L.COPIESALLOWEDFLAG as [LETTER!1!LETTER_Copiesallowedflag!element],
	L.COVERINGLETTER as [LETTER!1!LETTER_Coveringletter!element],
	L.EXTRACOPIES as [LETTER!1!LETTER_Extracopies!element],
	L.MULTICASEFLAG as [LETTER!1!LETTER_Multicaseflag!element],
	L.MACRO as [LETTER!1!LETTER_Macro!element],
	L.SINGLECASELETTERNO as [LETTER!1!LETTER_Singlecaseletterno!element],
	L.INSTRUCTIONTYPE as [LETTER!1!LETTER_Instructiontype!element],
	L.ENVELOPE as [LETTER!1!LETTER_Envelope!element],
	L.COUNTRYCODE as [LETTER!1!LETTER_Countrycode!element],
	L.DELIVERYID as [LETTER!1!LETTER_Deliveryid!element],
	L.PROPERTYTYPE as [LETTER!1!LETTER_Propertytype!element],
	L.HOLDFLAG as [LETTER!1!LETTER_Holdflag!element],
	L.NOTES as [LETTER!1!LETTER_Notes!element],
	L.DOCUMENTTYPE as [LETTER!1!LETTER_Documenttype!element],
	L.USEDBY as [LETTER!1!LETTER_Usedby!element]
	FROM LETTER L
	JOIN (	Select R.LETTERNO as LETTERNO
		From CRITERIA C
		Join REMINDERS R	on (R.CRITERIANO=C.CRITERIANO)
		Where C.ACTION in ("+@psActions+")
		And R.LETTERNO is not null
		UNION
		Select D.LETTERNO
		From CRITERIA C
		Join DETAILLETTERS D	on (D.CRITERIANO=C.CRITERIANO)
		Where C.ACTION in ("+@psActions+")
		And D.LETTERNO is not null
		UNION
		Select L.COVERINGLETTER
		From LETTER L
		Where L.COVERINGLETTER is not null) X on (X.LETTERNO=L.LETTERNO)
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Letter>'
end
if @nErrorCode = 0
begin
	select '<Numbertypes>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	NUMBERTYPE as [NUMBERTYPES!1!NUMBERTYPES_Numbertype!element],
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
	select '<Propertytype>'
	set @sSQLString =
	"SELECT DISTINCT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	P.PROPERTYTYPE as [PROPERTYTYPE!1!PROPERTYTYPE_Propertytype!element],
	P.PROPERTYNAME as [PROPERTYTYPE!1!PROPERTYTYPE_Propertyname!element],
	P.ALLOWSUBCLASS as [PROPERTYTYPE!1!PROPERTYTYPE_Allowsubclass!element]
	FROM PROPERTYTYPE P
	JOIN (	SELECT PROPERTYTYPE
		FROM CRITERIA
		WHERE ACTION in ("+@psActions+")
		and PROPERTYTYPE is not null
		UNION
		SELECT PROPERTYTYPE
		FROM VALIDPROPERTY
		UNION
		SELECT VC.PROPERTYTYPE
		FROM CRITERIA C
		JOIN VALIDCATEGORY VC	on (VC.CASETYPE=C.CASETYPE
					and VC.CASECATEGORY=C.CASECATEGORY)
		WHERE C.ACTION in ("+@psActions+")
		UNION
		SELECT VS.PROPERTYTYPE
		FROM CRITERIA C
		JOIN VALIDSUBTYPE VS	on (VS.CASETYPE=C.CASETYPE
					and VS.CASECATEGORY=C.CASECATEGORY
					and VS.SUBTYPE=C.SUBTYPE)
		WHERE C.ACTION in ("+@psActions+"))  X on (X.PROPERTYTYPE=P.PROPERTYTYPE)
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Propertytype>'
end

/***************
if @nErrorCode = 0
begin
	select '<Question>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	QUESTIONNO as [QUESTION!1!QUESTION_Questionno!element],
	IMPORTANCELEVEL as [QUESTION!1!QUESTION_Importancelevel!element],
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
*******************/
if @nErrorCode = 0
begin
	select '<Relatedevents>'
	set @sSQLString =
	"SELECT  1 AS TAG, 0 AS PARENT,	-- set up the output structure
	R.CRITERIANO as [RELATEDEVENTS!1!RELATEDEVENTS_Criteriano!element],
	R.EVENTNO as [RELATEDEVENTS!1!RELATEDEVENTS_Eventno!element],
	R.RELATEDNO as [RELATEDEVENTS!1!RELATEDEVENTS_Relatedno!element],
	R.RELATEDEVENT as [RELATEDEVENTS!1!RELATEDEVENTS_Relatedevent!element],
	R.CLEAREVENT as [RELATEDEVENTS!1!RELATEDEVENTS_Clearevent!element],
	R.CLEARDUE as [RELATEDEVENTS!1!RELATEDEVENTS_Cleardue!element],
	R.SATISFYEVENT as [RELATEDEVENTS!1!RELATEDEVENTS_Satisfyevent!element],
	R.UPDATEEVENT as [RELATEDEVENTS!1!RELATEDEVENTS_Updateevent!element],
	R.CREATENEXTCYCLE as [RELATEDEVENTS!1!RELATEDEVENTS_Createnextcycle!element],
	R.ADJUSTMENT as [RELATEDEVENTS!1!RELATEDEVENTS_Adjustment!element],
	R.INHERITED as [RELATEDEVENTS!1!RELATEDEVENTS_Inherited!element],
	R.RELATIVECYCLE as [RELATEDEVENTS!1!RELATEDEVENTS_Relativecycle!element],
	R.CLEAREVENTONDUECHANGE as [RELATEDEVENTS!1!RELATEDEVENTS_Cleareventonduechange!element],
	R.CLEARDUEONDUECHANGE as [RELATEDEVENTS!1!RELATEDEVENTS_Cleardueonduechange!element]
	FROM CRITERIA C
	JOIN RELATEDEVENTS R	on (R.CRITERIANO=C.CRITERIANO)
	Where C.ACTION in ("+@psActions+")
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Relatedevents>'
end
if @nErrorCode = 0
begin
	select '<Reminders>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	R.CRITERIANO as [REMINDERS!1!REMINDERS_Criteriano!element],
	R.EVENTNO as [REMINDERS!1!REMINDERS_Eventno!element],
	R.REMINDERNO as [REMINDERS!1!REMINDERS_Reminderno!element],
	R.PERIODTYPE as [REMINDERS!1!REMINDERS_Periodtype!element],
	R.LEADTIME as [REMINDERS!1!REMINDERS_Leadtime!element],
	R.FREQUENCY as [REMINDERS!1!REMINDERS_Frequency!element],
	R.STOPTIME as [REMINDERS!1!REMINDERS_Stoptime!element],
	R.UPDATEEVENT as [REMINDERS!1!REMINDERS_Updateevent!element],
	R.LETTERNO as [REMINDERS!1!REMINDERS_Letterno!element],
	R.CHECKOVERRIDE as [REMINDERS!1!REMINDERS_Checkoverride!element],
	R.MAXLETTERS as [REMINDERS!1!REMINDERS_Maxletters!element],
	R.LETTERFEE as [REMINDERS!1!REMINDERS_Letterfee!element],
	R.PAYFEECODE as [REMINDERS!1!REMINDERS_Payfeecode!element],
	R.EMPLOYEEFLAG as [REMINDERS!1!REMINDERS_Employeeflag!element],
	R.SIGNATORYFLAG as [REMINDERS!1!REMINDERS_Signatoryflag!element],
	R.INSTRUCTORFLAG as [REMINDERS!1!REMINDERS_Instructorflag!element],
	R.CRITICALFLAG as [REMINDERS!1!REMINDERS_Criticalflag!element],
	R.REMINDEMPLOYEE as [REMINDERS!1!REMINDERS_Remindemployee!element],
	R.USEMESSAGE1 as [REMINDERS!1!REMINDERS_Usemessage1!element],
	R.MESSAGE1 as [REMINDERS!1!REMINDERS_Message1!element],
	R.MESSAGE2 as [REMINDERS!1!REMINDERS_Message2!element],
	R.INHERITED as [REMINDERS!1!REMINDERS_Inherited!element],
	R.EMAILSUBJECT as [REMINDERS!1!REMINDERS_Emailsubject!element],
	R.SENDELECTRONICALLY as [REMINDERS!1!REMINDERS_Sendelectronically!element],
	R.NAMETYPE as [REMINDERS!1!REMINDERS_Nametype!element],
	R.ESTIMATEFLAG as [REMINDERS!1!REMINDERS_Estimateflag!element]
	FROM CRITERIA C
	JOIN REMINDERS R	on (R.CRITERIANO=C.CRITERIANO)
	Where C.ACTION in ("+@psActions+")
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Reminders>'
end
/*************************************
if @nErrorCode = 0
begin
	select '<Screencontrol>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	CRITERIANO as [SCREENCONTROL!1!SCREENCONTROL_Criteriano!element],
	SCREENNAME as [SCREENCONTROL!1!SCREENCONTROL_Screenname!element],
	SCREENID as [SCREENCONTROL!1!SCREENCONTROL_Screenid!element],
	ENTRYNUMBER as [SCREENCONTROL!1!SCREENCONTROL_Entrynumber!element],
	SCREENTITLE as [SCREENCONTROL!1!SCREENCONTROL_Screentitle!element],
	DISPLAYSEQUENCE as [SCREENCONTROL!1!SCREENCONTROL_Displaysequence!element],
	CHECKLISTTYPE as [SCREENCONTROL!1!SCREENCONTROL_Checklisttype!element],
	TEXTTYPE as [SCREENCONTROL!1!SCREENCONTROL_Texttype!element],
	NAMETYPE as [SCREENCONTROL!1!SCREENCONTROL_Nametype!element],
	NAMEGROUP as [SCREENCONTROL!1!SCREENCONTROL_Namegroup!element],
	FLAGNUMBER as [SCREENCONTROL!1!SCREENCONTROL_Flagnumber!element],
	CREATEACTION as [SCREENCONTROL!1!SCREENCONTROL_Createaction!element],
	RELATIONSHIP as [SCREENCONTROL!1!SCREENCONTROL_Relationship!element],
	INHERITED as [SCREENCONTROL!1!SCREENCONTROL_Inherited!element],
	PROFILENAME as [SCREENCONTROL!1!SCREENCONTROL_Profilename!element],
	SCREENTIP as [SCREENCONTROL!1!SCREENCONTROL_Screentip!element],
	MANDATORYFLAG as [SCREENCONTROL!1!SCREENCONTROL_Mandatoryflag!element],
	GENERICPARAMETER as [SCREENCONTROL!1!SCREENCONTROL_Genericparameter!element]
	FROM SCREENCONTROL
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Screencontrol>'
end
***************************/
if  @nErrorCode = 0
and @pbContent=1 -- LUS
begin
	If not exists(select 1 from SITECONTROL where CONTROLID='CPA Law Update Service')
	Begin
		insert into SITECONTROL(CONTROLID, DATATYPE, COMMENTS)
		values('CPA Law Update Service','C','Indicates the date time when the CPA Law Update File was extracted by CPA')

		Set @nErrorCode=@@Error
	End

	If @nErrorCode=0
	Begin
		update SITECONTROL
		set COLCHARACTER=convert(varchar,getdate(),113)
		where CONTROLID='CPA Law Update Service'

		Set @nErrorCode=@@Error
	End

	If @nErrorCode=0
	Begin
		select '<Sitecontrol>'
		set @sSQLString =
		"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
		CONTROLID as [SITECONTROL!1!SITECONTROL_Controlid!element],
		OWNER as [SITECONTROL!1!SITECONTROL_Owner!element],
		DATATYPE as [SITECONTROL!1!SITECONTROL_Datatype!element],
		COLINTEGER as [SITECONTROL!1!SITECONTROL_Colinteger!element],
		COLCHARACTER as [SITECONTROL!1!SITECONTROL_Colcharacter!element],
		COLDECIMAL as [SITECONTROL!1!SITECONTROL_Coldecimal!element],
		COLDATE as [SITECONTROL!1!SITECONTROL_Coldate!element],
		COLBOOLEAN as [SITECONTROL!1!SITECONTROL_Colboolean!element],
		COMMENTS as [SITECONTROL!1!SITECONTROL_Comments!element]
		FROM SITECONTROL
		where CONTROLID='CPA Law Update Service'
		ORDER BY TAG
		FOR XML EXPLICIT, BINARY BASE64"

		Exec(@sSQLString)
		Set @nErrorCode=@@error
		select '</Sitecontrol>'
	End
end
if @nErrorCode = 0
begin
	select '<State>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	COUNTRYCODE as [STATE!1!STATE_Countrycode!element],
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
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	S.STATUSCODE as [STATUS!1!STATUS_Statuscode!element],
	S.DISPLAYSEQUENCE as [STATUS!1!STATUS_Displaysequence!element],
	S.USERSTATUSCODE as [STATUS!1!STATUS_Userstatuscode!element],
	S.INTERNALDESC as [STATUS!1!STATUS_Internaldesc!element],
	S.EXTERNALDESC as [STATUS!1!STATUS_Externaldesc!element],
	S.LIVEFLAG as [STATUS!1!STATUS_Liveflag!element],
	S.REGISTEREDFLAG as [STATUS!1!STATUS_Registeredflag!element],
	S.RENEWALFLAG as [STATUS!1!STATUS_Renewalflag!element],
	S.POLICERENEWALS as [STATUS!1!STATUS_Policerenewals!element],
	S.POLICEEXAM as [STATUS!1!STATUS_Policeexam!element],
	S.POLICEOTHERACTIONS as [STATUS!1!STATUS_Policeotheractions!element],
	S.LETTERSALLOWED as [STATUS!1!STATUS_Lettersallowed!element],
	S.CHARGESALLOWED as [STATUS!1!STATUS_Chargesallowed!element],
	S.REMINDERSALLOWED as [STATUS!1!STATUS_Remindersallowed!element],
	S.CONFIRMATIONREQ as [STATUS!1!STATUS_Confirmationreq!element],
	S.STOPPAYREASON as [STATUS!1!STATUS_Stoppayreason!element]
	FROM STATUS S
	JOIN (	SELECT EC.STATUSCODE
		FROM CRITERIA C
		JOIN EVENTCONTROL EC	on (EC.CRITERIANO=C.CRITERIANO)
		WHERE C.ACTION in ("+@psActions+")
		AND EC.STATUSCODE is not null
		UNION
		SELECT DC.STATUSCODE
		FROM CRITERIA C
		JOIN DETAILCONTROL DC	on (DC.CRITERIANO=C.CRITERIANO)
		WHERE C.ACTION in ("+@psActions+")
		AND DC.STATUSCODE is not null
		UNION
		SELECT DC.RENEWALSTATUS
		FROM CRITERIA C
		JOIN DETAILCONTROL DC	on (DC.CRITERIANO=C.CRITERIANO)
		WHERE C.ACTION in ("+@psActions+")
		AND DC.RENEWALSTATUS is not null) X	on (X.STATUSCODE=S.STATUSCODE)
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Status>'
end
if @nErrorCode = 0
begin
	select '<Subtype>'
	set @sSQLString =
	"SELECT DISTINCT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	S.SUBTYPE as [SUBTYPE!1!SUBTYPE_Subtype!element],
	S.SUBTYPEDESC as [SUBTYPE!1!SUBTYPE_Subtypedesc!element]
	FROM CRITERIA C
	JOIN SUBTYPE S	on (S.SUBTYPE=C.SUBTYPE)
	WHERE C.ACTION in ("+@psActions+")
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Subtype>'
end
if @nErrorCode = 0
begin
	select '<Tableattributes>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	PARENTTABLE as [TABLEATTRIBUTES!1!TABLEATTRIBUTES_Parenttable!element],                                      
	GENERICKEY as [TABLEATTRIBUTES!1!TABLEATTRIBUTES_Generickey!element],          
	TABLECODE as [TABLEATTRIBUTES!1!TABLEATTRIBUTES_Tablecode!element],
	TABLETYPE as [TABLEATTRIBUTES!1!TABLEATTRIBUTES_Tabletype!element]
	FROM TABLEATTRIBUTES
	WHERE PARENTTABLE='COUNTRY'
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Tableattributes>'
end
if @nErrorCode = 0
begin
	select '<Tablecodes>'
	set @sSQLString =
	"SELECT DISTINCT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	T.TABLECODE as [TABLECODES!1!TABLECODES_Tablecode!element],
	T.TABLETYPE as [TABLECODES!1!TABLECODES_Tabletype!element],
	T.DESCRIPTION as [TABLECODES!1!TABLECODES_Description!element],
	T.USERCODE as [TABLECODES!1!TABLECODES_Usercode!element]
	FROM TABLECODES T
	JOIN (	SELECT C.ADDRESSSTYLE as TABLECODE
		FROM COUNTRY C
		WHERE C.ADDRESSSTYLE is not null
		UNION
		SELECT C.NAMESTYLE
		FROM COUNTRY C
		WHERE C.NAMESTYLE is not null
		UNION
		SELECT C.VALIDATINGSPID
		FROM VALIDATENUMBERS C
		WHERE C.VALIDATINGSPID is not null
		UNION
		SELECT C.TABLECODE
		FROM CRITERIA C
		WHERE C.ACTION in ("+@psActions+")
		AND C.TABLECODE is not null
		UNION
		SELECT C.TEXTID
		FROM COUNTRYTEXT C
		WHERE C.TEXTID is not null
		UNION
		SELECT C.LANGUAGE
		FROM COUNTRYTEXT C
		WHERE C.LANGUAGE is not null
		UNION
		SELECT C.TABLECODE
		FROM TABLEATTRIBUTES C
		WHERE C.PARENTTABLE='COUNTRY'
		and C.TABLECODE is not null) X	on (X.TABLECODE=T.TABLECODE)
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Tablecodes>'
end
if @nErrorCode = 0
begin
	select '<Tabletype>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	T.TABLETYPE as [TABLETYPE!1!TABLETYPE_Tabletype!element],
	T.TABLENAME as [TABLETYPE!1!TABLETYPE_Tablename!element],
	T.MODIFIABLE as [TABLETYPE!1!TABLETYPE_Modifiable!element],
	T.ACTIVITYFLAG as [TABLETYPE!1!TABLETYPE_Activityflag!element],
	T.DATABASETABLE as [TABLETYPE!1!TABLETYPE_Databasetable!element]
	FROM TABLETYPE T
	JOIN (	SELECT TC.TABLETYPE
		FROM COUNTRY C
		JOIN TABLECODES TC on (TC.TABLECODE=C.ADDRESSSTYLE)
		UNION
		SELECT TC.TABLETYPE
		FROM COUNTRY C
		JOIN TABLECODES TC on (TC.TABLECODE=C.NAMESTYLE)
		UNION
		SELECT TC.TABLETYPE
		FROM VALIDATENUMBERS C
		JOIN TABLECODES TC on (TC.TABLECODE=C.VALIDATINGSPID)
		UNION
		SELECT TC.TABLETYPE
		FROM CRITERIA C
		JOIN TABLECODES TC on (TC.TABLECODE=C.TABLECODE)
		WHERE C.ACTION in ("+@psActions+")
		UNION
		SELECT TC.TABLETYPE
		FROM COUNTRYTEXT C
		JOIN TABLECODES TC on (TC.TABLECODE=C.TEXTID)
		UNION
		SELECT TC.TABLETYPE
		FROM COUNTRYTEXT C
		JOIN TABLECODES TC on (TC.TABLECODE=C.LANGUAGE)
		UNION
		SELECT TC.TABLETYPE
		FROM TABLEATTRIBUTES C
		JOIN TABLECODES TC on (TC.TABLECODE=C.TABLECODE)
		WHERE C.PARENTTABLE='COUNTRY') X on (X.TABLETYPE=T.TABLETYPE)
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Tabletype>'
end
if @nErrorCode = 0
begin
	select '<Tmclass>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	COUNTRYCODE as [TMCLASS!1!TMCLASS_Countrycode!element],
	CLASS as [TMCLASS!1!TMCLASS_Class!element],
	EFFECTIVEDATE as [TMCLASS!1!TMCLASS_Effectivedate!element],
	GOODSSERVICES as [TMCLASS!1!TMCLASS_Goodsservices!element],
	INTERNATIONALCLASS as [TMCLASS!1!TMCLASS_Internationalclass!element],
	ASSOCIATEDCLASSES as [TMCLASS!1!TMCLASS_Associatedclasses!element],
	CLASSHEADING as [TMCLASS!1!TMCLASS_Classheading!element],
	CLASSNOTES as [TMCLASS!1!TMCLASS_Classnotes!element],

	PROPERTYTYPE as [TMCLASS!1!TMCLASS_Propertytype!element],
	SEQUENCENO as [TMCLASS!1!TMCLASS_Sequenceno!element],
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
	select '<Validactdates>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	COUNTRYCODE as [VALIDACTDATES!1!VALIDACTDATES_Countrycode!element],
	PROPERTYTYPE as [VALIDACTDATES!1!VALIDACTDATES_Propertytype!element],
	DATEOFACT as [VALIDACTDATES!1!VALIDACTDATES_Dateofact!element],
	SEQUENCENO as [VALIDACTDATES!1!VALIDACTDATES_Sequenceno!element],
	RETROSPECTIVEACTIO as [VALIDACTDATES!1!VALIDACTDATES_Retrospectiveactio!element],
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
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	VA.COUNTRYCODE as [VALIDACTION!1!VALIDACTION_Countrycode!element],
	VA.PROPERTYTYPE as [VALIDACTION!1!VALIDACTION_Propertytype!element],
	VA.CASETYPE as [VALIDACTION!1!VALIDACTION_Casetype!element],
	VA.ACTION as [VALIDACTION!1!VALIDACTION_Action!element],
	VA.ACTIONNAME as [VALIDACTION!1!VALIDACTION_Actionname!element],
	VA.ACTEVENTNO as [VALIDACTION!1!VALIDACTION_Acteventno!element],
	VA.RETROEVENTNO as [VALIDACTION!1!VALIDACTION_Retroeventno!element],
	VA.DISPLAYSEQUENCE as [VALIDACTION!1!VALIDACTION_Displaysequence!element]
	FROM VALIDACTION VA
	JOIN (	SELECT ACTION
		FROM ACTIONS
		WHERE ACTION in ("+@psActions+")
		UNION
		SELECT RETROSPECTIVEACTIO
		FROM VALIDACTDATES
		WHERE RETROSPECTIVEACTIO in ("+@psActions+")) X	on (X.ACTION=VA.ACTION)
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Validaction>'
end
if @nErrorCode = 0
begin
	select '<Validatenumbers>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	VALIDATIONID as [VALIDATENUMBERS!1!VALIDATENUMBERS_Validationid!element],
	COUNTRYCODE as [VALIDATENUMBERS!1!VALIDATENUMBERS_Countrycode!element],
	PROPERTYTYPE as [VALIDATENUMBERS!1!VALIDATENUMBERS_Propertytype!element],
	NUMBERTYPE as [VALIDATENUMBERS!1!VALIDATENUMBERS_Numbertype!element],
	VALIDFROM as [VALIDATENUMBERS!1!VALIDATENUMBERS_Validfrom!element],
	PATTERN as [VALIDATENUMBERS!1!VALIDATENUMBERS_Pattern!element],
	WARNINGFLAG as [VALIDATENUMBERS!1!VALIDATENUMBERS_Warningflag!element],
	ERRORMESSAGE as [VALIDATENUMBERS!1!VALIDATENUMBERS_Errormessage!element],
	VALIDATINGSPID as [VALIDATENUMBERS!1!VALIDATENUMBERS_Validatingspid!element]
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
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	COUNTRYCODE as [VALIDBASIS!1!VALIDBASIS_Countrycode!element],
	PROPERTYTYPE as [VALIDBASIS!1!VALIDBASIS_Propertytype!element],
	BASIS as [VALIDBASIS!1!VALIDBASIS_Basis!element],
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
	select '<Validcategory>'
	set @sSQLString =
	"SELECT DISTINCT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	VC.COUNTRYCODE as [VALIDCATEGORY!1!VALIDCATEGORY_Countrycode!element],
	VC.PROPERTYTYPE as [VALIDCATEGORY!1!VALIDCATEGORY_Propertytype!element],
	VC.CASETYPE as [VALIDCATEGORY!1!VALIDCATEGORY_Casetype!element],
	VC.CASECATEGORY as [VALIDCATEGORY!1!VALIDCATEGORY_Casecategory!element],
	VC.CASECATEGORYDESC as [VALIDCATEGORY!1!VALIDCATEGORY_Casecategorydesc!element],
	VC.PROPERTYEVENTNO as [VALIDCATEGORY!1!VALIDCATEGORY_Propertyeventno!element]
	FROM CRITERIA C
	JOIN VALIDCATEGORY VC	on (VC.CASETYPE=C.CASETYPE
				and VC.CASECATEGORY=C.CASECATEGORY)
	WHERE C.ACTION in ("+@psActions+")
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Validcategory>'
end
/*****************************
if @nErrorCode = 0
begin
	select '<Validchecklists>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	COUNTRYCODE as [VALIDCHECKLISTS!1!VALIDCHECKLISTS_Countrycode!element],
	PROPERTYTYPE as [VALIDCHECKLISTS!1!VALIDCHECKLISTS_Propertytype!element],
	CASETYPE as [VALIDCHECKLISTS!1!VALIDCHECKLISTS_Casetype!element],
	CHECKLISTTYPE as [VALIDCHECKLISTS!1!VALIDCHECKLISTS_Checklisttype!element],
	CHECKLISTDESC as [VALIDCHECKLISTS!1!VALIDCHECKLISTS_Checklistdesc!element]
	FROM VALIDCHECKLISTS
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Validchecklists>'
end
*****************************/
if @nErrorCode = 0
begin
	select '<Validproperty>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	COUNTRYCODE as [VALIDPROPERTY!1!VALIDPROPERTY_Countrycode!element],
	PROPERTYTYPE as [VALIDPROPERTY!1!VALIDPROPERTY_Propertytype!element],
	PROPERTYNAME as [VALIDPROPERTY!1!VALIDPROPERTY_Propertyname!element],
	OFFSET as [VALIDPROPERTY!1!VALIDPROPERTY_Offset!element],
	CYCLEOFFSET as [VALIDPROPERTY!1!VALIDPROPERTY_CycleOffset!element],
	ANNUITYTYPE as [VALIDPROPERTY!1!VALIDPROPERTY_AnnuityType!element]
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
	set @sSQLString =
	"SELECT DISTINCT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	VR.COUNTRYCODE as [VALIDRELATIONSHIPS!1!VALIDRELATIONSHIPS_Countrycode!element],
	VR.PROPERTYTYPE as [VALIDRELATIONSHIPS!1!VALIDRELATIONSHIPS_Propertytype!element],
	VR.RELATIONSHIP as [VALIDRELATIONSHIPS!1!VALIDRELATIONSHIPS_Relationship!element],
	VR.RECIPRELATIONSHIP as [VALIDRELATIONSHIPS!1!VALIDRELATIONSHIPS_Reciprelationship!element]
	FROM VALIDRELATIONSHIPS VR
	join (	Select CR.RELATIONSHIP
		FROM CRITERIA C
		JOIN EVENTCONTROL EC	on (EC.CRITERIANO=C.CRITERIANO)
		JOIN CASERELATION CR	on (CR.RELATIONSHIP=EC.FROMRELATIONSHIP)
		WHERE C.ACTION in ("+@psActions+")
		UNION
		Select VR.RECIPRELATIONSHIP
		FROM CRITERIA C
		JOIN EVENTCONTROL EC		on (EC.CRITERIANO=C.CRITERIANO)
		JOIN VALIDRELATIONSHIPS VR	on (VR.RELATIONSHIP=EC.FROMRELATIONSHIP)
		WHERE C.ACTION in ("+@psActions+")
		and VR.RECIPRELATIONSHIP is not null
		UNION
		Select CR.RELATIONSHIP
		FROM CRITERIA C
		JOIN DUEDATECALC DD	on (DD.CRITERIANO=C.CRITERIANO)
		JOIN CASERELATION CR	on (CR.RELATIONSHIP=DD.COMPARERELATIONSHIP)
		WHERE C.ACTION in ("+@psActions+")
		UNION
		Select VR.RECIPRELATIONSHIP
		FROM CRITERIA C
		JOIN DUEDATECALC DD		on (DD.CRITERIANO=C.CRITERIANO)
		JOIN VALIDRELATIONSHIPS VR	on (VR.RELATIONSHIP=DD.COMPARERELATIONSHIP)
		WHERE C.ACTION in ("+@psActions+")
		and VR.RECIPRELATIONSHIP is not null
		UNION
		Select CR.RELATIONSHIP
		FROM CRITERIA C
		JOIN DATESLOGIC DL	on (DL.CRITERIANO=C.CRITERIANO)
		JOIN CASERELATION CR	on (CR.RELATIONSHIP=DL.CASERELATIONSHIP)
		WHERE C.ACTION in ("+@psActions+")
		UNION
		Select VR.RECIPRELATIONSHIP
		FROM CRITERIA C
		JOIN DATESLOGIC DL		on (DL.CRITERIANO=C.CRITERIANO)
		JOIN VALIDRELATIONSHIPS VR	on (VR.RELATIONSHIP=DL.CASERELATIONSHIP)
		WHERE C.ACTION in ("+@psActions+")
		and VR.RECIPRELATIONSHIP is not null) X	on (X.RELATIONSHIP=VR.RELATIONSHIP)
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Validrelationships>'
end
if @nErrorCode = 0
begin
	select '<Validstatus>'
	set @sSQLString =
	"SELECT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	VS.COUNTRYCODE as [VALIDSTATUS!1!VALIDSTATUS_Countrycode!element],
	VS.PROPERTYTYPE as [VALIDSTATUS!1!VALIDSTATUS_Propertytype!element],
	VS.CASETYPE as [VALIDSTATUS!1!VALIDSTATUS_Casetype!element],
	VS.STATUSCODE as [VALIDSTATUS!1!VALIDSTATUS_Statuscode!element]
	FROM VALIDSTATUS VS
	JOIN (	SELECT EC.STATUSCODE
		FROM CRITERIA C
		JOIN EVENTCONTROL EC	on (EC.CRITERIANO=C.CRITERIANO)
		WHERE C.ACTION in ("+@psActions+")
		AND EC.STATUSCODE is not null
		UNION
		SELECT DC.STATUSCODE
		FROM CRITERIA C
		JOIN DETAILCONTROL DC	on (DC.CRITERIANO=C.CRITERIANO)
		WHERE C.ACTION in ("+@psActions+")
		AND DC.STATUSCODE is not null
		UNION
		SELECT DC.RENEWALSTATUS
		FROM CRITERIA C
		JOIN DETAILCONTROL DC	on (DC.CRITERIANO=C.CRITERIANO)
		WHERE C.ACTION in ("+@psActions+")
		AND DC.RENEWALSTATUS is not null) X	on (X.STATUSCODE=VS.STATUSCODE)
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Validstatus>'
end
if @nErrorCode = 0
begin
	select '<Validsubtype>'
	set @sSQLString =
	"SELECT DISTINCT 1 AS TAG, 0 AS PARENT,	-- set up the output structure
	VS.COUNTRYCODE as [VALIDSUBTYPE!1!VALIDSUBTYPE_Countrycode!element],
	VS.PROPERTYTYPE as [VALIDSUBTYPE!1!VALIDSUBTYPE_Propertytype!element],
	VS.CASETYPE as [VALIDSUBTYPE!1!VALIDSUBTYPE_Casetype!element],
	VS.CASECATEGORY as [VALIDSUBTYPE!1!VALIDSUBTYPE_Casecategory!element],
	VS.SUBTYPE as [VALIDSUBTYPE!1!VALIDSUBTYPE_Subtype!element],
	VS.SUBTYPEDESC as [VALIDSUBTYPE!1!VALIDSUBTYPE_Subtypedesc!element]
	FROM CRITERIA C
	JOIN VALIDSUBTYPE VS	on (VS.CASETYPE=C.CASETYPE
				and VS.CASECATEGORY=C.CASECATEGORY
				and VS.SUBTYPE=C.SUBTYPE)
	WHERE C.ACTION in ("+@psActions+")
	ORDER BY TAG
	FOR XML EXPLICIT, BINARY BASE64"
	Exec(@sSQLString)
	Set @nErrorCode=@@error
	select '</Validsubtype>'
end
 
RETURN @nErrorCode
GO

grant execute on dbo.xml_RulesExportAction  to public
go