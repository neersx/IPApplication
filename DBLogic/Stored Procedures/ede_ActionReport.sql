-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_ActionReport
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ede_ActionReport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ede_ActionReport.'
	Drop procedure [dbo].[ede_ActionReport]
End
Print '**** Creating Stored Procedure dbo.ede_ActionReport...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE	PROCEDURE dbo.ede_ActionReport 
		@psXMLActivityRequestRow	ntext
AS
-- PROCEDURE :	ede_ActionReport 
-- VERSION :	26
-- DESCRIPTION:	Builds the Action Report
-- CALLED BY :	SQLTemplates (sqlt_EDE_ActionReport.xml)
-- COPYRIGHT: 	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
--
-- MODIFICATIONS :
-- Date		Who	SQA	Version	Change
-- ------------	-------	-----	-------	----------------------------------------------- 
-- 23/03/2007	vql	13745	1	Procedure created
-- 28/05/2007	vql	13745	2	Fixed bugs.
-- 30/05/2007	vql	13745	3	Remove NOT PROCESSED issues.
-- 03/09/2007	vql	15146	4	Show Importance Level Description and dynamically populate Issues page.
-- 05/02/2008	vql	15852	5	Manually entered Issues on a Live Case are not appearing on the Action Report.
-- 08/04/2008	vql	16160	6	Duplicate entries sometimes appearing.
-- 29/05/2008	vql	16372	7	Incorrect main data instructor address.
-- 06/06/2008	vql	16487	8	Various issues with Action report.
-- 18/06/2008	vql	16526	9	Change filename for Action report output.
-- 19/06/2008	vql	16487	10	Various issues with Action report (revisit).
-- 25/09/2008	vql	16925	11	Change filename for Action Report.
-- 22/10/2008	vql	17048	12	No identifying information for rejected cases appearing on Action Report.
-- 29/05/2009	mf	17748	13	Reduce locking level to ensure other activities are not blocked.
-- 03/06/2009	vql	17692	14	Provide ‘Suppress empty document’ option for Report.
-- 20/07/2009	vql	17874	15	Action report is reporting on issues for batches that are unprocessed
-- 28/10/2009	vql	18143	16	Timeout error when generating a large Action Report.
-- 04/02/2010	DL	18430	17	Grant stored procedure to public
-- 19/02/2010	vql	18453	18	Action report is reporting on cases not belonging to the Data Instructor.
-- 04/06/2010	MF	18703	19	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE, ensure these are set to null.
-- 01/02/2011	vql	18763	20	Add NRD and Next Affidavit columns to Input/Amend and Action Report.
-- 02/02/2011	vql	16686	21	Add Data Instructor columns to Input Amend Report.
-- 12/07/2011	dl	RFC19795 22	Specify collate database_default for temp tables.
-- 03/04/2012	vql	20414	23	High Reject Issues not appearing in Action Report.
-- 22/10/2012	Dw	20973	24	Fix to 20414 to only include these issues when EDEOUTSTANDINGISSUES.CASEID is NULL
-- 12/11/2012	Dw	21033	25	Adjusted final delete to ensure that only issues already processed are deleted
-- 02 Nov 2015	vql	R53910	26	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare @nErrorCode		int
declare @nTranCountStart	int

declare	@sSQLString	nvarchar(4000)
declare	@sSQLWhere	nvarchar(4000)

declare	@sAlertXML	nvarchar(4000)
declare	@hDocument 	int	-- handle to the XML parameter.
declare	@nActivityId	int	-- the activityrequest key.
declare	@sSQLUser	nvarchar(40)
declare	@nBatchNo	int
declare @nRequestId	int	-- key from DOCUMENTREQUEST table.
declare @nDocRecipient	int	-- the Data Source.
declare @nDataSourceXML	nvarchar(4000) -- variable to store data source return details.
Declare @sPropertyType	nchar(2)-- the proeprty type to filter on.
Declare	@sFileName	nvarchar(254)
Declare @sDataInstrName	nvarchar(254)
Declare @sEDEIdentifier	nvarchar(10)
Declare @sNameCode	nvarchar(10)
Declare @bSuppressEmpty	bit
Declare @bIssuesToReport int
Declare @sEventToReport nvarchar(300)
Declare @sBelongingTo	nvarchar(2)
Declare @nRecipientNameFamilyNo	int
Declare @sRecipientGroupNames	nvarchar(4000)

