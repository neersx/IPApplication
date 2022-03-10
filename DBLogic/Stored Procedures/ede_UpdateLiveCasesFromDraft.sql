-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_UpdateLiveCasesFromDraft
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[ede_UpdateLiveCasesFromDraft]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure ede_UpdateLiveCasesFromDraft.'
	Drop procedure [dbo].[ede_UpdateLiveCasesFromDraft]
End
Print '**** Creating Stored Procedure ede_UpdateLiveCasesFromDraft...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO

CREATE PROCEDURE [dbo].[ede_UpdateLiveCasesFromDraft]
			@pnRowCount		int=0	OUTPUT,
			@pnUserIdentityId	int,			-- Mandatory
			@psCulture		nvarchar(10)	= null,
			@pnBatchNo		int,			-- Mandatory
			@psTransId		nvarchar(50)	= null,
			@pbPoliceImmediately	bit		= 0,	-- Option to run Police Immediately
			@pbReducedLocking	bit		= 0,	-- Flag to indicate process row limit to reduce locks
			@pnMaxTrans		int		= null	-- Number of transactions to process when @pbReducedLocking=1
			
AS
-- PROCEDURE :	ede_UpdateLiveCasesFromDraft
-- VERSION :	51
-- SCOPE:	CPA Inprotech
-- DESCRIPTION:	Accepts either an entire batch or a transaction within a batch to locate the 
--		configured update rules. The rules are then applied to determine if it is 
--		valid to update the live Case from the details held in the draft.
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 16 Jan 2007	MF	12299	1	Procedure created
-- 28 May 2007	MF	14825	2	Set Narrative when transaction pushed to Operator Review.
-- 04 Jun 2007	MF	12299	3	Separate the transactions that create new Cases and amend Cases.
--					This requires two separate TRANSACTIONINFO rows to be inserted.
-- 14 Jun 2007	MF	12413	4	Design correction.  Draft case is allowed to exist in multiple batches.
--					When draft case is applied to live case then update all batches it is referred
--					to in.
-- 20 Jul 2007	MF	15039	5	Remove POLICING tables that have not been processed for a draft case before
--					deleting the draft case.
-- 16 Oct 2007	vql	15318	6	Also insert BATCHNO when rows inserted into TRANSACTIONINFO table.
-- 06 Feb 2008	MF	15904	7	Allow for a limit on the number of transactions to process at the one
--					time.  The smaller the number the less time that locks will be held on
--					the database.
-- 06 Feb 2008	DL	15771	8	Insert a row into TRANSACTIONINFO table for each new live case.
-- 15 Feb 2008	MF	15968	9	When a draft case is changed to a live case the EDECASEMATCH row is
--					to be removed.
-- 03 Mar 2008	MF	16067	9	TRANSNARRATIVECODE is incorrectly being set to zero on the
--					EDETRANSACTIONBODY table
-- 06 Mar 2008	MF	16079	10	If Policing is to run immediately then use the asynchronous version of
--					Policing.
-- 12 Mar 2008	MF	16048	11	Insert TRANSACTIONINFO row for each transaction marked as processed or where
--					the live case has been updated.
-- 27 Mar 2008	MF	16149	12	Draft case is to go to Operator Review if the EDE Rule is marked for the who
--					case to be rejected without a specific issue.
-- 27 Mar 2008	MF	16092	12	Insert TRANSACTIONINFO row where the Stop Pay Date or Start Pay Date is being
--					inserted or updated.
-- 10 Apr 2008	MF	16107	13	New Official Numbers for a given Number Type should result in the any pre-existing
--					Official Numbers of the same Number Type having their Is Current flag turned off.
-- 14 Apr 2008	MF	16240	14	Some transactions to be considered for update may already have an Issue against them
--					which will result in them going to Operator or Supervisor review.  This should not
--					stop the Case from being updated unless the issue is of a high severity level.
-- 21 Apr 2008	MF	16281	15	When updating the TRANSACTIONINFO table, the TRANSACTIONREASONNO field needs to 
--					be set to EDEREQUESTTYPE.TRANSACTIONREASONNO for the Request Type of the batch 
--					being processed.
-- 07 May 2008	MF	16371	16	Set the ISCURRENT flag for an Official Number if the ISCURRENT flag on the draft
--					case for the matching official number does not match the ISCURRENT flag of the
--					live case.
-- 22 May 2008	MF	16430	17	Pass the EDE BatchNo to ede_CaseNameGlobalUpdates so that it can be loaded
--					into CASENAMEREQUEST row inserted for global name change.
-- 29 May 2008	MF	16461	18	Cases marked as Operator Review are to also have the Mandatory Rules applied
--					so when the operator opens the draft Case any missing data is highlighted.
-- 02 Jun 2008	MF	16489	19	When inserting an Event associated with a RelatedCase, ensure that the EventNo
--					determined from the Relationship is not flagged as being for Display Only purposes.
-- 26 Jun 2008	MF	16610	20	Prefix the POLICING.POLICINGNAME colum with EDE1- or EDE2- to indicate that this 
--					procedure inserted the row. This is for debugging reasons.
-- 18 Sep 2008	MF	16926	21	When comparing live and draft events, use the lowest open action for the respective 
--					cases.  The cycles may not be the same but this is acceptable.
-- 07 Oct 2008	MF	16936	21	Transaction Narrative was not set when action taken and moves to Operator Review
-- 10 Oct 2008	MF	17000	22	Official number being updated automatically when rule is to only do this if that 
--					number type already exists. Also extended correction to CaseEvents to ensure they are
--					inserted for rule type 3 or 8.
-- 29 Oct 2008	MF	17000	23	Revisit. Need to ensure that the specific Official Number being inserted does not exist
--					as well as any other Official Numbers for the same number type.
-- 28 Nov 2008	MF	17154	24	If no Amend rule is found then revert to the Whole Case rule as the default.
-- 04 Dec 2008	MF	17154	24	Revisit after test problem.
-- 11 Dec 2008	MF	17136	25	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 24 Feb 2009	MF	17429	26	Related case difference is being ignored if it cannot be auto updated
-- 01 Jul 2009	MF	17844	27	Use BEGIN TRY and BEGIN CATCH to catch deadlock errors (1205).
-- 24 Jul 2009	MF	16548	28	The FROMEVENTNO will now identify the Event from a related Case that will be pushed
--					into the child Case.
-- 03 Aug 2009	MF	17449	29	Recalculate all Action when a draft Case is changed to a live Case. Previously this did not occur if the
--					Criteria used against the Draft Case was not different to what would be used for the live Case. This caused
--					a problem for Events linked to a draft EventNo that had not previously been policed.
-- 11 Aug 2009	MF	17940	27	Auto Amend rules should be based on critieria fields from the live case
-- 07 Dec 2009	MF	18200	28	Automatic update of non IP official numbers to replace the existing number
-- 22 Mar 2010	MF	18565	29	Dynamic SQL exceeded the 4000 character limit.
-- 02 Dec 2010	MF	18403	30	Update related caseid if the Related Case details loaded can now be resolved to an actual case on the database.
-- 21 Dec 2010	MF	18403	31	Failed testing. RelatedCase row was not being inserted into live case.
-- 24 Jan 2011	MF	19341	32	Duplicate key error on insert of CASEEVENT. Add DISTINCT clause and cast LONGTEXT as nvarchar(MAX).
-- 14 Feb 2012	MF	20266	33	Provide a more flexible method to determine what NARRATIVECODE should be used in relation to a particular STOPPAYREASON.
-- 01 May 2012	MF	20448	34	Change the cycle for stop pay reason events to be based on the controlling action
-- 05 Jul 2013	vql	R13629	35	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 27 Aug 2014	MF	R38519	36	Cater for Type Of Mark as an input field associated with the Case.
-- 29 Aug 2014	MF	R37929	37	Check for new rule that allows the blocking of whole case updates for full and partial matched cases.
-- 04 Sep 2014	MF	R37929	38	Failed test.
-- 10 Sep 2014	MF	R37929	39	Need to ensure all updates are blocked. This is different from a Review requirement where the update may still occur.
-- 16 Mar 2015	MF	R45318	40	Reciprocal relationship not being inserted where imported case relates to existing Inprotech case.
-- 27 Apr 2015	MF	46613	41	Designated countries are not being considered when looking for Case differences that are to be reported to operator. 
-- 16 Mar 2016	MF	59434	42	Improve BEGIN CATCH block so that non deadlock errors still throw the error message and code.	
-- 22 Mar 2016	MF	59415	43	When being run with @pbReducedLocking=1 with a reduced batch size, it is possible that the system will not progress
--					if the number of Operator Review (3460) transactions in TRANSACTIONIDENTIFIER order total at least the specified 
--					number of @pnMaxTrans. 
-- 01 Jul 2016	DL	63684	44	Case Import batch is failing with referential integrity error - Remove RELATEDCASE that link to the draft case.
-- 05 Jul 2016	MF	63684	45	Failed testing.
-- 02 Aug 2016	MF	64248	46	CaseEvent for EventNo -14 will now be updated by database trigger so no need to perform this directly.
-- 12 Oct 2016	MF	DR25114	47	Correction to merge errors. (Use DR number because of problem with RFC allocation).
-- 11 Dec 2017	MF	73111	48	CaseName being allocated to be removed was using failing to indicate the correct NAMETYPE which caused procedure to fail.
-- 21 Dec 2017	MF	73189	49	A converstion error was occurring when DEFAULTNARRATIVE was a negative number.
-- 03 Apr 2019	MF	DR-48058 50	When an existing RelateCase row is updated from indicating an Official Number and Country to now pointing to a newly created
--					Case, then we also need to consider if there are any reciprocal relationships that can point from the new case back to the
--					CASEID from the RelatedCase.
-- 11 Jul 2019	MF	DR-50261 129	Official numbers that are linked to an Event should use the EventDate in the DateEntered of the Official Number.

SET NOCOUNT ON

Create table dbo.#TEMPCASEMATCH(TRANSACTIONIDENTIFIER	nvarchar(50)	collate database_default NOT NULL,
				MATCHLEVEL		int		NULL,
				DRAFTCASEID		int		NULL,
				LIVECASEID		int		NULL,
				DATASOURCETYPE		int		NULL,
				MANDATORYRULE		int		NULL,
				NEWCASERULE		int		NULL,
				AMENDCASERULE		int		NULL,
				TRANSSTATUSCODE		int		NULL
				)

Create table dbo.#TEMPISSUE(	TRANSACTIONIDENTIFIER	nvarchar(50)	collate database_default NOT NULL,
				DRAFTCASEID		int		NOT NULL,
				LIVECASEID		int		NULL,
				ISSUEID			int		NULL,
				SEVERITYLEVEL		int		NULL,
				REPORTEDVALUE		nvarchar(254)	collate database_default NULL,
				EXISTINGVALUE		nvarchar(254)	collate database_default NULL
				)

Create table dbo.#TEMPREVIEW(	TRANSACTIONIDENTIFIER	nvarchar(50)	collate database_default NOT NULL,
				DRAFTCASEID		int		NOT NULL,
				REVIEWTYPE		char(1)		collate database_default NOT NULL
				)

-- A temporary table to load CASENAMEs 
-- that might trigger global name changes
Create table dbo.#TEMPCASENAME(	TYPE			nvarchar(10)	collate database_default NOT NULL,
				CASEID			int		not null, 
				NAMETYPE		nvarchar(3)	collate database_default NOT NULL,
				OLDNAMENO		int		null, 
				NAMENO			int		null, 
				OLDCORRESPONDNAME	int		null, 
				CORRESPONDNAME		int		null, 
				OLDREFERENCENO		nvarchar(80)	collate database_default NULL,
				REFERENCENO		nvarchar(80)	collate database_default NULL,
				OLDADDRESSCODE		int		null,
				ADDRESSCODE		int		null,
				COMMENCEDATE		datetime	null
				)

Create table dbo.#TEMPPOLICE(	POLICINGSEQNO		int 		identity,
			        CASEID			int 		NOT NULL,
				EVENTNO			int		NULL,
			        CYCLE			smallint 	NOT NULL,
			        ACTION			nvarchar(2) 	collate database_default NULL,
				TYPEOFREQUEST		tinyint		NULL
				)

Create table dbo.#TEMPDERIVEDEVENTCHANGED(
				CASEID			int		NOT NULL
				)

Create table dbo.#TEMPCASESTOUPDATE(
				CASEID			int		NOT NULL
				)

-- The Cases whose Title has changed.
Create table dbo.#TEMPCASES(	CASEID			int		NOT NULL
				)

Create table dbo.#TEMPSTOPPAY (	CASEID			int		NOT NULL,
				EVENTNO			int		NOT NULL,
				CYCLE			smallint	NOT NULL,
				EVENTDATE		datetime	NULL,
				EVENTDUEDATE		datetime	NULL,
				OCCURREDFLAG		smallint	NULL,
				DATEDUESAVED		bit		NULL,
				EVENTTEXT		nvarchar(max)	collate database_default NULL,
				FUTUREDATENARRATIVE	int		NULL,
				PASTDATENARRATIVE	int		NULL
				)

Create table dbo.#TEMPCHECKRECIPROCAL (
				CASEID			int		NOT NULL, 
				RELATIONSHIPNO		int		NOT NULL, 
				RELATIONSHIP		nvarchar(3)	collate database_default NOT NULL,
				RELATEDCASEID		int		NOT NULL)

declare @nTranCountStart 	int
declare	@nTransactionCount	int
declare @nGlobalChanges		int
declare	@nPolicingRows		int
declare @nCaseCount		int
declare @nNewCaseCount		int
declare @nAmendCaseCount	int
declare @nReadyForProcess	int
declare @nIssueCount		int
declare	@nLoopCount		int
declare @nPoliceBatchNo		int		-- Batch number for Policing requests

declare @sRequestType		nvarchar(50)
declare @sLastTransId		nvarchar(50)
declare	@sRequestorNameType	nvarchar(3)
declare	@nSenderNameNo		int
declare @nReasonNo		int
declare	@nRuleNo		int
declare @sRule			nvarchar(max)

-- Declare working variables
Declare @sSQLModifiedCases	nvarchar(4000)
Declare	@sSQLString 		nvarchar(max)
Declare	@bHexNumber		varbinary(128)
Declare @nErrorCode 		int
Declare @nRowCount		int
Declare	@nTransNo		int
Declare @dtLogDateTime		datetime
Declare @nOfficeID		int
Declare @nLogMinutes		int
Declare @nStartPayEvent		int
Declare	@nStopPayEvent		int
Declare @nRetry			int

-- Flags to track existence of logs
Declare @bCasesLog		bit
Declare @bPropertyLog		bit
Declare @bCaseEventLog		bit
Declare @bCaseNameLog		bit
Declare @bCaseTextLog		bit
Declare @bOfficialNumbersLog	bit
Declare @bRelatedCaseLog	bit

------------------------------------
-- Variables for trapping any errors
-- raised during database update.
------------------------------------
declare @sErrorMessage		nvarchar(max)
declare @nErrorSeverity		int
declare @nErrorState		int

-----------------------
-- Initialise Variables
-----------------------
Set 	@nErrorCode 	= 0
Set	@pnRowCount	= 0
Set	@nCaseCount	= 0
Set	@bCasesLog	= 0
Set	@bPropertyLog	= 0
Set	@bCaseEventLog	= 0
Set	@bCaseNameLog	= 0
Set	@bCaseTextLog	= 0
Set	@bRelatedCaseLog= 0
Set	@bOfficialNumbersLog=0

--------------------------------------
-- Get the EventNos used to indicate
-- Start and Stop payment respectively
--------------------------------------

If @nErrorCode=0
Begin
	Set @sSQLString="
	Select @nStopPayEvent=COLINTEGER
	from SITECONTROL
	where CONTROLID='CPA Date-Stop'

	Select @nStartPayEvent=COLINTEGER
	from SITECONTROL
	where CONTROLID='CPA Date-Start'"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@nStopPayEvent	int		OUTPUT,
				  @nStartPayEvent	int		OUTPUT',
				  @nStopPayEvent  =@nStopPayEvent	OUTPUT,
				  @nStartPayEvent =@nStartPayEvent	OUTPUT
End

--------------------------------------
-- Initialise variables that will be 
-- loaded into CONTEXT_INFO for access
-- by the audit triggers
--------------------------------------
If @nErrorCode=0
Begin
	Set @sSQLString="
	Select @nOfficeID=COLINTEGER
	from SITECONTROL
	where CONTROLID='Office For Replication'

	Select @nLogMinutes=COLINTEGER
	from SITECONTROL
	where CONTROLID='Log Time Offset'"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@nOfficeID	int		OUTPUT,
				  @nLogMinutes	int		OUTPUT',
				  @nOfficeID  = @nOfficeID	OUTPUT,
				  @nLogMinutes=@nLogMinutes	OUTPUT
End
		
If(@pnUserIdentityId is null
or @pnUserIdentityId='')
and @nErrorCode=0
Begin
	Set @sSQLString="
	Select @pnUserIdentityId=min(IDENTITYID)
	from USERIDENTITY
	where LOGINID=substring(SYSTEM_USER,1,50)"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnUserIdentityId		int	OUTPUT',
			  @pnUserIdentityId=@pnUserIdentityId	OUTPUT
End


---------------------------------------
-- Check for the existence of the log
-- tables. This will be used later to 
-- check what data has been updated.
---------------------------------------
If @nErrorCode=0
Begin
	set @sSQLString="
	Select	@bCasesLog	    =@bCasesLog		 + CASE WHEN(TABLE_NAME='CASES_iLOG')		THEN 1 ELSE 0 END,
		@bPropertyLog	    =@bPropertyLog	 + CASE WHEN(TABLE_NAME='PROPERTY_iLOG')	THEN 1 ELSE 0 END,
		@bCaseEventLog	    =@bCaseEventLog	 + CASE WHEN(TABLE_NAME='CASEEVENT_iLOG')	THEN 1 ELSE 0 END,
		@bCaseNameLog	    =@bCaseNameLog	 + CASE WHEN(TABLE_NAME='CASENAME_iLOG') 	THEN 1 ELSE 0 END,
		@bCaseTextLog	    =@bCaseTextLog	 + CASE WHEN(TABLE_NAME='CASETEXT_iLOG') 	THEN 1 ELSE 0 END,
		@bRelatedCaseLog    =@bRelatedCaseLog	 + CASE WHEN(TABLE_NAME='RELATEDCASE_iLOG') 	THEN 1 ELSE 0 END,
		@bOfficialNumbersLog=@bOfficialNumbersLog+ CASE WHEN(TABLE_NAME='OFFICIALNUMBERS_iLOG')	THEN 1 ELSE 0 END
	from INFORMATION_SCHEMA.TABLES 
	where TABLE_NAME in ( 	'CASES_iLOG',
				'PROPERTY_iLOG',
				'CASEEVENT_iLOG',
				'CASENAME_iLOG',
				'CASETEXT_iLOG',
				'RELATEDCASE_iLOG',
				'OFFICIALNUMBERS_iLOG')"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@bCasesLog		bit			OUTPUT,
				  @bPropertyLog		bit			OUTPUT,
				  @bCaseEventLog	bit			OUTPUT,
				  @bCaseNameLog		bit			OUTPUT,
				  @bCaseTextLog		bit			OUTPUT,
				  @bOfficialNumbersLog	bit			OUTPUT,
				  @bRelatedCaseLog	bit			OUTPUT',
				  @bCasesLog		=@bCasesLog		OUTPUT,
				  @bPropertyLog		=@bPropertyLog		OUTPUT,
				  @bCaseEventLog	=@bCaseEventLog		OUTPUT,
				  @bCaseNameLog		=@bCaseNameLog		OUTPUT,
				  @bCaseTextLog		=@bCaseTextLog		OUTPUT,
				  @bOfficialNumbersLog	=@bOfficialNumbersLog	OUTPUT,
				  @bRelatedCaseLog	=@bRelatedCaseLog	OUTPUT
End

--------------------------------
-- Now construct a statement to 
-- load the Cases that have been
-- modified by reviewing the 
-- available log tables.
-- The constructed SQL will be
-- used after the Case updates
-- have been applied.
--------------------------------

If @nErrorCode=0
and (	@bCasesLog|
	@bPropertyLog|
	@bCaseEventLog|
	@bCaseNameLog|
	@bCaseTextLog|
     	@bOfficialNumbersLog|
	@bRelatedCaseLog)=1
Begin
	Set @sSQLModifiedCases=
	"Insert into #TEMPCASESTOUPDATE(CASEID)"

	If @bCasesLog=1
	Begin
		Set @sSQLModifiedCases=@sSQLModifiedCases+char(10)+
		"Select T.LIVECASEID"+char(10)+
		"From #TEMPCASEMATCH T"+char(10)+
		"join CASES_iLOG C on (C.CASEID=T.LIVECASEID)"+char(10)+
		"where C.LOGDATETIMESTAMP>=@dtLogDateTime"+char(10)+
		"and C.LOGTRANSACTIONNO=@nTransNo"
	End

	If @bPropertyLog=1
	Begin
		If @bCasesLog=1
			Set @sSQLModifiedCases=@sSQLModifiedCases+char(10)+"UNION"

		Set @sSQLModifiedCases=@sSQLModifiedCases+char(10)+
		"Select T.LIVECASEID"+char(10)+
		"From #TEMPCASEMATCH T"+char(10)+
		"join PROPERTY_iLOG C on (C.CASEID=T.LIVECASEID)"+char(10)+
		"where C.LOGDATETIMESTAMP>=@dtLogDateTime"+char(10)+
		"and C.LOGTRANSACTIONNO=@nTransNo"
	End

	If @bCaseEventLog=1
	Begin
		If @bCasesLog|@bPropertyLog=1
			Set @sSQLModifiedCases=@sSQLModifiedCases+char(10)+"UNION"

		Set @sSQLModifiedCases=@sSQLModifiedCases+char(10)+
		"Select T.LIVECASEID"+char(10)+
		"From #TEMPCASEMATCH T"+char(10)+
		"join CASEEVENT_iLOG C on (C.CASEID=T.LIVECASEID)"+char(10)+
		"where C.LOGDATETIMESTAMP>=@dtLogDateTime"+char(10)+
		"and C.LOGTRANSACTIONNO=@nTransNo"
	End

	If @bCaseNameLog=1
	Begin
		If @bCasesLog|@bPropertyLog|@bCaseEventLog=1
			Set @sSQLModifiedCases=@sSQLModifiedCases+char(10)+"UNION"

		Set @sSQLModifiedCases=@sSQLModifiedCases+char(10)+
		"Select T.LIVECASEID"+char(10)+
		"From #TEMPCASEMATCH T"+char(10)+
		"join CASENAME_iLOG C on (C.CASEID=T.LIVECASEID)"+char(10)+
		"where C.LOGDATETIMESTAMP>=@dtLogDateTime"+char(10)+
		"and C.LOGTRANSACTIONNO=@nTransNo"
	End

	If @bCaseTextLog=1
	Begin
		If @bCasesLog|@bPropertyLog|@bCaseEventLog|@bCaseNameLog=1
			Set @sSQLModifiedCases=@sSQLModifiedCases+char(10)+"UNION"

		Set @sSQLModifiedCases=@sSQLModifiedCases+char(10)+
		"Select T.LIVECASEID"+char(10)+
		"From #TEMPCASEMATCH T"+char(10)+
		"join CASETEXT_iLOG C on (C.CASEID=T.LIVECASEID)"+char(10)+
		"where C.LOGDATETIMESTAMP>=@dtLogDateTime"+char(10)+
		"and C.LOGTRANSACTIONNO=@nTransNo"
	End

	If @bOfficialNumbersLog=1
	Begin
		If @bCasesLog|@bPropertyLog|@bCaseEventLog|@bCaseNameLog|@bCaseTextLog=1
			Set @sSQLModifiedCases=@sSQLModifiedCases+char(10)+"UNION"

		Set @sSQLModifiedCases=@sSQLModifiedCases+char(10)+
		"Select T.LIVECASEID"+char(10)+
		"From #TEMPCASEMATCH T"+char(10)+
		"join OFFICIALNUMBERS_iLOG C on (C.CASEID=T.LIVECASEID)"+char(10)+
		"where C.LOGDATETIMESTAMP>=@dtLogDateTime"+char(10)+
		"and C.LOGTRANSACTIONNO=@nTransNo"
	End

	If @bRelatedCaseLog=1
	Begin
		If @bCasesLog|@bPropertyLog|@bCaseEventLog|@bCaseNameLog|@bCaseTextLog|@bOfficialNumbersLog=1
			Set @sSQLModifiedCases=@sSQLModifiedCases+char(10)+"UNION"

		Set @sSQLModifiedCases=@sSQLModifiedCases+char(10)+
		"Select T.LIVECASEID"+char(10)+
		"From #TEMPCASEMATCH T"+char(10)+
		"join RELATEDCASE_iLOG C on (C.CASEID=T.LIVECASEID)"+char(10)+
		"where C.LOGDATETIMESTAMP>=@dtLogDateTime"+char(10)+
		"and C.LOGTRANSACTIONNO=@nTransNo"
	End
End

If @nErrorCode=0
Begin
	---------------------------------------
	-- REQUEST TYPE AND SOURCE OF THE BATCH
	---------------------------------------
	Set @sSQLString="
	select	@nSenderNameNo	   =S.SENDERNAMENO,
		@sRequestType	   =S.SENDERREQUESTTYPE,
		@sRequestorNameType=R.REQUESTORNAMETYPE,
		@nReasonNo	   =R.TRANSACTIONREASONNO
	from EDESENDERDETAILS S
	join EDEREQUESTTYPE R on (R.REQUESTTYPECODE=S.SENDERREQUESTTYPE)
	where S.BATCHNO=@pnBatchNo"
	
	Exec @nErrorCode=sp_executesql @sSQLString,
				N'@sRequestType		nvarchar(50)	OUTPUT,
				  @nSenderNameNo	int		OUTPUT,
				  @sRequestorNameType	nvarchar(3)	OUTPUT,
				  @nReasonNo		int		OUTPUT,
				  @pnBatchNo		int',
				  @sRequestType	     =@sRequestType		OUTPUT,
				  @nSenderNameNo     =@nSenderNameNo		OUTPUT,
				  @sRequestorNameType=@sRequestorNameType	OUTPUT,
				  @nReasonNo	     =@nReasonNo		OUTPUT,
				  @pnBatchNo	     =@pnBatchNo
End


If @nErrorCode=0
Begin
	----------------------------------------------------------
	-- Get the total number of transactions that have a status
	-- of 'Ready for Case Update' or 'Operator Review'.
	-- This number will be used as a safeguard to ensure that
	-- an endless loop cannot occur.
	----------------------------------------------------------

	Set @sSQLString="
	Select  @nReadyForProcess=count(*)
	From EDETRANSACTIONBODY B
	where B.BATCHNO=@pnBatchNo
	and   B.TRANSSTATUSCODE in (3450,3460)	--'Ready For Case Update' or 'Operator Review'"


	Exec @nErrorCode=sp_executesql @sSQLString,
				N'@nReadyForProcess	int		OUTPUT,
				  @pnBatchNo		int',
				  @nReadyForProcess=@nReadyForProcess	OUTPUT,
				  @pnBatchNo	   =@pnBatchNo

	-----------------------------------------
	-- The maximum number of loops required 
	-- can be determined by dividing the 
	-- number of transactions to be processed
	-- by the size of the batch allowed.
	-----------------------------------------
	If  @pbReducedLocking=1
	and @nReadyForProcess>0
	and @pnMaxTrans      >0
		Set @nReadyForProcess=(@nReadyForProcess/@pnMaxTrans)+1

	Set @nLoopCount=0
	
	------------------------------------------
	-- Initialise the Last Transaction ID
	-- to ensure that we move forward through
	-- all of the transactions to be processed
	------------------------------------------
	Set @sLastTransId=''	
End
-------------------------------------------------------------------------------------
-- LOOP THROUGH VALID TRANSACTIONS
-------------------------------------------------------------------------------------
-- For performance reasons the transactions to be processed in parallel may be varied.
-- The lower the number of transactions, the least amount of time locks will be held
-- on the database.  The larger the number of transactions, the faster the overall 
-- processing time for the entire batch will be.
-------------------------------------------------------------------------------------

-- Continue looping until all Transactions marked as "Ready For Case Update" or
-- "Operator Review" have been processed or until the process has looped as many times
-- as there are available transactions (this is a safeguard against endless looping).

While @nReadyForProcess>@nLoopCount
and   @nErrorCode=0
and   Exists(select 1 from EDETRANSACTIONBODY
	     where BATCHNO=@pnBatchNo
	     and TRANSSTATUSCODE in (3450,3460)) -- 'Ready For Case Update' or 'Operator Review'
Begin
	-- Increment the Loop Count if the reduced locking
	-- mechanism is in use.
	If @pbReducedLocking=1
		Set @nLoopCount=@nLoopCount+1
	Else
		Set @nLoopCount=@nReadyForProcess

	-------------------------------------------------------------------------------------
	-- CHECK FOR TRANSACTIONS READY TO PROCESS
	-------------------------------------------------------------------------------------
	-- First check that there are rows to process by taking a snapshot of the
	-- transactions that are currently in a state to be processed.  Taking a snapshot
	-- allows those transactions that are not further enough progressed to be worked
	-- on in parallel to this processing.
	-------------------------------------------------------------------------------------
	If @nErrorCode=0
	Begin
		-- Start a new transaction
		Set @nTranCountStart = @@TranCount
		BEGIN TRANSACTION
		--------------------------------------------------------------------------------
		-- Only transactions in the given batch which are valid to this point 
		-- (ie. where transaction status = ‘Ready For Case Update' or 'Operator Review') 
		-- will be processed.
		-------------------------------------------------------------------------------- 
		If @nErrorCode=0
		Begin
			set @sSQLString="
			Insert into #TEMPCASEMATCH(TRANSACTIONIDENTIFIER, MATCHLEVEL, DRAFTCASEID, LIVECASEID, DATASOURCETYPE,TRANSSTATUSCODE)
			Select "+CASE WHEN(@pbReducedLocking=1) THEN "TOP "+convert(varchar,@pnMaxTrans)+" " ELSE '' END+
				"B.TRANSACTIONIDENTIFIER, M.MATCHLEVEL, M.DRAFTCASEID, M.LIVECASEID,
				---------------------------------
				-- Determine the Data Source Type
				---------------------------------
				CASE WHEN(@sRequestType='Data Verification')
					THEN 10302	-- 3rd Party
				     WHEN(@sRequestorNameType is null)	-- No data instructor
					THEN 10300	-- Direct
				     WHEN(CN1.NAMENO=CN2.NAMENO) 	-- Instructor and Data Instructor same
					THEN 10300	-- Direct
					ELSE 10301	-- Indirect
				END,
				B.TRANSSTATUSCODE
			From EDETRANSACTIONBODY B with (UPDLOCK)
			join EDECASEMATCH M	on (M.BATCHNO=B.BATCHNO
						and M.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER)
			left join CASENAME CN1	on (CN1.CASEID=M.DRAFTCASEID
						and CN1.NAMETYPE='I'
						and(CN1.EXPIRYDATE is null or CN1.EXPIRYDATE>getdate()))
			left join CASENAME CN2	on (CN2.CASEID=M.DRAFTCASEID
						and CN2.NAMETYPE=@sRequestorNameType
						and(CN2.EXPIRYDATE is null or CN2.EXPIRYDATE>getdate()))
			where B.BATCHNO=@pnBatchNo
			and  (B.TRANSACTIONIDENTIFIER=@psTransId or @psTransId is null)
			and   B.TRANSACTIONIDENTIFIER>@sLastTransId
			and   B.TRANSSTATUSCODE in(3450,3460)	--'Ready For Case Update' or 'Operator Review')
			Order by B.TRANSACTIONIDENTIFIER"
		
			Exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int,
						  @psTransId		nvarchar(50),
						  @sRequestType		nvarchar(50),
						  @sRequestorNameType	nvarchar(3),
						  @sLastTransId		nvarchar(50)',
						  @pnBatchNo		=@pnBatchNo,
						  @psTransId		=@psTransId,
						  @sRequestType		=@sRequestType,
						  @sRequestorNameType	=@sRequestorNameType,
						  @sLastTransId		=@sLastTransId
		
			Set @nTransactionCount=@@RowCount
		End
		
		If  @pbReducedLocking=1
		and @nTransactionCount>0
		and @nErrorCode=0
		Begin
			-- Get the highest TRANSACTIONIDENTIFIER
			-- in last batch just extracted.
			Set @sSQLString="
			Select @sLastTransId=max(TRANSACTIONIDENTIFIER)
			from #TEMPCASEMATCH"
			
			Exec @nErrorCode=sp_executesql @sSQLString,
						N'@sLastTransId	nvarchar(50)	OUTPUT',
						  @sLastTransId=@sLastTransId	OUTPUT
		End

		-- Commit transaction if successful
		If @@TranCount > @nTranCountStart
		Begin
			If @nErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
	End
	------------------------------------------------------------------------------------------
	-- DETERMINE RULES
	------------------------------------------------------------------------------------------
	-- Rule Type will be used to specify the functions to be performed during the update.
	-- The Rule Types used will differ based on the update type (New or Update):
	--
	-- Match Level	Rule Type
	-- -----------  --------------------------------------------------------------------------
	-- New		Use Mandatory rule(10303) to determine if any issues need to be created. 
	-- (3252)	If there are any medium level issues change status to 'Operator Review'.
	--
	--		Use New rule(10304) to determine if a case can be automatically created,
	--		or requires operator review.
	--
	-- Partial	Use Mandatory rule(10303) to determine if any issues need to be created.
	-- (3253)	Flag the input data as requiring manual processing. Transaction status
	--		changed to 'Operator Review'.
	--
	--		Use Auto Update rule(10305) to see if the whole Case is to be blocked from
	--		auto update.
	--
	-- Full		Use Mandatory rule(10303) to determine if any issues need to be created.
	-- (3254)
	-- 		Use Auto Update rule(10305) to determine which fields can be auto updated.
	------------------------------------------------------------------------------------------
	If @nErrorCode=0
	and @nTransactionCount>0
	Begin
		-------------------------------------
		-- Get the Mandatory Rule for each
		-- draft case that is to be processed
		-------------------------------------
		Set @sSQLString="
		Update #TEMPCASEMATCH
		Set MANDATORYRULE =
		       (SELECT
			convert(int,
			substring(
			max (
			CASE WHEN (C.CASEOFFICEID     IS NULL)	THEN '0' ELSE '1' END +
			CASE WHEN (C.REQUESTTYPE      IS NULL)	THEN '0' ELSE '1' END +
			CASE WHEN (C.DATASOURCETYPE   IS NULL)	THEN '0' ELSE '1' END +
			CASE WHEN (C.DATASOURCENAMENO IS NULL)	THEN '0' ELSE '1' END +
			CASE WHEN (C.CASETYPE         IS NULL)	THEN '0' 
				ELSE CASE WHEN(C.CASETYPE=CS.CASETYPE) 	 THEN '2' ELSE '1' END 
			END +  
			CASE WHEN (C.PROPERTYTYPE     IS NULL)	THEN '0' ELSE '1' END +    			
			CASE WHEN (C.COUNTRYCODE      IS NULL)	THEN '0' ELSE '1' END +
			CASE WHEN (C.CASECATEGORY     IS NULL)	THEN '0' ELSE '1' END +
			CASE WHEN (C.SUBTYPE          IS NULL)	THEN '0' ELSE '1' END +
			CASE WHEN (C.RENEWALSTATUS    IS NULL)	THEN '0' ELSE '1' END +
			CASE WHEN (C.STATUSCODE       IS NULL)	THEN '0' ELSE '1' END +
			CASE WHEN (C.USERDEFINEDRULE  IS NULL
				OR C.USERDEFINEDRULE = 0)	THEN '0' ELSE '1' END +
			convert(varchar,C.CRITERIANO)), 13,20))
			FROM CRITERIA C 
			     join CASES CS    on (CS.CASEID=T.DRAFTCASEID)
			     join CASETYPE CT on (CT.CASETYPE=CS.CASETYPE)
			left join PROPERTY P  on ( P.CASEID=CS.CASEID)
			WHERE	C.RULEINUSE		= 1  	
			AND	C.PURPOSECODE		= 'U' 
			AND	C.RULETYPE		= 10303 -- Mandatory Rule
			AND (	C.CASEOFFICEID 		= CS.OFFICEID 		OR C.CASEOFFICEID 	IS NULL )
			AND (	C.REQUESTTYPE 		= @sRequestType 	OR C.REQUESTTYPE 	IS NULL )
			AND (	C.DATASOURCETYPE	= T.DATASOURCETYPE      OR C.DATASOURCETYPE 	IS NULL )
			AND (	C.DATASOURCENAMENO	= @nSenderNameNo	OR C.DATASOURCENAMENO 	IS NULL )
			AND (	C.CASETYPE	      in (CS.CASETYPE,CT.ACTUALCASETYPE) or C.CASETYPE	is NULL )
			AND (	C.PROPERTYTYPE 		= CS.PROPERTYTYPE 	OR C.PROPERTYTYPE 	IS NULL ) 
			AND (	C.COUNTRYCODE 		= CS.COUNTRYCODE 	OR C.COUNTRYCODE 	IS NULL ) 
			AND (	C.CASECATEGORY 		= CS.CASECATEGORY 	OR C.CASECATEGORY 	IS NULL ) 
			AND (	C.SUBTYPE 		= CS.SUBTYPE 		OR C.SUBTYPE 		IS NULL ) 
			AND (	C.RENEWALSTATUS		= P.RENEWALSTATUS	OR C.RENEWALSTATUS	IS NULL ) 
			AND (	C.STATUSCODE		= CS.STATUSCODE		OR C.STATUSCODE		IS NULL )
			)
		From #TEMPCASEMATCH T"

		Exec @nErrorCode=sp_executesql @sSQLString,
					N'@sRequestType		nvarchar(50),
					  @nSenderNameNo	int',
					  @sRequestType=@sRequestType,
					  @nSenderNameNo=@nSenderNameNo

		If @nErrorCode=0
		Begin
			-------------------------------------
			-- Get the New Case Rule for each
			-- draft case flagged to create a new
			-- Case.
			-------------------------------------
			Set @sSQLString="
			Update #TEMPCASEMATCH
			Set NEWCASERULE =
			       (SELECT
				convert(int,
				substring(
				max (
				CASE WHEN (C.CASEOFFICEID     IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (C.REQUESTTYPE      IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (C.DATASOURCETYPE   IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (C.DATASOURCENAMENO IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (C.CASETYPE         IS NULL)	THEN '0' 
					ELSE CASE WHEN(C.CASETYPE=CS.CASETYPE) 	 THEN '2' ELSE '1' END 
				END +  
				CASE WHEN (C.PROPERTYTYPE     IS NULL)	THEN '0' ELSE '1' END +    			
				CASE WHEN (C.COUNTRYCODE      IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (C.CASECATEGORY     IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (C.SUBTYPE          IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (C.RENEWALSTATUS    IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (C.STATUSCODE       IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (C.USERDEFINEDRULE  IS NULL
					OR C.USERDEFINEDRULE = 0)	THEN '0' ELSE '1' END +
				convert(varchar,C.CRITERIANO)), 13,20))
				FROM CRITERIA C 
				     join CASES CS    on (CS.CASEID=T.DRAFTCASEID)
				     join CASETYPE CT on (CT.CASETYPE=CS.CASETYPE)
				left join PROPERTY P  on ( P.CASEID=CS.CASEID)
				WHERE	C.RULEINUSE		= 1  	
				AND	C.PURPOSECODE		= 'U' 
				AND	C.RULETYPE		= 10304 -- New Case Rule
				AND (	C.CASEOFFICEID 		= CS.OFFICEID 		OR C.CASEOFFICEID 	IS NULL )
				AND (	C.REQUESTTYPE 		= @sRequestType 	OR C.REQUESTTYPE 	IS NULL )
				AND (	C.DATASOURCETYPE	= T.DATASOURCETYPE      OR C.DATASOURCETYPE 	IS NULL )
				AND (	C.DATASOURCENAMENO	= @nSenderNameNo	OR C.DATASOURCENAMENO 	IS NULL )
				AND (	C.CASETYPE	      in (CS.CASETYPE,CT.ACTUALCASETYPE) or C.CASETYPE	is NULL )
				AND (	C.PROPERTYTYPE 		= CS.PROPERTYTYPE 	OR C.PROPERTYTYPE 	IS NULL ) 
				AND (	C.COUNTRYCODE 		= CS.COUNTRYCODE 	OR C.COUNTRYCODE 	IS NULL ) 
				AND (	C.CASECATEGORY 		= CS.CASECATEGORY 	OR C.CASECATEGORY 	IS NULL ) 
				AND (	C.SUBTYPE 		= CS.SUBTYPE 		OR C.SUBTYPE 		IS NULL ) 
				AND (	C.RENEWALSTATUS		= P.RENEWALSTATUS	OR C.RENEWALSTATUS	IS NULL ) 
				AND (	C.STATUSCODE		= CS.STATUSCODE		OR C.STATUSCODE		IS NULL )
				)
			From #TEMPCASEMATCH T
			Where T.MATCHLEVEL=3252		-- No match (create new case)
			and T.TRANSSTATUSCODE=3450	-- Ready for Update"
		
			Exec @nErrorCode=sp_executesql @sSQLString,
						N'@sRequestType		nvarchar(50),
						  @nSenderNameNo	int',
						  @sRequestType=@sRequestType,
						  @nSenderNameNo=@nSenderNameNo
		End

		If @nErrorCode=0
		Begin
			-----------------------------------
			-- Get the Amend Case Rule for each
			-- draft case flagged to update an
			-- existing Case.
			-----------------------------------
			Set @sSQLString="
			Update #TEMPCASEMATCH
			Set AMENDCASERULE =
			       (SELECT
				convert(int,
				substring(
				max (
				CASE WHEN (C.CASEOFFICEID     IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (C.REQUESTTYPE      IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (C.DATASOURCETYPE   IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (C.DATASOURCENAMENO IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (C.CASETYPE         IS NULL)	THEN '0' 
					ELSE CASE WHEN(C.CASETYPE=CS.CASETYPE) 	 THEN '2' ELSE '1' END 
				END +  
				CASE WHEN (C.PROPERTYTYPE     IS NULL)	THEN '0' ELSE '1' END +    			
				CASE WHEN (C.COUNTRYCODE      IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (C.CASECATEGORY     IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (C.SUBTYPE          IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (C.RENEWALSTATUS    IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (C.STATUSCODE       IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (C.USERDEFINEDRULE  IS NULL
					OR C.USERDEFINEDRULE = 0)	THEN '0' ELSE '1' END +
				convert(varchar,C.CRITERIANO)), 13,20))
				FROM CRITERIA C 
				     join CASES CS    on (CS.CASEID=T.LIVECASEID)
				     join CASETYPE CT on (CT.CASETYPE=CS.CASETYPE)
				left join PROPERTY P  on ( P.CASEID=CS.CASEID)
				WHERE	C.RULEINUSE		= 1  	
				AND	C.PURPOSECODE		= 'U' 
				AND	C.RULETYPE		= 10305 -- Amend Case Rule
				AND (	C.CASEOFFICEID 		= CS.OFFICEID 		OR C.CASEOFFICEID 	IS NULL )
				AND (	C.REQUESTTYPE 		= @sRequestType 	OR C.REQUESTTYPE 	IS NULL )
				AND (	C.DATASOURCETYPE	= T.DATASOURCETYPE      OR C.DATASOURCETYPE 	IS NULL )
				AND (	C.DATASOURCENAMENO	= @nSenderNameNo	OR C.DATASOURCENAMENO 	IS NULL )
				AND (	C.CASETYPE	      in (CS.CASETYPE,CT.ACTUALCASETYPE) or C.CASETYPE	is NULL )
				AND (	C.PROPERTYTYPE 		= CS.PROPERTYTYPE 	OR C.PROPERTYTYPE 	IS NULL ) 
				AND (	C.COUNTRYCODE 		= CS.COUNTRYCODE 	OR C.COUNTRYCODE 	IS NULL ) 
				AND (	C.CASECATEGORY 		= CS.CASECATEGORY 	OR C.CASECATEGORY 	IS NULL ) 
				AND (	C.SUBTYPE 		= CS.SUBTYPE 		OR C.SUBTYPE 		IS NULL ) 
				AND (	C.RENEWALSTATUS		= P.RENEWALSTATUS	OR C.RENEWALSTATUS	IS NULL ) 
				AND (	C.STATUSCODE		= CS.STATUSCODE		OR C.STATUSCODE		IS NULL )
				)
			From #TEMPCASEMATCH T
			Where T.MATCHLEVEL in (3253,3254)-- Partial or Full Match
			and T.TRANSSTATUSCODE=3450	 -- Ready for Update"
		
			Exec @nErrorCode=sp_executesql @sSQLString,
						N'@sRequestType		nvarchar(50),
						  @nSenderNameNo	int',
						  @sRequestType=@sRequestType,
						  @nSenderNameNo=@nSenderNameNo
		End

		--=======================================================================================
		-- APPLY RULES
		--=======================================================================================
		-- Apply the Action held for the rule against each data field.
		-- The type of Action to be taken will differ for each rule type.
		-----------------------------------------------------------------------------------------

		--=======================================================================================
		-- MANDATORY RULES PROCESSING
		--=======================================================================================

		-- In order to efficiently process the draft Cases,
		-- we will loop through each different Mandatory
		-- Rule and process all the draft Cases that share
		-- the same rule.

		If @nErrorCode=0
		Begin
			Set @nRuleNo=null

			-- Get the first Mandatory rule

			Set @sSQLString="
			Select @nRuleNo=min(MANDATORYRULE)
			FROM #TEMPCASEMATCH
			WHERE MANDATORYRULE is not null"

			exec @nErrorCode=sp_executesql @sSQLString,
						N'@nRuleNo	int	OUTPUT',
						  @nRuleNo=@nRuleNo	OUTPUT
		End

		Set @nIssueCount=0

		While @nRuleNo is not null
		and @nErrorCode=0
		Begin
			---------------------------------------------------
			-- Mandatory Rules are held against fields and
			-- indicate the Issue to raise.
			--
			-- Check the tables for mandatory fields.
			-- Raise issue when mandatory field(s) are missing.
			---------------------------------------------------

			------------------------
			-- CASES and PROPERTY --
			------------------------
			Set @sSQLString="
			Insert into #TEMPISSUE(TRANSACTIONIDENTIFIER,DRAFTCASEID,LIVECASEID,ISSUEID,SEVERITYLEVEL)
			Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID,T.LIVECASEID,
				S.ISSUEID,S.SEVERITYLEVEL
			From #TEMPCASEMATCH T
			join CASES C		on (C.CASEID=T.DRAFTCASEID)
			join EDERULECASE R	on (R.CRITERIANO=T.MANDATORYRULE)
			join EDESTANDARDISSUE S on (S.ISSUEID=R.CASETYPE)
			Where T.MANDATORYRULE=@nRuleNo
			and C.CASETYPE is null
			UNION ALL
			Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID,T.LIVECASEID,
				S.ISSUEID,S.SEVERITYLEVEL
			From #TEMPCASEMATCH T
			join CASES C		on (C.CASEID=T.DRAFTCASEID)
			join EDERULECASE R	on (R.CRITERIANO=T.MANDATORYRULE)
			join EDESTANDARDISSUE S on (S.ISSUEID=R.PROPERTYTYPE)
			Where T.MANDATORYRULE=@nRuleNo
			and C.PROPERTYTYPE is null
			UNION ALL
			Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID,T.LIVECASEID,
				S.ISSUEID,S.SEVERITYLEVEL
			From #TEMPCASEMATCH T
			join CASES C		on (C.CASEID=T.DRAFTCASEID)
			join EDERULECASE R	on (R.CRITERIANO=T.MANDATORYRULE)
			join EDESTANDARDISSUE S on (S.ISSUEID=R.COUNTRY)
			Where T.MANDATORYRULE=@nRuleNo
			and C.COUNTRYCODE is null
			UNION ALL
			Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID,T.LIVECASEID,
				S.ISSUEID,S.SEVERITYLEVEL
			From #TEMPCASEMATCH T
			join CASES C		on (C.CASEID=T.DRAFTCASEID)
			join EDERULECASE R	on (R.CRITERIANO=T.MANDATORYRULE)
			join EDESTANDARDISSUE S on (S.ISSUEID=R.CATEGORY)
			Where T.MANDATORYRULE=@nRuleNo
			and C.CASECATEGORY is null
			UNION ALL
			Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID,T.LIVECASEID,
				S.ISSUEID,S.SEVERITYLEVEL
			From #TEMPCASEMATCH T
			join CASES C		on (C.CASEID=T.DRAFTCASEID)
			join EDERULECASE R	on (R.CRITERIANO=T.MANDATORYRULE)
			join EDESTANDARDISSUE S on (S.ISSUEID=R.SUBTYPE)
			Where T.MANDATORYRULE=@nRuleNo
			and C.SUBTYPE is null"

			exec @nErrorCode=sp_executesql @sSQLString,
						N'@nRuleNo	int',
						  @nRuleNo=@nRuleNo

			Set @nIssueCount=@nIssueCount+@@rowcount

			If @nErrorCode=0
			Begin
				---------------------------------
				-- CASES and PROPERTY continued..
				---------------------------------
				Set @sSQLString="
				Insert into #TEMPISSUE(TRANSACTIONIDENTIFIER,DRAFTCASEID,LIVECASEID,ISSUEID,SEVERITYLEVEL)
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID,T.LIVECASEID,
					S.ISSUEID,S.SEVERITYLEVEL
				From #TEMPCASEMATCH T
				left join PROPERTY P	on (P.CASEID=T.DRAFTCASEID)
				join EDERULECASE R	on (R.CRITERIANO=T.MANDATORYRULE)
				join EDESTANDARDISSUE S on (S.ISSUEID=R.BASIS)
				Where T.MANDATORYRULE=@nRuleNo
				and P.BASIS is null
				UNION ALL
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID,T.LIVECASEID,
					S.ISSUEID,S.SEVERITYLEVEL
				From #TEMPCASEMATCH T
				join CASES C		on (C.CASEID=T.DRAFTCASEID)
				join EDERULECASE R	on (R.CRITERIANO=T.MANDATORYRULE)
				join EDESTANDARDISSUE S on (S.ISSUEID=R.ENTITYSIZE)
				Where T.MANDATORYRULE=@nRuleNo
				and C.ENTITYSIZE is null
				UNION ALL
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID,T.LIVECASEID,
					S.ISSUEID,S.SEVERITYLEVEL
				From #TEMPCASEMATCH T
				join CASES C		on (C.CASEID=T.DRAFTCASEID)
				join EDERULECASE R	on (R.CRITERIANO=T.MANDATORYRULE)
				join EDESTANDARDISSUE S on (S.ISSUEID=R.TYPEOFMARK)
				Where T.MANDATORYRULE=@nRuleNo
				and C.TYPEOFMARK is null
				UNION ALL
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID,T.LIVECASEID,
					S.ISSUEID,S.SEVERITYLEVEL
				From #TEMPCASEMATCH T
				left join PROPERTY P	on (P.CASEID=T.DRAFTCASEID)
				join EDERULECASE R	on (R.CRITERIANO=T.MANDATORYRULE)
				join EDESTANDARDISSUE S on (S.ISSUEID=R.NUMBEROFCLAIMS)
				Where T.MANDATORYRULE=@nRuleNo
				and P.NOOFCLAIMS is null
				UNION ALL
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID,T.LIVECASEID,
					S.ISSUEID,S.SEVERITYLEVEL
				From #TEMPCASEMATCH T
				join CASES C		on (C.CASEID=T.DRAFTCASEID)
				join EDERULECASE R	on (R.CRITERIANO=T.MANDATORYRULE)
				join EDESTANDARDISSUE S on (S.ISSUEID=R.NUMBEROFDESIGNS)
				Where T.MANDATORYRULE=@nRuleNo
				and C.NOINSERIES is null
				UNION ALL
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID,T.LIVECASEID,
					S.ISSUEID,S.SEVERITYLEVEL
				From #TEMPCASEMATCH T
				join CASES C		on (C.CASEID=T.DRAFTCASEID)
				join EDERULECASE R	on (R.CRITERIANO=T.MANDATORYRULE)
				join EDESTANDARDISSUE S on (S.ISSUEID=R.NUMBEROFYEARSEXT)
				Where T.MANDATORYRULE=@nRuleNo
				and C.EXTENDEDRENEWALS is null
				UNION ALL
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID,T.LIVECASEID,
					S.ISSUEID,S.SEVERITYLEVEL
				From #TEMPCASEMATCH T
				join CASES C		on (C.CASEID=T.DRAFTCASEID)
				join EDERULECASE R	on (R.CRITERIANO=T.MANDATORYRULE)
				join EDESTANDARDISSUE S on (S.ISSUEID=R.STOPPAYREASON)
				Where T.MANDATORYRULE=@nRuleNo
				and C.STOPPAYREASON is null
				UNION ALL
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID,T.LIVECASEID,
					S.ISSUEID,S.SEVERITYLEVEL
				From #TEMPCASEMATCH T
				join CASES C		on (C.CASEID=T.DRAFTCASEID)
				join EDERULECASE R	on (R.CRITERIANO=T.MANDATORYRULE)
				join EDESTANDARDISSUE S on (S.ISSUEID=R.SHORTTITLE)
				Where T.MANDATORYRULE=@nRuleNo
				and C.TITLE is null
				UNION ALL
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID,T.LIVECASEID,
					S.ISSUEID,S.SEVERITYLEVEL
				From #TEMPCASEMATCH T
				join CASES C		on (C.CASEID=T.DRAFTCASEID)
				join EDERULECASE R	on (R.CRITERIANO=T.MANDATORYRULE)
				join EDESTANDARDISSUE S on (S.ISSUEID=R.CLASSES)
				Where T.MANDATORYRULE=@nRuleNo
				and C.LOCALCLASSES is null
				UNION ALL
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID,T.LIVECASEID,
					S.ISSUEID,S.SEVERITYLEVEL
				From #TEMPCASEMATCH T
				join EDERULECASE R	on (R.CRITERIANO=T.MANDATORYRULE)
				join EDESTANDARDISSUE S on (S.ISSUEID=R.DESIGNATEDCOUNTRIES)
				left join RELATEDCASE C	on (C.CASEID=T.DRAFTCASEID
							and C.RELATIONSHIP='DC1'
							and C.COUNTRYCODE is not null)
				Where T.MANDATORYRULE=@nRuleNo
				and C.COUNTRYCODE is null"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@nRuleNo	int',
							  @nRuleNo=@nRuleNo

				Set @nIssueCount=@nIssueCount+@@rowcount
			End

			--------------
			-- CASENAME --
			--------------
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Insert into #TEMPISSUE(TRANSACTIONIDENTIFIER,DRAFTCASEID,LIVECASEID,ISSUEID,SEVERITYLEVEL)
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID,T.LIVECASEID,
					S.ISSUEID,S.SEVERITYLEVEL
				From #TEMPCASEMATCH T
				join EDERULECASENAME R	on (R.CRITERIANO=T.MANDATORYRULE)
				left join CASENAME CN	on (CN.CASEID=T.DRAFTCASEID
							and CN.NAMETYPE=R.NAMETYPE
							and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))
				join EDESTANDARDISSUE S on (S.ISSUEID=R.NAMENO)
				Where T.MANDATORYRULE=@nRuleNo
				and CN.NAMENO is null
				UNION ALL
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID,T.LIVECASEID,
					S.ISSUEID,S.SEVERITYLEVEL
				From #TEMPCASEMATCH T
				join EDERULECASENAME R	on (R.CRITERIANO=T.MANDATORYRULE)
				left join CASENAME CN	on (CN.CASEID=T.DRAFTCASEID
							and CN.NAMETYPE=R.NAMETYPE
							and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))
				join EDESTANDARDISSUE S on (S.ISSUEID=R.REFERENCENO)
				Where T.MANDATORYRULE=@nRuleNo
				and CN.REFERENCENO is null
				UNION ALL
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID,T.LIVECASEID,
					S.ISSUEID,S.SEVERITYLEVEL
				From #TEMPCASEMATCH T
				join EDERULECASENAME R	on (R.CRITERIANO=T.MANDATORYRULE)
				left join CASENAME CN	on (CN.CASEID=T.DRAFTCASEID
							and CN.NAMETYPE=R.NAMETYPE
							and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))
				join EDESTANDARDISSUE S on (S.ISSUEID=R.CORRESPONDNAME)
				Where T.MANDATORYRULE=@nRuleNo
				and CN.CORRESPONDNAME is null"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@nRuleNo	int',
							  @nRuleNo=@nRuleNo

				Set @nIssueCount=@nIssueCount+@@rowcount
			End

			---------------------
			-- OFFICIALNUMBERS --
			---------------------
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Insert into #TEMPISSUE(TRANSACTIONIDENTIFIER,DRAFTCASEID,LIVECASEID,ISSUEID,SEVERITYLEVEL)
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID,T.LIVECASEID,
					S.ISSUEID,S.SEVERITYLEVEL
				From #TEMPCASEMATCH T
				join EDERULEOFFICIALNUMBER R	on (R.CRITERIANO=T.MANDATORYRULE)
				left join OFFICIALNUMBERS N	on (N.CASEID=T.DRAFTCASEID
								and N.NUMBERTYPE=R.NUMBERTYPE)
				join EDESTANDARDISSUE S 	on (S.ISSUEID=R.OFFICIALNUMBER)
				Where T.MANDATORYRULE=@nRuleNo
				and N.OFFICIALNUMBER is null"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@nRuleNo	int',
							  @nRuleNo=@nRuleNo

				Set @nIssueCount=@nIssueCount+@@rowcount
			End

			--------------
			-- CASETEXT --
			--------------
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Insert into #TEMPISSUE(TRANSACTIONIDENTIFIER,DRAFTCASEID,LIVECASEID,ISSUEID,SEVERITYLEVEL)
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID,T.LIVECASEID,
					S.ISSUEID,S.SEVERITYLEVEL
				From #TEMPCASEMATCH T
				join EDERULECASETEXT R	on (R.CRITERIANO=T.MANDATORYRULE)
				left join CASETEXT CT	on (CT.CASEID=T.DRAFTCASEID
							and CT.TEXTTYPE=R.TEXTTYPE)
				join EDESTANDARDISSUE S on (S.ISSUEID=R.TEXT)
				Where T.MANDATORYRULE=@nRuleNo
				and CT.SHORTTEXT is null
				and CT.TEXT is null"

				exec @nErrorCode=sp_executesql @sSQLString,
							N'@nRuleNo	int',
							  @nRuleNo=@nRuleNo

				Set @nIssueCount=@nIssueCount+@@rowcount
			End

			---------------
			-- CASEEVENT --
			---------------
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Insert into #TEMPISSUE(TRANSACTIONIDENTIFIER,DRAFTCASEID,LIVECASEID,ISSUEID,SEVERITYLEVEL)
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID,T.LIVECASEID,
					S.ISSUEID,S.SEVERITYLEVEL
				From #TEMPCASEMATCH T
				join EDERULECASEEVENT R	on (R.CRITERIANO=T.MANDATORYRULE)
				left join CASEEVENT CE	on (CE.CASEID=T.DRAFTCASEID
							and CE.EVENTNO=R.EVENTNO)
				join EDESTANDARDISSUE S on (S.ISSUEID=R.EVENTDATE)
				Where T.MANDATORYRULE=@nRuleNo
				and CE.EVENTDATE is null
				UNION
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID,T.LIVECASEID,
					S.ISSUEID,S.SEVERITYLEVEL
				From #TEMPCASEMATCH T
				join EDERULECASEEVENT R	on (R.CRITERIANO=T.MANDATORYRULE)
				left join CASEEVENT CE	on (CE.CASEID=T.DRAFTCASEID
							and CE.EVENTNO=R.EVENTNO)
				join EDESTANDARDISSUE S on (S.ISSUEID=R.EVENTDUEDATE)
				Where T.MANDATORYRULE=@nRuleNo
				and CE.EVENTDUEDATE is null
				UNION
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID,T.LIVECASEID,
					S.ISSUEID,S.SEVERITYLEVEL
				From #TEMPCASEMATCH T
				join EDERULECASEEVENT R	on (R.CRITERIANO=T.MANDATORYRULE)
				left join CASEEVENT CE	on (CE.CASEID=T.DRAFTCASEID
							and CE.EVENTNO=R.EVENTNO)
				join EDESTANDARDISSUE S on (S.ISSUEID=R.EVENTTEXT)
				Where T.MANDATORYRULE=@nRuleNo
				and CE.EVENTTEXT is null
				and CE.EVENTLONGTEXT is null"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@nRuleNo	int',
							  @nRuleNo=@nRuleNo

				Set @nIssueCount=@nIssueCount+@@rowcount
			End

			-----------------
			-- RELATEDCASE --
			-----------------
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Insert into #TEMPISSUE(TRANSACTIONIDENTIFIER,DRAFTCASEID,LIVECASEID,ISSUEID,SEVERITYLEVEL)
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID,T.LIVECASEID,
					S.ISSUEID,S.SEVERITYLEVEL
				From #TEMPCASEMATCH T
				join EDERULERELATEDCASE R	on (R.CRITERIANO=T.MANDATORYRULE)
				left join RELATEDCASE RE	on (RE.CASEID=T.DRAFTCASEID
								and RE.RELATIONSHIP=R.RELATIONSHIP)
				join EDESTANDARDISSUE S 	on (S.ISSUEID=R.OFFICIALNUMBER)
				Where T.MANDATORYRULE=@nRuleNo
				and RE.OFFICIALNUMBER is null
				UNION
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID,T.LIVECASEID,
					S.ISSUEID,S.SEVERITYLEVEL
				From #TEMPCASEMATCH T
				join EDERULERELATEDCASE R	on (R.CRITERIANO=T.MANDATORYRULE)
				left join RELATEDCASE RE	on (RE.CASEID=T.DRAFTCASEID
								and RE.RELATIONSHIP=R.RELATIONSHIP)
				join EDESTANDARDISSUE S 	on (S.ISSUEID=R.PRIORITYDATE)
				Where T.MANDATORYRULE=@nRuleNo
				and RE.PRIORITYDATE is null"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@nRuleNo	int',
							  @nRuleNo=@nRuleNo

				Set @nIssueCount=@nIssueCount+@@rowcount
			End

			-------------------------------
			-- Get the next rule to process
			-------------------------------
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Select @nRuleNo=min(MANDATORYRULE)
				FROM #TEMPCASEMATCH
				WHERE MANDATORYRULE>@nRuleNo"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@nRuleNo	int	OUTPUT',
							  @nRuleNo=@nRuleNo	OUTPUT
			End
		End -- End Mandatory Rule Processing Loop

		------------------------------------
		-- APPLY MANDATORY RULES TO DATABASE
		------------------------------------
		If  @nErrorCode=0
		and @nIssueCount>0
		Begin	
			-----------------------------------------------------------------------------
			-- A separate database transaction will be used to insert the TRANSACTIONINFO
			-- row to ensure the lock on the database is kept to a minimum as this table
			-- will be used extensively by other processes.
			-----------------------------------------------------------------------------
		
			Select @nTranCountStart = @@TranCount
			BEGIN TRANSACTION
		
			-- Allocate a transaction id that can be accessed by the audit logs
			-- for inclusion.
		
			Set @sSQLString="Insert into TRANSACTIONINFO(TRANSACTIONDATE, BATCHNO,TRANSACTIONMESSAGENO, TRANSACTIONREASONNO) values(getdate(),@pnBatchNo,1,@nReasonNo)
					Set @nTransNo=SCOPE_IDENTITY()"
			
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int,
							  @nReasonNo	int,
							  @nTransNo	int	OUTPUT',
							  @pnBatchNo=@pnBatchNo,
							  @nReasonNo=@nReasonNo,
							  @nTransNo=@nTransNo	OUTPUT
		
			--------------------------------------------------------------
			-- Load a common area accessible from the database server with
			-- the TransactionNo just generated and other details.
			-- This will be used by the audit logs.
			--------------------------------------------------------------
		
			set @bHexNumber=substring(cast(isnull(@pnUserIdentityId,'') as varbinary),1,4) + 
					substring(cast(isnull(@nTransNo,'') as varbinary),1,4)+ 
					substring(cast(isnull(@pnBatchNo,'') as varbinary),1,4) +
					substring(cast(isnull(@nOfficeID,'') as varbinary),1,4) +
					substring(cast(isnull(@nLogMinutes,'') as varbinary),1,4)
			SET CONTEXT_INFO @bHexNumber

			Set @nIssueCount=0
		
			-- Commit or Rollback the transaction
			
			If @@TranCount > @nTranCountStart
			Begin
				If @nErrorCode = 0
					COMMIT TRANSACTION
				Else
					ROLLBACK TRANSACTION
			End
		End

		If @nErrorCode=0
		Begin
			Set @nRetry=3
			While @nRetry>0
			and @nErrorCode=0
			Begin
				BEGIN TRY
					-- Start a new transaction
					Set @nTranCountStart = @@TranCount
					BEGIN TRANSACTION
				
					--------------------------------------
					-- SEVERITY CHECK OF THE ISSUES RAISED
					--------------------------------------

					------------------------------------
					-- Insert the outstanding issues
					------------------------------------
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, CASEID, DATECREATED)
						Select 	distinct T.ISSUEID, @pnBatchNo, T.TRANSACTIONIDENTIFIER, 
							-- draft cases with HIGH severity will be deleted so don't reference CASEID
							CASE WHEN(T.SEVERITYLEVEL=4010) THEN NULL ELSE C.CASEID END, 
							getdate()
						from #TEMPISSUE T
						join #TEMPCASEMATCH CM		 on (CM.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
						left join CASES C		 on (C.CASEID=CM.DRAFTCASEID)
						left join EDEOUTSTANDINGISSUES I on (I.ISSUEID=T.ISSUEID
										 and I.BATCHNO=@pnBatchNo
										 and I.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
						where I.ISSUEID is null"
				
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@pnBatchNo	int',
									  @pnBatchNo=@pnBatchNo
					End

					-------------------------------------------
					-- Update the Transaction Status as follows
					-- Severity	Transaction Status
					-- --------     ------------------
					-- HIGH		3480 (processed)
					-- 
					-- Issues that do not have a High severity
					-- level will not update the Transaction
					-- Status at this time as we need to see
					-- if updates are still allowed.
					--------------------------------------------
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Update EDETRANSACTIONBODY
						Set TRANSSTATUSCODE=CASE WHEN(I.SEVERITYLEVEL=4010) THEN 3480 -- HIGH   becomes Processed
									 WHEN(T.MATCHLEVEL=3253)    THEN 3460 -- PARTIAL Match becomes Operator Review
								    END,
						    TRANSNARRATIVECODE=CASE WHEN(convert(int,SUBSTRING(SI.DEFAULTNARRATIVE,12,11))<>0) 
										THEN convert(int,SUBSTRING(SI.DEFAULTNARRATIVE,12,11))
										ELSE B.TRANSNARRATIVECODE
									END
						from EDETRANSACTIONBODY B
						join #TEMPCASEMATCH T	on (T.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER)
						left join #TEMPISSUE I	on (I.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER
									and I.SEVERITYLEVEL=4010)
						left join (	select	O.BATCHNO, 
									O.TRANSACTIONIDENTIFIER, 
									-- the highest Severity has the lowest SeverityLevel
									min(left(replicate('0', 11-len(S.SEVERITYLEVEL))   +convert(CHAR(11), S.SEVERITYLEVEL)   ,11)+	
									    CASE WHEN(S.DEFAULTNARRATIVE<0) THEN '-' ELSE '0' END + RIGHT('0000000000'+replace(cast(S.DEFAULTNARRATIVE as nvarchar),'-',''),10)	  -- NOTE: DEFAULTNARRATIVE can be a negative number
									   ) as DEFAULTNARRATIVE
								from EDEOUTSTANDINGISSUES O
								join EDESTANDARDISSUE S	on (S.ISSUEID=O.ISSUEID)
								where S.SEVERITYLEVEL=4010
								group by O.BATCHNO, O.TRANSACTIONIDENTIFIER) SI
									on (SI.BATCHNO=B.BATCHNO
									and SI.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER)
						Where B.BATCHNO=@pnBatchNo
						and (T.MATCHLEVEL=3253 
						 or  I.SEVERITYLEVEL is not null)"

						exec @nErrorCode=sp_executesql @sSQLString,
										N'@pnBatchNo	int',
										  @pnBatchNo=@pnBatchNo

					End

					If @nErrorCode=0
					Begin
						---------------------------------------------------------------
						-- If the transaction found a draft case from an earlier batch,
						-- then the draft Case was replaced with this transaction. The
						-- earlier batch transaction for the matching draft case now
						-- needs to have its TRANSSTATUSCODE updated.
						-------------------------------------------------------------
						Set @sSQLString="
						Update EDETRANSACTIONBODY
						Set	TRANSSTATUSCODE   	=T1.TRANSSTATUSCODE,
							TRANSACTIONRETURNCODE	=T1.TRANSACTIONRETURNCODE,
							TRANSNARRATIVECODE	=T1.TRANSNARRATIVECODE
						From #TEMPCASEMATCH TM
						left join #TEMPISSUE I	on (I.TRANSACTIONIDENTIFIER=TM.TRANSACTIONIDENTIFIER
									and I.SEVERITYLEVEL=4010)
						join EDECASEMATCH CM	on (CM.TRANSACTIONIDENTIFIER=TM.TRANSACTIONIDENTIFIER)
						join EDECASEMATCH M	  on (M.DRAFTCASEID=CM.DRAFTCASEID
									  and M.BATCHNO<>CM.BATCHNO)
						join EDETRANSACTIONBODY T on (T.BATCHNO=M.BATCHNO
									  and T.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
						-- Use derived table to avoid ambiguous table error
						join (select * from EDETRANSACTIONBODY) T1
									  on (T1.BATCHNO=CM.BATCHNO
									  and T1.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
						Where CM.BATCHNO=@pnBatchNo
						and (TM.MATCHLEVEL=3253 
						 or  I.SEVERITYLEVEL is not null)"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@pnBatchNo	int',
									  @pnBatchNo=@pnBatchNo
					End
				
					----------------------------------------------------------
					-- Delete Draft Cases where the Severity is HIGH.
					-- First delete draft Case from EDECASEMATCH.
					-- Note that rows from other batches may be removed as the
					-- same draft case may belong in multiple batches.
					----------------------------------------------------------
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Delete EDECASEMATCH
						from (select * from EDECASEMATCH) C
						join #TEMPCASEMATCH M	on (M.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
						join EDECASEMATCH CM	on (CM.DRAFTCASEID=C.DRAFTCASEID)
						join #TEMPISSUE I	on (I.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
						where C.BATCHNO=@pnBatchNo
						and CM.LIVECASEID is null
						and I.SEVERITYLEVEL=4010"	-- Severity is HIGH-REJECT
				
						exec @nErrorCode=sp_executesql @sSQLString,
										N'@pnBatchNo	int',
										  @pnBatchNo
					End

					-------------------------------------------------
					-- Delete unprocessed Policing requests against
					-- the POLICING table if the Case has been
					-- removed from EDECASEMATCH.
					-------------------------------------------------
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Delete POLICING
						from POLICING P
						join #TEMPCASEMATCH T		on (T.DRAFTCASEID=P.CASEID)
						join #TEMPISSUE I		on (I.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
						left join EDECASEMATCH CM	on (CM.DRAFTCASEID=P.CASEID)
						where CM.DRAFTCASEID is null
						and I.SEVERITYLEVEL=4010"	-- Severity is HIGH-REJECT

						exec @nErrorCode=sp_executesql @sSQLString

					End

					-------------------------------------------------
					-- Now delete the draft Case from the CASES table
					-- if it has been removed from EDECASEMATCH.
					-------------------------------------------------
					If @nErrorCode=0
					Begin
						---------------------------------
						-- RFC-63684
						-- Remove the relationship in RELATEDCASE 
						-- to the Draft Case 
						---------------------------------
						Set @sSQLString="
						Delete RELATEDCASE
						from RELATEDCASE R
						join #TEMPCASEMATCH T		on (T.DRAFTCASEID=R.RELATEDCASEID)
						join #TEMPISSUE I		on (I.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
						left join EDECASEMATCH CM	on (CM.DRAFTCASEID=R.RELATEDCASEID)
						where CM.DRAFTCASEID is null
						and I.SEVERITYLEVEL=4010"	-- Severity is HIGH-REJECT

						exec @nErrorCode=sp_executesql @sSQLString
					End
					
					
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Delete CASES
						from CASES C
						join #TEMPCASEMATCH T		on (T.DRAFTCASEID=C.CASEID)
						join #TEMPISSUE I		on (I.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
						left join EDECASEMATCH CM	on (CM.DRAFTCASEID=C.CASEID)
						where CM.DRAFTCASEID is null
						and I.SEVERITYLEVEL=4010"	-- Severity is HIGH-REJECT

						exec @nErrorCode=sp_executesql @sSQLString

					End

					-------------------------------------------------
					-- For each transaction that has been rejected
					-- insert a TRANSACTIONINFO row
					-------------------------------------------------
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Insert into TRANSACTIONINFO(TRANSACTIONDATE, BATCHNO,TRANSACTIONIDENTIFIER, TRANSACTIONMESSAGENO,TRANSACTIONREASONNO) 
						select getdate(),@pnBatchNo,T.TRANSACTIONIDENTIFIER,4,@nReasonNo
						From #TEMPCASEMATCH T
						join #TEMPISSUE I	on (I.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
						where I.SEVERITYLEVEL=4010"
						
						exec @nErrorCode=sp_executesql @sSQLString,
								N'@pnBatchNo	int,
								  @nReasonNo	int',
								  @pnBatchNo=@pnBatchNo,
								  @nReasonNo=@nReasonNo
					End

					-----------------------------------
					-- Commit transaction if successful
					-----------------------------------
					If @@TranCount > @nTranCountStart
					Begin
						If @nErrorCode = 0
							COMMIT TRANSACTION
						Else
							ROLLBACK TRANSACTION
					End
		
					-- Terminate the WHILE loop
					Set @nRetry=-1
				END TRY

				---------------------------------
				-- D E A D L O C K   V I C T I M   
				--       P R O C E S S I N G
				---------------------------------
				BEGIN CATCH
					------------------------------------------
					-- If the process has been made the victim
					-- of a deadlock (error 1205), then allow 
					-- another attempt to apply the updates 
					-- to the database up to a retry limit.
					------------------------------------------
					If ERROR_NUMBER()=1205
						Set @nRetry=@nRetry-1
					Else
						Set @nRetry=-1
						
					-- Wait 1 second before attempting to
					-- retry the update.
					If @nRetry>0
						WAITFOR DELAY '00:00:01'
					Else
						Set @nErrorCode=ERROR_NUMBER()
						
					If XACT_STATE()<>0
						Rollback Transaction
					
					If @nRetry<1
					Begin
						-- Get error details to propagate to the caller
						Select 	@sErrorMessage = 'Error:' + cast(ERROR_NUMBER() as nvarchar) + ' - ' + ERROR_MESSAGE(),
							@nErrorSeverity = ERROR_SEVERITY(),
							@nErrorState    = ERROR_STATE(),
							@nErrorCode     = ERROR_NUMBER()

						-- Use RAISERROR inside the CATCH block to return error
						-- information about the original error that caused
						-- execution to jump to the CATCH block.
						RAISERROR ( @sErrorMessage,	-- Message text.
							    @nErrorSeverity,	-- Severity.
							    @nErrorState	-- State.
							   )
					End
				END CATCH
			End -- While loop

			-------------------------------------
			-- Delete all of the temporary Issues
			-------------------------------------
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Delete from #TEMPISSUE"
		
				exec @nErrorCode=sp_executesql @sSQLString
			End

			-----------------------------------------------------
			-- Remove any transactions that have been marked as
			-- Operator Review or the draft case has been removed
			-----------------------------------------------------
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Delete #TEMPCASEMATCH 
				from #TEMPCASEMATCH T
				join EDETRANSACTIONBODY B on (B.BATCHNO=@pnBatchNo
							  and B.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
				left join CASES C	  on (C.CASEID=T.DRAFTCASEID)
				where B.TRANSSTATUSCODE=3460 -- Operator Review
				or C.CASEID is null"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int',
							  @pnBatchNo=@pnBatchNo
			End
		End  -- Mandatory Rules database update
		--=======================================================================================
		-- NEW CASE RULES PROCESSING
		--=======================================================================================

		---------------------------------------------------
		-- In order to efficiently process the draft Cases,
		-- we will loop through each different New Case
		-- Rule and process all the draft Cases that share
		-- the same rule.
		-- NOTE:
		-- The Cases that require operator review or have
		-- failed the mandatory rules with a High Severity
		-- have already been removed.
		--
		-- NEWCASERULE will only exists for those Cases
		-- where MATCHLEVEL=3252 
		-- No match will result in a new case being created
		---------------------------------------------------
		If @nErrorCode=0
		Begin
			Set @nRuleNo=null

			-- Get the first New Case rule

			Set @sSQLString="
			Select @nRuleNo=min(NEWCASERULE)
			FROM #TEMPCASEMATCH
			WHERE NEWCASERULE is not null"

			exec @nErrorCode=sp_executesql @sSQLString,
						N'@nRuleNo	int	OUTPUT',
						  @nRuleNo=@nRuleNo	OUTPUT
		End

		Set @nNewCaseCount=0

		While @nRuleNo is not null
		and @nErrorCode=0
		Begin
			Set @nNewCaseCount=@nNewCaseCount+1
			---------------------------------------------------------------------------------
			-- Action  Description
			-- ------  ----------------------------------------------------------------------
			--   0	   A live Case may not be created.
			--	   Delete the draft Case and create issue -30
			---------------------------------------------------------------------------------
			--   1	   If no high or medium issues raised and no transaction comments exist
			--	   then the live Case may be automatically created.
			--	   Specific fields need to be checked for operator review.
			---------------------------------------------------------------------------------
			--   2     A live case may be created however it will require operator review.
			--	   Change the transaction status to Operator Review.
			---------------------------------------------------------------------------------


			--------------------------------------------------
			-- Check to see if the rule will block creation of
			-- new Cases and raise IssueId -30
			-- This is where WHOLECASE = 0 which means the 
			-- rule applies to the entire Case (not just 
			-- individual columns).
			--------------------------------------------------
			Set @sSQLString="
			Insert into #TEMPISSUE(TRANSACTIONIDENTIFIER,DRAFTCASEID,ISSUEID,SEVERITYLEVEL)
			Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID,
				S.ISSUEID,S.SEVERITYLEVEL
			From #TEMPCASEMATCH T
			join EDERULECASE R	on (R.CRITERIANO=T.NEWCASERULE)
			join EDESTANDARDISSUE S on (S.ISSUEID=-30)
			Where T.NEWCASERULE=@nRuleNo
			and R.WHOLECASE=0"	-- entire case may not be updated automatically

			exec @nErrorCode=sp_executesql @sSQLString,
						N'@nRuleNo	int',
						  @nRuleNo=@nRuleNo

			If @nErrorCode=0
			Begin
				--------------------------------------------------
				-- Check to see if the rule will require operator
				-- review of the new Cases if the Case has not
				-- already rejected
				-- This is where WHOLECASE = 2
				--
				-- A row inserted into #TEMPISSUE with no ISSUEID
				-- will be used to indicate that the Case requires
				-- operator review.
				--------------------------------------------------
				Set @sSQLString="
				Insert into #TEMPISSUE(TRANSACTIONIDENTIFIER,DRAFTCASEID)
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID
				From #TEMPCASEMATCH T
				join EDERULECASE R	on (R.CRITERIANO=T.NEWCASERULE)
				left join #TEMPISSUE TI	on (TI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
							and TI.DRAFTCASEID=T.DRAFTCASEID
							and TI.ISSUEID=-30)
				Where T.NEWCASERULE=@nRuleNo
				and R.WHOLECASE=2
				and TI.ISSUEID is null"  -- Case has not already been rejected
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@nRuleNo	int',
							  @nRuleNo=@nRuleNo
			End

			--------------------------------------------------
			-- Check the rules against each column
			-- to see if Operator Review is required
			-- when data exists in the column.
			-- These rules will have WHOLECASE=1
			--
			-- A row inserted into #TEMPISSUE with no ISSUEID
			-- will be used to indicate that the Case requires
			-- operator review.
			--------------------------------------------------
			If @nErrorCode=0
			Begin
				------------------------
				-- CASES and PROPERTY --
				------------------------
				Set @sSQLString="
				Insert into #TEMPISSUE(TRANSACTIONIDENTIFIER,DRAFTCASEID)
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID
				From #TEMPCASEMATCH T
				join CASES C		on (C.CASEID=T.DRAFTCASEID)
				join EDERULECASE R	on (R.CRITERIANO=T.NEWCASERULE
							and R.CASETYPE=1
							and R.WHOLECASE=1)
				left join #TEMPISSUE TI	on (TI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
							and TI.DRAFTCASEID=T.DRAFTCASEID)
				Where T.NEWCASERULE=@nRuleNo
				and C.CASETYPE is not null
				and TI.DRAFTCASEID is null
				UNION
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID
				From #TEMPCASEMATCH T
				join CASES C		on (C.CASEID=T.DRAFTCASEID)
				join EDERULECASE R	on (R.CRITERIANO=T.NEWCASERULE
							and R.PROPERTYTYPE=1
							and R.WHOLECASE=1)
				left join #TEMPISSUE TI	on (TI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
							and TI.DRAFTCASEID=T.DRAFTCASEID)
				Where T.NEWCASERULE=@nRuleNo
				and C.PROPERTYTYPE is not null
				and TI.DRAFTCASEID is null
				UNION
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID
				From #TEMPCASEMATCH T
				join CASES C		on (C.CASEID=T.DRAFTCASEID)
				join EDERULECASE R	on (R.CRITERIANO=T.NEWCASERULE
							and R.COUNTRY=1
							and R.WHOLECASE=1)
				left join #TEMPISSUE TI	on (TI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
							and TI.DRAFTCASEID=T.DRAFTCASEID)
				Where T.NEWCASERULE=@nRuleNo
				and C.COUNTRYCODE is not null
				and TI.DRAFTCASEID is null
				UNION
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID
				From #TEMPCASEMATCH T
				join CASES C		on (C.CASEID=T.DRAFTCASEID)
				join EDERULECASE R	on (R.CRITERIANO=T.NEWCASERULE
							and R.CATEGORY=1
							and R.WHOLECASE=1)
				left join #TEMPISSUE TI	on (TI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
							and TI.DRAFTCASEID=T.DRAFTCASEID)
				Where T.NEWCASERULE=@nRuleNo
				and C.CASECATEGORY is not null
				and TI.DRAFTCASEID is null
				UNION
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID
				From #TEMPCASEMATCH T
				join CASES C		on (C.CASEID=T.DRAFTCASEID)
				join EDERULECASE R	on (R.CRITERIANO=T.NEWCASERULE
							and R.SUBTYPE=1
							and R.WHOLECASE=1)
				left join #TEMPISSUE TI	on (TI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
							and TI.DRAFTCASEID=T.DRAFTCASEID)
				Where T.NEWCASERULE=@nRuleNo
				and C.SUBTYPE is not null
				and TI.DRAFTCASEID is null"
		
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@nRuleNo	int',
							  @nRuleNo=@nRuleNo
			End

			---------------------------------
			-- CASES and PROPERTY continued..
			---------------------------------
			If @nErrorCode=0
			Begin
				Set @sSQLString=
				"Insert into #TEMPISSUE(TRANSACTIONIDENTIFIER,DRAFTCASEID)"+char(10)+
				"Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID"+char(10)+
				"From #TEMPCASEMATCH T"+char(10)+
				"left join PROPERTY P	on (P.CASEID=T.DRAFTCASEID)"+char(10)+
				"join EDERULECASE R	on (R.CRITERIANO=T.NEWCASERULE"+char(10)+
				"			and R.BASIS=1"+char(10)+
				"			and R.WHOLECASE=1)"+char(10)+
				"left join #TEMPISSUE TI	on (TI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER"+char(10)+
				"			and TI.DRAFTCASEID=T.DRAFTCASEID)"+char(10)+
				"Where T.NEWCASERULE=@nRuleNo"+char(10)+
				"and P.BASIS is not null"+char(10)+
				"and TI.DRAFTCASEID is null"+char(10)+
				"UNION"+char(10)+
				"Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID"+char(10)+
				"From #TEMPCASEMATCH T"+char(10)+
				"join CASES C		on (C.CASEID=T.DRAFTCASEID)"+char(10)+
				"join EDERULECASE R	on (R.CRITERIANO=T.NEWCASERULE"+char(10)+
				"			and R.ENTITYSIZE=1"+char(10)+
				"			and R.WHOLECASE=1)"+char(10)+
				"left join #TEMPISSUE TI	on (TI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER"+char(10)+
				"			and TI.DRAFTCASEID=T.DRAFTCASEID)"+char(10)+
				"Where T.NEWCASERULE=@nRuleNo"+char(10)+
				"and C.ENTITYSIZE is not null"+char(10)+
				"and TI.DRAFTCASEID is null"+char(10)+
				"UNION"+char(10)+
				"Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID"+char(10)+
				"From #TEMPCASEMATCH T"+char(10)+
				"join CASES C		on (C.CASEID=T.DRAFTCASEID)"+char(10)+
				"join EDERULECASE R	on (R.CRITERIANO=T.NEWCASERULE"+char(10)+
				"			and R.TYPEOFMARK=1"+char(10)+
				"			and R.WHOLECASE=1)"+char(10)+
				"left join #TEMPISSUE TI	on (TI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER"+char(10)+
				"			and TI.DRAFTCASEID=T.DRAFTCASEID)"+char(10)+
				"Where T.NEWCASERULE=@nRuleNo"+char(10)+
				"and C.TYPEOFMARK is not null"+char(10)+
				"and TI.DRAFTCASEID is null"+char(10)+
				"UNION"+char(10)+
				"Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID"+char(10)+
				"From #TEMPCASEMATCH T"+char(10)+
				"left join PROPERTY P	on (P.CASEID=T.DRAFTCASEID)"+char(10)+
				"join EDERULECASE R	on (R.CRITERIANO=T.NEWCASERULE"+char(10)+
				"			and R.NUMBEROFCLAIMS=1"+char(10)+
				"			and R.WHOLECASE=1)"+char(10)+
				"left join #TEMPISSUE TI	on (TI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER"+char(10)+
				"			and TI.DRAFTCASEID=T.DRAFTCASEID)"+char(10)+
				"Where T.NEWCASERULE=@nRuleNo"+char(10)+
				"and P.NOOFCLAIMS is not null"+char(10)+
				"and TI.DRAFTCASEID is null"+char(10)+
				"UNION"+char(10)+
				"Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID"+char(10)+
				"From #TEMPCASEMATCH T"+char(10)+
				"join CASES C		on (C.CASEID=T.DRAFTCASEID)"+char(10)+
				"join EDERULECASE R	on (R.CRITERIANO=T.NEWCASERULE"+char(10)+
				"			and R.NUMBEROFDESIGNS=1"+char(10)+
				"			and R.WHOLECASE=1)"+char(10)+
				"left join #TEMPISSUE TI	on (TI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER"+char(10)+
				"			and TI.DRAFTCASEID=T.DRAFTCASEID)"+char(10)+
				"Where T.NEWCASERULE=@nRuleNo"+char(10)+
				"and C.NOINSERIES is not null"+char(10)+
				"and TI.DRAFTCASEID is null"+char(10)+
				"UNION"+char(10)+
				"Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID"+char(10)+
				"From #TEMPCASEMATCH T"+char(10)+
				"join CASES C		on (C.CASEID=T.DRAFTCASEID)"+char(10)+
				"join EDERULECASE R	on (R.CRITERIANO=T.NEWCASERULE"+char(10)+
				"			and R.NUMBEROFYEARSEXT=1"+char(10)+
				"			and R.WHOLECASE=1)"+char(10)+
				"left join #TEMPISSUE TI	on (TI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER"+char(10)+
				"			and TI.DRAFTCASEID=T.DRAFTCASEID)"+char(10)+
				"Where T.NEWCASERULE=@nRuleNo"+char(10)+
				"and C.EXTENDEDRENEWALS is not null"+char(10)+
				"and TI.DRAFTCASEID is null"+char(10)+
				"UNION"+char(10)+
				"Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID"+char(10)+
				"From #TEMPCASEMATCH T"+char(10)+
				"join CASES C		on (C.CASEID=T.DRAFTCASEID)"+char(10)+
				"join EDERULECASE R	on (R.CRITERIANO=T.NEWCASERULE"+char(10)+
				"			and R.STOPPAYREASON=1"+char(10)+
				"			and R.WHOLECASE=1)"+char(10)+
				"left join #TEMPISSUE TI	on (TI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER"+char(10)+
				"			and TI.DRAFTCASEID=T.DRAFTCASEID)"+char(10)+
				"Where T.NEWCASERULE=@nRuleNo"+char(10)+
				"and C.STOPPAYREASON is not null"+char(10)+
				"and TI.DRAFTCASEID is null"+char(10)+
				"UNION"+char(10)+
				"Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID"+char(10)+
				"From #TEMPCASEMATCH T"+char(10)+
				"join CASES C		on (C.CASEID=T.DRAFTCASEID)"+char(10)+
				"join EDERULECASE R	on (R.CRITERIANO=T.NEWCASERULE"+char(10)+
				"			and R.SHORTTITLE=1"+char(10)+
				"			and R.WHOLECASE=1)"+char(10)+
				"left join #TEMPISSUE TI	on (TI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER"+char(10)+
				"			and TI.DRAFTCASEID=T.DRAFTCASEID)"+char(10)+
				"Where T.NEWCASERULE=@nRuleNo"+char(10)+
				"and C.TITLE is not null"+char(10)+
				"and TI.DRAFTCASEID is null"+char(10)+
				"UNION"+char(10)+
				"Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID"+char(10)+
				"From #TEMPCASEMATCH T"+char(10)+
				"join CASES C		on (C.CASEID=T.DRAFTCASEID)"+char(10)+
				"join EDERULECASE R	on (R.CRITERIANO=T.NEWCASERULE"+char(10)+
				"			and R.CLASSES=1"+char(10)+
				"			and R.WHOLECASE=1)"+char(10)+
				"left join #TEMPISSUE TI	on (TI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER"+char(10)+
				"			and TI.DRAFTCASEID=T.DRAFTCASEID)"+char(10)+
				"Where T.NEWCASERULE=@nRuleNo"+char(10)+
				"and C.LOCALCLASSES is not null"+char(10)+
				"and TI.DRAFTCASEID is null"+char(10)+
				"UNION"+char(10)+
				"Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID"+char(10)+
				"From #TEMPCASEMATCH T"+char(10)+
				"join EDERULECASE R	on (R.CRITERIANO=T.NEWCASERULE"+char(10)+
				"			and R.DESIGNATEDCOUNTRIES=1"+char(10)+
				"			and R.WHOLECASE=1)"+char(10)+
				"join RELATEDCASE C	on (C.CASEID=T.DRAFTCASEID"+char(10)+
				"			and C.RELATIONSHIP='DC1'"+char(10)+
				"			and C.COUNTRYCODE is not null)"+char(10)+
				"left join #TEMPISSUE TI	on (TI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER"+char(10)+
				"			and TI.DRAFTCASEID=T.DRAFTCASEID)"+char(10)+
				"Where T.NEWCASERULE=@nRuleNo"+char(10)+
				"and TI.DRAFTCASEID is null"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@nRuleNo	int',
							  @nRuleNo=@nRuleNo
			End

			--------------
			-- CASENAME --
			--------------
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Insert into #TEMPISSUE(TRANSACTIONIDENTIFIER,DRAFTCASEID)
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID
				From #TEMPCASEMATCH T
				join EDERULECASENAME R	on (R.CRITERIANO=T.NEWCASERULE
							and R.NAMENO=1)
				join CASENAME CN	on (CN.CASEID=T.DRAFTCASEID
							and CN.NAMETYPE=R.NAMETYPE
							and(CN.EXPIRYDATE is not null or CN.EXPIRYDATE>getdate()))
				left join #TEMPISSUE TI	on (TI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
							and TI.DRAFTCASEID=T.DRAFTCASEID)
				Where T.NEWCASERULE=@nRuleNo
				and CN.NAMENO is not null
				and TI.DRAFTCASEID is null
				UNION
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID
				From #TEMPCASEMATCH T
				join EDERULECASENAME R	on (R.CRITERIANO=T.NEWCASERULE
							and R.REFERENCENO=1)
				join CASENAME CN	on (CN.CASEID=T.DRAFTCASEID
							and CN.NAMETYPE=R.NAMETYPE
							and(CN.EXPIRYDATE is not null or CN.EXPIRYDATE>getdate()))
				left join #TEMPISSUE TI	on (TI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
							and TI.DRAFTCASEID=T.DRAFTCASEID)
				Where T.NEWCASERULE=@nRuleNo
				and CN.REFERENCENO is not null
				and TI.DRAFTCASEID is null
				UNION
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID
				From #TEMPCASEMATCH T
				join EDERULECASENAME R	on (R.CRITERIANO=T.NEWCASERULE
							and R.CORRESPONDNAME=1)
				join CASENAME CN	on (CN.CASEID=T.DRAFTCASEID
							and CN.NAMETYPE=R.NAMETYPE
							and(CN.EXPIRYDATE is not null or CN.EXPIRYDATE>getdate()))
				left join #TEMPISSUE TI	on (TI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
							and TI.DRAFTCASEID=T.DRAFTCASEID)
				Where T.NEWCASERULE=@nRuleNo
				and CN.CORRESPONDNAME is not null
				and TI.DRAFTCASEID is null"
		
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@nRuleNo	int',
							  @nRuleNo=@nRuleNo
			End

			---------------------
			-- OFFICIALNUMBERS --
			---------------------
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Insert into #TEMPISSUE(TRANSACTIONIDENTIFIER,DRAFTCASEID)
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID
				From #TEMPCASEMATCH T
				join EDERULEOFFICIALNUMBER R	on (R.CRITERIANO=T.NEWCASERULE
								and R.OFFICIALNUMBER=1)
				join OFFICIALNUMBERS N		on (N.CASEID=T.DRAFTCASEID
								and N.NUMBERTYPE=R.NUMBERTYPE)
				left join #TEMPISSUE TI	on (TI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
							and TI.DRAFTCASEID=T.DRAFTCASEID)
				Where T.NEWCASERULE=@nRuleNo
				and N.OFFICIALNUMBER is not null
				and TI.DRAFTCASEID is null"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@nRuleNo	int',
							  @nRuleNo=@nRuleNo
			End

			--------------
			-- CASETEXT --
			--------------
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Insert into #TEMPISSUE(TRANSACTIONIDENTIFIER,DRAFTCASEID)
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID
				From #TEMPCASEMATCH T
				join EDERULECASETEXT R	on (R.CRITERIANO=T.NEWCASERULE
							and R.TEXT=1)
				join CASETEXT CT	on (CT.CASEID=T.DRAFTCASEID
							and CT.TEXTTYPE=R.TEXTTYPE)
				left join #TEMPISSUE TI	on (TI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
							and TI.DRAFTCASEID=T.DRAFTCASEID)
				Where T.NEWCASERULE=@nRuleNo
				and(CT.SHORTTEXT is not null OR CT.TEXT is not null)
				and TI.DRAFTCASEID is null"

				exec @nErrorCode=sp_executesql @sSQLString,
							N'@nRuleNo	int',
							  @nRuleNo=@nRuleNo
			End

			---------------
			-- CASEEVENT --
			---------------
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Insert into #TEMPISSUE(TRANSACTIONIDENTIFIER,DRAFTCASEID)
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID
				From #TEMPCASEMATCH T
				join EDERULECASEEVENT R	on (R.CRITERIANO=T.NEWCASERULE
							and R.EVENTDATE=1)
				join CASEEVENT CE	on (CE.CASEID=T.DRAFTCASEID
							and CE.EVENTNO=R.EVENTNO)
				left join #TEMPISSUE TI	on (TI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
							and TI.DRAFTCASEID=T.DRAFTCASEID)
				Where T.NEWCASERULE=@nRuleNo
				and CE.EVENTDATE is not null
				and TI.DRAFTCASEID is null
				UNION
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID
				From #TEMPCASEMATCH T
				join EDERULECASEEVENT R	on (R.CRITERIANO=T.NEWCASERULE
							and R.EVENTDUEDATE=1)
				join CASEEVENT CE	on (CE.CASEID=T.DRAFTCASEID
							and CE.EVENTNO=R.EVENTNO)
				left join #TEMPISSUE TI	on (TI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
							and TI.DRAFTCASEID=T.DRAFTCASEID)
				Where T.NEWCASERULE=@nRuleNo
				and CE.EVENTDUEDATE is not null
				and TI.DRAFTCASEID is null
				UNION
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID
				From #TEMPCASEMATCH T
				join EDERULECASEEVENT R	on (R.CRITERIANO=T.NEWCASERULE
							and R.EVENTTEXT=1)
				join CASEEVENT CE	on (CE.CASEID=T.DRAFTCASEID
							and CE.EVENTNO=R.EVENTNO)
				left join #TEMPISSUE TI	on (TI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
							and TI.DRAFTCASEID=T.DRAFTCASEID)
				Where T.NEWCASERULE=@nRuleNo
				and (CE.EVENTTEXT is not null OR CE.EVENTLONGTEXT is not null)
				and TI.DRAFTCASEID is null"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@nRuleNo	int',
							  @nRuleNo=@nRuleNo
			End

			-----------------
			-- RELATEDCASE --
			-----------------
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Insert into #TEMPISSUE(TRANSACTIONIDENTIFIER,DRAFTCASEID)
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID
				From #TEMPCASEMATCH T
				join EDERULERELATEDCASE R	on (R.CRITERIANO=T.NEWCASERULE
								and R.OFFICIALNUMBER=1)
				join RELATEDCASE RE		on (RE.CASEID=T.DRAFTCASEID
								and RE.RELATIONSHIP=R.RELATIONSHIP)
				left join #TEMPISSUE TI		on (TI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
								and TI.DRAFTCASEID=T.DRAFTCASEID)
				Where T.NEWCASERULE=@nRuleNo
				and RE.OFFICIALNUMBER is not null
				and TI.DRAFTCASEID is null
				UNION
				Select 	T.TRANSACTIONIDENTIFIER,T.DRAFTCASEID
				From #TEMPCASEMATCH T
				join EDERULERELATEDCASE R	on (R.CRITERIANO=T.NEWCASERULE
								and R.PRIORITYDATE=1)
				join RELATEDCASE RE		on (RE.CASEID=T.DRAFTCASEID
								and RE.RELATIONSHIP=R.RELATIONSHIP)
				left join #TEMPISSUE TI		on (TI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
								and TI.DRAFTCASEID=T.DRAFTCASEID)
				Where T.NEWCASERULE=@nRuleNo
				and RE.PRIORITYDATE is not null
				and TI.DRAFTCASEID is null"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@nRuleNo	int',
							  @nRuleNo=@nRuleNo
			End

			-------------------------------
			-- Get the next rule to process
			-------------------------------

			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Select @nRuleNo=min(NEWCASERULE)
				FROM #TEMPCASEMATCH
				WHERE NEWCASERULE>@nRuleNo"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@nRuleNo	int	OUTPUT',
							  @nRuleNo=@nRuleNo	OUTPUT
			End

		End -- End New Case Rule Processing

		If @nErrorCode=0
		and @nNewCaseCount>0
		Begin	
			-----------------------------------------------------------------------------
			-- A separate database transaction will be used to insert the TRANSACTIONINFO
			-- row to ensure the lock on the database is kept to a minimum as this table
			-- will be used extensively by other processes.
			-----------------------------------------------------------------------------
		
			Select @nTranCountStart = @@TranCount
			BEGIN TRANSACTION
		
			-- Allocate a transaction id that can be accessed by the audit logs
			-- for inclusion.
		
			Set @sSQLString="Insert into TRANSACTIONINFO(TRANSACTIONDATE, BATCHNO,TRANSACTIONMESSAGENO,TRANSACTIONREASONNO) values(getdate(),@pnBatchNo,1,@nReasonNo)
					Set @nTransNo=SCOPE_IDENTITY()"
			
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int,
							  @nReasonNo	int,
							  @nTransNo	int	OUTPUT',
							  @pnBatchNo=@pnBatchNo,
							  @nReasonNo=@nReasonNo,
							  @nTransNo=@nTransNo	OUTPUT
		
			--------------------------------------------------------------
			-- Load a common area accessible from the database server with
			-- the TransactionNo just generated and other details.
			-- This will be used by the audit logs.
			--------------------------------------------------------------
		
			set @bHexNumber=substring(cast(isnull(@pnUserIdentityId,'') as varbinary),1,4) + 
					substring(cast(isnull(@nTransNo,'') as varbinary),1,4)+ 
					substring(cast(isnull(@pnBatchNo,'') as varbinary),1,4) +
					substring(cast(isnull(@nOfficeID,'') as varbinary),1,4) +
					substring(cast(isnull(@nLogMinutes,'') as varbinary),1,4)
			SET CONTEXT_INFO @bHexNumber
		
			-- Commit or Rollback the transaction
			
			If @@TranCount > @nTranCountStart
			Begin
				If @nErrorCode = 0
					COMMIT TRANSACTION
				Else
					ROLLBACK TRANSACTION
			End
		End

		------------------------------------
		-- APPLY NEW CASE RULES TO DATABASE
		------------------------------------

		If @nErrorCode=0
		and @nNewCaseCount>0
		Begin
			Set @nRetry=3
			While @nRetry>0
			and @nErrorCode=0
			Begin
				BEGIN TRY

					-- Start a new transaction
					Set @nTranCountStart = @@TranCount
					BEGIN TRANSACTION
				
					--------------------------------------
					-- SEVERITY CHECK OF THE ISSUES RAISED
					--------------------------------------
				
					-- Delete Draft Cases where the Severity is HIGH
					Set @sSQLString="
					Delete EDECASEMATCH
					from EDECASEMATCH CM
					join #TEMPCASEMATCH T	on (T.DRAFTCASEID=CM.DRAFTCASEID)
					join #TEMPISSUE I	on (I.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
					where CM.LIVECASEID is null
					and I.SEVERITYLEVEL=4010"	-- Severity is HIGH-REJECT

					exec @nErrorCode=sp_executesql @sSQLString

					-------------------------------------------------
					-- Delete unprocessed Policing requests against
					-- the POLICING table if the Case has been
					-- removed from EDECASEMATCH.
					-------------------------------------------------

					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Delete POLICING
						from POLICING P
						join #TEMPCASEMATCH T		on (T.DRAFTCASEID=P.CASEID)
						join #TEMPISSUE I		on (I.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
						left join EDECASEMATCH CM	on (CM.DRAFTCASEID=P.CASEID)
						where CM.DRAFTCASEID is null
						and I.SEVERITYLEVEL=4010"	-- Severity is HIGH-REJECT

						exec @nErrorCode=sp_executesql @sSQLString

					End

					If @nErrorCode=0
					Begin
						---------------------------------
						-- RFC-63684
						-- Remove the relationship in RELATEDCASE 
						-- to the Draft Case 
						---------------------------------
						Set @sSQLString="
						Delete RELATEDCASE
						from RELATEDCASE R
						join #TEMPCASEMATCH T		on (T.DRAFTCASEID=R.RELATEDCASEID)
						join #TEMPISSUE I		on (I.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
						left join EDECASEMATCH CM	on (CM.DRAFTCASEID=R.RELATEDCASEID)
						where CM.DRAFTCASEID is null
						and I.SEVERITYLEVEL=4010"	-- Severity is HIGH-REJECT
					
						exec @nErrorCode=sp_executesql @sSQLString
					End
					
					
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Delete CASES
						from CASES C
						join #TEMPCASEMATCH T		on (T.DRAFTCASEID=C.CASEID)
						join #TEMPISSUE I		on (I.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
						left join EDECASEMATCH CM	on (CM.DRAFTCASEID=C.CASEID)
						where CM.DRAFTCASEID is null
						and I.SEVERITYLEVEL=4010"	-- Severity is HIGH-REJECT

						exec @nErrorCode=sp_executesql @sSQLString

					End

					------------------------------------
					-- Now insert the outstanding issues
					-- to indicate a live case could not
					-- be created.
					------------------------------------
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, CASEID, DATECREATED)
						Select distinct T.ISSUEID, @pnBatchNo, T.TRANSACTIONIDENTIFIER, NULL, getdate()
						from #TEMPISSUE T
						left join EDEOUTSTANDINGISSUES I on (I.ISSUEID=T.ISSUEID
										 and I.BATCHNO=@pnBatchNo
										 and I.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
						where I.ISSUEID is null  -- do not insert a duplicate
						and T.ISSUEID=-30"
				
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@pnBatchNo	int',
									  @pnBatchNo=@pnBatchNo
					End

					-------------------------------------------------
					-- For each new case transaction that is being
					-- rejected, insert a TRANSACTIONINFO row.
					-------------------------------------------------
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Insert into TRANSACTIONINFO(TRANSACTIONDATE, BATCHNO,TRANSACTIONIDENTIFIER, TRANSACTIONMESSAGENO, TRANSACTIONREASONNO) 
						select getdate(),@pnBatchNo,B.TRANSACTIONIDENTIFIER,4,@nReasonNo
						from EDETRANSACTIONBODY B
						join #TEMPCASEMATCH T	on (T.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER)
						join (	select distinct TI.TRANSACTIONIDENTIFIER
							from #TEMPISSUE TI
							where TI.SEVERITYLEVEL=4010) I
									on (I.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
						where B.BATCHNO=@pnBatchNo
						and B.TRANSSTATUSCODE=3450	-- Ready for Case Update
						and T.MATCHLEVEL=3252		-- New case"
						
						exec @nErrorCode=sp_executesql @sSQLString,
								N'@pnBatchNo	int,
								  @nReasonNo	int',
								  @pnBatchNo=@pnBatchNo,
								  @nReasonNo=@nReasonNo
					End

					-------------------------------------------
					-- Update the Transaction Status as follows
					-- Severity	Transaction Status
					-- --------     ---------------------------
					-- HIGH		3480 (processed)
					-- MEDIUM	3460 (operator review)
					--		3460 (operator review) if Transaction Comment from Sender
					--		3460 (operator review) if Message Text from Sender
					--		3460 (operator review) if TEMPISSUE with no IssueId
					-------------------------------------------------------------------------
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Update EDETRANSACTIONBODY
						Set TRANSSTATUSCODE=CASE(CAST(LEFT(SI.DEFAULTNARRATIVE,11) as int))  -- check the Severity Level
									WHEN(4010) THEN 3480	-- HIGH   becomes Processed
									WHEN(4011) THEN 3460	-- MEDIUM becomes Operator Review
									ELSE CASE WHEN(CD.TRANSACTIONCOMMENT is not NULL)
							   				THEN 3460	-- Force Operator Review
										  WHEN(MT.TRANSACTIONMESSAGETEXT is not null)
											THEN 3460	-- Force Operator Review
										  WHEN(TI.TRANSACTIONIDENTIFIER is not null)
											THEN 3460	-- Force Operator Review
							   				ELSE B.TRANSSTATUSCODE
									     END
								    END,
						    TRANSNARRATIVECODE=CASE WHEN(convert(int,SUBSTRING(SI.DEFAULTNARRATIVE,12,11))<>0)
										THEN convert(int,SUBSTRING(SI.DEFAULTNARRATIVE,12,11))
										ELSE B.TRANSNARRATIVECODE
									END
						from EDETRANSACTIONBODY B
						join #TEMPCASEMATCH T	on (T.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER)
						left join (	select	O.BATCHNO, 
									O.TRANSACTIONIDENTIFIER, 
									-- the highest Severity has the lowest SeverityLevel
									min(left(replicate('0', 11-len(S.SEVERITYLEVEL))   +convert(CHAR(11), S.SEVERITYLEVEL)   ,11)+	
									    CASE WHEN(S.DEFAULTNARRATIVE<0) THEN '-' ELSE '0' END + RIGHT('0000000000'+replace(cast(S.DEFAULTNARRATIVE as nvarchar),'-',''),10)	  -- NOTE: DEFAULTNARRATIVE can be a negative number
									   ) as DEFAULTNARRATIVE
								from EDEOUTSTANDINGISSUES O
								join EDESTANDARDISSUE S	on (S.ISSUEID=O.ISSUEID)
								where S.SEVERITYLEVEL in (4010,4011)
								group by O.BATCHNO, O.TRANSACTIONIDENTIFIER) SI
									on (SI.BATCHNO=B.BATCHNO
									and SI.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER)
						left join (	select distinct TRANSACTIONIDENTIFIER
								from #TEMPISSUE
								where ISSUEID is null) TI
									on (TI.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER)
						left join EDETRANSACTIONCONTENTDETAILS CD
									on (CD.BATCHNO=B.BATCHNO
									and CD.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER
									and CD.TRANSACTIONCOMMENT is not null)
						left join EDETRANSACTIONMESSAGEDETAILS MT
									on (MT.BATCHNO=B.BATCHNO
									and MT.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER
									and MT.TRANSACTIONMESSAGETEXT is not null)
						Where B.BATCHNO=@pnBatchNo
						and B.TRANSSTATUSCODE=3450 -- Ready for Case Update
						and T.MATCHLEVEL=3252	   -- New Case
						and (SI.DEFAULTNARRATIVE       is not null
						 or  MT.TRANSACTIONMESSAGETEXT is not null
						 or  CD.TRANSACTIONCOMMENT     is not null
						 or  TI.TRANSACTIONIDENTIFIER  is not null)"

						exec @nErrorCode=sp_executesql @sSQLString,
										N'@pnBatchNo	int',
										  @pnBatchNo=@pnBatchNo

					End

					-- Delete all of the temporary Issues
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Delete from #TEMPISSUE"
				
						exec @nErrorCode=sp_executesql @sSQLString
					End

					-- Remove any transactions that have been marked
					-- as Operator Review or the draft case removed

					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Delete #TEMPCASEMATCH 
						from #TEMPCASEMATCH T
						join EDETRANSACTIONBODY B on (B.BATCHNO=@pnBatchNo
									  and B.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
						left join CASES C	  on (C.CASEID=T.DRAFTCASEID)
						where B.TRANSSTATUSCODE=3460
						or C.CASEID is null"
				
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@pnBatchNo	int',
									  @pnBatchNo=@pnBatchNo
					End

					-- Commit transaction if successful
					If @@TranCount > @nTranCountStart
					Begin
						If @nErrorCode = 0
							COMMIT TRANSACTION
						Else
							ROLLBACK TRANSACTION
					End
		
					-- Terminate the WHILE loop
					Set @nRetry=-1
				END TRY

				---------------------------------
				-- D E A D L O C K   V I C T I M   
				--       P R O C E S S I N G
				---------------------------------
				BEGIN CATCH
					------------------------------------------
					-- If the process has been made the victim
					-- of a deadlock (error 1205), then allow 
					-- another attempt to apply the updates 
					-- to the database up to a retry limit.
					------------------------------------------
					If ERROR_NUMBER()=1205
						Set @nRetry=@nRetry-1
					Else
						Set @nRetry=-1
						
					-- Wait 1 second before attempting to
					-- retry the update.
					If @nRetry>0
						WAITFOR DELAY '00:00:01'
					Else
						Set @nErrorCode=ERROR_NUMBER()
						
					If XACT_STATE()<>0
						Rollback Transaction
					
					If @nRetry<1
					Begin
						-- Get error details to propagate to the caller
						Select 	@sErrorMessage = 'Error:' + cast(ERROR_NUMBER() as nvarchar) + ' - ' + ERROR_MESSAGE(),
							@nErrorSeverity = ERROR_SEVERITY(),
							@nErrorState    = ERROR_STATE(),
							@nErrorCode     = ERROR_NUMBER()

						-- Use RAISERROR inside the CATCH block to return error
						-- information about the original error that caused
						-- execution to jump to the CATCH block.
						RAISERROR ( @sErrorMessage,	-- Message text.
							    @nErrorSeverity,	-- Severity.
							    @nErrorState	-- State.
							   )
					End
				END CATCH
			End -- While loop

			--------------------------------------------------
			-- Convert DRAFT Cases to LIVE Case
			--
			-- Convert those draft Cases that have a status
			-- marked as "Ready for Update"
			--------------------------------------------------
			--
			-- 1. Change CaseType to the Actual Live Case Type
			--
			-- 1a.Update any CaseEvents associates with 
			--    the related cases.
			--
			-- 1b.Update or insert CaseEvents associated
			--    with a particular Stop Pay Reason.
			--
			-- 1c.Update and RELATEDCASE rows that can now
			--    be resolved to point to an actual Case.
			--
			-- 2. Default Case Names as per inheritance rules
			--
			-- 3. Insert Events associated with Name changes
			--    (performed within Global Name Changes)
			--
			-- 4. Policing recalculation of all open Actions.
			--
			-- 5. Set Transaction Message to "New Case"
			--
			-- 6. Set Transaction narrative from any issues.
			--
			-- 7. Set Transaction status to "Processed"
			--------------------------------------------------

			Set @nRetry=3
			While @nRetry>0
			and @nErrorCode=0
			Begin
				BEGIN TRY
					-- Start a new transaction
					Set @nTranCountStart = @@TranCount
					BEGIN TRANSACTION

					--------------------------------------------------
					-- 0. Load the Cases that will require keywords
					--------------------------------------------------
					Set @sSQLString="
					Insert into #TEMPCASES(CASEID)
					Select distinct C.CASEID
					From CASES C
					join CASETYPE CT	  on (CT.CASETYPE=C.CASETYPE)
					join #TEMPCASEMATCH T	  on (T.DRAFTCASEID=C.CASEID)
					join EDETRANSACTIONBODY B on (B.BATCHNO=@pnBatchNo
								  and B.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
					Where T.MATCHLEVEL=3252		-- New case
					and CT.CASETYPE<>CT.ACTUALCASETYPE
					and B.TRANSSTATUSCODE=3450	-- Ready to Update"

					exec @nErrorCode=sp_executesql @sSQLString,
									N'@pnBatchNo	int',
									  @pnBatchNo=@pnBatchNo

					If @nErrorCode=0
						Exec @nErrorCode=dbo.cs_InsertKeyWordsFromTitle 
									@pbCaseFromTempTable=1

					If @nErrorCode=0
					Begin
						--------------------------------------------------
						-- 1. Change CaseType to the Actual Live Case Type
						--------------------------------------------------
						Set @sSQLString="
						Update CASES
						Set CASETYPE=CT.ACTUALCASETYPE
						From CASES C
						join CASETYPE CT	  on (CT.CASETYPE=C.CASETYPE)
						join #TEMPCASEMATCH T	  on (T.DRAFTCASEID=C.CASEID)
						join EDETRANSACTIONBODY B on (B.BATCHNO=@pnBatchNo
									  and B.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
						Where T.MATCHLEVEL=3252		-- New case
						and CT.CASETYPE<>CT.ACTUALCASETYPE
						and B.TRANSSTATUSCODE=3450	-- Ready to Update"

						exec @nErrorCode=sp_executesql @sSQLString,
										N'@pnBatchNo	int',
										  @pnBatchNo=@pnBatchNo

					End

					If @nErrorCode=0
					Begin
						---------------------------------------------
						-- 1a.	Changes to RelatedCases may result
						-- 	in new or modified data on CASEEVENT.
						---------------------------------------------
						Set @sSQLString="
						Update CASEEVENT
						Set EVENTDATE=RC.PRIORITYDATE,
						    OCCURREDFLAG=1
						From #TEMPCASEMATCH T
						join EDETRANSACTIONBODY B on (B.BATCHNO=@pnBatchNo
									  and B.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
						join CASEEVENT CE	on (CE.CASEID=T.LIVECASEID
									and CE.CYCLE=1)
						join CASERELATION CR	on (CR.EVENTNO=CE.EVENTNO)
						join (	select CASEID, RELATIONSHIP, min(PRIORITYDATE) as PRIORITYDATE
							from RELATEDCASE
							where PRIORITYDATE is not null
							group by CASEID, RELATIONSHIP) RC
									on (RC.CASEID=CE.CASEID
									and RC.RELATIONSHIP=CR.RELATIONSHIP)
						Where T.MATCHLEVEL=3252		-- New case
						and B.TRANSSTATUSCODE=3450	-- Ready to Update
						and CR.FROMEVENTNO is not null
						and (CE.EVENTDATE is null or CE.EVENTDATE>RC.PRIORITYDATE)"

						Exec @nErrorCode=sp_executesql @sSQLString,
									N'@pnBatchNo		int',
									  @pnBatchNo=@pnBatchNo
					End

					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Insert into CASEEVENT(CASEID,EVENTNO,CYCLE,EVENTDATE,OCCURREDFLAG)
						Select distinct T.LIVECASEID,CR.EVENTNO,1,RC.PRIORITYDATE,1
						From #TEMPCASEMATCH T
						join EDETRANSACTIONBODY B on (B.BATCHNO=@pnBatchNo
									  and B.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
						join CASERELATION CR	  on (CR.EVENTNO is not null)
						join (	select CASEID, RELATIONSHIP, min(PRIORITYDATE) as PRIORITYDATE
							from RELATEDCASE
							where PRIORITYDATE is not null
							group by CASEID, RELATIONSHIP) RC
									on (RC.CASEID=T.LIVECASEID
									and RC.RELATIONSHIP=CR.RELATIONSHIP)
						left join CASEEVENT CE	on (CE.CASEID=T.LIVECASEID
									and CE.EVENTNO=CR.EVENTNO
									and CE.CYCLE=1)
						Where T.MATCHLEVEL=3252		-- New case
						and B.TRANSSTATUSCODE=3450	-- Ready to Update
						and CR.FROMEVENTNO is not null
						and CE.CASEID is null"

						Exec @nErrorCode=sp_executesql @sSQLString,
									N'@pnBatchNo		int',
									  @pnBatchNo=@pnBatchNo
					End

					If @nErrorCode=0
					Begin

						------------------------------------------------------------------------
						-- 1b.	If a Stop Pay Reason has been provided then also update/insert a 
						-- 	specific Event that has been mapped to the Stop Reason.
						-- 	This is determined by concatenating the Stop Reason to a Site
						-- 	Control value.  
						-------------------------------------------------------------------------

						---------------------------------
						-- Store the Stop Pay Date in a
						-- temporary table as this may
						-- be required later to determine
						-- the Transaction Narrative
						---------------------------------
						Set @sSQLString="
						Delete from #TEMPSTOPPAY

						Insert into #TEMPSTOPPAY (CASEID, EVENTNO, CYCLE, EVENTDATE, EVENTDUEDATE, OCCURREDFLAG, DATEDUESAVED, EVENTTEXT,FUTUREDATENARRATIVE, PASTDATENARRATIVE)
						Select	C.CASEID, 
							E.EVENTNO, 
							isnull(OA.CYCLE,1), 
							CASE WHEN(CE.CASEID is not null) THEN CE.EVENTDATE ELSE convert(nvarchar,getdate(),106) END, 
							CE.EVENTDUEDATE, 
							CASE WHEN(CE.EVENTDATE is not null OR CE.CASEID is null) THEN 1 ELSE 0 END,
							CE.DATEDUESAVED,
							CE.EVENTTEXT,
							T2.TABLECODE,	-- Narrative Code to use for future date
							T3.TABLECODE	-- Narrative Code if date is not in the future
						From  #TEMPCASEMATCH T
						join EDETRANSACTIONBODY B on (B.BATCHNO=@pnBatchNo
									  and B.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
						     join CASES C	 on (C.CASEID=T.LIVECASEID)
						left join CASEEVENT CE	 on (CE.CASEID=C.CASEID
									 and CE.EVENTNO=@nStopPayEvent
									 and CE.CYCLE=1)
						     join SITECONTROL S1 on (S1.CONTROLID='CPA Stop When Reason='+C.STOPPAYREASON)
						     join EVENTS E	 on (E.EVENTNO=S1.COLINTEGER)
						     --------------------------------------
						     -- Determine the cycle to use from the 
						     -- earliest open action of the Events
						     -- Controlling Action
						     --------------------------------------
						left join (	select CASEID, ACTION, min(CYCLE) as CYCLE
								from OPENACTION
								where POLICEEVENTS=1
								group by CASEID, ACTION) OA
									 on (OA.CASEID=C.CASEID
									 and OA.ACTION=E.CONTROLLINGACTION)
						left join SITECONTROL S2 on (S2.CONTROLID='CPA Narrative Future Reason='+C.STOPPAYREASON)
						left join TABLECODES  T2 on (T2.TABLECODE=S2.COLINTEGER)
						left join SITECONTROL S3 on (S3.CONTROLID='CPA Narrative When Reason='+C.STOPPAYREASON)
						left join TABLECODES  T3 on (T3.TABLECODE=S3.COLINTEGER)
						Where C.STOPPAYREASON is not null"

						Exec @nErrorCode=sp_executesql @sSQLString,
									N'@pnBatchNo		int,
									  @nStopPayEvent	int',
									  @pnBatchNo    =@pnBatchNo,
									  @nStopPayEvent=@nStopPayEvent
					End

					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Update CASEEVENT
						Set	EVENTDATE   =CE.EVENTDATE,
							EVENTDUEDATE=CE.EVENTDUEDATE, 
							OCCURREDFLAG=CASE WHEN(CE.EVENTDATE is not null) THEN 1 ELSE 0 END,
							DATEDUESAVED=CE.DATEDUESAVED,
							EVENTTEXT   =CE.EVENTTEXT
						From CASEEVENT CE1
						join #TEMPSTOPPAY CE	on (CE.CASEID =CE1.CASEID
									and CE.EVENTNO=CE1.EVENTNO
									and CE.CYCLE  =CE1.CYCLE)
						Where checksum(CE1.EVENTDATE,CE1.EVENTDUEDATE,CE1.OCCURREDFLAG,CE1.DATEDUESAVED)
						    <>checksum(CE.EVENTDATE, CE.EVENTDUEDATE, CE.OCCURREDFLAG, CE.DATEDUESAVED)
						or isnull(CE1.EVENTTEXT,'') not like isnull(CE.EVENTTEXT,'')"

						Exec @nErrorCode=sp_executesql @sSQLString
					End

					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Insert into CASEEVENT(CASEID, EVENTNO, CYCLE, EVENTDATE, EVENTDUEDATE, OCCURREDFLAG, DATEDUESAVED, EVENTTEXT)
						Select	T.CASEID, 
							T.EVENTNO, 
							T.CYCLE, 
							T.EVENTDATE,
							T.EVENTDUEDATE, 
							T.OCCURREDFLAG,
							T.DATEDUESAVED,
							T.EVENTTEXT
						From #TEMPSTOPPAY T
						left join CASEEVENT CE1	on (CE1.CASEID =T.CASEID
									and CE1.EVENTNO=T.EVENTNO
									and CE1.CYCLE  =T.CYCLE)
						Where CE1.CASEID is null"

						Exec @nErrorCode=sp_executesql @sSQLString
					End

					If @nErrorCode=0
					Begin
						------------------------------------------------------------------------
						--	SQA18403
						-- 1c.	Now that this case has been turned into a live case, change any
						-- 	Related Cases that match on Official Number and Country so that
						-- 	they now point to this new live Case.
						-------------------------------------------------------------------------

						
						---------------------------------------------------------
						-- First save the RELATEDCASE rows to be updated so
						-- we can check if a Reciprocal Relationship is required.
						---------------------------------------------------------
						Set @sSQLString="
						Insert into dbo.#TEMPCHECKRECIPROCAL (CASEID, RELATIONSHIPNO, RELATIONSHIP, RELATEDCASEID)
						Select RC.CASEID, RC.RELATIONSHIPNO, RC.RELATIONSHIP, C.CASEID
						From CASES C
						join CASETYPE CT	  on (CT.CASETYPE=C.CASETYPE)
						join #TEMPCASEMATCH T	  on (T.DRAFTCASEID=C.CASEID)
						join EDETRANSACTIONBODY B on (B.BATCHNO=@pnBatchNo
									  and B.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
						join OFFICIALNUMBERS O	  on (O.CASEID=C.CASEID)
						join NUMBERTYPES NT	  on (NT.NUMBERTYPE=O.NUMBERTYPE
									  and NT.ISSUEDBYIPOFFICE=1)
						join RELATEDCASE RC	  on (RC.OFFICIALNUMBER=O.OFFICIALNUMBER
									  and RC.COUNTRYCODE   =C.COUNTRYCODE)
						join CASES C1		  on (C1.CASEID      =RC.CASEID
									  and C1.CASETYPE    =C.CASETYPE
									  and C1.PROPERTYTYPE=C.PROPERTYTYPE)
						join CASERELATION CR	  on (CR.RELATIONSHIP  =RC.RELATIONSHIP)
						left join CASEEVENT CE	  on (CE.CASEID   =C.CASEID
									  and CE.EVENTNO  =CR.FROMEVENTNO
									  and CE.CYCLE    =1)
						Where T.MATCHLEVEL=3252		-- New case
						and CT.ACTUALCASETYPE is null	-- indicates this is a live case
						and B.TRANSSTATUSCODE=3450	-- Ready to Update
						and (CE.EVENTDATE=RC.PRIORITYDATE OR RC.PRIORITYDATE is null OR CR.FROMEVENTNO is null)"

						exec @nErrorCode=sp_executesql @sSQLString,
										N'@pnBatchNo	int',
										  @pnBatchNo=@pnBatchNo

						If @nErrorCode=0
						Begin
							-----------------------------------
							-- Now reset the RELATEDCASE row to
							-- point to the newly loaded case.
							-----------------------------------
							Set @sSQLString="
							Update RC
							Set RELATEDCASEID =T.RELATEDCASEID,
							    OFFICIALNUMBER=NULL,
							    COUNTRYCODE   =NULL,
							    PRIORITYDATE  =NULL
							From dbo.#TEMPCHECKRECIPROCAL T
							join RELATEDCASE RC	  on (RC.CASEID=T.CASEID
										  and RC.RELATIONSHIPNO=T.RELATIONSHIPNO)
							Where RC.OFFICIALNUMBER is not null
							and   RC.COUNTRYCODE    is not null"

							exec @nErrorCode=sp_executesql @sSQLString
						End
					End

					If @nErrorCode=0
					Begin
						------------------------------------------------------------------------
						--	SQA18403
						-- 1c.	Now update the RelatedCase for the Case that has just been made
						-- 	into a live Case so that it points to any existing live Cases.
						-------------------------------------------------------------------------

						
						---------------------------------------------------------
						-- First save the RELATEDCASE rows to be updated so
						-- we can check if a Reciprocal Relationship is required.
						---------------------------------------------------------
						Set @sSQLString="
						Insert into dbo.#TEMPCHECKRECIPROCAL (CASEID, RELATIONSHIPNO, RELATIONSHIP, RELATEDCASEID)
						Select RC.CASEID, RC.RELATIONSHIPNO, RC.RELATIONSHIP, C1.CASEID
						From CASES C
						join CASETYPE CT	  on (CT.CASETYPE=C.CASETYPE)
						join #TEMPCASEMATCH T	  on (T.DRAFTCASEID=C.CASEID)
						join EDETRANSACTIONBODY B on (B.BATCHNO=@pnBatchNo
									  and B.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
						join RELATEDCASE RC	  on (RC.CASEID=C.CASEID
									  and RC.RELATEDCASEID is null)
						join EDEIDENTIFIERNUMBERDETAILS N
									  on (N.BATCHNO=B.BATCHNO
									  and N.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER
									  and N.IDENTIFIERNUMBERTEXT =RC.OFFICIALNUMBER
									  and N.ASSOCCASESEQ         =RC.RELATIONSHIPNO)
						join OFFICIALNUMBERS O	  on (O.OFFICIALNUMBER=RC.OFFICIALNUMBER
									  and O.NUMBERTYPE=N.IDENTIFIERNUMBERCODE_T)
						join CASES C1		  on (C1.CASEID      = O.CASEID
									  and C1.COUNTRYCODE =RC.COUNTRYCODE
									  and C1.PROPERTYTYPE= C.PROPERTYTYPE
									  and C1.CASETYPE    = C.CASETYPE)
						join CASERELATION CR	  on (CR.RELATIONSHIP  =RC.RELATIONSHIP)
						left join CASEEVENT CE	  on (CE.CASEID   =C1.CASEID
									  and CE.EVENTNO  =CR.FROMEVENTNO
									  and CE.CYCLE    =1)
						left join dbo.#TEMPCHECKRECIPROCAL TCR
									  on (TCR.CASEID=RC.CASEID
									  and TCR.RELATIONSHIPNO=RC.RELATIONSHIPNO)
						Where T.MATCHLEVEL=3252		-- New case
						and CT.ACTUALCASETYPE is null	-- indicates this is a live case
						and B.TRANSSTATUSCODE=3450	-- Ready to Update
						and (CE.EVENTDATE=RC.PRIORITYDATE OR RC.PRIORITYDATE is null OR CR.FROMEVENTNO is null)
						and TCR.CASEID is null		-- A row does not already exist in #TEMPCHECKRECIPROCAL
						--------------------------------
						-- Check that there is not an
						-- alternative Case to match on.
						--------------------------------
						and not exists
						(select 1
						 from OFFICIALNUMBERS O2
						 join CASES C2	on (C2.CASEID=O2.CASEID
								and C2.COUNTRYCODE=RC.COUNTRYCODE
								and C2.PROPERTYTYPE=C.PROPERTYTYPE
								and C2.CASETYPE    =C.CASETYPE)
						 where O2.OFFICIALNUMBER=RC.OFFICIALNUMBER
						 and   O2.NUMBERTYPE=N.IDENTIFIERNUMBERCODE_T
						 and   O2.CASEID<>O.CASEID)"

						exec @nErrorCode=sp_executesql @sSQLString,
										N'@pnBatchNo	int',
										  @pnBatchNo=@pnBatchNo
										  
						If @nErrorCode=0
						Begin
							-----------------------------------
							-- Now reset the RELATEDCASE row to
							-- point to the newly loaded case.
							-----------------------------------
							Set @sSQLString="
							Update RC
							Set RELATEDCASEID =T.RELATEDCASEID,
							    OFFICIALNUMBER=NULL,
							    COUNTRYCODE   =NULL,
							    PRIORITYDATE  =NULL
							From dbo.#TEMPCHECKRECIPROCAL T
							join RELATEDCASE RC	  on (RC.CASEID=T.CASEID
										  and RC.RELATIONSHIPNO=T.RELATIONSHIPNO)
							Where RC.OFFICIALNUMBER is not null
							and   RC.COUNTRYCODE    is not null"

							exec @nErrorCode=sp_executesql @sSQLString
						End
					End
								
					------------------------------------------------------------------
					-- DR-48058
					-- If a related case has linked to an Inprotech Case then see if
					-- a reciprocal relationship is able to be inserted to create the
					-- reverse relationship
					-- Need to consider draft cases inserted in this batch.
					------------------------------------------------------------------
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						With RecipRelationships AS
						(	Select  ROW_NUMBER() OVER(PARTITION BY coalesce(RC.RELATEDCASEID, RC.CASEID) 
										  ORDER     BY coalesce(RC.RELATEDCASEID, RC.CASEID), RC.RELATIONSHIPNO) AS RowNumber,
								RC.CASEID, 
								RC.RELATIONSHIP,
								RC.RELATEDCASEID
							From dbo.#TEMPCHECKRECIPROCAL RC
						)
						Insert into RELATEDCASE(CASEID, RELATIONSHIPNO, RELATIONSHIP, RELATEDCASEID)
						Select distinct RC.RELATEDCASEID, 
								isnull(RC2.RELATIONSHIPNO,0)+RC.RowNumber,	-- Need to increment the RELATIONSHIP number
								VR.RECIPRELATIONSHIP,				-- the Reciprocal Relationship
								RC.CASEID
						From RecipRelationships RC
						join CASES C		  on (C.CASEID=RC.CASEID)
						-------------------------------------
						-- Find the reciprocal relationship
						-- for the related case just updated
						-------------------------------------
						join VALIDRELATIONSHIPS VR on (VR.PROPERTYTYPE=C.PROPERTYTYPE
									   and VR.RELATIONSHIP=RC.RELATIONSHIP
									   and VR.COUNTRYCODE =(select min(VR1.COUNTRYCODE)
												from VALIDRELATIONSHIPS VR1
												where VR1.COUNTRYCODE in ('ZZZ',C.COUNTRYCODE)
												and   VR1.PROPERTYTYPE=C.PROPERTYTYPE) 
									  and VR.RECIPRELATIONSHIP is not null)
						left join RELATEDCASE RC1 on (RC1.CASEID       =RC.RELATEDCASEID
									  and RC1.RELATIONSHIP =VR.RECIPRELATIONSHIP
									  and RC1.RELATEDCASEID=RC.CASEID)
						----------------------------------
						-- Get the highest RELATIONSHIPNO
						-- allocated for each Relationship
						-- about to be inserted
						----------------------------------
						left join (select CASEID, max(RELATIONSHIPNO) as RELATIONSHIPNO
							   from RELATEDCASE
							   group by CASEID) RC2 on (RC2.CASEID=RC.RELATEDCASEID)
						Where RC1.CASEID is null"

						exec @nErrorCode=sp_executesql @sSQLString

					End

					If @nErrorCode=0
					Begin
						--------------------------------------------------
						-- 2. Default Case Names as per inheritance rules
						--------------------------------------------------

						-- Load the CaseName rows from the draft Case that
						-- are potential parents to other NameTypes.
						Set @sSQLString="
						insert into #TEMPCASENAME(TYPE, CASEID, NAMETYPE, NAMENO, CORRESPONDNAME, REFERENCENO, COMMENCEDATE)
						select distinct 'INSERT', CN.CASEID, CN.NAMETYPE, CN.NAMENO, CN.CORRESPONDNAME, CN.REFERENCENO, CN.COMMENCEDATE
						from #TEMPCASEMATCH T
						join EDETRANSACTIONBODY B on (B.BATCHNO=@pnBatchNo
									  and B.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
						join CASENAME CN	  on (CN.CASEID=T.DRAFTCASEID)
						where T.MATCHLEVEL=3252	   -- new case
						and B.TRANSSTATUSCODE=3450"-- Ready to update
					
						Exec @nErrorCode=sp_executesql @sSQLString,
										N'@pnBatchNo	int',
										  @pnBatchNo=@pnBatchNo

						Set @nGlobalChanges=@@RowCount

						If @nErrorCode=0
						and @nGlobalChanges>0
						Begin
							Exec @nErrorCode=ede_CaseNameGlobalUpdates
										@pnUserIdentityId	=@pnUserIdentityId,
										@pnBatchNo		=@pnBatchNo,
										@pnTransNo		=@nTransNo,
										@pbPoliceImmediately	=@pbPoliceImmediately,
										@pbUseFutureNameType	=0	-- Insert the exact NameType
						End

					End

					If @nErrorCode=0
					Begin
						--------------------------------------------------
						-- 4. Policing recalculation of open Actions.
						--------------------------------------------------
						Set @sSQLString="
						Insert into #TEMPPOLICE(CASEID,CYCLE,ACTION, TYPEOFREQUEST)
						Select OA.CASEID, OA.CYCLE, OA.ACTION,1
						From OPENACTION OA
						join #TEMPCASEMATCH T	  on (T.DRAFTCASEID=OA.CASEID)
						join CASES C		  on (C.CASEID=OA.CASEID)
						join EDETRANSACTIONBODY B on (B.BATCHNO=@pnBatchNo
									  and B.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
						Where T.MATCHLEVEL=3252		-- new case
						and B.TRANSSTATUSCODE=3450	-- ready to update
						and OA.POLICEEVENTS=1"

						Exec @nErrorCode=sp_executesql @sSQLString,
									N'@pnBatchNo	int',
									  @pnBatchNo=@pnBatchNo
						
						Set @nPolicingRows=@@Rowcount
					
						Set @nPoliceBatchNo=null

						If @nErrorCode=0
						and @pbPoliceImmediately=1
						Begin
							------------------------------------------------------
							-- Get the Batchnumber to use for Police Immediately.
							-- BatchNumber is relatively shortlived so reset it
							-- by incrementing the maximum BatchNo on the Policing
							-- table.
							------------------------------------------------------
						
							Set @sSQLString="
							Update LASTINTERNALCODE
							set INTERNALSEQUENCE=P.BATCHNO+1,
							    @nPoliceBatchNo =P.BATCHNO+1
							from LASTINTERNALCODE L
							cross join (select max(isnull(BATCHNO,0)) as BATCHNO
								    from POLICING) P
							where TABLENAME='POLICINGBATCH'"
						
							exec @nErrorCode=sp_executesql @sSQLString,
										N'@nPoliceBatchNo		int	OUTPUT',
										  @nPoliceBatchNo=@nPoliceBatchNo	OUTPUT
						
							Set @nRowCount=@@Rowcount
						
							If  @nErrorCode=0
							and @nRowCount=0
							Begin
								Set @sSQLString="
								Insert into LASTINTERNALCODE(TABLENAME, INTERNALSEQUENCE)
								values ('POLICINGBATCH', 0)"
						
								exec @nErrorCode=sp_executesql @sSQLString
								
								set @nPoliceBatchNo=0
							End
						End

						-- Now load the live Policing table from the temporary table.
						
						If  @nErrorCode=0
						and @nPolicingRows>0
						Begin
							Set @sSQLString="
							insert into POLICING(DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, ONHOLDFLAG, CASEID, CYCLE, ACTION, TYPEOFREQUEST,BATCHNO, SQLUSER, IDENTITYID)
							select getdate(), T.POLICINGSEQNO, 'EDE1-'+convert(varchar, getdate(), 121)+' '+convert(varchar,T.POLICINGSEQNO), 1, 0, T.CASEID, T.CYCLE, T.ACTION, T.TYPEOFREQUEST, @nPoliceBatchNo, SYSTEM_USER, @pnUserIdentityId
							from #TEMPPOLICE T
							left join POLICING P	on (P.CASEID=T.CASEID
										and P.ACTION=T.ACTION
										and P.CYCLE=T.CYCLE
										and P.TYPEOFREQUEST=1)
							where P.CASEID is null"
						
							Exec @nErrorCode=sp_executesql @sSQLString,
										N'@pnUserIdentityId	int,
										  @nPoliceBatchNo	int',
										  @pnUserIdentityId = @pnUserIdentityId,
										  @nPoliceBatchNo   = @nPoliceBatchNo

							Set @nPolicingRows=0

							If @nErrorCode=0
							Begin
								-- Clear out the TempPolice rows
								Set @sSQLString="Delete from #TEMPPOLICE"
								
								Exec @nErrorCode=sp_executesql @sSQLString
							End
						End
					End

					If @nErrorCode=0
					Begin
						---------------------------------------------
						-- SQA15968
						-- Transactions that are marked as ready for
						-- update are to have the EDECASEDETAILS table
						-- point to the CASEID before EDECASEMATCH 
						-- is removed
						-- Note that this update may extend beyond 
						-- the current batch as the Draft Case from
						-- an earlier batch may have been replaced by
						-- this transaction.
						---------------------------------------------
						Set @sSQLString="
						Update EDECASEDETAILS 
						Set CASEID=C.DRAFTCASEID
						from #TEMPCASEMATCH TM
						join EDECASEMATCH C		on (C.DRAFTCASEID=TM.DRAFTCASEID)
						join EDECASEDETAILS E		on (E.BATCHNO=C.BATCHNO
										and E.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
						join EDETRANSACTIONBODY T	on (T.BATCHNO=E.BATCHNO
										and T.TRANSACTIONIDENTIFIER=E.TRANSACTIONIDENTIFIER)
						Where T.TRANSSTATUSCODE=3450	-- Ready for Case Update
						and TM.MATCHLEVEL=3252		-- new case
						and isnull(E.CASEID,'')<>C.DRAFTCASEID"
				
						exec @nErrorCode=sp_executesql @sSQLString
					End

					If @nErrorCode=0
					Begin
						--------------------------------------------------
						-- SQA15968
						-- Delete EDECASEMATCH for transactions that have
						-- successfully been processed.
						-- Note that this Delete may extend beyond 
						-- the current batch as the Draft Case from
						-- an earlier batch may have been replaced by
						-- this transaction.
						--------------------------------------------------
					
						Set @sSQLString="
						Delete EDECASEMATCH
						from EDETRANSACTIONBODY B
						join #TEMPCASEMATCH T	on (T.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER)
						join EDECASEMATCH M	on (M.DRAFTCASEID=T.DRAFTCASEID)
						Where B.BATCHNO=@pnBatchNo
						and B.TRANSSTATUSCODE=3450 -- Ready for Case Update
						and T.MATCHLEVEL=3252	   -- new case"

						exec @nErrorCode=sp_executesql @sSQLString,
										N'@pnBatchNo	int',
										  @pnBatchNo=@pnBatchNo
					End

					-------------------------------------------------
					-- For each transaction that is changing to a 
					-- live case, insert a TRANSACTIONINFO row.
					-------------------------------------------------
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Insert into TRANSACTIONINFO(TRANSACTIONDATE, BATCHNO,TRANSACTIONIDENTIFIER, TRANSACTIONMESSAGENO,CASEID, TRANSACTIONREASONNO) 
						select getdate(),@pnBatchNo,B.TRANSACTIONIDENTIFIER,1,C.CASEID,@nReasonNo
						from EDETRANSACTIONBODY B
						join #TEMPCASEMATCH T	on (T.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER)
						join CASES C		on (C.CASEID=T.DRAFTCASEID)
						Where B.BATCHNO=@pnBatchNo
						and B.TRANSSTATUSCODE=3450 -- Ready for Case Update
						and T.MATCHLEVEL=3252	   -- new case"
						
						exec @nErrorCode=sp_executesql @sSQLString,
								N'@pnBatchNo	int,
								  @nReasonNo	int',
								  @pnBatchNo=@pnBatchNo,
								  @nReasonNo=@nReasonNo
					End

					-------------------------------------------------
					-- For each transaction that is changing to a 
					-- live case with a Stop Pay Event, insert a
					-- TRANSACTIONINFO row.
					-------------------------------------------------
					If @nErrorCode=0
					and @nStopPayEvent is not null
					Begin
						Set @sSQLString="
						Insert into TRANSACTIONINFO(TRANSACTIONDATE, BATCHNO,TRANSACTIONIDENTIFIER, TRANSACTIONMESSAGENO,CASEID,TRANSACTIONREASONNO) 
						select getdate(),@pnBatchNo,B.TRANSACTIONIDENTIFIER,5,C.CASEID,@nReasonNo
						from EDETRANSACTIONBODY B
						join #TEMPCASEMATCH T	on (T.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER)
						join CASES C		on (C.CASEID=T.DRAFTCASEID)
						join CASEEVENT CE	on (CE.CASEID=C.CASEID
									and CE.EVENTNO=@nStopPayEvent
									and CE.CYCLE=1)
						Where B.BATCHNO=@pnBatchNo
						and B.TRANSSTATUSCODE=3450 -- Ready for Case Update
						and CE.EVENTDATE is not null
						and T.MATCHLEVEL=3252	   -- new case"
						
						exec @nErrorCode=sp_executesql @sSQLString,
								N'@pnBatchNo		int,
								  @nStopPayEvent	int,
								  @nReasonNo		int',
								  @pnBatchNo    =@pnBatchNo,
								  @nStopPayEvent=@nStopPayEvent,
								  @nReasonNo    =@nReasonNo
					End

					-------------------------------------------------
					-- For each transaction that is changing to a 
					-- live case with a Start Pay Event, insert a
					-- TRANSACTIONINFO row.
					-------------------------------------------------
					If @nErrorCode=0
					and @nStartPayEvent is not null
					Begin
						Set @sSQLString="
						Insert into TRANSACTIONINFO(TRANSACTIONDATE, BATCHNO,TRANSACTIONIDENTIFIER, TRANSACTIONMESSAGENO,CASEID, TRANSACTIONREASONNO) 
						select getdate(),@pnBatchNo,B.TRANSACTIONIDENTIFIER,6,C.CASEID,@nReasonNo
						from EDETRANSACTIONBODY B
						join #TEMPCASEMATCH T	on (T.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER)
						join CASES C		on (C.CASEID=T.DRAFTCASEID)
						join CASEEVENT CE	on (CE.CASEID=C.CASEID
									and CE.EVENTNO=@nStartPayEvent
									and CE.CYCLE=1)
						Where B.BATCHNO=@pnBatchNo
						and B.TRANSSTATUSCODE=3450 -- Ready for Case Update
						and CE.EVENTDATE is not null
						and T.MATCHLEVEL=3252	   -- new case"
						
						exec @nErrorCode=sp_executesql @sSQLString,
								N'@pnBatchNo		int,
								  @nStartPayEvent	int,
								  @nReasonNo		int',
								  @pnBatchNo    =@pnBatchNo,
								  @nStartPayEvent=@nStartPayEvent,
								  @nReasonNo     =@nReasonNo
					End

					If @nErrorCode=0
					Begin
						--------------------------------------------------
						-- 5. Set Transaction Message to "New Case"
						-- 6. Set Transaction narrative from any issues
						--    or set to 4020 (New Case) if no issues.
						-- 7. Set Transaction status to "Processed"
						--------------------------------------------------
					
						Set @sSQLString="
						Update EDETRANSACTIONBODY
						Set TRANSSTATUSCODE=3480,	-- Processed
						    TRANSACTIONRETURNCODE='New Case',
						    TRANSNARRATIVECODE=	CASE WHEN(convert(int,SUBSTRING(SI.DEFAULTNARRATIVE,12,11))<>0)
										THEN convert(int,SUBSTRING(SI.DEFAULTNARRATIVE,12,11))
										ELSE 4020
									END
						from EDETRANSACTIONBODY B
						join #TEMPCASEMATCH T	on (T.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER)
						left join (	select	O.BATCHNO, 
									O.TRANSACTIONIDENTIFIER, 
									-- the highest Severity has the lowest SeverityLevel
									min(left(replicate('0', 11-len(S.SEVERITYLEVEL))   +convert(CHAR(11), S.SEVERITYLEVEL)   ,11)+	
									    CASE WHEN(S.DEFAULTNARRATIVE<0) THEN '-' ELSE '0' END + RIGHT('0000000000'+replace(cast(S.DEFAULTNARRATIVE as nvarchar),'-',''),10)	  -- NOTE: DEFAULTNARRATIVE can be a negative number
									   ) as DEFAULTNARRATIVE
								from EDEOUTSTANDINGISSUES O
								join EDESTANDARDISSUE S	on (S.ISSUEID=O.ISSUEID)
								where S.SEVERITYLEVEL  is not null
								group by O.BATCHNO, O.TRANSACTIONIDENTIFIER) SI
									on (SI.BATCHNO=B.BATCHNO
									and SI.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER)
						Where B.BATCHNO=@pnBatchNo
						and B.TRANSSTATUSCODE=3450 -- Ready for Case Update
						and T.MATCHLEVEL=3252	   -- new case"

						exec @nErrorCode=sp_executesql @sSQLString,
										N'@pnBatchNo	int',
										  @pnBatchNo=@pnBatchNo
					End

					-- Commit transaction if successful
					If @@TranCount > @nTranCountStart
					Begin
						If @nErrorCode = 0
							COMMIT TRANSACTION
						Else
							ROLLBACK TRANSACTION
					End
		
					-- Terminate the WHILE loop
					Set @nRetry=-1
				END TRY

				---------------------------------
				-- D E A D L O C K   V I C T I M   
				--       P R O C E S S I N G
				---------------------------------
				BEGIN CATCH
					------------------------------------------
					-- If the process has been made the victim
					-- of a deadlock (error 1205), then allow 
					-- another attempt to apply the updates 
					-- to the database up to a retry limit.
					------------------------------------------
					If ERROR_NUMBER()=1205
						Set @nRetry=@nRetry-1
					Else
						Set @nRetry=-1
						
					-- Wait 1 second before attempting to
					-- retry the update.
					If @nRetry>0
						WAITFOR DELAY '00:00:01'
					Else
						Set @nErrorCode=ERROR_NUMBER()
						
					If XACT_STATE()<>0
						Rollback Transaction
					
					If @nRetry<1
					Begin
						-- Get error details to propagate to the caller
						Select 	@sErrorMessage = 'Error:' + cast(ERROR_NUMBER() as nvarchar) + ' - ' + ERROR_MESSAGE(),
							@nErrorSeverity = ERROR_SEVERITY(),
							@nErrorState    = ERROR_STATE(),
							@nErrorCode     = ERROR_NUMBER()

						-- Use RAISERROR inside the CATCH block to return error
						-- information about the original error that caused
						-- execution to jump to the CATCH block.
						RAISERROR ( @sErrorMessage,	-- Message text.
							    @nErrorSeverity,	-- Severity.
							    @nErrorState	-- State.
							   )
					End
				END CATCH
			End -- While loop

			------------------------------------------------
			-- Police Immediately
			-- If the Police Immediately option has been
			-- selected then run Policing within its own
			-- transacation.  This is safe to do because
			-- the Policing rows have already been committed
			-- to the database so any failure will ensure
			-- that the unprocessed requests will remain.
			-- A separate transaction will reduce the chance
			-- of extended locks on the database.
			------------------------------------------------
			If  @nErrorCode=0
			and @nPolicingRows>0
			and @pbPoliceImmediately=1
			Begin
				exec @nErrorCode=dbo.ipu_Policing_async
							@pnBatchNo=@nPoliceBatchNo,
							@pnUserIdentityId=@pnUserIdentityId
		
				Set @nPolicingRows=0
			End

		End  -- New Rules database update

		--=======================================================================================
		-- AMENDED CASE RULES PROCESSING
		--=======================================================================================

		--------------------------------------------
		-- Load a temporary table with Cases that 
		-- have a difference between the draft Cases
		-- and live Cases events where the draft
		-- Case event was derived (calculated).
		-- This is used for Rule Action = 6.
		-- This avoids including the same derived
		-- table in each of the updates.
		--------------------------------------------

		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Insert into #TEMPDERIVEDEVENTCHANGED(CASEID)
			select distinct T.DRAFTCASEID
			from EVENTS E
			cross join #TEMPCASEMATCH T
			left join CASEEVENT CE1 on (CE1.CASEID =T.DRAFTCASEID
				   		and CE1.EVENTNO=E.EVENTNO)
			left join CASEEVENT CE2	on (CE2.CASEID =T.LIVECASEID
						and CE2.CYCLE  =CE1.CYCLE
						and CE2.EVENTNO=CE1.EVENTNO)
			where E.DRAFTEVENTNO is not null
			and T.AMENDCASERULE is not null
			and T.DRAFTCASEID is not null
			and T.LIVECASEID is not null
			and CHECKSUM(CE1.EVENTDATE, CE1.EVENTDUEDATE, CE1.OCCURREDFLAG)
			 <> CHECKSUM(CE2.EVENTDATE, CE2.EVENTDUEDATE, CE2.OCCURREDFLAG)"

			Exec @nErrorCode=sp_executesql @sSQLString
		End

		---------------------------------------------------
		-- In order to efficiently process the draft Cases,
		-- we will loop through each different Amend Case
		-- Rule and process all the draft Cases that share
		-- the same rule.
		---------------------------------------------------

		If @nErrorCode=0
		Begin
			Set @nRuleNo=null

			-- Get the first Amend Case rule

			Set @sSQLString="
			Select @nRuleNo=min(AMENDCASERULE)
			FROM #TEMPCASEMATCH
			WHERE AMENDCASERULE is not null"

			exec @nErrorCode=sp_executesql @sSQLString,
						N'@nRuleNo	int	OUTPUT',
						  @nRuleNo=@nRuleNo	OUTPUT
		End

		If @nErrorCode=0
		and @nRuleNo is not null
		Begin	
			-----------------------------------------------------------------------------
			-- A separate database transaction will be used to insert the TRANSACTIONINFO
			-- row to ensure the lock on the database is kept to a minimum as this table
			-- will be used extensively by other processes.
			-----------------------------------------------------------------------------
		
			Select @nTranCountStart = @@TranCount
			BEGIN TRANSACTION
		
			-- Allocate a transaction id that can be accessed by the audit logs
			-- for inclusion.
		
			Set @sSQLString="Insert into TRANSACTIONINFO(TRANSACTIONDATE, BATCHNO,TRANSACTIONMESSAGENO, TRANSACTIONREASONNO) values(getdate(),@pnBatchNo,2,@nReasonNo)
					Set @nTransNo=SCOPE_IDENTITY()"
			
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int,
							  @nReasonNo	int,
							  @nTransNo	int	OUTPUT',
							  @pnBatchNo=@pnBatchNo,
							  @nReasonNo=@nReasonNo,
							  @nTransNo=@nTransNo	OUTPUT

			--------------------------------------------------------------
			-- Load a common area accessible from the database server with
			-- the TransactionNo just generated.
			-- This will be used by the audit logs.
			--------------------------------------------------------------
		
			set @bHexNumber=substring(cast(isnull(@pnUserIdentityId,'') as varbinary),1,4) + 
					substring(cast(isnull(@nTransNo,'') as varbinary),1,4)+ 
					substring(cast(isnull(@pnBatchNo,'') as varbinary),1,4) +
					substring(cast(isnull(@nOfficeID,'') as varbinary),1,4) +
					substring(cast(isnull(@nLogMinutes,'') as varbinary),1,4)
			SET CONTEXT_INFO @bHexNumber
		
			-- Commit or Rollback the transaction
			
			If @@TranCount > @nTranCountStart
			Begin
				If @nErrorCode = 0
					COMMIT TRANSACTION
				Else
					ROLLBACK TRANSACTION
			End
		End

		Set @nAmendCaseCount=0

		While @nRuleNo is not null
		and @nErrorCode=0
		Begin
			-----------------------------------
			-- Get the rule that applies to the 
			-- entire case.
			-----------------------------------
			Set @sRule='0'	-- If no rule then set to Operator Review
			
			Set @sSQLString="
			Select @sRule=Cast(WHOLECASE as varchar)
			from EDERULECASE
			where CRITERIANO=@nRuleNo"
			
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@sRule	varchar(4)	OUTPUT,
						  @nRuleNo	int',
						  @sRule  =@sRule		OUTPUT,
						  @nRuleNo=@nRuleNo
			
			Set @nAmendCaseCount=@nAmendCaseCount+1
			
			Set @nRetry=3
			While @nRetry>0
			and @nErrorCode=0
			Begin
				BEGIN TRY
					-------------------------------------------
					-- Start a new transaction
					-------------------------------------------
					-- A new database transaction will be used
					-- for each different Amend Rule being
					-- processed.  This is because the actual
					-- database changes will be applied as 
					-- the rules are processed so locks on 
					-- the database should be held for no
					-- longer than the time it takes to process
					-- one rule in full.
					-------------------------------------------
					Select @nTranCountStart = @@TranCount
					BEGIN TRANSACTION

					-----------------------------------------------------------------------------
					-- Check the Amend Case rules to identify those cases that will need to go to 
					-- either operator or supervisor review or be rejected altogether.
					-- Operator review will take precedence over Supervisor review so once a Case
					-- is marked for Operator Review it does not need to be considered again.
					-----------------------------------------------------------------------------

					--------------------------------------------------------------------------------------------------------
					-- Action  	Description
					--------------------------------------------------------------------------------------------------------
					--   0		Automatic update not allowed
					--		Change Transaction Status to ‘Operator Review’
					--------------------------------------------------------------------------------------------------------
					--   5		If name is changing within a group then automatically update, otherwise operator review 
					--		required.
					--		Only applies to case names.
					--------------------------------------------------------------------------------------------------------
					--   6		Automatic update for new and amended data only if derived events are not impacted. 
					--		Otherwise Supervisor Approval required.
					--		Change Transaction Status to ‘Supervisor Approval’, unless Operator review required.
					--------------------------------------------------------------------------------------------------------
					--   8		Automatic update if live field is empty. If existing value is changing supervisor  
					--		approval required.
					--		Change Transaction Status to ‘Supervisor Approval’, unless Operator review required.
					--------------------------------------------------------------------------------------------------------
					--   9		Automatic update is not allowed and no Operator or Supervisor intervention is required.
					--		Change Transaction Status to 'Processed'
					--		Raise  issue -38 'Update of existing case not allowed'
					--------------------------------------------------------------------------------------------------------

					------------------------------------
					-- CASES
					-- Check if all updates are blocked.
					------------------------------------
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Insert into #TEMPREVIEW(TRANSACTIONIDENTIFIER,DRAFTCASEID,REVIEWTYPE)
						Select T.TRANSACTIONIDENTIFIER, T.DRAFTCASEID, 'X'
						From #TEMPCASEMATCH T
						join EDERULECASE R on (R.CRITERIANO=T.AMENDCASERULE)			
						Where T.AMENDCASERULE=@nRuleNo
						and R.WHOLECASE=9"
				
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End
					
					------------------------------------
					-- Now insert the outstanding issues
					-- to indicate that updates were not
					-- allowed.
					------------------------------------
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, CASEID, DATECREATED)
						-- draft cases that block the update of live case will be deleted so don't reference CASEID
						Select Distinct -38, @pnBatchNo, T.TRANSACTIONIDENTIFIER, NULL, getdate()
						from #TEMPREVIEW T
						left join EDEOUTSTANDINGISSUES I on (I.ISSUEID=-38
										 and I.BATCHNO=@pnBatchNo
										 and I.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
						where I.ISSUEID is null  -- do not insert a duplicate
						and T.REVIEWTYPE='X'"
				
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@pnBatchNo	int',
									  @pnBatchNo=@pnBatchNo
					End

					-----------
					-- CASES --
					-----------

					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Insert into #TEMPREVIEW(TRANSACTIONIDENTIFIER,DRAFTCASEID,REVIEWTYPE)
						Select T.TRANSACTIONIDENTIFIER, T.DRAFTCASEID,
							-- Operator review is required
							-- for partial match cases.
						CASE	WHEN(T.MATCHLEVEL=3253)	THEN 'O'
							-- Operator review is required
							-- if any data item is to change
							WHEN(isnull(R.CASETYPE,"+@sRule+")=0 	  and checksum(L.CASETYPE)	  <>checksum(isnull(CT.ACTUALCASETYPE,D.CASETYPE))) THEN 'O'
							WHEN(isnull(R.PROPERTYTYPE,"+@sRule+")=0  and checksum(L.PROPERTYTYPE)	  <>checksum(D.PROPERTYTYPE))	 THEN 'O'
							WHEN(isnull(R.COUNTRY,"+@sRule+")=0 	  and checksum(L.COUNTRYCODE)	  <>checksum(D.COUNTRYCODE))	 THEN 'O'
							WHEN(isnull(R.CATEGORY,"+@sRule+")=0 	  and checksum(L.CASECATEGORY)	  <>checksum(D.CASECATEGORY))	 THEN 'O'
							WHEN(isnull(R.SUBTYPE,"+@sRule+")=0 	  and checksum(L.SUBTYPE)	  <>checksum(D.SUBTYPE))	 THEN 'O'
							WHEN(isnull(R.ENTITYSIZE,"+@sRule+")=0 	  and checksum(L.ENTITYSIZE)      <>checksum(D.ENTITYSIZE))	 THEN 'O'
							WHEN(isnull(R.TYPEOFMARK,"+@sRule+")=0 	  and checksum(L.TYPEOFMARK)      <>checksum(D.TYPEOFMARK))	 THEN 'O'
							WHEN(isnull(R.NUMBEROFDESIGNS,"+@sRule+")=0  and checksum(L.NOINSERIES)   <>checksum(D.NOINSERIES))	 THEN 'O'
							WHEN(isnull(R.NUMBEROFYEARSEXT,"+@sRule+")=0 and checksum(L.EXTENDEDRENEWALS)<>checksum(D.EXTENDEDRENEWALS))THEN 'O'
							WHEN(isnull(R.STOPPAYREASON,"+@sRule+")=0 and checksum(L.STOPPAYREASON)   <>checksum(D.STOPPAYREASON))	 THEN 'O'
							WHEN(isnull(R.SHORTTITLE,"+@sRule+")=0 	  and checksum(L.TITLE)           <>checksum(D.TITLE))		 THEN 'O'
							WHEN(isnull(R.CLASSES,"+@sRule+")=0 	  and checksum(L.LOCALCLASSES)    <>checksum(D.LOCALCLASSES))	 THEN 'O'
				
							-- Supervisor review is required
							-- if live value is to change and derived events effected
							WHEN(X.CASEID is not null and isnull(R.CASETYPE,"+@sRule+")=6 	   and checksum(L.CASETYPE)	   <>checksum(isnull(CT.ACTUALCASETYPE,D.CASETYPE))) THEN 'S'
							WHEN(X.CASEID is not null and isnull(R.PROPERTYTYPE,"+@sRule+")=6  and checksum(L.PROPERTYTYPE)	   <>checksum(D.PROPERTYTYPE))	  THEN 'S'
							WHEN(X.CASEID is not null and isnull(R.COUNTRY,"+@sRule+")=6 	   and checksum(L.COUNTRYCODE)	   <>checksum(D.COUNTRYCODE))	  THEN 'S'
							WHEN(X.CASEID is not null and isnull(R.CATEGORY,"+@sRule+")=6 	   and checksum(L.CASECATEGORY)	   <>checksum(D.CASECATEGORY))	  THEN 'S'
							WHEN(X.CASEID is not null and isnull(R.SUBTYPE,"+@sRule+")=6 	   and checksum(L.SUBTYPE)	   <>checksum(D.SUBTYPE))	  THEN 'S'
							WHEN(X.CASEID is not null and isnull(R.ENTITYSIZE,"+@sRule+")=6    and checksum(L.ENTITYSIZE)	   <>checksum(D.ENTITYSIZE))	  THEN 'S'
							WHEN(X.CASEID is not null and isnull(R.TYPEOFMARK,"+@sRule+")=6    and checksum(L.TYPEOFMARK)	   <>checksum(D.TYPEOFMARK))	  THEN 'S'
							WHEN(X.CASEID is not null and isnull(R.NUMBEROFDESIGNS,"+@sRule+")=6  and checksum(L.NOINSERIES)	   <>checksum(D.NOINSERIES))	  THEN 'S'
							WHEN(X.CASEID is not null and isnull(R.NUMBEROFYEARSEXT,"+@sRule+")=6 and checksum(L.EXTENDEDRENEWALS)<>checksum(D.EXTENDEDRENEWALS))THEN 'S'
							WHEN(X.CASEID is not null and isnull(R.STOPPAYREASON,"+@sRule+")=6    and checksum(L.STOPPAYREASON)   <>checksum(D.STOPPAYREASON))	  THEN 'S'
							WHEN(X.CASEID is not null and isnull(R.SHORTTITLE,"+@sRule+")=6    and checksum(L.TITLE)	   <>checksum(D.TITLE))		  THEN 'S'
							WHEN(X.CASEID is not null and isnull(R.CLASSES,"+@sRule+")=6 	   and checksum(L.LOCALCLASSES)	   <>checksum(D.LOCALCLASSES))	  THEN 'S'
				
							-- Supervisor review is required
							-- if live value is not null and about to change
							WHEN(isnull(R.CASETYPE,"+@sRule+")=8 	  and L.CASETYPE	<>isnull(CT.ACTUALCASETYPE,D.CASETYPE)) THEN 'S'
							WHEN(isnull(R.PROPERTYTYPE,"+@sRule+")=8  and L.PROPERTYTYPE	<>isnull(D.PROPERTYTYPE,''))	THEN 'S'
							WHEN(isnull(R.COUNTRY,"+@sRule+")=8 	  and L.COUNTRYCODE	<>isnull(D.COUNTRYCODE,''))	THEN 'S'
							WHEN(isnull(R.CATEGORY,"+@sRule+")=8 	  and L.CASECATEGORY	<>isnull(D.CASECATEGORY,''))	THEN 'S'
							WHEN(isnull(R.SUBTYPE,"+@sRule+")=8 	  and L.SUBTYPE		<>isnull(D.SUBTYPE,''))		THEN 'S'
							WHEN(isnull(R.ENTITYSIZE,"+@sRule+")=8 	  and L.ENTITYSIZE	<>isnull(D.ENTITYSIZE,''))	THEN 'S'
							WHEN(isnull(R.TYPEOFMARK,"+@sRule+")=8 	  and L.TYPEOFMARK	<>isnull(D.TYPEOFMARK,''))	THEN 'S'
							WHEN(isnull(R.NUMBEROFDESIGNS,"+@sRule+")=8  and L.NOINSERIES	<>isnull(D.NOINSERIES,''))	THEN 'S'
							WHEN(isnull(R.NUMBEROFYEARSEXT,"+@sRule+")=8 and L.EXTENDEDRENEWALS<>isnull(D.EXTENDEDRENEWALS,''))THEN 'S'
							WHEN(isnull(R.STOPPAYREASON,"+@sRule+")=8 and L.STOPPAYREASON	<>isnull(D.STOPPAYREASON,''))	THEN 'S'
							WHEN(isnull(R.SHORTTITLE,"+@sRule+")=8 	  and L.TITLE		<>isnull(D.TITLE,''))		THEN 'S'
							WHEN(isnull(R.CLASSES,"+@sRule+")=8 	  and L.LOCALCLASSES	<>isnull(D.LOCALCLASSES,''))	THEN 'S'
						End
						From CASES L
						join #TEMPCASEMATCH T	on (T.LIVECASEID=L.CASEID)
						left join EDERULECASE R	on (R.CRITERIANO=T.AMENDCASERULE)
						join (select *
						      from CASES) D	on (D.CASEID=T.DRAFTCASEID)
						join CASETYPE CT	on (CT.CASETYPE=D.CASETYPE)
						-- derived events do not match
						left join #TEMPDERIVEDEVENTCHANGED X
									on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('O','X'))				
						Where T.AMENDCASERULE=@nRuleNo
						and V.TRANSACTIONIDENTIFIER is null
						and((checksum(L.CASETYPE)<>checksum(isnull(CT.ACTUALCASETYPE,D.CASETYPE))  
							and( (isnull(R.CASETYPE,"+@sRule+")=0)	
							   or(isnull(R.CASETYPE,"+@sRule+")=8 and L.CASETYPE is not null)
							   or(isnull(R.CASETYPE,"+@sRule+")=6 and X.CASEID is not null) ) )
						 OR (checksum(L.PROPERTYTYPE)<>checksum(D.PROPERTYTYPE)  
							and( (isnull(R.PROPERTYTYPE,"+@sRule+")=0)	
							   or(isnull(R.PROPERTYTYPE,"+@sRule+")=8 and L.PROPERTYTYPE is not null)
							   or(isnull(R.PROPERTYTYPE,"+@sRule+")=6 and X.CASEID is not null) ) )
						 OR (checksum(L.COUNTRYCODE)<>checksum(D.COUNTRYCODE)  
							and( (isnull(R.COUNTRY,"+@sRule+")=0)	
							   or(isnull(R.COUNTRY,"+@sRule+")=8 and L.COUNTRYCODE is not null)
							   or(isnull(R.COUNTRY,"+@sRule+")=6 and X.CASEID is not null) ) )
						 OR (checksum(L.CASECATEGORY)<>checksum(D.CASECATEGORY)  
							and( (isnull(R.CATEGORY,"+@sRule+")=0)	
							   or(isnull(R.CATEGORY,"+@sRule+")=8 and L.CASECATEGORY is not null)
							   or(isnull(R.CATEGORY,"+@sRule+")=6 and X.CASEID is not null) ) )
						 OR (checksum(L.SUBTYPE)<>checksum(D.SUBTYPE)  
							and( (isnull(R.SUBTYPE,"+@sRule+")=0)	
							   or(isnull(R.SUBTYPE,"+@sRule+")=8 and L.SUBTYPE is not null)
							   or(isnull(R.SUBTYPE,"+@sRule+")=6 and X.CASEID is not null) ) )
						 OR (checksum(L.ENTITYSIZE)<>checksum(D.ENTITYSIZE)  
							and( (isnull(R.ENTITYSIZE,"+@sRule+")=0)	
							   or(isnull(R.ENTITYSIZE,"+@sRule+")=8 and L.ENTITYSIZE is not null)
							   or(isnull(R.ENTITYSIZE,"+@sRule+")=6 and X.CASEID is not null) ) )
						 OR (checksum(L.TYPEOFMARK)<>checksum(D.TYPEOFMARK)  
							and( (isnull(R.TYPEOFMARK,"+@sRule+")=0)	
							   or(isnull(R.TYPEOFMARK,"+@sRule+")=8 and L.TYPEOFMARK is not null)
							   or(isnull(R.TYPEOFMARK,"+@sRule+")=6 and X.CASEID is not null) ) )
						 OR (checksum(L.NOINSERIES)<>checksum(D.NOINSERIES)  
							and( (isnull(R.NUMBEROFDESIGNS,"+@sRule+")=0)	
							   or(isnull(R.NUMBEROFDESIGNS,"+@sRule+")=8 and L.NOINSERIES is not null)
							   or(isnull(R.NUMBEROFDESIGNS,"+@sRule+")=6 and X.CASEID is not null) ) )
						 OR (checksum(L.EXTENDEDRENEWALS)<>checksum(D.EXTENDEDRENEWALS)  
							and( (isnull(R.NUMBEROFYEARSEXT,"+@sRule+")=0)	
							   or(isnull(R.NUMBEROFYEARSEXT,"+@sRule+")=8 and L.EXTENDEDRENEWALS is not null)
							   or(isnull(R.NUMBEROFYEARSEXT,"+@sRule+")=6 and X.CASEID is not null) ) )
						 OR (checksum(L.STOPPAYREASON)<>checksum(D.STOPPAYREASON)  
							and( (isnull(R.STOPPAYREASON,"+@sRule+")=0)	
							   or(isnull(R.STOPPAYREASON,"+@sRule+")=8 and L.STOPPAYREASON is not null)
							   or(isnull(R.STOPPAYREASON,"+@sRule+")=6 and X.CASEID is not null) ) )
						 OR (checksum(L.TITLE)<>checksum(D.TITLE)  
							and( (isnull(R.SHORTTITLE,"+@sRule+")=0)	
							   or(isnull(R.SHORTTITLE,"+@sRule+")=8 and L.TITLE is not null)
							   or(isnull(R.SHORTTITLE,"+@sRule+")=6 and X.CASEID is not null) ) )
						 OR (checksum(L.LOCALCLASSES)<>checksum(D.LOCALCLASSES)  
							and( (isnull(R.CLASSES,"+@sRule+")=0)	
							   or(isnull(R.CLASSES,"+@sRule+")=8 and L.LOCALCLASSES is not null)
							   or(isnull(R.CLASSES,"+@sRule+")=6 and X.CASEID is not null) ) ) )"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End
					
					--------------
					-- PROPERTY --
					--------------
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Insert into #TEMPREVIEW(TRANSACTIONIDENTIFIER,DRAFTCASEID,REVIEWTYPE)
						Select T.TRANSACTIONIDENTIFIER, T.DRAFTCASEID,
							-- Operator review is required
							-- for partial match cases.
						CASE	WHEN(T.MATCHLEVEL=3253)	THEN 'O'
							-- Operator review is required
							-- if any data item is to change
							WHEN(isnull(R.BASIS,"+@sRule+")=0 	   and checksum(L.BASIS)     <>checksum(D.BASIS))      THEN 'O'
			 				WHEN(isnull(R.NUMBEROFCLAIMS,"+@sRule+")=0 and checksum(L.NOOFCLAIMS)<>checksum(D.NOOFCLAIMS)) THEN 'O'
							
							-- Supervisor review is required
							-- if live value is to change and derived events effected
							WHEN(X.CASEID is not null and isnull(R.BASIS,"+@sRule+")=6          and checksum(L.BASIS)     <>checksum(D.BASIS)) THEN 'S'
							WHEN(X.CASEID is not null and isnull(R.NUMBEROFCLAIMS,"+@sRule+")=6 and checksum(L.NOOFCLAIMS)<>checksum(D.BASIS)) THEN 'S'
							
							-- Supervisor review is required
							-- if live value is not null and about to change
							WHEN(isnull(R.BASIS,"+@sRule+")=8          and L.BASIS	    <>isnull(D.BASIS,''))	THEN 'S'
							WHEN(isnull(R.NUMBEROFCLAIMS,"+@sRule+")=8 and L.NOOFCLAIMS<>isnull(D.NOOFCLAIMS,''))	THEN 'S'
						End
						From PROPERTY L
						join #TEMPCASEMATCH T	on (T.LIVECASEID=L.CASEID)
						left join EDERULECASE R	on (R.CRITERIANO=T.AMENDCASERULE)
						join (select *
						      from PROPERTY) D	on (D.CASEID=T.DRAFTCASEID)
						-- derived events do not match
						left join #TEMPDERIVEDEVENTCHANGED X
									on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('O','X'))
						Where T.AMENDCASERULE=@nRuleNo
						and V.TRANSACTIONIDENTIFIER is null
						and((checksum(L.BASIS)<>checksum(D.BASIS)  
							and( (isnull(R.BASIS,"+@sRule+")=0)	
							   or(isnull(R.BASIS,"+@sRule+")=8 and L.BASIS is not null)
							   or(isnull(R.BASIS,"+@sRule+")=6 and X.CASEID is not null) ) )
						 OR (checksum(L.NOOFCLAIMS)<>checksum(D.NOOFCLAIMS)  
							and( (isnull(R.NUMBEROFCLAIMS,"+@sRule+")=0)	
							   or(isnull(R.NUMBEROFCLAIMS,"+@sRule+")=8 and L.NOOFCLAIMS is not null)
							   or(isnull(R.NUMBEROFCLAIMS,"+@sRule+")=6 and X.CASEID is not null) ) ))"	
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End


					--------------------------
					-- DESIGNATED COUNTRIES --
					--------------------------
					If @nErrorCode=0
					Begin

						Set @sSQLString="
						Insert into #TEMPREVIEW(TRANSACTIONIDENTIFIER,DRAFTCASEID,REVIEWTYPE)
						Select T.TRANSACTIONIDENTIFIER, T.DRAFTCASEID,
							------------------------------
							-- Operator review is required
							-- if designated country on 
							-- draft case is missing
							------------------------------
						CASE	WHEN(R.DESIGNATEDCOUNTRIES=0) THEN 'O'
							---------------------------------
							-- Supervisor review is required
							-- if live value is to change and 
							-- derived events effected
							---------------------------------
							WHEN(X.CASEID is not null and R.DESIGNATEDCOUNTRIES=6) THEN 'S'
							---------------------------------
							-- Supervisor review is required
							-- if live value is not null and 
							-- about to change
							---------------------------------
							WHEN(R.DESIGNATEDCOUNTRIES=8) THEN 'S'
						End
						From #TEMPCASEMATCH T
						join EDERULECASE R		on (R.CRITERIANO=T.AMENDCASERULE)
						------------------------------
						-- Designated country on live  
						-- case does not exist against 
						-- draft case
						------------------------------
						join RELATEDCASE L		on (L.CASEID=T.LIVECASEID
										and L.RELATIONSHIP='DC1')	-- Designated Countries are held as related cases with relationship DC1
						left join RELATEDCASE D		on (D.CASEID=T.DRAFTCASEID
										and D.RELATIONSHIP='DC1'
										and D.COUNTRYCODE =L.COUNTRYCODE)
						------------------------------
						-- Derived events do not match
						------------------------------
						left join #TEMPDERIVEDEVENTCHANGED X
										on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V		on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
										and V.REVIEWTYPE='O')			
						Where T.AMENDCASERULE=@nRuleNo
						and V.TRANSACTIONIDENTIFIER is null
						and D.COUNTRYCODE is null  
						and(  R.DESIGNATEDCOUNTRIES in (0,8)
						   or(R.DESIGNATEDCOUNTRIES=6 and  X.CASEID is not null) )
						UNION
						Select T.TRANSACTIONIDENTIFIER, T.DRAFTCASEID,
							------------------------------
							-- Operator review is required
							-- if designated country on 
							-- draft case is missing
							------------------------------
						CASE	WHEN(R.DESIGNATEDCOUNTRIES=0) THEN 'O'
							---------------------------------
							-- Supervisor review is required
							-- if live value is to change and 
							-- derived events effected
							---------------------------------
							WHEN(X.CASEID is not null  and R.DESIGNATEDCOUNTRIES=6) THEN 'S'
							---------------------------------
							-- Supervisor review is required
							-- if live value is not null and 
							-- about to change
							---------------------------------
							WHEN(L1.CASEID is not null and R.DESIGNATEDCOUNTRIES=8) THEN 'S'
						End
						From #TEMPCASEMATCH T
						join EDERULECASE R		on (R.CRITERIANO=T.AMENDCASERULE)
						------------------------------
						-- Designated country on draft  
						-- case does not exist against 
						-- live case
						------------------------------
						join RELATEDCASE D		on (D.CASEID=T.DRAFTCASEID
										and D.RELATIONSHIP='DC1')	-- Designated Countries are held as related cases with relationship DC1
						left join RELATEDCASE L		on (L.CASEID=T.LIVECASEID
										and L.RELATIONSHIP='DC1'
										and L.COUNTRYCODE =D.COUNTRYCODE)
						------------------------------
						-- Do any designated countries  
						-- exist against the live case.
						------------------------------
						left join (select distinct CASEID
						           from RELATEDCASE
						           where RELATIONSHIP='DC1') L1
										on (L1.CASEID=T.LIVECASEID)
						------------------------------
						-- Derived events do not match
						------------------------------
						left join #TEMPDERIVEDEVENTCHANGED X
										on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V		on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
										and V.REVIEWTYPE='O')			
						Where T.AMENDCASERULE=@nRuleNo
						and V.TRANSACTIONIDENTIFIER is null
						and L.COUNTRYCODE is null
						and(  R.DESIGNATEDCOUNTRIES=0 	
						   or(R.DESIGNATEDCOUNTRIES=8 and L1.CASEID is not null)
						   or(R.DESIGNATEDCOUNTRIES=6 and  X.CASEID is not null) )"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End

					---------------------
					-- OFFICIALNUMBERS --
					---------------------
					If @nErrorCode=0
					Begin

						Set @sSQLString="
						Insert into #TEMPREVIEW(TRANSACTIONIDENTIFIER,DRAFTCASEID,REVIEWTYPE)
						Select T.TRANSACTIONIDENTIFIER, T.DRAFTCASEID,
							-- Operator review is required
							-- if any data item is to change
						CASE	WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+")=0 and checksum(L.OFFICIALNUMBER)<>checksum(D.OFFICIALNUMBER)) THEN 'O'
						 	
							-- Supervisor review is required
							-- if live value is to change and derived events effected
							WHEN(X.CASEID is not null and isnull(R.OFFICIALNUMBER,"+@sRule+")=6 and checksum(L.OFFICIALNUMBER)<>checksum(D.OFFICIALNUMBER)) THEN 'S'
							
							-- Supervisor review is required
							-- if live value is not null and about to change
							WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+")=8 and L.OFFICIALNUMBER<>isnull(D.OFFICIALNUMBER,'')) THEN 'S'
						End
						From #TEMPCASEMATCH T
						join OFFICIALNUMBERS L		on (L.CASEID=T.LIVECASEID)
						join OFFICIALNUMBERS D		on (D.CASEID=T.DRAFTCASEID
										and D.NUMBERTYPE=L.NUMBERTYPE)
						left join EDERULEOFFICIALNUMBER R on (R.CRITERIANO=T.AMENDCASERULE
										  and R.NUMBERTYPE=L.NUMBERTYPE)
						-- derived events do not match
						left join #TEMPDERIVEDEVENTCHANGED X
									on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('O','X'))
						Where T.AMENDCASERULE=@nRuleNo
						and V.TRANSACTIONIDENTIFIER is null
						and  checksum(L.OFFICIALNUMBER)<>checksum(D.OFFICIALNUMBER)  
							and( (isnull(R.OFFICIALNUMBER,"+@sRule+")=0)	
							   or(isnull(R.OFFICIALNUMBER,"+@sRule+")=8 and L.OFFICIALNUMBER is not null)
							   or(isnull(R.OFFICIALNUMBER,"+@sRule+")=6 and X.CASEID is not null) )"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End

					If @nErrorCode=0
					Begin

						Set @sSQLString="
						Insert into #TEMPREVIEW(TRANSACTIONIDENTIFIER,DRAFTCASEID,REVIEWTYPE)
						Select T.TRANSACTIONIDENTIFIER, T.DRAFTCASEID,
							-- Operator review is required
							-- for partial match cases.
						CASE	WHEN(T.MATCHLEVEL=3253)	THEN 'O'
							-- Operator review is required
							-- if any data item is to change
							WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+")=0 ) THEN 'O'
						 	
							-- Supervisor review is required
							-- if live value is to change and derived events effected
							WHEN(X.CASEID is not null and isnull(R.OFFICIALNUMBER,"+@sRule+")=6) THEN 'S'
							
							-- Supervisor review is required
							-- if live value is about to change
							WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+")=8 and L1.CASEID is not null) THEN 'S'
						End
						From #TEMPCASEMATCH T
						join OFFICIALNUMBERS D		on (D.CASEID=T.DRAFTCASEID)
						left join OFFICIALNUMBERS L	on (L.CASEID=T.LIVECASEID
										and L.NUMBERTYPE=D.NUMBERTYPE
										and L.OFFICIALNUMBER=D.OFFICIALNUMBER)
						-- check if live 
						left join (select distinct CASEID, NUMBERTYPE
							   from OFFICIALNUMBERS
							   where ISCURRENT=1) L1 on (L1.CASEID=T.LIVECASEID
										and  L1.NUMBERTYPE=D.NUMBERTYPE)
						left join EDERULEOFFICIALNUMBER R on (R.CRITERIANO=T.AMENDCASERULE
										  and R.NUMBERTYPE=D.NUMBERTYPE)
						-- derived events do not match
						left join #TEMPDERIVEDEVENTCHANGED X
									on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('O','X'))
						Where T.AMENDCASERULE=@nRuleNo
						and V.TRANSACTIONIDENTIFIER is null
						and L.CASEID is null
						and (isnull(R.OFFICIALNUMBER,"+@sRule+")=0)
						  or(isnull(R.OFFICIALNUMBER,"+@sRule+")=6 and X.CASEID is not null)"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End
			
					--------------
					-- CASETEXT --
					--------------
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Insert into #TEMPREVIEW(TRANSACTIONIDENTIFIER,DRAFTCASEID,REVIEWTYPE)
						Select T.TRANSACTIONIDENTIFIER, T.DRAFTCASEID,
							-- Operator review is required
							-- for partial match cases.
						CASE	WHEN(T.MATCHLEVEL=3253)	THEN 'O'
							-- Operator review is required
							-- if any data item is to change
							WHEN(isnull(R.TEXT,"+@sRule+")=0) THEN 'O'
						 	
							-- Supervisor review is required
							-- if live value is to change and derived events effected
							WHEN(X.CASEID is not null) THEN 'S'
							
							-- Supervisor review is required
							-- if live value is not null and about to change
							WHEN(isnull(R.TEXT,"+@sRule+")=8 and L.CASEID is not null) THEN 'S'
						End
						From #TEMPCASEMATCH T
						join CASETEXT L		on (L.CASEID=T.LIVECASEID)
						join CASETEXT D		on (D.CASEID=T.DRAFTCASEID
									and D.TEXTTYPE=L.TEXTTYPE
									and(D.LANGUAGE=L.LANGUAGE or L.LANGUAGE is null)
									and(D.CLASS=L.CLASS or L.CLASS is null))
						left join EDERULECASETEXT R on (R.CRITERIANO=T.AMENDCASERULE
									    and R.TEXTTYPE=L.TEXTTYPE)
						-- derived events do not match
						left join #TEMPDERIVEDEVENTCHANGED X
										on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('O','X'))
						Where T.AMENDCASERULE=@nRuleNo
						and V.TRANSACTIONIDENTIFIER is null
						and ( checksum(L.SHORTTEXT)<>checksum(D.SHORTTEXT) or checksum(datalength(L.TEXT))<>checksum(datalength(D.TEXT)) or L.TEXT not like D.TEXT)
							and( (isnull(R.TEXT,"+@sRule+")=0)	
							   or(isnull(R.TEXT,"+@sRule+")=8 and L.CASEID is not null)
							   or(isnull(R.TEXT,"+@sRule+")=6 and X.CASEID is not null) )"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End
					
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Insert into #TEMPREVIEW(TRANSACTIONIDENTIFIER,DRAFTCASEID,REVIEWTYPE)
						Select T.TRANSACTIONIDENTIFIER, T.DRAFTCASEID,
							-- Operator review is required
							-- for partial match cases.
						CASE	WHEN(T.MATCHLEVEL=3253)	THEN 'O'
							-- Operator review is required
							-- if any data item is to change
							WHEN(isnull(R.TEXT,"+@sRule+")=0) THEN 'O'
						 	
							-- Supervisor review is required
							-- if live value is to change and derived events effected
							WHEN(X.CASEID is not null) THEN 'S'
							
							-- Supervisor review is required
							-- if live value is not null and about to change
							WHEN(isnull(R.TEXT,"+@sRule+")=8) THEN 'S'
						End
						From #TEMPCASEMATCH T
						join CASETEXT D		on (D.CASEID=T.DRAFTCASEID)
						left join CASETEXT L	on (L.CASEID=T.LIVECASEID
									and L.TEXTTYPE=D.TEXTTYPE
									and(L.LANGUAGE=D.LANGUAGE or D.LANGUAGE is null)
									and(L.CLASS=D.CLASS or D.CLASS is null))
						left join EDERULECASETEXT R on (R.CRITERIANO=T.AMENDCASERULE
									    and R.TEXTTYPE=D.TEXTTYPE)
						-- derived events do not match
						left join #TEMPDERIVEDEVENTCHANGED X
									on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('O','X'))
						Where T.AMENDCASERULE=@nRuleNo
						and V.TRANSACTIONIDENTIFIER is null
						and L.CASEID is null
						and( (isnull(R.TEXT,"+@sRule+")=0)
						   or(isnull(R.TEXT,"+@sRule+")=6 and X.CASEID is not null) )"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End

					---------------
					-- CASEEVENT --
					---------------
					If @nErrorCode=0
					Begin
						Set @sSQLString=
						"Insert into #TEMPREVIEW(TRANSACTIONIDENTIFIER,DRAFTCASEID,REVIEWTYPE)"+char(10)+
						"Select T.TRANSACTIONIDENTIFIER, T.DRAFTCASEID,"+char(10)+
							-- Operator review is required
							-- for partial match cases.
						"CASE	WHEN(T.MATCHLEVEL=3253)	THEN 'O'"+char(10)+
							-- Operator review is required
							-- if any data item is to change
						"	WHEN(R.EVENTDATE=0    and checksum(L.EVENTDATE)   <>checksum(D.EVENTDATE))    THEN 'O'"+char(10)+
			 			"	WHEN(R.EVENTDUEDATE=0 and checksum(L.EVENTDUEDATE)<>checksum(D.EVENTDUEDATE)) THEN 'O'"+char(10)+
			 			"	WHEN(R.EVENTTEXT=0    and(checksum(L.EVENTTEXT)   <>checksum(D.EVENTTEXT) or checksum(datalength(L.EVENTLONGTEXT))<>checksum(datalength(D.EVENTLONGTEXT)) or L.EVENTLONGTEXT not like D.EVENTLONGTEXT))"+char(10)+
						"		THEN 'O'"+char(10)+
							-- Supervisor review is required
							-- if live value is to change and derived events effected
						"	WHEN(X.CASEID is not null and R.EVENTDATE=6    and checksum(L.EVENTDATE)   <>checksum(D.EVENTDATE))   THEN 'S'"+char(10)+
						"	WHEN(X.CASEID is not null and R.EVENTDUEDATE=6 and checksum(L.EVENTDUEDATE)<>checksum(D.EVENTDUEDATE))THEN 'S'"+char(10)+
						"	WHEN(X.CASEID is not null and R.EVENTTEXT=6    and(checksum(L.EVENTTEXT)   <>checksum(D.EVENTTEXT) or checksum(datalength(L.EVENTLONGTEXT))<>checksum(datalength(D.EVENTLONGTEXT)) or L.EVENTLONGTEXT not like D.EVENTLONGTEXT))"+char(10)+
						"		THEN 'S'"+char(10)+
							-- Supervisor review is required
							-- if live value is not null and about to change
						"	WHEN(R.EVENTDATE=8    and L.EVENTDATE	<>isnull(D.EVENTDATE,''))   THEN 'S'"+char(10)+
						"	WHEN(R.EVENTDUEDATE=8 and L.EVENTDUEDATE<>isnull(D.EVENTDUEDATE,''))THEN 'S'"+char(10)+
						"	WHEN(R.EVENTTEXT=8    and(L.EVENTTEXT   <>isnull(D.EVENTTEXT,'') or L.EVENTLONGTEXT not like isnull(D.EVENTLONGTEXT,'')))"+char(10)+
						"		THEN 'S'"+char(10)+
						"End"+char(10)+
						"From #TEMPCASEMATCH T"+char(10)+
						"join EDERULECASEEVENT R	on (R.CRITERIANO=T.AMENDCASERULE)"+char(10)+
						-- Get the lowest open cycle taking cyclic actions in preference to non cyclic
						"Left Join (select OA.CASEID, EC.EVENTNO,"+char(10)+
	 					"	max(	convert(char(5), A.NUMCYCLESALLOWED)+"+char(10)+
						"		convert(char(5), 99999-OA.CYCLE)+"+char(10)+
						"		OA.ACTION) as BestAction"+char(10)+
						"	from EVENTCONTROL EC"+char(10)+
						"	join EVENTS E      on (E.EVENTNO=EC.EVENTNO)"+char(10)+
						"	join OPENACTION OA on (OA.CRITERIANO=EC.CRITERIANO)"+char(10)+
						"	join ACTIONS A     on (A.ACTION=OA.ACTION)"+char(10)+
						"	where OA.POLICEEVENTS=1"+char(10)+
						"	and OA.ACTION=isnull(E.CONTROLLINGACTION,OA.ACTION)"+char(10)+
						"	group by OA.CASEID, EC.EVENTNO) BA1	on (BA1.CASEID=T.LIVECASEID"+char(10)+
						"						and BA1.EVENTNO=R.EVENTNO)"+CHAR(10)+
						"left join CASEEVENT L	on (L.CASEID=T.LIVECASEID"+char(10)+
						"			and L.EVENTNO=R.EVENTNO"+char(10)+
						"			and L.CYCLE=	CASE WHEN( (convert(int,substring(BA1.BestAction,1,5))>1) )"+char(10)+
						"						THEN 99999-convert(int,substring(BA1.BestAction,6,5))"+char(10)+
						"						ELSE (	select max(L1.CYCLE)"+char(10)+
						"							From CASEEVENT L1"+char(10)+
						"							where L1.CASEID=L.CASEID"+char(10)+
						"							and L1.EVENTNO=L.EVENTNO)"+char(10)+
						"					END )"+char(10)+
						-- Get the lowest open cycle taking cyclic actions in preference to non cyclic
						"Left Join (select OA.CASEID, EC.EVENTNO,"+char(10)+
	 					"	max(	convert(char(5), A.NUMCYCLESALLOWED)+"+char(10)+
						"		convert(char(5), 99999-OA.CYCLE)+"+char(10)+
						"		OA.ACTION) as BestAction"+char(10)+
						"	from EVENTCONTROL EC"+char(10)+
						"	join EVENTS E      on (E.EVENTNO=EC.EVENTNO)"+char(10)+
						"	join OPENACTION OA on (OA.CRITERIANO=EC.CRITERIANO)"+char(10)+
						"	join ACTIONS A     on (A.ACTION=OA.ACTION)"+char(10)+
						"	where OA.POLICEEVENTS=1"+char(10)+
						"	and OA.ACTION=isnull(E.CONTROLLINGACTION,OA.ACTION)"+char(10)+
						"	group by OA.CASEID, EC.EVENTNO) BA2	on (BA2.CASEID=T.DRAFTCASEID"+char(10)+
						"						and BA2.EVENTNO=R.EVENTNO)"+char(10)+
						"left join CASEEVENT D	on (D.CASEID=T.DRAFTCASEID"+char(10)+
						"			and D.EVENTNO=R.EVENTNO"+char(10)+
						"			and D.CYCLE=	CASE WHEN( (convert(int,substring(BA2.BestAction,1,5))>1) )"+char(10)+
						"						THEN 99999-convert(int,substring(BA2.BestAction,6,5))"+char(10)+
						"						ELSE (	select max(D1.CYCLE)"+char(10)+
						"							From CASEEVENT D1"+char(10)+
						"							where D1.CASEID=D.CASEID"+char(10)+
						"							and D1.EVENTNO=D.EVENTNO)"+char(10)+
						"					END )"+char(10)+
						-- derived events do not match
						"left join #TEMPDERIVEDEVENTCHANGED X"+char(10)+
						"			on (X.CASEID=T.DRAFTCASEID)"+char(10)+
						"left join #TEMPREVIEW V on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER"+char(10)+
						"			and V.REVIEWTYPE in ('O','X'))"+char(10)+
						"Where T.AMENDCASERULE=@nRuleNo"+char(10)+
						"and V.TRANSACTIONIDENTIFIER is null"+char(10)+
						"and(((checksum(L.EVENTTEXT)<>checksum(D.EVENTTEXT) or checksum(datalength(L.EVENTLONGTEXT))<>checksum(datalength(D.EVENTLONGTEXT)) or L.EVENTLONGTEXT not like D.EVENTLONGTEXT)"+char(10)+
						"	and(  R.EVENTTEXT=0"+char(10)+
						"	or(R.EVENTTEXT=8 and isnull(L.EVENTLONGTEXT,L.EVENTTEXT) is not null)"+char(10)+
						"	or(R.EVENTTEXT=6 and isnull(D.EVENTLONGTEXT,D.EVENTTEXT) is not null and X.CASEID is null)))"+char(10)+
						"OR  (checksum(L.EVENTDATE)<>checksum(D.EVENTDATE)"+char(10)+
						"	and(  R.EVENTDATE=0"+char(10)+
						"	or(R.EVENTDATE=8 and L.EVENTDATE is not null)"+char(10)+
						"	or(R.EVENTDATE=6 and X.CASEID is not null)))"+char(10)+
						"OR  (checksum(L.EVENTDUEDATE)<>checksum(D.EVENTDUEDATE)"+char(10)+
						"	and(  R.EVENTDUEDATE=0"+char(10)+
						"	or(R.EVENTDUEDATE=8 and L.EVENTDUEDATE is not null)"+char(10)+
						"	or(R.EVENTDUEDATE=6 and X.CASEID is not null))))"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End

					-----------------
					-- RELATEDCASE --
					-----------------
					If @nErrorCode=0
					Begin

						Set @sSQLString="
						Insert into #TEMPREVIEW(TRANSACTIONIDENTIFIER,DRAFTCASEID,REVIEWTYPE)
						Select T.TRANSACTIONIDENTIFIER, T.DRAFTCASEID,
							-- Operator review is required
							-- for partial match cases.
						CASE	WHEN(T.MATCHLEVEL=3253)	THEN 'O'
							-- Operator review is required
							-- if any data item is to change
							WHEN(isnull(R.PRIORITYDATE,"+@sRule+")=0) THEN 'O'
							-- Supervisor review is required
							-- if live value is to change and derived events effected
							WHEN(X.CASEID is not null and isnull(R.PRIORITYDATE,"+@sRule+")=6) THEN 'S'
							-- Supervisor review is required
							-- if live value is not null and about to change
							WHEN(isnull(R.PRIORITYDATE,"+@sRule+")=8) THEN 'S'
						End
						From #TEMPCASEMATCH T
						join EDERULERELATEDCASE R	on (R.CRITERIANO=T.AMENDCASERULE)
						join RELATEDCASE L		on (L.CASEID=T.LIVECASEID
										and L.RELATIONSHIP=R.RELATIONSHIP)
						join RELATEDCASE D		on (D.CASEID=T.DRAFTCASEID
										and D.RELATIONSHIP=R.RELATIONSHIP
										and(D.COUNTRYCODE=L.COUNTRYCODE or D.RELATIONSHIP<>'DC1') -- Designated Countries must match on Country							
										and isnull(D.RELATEDCASEID,'') =isnull(L.RELATEDCASEID,'')
										and isnull(D.OFFICIALNUMBER,'')=isnull(L.OFFICIALNUMBER,''))
						-- derived events do not match
						left join #TEMPDERIVEDEVENTCHANGED X
										on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('O','X'))
						Where T.AMENDCASERULE=@nRuleNo
						and V.TRANSACTIONIDENTIFIER is null
						and checksum(L.PRIORITYDATE)<>checksum(D.PRIORITYDATE)  
							and( (isnull(R.PRIORITYDATE,"+@sRule+")=0)	
							   or(isnull(R.PRIORITYDATE,"+@sRule+")=8 and L.PRIORITYDATE is not null)
							   or(isnull(R.PRIORITYDATE,"+@sRule+")=6 and X.CASEID is not null) )
						UNION
						Select T.TRANSACTIONIDENTIFIER, T.DRAFTCASEID,
							-- Operator review is required
							-- if any data item is to change
						CASE	WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+")=0) THEN 'O'
							-- Supervisor review is required
							-- if live value is to change and derived events effected
							WHEN(X.CASEID is not null and isnull(R.OFFICIALNUMBER,"+@sRule+")=6) THEN 'S'
							-- Supervisor review is required
							-- if live value is not null and about to change
							WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+")=8 and L.CASEID is not null) THEN 'S'
						End
						From #TEMPCASEMATCH T
						join EDERULERELATEDCASE R	on (R.CRITERIANO=T.AMENDCASERULE)
						join RELATEDCASE D		on (D.CASEID=T.DRAFTCASEID
										and D.RELATIONSHIP=R.RELATIONSHIP)
						left join RELATEDCASE L		on (L.CASEID=T.LIVECASEID
										and L.RELATIONSHIP=R.RELATIONSHIP
										and isnull(L.COUNTRYCODE,'')=isnull(D.COUNTRYCODE,''))
						-- derived events do not match
						left join #TEMPDERIVEDEVENTCHANGED X
										on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('O','X'))
						Where T.AMENDCASERULE=@nRuleNo
						and V.TRANSACTIONIDENTIFIER is null
						and( (isnull(R.OFFICIALNUMBER,"+@sRule+")=0)	
						   or(isnull(R.OFFICIALNUMBER,"+@sRule+")=8 and L.CASEID is not null)
						   or(isnull(R.OFFICIALNUMBER,"+@sRule+")=6 and X.CASEID is not null) )
						and not exists
						(select 1 from RELATEDCASE L
						 where L.CASEID=T.LIVECASEID
						 and L.RELATIONSHIP=R.RELATIONSHIP
						 and isnull(L.COUNTRYCODE,'')=isnull(D.COUNTRYCODE,'')
						 and isnull(L.OFFICIALNUMBER,'')=isnull(D.OFFICIALNUMBER,'') )"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End

					If @nErrorCode=0
					Begin

						Set @sSQLString="
						Insert into #TEMPREVIEW(TRANSACTIONIDENTIFIER,DRAFTCASEID,REVIEWTYPE)
						Select T.TRANSACTIONIDENTIFIER, T.DRAFTCASEID,
							-- Operator review is required
							-- for partial match cases.
						CASE	WHEN(T.MATCHLEVEL=3253)	THEN 'O'
							-- Operator review is required
							-- if any data item is to change
							WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+")=0 and checksum(L.OFFICIALNUMBER, L.COUNTRYCODE, L.RELATEDCASEID)<>checksum(D.OFFICIALNUMBER, D.COUNTRYCODE, D.RELATEDCASEID))
																	THEN 'O'
			 				WHEN(isnull(R.PRIORITYDATE,"+@sRule+")=0 and checksum(L.PRIORITYDATE)<>checksum(D.PRIORITYDATE)) THEN 'O'
							-- Supervisor review is required
							-- if live value is to change and derived events effected
							WHEN(X.CASEID is not null and isnull(R.OFFICIALNUMBER,"+@sRule+")=6 and checksum(L.OFFICIALNUMBER, L.COUNTRYCODE, L.RELATEDCASEID)<>checksum(D.OFFICIALNUMBER, D.COUNTRYCODE, D.RELATEDCASEID))
																	THEN 'S'
							WHEN(X.CASEID is not null and isnull(R.PRIORITYDATE,"+@sRule+")=6    and checksum(L.PRIORITYDATE)<>checksum(D.PRIORITYDATE))
																	THEN 'S'
							-- Supervisor review is required
							-- if live value is not null and about to change
							WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+")=8 and L.OFFICIALNUMBER<>isnull(D.OFFICIALNUMBER,'')) THEN 'S'
							WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+")=8 and L.COUNTRYCODE   <>isnull(D.COUNTRYCODE,''))    THEN 'S'
							WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+")=8 and L.RELATEDCASEID <>isnull(D.RELATEDCASEID,''))  THEN 'S'
							WHEN(isnull(R.PRIORITYDATE,"+@sRule+")=8    and L.PRIORITYDATE  <>isnull(D.PRIORITYDATE,''))   THEN 'S'
						End
						From #TEMPCASEMATCH T
						join RELATEDCASE D		on (D.CASEID=T.DRAFTCASEID)
						left join RELATEDCASE L		on (L.CASEID=T.LIVECASEID
										and L.RELATIONSHIP=D.RELATIONSHIP
										and(L.COUNTRYCODE=D.COUNTRYCODE or L.RELATIONSHIP<>'DC1' or D.CASEID is null) -- Designated Countries must match on Country							
										and isnull(L.RELATEDCASEID,'') =isnull(D.RELATEDCASEID,'')
										and isnull(L.OFFICIALNUMBER,'')=isnull(D.OFFICIALNUMBER,''))
						left join EDERULERELATEDCASE R	on (R.CRITERIANO=T.AMENDCASERULE
										and R.RELATIONSHIP=D.RELATIONSHIP)
						-- derived events do not match
						left join #TEMPDERIVEDEVENTCHANGED X
										on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('O','X'))
						Where T.AMENDCASERULE=@nRuleNo
						and V.TRANSACTIONIDENTIFIER is null
						and L.CASEID is null
						and ((isnull(R.OFFICIALNUMBER,"+@sRule+")=0)	
							   or(isnull(R.OFFICIALNUMBER,"+@sRule+")=6 and X.CASEID is not null)
						 OR  D.PRIORITYDATE is not null
							and( (isnull(R.PRIORITYDATE,"+@sRule+")=0)	
							   or(isnull(R.PRIORITYDATE,"+@sRule+")=6 and X.CASEID is not null) ) )"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End

					--------------
					-- CASENAME --
					--------------
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Insert into #TEMPREVIEW(TRANSACTIONIDENTIFIER,DRAFTCASEID,REVIEWTYPE)
						Select	distinct 
							T.TRANSACTIONIDENTIFIER, T.DRAFTCASEID,
							-- Operator review is required
							-- for partial match cases.
						CASE	WHEN(T.MATCHLEVEL=3253)	THEN 'O'
							-- Operator review is required
							-- if any data item is to change
							WHEN(isnull(R.NAMENO,"+@sRule+")=0         and checksum(L.NAMENO)        <>checksum(D.NAMENO))         THEN 'O'
			 				WHEN(isnull(R.CORRESPONDNAME,"+@sRule+")=0 and checksum(L.CORRESPONDNAME)<>checksum(D.CORRESPONDNAME)) THEN 'O'
			 				WHEN(isnull(R.REFERENCENO,"+@sRule+")=0    and checksum(L.REFERENCENO)   <>checksum(D.REFERENCENO))    THEN 'O'
							-- Operator review is required
							-- if Name is changing so that the Family of the names is different
							-- Note that any nulls are to be treated as a mismatch
							WHEN(isnull(R.NAMENO,"+@sRule+")=5 and checksum(isnull(NL.FAMILYNO,''))<>checksum(ND.FAMILYNO)) THEN 'O'
							-- Supervisor review is required
							-- if live value is to change and derived events effected
							WHEN(X.CASEID is not null and isnull(R.NAMENO,"+@sRule+")=6         and checksum(L.NAMENO)        <>checksum(D.NAMENO))        THEN 'S'
							WHEN(X.CASEID is not null and isnull(R.CORRESPONDNAME,"+@sRule+")=6 and checksum(L.CORRESPONDNAME)<>checksum(D.CORRESPONDNAME))THEN 'S'
							WHEN(X.CASEID is not null and isnull(R.REFERENCENO,"+@sRule+")=6    and checksum(L.REFERENCENO)   <>checksum(D.REFERENCENO))   THEN 'S'
							-- Supervisor review is required
							-- if live value is not null and about to change
							WHEN(isnull(R.NAMENO,"+@sRule+")=8         and L.NAMENO	      <>isnull(D.NAMENO,''))        THEN 'S'
							WHEN(isnull(R.CORRESPONDNAME,"+@sRule+")=8 and L.CORRESPONDNAME<>isnull(D.CORRESPONDNAME,''))THEN 'S'
							WHEN(isnull(R.REFERENCENO,"+@sRule+")=8    and L.REFERENCENO   <>isnull(D.REFERENCENO,''))   THEN 'S'
						End
						From #TEMPCASEMATCH T
						join CASENAME L		on (L.CASEID=T.LIVECASEID)
						-- To get the Family of the live Name
						join NAME NL		on (NL.NAMENO=L.NAMENO)
						join CASENAME D		on (D.CASEID=T.DRAFTCASEID
									and D.NAMETYPE=L.NAMETYPE
									and D.SEQUENCE=L.SEQUENCE)
						-- To get the Family of the draft Name
						join NAME ND		on (ND.NAMENO=D.NAMENO)
						left join EDERULECASENAME R on (R.CRITERIANO=T.AMENDCASERULE
									    and R.NAMETYPE  =L.NAMETYPE)
						-- derived events do not match
						left join #TEMPDERIVEDEVENTCHANGED X
									on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('O','X'))
						Where T.AMENDCASERULE=@nRuleNo
						and V.TRANSACTIONIDENTIFIER is null
						and((checksum(L.NAMENO)<>checksum(D.NAMENO)  
							and( (isnull(R.NAMENO,"+@sRule+")=0 and D.NAMENO is not null)
							   or(isnull(R.NAMENO,"+@sRule+")=5 and checksum(isnull(NL.FAMILYNO,''))<>checksum(ND.FAMILYNO))
							   or(isnull(R.NAMENO,"+@sRule+")=8 and L.NAMENO is not null)
							   or(isnull(R.NAMENO,"+@sRule+")=6 and X.CASEID is not null) ) )
						OR  (checksum(L.REFERENCENO)<>checksum(D.REFERENCENO)  
							and( (isnull(R.REFERENCENO,"+@sRule+")=0)	
							   or(isnull(R.REFERENCENO,"+@sRule+")=9 and L.REFERENCENO is not null)
							   or(isnull(R.REFERENCENO,"+@sRule+")=6 and X.CASEID is not null) ) )
						OR  (checksum(L.CORRESPONDNAME)<>checksum(D.CORRESPONDNAME)  
							and( (isnull(R.CORRESPONDNAME,"+@sRule+")=0)
							   or(isnull(R.CORRESPONDNAME,"+@sRule+")=8 and L.CORRESPONDNAME is not null)
							   or(isnull(R.CORRESPONDNAME,"+@sRule+")=6 and X.CASEID is not null) ) ) )"
					
						Exec @nErrorCode=sp_executesql @sSQLString,
										N'@nRuleNo	int',
										  @nRuleNo=@nRuleNo
					End
				
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Insert into #TEMPREVIEW(TRANSACTIONIDENTIFIER,DRAFTCASEID,REVIEWTYPE)
						Select	distinct
							T.TRANSACTIONIDENTIFIER, T.DRAFTCASEID,
							-- Operator review is required
							-- for partial match cases.
						CASE	WHEN(T.MATCHLEVEL=3253)	THEN 'O'
							-- Operator review is required
							-- if any data item is to change
							WHEN(isnull(R.NAMENO,"+@sRule+")=0)						THEN 'O'
			 				WHEN(isnull(R.CORRESPONDNAME,"+@sRule+")=0 and D.CORRESPONDNAME is not null)	THEN 'O'
			 				WHEN(isnull(R.REFERENCENO,"+@sRule+")=0    and D.REFERENCENO is not null)	THEN 'O'
							-- Supervisor review is required
							-- if live value is to change and derived events effected
							WHEN(X.CASEID is not null and isnull(R.NAMENO,"+@sRule+")=6)						THEN 'S'
							WHEN(X.CASEID is not null and isnull(R.CORRESPONDNAME,"+@sRule+")=6 and D.CORRESPONDNAME is not null)	THEN 'S'
							WHEN(X.CASEID is not null and isnull(R.REFERENCENO,"+@sRule+")=6    and D.REFERENCENO is not null)	THEN 'S'
						End
						From #TEMPCASEMATCH T
						join CASENAME D		on (D.CASEID=T.DRAFTCASEID)
						-- Check that matching Live name does not exist
						-- as this is handled in previous statement
						left join CASENAME L	on (L.CASEID=T.LIVECASEID
									and L.NAMETYPE=D.NAMETYPE
									and L.SEQUENCE=D.SEQUENCE)
						left join EDERULECASENAME R on (R.CRITERIANO=T.AMENDCASERULE
									    and R.NAMETYPE  =L.NAMETYPE)
						-- derived events do not match
						left join #TEMPDERIVEDEVENTCHANGED X
									on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('O','X'))
						Where T.AMENDCASERULE=@nRuleNo
						and V.TRANSACTIONIDENTIFIER is null
						and L.CASEID is null
						and((checksum(L.NAMENO)<>checksum(D.NAMENO)  
							and( (isnull(R.NAMENO,"+@sRule+")=0 and D.NAMENO is not null)
							   or(isnull(R.NAMENO,"+@sRule+")=6 and X.CASEID is not null) ) )
						OR  (checksum(L.REFERENCENO)<>checksum(D.REFERENCENO)  
							and( (isnull(R.REFERENCENO,"+@sRule+")=0)
							   or(isnull(R.REFERENCENO,"+@sRule+")=6 and X.CASEID is not null) ) )
						OR  (checksum(L.CORRESPONDNAME)<>checksum(D.CORRESPONDNAME)  
							and( (isnull(R.CORRESPONDNAME,"+@sRule+")=0)
							   or(isnull(R.CORRESPONDNAME,"+@sRule+")=6 and X.CASEID is not null) ) ) )"
					
						Exec @nErrorCode=sp_executesql @sSQLString,
										N'@nRuleNo	int',
										  @nRuleNo=@nRuleNo
					End

					---------------------------------------------------------------------------
					-- End of check for Operator/Supervisor Review or Whole Case Amend blocked.
					---------------------------------------------------------------------------

					-------------------------------------------------------------------------------
					-------------------------------------------------------------------------------
					-- Apply the Amend Case rules to the live cases if the rules allow it.  This is
					-- despite some rules requiring operator or supervisor review.
					-------------------------------------------------------------------------------

					---------------------------------------------------------------------------------
					-- Action  Description
					-- ------  ----------------------------------------------------------------------
					--   0	   Automatic update not allowed
					--	   Change Transaction Status to ‘Operator Review’
					---------------------------------------------------------------------------------
					--   1	   Automatic update for new or amended data
					--	   Update the field on live case unless the draft value is null.
					---------------------------------------------------------------------------------
					--   2     Ignore. Field is not applicable for the criteria. For eg. Entity Size 
					--	   would be ignored for Trademark rule.
					---------------------------------------------------------------------------------
					--   3	   Automatic update if live field empty.
					--	   Update the field on live case only if it is currently null.
					---------------------------------------------------------------------------------
					--   4	   Automatic update always regardless of live value 
					--	   (NOTE: will delete existing value if reporting a blank).
					--	   Update the live field. If draft value is null, then this may result 
					--	   in deletion of a case name, number type, event etc.
					---------------------------------------------------------------------------------
					--   5	   If name is changing within a group then automatically update, 
					--	   otherwise operator review required.
					--	   Only applies to case names.
					---------------------------------------------------------------------------------
					--   6	   Automatic update for new and amended data only if derived events are 
					--	   not impacted. Otherwise Supervisor Approval required.
					--	   Change Transaction Status to ‘Supervisor Approval’, unless Operator 
					--	   review required.
					---------------------------------------------------------------------------------
					--   8	   Automatic update if live field is empty. If existing value is changing 
					--	   supervisor approval required.
					--	   Change Transaction Status to ‘Supervisor Approval’, unless Operator 
					--	   review required.
					---------------------------------------------------------------------------------

					----------------------------------------
					-- Save the current system date and time
					-- so this can be used for checking the 
					-- log tables for changes applied to the
					-- database.
					----------------------------------------
					Set @dtLogDateTime=getdate()

					-----------
					-- CASES --
					-----------
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Update CASES
						Set
						CASETYPE=CASE	WHEN(isnull(R.CASETYPE,"+@sRule+")=1 and D.CASETYPE is not null)	THEN isnull(CT.ACTUALCASETYPE,D.CASETYPE)
								WHEN(isnull(R.CASETYPE,"+@sRule+") in (3,8) and L.CASETYPE is null)	THEN isnull(CT.ACTUALCASETYPE,D.CASETYPE)
								WHEN(isnull(R.CASETYPE,"+@sRule+")=4)					THEN isnull(CT.ACTUALCASETYPE,D.CASETYPE)
								WHEN(isnull(R.CASETYPE,"+@sRule+")=6 and X.CASEID is null)		THEN isnull(CT.ACTUALCASETYPE,D.CASETYPE)
														ELSE L.CASETYPE
							 END,
						PROPERTYTYPE=
							CASE 	WHEN(isnull(R.PROPERTYTYPE,"+@sRule+")=1 and D.PROPERTYTYPE is not null)THEN D.PROPERTYTYPE
								WHEN(isnull(R.PROPERTYTYPE,"+@sRule+") in (3,8) and L.PROPERTYTYPE is null)THEN D.PROPERTYTYPE
								WHEN(isnull(R.PROPERTYTYPE,"+@sRule+")=4)				THEN D.PROPERTYTYPE
								WHEN(isnull(R.PROPERTYTYPE,"+@sRule+")=6 and X.CASEID is null)		THEN D.PROPERTYTYPE
								WHEN(isnull(R.PROPERTYTYPE,"+@sRule+")=8 and L.PROPERTYTYPE is null)	THEN D.PROPERTYTYPE
															ELSE L.PROPERTYTYPE
							 END,
						COUNTRYCODE=
							CASE 	WHEN(isnull(R.COUNTRY,"+@sRule+")=1 and D.COUNTRYCODE is not null)	THEN D.COUNTRYCODE
								WHEN(isnull(R.COUNTRY,"+@sRule+") in (3,8) and L.COUNTRYCODE is null)	THEN D.COUNTRYCODE
								WHEN(isnull(R.COUNTRY,"+@sRule+")=4)					THEN D.COUNTRYCODE
								WHEN(isnull(R.COUNTRY,"+@sRule+")=6 and X.CASEID is null)		THEN D.COUNTRYCODE
														ELSE L.COUNTRYCODE
							 END,
						CASECATEGORY=
							CASE 	WHEN(isnull(R.CATEGORY,"+@sRule+")=1 and D.CASECATEGORY is not null)	THEN D.CASECATEGORY
								WHEN(isnull(R.CATEGORY,"+@sRule+") in (3,8) and L.CASECATEGORY is null)	THEN D.CASECATEGORY
								WHEN(isnull(R.CATEGORY,"+@sRule+")=4)					THEN D.CASECATEGORY
								WHEN(isnull(R.CATEGORY,"+@sRule+")=6 and X.CASEID is null)		THEN D.CASECATEGORY
														ELSE L.CASECATEGORY
							 END,
						SUBTYPE=
							CASE 	WHEN(isnull(R.SUBTYPE,"+@sRule+")=1 and D.SUBTYPE is not null)		THEN D.SUBTYPE
								WHEN(isnull(R.SUBTYPE,"+@sRule+") in (3,8) and L.SUBTYPE is null)	THEN D.SUBTYPE
								WHEN(isnull(R.SUBTYPE,"+@sRule+")=4)					THEN D.SUBTYPE
								WHEN(isnull(R.SUBTYPE,"+@sRule+")=6 and X.CASEID is null)		THEN D.SUBTYPE
														ELSE L.SUBTYPE
							 END,
						ENTITYSIZE=
							CASE 	WHEN(isnull(R.ENTITYSIZE,"+@sRule+")=1 and D.ENTITYSIZE is not null)	THEN D.ENTITYSIZE
								WHEN(isnull(R.ENTITYSIZE,"+@sRule+") in (3,8) and L.ENTITYSIZE is null)	THEN D.ENTITYSIZE
								WHEN(isnull(R.ENTITYSIZE,"+@sRule+")=4)					THEN D.ENTITYSIZE
								WHEN(isnull(R.ENTITYSIZE,"+@sRule+")=6 and X.CASEID is null)		THEN D.ENTITYSIZE
															ELSE L.ENTITYSIZE
							 END,
						TYPEOFMARK=
							CASE 	WHEN(isnull(R.TYPEOFMARK,"+@sRule+")=1 and D.TYPEOFMARK is not null)	THEN D.TYPEOFMARK
								WHEN(isnull(R.TYPEOFMARK,"+@sRule+") in (3,8) and L.TYPEOFMARK is null)	THEN D.TYPEOFMARK
								WHEN(isnull(R.TYPEOFMARK,"+@sRule+")=4)					THEN D.TYPEOFMARK
								WHEN(isnull(R.TYPEOFMARK,"+@sRule+")=6 and X.CASEID is null)		THEN D.TYPEOFMARK
															ELSE L.TYPEOFMARK
							 END,
						NOINSERIES=
							CASE 	WHEN(isnull(R.NUMBEROFDESIGNS,"+@sRule+")=1 and D.ENTITYSIZE is not null)	THEN D.NOINSERIES
								WHEN(isnull(R.NUMBEROFDESIGNS,"+@sRule+") in (3,8) and L.ENTITYSIZE is null)	THEN D.NOINSERIES
								WHEN(isnull(R.NUMBEROFDESIGNS,"+@sRule+")=4)					THEN D.NOINSERIES
								WHEN(isnull(R.NUMBEROFDESIGNS,"+@sRule+")=6 and X.CASEID is null)		THEN D.NOINSERIES
															 ELSE L.NOINSERIES
							 END,
						EXTENDEDRENEWALS=
							CASE 	WHEN(isnull(R.NUMBEROFYEARSEXT,"+@sRule+")=1 and D.EXTENDEDRENEWALS is not null)	THEN D.EXTENDEDRENEWALS
								WHEN(isnull(R.NUMBEROFYEARSEXT,"+@sRule+") in (3,8) and L.EXTENDEDRENEWALS is null)	THEN D.EXTENDEDRENEWALS
								WHEN(isnull(R.NUMBEROFYEARSEXT,"+@sRule+")=4)						THEN D.EXTENDEDRENEWALS
								WHEN(isnull(R.NUMBEROFYEARSEXT,"+@sRule+")=6 and X.CASEID is null)			THEN D.EXTENDEDRENEWALS
																ELSE L.EXTENDEDRENEWALS
							 END,
						STOPPAYREASON=
							CASE 	WHEN(isnull(R.STOPPAYREASON,"+@sRule+")=1 and D.STOPPAYREASON is not null)	THEN D.STOPPAYREASON
								WHEN(isnull(R.STOPPAYREASON,"+@sRule+") in (3,8) and L.STOPPAYREASON is null)	THEN D.STOPPAYREASON
								WHEN(isnull(R.STOPPAYREASON,"+@sRule+")=4)					THEN D.STOPPAYREASON
								WHEN(isnull(R.STOPPAYREASON,"+@sRule+")=6 and X.CASEID is null)			THEN D.STOPPAYREASON
																ELSE L.STOPPAYREASON
							 END,
						TITLE=
							CASE 	WHEN(isnull(R.SHORTTITLE,"+@sRule+")=1 and D.TITLE is not null)		THEN D.TITLE
								WHEN(isnull(R.SHORTTITLE,"+@sRule+") in (3,8) and L.TITLE is null)	THEN D.TITLE
								WHEN(isnull(R.SHORTTITLE,"+@sRule+")=4)					THEN D.TITLE
								WHEN(isnull(R.SHORTTITLE,"+@sRule+")=6 and X.CASEID is null)		THEN D.TITLE
															ELSE L.TITLE
							 END,
						LOCALCLASSES=
							CASE 	WHEN(isnull(R.CLASSES,"+@sRule+")=1 and D.LOCALCLASSES is not null)	THEN D.LOCALCLASSES
								WHEN(isnull(R.CLASSES,"+@sRule+") in (3,8) and L.LOCALCLASSES is null)	THEN D.LOCALCLASSES
								WHEN(isnull(R.CLASSES,"+@sRule+")=4)					THEN D.LOCALCLASSES
								WHEN(isnull(R.CLASSES,"+@sRule+")=6 and X.CASEID is null)		THEN D.LOCALCLASSES
															ELSE L.LOCALCLASSES
							 END,
						INTCLASSES=
							CASE 	WHEN(isnull(R.CLASSES,"+@sRule+")=1 and D.INTCLASSES is not null)	THEN D.INTCLASSES
								WHEN(isnull(R.CLASSES,"+@sRule+") in (3,8) and L.INTCLASSES is null)	THEN D.INTCLASSES
								WHEN(isnull(R.CLASSES,"+@sRule+")=4)					THEN D.INTCLASSES
								WHEN(isnull(R.CLASSES,"+@sRule+")=6 and X.CASEID is null)		THEN D.INTCLASSES
															ELSE L.INTCLASSES
							 END
						From CASES L
						join #TEMPCASEMATCH T	on (T.LIVECASEID=L.CASEID)
						left join EDERULECASE R	on (R.CRITERIANO=T.AMENDCASERULE)
						join (select *
						      from CASES) D	on (D.CASEID=T.DRAFTCASEID)
						join CASETYPE CT	on (CT.CASETYPE=D.CASETYPE)
						-- derived events do not match
						left join #TEMPDERIVEDEVENTCHANGED X
									on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('X'))				
						Where T.AMENDCASERULE=@nRuleNo
						and V.TRANSACTIONIDENTIFIER is null
						and((checksum(L.CASETYPE)<>checksum(isnull(CT.ACTUALCASETYPE,D.CASETYPE))  
							and( (isnull(R.CASETYPE,"+@sRule+")=1 and D.CASETYPE is not null)	
							   or(isnull(R.CASETYPE,"+@sRule+") in (3,8) and L.CASETYPE is null)
							   or(isnull(R.CASETYPE,"+@sRule+")=4)
							   or(isnull(R.CASETYPE,"+@sRule+")=6 and X.CASEID is null) ) )
						 OR (checksum(L.PROPERTYTYPE)<>checksum(D.PROPERTYTYPE)  
							and( (isnull(R.PROPERTYTYPE,"+@sRule+")=1 and D.PROPERTYTYPE is not null)	
							   or(isnull(R.PROPERTYTYPE,"+@sRule+") in (3,8) and L.PROPERTYTYPE is null)
							   or(isnull(R.PROPERTYTYPE,"+@sRule+")=4)
							   or(isnull(R.PROPERTYTYPE,"+@sRule+")=6 and X.CASEID is null) ) )
						 OR (checksum(L.COUNTRYCODE)<>checksum(D.COUNTRYCODE)  
							and( (isnull(R.COUNTRY,"+@sRule+")=1 and D.COUNTRYCODE is not null)	
							   or(isnull(R.COUNTRY,"+@sRule+") in (3,8) and L.COUNTRYCODE is null)
							   or(isnull(R.COUNTRY,"+@sRule+")=4)
							   or(isnull(R.COUNTRY,"+@sRule+")=6 and X.CASEID is null) ) )
						 OR (checksum(L.CASECATEGORY)<>checksum(D.CASECATEGORY)  
							and( (isnull(R.CATEGORY,"+@sRule+")=1 and D.CASECATEGORY is not null)	
							   or(isnull(R.CATEGORY,"+@sRule+") in (3,8) and L.CASECATEGORY is null)
							   or(isnull(R.CATEGORY,"+@sRule+")=4)
							   or(isnull(R.CATEGORY,"+@sRule+")=6 and X.CASEID is null) ) )
						 OR (checksum(L.SUBTYPE)<>checksum(D.SUBTYPE)  
							and( (isnull(R.SUBTYPE,"+@sRule+")=1 and D.SUBTYPE is not null)	
							   or(isnull(R.SUBTYPE,"+@sRule+") in (3,8) and L.SUBTYPE is null)
							   or(isnull(R.SUBTYPE,"+@sRule+")=4)
							   or(isnull(R.SUBTYPE,"+@sRule+")=6 and X.CASEID is null) ) )
						 OR (checksum(L.ENTITYSIZE)<>checksum(D.ENTITYSIZE)  
							and( (isnull(R.ENTITYSIZE,"+@sRule+")=1 and D.ENTITYSIZE is not null)	
							   or(isnull(R.ENTITYSIZE,"+@sRule+") in (3,8) and L.ENTITYSIZE is null)
							   or(isnull(R.ENTITYSIZE,"+@sRule+")=4)
							   or(isnull(R.ENTITYSIZE,"+@sRule+")=6 and X.CASEID is null) ) )
						 OR (checksum(L.TYPEOFMARK)<>checksum(D.TYPEOFMARK)  
							and( (isnull(R.TYPEOFMARK,"+@sRule+")=1 and D.TYPEOFMARK is not null)	
							   or(isnull(R.TYPEOFMARK,"+@sRule+") in (3,8) and L.TYPEOFMARK is null)
							   or(isnull(R.TYPEOFMARK,"+@sRule+")=4)
							   or(isnull(R.TYPEOFMARK,"+@sRule+")=6 and X.CASEID is null) ) )
						 OR (checksum(L.NOINSERIES)<>checksum(D.NOINSERIES)  
							and( (isnull(R.NUMBEROFDESIGNS,"+@sRule+")=1 and D.NOINSERIES is not null)	
							   or(isnull(R.NUMBEROFDESIGNS,"+@sRule+") in (3,8) and L.NOINSERIES is null)
							   or(isnull(R.NUMBEROFDESIGNS,"+@sRule+")=4)
							   or(isnull(R.NUMBEROFDESIGNS,"+@sRule+")=6 and X.CASEID is null) ) )
						 OR (checksum(L.EXTENDEDRENEWALS)<>checksum(D.EXTENDEDRENEWALS)  
							and( (isnull(R.NUMBEROFYEARSEXT,"+@sRule+")=1 and D.EXTENDEDRENEWALS is not null)	
							   or(isnull(R.NUMBEROFYEARSEXT,"+@sRule+") in (3,8) and L.EXTENDEDRENEWALS is null)
							   or(isnull(R.NUMBEROFYEARSEXT,"+@sRule+")=4)
							   or(isnull(R.NUMBEROFYEARSEXT,"+@sRule+")=6 and X.CASEID is null) ) )
						 OR (checksum(L.STOPPAYREASON)<>checksum(D.STOPPAYREASON)  
							and( (isnull(R.STOPPAYREASON,"+@sRule+")=1 and D.STOPPAYREASON is not null)	
							   or(isnull(R.STOPPAYREASON,"+@sRule+") in (3,8) and L.STOPPAYREASON is null)
							   or(isnull(R.STOPPAYREASON,"+@sRule+")=4)
							   or(isnull(R.STOPPAYREASON,"+@sRule+")=6 and X.CASEID is null) ) )
						 OR (checksum(L.TITLE)<>checksum(D.TITLE)  
							and( (isnull(R.SHORTTITLE,"+@sRule+")=1 and D.TITLE is not null)	
							   or(isnull(R.SHORTTITLE,"+@sRule+") in (3,8) and L.TITLE is null)
							   or(isnull(R.SHORTTITLE,"+@sRule+")=4)
							   or(isnull(R.SHORTTITLE,"+@sRule+")=6 and X.CASEID is null) ) )
						 OR (checksum(L.LOCALCLASSES)<>checksum(D.LOCALCLASSES)  
							and( (isnull(R.CLASSES,"+@sRule+")=1 and D.LOCALCLASSES is not null)	
							   or(isnull(R.CLASSES,"+@sRule+") in (3,8) and L.LOCALCLASSES is null)
							   or(isnull(R.CLASSES,"+@sRule+")=4)
							   or(isnull(R.CLASSES,"+@sRule+")=6 and X.CASEID is null) ) )
						 OR (checksum(L.INTCLASSES)<>checksum(D.INTCLASSES)  
							and( (isnull(R.CLASSES,"+@sRule+")=1 and D.INTCLASSES is not null)	
							   or(isnull(R.CLASSES,"+@sRule+") in (3,8) and L.INTCLASSES is null)
							   or(isnull(R.CLASSES,"+@sRule+")=4)
							   or(isnull(R.CLASSES,"+@sRule+")=6 and X.CASEID is null) ) ) )"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End

					--------------------------------------
					-- If Stop Pay Reason is provided, and
					-- automatic update cannot proceed,
					-- then raise an issue : "Cancellation
					-- Instruction Not Processed"
					--------------------------------------
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, CASEID, DATECREATED)
						Select -31, @pnBatchNo, T.TRANSACTIONIDENTIFIER, T.DRAFTCASEID, getdate()
						From CASES L
						join #TEMPCASEMATCH T	on (T.LIVECASEID=L.CASEID)
						left join EDERULECASE R	on (R.CRITERIANO=T.AMENDCASERULE)
						join CASES D		on (D.CASEID=T.DRAFTCASEID)
						left join EDEOUTSTANDINGISSUES I on (I.ISSUEID=-31
										 and I.BATCHNO=@pnBatchNo
										 and I.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('X'))				
						Where T.AMENDCASERULE=@nRuleNo
						and V.TRANSACTIONIDENTIFIER is null
						and isnull(L.STOPPAYREASON,'')<>D.STOPPAYREASON -- Stop Pay Reason trying to be set
						and isnull(R.STOPPAYREASON,"+@sRule+") in (0,2) -- automatic update not allowed
						and I.ISSUEID is null -- do not insert a duplicate"
				
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@pnBatchNo	int,
									  @nRuleNo	int',
									  @pnBatchNo=@pnBatchNo,
									  @nRuleNo  =@nRuleNo
					End

					--------------
					-- PROPERTY --
					--------------
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Update PROPERTY
						Set
						BASIS=	CASE	WHEN(isnull(R.BASIS,"+@sRule+")=1 and D.BASIS is not null)	THEN D.BASIS
								WHEN(isnull(R.BASIS,"+@sRule+") in (3,8) and L.BASIS is null)	THEN D.BASIS
								WHEN(isnull(R.BASIS,"+@sRule+")=4)				THEN D.BASIS
								WHEN(isnull(R.BASIS,"+@sRule+")=6 and X.CASEID is null)		THEN D.BASIS
														ELSE L.BASIS
							 END,
						NOOFCLAIMS=
							CASE	WHEN(isnull(R.NUMBEROFCLAIMS,"+@sRule+")=1 and D.NOOFCLAIMS is not null)	THEN D.NOOFCLAIMS
								WHEN(isnull(R.NUMBEROFCLAIMS,"+@sRule+") in (3,8) and L.NOOFCLAIMS is null)	THEN D.NOOFCLAIMS
								WHEN(isnull(R.NUMBEROFCLAIMS,"+@sRule+")=4)					THEN D.NOOFCLAIMS
								WHEN(isnull(R.NUMBEROFCLAIMS,"+@sRule+")=6 and X.CASEID is null)		THEN D.NOOFCLAIMS
															ELSE L.NOOFCLAIMS
							 END
						From PROPERTY L
						join #TEMPCASEMATCH T	on (T.LIVECASEID=L.CASEID)
						left join EDERULECASE R	on (R.CRITERIANO=T.AMENDCASERULE)
						join (select *
						      from PROPERTY) D	on (D.CASEID=T.DRAFTCASEID)
						-- derived events do not match
						left join #TEMPDERIVEDEVENTCHANGED X
									on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('X'))				
						Where T.AMENDCASERULE=@nRuleNo
						and V.TRANSACTIONIDENTIFIER is null
						and((checksum(L.BASIS)<>checksum(D.BASIS)  
							and( (isnull(R.BASIS,"+@sRule+")=1 and D.BASIS is not null)	
							   or(isnull(R.BASIS,"+@sRule+") in (3,8) and L.BASIS is null)
							   or(isnull(R.BASIS,"+@sRule+")=4)
							   or(isnull(R.BASIS,"+@sRule+")=6 and X.CASEID is null) ) )
						 OR (checksum(L.NOOFCLAIMS)<>checksum(D.NOOFCLAIMS)  
							and( (isnull(R.NUMBEROFCLAIMS,"+@sRule+")=1 and D.NOOFCLAIMS is not null)	
							   or(isnull(R.NUMBEROFCLAIMS,"+@sRule+") in (3,8) and L.NOOFCLAIMS is null)
							   or(isnull(R.NUMBEROFCLAIMS,"+@sRule+")=4)
							   or(isnull(R.NUMBEROFCLAIMS,"+@sRule+")=6 and X.CASEID is null) ) ))"	
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End

					If @nErrorCode=0
					Begin
						-----------------------------------
						-- Insert the Property if it 
						-- does not exist on the live case
						-- but exists on Draft Case.
						-----------------------------------
						Set @sSQLString="
						Insert into PROPERTY (CASEID,BASIS,NOOFCLAIMS)
						Select 	T.LIVECASEID,
							CASE	WHEN(isnull(R.BASIS,"+@sRule+")=1 and D.BASIS is not null)	THEN D.BASIS
								WHEN(isnull(R.BASIS,"+@sRule+") in (3,8) and L.BASIS is null)	THEN D.BASIS
								WHEN(isnull(R.BASIS,"+@sRule+")=4)				THEN D.BASIS
								WHEN(isnull(R.BASIS,"+@sRule+")=6 and X.CASEID is null)		THEN D.BASIS
														ELSE L.BASIS
							END,
							CASE	WHEN(isnull(R.NUMBEROFCLAIMS,"+@sRule+")=1 and D.NOOFCLAIMS is not null)	THEN D.NOOFCLAIMS
								WHEN(isnull(R.NUMBEROFCLAIMS,"+@sRule+") in (3,8) and L.NOOFCLAIMS is null)	THEN D.NOOFCLAIMS
								WHEN(isnull(R.NUMBEROFCLAIMS,"+@sRule+")=4)					THEN D.NOOFCLAIMS
								WHEN(isnull(R.NUMBEROFCLAIMS,"+@sRule+")=6 and X.CASEID is null)		THEN D.NOOFCLAIMS
															ELSE L.NOOFCLAIMS
							 END
						From #TEMPCASEMATCH T
						left join EDERULECASE R	on (R.CRITERIANO=T.AMENDCASERULE)
						join PROPERTY D		on (D.CASEID=T.DRAFTCASEID)
						left join PROPERTY L	on (L.CASEID=T.LIVECASEID)
						-- derived events do not match
						left join #TEMPDERIVEDEVENTCHANGED X
										on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('X'))				
						Where T.AMENDCASERULE=@nRuleNo
						and V.TRANSACTIONIDENTIFIER is null
						and T.LIVECASEID is not null
						and L.CASEID is null"	
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End

					---------------------
					-- OFFICIALNUMBERS --
					---------------------
					If @nErrorCode=0
					Begin
						---------------------------------------
						-- Update the existing current official
						-- number for the Number Type.
						-- Restricted to IP Office numbers.
						---------------------------------------

						Set @sSQLString="
						Update OFFICIALNUMBERS
						Set
						ISCURRENT=
							CASE	WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+")=1 and D.OFFICIALNUMBER is not null)	THEN isnull(D.ISCURRENT,1)
								WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+") in (3,8) and L.OFFICIALNUMBER is null)	THEN isnull(D.ISCURRENT,1)
								WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+")=4)					THEN isnull(D.ISCURRENT,1)
								WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+")=6 and D.OFFICIALNUMBER is not null 
											and X.CASEID is null)			THEN isnull(D.ISCURRENT,1)
																ELSE L.ISCURRENT
							 END,
						DATEENTERED=coalesce(D.DATEENTERED, CE.EVENTDATE, L.DATEENTERED)
						From OFFICIALNUMBERS L
						join #TEMPCASEMATCH T		on (T.LIVECASEID=L.CASEID)
						left join EDERULEOFFICIALNUMBER R on (R.CRITERIANO=T.AMENDCASERULE
										and R.NUMBERTYPE=L.NUMBERTYPE)
						join (select *
						      from OFFICIALNUMBERS) D	on (D.CASEID=T.DRAFTCASEID
										and D.OFFICIALNUMBER=L.OFFICIALNUMBER
										and D.NUMBERTYPE=L.NUMBERTYPE)
						join NUMBERTYPES NT		on (NT.NUMBERTYPE=L.NUMBERTYPE	-- SQA18200
										and NT.ISSUEDBYIPOFFICE=1)
						left join CASEEVENT CE		on (CE.CASEID =L.CASEID
										and CE.EVENTNO=NT.RELATEDEVENTNO
										and CE.CYCLE  =1
										and CE.EVENTDATE is not null)
						-- derived events do not match
						left join #TEMPDERIVEDEVENTCHANGED X
										on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('X'))				
						Where T.AMENDCASERULE=@nRuleNo
						and   V.TRANSACTIONIDENTIFIER is null
						and  checksum(L.ISCURRENT)<>checksum(D.ISCURRENT)  
							and( (isnull(R.OFFICIALNUMBER,"+@sRule+")=1 and D.OFFICIALNUMBER is not null)	
							   or(isnull(R.OFFICIALNUMBER,"+@sRule+") in (3,8) and L.OFFICIALNUMBER is null)
							   or(isnull(R.OFFICIALNUMBER,"+@sRule+")=4)
							   or(isnull(R.OFFICIALNUMBER,"+@sRule+")=6 and D.OFFICIALNUMBER is not null and X.CASEID is null) )"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End
					
					If @nErrorCode=0
					Begin
						---------------------------------------
						-- Update the existing official number 
						-- row for number type that have not 
						-- been issued by and IP Office.
						---------------------------------------

						Set @sSQLString="
						Update L
						Set ISCURRENT     =isnull(D.ISCURRENT,1), 
						    OFFICIALNUMBER=D.OFFICIALNUMBER,
						    DATEENTERED   =D.DATEENTERED
						From OFFICIALNUMBERS L
						join #TEMPCASEMATCH T		on (T.LIVECASEID=L.CASEID)
						join EDERULEOFFICIALNUMBER R	on (R.CRITERIANO=T.AMENDCASERULE
										and R.NUMBERTYPE=L.NUMBERTYPE)
						join (select *
						      from OFFICIALNUMBERS) D	on (D.CASEID=T.DRAFTCASEID
										and D.NUMBERTYPE=L.NUMBERTYPE)
						join NUMBERTYPES NT		on (NT.NUMBERTYPE=L.NUMBERTYPE	-- SQA18200
										and isnull(NT.ISSUEDBYIPOFFICE,0)=0)
						join (select CASEID, NUMBERTYPE, count(*) as NUMBERTYPECOUNT
						      from OFFICIALNUMBERS
						      group by CASEID, NUMBERTYPE) L1	
										on (L1.CASEID=T.LIVECASEID
										and L1.NUMBERTYPE=L.NUMBERTYPE)
						-- derived events do not match
						left join #TEMPDERIVEDEVENTCHANGED X
										on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('X'))				
						Where T.AMENDCASERULE=@nRuleNo
						and   V.TRANSACTIONIDENTIFIER is null
						and((L.OFFICIALNUMBER=D.OFFICIALNUMBER and checksum(L.ISCURRENT)<>checksum(D.ISCURRENT))
						 OR (L.OFFICIALNUMBER<>D.OFFICIALNUMBER and L1.NUMBERTYPECOUNT=1))
						and  checksum(L.ISCURRENT,L.OFFICIALNUMBER)<>checksum(D.ISCURRENT,D.OFFICIALNUMBER)  
							and( (R.OFFICIALNUMBER=1 and D.OFFICIALNUMBER is not null)	
							   or(R.OFFICIALNUMBER in (3,8) and L.OFFICIALNUMBER is null)
							   or(R.OFFICIALNUMBER=4)
							   or(R.OFFICIALNUMBER=6 and D.OFFICIALNUMBER is not null and X.CASEID is null) )"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End

					If @nErrorCode=0
					Begin
						-----------------------------------
						-- Insert the Official Number if it 
						-- does not exist on the live case
						-----------------------------------
						Set @sSQLString="
						Insert into OFFICIALNUMBERS(CASEID, NUMBERTYPE, OFFICIALNUMBER, ISCURRENT, DATEENTERED)
						Select distinct T.LIVECASEID, D.NUMBERTYPE, D.OFFICIALNUMBER, isnull(D.ISCURRENT,1), D.DATEENTERED
						From #TEMPCASEMATCH T
						join OFFICIALNUMBERS D		on (D.CASEID=T.DRAFTCASEID)
						-- This number type does not already exist
						left join OFFICIALNUMBERS L	on (L.CASEID=T.LIVECASEID
										and L.NUMBERTYPE=D.NUMBERTYPE
										and L.ISCURRENT=1)
						-- This specific number does not already exist
						left join OFFICIALNUMBERS L1	on (L1.CASEID=T.LIVECASEID
										and L1.NUMBERTYPE=D.NUMBERTYPE
										and L1.OFFICIALNUMBER=D.OFFICIALNUMBER)
						left join EDERULEOFFICIALNUMBER R on (R.CRITERIANO=T.AMENDCASERULE
										 and  R.NUMBERTYPE=D.NUMBERTYPE)
						-- derived events do not match
						left join #TEMPDERIVEDEVENTCHANGED X
										on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('X'))				
						Where T.AMENDCASERULE=@nRuleNo
						and   V.TRANSACTIONIDENTIFIER is null
						and L1.CASEID is null
						and ((isnull(R.OFFICIALNUMBER,"+@sRule+")=1 and D.OFFICIALNUMBER is not null)	
						   or(isnull(R.OFFICIALNUMBER,"+@sRule+") in (3,8) and L.OFFICIALNUMBER is null)
						   or(isnull(R.OFFICIALNUMBER,"+@sRule+")=4)
						   or(isnull(R.OFFICIALNUMBER,"+@sRule+")=6 and X.CASEID is null) )"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End

					If @nErrorCode=0
					Begin
						------------------------------------
						-- Update the Official Number to set 
						-- its Current flag off if for that
						-- number type the draft Case just
						-- set a different row to be current
						------------------------------------
						Set @sSQLString="
						UPDATE OFFICIALNUMBERS
						Set ISCURRENT=0
						From OFFICIALNUMBERS L
						join NUMBERTYPES NT		on (NT.NUMBERTYPE=L.NUMBERTYPE	-- SQA18200
										and NT.ISSUEDBYIPOFFICE=1)
						join #TEMPCASEMATCH T		on (T.LIVECASEID=L.CASEID)
						-- the draft Case current official number
						join (select *
						      from OFFICIALNUMBERS) D	on (D.CASEID=T.DRAFTCASEID
										and D.NUMBERTYPE=L.NUMBERTYPE
										and D.OFFICIALNUMBER<>L.OFFICIALNUMBER
										and isnull(D.ISCURRENT,1)=1)
						-- the new Current Official Number
						join (select *
						      from OFFICIALNUMBERS) N	on (N.CASEID=L.CASEID
										and N.NUMBERTYPE=L.NUMBERTYPE
										and N.OFFICIALNUMBER=D.OFFICIALNUMBER
										and N.ISCURRENT=1)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('X'))				
						Where T.AMENDCASERULE=@nRuleNo
						and   V.TRANSACTIONIDENTIFIER is null
						and   L.ISCURRENT=1"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End

					If @nErrorCode=0
					Begin
						-----------------------------------
						-- Delete the Official Number if it 
						-- does not exist on the draft case
						-- and the rules says to Delete it.
						-----------------------------------
						Set @sSQLString="
						Delete OFFICIALNUMBERS
						from OFFICIALNUMBERS L
						join #TEMPCASEMATCH T		on (T.LIVECASEID=L.CASEID)
						join EDERULEOFFICIALNUMBER R	on (R.CRITERIANO=T.AMENDCASERULE
										and R.NUMBERTYPE=L.NUMBERTYPE)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('X'))				
						Where T.AMENDCASERULE=@nRuleNo
						and   V.TRANSACTIONIDENTIFIER is null
						and   R.OFFICIALNUMBER=4
						and not exists
						(select 1 from OFFICIALNUMBERS D
						 where D.CASEID=T.DRAFTCASEID
						 and D.NUMBERTYPE=L.NUMBERTYPE)"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End

					--------------
					-- CASETEXT --
					--------------
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Update CASETEXT
						Set
						SHORTTEXT=	
							CASE	WHEN(isnull(R.TEXT,"+@sRule+")=1 and isnull(D.TEXT,D.SHORTTEXT) is not null)	
														THEN D.SHORTTEXT
								WHEN(isnull(R.TEXT,"+@sRule+") in (3,8) and isnull(L.TEXT,L.SHORTTEXT) is null)	
														THEN D.SHORTTEXT
								WHEN(isnull(R.TEXT,"+@sRule+")=4)		THEN D.SHORTTEXT
								WHEN(isnull(R.TEXT,"+@sRule+")=6 and isnull(D.TEXT,D.SHORTTEXT) is not null 
											and X.CASEID is null)	THEN D.SHORTTEXT
														ELSE L.SHORTTEXT
							 END,
						TEXT=	CASE	WHEN(isnull(R.TEXT,"+@sRule+")=1 and isnull(D.TEXT,D.SHORTTEXT) is not null)	
														THEN D.TEXT
								WHEN(isnull(R.TEXT,"+@sRule+") in (3,8) and isnull(L.TEXT,L.SHORTTEXT) is null)	
														THEN D.TEXT
								WHEN(isnull(R.TEXT,"+@sRule+")=4)		THEN D.TEXT
								WHEN(isnull(R.TEXT,"+@sRule+")=6 and isnull(D.TEXT,D.SHORTTEXT) is not null 
											and X.CASEID is null)	THEN D.TEXT
														ELSE L.TEXT
							 END,
						LONGFLAG=CASE	WHEN(isnull(R.TEXT,"+@sRule+")=1 and isnull(D.TEXT,D.SHORTTEXT) is not null)	
														THEN D.LONGFLAG
								WHEN(isnull(R.TEXT,"+@sRule+") in (3,8) and isnull(L.TEXT,L.SHORTTEXT) is null)	
														THEN D.LONGFLAG
								WHEN(isnull(R.TEXT,"+@sRule+")=4)		THEN D.LONGFLAG
								WHEN(isnull(R.TEXT,"+@sRule+")=6 and isnull(D.TEXT,D.SHORTTEXT) is not null 
											and X.CASEID is null)	THEN D.LONGFLAG
														ELSE L.LONGFLAG
							 END,
						MODIFIEDDATE=getdate()
						From CASETEXT L
						join #TEMPCASEMATCH T	on (T.LIVECASEID=L.CASEID)
						left join EDERULECASETEXT R on(R.CRITERIANO=T.AMENDCASERULE
									and R.TEXTTYPE=L.TEXTTYPE)
						join (select *
						      from CASETEXT) D	on (D.CASEID=T.DRAFTCASEID
									and D.TEXTTYPE=L.TEXTTYPE
									and isnull(D.LANGUAGE,'')=isnull(L.LANGUAGE,'')
									and isnull(D.CLASS,'')   =isnull(L.CLASS,''))
						-- derived events do not match
						left join #TEMPDERIVEDEVENTCHANGED X
										on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('X'))				
						Where T.AMENDCASERULE=@nRuleNo
						and   V.TRANSACTIONIDENTIFIER is null
						and ( checksum(L.SHORTTEXT)<>checksum(D.SHORTTEXT) or checksum(datalength(L.TEXT))<>checksum(datalength(D.TEXT)) or L.TEXT not like D.TEXT)
							and( (isnull(R.TEXT,"+@sRule+")=1 and isnull(D.TEXT,D.SHORTTEXT) is not null)	
							   or(isnull(R.TEXT,"+@sRule+") in (3,8) and isnull(L.TEXT,L.SHORTTEXT) is null)
							   or(isnull(R.TEXT,"+@sRule+")=4)
							   or(isnull(R.TEXT,"+@sRule+")=6 and isnull(D.TEXT,D.SHORTTEXT) is not null and X.CASEID is null) )"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End

					If @nErrorCode=0
					Begin
						-----------------------------------
						-- Insert the Case Text if it 
						-- does not exist on the live case
						-----------------------------------
						Set @sSQLString="
						Insert into CASETEXT(CASEID,TEXTTYPE,TEXTNO,CLASS,LANGUAGE,MODIFIEDDATE,LONGFLAG,SHORTTEXT,TEXT)
						Select 	T.LIVECASEID, D.TEXTTYPE,
							isnull(MX.TEXTNO,-1)+1+D.TEXTNO,
							D.CLASS, D.LANGUAGE, getdate(), D.LONGFLAG, D.SHORTTEXT, D.TEXT
						From #TEMPCASEMATCH T
						join CASETEXT D		on (D.CASEID=T.DRAFTCASEID)
						left join CASETEXT L	on (L.CASEID=T.LIVECASEID
									and L.TEXTTYPE=D.TEXTTYPE
									and isnull(L.LANGUAGE,'')=isnull(D.LANGUAGE,'')
									and isnull(L.CLASS,'')   =isnull(D.CLASS,''))
						left join EDERULECASETEXT R	on (R.CRITERIANO=T.AMENDCASERULE
										and R.TEXTTYPE=D.TEXTTYPE)
						-- get the current highest TEXTNO against the live case
						left join (Select CASEID, max(TEXTNO) as TEXTNO
							   from CASETEXT
							   group by CASEID) MX	on (MX.CASEID=T.LIVECASEID)
						-- derived events do not match
						left join #TEMPDERIVEDEVENTCHANGED X
										on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('X'))				
						Where T.AMENDCASERULE=@nRuleNo
						and   V.TRANSACTIONIDENTIFIER is null
						and T.LIVECASEID is not null
						and L.CASEID is null
						and ((isnull(R.TEXT,"+@sRule+")=1 and isnull(D.TEXT,D.SHORTTEXT) is not null)
						   or(isnull(R.TEXT,"+@sRule+")=4)
						   or(isnull(R.TEXT,"+@sRule+")=6 and X.CASEID is null) )"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End

					If @nErrorCode=0
					Begin
						-----------------------------------
						-- Delete the Case Text if it 
						-- does not exist on the draft case
						-----------------------------------
						Set @sSQLString="
						Delete CASETEXT
						from CASETEXT L
						join #TEMPCASEMATCH T	on (T.LIVECASEID=L.CASEID)
						join EDERULECASETEXT R	on (R.CRITERIANO=T.AMENDCASERULE
									and R.TEXTTYPE=L.TEXTTYPE)
						-- derived events do not match
						left join #TEMPDERIVEDEVENTCHANGED X
									on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('X'))				
						Where T.AMENDCASERULE=@nRuleNo
						and   V.TRANSACTIONIDENTIFIER is null
						and   R.TEXT=4
						and not exists
						(select 1 from CASETEXT D
						 where D.CASEID=T.DRAFTCASEID
						 and D.TEXTTYPE=L.TEXTTYPE
						 and isnull(D.LANGUAGE,'')=isnull(L.LANGUAGE,'')
						 and isnull(D.CLASS,'')   =isnull(L.CLASS,''))"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End

					---------------
					-- CASEEVENT --
					---------------
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Update CASEEVENT
						Set
						EVENTDATE=
							CASE	WHEN(R.EVENTDATE=1 and D.EVENTDATE is not null)	THEN D.EVENTDATE
								WHEN(R.EVENTDATE in (3,8) and L.EVENTDATE is null)	
														THEN D.EVENTDATE
								WHEN(R.EVENTDATE=4)				THEN D.EVENTDATE
								WHEN(R.EVENTDATE=6 and D.EVENTDATE is not null 
										   and X.CASEID is null)	THEN D.EVENTDATE
														ELSE L.EVENTDATE
							 END,
						EVENTDUEDATE=	
							CASE	WHEN(R.EVENTDUEDATE=1 and D.EVENTDUEDATE is not null)	
														THEN D.EVENTDUEDATE
								WHEN(R.EVENTDUEDATE in (3,8) and L.EVENTDUEDATE is null)	
														THEN D.EVENTDUEDATE
								WHEN(R.EVENTDUEDATE=4)				THEN D.EVENTDUEDATE
								WHEN(R.EVENTDUEDATE=6 and D.EVENTDUEDATE is not null 
										   and X.CASEID is null)	THEN D.EVENTDUEDATE
														ELSE L.EVENTDUEDATE
							 END,
						OCCURREDFLAG=
							CASE	WHEN(R.EVENTDATE=1 and D.EVENTDATE is not null)	THEN 1
								WHEN(R.EVENTDATE in (3,8) and L.EVENTDATE is null)	
														THEN D.OCCURREDFLAG
								WHEN(R.EVENTDATE=4)				THEN D.OCCURREDFLAG
								WHEN(R.EVENTDATE=6 and D.EVENTDATE is not null 
										   and X.CASEID is null)	THEN 1
								WHEN(R.EVENTDUEDATE=1 and D.EVENTDUEDATE is not null)	
														THEN D.OCCURREDFLAG
								WHEN(R.EVENTDUEDATE in (3,8) and L.EVENTDUEDATE is null)	
														THEN D.OCCURREDFLAG
								WHEN(R.EVENTDUEDATE=4)				THEN D.OCCURREDFLAG
								WHEN(R.EVENTDUEDATE=6 and D.EVENTDUEDATE is not null 
										   and X.CASEID is null)	THEN D.OCCURREDFLAG
														ELSE L.OCCURREDFLAG
							 END,
						DATEDUESAVED=
							CASE	WHEN(R.EVENTDATE=1 and D.EVENTDATE is not null)	THEN D.DATEDUESAVED
								WHEN(R.EVENTDATE in (3,8) and L.EVENTDATE is null)	
														THEN D.DATEDUESAVED
								WHEN(R.EVENTDATE=4)				THEN D.DATEDUESAVED
								WHEN(R.EVENTDATE=6 and D.EVENTDATE is not null 
										   and X.CASEID is null)	THEN D.DATEDUESAVED
								WHEN(R.EVENTDUEDATE=1 and D.EVENTDUEDATE is not null)	
														THEN D.DATEDUESAVED
								WHEN(R.EVENTDUEDATE in (3,8) and L.EVENTDUEDATE is null)	
														THEN D.DATEDUESAVED
								WHEN(R.EVENTDUEDATE=4)				THEN D.DATEDUESAVED
								WHEN(R.EVENTDUEDATE=6 and D.EVENTDUEDATE is not null 
										   and X.CASEID is null)	THEN D.DATEDUESAVED
														ELSE L.DATEDUESAVED
							 END,
						EVENTTEXT=	
							CASE	WHEN(R.EVENTTEXT=1 and isnull(D.EVENTLONGTEXT,D.EVENTTEXT) is not null)	
														THEN D.EVENTTEXT
								WHEN(R.EVENTTEXT in (3,8) and isnull(L.EVENTLONGTEXT,L.EVENTTEXT) is null)	
														THEN D.EVENTTEXT
								WHEN(R.EVENTTEXT=4)				THEN D.EVENTTEXT
								WHEN(R.EVENTTEXT=6 and isnull(D.EVENTLONGTEXT,D.EVENTTEXT) is not null 
											and X.CASEID is null)	THEN D.EVENTTEXT
														ELSE L.EVENTTEXT
							 END,
						EVENTLONGTEXT=	
							CASE	WHEN(R.EVENTTEXT=1 and isnull(D.EVENTLONGTEXT,D.EVENTTEXT) is not null)	
														THEN D.EVENTLONGTEXT
								WHEN(R.EVENTTEXT in (3,8) and isnull(L.EVENTLONGTEXT,L.EVENTTEXT) is null)	
														THEN D.EVENTLONGTEXT
								WHEN(R.EVENTTEXT=4)				THEN D.EVENTLONGTEXT
								WHEN(R.EVENTTEXT=6 and isnull(D.EVENTLONGTEXT,D.EVENTTEXT) is not null 
											and X.CASEID is null)	THEN D.EVENTLONGTEXT
														ELSE L.EVENTLONGTEXT
							 END,
						LONGFLAG=CASE	WHEN(R.EVENTTEXT=1 and isnull(D.EVENTLONGTEXT,D.EVENTTEXT) is not null)	
														THEN D.LONGFLAG
								WHEN(R.EVENTTEXT in (3,8) and isnull(L.EVENTLONGTEXT,L.EVENTTEXT) is null)	
														THEN D.LONGFLAG
								WHEN(R.EVENTTEXT=4)				THEN D.LONGFLAG
								WHEN(R.EVENTTEXT=6 and isnull(D.EVENTLONGTEXT,D.EVENTTEXT) is not null 
											and X.CASEID is null)	THEN D.LONGFLAG
														ELSE L.LONGFLAG
							 END
						From CASEEVENT L
						join #TEMPCASEMATCH T	on (T.LIVECASEID=L.CASEID)
						join EDERULECASEEVENT R	on (R.CRITERIANO=T.AMENDCASERULE
									and R.EVENTNO=L.EVENTNO)
						join (select *
						      from CASEEVENT) D	on (D.CASEID=T.DRAFTCASEID
									and D.EVENTNO=L.EVENTNO
									and D.CYCLE=L.CYCLE)
						-- derived events do not match
						left join #TEMPDERIVEDEVENTCHANGED X
										on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('X'))				
						Where T.AMENDCASERULE=@nRuleNo
						and   V.TRANSACTIONIDENTIFIER is null
						and  L.EVENTNO not in (-16,-14,-13)
						and(((checksum(L.EVENTTEXT)<>checksum(D.EVENTTEXT) or checksum(datalength(L.EVENTLONGTEXT))<>checksum(datalength(D.EVENTLONGTEXT)) or L.EVENTLONGTEXT not like D.EVENTLONGTEXT)
							and( (R.EVENTTEXT=1 and isnull(D.EVENTLONGTEXT,D.EVENTTEXT) is not null)
							   or(R.EVENTTEXT in (3,8) and isnull(L.EVENTLONGTEXT,L.EVENTTEXT) is null)
							   or(R.EVENTTEXT=4)
							   or(R.EVENTTEXT=6 and isnull(D.EVENTLONGTEXT,D.EVENTTEXT) is not null and X.CASEID is null) ) )
						OR  (checksum(L.EVENTDATE)<>checksum(D.EVENTDATE)
							and( (R.EVENTDATE=1 and D.EVENTDATE is not null)
							   or(R.EVENTDATE in (3,8) and L.EVENTDATE is null)
							   or(R.EVENTDATE=4)
							   or(R.EVENTDATE=6 and X.CASEID is null) ) )
						OR  (checksum(L.EVENTDUEDATE)<>checksum(D.EVENTDUEDATE)
							and( (R.EVENTDUEDATE=1 and D.EVENTDUEDATE is not null)
							   or(R.EVENTDUEDATE in (3,8) and L.EVENTDUEDATE is null)
							   or(R.EVENTDUEDATE=4)
							   or(R.EVENTDUEDATE=6 and X.CASEID is null) ) ) )"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End

					If @nErrorCode=0
					Begin
						-----------------------------------
						-- Insert the Case Event if it 
						-- does not exist on the live case
						-----------------------------------
						Set @sSQLString="
						Insert into CASEEVENT(CASEID,EVENTNO,CYCLE,EVENTDATE,EVENTDUEDATE,DATEDUESAVED,OCCURREDFLAG,EVENTTEXT,LONGFLAG,EVENTLONGTEXT)
						Select 	DISTINCT T.LIVECASEID, D.EVENTNO, D.CYCLE, D.EVENTDATE, D.EVENTDUEDATE, D.DATEDUESAVED,	-- SQA19341
							 D.OCCURREDFLAG, D.EVENTTEXT, D.LONGFLAG, cast(D.EVENTLONGTEXT as nvarchar(max))	-- SQA19341
						From #TEMPCASEMATCH T
						join EDERULECASEEVENT R	on (R.CRITERIANO=T.AMENDCASERULE)
						join CASEEVENT D	on (D.CASEID=T.DRAFTCASEID
									and D.EVENTNO=R.EVENTNO)
						left join CASEEVENT L	on (L.CASEID=T.LIVECASEID
									and L.EVENTNO=D.EVENTNO
									and L.CYCLE=D.CYCLE)
						-- derived events do not match
						left join #TEMPDERIVEDEVENTCHANGED X
									on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('X'))				
						Where T.AMENDCASERULE=@nRuleNo
						and   V.TRANSACTIONIDENTIFIER is null
						and T.LIVECASEID is not null
						and L.CASEID is null
						and(((R.EVENTDATE=1 and D.EVENTDATE is not null)	
						   or(R.EVENTDATE in (3,8) and L.EVENTDATE is null)
						   or(R.EVENTDATE=4)
						   or(R.EVENTDATE=6 and X.CASEID is null) )
						OR  ((R.EVENTDUEDATE=1 and D.EVENTDUEDATE is not null)	
						   or(R.EVENTDUEDATE in (3,8) and L.EVENTDUEDATE is null)
						   or(R.EVENTDUEDATE=4)
						   or(R.EVENTDUEDATE=6 and X.CASEID is null) )
						OR  ((R.EVENTTEXT=1 and isnull(D.EVENTLONGTEXT,D.EVENTTEXT) is not null)	
						   or(R.EVENTTEXT in (3,8) and isnull(L.EVENTLONGTEXT,L.EVENTTEXT) is null)
						   or(R.EVENTTEXT=4)
						   or(R.EVENTTEXT=6 and X.CASEID is null) ) )"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End

					If @nErrorCode=0
					Begin
						------------------------------------
						-- Direct deletion of the Case Event
						-- is not allowed as this will be
						-- performed by Policing after an 
						-- Event Date is cleared out and no
						-- Event Due Date can be calculated.
						------------------------------------
						Set @sSQLString="
						Update CASEEVENT
						Set  EVENTDATE=null,
						     OCCURREDFLAG=0
						From CASEEVENT L
						join #TEMPCASEMATCH T	on (T.LIVECASEID=L.CASEID)
						-- Note a rule is required to explicitly
						-- indicate that an EventNo may be cleared
						-- if it does not exist on the draft Case
						join EDERULECASEEVENT R	on (R.CRITERIANO=T.AMENDCASERULE
									and R.EVENTNO=L.EVENTNO)
						left join 
						     (select *
						      from CASEEVENT) D	on (D.CASEID=T.DRAFTCASEID
									and D.EVENTNO=L.EVENTNO
									and D.CYCLE=L.CYCLE)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('X'))				
						Where T.AMENDCASERULE=@nRuleNo
						and   V.TRANSACTIONIDENTIFIER is null
						and D.CASEID is null	-- no matching draft Case Event
						and R.EVENTDATE=4"

						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End

					-----------------
					-- RELATEDCASE --
					-----------------
					If @nErrorCode=0
					Begin

						Set @sSQLString="
						Update RELATEDCASE
						Set
						OFFICIALNUMBER=
							CASE	WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+")=1 and D.OFFICIALNUMBER is not null)	THEN D.OFFICIALNUMBER
								WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+") in (3,8) and L.OFFICIALNUMBER is null)	THEN D.OFFICIALNUMBER
								WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+")=4)					THEN D.OFFICIALNUMBER
								WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+")=6 and D.OFFICIALNUMBER is not null 
											and X.CASEID is null)			THEN D.OFFICIALNUMBER
																ELSE L.OFFICIALNUMBER
							 END,
							-- no rule for COUNTRYCODE, RELATEDCASEID or CURRENTSTATUS so use
							-- OFFICIALNUMBER rule as these columns are logically connected
						RELATEDCASEID=
							CASE	WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+")=1 and D.RELATEDCASEID is not null)	THEN D.RELATEDCASEID
								WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+") in (3,8) and L.RELATEDCASEID is null)	THEN D.RELATEDCASEID
								WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+")=4)					THEN D.RELATEDCASEID
								WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+")=6 and D.RELATEDCASEID is not null 
											and X.CASEID is null)			THEN D.RELATEDCASEID
																ELSE L.RELATEDCASEID
							 END,
						COUNTRYCODE=
							CASE	WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+")=1 and D.COUNTRYCODE is not null)		THEN D.COUNTRYCODE
								WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+") in (3,8) and L.COUNTRYCODE is null)	THEN D.COUNTRYCODE
								WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+")=4)					THEN D.COUNTRYCODE
								WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+")=6 and D.COUNTRYCODE is not null 
											and X.CASEID is null)			THEN D.COUNTRYCODE
																ELSE L.COUNTRYCODE
							 END,
						CURRENTSTATUS=
							CASE	WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+")=1 and D.CURRENTSTATUS is not null)	THEN D.CURRENTSTATUS
								WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+") in (3,8) and L.CURRENTSTATUS is null)	THEN D.CURRENTSTATUS
								WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+")=4)					THEN D.CURRENTSTATUS
								WHEN(isnull(R.OFFICIALNUMBER,"+@sRule+")=6 and D.CURRENTSTATUS is not null 
											and X.CASEID is null)			THEN D.CURRENTSTATUS
																ELSE L.CURRENTSTATUS
							 END,
						PRIORITYDATE=
							CASE	WHEN(R.PRIORITYDATE=1 and D.PRIORITYDATE is not null)	THEN D.PRIORITYDATE
								WHEN(R.PRIORITYDATE in (3,8) and L.PRIORITYDATE is null)THEN D.PRIORITYDATE
								WHEN(R.PRIORITYDATE=4)					THEN D.PRIORITYDATE
								WHEN(R.PRIORITYDATE=6 and D.PRIORITYDATE is not null 
											and X.CASEID is null)		THEN D.PRIORITYDATE
															ELSE L.PRIORITYDATE
							 END
						From RELATEDCASE L
						join #TEMPCASEMATCH T		on (T.LIVECASEID=L.CASEID)
						left join EDERULERELATEDCASE R	on (R.CRITERIANO=T.AMENDCASERULE
										and R.RELATIONSHIP=L.RELATIONSHIP)
						join (select *
						      from RELATEDCASE) D	on (D.CASEID=T.DRAFTCASEID
										and D.RELATIONSHIP=L.RELATIONSHIP
										and(D.COUNTRYCODE=L.COUNTRYCODE or D.RELATIONSHIP<>'DC1') -- Designated Countries must match on Country
										and isnull(D.RELATEDCASEID,'') =isnull(L.RELATEDCASEID,'')
										and isnull(D.OFFICIALNUMBER,'')=isnull(L.OFFICIALNUMBER,''))
						-- derived events do not match
						left join #TEMPDERIVEDEVENTCHANGED X
										on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('X'))				
						Where T.AMENDCASERULE=@nRuleNo
						and   V.TRANSACTIONIDENTIFIER is null
						and (checksum(L.OFFICIALNUMBER, L.COUNTRYCODE, L.RELATEDCASEID)<>checksum(D.OFFICIALNUMBER, D.COUNTRYCODE, D.RELATEDCASEID)
							and( (isnull(R.OFFICIALNUMBER,"+@sRule+")=1 and D.OFFICIALNUMBER is not null)	
							   or(isnull(R.OFFICIALNUMBER,"+@sRule+") in (3,8) and L.OFFICIALNUMBER is null)
							   or(isnull(R.OFFICIALNUMBER,"+@sRule+")=4)
							   or(isnull(R.OFFICIALNUMBER,"+@sRule+")=6 and D.OFFICIALNUMBER is not null and X.CASEID is null) )
						 OR  checksum(L.PRIORITYDATE)<>checksum(D.PRIORITYDATE)  
							and( (R.PRIORITYDATE=1 and D.PRIORITYDATE is not null)	
							   or(R.PRIORITYDATE in (3,8) and L.PRIORITYDATE is null)
							   or(R.PRIORITYDATE=4)
							   or(R.PRIORITYDATE=6 and D.PRIORITYDATE is not null and X.CASEID is null) ) )"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End

					If @nErrorCode=0
					Begin
						-----------------------------------
						-- Insert the Related Case if it 
						-- does not exist on the live case
						-----------------------------------
						Set @sSQLString="
						Insert into RELATEDCASE(CASEID,RELATIONSHIPNO,RELATIONSHIP,RELATEDCASEID,OFFICIALNUMBER,COUNTRYCODE,PRIORITYDATE, CURRENTSTATUS)
						Select T.LIVECASEID, D.RELATIONSHIPNO,D.RELATIONSHIP,D.RELATEDCASEID,D.OFFICIALNUMBER,D.COUNTRYCODE,D.PRIORITYDATE,D.CURRENTSTATUS
						From #TEMPCASEMATCH T
						join RELATEDCASE D		on (D.CASEID=T.DRAFTCASEID)
						left join RELATEDCASE L		on (L.CASEID=T.LIVECASEID
										and L.RELATIONSHIP=D.RELATIONSHIP
										and(L.COUNTRYCODE=D.COUNTRYCODE or L.RELATIONSHIP<>'DC1') -- Designated Countries must match on Country
										and isnull(L.RELATEDCASEID,'') =isnull(D.RELATEDCASEID,'')
										and isnull(L.OFFICIALNUMBER,'')=isnull(D.OFFICIALNUMBER,''))
						left join EDERULERELATEDCASE R	on (R.CRITERIANO=T.AMENDCASERULE
										and R.RELATIONSHIP=D.RELATIONSHIP)
						-- derived events do not match
						left join #TEMPDERIVEDEVENTCHANGED X
										on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('X'))				
						Where T.AMENDCASERULE=@nRuleNo
						and   V.TRANSACTIONIDENTIFIER is null
						and L.CASEID is null
						and  checksum(L.OFFICIALNUMBER, L.COUNTRYCODE, L.RELATEDCASEID)<>checksum(D.OFFICIALNUMBER, D.COUNTRYCODE, D.RELATEDCASEID)
							and( (isnull(R.OFFICIALNUMBER,"+@sRule+")=1 and D.OFFICIALNUMBER is not null)	
							   or(isnull(R.OFFICIALNUMBER,"+@sRule+") in (3,8) and L.OFFICIALNUMBER is null)
							   or(isnull(R.OFFICIALNUMBER,"+@sRule+")=4)
							   or(isnull(R.OFFICIALNUMBER,"+@sRule+")=6 and D.OFFICIALNUMBER is not null and X.CASEID is null) )"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End

					If @nErrorCode=0
					Begin
						-----------------------------------
						-- Delete the Related Case if it 
						-- does not exist on the draft case
						-----------------------------------
						Set @sSQLString="
						Delete RELATEDCASE
						from RELATEDCASE L
						join #TEMPCASEMATCH T		on (T.LIVECASEID=L.CASEID)
						join EDERULERELATEDCASE R	on (R.CRITERIANO=T.AMENDCASERULE
										and R.RELATIONSHIP=L.RELATIONSHIP)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('X'))				
						Where T.AMENDCASERULE=@nRuleNo
						and   V.TRANSACTIONIDENTIFIER is null
						and   R.OFFICIALNUMBER=4
						and not exists
						(select 1 from RELATEDCASE D
						 where D.CASEID=T.DRAFTCASEID
						 and D.RELATIONSHIP=L.RELATIONSHIP
						 and(D.COUNTRYCODE=L.COUNTRYCODE or D.RELATIONSHIP<>'DC1') -- Designated Countries must match on Country
						 and isnull(D.RELATEDCASEID,'') =isnull(L.RELATEDCASEID,'')
						 and isnull(D.OFFICIALNUMBER,'')=isnull(L.OFFICIALNUMBER,''))"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo=@nRuleNo
					End

					If @nErrorCode=0
					Begin
						------------------------------------------------------------------------
						-- SQA18403
						-- Now that updates of the live case have been made for bother Related
						-- Cases and Official Numbers we can match on Official Number and Country
						-- to point to the live Case.
						-- This update looks for existing live Cases that can now related to the
						-- Case just updated.
						-------------------------------------------------------------------------

						
						---------------------------------------------------------
						-- First save the RELATEDCASE rows to be updated so
						-- we can check if a Reciprocal Relationship is required.
						---------------------------------------------------------
						Set @sSQLString="
						Insert into dbo.#TEMPCHECKRECIPROCAL (CASEID, RELATIONSHIPNO, RELATIONSHIP, RELATEDCASEID)
						Select RC.CASEID, RC.RELATIONSHIPNO, RC.RELATIONSHIP, C.CASEID
						From CASES C
						join CASETYPE CT	  on (CT.CASETYPE=C.CASETYPE)
						join #TEMPCASEMATCH T	  on (T.LIVECASEID=C.CASEID)
						join OFFICIALNUMBERS O	  on (O.CASEID=C.CASEID)
						join NUMBERTYPES NT	  on (NT.NUMBERTYPE=O.NUMBERTYPE
									  and NT.ISSUEDBYIPOFFICE=1)
						join RELATEDCASE RC	  on (RC.OFFICIALNUMBER=O.OFFICIALNUMBER
									  and RC.COUNTRYCODE   =C.COUNTRYCODE)
						join CASES C1		  on (C1.CASEID      =RC.CASEID
									  and C1.CASETYPE    =C.CASETYPE
									  and C1.PROPERTYTYPE=C.PROPERTYTYPE)
						join CASERELATION CR	  on (CR.RELATIONSHIP  =RC.RELATIONSHIP)
						left join CASEEVENT CE	  on (CE.CASEID   =C.CASEID
									  and CE.EVENTNO  =CR.FROMEVENTNO
									  and CE.CYCLE    =1)
						left join #TEMPREVIEW V	  on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									  and V.REVIEWTYPE in ('X'))				
						Where T.AMENDCASERULE=@nRuleNo
						and   V.TRANSACTIONIDENTIFIER is null
						and CT.ACTUALCASETYPE is null	-- Indicates this is a live Case Type
						and (CE.EVENTDATE=RC.PRIORITYDATE OR RC.PRIORITYDATE is null OR CR.FROMEVENTNO is null)"

						exec @nErrorCode=sp_executesql @sSQLString,
										N'@nRuleNo	int',
										  @nRuleNo=@nRuleNo
										  
						If @nErrorCode=0
						Begin
							-----------------------------------
							-- Now reset the RELATEDCASE row to
							-- point to the newly loaded case.
							-----------------------------------
							Set @sSQLString="
							Update RC
							Set RELATEDCASEID =T.RELATEDCASEID,
							    OFFICIALNUMBER=NULL,
							    COUNTRYCODE   =NULL,
							    PRIORITYDATE  =NULL
							From dbo.#TEMPCHECKRECIPROCAL T
							join RELATEDCASE RC	  on (RC.CASEID=T.CASEID
										  and RC.RELATIONSHIPNO=T.RELATIONSHIPNO)
							Where RC.OFFICIALNUMBER is not null
							and   RC.COUNTRYCODE    is not null"

							exec @nErrorCode=sp_executesql @sSQLString
						End
					End

					If @nErrorCode=0
					Begin
						------------------------------------------------------------------------
						-- SQA18403
						-- Now update the RelatedCase for the Case that has just been updated 
						-- so that it points to any existing live Cases.
						-------------------------------------------------------------------------

						
						---------------------------------------------------------
						-- First save the RELATEDCASE rows to be updated so
						-- we can check if a Reciprocal Relationship is required.
						---------------------------------------------------------
						Set @sSQLString="
						Insert into dbo.#TEMPCHECKRECIPROCAL (CASEID, RELATIONSHIPNO, RELATIONSHIP, RELATEDCASEID)
						Select RC.CASEID, RC.RELATIONSHIPNO, RC.RELATIONSHIP, C1.CASEID
						From CASES C
						join CASETYPE CT	  on (CT.CASETYPE=C.CASETYPE)
						join #TEMPCASEMATCH T	  on (T.LIVECASEID=C.CASEID)
						join RELATEDCASE RC	  on (RC.CASEID=C.CASEID
									  and RC.RELATEDCASEID is null)
						join EDEIDENTIFIERNUMBERDETAILS N
									  on (N.BATCHNO=@pnBatchNo
									  and N.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									  and N.IDENTIFIERNUMBERTEXT =RC.OFFICIALNUMBER
									  and N.ASSOCCASESEQ         =RC.RELATIONSHIPNO)
						join OFFICIALNUMBERS O	  on (O.OFFICIALNUMBER=RC.OFFICIALNUMBER
									  and O.NUMBERTYPE    =N.IDENTIFIERNUMBERCODE_T)

						join CASES C1		  on (C1.CASEID      = O.CASEID
									  and C1.COUNTRYCODE =RC.COUNTRYCODE
									  and C1.PROPERTYTYPE= C.PROPERTYTYPE
									  and C1.CASETYPE    = C.CASETYPE)
						join CASERELATION CR	  on (CR.RELATIONSHIP=RC.RELATIONSHIP)
						left join CASEEVENT CE	  on (CE.CASEID =C1.CASEID
									  and CE.EVENTNO=CR.FROMEVENTNO
									  and CE.CYCLE  =1)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('X'))
						left join dbo.#TEMPCHECKRECIPROCAL TCR
									on (TCR.CASEID=RC.CASEID
									and TCR.RELATIONSHIPNO=RC.RELATIONSHIPNO)				
						Where T.AMENDCASERULE=@nRuleNo
						and   V.TRANSACTIONIDENTIFIER is null
						and CT.ACTUALCASETYPE is null	-- Indicates that this is a live Case
						and (CE.EVENTDATE=RC.PRIORITYDATE OR RC.PRIORITYDATE is null OR CR.FROMEVENTNO is null)
						and TCR.CASEID is null
						--------------------------------
						-- Check that there is not an
						-- alternative Case to match on.
						--------------------------------
						and not exists
						(select 1
						 from OFFICIALNUMBERS O2
						 join CASES C2		on (C2.CASEID=O2.CASEID
									and C2.COUNTRYCODE=RC.COUNTRYCODE
									and C2.PROPERTYTYPE=C.PROPERTYTYPE
									and C2.CASETYPE    =C.CASETYPE)
						 where O2.OFFICIALNUMBER=RC.OFFICIALNUMBER
						 and   O2.NUMBERTYPE    =O.NUMBERTYPE
						 and   O2.CASEID<>O.CASEID)"

						exec @nErrorCode=sp_executesql @sSQLString,
										N'@nRuleNo	int,
										  @pnBatchNo	int',
										  @nRuleNo=@nRuleNo,
										  @pnBatchNo=@pnBatchNo
										  
						If @nErrorCode=0
						Begin
							-----------------------------------
							-- Now reset the RELATEDCASE row to
							-- point to the newly loaded case.
							-----------------------------------
							Set @sSQLString="
							Update RC
							Set RELATEDCASEID =T.RELATEDCASEID,
							    OFFICIALNUMBER=NULL,
							    COUNTRYCODE   =NULL,
							    PRIORITYDATE  =NULL
							From dbo.#TEMPCHECKRECIPROCAL T
							join RELATEDCASE RC	  on (RC.CASEID=T.CASEID
										  and RC.RELATIONSHIPNO=T.RELATIONSHIPNO)
							Where RC.OFFICIALNUMBER is not null
							and   RC.COUNTRYCODE    is not null"

							exec @nErrorCode=sp_executesql @sSQLString
						End
					End
								
					------------------------------------------------------------------
					-- DR-48058
					-- If a related case has linked to an Inprotech Case then see if
					-- a reciprocal relationship is able to be inserted to create the
					-- reverse relationship
					-- Need to consider draft cases inserted in this batch.
					------------------------------------------------------------------
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						With RecipRelationships AS
						(	Select  ROW_NUMBER() OVER(PARTITION BY coalesce(RC.RELATEDCASEID, RC.CASEID) 
										  ORDER     BY coalesce(RC.RELATEDCASEID, RC.CASEID), RC.RELATIONSHIPNO) AS RowNumber,
								RC.CASEID, 
								RC.RELATIONSHIP,
								RC.RELATEDCASEID
							From dbo.#TEMPCHECKRECIPROCAL RC
						)
						Insert into RELATEDCASE(CASEID, RELATIONSHIPNO, RELATIONSHIP, RELATEDCASEID)
						Select distinct RC.RELATEDCASEID, 
								isnull(RC2.RELATIONSHIPNO,0)+RC.RowNumber,	-- Need to increment the RELATIONSHIP number
								VR.RECIPRELATIONSHIP,				-- the Reciprocal Relationship
								RC.CASEID
						From RecipRelationships RC
						join CASES C		  on (C.CASEID=RC.CASEID)
						-------------------------------------
						-- Find the reciprocal relationship
						-- for the related case just updated
						-------------------------------------
						join VALIDRELATIONSHIPS VR on (VR.PROPERTYTYPE=C.PROPERTYTYPE
									   and VR.RELATIONSHIP=RC.RELATIONSHIP
									   and VR.COUNTRYCODE =(select min(VR1.COUNTRYCODE)
												from VALIDRELATIONSHIPS VR1
												where VR1.COUNTRYCODE in ('ZZZ',C.COUNTRYCODE)
												and   VR1.PROPERTYTYPE=C.PROPERTYTYPE) 
									  and VR.RECIPRELATIONSHIP is not null)
						left join RELATEDCASE RC1 on (RC1.CASEID       =RC.RELATEDCASEID
									  and RC1.RELATIONSHIP =VR.RECIPRELATIONSHIP
									  and RC1.RELATEDCASEID=RC.CASEID)
						----------------------------------
						-- Get the highest RELATIONSHIPNO
						-- allocated for each Relationship
						-- about to be inserted
						----------------------------------
						left join (select CASEID, max(RELATIONSHIPNO) as RELATIONSHIPNO
							   from RELATEDCASE
							   group by CASEID) RC2 on (RC2.CASEID=RC.RELATEDCASEID)
						Where RC1.CASEID is null"

						exec @nErrorCode=sp_executesql @sSQLString

					End
					
								
					------------------------------------------------------------------
					-- DR-48058
					-- Now clear out the contents of #TEMPCHECKRECIPROCAL so that it 
					-- can be used for the next RuleNo to be processed.
					------------------------------------------------------------------
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						delete from dbo.#TEMPCHECKRECIPROCAL"

						exec @nErrorCode=sp_executesql @sSQLString

					End

					--------------
					-- CASENAME --
					--------------------------------------------------------------------------------
					-- Processing associated with name changes is complicated by various rules
					-- that may be associated with NameTypes.  These include the following :
					-- 1. Change of Standing Instruction when Name changed against Case.
					--    This might require events against associated Cases to be recalculated.
					-- 2. Inheritance of other NameTypes may be triggered or changed.
					-- 3. Updating of an Event associated with a NameType and subsequent Policing.
					-- 4. If the NameType being changed has an associated Future Name Type then 
					--    the Future Name Type will be substituted.
					-- Due to the complex nature of this processing the Global Name Change procedure
					-- will be utilised to apply these changes
					--------------------------------------------------------------------------------
					
					If @nGlobalChanges>0
					and @nErrorCode=0
					Begin
						Set @nGlobalChanges=0

						Set @sSQLString="Delete from #TEMPCASENAME"

						Exec @nErrorCode=sp_executesql @sSQLString
					End

					If @nErrorCode=0
					Begin
						-- Load the CaseName changes in preparation to let the Global Name
						-- Change procedure apply the changes.
						Set @sSQLString="
						insert into #TEMPCASENAME(TYPE, CASEID, NAMETYPE, OLDNAMENO, NAMENO, OLDCORRESPONDNAME, CORRESPONDNAME,
									  OLDREFERENCENO, REFERENCENO, OLDADDRESSCODE, ADDRESSCODE, COMMENCEDATE)
						Select	'UPDATE', T.LIVECASEID, L.NAMETYPE, L.NAMENO,
							CASE	WHEN(isnull(R.NAMENO,"+@sRule+")=1 and D.NAMENO is not null)	THEN D.NAMENO
								WHEN(isnull(R.NAMENO,"+@sRule+") in (3,8) and L.NAMENO is null)	THEN D.NAMENO
								WHEN(isnull(R.NAMENO,"+@sRule+")=4)				THEN D.NAMENO
				   				WHEN(isnull(R.NAMENO,"+@sRule+")=5 and NL.FAMILYNO=ND.FAMILYNO)	THEN D.NAMENO
								WHEN(isnull(R.NAMENO,"+@sRule+")=6 and D.NAMENO is not null 
										   and X.CASEID is null)	THEN D.NAMENO
														ELSE L.NAMENO
							END,
							L.CORRESPONDNAME,
							CASE	WHEN(isnull(R.CORRESPONDNAME,"+@sRule+")=1 and D.CORRESPONDNAME is not null)
														THEN D.CORRESPONDNAME
								WHEN(isnull(R.CORRESPONDNAME,"+@sRule+") in (3,8) and L.CORRESPONDNAME is null)	
														THEN D.CORRESPONDNAME
								WHEN(isnull(R.CORRESPONDNAME,"+@sRule+")=4)	THEN D.CORRESPONDNAME
								WHEN(isnull(R.CORRESPONDNAME,"+@sRule+")=6 and D.CORRESPONDNAME is not null 
										   and X.CASEID is null)	THEN D.CORRESPONDNAME
														ELSE L.CORRESPONDNAME
							END,
							L.REFERENCENO,
							CASE	WHEN(isnull(R.REFERENCENO,"+@sRule+")=1 and D.REFERENCENO is not null)
														THEN D.REFERENCENO
								WHEN(isnull(R.REFERENCENO,"+@sRule+") in (3,8) and L.REFERENCENO is null)	
														THEN D.REFERENCENO
								WHEN(isnull(R.REFERENCENO,"+@sRule+")=4)	THEN D.REFERENCENO
								WHEN(isnull(R.REFERENCENO,"+@sRule+")=6 and D.REFERENCENO is not null 
										   and X.CASEID is null)	THEN D.REFERENCENO
														ELSE L.REFERENCENO
							END,
							L.ADDRESSCODE,
							D.ADDRESSCODE,
							D.COMMENCEDATE
						From CASENAME L
						join NAME NL		on (NL.NAMENO=L.NAMENO)
						join #TEMPCASEMATCH T	on (T.LIVECASEID=L.CASEID)
						left join EDERULECASENAME R	on (R.CRITERIANO=T.AMENDCASERULE
										and R.NAMETYPE=L.NAMETYPE)
						join CASENAME D		on (D.CASEID=T.DRAFTCASEID
									and D.NAMETYPE=L.NAMETYPE
									and D.SEQUENCE=L.SEQUENCE)
						join NAME ND		on (ND.NAMENO=D.NAMENO)
						-- derived events do not match
						left join #TEMPDERIVEDEVENTCHANGED X
									on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('X'))				
						Where T.AMENDCASERULE=@nRuleNo
						and   V.TRANSACTIONIDENTIFIER is null
						and((checksum(L.NAMENO)<>checksum(D.NAMENO)  
							and( (isnull(R.NAMENO,"+@sRule+")=1 and D.NAMENO is not null)
							   or(isnull(R.NAMENO,"+@sRule+") in (3,8) and L.NAMENO is null)
							   or(isnull(R.NAMENO,"+@sRule+")=4)
							   or(isnull(R.NAMENO,"+@sRule+")=5 and NL.FAMILYNO=ND.FAMILYNO)  -- Family must be the same.  Nulls treated as not being equal.
							   or(isnull(R.NAMENO,"+@sRule+")=6 and X.CASEID is null) ) )
						OR  (checksum(L.REFERENCENO)<>checksum(D.REFERENCENO)  
							and( (isnull(R.REFERENCENO,"+@sRule+")=1 and D.REFERENCENO is not null)	
							   or(isnull(R.REFERENCENO,"+@sRule+") in (3,8) and L.REFERENCENO is null)
							   or(isnull(R.REFERENCENO,"+@sRule+")=4)
							   or(isnull(R.REFERENCENO,"+@sRule+")=6 and X.CASEID is null) ) )
						OR  (checksum(L.CORRESPONDNAME)<>checksum(D.CORRESPONDNAME)  
							and( (isnull(R.CORRESPONDNAME,"+@sRule+")=1 and D.CORRESPONDNAME is not null)	
							   or(isnull(R.CORRESPONDNAME,"+@sRule+") in (3,8) and L.CORRESPONDNAME is null)
							   or(isnull(R.CORRESPONDNAME,"+@sRule+")=4)
							   or(isnull(R.CORRESPONDNAME,"+@sRule+")=6 and X.CASEID is null) ) ) )"
					
						Exec @nErrorCode=sp_executesql @sSQLString,
										N'@nRuleNo	int',
										  @nRuleNo=@nRuleNo

						Set @nGlobalChanges=@@RowCount
					End
						
					If @nErrorCode=0
					Begin
						-- Insert details of the new CASENAME rows to be inserted
						-- against the live case
						Set @sSQLString="
						insert into #TEMPCASENAME(TYPE, CASEID, NAMETYPE, OLDNAMENO, NAMENO, OLDCORRESPONDNAME, CORRESPONDNAME,
									  OLDREFERENCENO, REFERENCENO, OLDADDRESSCODE, ADDRESSCODE, COMMENCEDATE)
						Select	'INSERT', T.LIVECASEID, D.NAMETYPE, L.NAMENO,
							CASE	WHEN(isnull(R.NAMENO,"+@sRule+")=1 and D.NAMENO is not null)	THEN D.NAMENO
								WHEN(isnull(R.NAMENO,"+@sRule+") in (3,8) and L.NAMENO is null)	THEN D.NAMENO
								WHEN(isnull(R.NAMENO,"+@sRule+")=4)				THEN D.NAMENO
								WHEN(isnull(R.NAMENO,"+@sRule+")=6 and D.NAMENO is not null 
										   and X.CASEID is null)	THEN D.NAMENO
														ELSE L.NAMENO
							END,
							L.CORRESPONDNAME,
							CASE	WHEN(isnull(R.CORRESPONDNAME,"+@sRule+")=1 and D.CORRESPONDNAME is not null)
														THEN D.CORRESPONDNAME
								WHEN(isnull(R.CORRESPONDNAME,"+@sRule+") in (3,8) and L.CORRESPONDNAME is null)	
														THEN D.CORRESPONDNAME
								WHEN(isnull(R.CORRESPONDNAME,"+@sRule+")=4)			THEN D.CORRESPONDNAME
								WHEN(isnull(R.CORRESPONDNAME,"+@sRule+")=6 and D.CORRESPONDNAME is not null 
										   and X.CASEID is null)	THEN D.CORRESPONDNAME
														ELSE L.CORRESPONDNAME
							END,
							L.REFERENCENO,
							CASE	WHEN(isnull(R.REFERENCENO,"+@sRule+")=1 and D.REFERENCENO is not null)
														THEN D.REFERENCENO
								WHEN(isnull(R.REFERENCENO,"+@sRule+") in (3,8) and L.REFERENCENO is null)	
														THEN D.REFERENCENO
								WHEN(isnull(R.REFERENCENO,"+@sRule+")=4)				THEN D.REFERENCENO
								WHEN(isnull(R.REFERENCENO,"+@sRule+")=6 and D.REFERENCENO is not null 
										   and X.CASEID is null)	THEN D.REFERENCENO
														ELSE L.REFERENCENO
							END,
							L.ADDRESSCODE,
							D.ADDRESSCODE,
							D.COMMENCEDATE
						From CASENAME D
						join #TEMPCASEMATCH T	on (T.DRAFTCASEID=D.CASEID)
						left join EDERULECASENAME R	on (R.CRITERIANO=T.AMENDCASERULE
									and R.NAMETYPE=D.NAMETYPE)
						left join CASENAME L	on (L.CASEID=T.LIVECASEID
									and L.NAMETYPE=D.NAMETYPE
									and L.SEQUENCE=D.SEQUENCE)
						-- derived events do not match
						left join #TEMPDERIVEDEVENTCHANGED X
										on (X.CASEID=T.DRAFTCASEID)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('X'))				
						Where T.AMENDCASERULE=@nRuleNo
						and   V.TRANSACTIONIDENTIFIER is null
						and T.LIVECASEID is not null
						and L.CASEID is null
						and((checksum(L.NAMENO)<>checksum(D.NAMENO)  
							and( (isnull(R.NAMENO,"+@sRule+")=1 and D.NAMENO is not null)	
							   or(isnull(R.NAMENO,"+@sRule+") in (3,8) and L.NAMENO is null)
							   or(isnull(R.NAMENO,"+@sRule+")=4)
							   or(isnull(R.NAMENO,"+@sRule+")=6 and X.CASEID is null) ) )
						OR  (checksum(L.REFERENCENO)<>checksum(D.REFERENCENO)  
							and( (isnull(R.REFERENCENO,"+@sRule+")=1 and D.REFERENCENO is not null)	
							   or(isnull(R.REFERENCENO,"+@sRule+") in (3,8) and L.REFERENCENO is null)
							   or(isnull(R.REFERENCENO,"+@sRule+")=4)
							   or(isnull(R.REFERENCENO,"+@sRule+")=6 and X.CASEID is null) ) )
						OR  (checksum(L.CORRESPONDNAME)<>checksum(D.CORRESPONDNAME)  
							and( (isnull(R.CORRESPONDNAME,"+@sRule+")=1 and D.CORRESPONDNAME is not null)	
							   or(isnull(R.CORRESPONDNAME,"+@sRule+") in (3,8) and L.CORRESPONDNAME is null)
							   or(isnull(R.CORRESPONDNAME,"+@sRule+")=4)
							   or(isnull(R.CORRESPONDNAME,"+@sRule+")=6 and X.CASEID is null) ) ) )"
					
						Exec @nErrorCode=sp_executesql @sSQLString,
										N'@nRuleNo	int',
										  @nRuleNo=@nRuleNo

						Set @nGlobalChanges=@nGlobalChanges+@@RowCount
					End

					If @nErrorCode=0
					Begin
						-- Insert details of the old CASENAME rows to be deleted
						-- from the live case

						Set @sSQLString="
						insert into #TEMPCASENAME(TYPE, CASEID, NAMETYPE, OLDNAMENO, NAMENO, OLDCORRESPONDNAME, CORRESPONDNAME,
									  OLDREFERENCENO, REFERENCENO, OLDADDRESSCODE, ADDRESSCODE, COMMENCEDATE)
						Select	'DELETE', T.LIVECASEID, L.NAMETYPE, L.NAMENO,
							NULL,
							L.CORRESPONDNAME,
							NULL,
							L.REFERENCENO,
							NULL,
							L.ADDRESSCODE,
							D.ADDRESSCODE,
							D.COMMENCEDATE
						From CASENAME L
						join #TEMPCASEMATCH T	on (T.LIVECASEID=L.CASEID)
						join EDERULECASENAME R	on (R.CRITERIANO=T.AMENDCASERULE
									and R.NAMETYPE=L.NAMETYPE)
						left join CASENAME D	on (D.CASEID=T.DRAFTCASEID
									and D.NAMETYPE=L.NAMETYPE
									and D.SEQUENCE=L.SEQUENCE)
						left join #TEMPREVIEW V	on (V.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and V.REVIEWTYPE in ('X'))				
						Where T.AMENDCASERULE=@nRuleNo
						and   V.TRANSACTIONIDENTIFIER is null
						and T.DRAFTCASEID is not null
						and D.CASEID is null
						and R.NAMENO=4" -- Delete is allowed
					
						Exec @nErrorCode=sp_executesql @sSQLString,
										N'@nRuleNo	int',
										  @nRuleNo=@nRuleNo

						Set @nGlobalChanges=@nGlobalChanges+@@RowCount

						If @nErrorCode=0
						and @nGlobalChanges>0
						Begin
							Exec @nErrorCode=ede_CaseNameGlobalUpdates
										@pnUserIdentityId	=@pnUserIdentityId,
										@pnBatchNo		=@pnBatchNo,
										@pnTransNo		=@nTransNo,
										@pbPoliceImmediately	=@pbPoliceImmediately
						End
					End

					----------------------------------------
					-- Insert/Update Date Last Changed.
					-- Any changes that have been applied to 
					-- a Case or any of its related tables
					-- is to result in the data last changed
					-- event for the Case to be updated.
					-- Check the following tables:
					-- 	CASES
					--	PROPERTY
					--	OFFICIALNUMBERS
					--	CASETEXT
					--	CASEEVENT
					--	RELATEDCASE
					--	CASENAME
					----------------------------------------

					If @nErrorCode=0
					and @sSQLModifiedCases is not null
					Begin
						-------------------------------------
						-- Clear out the Cases updated in the
						-- previous transaction
						-------------------------------------
						If @nCaseCount>0
						Begin
							Set @sSQLString="Delete from #TEMPCASESTOUPDATE"

							Exec @nErrorCode=sp_executesql @sSQLString
						End
						--------------------------------------
						-- Execute the earlier constructed
						-- SQL to get a distinct list of Cases
						-- that have been modified.
						--------------------------------------
						If @nErrorCode=0
						Begin
							Exec @nErrorCode=sp_executesql @sSQLModifiedCases,
										N'@dtLogDateTime	datetime,
										  @nTransNo		int',
										  @dtLogDateTime=@dtLogDateTime,
										  @nTransNo=@nTransNo
						
							Set @nCaseCount=@@Rowcount
						End
					End

					-----------------------------------------
					-- Local Client Flag on CASES must be set
					-- Number of local classes must be set
					-- Current Official no must be set
					-----------------------------------------
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Update CASES
						Set	LOCALCLIENTFLAG=isnull(IP.LOCALCLIENTFLAG,C.LOCALCLIENTFLAG),
							LOCALCLASSES   =isnull(C.LOCALCLASSES,C.INTCLASSES),
							NOOFCLASSES    =CASE WHEN(isnull(C.LOCALCLASSES,C.INTCLASSES) is not null)
										-- count the comma separators and increment by 1
										THEN dbo.fn_StringOccurrenceCount(',',isnull(C.LOCALCLASSES,C.INTCLASSES))+1
									END,
							CURRENTOFFICIALNO = substring(O1.OFFICIALNUMBER,14,36)
						From CASES C
						join #TEMPCASESTOUPDATE T on (T.CASEID=C.CASEID)
						left join CASENAME CN	on (CN.CASEID=C.CASEID
									and CN.NAMETYPE='I'
									and(CN.COMMENCEDATE>getdate() or CN.COMMENCEDATE is null)
									and CN.EXPIRYDATE is null)
						left join IPNAME IP	on (IP.NAMENO=CN.NAMENO)
						-- get the Official number to use as the Current Official numner
						left join (	select O.CASEID, 
								max(convert(nchar(5), 99999-NT.DISPLAYPRIORITY )+
								    convert(nchar(8), ISNULL(O.DATEENTERED,0),112)+
								    O.OFFICIALNUMBER) as OFFICIALNUMBER
								from OFFICIALNUMBERS O
								join NUMBERTYPES NT 	on (NT.NUMBERTYPE = O.NUMBERTYPE)
								where NT.ISSUEDBYIPOFFICE = 1
								and NT.DISPLAYPRIORITY is not null
								and O.ISCURRENT=1
								group by O.CASEID) O1 	on (O1.CASEID=C.CASEID)"
				
						exec @nErrorCode=sp_executesql @sSQLString
					End

					----------------------------------------
					-- Changes to RelatedCases may result
					-- in new or modified data on CASEEVENT.
					----------------------------------------
					If @nErrorCode=0
					and @bRelatedCaseLog=1
					Begin
						Set @sSQLString="
						Update CASEEVENT
						Set EVENTDATE=RC.PRIORITYDATE,
						    OCCURREDFLAG=1
						From #TEMPCASEMATCH T
						join CASEEVENT CE	on (CE.CASEID=T.LIVECASEID
									and CE.CYCLE=1)
						join CASERELATION CR	on (CR.EVENTNO=CE.EVENTNO)
						join (	select CASEID, RELATIONSHIP, min(PRIORITYDATE) as PRIORITYDATE
							from RELATEDCASE
							where PRIORITYDATE is not null
							group by CASEID, RELATIONSHIP) RC
									on (RC.CASEID=CE.CASEID
									and RC.RELATIONSHIP=CR.RELATIONSHIP)
						Where (CE.EVENTDATE is null
						or CE.EVENTDATE>RC.PRIORITYDATE)
						and CR.FROMEVENTNO is not null
						-- A RelatedCase change must have occurred
						and exists
						(select 1 from RELATEDCASE_iLOG L
						 where L.CASEID=CE.CASEID
						 and L.RELATIONSHIP=CR.RELATIONSHIP
						 and L.LOGDATETIMESTAMP>=@dtLogDateTime
						 and L.LOGTRANSACTIONNO=@nTransNo)"

						Exec @nErrorCode=sp_executesql @sSQLString,
									N'@dtLogDateTime	datetime,
									  @nTransNo		int',
									  @dtLogDateTime=@dtLogDateTime,
									  @nTransNo=@nTransNo
					End

					If @nErrorCode=0
					and @bRelatedCaseLog=1
					Begin
						Set @sSQLString="
						Insert into CASEEVENT(CASEID,EVENTNO,CYCLE,EVENTDATE,OCCURREDFLAG)
						Select distinct T.LIVECASEID,CR.EVENTNO,1,RC.PRIORITYDATE,1
						From #TEMPCASEMATCH T
						join RELATEDCASE_iLOG L	on (L.CASEID=T.LIVECASEID
									and L.LOGDATETIMESTAMP>=@dtLogDateTime
									and L.LOGTRANSACTIONNO=@nTransNo)
						join CASERELATION CR	on (CR.RELATIONSHIP=L.RELATIONSHIP
									and CR.EVENTNO is not null)
						join (	select CASEID, RELATIONSHIP, min(PRIORITYDATE) as PRIORITYDATE
							from RELATEDCASE
							where PRIORITYDATE is not null
							group by CASEID, RELATIONSHIP) RC
									on (RC.CASEID=T.LIVECASEID
									and RC.RELATIONSHIP=CR.RELATIONSHIP)
						left join CASEEVENT CE	on (CE.CASEID=T.LIVECASEID
									and CE.EVENTNO=CR.EVENTNO
									and CE.CYCLE=1)
						Where CE.CASEID is null
						and CR.FROMEVENTNO is not null"

						Exec @nErrorCode=sp_executesql @sSQLString,
									N'@dtLogDateTime	datetime,
									  @nTransNo		int',
									  @dtLogDateTime=@dtLogDateTime,
									  @nTransNo=@nTransNo
					End
					---------------------------------------------------------------------
					-- If a Stop Pay Reason has been provided then also update/insert a 
					-- specific Event that has been mapped to the Stop Reason.
					-- This is determined by concatenating the Stop Reason to a Site
					-- Control value.  
					---------------------------------------------------------------------
					If @nErrorCode=0
					and @bCasesLog=1
					Begin
						-------------------------------
						-- Store the Stop Pay Date in a
						-- temporary table as this is
						-- required later to determine
						-- the Transaction Narrative
						-------------------------------
						Set @sSQLString="
						Delete from #TEMPSTOPPAY

						Insert into #TEMPSTOPPAY (CASEID, EVENTNO, CYCLE, EVENTDATE, EVENTDUEDATE, OCCURREDFLAG, DATEDUESAVED, EVENTTEXT, FUTUREDATENARRATIVE, PASTDATENARRATIVE)
						Select	C.CASEID, 
							E.EVENTNO, 
							isnull(OA.CYCLE,1), 
							CASE WHEN(CE.CASEID is not null) THEN CE.EVENTDATE ELSE convert(nvarchar,getdate(),106) END, 
							CE.EVENTDUEDATE, 
							CASE WHEN(CE.EVENTDATE is not null OR CE.CASEID is null) THEN 1 ELSE 0 END,
							CE.DATEDUESAVED,
							CE.EVENTTEXT,
							T2.TABLECODE,	-- Narrative Code to use for future date
							T3.TABLECODE	-- Narrative Code if date is not in the future
						From #TEMPCASESTOUPDATE T
						     join CASES C	 on (C.CASEID=T.CASEID)
						left join CASEEVENT CE	 on (CE.CASEID=C.CASEID
									 and CE.EVENTNO=@nStopPayEvent
									 and CE.CYCLE=1)
						     join SITECONTROL S1 on (upper(S1.CONTROLID)='CPA STOP WHEN REASON='+C.STOPPAYREASON)
						     join EVENTS E	 on (E.EVENTNO=S1.COLINTEGER)
						     --------------------------------------
						     -- Determine the cycle to use from the 
						     -- earliest open action of the Events
						     -- Controlling Action
						     --------------------------------------
						left join (	select CASEID, ACTION, min(CYCLE) as CYCLE
								from OPENACTION
								where POLICEEVENTS=1
								group by CASEID, ACTION) OA
									 on (OA.CASEID=C.CASEID
									 and OA.ACTION=E.CONTROLLINGACTION)
						left join SITECONTROL S2 on (S2.CONTROLID='CPA Narrative Future Reason='+C.STOPPAYREASON)
						left join TABLECODES  T2 on (T2.TABLECODE=S2.COLINTEGER)
						left join SITECONTROL S3 on (S3.CONTROLID='CPA Narrative When Reason='+C.STOPPAYREASON)
						left join TABLECODES  T3 on (T3.TABLECODE=S3.COLINTEGER)
						Where C.STOPPAYREASON is not null
						and exists
						(select 1
						 from CASES_iLOG L
						 where L.CASEID=C.CASEID
						 and L.LOGDATETIMESTAMP>=@dtLogDateTime
						 and L.LOGTRANSACTIONNO=@nTransNo
						 and isnull(L.STOPPAYREASON,'')<>C.STOPPAYREASON)"

						Exec @nErrorCode=sp_executesql @sSQLString,
									N'@dtLogDateTime	datetime,
									  @nTransNo		int,
									  @nStopPayEvent	int',
									  @dtLogDateTime=@dtLogDateTime,
									  @nTransNo     =@nTransNo,
									  @nStopPayEvent=@nStopPayEvent

						If @nErrorCode=0
						Begin
							-----------------------------
							-- Changes to the Case title
							-- are to regenerate keywords
							-- derived from the title.
							-----------------------------
							Set @sSQLString="
							Delete from #TEMPCASES

							Insert into #TEMPCASES (CASEID)
							Select	C.CASEID
							From #TEMPCASESTOUPDATE T
							join CASES C		on (C.CASEID=T.CASEID)
							Where C.TITLE is not null
							and exists
							(select 1
							 from CASES_iLOG L
							 where L.CASEID=C.CASEID
							 and L.LOGDATETIMESTAMP>=@dtLogDateTime
							 and L.LOGTRANSACTIONNO=@nTransNo
							 and isnull(L.TITLE,'')<>C.TITLE)"
				
							Exec @nErrorCode=sp_executesql @sSQLString,
										N'@dtLogDateTime	datetime,
										  @nTransNo		int',
										  @dtLogDateTime=@dtLogDateTime,
										  @nTransNo=@nTransNo
							
							If @nErrorCode=0
								Exec @nErrorCode=dbo.cs_InsertKeyWordsFromTitle 
										@pbCaseFromTempTable=1
						End
					End

					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Update CASEEVENT
						Set	EVENTDATE   =CE.EVENTDATE,
							EVENTDUEDATE=CE.EVENTDUEDATE, 
							OCCURREDFLAG=CASE WHEN(CE.EVENTDATE is not null) THEN 1 ELSE 0 END,
							DATEDUESAVED=CE.DATEDUESAVED,
							EVENTTEXT   =CE.EVENTTEXT
						From CASEEVENT CE1
						join #TEMPSTOPPAY CE	on (CE.CASEID =CE1.CASEID
									and CE.EVENTNO=CE1.EVENTNO
									and CE.CYCLE  =CE1.CYCLE)
						Where checksum(CE1.EVENTDATE,CE1.EVENTDUEDATE,CE1.OCCURREDFLAG,CE1.DATEDUESAVED)
						    <>checksum(CE.EVENTDATE, CE.EVENTDUEDATE, CE.OCCURREDFLAG, CE.DATEDUESAVED)
						or isnull(CE1.EVENTTEXT,'') not like isnull(CE1.EVENTTEXT,'')"

						Exec @nErrorCode=sp_executesql @sSQLString
					End

					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Insert into CASEEVENT(CASEID, EVENTNO, CYCLE, EVENTDATE, EVENTDUEDATE, OCCURREDFLAG, DATEDUESAVED, EVENTTEXT)
						Select	T.CASEID, 
							T.EVENTNO, 
							T.CYCLE, 
							T.EVENTDATE,
							T.EVENTDUEDATE, 
							T.OCCURREDFLAG,
							T.DATEDUESAVED,
							T.EVENTTEXT
						From #TEMPSTOPPAY T
						left join CASEEVENT CE1	on (CE1.CASEID =T.CASEID
									and CE1.EVENTNO=T.EVENTNO
									and CE1.CYCLE  =T.CYCLE)
						Where CE1.CASEID is null"

						Exec @nErrorCode=sp_executesql @sSQLString
					End

					----------------------------------------
					-- Any changes to CASEEVENT will require
					-- Policing to be run.  Check the 
					-- Case Event log row 
					----------------------------------------
					Set @nPolicingRows=0

					If @nErrorCode=0
					and @bCaseEventLog=1
					Begin
						Set @sSQLString="
						Insert into #TEMPPOLICE(CASEID,EVENTNO,CYCLE,TYPEOFREQUEST)
						Select	CE.CASEID, CE.EVENTNO, CE.CYCLE, 
							CASE WHEN(CE.EVENTDATE is null and 
								  CE.EVENTDUEDATE is not null and 
								  CE.DATEDUESAVED=1) 
								THEN 2 
								ELSE 3
							END
						From #TEMPCASEMATCH T
						-- Find the CaseEvents that
						-- have been updated
						join (	select distinct CASEID, EVENTNO, CYCLE
							from CASEEVENT_iLOG
							where LOGDATETIMESTAMP>=@dtLogDateTime
							and LOGTRANSACTIONNO=@nTransNo) L
									on (L.CASEID=T.LIVECASEID)
						join CASEEVENT CE	on (CE.CASEID=L.CASEID
									and CE.EVENTNO=L.EVENTNO
									and CE.CYCLE=L.CYCLE)"

						Exec @nErrorCode=sp_executesql @sSQLString,
									N'@dtLogDateTime	datetime,
									  @nTransNo		int',
									  @dtLogDateTime=@dtLogDateTime,
									  @nTransNo=@nTransNo
						
						Set @nPolicingRows=@@Rowcount

						If  @nErrorCode=0
						and @nPolicingRows>0
						and @pbPoliceImmediately=1
						Begin
							------------------------------------------------------
							-- Get the Batchnumber to use for Police Immediately.
							-- BatchNumber is relatively shortlived so reset it
							-- by incrementing the maximum BatchNo on the Policing
							-- table.
							------------------------------------------------------
						
							Set @sSQLString="
							Update LASTINTERNALCODE
							set INTERNALSEQUENCE=P.BATCHNO+1,
							    @nPoliceBatchNo =P.BATCHNO+1
							from LASTINTERNALCODE L
							cross join (select max(isnull(BATCHNO,0)) as BATCHNO
								    from POLICING) P
							where TABLENAME='POLICINGBATCH'"
						
							exec @nErrorCode=sp_executesql @sSQLString,
										N'@nPoliceBatchNo		int	OUTPUT',
										  @nPoliceBatchNo=@nPoliceBatchNo	OUTPUT
						
							Set @nRowCount=@@Rowcount
						
							If  @nErrorCode=0
							and @nRowCount=0
							Begin
								Set @sSQLString="
								Insert into LASTINTERNALCODE(TABLENAME, INTERNALSEQUENCE)
								values ('POLICINGBATCH', 0)"
						
								exec @nErrorCode=sp_executesql @sSQLString
								
								set @nPoliceBatchNo=0
							End
						End

						-- Now load the live Policing table from the temporary table.
						
						If  @nErrorCode=0
						and @nPolicingRows>0
						Begin
							Set @sSQLString="
							insert into POLICING(DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, ONHOLDFLAG, CASEID, EVENTNO, CYCLE,  TYPEOFREQUEST,BATCHNO, SQLUSER, IDENTITYID)
							select getdate(), T.POLICINGSEQNO, 'EDE2-'+convert(varchar, getdate(), 121)+' '+convert(varchar,T.POLICINGSEQNO), 1, 0, T.CASEID, T.EVENTNO, T.CYCLE,  T.TYPEOFREQUEST, @nPoliceBatchNo, SYSTEM_USER, @pnUserIdentityId
							from #TEMPPOLICE T
							left join POLICING P	on (P.CASEID=T.CASEID
										and P.EVENTNO=T.EVENTNO
										and P.CYCLE=T.CYCLE
										and P.TYPEOFREQUEST=T.TYPEOFREQUEST)
							where P.CASEID is null"
						
							Exec @nErrorCode=sp_executesql @sSQLString,
										N'@pnUserIdentityId	int,
										  @nPoliceBatchNo	int',
										  @pnUserIdentityId = @pnUserIdentityId,
										  @nPoliceBatchNo   = @nPoliceBatchNo
						End
					End

					--------------------------------
					-- Update the Transaction Status
					-- and the EDEOUTSTANDINGISSUES
					--------------------------------
					If @nErrorCode=0
					Begin
						---------------------------------------------------------
						-- For the rule just processed update all of the matching
						-- transactions and set the status of the transaction.
						-- Also set the Default Narrative if one exists
						---------------------------------------------------------

						Set @sSQLString="
						Update EDETRANSACTIONBODY
						Set	TRANSSTATUSCODE=
								CASE	WHEN(RV.REVIEWTYPE='X')                     THEN 3480 -- Processed as Auto Update not allowed RFC37929
									WHEN(RV.REVIEWTYPE='O')			    THEN 3460 -- Operator Review
									WHEN(CD.TRANSACTIONCOMMENT     is not null) THEN 3460
									WHEN(MT.TRANSACTIONMESSAGETEXT is not null) THEN 3460
									-- Medium level issue)
									WHEN(convert(int,SUBSTRING(SI.DEFAULTNARRATIVE,1,11))=4011)
												THEN 3460 -- Operator Review
									WHEN(RV.REVIEWTYPE='S')	THEN 3470 -- Supervisor Review
												ELSE 3480 -- Processed
								END,
							TRANSACTIONRETURNCODE=	
								CASE WHEN(RV.REVIEWTYPE='X')
									THEN 'Case rejected'	-- RFC37929
								     WHEN(S.CASEID is not null)	
									THEN 'Cancellation Instruction'
								     WHEN(checksum(OLD.FAMILYNO)<>checksum(NEW.FAMILYNO)
								       or(OLD.FAMILYNO is null and NEW.FAMILYNO is null and OLD.NAMENO<>NEW.NAMENO))
									THEN 'New Case' -- Data Instructor changed to different family
								     WHEN(U.CASEID is not null)
									THEN 'Case Amended'
								     WHEN(U.CASEID is null and RV.REVIEWTYPE is null)
									THEN 'No Changes Made'
								END,
							TRANSNARRATIVECODE=	
								CASE WHEN(S.EVENTDATE<=getdate()) 
									THEN S.PASTDATENARRATIVE
								     WHEN(isnull(S.EVENTDATE,S.EVENTDUEDATE)>getdate())
									THEN S.FUTUREDATENARRATIVE
								     WHEN((checksum(OLD.FAMILYNO)<>checksum(NEW.FAMILYNO)
								       or(OLD.FAMILYNO is null and NEW.FAMILYNO is null and OLD.NAMENO<>NEW.NAMENO))
								      and RV.REVIEWTYPE is null		    -- Operator review not required
								      and SI.TRANSACTIONIDENTIFIER is null) -- Data Instructor changed and no issues
									THEN 4020	-- NEW CASES
								     WHEN(convert(int,SUBSTRING(SI.DEFAULTNARRATIVE,12,11))<>0)
									THEN convert(int,SUBSTRING(SI.DEFAULTNARRATIVE,12,11))
								     WHEN(U.CASEID is null and RV.REVIEWTYPE is null)
									THEN 4022	-- AMENDED CASES - NO CHANGE REQUIRED
								     WHEN(U.CASEID is not null and RV.REVIEWTYPE is null
								      and SI.TRANSACTIONIDENTIFIER is null)
									THEN 4021	-- AMENDED CASES
								END
						From EDETRANSACTIONBODY T
						join #TEMPCASEMATCH TM	 on (TM.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
						left join (	select TRANSACTIONIDENTIFIER, min(REVIEWTYPE) as REVIEWTYPE
								from #TEMPREVIEW
								group by TRANSACTIONIDENTIFIER) RV
									 on (RV.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
						left join #TEMPSTOPPAY S on (S.CASEID=TM.LIVECASEID)	-- has stop pay date or reason been set
						left join #TEMPCASENAME CN on (CN.TYPE='UPDATE'		-- check change of Data Instructor
									   and CN.CASEID=TM.LIVECASEID
									   and CN.NAMETYPE='DI')
						left join NAME OLD	   on (OLD.NAMENO=CN.OLDNAMENO)
						left join NAME NEW	   on (NEW.NAMENO=CN.NAMENO)
						left join EDETRANSACTIONCONTENTDETAILS CD
							on (CD.BATCHNO=T.BATCHNO
							and CD.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
							and CD.TRANSACTIONCOMMENT is not null)
						left join EDETRANSACTIONMESSAGEDETAILS MT
							on (MT.BATCHNO=T.BATCHNO
							and MT.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
							and MT.TRANSACTIONMESSAGETEXT is not null)
						left join #TEMPCASESTOUPDATE U
									on (U.CASEID=TM.LIVECASEID)	-- Cases have been amended
						left join (	select	O.BATCHNO, 
									O.TRANSACTIONIDENTIFIER, 
									-- the highest Severity has the lowest SeverityLevel
									min(left(replicate('0', 11-len(S.SEVERITYLEVEL))   +convert(CHAR(11), S.SEVERITYLEVEL)   ,11)+	
									    CASE WHEN(S.DEFAULTNARRATIVE<0) THEN '-' ELSE '0' END + RIGHT('0000000000'+replace(cast(S.DEFAULTNARRATIVE as nvarchar),'-',''),10)	  -- NOTE: DEFAULTNARRATIVE can be a negative number
									   ) as DEFAULTNARRATIVE
								from EDEOUTSTANDINGISSUES O
								join EDESTANDARDISSUE S	on (S.ISSUEID=O.ISSUEID)
								where S.SEVERITYLEVEL is not null
								group by O.BATCHNO, O.TRANSACTIONIDENTIFIER) SI
									on (SI.BATCHNO=T.BATCHNO
									and SI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
						Where T.BATCHNO=@pnBatchNo
						and TM.AMENDCASERULE=@nRuleNo"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@pnBatchNo	int,
									  @nRuleNo	int',
									  @pnBatchNo=@pnBatchNo,
									  @nRuleNo  =@nRuleNo
					End

					If @nErrorCode=0
					Begin
						---------------------------------------------------------------
						-- If the transaction found a draft case from an earlier batch,
						-- then the draft Case was replaced with this transaction. The
						-- earlier batch transaction for the matching draft case now
						-- needs to have its TRANSSTATUSCODE updated.
						-------------------------------------------------------------
						Set @sSQLString="
						Update EDETRANSACTIONBODY
						Set	TRANSSTATUSCODE   	=T1.TRANSSTATUSCODE,
							TRANSACTIONRETURNCODE	=T1.TRANSACTIONRETURNCODE,
							TRANSNARRATIVECODE	=T1.TRANSNARRATIVECODE
						From #TEMPCASEMATCH TM
						join EDECASEMATCH CM	  on (CM.TRANSACTIONIDENTIFIER=TM.TRANSACTIONIDENTIFIER)
						join EDECASEMATCH M	  on (M.DRAFTCASEID=CM.DRAFTCASEID
									  and M.BATCHNO<>CM.BATCHNO)
						join EDETRANSACTIONBODY T on (T.BATCHNO=M.BATCHNO
									  and T.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
						-- Use derived table to avoid ambiguous table error
						join (select * from EDETRANSACTIONBODY) T1
									  on (T1.BATCHNO=CM.BATCHNO
									  and T1.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
						Where CM.BATCHNO=@pnBatchNo
						and TM.AMENDCASERULE=@nRuleNo"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@pnBatchNo	int,
									  @nRuleNo	int',
									  @pnBatchNo=@pnBatchNo,
									  @nRuleNo  =@nRuleNo
					End

					--------------------------------------------------------
					-- Where the transaction has been successfully applied
					-- and no operator or supervisor review is required then
					-- any issues against the draft Case are to be moved
					-- to the live Case.
					-- This might cross multiple batches if the Draft Case
					-- belongs to more than one batch.
					--------------------------------------------------------
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Update EDEOUTSTANDINGISSUES
						set CASEID=TM.LIVECASEID
						from EDEOUTSTANDINGISSUES I
						join #TEMPCASEMATCH TM	  on (TM.DRAFTCASEID=I.CASEID)
						join EDETRANSACTIONBODY T on (T.BATCHNO=I.BATCHNO
									  and T.TRANSACTIONIDENTIFIER=I.TRANSACTIONIDENTIFIER)
						left join #TEMPREVIEW R   on (R.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									  and R.REVIEWTYPE='X')
						where TM.AMENDCASERULE=@nRuleNo
						AND T.TRANSSTATUSCODE=3480
						AND R.TRANSACTIONIDENTIFIER is null"
							
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo  =@nRuleNo
				
						
					End

					---------------------------------------
					-- Draft Cases that have been processed
					-- are now able to be deleted.
					---------------------------------------

					If @nErrorCode=0
					Begin
						---------------------------------------------
						-- Transactions that are marked as processed
						-- are to have the EDECASEDETAILS table point
						-- to the live CASEID before EDECASEMATCH is
						-- removed
						-- Note that this update may extend beyond 
						-- the current batch as the Draft Case from
						-- an earlier batch may have been replaced by
						-- this transaction.
						---------------------------------------------
						Set @sSQLString="
						Update EDECASEDETAILS 
						Set CASEID=C.LIVECASEID
						from #TEMPCASEMATCH TM
						join EDECASEMATCH C		on (C.DRAFTCASEID=TM.DRAFTCASEID)
						join EDECASEDETAILS E		on (E.BATCHNO=C.BATCHNO
										and E.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
						join EDETRANSACTIONBODY T	on (T.BATCHNO=E.BATCHNO
										and T.TRANSACTIONIDENTIFIER=E.TRANSACTIONIDENTIFIER)
						Where T.TRANSSTATUSCODE=3480
						and TM.AMENDCASERULE=@nRuleNo
						and isnull(E.CASEID,'')<>C.LIVECASEID"
				
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@pnBatchNo	int,
									  @nRuleNo	int',
									  @pnBatchNo=@pnBatchNo,
									  @nRuleNo  =@nRuleNo
					End

					If @nErrorCode=0
					Begin
						-----------------------------------------------------------
						-- First remove the EDECASEMATCH referencing the Draft Case
						-- Note that rows from other batches may be removed as the
						-- same draft case may belong in multiple batches.
						-----------------------------------------------------------
						Set @sSQLString="
						Delete EDECASEMATCH
						From #TEMPCASEMATCH TM
						join EDECASEMATCH CM	  on (CM.DRAFTCASEID=TM.DRAFTCASEID)
						join EDETRANSACTIONBODY T on (T.BATCHNO=CM.BATCHNO
									  and T.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
						where TM.AMENDCASERULE=@nRuleNo
						AND T.TRANSSTATUSCODE=3480"
							
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nRuleNo	int',
									  @nRuleNo  =@nRuleNo
					End

					If @nErrorCode=0
					Begin
						-------------------------------------------------
						-- Delete unprocessed Policing requests against
						-- the POLICING table if the Case has been
						-- removed from EDECASEMATCH.
						-------------------------------------------------
						Set @sSQLString="
						Delete POLICING
						from POLICING P
						join #TEMPCASEMATCH CM	  on (CM.DRAFTCASEID=P.CASEID)
						join EDETRANSACTIONBODY T on (T.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
						where T.BATCHNO=@pnBatchNo
						AND T.TRANSSTATUSCODE=3480
						and CM.AMENDCASERULE=@nRuleNo"
							
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@pnBatchNo	int,
									  @nRuleNo	int',
									  @pnBatchNo=@pnBatchNo,
									  @nRuleNo  =@nRuleNo
					End


					If @nErrorCode=0
					Begin
						---------------------------------
						-- RFC-63684
						-- Remove the relationship in RELATEDCASE 
						-- to the Draft Case 
						---------------------------------
						Set @sSQLString="
						Delete RELATEDCASE
						from RELATEDCASE R
						join #TEMPCASEMATCH CM	  on (CM.DRAFTCASEID=R.RELATEDCASEID)
						join EDETRANSACTIONBODY T on (T.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
						where T.BATCHNO=@pnBatchNo
						AND T.TRANSSTATUSCODE=3480
						and CM.AMENDCASERULE=@nRuleNo"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@pnBatchNo	int,
									  @nRuleNo	int',
									  @pnBatchNo=@pnBatchNo,
									  @nRuleNo  =@nRuleNo
					End
					
					
					If @nErrorCode=0
					Begin
						---------------------------------
						-- Now remove the Draft Case 
						-- which will remove child tables
						---------------------------------
						Set @sSQLString="
						Delete CASES
						from CASES C
						join #TEMPCASEMATCH CM	  on (CM.DRAFTCASEID=C.CASEID)
						join EDETRANSACTIONBODY T on (T.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
						where T.BATCHNO=@pnBatchNo
						AND T.TRANSSTATUSCODE=3480
						and CM.AMENDCASERULE=@nRuleNo"
							
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@pnBatchNo	int,
									  @nRuleNo	int',
									  @pnBatchNo=@pnBatchNo,
									  @nRuleNo  =@nRuleNo
					End

					-------------------------------------------------
					-- For each transaction that has been processed 
					-- insert a TRANSACTIONINFO row.
					-- This is done at the end of this transaction to
					-- keep locks on TRANSACTIONINFO short.
					-------------------------------------------------
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Insert into TRANSACTIONINFO(TRANSACTIONDATE, BATCHNO,TRANSACTIONIDENTIFIER,CASEID,TRANSACTIONMESSAGENO, TRANSACTIONREASONNO) 
						select getdate(),@pnBatchNo,T.TRANSACTIONIDENTIFIER,isnull(E.CASEID,T.LIVECASEID),
						CASE WHEN(B.TRANSACTIONRETURNCODE='No Changes Made' OR R.TRANSACTIONIDENTIFIER is not null) 
							THEN 3	-- No Changes Made
							ELSE 2	-- Amended Case
						END,
						@nReasonNo
						from EDETRANSACTIONBODY B
						join #TEMPCASEMATCH T	on (T.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER)
						left join EDECASEDETAILS E	
									on (E.BATCHNO=B.BATCHNO
									and E.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER)
						left join #TEMPCASESTOUPDATE U
									on (U.CASEID=T.LIVECASEID)	-- Case has been amended
						left join #TEMPREVIEW R on (R.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and R.REVIEWTYPE='X')
						where B.BATCHNO=@pnBatchNo
						and(B.TRANSSTATUSCODE=3480 -- Processed
						OR (B.TRANSSTATUSCODE in (3460,3470) and U.CASEID is not null))
						and T.AMENDCASERULE=@nRuleNo"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@pnBatchNo	int,
									  @nRuleNo	int,
									  @nReasonNo	int',
									  @pnBatchNo=@pnBatchNo,
									  @nRuleNo  =@nRuleNo,
									  @nReasonNo=@nReasonNo
					End

					-------------------------------------------------
					-- Insert a TRANSACTIONINFO row if the Stop Pay
					-- Event has been inserted or updated.
					-------------------------------------------------
					If @nErrorCode=0
					and @nStopPayEvent is not null
					Begin
						Set @sSQLString="
						Insert into TRANSACTIONINFO(TRANSACTIONDATE, BATCHNO,TRANSACTIONIDENTIFIER,CASEID,TRANSACTIONMESSAGENO,TRANSACTIONREASONNO) 
						select getdate(),@pnBatchNo,T.TRANSACTIONIDENTIFIER,T.LIVECASEID,5,@nReasonNo
						from EDETRANSACTIONBODY B
						join #TEMPCASEMATCH T	on (T.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER)
						join #TEMPPOLICE P	on (P.CASEID=T.LIVECASEID
									and P.EVENTNO=@nStopPayEvent
									and P.CYCLE=1)
						join CASEEVENT CE	on (CE.CASEID =P.CASEID
									and CE.EVENTNO=P.EVENTNO
									and CE.CYCLE=1)
						where B.BATCHNO=@pnBatchNo
						and T.AMENDCASERULE=@nRuleNo
						and CE.EVENTDATE is not null"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@pnBatchNo		int,
									  @nRuleNo		int,
									  @nStopPayEvent	int,
									  @nReasonNo		int',
									  @pnBatchNo    =@pnBatchNo,
									  @nRuleNo      =@nRuleNo,
									  @nStopPayEvent=@nStopPayEvent,
									  @nReasonNo    =@nReasonNo
					End

					-------------------------------------------------
					-- Insert a TRANSACTIONINFO row if the Start Pay
					-- Event has been inserted or updated.
					-------------------------------------------------
					If @nErrorCode=0
					and @nStartPayEvent is not null
					Begin
						Set @sSQLString="
						Insert into TRANSACTIONINFO(TRANSACTIONDATE, BATCHNO,TRANSACTIONIDENTIFIER,CASEID,TRANSACTIONMESSAGENO,TRANSACTIONREASONNO) 
						select getdate(),@pnBatchNo,T.TRANSACTIONIDENTIFIER,T.LIVECASEID,6,@nReasonNo
						from EDETRANSACTIONBODY B
						join #TEMPCASEMATCH T	on (T.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER)
						join #TEMPPOLICE P	on (P.CASEID=T.LIVECASEID
									and P.EVENTNO=@nStartPayEvent
									and P.CYCLE=1)
						join CASEEVENT CE	on (CE.CASEID =P.CASEID
									and CE.EVENTNO=P.EVENTNO
									and CE.CYCLE=1)
						where B.BATCHNO=@pnBatchNo
						and T.AMENDCASERULE=@nRuleNo
						and CE.EVENTDATE is not null"
					
						exec @nErrorCode=sp_executesql @sSQLString,
									N'@pnBatchNo		int,
									  @nRuleNo		int,
									  @nStartPayEvent	int,
									  @nReasonNo		int',
									  @pnBatchNo     =@pnBatchNo,
									  @nRuleNo       =@nRuleNo,
									  @nStartPayEvent=@nStartPayEvent,
									  @nReasonNo     =@nReasonNo
					End

					-- Commit entire transaction if successful
					If @@TranCount > @nTranCountStart
					Begin
						If @nErrorCode = 0
						Begin
							COMMIT TRANSACTION
						End
						Else Begin
							ROLLBACK TRANSACTION
						End
					End
		
					-- Terminate the WHILE loop
					Set @nRetry=-1
				END TRY

				---------------------------------
				-- D E A D L O C K   V I C T I M   
				--       P R O C E S S I N G
				---------------------------------
				BEGIN CATCH
					------------------------------------------
					-- If the process has been made the victim
					-- of a deadlock (error 1205), then allow 
					-- another attempt to apply the updates 
					-- to the database up to a retry limit.
					------------------------------------------
					If ERROR_NUMBER()=1205
						Set @nRetry=@nRetry-1
					Else
						Set @nRetry=-1
						
					-- Wait 1 second before attempting to
					-- retry the update.
					If @nRetry>0
						WAITFOR DELAY '00:00:01'
					Else
						Set @nErrorCode=ERROR_NUMBER()
						
					If XACT_STATE()<>0
						Rollback Transaction
					
					If @nRetry<1
					Begin
						-- Get error details to propagate to the caller
						Select 	@sErrorMessage = 'Error:' + cast(ERROR_NUMBER() as nvarchar) + ' - ' + ERROR_MESSAGE(),
							@nErrorSeverity = ERROR_SEVERITY(),
							@nErrorState    = ERROR_STATE(),
							@nErrorCode     = ERROR_NUMBER()

						-- Use RAISERROR inside the CATCH block to return error
						-- information about the original error that caused
						-- execution to jump to the CATCH block.
						RAISERROR ( @sErrorMessage,	-- Message text.
							    @nErrorSeverity,	-- Severity.
							    @nErrorState	-- State.
							   )
					End
				END CATCH
			End -- While loop

			------------------------------------------------
			-- Police Immediately
			-- If the Police Immediately option has been
			-- selected then run Policing within its own
			-- transacation.  This is safe to do because
			-- the Policing rows have already been committed
			-- to the database so any failure will ensure
			-- that the unprocessed requests will remain.
			-- Policing looks after its own transaction
			-- control.
			------------------------------------------------
			If  @nErrorCode=0
			and @nPolicingRows>0
			and @pbPoliceImmediately=1
			Begin
				exec @nErrorCode=dbo.ipu_Policing_async
							@pnBatchNo=@nPoliceBatchNo,
							@pnUserIdentityId=@pnUserIdentityId
			End

			-------------------------------
			-- Get the next rule to process
			-------------------------------
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Select @nRuleNo=min(AMENDCASERULE)
				FROM #TEMPCASEMATCH
				WHERE AMENDCASERULE>@nRuleNo"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@nRuleNo	int	OUTPUT',
							  @nRuleNo=@nRuleNo	OUTPUT
			End
		End -- End Update Rule Processing
	End -- @nTransactionCount>0

	-------------------------------------------------
	-- If transactions are still being looped through
	-- then reset the temporary tables for use in 
	-- the next cycle through the loop.
	-------------------------------------------------
 
	If @nReadyForProcess>@nLoopCount
	and @nErrorCode=0
	Begin
		-- Start a new transaction
		Set @nTranCountStart = @@TranCount
		BEGIN TRANSACTION

		set @sSQLString="
		Delete from dbo.#TEMPCASEMATCH"

		exec @nErrorCode=sp_executesql @sSQLString

		If @nErrorCode=0
		Begin
			set @sSQLString="
			Delete from dbo.#TEMPISSUE"

			exec @nErrorCode=sp_executesql @sSQLString
		End

		If @nErrorCode=0
		Begin
			-- Use truncate to reset Identity column
			set @sSQLString="
			truncate table dbo.#TEMPPOLICE"

			exec @nErrorCode=sp_executesql @sSQLString
		End

		If @nErrorCode=0
		Begin
			set @sSQLString="
			Delete from dbo.#TEMPREVIEW"

			exec @nErrorCode=sp_executesql @sSQLString
		End

		If @nErrorCode=0
		Begin
			set @sSQLString="
			Delete from dbo.#TEMPCASENAME"

			exec @nErrorCode=sp_executesql @sSQLString
		End

		If @nErrorCode=0
		Begin
			set @sSQLString="
			Delete from dbo.#TEMPDERIVEDEVENTCHANGED"

			exec @nErrorCode=sp_executesql @sSQLString
		End

		If @nErrorCode=0
		Begin
			set @sSQLString="
			Delete from dbo.#TEMPCASESTOUPDATE"

			exec @nErrorCode=sp_executesql @sSQLString
		End

		If @nErrorCode=0
		Begin
			set @sSQLString="
			Delete from dbo.#TEMPCASES"

			exec @nErrorCode=sp_executesql @sSQLString
		End

		If @nErrorCode=0
		Begin
			set @sSQLString="
			Delete from dbo.#TEMPSTOPPAY"

			exec @nErrorCode=sp_executesql @sSQLString
		End

		-- Commit entire transaction if successful
		If @@TranCount > @nTranCountStart
		Begin
			If @nErrorCode = 0
			Begin
				COMMIT TRANSACTION
			End
			Else Begin
				ROLLBACK TRANSACTION
			End
		End
	End
End	-- End main loop through transactions

RETURN @nErrorCode
go

grant execute on ede_UpdateLiveCasesFromDraft to public
go

