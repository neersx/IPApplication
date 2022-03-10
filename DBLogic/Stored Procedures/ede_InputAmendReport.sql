-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_InputAmendReport
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ede_InputAmendReport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ede_InputAmendReport.'
	Drop procedure [dbo].[ede_InputAmendReport]
End
Print '**** Creating Stored Procedure dbo.ede_InputAmendReport...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE	PROCEDURE dbo.ede_InputAmendReport 
		@psXMLActivityRequestRow	ntext,
		@sInputAmendXML			ntext=null	-- This is for storing ntext data as SQL Server 2000 does not allow ntext variable. Always place at the end.
AS
-- PROCEDURE :	ede_InputAmendReport 
-- VERSION :	51
-- DESCRIPTION:	Builds the Action Report
-- CALLED BY :	SQLTemplates (sqlt_ede_InputAmendReport.xml)
-- COPYRIGHT: 	Copyright 1993 - 2013 CPA Software Solutions (Australia) Pty Limited
--
-- MODIFICATIONS :
-- Date		Who	SQA	Version	Change
-- ------------	-------	-----	-------	----------------------------------------------- 
-- 23/03/2007	vql	12302	1	Procedure created
-- 28/05/2007	vql	12302	2	Fixed bugs.
-- 29/05/2007	vql	12302	3	Fix filter for employee report.
-- 20/06/2007	vql	14912	4	Fix report name so that it does not have spaces in them.
-- 13/08/2007	vql	15140	5	Bugs for Input Amend and Address Report.
-- 28/08/2007	vql	15190	6	The Address Line Column Should Only Show the Address.
-- 28/08/2007	vql	15142	7	Input Amend report: Add two new columns to the Existing Case Updates tab.
-- 29/08/2007	vql	15141	8	Input Amend Report Group Name Changes into 1 line.
-- 18/10/2007	vql	15318	9	Import Amend Report Does not Show All Cases When Created via Batch Processing
-- 10/03/2008	vql	15984	10	InputAmend EDE report is omitting dates included in the Draft Cases and remove Transaction Message.
-- 09/04/2008	vql	16148	11	Input/Amend report - missing columns and descriptions.
-- 10/04/2008	vql	16172	12	Not all information is appearing in Input/Amend report.
-- 19/05/2008	vql	16236	13	Improve performance.
-- 29/05/2008	vql	16372	14	Incorrect main data instructor address.
-- 30/05/2008	vql	16172	15	Not all information is appearing in Input/Amend report (fix and new requirements).
-- 18/06/2008	vql	16456	16	Input/Amend report details not correct when produced as Document Request.
-- 19/06/2008	vql	16323	17	Ad hoc InputAmend report details not appearing.
-- 25/06/2008	vql	16323	18	Allow storage of phone number greater than 50 characters.
-- 10/07/2008	vql	16677	19	EDE Input Amend report Issues.
-- 10/07/2008	vql	16683	20	Input/Amend for EDE batch which uses Alternative Sender not working correctly.
-- 10/07/2008	vql	16323	21	Fix problems where Ad Hoc reports not showing after removing DI filtering. And redo filtering for the different reports.
-- 23/07/2008	vql	16716	22	InputAmend report is not reporting on deletes.
-- 23/07/2008	vql	16747	23	Not all event changes are appearing in InputAmend report.
-- 23/07/2008	vql	16747	24	Bug fixes.
-- 05/08/2008	vql	16795	24	Change the filename of Input Amend when produced from EDE batch.
-- 07/08/2008	vql	16771	25	InputAmend report does not include case name changes.
-- 11/09/2008	vql	16857	26	Include Owner Address Change in Input Amend Report.
-- 19/09/2008	vql	16854	27	Changes to existing address not appearing in Input/Amend.
-- 25/09/2008	vql	16925	28	Change filename for InputAmend Report.
-- 29/10/2008	DL	15028	29	Change filename for InputAmend Report to cater for reversed batch.
-- 11/12/2008	MF	17136	30	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 05/03/2009	vql	17151	31	Check for logging tables existing needs to be case insensitive.
-- 23/03/2009	vql	17514	32	Change in -500 event (Affidavit deadline) does not appear in Input/Amend.
-- 29/05/2009	mf	17748	33	Reduce locking level to ensure other activities are not blocked.
-- 03/06/2009	vql	17692	34	Provide ‘Suppress empty document’ option for Report.
-- 29/06/2009	vql	17816	35	Input and Amend for document request should exclude EDE changes and  InputAmend - Exclude any changes with blank reason for change.
--		       &17832
-- 17/07/2009	vql	17866	34	InputAmend for EDE Batch is reporting on cases that were not included in the batch.
-- 16/09/2009	vql	17978	35	Bug in the stored procedure that generates the input amend report.
-- 04/06/2010	MF	18703	36	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE, ensure these are set to null.
-- 01 Jul 2010	MF	18758 	37	Increase the column size of Instruction Type to allow for expanded list.
-- 01/02/2011	vql	18763	38	Add NRD and Next Affidavit columns to Input/Amend and Action Report.
-- 02/02/2011	vql	16686	39	Add Data Instructor columns to Input Amend Report.
-- 15/02/2011	vql	17324	40	Report on changes to case names, numbers and events on one line.
-- 15/07/2011	vql	19785	41	Changes to Instructor Alternative Reference via EDE not reporting on 1 line.
-- 17/08/2011	vql	19909	42	Unable to produce Input/Amend report efficiently.
-- 21/12/2011	vql	20226	43	Abandon events sometimes not being reported.
-- 19/04/2012	vql	20493	44	Events not being reported for Abandoned cases.
-- 11/09/2012	vql	20822	45	Input/Amend report is not reporting on any case updates.
-- 21/09/2012	DL	R12763	46	Fix collation error by adding 'collate database_default' to character based columns in temp table definition.
-- 24/04/2013	DL	21295	47	Input/Amend report is not including owner changes for some cases
-- 05/07/2013	vql	R13629	48	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 02 Nov 2015	vql	R53910	49	Adjust formatted names logic (DR-15543).
-- 14 Nov 2018  AV  75198/DR-45358	50   Date conversion errors when creating cases and opening names in Chinese DB
-- 19 May 2020	DL	DR-58943 51	Ability to enter up to 3 characters for Number type code via client server	

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare @nErrorCode	int

Declare	@sSQLString	nvarchar(4000)
Declare	@sSQLString2	nvarchar(4000)
Declare	@sSQLWhere	nvarchar(4000)
Declare	@sLocalSQLWhere	nvarchar(4000)

Declare	@sAlertXML	nvarchar(4000)
Declare	@sMissingTables	nvarchar(2000)
Declare	@hDocument 	int	-- handle to the XML parameter.
Declare	@nActivityId	int	-- the activityrequest key.
Declare	@sSQLUser	nvarchar(40)
Declare	@nBatchNo	int
Declare	@nBatchIdentifier	nvarchar(254)
Declare @nRequestId	int	-- key from DOCUMENTREQUEST table.
Declare @nDocRecipient	int	-- the Document Recipient from a WorkBench Doc Request.
Declare @nDataInstructor int	-- the Data Instructor from a Batch Report Request.
Declare @dtLastGenDate	datetime-- the last time the document request was generated and the FROM date to filter reports on.
Declare @dtCurrentDate	datetime-- the current date and the TO date to filter reports on.
Declare @sPropertyType	nchar(2)-- the proeprty type to filter on.
Declare	@nEmployeeNo	int	-- the Staff NameNo from a Ad Hoc Report Request.
Declare	@sActReqFilter	nvarchar(254) -- XML filter for the activity request.
Declare @sFrom		nvarchar(25)
Declare @sTo		nvarchar(25)
Declare	@sFileName	nvarchar(254)
Declare @sDataInstrName	nvarchar(254)
Declare @sEDEIdentifier	nvarchar(10)
Declare @sNameCode	nvarchar(10)
Declare @nHomeNameNo	int
Declare @sEDEActionCode	nvarchar(2)
Declare @bSuppressEmpty	bit
Declare @bRowsToReport	int
Declare @bTransReason	bit
Declare @sBelongingTo	nvarchar(2)
Declare @nRecipientNameFamilyNo	int
Declare @sRecipientGroupNames	nvarchar(4000)


-- SQA17748 Reduce the locking level to avoid blocking other processes
set transaction isolation level read uncommitted

-------------------------------------------------------------------------------------------------
-- declare @sInputAmendXML	nvarchar(max)	-- The XML to return. Use dummy param instead. --
-------------------------------------------------------------------------------------------------

----------------
-- Initialise --
----------------
Set @nErrorCode = 0

If (Select left( cast(SERVERPROPERTY('ProductVersion') as varchar), CHARINDEX('.', CAST(SERVERPROPERTY('ProductVersion') as varchar))-1) ) <= 8
Begin
	-- Check database version. Only allow Input Amend Report to run if the database version is SQL Server 2005.
	Set @sAlertXML = 'This document can only be generated for databases on SQL Server 2005 or later.'
	RAISERROR(@sAlertXML, 17, 1) with SETERROR

	Set @nErrorCode = @@error
End

If @nErrorCode = 0
Begin
	Select @sMissingTables=case
		when (@sMissingTables is not null) then upper(@sMissingTables)+', '+name
		else name
		end
	from sysobjects 
	where upper(name) in ('CASEEVENT_ILOG','CASES_ILOG','NAME_ILOG','CASENAME_ILOG','ADDRESS_ILOG','RELATEDCASE_ILOG','OFFICIALNUMBERS_ILOG')

	If @@rowcount < 7
	Begin
		-- Check database tables. Must be logging these tables for report to run.
		Set @sAlertXML = 'You must log these tables to see all results for this report CASEEVENT,CASES,NAME,CASENAME,ADDRESS,RELATEDCASE,OFFICIALNUMBER.'+
		' Currently you are only logging these tables '+@sMissingTables

		RAISERROR(@sAlertXML, 17, 1)

		Set @nErrorCode = @@error
	End
End

-------------------------------------------------------------------------------
-- Get intial information set up temporary table to story XML to be returned --
-------------------------------------------------------------------------------
If @nErrorCode = 0
Begin
	-- First collect the key for the Activity Request row that has been passed as an XML parameter using OPENXML functionality.
	Exec 	sp_xml_preparedocument  @hDocument OUTPUT, @psXMLActivityRequestRow

	Set 	@nErrorCode = @@error
End

If @nErrorCode = 0
Begin
	-- Now select the key information from the xml.
	Set @sSQLString="
	Select 	@nActivityId = ACTIVITYID,
		@sSQLUser = SQLUSER
	from openxml(@hDocument,'ACTIVITYREQUEST', 2)
	with (ACTIVITYID int, SQLUSER nvarchar(40))"

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nActivityId	int    		OUTPUT,
		  @sSQLUser	nvarchar(40)	OUTPUT,
		  @hDocument	int',
		  @nActivityId	= @nActivityId	OUTPUT,
		  @sSQLUser	= @sSQLUser	OUTPUT,
		  @hDocument 	= @hDocument
End

If @nErrorCode = 0	
Begin	
	-- Remove the internal representation of the XML.
	Exec sp_xml_removedocument @hDocument 

	Set @nErrorCode	  = @@error
End

If @nErrorCode = 0 
Begin
	-- Get the REQUESTID and Document Request recipient and other stuff.
	Set @sSQLString="
	Select 	@nRequestId=A.REQUESTID,
		@nBatchNo=A.BATCHNO,
		@nBatchIdentifier=E.SENDERREQUESTIDENTIFIER,
		@nDocRecipient=D.RECIPIENT,
		@nDataInstructor=E.SENDERNAMENO,
		@dtLastGenDate=D.LASTGENERATED, 
		@dtCurrentDate=getdate( ),
		@sPropertyType=L.PROPERTYTYPE,
		@sActReqFilter=A.XMLFILTER,
		@nEmployeeNo=A.EMPLOYEENO,
		@bSuppressEmpty=D.SUPPRESSWHENEMPTY,
		@sBelongingTo=D.BELONGINGTOCODE
	from ACTIVITYREQUEST A
	left join DOCUMENTREQUEST D on (D.REQUESTID = A.REQUESTID)
	join LETTER L on (L.LETTERNO = A.LETTERNO)
	left join EDESENDERDETAILS E on (E.BATCHNO = A.BATCHNO)
	where A.ACTIVITYID = @nActivityId"

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nRequestId		int    		OUTPUT,
		  @nDocRecipient	int	    	OUTPUT,
		  @nDataInstructor	int		OUTPUT,
		  @dtLastGenDate	datetime	OUTPUT,
		  @dtCurrentDate	datetime	OUTPUT,
		  @sPropertyType	nchar(2)	OUTPUT,
		  @nBatchNo		int	    	OUTPUT,
		  @sActReqFilter	nvarchar(254)  	OUTPUT,
		  @nEmployeeNo		int	    	OUTPUT,
		  @nBatchIdentifier	nvarchar(254)	OUTPUT,
		  @bSuppressEmpty	bit	    	OUTPUT,
		  @sBelongingTo		nvarchar(2)	OUTPUT,
		  @nActivityId	int',
		  @nRequestId	=@nRequestId	OUTPUT,
		  @nDocRecipient=@nDocRecipient OUTPUT,
		  @nDataInstructor=@nDataInstructor OUTPUT,
		  @dtLastGenDate=@dtLastGenDate OUTPUT,
		  @dtCurrentDate=@dtCurrentDate OUTPUT,
		  @sPropertyType=@sPropertyType OUTPUT,
		  @nBatchNo	=@nBatchNo	OUTPUT,
		  @sActReqFilter=@sActReqFilter	OUTPUT,
		  @nEmployeeNo	=@nEmployeeNo	OUTPUT,
		  @nBatchIdentifier=@nBatchIdentifier OUTPUT,
		  @bSuppressEmpty=@bSuppressEmpty OUTPUT,
		  @sBelongingTo=@sBelongingTo	OUTPUT,
		  @nActivityId	=@nActivityId
End

If @nErrorCode = 0 and @sActReqFilter is not null
Begin
	-- Parse the XML in @sActReqFilter.
	Exec sp_xml_preparedocument  @hDocument OUTPUT, @sActReqFilter

	Set @nErrorCode = @@Error
End

If @nErrorCode = 0 and @sActReqFilter is not null
Begin
	-- Now select the filter information from the xml.
	Set @sSQLString="
	Select 	@sFrom=FromDate,
		@sTo=ToDate
	from openxml(@hDocument,'FilterCriteria',2)
	with (FromDate nvarchar(254), ToDate nvarchar(254))"

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@sFrom	nvarchar(25)	OUTPUT,
		  @sTo		nvarchar(25)	OUTPUT,
		  @hDocument	int',
		  @sFrom	= @sFrom	OUTPUT,
		  @sTo		= @sTo		OUTPUT,
		  @hDocument 	= @hDocument
End

If @nErrorCode = 0 and @sActReqFilter is not null
Begin	
	-- Remove the internal representation of the XML.
	Exec sp_xml_removedocument @hDocument 

	Set @nErrorCode	  = @@error
End

If @nErrorCode = 0
Begin
	-- Get the HomeNameNo.
	Set @sSQLString="
	Select @nHomeNameNo = COLINTEGER
	from SITECONTROL
	where CONTROLID='HOMENAMENO'"
	
	exec @nErrorCode=sp_executesql @sSQLString,
				N'@nHomeNameNo	int	OUTPUT',
				  @nHomeNameNo 	=@nHomeNameNo	OUTPUT
End

If @nErrorCode = 0
Begin
	-- Get the EDE Action Code first.
	Set @sSQLString="
	Select @sEDEActionCode=COLCHARACTER
	from SITECONTROL
	where CONTROLID = 'Input Amend EDE Action'"
	
	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@sEDEActionCode 	nvarchar(2)		OUTPUT',
		  @sEDEActionCode	=@sEDEActionCode	OUTPUT
End

If @nErrorCode = 0
Begin
	-- Get the Transaction Reason Site Control.
	Set @sSQLString="
	Select @bTransReason=COLBOOLEAN
	from SITECONTROL
	where CONTROLID = 'Transaction Reason'"
	
	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@bTransReason bit OUTPUT',
		  @bTransReason=@bTransReason	OUTPUT
End

If @nErrorCode = 0
Begin
	-- Create a tempory table to store XML.
	-- Note this xml data type will compile in SQL 2000 but will not run on SQL 2000.
	Create table #XMLTEMPTABLE
	(
		XMLSTR	xml
	)

	Set @nErrorCode = @@Error
End

----------------------------------------------
-- Get the stuff for the Input/Amend Report --
----------------------------------------------
Declare @nReportNameNo	int	-- the person the report will be addressed to.

If @nEmployeeNo is not null
Begin
	-- If the employee is specified make him the person on report.
	Set @nReportNameNo=@nEmployeeNo
End
Else if @nDocRecipient is not null
Begin
	-- If the doc recipient is specified make him the person on report.
	Set @nReportNameNo=@nDocRecipient
End
Else if @nDataInstructor is not null
Begin
	-- If the data instructor is specified make him the person on report.
	Set @nReportNameNo=@nDataInstructor
End

If @nErrorCode = 0
Begin
	-- Get the name for file name.
	Set @sSQLString="
	Select @sDataInstrName=isnull(dbo.fn_FormatNameUsingNameNo(N.NAMENO, null), N.NAME),
	@sEDEIdentifier=NA.ALIAS, @sNameCode=N.NAMECODE
	from NAME N
	left join NAMEALIAS NA	on (NA.NAMENO = N.NAMENO 
				and NA.ALIASTYPE = '_E'
				and NA.COUNTRYCODE  is null
				and NA.PROPERTYTYPE is null)
	where N.NAMENO = @nReportNameNo"

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@sDataInstrName   nvarchar(254) OUTPUT,
		  @sEDEIdentifier   nvarchar(10) OUTPUT,
		  @sNameCode	    nvarchar(10) OUTPUT,
		  @nReportNameNo    int',
		  @sDataInstrName   =@sDataInstrName OUTPUT,
		  @sEDEIdentifier   =@sEDEIdentifier OUTPUT,
		  @sNameCode	    =@sNameCode OUTPUT,
		  @nReportNameNo    =@nReportNameNo
End

If @nErrorCode = 0
Begin
	-- Construct a where clause for all data going into the report.
	-- If the BATCHNO is not null then the request has come from the Batch Processing program.
	-- Filter on BATCHNO done separately.
	-- If @nRequestId is null and @nEmployeeNo is not null then request has come from names program.
	-- Otherwise we filter on last generated date and the current date.
	If @nRequestId is null and @nEmployeeNo is not null
	Begin
		-- Determine the USERID from the @nEmployeeNo provided.
		Declare @sUsers 	nvarchar(1000)
		Declare @sIdentity	nvarchar(1000)

		Select @sUsers=isnull(nullif(@sUsers+',',','),'')+"'"+U.USERID+"'"
		from USERIDENTITY UI
		join USERS U on (U.USERID=UI.LOGINID)
		where UI.NAMENO=@nEmployeeNo

		Select @sIdentity=isnull(nullif(@sIdentity+',',','),'')+convert(nvarchar,UI.IDENTITYID)
		from USERIDENTITY UI
		where UI.NAMENO=@nEmployeeNo

		If @sUsers is not null
		Begin
			Set @sSQLWhere=@sSQLWhere+char(10)+"substring(L1.LOGUSERID, charindex('\',L1.LOGUSERID) + 1, len(L1.LOGUSERID)- charindex('\',L1.LOGUSERID)) in ("+@sUsers+")"
		End
		Else If @sIdentity is null
		Begin
			Set @sSQLWhere=@sSQLWhere+char(10)+"L1.LOGUSERID <> L1.LOGUSERID"
		End

		If @sIdentity is not null
		Begin
			If @sUsers is not null
			Begin
				Set @sSQLWhere=@sSQLWhere+char(10)+"and (L1.LOGIDENTITYID in ("+@sIdentity+") or L1.LOGIDENTITYID is null)"
			End
			Else
			Begin
				Set @sSQLWhere=@sSQLWhere+char(10)+"and L1.LOGIDENTITYID in ("+@sIdentity+")"
			End
		End

		If @sActReqFilter is not null
		Begin
			If @sFrom is not null
			Begin
				Set @sSQLWhere=@sSQLWhere+char(10)+"and dbo.fn_DateOnly(L1.LOGDATETIMESTAMP) >= "+"'"+@sFrom+"'"
			End
			If @sTo is not null
			Begin
				Set @sSQLWhere=@sSQLWhere+char(10)+"and dbo.fn_DateOnly(L1.LOGDATETIMESTAMP) <= "+"'"+@sTo+"'"
			End
		End
	End
	Else
	Begin	
		Set @sSQLWhere="L1.LOGDATETIMESTAMP <= "+"'"+convert(nvarchar(25), @dtCurrentDate, 21)+"'"
		If @dtLastGenDate is not null
		Begin
			Set @sSQLWhere=@sSQLWhere+" and L1.LOGDATETIMESTAMP >= "+"'"+convert(nvarchar(25), @dtLastGenDate, 21)+"'"
		End
	End
