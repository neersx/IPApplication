-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_GenerateCEF
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ede_GenerateCEF]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ede_GenerateCEF.'
	Drop procedure [dbo].[ede_GenerateCEF]
End
Print '**** Creating Stored Procedure dbo.ede_GenerateCEF...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO 

CREATE  PROCEDURE [dbo].[ede_GenerateCEF]
		@psXMLActivityRequestRow	ntext
AS
-- PROCEDURE :	ede_GenerateCEF
-- VERSION :	52
-- DESCRIPTION:	Generate EDE CEF files in CPAXML format.
-- COPYRIGHT: 	Copyright 1993 - 2009 CPA Software Solutions (Australia) Pty Limited
--
--
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change Description
-- ------------	-------	-----	-------	----------------------------------------------- 
-- 09/05/2007	AT	12330	1	Procedure created.
-- 28/05/2007	AT	12330	2	Fixed bugs filtering of dates and returning empty result.
-- 31/05/2007	AT	12330	3	Modified elements to conform with CPA-XML standard.
-- 26/06/2007	AT	12330	4	Modified ANNUITYTERM element to cater for TMs with no Expiry Date.
-- 02/07/2007	AT	12330	5	Modified calculation of currently open renewal cycle for the case.
-- 05/07/2007	AT	12330	6	Modified TransactionSummary and ClassDescriptionDetails to return once only.
-- 03/08/2007	AT	15016	7	Changed TransactionSummary to TransactionSummaryDetails.
-- 14/02/2008	DL	15961	8	<OutputFormat> element should return TABLECODES.USERCODE instead of TABLECODES.DESCRIPTION.
-- 04/03/2008	AT	15962	9	Added FilterSummary element with from/to dates.
-- 09/04/2008	AT	16133		Correct retrieval of Sender name.
--			16138		Fix Expiry date typo.
--			16132		Fix retrieval of From date in FilterSummary.
--			16101	10	Send CaseName code from previously imported value.
-- 15/04/2008	AT	16132	11	Fix variable declaration bug.
-- 21/04/2008	DL	16268	12	Performance enhancement
--					- copy mappings from views to temp tables so that views are only recalcuated once rather then one for each case.
--					- add index to temp tables.
-- 22/04/2008	AT	16233	13	Derive Division case names.
-- 30/04/2008	AT	16101	14	Fix bug retrieving original case names.
-- 01/05/2008	AT	16338	15	Exclude draft cases.
-- 02/05/2008	AT	16343	16	Include name mappings/batches from names in the same family when deriving case names.
-- 04/06/2008	DL	16439	17	Redo 16268 as code got deleted due to merge problem.
-- 16/06/2008	AT	16537	18	Fix reported From date filter.
-- 20/06/2008	DL	16547	19	- Move fn_tokenise out of main XML extract query to enhance performance.
--					- Fix typo error 'Expiry Date'  to 'Expiry'
-- 09/07/2008	DL	16621	20	Use billing currency instead of local currency for invoices.
--			16525	20	Filename for CEF output is incorrect	
-- 17/07/2008	DL	16584	21	Include charges for reminder events
-- 22/07/2008	DL	16605	22	Handling events for transferred cases
-- 22/09/2008	DL	16923	23	Exclude blank Event date and before change image for update transaction, also fix duplicate Next Renewal Dates.
--			16935	23	Add <EventDescription> and retrieve recipient's main e-mail into <ReceiverEmail> if document request main email does not exist
-- 03/12/2008	DL	17141	24	Exclude CASEEVENT_iLOG transactions that are duedate only or none of event fields CYCLE, EVENTDATE, EVENTTEXT did not changed.
-- 08/12/2008	DL      17141	25	Include CASEEVENT transactions that have event date updated from null, e.g. event date is entered for duedate event. 
-- 11/12/2008	DL      17214	26	CEF is reporting on cases for Old Data Instructor after they cease being DI.
--					- Hide old name type that are not the recipient
--					- For transferred cases only display events with occurred date < old name commence date.
-- 11/12/2008	MF	17136	27	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 06/02/2009	AT	17348	28	Return 1 Invoice event per charge.
-- 13/02/2009	AT	17391	29	Fix return of 1 invoice event per charge to group by case.
-- 16/02/2009	AT	17391	30	Fix amounts returning in negative and amounts returning as 0.
-- 19/02/2009	DL	17416	30	If update transaction does not change either CYCLE, EVENTDATE or EVENTTEXT then exclude the transaction.
-- 27/02/2009	AT	17446	31	Updated to incorporate Belonging To names from document request.
-- 02/03/2009	AT	17448	32	Updated bill calculation to derive exch rate by case.
--					- moved class tokenisation until after cases with no events are deleted.
-- 06/03/2009	AT	17473	33	Use a temporary table to store names in recipient's family.
-- 10/03/2009	DL	17481	34	Fix bug Some events are not being reported in CEF if event date changed from null to a date.
-- 29/05/2009	mf	17748	35	Reduce locking level to ensure other activities are not blocked.
-- 01/06/2009	DL	17747	36	Fix bug - Inappropriate historic reminder events being included in CEF
-- 05/06/2009	DL	17692	37	Suprress the output report if there are no EVENTS to be reported.
-- 10/06/2009	DL	17758	38	Exclude events with event dates outside of the reporting date range.
-- 23/06/2009	DL	17758	39	Revisiting to fix a bug.
-- 24/06/2009	DL	17761	40	Provide additional event details for event Next Affidavit and Lapse Date Affidavit.  Also include new element <CreatedByAction> for events.
-- 10/07/2009	AT	17851	41	Distinguish between manual and automatic invoice events.
-- 03/09/2009	AT	17954	42	Fix bug of adding variation back onto billed amount.
-- 18/12/2009	DL	18317	43	Return NULL if derived annuityterm is not in valid range 0-255
-- 24/06/2010	AT	18827	44	Fix bug when foreign amount calculated as zero.
-- 20 Feb 2012	NML	20412	45	Change to map output caseid internal to external ID dbo.fn_InternaltoExternal
-- 26 Jun 2012	DL	20156	46	Ensure Invoice & Credit Note events cycle are based on open action
-- 09 Oct 2012	DL	20971	47	Invoice and Credit Note events not appearing correctly in CEF
-- 28 May 2013	MOS	21484	48	Added @nRecipientNameNo parameter to function call dbo.fn_InternaltoExternal
-- 03 Dec 2013	MF	21397	49	Extend the calculation of the Annuity Term to cater for the situation where we do not have the next Renewal Date
--					cycle to calculate the term from.
-- 29 Aug 2014	MF	R38902	50	Official number is incorrectly being suppressed if the data instructor is also linked to case as Old Data Instructor. Only
--					suppress Non IP Office issued numbers if the CEF recipient is an Old Data Instructor and is als not the current Data Instructor.
-- 11 Jan 2019	DL	DR-46493 51	Add Family and FamilyTitle to CaseDetails.
-- 19 May 2020	DL	DR-58943 52	Ability to enter up to 3 characters for Number type code via client server	


Set NOCOUNT ON
Set CONCAT_NULL_YIELDS_NULL OFF

Declare	
	@hDocument 		int,
	@nActivityId		int,
	@nDocRequestId		int,

	@sSQLUser		nvarchar(15),
	@nQueryFilterId 	int,
	@dtLastGenerated	datetime,
	@dtEventStart		datetime,
	@dtFromDateFilter	datetime,
	@nRowCount 		int,
	@sCaseWhere 		nvarchar(4000),
	@sTable 		nvarchar(50),

	@sReceiver 		nvarchar(30),
	@sSender		nvarchar(30),
	@sSenderName		nvarchar(30),

	@sTempCEFTable 		nvarchar(50),
	@sCaseClassTableName	nvarchar(50),

	-- variables used in header
	@sReceiverRequestId	nvarchar(100),
	@sReceiverMainEmail	nvarchar(50),
	@nRecipientNameNo	int,
	@sDestinationDirectory	nvarchar(128),
	@sFileName		nvarchar(60),
	@dCurrentDateTime	datetime,
	@sSenderRequestIdentifier nvarchar(50),
	@sSenderProducedDateTime nvarchar(25),
 	@sFromDateFilter	nvarchar(25),
	@sFileNameSP		nvarchar(60),
	@nLetterNo		int,
	@sDivisionNameTypes	nvarchar(254),
	@nRecipientFamily	int,

	@sSQLString 		nvarchar(4000),
	@sSQLString1 		nvarchar(4000),
	@sSQLString2 		nvarchar(4000),
	@sSQLString3 		nvarchar(4000),
	@sSQLString4 		nvarchar(4000),
	@sSQLString4A 		nvarchar(4000),
	@sSQLString4B 		nvarchar(4000),
	@sSQLString5 		nvarchar(4000),
	@sSQLString5A1 		nvarchar(4000),
	@sSQLString5A 		nvarchar(4000),
	@sSQLString6 		nvarchar(4000),
	@sSQLStringLast		nvarchar(4000),
	@sAlertXML		nvarchar(250),
	@nErrorCode 		int,
	@nResultExist		int,
	@sSenderReqType		nvarchar(100),
	@sBelongingToCode	nvarchar(2),
	@nNumberOfCaseEvents	int,
	@dtReportFromDate	datetime,
	@nLapseDateAffidEventNo int,
	@nNextAffidEventNo	int,
	@nExpiryEventNo		int,
	@nLapseDateEventNo	int,
	@bDebug			bit,
	@nAnnuityTerm		int



Set @nErrorCode = 0
set @bDebug = 0

-- Temp table to hold the cases applicable for the CEF
CREATE TABLE #CASESTOINCLUDE(
	ROWID			int identity(1,1),
	CASEID			int		NOT NULL,
	IRN			NVARCHAR(30)	COLLATE database_default NULL,
	PROPERTYTYPE		NVARCHAR(1)	COLLATE database_default NULL,
	RECCASEREF		NVARCHAR(80)	COLLATE database_default NULL, -- RECEIVERS CASE REF
	CASETYPE_MAP		NVARCHAR(50)	COLLATE database_default NULL,
	PROPERTYTYPE_MAP	NVARCHAR(50)	COLLATE database_default NULL,
	CASECATEGORY_MAP	NVARCHAR(50)	COLLATE database_default NULL,
	SUBTYPE_MAP		NVARCHAR(50)	COLLATE database_default NULL,
	BASIS_MAP		NVARCHAR(50)	COLLATE database_default NULL,
	COUNTRYCODE		NVARCHAR(3)	COLLATE database_default NULL,
	CYCLE			TINYINT		NULL,
	RENEWALSTART		DATETIME	NULL,
	NEXTRENEWAL		DATETIME	NULL,
	CPARENEWALDATE		DATETIME	NULL,
	NEXTRENEWALDUEDATE	DATETIME	NULL,
	ANNUITYTERM		TINYINT		NULL,
	LAPSEDATE		DATETIME	NULL,
	LAPSEDUEDATE		DATETIME	NULL,
	LAPSECYCLE		TINYINT		NULL,
	EXPIRYDATE		DATETIME	NULL,
	EXPIRYDUEDATE		DATETIME	NULL,
	EXPIRYCYCLE		TINYINT		NULL,
	TRANSFERFLAG		BIT		NULL, 	
	CASENAMECOMMENCEDATE	DATETIME	NULL,
	OLDNAMETYPE		NVARCHAR(6)	NULL,
	CASENAMENO		INT		NULL,
	AFFIDCYCLE		TINYINT		NULL,
	AFFIDANNUITYTERM	TINYINT		NULL,
	AFFIDDATE		DATETIME	NULL,
	AFFIDDUEDATE		DATETIME	NULL,
	AFFIDLAPSEDATE		DATETIME	NULL,
	AFFIDLAPSEDUEDATE	DATETIME	NULL,
	AFFIDLAPSECYCLE		TINYINT		NULL, 
	-- SQA21397 Introduced columns to be used in the 
	--	    determination of Annuity Term
	CRITERIANO		INT		NULL,	-- SQA21397
	PERIODTYPE		nchar(1)	NULL,	-- SQA21397
	INSTRUCTION		nvarchar(3)	NULL,	-- SQA21397
	PARENTCASEID		int		NULL,	-- SQA21397
	PARENTCASEFLAG		bit		NULL	-- SQA21397
	)

CREATE INDEX X1CASESTOINCLUDE ON #CASESTOINCLUDE
(
	CASEID
)

CREATE TABLE #TEMPCASES(
	CASEID			INT		NOT NULL,
	PROPERTYTYPE		NCHAR(1)	COLLATE database_default NOT NULL,
	COUNTRYCODE		NVARCHAR(3)	COLLATE database_default NOT NULL,
	INSTRUCTIONSLOADED	Bit
	)
 
CREATE TABLE #CASEEVENTS(
	ROWID			INT IDENTITY(1,1),
	CASEID			int		NOT NULL,
	EVENTNO			INT,
	EVENTCODE		NVARCHAR(10)	COLLATE database_default NULL,
	EVENTDESC		NVARCHAR(160)	COLLATE database_default NULL,
	EVENTDATE		DATETIME,
	EVENTDUEDATE		DATETIME, 
	EVENTTEXT		NVARCHAR(508)	COLLATE database_default NULL,	-- SQA16923 change from 254 char to 508
	CYCLE			TINYINT,
	CREATEDBYACTION		NVARCHAR(4),					-- SQA17761
	NEXTRENEWALEVENT	DATETIME,
	NEXTRENEWALDUEDATE	DATETIME,
	ANNUITYTERM		TINYINT,
	REMINDEREVENTFLAG	BIT,
	CHARGEDOCUMENTNUMBER	INT		NULL,					-- REMINDER CHARGE DETAILS
	CURRENCYCODE		NVARCHAR(6)	COLLATE database_default NULL,
	CHARGEAMOUNT		decimal(11, 2),
	TRANSFERFLAG		BIT,
	AFFIDEVENTDATE		DATETIME,
	AFFIDEVENTDUEDATE	DATETIME,
	ACTIONDISPLAYSEQUENCE	SMALLINT					-- SQA20971
	)


-- SQA20971 Invoices details for accounting events
CREATE TABLE #OPENITEMCASEEVENT(
	ITEMENTITYNO		INT		NULL,
	ITEMTRANSNO		INT		NULL, 
	OPENITEMNO		NVARCHAR(12)	COLLATE database_default NULL,	
	ITEMTYPE		int		NULL,
	POSTDATE		DATETIME	NULL,
	CASEID			int		NOT NULL,
	IRN			NVARCHAR(30)	COLLATE database_default NULL
	)

-- Create a temporary table to load the Standing Instructions for a Case.  Standing Instructions are determined
-- from a reasonably complex hierarchy and are used throughout Policing in a number of places so it is 
-- more efficient to calculate the specific Standing Instructions applying to Case just once.

CREATE table #TEMPCASEINSTRUCTIONS (
	CASEID			int		NOT NULL, 
	INSTRUCTIONTYPE		nvarchar(3)	collate database_default NOT NULL,
	COMPOSITECODE		nchar(33) 	collate database_default NULL,
	INSTRUCTIONCODE 	smallint	NULL,
	PERIOD1TYPE		nchar(1) 	collate database_default NULL,
	PERIOD1AMT		smallint	NULL,
	PERIOD2TYPE		nchar(1) 	collate database_default NULL,
	PERIOD2AMT		smallint	NULL,
	PERIOD3TYPE		nchar(1) 	collate database_default NULL,
	PERIOD3AMT		smallint	NULL,
	ADJUSTMENT		nvarchar(4)	collate database_default NULL,
	ADJUSTDAY		tinyint		NULL,
	ADJUSTSTARTMONTH	tinyint		NULL,
	ADJUSTDAYOFWEEK		tinyint		NULL,
	ADJUSTTODATE		datetime	NULL
)

CREATE CLUSTERED INDEX XPKTEMPCASEINSTRUCTIONS ON #TEMPCASEINSTRUCTIONS
(
	CASEID,
	INSTRUCTIONTYPE
)

