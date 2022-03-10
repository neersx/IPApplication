-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ImportJournalProcess
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ImportJournalProcess]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_ImportJournalProcess.'
	Drop procedure [dbo].[ip_ImportJournalProcess]
End
Print '**** Creating Stored Procedure dbo.ip_ImportJournalProcess...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO

CREATE PROCEDURE dbo.ip_ImportJournalProcess
			@pnUserIdentityId	int		= null,	-- User in the Workbench system
			@psCulture		nvarchar(10)	= null, -- the language in which output is to be expressed
			@pnBatchNo		int,
			@pbPoliceImmediately	bit		= null	-- indicates that Policing should run on completion
AS
-- PROCEDURE :	ip_ImportJournalProcess
-- VERSION :	39
-- DESCRIPTION:	Process the import journal batch that was previously loaded.
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 22 Mar 2004	MF	9627	1	Process a previously loaded Import Journal Batch.
-- 02 Apr 2004	MF	7754	2	Allow the VALIDATEONLYFLAG to have a value of 2 to indicate
--					that Validation should occur if the data exists within Inproma
--					otherwise the record will be used to update the Case.
-- 05 Apr 2004	MF	9627	3	Need to handle Event Text that exceed 254 characters.
-- 06 Apr 2004	MF		4	Extend the transactions to cater for the creation of information
--					against a Case for Cases that have been created through the import.
-- 16 May 2004	MF	9034	5	Allow for the creation of Names associated with a newly created Case.
-- 16 Jun 2004	MF	10183	6	Insert CaseEvent for Event -13 (Date of Entry) when a Case is created.
-- 16 Nov 2004	RCT		7	Correct error in where clause of EVENTTEXT transaction failed data comparison update
-- 16 Nov 2004	MF	RFC2184	8	Performance problems with table variables on extremely large import batch.
--					Change to temporary table.
-- 14 Jan 2005	MF	10868	9	Allow the creation of Names and RelatedCases against Cases that previously
--					existed
-- 18 Jan 2005	MF	10882	10	Problem with Insert of JOURNAL row.  Need to ensure that no previous 
--					identical JOURNAL row had already been inserted.
-- 20 Jan 2005	MF	10882	11	Add DISTINCT to insert into JOURNAL to cater for the possibility of multiple
--					Journal transactions in the one batch.
-- 15 Mar 2005	MF	11152	12	If an ACTION is specified with an EVENT DATE, DUE DATE or EVENT TEXT transaction
--					then the system will cause the OPENACTION row to be inserted and/or opened for
--					that Action.
-- 15 Mar 2005	MF	11157	13	Validation is only required against Cases that already exist on the database.
--					Do not validate Cases that are being loaded from the Import Journal.
-- 16 Mar 2005	MF	11161	14	The CASEEVENT rows should only have the ImportBatchNo column set if there are
--					any transactions in the batch that were rejected.
-- 17 Mar 2005	MF	11167	15	Increase TRANSACTIONNO to INT
-- 04 Apr 2005	MF	11232	16	Update the CaseEvent when a related case is imported with a relationship
--					that is associated with an EventNo.
-- 08 Apr 2005	MF	11232	17	Rework of 11232 due to error when no EventNo associated with Relationship.
-- 15 Apr 2005	AB	11271	18	Collation conflict caused by stored procedures
-- 13 May 2005	MF	8748	19	New Transactions created for Entity Size, Number of Claims, Designated States,
--					Reference Number, and Estimated Charge
-- 06 Jul 2005	CR	11487	20	changed datalength(I.TEXTDATA)>254 to datalength(I.TEXTDATA)>508
-- 19 Jul 2005	MF	11641	21	Allow multiple CASETEXT rows for a single Case to be inserted without
--					causing a duplicate key error.
--					Allow Type Of Mark to be an update transaction.
--					Create a new CASE OFFICE transaction
-- 21 Jul 2005	MF	11641	22	Revisit to correct test failure.
-- 04 Oct 2005	MF	11933	23	Allow the specific CLASS to be pass as part of the TEXT transaction.
-- 11 Nov 2005	MF	12051	24	A cyclic Event is to be allowed to open an OPENACTION of cycle 1 if the 
--					Action is defined as being non cyclic.
-- 17 Nov 2005	MF	12051	25	Also ensure the CURRENTOFFICIALNO of the Case is updated if there are any
--					transactions that result in the new OfficialNumbers being added against the
--					Case.
-- 28 Feb 2007	PY	14425 	26 	Reserved word [sequence]
-- 30 Jul 2007	MF	15082	27	CASETEXT rows are automatically inserted by a Case trigger if there are classes
--					against the Case.  This was causing rejection of transactions that had the
--					validate or update flag (VALIDATEONLYFLAG=2) set.
-- 06 Aug 2007	MF	15082	28	Extend to work with Text Types other than 'G'
-- 06 Aug 2007	MF	15082	29	Set the TEXTNO to zero for new rows.
-- 08 Oct 2007	MF	15439	30	Allow for the possibility of multiple transactions that impact CASEEVENT where
--					the Next Cycle is being calculated.  If the dates involved are different then the
--					cycle needs to increment for each different transaction.  Currently only the last
--					transaction is being considered.
-- 19 Dec 2007	MF	15760	31	The IRN is not allowed to be NULL. Assign a value of <Generate Reference> as
--					an interim measure until the IRN is determined.
-- 15 Jan 2008  Dw	9782	32	Tax No moved from Organisation to Name table.
-- 11 Dec 2008	MF	17136	33	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 24 Jul 2009	MF	16548	34	The FROMEVENTNO will now identify the Event from a related Case that will be pushed
--					into the child Case.
-- 18 Mar 2010	MF	18557	35	Revisit of 16548 to correct problem as the Group By should have remained as CR.EVENTNO instead of CR.FROMEVENTNO.
-- 05 Jul 2013	vql	R13629	36	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 16 Apr 2015	MF	46129	37	Clear out previously generated IRN before calling cs_ApplyGeneratedReference. Problem caused by RFC28144.
-- 20 Oct 2015  MS      R53933  38      Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols
-- 14 Nov 2018  AV  75198/DR-45358	39   Date conversion errors when creating cases and opening names in Chinese DB
--
-- The transactions that have been catered for are as follows :
--	CASE OFFICE
-- 	CLASS TYPE 
--	DESIGNATED STATES
--	DUE DATE 
--	ENTITY SIZE
--	ESTIMATED CHARGE
--	EVENT DATE 
--	EVENT TEXT
--	JOURNAL
--	LOCAL CLASSES
--	NAME
--	NAME ALIAS
--	NAME COUNTRY
--	NAME STATE
--	NAME VAT NO
--	NUMBER OF CLAIMS
--	NUMBER TYPE
--	REFERENCE NUMBER
--	RELATED COUNTRY
--	RELATED DATE
--	RELATED NUMBER
--	TEXT
--	TITLE
--	TYPE OF MARK


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET ANSI_WARNINGS OFF	-- normally not recommended however required in this situation

create table #TEMPOPENACTION  (	CASEID		int		NOT NULL,
				ACTION		nvarchar(2)	collate database_default NOT NULL,
				CYCLE		int		NOT NULL,
				SEQUENCENO	int		identity(-1,-1)
				)

create table #TEMPCASEEVENT  (	CASEID		int		NOT NULL,
				EVENTNO		int		NOT NULL,
				CYCLE		int		NOT NULL,
				TRANSACTIONNO	int		NOT NULL,
				ACTION		nvarchar(2)	collate database_default NULL,
				EVENTDATE	datetime	NULL,
				EVENTDUEDATE	datetime	NULL,
				EVENTTEXT	nvarchar(254) 	collate database_default NULL,
				LONGFLAG	decimal(1,0)	NULL,
				EVENTLONGTEXT	text		collate database_default NULL,
				JOURNALNO	nvarchar(20)  	collate database_default NULL,
				TRANTYPE	nvarchar(20)	collate database_default NULL
				)

-- A non unique index is used because it is possible
-- for an event to be calculated from two different
-- actions.  When this occurs we allow the rows to be
-- inserted however one of them is then removed.

create index XPKTEMPCASEEVENT ON #TEMPCASEEVENT
				(CASEID)

create table #TEMPACTIVITYHISTORY (
				CASEID			int		NOT NULL,
				CYCLE			smallint	NULL,
				RATENO			int		NOT NULL,
				UNIQUEID		int		identity(0,3),
				DISBCURRENCY		nvarchar(3)  	collate database_default NULL,
				DISBEXCHANGERATE	decimal(11,4)	NULL,
				SERVICECURRENCY		nvarchar(3)  	collate database_default NULL,
				SERVEXCHANGERATE	decimal(11,4)	NULL,
				BILLCURRENCY		nvarchar(3)  	collate database_default NULL,
				BILLEXCHANGERATE	decimal(11,4)	NULL,
				DISBAMOUNT		decimal(11,2)	NULL,
				SERVICEAMOUNT		decimal(11,2)	NULL,
				DISBORIGINALAMOUNT	decimal(11,2)	NULL,
				SERVORIGINALAMOUNT	decimal(11,2)	NULL,
				DISBBILLAMOUNT		decimal(11,2)	NULL,
				SERVBILLAMOUNT		decimal(11,2)	NULL,
				ESTIMATEFLAG		decimal(1,0)	NULL,
				IDENTITYID		int		NULL,
				DEBTOR			int		NULL,
				SEPARATEDEBTORFLAG	decimal(1,0)	NULL )

create index XPKTEMPACTIVITYHISTORY ON #TEMPACTIVITYHISTORY
				(CASEID,
				 CYCLE,
				 RATENO)

declare @nErrorCode 		int,
	@nRowCount		int,
	@nTranCountStart 	int,
	@nFailedCount		int,
	@nBatchCount		int,
	@nBatchNo   		int,
	@nRejectCount		int,
	@nBatchHeaderCount	int,
	@nCaseOfficeCount	int,
	@nClassTypeCount	int,
	@nDueDateCount  	int,
	@nEntitySizeCount	int,
	@nEstimatedChargeCount	int,
	@nNumberOfClaimsCount	int,
	@nDesignatedStatesCount	int,
	@nReferenceNumberCount	int,
	@nEventDateCount	int,
	@nEventTextCount	int,
	@nJournalCount  	int,
	@nLocalClassesCount	int,
	@nNameCount		int,
	@nNameAliasCount	int,
	@nNameCountryCount	int,
	@nNameStateCount	int,
	@nNameVATNoCount	int,
	@nNameCreateCount	int,
	@nNumberTypeCount	int,
	@nRelatedCountryCount	int,
	@nRelatedDateCount	int,
	@nRelatedNumberCount	int,
	@nRelationCreateCount	int,
	@nTextCount		int,
	@nTitleCount		int,
	@nTypeOfMarkCount	int,
	@nNewCasesRecords	int,
	@nPolicingBatchNo	int,
	@nTransactionNo		int,
	@sStates		nvarchar(600)


declare @nEventNo		int
declare @nCycle			smallint
declare @nCaseId		int
declare	@sIRN			nvarchar(30)

declare	@sSQLString 		nvarchar(4000)
declare	@dtCurrentDateTime	datetime

-- Initialise the errorcode and then set it after each SQL Statement
Set @nErrorCode=0
Set @nRowCount =0

-- First check that there are rows to process
-- and keep a count of each different type of transaction
If @nErrorCode=0
Begin
	set @sSQLString="
		SELECT @nBatchCount    =count(1),
		@nBatchHeaderCount     =SUM(CASE WHEN(I.TRANSACTIONTYPE='BATCH HEADER')     THEN 1 ELSE 0 END),
		@nCaseOfficeCount      =SUM(CASE WHEN(I.TRANSACTIONTYPE='CASE OFFICE')      THEN 1 ELSE 0 END),
		@nClassTypeCount       =SUM(CASE WHEN(I.TRANSACTIONTYPE='CLASS TYPE')       THEN 1 ELSE 0 END),
		@nDueDateCount         =SUM(CASE WHEN(I.TRANSACTIONTYPE='DUE DATE')         THEN 1 ELSE 0 END),
		@nEntitySizeCount      =SUM(CASE WHEN(I.TRANSACTIONTYPE='ENTITY SIZE')      THEN 1 ELSE 0 END),
		@nEstimatedChargeCount =SUM(CASE WHEN(I.TRANSACTIONTYPE='ESTIMATED CHARGE') THEN 1 ELSE 0 END),
		@nNumberOfClaimsCount  =SUM(CASE WHEN(I.TRANSACTIONTYPE='NUMBER OF CLAIMS') THEN 1 ELSE 0 END),
		@nDesignatedStatesCount=SUM(CASE WHEN(I.TRANSACTIONTYPE='DESIGNATED STATES')THEN 1 ELSE 0 END),
		@nReferenceNumberCount =SUM(CASE WHEN(I.TRANSACTIONTYPE='REFERENCE NUMBER') THEN 1 ELSE 0 END),
		@nEventDateCount       =SUM(CASE WHEN(I.TRANSACTIONTYPE='EVENT DATE')       THEN 1 ELSE 0 END),
		@nEventTextCount       =SUM(CASE WHEN(I.TRANSACTIONTYPE='EVENT TEXT')       THEN 1 ELSE 0 END),
		@nJournalCount         =SUM(CASE WHEN(I.TRANSACTIONTYPE='JOURNAL')          THEN 1 ELSE 0 END),
		@nLocalClassesCount    =SUM(CASE WHEN(I.TRANSACTIONTYPE='LOCAL CLASSES')    THEN 1 ELSE 0 END),
		@nNameCount            =SUM(CASE WHEN(I.TRANSACTIONTYPE='NAME')             THEN 1 ELSE 0 END),
		@nNameAliasCount       =SUM(CASE WHEN(I.TRANSACTIONTYPE='NAME ALIAS')       THEN 1 ELSE 0 END),
		@nNameCountryCount     =SUM(CASE WHEN(I.TRANSACTIONTYPE='NAME COUNTRY')     THEN 1 ELSE 0 END),
		@nNameStateCount       =SUM(CASE WHEN(I.TRANSACTIONTYPE='NAME STATE')       THEN 1 ELSE 0 END),
		@nNameVATNoCount       =SUM(CASE WHEN(I.TRANSACTIONTYPE='NAME VAT NO')      THEN 1 ELSE 0 END),
		@nNumberTypeCount      =SUM(CASE WHEN(I.TRANSACTIONTYPE='NUMBER TYPE')      THEN 1 ELSE 0 END),
		@nRelatedCountryCount  =SUM(CASE WHEN(I.TRANSACTIONTYPE='RELATED COUNTRY')  THEN 1 ELSE 0 END),
		@nRelatedDateCount     =SUM(CASE WHEN(I.TRANSACTIONTYPE='RELATED DATE')     THEN 1 ELSE 0 END),
		@nRelatedNumberCount   =SUM(CASE WHEN(I.TRANSACTIONTYPE='RELATED NUMBER')   THEN 1 ELSE 0 END),
		@nTextCount            =SUM(CASE WHEN(I.TRANSACTIONTYPE='TEXT')             THEN 1 ELSE 0 END),
		@nTitleCount           =SUM(CASE WHEN(I.TRANSACTIONTYPE='TITLE')            THEN 1 ELSE 0 END),
		@nTypeOfMarkCount      =SUM(CASE WHEN(I.TRANSACTIONTYPE='TYPE OF MARK')     THEN 1 ELSE 0 END),
		@nNewCasesRecords      =SUM(CASE WHEN(C.IRN ='<Generate Reference>')        THEN 1 ELSE 0 END),
		@nNameCreateCount      =SUM(CASE WHEN(I.TRANSACTIONTYPE like 'NAME%'
				  		  and I.VALIDATEONLYFLAG in (0,2))          THEN 1 ELSE 0 END),
		@nRelationCreateCount  =SUM(CASE WHEN(I.TRANSACTIONTYPE like 'RELATED %'
					 	  and I.VALIDATEONLYFLAG in (0,2))          THEN 1 ELSE 0 END)
		FROM IMPORTJOURNAL I
		join CASES C	on (C.CASEID=I.CASEID)
		where IMPORTBATCHNO=@pnBatchNo
		and REJECTREASON is NULL
		and isnull(PROCESSEDFLAG,0)=0"

	Exec @nErrorCode=sp_executesql @sSQLString, 
					N'@nBatchCount			int	OUTPUT,
					  @nBatchHeaderCount		int	OUTPUT,
					  @nCaseOfficeCount		int	OUTPUT,
					  @nClassTypeCount		int	OUTPUT,
					  @nDueDateCount  		int	OUTPUT,
					  @nEventDateCount		int	OUTPUT,
					  @nEventTextCount		int	OUTPUT,
					  @nJournalCount  		int	OUTPUT,
					  @nLocalClassesCount		int	OUTPUT,
					  @nNameCount			int	OUTPUT,
					  @nNameAliasCount		int	OUTPUT,
					  @nNameCountryCount		int	OUTPUT,
					  @nNameStateCount		int	OUTPUT,
					  @nNameVATNoCount		int	OUTPUT,
					  @nNumberTypeCount		int	OUTPUT,
					  @nRelatedCountryCount		int	OUTPUT,
					  @nRelatedDateCount		int	OUTPUT,
					  @nRelatedNumberCount		int	OUTPUT,
					  @nTextCount			int	OUTPUT,
					  @nTitleCount			int	OUTPUT,
					  @nTypeOfMarkCount		int	OUTPUT,
					  @nNameCreateCount		int	OUTPUT,
					  @nRelationCreateCount		int	OUTPUT,
					  @nNewCasesRecords		int	OUTPUT,
					  @nEntitySizeCount		int	OUTPUT,
					  @nEstimatedChargeCount	int	OUTPUT,
					  @nNumberOfClaimsCount		int	OUTPUT,
					  @nDesignatedStatesCount	int	OUTPUT,
					  @nReferenceNumberCount	int	OUTPUT,
					  @pnBatchNo			int	OUTPUT',
					  @nBatchCount			=@nBatchCount 		OUTPUT,
					  @nBatchHeaderCount		=@nBatchHeaderCount	OUTPUT,
					  @nCaseOfficeCount		=@nCaseOfficeCount	OUTPUT,
					  @nClassTypeCount		=@nClassTypeCount	OUTPUT,
					  @nDueDateCount  		=@nDueDateCount		OUTPUT,
					  @nEventDateCount		=@nEventDateCount	OUTPUT,
					  @nEventTextCount		=@nEventTextCount	OUTPUT,
					  @nJournalCount  		=@nJournalCount		OUTPUT,
					  @nLocalClassesCount		=@nLocalClassesCount	OUTPUT,
					  @nNameCount			=@nNameCount		OUTPUT,
					  @nNameAliasCount		=@nNameAliasCount	OUTPUT,
					  @nNameCountryCount		=@nNameCountryCount	OUTPUT,
					  @nNameStateCount		=@nNameStateCount	OUTPUT,
					  @nNameVATNoCount		=@nNameVATNoCount	OUTPUT,
					  @nNumberTypeCount		=@nNumberTypeCount	OUTPUT,
					  @nRelatedCountryCount		=@nRelatedCountryCount	OUTPUT,
					  @nRelatedDateCount		=@nRelatedDateCount	OUTPUT,
					  @nRelatedNumberCount		=@nRelatedNumberCount	OUTPUT,
					  @nTextCount			=@nTextCount		OUTPUT,
					  @nTitleCount			=@nTitleCount		OUTPUT,
					  @nTypeOfMarkCount		=@nTypeOfMarkCount	OUTPUT,
					  @nNameCreateCount		=@nNameCreateCount	OUTPUT,
					  @nRelationCreateCount 	=@nRelationCreateCount	OUTPUT,
					  @nNewCasesRecords		=@nNewCasesRecords	OUTPUT,
					  @nEntitySizeCount		=@nEntitySizeCount	OUTPUT,
					  @nEstimatedChargeCount	=@nEstimatedChargeCount	OUTPUT,
					  @nNumberOfClaimsCount		=@nNumberOfClaimsCount	OUTPUT,
					  @nDesignatedStatesCount	=@nDesignatedStatesCount OUTPUT,
					  @nReferenceNumberCount	=@nReferenceNumberCount	OUTPUT,
					  @pnBatchNo 			=@pnBatchNo

	If @nBatchCount = 0
	Begin
		RAISERROR("There are no unprocessed transactions to process.", 16, 1)
		Set @nErrorCode	  = @@Error
	End