End

-----------------------------------------------------------------------------------------------------
-- Get the information for the Name and Address Updates worksheet. ----------------------------------
-- Displays new or updated name and address details of names related to the recipient. --------------
-- Only names related to the client’s cases that are not inherited will be included in the report. --
-- The name relationships to include will be determined by the name types included in the name ------
-- group specified in the new site control, ‘EDE Name group’. ---------------------------------------
-- The default value for this site control will be ‘EDE NAME GROUP’. Owner name type will be --------
-- excluded since address changes for owner will be reported with a case. ---------------------------
-----------------------------------------------------------------------------------------------------
If @nErrorCode = 0
Begin
	-- Create a tempory table to store names related to the datasource.
	Create table #NAMESTOREPORT
	(
		NAMENO	int,
		NAMETYPE nvarchar(3)	collate database_default null,
		CASEID	int
	)
	Create index X1TEMPNAMES ON #NAMESTOREPORT
	(
		NAMENO
	)
	Create index X2TEMPCASES ON #NAMESTOREPORT
	(
		CASEID
	)

	Set @nErrorCode = @@Error
End

If @nErrorCode = 0
Begin
	Set @sLocalSQLWhere = null

	If @nBatchNo is not null
	Begin
		If @sSQLWhere is not null
		Begin
			Set @sLocalSQLWhere=@sSQLWhere+" and TI.BATCHNO = "+cast(@nBatchNo as nvarchar(50))
		End
		Else
		Begin
			Set @sLocalSQLWhere="TI.BATCHNO = "+cast(@nBatchNo as nvarchar(50))
		End
	End
	Else if @nDocRecipient is not null
	Begin
		Set @sLocalSQLWhere = @sSQLWhere + " and (TR.INTERNALFLAG <> 1 or TR.INTERNALFLAG is null) and (TI.BATCHNO is null or TI.BATCHNO = -1)"
	End
	Else
	Begin
		Set @sLocalSQLWhere = @sSQLWhere
	End
End

If @nErrorCode = 0
Begin
	If @nEmployeeNo is not null
	Begin
		Set @sSQLString="
		Insert into #NAMESTOREPORT (NAMENO)
		select distinct L1.NAMENO
		from NAME_iLOG L1
		where "+@sSQLWhere+"
		union
		select distinct NA.NAMENO
		from ADDRESS_iLOG L1
		join NAMEADDRESS NA on (NA.ADDRESSCODE = L1.ADDRESSCODE)
		where "+@sSQLWhere

		Exec @nErrorCode=sp_executesql @sSQLString
	End
	Else if @nDocRecipient is not null
	Begin
		-- Find all the names related to the document recipient.
		-- Need distinct because there the same name can be more than one name type
		-- Note we are only selecting the first Name Type.
		Set @sSQLString="
		Insert into #NAMESTOREPORT (NAMENO, NAMETYPE)
		select distinct CN.NAMENO, max(CN.NAMETYPE)
		from CASENAME C
		join CASENAME CN on (CN.CASEID = C.CASEID and C.NAMETYPE = 'DI')
		join SITECONTROL SC on (SC.CONTROLID = 'EDE Name Group')
		join NAMEGROUPS NG on (NG.GROUPDESCRIPTION = SC.COLCHARACTER)
		join GROUPMEMBERS GM on (GM.NAMEGROUP = NG.NAMEGROUP)
		where C.NAMENO = @nDocRecipient and C.NAMETYPE = 'DI'
		and CN.NAMETYPE = GM.NAMETYPE and CN.NAMETYPE in ('I','DIV','D','O')
		and (CN.INHERITED <> 1 or CN.INHERITED is null)
		group by CN.NAMENO"

		Exec @nErrorCode=sp_executesql @sSQLString,
			N'@nDocRecipient		int',
			  @nDocRecipient		= @nDocRecipient
	End
	Else if @nBatchNo is not null
		-- Find all batch changes.
	Begin
		Set @sSQLString="
		Insert into #NAMESTOREPORT (NAMENO, NAMETYPE)
		select distinct L1.NAMENO, max(CN.NAMETYPE)
		from NAME_iLOG L1
		join CASENAME CN on (CN.NAMENO = L1.NAMENO)
		left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
		join SITECONTROL SC on (SC.CONTROLID = 'EDE Name Group')
		join NAMEGROUPS NG on (NG.GROUPDESCRIPTION = SC.COLCHARACTER)
		join GROUPMEMBERS GM on (GM.NAMEGROUP = NG.NAMEGROUP)
		where "+@sLocalSQLWhere+"
		and CN.NAMETYPE = GM.NAMETYPE and CN.NAMETYPE in ('I','DIV','D','O')
		group by L1.NAMENO
		union
		select distinct NA.NAMENO, max(CN.NAMETYPE)
		from ADDRESS_iLOG L1
		join NAMEADDRESS NA on (NA.ADDRESSCODE = L1.ADDRESSCODE)
		join CASENAME CN on (CN.NAMENO = NA.NAMENO)
		join SITECONTROL SC on (SC.CONTROLID = 'EDE Name Group')
		join NAMEGROUPS NG on (NG.GROUPDESCRIPTION = SC.COLCHARACTER)
		join GROUPMEMBERS GM on (GM.NAMEGROUP = NG.NAMEGROUP)
		left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
		where "+@sLocalSQLWhere+"
		and CN.NAMETYPE = GM.NAMETYPE and CN.NAMETYPE in ('I','DIV','D','O')
		group by NA.NAMENO"

		Exec @nErrorCode=sp_executesql @sSQLString,
			N'@nDataInstructor	int',
			  @nDataInstructor	= @nDataInstructor
	End
End

If @nErrorCode = 0
Begin
	-- Create a temporary table to store address telecom details.
	Create table #TELECOMDETAILS
	(
		NAMENO	int,
		PHONE	nvarchar(100)	collate database_default null,
		FAX	nvarchar(100)	collate database_default null,
		EMAIL	nvarchar(100)	collate database_default null
	)
	Create index X1TEMPNAMES ON #TELECOMDETAILS
	(
		NAMENO
	)

	Set @nErrorCode = @@Error
End

If @nErrorCode = 0
Begin
	-- Get telecom details.
	Set @sSQLString="
	Insert into #TELECOMDETAILS (NAMENO, PHONE, FAX, EMAIL)
	Select NDS.NAMENO, NTPHONE.TELECOMNUMBER, NTFAX.TELECOMNUMBER, NTEMAIL.TELECOMNUMBER 
	from #NAMESTOREPORT NDS
	left join
		(select NT.NAMENO, NT.TELECODE, dbo.fn_FormatTelecom(T1.TELECOMTYPE, T1.ISD, T1.AREACODE, T1.TELECOMNUMBER, T1.EXTENSION) as TELECOMNUMBER
		from NAMETELECOM NT 
		join TELECOMMUNICATION T1 on (NT.TELECODE = T1.TELECODE)
		where T1.TELECOMTYPE = 1901) 
		as NTPHONE on (NTPHONE.NAMENO = NDS.NAMENO)
	left join
		(select NT.NAMENO, NT.TELECODE, dbo.fn_FormatTelecom(T1.TELECOMTYPE, T1.ISD, T1.AREACODE, T1.TELECOMNUMBER, T1.EXTENSION) as TELECOMNUMBER
		from NAMETELECOM NT 
		join TELECOMMUNICATION T1 on NT.TELECODE = T1.TELECODE
		where T1.TELECOMTYPE = 1902) 
		as NTFAX on (NTFAX.NAMENO = NDS.NAMENO)
	left join
		(select NT.NAMENO, NT.TELECODE, T1.TELECOMNUMBER
		from NAMETELECOM NT 
		join TELECOMMUNICATION T1 on (NT.TELECODE = T1.TELECODE)
		where T1.TELECOMTYPE = 1903) 
		as NTEMAIL on (NTEMAIL.NAMENO = NDS.NAMENO)"

	Exec @nErrorCode=sp_executesql @sSQLString
End

If @nErrorCode = 0
Begin
	Set @sLocalSQLWhere = null

	If @nBatchNo is not null
	Begin
		If @sSQLWhere is not null
		Begin
			Set @sLocalSQLWhere=@sSQLWhere+" and TI.BATCHNO = "+cast(@nBatchNo as nvarchar(50))
		End
		Else
		Begin
			Set @sLocalSQLWhere="TI.BATCHNO = "+cast(@nBatchNo as nvarchar(50))
		End
	End
	Else if @nDocRecipient is not null
	Begin
		Set @sLocalSQLWhere = @sSQLWhere + " and (TR.INTERNALFLAG <> 1 or TR.INTERNALFLAG is null) and (TI.BATCHNO is null  or TI.BATCHNO = -1)"
	End
	Else
	Begin
		Set @sLocalSQLWhere = @sSQLWhere
	End

	If @bTransReason = 1
	Begin
	    Set @sLocalSQLWhere = @sLocalSQLWhere + " and TR.TRANSACTIONREASONNO is not null"
	End

	-- Return the XML for the Name and Address Updates tab.
	Set @sSQLString="
	Insert into #XMLTEMPTABLE (XMLSTR)
	Select (Select * from (
	select distinct EXN.EXTERNALNAMECODE as 'YourNameCode',NI.NAMECODE as 'OurNameCode',
	isnull(dbo.fn_FormatNameUsingNameNo(NI.NAMENO,null),NI.NAME) as 'Name', isnull(dbo.fn_FormatNameUsingNameNo(N.NAMENO,null), N.NAME) as 'MainContact',
	A.STREET1 as 'AddressLine',A.CITY as 'City',
	case when CO.ADDRESSSTYLE IN (7201,7204,7208) then isnull(SO.STATENAME,A.STATE)
	else isnull(SO.STATE,A.STATE) end as 'State',
	A.POSTCODE as 'PostCode',C.COUNTRY as 'Country',T.PHONE as 'Telephone',T.FAX as 'Fax',
	T.EMAIL as 'Email',NT.DESCRIPTION as 'NameType',TR.DESCRIPTION as 'TransactionReason',
	isnull(E.SENDERREQUESTIDENTIFIER,'"+@nBatchIdentifier+"') as 'BatchNumber',dbo.fn_DateOnly(L1.LOGDATETIMESTAMP) as 'DateOfChange'
	from #NAMESTOREPORT NDS
	join NAME NI on (NI.NAMENO=NDS.NAMENO)
	join NAME_iLOG L1 on (L1.NAMENO=NDS.NAMENO)
	left join NAMETYPE NT on (NT.NAMETYPE=NDS.NAMETYPE)
	left join ADDRESS A on (A.ADDRESSCODE=NI.POSTALADDRESS)
	left join COUNTRY CO on (CO.COUNTRYCODE = A.COUNTRYCODE)
	left join STATE SO on (SO.STATE = A.STATE and SO.COUNTRYCODE = A.COUNTRYCODE)
	left join NAME N on (N.NAMENO=NI.MAINCONTACT)
	left join COUNTRY C on (C.COUNTRYCODE=A.COUNTRYCODE)
	left join #TELECOMDETAILS T on (T.NAMENO=NI.NAMENO)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO=L1.LOGTRANSACTIONNO)
	left join TRANSACTIONREASON TR on (TR.TRANSACTIONREASONNO=TI.TRANSACTIONREASONNO)
	left join EXTERNALNAMEMAPPING EXM on (EXM.INPRONAMENO=NDS.NAMENO and (EXM.PROPERTYTYPE='T' or EXM.PROPERTYTYPE is null))
	"
	If @nBatchNo is not null
	    Begin
		Set @sSQLString = @sSQLString + "join EXTERNALNAME EXN on (EXN.DATASOURCENAMENO="+cast(@nReportNameNo as nvarchar(50))+" and EXN.EXTERNALNAMEID=EXM.EXTERNALNAMEID)"
	    End
	Else
	    Begin
		Set @sSQLString = @sSQLString + "left join EXTERNALNAME EXN on (EXN.DATASOURCENAMENO="+cast(@nReportNameNo as nvarchar(50))+" and EXN.EXTERNALNAMEID=EXM.EXTERNALNAMEID)"
	    End
	Set @sSQLString2 = @sSQLString2 + "
	left join EDESENDERDETAILS E on (TI.BATCHNO=E.BATCHNO)
	where "+@sLocalSQLWhere+"
	union
	select distinct EXN.EXTERNALNAMECODE as 'YourNameCode',NI.NAMECODE as 'OurNameCode',
	isnull(dbo.fn_FormatNameUsingNameNo(NI.NAMENO,null),NI.NAME) as 'Name',isnull(dbo.fn_FormatNameUsingNameNo(N.NAMENO,null),N.NAME) as 'MainContact',
	A.STREET1 as 'AddressLine',A.CITY as 'City',
	case when CO.ADDRESSSTYLE IN (7201,7204,7208) then isnull(SO.STATENAME,A.STATE)
	else isnull(SO.STATE,A.STATE) end as 'State',
	A.POSTCODE as 'PostCode',C.COUNTRY as 'Country',T.PHONE as 'Telephone',T.FAX as 'Fax', 
	T.EMAIL as 'Email',NT.DESCRIPTION as 'NameType',TR.DESCRIPTION as 'TransactionReason',
	isnull(E.SENDERREQUESTIDENTIFIER,'"+@nBatchIdentifier+"') as 'BatchNumber',dbo.fn_DateOnly(L1.LOGDATETIMESTAMP) as 'DateOfChange'
	from #NAMESTOREPORT NDS
	join NAME NI on (NI.NAMENO=NDS.NAMENO)
	left join NAMETYPE NT on (NT.NAMETYPE=NDS.NAMETYPE)
	join ADDRESS_iLOG L1 on (L1.ADDRESSCODE=NI.POSTALADDRESS)
	left join ADDRESS A on (A.ADDRESSCODE=NI.POSTALADDRESS)
	left join COUNTRY CO on (CO.COUNTRYCODE = A.COUNTRYCODE)
	left join STATE SO on (SO.STATE = A.STATE and SO.COUNTRYCODE = A.COUNTRYCODE)
	left join NAME N on (N.NAMENO=NI.MAINCONTACT)
	left join COUNTRY C on (C.COUNTRYCODE=A.COUNTRYCODE)
	left join #TELECOMDETAILS T on (T.NAMENO=NI.NAMENO)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO=L1.LOGTRANSACTIONNO)
	left join TRANSACTIONREASON TR on (TR.TRANSACTIONREASONNO=TI.TRANSACTIONREASONNO)
	left join EXTERNALNAMEMAPPING EXM on (EXM.INPRONAMENO=NDS.NAMENO and (EXM.PROPERTYTYPE='T' or EXM.PROPERTYTYPE is null))
	"
	If @nBatchNo is not null
	    Begin
		Set @sSQLString2 = @sSQLString2 + "join EXTERNALNAME EXN on (EXN.DATASOURCENAMENO="+cast(@nReportNameNo as nvarchar(50))+" and EXN.EXTERNALNAMEID=EXM.EXTERNALNAMEID)"
	    End
	Else
	    Begin
		Set @sSQLString2 = @sSQLString2 + "left join EXTERNALNAME EXN on (EXN.DATASOURCENAMENO="+cast(@nReportNameNo as nvarchar(50))+" and EXN.EXTERNALNAMEID=EXM.EXTERNALNAMEID)"
	    End
	Set @sSQLString2 = @sSQLString2 + "
	left join EDESENDERDETAILS E on (TI.BATCHNO=E.BATCHNO)
	where "+@sLocalSQLWhere+" ) as T
	for XML PATH ('NameAddressUpdates'),TYPE)"

	Exec (@sSQLString+@sSQLString2)
	Set @nErrorCode=@@error
End

----------------------------------------------------------------------------------------------
-- Displays case details of new cases entered. -----------------------------------------------
-- Only cases where the recipient is now the data instructor for the case will be included. --
-- Any new cases that were created in a batch will be included in batch report. --------------
----------------------------------------------------------------------------------------------
If @nErrorCode = 0
Begin
	-- Create a tempory table new cases related to the data instructor.
	Create table #NEWCASESTOREPORT
	(
	    CASEID		int	NOT NULL	PRIMARY KEY,
	    SEQUENCENO  	int identity(1,1)
	)
	
	Set @nErrorCode = @@Error
End

If @nErrorCode = 0
Begin
	-- Create a temporary table to store Renewal Standing Instructions
	Create table #CASESTANDINGINSTRUCTION
	(
		CASEID int,
		INSTRUCTION nvarchar(254)   collate database_default null
	)
	Create index X1TEMPCASES ON #CASESTANDINGINSTRUCTION
	(
		CASEID
	)

	Set @nErrorCode = @@Error
End

If @nErrorCode = 0
Begin
	Create table #TEMPCASEINSTRUCTIONS (
		CASEID			int	    not null,
		INSTRUCTIONTYPE		nvarchar(3) collate database_default null, 
		INSTRUCTIONCODE		smallint    not null)

	Set @nErrorCode = @@Error
End

If @nErrorCode = 0
Begin
	Set @sLocalSQLWhere = null

	If @nBatchNo is not null
	Begin
		-- filter in transactions for this batch.
		If @sSQLWhere is not null
		Begin
			Set @sLocalSQLWhere=@sSQLWhere+" and TI.BATCHNO = "+cast(@nBatchNo as nvarchar(50))
		End
		Else
		Begin
			Set @sLocalSQLWhere="TI.BATCHNO = "+cast(@nBatchNo as nvarchar(50))
		End
	End
	Else
	Begin
		-- filter in data instructor.
		Set @sLocalSQLWhere = @sSQLWhere+" and (TI.BATCHNO is null  or TI.BATCHNO = -1) and (TR.INTERNALFLAG <> 1 or TR.INTERNALFLAG is null)"
	End
End

