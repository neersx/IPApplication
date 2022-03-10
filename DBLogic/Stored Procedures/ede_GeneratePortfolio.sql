-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_GeneratePortfolio
-----------------------------------------------------------------------------------------------------------------------------
If exists (Select * from dbo.sysobjects where id = object_id(N'[dbo].[ede_GeneratePortfolio]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	Print '**** Drop Stored Procedure dbo.ede_GeneratePortfolio.'
	Drop procedure [dbo].[ede_GeneratePortfolio]
end
Print '**** Creating Stored Procedure dbo.ede_GeneratePortfolio...'
Print ''
GO



SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


CREATE  PROCEDURE [dbo].[ede_GeneratePortfolio] 
		@psXMLActivityRequestRow	ntext, 
		@sXMLFilterCriteria		ntext = null -- Dummy parameter to use for storing ntext data as SQL Server does not allow ntext variable.
AS
-- PROCEDURE :	ede_GeneratePortfolio
-- VERSION :	33
-- DESCRIPTION:	Generate EDE Portfolio file in CPAXML format for a client/agent.
-- COPYRIGHT: 	CPA Software Solutions (Australia) Pty Limited
--
--
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	-----	-------	---------------------------------------------- 
-- 10/04/2007	DL	12331	1	Procedure created
-- 13/08/2007	DL	15059	2	Rename the element <ReceiverOutputFormat> to <OutputFormat>.
-- 20/12/2007	DL	15741	3	Bugs fixing.
-- 14/02/2007	DL	15961	4	Bug fix - <OutputFormat> element should return TABLECODES.USERCODE instead of TABLECODES.DESCRIPTION.
-- 04/03/2008	DL	16053	5	Add attribute sequenceNumber to element <Phone>, <Fax>, <Email>
-- 06/03/2008	DL	16044	6	- Retrieve renewal dates of the current cycle 
--					- add name salutation (SQA16047)
--					- Incorrect FirstName & MiddleName if NAME.FIRSTNAME is a single value.
--					- Change SenderXSDVersion from 1.0 to 1.1 to synchronise with the current CPA-XML version
-- 10/04/2008	DL	16142	7	Exclude name type (DI,I,D) when case is transferred.  Exclude DIO name type if case is non-transferred.
-- 10/04/2008	AT	16049	8	Retrieve Annuity/Term period for Trademarks.
-- 15/04/2008	AT	16049	9	Fixed typo.
-- 18/04/2008	DL	16268	10	Performance enhancement
--					- copy mappings from views to temp tables so that views are only recalcuated once rather then one for each case.
--					- add index to large temp tables.
-- 22/04/2008	AT	16233	11	Derive Division case names.
-- 02/05/2008	AT	16343	12	Include name mappings/batches from names in the same family when deriving case names.
-- 14/05/2008	AT	16384	13	Change retrieval/validation of _E name alias.
-- 04/06/2008	DL	16439	14	- Ensure all mapped events are included in report.
--					- Resolve timeout issue when more than 50000 cases are exported.
-- 16/06/2008	AT	16533	15	Return all parts of phone/fax numbers.
-- 24/06/2008	DL	16577	16	Use old instructor commence date instead of expriry date for transferred cases.
-- 30/06/2008	DL	16625	17	Portfolio is giving an error when there is more than one old DI row for a transferred case
-- 07/07/2008	AT	16533	18	Fix return of phone/fax numbers.
-- 21/10/2008	AT	17022	19	Retrieve recipient's main e-mail into <ReceiverEmail> if document request main email does not exist
-- 18/12/2008	DL	17233	20	Always use event 'APPLICATION' (-4) for displaying event details for associated cases.
-- 12/05/2009	DL	17676	21	Performance enhancement.  Pre-calculate ANNUITYTERM and event cycle, enhance case class parsing process.
-- 05/06/2009	DL	17692	22	Suprress the output report if there are no cases to be reported.
-- 04 Jun 2010	MF	18703	23	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE, ensure these are set to null.
-- 20 Dec 2010	DL	18988	24	Attention of name being incorrectly populated if casename does not have a CORRESPONDNAME.
-- 21 Dec 2010	DL	R9683	24	Cater for a new document request for exporting cases for EDE import in other system.
--								- Ignore NAMETYPE restriction from sitecontrol 'Client Name Types Shown'
--								- Ignore restriction from sitecontrol 'Client Importance'
--								- Only extract the MAIN Phone/Fax/Email
--								- Exclude inherited names for export type.

-- 07 Jul 2011	DL	R10830	25	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 20 Jan 2012  DL	S20161	 26	Fix error for 'FormattedName/MiddleName' if FIRSTNAME contains trailing spaces
-- 20/02/2012	NML	20412	27	Change to map output caseid internal to external ID dbo.fn_InternaltoExternal


-- 11 Dec 2012	MF	R12979	28	When additional filter details are supplied the generated SQL was included in a subselect
--					with no reference to the outer CASEID. The result was that the filter had no impact.
-- 8/12/2012	NML		29	Remove NGB 9999999
-- 31/05/2013	MOS	21484	30	Added @nReceiverNameNo parameter to function dbo.fn_InternaltoExternal
-- 9/9/2015	DL	R51575	31	Include case count in header for Portfolio file
-- 01 Oct 2018	MF	74987	32	Output parameter to csw_ConstructCaseWhere to be nvarchar(max).
-- 11 Jan 2019	DL	DR-46493 33	Add Family and FamilyTitle to CaseDetails.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET ANSI_WARNINGS OFF 


-- Temp table to hold cases to be included in the porfolio file
CREATE TABLE #TEMPCASES(
	ROWID		int identity(1,1),
	CASEID		int,
	STATUS		nvarchar(30) collate database_default,
	PROPERTYTYPE	nvarchar(1) collate database_default,
	COUNTRYCODE	nvarchar(3) collate database_default,
	CPARENEWALDATE	datetime,
	ANNUITYTERM	int
	)
CREATE INDEX X1TEMPCASES ON #TEMPCASES
(
	CASEID
)
 
CREATE INDEX X2TEMPCASES ON #TEMPCASES
(
	ROWID
)

CREATE INDEX X3TEMPCASES ON #TEMPCASES
(
	PROPERTYTYPE, COUNTRYCODE
)
    

-- Temp tables to copy data mappings from views.
-- The report query will use these tables instead of the views to enhance performance 
-- as the views are regenerated each time they are accessed. 
CREATE TABLE #BASIS_VIEW(BASIS_INPRO NVARCHAR(2) collate database_default, BASIS_CPAXML NVARCHAR(50) collate database_default)
CREATE TABLE #CASECATEGORY_VIEW(CASECATEGORY_INPRO NVARCHAR(2) collate database_default, CASECATEGORY_CPAXML NVARCHAR(50) collate database_default)
CREATE TABLE #CASETYPE_VIEW(CASETYPE_INPRO NCHAR(1) collate database_default, CASETYPE_CPAXML NVARCHAR(50) collate database_default)
CREATE TABLE #EVENT_VIEW(EVENT_INPRO INT, EVENT_CPAXML NVARCHAR(50) collate database_default)
CREATE INDEX X1EVENT_VIEW ON #EVENT_VIEW(EVENT_INPRO)
CREATE INDEX X2EVENT_VIEW ON #EVENT_VIEW(EVENT_CPAXML)
CREATE TABLE #NAMETYPE_VIEW(NAMETYPE_INPRO NVARCHAR(3) collate database_default, NAMETYPE_CPAXML NVARCHAR(50) collate database_default)
CREATE TABLE #NUMBERTYPE_VIEW(NUMBERTYPE_INPRO NCHAR(1) collate database_default, NUMBERTYPE_CPAXML NVARCHAR(50) collate database_default)
CREATE TABLE #PROPERTYTYPE_VIEW(PROPERTYTYPE_INPRO NCHAR(1) collate database_default, PROPERTYTYPE_CPAXML NVARCHAR(50) collate database_default)
CREATE TABLE #RELATIONSHIP_VIEW(RELATIONSHIP_INPRO NVARCHAR(3) collate database_default, RELATIONSHIP_CPAXML NVARCHAR(50) collate database_default)
CREATE TABLE #SUBTYPE_VIEW(SUBTYPE_INPRO NVARCHAR(2) collate database_default, SUBTYPE_CPAXML NVARCHAR(50) collate database_default)
CREATE TABLE #TEXTTYPE_VIEW(TEXTTYPE_INPRO NVARCHAR(2) collate database_default, TEXTTYPE_CPAXML NVARCHAR(50) collate database_default)

CREATE TABLE #SiteCtrlClientTextType(Parameter NVARCHAR(255) collate database_default)
CREATE TABLE #SiteCtrlNameTypes(Parameter NVARCHAR(255) collate database_default)
CREATE TABLE #DivisionNameTypes(Parameter NVARCHAR(255) collate database_default)

CREATE TABLE #RecipientNameList(NAMENO INT)
CREATE INDEX X1RecipientNameList ON #RecipientNameList
(
	NAMENO
)

-- SQA17676  precalculate the event cycle for each case event
CREATE TABLE #CASEEVENTCYCLE(CASEID INT, EVENTNO INT, CYCLE INT)
CREATE INDEX X1CASEEVENTCYCLE ON #CASEEVENTCYCLE
(
	CASEID, EVENTNO, CYCLE
)

Declare	
	@hDocument 					int,
	@nActivityId					int,
	@sSQLUser					nvarchar(40),
	@nRequestId					int,

--	@sXMLFilterCriteria nvarchar(max),				-- declared as parameter to allow SP to compile on SQL Server 2000 or older version as nvarchar(MAX) is new variable type.
	@sAdditionalWhereClause				nvarchar(max),


	@dCurrentDateTime 				datetime,
	@sSenderRequestIdentifier			nvarchar(14),
	@sSenderProducedDateTime			nvarchar(22),
	@sSender					nvarchar(30),
	@sReceiver					nvarchar(30),
  	@nCPASchemaId					int,
	@nInproSchemaId					int,
	@sStructureTableName  				nvarchar(50),
	@sInputCode					nvarchar(50),
	@sDataInstructorCode				nvarchar(50),
	@sNumberTypeFileNumber				nvarchar(50),
	@sEventNoChangeOfResponsibility 		nvarchar(50),
	@sOldDataInstructorCode 			nvarchar(3),
	@nReceiverNameNo				int,
	@sReceiverFamilyNamesList				nvarchar(254),

	@sSiteCtrlClientTextType 			nvarchar(254),
	@sSiteCtrlNameTypes 				nvarchar(254),

	@sTempTableCaseClass				nvarchar(100),
	@sTempTablePortfolioXML				nvarchar(100),
	@sTokenisedAddressTableName 			nvarchar(100),
	@sDivisionNameTypes				nvarchar(254),

	@sSQLString 					nvarchar(4000),
	@sSQLString1 					nvarchar(4000),
	@sSQLString2 					nvarchar(4000),
	@sSQLString3 					nvarchar(4000),
	@sSQLString4 					nvarchar(4000),
	@sSQLString4A 					nvarchar(4000),
	@sSQLString5 					nvarchar(4000),
	@sSQLString5A 					nvarchar(4000),
	@sSQLString6 					nvarchar(4000),
	@sSQLString7 					nvarchar(4000),
	@sSQLString8 					nvarchar(4000),
	@sSQLString9 					nvarchar(4000),
	@sSQLString10 					nvarchar(4000),
	@sSQLString11					nvarchar(4000),
	@sSQLString12 					nvarchar(4000),
	@sSQLString13 					nvarchar(4000),
	@sSQLStringLast					nvarchar(4000),
	@bDebug						bit,
	@sAlertXML					nvarchar(250),
	@nErrorCode 					int,

	@sSQLStringFilter				nvarchar (1000),
	@nLastFromRowId					int,
	@nNumberOfCases					int,
	@nClientImportance				int,
	@sDivisionNameAlias				nvarchar(508),
	@sMainRenewalAction				nvarchar(508),
	@nRequestTypeCaseExport			int,				-- If not null indicates document request type is for ‘Case Export for EDE Data Input’ 
	@sSQLTemp						nvarchar (1000),
	@sExcludeInheritedName			nvarchar(1000)


	Set @nErrorCode = 0
	set @bDebug = 0



	-----------------------------------------------------------------------------------------------------------------------------
	-- Only allow stored procedure run if the data base version is >=9 (SQL Server 2005 or later)
	-----------------------------------------------------------------------------------------------------------------------------
	If  (Select left( cast(SERVERPROPERTY('ProductVersion') as varchar), CHARINDEX('.', CAST(SERVERPROPERTY('ProductVersion') as varchar))-1)   ) <= 8
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML("ed2", "This document can only be generated for databases on SQL Server 2005 or later.", null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR
	End
	--------------------------------------------------------------------------------------------------------------------

	-- Collect the key for the Activity Request row that has been passed as an XML parameter using OPENXML functionality.
	If @nErrorCode = 0
	Begin	
		Exec 	sp_xml_preparedocument  @hDocument OUTPUT, @psXMLActivityRequestRow
		Set 	@nErrorCode = @@Error
	End
	

	-- Now select the key from the xml.
	If @nErrorCode = 0
	Begin
	    Set @sSQLString="
	    select
		    @nActivityId = ACTIVITYID,
		    @sSQLUser = SQLUSER,
		    @nRequestId = REQUESTID
		    from openxml(@hDocument,'ACTIVITYREQUEST',2)
		    with (ACTIVITYID int,
				    SQLUSER nvarchar(40),
				    REQUESTID int) "
	    Exec @nErrorCode=sp_executesql @sSQLString,
		    N'	@nActivityId		int		OUTPUT,
			    @sSQLUser		nvarchar(40) 	OUTPUT,
			    @nRequestId		int     	OUTPUT,
	  		    @hDocument		int',
			    @nActivityId	= @nActivityId	OUTPUT,
			    @sSQLUser		= @sSQLUser 	OUTPUT,
		  	    @nRequestId		= @nRequestId	OUTPUT,
		  	    @hDocument 		= @hDocument
	End


	If @nErrorCode = 0	
	Begin	
	    Exec sp_xml_removedocument @hDocument 
	    Set @nErrorCode	  = @@Error
	End

	--------------------------------------------------------------------------------------------------------------------

	-- Use the lowest level of locks on the database
	set transaction isolation level read uncommitted

	--Ensure the Sender exists
	If @nErrorCode = 0	
	Begin	
	    -- Get Sender = _H Alias against HOME NAME CODE 
	    Set @sSQLString="
	    Select @sSender = NA.ALIAS 
				    from SITECONTROL SC
	    join NAMEALIAS NA	on (NA.NAMENO=SC.COLINTEGER
				and NA.ALIASTYPE='_H'
				and NA.COUNTRYCODE  is null
				and NA.PROPERTYTYPE is null)
	    where SC.CONTROLID = 'HOMENAMENO'"

		    exec @nErrorCode=sp_executesql @sSQLString,
				    N'@sSender		nvarchar(30)	OUTPUT',
				      @sSender		= @sSender	OUTPUT

	    If @nErrorCode = 0 and @sSender is null
	    Begin
		Set @sAlertXML = dbo.fn_GetAlertXML("ed11", "There is no valid sender alias against the HOME NAME.  Please set up Alias of type _H against the Name specified in site control HOMENAMENO.", null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR
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


	-- Improve SP performance by getting SITECONTROL values into variables to avoid joining to SITECONTROL 
	If @nErrorCode = 0	
	Begin	
		Select @nClientImportance = COLINTEGER
		from SITECONTROL 
		where CONTROLID = 'Client Importance'
		set @nErrorCode = @@ERROR

		If @nErrorCode = 0	
		Begin	
			Select @sDivisionNameAlias = COLCHARACTER 
			from SITECONTROL 
			where CONTROLID = 'Division Name Alias'
			set @nErrorCode = @@ERROR
		End

		If @nErrorCode = 0	
		Begin	
			Select @sMainRenewalAction = COLCHARACTER 
			from SITECONTROL 
			where CONTROLID = 'Main Renewal Action'
			set @nErrorCode = @@ERROR
		End
	End

	--Ensure the Reveiver exists
	If @nErrorCode = 0	
	Begin	
	    -- Get receiver = _E Alias against the DOCUMENTREQUEST.RECIPIENT
	    Set @sSQLString="
	    Select @sReceiver = isnull(NA.ALIAS,N.NAMECODE),
		   @nReceiverNameNo = N.NAMENO
	    from DOCUMENTREQUEST DR
	    join NAME N			on (N.NAMENO=DR.RECIPIENT)
			Left Join NAMEALIAS NA on (NA.NAMENO = N.NAMENO
					and NA.ALIASTYPE = '_E'
					and NA.COUNTRYCODE  is null
					and NA.PROPERTYTYPE is null)
	    where DR.REQUESTID = @nRequestId"

		    exec @nErrorCode=sp_executesql @sSQLString,
				    N'@sReceiver		nvarchar(30)	OUTPUT,
				      @nReceiverNameNo		int		OUTPUT,
				      @nRequestId		int',
				      @sReceiver = @sReceiver			OUTPUT,
				      @nReceiverNameNo = @nReceiverNameNo 	OUTPUT,
				      @nRequestId = @nRequestId
	End

	-- Get a string of names within the same family
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
			Select @sReceiverFamilyNamesList = Case When @sReceiverFamilyNamesList is null 
							Then CAST(NAMENO AS NVARCHAR(30))
							Else @sReceiverFamilyNamesList + ',' + CAST(NAMENO AS NVARCHAR(30))
							End
			From NAME
			Where FAMILYNO = (SELECT FAMILYNO FROM NAME WHERE NAMENO = @nReceiverNameNo)
			AND FAMILYNO IS NOT NULL"
	
		Exec @nErrorCode = sp_executesql @sSQLString,
						N'@sReceiverFamilyNamesList nvarchar(254) OUTPUT,
						@nReceiverNameNo int',
						@sReceiverFamilyNamesList = @sReceiverFamilyNamesList OUTPUT,
						@nReceiverNameNo = @nReceiverNameNo
		
	End

	-- RFC9683 is the request type is 'Case Export for EDE Data Input'  (@nRequestTypeCaseExport is not null)
	If @nErrorCode = 0	
	Begin
		set @nRequestTypeCaseExport = NULL
		
		Select @nRequestTypeCaseExport = DD.DOCUMENTDEFID
		from DOCUMENTREQUEST DR
		join DOCUMENTDEFINITION DD on DD.DOCUMENTDEFID = DR.DOCUMENTDEFID
		join LETTER L ON L.LETTERNO = DD.LETTERNO
		where DR.REQUESTID = @nRequestId
		and L.MACRO like '%sqlt_ede_case_export.xml%'
		set @nErrorCode = @@ERROR
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
			Set @sSQLString="Insert into #RELATIONSHIP_VIEW (RELATIONSHIP_INPRO, RELATIONSHIP_CPAXML)
			select RELATIONSHIP_INPRO, RELATIONSHIP_CPAXML from RELATIONSHIP_VIEW"
			exec @nErrorCode=sp_executesql @sSQLString
		End
		If @nErrorCode = 0	
		Begin
			Set @sSQLString="Insert into #SUBTYPE_VIEW (SUBTYPE_INPRO, SUBTYPE_CPAXML)
			select SUBTYPE_INPRO, SUBTYPE_CPAXML from SUBTYPE_VIEW"
			exec @nErrorCode=sp_executesql @sSQLString
		End
		If @nErrorCode = 0	
		Begin
			Set @sSQLString="Insert into #TEXTTYPE_VIEW (TEXTTYPE_INPRO, TEXTTYPE_CPAXML)
			select TEXTTYPE_INPRO, TEXTTYPE_CPAXML from TEXTTYPE_VIEW"
			exec @nErrorCode=sp_executesql @sSQLString
		End
	End

	-- Create a temp table to hold XML transaction body data for cases so that each case can be separated by a line break.
	If @nErrorCode = 0	
	Begin
	    -- Generate a unique table name from the newid() 
	    Set @sSQLString="Select @sTempTablePortfolioXML = '##' + replace(newid(),'-','_')"
	    exec @nErrorCode=sp_executesql @sSQLString,
		    N'@sTempTablePortfolioXML nvarchar(100) OUTPUT',
		    @sTempTablePortfolioXML = @sTempTablePortfolioXML OUTPUT

	    -- Note: Need to implement this as dynamic SQL to allow stored procedure to compile on SQL Server older than 2005
	    -- without giving error due to new XML data type.
	    Set @sSQLString="
			    CREATE TABLE "+ @sTempTablePortfolioXML +" (
				    ROWID	int,
				    XMLSTR	XML
				    )"
	    exec @nErrorCode=sp_executesql @sSQLString
	End

	----------------------------------------------------------------------------------------------------------
	-- Determine which cases to include the portfolio file
	----------------------------------------------------------------------------------------------------------
	-- Get all the names associated with the recipient based on the DOCUMENTREQUEST.BELONGINGTOCODE
	If @nErrorCode = 0
	Begin
		-- RFC9683 exclude inherited names for export type.
		set @sExcludeInheritedName = ''
		If @nRequestTypeCaseExport is not null
			set @sExcludeInheritedName = ' and ISNULL(CN.INHERITED, 0) <> 1 '

		Set @sSQLString="
		Select @sSQLString1 = 
		case    when BELONGINGTOCODE = 'R' or  isnull(BELONGINGTOCODE,'') = '' then
			'Insert into  #RecipientNameList  (NAMENO)  
			Select RECIPIENT from DOCUMENTREQUEST where REQUESTID =' + cast( @nRequestId as nvarchar(50)) 
		    when BELONGINGTOCODE = 'RG' then
			'Insert into #RecipientNameList (NAMENO)  
			Select RECIPIENT from DOCUMENTREQUEST where REQUESTID = ' + cast( @nRequestId as nvarchar(50)) + '
			UNION 
			Select distinct CN.NAMENO
			from CASENAME CN
			    where 1=1 " + 
			    @sExcludeInheritedName + " 			    
			    and CN.NAMENO in 
			    (Select N.NAMENO 
			    from NAME N 
			    join NAME N2 ON (N2.FAMILYNO = N.FAMILYNO)
			    where N2.NAMENO = (Select RECIPIENT from DOCUMENTREQUEST where REQUESTID = ' + cast( @nRequestId as nvarchar(50)) +' ))  
			and CN.NAMETYPE in (Select NAMETYPE from DOCUMENTREQUESTACTINGAS DRA	where DRA.REQUESTID = ' + cast( @nRequestId as nvarchar(50)) +' )'
		    when BELONGINGTOCODE = 'RA' then
			'Insert into #RecipientNameList(NAMENO)  
			Select RECIPIENT from DOCUMENTREQUEST where REQUESTID = ' + cast( @nRequestId as nvarchar(50)) + '
			UNION 
			Select distinct CN.NAMENO
			from CASENAME CN
			    where 1=1 " + 
			    @sExcludeInheritedName + " 
			    and CN.NAMENO in 
			    (Select distinct ACN.NAMENO 
			    from ACCESSACCOUNTNAMES ACN
			    join USERIDENTITY UI ON (UI.ACCOUNTID = ACN.ACCOUNTID)
			    where UI.NAMENO = (Select RECIPIENT from DOCUMENTREQUEST where REQUESTID = '+ cast( @nRequestId as nvarchar(50)) + ') )
			and CN.NAMETYPE in (Select NAMETYPE from DOCUMENTREQUESTACTINGAS DRA	where DRA.REQUESTID = ' + cast( @nRequestId as nvarchar(50)) + ' )'
		    end 
		from DOCUMENTREQUEST
		where REQUESTID = @nRequestId"

		exec @nErrorCode=sp_executesql @sSQLString,
		    N'@nRequestId int,
		    @sSQLString1 nvarchar(4000) OUTPUT',
		    @nRequestId = @nRequestId,
		    @sSQLString1 = @sSQLString1 OUTPUT


		If @nErrorCode = 0	
		Begin
			Exec @nErrorCode=sp_executesql @sSQLString1
		End
	End

	-- get additional case/name filter
	If @nErrorCode = 0
	Begin
		-- get the criteria xml
		Set @sSQLString="
			select @sXMLFilterCriteria = XMLFILTERCRITERIA 
			from QUERYFILTER QF
			join DOCUMENTREQUEST DR on (DR.CASEFILTERID = QF.FILTERID)
			where DR.REQUESTID = @nRequestId"
		exec @nErrorCode=sp_executesql @sSQLString,
			N'@nRequestId int,
			@sXMLFilterCriteria  nvarchar(max) OUTPUT',
			@nRequestId = @nRequestId,
			@sXMLFilterCriteria  = @sXMLFilterCriteria  OUTPUT

		-- convert criteria xml to where clause
		If @nErrorCode = 0 and @sXMLFilterCriteria is not null
		Begin
		    exec dbo.csw_ConstructCaseWhere 	@psReturnClause = @sAdditionalWhereClause output,
							@pnFilterGroupIndex = 1,
							@pbCalledFromCentura = 1,		-- BUGGY MUST SET TO 1!
							@ptXMLFilterCriteria = @sXMLFilterCriteria
		    If @nErrorCode = 0 and @sAdditionalWhereClause is not null and datalength(@sAdditionalWhereClause) > 0
			Set @sAdditionalWhereClause = 'and exists (select * ' + @sAdditionalWhereClause + char(10)+'	and	XC.CASEID=C.CASEID)'
		End
	End

	-- and build the query to get cases
	If @nErrorCode = 0 
	Begin	
		Set @sSQLString="
		    Insert into #TEMPCASES (CASEID, PROPERTYTYPE, COUNTRYCODE)
		    Select  distinct CN.CASEID, C.PROPERTYTYPE, C.COUNTRYCODE
		    from  CASENAME CN 
		    join CASES C on (C.CASEID = CN.CASEID)
		    join CASETYPE CT on (CT.CASETYPE = C.CASETYPE)
		    join #RecipientNameList CNLIST on (CNLIST.NAMENO = CN.NAMENO)
			-- exclude draft cases	
		    where CT.ACTUALCASETYPE is null "				
		    + char(10) + " and CN.NAMETYPE in (Select NAMETYPE from DOCUMENTREQUESTACTINGAS DRA	where DRA.REQUESTID = @nRequestId)"
		    + char(10) + COALESCE(@sAdditionalWhereClause, '') 

		exec @nErrorCode=sp_executesql @sSQLString,
		    N'@nRequestId int',
		    @nRequestId = @nRequestId

		set @nNumberOfCases = 	@@ROWCOUNT

--		If @nErrorCode = 0 and @nNumberOfCases = 0 
--		Begin
			-- SQA17692 if there are no cases to report flag the request for suppressed.
--			Set @sAlertXML = dbo.fn_GetAlertXML("ed10", "There are no cases to include in portfolio file for the request.", null, null, null, null, null)
--			RAISERROR(@sAlertXML, 14, 1)
--			Set @nErrorCode = @@ERROR
--		End
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
		Update #TEMPCASES
		Set CPARENEWALDATE = CPARD.CPARENEWALDATE
		From (SELECT convert(datetime,substring(max(convert(char(8),isnull(P.ASATDATE,'18010101'),112)+convert(char(8),isnull(P.NEXTRENEWALDATE,'18010101'),112)),9,8)) AS CPARENEWALDATE
		From CASES C
		Join #TEMPCASES on (#TEMPCASES.CASEID = C.CASEID)
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



	-- Calculate the ANNUITYTERM for eventno -11 (SQA17676)
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update #TEMPCASES 
		Set ANNUITYTERM = 
		(select  Case
			When VP.ANNUITYTYPE=0 AND VP.PROPERTYTYPE = 'T' Then floor(datediff(mm,isnull(CECYCLE1.EVENTDATE,CECYCLE1.EVENTDUEDATE), isnull(CECYCLE2.EVENTDATE,CECYCLE2.EVENTDUEDATE))/12)
			When VP.ANNUITYTYPE=0 AND VP.PROPERTYTYPE != 'T' Then NULL
			When VP.ANNUITYTYPE=1 AND EXPIRYDATE.EVENTDATE IS NOT NULL Then floor(datediff(mm,RENEWALSTART.EVENTDATE, isnull(C.CPARENEWALDATE, NEXTRENEW.EVENTDATE))/12) + ISNULL(VP.OFFSET, 0)
			When VP.ANNUITYTYPE=2 Then OA.CYCLE + isnull(VP.CYCLEOFFSET,0)
			End
			From #TEMPCASES C
			Join VALIDPROPERTY VP	on (VP.PROPERTYTYPE = C.PROPERTYTYPE
						and VP.COUNTRYCODE  = (Select min(VP1.COUNTRYCODE)
									From VALIDPROPERTY VP1
									Where VP1.PROPERTYTYPE=C.PROPERTYTYPE
									and   VP1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
			Left Join (	select MIN(O.CYCLE) as [CYCLE], O.CASEID
					from OPENACTION O
					where O.ACTION= '" + @sMainRenewalAction + "' 
					AND O.CASEID = TC.CASEID
					and O.POLICEEVENTS=1
					group by O.CASEID) OA on (OA.CASEID=C.CASEID)
			Left JOIN CASEEVENT CECYCLE1 ON (CECYCLE1.CASEID = C.CASEID
						and CECYCLE1.EVENTNO = -11
						and CECYCLE1.CYCLE = OA.CYCLE)
			Left JOIN CASEEVENT CECYCLE2 on (CECYCLE2.CASEID = CECYCLE1.CASEID
						and CECYCLE2.EVENTNO = -11
						and CECYCLE2.CYCLE = OA.CYCLE + 1)

			Left Join CASEEVENT RENEWALSTART	on (RENEWALSTART.CASEID = C.CASEID
									and RENEWALSTART.EVENTNO = -9)

			Left Join CASEEVENT NEXTRENEW	on (NEXTRENEW.CASEID = OA.CASEID
					and NEXTRENEW.CASEID = C.CASEID
					and NEXTRENEW.EVENTNO = -11
					and NEXTRENEW.CYCLE=OA.CYCLE)
			Left Join CASEEVENT EXPIRYDATE ON (EXPIRYDATE.CASEID = C.CASEID
						AND EXPIRYDATE.EVENTNO = (SELECT EVENT_INPRO 
						FROM #EVENT_VIEW 
						WHERE EVENT_CPAXML = 'Expiry'))
			where C.CASEID = TC.CASEID)
		FROM #TEMPCASES TC "
		Exec @nErrorCode=sp_executesql @sSQLString	
	End


	-- Calculate the event cycle for each case event (SQA17676)
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Insert into  #CASEEVENTCYCLE (CASEID, EVENTNO, CYCLE) 
		select CE.CASEID, CE.EVENTNO, CE.CYCLE
		from #TEMPCASES TC 
		Join CASEEVENT CE on CE.CASEID = TC.CASEID
		Join (	select MIN(O.CYCLE) as [CYCLE], O.CASEID
			from OPENACTION O
			Join #TEMPCASES TC2 on TC2.CASEID = O.CASEID
			where O.ACTION= '" + @sMainRenewalAction + "' 
			and O.POLICEEVENTS=1
			group by O.CASEID) OA on (OA.CASEID = CE.CASEID and OA.CYCLE = CE.CYCLE)
		where CE.EVENTNO = -11
		union 
		select -- single cycle event
		CE.CASEID, CE.EVENTNO, CE.CYCLE
		from #TEMPCASES TC 
		Join CASEEVENT CE on CE.CASEID = TC.CASEID
		Join #EVENT_VIEW EV on EV.EVENT_INPRO = CE.EVENTNO
		join (	select CE2.CASEID, CE2.EVENTNO
			from #TEMPCASES TC2
			Join CASEEVENT CE2 on CE2.CASEID = TC2.CASEID
			Join #EVENT_VIEW EV on EV.EVENT_INPRO = CE2.EVENTNO
			where CE2.EVENTNO <> -11
			group by CE2.CASEID, CE2.EVENTNO
			having COUNT(*) = 1) CE3 on (CE3.CASEID = CE.CASEID AND  CE3.EVENTNO = CE.EVENTNO)
		where CE.EVENTNO <> -11
		union 
		select -- events with multiple cycles
		distinct CE.CASEID, CE.EVENTNO, CE.CYCLE
		from #TEMPCASES TC 
		Join CASEEVENT CE on CE.CASEID = TC.CASEID
		Join #EVENT_VIEW EV on EV.EVENT_INPRO = CE.EVENTNO
		join (select CE2.CASEID, CE2.EVENTNO
			from #TEMPCASES TC2
			Join CASEEVENT CE2 on CE2.CASEID = TC2.CASEID
			Join #EVENT_VIEW EV on EV.EVENT_INPRO = CE2.EVENTNO
			where CE2.EVENTNO <> -11
			group by CE2.CASEID, CE2.EVENTNO
			having COUNT(*) > 1) CE3 on (CE3.CASEID = CE.CASEID AND  CE3.EVENTNO = CE.EVENTNO)
		join(	select O.CASEID, O.ACTION, O.CRITERIANO, min(O.CYCLE) as CYCLE
			from OPENACTION O
			Join #TEMPCASES TC2 on TC2.CASEID = O.CASEID
			where POLICEEVENTS=1
			group by O.CASEID, O.ACTION, O.CRITERIANO) OA 
					on (OA.CASEID=CE.CASEID
					and OA.ACTION=isnull(CE.CREATEDBYACTION, OA.ACTION))
		join EVENTCONTROL EC on (EC.CRITERIANO=OA.CRITERIANO
				     and EC.EVENTNO=CE.EVENTNO)
		join ACTIONS A on (A.ACTION=OA.ACTION)
		where CE.EVENTNO <> -11   -- exclude next renewal event
		and CE.OCCURREDFLAG<9
		and CE.CYCLE=CASE WHEN(A.NUMCYCLESALLOWED>1) 
				    THEN OA.CYCLE
				    ELSE isnull((select min(CYCLE) 
						    from CASEEVENT CE1 
						    where CE1.CASEID=CE.CASEID 
						    and CE1.EVENTNO=CE.EVENTNO 
						    and CE1.OCCURREDFLAG=0),
						(Select max(CYCLE) 
						    from CASEEVENT CE2 
						    where CE2.CASEID=CE.CASEID 
						    and CE2.EVENTNO=CE.EVENTNO 
						    and CE2.OCCURREDFLAG<9) )
				END -- end case"

		Exec @nErrorCode=sp_executesql @sSQLString	
	End


	-------------------------------------------------------------------------------------------------------
	-- Portfolio HEADER
	-------------------------------------------------------------------------------------------------------
	If @nErrorCode = 0
	Begin
	    -- Get timestamp
	    Select @dCurrentDateTime = getdate()

	    -- Get @sSenderRequestIdentifier as Timestamp in format CCYYMMDDHHMMSS,
	    -- and @sSenderProducedDateTime as Timestamp in format CCYY-MM-DDTHH:MM:SS.0Z  (.0Z is zero not letter O) 
	    Set  @sSenderRequestIdentifier = RTRIM( CONVERT(char(4), year(@dCurrentDateTime))) 
	    + RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), month(@dCurrentDateTime)))) + CONVERT(char(2), month(@dCurrentDateTime)))
	    + RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), day(@dCurrentDateTime)))) + CONVERT(char(2), day(@dCurrentDateTime)))
	    + RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(hh, @dCurrentDateTime)))) + CONVERT(char(2), datepart(hh,@dCurrentDateTime)))
	    + RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(mi, @dCurrentDateTime)))) + CONVERT(char(2), datepart(mi,@dCurrentDateTime)))
	    + RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(ss, @dCurrentDateTime)))) + CONVERT(char(2), datepart(ss,@dCurrentDateTime))) 
    	
	    Set @sSenderProducedDateTime = RTRIM( CONVERT(char(4), year(@dCurrentDateTime))) + '-' +
	    + RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), month(@dCurrentDateTime)))) + CONVERT(char(2), month(@dCurrentDateTime))) + '-' +
	    + RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), day(@dCurrentDateTime)))) + CONVERT(char(2), day(@dCurrentDateTime))) + 'T' +
	    + RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(hh, @dCurrentDateTime)))) + CONVERT(char(2), datepart(hh,@dCurrentDateTime))) + ':' +
	    + RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(mi, @dCurrentDateTime)))) + CONVERT(char(2), datepart(mi,@dCurrentDateTime))) + ':' +
	    + RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(ss, @dCurrentDateTime)))) + CONVERT(char(2), datepart(ss,@dCurrentDateTime))) + '.0Z' 


		-- RFC9683 exclude time component for export type.
		If @nRequestTypeCaseExport is not null
		begin
			set @sSenderProducedDateTime = left(@sSenderProducedDateTime, 10)
			Set @sSQLTemp = "SenderProducedDate"
		end			
		else		
			Set @sSQLTemp = "SenderProducedDateTime"
			
			

	    -- Create transaction header
	    set @sSQLString = "
		Select 		
			(Select  
				DD.SENDERREQUESTTYPE as 'SenderRequestType',
				'"+ @sSenderRequestIdentifier +"' as 'SenderRequestIdentifier',
				'"+ @sSender +"' as 'Sender',
				'1.3' as 'SenderXSDVersion',
				(Select 
					'CPA Inprotech' as 'SenderSoftwareName',
					SC.COLCHARACTER as 'SenderSoftwareVersion'
					from SITECONTROL SC WHERE CONTROLID = 'DB Release Version' 
					for XML PATH('SenderSoftware'), TYPE
				),
				DD.SENDERREQUESTTYPE + '~' + ISNULL(NA.ALIAS, NAME.NAMECODE) + '~' + '" + @sSenderRequestIdentifier + ".XML'  as 'SenderFilename', 
				'"+ @sSenderProducedDateTime +"' as '" + @sSQLTemp + "' 
				for XML PATH('SenderDetails'), TYPE
			),
			(Select 
				DR.DESCRIPTION as 'ReceiverRequestIdentifier',
				ISNULL(NA.ALIAS, NAME.NAMECODE) as 'Receiver',
				-- SQA17022 get recipient main email if document request main mail does not exist 
				RTRIM(ISNULL(DRE.EMAIL, TELE.TELECOMNUMBER)) as 'ReceiverEmail',
				(SELECT TC.USERCODE from TABLECODES TC where TABLETYPE = 137 AND TABLECODE = DR.OUTPUTFORMATID) as 'OutputFormat'
				for XML PATH('ReceiverDetails'), TYPE
			),
			(Select null, --<TransactionSummaryDetails>	-- R51575
				(Select 'Cases' as 'CountTypeCode',
				'Number of Cases included in file' as 'CountDescription',
				" + cast( @nNumberOfCases as nvarchar(13)) + " as 'Count'
				for XML PATH('CountSummary'), TYPE) 
			for XML Path('TransactionSummaryDetails'), TYPE)		    
		    from DOCUMENTREQUEST DR
		    join DOCUMENTDEFINITION DD on (DD.DOCUMENTDEFID = DR.DOCUMENTDEFID)
		    join NAME NAME on (NAME.NAMENO = DR.RECIPIENT)
		    left join NAMEALIAS NA	on (NA.NAMENO = DR.RECIPIENT 
						and NA.ALIASTYPE = '_E'
						and NA.COUNTRYCODE  is null
						and NA.PROPERTYTYPE is null)
		    left join DOCUMENTREQUESTEMAIL DRE on (DRE.REQUESTID = DR.REQUESTID AND DRE.ISMAIN =1)
		    -- SQA17022 get recipient main email 	
		    Left Join TELECOMMUNICATION TELE ON (NAME.MAINEMAIL = TELE.TELECODE)
		    where DR.REQUESTID = " + CAST(@nRequestId as nvarchar ) + "
		    for XML PATH('TransactionHeader'), TYPE
		    "
	    If @bDebug = 1
		    print 'transaction header SQL = ' + @sSQLString

	    exec(@sSQLString)
	    set @nErrorCode=@@error
	End
	


    -------------------------------------------------------------------------------------------------------
    -- Portfolio BODY for cases
    -------------------------------------------------------------------------------------------------------
    If @nErrorCode = 0
    Begin	

	If @bDebug = 1
		print 'create portfolio body.' 


	-----------------------------------------------------------------------------------------------
	-- Prepare data for main SQL which generates the XML
	-----------------------------------------------------------------------------------------------

	set @nCPASchemaId = -3
	set @nInproSchemaId = -1

	-- Get Inprotech Data Instructor code from CPAINPRO STANDARD MAPPING.
	Set @sSQLString = "Select @sDataInstructorCode = EV.CODE 
	from ENCODEDVALUE EV
	join MAPSTRUCTURE MS on MS.STRUCTUREID = EV.STRUCTUREID
	where MS.TABLENAME = 'NAMETYPE'
	and EV.SCHEMEID = @nInproSchemaId 
	and EV.DESCRIPTION = 'DATA INSTRUCTOR'"
	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nInproSchemaId			int,
		  @sDataInstructorCode	nvarchar(50) output',
		  @nInproSchemaId			= @nInproSchemaId,
		  @sDataInstructorCode	= @sDataInstructorCode output


	-- Get the Old Data Instructor
	If @nErrorCode = 0
	Begin		
		Set @sSQLString = "Select @sOldDataInstructorCode = OLDNAMETYPE 
				from NAMETYPE  
				where UPPER(NAMETYPE) = UPPER(@sDataInstructorCode)"
		Exec @nErrorCode=sp_executesql @sSQLString,
			N'@sDataInstructorCode	nvarchar(3),
			  @sOldDataInstructorCode nvarchar(3) output',
			  @sDataInstructorCode = @sDataInstructorCode,
			  @sOldDataInstructorCode	= @sOldDataInstructorCode output
	End



	-- Get Inprotech Official Number code for 'FILE NUMBER' from CPAINPRO STANDARD MAPPING.  
	Set @sSQLString = "Select @sNumberTypeFileNumber = NUMBERTYPE_INPRO
	from #NUMBERTYPE_VIEW 
	where NUMBERTYPE_CPAXML = 'File Number'"
	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@sNumberTypeFileNumber	nvarchar(50) output',
		  @sNumberTypeFileNumber	= @sNumberTypeFileNumber output


	-- Get Inprotech EVENTNO for EVENT 'CHANGE OF RESPONSIBILITY' from CPAINPRO STANDARD MAPPING.
	Set @sSQLString = "Select @sEventNoChangeOfResponsibility = EV.EVENT_INPRO
	from #EVENT_VIEW EV
	where EV.EVENT_CPAXML = 'Change of Responsibility'"
	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@sEventNoChangeOfResponsibility	nvarchar(50) output',
		  @sEventNoChangeOfResponsibility	= @sEventNoChangeOfResponsibility output

	-- Determine Case Status (i.e, Live, Dead, Transferred)
	If @nErrorCode = 0 
	Begin	
