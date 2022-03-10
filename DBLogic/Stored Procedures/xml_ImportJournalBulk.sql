-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xml_ImportJournalBulk
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[xml_ImportJournalBulk]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.xml_ImportJournalBulk.'
	Drop procedure [dbo].[xml_ImportJournalBulk]
End
Print '**** Creating Stored Procedure dbo.xml_ImportJournalBulk...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO

CREATE PROCEDURE dbo.xml_ImportJournalBulk
			@pnRowCount		int=0	OUTPUT,
			@psUserName		nvarchar(40),
			@pnMode			int=2,			--- 1 = Cleanup, 2 = Process (default)
			@pnUserIdentityId	int	= null
			
AS
-- PROCEDURE :	xml_ImportJournalBulk
-- VERSION :	34
-- SCOPE:	CPA Inprotech
-- DESCRIPTION:	Import any number of Import Journal transactions initially delivered in an xml file.
-- MATCHING SCHEMA: The import procedure assumes that the xml file has been processed using 
--		Bulk XML and the mapping schema named ImportJournalBulk.xsd. Bulk XML will  
--		have created and populated the table defined by ImportJournalBulk.xsd 
--		called IMPORTJOURNALBULK.
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited--
-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
--    SEP 2003	AvdA   		1	Procedure shell - this version does nothing!
-- 17 OCT 2003	AvdA	  		Complete stored procedure to insert the Import Journal 
-- 				 	for processing via Import Journal program.
-- 22 OCT 2003	MF		2	Add in the code that inserts or updates an Event for any imported
--					row found to be in error somehow.
-- 14 NOV 2003	RCTT		3	Each TRANSACTIONTYPE was being inserted with a PROCESSEDFLAG equal to 1,
--					indicating that it had been processed. This has been changed, so that on
--					insertion of the TRANSACTIONTYPE the PROCESSEDFLAG is set equal to 0, 
--					indicating that the row needs to be processed, and an update statement
--					has been included to set the PROCESSEDFLAG equal to 1 where the REJECTREASON
--					is not NULL
-- 24 NOV 2003	AvdA		4	Let the bulk load mapping schema create the table rather than creating it first.
--					Add a column to IMPORTJOURNALBULK to hold the CASEID and add the auto-identity column TRANSACTIONNO. 
--					Change count(TRANSACTIONNO) to count(1).
--					Drop the IMPORTJOURNALBULK table when processing is complete.
-- 30 MAR 2004	MF		5	Code correction to GETDATE missing ()
-- 01 APR 2004	MF		6	On successfully loading the batch call the ip_ImportJournalProcess
--					stored procedure to process the transactions.
-- 04 APR 2004	RCT	9627	7	Correct relative cycle for the EVENT DATE, DUE DATE and EVENT TEXT transaction 
--					types to use the current cycle when validating and no specific relative cycle 
--					has been declared. Also, included CharacterData column for insertion into 
--					IMPORTJOURNAL for the EVENT DATE, DUE DATE and EVENT TEXT transaction types.
-- 05 APR 2004	RCT	9627	8	Change COUNTRY to COUNTRYCODE
-- 05 APR 2004	MF		9	Create a stub Case for any entries in the journal that do not have a 
--					matching Case in the database.
-- 16 Jun 2004	MF	10184	10	Extend the IMPORTJOURNALBULK table to include CASECATEGORY, SUBTYPE and BASIS
--					and ensure any Cases created includes these columns.
-- 06 Aug 2004	AB	8035	11	Add collate database_default to temp table definitions
-- 22 Sep 2004	RCT	10623	12	Alter Transaction Types EVENT DATE, DUE DATE and EVENT TEXT to include 
--					ValidateOnly flag = 2
-- 16 Nov 2004	RCT	RFC2181	13	On inserting Basis into PROPERTY table include restriction to 
--					CaseType = 'X' (External) as well as CaseType = 'A'
-- 10 Jan 2004	MF	RFC2184	14	Set ANSI_WARNING off. Use LEN function instead of DATALENGTH as LEN returns the
--					number of characters rather than the number of bytes.
-- 8 Feb 2005	PK	10796	13	Add mode to parameters and restructure to remove the temp table when @pnMode = Cleanup
--					and process the stored procedure when @pnMode = Process
-- 17 Mar 2005	MF	11167	15	Increase TRANSACTIONNO to INT
-- 30 Mar 2005	MF	8748	17	Three new columns added to IMPORTJOURANLBULK. BatchType and FromNameNo to be 
--					used in IMPORTBATCH and DECIMALDATA which is to be included in the IMPORTJOURNAL 
--					table.  Create a more sophisticated algorithm for trying to identify if the
--					imported Case already exists on the database.  Allow the creation of a "header"
--					case based upon rules defined in the BATCHTYPERULES table.
--					New transaction types for Entity Size; Number of Claims; Designated States;
--					Reference Number; Estimated Charge
-- 03 Jun 2005	MF	8748	18	Revisit.  Allow imported Cases to not specify a Case Type if the Batch Type
--					Rule indicates the CaseType for imported Cases.
-- 07 Jul 2005	MF	11011	19	Increase CaseCategory column size to NVARCHAR(2)
-- 19 Jul 2005	MF	11641	20	Create a new CASE OFFICE transaction.
-- 22 Jul 2005	MF	11641	21	Correction to 11641 found in testing
-- 25 Jul 2005	PK	11665	22	Swap the parameters around so the OUTPUT parameter is first
-- 16 Aug 2005	MF	11753	23	When considering if a Case is live or not take into consideration
--					both the Case and Renewal Status.
-- 25 Aug 2005	MF	11789	24	Allow an ImportJournalBulk row to be expanded into multiple Cases that all match
--					the Official Number on the transaction.
-- 02 Sep 2005	MF	11789	25	Revisit.  Put an Order By in the insert into ImportJournalBulk to keep the 
--					Cases together.
-- 10 Nov 2005	MF	12051	26	Provide a new flag on the ImportJournalBulk table to indicate that a new Case
--					must always be created even if a matching Case can be found.
-- 15 Nov 2005	MF	12051	27	Revisit.  Ensure that if one of the NUMBER TYPE transactions are used to locate
--					the Case on the database that all of the associated transactions for that same
--					Case are updated with the CASEID.
-- 16 Nov 2005	vql	9704	28	When updating POLICING table insert @pnUserIdentityId.
--					Create 	@pnUserIdentityId parameter.
-- 17 Dec 2007	MF	15754	29	Add CASEID to #TEMPCASES as the column is required to exist to stop 
--					cs_InsertKeyWordsFromTitle from giving an error.
-- 19 Dec 2007	MF	15760	30	The IRN is not allowed to be NULL. Assign a value of <Generate Reference> as
--					an interim measure until the IRN is determined.
-- 08 Oct 2008	MF	16987	31	Disable triggers on IMPORTJOURNAL when the primary key is being modified to ensure
--					a contiguous sequence of transaction numbers.
-- 05 Jul 2013	vql	R13629	32	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 14 Nov 2018  AV  75198/DR-45358	33   Date conversion errors when creating cases and opening names in Chinese DB
-- 19 May 2020	DL	DR-58943	34	Ability to enter up to 3 characters for Number type code via client server	


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET ANSI_WARNINGS OFF	-- normally not recommended however required in this situation

Create table #TEMPTRANS(	TRANSACTIONNO	int		NOT NULL,
				CASEID		int		NOT NULL
				)

Create table #TEMPCASES(	SEQUENCENO	int		identity(0,1),
				OFFICIALNO	nvarchar(36)	collate database_default NOT NULL,
				CASETYPE	nchar(1)	collate database_default NOT NULL,
				PROPERTYTYPE	nchar(1)	collate database_default NULL,
				COUNTRYCODE	nvarchar(3)	collate database_default NULL,
				CASECATEGORY	nvarchar(2)	collate database_default NULL,
				SUBTYPE		nvarchar(2)	collate database_default NULL,
				BASIS		nvarchar(2)	collate database_default NULL,
				REJECTEDFLAG	bit		NULL,
				CASEID		int		NULL	-- SQA15754 column required by cs_InsertKeyWordsFromTitle
				)

Create table #TEMPCASEEVENT(	CASEID		int		NOT NULL,
				TRANSACTIONNO	int		NOT NULL,
				EVENTNO		int		NOT NULL,
				CYCLE		int		NOT NULL,
				REJECTREASON	nvarchar(254) 	collate database_default NOT NULL,
				JOURNALNO	nvarchar(20)  	collate database_default NULL
				)

Create table #TEMPOPENACTION(	CASEID		int		NOT NULL,
				ACTION		nvarchar(2)	collate database_default NOT NULL,
				CYCLE		int		NOT NULL,
				SEQUENCENO	int		identity(1,1)
				)

Create table #TEMPRELATEDCASE(	CASEID      	int		NOT NULL,
				RELATIONSHIPNO	int		identity(0,1),
				RELATIONSHIP	nvarchar(3)	collate database_default NOT NULL,
				RELATEDCASEID	int		NOT NULL,
				CYCLE		int		NULL
				)

Create table #TEMPCASESTOUPDATE(	CASEID		int		NOT NULL,
					ISMODIFIED	bit		NULL)

declare @nTranCountStart 	int,
	@nJournalCount		int,
	@nBatchNo   		int,
	@nRejectCount		int,
	@nTransactionNo		int,
	@sStates		nvarchar(600),
	@dtBatchDate		datetime

declare @nNewCases		int		-- the number of new Cases to be created
declare @nCaseId		int		-- holds the highest CaseId number generated for new cases

-- Variables required for Official Number validation
declare @sNumberType		nvarchar(3),
	@sPropertyType		nchar(1),
	@sCountryCode		nvarchar(3),
	@sOfficialNumber	nvarchar(36),
	@sValidNumber		nvarchar(36),
	@sErrorMessage		nvarchar(254),
	@dtEventDate		datetime,
	@nPatternError		int,
	@nWarningFlag		tinyint

-- Variables used in the Global Name change
declare @nNamesUpdatedCount	int,
	@nNamesInsertedCount	int,
	@nNamesDeletedCount	int

-- Hold details about the BatchTypeRule
declare	@nBatchType		int,
	@nFromNameNo		int,
	@nHeaderCaseId		int,		-- CaseId generated for the Header Case
	@sHeaderCaseType	nchar(1),
	@sHeaderCountry		nvarchar(3),
	@sHeaderProperty	nchar(1),
	@sHeaderCategory	nvarchar(2),
	@sHeaderSubType		nvarchar(2),
	@sHeaderBasis		nvarchar(2),
	@sHeaderTitle		nvarchar(100),
	@sHeaderAction		nvarchar(2),
	@nHeaderStaffName	int,
	@sRelateToValidCase	nvarchar(3),
	@sRelateToReject	nvarchar(3),
	@bInheritToHeader	bit,
	@bInheritToValidCase	bit,
	@bInheritToReject	bit,
	@sProgramId		nvarchar(20),
	@sImportedCaseType	nchar(1),
	@sImportedCountry	nvarchar(3),
	@sImportedProperty	nchar(1),
	@sImportedCategory	nvarchar(2),
	@sImportedSubType	nvarchar(2),
	@sImportedBasis		nvarchar(2),
	@sImportedAction	nvarchar(2),
	@nImportedInstructor	int,
	@nImportedStaffName	int,
	@sRejectedCaseType	nchar(1),
	@sRejectedCountry	nvarchar(3),
	@sRejectedProperty	nchar(1),
	@sRejectedCategory	nvarchar(2),
	@sRejectedSubType	nvarchar(2),
	@sRejectedBasis		nvarchar(2),
	@sRejectedAction	nvarchar(2),
	@nRejectedInstructor	int,
	@nRejectedStaffName	int,
	@sSearchCaseType1	nchar(1),
	@sSearchCaseType2	nchar(1),
	@sInstructorNameType	nvarchar(3)

-- Declare working variables
Declare @bInterimTableExists	bit
Declare @sUserName		nvarchar(40)
Declare	@sSQLString 		nvarchar(4000)
Declare @nErrorCode 		int
Declare @nRowCount		int
Declare @nRowsInserted		int

-- Initialise the errorcode and then set it after each SQL Statement
Set 	@nErrorCode 	=0