If @nErrorCode = 0
Begin
	If @nEmployeeNo is not null
	Begin
	-- Find cases that were inserted by the employee.
		Set @sSQLString="
		Insert into #NEWCASESTOREPORT(CASEID)
		select distinct L1.CASEID
		from CASES_iLOG L1
		join CASES C on (C.CASEID = L1.CASEID)
		where "+@sSQLWhere+"
		and L1.LOGACTION = 'I'
		and C.CASETYPE= 'A'"

		Exec @nErrorCode=sp_executesql @sSQLString
	End
	Else if @nBatchNo is not null
	Begin
	-- Filter for all new cases for batch.
		Set @sSQLString="
		Insert into #NEWCASESTOREPORT(CASEID)
		select distinct C.CASEID
		from CASES C
		join CASES_iLOG L1 on (L1.CASEID = C.CASEID)
		left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
		where "+@sLocalSQLWhere+"
		and L1.LOGACTION = 'I'
		and C.CASETYPE= 'A'"

		Exec @nErrorCode=sp_executesql @sSQLString
	End
	Else if @nDocRecipient is not null
	Begin
	-- Filter for all new cases for doc recipient.
		select @nRecipientNameFamilyNo = FAMILYNO from NAME where NAMENO = @nDocRecipient
		
		If (@sBelongingTo = 'RG') and (@nRecipientNameFamilyNo is not null)
		Begin
			Select @sRecipientGroupNames = nullif(@sRecipientGroupNames+',', ',')+cast(NAMENO as nvarchar(15)) 
			from NAME where FAMILYNO = @nRecipientNameFamilyNo
			
			Set @sSQLString="
			Insert into #NEWCASESTOREPORT(CASEID)
			select distinct C.CASEID
			from CASES C
			join CASES_iLOG L1 on (L1.CASEID = C.CASEID)
			join CASENAME CN on (CN.CASEID = C.CASEID and CN.NAMENO in ("+@sRecipientGroupNames+") and CN.NAMETYPE = 'DI')
			left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
			left join TRANSACTIONREASON TR on (TR.TRANSACTIONREASONNO = TI.TRANSACTIONREASONNO)
			where "+@sLocalSQLWhere+"
			and L1.LOGACTION = 'I'
			and C.CASETYPE= 'A'"

			Exec @nErrorCode=sp_executesql @sSQLString
		End
		Else
		Begin
			Set @sSQLString="
			Insert into #NEWCASESTOREPORT(CASEID)
			select distinct C.CASEID
			from CASES C
			join CASES_iLOG L1 on (L1.CASEID = C.CASEID)
			join CASENAME CN on (CN.CASEID = C.CASEID and CN.NAMENO = @nDocRecipient and CN.NAMETYPE = 'DI')
			left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
			left join TRANSACTIONREASON TR on (TR.TRANSACTIONREASONNO = TI.TRANSACTIONREASONNO)
			where "+@sLocalSQLWhere+"
			and L1.LOGACTION = 'I'
			and C.CASETYPE= 'A'"

			Exec @nErrorCode=sp_executesql @sSQLString,
			    N'@nDocRecipient	int',
			      @nDocRecipient	= @nDocRecipient
		End
	End
End

If @nErrorCode = 0
Begin
	-- Create a tempory table for case events to report.
	Create table #CASESEVENTDATESTOREPORT
	(
		CASEID int,
		EVENTNO int,
		EVENTDATE datetime,
		EVENTDUEDATE datetime,
		CYCLE nvarchar(30)  collate database_default null
	)
	Create index X1TEMPCASES ON #CASESEVENTDATESTOREPORT
	(
		CASEID
	)


	Set @nErrorCode = @@Error
End

If @nErrorCode = 0
Begin
	-- Find event dates before hand. And store them.
	-- Earliest Priority date	-1.
	-- Application date		-4.
	-- Registration date		-8.
	-- Next affidavit date or Intent to use date -500.
	-- Next tax date	-98.
	-- Next Renewal date	-11.
	-- CPA Start Pay date	-11858.
	-- CPA Stop Pay date	-11859.

	Declare @sEventToReport nvarchar(300)
	Declare @sCPAStart  nvarchar(10)
	Declare @sCPAStop   nvarchar(10)

	select @sCPAStart = cast(isnull(COLINTEGER,11858) as nvarchar(10))
	from SITECONTROL
	where CONTROLID = 'CPA Date-Start'

	select @sCPAStop = cast(isnull(COLINTEGER,11859) as nvarchar(10))
	from SITECONTROL
	where CONTROLID = 'CPA Date-Stop'

	Set @sEventToReport = "(-1,-4,-8,-500,-98,"+@sCPAStart+","+@sCPAStart+")"
	
	Set @sSQLString="
	Insert into #CASESEVENTDATESTOREPORT(CASEID, EVENTNO, EVENTDATE, EVENTDUEDATE, CYCLE)
	Select CE.CASEID, CE.EVENTNO, CE.EVENTDATE, CE.EVENTDUEDATE, CE.CYCLE
	from CASEEVENT CE
	join #NEWCASESTOREPORT CRD on (CRD.CASEID = CE.CASEID)
	Join (	select MIN(O.CYCLE) as [CYCLE], O.CASEID
		from OPENACTION O
		join SITECONTROL SC on (SC.CONTROLID='Main Renewal Action')
		where O.ACTION=SC.COLCHARACTER
		and O.POLICEEVENTS=1
		group by O.CASEID) OA on (OA.CASEID = CE.CASEID and OA.CYCLE = CE.CYCLE)
	join EVENTS E on (E.EVENTNO = CE.EVENTNO)  
	where CE.EVENTNO = -11
	and E.IMPORTANCELEVEL >= (select COLINTEGER 
				from SITECONTROL 
				where CONTROLID = 'Client Importance')
	union
	Select distinct CE.CASEID, CE.EVENTNO, CE.EVENTDATE, CE.EVENTDUEDATE, CE.CYCLE
	from CASEEVENT CE
	join #NEWCASESTOREPORT CRD on (CRD.CASEID = CE.CASEID)
	join (	select CE01.CASEID, CE01.EVENTNO
		from CASEEVENT CE01
		join #NEWCASESTOREPORT CRD2 on (CRD2.CASEID = CE01.CASEID)
		where CE01.CASEID = CRD2.CASEID
		group by CE01.CASEID, CE01.EVENTNO
		having count(*) > 1    
		) as CE2 on (CE2.CASEID = CE.CASEID and CE2.EVENTNO = CE.EVENTNO)
	join(	select CASEID, ACTION, CRITERIANO, min(CYCLE) as CYCLE
		from OPENACTION
		where POLICEEVENTS=1
		group by CASEID, ACTION, CRITERIANO) OA 
				on (OA.CASEID=CE.CASEID)
	join EVENTCONTROL EC on (EC.CRITERIANO=OA.CRITERIANO
			     and EC.EVENTNO=CE.EVENTNO)
	join ACTIONS A on (A.ACTION=OA.ACTION)
	where CE.EVENTNO != -11
	and CE.EVENTNO in "+@sEventToReport+
	"and CE.OCCURREDFLAG<9
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
		     END
	union
	Select CE.CASEID, CE.EVENTNO, CE.EVENTDATE, CE.EVENTDUEDATE, CE.CYCLE
	from CASEEVENT CE
	join #NEWCASESTOREPORT CRD on (CRD.CASEID = CE.CASEID)
	join (	select CE01.CASEID, CE01.EVENTNO
		from CASEEVENT CE01
		join #NEWCASESTOREPORT CRD2 on (CRD2.CASEID = CE01.CASEID)
		where CE01.CASEID = CRD2.CASEID
		group by CE01.CASEID, CE01.EVENTNO
		having count(*) = 1    
		) as CE2 on (CE2.CASEID = CE.CASEID and CE2.EVENTNO = CE.EVENTNO)
	where CE.EVENTNO in "+@sEventToReport
	
	Exec @nErrorCode=sp_executesql @sSQLString
End

If @nErrorCode = 0
Begin
	-- Find the standing instruction 'R' for cases.
	-- Do this separately thru the existing SP as its is complex.
	exec @nErrorCode = dbo.cs_GetStandingInstructionsBulk 'R', #NEWCASESTOREPORT
End

If @nErrorCode = 0
Begin
	-- Retrieve the instruction description.
	Set @sSQLString="
	Insert into #CASESTANDINGINSTRUCTION(CASEID, INSTRUCTION) 
	select TC.CASEID,I.DESCRIPTION
	from #TEMPCASEINSTRUCTIONS TC
	join INSTRUCTIONS I on (I.INSTRUCTIONTYPE=TC.INSTRUCTIONTYPE and I.INSTRUCTIONCODE = TC.INSTRUCTIONCODE)"

	Exec @nErrorCode=sp_executesql @sSQLString
End

If @nErrorCode = 0
Begin
	Set @sLocalSQLWhere = null

	If @nBatchNo is not null
	Begin
		If @sSQLWhere is not null
		Begin
			Set @sLocalSQLWhere="and "+@sSQLWhere+" and EDC.BATCHNO = "+cast(@nBatchNo as nvarchar(50))
		End
		Else
		Begin
			Set @sLocalSQLWhere="and EDC.BATCHNO = "+cast(@nBatchNo as nvarchar(50))
		End
	End
	Else if @nDocRecipient is not null
	Begin
		Set @sLocalSQLWhere = "and "+@sSQLWhere+" and (TR.INTERNALFLAG <> 1 or TR.INTERNALFLAG is null) and (EDC.BATCHNO is null or EDC.BATCHNO = -1)"
	End
	Else
	Begin
		Set @sLocalSQLWhere = "and "+@sSQLWhere
	End

	If @bTransReason = 1
	Begin
	    Set @sLocalSQLWhere = @sLocalSQLWhere + " and TR.TRANSACTIONREASONNO is not null"
	End

	-- Return the XML for the New Cases tab.
	-- Hard coded event dates are defined on the 4th worksheet.
	Set @sSQLString="
	Insert into #XMLTEMPTABLE (XMLSTR)
	Select (select NDI.NAMECODE as 'DataInstructorNameCode', 
	isnull(dbo.fn_FormatNameUsingNameNo(NDI.NAMENO,null), NDI.NAME) as 'DataInstructorName', NADI.ALIAS as 'EDEAlias',
	CNDI.REFERENCENO as 'SenderReference', OD.OFFICIALNUMBER as 'SenderFileNumber', C.COUNTRYCODE as 'CountryCode',
	CC.CASECATEGORYDESC as 'Category', ST.SUBTYPEDESC as 'SubType', OA.OFFICIALNUMBER as 'ApplicationNumber', isnull(CED2.EVENTDATE,CED2.EVENTDUEDATE) as 'ApplicationDate',
	isnull(CED3.EVENTDATE,CED3.EVENTDUEDATE) as 'RegistrationDate', OE.OFFICIALNUMBER as 'RegistrationNumber', C.IRN as 'OurCaseReference',
	TM.DESCRIPTION as 'TransactionMessage', TR.DESCRIPTION as 'ReasonForChange', C.TITLE as 'Title', C.INTCLASSES as 'InternationalClasses',
	C.LOCALCLASSES as 'NationalClasses', dbo.fn_GetDesignatedCountries(C.CASEID,0,',','-') as 'DesignatedCountries', 
	isnull(CED1.EVENTDATE,CED1.EVENTDUEDATE) as 'EarliestPriorityDate', RCR.PRIORITYDATE as 'ParentDate',
	isnull(CED4.EVENTDUEDATE,CED4.EVENTDATE) as 'NextAffidavitIntentUseDate', isnull(CED5.EVENTDUEDATE,CED5.EVENTDATE) as 'NextTaxDate', 
	isnull(CED6.EVENTDUEDATE,CED6.EVENTDATE) as 'NextRenewalDate', isnull(CED7.EVENTDATE,CED7.EVENTDUEDATE) as 'CPAStartPayDate', isnull(CED8.EVENTDATE,CED8.EVENTDUEDATE) as 'CPAStopPayDate',
	RCB.OFFICIALNUMBER as 'EarliestPriorityNumber', RCR.OFFICIALNUMBER as 'ParentNumber', NCI.NAMECODE as 'InstructorNameCode',
	isnull(dbo.fn_FormatNameUsingNameNo(NCI.NAMENO,null), NCI.NAME) as 'InstructorName', CNI.REFERENCENO as 'InstructorReference',
	OI.OFFICIALNUMBER as 'InstructorAlternativeReference', NCO.NAMECODE as 'OwnerNameCode', 
	isnull(dbo.fn_FormatNameUsingNameNo(NCO.NAMENO,null), NCO.NAME) as 'OwnerName',
	isnull(dbo.fn_FormatNameUsingNameNo(NMC.NAMENO,null), NMC.NAME) as 'OwnerMainContact', 
	AO.STREET1 as 'OwnerAddress', AO.CITY as 'OwnerAddressCity', 
	case when CO.ADDRESSSTYLE IN (7201,7204,7208) then isnull(SO.STATENAME,AO.STATE)
	else isnull(SO.STATE,AO.STATE) end as 'OwnerAddressCountyState', 
	AO.POSTCODE as 'OwnerAddressPostCode', AO.COUNTRYCODE as 'OwnerAddressCountry', 
	NCDIV.NAMECODE as 'DivisionNameCode', isnull(dbo.fn_FormatNameUsingNameNo(NCDIV.NAMENO,null), NCDIV.NAME) as 'DivisionName',
	isnull(dbo.fn_FormatNameUsingNameNo(DIVMC.NAMENO,null), DIVMC.NAME) as 'DivisionMainContact',
	ADIV.STREET1 as 'DivisionAddress',
	ADIV.COUNTRYCODE as 'DivisionAddressCounty', ADIV.POSTCODE as 'DivisionAddressPostCode',
	NI.INSTRUCTION as 'RenewalStandingInstruction', S.EXTERNALDESC as 'CaseStatus', 
	isnull(E.SENDERREQUESTIDENTIFIER,'"+@nBatchIdentifier+"') as 'EDEBatchNumber'
	from #NEWCASESTOREPORT CRD 
	join CASES_iLOG L1 on (L1.CASEID = CRD.CASEID)
	join CASES C on (C.CASEID = CRD.CASEID)
	left join EDECASEDETAILS EDC on (EDC.CASEID = CRD.CASEID)
	left join CASENAME CNDI on (CNDI.CASEID = C.CASEID and CNDI.NAMETYPE = 'DI' and CNDI.SEQUENCE = 0)
	left join NAME NDI on (NDI.NAMENO = CNDI.NAMENO)
	left join NAMEALIAS NADI on (NADI.ALIASTYPE = '_E' and NADI.NAMENO = NDI.NAMENO)
	left join CASECATEGORY CC on (CC.CASETYPE = C.CASETYPE and CC.CASECATEGORY = C.CASECATEGORY)
	left join SUBTYPE ST on (ST.SUBTYPE = C.SUBTYPE)
	left join OFFICIALNUMBERS OA on (OA.CASEID = C.CASEID and OA.NUMBERTYPE = 'A')
	left join OFFICIALNUMBERS OE on (OE.CASEID = C.CASEID and OE.NUMBERTYPE = 'R')
	left join OFFICIALNUMBERS OD on (OD.CASEID = C.CASEID and OD.NUMBERTYPE = 'D')
	left join OFFICIALNUMBERS OI on (OI.CASEID = C.CASEID and OI.NUMBERTYPE = '3')
	left join #CASESEVENTDATESTOREPORT CED1 on (CED1.CASEID = CRD.CASEID and CED1.EVENTNO = -1)
	left join #CASESEVENTDATESTOREPORT CED2 on (CED2.CASEID = CRD.CASEID and CED2.EVENTNO = -4)
	left join #CASESEVENTDATESTOREPORT CED6 on (CED6.CASEID = CRD.CASEID and CED6.EVENTNO = -11)
	left join #CASESEVENTDATESTOREPORT CED7 on (CED7.CASEID = CRD.CASEID and CED7.EVENTNO = "+@sCPAStart+")
	"
	
	Set @sSQLString2="
	left join #CASESEVENTDATESTOREPORT CED3 on (CED3.CASEID = CRD.CASEID and CED3.EVENTNO = -8)
	left join #CASESEVENTDATESTOREPORT CED4 on (CED4.CASEID = CRD.CASEID and CED4.EVENTNO = -500)
	left join #CASESEVENTDATESTOREPORT CED5 on (CED5.CASEID = CRD.CASEID and CED5.EVENTNO = -98)
	left join #CASESEVENTDATESTOREPORT CED8 on (CED8.CASEID = CRD.CASEID and CED8.EVENTNO = "+@sCPAStop+")
	left join RELATEDCASE RCR on (RCR.CASEID = C.CASEID and RCR.RELATIONSHIP = 'RER')
	left join RELATEDCASE RCB on (RCB.CASEID = C.CASEID and RCB.RELATIONSHIP = 'BAS')
	left join #CASESTANDINGINSTRUCTION NI on (NI.CASEID = C.CASEID)
	left join CASENAME CNI on (CNI.CASEID = C.CASEID and CNI.NAMETYPE = 'I' and CNI.SEQUENCE = 0)
	left join NAME NCI on (NCI.NAMENO = CNI.NAMENO)
	left join CASENAME CNO on (CNO.CASEID = C.CASEID and CNO.NAMETYPE = 'O' and CNO.SEQUENCE = 0)
	left join NAME NCO on (NCO.NAMENO = CNO.NAMENO)
	left join ADDRESS AO on (AO.ADDRESSCODE = NCO.POSTALADDRESS)
	left join COUNTRY CO on (CO.COUNTRYCODE = AO.COUNTRYCODE)
	left join STATE SO on (SO.STATE = AO.STATE and SO.COUNTRYCODE = AO.COUNTRYCODE)
	left join NAME NMC on (NMC.NAMENO = NCO.MAINCONTACT)
	left join CASENAME CNDIV on (CNDIV.CASEID = C.CASEID and CNDIV.NAMETYPE = 'DIV' and CNDIV.SEQUENCE = 0)
	left join NAME NCDIV on (NCDIV.NAMENO = CNDIV.NAMENO)
	left join ADDRESS ADIV on (ADIV.ADDRESSCODE = NCDIV.POSTALADDRESS)
	left join NAME DIVMC on (DIVMC.NAMENO = NCDIV.MAINCONTACT)
	left join STATUS S on (S.STATUSCODE = C.STATUSCODE)
	left join EDESENDERDETAILS E on (EDC.BATCHNO = E.BATCHNO)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	left join TRANSACTIONMESSAGE TM on (TM.TRANSACTIONMESSAGENO = TI.TRANSACTIONMESSAGENO)
	left join TRANSACTIONREASON TR on (TR.TRANSACTIONREASONNO = TI.TRANSACTIONREASONNO)
	where L1.LOGACTION = 'I' "+@sLocalSQLWhere+"
	for XML PATH ('NewCases'), TYPE)"

	Exec (@sSQLString+@sSQLString2)
	Set @nErrorCode=@@error
End