-- SQA17748 Reduce the locking level to avoid blocking other processes
set transaction isolation level read uncommitted

----------------
-- Initialise --
----------------
-- Check database version. Only allow Action Report to run if the database version is SQL Server 2005.
If  (Select left( cast(SERVERPROPERTY('ProductVersion') as varchar), CHARINDEX('.', CAST(SERVERPROPERTY('ProductVersion') as varchar))-1) ) <= 8
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML("edn", "This document can only be generated for databases on SQL Server 2005 or later.", null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@error
End

Set @bIssuesToReport = 1

----------------------------
-- Get intial information --
----------------------------
-- First collect the key for the Activity Request row that has been passed as an XML parameter using OPENXML functionality.
Set @nErrorCode = 0
Begin	
	Exec 	sp_xml_preparedocument  @hDocument OUTPUT, @psXMLActivityRequestRow
	Set 	@nErrorCode = @@error
End

-- Now select the key information from the xml.
If @nErrorCode = 0
Begin
	Set @sSQLString="
	Select 	@nActivityId = ACTIVITYID,
		@sSQLUser = SQLUSER,
		@nBatchNo = BATCHNO
	from openxml( @hDocument,'ACTIVITYREQUEST',2 )
	with (ACTIVITYID int, SQLUSER nvarchar(40), BATCHNO int)"

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nActivityId	int    		OUTPUT,
		  @sSQLUser	nvarchar(40)	OUTPUT,
		  @nBatchNo	int    		OUTPUT,
		  @hDocument	int',
		  @nActivityId	= @nActivityId	OUTPUT,
		  @sSQLUser	= @sSQLUser	OUTPUT,
		  @nBatchNo	= @nBatchNo	OUTPUT,
		  @hDocument 	= @hDocument
End

-- Remove the internal representation of the XML.
If @nErrorCode = 0	
Begin	
	Exec sp_xml_removedocument @hDocument 
	Set @nErrorCode	  = @@error
End

-- Get the REQUESTID and Document Request recipient (Data Source).
If @nErrorCode = 0
Begin
	Set @sSQLString="
	Select 	@nRequestId = A.REQUESTID, @nDocRecipient = D.RECIPIENT, @sPropertyType=L.PROPERTYTYPE, @bSuppressEmpty=D.SUPPRESSWHENEMPTY,
			@sBelongingTo = D.BELONGINGTOCODE
	from ACTIVITYREQUEST A
	left join DOCUMENTREQUEST D on (D.REQUESTID = A.REQUESTID)
	left join LETTER L on (L.LETTERNO = A.LETTERNO)
	where A.ACTIVITYID = @nActivityId"

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nRequestId		int    		OUTPUT,
		  @nDocRecipient	int	    	OUTPUT,
		  @sPropertyType	nchar(2)	OUTPUT,
		  @bSuppressEmpty	bit	    	OUTPUT,
		  @sBelongingTo		nvarchar(2)	OUTPUT,
		  @nActivityId	int',
		  @nRequestId		=@nRequestId	OUTPUT,
		  @nDocRecipient	=@nDocRecipient OUTPUT,
		  @sPropertyType	=@sPropertyType OUTPUT,
		  @bSuppressEmpty	=@bSuppressEmpty OUTPUT,
		  @sBelongingTo		=@sBelongingTo	OUTPUT,
		  @nActivityId		=@nActivityId
End

-- Get the name for file name.
If @nErrorCode = 0
Begin

	Set @sSQLString="
	Select @sDataInstrName=isnull(dbo.fn_FormatNameUsingNameNo(N.NAMENO, null), N.NAME),
	@sEDEIdentifier=NA.ALIAS, @sNameCode=N.NAMECODE
	from NAME N
	left join NAMEALIAS NA	on (NA.NAMENO = N.NAMENO 
				and NA.ALIASTYPE = '_E'
				and NA.COUNTRYCODE  is null
				and NA.PROPERTYTYPE is null)
	where N.NAMENO = @nDocRecipient"

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@sDataInstrName   nvarchar(254) OUTPUT,
		  @sEDEIdentifier   nvarchar(10) OUTPUT,
		  @sNameCode	    nvarchar(10) OUTPUT,
		  @nDocRecipient    int',
		  @sDataInstrName   =@sDataInstrName OUTPUT,
		  @sEDEIdentifier   =@sEDEIdentifier OUTPUT,
		  @sNameCode	    =@sNameCode OUTPUT,
		  @nDocRecipient    =@nDocRecipient
End

If @nErrorCode = 0
Begin
	-- Get the information for the Data Instructor worksheet.
	Set @sSQLString="
	Select N.NAMECODE as 'DataInstructorNameCode', isnull(dbo.fn_FormatNameUsingNameNo(N.NAMENO, null), N.NAME) as 'DataInstructorName',
	dbo.fn_FormatAddress(A.STREET1, A.STREET2, A.CITY, A.STATE, null, A.POSTCODE, A.COUNTRYCODE, 0, 1, null, 7202) as 'DataInstructorAddress', getdate( ) as 'Date'
	from NAME N
	left join ADDRESS A on (A.ADDRESSCODE = N.POSTALADDRESS)
	where N.NAMENO = @nDocRecipient
	for XML PATH ('DataSource'), TYPE"

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nDocRecipient		int',
		  @nDocRecipient		= @nDocRecipient
End

If @nErrorCode = 0
Begin
	-- Construct WHERE clause.
	select @nRecipientNameFamilyNo = FAMILYNO from NAME where NAMENO = @nDocRecipient
		
	If (@sBelongingTo = 'RG') and (@nRecipientNameFamilyNo is not null)
	Begin
		Select @sRecipientGroupNames = nullif(@sRecipientGroupNames+',', ',')+cast(NAMENO as nvarchar(15)) 
		from NAME where FAMILYNO = @nRecipientNameFamilyNo
		
		Set @sSQLWhere="
		where (CN.NAMENO = @nDocRecipient and ETH.BATCHSTATUS = 1282) or (CN.NAMENO in ("+@sRecipientGroupNames+") and EOI.BATCHNO is null)
		or (ESD.SENDERNAMENO = @nDocRecipient and ETH.BATCHSTATUS = 1282 and EOI.CASEID is null)"
	End
	Else	
	Begin
		Set @sSQLWhere="
		where (CN.NAMENO = @nDocRecipient and ETH.BATCHSTATUS = 1282) or (CN.NAMENO = @nDocRecipient and EOI.BATCHNO is null)
		or (ESD.SENDERNAMENO = @nDocRecipient and ETH.BATCHSTATUS = 1282 and EOI.CASEID is null)"
	End
	
	If @sPropertyType is not null
	Begin
		Set @sSQLWhere=@sSQLWhere+" and isnull(C.PROPERTYTYPE,@sPropertyType) = @sPropertyType" 
	End
End

-------------------------------------------
-- See if we need to suppress the report --
-------------------------------------------
If @nErrorCode = 0 and @bSuppressEmpty = 1
Begin
	Set @sSQLString="
	Select @bIssuesToReport=count(*)
	from EDEOUTSTANDINGISSUES EOI
	left join EDESENDERDETAILS ESD on (ESD.BATCHNO = EOI.BATCHNO)
	left join EDETRANSACTIONHEADER ETH on (ETH.BATCHNO = ESD.BATCHNO)
	left join CASES C on (C.CASEID = EOI.CASEID)
	left join CASENAME CN on (CN.CASEID = C.CASEID and CN.NAMETYPE = 'DI')
	"+@sSQLWhere

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@bIssuesToReport	int OUTPUT,
		  @nDocrecipient	int,
		  @sPropertyType	nchar(2)',
		  @bIssuesToReport	=@bIssuesToReport OUTPUT,
		  @nDocrecipient	=@nDocRecipient,
		  @sPropertyType	=@sPropertyType
End

If @nErrorCode = 0 and @bIssuesToReport = 0
Begin
	Set @sSQLString="
		Update ACTIVITYREQUEST
		set SYSTEMMESSAGE = 'Report Suppressed'
		where ACTIVITYID = @nActivityId"

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'	@nActivityId	int',
			@nActivityId	= @nActivityId
End

-----------------------------------------
-- Get the stuff for the Action Report --
-----------------------------------------
If @nErrorCode = 0 and @bIssuesToReport > 0
Begin
	-- Create a tempory table to store issue priority.
	Create table #ISSUESMESSAGEPRIORITY
	(
		OUTSTANDINGISSUEID	int,
		MESSAGEPRIORITY		int
	)

	Create index X1TEMPISSUES ON #ISSUESMESSAGEPRIORITY
	(
		OUTSTANDINGISSUEID
	)

	Set @nErrorCode = @@Error
End

If @nErrorCode = 0 and @bIssuesToReport > 0
Begin
	-- Create a tempory table to store issue priority.
	Create table #OUTSTANDINGUISSUES
	(
		CASEID				int,
		SHORTDESCRIPTION		nvarchar(254) collate database_default,
		URGENCYCODE			nvarchar(10) collate database_default,
		URGENCYLEVEL			nvarchar(80) collate database_default,
		EXISTINGVALUE			nvarchar(254) collate database_default,
		REPORTEDVALUE			nvarchar(254) collate database_default,
		ISSUETEXT			nvarchar(254) collate database_default,
		TRANSDESCRIPTION		nvarchar(254) collate database_default,
		REFERENCENO			nvarchar(254) collate database_default,
		SENDERFILENUMBER		nvarchar(32) collate database_default,
		PROPERTYNAME			nvarchar(50) collate database_default,
		COUNTRY				nvarchar(60) collate database_default,
		CASECATEGORY			nvarchar(50) collate database_default,
		SUBTYPE				nvarchar(50) collate database_default,
		APPLICATIONNUMBER		nvarchar(32) collate database_default,
		REGISTRATIONNUMBER		nvarchar(32) collate database_default,
		IRN				nvarchar(30) collate database_default,
		TITLE				nvarchar(254) collate database_default,
		BATCHNUMBER			nvarchar(254) collate database_default,
		DATECREATED			datetime
	)

	Set @nErrorCode = @@Error
End

If @nErrorCode = 0 and @bIssuesToReport > 0
Begin
	Set @sSQLString="
	Insert #ISSUESMESSAGEPRIORITY (OUTSTANDINGISSUEID, MESSAGEPRIORITY)
	Select EOI.OUTSTANDINGISSUEID as OUTSTANDINGISSUEID, min(TM.MESSAGEPRIORITY) as MESSAGEPRIORITY
	from EDEOUTSTANDINGISSUES EOI
	left join TRANSACTIONINFO TI on ((TI.TRANSACTIONIDENTIFIER = EOI.TRANSACTIONIDENTIFIER and TI.BATCHNO = EOI.BATCHNO) or (TI.SESSIONNO = EOI.SESSIONNO and TI.CASEID = EOI.CASEID))
	left join TRANSACTIONREASON TR on (TR.TRANSACTIONREASONNO = TI.TRANSACTIONREASONNO)
	left join TRANSACTIONMESSAGE TM on (TM.TRANSACTIONMESSAGENO = TI.TRANSACTIONMESSAGENO)
	left join EDESENDERDETAILS ESD on (ESD.BATCHNO = EOI.BATCHNO)
	left join EDETRANSACTIONHEADER ETH on (ETH.BATCHNO = ESD.BATCHNO)
	left join CASES C on (C.CASEID = EOI.CASEID)
	left join CASENAME CN on (CN.CASEID = C.CASEID and CN.NAMETYPE = 'DI')"
	+@sSQLWhere+"
	group by EOI.OUTSTANDINGISSUEID"

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nDocrecipient	int,
		  @sPropertyType	nchar(2)',
		  @nDocrecipient	=@nDocRecipient,
		  @sPropertyType	=@sPropertyType
End

If @nErrorCode = 0 and @bIssuesToReport > 0
Begin
	Set @sSQLString="
	Insert into #OUTSTANDINGUISSUES (CASEID, SHORTDESCRIPTION, URGENCYCODE, URGENCYLEVEL, EXISTINGVALUE, REPORTEDVALUE, ISSUETEXT, TRANSDESCRIPTION, 
	REFERENCENO, SENDERFILENUMBER, PROPERTYNAME, COUNTRY, CASECATEGORY, SUBTYPE, APPLICATIONNUMBER, REGISTRATIONNUMBER, IRN, TITLE, 
	BATCHNUMBER, DATECREATED)
	Select C.CASEID, ESI.SHORTDESCRIPTION, T.USERCODE, T.DESCRIPTION, EOI.EXISTINGVALUE, EOI.REPORTEDVALUE, EOI.ISSUETEXT, TM.DESCRIPTION,
	isnull(CN.REFERENCENO,ECD.SENDERCASEREFERENCE), OFN.OFFICIALNUMBER, P.PROPERTYNAME, CO.COUNTRY, CC.CASECATEGORYDESC, S.SUBTYPEDESC,
	OFNA.OFFICIALNUMBER, OFNR.OFFICIALNUMBER, C.IRN, C.TITLE, ESD.SENDERREQUESTIDENTIFIER, EOI.DATECREATED
	from EDEOUTSTANDINGISSUES EOI 
	join EDESTANDARDISSUE ESI on (ESI.ISSUEID = EOI.ISSUEID)
	left join EDESENDERDETAILS ESD on (ESD.BATCHNO = EOI.BATCHNO)
	left join EDETRANSACTIONHEADER ETH on (ETH.BATCHNO = ESD.BATCHNO)
	left join CASES C on (C.CASEID = EOI.CASEID)
	left join EDECASEDETAILS ECD on (ECD.BATCHNO = EOI.BATCHNO and ECD.TRANSACTIONIDENTIFIER = EOI.TRANSACTIONIDENTIFIER)
	left join TRANSACTIONINFO TI on ((TI.TRANSACTIONIDENTIFIER = EOI.TRANSACTIONIDENTIFIER and TI.BATCHNO = EOI.BATCHNO) or (TI.SESSIONNO = EOI.SESSIONNO and TI.CASEID = EOI.CASEID))
	left join TRANSACTIONREASON TR on (TR.TRANSACTIONREASONNO = TI.TRANSACTIONREASONNO)
	left join TRANSACTIONMESSAGE TM on (TM.TRANSACTIONMESSAGENO = TI.TRANSACTIONMESSAGENO)
	left join CASENAME CN on (CN.CASEID = C.CASEID and CN.NAMETYPE = 'DI')
	left join OFFICIALNUMBERS OFN on (OFN.CASEID = C.CASEID and OFN.NUMBERTYPE = 'D' and OFN.ISCURRENT = 1)
	left join PROPERTYTYPE P on (P.PROPERTYTYPE = C.PROPERTYTYPE)
	left join COUNTRY CO on (CO.COUNTRYCODE = C.COUNTRYCODE)
	left join CASECATEGORY CC on (CC.CASETYPE = C.CASETYPE and CC.CASECATEGORY = C.CASECATEGORY)
	left join SUBTYPE S on (S.SUBTYPE = C.SUBTYPE)
	left join OFFICIALNUMBERS OFNA on (OFNA.CASEID = C.CASEID and OFNA.NUMBERTYPE = 'A' and OFNA.ISCURRENT = 1)
	left join OFFICIALNUMBERS OFNR on (OFNR.CASEID = C.CASEID and OFNR.NUMBERTYPE = 'R' and OFNR.ISCURRENT = 1)
	left join TABLECODES T on (T.TABLECODE = ESI.IMPORTANCELEVEL)
	join #ISSUESMESSAGEPRIORITY X on ((X.OUTSTANDINGISSUEID = EOI.OUTSTANDINGISSUEID and X.MESSAGEPRIORITY = TM.MESSAGEPRIORITY) or TM.DESCRIPTION is null)"
	+@sSQLWhere+"
	group by C.CASEID, ESI.SHORTDESCRIPTION, T.USERCODE, T.DESCRIPTION, EOI.EXISTINGVALUE, EOI.REPORTEDVALUE ,EOI.ISSUETEXT,
	TM.DESCRIPTION, isnull(CN.REFERENCENO,ECD.SENDERCASEREFERENCE), OFN.OFFICIALNUMBER, P.PROPERTYNAME, CO.COUNTRY, CC.CASECATEGORYDESC, 
	S.SUBTYPEDESC, OFNA.OFFICIALNUMBER, OFNR.OFFICIALNUMBER, C.IRN, C.TITLE, ESD.SENDERREQUESTIDENTIFIER, EOI.DATECREATED
	order by T.USERCODE desc"

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nDocrecipient	int,
		  @sPropertyType	nchar(2)',
		  @nDocrecipient	=@nDocRecipient,
		  @sPropertyType	=@sPropertyType
