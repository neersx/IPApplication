-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_LoadDraftCasesFromEDE
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[ede_LoadDraftCasesFromEDE]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure ede_LoadDraftCasesFromEDE.'
	Drop procedure [dbo].[ede_LoadDraftCasesFromEDE]
End
Print '**** Creating Stored Procedure ede_LoadDraftCasesFromEDE...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO

CREATE PROCEDURE [dbo].[ede_LoadDraftCasesFromEDE]
			@pnRowCount		int=0	OUTPUT,
			@pnUserIdentityId	int,		-- Mandatory
			@psCulture		nvarchar(10)	= null,
			@pnBatchNo		int,		-- Mandatory
			@pbPoliceImmediately	bit	=1,	-- Option to run Police Immediately
			@pbReducedLocking	bit	=1
			
AS
-- PROCEDURE :	ede_LoadDraftCasesFromEDE
-- VERSION :	130
-- SCOPE:	CPA Inprotech
-- DESCRIPTION:	Import any number of Import Journal transactions initially delivered in an xml file.
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 29 Aug 2006	MF	12413	1	Procedure created
-- 24 Oct 2006	MF	13706	2	Improve performance by stripping non alpha numeric characters
--					from loaded OfficialNumbers in preparation for Case matching.
-- 26 Oct 2006	MF	12413	3	Duplicate Case problem
-- 01 Nov 2006	MF	12413	4	When full match was found the Live Case was not being returned.
-- 07 Nov 2006	MF	12413	5	Corrections from integration testing
-- 08 Nov 2006	MF	12413	6	Current Official Number should be updated on the draft case.
-- 08 Nov 2006	MF	12413	7	Valid Category and SubType edit is not correct.
-- 13 Nov 2006	MF	12413	8	Use EVENTDATE for EVENTDUEDATE if it is in the future and no
--					explicitly provided.
-- 13 Nov 2006	MF	13808	9	A partially processed batch that has been resubmitted is to 
--					continue processing.
-- 17 Nov 2006	MF	13743	10	Record existing and loaded data where relevant in Issues raised
-- 14 Dec 2006	MF	14025	11	Allow multiple transactions to point to the same live Case and
--					generate a different IRN for each draft Case in this situation.
-- 02 Jan 2007	AT	13473	12	Renamed Transaction Producer to Alternative Sender.
-- 12 Jan 2007	DR	13452	13	Set CASENAME columns CORRESPONDNAME and DERIVEDCORRNAME.
-- 31 Jan 2007	DR	13452	14	Fix setting of DERIVEDCORRNAME to prevent null value.
-- 31 Jan 2007	MF	12413	14 	Do not overwrite an existing TRANSNARRATIVECODE in EDETRANSACTIONBODY.
-- 01 Feb 2007	DL	14174	15	Only update EDEOUTSTANDINGISSUES.CASEID if CASEID exists in CASES.
-- 01 Feb 2007	DR	13452	16	Replace usage of fn_GetDerivedAttnNameNo with imbedded derivation SQL.
-- 06 Feb 2007	MF	13967	17	If a transaction to be processed matches with an existing Case and 
--					the details of the Transaction are such that no data would actually
--					be modified on the live Case then mark the transaction as 'Processed'
--					so no operator review is required.
-- 14 Feb 2007	DR	13452	18	Un-comment code to insert CASENAME records.
-- 26 Apr 2007	JS	14323	19	Added CASENAME attention name derivation logic for Debtor/Renewal Debtor. 
-- 30 Apr 2007	MF	12299	19	Change the Transaction Status to "Ready for Case Update" if a new Case,
--					partial or full match is found.
-- 08 May 2007	MF	12320	20	Update Case details for transactions received from Agent/IPO however
--					do not generate a Case if match is not found.
--						EDESENDERDETAILS.SENDERREQUESTTYPE = 'Agent Response'
--						EDETRANSACTIONCONTENTDETAILS.TRANSACTIONCODE = 'Renewal Response'
-- 25 May 2007	MF	14825	21	If no changes are detected then set the return code to 'No Changes Made'
-- 31 May 2007	MF	12299	22	If multiple case matches found then set to Operator Review
-- 13 Jun 2007	MF	12413	23	Update the EDETRANSACTIONHEADER and set its Batch Status on completion of batch.
-- 14 Jun 2007	MF	12413	24	Backout update of EDETRANSACTIONHEADER as this is being handled by a trigger.
-- 18 Jul 2007	MF	15039	25	Allow procedure to be called with ReducedLocking flag which will
--					limit the number of transactions to be processed within a batch at the one time.
-- 20 Jul 2007	MF	15039	26	Revisit to correct test problem.
-- 10 Aug 2007	MF	15155	27	Ensure Narrative is set if it is attached to an Issue being raised.
-- 10 Dec 2007	DL	15666	28	Filter duplicate Official Numbers for each transaction before adding to live table.
-- 12 Dec 2007	DL	15686	29	Add isnull to aggregate functions to eliminate warning error.
-- 01 Feb 2008	MF	15151	30	Only set the draft Case to a Partial Match (3253) if there is a single possible
--					live case matched to the draft.
-- 04 Feb 2008	MF	15869	31	Duplicate key error inserting into RELATEDCASE.
-- 06 Feb 2008	MF	15904	32	If a batch has no transactions waiting to be imported but does have transactions
--					ready for update then those transactions are to be processed.
-- 06 Mar 2008	MF	16079	33	Reduce the period of time that locks are held on the database by changing the 
--					default value for the @pbReducedLocking flag to be ON.  Policing needs to be run
--					immediately against the Draft Case so that certain validations requiring comparison
--					of derived events can be performed.  When the live case is to be updated Policing
--					no longer needs to be run immediately so change the option
-- 12 Mar 2008	MF	16048	34	Insert TRANSACTIONINFO row for each transaction marked as processed.
-- 27 Mar 2008	MF	16149	35	Correct Issue -29 to handle Country Group with null DateCommenced.
--					Correct Issue -26 to insert the dates found to not match.
-- 31 Mar 2008	MF	16159	36	When transactions are being processed one at a time instead of as an entire
--					batch, then we need to handle the situation where more than one transaction is
--					referring to the same live Case.  This should create multiple draft Cases.
-- 03 Apr 2008	MF	16193	37	Status is not being set against draft Case created because Events being set
--					must subsequently call Policing after the action has been opened.
-- 10 Apr 2008	MF	16107	38	If more than one current official number exists for a given Case and NumberType
--					then force the transaction through to operator review.
-- 14 Apr 2008	MF	16240	39	Some rejections that require the transaction to go to Operator Review will be
--					moved from the draft Case processing into the procedure for updating the 
--					live Case (eded_UpdateLiveCasesFromDraft). This is because it is valid in some
--					situations to automatically apply the updates even though the operator needs 
--					to review the Case.
-- 21 Apr 2008	MF	16281	39	When updating the TRANSACTIONINFO table, the TRANSACTIONREASONNO field needs to 
--					be set to EDEREQUESTTYPE.TRANSACTIONREASONNO for the Request Type of the batch 
--					being processed.
-- 21 Apr 2008	MF	16260	39	The Matching Criteria algorithm for matching case imported with a live case 
--					has bee changed so that it matches on any official number regardless of the 
--					number type and then uses the number type to determine if a full match or
--					a partial match has been achieved.
-- 09 May 2008	MF	16398	40	Classification greater than 11 characters in EDE record resulting in duplicate 
--					key error on CASETEXT. Corrected by using SUBSTRING to just take the first 11
--					characters.
-- 26 May 2008	MF	16430	41	Correction to collation error found during this SQA.
-- 29 May 2008	MF	16461	42	Cases marked as Operator Review are to also have the Mandatory Rules applied
--					so when the operator opens the draft Case any missing data is highlighted.
-- 30 May 2008	MF	16481	42	Reset the match level to 'unmapped' for Agent Response batches with transaction
--					code of 'Renewal Response'. 
-- 02 Jun 2008	MF	16489	43	When inserting an Event associated with a RelatedCase, ensure that the EventNo
--					determined from the Relationship is not flagged as being for Display Only purposes.
-- 03 Jun 2008	MF	16494	44	If Instructor is not supplied in the input data then copy the Name used for
--					the Requestor Name Type (Data Instructor).
-- 06 Jun 2008	MF	16494	45	Remove the validation check that the instructor must exists as it will now
--					default from the Requestor Name Type.
-- 26 Jun 2008	MF	16610	46	Prefix the POLICING.POLICINGNAME colum with EDE1- or EDE2- to indicate that this 
--					procedure inserted the row. This is for debugging reasons.
-- 30 Jun 2008	MF	16627	47	Force Policing to process the opening of the required Action for the draft Case
--					before any of the imported Events are inserted against the Case.  This will then
--					mimic the way a manual Case is entered.
-- 03 Jul 2008	MF	16645	48	If multiple renewal cycles are opened then it is possible to get an error 
--					comparing NRD against supplied date. Select the Action that allows the most cycles
--					then take the lowest opened cycle.
-- 10 Jul 2008	MF	16694	49	Change issue text for reported vs calculated date discrepancy
-- 21 Jul 2008	MF	16724	50	Related case should be created if there is a priority date event if there is
--					no priority number.
-- 25 Jul 2008	MF	16589	51	If EMP and SIG nametypes are not imported into the draft Case then check if
--					they can be defaulted.
-- 26 Aug 2008	MF	16847	52	No draft case being created when multiple transaction match to a live case
-- 21 Oct 2008	MF	17021	53	Raise issue -19 or -20 for new Cases where a Stop Pay Date has been provided.
--					Previously the issue was only raised if the Stop Pay Date was in the past.
-- 23 Oct 2008	MF	17020	54	If no match on CaseId, IRN or Official No but other matches to a single case then
--					treat as partial match.
-- 27 Oct 2008	MF	17063	55	Existing draft Case not correctly being replaced when same Case is matched in a subsequent batch.
-- 11 Dec 2008	MF	17136	56	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 27 Jan 2009	MF	17186	57	Transaction being set to 'Processed' without a Transaction Narrative
-- 11 Feb 2009	MF	17385	58	Extend SQA16589 to include any NameType that can be inherited from the Names loaded from EDE.
-- 18 Mar 2009	MF	17499	59	When a Case matches with multiple potential Cases then use a positive Draft CASEID in the same way
--					that New Cases get a positive number.  This is because it is possible that the Case will in fact end
--					up being treated as a new Case. If the operator does in fact match to an existing live Case then the
--					draft Case will be removed and one positive CASEID will be sacrificed.
-- 19 Mar 2009	MF	17449	60	Do not raise Renewal Maintenance discrepancy issue when calculated date is blank. If no calculated date
--					then this is because the base dates to calculate it have not been provided. If the EDE has provided
--					a reported date then this date will be used instead of the calculated date.
-- 20 Mar 2009	MF	16776	61	Report the existing value of Case Category and Sub Type if the imported value is not valid.
-- 26 Mar 2009	MF	17537	62	Performance improvement
-- 01 Apr 2009	MF	16776	63	Failed testing.
-- 31 Mar 2009	MF	17146	64	Pass the SENDERREQUESTTYPE to ede_FindCandidateCases as parameter @psRequestType.
-- 08 May 2009	MF	17541	65	The issue for no dates being supplied is only to be handled differently depending on whether the imported
--					case is a new case or not.  Different issues will be raised depending on the Case Match Level.
-- 18 May 2009	MF	17695	66	Inherited Names should also check if the Reference should also be inherited.
-- 20 May 2009	MF	17707	67	Revisit SQA17541 to handle the situation where IssueId -33 has not been made available in EDESTANDARDISSUE.
-- 27 May 2009	MF	17729	68	Move the updating of Instructor's Reference No. from Data Instructor's Reference No to before the code
--					that inherits other Name Types. This way the inheritance will get the benefit of the inheriting the
--					Reference No. as well.
-- 26 Jun 2009	MF	17505	69	If the transaction matches a previously created draft case from an earlier batch that has not yet been
--					processed, then leave the transaction on hold to wait for the earlier transaction to be completed.
-- 06 Jul 2009	MF	17849	70	If an earlier batch from the same sender has incomplete transactions then raise an issue against the
--					batch and stop processing of this batch.
-- 15 Jul 2009	MF	17872	71	Error when two transactions in batch match with the same live Case that has a draft Case outstanding.
-- 17 Jul 2009	MF	17863	72	After Policing has been called reset the transaction number and batch number for this batch into memory as
--					Policing will have reset these.
-- 21 Jul 2009	MF	17878	73	Clean up any incomplete batches that have failed after the Draft Case is created and committed while
--					leaving the transaction still as Ready For Import.
-- 24 Jul 2009	MF	16548	74	The FROMEVENTNO will now identify the Event from a related Case that will be pushed
--					into the child Case.
-- 03 Aug 2009	MF	17449	75	Do not raise Renewal Maintenance discrepancy issue when calculated date is blank. If no calculated date
--					then this is because the base dates to calculate it have not been provided. If the EDE has provided
--					a reported date then this date will be used instead of the calculated date.
-- 10 Aug 2009	MF	17937	76	When a draft Case is created and the initial Policing run, there may be Events created that are for 
--					the same EventNo as an event being imported. The imported Event should then update the existing event.
-- 31 Aug 2009	MF	17971	77	If batches have been processed out of sequence for a given Sender then when the earlier batch is processed
--					it may match on draft Cases that are still waiting for Operator Review. Rather than block the earlier batch, 
--					the matching draft Cases from the later batch will be deleted and the transaction status on the later batch
--					updated to Ready for Import. This will then allow it to be reprocessed in the correct sequence.
-- 31 Aug 2009	MF	17986	78	Revisit of 17449. IssueId -14 (Renewal Date not calculated), is to be reported irrespective of whether the
--					user has supplied a Renewal Date or not.
-- 08 Sep 2009	MF	18014	79	Duplicate key error when trying to import CASETEXT data with invalid CLASS data.
-- 10 Sep 2009	MF	18027	80	Restructure code to avoid using ISNULL on joins involving the CASEEVENT table. These were found to cause
--					serious performance issues on large batches.
-- 14 Sep 2009	MF	17971	81	Revisit after test failure.
-- 15 Oct 2009	MF	17949	82	Validation issues to be checked after the draft Case are to be determined by looking up the EDE Rules
--					for Special Issues. If the issueid exists in the EDERULESPECIALISSUE table then the validation may occur,
--					otherwise ignore.
-- 14 Dec 2009	MF/vql	18309	83	RN Action not opening for EDE cases with only client reported renewal date.
-- 18 Jan 2010	MF	18352	84	Determinine the current cycle of a cyclic Event should use the Open Cyclic Action as the preference.  If
--					there is no open action the the lowest cycle of the event that has a due date is to be used and finally
--					if there are no due dates then the highest cycle of an event that has occured will be used.
-- 06 Apr 2010	MF	18610	85	Related to 17449. If the transaction being raised has more than one non severe issue against it then a 
--					duplicate key error is occurring during the insert into CASEEVENT.
-- 03 Jun 2010	MF	18702	86	Remove any orphan EDECASEMATCH rows whose Draft Case is no longer in the CASES table.
-- 02 Dec 2010	MF	18403	87	Update related caseid if the Related Case details loaded can now be resolved to an actual case on the database.
-- 26 May 2011	MF	19637	88	When an imported Event does not specify a Cycle then it is currently being set to 1. This is correct if the
--					cycle is non cyclic however if the Event allows cycles then use the CONTROLLINGACTION held against the Event
--					to determine the lowest Open Action if the Action is cyclic otherwise set the cycle to the next available cycle 
--					if the Action is not cyclic.
-- 24 Jul 2012	MF	16184	89	Allow the data that has been retrieved from PTO Access ( RequestType='Extract Cases Response') to be imported into Inprotech.
-- 17 Sep 2012	MF	20830	90	If the Draft Case does not have a Stop Pay Date and Reason but either of these exist on the Live Case then an issue is 
--					to be raised to allow operator review.
-- 05 Jul 2013	vql	R13629	91	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 27 Aug 2014	MF	R38519	92	Cater for Type Of Mark as an input field associated with the Case.
-- 29 Aug 2014	MF	R37928	92	Cater for user provided IRN
-- 29 Aug 2014	MF	R38555	92	Cater for user provided STEM
-- 29 Aug 2014	MF	R38913	92	Name Code used in IRN Generation was being excluded. Move the IRN Generation to after all names are added to Case.
-- 04 Sep 2014	MF	R38519	93	Correction after test fail.
-- 08 Sep 2014	MF	R39030	94	Suppress issue -35 for the batch when the sender is the home name
-- 09 Sep 2014	MF	R37922	95	Recognise the Request Type "Case Import".
-- 19 Sep 2014	MF	R39669	96	EDE appeared to be looping on a very large batch when it found that a large number of transactions already had a draft
--					case still being processed in an earlier batch.
-- 08 Oct 2014	MF	R40322	96	If a country uses the international class system then we can use the provided local classes to load the international
--					class or vice versa.
-- 16 Oct 2014	MF	R40469	97	When validating a Country also consider if the Date Ceased for the country is in the past.
-- 12 Jan 2015	AT	R42920	98	Add try catch around cs_ApplyGeneratedReference. Leave status as Ready For Case Import when there are IRN generation issues.
-- 13 Mar 2015	MF	R45318	99	Reciprocal relationship not being inserted where imported case relates to existing Inprotech case.
-- 14 Sep 2015	MF	51926	100	When CLASSNUMBER is a single non zero digit then concatenate a leading zero.
-- 23 Dec 2015	MF	56512	101	Revisit of 51926 as there was another place where CLASSNUMBER required concatenation of leading zero.
-- 08 Apr 2016	MF	60157	102	The system thinks that a draft for the Case already exists.  This is being caused because I found the database had "Set ANSI_NULLS off"
--					which resulted in a comparison of 2 NULL values being treated as a match. I have no idea why this setting was on for the client database
--					but as a safeguard I am adding an additional test to ensure there is a real match.
-- 27 May 2016	MF	61860	103	CASEEVENT being created from RelatedCase should use CaseRelation.EVENTNO and not FROMEVENTNO in the row being loaded.
-- 06 Jun 2016	MF	62404	104	Reciprocal relationships not always being created between Cases loaded in the one batch.
-- 01 Jul 2016	DL	63684	105	Case Import batch is failing with referential integrity error - Remove RELATEDCASE that link to the draft case.
-- 04 Jul 2016	MF	63301	106	Revisit 62404. Ensure RELATEDCASEID exists before inserting into RELATEDCASE.
-- 05 Jul 2016	MF	63631	107	When creating the Case check to see if the Status should default using the site control 'Case Default Status'.
-- 02 Aug 2016	MF	64248	108	CaseEvent for EventNo -14 will now be updated by database trigger so no need to perform this directly.
-- 01 Sep 2016	MF	66799	109	When reporting an issue -29 because designated countries are not members of the treaty country of the Case, the
--					invalid countries should be included in the issue being raised.
-- 06 Sep 2016	MF	63117	110	Raise an issue if a Related Case relationship is not configured as a valid relationship for the jurisdiction and property type.
-- 21 Sep 2016	MF	56450	111	Cases can now be added with the optional Office and Family.
-- 21 Nov 2016	MF	69597	112	When determining if a Draft Case already exists, need to handle the fact that matches on NULL can occur if the database has
--					ANSI_NULLS set to OFF.
-- 12 Dec 2016	MF	70090	113	Missing goods/services text when importing single digit classes.
-- 14 Feb 2017	MF	70614	114	Duplicate RelatedCase could be generated for reciprocal where one relationship is pointing directly to inprotech Case and the other 
--					is using an Official Number/Country which is being resolved to the same internal case.
-- 31 Mar 2017	MF	44603	115	Use the Web screen control to determine the Action to be opened.
-- 14 Jul 2017	MF	71794	116	An imported batch of cases must not include cases with a duplicated IRN within the batch.
-- 19 Jul 2017	MF	71793	117	When the jurisdiction (Country) of the case being imported has a ceased date in the passed, issue -43 is to be raised.
-- 19 Jul 2017	MF	71968	118	When determining the default Case program, first consider the Profile of the User.
-- 16 Aug 2017	MF	72191	119	Introduce new Request Type "Agent Input" that does not require a match on Instructor and Instructor Ref.
-- 17 Aug 2017	MF	72191	120	Failed testing.
-- 07 Sep 2017	MF	72347	121	Where IRN is being supplied for use in creation of new case, include a validation check that the IRN does
--					not already exist. Raise issue -44 when already in existence.
-- 08 Sep 2017	MF	72347	122	Extend the processing for Request Type "Agent Input" so that it does the same things as "Case Import".
-- 21 Dec 2017	MF	73189	123	A converstion error was occurring when DEFAULTNARRATIVE was a negative number.
-- 16 Jan 2018	MF	72841	124	For an "Agent Input" batch, if the reporting Agent is different to the existing Agent of a match case then raise issue -45. Depending
--					on the firm's severity level for that issue will then determine whether the change is rejected or sent to operator review.
-- 09 May 2018	MF	73661	125	When resolving a related case from its Official Number to a case already on the Inprotech database, we are currently insisting on using
--					the same Property Type as the case being related to.  This is not strictly always required (e.g. Patent can relate to Utility Model). This
--					change will remove this restriction, but where multiple cases match on the Official Number, a matching Property Type will be taken as 
--					the first preference.
-- 26 Jun 2018	MF	74433	126	When an imported Case matches on multiple Cases it will be given a MatchLevel of 3251 to indicate that the Case is unmapped which will
--					require operator review.  If IRN has been provided on the input record, then we need to keep that with the draft case created. This way
--					if the operator elects to create a new Case, the provided IRN will not be lost.
-- 27 Jun 2018	MF	74433	126	If the Case has a MatchLevel of 3251 (unmapped) then also check that the IRN  being supplied has not been used on a Case.
-- 14 Nov 2018  AV	DR-45358 127	Date conversion errors when creating cases and opening names in Chinese DB
-- 09 Apr 2019	MF	DR-48125 128	Insertion of inherited names was causing a duplicate key error, when multiple names for the same Name Type and same Company,
--					but with different correspondence names were being added.
-- 11 Jul 2019	MF	DR-50261 129	Official numbers that are linked to an Event should use the EventDate in the DateEntered of the Official Number.
-- 19 May 2020	DL	DR-58943 130	Ability to enter up to 3 characters for Number type code via client server	

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET ANSI_WARNINGS OFF	-- normally not recommended however required in this situation

Create table #TEMPCANDIDATECASES(
				TRANSACTIONIDENTIFIER	nvarchar(50)	collate database_default NOT NULL,
				CASEID			int		NOT NULL, 
				CASEIDMATCH		bit		NOT NULL, 
				IRNMATCH		bit		NOT NULL,
				REQUESTORMATCH		bit		NOT NULL,
				REQUESTORREFMATCH	bit		NOT NULL,
				INSTRUCTORMATCH		bit		NOT NULL,
				INSTRUCTORREFMATCH	bit		NOT NULL,
				NUMBERTYPEMATCH		int		NULL,
				OFFICIALNOMATCH		int		NULL,
				NOFUTURENAMEFOUND	bit		NOT NULL
				)

Create Unique Index XPKTEMPCANDIDATECASES ON #TEMPCANDIDATECASES
	(
	TRANSACTIONIDENTIFIER,
	CASEID
	)

Create table #TEMPCASEMATCH(	TRANSACTIONIDENTIFIER	nvarchar(50)	collate database_default NOT NULL,
				MATCHLEVEL		int		NULL,
				DRAFTCASEID		int		NULL,
				LIVECASEID		int		NULL,
				DRAFTALREADYEXISTS	bit		NULL,
				CREATEACTION		nvarchar(2)	collate database_default NULL,
				UPDATEREQUIRED		bit		default(0),
				MATCHINGBATCHNO		int		NULL,
				MATCHINGTRANSACTION	nvarchar(50)	collate database_default NULL,
				SPECIALISSUERULE	int		NULL
				)

Create table #TEMPCASES(	SEQUENCENO		int		identity(0,1),
				TRANSACTIONIDENTIFIER	nvarchar(50)	collate database_default NOT NULL
				)

Create table #TEMPCASESTOUPDATE(CASEID		int		NOT NULL,
				ISMODIFIED	bit		NULL)

Create table #TEMPPOLICING (	CASEID		int		NOT NULL,
				ACTION		nvarchar(3)	collate database_default NULL,
				EVENTNO		int		NULL,
				CYCLE		int		NOT NULL,
				TYPEOFREQUEST	smallint	NOT NULL,
				SEQUENCENO	int		identity(1,1)
				)

Create table #TEMPNUMBERCOUNT(	CASEID		int		NOT NULL,
				NUMBERTYPE	nvarchar(3)	collate database_default NOT NULL, 
				NUMBERCOUNT	smallint	NOT NULL)

declare @nTranCountStart 	int
declare	@nTransactionCount	int
declare	@sStates		nvarchar(600)
declare	@sAlertXML		nvarchar(400)

declare @nMaxTrans		int		-- number of transactions to process in parallel
declare @nReadyForImport	int		-- number of transaction waiting to be imported
declare @nReadyForUpdate	int		-- number of transactions waiting for update
declare @nNewCases		int		-- the number of new Cases where no possible match was found
declare @nMatchedCases		int		-- the number of Cases that have a potential Match
declare @nLiveCaseId		int		-- holds the highest CaseId number generated for new cases
declare @nDraftCaseId		int		-- holds the highest CaseId number generated for draft cases (that already have a live case)
declare @nExistDraftCases	int		-- number of draft Cases that are to be updated
declare @nMatchLevel		int		-- code that indicates the level of match achieved
declare @sProgramId		nvarchar(8)	-- default program to use for determining creation rules
declare @nDateFormat		tinyint		-- format of date to be reported in issues
declare @nCaseId		int
declare	@sIRN			nvarchar(30)
declare @nIssueNo		int		-- the Issue to be raised against the transaction
declare @nPoliceBatchNo		int		-- Batch number for Policing requests
declare	@nPolicingCount		int		-- Number of Policing rows
declare @nStopEventNo		int		-- EventNo set from Standing Instructions to indicate stop processing
declare @nStatus		int		-- Default starting status of Case
declare	@sNameType		nvarchar(3)
declare	@nSequenceNo		smallint
declare @nLoopCount		int
declare @sTimeStamp		nvarchar(24)
declare @bUseWebScreen	        bit
declare	@bDraftExists		bit
declare @bBlockBatchFlag	bit
declare	@bPolicingNotRequired	bit

Declare	@nTransNo		int
Declare @nOfficeID		int
Declare @nLogMinutes		int

-- Variables from the input batch
declare @sRequestorNameType	nvarchar(3)
declare	@sRequestType		nvarchar(50)
declare	@nSenderNameNo		int
declare	@nFamilyNo		int
declare @nReasonNo		int
declare	@nUpdateEventNo		int

-- Declare working variables
Declare	@sSQLString 		nvarchar(max)
Declare	@sSQLString1 		nvarchar(4000)
Declare	@sSQLString2 		nvarchar(4000)
Declare	@sSQLString3 		nvarchar(4000)
Declare @sLastTransId		nvarchar(50)
Declare @nErrorCode 		int
Declare @nRowCount		int
Declare @nOpenActionCount	int
Declare @nCaseEventCount	int
Declare @nRetry			int
Declare	@bHexNumber		varbinary(128)

-----------------------
-- Initialise Variables
-----------------------
Set 	@nErrorCode 	     = 0
Set	@nNewCases	     = 0
Set	@nMatchedCases	     = 0
Set	@pnRowCount	     = 0
Set	@nReadyForImport     = 0
Set	@nReadyForUpdate     = 0
Set	@nOpenActionCount    = 0
Set	@bPolicingNotRequired= 0
Set	@bUseWebScreen       = 0
Set	@sLastTransId	 =''

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
--------------------------------------
-- Get the sender details of the batch
--------------------------------------
If @nErrorCode=0
Begin
	---------------------------------------------------------------------------------
	-- Check to see if the Sender of the batch requires the Name of the sender
	-- to be associated with each Case.
	-- This is determined if there is a NameType associated with the type of request.
	---------------------------------------------------------------------------------
	Set @sSQLString="
	select	@sRequestorNameType  =R.REQUESTORNAMETYPE,
		@nSenderNameNo	     =S.SENDERNAMENO,
		@sRequestType	     =S.SENDERREQUESTTYPE,
		@nReasonNo	     =R.TRANSACTIONREASONNO,
		@nFamilyNo	     =N.FAMILYNO,
		@bPolicingNotRequired=isnull(R.POLICINGNOTREQUIRED,0),
		@nUpdateEventNo      =R.UPDATEEVENTNO
	from EDESENDERDETAILS S
	join EDEREQUESTTYPE R	on (R.REQUESTTYPECODE=S.SENDERREQUESTTYPE)
	join NAME N		on (N.NAMENO=S.SENDERNAMENO)
	where S.BATCHNO=@pnBatchNo"
	
	Exec @nErrorCode=sp_executesql @sSQLString,
				N'@sRequestorNameType	nvarchar(3)		OUTPUT,
				  @nSenderNameNo	int			OUTPUT,
				  @sRequestType		nvarchar(50)		OUTPUT,
				  @nReasonNo		int			OUTPUT,
				  @nFamilyNo		int			OUTPUT,
				  @bPolicingNotRequired	bit			OUTPUT,
				  @nUpdateEventNo	int			OUTPUT,
				  @pnBatchNo		int',
				  @sRequestorNameType	=@sRequestorNameType	OUTPUT,
				  @nSenderNameNo	=@nSenderNameNo		OUTPUT,
				  @sRequestType		=@sRequestType		OUTPUT,
				  @nReasonNo		=@nReasonNo		OUTPUT,
				  @nFamilyNo		=@nFamilyNo		OUTPUT,
				  @bPolicingNotRequired	=@bPolicingNotRequired	OUTPUT,
				  @nUpdateEventNo	=@nUpdateEventNo	OUTPUT,
				  @pnBatchNo		=@pnBatchNo
End

-----------------------------------------------
-- RFC39030
-- If the Sender of the Batch is the HomeNameNo
-- and the Request Type is 'Case Import' then
-- no need to check for earlier batch from the
-- same sender.
-----------------------------------------------
Set @bBlockBatchFlag=0

If @nErrorCode=0
and not exists (select 1 
		from SITECONTROL S 
		where S.CONTROLID='HOMENAMENO'
		and S.COLINTEGER=@nSenderNameNo
		and @sRequestType='Case Import')
Begin
	---------------------------------------------------------------
	-- Check to see if there are any earlier Batches from the same 
	-- sender that still have outstanding transactions open.
	-- If so then the current batch will not be allowed to proceed.
	---------------------------------------------------------------	
	Set @sSQLString="
	Select	@bBlockBatchFlag=1
	from EDESENDERDETAILS S
	join PROCESSREQUEST P		on (P.BATCHNO<S.BATCHNO)
	join EDESENDERDETAILS S1	on (S1.BATCHNO=P.BATCHNO
					and S1.SENDERNAMENO=S.SENDERNAMENO)		 
	where S.BATCHNO=@pnBatchNo"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@bBlockBatchFlag	bit		OUTPUT,
				  @pnBatchNo		int',
				  @bBlockBatchFlag=@bBlockBatchFlag	OUTPUT,
				  @pnBatchNo      =@pnBatchNo
	
	If @nErrorCode=0
	Begin

		Select @nTranCountStart = @@TranCount
		BEGIN TRANSACTION
		
		If @bBlockBatchFlag=0
		Begin
			--------------------------
			-- Delete any preexisting
			-- issues for -35 that are 
			-- no longer required for
			-- this batch.
			--------------------------
			Set @sSQLString="
			Delete I
			from EDEOUTSTANDINGISSUES I
			where I.BATCHNO=@pnBatchNo
			and I.ISSUEID=-35"
			
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int',
							  @pnBatchNo=@pnBatchNo
		End
		Else Begin
			  
			--------------------------------
			-- Raise issue -35 for Batches
			-- that have incomplete batches
			-- from the same sender.
			--------------------------------
			Set @sSQLString="
			Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, DATECREATED)
			Select	-35, S.BATCHNO, getdate()
			from EDESENDERDETAILS S
			left join EDEOUTSTANDINGISSUES I on (I.ISSUEID=-35
							 and I.BATCHNO=S.BATCHNO)				 
			where S.BATCHNO=@pnBatchNo
			and I.ISSUEID is null"

			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End
	
		Set @nTransactionCount=@@RowCount
	
		-- Commit transaction if successful
		If @@TranCount > @nTranCountStart
		Begin
			If @nErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
	End
End

If  @nErrorCode=0
and @bBlockBatchFlag=0
Begin
	----------------------------------------------------------
	-- Get the default ProgramId to use for determining rules
	-- about Name inheritance and the Action to open against
	-- the created draft cases
	-- Also if the @pbReducedLocking parameter is ON then get
	-- the maximum number of transactions to be processed in
	-- parallel.
	----------------------------------------------------------
	Set @sSQLString="
	Select @sProgramId=left(isnull(PA.ATTRIBUTEVALUE,S.COLCHARACTER),8),
	       @bUseWebScreen=CASE WHEN(PA.ATTRIBUTEVALUE is not null) THEN cast(1 as bit) ELSE cast(0 as bit) END,
	       @nDateFormat=CASE S1.COLINTEGER
				WHEN(1)	THEN 106
				WHEN(2) THEN 100
				WHEN(3)	THEN 111
					ELSE 103
			    END,
		@nMaxTrans=isnull(S2.COLINTEGER,1),
		@nStatus  =S3.COLINTEGER
	from SITECONTROL S
	     join USERIDENTITY U        on (U.IDENTITYID=@pnUserIdentityId)
	left join PROFILEATTRIBUTES PA  on (PA.PROFILEID=U.PROFILEID
					and PA.ATTRIBUTEID=2)	-- Default Cases Program
	left join SITECONTROL S1 on (S1.CONTROLID='Date Style')
	left join SITECONTROL S2 on (S2.CONTROLID='EDE Transaction Processing'
				 and @pbReducedLocking=1)
	left join SITECONTROL S3 on (S3.CONTROLID='Case Default Status')
	where S.CONTROLID='Case Screen Default Program'"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@sProgramId		nvarchar(8)	OUTPUT,
				  @nDateFormat		tinyint		OUTPUT,
				  @nMaxTrans		int		OUTPUT,
				  @nStatus		int		OUTPUT,
				  @bUseWebScreen	bit		OUTPUT,
				  @pnUserIdentityId	int,
				  @pbReducedLocking	bit',
				  @sProgramId 	   =@sProgramId		OUTPUT,
				  @nDateFormat	   =@nDateFormat	OUTPUT,
				  @nMaxTrans  	   =@nMaxTrans		OUTPUT,
				  @nStatus         =@nStatus		OUTPUT,
				  @bUseWebScreen   =@bUseWebScreen	OUTPUT,
				  @pnUserIdentityId=@pnUserIdentityId,
				  @pbReducedLocking=@pbReducedLocking

	-- If no EDE Transaction Processing size has 
	-- been set greater than zero then turn off
	-- Reduced Locking flag and process the 
	-- entire batch.
	If  @nMaxTrans=0
	and @pbReducedLocking=1
		Set @pbReducedLocking=0
End

If @nErrorCode=0
and @bBlockBatchFlag=0
Begin
	----------------------------------------------------------
	-- Get the total number of transactions that have a status
	-- of 'Ready for Case Import'.
	-- This number will be used as a safeguard to ensure that
	-- and endless loop cannot occur.
	-- Also check for the number of transactions with status
	-- of 'Ready for Case Update' or 'Operator Review'.
	----------------------------------------------------------
	Set @sSQLString="
	Select  @nReadyForImport=@nReadyForImport+CASE WHEN(B.TRANSSTATUSCODE=3440)           THEN 1 ELSE 0 END,
		@nReadyForUpdate=@nReadyForUpdate+CASE WHEN(B.TRANSSTATUSCODE in (3450,3460)) THEN 1 ELSE 0 END
	From EDETRANSACTIONBODY B
	where B.BATCHNO=@pnBatchNo
	and   B.TRANSSTATUSCODE in (3440,3450,3460)	--'Ready For Case Import','Ready For Case Update' or 'Operator Review'"


	Exec @nErrorCode=sp_executesql @sSQLString,
				N'@nReadyForImport	int		OUTPUT,
				  @nReadyForUpdate	int		OUTPUT,
				  @pnBatchNo		int',
				  @nReadyForImport=@nReadyForImport	OUTPUT,
				  @nReadyForUpdate=@nReadyForUpdate	OUTPUT,
				  @pnBatchNo	  =@pnBatchNo

	Set @nLoopCount=0
End

	
----------------------------------
-- Transactions that have a status
-- of "Ready for Case Update" are
-- to be processed now if there
-- are no transactions requiring
-- import.
----------------------------------
If  @nErrorCode=0
and @nReadyForImport=0
and @nReadyForUpdate>0
Begin
	exec @nErrorCode=dbo.ede_UpdateLiveCasesFromDraft
				@pnUserIdentityId	=@pnUserIdentityId,			
				@pnBatchNo		=@pnBatchNo,
				@pbPoliceImmediately	=0,
				@pbReducedLocking	=@pbReducedLocking,
				@pnMaxTrans		=@nMaxTrans
End

If @nErrorCode=0
and @nReadyForImport>0
Begin
	-----------------------------
	-- B A T C H    C L E A N U P
	-----------------------------
	
	Select @nTranCountStart = @@TranCount
	BEGIN TRANSACTION
	
	----------------------------------------------------------------
	-- Remove any draft Cases that incomplete transactions have left
	-- when the transaction is still 'Read For Case Import'. 
	-- This might occur if the batch had previously failed after
	-- the draft Cases had been created and committed.
	----------------------------------------------------------------
	If @nErrorCode=0
	Begin
		---------------------------------
		-- RFC-63684
		-- Remove the relationship in RELATEDCASE 
		-- to the Draft Case before removing the draft case
		---------------------------------
		set @sSQLString="
		Delete R
		From EDETRANSACTIONBODY B
		join EDECASEMATCH M on (M.BATCHNO=B.BATCHNO
				    and M.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER)
		join RELATEDCASE R  on (R.RELATEDCASEID=M.DRAFTCASEID)
		where B.BATCHNO=@pnBatchNo
		and   B.TRANSSTATUSCODE=3440"	--'Ready For Case Import'

		Exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo	int',
					  @pnBatchNo=@pnBatchNo

	End
	

	If @nErrorCode=0
	Begin  
		set @sSQLString="
		Delete C
		From EDETRANSACTIONBODY B
		join EDECASEMATCH M on (M.BATCHNO=B.BATCHNO
				    and M.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER)
		join CASES C        on (C.CASEID=M.DRAFTCASEID)
		where B.BATCHNO=@pnBatchNo
		and   B.TRANSSTATUSCODE=3440"	--'Ready For Case Import'

		Exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo	int',
					  @pnBatchNo=@pnBatchNo
	End	
	
				
	If @nErrorCode=0
	Begin  
		----------------------------------------------------------------
		-- Remove any EDECASEMATCH rows that may exist for transactions
		-- of this batch that are at the 'Ready For Case Import' status.
		-- This will cleanup any batches that have failed previously.
		----------------------------------------------------------------
		set @sSQLString="
		Delete M
		From EDETRANSACTIONBODY B
		join EDECASEMATCH M on (M.BATCHNO=B.BATCHNO
				    and M.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER)
		where B.BATCHNO=@pnBatchNo
		and   B.TRANSSTATUSCODE=3440"	--'Ready For Case Import'

		Exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo	int',
					  @pnBatchNo=@pnBatchNo
	End
	
	If @nErrorCode=0
	Begin
		--------------------------
		-- Delete any preexisting
		-- issues for -34 that are 
		-- no longer required.
		--------------------------
		Set @sSQLString="
		Delete I
		from EDEOUTSTANDINGISSUES I
		join EDETRANSACTIONBODY B on (B.BATCHNO=I.BATCHNO
					  and B.TRANSACTIONIDENTIFIER=I.TRANSACTIONIDENTIFIER
					  and B.TRANSSTATUSCODE=3440)	--'Ready For Case Import'
		where I.BATCHNO=@pnBatchNo
		and I.ISSUEID=-34"
		
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
End