-----------------------------------------------------------------------------------------------------
-- Displays details of fields updated for particular cases. -----------------------------------------
-- Not all case details will be reported on. The fields that will be reported on are summarised in --
-- the Field Definition tab in the sample report. ---------------------------------------------------
-- The events to be reported on will vary depending on the events under the ‘EDE Action’ events -----
-- and entries rule for the case. The EDE Action code will be specified under a new -----------------
-- ‘EDE Action code’ site control. The default value for the site control will be ‘ED’ --------------
-----------------------------------------------------------------------------------------------------
If @nErrorCode = 0
Begin
	-- Create a tempory table for cases related to the data instructor and performance.
	Create table #CASESTOREPORT
	(
	    CASEID	int,
	    SEQUENCENO  int identity(1,1)
	)
	Create index X1TEMPCASES ON #CASESTOREPORT
	(
		CASEID
	)
	
	Create table #TEMPCASENAME
	(
		CASEID int,
		NAMENO int,
		NAMETYPE nvarchar(3) 	collate database_default 
	)

	Create table #CASEEVENT_iLOG
	(
		LOGUSERID		nvarchar(50) 	collate database_default ,
		LOGIDENTITYID		int,
		LOGTRANSACTIONNO	int,
		LOGDATETIMESTAMP	datetime,
		LOGACTION		nchar(1) 	collate database_default,
		LOGAPPLICATION		nvarchar(128) 	collate database_default,
		CASEID			int,
		EVENTNO			int,
		CYCLE			smallint,
		EVENTDATE		datetime,
		EVENTDUEDATE		datetime,
		DATEREMIND		datetime,
		DATEDUESAVED		decimal(1,0),
		OCCURREDFLAG		decimal(1,0),
		CREATEDBYACTION		nvarchar(2) 	collate database_default,
		CREATEDBYCRITERIA	int,
		ENTEREDDEADLINE		smallint,
		PERIODTYPE		nchar(1) 	collate database_default,
		DOCUMENTNO		smallint,
		DOCSREQUIRED		smallint,
		DOCSRECEIVED		smallint,
		USEMESSAGE2FLAG		decimal(1,0),
		GOVERNINGEVENTNO	int,
		EVENTTEXT		nvarchar(254) 	collate database_default,
		LONGFLAG		decimal(1,0),
		JOURNALNO		nvarchar(20) 	collate database_default,
		IMPORTBATCHNO		int,
		EVENTTEXT_TID		int,
		EMPLOYEENO		int,
		SENDMETHOD		int,
		SENTDATE		datetime,
		RECEIPTDATE		datetime,
		RECEIPTREFERENCE	nvarchar(50) 	collate database_default,
		DISPLAYORDER		smallint,
		FROMCASEID		int
	)

	Create index X1CASEEVENT_iLOG ON #CASEEVENT_iLOG
	(
		CASEID,
		EVENTNO,
		CYCLE
	)

	Create table #CASENAME_iLOG
	(
		LOGUSERID		nvarchar(50) 	collate database_default,
		LOGIDENTITYID		int,
		LOGTRANSACTIONNO	int,
		LOGDATETIMESTAMP	datetime,
		LOGACTION		nchar(1) 	collate database_default,
		LOGAPPLICATION		nvarchar(128) 	collate database_default,
		CASEID			int,
		NAMETYPE		nvarchar(3) 	collate database_default,
		NAMENO			int,
		SEQUENCE		smallint,
		CORRESPONDNAME		int,
		ADDRESSCODE		int,
		REFERENCENO		nvarchar(80) 	collate database_default,
		ASSIGNMENTDATE		datetime,
		COMMENCEDATE		datetime,
		EXPIRYDATE		datetime,
		BILLPERCENTAGE		decimal(5,2),
		INHERITED		decimal(1,0),
		INHERITEDNAMENO		int,
		INHERITEDRELATIONS	nvarchar(3) 	collate database_default,
		INHERITEDSEQUENCE	smallint,
		NAMEVARIANTNO		int,
		DERIVEDCORRNAME		decimal(1,0)
	)

	Create index X1CASENAME_iLOG ON #CASENAME_iLOG
	(
		CASEID,
		NAMETYPE,
		NAMENO,
		SEQUENCE
	)

	Create table #OFFICIALNUMBERS_iLOG
	(
		LOGUSERID		nvarchar(50) 	collate database_default,
		LOGIDENTITYID		int,
		LOGTRANSACTIONNO	int,
		LOGDATETIMESTAMP	datetime,
		LOGACTION		nchar(1) 	collate database_default,
		LOGAPPLICATION		nvarchar(128) 	collate database_default,
		CASEID			int,
		OFFICIALNUMBER		nvarchar(36) 	collate database_default,
		NUMBERTYPE		nvarchar(3) 	collate database_default,
		ISCURRENT		decimal(1,0),
		DATEENTERED		datetime,
		OFFICIALNUMBER_TID	int
	)

	Create index X1OFFICIALNUMBERS_iLOG ON #OFFICIALNUMBERS_iLOG
	(
		CASEID,
		OFFICIALNUMBER,
		NUMBERTYPE
	)

	Set @nErrorCode = @@Error

End

If @nErrorCode = 0
Begin
	-- Clear out rows from #CASESTANDINGINSTRUCTION.
	Set @sSQLString="
	Delete from #CASESTANDINGINSTRUCTION"

	Exec @nErrorCode=sp_executesql @sSQLString
End

If @nErrorCode = 0
Begin
	-- Clear out rows from #TEMPCASEINSTRUCTIONS.
	Set @sSQLString="
	Delete from #TEMPCASEINSTRUCTIONS"

	Exec @nErrorCode=sp_executesql @sSQLString
End

If @nErrorCode = 0
Begin
	Set @sLocalSQLWhere = null

	If @nBatchNo is not null
	Begin
		-- filter in transactions for this batch.
		If @sSQLWhere is not null
		Begin
			Set @sLocalSQLWhere=@sSQLWhere+" and TI.BATCHNO = "+cast(@nBatchNo as nvarchar(50))
		End
		Else
		Begin
			Set @sLocalSQLWhere="TI.BATCHNO = "+cast(@nBatchNo as nvarchar(50))
		End
	End
	Else
	Begin
		-- filter in data instructor.
		Set @sLocalSQLWhere = @sSQLWhere+" and (TI.BATCHNO is null or TI.BATCHNO = -1) and (TR.INTERNALFLAG <> 1 or TR.INTERNALFLAG is null)"
	End
End