End

-- For each new Case created rows are to be inserted into CASEEVENT
-- to indicate when the Case was created and last updated.

If @nNewCasesRecords>0
and @nErrorCode=0
Begin
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	Set @sSQLString="
	insert into CASEEVENT(CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG)
	Select	distinct I.CASEID, E.EVENTNO, 1, convert(nvarchar, getdate(), 112), 1
	from IMPORTJOURNAL I
	join CASES C		on (C.CASEID=I.CASEID)
	join EVENTS E		on (E.EVENTNO in (-13, -14))
	left join CASEEVENT CE	on (CE.CASEID=I.CASEID
				and CE.EVENTNO=E.EVENTNO
				and CE.CYCLE=1)
	where I.IMPORTBATCHNO=@pnBatchNo
	and I.REJECTREASON is NULL
	and C.IRN='<Generate Reference>'
	and isnull(I.PROCESSEDFLAG,0)=0
	and CE.CASEID is NULL"

	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo=@pnBatchNo

	-- Commit entire transaction if successful
	If @@TranCount > @nTranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

-- If there are any Names to create or link to newly created Cases call procedure

If  @nNameCreateCount>0
and @nErrorCode=0
Begin
	Exec @nErrorCode=ip_ImportJournalNames
					@pnBatchNo
End

-- If there are any Case Relationships to create then call procedure

If  @nRelationCreateCount>0
and @nErrorCode=0
Begin
	Exec @nErrorCode=ip_ImportJournalRelatedCases
					@pnBatchNo
End

-- Generate a batch number to be used on all of the Policing Transactions being inserted
-- if the Police Immediately option has been set on.
If  @nErrorCode=0
and @nBatchCount>0
and @pbPoliceImmediately=1
Begin
	-- A very short transaction is required to get the next Batchno as we must keep any
	-- locks against the LASTINTERNALCODE table as short as possible.

	Select @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Generate the batch no by updating the LastInternalCode and selecting it.
	If @nErrorCode=0
	Begin
		set @sSQLString="
			UPDATE LASTINTERNALCODE 
			SET INTERNALSEQUENCE = INTERNALSEQUENCE + 1,
			    @nPolicingBatchNo= INTERNALSEQUENCE + 1
			WHERE  TABLENAME = 'POLICINGBATCH'"

		Exec @nErrorCode=sp_executesql @sSQLString, 
						N'@nPolicingBatchNo		int	OUTPUT',
						  @nPolicingBatchNo=@nPolicingBatchNo	OUTPUT
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


-- TransactionType ===> BATCH HEADER

If  @nBatchHeaderCount>0
and @nErrorCode=0
Begin
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	If @nErrorCode=0
	Begin

		Set @sSQLString="
		Update IMPORTJOURNAL
		Set PROCESSEDFLAG=1
		from IMPORTJOURNAL I
		join CASES C		on (C.CASEID=I.CASEID)
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='BATCH HEADER'
		and isnull(I.PROCESSEDFLAG,0)=0
		and I.REJECTREASON is NULL"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
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


-- TransactionType ===> CLASS TYPE
-- Note that this is a validate only transaction

If  @nClassTypeCount>0
and @nErrorCode=0
Begin
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Update the transactions that have failed the data comparison
	Set @sSQLString="
	Update IMPORTJOURNAL
	Set PROCESSEDFLAG=0,
	    REJECTREASON='Type of Class does not match against Case'
	from IMPORTJOURNAL I
	join CASES C		on (C.CASEID=I.CASEID)
	Where I.IMPORTBATCHNO=@pnBatchNo
	and I.TRANSACTIONTYPE='CLASS TYPE'
	and isnull(I.PROCESSEDFLAG,0)=0
	and C.IRN<>'<Generate Reference>'	-- indicates the Case already exists
	and not exists
	(select * from CASETEXT CT
	 join TMCLASS TM on (TM.CLASS=CT.CLASS
			 and TM.COUNTRYCODE=(	select min(COUNTRYCODE)
						from TMCLASS TM1
						where TM1.COUNTRYCODE in ('ZZZ',C.COUNTRYCODE)))
	 where CT.CASEID=C.CASEID
	 and CT.TEXTTYPE='G'
	 and TM.GOODSSERVICES=I.CHARACTERDATA)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo=@pnBatchNo
	Set @nFailedCount=@@Rowcount

	If  @nErrorCode=0
	and @nFailedCount>0
	Begin
		exec @nErrorCode=ip_ImportJournalError	@pnUserIdentityId=@pnUserIdentityId,
							@psCulture=@psCulture,
							@pnBatchNo=@pnBatchNo,
							@pnPolicingBatchNo=@nPolicingBatchNo,
							@psTransType='CLASS TYPE'
	End

	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update IMPORTJOURNAL
		Set PROCESSEDFLAG=1,
		    REJECTREASON=NULL,
		    ERROREVENTNO=NULL
		from IMPORTJOURNAL I
		join CASES C		on (C.CASEID=I.CASEID)
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='CLASS TYPE'
		and isnull(I.PROCESSEDFLAG,0)=0
		and exists
		(select * from CASETEXT CT
		 join TMCLASS TM on (TM.CLASS=CT.CLASS
				 and TM.COUNTRYCODE=(	select min(COUNTRYCODE)
							from TMCLASS TM1
							where TM1.COUNTRYCODE in ('ZZZ',C.COUNTRYCODE)))
		 where CT.CASEID=C.CASEID
		 and CT.TEXTTYPE='G'
		 and TM.GOODSSERVICES=I.CHARACTERDATA)"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
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

-- TransactionType ===> DESIGNATED STATES

If  @nDesignatedStatesCount>0
and @nErrorCode=0
Begin
	-- Loop through each Designated State transaction which will contain a comma separated 
	-- list of Designated Countries.  Each Country will then be used to create a Related Case
	-- entry.

	Set @sSQLString="
	Select	@nTransactionNo=I.TRANSACTIONNO,
		@sStates=I.CHARACTERDATA
	from IMPORTJOURNAL I
	where I.IMPORTBATCHNO=@pnBatchNo
	and I.TRANSACTIONNO=(	select min(I2.TRANSACTIONNO)
				from IMPORTJOURNAL I2
				where I2.IMPORTBATCHNO=@pnBatchNo
				and I2.TRANSACTIONTYPE='DESIGNATED STATES'
				and I2.CHARACTERDATA is not null)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nTransactionNo	int		OUTPUT,
					  @sStates		nvarchar(600)	OUTPUT,
					  @pnBatchNo		int',
					  @nTransactionNo=@nTransactionNo	OUTPUT,
					  @sStates=@sStates			OUTPUT,
					  @pnBatchNo=@pnBatchNo

	WHILE @sStates is not null
	and @nErrorCode=0
	Begin

		Set @nTranCountStart = @@TranCount
		BEGIN TRANSACTION
	
		-- Update the transactions that have failed the data comparison
		-- Check where the Designated State in the import transaction does
		-- not exist against the Case.
		Set @sSQLString="
		Update IMPORTJOURNAL
		Set PROCESSEDFLAG=0,
		    REJECTREASON='Designated State(s) mismatches with Case'
		from IMPORTJOURNAL I
		join CASES C	on (C.CASEID=I.CASEID)
		cross join dbo.fn_Tokenise(@sStates,',') T
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONNO=@nTransactionNo
		and I.TRANSACTIONTYPE='DESIGNATED STATES'
		and isnull(I.PROCESSEDFLAG,0)=0
		and I.VALIDATEONLYFLAG=1 -- if ValidateOnlyFlag is 2 then Designated State will be added if it does not exist
		and C.IRN<>'<Generate Reference>'	-- indicates the Case already exists
		and not exists
		(select * 
		 from RELATEDCASE R	
		 where R.CASEID=I.CASEID
		 and R.RELATIONSHIP='DC1'
		 and R.COUNTRYCODE=T.Parameter)"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int,
						  @nTransactionNo	int,
						  @sStates		nvarchar(600)',
						  @pnBatchNo=@pnBatchNo,
						  @nTransactionNo=@nTransactionNo,
						  @sStates=@sStates
		Set @nFailedCount=@@Rowcount
	
		If @nErrorCode=0
		Begin
			-- Update the transactions that have failed the data comparison
			-- This is where there are more Designated States against the Case than 
			-- in the imported transaction.
			Set @sSQLString="
			Update IMPORTJOURNAL
			Set PROCESSEDFLAG=0,
			    REJECTREASON='Designated State(s) mismatches with Case'
			from IMPORTJOURNAL I
			join CASES C		on (C.CASEID=I.CASEID)
			join RELATEDCASE R	on (R.CASEID=I.CASEID
						and R.RELATIONSHIP='DC1')
			Where I.IMPORTBATCHNO=@pnBatchNo
			and I.TRANSACTIONNO=@nTransactionNo
			and I.TRANSACTIONTYPE='DESIGNATED STATES'
			and isnull(I.PROCESSEDFLAG,0)=0
			and I.VALIDATEONLYFLAG in (1,2) -- if ValidateOnlyFlag is 2 then Designated State will be added if it does not exist
			and C.IRN<>'<Generate Reference>'	-- indicates the Case already exists
			and not exists
			(select * 
			 from dbo.fn_Tokenise(@sStates,',') T
			 where T.Parameter=R.COUNTRYCODE)"
		
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @nTransactionNo	int,
							  @sStates		nvarchar(600)',
							  @pnBatchNo=@pnBatchNo,
							  @nTransactionNo=@nTransactionNo,
							  @sStates=@sStates
			Set @nFailedCount=@nFailedCount+@@Rowcount
		End
	
		If  @nErrorCode=0
		and @nFailedCount>0
		Begin
			exec @nErrorCode=ip_ImportJournalError	@pnUserIdentityId=@pnUserIdentityId,
								@psCulture=@psCulture,
								@pnBatchNo=@pnBatchNo,
								@pnPolicingBatchNo=@nPolicingBatchNo,
								@psTransType='DESIGNATED STATES'
		End
	
		-- Insert Designated Country rows if the transaction is not Validate Only
	
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Insert into RELATEDCASE(CASEID, RELATIONSHIPNO, RELATIONSHIP, COUNTRYCODE, COUNTRYFLAGS, CURRENTSTATUS)
			Select I.CASEID, isnull(R1.RELATIONSHIPNO,0)+T.InsertOrder, 'DC1', T.Parameter, F.FLAGNUMBER, F.FLAGNUMBER
			from IMPORTJOURNAL I
			join CASES C		on (C.CASEID=I.CASEID)
			cross join dbo.fn_Tokenise(@sStates,',') T
			left join RELATEDCASE R	on (R.CASEID=I.CASEID
						and R.RELATIONSHIP='DC1'
						and R.COUNTRYCODE=T.Parameter)
			left join (	select CASEID, max(RELATIONSHIPNO) as RELATIONSHIPNO
					from RELATEDCASE
					group by CASEID) R1	on (R1.CASEID=I.CASEID)
			left join COUNTRYFLAGS F		on (F.COUNTRYCODE=C.COUNTRYCODE
								and F.FLAGNUMBER=I.INTEGERDATA)
			where I.IMPORTBATCHNO=@pnBatchNo
			and I.TRANSACTIONNO=@nTransactionNo
			and I.TRANSACTIONTYPE='DESIGNATED STATES'
			and isnull(I.PROCESSEDFLAG,0)=0
			and isnull(I.VALIDATEONLYFLAG,0) in (0,2)
			and I.REJECTREASON is null
			and R.CASEID is null"
		
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @nTransactionNo	int,
							  @sStates		nvarchar(600)',
							  @pnBatchNo=@pnBatchNo,
							  @nTransactionNo=@nTransactionNo,
							  @sStates=@sStates
		End
	
		-- Update the valid transactions to indicate they have been processed.
		-- This includes both the Validate Only transactions and the ones that have just
		-- performed the update.
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Update IMPORTJOURNAL
			Set PROCESSEDFLAG=1,
			    REJECTREASON=NULL,
			    ERROREVENTNO=NULL
			from IMPORTJOURNAL I
			cross join dbo.fn_Tokenise(@sStates,',') T
			Where I.IMPORTBATCHNO=@pnBatchNo
			and I.TRANSACTIONNO=@nTransactionNo
			and I.TRANSACTIONTYPE='DESIGNATED STATES'
			and isnull(I.PROCESSEDFLAG,0)=0
			and exists
			(select * from RELATEDCASE R
			 where R.CASEID=I.CASEID
			 and R.RELATIONSHIP='DC1'
			 and R.COUNTRYCODE=T.Parameter)"
		
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @nTransactionNo	int,
							  @sStates		nvarchar(600)',
							  @pnBatchNo=@pnBatchNo,
							  @nTransactionNo=@nTransactionNo,
							  @sStates=@sStates
		End
	
		-- Commit entire transaction if successful
		If @@TranCount > @nTranCountStart
		Begin
			If @nErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End

		-- Get the next Designated States transaciton
		-- are valid
		Set @sStates=NULL

		Set @sSQLString="
		Select	@nTransactionNo=I.TRANSACTIONNO,
			@sStates=I.CHARACTERDATA
		from IMPORTJOURNAL I
		where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONNO=(	select min(I2.TRANSACTIONNO)
					from IMPORTJOURNAL I2
					where I2.IMPORTBATCHNO=@pnBatchNo
					and I2.TRANSACTIONTYPE='DESIGNATED STATES'
					and I2.CHARACTERDATA is not null
					and I2.TRANSACTIONNO>@nTransactionNo)"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nTransactionNo	int		OUTPUT,
						  @sStates		nvarchar(600)	OUTPUT,
						  @pnBatchNo		int',
						  @nTransactionNo=@nTransactionNo	OUTPUT,
						  @sStates=@sStates			OUTPUT,
						  @pnBatchNo=@pnBatchNo

	End -- End of Designated State transaction loop
End



-- TransactionType ===> ESTIMATED CHARGE
-- Import only