/*		Set @sSQLString="
			UPDATE #TEMPCASES
			SET STATUS =
				(Select  case 
					-- Transferred If Receiver is Old Data Instructor, and not Data Instructor or Instructor.
					when exists (select 1 
						    from CASENAME CN 
						    where CN.CASEID = TC.CASEID 
						    and CN.NAMETYPE= '" + @sOldDataInstructorCode + "' 
						    and CN.NAMENO = (Select RECIPIENT from DOCUMENTREQUEST where REQUESTID = " + cast( @nRequestId as nvarchar(50)) +" )   
						    and not exists (select 1 
								    from CASENAME CN2 
								    where CN2.CASEID = CN.CASEID 
								    and CN2.NAMENO = CN.NAMENO
								    and CN2.NAMETYPE in ('I', '" + @sDataInstructorCode + "') ) ) 
						    then 'Transferred'
					when S.LIVEFLAG = 1 then 'Live'
					when isnull(S.LIVEFLAG,0) = 0 then 'Dead'
					end 
				from CASES C 
				left join STATUS S ON ( S.STATUSCODE = C.STATUSCODE )
				where C.CASEID = TC.CASEID)
			from #TEMPCASES TC"
*/

		Set @sSQLString="
			UPDATE TC
			SET STATUS =case 
					-- Transferred If Receiver is Old Data Instructor, and not Data Instructor or Instructor.
					when (CN.NAMENO is not NULL and CN2.NAMENO is null) then 'Transferred'
					when (S.LIVEFLAG = 1)           then 'Live'
					when (isnull(S.LIVEFLAG,0) = 0) then 'Dead'
				    end 
			from #TEMPCASES TC
			join CASES C on (C.CASEID=TC.CASEID)
			left join DOCUMENTREQUEST D on (  D.REQUESTID=@nRequestId)
			left join CASENAME CN       on ( CN.CASEID=C.CASEID
						    and  CN.NAMETYPE=@sOldDataInstructorCode
						    and  CN.NAMENO=D.RECIPIENT)
			left join CASENAME CN2      on (CN2.CASEID=C.CASEID
						    and CN2.NAMETYPE in ('I', @sDataInstructorCode)
						    and CN2.NAMENO=CN.NAMENO)
			left join STATUS S          on (  S.STATUSCODE = C.STATUSCODE )
		"
		if @bDebug = 1
			print @sSQLString

		exec @nErrorCode=sp_executesql @sSQLString,
			N'@nRequestId int,
			  @sOldDataInstructorCode nvarchar(3),
			  @sDataInstructorCode	nvarchar(50)',
			@nRequestId = @nRequestId,
			@sOldDataInstructorCode = @sOldDataInstructorCode,
			@sDataInstructorCode = @sDataInstructorCode
	End


	--Get site control values which determine what data can be extracted.
	 If @nErrorCode = 0
	Begin		
		Set @sSQLString = "Select @sSiteCtrlClientTextType = COLCHARACTER 
				from SITECONTROL S 
				where CONTROLID = 'Client Text Types'"
		Exec @nErrorCode=sp_executesql @sSQLString,
			N'@sSiteCtrlClientTextType	nvarchar(254) output',
			  @sSiteCtrlClientTextType	= @sSiteCtrlClientTextType output

		If @nErrorCode = 0
		Begin	
			Set @sSQLString = "insert into #SiteCtrlClientTextType (Parameter)
			select Parameter from fn_Tokenise( @sSiteCtrlClientTextType, NULL)" 

			Exec @nErrorCode=sp_executesql @sSQLString,
				N'@sSiteCtrlClientTextType	nvarchar(254)',
				  @sSiteCtrlClientTextType	= @sSiteCtrlClientTextType 
		End

			
		If @nErrorCode = 0
		Begin		
			Set @sSQLString = "Select @sSiteCtrlNameTypes = COLCHARACTER 
					from SITECONTROL 
					where CONTROLID =  'Client Name Types Shown'"
			Exec @nErrorCode=sp_executesql @sSQLString,
				N'@sSiteCtrlNameTypes	nvarchar(254) output',
				  @sSiteCtrlNameTypes	= @sSiteCtrlNameTypes output
		End

		If @nErrorCode = 0
		Begin	
			Set @sSQLString = "insert into #SiteCtrlNameTypes (Parameter)
			select Parameter from fn_Tokenise( @sSiteCtrlNameTypes, NULL)" 
			Exec @nErrorCode=sp_executesql @sSQLString,
				N'@sSiteCtrlNameTypes	nvarchar(254)',
				  @sSiteCtrlNameTypes	= @sSiteCtrlNameTypes 
		End


	End



	-- Tokenised case name ADDRESS.STREET1 separated by carriage return character
	If @nErrorCode = 0
	Begin
		-- temp table to hold case name address code
		Create table #TEMPCASENAMEADDRESS (
					CASEID		int,
					NAMENO		int,
					NAMETYPE	nvarchar(3) collate database_default,
					SEQUENCE	int,
					ADDRESSCODE	int
					)
		CREATE INDEX X1TEMPCASENAMEADDRESS ON #TEMPCASENAMEADDRESS
		(
			CASEID
		)
		CREATE INDEX X2TEMPCASENAMEADDRESS ON #TEMPCASENAMEADDRESS
		(
			ADDRESSCODE
		)


		If @nErrorCode = 0
		Begin
			-- List of case name addresses
			-- Rules: Use CASENAME.ADDRESSCODE if it exists, otherwise use default Street address
			-- if name type is Owner or Inventor, otherwise assume is postal address for other name types.
			-- RFC9683 exclude inherited names for export type.
			Set @sSQLString="
				Insert into #TEMPCASENAMEADDRESS ( CASEID, NAMENO, NAMETYPE, SEQUENCE, ADDRESSCODE)
				Select CN.CASEID, CN.NAMENO, CN.NAMETYPE, CN.SEQUENCE,
					Case 	when (CN.ADDRESSCODE is not null) then CN.ADDRESSCODE
	 					when (CN.NAMETYPE in ('O','J')  ) then N.STREETADDRESS
										    else N.POSTALADDRESS
					end as ADDRESSCODE
				from #TEMPCASES TC
				join CASENAME CN on (CN.CASEID = TC.CASEID)
				join NAME N      on (N.NAMENO = CN.NAMENO)
				where 1=1 " + 
				@sExcludeInheritedName

				
			if @bDebug = 1
				print @sSQLString
			exec @nErrorCode=sp_executesql @sSQLString
			
		End
			
		-- Global temp table to hold tokenised ADDRESS.STREET1 separated by carriage return character
		-- This table is used for holding Live Case Name or Processed Name transactions address STREET1.
		If @nErrorCode = 0
		Begin
			-- Generate a unique table name from the newid() 
			Set @sSQLString="Select @sTokenisedAddressTableName = '##' + replace(newid(),'-','_')"
			exec @nErrorCode=sp_executesql @sSQLString,
				N'@sTokenisedAddressTableName nvarchar(100) OUTPUT',
				@sTokenisedAddressTableName = @sTokenisedAddressTableName OUTPUT
		
			-- and create the table	
			If @nErrorCode = 0
			Begin
				Set @sSQLString="
				Create table " + @sTokenisedAddressTableName + "(
							ADDRESSCODE	int,
							ADDRESSLINE	nvarchar(254) collate database_default,
							SEQUENCENUMBER	int
							)"
				Exec @nErrorCode=sp_executesql @sSQLString

				If @nErrorCode = 0
				Begin
					Set @sSQLString="
					CREATE INDEX X1TokeniseAddress ON " + @sTokenisedAddressTableName + " 
					(
						ADDRESSCODE
					) "
					Exec @nErrorCode=sp_executesql @sSQLString
				End

			End
		End


		-- list of distinct addresscode to be tokenised
		If @nErrorCode = 0
		Begin
			-- Load distinct address codes for parsing
			If @nErrorCode = 0
			Begin
				Set @sSQLString="
					Insert into "+ @sTokenisedAddressTableName +"( ADDRESSCODE)
					Select distinct ADDRESSCODE
					from #TEMPCASENAMEADDRESS			"
				exec 	@nErrorCode=sp_executesql @sSQLString
			End
		End

		-- And tokenise case name ADDRESS.STREET1 into multiple lines
 
		If @nErrorCode = 0
		Begin
			Exec @nErrorCode=ede_TokeniseAddressLine @sTokenisedAddressTableName	
		End
	End



	-- Temp table to hold tokenised CASES.LOCALCLASSES and CASES.LOCALCLASSES, which are commas delimited,
	-- for affected cases to be reported.  
	-- Note: This must be a distinct global temp table as table name is passed to another 
	-- stored procedure to tokenise the classes.
	If @nErrorCode = 0
	Begin
		-- Generate a unique table name from the newid() 
		Set @sSQLString="Select @sTempTableCaseClass = '##' + replace(newid(),'-','_')"
		exec @nErrorCode=sp_executesql @sSQLString,
			N'@sTempTableCaseClass nvarchar(100) OUTPUT',
			@sTempTableCaseClass = @sTempTableCaseClass OUTPUT
		

		-- and create the table	
		If @nErrorCode = 0
		Begin
			Set @sSQLString="
			Create table " + @sTempTableCaseClass +" (
						CASEID		int,
						CLASSTYPE	nvarchar(3) collate database_default,
						CLASS		nvarchar(250) collate database_default,
						SEQUENCENO	int
						)"
			Exec @nErrorCode=sp_executesql @sSQLString

			If @nErrorCode = 0
			Begin
				Set @sSQLString="
				CREATE INDEX X1TempTableCaseClass ON " + @sTempTableCaseClass + " 
				(
					CASEID
				) "
				Exec @nErrorCode=sp_executesql @sSQLString
			End

		End

		-- load draft and live cases id into table for parsing case classes
		If @nErrorCode = 0
		Begin		
			Set @sSQLString = "Insert into "+ @sTempTableCaseClass +" (CASEID) 
					Select distinct CASEID 
					from #TEMPCASES"
			Exec @nErrorCode=sp_executesql @sSQLString
		End		


		-- Now tokenise case classes
		If @nErrorCode = 0
		Begin
			Exec @nErrorCode=ede_TokeniseCaseClass @sTempTableCaseClass	
		End
	End



	Set @sSQLString1 = ""
	Set @sSQLString2 = ""
	Set @sSQLString3 = ""
	Set @sSQLString4 = ""
	Set @sSQLString5 = ""
	Set @sSQLString5A = ""
	Set @sSQLString6 = ""
	Set @sSQLString7 = ""
	Set @sSQLString8 = ""
	Set @sSQLString9 = ""
	Set @sSQLString10 = ""
	Set @sSQLString11 = ""
	Set @sSQLString12 = ""
	Set @sSQLString13 = ""
	Set @sSQLStringLast = ""


	-----------------------------------------------------------------------------------------------
	-- Main SQL to generate the XML
	-----------------------------------------------------------------------------------------------
	Set @sSQLString1 = "
	    Insert into "+ @sTempTablePortfolioXML +" (ROWID, XMLSTR)
	    Select 
		TC.ROWID,
		(
		Select 	-- <TransactionBody>
		    TC.ROWID  as 'TransactionIdentifier',
		    (
		    Select 	 -- <TransactionContentDetails>
	    "

	-- RFC9683 if request type is case export.
	If @nRequestTypeCaseExport is not null 
		Set @sSQLString1 = @sSQLString1 + 
					"'Case Import' as 'TransactionCode'"
	else 
		Set @sSQLString1 = @sSQLString1 + 
						"'Case Export' as 'TransactionCode'"

	--
	Set @sSQLString2 = ",
			(
			Select 	-- <TransactionData>
			    null,
			    (	
			    select 	-- <CaseDetails>
			    "
				if isnull((select colboolean from sitecontrol where controlid ='Mapping Table Control'),0)	=1
				begin	
					Set @sSQLString2 = @sSQLString2 +"dbo.fn_InternaltoExternal(C.CASEID, "+ cast(@nReceiverNameNo as nvarchar(15)) +", NULL) as 'SenderCaseIdentifier', "
				end
				else
					Set @sSQLString2 = @sSQLString2 +"C.CASEID as 'SenderCaseIdentifier', "
				
				Set @sSQLString2 = @sSQLString2 +		
				"C.IRN as 'SenderCaseReference', 
				CN_RECEIPIENT.REFERENCENO as 'ReceiverCaseReference',
				CTV.CASETYPE_CPAXML  as 'CaseTypeCode', 
				PTV.PROPERTYTYPE_CPAXML as 'CasePropertyTypeCode', 
				(Select CASECATEGORY_CPAXML from #CASECATEGORY_VIEW where CASECATEGORY_INPRO = C.CASECATEGORY and CASECATEGORY_CPAXML is not null) as 'CaseCategoryCode',
				(Select SUBTYPE_CPAXML from #SUBTYPE_VIEW where SUBTYPE_INPRO = C.SUBTYPE and SUBTYPE_CPAXML is not null) as 'CaseSubTypeCode',
				BV.BASIS_CPAXML as 'CaseBasisCode', 
				isnull(COU.ALTERNATECODE, C.COUNTRYCODE) as 'CaseCountryCode', 
				(Select S.EXTERNALDESC from STATUS S where S.STATUSCODE = C.STATUSCODE) as 'CaseStatus',
				(Select S.EXTERNALDESC from STATUS S join PROPERTY P on (P.RENEWALSTATUS = S.STATUSCODE and P.CASEID = C.CASEID)) as 'CaseRenewalStatus',
				TC.STATUS as 'CaseStatusFlag',
				C.FAMILY as 'Family',
				(Select F.FAMILYTITLE from CASEFAMILY F where F.FAMILY = C.FAMILY) as 'FamilyTitle'
	"

	Set @sSQLString3 = "		
				,(
				Select		-- <DescriptionDetails>
				    TempDesc.DescriptionCode as 'DescriptionCode',
				    TempDesc.DescriptionText as 'DescriptionText'								
				    from					 
				    (	
				    Select 		-- <DescriptionDetails>
					'Short Title' as 'DescriptionCode',
					isnull(C.TITLE, '') as 'DescriptionText'								

				    UNION ALL

				    Select
					distinct TTV.TEXTTYPE_CPAXML as 'DescriptionCode',
					CT.SHORTTEXT as 'DescriptionText'
					from #SiteCtrlClientTextType AS Temp
					join CASETEXT CT ON (CT.TEXTTYPE = Temp.Parameter and CT.CASEID = C.CASEID AND CT.SHORTTEXT IS NOT NULL  ) 
					join #TEXTTYPE_VIEW TTV ON (TTV.TEXTTYPE_INPRO = CT.TEXTTYPE AND TTV.TEXTTYPE_CPAXML IS NOT NULL)
				    ) TempDesc
				    for XML PATH('DescriptionDetails'), TYPE 
				),
				( 
				Select 		-- <IdentifierNumberDetails>
				    -- exclude number type 'FILE NUMBER' if case is transferred
				    NUMBERTYPE_CPAXML as 'IdentifierNumberCode',  
				    OFFICIALNUMBER as 'IdentifierNumberText'
				    from
					(Select 
					    NTV.NUMBERTYPE_CPAXML AS NUMBERTYPE_CPAXML, 
					    ONS.OFFICIALNUMBER  AS OFFICIALNUMBER,
					    ONS.NUMBERTYPE AS NUMBERTYPE, 
					    Case when (TC.STATUS= 'Transferred' and ONS.NUMBERTYPE= COALESCE('"+  @sNumberTypeFileNumber +"', '') )
						    then 0
						    else 1 end as CANDISPLAY 
					    from  OFFICIALNUMBERS ONS
					    join #NUMBERTYPE_VIEW NTV ON (NTV.NUMBERTYPE_INPRO = ONS.NUMBERTYPE AND NTV.NUMBERTYPE_CPAXML IS NOT NULL)
					    where ONS.CASEID = C.CASEID
					    and ONS.ISCURRENT = 1
					) temp
				    where temp.CANDISPLAY = 1
				    for XML PATH('IdentifierNumberDetails'), TYPE
				)
	"

	-- RFC9683 exclude inherited names for export type.
	Set @sExcludeInheritedName = ''
	If @nRequestTypeCaseExport is not null 
		Set @sExcludeInheritedName = ' and ISNULL(TCN.INHERITED, 0) <> 1 '

	--16049 Modified annuity term
	Set @sSQLString4 = ",
				( 
				Select	-- <EventDetails>
				    EV.EVENT_CPAXML as 'EventCode', 
				    replace( convert(nvarchar(10), CE.EVENTDATE, 111), '/', '-') as 'EventDate', 

				    -- For Transferred case, event due date is the OLD DATA INSTRUCTOR COMMENCE DATE WHERE EXPIRY DATE IS NULL
				    case when (COALESCE(TC.STATUS, '') = 'Transferred' and E.EVENTNO = '"+ @sEventNoChangeOfResponsibility + "') then
					(select replace( convert(nvarchar(10), MAX(TCN.COMMENCEDATE), 111), '/', '-') 
						from CASENAME TCN 
						join #RecipientNameList RNL on (RNL.NAMENO = TCN.NAMENO)
						where TCN.CASEID = TC.CASEID " +
						@sExcludeInheritedName + " 
						and TCN.NAMETYPE = '" + @sOldDataInstructorCode + "' )
				    else
					replace( convert(nvarchar(10), CE.EVENTDUEDATE, 111), '/', '-') 
				    end as 'EventDueDate',
				    CE.EVENTTEXT as 'EventText',
				    CE2.CYCLE as 'EventCycle',
				    Case when CE.EVENTNO = -11 THEN TC.ANNUITYTERM  end as 'AnnuityTerm'
					
				    from CASEEVENT CE 
				    Join #CASEEVENTCYCLE CE2 on (CE2.CASEID = CE.CASEID and CE2.EVENTNO = CE.EVENTNO and CE2.CYCLE = CE.CYCLE)
"

	-- RFC9683 if output is for case export then ignore restriction from sitecontrol 'Client Importance'
	If @nRequestTypeCaseExport is not null 
		Set @sSQLTemp = ''
	else		
		Set @sSQLTemp = "and E.IMPORTANCELEVEL >= " + cast(@nClientImportance as nvarchar(10)) 

	Set @sSQLString4A = "
				    join EVENTS E on (E.EVENTNO = CE.EVENTNO)  
				    join #EVENT_VIEW EV on (EV.EVENT_INPRO = CE.EVENTNO AND EV.EVENT_CPAXML is not null)
				    where CE.CASEID = C.CASEID " + 
				    @sSQLTemp + " 
				    -- exclude event ChangeOfResponsibility when status is NOT Transferred
--				    and  1 = (case when (COALESCE(TC.STATUS, '') <> 'Transferred') and
--				    E.EVENTNO = '"+ @sEventNoChangeOfResponsibility + "' then 0 else 1 end )
				    and  1 = (case 
					when (COALESCE(TC.STATUS, '') = 'Transferred') 
						and E.EVENTNO <> '"+ @sEventNoChangeOfResponsibility + "' 
						then 1 
					when (COALESCE(TC.STATUS, '') = 'Transferred') 
						and E.EVENTNO = '"+ @sEventNoChangeOfResponsibility + "' 
						and CE.EVENTDATE = 
							(select MAX(TCN.COMMENCEDATE) 
							from CASENAME TCN 
							join #RecipientNameList RNL on (RNL.NAMENO = TCN.NAMENO)
							where TCN.CASEID = TC.CASEID " +
							@sExcludeInheritedName + "
							and TCN.NAMETYPE = '" + @sOldDataInstructorCode + "' )
						then 1 
					when (COALESCE(TC.STATUS, '') <> 'Transferred') 
						and E.EVENTNO <> '"+ @sEventNoChangeOfResponsibility + "' 
						then 1
					ELSE 0 end )
				    for XML PATH('EventDetails'), TYPE
				)

	"


	Set @sSQLString5 = ",
				( 
	     			Select	-- <NameDetails>
				    NTV.NAMETYPE_CPAXML as 'NameTypeCode', 
				    CN.SEQUENCE as 'NameSequenceNumber',
				    CN.REFERENCENO as 'NameReference',
				    -- SQA15741
				    --(Select CURRENCY from IPNAME IPN where IPN.NAMENO = CN.NAMENO and CN.NAMETYPE in ('I', 'D') ) as 'NameCurrencyCode',
				    case when (CN.NAMETYPE = 'I' or CN.NAMETYPE = 'D') then
					(Select CURRENCY from IPNAME IPN where IPN.NAMENO = CN.NAMENO)
				    end as 'NameCurrencyCode',
				    (
				    Select   --<AddressBook>
					null,
					(
					    Select --<FormattedNameAddress>
						null, 
						(
						Select -- <Name>
						    N.NAMECODE as 'SenderNameIdentifier', 
						    (
							Select top 1 TBL2.EXTERNALNAMECODE
							from
								(select SORTORDER, max(TEMP_EXTERNALNAME.EXTERNALNAMECODE) EXTERNALNAMECODE
								from 
									(
									-- Division name
									SELECT TOP 1 'a' AS SORTORDER, NAL.ALIAS AS EXTERNALNAMECODE
									FROM NAMEALIAS NAL
									WHERE NAL.NAMENO = CN.NAMENO
									and upper(CN.NAMETYPE) IN (SELECT Parameter from #DivisionNameTypes)
									-- todo
									and NAL.ALIASTYPE = '" + @sDivisionNameAlias + "' 
									and NAL.COUNTRYCODE  is null
									and NAL.PROPERTYTYPE is null

									UNION
									Select  top 1 'b' as SORTORDER, EN.EXTERNALNAMECODE
									from EXTERNALNAME EN
									join EXTERNALNAMEMAPPING ENM on (ENM.EXTERNALNAMEID = EN.EXTERNALNAMEID)
									where (ENM.PROPERTYTYPE = C.PROPERTYTYPE OR PROPERTYTYPE IS NULL)
									and (ENM.INSTRUCTORNAMENO is null 
										or ENM.INSTRUCTORNAMENO =  (select CN.NAMENO
														from CASENAME CN 
														where CN.NAMETYPE = 'I'
														and CN.NAMETYPE NOT IN (SELECT Parameter from #DivisionNameTypes)
														and CN.CASEID = C.CASEID) )
									and ENM.INPRONAMENO = CN.NAMENO
									and EN.NAMETYPE = CN.NAMETYPE
									and EN.NAMETYPE NOT IN (SELECT Parameter from #DivisionNameTypes)
									and EN.DATASOURCENAMENO in (" + isnull(@sReceiverFamilyNamesList, cast(@nReceiverNameNo as nvarchar(15))) + ")
									) TEMP_EXTERNALNAME
								group by SORTORDER
								) TBL2
						    ) as 'ReceiverNameIdentifier',"

	Set @sSQLString5A = "
                    				    N.TITLE as 'FormattedName/NamePrefix',

						    -- NAME.USEDASFLAG & 1 = 1 is Individual, else Organization.
						    Case when ( (N.USEDASFLAG & 1 = 1) and (charindex(' ', N.FIRSTNAME)=0)) then
							    N.FIRSTNAME
							when ( (N.USEDASFLAG & 1 = 1) and (charindex(' ', N.FIRSTNAME)>0)) then
							    left (N.FIRSTNAME, charindex(' ', N.FIRSTNAME))
						    end as 'FormattedName/FirstName',
						    -- sqa20161 fix error if FIRSTNAME contains trailing spaces
						    Case when ((N.USEDASFLAG & 1 = 1) and (charindex(' ', LTRIM(RTRIM(N.FIRSTNAME)))>0)) then
							    right (LTRIM(RTRIM(N.FIRSTNAME)), len(LTRIM(RTRIM(N.FIRSTNAME))) - charindex(' ', LTRIM(RTRIM(N.FIRSTNAME))))  
						    end as 'FormattedName/MiddleName',

						    Case when (N.USEDASFLAG & 1 = 1) then
                        				dbo.fn_SplitText(N.NAME, ' ', 1, 1)
						    end as 'FormattedName/LastName',

						    Case when (N.USEDASFLAG & 1 = 1) then
							dbo.fn_SplitText(N.NAME, ' ', 2, 2) 
						    end as 'FormattedName/SecondLastName',  

						    Case when (N.USEDASFLAG & 1 = 1) then
							dbo.fn_SplitText(N.NAME, ' ', 3, 1) 
						    end as 'FormattedName/NameSuffix', 			

						    Case IND.SEX 
							when  'M' then 'Male' 
							when  'F' then 'Female' 
						    end as 'FormattedName/Gender',

						    Case when (N.USEDASFLAG & 1 = 1) 
							-- individual salutation
							then (select FORMALSALUTATION FROM INDIVIDUAL where NAMENO = N.NAMENO)  
							-- Organisation main contact's salutation
							else (select FORMALSALUTATION FROM INDIVIDUAL where NAMENO = N.MAINCONTACT)  
						    end as 'FormattedName/Salutation',

						    Case when not (N.USEDASFLAG & 1 = 1) then
							N.NAME 
						    end as 'FormattedName/OrganizationName'

                    				    from NAME N
						    left join INDIVIDUAL IND on (IND.NAMENO = N.NAMENO)
						    where N.NAMENO = CN.NAMENO 
						    for XML PATH('Name'), TYPE
						)
	"


	Set @sSQLString6 = "		,			
						(
						Select -- <Address>
						    null,
						    (	
						    Select --<FormattedAddress>
						       null,	
						       (		
						       Select  -- <AddressLines>
							  DISTINCT TATN.SEQUENCENUMBER as 'AddressLine/@sequenceNumber', 
							  TATN.ADDRESSLINE as 'AddressLine'
							  from #TEMPCASENAMEADDRESS TCNA
							  join " + @sTokenisedAddressTableName  + " TATN on (TATN.ADDRESSCODE = TCNA.ADDRESSCODE) 
							  where TCNA.CASEID = CN.CASEID 
							  and TCNA.NAMETYPE = CN.NAMETYPE
							  and TCNA.NAMENO = CN.NAMENO
							  and TCNA.SEQUENCE = CN.SEQUENCE
							  ORDER BY TATN.SEQUENCENUMBER 
							  for XML PATH(''), TYPE
						       ),
						       (
						       Select  -- <AddressCity><AddressState>	
							  DISTINCT ADDR.CITY as 'AddressCity', 
							  ADDR.STATE as 'AddressState', 
							  ADDR.POSTCODE as 'AddressPostcode', 
							  isnull(COU.ALTERNATECODE, COU.COUNTRYCODE) as 'AddressCountryCode'
							  from #TEMPCASENAMEADDRESS TCNA
							  join ADDRESS ADDR on (ADDR.ADDRESSCODE = TCNA.ADDRESSCODE)
							  join COUNTRY COU on (COU.COUNTRYCODE = ADDR.COUNTRYCODE)
							  where TCNA.CASEID = CN.CASEID 
							  and TCNA.NAMETYPE = CN.NAMETYPE
							  and TCNA.NAMENO = CN.NAMENO
							  and TCNA.SEQUENCE = CN.SEQUENCE
							  for XML PATH(''), TYPE
						       )
						       for XML PATH('FormattedAddress'), TYPE
						    )
						    for XML PATH('Address'), TYPE
						)
	"

	-- SQA18988 - Attention of name being incorrectly populated
	-- Change MAINCONTACT.NAMENO to MAINCONTACT.MAINCONTACT to populate the name main contact.
	Set @sSQLString7 = "		,			
						(
						Select -- <AttentionOf>
						    N.TITLE as 'FormattedAttentionOf/NamePrefix',  
						    N.FIRSTNAME as 'FormattedAttentionOf/FirstName', 
						    N.NAME as 'FormattedAttentionOf/LastName'
						    from NAME N 
						    where N.NAMENO = (
								Select isnull(CORRESPOND.NAMENO, MAINCONTACT.MAINCONTACT) AS NAMENO
								from CASENAME CN2
								left join NAME CORRESPOND on (CORRESPOND.NAMENO = CN2.CORRESPONDNAME)
								left join NAME MAINCONTACT on (MAINCONTACT.NAMENO = CN2.NAMENO)
								where CN2.CASEID = CN.CASEID 
								and CN2.NAMETYPE = CN.NAMETYPE
								and CN2.NAMENO = CN.NAMENO
								and CN2.SEQUENCE = CN.SEQUENCE 
								)
						    for XML PATH('AttentionOf'), TYPE
						)		
						for XML PATH('FormattedNameAddress'), TYPE
					    )  -- <FormattedNameAddress>
	"

	-- RFC9683 if output is for case export then only extract the MAIN Phone/Fax/Email
	If @nRequestTypeCaseExport is not null 
		Set @sSQLTemp = ' and 1 = 0 '   -- forcing a false condition will result in no result.
	else		
		Set @sSQLTemp = ''

	Set @sSQLString8 = "	,	
					    (
					    Select -- <ContactInformationDetails>
						(Select 
						    SORTORDER as 'Phone/@sequenceNumber',
						    PHONE as 'Phone'
						    from
						    (Select 1 as SORTORDER, dbo.fn_FormatTelecom(1901, TEL.ISD, TEL.AREACODE, TEL.TELECOMNUMBER, TEL.EXTENSION) as 'PHONE' 
							from NAME N
							join TELECOMMUNICATION TEL on (TEL.TELECODE = N.MAINPHONE)
							where NAMENO = CN.NAMENO
						    UNION
						    Select ROW_NUMBER() OVER (order by N.NAMENO ) + 1 as SORTORDER, dbo.fn_FormatTelecom(1901, TEL.ISD, TEL.AREACODE, TEL.TELECOMNUMBER, TEL.EXTENSION) as 'PHONE'
							from NAME N
							join NAMETELECOM NTEL on (NTEL.NAMENO = N.NAMENO and NTEL.TELECODE != N.MAINPHONE)
							join TELECOMMUNICATION TEL on (TEL.TELECODE = NTEL.TELECODE)
							where N.NAMENO = CN.NAMENO " + @sSQLTemp + " 
							and TEL.TELECOMTYPE = 1901
						    ) temp
						    order by SORTORDER
						    for XML PATH(''), TYPE
						),										
                                                	
						(Select 
						    SORTORDER as 'Fax/@sequenceNumber',
						    FAX as 'Fax'
						    from
						    (Select 1 as SORTORDER, dbo.fn_FormatTelecom(1902, TEL.ISD, TEL.AREACODE, TEL.TELECOMNUMBER, TEL.EXTENSION) as 'FAX' 
							from NAME N
							join TELECOMMUNICATION TEL on (TEL.TELECODE = N.FAX)
							where NAMENO = CN.NAMENO
						    UNION
						    Select ROW_NUMBER() OVER (order by N.NAMENO ) + 1 as SORTORDER, dbo.fn_FormatTelecom(1902, TEL.ISD, TEL.AREACODE, TEL.TELECOMNUMBER, TEL.EXTENSION) as 'FAX'
							from NAME N
							join NAMETELECOM NTEL on (NTEL.NAMENO = N.NAMENO and NTEL.TELECODE != N.FAX)
							join TELECOMMUNICATION TEL on (TEL.TELECODE = NTEL.TELECODE)
							where N.NAMENO = CN.NAMENO " + @sSQLTemp + " 
							and TEL.TELECOMTYPE = 1902
						    ) temp
						    order by SORTORDER
						    for XML PATH(''), TYPE
						), 
                                                	
						(Select 
						    SORTORDER as 'Email/@sequenceNumber',
						    EMAIL as 'Email'
						    from
						    (Select 1 as SORTORDER, dbo.fn_FormatTelecom(1903, TEL.ISD, TEL.AREACODE, TEL.TELECOMNUMBER, TEL.EXTENSION) as 'EMAIL'
							from NAME N
							join TELECOMMUNICATION TEL on (TEL.TELECODE = N.MAINEMAIL)
							where NAMENO = CN.NAMENO
						    UNION
						    Select ROW_NUMBER() OVER (order by N.NAMENO ) + 1 as SORTORDER,  dbo.fn_FormatTelecom(1903, TEL.ISD, TEL.AREACODE, TEL.TELECOMNUMBER, TEL.EXTENSION) as 'EMAIL'
							from NAME N
							join NAMETELECOM NTEL on (NTEL.NAMENO = N.NAMENO and NTEL.TELECODE != N.MAINEMAIL)
							join TELECOMMUNICATION TEL on (TEL.TELECODE = NTEL.TELECODE)
							where N.NAMENO = CN.NAMENO " + @sSQLTemp + " 
							and TEL.TELECOMTYPE = 1903
						    ) temp
						    order by SORTORDER
						    for XML PATH(''), TYPE
						) 
						for XML PATH('ContactInformationDetails'), TYPE
					    )		
	"
	If @nRequestTypeCaseExport is not null 
	Begin
		-- RFC9683 exclude inherited names for export type.
		Set @sExcludeInheritedName = ' and ISNULL(CN.INHERITED, 0) <> 1 '
		-- RFC9683 Remove NAMETYPE restriction from sitecontrol 'Client Name Types Shown'
		Set @sSQLTemp = ''
	End
	else Begin
		Set @sExcludeInheritedName = ''
		Set @sSQLTemp = ' join #SiteCtrlNameTypes as VNT on (VNT.Parameter = CN.NAMETYPE) '
	End

	Set @sSQLString9 = "	
					    for XML PATH('AddressBook'), TYPE
					)	-- <AddressBook>
					from CASENAME CN " +
					@sSQLTemp + " 
					join #NAMETYPE_VIEW NTV on (NTV.NAMETYPE_INPRO = CN.NAMETYPE and NTV.NAMETYPE_CPAXML is not null)
					where CN.CASEID = C.CASEID " +
					@sExcludeInheritedName + "
					and  1 = (case 
						-- Exclude NAMETYPE 'OLD DATA INSTRUCTOR (DIO)' when status is NOT Transferred
						when (COALESCE(TC.STATUS, '') <> 'Transferred') 
						and CN.NAMETYPE = 'DIO' 
							then 0 
						-- Enclude NAMETYPE 'DI, I, D' when status is Transferred
						when (COALESCE(TC.STATUS, '') = 'Transferred') 
						and CN.NAMETYPE IN ('DI','I','D') 
							then 0 
						-- Enclude NAMETYPE 'DI0' that are not the recipients when status is Transferred
						when (COALESCE(TC.STATUS, '') = 'Transferred') 
						--and CN.NAMETYPE = 'DIO' and CN.NAMENO <> " + cast(@nReceiverNameNo as nvarchar(15)) + "
						and CN.NAMETYPE = 'DIO' and CN.NAMENO NOT IN ( select NAMENO from #RecipientNameList )
							then 0 
						else 1 end )
					for XML PATH('NameDetails'), TYPE
				    ) -- <NameDetails>
	"

	-- RFC9683 
	-- When exporting related case information for a case where there is no related caseid, 
	-- for the number type use 'A' instead of 'R' for the new export	
	If @nRequestTypeCaseExport is not null 
		Set @sSQLTemp = "					    
						    join  #NUMBERTYPE_VIEW NTV on (NTV.NUMBERTYPE_INPRO = 'A' AND NTV.NUMBERTYPE_CPAXML IS NOT NULL)
					"
	Else					
		Set @sSQLTemp = "					    
						    join  #NUMBERTYPE_VIEW NTV on (NTV.NUMBERTYPE_INPRO = 'R' AND NTV.NUMBERTYPE_CPAXML IS NOT NULL)
					"


	Set @sSQLString10 = " , 
				    ( 
				    Select     	-- <AssociatedCaseDetails>
					RV.RELATIONSHIP_CPAXML as 'AssociatedCaseRelationshipCode', 
					isnull(COU1.ALTERNATECODE, COU2.ALTERNATECODE) as 'AssociatedCaseCountryCode',
					(
					Select     	-- <AssociatedCaseIdentifierNumberDetails>
					    TEMP.NUMBERTYPE as 'IdentifierNumberCode', 
					    TEMP.NUMBERTEXT as 'IdentifierNumberText'
					    from 
					    (
					    Select NTV.NUMBERTYPE_CPAXML as NUMBERTYPE,  
						    OFN.OFFICIALNUMBER as NUMBERTEXT
						    from RELATEDCASE RC2
						    join OFFICIALNUMBERS OFN on (OFN.CASEID = RC.RELATEDCASEID AND OFN.ISCURRENT = 1)
						    join #NUMBERTYPE_VIEW NTV on (NTV.NUMBERTYPE_INPRO = OFN.NUMBERTYPE AND NTV.NUMBERTYPE_CPAXML IS NOT NULL)
						    where RC2.CASEID = RC.CASEID
						    and RC2.RELATIONSHIPNO = RC.RELATIONSHIPNO
						    and RC2.OFFICIALNUMBER is null
						    and OFN.NUMBERTYPE IN ('A', 'R')
					    Union
					    Select 
						    NTV.NUMBERTYPE_CPAXML as NUMBERTYPE, 
						    RC2.OFFICIALNUMBER as NUMBERTEXT
						    from RELATEDCASE RC2 " +
						    @sSQLTemp + " 
						    --join  #NUMBERTYPE_VIEW NTV on (NTV.NUMBERTYPE_INPRO = 'R' AND NTV.NUMBERTYPE_CPAXML IS NOT NULL)
						    where RC2.CASEID = RC.CASEID
						    and RC2.RELATIONSHIPNO = RC.RELATIONSHIPNO
						    and RC2.OFFICIALNUMBER is not null										
					    ) TEMP
					    for XML PATH('AssociatedCaseIdentifierNumberDetails'), TYPE
					)
	"
	-- RFC9683 
	-- When exporting related case information for a case 
	-- the priority date field should be derived from the FROMEVENTNO field on the relationship.
	-- Otherwise use the application date from the event -4. 	
	If @nRequestTypeCaseExport is null 
	Set @sSQLString11 = " , 
					(
					Select     	-- <AssociatedCaseEventDetails>
					    TEMP.EVENTCODE as 'EventCode', 
					    replace( convert(nvarchar(10), TEMP.EVENTDATE, 111), '/', '-') as 'EventDate'
					    from
					    (
					    Select EV.EVENT_CPAXML as EVENTCODE, RC2.PRIORITYDATE as EVENTDATE 
						    from RELATEDCASE RC2
						    join #EVENT_VIEW EV on (EV.EVENT_INPRO = -4 and EV.EVENT_CPAXML is not null)
						    where RC2.CASEID = RC.CASEID
						    and RC2.RELATIONSHIPNO = RC.RELATIONSHIPNO
						    and RC2.OFFICIALNUMBER is not null
						    and RC2.RELATEDCASEID is null
					    Union
					    Select EV.EVENT_CPAXML as EVENTCODE, CE.EVENTDATE as EVENTDATE
						    from RELATEDCASE RC2
						    join CASEEVENT CE on (CE.CASEID = RC2.RELATEDCASEID and CE.EVENTNO = -4)
						    join #EVENT_VIEW EV on (EV.EVENT_INPRO = -4 and EV.EVENT_CPAXML is not null)
						    where RC2.CASEID = RC.CASEID
						    and RC2.RELATIONSHIPNO = RC.RELATIONSHIPNO
						    and RC2.RELATEDCASEID is not null
					    ) TEMP
					    for XML PATH('AssociatedCaseEventDetails'), TYPE
					)
				
					from RELATEDCASE RC
					join #RELATIONSHIP_VIEW RV on (RV.RELATIONSHIP_INPRO = RC.RELATIONSHIP AND RV.RELATIONSHIP_CPAXML is not null)
					left join CASES CA on (CA.CASEID = RC.RELATEDCASEID)
					left join COUNTRY COU1 on (COU1.COUNTRYCODE = CA.COUNTRYCODE) 
					left join COUNTRY COU2 on (COU2.COUNTRYCODE = RC.COUNTRYCODE)
					where RC.CASEID =  C.CASEID
					for XML PATH('AssociatedCaseDetails'), TYPE
				    ) 	-- <AssociatedCaseDetails>
	"
	Else 
		Set @sSQLString11 = " , 
						(
						Select     	-- <AssociatedCaseEventDetails>
							TEMP.EVENTCODE as 'EventCode', 
							replace( convert(nvarchar(10), TEMP.EVENTDATE, 111), '/', '-') as 'EventDate'
							from
							(
							Select EV.EVENT_CPAXML as EVENTCODE, RC2.PRIORITYDATE as EVENTDATE 
								from RELATEDCASE RC2
								--join #EVENT_VIEW EV on (EV.EVENT_INPRO = -4 and EV.EVENT_CPAXML is not null)
								join CASERELATION CR ON (CR.RELATIONSHIP = RC2.RELATIONSHIP)
								join #EVENT_VIEW EV on (EV.EVENT_INPRO = CR.FROMEVENTNO and EV.EVENT_CPAXML is not null)
								where RC2.CASEID = RC.CASEID
								and RC2.RELATIONSHIPNO = RC.RELATIONSHIPNO
								and RC2.OFFICIALNUMBER is not null
								and RC2.RELATEDCASEID is null
							Union
							Select EV.EVENT_CPAXML as EVENTCODE, CE.EVENTDATE as EVENTDATE
								from RELATEDCASE RC2 
								--join CASEEVENT CE on (CE.CASEID = RC2.RELATEDCASEID and CE.EVENTNO = -4)
								--join #EVENT_VIEW EV on (EV.EVENT_INPRO = -4 and EV.EVENT_CPAXML is not null)
								join CASERELATION CR ON (CR.RELATIONSHIP = RC2.RELATIONSHIP)
								join CASEEVENT CE on (CE.CASEID = RC2.RELATEDCASEID and CE.EVENTNO = CR.FROMEVENTNO)
								join #EVENT_VIEW EV on (EV.EVENT_INPRO = CR.FROMEVENTNO and EV.EVENT_CPAXML is not null)
								where RC2.CASEID = RC.CASEID
								and RC2.RELATIONSHIPNO = RC.RELATIONSHIPNO
								and RC2.RELATEDCASEID is not null
							) TEMP
							for XML PATH('AssociatedCaseEventDetails'), TYPE
						)
					
						from RELATEDCASE RC
						join #RELATIONSHIP_VIEW RV on (RV.RELATIONSHIP_INPRO = RC.RELATIONSHIP AND RV.RELATIONSHIP_CPAXML is not null)
						left join CASES CA on (CA.CASEID = RC.RELATEDCASEID)
						left join COUNTRY COU1 on (COU1.COUNTRYCODE = CA.COUNTRYCODE) 
						left join COUNTRY COU2 on (COU2.COUNTRYCODE = RC.COUNTRYCODE)
						where RC.CASEID =  C.CASEID
						for XML PATH('AssociatedCaseDetails'), TYPE
						) 	-- <AssociatedCaseDetails>
		"

	Set @sSQLString12 = ",
				    ( 
				    Select     	-- <GoodsServicesDetails> for International classes 'Nice' 
					'Nice' as 'ClassificationTypeCode',
					( 
					Select     	-- <ClassDescriptionDetails>  
					    null,
					    (
					    Select  -- <ClassDescription>
						IC.CLASS as 'ClassNumber'
						from  " + @sTempTableCaseClass + " IC
						where IC.CASEID =  C.CASEID
						and IC.CLASSTYPE = 'INT'
						and IC.CLASS is not null
						order by IC.SEQUENCENO
						for XML PATH('ClassDescription'), TYPE
					    )
					    for XML PATH('ClassDescriptionDetails'), TYPE
					)  
					from  CASES LC
					where LC.CASEID =  C.CASEID
					and LC.INTCLASSES IS NOT NULL
					for XML PATH('GoodsServicesDetails'), TYPE
				    ),
		     		    ( 
				    Select     	-- <GoodsServicesDetails> for Local classes 'Domestic' 
					'Domestic' as 'ClassificationTypeCode',
					( 
					Select     	-- <ClassDescriptionDetails>  
					    null,
					    (
					    Select	-- <ClassDescription>
						IC.CLASS as 'ClassNumber'
						from  " + @sTempTableCaseClass + " IC
						where IC.CASEID =  C.CASEID
						and IC.CLASSTYPE = 'LOC'
						order by IC.SEQUENCENO
						for XML PATH('ClassDescription'), TYPE
					    )	
					    for XML PATH('ClassDescriptionDetails'), TYPE
					)  
					from  CASES LC
					where LC.CASEID =  C.CASEID
					and LC.LOCALCLASSES IS NOT NULL
					for XML PATH('GoodsServicesDetails'), TYPE
				    )
	"

	-- RFC9683 exclude inherited names for export type.
	Set @sExcludeInheritedName = ''
	If @nRequestTypeCaseExport is not null 
		Set @sExcludeInheritedName = ' and ISNULL(CN.INHERITED, 0) <> 1 '

	Set @sSQLStringLast = "		
				    from CASES C
				    left join(Select top 1 REFERENCENO, CASEID
							    FROM CASENAME CN
							    join DOCUMENTREQUESTACTINGAS DRA on (DRA.NAMETYPE = CN.NAMETYPE and DRA.REQUESTID = "+ cast(@nRequestId as nvarchar(30)) + " )
							    where CN.CASEID = TC.CASEID " +
							    @sExcludeInheritedName + "
							    and CN.REFERENCENO is NOT NULL) CN_RECEIPIENT on (CN_RECEIPIENT.CASEID = C.CASEID)
				    left join #CASETYPE_VIEW CTV on (CTV.CASETYPE_INPRO = C.CASETYPE and CTV.CASETYPE_CPAXML is not null)
				    left join #PROPERTYTYPE_VIEW PTV on (PTV.PROPERTYTYPE_INPRO = C.PROPERTYTYPE AND PTV.PROPERTYTYPE_CPAXML is not null)
				    left join COUNTRY COU on (COU.COUNTRYCODE = C.COUNTRYCODE)
				    left join PROPERTY P on (P.CASEID = C.CASEID)
				    left join #BASIS_VIEW BV on (BV.BASIS_INPRO = P.BASIS and P.BASIS is not null AND BV.BASIS_CPAXML is not null )
				    where C.CASEID = TC.CASEID
				    for XML PATH('CaseDetails'), TYPE
				)  -- end <CaseDetails>
				for XML PATH('TransactionData'), TYPE
			    ) 	-- end <TransactionData>
			    for XML PATH('TransactionContentDetails'), TYPE
    			)	-- end <TransactionContentDetails>
			for XML PATH(''), ROOT('TransactionBody') 
		    ) as XMLSTR     -- end <TransactionBody>

		    from #TEMPCASES TC
	    "



	If @bDebug = 1
	Begin		
	    PRINT /*--1--*/ + @sSQLString1
	    PRINT /*--2--*/ + @sSQLString2
	    PRINT /*--3--*/ + @sSQLString3
	    PRINT /*--4--*/ + @sSQLString4
	    PRINT /*--4A--*/ + @sSQLString4A
	    PRINT /*--5--*/ + @sSQLString5
	    PRINT /*--5A--*/ + @sSQLString5A
	    PRINT /*--6--*/ + @sSQLString6
	    PRINT /*--7--*/ + @sSQLString7
	    PRINT /*--8--*/ + @sSQLString8
	    PRINT /*--9--*/ + @sSQLString9
	    PRINT /*--10--*/ + @sSQLString10
	    PRINT /*--11--*/ + @sSQLString11
	    PRINT /*--12--*/ + @sSQLString12
	    PRINT /*--13--*/ + @sSQLString13
	    PRINT /*--last--*/ + @sSQLStringLast
	End


--	If @nErrorCode = 0
--	Begin
--	    exec(@sSQLString1+@sSQLString2+@sSQLString3+@sSQLString4+@sSQLString4A+@sSQLString5+@sSQLString5A+@sSQLString6+@sSQLString7+@sSQLString8+@sSQLString9+@sSQLString10+@sSQLString11+@sSQLString12+@sSQLString13+@sSQLStringLast)
--	    set @nErrorCode=@@error
--	End

	-- sqa17676  extracting 1000 rows at a time seems to improve performance
	set @nLastFromRowId = 0
	While @nErrorCode = 0 
	and @nLastFromRowId <= @nNumberOfCases
	Begin

		set @sSQLStringFilter = " WHERE TC.ROWID >= " + CAST(@nLastFromRowId as nvarchar(10)) + 
								" and TC.ROWID < " + CAST(@nLastFromRowId + 1000 as nvarchar(10) )
		If @bDebug = 1
			print /*--filter--*/ @sSQLStringFilter

	        exec(@sSQLString1+@sSQLString2+@sSQLString3+@sSQLString4+@sSQLString4A+@sSQLString5+@sSQLString5A+@sSQLString6+@sSQLString7+@sSQLString8+@sSQLString9+@sSQLString10+@sSQLString11+@sSQLString12+@sSQLString13+@sSQLStringLast+@sSQLStringFilter)
	        set @nErrorCode=@@error

		set @nLastFromRowId = @nLastFromRowId + 1000

		If @bDebug = 1
			PRINT 'inserted next 1000 rows into XML BODY'
	End
    End  /* transactions body*/


    --Return XML BODY.  
    If @nErrorCode = 0	
    Begin	
	-- separate transaction header and details with line break
	Select char(13)+char(10)

	Set @sSQLString="
	Select CAST(XMLSTR as nvarchar(max)) + char(13)+char(10)
		from  " + @sTempTablePortfolioXML +"
		order by ROWID
		"
	exec @nErrorCode=sp_executesql @sSQLString
    End


    BEGIN TRANSACTION	

    -- Save the filename into ACTIVYTYREQUEST table to enable centura to use the same file name when saving
    If @nErrorCode = 0 
    Begin
	Set @sSQLString="
		Update ACTIVITYREQUEST 
		set FILENAME = 
			(Select  
			DD.SENDERREQUESTTYPE + '~' + ISNULL(NA.ALIAS, NAME.NAMECODE) + '~' + @sSenderRequestIdentifier + '.XML'
			from DOCUMENTREQUEST DR
			join DOCUMENTDEFINITION DD on (DD.DOCUMENTDEFID = DR.DOCUMENTDEFID)
			join NAME NAME on (NAME.NAMENO = DR.RECIPIENT)
			left join NAMEALIAS NA	on (NA.NAMENO = DR.RECIPIENT 
						and NA.ALIASTYPE = '_E'
						and NA.COUNTRYCODE  is null
						and NA.PROPERTYTYPE is null)
			where DR.REQUESTID = @nRequestId
			)
		where ACTIVITYID 	= @nActivityId
		and  SQLUSER 		= @sSQLUser
		"
	exec @nErrorCode=sp_executesql @sSQLString,
		N'	@sSenderRequestIdentifier	nvarchar(14),
			@nRequestId			int,
			@nActivityId			int,
			@sSQLUser			nvarchar(40)',
			@sSenderRequestIdentifier	= @sSenderRequestIdentifier,
			@nRequestId 			= @nRequestId,
			@nActivityId			= @nActivityId,
			@sSQLUser			= @sSQLUser

	If @nErrorCode = 0 and @nNumberOfCases = 0 
	Begin
		-- SQA17692 if there are no cases to report flag the request to be suppressed.
		Update AR 
		Set AR.SYSTEMMESSAGE = 'Report Suppressed'
		from ACTIVITYREQUEST AR
		join  DOCUMENTREQUEST DR on DR.REQUESTID = AR.REQUESTID and DR.SUPPRESSWHENEMPTY = 1
		where AR.ACTIVITYID = @nActivityId
		and  AR.SQLUSER 	= @sSQLUser
		set @nErrorCode = @@ERROR
	End

    End


    If @nErrorCode = 0
	COMMIT TRANSACTION
    Else
	ROLLBACK TRANSACTION


    -- Drop global temporary table used
    if exists(select * from tempdb.dbo.sysobjects where name = @sTempTableCaseClass)
    Begin
	    Set @sSQLString = "drop table "+@sTempTableCaseClass
	    exec sp_executesql @sSQLString
    End
    if exists(select * from tempdb.dbo.sysobjects where name = @sTempTablePortfolioXML)
    Begin
	    Set @sSQLString = "drop table "+@sTempTablePortfolioXML
	    exec sp_executesql @sSQLString
    End
    if exists(select * from tempdb.dbo.sysobjects where name = @sTokenisedAddressTableName)
    Begin
	    Set @sSQLString = "drop table "+@sTokenisedAddressTableName
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
    if exists(select * from tempdb.dbo.sysobjects where name = '#RELATIONSHIP_VIEW')
    Begin
	    Set @sSQLString = "drop table #RELATIONSHIP_VIEW"
	    exec sp_executesql @sSQLString
    End
    if exists(select * from tempdb.dbo.sysobjects where name = '#SUBTYPE_VIEW')
    Begin
	    Set @sSQLString = "drop table #SUBTYPE_VIEW"
	    exec sp_executesql @sSQLString
    End
    if exists(select * from tempdb.dbo.sysobjects where name = '#TEXTTYPE_VIEW')
    Begin
	    Set @sSQLString = "drop table #TEXTTYPE_VIEW"
	    exec sp_executesql @sSQLString
    End




    RETURN @nErrorCode



GO


GRANT EXECUTE	 on [dbo].[ede_GeneratePortfolio]	TO PUBLIC
GO