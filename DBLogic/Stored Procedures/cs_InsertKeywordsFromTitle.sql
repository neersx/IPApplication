-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_InsertKeyWordsFromTitle
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_InsertKeyWordsFromTitle]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_InsertKeyWordsFromTitle.'
	drop procedure dbo.cs_InsertKeyWordsFromTitle
	print '**** Creating Stored Procedure dbo.cs_InsertKeyWordsFromTitle...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

create procedure dbo.cs_InsertKeyWordsFromTitle 
	@nCaseId		int 	= NULL,	-- Caseid for 1 case
	@pbCasesWithNoIRN	bit 	=0,	-- Set to 1 when all cases with no IRN are to be processed
	@pbCaseFromTempTable	bit	=0,	-- Process the cases in #TEMPCASES
	@pbDebug		bit	=0	-- Debug flag
as
-- PROCEDURE :	cs_InsertKeyWordsFromTitle
-- VERSION :	16
-- DESCRIPTION:	Combinations of alphanumeric characters separated by a single space are
--		stripped out of the Case TITLE as KEYWORDS and linked to the cases.
-- CALLED BY :	

-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 24/06/2001	MF			Procedure created
-- 03/08/2001	MF			Go back to using a temporary table however change the code that replaces 2 spaces
--					with a single space to first convert all spaces to a tilde "~" and then replace
--					all occurrences of 2 tildes with a single tilde.  Finally replace the remaining
--					single tilde with a space.
-- 29/07/2002	MF			If the keywords for a specific Case are being generated then delete the existing
--					CASEWORDS rows for that Case first.
--					Replace temporary table with a Table Variable and get rid of Cursors.
-- 06/12/2002	JB		5 	Replaced @nCaseid with @nCaseId
-- 10/02/2004	MF		6	Problems in handling extended character set such as with European characters and also 
--					problem with accent insensitive database collations.  Also ignore words that have 
--					been marked as a Stop Word for both Cases and Names.
-- 24 May 2004	MF	9034	7	A new input parameter to indicate that all Cases that are missing an IRN
--					are to be processed.  This is useful for bulk processing of Cases being loaded
--					from the Import Journal.
-- 20 Dec 2004	RTS/RCT	RFC2182	8	Prevent looping error caused by mismatched TITLE length declarations
-- 19 Dec 2005	TM	RFC3258	9	Replace with spaces non alphanumeric characters which are in the ASCII range 
--					0 to 127 in keywords which are not stop words.
-- 28 May 2007	MF	14825	10	Provide a flag to indicate that the Cases to be processed are listed
--					in the temporary table #TEMPCASES.
-- 19 Dec 2007	MF	15760	11	When the @pbCaseWithNoIRN option is on then process Cases where the IRN is null
--					or where it is set to '<Generate Reference>'
-- 14 Feb 2008	MF	15732	12	Keep the lock on the LASTINTERNALCODE table as short as possible
-- 07 Jul 2011	DL	R10830	13	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 29 Nov 2013	MF	R29061	14	Cater for double byte characters.
-- 03 Dec 2013 AvB	R29305	15	Rewrite to use set-based approach to improve performance on large datasets.
-- 20 Sep 2016	MF	68831	16	Revisit of RFC 29305 which was incorrectly always updating the LASTINTERNALCODE table to the 
--					maximum value held in KEYWORDS. This was causing problems in a replicated database where different
--					number ranges were in use.
SET NOCOUNT ON

CREATE TABLE #TEMPCASEWORD( 
	CASEID		int		NOT NULL,
	KEYWORD		nvarchar(50)	COLLATE database_default NULL,
	KEYWORDNO	int		NULL,
	STOPWORD	decimal(1,0)	NULL
	)

CREATE TABLE #TEMPNEWKEYWORD(
	KEYWORDNO	int		NULL,
	KEYWORD		nvarchar(50)	COLLATE database_default NULL
	)