If @nErrorCode = 0
Begin
	If @nEmployeeNo is not null
	Begin
	-- Find cases where the @nEmployeeNo has updated.
		Set @sSQLString="
		Insert into #CASESTOREPORT(CASEID)
		select distinct L1.CASEID
		from CASES_iLOG L1
		join CASES C on (C.CASEID = L1.CASEID)
		where "+@sSQLWhere+"
		and L1.LOGACTION in ('I', 'U')
		and C.CASETYPE = 'A'
		and C.CASEID not in (select CASEID from #NEWCASESTOREPORT)
		union
		select distinct L1.CASEID
		from OFFICIALNUMBERS_iLOG L1
		join CASES C on (C.CASEID = L1.CASEID)
		where "+@sSQLWhere+"
		and L1.LOGACTION in ('I', 'U')
		and C.CASETYPE = 'A'
		and C.CASEID not in (select CASEID from #NEWCASESTOREPORT)
		union
		select distinct L1.CASEID
		from RELATEDCASE_iLOG L1
		join CASES C on (C.CASEID = L1.CASEID)
		where "+@sSQLWhere+"
		and L1.LOGACTION in ('I', 'U')
		and C.CASETYPE = 'A'
		and C.CASEID not in (select CASEID from #NEWCASESTOREPORT)
		union
		select distinct L1.CASEID
		from CASEEVENT_iLOG L1
		join CASES C on (C.CASEID = L1.CASEID)
		where "+@sSQLWhere+"
		and L1.LOGACTION in ('I', 'U')
		and C.CASETYPE = 'A'
		and C.CASEID not in (select CASEID from #NEWCASESTOREPORT)
		union
		select distinct L1.CASEID
		from CASENAME_iLOG L1
		join CASES C on (C.CASEID = L1.CASEID)
		where "+@sSQLWhere+"
		and L1.LOGACTION in ('I', 'U')
		and C.CASETYPE = 'A'
		and C.CASEID not in (select CASEID from #NEWCASESTOREPORT)"

		Exec @nErrorCode=sp_executesql @sSQLString
	End
	Else if @nBatchNo is not null
	Begin
	-- Find cases where the @nDocRecipient is the Data Instructor. And store them.
		Set @sSQLString="
		Insert into #CASESTOREPORT(CASEID)
		select C.CASEID
		from TRANSACTIONINFO TI
		join CASES_iLOG L1 on (L1.LOGTRANSACTIONNO=TI.LOGTRANSACTIONNO)
		join CASES C on (C.CASEID=L1.CASEID)
		left join #NEWCASESTOREPORT N on (N.CASEID=C.CASEID)
		where "+@sLocalSQLWhere+"
		and L1.LOGACTION in ('I', 'U')
		and C.CASETYPE = 'A'
		and C.CASEID not in (select CASEID from #NEWCASESTOREPORT)
		union
		select C.CASEID
		from TRANSACTIONINFO TI
		join OFFICIALNUMBERS_iLOG L1 on (L1.LOGTRANSACTIONNO=TI.LOGTRANSACTIONNO)
		join CASES C on (C.CASEID=L1.CASEID)
		left join #NEWCASESTOREPORT N on (N.CASEID=C.CASEID)
		where "+@sLocalSQLWhere+"
		and L1.LOGACTION in ('I', 'U')
		and C.CASETYPE = 'A'		
		and C.CASEID not in (select CASEID from #NEWCASESTOREPORT)
		union
		select C.CASEID
		from TRANSACTIONINFO TI
		join RELATEDCASE_iLOG L1 on (L1.LOGTRANSACTIONNO=TI.LOGTRANSACTIONNO)
		join CASES C on (C.CASEID=L1.CASEID)
		left join #NEWCASESTOREPORT N on (N.CASEID=C.CASEID)		
		where "+@sLocalSQLWhere+"
		and L1.LOGACTION in ('I', 'U')
		and C.CASETYPE = 'A'		
		and C.CASEID not in (select CASEID from #NEWCASESTOREPORT)
		union
		select C.CASEID
		from TRANSACTIONINFO TI
		join CASEEVENT_iLOG L1 on (L1.LOGTRANSACTIONNO=TI.LOGTRANSACTIONNO)
		join CASES C on (C.CASEID=L1.CASEID)
		left join #NEWCASESTOREPORT N on (N.CASEID=C.CASEID)
		where "+@sLocalSQLWhere+"
		and L1.LOGACTION in ('I', 'U')
		and C.CASETYPE = 'A'		
		and C.CASEID not in (select CASEID from #NEWCASESTOREPORT)
		union
		select C.CASEID
		from TRANSACTIONINFO TI
		join CASENAME_iLOG L1 on (L1.LOGTRANSACTIONNO= TI.LOGTRANSACTIONNO)
		join CASES C on (C.CASEID=L1.CASEID)
		left join #NEWCASESTOREPORT N on (N.CASEID=C.CASEID)
		where "+@sLocalSQLWhere+"
		and L1.LOGACTION in ('I', 'U')
		and C.CASETYPE = 'A'		
		and C.CASEID not in (select CASEID from #NEWCASESTOREPORT)"

		Exec @nErrorCode=sp_executesql @sSQLString
	End
	Else if @nDocRecipient is not null
	Begin
		select @nRecipientNameFamilyNo = FAMILYNO from NAME where NAMENO = @nDocRecipient
		
		If (@sBelongingTo = 'RG') and (@nRecipientNameFamilyNo is not null)
		Begin
			Select @sRecipientGroupNames = nullif(@sRecipientGroupNames+',', ',')+cast(NAMENO as nvarchar(15)) 
			from NAME where FAMILYNO = @nRecipientNameFamilyNo
		End
		Else
		Begin
			Set @sRecipientGroupNames = cast(@nDocRecipient as nvarchar(15))
		End

		-- improve performance
		Set @sSQLString="
		Insert into #TEMPCASENAME(CASEID,NAMENO,NAMETYPE)
		select CASEID,NAMENO,NAMETYPE
		from CASENAME
		where NAMENO in ("+@sRecipientGroupNames+") and NAMETYPE ='DI'"
		
		Exec @nErrorCode=sp_executesql @sSQLString
		
		Set @sSQLString="
		Insert into #CASEEVENT_iLOG(LOGUSERID,LOGIDENTITYID,LOGTRANSACTIONNO,LOGDATETIMESTAMP,LOGACTION,LOGAPPLICATION,
		CASEID,EVENTNO,CYCLE,EVENTDATE,EVENTDUEDATE,DATEREMIND,DATEDUESAVED,OCCURREDFLAG,CREATEDBYACTION,CREATEDBYCRITERIA,
		ENTEREDDEADLINE,PERIODTYPE,DOCUMENTNO,DOCSREQUIRED,DOCSRECEIVED,USEMESSAGE2FLAG,GOVERNINGEVENTNO,EVENTTEXT,LONGFLAG,
		JOURNALNO,IMPORTBATCHNO,EVENTTEXT_TID,EMPLOYEENO,SENDMETHOD,SENTDATE,RECEIPTDATE,RECEIPTREFERENCE,DISPLAYORDER,FROMCASEID)
		select C.LOGUSERID,C.LOGIDENTITYID,C.LOGTRANSACTIONNO,C.LOGDATETIMESTAMP,C.LOGACTION,C.LOGAPPLICATION,
		C.CASEID,C.EVENTNO,C.CYCLE,C.EVENTDATE,C.EVENTDUEDATE,C.DATEREMIND,C.DATEDUESAVED,C.OCCURREDFLAG,C.CREATEDBYACTION,C.CREATEDBYCRITERIA,
		C.ENTEREDDEADLINE,C.PERIODTYPE,C.DOCUMENTNO,C.DOCSREQUIRED,C.DOCSRECEIVED,C.USEMESSAGE2FLAG,C.GOVERNINGEVENTNO,C.EVENTTEXT,C.LONGFLAG,
		C.JOURNALNO,C.IMPORTBATCHNO,C.EVENTTEXT_TID,C.EMPLOYEENO,C.SENDMETHOD,C.SENTDATE,C.RECEIPTDATE,C.RECEIPTREFERENCE,C.DISPLAYORDER,C.FROMCASEID
		from CASEEVENT_iLOG C
		join #TEMPCASENAME CN on (CN.CASEID = C.CASEID)"
		
		Exec @nErrorCode=sp_executesql @sSQLString

		Set @sSQLString="
		Insert into #CASENAME_iLOG(LOGUSERID,LOGIDENTITYID,LOGTRANSACTIONNO,LOGDATETIMESTAMP,LOGACTION,LOGAPPLICATION,CASEID,NAMETYPE,NAMENO,
		SEQUENCE,CORRESPONDNAME,ADDRESSCODE,REFERENCENO,ASSIGNMENTDATE,COMMENCEDATE,EXPIRYDATE,BILLPERCENTAGE,INHERITED,INHERITEDNAMENO,
		INHERITEDRELATIONS,INHERITEDSEQUENCE,NAMEVARIANTNO,DERIVEDCORRNAME)
		select C.LOGUSERID,C.LOGIDENTITYID,C.LOGTRANSACTIONNO,C.LOGDATETIMESTAMP,C.LOGACTION,C.LOGAPPLICATION,C.CASEID,C.NAMETYPE,C.NAMENO,
		C.SEQUENCE,C.CORRESPONDNAME,C.ADDRESSCODE,C.REFERENCENO,C.ASSIGNMENTDATE,C.COMMENCEDATE,C.EXPIRYDATE,C.BILLPERCENTAGE,C.INHERITED,C.INHERITEDNAMENO,
		C.INHERITEDRELATIONS,C.INHERITEDSEQUENCE,C.NAMEVARIANTNO,C.DERIVEDCORRNAME
		from CASENAME_iLOG C
		join #TEMPCASENAME CN on (CN.CASEID = C.CASEID)"
		
		Exec @nErrorCode=sp_executesql @sSQLString

		Set @sSQLString="
		Insert into #OFFICIALNUMBERS_iLOG(LOGUSERID,LOGIDENTITYID,LOGTRANSACTIONNO,LOGDATETIMESTAMP,LOGACTION,LOGAPPLICATION,CASEID,
		OFFICIALNUMBER,NUMBERTYPE,ISCURRENT,DATEENTERED,OFFICIALNUMBER_TID)
		select I.LOGUSERID,I.LOGIDENTITYID,I.LOGTRANSACTIONNO,I.LOGDATETIMESTAMP,I.LOGACTION,I.LOGAPPLICATION,I.CASEID,
		I.OFFICIALNUMBER,I.NUMBERTYPE,I.ISCURRENT,I.DATEENTERED,I.OFFICIALNUMBER_TID
		from OFFICIALNUMBERS_iLOG I
		join #TEMPCASENAME CN on (CN.CASEID = I.CASEID)"
		
		Exec @nErrorCode=sp_executesql @sSQLString

		Set @sSQLString="
		Insert into #CASESTOREPORT(CASEID)
		select distinct C.CASEID
		from CASES C
		join CASES_iLOG L1 on (L1.CASEID = C.CASEID)
		join #TEMPCASENAME CN on (CN.CASEID = C.CASEID and CN.NAMENO in ("+@sRecipientGroupNames+") and CN.NAMETYPE = 'DI')
		left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
		left join TRANSACTIONREASON TR on (TR.TRANSACTIONREASONNO = TI.TRANSACTIONREASONNO)
		where "+@sLocalSQLWhere+" 
		and C.CASETYPE = 'A'
		and L1.LOGACTION in ('I', 'U')
		and C.CASEID not in (select CASEID from #NEWCASESTOREPORT)
		union
		select distinct C.CASEID
		from CASES C
		join #OFFICIALNUMBERS_iLOG L1 on (L1.CASEID = C.CASEID)
		join #TEMPCASENAME CN on (CN.CASEID = C.CASEID and CN.NAMENO in ("+@sRecipientGroupNames+") and CN.NAMETYPE = 'DI')
		left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
		left join TRANSACTIONREASON TR on (TR.TRANSACTIONREASONNO = TI.TRANSACTIONREASONNO)
		where "+@sLocalSQLWhere+"
		and C.CASETYPE = 'A'
		and L1.LOGACTION in ('I', 'U')
		and C.CASEID not in (select CASEID from #NEWCASESTOREPORT)
		union
		select distinct C.CASEID
		from CASES C
		join RELATEDCASE_iLOG L1 on (L1.CASEID = C.CASEID)
		join #TEMPCASENAME CN on (CN.CASEID = C.CASEID and CN.NAMENO in ("+@sRecipientGroupNames+") and CN.NAMETYPE = 'DI')
		left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
		left join TRANSACTIONREASON TR on (TR.TRANSACTIONREASONNO = TI.TRANSACTIONREASONNO)
		where "+@sLocalSQLWhere+"
		and C.CASETYPE = 'A'
		and L1.LOGACTION in ('I', 'U')
		and C.CASEID not in (select CASEID from #NEWCASESTOREPORT)
		union
		select distinct C.CASEID
		from CASES C
		join #CASENAME_iLOG L1 on (L1.CASEID = C.CASEID)
		join #TEMPCASENAME CN on (CN.CASEID = C.CASEID and CN.NAMENO in ("+@sRecipientGroupNames+") and CN.NAMETYPE = 'DI')
		left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
		left join TRANSACTIONREASON TR on (TR.TRANSACTIONREASONNO = TI.TRANSACTIONREASONNO)
		where "+@sLocalSQLWhere+"
		and C.CASETYPE = 'A'
		and L1.LOGACTION in ('I', 'U')
		and C.CASEID not in (select CASEID from #NEWCASESTOREPORT)
		union
		select distinct C.CASEID
		from CASES C
		join #CASEEVENT_iLOG L1 on (L1.CASEID = C.CASEID)
		join #TEMPCASENAME CN on (CN.CASEID = C.CASEID and CN.NAMENO in ("+@sRecipientGroupNames+") and CN.NAMETYPE = 'DI')
		left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
		left join TRANSACTIONREASON TR on (TR.TRANSACTIONREASONNO = TI.TRANSACTIONREASONNO)
		where "+@sLocalSQLWhere+"
		and C.CASETYPE = 'A'
		and L1.LOGACTION in ('I', 'U')
		and C.CASEID not in (select CASEID from #NEWCASESTOREPORT)"
		
		Exec @nErrorCode=sp_executesql @sSQLString
	End

End

If @nErrorCode = 0
Begin
	-- Create a temp table to store all before and after infomration.
	Create table #AMENDEDCASES
	(
		CASEID int,
		FIELD nvarchar(254)	    collate database_default null,
		OLDVALUE nvarchar(254)	    collate database_default null,
		NEWVALUE nvarchar(254)	    collate database_default null,
		EDEBATCHNO nvarchar(254)    collate database_default null,
		DATEOFCHANGE datetime,
		TRANSACTIONREASONNO int,
		TRANSACTIONMESSAGENO int
	)
	Create index X1TEMPCASES ON #AMENDEDCASES
	(
		CASEID
	)

	Set @nErrorCode=@@error
End

If @nErrorCode = 0
Begin
	-- Find the standing instruction 'R' for cases.
	-- Do this separately thru the existing SP as its is complex.
	exec @nErrorCode = dbo.cs_GetStandingInstructionsBulk 'R', #CASESTOREPORT
End

If @nErrorCode = 0
Begin
	-- Retrieve the instruction description.
	Set @sSQLString="
	Insert into #CASESTANDINGINSTRUCTION(CASEID, INSTRUCTION) 
	select TC.CASEID,I.DESCRIPTION
	from #TEMPCASEINSTRUCTIONS TC
	left join INSTRUCTIONS I on (I.INSTRUCTIONTYPE=TC.INSTRUCTIONTYPE and I.INSTRUCTIONCODE = TC.INSTRUCTIONCODE)"

	Exec @nErrorCode=sp_executesql @sSQLString
End

-------------
-- UPDATES --
-------------
If @nErrorCode = 0
Begin
	Set @sLocalSQLWhere = null

	If @nBatchNo is not null
	Begin
		-- filter in transactions for this batch.
		If @sSQLWhere is not null
		Begin
			Set @sLocalSQLWhere=@sSQLWhere+" and TI.BATCHNO = "+cast(@nBatchNo as nvarchar(50))
		End
		Else
		Begin
			Set @sLocalSQLWhere="TI.BATCHNO = "+cast(@nBatchNo as nvarchar(50))
		End
	End
	Else
	Begin
	    Set @sLocalSQLWhere=@sSQLWhere
	End
End

If @nErrorCode = 0
Begin
	-- We want to report only on fields specified on the 4th tab of the report.
	-- This section returns the case changes.
	-- Case Type = CASES_iLOG.CASETYPE.
	-- Property Type = CASES_iLOG.PROPERTYTYPE.
	-- Country Code = CASES_iLOG.COUNTRYCODE.
	-- Category = CASES_iLOG.CASECATEGORY.
	-- Sub Type = CASES_iLOG.SUBTYPE.
	-- Title = CASES_iLOG.TITLE.
	-- IRN = CASES_iLOG.IRN.
	-- National Classes = CASES_iLOG.LOCALCLASSES.
	-- International Classes = CASES_iLOG.INTCLASSES.
	Set @sSQLString="
	Insert into #AMENDEDCASES (CASEID, FIELD, OLDVALUE, NEWVALUE, EDEBATCHNO, DATEOFCHANGE, TRANSACTIONREASONNO, TRANSACTIONMESSAGENO)
	Select distinct L1.CASEID, 
	case
		when checksum(L1.CASETYPE)<>checksum(isnull(L2.CASETYPE,X.CASETYPE)) then 'Case Type'
		when checksum(L1.PROPERTYTYPE)<>checksum(isnull(L2.PROPERTYTYPE,X.PROPERTYTYPE)) then 'Property Type'
		when checksum(L1.COUNTRYCODE)<>checksum(isnull(L2.COUNTRYCODE,X.COUNTRYCODE)) then 'Country Code'
		when checksum(L1.CASECATEGORY)<>checksum(isnull(L2.CASECATEGORY,X.CASECATEGORY)) then 'Category'
		when checksum(L1.SUBTYPE)<>checksum(isnull(L2.SUBTYPE,X.SUBTYPE)) then 'Sub Type'
		when checksum(L1.TITLE)<>checksum(isnull(L2.TITLE,X.TITLE)) then 'Title'
		when checksum(L1.IRN)<>checksum(isnull(L2.IRN,X.IRN)) then 'IRN'
		when checksum(L1.LOCALCLASSES)<>checksum(isnull(L2.LOCALCLASSES,X.LOCALCLASSES)) then 'National Classes'
		when checksum(L1.INTCLASSES)<>checksum(isnull(L2.INTCLASSES,X.INTCLASSES)) then 'International Classes'
	end, 
	case
		when checksum(L1.CASETYPE)<>checksum(isnull(L2.CASETYPE,X.CASETYPE)) then cast(L1.CASETYPE as nvarchar(254))+' {'+CTK1.CASETYPEDESC+'}'
		when checksum(L1.PROPERTYTYPE)<>checksum(isnull(L2.PROPERTYTYPE,X.PROPERTYTYPE)) then cast(L1.PROPERTYTYPE as nvarchar(254))+' {'+PTK1.PROPERTYNAME+'}'
		when checksum(L1.COUNTRYCODE)<>checksum(isnull(L2.COUNTRYCODE,X.COUNTRYCODE)) then cast(L1.COUNTRYCODE as nvarchar(254))
		when checksum(L1.CASECATEGORY)<>checksum(isnull(L2.CASECATEGORY,X.CASECATEGORY)) then cast(L1.CASECATEGORY as nvarchar(254))+' {'+CCK1.CASECATEGORYDESC+'}'
		when checksum(L1.SUBTYPE)<>checksum(isnull(L2.SUBTYPE,X.SUBTYPE)) then cast(L1.SUBTYPE as nvarchar(254))+' {'+STK1.SUBTYPEDESC+'}'
		when checksum(L1.TITLE)<>checksum(isnull(L2.TITLE,X.TITLE)) then cast(L1.TITLE as nvarchar(254))
		when checksum(L1.IRN)<>checksum(isnull(L2.IRN,X.IRN)) then cast(L1.IRN as nvarchar(254))
		when checksum(L1.LOCALCLASSES)<>checksum(isnull(L2.LOCALCLASSES,X.LOCALCLASSES)) then cast(L1.LOCALCLASSES as nvarchar(254))
		when checksum(L1.INTCLASSES)<>checksum(isnull(L2.INTCLASSES,X.INTCLASSES)) then cast(L1.INTCLASSES as nvarchar(254))
	end,
	case
		when checksum(L1.CASETYPE)<>checksum(isnull(L2.CASETYPE,X.CASETYPE)) then cast(isnull(L2.CASETYPE,X.CASETYPE) as nvarchar(254))+' {'+CTK2.CASETYPEDESC+'}'
		when checksum(L1.PROPERTYTYPE)<>checksum(isnull(L2.PROPERTYTYPE,X.PROPERTYTYPE)) then cast(isnull(L2.PROPERTYTYPE,X.PROPERTYTYPE) as nvarchar(254))+' {'+PTK2.PROPERTYNAME+'}'
		when checksum(L1.COUNTRYCODE)<>checksum(isnull(L2.COUNTRYCODE,X.COUNTRYCODE)) then cast(isnull(L2.COUNTRYCODE,X.COUNTRYCODE) as nvarchar(254))
		when checksum(L1.CASECATEGORY)<>checksum(isnull(L2.CASECATEGORY,X.CASECATEGORY)) then cast(isnull(L2.CASECATEGORY,X.CASECATEGORY) as nvarchar(254))+' {'+CCK2.CASECATEGORYDESC+'}'
		when checksum(L1.SUBTYPE)<>checksum(isnull(L2.SUBTYPE,X.SUBTYPE)) then cast(isnull(L2.SUBTYPE,X.SUBTYPE) as nvarchar(254))+' {'+STK2.SUBTYPEDESC+'}'
		when checksum(L1.TITLE)<>checksum(isnull(L2.TITLE,X.TITLE)) then cast(isnull(L2.TITLE,X.TITLE) as nvarchar(254))
		when checksum(L1.IRN)<>checksum(isnull(L2.IRN,X.IRN)) then cast(isnull(L2.IRN,X.IRN) as nvarchar(254))
		when checksum(L1.LOCALCLASSES)<>checksum(isnull(L2.LOCALCLASSES,X.LOCALCLASSES)) then cast(isnull(L2.LOCALCLASSES,X.LOCALCLASSES) as nvarchar(254))
		when checksum(L1.INTCLASSES)<>checksum(isnull(L2.INTCLASSES,X.INTCLASSES)) then cast(isnull(L2.INTCLASSES,X.INTCLASSES) as nvarchar(254))
	end,"
	Set @sSQLString2="
	TI.BATCHNO, L1.LOGDATETIMESTAMP, TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO
	from CASES_iLOG L1
	left join CASES_iLOG L2 on (L1.LOGACTION='U'
				and L2.CASEID=L1.CASEID
				and L2.LOGDATETIMESTAMP=(select min(L3.LOGDATETIMESTAMP)
							 from CASES_iLOG L3
							 where L3.CASEID=L1.CASEID
							 and L3.LOGDATETIMESTAMP>L1.LOGDATETIMESTAMP))
	left join CASES X on (L1.LOGACTION='U'
				and L2.LOGDATETIMESTAMP is null
				and X.CASEID=L1.CASEID)
	join #CASESTOREPORT C on (C.CASEID = L1.CASEID)
	left join CASETYPE CTK1 on (CTK1.CASETYPE=L1.CASETYPE)
	left join CASETYPE CTK2 on (CTK2.CASETYPE=isnull(L2.CASETYPE,X.CASETYPE))
	left join CASECATEGORY CCK1 on (CCK1.CASETYPE=L1.CASETYPE and
				    CCK1.CASECATEGORY = L1.CASECATEGORY)
	left join CASECATEGORY CCK2 on (CCK2.CASETYPE=isnull(L2.CASETYPE,X.CASETYPE) and
				    CCK2.CASECATEGORY = isnull(L2.CASECATEGORY,X.CASECATEGORY))
	left join PROPERTYTYPE PTK1 on (PTK1.PROPERTYTYPE=L1.PROPERTYTYPE)
	left join PROPERTYTYPE PTK2 on (PTK2.PROPERTYTYPE=isnull(L2.PROPERTYTYPE,X.PROPERTYTYPE))
	left join SUBTYPE STK1 on (STK1.SUBTYPE=L1.SUBTYPE)
	left join SUBTYPE STK2 on (STK2.SUBTYPE=isnull(L2.SUBTYPE,X.SUBTYPE))
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION='U' and 
	(checksum(L1.CASETYPE)<>checksum(isnull(L2.CASETYPE,X.CASETYPE)) or
	checksum(L1.PROPERTYTYPE)<>checksum(isnull(L2.PROPERTYTYPE,X.PROPERTYTYPE)) or
	checksum(L1.COUNTRYCODE)<>checksum(isnull(L2.COUNTRYCODE,X.COUNTRYCODE)) or
	checksum(L1.CASECATEGORY)<>checksum(isnull(L2.CASECATEGORY,X.CASECATEGORY)) or
	checksum(L1.SUBTYPE)<>checksum(isnull(L2.SUBTYPE,X.SUBTYPE)) or
	checksum(L1.TITLE)<>checksum(isnull(L2.TITLE,X.TITLE)) or
	checksum(L1.IRN)<>checksum(isnull(L2.IRN,X.IRN)) or
	checksum(L1.LOCALCLASSES)<>checksum(isnull(L2.LOCALCLASSES,X.LOCALCLASSES)) or
	checksum(L1.INTCLASSES)<>checksum(isnull(L2.INTCLASSES,X.INTCLASSES))
	) and "+@sLocalSQLWhere

	Exec (@sSQLString+@sSQLString2)
	Set @nErrorCode=@@error
End

If @nErrorCode = 0
Begin
	-- Clear out rows from #NAMESTOREPORT.
	Set @sSQLString="
	Delete from #NAMESTOREPORT"

	Exec @nErrorCode=sp_executesql @sSQLString
End

If @nErrorCode = 0
Begin
	-- Find all the names related to the data source (date instructor).
	-- Note this is different to above insert to same table as it has CASEID.
	Set @sSQLString="
	Insert into #NAMESTOREPORT (NAMENO, NAMETYPE, CASEID)
	select distinct CN.NAMENO, CN.NAMETYPE, CN.CASEID
	from CASENAME C
	join CASENAME CN on (CN.CASEID = C.CASEID and C.NAMETYPE = 'DI')
	join SITECONTROL SC on (SC.CONTROLID = 'EDE Name Group')
	join NAMEGROUPS NG on (NG.GROUPDESCRIPTION = SC.COLCHARACTER)
	join GROUPMEMBERS GM on (GM.NAMEGROUP = NG.NAMEGROUP)
	where C.NAMENO = @nDocRecipient and C.NAMETYPE = 'DI'
	and CN.NAMETYPE = GM.NAMETYPE and CN.NAMETYPE in ('I','DIV','D') 
	and (CN.INHERITED <> 1 or CN.INHERITED is null)"

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nDocRecipient		int',
		  @nDocRecipient		= @nDocRecipient
End

If @nErrorCode = 0
Begin
	-- Report on the NAME_iLOG table.
	Set @sSQLString="
	Insert into #AMENDEDCASES (CASEID, FIELD, OLDVALUE, NEWVALUE, EDEBATCHNO, DATEOFCHANGE, TRANSACTIONREASONNO, TRANSACTIONMESSAGENO)
	Select distinct CN.CASEID, 
	case
		when checksum(L1.NAMECODE)<>checksum(isnull(L2.NAMECODE,X.NAMECODE))
		then 'Name Code'+' ('+NT.DESCRIPTION+')'
		when checksum(L1.NAME)<>checksum(isnull(L2.NAME,X.NAME))
		then 'Name'+' ('+NT.DESCRIPTION+')'
		when checksum(L1.MAINCONTACT)<>checksum(isnull(L2.MAINCONTACT,X.MAINCONTACT))
		then 'Main Contact'+' ('+NT.DESCRIPTION+')'
	end,
	case
		when checksum(L1.NAMECODE)<>checksum(isnull(L2.NAMECODE,X.NAMECODE)) then cast(L1.NAMECODE as nvarchar(254))
		when checksum(L1.NAME)<>checksum(isnull(L2.NAME,X.NAME)) then cast(L1.NAME as nvarchar(254))
		when checksum(L1.MAINCONTACT)<>checksum(isnull(L2.MAINCONTACT,X.MAINCONTACT)) 
		then cast(isnull(dbo.fn_FormatNameUsingNameNo(MC1.NAMENO,null), MC1.NAME) as nvarchar(254))
	end,
	case
		when checksum(L1.NAMECODE)<>checksum(isnull(L2.NAMECODE,X.NAMECODE)) then cast(isnull(L2.NAMECODE,X.NAMECODE) as nvarchar(254))
		when checksum(L1.NAME)<>checksum(isnull(L2.NAME,X.NAME)) then cast(isnull(L2.NAME,X.NAME) as nvarchar(254))
		when checksum(L1.MAINCONTACT)<>checksum(isnull(L2.MAINCONTACT,X.MAINCONTACT))
		then cast(isnull(isnull(dbo.fn_FormatNameUsingNameNo(MC2.NAMENO,null), MC2.NAME),isnull(dbo.fn_FormatNameUsingNameNo(MCX.NAMENO,null), MCX.NAME)) as nvarchar(254))
	end,
	TI.BATCHNO, L1.LOGDATETIMESTAMP, TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO
	from NAME_iLOG L1
	left join NAME_iLOG L2 on (L1.LOGACTION='U'
				and L2.NAMENO=L1.NAMENO
				and L2.LOGDATETIMESTAMP=(select min(L3.LOGDATETIMESTAMP)
							 from NAME_iLOG L3
							 where L3.NAMENO=L1.NAMENO
							 and L3.LOGDATETIMESTAMP>L1.LOGDATETIMESTAMP))
	left join NAME X on (L1.LOGACTION='U'
				and L2.LOGDATETIMESTAMP is null
				and X.NAMENO=L1.NAMENO)
	join #NAMESTOREPORT N on (N.NAMENO = L1.NAMENO)
	join CASENAME CN on (CN.NAMENO = N.NAMENO and CN.NAMETYPE = N.NAMETYPE and CN.CASEID = N.CASEID)
	left join NAMETYPE NT on (NT.NAMETYPE = CN.NAMETYPE)
	left join NAME MC1 on (MC1.NAMENO = L1.MAINCONTACT)
	left join NAME MC2 on (MC2.NAMENO = L2.MAINCONTACT)
	left join NAME MCX on (MCX.NAMENO = X.MAINCONTACT)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION='U' and 
	(checksum(L1.NAMECODE)<>checksum(isnull(L2.NAMECODE,X.NAMECODE)) or
	checksum(L1.NAME)<>checksum(isnull(L2.NAME,X.NAME)) or
	(checksum(L1.MAINCONTACT)<>checksum(isnull(L2.MAINCONTACT,X.MAINCONTACT)) and N.NAMETYPE in ('DIV', 'O'))
	) and "+@sLocalSQLWhere

	Exec @nErrorCode=sp_executesql @sSQLString
End

If @nErrorCode = 0
Begin
	-- Report on the RELATEDCASE_iLOG table.
	-- Parent Number = RELATEDCASE_iLOG.OFFICIALNUMBER for relation 'RER'.
	-- Earliest Priority No. = CASERELATION_iLOG.OFFICIALNUMBER for relation 'BAS'.
	-- Parent Date = CASERELATION_iLOG.PRIORITYDATE for relation 'BAS'.
	-- Designated Country = CASERELATION_iLOG.COUNTRYCODE for relation 'DC1'.
	Set @sSQLString="
	Insert into #AMENDEDCASES (CASEID, FIELD, OLDVALUE, NEWVALUE, EDEBATCHNO, DATEOFCHANGE, TRANSACTIONREASONNO, TRANSACTIONMESSAGENO)
	Select L1.CASEID,
	case
		when checksum(L1.OFFICIALNUMBER)<>checksum(isnull(L2.OFFICIALNUMBER,X.OFFICIALNUMBER)) and L1.RELATIONSHIP = 'RER'
		then 'Parent Number'
		when checksum(L1.OFFICIALNUMBER)<>checksum(isnull(L2.OFFICIALNUMBER,X.OFFICIALNUMBER)) and L1.RELATIONSHIP = 'BAS'
		then 'Earliest Priority No.'
		when checksum(L1.PRIORITYDATE)<>checksum(isnull(L2.PRIORITYDATE,X.PRIORITYDATE)) and L1.RELATIONSHIP = 'RER'
		then 'Parent Date'
		when checksum(L1.COUNTRYCODE)<>checksum(isnull(L2.COUNTRYCODE,X.COUNTRYCODE)) and L1.RELATIONSHIP = 'DC1'
		then 'Designated Country'
	end,
	case
		when checksum(L1.OFFICIALNUMBER)<>checksum(isnull(L2.OFFICIALNUMBER,X.OFFICIALNUMBER))
		then cast(L1.OFFICIALNUMBER as nvarchar(254))
		when checksum(L1.PRIORITYDATE)<>checksum(isnull(L2.PRIORITYDATE,X.PRIORITYDATE))
		then cast(L1.PRIORITYDATE as nvarchar(254))
		when checksum(L1.COUNTRYCODE)<>checksum(isnull(L2.COUNTRYCODE,X.COUNTRYCODE))
		then cast(L1.COUNTRYCODE as nvarchar(254))
	end,
	case
		when checksum(L1.OFFICIALNUMBER)<>checksum(isnull(L2.OFFICIALNUMBER,X.OFFICIALNUMBER))
		then cast(isnull(L2.OFFICIALNUMBER,X.OFFICIALNUMBER) as nvarchar(254))
		when checksum(L1.PRIORITYDATE)<>checksum(isnull(L2.PRIORITYDATE,X.PRIORITYDATE))
		then convert(nvarchar, isnull(L2.PRIORITYDATE,X.PRIORITYDATE), 112)
		when checksum(L1.COUNTRYCODE)<>checksum(isnull(L2.COUNTRYCODE,X.COUNTRYCODE))
		then cast(isnull(L2.COUNTRYCODE,X.COUNTRYCODE) as nvarchar(254))
	end,
	TI.BATCHNO, L1.LOGDATETIMESTAMP, TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO
	from RELATEDCASE_iLOG L1
	left join RELATEDCASE_iLOG L2 on (L1.LOGACTION='U'
				and L2.CASEID=L1.CASEID
				and L2.RELATIONSHIPNO=L1.RELATIONSHIPNO
				and L2.LOGDATETIMESTAMP=(select min(L3.LOGDATETIMESTAMP)
							 from RELATEDCASE_iLOG L3
							 where L3.LOGACTION=L3.LOGACTION
							and L3.CASEID=L1.CASEID
							and L3.RELATIONSHIPNO=L1.RELATIONSHIPNO
							 and L3.LOGDATETIMESTAMP>L1.LOGDATETIMESTAMP))
	left join RELATEDCASE X on (L1.LOGACTION='U'
				and L2.LOGDATETIMESTAMP is null
				and X.CASEID=L1.CASEID
				and X.RELATIONSHIPNO=L1.RELATIONSHIPNO)
	join #CASESTOREPORT C on (C.CASEID = L1.CASEID)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION='U' and 
	((checksum(L1.OFFICIALNUMBER)<>checksum(isnull(L2.OFFICIALNUMBER,X.OFFICIALNUMBER)) and L1.RELATIONSHIP = 'RER') or
	(checksum(L1.OFFICIALNUMBER)<>checksum(isnull(L2.OFFICIALNUMBER,X.OFFICIALNUMBER)) and L1.RELATIONSHIP = 'BAS') or 
	(checksum(L1.PRIORITYDATE)<>checksum(isnull(L2.PRIORITYDATE,X.PRIORITYDATE)) and L1.RELATIONSHIP = 'RER') or
	(checksum(L1.COUNTRYCODE)<>checksum(isnull(L2.COUNTRYCODE,X.COUNTRYCODE)) and L1.RELATIONSHIP = 'DC1')
	) and "+@sLocalSQLWhere

	Exec @nErrorCode=sp_executesql @sSQLString
End

If @nErrorCode = 0
Begin
	-- Report on RELATEDCASE_iLOG table.
	-- Only specifically for Designated Country added, 'DC1'.
	-- That is a row inserted to RELATEDCASE table, 'I'.
	Set @sSQLString="
	Insert into #AMENDEDCASES (CASEID, FIELD, OLDVALUE, NEWVALUE, EDEBATCHNO, DATEOFCHANGE, TRANSACTIONREASONNO, TRANSACTIONMESSAGENO)
	select L1.CASEID,'Designated Country',null,cast(L1.COUNTRYCODE as nvarchar(254)),
	TI.BATCHNO, L1.LOGDATETIMESTAMP, TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO
	from RELATEDCASE_iLOG L1
	join #CASESTOREPORT C on (C.CASEID = L1.CASEID)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('I')
	and L1.RELATIONSHIP = 'DC1'
	and L1.RELATEDCASEID is null and "+@sLocalSQLWhere

	Exec @nErrorCode=sp_executesql @sSQLString
End

If @nErrorCode = 0
Begin
	-- Report on the CASENAME_iLOG table.
	-- Reference Number = CASENAME.REFERENCENO.

	-- sqa21295 CHANGE TI.CASEID WITH L1.CASEID on the line below.  Grouping should be based on CASEID on each log entry.
	--row_number () over ( partition by TI.CASEID, L1.NAMENO, L1.NAMETYPE, L1.SEQUENCE, TI.BATCHNO order by L1.LOGDATETIMESTAMP) as RowNumber"
	
	Set @sSQLString="
	with CASENAMEORDER1
	as ( 	
	Select distinct L1.CASEID, 
	case
		when checksum(L1.REFERENCENO)<>checksum(isnull(L2.REFERENCENO,X.REFERENCENO)) then NT1.DESCRIPTION+' (Reference No)'
		when checksum(L1.NAMETYPE)<>checksum(isnull(L2.NAMETYPE,X.NAMETYPE)) then 'Case Name Type'
	end as Description, 
	case
		when checksum(L1.REFERENCENO)<>checksum(isnull(L2.REFERENCENO,X.REFERENCENO)) then L1.REFERENCENO
		when checksum(L1.NAMETYPE)<>checksum(isnull(L2.NAMETYPE,X.NAMETYPE)) then NT1.DESCRIPTION
	end as Before,
	case
		when checksum(L1.REFERENCENO)<>checksum(isnull(L2.REFERENCENO,X.REFERENCENO)) then isnull(L2.REFERENCENO,X.REFERENCENO)
		when checksum(L1.NAMETYPE)<>checksum(isnull(L2.NAMETYPE,X.NAMETYPE)) then isnull(NT1.DESCRIPTION,NTX.DESCRIPTION)
	end as After,
	TI.BATCHNO, L1.LOGDATETIMESTAMP, TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO, L1.NAMENO, L1.NAMETYPE, L1.SEQUENCE,
	row_number () over ( partition by L1.CASEID, L1.NAMENO, L1.NAMETYPE, L1.SEQUENCE, TI.BATCHNO order by L1.LOGDATETIMESTAMP) as RowNumber"
	If @nDocRecipient is not null
	Begin
		Set @sSQLString=@sSQLString+"
	from #CASENAME_iLOG L1
	left join #CASENAME_iLOG L2 on (L1.LOGACTION='U'
				and L2.CASEID=L1.CASEID
				and L2.NAMETYPE=L1.NAMETYPE
				and L2.SEQUENCE=L1.SEQUENCE	
				and L2.LOGDATETIMESTAMP=(select min(L3.LOGDATETIMESTAMP)
							 from #CASENAME_iLOG L3
							 where L3.CASEID=L1.CASEID
 							 and L3.NAMETYPE=L1.NAMETYPE
							 and L3.SEQUENCE=L1.SEQUENCE
							 and L3.LOGDATETIMESTAMP>L1.LOGDATETIMESTAMP))"
	End
	Else
	Begin
	Set @sSQLString=@sSQLString+"
	from CASENAME_iLOG L1
	left join CASENAME_iLOG L2 on (L1.LOGACTION='U'
				and L2.CASEID=L1.CASEID
				and L2.NAMETYPE=L1.NAMETYPE
				and L2.SEQUENCE=L1.SEQUENCE	
				and L2.LOGDATETIMESTAMP=(select min(L3.LOGDATETIMESTAMP)
							 from CASENAME_iLOG L3
							 where L3.CASEID=L1.CASEID
 							 and L3.NAMETYPE=L1.NAMETYPE
							 and L3.SEQUENCE=L1.SEQUENCE
							 and L3.LOGDATETIMESTAMP>L1.LOGDATETIMESTAMP))"
	End
	Set @sSQLString=@sSQLString+"	

	left join CASENAME X on (L1.LOGACTION='U'
				and L2.LOGDATETIMESTAMP is null
				and X.CASEID=L1.CASEID
				and X.NAMETYPE=L1.NAMETYPE
				and X.SEQUENCE=L1.SEQUENCE)
	left join NAMETYPE NT1 on (NT1.NAMETYPE = L1.NAMETYPE)
	left join NAMETYPE NT2 on (NT2.NAMETYPE = L2.NAMETYPE)
	left join NAMETYPE NTX on (NTX.NAMETYPE = X.NAMETYPE)
	join GROUPMEMBERS GM on (GM.NAMETYPE = L1.NAMETYPE)
	join NAMEGROUPS NG on (NG.NAMEGROUP = GM.NAMEGROUP)
	join SITECONTROL SC on (upper(SC.COLCHARACTER) = upper(NG.GROUPDESCRIPTION) and SC.CONTROLID = 'EDE Name Group')
	join #CASESTOREPORT C on (C.CASEID = L1.CASEID)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION='U' and 
	(L1.INHERITEDNAMENO is null) and
	(checksum(L1.REFERENCENO)<>checksum(isnull(L2.REFERENCENO,X.REFERENCENO)) or
	checksum(L1.NAMETYPE)<>checksum(isnull(L2.NAMETYPE,X.NAMETYPE))
	) and "+@sLocalSQLWhere+"
	)
	Insert into #AMENDEDCASES (CASEID, FIELD, OLDVALUE, NEWVALUE, EDEBATCHNO, DATEOFCHANGE, TRANSACTIONREASONNO, TRANSACTIONMESSAGENO)
	Select E1.CASEID, E1.Description, E1.Before, E2.After, E1.BATCHNO, E1.LOGDATETIMESTAMP, E1.TRANSACTIONREASONNO, E1.TRANSACTIONMESSAGENO
	from CASENAMEORDER1 E1
	join CASENAMEORDER1 E2 ON (E2.CASEID = E1.CASEID
							and E2.NAMETYPE = E1.NAMETYPE
							and E2.NAMENO = E1.NAMENO
							and E2.SEQUENCE = E1.SEQUENCE
							and E2.RowNumber = (select max(RowNumber) from CASENAMEORDER1 
											where CASEID = E2.CASEID
											and NAMETYPE = E2.NAMETYPE
											and NAMENO = E2.NAMENO
											and SEQUENCE = E2.SEQUENCE))
	where E1.RowNumber = 1"
	
	Exec @nErrorCode=sp_executesql @sSQLString
End

If @nErrorCode = 0
Begin
	-- Report on the CASENAME_iLOG table.
	-- Name = CASENAME.NAMENO.
	
	-- sqa21295 CHANGE TI.CASEID WITH L1.CASEID on the line below.  Grouping should be based on CASEID on each log entry.
	-- row_number () over ( partition by TI.CASEID, L1.NAMENO, L1.NAMETYPE, L1.SEQUENCE, TI.BATCHNO order by L1.LOGDATETIMESTAMP) as RowNumber"
	Set @sSQLString="
	with CASENAMEORDER1
	as (
	Select distinct L1.CASEID, NT1.DESCRIPTION+' (Name)' as Description,
	dbo.fn_FormatNameUsingNameNo(N1.NAMENO,null)+ case when N1.NAMECODE is not null then ' {'+N1.NAMECODE+'}' end  as Before,
	isnull(dbo.fn_FormatNameUsingNameNo(N2.NAMENO,null)+ case when N2.NAMECODE is not null then ' {'+N2.NAMECODE+'}' end,
	dbo.fn_FormatNameUsingNameNo(NX.NAMENO,null)+ case when NX.NAMECODE is not null then ' {'+NX.NAMECODE+'}' end) as After,
	TI.BATCHNO, L1.LOGDATETIMESTAMP, TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO, L1.NAMENO, L1.NAMETYPE, L1.SEQUENCE,
	row_number () over ( partition by L1.CASEID, L1.NAMENO, L1.NAMETYPE, L1.SEQUENCE, TI.BATCHNO order by L1.LOGDATETIMESTAMP) as RowNumber"
	If @nDocRecipient is not null
	Begin
		Set @sSQLString=@sSQLString+"
	from #CASENAME_iLOG L1
	left join #CASENAME_iLOG L2 on (L1.LOGACTION='U'
				and L2.CASEID=L1.CASEID
				and L2.NAMETYPE=L1.NAMETYPE
				and L2.SEQUENCE=L1.SEQUENCE	
				and L2.LOGDATETIMESTAMP=(select min(L3.LOGDATETIMESTAMP)
							 from #CASENAME_iLOG L3
							 where L3.CASEID=L1.CASEID
 							 and L3.NAMETYPE=L1.NAMETYPE
							 and L3.SEQUENCE=L1.SEQUENCE
							 and L3.LOGDATETIMESTAMP>L1.LOGDATETIMESTAMP))"
	End
	Else
	Begin
	Set @sSQLString=@sSQLString+"
	from CASENAME_iLOG L1
	left join CASENAME_iLOG L2 on (L1.LOGACTION='U'
				and L2.CASEID=L1.CASEID
				and L2.NAMETYPE=L1.NAMETYPE
				and L2.SEQUENCE=L1.SEQUENCE	
				and L2.LOGDATETIMESTAMP=(select min(L3.LOGDATETIMESTAMP)
							 from CASENAME_iLOG L3
							 where L3.CASEID=L1.CASEID
 							 and L3.NAMETYPE=L1.NAMETYPE
							 and L3.SEQUENCE=L1.SEQUENCE
							 and L3.LOGDATETIMESTAMP>L1.LOGDATETIMESTAMP))"
	End
	Set @sSQLString=@sSQLString+"
	left join CASENAME X on (L1.LOGACTION='U'
				and L2.LOGDATETIMESTAMP is null
				and X.CASEID=L1.CASEID
				and X.NAMETYPE=L1.NAMETYPE
				and X.SEQUENCE=L1.SEQUENCE)
	left join NAMETYPE NT1 on (NT1.NAMETYPE = L1.NAMETYPE)
	left join NAME N1 on (N1.NAMENO = L1.NAMENO)
	left join NAME N2 on (N2.NAMENO = L2.NAMENO)
	left join NAME NX on (NX.NAMENO = X.NAMENO)
	join GROUPMEMBERS GM on (GM.NAMETYPE = L1.NAMETYPE)
	join NAMEGROUPS NG on (NG.NAMEGROUP = GM.NAMEGROUP)
	join SITECONTROL SC on (upper(SC.COLCHARACTER) = upper(NG.GROUPDESCRIPTION) and SC.CONTROLID = 'EDE Name Group')
	join #CASESTOREPORT C on (C.CASEID = L1.CASEID)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION='U' and 
	(L1.INHERITEDNAMENO is null) and
	(checksum(L1.NAMENO)<>checksum(isnull(L2.NAMENO,X.NAMENO))
	) and "+@sLocalSQLWhere+"
	)
	Insert into #AMENDEDCASES (CASEID, FIELD, OLDVALUE, NEWVALUE, EDEBATCHNO, DATEOFCHANGE, TRANSACTIONREASONNO, TRANSACTIONMESSAGENO)
	Select E1.CASEID, E1.Description, E1.Before, E2.After, E1.BATCHNO, E1.LOGDATETIMESTAMP, E1.TRANSACTIONREASONNO, E1.TRANSACTIONMESSAGENO
	from CASENAMEORDER1 E1
	join CASENAMEORDER1 E2 ON (E2.CASEID = E1.CASEID
							and E2.NAMETYPE = E1.NAMETYPE
							and E2.NAMENO = E1.NAMENO
							and E2.SEQUENCE = E1.SEQUENCE
							and E2.RowNumber = (select max(RowNumber) from CASENAMEORDER1 
											where CASEID = E2.CASEID
											and NAMETYPE = E2.NAMETYPE
											and NAMENO = E2.NAMENO
											and SEQUENCE = E2.SEQUENCE))
	where E1.RowNumber = 1"

	Exec @nErrorCode=sp_executesql @sSQLString
End

If @nErrorCode = 0
Begin
	-- Find events to report and the correct cycle to report.
	Delete from #CASESEVENTDATESTOREPORT

	Set @sSQLString="
	Insert into #CASESEVENTDATESTOREPORT(CASEID, EVENTNO, EVENTDATE, EVENTDUEDATE, CYCLE)
	Select CE.CASEID, CE.EVENTNO, CE.EVENTDATE, CE.EVENTDUEDATE, CE.CYCLE
	from CASEEVENT CE
	join #CASESTOREPORT CRD on (CRD.CASEID = CE.CASEID)
	Join (	select MIN(O.CYCLE) as [CYCLE], O.CASEID
		from OPENACTION O
		join SITECONTROL SC on (SC.CONTROLID='Main Renewal Action')
		where O.ACTION=SC.COLCHARACTER
		and O.POLICEEVENTS=1
		group by O.CASEID) OA on (OA.CASEID = CE.CASEID and OA.CYCLE = CE.CYCLE)
	join EVENTS E on (E.EVENTNO = CE.EVENTNO)  
	where CE.EVENTNO = -11
	and E.IMPORTANCELEVEL >= (select COLINTEGER 
				from SITECONTROL 
				where CONTROLID = 'Client Importance')
	union
	Select distinct CE.CASEID, CE.EVENTNO, CE.EVENTDATE, CE.EVENTDUEDATE, CE.CYCLE
	from CASEEVENT CE
	join #CASESTOREPORT CRD on (CRD.CASEID = CE.CASEID)
	join CASES C on (C.CASEID = CRD.CASEID)
	join (	select CE01.CASEID, CE01.EVENTNO
		from CASEEVENT CE01
		join #CASESTOREPORT CRD2 on (CRD2.CASEID = CE01.CASEID)
		where CE01.CASEID = CRD2.CASEID
		group by CE01.CASEID, CE01.EVENTNO
		having count(*) > 1    
		) as CE2 on (CE2.CASEID = CE.CASEID and CE2.EVENTNO = CE.EVENTNO)
	join(	select CASEID, ACTION, CRITERIANO, min(CYCLE) as CYCLE
		from OPENACTION
		where POLICEEVENTS=1
		group by CASEID, ACTION, CRITERIANO) OA 
				on (OA.CASEID=CE.CASEID)
	join EVENTCONTROL EC on (EC.CRITERIANO=OA.CRITERIANO
			     and EC.EVENTNO=CE.EVENTNO)
	join ACTIONS A on (A.ACTION=OA.ACTION)"
	Set @sSQLString2="
	where CE.EVENTNO != -11
	and CE.EVENTNO in (	Select EV.EVENTNO
				from (Select CRITERIANO from dbo.fn_GetCriteriaRows('E',null,'A','"+@sEDEActionCode+"',null,null,null,C.PROPERTYTYPE,C.COUNTRYCODE,C.CASECATEGORY,C.SUBTYPE,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,0,null)) as BESTCRIT
				join EVENTCONTROL EV on (EV.CRITERIANO = BESTCRIT.CRITERIANO)
			) 
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
		     END
	union
	Select CE.CASEID, CE.EVENTNO, CE.EVENTDATE, CE.EVENTDUEDATE, CE.CYCLE
	from CASEEVENT CE
	join #CASESTOREPORT CRD on (CRD.CASEID = CE.CASEID)
	join CASES C on (C.CASEID = CRD.CASEID)
	join (	select CE01.CASEID, CE01.EVENTNO
		from CASEEVENT CE01
		join #CASESTOREPORT CRD2 on (CRD2.CASEID = CE01.CASEID)
		where CE01.CASEID = CRD2.CASEID
		group by CE01.CASEID, CE01.EVENTNO
		having count(*) = 1    
		) as CE2 on (CE2.CASEID = CE.CASEID and CE2.EVENTNO = CE.EVENTNO)
	where CE.EVENTNO in (	Select EV.EVENTNO
				from (Select CRITERIANO from dbo.fn_GetCriteriaRows('E',null,'A','"+@sEDEActionCode+"',null,null,null,C.PROPERTYTYPE,C.COUNTRYCODE,C.CASECATEGORY,C.SUBTYPE,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,0,null)) as BESTCRIT
				join EVENTCONTROL EV on (EV.CRITERIANO = BESTCRIT.CRITERIANO)
			)"
	
	Exec (@sSQLString+@sSQLString2)
	Set @nErrorCode=@@error
End

-------------
-- INSERTS --
-------------
If @nErrorCode = 0
Begin
	-- Report on inserts on the NAME_iLOG table. 
	Set @sSQLString="
	Insert into #AMENDEDCASES (CASEID, FIELD, OLDVALUE, NEWVALUE, EDEBATCHNO, DATEOFCHANGE, TRANSACTIONREASONNO, TRANSACTIONMESSAGENO)
	Select N.CASEID, 'Name Code', null, L1.NAMECODE, TI.BATCHNO, L1.LOGDATETIMESTAMP, TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO
	from NAME_iLOG L1
	join #NAMESTOREPORT N on (N.NAMENO = L1.NAMENO)
	join CASENAME CN on (CN.NAMENO = N.NAMENO and CN.NAMETYPE = N.NAMETYPE and CN.CASEID = N.CASEID)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('I')
	and L1.NAMECODE is not null
	and "+@sLocalSQLWhere+"
	union
	Select N.CASEID, 'Name', null, L1.NAME, TI.BATCHNO, L1.LOGDATETIMESTAMP,  TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO
	from NAME_iLOG L1
	join #NAMESTOREPORT N on (N.NAMENO = L1.NAMENO)
	join CASENAME CN on (CN.NAMENO = N.NAMENO and CN.NAMETYPE = N.NAMETYPE and CN.CASEID = N.CASEID)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('I')
	and L1.NAME is not null
	and "+@sLocalSQLWhere+"
	union
	Select N.CASEID, 'Main Contact', null, dbo.fn_FormatNameUsingNameNo(MC.NAMENO,null), TI.BATCHNO, L1.LOGDATETIMESTAMP,  TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO
	from NAME_iLOG L1
	join #NAMESTOREPORT N on (N.NAMENO = L1.NAMENO)
	join CASENAME CN on (CN.NAMENO = N.NAMENO and CN.NAMETYPE = N.NAMETYPE and CN.CASEID = N.CASEID)
	left join NAME MC on (MC.NAMENO = L1.MAINCONTACT)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('I')
	and L1.NAME is not null
	and "+@sLocalSQLWhere
End

If @nErrorCode = 0
Begin
	-- Report on inserts on the RELATEDCASE_iLOG table.
	Set @sSQLString="
	Insert into #AMENDEDCASES (CASEID, FIELD, OLDVALUE, NEWVALUE, EDEBATCHNO, DATEOFCHANGE, TRANSACTIONREASONNO, TRANSACTIONMESSAGENO)
	Select L1.CASEID, 	
	case
		when L1.RELATIONSHIP = 'RER'
		then 'Parent Number'
		when L1.RELATIONSHIP = 'BAS'
		then 'Earliest Priority No.'
	end, 
	null, L1.OFFICIALNUMBER, TI.BATCHNO, L1.LOGDATETIMESTAMP,  TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO
	from RELATEDCASE_iLOG L1
	join #CASESTOREPORT C on (C.CASEID = L1.CASEID)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('I')
	and L1.OFFICIALNUMBER is not null
	and L1.RELATIONSHIP in ('RER','BAS')
	and "+@sLocalSQLWhere+"
	union
	Select L1.CASEID, 'Parent Date', null, convert(nvarchar, L1.PRIORITYDATE, 112), TI.BATCHNO, L1.LOGDATETIMESTAMP,  TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO
	from RELATEDCASE_iLOG L1
	join #CASESTOREPORT C on (C.CASEID = L1.CASEID)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('I')
	and L1.PRIORITYDATE is not null
	and L1.RELATIONSHIP = 'RER' 
	and "+@sLocalSQLWhere+"
	union
	Select L1.CASEID, 'Designated Country', null, L1.COUNTRYCODE, TI.BATCHNO, L1.LOGDATETIMESTAMP,  TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO
	from RELATEDCASE_iLOG L1
	join #CASESTOREPORT C on (C.CASEID = L1.CASEID)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('I')
	and L1.COUNTRYCODE is not null
	and L1.RELATIONSHIP = 'DC1' 
	and "+@sLocalSQLWhere

	Exec @nErrorCode=sp_executesql @sSQLString
End

If @nErrorCode = 0
Begin
	-- Report only inserts specifically for Designated Country added, 'DC1'.
	Set @sSQLString="
	Insert into #AMENDEDCASES (CASEID, FIELD, OLDVALUE, NEWVALUE, EDEBATCHNO, DATEOFCHANGE, TRANSACTIONREASONNO, TRANSACTIONMESSAGENO)
	select L1.CASEID, 'Designated Country', null, L1.COUNTRYCODE, TI.BATCHNO, L1.LOGDATETIMESTAMP, TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO
	from RELATEDCASE_iLOG L1
	join #CASESTOREPORT C on (C.CASEID = L1.CASEID)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('I')
	and L1.RELATIONSHIP = 'DC1'
	and L1.COUNTRYCODE is not null
	and L1.RELATEDCASEID is null 
	and "+@sLocalSQLWhere

	Exec @nErrorCode=sp_executesql @sSQLString
End

If @nErrorCode = 0
Begin
	-- Report on the inserts on CASENAME_iLOG table.
	-- Reference Number = CASENAME.REFERENCENO.
	Set @sSQLString="
	Insert into #AMENDEDCASES (CASEID, FIELD, OLDVALUE, NEWVALUE, EDEBATCHNO, DATEOFCHANGE, TRANSACTIONREASONNO, TRANSACTIONMESSAGENO)
	select L1.CASEID, NT.DESCRIPTION+' (Reference No)', null, L1.REFERENCENO, TI.BATCHNO, L1.LOGDATETIMESTAMP, TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO"
	If @nDocRecipient is not null
	Begin
		Set @sSQLString=@sSQLString+"
		from #CASENAME_iLOG L1"
	End
	Else
	Begin
	Set @sSQLString=@sSQLString+"
		from CASENAME_iLOG L1"
	End
	Set @sSQLString=@sSQLString+"
	join #CASESTOREPORT C on (C.CASEID = L1.CASEID)
	join NAMETYPE NT on (NT.NAMETYPE = L1.NAMETYPE)
	join GROUPMEMBERS GM on (GM.NAMETYPE = L1.NAMETYPE)
	join NAMEGROUPS NG on (NG.NAMEGROUP = GM.NAMEGROUP)
	join SITECONTROL SC on (SC.COLCHARACTER = NG.GROUPDESCRIPTION and SC.CONTROLID = 'EDE Name Group')
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('I') 
	and (L1.INHERITEDNAMENO is null)
	and L1.REFERENCENO is not null
	and "+@sLocalSQLWhere
	
	Exec @nErrorCode=sp_executesql @sSQLString
End	

If @nErrorCode = 0
Begin
	Set @sSQLString="
	with CASENAMEORDER1
	as ( 
	select L1.CASEID, NT.DESCRIPTION+' (Name)' as Description,
	null as Before, dbo.fn_FormatNameUsingNameNo(N.NAMENO,null)+ case when N.NAMECODE is not null then ' {'+N.NAMECODE+'}' end as After,
	TI.BATCHNO, L1.LOGDATETIMESTAMP, TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO, L1.NAMENO, L1.SEQUENCE, L1.NAMETYPE,
	row_number () over ( partition by TI.CASEID, L1.NAMETYPE, L1.SEQUENCE order by L1.LOGDATETIMESTAMP) as RowNumber"
	If @nDocRecipient is not null
	Begin
		Set @sSQLString=@sSQLString+"
		from #CASENAME_iLOG L1"
	End
	Else
	Begin
	Set @sSQLString=@sSQLString+"
		from CASENAME_iLOG L1"
	End
	Set @sSQLString=@sSQLString+"
	join #CASESTOREPORT C on (C.CASEID = L1.CASEID)
	join NAMETYPE NT on (NT.NAMETYPE = L1.NAMETYPE)
	join NAME N on (N.NAMENO = L1.NAMENO)
	join GROUPMEMBERS GM on (GM.NAMETYPE = L1.NAMETYPE)
	join NAMEGROUPS NG on (NG.NAMEGROUP = GM.NAMEGROUP)
	join SITECONTROL SC on (upper(SC.CONTROLID) = upper(NG.GROUPDESCRIPTION) and upper(SC.CONTROLID) = 'EDE NAME GROUP')
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('I','D')
	and (L1.INHERITEDNAMENO is null)
	and L1.NAMENO is not null
	and "+@sLocalSQLWhere+"
	)
	Insert into #AMENDEDCASES (CASEID, FIELD, OLDVALUE, NEWVALUE, EDEBATCHNO, DATEOFCHANGE, TRANSACTIONREASONNO, TRANSACTIONMESSAGENO)	
	Select E1.CASEID, E1.Description, E1.After, E2.After, E1.BATCHNO, E2.LOGDATETIMESTAMP, E1.TRANSACTIONREASONNO, E1.TRANSACTIONMESSAGENO
	from CASENAMEORDER1 E1
	join CASENAMEORDER1 E2 ON (E2.CASEID = E1.CASEID
							and E2.NAMETYPE = E1.NAMETYPE 
							and E2.SEQUENCE = E1.SEQUENCE
							and E2.RowNumber = (select max(RowNumber) from CASENAMEORDER1 
											where CASEID = E2.CASEID
											and NAMETYPE = E2.NAMETYPE
											and SEQUENCE = E2.SEQUENCE))
	WHERE E1.RowNumber = 1
	and E1.After <> E2.After
	and E1.LOGDATETIMESTAMP < E2.LOGDATETIMESTAMP"
End

-------------
-- DELETES --
-------------
If @nErrorCode = 0
Begin
	-- Report on deletes on the CASES_iLOG table now.
	-- This section returns the case changes.
	-- Case Type = CASES_iLOG.CASETYPE.
	-- Property Type = CASES_iLOG.PROPERTYTYPE.
	-- Country Code = CASES_iLOG.COUNTRYCODE.
	-- Category = CASES_iLOG.CASECATEGORY.
	-- Sub Type = CASES_iLOG.SUBTYPE.
	-- Title = CASES_iLOG.TITLE.
	-- IRN = CASES_iLOG.IRN.
	-- National Classes = CASES_iLOG.LOCALCLASSES.
	-- International Classes = CASES_iLOG.INTCLASSES.
	Set @sSQLString="
	Insert into #AMENDEDCASES (CASEID, FIELD, OLDVALUE, NEWVALUE, EDEBATCHNO, DATEOFCHANGE, TRANSACTIONREASONNO, TRANSACTIONMESSAGENO)
	Select L1.CASEID, 'Case Type', FK1.CASETYPEDESC, null, TI.BATCHNO, L1.LOGDATETIMESTAMP,  TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO
	from CASES_iLOG L1
	join #CASESTOREPORT C on (C.CASEID = L1.CASEID)
	left join CASETYPE FK1 on (FK1.CASETYPE=L1.CASETYPE)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('D')
	and L1.CASETYPE is not null
	and "+@sLocalSQLWhere+"
	union
	Select L1.CASEID, 'Property Type', FK1.PROPERTYNAME, null, TI.BATCHNO, L1.LOGDATETIMESTAMP,  TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO
	from CASES_iLOG L1
	join #CASESTOREPORT C on (C.CASEID = L1.CASEID)
	left join PROPERTYTYPE FK1 on (FK1.PROPERTYTYPE=L1.PROPERTYTYPE)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('D')
	and L1.PROPERTYTYPE is not null
	and "+@sLocalSQLWhere+"
	union
	Select L1.CASEID, 'Country Code', L1.COUNTRYCODE, null, TI.BATCHNO, L1.LOGDATETIMESTAMP,  TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO
	from CASES_iLOG L1
	join #CASESTOREPORT C on (C.CASEID = L1.CASEID)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('D')
	and L1.COUNTRYCODE is not null
	and "+@sLocalSQLWhere+"
	union"
	Set @sSQLString2="
	Select L1.CASEID, 'Case Category', FK1.CASECATEGORYDESC, null, TI.BATCHNO, L1.LOGDATETIMESTAMP,  TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO
	from CASES_iLOG L1
	join #CASESTOREPORT C on (C.CASEID = L1.CASEID)
	left join CASECATEGORY FK1 on (FK1.CASETYPE=L1.CASETYPE AND FK1.CASECATEGORY=L1.CASECATEGORY)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('D')
	and L1.CASECATEGORY is not null
	and "+@sLocalSQLWhere+"
	union
	Select L1.CASEID, 'Sub Type', FK1.SUBTYPEDESC, null, TI.BATCHNO, L1.LOGDATETIMESTAMP,  TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO
	from CASES_iLOG L1
	join #CASESTOREPORT C on (C.CASEID = L1.CASEID)
	left join SUBTYPE FK1 on (FK1.SUBTYPE=L1.SUBTYPE)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('D')
	and L1.SUBTYPE is not null
	and "+@sLocalSQLWhere+"
	union
	Select L1.CASEID, 'Title', L1.TITLE, null, TI.BATCHNO, L1.LOGDATETIMESTAMP,  TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO
	from CASES_iLOG L1
	join #CASESTOREPORT C on (C.CASEID = L1.CASEID)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('D')
	and L1.TITLE is not null
	and "+@sLocalSQLWhere+"
	union
	Select L1.CASEID, 'IRN', L1.IRN, null, TI.BATCHNO, L1.LOGDATETIMESTAMP,  TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO
	from CASES_iLOG L1
	join #CASESTOREPORT C on (C.CASEID = L1.CASEID)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('D')
	and L1.IRN is not null
	and "+@sLocalSQLWhere

	Exec (@sSQLString+@sSQLString2)
	Set @nErrorCode=@@error
End

If @nErrorCode = 0
Begin
	-- Report on deletes on the NAME_iLOG table.
	Set @sSQLString="
	Insert into #AMENDEDCASES (CASEID, FIELD, OLDVALUE, NEWVALUE, EDEBATCHNO, DATEOFCHANGE, TRANSACTIONREASONNO, TRANSACTIONMESSAGENO)
	Select N.CASEID, 'Name Code', L1.NAMECODE, null, TI.BATCHNO, L1.LOGDATETIMESTAMP,  TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO
	from NAME_iLOG L1
	join #NAMESTOREPORT N on (N.NAMENO = L1.NAMENO)
	join CASENAME CN on (CN.NAMENO = N.NAMENO and CN.NAMETYPE = N.NAMETYPE and CN.CASEID = N.CASEID)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('D')
	and L1.NAMECODE is not null
	and "+@sLocalSQLWhere+"
	union
	Select N.CASEID, 'Name', L1.NAME, null, TI.BATCHNO, L1.LOGDATETIMESTAMP,  TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO
	from NAME_iLOG L1
	join #NAMESTOREPORT N on (N.NAMENO = L1.NAMENO)
	join CASENAME CN on (CN.NAMENO = N.NAMENO and CN.NAMETYPE = N.NAMETYPE and CN.CASEID = N.CASEID)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('D')
	and L1.NAME is not null
	and "+@sLocalSQLWhere+"
	union
	Select N.CASEID, 'Main Contact', dbo.fn_FormatNameUsingNameNo(MC.NAMENO,null), null, TI.BATCHNO, L1.LOGDATETIMESTAMP,  TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO
	from NAME_iLOG L1
	join #NAMESTOREPORT N on (N.NAMENO = L1.NAMENO)
	join CASENAME CN on (CN.NAMENO = N.NAMENO and CN.NAMETYPE = N.NAMETYPE and CN.CASEID = N.CASEID)
	left join NAME MC on (MC.NAMENO = L1.MAINCONTACT)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('D')
	and L1.NAME is not null
	and "+@sLocalSQLWhere

	Exec @nErrorCode=sp_executesql @sSQLString
End

If @nErrorCode = 0
Begin
	-- Report on deletes on the RELATEDCASE_iLOG table.
	Set @sSQLString="
	Insert into #AMENDEDCASES (CASEID, FIELD, OLDVALUE, NEWVALUE, EDEBATCHNO, DATEOFCHANGE, TRANSACTIONREASONNO, TRANSACTIONMESSAGENO)
	Select L1.CASEID, 	
	case
		when L1.RELATIONSHIP = 'RER'
		then 'Parent Number'
		when L1.RELATIONSHIP = 'BAS'
		then 'Earliest Priority No.'
	end, 
	L1.OFFICIALNUMBER, null, TI.BATCHNO, L1.LOGDATETIMESTAMP,  TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO
	from RELATEDCASE_iLOG L1
	join #CASESTOREPORT C on (C.CASEID = L1.CASEID)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('D')
	and L1.OFFICIALNUMBER is not null
	and L1.RELATIONSHIP in ('RER','BAS')
	and "+@sLocalSQLWhere+"
	union
	Select L1.CASEID, 'Parent Date', convert(nvarchar, L1.PRIORITYDATE, 112), null, TI.BATCHNO, L1.LOGDATETIMESTAMP,  TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO
	from RELATEDCASE_iLOG L1
	join #CASESTOREPORT C on (C.CASEID = L1.CASEID)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('D')
	and L1.PRIORITYDATE is not null
	and L1.RELATIONSHIP = 'RER' 
	and "+@sLocalSQLWhere+"
	union
	Select L1.CASEID, 'Designated Country', L1.COUNTRYCODE, null, TI.BATCHNO, L1.LOGDATETIMESTAMP,  TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO
	from RELATEDCASE_iLOG L1
	join #CASESTOREPORT C on (C.CASEID = L1.CASEID)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('D')
	and L1.COUNTRYCODE is not null
	and L1.RELATIONSHIP = 'DC1' 
	and "+@sLocalSQLWhere

	Exec @nErrorCode=sp_executesql @sSQLString
End

If @nErrorCode = 0
Begin
	-- Report only deletes specifically for Designated Country added, 'DC1'.
	Set @sSQLString="
	Insert into #AMENDEDCASES (CASEID, FIELD, OLDVALUE, NEWVALUE, EDEBATCHNO, DATEOFCHANGE, TRANSACTIONREASONNO, TRANSACTIONMESSAGENO)
	select L1.CASEID, 'Designated Country' , L1.COUNTRYCODE, null, TI.BATCHNO, L1.LOGDATETIMESTAMP, TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO
	from RELATEDCASE_iLOG L1
	join #CASESTOREPORT C on (C.CASEID = L1.CASEID)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('D')
	and L1.RELATIONSHIP = 'DC1'
	and L1.COUNTRYCODE is not null
	and L1.RELATEDCASEID is null 
	and "+@sLocalSQLWhere

	Exec @nErrorCode=sp_executesql @sSQLString
End

If @nErrorCode = 0
Begin
	-- Report on the deletes on CASENAME_iLOG table.
	-- Reference Number = CASENAME.REFERENCENO.
	Set @sSQLString="
	Insert into #AMENDEDCASES (CASEID, FIELD, OLDVALUE, NEWVALUE, EDEBATCHNO, DATEOFCHANGE, TRANSACTIONREASONNO, TRANSACTIONMESSAGENO)
	select L1.CASEID, NT.DESCRIPTION+' (Reference No)', L1.REFERENCENO, null, TI.BATCHNO, L1.LOGDATETIMESTAMP, TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO"
	If @nDocRecipient is not null
	Begin
		Set @sSQLString=@sSQLString+"
		from #CASENAME_iLOG L1"
	End
	Else
	Begin
	Set @sSQLString=@sSQLString+"
		from CASENAME_iLOG L1"
	End
	Set @sSQLString=@sSQLString+"
	join #CASESTOREPORT C on (C.CASEID = L1.CASEID)
	join NAMETYPE NT on (NT.NAMETYPE = L1.NAMETYPE)
	join GROUPMEMBERS GM on (GM.NAMETYPE = L1.NAMETYPE)
	join NAMEGROUPS NG on (NG.NAMEGROUP = GM.NAMEGROUP)
	join SITECONTROL SC on (SC.COLCHARACTER = NG.GROUPDESCRIPTION and SC.CONTROLID = 'EDE Name Group')
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('D')
	and (L1.INHERITEDNAMENO is null)
	and L1.REFERENCENO is not null
	and "+@sLocalSQLWhere

	Exec @nErrorCode=sp_executesql @sSQLString
End

------------------
-- CONSOLIDATED --
------------------
If @nErrorCode = 0
Begin
	-- Report on OFFICIALNUMBER_iLOG table.
	-- Note that we only reporting on  ('D','A','R','3') number types.
	Set @sSQLString="
	with OFFICIALNUMBERORDER1
	as ( 
	select L1.CASEID,N.DESCRIPTION  as OfficialNumberDescription, cast(L1.OFFICIALNUMBER as nvarchar(254)) as Before, 
	null as After, L1.NUMBERTYPE,
	TI.BATCHNO, L1.LOGDATETIMESTAMP, TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO, L1.LOGACTION,
	row_number () over (partition by L1.CASEID, L1.NUMBERTYPE order by L1.LOGDATETIMESTAMP) as RowNumber"
	If @nDocRecipient is not null
	Begin
		Set @sSQLString=@sSQLString+"
		from #OFFICIALNUMBERS_iLOG L1"
	End
	Else
	Begin
	Set @sSQLString=@sSQLString+"
		from OFFICIALNUMBERS_iLOG L1"
	End
	Set @sSQLString=@sSQLString+"
	join #CASESTOREPORT C on (C.CASEID = L1.CASEID)
	join NUMBERTYPES N on (N.NUMBERTYPE = L1.NUMBERTYPE)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('I','D','U')
	and L1.OFFICIALNUMBER is not null
	and "+@sLocalSQLWhere+"
	)
	Insert into #AMENDEDCASES (CASEID, FIELD, OLDVALUE, NEWVALUE, EDEBATCHNO, DATEOFCHANGE, TRANSACTIONREASONNO, TRANSACTIONMESSAGENO)
	Select E1.CASEID, E1.OfficialNumberDescription,	
	case
		when E1.Before=E2.OFFICIALNUMBER and E1.LOGACTION = 'I' then null
		else E1.Before 
	end, 
	case
		when E1.Before=E2.OFFICIALNUMBER and E1.LOGACTION = 'D' then null
		else E2.OFFICIALNUMBER 
	end,
	E1.BATCHNO, E1.LOGDATETIMESTAMP, E1.TRANSACTIONREASONNO, E1.TRANSACTIONMESSAGENO
	from OFFICIALNUMBERORDER1 E1
	left join OFFICIALNUMBERS E2 ON (E2.CASEID = E1.CASEID and E2.NUMBERTYPE = E1.NUMBERTYPE )
	WHERE E1.RowNumber = 1"

	Exec @nErrorCode=sp_executesql @sSQLString
End

If @nErrorCode = 0
Begin
	-- Report on CASEEVENT_iLOG table for event dates.
	Set @sSQLString="
	with EVENTORDER1
	as ( 
	select L1.CASEID, L1.EVENTNO, L1.CYCLE,
	E.EVENTDESCRIPTION+' ('+'Event Date)' as EventDescription, 
	L1.EVENTDATE as Before,
	null as After,
	TI.BATCHNO, L1.LOGDATETIMESTAMP, TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO, L1.LOGACTION,
	row_number() over ( partition by L1.CASEID, L1.EVENTNO, L1.CYCLE, TI.BATCHNO order by L1.LOGDATETIMESTAMP) as RowNumber"
	If @nDocRecipient is not null
	Begin
		Set @sSQLString=@sSQLString+"
		from #CASEEVENT_iLOG L1"
	End
	Else
	Begin
		Set @sSQLString=@sSQLString+"
		from CASEEVENT_iLOG L1"	
	End
	Set @sSQLString=@sSQLString+"
	join EVENTS E on (L1.EVENTNO = E.EVENTNO)
	join #CASESTOREPORT C on (C.CASEID = L1.CASEID)	
	join CASES CS on (CS.CASEID = C.CASEID)
	join #CASESEVENTDATESTOREPORT CE on (L1.CASEID = CE.CASEID and L1.EVENTNO = CE.EVENTNO and L1.CYCLE = CE.CYCLE)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('I','D','U')
	and L1.EVENTDATE is not null
	and "+@sLocalSQLWhere+"
	)
	Insert into #AMENDEDCASES (CASEID, FIELD, OLDVALUE, NEWVALUE, EDEBATCHNO, DATEOFCHANGE, TRANSACTIONREASONNO, TRANSACTIONMESSAGENO)
	Select E1.CASEID, E1.EventDescription,
	case
		when E1.Before=E2.EVENTDATE and E1.LOGACTION = 'I' then null
		else convert(nvarchar, E1.Before, 112)
	end,
	case
		when E1.Before=E2.EVENTDATE and E1.LOGACTION = 'D' then null
		else convert(nvarchar, E2.EVENTDATE, 112)
	end,
	E1.BATCHNO, E1.LOGDATETIMESTAMP, E1.TRANSACTIONREASONNO, E1.TRANSACTIONMESSAGENO
	from EVENTORDER1 E1
	left join CASEEVENT E2 on (E2.CASEID = E1.CASEID and E2.EVENTNO = E1.EVENTNO and E2.CYCLE = E1.CYCLE)
	where (E1.RowNumber = 1 and E1.Before<>E2.EVENTDATE and E1.LOGACTION = 'U')
	or (E1.RowNumber = 1 and E1.Before=E2.EVENTDATE and E1.LOGACTION = 'I')
	or (E1.RowNumber = 1 and E1.Before=E2.EVENTDATE and E1.LOGACTION = 'D')"

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@sEDEActionCode 	nvarchar(2),
		  @sPropertyType	nchar(1)',
		  @sEDEActionCode	=@sEDEActionCode,
		  @sPropertyType	=@sPropertyType
End

If @nErrorCode = 0
Begin
	-- Report on CASEEVENT_iLOG table for due dates.
	Set @sSQLString="
	with EVENTORDER1
	as ( 
	select L1.CASEID, L1.EVENTNO, L1.CYCLE,
	E.EVENTDESCRIPTION+' ('+'Due Date)' as EventDescription, 
	L1.EVENTDUEDATE as Before,
	null as After,
	TI.BATCHNO, L1.LOGDATETIMESTAMP, TI.TRANSACTIONREASONNO, TI.TRANSACTIONMESSAGENO, L1.LOGACTION,
	row_number() over ( partition by L1.CASEID, L1.EVENTNO, L1.CYCLE, TI.BATCHNO order by L1.LOGDATETIMESTAMP) as RowNumber"
	If @nDocRecipient is not null
	Begin
		Set @sSQLString=@sSQLString+"
		from #CASEEVENT_iLOG L1"
	End
	Else
	Begin
		Set @sSQLString=@sSQLString+"
		from CASEEVENT_iLOG L1"	
	End
	Set @sSQLString=@sSQLString+"
	join EVENTS E on (L1.EVENTNO = E.EVENTNO)
	join #CASESTOREPORT C on (C.CASEID = L1.CASEID)	
	join CASES CS on (CS.CASEID = C.CASEID)
	join #CASESEVENTDATESTOREPORT CE on (L1.CASEID = CE.CASEID and L1.EVENTNO = CE.EVENTNO and L1.CYCLE = CE.CYCLE)
	left join TRANSACTIONINFO TI on (TI.LOGTRANSACTIONNO = L1.LOGTRANSACTIONNO)
	where L1.LOGACTION in ('I','D','U')
	and L1.EVENTDUEDATE is not null
	and "+@sLocalSQLWhere+"
	)
	Insert into #AMENDEDCASES (CASEID, FIELD, OLDVALUE, NEWVALUE, EDEBATCHNO, DATEOFCHANGE, TRANSACTIONREASONNO, TRANSACTIONMESSAGENO)
	Select E1.CASEID, E1.EventDescription,
	case
		when E1.Before=E2.EVENTDUEDATE and E1.LOGACTION = 'I' then null
		else convert(nvarchar, E1.Before, 112)
	end,
	case
		when E1.Before=E2.EVENTDUEDATE and E1.LOGACTION = 'D' then null
		else convert(nvarchar, E2.EVENTDUEDATE, 112)
	end,
	E1.BATCHNO, E1.LOGDATETIMESTAMP, E1.TRANSACTIONREASONNO, E1.TRANSACTIONMESSAGENO
	from EVENTORDER1 E1
	left join CASEEVENT E2 on (E2.CASEID = E1.CASEID and E2.EVENTNO = E1.EVENTNO and E2.CYCLE = E1.CYCLE)
	where (E1.RowNumber = 1 and E1.Before<>E2.EVENTDUEDATE and E1.LOGACTION = 'U')
	or (E1.RowNumber = 1 and E1.Before=E2.EVENTDUEDATE and E1.LOGACTION = 'I')
	or (E1.RowNumber = 1 and E1.Before=E2.EVENTDUEDATE and E1.LOGACTION = 'D')"

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@sEDEActionCode 	nvarchar(2),
		  @sPropertyType	nchar(1)',
		  @sEDEActionCode	=@sEDEActionCode,
		  @sPropertyType	=@sPropertyType
End

If @nErrorCode = 0
Begin
	-- Find events to report for amended case tab and the correct cycle to report.
	Delete from #CASESEVENTDATESTOREPORT
	
	Set @sEventToReport = "(-11,-500)"
	
	Set @sSQLString="
	Insert into #CASESEVENTDATESTOREPORT(CASEID, EVENTNO, EVENTDATE, EVENTDUEDATE, CYCLE)
	Select CE.CASEID, CE.EVENTNO, CE.EVENTDATE, CE.EVENTDUEDATE, CE.CYCLE
	from CASEEVENT CE
	join #CASESTOREPORT CRD on (CRD.CASEID = CE.CASEID)
	Join (	select MIN(O.CYCLE) as [CYCLE], O.CASEID
		from OPENACTION O
		join SITECONTROL SC on (UPPER(SC.CONTROLID)='MAIN RENEWAL ACTION')
		where O.ACTION=SC.COLCHARACTER
		and O.POLICEEVENTS=1
		group by O.CASEID) OA on (OA.CASEID = CE.CASEID and OA.CYCLE = CE.CYCLE)
	join EVENTS E on (E.EVENTNO = CE.EVENTNO)  
	where CE.EVENTNO = -11
	and E.IMPORTANCELEVEL >= (select COLINTEGER 
				from SITECONTROL 
				where UPPER(CONTROLID) = UPPER('Client Importance') )
	union
	Select distinct CE.CASEID, CE.EVENTNO, CE.EVENTDATE, CE.EVENTDUEDATE, CE.CYCLE
	from CASEEVENT CE
	join #CASESTOREPORT CRD on (CRD.CASEID = CE.CASEID)
	join (	select CE01.CASEID, CE01.EVENTNO
		from CASEEVENT CE01
		join #CASESTOREPORT CRD2 on (CRD2.CASEID = CE01.CASEID)
		where CE01.CASEID = CRD2.CASEID
		group by CE01.CASEID, CE01.EVENTNO
		having count(*) > 1    
		) as CE2 on (CE2.CASEID = CE.CASEID and CE2.EVENTNO = CE.EVENTNO)
	join(	select CASEID, ACTION, CRITERIANO, min(CYCLE) as CYCLE
		from OPENACTION
		where POLICEEVENTS=1
		group by CASEID, ACTION, CRITERIANO) OA 
				on (OA.CASEID=CE.CASEID)
	join EVENTCONTROL EC on (EC.CRITERIANO=OA.CRITERIANO
			     and EC.EVENTNO=CE.EVENTNO)
	join ACTIONS A on (A.ACTION=OA.ACTION)
	where CE.EVENTNO != -11
	and CE.EVENTNO in "+@sEventToReport+
	"and CE.OCCURREDFLAG<9
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
		     END
	union
	Select CE.CASEID, CE.EVENTNO, CE.EVENTDATE, CE.EVENTDUEDATE, CE.CYCLE
	from CASEEVENT CE
	join #CASESTOREPORT CRD on (CRD.CASEID = CE.CASEID)
	join (	select CE01.CASEID, CE01.EVENTNO
		from CASEEVENT CE01
		join #CASESTOREPORT CRD2 on (CRD2.CASEID = CE01.CASEID)
		where CE01.CASEID = CRD2.CASEID
		group by CE01.CASEID, CE01.EVENTNO
		having count(*) = 1    
		) as CE2 on (CE2.CASEID = CE.CASEID and CE2.EVENTNO = CE.EVENTNO)
	where CE.EVENTNO in "+@sEventToReport
	
	Exec @nErrorCode=sp_executesql @sSQLString
End

If @nErrorCode = 0
Begin
	Set @sLocalSQLWhere = null

	If @nBatchNo is not null
	Begin
	    Set @sLocalSQLWhere=" and (EDC.BATCHNO = "+cast(@nBatchNo as nvarchar(50))+ " OR AC.EDEBATCHNO = "+cast(@nBatchNo as nvarchar(50))+")" + " and (TR.INTERNALFLAG <> 1 or TR.INTERNALFLAG is null)"
	End
	Else if @nDocRecipient is not null
	Begin
	    Set @sLocalSQLWhere=" and (AC.EDEBATCHNO is null or AC.EDEBATCHNO = -1) and (TR.INTERNALFLAG <> 1 or TR.INTERNALFLAG is null)"
	End

	If @bTransReason = 1
	Begin
	    Set @sLocalSQLWhere = @sLocalSQLWhere + " and TR.TRANSACTIONREASONNO is not null"
	End

	-- Put together the information for the Existing Case Updates worksheet and put it in 
	-- that big XML #XMLTEMPTABLE table.
	Set @sSQLString="
	Insert into #XMLTEMPTABLE (XMLSTR)
	Select (select distinct NDI.NAMECODE as 'DataInstructorNameCode', 
	isnull(dbo.fn_FormatNameUsingNameNo(NDI.NAMENO,null), NDI.NAME) as 'DataInstructorName', NADI.ALIAS as 'EDEAlias',
	CNDI.REFERENCENO as 'SenderReference', OD.OFFICIALNUMBER as 'SenderFileNumber', C.PROPERTYTYPE as 'PropertyType',
	C.COUNTRYCODE as 'Country', CC.CASECATEGORYDESC as 'Category', ST.SUBTYPEDESC as 'SubType', OA.OFFICIALNUMBER as 'ApplicationNumber',
	isnull(CED1.EVENTDUEDATE,CED1.EVENTDATE) as 'NextRenewalDate', isnull(CED2.EVENTDUEDATE,CED2.EVENTDATE) as 'NextAffidavitIntentUseDate',
	OE.OFFICIALNUMBER as 'RegistrationNumber', C.IRN as 'OurCaseReference', C.TITLE as 'Title', NI.INSTRUCTION as 'RenewalStandingInstruction',
	S.EXTERNALDESC as 'CaseStatus', TM.DESCRIPTION as 'TransactionMessage', AC.FIELD as 'FieldName', AC.OLDVALUE as 'OldValue',
	AC.NEWVALUE as 'NewValue', isnull(@nBatchIdentifier,E.SENDERREQUESTIDENTIFIER) as 'EDEBatchNumber', AC.DATEOFCHANGE as 'DateOfChange', TR.DESCRIPTION as 'ReasonForChange'
	from #AMENDEDCASES AC
	join CASES C on (C.CASEID = AC.CASEID)
	left join EDECASEDETAILS EDC on (EDC.CASEID = C.CASEID)
	left join CASENAME CNDI on (CNDI.CASEID = C.CASEID and CNDI.NAMETYPE = 'DI' and CNDI.SEQUENCE = 0)
	left join NAME NDI on (NDI.NAMENO = CNDI.NAMENO)
	left join NAMEALIAS NADI on (NADI.ALIASTYPE = '_E' and NADI.NAMENO = NDI.NAMENO)
	left join CASECATEGORY CC on (CC.CASETYPE = C.CASETYPE and CC.CASECATEGORY = C.CASECATEGORY)
	left join SUBTYPE ST on (ST.SUBTYPE = C.SUBTYPE)
	left join OFFICIALNUMBERS OD on (OD.CASEID = C.CASEID and OD.NUMBERTYPE = 'D' and OD.ISCURRENT = 1)
	left join OFFICIALNUMBERS OA on (OA.CASEID = C.CASEID and OA.NUMBERTYPE = 'A' and OA.ISCURRENT = 1)
	left join OFFICIALNUMBERS OE on (OE.CASEID = C.CASEID and OE.NUMBERTYPE = 'R' and OE.ISCURRENT = 1)
	left join EDESENDERDETAILS E on (AC.EDEBATCHNO = E.BATCHNO)
	left join STATUS S on (S.STATUSCODE = C.STATUSCODE)
	left join #CASESTANDINGINSTRUCTION NI on (NI.CASEID = C.CASEID)
	left join #CASESEVENTDATESTOREPORT CED1 on (CED1.CASEID = AC.CASEID and CED1.EVENTNO = -11)
	left join #CASESEVENTDATESTOREPORT CED2 on (CED2.CASEID = AC.CASEID and CED2.EVENTNO = -500)
	left join TRANSACTIONMESSAGE TM on (TM.TRANSACTIONMESSAGENO = AC.TRANSACTIONMESSAGENO)
	left join TRANSACTIONREASON TR on (TR.TRANSACTIONREASONNO = AC.TRANSACTIONREASONNO)
	where ((AC.FIELD <> 'Case Type' and AC.OLDVALUE <> '<Generate Reference>') or (AC.FIELD <> 'Case Type' and AC.OLDVALUE is null))
	and ((AC.FIELD <> 'Case Type' and left(AC.OLDVALUE,1) <> 'X') or (AC.FIELD <> 'Case Type' and AC.OLDVALUE is null))"
	+@sLocalSQLWhere+"
	order by C.IRN
	for XML PATH ('ExistingCaseUpdates'), TYPE)"

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nBatchIdentifier	nvarchar(254)',
		  @nBatchIdentifier	= @nBatchIdentifier
End

---------------------------------------------------------------------------------------------------------
-- Save the filename into ACTIVYTYREQUEST table to enable centura to save the file with the same name. --
---------------------------------------------------------------------------------------------------------
If @nErrorCode = 0 
Begin	
	If @nBatchIdentifier is not null
	Begin
		Set @sSQLString="
		select @sFileName=SENDER + SENDERREQUESTIDENTIFIER + '_Input_Amend.xml' 
		from EDESENDERDETAILS 
		where BATCHNO = @nBatchNo"
		
		Exec @nErrorCode=sp_executesql @sSQLString,
					N'@sFileName		nvarchar(254)	OUTPUT,
					  @nBatchNo		int',
					  @sFileName=@sFileName	OUTPUT,
					  @nBatchNo =@nBatchNo		
	End
	Else if @nRequestId is not null
	Begin
		Set @sFileName = 'InputAmend~'+isnull(replace(@sEDEIdentifier,' ','_'),replace(@sNameCode,' ','_'))+'~'+left(dbo.fn_DateToString(getdate(),'CLEAN-DATETIME'),18)+'.xml'
	End
	Else
	Begin
		Set @sFileName = 'InputAmend~'+replace(@sDataInstrName,' ','_')+'~'+left(dbo.fn_DateToString(getdate(),'CLEAN-DATETIME'),18)+'.xml'
	End
End

If @nErrorCode=0
Begin		
	-- Reset the locking level before updating database
	set transaction isolation level read committed
	
	BEGIN TRANSACTION
		
	Set @sSQLString="
		Update ACTIVITYREQUEST
		set FILENAME = @sFileName
		where ACTIVITYID = @nActivityId"

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'	@sFileName	nvarchar(254),
			@nActivityId	int',
			@sFileName	= @sFileName,
			@nActivityId	= @nActivityId
			
	If @nErrorCode = 0
		COMMIT TRANSACTION
	Else
		ROLLBACK TRANSACTION
End

-------------------------
-- Return the XML data --
-------------------------
If @nErrorCode = 0 and @bSuppressEmpty = 1
Begin
	-- If suppress flag ON, only report if there is something to report.
	Set @sSQLString="
	select @bRowsToReport=count(*)
	from #XMLTEMPTABLE
	where XMLSTR is not null"

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@bRowsToReport    int OUTPUT',
		  @bRowsToReport=@bRowsToReport OUTPUT
End

If @nErrorCode = 0 and @bRowsToReport = 0 and @nEmployeeNo is null and @nBatchNo is null
Begin
	Set @sSQLString="
		Update ACTIVITYREQUEST
		set SYSTEMMESSAGE = 'Report Suppressed'
		where ACTIVITYID = @nActivityId"

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'	@nActivityId	int',
			@nActivityId	= @nActivityId
End

If @nErrorCode = 0
Begin
	-- Get the information for the Data Instructor worksheet	
	Set @sSQLString="
	Insert into #XMLTEMPTABLE (XMLSTR)
	Select (Select N.NAMECODE as 'DataInstructorNameCode', isnull(dbo.fn_FormatNameUsingNameNo(N.NAMENO,null), N.NAME) as 'DataInstructorName',
	dbo.fn_FormatAddress(A.STREET1, A.STREET2, A.CITY, A.STATE, null, A.POSTCODE, A.COUNTRYCODE, 0, 1, null, 7202) as 'DataInstructorAddress', getdate( ) as 'Date',
	NT.DESCRIPTION + ' ' + 'Code' as 'DataInstructorLabel', NT.DESCRIPTION + ' ' + 'Name' as 'DataInstructorLabelName'
	from NAME N
	left join ADDRESS A on (A.ADDRESSCODE = N.POSTALADDRESS)
	left join EDEREQUESTTYPE E on (E.REQUESTTYPECODE = 'Data Input')
	left join NAMETYPE NT on (NT.NAMETYPE = E.REQUESTORNAMETYPE)
	where N.NAMENO = @nReportNameNo
	for XML PATH ('DataSource'), TYPE)"

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nReportNameNo		int',
		  @nReportNameNo		= @nReportNameNo
End

If @nErrorCode = 0
Begin
	Set @sSQLString="
	Select 
	@sInputAmendXML=case
		when (@sInputAmendXML is not null) then @sInputAmendXML+cast(XMLSTR as nvarchar(max))
		else cast(XMLSTR as nvarchar(max))
	end
	from #XMLTEMPTABLE"

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@sInputAmendXML	nvarchar(max)	OUTPUT',
		  @sInputAmendXML	= @sInputAmendXML	OUTPUT
End

If @nErrorCode = 0
Begin
	Set @sSQLString="
	Select @sInputAmendXML"

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@sInputAmendXML	nvarchar(max)',
		  @sInputAmendXML	= @sInputAmendXML
End

RETURN @nErrorCode

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.ede_InputAmendReport to public
go