-- Process when @pnMode = Process
If  @pnMode = 2
and @nErrorCode=0
Begin
	Set	@nNewCases	= 0

	Set	@pnRowCount	= 0
	Set 	@sUserName	= @psUserName

	-- First check that there are rows to process
	If @nErrorCode=0
	Begin

		set @sSQLString="
			SELECT @nJournalCountOUT=count(1)	
			FROM "+@sUserName+".IMPORTJOURNALBULK"

		Exec @nErrorCode=sp_executesql @sSQLString, 
						N'@nJournalCountOUT	int	   OUTPUT',
						  @nJournalCountOUT=@nJournalCount OUTPUT

		If @nJournalCount = 0
		Begin
			RAISERROR("There are no rows to import.", 16, 1)
			Set @nErrorCode	  = @@Error
		End
	End

	-- Get the BatchType, Date and Source of data
	If @nErrorCode=0
	Begin
		-- Initialise the Batch Type in case there is not one found in the imported batch
		Set @nBatchType=6201

		Set @sSQLString="
		Select 	Top 1
			@nBatchType =BATCHTYPE,
			@nFromNameNo=FROMNAMENO,
			@dtBatchDate=isnull(BATCHDATE,getdate())
		from  "+@sUserName+".IMPORTJOURNALBULK
		where BATCHTYPE is not null
		order by BATCHTYPE,FROMNAMENO,BATCHDATE"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@nBatchType		int		OUTPUT,
					  @nFromNameNo		int		OUTPUT,
					  @dtBatchDate		datetime	OUTPUT',
					  @nBatchType=@nBatchType		OUTPUT,
					  @nFromNameNo=@nFromNameNo		OUTPUT,
					  @dtBatchDate=@dtBatchDate		OUTPUT
	End

	If @nErrorCode=0
	Begin
		-- Get the details for the Batch Type.  If there are
		-- specific details associated with the FROMNAMENO then
		-- use these in preference to a generic rule where
		-- FROMNAMENO is not specified.
		Set @sSQLString="
		Select	TOP 1
			@sHeaderCaseType	=HEADERCASETYPE,
			@sHeaderCountry		=HEADERCOUNTRY,
			@sHeaderProperty	=HEADERPROPERTY,
			@sHeaderCategory	=HEADERCATEGORY,
			@sHeaderSubType		=HEADERSUBTYPE,
			@sHeaderBasis		=HEADERBASIS,
			@sHeaderTitle		=HEADERTITLE,
			@sHeaderAction		=HEADERACTION,
			@nHeaderStaffName	=HEADERSTAFFNAME,
			@sRelateToValidCase	=RELATETOVALIDCASE,
			@sRelateToReject	=RELATETOREJECT,
			@bInheritToHeader	=INHERITTOHEADER,
			@bInheritToValidCase	=INHERITTOVALIDCASE,
			@bInheritToReject	=INHERITTOREJECT,
			@sProgramId		=PROGRAMID,
			@sImportedCaseType	=IMPORTEDCASETYPE,
			@sImportedCountry	=IMPORTEDCOUNTRY,
			@sImportedProperty	=IMPORTEDPROPERTY,
			@sImportedCategory	=IMPORTEDCATEGORY,
			@sImportedSubType	=IMPORTEDSUBTYPE,
			@sImportedBasis		=IMPORTEDBASIS,
			@sImportedAction	=IMPORTEDACTION,
			@nImportedInstructor	=IMPORTEDINSTRUCTOR,
			@nImportedStaffName	=IMPORTEDSTAFFNAME,
			@sRejectedCaseType	=REJECTEDCASETYPE,
			@sRejectedCountry	=REJECTEDCOUNTRY,
			@sRejectedProperty	=REJECTEDPROPERTY,
			@sRejectedCategory	=REJECTEDCATEGORY,
			@sRejectedSubType	=REJECTEDSUBTYPE,
			@sRejectedBasis		=REJECTEDBASIS,
			@sRejectedAction	=REJECTEDACTION,
			@nRejectedInstructor	=REJECTEDINSTRUCTOR,
			@nRejectedStaffName	=REJECTEDSTAFFNAME,
			@sSearchCaseType1	=SEARCHCASETYPE1,
			@sSearchCaseType2	=SEARCHCASETYPE2,
			@sInstructorNameType	=INSTRUCTORNAMETYPE
		From BATCHTYPERULES
		where BATCHTYPE=@nBatchType
		and (isnull(FROMNAMENO,@nFromNameNo)=@nFromNameNo or @nFromNameNo is NULL)
		Order By FROMNAMENO desc"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@sHeaderCaseType	nchar(1)	OUTPUT,
						  @sHeaderCountry	nvarchar(3)	OUTPUT,
						  @sHeaderProperty	nchar(1)	OUTPUT,
						  @sHeaderCategory	nvarchar(2)	OUTPUT,
						  @sHeaderSubType	nvarchar(2)	OUTPUT,
						  @sHeaderBasis		nvarchar(2)	OUTPUT,
						  @sHeaderTitle		nvarchar(100)	OUTPUT,
						  @sHeaderAction	nvarchar(2)	OUTPUT,
						  @nHeaderStaffName	int		OUTPUT,
						  @sRelateToValidCase	nvarchar(3)	OUTPUT,
						  @sRelateToReject	nvarchar(3)	OUTPUT,
						  @bInheritToHeader	bit		OUTPUT,
						  @bInheritToValidCase	bit		OUTPUT,
						  @bInheritToReject	bit		OUTPUT,
						  @sProgramId		nvarchar(20)	OUTPUT,
						  @sImportedCaseType	nchar(1)	OUTPUT,
						  @sImportedCountry	nvarchar(3)	OUTPUT,
						  @sImportedProperty	nchar(1)	OUTPUT,
						  @sImportedCategory	nvarchar(2)	OUTPUT,
						  @sImportedSubType	nvarchar(2)	OUTPUT,
						  @sImportedBasis	nvarchar(2)	OUTPUT,
						  @sImportedAction	nvarchar(2)	OUTPUT,
						  @nImportedInstructor	int		OUTPUT,
						  @nImportedStaffName	int		OUTPUT,
						  @sRejectedCaseType	nchar(1)	OUTPUT,
						  @sRejectedCountry	nvarchar(3)	OUTPUT,
						  @sRejectedProperty	nchar(1)	OUTPUT,
						  @sRejectedCategory	nvarchar(2)	OUTPUT,
						  @sRejectedSubType	nvarchar(2)	OUTPUT,
						  @sRejectedBasis	nvarchar(2)	OUTPUT,
						  @sRejectedAction	nvarchar(2)	OUTPUT,
						  @nRejectedInstructor	int		OUTPUT,
						  @nRejectedStaffName	int		OUTPUT,
						  @sSearchCaseType1	nchar(1)	OUTPUT,
						  @sSearchCaseType2	nchar(1)	OUTPUT,
						  @sInstructorNameType	nvarchar(3)	OUTPUT,
						  @nBatchType		int,
						  @nFromNameNo		int',
						  @sHeaderCaseType	=@sHeaderCaseType	OUTPUT,
						  @sHeaderCountry	=@sHeaderCountry	OUTPUT,
						  @sHeaderProperty	=@sHeaderProperty	OUTPUT,
						  @sHeaderCategory	=@sHeaderCategory	OUTPUT,
						  @sHeaderSubType	=@sHeaderSubType	OUTPUT,
						  @sHeaderBasis		=@sHeaderBasis		OUTPUT,
						  @sHeaderTitle		=@sHeaderTitle		OUTPUT,
						  @sHeaderAction	=@sHeaderAction		OUTPUT,
						  @nHeaderStaffName	=@nHeaderStaffName	OUTPUT,
						  @sRelateToValidCase	=@sRelateToValidCase	OUTPUT,
						  @sRelateToReject	=@sRelateToReject	OUTPUT,
						  @bInheritToHeader	=@bInheritToHeader	OUTPUT,
						  @bInheritToValidCase	=@bInheritToValidCase	OUTPUT,
						  @bInheritToReject	=@bInheritToReject	OUTPUT,
						  @sProgramId		=@sProgramId		OUTPUT,
						  @sImportedCaseType	=@sImportedCaseType	OUTPUT,
						  @sImportedCountry	=@sImportedCountry	OUTPUT,
						  @sImportedProperty	=@sImportedProperty	OUTPUT,
						  @sImportedCategory	=@sImportedCategory	OUTPUT,
						  @sImportedSubType	=@sImportedSubType	OUTPUT,
						  @sImportedBasis	=@sImportedBasis	OUTPUT,
						  @sImportedAction	=@sImportedAction	OUTPUT,
						  @nImportedInstructor	=@nImportedInstructor	OUTPUT,
						  @nImportedStaffName	=@nImportedStaffName	OUTPUT,
						  @sRejectedCaseType	=@sRejectedCaseType	OUTPUT,
						  @sRejectedCountry	=@sRejectedCountry	OUTPUT,
						  @sRejectedProperty	=@sRejectedProperty	OUTPUT,
						  @sRejectedCategory	=@sRejectedCategory	OUTPUT,
						  @sRejectedSubType	=@sRejectedSubType	OUTPUT,
						  @sRejectedBasis	=@sRejectedBasis	OUTPUT,
						  @sRejectedAction	=@sRejectedAction	OUTPUT,
						  @nRejectedInstructor	=@nRejectedInstructor	OUTPUT,
						  @nRejectedStaffName	=@nRejectedStaffName	OUTPUT,
						  @sSearchCaseType1	=@sSearchCaseType1	OUTPUT,
						  @sSearchCaseType2	=@sSearchCaseType2	OUTPUT,
						  @sInstructorNameType	=@sInstructorNameType	OUTPUT,
						  @nBatchType		=@nBatchType,
						  @nFromNameNo		=@nFromNameNo
	
		If @sInstructorNameType is null
			Set @sInstructorNameType='I'

	End

	-- Generate a batch number and insert the data into the IMPORTJOURNAL table
	--  so that it can be processed via the existing Import Journal program.
	If @nErrorCode=0
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
				    @nBatchNoOUT     = INTERNALSEQUENCE + 1
				WHERE  TABLENAME = 'IMPORTBATCH'"

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nBatchNoOUT		int	OUTPUT',
							  @nBatchNoOUT=@nBatchNo	OUTPUT
		End


		-- Now create the new import batch.
		If @nErrorCode=0
		Begin
			set @sSQLString="
				INSERT INTO IMPORTBATCH (IMPORTBATCHNO,BATCHTYPE,IMPORTEDDATE,FROMNAMENO)
				VALUES(@nBatchNo, @nBatchType, @dtBatchDate, @nFromNameNo)"

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nBatchNo	int,
							  @nBatchType	int,
							  @dtBatchDate	datetime,
							  @nFromNameNo	int',
							  @nBatchNo,
							  @nBatchType,
							  @dtBatchDate,
							  @nFromNameNo

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

	If @nErrorCode=0
	Begin
		-- Now start a new transaction
		Select @nTranCountStart = @@TranCount
		BEGIN TRANSACTION

		-- Initial verification
		If @nErrorCode=0
		Begin
			-- Minimum requirement for record to be valid 
			set @sSQLString="
				SELECT @nJournalCountOUT=count(1)
				FROM "+@sUserName+".IMPORTJOURNALBULK
				WHERE (TRANSACTIONTYPE<>'BATCH HEADER' OR TRANSACTIONTYPE IS NULL)
				AND((isnull(CASETYPE,@sImportedCaseType) IS NULL OR PROPERTYTYPE IS NULL OR COUNTRYCODE IS NULL)
				 OR (IRN IS NULL AND CASEOFFICIALNUMBER IS NULL))"

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nJournalCountOUT	int	OUTPUT,
							  @sImportedCaseType	nvarchar(2)',
							  @nJournalCountOUT=@nJournalCount OUTPUT,
							  @sImportedCaseType=@sImportedCaseType

			If @nJournalCount > 0
			Begin
				-- Write error to column in IMPORTBATCH table
				-- for all the rows which don't have enough key data
				If @nErrorCode=0
				Begin
					set @sSQLString="
						UPDATE IMPORTBATCH
						SET BATCHNOTES = BATCHNOTES + CAST (@nJournalCount as nvarchar(10)) + ' records were skipped - required values found empty. '
						WHERE IMPORTBATCHNO = @nBatchNo"

						Exec @nErrorCode=sp_executesql @sSQLString, 
									N'@nJournalCount int,
									  @nBatchNo int',
									  @nJournalCount,
									  @nBatchNo
				End
			End
		End

		If @nErrorCode=0
		Begin
			-- Add CASEID, TRANSACTIONNO, REJECTREASON, REJECTEDFLAG columns for further processing.
			set @sSQLString="
				ALTER TABLE "+@sUserName+".IMPORTJOURNALBULK
				ADD	TRANSACTIONNO	int IDENTITY PRIMARY KEY,
					CASEID 		int,
					REJECTEDFLAG	bit,
					REJECTREASON	nvarchar(254)"

			Exec @nErrorCode=sp_executesql @sSQLString
		End


		If @nErrorCode=0
		Begin
			-- Record CASEID to increase performance and simplicity.
			-- IRN is known
			set @sSQLString="
				UPDATE "+@sUserName+".IMPORTJOURNALBULK
				SET CASEID = C.CASEID
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				JOIN CASES C	ON (C.CASETYPE     = isnull(@sImportedCaseType, IJB.CASETYPE)
						AND C.PROPERTYTYPE = isnull(@sImportedProperty, IJB.PROPERTYTYPE)
						AND C.COUNTRYCODE  = isnull(@sImportedCountry,  IJB.COUNTRYCODE)
						AND C.IRN          = IJB.IRN)
				WHERE IJB.CASEID is null
				and isnull(IJB.FORCECREATECASE,0)=0
				and (C.CURRENTOFFICIALNO=IJB.CASEOFFICIALNUMBER
				 or  C.CURRENTOFFICIALNO is null
				 or  IJB.CASEOFFICIALNUMBER is null)"

			Exec @nErrorCode=sp_executesql @sSQLString,
						N'@sImportedCaseType	nchar(1),
						  @sImportedCountry	nvarchar(3),
						  @sImportedProperty	nchar(1)',
						  @sImportedCaseType=@sImportedCaseType,
						  @sImportedCountry =@sImportedCountry,
						  @sImportedProperty=@sImportedProperty
		End

		If  @sSearchCaseType1 is not null
		and @nErrorCode=0
		Begin
			-- Record CASEID to increase performance and simplicity.
			-- No IRN but Official Number matches and match on SearchCaseType1
			-- Case must be LIVE

			-- Note that the Official Number may match with multiple Cases on the database. If
			-- so then an entry for each Case is to be added to the IMPORTJOURNALBULK table

			Set @sSQLString="
				insert into #TEMPTRANS (TRANSACTIONNO, CASEID)
				SELECT distinct IJB.TRANSACTIONNO, CO.CASEID
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				JOIN CASES CO 	ON (CO.CASETYPE          = @sSearchCaseType1 
						AND CO.PROPERTYTYPE      = isnull(@sImportedProperty,IJB.PROPERTYTYPE)
						AND CO.COUNTRYCODE       = isnull(@sImportedCountry, IJB.COUNTRYCODE))
				JOIN OFFICIALNUMBERS O
						ON (O.CASEID=CO.CASEID
						AND O.OFFICIALNUMBER=IJB.CASEOFFICIALNUMBER
						AND O.ISCURRENT=1)
				JOIN NUMBERTYPES NT
						ON (NT.NUMBERTYPE=O.NUMBERTYPE
						AND NT.ISSUEDBYIPOFFICE=1)
				LEFT JOIN PROPERTY P
						ON (P.CASEID=CO.CASEID)
				LEFT JOIN STATUS S	
						ON (S.STATUSCODE=CO.STATUSCODE)
				LEFT JOIN STATUS R
						ON (R.STATUSCODE=P.RENEWALSTATUS)
				WHERE IJB.CASEID is null
				and isnull(IJB.FORCECREATECASE,0)=0
				and IJB.IRN is null
				and isnull(S.LIVEFLAG,1)=1
				and isnull(R.LIVEFLAG,1)=1"

			Exec @nErrorCode=sp_executesql @sSQLString,
							N'@sSearchCaseType1	nchar(1),
							  @sImportedCaseType	nchar(1),
							  @sImportedCountry	nvarchar(3),
							  @sImportedProperty	nchar(1)',
							  @sSearchCaseType1 =@sSearchCaseType1,
							  @sImportedCaseType=@sImportedCaseType,
							  @sImportedCountry =@sImportedCountry,
							  @sImportedProperty=@sImportedProperty
		End

		If  @sSearchCaseType2 is not null
		and @nErrorCode=0
		Begin
			-- Record CASEID to increase performance and simplicity.
			-- No IRN but Official Number matches and match on SearchCaseType2
			-- Case found does not need to be live
			-- If multiple Cases exist that match the Official Number
			-- then expand the transaction for each Case.
			set @sSQLString="
				insert into #TEMPTRANS (TRANSACTIONNO, CASEID)
				SELECT distinct IJB.TRANSACTIONNO, CO.CASEID
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				LEFT JOIN #TEMPTRANS T
						ON (T.TRANSACTIONNO=IJB.TRANSACTIONNO)
				JOIN CASES CO 	ON (CO.CASETYPE          = @sSearchCaseType2 
						AND CO.PROPERTYTYPE      = isnull(@sImportedProperty,IJB.PROPERTYTYPE)
						AND CO.COUNTRYCODE       = isnull(@sImportedCountry, IJB.COUNTRYCODE))
				JOIN OFFICIALNUMBERS O
						ON (O.CASEID=CO.CASEID
						AND O.OFFICIALNUMBER=IJB.CASEOFFICIALNUMBER
						AND O.ISCURRENT=1)
				JOIN NUMBERTYPES NT
						ON (NT.NUMBERTYPE=O.NUMBERTYPE
						AND NT.ISSUEDBYIPOFFICE=1)
				WHERE IJB.CASEID      is null
				and   IJB.IRN         is null
				and   isnull(IJB.FORCECREATECASE,0)=0
				and   T.TRANSACTIONNO is null"

			Exec @nErrorCode=sp_executesql @sSQLString,
							N'@sSearchCaseType2	nchar(1),
							  @sImportedCaseType	nchar(1),
							  @sImportedCountry	nvarchar(3),
							  @sImportedProperty	nchar(1)',
							  @sSearchCaseType2 =@sSearchCaseType2,
							  @sImportedCaseType=@sImportedCaseType,
							  @sImportedCountry =@sImportedCountry,
							  @sImportedProperty=@sImportedProperty
		End

		-- Commit transaction if successful
		If @@TranCount > @nTranCountStart
		Begin
			If @nErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End

		-- For rows where the CaseId has still not been determined perform the following:
		-- 1. Loop through each transaction that relates to an official number type (NUMBER TYPE)
		--    Ignore any that match the Case Official Number as these have already been searched on
		-- 2. Validate the Official Number against the stored patterns in VALIDATENUMBERS
		-- 3. If a check digit is missing from the Official Number then insert the calculated number
		-- 4. If the Official Number is invalid then mark the transaction with details of the error
		-- 5. When you have a Valid Official Number attempt to find a Case on the database using that
		--    number and update the associated transactions to that CASEID

		If @nErrorCode=0
		Begin
			-- Now start a new transaction
			Select @nTranCountStart = @@TranCount
			BEGIN TRANSACTION

			Set @sSQLString="
				select @nTransactionNo=min(I.TRANSACTIONNO)
				from  "+@sUserName+".IMPORTJOURNALBULK I
				left join #TEMPTRANS T	on (T.TRANSACTIONNO=I.TRANSACTIONNO)
				join NUMBERTYPES N	on (N.NUMBERTYPE=I.CHARACTERKEY)
				Where I.CASEID is null
				and isnull(I.FORCECREATECASE,0)=0
				and I.TRANSACTIONTYPE='NUMBER TYPE'
				and I.CHARACTERDATA<>I.CASEOFFICIALNUMBER
				and T.TRANSACTIONNO is null"

			exec @nErrorCode=sp_executesql @sSQLString,
						N'@nTransactionNo	int		OUTPUT',
						  @nTransactionNo=@nTransactionNo	OUTPUT
		End

		-- 1. Loop through each transaction that relates to an official number type (NUMBER TYPE)
		While @nTransactionNo is not null
		and   @nErrorCode=0
		Begin
			-- Get the Official Number to be validated 
			-- If there is an Event associated with the Number Type then extract
			-- the Event Date from the imported data if it exists as it may be 
			-- required to determine the format of the Official Number
			Set @sSQLString="
				Select 	@sNumberType	=I.CHARACTERKEY,
					@sOfficialNumber=I.CHARACTERDATA,
					@sPropertyType  =I.PROPERTYTYPE,
					@sCountryCode   =I.COUNTRYCODE,
					@dtEventDate    =I2.DATEDATA
				from  "+@sUserName+".IMPORTJOURNALBULK I
				join NUMBERTYPES N	on (N.NUMBERTYPE=I.CHARACTERKEY)
				left join "+@sUserName+".IMPORTJOURNALBULK I2
							on (I2.COUNTRYCODE=I.COUNTRYCODE
							and I2.CASETYPE=I.CASETYPE
							and I2.PROPERTYTYPE=I.PROPERTYTYPE
							and I2.CASEOFFICIALNUMBER=I.CASEOFFICIALNUMBER
							and I2.TRANSACTIONTYPE='EVENT DATE'
							and I2.NUMBERKEY=I.NUMBERKEY)
				where I.TRANSACTIONNO=@nTransactionNo"

			exec @nErrorCode=sp_executesql @sSQLString,
						N'@sNumberType		nvarchar(3)	OUTPUT,
						  @sOfficialNumber	nvarchar(36)	OUTPUT,
						  @sPropertyType	nchar(1)	OUTPUT,
						  @sCountryCode		nvarchar(3)	OUTPUT,
						  @dtEventDate		datetime	OUTPUT,
						  @nTransactionNo	int',
						  @sNumberType	  =@sNumberType		OUTPUT,
						  @sOfficialNumber=@sOfficialNumber	OUTPUT,
						  @sPropertyType  =@sPropertyType	OUTPUT,
						  @sCountryCode   =@sCountryCode	OUTPUT,
						  @dtEventDate	  =@dtEventDate		OUTPUT,
						  @nTransactionNo =@nTransactionNo

			-- 2. Validate the Official Number against the stored patterns in VALIDATENUMBERS

			If @nErrorCode=0
			Begin
				exec @nErrorCode=dbo.ip_ImportValidateOfficialNumber
							@pnPatternError	 =@nPatternError		OUTPUT,
							@psErrorMessage	 =@sErrorMessage		OUTPUT,
							@pnWarningFlag	 =@nWarningFlag			OUTPUT,
							@psValidNumber	 =@sValidNumber			OUTPUT,
							@psNumberType	 =@sNumberType,
							@psOfficialNumber=@sOfficialNumber,
							@psPropertyType	 =@sPropertyType,
							@psCountryCode	 =@sCountryCode,
							@pdtEventDate	 =@dtEventDate
			End

			-- 3. If a check digit is missing from the Official Number then insert the calculated number

			If  @nErrorCode   =0
			and @nPatternError=1  		-- indicates that a problem occurred in the Official Number validation
			and @sValidNumber is not null	-- indicates the check digit has been returned in the Valid Number
			Begin
				Set @sSQLString="
				Update "+@sUserName+".IMPORTJOURNALBULK
				Set CHARACTERDATA=@sValidNumber
				where TRANSACTIONNO=@nTransactionNo"

				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnValidNumber	nvarchar(36),
							  @nTransactionNo	int',
							  @sValidNumber=@sValidNumber,
							  @nTransactionNo=@nTransactionNo
			End

			-- 4. If the Official Number is invalid then mark the transaction with details of the error
			Else If @nErrorCode=0
			     and @nPatternError<>0
			     and @sErrorMessage is not null
			Begin
				Set @sSQLString="
				Update "+@sUserName+".IMPORTJOURNALBULK
				Set REJECTREASON=@sErrorMessage
				where TRANSACTIONNO=@nTransactionNo"

				exec @nErrorCode=sp_executesql @sSQLString,
							N'@sErrorMessage	nvarchar(254),
							  @nTransactionNo	int',
							  @sErrorMessage=@sErrorMessage,
							  @nTransactionNo=@nTransactionNo
				
			End

			-- 5. When you have a Valid Official Number attempt to find a Case on the database using that
			--    number and update the associated transactions to that CASEID.  Work through the 
			--    hierarchy of different CaseTypes.

			Set @nRowCount=0
	
			If  @sSearchCaseType1 is not null
			and @nErrorCode=0
			Begin
				-- Record CASEID to increase performance and simplicity.
				-- No IRN but Official Number matches and match on SearchCaseType1
				-- Case found must be LIVE
				-- Note that multiple Cases may be found so expand the
				-- transaction to cover all matching Cases.
				set @sSQLString="
					insert into #TEMPTRANS (TRANSACTIONNO, CASEID)
					SELECT distinct IJB.TRANSACTIONNO, CO.CASEID
					FROM "+@sUserName+".IMPORTJOURNALBULK IJB
					LEFT JOIN #TEMPTRANS T
							ON (T.TRANSACTIONNO=IJB.TRANSACTIONNO)
					JOIN (	select CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASEOFFICIALNUMBER, CHARACTERDATA
						from "+@sUserName+".IMPORTJOURNALBULK 
						where TRANSACTIONNO=@nTransactionNo
						and REJECTREASON is null) I
							ON (I.CASETYPE 		 = IJB.CASETYPE
							AND I.PROPERTYTYPE	 = IJB.PROPERTYTYPE
							AND I.COUNTRYCODE	 = IJB.COUNTRYCODE
							AND I.CASEOFFICIALNUMBER = IJB.CASEOFFICIALNUMBER)
					JOIN CASES CO 	ON (CO.CASETYPE          = @sSearchCaseType1 
							AND CO.PROPERTYTYPE= isnull(@sImportedProperty, IJB.PROPERTYTYPE)
							AND CO.COUNTRYCODE = isnull(@sImportedCountry,  IJB.COUNTRYCODE))
					JOIN OFFICIALNUMBERS O
							ON (O.CASEID=CO.CASEID
							AND O.OFFICIALNUMBER=IJB.CHARACTERDATA
							AND O.ISCURRENT=1)
					JOIN NUMBERTYPES NT
							ON (NT.NUMBERTYPE=O.NUMBERTYPE
							AND NT.ISSUEDBYIPOFFICE=1)
					LEFT JOIN PROPERTY P
							ON (P.CASEID=CO.CASEID)
					LEFT JOIN STATUS S
							ON (S.STATUSCODE=CO.STATUSCODE)
					LEFT JOIN STATUS R
							ON (R.STATUSCODE=P.RENEWALSTATUS)
					WHERE IJB.CASEID    is null
					and IJB.IRN         is null
					and T.TRANSACTIONNO is null
					--and isnull(@sImportedCaseType,IJB.CASETYPE)<>@sSearchCaseType1
					and isnull(S.LIVEFLAG,1)=1
					and isnull(R.LIVEFLAG,1)=1"
	
				Exec @nErrorCode=sp_executesql @sSQLString,
								N'@nTransactionNo	int,
								  @sImportedCaseType	nchar(1),
								  @sImportedCountry	nvarchar(3),
								  @sImportedProperty	nchar(1),
								  @sSearchCaseType1	nchar(1)',
								  @nTransactionNo   =@nTransactionNo,
								  @sImportedCaseType=@sImportedCaseType,
								  @sImportedCountry =@sImportedCountry,
								  @sImportedProperty=@sImportedProperty,
								  @sSearchCaseType1=@sSearchCaseType1

				Set @nRowCount=@@RowCount
			End
	
			If  @sSearchCaseType2 is not null
			and @nErrorCode=0
			and @nRowCount =0
			Begin
				-- Record CASEID to increase performance and simplicity.
				-- No IRN but Official Number matches and match on SearchCaseType2
				-- Case found does not need to be Live
				set @sSQLString="
					insert into #TEMPTRANS (TRANSACTIONNO, CASEID)
					SELECT distinct IJB.TRANSACTIONNO, CO.CASEID
					FROM "+@sUserName+".IMPORTJOURNALBULK IJB
					LEFT JOIN #TEMPTRANS T
							ON (T.TRANSACTIONNO=IJB.TRANSACTIONNO)
					JOIN (	select CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASEOFFICIALNUMBER, CHARACTERDATA
						from "+@sUserName+".IMPORTJOURNALBULK 
						where TRANSACTIONNO=@nTransactionNo
						and REJECTREASON is null) I
							ON (I.CASETYPE 		 = IJB.CASETYPE
							AND I.PROPERTYTYPE	 = IJB.PROPERTYTYPE
							AND I.COUNTRYCODE	 = IJB.COUNTRYCODE
							AND I.CASEOFFICIALNUMBER = IJB.CASEOFFICIALNUMBER)
					JOIN CASES CO 	ON (CO.CASETYPE          = @sSearchCaseType2 
							AND CO.PROPERTYTYPE= isnull(@sImportedProperty, IJB.PROPERTYTYPE)
							AND CO.COUNTRYCODE = isnull(@sImportedCountry,  IJB.COUNTRYCODE))
					JOIN OFFICIALNUMBERS O
							ON (O.CASEID=CO.CASEID
							AND O.OFFICIALNUMBER=IJB.CHARACTERDATA
							AND O.ISCURRENT=1)
					JOIN NUMBERTYPES NT
							ON (NT.NUMBERTYPE=O.NUMBERTYPE
							AND NT.ISSUEDBYIPOFFICE=1)
					WHERE IJB.CASEID    is null
					and IJB.IRN         is null
					and T.TRANSACTIONNO is null"
					--and isnull(@sImportedCaseType,IJB.CASETYPE)<>@sSearchCaseType2"
	
				Exec @nErrorCode=sp_executesql @sSQLString,
								N'@nTransactionNo	int,
								  @sImportedCaseType	nchar(1),
								  @sImportedCountry	nvarchar(3),
								  @sImportedProperty	nchar(1),
								  @sSearchCaseType2	nchar(1)',
								  @nTransactionNo   =@nTransactionNo,
								  @sImportedCaseType=@sImportedCaseType,
								  @sImportedCountry =@sImportedCountry,
								  @sImportedProperty=@sImportedProperty,
								  @sSearchCaseType2=@sSearchCaseType2
			End

			-- Get the next row requiring validation
			If @nErrorCode=0
			Begin
				Set @sSQLString="
					select @nTransactionNo=min(I.TRANSACTIONNO)
					from  "+@sUserName+".IMPORTJOURNALBULK I
					left join #TEMPTRANS T	on (T.TRANSACTIONNO=I.TRANSACTIONNO)
					join NUMBERTYPES N	on (N.NUMBERTYPE=I.CHARACTERKEY)
					Where I.CASEID is null
					and isnull(I.FORCECREATECASE,0)=0
					and I.TRANSACTIONTYPE='NUMBER TYPE'
					and I.CHARACTERDATA<>I.CASEOFFICIALNUMBER
					and I.TRANSACTIONNO>@nTransactionNo
					and T.TRANSACTIONNO is null"
	
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@nTransactionNo	int		OUTPUT',
							  @nTransactionNo=@nTransactionNo	OUTPUT
			End
		End	-- End of WHILE loop


		-- Now copy each IMPORTJOURNALBULK row that now has a CASEID back
		If @nErrorCode=0
		Begin
			-- Note that TRANSACTIONNO is not inserted as this is an Identity columns
			-- so a new value will be created
			Set @sSQLString="
			Insert into "+@sUserName+".IMPORTJOURNALBULK (	
				CASEID,  BATCHTYPE,FROMNAMENO,BATCHDATE,COUNTRYCODE,CASETYPE,PROPERTYTYPE,
				CASECATEGORY,SUBTYPE,BASIS,CASEOFFICIALNUMBER,IRN,
				VALIDATEONLYFLAG,TRANSACTIONTYPE,JOURNALNO,JOURNALPAGE,OFFICIALNO,
				ACTION,RELATIVECYCLE,CYCLE,NUMBERKEY,CHARACTERKEY,DATEDATA,INTEGERDATA,
				DECIMALDATA,CHARACTERDATA,REJECTEDFLAG,REJECTREASON)
			select  T.CASEID,BATCHTYPE,FROMNAMENO,BATCHDATE,COUNTRYCODE,CASETYPE,PROPERTYTYPE,
				CASECATEGORY,SUBTYPE,BASIS,CASEOFFICIALNUMBER,IRN,
				VALIDATEONLYFLAG,TRANSACTIONTYPE,JOURNALNO,JOURNALPAGE,OFFICIALNO,
				ACTION,RELATIVECYCLE,CYCLE,NUMBERKEY,CHARACTERKEY,DATEDATA,INTEGERDATA,
				DECIMALDATA,CHARACTERDATA,REJECTEDFLAG,REJECTREASON
			from "+@sUserName+".IMPORTJOURNALBULK IJB
			join #TEMPTRANS T on (T.TRANSACTIONNO=IJB.TRANSACTIONNO)
			ORDER BY T.CASEID, T.TRANSACTIONNO"

			exec @nErrorCode=sp_executesql @sSQLString
		End
		-- Now delete each original IMPORTJOURNALBULK row that was expanded to include a CASEID
		-- The TransactionNo will identify the original rows to be removed.
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			delete "+@sUserName+".IMPORTJOURNALBULK
			from "+@sUserName+".IMPORTJOURNALBULK IJB
			join #TEMPTRANS T on (T.TRANSACTIONNO=IJB.TRANSACTIONNO)"

			exec @nErrorCode=sp_executesql @sSQLString
		End

		-- If an alternative Official Number has been used to find the CASEID 
		-- then update all of the other transactions for that Case to use the
		-- same CASEID
		If @nErrorCode=0
		Begin
			set @sSQLString="
				UPDATE "+@sUserName+".IMPORTJOURNALBULK
				SET CASEID = I.CASEID
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				JOIN (	select CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASEOFFICIALNUMBER, CASEID
					from "+@sUserName+".IMPORTJOURNALBULK 
					where TRANSACTIONTYPE='NUMBER TYPE'
					and CASEID is not null
					and REJECTREASON is null) I
						ON (I.CASETYPE		 = IJB.CASETYPE
						AND I.PROPERTYTYPE	 = IJB.PROPERTYTYPE
						AND I.COUNTRYCODE	 = IJB.COUNTRYCODE
						AND I.CASEOFFICIALNUMBER = IJB.CASEOFFICIALNUMBER)
				WHERE IJB.CASEID is null
				and IJB.IRN is null"

			Exec @nErrorCode=sp_executesql @sSQLString
		End

		-- If an Official Number has been rejected and none of the other
		-- Number Type transactions for the same Case were valid then mark 
		-- all of the transactions as rejected
		If @nErrorCode=0
		Begin
			set @sSQLString="
				UPDATE "+@sUserName+".IMPORTJOURNALBULK
				SET REJECTEDFLAG = 1
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				JOIN (	select CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASEOFFICIALNUMBER
					from "+@sUserName+".IMPORTJOURNALBULK 
					where TRANSACTIONTYPE='NUMBER TYPE'
					and REJECTREASON is not null) I
						ON (I.CASETYPE		 = IJB.CASETYPE
						AND I.PROPERTYTYPE	 = IJB.PROPERTYTYPE
						AND I.COUNTRYCODE	 = IJB.COUNTRYCODE
						AND I.CASEOFFICIALNUMBER = IJB.CASEOFFICIALNUMBER)
				LEFT JOIN (select CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASEOFFICIALNUMBER
					from "+@sUserName+".IMPORTJOURNALBULK 
					where TRANSACTIONTYPE='NUMBER TYPE'
					and REJECTREASON is null) I1
						ON (I1.CASETYPE		 = IJB.CASETYPE
						AND I1.PROPERTYTYPE	 = IJB.PROPERTYTYPE
						AND I1.COUNTRYCODE	 = IJB.COUNTRYCODE
						AND I1.CASEOFFICIALNUMBER= IJB.CASEOFFICIALNUMBER)
				WHERE IJB.CASEID is null
				and IJB.IRN is null
				and I1.CASEOFFICIALNUMBER is null -- ensure no other valid Number Type"

			Exec @nErrorCode=sp_executesql @sSQLString
		End

		If @nErrorCode=0
		Begin
			-- Count the rows that did not get a valid CASEID even though an IRN was provided
			set @sSQLString="
				SELECT @nJournalCountOUT=count(1)
				FROM "+@sUserName+".IMPORTJOURNALBULK 
				WHERE IRN IS NOT NULL
				AND CASEID is null"

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nJournalCountOUT	int	OUTPUT',
							  @nJournalCountOUT=@nJournalCount OUTPUT

			If @nJournalCount > 0
			Begin
				-- Write error to new column in IMPORTBATCH table
				-- for all the rows which don't define a distinct case
				If @nErrorCode=0
				Begin
					set @sSQLString="
						UPDATE IMPORTBATCH
						SET BATCHNOTES = CASE WHEN(BATCHNOTES is not null) THEN BATCHNOTES+char(10) END + 
								 CAST(@nJournalCount as nvarchar(10)) + ' records were skipped - distinct Case not identified.'
						WHERE IMPORTBATCHNO = @nBatchNo"

					Exec @nErrorCode=sp_executesql @sSQLString, 
								N'@nJournalCount	int,
								  @nBatchNo		int',
								  @nJournalCount,
								  @nBatchNo
				End
			End
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

	If @nErrorCode=0
	Begin
		-- Now start a new transaction
		Select @nTranCountStart = @@TranCount
		BEGIN TRANSACTION

		-- For each imported row where the Case does not currently exist in the database
		-- insert a row into a table variable in preparation to load the CASES table.
		-- Note that Rejected Cases will source the characteristics differently 
		-- from valid Cases.

		Set @sSQLString="
		insert into #TEMPCASES(OFFICIALNO, CASETYPE, COUNTRYCODE, PROPERTYTYPE, CASECATEGORY, SUBTYPE, BASIS, REJECTEDFLAG)
		SELECT 	I.CASEOFFICIALNUMBER, 
			isnull(@sImportedCaseType,I.CASETYPE), 
			isnull(@sImportedCountry, I.COUNTRYCODE), 
			isnull(@sImportedProperty,I.PROPERTYTYPE), 
			isnull(@sImportedCategory,I.CASECATEGORY), 
			isnull(@sImportedSubType, I.SUBTYPE),
			isnull(@sImportedBasis,   I.BASIS),
			0
		FROM "+@sUserName+".IMPORTJOURNALBULK I
		WHERE I.IRN IS NULL
		AND I.CASEID is null
		AND I.CASEOFFICIALNUMBER is not null
		AND I.REJECTEDFLAG is null
		UNION
		SELECT 	I.CASEOFFICIALNUMBER, 
			isnull(@sRejectedCaseType,I.CASETYPE), 
			isnull(@sRejectedCountry, I.COUNTRYCODE), 
			isnull(@sRejectedProperty,I.PROPERTYTYPE), 
			isnull(@sRejectedCategory,I.CASECATEGORY), 
			isnull(@sRejectedSubType, I.SUBTYPE),
			isnull(@sRejectedBasis,   I.BASIS),
			I.REJECTEDFLAG
		FROM "+@sUserName+".IMPORTJOURNALBULK I
		WHERE I.IRN IS NULL
		AND I.CASEID is null
		AND I.CASEOFFICIALNUMBER is not null
		AND I.REJECTEDFLAG=1"

		Exec @nErrorCode=sp_executesql @sSQLString,
					N'@sImportedCaseType	nchar(1),
					  @sImportedCountry	nvarchar(3),
					  @sImportedProperty	nchar(1),
					  @sImportedCategory	nvarchar(2),
					  @sImportedSubType	nvarchar(2),
					  @sImportedBasis	nvarchar(2),
					  @sRejectedCaseType	nchar(1),
					  @sRejectedCountry	nvarchar(3),
					  @sRejectedProperty	nchar(1),
					  @sRejectedCategory	nvarchar(2),
					  @sRejectedSubType	nvarchar(2),
					  @sRejectedBasis	nvarchar(2)',
					  @sImportedCaseType	=@sImportedCaseType,
					  @sImportedCountry	=@sImportedCountry,
					  @sImportedProperty	=@sImportedProperty,
					  @sImportedCategory	=@sImportedCategory,
					  @sImportedSubType	=@sImportedSubType,
					  @sImportedBasis	=@sImportedBasis,
					  @sRejectedCaseType	=@sRejectedCaseType,
					  @sRejectedCountry	=@sRejectedCountry,
					  @sRejectedProperty	=@sRejectedProperty,
					  @sRejectedCategory	=@sRejectedCategory,
					  @sRejectedSubType	=@sRejectedSubType,
					  @sRejectedBasis	=@sRejectedBasis

		Set @nNewCases=@@Rowcount

		-- Now reserve a CASEID for each of the about to be created Cases by incrementing 
		-- the LASTINTERNALCODE table
		If @nNewCases>0
		Begin
			If @nErrorCode=0
			Begin
				set @sSQLString="
					UPDATE LASTINTERNALCODE 
					SET INTERNALSEQUENCE = INTERNALSEQUENCE + @nNewCases,
					    @nCaseId         = INTERNALSEQUENCE + @nNewCases
					WHERE  TABLENAME = 'CASES'"

				Exec @nErrorCode=sp_executesql @sSQLString, 
								N'@nCaseId	int	OUTPUT,
								  @nNewCases	int',
								  @nCaseId  =@nCaseId	OUTPUT,
								  @nNewCases=@nNewCases
			End

			-- Now insert a row into the CASES table for each new Case
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Insert into CASES(CASEID, IRN, CURRENTOFFICIALNO, CASETYPE, COUNTRYCODE, PROPERTYTYPE, CASECATEGORY, SUBTYPE)
				select  @nCaseId-T.SEQUENCENO, '<Generate Reference>',T.OFFICIALNO, CT.CASETYPE, CC.COUNTRYCODE, P.PROPERTYTYPE, C.CASECATEGORY, SB.SUBTYPE
				from #TEMPCASES T
				left join CASETYPE CT	on (CT.CASETYPE=T.CASETYPE)
				left join COUNTRY CC	on (CC.COUNTRYCODE=T.COUNTRYCODE)
				left join PROPERTYTYPE P on(P.PROPERTYTYPE=T.PROPERTYTYPE)
				left join CASECATEGORY C on(C.CASETYPE=CT.CASETYPE
							and C.CASECATEGORY=T.CASECATEGORY)
				left join SUBTYPE SB	 on(SB.SUBTYPE=T.SUBTYPE)"

				Exec @nErrorCode=sp_executesql @sSQLString,
								N'@nCaseId	int',
								  @nCaseId=@nCaseId
			End

			-- Now insert a row into the PROPERTY table for each new Case where CASETYPE='A' or CASETYPE = 'X'	-- RCT 16/11/2004
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Insert into PROPERTY(CASEID, BASIS)
				select  @nCaseId-T.SEQUENCENO, A.BASIS
				from #TEMPCASES T
				left join APPLICATIONBASIS A	on (A.BASIS=T.BASIS)
				where T.CASETYPE in ('A','X')"									-- RCT 16/11/2004
				Exec @nErrorCode=sp_executesql @sSQLString,
								N'@nCaseId	int',
								  @nCaseId=@nCaseId
			End
		End

		-- Update the CASEID on the Imported rows for the newly created Cases.
		If @nErrorCode=0
		and @nCaseId  >0
		Begin
			Set @sSQLString="
			Update  "+@sUserName+".IMPORTJOURNALBULK
			Set CASEID=@nCaseId-T.SEQUENCENO
			From "+@sUserName+".IMPORTJOURNALBULK IJB
			join #TEMPCASES T on (T.OFFICIALNO=IJB.CASEOFFICIALNUMBER)
			Where (T.CASETYPE    =CASE WHEN(IJB.REJECTEDFLAG=1) THEN isnull(@sRejectedCaseType,IJB.CASETYPE)     ELSE isnull(@sImportedCaseType,IJB.CASETYPE)     END or (T.CASETYPE     is null and CASE WHEN(IJB.REJECTEDFLAG=1) THEN isnull(@sRejectedCaseType,IJB.CASETYPE)     ELSE isnull(@sImportedCaseType,IJB.CASETYPE)     END is null))
			and   (T.PROPERTYTYPE=CASE WHEN(IJB.REJECTEDFLAG=1) THEN isnull(@sRejectedProperty,IJB.PROPERTYTYPE) ELSE isnull(@sImportedProperty,IJB.PROPERTYTYPE) END or (T.PROPERTYTYPE is null and CASE WHEN(IJB.REJECTEDFLAG=1) THEN isnull(@sRejectedProperty,IJB.PROPERTYTYPE) ELSE isnull(@sImportedProperty,IJB.PROPERTYTYPE) END is null))
			and   (T.COUNTRYCODE =CASE WHEN(IJB.REJECTEDFLAG=1) THEN isnull(@sRejectedCountry, IJB.COUNTRYCODE)  ELSE isnull(@sImportedCountry, IJB.COUNTRYCODE)  END or (T.COUNTRYCODE  is null and CASE WHEN(IJB.REJECTEDFLAG=1) THEN isnull(@sRejectedCountry, IJB.COUNTRYCODE)  ELSE isnull(@sImportedCountry, IJB.COUNTRYCODE)  END is null))"

			Exec @nErrorCode=sp_executesql @sSQLString,
							N'@nCaseId		int,
							  @sImportedCaseType	nchar(1),
							  @sImportedCountry	nvarchar(3),
							  @sImportedProperty	nchar(1),
							  @sRejectedCaseType	nchar(1),
							  @sRejectedCountry	nvarchar(3),
							  @sRejectedProperty	nchar(1)',
							  @nCaseId		=@nCaseId,
							  @sImportedCaseType	=@sImportedCaseType,
							  @sImportedCountry	=@sImportedCountry,
							  @sImportedProperty	=@sImportedProperty,
							  @sRejectedCaseType	=@sRejectedCaseType,
							  @sRejectedCountry	=@sRejectedCountry,
							  @sRejectedProperty	=@sRejectedProperty
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

	------------------------------------------
	-- Create a Header Case if one is required
	------------------------------------------
	If @nErrorCode=0
	and @sHeaderCaseType is not null
	and @sHeaderProperty is not null
	and @sHeaderCountry  is not null
	Begin
		-- Start a new transaction
		-- This transaction will be kept very short so as not to 
		-- leave an extensive lock on the LASTINTERNALCODE table

		Select @nTranCountStart = @@TranCount
		BEGIN TRANSACTION

		set @sSQLString="
			UPDATE LASTINTERNALCODE 
			SET INTERNALSEQUENCE = INTERNALSEQUENCE + 1,
			    @nCaseId         = INTERNALSEQUENCE + 1
			WHERE  TABLENAME = 'CASES'"

		Exec @nErrorCode=sp_executesql @sSQLString, 
						N'@nCaseId	int	OUTPUT',
						  @nCaseId  =@nCaseId	OUTPUT

		If @nErrorCode=0
		Begin
			-- Save the header CaseId for future reference
			Set @nHeaderCaseId=@nCaseId

			Set @sSQLString="
			INSERT INTO CASES(CASEID, IRN, CASETYPE, COUNTRYCODE, PROPERTYTYPE, CASECATEGORY, SUBTYPE, TITLE, LOCALCLIENTFLAG)
			Select	@nCaseId,
				'<Generate Reference>',
				@sHeaderCaseType, 
				@sHeaderCountry, 
				@sHeaderProperty, 
				@sHeaderCategory, 
				@sHeaderSubType,
				CASE WHEN(@sHeaderTitle is not null) 
					THEN @sHeaderTitle+' '+convert(nvarchar,@nBatchNo)+' '+convert(nvarchar,@dtBatchDate,106)
				END,
				IP.LOCALCLIENTFLAG
			From IPNAME IP 
			Where IP.NAMENO=@nFromNameNo"

			Exec @nErrorCode=sp_executesql @sSQLString,
						N'@nCaseId		int,
						  @sHeaderCaseType	nchar(1),
					  	  @sHeaderCountry	nvarchar(3),
						  @sHeaderProperty	nchar(1),
						  @sHeaderCategory	nvarchar(2),
						  @sHeaderSubType	nvarchar(2),
						  @sHeaderTitle		nvarchar(100),
						  @nFromNameNo		int,
						  @nBatchNo		int,
						  @dtBatchDate		datetime',
						  @nCaseId		=@nCaseId,
						  @sHeaderCaseType	=@sHeaderCaseType,
					  	  @sHeaderCountry	=@sHeaderCountry,
						  @sHeaderProperty	=@sHeaderProperty,
						  @sHeaderCategory	=@sHeaderCategory,
						  @sHeaderSubType	=@sHeaderSubType,
						  @sHeaderTitle		=@sHeaderTitle,
						  @nFromNameNo		=@nFromNameNo,
						  @nBatchNo		=@nBatchNo,
						  @dtBatchDate		=@dtBatchDate
		End

		If @nErrorCode=0
		and @sHeaderBasis is not null
		Begin
			Set @sSQLString="
			INSERT INTO PROPERTY(CASEID, BASIS)
			Select	C.CASEID,  
				@sHeaderBasis
			From CASES C 
			Where C.CASEID=@nCaseId"

			Exec @nErrorCode=sp_executesql @sSQLString,
						N'@nCaseId		int,
						  @sHeaderBasis		nvarchar(2)',
						  @nCaseId		=@nCaseId,
						  @sHeaderBasis		=@sHeaderBasis
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

	If @nErrorCode=0
	Begin
		-- Start a new transaction
		Select @nTranCountStart = @@TranCount
		BEGIN TRANSACTION

		-----------------------------------------------------------------------
		-- Now add various Names to the Cases created and also any relationship
		-- between the header and other cases.
		-----------------------------------------------------------------------

		-- INSTRUCTOR for the HEADER Case

		Set @nRowCount=@@Rowcount

		-- Load a Caseid into temporary table to be used by Global Name Change
		If @nHeaderCaseId is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
				Insert into #TEMPCASESTOUPDATE(CASEID)
				values (@nHeaderCaseId)"

			exec @nErrorCode=sp_executesql @sSQLString,
						N'@nHeaderCaseId	int',
						  @nHeaderCaseId=@nHeaderCaseId

			Set @nRowCount=@@Rowcount
		End

		-- Use the Global Name Change stored procedure as this will also apply any inheritance
		-- rules for other NameTypes to the Cases.  Note that a ProgramId is required as the 
		-- screen control associated with the Program is used to determine what inherited NameTypes
		-- are valid to add to the Case.

		If  @nFromNameNo   is not null
		and @nHeaderCaseId is not null
		and @nErrorCode=0
		Begin
			exec @nErrorCode=dbo.cs_GlobalNameChange
					@pnNamesUpdatedCount	=@nNamesUpdatedCount	OUTPUT,
					@pnNamesInsertedCount	=@nNamesInsertedCount	OUTPUT,
					@pnNamesDeletedCount	=@nNamesDeletedCount	OUTPUT,
					-- Change Details
					@psGlobalTempTable	= '#TEMPCASESTOUPDATE',	-- mandatory name of temporary table of CASEIDs to be reported on.
					@psProgramId		= @sProgramId,		-- the program used for determining valid nametypes for inheritance
					@psNameType		= 'I',			-- Always use Instructor on Header Case
					@pnNewNameNo		=@nFromNameNo,
					-- Options
					@pbUpdateName		= 1,	
					@pbInsertName		= 1,	-- indicates that the Name is to be inserted if it does not already exist
					@pbApplyInheritance	= 1,	-- apply inheritance rules for other Name Types
					@pbSuppressOutput	= 1
		End

		-- STAFF MEMBER for the HEADER Case
		If  @nHeaderStaffName is not null
		and @nHeaderCaseId    is not null
		and @nErrorCode=0
		Begin
			exec @nErrorCode=dbo.cs_GlobalNameChange
					@pnNamesUpdatedCount	=@nNamesUpdatedCount	OUTPUT,
					@pnNamesInsertedCount	=@nNamesInsertedCount	OUTPUT,
					@pnNamesDeletedCount	=@nNamesDeletedCount	OUTPUT,
					-- Change Details
					@psGlobalTempTable	= '#TEMPCASESTOUPDATE',	-- mandatory name of temporary table of CASEIDs to be reported on.
					@psProgramId		= @sProgramId,		-- the program used for determining valid nametypes for inheritance
					@psNameType		= 'EMP',
					@pnNewNameNo		=@nHeaderStaffName,
					-- Options
					@pbUpdateName		= 1,	
					@pbInsertName		= 1,	-- indicates that the Name is to be inserted if it does not already exist
					@pbApplyInheritance	= 1,	-- apply inheritance rules for other Name Types
					@pbSuppressOutput	= 1
		End

		-- Clear out the temporary table
		If  @nRowCount>0
		and @nErrorCode=0
		Begin
			Set @sSQLString="delete from #TEMPCASESTOUPDATE"

			exec @nErrorCode=sp_executesql @sSQLString

			Set @nRowCount=0
		End

		-- INSTRUCTOR for the imported and existing Cases
		If @nImportedInstructor is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
				Insert into #TEMPCASESTOUPDATE(CASEID)
				Select @nCaseId-T.SEQUENCENO
				from #TEMPCASES T
				Where T.REJECTEDFLAG is null
				UNION
				Select I.CASEID
				from "+@sUserName+".IMPORTJOURNALBULK I
				where I.CASEID is not null
				and I.REJECTEDFLAG is null"

			exec @nErrorCode=sp_executesql @sSQLString,
							N'@nCaseId	int',
							  @nCaseId=@nCaseId

			Set @nRowCount=@@Rowcount
		End

		If  @nImportedInstructor is not null
		and @nRowCount >0
		and @nErrorCode=0
		Begin
			exec @nErrorCode=dbo.cs_GlobalNameChange
					@pnNamesUpdatedCount	=@nNamesUpdatedCount	OUTPUT,
					@pnNamesInsertedCount	=@nNamesInsertedCount	OUTPUT,
					@pnNamesDeletedCount	=@nNamesDeletedCount	OUTPUT,
					-- Change Details
					@psGlobalTempTable	= '#TEMPCASESTOUPDATE',	-- mandatory name of temporary table of CASEIDs to be reported on.
					@psProgramId		= @sProgramId,		-- the program used for determining valid nametypes for inheritance
					@psNameType		= @sInstructorNameType,
					@pnNewNameNo		= @nImportedInstructor,
					-- Options
					@pbUpdateName		= 1,	-- Update flag handles changes to existing Cases
					@pbInsertName		= 1,	-- indicates that the Name is to be inserted if it does not already exist
					@pbApplyInheritance	= 1,	-- apply inheritance rules for other Name Types
					@pbSuppressOutput	= 1
		End

		-- Clear out the temporary table
		If  @nRowCount>0
		and @nErrorCode=0
		Begin
			Set @sSQLString="delete from #TEMPCASESTOUPDATE"

			exec @nErrorCode=sp_executesql @sSQLString

			Set @nRowCount=0
		End

		-- STAFF MEMBER for the IMPORTED Case (don't change existing Cases)
		If @nImportedStaffName is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
				Insert into #TEMPCASESTOUPDATE(CASEID)
				Select @nCaseId-T.SEQUENCENO
				from #TEMPCASES T
				Where T.REJECTEDFLAG is null"

			exec @nErrorCode=sp_executesql @sSQLString,
							N'@nCaseId	int',
							  @nCaseId=@nCaseId

			Set @nRowCount=@@Rowcount
		End

		If  @nImportedStaffName is not null
		and @nRowCount >0
		and @nErrorCode=0
		Begin
			exec @nErrorCode=dbo.cs_GlobalNameChange
					@pnNamesUpdatedCount	=@nNamesUpdatedCount	OUTPUT,
					@pnNamesInsertedCount	=@nNamesInsertedCount	OUTPUT,
					@pnNamesDeletedCount	=@nNamesDeletedCount	OUTPUT,
					-- Change Details
					@psGlobalTempTable	= '#TEMPCASESTOUPDATE',	-- mandatory name of temporary table of CASEIDs to be reported on.
					@psProgramId		= @sProgramId,		-- the program used for determining valid nametypes for inheritance
					@psNameType		= 'EMP',
					@pnNewNameNo		=@nImportedStaffName,
					-- Options
					@pbUpdateName		= 1,	
					@pbInsertName		= 1,	-- indicates that the Name is to be inserted if it does not already exist
					@pbApplyInheritance	= 1,	-- apply inheritance rules for other Name Types
					@pbSuppressOutput	= 1
		End

		-- Clear out the temporary table
		If  @nRowCount>0
		and @nErrorCode=0
		Begin
			Set @sSQLString="delete from #TEMPCASESTOUPDATE"

			exec @nErrorCode=sp_executesql @sSQLString

			Set @nRowCount=0
		End

		-- INSTRUCTOR for the REJECTED Cases
		If  @nRejectedInstructor is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
				Insert into #TEMPCASESTOUPDATE(CASEID)
				Select @nCaseId-T.SEQUENCENO
				from #TEMPCASES T
				Where REJECTEDFLAG=1"

			exec @nErrorCode=sp_executesql @sSQLString,
							N'@nCaseId	int',
							  @nCaseId=@nCaseId

			Set @nRowCount=@@Rowcount
		End

		If  @nRejectedInstructor is not null
		and @nRowCount >0
		and @nErrorCode=0
		Begin
			exec @nErrorCode=dbo.cs_GlobalNameChange
					@pnNamesUpdatedCount	=@nNamesUpdatedCount	OUTPUT,
					@pnNamesInsertedCount	=@nNamesInsertedCount	OUTPUT,
					@pnNamesDeletedCount	=@nNamesDeletedCount	OUTPUT,
					-- Change Details
					@psGlobalTempTable	= '#TEMPCASESTOUPDATE',	-- mandatory name of temporary table of CASEIDs to be reported on.
					@psProgramId		= @sProgramId,		-- the program used for determining valid nametypes for inheritance
					@psNameType		= @sInstructorNameType,
					@pnNewNameNo		= @nRejectedInstructor,
					-- Options
					@pbUpdateName		= 1,	
					@pbInsertName		= 1,	-- indicates that the Name is to be inserted if it does not already exist
					@pbApplyInheritance	= 1,	-- apply inheritance rules for other Name Types
					@pbSuppressOutput	= 1
		End

		-- STAFF MEMBER for the REJECTED Case
		If  @nRejectedStaffName is not null
		and @nRowCount >0
		and @nErrorCode=0
		Begin
			exec @nErrorCode=dbo.cs_GlobalNameChange
					@pnNamesUpdatedCount	=@nNamesUpdatedCount	OUTPUT,
					@pnNamesInsertedCount	=@nNamesInsertedCount	OUTPUT,
					@pnNamesDeletedCount	=@nNamesDeletedCount	OUTPUT,
					-- Change Details
					@psGlobalTempTable	= '#TEMPCASESTOUPDATE',	-- mandatory name of temporary table of CASEIDs to be reported on.
					@psProgramId		= @sProgramId,		-- the program used for determining valid nametypes for inheritance
					@psNameType		= 'EMP',
					@pnNewNameNo		=@nRejectedStaffName,
					-- Options
					@pbUpdateName		= 1,	
					@pbInsertName		= 1,	-- indicates that the Name is to be inserted if it does not already exist
					@pbApplyInheritance	= 1,	-- apply inheritance rules for other Name Types
					@pbSuppressOutput	= 1
		End

		---------------------------------------------------
		-- Update the LOCALCLIENTFLAG on the Cases table
		---------------------------------------------------

		If @nErrorCode=0
		Begin
			Set @sSQLString="
				Update CASES
				Set LOCALCLIENTFLAG=IP.LOCALCLIENTFLAG
				From CASES C
				join (	select distinct CASEID
					from  "+@sUserName+".IMPORTJOURNALBULK
					where CASEID is not null) I
							on (I.CASEID=C.CASEID)
				join CASENAME CN	on (CN.CASEID=C.CASEID
							and CN.NAMETYPE='I'
							and CN.EXPIRYDATE is null)
				join IPNAME IP		on (IP.NAMENO=CN.NAMENO)"

			exec @nErrorCode=sp_executesql @sSQLString
		End

		-- Update the LOCALCLIENTFLAG from the Renwewal Instructor
		-- if no Instructor exists.
		If @nErrorCode=0
		Begin
			Set @sSQLString="
				Update CASES
				Set LOCALCLIENTFLAG=IP.LOCALCLIENTFLAG
				From CASES C
				join (	select distinct CASEID
					from  "+@sUserName+".IMPORTJOURNALBULK
					where CASEID is not null) I
							on (I.CASEID=C.CASEID)
				join CASENAME CN	on (CN.CASEID=C.CASEID
							and CN.NAMETYPE='R'
							and CN.EXPIRYDATE is null)
				join IPNAME IP		on (IP.NAMENO=CN.NAMENO)
				left join CASENAME CN1	on (CN1.CASEID=C.CASEID
							and CN1.NAMETYPE='I'
							and CN1.EXPIRYDATE is null)
				Where CN1.CASEID is null"

			exec @nErrorCode=sp_executesql @sSQLString
		End

		---------------------------------------------------
		-- Relate the Header Case to the Cases in the batch
		---------------------------------------------------
		If  @nHeaderCaseId is not null
		and @sRelateToValidCase is not null
		and @nErrorCode=0
		Begin
			-- Load via a temporary table so as to allocate the RELATIONSHIP number automatically
			Set @sSQLString="
				Insert into #TEMPRELATEDCASE(CASEID,RELATIONSHIP,RELATEDCASEID,CYCLE)
				Select distinct @nHeaderCaseId, CR.RELATIONSHIP, I.CASEID, 
						CASE WHEN(I2.INTEGERDATA is not null)
							THEN I2.INTEGERDATA-isnull(VP.CYCLEOFFSET,0)
						END
				From "+@sUserName+".IMPORTJOURNALBULK I
				join CASERELATION CR	on (CR.RELATIONSHIP=@sRelateToValidCase)
				join CASES C		on (C.CASEID=I.CASEID)
				left join "+@sUserName+".IMPORTJOURNALBULK I2
							on (I2.CASEID=C.CASEID
							and I2.TRANSACTIONTYPE='RENEWAL YEAR')
				left join VALIDPROPERTY VP
							on (VP.PROPERTYTYPE=C.PROPERTYTYPE
							and VP.COUNTRYCODE=(select min(VP1.COUNTRYCODE)
									    from VALIDPROPERTY VP1
									    where VP1.PROPERTYTYPE=VP.PROPERTYTYPE
									    and VP1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))
				where I.REJECTEDFLAG is null"

			exec @nErrorCode=sp_executesql @sSQLString,
						N'@nHeaderCaseId	int,
						  @sRelateToValidCase	nvarchar(3)',
						  @nHeaderCaseId=@nHeaderCaseId,
						  @sRelateToValidCase=@sRelateToValidCase

			Set @nRowsInserted=@@Rowcount

			-- Now load any reciprocal relationship.  
			If @nErrorCode=0
			Begin
				Set @sSQLString="
					Insert into RELATEDCASE(CASEID, RELATIONSHIPNO, RELATIONSHIP, RELATEDCASEID)
					Select distinct I.CASEID, isnull(RC.RELATIONSHIPNO,0)+1, V.RECIPRELATIONSHIP, @nHeaderCaseId
					From "+@sUserName+".IMPORTJOURNALBULK I
					join CASES C	on (C.CASEID=I.CASEID)
					join VALIDRELATIONSHIPS V on (V.PROPERTYTYPE=C.PROPERTYTYPE
								  and V.RELATIONSHIP=@sRelateToValidCase
								  and V.COUNTRYCODE=(	select min(V1.COUNTRYCODE)
											from VALIDRELATIONSHIPS V1
											where V1.PROPERTYTYPE=C.PROPERTYTYPE
											and V1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
					left join (select CASEID, max(RELATIONSHIPNO) as RELATIONSHIPNO
						   from RELATEDCASE
						   group by CASEID) RC	on (RC.CASEID=C.CASEID)"

				exec @nErrorCode=sp_executesql @sSQLString,
							N'@nHeaderCaseId	int,
							  @sRelateToValidCase	nvarchar(3)',
							  @nHeaderCaseId=@nHeaderCaseId,
							  @sRelateToValidCase=@sRelateToValidCase
			End
		End

		If  @nHeaderCaseId is not null
		and @sRelateToReject is not null
		and @nErrorCode=0
		Begin
			-- Load via a temporary table so as to allocate the RELATIONSHIP number automatically
			Set @sSQLString="
				Insert into #TEMPRELATEDCASE(CASEID,RELATIONSHIP,RELATEDCASEID,CYCLE)
				Select distinct @nHeaderCaseId, CR.RELATIONSHIP, I.CASEID, 
						CASE WHEN(I2.INTEGERDATA is not null)
							THEN I2.INTEGERDATA-isnull(VP.CYCLEOFFSET,0)
						END
				From "+@sUserName+".IMPORTJOURNALBULK I
				join CASERELATION CR	on (CR.RELATIONSHIP=@sRelateToReject)
				join CASES C		on (C.CASEID=I.CASEID)
				left join "+@sUserName+".IMPORTJOURNALBULK I2
							on (I2.CASEID=C.CASEID
							and I2.TRANSACTIONTYPE='RENEWAL YEAR')
				left join VALIDPROPERTY VP
							on (VP.PROPERTYTYPE=C.PROPERTYTYPE
							and VP.COUNTRYCODE=(select min(VP1.COUNTRYCODE)
									    from VALIDPROPERTY VP1
									    where VP1.PROPERTYTYPE=VP.PROPERTYTYPE
									    and VP1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))
				where I.REJECTEDFLAG=1"

			exec @nErrorCode=sp_executesql @sSQLString,
						N'@nHeaderCaseId	int,
						  @sRelateToReject	nvarchar(3)',
						  @nHeaderCaseId=@nHeaderCaseId,
						  @sRelateToReject=@sRelateToReject

			set @nRowsInserted=@nRowsInserted+@@Rowcount

			-- Now load any reciprocal relationship.  
			If @nErrorCode=0
			Begin
				Set @sSQLString="
					Insert into RELATEDCASE(CASEID, RELATIONSHIPNO, RELATIONSHIP, RELATEDCASEID)
					Select distinct I.CASEID, isnull(RC.RELATIONSHIPNO,0)+1, V.RECIPRELATIONSHIP, @nHeaderCaseId
					From "+@sUserName+".IMPORTJOURNALBULK I
					join CASES C	on (C.CASEID=I.CASEID)
					join VALIDRELATIONSHIPS V on (V.PROPERTYTYPE=C.PROPERTYTYPE
								  and V.RELATIONSHIP=@sRelateToReject
								  and V.COUNTRYCODE=(	select min(V1.COUNTRYCODE)
											from VALIDRELATIONSHIPS V1
											where V1.PROPERTYTYPE=C.PROPERTYTYPE
											and V1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
					left join (select CASEID, max(RELATIONSHIPNO) as RELATIONSHIPNO
						   from RELATEDCASE
						   group by CASEID) RC	on (RC.CASEID=C.CASEID)"

				exec @nErrorCode=sp_executesql @sSQLString,
							N'@nHeaderCaseId	int,
							  @sRelateToReject	nvarchar(3)',
							  @nHeaderCaseId=@nHeaderCaseId,
							  @sRelateToReject=@sRelateToReject
			End
		End

		If @nRowsInserted>0
		and @nErrorCode=0
		Begin
			-- Now load the TempRelatedCase into the live table
			Set @sSQLString="
				Insert into RELATEDCASE(CASEID, RELATIONSHIPNO, RELATIONSHIP, RELATEDCASEID, CYCLE)
				Select CASEID, RELATIONSHIPNO, RELATIONSHIP, RELATEDCASEID, CYCLE
				from #TEMPRELATEDCASE"

			Exec @nErrorCode=sp_executesql @sSQLString
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

	----------------------------
	-- Validate the transactions
	----------------------------
	If @nErrorCode=0
	Begin
		-- Now start a new transaction
		Select @nTranCountStart = @@TranCount
		BEGIN TRANSACTION

		-- Now validate and process by each TRANSACTIONTYPE for the rows that we can deduce the CASEID 
		If @nErrorCode=0
		Begin
			-- TRANSACTIONTYPE "BATCH HEADER" 
			set @sSQLString="
				INSERT INTO IMPORTJOURNAL (
					IMPORTBATCHNO,TRANSACTIONNO,CASEID,PROCESSEDFLAG,VALIDATEONLYFLAG,TRANSACTIONTYPE,
					REJECTREASON)

				SELECT @nBatchNo, IJB.TRANSACTIONNO, @nHeaderCaseId, 0, IJB.VALIDATEONLYFLAG, IJB.TRANSACTIONTYPE,
					CASE WHEN (T.TABLECODE is null) THEN 'Batch Type missing or invalid'
					     WHEN (N.NAMENO    is null) THEN 'Batch received from Name unknown or not specified' 
					END
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				left join TABLECODES T	on (T.TABLECODE=IJB.BATCHTYPE)
				left join NAME N	on (N.NAMENO=IJB.FROMNAMENO)
				WHERE @nHeaderCaseId IS NOT NULL
				AND IJB.TRANSACTIONTYPE = 'BATCH HEADER'"	

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nBatchNo		int,
							  @nHeaderCaseId	int',
							  @nBatchNo=@nBatchNo,
							  @nHeaderCaseId=@nHeaderCaseId

			Set @pnRowCount=@pnRowCount+@@Rowcount
		End

		-- Now validate and process by each TRANSACTIONTYPE for the rows that we can deduce the CASEID 

		If @nErrorCode=0
		Begin
			-- TRANSACTIONTYPE "CASE OFFICE" 
			set @sSQLString="
				INSERT INTO IMPORTJOURNAL (
					IMPORTBATCHNO,TRANSACTIONNO,CASEID,PROCESSEDFLAG,VALIDATEONLYFLAG,TRANSACTIONTYPE,
					JOURNALNO,JOURNALPAGE,COUNTRYCODE,OFFICIALNO,
					CHARACTERDATA, REJECTREASON)

				SELECT @nBatchNo, IJB.TRANSACTIONNO, IJB.CASEID, 0, IJB.VALIDATEONLYFLAG, IJB.TRANSACTIONTYPE,
					IJB.JOURNALNO,IJB.JOURNALPAGE,IJB.COUNTRYCODE,IJB.OFFICIALNO,
					IJB.CHARACTERDATA,
					CASE WHEN (O.OFFICEID is null AND IJB.CHARACTERDATA is not null) 
						THEN 'Invalid Case Office' 
					END
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				LEFT JOIN OFFICE O	on (O.OFFICEID=( select max(O1.OFFICEID)
									 from OFFICE O1
									 where O1.USERCODE=IJB.CHARACTERDATA))
				WHERE IJB.CASEID IS NOT NULL
				AND IJB.TRANSACTIONTYPE = 'CASE OFFICE'"	

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nBatchNo		int',
							  @nBatchNo=@nBatchNo

			Set @pnRowCount=@pnRowCount+@@Rowcount
		End

		If @nErrorCode=0
		Begin
			-- TRANSACTIONTYPE "CLASS TYPE" 
			set @sSQLString="
				INSERT INTO IMPORTJOURNAL (
					IMPORTBATCHNO,TRANSACTIONNO,CASEID,PROCESSEDFLAG,VALIDATEONLYFLAG,TRANSACTIONTYPE,
					JOURNALNO,JOURNALPAGE,COUNTRYCODE,OFFICIALNO,
					CHARACTERDATA, REJECTREASON)

				SELECT @nBatchNo, IJB.TRANSACTIONNO, IJB.CASEID, 0, IJB.VALIDATEONLYFLAG, IJB.TRANSACTIONTYPE,
					IJB.JOURNALNO,IJB.JOURNALPAGE,IJB.COUNTRYCODE,IJB.OFFICIALNO,
					IJB.CHARACTERDATA,
					CASE WHEN (IJB.CHARACTERDATA not in('G','S') OR IJB.CHARACTERDATA is null) 
						THEN 'Invalid class type' 
					END
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				WHERE IJB.CASEID IS NOT NULL
				AND IJB.TRANSACTIONTYPE = 'CLASS TYPE'"	

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nBatchNo		int',
							  @nBatchNo=@nBatchNo

			Set @pnRowCount=@pnRowCount+@@Rowcount
		End

		If @nErrorCode=0
		Begin
			-- TRANSACTIONTYPE "DESIGNATED STATES"

			-- Loop through each Designated States transaction and validate that the countries listed 
			-- are valid
			Set @sSQLString="
			Select	@nTransactionNo=I.TRANSACTIONNO,
				@sStates=I.CHARACTERDATA
			from "+@sUserName+".IMPORTJOURNALBULK I
			where TRANSACTIONNO=(	select min(I2.TRANSACTIONNO)
						from "+@sUserName+".IMPORTJOURNALBULK I2
						where I2.TRANSACTIONTYPE='DESIGNATED STATES'
						and I2.CASEID is not null
						and I2.CHARACTERDATA is not null)"

			exec @nErrorCode=sp_executesql @sSQLString,
							N'@nTransactionNo	int		OUTPUT,
							  @sStates		nvarchar(600)	OUTPUT',
							  @nTransactionNo=@nTransactionNo	OUTPUT,
							  @sStates=@sStates			OUTPUT

			WHILE @sStates is not null
			and @nErrorCode=0
			Begin
				set @sSQLString="
				INSERT INTO IMPORTJOURNAL (
					IMPORTBATCHNO,TRANSACTIONNO,CASEID,PROCESSEDFLAG,VALIDATEONLYFLAG,TRANSACTIONTYPE,
					JOURNALNO,JOURNALPAGE,COUNTRYCODE,OFFICIALNO,
					CHARACTERDATA, REJECTREASON)

				SELECT @nBatchNo, IJB.TRANSACTIONNO, IJB.CASEID, 0, IJB.VALIDATEONLYFLAG, IJB.TRANSACTIONTYPE,
					IJB.JOURNALNO,IJB.JOURNALPAGE,IJB.COUNTRYCODE,IJB.OFFICIALNO,
					IJB.CHARACTERDATA,
					CASE WHEN(SC.StateCount<>isnull(VS.ValidStates,0))
						THEN 'Invalid Country in designated country list'
					END
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				cross join (	select count(*) as StateCount
						from dbo.fn_Tokenise(@sStates,',')) SC
				cross join (	select count(*) as ValidStates
						from dbo.fn_Tokenise(@sStates,',') T
						join COUNTRY C on (C.COUNTRYCODE=T.Parameter)) VS
				WHERE IJB.TRANSACTIONNO=@nTransactionNo"	

				Exec @nErrorCode=sp_executesql @sSQLString, 
								N'@nBatchNo		int,
								  @nTransactionNo	int,
								  @sStates		nvarchar(600)',
								  @nBatchNo=@nBatchNo,
								  @nTransactionNo=@nTransactionNo,
								  @sStates=@sStates

				Set @pnRowCount=@pnRowCount+@@Rowcount

				If @nErrorCode=0
				Begin
					-- Get the next Designated States transaciton
					-- are valid
					Set @sStates=NULL
					Set @sSQLString="
					Select	@nTransactionNo=I.TRANSACTIONNO,
						@sStates=I.CHARACTERDATA
					from "+@sUserName+".IMPORTJOURNALBULK I
					where TRANSACTIONNO=(	select min(I2.TRANSACTIONNO)
								from "+@sUserName+".IMPORTJOURNALBULK I2
								where I2.TRANSACTIONTYPE='DESIGNATED STATES'
								and I2.CASEID is not null
								and I2.CHARACTERDATA is not null
								and I2.TRANSACTIONNO>@nTransactionNo)"
	
					exec @nErrorCode=sp_executesql @sSQLString,
									N'@nTransactionNo	int		OUTPUT,
									  @sStates		nvarchar(600)	OUTPUT',
									  @nTransactionNo=@nTransactionNo	OUTPUT,
									  @sStates=@sStates			OUTPUT
				End

			End
		End

		If @nErrorCode=0
		Begin
			-- TRANSACTIONTYPE "DUE DATE" 
			set @sSQLString="
				INSERT INTO IMPORTJOURNAL (
				IMPORTBATCHNO,TRANSACTIONNO,CASEID,PROCESSEDFLAG,VALIDATEONLYFLAG,TRANSACTIONTYPE,
				JOURNALNO,JOURNALPAGE,COUNTRYCODE,OFFICIALNO,
				ACTION, NUMBERKEY, DATEDATA, CYCLE, RELATIVECYCLE, CHARACTERDATA, TEXTDATA, REJECTREASON) 		-- RCT Include CHARACTERDATA

				SELECT @nBatchNo, IJB.TRANSACTIONNO, IJB.CASEID, 0, IJB.VALIDATEONLYFLAG, IJB.TRANSACTIONTYPE,
				IJB.JOURNALNO,IJB.JOURNALPAGE,IJB.COUNTRYCODE,IJB.OFFICIALNO,
				IJB.ACTION, IJB.NUMBERKEY, IJB.DATEDATA, IJB.CYCLE,
				CASE WHEN IJB.RELATIVECYCLE IS NOT NULL
					THEN IJB.RELATIVECYCLE
					ELSE CASE WHEN (IJB.CYCLE IS NULL AND IJB.RELATIVECYCLE IS NULL AND VALIDATEONLYFLAG in (1, 2))	-- RCT include ValidateOnlyFlag = 2
						THEN 0											-- RCT Corrected to current relative cycle rather than previous relative cycle
						ELSE CASE WHEN (IJB.CYCLE IS NULL AND IJB.RELATIVECYCLE IS NULL) THEN 5 END 
					     END 
				END,
				CASE WHEN(LEN(IJB.CHARACTERDATA)<=254) THEN IJB.CHARACTERDATA ELSE NULL END,			-- RCT Include Character Data if less than or equal to 254 characters
				CASE WHEN(LEN(IJB.CHARACTERDATA)> 254) THEN IJB.CHARACTERDATA ELSE NULL END,			-- RCT Include Text Data if greater than 254 characters
				CASE WHEN(IJB.NUMBERKEY is null ) THEN 'Event No. is not specified' 
				     WHEN(E.EVENTNO     is null ) THEN 'Event No. does not exist in the database' 
				     WHEN(IJB.RELATIVECYCLE=5 AND EC.NUMCYCLESALLOWED=1)
								  THEN 'Relative Cycle is ''Current or Next Cycle'' and Event is not Cyclic'
				     WHEN(IJB.CYCLE>isnull(EC.NUMCYCLESALLOWED,E.NUMCYCLESALLOWED))
								  THEN 'Cycle of event exceeds maximum allowed'
				     WHEN(IJB.RELATIVECYCLE=2 AND (CE.CYCLE+1)>isnull(EC.NUMCYCLESALLOWED,E.NUMCYCLESALLOWED))
								  THEN 'Next Cycle of event exceeds maximum allowed'
				END
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				left join EVENTS E 		on (E.EVENTNO=IJB.NUMBERKEY)
				left join CASEEVENT CE		on (CE.CASEID=IJB.CASEID
								and CE.EVENTNO=E.EVENTNO
								and CE.CYCLE=(	select max(CE1.CYCLE)
										from CASEEVENT CE1
										where CE1.CASEID=CE.CASEID
										and CE1.EVENTNO=E.EVENTNO))
				left join EVENTCONTROL EC	on (EC.CRITERIANO=CE.CREATEDBYCRITERIA
								and EC.EVENTNO   =E.EVENTNO)
				WHERE IJB.CASEID IS NOT NULL
				AND IJB.TRANSACTIONTYPE ='DUE DATE'"

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nBatchNo		int',
							  @nBatchNo=@nBatchNo

			Set @pnRowCount=@pnRowCount+@@Rowcount
		End
 
		If @nErrorCode=0
		Begin
			-- TRANSACTIONTYPE "ENTITY SIZE" 
			set @sSQLString="
				INSERT INTO IMPORTJOURNAL (
					IMPORTBATCHNO,TRANSACTIONNO,CASEID,PROCESSEDFLAG,VALIDATEONLYFLAG,TRANSACTIONTYPE,
					JOURNALNO,JOURNALPAGE,COUNTRYCODE,OFFICIALNO,
					CHARACTERDATA, REJECTREASON)

				SELECT @nBatchNo, IJB.TRANSACTIONNO, IJB.CASEID, 0, IJB.VALIDATEONLYFLAG, IJB.TRANSACTIONTYPE,
					IJB.JOURNALNO,IJB.JOURNALPAGE,IJB.COUNTRYCODE,IJB.OFFICIALNO,
					IJB.CHARACTERDATA,
					CASE WHEN (T.TABLECODE is null AND IJB.CHARACTERDATA is not null) 
						THEN 'Invalid entity size' 
					END
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				LEFT JOIN TABLECODES T	on (T.TABLECODE=(select max(T1.TABLECODE)
									 from TABLECODES T1
									 where T1.TABLETYPE=26
									 and T1.USERCODE=IJB.CHARACTERDATA))
				WHERE IJB.CASEID IS NOT NULL
				AND IJB.TRANSACTIONTYPE = 'ENTITY SIZE'"	

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nBatchNo		int',
							  @nBatchNo=@nBatchNo

			Set @pnRowCount=@pnRowCount+@@Rowcount
		End
 
		If @nErrorCode=0
		Begin
			-- TRANSACTIONTYPE "ESTIMATED CHARGE" 
			set @sSQLString="
				INSERT INTO IMPORTJOURNAL (
					IMPORTBATCHNO,TRANSACTIONNO,CASEID,PROCESSEDFLAG,VALIDATEONLYFLAG,TRANSACTIONTYPE,
					JOURNALNO,JOURNALPAGE,COUNTRYCODE,OFFICIALNO,NUMBERKEY,CHARACTERKEY,
					CHARACTERDATA,INTEGERDATA,DECIMALDATA, REJECTREASON)

				SELECT @nBatchNo, IJB.TRANSACTIONNO, IJB.CASEID, 0, IJB.VALIDATEONLYFLAG, IJB.TRANSACTIONTYPE,
					IJB.JOURNALNO,IJB.JOURNALPAGE,IJB.COUNTRYCODE,IJB.OFFICIALNO,IJB.NUMBERKEY,
					IJB.CHARACTERKEY, IJB.CHARACTERDATA, 
					I2.INTEGERDATA-isnull(VP.CYCLEOFFSET,0), -- calculate the cycle from the Renewal Year
					IJB.DECIMALDATA,
					CASE WHEN (IJB.DECIMALDATA<0 or IJB.DECIMALDATA is null) 
						THEN 'Estimated charge must be positive value' 
					     WHEN (R.RATENO is null)
						THEN 'Estimated charge must specify a valid Rate Number'
					     WHEN (IJB.CHARACTERKEY is not null and C.CURRENCY is null)
						THEN 'Estimated charge has Invalid Currency Code'
					     WHEN (IJB.CHARACTERDATA not in ('S','D'))
						THEN 'Estimated charge must indicate Service or Disbursement'
					END
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				left join RATES R 	on (R.RATENO=IJB.NUMBERKEY)
				left join CURRENCY C	on (C.CURRENCY=IJB.CHARACTERKEY)
				left join "+@sUserName+".IMPORTJOURNALBULK I2
							on (I2.CASEID=IJB.CASEID
							and I2.TRANSACTIONTYPE='RENEWAL YEAR')
				left join CASES CS	on (CS.CASEID=I2.CASEID)
				left join VALIDPROPERTY VP
							on (VP.PROPERTYTYPE=CS.PROPERTYTYPE
							and VP.COUNTRYCODE=(select min(VP1.COUNTRYCODE)
									    from VALIDPROPERTY VP1
									    where VP1.PROPERTYTYPE=VP.PROPERTYTYPE
									    and VP1.COUNTRYCODE in (CS.COUNTRYCODE,'ZZZ')))
				WHERE IJB.CASEID IS NOT NULL
				AND IJB.TRANSACTIONTYPE = 'ESTIMATED CHARGE'"	

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nBatchNo		int',
							  @nBatchNo=@nBatchNo

			Set @pnRowCount=@pnRowCount+@@Rowcount
		End

		If @nErrorCode=0
		Begin
			-- TRANSACTIONTYPE "EVENT DATE" 
			set @sSQLString="
				INSERT INTO IMPORTJOURNAL (
				IMPORTBATCHNO,TRANSACTIONNO,CASEID,PROCESSEDFLAG,VALIDATEONLYFLAG,TRANSACTIONTYPE,
				JOURNALNO,JOURNALPAGE,COUNTRYCODE,OFFICIALNO,
				ACTION, NUMBERKEY, DATEDATA, CYCLE, RELATIVECYCLE, CHARACTERDATA, TEXTDATA, REJECTREASON) 		-- RCT Include CHARACTERDATA

				SELECT @nBatchNo, IJB.TRANSACTIONNO, IJB.CASEID, 0, IJB.VALIDATEONLYFLAG, IJB.TRANSACTIONTYPE,
				IJB.JOURNALNO,IJB.JOURNALPAGE,IJB.COUNTRYCODE,IJB.OFFICIALNO,
				IJB.ACTION, IJB.NUMBERKEY, IJB.DATEDATA, IJB.CYCLE,
				CASE WHEN IJB.RELATIVECYCLE IS NOT NULL
					THEN IJB.RELATIVECYCLE
					ELSE CASE WHEN (IJB.CYCLE IS NULL AND IJB.RELATIVECYCLE IS NULL AND VALIDATEONLYFLAG in (1, 2))	-- RCT include ValidateOnlyFlag = 2
						THEN 0											-- RCT Corrected to current relative cycle rather than previous relative cycle
						ELSE CASE WHEN (IJB.CYCLE IS NULL AND IJB.RELATIVECYCLE IS NULL) THEN 5 END 
					     END 
				END,
				CASE WHEN(LEN(IJB.CHARACTERDATA)<=254) THEN IJB.CHARACTERDATA ELSE NULL END,			-- RCT Include Character Data if less than or equal to 254 characters
				CASE WHEN(LEN(IJB.CHARACTERDATA)> 254) THEN IJB.CHARACTERDATA ELSE NULL END,			-- RCT Include Text Data if greater than 254 characters
				CASE WHEN(IJB.NUMBERKEY is null ) THEN 'Event No. is not specified'
				     WHEN(E.EVENTNO     is null ) THEN 'Event No. does not exist in the database' 
				     WHEN(IJB.RELATIVECYCLE=5 AND EC.NUMCYCLESALLOWED=1)
								  THEN 'Relative Cycle is ''Current or Next Cycle'' and Event is not Cyclic'
				     WHEN(IJB.CYCLE>isnull(EC.NUMCYCLESALLOWED,E.NUMCYCLESALLOWED))
								  THEN 'Cycle of event exceeds maximum allowed'
				     WHEN(IJB.RELATIVECYCLE=2 AND (CE.CYCLE+1)>isnull(EC.NUMCYCLESALLOWED,E.NUMCYCLESALLOWED))
								  THEN 'Next Cycle of event exceeds maximum allowed'
				END
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				left join EVENTS E 		on (E.EVENTNO=IJB.NUMBERKEY)
				left join CASEEVENT CE		on (CE.CASEID=IJB.CASEID
								and CE.EVENTNO=E.EVENTNO
								and CE.CYCLE=(	select max(CE1.CYCLE)
										from CASEEVENT CE1
										where CE1.CASEID=CE.CASEID
										and CE1.EVENTNO=E.EVENTNO))
				left join EVENTCONTROL EC	on (EC.CRITERIANO=CE.CREATEDBYCRITERIA
								and EC.EVENTNO   =E.EVENTNO)
				WHERE IJB.CASEID IS NOT NULL
				AND IJB.TRANSACTIONTYPE ='EVENT DATE'"

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nBatchNo		int',
							  @nBatchNo=@nBatchNo

			Set @pnRowCount=@pnRowCount+@@Rowcount
		End

		If @nErrorCode=0
		Begin
			-- TRANSACTIONTYPE "EVENT TEXT"
			set @sSQLString="
				INSERT INTO IMPORTJOURNAL (
				IMPORTBATCHNO,TRANSACTIONNO,CASEID,PROCESSEDFLAG,VALIDATEONLYFLAG,TRANSACTIONTYPE,
				JOURNALNO,JOURNALPAGE,COUNTRYCODE,OFFICIALNO,
				ACTION, NUMBERKEY, CYCLE, RELATIVECYCLE, CHARACTERDATA, TEXTDATA, REJECTREASON) 			-- RCT Include CHARACTERDATA

				SELECT @nBatchNo, IJB.TRANSACTIONNO, IJB.CASEID, 0, IJB.VALIDATEONLYFLAG, IJB.TRANSACTIONTYPE,
				IJB.JOURNALNO,IJB.JOURNALPAGE,IJB.COUNTRYCODE,IJB.OFFICIALNO,
				IJB.ACTION, IJB.NUMBERKEY, IJB.CYCLE,
				CASE WHEN IJB.RELATIVECYCLE IS NOT NULL
					THEN IJB.RELATIVECYCLE
					ELSE CASE WHEN (IJB.CYCLE IS NULL AND IJB.RELATIVECYCLE IS NULL AND VALIDATEONLYFLAG in (1, 2))	-- RCT include ValidateOnlyFlag = 2
						THEN 0											-- RCT Corrected to current relative cycle rather than previous relative cycle
						ELSE CASE WHEN (IJB.CYCLE IS NULL AND IJB.RELATIVECYCLE IS NULL) THEN 5 END 
					     END 
				END,
				CASE WHEN(LEN(IJB.CHARACTERDATA)<=254) THEN IJB.CHARACTERDATA ELSE NULL END,			-- RCT Include Character Data if less than or equal to 254 characters
				CASE WHEN(LEN(IJB.CHARACTERDATA)> 254) THEN IJB.CHARACTERDATA ELSE NULL END,			-- RCT Include Text Data if greater than 254 characters
				CASE WHEN(IJB.NUMBERKEY is null ) THEN 'Event No. is not specified'
				     WHEN(E.EVENTNO     is null ) THEN 'Event No. does not exist in the database' 
				     WHEN(IJB.RELATIVECYCLE=5 AND EC.NUMCYCLESALLOWED=1)
								  THEN 'Relative Cycle is ''Current or Next Cycle'' and Event is not Cyclic'
				     WHEN(IJB.CYCLE>isnull(EC.NUMCYCLESALLOWED,E.NUMCYCLESALLOWED))
								  THEN 'Cycle of event exceeds maximum allowed'
				     WHEN(IJB.RELATIVECYCLE=2 AND (CE.CYCLE+1)>isnull(EC.NUMCYCLESALLOWED,E.NUMCYCLESALLOWED))
								  THEN 'Next Cycle of event exceeds maximum allowed'
				END
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				left join EVENTS E 		on (E.EVENTNO=IJB.NUMBERKEY)
				left join CASEEVENT CE		on (CE.CASEID=IJB.CASEID
								and CE.EVENTNO=E.EVENTNO
								and CE.CYCLE=(	select max(CE1.CYCLE)
										from CASEEVENT CE1
										where CE1.CASEID=CE.CASEID
										and CE1.EVENTNO=E.EVENTNO))
				left join EVENTCONTROL EC	on (EC.CRITERIANO=CE.CREATEDBYCRITERIA
								and EC.EVENTNO   =E.EVENTNO)
				WHERE IJB.CASEID IS NOT NULL
				AND IJB.TRANSACTIONTYPE ='EVENT TEXT'"

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nBatchNo		int',
							  @nBatchNo=@nBatchNo

			Set @pnRowCount=@pnRowCount+@@Rowcount
		End

		If @nErrorCode=0
		Begin
			-- TRANSACTIONTYPE "JOURNAL"
			set @sSQLString="
				INSERT INTO IMPORTJOURNAL (
				IMPORTBATCHNO,TRANSACTIONNO,CASEID,PROCESSEDFLAG,VALIDATEONLYFLAG,TRANSACTIONTYPE,
				JOURNALNO,JOURNALPAGE,COUNTRYCODE,OFFICIALNO,
				DATEDATA, REJECTREASON)

				SELECT @nBatchNo, IJB.TRANSACTIONNO, IJB.CASEID, 0, IJB.VALIDATEONLYFLAG, IJB.TRANSACTIONTYPE,
				IJB.JOURNALNO,IJB.JOURNALPAGE,IJB.COUNTRYCODE,IJB.OFFICIALNO,
				IJB.DATEDATA, 
				CASE WHEN IJB.JOURNALNO IS NULL 
					THEN 'Journal No. has not been supplied'
				END
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				WHERE IJB.CASEID IS NOT NULL
				AND IJB.TRANSACTIONTYPE ='JOURNAL'"

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nBatchNo		int',
							  @nBatchNo=@nBatchNo

			Set @pnRowCount=@pnRowCount+@@Rowcount
		End

		If @nErrorCode=0
		Begin
			-- TRANSACTIONTYPE "LOCAL CLASSES"
			set @sSQLString="
				INSERT INTO IMPORTJOURNAL (
				IMPORTBATCHNO,TRANSACTIONNO,CASEID,PROCESSEDFLAG,VALIDATEONLYFLAG,TRANSACTIONTYPE,
				JOURNALNO,JOURNALPAGE,COUNTRYCODE,OFFICIALNO,
				CHARACTERDATA, REJECTREASON)

				SELECT @nBatchNo, IJB.TRANSACTIONNO, IJB.CASEID, 0, IJB.VALIDATEONLYFLAG, IJB.TRANSACTIONTYPE,
				IJB.JOURNALNO,IJB.JOURNALPAGE,IJB.COUNTRYCODE,IJB.OFFICIALNO,
				IJB.CHARACTERDATA, 
				CASE WHEN IJB.CHARACTERDATA IS NULL 
					THEN 'A comma separated list of Classes was expected.' 
				END
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				WHERE IJB.CASEID IS NOT NULL
				AND IJB.TRANSACTIONTYPE ='LOCAL CLASSES'"

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nBatchNo		int',
							  @nBatchNo=@nBatchNo

			Set @pnRowCount=@pnRowCount+@@Rowcount
		End

		If @nErrorCode=0
		Begin
			-- TRANSACTIONTYPE "NAME"
			set @sSQLString="
				INSERT INTO IMPORTJOURNAL (
				IMPORTBATCHNO,TRANSACTIONNO,CASEID,PROCESSEDFLAG,VALIDATEONLYFLAG,TRANSACTIONTYPE,
				JOURNALNO,JOURNALPAGE,COUNTRYCODE,OFFICIALNO,
				CHARACTERKEY, CHARACTERDATA, REJECTREASON)

				SELECT @nBatchNo, IJB.TRANSACTIONNO, IJB.CASEID, 0, IJB.VALIDATEONLYFLAG, IJB.TRANSACTIONTYPE,
				IJB.JOURNALNO,IJB.JOURNALPAGE,IJB.COUNTRYCODE,IJB.OFFICIALNO,
				IJB.CHARACTERKEY, IJB.CHARACTERDATA, 
				CASE WHEN IJB.CHARACTERKEY is null THEN 'A Name Type must be supplied.' 
				     WHEN NT.NAMETYPE      is null THEN 'The Name Type supplied is not valid.' 
				END
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				LEFT JOIN NAMETYPE NT ON (NT.NAMETYPE=IJB.CHARACTERKEY)
				WHERE IJB.CASEID IS NOT NULL
				AND IJB.TRANSACTIONTYPE ='NAME'"

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nBatchNo		int',
							  @nBatchNo=@nBatchNo

			Set @pnRowCount=@pnRowCount+@@Rowcount
		End

		If @nErrorCode=0
		Begin
			-- TRANSACTIONTYPE "NAME ALIAS"
			set @sSQLString="
				INSERT INTO IMPORTJOURNAL (
				IMPORTBATCHNO,TRANSACTIONNO,CASEID,PROCESSEDFLAG,VALIDATEONLYFLAG,TRANSACTIONTYPE,
				JOURNALNO,JOURNALPAGE,COUNTRYCODE,OFFICIALNO,
				CHARACTERKEY, CHARACTERDATA, REJECTREASON)

				SELECT DISTINCT @nBatchNo, IJB.TRANSACTIONNO, IJB.CASEID, 0, IJB.VALIDATEONLYFLAG, IJB.TRANSACTIONTYPE,
				IJB.JOURNALNO,IJB.JOURNALPAGE,IJB.COUNTRYCODE,IJB.OFFICIALNO,
				IJB.CHARACTERKEY, IJB.CHARACTERDATA,
				CASE WHEN IJB.CHARACTERKEY is null THEN 'An Alias Type must be supplied.' 
				     WHEN NA.ALIASTYPE     is null THEN 'The Alias Type supplied is not valid.' 
				END
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				LEFT JOIN NAMEALIAS NA ON (NA.ALIASTYPE=IJB.CHARACTERKEY)
				WHERE IJB.CASEID IS NOT NULL
				AND IJB.TRANSACTIONTYPE ='NAME ALIAS'"

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nBatchNo		int',
							  @nBatchNo=@nBatchNo

			Set @pnRowCount=@pnRowCount+@@Rowcount
		End

		If @nErrorCode=0
		Begin
			-- TRANSACTIONTYPE "NAME COUNTRY"
			set @sSQLString="
				INSERT INTO IMPORTJOURNAL (
				IMPORTBATCHNO,TRANSACTIONNO,CASEID,PROCESSEDFLAG,VALIDATEONLYFLAG,TRANSACTIONTYPE,
				JOURNALNO,JOURNALPAGE,COUNTRYCODE,OFFICIALNO,
				CHARACTERKEY, REJECTREASON)

				SELECT @nBatchNo, IJB.TRANSACTIONNO, IJB.CASEID, 0, IJB.VALIDATEONLYFLAG, IJB.TRANSACTIONTYPE,
				IJB.JOURNALNO,IJB.JOURNALPAGE,IJB.COUNTRYCODE,IJB.OFFICIALNO,
				IJB.CHARACTERKEY,
				CASE WHEN IJB.CHARACTERKEY is null THEN 'The Country of the Name must be supplied.' 
				     WHEN C.COUNTRYCODE    is null THEN 'The Country supplied is not valid.' 
				END
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				LEFT JOIN COUNTRY C ON (C.COUNTRYCODE=IJB.CHARACTERKEY)
				WHERE IJB.CASEID IS NOT NULL
				AND IJB.TRANSACTIONTYPE ='NAME COUNTRY'"

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nBatchNo		int',
							  @nBatchNo=@nBatchNo

			Set @pnRowCount=@pnRowCount+@@Rowcount
		End

		If @nErrorCode=0
		Begin
			-- TRANSACTIONTYPE "NAME STATE"
			set @sSQLString="
				INSERT INTO IMPORTJOURNAL (
				IMPORTBATCHNO,TRANSACTIONNO,CASEID,PROCESSEDFLAG,VALIDATEONLYFLAG,TRANSACTIONTYPE,
				JOURNALNO,JOURNALPAGE,COUNTRYCODE,OFFICIALNO,
				CHARACTERDATA, REJECTREASON)

				SELECT @nBatchNo, IJB.TRANSACTIONNO, IJB.CASEID, 0, IJB.VALIDATEONLYFLAG, IJB.TRANSACTIONTYPE,
				IJB.JOURNALNO,IJB.JOURNALPAGE,IJB.COUNTRYCODE,IJB.OFFICIALNO,
				IJB.CHARACTERDATA, 
				CASE WHEN IJB.CHARACTERDATA is null THEN 'The State associated with the Name must be supplied.' END
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				WHERE IJB.CASEID IS NOT NULL
				AND IJB.TRANSACTIONTYPE ='NAME STATE'"

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nBatchNo		int',
							  @nBatchNo=@nBatchNo

			Set @pnRowCount=@pnRowCount+@@Rowcount
		End

		If @nErrorCode=0
		Begin
			-- TRANSACTIONTYPE "NAME VAT NO"
			set @sSQLString="
				INSERT INTO IMPORTJOURNAL (
				IMPORTBATCHNO,TRANSACTIONNO,CASEID,PROCESSEDFLAG,VALIDATEONLYFLAG,TRANSACTIONTYPE,
				JOURNALNO,JOURNALPAGE,COUNTRYCODE,OFFICIALNO,
				CHARACTERDATA, REJECTREASON)

				SELECT @nBatchNo, IJB.TRANSACTIONNO, IJB.CASEID, 0, IJB.VALIDATEONLYFLAG, IJB.TRANSACTIONTYPE,
				IJB.JOURNALNO,IJB.JOURNALPAGE,IJB.COUNTRYCODE,IJB.OFFICIALNO,
				IJB.CHARACTERDATA, 
				CASE WHEN IJB.CHARACTERDATA is null THEN 'The VAT Number associated with the Name must be supplied.' END 
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				WHERE IJB.CASEID IS NOT NULL
				AND IJB.TRANSACTIONTYPE ='NAME VAT NO'"

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nBatchNo		int',
							  @nBatchNo=@nBatchNo

			Set @pnRowCount=@pnRowCount+@@Rowcount
		End
 
		If @nErrorCode=0
		Begin
			-- TRANSACTIONTYPE "NUMBER OF CLAIMS" 
			set @sSQLString="
				INSERT INTO IMPORTJOURNAL (
					IMPORTBATCHNO,TRANSACTIONNO,CASEID,PROCESSEDFLAG,VALIDATEONLYFLAG,TRANSACTIONTYPE,
					JOURNALNO,JOURNALPAGE,COUNTRYCODE,OFFICIALNO,
					INTEGERDATA, REJECTREASON)

				SELECT @nBatchNo, IJB.TRANSACTIONNO, IJB.CASEID, 0, IJB.VALIDATEONLYFLAG, IJB.TRANSACTIONTYPE,
					IJB.JOURNALNO,IJB.JOURNALPAGE,IJB.COUNTRYCODE,IJB.OFFICIALNO,
					IJB.INTEGERDATA,
					CASE WHEN (IJB.INTEGERDATA is null or IJB.INTEGERDATA<0) 
						THEN 'Number of claims must be positive number' 
					END
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				WHERE IJB.CASEID IS NOT NULL
				AND IJB.TRANSACTIONTYPE = 'NUMBER OF CLAIMS'"	

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nBatchNo		int',
							  @nBatchNo=@nBatchNo

			Set @pnRowCount=@pnRowCount+@@Rowcount
		End

		If @nErrorCode=0
		Begin
			-- TRANSACTIONTYPE "NUMBER TYPE"
			set @sSQLString="
				INSERT INTO IMPORTJOURNAL (
				IMPORTBATCHNO,TRANSACTIONNO,CASEID,PROCESSEDFLAG,VALIDATEONLYFLAG,TRANSACTIONTYPE,
				JOURNALNO,JOURNALPAGE,COUNTRYCODE,OFFICIALNO,
				CHARACTERKEY, CHARACTERDATA, DATEDATA, REJECTREASON)

				SELECT @nBatchNo, IJB.TRANSACTIONNO, IJB.CASEID, 0, IJB.VALIDATEONLYFLAG, IJB.TRANSACTIONTYPE,
				IJB.JOURNALNO,IJB.JOURNALPAGE,IJB.COUNTRYCODE,IJB.OFFICIALNO,
				IJB.CHARACTERKEY, IJB.CHARACTERDATA, IJB.DATEDATA, 
				CASE WHEN IJB.CHARACTERKEY is null     THEN 'A Number Type must be supplied.' 
				     WHEN NT.NUMBERTYPE    is null     THEN 'The Number Type supplied is not valid.' 
				     WHEN IJB.REJECTREASON is not null THEN 'Official number failed format validation'
				END
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				left join NUMBERTYPES NT ON (NT.NUMBERTYPE=IJB.CHARACTERKEY)
				WHERE IJB.CASEID IS NOT NULL
				AND IJB.TRANSACTIONTYPE ='NUMBER TYPE'"

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nBatchNo		int',
							  @nBatchNo=@nBatchNo

			Set @pnRowCount=@pnRowCount+@@Rowcount
		End

		If @nErrorCode=0
		Begin
			-- TRANSACTIONTYPE "REFERENCE NUMBER"
			set @sSQLString="
				INSERT INTO IMPORTJOURNAL (
				IMPORTBATCHNO,TRANSACTIONNO,CASEID,PROCESSEDFLAG,VALIDATEONLYFLAG,TRANSACTIONTYPE,
				JOURNALNO,JOURNALPAGE,COUNTRYCODE,OFFICIALNO,
				CHARACTERKEY, CHARACTERDATA, DATEDATA, REJECTREASON)

				SELECT @nBatchNo, IJB.TRANSACTIONNO, IJB.CASEID, 0, IJB.VALIDATEONLYFLAG, IJB.TRANSACTIONTYPE,
				IJB.JOURNALNO,IJB.JOURNALPAGE,IJB.COUNTRYCODE,IJB.OFFICIALNO,
				IJB.CHARACTERKEY, IJB.CHARACTERDATA, IJB.DATEDATA, NULL
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				WHERE IJB.CASEID IS NOT NULL
				AND IJB.TRANSACTIONTYPE ='REFERENCE NUMBER'"

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nBatchNo		int',
							  @nBatchNo=@nBatchNo

			Set @pnRowCount=@pnRowCount+@@Rowcount
		End

		If @nErrorCode=0
		Begin
			-- TRANSACTIONTYPE "RELATED COUNTRY"
			set @sSQLString="
				INSERT INTO IMPORTJOURNAL (
				IMPORTBATCHNO,TRANSACTIONNO,CASEID,PROCESSEDFLAG,VALIDATEONLYFLAG,TRANSACTIONTYPE,
				JOURNALNO,JOURNALPAGE,COUNTRYCODE,OFFICIALNO,
				CHARACTERKEY, CHARACTERDATA, REJECTREASON)

				SELECT @nBatchNo, IJB.TRANSACTIONNO, IJB.CASEID, 0, IJB.VALIDATEONLYFLAG, IJB.TRANSACTIONTYPE,
				IJB.JOURNALNO,IJB.JOURNALPAGE,IJB.COUNTRYCODE,IJB.OFFICIALNO,
				IJB.CHARACTERKEY, IJB.CHARACTERDATA,
				CASE WHEN IJB.CHARACTERKEY is null THEN 'A Case Relationship must be supplied.' 
				     WHEN CR.RELATIONSHIP  is null THEN 'The Case Relationship supplied is not valid.' 
				     WHEN (CT.COUNTRYCODE  is null AND IJB.CHARACTERDATA is not null)
								   THEN 'The Country Code supplied is not valid'
				END
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				left join CASERELATION CR ON (CR.RELATIONSHIP=IJB.CHARACTERKEY)
				left join COUNTRY CT      ON (CT.COUNTRYCODE=IJB.CHARACTERDATA)
				WHERE IJB.CASEID IS NOT NULL
				AND IJB.TRANSACTIONTYPE ='RELATED COUNTRY'"

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nBatchNo		int',
							  @nBatchNo=@nBatchNo

			Set @pnRowCount=@pnRowCount+@@Rowcount
		End

		If @nErrorCode=0
		Begin
			-- TRANSACTIONTYPE "RELATED DATE"
			set @sSQLString="
				INSERT INTO IMPORTJOURNAL (
				IMPORTBATCHNO,TRANSACTIONNO,CASEID,PROCESSEDFLAG,VALIDATEONLYFLAG,TRANSACTIONTYPE,
				JOURNALNO,JOURNALPAGE,COUNTRYCODE,OFFICIALNO,
				CHARACTERKEY, DATEDATA, REJECTREASON)

				SELECT @nBatchNo, IJB.TRANSACTIONNO, IJB.CASEID, 0, IJB.VALIDATEONLYFLAG, IJB.TRANSACTIONTYPE,
				IJB.JOURNALNO,IJB.JOURNALPAGE,IJB.COUNTRYCODE,IJB.OFFICIALNO,
				IJB.CHARACTERKEY, IJB.DATEDATA,
				CASE WHEN IJB.CHARACTERKEY is null THEN 'A Case Relationship must be supplied.' 
				     WHEN CR.RELATIONSHIP  is null THEN 'The Case Relationship supplied is not valid.' 
				END
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				LEFT JOIN CASERELATION CR ON (CR.RELATIONSHIP=IJB.CHARACTERKEY)
				WHERE IJB.CASEID IS NOT NULL
				AND IJB.TRANSACTIONTYPE ='RELATED DATE'"

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nBatchNo		int',
							  @nBatchNo=@nBatchNo

			Set @pnRowCount=@pnRowCount+@@Rowcount
		End

		If @nErrorCode=0
		Begin
			-- TRANSACTIONTYPE "RELATED NUMBER"
			set @sSQLString="
				INSERT INTO IMPORTJOURNAL (
				IMPORTBATCHNO,TRANSACTIONNO,CASEID,PROCESSEDFLAG,VALIDATEONLYFLAG,TRANSACTIONTYPE,
				JOURNALNO,JOURNALPAGE,COUNTRYCODE,OFFICIALNO,
				CHARACTERKEY, CHARACTERDATA, REJECTREASON)

				SELECT @nBatchNo, IJB.TRANSACTIONNO, IJB.CASEID, 0, IJB.VALIDATEONLYFLAG, IJB.TRANSACTIONTYPE,
				IJB.JOURNALNO,IJB.JOURNALPAGE,IJB.COUNTRYCODE,IJB.OFFICIALNO,
				IJB.CHARACTERKEY, IJB.CHARACTERDATA,
				CASE WHEN IJB.CHARACTERKEY is null THEN 'A Case Relationship must be supplied.' 
				     WHEN CR.RELATIONSHIP  is null THEN 'The Case Relationship supplied is not valid.' 
				END
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				LEFT JOIN CASERELATION CR ON (CR.RELATIONSHIP=IJB.CHARACTERKEY)
				WHERE IJB.CASEID IS NOT NULL
				AND IJB.TRANSACTIONTYPE ='RELATED NUMBER'"

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nBatchNo		int',
							  @nBatchNo=@nBatchNo

			Set @pnRowCount=@pnRowCount+@@Rowcount
		End

		If @nErrorCode=0
		Begin
			-- TRANSACTIONTYPE "TEXT"
			set @sSQLString="
				INSERT INTO IMPORTJOURNAL (
				IMPORTBATCHNO,TRANSACTIONNO,CASEID,PROCESSEDFLAG,VALIDATEONLYFLAG,TRANSACTIONTYPE,
				JOURNALNO,JOURNALPAGE,COUNTRYCODE,OFFICIALNO,
				CHARACTERKEY, CHARACTERDATA, TEXTDATA, REJECTREASON)

				SELECT @nBatchNo, IJB.TRANSACTIONNO, IJB.CASEID, 0, IJB.VALIDATEONLYFLAG, IJB.TRANSACTIONTYPE,
				IJB.JOURNALNO,IJB.JOURNALPAGE,IJB.COUNTRYCODE,IJB.OFFICIALNO,
				IJB.CHARACTERKEY, 
				CASE WHEN (LEN(IJB.CHARACTERDATA)< 254) THEN IJB.CHARACTERDATA ELSE NULL END,
				CASE WHEN (LEN(IJB.CHARACTERDATA)>=254) THEN IJB.CHARACTERDATA ELSE NULL END,
				CASE WHEN IJB.CHARACTERKEY IS NULL  THEN 'The Text Type has not been supplied' 
				     WHEN TT.TEXTTYPE IS NULL       THEN 'The Text Type supplied is not valid' 
				     WHEN IJB.CHARACTERDATA IS NULL THEN 'The Text has not been supplied'
				END
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				left join TEXTTYPE TT ON (TT.TEXTTYPE=IJB.CHARACTERKEY)
				WHERE IJB.CASEID IS NOT NULL
				AND IJB.TRANSACTIONTYPE ='TEXT'"

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nBatchNo		int',
							  @nBatchNo=@nBatchNo

			Set @pnRowCount=@pnRowCount+@@Rowcount
		End

		If @nErrorCode=0
		Begin
			-- TRANSACTIONTYPE "TITLE"
			set @sSQLString="
				INSERT INTO IMPORTJOURNAL (
				IMPORTBATCHNO,TRANSACTIONNO,CASEID,PROCESSEDFLAG,VALIDATEONLYFLAG,TRANSACTIONTYPE,
				JOURNALNO,JOURNALPAGE,COUNTRYCODE,OFFICIALNO,
				CHARACTERDATA, REJECTREASON)

				SELECT @nBatchNo, IJB.TRANSACTIONNO, IJB.CASEID, 0, IJB.VALIDATEONLYFLAG, IJB.TRANSACTIONTYPE,
				IJB.JOURNALNO,IJB.JOURNALPAGE,IJB.COUNTRYCODE,IJB.OFFICIALNO,
				IJB.CHARACTERDATA,
				CASE WHEN IJB.CHARACTERDATA IS NULL THEN 'The Title has not been supplied' 
				END
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				WHERE IJB.CASEID IS NOT NULL
				AND IJB.TRANSACTIONTYPE ='TITLE'"

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nBatchNo		int',
							  @nBatchNo=@nBatchNo

			Set @pnRowCount=@pnRowCount+@@Rowcount
		End

		If @nErrorCode=0
		Begin
			-- TRANSACTIONTYPE "TYPE OF MARK"
			set @sSQLString="
				INSERT INTO IMPORTJOURNAL (
				IMPORTBATCHNO,TRANSACTIONNO,CASEID,PROCESSEDFLAG,VALIDATEONLYFLAG,TRANSACTIONTYPE,
				JOURNALNO,JOURNALPAGE,COUNTRYCODE,OFFICIALNO,
				CHARACTERDATA, REJECTREASON)

				SELECT @nBatchNo, IJB.TRANSACTIONNO, IJB.CASEID, 0, IJB.VALIDATEONLYFLAG, IJB.TRANSACTIONTYPE,
				IJB.JOURNALNO,IJB.JOURNALPAGE,IJB.COUNTRYCODE,IJB.OFFICIALNO,
				IJB.CHARACTERDATA,
				CASE WHEN IJB.CHARACTERDATA IS NULL THEN 'The Type of Mark has not been supplied' 
				END
				FROM "+@sUserName+".IMPORTJOURNALBULK IJB
				WHERE IJB.CASEID IS NOT NULL
				AND IJB.TRANSACTIONTYPE ='TYPE OF MARK'"

			Exec @nErrorCode=sp_executesql @sSQLString, 
							N'@nBatchNo		int',
							  @nBatchNo=@nBatchNo

			Set @pnRowCount=@pnRowCount+@@Rowcount
		End

		-- Renumber the transactions so that they are contiguous starting from 1
		If @nErrorCode=0
		Begin
			Set @nTransactionNo=0

			Set @sSQLString="
				alter table IMPORTJOURNAL disable trigger all
				
				Update IMPORTJOURNAL
				Set 	@nTransactionNo= @nTransactionNo+1,
					TRANSACTIONNO  = @nTransactionNo
				Where IMPORTBATCHNO=@nBatchNo
				
				alter table IMPORTJOURNAL enable trigger all"

			Exec @nErrorCode=sp_executesql @sSQLString,
							N'@nBatchNo		int,
							  @nTransactionNo	int',
							  @nBatchNo=@nBatchNo,
							  @nTransactionNo=@nTransactionNo
		End

		-- For each transaction with a reject reason set the processed flag equal to 1. 		RCTT - 14/11/2003
		If @nErrorCode=0
		Begin
			set @sSQLString="
				UPDATE IMPORTJOURNAL
				SET PROCESSEDFLAG=1
				WHERE REJECTREASON <> 'Official number failed format validation'
				AND IMPORTBATCHNO=@nBatchNo"

			Exec @nErrorCode=sp_executesql @sSQLString,
						N'@nBatchNo	int',
						  @nBatchNo=@nBatchNo
		End

		-- For each transaction with a rejected reason determine if there is an ImportControl row that
		-- indicates that an event is to be inserted or updated to process the error.

		If @nErrorCode=0
		Begin
			set @sSQLString="
			insert into #TEMPCASEEVENT(CASEID, TRANSACTIONNO, REJECTREASON, JOURNALNO, CYCLE, EVENTNO)
			select	I.CASEID, I.TRANSACTIONNO, I.REJECTREASON, I.JOURNALNO, 1,
			convert(int,
			substring(
			max(
			CASE WHEN(IC.TRANSACTIONTYPE is null) THEN '0' ELSE '1' END+
			CASE WHEN(IC.PROPERTYTYPE    is null) THEN '0' ELSE '1' END+
			CASE WHEN(IC.COUNTRYCODE     is null) THEN '0' ELSE '1' END+
			convert(varchar(11), IC.EVENTNO)),4,20))		
			from IMPORTCONTROL IC
			join IMPORTJOURNAL I	on (I.IMPORTBATCHNO = @nBatchNo
						and I.REJECTREASON is not null)
			join CASES C		on (C.CASEID=I.CASEID)
			where (IC.COUNTRYCODE    =C.COUNTRYCODE    or IC.COUNTRYCODE      is null)
			and   (IC.PROPERTYTYPE   =C.PROPERTYTYPE    or IC.PROPERTYTYPE    is null)
			and   (IC.TRANSACTIONTYPE=I.TRANSACTIONTYPE or IC.TRANSACTIONTYPE is null)
			group by I.CASEID, I.TRANSACTIONNO, I.REJECTREASON, I.JOURNALNO"

			exec @nErrorCode=sp_executesql @sSQLString,
						N'@nBatchNo	int',
						  @nBatchNo=@nBatchNo

			Set @nRejectCount=@@Rowcount
		End

		-- If there were rows written to #TEMPCASEEVENT then load them into CASEEVENT
		If @nRejectCount>0
		Begin
			-- Update the IMPORTJOURNAL with details of the Event to be inserted.
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Update IMPORTJOURNAL
				Set ERROREVENTNO=T.EVENTNO
				from IMPORTJOURNAL I
				join #TEMPCASEEVENT T	on (T.CASEID=I.CASEID
							and T.TRANSACTIONNO=I.TRANSACTIONNO)
				where I.IMPORTBATCHNO=@nBatchNo"				-- RCTT 14/11/2003 corrected I.BATCHNO to I.IMPORTBATCHNO

				exec @nErrorCode=sp_executesql @sSQLString,
							N'@nBatchNo	int',
							  @nBatchNo=@nBatchNo
			End

			-- Update any preexisting CASEEVENT rows
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				update CASEEVENT
				set	EVENTDATE=convert(nvarchar,getdate(),112),
					OCCURREDFLAG=1,
					DATEREMIND=NULL,
					EVENTTEXT=T.REJECTREASON,
					JOURNALNO=T.JOURNALNO,
					IMPORTBATCHNO=@nBatchNo
				from CASEEVENT CE
				join #TEMPCASEEVENT T	on (T.CASEID =CE.CASEID
							and T.EVENTNO=CE.EVENTNO
							and T.CYCLE  =CE.CYCLE)
				where T.CYCLE=1"

				exec @nErrorCode=sp_executesql @sSQLString,
							N'@nBatchNo	int',
							  @nBatchNo=@nBatchNo
			End

			-- Insert new CASEEVENT rows
			If @nErrorCode=0
			Begin
				-- It is possible for the same transaction type to appear for the same Case in a batch.
				-- To avoid a duplicate CASEEVENT row being inserted if the transactions are deleted then
				-- use a DISTINCT clause.
				Set @sSQLString="
				insert into CASEEVENT(CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG, EVENTTEXT, JOURNALNO, IMPORTBATCHNO)
				select distinct T.CASEID, T.EVENTNO, T.CYCLE, convert(nvarchar,getdate(),112), 1, T.REJECTREASON, T.JOURNALNO, @nBatchNo
				from #TEMPCASEEVENT T
				left join CASEEVENT CE	on (CE.CASEID =T.CASEID
							and CE.EVENTNO=T.EVENTNO
							and CE.CYCLE  =T.CYCLE)
				where CE.CASEID is null"

				exec @nErrorCode=sp_executesql @sSQLString,
							N'@nBatchNo	int',
							  @nBatchNo=@nBatchNo
			End

			-- Now insert a Policing row for each CASEEVENT updated or inserted.
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				insert into POLICING (	DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, 
							ONHOLDFLAG, EVENTNO, CASEID, CYCLE, TYPEOFREQUEST, SQLUSER, IDENTITYID)
				select	getdate(), T.TRANSACTIONNO, 
					convert(varchar, getdate(),126)+convert(varchar,T.TRANSACTIONNO),1,
					0,T.EVENTNO, T.CASEID, 1, 3, substring(SYSTEM_USER,1,60), @pnUserIdentityId
				from #TEMPCASEEVENT T"

				Exec @nErrorCode=sp_executesql @sSQLString,
								N'@pnUserIdentityId	 int',
								@pnUserIdentityId = @pnUserIdentityId

			
				Set @nRowCount=@@Rowcount
			End
		End	

		----------------------------------------------------
		-- Create OpenActions against the Cases in the batch
		----------------------------------------------------

		-- Load the OpenAction for the Header Case
		If @nErrorCode=0
		and @sHeaderAction is not null
		and @nHeaderCaseId is not null
		Begin
			Set @sSQLString="
			Insert into #TEMPOPENACTION(CASEID, ACTION, CYCLE)
			Select @nHeaderCaseId , A.ACTION, 1
			from ACTIONS A
			where A.ACTION=@sHeaderAction"

			exec @nErrorCode=sp_executesql @sSQLString,
						N'@nHeaderCaseId	int,
						  @sHeaderAction	nvarchar(2)',
						  @nHeaderCaseId=@nHeaderCaseId,
						  @sHeaderAction=@sHeaderAction

		End

		-- Load the OpenAction for the imported Cases
		If @nErrorCode=0
		and @sImportedAction is not null
		Begin
			Set @sSQLString="
			Insert into #TEMPOPENACTION(CASEID,ACTION,CYCLE)
			Select distinct I.CASEID, A.ACTION, 1
			From "+@sUserName+".IMPORTJOURNALBULK I
			     join ACTIONS A	on (A.ACTION=@sImportedAction)
			left join OPENACTION OA	on (OA.CASEID=I.CASEID
						and OA.ACTION=A.ACTION
						and OA.CYCLE=1)
			Where I.CASEID is not null
			and I.REJECTEDFLAG is null
			and (OA.CASEID is null or OA.POLICEEVENTS=0)"

			exec @nErrorCode=sp_executesql @sSQLString,
						N'@sImportedAction	nvarchar(2)',
						  @sImportedAction=@sImportedAction
		End

		-- Load the OpenAction for the rejected Cases
		If @nErrorCode=0
		and @sImportedAction is not null
		Begin
			Set @sSQLString="
			Insert into #TEMPOPENACTION(CASEID,ACTION,CYCLE)
			Select distinct I.CASEID, A.ACTION, 1
			From "+@sUserName+".IMPORTJOURNALBULK I
			     join ACTIONS A	on (A.ACTION=@sRejectedAction)
			left join OPENACTION OA	on (OA.CASEID=I.CASEID
						and OA.ACTION=A.ACTION
						and OA.CYCLE=1)
			Where I.CASEID is not null
			and I.REJECTEDFLAG=1
			and (OA.CASEID is null or OA.POLICEEVENTS=0)"

			exec @nErrorCode=sp_executesql @sSQLString,
						N'@sRejectedAction	nvarchar(2)',
						  @sRejectedAction=@sRejectedAction
		End

		-- Now load the live OPENACTION table if no row currently exists
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Insert into OPENACTION(CASEID, ACTION, CYCLE, POLICEEVENTS, DATEENTERED, DATEUPDATED)
			Select T.CASEID, T.ACTION, T.CYCLE, 1, getdate(), getdate()
			from #TEMPOPENACTION T
			left join OPENACTION OA	on (OA.CASEID=T.CASEID
						and OA.ACTION=T.ACTION
						and OA.CYCLE=1)
			where OA.CASEID is null"

			Exec @nErrorCode=sp_executesql @sSQLString
		End

		-- Update existing OPENACTION rows that are currently closed
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Update OPENACTION
			Set POLICEEVENTS=1
			From OPENACTION OA
			join #TEMPOPENACTION T	on (T.CASEID=OA.CASEID
						and T.ACTION=OA.ACTION
						and T.CYCLE =OA.CYCLE)
			where isnull(OA.POLICEEVENTS,0)=0"

			Exec @nErrorCode=sp_executesql @sSQLString
		End

		-- Now load a Policing row for each Open Action to be processed.
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			insert into POLICING (	DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, 
						ONHOLDFLAG, ACTION, CASEID, CYCLE, TYPEOFREQUEST, SQLUSER, IDENTITYID)
			select	getdate(), isnull(@nRowCount,0)+T.SEQUENCENO, 
				convert(varchar, getdate(),126)+convert(varchar,T.SEQUENCENO),1,
				0,T.ACTION, T.CASEID, 1, 1, substring(SYSTEM_USER,1,60), @pnUserIdentityId
			from #TEMPOPENACTION T"

			Exec @nErrorCode=sp_executesql @sSQLString,
						N'@nRowCount		int,
						  @pnUserIdentityId	int',
						  @nRowCount=@nRowCount,
						  @pnUserIdentityId=@pnUserIdentityId
		End


		-- Commit entire transaction if successful
		If @@TranCount > @nTranCountStart
		Begin
			If @nErrorCode = 0
			Begin
				COMMIT TRANSACTION

				-- now process the ImportJournal batch just loaded
				If @pnRowCount>0
				Begin
					exec @nErrorCode=dbo.ip_ImportJournalProcess @pnBatchNo=@nBatchNo
				End
			End
			Else Begin
				ROLLBACK TRANSACTION
			End
		End
	End	-- End of Validate Transaction section
End	-- End of @pnMode=2

If @nErrorCode = 0 and (@pnMode = 1 or @pnMode = 2)
Begin
	-- Clean up - prepare for next attempt if failed or next import if successful.
	exec @nErrorCode=xml_ImportJournalCleanup @sUserName
End
RETURN @nErrorCode
go

grant execute on dbo.xml_ImportJournalBulk to public
go