DECLARE @nErrorCode     int,
	@nTranCount	int,
	@nRowCount      int,
	@nLastKeyWordNo int,
	@sTitle         nvarchar (254),
	@bUseCursor     bit

set @bUseCursor = 0
set @nErrorCode	=0


-----------------------------------------------------
-- Ensure LASTINTERNALCODE for tracking the next
-- KEYWORDNO is available and accurate.
-----------------------------------------------------
Set @nTranCount = @@TranCount
BEGIN TRANSACTION

IF NOT EXISTS (SELECT 1 FROM [dbo].[LASTINTERNALCODE] WHERE [TABLENAME] = N'KEYWORDS')
Begin
	INSERT INTO LASTINTERNALCODE (TABLENAME,INTERNALSEQUENCE) VALUES( N'KEYWORDS',	0)
	
	Set @nErrorCode=@@Error

	If @nErrorCode=0
	Begin
		UPDATE LASTINTERNALCODE
		SET INTERNALSEQUENCE = ISNULL ((SELECT MAX (KEYWORDNO)
						FROM KEYWORDS), 0)
		WHERE TABLENAME = N'KEYWORDS'
		
		Set @nErrorCode=@@Error
	End
End

-- Commit or Rollback the transaction

If @@TranCount > @nTranCount	
Begin
	If @nErrorCode = 0
		COMMIT TRANSACTION
	Else
		ROLLBACK TRANSACTION
End

-----------------------------------------------------
-- Cases with IRN = <Generate Reference> -> new cases
-----------------------------------------------------
IF  @pbCasesWithNoIRN = 1
and @nErrorCode=0
BEGIN
	DECLARE [CaseToProcessCursor] CURSOR FOR
		SELECT CASEID, LTRIM(RTRIM(UPPER(TITLE))) AS TITLE
		FROM CASES
		WHERE TITLE IS NOT NULL 
		AND (IRN IS NULL OR IRN = N'<Generate Reference>')

	SET @nErrorCode = @@ERROR
	SET @bUseCursor = 1
END
-----------------------------------------------------
-- List of cases from temp table #TEMPCASES 
-----------------------------------------------------
ELSE IF @pbCaseFromTempTable = 1
    and @nErrorCode=0
BEGIN
	DECLARE [CaseToProcessCursor] CURSOR FOR
		SELECT C.CASEID, LTRIM(RTRIM(UPPER(C.TITLE))) AS TITLE
		FROM CASES C
		JOIN #TEMPCASES T ON (T.CASEID = C.CASEID)
		WHERE C.TITLE IS NOT NULL

	SET @nErrorCode = @@ERROR
	SET @bUseCursor = 1
END
-----------------------------------------------------
-- @nCaseId IS NULL -> cases which have a title
-----------------------------------------------------
ELSE IF @nCaseId IS NULL
    and @nErrorCode=0
BEGIN
	DECLARE [CaseToProcessCursor] CURSOR FOR
		SELECT CASEID, LTRIM(RTRIM(UPPER(TITLE))) AS TITLE
		FROM CASES
		WHERE TITLE IS NOT NULL

	SET @nErrorCode = @@ERROR
	SET @bUseCursor = 1
END
-----------------------------------------------------
-- @nCaseId IS NOT NULL -> 1 specific case only
-----------------------------------------------------
ELSE IF @nCaseId is not null
    and @nErrorCode=0 
BEGIN
	SELECT @sTitle = LTRIM(RTRIM(TITLE))
	FROM CASES
	WHERE CASEID = @nCaseId

	SET @nErrorCode = @@ERROR

	If @nErrorCode=0
	Begin
		INSERT INTO #TEMPCASEWORD (CASEID, KEYWORD)
		SELECT DISTINCT CASEID, SUBSTRING (UPPER(Word), 1, 50) AS KEYWORD
		FROM dbo.fn_ParseTITLE (@nCaseId, @sTitle)

		SET @nErrorCode = @@ERROR
		SET @bUseCursor = 0
	End
END