If  @nEstimatedChargeCount>0
and @nErrorCode=0
Begin
	-- Insert the ESTIMATED CHARGE data into the ACTIVITYHISTORY

	If @nErrorCode=0
	Begin
		-- Create a temporary ACTIVITYHISTORY row where there is a Service Charge and also get the matching
		-- disbursement if it exists.
		Set @sSQLString="
		Insert into #TEMPACTIVITYHISTORY(CASEID, CYCLE, RATENO, 
						 DISBCURRENCY, DISBEXCHANGERATE, 
						 SERVICECURRENCY, SERVEXCHANGERATE, BILLCURRENCY, BILLEXCHANGERATE,
						 DISBAMOUNT, SERVICEAMOUNT, DISBORIGINALAMOUNT, SERVORIGINALAMOUNT,
						 DISBBILLAMOUNT, SERVBILLAMOUNT)
		select	I.CASEID,
			CASE WHEN(R.RATETYPE=1601) THEN I.INTEGERDATA END, --CYCLE
			R.RATENO, 
			C1.CURRENCY,		--DISBCURRENCY
			isnull(C1.SELLRATE,1),	--DISBEXCHANGERATE
			C.CURRENCY, 		--SERVICECURRENCY
			isnull(C.SELLRATE,1),	--SERVEXCHANGERATE
			C2.CURRENCY,		--BILLCURRENCY
			isnull(C2.SELLRATE,1),	--BILLEXCHANGERATE

			-- Calulate the disbursement in the home currency
			CASE WHEN(C1.CURRENCY=S1.COLCHARACTER OR C1.CURRENCY is null)
				THEN I1.DECIMALDATA	-- Home currency same as disbursement currency
			     WHEN(S.COLBOOLEAN=1)
				THEN Round((I1.DECIMALDATA/isnull(C1.SELLRATE,1)), 0)	-- Rounding required
				ELSE I1.DECIMALDATA/isnull(C1.SELLRATE,1)
			END,		--DISBAMOUNT, 

			-- Calculate the service charge in the home currency
			CASE WHEN(C.CURRENCY=S1.COLCHARACTER OR C.CURRENCY is null)
				THEN I.DECIMALDATA	-- Home currency same as service currency
			     WHEN(S.COLBOOLEAN=1)
				THEN Round((I.DECIMALDATA/isnull(C.SELLRATE,1)), 0)	-- Rounding required
				ELSE I.DECIMALDATA/isnull(C.SELLRATE,1)
			END,		--SERVICEAMOUNT

			I1.DECIMALDATA,	--DISBORIGINALAMOUNT, 
			I.DECIMALDATA,	--SERVORIGINALAMOUNT

			-- Calculate the disbursement in the billing currency
			CASE WHEN(C2.CURRENCY=C1.CURRENCY or (C2.CURRENCY is null and C1.CURRENCY is null))
				THEN I1.DECIMALDATA	-- Bill currency same as disbursement currency
			     WHEN(C2.ROUNDBILLEDVALUES=1)
				THEN Round((I1.DECIMALDATA/isnull(C1.SELLRATE,1))*C2.SELLRATE,0)
				ELSE (I1.DECIMALDATA/isnull(C1.SELLRATE,1))*C2.SELLRATE
			END,		--DISBBILLAMOUNT

			-- Calculate the service charge in the billing currency
			CASE WHEN(C2.CURRENCY=C.CURRENCY or (C2.CURRENCY is null and C.CURRENCY is null))
				THEN I.DECIMALDATA	-- Bill currency same as service charge currency
			     WHEN(C2.ROUNDBILLEDVALUES=1)
				THEN Round((I.DECIMALDATA/isnull(C.SELLRATE,1))*C2.SELLRATE,0)
				ELSE (I.DECIMALDATA/isnull(C.SELLRATE,1))*C2.SELLRATE
			END		--SERVBILLAMOUNT
		from IMPORTJOURNAL I
		join RATES R 			on (R.RATENO=I.NUMBERKEY)
		left join CURRENCY C		on (C.CURRENCY=I.CHARACTERKEY)
		left join SITECONTROL S		on (S.CONTROLID = 'Currency Whole Units')
		left join SITECONTROL S1	on (S1.CONTROLID= 'CURRENCY') -- get the home currency
		-- see if there is a Disbursement to pair with the Service charge
		left join IMPORTJOURNAL I1	on (I1.IMPORTBATCHNO=I.IMPORTBATCHNO
						and I1.CASEID=I.CASEID
						and I1.TRANSACTIONTYPE=I.TRANSACTIONTYPE
						and I1.CHARACTERDATA='D'
						and I1.NUMBERKEY=I.NUMBERKEY
						and isnull(I1.PROCESSEDFLAG,0)=0
						and isnull(I1.VALIDATEONLYFLAG,0) in (0,2)
						and I1.REJECTREASON is null)
		left join CURRENCY C1		on (C1.CURRENCY=I1.CHARACTERKEY)
		-- Get the Renewal Debtor for the case
		left join CASENAME CN		on (CN.CASEID=I.CASEID
						and CN.NAMETYPE='Z'
						and CN.EXPIRYDATE is null
						and CN.SEQUENCE=(select MIN(CN2.SEQUENCE)
								 from CASENAME CN2
								 where CN2.CASEID = CN.CASEID
								 and CN2.NAMETYPE = CN.NAMETYPE
								 and CN2.EXPIRYDATE is null))
		left join IPNAME IP		on (IP.NAMENO=CN.NAMENO)
		left join CURRENCY C2		on (C2.CURRENCY=IP.CURRENCY)

		where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='ESTIMATED CHARGE'
		and I.CHARACTERDATA='S' -- Service Charge
		and(C.CURRENCY is not null OR I.CHARACTERKEY is null) -- Currency must be valid
		and isnull(I.PROCESSEDFLAG,0)=0
		and isnull(I.VALIDATEONLYFLAG,0) in (0,2)
		and I.REJECTREASON is null"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
	End


	If @nErrorCode=0
	Begin
		-- Create a temporary ACTIVITYHISTORY row where there is a Disbursement but no
		-- service charge exists
		Set @sSQLString="
		Insert into #TEMPACTIVITYHISTORY(CASEID, CYCLE, RATENO, 
						 DISBCURRENCY, DISBEXCHANGERATE, 
						 BILLCURRENCY, BILLEXCHANGERATE,
						 DISBAMOUNT, DISBORIGINALAMOUNT,
						 DISBBILLAMOUNT)
		select	I.CASEID,
			CASE WHEN(R.RATETYPE=1601) THEN I.INTEGERDATA END, --CYCLE
			R.RATENO, 
			C.CURRENCY,		--DISBCURRENCY
			isnull(C.SELLRATE,1),	--DISBEXCHANGERATE
			C2.CURRENCY,		--BILLCURRENCY
			isnull(C2.SELLRATE,1),	--BILLEXCHANGERATE

			-- Calculate the service charge in the home currency
			CASE WHEN(C.CURRENCY=S1.COLCHARACTER OR C.CURRENCY is null)
				THEN I.DECIMALDATA	-- Home currency same as disbursement currency
			     WHEN(S.COLBOOLEAN=1)
				THEN Round((I.DECIMALDATA/isnull(C.SELLRATE,1)), 0)	-- Rounding required
				ELSE I.DECIMALDATA/isnull(C.SELLRATE,1)
			END,		--DISBAMOUNT

			I.DECIMALDATA,	--DISBORIGINALAMOUNT

			-- Calculate the service charge in the billing currency
			CASE WHEN(C2.CURRENCY=C.CURRENCY or (C2.CURRENCY is null and C.CURRENCY is null))
				THEN I.DECIMALDATA	-- Bill currency same as disbursement currency
			     WHEN(C2.ROUNDBILLEDVALUES=1)
				THEN Round((I.DECIMALDATA/isnull(C.SELLRATE,1))*C2.SELLRATE,0)
				ELSE (I.DECIMALDATA/isnull(C.SELLRATE,1))*C2.SELLRATE
			END		--DISBBILLAMOUNT
		from IMPORTJOURNAL I
		join RATES R 			on (R.RATENO=I.NUMBERKEY)
		left join CURRENCY C		on (C.CURRENCY=I.CHARACTERKEY)
		left join SITECONTROL S		on (S.CONTROLID = 'Currency Whole Units')
		left join SITECONTROL S1	on (S1.CONTROLID= 'CURRENCY') -- get the home currency
		-- see if there is a Disbursement to pair with the Service charge
		left join IMPORTJOURNAL I1	on (I1.IMPORTBATCHNO=I.IMPORTBATCHNO
						and I1.CASEID=I.CASEID
						and I1.TRANSACTIONTYPE=I.TRANSACTIONTYPE
						and I1.CHARACTERDATA='S'
						and I1.NUMBERKEY=I.NUMBERKEY
						and isnull(I1.PROCESSEDFLAG,0)=0
						and isnull(I1.VALIDATEONLYFLAG,0) in (0,2)
						and I1.REJECTREASON is null)
		-- Get the Renewal Debtor for the case
		left join CASENAME CN		on (CN.CASEID=I.CASEID
						and CN.NAMETYPE='Z'
						and CN.EXPIRYDATE is null
						and CN.SEQUENCE=(select MIN(CN2.SEQUENCE)
								 from CASENAME CN2
								 where CN2.CASEID = CN.CASEID
								 and CN2.NAMETYPE = CN.NAMETYPE
								 and CN2.EXPIRYDATE is null))
		left join IPNAME IP		on (IP.NAMENO=CN.NAMENO)
		left join CURRENCY C2		on (C2.CURRENCY=IP.CURRENCY)

		where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='ESTIMATED CHARGE'
		and I.CHARACTERDATA='D' -- Disbursement
		and(C.CURRENCY is not null OR I.CHARACTERKEY is null) -- Currency must be valid
		and isnull(I.PROCESSEDFLAG,0)=0
		and isnull(I.VALIDATEONLYFLAG,0) in (0,2)
		and I.REJECTREASON is null
		and I1.CASEID is null	-- indicates no Service charge found"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
	End

	-- Commence a transaction
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Now copy the temporary Activity History rows across to the live table
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Insert into ACTIVITYHISTORY(
			CASEID, WHENREQUESTED, SQLUSER, HOLDFLAG, PROGRAMID, CYCLE, ACTIVITYTYPE, 
		 	ACTIVITYCODE, PROCESSED, ESTIMATEFLAG, RATENO, DISBCURRENCY, DISBEXCHANGERATE, 
			SERVICECURRENCY, SERVEXCHANGERATE, BILLCURRENCY, BILLEXCHANGERATE,
			DISBAMOUNT, SERVICEAMOUNT, DISBORIGINALAMOUNT, SERVORIGINALAMOUNT,
			DISBBILLAMOUNT, SERVBILLAMOUNT, IDENTITYID)
		select	T.CASEID,
			dateadd(ms, T.UNIQUEID, getdate()), -- ensure each row has a unique time stamp
			SYSTEM_USER,
			0,
			'Import',
			T.CYCLE,
			32, 
			3202, 
			1,
			1,
			T.RATENO,
			T.DISBCURRENCY, T.DISBEXCHANGERATE, 
			T.SERVICECURRENCY, T.SERVEXCHANGERATE, T.BILLCURRENCY, T.BILLEXCHANGERATE,
			T.DISBAMOUNT, T.SERVICEAMOUNT, T.DISBORIGINALAMOUNT, T.SERVORIGINALAMOUNT,
			T.DISBBILLAMOUNT, T.SERVBILLAMOUNT,@pnUserIdentityId
		from #TEMPACTIVITYHISTORY T"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnUserIdentityId	int',
						  @pnUserIdentityId=@pnUserIdentityId
	End

	-- Update the valid transactions to indicate they have been processed.
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update IMPORTJOURNAL
		Set PROCESSEDFLAG=1,
		    REJECTREASON=NULL,
		    ERROREVENTNO=NULL
		from IMPORTJOURNAL I
		join RATES R			on (R.RATENO=I.NUMBERKEY)
		join #TEMPACTIVITYHISTORY T	on (T.CASEID=I.CASEID
						and T.RATENO=R.RATENO
						and( T.CYCLE=I.INTEGERDATA 
						 or (T.CYCLE is null and I.INTEGERDATA is null)
						 or  isnull(R.RATETYPE,0)<>1601))
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='ESTIMATED CHARGE'
		and isnull(I.PROCESSEDFLAG,0)=0
		and((I.CHARACTERDATA='S' and T.SERVICEAMOUNT is not null)
		 or (I.CHARACTERDATA='D' and T.DISBAMOUNT    is not null)) "
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
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

-- TransactionType ===> JOURNAL
-- Update ONLY

If  @nJournalCount>0
and @nErrorCode=0
Begin

	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	Set @sSQLString="
	insert into JOURNAL(CASEID, SEQUENCE, JOURNALDATE,  JOURNALNO, JOURNALPAGE)
	Select distinct I.CASEID, isnull(JN.SEQUENCE,0)+1, I.DATEDATA, I.JOURNALNO, I.JOURNALPAGE
	from IMPORTJOURNAL I
	left join (	select CASEID, max(SEQUENCE) as [SEQUENCE]
			from JOURNAL
			group by CASEID) JN on (JN.CASEID=I.CASEID)
	left join JOURNAL J	on  (J.CASEID=I.CASEID
				and (J.JOURNALNO  =I.JOURNALNO   OR (J.JOURNALNO   is null AND I.JOURNALNO   is null))
				and (J.JOURNALPAGE=I.JOURNALPAGE OR (J.JOURNALPAGE is null AND I.JOURNALPAGE is null))
				and (J.JOURNALDATE=I.DATEDATA    OR (J.JOURNALDATE is null AND I.DATEDATA    is null)))
	where I.IMPORTBATCHNO=@pnBatchNo
	and I.TRANSACTIONTYPE='JOURNAL'
	and isnull(I.PROCESSEDFLAG,0)=0
	and J.CASEID is null"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo=@pnBatchNo

	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update IMPORTJOURNAL
		set PROCESSEDFLAG=1
		where IMPORTBATCHNO=@pnBatchNo
		and TRANSACTIONTYPE='JOURNAL'
		and isnull(PROCESSEDFLAG,0)=0"


		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
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

-- TransactionType ===> LOCAL CLASSES

If  @nLocalClassesCount>0
and @nErrorCode=0
Begin
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Update the transactions that have failed the data comparison
	Set @sSQLString="
	Update IMPORTJOURNAL
	Set PROCESSEDFLAG=0,
	    REJECTREASON='Classes mismatches with Case'
	from IMPORTJOURNAL I
	join CASES C		on (C.CASEID=I.CASEID)
	Where I.IMPORTBATCHNO=@pnBatchNo
	and I.TRANSACTIONTYPE='LOCAL CLASSES'
	and C.IRN<>'<Generate Reference>'	-- indicates the Case already exists
	and isnull(I.PROCESSEDFLAG,0)=0
	and I.VALIDATEONLYFLAG in (1,2)
	and ( C.LOCALCLASSES is not null OR I.VALIDATEONLYFLAG<>2) -- LocalClasses must exist for VALIDATEONLYFLAG=2
	and ( C.LOCALCLASSES<>I.CHARACTERDATA 
	 or  (C.LOCALCLASSES is null      AND I.CHARACTERDATA is not null)
	 or  (C.LOCALCLASSES is not null  AND I.CHARACTERDATA is null))"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo=@pnBatchNo
	Set @nFailedCount=@@Rowcount

	If  @nErrorCode=0
	and @nFailedCount>0
	Begin
		exec @nErrorCode=ip_ImportJournalError	@pnUserIdentityId=@pnUserIdentityId,
							@psCulture=@psCulture,
							@pnBatchNo=@pnBatchNo,
							@pnPolicingBatchNo=@nPolicingBatchNo,
							@psTransType='LOCAL CLASSES'
	End

	-- Update the LOCALCLASSES column on Cases if the transaction is not Validate Only

	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update CASES
		Set LOCALCLASSES=I.CHARACTERDATA
		from CASES C
		join IMPORTJOURNAL I	on (I.CASEID=C.CASEID)
		where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='LOCAL CLASSES'
		and isnull(I.PROCESSEDFLAG,0)=0
		and isnull(I.VALIDATEONLYFLAG,0) in (0,2)
		and I.REJECTREASON is null"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
	End

	-- Update the valid transactions to indicate they have been processed.
	-- This includes both the Validate Only transactions and the ones that have just
	-- performed the update.
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update IMPORTJOURNAL
		Set PROCESSEDFLAG=1,
		    REJECTREASON=NULL,
		    ERROREVENTNO=NULL
		from IMPORTJOURNAL I
		join CASES C		on (C.CASEID=I.CASEID)
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='LOCAL CLASSES'
		and isnull(I.PROCESSEDFLAG,0)=0
		and ( C.LOCALCLASSES=I.CHARACTERDATA or (C.LOCALCLASSES is null and I.CHARACTERDATA is null))"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
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

-- TransactionType ===> NAME

