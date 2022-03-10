-----------------------------------------------------------------------------------------------------------------------------
-- Creation of de_CaseComparisonCreate
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[de_CaseComparisonCreate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.de_CaseComparisonCreate.'
	Drop procedure [dbo].[de_CaseComparisonCreate]
End
Print '**** Creating Stored Procedure dbo.de_CaseComparisonCreate...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.de_CaseComparisonCreate
(
	@psTableNameQualifier	nvarchar(15)	OUTPUT, -- A qualifier appended to the table names to ensure that they are unique.
	@pnUserIdentityId	int		-- Mandatory
)
as
-- PROCEDURE:	de_CaseComparisonCreate
-- VERSION:	7
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Creates the work tables necessary for the case comparison process.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 Sep 2005	JEK	RFC1324	1	Procedure created
-- 21 Sep 2005	JEK	RFC1324	2	Add ImportedCaseID, add sender, case name table.
-- 23 Sep 2005	JEK	RFC3007	3	Extend processing.
-- 10 Oct 2005	TM	RFC3120	4	Change to add the new SequenceNumber attribute to the work tables.
-- 11 May 2006	JEK	RFC3009	5	Implement update flags and proposed values for updatable data.
-- 17 Aug 2006	JEK	RFC4241	6	Implement international classes
-- 19 May 2020	DL	DR-58943 7	Ability to enter up to 3 characters for Number type code via client server	

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(4000)
declare	@sTimeStamp	nvarchar(24)

declare @sSenderTable		nvarchar(50)
declare @sCaseTable		nvarchar(50)
declare @sOfficialNumberTable	nvarchar(50)
declare @sRelatedCaseTable	nvarchar(50)
declare @sEventTable		nvarchar(50)
declare @sCaseNameTable		nvarchar(50)

Set @psTableNameQualifier = '_'+ Cast(@@SPID as varchar(10))
-- Initialise variables
Set @nErrorCode = 0
Set @sSenderTable = 'CC_SENDER' + @psTableNameQualifier
Set @sCaseTable = 'CC_CASE' + @psTableNameQualifier
Set @sOfficialNumberTable = 'CC_OFFICIALNUMBER' + @psTableNameQualifier
Set @sRelatedCaseTable = 'CC_RELATEDCASE' + @psTableNameQualifier
Set @sEventTable = 'CC_CASEEVENT' + @psTableNameQualifier
Set @sCaseNameTable = 'CC_CASENAME' + @psTableNameQualifier

-- Create Work Tables
-- Each table contains the following general categories of information:
--	Imported information (IMP_)
--	Mapped information (MAP_ map imported values to implemented values for types)
--	Existing information (EX_ existing information on the database)
--	Proposed information (PR_ proposed changes to the system) - Implementation postponed

-- Sender information
If @nErrorCode = 0
Begin
	If exists(select * from dbo.sysobjects where name = @sSenderTable )
	Begin
		Set @sSQLString = "delete from "+@sSenderTable
	End
	Else
	Begin
		Set @sSQLString = "
		Create table "+@sSenderTable+" (
				-- Imported data
				IMP_SYSTEMCODE			nvarchar(20)	collate database_default
		)"
	End

	exec @nErrorCode = sp_executesql @sSQLString
End

-- Case information
If @nErrorCode = 0
Begin
	If exists(select * from dbo.sysobjects where name = @sCaseTable )
	Begin
		Set @sSQLString = "delete from "+@sCaseTable
	End
	Else
	Begin
		Set @sSQLString = "
		Create table "+@sCaseTable+" (
				-- Imported data
				IMP_CASESEQUENCE		int,
				IMP_CASEREFERENCE		nvarchar(30)	collate database_default,
				IMP_SHORTTITLE			nvarchar(254)	collate database_default,
				IMP_CASESTATUSDESCRIPTION	nvarchar(100)	collate database_default, -- Display only
				IMP_CASESTATUSDATE		datetime,
				IMP_LOCALCLASSES		nvarchar(254)	collate database_default,
				IMP_INTCLASSES			nvarchar(254)	collate database_default,
				IMP_IPODELAYDAYS		int,
				IMP_APPLICANTDELAYDAYS		int,
				IMP_TOTALADJUSTMENTDAYS		int,
				-- Snapshot of all compared values loaded to avoid concurrency problems
				EX_CASEKEY			int,
				EX_CASEREFERENCE		nvarchar(30)	collate database_default,
				EX_SHORTTITLE			nvarchar(254)	collate database_default,
				EX_LOCALCLASSES			nvarchar(254)	collate database_default,
				EX_INTCLASSES			nvarchar(254)	collate database_default,
				EX_IPODELAYDAYS			int,
				EX_APPLICANTDELAYDAYS		int,
				EX_TOTALADJUSTMENTDAYS		int,
				-- Processing information
				CASEREFERENCEMATCH		tinyint		default 1, -- MatchDifferent
				SHORTTITLEMATCH			tinyint		default 1,  -- MatchDifferent
				LOCALCLASSMATCH			tinyint		default 1,  -- MatchDifferent
				INTCLASSMATCH			tinyint		default 1,  -- MatchDifferent
				IPODELAYMATCH			tinyint		default 1,  -- MatchDifferent
				APPLICANTDELAYMATCH		tinyint		default 1,  -- MatchDifferent
				TOTALADJUSTMENTMATCH		tinyint		default 1,  -- MatchDifferent
				SHORTTITLEUPDATE		tinyint		default 0,
				IPODELAYUPDATE			tinyint		default 0,  
				APPLICANTDELAYUPDATE		tinyint		default 0,  
				TOTALADJUSTMENTUPDATE		tinyint		default 0,  
				-- Proposed changes
				PR_SHORTTITLE			nvarchar(254)	collate database_default,
				PR_IPODELAYDAYS			int,
				PR_APPLICANTDELAYDAYS		int,
				PR_TOTALADJUSTMENTDAYS		int

		)"
		/** Implementation postponed
				-- Message describing proposed changes, expressed in <Alert> XML format
				SHORTTITLEUPDATEALERT		nvarchar(2000)
		**/
	End

	exec @nErrorCode = sp_executesql @sSQLString
End

-- Official Numbers
-- TO DO: Still need to work out how to relate data for a single case.  CaseKey won't work for new cases.
If @nErrorCode = 0
Begin
	If exists(select * from dbo.sysobjects where name = @sOfficialNumberTable )
	Begin
		Set @sSQLString = "delete from "+@sOfficialNumberTable
	End
	Else
	Begin
		Set @sSQLString = "
		Create table "+@sOfficialNumberTable+"(
				-- Unique identifier to allow synchronisation of imported/existing/proposed information
				SYNCHID				int		identity(1,1),
				-- Imported Data
				IMP_CASESEQUENCE		int,
				IMP_NUMBERTYPECODE		nvarchar(50)	collate database_default,
				IMP_NUMBERTYPEDESCRIPTION	nvarchar(100)	collate database_default,
				IMP_NUMBERTYPEENCODING		nvarchar(50)	collate database_default,
				IMP_OFFICIALNUMBER		nvarchar(100)	collate database_default,
				IMP_EVENTDATE			datetime,
				-- Mapped data
				MAP_NUMBERTYPEKEY		nvarchar(3)	collate database_default,
				-- Snapshot of all compared values loaded to avoid concurrency problems
				EX_CASEKEY			int,
				EX_NUMBERTYPEKEY		nvarchar(3)	collate database_default,
				EX_OFFICIALNUMBER		nvarchar(36)	collate database_default,
				EX_ISCURRENT			dec(1,0),
				EX_EVENTKEY			int,
				EX_EVENTDATE			datetime,
				-- Processing information
				OFFICIALNUMBERMATCH		tinyint		default 0, -- MatchAbsent
				EVENTDATEMATCH			tinyint		default 0,  -- MatchAbsent
				OFFICIALNUMBERUPDATE		tinyint		default 0,
				EVENTDATEUPDATE			tinyint		default 0, 
				-- Proposed changes
				PR_OFFICIALNUMBER		nvarchar(36)	collate database_default,
				PR_EVENTDATE			datetime,
				PR_ISCURRENT			dec(1,0)
				)"
		/** Implementation postponed
				ROWUPDATE			tinyint		default 0,
				-- Message describing proposed changes, expressed in <Alert> XML format
				ROWUPDATEALERT			nvarchar(2000)
		**/
	End

	exec @nErrorCode = sp_executesql @sSQLString
End

-- Related Cases
-- TO DO: Still need to work out how to relate data for a single case.  CaseKey won't work for new cases.
If @nErrorCode = 0
Begin
	If exists(select * from dbo.sysobjects where name = @sRelatedCaseTable )
	Begin
		Set @sSQLString = "delete from "+@sRelatedCaseTable
	End
	Else
	Begin
		Set @sSQLString = "
		Create table "+@sRelatedCaseTable+" (
			-- Unique identifier to allow synchronisation of imported/existing/proposed information
			SYNCHID				int		identity(1,1),
			-- Imported Data
			IMP_SEQUENCENUMBER 		int,		-- The order in which relationships on the USPTO/PAIR web site are displayed 
			IMP_CASESEQUENCE		int,
			IMP_RELATIONSHIPCODE		nvarchar(50)	collate database_default,
			IMP_RELATIONSHIPDESCRIPTION	nvarchar(100)	collate database_default,
			IMP_RELATIONSHIPENCODING	nvarchar(50)	collate database_default,
			IMP_COUNTRYCODE			nvarchar(50)	collate database_default,
			IMP_COUNTRYNAME			nvarchar(100)	collate database_default,
			IMP_OFFICIALNUMBER		nvarchar(100)	collate database_default,
			IMP_EVENTDATE			datetime,
			IMP_PARENTSTATUS		nvarchar(100)	collate database_default,
			IMP_REGISTRATIONNUMBER		nvarchar(100)	collate database_default,
			-- Mapped data
			MAP_RELATIONSHIPKEY		nvarchar(3)	collate database_default,
			MAP_COUNTRYKEY			nvarchar(3)	collate database_default,
			MAP_EVENTKEY			int,
			-- Snapshot of all compared values loaded to avoid concurrency problems
			EX_CASEKEY			int,
			EX_RELATIONSHIPNO		int,
			EX_RELATIONSHIPKEY		nvarchar(3)	collate database_default,
			EX_RELATEDCASEKEY		int,
			EX_COUNTRYKEY			nvarchar(3)	collate database_default,
			EX_OFFICIALNUMBER		nvarchar(36)	collate database_default,
			EX_EVENTKEY			int,
			EX_EVENTDATE			datetime,
			-- Processing information
			OFFICIALNUMBERMATCH		tinyint		default 0, -- MatchAbsent
			RELATIONSHIPMATCH		tinyint		default 0, -- MatchAbsent
			EVENTDATEMATCH			tinyint		default 0  -- MatchAbsent
			)"
		/** Implementation postponed
			-- Proposed changes
			PR_RELATEDCASEKEY		int,
			PR_COUNTRYKEY			nvarchar(3)	collate database_default,
			PR_OFFICIALNUMBER		nvarchar(36)	collate database_default,
			PR_EVENTDATE			datetime,
			ROWUPDATE			tinyint		default 0,
			-- Message describing proposed changes, expressed in <Alert> XML format
			ROWUPDATEALERT			nvarchar(2000)
		**/
	End

	exec @nErrorCode = sp_executesql @sSQLString
End

-- CaseEvent
If @nErrorCode = 0
Begin
	If exists(select * from dbo.sysobjects where name = @sEventTable )
	Begin
		Set @sSQLString = "delete from "+@sEventTable
	End
	Else
	Begin
		Set @sSQLString = "
		Create table "+@sEventTable+" (
				-- Unique identifier to allow synchronisation of imported/existing/proposed information
				SYNCHID				int		identity(1,1),
				-- Imported data
				IMP_CASESEQUENCE		int,
				IMP_EVENTDESCRIPTION		nvarchar(254)	collate database_default,
				IMP_CYCLE			smallint,
				IMP_EVENTDATE			datetime,
				-- Mapped data
				MAP_EVENTKEY			int,
				-- Snapshot of all compared values loaded to avoid concurrency problems
				EX_CASEKEY			int,
				EX_EVENTKEY			int,
				EX_CYCLE			smallint,
				EX_EVENTDATE			datetime,
				-- Processing information
				EVENTDATEMATCH			tinyint		default 0, -- MatchAbsent
				EVENTDATEUPDATE			tinyint		default 0,
				-- Proposed data
				PR_CYCLE			smallint,
				PR_EVENTDATE			datetime
		)"
	End

	exec @nErrorCode = sp_executesql @sSQLString
End

-- CaseName
If @nErrorCode = 0
Begin
	If exists(select * from dbo.sysobjects where name = @sCaseNameTable )
	Begin
		Set @sSQLString = "delete from "+@sCaseNameTable
	End
	Else
	Begin
		Set @sSQLString = "
		Create table "+@sCaseNameTable+" (
				-- Unique identifier to allow synchronisation of imported/existing/proposed information
				SYNCHID				int		identity(1,1),
				-- Imported data
				IMP_CASESEQUENCE		int,
				IMP_NAMETYPECODE		nvarchar(3)	collate database_default,
				IMP_NAMETYPEDESCRIPTION		nvarchar(100)	collate database_default,
				IMP_NAMETYPEENCODING		nvarchar(50)	collate database_default,
				IMP_NAME			nvarchar(500)	collate database_default,
				IMP_FIRSTNAME			nvarchar(254)	collate database_default,					-- Mapped data
				IMP_ISINDIVIDUAL		bit,
				IMP_STREET			nvarchar(500)	collate database_default,
				IMP_CITY			nvarchar(30)	collate database_default,
				IMP_STATECODE			nvarchar(30)	collate database_default,
				IMP_STATENAME			nvarchar(40)	collate database_default,
				IMP_POSTCODE			nvarchar(10)	collate database_default,
				IMP_COUNTRYCODE			nvarchar(50)	collate database_default,
				IMP_COUNTRYNAME			nvarchar(100)	collate database_default,
				IMP_PHONE			nvarchar(50)	collate database_default,
				IMP_FAX				nvarchar(50)	collate database_default,
				IMP_EMAIL			nvarchar(50)	collate database_default,
				-- Mapped data
				MAP_NAMETYPEKEY			nvarchar(3)	collate database_default,
				MAP_COUNTRYKEY			nvarchar(3)	collate database_default,
				-- Snapshot of all compared values loaded to avoid concurrency problems
				EX_CASEKEY			int,
				EX_NAMETYPEKEY			nvarchar(3)	collate database_default,
				EX_NAMEKEY			int,
				EX_SEQUENCENO			smallint,
				EX_NAME				nvarchar(254)	collate database_default,
				EX_FIRSTNAME			nvarchar(50)	collate database_default,					-- Mapped data
				-- Processing information
				NAMEMATCH			tinyint		default 0 -- MatchAbsent
			)"
	End

	exec @nErrorCode = sp_executesql @sSQLString
End

Return @nErrorCode
GO

Grant execute on dbo.de_CaseComparisonCreate to public
GO