-----------------------------------------------------
-- If a cursor has been opened then fetch the next
-- rows until all rows are processed.
-----------------------------------------------------
IF  @bUseCursor = 1
and @nErrorCode=0
BEGIN
	OPEN [CaseToProcessCursor]

	FETCH NEXT FROM [CaseToProcessCursor]
	INTO @nCaseId,
	     @sTitle
	     
	SET @nErrorCode = @@ERROR

	WHILE @@FETCH_STATUS = 0
	  and @nErrorCode=0
	BEGIN
		INSERT INTO #TEMPCASEWORD (CASEID, KEYWORD)
		SELECT DISTINCT CASEID, SUBSTRING(UPPER(Word), 1, 50) AS KEYWORD
		FROM dbo.fn_ParseTITLE (@nCaseId, @sTitle)
	     
		SET @nErrorCode = @@ERROR

		If @nErrorCode=0
		Begin
			FETCH NEXT FROM [CaseToProcessCursor]
			INTO @nCaseId,
			     @sTitle
	     
			SET @nErrorCode = @@ERROR
		End

	END -- while @@FETCH_STATUS = 0

	CLOSE [CaseToProcessCursor]
	DEALLOCATE [CaseToProcessCursor]

END -- if: @bUseCursor = 1

-----------------------------------------------------
-- Create index on #TEMPCASEWORD
-----------------------------------------------------

If @nErrorCode=0
Begin
	CREATE CLUSTERED INDEX [XIE_TEMPCASEWORD_TEMP01_MAIN]
	ON #TEMPCASEWORD(CASEID, KEYWORD, KEYWORDNO, STOPWORD)
	
	SET @nErrorCode = @@ERROR
End

IF  @pbDebug = 1
BEGIN
	PRINT N'#TEMPCASEWORD: After initial population'
	SELECT * FROM #TEMPCASEWORD
END

-----------------------------------------------------
-- Delete any existing CASEWORDS rows that were
-- created from the TITLE of the Case
-----------------------------------------------------
If @nErrorCode=0
Begin
	DELETE C
	FROM CASEWORDS C
	JOIN #TEMPCASEWORD T ON (T.CASEID = C.CASEID)

	Select	@nRowCount  = @@ROWCOUNT,
		@nErrorCode = @@ERROR

	IF  @pbDebug = 1
	and @nErrorCode=0
		SELECT @nRowCount AS [Number of rows deleted from CASEWORDS]
End

-----------------------------------------------------
-- Any extracted words that already exist as a 
-- keyword are to have the KEYWORDNO assigned.
-----------------------------------------------------
If @nErrorCode=0
Begin
	UPDATE T
	SET KEYWORDNO=K.KEYWORDNO,
	    STOPWORD =K.STOPWORD
	FROM #TEMPCASEWORD T
	JOIN KEYWORDS K ON (T.KEYWORD = K.KEYWORD COLLATE database_default)

	Set @nErrorCode = @@ERROR

	IF  @pbDebug = 1
	and @nErrorCode=0
	BEGIN
		PRINT N'#TEMPCASEWORD: After populating KEYWORDNO and STOPWORD'
		SELECT * FROM #TEMPCASEWORD
	END
End

-----------------------------------------------------
-- Get the last KEYWORDNO that has been allocated.
-----------------------------------------------------
If @nErrorCode=0
Begin
	SELECT @nLastKeyWordNo = INTERNALSEQUENCE
	FROM LASTINTERNALCODE
	WHERE TABLENAME = N'KEYWORDS'

	Set @nErrorCode = @@ERROR
End

