-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertJournal
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertJournal]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_InsertJournal.'
	Drop procedure [dbo].[csw_InsertJournal]
End
Print '**** Creating Stored Procedure dbo.csw_InsertJournal...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_InsertJournal
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,	
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory	
	@psJournalNumber		nvarchar(20),	-- Mandatory	
	@pnJournalPage		        int             = null,	
	@pdJournalDate			datetime	= null,
	@pnSequence                     smallint        = null output,
	@pdtLastModifiedDate		datetime	= null output,
	@psRowKey			nvarchar(50)	= null output
)
as
-- PROCEDURE:	csw_InsertJournal
-- VERSION:	2
-- DESCRIPTION:	Insert new Journal.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24 Sep 2010	MS	RFC9759	1	Procedure created
-- 22 Feb 2011  MS      R11186  2       Removed InUse parameters

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	        int
declare @sSQLString 	        nvarchar(4000)
Declare @nSequence              smallint

-- Initialise variables
Set @nErrorCode = 0
Set @nSequence = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select @nSequence = MAX(SEQUENCE) + 1 
			from JOURNAL
			where CASEID = @pnCaseKey"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@nSequence	smallint        output,
				@pnCaseKey	int',
				@nSequence	= @nSequence	output,
				@pnCaseKey	= @pnCaseKey
End

If @nErrorCode = 0 and @nSequence is null
Begin
        Set @nSequence = 0
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "Insert into JOURNAL (CASEID, SEQUENCE, JOURNALNO, JOURNALPAGE, JOURNALDATE)
			   values (@pnCaseKey, @nSequence, @psJournalNumber, @pnJournalPage, @pdJournalDate)
			   
	Select	@pdtLastModifiedDate = LOGDATETIMESTAMP,
		@psRowKey = CAST(CASEID as nvarchar(11))+'^'+ CAST(SEQUENCE as nvarchar(10)),
		@pnSequence = @nSequence
	from	JOURNAL
	where	CASEID			= @pnCaseKey
	and	SEQUENCE		= @nSequence"
				
	exec @nErrorCode=sp_executesql @sSQLString,
		      N'@pdtLastModifiedDate	datetime                output,
			@psRowKey		nvarchar(50)            output,
			@pnSequence             smallint                output,
		        @pnCaseKey		int,
		        @nSequence              smallint,
			@psJournalNumber	nvarchar(20),
			@pnJournalPage		int,
			@pdJournalDate	        datetime',
			@pdtLastModifiedDate	= @pdtLastModifiedDate  output,
			@psRowKey		= @psRowKey             output,
			@pnSequence             = @pnSequence           output,
			@pnCaseKey	 	= @pnCaseKey,
			@nSequence              = @nSequence,
			@psJournalNumber	= @psJournalNumber,
			@pnJournalPage	 	= @pnJournalPage,
			@pdJournalDate	        = @pdJournalDate
End

Return @nErrorCode
GO

Grant execute on dbo.csw_InsertJournal to public
GO