End

If @nErrorCode = 0 and @bIssuesToReport > 0
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
		
	Set @sEventToReport = "(-11,-500)"

	-- Find events to report for amended case tab and the correct cycle to report.
	Set @sSQLString="
	Insert into #CASESEVENTDATESTOREPORT(CASEID, EVENTNO, EVENTDATE, EVENTDUEDATE, CYCLE)
	Select CE.CASEID, CE.EVENTNO, CE.EVENTDATE, CE.EVENTDUEDATE, CE.CYCLE
	from CASEEVENT CE
	join #OUTSTANDINGUISSUES CRD on (CRD.CASEID = CE.CASEID)
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
	join #OUTSTANDINGUISSUES CRD on (CRD.CASEID = CE.CASEID)
	join (	select CE01.CASEID, CE01.EVENTNO
		from CASEEVENT CE01
		join #OUTSTANDINGUISSUES CRD2 on (CRD2.CASEID = CE01.CASEID)
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
	join #OUTSTANDINGUISSUES CRD on (CRD.CASEID = CE.CASEID)
	join (	select CE01.CASEID, CE01.EVENTNO
		from CASEEVENT CE01
		join #OUTSTANDINGUISSUES CRD2 on (CRD2.CASEID = CE01.CASEID)
		where CE01.CASEID = CRD2.CASEID
		group by CE01.CASEID, CE01.EVENTNO
		having count(*) = 1    
		) as CE2 on (CE2.CASEID = CE.CASEID and CE2.EVENTNO = CE.EVENTNO)
	where CE.EVENTNO in "+@sEventToReport
	
	Exec @nErrorCode=sp_executesql @sSQLString
End

If @nErrorCode = 0 and @bIssuesToReport > 0
Begin

	Set @sSQLString="
	Select O.SHORTDESCRIPTION as 'CPAIssue', O.URGENCYCODE as 'UrgencyLevel', O.URGENCYLEVEL as 'UrgencyLevelDescription', O.EXISTINGVALUE as 'CurrentValue',
	O.REPORTEDVALUE as 'ReportValue', O.ISSUETEXT as 'AdditionalIssueText', O.TRANSDESCRIPTION as 'TransactionMessage',
	O.REFERENCENO as 'SenderReference', O.SENDERFILENUMBER as 'SenderFileNumber', O.PROPERTYNAME as 'PropertyType', 
	O.COUNTRY as 'Country', O.CASECATEGORY as 'CaseCategory', O.SUBTYPE as 'SubType', O.APPLICATIONNUMBER as 'ApplicationNumber',
	O.REGISTRATIONNUMBER as 'RegistrationNumber', O.IRN as 'CaseReference', O.TITLE as 'Title', O.BATCHNUMBER as 'BatchNumber', O.DATECREATED as 'DateOfIssued',
	isnull(CED1.EVENTDUEDATE,CED1.EVENTDATE) as 'NextRenewalDate', isnull(CED2.EVENTDUEDATE,CED2.EVENTDATE) as 'NextAffidavitIntentUseDate',
	NDI.NAMECODE as 'DataInstructorNameCode', isnull(dbo.fn_FormatNameUsingNameNo(NDI.NAMENO, null), NDI.NAME) as 'DataInstructorName', 
	NADI.ALIAS as 'EDEAlias'
	from #OUTSTANDINGUISSUES O
	left join #CASESEVENTDATESTOREPORT CED1 on (CED1.CASEID = O.CASEID and CED1.EVENTNO = -11)
	left join #CASESEVENTDATESTOREPORT CED2 on (CED2.CASEID = O.CASEID and CED2.EVENTNO = -500)
	left join CASENAME CNDI on (CNDI.CASEID = O.CASEID and CNDI.NAMETYPE = 'DI' and CNDI.SEQUENCE = 0)
	left join NAME NDI on (NDI.NAMENO = CNDI.NAMENO)
	left join NAMEALIAS NADI on (NADI.ALIASTYPE = '_E' and NADI.NAMENO = NDI.NAMENO)
	order by URGENCYCODE desc
	for XML PATH ('OutstandingIssues'), TYPE"

	Exec @nErrorCode=sp_executesql @sSQLString
End


--------------------------
-- Get the Issues page	--
--------------------------
If @nErrorCode = 0	
Begin
	Set @sSQLString="
	Select S.SHORTDESCRIPTION as 'CPAIssue', S.LONGDESCRIPTION as 'CPAIssueDescription', 
	T.USERCODE as 'UrgencyLevel', T.DESCRIPTION as 'UrgencyLevelDescription'
	from EDESTANDARDISSUE S
	left join TABLECODES T on (T.TABLECODE = S.IMPORTANCELEVEL)
	order by CPAIssue
	for XML PATH ('CPAIssues'), TYPE"

	Exec @nErrorCode=sp_executesql @sSQLString
End



----------------------------------------------
-- Delete all issues that are not processed --
----------------------------------------------
-- All outstanding issues that are not processed will be reported once, then removed.
If @nErrorCode = 0
Begin
	-- Reset the locking level before updating database
	set transaction isolation level read committed

	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	Set @sSQLString="
	Delete EDEOUTSTANDINGISSUES
	from EDEOUTSTANDINGISSUES EOI
	join EDESENDERDETAILS ESD on (ESD.BATCHNO = EOI.BATCHNO)
	join EDETRANSACTIONHEADER ETH on (ETH.BATCHNO = ESD.BATCHNO)
	join EDESTANDARDISSUE ESI on (ESI.ISSUEID = EOI.ISSUEID)
	where ESD.SENDERNAMENO = @nDocRecipient
	and ETH.BATCHSTATUS = 1282
	and ESI.SEVERITYLEVEL = 4010
	and EOI.CASEID is null"

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nDocrecipient	int',
		  @nDocrecipient	=@nDocRecipient

	---------------------------------------------------------------------------------------------------------
	-- Save the filename into ACTIVYTYREQUEST table to enable centura to save the file with the same name. --
	---------------------------------------------------------------------------------------------------------
	If @nErrorCode = 0 
	Begin
		Set @sFileName = 'ActionReport~'+isnull(replace(@sEDEIdentifier,' ','_'),replace(@sNameCode,' ','_'))+'~'+left(dbo.fn_DateToString(getdate(),'CLEAN-DATETIME'),18)+'.xml'

		Set @sSQLString="
			Update ACTIVITYREQUEST
			set FILENAME = @sFileName
			where ACTIVITYID = @nActivityId"

		Exec @nErrorCode=sp_executesql @sSQLString,
			N'	@sFileName	nvarchar(254),
				@nActivityId	int',
				@sFileName	= @sFileName,
				@nActivityId	= @nActivityId
	End
	
	If @@TranCount > @nTranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

RETURN @nErrorCode

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

GRANT execute on dbo.ede_ActionReport to public
GO