-----------------------------------------------------
-- Assign the next available unique KEYWORDNO to each
-- unique KEYWORD that does not yet have a KEYWORDNO.
-----------------------------------------------------
If @nErrorCode=0
Begin
	INSERT INTO #TEMPNEWKEYWORD (KEYWORDNO, KEYWORD)
	SELECT ROW_NUMBER() OVER (ORDER BY KEYWORD) + @nLastKeyWordNo,
	      K.KEYWORD
	FROM (	SELECT DISTINCT KEYWORD
		FROM #TEMPCASEWORD
		WHERE KEYWORDNO IS NULL
		) K

	Set @nErrorCode = @@ERROR

	IF  @pbDebug = 1
	and @nErrorCode=0
	BEGIN
		PRINT N'#TEMPNEWKEYWORD: After initial population'
		SELECT * FROM #TEMPNEWKEYWORD
	END
End

-----------------------------------------------------
-- Need to update  the LASETINTERNALCODE with the
-- last KEYWORDNO used.
-----------------------------------------------------

Set @nTranCount = @@TranCount
BEGIN TRANSACTION

If @nErrorCode=0
Begin
	SELECT @nLastKeyWordNo = MAX (KEYWORDNO)
	FROM #TEMPNEWKEYWORD
	
	Set @nErrorCode = @@ERROR

	IF  @nLastKeyWordNo IS NOT NULL
	and @nErrorCode=0
	Begin
		UPDATE LASTINTERNALCODE
		SET INTERNALSEQUENCE = @nLastKeyWordNo
		WHERE TABLENAME = N'KEYWORDS'
	
		Set @nErrorCode = @@ERROR
	End
End

-----------------------------------------------------
-- Now load the newly created Keywords into database.
-----------------------------------------------------
If @nErrorCode=0
Begin
	INSERT INTO KEYWORDS (KEYWORDNO, KEYWORD, STOPWORD)
	SELECT KEYWORDNO, KEYWORD, 0
	FROM #TEMPNEWKEYWORD

	Select	@nRowCount  = @@ROWCOUNT,
		@nErrorCode = @@ERROR

	IF @pbDebug     = 1
	and @nErrorCode = 0
		SELECT @nRowCount AS [Number of new keywords inserted from #TEMPNEWKEYWORD into KEYWORDS]
End

-----------------------------------------------------
-- Update the newly generated CaseWords with KEYWORDNO
-----------------------------------------------------
If @nErrorCode=0
Begin

	UPDATE CW
	SET KEYWORDNO = K.KEYWORDNO,
	    STOPWORD  = 0
	FROM #TEMPCASEWORD CW
	JOIN #TEMPNEWKEYWORD K ON (CW.KEYWORD = K.KEYWORD COLLATE database_default)

	Select	@nRowCount  = @@ROWCOUNT,
		@nErrorCode = @@ERROR

	IF  @pbDebug    = 1
	and @nErrorCode = 0
	BEGIN
		PRINT N'#TEMPCASEWORD: After update of KEYWORDNO for newly inserted keywords'
		SELECT * FROM #TEMPCASEWORD
	END
End

-----------------------------------------------------
-- Insert the CASEWORDS just generated to link the 
-- CASES to the KEYWORDS
-----------------------------------------------------
If @nErrorCode=0
Begin
	INSERT INTO CASEWORDS (CASEID, KEYWORDNO, FROMTITLE)
	SELECT T.CASEID, T.KEYWORDNO, 1
	FROM #TEMPCASEWORD T
	LEFT JOIN CASEWORDS CW on (CW.CASEID=T.CASEID
			       and CW.KEYWORDNO=T.KEYWORDNO)
	WHERE T.STOPWORD NOT IN (1, 3)
	and CW.CASEID is null	-- Ensure the CASEWORD does not already exist
	
	Set @nErrorCode=@@ERROR
End

-- Commit or Rollback the transaction

If @@TranCount > @nTranCount	
Begin
	If @nErrorCode = 0
		COMMIT TRANSACTION
	Else
		ROLLBACK TRANSACTION
End

-----------------------------------------------------
-- Cleanup by removing temporary tables
-----------------------------------------------------
DROP TABLE #TEMPCASEWORD
DROP TABLE #TEMPNEWKEYWORD

return @nErrorCode
go

grant execute on dbo.cs_InsertKeyWordsFromTitle  to public
go