-- Temp tables to copy data mappings from views.
-- The report query will use these tables instead of the views to enhance performance 
-- as the views are regenerated each time they are accessed. 
CREATE TABLE #BASIS_VIEW(	BASIS_INPRO		NVARCHAR(2)	collate database_default, 
				BASIS_CPAXML		NVARCHAR(50)	collate database_default)
				
CREATE TABLE #CASECATEGORY_VIEW(CASECATEGORY_INPRO	NVARCHAR(2)	collate database_default, 
				CASECATEGORY_CPAXML	NVARCHAR(50)	collate database_default)
				
CREATE TABLE #CASETYPE_VIEW(	CASETYPE_INPRO		NCHAR(1)	collate database_default, 
				CASETYPE_CPAXML		NVARCHAR(50)	collate database_default)
				
CREATE TABLE #EVENT_VIEW(	EVENT_INPRO		INT, 
				EVENT_CPAXML		NVARCHAR(50)	collate database_default)
				
CREATE INDEX X1EVENT_VIEW ON #EVENT_VIEW(EVENT_INPRO)
CREATE INDEX X2EVENT_VIEW ON #EVENT_VIEW(EVENT_CPAXML)

CREATE TABLE #NAMETYPE_VIEW(	NAMETYPE_INPRO		NVARCHAR(3)	collate database_default, 
				NAMETYPE_CPAXML		NVARCHAR(50)	collate database_default)
				
CREATE TABLE #NUMBERTYPE_VIEW(	NUMBERTYPE_INPRO	NVARCHAR(3)	collate database_default, 
				NUMBERTYPE_CPAXML	NVARCHAR(50)	collate database_default)
				
CREATE TABLE #PROPERTYTYPE_VIEW(PROPERTYTYPE_INPRO	NCHAR(1)	collate database_default, 
				PROPERTYTYPE_CPAXML	NVARCHAR(50)	collate database_default)
				
CREATE TABLE #SUBTYPE_VIEW(	SUBTYPE_INPRO		NVARCHAR(2)	collate database_default, 
				SUBTYPE_CPAXML		NVARCHAR(50)	collate database_default)
				
CREATE TABLE #DivisionNameTypes(Parameter		NVARCHAR(255)	collate database_default)

CREATE TABLE #NAMESTOINCLUDE(	NAMENO			INT)

CREATE INDEX X1NAMESTOINCLUDE ON #NAMESTOINCLUDE(NAMENO)

CREATE TABLE #NAMESINFAMILY(	NAMENO			INT)

CREATE INDEX X1NAMESINFAMILY ON #NAMESINFAMILY(NAMENO)

-- SQA17748 Reduce the locking level to avoid blocking other processes
set transaction isolation level read uncommitted

-- Temp table to hold tokenised CASES.LOCALCLASSES and CASES.LOCALCLASSES, which are commas delimited,
-- for affected cases to be reported.  
-- Note: This must be a distinct global temp table as table name is passed to another 
-- stored procedure to tokenise the classes.
If @nErrorCode = 0
Begin
	-- Generate a unique table name from the newid() 
	Set @sSQLString="Select @sCaseClassTableName = '##' + replace(newid(),'-','_')"
	exec @nErrorCode=sp_executesql @sSQLString,
		N'@sCaseClassTableName nvarchar(100) OUTPUT',
		@sCaseClassTableName = @sCaseClassTableName OUTPUT

	-- and create the table	
	If @nErrorCode = 0
	Begin
		Set @sSQLString="
		Create table " + @sCaseClassTableName +" (
					CASEID						int,
					CLASSTYPE					nvarchar(3) collate database_default,
					CLASS							nvarchar(250) collate database_default,
					SEQUENCENO					int
					)"
		Exec @nErrorCode=sp_executesql @sSQLString
	End
End