If  @nNameCount>0
and @nErrorCode=0
Begin
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Update the transactions that have failed the data comparison
	Set @sSQLString="
	Update IMPORTJOURNAL
	Set PROCESSEDFLAG=0,
	    REJECTREASON='Name does not match with Case'
	from IMPORTJOURNAL I
	join CASES C	on (C.CASEID=I.CASEID)
	Where I.IMPORTBATCHNO=@pnBatchNo
	and I.TRANSACTIONTYPE='NAME'
	and I.VALIDATEONLYFLAG in (1,2)
	and C.IRN<>'<Generate Reference>'	-- indicates the Case already exists
	and isnull(I.PROCESSEDFLAG,0)=0
	and not exists
	(select * from CASENAME CN
	 join NAME N	on (N.NAMENO=CN.NAMENO)
	 where CN.CASEID=I.CASEID
	 and   CN.NAMETYPE=I.CHARACTERKEY
	 and  (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
	 and  UPPER(NULLIF(FIRSTNAME+' ',' ')+NAME)=UPPER(I.CHARACTERDATA) )"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo=@pnBatchNo
	Set @nFailedCount=@@Rowcount

	If  @nErrorCode=0
	and @nFailedCount>0
	Begin
		exec @nErrorCode=ip_ImportJournalError	@pnUserIdentityId=@pnUserIdentityId,
							@psCulture=@psCulture,
							@pnBatchNo=@pnBatchNo,
							@pnPolicingBatchNo=@nPolicingBatchNo,
							@psTransType='NAME'
	End

	-- Update the valid transactions to indicate they have been processed.
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update IMPORTJOURNAL
		Set PROCESSEDFLAG=1,
		    REJECTREASON=NULL,
		    ERROREVENTNO=NULL
		from IMPORTJOURNAL I
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='NAME'
		and isnull(I.PROCESSEDFLAG,0)=0
		and exists
		(select * from CASENAME CN
		 join NAME N	on (N.NAMENO=CN.NAMENO)
		 where CN.CASEID=I.CASEID
		 and   CN.NAMETYPE=I.CHARACTERKEY
		 and  (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
		 and  UPPER(NULLIF(FIRSTNAME+' ',' ')+NAME)=UPPER(I.CHARACTERDATA) )"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
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

-- TransactionType ===> NAME ALIAS

If  @nNameAliasCount>0
and @nErrorCode=0
Begin
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Update the transactions that have failed the data comparison
	Set @sSQLString="
	Update IMPORTJOURNAL
	Set PROCESSEDFLAG=0,
	    REJECTREASON= CASE WHEN(I1.TRANSACTIONNO is null)
				THEN 'No related Name transaction found prior'
				ELSE 'Alias does not match this Alias Type for this Name and Case'
			  END
	from IMPORTJOURNAL I
	join CASES C	on (C.CASEID=I.CASEID)
	-- We need to get the previous NAME transaction to determine the Name to be checked
	left join (	select IMPORTBATCHNO, TRANSACTIONNO, CASEID, CHARACTERKEY, CHARACTERDATA
			from IMPORTJOURNAL
			where TRANSACTIONTYPE='NAME') I1
					on (I1.IMPORTBATCHNO=I.IMPORTBATCHNO
					and I1.TRANSACTIONNO=(	select max(TRANSACTIONNO)
								from IMPORTJOURNAL I2
								where I2.IMPORTBATCHNO=I.IMPORTBATCHNO
								and I2.TRANSACTIONNO<I.TRANSACTIONNO
								and I2.CASEID=I.CASEID
								and I2.TRANSACTIONTYPE='NAME'))
	Where I.IMPORTBATCHNO=@pnBatchNo
	and I.VALIDATEONLYFLAG in (1,2)
	and I.TRANSACTIONTYPE='NAME ALIAS'
	and C.IRN<>'<Generate Reference>'	-- indicates the Case already exists
	and isnull(I.PROCESSEDFLAG,0)=0
	and not exists
	(select * from CASENAME CN
	 join NAME N		on (N.NAMENO=CN.NAMENO)
	 join NAMEALIAS NA	on (NA.NAMENO=N.NAMENO
				and NA.ALIASTYPE=I.CHARACTERKEY
				and UPPER(NA.ALIAS)=UPPER(I.CHARACTERDATA))
	 where CN.CASEID=I.CASEID
	 and   CN.NAMETYPE=I1.CHARACTERKEY
	 and  (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
	 and  UPPER(NULLIF(FIRSTNAME+' ',' ')+NAME)=UPPER(I1.CHARACTERDATA) )"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo=@pnBatchNo
	Set @nFailedCount=@@Rowcount

	If  @nErrorCode=0
	and @nFailedCount>0
	Begin
		exec @nErrorCode=ip_ImportJournalError	@pnUserIdentityId=@pnUserIdentityId,
							@psCulture=@psCulture,
							@pnBatchNo=@pnBatchNo,
							@pnPolicingBatchNo=@nPolicingBatchNo,
							@psTransType='NAME ALIAS'
	End

	-- Update the valid transactions to indicate they have been processed.
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update IMPORTJOURNAL
		Set PROCESSEDFLAG=1,
		    REJECTREASON=NULL,
		    ERROREVENTNO=NULL
		from IMPORTJOURNAL I
		-- We need to get the previous NAME transaction to determine the Name to be checked
		left join (	select IMPORTBATCHNO, TRANSACTIONNO, CASEID, CHARACTERKEY, CHARACTERDATA
				from IMPORTJOURNAL
				where TRANSACTIONTYPE='NAME') I1
						on (I1.IMPORTBATCHNO=I.IMPORTBATCHNO
						and I1.TRANSACTIONNO=(	select max(TRANSACTIONNO)
									from IMPORTJOURNAL I2
									where I2.IMPORTBATCHNO=I.IMPORTBATCHNO
									and I2.TRANSACTIONNO<I.TRANSACTIONNO
									and I2.CASEID=I.CASEID
									and I2.TRANSACTIONTYPE='NAME'))
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='NAME ALIAS'
		and isnull(I.PROCESSEDFLAG,0)=0
		and exists
		(select * from CASENAME CN
		 join NAME N		on (N.NAMENO=CN.NAMENO)
		 join NAMEALIAS NA	on (NA.NAMENO=N.NAMENO
					and NA.ALIASTYPE=I.CHARACTERKEY
					and UPPER(NA.ALIAS)=UPPER(I.CHARACTERDATA))
		 where CN.CASEID=I.CASEID
		 and   CN.NAMETYPE=I1.CHARACTERKEY
		 and  (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
		 and  UPPER(NULLIF(FIRSTNAME+' ',' ')+NAME)=UPPER(I1.CHARACTERDATA) )"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
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

-- TransactionType ===> NAME COUNTRY

If  @nNameCountryCount>0
and @nErrorCode=0
Begin
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Update the transactions that have failed the data comparison
	Set @sSQLString="
	Update IMPORTJOURNAL
	Set PROCESSEDFLAG=0,
	    REJECTREASON= CASE WHEN(I1.TRANSACTIONNO is null)
				THEN 'No related Name transaction found prior'
				ELSE 'Country does not match Country recorded for this Name and Case'
			  END
	from IMPORTJOURNAL I
	join CASES C	on (C.CASEID=I.CASEID)
	-- We need to get the previous NAME transaction to determine the Name to be checked
	left join (	select IMPORTBATCHNO, TRANSACTIONNO, CASEID, CHARACTERKEY, CHARACTERDATA
			from IMPORTJOURNAL
			where TRANSACTIONTYPE='NAME') I1
					on (I1.IMPORTBATCHNO=I.IMPORTBATCHNO
					and I1.TRANSACTIONNO=(	select max(TRANSACTIONNO)
								from IMPORTJOURNAL I2
								where I2.IMPORTBATCHNO=I.IMPORTBATCHNO
								and I2.TRANSACTIONNO<I.TRANSACTIONNO
								and I2.CASEID=I.CASEID
								and I2.TRANSACTIONTYPE='NAME'))
	Where I.IMPORTBATCHNO=@pnBatchNo
	and I.VALIDATEONLYFLAG in (1,2)
	and I.TRANSACTIONTYPE='NAME COUNTRY'
	and C.IRN<>'<Generate Reference>'	-- indicates the Case already exists
	and isnull(I.PROCESSEDFLAG,0)=0
	and not exists
	(select * from CASENAME CN
	 join NAME N		on (N.NAMENO=CN.NAMENO)
	 join ADDRESS A		on (A.ADDRESSCODE=isnull(CN.ADDRESSCODE,N.STREETADDRESS)
				and A.COUNTRYCODE=I.CHARACTERKEY)
	 where CN.CASEID=I.CASEID
	 and   CN.NAMETYPE=I1.CHARACTERKEY
	 and  (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
	 and  UPPER(NULLIF(FIRSTNAME+' ',' ')+NAME)=UPPER(I1.CHARACTERDATA) )"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo=@pnBatchNo
	Set @nFailedCount=@@Rowcount

	If  @nErrorCode=0
	and @nFailedCount>0
	Begin
		exec @nErrorCode=ip_ImportJournalError	@pnUserIdentityId=@pnUserIdentityId,
							@psCulture=@psCulture,
							@pnBatchNo=@pnBatchNo,
							@pnPolicingBatchNo=@nPolicingBatchNo,
							@psTransType='NAME COUNTRY'
	End

	-- Update the valid transactions to indicate they have been processed.
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update IMPORTJOURNAL
		Set PROCESSEDFLAG=1,
		    REJECTREASON=NULL,
		    ERROREVENTNO=NULL
		from IMPORTJOURNAL I
		-- We need to get the previous NAME transaction to determine the Name to be checked
		left join (	select IMPORTBATCHNO, TRANSACTIONNO, CASEID, CHARACTERKEY, CHARACTERDATA
				from IMPORTJOURNAL
				where TRANSACTIONTYPE='NAME') I1
						on (I1.IMPORTBATCHNO=I.IMPORTBATCHNO
						and I1.TRANSACTIONNO=(	select max(TRANSACTIONNO)
									from IMPORTJOURNAL I2
									where I2.IMPORTBATCHNO=I.IMPORTBATCHNO
									and I2.CASEID=I.CASEID
									and I2.TRANSACTIONNO<I.TRANSACTIONNO
									and I2.TRANSACTIONTYPE='NAME'))
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='NAME COUNTRY'
		and isnull(I.PROCESSEDFLAG,0)=0
		and exists
		(select * from CASENAME CN
		 join NAME N		on (N.NAMENO=CN.NAMENO)
		 join ADDRESS A		on (A.ADDRESSCODE=isnull(CN.ADDRESSCODE,N.STREETADDRESS)
					and A.COUNTRYCODE=I.CHARACTERKEY)
		 where CN.CASEID=I.CASEID
		 and   CN.NAMETYPE=I1.CHARACTERKEY
		 and  (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
		 and  UPPER(NULLIF(FIRSTNAME+' ',' ')+NAME)=UPPER(I1.CHARACTERDATA) )"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
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

-- TransactionType ===> NAME STATE

If  @nNameStateCount>0
and @nErrorCode=0
Begin
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Update the transactions that have failed the data comparison
	Set @sSQLString="
	Update IMPORTJOURNAL
	Set PROCESSEDFLAG=0,
	    REJECTREASON= CASE WHEN(I1.TRANSACTIONNO is null)
				THEN 'No related Name transaction found prior'
				ELSE 'State does not match State recorded for this Name and Case'
			  END
	from IMPORTJOURNAL I
	join CASES C	on (C.CASEID=I.CASEID)
	-- We need to get the previous NAME transaction to determine the Name to be checked
	left join (	select IMPORTBATCHNO, TRANSACTIONNO, CASEID, CHARACTERKEY, CHARACTERDATA
			from IMPORTJOURNAL
			where TRANSACTIONTYPE='NAME') I1
					on (I1.IMPORTBATCHNO=I.IMPORTBATCHNO
					and I1.TRANSACTIONNO=(	select max(TRANSACTIONNO)
								from IMPORTJOURNAL I2
								where I2.IMPORTBATCHNO=I.IMPORTBATCHNO
								and I2.CASEID=I.CASEID
								and I2.TRANSACTIONNO<I.TRANSACTIONNO
								and I2.TRANSACTIONTYPE='NAME'))
	Where I.IMPORTBATCHNO=@pnBatchNo
	and I.VALIDATEONLYFLAG in (1,2)
	and I.TRANSACTIONTYPE='NAME STATE'
	and C.IRN<>'<Generate Reference>'	-- indicates the Case already exists
	and isnull(I.PROCESSEDFLAG,0)=0
	and not exists
	(select * from CASENAME CN
	 join NAME N		on (N.NAMENO=CN.NAMENO)
	 join ADDRESS A		on (A.ADDRESSCODE=isnull(CN.ADDRESSCODE,N.STREETADDRESS)
				and A.STATE=I.CHARACTERDATA)
	 where CN.CASEID=I.CASEID
	 and   CN.NAMETYPE=I1.CHARACTERKEY
	 and  (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
	 and  UPPER(NULLIF(FIRSTNAME+' ',' ')+NAME)=UPPER(I1.CHARACTERDATA) )"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo=@pnBatchNo
	Set @nFailedCount=@@Rowcount

	If  @nErrorCode=0
	and @nFailedCount>0
	Begin
		exec @nErrorCode=ip_ImportJournalError	@pnUserIdentityId=@pnUserIdentityId,
							@psCulture=@psCulture,
							@pnBatchNo=@pnBatchNo,
							@pnPolicingBatchNo=@nPolicingBatchNo,
							@psTransType='NAME STATE'
	End

	-- Update the valid transactions to indicate they have been processed.
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update IMPORTJOURNAL
		Set PROCESSEDFLAG=1,
		    REJECTREASON=NULL,
		    ERROREVENTNO=NULL
		from IMPORTJOURNAL I
		-- We need to get the previous NAME transaction to determine the Name to be checked
		left join (	select IMPORTBATCHNO, TRANSACTIONNO, CASEID, CHARACTERKEY, CHARACTERDATA
				from IMPORTJOURNAL
				where TRANSACTIONTYPE='NAME') I1
						on (I1.IMPORTBATCHNO=I.IMPORTBATCHNO
						and I1.TRANSACTIONNO=(	select max(TRANSACTIONNO)
									from IMPORTJOURNAL I2
									where I2.IMPORTBATCHNO=I.IMPORTBATCHNO
									and I2.CASEID=I.CASEID
									and I2.TRANSACTIONNO<I.TRANSACTIONNO
									and I2.TRANSACTIONTYPE='NAME'))
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='NAME STATE'
		and isnull(I.PROCESSEDFLAG,0)=0
		and exists
		(select * from CASENAME CN
		 join NAME N		on (N.NAMENO=CN.NAMENO)
		 join ADDRESS A		on (A.ADDRESSCODE=isnull(CN.ADDRESSCODE,N.STREETADDRESS)
					and A.STATE=I.CHARACTERDATA)
		 where CN.CASEID=I.CASEID
		 and   CN.NAMETYPE=I1.CHARACTERKEY
		 and  (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
		 and  UPPER(NULLIF(FIRSTNAME+' ',' ')+NAME)=UPPER(I1.CHARACTERDATA) )"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
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

-- TransactionType ===> NAME VAT NO

If  @nNameVATNoCount>0
and @nErrorCode=0
Begin
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Update the transactions that have failed the data comparison
	Set @sSQLString="
	Update IMPORTJOURNAL
	Set PROCESSEDFLAG=0,
	    REJECTREASON= CASE WHEN(I1.TRANSACTIONNO is null)
				THEN 'No related Name transaction found prior'
				ELSE 'Tax No does not match the Tax No for this Name and Case'
			  END
	from IMPORTJOURNAL I
	join CASES C	on (C.CASEID=I.CASEID)
	-- We need to get the previous NAME transaction to determine the Name to be checked
	left join (	select IMPORTBATCHNO, TRANSACTIONNO, CASEID, CHARACTERKEY, CHARACTERDATA
			from IMPORTJOURNAL
			where TRANSACTIONTYPE='NAME') I1
					on (I1.IMPORTBATCHNO=I.IMPORTBATCHNO
					and I1.TRANSACTIONNO=(	select max(TRANSACTIONNO)
								from IMPORTJOURNAL I2
								where I2.IMPORTBATCHNO=I.IMPORTBATCHNO
								and I2.CASEID=I.CASEID
								and I2.TRANSACTIONTYPE='NAME'))
	Where I.IMPORTBATCHNO=@pnBatchNo
	and I.VALIDATEONLYFLAG in (1,2)
	and I.TRANSACTIONTYPE='NAME VAT NO'
	and C.IRN<>'<Generate Reference>'	-- indicates the Case already exists
	and isnull(I.PROCESSEDFLAG,0)=0
	and not exists
	(select * from CASENAME CN
	 join NAME N		on (N.NAMENO=CN.NAMENO
				and N.TAXNO =I.CHARACTERDATA)
	 where CN.CASEID=I.CASEID
	 and   CN.NAMETYPE=I1.CHARACTERKEY
	 and  (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
	 and  UPPER(NULLIF(FIRSTNAME+' ',' ')+NAME)=UPPER(I1.CHARACTERDATA) )"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo=@pnBatchNo
	Set @nFailedCount=@@Rowcount

	If  @nErrorCode=0
	and @nFailedCount>0
	Begin
		exec @nErrorCode=ip_ImportJournalError	@pnUserIdentityId=@pnUserIdentityId,
							@psCulture=@psCulture,
							@pnBatchNo=@pnBatchNo,
							@pnPolicingBatchNo=@nPolicingBatchNo,
							@psTransType='NAME VAT NO'
	End

	-- Update the valid transactions to indicate they have been processed.
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update IMPORTJOURNAL
		Set PROCESSEDFLAG=1,
		    REJECTREASON=NULL,
		    ERROREVENTNO=NULL
		from IMPORTJOURNAL I
		-- We need to get the previous NAME transaction to determine the Name to be checked
		left join (	select IMPORTBATCHNO, TRANSACTIONNO, CASEID, CHARACTERKEY, CHARACTERDATA
				from IMPORTJOURNAL
				where TRANSACTIONTYPE='NAME') I1
						on (I1.IMPORTBATCHNO=I.IMPORTBATCHNO
						and I1.TRANSACTIONNO=(	select max(TRANSACTIONNO)
									from IMPORTJOURNAL I2
									where I2.IMPORTBATCHNO=I.IMPORTBATCHNO
									and I2.CASEID=I.CASEID
									and I2.TRANSACTIONTYPE='NAME'))
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='NAME VAT NO'
		and isnull(I.PROCESSEDFLAG,0)=0
		and exists
		(select * from CASENAME CN
		 join NAME N		on (N.NAMENO=CN.NAMENO
					and N.TAXNO =I.CHARACTERDATA)
		 where CN.CASEID=I.CASEID
		 and   CN.NAMETYPE=I1.CHARACTERKEY
		 and  (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
		 and  UPPER(NULLIF(FIRSTNAME+' ',' ')+NAME)=UPPER(I1.CHARACTERDATA) )"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
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

-- TransactionType ===> NUMBER OF CLAIMS

If  @nNumberOfClaimsCount>0
and @nErrorCode=0
Begin
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Update the transactions that have failed the data comparison
	Set @sSQLString="
	Update IMPORTJOURNAL
	Set PROCESSEDFLAG=0,
	    REJECTREASON='Number of Claims mismatches with Case'
	from IMPORTJOURNAL I
	join CASES C		on (C.CASEID=I.CASEID)
	left join PROPERTY P	on (P.CASEID=I.CASEID)
	Where I.IMPORTBATCHNO=@pnBatchNo
	and I.TRANSACTIONTYPE='NUMBER OF CLAIMS'
	and isnull(I.PROCESSEDFLAG,0)=0
	and I.VALIDATEONLYFLAG in (1,2)
	and C.IRN<>'<Generate Reference>'	-- indicates the Case already exists
	and ( P.NOOFCLAIMS is not null OR I.VALIDATEONLYFLAG<>2)  -- NoOfClaims must exist for VALIDATEONLYFLAG=2
	and ( P.NOOFCLAIMS<>I.INTEGERDATA 
	 or  (P.NOOFCLAIMS is null     AND I.INTEGERDATA is not null)
	 or  (P.NOOFCLAIMS is not null AND I.INTEGERDATA is null))"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo=@pnBatchNo
	Set @nFailedCount=@@Rowcount

	If  @nErrorCode=0
	and @nFailedCount>0
	Begin
		exec @nErrorCode=ip_ImportJournalError	@pnUserIdentityId=@pnUserIdentityId,
							@psCulture=@psCulture,
							@pnBatchNo=@pnBatchNo,
							@pnPolicingBatchNo=@nPolicingBatchNo,
							@psTransType='NUMBER OF CLAIMS'
	End

	-- Update the NUMBER OF CLAIMS column on Property if the transaction is not Validate Only

	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update PROPERTY
		Set NOOFCLAIMS=I.INTEGERDATA
		from PROPERTY P
		join IMPORTJOURNAL I	on (I.CASEID=P.CASEID)
		where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='NUMBER OF CLAIMS'
		and isnull(I.PROCESSEDFLAG,0)=0
		and isnull(I.VALIDATEONLYFLAG,0) in (0,2)
		and I.REJECTREASON is null"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
	End

	-- Insert the NUMBER OF CLAIMS column on Property if the transaction is not Validate Only

	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Insert into PROPERTY(CASEID, NOOFCLAIMS)
		Select I.CASEID, I.INTEGERDATA
		from IMPORTJOURNAL I
		left join PROPERTY P	on (P.CASEID=I.CASEID)
		where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='NUMBER OF CLAIMS'
		and isnull(I.PROCESSEDFLAG,0)=0
		and isnull(I.VALIDATEONLYFLAG,0) in (0,2)
		and I.REJECTREASON is null
		and P.CASEID is null"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
	End

	-- Update the valid transactions to indicate they have been processed.
	-- This includes both the Validate Only transactions and the ones that have just
	-- performed the update.
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update IMPORTJOURNAL
		Set PROCESSEDFLAG=1,
		    REJECTREASON=NULL,
		    ERROREVENTNO=NULL
		from IMPORTJOURNAL I
		join PROPERTY P	on (P.CASEID=I.CASEID)
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='NUMBER OF CLAIMS'
		and isnull(I.PROCESSEDFLAG,0)=0
		and ( P.NOOFCLAIMS=I.INTEGERDATA or (P.NOOFCLAIMS is null and I.INTEGERDATA is null))"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
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

-- TransactionType ===> REFERENCE NUMBER

If  @nEntitySizeCount>0
and @nErrorCode=0
Begin
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Update the transactions that have failed the data comparison
	Set @sSQLString="
	Update IMPORTJOURNAL
	Set PROCESSEDFLAG=0,
	    REJECTREASON='REFERENCE NUMBER does not match Case'
	from IMPORTJOURNAL I
	join CASES C		on (C.CASEID=I.CASEID)
	join CASENAME CN	on (CN.CASEID=I.CASEID
				and CN.EXPIRYDATE is null
				and CN.NAMETYPE=(select min(CN1.NAMETYPE)
						 from CASENAME CN1
						 where CN1.CASEID=CN.CASEID
						 and CN1.EXPIRYDATE is null
						 and CN1.NAMETYPE in ('I','R')))
	Where I.IMPORTBATCHNO=@pnBatchNo
	and I.TRANSACTIONTYPE='REFERENCE NUMBER'
	and isnull(I.PROCESSEDFLAG,0)=0
	and I.VALIDATEONLYFLAG in (1,2)
	and C.IRN<>'<Generate Reference>'	-- indicates the Case already exists
	and ( CN.REFERENCENO<>I.CHARACTERDATA
	 or  (CN.REFERENCENO is null     AND I.CHARACTERDATA is not null and I.VALIDATEONLYFLAG=1)
	 or  (CN.REFERENCENO is not null AND I.CHARACTERDATA is null     and I.VALIDATEONLYFLAG=1))"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo=@pnBatchNo
	Set @nFailedCount=@@Rowcount

	If  @nErrorCode=0
	and @nFailedCount>0
	Begin
		exec @nErrorCode=ip_ImportJournalError	@pnUserIdentityId=@pnUserIdentityId,
							@psCulture=@psCulture,
							@pnBatchNo=@pnBatchNo,
							@pnPolicingBatchNo=@nPolicingBatchNo,
							@psTransType='REFERENCE NUMBER'
	End

	-- Update the REFERENCE NUMBER column on CaseName if the transaction is not Validate Only

	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update CASENAME
		Set REFERENCENO=I.CHARACTERDATA
		from CASENAME CN
		join IMPORTJOURNAL I	on (I.CASEID=CN.CASEID)
		where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='REFERENCE NUMBER'
		and isnull(I.PROCESSEDFLAG,0)=0
		and isnull(I.VALIDATEONLYFLAG,0) in (0,2)
		and I.REJECTREASON is null
		and CN.EXPIRYDATE is null
		and CN.NAMETYPE=(select min(CN1.NAMETYPE)
				 from CASENAME CN1
				 where CN1.CASEID=CN.CASEID
				 and CN1.EXPIRYDATE is null
				 and CN1.NAMETYPE in ('I','R'))"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
	End

	-- Update the valid transactions to indicate they have been processed.
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update IMPORTJOURNAL
		Set PROCESSEDFLAG=1,
		    REJECTREASON=NULL,
		    ERROREVENTNO=NULL
		from IMPORTJOURNAL I
		join CASENAME CN on(CN.CASEID=I.CASEID
				and CN.EXPIRYDATE is null
				and CN.NAMETYPE=(select min(CN1.NAMETYPE)
						 from CASENAME CN1
						 where CN1.CASEID=CN.CASEID
						 and CN1.EXPIRYDATE is null
						 and CN1.NAMETYPE in ('I','R')))
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='REFERENCE NUMBER'
		and isnull(I.PROCESSEDFLAG,0)=0
		and (CN.REFERENCENO=I.CHARACTERDATA or (CN.REFERENCENO is null and I.CHARACTERDATA is null))"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
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

-- TransactionType ===> NUMBER TYPE

If  @nNumberTypeCount>0
and @nErrorCode=0
Begin
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Update the transactions that have failed the data comparison
	Set @sSQLString="
	Update IMPORTJOURNAL
	Set PROCESSEDFLAG=0,
	    REJECTREASON= CASE WHEN(O.OFFICIALNUMBER<>I.CHARACTERDATA OR O.OFFICIALNUMBER is null) 
					THEN	'Official Number does not match with Case'
			       WHEN(O.DATEENTERED<>I.DATEDATA) 
					THEN 'Official Number Date does not match with Case Official Number Date'
			       WHEN(O.DATEENTERED is null and I.DATEDATA is not null) 
					THEN 'Official Number Date does not match with Case Official Number Date'
			  END
	from IMPORTJOURNAL I
	join CASES C			on (C.CASEID=I.CASEID)
	left join OFFICIALNUMBERS O	on (O.CASEID=I.CASEID
					and O.NUMBERTYPE=I.CHARACTERKEY
					and O.ISCURRENT=1)
	Where I.IMPORTBATCHNO=@pnBatchNo
	and I.TRANSACTIONTYPE='NUMBER TYPE'
	and C.IRN<>'<Generate Reference>'	-- indicates the Case already exists
	and isnull(I.PROCESSEDFLAG,0)=0
	and I.VALIDATEONLYFLAG in (1,2)
	and ( O.CASEID is not null OR I.VALIDATEONLYFLAG<>2)  -- Official Number must exist for VALIDATEONLYFLAG=2
	and ( O.OFFICIALNUMBER<>I.CHARACTERDATA 
	 or   O.OFFICIALNUMBER is null
	 or   O.DATEENTERED<>I.DATEDATA
	 or  (O.DATEENTERED is null and I.DATEDATA is not null))"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo=@pnBatchNo
	Set @nFailedCount=@@Rowcount

	If @nErrorCode=0
	Begin
		-- Reject any update transactions where the Official Number already exists.
		Set @sSQLString="
		Update IMPORTJOURNAL
		Set PROCESSEDFLAG=0,
		    REJECTREASON= 'Official Number already entered against Case'
		from IMPORTJOURNAL I
		join CASES C		on (C.CASEID=I.CASEID)
		join OFFICIALNUMBERS O	on (O.CASEID=I.CASEID
					and O.NUMBERTYPE=I.CHARACTERKEY
					and O.ISCURRENT=1
					and O.OFFICIALNUMBER=I.CHARACTERDATA)
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='NUMBER TYPE'
		and isnull(I.PROCESSEDFLAG,0)=0
		and isnull(I.VALIDATEONLYFLAG,0)=0
		and C.IRN<>'<Generate Reference>'	-- indicates the Case already exists
		and (O.DATEENTERED=I.DATEDATA
		 or (O.DATEENTERED is null and I.DATEDATA is null))"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
		Set @nFailedCount=@nFailedCount+@@Rowcount
	End

	If  @nErrorCode=0
	and @nFailedCount>0
	Begin
		exec @nErrorCode=ip_ImportJournalError	@pnUserIdentityId=@pnUserIdentityId,
							@psCulture=@psCulture,
							@pnBatchNo=@pnBatchNo,
							@pnPolicingBatchNo=@nPolicingBatchNo,
							@psTransType='NUMBER TYPE'
	End

	-- Turn off the ISCURRENT flag for any OFFICIALNUMBERS where a new
	-- OfficialNumber of the same NumberType is about to be inserted.

	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update OFFICIALNUMBERS
		Set ISCURRENT=0
		from OFFICIALNUMBERS O
		join IMPORTJOURNAL I	on (I.CASEID=O.CASEID
					and I.CHARACTERKEY=O.NUMBERTYPE)
		where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='NUMBER TYPE'
		and isnull(I.PROCESSEDFLAG,0)=0
		and isnull(I.VALIDATEONLYFLAG,0)=0"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
	End

	-- Update the DATEENTERED for existing and matching OFFICIALNUMBERS
	
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update OFFICIALNUMBERS
		set DATEENTERED=I.DATEDATA,
		    ISCURRENT=1
		from OFFICIALNUMBERS O
		join IMPORTJOURNAL I	on (I.CASEID=O.CASEID
					and I.CHARACTERKEY=O.NUMBERTYPE
					and I.CHARACTERDATA=O.OFFICIALNUMBER)
		where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='NUMBER TYPE'
		and I.DATEDATA is not null
		and isnull(I.PROCESSEDFLAG,0)=0
		and isnull(I.VALIDATEONLYFLAG,0)=0"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
	End

	-- Now insert a new row into OFFICIALNUMBERS

	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Insert into OFFICIALNUMBERS(CASEID, OFFICIALNUMBER, NUMBERTYPE, ISCURRENT, DATEENTERED)
		select distinct I.CASEID, I.CHARACTERDATA, I.CHARACTERKEY, 1, I.DATEDATA
		from IMPORTJOURNAL I
		where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='NUMBER TYPE'
		and I.CHARACTERDATA is not null
		and I.CHARACTERKEY is not null
		and isnull(I.PROCESSEDFLAG,0)=0
		and isnull(I.VALIDATEONLYFLAG,0) in (0,2)
		and I.REJECTREASON is null
		and not exists
		(select * from OFFICIALNUMBERS O1
		 where O1.CASEID=I.CASEID
		 and O1.NUMBERTYPE=I.CHARACTERKEY
		 and O1.OFFICIALNUMBER=I.CHARACTERDATA)"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
	End

	-- Update the CURRENTOFFICIALNO against the Case
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update CASES
		set CURRENTOFFICIALNO=substring(O1.OFFICIALNUMBER,14,36)
		from CASES C
		join (	select O.CASEID, 
				-- this findes the best Official Number to use based on 
				-- NumberType priority and Date entered
				max(convert(char(5), 99999-NT.DISPLAYPRIORITY )+
				    convert(char(8), O.DATEENTERED,112)+
				    O.OFFICIALNUMBER) as OFFICIALNUMBER
			from OFFICIALNUMBERS O
			join NUMBERTYPES NT on (NT.NUMBERTYPE=O.NUMBERTYPE)
			where NT.ISSUEDBYIPOFFICE=1
			and NT.DISPLAYPRIORITY is not null
			and O.ISCURRENT=1
			group by O.CASEID) O1 on (O1.CASEID=C.CASEID)
		where exists
		(select 1 from IMPORTJOURNAL I
		 where I.CASEID=C.CASEID
		 and I.IMPORTBATCHNO=@pnBatchNo
		 and I.TRANSACTIONTYPE='NUMBER TYPE'
		 and I.CHARACTERDATA is not null
		 and I.CHARACTERKEY is not null
		 and isnull(I.PROCESSEDFLAG,0)=0
		 and isnull(I.VALIDATEONLYFLAG,0) in (0,2)
		 and I.REJECTREASON is null)
		-- Only update if a change has occurred. Using CHECKSUM to recognis NULLs on either side.
		and checksum(C.CURRENTOFFICIALNO)<>checksum(substring(O1.OFFICIALNUMBER,14,36))"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
	End

	-- Update the valid transactions to indicate they have been processed.
	-- This includes both the Validate Only transactions and the ones that have just
	-- performed the update.
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update IMPORTJOURNAL
		Set PROCESSEDFLAG=1,
		    REJECTREASON=NULL,
		    ERROREVENTNO=NULL
		from IMPORTJOURNAL I
		join OFFICIALNUMBERS O	on (O.CASEID=I.CASEID
					and O.NUMBERTYPE=I.CHARACTERKEY
					and O.ISCURRENT=1
					and O.OFFICIALNUMBER=I.CHARACTERDATA)
		Where I.IMPORTBATCHNO=@pnBatchNo
		and (REJECTREASON is null OR REJECTREASON<>'Official Number already entered against Case' )
		and  I.TRANSACTIONTYPE='NUMBER TYPE'
		and  isnull(I.PROCESSEDFLAG,0)=0"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
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

-- TransactionType ===> RELATED COUNTRY
-- Note that this is a validate only transaction

If  @nRelatedCountryCount>0
and @nErrorCode=0
Begin
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Update the transactions that have failed the data comparison
	Set @sSQLString="
	Update IMPORTJOURNAL
	Set PROCESSEDFLAG=0,
	    REJECTREASON='Related Country does not match with Case'
	from IMPORTJOURNAL I
	join CASES C	on (C.CASEID=I.CASEID)
	Where I.IMPORTBATCHNO=@pnBatchNo
	and I.TRANSACTIONTYPE='RELATED COUNTRY'
	and isnull(I.PROCESSEDFLAG,0)=0
	and C.IRN<>'<Generate Reference>'	-- indicates the Case already exists
	and not exists
	(select * from RELATEDCASE RC
	 left join CASES C1 on (C1.CASEID=RC.RELATEDCASEID)
	 where RC.CASEID=I.CASEID
	 and RC.RELATIONSHIP=I.CHARACTERKEY
	 and isnull(C1.COUNTRYCODE,RC.COUNTRYCODE)=I.CHARACTERDATA)
	and not exists
	(select * from RELATEDCASE RC
	 left join CASES C1 on (C1.CASEID=RC.CASEID)
	 where RC.RELATEDCASEID=I.CASEID
	 and RC.RELATIONSHIP=I.CHARACTERKEY
	 and isnull(C1.COUNTRYCODE,RC.COUNTRYCODE)=I.CHARACTERDATA)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo=@pnBatchNo
	Set @nFailedCount=@@Rowcount

	If  @nErrorCode=0
	and @nFailedCount>0
	Begin
		exec @nErrorCode=ip_ImportJournalError	@pnUserIdentityId=@pnUserIdentityId,
							@psCulture=@psCulture,
							@pnBatchNo=@pnBatchNo,
							@pnPolicingBatchNo=@nPolicingBatchNo,
							@psTransType='RELATED COUNTRY'
	End

	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update IMPORTJOURNAL
		Set PROCESSEDFLAG=1,
		    REJECTREASON=NULL,
		    ERROREVENTNO=NULL
		from IMPORTJOURNAL I
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='RELATED COUNTRY'
		and isnull(I.PROCESSEDFLAG,0)=0
		and ( exists
		(select * from RELATEDCASE RC
		 left join CASES C on (C.CASEID=RC.RELATEDCASEID)
		 where RC.CASEID=I.CASEID
		 and RC.RELATIONSHIP=I.CHARACTERKEY
		 and isnull(C.COUNTRYCODE,RC.COUNTRYCODE)=I.CHARACTERDATA)
		OR exists
		(select * from RELATEDCASE RC
		 left join CASES C on (C.CASEID=RC.CASEID)
		 where RC.RELATEDCASEID=I.CASEID
		 and RC.RELATIONSHIP=I.CHARACTERKEY
		 and isnull(C.COUNTRYCODE,RC.COUNTRYCODE)=I.CHARACTERDATA))"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
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

-- TransactionType ===> RELATED DATE
-- Note that this is a validate only transaction

If  @nRelatedDateCount>0
and @nErrorCode=0
Begin
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Update the transactions that have failed the data comparison
	Set @sSQLString="
	Update IMPORTJOURNAL
	Set PROCESSEDFLAG=0,
	    REJECTREASON='Related Date does not match with Case'
	from IMPORTJOURNAL I
	join CASES C	on (C.CASEID=I.CASEID)
	Where I.IMPORTBATCHNO=@pnBatchNo
	and I.TRANSACTIONTYPE='RELATED DATE'
	and isnull(I.PROCESSEDFLAG,0)=0
	and C.IRN<>'<Generate Reference>'	-- indicates the Case already exists
	and not exists
	(select * from RELATEDCASE RC
	 join CASERELATION CR	on (CR.RELATIONSHIP=RC.RELATIONSHIP)
	 left join CASEEVENT CE	on (CE.CASEID=RC.RELATEDCASEID
				and CE.EVENTNO=CR.FROMEVENTNO)
	 where RC.CASEID=I.CASEID
	 and RC.RELATIONSHIP=I.CHARACTERKEY
	 and isnull(CE.EVENTDATE,RC.PRIORITYDATE)=I.DATEDATA)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo=@pnBatchNo
	Set @nFailedCount=@@Rowcount

	If  @nErrorCode=0
	and @nFailedCount>0
	Begin
		exec @nErrorCode=ip_ImportJournalError	@pnUserIdentityId=@pnUserIdentityId,
							@psCulture=@psCulture,
							@pnBatchNo=@pnBatchNo,
							@pnPolicingBatchNo=@nPolicingBatchNo,
							@psTransType='RELATED DATE'
	End

	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update IMPORTJOURNAL
		Set PROCESSEDFLAG=1,
		    REJECTREASON=NULL,
		    ERROREVENTNO=NULL
		from IMPORTJOURNAL I
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='RELATED DATE'
		and isnull(I.PROCESSEDFLAG,0)=0
		and exists
		(select * from RELATEDCASE RC
		 join CASERELATION CR	on (CR.RELATIONSHIP=RC.RELATIONSHIP)
		 left join CASEEVENT CE	on (CE.CASEID=RC.RELATEDCASEID
					and CE.EVENTNO=CR.FROMEVENTNO)
		 where RC.CASEID=I.CASEID
		 and RC.RELATIONSHIP=I.CHARACTERKEY
		 and isnull(CE.EVENTDATE,RC.PRIORITYDATE)=I.DATEDATA)"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
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

-- TransactionType ===> RELATED NUMBER
-- Note that this is a validate only transaction

If  @nRelatedNumberCount>0
and @nErrorCode=0
Begin
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Update the transactions that have failed the data comparison
	Set @sSQLString="
	Update IMPORTJOURNAL
	Set PROCESSEDFLAG=0,
	    REJECTREASON='Related Number does not match with Case'
	from IMPORTJOURNAL I
	join CASES C	on (C.CASEID=I.CASEID)
	Where I.IMPORTBATCHNO=@pnBatchNo
	and I.TRANSACTIONTYPE='RELATED NUMBER'
	and isnull(I.PROCESSEDFLAG,0)=0
	and C.IRN<>'<Generate Reference>'	-- indicates the Case already exists
	and not exists
	(select * from RELATEDCASE RC
	 left join OFFICIALNUMBERS O	on (O.CASEID=RC.RELATEDCASEID
					and O.OFFICIALNUMBER=I.CHARACTERDATA)
	 where RC.CASEID=I.CASEID
	 and RC.RELATIONSHIP=I.CHARACTERKEY
	 and isnull(O.OFFICIALNUMBER,RC.OFFICIALNUMBER)=I.CHARACTERDATA)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo=@pnBatchNo
	Set @nFailedCount=@@Rowcount

	If  @nErrorCode=0
	and @nFailedCount>0
	Begin
		exec @nErrorCode=ip_ImportJournalError	@pnUserIdentityId=@pnUserIdentityId,
							@psCulture=@psCulture,
							@pnBatchNo=@pnBatchNo,
							@pnPolicingBatchNo=@nPolicingBatchNo,
							@psTransType='RELATED NUMBER'
	End

	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update IMPORTJOURNAL
		Set PROCESSEDFLAG=1,
		    REJECTREASON=NULL,
		    ERROREVENTNO=NULL
		from IMPORTJOURNAL I
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='RELATED NUMBER'
		and isnull(I.PROCESSEDFLAG,0)=0
		and exists
		(select * from RELATEDCASE RC
		 left join OFFICIALNUMBERS O	on (O.CASEID=RC.RELATEDCASEID
						and O.OFFICIALNUMBER=I.CHARACTERDATA)
		 where RC.CASEID=I.CASEID
		 and RC.RELATIONSHIP=I.CHARACTERKEY
		 and isnull(O.OFFICIALNUMBER,RC.OFFICIALNUMBER)=I.CHARACTERDATA)"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
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

-- TransactionType ===> TEXT

If  @nTextCount>0
and @nErrorCode=0
Begin
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Update the transactions that have failed the data comparison
	Set @sSQLString="
	Update IMPORTJOURNAL
	Set PROCESSEDFLAG=0,
	    REJECTREASON='Text does not match with Case Text'
	from IMPORTJOURNAL I
	join CASES C		on (C.CASEID=I.CASEID)
	left join CASETEXT T	on (T.CASEID=I.CASEID
				and T.TEXTTYPE=I.CHARACTERKEY
				and T.TEXTNO=(	select max(TEXTNO)
						from CASETEXT T1
						where T1.CASEID=I.CASEID
						and T1.TEXTTYPE=I.CHARACTERKEY))
	Where I.IMPORTBATCHNO=@pnBatchNo
	and I.TRANSACTIONTYPE='TEXT'
	and isnull(I.PROCESSEDFLAG,0)=0
	and I.VALIDATEONLYFLAG in (1,2)
	and C.IRN<>'<Generate Reference>'	-- indicates the Case already exists
	and ((T.CASEID is not null and I.CHARACTERKEY<>'G')
	  OR  I.VALIDATEONLYFLAG=1 
	  OR (I.VALIDATEONLYFLAG=2 and (isnull(T.TEXT,T.SHORTTEXT) is not null and I.CHARACTERKEY='G'))) -- CaseText must exist with text(SQA15082) if ValidateOnlyFlag=2
	and not exists
	(select * from CASETEXT CT
	 where CT.CASEID=I.CASEID
	 and CT.TEXTTYPE=I.CHARACTERKEY
	 and isnull(convert(nvarchar(4000),CT.TEXT),CT.SHORTTEXT) = isnull(convert(nvarchar(4000),I.TEXTDATA),I.CHARACTERDATA))"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo=@pnBatchNo
	Set @nFailedCount=@@Rowcount

	If  @nErrorCode=0
	and @nFailedCount>0
	Begin
		exec @nErrorCode=ip_ImportJournalError	@pnUserIdentityId=@pnUserIdentityId,
							@psCulture=@psCulture,
							@pnBatchNo=@pnBatchNo,
							@pnPolicingBatchNo=@nPolicingBatchNo,
							@psTransType='TEXT'
	End

	-- Insert new CASETEXT rows

	If @nErrorCode=0
	Begin
		Set @dtCurrentDateTime=getdate()

		Set @sSQLString="
		Insert into CASETEXT(CASEID, TEXTTYPE, TEXTNO, MODIFIEDDATE, CLASS, LONGFLAG, SHORTTEXT, TEXT)
		Select I.CASEID, I.CHARACTERKEY,isnull(CT.TEXTNO,-1)+1, getdate(),
		CASE WHEN(I.CHARACTERKEY='G') THEN isnull(I1.CHARACTERDATA, I.CHARACTERDATA) END, -- SQA1933 For Goods get CLASS from this transaction or previous transaction
		CASE WHEN(datalength(I.TEXTDATA)>508) THEN 1    ELSE 0 END,
		CASE WHEN(datalength(I.TEXTDATA)>508) THEN NULL ELSE isnull(I.TEXTDATA, I.CHARACTERDATA) END,
		CASE WHEN(datalength(I.TEXTDATA)>508) THEN I.TEXTDATA END
		from IMPORTJOURNAL I
		left join (select CASEID, TEXTTYPE, max(TEXTNO) as TEXTNO
			   from CASETEXT
			   group by CASEID, TEXTTYPE) CT on (CT.CASEID=I.CASEID
							 and CT.TEXTTYPE=I.CHARACTERKEY)
		left join IMPORTJOURNAL I1	on (I1.IMPORTBATCHNO=I.IMPORTBATCHNO
						and I1.TRANSACTIONNO=I.TRANSACTIONNO-1
						and I1.TRANSACTIONTYPE='LOCAL CLASSES')
		left join CASETEXT CT1		on (CT1.CASEID=I.CASEID
						and CT1.TEXTTYPE=I.CHARACTERKEY
						and(CT1.CLASS=isnull(I1.CHARACTERDATA, I.CHARACTERDATA) OR (CT1.CLASS is NULL and I.CHARACTERDATA is NULL and I1.CHARACTERDATA is NULL)))
		where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='TEXT'
		and isnull(I.PROCESSEDFLAG,0)=0
		and isnull(I.VALIDATEONLYFLAG,0) in (0,2)
		and I.REJECTREASON is null
		and I.CHARACTERKEY is not null
		and I.TRANSACTIONNO = ( select min(I2.TRANSACTIONNO)
					from IMPORTJOURNAL I2
					where I2.IMPORTBATCHNO=I.IMPORTBATCHNO
					and I2.CASEID	      =I.CASEID
					and I2.TRANSACTIONTYPE=I.TRANSACTIONTYPE
					and I2.CHARACTERKEY   =I.CHARACTERKEY)"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
	End

	-- If the option to keep historical text is not set ON then delete any old versions
	-- of the text
	
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Delete CASETEXT
		from CASETEXT CT
		left join SITECONTROL S	on (S.CONTROLID='KEEPSPECIHISTORY')
		join IMPORTJOURNAL I	on (I.CASEID=CT.CASEID
					and I.CHARACTERKEY=CT.TEXTTYPE)
		Where isnull(S.COLBOOLEAN,0)=0	-- if flag off then allow deletion
		and I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='TEXT'
		and isnull(I.PROCESSEDFLAG,0)=0
		and isnull(I.VALIDATEONLYFLAG,0)in (0,2)
		and I.REJECTREASON is null
		and exists
		(select * from CASETEXT CT1
		 where CT1.CASEID=CT.CASEID
		 and   CT1.TEXTTYPE=CT.TEXTTYPE
		 and  (CT1.LANGUAGE=CT.LANGUAGE OR (CT1.LANGUAGE is null and CT.LANGUAGE is null))
		 and  (CT1.CLASS=CT.CLASS       OR (CT1.CLASS    is null and CT.CLASS    is null))
		 and   CT1.MODIFIEDDATE>CT.MODIFIEDDATE
		 and   CT1.MODIFIEDDATE>=@dtCurrentDateTime)"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int,
						  @dtCurrentDateTime	datetime',
						  @pnBatchNo=@pnBatchNo,
						  @dtCurrentDateTime=@dtCurrentDateTime
	End

	-- Update the valid transactions to indicate they have been processed.
	-- This includes both the Validate Only transactions and the ones that have just
	-- performed the update.
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update IMPORTJOURNAL
		Set PROCESSEDFLAG=1,
		    REJECTREASON=NULL,
		    ERROREVENTNO=NULL
		from IMPORTJOURNAL I
		join CASES C		on (C.CASEID=I.CASEID)
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='TEXT'
		and isnull(I.PROCESSEDFLAG,0)=0
		and exists
		(select * from CASETEXT CT
		 where CT.CASEID=I.CASEID
		 and CT.TEXTTYPE=I.CHARACTERKEY
		 and isnull(convert(nvarchar(4000),CT.TEXT),CT.SHORTTEXT) = isnull(convert(nvarchar(4000),I.TEXTDATA),I.CHARACTERDATA))"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
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

-- TransactionType ===> TITLE

If  @nTitleCount>0
and @nErrorCode=0
Begin
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Update the transactions that have failed the data comparison
	Set @sSQLString="
	Update IMPORTJOURNAL
	Set PROCESSEDFLAG=0,
	    REJECTREASON='Title mismatches with Case'
	from IMPORTJOURNAL I
	join CASES C		on (C.CASEID=I.CASEID)
	Where I.IMPORTBATCHNO=@pnBatchNo
	and I.TRANSACTIONTYPE='TITLE'
	and isnull(I.PROCESSEDFLAG,0)=0
	and I.VALIDATEONLYFLAG in (1,2)
	and C.IRN<>'<Generate Reference>'	-- indicates the Case already exists
	and ( C.TITLE is not null OR I.VALIDATEONLYFLAG<>2)  -- Title must exist for VALIDATEONLYFLAG=2
	and ( C.TITLE<>I.CHARACTERDATA 
	 or  (C.TITLE is null      AND I.CHARACTERDATA is not null)
	 or  (C.TITLE is not null  AND I.CHARACTERDATA is null))"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo=@pnBatchNo
	Set @nFailedCount=@@Rowcount

	If  @nErrorCode=0
	and @nFailedCount>0
	Begin
		exec @nErrorCode=ip_ImportJournalError	@pnUserIdentityId=@pnUserIdentityId,
							@psCulture=@psCulture,
							@pnBatchNo=@pnBatchNo,
							@pnPolicingBatchNo=@nPolicingBatchNo,
							@psTransType='TITLE'
	End

	-- Update the TITLE column on Cases if the transaction is not Validate Only

	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update CASES
		Set TITLE=I.CHARACTERDATA
		from CASES C
		join IMPORTJOURNAL I	on (I.CASEID=C.CASEID)
		where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='TITLE'
		and isnull(I.PROCESSEDFLAG,0)=0
		and isnull(I.VALIDATEONLYFLAG,0) in (0,2)
		and I.REJECTREASON is null"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
	End

	-- Update the valid transactions to indicate they have been processed.
	-- This includes both the Validate Only transactions and the ones that have just
	-- performed the update.
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update IMPORTJOURNAL
		Set PROCESSEDFLAG=1,
		    REJECTREASON=NULL,
		    ERROREVENTNO=NULL
		from IMPORTJOURNAL I
		join CASES C		on (C.CASEID=I.CASEID)
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='TITLE'
		and isnull(I.PROCESSEDFLAG,0)=0
		and ( C.TITLE=I.CHARACTERDATA or (C.TITLE is null and I.CHARACTERDATA is null))"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
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

-- TransactionType ===> TYPE OF MARK

If  @nTypeOfMarkCount>0
and @nErrorCode=0
Begin
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Update the transactions that have failed the data comparison
	Set @sSQLString="
	Update IMPORTJOURNAL
	Set PROCESSEDFLAG=0,
	    REJECTREASON='Type of Mark does not match Case'
	from IMPORTJOURNAL I
	join CASES C		on (C.CASEID=I.CASEID)
	left join TABLECODES T	on (T.TABLECODE=C.TYPEOFMARK)
	Where I.IMPORTBATCHNO=@pnBatchNo
	and I.TRANSACTIONTYPE='TYPE OF MARK'
	and isnull(I.PROCESSEDFLAG,0)=0
	and C.IRN<>'<Generate Reference>'	-- indicates the Case already exists
	and ( UPPER(T.DESCRIPTION)<>UPPER(I.CHARACTERDATA )
	 or  (T.DESCRIPTION is null     AND I.CHARACTERDATA is not null)
	 or  (T.DESCRIPTION is not null AND I.CHARACTERDATA is null))"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo=@pnBatchNo
	Set @nFailedCount=@@Rowcount

	If  @nErrorCode=0
	and @nFailedCount>0
	Begin
		exec @nErrorCode=ip_ImportJournalError	@pnUserIdentityId=@pnUserIdentityId,
							@psCulture=@psCulture,
							@pnBatchNo=@pnBatchNo,
							@pnPolicingBatchNo=@nPolicingBatchNo,
							@psTransType='TYPE OF MARK'
	End

	-- Update the TYPE OF MARK column on Cases if the transaction is not Validate Only

	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update CASES
		Set TYPEOFMARK=T.TABLECODE
		from CASES C
		join IMPORTJOURNAL I	on (I.CASEID=C.CASEID)
		left join TABLECODES T	on (T.TABLECODE=(select min(T1.TABLECODE)
							 from TABLECODES T1
							 where T1.TABLETYPE=51
							 and T1.DESCRIPTION=I.CHARACTERDATA))
		where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='TYPE OF MARK'
		and isnull(I.PROCESSEDFLAG,0)=0
		and isnull(I.VALIDATEONLYFLAG,0) in (0,2)
		and I.REJECTREASON is null"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
	End

	-- Update the valid transactions to indicate they have been processed.
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update IMPORTJOURNAL
		Set PROCESSEDFLAG=1,
		    REJECTREASON=NULL,
		    ERROREVENTNO=NULL
		from IMPORTJOURNAL I
		join CASES C		on (C.CASEID=I.CASEID)
		left join TABLECODES T	on (T.TABLECODE=C.TYPEOFMARK)
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='TYPE OF MARK'
		and isnull(I.PROCESSEDFLAG,0)=0
		and ( T.DESCRIPTION=I.CHARACTERDATA or (T.DESCRIPTION is null and I.CHARACTERDATA is null))"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
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

-- NOTE : Processing of the CASEEVENT transactions is at the end of the process because the 
--	  CASEEVENT row will be marked with the IMPORTBATCHNO if there were any errors recorded
--	  for that Case in this batch.

-- TransactionType ===> DUE DATE - ValidateOnly

If  @nDueDateCount>0
and @nErrorCode=0
Begin
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Update the transactions that have failed the data comparison
	Set @sSQLString="
	Update IMPORTJOURNAL
	Set PROCESSEDFLAG=0,
	    REJECTREASON=CASE WHEN(CE2.OCCURREDFLAG>0)
				THEN 'The Event is no longer due'
			      WHEN(CE2.EVENTDUEDATE<>I.DATEDATA)
				THEN 'Due Date does not match with CaseEvent Due Date'
			      WHEN(CE2.EVENTDUEDATE is null)
				THEN 'Event does not match with case'
			 END
	from IMPORTJOURNAL I
	join CASES C		on (C.CASEID=I.CASEID)
	left join ACTIONS A	on (A.ACTION=I.ACTION)
	left join OPENACTION OA	on (OA.CASEID=I.CASEID
				and OA.ACTION=I.ACTION
				and OA.CYCLE=(select max(CYCLE)
					      from OPENACTION OA1
					      where OA1.CASEID=OA.CASEID
					      and OA1.ACTION=I.ACTION
					      and OA1.POLICEEVENTS=1))
	left join CASEEVENT CE1	on (CE1.CASEID=I.CASEID
				and CE1.EVENTNO=I.NUMBERKEY
				and CE1.CYCLE=(	select max(CYCLE)
						from CASEEVENT CE11
						where CE11.CASEID=CE1.CASEID
						and CE11.EVENTNO=I.NUMBERKEY))
	left join CASEEVENT CE2	on (CE2.CASEID=I.CASEID
				and CE2.EVENTNO=I.NUMBERKEY
				and CE2.CYCLE=	CASE WHEN(I.CYCLE is not null)
							THEN I.CYCLE
							ELSE CASE(I.RELATIVECYCLE)
								-- Current Cycle
								-- If the Action is cyclic then use the current open action
								-- else use the highest cycle for the Event.
								WHEN(0) THEN CASE WHEN(A.NUMCYCLESALLOWED>1 and OA.CYCLE is not null)
										THEN OA.CYCLE
										ELSE isnull(CE1.CYCLE,1)
									     END
								-- Previous Cycle
								WHEN(1) THEN CASE WHEN(A.NUMCYCLESALLOWED>1 and OA.CYCLE is not null)
										THEN OA.CYCLE-1
										ELSE isnull(CE1.CYCLE,1)-1
									     END
								-- Next Cycle
								WHEN(2) THEN CASE WHEN(A.NUMCYCLESALLOWED>1 and OA.CYCLE is not null)
										THEN OA.CYCLE+1
										ELSE isnull(CE1.CYCLE,0)+1
									     END
								-- First Cycle
								WHEN(3) THEN 1
								-- Highest Cycle
								WHEN(4) THEN CE1.CYCLE
								-- Current(if due) otherwise next
								WHEN(5) THEN CASE WHEN(CE1.OCCURREDFLAG=0)
										THEN CE1.CYCLE
										ELSE isnull(CE1.CYCLE,0)+1
									     END
							     END
						END)
	Where I.IMPORTBATCHNO=@pnBatchNo
	and I.TRANSACTIONTYPE='DUE DATE'
	and I.VALIDATEONLYFLAG in (1,2)
	and C.IRN<>'<Generate Reference>'	-- indicates the Case already exists
	and isnull(I.PROCESSEDFLAG,0)=0
	and ( CE2.CASEID is not null OR I.VALIDATEONLYFLAG<>2) -- CaseEvent must exist for VALIDATEONLYFLAG=2
	and ( CE2.EVENTDUEDATE<>I.DATEDATA OR CE2.EVENTDUEDATE is null OR CE2.OCCURREDFLAG>0)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo=@pnBatchNo
	Set @nFailedCount=@@Rowcount

	-- If transactions failed call the stored procedure to take any action required.

	If  @nErrorCode=0
	and @nFailedCount>0
	Begin
		exec @nErrorCode=ip_ImportJournalError	@pnUserIdentityId=@pnUserIdentityId,
							@psCulture=@psCulture,
							@pnBatchNo=@pnBatchNo,
							@pnPolicingBatchNo=@nPolicingBatchNo,
							@psTransType='DUE DATE'
	End

	-- Update the ValidateOnly transactions that have passed the data comparison
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update IMPORTJOURNAL
		Set PROCESSEDFLAG=1,
		    REJECTREASON=NULL,
		    ERROREVENTNO=NULL
		from IMPORTJOURNAL I
		left join ACTIONS A	on (A.ACTION=I.ACTION)
		left join OPENACTION OA	on (OA.CASEID=I.CASEID
					and OA.ACTION=I.ACTION
					and OA.CYCLE=(select max(CYCLE)
						      from OPENACTION OA1
						      where OA1.CASEID=OA.CASEID
						      and OA1.ACTION=I.ACTION
						      and OA1.POLICEEVENTS=1))
		join CASEEVENT CE1	on (CE1.CASEID=I.CASEID
					and CE1.EVENTNO=I.NUMBERKEY
					and CE1.CYCLE=(	select max(CYCLE)
							from CASEEVENT CE11
							where CE11.CASEID=CE1.CASEID
							and CE11.EVENTNO=I.NUMBERKEY))
		join CASEEVENT CE2	on (CE2.CASEID=I.CASEID
					and CE2.EVENTNO=I.NUMBERKEY
					and CE2.CYCLE=	CASE WHEN(I.CYCLE is not null)
								THEN I.CYCLE
								ELSE CASE(I.RELATIVECYCLE)
									-- Current Cycle
									-- If the Action is cyclic then use the current open action
									-- else use the highest cycle for the Event.
									WHEN(0) THEN CASE WHEN(A.NUMCYCLESALLOWED>1 and OA.CYCLE is not null)
											THEN OA.CYCLE
											ELSE isnull(CE1.CYCLE,1)
										     END
									-- Previous Cycle
									WHEN(1) THEN CASE WHEN(A.NUMCYCLESALLOWED>1 and OA.CYCLE is not null)
											THEN OA.CYCLE-1
											ELSE isnull(CE1.CYCLE,1)-1
										     END
									-- Next Cycle
									WHEN(2) THEN CASE WHEN(A.NUMCYCLESALLOWED>1 and OA.CYCLE is not null)
											THEN OA.CYCLE+1
											ELSE isnull(CE1.CYCLE,0)+1
										     END
									-- First Cycle
									WHEN(3) THEN 1
									-- Highest Cycle
									WHEN(4) THEN CE1.CYCLE
									-- Current(if due) otherwise next
									WHEN(5) THEN CASE WHEN(CE1.OCCURREDFLAG=0)
											THEN CE1.CYCLE
											ELSE isnull(CE1.CYCLE,0)+1
										     END
								     END
							END)
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='DUE DATE'
		and I.VALIDATEONLYFLAG in (1,2)
		and isnull(I.PROCESSEDFLAG,0)=0
		and CE2.OCCURREDFLAG=0
		and CE2.EVENTDUEDATE=I.DATEDATA"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
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


-- TransactionType ===> ENTITY SIZE

If  @nEntitySizeCount>0
and @nErrorCode=0
Begin
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Update the transactions that have failed the data comparison
	Set @sSQLString="
	Update IMPORTJOURNAL
	Set PROCESSEDFLAG=0,
	    REJECTREASON='ENTITY SIZE does not match Case'
	from IMPORTJOURNAL I
	join CASES C		on (C.CASEID=I.CASEID)
	left join TABLECODES T	on (T.TABLECODE=C.ENTITYSIZE)
	Where I.IMPORTBATCHNO=@pnBatchNo
	and I.TRANSACTIONTYPE='ENTITY SIZE'
	and isnull(I.PROCESSEDFLAG,0)=0
	and I.VALIDATEONLYFLAG in (1,2)
	and C.IRN<>'<Generate Reference>'	-- indicates the Case already exists
	and ( UPPER(T.USERCODE)<>UPPER(I.CHARACTERDATA )
	 or  (T.USERCODE is null     AND I.CHARACTERDATA is not null)
	 or  (T.USERCODE is not null AND I.CHARACTERDATA is null))"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo=@pnBatchNo
	Set @nFailedCount=@@Rowcount

	If  @nErrorCode=0
	and @nFailedCount>0
	Begin
		exec @nErrorCode=ip_ImportJournalError	@pnUserIdentityId=@pnUserIdentityId,
							@psCulture=@psCulture,
							@pnBatchNo=@pnBatchNo,
							@pnPolicingBatchNo=@nPolicingBatchNo,
							@psTransType='ENTITY SIZE'
	End

	-- Update the ENTITY SIZE column on Cases if the transaction is not Validate Only

	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update CASES
		Set ENTITYSIZE=T.TABLECODE
		from CASES C
		join IMPORTJOURNAL I	on (I.CASEID=C.CASEID)
		left join TABLECODES T	on (T.TABLECODE=(select min(T1.TABLECODE)
							 from TABLECODES T1
							 where T1.TABLETYPE=26
							 and T1.USERCODE=I.CHARACTERDATA))
		where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='ENTITY SIZE'
		and isnull(I.PROCESSEDFLAG,0)=0
		and isnull(I.VALIDATEONLYFLAG,0) in (0,2)
		and I.REJECTREASON is null"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
	End

	-- Update the valid transactions to indicate they have been processed.
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update IMPORTJOURNAL
		Set PROCESSEDFLAG=1,
		    REJECTREASON=NULL,
		    ERROREVENTNO=NULL
		from IMPORTJOURNAL I
		join CASES C		on (C.CASEID=I.CASEID)
		left join TABLECODES T	on (T.TABLECODE=C.ENTITYSIZE)
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='ENTITY SIZE'
		and isnull(I.PROCESSEDFLAG,0)=0
		and ( T.USERCODE=I.CHARACTERDATA or (T.USERCODE is null and I.CHARACTERDATA is null))"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
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

-- TransactionType ===> CASE OFFICE

If  @nCaseOfficeCount>0
and @nErrorCode=0
Begin
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Update the transactions that have failed the data comparison
	Set @sSQLString="
	Update IMPORTJOURNAL
	Set PROCESSEDFLAG=0,
	    REJECTREASON='CASE OFFICE does not match Case'
	from IMPORTJOURNAL I
	join CASES C		on (C.CASEID=I.CASEID)
	left join OFFICE O	on (O.OFFICEID=C.OFFICEID)
	Where I.IMPORTBATCHNO=@pnBatchNo
	and I.TRANSACTIONTYPE='CASE OFFICE'
	and isnull(I.PROCESSEDFLAG,0)=0
	and I.VALIDATEONLYFLAG in (1,2)
	and C.IRN<>'<Generate Reference>'	-- indicates the Case already exists
	and ( UPPER(O.USERCODE)<>UPPER(I.CHARACTERDATA )
	 or  (O.USERCODE is null     AND I.CHARACTERDATA is not null)
	 or  (O.USERCODE is not null AND I.CHARACTERDATA is null))"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo=@pnBatchNo
	Set @nFailedCount=@@Rowcount

	If  @nErrorCode=0
	and @nFailedCount>0
	Begin
		exec @nErrorCode=ip_ImportJournalError	@pnUserIdentityId=@pnUserIdentityId,
							@psCulture=@psCulture,
							@pnBatchNo=@pnBatchNo,
							@pnPolicingBatchNo=@nPolicingBatchNo,
							@psTransType='CASE OFFICE'
	End

	-- Update the CASE OFFICE column on Cases if the transaction is not Validate Only

	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update CASES
		Set OFFICEID=O.OFFICEID
		from CASES C
		join IMPORTJOURNAL I	on (I.CASEID=C.CASEID)
		left join OFFICE O	on (O.OFFICEID=( select min(O1.OFFICEID)
							 from OFFICE O1
							 where O1.USERCODE=I.CHARACTERDATA))
		where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='CASE OFFICE'
		and isnull(I.PROCESSEDFLAG,0)=0
		and isnull(I.VALIDATEONLYFLAG,0) in (0,2)
		and I.REJECTREASON is null"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
	End

	-- Update the valid transactions to indicate they have been processed.
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update IMPORTJOURNAL
		Set PROCESSEDFLAG=1,
		    REJECTREASON=NULL,
		    ERROREVENTNO=NULL
		from IMPORTJOURNAL I
		join CASES C		on (C.CASEID=I.CASEID)
		left join OFFICE O	on (O.OFFICEID=C.OFFICEID)
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='CASE OFFICE'
		and isnull(I.PROCESSEDFLAG,0)=0
		and ( O.USERCODE=I.CHARACTERDATA or (O.USERCODE is null and I.CHARACTERDATA is null))"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
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

-- TransactionType ===> EVENT DATE - ValidateOnly

If  @nEventDateCount>0
and @nErrorCode=0
Begin
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Update the transactions that have failed the data comparison
	Set @sSQLString="
	Update IMPORTJOURNAL
	Set PROCESSEDFLAG=0,
	    REJECTREASON=CASE WHEN(CE2.EVENTDATE<>I.DATEDATA)
				THEN 'Event Date does not match with CaseEvent Date'
			      WHEN(CE2.EVENTDATE is null)
				THEN 'Event does not match with case'
			 END
	from IMPORTJOURNAL I
	join CASES C		on (C.CASEID=I.CASEID)
	left join ACTIONS A	on (A.ACTION=I.ACTION)
	left join OPENACTION OA	on (OA.CASEID=I.CASEID
				and OA.ACTION=I.ACTION
				and OA.CYCLE=(select max(CYCLE)
					      from OPENACTION OA1
					      where OA1.CASEID=OA.CASEID
					      and OA1.ACTION=I.ACTION
					      and OA1.POLICEEVENTS=1))
	left join CASEEVENT CE1	on (CE1.CASEID=I.CASEID
				and CE1.EVENTNO=I.NUMBERKEY
				and CE1.CYCLE=(	select max(CYCLE)
						from CASEEVENT CE11
						where CE11.CASEID=CE1.CASEID
						and CE11.EVENTNO=I.NUMBERKEY))
	left join CASEEVENT CE2	on (CE2.CASEID=I.CASEID
				and CE2.EVENTNO=I.NUMBERKEY
				and CE2.CYCLE=	CASE WHEN(I.CYCLE is not null)
							THEN I.CYCLE
							ELSE CASE(I.RELATIVECYCLE)
								-- Current Cycle
								-- If the Action is cyclic then use the current open action
								-- else use the highest cycle for the Event.
								WHEN(0) THEN CASE WHEN(A.NUMCYCLESALLOWED>1 and OA.CYCLE is not null)
										THEN OA.CYCLE
										ELSE isnull(CE1.CYCLE,1)
									     END
								-- Previous Cycle
								WHEN(1) THEN CASE WHEN(A.NUMCYCLESALLOWED>1 and OA.CYCLE is not null)
										THEN OA.CYCLE-1
										ELSE isnull(CE1.CYCLE,1)-1
									     END
								-- Next Cycle
								WHEN(2) THEN CASE WHEN(A.NUMCYCLESALLOWED>1 and OA.CYCLE is not null)
										THEN OA.CYCLE+1
										ELSE isnull(CE1.CYCLE,0)+1
									     END
								-- First Cycle
								WHEN(3) THEN 1
								-- Highest Cycle
								WHEN(4) THEN CE1.CYCLE
								-- Current(if due) otherwise next
								WHEN(5) THEN CASE WHEN(CE1.OCCURREDFLAG=0)
										THEN CE1.CYCLE
										ELSE isnull(CE1.CYCLE,0)+1
									     END
							     END
						END)
	Where I.IMPORTBATCHNO=@pnBatchNo
	and I.TRANSACTIONTYPE='EVENT DATE'
	and I.VALIDATEONLYFLAG in (1,2)
	and C.IRN<>'<Generate Reference>'	-- indicates the Case already exists
	and isnull(I.PROCESSEDFLAG,0)=0
	and (CE2.CASEID is not null OR I.VALIDATEONLYFLAG<>2) -- CaseEvent must exist for VALIDATEONLYFLAG=2
	and (CE2.EVENTDATE<>I.DATEDATA OR CE2.EVENTDATE is null)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo=@pnBatchNo
	Set @nFailedCount=@@Rowcount

	-- If transactions failed call the stored procedure to take any action required.

	If  @nErrorCode=0
	and @nFailedCount>0
	Begin
		exec @nErrorCode=ip_ImportJournalError	@pnUserIdentityId=@pnUserIdentityId,
							@psCulture=@psCulture,
							@pnBatchNo=@pnBatchNo,
							@pnPolicingBatchNo=@nPolicingBatchNo,
							@psTransType='EVENT DATE'
	End

	-- Update the ValidateOnly transactions that have passed the data comparison
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update IMPORTJOURNAL
		Set PROCESSEDFLAG=1,
		    REJECTREASON=NULL,
		    ERROREVENTNO=NULL
		from IMPORTJOURNAL I
		left join ACTIONS A	on (A.ACTION=I.ACTION)
		left join OPENACTION OA	on (OA.CASEID=I.CASEID
					and OA.ACTION=I.ACTION
					and OA.CYCLE=(select max(CYCLE)
						      from OPENACTION OA1
						      where OA1.CASEID=OA.CASEID
						      and OA1.ACTION=I.ACTION
						      and OA1.POLICEEVENTS=1))
		join CASEEVENT CE1	on (CE1.CASEID=I.CASEID
					and CE1.EVENTNO=I.NUMBERKEY
					and CE1.CYCLE=(	select max(CYCLE)
							from CASEEVENT CE11
							where CE11.CASEID=CE1.CASEID
							and CE11.EVENTNO=I.NUMBERKEY))
		join CASEEVENT CE2	on (CE2.CASEID=I.CASEID
					and CE2.EVENTNO=I.NUMBERKEY
					and CE2.CYCLE=	CASE WHEN(I.CYCLE is not null)
								THEN I.CYCLE
								ELSE CASE(I.RELATIVECYCLE)
									-- Current Cycle
									-- If the Action is cyclic then use the current open action
									-- else use the highest cycle for the Event.
									WHEN(0) THEN CASE WHEN(A.NUMCYCLESALLOWED>1 and OA.CYCLE is not null)
											THEN OA.CYCLE
											ELSE isnull(CE1.CYCLE,1)
										     END
									-- Previous Cycle
									WHEN(1) THEN CASE WHEN(A.NUMCYCLESALLOWED>1 and OA.CYCLE is not null)
											THEN OA.CYCLE-1
											ELSE isnull(CE1.CYCLE,1)-1
										     END
									-- Next Cycle
									WHEN(2) THEN CASE WHEN(A.NUMCYCLESALLOWED>1 and OA.CYCLE is not null)
											THEN OA.CYCLE+1
											ELSE isnull(CE1.CYCLE,0)+1
										     END
									-- First Cycle
									WHEN(3) THEN 1
									-- Highest Cycle
									WHEN(4) THEN CE1.CYCLE
									-- Current(if due) otherwise next
									WHEN(5) THEN CASE WHEN(CE1.OCCURREDFLAG=0)
											THEN CE1.CYCLE
											ELSE isnull(CE1.CYCLE,0)+1
										     END
								     END
							END)
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='EVENT DATE'
		and I.VALIDATEONLYFLAG in (1,2)
		and isnull(I.PROCESSEDFLAG,0)=0
		and CE2.EVENTDATE=I.DATEDATA"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
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

-- TransactionType ===> EVENT TEXT - ValidateOnly

If  @nEventTextCount>0
and @nErrorCode=0
Begin
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Update the transactions that have failed the data comparison
	Set @sSQLString="
	Update IMPORTJOURNAL
	Set PROCESSEDFLAG=0,
	    REJECTREASON='Event Text does not match with CaseEvent Event Text'
	from IMPORTJOURNAL I
	join CASES C		on (C.CASEID=I.CASEID)
	left join ACTIONS A	on (A.ACTION=I.ACTION)
	left join OPENACTION OA	on (OA.CASEID=I.CASEID
				and OA.ACTION=I.ACTION
				and OA.CYCLE=(select max(CYCLE)
					      from OPENACTION OA1
					      where OA1.CASEID=OA.CASEID
					      and OA1.ACTION=I.ACTION
					      and OA1.POLICEEVENTS=1))
	left join CASEEVENT CE1	on (CE1.CASEID=I.CASEID
				and CE1.EVENTNO=I.NUMBERKEY
				and CE1.CYCLE=(	select max(CYCLE)
						from CASEEVENT CE11
						where CE11.CASEID=CE1.CASEID
						and CE11.EVENTNO=I.NUMBERKEY))
	left join CASEEVENT CE2	on (CE2.CASEID=I.CASEID
				and CE2.EVENTNO=I.NUMBERKEY
				and CE2.CYCLE=	CASE WHEN(I.CYCLE is not null)
							THEN I.CYCLE
							ELSE CASE(I.RELATIVECYCLE)
								-- Current Cycle
								-- If the Action is cyclic then use the current open action
								-- else use the highest cycle for the Event.
								WHEN(0) THEN CASE WHEN(A.NUMCYCLESALLOWED>1 and OA.CYCLE is not null)
										THEN OA.CYCLE
										ELSE isnull(CE1.CYCLE,1)
									     END
								-- Previous Cycle
								WHEN(1) THEN CASE WHEN(A.NUMCYCLESALLOWED>1 and OA.CYCLE is not null)
										THEN OA.CYCLE-1
										ELSE isnull(CE1.CYCLE,1)-1
									     END
								-- Next Cycle
								WHEN(2) THEN CASE WHEN(A.NUMCYCLESALLOWED>1 and OA.CYCLE is not null)
										THEN OA.CYCLE+1
										ELSE isnull(CE1.CYCLE,0)+1
									     END
								-- First Cycle
								WHEN(3) THEN 1
								-- Highest Cycle
								WHEN(4) THEN CE1.CYCLE
								-- Current(if due) otherwise next
								WHEN(5) THEN CASE WHEN(CE1.OCCURREDFLAG=0)
										THEN CE1.CYCLE
										ELSE isnull(CE1.CYCLE,0)+1
									     END
							     END
						END)
	Where I.IMPORTBATCHNO=@pnBatchNo
	and I.TRANSACTIONTYPE='EVENT TEXT'
	and I.VALIDATEONLYFLAG in (1,2)
	and C.IRN<>'<Generate Reference>'	-- indicates the Case already exists
	and isnull(I.PROCESSEDFLAG,0)=0
	and (CE2.CASEID is not null OR I.VALIDATEONLYFLAG<>2) -- CaseEvent must exist for VALIDATEONLYFLAG=2
	and (isnull(convert(nvarchar(4000),CE2.EVENTLONGTEXT),CE2.EVENTTEXT) <> isnull(convert(nvarchar(4000),I.TEXTDATA),I.CHARACTERDATA)	-- RCT 16/11/2004 Removed extra closing parenthesis at end of line
	 or  (CE2.EVENTLONGTEXT is null and CE2.EVENTTEXT is null))"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo=@pnBatchNo
	Set @nFailedCount=@@Rowcount

	-- If transactions failed call the stored procedure to take any action required.

	If  @nErrorCode=0
	and @nFailedCount>0
	Begin
		exec @nErrorCode=ip_ImportJournalError	@pnUserIdentityId=@pnUserIdentityId,
							@psCulture=@psCulture,
							@pnBatchNo=@pnBatchNo,
							@pnPolicingBatchNo=@nPolicingBatchNo,
							@psTransType='EVENT TEXT'
	End

	-- Update the ValidateOnly transactions that have passed the data comparison
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Update IMPORTJOURNAL
		Set PROCESSEDFLAG=1,
		    REJECTREASON=NULL,
		    ERROREVENTNO=NULL
		from IMPORTJOURNAL I
		left join ACTIONS A	on (A.ACTION=I.ACTION)
		left join OPENACTION OA	on (OA.CASEID=I.CASEID
					and OA.ACTION=I.ACTION
					and OA.CYCLE=(select max(CYCLE)
						      from OPENACTION OA1
						      where OA1.CASEID=OA.CASEID
						      and OA1.ACTION=I.ACTION
						      and OA1.POLICEEVENTS=1))
		join CASEEVENT CE1	on (CE1.CASEID=I.CASEID
					and CE1.EVENTNO=I.NUMBERKEY
					and CE1.CYCLE=(	select max(CYCLE)
							from CASEEVENT CE11
							where CE11.CASEID=CE1.CASEID
							and CE11.EVENTNO=I.NUMBERKEY))
		join CASEEVENT CE2	on (CE2.CASEID=I.CASEID
					and CE2.EVENTNO=I.NUMBERKEY
					and CE2.CYCLE=	CASE WHEN(I.CYCLE is not null)
								THEN I.CYCLE
								ELSE CASE(I.RELATIVECYCLE)
									-- Current Cycle
									-- If the Action is cyclic then use the current open action
									-- else use the highest cycle for the Event.
									WHEN(0) THEN CASE WHEN(A.NUMCYCLESALLOWED>1 and OA.CYCLE is not null)
											THEN OA.CYCLE
											ELSE isnull(CE1.CYCLE,1)
										     END
									-- Previous Cycle
									WHEN(1) THEN CASE WHEN(A.NUMCYCLESALLOWED>1 and OA.CYCLE is not null)
											THEN OA.CYCLE-1
											ELSE isnull(CE1.CYCLE,1)-1
										     END
									-- Next Cycle
									WHEN(2) THEN CASE WHEN(A.NUMCYCLESALLOWED>1 and OA.CYCLE is not null)
											THEN OA.CYCLE+1
											ELSE isnull(CE1.CYCLE,0)+1
										     END
									-- First Cycle
									WHEN(3) THEN 1
									-- Highest Cycle
									WHEN(4) THEN CE1.CYCLE
									-- Current(if due) otherwise next
									WHEN(5) THEN CASE WHEN(CE1.OCCURREDFLAG=0)
											THEN CE1.CYCLE
											ELSE isnull(CE1.CYCLE,0)+1
										     END
								     END
							END)
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE='EVENT TEXT'
		and I.VALIDATEONLYFLAG in (1,2)
		and isnull(I.PROCESSEDFLAG,0)=0
		and (isnull(convert(nvarchar(4000),CE2.EVENTLONGTEXT),CE2.EVENTTEXT) = isnull(convert(nvarchar(4000),I.TEXTDATA),I.CHARACTERDATA))"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo
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


-- TransactionType ===> DUE DATE; EVENT DATE & EVENT TEXT - update

If (@nDueDateCount+@nEventDateCount+@nEventTextCount>0
or  @nRelationCreateCount >0)
and @nErrorCode=0
Begin
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Load the temporary table with the CaseEvent details to be updated from the Event transactions.
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Insert into #TEMPCASEEVENT(CASEID,TRANSACTIONNO,ACTION,EVENTNO,EVENTDATE,EVENTDUEDATE,LONGFLAG,EVENTTEXT,EVENTLONGTEXT, 
					 JOURNALNO,TRANTYPE,CYCLE)
		Select	I.CASEID, I.TRANSACTIONNO, I.ACTION, I.NUMBERKEY,
			CASE WHEN(I.TRANSACTIONTYPE='EVENT DATE') THEN I.DATEDATA ELSE NULL END,
			CASE WHEN(I.TRANSACTIONTYPE='DUE DATE')   THEN I.DATEDATA ELSE NULL END,
			CASE WHEN(datalength(I.TEXTDATA)>508) THEN 1    ELSE 0 END,
			CASE WHEN(datalength(I.TEXTDATA)>508) THEN NULL ELSE isnull(convert(nvarchar(254),I.TEXTDATA), I.CHARACTERDATA) END,
			CASE WHEN(datalength(I.TEXTDATA)>508) THEN I.TEXTDATA END,
			I.JOURNALNO, I.TRANSACTIONTYPE,
			-- Determine the Cycle either from the explicitly provided Cycle or
			-- base on a Relative Cycle rule which will consider the Action if it
			-- is open and cyclic as well as the current maximum cycle
			CASE WHEN(I.CYCLE is not null)
				THEN I.CYCLE
				ELSE CASE(I.RELATIVECYCLE)
					-- Current Cycle
					-- If the Action is cyclic then use the current open action
					-- else use the highest cycle for the Event.
					WHEN(0) THEN CASE WHEN(A.NUMCYCLESALLOWED>1 and OA.CYCLE is not null)
							THEN OA.CYCLE
							ELSE isnull(CE1.CYCLE,1)
						     END
					-- Previous Cycle
					WHEN(1) THEN CASE WHEN(A.NUMCYCLESALLOWED>1 and OA.CYCLE is not null)
							THEN OA.CYCLE-1
							ELSE isnull(CE1.CYCLE,1)-1
						     END
					-- Next Cycle
					WHEN(2) THEN CASE WHEN(A.NUMCYCLESALLOWED>1 and OA.CYCLE is not null)
							THEN OA.CYCLE+1
							ELSE isnull(CE1.CYCLE,0)+1
						     END
					-- First Cycle
					WHEN(3) THEN 1
					-- Highest Cycle
					WHEN(4) THEN CE1.CYCLE
					-- Current(if due) otherwise next
					WHEN(5) THEN CASE WHEN(CE1.OCCURREDFLAG=0)
							THEN CE1.CYCLE
							ELSE isnull(CE1.CYCLE,0)+1
						     END
				     END
			END
		from IMPORTJOURNAL I
		left join ACTIONS A	on (A.ACTION=I.ACTION)
		left join OPENACTION OA	on (OA.CASEID=I.CASEID
					and OA.ACTION=I.ACTION
					and OA.CYCLE=(select max(CYCLE)
						      from OPENACTION OA1
						      where OA1.CASEID=OA.CASEID
						      and OA1.ACTION=I.ACTION
						      and OA1.POLICEEVENTS=1))
		left join CASEEVENT CE1	on (CE1.CASEID=I.CASEID
					and CE1.EVENTNO=I.NUMBERKEY
					and CE1.CYCLE=(	select max(CYCLE)
							from CASEEVENT CE11
							where CE11.CASEID=CE1.CASEID
							and CE11.EVENTNO=I.NUMBERKEY))
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE in ('EVENT TEXT','EVENT DATE','DUE DATE')
		and I.NUMBERKEY is not null
		and (I.CYCLE is not null or I.RELATIVECYCLE is not null)
		and isnull(I.VALIDATEONLYFLAG,0) in (0,2)
		and isnull(I.PROCESSEDFLAG,0)=0
		and I.REJECTREASON is null
		order by 1,4,5,6"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo

		Set @nRowCount=@@RowCount
	End

	-- SQA15439
	-- if multiple rows have been inserted into #TEMPCASEEVENT for the same CASEID, EVENTNO & CYCLE
	-- where the Cycle was determined by a Next Cycle relative cycle rule, then we need to increment
	-- these cycles
	If @nErrorCode=0
	and @nRowCount>0
	Begin
		Set @nCaseId =''
		Set @nEventNo=''
		Set @nCycle  =''

		set @sSQLString="
		Update #TEMPCASEEVENT
		Set	@nCycle=
			CASE WHEN(@nCaseId<>T.CASEID OR @nEventNo<>T.EVENTNO OR @nCycle<>T.CYCLE)
				THEN T.CYCLE
				ELSE @nCycle+1
			END,
			CYCLE = @nCycle,
			@nCaseId=T.CASEID,
			@nEventNo=T.EVENTNO
		from #TEMPCASEEVENT T
		join IMPORTJOURNAL I on (I.TRANSACTIONNO=T.TRANSACTIONNO)
		join (	select TX.CASEID,TX.EVENTNO,TX.CYCLE
			from #TEMPCASEEVENT TX
			join IMPORTJOURNAL IX on (IX.TRANSACTIONNO=TX.TRANSACTIONNO)
			where IX.IMPORTBATCHNO=@pnBatchNo
			and IX.RELATIVECYCLE in (2,5)
			group by TX.CASEID,TX.EVENTNO,TX.CYCLE
			having count(*)>1) T1	on (T1.CASEID =T.CASEID
						and T1.EVENTNO=T.EVENTNO
						and T1.CYCLE  =T.CYCLE)
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.RELATIVECYCLE in (2,5)"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@nCaseId	int		OUTPUT,
					  @nEventNo	int		OUTPUT,
					  @nCycle	smallint	OUTPUT,
					  @pnBatchNo	int',
					  @nCaseId  =@nCaseId		OUTPUT,
					  @nEventNo =@nEventNo		OUTPUT,
					  @nCycle   =@nCycle		OUTPUT,
					  @pnBatchNo=@pnBatchNo

	End

	-- SQA11232
	-- Load a temporary table with the CaseEvent details to be updated as a result of a
	-- Related Case transaction
	
	If @nRelationCreateCount>0
	and @nErrorCode=0
	Begin
		Set @sSQLString="
		Insert into #TEMPCASEEVENT(CASEID,TRANSACTIONNO,EVENTNO,CYCLE,EVENTDATE,
					   JOURNALNO,TRANTYPE)
		Select	I.CASEID, I.TRANSACTIONNO, isnull(RC1.EVENTNO,RC2.EVENTNO),1, isnull(RC1.PRIORITYDATE,RC2.PRIORITYDATE),
			I.JOURNALNO, I.TRANSACTIONTYPE
		from IMPORTJOURNAL I
		left join (select min(isnull(CE.EVENTDATE, R.PRIORITYDATE)) as PRIORITYDATE, 
				  R.CASEID, R.RELATIONSHIP, CR.EVENTNO
			   from RELATEDCASE R
			   join CASERELATION CR		on (CR.RELATIONSHIP=R.RELATIONSHIP
							and CR.EARLIESTDATEFLAG=1)
			   left join CASEEVENT CE	on (CE.CASEID=R.RELATEDCASEID
							and CE.EVENTNO=CR.FROMEVENTNO)
			   where CR.FROMEVENTNO is not null
			   and CR.EVENTNO is not null
			   group by R.CASEID, R.RELATIONSHIP, CR.EVENTNO) RC1	
						on (RC1.CASEID=I.CASEID
						and RC1.RELATIONSHIP=I.CHARACTERKEY)
		left join (select max(isnull(CE.EVENTDATE, R.PRIORITYDATE)) as PRIORITYDATE, 
				  R.CASEID, R.RELATIONSHIP, CR.EVENTNO
			   from RELATEDCASE R
			   join CASERELATION CR		on (CR.RELATIONSHIP=R.RELATIONSHIP
							and isnull(CR.EARLIESTDATEFLAG,0)=0)
			   left join CASEEVENT CE	on (CE.CASEID=R.RELATEDCASEID
							and CE.EVENTNO=CR.FROMEVENTNO)
			   where CR.EVENTNO is not null
			   and CR.FROMEVENTNO is not null
			   group by R.CASEID, R.RELATIONSHIP, CR.EVENTNO) RC2	
						on (RC2.CASEID=I.CASEID
						and RC2.RELATIONSHIP=I.CHARACTERKEY)
		left join #TEMPCASEEVENT T	on (T.CASEID=I.CASEID
						and T.EVENTNO=isnull(RC1.EVENTNO,RC2.EVENTNO)
						and T.CYCLE=1)
		Where I.IMPORTBATCHNO=@pnBatchNo
		and I.TRANSACTIONTYPE ='RELATED NUMBER'
		and I.VALIDATEONLYFLAG in (0,2)
		and I.REJECTREASON is null
		and (RC1.EVENTNO is not null or RC2.EVENTNO is not null)
		and T.CASEID is null"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo=@pnBatchNo

		Set @nRowCount=@nRowCount+@@RowCount
	End

	-- If there were rows written to #TEMPCASEEVENT then load them into CASEEVENT
	If @nRowCount>0
	Begin
		-- Load a temporary table with the details of Actions that will need to be
		-- inserted or updated.
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Insert into #TEMPOPENACTION(CASEID, ACTION, CYCLE)
			Select distinct T.CASEID, 
					T.ACTION, 
					CASE WHEN(A.NUMCYCLESALLOWED=1) THEN 1 ELSE T.CYCLE END
			from #TEMPCASEEVENT T
			join ACTIONS A	on (A.ACTION=T.ACTION)
			left join OPENACTION OA	on (OA.CASEID=T.CASEID
						and OA.ACTION=T.ACTION
						and OA.CYCLE=T.CYCLE)
			where (T.CYCLE<=A.NUMCYCLESALLOWED or A.NUMCYCLESALLOWED=1)
			and (OA.CASEID is null OR isnull(OA.POLICEEVENTS,0)=0)"

			exec @nErrorCode=sp_executesql @sSQLString
		End

		-- Update the IMPORTJOURNAL to indicate the transaction has been processed
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Update IMPORTJOURNAL
			Set PROCESSEDFLAG=1
			from IMPORTJOURNAL I
			join #TEMPCASEEVENT T	on (T.CASEID=I.CASEID
						and T.TRANSACTIONNO=I.TRANSACTIONNO)
			where I.IMPORTBATCHNO=@pnBatchNo"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int',
							  @pnBatchNo=@pnBatchNo
		End

		-- Update any preexisting OPENACTION rows
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Update OPENACTION
			Set POLICEEVENTS=1
			from OPENACTION OA
			join #TEMPOPENACTION T	on (T.CASEID=OA.CASEID
						and T.ACTION=OA.ACTION
						and T.CYCLE=OA.CYCLE)"

			Exec @nErrorCode=sp_executesql @sSQLString
		End

		-- Insert new OPENACTION rows
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Insert into OPENACTION(CASEID, ACTION, CYCLE, POLICEEVENTS, DATEENTERED, DATEUPDATED)
			Select distinct T.CASEID, T.ACTION, T.CYCLE, 1, getdate(), getdate()
			From #TEMPOPENACTION T
			left join OPENACTION OA	on (OA.CASEID=T.CASEID
						and OA.ACTION=T.ACTION
						and OA.CYCLE=T.CYCLE)
			Where OA.CASEID is null"
	
			Exec @nErrorCode=sp_executesql @sSQLString
		End

		-- Now insert a Policing row for each OPENACTION updated or inserted.
		-- TypeOfRequest=1 will cause the OpenAction row to be calculated.
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			insert into POLICING (	DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, ONHOLDFLAG,
						CASEID, ACTION, CYCLE, SQLUSER, IDENTITYID,TYPEOFREQUEST, BATCHNO)
			select	getdate(), T.SEQUENCENO, 
				convert(varchar, getdate(),126)+convert(varchar,T.SEQUENCENO),1,
				CASE WHEN(@nPolicingBatchNo is null) THEN 0 ELSE 1 END,
				T.CASEID, T.ACTION, T.CYCLE, substring(SYSTEM_USER,1,60),@pnUserIdentityId, 1,
				@nPolicingBatchNo
			from #TEMPOPENACTION T"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@nPolicingBatchNo	int,
							  @pnUserIdentityId	int',
							  @nPolicingBatchNo=@nPolicingBatchNo,
							  @pnUserIdentityId=@pnUserIdentityId
		End

		-- Update any preexisting CASEEVENT rows
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			update CASEEVENT
			set	EVENTDATE   =CASE WHEN(T.TRANTYPE in ('EVENT DATE','RELATED NUMBER')) 
										THEN T.EVENTDATE    ELSE CE.EVENTDATE END,
				EVENTDUEDATE=CASE WHEN(T.TRANTYPE='DUE DATE')   THEN T.EVENTDUEDATE ELSE CE.EVENTDUEDATE END,
				OCCURREDFLAG=CASE WHEN(T.TRANTYPE='DUE DATE')   THEN 0
						  WHEN(T.TRANTYPE='EVENT DATE' and T.EVENTDATE is null)     THEN 0
						  WHEN(T.TRANTYPE='EVENT DATE' and T.EVENTDATE is not null) THEN 1
						  ELSE CE.OCCURREDFLAG
					     END,
				DATEDUESAVED =CASE WHEN(T.TRANTYPE='DUE DATE' and T.EVENTDUEDATE is not null) THEN 1 ELSE 0 END,
				DATEREMIND   =NULL,
				EVENTTEXT    =T.EVENTTEXT,
				LONGFLAG     =T.LONGFLAG,
				EVENTLONGTEXT=T.EVENTLONGTEXT,
				JOURNALNO    =T.JOURNALNO,
				IMPORTBATCHNO=I.IMPORTBATCHNO
			from CASEEVENT CE
			join #TEMPCASEEVENT T	on (T.CASEID =CE.CASEID
						and T.EVENTNO=CE.EVENTNO
						and T.CYCLE  =CE.CYCLE)
			-- see if this Case has had any transactions rejected in this batch
			left join (	select distinct CASEID, IMPORTBATCHNO
					from IMPORTJOURNAL
					where IMPORTBATCHNO=@pnBatchNo
					and REJECTREASON is not null) I	on (I.CASEID=T.CASEID)
			Where (isnull(CE.OCCURREDFLAG,0)=0 and T.TRANTYPE='DUE DATE')
			OR T.TRANTYPE<>'DUE DATE'"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int',
							  @pnBatchNo=@pnBatchNo
		End
		
		-- Insert new CASEEVENT rows
		If @nErrorCode=0
		Begin
			set @sSQLString="
			insert into CASEEVENT(	CASEID, EVENTNO, CYCLE, EVENTDATE, EVENTDUEDATE, DATEDUESAVED, 
						OCCURREDFLAG, LONGFLAG, EVENTTEXT, EVENTLONGTEXT, JOURNALNO, IMPORTBATCHNO)
			select	T.CASEID, T.EVENTNO, T.CYCLE, T.EVENTDATE, T.EVENTDUEDATE,
				CASE WHEN(T.TRANTYPE='DUE DATE') THEN 1 ELSE 0 END,
				CASE WHEN(T.TRANTYPE='DUE DATE') THEN 0 ELSE 1 END,
				T.LONGFLAG, T.EVENTTEXT, T.EVENTLONGTEXT, T.JOURNALNO, I.IMPORTBATCHNO
			from #TEMPCASEEVENT T
			     join EVENTS E	on (E.EVENTNO =T.EVENTNO)
			left join CASEEVENT CE	on (CE.CASEID =T.CASEID
						and CE.EVENTNO=T.EVENTNO
						and CE.CYCLE  =T.CYCLE)
			-- see if this Case has had any transactions rejected in this batch
			left join (	select distinct CASEID, IMPORTBATCHNO
					from IMPORTJOURNAL
					where IMPORTBATCHNO=@pnBatchNo
					and REJECTREASON is not null) I	on (I.CASEID=T.CASEID)
			where CE.CASEID is null
			and (T.EVENTDATE is not null OR T.EVENTDUEDATE is not null)
			and T.TRANSACTIONNO=(	select max(T1.TRANSACTIONNO)
						from #TEMPCASEEVENT T1
						where T1.CASEID=T.CASEID
						and T1.EVENTNO=T.EVENTNO
						and T1.CYCLE=T.CYCLE)"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int',
							  @pnBatchNo=@pnBatchNo
		End

		-- Now insert a Policing row for each CASEEVENT updated or inserted.
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			insert into POLICING (	DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, ONHOLDFLAG,
						EVENTNO, CASEID, CYCLE, SQLUSER, IDENTITYID,TYPEOFREQUEST, BATCHNO)
			select	getdate(), T.TRANSACTIONNO, 
				convert(varchar, getdate(),126)+convert(varchar,T.TRANSACTIONNO),1,
				CASE WHEN(@nPolicingBatchNo is null) THEN 0 ELSE 1 END,
				T.EVENTNO, T.CASEID, T.CYCLE, substring(SYSTEM_USER,1,60),@pnUserIdentityId,
				CASE 	WHEN(T.TRANTYPE='EVENT DATE')	  THEN 3
					WHEN(T.TRANTYPE='RELATED NUMBER') THEN 3
					WHEN(T.TRANTYPE='DUE DATE' 
					 and T.EVENTDUEDATE is NULL)	  THEN 3
					WHEN(T.TRANTYPE='DUE DATE')	  THEN 2
				END,
				@nPolicingBatchNo
			from #TEMPCASEEVENT T
			join EVENTS E	on (E.EVENTNO=T.EVENTNO)
			where T.TRANTYPE in ('EVENT DATE','DUE DATE', 'RELATED NUMBER')"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@nPolicingBatchNo	int,
							  @pnUserIdentityId	int',
							  @nPolicingBatchNo=@nPolicingBatchNo,
							  @pnUserIdentityId=@pnUserIdentityId
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

-- For newly created Cases Keywords are to be generated

If  @nErrorCode=0
Begin
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Pass a parameter to the Keyword generating routine that limits the
	-- generation of keywords to those Cases that do not have an IRN
	exec @nErrorCode=dbo.cs_InsertKeyWordsFromTitle
					@pbCasesWithNoIRN=1

	-- Commit entire transaction if successful
	If @@TranCount > @nTranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

-- For newly created Cases the IRN will now need to be generated.

If  @nErrorCode=0
Begin
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Any CASES that have been created as result of loading this batch will now require
	-- the IRN to be generated.

	Set @sSQLString="
	Select @nCaseId=min(I.CASEID)
	from IMPORTJOURNAL I
	join CASES C	on (C.CASEID=I.CASEID)
	Where I.IMPORTBATCHNO=@pnBatchNo
	and C.IRN='<Generate Reference>'"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nCaseId	int	OUTPUT,
					  @pnBatchNo	int',
					  @nCaseId  =@nCaseId	OUTPUT,
					  @pnBatchNo=@pnBatchNo

	While @nCaseId is not null
	and @nErrorCode=0
	Begin
		-- Call a stored procedure to get the IRN to use for the Case
		Set @sIRN=NULL
		
		exec @nErrorCode=dbo.cs_ApplyGeneratedReference
						@psCaseReference=@sIRN	OUTPUT,
						@pnUserIdentityId=@pnUserIdentityId,
						@psCulture	=@psCulture,
						@pnCaseKey	=@nCaseId

		-- Now Update the CASES table with the generated IRN
		If @nErrorCode=0
		and @sIRN is not null
		Begin
			Set @sSQLString="
			Update CASES
			Set IRN=@sIRN
			Where CASEID=@nCaseId
			and IRN='<Generate Reference>'"

			exec @nErrorCode=sp_executesql @sSQLString,
							N'@nCaseId	int,
							  @sIRN		nvarchar(30)',
							  @nCaseId=@nCaseId,
							  @sIRN=@sIRN
		End

		-- Get the next CASEID that does not have an IRN
		-- and was created in the current batch

		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @nCaseId=min(C.CASEID)
			from IMPORTJOURNAL I
			join CASES C	on (C.CASEID=I.CASEID)
			Where I.IMPORTBATCHNO=@pnBatchNo
			and I.CASEID>@nCaseId
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

-- Policing
-- If Policing is to be run immediately then a Batch Number will have been assigned to each Policing
-- request raised.  Run Policing for this entire batch.

If @nPolicingBatchNo is not null
Begin
	Exec @nErrorCode=ipu_Policing	@pnBatchNo=@nPolicingBatchNo,
					@pnUserIdentityId=@pnUserIdentityId
End

RETURN @nErrorCode
go

grant execute on dbo.ip_ImportJournalProcess to public
go