-------------------------------------------------------------------------------------
-- LOOP THROUGH VALID TRANSACTIONS
-------------------------------------------------------------------------------------
-- For performance reasons the transactions to be processed in parallel may be varied.
-- The lower the number of transactions, the least amount of time locks will be held
-- on the database.  The larger the number of transactions, the faster the overall 
-- processing time for the entire batch will be.
-------------------------------------------------------------------------------------

-- Continue looping until all Transactions marked as "Ready For Case Import"
-- have been processed or until the process has looped as many times as there
-- are available transactions (this is to stop endless looping)
-- or until an Issue -34 has been raised against a tran

While @nReadyForImport>@nLoopCount
and   @nErrorCode=0
and   Exists(select 1 from EDETRANSACTIONBODY B
             left join EDEOUTSTANDINGISSUES I	on (I.BATCHNO=B.BATCHNO
						and I.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER
						and I.ISSUEID=-34)
	     where B.BATCHNO=@pnBatchNo
	     and B.TRANSSTATUSCODE=3440 -- 'Ready For Case Import'
	     and I.TRANSACTIONIDENTIFIER is null)
Begin	
	-- Increment the Loop Count if the reduced locking
	-- mechanism is in use.
	If @pbReducedLocking=1
		Set @nLoopCount=@nLoopCount+(CASE WHEN(@nMaxTrans>1) THEN @nMaxTrans-1 ELSE 1 END )	-- Increment the loop count by the number of rows being processed (less 1) in each iteration
	Else
		Set @nLoopCount=@nReadyForImport

	-------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------
	-- CHECK FOR VALID TRANSACTIONS
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
	
		------------------------------------------------------------------------------
		-- Only transactions in the given batch which are valid to this point 
		-- (ie. where transaction status = ‘Ready For Case Import’) will be processed.
		------------------------------------------------------------------------------ 
	
		set @sSQLString="
		Insert into #TEMPCASEMATCH(TRANSACTIONIDENTIFIER)
		Select "+CASE WHEN(@pbReducedLocking=1) THEN "TOP "+convert(varchar,@nMaxTrans)+" " END+
		"B.TRANSACTIONIDENTIFIER
		From EDETRANSACTIONBODY B with (UPDLOCK)
		left join EDECASEMATCH M on (M.BATCHNO=B.BATCHNO
					 and M.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER)
		where B.BATCHNO=@pnBatchNo
		and   B.TRANSSTATUSCODE=3440	--'Ready For Case Import'
		and   B.TRANSACTIONIDENTIFIER>@sLastTransId
		and   M.BATCHNO is null		-- Ensure the transaction has not already been processed
		Order by B.TRANSACTIONIDENTIFIER"

		Exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int,
					  @sLastTransId		nvarchar(50)',
					  @pnBatchNo	=@pnBatchNo,
					  @sLastTransId	=@sLastTransId
	
		Set @nTransactionCount=@@RowCount
	
		-- Commit transaction if successful
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
		set @sSQLString="
		Select @sLastTransId=max(TRANSACTIONIDENTIFIER)
		from #TEMPCASEMATCH"
	
		Exec @nErrorCode=sp_executesql @sSQLString,
					N'@sLastTransId		nvarchar(50)	OUTPUT',
					  @sLastTransId	=@sLastTransId		OUTPUT
	End	
		
	-------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------
	-- VALIDATION - BEFORE CASE MATCHING
	-------------------------------------------------------------------------------------
	-- If the fields which are necessary to create a case are not provided 
	-- or are invalid, the appropriate issue will be created and the transaction flagged 
	-- as rejected. 
	-- The required fields are defined in the EDE Processing Rules for new cases.
	-------------------------------------------------------------------------------------
	If  @nErrorCode=0
	and @nTransactionCount>0
	Begin
		Select @nTranCountStart = @@TranCount
		BEGIN TRANSACTION
	
		--------------------
		-- Validate CaseType
		--------------------
		Set @nIssueNo = -1
	
		Set @sSQLString="
		Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED, REPORTEDVALUE)
		Select @nIssueNo, C.BATCHNO, C.TRANSACTIONIDENTIFIER, getdate(), C.CASETYPECODE_T
		from EDECASEDETAILS C
		join #TEMPCASEMATCH M		on (M.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
		left join CASETYPE CT		on (CT.ACTUALCASETYPE=C.CASETYPECODE_T)
		left join EDEOUTSTANDINGISSUES I on (I.ISSUEID=@nIssueNo
						and  I.BATCHNO=C.BATCHNO
						and  I.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
		where C.BATCHNO=@pnBatchNo
		and I.ISSUEID   is null
		and CT.CASETYPE is null"
	
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo	int,
					  @nIssueNo	int',
					  @pnBatchNo=@pnBatchNo,
					  @nIssueNo =@nIssueNo
	
		If @nErrorCode=0
		Begin
			--------------------------
			-- Validate Country Exists
			--------------------------
			Set @nIssueNo = -3
	
			Set @sSQLString="
			Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED, REPORTEDVALUE)
			Select @nIssueNo, C.BATCHNO, C.TRANSACTIONIDENTIFIER, getdate(), C.CASECOUNTRYCODE_T
			from EDECASEDETAILS C
			join #TEMPCASEMATCH M		 on (M.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			left join COUNTRY CY		 on (CY.COUNTRYCODE=C.CASECOUNTRYCODE_T)
			left join EDEOUTSTANDINGISSUES I on (I.ISSUEID=@nIssueNo
							 and I.BATCHNO=C.BATCHNO
							 and I.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			where C.BATCHNO=@pnBatchNo
			and I.ISSUEID is null
			and CY.COUNTRYCODE is null"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int,
						  @nIssueNo	int',
						  @pnBatchNo=@pnBatchNo,
						  @nIssueNo =@nIssueNo
		End
	
		If @nErrorCode=0
		Begin
			--------------------------------------------
			-- Validate Country has ceased (in the past)
			-- or is yet to commence (in the future). 
			--------------------------------------------
			Set @nIssueNo = -43
	
			Set @sSQLString="
			Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED, REPORTEDVALUE)
			Select @nIssueNo, C.BATCHNO, C.TRANSACTIONIDENTIFIER, getdate(), C.CASECOUNTRYCODE_T
			from EDECASEDETAILS C
			join #TEMPCASEMATCH M		 on (M.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			join COUNTRY CY			 on (CY.COUNTRYCODE=C.CASECOUNTRYCODE_T)
			left join EDEOUTSTANDINGISSUES I on (I.ISSUEID=@nIssueNo
							 and I.BATCHNO=C.BATCHNO
							 and I.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			where C.BATCHNO=@pnBatchNo
			and I.ISSUEID is null
			and(CY.DATECOMMENCED>getdate() OR CY.DATECEASED<getdate())"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int,
						  @nIssueNo	int',
						  @pnBatchNo=@pnBatchNo,
						  @nIssueNo =@nIssueNo
		End
	
		If @nErrorCode=0
		Begin
			-------------------------
			-- Validate Property Type
			-------------------------
			Set @nIssueNo = -2
	
			Set @sSQLString="
			Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED, REPORTEDVALUE)
			Select @nIssueNo, C.BATCHNO, C.TRANSACTIONIDENTIFIER, getdate(), C.CASEPROPERTYTYPECODE_T
			from EDECASEDETAILS C
			join #TEMPCASEMATCH M		on (M.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			left join VALIDPROPERTY P	on (P.PROPERTYTYPE=C.CASEPROPERTYTYPECODE_T
							and P.COUNTRYCODE=(select min(P1.COUNTRYCODE)
									   from VALIDPROPERTY P1
									   where P1.COUNTRYCODE in ('ZZZ',C.CASECOUNTRYCODE_T)))
			left join EDEOUTSTANDINGISSUES I	on (I.ISSUEID=@nIssueNo
							and I.BATCHNO=C.BATCHNO
							and I.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			where C.BATCHNO=@pnBatchNo
			and I.ISSUEID is null
			and P.PROPERTYTYPE is null"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int,
						  @nIssueNo	int',
						  @pnBatchNo=@pnBatchNo,
						  @nIssueNo =@nIssueNo
		End
	
		If @nErrorCode=0
		Begin
			-------------------------------
			-- Check that no duplicate Case
			-- References (in this batch)
			-- have been supplied
			-------------------------------
			Set @nIssueNo = -42
	
			Set @sSQLString="
			Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED, REPORTEDVALUE)
			Select DISTINCT @nIssueNo, C.BATCHNO, C.TRANSACTIONIDENTIFIER, getdate(), C.RECEIVERCASEREFERENCE
			from EDECASEDETAILS C
			join EDECASEDETAILS C1		on (C1.BATCHNO=C.BATCHNO				-- In the same batch
							and C1.RECEIVERCASEREFERENCE= C.RECEIVERCASEREFERENCE	-- the Case Reference matches 
							and C1.TRANSACTIONIDENTIFIER<>C.TRANSACTIONIDENTIFIER)	-- on a different transaction.
			left join EDEOUTSTANDINGISSUES I on(I.ISSUEID=@nIssueNo
							and I.BATCHNO=C.BATCHNO
							and I.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			where C.BATCHNO=@pnBatchNo
			and I.ISSUEID is null"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int,
						  @nIssueNo	int',
						  @pnBatchNo=@pnBatchNo,
						  @nIssueNo =@nIssueNo
		End
	
		If @nErrorCode=0
		Begin
			---------------------------
			-- Official Numbers Missing
			---------------------------
			Set @nIssueNo = -8
	
			Set @sSQLString="
			Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED)
			Select @nIssueNo, C.BATCHNO, C.TRANSACTIONIDENTIFIER, getdate()
			from EDECASEDETAILS C
			join #TEMPCASEMATCH M		 on (M.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			left join EDEOUTSTANDINGISSUES I on (I.ISSUEID=@nIssueNo
							 and I.BATCHNO=C.BATCHNO
							 and I.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			where C.BATCHNO=@pnBatchNo
			and I.ISSUEID is null
			and not exists
			(select 1
			 from EDEIDENTIFIERNUMBERDETAILS N 
			 join NUMBERTYPES NT	on (NT.NUMBERTYPE=N.IDENTIFIERNUMBERCODE_T
						and NT.ISSUEDBYIPOFFICE=1)
			 where N.BATCHNO=C.BATCHNO
			 and N.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER
			 and N.IDENTIFIERNUMBERTEXT is not null
			 and N.ASSOCIATEDCASERELATIONSHIPCODE is null)"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int,
						  @nIssueNo	int',
						  @pnBatchNo=@pnBatchNo,
						  @nIssueNo =@nIssueNo
		End
	
		If @nErrorCode=0
		Begin
			----------------------------
			-- No Identification Numbers
			----------------------------
			Set @nIssueNo = -9
	
			Set @sSQLString="
			Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED)
			Select @nIssueNo, C.BATCHNO, C.TRANSACTIONIDENTIFIER, getdate()
			from EDECASEDETAILS C
			join #TEMPCASEMATCH M		 on (M.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			left join EDEOUTSTANDINGISSUES I on (I.ISSUEID=@nIssueNo
							 and I.BATCHNO=C.BATCHNO
							 and I.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			where C.BATCHNO=@pnBatchNo
			and I.ISSUEID is null
			and C.SENDERCASEREFERENCE is null
			and not exists
			(select 1
			 from EDEIDENTIFIERNUMBERDETAILS N 
			 join NUMBERTYPES NT on (NT.NUMBERTYPE=N.IDENTIFIERNUMBERCODE_T)
			 where N.BATCHNO=C.BATCHNO
			 and   N.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER
			 and   N.IDENTIFIERNUMBERTEXT is not null
			 and   N.ASSOCIATEDCASERELATIONSHIPCODE is null)"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int,
						  @nIssueNo	int',
						  @pnBatchNo=@pnBatchNo,
						  @nIssueNo =@nIssueNo
		End
	
		If @nErrorCode=0
		Begin
			------------------------------------
			-- Mark the rejected transactions as
			-- Processed if an issue has been
			-- raised with a reject severity
			------------------------------------
			Set @sSQLString="
			Update EDETRANSACTIONBODY
			Set TRANSSTATUSCODE=3480,
			    TRANSACTIONRETURNCODE='Case rejected',
			    TRANSNARRATIVECODE=CASE WHEN(T.TRANSNARRATIVECODE is not null) THEN T.TRANSNARRATIVECODE
						    WHEN(SI.DEFAULTNARRATIVE<>'')          THEN SI.DEFAULTNARRATIVE
						END
			From EDETRANSACTIONBODY T
			join (	select	O.BATCHNO, 
					O.TRANSACTIONIDENTIFIER, 
					min(isnull(S.DEFAULTNARRATIVE,'')) as DEFAULTNARRATIVE
				from EDEOUTSTANDINGISSUES O
				join EDESTANDARDISSUE S	on (S.ISSUEID=O.ISSUEID)
				where S.SEVERITYLEVEL=4010
				group by O.BATCHNO, O.TRANSACTIONIDENTIFIER) SI
					on (SI.BATCHNO=T.BATCHNO
					and SI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			Where T.BATCHNO=@pnBatchNo
			and T.TRANSSTATUSCODE=3440"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End
	
		If @nErrorCode=0
		Begin
			-------------------------------
			-- Strip non alpha numerics
			-- from loaded official numbers
			-- in preparation for Case
			-- matching
			-------------------------------
			Set @sSQLString="
			Update EDEIDENTIFIERNUMBERDETAILS
			set IDENTIFIERSTRIPPEDTEXT=dbo.fn_StripNonAlphaNumerics(IDENTIFIERNUMBERTEXT)
			From EDEIDENTIFIERNUMBERDETAILS N
			join #TEMPCASEMATCH M	on (M.TRANSACTIONIDENTIFIER=N.TRANSACTIONIDENTIFIER)
			Where N.BATCHNO=@pnBatchNo
			and N.IDENTIFIERSTRIPPEDTEXT is null
			and N.IDENTIFIERNUMBERTEXT is not null"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End
		-------------------------------------------------
		-- For each transaction that is rejected at this 
		-- stage insert a TRANSACTIONINFO row.
		-- This is done immediately before the COMMIT
		-- to keep locks on TRANSACTIONINFO short.
		-------------------------------------------------
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Insert into TRANSACTIONINFO(TRANSACTIONDATE, BATCHNO,TRANSACTIONIDENTIFIER, TRANSACTIONMESSAGENO,TRANSACTIONREASONNO) 
			select getdate(),B.BATCHNO,B.TRANSACTIONIDENTIFIER,4,@nReasonNo
			from #TEMPCASEMATCH M
			join EDETRANSACTIONBODY B on (B.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join (	select	distinct BATCHNO, TRANSACTIONIDENTIFIER
				from EDEOUTSTANDINGISSUES O
				join EDESTANDARDISSUE S	on (S.ISSUEID=O.ISSUEID)
				where S.SEVERITYLEVEL=4010) SI
					on (SI.BATCHNO=B.BATCHNO
					and SI.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER)
			where B.BATCHNO=@pnBatchNo
			and B.TRANSSTATUSCODE=3480"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int,
						  @nReasonNo	int',
						  @pnBatchNo=@pnBatchNo,
						  @nReasonNo=@nReasonNo
		End
	
		-- Commit transaction if successful
		If @@TranCount > @nTranCountStart
		Begin
			If @nErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
	
		If @nErrorCode=0
		Begin
			--------------------------------
			-- Delete the #TEMPCASEMATCH
			-- transactions that have failed
			-- the validation stage.
			--------------------------------
			Set @sSQLString="
			Delete #TEMPCASEMATCH
			from #TEMPCASEMATCH M
			join EDETRANSACTIONBODY B on (B.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			where B.BATCHNO=@pnBatchNo
			and B.TRANSSTATUSCODE=3480"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End
	End
	-------------------------------------------------------------------------------------
	-- 1. IDENTIFY/MATCH TO LIVE CASE
	-------------------------------------------------------------------------------------
	-- Load the candidate Cases for this batch that are returned from the stored procedure
	-- ede_FindCandidateCases into a temporary table
	-- This temporary table will list all of the possible Cases along with information
	-- indicating how the match occurred
	-- NOTE : The stored procedure ede_FindCandidateCases was developed so the same code
	--	  can be used in other places where we need to return a list of possible
	--	  cases to match on.
	-------------------------------------------------------------------------------------
	If  @nErrorCode=0
	and @nTransactionCount>0
	Begin
		Set @sSQLString="
		insert into #TEMPCANDIDATECASES(TRANSACTIONIDENTIFIER, CASEID, CASEIDMATCH, IRNMATCH, 
						REQUESTORMATCH, REQUESTORREFMATCH, INSTRUCTORMATCH, 
						INSTRUCTORREFMATCH, NUMBERTYPEMATCH, OFFICIALNOMATCH, NOFUTURENAMEFOUND)
		exec ede_FindCandidateCases
				@pnBatchNo	    =@pnBatchNo,
				@psRequestorNameType=@sRequestorNameType,
				@pnSenderNameNo	    =@nSenderNameNo,
				@pbDraftCaseSearch  =0,
				@psRequestType      =@sRequestType,
				@pnFamilyNo	    =@nFamilyNo"
		
		exec sp_executesql @sSQLString,
				N'@pnBatchNo		int,
				  @sRequestorNameType	nvarchar(3),
				  @nSenderNameNo	int,
				  @sRequestType		nvarchar(50),
				  @nFamilyNo		int',
				  @pnBatchNo		=@pnBatchNo,
				  @sRequestorNameType	=@sRequestorNameType,
				  @nSenderNameNo	=@nSenderNameNo,
				  @sRequestType		=@sRequestType,
				  @nFamilyNo		=@nFamilyNo	
	End
	-----------------------------------------------------------------------------------------
	-- DETERMINE THE MATCH LEVEL
	-----------------------------------------------------------------------------------------
	-- For each transaction to be processed for this batch in the #TEMPCASEMATCH table
	-- we can now look at the candidate Cases and determine the level of match to apply.
	-- Matching is determined as follows:
	-- 1. Case ID / Case Reference
	-- 2. Property (Trademarks, Patents, Designs), Country Code, Any of the Official Numbers
	-- 3. Data Instructor (same Family is considered a match), Data Instructor Reference
	-- 4. Instructor, Instructor Reference 
	--
	-- If there is a Case ID or Case Reference you use that. 
	--
	-- If point 1 results in no match, you use Property type, country and any official  
	-- number (restrict to IP official numbers, since there are other number types in use).
	-- As long as one official number matches that's ok. You don't have to flag the case
	-- as partial match if all the official numbers don't match.
	--
	-- If point 2 results in multiple cases or no cases, then use point 3 to restrict  
	-- the list down to one case if possible, and then use point 4 to restrict the list
	-- further if necessary.
	--
	-- If after point 4 you have no cases - then this indicates it is a new case. 
	-- If after point 4 you have multiple cases, then this is unmapped.
	-- If you have one case resulting, you check for full/partial match.
	-----------------------------------------------------------------------------------------
	If @nErrorCode=0
	and @nTransactionCount>0
	Begin
		---------------------------------------------------------------------------------
		-- A best fit weighting will be used to determine the level of matching achieved.
		-- 9 flags will be concatenated together to indicate the match level. The highest
		-- value will then indicate the best fit.  The flags are :
		-- Position 1 -	Match on CaseId
		-- Position 2 -	Match on IRN
		-- Position 3 - Match on Number Type
		-- Position 4 -	Match on Official Number
		-- Position 5 -	Match on Requestor
		-- Position 6 -	Match on Requestor's reference
		-- Position 7 -	Match on Instructor
		-- Position 8 -	Match on Instructor's reference
		-- Position 9 - No Future Name found for Instructor or Requestor
		--
		--	3251	= multiple matches
		--	3252	= no match
		--	3253	= partial match
		--	3254	= full match
		---------------------------------------------------------------------------------
		Set @nExistDraftCases=0
		
		Set @sSQLString=
		"Update #TEMPCASEMATCH"+char(10)+
		"Set @nMatchLevel="+char(10)+
		"CASE WHEN(BF.BESTFIT in ('011111111','111111111'))"+char(10)+ -- On CaseId/IRN and all other characteristics
		"	THEN CASE WHEN(MC.MATCHCOUNT=1) THEN 3254"+char(10)+
		"					ELSE 3251"+char(10)+
		"	     END"+char(10)+
		"     WHEN(BF.BESTFIT in ('001111011','001111111','011111011','101111011','101111111','111111011')"+char(10)+
		"      and @sRequestType in ('Agent Input'))"+char(10)+
		"	THEN 3254"+char(10)+			 -- On IRN, Official no., Requestor & Requestor Ref Ignore other characteristics if an Agent Input batch
		"     WHEN(BF.BESTFIT>='011100000' and @sRequestType not in ('Data Input','Agent Input'))"+char(10)+
		"	THEN 3254"+char(10)+			 -- On IRN & Official no. Ignore other characteristics if not a Data Input or Agent Input batch
		"     WHEN(BF.BESTFIT>='010000000'"+char(10)+
		"      and MC.MATCHCOUNT=1)"+char(10)+		 -- On CaseId/IRN but not on all characteristics
		"	THEN 3253"+char(10)+
		"     WHEN(BF.BESTFIT ='001111111')"+char(10)+	 -- On Official No. and all other characteristics
		"	THEN CASE WHEN(MC.MATCHCOUNT=1) THEN 3254"+char(10)+
		"					ELSE 3251"+char(10)+
		"	     END"+char(10)+
		"     WHEN(BF.BESTFIT>='000100000' and @sRequestType in('Extract Cases Response'))"+char(10)+	 -- SQA16184 On Official No. for Extract Cases Response batch
		"	THEN CASE WHEN(MC.MATCHCOUNT=1)"+char(10)+
		"		THEN 3254"+char(10)+		-- full match if only 1 row found
		"		ELSE 3253"+char(10)+		-- partial match
		"	     END"+char(10)+
		"     WHEN(BF.BESTFIT>='000100000')"+char(10)+	 -- On Official No. but not on all characteristics
		"	THEN CASE WHEN(@sRequestType in ('Data Input','Agent Input') and MC.MATCHCOUNT=1)"+char(10)+
		"		THEN 3253"+char(10)+
		"		ELSE CASE WHEN(MC.MATCHCOUNT=1) THEN 3254"+char(10)+	-- full match if not Data Input or Agent Input batch
		"						ELSE 3251"+char(10)+
		"		     END"+char(10)+
		"	     END"+char(10)+
		"     WHEN(BF.BESTFIT='000011111')"+char(10)+	 -- On Requestor and Instructor Ref
		"	THEN CASE WHEN(MC.MATCHCOUNT=1) THEN 3253"+char(10)+  -- Partial match
		"					ELSE 3251"+char(10)+
		"	     END"+char(10)+
		"     WHEN(BF.BESTFIT>='000011000'"+char(10)+
		"      and MC.MATCHCOUNT=1)"+char(10)+		 -- On Requestor Ref but not on all Instructor
		"	THEN 3253"+char(10)+
		"     WHEN(BF.BESTFIT='000000111')"+char(10)+	 -- On Instructor Ref but not Requestor
		"	THEN CASE WHEN(MC.MATCHCOUNT=1) THEN 3253"+char(10)+ -- Partial match
		"					ELSE 3251"+char(10)+
		"	     END"+char(10)+
		"     WHEN(BF.BESTFIT='000000110'"+char(10)+
		"      and MC.MATCHCOUNT=1)"+char(10)+	-- On Instructor Ref but a Future Name exists
		"	THEN 3253"+char(10)+
		"     WHEN(BF.BESTFIT is null)"+char(10)+   -- No matches
		"	THEN 3252"+char(10)+
		"	ELSE 3251"+char(10)+
		"END,"+char(10)+
		"@bDraftExists= CASE WHEN(N.NAMENO=isnull(D.ALTSENDERNAMENO,'') OR (D.ALTSENDERNAMENO is null and N.NAMENO=isnull(@nSenderNameNo,'')) OR (N.FAMILYNO=isnull(@nFamilyNo,''))) THEN 1 ELSE 0 END,"+char(10)+
		"MATCHLEVEL=	@nMatchLevel,"+char(10)+
		"LIVECASEID=	CASE WHEN(@nMatchLevel in (3254, 3253)) THEN CC.CASEID END,"+char(10)+
		"DRAFTCASEID=	CASE WHEN(@bDraftExists=1) THEN CN.CASEID END,"+char(10)+
		"DRAFTALREADYEXISTS=@bDraftExists,"+char(10)+
		"@nExistDraftCases=@nExistDraftCases+@bDraftExists"+char(10)+
		"From #TEMPCASEMATCH T"+char(10)+
		"left join EDETRANSACTIONCONTENTDETAILS D on (D.BATCHNO=@pnBatchNo"+char(10)+
		"					  and D.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)"+char(10)+
		-- Find the BestFit weighting
		"left join(select TRANSACTIONIDENTIFIER, "+char(10)+
		"	  max(	cast(CASEIDMATCH	as char(1))+"+char(10)+
		"		cast(IRNMATCH		as char(1))+"+char(10)+
		"		CASE WHEN(NUMBERTYPEMATCH>0) THEN '1' ELSE '0' END+"+char(10)+
		"		CASE WHEN(OFFICIALNOMATCH>0) THEN '1' ELSE '0' END+"+char(10)+
		"		cast(REQUESTORMATCH 	as char(1))+"+char(10)+
		"		cast(REQUESTORREFMATCH 	as char(1))+"+char(10)+
		"		cast(INSTRUCTORMATCH 	as char(1))+"+char(10)+
		"		cast(INSTRUCTORREFMATCH as char(1))+"+char(10)+
		"		cast(NOFUTURENAMEFOUND  as char(1))) as BESTFIT"+char(10)+
		"	  from #TEMPCANDIDATECASES"+char(10)+
		"	  group by TRANSACTIONIDENTIFIER) BF	on (BF.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)"+char(10)+
	
		-- Now find how many candidate rows have a match weighting equivalent to the BestFit
		"left join(select TRANSACTIONIDENTIFIER,"+char(10)+
		"	 	cast(CASEIDMATCH	as char(1))+"+char(10)+
		"		cast(IRNMATCH		as char(1))+"+char(10)+
		"		CASE WHEN(NUMBERTYPEMATCH>0) THEN '1' ELSE '0' END+"+char(10)+
		"		CASE WHEN(OFFICIALNOMATCH>0) THEN '1' ELSE '0' END+"+char(10)+
		"		cast(REQUESTORMATCH 	as char(1))+"+char(10)+
		"		cast(REQUESTORREFMATCH 	as char(1))+"+char(10)+
		"		cast(INSTRUCTORMATCH 	as char(1))+"+char(10)+
		"		cast(INSTRUCTORREFMATCH as char(1))+"+char(10)+
		"		cast(NOFUTURENAMEFOUND  as char(1)) as BESTFIT,"+char(10)+
		"		Count(*) as MATCHCOUNT"+char(10)+
		"	  from #TEMPCANDIDATECASES"+char(10)+
		"	  group by"+char(10)+
		"		TRANSACTIONIDENTIFIER,"+char(10)+
		"	  	cast(CASEIDMATCH	as char(1))+"+char(10)+
		"		cast(IRNMATCH		as char(1))+"+char(10)+
		"		CASE WHEN(NUMBERTYPEMATCH>0) THEN '1' ELSE '0' END+"+char(10)+
		"		CASE WHEN(OFFICIALNOMATCH>0) THEN '1' ELSE '0' END+"+char(10)+
		"		cast(REQUESTORMATCH 	as char(1))+"+char(10)+
		"		cast(REQUESTORREFMATCH 	as char(1))+"+char(10)+
		"		cast(INSTRUCTORMATCH 	as char(1))+"+char(10)+
		"		cast(INSTRUCTORREFMATCH as char(1))+"+char(10)+
		"		cast(NOFUTURENAMEFOUND  as char(1))) MC"+char(10)+
		"				on (MC.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER"+char(10)+
		"				and MC.BESTFIT=BF.BESTFIT)"+char(10)+
	
		-- Where there is one possible match return the candidate case
		"left join #TEMPCANDIDATECASES CC on(CC.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER"+char(10)+
		"				and MC.MATCHCOUNT=1"+char(10)+
		"				and cast(CC.CASEIDMATCH	       as char(1))+ "+char(10)+
		"				    cast(CC.IRNMATCH	       as char(1))+"+char(10)+
		"				    CASE WHEN(CC.NUMBERTYPEMATCH>0) THEN '1' ELSE '0' END+"+char(10)+
		"				    CASE WHEN(CC.OFFICIALNOMATCH>0) THEN '1' ELSE '0' END+"+char(10)+
		"				    cast(CC.REQUESTORMATCH     as char(1))+"+char(10)+
		"				    cast(CC.REQUESTORREFMATCH  as char(1))+"+char(10)+
		"				    cast(CC.INSTRUCTORMATCH    as char(1))+"+char(10)+
		"				    cast(CC.INSTRUCTORREFMATCH as char(1))+"+char(10)+
		"				    cast(CC.NOFUTURENAMEFOUND  as char(1))=BF.BESTFIT )"+char(10)+
	
		-- When a live Case is found then see if there is a draft Case already in existence with 
		-- the same Requestor/Instructor but from a different batch
		"left join EDECASEMATCH CM	on (CM.LIVECASEID=CC.CASEID"+char(10)+
		"				and CM.BATCHNO<>@pnBatchNo)"+char(10)+	--SQA16847
		"left join EDETRANSACTIONBODY TB on(TB.BATCHNO=CM.BATCHNO"+char(10)+
		"				and TB.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER"+char(10)+
		"				and(TB.TRANSSTATUSCODE=3480"+char(10)+
		"				 OR(TB.TRANSSTATUSCODE=3440 and TB.BATCHNO=@pnBatchNo and TB.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)))"+char(10)+
		"left join CASENAME CN		on (CN.CASEID=CM.DRAFTCASEID"+char(10)+
		"				and CN.NAMETYPE=@sRequestorNameType"+char(10)+
		"				and TB.BATCHNO is not null)	-- Only get requestor if draft Case
		left join NAME N		on (N.NAMENO=CN.NAMENO)"
	
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@nMatchLevel		int		Output,
					  @nExistDraftCases	int		Output,
					  @bDraftExists		bit		Output,
					  @sRequestorNameType	nvarchar(3),
					  @sRequestType		nvarchar(50),
					  @nSenderNameNo	int,
					  @pnBatchNo		int,
					  @nFamilyNo		int',
					  @nMatchLevel		=@nMatchLevel		Output,
					  @nExistDraftCases	=@nExistDraftCases	Output,
					  @bDraftExists		=@bDraftExists		Output,
					  @sRequestorNameType	=@sRequestorNameType,
					  @sRequestType		=@sRequestType,
					  @nSenderNameNo	=@nSenderNameNo,
					  @pnBatchNo		=@pnBatchNo,
					  @nFamilyNo		=@nFamilyNo
	End
	-------------------------------------------------------------------------------------
	-- 2. IDENTIFY/MATCH TO DRAFT CASE for 'Data Input' batches
	-------------------------------------------------------------------------------------
	-- Load the candidate Cases for this batch that are returned from the stored procedure
	-- ede_FindCandidateCases into a temporary table
	-- This temporary table will list all of the possible Cases along with information
	-- indicating how the match occurred
	-------------------------------------------------------------------------------------

	If @sRequestType='Data Input'
	and @nTransactionCount>0
	Begin	
		If @nErrorCode=0
		Begin
			-- clear out the live Case candidates so we can now get the
			-- draft case candidates.
			Set @sSQLString="delete from #TEMPCANDIDATECASES"
			
			exec @nErrorCode=sp_executesql @sSQLString
		
		End
		
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			insert into #TEMPCANDIDATECASES(TRANSACTIONIDENTIFIER, CASEID, CASEIDMATCH, IRNMATCH, 
							REQUESTORMATCH, REQUESTORREFMATCH, INSTRUCTORMATCH, 
							INSTRUCTORREFMATCH, NUMBERTYPEMATCH,OFFICIALNOMATCH, NOFUTURENAMEFOUND)
			exec ede_FindCandidateCases
					@pnBatchNo	    =@pnBatchNo,
					@psRequestorNameType=@sRequestorNameType,
					@pnSenderNameNo	    =@nSenderNameNo,
					@pbDraftCaseSearch  =1,
					@psRequestType      =@sRequestType,
					@pnFamilyNo	    =@nFamilyNo"
			
			exec sp_executesql @sSQLString,
					N'@pnBatchNo		int,
					  @sRequestorNameType	nvarchar(3),
					  @nSenderNameNo	int,
					  @sRequestType		nvarchar(50),
					  @nFamilyNo		int',
					  @pnBatchNo		=@pnBatchNo,
					  @sRequestorNameType	=@sRequestorNameType,
					  @nSenderNameNo	=@nSenderNameNo,
					  @sRequestType		=@sRequestType,
					  @nFamilyNo		=@nFamilyNo			  
		End
		
		-------------------------------------------------------------------------------------
		-- GET EXISTING DRAFT CASEID
		-------------------------------------------------------------------------------------
		-- If a draft Case linked to an existing Live Case has not been assigned then consider
		-- the candidate draft Cases that already exist
		-------------------------------------------------------------------------------------

		If @nErrorCode=0
		Begin
			-----------------------------------------------------------------------------
			-- A best fit weighting is used to determine the level of matching achieved.
			-- 9 flags are concatenated together to indicate the match level. The highest
			-- value will then indicate the best fit.  The flags are :
			-- Position 1 -	Match on CaseId
			-- Position 2 -	Match on IRN
			-- Position 3 - Match on Number Type
			-- Position 4 -	Match on Official Number
			-- Position 5 -	Match on Requestor
			-- Position 6 -	Match on Requestor's reference
			-- Position 7 -	Match on Instructor
			-- Position 8 -	Match on Instructor's reference
			-- Position 9 - No Future Name found for Instructor or Requestor
			-----------------------------------------------------------------------------
			
			Set @sSQLString="
			Update #TEMPCASEMATCH
			Set DRAFTCASEID	      =	CASE WHEN(TB.TRANSSTATUSCODE=3480)	THEN CC.CASEID
						     WHEN(TB.TRANSSTATUSCODE=3440 and TB.BATCHNO=@pnBatchNo and TB.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
											THEN CC.CASEID
						     WHEN(TB.TRANSSTATUSCODE=3460 and TB.BATCHNO>@pnBatchNo)		
											THEN CC.CASEID	-- SQA17971
											ELSE NULL
						END,
			    DRAFTALREADYEXISTS=	1,
			    MATCHINGBATCHNO	=CASE WHEN(TB.TRANSSTATUSCODE=3460 and TB.BATCHNO>@pnBatchNo) 
											THEN M.BATCHNO ELSE NULL END, 		 -- SQA17971
			    MATCHINGTRANSACTION =CASE WHEN(TB.TRANSSTATUSCODE=3460 and TB.BATCHNO>@pnBatchNo) 
											THEN M.TRANSACTIONIDENTIFIER ELSE NULL END -- SQA17971
			From #TEMPCASEMATCH T
		
			-- Find the BestFit weighting 
			join(	select TRANSACTIONIDENTIFIER, 
				  max(	cast(CASEIDMATCH	as char(1))+
					cast(IRNMATCH		as char(1))+
					CASE WHEN(NUMBERTYPEMATCH>0) THEN '1' ELSE '0' END+
					CASE WHEN(OFFICIALNOMATCH>0) THEN '1' ELSE '0' END+
					cast(REQUESTORMATCH 	as char(1))+
					cast(REQUESTORREFMATCH 	as char(1))+
					cast(INSTRUCTORMATCH 	as char(1))+
					cast(INSTRUCTORREFMATCH as char(1))+
					cast(NOFUTURENAMEFOUND  as char(1))) as BESTFIT
				  from #TEMPCANDIDATECASES
				  group by TRANSACTIONIDENTIFIER) BF	on (BF.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
		
			-- Now find how many candidate rows that have a match weighting equivalent to the BestFit
			join(	select TRANSACTIONIDENTIFIER,
				  	cast(CASEIDMATCH	as char(1))+
					cast(IRNMATCH		as char(1))+
					CASE WHEN(NUMBERTYPEMATCH>0) THEN '1' ELSE '0' END+
					CASE WHEN(OFFICIALNOMATCH>0) THEN '1' ELSE '0' END+
					cast(REQUESTORMATCH 	as char(1))+
					cast(REQUESTORREFMATCH 	as char(1))+
					cast(INSTRUCTORMATCH 	as char(1))+
					cast(INSTRUCTORREFMATCH as char(1))+
					cast(NOFUTURENAMEFOUND  as char(1)) as BESTFIT,
					Count(*) as MATCHCOUNT
				  from #TEMPCANDIDATECASES
				  group by 
					TRANSACTIONIDENTIFIER,
				  	cast(CASEIDMATCH	as char(1))+
					cast(IRNMATCH		as char(1))+
					CASE WHEN(NUMBERTYPEMATCH>0) THEN '1' ELSE '0' END+
					CASE WHEN(OFFICIALNOMATCH>0) THEN '1' ELSE '0' END+
					cast(REQUESTORMATCH 	as char(1))+
					cast(REQUESTORREFMATCH 	as char(1))+
					cast(INSTRUCTORMATCH 	as char(1))+
					cast(INSTRUCTORREFMATCH as char(1))+
					cast(NOFUTURENAMEFOUND  as char(1))) MC
									on (MC.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and MC.BESTFIT=BF.BESTFIT)
		
			-- Where there is one possible match return the candidate draft case
			join #TEMPCANDIDATECASES CC			on (CC.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
									and MC.MATCHCOUNT=1
									and cast(CC.CASEIDMATCH	       as char(1))+ 
									    cast(CC.IRNMATCH	       as char(1))+
									    CASE WHEN(CC.NUMBERTYPEMATCH>0) THEN '1' ELSE '0' END+
									    CASE WHEN(CC.OFFICIALNOMATCH>0) THEN '1' ELSE '0' END+
									    cast(CC.REQUESTORMATCH     as char(1))+
									    cast(CC.REQUESTORREFMATCH  as char(1))+
									    cast(CC.INSTRUCTORMATCH    as char(1))+
									    cast(CC.INSTRUCTORREFMATCH as char(1))+
									    cast(CC.NOFUTURENAMEFOUND  as char(1))=BF.BESTFIT )
			-- The already existing Draft CaseId must have 
			-- a status of Processed (3480) for it to be 
			-- eligible to be overwritten unless it is the
			-- same as the current batch be reprocessed
			join EDECASEMATCH M		on (M.DRAFTCASEID=CC.CASEID)
			join EDETRANSACTIONBODY TB	on (TB.BATCHNO=M.BATCHNO
							and TB.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			Where T.DRAFTCASEID is null
			and (M.MATCHLEVEL=3252		-- Match level is New Case
			 OR  TB.TRANSSTATUSCODE=3480	-- or Transaction is processed or this is the current transaction
			 OR (TB.TRANSSTATUSCODE=3440 and TB.BATCHNO=@pnBatchNo and TB.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER))
			and BF.BESTFIT like '____11%'	-- Match on Requestor and Requestor Reference (underscores mean any character in that position)
			and MC.MATCHCOUNT=1		-- Only one candidate Draft Case"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int,
						  @nSenderNameNo	int,
						  @sRequestorNameType	nvarchar(3)',
						  @pnBatchNo=@pnBatchNo,
						  @nSenderNameNo=@nSenderNameNo,
						  @sRequestorNameType=@sRequestorNameType
			
			Set @nExistDraftCases=@nExistDraftCases+@@Rowcount
		End
		-------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------
		-- L A T E R   B A T C H   C L E A N U P
		-------------------------------------------------------------------------------------
		If @nErrorCode=0
		and @nExistDraftCases>0
		Begin
			Set @nRetry=3
			While @nRetry>0
			and @nErrorCode=0
			Begin
				BEGIN TRY
					Select @nTranCountStart = @@TranCount
					BEGIN TRANSACTION
					
					----------------------------------------------------------------
					-- Remove any draft Cases that have been matched for this Sender
					-- that were created in a later batch to the current batch.
					----------------------------------------------------------------
					If @nErrorCode=0
					Begin
						---------------------------------
						-- RFC-63684
						-- Remove the relationship in RELATEDCASE 
						-- to the Draft Case first before removing the case
						---------------------------------
						set @sSQLString="
						Delete R
						From #TEMPCASEMATCH T
						join RELATEDCASE R on (R.RELEATEDCASEID=T.DRAFTCASEID)
						where T.MATCHINGBATCHNO is not null
						and T.MATCHINGTRANSACTION is not null"
					
						exec @nErrorCode=sp_executesql @sSQLString
					End
					
					If @nErrorCode=0
					Begin  
						set @sSQLString="
						Delete C
						From #TEMPCASEMATCH T
						join CASES C on (C.CASEID=T.DRAFTCASEID)
						where T.MATCHINGBATCHNO is not null
						and T.MATCHINGTRANSACTION is not null"

						Exec @nErrorCode=sp_executesql @sSQLString
					End	
					
											
					If @nErrorCode=0
					Begin  
						----------------------------------------------------------------
						-- Remove any EDECASEMATCH rows that may exist for transactions
						-- of this batch that are at the 'Ready For Case Import' status.
						-- This will cleanup any batches that have failed previously.
						----------------------------------------------------------------
						set @sSQLString="
						Delete M
						From #TEMPCASEMATCH T
						join EDECASEMATCH M on (M.BATCHNO=T.MATCHINGBATCHNO
								    and M.TRANSACTIONIDENTIFIER=T.MATCHINGTRANSACTION)"

						Exec @nErrorCode=sp_executesql @sSQLString
					End
					
					If @nErrorCode=0
					Begin
						--------------------------
						-- Update the transaction
						-- to a status that allows
						-- it to be reloaded.
						--------------------------
						Set @sSQLString="
						Update B
						Set TRANSSTATUSCODE=3440 -- 'Ready For Case Import'
						From #TEMPCASEMATCH T
						join EDETRANSACTIONBODY B on (B.BATCHNO=T.MATCHINGBATCHNO
									  and B.TRANSACTIONIDENTIFIER=T.MATCHINGTRANSACTION)"
						
						exec @nErrorCode=sp_executesql @sSQLString
					End

					If @nErrorCode=0
					Begin
						---------------------------
						-- Reset the #TEMPCASEMATCH
						-- rows now the draft Case
						-- has been removed.
						---------------------------
						Set @sSQLString="
						Update #TEMPCASEMATCH
						Set DRAFTCASEID=NULL,
						    DRAFTALREADYEXISTS=0,
						    MATCHINGBATCHNO=NULL,
						    MATCHINGTRANSACTION=NULL
						where MATCHINGBATCHNO is not null
						and MATCHINGTRANSACTION is not null"
						
						exec @nErrorCode=sp_executesql @sSQLString
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
						
					-- Wait 5 seconds before attempting to
					-- retry the update.
					If @nRetry>0
						WAITFOR DELAY '00:00:05'
					Else
						Set @nErrorCode=ERROR_NUMBER()
						
					If XACT_STATE()<>0
						Rollback Transaction
				END CATCH
			End -- While loop
		End	-- E N D   L A T E R   B A T C H   C L E A N U P
		-------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------

		If @nErrorCode=0
		Begin
			-------------------------------------------------------------------
			-- Ensure that the same existing draft CaseId is only used by one 
			-- transaction in the batch.  Any other transaction matching on the
			-- same live Case should generate another draft Case.
			-------------------------------------------------------------------
			
			---------------------------------------------------
			-- First, keep the DRAFTCASEID against transactions
			-- that have a Full match against the Case.
			---------------------------------------------------			
			Set @sSQLString="
			Update T
			set DRAFTCASEID	= NULL,
			    DRAFTALREADYEXISTS = 0
			From #TEMPCASEMATCH T
			join (select * from #TEMPCASEMATCH) T1
					on (T1.DRAFTCASEID=T.DRAFTCASEID)
			where T.MATCHLEVEL=3253
			and T1.MATCHLEVEL=3254"
			
			exec @nErrorCode=sp_executesql @sSQLString
			
			If @nErrorCode=0
			Begin
				------------------------------------------------
				-- Now, keep the DRAFTCASEID against transaction
				-- that came first and clear out the DRAFTCASEID
				-- against the later transactions.
				------------------------------------------------
				
				Set @sSQLString="
				Update T
				set DRAFTCASEID	= NULL,
				    DRAFTALREADYEXISTS = 0
				From #TEMPCASEMATCH T
				join (select * from #TEMPCASEMATCH) T1
						on (T1.TRANSACTIONIDENTIFIER<T.TRANSACTIONIDENTIFIER
						and T1.DRAFTCASEID=T.DRAFTCASEID)"
			
				exec @nErrorCode=sp_executesql @sSQLString
			End
		End
	End
	-------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------
	-- VALIDATION - AFTER CASE MATCHING
	-------------------------------------------------------------------------------------
						  
	If  @nErrorCode=0
	and @nTransactionCount>0
	Begin
		Select @nTranCountStart = @@TranCount
		BEGIN TRANSACTION
		
		If  @nErrorCode=0
		and @nExistDraftCases>0
		Begin
			--------------------------
			-- Draft Case to raise
			-- new Case is unprocessed
			-- in an earlier batch.
			--------------------------
			Set @sSQLString="
			Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED)
			Select 	-34,
				@pnBatchNo, 
				M.TRANSACTIONIDENTIFIER, 
				getdate()
			from #TEMPCASEMATCH M
			left join EDEOUTSTANDINGISSUES I on (I.ISSUEID = -34
							 and I.BATCHNO=@pnBatchNo
							 and I.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			where M.DRAFTCASEID is null
			and M.DRAFTALREADYEXISTS=1
			and I.ISSUEID is null"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
						  
			----------------------------------------------
			-- SQA17505
			-- Delete any candidate transactions 
			-- where a draft Case was found in an earlier
			-- batch however the draft Case is still being 
			-- processed so cannot be overwritten. This
			-- will leave the transaction Ready to Import
			-- until the previous transaction for the same
			-- case is cleared.
			----------------------------------------------
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Delete #TEMPCASEMATCH
				Where DRAFTCASEID is null
				and DRAFTALREADYEXISTS=	1"
				
				exec @nErrorCode=sp_executesql @sSQLString
				
				set @nExistDraftCases=@nExistDraftCases-@@Rowcount
			End
		End
	
		If @nErrorCode=0
		Begin
			-------------------------
			-- Validate Case Category
			-------------------------
			Set @nIssueNo = -4
	
			Set @sSQLString="
			Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED, REPORTEDVALUE, EXISTINGVALUE, ISSUETEXT)
			Select @nIssueNo, C.BATCHNO, C.TRANSACTIONIDENTIFIER, getdate(), C.CASECATEGORYCODE_T,CS.CASECATEGORY,VC.CASECATEGORYDESC
			from EDECASEDETAILS C
			join #TEMPCASEMATCH M		on (M.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			left join VALIDCATEGORY CC	on (CC.CASETYPE    =C.CASETYPECODE_T
							and CC.PROPERTYTYPE=C.CASEPROPERTYTYPECODE_T
							and CC.CASECATEGORY=C.CASECATEGORYCODE_T
							and CC.COUNTRYCODE=(select min(CC1.COUNTRYCODE)
									    from VALIDCATEGORY CC1
									    where CC1.CASETYPE=CC.CASETYPE
									    and CC1.PROPERTYTYPE=CC.PROPERTYTYPE
									    and CC1.COUNTRYCODE in ('ZZZ',C.CASECOUNTRYCODE_T)))
			left join EDEOUTSTANDINGISSUES I	on (I.ISSUEID=@nIssueNo
							and I.BATCHNO=C.BATCHNO
							and I.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			left join CASES CS		on (CS.CASEID=M.LIVECASEID)
			left join VALIDCATEGORY VC	on (VC.CASETYPE    =CS.CASETYPE
							and VC.PROPERTYTYPE=CS.PROPERTYTYPE
							and VC.CASECATEGORY=CS.CASECATEGORY
							and VC.COUNTRYCODE=(select min(VC1.COUNTRYCODE)
									    from VALIDCATEGORY VC1
									    where VC1.CASETYPE=VC.CASETYPE
									    and VC1.PROPERTYTYPE=VC.PROPERTYTYPE
									    and VC1.COUNTRYCODE in ('ZZZ',CS.COUNTRYCODE)))
			where C.BATCHNO=@pnBatchNo
			and I.ISSUEID is null
			and C.CASECATEGORYCODE_T is not null
			and CC.CASECATEGORY      is null"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int,
						  @nIssueNo	int',
						  @pnBatchNo=@pnBatchNo,
						  @nIssueNo =@nIssueNo
		End
	
		If @nErrorCode=0
		Begin
			-------------------
			-- Validate SubType
			-------------------
			Set @nIssueNo = -5
	
			Set @sSQLString="
			Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED, REPORTEDVALUE, EXISTINGVALUE, ISSUETEXT)
			Select @nIssueNo, C.BATCHNO, C.TRANSACTIONIDENTIFIER, getdate(), C.CASESUBTYPECODE_T,CS.SUBTYPE,VS.SUBTYPEDESC
			from EDECASEDETAILS C
			join #TEMPCASEMATCH M		on (M.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			left join VALIDSUBTYPE S	on (S.CASETYPE    =C.CASETYPECODE_T
							and S.PROPERTYTYPE=C.CASEPROPERTYTYPECODE_T
							and S.CASECATEGORY=C.CASECATEGORYCODE_T
							and S.SUBTYPE     =C.CASESUBTYPECODE_T
							and S.COUNTRYCODE=(select min(S1.COUNTRYCODE)
									   from VALIDSUBTYPE S1
									   where S1.CASETYPE=S.CASETYPE
									   and S1.PROPERTYTYPE=S.PROPERTYTYPE
									   and S1.CASECATEGORY=S.CASECATEGORY
									   and S1.COUNTRYCODE in ('ZZZ',C.CASECOUNTRYCODE_T)))
			left join EDEOUTSTANDINGISSUES I on(I.ISSUEID=@nIssueNo
							and I.BATCHNO=C.BATCHNO
							and I.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			left join CASES CS		on (CS.CASEID=M.LIVECASEID)
			left join VALIDSUBTYPE VS	on (VS.CASETYPE    =CS.CASETYPE
							and VS.PROPERTYTYPE=CS.PROPERTYTYPE
							and VS.CASECATEGORY=CS.CASECATEGORY
							and VS.SUBTYPE     =CS.SUBTYPE
							and VS.COUNTRYCODE=(select min(VS1.COUNTRYCODE)
									   from VALIDSUBTYPE VS1
									   where VS1.CASETYPE=VS.CASETYPE
									   and VS1.PROPERTYTYPE=VS.PROPERTYTYPE
									   and VS1.CASECATEGORY=VS.CASECATEGORY
									   and VS1.COUNTRYCODE in ('ZZZ',CS.COUNTRYCODE)))
			where C.BATCHNO=@pnBatchNo
			and I.ISSUEID is null
			and C.CASESUBTYPECODE_T is not null
			and S.SUBTYPE is null"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int,
						  @nIssueNo	int',
						  @pnBatchNo=@pnBatchNo,
						  @nIssueNo =@nIssueNo
		End
	
		If @nErrorCode=0
		Begin
			-------------------
			-- Validate Basis
			-------------------
			Set @nIssueNo = -6
	
			Set @sSQLString="
			Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED, REPORTEDVALUE, EXISTINGVALUE, ISSUETEXT)
			Select @nIssueNo, C.BATCHNO, C.TRANSACTIONIDENTIFIER, getdate(), C.CASEBASISCODE_T,P.BASIS,VB.BASISDESCRIPTION
			from EDECASEDETAILS C
			join #TEMPCASEMATCH M		on (M.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			left join VALIDBASIS B		on (B.PROPERTYTYPE=C.CASEPROPERTYTYPECODE_T
							and B.BASIS       =C.CASEBASISCODE_T
							and B.COUNTRYCODE=(select min(B1.COUNTRYCODE)
									   from VALIDBASIS B1
									   where B1.PROPERTYTYPE=B.PROPERTYTYPE
									   and   B1.BASIS=B.BASIS
									   and   B1.COUNTRYCODE in ('ZZZ',C.CASECOUNTRYCODE_T)))
			left join EDEOUTSTANDINGISSUES I on (I.ISSUEID=@nIssueNo
							 and I.BATCHNO=C.BATCHNO
							 and I.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			left join CASES CS		on (CS.CASEID=M.LIVECASEID)
			left join PROPERTY P		on (P.CASEID=CS.CASEID)
			left join VALIDBASIS VB		on (VB.PROPERTYTYPE=CS.PROPERTYTYPE
							and VB.BASIS       =P.BASIS
							and VB.COUNTRYCODE=(select min(VB1.COUNTRYCODE)
									   from VALIDBASIS VB1
									   where VB1.PROPERTYTYPE=VB.PROPERTYTYPE
									   and   VB1.BASIS=VB.BASIS
									   and   VB1.COUNTRYCODE in ('ZZZ',CS.COUNTRYCODE)))
			where C.BATCHNO=@pnBatchNo
			and I.ISSUEID is null
			and C.CASEBASISCODE_T is not null
			and B.BASIS is null"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int,
						  @nIssueNo	int',
						  @pnBatchNo=@pnBatchNo,
						  @nIssueNo =@nIssueNo
		End
	
		-----------------------
		-- Stop Pay on New Case
		-----------------------
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED)
			Select 	CASE WHEN(C.STOPREASONCODE_T='A') THEN -19 ELSE -20 END,
				C.BATCHNO, 
				C.TRANSACTIONIDENTIFIER, getdate()
			from EDECASEDETAILS C
			join #TEMPCASEMATCH M		on (M.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			join SITECONTROL S		on (S.CONTROLID='CPA Date-Stop')
			join EDEEVENTDETAILS ED		on (ED.BATCHNO=C.BATCHNO
							and ED.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER
							and ED.ASSOCIATEDCASERELATIONSHIPCODE is null
							and ED.EVENTCODE_T=S.COLINTEGER)
			left join EDEOUTSTANDINGISSUES I on (I.ISSUEID in (-19,-20)
							 and I.BATCHNO=C.BATCHNO
							 and I.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			where C.BATCHNO=@pnBatchNo
			and M.MATCHLEVEL=3252  -- New Case will be created
			and I.ISSUEID is null
			and isnull(ED.EVENTDATE,ED.EVENTDUEDATE) is not null"	-- SQA17021
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End
			  
		--------------------------
		-- No Event Dates provided
		--------------------------
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED)
			Select	S.ISSUEID, C.BATCHNO, C.TRANSACTIONIDENTIFIER, getdate()
			from EDECASEDETAILS C
			join #TEMPCASEMATCH M	 	 on (M.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			join EDESTANDARDISSUE S		 on (S.ISSUEID=CASE WHEN(M.MATCHLEVEL=3252) THEN -7 ELSE -33 END) -- SQA17541 Raise issue -7 for New Cases otherwise issue -33
			left join EDEOUTSTANDINGISSUES I on (I.ISSUEID=S.ISSUEID
							 and I.BATCHNO=C.BATCHNO
							 and I.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)				 
			where C.BATCHNO=@pnBatchNo
			and I.ISSUEID is null
			and not exists
			(select 1
			 from EDEEVENTDETAILS ED
			 join EVENTS E on (E.EVENTNO=ED.EVENTCODE_T)
			 where ED.BATCHNO=C.BATCHNO
			 and   ED.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER
			 and   ED.ASSOCIATEDCASERELATIONSHIPCODE is null)"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End

		----------------------------------------
		-- Raise an issue for Renewal Response
		-- transactions within an Agent Response
		-- batch where a match against a live
		-- case has not been found
		----------------------------------------
		If @nErrorCode=0
		and @sRequestType='Agent Response'
		Begin
			Set @sSQLString="
			Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED)
			Select 	-32,
				@pnBatchNo, 
				M.TRANSACTIONIDENTIFIER, getdate()
			from #TEMPCASEMATCH M
			join EDETRANSACTIONCONTENTDETAILS T	on (T.BATCHNO=@pnBatchNo
								and T.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			left join EDEOUTSTANDINGISSUES I on (I.ISSUEID =-32
							 and I.BATCHNO=T.BATCHNO
							 and I.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			where M.LIVECASEID is null
			and I.ISSUEID is null
			and T.TRANSACTIONCODE='Renewal Response'"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo

			If @nErrorCode=0
			Begin
				---------------------------------------------
				-- SQA16481
				-- Reset the match level to 'unmapped' for 
				-- Agent Response batches with transaction
				-- code of 'Renewal Response'. 
				-- If the transaction goes to Operator Review
				-- then there will be a draft Case for the 
				-- operator to match against a live Case.
				---------------------------------------------
				Set @sSQLString="
				Update #TEMPCASEMATCH
				Set MATCHLEVEL=3251
				from #TEMPCASEMATCH M
				join EDETRANSACTIONCONTENTDETAILS T	on (T.BATCHNO=@pnBatchNo
									and T.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
				where M.LIVECASEID is null
				and T.TRANSACTIONCODE='Renewal Response'"
			
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int',
							  @pnBatchNo=@pnBatchNo
			End
		End

		-------------------------------------------------
		-- For each transaction that about to be rejected
		-- insert a TRANSACTIONINFO row.
		-------------------------------------------------
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Insert into TRANSACTIONINFO(TRANSACTIONDATE, BATCHNO,TRANSACTIONIDENTIFIER, TRANSACTIONMESSAGENO, TRANSACTIONREASONNO) 
			select distinct getdate(),B.BATCHNO,B.TRANSACTIONIDENTIFIER,4,@nReasonNo
			from #TEMPCASEMATCH M
			join EDETRANSACTIONBODY B   on (B.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join EDEOUTSTANDINGISSUES I on (I.BATCHNO=B.BATCHNO
						    and I.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join EDESTANDARDISSUE S	    on (S.ISSUEID=I.ISSUEID)
			where B.BATCHNO=@pnBatchNo
			and B.TRANSSTATUSCODE=3440
			and S.SEVERITYLEVEL=4010" -- Reject Severity
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int,
						  @nReasonNo	int',
						  @pnBatchNo=@pnBatchNo,
						  @nReasonNo=@nReasonNo
		End

		If @nErrorCode=0
		Begin
			----------------------------------------------
			-- Check that Cases that have a 
			-- Match Level as new(3252) or unmapped(3251),
			-- do not have a RECEIVERCASEREFERENCE
			-- that already exists as an IRN.
			-- This can occur when other key details 
			-- do not match (e.g. Country).
			----------------------------------------------
			Set @nIssueNo = -44
	
			Set @sSQLString="
			Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED, REPORTEDVALUE)
			Select DISTINCT @nIssueNo, C.BATCHNO, C.TRANSACTIONIDENTIFIER, getdate(), C.RECEIVERCASEREFERENCE
			from EDECASEDETAILS C
			join #TEMPCASEMATCH M		on (M.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER
							and M.MATCHLEVEL           in (3251,3252))		-- Indicates no match, so a new case will be created.
			join CASES CS			on (CS.IRN		   =C.RECEIVERCASEREFERENCE)	-- The RECEIVERCASEREFERENCE has already been used.
			left join EDEOUTSTANDINGISSUES I on(I.ISSUEID=@nIssueNo
							and I.BATCHNO=C.BATCHNO
							and I.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			where C.BATCHNO=@pnBatchNo
			and I.ISSUEID is null"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int,
						  @nIssueNo	int',
						  @pnBatchNo=@pnBatchNo,
						  @nIssueNo =@nIssueNo
		End
	
		If @nErrorCode=0
		Begin
			------------------------------------
			-- Mark the rejected transactions as
			-- Processed if an issue has been
			-- raised with a reject severity
			------------------------------------
			Set @sSQLString="
			Update EDETRANSACTIONBODY
			Set TRANSSTATUSCODE=3480,
			    TRANSACTIONRETURNCODE='Case rejected',
			    TRANSNARRATIVECODE=CASE WHEN(T.TRANSNARRATIVECODE is not null) THEN T.TRANSNARRATIVECODE
						    WHEN(SI.DEFAULTNARRATIVE<>'')          THEN SI.DEFAULTNARRATIVE
						END
			From EDETRANSACTIONBODY T
			join #TEMPCASEMATCH M on (M.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			join (	select	O.BATCHNO, 
					O.TRANSACTIONIDENTIFIER, 
					min(isnull(S.DEFAULTNARRATIVE,'')) as DEFAULTNARRATIVE
				from EDEOUTSTANDINGISSUES O
				join EDESTANDARDISSUE S	on (S.ISSUEID=O.ISSUEID)
				where S.SEVERITYLEVEL=4010
				group by O.BATCHNO, O.TRANSACTIONIDENTIFIER) SI
					on (SI.BATCHNO=T.BATCHNO
					and SI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			Where T.BATCHNO=@pnBatchNo
			and T.TRANSSTATUSCODE=3440"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End

		If @nErrorCode=0
		Begin
			--------------------------------
			-- Delete the #TEMPCASEMATCH
			-- transactions that have failed
			-- the validation stage.
			--------------------------------
			Set @sSQLString="
			Delete #TEMPCASEMATCH
			from #TEMPCASEMATCH M
			join EDETRANSACTIONBODY B on (B.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			where B.BATCHNO=@pnBatchNo
			and B.TRANSSTATUSCODE=3480"
	
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
	End
	-------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------
	-- 3. CREATE/UPDATE DRAFT CASES
	-------------------------------------------------------------------------------------
	If  @nErrorCode=0
	and @nTransactionCount>0
	Begin

		-- Now start a new transaction
		-- NOTE : We want to keep the execution of this transaction as short as practical
		--	  to avoid leaving extensive locks on the LASTINTERNALCODE table which is
		--	  a widely used table
		Select @nTranCountStart = @@TranCount
		BEGIN TRANSACTION
	
		-- For each imported row where there is no matching Case then load a temporary Case row 
		-- in order to allocate an internal number which will be used in the CASEID generation
	
		Set @sSQLString="
		insert into #TEMPCASES(TRANSACTIONIDENTIFIER)
		SELECT 	TRANSACTIONIDENTIFIER
		FROM #TEMPCASEMATCH T
		WHERE T.DRAFTCASEID is null
		and T.MATCHLEVEL in (3251,3252)"
	
		Exec @nErrorCode=sp_executesql @sSQLString
	
		Set @nNewCases=@@Rowcount
		
		If @nErrorCode=0
		Begin
			-- Now load a row for each Draft Case to be created where at least 1 live
			-- Case does already exist.  These Draft Cases will eventually be removed
			Set @sSQLString="
			insert into #TEMPCASES(TRANSACTIONIDENTIFIER)
			SELECT 	TRANSACTIONIDENTIFIER
			FROM #TEMPCASEMATCH T
			WHERE T.DRAFTCASEID is null
			and T.MATCHLEVEL not in (3251,3252)"
		
			Exec @nErrorCode=sp_executesql @sSQLString
		
			Set @nMatchedCases=@@Rowcount
		End
		
		-- Allocate a transaction id that can be accessed by the audit logs
		-- for inclusion.
	
		Set @sSQLString="Insert into TRANSACTIONINFO(TRANSACTIONDATE, BATCHNO,TRANSACTIONMESSAGENO, TRANSACTIONREASONNO) 
				 values(getdate(),@pnBatchNo,1,@nReasonNo)
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
	
		-- Now reserve a CASEID for each of the about to be created Cases by incrementing 
		-- the LASTINTERNALCODE table
		-- A different range is kept for those Draft Cases that do not have any matching Live Case as
		-- these draft Cases will be converted to Live Cases and the CASEID kept.  Draft Cases that 
		-- do have a matching Live Case will only be short lived and will eventually be deleted.

		If @nNewCases>0
		and @nErrorCode=0
		Begin
			set @sSQLString="
				UPDATE LASTINTERNALCODE 
				SET INTERNALSEQUENCE = INTERNALSEQUENCE + @nNewCases,
				    @nLiveCaseId     = INTERNALSEQUENCE + @nNewCases
				WHERE  TABLENAME = 'CASES'"

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nLiveCaseId	int		OUTPUT,
							  @nNewCases	int',
							  @nLiveCaseId=@nLiveCaseId	OUTPUT,
							  @nNewCases=@nNewCases
		End

		If @nMatchedCases>0
		and @nErrorCode=0
		Begin
			set @sSQLString="
				UPDATE LASTINTERNALCODE 
				SET INTERNALSEQUENCE = INTERNALSEQUENCE + @nMatchedCases,
				    @nDraftCaseId    = INTERNALSEQUENCE + @nMatchedCases
				WHERE  TABLENAME = 'DRAFT CASES'"

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nDraftCaseId		int	OUTPUT,
							  @nMatchedCases	int',
							  @nDraftCaseId =@nDraftCaseId	OUTPUT,
							  @nMatchedCases=@nMatchedCases
		End
		
		-- Commit or Rollback the transaction
		
		If @@TranCount > @nTranCountStart
		Begin
			If @nErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End

		-- Now start a new transaction to create the draft Cases
		Select @nTranCountStart = @@TranCount
		BEGIN TRANSACTION
		
		If @nErrorCode=0
		Begin
			----------------------------------------------------
			-- For each Draft Case about to be created, check if
			-- the FAMILY is available in the CASEFAMILY table, 
			-- and if not, it needs to be created.
			----------------------------------------------------
			Set @sSQLString="
			Insert into CASEFAMILY(FAMILY, FAMILYTITLE)
			select distinct C.FAMILY, C.FAMILY
			from #TEMPCASES T
			join EDECASEDETAILS C	on (C.BATCHNO=@pnBatchNo
						and C.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			left join CASEFAMILY F	on (F.FAMILY=C.FAMILY)
			Where C.FAMILY is not null
			and   F.FAMILY is     null"
			
			Exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int',
							  @pnBatchNo=@pnBatchNo
		End
		
		-- Now insert a row into the CASES table for each new Case
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			-----------------------------------------------
			-- CTE included to establish if international
			--     classes are used for a country
			-----------------------------------------------
			With ValidClass (COUNTRYCODE, PROPERTYTYPE, INTCLASSFLAG)
			as (Select distinct CT.COUNTRYCODE, P.PROPERTYTYPE, CASE WHEN(TM.COUNTRYCODE='ZZZ') THEN cast(1 as bit) ELSE cast(0 as bit) END
			    from COUNTRY CT
			    cross join PROPERTYTYPE P
			    join TMCLASS TM on (TM.PROPERTYTYPE=P.PROPERTYTYPE)
			    where TM.COUNTRYCODE =(SELECT MIN(TM1.COUNTRYCODE)
						   from TMCLASS TM1 
						   where TM1.PROPERTYTYPE=P.PROPERTYTYPE
						   and TM1.COUNTRYCODE in (CT.COUNTRYCODE, 'ZZZ'))
			    )
			Insert into CASES(CASEID, IRN, STEM, CASETYPE, COUNTRYCODE, PROPERTYTYPE, CASECATEGORY, SUBTYPE, ENTITYSIZE,
					  NOINSERIES, EXTENDEDRENEWALS, STOPPAYREASON, TITLE, LOCALCLASSES, INTCLASSES, TYPEOFMARK, STATUSCODE,
					  OFFICEID, FAMILY)
			select  CASE WHEN(M.MATCHLEVEL in (3251,3252)) -- No match found
					THEN @nLiveCaseId -T.SEQUENCENO			-- live CaseId range
					ELSE @nDraftCaseId-(T.SEQUENCENO-@nNewCases)	-- draft CaseId range
				END,
				CASE WHEN(M.MATCHLEVEL in (3251,3252))
					THEN isnull(C.RECEIVERCASEREFERENCE, '<Generate Reference>')	-- RFC37928 Cater for user provided IRN
					ELSE '<Generate Reference>'
				END,
				CASE WHEN(M.MATCHLEVEL in (3251,3252))
					THEN C.CASEREFERENCESTEM					-- RFC38555 Cater for user provided STEM
					ELSE NULL
				END,
				CT.CASETYPE, 
				CY.COUNTRYCODE, 
				P.PROPERTYTYPE,
				CC.CASECATEGORY,
				S.SUBTYPE,
				TC.TABLECODE,
				C.NUMBERDESIGNS,
				C.EXTENDEDNUMBERYEARS,
				CASE WHEN(C.STOPREASONCODE_T='') THEN NULL ELSE C.STOPREASONCODE_T END,
				CASE WHEN(datalength(D.DESCRIPTIONTEXT)<=508) THEN D.DESCRIPTIONTEXT END,
				-----------------------------------------------------
				-- If Country uses the international class system and
				-- no local classes supplied then use the supplied
				-- international classes
				-----------------------------------------------------
				CASE WHEN(INTCLASSFLAG=1)
					THEN coalesce(dbo.fn_GetConcatenatedEDEClasses(C.BATCHNO,C.TRANSACTIONIDENTIFIER,'Domestic',','),dbo.fn_GetConcatenatedEDEClasses(C.BATCHNO,C.TRANSACTIONIDENTIFIER,'Nice',','))
					ELSE          dbo.fn_GetConcatenatedEDEClasses(C.BATCHNO,C.TRANSACTIONIDENTIFIER,'Domestic',',')
				END,
				-----------------------------------------------------
				-- If Country uses the international class system and
				-- no international classes supplied then use the 
				-- supplied local classes
				-----------------------------------------------------
				CASE WHEN(INTCLASSFLAG=1)
					THEN coalesce(dbo.fn_GetConcatenatedEDEClasses(C.BATCHNO,C.TRANSACTIONIDENTIFIER,'Nice',','), dbo.fn_GetConcatenatedEDEClasses(C.BATCHNO,C.TRANSACTIONIDENTIFIER,'Domestic',','))
					ELSE          dbo.fn_GetConcatenatedEDEClasses(C.BATCHNO,C.TRANSACTIONIDENTIFIER,'Nice',',')
				END,
				TM.TABLECODE,
				ST.STATUSCODE,
				O.OFFICEID,
				F.FAMILY
			from EDECASEDETAILS C
			join #TEMPCASES T	  on (T.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			join #TEMPCASEMATCH M	  on (M.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			join CASETYPE CT	  on (CT.ACTUALCASETYPE=C.CASETYPECODE_T)
			join COUNTRY CY		  on (CY.COUNTRYCODE=C.CASECOUNTRYCODE_T)
			join PROPERTYTYPE P	  on (P.PROPERTYTYPE=C.CASEPROPERTYTYPECODE_T)
			left join ValidClass VC   on (VC.COUNTRYCODE =CY.COUNTRYCODE
			                          and VC.PROPERTYTYPE=P.PROPERTYTYPE)
			left join CASECATEGORY CC on (CC.CASETYPE=CT.CASETYPE
						  and CC.CASECATEGORY=C.CASECATEGORYCODE_T)
			left join SUBTYPE S	  on (S.SUBTYPE=C.CASESUBTYPECODE_T)
			left join TABLECODES TC	  on (TC.TABLECODE=C.ENTITYSIZE_T)
			left join TABLECODES TM	  on (TM.TABLECODE=C.TYPEOFMARK_T)
			left join EDEDESCRIPTIONDETAILS	D on (D.BATCHNO=C.BATCHNO
							  and D.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER
							  and D.DESCRIPTIONCODE='Short Title')
			left join STATUS ST	  on (ST.STATUSCODE=@nStatus)
			left join OFFICE O	  on (O.DESCRIPTION=C.CASEOFFICE)
			left join CASEFAMILY F	  on (F.FAMILY=C.FAMILY)
			where C.BATCHNO=@pnBatchNo"

			Exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @nLiveCaseId		int,
							  @nDraftCaseId		int,
							  @nNewCases		int,
							  @nStatus		int',
							  @pnBatchNo	=@pnBatchNo,
							  @nLiveCaseId	=@nLiveCaseId,
							  @nDraftCaseId	=@nDraftCaseId,
							  @nNewCases	=@nNewCases,
							  @nStatus	=@nStatus
			
			-- Save the number of Cases created
			Set @pnRowCount=@@Rowcount
		End

		-- Now insert a row into the PROPERTY table for each new Case where CASETYPE='A' (or the draft equivalent)
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Insert into PROPERTY(CASEID, BASIS, NOOFCLAIMS)
			select  CS.CASEID,
				AB.BASIS, 
				C.NUMBERCLAIMS
			from EDECASEDETAILS C
			join #TEMPCASES T		on (T.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			join #TEMPCASEMATCH M		on (M.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			join CASES CS			on (CS.CASEID=	CASE WHEN(M.MATCHLEVEL in (3251,3252)) -- No match found
										THEN @nLiveCaseId -T.SEQUENCENO			-- live  CaseId range
										ELSE @nDraftCaseId-(T.SEQUENCENO-@nNewCases)	-- draft CaseId range
									END)
			left join CASETYPE CT		on (CT.ACTUALCASETYPE=C.CASETYPECODE_T)
			left join APPLICATIONBASIS AB	on (AB.BASIS=C.CASEBASISCODE_T)
			where C.BATCHNO=@pnBatchNo
			and (C.CASETYPECODE_T = 'A' OR AB.BASIS is not null OR C.NUMBERCLAIMS is not null)"

			Exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @nLiveCaseId		int,
							  @nDraftCaseId		int,
							  @nNewCases		int',
							  @pnBatchNo	=@pnBatchNo,
							  @nLiveCaseId	=@nLiveCaseId,
							  @nDraftCaseId	=@nDraftCaseId,
							  @nNewCases	=@nNewCases
		End
	
		-- Load the EDECASEMATCH details
		If @nErrorCode=0
		Begin
			set @sSQLString="
			Insert into EDECASEMATCH(DRAFTCASEID, BATCHNO, TRANSACTIONIDENTIFIER, LIVECASEID, MATCHLEVEL, SEQUENCENO)
			Select  CS.CASEID, 
				@pnBatchNo,
				C.TRANSACTIONIDENTIFIER,
				C.LIVECASEID,
				C.MATCHLEVEL,
				CASE WHEN(C.LIVECASEID is not null) THEN isnull(CC.SEQUENCENO,0)+1 END
			From #TEMPCASEMATCH C
			left join #TEMPCASES T	 on (T.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			join CASES CS		 on (CS.CASEID=CASE WHEN(C.DRAFTCASEID is not null)
								     THEN C.DRAFTCASEID
								     ELSE
									CASE WHEN(C.MATCHLEVEL in (3251,3252))				-- No match found
										THEN @nLiveCaseId -T.SEQUENCENO			-- live  CaseId range
										ELSE @nDraftCaseId-(T.SEQUENCENO-@nNewCases)	-- draft CaseId range
									END
								END)
			left join EDECASEMATCH M on (M.BATCHNO=@pnBatchNo
						 and M.DRAFTCASEID=CS.CASEID)
			-- need to increment the SEQUENCENO each time a Draft Case is matched to a Live Case
			left join (	select LIVECASEID, max(isnull(SEQUENCENO,0)) as SEQUENCENO
					from EDECASEMATCH
					group by LIVECASEID) CC	on (CC.LIVECASEID=C.LIVECASEID)
			where M.BATCHNO is null"
		
			Exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @nLiveCaseId		int,
							  @nDraftCaseId		int,
							  @nNewCases		int',
							  @pnBatchNo	=@pnBatchNo,
							  @nLiveCaseId	=@nLiveCaseId,
							  @nDraftCaseId	=@nDraftCaseId,
							  @nNewCases	=@nNewCases
		End
	
		-- If any transactions are pointing to the same live Case then
		-- the sequence number of each transaction will need to be 
		-- incremented
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Update EDECASEMATCH
			set SEQUENCENO=SEQUENCENO+(select count(*)
						   from EDECASEMATCH M1
						   where M1.BATCHNO=M.BATCHNO
						   and M1.LIVECASEID=M.LIVECASEID
						   and M1.MATCHLEVEL in (3254,3253)
						   and M1.TRANSACTIONIDENTIFIER<M.TRANSACTIONIDENTIFIER)
			from EDECASEMATCH M
			where M.BATCHNO=@pnBatchNo
			and M.LIVECASEID is not null
			and M.MATCHLEVEL in (3254,3253)"
	
			Exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int',
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
	End
	-------------------------------------------------
	-- If the #TEMPCASEMATCH table was not initially
	-- loaded because EDECASEMATCH transactions 
	-- already existed as a result of the transaction
	-- failing after the creation of the Draft Case
	-- then load #TEMPCASEMATCH at this point
	-------------------------------------------------
	If  @nErrorCode=0
	and @nTransactionCount=0
	Begin
		-- Start a new transaction
		Set @nTranCountStart = @@TranCount
		BEGIN TRANSACTION
	
		------------------------------------------------------------------------------
		-- Only transactions in the given batch which are valid to this point 
		-- (ie. where transaction status = ‘Ready For Case Import’) will be processed.
		------------------------------------------------------------------------------ 
		set @sSQLString="
		Insert into #TEMPCASEMATCH(TRANSACTIONIDENTIFIER, MATCHLEVEL, DRAFTCASEID, LIVECASEID)
		Select B.TRANSACTIONIDENTIFIER, M.MATCHLEVEL, M.DRAFTCASEID, M.LIVECASEID
		From EDETRANSACTIONBODY B
		join EDECASEMATCH M on (M.BATCHNO=B.BATCHNO
				    and M.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER)
		where B.BATCHNO=@pnBatchNo
		and   B.TRANSSTATUSCODE=3440	--'Ready For Case Import'"
	
		Exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo	int',
					  @pnBatchNo=@pnBatchNo
	
		-- Commit transaction if successful
		If @@TranCount > @nTranCountStart
		Begin
			If @nErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
	End

				
	--------------------------------------------------------------------
	-- Remove details of pre-existing Draft Cases that are in this batch
	--------------------------------------------------------------------
	If  @nErrorCode=0
	and @nExistDraftCases>0
	Begin
		-- Now start a new transaction
		Select @nTranCountStart = @@TranCount
		BEGIN TRANSACTION
	
		-------------------------------------------------------------
		-- Where a draft Case already exists and is to be updated,
		-- the newly imported data is to completely replace the
		-- existing draft Case.  The most efficient way to achieve
		-- this is to delete all of the child table rows of the CASES
		-- table and then reinsert the new details.  The CASES row 
		-- cannot be deleted as we need to retain the reference to
		-- its CASEID.
		-- NOTE: DRAFTCASEID on #TEMPCASEMATCH indicates the draft
		--       case already existed
		-------------------------------------------------------------
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Delete ACTIVITYREQUEST
			from ACTIVITYREQUEST D
			join #TEMPCASEMATCH T on (T.DRAFTCASEID=D.CASEID)"
		
			exec @nErrorCode=sp_executesql @sSQLString
		End
	
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Delete CASEBUDGET
			from CASEBUDGET D
			join #TEMPCASEMATCH T on (T.DRAFTCASEID=D.CASEID)"
		
			exec @nErrorCode=sp_executesql @sSQLString
		End
	
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Delete CASECHECKLIST
			from CASECHECKLIST D
			join #TEMPCASEMATCH T on (T.DRAFTCASEID=D.CASEID)"
		
			exec @nErrorCode=sp_executesql @sSQLString
		End
	
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Delete CASEEVENT
			from CASEEVENT D
			join #TEMPCASEMATCH T on (T.DRAFTCASEID=D.CASEID)"
		
			exec @nErrorCode=sp_executesql @sSQLString
		End
	
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Delete CASEIMAGE
			from CASEIMAGE D
			join #TEMPCASEMATCH T on (T.DRAFTCASEID=D.CASEID)"
		
			exec @nErrorCode=sp_executesql @sSQLString
		End
	
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Delete CASELOCATION
			from CASELOCATION D
			join #TEMPCASEMATCH T on (T.DRAFTCASEID=D.CASEID)"
		
			exec @nErrorCode=sp_executesql @sSQLString
		End
	
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Delete CASENAME
			from CASENAME D
			join #TEMPCASEMATCH T on (T.DRAFTCASEID=D.CASEID)"
		
			exec @nErrorCode=sp_executesql @sSQLString
		End
	
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Delete CASETEXT
			from CASETEXT D
			join #TEMPCASEMATCH T on (T.DRAFTCASEID=D.CASEID)"
		
			exec @nErrorCode=sp_executesql @sSQLString
		End
	
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Delete CASEWORDS
			from CASEWORDS D
			join #TEMPCASEMATCH T on (T.DRAFTCASEID=D.CASEID)"
		
			exec @nErrorCode=sp_executesql @sSQLString
		End
	
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Delete CLASSFIRSTUSE
			from CLASSFIRSTUSE D
			join #TEMPCASEMATCH T on (T.DRAFTCASEID=D.CASEID)"
		
			exec @nErrorCode=sp_executesql @sSQLString
		End
	
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Delete DESIGNELEMENT
			from DESIGNELEMENT D
			join #TEMPCASEMATCH T on (T.DRAFTCASEID=D.CASEID)"
		
			exec @nErrorCode=sp_executesql @sSQLString
		End
	
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Delete JOURNAL
			from JOURNAL D
			join #TEMPCASEMATCH T on (T.DRAFTCASEID=D.CASEID)"
		
			exec @nErrorCode=sp_executesql @sSQLString
		End
	
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Delete OFFICIALNUMBERS
			from OFFICIALNUMBERS D
			join #TEMPCASEMATCH T on (T.DRAFTCASEID=D.CASEID)"
		
			exec @nErrorCode=sp_executesql @sSQLString
		End
	
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Delete OPENACTION
			from OPENACTION D
			join #TEMPCASEMATCH T on (T.DRAFTCASEID=D.CASEID)"
		
			exec @nErrorCode=sp_executesql @sSQLString
		End
	
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Delete PROPERTY
			from PROPERTY D
			join #TEMPCASEMATCH T on (T.DRAFTCASEID=D.CASEID)"
		
			exec @nErrorCode=sp_executesql @sSQLString
		End
	
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Delete RELATEDCASE
			from RELATEDCASE D
			join #TEMPCASEMATCH T on (T.DRAFTCASEID=D.CASEID)"
		
			exec @nErrorCode=sp_executesql @sSQLString
		End
	
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Delete RELATEDCASE
			from RELATEDCASE D
			join #TEMPCASEMATCH T on (T.DRAFTCASEID=D.RELATEDCASEID)"
		
			exec @nErrorCode=sp_executesql @sSQLString
		End
	
		--------------------------------------------------------
		-- Delete the outstanding issues against the draft Case.
		--------------------------------------------------------
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Delete EDEOUTSTANDINGISSUES
			from EDEOUTSTANDINGISSUES D
			join #TEMPCASEMATCH T on (T.DRAFTCASEID=D.CASEID)"
		
			exec @nErrorCode=sp_executesql @sSQLString
		End
	
		--------------------------------------------------------------------
		-- Where the draft Case already exists we need to update each column
		--------------------------------------------------------------------
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Update	CASES
			Set	CASETYPE	=CT.CASETYPE,
				COUNTRYCODE	=CY.COUNTRYCODE,
				PROPERTYTYPE	=P.PROPERTYTYPE,
				CASECATEGORY	=CC.CASECATEGORY,
				SUBTYPE		=S.SUBTYPE,
				ENTITYSIZE	=TC.TABLECODE,
				NOINSERIES	=C.NUMBERDESIGNS,
				EXTENDEDRENEWALS=C.EXTENDEDNUMBERYEARS,
				STOPPAYREASON	=CASE WHEN(C.STOPREASONCODE_T='') THEN NULL ELSE C.STOPREASONCODE_T END,
				TITLE		=CASE WHEN(datalength(D.DESCRIPTIONTEXT)<=508) THEN D.DESCRIPTIONTEXT END,
				LOCALCLASSES	=dbo.fn_GetConcatenatedEDEClasses(C.BATCHNO,C.TRANSACTIONIDENTIFIER,'Domestic',','),
				INTCLASSES	=dbo.fn_GetConcatenatedEDEClasses(C.BATCHNO,C.TRANSACTIONIDENTIFIER,'Nice',','),
				TYPEOFMARK	=TM.TABLECODE
			From CASES CS
			join #TEMPCASEMATCH T	  on (T.DRAFTCASEID=CS.CASEID)				
			join EDECASEDETAILS C 	  on (C.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			join CASETYPE CT	  on (CT.ACTUALCASETYPE=C.CASETYPECODE_T)
			join COUNTRY CY		  on (CY.COUNTRYCODE=C.CASECOUNTRYCODE_T)
			join PROPERTYTYPE P	  on (P.PROPERTYTYPE=C.CASEPROPERTYTYPECODE_T)
			left join CASECATEGORY CC on (CC.CASETYPE=CT.CASETYPE
						  and CC.CASECATEGORY=C.CASECATEGORYCODE_T)
			left join SUBTYPE S	  on (S.SUBTYPE=C.CASESUBTYPECODE_T)
			left join TABLECODES TC	  on (TC.TABLECODE=C.ENTITYSIZE_T)
			left join TABLECODES TM	  on (TM.TABLECODE=C.TYPEOFMARK_T)
			left join EDEDESCRIPTIONDETAILS	D on (D.BATCHNO=C.BATCHNO
							  and D.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER
							  and D.DESCRIPTIONCODE='Short Title')
			where C.BATCHNO=@pnBatchNo"
		
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int',
							  @pnBatchNo=@pnBatchNo
		End
	
		--------------------------------------------------------------------
		-- Where the draft Case already exists we need to update each column
		--------------------------------------------------------------------
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Update PROPERTY
			Set	BASIS		=A.BASIS,
				NOOFCLAIMS	=C.NUMBERCLAIMS
			From PROPERTY P
			join #TEMPCASEMATCH T on (T.DRAFTCASEID=P.CASEID)				
			join EDECASEDETAILS C on (C.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			left join APPLICATIONBASIS A on (A.BASIS=C.CASEBASISCODE_T)
			where C.BATCHNO=@pnBatchNo"
	
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
	End
	
	------------------------------
	-- Additional CASE detail Load
	------------------------------
	If @nErrorCode=0
	Begin
		-- Start a new transaction
		Select @nTranCountStart = @@TranCount
		BEGIN TRANSACTION
	
		------------------------
		-- Load CASETEXT details
		------------------------
		
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			insert into CASETEXT(CASEID, TEXTTYPE, TEXTNO, LONGFLAG, SHORTTEXT, TEXT)
			select 	M.DRAFTCASEID,
				TT.TEXTTYPE,
				isnull(D.SEQUENCENUMBER,0),
				CASE WHEN(datalength(D.DESCRIPTIONTEXT)>508) THEN 1    ELSE 0 END,
				CASE WHEN(datalength(D.DESCRIPTIONTEXT)>508) THEN NULL ELSE D.DESCRIPTIONTEXT END,
				CASE WHEN(datalength(D.DESCRIPTIONTEXT)<509) THEN NULL ELSE D.DESCRIPTIONTEXT END
			from EDECASEMATCH M
			join #TEMPCASEMATCH TM	     on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join EDEDESCRIPTIONDETAILS D on (D.BATCHNO=M.BATCHNO
						     and D.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join TEXTTYPE TT	     on (TT.TEXTTYPE=D.DESCRIPTIONCODE_T)
			left join CASETEXT CT	     on (CT.CASEID=M.DRAFTCASEID
						     and CT.TEXTTYPE=TT.TEXTTYPE
						     and CT.TEXTNO  =isnull(D.SEQUENCENUMBER,0))
			where M.BATCHNO=@pnBatchNo
			and M.DRAFTCASEID is not null
			and CT.CASEID is null
			and D.DESCRIPTIONCODE<>'Short Title'
			and TT.TEXTTYPE<>'G'				-- Goods/Services are handled separately
			and datalength(isnull(D.DESCRIPTIONTEXT,''))>0"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End
	
		-------------------------------
		-- Load OFFICIALNUMBERS details
		-------------------------------
	
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			insert into OFFICIALNUMBERS(CASEID, OFFICIALNUMBER, NUMBERTYPE, ISCURRENT)
			select 	M.DRAFTCASEID,
				left(D.IDENTIFIERNUMBERTEXT,36),
				NT.NUMBERTYPE,
				1
			from EDECASEMATCH M
			join #TEMPCASEMATCH TM		  on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)

			-- Filter duplicate official number from Raw data
			join (select distinct BATCHNO, TRANSACTIONIDENTIFIER, IDENTIFIERNUMBERCODE, 
				  IDENTIFIERNUMBERCODE_T, IDENTIFIERNUMBERTEXT
			      from EDEIDENTIFIERNUMBERDETAILS
				  where BATCHNO=@pnBatchNo
				  and ASSOCIATEDCASERELATIONSHIPCODE is null 
				  and IDENTIFIERNUMBERTEXT   is not null) D 
							on (D.BATCHNO=M.BATCHNO
							and D.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join NUMBERTYPES NT		  on (NT.NUMBERTYPE=D.IDENTIFIERNUMBERCODE_T)
			left join OFFICIALNUMBERS O	  on (O.CASEID=M.DRAFTCASEID
							  and O.OFFICIALNUMBER=left(D.IDENTIFIERNUMBERTEXT,36)
							  and O.NUMBERTYPE=NT.NUMBERTYPE)
			where M.BATCHNO=@pnBatchNo
			and M.DRAFTCASEID is not null
			and O.CASEID is null
			"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End	
		----------------
		-- Load CASENAME
		----------------
	
		If @nErrorCode=0
		Begin
			Set @sSQLString="
				Insert into CASENAME(CASEID, NAMETYPE, NAMENO, SEQUENCE, REFERENCENO, ADDRESSCODE,
							CORRESPONDNAME, DERIVEDCORRNAME, BILLPERCENTAGE)
				Select	M.DRAFTCASEID,
					NT.NAMETYPE,
					N.NAMENO,
					isnull(CN.NAMESEQUENCENUMBER,0),
					CN.NAMEREFERENCE,
					CASE WHEN(NT.KEEPSTREETFLAG=1)
						THEN N.STREETADDRESS
					END,
					CASE WHEN(convert(bit,NT.COLUMNFLAGS&1)=1 or NT.NAMETYPE in ('I','A'))
						THEN CASE WHEN(isnull(S.COLBOOLEAN,1)=0 and AN.NAMENO is not null)
								THEN AN.NAMENO
							  WHEN(S1.COLBOOLEAN=1)
								THEN N.MAINCONTACT
							  WHEN(NT.NAMETYPE in ('D','Z')) THEN (
								select	isnull( AN1.CONTACT, N1.MAINCONTACT )
								from NAME N1
								left join ASSOCIATEDNAME AN1 on ( AN1.NAMENO = N1.NAMENO
										and AN1.RELATIONSHIP = 'BIL'
										and AN1.CEASEDDATE is null
										and AN1.NAMENO = AN1.RELATEDNAME )
								where N1.NAMENO = N.NAMENO )							
							  ELSE(	select convert(int,substring(
									min(CASE WHEN(AN.PROPERTYTYPE is not null) THEN '0' ELSE '1' END+
									    CASE WHEN(AN.COUNTRYCODE is not null) THEN '0' ELSE '1' END+
									    CASE WHEN(AN.RELATEDNAME=N1.MAINCONTACT) THEN '0' ELSE '1' END+
									    replicate('0',6-datalength(convert(varchar(6),AN.SEQUENCE)))+
									    convert(varchar(6),AN.SEQUENCE)+
									    convert(varchar,AN.RELATEDNAME)),10,19))
								from CASES C
								join NAME N1 on (N1.NAMENO=N.NAMENO)
								join ASSOCIATEDNAME AN on ( AN.NAMENO=N.NAMENO
											and AN.RELATIONSHIP='EMP'
											and AN.CEASEDDATE is null
											and (AN.PROPERTYTYPE is not null
												or AN.COUNTRYCODE is not null
												or AN.RELATEDNAME=N1.MAINCONTACT)
											and (AN.PROPERTYTYPE=C.PROPERTYTYPE or AN.PROPERTYTYPE is null )
											and (AN.COUNTRYCODE=C.COUNTRYCODE or AN.COUNTRYCODE  is null ) )
								where C.CASEID=M.DRAFTCASEID )
						     END
					END,
					CASE WHEN( (convert(bit,NT.COLUMNFLAGS&1)=1 or NT.NAMETYPE in ('I','A'))
							and isnull(S.COLBOOLEAN,1)=0
							and AN.NAMENO is not null) THEN 0
					     ELSE 1
					END,
					-- Check if the Bill Percentage is required
					CASE WHEN(NT.COLUMNFLAGS&64=64) THEN 100 END
				From EDECASEMATCH M
				join #TEMPCASEMATCH TM	on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
				join EDECASENAMEDETAILS CN	
							on (CN.BATCHNO=M.BATCHNO
							and CN.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
				join NAMETYPE NT	on (NT.NAMETYPE=CN.NAMETYPECODE_T)
				join EDEADDRESSBOOK A	on (A.BATCHNO=M.BATCHNO
							and A.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER
							and A.NAMETYPECODE=CN.NAMETYPECODE
							and isnull(A.NAMESEQUENCENUMBER,'')=isnull(CN.NAMESEQUENCENUMBER,''))
				join NAME N		on (N.NAMENO=A.NAMENO)
				left join EDEFORMATTEDATTNOF AN
							on (AN.BATCHNO=M.BATCHNO
							and AN.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER
							and AN.NAMETYPECODE=CN.NAMETYPECODE
							and isnull(AN.NAMESEQUENCENUMBER,'')=isnull(CN.NAMESEQUENCENUMBER,''))
				left join SITECONTROL S on (S.CONTROLID='EDE Attention as Main Contact')
				left join SITECONTROL S1 on (S1.CONTROLID='Main Contact used as Attention')
				left join CASENAME CN1	on (CN1.CASEID=M.DRAFTCASEID
							and CN1.NAMETYPE=NT.NAMETYPE
							and CN1.NAMENO=N.NAMENO
							and CN1.SEQUENCE=isnull(CN.NAMESEQUENCENUMBER,0))
				Where M.BATCHNO=@pnBatchNo
				and CN1.CASEID is null
				order by 1,2,4"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int',
							  @pnBatchNo=@pnBatchNo
	
	
		End
		
		---------------------------------------
		-- Load CASENAME with REQUESTORNAMETYPE
		---------------------------------------
	
		If @sRequestorNameType is not null
		and @nErrorCode=0
		Begin
			-----------------------------------------------------------------
			-- Note that this name type is loaded after the other CASENAME
			-- rows as it needs to refer to the Instructor previously loaded.
			-----------------------------------------------------------------
			Set @sSQLString="
				Insert into CASENAME(CASEID, NAMETYPE, NAMENO, SEQUENCE, REFERENCENO, ADDRESSCODE,
							CORRESPONDNAME, DERIVEDCORRNAME, BILLPERCENTAGE)
				Select	M.DRAFTCASEID,
					NT.NAMETYPE,
					-- If the family of the proposed Requestor is the same
					-- as the family of the instructor then the Requestor 
					-- is to be  set to the instructor
					CASE WHEN(NR.FAMILYNO=NI.FAMILYNO)
						THEN NI.NAMENO
						ELSE NR.NAMENO
					END,
					0,
					isnull(C.SENDERCASEREFERENCE,C.SENDERCASEIDENTIFIER),
					CASE WHEN(NT.KEEPSTREETFLAG=1)
						THEN CASE WHEN(NR.FAMILYNO=NI.FAMILYNO)
							THEN NI.STREETADDRESS
							ELSE NR.STREETADDRESS
						     END
					END,
					CASE WHEN(NR.FAMILYNO=NI.FAMILYNO OR NI.NAMENO=NR.NAMENO)
						THEN CN.CORRESPONDNAME
					     WHEN(S1.COLBOOLEAN=1)
						THEN NR.MAINCONTACT
					     ELSE(select convert(int,substring(min(
								CASE WHEN(AN.PROPERTYTYPE is not null) THEN '0' ELSE '1' END+
								CASE WHEN(AN.COUNTRYCODE is not null) THEN '0' ELSE '1' END+
								CASE WHEN(AN.RELATEDNAME=N1.MAINCONTACT) THEN '0' ELSE '1' END+
								replicate('0',6-datalength(convert(varchar(6),AN.SEQUENCE)))+
								convert(varchar(6),AN.SEQUENCE)+
								convert(varchar,AN.RELATEDNAME)),10,19))
						  from CASES C
						  join NAME N1 on (N1.NAMENO=NR.NAMENO)
						  join ASSOCIATEDNAME AN on (AN.NAMENO=N1.NAMENO
									and  AN.RELATIONSHIP='EMP'
									and  AN.CEASEDDATE is null
									and (AN.PROPERTYTYPE is not null
										or AN.COUNTRYCODE is not null
										or AN.RELATEDNAME=N1.MAINCONTACT)
									and (AN.PROPERTYTYPE=C.PROPERTYTYPE or AN.PROPERTYTYPE is null )
									and (AN.COUNTRYCODE=C.COUNTRYCODE or AN.COUNTRYCODE  is null ) )
						  where C.CASEID=M.DRAFTCASEID)
					END,
					CASE WHEN(NR.FAMILYNO=NI.FAMILYNO OR NI.NAMENO=NR.NAMENO)
						THEN CN.DERIVEDCORRNAME
					     ELSE 1
					END,
					-- Check if the Bill Percentage is required
					CASE WHEN(NT.COLUMNFLAGS&64=64) THEN 100 END
				From EDECASEMATCH M
				join #TEMPCASEMATCH TM	on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
				join NAMETYPE NT	on (NT.NAMETYPE=@sRequestorNameType)
				join EDECASEDETAILS C	on (C.BATCHNO=M.BATCHNO
							and C.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
				join EDETRANSACTIONCONTENTDETAILS D	
							on (D.BATCHNO=M.BATCHNO
							and D.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
				join NAME NR		on (NR.NAMENO=isnull(D.ALTSENDERNAMENO,@nSenderNameNo))
				-- Get the Instructor
				left join CASENAME CN	on (CN.CASEID=M.DRAFTCASEID
							and CN.NAMETYPE='I'
							and(CN.EXPIRYDATE  > getdate() or CN.EXPIRYDATE   is null)
							and(CN.COMMENCEDATE<=getdate() or CN.COMMENCEDATE is null))
				left join NAME NI	on (NI.NAMENO=CN.NAMENO)
				left join SITECONTROL S1 on (S1.CONTROLID='Main Contact used as Attention')
				left join CASENAME CN1	on (CN1.CASEID=M.DRAFTCASEID
							and CN1.NAMETYPE=NT.NAMETYPE
							and CN1.NAMENO=	CASE WHEN(NR.FAMILYNO=NI.FAMILYNO)
										THEN NI.NAMENO
										ELSE NR.NAMENO
									END)
				Where M.BATCHNO=@pnBatchNo
				and CN1.CASEID is null"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @sRequestorNameType	nvarchar(3),
							  @nSenderNameNo	int',
							  @pnBatchNo=@pnBatchNo,
							  @sRequestorNameType=@sRequestorNameType,
							  @nSenderNameNo=@nSenderNameNo

			If  @nErrorCode=0
			and @sRequestType not in ('Extract Cases Response')
			Begin
				------------------------------------------------
				-- SQA16494
				-- Where no Instructor has been supplied then
				-- use the @sRequestorNameType as the Instructor
				------------------------------------------------
				Set @sSQLString="
				Insert into CASENAME(CASEID, NAMETYPE, NAMENO, SEQUENCE, REFERENCENO, ADDRESSCODE,
							CORRESPONDNAME, DERIVEDCORRNAME, BILLPERCENTAGE)
				select CN.CASEID,NT.NAMETYPE,CN.NAMENO,0,CN.REFERENCENO,
					CASE WHEN(NT.KEEPSTREETFLAG=1) THEN NR.STREETADDRESS END,
					
					CASE WHEN(S.COLBOOLEAN=1) THEN NR.MAINCONTACT
					     ELSE(select convert(int,substring(min(
								CASE WHEN(AN.PROPERTYTYPE is not null) THEN '0' ELSE '1' END+
								CASE WHEN(AN.COUNTRYCODE is not null) THEN '0' ELSE '1' END+
								CASE WHEN(AN.RELATEDNAME=N1.MAINCONTACT) THEN '0' ELSE '1' END+
								replicate('0',6-datalength(convert(varchar(6),AN.SEQUENCE)))+
								convert(varchar(6),AN.SEQUENCE)+
								convert(varchar,AN.RELATEDNAME)),10,19))
						  from CASES C
						  join NAME N1 on (N1.NAMENO=NR.NAMENO)
						  join ASSOCIATEDNAME AN on (AN.NAMENO=N1.NAMENO
									and  AN.RELATIONSHIP='EMP'
									and  AN.CEASEDDATE is null
									and (AN.PROPERTYTYPE is not null
										or AN.COUNTRYCODE is not null
										or AN.RELATEDNAME=N1.MAINCONTACT)
									and (AN.PROPERTYTYPE=C.PROPERTYTYPE or AN.PROPERTYTYPE is null )
									and (AN.COUNTRYCODE=C.COUNTRYCODE or AN.COUNTRYCODE  is null ) )
						  where C.CASEID=M.DRAFTCASEID)
					END,
					1,
					-- Check if the Bill Percentage is required
					CASE WHEN(NT.COLUMNFLAGS&64=64) THEN 100 END
				From EDECASEMATCH M
				join #TEMPCASEMATCH TM	on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
				join CASENAME CN	on (CN.CASEID=M.DRAFTCASEID
							and CN.NAMETYPE=@sRequestorNameType)
				join NAME NR		on (NR.NAMENO=CN.NAMENO)
				join NAMETYPE NT	on (NT.NAMETYPE='I')
				left join CASENAME CN1	on (CN1.CASEID=M.DRAFTCASEID
							and CN1.NAMETYPE=NT.NAMETYPE)
				left join SITECONTROL S on (S.CONTROLID='Main Contact used as Attention')
				Where M.BATCHNO=@pnBatchNo
				and CN1.CASEID is null"
	
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @sRequestorNameType	nvarchar(3)',
							  @pnBatchNo=@pnBatchNo,
							  @sRequestorNameType=@sRequestorNameType				
			End

			If  @nErrorCode=0
			and @sRequestorNameType='A'
			and @sRequestType='Agent Input'
			and @nSenderNameNo is not null
			Begin
				----------------------------------------------
				-- RFC72841
				-- If the batch type is Agent Input then 
				-- compare the Requestor Name against the 
				-- existing Agent against a match case. Raise
				-- IssueId -45 if the agent is different.
				----------------------------------------------
				Set @nIssueNo = -45

				Set @sSQLString="
				Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED)
				Select distinct @nIssueNo, C.BATCHNO, C.TRANSACTIONIDENTIFIER, 
						getdate()
				from EDECASEMATCH C
				join #TEMPCASEMATCH TM		 on (TM.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
				left join CASENAME CN		 on (CN.CASEID  =C.LIVECASEID
								 and CN.NAMETYPE='A'
								 and CN.NAMENO  =@nSenderNameNo
								 and CN.EXPIRYDATE is null)
				left join EDEOUTSTANDINGISSUES I on (I.ISSUEID=@nIssueNo
								 and I.BATCHNO=C.BATCHNO
								 and I.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
				where C.BATCHNO=@pnBatchNo
				and CN.NAMENO is null		-- The Sender is not the current Agent
				and I.ISSUEID is null		-- The Issue has not already been raised against the transaction
				----------------------------
				-- An agent currently exists
				-- against the live case.
				----------------------------
				and exists
				(select 1
				 from CASENAME CN1
				 where CN1.CASEID=C.LIVECASEID
				 and CN1.NAMETYPE='A'
				 and CN1.EXPIRYDATE is null)"
	
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	 int,
							  @nIssueNo	 int,
							  @nSenderNameNo int',
							  @pnBatchNo	=@pnBatchNo,
							  @nIssueNo	=@nIssueNo,
							  @nSenderNameNo=@nSenderNameNo
			End
		End
	
		---------------------------------
		-- Update Instructor to reset its 
		-- ReferenceNo if the Instructor 
		-- and the Data Instructor are
		-- the same.
		---------------------------------
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Update CASENAME
			Set REFERENCENO=CN1.REFERENCENO
			from CASENAME CN
			join EDECASEMATCH M	on (M.DRAFTCASEID=CN.CASEID)
			join #TEMPCASEMATCH TM	on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			-- derived table required to avoid ambiguity error
			join (	select CASEID, NAMENO, REFERENCENO
				from CASENAME
				where NAMETYPE=@sRequestorNameType
				and REFERENCENO is not null) CN1
						on (CN1.CASEID=CN.CASEID
						and CN1.NAMENO=CN.NAMENO)
			Where M.BATCHNO=@pnBatchNo
			and CN.NAMETYPE='I'
			and CN.EXPIRYDATE is null
			and CN.REFERENCENO is null
			and(CN.COMMENCEDATE>getdate() OR CN.COMMENCEDATE is null)"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @sRequestorNameType	nvarchar(3)',
							  @pnBatchNo=@pnBatchNo,
							  @sRequestorNameType=@sRequestorNameType
			
		End
				
		-----------------------------------
		-- SQA16589 & SQA17385
		-- Load CASENAME with inherited
		-- NameTypes if they have not been
		-- loaded already. This will apply
		-- the defaulting rules for each
		-- of the NameTypes.
		----------------------------------
		If @nErrorCode=0
		Begin
			Set @sSQLString1="
			Insert into CASENAME
				(
					CASEID,
					NAMETYPE,
					NAMENO,
					[SEQUENCE],
					REFERENCENO,
					CORRESPONDNAME,
					DERIVEDCORRNAME,
					ADDRESSCODE,
					BILLPERCENTAGE,
					INHERITED,
					INHERITEDNAMENO,
					INHERITEDRELATIONS,
					INHERITEDSEQUENCE
				)
			select 	distinct
				CS.CASEID, 
				NT.NAMETYPE,
				N.NAMENO as NAMENO,
				ROW_NUMBER() OVER(PARTITION BY CS.CASEID, NT.NAMETYPE, N.NAMENO 
						          ORDER  BY CS.CASEID, NT.NAMETYPE, N.NAMENO ) -1 as [SEQUENCE], -- Subtracting 1 so SEQUENCE starts at 0
				CASE	WHEN (convert(bit,NT.COLUMNFLAGS&4)=1 and N.NAMENO=CN.NAMENO) THEN CN.REFERENCENO END, --SQA17695
				-- Only set correspondname if name type indicates, or Instructor or Agent.
				CASE	WHEN (convert(bit,NT.COLUMNFLAGS&1)=0 and NT.NAMETYPE not in ('I','A')) THEN null
					WHEN (A.CONTACT is not null) THEN A.CONTACT
					WHEN (A.RELATEDNAME is not null)
							THEN dbo.fn_GetDerivedAttnNameNo(A.RELATEDNAME,CS.CASEID,NT.NAMETYPE)
					WHEN (NT.HIERARCHYFLAG=1 and CN.NAMENO is not null)
							THEN CN.CORRESPONDNAME
					WHEN (NT.USEHOMENAMEREL=1 and AH.RELATEDNAME is not null)
							THEN CASE WHEN(AH.CONTACT is not null) THEN AH.CONTACT
								  ELSE dbo.fn_GetDerivedAttnNameNo(AH.RELATEDNAME,CS.CASEID,NT.NAMETYPE)
							     END
					WHEN (NT.DEFAULTNAMENO is not null)
							THEN dbo.fn_GetDerivedAttnNameNo(NT.DEFAULTNAMENO,CS.CASEID,NT.NAMETYPE)
				END as CORRESPONDNAME,
				-- copy derived correspondname flag from parent.
				-- copy derived correspondname flag if name type uses attention, or Instructor or Agent.
				CASE	WHEN ((convert(bit,NT.COLUMNFLAGS&1)=0 and NT.NAMETYPE not in ('I','A'))
						or A.RELATEDNAME is not null
						or AH.RELATEDNAME is not null
						or CN.NAMENO is null
						or isnull(NT.HIERARCHYFLAG,0)=0 ) then 1
					ELSE CN.DERIVEDCORRNAME
				END as DERIVEDCORRNAME,
				-- Save address code if the Name Type requires one.
				CASE WHEN NT.KEEPSTREETFLAG = 1
				     THEN N.STREETADDRESS
				END  as ADDRESSCODE, 			
				-- If the bill percent flag is on, default to 100
				CASE WHEN convert(bit, NT.COLUMNFLAGS & 64) = 1 THEN 100 ELSE null END as BILLPERCENTAGE,
				1 as INHERITED,
				-- Save pointer to parent name.
				CASE WHEN (NT.PATHRELATIONSHIP is null
						or A.RELATEDNAME is not null
						or NT.USEHOMENAMEREL=0
						or AH.RELATEDNAME is null) THEN CN.NAMENO
				     ELSE S.COLINTEGER
				END as INHERITEDNAMENO,
				isnull(A.RELATIONSHIP,AH.RELATIONSHIP) as INHERITEDRELATIONS,
				isnull(A.SEQUENCE,AH.SEQUENCE) as INHERITEDSEQUENCE"
				
			Set @sSQLString2="
			from EDECASEMATCH M
			join #TEMPCASEMATCH TM	on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
     			join CASES CS 		on (CS.CASEID = M.DRAFTCASEID)
     			join NAMETYPE NT	on (NT.PATHNAMETYPE  is not null
     						OR  NT.DEFAULTNAMENO is not null)
			-- The CaseName that acts as the starting point
			left join CASENAME CN	on (CN.CASEID = CS.CASEID
			    			and CN.NAMETYPE = NT.PATHNAMETYPE) 
			-- Pick up the CaseName's associated Name
     			left join ASSOCIATEDNAME A 
						on (A.NAMENO = CN.NAMENO 
						and A.RELATIONSHIP = NT.PATHRELATIONSHIP
						and(A.PROPERTYTYPE = CS.PROPERTYTYPE or A.PROPERTYTYPE is null)
						and(A.COUNTRYCODE  = CS.COUNTRYCODE  or A.COUNTRYCODE  is null)
						-- There may be multiple AssociatedNames.  
						-- A best fit against the Case attributes is required to determine
						-- the characteristics of the Associated Name that best match the Case.
						-- This then allows for all of the associated names with the best
						-- characteristics for the Case to be returned.
						and CASE WHEN(A.PROPERTYTYPE is null) THEN '0' ELSE '1' END +
						    CASE WHEN(A.COUNTRYCODE  is null) THEN '0' ELSE '1' END
							=	(	select
									max (	case when (A1.PROPERTYTYPE is null) then '0' else '1' end +    			
										case when (A1.COUNTRYCODE  is null) then '0' else '1' end)
									from ASSOCIATEDNAME A1
									where A1.NAMENO=A.NAMENO
									and   A1.RELATIONSHIP=A.RELATIONSHIP
									and  (A1.PROPERTYTYPE=CS.PROPERTYTYPE OR A1.PROPERTYTYPE is null)
									and  (A1.COUNTRYCODE =CS.COUNTRYCODE  OR A1.COUNTRYCODE  is null)))
			-- Get the Home NameNo if no associated Name found and inheritance
			-- is to also consider the Home Name.
			left join SITECONTROL S	on (S.CONTROLID='HOMENAMENO'
						and A.RELATEDNAME is null
						and NT.USEHOMENAMEREL=1) "
						
			Set @sSQLString3="
			-- Pick up the Home Name's associated Name
     			left join ASSOCIATEDNAME AH 
						on (AH.NAMENO = S.COLINTEGER 
						and AH.RELATIONSHIP = NT.PATHRELATIONSHIP
						and(AH.PROPERTYTYPE = CS.PROPERTYTYPE or AH.PROPERTYTYPE is null)
						and(AH.COUNTRYCODE  = CS.COUNTRYCODE  or AH.COUNTRYCODE  is null)
						-- There may be multiple AssociatedNames.  
						-- A best fit against the Case attributes is required to determine
						-- the characteristics of the Associated Name that best match the Case.
						-- This then allows for all of the associated names with the best
						-- characteristics for the Case to be returned.
						
						and CASE WHEN(AH.PROPERTYTYPE is null) THEN '0' ELSE '1' END +
						    CASE WHEN(AH.COUNTRYCODE  is null) THEN '0' ELSE '1' END
							=	(	select
									max (	case when (AH1.PROPERTYTYPE is null) then '0' else '1' end +    			
										case when (AH1.COUNTRYCODE  is null) then '0' else '1' end)
									from ASSOCIATEDNAME AH1
									where AH1.NAMENO=AH.NAMENO
									and   AH1.RELATIONSHIP=AH.RELATIONSHIP
									and  (AH1.PROPERTYTYPE=CS.PROPERTYTYPE OR AH1.PROPERTYTYPE is null)
									and  (AH1.COUNTRYCODE =CS.COUNTRYCODE  OR AH1.COUNTRYCODE  is null)))
			-- Choose the name to add
     			join NAME N  on (N.NAMENO= 	CASE 
								-- Handle when defaulting directly from another NameType.
								WHEN (NT.PATHNAMETYPE is not null and NT.PATHRELATIONSHIP is null)THEN CN.NAMENO
								WHEN(A.RELATEDNAME is not null) THEN A.RELATEDNAME
								--  Only default to parent name if hierarchy flag set on.
								WHEN(NT.HIERARCHYFLAG=1)	THEN CN.NAMENO
								-- Use Default Name if relationship not there for home name.
								WHEN(NT.USEHOMENAMEREL=1)       THEN isnull(AH.RELATEDNAME, NT.DEFAULTNAMENO)
								-- Use Default Name if nothing else found.
								ELSE NT.DEFAULTNAMENO
							END)
			left join CASENAME CN1	on (CN1.CASEID=CS.CASEID
						and CN1.NAMETYPE=NT.NAMETYPE)
			where M.BATCHNO="+cast(@pnBatchNo as varchar(11))+"
			and CN1.CASEID is null
			-- Only default if parent name type exists against the case,
			-- or no parent name type and default name defined.
			and ( CN.NAMENO is not null or (NT.PATHNAMETYPE is null and NT.DEFAULTNAMENO is not null) )
			Order by CS.CASEID, NT.NAMETYPE, N.NAMENO"
			
			exec(@sSQLString1+@sSQLString2+@sSQLString3)
			
			Set @nErrorCode=@@Error
		End
	
		---------------------------------
		-- Update CASENAME to ensure the
		-- Sequence is incremented within 
		-- each NameType for a Case.
		---------------------------------
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Update CASENAME
			Set @nSequenceNo=CASE WHEN(@nCaseId=CN.CASEID and @sNameType=CN.NAMETYPE)
						THEN @nSequenceNo+1
						ELSE 0
					 END,
			    @nCaseId  =CN.CASEID,
			    @sNameType=CN.NAMETYPE,
			    SEQUENCE  =@nSequenceNo
			from CASENAME CN
			join EDECASEMATCH M	on (M.DRAFTCASEID=CN.CASEID)
			join #TEMPCASEMATCH TM	on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			Where M.BATCHNO=@pnBatchNo"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @nCaseId		int		OUTPUT,
							  @sNameType		nvarchar(3)	OUTPUT,
							  @nSequenceNo		smallint	OUTPUT',
							  @pnBatchNo=@pnBatchNo,
							  @nCaseId=@nCaseId			OUTPUT,
							  @sNameType=@sNameType			OUTPUT,
							  @nSequenceNo=@nSequenceNo		OUTPUT
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
			Set	LOCALCLIENTFLAG=IP.LOCALCLIENTFLAG,
				LOCALCLASSES   =isnull(C.LOCALCLASSES,C.INTCLASSES),
				NOOFCLASSES    =CASE WHEN(isnull(C.LOCALCLASSES,C.INTCLASSES) is not null)
							-- count the comma separators and increment by 1
							THEN dbo.fn_StringOccurrenceCount(',',isnull(C.LOCALCLASSES,C.INTCLASSES))+1
						END,
				CURRENTOFFICIALNO = substring(O1.OFFICIALNUMBER,14,36)
			From CASES C
			join EDECASEMATCH M	on (M.DRAFTCASEID=C.CASEID)
			join #TEMPCASEMATCH TM	on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
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
					group by O.CASEID) O1 	on (O1.CASEID=C.CASEID)
			Where M.BATCHNO=@pnBatchNo"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End
	
		------------------------
		-- Load CASETEXT details
		-- for Goods & Services
		------------------------
		
		If @nErrorCode=0
		Begin
			------------------------------------
			-- A trigger against the CASES table 
			-- inserts a CASETEXT row for each
			-- Class stored in LOCALCLASSES
			-- Update those rows with any Goods
			-- and services text.
			------------------------------------
			Set @sSQLString="
			Update CASETEXT
			SET
			LONGFLAG =CASE WHEN(D.CLASSNUMBER=CT.CLASS OR CT.CLASS='0'+D.CLASSNUMBER)
					THEN CASE WHEN(datalength(D.GOODSSERVICESDESCRIPTION)>508) THEN 1    ELSE 0 END
					ELSE CASE WHEN(datalength(I.GOODSSERVICESDESCRIPTION)>508) THEN 1    ELSE 0 END
				  END,
			SHORTTEXT=CASE WHEN(D.CLASSNUMBER=CT.CLASS OR CT.CLASS='0'+D.CLASSNUMBER)
					THEN CASE WHEN(datalength(D.GOODSSERVICESDESCRIPTION)>508) THEN NULL ELSE D.GOODSSERVICESDESCRIPTION END
					ELSE CASE WHEN(datalength(I.GOODSSERVICESDESCRIPTION)>508) THEN NULL ELSE I.GOODSSERVICESDESCRIPTION END
				  END,
			TEXT=	  CASE WHEN(D.CLASSNUMBER=CT.CLASS OR CT.CLASS='0'+D.CLASSNUMBER)
					THEN CASE WHEN(datalength(D.GOODSSERVICESDESCRIPTION)<509) THEN NULL ELSE D.GOODSSERVICESDESCRIPTION END
					ELSE CASE WHEN(datalength(I.GOODSSERVICESDESCRIPTION)<509) THEN NULL ELSE I.GOODSSERVICESDESCRIPTION END
				  End
			from EDECASEMATCH M
			join #TEMPCASEMATCH TM	on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join CASETEXT CT	on (CT.CASEID=M.DRAFTCASEID
						and CT.TEXTTYPE='G')
			left join EDECLASSDESCRIPTION D on (D.BATCHNO=M.BATCHNO
						   	and D.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER
							and D.CLASSIFICATIONTYPECODE='Domestic'
							and(D.CLASSNUMBER=CT.CLASS OR CT.CLASS='0'+D.CLASSNUMBER))	--RFC51926 Handle CLASSES missing the leading zero
			left join EDECLASSDESCRIPTION I on (I.BATCHNO=M.BATCHNO
						   	and I.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER
							and I.CLASSIFICATIONTYPECODE='Nice'
							and(I.CLASSNUMBER=CT.CLASS OR CT.CLASS='0'+I.CLASSNUMBER))	--RFC51926 Handle CLASSES missing the leading zero
			where M.BATCHNO=@pnBatchNo
			and CT.CLASS is not null
			and(datalength(D.GOODSSERVICESDESCRIPTION)>0 
			 OR datalength(I.GOODSSERVICESDESCRIPTION)>0)"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End
		
		If @nErrorCode=0
		Begin
			--------------------------------------
			-- Still need to insert a CASETEXT row
			-- in Case the Goods/Services imported
			-- does not match cleanly against the 
			-- individual Classes e.g. "18 and 32"
			--------------------------------------
			Set @sSQLString="
			insert into CASETEXT(CASEID, TEXTTYPE, TEXTNO, CLASS, LONGFLAG, SHORTTEXT, TEXT)
			select 	M.DRAFTCASEID,
				'G',
				(	select count(*)
					From EDECLASSDESCRIPTION D1 
					left join CASETEXT CT1	on (CT1.CASEID=M.DRAFTCASEID
								and CT1.TEXTTYPE='G'
								and(CT1.CLASS=replace(D1.CLASSNUMBER,' ','')
								 OR CT1.CLASS='0'+replace(D1.CLASSNUMBER,' ','')))
					where D1.BATCHNO=D.BATCHNO
					and   D1.TRANSACTIONIDENTIFIER=D.TRANSACTIONIDENTIFIER
					and   D1.CLASSIFICATIONTYPECODE=D.CLASSIFICATIONTYPECODE
					and   D1.CLASSNUMBER<D.CLASSNUMBER
					and   CT1.CASEID is null
				) + isnull(TC.TEXTCOUNT,0),
				CASE WHEN(isnumeric(D.CLASSNUMBER)=1)
						THEN CASE WHEN(CAST(D.CLASSNUMBER as NUMERIC) between 1 and 9)
							THEN '0'+cast(cast(D.CLASSNUMBER as tinyint) as char(1))
							ELSE D.CLASSNUMBER
						     END
						ELSE substring(D.CLASSNUMBER,1,11)
				     END,
				CASE WHEN(datalength(D.GOODSSERVICESDESCRIPTION)>508) THEN 1    ELSE 0 END,
				CASE WHEN(datalength(D.GOODSSERVICESDESCRIPTION)>508) THEN NULL ELSE D.GOODSSERVICESDESCRIPTION END,
				CASE WHEN(datalength(D.GOODSSERVICESDESCRIPTION)<509) THEN NULL ELSE D.GOODSSERVICESDESCRIPTION END
			from EDECASEMATCH M
			join #TEMPCASEMATCH TM	   on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join EDECLASSDESCRIPTION D on (D.BATCHNO=M.BATCHNO
						   and D.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			left join (select CASEID, max(TEXTNO) as TEXTCOUNT
				   from CASETEXT
				   where TEXTTYPE='G'
				   group by CASEID) TC
						on (TC.CASEID=M.DRAFTCASEID)
			left join CASETEXT CT	on (CT.CASEID=M.DRAFTCASEID
						and CT.TEXTTYPE='G'
						and(CT.CLASS=substring(replace(D.CLASSNUMBER,' ',''),1,11)
						 OR CT.CLASS='0'+substring(replace(D.CLASSNUMBER,' ',''),1,11)))	--RFC51926 Handle CLASSES missing the leading zero
			where M.BATCHNO=@pnBatchNo
			and M.DRAFTCASEID is not null
			and CT.CASEID is null
			and D.CLASSIFICATIONTYPECODE='Domestic'
			and D.CLASSNUMBER<>'and'
			and substring(D.CLASSNUMBER,1,11)<>''"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End
			
		------------------------------------------
		-- Raise an issue if the OFFICE for the  
		-- newly created Case is not available in
		-- the OFFICE table
		------------------------------------------
		If @nErrorCode=0
		Begin
			Set @nIssueNo = -41
	
			Set @sSQLString="
			Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED,ISSUETEXT)
			Select @nIssueNo, C.BATCHNO, C.TRANSACTIONIDENTIFIER, getdate(), C.CASEOFFICE
			from EDECASEDETAILS C
			join #TEMPCASES T		on (T.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			left join OFFICE O		on (O.DESCRIPTION=C.CASEOFFICE)
			left join EDEOUTSTANDINGISSUES I on (I.ISSUEID=@nIssueNo
							 and I.BATCHNO=C.BATCHNO
							 and I.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			where C.BATCHNO=@pnBatchNo
			and C.CASEOFFICE is not null
			and O.OFFICEID   is null
			and I.ISSUEID    is null"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int,
						  @nIssueNo	int',
						  @pnBatchNo=@pnBatchNo,
						  @nIssueNo =@nIssueNo
		End
	
		------------------------------------------
		-- Raise an issue if the Relationship 
		-- for the RelatedCase is not valid
		-- for the Jurisdiction and Property Type.
		------------------------------------------
	
		If @nErrorCode=0
		Begin
			Set @nIssueNo = -40
	
			Set @sSQLString="
			Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED, ISSUETEXT)
			Select I.ISSUEID, M.BATCHNO, M.TRANSACTIONIDENTIFIER, getdate(), CR.RELATIONSHIP
			From EDECASEMATCH M
			join #TEMPCASEMATCH TM		  on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join CASES C			  on (C.CASEID=M.DRAFTCASEID)
			join EDEASSOCIATEDCASEDETAILS AC  on (AC.BATCHNO=M.BATCHNO
							  and AC.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join CASERELATION CR		  on (CR.RELATIONSHIP=ASSOCIATEDCASERELATIONSHIPCODE_T)
			join EDESTANDARDISSUE I		  on (I.ISSUEID=@nIssueNo)
			left join VALIDRELATIONSHIPS VR	  on (VR.PROPERTYTYPE=C.PROPERTYTYPE
							  and VR.RELATIONSHIP=CR.RELATIONSHIP
							  and VR.COUNTRYCODE=(select min(VR1.COUNTRYCODE)
							                      from VALIDRELATIONSHIPS VR1
							                      where VR1.PROPERTYTYPE=VR.PROPERTYTYPE
							                      and   VR1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))
			Where M.BATCHNO=@pnBatchNo
			and AC.ASSOCCASESEQ is not null
			and VR.RELATIONSHIP is null"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int,
						  @nIssueNo	int',
						  @pnBatchNo=@pnBatchNo,
						  @nIssueNo =@nIssueNo
		End
	
		---------------------------
		-- Load RELATEDCASE details
		---------------------------
	
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Insert into RELATEDCASE(CASEID, RELATIONSHIPNO, RELATIONSHIP, COUNTRYCODE, OFFICIALNUMBER, PRIORITYDATE)
			Select distinct M.DRAFTCASEID, 
					AC.ASSOCCASESEQ,
					CR.RELATIONSHIP, 
					CT.COUNTRYCODE,
					N.IDENTIFIERNUMBERTEXT,
					E.EVENTDATE
			From EDECASEMATCH M
			join #TEMPCASEMATCH TM		  on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join EDEASSOCIATEDCASEDETAILS AC  on (AC.BATCHNO=M.BATCHNO
							  and AC.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join CASERELATION CR		  on (CR.RELATIONSHIP=ASSOCIATEDCASERELATIONSHIPCODE_T)
			left join COUNTRY CT		  on (CT.COUNTRYCODE=AC.ASSOCIATEDCASECOUNTRYCODE_T)
			left join 
			      (	select	BATCHNO, TRANSACTIONIDENTIFIER, ASSOCCASESEQ, ASSOCIATEDCASERELATIONSHIPCODE, ASSOCIATEDCASECOUNTRYCODE,
					min(ISNULL(IDENTIFIERNUMBERTEXT, '')) as IDENTIFIERNUMBERTEXT
				from EDEIDENTIFIERNUMBERDETAILS
				group by BATCHNO, 
					 TRANSACTIONIDENTIFIER, 
					 ASSOCCASESEQ, 
					 ASSOCIATEDCASERELATIONSHIPCODE, 
					 ASSOCIATEDCASECOUNTRYCODE) N
							on (N.BATCHNO=M.BATCHNO
							and N.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER
							and(N.ASSOCCASESEQ=AC.ASSOCCASESEQ or N.ASSOCCASESEQ is null)
							and N.ASSOCIATEDCASERELATIONSHIPCODE=AC.ASSOCIATEDCASERELATIONSHIPCODE
							and isnull(N.ASSOCIATEDCASECOUNTRYCODE,'')=isnull(AC.ASSOCIATEDCASECOUNTRYCODE,''))
			left join EDEEVENTDETAILS E	on (E.BATCHNO=M.BATCHNO
							and E.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER
							and(E.ASSOCCASESEQ=AC.ASSOCCASESEQ OR E.ASSOCCASESEQ is null)
							and E.ASSOCIATEDCASERELATIONSHIPCODE=AC.ASSOCIATEDCASERELATIONSHIPCODE
							and isnull(E.ASSOCIATEDCASECOUNTRYCODE,'')=isnull(AC.ASSOCIATEDCASECOUNTRYCODE,''))
			left join RELATEDCASE RC	on (RC.CASEID=M.DRAFTCASEID
							and RC.RELATIONSHIPNO=AC.ASSOCCASESEQ)
			Where M.BATCHNO=@pnBatchNo
			and M.DRAFTCASEID   is not null
			and AC.ASSOCCASESEQ is not null
			and RC.CASEID       is null
			and(N.IDENTIFIERNUMBERTEXT is NOT NULL OR E.EVENTDATE is NOT NULL)"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End

		------------------------------------------------------------------
		-- SQA18403
		-- Now update the new RelatedCase if a live Case can be identified
		-- that matches on Official Number, Country and date if a date has
		-- been provided as well as Property Type.
		-- If there is no CaseEvent to match on then it will be excluded
		-- from the match criteria.
		------------------------------------------------------------------
		-- Preference 1 : Match on live case with same Property Type
		------------------------------------------------------------------
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Update RC
			Set RELATEDCASEID =C1.CASEID,
			    OFFICIALNUMBER=NULL,
			    COUNTRYCODE   =NULL,
			    PRIORITYDATE  =NULL
			From EDECASEMATCH M
			join #TEMPCASEMATCH TM	  on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join EDEASSOCIATEDCASEDETAILS AC 
						  on (AC.BATCHNO=M.BATCHNO
						  and AC.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join CASES C		  on (C.CASEID=M.DRAFTCASEID)
			join CASETYPE CT	  on (CT.CASETYPE=C.CASETYPE)
			join RELATEDCASE RC	  on (RC.CASEID=C.CASEID
						  and RC.RELATEDCASEID is null)
			join EDEIDENTIFIERNUMBERDETAILS N
						  on (N.BATCHNO=M.BATCHNO
						  and N.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER
						  and N.IDENTIFIERNUMBERTEXT =RC.OFFICIALNUMBER
						  and N.ASSOCCASESEQ         =RC.RELATIONSHIPNO)
			join OFFICIALNUMBERS O	  on (O.OFFICIALNUMBER=RC.OFFICIALNUMBER
						  and O.NUMBERTYPE=N.IDENTIFIERNUMBERCODE_T)
			join CASES C1		  on (C1.CASEID      = O.CASEID
						  and C1.COUNTRYCODE =RC.COUNTRYCODE
						  and C1.PROPERTYTYPE= C.PROPERTYTYPE
						  and C1.CASETYPE    = CT.ACTUALCASETYPE)	-- Live CaseType
			join CASERELATION CR	  on (CR.RELATIONSHIP  =RC.RELATIONSHIP)
			left join CASEEVENT CE	  on (CE.CASEID   =C1.CASEID
						  and CE.EVENTNO  =CR.FROMEVENTNO
						  and CE.CYCLE    =1)
			Where M.BATCHNO = @pnBatchNo
			and (CE.EVENTDATE=RC.PRIORITYDATE OR RC.PRIORITYDATE is null OR CE.CASEID is NULL)
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
						and C2.CASETYPE    =CT.ACTUALCASETYPE)
			 where O2.OFFICIALNUMBER=RC.OFFICIALNUMBER
			 and   O2.NUMBERTYPE=N.IDENTIFIERNUMBERCODE_T
			 and   O2.CASEID<>O.CASEID)"

			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int',
							  @pnBatchNo=@pnBatchNo
		End

		------------------------------------------------------------------
		-- Now update the new RelatedCase if a draft Case can be identified
		-- that matches on Official Number and Country
		------------------------------------------------------------------
		-- Preference 2 : Match on Draft case with same Property Type
		------------------------------------------------------------------
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Update RC
			Set RELATEDCASEID =C1.CASEID,
			    OFFICIALNUMBER=NULL,
			    COUNTRYCODE   =NULL,
			    PRIORITYDATE  =NULL
			From EDECASEMATCH M
			join #TEMPCASEMATCH TM	  on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join EDEASSOCIATEDCASEDETAILS AC 
						  on (AC.BATCHNO=M.BATCHNO
						  and AC.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join CASES C		  on (C.CASEID=M.DRAFTCASEID)
			join RELATEDCASE RC	  on (RC.CASEID=C.CASEID
						  and RC.RELATEDCASEID is null)
			join EDEIDENTIFIERNUMBERDETAILS N
						  on (N.BATCHNO=M.BATCHNO
						  and N.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER
						  and N.IDENTIFIERNUMBERTEXT =RC.OFFICIALNUMBER
						  and N.ASSOCCASESEQ         =RC.RELATIONSHIPNO)
			join OFFICIALNUMBERS O	  on (O.OFFICIALNUMBER=RC.OFFICIALNUMBER
						  and O.NUMBERTYPE=N.IDENTIFIERNUMBERCODE_T)
			join CASES C1		  on (C1.CASEID      = O.CASEID
						  and C1.COUNTRYCODE =RC.COUNTRYCODE
						  and C1.PROPERTYTYPE= C.PROPERTYTYPE
						  and C1.CASETYPE    = C.CASETYPE)
			join CASERELATION CR	  on (CR.RELATIONSHIP  =RC.RELATIONSHIP)
			Where M.BATCHNO = @pnBatchNo
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
			 and   O2.NUMBERTYPE=N.IDENTIFIERNUMBERCODE_T
			 and   O2.CASEID<>O.CASEID)"

			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int',
							  @pnBatchNo=@pnBatchNo
		End

		------------------------------------------------------------------
		-- RFC 73661
		-- If the new RelatedCase has not been linked to a live Case then
		-- consider cases without the Property Type included in the match.
		-- This can occur when a Patent is related to a Utility Model.
		------------------------------------------------------------------
		-- Preference 3 : Match on live case for any Property Type
		------------------------------------------------------------------
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Update RC
			Set RELATEDCASEID =C1.CASEID,
			    OFFICIALNUMBER=NULL,
			    COUNTRYCODE   =NULL,
			    PRIORITYDATE  =NULL
			From EDECASEMATCH M
			join #TEMPCASEMATCH TM	  on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join EDEASSOCIATEDCASEDETAILS AC 
						  on (AC.BATCHNO=M.BATCHNO
						  and AC.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join CASES C		  on (C.CASEID=M.DRAFTCASEID)
			join CASETYPE CT	  on (CT.CASETYPE=C.CASETYPE)
			join RELATEDCASE RC	  on (RC.CASEID=C.CASEID
						  and RC.RELATEDCASEID is null)
			join EDEIDENTIFIERNUMBERDETAILS N
						  on (N.BATCHNO=M.BATCHNO
						  and N.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER
						  and N.IDENTIFIERNUMBERTEXT =RC.OFFICIALNUMBER
						  and N.ASSOCCASESEQ         =RC.RELATIONSHIPNO)
			join OFFICIALNUMBERS O	  on (O.OFFICIALNUMBER=RC.OFFICIALNUMBER
						  and O.NUMBERTYPE=N.IDENTIFIERNUMBERCODE_T)
			join CASES C1		  on (C1.CASEID      = O.CASEID
						  and C1.COUNTRYCODE =RC.COUNTRYCODE
						  and C1.CASETYPE    = CT.ACTUALCASETYPE)	-- Live CaseType
			join CASERELATION CR	  on (CR.RELATIONSHIP  =RC.RELATIONSHIP)
			left join CASEEVENT CE	  on (CE.CASEID   =C1.CASEID
						  and CE.EVENTNO  =CR.FROMEVENTNO
						  and CE.CYCLE    =1)
			Where M.BATCHNO = @pnBatchNo
			and (CE.EVENTDATE=RC.PRIORITYDATE OR RC.PRIORITYDATE is null OR CE.CASEID is NULL)
			--------------------------------
			-- Check that there is not an
			-- alternative Case to match on.
			--------------------------------
			and not exists
			(select 1
			 from OFFICIALNUMBERS O2
			 join CASES C2		on (C2.CASEID=O2.CASEID
						and C2.COUNTRYCODE=RC.COUNTRYCODE
						and C2.CASETYPE    =CT.ACTUALCASETYPE)
			 where O2.OFFICIALNUMBER=RC.OFFICIALNUMBER
			 and   O2.NUMBERTYPE=N.IDENTIFIERNUMBERCODE_T
			 and   O2.CASEID<>O.CASEID)"

			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int',
							  @pnBatchNo=@pnBatchNo
		End
		
		------------------------------------------------------------------
		-- RFC 73661
		-- If the new RelatedCase has not been linked to a draft Case then
		-- consider cases without the Property Type included in the match.
		-- This can occur when a Patent is related to a Utility Model.
		------------------------------------------------------------------
		-- Preference 4 : Match on Draft case for any Property Type
		------------------------------------------------------------------
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Update RC
			Set RELATEDCASEID =C1.CASEID,
			    OFFICIALNUMBER=NULL,
			    COUNTRYCODE   =NULL,
			    PRIORITYDATE  =NULL
			From EDECASEMATCH M
			join #TEMPCASEMATCH TM	  on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join EDEASSOCIATEDCASEDETAILS AC 
						  on (AC.BATCHNO=M.BATCHNO
						  and AC.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join CASES C		  on (C.CASEID=M.DRAFTCASEID)
			join RELATEDCASE RC	  on (RC.CASEID=C.CASEID
						  and RC.RELATEDCASEID is null)
			join EDEIDENTIFIERNUMBERDETAILS N
						  on (N.BATCHNO=M.BATCHNO
						  and N.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER
						  and N.IDENTIFIERNUMBERTEXT =RC.OFFICIALNUMBER
						  and N.ASSOCCASESEQ         =RC.RELATIONSHIPNO)
			join OFFICIALNUMBERS O	  on (O.OFFICIALNUMBER=RC.OFFICIALNUMBER
						  and O.NUMBERTYPE=N.IDENTIFIERNUMBERCODE_T)
			join CASES C1		  on (C1.CASEID      = O.CASEID
						  and C1.COUNTRYCODE =RC.COUNTRYCODE
						  and C1.CASETYPE    = C.CASETYPE)
			join CASERELATION CR	  on (CR.RELATIONSHIP  =RC.RELATIONSHIP)
			Where M.BATCHNO = @pnBatchNo
			--------------------------------
			-- Check that there is not an
			-- alternative Case to match on.
			--------------------------------
			and not exists
			(select 1
			 from OFFICIALNUMBERS O2
			 join CASES C2		on (C2.CASEID=O2.CASEID
						and C2.COUNTRYCODE=RC.COUNTRYCODE
						and C2.CASETYPE    =C.CASETYPE)
			 where O2.OFFICIALNUMBER=RC.OFFICIALNUMBER
			 and   O2.NUMBERTYPE=N.IDENTIFIERNUMBERCODE_T
			 and   O2.CASEID<>O.CASEID)"

			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int',
							  @pnBatchNo=@pnBatchNo
		End
	
		---------------------------
		-- Raise an issue if there  
		-- are more than one Cases 
		-- that the Related Case
		-- can match with.
		---------------------------
	
		If @nErrorCode=0
		Begin
			Set @nIssueNo = -36
	
			Set @sSQLString="
			Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED)
			Select @nIssueNo, M.BATCHNO, M.TRANSACTIONIDENTIFIER, getdate()
			From EDECASEMATCH M
			join #TEMPCASEMATCH TM	on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join CASES C		on (C.CASEID=M.DRAFTCASEID)
			join CASETYPE CT	on (CT.CASETYPE=C.CASETYPE)
			join RELATEDCASE RC	on (RC.CASEID=C.CASEID
						and RC.RELATEDCASEID is null)
			join EDEIDENTIFIERNUMBERDETAILS N
						on (N.BATCHNO=M.BATCHNO
						and N.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER
						and N.IDENTIFIERNUMBERTEXT =RC.OFFICIALNUMBER
						and N.ASSOCCASESEQ         =RC.RELATIONSHIPNO)
			Where M.BATCHNO = @pnBatchNo
			------------------------------
			-- Check if there are multiple
			-- Case to match on.
			------------------------------
			and 
			(select count(*)
			 from OFFICIALNUMBERS O2
			 join CASES C2		on (C2.CASEID=O2.CASEID
						and C2.COUNTRYCODE=RC.COUNTRYCODE
						and C2.CASETYPE    =CT.ACTUALCASETYPE)
			 where O2.OFFICIALNUMBER=RC.OFFICIALNUMBER
			 and   O2.NUMBERTYPE=N.IDENTIFIERNUMBERCODE_T) > 1"	-- Duplicates exist
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int,
						  @nIssueNo	int',
						  @pnBatchNo=@pnBatchNo,
						  @nIssueNo =@nIssueNo
		End
		------------------------------------------------------------------
		-- RFC45318
		-- If a related case has linked to an Inprotech Case then see if
		-- a reciprocal relationship is able to be inserted to create the
		-- reverse relationship
		-- Need to consider draft cases inserted in this batch.
		------------------------------------------------------------------
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			With RecipRelationships AS
			(	Select  ROW_NUMBER() OVER(PARTITION BY coalesce(RC.RELATEDCASEID, C.CASEID) 
						          ORDER     BY coalesce(RC.RELATEDCASEID, C.CASEID), RC.RELATIONSHIPNO) AS RowNumber,
					RC.CASEID, 
					RC.RELATIONSHIP,
					coalesce(RC.RELATEDCASEID, C.CASEID) as RELATEDCASEID
				From EDECASEMATCH M
				join #TEMPCASEMATCH TM	  on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
				join RELATEDCASE RC	  on (RC.CASEID=M.DRAFTCASEID)
				left join OFFICIALNUMBERS O on (O.OFFICIALNUMBER=RC.OFFICIALNUMBER
							    and RC.RELATEDCASEID is null)
				left join CASES C	    on (C.CASEID=O.CASEID
							    and C.COUNTRYCODE=RC.COUNTRYCODE)
				join CASERELATION CR	    on (CR.RELATIONSHIP=RC.RELATIONSHIP)
				left join CASEEVENT CE      on (CE.CASEID   =C.CASEID
							    and CE.EVENTNO  =CR.FROMEVENTNO
							    and CE.CYCLE    =1)
				where M.BATCHNO = @pnBatchNo
				and (RC.RELATEDCASEID is not null OR C.CASEID is not null)
				and (CE.EVENTDATE=RC.PRIORITYDATE OR RC.PRIORITYDATE is null OR CE.CASEID is null)
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
			-- for the related case just inserted
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

			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int',
							  @pnBatchNo=@pnBatchNo
		End

		---------------------------
		-- Check that all of the 
		-- designated countries are
		-- valid and report a comma
		-- separated list of the
		-- invalid countries.
		---------------------------
	
		If @nErrorCode=0
		Begin
			Set @nIssueNo = -29
	
			Set @sSQLString="
			with InvalidCountry 
			as (	select distinct C.BATCHNO, C.TRANSACTIONIDENTIFIER, 
				SUBSTRING( (select distinct ', '+DC.DESIGNATEDCOUNTRYCODE as [text()]
					    from EDEDESIGNATEDCOUNTRYDETAILS DC
					    left join COUNTRYGROUP CG on (CG.TREATYCODE=CS.COUNTRYCODE
								      and CG.MEMBERCOUNTRY=DC.DESIGNATEDCOUNTRYCODE_T
								      and isnull(CG.DATECOMMENCED,getdate())<=getdate()
								      and isnull(CG.DATECEASED,   getdate())>=getdate())
					    Where DC.BATCHNO=C.BATCHNO
					    and   DC.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER
					    and   CG.TREATYCODE is null
					    For XML PATH ('') ),
					    2, 254) as [Countries]
				from EDECASEMATCH C
				join (select distinct BATCHNO, TRANSACTIONIDENTIFIER
				      from EDEDESIGNATEDCOUNTRYDETAILS
				      where DESIGNATEDCOUNTRYCODE_T is not null) DC1 on (DC1.BATCHNO=C.BATCHNO
										     and DC1.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
				join CASES CS on (CS.CASEID=C.DRAFTCASEID)
				)
			Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED, ISSUETEXT)
			Select @nIssueNo, C.BATCHNO, C.TRANSACTIONIDENTIFIER, getdate(), IC.Countries
			from EDECASEMATCH C
			join CASES CS			 on (CS.CASEID=C.DRAFTCASEID)
			join #TEMPCASEMATCH TM		 on (TM.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			join InvalidCountry IC		 on (IC.BATCHNO=C.BATCHNO
							 and IC.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			left join EDEOUTSTANDINGISSUES I on (I.ISSUEID=@nIssueNo
							 and I.BATCHNO=C.BATCHNO
							 and I.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			where C.BATCHNO=@pnBatchNo
			and I.ISSUEID is null
			-- If there are one or more Designated Countries specified that are not a valid
			-- member of the group country then raise the issue, and report the invalid Countries
			and IC.Countries is not null"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int,
						  @nIssueNo	int',
						  @pnBatchNo=@pnBatchNo,
						  @nIssueNo =@nIssueNo
		End
	
		-----------------------------
		-- Load RELATEDCASE details
		-- with Designated Countries
		-- if none have been rejected
		-----------------------------
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Insert into RELATEDCASE(CASEID, RELATIONSHIPNO, RELATIONSHIP, COUNTRYCODE)
			Select distinct M.DRAFTCASEID, 
					
					(select count(*)
					 From EDEDESIGNATEDCOUNTRYDETAILS DC1 
					 where DC1.BATCHNO=DC.BATCHNO
					 and   DC1.TRANSACTIONIDENTIFIER=DC.TRANSACTIONIDENTIFIER
					 and   DC1.DESIGNATEDCOUNTRYCODE_T<DC.DESIGNATEDCOUNTRYCODE_T
					) + isnull(RC.RELCOUNT,-1) + 1,
					'DC1', 
					CT.COUNTRYCODE
			From EDECASEMATCH M
			join #TEMPCASEMATCH TM		    	on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join EDEDESIGNATEDCOUNTRYDETAILS DC	on (DC.BATCHNO=M.BATCHNO
								and DC.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join COUNTRY CT		 		on (CT.COUNTRYCODE=DC.DESIGNATEDCOUNTRYCODE_T)
			left join (select CASEID, max(RELATIONSHIPNO) as RELCOUNT
				   from RELATEDCASE
				   group by CASEID) RC		on (RC.CASEID=M.DRAFTCASEID)
			-- ensure that no designated countries
			-- were rejected
			left join EDEOUTSTANDINGISSUES I	on (I.ISSUEID=-29
								and I.BATCHNO=M.BATCHNO
								and I.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			left join RELATEDCASE RC1		on (RC1.CASEID=M.DRAFTCASEID
								and RC1.RELATIONSHIP='DC1'
								and RC1.COUNTRYCODE=CT.COUNTRYCODE)
			Where M.BATCHNO=@pnBatchNo
			and M.DRAFTCASEID is not null
			and I.BATCHNO is null
			and RC1.CASEID is null"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End
		
		--------------------------
		-- Load CASEEVENT details
		-- from RelatedCase
		--------------------------
	
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Insert into CASEEVENT(CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG)
			select RC.CASEID, CR.EVENTNO,1, min(RC.PRIORITYDATE), 1
			From EDECASEMATCH M
			join #TEMPCASEMATCH TM	on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join RELATEDCASE RC	on (RC.CASEID=M.DRAFTCASEID)
			join CASERELATION CR	on (CR.RELATIONSHIP=RC.RELATIONSHIP)
			left join CASEEVENT CE	on (CE.CASEID=RC.CASEID
						and CE.EVENTNO=CR.EVENTNO
						and CE.CYCLE=1)
			Where M.BATCHNO=@pnBatchNo
			and CR.EVENTNO is not null
			and RC.PRIORITYDATE is not null
			and CE.CASEID is null
			group by RC.CASEID, CR.EVENTNO"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End	

		--------------------------
		-- Update CASEEVENT for :
		--  Date Last Change (-14)
		--  Instructions Received (-16)
		--  Date of Entry (-13)
		--  Date Last Change (-14)
		-------------------------------
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Insert into CASEEVENT(CASEID, EVENTNO, CYCLE, EVENTDATE, EVENTDUEDATE, OCCURREDFLAG, DATEDUESAVED, EVENTTEXT)
			Select	M.DRAFTCASEID, 
				E.DRAFTEVENTNO,
				1, 
				convert(nvarchar,getdate(),112),
				NULL, 
				1,
				0,
				NULL
			From EDECASEMATCH M
			join #TEMPCASEMATCH TM	on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join EVENTS E on (E.EVENTNO in (-16,-14,-13))
			left join CASEEVENT CE	on (CE.CASEID=M.DRAFTCASEID
						and CE.CYCLE =1
						and CE.EVENTNO=E.DRAFTEVENTNO)
			Where M.BATCHNO=@pnBatchNo
			and M.DRAFTCASEID  is not null
			and E.DRAFTEVENTNO is not null
			and CE.CASEID      is null
			UNION ALL
			Select	M.DRAFTCASEID, 
				E.EVENTNO, 
				1, 
				convert(nvarchar,getdate(),112),
				NULL, 
				1,
				0,
				NULL
			From EDECASEMATCH M
			join #TEMPCASEMATCH TM	on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join EVENTS E on (E.EVENTNO in (-16,-14,-13))
			left join CASEEVENT CE	on (CE.CASEID=M.DRAFTCASEID
						and CE.CYCLE =1
						and CE.EVENTNO=E.EVENTNO)
			Where M.BATCHNO=@pnBatchNo
			and M.DRAFTCASEID  is not null
			and E.DRAFTEVENTNO is null
			and CE.CASEID      is null"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End
	
		--------------------------
		-- Load OPENACTION details
		--------------------------
		
		If  @sRequestType in ('Data Input','Data Verification','Extract Cases Response','Case Import','Agent Input')
		Begin
			-------------------------
			-- Get the ACTION to Open
			-------------------------
			------------------------------------------------------------
			-- To determine the Action to open as the default for each 
			-- Case, we will use a default Case Program and locate the
			-- screen control rule that indicates the Action to open.
			-- First attempt to get the ACTION using the Web screen 
			-- rules before dropping back to client/server rules.
			-- NOTE : The ACTUALCASETYPE associated with the draft
			--        case type will be used and not the draft case type
			------------------------------------------------------------
			If @nErrorCode=0
			and @bUseWebScreen=1
			Begin
				-------------------------------------
				-- Use the screen definition rules
				-- for the web screens to find Action
				-------------------------------------
				Set @sSQLString="
				Update #TEMPCASEMATCH
				Set CREATEACTION=TD.FILTERVALUE
				From #TEMPCASEMATCH T
				-- Get the screen control criteria 
				join (	Select 	M.TRANSACTIONIDENTIFIER,
						convert(int,
						substring(
						max (
						CASE WHEN (C.CASEOFFICEID    IS NULL)	THEN '0' ELSE '1' END +
						CASE WHEN (C.CASETYPE        IS NULL)	THEN '0' ELSE '1' END +  
						CASE WHEN (C.PROPERTYTYPE    IS NULL)	THEN '0' ELSE '1' END +    			
						CASE WHEN (C.COUNTRYCODE     IS NULL)	THEN '0' ELSE '1' END +
						CASE WHEN (C.CASECATEGORY    IS NULL)	THEN '0' ELSE '1' END +
						CASE WHEN (C.SUBTYPE         IS NULL)	THEN '0' ELSE '1' END +
						CASE WHEN (C.BASIS           IS NULL)	THEN '0' ELSE '1' END +
						CASE WHEN (C.USERDEFINEDRULE IS NULL
							OR C.USERDEFINEDRULE = 0)	THEN '0' ELSE '1' END +
						convert(varchar,C.CRITERIANO)), 9,20)) as CRITERIANO
					From CRITERIA C
					     join EDECASEMATCH M on (M.BATCHNO=@pnBatchNo)
					     join CASES CS	 on (CS.CASEID=M.DRAFTCASEID)
					     join CASETYPE CT	 on (CT.CASETYPE=CS.CASETYPE)
					left join PROPERTY P	 on (P.CASEID =M.DRAFTCASEID)
					Where	C.RULEINUSE		= 1  	
					AND	C.PURPOSECODE		= 'W'	-- Web Screen Definitions
					AND 	C.PROGRAMID		= @sProgramId
					AND (	C.CASEOFFICEID 		= CS.OFFICEID 		OR C.CASEOFFICEID 	IS NULL )
					AND (	C.CASETYPE		= CT.ACTUALCASETYPE	OR C.CASETYPE		IS NULL )
					AND (	C.PROPERTYTYPE 		= CS.PROPERTYTYPE 	OR C.PROPERTYTYPE 	IS NULL ) 
					AND (	C.COUNTRYCODE 		= CS.COUNTRYCODE 	OR C.COUNTRYCODE 	IS NULL ) 
					AND (	C.CASECATEGORY 		= CS.CASECATEGORY 	OR C.CASECATEGORY 	IS NULL ) 
					AND (	C.SUBTYPE 		= CS.SUBTYPE 		OR C.SUBTYPE 		IS NULL ) 
					AND (	C.BASIS 		= P.BASIS 		OR C.BASIS 		IS NULL ) 	
					-- Since this is an existing case, all criteria are known
					AND (	C.PROPERTYUNKNOWN	= 0 			OR C.PROPERTYUNKNOWN 	IS NULL )
					AND (	C.COUNTRYUNKNOWN	= 0 			OR C.COUNTRYUNKNOWN 	IS NULL )
					AND (	C.CATEGORYUNKNOWN	= 0 			OR C.CATEGORYUNKNOWN 	IS NULL )
					AND (	C.SUBTYPEUNKNOWN	= 0 			OR C.SUBTYPEUNKNOWN 	IS NULL )
					Group By M.TRANSACTIONIDENTIFIER ) CR	on (CR.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
				join TOPICDEFAULTSETTINGS TD on (TD.CRITERIANO=CR.CRITERIANO
							     and TD.TOPICNAME ='Actions_Component'
							     and TD.FILTERNAME='NewCaseAction')
				where TD.FILTERVALUE is not null"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int,
							  @sProgramId	nvarchar(8)',
							  @pnBatchNo=@pnBatchNo,
							  @sProgramId=@sProgramId
			End

			If @nErrorCode=0
			and exists(select 1 from #TEMPCASEMATCH where CREATEACTION is null)
			and @sProgramId is not null
			Begin
				-------------------------------------
				-- Use the c/s screen control rules
				-- if the Action is still not set.
				-------------------------------------
				Set @sSQLString="
				Update T
				Set CREATEACTION=SC.CREATEACTION
				From #TEMPCASEMATCH T
				-- Get the screen control criteria 
				join (	Select 	M.TRANSACTIONIDENTIFIER,
						convert(int,
						substring(
						max (
						CASE WHEN (C.CASEOFFICEID    IS NULL)	THEN '0' ELSE '1' END +
						CASE WHEN (C.CASETYPE        IS NULL)	THEN '0' ELSE '1' END +  
						CASE WHEN (C.PROPERTYTYPE    IS NULL)	THEN '0' ELSE '1' END +    			
						CASE WHEN (C.COUNTRYCODE     IS NULL)	THEN '0' ELSE '1' END +
						CASE WHEN (C.CASECATEGORY    IS NULL)	THEN '0' ELSE '1' END +
						CASE WHEN (C.SUBTYPE         IS NULL)	THEN '0' ELSE '1' END +
						CASE WHEN (C.BASIS           IS NULL)	THEN '0' ELSE '1' END +
						CASE WHEN (C.USERDEFINEDRULE IS NULL
							OR C.USERDEFINEDRULE = 0)	THEN '0' ELSE '1' END +
						convert(varchar,C.CRITERIANO)), 9,20)) as CRITERIANO
					From CRITERIA C
					     join EDECASEMATCH M on (M.BATCHNO=@pnBatchNo)
					     join CASES CS	 on (CS.CASEID=M.DRAFTCASEID)
					     join CASETYPE CT	 on (CT.CASETYPE=CS.CASETYPE)
					left join PROPERTY P	 on (P.CASEID =M.DRAFTCASEID)
					Where	C.RULEINUSE		= 1  	
					AND	C.PURPOSECODE		= 'S'	-- Client/server Screen Control
					AND 	C.PROGRAMID		= @sProgramId
					AND (	C.CASEOFFICEID 		= CS.OFFICEID 		OR C.CASEOFFICEID 	IS NULL )
					AND (	C.CASETYPE		= CT.ACTUALCASETYPE	OR C.CASETYPE		IS NULL )
					AND (	C.PROPERTYTYPE 		= CS.PROPERTYTYPE 	OR C.PROPERTYTYPE 	IS NULL ) 
					AND (	C.COUNTRYCODE 		= CS.COUNTRYCODE 	OR C.COUNTRYCODE 	IS NULL ) 
					AND (	C.CASECATEGORY 		= CS.CASECATEGORY 	OR C.CASECATEGORY 	IS NULL ) 
					AND (	C.SUBTYPE 		= CS.SUBTYPE 		OR C.SUBTYPE 		IS NULL ) 
					AND (	C.BASIS 		= P.BASIS 		OR C.BASIS 		IS NULL ) 	
					-- Since this is an existing case, all criteria are known
					AND (	C.PROPERTYUNKNOWN	= 0 			OR C.PROPERTYUNKNOWN 	IS NULL )
					AND (	C.COUNTRYUNKNOWN	= 0 			OR C.COUNTRYUNKNOWN 	IS NULL )
					AND (	C.CATEGORYUNKNOWN	= 0 			OR C.CATEGORYUNKNOWN 	IS NULL )
					AND (	C.SUBTYPEUNKNOWN	= 0 			OR C.SUBTYPEUNKNOWN 	IS NULL )
					Group By M.TRANSACTIONIDENTIFIER ) CR	on (CR.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
				join SCREENCONTROL SC	on (SC.CRITERIANO=CR.CRITERIANO)
				where SC.SCREENNAME='frmCaseHistory'
				and SC.CREATEACTION is not null
				and  T.CREATEACTION is null"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int,
							  @sProgramId	nvarchar(8)',
							  @pnBatchNo=@pnBatchNo,
							  @sProgramId=@sProgramId
			End
		
			If @nErrorCode=0
			Begin
				----------------------------------------------------
				-- Create OpenActions against the Cases in the batch
				----------------------------------------------------
				Set @sSQLString="
				Insert into OPENACTION(CASEID, ACTION, CYCLE, POLICEEVENTS, DATEENTERED, DATEUPDATED)
				Select distinct M.DRAFTCASEID, T.CREATEACTION, 1, 1, getdate(), getdate()
				From EDECASEMATCH M
				join #TEMPCASEMATCH T	on (T.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
				left join OPENACTION OA	on (OA.CASEID=M.DRAFTCASEID
							and OA.ACTION=T.CREATEACTION)
				Where M.BATCHNO=@pnBatchNo
				and M.DRAFTCASEID  is not null
				and T.CREATEACTION is not null
				and OA.CASEID is null"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int',
							  @pnBatchNo=@pnBatchNo
				
				Set @nOpenActionCount=@@rowcount
			End
		
			If @nOpenActionCount>0
			and @bPolicingNotRequired=0
			Begin			
				-----------
				-- Policing
				-----------

				If @nErrorCode=0
				Begin
					----------------------------------------------------------------
					-- Load a Policing row for each Open Action to be processed
					----------------------------------------------------------------
					Set @sSQLString="
					insert into #TEMPPOLICING (CASEID, ACTION, EVENTNO, CYCLE, TYPEOFREQUEST)
					Select OA.CASEID, OA.ACTION, NULL, 1, 1
					From EDECASEMATCH M
					join #TEMPCASEMATCH T	on (T.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
					join OPENACTION OA	on (OA.CASEID=M.DRAFTCASEID
								and OA.ACTION=T.CREATEACTION)
					Where M.BATCHNO=@pnBatchNo"
			
					Exec @nErrorCode=sp_executesql @sSQLString,
								N'@pnBatchNo	int',
								  @pnBatchNo=@pnBatchNo

					Set @nPolicingCount=@@Rowcount
				End
				
				If  @nErrorCode=0
				and @pbPoliceImmediately=1
				and @nPolicingCount>0
				Begin	
					---------------------------------------------------------------------------
					-- If the Police Immediately option is on then attach a unique Batch Number
					-- for all entries so that they can be recalculated at the one time. Also
					-- set the On Hold Flag on so that the Policing Server does not pick up
					-- these requests
					---------------------------------------------------------------------------
			
					------------------------------------------------------
					-- Get the Batchnumber to use for Police Immediately
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
			
				If  @nErrorCode=0
				and @nPolicingCount>0
				Begin
					----------------------------------------------------------------
					-- Now load live Policing table with generated sequence no
					----------------------------------------------------------------
					Set @sSQLString="
					insert into POLICING (DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, 
						 	      ONHOLDFLAG, ACTION, CASEID, EVENTNO, CYCLE, TYPEOFREQUEST, BATCHNO, SQLUSER, IDENTITYID)
					select	getdate(), 
						T.SEQUENCENO, 
						'EDE0-'+convert(varchar, getdate(),126)+convert(varchar,T.SEQUENCENO),
						1,
						isnull(@pbPoliceImmediately, 0),
						T.ACTION, 
						T.CASEID, 
						T.EVENTNO,
						T.CYCLE, 
						T.TYPEOFREQUEST, 
						@nPoliceBatchNo, 
						substring(SYSTEM_USER,1,60), 
						@pnUserIdentityId
					from #TEMPPOLICING T

					delete from #TEMPPOLICING"
			
					Exec @nErrorCode=sp_executesql @sSQLString,
								N'@pnUserIdentityId	int,
								  @nPoliceBatchNo	int,
								  @pbPoliceImmediately	bit',
								  @pnUserIdentityId   =@pnUserIdentityId,
								  @nPoliceBatchNo     =@nPoliceBatchNo,
								  @pbPoliceImmediately=@pbPoliceImmediately

					Set @nPolicingCount=0
				End
			End
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

	
	-------------------------------------
	-- Generate the IRN for new Cases
	-------------------------------------
	-- Moved down in the code to allow
	-- Names to be loaded against Case
	-- as this can impact IRN generation.
	-------------------------------------
	
	If  @nErrorCode=0
	Begin
		Set @nTranCountStart = @@TranCount
		BEGIN TRANSACTION
	
		------------------------------------------------------------------
		-- Generate the IRN of Draft Cases already attached to a Live Case
		-- by adding a SequenceNo (zero padded) to the Live Case IRN.
		------------------------------------------------------------------
		Set @sSQLString="
		Update CASES
		Set IRN=C1.IRN + CASE WHEN(M.SEQUENCENO<10) THEN '0' ELSE '' END + convert(varchar, M.SEQUENCENO)
		from CASES C
		join EDECASEMATCH M on (M.DRAFTCASEID=C.CASEID)
		-- Derived table on CASES has to be used to avoid
		-- an ambiguous table error
		join (	select CASEID, IRN
			from CASES C
			where C.IRN is not null) C1 on (C1.CASEID=M.LIVECASEID)
		where M.BATCHNO=@pnBatchNo
		and M.MATCHLEVEL in (3254,3253)
		and len(C1.IRN)<=28 -- to ensure a truncation error does not occur
		and C.IRN='<Generate Reference>'"
	
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo	int',
					  @pnBatchNo=@pnBatchNo
	
		----------------------------------------------------------------------------
		-- Any CASES that have been created as a result of loading this batch will
		-- now require the IRN to be generated.
		----------------------------------------------------------------------------
	
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @nCaseId=min(C.CASEID)
			from EDECASEMATCH M
			join CASES C on (C.CASEID=M.DRAFTCASEID)
			Where M.BATCHNO=@pnBatchNo
			and C.IRN='<Generate Reference>'"
			
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@nCaseId	int	OUTPUT,
							  @pnBatchNo	int',
							  @nCaseId  =@nCaseId	OUTPUT,
							  @pnBatchNo=@pnBatchNo
		End
	
		While @nCaseId is not null
		and @nErrorCode=0
		Begin
			-------------------------------------------------------------
			-- Call a stored procedure to get the IRN to use for the Case
			-- The procedure will actually update the CASES row.
			-------------------------------------------------------------
			Set @sIRN=null
			Begin try
				exec dbo.cs_ApplyGeneratedReference
							@psCaseReference =@sIRN	OUTPUT,
							@pnUserIdentityId=@pnUserIdentityId,
							@psCulture	 =@psCulture,
							@pnCaseKey	 =@nCaseId
			End try
			Begin catch
				Set @nErrorCode=@@ERROR
				
				If @nErrorCode=50000
				Begin
					----------------------------
					-- If IRN failed to generate
					-- raise an issue
					----------------------------
					Set @nIssueNo = -27
			
					Set @sSQLString="
					Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED)
					Select @nIssueNo, C.BATCHNO, C.TRANSACTIONIDENTIFIER, getdate()
					from EDECASEMATCH C
					left join EDEOUTSTANDINGISSUES I on (I.ISSUEID=@nIssueNo
									 and I.BATCHNO=C.BATCHNO
									 and I.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
					where C.BATCHNO=@pnBatchNo
					and C.DRAFTCASEID=@nCaseId
					and I.ISSUEID is null"
			
					exec @nErrorCode=sp_executesql @sSQLString,
								N'@pnBatchNo	int,
								  @nIssueNo	int,
								  @nCaseId	int',
								  @pnBatchNo=@pnBatchNo,
								  @nIssueNo =@nIssueNo,
								  @nCaseId  =@nCaseId
				End
			End catch
	
			------------------------------------------------
			-- Get the next CASEID that does not have an IRN
			-- and was created in the current batch
			------------------------------------------------
	
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Select @nCaseId=min(C.CASEID)
				from EDECASEMATCH M
				join CASES C on (C.CASEID=M.DRAFTCASEID)
				Where M.BATCHNO=@pnBatchNo
				and C.CASEID>@nCaseId
				and C.IRN='<Generate Reference>'"
				
				exec @nErrorCode=sp_executesql @sSQLString,
								N'@nCaseId	int	OUTPUT,
								  @pnBatchNo	int',
								  @nCaseId  =@nCaseId	OUTPUT,
								  @pnBatchNo=@pnBatchNo
			End
		End
	
		-- Commit entire transaction if successful
		If @@TranCount > @nTranCountStart
		Begin
			If @nErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
	End

	-----------------------------------------
	-- Run Policing to process Open Actions
	-- if the Police Immediately option has 
	-- been set.
	-- Policing manages its own database
	-- transactions.
	-----------------------------------------

	If  @nErrorCode=0
	and @pbPoliceImmediately=1
	and @bPolicingNotRequired=0
	and @nPoliceBatchNo is not null
	and @sRequestType in ('Data Input','Data Verification','Extract Cases Response','Case Import','Agent Input')
	Begin
		----------------------------------------------
		-- NOTE : The Policing of Open Action requests
		--        must occur before the imported Event
		--        dates are loaded against the Draft
		--        Case. This is to mimic what would 
		--        occur if the Case was manually 
		--        entered via the Case program.	
		----------------------------------------------
		exec @nErrorCode=dbo.ipu_Policing
					@pnBatchNo=@nPoliceBatchNo,
					@pnUserIdentityId=@pnUserIdentityId,
					@pnEDEBatchNo=@pnBatchNo
	
		--------------------------------------------------------------
		-- Reload the common area accessible from the database server
		-- with the previously generated TransactionNo as it may have
		-- been reset by Policing. This will be used by the audit logs.
		--------------------------------------------------------------
	
		set @bHexNumber=substring(cast(isnull(@pnUserIdentityId,'') as varbinary),1,4) + 
				substring(cast(isnull(@nTransNo,'') as varbinary),1,4)+ 
				substring(cast(isnull(@pnBatchNo,'') as varbinary),1,4) +
				substring(cast(isnull(@nOfficeID,'') as varbinary),1,4) +
				substring(cast(isnull(@nLogMinutes,'') as varbinary),1,4)
		SET CONTEXT_INFO @bHexNumber
	End

	If @nErrorCode=0
	Begin
		---------------------------------------------------
		-- For performance reasons set any EDEDEVENTDETAILS
		-- rows that have not been given a cycle to 1.
		---------------------------------------------------

		-----------------------------
		-- SQA19637
		-----------------------------
		-- If the EVENT only allows 1 
		-- cycle then set to 1.
		-----------------------------
		Set @sSQLString="
		Update ED
		set EVENTCYCLE=1
		From EDEEVENTDETAILS ED
		join #TEMPCASEMATCH TM	on (TM.TRANSACTIONIDENTIFIER=ED.TRANSACTIONIDENTIFIER)
		join EVENTS E		on (E.EVENTNO=ED.EVENTCODE_T)
		where ED.BATCHNO=@pnBatchNo
		and ED.EVENTCYCLE is null
		and isnull(E.NUMCYCLESALLOWED,1)=1"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo=@pnBatchNo

		If @nErrorCode=0
		Begin
			---------------------------------
			-- If the EVENT allows multiple
			-- cycles and has a controlling
			-- action that is cyclic then use
			-- the cycle of the lowest Open
			-- Action.
			---------------------------------
			Set @sSQLString="
			Update ED
			set EVENTCYCLE=isnull(OA.CYCLE,1)
			From EDEEVENTDETAILS ED
			join EVENTS E  on (E.EVENTNO=ED.EVENTCODE_T)
			join ACTIONS A on (A.ACTION =E.CONTROLLINGACTION)
			join #TEMPCASEMATCH TM	on (TM.TRANSACTIONIDENTIFIER=ED.TRANSACTIONIDENTIFIER)
			left join (	select CASEID, ACTION, min(CYCLE) as CYCLE
					from OPENACTION
					Where POLICEEVENTS=1
					group by CASEID, ACTION) OA
						on (OA.CASEID=isnull(TM.LIVECASEID,TM.DRAFTCASEID)
						and OA.ACTION=A.ACTION)
			where ED.BATCHNO=@pnBatchNo
			and ED.EVENTCYCLE is null
			and E.NUMCYCLESALLOWED>1"

			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
		End

		If @nErrorCode=0
		Begin
			---------------------------------
			-- If the EVENT allows multiple
			-- cycles and has still not been
			-- set then increment the highest
			-- cycle for that Event on the
			-- live case.
			---------------------------------
			Set @sSQLString="
			Update ED
			set EVENTCYCLE=isnull(CE.CYCLE,0)+1
			From EDEEVENTDETAILS ED
			join EVENTS E  on (E.EVENTNO=ED.EVENTCODE_T)
			join #TEMPCASEMATCH TM	on (TM.TRANSACTIONIDENTIFIER=ED.TRANSACTIONIDENTIFIER)
			left join (	select CASEID, EVENTNO, max(CYCLE) as CYCLE
					from CASEEVENT
					group by CASEID, EVENTNO) CE
						on (CE.CASEID =TM.LIVECASEID
						and CE.EVENTNO=E.EVENTNO)
			where ED.BATCHNO=@pnBatchNo
			and ED.EVENTCYCLE is null
			and E.NUMCYCLESALLOWED>1"

			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
		End
	End
		
	--------------------------
	-- Load CASEEVENT details
	--------------------------

	If @nErrorCode=0
	Begin
		-- Start a new transaction
		Select @nTranCountStart = @@TranCount
		BEGIN TRANSACTION
		
		----------------------------------------------------------
		-- SQA17937 
		-- Allow Events that exist on the draft Case to be updated
		-- from the imported Event.
		-- Using DRAFTEVENTNO
		----------------------------------------------------------
		Set @sSQLString="
		Update CE
		Set EVENTDATE   =CASE WHEN(ED.EVENTDUEDATE is null and ED.EVENTDATE>getdate()) THEN NULL ELSE convert(nvarchar,ED.EVENTDATE,112) END,
		    EVENTDUEDATE=CASE WHEN(ED.EVENTDUEDATE is not null) THEN convert(nvarchar,ED.EVENTDUEDATE,112)
				      WHEN(ED.EVENTDATE>getdate())      THEN convert(nvarchar,ED.EVENTDATE,112)
								        ELSE NULL
				 END,
		    OCCURREDFLAG=CASE WHEN(ED.EVENTDATE is null) THEN 0
				      WHEN(ED.EVENTDATE > getdate() and ED.EVENTDUEDATE is null) THEN 0
				      ELSE 1
				 END, 
		    DATEDUESAVED=CASE WHEN(ED.EVENTDATE is null) THEN 1
				      WHEN(ED.EVENTDATE > getdate() and ED.EVENTDUEDATE is null) THEN 1
				      ELSE 0
				 END, 
		    EVENTTEXT   =ED.EVENTTEXT
		From EDECASEMATCH M
		join #TEMPCASEMATCH TM	on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
		join EDEEVENTDETAILS ED	on (ED.BATCHNO=M.BATCHNO
					and ED.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
		join EVENTS E		on (E.EVENTNO=ED.EVENTCODE_T)
		join CASEEVENT CE	on (CE.CASEID=M.DRAFTCASEID
					and CE.CYCLE =ED.EVENTCYCLE
					and CE.EVENTNO=E.DRAFTEVENTNO)
		Where M.BATCHNO=@pnBatchNo
		and M.DRAFTCASEID is not null
		and ED.ASSOCCASESEQ                   is null
		and ED.ASSOCIATEDCASERELATIONSHIPCODE is null
		and ED.ASSOCIATEDCASECOUNTRYCODE      is null
		and(ED.EVENTDATE is not null OR ED.EVENTDUEDATE is not null)"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo	int',
					  @pnBatchNo=@pnBatchNo

		Set @nCaseEventCount=@@Rowcount
	End

	If @nErrorCode=0
	Begin		
		----------------------------------------------------------
		-- SQA17937 
		-- Allow Events that exist on the draft Case to be updated
		-- from the imported Event.
		-- Where Event not linked to Draft Event.
		----------------------------------------------------------
		Set @sSQLString="
		Update CE
		Set EVENTDATE   =CASE WHEN(ED.EVENTDUEDATE is null and ED.EVENTDATE>getdate()) THEN NULL ELSE convert(nvarchar,ED.EVENTDATE,112) END,
		    EVENTDUEDATE=CASE WHEN(ED.EVENTDUEDATE is not null) THEN convert(nvarchar,ED.EVENTDUEDATE,112)
				      WHEN(ED.EVENTDATE>getdate())      THEN convert(nvarchar,ED.EVENTDATE,112)
								        ELSE NULL
				 END,
		    OCCURREDFLAG=CASE WHEN(ED.EVENTDATE is null) THEN 0
				      WHEN(ED.EVENTDATE > getdate() and ED.EVENTDUEDATE is null) THEN 0
				      ELSE 1
				 END, 
		    DATEDUESAVED=CASE WHEN(ED.EVENTDATE is null) THEN 1
				      WHEN(ED.EVENTDATE > getdate() and ED.EVENTDUEDATE is null) THEN 1
				      ELSE 0
				 END, 
		    EVENTTEXT   =ED.EVENTTEXT
		From EDECASEMATCH M
		join #TEMPCASEMATCH TM	on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
		join EDEEVENTDETAILS ED	on (ED.BATCHNO=M.BATCHNO
					and ED.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
		join EVENTS E		on (E.EVENTNO=ED.EVENTCODE_T)
		join CASEEVENT CE	on (CE.CASEID=M.DRAFTCASEID
					and CE.CYCLE =ED.EVENTCYCLE
					and CE.EVENTNO=E.EVENTNO)
		Where M.BATCHNO=@pnBatchNo
		and M.DRAFTCASEID  is not null
		and E.DRAFTEVENTNO is null
		and ED.ASSOCCASESEQ                   is null
		and ED.ASSOCIATEDCASERELATIONSHIPCODE is null
		and ED.ASSOCIATEDCASECOUNTRYCODE      is null
		and(ED.EVENTDATE is not null OR ED.EVENTDUEDATE is not null)"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo	int',
					  @pnBatchNo=@pnBatchNo

		Set @nCaseEventCount=@nCaseEventCount+@@Rowcount
	End
	
	If @nErrorCode=0
	and @nUpdateEventNo is not NULL
	Begin		
		-----------------------------------------------------
		-- SQA16184
		-- Allow Event associated to the EDEREQUESTTYPE to be
		-- updated as todays date.
		-----------------------------------------------------
		Set @sSQLString="
		Update CE
		Set EVENTDATE   =convert(nvarchar,getdate(),112),
		    EVENTDUEDATE=NULL,
		    OCCURREDFLAG=1, 
		    DATEDUESAVED=0
		From EDECASEMATCH M
		join #TEMPCASEMATCH TM	on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
		join CASEEVENT CE	on (CE.CASEID=CASE WHEN (M.MATCHLEVEL=3254 and M.LIVECASEID is not null) THEN M.LIVECASEID ELSE M.DRAFTCASEID END
					and CE.CYCLE =1
					and CE.EVENTNO=@nUpdateEventNo)
		Where M.BATCHNO=@pnBatchNo
		and ((M.MATCHLEVEL=3254 and M.LIVECASEID is not null) OR M.DRAFTCASEID is not null)
		and(CE.EVENTDATE<>convert(nvarchar,getdate(),112) OR CE.EVENTDATE is null)"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int,
					  @nUpdateEventNo	int',
					  @pnBatchNo     =@pnBatchNo,
					  @nUpdateEventNo=@nUpdateEventNo

		Set @nCaseEventCount=@nCaseEventCount+@@Rowcount
	End
	
	If @nErrorCode=0
	and @nUpdateEventNo is not NULL
	Begin		
		-----------------------------------------------------
		-- SQA16184
		-- Allow Event associated to the EDEREQUESTTYPE to be
		-- inserted as todays date if it does not exist.
		-----------------------------------------------------
		Set @sSQLString="
		Insert into CASEEVENT(CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG, DATEDUESAVED)
		Select	CASE WHEN (M.MATCHLEVEL=3254 and M.LIVECASEID is not null) THEN M.LIVECASEID ELSE M.DRAFTCASEID END, 
			@nUpdateEventNo, 
			1, 
			convert(nvarchar,getdate(),112),
			1,
			0
		From EDECASEMATCH M
		join #TEMPCASEMATCH TM	on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
		left join CASEEVENT CE	on (CE.CASEID=CASE WHEN (M.MATCHLEVEL=3254 and M.LIVECASEID is not null) THEN M.LIVECASEID ELSE M.DRAFTCASEID END
					and CE.CYCLE =1
					and CE.EVENTNO=@nUpdateEventNo)
		Where M.BATCHNO=@pnBatchNo
		and ((M.MATCHLEVEL=3254 and M.LIVECASEID is not null) OR M.DRAFTCASEID is not null)
		and CE.CASEID is null"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int,
					  @nUpdateEventNo	int',
					  @pnBatchNo     =@pnBatchNo,
					  @nUpdateEventNo=@nUpdateEventNo

		Set @nCaseEventCount=@nCaseEventCount+@@Rowcount
	End

	If @nErrorCode=0
	Begin
		-------------------------------------------------
		-- Load Events that have been imported and do not
		-- already exist against the draft Case.
		-- Using DRAFTEVENTNO
		-------------------------------------------------
		Set @sSQLString="
		Insert into CASEEVENT(CASEID, EVENTNO, CYCLE, EVENTDATE, EVENTDUEDATE, OCCURREDFLAG, DATEDUESAVED, EVENTTEXT)
		Select	M.DRAFTCASEID, 
			E.DRAFTEVENTNO, 
			ED.EVENTCYCLE, 
			CASE WHEN(ED.EVENTDUEDATE is null and ED.EVENTDATE>getdate()) THEN NULL ELSE convert(nvarchar,ED.EVENTDATE,112) END,
			CASE WHEN(ED.EVENTDUEDATE is not null) THEN convert(nvarchar,ED.EVENTDUEDATE,112)
			     WHEN(ED.EVENTDATE>getdate())      THEN convert(nvarchar,ED.EVENTDATE,112)
							       ELSE NULL
			END,
			CASE WHEN(ED.EVENTDATE is null) THEN 0
			     WHEN(ED.EVENTDATE > getdate() and ED.EVENTDUEDATE is null) THEN 0
			     ELSE 1
			END, 
			CASE WHEN(ED.EVENTDATE is null) THEN 1
			     WHEN(ED.EVENTDATE > getdate() and ED.EVENTDUEDATE is null) THEN 1
			     ELSE 0
			END, 
			ED.EVENTTEXT
		From EDECASEMATCH M
		join #TEMPCASEMATCH TM	on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
		join EDEEVENTDETAILS ED	on (ED.BATCHNO=M.BATCHNO
					and ED.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
		join EVENTS E		on (E.EVENTNO=ED.EVENTCODE_T)
		left join CASEEVENT CE	on (CE.CASEID=M.DRAFTCASEID
					and CE.CYCLE =ED.EVENTCYCLE
					and CE.EVENTNO=E.DRAFTEVENTNO)
		Where M.BATCHNO=@pnBatchNo
		and M.DRAFTCASEID  is not null
		and E.DRAFTEVENTNO is not null
		and CE.CASEID      is null
		and ED.ASSOCCASESEQ                   is null
		and ED.ASSOCIATEDCASERELATIONSHIPCODE is null
		and ED.ASSOCIATEDCASECOUNTRYCODE      is null
		and(ED.EVENTDATE is not null OR ED.EVENTDUEDATE is not null)"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo	int',
					  @pnBatchNo=@pnBatchNo

		Set @nCaseEventCount=@nCaseEventCount+@@Rowcount
	End
	
	If @nErrorCode=0
	Begin
		-------------------------------------------------
		-- Load Events that have been imported and do not
		-- already exist against the draft Case.
		-- Where Event is not linked to DRAFTEVENTNO
		-------------------------------------------------
		Set @sSQLString="
		Insert into CASEEVENT(CASEID, EVENTNO, CYCLE, EVENTDATE, EVENTDUEDATE, OCCURREDFLAG, DATEDUESAVED, EVENTTEXT)
		Select	M.DRAFTCASEID, 
			E.EVENTNO,
			ED.EVENTCYCLE, 
			CASE WHEN(ED.EVENTDUEDATE is null and ED.EVENTDATE>getdate()) THEN NULL ELSE convert(nvarchar,ED.EVENTDATE,112) END,
			CASE WHEN(ED.EVENTDUEDATE is not null) THEN convert(nvarchar,ED.EVENTDUEDATE,112)
			     WHEN(ED.EVENTDATE>getdate())      THEN convert(nvarchar,ED.EVENTDATE,112)
							       ELSE NULL
			END,
			CASE WHEN(ED.EVENTDATE is null) THEN 0
			     WHEN(ED.EVENTDATE > getdate() and ED.EVENTDUEDATE is null) THEN 0
			     ELSE 1
			END, 
			CASE WHEN(ED.EVENTDATE is null) THEN 1
			     WHEN(ED.EVENTDATE > getdate() and ED.EVENTDUEDATE is null) THEN 1
			     ELSE 0
			END, 
			ED.EVENTTEXT
		From EDECASEMATCH M
		join #TEMPCASEMATCH TM	on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
		join EDEEVENTDETAILS ED	on (ED.BATCHNO=M.BATCHNO
					and ED.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
		join EVENTS E		on (E.EVENTNO=ED.EVENTCODE_T)
		left join CASEEVENT CE	on (CE.CASEID=M.DRAFTCASEID
					and CE.CYCLE =ED.EVENTCYCLE
					and CE.EVENTNO=E.EVENTNO)
		Where M.BATCHNO=@pnBatchNo
		and M.DRAFTCASEID  is not null
		and E.DRAFTEVENTNO is null
		and CE.CASEID      is null
		and ED.ASSOCCASESEQ                   is null
		and ED.ASSOCIATEDCASERELATIONSHIPCODE is null
		and ED.ASSOCIATEDCASECOUNTRYCODE      is null
		and(ED.EVENTDATE is not null OR ED.EVENTDUEDATE is not null)"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo	int',
					  @pnBatchNo=@pnBatchNo

		Set @nCaseEventCount=@nCaseEventCount+@@Rowcount
	End
		
	If  @nCaseEventCount>0
	Begin
		-------------------------------------------
		-- Events that have been loaded may be
		-- associated with an Official Number Type.
		-- If so then the DATEENTERED against the
		-- number type is to be updated with the
		-- EventDate.
		-------------------------------------------
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Update O
			Set DATEENTERED=CE.EVENTDATE
			From EDECASEMATCH M
			join #TEMPCASEMATCH TM	on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join CASEEVENT CE	on (CE.CASEID =M.DRAFTCASEID
						and CE.CYCLE  =1
						and CE.EVENTDATE is not null)
			join NUMBERTYPES NT	on (NT.RELATEDEVENTNO=CE.EVENTNO)
			join OFFICIALNUMBERS O	on (O.CASEID=CE.CASEID
						and O.NUMBERTYPE=NT.NUMBERTYPE)
			Where M.BATCHNO=@pnBatchNo
			and O.ISCURRENT = 1"
	
			Exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo		=@pnBatchNo
		End


		-----------
		-- Policing
		--------------------------------------------------------------------
		-- Policing will explicitly be triggered by the imported Events.
		-- This is required to ensure any rules associated with the Events
		-- will take effect (e.g. set Status against Case).
		--------------------------------------------------------------------

		If @nErrorCode=0
		Begin
			-----------------------------------------------------------------
			-- Load a Policing row for each loaded CaseEvent to be processed.
			-- This occurs after the Open Action Policing request so that the
			-- Case status is set appropriately from the Events being updated.
			-----------------------------------------------------------------
			Set @sSQLString="
			insert into #TEMPPOLICING (CASEID, ACTION, EVENTNO, CYCLE, TYPEOFREQUEST)
			Select  CE.CASEID, NULL, CE.EVENTNO, CE.CYCLE,
				CASE WHEN(CE.OCCURREDFLAG=0) THEN 2 ELSE 3 END
			From EDECASEMATCH M
			join #TEMPCASEMATCH TM		 on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join EDEEVENTDETAILS ED		 on (ED.BATCHNO=M.BATCHNO
							 and ED.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join EVENTS E			 on (E.EVENTNO=ED.EVENTCODE_T)
			join CASEEVENT CE		 on (CE.CASEID=M.DRAFTCASEID
							 and CE.CYCLE=ED.EVENTCYCLE
							 and CE.EVENTNO=E.DRAFTEVENTNO) --SQA17537
			Where M.BATCHNO=@pnBatchNo
			and @bPolicingNotRequired=0
			and CE.EVENTNO not in (-16,-14,-13)
			and ED.ASSOCCASESEQ                   is null
			and ED.ASSOCIATEDCASERELATIONSHIPCODE is null
			and ED.ASSOCIATEDCASECOUNTRYCODE      is null
			UNION ALL
			Select  CE.CASEID, NULL, CE.EVENTNO, CE.CYCLE,
				CASE WHEN(CE.OCCURREDFLAG=0) THEN 2 ELSE 3 END
			From EDECASEMATCH M
			join #TEMPCASEMATCH TM		 on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join EDEEVENTDETAILS ED		 on (ED.BATCHNO=M.BATCHNO
							 and ED.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join EVENTS E			 on (E.EVENTNO=ED.EVENTCODE_T)
			join CASEEVENT CE		 on (CE.CASEID=M.DRAFTCASEID
							 and CE.CYCLE=ED.EVENTCYCLE
							 and CE.EVENTNO=E.EVENTNO) --SQA17537
			Where M.BATCHNO=@pnBatchNo
			and @bPolicingNotRequired=0
			and CE.EVENTNO not in (-16,-14,-13)
			and E.DRAFTEVENTNO                    is null
			and ED.ASSOCCASESEQ                   is null
			and ED.ASSOCIATEDCASERELATIONSHIPCODE is null
			and ED.ASSOCIATEDCASECOUNTRYCODE      is null
			UNION ALL
			Select  CE.CASEID, NULL, CE.EVENTNO, CE.CYCLE,3
			From EDECASEMATCH M
			join #TEMPCASEMATCH TM		 on (TM.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			join CASEEVENT CE		 on (CE.CASEID=CASE WHEN (M.MATCHLEVEL=3254 and M.LIVECASEID is not null) THEN M.LIVECASEID ELSE M.DRAFTCASEID END
							 and CE.CYCLE=1
							 and CE.EVENTNO=@nUpdateEventNo)
			Where M.BATCHNO=@pnBatchNo
			and CE.EVENTDATE=convert(nvarchar,getdate(),112)
			and ((M.MATCHLEVEL=3254 and M.LIVECASEID is not null) OR @bPolicingNotRequired=0)"
	
			Exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int,
						  @nUpdateEventNo	int,
						  @bPolicingNotRequired	bit',
						  @pnBatchNo		=@pnBatchNo,
						  @nUpdateEventNo	=@nUpdateEventNo,
						  @bPolicingNotRequired	=@bPolicingNotRequired

			Set @nPolicingCount=@@Rowcount
			Set @nPoliceBatchNo=NULL
		End
				
		If  @nErrorCode=0
		and @pbPoliceImmediately=1
		and @nPolicingCount>0
		Begin	
			---------------------------------------------------------------------------
			-- If the Police Immediately option is on then attach a unique Batch Number
			-- for all entries so that they can be recalculated at the one time. Also
			-- set the On Hold Flag on so that the Policing Server does not pick up
			-- these requests
			---------------------------------------------------------------------------
	
			------------------------------------------------------
			-- Get the Batchnumber to use for Police Immediately
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
			
		If  @nErrorCode=0
		and @nPolicingCount>0
		Begin
			----------------------------------------------------------------
			-- Now load live Policing table with generated sequence no
			----------------------------------------------------------------
			Set @sSQLString="
			insert into POLICING (DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, 
				 	      ONHOLDFLAG, CASEID, EVENTNO, CYCLE, TYPEOFREQUEST, BATCHNO, SQLUSER, IDENTITYID)
			select	getdate(), 
				T.SEQUENCENO, 
				'EDE4-'+convert(varchar, getdate(),126)+convert(varchar,T.SEQUENCENO),
				1,
				isnull(@pbPoliceImmediately,0), 
				T.CASEID, 
				T.EVENTNO,
				T.CYCLE, 
				T.TYPEOFREQUEST, 
				@nPoliceBatchNo, 
				substring(SYSTEM_USER,1,60), 
				@pnUserIdentityId
			from #TEMPPOLICING T"
	
			Exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnUserIdentityId	int,
						  @nPoliceBatchNo	int,
						  @pbPoliceImmediately	bit',
						  @pnUserIdentityId   =@pnUserIdentityId,
						  @nPoliceBatchNo     =@nPoliceBatchNo,
						  @pbPoliceImmediately=@pbPoliceImmediately
		End
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

	-----------------------------------------
	-- Run Policing if the Police Immediately
	-- option has been set
	-----------------------------------------

	If  @nErrorCode=0
	and @pbPoliceImmediately=1
	and @nPoliceBatchNo is not null
	and @sRequestType in ('Data Input','Data Verification','Extract Cases Response','Case Import','Agent Input')
	Begin
		exec @nErrorCode=dbo.ipu_Policing
					@pnBatchNo=@nPoliceBatchNo,
					@pnUserIdentityId=@pnUserIdentityId,
					@pnEDEBatchNo=@pnBatchNo
	
		--------------------------------------------------------------
		-- Reload the common area accessible from the database server
		-- with the previously generated TransactionNo as it may have
		-- been reset by Policing. This will be used by the audit logs.
		--------------------------------------------------------------
	
		set @bHexNumber=substring(cast(isnull(@pnUserIdentityId,'') as varbinary),1,4) + 
				substring(cast(isnull(@nTransNo,'') as varbinary),1,4)+ 
				substring(cast(isnull(@pnBatchNo,'') as varbinary),1,4) +
				substring(cast(isnull(@nOfficeID,'') as varbinary),1,4) +
				substring(cast(isnull(@nLogMinutes,'') as varbinary),1,4)
		SET CONTEXT_INFO @bHexNumber
		
		------------------------------------------------------------------------------------------
		-- DETERMINE SPECIAL ISSUE RULES
		------------------------------------------------------------------------------------------
		-- The "Special Issues" Rule Type will be used to determine which issues are to be checked.
		-- Characteristics of either the matched live Case or the draft Case will be used by
		-- considering the match level.
		--
		-- Match Level	Rule Search
		-- -----------  --------------------------------------------------------------------------
		-- Full (3254)	Characteristics of the live case will be used to find the rule.
		-- Part (3253)
		--
		-- New  (3252)  Characteristics of the draft case will be used to find the rule.
		-- Unmapped
		--      (3251)
		------------------------------------------------------------------------------------------
		If @nErrorCode=0
		Begin
			--------------------------------------
			-- Get the Special Issue Rule for each
			-- case that is to be processed
			--------------------------------------
			Set @sSQLString="
			Update #TEMPCASEMATCH
			Set SPECIALISSUERULE =
			       (SELECT
				convert(int,
				substring(
				max (
				CASE WHEN (C.CASEOFFICEID     IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (C.REQUESTTYPE      IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (C.DATASOURCENAMENO IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (C.CASETYPE         IS NULL)	THEN '0' 
					ELSE CASE WHEN(C.CASETYPE=CS.CASETYPE) 	 
					                                THEN '2' ELSE '1' END 
				END +  
				CASE WHEN (C.PROPERTYTYPE     IS NULL)	THEN '0' ELSE '1' END +    			
				CASE WHEN (C.COUNTRYCODE      IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (C.CASECATEGORY     IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (C.SUBTYPE          IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (C.RENEWALSTATUS    IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (C.STATUSCODE       IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (C.USERDEFINEDRULE  IS NULL
					OR C.USERDEFINEDRULE = 0)	THEN '0' ELSE '1' END +
				convert(varchar,C.CRITERIANO)), 12,20))
				FROM CRITERIA C 
				     join CASES CS    on (CS.CASEID=coalesce(T.LIVECASEID,T.DRAFTCASEID,E.LIVECASEID,E.DRAFTCASEID))
				     join CASETYPE CT on (CT.CASETYPE=CS.CASETYPE)
				left join PROPERTY P  on ( P.CASEID=CS.CASEID)
				WHERE	C.RULEINUSE		= 1  	
				AND	C.PURPOSECODE		= 'U' 
				AND	C.RULETYPE		= 10307 -- Special Issue Rule
				AND (	C.CASEOFFICEID 		= CS.OFFICEID 		OR C.CASEOFFICEID 	IS NULL )
				AND (	C.REQUESTTYPE 		= @sRequestType 	OR C.REQUESTTYPE 	IS NULL )
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
			left join EDECASEMATCH E on (E.BATCHNO=@pnBatchNo
			                         and E.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)"

			Exec @nErrorCode=sp_executesql @sSQLString,
						N'@sRequestType		nvarchar(50),
						  @nSenderNameNo	int,
						  @pnBatchNo		int',
						  @sRequestType=@sRequestType,
						  @nSenderNameNo=@nSenderNameNo,
						  @pnBatchNo=@pnBatchNo
		End
		
		-------------------------------------------------------------------------------------
		-- VALIDATION - AFTER POLICING
		-------------------------------------------------------------------------------------
		If @nErrorCode=0
		and @bPolicingNotRequired=0
		Begin
			Select @nTranCountStart = @@TranCount
			BEGIN TRANSACTION

			------------------------------
			-- Compare imported dates that 
			-- do not have a derived Event
			-- against the same Event on 
			-- the live Case
			------------------------------

			If  @nErrorCode=0
			and @nCaseEventCount>0
			and @sRequestType in ('Data Input','Data Verification','Extract Cases Response')
			Begin
				Set @nIssueNo = -26

				Set @sSQLString="
				Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED, REPORTEDVALUE, EXISTINGVALUE, ISSUETEXT)
				Select distinct @nIssueNo, C.BATCHNO, C.TRANSACTIONIDENTIFIER, 
						getdate(), 
						convert(nvarchar(12), CE1.EVENTDATE,@nDateFormat), 
						convert(nvarchar(12), CE2.EVENTDATE,@nDateFormat),
						E.EVENTDESCRIPTION
				from EDECASEMATCH C
				join #TEMPCASEMATCH TM		 on (TM.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
				join EDEEVENTDETAILS ED		 on (ED.BATCHNO=C.BATCHNO
								 and ED.TRANSACTIONIDENTIFIER=TM.TRANSACTIONIDENTIFIER)
				join EVENTS E			 on (E.EVENTNO=ED.EVENTCODE_T
								 and E.DRAFTEVENTNO is null)
				join CASEEVENT CE1		 on (CE1.CASEID=C.DRAFTCASEID
								 and CE1.CYCLE=ED.EVENTCYCLE
								 and CE1.EVENTNO=E.EVENTNO)
				join CASEEVENT CE2		 on (CE2.CASEID=C.LIVECASEID
								 and CE2.EVENTNO=CE1.EVENTNO
								 and CE2.CYCLE  =CE1.CYCLE)
				join EDERULESPECIALISSUE SI	 on (SI.CRITERIANO=TM.SPECIALISSUERULE  -- Issue must exist on Rule
								 and SI.ISSUEID   =@nIssueNo)
				left join EDEOUTSTANDINGISSUES I on (I.ISSUEID=SI.ISSUEID
								 and I.BATCHNO=C.BATCHNO
								 and I.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
				where C.BATCHNO=@pnBatchNo
				and ED.ASSOCCASESEQ                   is null
				and ED.ASSOCIATEDCASERELATIONSHIPCODE is null
				and ED.ASSOCIATEDCASECOUNTRYCODE      is null
				and CE1.EVENTDATE<>CE2.EVENTDATE
				and CE1.EVENTNO not in (-13, -14, -16)
				and I.ISSUEID is null"

				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int,
							  @nIssueNo	int,
							  @nDateFormat	tinyint',
							  @pnBatchNo   =@pnBatchNo,
							  @nIssueNo    =@nIssueNo,
							  @nDateFormat =@nDateFormat
			End
	
			------------------------------------------
			-- The current date is on or after the 
			-- Renewal Date less a number of specified
			-- days.
			-- New Cases only.
			------------------------------------------
			Set @nIssueNo = -11
	
			Set @sSQLString="
			Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED, REPORTEDVALUE)
			Select @nIssueNo, CM.BATCHNO, CM.TRANSACTIONIDENTIFIER,
					getdate(), 
					convert(nvarchar(12), isnull(CE.EVENTDATE,CE.EVENTDUEDATE),@nDateFormat)
			from EDECASEMATCH CM
			join #TEMPCASEMATCH M		on (M.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
			-- Get the current renewal cycle
			join SITECONTROL S		on (S.CONTROLID='Main Renewal Action')
			join OPENACTION OA		on (OA.CASEID=CM.DRAFTCASEID
							and OA.ACTION=S.COLCHARACTER
							and OA.CYCLE=(	select min(OA1.CYCLE)
									from OPENACTION OA1
									where OA1.CASEID=OA.CASEID
									and   OA1.ACTION=OA.ACTION
									and   OA1.POLICEEVENTS=1))
			-- Get the date of the current renewal date
			join CASEEVENT CE		on (CE.CASEID =CM.DRAFTCASEID
							and CE.EVENTNO=-11
							and CE.CYCLE  =OA.CYCLE)
			-- Get the number of days that determines that
			-- the renewal is imminent.
			join SITECONTROL S1		on (S1.CONTROLID='Renewal imminent days'
							and S1.COLINTEGER is not null)
			join EDERULESPECIALISSUE SI	 on (SI.CRITERIANO=M.SPECIALISSUERULE  -- Issue must exist on Rule
							 and SI.ISSUEID   =@nIssueNo)
			left join EDEOUTSTANDINGISSUES I on (I.ISSUEID=SI.ISSUEID
							and I.BATCHNO=CM.BATCHNO
							and I.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
			where CM.BATCHNO=@pnBatchNo
			and CM.MATCHLEVEL=3252	-- Error applies to New Cases only
			and I.ISSUEID is null
			and dateadd(dd, -1*S1.COLINTEGER, isnull(CE.EVENTDATE,CE.EVENTDUEDATE))<=getdate() "
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int,
						  @nIssueNo	int,
						  @nDateFormat	tinyint',
						  @pnBatchNo	=@pnBatchNo,
						  @nIssueNo 	=@nIssueNo,
						  @nDateFormat	=@nDateFormat
	
			If @nErrorCode=0
			Begin
				----------------------------
				-- Check for overriding Stop
				-- Processing Event if no
				-- match was found on Case.
				----------------------------
				Set @sSQLString="
				Select	@nStopEventNo=S.COLINTEGER
				from SITECONTROL S
				where S.CONTROLID='Stop Processing Event'"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@nStopEventNo		int	OUTPUT',
							  @nStopEventNo=@nStopEventNo	OUTPUT
			End
	
			If  @nErrorCode=0
			and @nStopEventNo is not null
			Begin
				-------------------------------------------------------------------
				-- Rather than look up the standing instruction directly (which may
				-- be slow), check to see if the Event that gets set from Standing 
				-- Instruction has been set. This way Policing will have already
				-- done the work of determining the standing instruction.
				-------------------------------------------------------------------
				Set @nIssueNo = -13
		
				Set @sSQLString="
				Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED)
				Select @nIssueNo, CM.BATCHNO, CM.TRANSACTIONIDENTIFIER, getdate()
				from EDECASEMATCH CM
				join #TEMPCASEMATCH M		on (M.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
				join CASEEVENT CE		on (CE.CASEID =CM.DRAFTCASEID
								and CE.EVENTNO=@nStopEventNo
								and CE.CYCLE  =1)
				join EDERULESPECIALISSUE SI	 on (SI.CRITERIANO=M.SPECIALISSUERULE  -- Issue must exist on Rule
								 and SI.ISSUEID   =@nIssueNo)
				left join EDEOUTSTANDINGISSUES I on (I.ISSUEID=SI.ISSUEID
								and I.BATCHNO=CM.BATCHNO
								and I.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
				where CM.BATCHNO=@pnBatchNo
				and CM.MATCHLEVEL=3252 	-- new live case created
				and I.ISSUEID is null
				and isnull(CE.EVENTDATE, CE.EVENTDUEDATE)<getdate()"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int,
							  @nIssueNo	int,
							  @nStopEventNo	int',
							  @pnBatchNo	=@pnBatchNo,
							  @nIssueNo	=@nIssueNo,
							  @nStopEventNo	=@nStopEventNo
			End
	
			If  @nErrorCode=0
			Begin
				-------------------------------------------------------------------
				-- SQA20830
				-- If the live case has a Stop Pay Reason or a Stop Pay Date but
				-- the Draft Case does not have either of these data items then
				-- raise issue -37 if it exists as a Special Issue rule.
				-------------------------------------------------------------------
				Set @nIssueNo = -37
		
				Set @sSQLString="
				Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED)
				Select @nIssueNo, CM.BATCHNO, CM.TRANSACTIONIDENTIFIER, getdate()
				from EDECASEMATCH CM
				join #TEMPCASEMATCH M		on (M.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
				join CASES C1			on (C1.CASEID  =CM.DRAFTCASEID)
				join CASES C2			on (C2.CASEID  =CM.LIVECASEID)
				join EDERULESPECIALISSUE SI	on (SI.CRITERIANO=M.SPECIALISSUERULE  -- Issue must exist on Rule
								and SI.ISSUEID   =@nIssueNo)
				left join CASEEVENT CE1		on (CE1.CASEID =C1.CASEID
								and CE1.EVENTNO=@nStopEventNo
								and CE1.CYCLE  =1)
				left join CASEEVENT CE2		on (CE2.CASEID =C2.CASEID
								and CE2.EVENTNO=@nStopEventNo
								and CE2.CYCLE  =1)
				left join EDEOUTSTANDINGISSUES I on(I.ISSUEID=SI.ISSUEID
								and I.BATCHNO=CM.BATCHNO
								and I.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
				where CM.BATCHNO=@pnBatchNo
				and CM.MATCHLEVEL=3254 	-- existing live case only
				and I.ISSUEID is null
				and ((CE1.EVENTDATE is null and C1.STOPPAYREASON is null) and (isnull(CE2.EVENTDATE, CE2.EVENTDUEDATE) is not null OR C2.STOPPAYREASON is not null))"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int,
							  @nIssueNo	int,
							  @nStopEventNo	int',
							  @pnBatchNo	=@pnBatchNo,
							  @nIssueNo	=@nIssueNo,
							  @nStopEventNo	=@nStopEventNo
			End
		
			If @nErrorCode=0
			Begin
				--------------------------
				-- Renewal Date cannot be 
				-- calculated. Report this
				-- even if Renewal Date
				-- was supplied.
				--------------------------
				Set @nIssueNo = -14
		
				Set @sSQLString="
				Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED)
				Select @nIssueNo, CM.BATCHNO, CM.TRANSACTIONIDENTIFIER, getdate()
				from EDECASEMATCH CM
				join #TEMPCASEMATCH M		on (M.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
				join OPENACTION OA		on (OA.CASEID=CM.DRAFTCASEID
								and OA.ACTION='~2'	-- Renewal calculation opened
								and OA.CYCLE =1
								and OA.POLICEEVENTS=1)
				left join CASEEVENT CE		on (CE.CASEID =CM.DRAFTCASEID
								and CE.EVENTNO=-11
								and isnull(CE.EVENTDATE, CE.EVENTDUEDATE) is not null)
				join EDERULESPECIALISSUE SI	 on (SI.CRITERIANO=M.SPECIALISSUERULE  -- Issue must exist on Rule
								 and SI.ISSUEID   =@nIssueNo)
				left join EDEOUTSTANDINGISSUES I on (I.ISSUEID=SI.ISSUEID
								and I.BATCHNO=CM.BATCHNO
								and I.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
				where CM.BATCHNO=@pnBatchNo
				and I.ISSUEID is null
				and CE.CASEID is null"		-- Renewal date has not been calculated
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int,
							  @nIssueNo	int',
							  @pnBatchNo=@pnBatchNo,
							  @nIssueNo =@nIssueNo
			End
	
			If @nErrorCode=0
			Begin
				---------------------------------------
				-- Supplied Renewal Date matches the 
				-- calculated Renewal Date of the 
				-- previous cycle.
				-- This indicates that the Case would
				-- have already gone past the grace 
				-- period of the supplied Renewal Date.
				-- New Cases only.
				---------------------------------------
				Set @nIssueNo = -21
		
				Set @sSQLString="
				Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED, REPORTEDVALUE)
				Select @nIssueNo, CM.BATCHNO, CM.TRANSACTIONIDENTIFIER,
					getdate(), 
					convert(nvarchar(12), CE2.EVENTDATE,@nDateFormat)
				from EDECASEMATCH CM
				join #TEMPCASEMATCH M		on (M.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
				-- Get the current renewal cycle
				join SITECONTROL S		on (S.CONTROLID='Main Renewal Action')
				join OPENACTION OA		on (OA.CASEID=CM.DRAFTCASEID
								and OA.ACTION=S.COLCHARACTER
								and OA.CYCLE=(	select min(OA1.CYCLE)
										from OPENACTION OA1
										where OA1.CASEID=OA.CASEID
										and   OA1.ACTION=OA.ACTION
										and   OA1.POLICEEVENTS=1))
				join EVENTS E			on (E.EVENTNO =-11)
				-- Get the renewal date calculated in the previous cycle
				join CASEEVENT CE1		on (CE1.CASEID =CM.DRAFTCASEID
								and CE1.EVENTNO=E.EVENTNO
								and CE1.CYCLE  =OA.CYCLE-1)
				-- Get the user supplied renewal date
				join CASEEVENT CE2		on (CE2.CASEID =CM.DRAFTCASEID
								and CE2.EVENTNO=E.DRAFTEVENTNO
								and CE2.CYCLE  =1
								and CE2.EVENTDATE=CE1.EVENTDATE)
				join EDERULESPECIALISSUE SI	 on (SI.CRITERIANO=M.SPECIALISSUERULE  -- Issue must exist on Rule
								 and SI.ISSUEID   =@nIssueNo)
				left join EDEOUTSTANDINGISSUES I on (I.ISSUEID=SI.ISSUEID
								and I.BATCHNO=CM.BATCHNO
								and I.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
				where CM.BATCHNO=@pnBatchNo
				and CM.MATCHLEVEL=3252 	-- new live case created
				and I.ISSUEID is null"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int,
							  @nIssueNo	int,
							  @nDateFormat	tinyint',
							  @pnBatchNo	=@pnBatchNo,
							  @nIssueNo	=@nIssueNo,
							  @nDateFormat	=@nDateFormat
			End
	
			If @nErrorCode=0
			Begin
				------------------------------
				-- Registration number missing
				------------------------------
				Set @nIssueNo = -22
		
				Set @sSQLString="
				Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED)
				Select @nIssueNo, CM.BATCHNO, CM.TRANSACTIONIDENTIFIER, getdate()
				from EDECASEMATCH CM
				join #TEMPCASEMATCH M		on (M.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
				join CASEEVENT CE		on (CE.CASEID =CM.DRAFTCASEID
								and CE.EVENTNO=-8
								and CE.CYCLE  =1
								and CE.EVENTDATE is not null)
				left join OFFICIALNUMBERS O	on (O.CASEID=CM.DRAFTCASEID
								and O.NUMBERTYPE='R')
				join EDERULESPECIALISSUE SI	 on (SI.CRITERIANO=M.SPECIALISSUERULE  -- Issue must exist on Rule
								 and SI.ISSUEID   =@nIssueNo)
				left join EDEOUTSTANDINGISSUES I on (I.ISSUEID=SI.ISSUEID
								and I.BATCHNO=CM.BATCHNO
								and I.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
				where CM.BATCHNO=@pnBatchNo
				and I.ISSUEID is null
				and O.OFFICIALNUMBER is null	-- No Registration number"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int,
							  @nIssueNo	int',
							  @pnBatchNo=@pnBatchNo,
							  @nIssueNo =@nIssueNo
			End
		
			If @nErrorCode=0
			Begin
				---------------------------------
				-- Imported date that has a
				-- derived event is not equal to
				-- the live date.
				---------------------------------
				Set @nIssueNo = -23
		
				Set @sSQLString="
				Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED, REPORTEDVALUE, EXISTINGVALUE, ISSUETEXT)
				Select @nIssueNo, CM.BATCHNO, CM.TRANSACTIONIDENTIFIER,
					getdate(), 
					convert(nvarchar(12), isnull(IMP.EVENTDATE,IMP.EVENTDUEDATE),@nDateFormat),
					convert(nvarchar(12), isnull(LIV.EVENTDATE,LIV.EVENTDUEDATE),@nDateFormat),
					E.EVENTDESCRIPTION+' - Discrepancy with Reported and Existing Date'
				from EDECASEMATCH CM
				join #TEMPCASEMATCH M		on (M.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
				join EDERULESPECIALISSUE SI	 on (SI.CRITERIANO=M.SPECIALISSUERULE  -- Issue must exist on Rule
								 and SI.ISSUEID   =@nIssueNo)
				left join EDEOUTSTANDINGISSUES I on (I.ISSUEID=SI.ISSUEID
								and I.BATCHNO=CM.BATCHNO
								and I.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
				 -- imported events
				 join CASEEVENT IMP		on (IMP.CASEID=CM.DRAFTCASEID)
				 join EVENTS E			on (E.DRAFTEVENTNO=IMP.EVENTNO)
				 -- get the best Action and cycle for the Live Event
				 -- noting that the Action that calculated the Event may not 
				 -- in itself be the best one to use (e.g. Renewals).
				 -- SQA16645
				 -- To get the lowest open Cycle against the Action that allows
				 -- the most cycles requires the use of MAX and a 9's complement
				 -- of the cycle (to get the lowest cycle)
				 Left Join (	select OA.CASEID, EC.EVENTNO, 
							max(
							convert(char(5), A.NUMCYCLESALLOWED)+
							convert(char(5),99999-OA.CYCLE)+
							OA.ACTION) as BestAction
						from EVENTCONTROL EC
						join OPENACTION OA on (OA.CRITERIANO=EC.CRITERIANO)
						join ACTIONS A     on (A.ACTION=OA.ACTION)
						where OA.POLICEEVENTS=1
						group by OA.CASEID, EC.EVENTNO) BA on (BA.CASEID=CM.LIVECASEID
										   and BA.EVENTNO=E.EVENTNO)
				 Left Join CASEEVENT LIV On (LIV.CASEID=CM.LIVECASEID
							AND LIV.EVENTNO=E.EVENTNO
							AND LIV.CYCLE=	CASE WHEN( (convert(int,substring(BA.BestAction,1,5))>1) ) 
										THEN 99999-convert(int,substring(BA.BestAction,6,5)) 
										ELSE isnull( (	select min(CE.CYCLE)
												from CASEEVENT CE
												where CE.CASEID=LIV.CASEID
												and CE.EVENTNO=LIV.EVENTNO
												and CE.OCCURREDFLAG=0),
											     (	select max(CE.CYCLE)
												From CASEEVENT CE
												where CE.CASEID=LIV.CASEID
												and CE.EVENTNO=LIV.EVENTNO
												and CE.EVENTDATE is not null) )
						      			END) 
				where CM.BATCHNO=@pnBatchNo
				and I.ISSUEID is null
				-- check where the imported date is not equal to the calculated date
				and isnull(IMP.EVENTDATE,IMP.EVENTDUEDATE)<>isnull(LIV.EVENTDATE,LIV.EVENTDUEDATE)"
	
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int,
							  @nIssueNo	int,
							  @nDateFormat	tinyint',
							  @pnBatchNo	=@pnBatchNo,
							  @nIssueNo	=@nIssueNo,
							  @nDateFormat	=@nDateFormat
			End
		
			If @nErrorCode=0
			Begin
				---------------------------------
				-- Calculated date not equal to
				-- imported date.
				-- Do not report if Imported date
				-- has been reported as different
				-- from the live date.
				---------------------------------
				Set @nIssueNo = -23
		
				Set @sSQLString="
				Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED, REPORTEDVALUE, EXISTINGVALUE, ISSUETEXT)
				Select @nIssueNo, CM.BATCHNO, CM.TRANSACTIONIDENTIFIER,
					getdate(), 
					convert(nvarchar(12), isnull(IMP.EVENTDATE,IMP.EVENTDUEDATE),@nDateFormat),
					convert(nvarchar(12), isnull(CAL.EVENTDATE,CAL.EVENTDUEDATE),@nDateFormat),
					E.EVENTDESCRIPTION+' - Discrepancy with Reported and Calculated Date'
				from EDECASEMATCH CM
				join #TEMPCASEMATCH M		on (M.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
				join EDERULESPECIALISSUE SI	on (SI.CRITERIANO=M.SPECIALISSUERULE  -- Issue must exist on Rule
								and SI.ISSUEID   =@nIssueNo)
				left join EDEOUTSTANDINGISSUES I on(I.ISSUEID=SI.ISSUEID
								and I.BATCHNO=CM.BATCHNO
								and I.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
				 -- imported events
				 join CASEEVENT IMP		on (IMP.CASEID=CM.DRAFTCASEID)
				 join EVENTS E			on (E.DRAFTEVENTNO=IMP.EVENTNO)
				 -- get the best Action and cycle for the calculated Event
				 -- noting that the Action that calculated the Event may not 
				 -- in itself be the best one to use (e.g. Renewals).
				 -- SQA16645
				 -- To get the lowest open Cycle against the Action that allows
				 -- the most cycles requires the use of MAX and a 9's complement
				 -- of the cycle (to get the lowest cycle)
				 Left Join (	select OA.CASEID, EC.EVENTNO, 
							max(
							convert(char(5), A.NUMCYCLESALLOWED)+
							convert(char(5),99999-OA.CYCLE)+
							OA.ACTION) as BestAction
						from EVENTCONTROL EC
						join OPENACTION OA on (OA.CRITERIANO=EC.CRITERIANO)
						join ACTIONS A     on (A.ACTION=OA.ACTION)
						where OA.POLICEEVENTS=1
						group by OA.CASEID, EC.EVENTNO) BA on (BA.CASEID=CM.DRAFTCASEID
										   and BA.EVENTNO=E.EVENTNO)
				 Left Join CASEEVENT CAL On (CAL.CASEID=CM.DRAFTCASEID
							AND CAL.EVENTNO=E.EVENTNO
							AND CAL.CYCLE=	CASE WHEN( (convert(int,substring(BA.BestAction,1,5))>1) ) 
										THEN 99999-convert(int,substring(BA.BestAction,6,5)) 
										ELSE isnull( (	select min(CE.CYCLE)
												from CASEEVENT CE
												where CE.CASEID=CAL.CASEID
												and CE.EVENTNO=CAL.EVENTNO
												and CE.OCCURREDFLAG=0),
											     (	select max(CE.CYCLE)
												From CASEEVENT CE
												where CE.CASEID=CAL.CASEID
												and CE.EVENTNO=CAL.EVENTNO
												and CE.EVENTDATE is not null) )
						      			END) 
				where CM.BATCHNO=@pnBatchNo
				and I.ISSUEID is null
				-- check where the imported date is not equal to the calculated date
				-- SQA17449 Note that if there is no calculated date then this means that the base
				--          dates to perform the calculation have not been provided so this will not
				--          be treated as an error. 
				and isnull(IMP.EVENTDATE,IMP.EVENTDUEDATE)<>isnull(CAL.EVENTDATE,CAL.EVENTDUEDATE)"
	
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int,
							  @nIssueNo	int,
							  @nDateFormat	tinyint',
							  @pnBatchNo	=@pnBatchNo,
							  @nIssueNo	=@nIssueNo,
							  @nDateFormat	=@nDateFormat
			End
		
			If @nErrorCode=0
			Begin
				---------------------------------
				-- Calculated derived date does
				-- not match the live date.
				---------------------------------
				Set @nIssueNo = -23
		
				Set @sSQLString="
				Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED, REPORTEDVALUE, EXISTINGVALUE, ISSUETEXT)
				Select @nIssueNo, CM.BATCHNO, CM.TRANSACTIONIDENTIFIER,
					getdate(), 
					convert(nvarchar(12), isnull(CAL.EVENTDATE,CAL.EVENTDUEDATE),@nDateFormat),
					convert(nvarchar(12), isnull(LIV.EVENTDATE,LIV.EVENTDUEDATE),@nDateFormat),
					E.EVENTDESCRIPTION+' - Discrepancy with Calculated and Existing Date'
				from EDECASEMATCH CM
				join #TEMPCASEMATCH M		on (M.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
				join EDERULESPECIALISSUE SI	on (SI.CRITERIANO=M.SPECIALISSUERULE  -- Issue must exist on Rule
								and SI.ISSUEID   =@nIssueNo)
				left join EDEOUTSTANDINGISSUES I on(I.ISSUEID=SI.ISSUEID
								and I.BATCHNO=CM.BATCHNO
								and I.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)

				 join EVENTS E			on (E.DRAFTEVENTNO is not null)
				 -- get the best Action and cycle for the calculated Event
				 -- noting that the Action that calculated the Event may not 
				 -- in itself be the best one to use (e.g. Renewals).
				 -- SQA16645
				 -- To get the lowest open Cycle against the Action that allows
				 -- the most cycles requires the use of MAX and a 9's complement
				 -- of the cycle (to get the lowest cycle)
				 Left Join (	select OA.CASEID, EC.EVENTNO, 
							max(
							convert(char(5), A.NUMCYCLESALLOWED)+
							convert(char(5),99999-OA.CYCLE)+
							OA.ACTION) as BestAction
						from EVENTCONTROL EC
						join OPENACTION OA on (OA.CRITERIANO=EC.CRITERIANO)
						join ACTIONS A     on (A.ACTION=OA.ACTION)
						where OA.POLICEEVENTS=1
						group by OA.CASEID, EC.EVENTNO) BA on (BA.CASEID=CM.DRAFTCASEID
										   and BA.EVENTNO=E.EVENTNO)
				 Left Join CASEEVENT CAL On (CAL.CASEID=CM.DRAFTCASEID
							AND CAL.EVENTNO=E.EVENTNO
							AND CAL.CYCLE=	CASE WHEN( (convert(int,substring(BA.BestAction,1,5))>1) ) 
										THEN 99999-convert(int,substring(BA.BestAction,6,5)) 
										ELSE isnull( (	select min(CE.CYCLE)
												from CASEEVENT CE
												where CE.CASEID=CAL.CASEID
												and CE.EVENTNO=CAL.EVENTNO
												and CE.OCCURREDFLAG=0),
											     (	select max(CE.CYCLE)
												From CASEEVENT CE
												where CE.CASEID=CAL.CASEID
												and CE.EVENTNO=CAL.EVENTNO
												and CE.EVENTDATE is not null) )
						      			END)
				 -- get the best Action and cycle for the Live Event
				 -- noting that the Action that calculated the Event may not 
				 -- in itself be the best one to use (e.g. Renewals).
				 -- SQA16645
				 -- To get the lowest open Cycle against the Action that allows
				 -- the most cycles requires the use of MAX and a 9's complement
				 -- of the cycle (to get the lowest cycle)
				 Left Join (	select OA.CASEID, EC.EVENTNO, 
							max(
							convert(char(5), A.NUMCYCLESALLOWED)+
							convert(char(5),99999-OA.CYCLE)+
							OA.ACTION) as BestAction
						from EVENTCONTROL EC
						join OPENACTION OA on (OA.CRITERIANO=EC.CRITERIANO)
						join ACTIONS A     on (A.ACTION=OA.ACTION)
						where OA.POLICEEVENTS=1
						group by OA.CASEID, EC.EVENTNO) BL on (BL.CASEID=CM.LIVECASEID
										   and BL.EVENTNO=E.EVENTNO)
				 Left Join CASEEVENT LIV On (LIV.CASEID=CM.LIVECASEID
							AND LIV.EVENTNO=E.EVENTNO
							AND LIV.CYCLE=	CASE WHEN( (convert(int,substring(BL.BestAction,1,5))>1) ) 
										THEN 99999-convert(int,substring(BL.BestAction,6,5)) 
										ELSE isnull( (	select min(CE.CYCLE)
												from CASEEVENT CE
												where CE.CASEID=LIV.CASEID
												and CE.EVENTNO=LIV.EVENTNO
												and CE.OCCURREDFLAG=0),
											     (	select max(CE.CYCLE)
												From CASEEVENT CE
												where CE.CASEID=LIV.CASEID
												and CE.EVENTNO=LIV.EVENTNO
												and CE.EVENTDATE is not null) )
						      			END) 
				where CM.BATCHNO=@pnBatchNo
				and I.ISSUEID is null
				-- the live Event must exist
				and LIV.CASEID is not null
				-- check where the live date is not equal to the calculated date
				-- SQA17449 Note that if there is no calculated date then this means that the base
				--          dates to perform the calculation have not been provided so this will not
				--          be treated as an error. 
				and isnull(CAL.EVENTDATE,CAL.EVENTDUEDATE)<>isnull(LIV.EVENTDATE,LIV.EVENTDUEDATE)"
	
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int,
							  @nIssueNo	int,
							  @nDateFormat	tinyint',
							  @pnBatchNo	=@pnBatchNo,
							  @nIssueNo	=@nIssueNo,
							  @nDateFormat	=@nDateFormat
			End
		
			If @nErrorCode=0
			Begin
				----------------------------
				-- If no Open Action policed
				-- raise an issue
				----------------------------
				Set @nIssueNo = -28
		
				Set @sSQLString="
				Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED)
				Select @nIssueNo, CM.BATCHNO, CM.TRANSACTIONIDENTIFIER, getdate()
				from EDECASEMATCH CM
				join #TEMPCASEMATCH M		 on (M.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
				left join EDEOUTSTANDINGISSUES I on (I.ISSUEID=@nIssueNo
								 and I.BATCHNO=CM.BATCHNO
								 and I.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
				where CM.BATCHNO=@pnBatchNo
				and I.ISSUEID is null
				and not exists
				(select 1
				 from OPENACTION OA
				 where OA.CASEID=CM.DRAFTCASEID
				 and OA.CRITERIANO is not null)"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int,
							  @nIssueNo	int',
							  @pnBatchNo=@pnBatchNo,
							  @nIssueNo =@nIssueNo
			End
		
			If @nErrorCode=0
			Begin
				------------------------------------------
				-- SQA17449
				-- An imported date that is associated
				-- with another Event that may be
				-- calculated is to be loaded into the
				-- imported date if the calculated Event 
				-- does not exist.
				-- This is to occur for new Cases only.
				------------------------------------------

				Set @sSQLString="
				Insert into CASEEVENT(CASEID, EVENTNO, CYCLE, EVENTDATE, EVENTDUEDATE, OCCURREDFLAG, DATEDUESAVED, EVENTTEXT, LONGFLAG, EVENTLONGTEXT)
				Select  CM.DRAFTCASEID, 
					E.EVENTNO, 
					1, 
					IMP.EVENTDATE, 
					IMP.EVENTDUEDATE, 
					IMP.OCCURREDFLAG, 
					CASE WHEN(IMP.EVENTDATE is null and IMP.EVENTDUEDATE is not null) THEN 1 ELSE 0 END, 
					IMP.EVENTTEXT, 
					IMP.LONGFLAG, 
					IMP.EVENTLONGTEXT
				from EDECASEMATCH CM
				join #TEMPCASEMATCH M		on (M.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
				left join (	select I.BATCHNO, I.TRANSACTIONIDENTIFIER
						from EDEOUTSTANDINGISSUES I
						join EDESTANDARDISSUE SI on (SI.ISSUEID=I.ISSUEID)
						where SI.SEVERITYLEVEL=4010) XI	on (XI.BATCHNO=CM.BATCHNO
										and XI.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
				 -- imported events
				 join CASEEVENT IMP		on (IMP.CASEID=CM.DRAFTCASEID)
				 join EVENTS E			on (E.DRAFTEVENTNO=IMP.EVENTNO)
				 -- The calculated Event does not exist for any cycle
				 left Join CASEEVENT CAL On (CAL.CASEID=CM.DRAFTCASEID
							 and CAL.EVENTNO=E.EVENTNO) 
				where CM.BATCHNO=@pnBatchNo
				and M.MATCHLEVEL=3252			-- new case
				and XI.TRANSACTIONIDENTIFIER is null	-- no severe issues
				and CAL.CASEID is null			-- no calculated event
				and(IMP.EVENTDATE is not null OR IMP.EVENTDUEDATE is not null)"
	
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int',
							  @pnBatchNo	=@pnBatchNo
			End

			-------------------------------------------------
			-- For each transaction that about to be rejected
			-- insert a TRANSACTIONINFO row.
			-------------------------------------------------
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Insert into TRANSACTIONINFO(TRANSACTIONDATE, BATCHNO,TRANSACTIONIDENTIFIER, TRANSACTIONMESSAGENO, TRANSACTIONREASONNO) 
				select distinct getdate(),B.BATCHNO,B.TRANSACTIONIDENTIFIER,4, @nReasonNo
				from #TEMPCASEMATCH M
				join EDETRANSACTIONBODY B   on (B.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
				join EDEOUTSTANDINGISSUES I on (I.BATCHNO=B.BATCHNO
							    and I.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
				join EDESTANDARDISSUE S	    on (S.ISSUEID=I.ISSUEID)
				where B.BATCHNO=@pnBatchNo
				and B.TRANSSTATUSCODE=3440
				and S.SEVERITYLEVEL=4010" -- Reject Severity
			
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int,
							  @nReasonNo	int',
							  @pnBatchNo=@pnBatchNo,
							  @nReasonNo=@nReasonNo
			End
	
			If @nErrorCode=0
			Begin
				------------------------------------
				-- Mark the rejected transactions as
				-- Processed if an issue has been
				-- raised with a reject severity
				------------------------------------
				Set @sSQLString="
				Update EDETRANSACTIONBODY
				Set TRANSSTATUSCODE=3480,
			    	    TRANSACTIONRETURNCODE='Case rejected',
				    TRANSNARRATIVECODE=CASE WHEN(T.TRANSNARRATIVECODE is not null) THEN T.TRANSNARRATIVECODE
							    WHEN(SI.DEFAULTNARRATIVE<>'')          THEN SI.DEFAULTNARRATIVE
							END
				From EDETRANSACTIONBODY T
				join (	select	O.BATCHNO, 
						O.TRANSACTIONIDENTIFIER,
						min(isnull(S.DEFAULTNARRATIVE,'')) as DEFAULTNARRATIVE
					from EDEOUTSTANDINGISSUES O
					join EDESTANDARDISSUE S	on (S.ISSUEID=O.ISSUEID)
					where S.SEVERITYLEVEL=4010
					group by O.BATCHNO, O.TRANSACTIONIDENTIFIER) SI
						on (SI.BATCHNO=T.BATCHNO
						and SI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
				Where T.BATCHNO=@pnBatchNo
				and T.TRANSSTATUSCODE=3440"
		
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
				and T1.TRANSSTATUSCODE=3480
				and T1.TRANSACTIONRETURNCODE='Case rejected'"
			
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int',
							  @pnBatchNo=@pnBatchNo
			End
	
			If @nErrorCode=0
			Begin
				----------------------------------------------
				-- Update #TEMPCASEMATCH with the draft CaseId
				-- will need this after EDECASEMATCH deleted
				----------------------------------------------
				Set @sSQLString="
				Update #TEMPCASEMATCH
				set DRAFTCASEID=E.DRAFTCASEID
				from EDECASEMATCH E
				join #TEMPCASEMATCH T	on (T.TRANSACTIONIDENTIFIER=E.TRANSACTIONIDENTIFIER)
				where E.BATCHNO=@pnBatchNo
				and E.DRAFTCASEID is not null
				and T.DRAFTCASEID is null"
		
				Exec @nErrorCode=sp_executesql @sSQLString,
								N'@pnBatchNo		int',
								  @pnBatchNo=@pnBatchNo
			End
	
			If @nErrorCode=0
			Begin
				---------------------------------------------
				-- Transactions that are marked as processed
				-- are to have the EDECASEDETAILS table point
				-- to the live CASEID before EDECASEMATCH is
				-- removed.
				-- Note that this update may extend beyond 
				-- the current batch as the Draft Case from
				-- an earlier batch may have been replaced by
				-- this transaction.
				---------------------------------------------
				Set @sSQLString="
				Update EDECASEDETAILS 
				Set CASEID=C1.LIVECASEID
				from EDECASEMATCH C
				join #TEMPCASEMATCH M		on (M.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
				join EDECASEMATCH C1		on (C1.DRAFTCASEID=C.DRAFTCASEID)
				join EDECASEDETAILS E		on (E.BATCHNO=C1.BATCHNO
								and E.TRANSACTIONIDENTIFIER=C1.TRANSACTIONIDENTIFIER)
				join EDETRANSACTIONBODY T	on (T.BATCHNO=E.BATCHNO
								and T.TRANSACTIONIDENTIFIER=E.TRANSACTIONIDENTIFIER)
				Where C.BATCHNO=@pnBatchNo
				and T.TRANSSTATUSCODE=3480
				and isnull(E.CASEID,'')<>C1.LIVECASEID"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int',
							  @pnBatchNo=@pnBatchNo
			End
	
			If @nErrorCode=0
			Begin
				-------------------------------------------------------------
				-- Remove any EDECASEMATCH rows with "processed" transactions
				-- Note that rows from other batches may be removed as the
				-- same draft case may belong in multiple batches.
				-------------------------------------------------------------
				Set @sSQLString="
				Delete EDECASEMATCH
				From (select * from EDECASEMATCH) C
				join #TEMPCASEMATCH M	  on (M.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
				join EDECASEMATCH CM	  on (CM.DRAFTCASEID=C.DRAFTCASEID)
				join EDETRANSACTIONBODY T on (T.BATCHNO=CM.BATCHNO
							  and T.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
				Where C.BATCHNO=@pnBatchNo
				and T.TRANSSTATUSCODE=3480"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int',
							  @pnBatchNo=@pnBatchNo
			End
	

			If @nErrorCode=0
			Begin
				-------------------------------
				-- RFC-63684 
				-- Remove any RELATEDCASE to the draft Cases for  
				-- the "processed" transactions
				-------------------------------
				Set @sSQLString="
				Delete RELATEDCASE
				From RELATEDCASE R
				join #TEMPCASEMATCH M	  on (M.DRAFTCASEID=R.RELATEDCASEID)
				join EDETRANSACTIONBODY T on (T.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
				Where T.BATCHNO=@pnBatchNo
				and T.TRANSSTATUSCODE=3480"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int',
							  @pnBatchNo=@pnBatchNo
			End


			If @nErrorCode=0
			Begin
				-------------------------------
				-- Remove any draft Cases for  
				-- the "processed" transactions
				-------------------------------
				Set @sSQLString="
				Delete CASES
				From CASES C
				join #TEMPCASEMATCH M	  on (M.DRAFTCASEID=C.CASEID)
				join EDETRANSACTIONBODY T on (T.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
				Where T.BATCHNO=@pnBatchNo
				and T.TRANSSTATUSCODE=3480"
		
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
		End
	
	End
	
	--------------------------------------------------------
	-- Compare draft Cases against the Full Match live Case.  
	-- If no data difference is found then the transaction
	-- will be marked as Processed and the Draft removed.
	-- Ignore transactions that already have issues raised.
	--------------------------------------------------------
	If @nErrorCode=0
	Begin
		-----------
		-- CASES --
		-----------
		Set @sSQLString="
		Update #TEMPCASEMATCH
		Set UPDATEREQUIRED=1
		From #TEMPCASEMATCH TM
		join EDECASEMATCH T on (T.BATCHNO=@pnBatchNo
				    and T.TRANSACTIONIDENTIFIER=TM.TRANSACTIONIDENTIFIER)
		join EDETRANSACTIONBODY B on (B.BATCHNO=T.BATCHNO
					  and B.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
		join CASES D	on (D.CASEID=T.DRAFTCASEID)
		join CASES L	on (L.CASEID=T.LIVECASEID)
		left join EDEOUTSTANDINGISSUES I on (I.BATCHNO=B.BATCHNO
						 and I.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
		left join EDESTANDARDISSUE S	 on (S.ISSUEID=I.ISSUEID
						 and S.SEVERITYLEVEL=4010)
		where T.MATCHLEVEL=3254		-- Full match
		and TM.UPDATEREQUIRED=0
		and B.TRANSSTATUSCODE=3440	-- Ready for Case Import	
		and S.ISSUEID is null	 	-- No issues of high severity
		and CHECKSUM(D.PROPERTYTYPE,D.COUNTRYCODE,D.CASECATEGORY,D.SUBTYPE,D.TYPEOFMARK,D.TITLE,D.NOINSERIES,D.NOOFCLASSES,D.LOCALCLASSES,D.INTCLASSES,D.LOCALCLIENTFLAG,D.ENTITYSIZE,D. CURRENTOFFICIALNO,D.TAXCODE,D.STOPPAYREASON,D.EXTENDEDRENEWALS)
		 <> CHECKSUM(L.PROPERTYTYPE,L.COUNTRYCODE,L.CASECATEGORY,L.SUBTYPE,L.TYPEOFMARK,L.TITLE,L.NOINSERIES,L.NOOFCLASSES,L.LOCALCLASSES,L.INTCLASSES,L.LOCALCLIENTFLAG,L.ENTITYSIZE,L. CURRENTOFFICIALNO,L.TAXCODE,L.STOPPAYREASON,L.EXTENDEDRENEWALS)"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo


	
		If @nErrorCode=0
		Begin
			--------------
			-- PROPERTY --
			--------------
			Set @sSQLString="
			Update #TEMPCASEMATCH
			Set UPDATEREQUIRED=1
			From #TEMPCASEMATCH TM
			join EDECASEMATCH T on (T.BATCHNO=@pnBatchNo
					    and T.TRANSACTIONIDENTIFIER=TM.TRANSACTIONIDENTIFIER)
			join EDETRANSACTIONBODY B on (B.BATCHNO=T.BATCHNO
						  and B.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			join PROPERTY D	on (D.CASEID=T.DRAFTCASEID)
			join PROPERTY L	on (L.CASEID=T.LIVECASEID)
			left join EDEOUTSTANDINGISSUES I on (I.BATCHNO=B.BATCHNO
							 and I.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			left join EDESTANDARDISSUE S	 on (S.ISSUEID=I.ISSUEID
							 and S.SEVERITYLEVEL=4010)
			where T.MATCHLEVEL=3254		-- Full match
			and TM.UPDATEREQUIRED=0
			and B.TRANSSTATUSCODE=3440	-- Ready for Case Import	
			and S.ISSUEID is null	 	-- No issues of high severity
			and CHECKSUM(D.BASIS,D.REGISTEREDUSERS,D.EXAMTYPE,D.NOOFCLAIMS,D.RENEWALTYPE,D.RENEWALNOTES,D.PLACEFIRSTUSED,D.PROPOSEDUSE)
			 <> CHECKSUM(L.BASIS,L.REGISTEREDUSERS,L.EXAMTYPE,L.NOOFCLAIMS,L.RENEWALTYPE,L.RENEWALNOTES,L.PLACEFIRSTUSED,L.PROPOSEDUSE)"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End
		
		If @nErrorCode=0
		Begin
			---------------------
			-- OFFICIALNUMBERS --
			---------------------
			Set @sSQLString="
			Update #TEMPCASEMATCH
			Set UPDATEREQUIRED=1
			From #TEMPCASEMATCH TM
			join EDECASEMATCH T on (T.BATCHNO=@pnBatchNo
					    and T.TRANSACTIONIDENTIFIER=TM.TRANSACTIONIDENTIFIER)
			join EDETRANSACTIONBODY B on (B.BATCHNO=T.BATCHNO
							and B.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			     join OFFICIALNUMBERS D	on (D.CASEID=T.DRAFTCASEID)
			left join OFFICIALNUMBERS L	on (L.CASEID=T.LIVECASEID
							and L.NUMBERTYPE=D.NUMBERTYPE)
			left join EDEOUTSTANDINGISSUES I on (I.BATCHNO=B.BATCHNO
							 and I.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			left join EDESTANDARDISSUE S	 on (S.ISSUEID=I.ISSUEID
							 and S.SEVERITYLEVEL=4010)
			where T.MATCHLEVEL=3254		-- Full match
			and TM.UPDATEREQUIRED=0
			and B.TRANSSTATUSCODE=3440	-- Ready for Case Import	
			and S.ISSUEID is null	 	-- No issues of high severity
			and CHECKSUM(D.OFFICIALNUMBER,D.ISCURRENT)
			 <> CHECKSUM(L.OFFICIALNUMBER,L.ISCURRENT)"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		
			------------------------------------------------
			-- If the draft is missing an Official Number 
			-- that exists on the live Case then this may
			-- indicate the Official Number is to be removed
			------------------------------------------------
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Update #TEMPCASEMATCH
				Set UPDATEREQUIRED=1
				From #TEMPCASEMATCH TM
				join EDECASEMATCH T 		on (T.BATCHNO=@pnBatchNo
						    		and T.TRANSACTIONIDENTIFIER=TM.TRANSACTIONIDENTIFIER)
				join EDETRANSACTIONBODY B 	on (B.BATCHNO=T.BATCHNO
								and B.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
				     join OFFICIALNUMBERS L	on (L.CASEID=T.LIVECASEID)
				left join OFFICIALNUMBERS D	on (D.CASEID=T.DRAFTCASEID
								and D.NUMBERTYPE=L.NUMBERTYPE)
				left join EDEOUTSTANDINGISSUES I on (I.BATCHNO=B.BATCHNO
								 and I.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
				left join EDESTANDARDISSUE S	 on (S.ISSUEID=I.ISSUEID
								 and S.SEVERITYLEVEL=4010)
				where T.MATCHLEVEL=3254		-- Full match
				and TM.UPDATEREQUIRED=0
				and B.TRANSSTATUSCODE=3440	-- Ready for Case Import	
				and S.ISSUEID is null	 	-- No issues of high severity
				and D.CASEID  is null		-- No matching draft Official Number
				-- check that a rule exists that allows the Official Number to be removed
				and exists
				(select 1
				 from EDERULEOFFICIALNUMBER R
				 where R.NUMBERTYPE=L.NUMBERTYPE
				 and   R.OFFICIALNUMBER=4)"
			
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int',
							  @pnBatchNo=@pnBatchNo
			End
		End
		
		If @nErrorCode=0
		Begin
			--------------
			-- CASETEXT --
			--------------
			Set @sSQLString="
			Update #TEMPCASEMATCH
			Set UPDATEREQUIRED=1
			From #TEMPCASEMATCH TM
				join EDECASEMATCH T 	  on (T.BATCHNO=@pnBatchNo
						    	  and T.TRANSACTIONIDENTIFIER=TM.TRANSACTIONIDENTIFIER)
				join EDETRANSACTIONBODY B on (B.BATCHNO=T.BATCHNO
							  and B.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			     join CASETEXT D	on (D.CASEID=T.DRAFTCASEID)
			left join CASETEXT L	on (L.CASEID=T.LIVECASEID
						and L.TEXTTYPE=D.TEXTTYPE
						and isnull(L.LANGUAGE,'')=isnull(D.LANGUAGE,'')
						and isnull(L.CLASS,'')   =isnull(D.CLASS,''))
			left join EDEOUTSTANDINGISSUES I on (I.BATCHNO=B.BATCHNO
							 and I.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			left join EDESTANDARDISSUE S	 on (S.ISSUEID=I.ISSUEID
							 and S.SEVERITYLEVEL=4010)
			where T.MATCHLEVEL=3254		-- Full match
			and TM.UPDATEREQUIRED=0
			and B.TRANSSTATUSCODE=3440	-- Ready for Case Import	
			and S.ISSUEID is null	 	-- No issues of high severity
			and( CHECKSUM(L.SHORTTEXT)<>checksum(D.SHORTTEXT) or CHECKSUM(datalength(L.TEXT))<>CHECKSUM(datalength(D.TEXT)) or L.TEXT not like D.TEXT)"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		
			------------------------------------------------
			-- If the draft is missing a Case Text 
			-- that exists on the live Case then this may
			-- indicate the Case Text is to be removed
			------------------------------------------------
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Update #TEMPCASEMATCH
				Set UPDATEREQUIRED=1
				From #TEMPCASEMATCH TM
				     join EDECASEMATCH T 	on (T.BATCHNO=@pnBatchNo
							    	and T.TRANSACTIONIDENTIFIER=TM.TRANSACTIONIDENTIFIER)
				     join EDETRANSACTIONBODY B	on (B.BATCHNO=T.BATCHNO
								and B.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
				     join CASETEXT L	on (L.CASEID=T.LIVECASEID)
				left join CASETEXT D	on (D.CASEID=T.DRAFTCASEID
							and D.TEXTTYPE=D.TEXTTYPE
							and isnull(D.LANGUAGE,'')=isnull(L.LANGUAGE,'')
							and isnull(D.CLASS,'')   =isnull(L.CLASS,''))
				left join EDEOUTSTANDINGISSUES I on (I.BATCHNO=B.BATCHNO
								 and I.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
				left join EDESTANDARDISSUE S	 on (S.ISSUEID=I.ISSUEID
								 and S.SEVERITYLEVEL=4010)
				where T.MATCHLEVEL=3254		-- Full match
				and TM.UPDATEREQUIRED=0
				and B.TRANSSTATUSCODE=3440	-- Ready for Case Import	
				and S.ISSUEID is null	 	-- No issues of high severity
				and D.CASEID  is null		-- No matching draft Case Text
				-- check that a rule exists that allows the Case Text to be removed
				and exists
				(select 1
				 from EDERULECASETEXT R
				 where R.TEXTTYPE=L.TEXTTYPE
				 and   R.TEXT=4)"
			
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int',
							  @pnBatchNo=@pnBatchNo
			End
		End
		
		If @nErrorCode=0
		Begin
			---------------
			-- CASEEVENT --
			---------------
			Set @sSQLString="
			Update #TEMPCASEMATCH
			Set UPDATEREQUIRED=1
			From #TEMPCASEMATCH TM
			     join EDECASEMATCH T 	on (T.BATCHNO=@pnBatchNo
						    	and T.TRANSACTIONIDENTIFIER=TM.TRANSACTIONIDENTIFIER)
			     join EDETRANSACTIONBODY B	on (B.BATCHNO=T.BATCHNO
							and B.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			     join CASEEVENT D	on (D.CASEID=T.DRAFTCASEID)
			left join CASEEVENT L	on (L.CASEID=T.LIVECASEID
						and L.EVENTNO=D.EVENTNO
						and L.CYCLE  =D.CYCLE)
			left join EDEOUTSTANDINGISSUES I on (I.BATCHNO=B.BATCHNO
							 and I.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			left join EDESTANDARDISSUE S	 on (S.ISSUEID=I.ISSUEID
							 and S.SEVERITYLEVEL=4010)
			where T.MATCHLEVEL=3254		-- Full match
			and TM.UPDATEREQUIRED=0
			and B.TRANSSTATUSCODE=3440	-- Ready for Case Import
			and(D.EVENTNO<>@nUpdateEventNo OR @nUpdateEventNo is null)
			and S.ISSUEID is null	 	-- No issues of high severity
			and( CHECKSUM(D.EVENTDATE,D.EVENTDUEDATE,D.EVENTTEXT,D.LONGFLAG)<>checksum(L.EVENTDATE,L.EVENTDUEDATE,L.EVENTTEXT,L.LONGFLAG) or CHECKSUM(datalength(L.EVENTLONGTEXT))<>CHECKSUM(datalength(D.EVENTLONGTEXT)) or L.EVENTLONGTEXT not like D.EVENTLONGTEXT)"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int,
						  @nUpdateEventNo	int',
						  @pnBatchNo    =@pnBatchNo,
						  @nUpdateEventNo=@nUpdateEventNo
	
			------------------------------------------------
			-- If the draft is missing a Case Event 
			-- that exists on the live Case then this may
			-- indicate the Case Text is to be removed
			------------------------------------------------
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Update #TEMPCASEMATCH
				Set UPDATEREQUIRED=1
				From #TEMPCASEMATCH TM
				     join EDECASEMATCH T 	on (T.BATCHNO=@pnBatchNo
							    	and T.TRANSACTIONIDENTIFIER=TM.TRANSACTIONIDENTIFIER)
				     join EDETRANSACTIONBODY B	on (B.BATCHNO=T.BATCHNO
								and B.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
				     join CASEEVENT L	on (L.CASEID =T.LIVECASEID)
				left join CASEEVENT D	on (D.CASEID =T.DRAFTCASEID
							and D.EVENTNO=L.EVENTNO
							and D.CYCLE  =L.CYCLE)
				left join EDEOUTSTANDINGISSUES I on (I.BATCHNO=B.BATCHNO
								 and I.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
				left join EDESTANDARDISSUE S	 on (S.ISSUEID=I.ISSUEID
								 and S.SEVERITYLEVEL=4010)
				where T.MATCHLEVEL=3254		-- Full match
				and TM.UPDATEREQUIRED=0
				and B.TRANSSTATUSCODE=3440	-- Ready for Case Import	
				and S.ISSUEID is null	 	-- No issues of high severity
				and D.CASEID  is null
				-- check that a rule exists that allows the EventDate to be removed
				and exists
				(select 1
				 from EDERULECASEEVENT R
				 where R.EVENTNO=L.EVENTNO
				 and   R.EVENTDATE=4)"
			
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int',
							  @pnBatchNo=@pnBatchNo
			End
		End
		
		If @nErrorCode=0
		Begin
			-----------------
			-- RELATEDCASE --
			-----------------
			Set @sSQLString="
			Update #TEMPCASEMATCH
			Set UPDATEREQUIRED=1
			From #TEMPCASEMATCH TM
			     join EDECASEMATCH T 	on (T.BATCHNO=@pnBatchNo
						    	and T.TRANSACTIONIDENTIFIER=TM.TRANSACTIONIDENTIFIER)
			     join EDETRANSACTIONBODY B	on (B.BATCHNO=T.BATCHNO
							and B.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			     join RELATEDCASE D	on (D.CASEID=T.DRAFTCASEID)
			left join RELATEDCASE L	on (L.CASEID=T.LIVECASEID
						and L.RELATIONSHIP=D.RELATIONSHIP
						and isnull(L.RELATEDCASEID,'') =isnull(D.RELATEDCASEID,'')
						and isnull(L.OFFICIALNUMBER,'')=isnull(D.OFFICIALNUMBER,''))
			left join EDEOUTSTANDINGISSUES I on (I.BATCHNO=B.BATCHNO
							 and I.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			left join EDESTANDARDISSUE S	 on (S.ISSUEID=I.ISSUEID
							 and S.SEVERITYLEVEL=4010)
			where T.MATCHLEVEL=3254		-- Full match
			and TM.UPDATEREQUIRED=0
			and B.TRANSSTATUSCODE=3440	-- Ready for Case Import	
			and S.ISSUEID is null	 	-- No issues of high severity
			and CHECKSUM(D.RELATEDCASEID,D.OFFICIALNUMBER,D.COUNTRYCODE,D.PRIORITYDATE)
			 <> CHECKSUM(L.RELATEDCASEID,L.OFFICIALNUMBER,L.COUNTRYCODE,L.PRIORITYDATE)"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		
			------------------------------------------------
			-- If the draft is missing a Related Case
			-- that exists on the live Case then this may
			-- indicate the Related Case is to be removed
			------------------------------------------------
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Update #TEMPCASEMATCH
				Set UPDATEREQUIRED=1
				From #TEMPCASEMATCH TM
				     join EDECASEMATCH T 	on (T.BATCHNO=@pnBatchNo
							    	and T.TRANSACTIONIDENTIFIER=TM.TRANSACTIONIDENTIFIER)
				     join EDETRANSACTIONBODY B	on (B.BATCHNO=T.BATCHNO
								and B.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
				     join RELATEDCASE L	on (L.CASEID=T.LIVECASEID)
				left join RELATEDCASE D	on (D.CASEID=T.DRAFTCASEID
							and D.RELATIONSHIP=L.RELATIONSHIP
							and isnull(D.RELATEDCASEID,'') =isnull(L.RELATEDCASEID,'')
							and isnull(D.OFFICIALNUMBER,'')=isnull(L.OFFICIALNUMBER,''))
				left join EDEOUTSTANDINGISSUES I on (I.BATCHNO=B.BATCHNO
								 and I.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
				left join EDESTANDARDISSUE S	 on (S.ISSUEID=I.ISSUEID
								 and S.SEVERITYLEVEL=4010)
				where T.MATCHLEVEL=3254		-- Full match
				and TM.UPDATEREQUIRED=0
				and B.TRANSSTATUSCODE=3440	-- Ready for Case Import	
				and S.ISSUEID is null	 	-- No issues of high severity
				and D.CASEID  is null		-- No matching draft related case
				-- check that a rule exists that allows the Related Case to be removed
				and exists
				(select 1
				 from EDERULERELATEDCASE R
				 where R.RELATIONSHIP=L.RELATIONSHIP
				 and   R.OFFICIALNUMBER=4)"
			
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int',
							  @pnBatchNo=@pnBatchNo
			End
		End
		
		If @nErrorCode=0
		Begin
			--------------
			-- CASENAME --
			--------------
			Set @sSQLString="
			Update #TEMPCASEMATCH
			Set UPDATEREQUIRED=1
			From #TEMPCASEMATCH TM
			     join EDECASEMATCH T 	on (T.BATCHNO=@pnBatchNo
						    	and T.TRANSACTIONIDENTIFIER=TM.TRANSACTIONIDENTIFIER)
			     join EDETRANSACTIONBODY B	on (B.BATCHNO=T.BATCHNO
							and B.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			     join CASENAME D	on (D.CASEID=T.DRAFTCASEID)
			left join CASENAME L	on (L.CASEID=T.LIVECASEID
						and L.NAMETYPE=D.NAMETYPE
						and L.NAMENO=D.NAMENO)
			left join EDEOUTSTANDINGISSUES I on (I.BATCHNO=B.BATCHNO
							 and I.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			left join EDESTANDARDISSUE S	 on (S.ISSUEID=I.ISSUEID
							 and S.SEVERITYLEVEL=4010)
			where T.MATCHLEVEL=3254		-- Full match
			and TM.UPDATEREQUIRED=0
			and B.TRANSSTATUSCODE=3440	-- Ready for Case Import	
			and S.ISSUEID is null	 	-- No issues of high severity
			and D.NAMETYPE<>@sRequestorNameType
			and CHECKSUM(D.CORRESPONDNAME,D.ADDRESSCODE,D.REFERENCENO,D.ASSIGNMENTDATE,D.COMMENCEDATE,D.EXPIRYDATE,D.BILLPERCENTAGE)
			 <> CHECKSUM(L.CORRESPONDNAME,L.ADDRESSCODE,L.REFERENCENO,L.ASSIGNMENTDATE,L.COMMENCEDATE,L.EXPIRYDATE,L.BILLPERCENTAGE)"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int,
						  @sRequestorNameType	nvarchar(3)',
						  @pnBatchNo=@pnBatchNo,
						  @sRequestorNameType=@sRequestorNameType
		
			------------------------------------------------
			-- If the draft is missing a Case Name
			-- that exists on the live Case then this may
			-- indicate the Case Name is to be removed
			------------------------------------------------
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Update #TEMPCASEMATCH
				Set UPDATEREQUIRED=1
				From #TEMPCASEMATCH TM
				     join EDECASEMATCH T 	on (T.BATCHNO=@pnBatchNo
							    	and T.TRANSACTIONIDENTIFIER=TM.TRANSACTIONIDENTIFIER)
				     join EDETRANSACTIONBODY B	on (B.BATCHNO=T.BATCHNO
								and B.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
				     join CASENAME L	on (L.CASEID=T.LIVECASEID)
				left join CASENAME D	on (D.CASEID=T.DRAFTCASEID
							and D.NAMETYPE=L.NAMETYPE
							and D.NAMENO=L.NAMENO)
				left join EDEOUTSTANDINGISSUES I on (I.BATCHNO=B.BATCHNO
								 and I.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
				left join EDESTANDARDISSUE S	 on (S.ISSUEID=I.ISSUEID
								 and S.SEVERITYLEVEL=4010)
				where T.MATCHLEVEL=3254		-- Full match
				and TM.UPDATEREQUIRED=0
				and B.TRANSSTATUSCODE=3440	-- Ready for Case Import	
				and S.ISSUEID is null	 	-- No issues of high severity
				and L.NAMETYPE<>@sRequestorNameType
				and D.CASEID  is null		-- No matching draft Case Name
				-- check that a rule exists that allows the Case Name to be removed
				and exists
				(select 1
				 from EDERULECASENAME R
				 where R.NAMETYPE=L.NAMETYPE
				 and   R.NAMENO=4)"
			
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @sRequestorNameType	nvarchar(3)',
							  @pnBatchNo=@pnBatchNo,
							  @sRequestorNameType=@sRequestorNameType
			End
		End
		
		If @nErrorCode=0
		Begin
			----------------
			-- OPENACTION --
			----------------
		
			-- Restrict comparison to the Open Renewal Action only
			Set @sSQLString="
			Update #TEMPCASEMATCH
			Set UPDATEREQUIRED=1
			From #TEMPCASEMATCH TM
			     join EDECASEMATCH T 	on (T.BATCHNO=@pnBatchNo
						    	and T.TRANSACTIONIDENTIFIER=TM.TRANSACTIONIDENTIFIER)
			     join EDETRANSACTIONBODY B	on (B.BATCHNO=T.BATCHNO
							and B.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			     join SITECONTROL S on (S.CONTROLID='Main Renewal Action')
			     join OPENACTION D	on (D.CASEID=T.DRAFTCASEID
						and D.ACTION=S.COLCHARACTER
						and D.POLICEEVENTS=1)
			left join OPENACTION L	on (L.CASEID=T.LIVECASEID
						and L.ACTION=D.ACTION
						and L.POLICEEVENTS=1)
			left join EDEOUTSTANDINGISSUES I on (I.BATCHNO=B.BATCHNO
							 and I.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			left join EDESTANDARDISSUE SI	 on (SI.ISSUEID=I.ISSUEID
							 and SI.SEVERITYLEVEL=4010)
			where T.MATCHLEVEL=3254		-- Full match
			and TM.UPDATEREQUIRED=0
			and B.TRANSSTATUSCODE=3440	-- Ready for Case Import	
			and SI.ISSUEID is null	 	-- No issues of high severity
			and L.CASEID  is null		-- No matching live Open Action"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End
	End

	-------------------------------------
	-- Load a table of Cases where there
	-- are more than one Official Numbers
	-- for the same Number Type that are 
	-- marked as being current.  These
	-- will trigger the transaction to 
	-- go to operator review.
	-------------------------------------
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Insert into #TEMPNUMBERCOUNT(CASEID, NUMBERTYPE, NUMBERCOUNT)
		Select O.CASEID, O.NUMBERTYPE, COUNT(*)
		From EDETRANSACTIONBODY T
		join EDECASEMATCH M	on (M.BATCHNO=T.BATCHNO
					and M.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
		join #TEMPCASEMATCH TM	on (TM.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
		join OFFICIALNUMBERS O	on (O.CASEID=M.DRAFTCASEID)
		Where T.BATCHNO=@pnBatchNo
		and isnull(O.ISCURRENT,1)=1
		group by O.CASEID, O.NUMBERTYPE
		having count(*)>1"
		
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo	int',
					  @pnBatchNo=@pnBatchNo
	End

	--------------------------------
	-- Update the Transaction Status
	-- and the EDEOUTSTANDINGISSUES
	--------------------------------
	If @nErrorCode=0
	Begin
		-- Start a new transaction
		Select @nTranCountStart = @@TranCount
		BEGIN TRANSACTION

		-------------------------------------------------
		-- For each transaction that about to be marked
		-- as Processed,insert a TRANSACTIONINFO row to 
		-- indicate that no changes resulted from the
		-- transaciton
		-------------------------------------------------
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Insert into TRANSACTIONINFO(TRANSACTIONDATE, BATCHNO,TRANSACTIONIDENTIFIER,CASEID,TRANSACTIONMESSAGENO, TRANSACTIONREASONNO) 
			select distinct getdate(),T.BATCHNO,T.TRANSACTIONIDENTIFIER,TM.LIVECASEID,3,@nReasonNo
			From EDETRANSACTIONBODY T
			     join #TEMPCASEMATCH TM on (TM.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			left join EDEOUTSTANDINGISSUES SI
						    on (SI.BATCHNO=T.BATCHNO
						    and SI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			Where T.BATCHNO=@pnBatchNo
			and T.TRANSSTATUSCODE=3440
			and SI.BATCHNO is null  -- No issues
			and TM.MATCHLEVEL=3254	-- Full match
			and isnull(TM.UPDATEREQUIRED,0)=0"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int,
						  @nReasonNo	int',
						  @pnBatchNo=@pnBatchNo,
						  @nReasonNo=@nReasonNo
		End

		-------------------------------------------------------------
		-- Mark the succcessful transactions as Ready for Case Update
		-- Also set the Default Narrative if one exists
		-------------------------------------------------------------
		If @nErrorCode=0
		Begin	
		
			Set @sSQLString="
			Update EDETRANSACTIONBODY
			Set TRANSSTATUSCODE=	CASE 
						WHEN(T.TRANSSTATUSCODE=3440)
							THEN	CASE 
								WHEN(TM.MATCHLEVEL=3251)	-- Multiple Matches
									THEN 3460		-- Operator Review
								WHEN(TM.MATCHLEVEL=3252)	-- New Case
									THEN	CASE 
										WHEN (C.CASEID IS NOT NULL AND IRNISSUE.BATCHNO IS NOT NULL)
											THEN 3440 -- Ready for Case Import (IRN generation issue)
										WHEN(C.CASEID is not null and N.CASEID is NULL)
											THEN 3450	-- Ready for Case Update
										WHEN(C.CASEID is not null and N.CASEID is not NULL)
											THEN 3460	-- Operator Review
										END
								WHEN(TM.MATCHLEVEL=3253)	-- Partial Match
									THEN 3460		-- Operator Review
								WHEN(TM.MATCHLEVEL=3254)	-- Full Match
									THEN	CASE 
										WHEN(TM.UPDATEREQUIRED=1 and N.CASEID is null)
											THEN 3450	-- Ready for Case Update
										WHEN(TM.UPDATEREQUIRED=1 and N.CASEID is not null)
											THEN 3460	-- Operator Review
										ELSE 3480	-- Processed - no updates or severe issues
										END
								ELSE T.TRANSSTATUSCODE
							END -- Match Level
						ELSE T.TRANSSTATUSCODE
						END,
			TRANSACTIONRETURNCODE=	CASE WHEN(T.TRANSSTATUSCODE=3440 AND 
						     TM.UPDATEREQUIRED=0    AND
						     TM.MATCHLEVEL=3254	    AND -- Full match
						     SI.BATCHNO is null)
							THEN 'No Changes Made'
							ELSE T.TRANSACTIONRETURNCODE
						END,
			TRANSNARRATIVECODE=	CASE WHEN(T.TRANSSTATUSCODE=3440 AND 
						     TM.UPDATEREQUIRED=0    AND
						     TM.MATCHLEVEL=3254	    AND -- Full match
						     SI.BATCHNO is null)
							THEN 4022	-- AMENDED CASES - NO CHANGE REQUIRED
							ELSE isnull(T.TRANSNARRATIVECODE,convert(int,SUBSTRING(SI.DEFAULTNARRATIVE,12,11)))
						END
			From EDETRANSACTIONBODY T
			left join EDECASEMATCH M    on (M.BATCHNO=T.BATCHNO
						    and M.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			     join #TEMPCASEMATCH TM on (TM.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			left join CASES C	    on (C.CASEID=M.DRAFTCASEID)
			left join (	select	O.BATCHNO, 
						O.TRANSACTIONIDENTIFIER, 
						-- the highest Severity has the lowest SeverityLevel
						min(left(replicate('0', 11-len(S.SEVERITYLEVEL))   +convert(CHAR(11), S.SEVERITYLEVEL)   ,11)+	
						    CASE WHEN(S.DEFAULTNARRATIVE<0) THEN '-' ELSE '0' END + RIGHT('0000000000'+replace(cast(S.DEFAULTNARRATIVE as nvarchar),'-',''),10)	  -- NOTE: DEFAULTNARRATIVE can be a negative number
						   ) as DEFAULTNARRATIVE
					from EDEOUTSTANDINGISSUES O
					join EDESTANDARDISSUE S	on (S.ISSUEID=O.ISSUEID)
					where S.SEVERITYLEVEL    is not null
					and   S.DEFAULTNARRATIVE is not null
					group by O.BATCHNO, O.TRANSACTIONIDENTIFIER) SI
						on (SI.BATCHNO=T.BATCHNO
						and SI.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			left join (SELECT BATCHNO, TRANSACTIONIDENTIFIER FROM EDEOUTSTANDINGISSUES
					WHERE BATCHNO = @pnBatchNo
					AND ISSUEID = -27) AS IRNISSUE	on (IRNISSUE.BATCHNO=T.BATCHNO
										and IRNISSUE.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)			
			-- Check for multple Official Numbers 
			-- marked as current
			left join (	select distinct CASEID
					from #TEMPNUMBERCOUNT)  N
						on (N.CASEID=M.DRAFTCASEID)
			Where T.BATCHNO=@pnBatchNo"
		
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
			join EDECASEMATCH CM	  on (CM.TRANSACTIONIDENTIFIER=TM.TRANSACTIONIDENTIFIER)
			join EDECASEMATCH M	  on (M.DRAFTCASEID=CM.DRAFTCASEID
						  and M.BATCHNO<>CM.BATCHNO)
			join EDETRANSACTIONBODY T on (T.BATCHNO=M.BATCHNO
						  and T.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			-- Use derived table to avoid ambiguous table error
			join (select * from EDETRANSACTIONBODY) T1
						  on (T1.BATCHNO=CM.BATCHNO
						  and T1.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
			Where CM.BATCHNO=@pnBatchNo"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End
	
		If @nErrorCode=0
		Begin
			---------------------------------------------
			-- Transactions that are marked as processed
			-- are to have the EDECASEDETAILS table point
			-- to the live CASEID before EDECASEMATCH is
			-- removed.
			-- Note that this update may extend beyond 
			-- the current batch as the Draft Case from
			-- an earlier batch may have been replaced by
			-- this transaction.
			---------------------------------------------
			Set @sSQLString="
			Update EDECASEDETAILS 
			Set CASEID=C1.LIVECASEID
			from EDECASEMATCH C
			join #TEMPCASEMATCH M		on (M.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			join EDECASEMATCH C1		on (C1.DRAFTCASEID=C.DRAFTCASEID)
			join EDECASEDETAILS E		on (E.BATCHNO=C1.BATCHNO
							and E.TRANSACTIONIDENTIFIER=C1.TRANSACTIONIDENTIFIER)
			join EDETRANSACTIONBODY T	on (T.BATCHNO=E.BATCHNO
							and T.TRANSACTIONIDENTIFIER=E.TRANSACTIONIDENTIFIER)
			Where C.BATCHNO=@pnBatchNo
			and T.TRANSSTATUSCODE=3480
			and isnull(E.CASEID,'')<>C1.LIVECASEID"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End
	
		If @nErrorCode=0
		and @sRequestType in ('Case Import','Agent Input')
		Begin
			---------------------------------
			-- RFC-63684
			-- Remove the relationship in RELATEDCASE 
			-- to the Draft Case 
			---------------------------------
			Set @sSQLString="
			Delete R
			From RELATEDCASE R
			join EDECASEMATCH M	  on (M.DRAFTCASEID=R.RELATEDCASEID)
			join EDETRANSACTIONBODY T on (T.BATCHNO=M.BATCHNO
						  and T.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			Where M.BATCHNO=@pnBatchNo
			and T.TRANSSTATUSCODE=3480
			and T.TRANSACTIONRETURNCODE='No Changes Made'"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		
			If @nErrorCode=0
			Begin
				-------------------------------------
				-- Remove any draft Cases for  
				-- the "processed" transactions
				-- for "Case Import" or "Agent Input"
				-- batches where "No Changes Made".
				-------------------------------------
				Set @sSQLString="
				Delete C
				From CASES C
				join EDECASEMATCH M	  on (M.DRAFTCASEID=C.CASEID)
				join EDETRANSACTIONBODY T on (T.BATCHNO=M.BATCHNO
							  and T.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
				Where M.BATCHNO=@pnBatchNo
				and T.TRANSSTATUSCODE=3480
				and T.TRANSACTIONRETURNCODE='No Changes Made'"
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo	int',
							  @pnBatchNo=@pnBatchNo
			End
		End
	
		If @nErrorCode=0
		Begin
			-------------------------------------------------------------
			-- Remove any EDECASEMATCH rows with "processed" transactions
			-- Note that rows from other batches may be removed as the
			-- same draft case may belong in multiple batches.
			-------------------------------------------------------------
			Set @sSQLString="
			Delete EDECASEMATCH
			From (select * from EDECASEMATCH) C
			join #TEMPCASEMATCH M	  on (M.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
			join EDECASEMATCH CM	  on (CM.DRAFTCASEID=C.DRAFTCASEID)
			join EDETRANSACTIONBODY T on (T.BATCHNO=CM.BATCHNO
						  and T.TRANSACTIONIDENTIFIER=CM.TRANSACTIONIDENTIFIER)
			Where C.BATCHNO=@pnBatchNo
			and T.TRANSSTATUSCODE=3480"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End


		If @nErrorCode=0
		Begin
			-------------------------------
			-- RFC-63684
			-- Remove any RELATEDCASE to the draft Cases for  
			-- the "processed" transactions
			-------------------------------
			Set @sSQLString="
			Delete RELATEDCASE
			From RELATEDCASE R
			join #TEMPCASEMATCH M	  on (M.DRAFTCASEID=R.RELATEDCASEID)
			join EDETRANSACTIONBODY T on (T.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			Where T.BATCHNO=@pnBatchNo
			and T.TRANSSTATUSCODE=3480"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End

	
		If @nErrorCode=0
		Begin
			-------------------------------
			-- Remove any draft Cases for  
			-- the "processed" transactions
			-------------------------------
			Set @sSQLString="
			Delete CASES
			From CASES C
			join #TEMPCASEMATCH M	  on (M.DRAFTCASEID=C.CASEID)
			join EDETRANSACTIONBODY T on (T.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER)
			Where T.BATCHNO=@pnBatchNo
			and T.TRANSSTATUSCODE=3480"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End
		-------------------------------
		-- Point the Outstanding Issues 
		-- against the Draft Case.
		-------------------------------
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Update I 
			set CASEID=M.DRAFTCASEID
			from EDEOUTSTANDINGISSUES I
			join EDECASEMATCH M	on (M.BATCHNO=I.BATCHNO
						and M.TRANSACTIONIDENTIFIER=I.TRANSACTIONIDENTIFIER
						and exists(Select 1 from CASES C where C.CASEID = M.DRAFTCASEID) )
			where I.BATCHNO=@pnBatchNo
			and isnull(I.CASEID,'')<>isnull(M.DRAFTCASEID,'')"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
			
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
	
	----------------------------------
	-- Transactions that have a status
	-- of "Ready for Case Update" or 
	-- "Operator Review" are to be
	-- processed.
	----------------------------------
	If @nErrorCode=0
	Begin
		exec @nErrorCode=dbo.ede_UpdateLiveCasesFromDraft
					@pnUserIdentityId	=@pnUserIdentityId,			
					@pnBatchNo		=@pnBatchNo,
					@pbPoliceImmediately	=0
	End

	-------------------------------------------------
	-- If transactions are still being looped through
	-- then reset the temporary tables for use in 
	-- the next cycle through the loop.
	-------------------------------------------------
	If @nReadyForImport>@nLoopCount
	and @nErrorCode=0
	Begin
		set @sSQLString="
		Delete from #TEMPCANDIDATECASES"

		exec @nErrorCode=sp_executesql @sSQLString

		If @nErrorCode=0
		Begin
			set @sSQLString="
			Delete from #TEMPCASEMATCH"

			exec @nErrorCode=sp_executesql @sSQLString
		End

		If @nErrorCode=0
		Begin
			-- User truncate to reset Identity column
			set @sSQLString="
			truncate table #TEMPCASES"

			exec @nErrorCode=sp_executesql @sSQLString
		End

		If @nErrorCode=0
		and @nPolicingCount>0
		Begin
			Set @nPolicingCount=0

			-- User truncate to reset Identity column
			set @sSQLString="
			truncate table #TEMPPOLICING"

			exec @nErrorCode=sp_executesql @sSQLString
		End

		If @nErrorCode=0
		Begin
			set @sSQLString="
			Delete from #TEMPCASESTOUPDATE"

			exec @nErrorCode=sp_executesql @sSQLString
		End
	End
End	-- End main loop through transactions


----------------------------------
-- SQA18702
-- Remove orphan EDECASEMATCH rows
-- where the draft Case no longer
-- exists.
----------------------------------
If @nErrorCode=0
Begin
	-- Start a new transaction
	Select @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	set @sSQLString="
	Delete M
	FROM EDECASEMATCH M
	Left JOIN CASES C ON (C.CASEID = M.DRAFTCASEID)
	WHERE C.CASEID is null"

	exec @nErrorCode=sp_executesql @sSQLString
	
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


RETURN @nErrorCode
go

grant execute on dbo.ede_LoadDraftCasesFromEDE to public
go