-----------------------------------------------------------------------------------------------------------------------------
-- Only allow stored procedure run if the data base version is >=9 (SQL Server 2005 or later)
-----------------------------------------------------------------------------------------------------------------------------
If  (Select left( cast(SERVERPROPERTY('ProductVersion') as varchar), CHARINDEX('.', CAST(SERVERPROPERTY('ProductVersion') as varchar))-1)   ) <= 8
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML("ed2", "This document can only be generated for databases on SQL Server 2005 or later.", null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = 1
End

-- Create a temp table to hold XML data for each transaction in a batch.
-- This table will allow the XML be sorted in the transaction order as stored in the batch
If @nErrorCode = 0	
Begin
	-- Generate a unique table name from the newid() 
	set @sTempCEFTable = '##' + replace(newid(),'-','_')

	If @nErrorCode = 0	
	Begin
		Set @sSQLString="
			CREATE TABLE "+ @sTempCEFTable +" (
				ROWID			int,
				XMLSTR			XML
				)"
		exec @nErrorCode=sp_executesql @sSQLString
	End
End

-- Collect the key for the Activity Request row that has been passed as an XML parameter using OPENXML functionality.
If @nErrorCode = 0
Begin	
	Exec 	sp_xml_preparedocument  @hDocument OUTPUT, @psXMLActivityRequestRow
	Set 	@nErrorCode = @@Error
End

-- Now select the key from the xml, at the same time joining it to the ACTIVITYREQUEST table.
If @nErrorCode = 0
Begin
	Set @sSQLString="
		Select	@nActivityId = ACTIVITYID,
				@nDocRequestId = REQUESTID,
				@sSQLUser = SQLUSER,
				@nLetterNo = LETTERNO
		from openxml(@hDocument,'ACTIVITYREQUEST',2)
		with (ACTIVITYID int,
				REQUESTID int,
				SQLUSER nvarchar(15),
				LETTERNO int)"

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'	@nActivityId	int		OUTPUT,
			@nDocRequestId	int		OUTPUT,
			@sSQLUser	nvarchar(15) 	OUTPUT,
			@nLetterNo	int		OUTPUT,
			@hDocument	int',
			@nActivityId	= @nActivityId	OUTPUT,
			@nDocRequestId	= @nDocRequestId OUTPUT,
			@sSQLUser	= @sSQLUser 	OUTPUT,
			@nLetterNo	= @nLetterNo	OUTPUT,
		  	@hDocument 	= @hDocument
End

If @nErrorCode = 0	
Begin	
	Exec sp_xml_removedocument @hDocument 
	Set @nErrorCode	  = @@Error
End

If (@nErrorCode = 0) and (@nDocRequestId is null)
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML("ed3", "This document is not associated with a Document Request.", null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = 1
End

-- Get required elements from the Document Request
If @nErrorCode = 0
	Begin
		Set @sSQLString="
			Select	@sReceiverRequestId = D.DESCRIPTION,
				@nRecipientNameNo = D.RECIPIENT,
				@sReceiverMainEmail = ISNULL(DE.EMAIL, T.TELECOMNUMBER),
				@nQueryFilterId = CASEFILTERID,
				@dtLastGenerated = Case when LASTGENERATED IS NULL then '1753-01-01' else LASTGENERATED end,
				@dtEventStart = Case when D.EVENTSTART IS NULL then '1753-01-01' else D.EVENTSTART end,
				@sSenderReqType = DD.SENDERREQUESTTYPE,
				@sBelongingToCode = D.BELONGINGTOCODE
			From DOCUMENTREQUEST D
			join DOCUMENTDEFINITION DD on (DD.DOCUMENTDEFID = D.DOCUMENTDEFID)
			LEFT join DOCUMENTREQUESTEMAIL DE ON (DE.REQUESTID = D.REQUESTID AND DE.ISMAIN = 1)
			JOIN NAME N ON (N.NAMENO = D.RECIPIENT)
			LEFT JOIN TELECOMMUNICATION T ON (T.TELECODE = N.MAINEMAIL)
			Where D.REQUESTID = @nDocRequestId"

		Exec @nErrorCode = sp_executesql @sSQLString,
			N'@sReceiverRequestId nvarchar(100) OUTPUT,
			@nRecipientNameNo int OUTPUT,
			@sReceiverMainEmail nvarchar(50) OUTPUT,
			@nQueryFilterId int OUTPUT,
			@dtLastGenerated datetime OUTPUT,
			@dtEventStart datetime OUTPUT,
			@sSenderReqType nvarchar(100) OUTPUT,
			@sBelongingToCode nvarchar(2) OUTPUT,
			@nDocRequestId int',
			@sReceiverRequestId	= @sReceiverRequestId OUTPUT,
			@nRecipientNameNo	= @nRecipientNameNo OUTPUT,
			@sReceiverMainEmail	= @sReceiverMainEmail OUTPUT,
			@nQueryFilterId		= @nQueryFilterId OUTPUT,
			@dtLastGenerated	= @dtLastGenerated OUTPUT,
			@dtEventStart		= @dtEventStart OUTPUT,
			@sSenderReqType		= @sSenderReqType OUTPUT,
			@sBelongingToCode	= @sBelongingToCode OUTPUT,
			@nDocRequestId		= @nDocRequestId
	End

-- derive the from date
If (@dtEventStart > @dtLastGenerated)
	Set @dtFromDateFilter = @dtEventStart
else
	Set @dtFromDateFilter = @dtLastGenerated


-- 17758 Determine whether old events should be excluded
-- Set from date to a very old date to ensure all events will be included if site control is off
If exists(Select 1 from SITECONTROL where CONTROLID = 'CEF Exclude Old Events' and COLBOOLEAN = 1)
	select @dtReportFromDate = dbo.fn_DateOnly(@dtFromDateFilter)
Else
	Set @dtReportFromDate = '1753-01-01'


-- Get Sender's alias
If @nErrorCode = 0
Begin
	Set @sSQLString="
		Select @sSender = NA.ALIAS,
			@sSenderName = N.NAME
			From NAMEALIAS NA JOIN NAME N ON (N.NAMENO = NA.NAMENO)
			Where NA.ALIASTYPE = '_H'
			And NA.NAMENO = (select SC.COLINTEGER 
					from SITECONTROL SC
					where SC.CONTROLID = 'HOMENAMENO')"

	Exec @nErrorCode = sp_executesql @sSQLString,
					N'@sSender nvarchar(30) OUTPUT,
					@sSenderName nvarchar(30) OUTPUT',
					@sSender =@sSender OUTPUT,
					@sSenderName = @sSenderName OUTPUT
End

-- Get Receiver's alias
If @nErrorCode = 0
Begin
	Set @sSQLString="
		Select @sReceiver = ISNULL(NA.ALIAS, N.NAMECODE),
			@nRecipientFamily = N.FAMILYNO
		From NAME N
		LEFT JOIN NAMEALIAS NA ON (NA.NAMENO = N.NAMENO AND NA.ALIASTYPE = '_E')
		Where N.NAMENO = @nRecipientNameNo"

	Exec @nErrorCode = sp_executesql @sSQLString,
					N'@sReceiver nvarchar(30) OUTPUT,
						@nRecipientFamily int OUTPUT,
						@nRecipientNameNo int',
					@sReceiver 		= @sReceiver OUTPUT,
					@nRecipientFamily 	= @nRecipientFamily OUTPUT,
					@nRecipientNameNo	= @nRecipientNameNo
End

-- populate #NAMESINFAMILY with the names in the recipient's family.
If @nErrorCode = 0 and @nRecipientFamily is not null
Begin
	Set @sSQLString = "
		insert into #NAMESINFAMILY
		select NAMENO from NAME
		Where FAMILYNO = @nRecipientFamily"

	Exec @nErrorCode = sp_executesql @sSQLString,
				N'@nRecipientFamily int',
				@nRecipientFamily = @nRecipientFamily
End


-- Get the appropriate belonging to names
If @nErrorCode = 0
Begin
	Set @sSQLString = "INSERT INTO #NAMESTOINCLUDE(NAMENO)"

	If @sBelongingToCode = 'RG'
	Begin
		Set @sSQLString = @sSQLString +char(10)+
			"select NAMENO
			from #NAMESINFAMILY"
	End
	Else If @sBelongingToCode = 'RA'
	Begin
		Set @sSQLString = @sSQLString +char(10)+
			"SELECT AAN.NAMENO 
			FROM ACCESSACCOUNTNAMES AAN
			JOIN ACCESSACCOUNTNAMES AAN1 on (AAN1.ACCOUNTID = AAN.ACCOUNTID)
			WHERE AAN1.NAMENO = @nRecipientNameNo"
	End
	Else
	Begin
		Set @sSQLString = @sSQLString +char(10)+ "values(@nRecipientNameNo)"
	End

	Exec @nErrorCode = sp_executesql @sSQLString,
				N'@nRecipientNameNo int',
				@nRecipientNameNo = @nRecipientNameNo

	-- Ensure at least the Recipient is included.
	If not exists (select * from #NAMESTOINCLUDE)
	Begin
	    Set @sSQLString = "INSERT INTO #NAMESTOINCLUDE(NAMENO)
				values(@nRecipientNameNo)"

	    Exec @nErrorCode = sp_executesql @sSQLString,
			N'@nRecipientNameNo int',
			@nRecipientNameNo = @nRecipientNameNo
	End
End

-- Get the Division name types
If @nErrorCode = 0
Begin
	Set @sSQLString = "Select @sDivisionNameTypes = COLCHARACTER
			FROM SITECONTROL WHERE CONTROLID = 'Division Name Types'"

	Exec @nErrorCode = sp_executesql @sSQLString,
				N'@sDivisionNameTypes nvarchar(254) OUTPUT',
				@sDivisionNameTypes=@sDivisionNameTypes OUTPUT

	If @nErrorCode = 0
	Begin	
		Set @sSQLString = "insert into #DivisionNameTypes (Parameter)
		select Parameter from fn_Tokenise( @sDivisionNameTypes, null)" 

		Exec @nErrorCode=sp_executesql @sSQLString,
			N'@sDivisionNameTypes	nvarchar(254)',
			  @sDivisionNameTypes	= @sDivisionNameTypes 
	End

End


-- Check that the sender and receiver aliases have been filled in.
If (@nErrorCode = 0) and (@sSender = '' or @sSender is null)
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML("ed4", "There is no valid Sender alias against the recipient. Please set up Alias of type _H for the sender, {0} against the receiver, {1}.", @sSenderName, @sReceiver, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = 1
End

-- Get the CASE Where clause
If @nErrorCode = 0
Begin
	exec @nErrorCode = csw_FilterCases @nRowCount OUTPUT, @sCaseWhere OUTPUT, @sTable OUTPUT, null, null, 0, null, 0, @nQueryFilterId
End


-- copy mapping data from views to temp tables
If @nErrorCode = 0	
Begin
	Set @sSQLString="Insert into #BASIS_VIEW (BASIS_INPRO, BASIS_CPAXML)
	select BASIS_INPRO, BASIS_CPAXML from BASIS_VIEW"
	exec @nErrorCode=sp_executesql @sSQLString
	If @nErrorCode = 0	
	Begin
		Set @sSQLString="Insert into #CASECATEGORY_VIEW (CASECATEGORY_INPRO, CASECATEGORY_CPAXML)
		select CASECATEGORY_INPRO, CASECATEGORY_CPAXML from CASECATEGORY_VIEW"
		exec @nErrorCode=sp_executesql @sSQLString
	End
	If @nErrorCode = 0	
	Begin
		Set @sSQLString="Insert into #CASETYPE_VIEW (CASETYPE_INPRO, CASETYPE_CPAXML)
			select CASETYPE_INPRO, CASETYPE_CPAXML from CASETYPE_VIEW"
		exec @nErrorCode=sp_executesql @sSQLString
	End
	If @nErrorCode = 0	
	Begin
		-- get all events with mapping in view EVENT_VIEW.		
		Set @sSQLString="Insert into #EVENT_VIEW(EVENT_INPRO, EVENT_CPAXML) 
			select EVENT_INPRO, EVENT_CPAXML 
			from EVENT_VIEW E 
			where  EVENT_CPAXML is not null"
		exec @nErrorCode=sp_executesql @sSQLString
	End
	If @nErrorCode = 0	
	Begin
		Set @sSQLString="Insert into #NAMETYPE_VIEW (NAMETYPE_INPRO, NAMETYPE_CPAXML)
		select NAMETYPE_INPRO, NAMETYPE_CPAXML from NAMETYPE_VIEW"
		exec @nErrorCode=sp_executesql @sSQLString
	End
	If @nErrorCode = 0	
	Begin
		Set @sSQLString="Insert into #NUMBERTYPE_VIEW (NUMBERTYPE_INPRO, NUMBERTYPE_CPAXML)
		select NUMBERTYPE_INPRO, NUMBERTYPE_CPAXML from NUMBERTYPE_VIEW"
		exec @nErrorCode=sp_executesql @sSQLString
	End
	If @nErrorCode = 0	
	Begin
		Set @sSQLString="Insert into #PROPERTYTYPE_VIEW (PROPERTYTYPE_INPRO, PROPERTYTYPE_CPAXML)
		select PROPERTYTYPE_INPRO, PROPERTYTYPE_CPAXML from PROPERTYTYPE_VIEW"
		exec @nErrorCode=sp_executesql @sSQLString
	End

	If @nErrorCode = 0	
	Begin
		Set @sSQLString="Insert into #SUBTYPE_VIEW (SUBTYPE_INPRO, SUBTYPE_CPAXML)
		select SUBTYPE_INPRO, SUBTYPE_CPAXML from SUBTYPE_VIEW"
		exec @nErrorCode=sp_executesql @sSQLString
	End
End


-- SQA17761 Get event number for event Lapse Date Affidavit
If @nErrorCode=0
Begin 
	Select @nLapseDateAffidEventNo = EVENT_INPRO 
	from #EVENT_VIEW 
	where upper(EVENT_CPAXML) = 'LAPSE DATE AFFIDAVIT'
	Set @nErrorCode= @@ERROR
End

-- SQA17761 Get event number for event Next Affidavit
If @nErrorCode=0
Begin 
	Select @nNextAffidEventNo = EVENT_INPRO 
	from #EVENT_VIEW 
	where UPPER(EVENT_CPAXML) = 'NEXT AFFIDAVIT OR INTENT TO USE'
	Set @nErrorCode= @@ERROR
End

-- SQA17761 Get event number for event Lapse Date
If @nErrorCode=0
Begin 
	Select @nLapseDateEventNo = EVENT_INPRO 
	from #EVENT_VIEW 
	where UPPER(EVENT_CPAXML) = 'LAPSE DATE'
	Set @nErrorCode= @@ERROR
End

-- SQA17761 Get event number for event Expiry
If @nErrorCode=0
Begin 
	Select @nExpiryEventNo = EVENT_INPRO 
	from #EVENT_VIEW 
	where UPPER(EVENT_CPAXML) = 'EXPIRY'
	Set @nErrorCode= @@ERROR
End


-- Populate the temp table with applicable cases AND case information.
If @nErrorCode = 0
Begin
	Set @sSQLString ="
			Insert into #CASESTOINCLUDE(CASEID, IRN, PROPERTYTYPE,
				CASETYPE_MAP, PROPERTYTYPE_MAP, CASECATEGORY_MAP, SUBTYPE_MAP, 
				BASIS_MAP, COUNTRYCODE, TRANSFERFLAG, CASENAMECOMMENCEDATE, OLDNAMETYPE, PARENTCASEID )
			Select C.CASEID, C.IRN, C.PROPERTYTYPE,
				CTV.CASETYPE_CPAXML, PTV.PROPERTYTYPE_CPAXML, CCV.CASECATEGORY_CPAXML, STV.SUBTYPE_CPAXML,
				CBV.BASIS_CPAXML, ISNULL(COUNTRY.ALTERNATECODE, C.COUNTRYCODE), 
				CASENAMES.TRANSFERFLAG, CASENAMES.COMMENCEDATE, CASENAMES.OLDNAMETYPE, RC.RELATEDCASEID
			From CASES C
			Join CASETYPE CT on (CT.CASETYPE = C.CASETYPE)
			Join (
				-- Non-transfer cases
				Select DISTINCT CN.CASEID, 0 AS TRANSFERFLAG, MIN(CASE WHEN COMMENCEDATE IS NULL THEN '17530101' ELSE CN.COMMENCEDATE END) AS COMMENCEDATE, NULL as OLDNAMETYPE
				from DOCUMENTREQUEST D 
				Join DOCUMENTREQUESTACTINGAS DA ON (DA.REQUESTID = D.REQUESTID)
				Join CASENAME CN ON (CN.NAMETYPE = DA.NAMETYPE)
				Join #NAMESTOINCLUDE NTI on (NTI.NAMENO = CN.NAMENO)
				Where D.REQUESTID = @nDocRequestId
				GROUP BY CASEID
				union
				-- Transferred cases
				Select DISTINCT CN.CASEID, 1 AS TRANSFERFLAG, MIN(CASE WHEN COMMENCEDATE IS NULL THEN '17530101' ELSE CN.COMMENCEDATE END) AS COMMENCEDATE, MIN(CN.NAMETYPE) as OLDNAMETYPE
				from DOCUMENTREQUEST D 
				Join DOCUMENTREQUEST DR ON (DR.REQUESTID = D.REQUESTID)
				Join DOCUMENTREQUESTACTINGAS DA ON (DA.REQUESTID = D.REQUESTID)
				Join NAMETYPE NT on (NT.NAMETYPE = DA.NAMETYPE)
				Join CASENAME CN ON (CN.NAMETYPE = NT.OLDNAMETYPE)
				Join #NAMESTOINCLUDE NTI on (NTI.NAMENO = CN.NAMENO)
				Where D.REQUESTID = @nDocRequestId
				and (CN.COMMENCEDATE IS NULL OR  CN.COMMENCEDATE >=   '" + CAST(@dtFromDateFilter as nvarchar) + "' ) 
				GROUP BY CASEID
				) as CASENAMES on (CASENAMES.CASEID = C.CASEID)
			Left Join COUNTRY ON (COUNTRY.COUNTRYCODE = C.COUNTRYCODE)
			Left Join PROPERTY ON (PROPERTY.CASEID = C.CASEID)
			Left Join #CASETYPE_VIEW CTV ON (CTV.CASETYPE_INPRO = C.CASETYPE and CASETYPE_CPAXML is not null)
			Left Join #PROPERTYTYPE_VIEW PTV ON (PTV.PROPERTYTYPE_INPRO = C.PROPERTYTYPE  and PROPERTYTYPE_CPAXML is not null)
			Left Join #CASECATEGORY_VIEW CCV ON (CCV.CASECATEGORY_INPRO = C.CASECATEGORY  and CASECATEGORY_CPAXML is not null)
			Left Join #SUBTYPE_VIEW STV ON (STV.SUBTYPE_INPRO = C.SUBTYPE  and SUBTYPE_CPAXML is not null)
			Left Join #BASIS_VIEW CBV ON (CBV.BASIS_INPRO = PROPERTY.BASIS and BASIS_CPAXML is not null)
			Left Join RELATEDCASE RC  ON (RC.CASEID=C.CASEID
						  and RC.RELATIONSHIP='ITM'
						  and C.CASECATEGORY in ('~A','~B','AD')
						  and RC.RELATIONSHIPNO=(select min(RC1.RELATIONSHIPNO)
									 from RELATEDCASE RC1
									 where RC1.CASEID      =RC.CASEID
									 and   RC1.RELATIONSHIP=RC.RELATIONSHIP))
			Where CT.ACTUALCASETYPE is null
			" + @sCaseWhere

	exec @nErrorCode = sp_executesql @sSQLString,
		N'@nDocRequestId int',
		@nDocRequestId = @nDocRequestId
End

-- Get the receiver case reference.
If @nErrorCode = 0
Begin
	Set @sSQLString ="
			Update C
			Set RECCASEREF = CN.REFERENCENO,
			CASENAMENO = CN.NAMENO
			From #CASESTOINCLUDE C
			Join CASENAME CN ON (CN.CASEID = C.CASEID)
			Join #NAMESTOINCLUDE NTI on (NTI.NAMENO = CN.NAMENO)
			Where CN.NAMETYPE IN (Select NAMETYPE From DOCUMENTREQUESTACTINGAS Where REQUESTID = @nDocRequestId )
			and CN.REFERENCENO is not null"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@nRecipientNameNo int,
					@nDocRequestId int',
					@nRecipientNameNo = @nRecipientNameNo,
					@nDocRequestId = @nDocRequestId
End

-- Get all the events to include
If @nErrorCode = 0
Begin
	-- Get timestamp
	Select @dCurrentDateTime = getdate()

	Insert into #CASEEVENTS(CASEID, EVENTNO, EVENTCODE, EVENTDESC, EVENTDATE, EVENTDUEDATE, EVENTTEXT, CYCLE, CREATEDBYACTION, REMINDEREVENTFLAG, TRANSFERFLAG)
	-- extract all insert transactions
	Select Distinct LOG1.CASEID, LOG1.EVENTNO, T.USERCODE, T.DESCRIPTION, LOG1.EVENTDATE, LOG1.EVENTDUEDATE, LOG1.EVENTTEXT, LOG1.CYCLE,
		LOG1.CREATEDBYACTION,
		case when (CHARINDEX(T.USERCODE, SC.COLCHARACTER)> 0) then 1 else 0 end  REMINDEREVENTFLAG,
		C.TRANSFERFLAG
	From DOCUMENTREQUEST D
	Join DOCUMENTEVENTGROUP DEG	ON (DEG.REQUESTID = D.REQUESTID)
	Join TABLECODES T		ON (T.TABLECODE = DEG.EVENTGROUP)
	Join EVENTS E			ON (E.EVENTGROUP = DEG.EVENTGROUP)
	Join CASEEVENT_iLOG LOG1		ON (LOG1.EVENTNO = E.EVENTNO)
	Join #CASESTOINCLUDE C			ON (C.CASEID = LOG1.CASEID)
	Left Join SITECONTROL SC ON  SC.CONTROLID = 'Reminder Event Group'

	Where D.REQUESTID = @nDocRequestId
	and LOG1.LOGDATETIMESTAMP >= ISNULL(D.LASTGENERATED, '1753-01-01')
	and LOG1.LOGDATETIMESTAMP >= ISNULL(D.EVENTSTART, '1753-01-01')

	-- 16923 exclude events with null date and include only Insert transactions
	and (LOG1.EVENTDATE is not null )

	-- 17758 exclude old events 
	and LOG1.EVENTDATE >= @dtReportFromDate 

	and LOG1.LOGACTION='I'
	-- only include relevant events for transfer and non-transfer cases.
	and 1 = (Case	when C.TRANSFERFLAG = 0 and (C.CASENAMECOMMENCEDATE is null or C.CASENAMECOMMENCEDATE <= dbo.fn_DateOnly(LOG1.LOGDATETIMESTAMP)) then 1
			when C.TRANSFERFLAG = 1 and (C.CASENAMECOMMENCEDATE is null or C.CASENAMECOMMENCEDATE > dbo.fn_DateOnly(LOG1.LOGDATETIMESTAMP)) then 1
			else 0 end )
	and E.IMPORTANCELEVEL >= (select COLINTEGER 
				from SITECONTROL 
				where CONTROLID = 'Client Importance')

	--
	-- Extract update transactions but exclude before change image
	-- Table alias LOG2 has all after images of change exclude the first before image.
	-- Table alias CE has the last after image of change.
	-- Use UNION only to filter duplicate data (sqa17141).
	UNION 

	Select CASEID, EVENTNO, USERCODE, DESCRIPTION, EVENTDATE, EVENTDUEDATE, EVENTTEXT, CYCLE, CREATEDBYACTION, REMINDEREVENTFLAG, TRANSFERFLAG
	From (
		Select Distinct isnull( LOG2.CASEID, CE.CASEID) CASEID, isnull(LOG2.EVENTNO, CE.EVENTNO)EVENTNO, 
			T.USERCODE, T.DESCRIPTION,  
			isnull(LOG2.EVENTDATE, CE.EVENTDATE) EVENTDATE, isnull(LOG2.EVENTDUEDATE, CE.EVENTDUEDATE) EVENTDUEDATE, 
			isnull(LOG2.EVENTTEXT, CE.EVENTTEXT) EVENTTEXT, isnull(LOG2.CYCLE, CE.CYCLE) CYCLE,
			isnull(LOG2.CREATEDBYACTION, CE.CREATEDBYACTION) CREATEDBYACTION,
			case when (CHARINDEX(T.USERCODE, SC.COLCHARACTER)> 0) then 1 else 0 end  REMINDEREVENTFLAG,
			C.TRANSFERFLAG
		From DOCUMENTREQUEST D
		Join DOCUMENTEVENTGROUP DEG	ON (DEG.REQUESTID = D.REQUESTID)
		Join TABLECODES T		ON (T.TABLECODE = DEG.EVENTGROUP)
		Join EVENTS E			ON (E.EVENTGROUP = DEG.EVENTGROUP)
		Join CASEEVENT_iLOG LOG1	ON (LOG1.EVENTNO = E.EVENTNO)
		left join CASEEVENT_iLOG LOG2 on (LOG1.LOGACTION='U'
					and LOG2.CASEID=LOG1.CASEID
					and LOG2.CYCLE=LOG1.CYCLE
					and LOG2.EVENTNO=LOG1.EVENTNO
					and LOG2.LOGDATETIMESTAMP=(select min(LOG3.LOGDATETIMESTAMP)
								from CASEEVENT_iLOG LOG3
								where LOG3.CASEID=LOG1.CASEID
								-- 17416 exclude transactions that did not change EVENTDATE or EVENTTEXT
								and LOG3.CYCLE=LOG1.CYCLE
								and ( ISNULL(LOG2.EVENTDATE, '19000101') <>ISNULL(LOG1.EVENTDATE, '19000101') OR ISNULL(LOG2.EVENTTEXT, '') <> ISNULL(LOG1.EVENTTEXT, ''))
								and LOG3.EVENTNO=LOG1.EVENTNO
								and (LOG3.EVENTDATE is not null or LOG3.EVENTDUEDATE is not null)
								and LOG3.LOGDATETIMESTAMP>LOG1.LOGDATETIMESTAMP))
		left join CASEEVENT CE on (LOG1.LOGACTION='U'
					and LOG2.LOGDATETIMESTAMP is null
					and CE.CASEID=LOG1.CASEID
					-- 17416 exclude transactions that did not change EVENTDATE or EVENTTEXT
					and CE.CYCLE=LOG1.CYCLE 
					and ( ISNULL(CE.EVENTDATE, '19000101') <> ISNULL(LOG1.EVENTDATE, '19000101') OR ISNULL(CE.EVENTTEXT, '') <> ISNULL(LOG1.EVENTTEXT, ''))
					and CE.EVENTNO=LOG1.EVENTNO 
					)

		Join #CASESTOINCLUDE C			ON (C.CASEID = LOG1.CASEID)
		Left Join SITECONTROL SC ON  SC.CONTROLID = 'Reminder Event Group'

		Where D.REQUESTID = @nDocRequestId
		and LOG1.LOGDATETIMESTAMP >= ISNULL(D.LASTGENERATED, '1753-01-01')
		and LOG1.LOGDATETIMESTAMP >= ISNULL(D.EVENTSTART, '1753-01-01')

		-- 16923 exclude events with null date and include only Update transactions
		and (LOG1.EVENTDATE is not null or LOG1.EVENTDUEDATE is not null)
		and LOG1.LOGACTION='U'			-- include update transactions only
		-- only include relevant events for transfer and non-transfer cases.
		and 1 = (Case	when C.TRANSFERFLAG = 0 and (C.CASENAMECOMMENCEDATE is null or C.CASENAMECOMMENCEDATE <= dbo.fn_DateOnly(LOG1.LOGDATETIMESTAMP)) then 1
				when C.TRANSFERFLAG = 1 and (C.CASENAMECOMMENCEDATE is null or C.CASENAMECOMMENCEDATE > dbo.fn_DateOnly(LOG1.LOGDATETIMESTAMP)) then 1
				else 0 end )
		and E.IMPORTANCELEVEL >= (select COLINTEGER 
					from SITECONTROL 
					where CONTROLID = 'Client Importance')
		) AS TEMPUPDATEEVENT 
	Where TEMPUPDATEEVENT.EVENTDATE >= @dtReportFromDate  -- 17758 exclude old events 
	ORDER BY CASEID, USERCODE, EVENTDATE, EVENTDUEDATE


	Select @nErrorCode = @@ERROR, @nNumberOfCaseEvents = @@rowcount
End

-- Create the indexes after inserting the data.

CREATE INDEX X1CASEEVENTS ON #CASEEVENTS
(
	CASEID
)
CREATE INDEX X2CASEEVENTS ON #CASEEVENTS
(
	EVENTNO
)

-- Delete cases where no events exist
If @nErrorCode = 0
Begin
	Set @sSQLString ="
		DELETE #CASESTOINCLUDE
		FROM #CASESTOINCLUDE CTI
		WHERE NOT EXISTS (SELECT 1 
				FROM #CASEEVENTS CE 
				WHERE CE.CASEID = CTI.CASEID
				AND CE.TRANSFERFLAG = CTI.TRANSFERFLAG)"
	exec @nErrorCode = sp_executesql @sSQLString
End

-- load cases into classes
If @nErrorCode = 0
Begin
	Set @sSQLString = "Insert into "+ @sCaseClassTableName +" (CASEID) 
			Select distinct CASEID 
			from #CASESTOINCLUDE"
	Exec @nErrorCode=sp_executesql @sSQLString
End		


-- Now tokenise case classes
If @nErrorCode = 0
Begin
	Exec @nErrorCode=ede_TokeniseCaseClass @sCaseClassTableName	
End

-- SQA21397
-- Load parent Case of Cases withe Category of ~A, ~B or AD
-- so that the Annuity Term of parent can be calculated and used
-- in the child
If @nErrorCode=0
Begin
	Set @sSQLString="
	Insert into #CASESTOINCLUDE(CASEID, PARENTCASEFLAG)
	select CI.PARENTCASEID, 1
	from #CASESTOINCLUDE CI
	left join #CASESTOINCLUDE P on (P.CASEID=CI.PARENTCASEID)
	where CI.PARENTCASEID is not null
	and P.CASEID is null"
	
	exec @nErrorCode=sp_executesql @sSQLString
End

-- Calculate the Expiry date and renewal start date and renewal date if exists for all the CASES involved.
-- Borrowed code from [pt_GetAgeOfCase]
If @nErrorCode=0
Begin 
	Set @sSQLString="
	Update #CASESTOINCLUDE
	Set CYCLE=OA.CYCLE, 
		RENEWALSTART=RENEWALSTART.EVENTDATE, 
		NEXTRENEWAL = NEXTRENEW.EVENTDATE, 
		NEXTRENEWALDUEDATE = NEXTRENEW.EVENTDUEDATE, 
		LAPSEDATE = LAPSEDATE.EVENTDATE, 
		LAPSEDUEDATE = LAPSEDATE.EVENTDUEDATE,
		LAPSECYCLE = LAPSEDATE.CYCLE,
		EXPIRYDATE = EXPIRYDATE.EVENTDATE, 
		EXPIRYDUEDATE = EXPIRYDATE.EVENTDUEDATE,
		EXPIRYCYCLE = EXPIRYDATE.CYCLE

	From #CASESTOINCLUDE
	Left Join CASEEVENT RENEWALSTART	on (RENEWALSTART.CASEID = #CASESTOINCLUDE.CASEID
									and RENEWALSTART.EVENTNO = -9)
	Left Join (	select MIN(O.CYCLE) as [CYCLE], O.CASEID
				from OPENACTION O
				join SITECONTROL SC on (SC.CONTROLID='Main Renewal Action')
				where O.ACTION=SC.COLCHARACTER
				and O.POLICEEVENTS=1
				group by O.CASEID) OA on (OA.CASEID=#CASESTOINCLUDE.CASEID)
	Left Join CASEEVENT NEXTRENEW	on (NEXTRENEW.CASEID = OA.CASEID
				and NEXTRENEW.CASEID = #CASESTOINCLUDE.CASEID
				and NEXTRENEW.EVENTNO = -11
				and NEXTRENEW.CYCLE=OA.CYCLE)
	Left Join CASEEVENT LAPSEDATE ON (LAPSEDATE.CASEID = #CASESTOINCLUDE.CASEID
					AND LAPSEDATE.EVENTNO = (SELECT EVENT_INPRO 
								FROM #EVENT_VIEW 
								WHERE upper(EVENT_CPAXML) = 'LAPSE DATE')
					-- 17761 get the current cycle
					AND LAPSEDATE.CYCLE = ( select min(O.CYCLE) 
							from CASEEVENT CE
							join EVENTS EV	on (EV.EVENTNO=CE.EVENTNO)
							join ACTIONS AC	on (AC.ACTION=isnull(EV.CONTROLLINGACTION, CE.CREATEDBYACTION))
							join OPENACTION O	on (O.CASEID=CE.CASEID
										and O.ACTION=AC.ACTION
										and O.CYCLE=CASE WHEN(AC.NUMCYCLESALLOWED=1) THEN 1 ELSE CE.CYCLE END
										and O.CYCLE=(select min(O1.CYCLE)
											from OPENACTION O1
											where O1.CASEID=CE.CASEID
											and O1.ACTION=O.ACTION
											and O1.POLICEEVENTS=1))
							where CE.CASEID = #CASESTOINCLUDE.CASEID
							and CE.EVENTNO = (SELECT EVENT_INPRO 
									FROM #EVENT_VIEW 
									WHERE upper(EVENT_CPAXML) = 'LAPSE DATE') )	
					)
	Left Join CASEEVENT EXPIRYDATE ON (EXPIRYDATE.CASEID = #CASESTOINCLUDE.CASEID
					AND EXPIRYDATE.EVENTNO = (SELECT EVENT_INPRO 
					FROM #EVENT_VIEW 
					WHERE upper(EVENT_CPAXML) = 'EXPIRY'))"

	Exec @nErrorCode=sp_executesql @sSQLString
End


-- SQA17761  Get details for event 'next affidavit' at CASE LEVEL for the current cycle
If @nErrorCode=0
Begin 
	Update CTI
	Set AFFIDCYCLE			= NEXTAFFID.CYCLE, 
		AFFIDDATE		= NEXTAFFID.EVENTDATE,
		AFFIDDUEDATE		= NEXTAFFID.EVENTDUEDATE

	From #CASESTOINCLUDE CTI
	Left Join  (select CE.CASEID, CE.EVENTNO, min(O.CYCLE) AS CYCLE
				from CASEEVENT CE
				join EVENTS EV	on (EV.EVENTNO=CE.EVENTNO)
				join ACTIONS AC	on (AC.ACTION=isnull(EV.CONTROLLINGACTION,CE.CREATEDBYACTION))
				join OPENACTION O on (O.CASEID=CE.CASEID
							and O.ACTION=AC.ACTION
							and O.CYCLE=CASE WHEN(AC.NUMCYCLESALLOWED=1) THEN 1 ELSE CE.CYCLE END
							and O.CYCLE=(select min(O1.CYCLE)
								from OPENACTION O1
								where O1.CASEID=CE.CASEID
								and O1.ACTION=O.ACTION
								and O1.POLICEEVENTS=1))
				where CE.EVENTNO = @nNextAffidEventNo
				group by CE.CASEID, CE.EVENTNO) OA on (OA.CASEID = CTI.CASEID)

	Left Join CASEEVENT NEXTAFFID on ( NEXTAFFID.CASEID = OA.CASEID
					and NEXTAFFID.EVENTNO	= OA.EVENTNO
					and NEXTAFFID.CYCLE	= OA.CYCLE
					and NEXTAFFID.CASEID	= CTI.CASEID
					and NEXTAFFID.EVENTNO	= @nNextAffidEventNo
					)
	Set @nErrorCode= @@ERROR
End


-- SQA17761  Get details for event 'Lapse Date Affidavit' at CASE LEVEL for the current cycle
If @nErrorCode=0
Begin 
	Update CTI
	Set 	AFFIDLAPSEDATE		= AFFIDLAPSEDATE.EVENTDATE,
		AFFIDLAPSEDUEDATE	= AFFIDLAPSEDATE.EVENTDUEDATE,
		AFFIDLAPSECYCLE		= AFFIDLAPSEDATE.CYCLE

	From #CASESTOINCLUDE CTI
	Left Join  (select CE.CASEID, CE.EVENTNO, min(O.CYCLE) AS CYCLE
				from CASEEVENT CE
				join EVENTS EV	on (EV.EVENTNO=CE.EVENTNO)
				join ACTIONS AC	on (AC.ACTION=isnull(EV.CONTROLLINGACTION,CE.CREATEDBYACTION))
				join OPENACTION O on (O.CASEID=CE.CASEID
							and O.ACTION=AC.ACTION
							and O.CYCLE=CASE WHEN(AC.NUMCYCLESALLOWED=1) THEN 1 ELSE CE.CYCLE END
							and O.CYCLE=(select min(O1.CYCLE)
								from OPENACTION O1
								where O1.CASEID=CE.CASEID
								and O1.ACTION=O.ACTION
								and O1.POLICEEVENTS=1))
				where CE.EVENTNO = @nLapseDateAffidEventNo 
				group by CE.CASEID, CE.EVENTNO) OA on (OA.CASEID = CTI.CASEID)
	Left Join CASEEVENT AFFIDLAPSEDATE ON (AFFIDLAPSEDATE.CASEID = OA.CASEID
						and AFFIDLAPSEDATE.EVENTNO	= OA.EVENTNO
						and AFFIDLAPSEDATE.CYCLE	= OA.CYCLE
						and AFFIDLAPSEDATE.CASEID	= CTI.CASEID
						and AFFIDLAPSEDATE.EVENTNO	= @nLapseDateAffidEventNo
						)
	Set @nErrorCode= @@ERROR
End




-- Calculate the next renewal date if reporting to CPA.
-- Borrowed code from [cs_GetNextRenewalDate]
If @nErrorCode=0
Begin
	-- The CPA Renewal Date is determined from the latest record available in the 3 files
	-- that CPA provide in the interface.  It is possible for there to be no Renewal Date
	-- in which case a date of 01 Jan 1801 is used in the calculation to avoid a 
	-- Null Eliminated warning message.

	Set @sSQLString="
	Update #CASESTOINCLUDE
	Set CPARENEWALDATE = CPARD.CPARENEWALDATE
	From (SELECT convert(datetime,substring(max(convert(char(8),isnull(P.ASATDATE,'18010101'),112)+convert(char(8),isnull(P.NEXTRENEWALDATE,'18010101'),112)),9,8)) AS CPARENEWALDATE
	From CASES C
	Join #CASESTOINCLUDE on (#CASESTOINCLUDE.CASEID = C.CASEID)
	Join (Select DATEOFPORTFOLIOLST as ASATDATE, NEXTRENEWALDATE, CASEID
	      from CPAPORTFOLIO
	      where STATUSINDICATOR='L'
	      and NEXTRENEWALDATE is not null
	      and TYPECODE not in ('A1','A6','AF','CI','CN','DE','DI','NW','SW')
	      UNION ALL
	      select EVENTDATE, NEXTRENEWALDATE, CASEID
	      from CPAEVENT
	      UNION ALL
	      select BATCHDATE, RENEWALDATE, CASEID
	      from CPARECEIVE
	      where IPRURN is not null
	      and NARRATIVE not like 'NON-RELEVANT AMEND%') P on (P.CASEID=C.CASEID)
	Where C.REPORTTOTHIRDPARTY = 1) AS CPARD
	"

	Exec @nErrorCode=sp_executesql @sSQLString

End

-- Calculate the term of the renewal
-- Borrowed code from [pt_GetAgeOfCase]
-- sqa18317 convert derive annuityterm to null if value not in the range 0-255
If @nErrorCode=0
Begin 
	Update CI
		Set @nAnnuityTerm =
			Case
				When VP.ANNUITYTYPE=0 AND VP.PROPERTYTYPE  = 'T'    Then floor(datediff(mm,isnull(CE1.EVENTDATE,CE1.EVENTDUEDATE), isnull(CE2.EVENTDATE,CE2.EVENTDUEDATE))/12)
				When VP.ANNUITYTYPE=0 AND VP.PROPERTYTYPE != 'T'    Then NULL
				When VP.ANNUITYTYPE=1 AND CI.EXPIRYDATE IS NOT NULL Then floor(datediff(mm,CI.RENEWALSTART, isnull(CI.CPARENEWALDATE, CI.NEXTRENEWAL))/12) + ISNULL(VP.OFFSET, 0)
				When VP.ANNUITYTYPE=2 Then CI.CYCLE + isnull(VP.CYCLEOFFSET,0)
			End,
		ANNUITYTERM = Case When ((@nAnnuityTerm < 0) OR (@nAnnuityTerm > 255)) Then NULL else @nAnnuityTerm End, 
		CRITERIANO  = Case When (CE2.CASEID IS NULL and C.PROPERTYTYPE='T' and CE1.CREATEDBYACTION='~2') Then CE1.CREATEDBYCRITERIA ELSE NULL End

		From #CASESTOINCLUDE CI
		Join CASES C ON (C.CASEID = CI.CASEID)
		Join VALIDPROPERTY VP	on (VP.PROPERTYTYPE = C.PROPERTYTYPE
					and VP.COUNTRYCODE  = ( Select min(VP1.COUNTRYCODE)
								From VALIDPROPERTY VP1
								Where VP1.PROPERTYTYPE=CI.PROPERTYTYPE
								and   VP1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
		Left JOIN CASEEVENT CE1 ON (CE1.CASEID  = CI.CASEID
					and CE1.EVENTNO = -11
					and CE1.CYCLE   = CI.CYCLE)
		Left JOIN CASEEVENT CE2 on (CE2.CASEID  = CE1.CASEID
					and CE2.EVENTNO = -11
					and CE2.CYCLE   = CI.CYCLE + 1) 

	Set @nErrorCode = @@ERROR
End

-- SQA21397
-- Calculate the term of the Renewal when the Next Renewal Date is not known.
-- Use the appropriate DueDateCalc rule taking into consideration the Next Cycle 
-- and the Country of the Case.
-- If the DueDateCalc specifies that the period is determined from the Standing Instruction
-- then save the PeriodType and the Instruction so that the next step can then get the 
-- appropriate standing instruction.
If @nErrorCode=0
Begin 
	Update CI
	Set ANNUITYTERM = Case	When(DD1.CRITERIANO is not null) THEN DD1.DEADLINEPERIOD
				When(DD3.CRITERIANO is not null) THEN DD3.DEADLINEPERIOD
				Else NULL
			  End,
	    PERIODTYPE =  Case	When(DD1.CRITERIANO is not null) Then Case When(DD1.PERIODTYPE IN ('1','2','3')) Then DD1.PERIODTYPE End
				When(DD3.CRITERIANO is not null) Then Case When(DD3.PERIODTYPE IN ('1','2','3')) Then DD3.PERIODTYPE End
				Else NULL
			  End,
	    INSTRUCTION=  Case	When(DD1.CRITERIANO is not null) Then Case When(DD1.PERIODTYPE IN ('1','2','3')) Then EC.INSTRUCTIONTYPE End
				When(DD3.CRITERIANO is not null) Then Case When(DD3.PERIODTYPE IN ('1','2','3')) Then EC.INSTRUCTIONTYPE End
				Else NULL
			  End		  
	From #CASESTOINCLUDE CI
	Join CASES C ON (C.CASEID = CI.CASEID)
	Join EVENTCONTROL EC	  on (EC.CRITERIANO =CI.CRITERIANO
				  and EC.EVENTNO    =-11)
	-- Country specific due date calculation
	Left Join DUEDATECALC DD1 on (DD1.CRITERIANO=CI.CRITERIANO
				  and DD1.EVENTNO   =-11
				  and DD1.COUNTRYCODE=C.COUNTRYCODE
				  and DD1.CYCLENUMBER=(	select max(DD2.CYCLENUMBER)
							from DUEDATECALC DD2
							where DD2.CRITERIANO=DD1.CRITERIANO
							and   DD2.EVENTNO   =-11
							and   DD2.COMPAREEVENT is null
							and   DD2.COUNTRYCODE =C.COUNTRYCODE
							and   DD2.CYCLENUMBER<=CI.CYCLE+1) )
	-- Generic due date calculation not specific for a Country
	Left Join DUEDATECALC DD3 on (DD3.CRITERIANO=CI.CRITERIANO
				  and DD1.CRITERIANO is null
				  and DD3.EVENTNO   =-11
				  and DD3.COUNTRYCODE is null
				  and DD3.CYCLENUMBER=(	select max(DD4.CYCLENUMBER)
							from DUEDATECALC DD4
							where DD4.CRITERIANO=DD3.CRITERIANO
							and   DD4.EVENTNO   =-11
							and   DD4.COMPAREEVENT is null
							and   DD4.COUNTRYCODE  is null
							and   DD4.CYCLENUMBER<=CI.CYCLE+1) ) 
	Where CI.ANNUITYTERM is NULL

	Set @nErrorCode = @@ERROR
End

-- SQA21397
-- Check to see if there are any standing instructions required to be used to 
-- determine the term of renewal.
If @nErrorCode=0
Begin 
	insert into #TEMPCASES(CASEID, PROPERTYTYPE, COUNTRYCODE, INSTRUCTIONSLOADED)
	Select C.CASEID, C.PROPERTYTYPE, C.COUNTRYCODE, 0
	from #CASESTOINCLUDE CI
	join CASES C on (C.CASEID=CI.CASEID)
	where CI.ANNUITYTERM is null
	and CI.INSTRUCTION   is not null
	
	Select @nErrorCode = @@ERROR,
	       @nRowCount  = @@ROWCOUNT
End

If  @nRowCount>0
and @nErrorCode=0
Begin
	--------------------------------------------------------
	-- Get the Standing Instructions for each Case by using
	-- the following procedure to load #TEMPCASEINSTRUCTIONS
	--------------------------------------------------------
	exec @nErrorCode= dbo.ip_PoliceGetStandingInstructions 
				@pnDebugFlag=0
			
	-------------------------------------------------------
	-- After getting the Standing Instructions for the
	-- Cases, we can now update the annuity term using the
	-- available Period defined for the Standing
	-- Instruction.
	-------------------------------------------------------			
	Update CI
	Set ANNUITYTERM = Case	When(CI.PERIODTYPE='1') THEN T.PERIOD1AMT
				When(CI.PERIODTYPE='2') THEN T.PERIOD2AMT
				When(CI.PERIODTYPE='3') THEN T.PERIOD3AMT
				Else NULL
			  End		  
	From #CASESTOINCLUDE CI
	Join #TEMPCASEINSTRUCTIONS T	on (T.CASEID         =CI.CASEID
					and T.INSTRUCTIONTYPE=CI.INSTRUCTION) 
	Where CI.ANNUITYTERM is NULL
	and   CI.PERIODTYPE  is not NULL

	Set @nErrorCode = @@ERROR
End

---------------------------------------------------------
-- SQA21397
-- Finally if the Annuity Term is still not known and the 
-- parent Case has the information available then use the
-- details of the parent
---------------------------------------------------------
If @nErrorCode=0
Begin		
	Update CI
	Set ANNUITYTERM = P.ANNUITYTERM	  
	From #CASESTOINCLUDE CI
	Join (select * from #CASESTOINCLUDE) P	on (P.CASEID=CI.PARENTCASEID) 
	Where CI.ANNUITYTERM is NULL

	Set @nErrorCode = @@ERROR
End

---------------------------------------------------------
-- SQA21397
-- Remove any rows from #CASESTOINCLUDE that were only
-- included because they were the parent of another Case
-- being reported
---------------------------------------------------------
If @nErrorCode=0
Begin		
	Delete #CASESTOINCLUDE 
	Where PARENTCASEFLAG=1

	Set @nErrorCode = @@ERROR
End

-- SQA17761 Calculate ANNUITYTERM for event Next Affidavit (-500)
-- SQA18317 convert derive annuityterm to null if value not in the range 0-255
If @nErrorCode=0
Begin 
	Update #CASESTOINCLUDE
	Set @nAnnuityTerm = 
		Case
		When VP.ANNUITYTYPE=0 AND VP.PROPERTYTYPE = 'T' Then floor(datediff(mm,isnull(CECYCLE1.EVENTDATE,CECYCLE1.EVENTDUEDATE), isnull(CECYCLE2.EVENTDATE,CECYCLE2.EVENTDUEDATE))/12)
		When VP.ANNUITYTYPE=0 AND VP.PROPERTYTYPE != 'T' Then NULL
		When VP.ANNUITYTYPE=1 AND #CASESTOINCLUDE.EXPIRYDATE IS NOT NULL Then floor(datediff(mm,#CASESTOINCLUDE.RENEWALSTART, isnull(#CASESTOINCLUDE.CPARENEWALDATE, #CASESTOINCLUDE.NEXTRENEWAL))/12) + ISNULL(VP.OFFSET, 0)
		When VP.ANNUITYTYPE=2 Then #CASESTOINCLUDE.CYCLE + isnull(VP.CYCLEOFFSET,0)
		End,
	    AFFIDANNUITYTERM = Case when ((@nAnnuityTerm < 0) OR (@nAnnuityTerm > 255)) then NULL else @nAnnuityTerm end
	From #CASESTOINCLUDE
	Join CASES C ON (C.CASEID = #CASESTOINCLUDE.CASEID)
	Join VALIDPROPERTY VP	on (VP.PROPERTYTYPE = C.PROPERTYTYPE
				and VP.COUNTRYCODE  = (Select min(VP1.COUNTRYCODE)
							From VALIDPROPERTY VP1
							Where VP1.PROPERTYTYPE=#CASESTOINCLUDE.PROPERTYTYPE
							and   VP1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
	Left JOIN CASEEVENT CECYCLE1 ON (CECYCLE1.CASEID = #CASESTOINCLUDE.CASEID
				and CECYCLE1.EVENTNO = @nNextAffidEventNo
				and CECYCLE1.CYCLE = #CASESTOINCLUDE.CYCLE)
	Left JOIN CASEEVENT CECYCLE2 on (CECYCLE2.CASEID = CECYCLE1.CASEID
				and CECYCLE2.EVENTNO = @nNextAffidEventNo
				and CECYCLE2.CYCLE = #CASESTOINCLUDE.CYCLE + 1)

	SET @nErrorCode=@@ERROR
End


-- Calculate the renewal start date and renewal date if exists for all the EVENTS involved.
-- Borrowed code from [cs_GetNextRenewalDate]
If @nErrorCode=0
Begin 
	Update #CASEEVENTS
	Set NEXTRENEWALEVENT = NEXTRENEW.EVENTDATE, 
	NEXTRENEWALDUEDATE = NEXTRENEW.EVENTDUEDATE,
	AFFIDEVENTDATE = AFFIDNEXTRENEW.EVENTDATE,		-- SQA17761 
	AFFIDEVENTDUEDATE = AFFIDNEXTRENEW.EVENTDUEDATE 
	From #CASEEVENTS
	Left Join CASEEVENT NEXTRENEW on (NEXTRENEW.CASEID = #CASEEVENTS.CASEID
								and NEXTRENEW.EVENTNO = -11
								and NEXTRENEW.CYCLE = #CASEEVENTS.CYCLE)
	Left Join CASEEVENT AFFIDNEXTRENEW on (AFFIDNEXTRENEW.CASEID = #CASEEVENTS.CASEID
								and AFFIDNEXTRENEW.EVENTNO = @nNextAffidEventNo
								and AFFIDNEXTRENEW.CYCLE = #CASEEVENTS.CYCLE)

	Set @nErrorCode=@@ERROR
End


--
-- Calculate the charges for reminder events
If @nErrorCode=0
Begin 
	Declare	@nRowId			int,
		@nEventNo		int,
		@nDebtorNo		int,
		@nCaseId		int,
		@nActivityIdHistory		int,
		@sBillCurrency		nvarchar(6),
		@sDisbTaxCode		nvarchar(6),
		@sServTaxCode		nvarchar(6),
		@nTaxRate		int,
		@sTempTaxCode		nvarchar(6),
		@nServBillAmount	decimal(11,2),
		@nDisbBillAmount	decimal(11,2),
		@nDisbTaxBillAmount	decimal(11,2),
		@nServTaxBillAmount	decimal(11,2),
		@nServBillDiscount	decimal(11,2),
		@nDisbBillDiscount	decimal(11,2),
		@nTotalReminderFee	decimal(11,2)

	Set @nRowId = 0
	While (@nErrorCode = 0) and  (@nRowId < @nNumberOfCaseEvents+1)
	Begin
		Set @sSQLString="
			Select TOP 1 
			@nRowId = CE.ROWID,
			@nCaseId = CE.CASEID,
			@nActivityIdHistory = AH.ACTIVITYID,
			@sBillCurrency = AH.BILLCURRENCY,
			@sDisbTaxCode = AH.DISBTAXCODE,
			@sServTaxCode = AH.SERVICETAXCODE,
			@nDisbBillAmount = isnull(AH.DISBBILLAMOUNT, 0),
			@nServBillAmount = isnull(AH.SERVBILLAMOUNT, 0),
			@nServBillDiscount = isnull(AH.SERVBILLDISCOUNT, 0),
			@nDisbBillDiscount = isnull(AH.DISBBILLDISCOUNT, 0)

			from #CASEEVENTS CE
			Join ACTIVITYHISTORY AH on (AH.CASEID = CE.CASEID AND AH.EVENTNO = CE.EVENTNO)
			left join DOCUMENTREQUEST D on D.REQUESTID = @nDocRequestId
			where CE.ROWID > @nRowId
			and CE.REMINDEREVENTFLAG = 1
			and AH.WHENOCCURRED >= ISNULL(D.LASTGENERATED, '1753-01-01')
			and AH.WHENOCCURRED >= ISNULL(D.EVENTSTART, '1753-01-01')
			and AH.ESTIMATEFLAG = 1 
			and AH.PAYFEECODE IS NULL
			-- get latest estimates if there are multiple
			and AH.ACTIVITYID = (Select MAX(AH2.ACTIVITYID) from ACTIVITYHISTORY AH2
						where AH2.CASEID = CE.CASEID 
						and AH2.EVENTNO = CE.EVENTNO
						and AH2.ESTIMATEFLAG = 1 
						and AH2.PAYFEECODE IS NULL)
			ORDER BY CE.ROWID
		"
		Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nRowId			int output,
		  @nCaseId			int output, 
		  @nActivityIdHistory		int output,
		  @sBillCurrency		nvarchar(6) output,
		  @sDisbTaxCode			nvarchar(6) output,
		  @sServTaxCode			nvarchar(6) output,
		  @nDisbBillAmount		decimal(11,2) output,	
		  @nServBillAmount		decimal(11,2) output,	
		  @nServBillDiscount		decimal(11,2) output,
		  @nDisbBillDiscount		decimal(11,2) output,
		  @nDocRequestId		int',
		  @nRowId			= @nRowId output,
		  @nCaseId			= @nCaseId output,
		  @nActivityIdHistory		= @nActivityIdHistory output,
		  @sBillCurrency		= @sBillCurrency output,
		  @sDisbTaxCode			= @sDisbTaxCode output,
		  @sServTaxCode			= @sServTaxCode output,
		  @nDisbBillAmount		= @nDisbBillAmount output,
		  @nServBillAmount		= @nServBillAmount output,
		  @nServBillDiscount		= @nServBillDiscount output,
		  @nDisbBillDiscount		= @nDisbBillDiscount output,
		  @nDocRequestId		= @nDocRequestId	

		If @@ROWCOUNT = 0 
			BREAK

		-- get debtor name for the case
		If @nErrorCode = 0
		Begin
			Select @nDebtorNo = NAMENO
			from CASENAME 
			where CASEID = @nCaseId
			and NAMETYPE = 'D'
			and SEQUENCE = (Select min(SEQUENCE) from CASENAME 
					where CASEID = @nCaseId and NAMETYPE = 'D')
		End

		-- Calculate disbursement tax bill amount:
		If @nErrorCode = 0
		Begin
			-- Get disbursment tax rate 
			exec @nErrorCode=pt_GetTaxRate 
				@prnTaxRate	= @nTaxRate output,
				@psNewTaxCode	= @sTempTaxCode output,
				@psTaxCode	= @sDisbTaxCode,   
				@pnCaseId	= @nCaseId,
				@pnDebtorNo 	= @nDebtorNo
			Set @nDisbTaxBillAmount = (@nDisbBillAmount - @nDisbBillDiscount) * isnull(@nTaxRate,0) / 100
		End

		-- Calculate service tax bill amount:
		If @nErrorCode = 0
		Begin
			-- Get service tax rate 
			exec @nErrorCode=pt_GetTaxRate 
				@prnTaxRate	= @nTaxRate output,
				@psNewTaxCode	= @sTempTaxCode output,
				@psTaxCode	= @sServTaxCode,   
				@pnCaseId	= @nCaseId,
				@pnDebtorNo 	= @nDebtorNo
			Set @nServTaxBillAmount = (@nServBillAmount - @nServBillDiscount) * isnull(@nTaxRate,0) / 100
		End

		-- save the reminder charge in #CASEEVENTS
		If @nErrorCode = 0
		Begin
			Set @nTotalReminderFee = @nServBillAmount +
						@nDisbBillAmount +
						@nServTaxBillAmount +
						@nDisbTaxBillAmount -
						@nServBillDiscount -
						@nDisbBillDiscount
			Set @sSQLString="
			Update #CASEEVENTS
			Set CHARGEDOCUMENTNUMBER = @nActivityIdHistory, 
			CURRENCYCODE = @sBillCurrency,
			CHARGEAMOUNT = @nTotalReminderFee
			From #CASEEVENTS
			where ROWID = @nRowId"
			Exec @nErrorCode=sp_executesql @sSQLString,
			N'@nActivityIdHistory int,
			  @sBillCurrency nvarchar(6),
			  @nTotalReminderFee dec(11,2),
			  @nRowId int',
			  @nActivityIdHistory = @nActivityIdHistory,
			  @sBillCurrency = @sBillCurrency,
			  @nTotalReminderFee = @nTotalReminderFee,
			  @nRowId = @nRowId
		End
	End -- loop each reminder event.	
End



-- SQA20971Get INVOICE for ACCOUNTING EVENTS at case level.  If there are multiple events associated with an invoice, only one invoice will be extracted for the case.
-- Note :  the eventdate and invoice postdate are the same to the millisecond
If @nErrorCode = 0
Begin
	Insert into #OPENITEMCASEEVENT (ITEMENTITYNO, ITEMTRANSNO, OPENITEMNO,  ITEMTYPE, POSTDATE,  CASEID, IRN )
	select DISTINCT OI1.ITEMENTITYNO, OI1.ITEMTRANSNO, OI1.OPENITEMNO, OI1.ITEMTYPE, OI1.POSTDATE, OI1.CASEID, C.IRN
	from  #CASEEVENTS CE1 
	join CASES C ON C.CASEID = CE1.CASEID
	left join DEBTOR_ITEM_TYPE DIT on (DIT.EVENTNO = CE1.EVENTNO)
	left join ITEMTYPEACTION ITA on (ITA.ACTION = CE1.CREATEDBYACTION and ITA.EVENTNO = CE1.EVENTNO)
	join (select DISTINCT WH.CASEID, OI.ITEMTYPE, OI.POSTDATE, OI.ITEMENTITYNO, OI.ITEMTRANSNO, OI.OPENITEMNO
			from OPENITEM OI 
			join WORKHISTORY WH ON (WH.REFTRANSNO = OI.ITEMTRANSNO
									AND WH.REFENTITYNO = OI.ITEMENTITYNO)
			) as OI1 on (OI1.ITEMTYPE = ISNULL(ITA.ITEMTYPEID, DIT.ITEM_TYPE_ID)   
							AND OI1.CASEID = CE1.CASEID
							AND OI1.POSTDATE = CE1.EVENTDATE )

	Select @nErrorCode = @@error
End


-- SQA20971  Get  DISPLAYSEQUENCE for the CREATEDBYACTION from VALIDACTION to help event consolidation.  Only process events associated with invoices.
-- Note: If there are multiple events associated with an invoice, only one event which has createdbyaction with the lowest display sequence number will be reported for the case.
If @nErrorCode=0
Begin 
	Update CE1
	Set ACTIONDISPLAYSEQUENCE = VA.DISPLAYSEQUENCE
	from #CASEEVENTS CE1
	join CASES C on C.CASEID = CE1.CASEID
	join EVENTS E on (E.EVENTNO = CE1.EVENTNO)
	join #OPENITEMCASEEVENT OI  on (OI.CASEID = CE1.CASEID AND OI.POSTDATE = CE1.EVENTDATE)
	join VALIDACTION VA on (  (VA.COUNTRYCODE = C.COUNTRYCODE OR VA.COUNTRYCODE = 'ZZZ')
							and VA.PROPERTYTYPE = C.PROPERTYTYPE 
							and VA.CASETYPE = C.CASETYPE 
							and VA.ACTION = CE1.CREATEDBYACTION )
	where E.ACCOUNTINGEVENTFLAG = 1
	and CE1.REMINDEREVENTFLAG != 1
	and CE1.CREATEDBYACTION is not null

	Set @nErrorCode= @@ERROR
End

-- SQA20971  Consolidate accounting events by keeping only the event with the lowest validaction.displaysequence for each case / invoice 
-- do this before the event is being counted in the header.
If @nErrorCode=0
Begin 
	Delete CE1
	from #CASEEVENTS CE1
	join CASES C on C.CASEID = CE1.CASEID
	join EVENTS E on (E.EVENTNO = CE1.EVENTNO)
	join #OPENITEMCASEEVENT OI  on (OI.CASEID = CE1.CASEID AND OI.POSTDATE = CE1.EVENTDATE)
	join 	( Select CE2.CASEID, CE2.EVENTDATE, min(CE2.ACTIONDISPLAYSEQUENCE) as ACTIONDISPLAYSEQUENCE
		from #CASEEVENTS CE2
		where CE2.ACTIONDISPLAYSEQUENCE IS NOT NULL
		group by CE2.CASEID, CE2.EVENTDATE) VA on VA.CASEID = CE1.CASEID
											and VA.EVENTDATE = CE1.EVENTDATE
	where E.ACCOUNTINGEVENTFLAG = 1
	and CE1.REMINDEREVENTFLAG != 1
	and CE1.CREATEDBYACTION is not null
	and CE1.ACTIONDISPLAYSEQUENCE <> VA.ACTIONDISPLAYSEQUENCE 
End




/********************************************************************
Start Returning data
***********************************************************************/
-- Return the header

If @nErrorCode = 0
Begin
	-- time stamp captured just before retrieving the events.

	Select  @sSenderRequestIdentifier = RTRIM( CONVERT(char(4), year(@dCurrentDateTime))) 
	+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), month(@dCurrentDateTime)))) + CONVERT(char(2), month(@dCurrentDateTime)))
	+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), day(@dCurrentDateTime)))) + CONVERT(char(2), day(@dCurrentDateTime)))
	+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(hh, @dCurrentDateTime)))) + CONVERT(char(2), datepart(hh,@dCurrentDateTime)))
	+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(mi, @dCurrentDateTime)))) + CONVERT(char(2), datepart(mi,@dCurrentDateTime)))
	+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(ss, @dCurrentDateTime)))) + CONVERT(char(2), datepart(ss,@dCurrentDateTime)))

	-- Get @sSenderProducedDateTime as Timestamp in format CCYY-MM-DDTHH:MM:SS.OZ 
	Select  @sSenderProducedDateTime = RTRIM( CONVERT(char(4), year(@dCurrentDateTime))) + '-' +
	+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), month(@dCurrentDateTime)))) + CONVERT(char(2), month(@dCurrentDateTime))) + '-' +
	+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), day(@dCurrentDateTime)))) + CONVERT(char(2), day(@dCurrentDateTime))) + 'T' +
	+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(hh, @dCurrentDateTime)))) + CONVERT(char(2), datepart(hh,@dCurrentDateTime))) + ':' +
	+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(mi, @dCurrentDateTime)))) + CONVERT(char(2), datepart(mi,@dCurrentDateTime))) + ':' +
	+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(ss, @dCurrentDateTime)))) + CONVERT(char(2), datepart(ss,@dCurrentDateTime))) + '.0Z'


	Select  @sFromDateFilter = RTRIM( CONVERT(char(4), year(@dtFromDateFilter))) + '-' +
	+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), month(@dtFromDateFilter)))) + CONVERT(char(2), month(@dtFromDateFilter))) + '-' +
	+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), day(@dtFromDateFilter)))) + CONVERT(char(2), day(@dtFromDateFilter))) + 'T' +
	+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(hh, @dtFromDateFilter)))) + CONVERT(char(2), datepart(hh,@dtFromDateFilter))) + ':' +
	+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(mi, @dtFromDateFilter)))) + CONVERT(char(2), datepart(mi,@dtFromDateFilter))) + ':' +
	+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(ss, @dtFromDateFilter)))) + CONVERT(char(2), datepart(ss,@dtFromDateFilter))) + '.0Z'

	If @nErrorCode = 0
	Begin
		-- Get Filename
		-- Check if a stored procedure exists first:
		SET @sSQLString = "Select @sFileNameSP = DM.DESTINATIONSP 
								from LETTER L
								JOIN DELIVERYMETHOD DM ON DM.DELIVERYID = L.DELIVERYID
								WHERE L.LETTERNO = @nLetterNo"

		Exec @nErrorCode=sp_executesql @sSQLString,
					N'@sFileNameSP nvarchar(60) OUTPUT,
					@nLetterNo int',
					@sFileNameSP = @sFileNameSP	OUTPUT,
					@nLetterNo = @nLetterNo

		If NOT (@sFileNameSP = '' or @sFileNameSP is null)
		Begin 
			exec @sFileNameSP 
			@pnCaseId = null, 
			@pnLetterNo = @nLetterNo, 
			@pbCalledFromCentura = 0,
			@pnActivityId = @nActivityId,
			@prsDestinationDirectory = @sDestinationDirectory OUTPUT,
			@prsDestinationFile = @sFileName OUTPUT
			
			If (right(rtrim(@sDestinationDirectory), 1) != '\') and (@sDestinationDirectory != '' and @sDestinationDirectory is not null)
			Begin
				set @sDestinationDirectory = @sDestinationDirectory + '\'
			End
		End

		If (@sFileName = '' or @sFileName is null)
		Begin
			-- No stored proc defined. Default the filename.
			Set @sFileName = @sSenderReqType + '~' + @sReceiver + '~' + @sSenderRequestIdentifier + '.xml'	
		End
	End

	set @sSQLString = "
		Select 		
		(Select
			DD.SENDERREQUESTTYPE as 'SenderRequestType',
			'"+ @sSenderRequestIdentifier +"' as 'SenderRequestIdentifier',
			'" + @sSender + "' as 'Sender',
			'1.1' as 'SenderXSDVersion',
			(Select 
				'CPA Inprotech' as 'SenderSoftwareName',
				SC.COLCHARACTER as 'SenderSoftwareVersion'
				from SITECONTROL SC WHERE CONTROLID = 'DB Release Version' 
		   	for XML PATH('SenderSoftware'), TYPE
			),
			'" + @sFileName + "' as 'SenderFilename', 
			'" + @sSenderProducedDateTime + "' as 'SenderProducedDateTime'
	   	for XML PATH('SenderDetails'), TYPE
		),
		(Select 
			DR.DESCRIPTION as 'ReceiverRequestIdentifier',
			ISNULL(NA.ALIAS, NAME.NAMECODE) as 'Receiver',
			-- SQA16935 get recipient main email if document request main mail does not exist 
			RTRIM(ISNULL(DRE.EMAIL, TELE.TELECOMNUMBER)) as 'ReceiverEmail',
				(Select RTRIM(EMAIL) as 'ReceiverCopyToEmail'
				from DOCUMENTREQUESTEMAIL
				Where REQUESTID = " + CAST(@nDocRequestId as nvarchar) + " 
				and ISMAIN != 1
				for XML PATH (''), TYPE),
			(SELECT TC.USERCODE from TABLECODES TC where TABLETYPE = 137 AND TABLECODE = DR.OUTPUTFORMATID) as 'OutputFormat'
			for XML PATH('ReceiverDetails'), TYPE
		),
		(Select null, --<TransactionSummaryDetails>
			(Select 'Event Group' as 'CountTypeCode',
			isnull(TC.USERCODE, '') as 'CountCode',
			TC.DESCRIPTION as 'CountDescription',
			isnull(EVENTCOUNT.EVENTCOUNT, 0) as 'Count'
			From (Select TCD.TABLECODE, TCD.USERCODE, TCD.DESCRIPTION 
					From DOCUMENTEVENTGROUP DEG
					Left Join TABLECODES TCD ON (TCD.TABLECODE = DEG.EVENTGROUP)
					Where DEG.REQUESTID = " + cast(@nDocRequestId as nvarchar) + ") as TC
			Left Join
				(Select COUNT(*) as EVENTCOUNT, CE.EVENTGROUP From #CASEEVENTS CEV
					Join EVENTS CE on (CEV.EVENTNO = CE.EVENTNO)
					Group By CE.EVENTGROUP) as EVENTCOUNT
				on EVENTCOUNT.EVENTGROUP = TC.TABLECODE
			for XML PATH('CountSummary'), TYPE),
		(select 'Date Range From' as 'FilterTypeCode',
			'" + CAST(@sFromDateFilter as nvarchar) + "' as 'ValueDateTime'
			for XML PATH('FilterSummary'), TYPE),
		(select 'Date Range To' as 'FilterTypeCode',
			'" + CAST(@sSenderProducedDateTime as nvarchar) + "' as 'ValueDateTime'
			for XML PATH('FilterSummary'), TYPE)
		for XML Path('TransactionSummaryDetails'), TYPE)
		From DOCUMENTREQUEST DR
		Join DOCUMENTDEFINITION DD on (DD.DOCUMENTDEFID = DR.DOCUMENTDEFID)
		Join NAME NAME on (NAME.NAMENO = DR.RECIPIENT)
		Left Join NAMEALIAS NA on (NA.NAMENO = DR.RECIPIENT and NA.ALIASTYPE = '_E')
		Left Join DOCUMENTREQUESTEMAIL DRE on (DRE.REQUESTID = DR.REQUESTID AND DRE.ISMAIN =1)
		-- SQA16935 get recipient main email 	
		Left Join TELECOMMUNICATION TELE ON (NAME.MAINEMAIL = TELE.TELECODE)
		Where DR.REQUESTID = " + CAST(@nDocRequestId as nvarchar ) + "
		for XML PATH('TransactionHeader'), TYPE
		"
	Exec @nErrorCode= sp_executesql @sSQLString
End

-- Consolidate accounting events (after they've been counted)
If @nErrorCode = 0
Begin
	Set @sSQLString = "DELETE CE1"+char(10)+
		"from #CASEEVENTS CE1"+char(10)+
		"join EVENTS E on (E.EVENTNO = CE1.EVENTNO)"+char(10)+
		"where E.ACCOUNTINGEVENTFLAG = 1"+char(10)+
		"and CE1.REMINDEREVENTFLAG != 1"+char(10)+
		"and CE1.ROWID not in (select min(ROWID)"+char(10)+
		"			from #CASEEVENTS CE"+char(10)+
		"			join EVENTS E ON E.EVENTNO = CE.EVENTNO"+char(10)+
		"			where E.ACCOUNTINGEVENTFLAG = 1"+char(10)+
		"			and CE.REMINDEREVENTFLAG != 1"+char(10)+
		"			group by CE.CASEID, CE.EVENTNO, CE.EVENTDATE )"
	exec @nErrorCode = sp_executesql @sSQLString
End


If @nErrorCode = 0
Begin

	Set @sSQLString1 = ""
	Set @sSQLString2 = ""
	Set @sSQLString3 = ""
	Set @sSQLString4 = ""
	Set @sSQLString4A = ""
	Set @sSQLString4B = ""
	Set @sSQLString5 = ""
	Set @sSQLString5A1 = ""
	Set @sSQLString5A = ""
	Set @sSQLString6 = ""
	Set @sSQLStringLast = ""

	-----------------------------------------------------------------------------------------------
	-- Main SQL to generate the XML
	-----------------------------------------------------------------------------------------------
	Set @sSQLString1 = "
	Insert into  "+ @sTempCEFTable +" (ROWID, XMLSTR)
	Select 
	TT.ROWID, 
		(
		Select 	-- <TransactionBody>
		CTI.ROWID as 'TransactionIdentifier',
			(
			Select -- <TransactionContentDetails>
			'Case Events' as 'TransactionCode'
	"

	Set @sSQLString2 = ",
		(
		Select 	-- <CaseDetails>
		"
		if isnull((select colboolean from sitecontrol where controlid ='Mapping Table Control'),0)	=1
			Set @sSQLString2 = @sSQLString2 +"dbo.fn_InternaltoExternal(C.CASEID, "+ cast(@nRecipientNameNo as nvarchar(11)) +", NULL) as 'SenderCaseIdentifier', "
		else
			Set @sSQLString2 = @sSQLString2 +"C.CASEID as 'SenderCaseIdentifier', "
	
		Set @sSQLString2 = @sSQLString2 +		"C.IRN as 'SenderCaseReference',
		C.RECCASEREF as 'ReceiverCaseReference',
		C.CASETYPE_MAP as 'CaseTypeCode',
		C.PROPERTYTYPE_MAP as 'CasePropertyTypeCode',
		C.CASECATEGORY_MAP as 'CaseCategoryCode',
		C.SUBTYPE_MAP as 'CaseSubTypeCode',
		C.BASIS_MAP as 'CaseBasisCode',
		C.COUNTRYCODE as 'CaseCountryCode',
		C.FAMILY as 'Family',
		(Select F.FAMILYTITLE from CASEFAMILY F where F.FAMILY = C.FAMILY) as 'FamilyTitle'
		(select -- <DescriptionDetails>
			'Short Title' as 'DescriptionCode',
			CASES.TITLE as 'DescriptionText' 
			FROM CASES
			Where CASES.CASEID = CTI.CASEID
			for XML PATH('DescriptionDetails'), TYPE),
		(Select 		-- <IdentifierNumberDetails>
			NTV.NUMBERTYPE_CPAXML as 'IdentifierNumberCode',  
			ONS.OFFICIALNUMBER as 'IdentifierNumberText'
			from OFFICIALNUMBERS ONS
			join #NUMBERTYPE_VIEW NTV ON (NTV.NUMBERTYPE_INPRO = ONS.NUMBERTYPE 
										AND NTV.NUMBERTYPE_CPAXML IS NOT NULL)
			join NUMBERTYPES NT on (NT.NUMBERTYPE=ONS.NUMBERTYPE)
			where ONS.CASEID = CTI.CASEID
			and ONS.ISCURRENT = 1
						-- Do not return NON IP Office Official Numbers
						-- if the CEF recipient is an Old Data Instructor
						-- and is also NOT the current Data Instructor
			AND ONS.CASEID NOT IN ( SELECT CN.CASEID 
			                        FROM CASENAME CN
						JOIN #CASESTOINCLUDE C on (C.CASEID    = CN.CASEID
								       and C.CASENAMENO= CN.NAMENO)
						LEFT JOIN CASENAME CN1 on (CN1.CASEID  = CN.CASEID
						                       and CN1.NAMENO  = CN.NAMENO
						                       and CN1.NAMETYPE='DI')
						WHERE isnull(NT.ISSUEDBYIPOFFICE,0)=0
						and CN.NAMETYPE ='DIO'
						and CN1.CASEID is null)
			for XML PATH('IdentifierNumberDetails'), TYPE),
	"

	Set @sSQLString3 = "
		(
		Select	-- <EventDetails>
		CE1.EVENTCODE as 'EventCode',
		replace( convert(nvarchar(10), CE1.EVENTDATE, 111), '/', '-') as 'EventDate', 
		replace( convert(nvarchar(10), CE1.EVENTDUEDATE, 111), '/', '-') as 'EventDueDate',
		CE1.EVENTDESC as 'EventDescription',
		CE1.EVENTTEXT as 'EventText',
		CE1.CYCLE as 'EventCycle',
		A.ACTIONNAME as 'CreatedByAction',
		( -- Charge Details
			Select ChargeDocumentNumber, 
			CURRENCY AS 'ChargeAmount/@currencyCode', 
			round(ChargeAmount,2) as 'ChargeAmount',
			ChargeComment
			From
				(Select OI.OPENITEMNO as 'ChargeDocumentNumber',
				CASE WHEN BL.TOTALFOREIGN = 0 OR BL.TOTALFOREIGN IS NULL THEN SC.COLCHARACTER ELSE isnull(OI.CURRENCY, SC.COLCHARACTER) END as CURRENCY,
				CASE WHEN BL.TOTALFOREIGN = 0 OR BL.TOTALFOREIGN IS NULL THEN BL.TOTALLOCAL ELSE BL.TOTALFOREIGN END as 'ChargeAmount',
				-- SQA17851
				Case when DH.TRANSTYPE = 514 then null when R.DESCRIPTION is not null then R.DESCRIPTION else 'Manual Invoice' end as 'ChargeComment'
				From 
				OPENITEM OI 
				-- Get the total amount by case.
				join (select IRN, ITEMTRANSNO, ITEMENTITYNO,
					sum(VALUE) AS TOTALLOCAL, SUM(FOREIGNVALUE) AS TOTALFOREIGN
					from BILLLINE
					group by IRN, ITEMTRANSNO, ITEMENTITYNO) as BL on (BL.ITEMENTITYNO = OI.ITEMENTITYNO 
																and BL.ITEMTRANSNO = OI.ITEMTRANSNO)
				left join CASES C ON (C.IRN = BL.IRN)
				-- JOIN ON DEBTORHISTORY TO PICK UP THE REASON CODE.
				Left Join DEBTORHISTORY DH ON (DH.REFENTITYNO = OI.ITEMENTITYNO
										AND DH.REFTRANSNO = OI.ITEMTRANSNO
										AND DH.HISTORYLINENO = 1 
										AND DH.STATUS = 1)
				Left Join REASON R ON (R.REASONCODE = DH.REASONCODE),
				SITECONTROL SC
				Where SC.CONTROLID = 'CURRENCY'
				and OI.POSTDATE >= '" + CAST(@dtLastGenerated as nvarchar) + "'
				and OI.POSTDATE >= '" + CAST(@dtEventStart as nvarchar) + "'
				and C.CASEID = CE1.CASEID
				-- JOIN to OPENITEM on the outside
				AND OI.ITEMTRANSNO = OI1.ITEMTRANSNO
				AND OI.ITEMENTITYNO = OI1.ITEMENTITYNO

				Union all

				-- Reminder charges
				Select NULL as 'ChargeDocumentNumber',
				CE2.CURRENCYCODE ,
				CE2.CHARGEAMOUNT ,
				NULL as  'ChargeComment'
				From #CASEEVENTS CE2
				where CE2.REMINDEREVENTFLAG = 1
				and CE2.ROWID = CE1.ROWID )AS TEMPEVENTCHARGES
			for XML PATH('EventChargeDetails'), TYPE 
		)
		from #CASEEVENTS CE1
		left join ACTIONS A on (A.ACTION = CE1.CREATEDBYACTION)
		-- SQA20971   invoice details for accounting events
		left join  #OPENITEMCASEEVENT OI1  on (OI1.CASEID = CE1.CASEID AND OI1.POSTDATE = CE1.EVENTDATE)
		where CE1.CASEID = CTI.CASEID
		and CE1.TRANSFERFLAG = CTI.TRANSFERFLAG
		for XML PATH('EventDetails'), TYPE), "

	Set @sSQLString4 = "
		( -- Event selection continued
		SELECT DISTINCT EXTEVENTS.EventCode,
			EXTEVENTS.EventDate,
			EXTEVENTS.EventDueDate,
			EXTEVENTS.EventText,
			EXTEVENTS.EventCycle,
			EXTEVENTS.AnnuityTerm,
			EXTEVENTS.CreatedByAction,
			EXTEVENTS.EventChargeDetails

			FROM (
			Select -- <EventDetails> NextRenewal for event
			'Next Renewal' as 'EventCode',
			replace( convert(nvarchar(10), CE1.NEXTRENEWALEVENT, 111), '/', '-') as 'EventDate',
			replace( convert(nvarchar(10), CE1.NEXTRENEWALDUEDATE, 111), '/', '-') as 'EventDueDate',
			-- SQA16923 Replace CE1.EVENTTEXT with null
			null as 'EventText',
			CE1.CYCLE as 'EventCycle',
			null as 'AnnuityTerm',

			-- 17761 get CreatedByAction
			(Select A.ACTIONNAME
			from ACTIONS A 
			join CASEEVENT CEX on (CEX.CREATEDBYACTION = A.ACTION) 
			where CEX.CASEID = CE1.CASEID 
			and CEX.CYCLE = CE1.CYCLE
			and CEX.EVENTNO = -11) as 'CreatedByAction',
 
			null as 'EventChargeDetails'
			from #CASEEVENTS CE1
			WHERE CE1.CASEID = CTI.CASEID
			AND (CE1.NEXTRENEWALEVENT IS NOT NULL OR CE1.NEXTRENEWALDUEDATE IS NOT NULL)

			UNION ALL

			Select -- <EventDetails> NextRenewal for CASE
			'Next Renewal' as 'EventCode',
			replace( convert(nvarchar(10), C.NEXTRENEWAL, 111), '/', '-') as 'EventDate',
			replace( convert(nvarchar(10), C.NEXTRENEWALDUEDATE, 111), '/', '-') as 'EventDueDate',
			NULL as 'EventText',
			C.CYCLE as 'EventCycle',
			C.ANNUITYTERM as 'AnnuityTerm', 

			-- 17761 get CreatedByAction
			(Select A.ACTIONNAME
			from ACTIONS A 
			join CASEEVENT CEX on (CEX.CREATEDBYACTION = A.ACTION) 
			where CEX.CASEID = C.CASEID 
			and CEX.CYCLE = C.CYCLE
			and CEX.EVENTNO = -11) as 'CreatedByAction',

			null as 'EventChargeDetails'
			from #CASESTOINCLUDE C
			WHERE C.ROWID = CTI.ROWID
			AND (C.NEXTRENEWAL IS NOT NULL OR C.NEXTRENEWALDUEDATE IS NOT NULL)

	"


	Set @sSQLString4A = "
			UNION ALL

			-- SQA17761 <EventDetails> Next Affidavit for event
			Select 
			'Next Affidavit or Intent to Use' as 'EventCode',
			replace( convert(nvarchar(10), CE1.AFFIDEVENTDATE, 111), '/', '-') as 'EventDate',
			replace( convert(nvarchar(10), CE1.AFFIDEVENTDUEDATE, 111), '/', '-') as 'EventDueDate',
			null as 'EventText',
			CE1.CYCLE as 'EventCycle',
			null as 'AnnuityTerm', 
	" + 
			-- 17761 get CreatedByAction
		case when @nNextAffidEventNo is null then
			" null "  
		else
			" (Select A.ACTIONNAME
			from ACTIONS A 
			join CASEEVENT CEX on (CEX.CREATEDBYACTION = A.ACTION) 
			where CEX.CASEID = CE1.CASEID 
			and CEX.CYCLE = CE1.CYCLE
			and CEX.EVENTNO = " + CAST(@nNextAffidEventNo as nvarchar )+ ")" 
		end + "  as 'CreatedByAction',
	
			null as 'EventChargeDetails'
			from #CASEEVENTS CE1
			left join ACTIONS A on (A.ACTION = CE1.CREATEDBYACTION)
			WHERE CE1.CASEID = CTI.CASEID
			AND (CE1.AFFIDEVENTDATE IS NOT NULL OR CE1.AFFIDEVENTDUEDATE IS NOT NULL)


			UNION ALL

			-- SQA17761 <EventDetails> Next Affidavit for CASE
			Select 
			'Next Affidavit or Intent to Use' as 'EventCode',
			replace( convert(nvarchar(10), C.AFFIDDATE, 111), '/', '-') as 'EventDate',
			replace( convert(nvarchar(10), C.AFFIDDUEDATE, 111), '/', '-') as 'EventDueDate',
			NULL as 'EventText',
			C.AFFIDCYCLE as 'EventCycle',
			C.AFFIDANNUITYTERM as 'AnnuityTerm', 
	" + 
		-- 17761 get CreatedByAction
		case when @nNextAffidEventNo is null then
			" null "  
		else
			" (Select A.ACTIONNAME
			from ACTIONS A 
			join CASEEVENT CEX on (CEX.CREATEDBYACTION = A.ACTION) 
			where CEX.CASEID = C.CASEID 
			and CEX.CYCLE = C.AFFIDCYCLE
			and CEX.EVENTNO = " + CAST(@nNextAffidEventNo as nvarchar )+ ")" 
		end + "  as 'CreatedByAction',

			null as 'EventChargeDetails'
			from #CASESTOINCLUDE C
			WHERE C.ROWID = CTI.ROWID
			AND (C.AFFIDDATE IS NOT NULL OR C.AFFIDDUEDATE IS NOT NULL)

			UNION ALL

			Select -- <EventDetails> Lapse date for CASE
			'Lapse Date' as 'EventCode',
			replace( convert(nvarchar(10), C.LAPSEDATE, 111), '/', '-') as 'EventDate',
			replace( convert(nvarchar(10), C.LAPSEDUEDATE, 111), '/', '-') as 'EventDueDate',
			NULL as 'EventText',
			C.LAPSECYCLE as 'EventCycle',
			NULL as 'AnnuityTerm', 
	" + 
		-- 17761 get CreatedByAction  
		case when @nLapseDateEventNo is null then
			" null "  
		else
			" (Select A.ACTIONNAME
			from ACTIONS A 
			join CASEEVENT CEX on (CEX.CREATEDBYACTION = A.ACTION) 
			where CEX.CASEID = C.CASEID 
			and CEX.CYCLE = C.LAPSECYCLE
			and CEX.EVENTNO = " + CAST(@nLapseDateEventNo as nvarchar )+ ")" 
		end + "  as 'CreatedByAction',

			null as 'EventChargeDetails'
			from #CASESTOINCLUDE C
			WHERE C.ROWID = CTI.ROWID
			AND (C.LAPSEDATE IS NOT NULL OR C.LAPSEDUEDATE IS NOT NULL)
	"

	Set @sSQLString4B = "
			UNION ALL

			-- SQA17761 <EventDetails> Lapse Date Affidavit for CASE  (@nLapseDateAffidEventNo)
			Select  
			'Lapse Date Affidavit' as 'EventCode',
			replace( convert(nvarchar(10), C.AFFIDLAPSEDATE, 111), '/', '-') as 'EventDate',
			replace( convert(nvarchar(10), C.AFFIDLAPSEDUEDATE, 111), '/', '-') as 'EventDueDate',
			NULL as 'EventText',
			C.AFFIDLAPSECYCLE as 'EventCycle',
			NULL as 'AnnuityTerm', 
	" + 
		-- 17761 get CreatedByAction 
		case when @nLapseDateAffidEventNo is null then
			" null "  
		else
			" (Select A.ACTIONNAME
			from ACTIONS A 
			join CASEEVENT CEX on (CEX.CREATEDBYACTION = A.ACTION) 
			where CEX.CASEID = C.CASEID 
			and CEX.CYCLE = C.AFFIDLAPSECYCLE
			and CEX.EVENTNO = " + CAST(@nLapseDateAffidEventNo as nvarchar )+ ")" 
		end + "  as 'CreatedByAction',
 
			null as 'EventChargeDetails'
			from #CASESTOINCLUDE C
			WHERE C.ROWID = CTI.ROWID
			AND (C.AFFIDLAPSEDATE IS NOT NULL OR C.AFFIDLAPSEDUEDATE IS NOT NULL)

			UNION ALL

			Select -- <EventDetails> Expiry date for CASE
			'Expiry' as 'EventCode',
			replace( convert(nvarchar(10), C.EXPIRYDATE, 111), '/', '-') as 'EventDate',
			replace( convert(nvarchar(10), C.EXPIRYDUEDATE, 111), '/', '-') as 'EventDueDate',
			NULL as 'EventText',
			C.EXPIRYCYCLE as 'EventCycle',
			NULL as 'AnnuityTerm', 
	" + 
		-- 17761 get CreatedByAction  
		case when @nExpiryEventNo is null then
			" null "  
		else
			" (Select A.ACTIONNAME
			from ACTIONS A 
			join CASEEVENT CEX on (CEX.CREATEDBYACTION = A.ACTION) 
			where CEX.CASEID = C.CASEID 
			and CEX.CYCLE = C.EXPIRYCYCLE
			and CEX.EVENTNO = " + CAST(@nExpiryEventNo as nvarchar )+ ")" 
		end + "  as 'CreatedByAction',

			null as 'EventChargeDetails'
			From #CASESTOINCLUDE C
			Where C.ROWID = CTI.ROWID
			and (C.EXPIRYDATE is not null OR C.EXPIRYDUEDATE is not null)
		) EXTEVENTS
		for XML PATH('EventDetails'), TYPE )"

	Set @sSQLString5 = ",
    (Select	-- <NameDetails>
    NTV.NAMETYPE_CPAXML as 'NameTypeCode', 
    CN.SEQUENCE as 'NameSequenceNumber',
    CN.REFERENCENO as 'NameReference',
    (
    Select null,  --<AddressBook>
	    (
	    Select null, --<FormattedNameAddress>
		    (
		    Select -- <Name>
		    N.NAMECODE as 'SenderNameIdentifier', 
		    (SELECT TOP 1 FILTEREDMAPPEDNAMES.EXTERNALNAMECODE FROM
			    (
				SELECT COUNT(*) AS ROWCOUNTS, MAX(EXTERNALNAMECODE) AS EXTERNALNAMECODE
				FROM
				(	
					-- Division name
					SELECT top 1 'A' AS SORTORDER, NAL.ALIAS AS EXTERNALNAMECODE
					FROM NAMEALIAS NAL
					WHERE NAL.NAMENO = CN.NAMENO
					and upper(CN.NAMETYPE) IN (SELECT Parameter from #DivisionNameTypes)
					AND NAL.ALIASTYPE = (SELECT COLCHARACTER 
								FROM SITECONTROL 
								WHERE CONTROLID = 'Division Name Alias')
					UNION
					-- Mapped name
					Select 'B' AS SORTORDER, RTRIM(EN.EXTERNALNAMECODE) as EXTERNALNAMECODE
					from EXTERNALNAME EN
					join EXTERNALNAMEMAPPING ENM on (ENM.EXTERNALNAMEID = EN.EXTERNALNAMEID)
					where (ENM.PROPERTYTYPE = C.PROPERTYTYPE OR ENM.PROPERTYTYPE IS NULL)
					and	(ENM.INSTRUCTORNAMENO is null 
						or ENM.INSTRUCTORNAMENO =  (select CN.NAMENO 
										from CASENAME CN 
										where CN.NAMETYPE = 'I' 
										and CN.CASEID = C.CASEID
										and CN.NAMETYPE NOT IN (SELECT Parameter from #DivisionNameTypes )
										)
						)
					and ENM.INPRONAMENO = CN.NAMENO
					and EN.NAMETYPE = CN.NAMETYPE
					and (EN.DATASOURCENAMENO in (select NAMENO from #NAMESINFAMILY)
						OR EN.DATASOURCENAMENO = " + cast(@nRecipientNameNo as nvarchar(11)) + ")"

	Set @sSQLString5A1 = "
					UNION
					-- Original name sent by recipient
					SELECT 'C' AS SORTORDER, SENDERNAMEIDENTIFIER AS EXTERNALNAMECODE
					FROM EDENAME
					WHERE EDENAME.ROWID = (
					    SELECT MAX(EDEN.ROWID)
					    FROM EDECASEDETAILS CD 
					    JOIN EDECASENAMEDETAILS ND ON (ND.TRANSACTIONIDENTIFIER = CD.TRANSACTIONIDENTIFIER
									    AND ND.BATCHNO = CD.BATCHNO)
					    JOIN EDENAME EDEN ON (EDEN.TRANSACTIONIDENTIFIER = ND.TRANSACTIONIDENTIFIER
								    AND EDEN.NAMETYPECODE = ND.NAMETYPECODE
								    AND EDEN.BATCHNO = ND.BATCHNO)
					    JOIN EDESENDERDETAILS EDES ON (EDES.BATCHNO = EDEN.BATCHNO)
					    WHERE ND.NAMETYPECODE_T = CN.NAMETYPE
					    AND ND.NAMETYPECODE_T NOT IN (SELECT Parameter from #DivisionNameTypes )
					    AND EDEN.SENDERNAMEIDENTIFIER IS NOT NULL
					    AND CD.CASEID = CN.CASEID
					    and (EDES.SENDERNAMENO in (select NAMENO from #NAMESINFAMILY)
						OR EDES.SENDERNAMENO = " + cast(@nRecipientNameNo as nvarchar(11)) + ")
					)
				) AS SENDERNAMES
			    GROUP BY SENDERNAMES.SORTORDER
			    ) AS FILTEREDMAPPEDNAMES
		    WHERE ROWCOUNTS=1) as 'ReceiverNameIdentifier',
		    N.TITLE as 'FormattedName/NamePrefix',"

	Set @sSQLString5A = "
		    -- Individual
		    Case when (N.USEDASFLAG & 1 = 1) Then
			    N.TITLE
		    End as 'FormattedName/NamePrefix',

		    Case when (N.USEDASFLAG & 1 = 1) Then
			    Case When (charindex(' ', N.FIRSTNAME) != 0 )
			    Then RTRIM(left(N.FIRSTNAME, charindex(' ', N.FIRSTNAME)))
			    Else N.FIRSTNAME
			    End
		    End as 'FormattedName/FirstName',

		    Case when (N.USEDASFLAG & 1 = 1) Then
			    Case when charindex(' ', N.FIRSTNAME) != 0
			    Then LTRIM(right (N.FIRSTNAME, len(N.FIRSTNAME) - charindex(' ', N.FIRSTNAME)))
			    Else Null 
			    End
		    End as 'FormattedName/MiddleName',

		    Case when (N.USEDASFLAG & 1 = 1) Then
			    Case When (charindex(' ', N.NAME) != 0 )
			    Then RTRIM(left(N.NAME, charindex(' ', N.NAME)))
			    Else N.NAME
			    End
		    End as 'FormattedName/LastName',

		    Case when (N.USEDASFLAG & 1 = 1) then
			    Case when (charindex(' ', N.NAME) != 0)
			    Then Substring(N.NAME, charindex(' ', N.NAME) + 1, 
						    ABS(charindex(' ', N.NAME, charindex(' ', N.NAME) + 1) - (charindex(' ', N.NAME) + 1)))
			    Else NULL
			    End
		    End as 'FormattedName/SecondLastName',

		    Case when (N.USEDASFLAG & 1 = 1) then
       				    Case When charindex(' ', N.NAME, charindex(' ', N.NAME) + 1) > 0 
			    Then right(N.NAME, len(N.NAME) - charindex(' ', N.NAME, charindex(' ', N.NAME) + 1))
			    Else NULL
			    End
		    End as 'FormattedName/NameSuffix',

		    Case IND.SEX 
		    when 'M' then 'Male' 
		    when 'F' then 'Female' 
		    End as 'FormattedName/Gender',

		    -- Organization.
		    Case when not (N.USEDASFLAG & 1 = 1) then
			    N.NAME End as 'FormattedName/OrganizationName'

	    	    from NAME N left join INDIVIDUAL IND on (IND.NAMENO = N.NAMENO)
		    where N.NAMENO = CN.NAMENO 
			for XML PATH('Name'), TYPE) 
	    for XML PATH('FormattedNameAddress'), TYPE)
    for XML PATH('AddressBook'), TYPE)

    From CASENAME CN
    Join #NAMETYPE_VIEW NTV on (NTV.NAMETYPE_INPRO = CN.NAMETYPE and NTV.NAMETYPE_CPAXML is not null)
    Where CN.CASEID = CTI.CASEID
    -- and CN.NAMETYPE IN ('DI', 'DIV', 'I', 'O', 'D')
    and 1 = case 
		-- SQA16605 hide current nametype if case is transferred
		when CTI.TRANSFERFLAG = 1 and CN.NAMETYPE in (select NT.NAMETYPE 
								from NAMETYPE NT 
								where NT.OLDNAMETYPE = CTI.OLDNAMETYPE
								) then 0
		 -- Show old nametype if case is transferred
		when CTI.TRANSFERFLAG = 1 and CN.NAMENO = CTI.CASENAMENO 
			and CN.NAMETYPE in (select NT.OLDNAMETYPE 
						from NAMETYPE NT 
						join DOCUMENTREQUESTACTINGAS DRA on DRA.NAMETYPE = NT.NAMETYPE
						where DRA.REQUESTID =  " + CAST(@nDocRequestId as nvarchar) + " 
						)  then 1 
		-- Hide old nametype if case is NOT transferred
		when CTI.TRANSFERFLAG = 0 and CN.NAMETYPE in (select NT.OLDNAMETYPE 
								from NAMETYPE NT 
								join DOCUMENTREQUESTACTINGAS DRA on DRA.NAMETYPE = NT.NAMETYPE
								where DRA.REQUESTID =  " + CAST(@nDocRequestId as nvarchar) + " 
								) then 0 
		 when CN.NAMETYPE in ('DI', 'DIV', 'I', 'O', 'D') then 1 
		 else 0 end 

    and (	(CN.COMMENCEDATE <= GETDATE() OR CN.COMMENCEDATE is null)
	     and (CN.EXPIRYDATE > GETDATE() OR CN.EXPIRYDATE is null)
	)
    for XML PATH('NameDetails'), TYPE)
    "

	Set @sSQLString6 = ",
		(
		Select -- <GoodsServicesDetails> for International classes 'Nice' 
		'Nice' as 'ClassificationTypeCode',
		(Select null, --<ClassDescriptionDetails>
			(
			Select	 	-- <ClassDescriptionDetails>  
			IC.CLASS as 'ClassNumber'
			From " + @sCaseClassTableName + " IC
			Where IC.CASEID =  C.CASEID
			and IC.CLASSTYPE = 'INT'
			and IC.CLASS is not null
			order by IC.SEQUENCENO
			for XML PATH('ClassDescription'), TYPE
			)
		for XML PATH('ClassDescriptionDetails'), TYPE)
		From  CASES LC
		Where LC.CASEID =  C.CASEID
		and LC.INTCLASSES IS NOT NULL
		for XML PATH('GoodsServicesDetails'), TYPE
	    	),
		( 
		Select -- <GoodsServicesDetails> for Local classes 'Domestic' 
		'Domestic' as 'ClassificationTypeCode',
		(Select null, --<ClassDescriptionDetails>
			( 
				Select	 	-- <ClassDescriptionDetails>  
				IC.CLASS as 'ClassNumber'
				From  " + @sCaseClassTableName + " IC
				Where IC.CASEID =  C.CASEID
				and IC.CLASSTYPE = 'LOC'
				order by IC.SEQUENCENO
				for XML PATH('ClassDescription'), TYPE
			)
		for XML PATH('ClassDescriptionDetails'), TYPE)
	From  CASES LC
	    Where LC.CASEID =  C.CASEID
		and LC.LOCALCLASSES IS NOT NULL
		for XML PATH('GoodsServicesDetails'), TYPE
		)"

	Set @sSQLStringLast = "
					From #CASESTOINCLUDE C
					Where C.ROWID = CTI.ROWID 
					for XML PATH('CaseDetails'), TYPE, root('TransactionData'))
				for XML PATH('TransactionContentDetails'), TYPE)
			from #CASESTOINCLUDE CTI
			Where CTI.ROWID = TT.ROWID
			for XML PATH('TransactionBody'), TYPE
			) as XMLSTR
		from #CASESTOINCLUDE TT"

	If @bDebug = 1
	Begin		
	    PRINT /*--1--*/ + @sSQLString1
	    PRINT /*--2--*/ + @sSQLString2
	    PRINT /*--3--*/ + @sSQLString3
	    PRINT /*--4--*/ + @sSQLString4
	    PRINT /*--4A--*/ + @sSQLString4A
	    PRINT /*--4B--*/ + @sSQLString4B
	    PRINT /*--5--*/ + @sSQLString5
	    PRINT /*--5A1--*/ + @sSQLString5A1
	    PRINT /*--5A--*/ + @sSQLString5A
	    PRINT /*--6--*/ + @sSQLString6
	    PRINT /*--last--*/ + @sSQLStringLast
	End


	If @nErrorCode = 0
	Begin
		exec(@sSQLString1+@sSQLString2+@sSQLString3+@sSQLString4+@sSQLString4A+@sSQLString4B+@sSQLString5+@sSQLString5A1+@sSQLString5A+@sSQLString6+@sSQLStringLast)
		select @nErrorCode=@@error, @nResultExist = @@rowcount
	End
End

-- dl use @@rowcount from the insert statement instead of this query
--If @nErrorCode = 0
--Begin
--	Set @sSQLString = "SELECT @nResultExist = min(ROWID) FROM " + @sTempCEFTable + " where XMLSTR IS NOT NULL"
--
--	exec @nErrorCode=sp_executesql @sSQLString, 
--			N'@nResultExist int OUTPUT',
--			@nResultExist = @nResultExist OUTPUT
--End

-- Don't return anything if there are no results, otherwise the file will not generate (with header data only).
If @nErrorCode = 0 AND @nResultExist > 0
Begin
	SET @sSQLString = "SELECT XMLSTR FROM " + @sTempCEFTable
	exec @nErrorCode=sp_executesql @sSQLString
End

	-- Save the filename into ACTIVIYTYREQUEST table to enable Doc Gen to save the file with the same name
	If @nErrorCode = 0 
	Begin
		-- Reset the locking level before updating database
		set transaction isolation level read committed
		
		BEGIN TRANSACTION
		
		Set @sSQLString="
			Update ACTIVITYREQUEST
			Set FILENAME = @sDestinationDirectory + @sFileName
			Where ACTIVITYID 	= @nActivityId
			and  SQLUSER 		= @sSQLUser
			"
		exec @nErrorCode=sp_executesql @sSQLString,
			N'	@sDestinationDirectory nvarchar(128),
				@sFileName		nvarchar(60),
				@nActivityId	int,
				@sSQLUser		nvarchar(15)',
				@sDestinationDirectory = @sDestinationDirectory,
				@sFileName		= @sFileName,
				@nActivityId	= @nActivityId,
				@sSQLUser		= @sSQLUser

		-- SQA17692 if there are no events to be reported then flag the request to suppress output
		If @nErrorCode = 0 AND @nResultExist = 0
		Begin
			Update AR 
			Set AR.SYSTEMMESSAGE = 'Report Suppressed'
			from ACTIVITYREQUEST AR
			join  DOCUMENTREQUEST DR on DR.REQUESTID = AR.REQUESTID and DR.SUPPRESSWHENEMPTY = 1
			where AR.ACTIVITYID = @nActivityId
			and  AR.SQLUSER 	= @sSQLUser
			
			set @nErrorCode = @@error
		End

		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End

	-- Drop global temporary tables used
	if exists(select * from tempdb.dbo.sysobjects where name = @sCaseClassTableName)
	Begin
		Set @sSQLString = "drop table "+@sCaseClassTableName
		exec sp_executesql @sSQLString
	End
	if exists(select * from tempdb.dbo.sysobjects where name = @sTempCEFTable)
	Begin
		Set @sSQLString = "drop table "+@sTempCEFTable
		exec sp_executesql @sSQLString
	End
	if exists(select * from tempdb.dbo.sysobjects where name = '#CASESTOINCLUDE')
	Begin
		Set @sSQLString = "drop table #CASESTOINCLUDE"
		exec sp_executesql @sSQLString
	End
	if exists(select * from tempdb.dbo.sysobjects where name = '#CASEEVENTS')
	Begin
		Set @sSQLString = "drop table #CASEEVENTS"
		exec sp_executesql @sSQLString
	End


	if exists(select * from tempdb.dbo.sysobjects where name = '#BASIS_VIEW')
	Begin
	    Set @sSQLString = "drop table #BASIS_VIEW"
	    exec sp_executesql @sSQLString
	End
	if exists(select * from tempdb.dbo.sysobjects where name = '#CASECATEGORY_VIEW')
	Begin
	    Set @sSQLString = "drop table #CASECATEGORY_VIEW"
	    exec sp_executesql @sSQLString
	End
	if exists(select * from tempdb.dbo.sysobjects where name = '#CASETYPE_VIEW')
	Begin
	    Set @sSQLString = "drop table #CASETYPE_VIEW"
	    exec sp_executesql @sSQLString
	End
	if exists(select * from tempdb.dbo.sysobjects where name = '#EVENT_VIEW')
	Begin
	    Set @sSQLString = "drop table #EVENT_VIEW"
	    exec sp_executesql @sSQLString
	End
	if exists(select * from tempdb.dbo.sysobjects where name = '#NAMETYPE_VIEW')
	Begin
	    Set @sSQLString = "drop table #NAMETYPE_VIEW"
	    exec sp_executesql @sSQLString
	End
	if exists(select * from tempdb.dbo.sysobjects where name = '#NUMBERTYPE_VIEW')
	Begin
	    Set @sSQLString = "drop table #NUMBERTYPE_VIEW"
	    exec sp_executesql @sSQLString
	End
	if exists(select * from tempdb.dbo.sysobjects where name = '#PROPERTYTYPE_VIEW')
	Begin
	    Set @sSQLString = "drop table #PROPERTYTYPE_VIEW"
	    exec sp_executesql @sSQLString
	End
	if exists(select * from tempdb.dbo.sysobjects where name = '#SUBTYPE_VIEW')
	Begin
	    Set @sSQLString = "drop table #SUBTYPE_VIEW"
	    exec sp_executesql @sSQLString
	End
	if exists(select * from tempdb.dbo.sysobjects where name = '#DivisionNameTypes')
	Begin
	    Set @sSQLString = "drop table #DivisionNameTypes"
	    exec sp_executesql @sSQLString
	End
	if exists(select * from tempdb.dbo.sysobjects where name = '#NAMESINFAMILY')
	Begin
	    Set @sSQLString = "drop table #NAMESINFAMILY"
	    exec sp_executesql @sSQLString
	End


RETURN @nErrorCode
go

GRANT EXECUTE	ON [dbo].[ede_GenerateCEF]	TO PUBLIC
GO