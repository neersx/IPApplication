-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateJournal									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateJournal]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateJournal.'
	Drop procedure [dbo].[csw_UpdateJournal]
End
Print '**** Creating Stored Procedure dbo.csw_UpdateJournal...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.csw_UpdateJournal
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory	
	@pnSequence			smallint,	-- Mandatory
	@psJournalNo			nvarchar(20),	-- Mandatory
	@pnJournalPage                  int             = null,
	@pdJournalDate                  datetime        = null,	
	@pdtLastModifiedDate		datetime	= null
)
as
-- PROCEDURE:	csw_UpdateJournal
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update Journal if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 24 Sep 2010	MS	RFC9759	1	Procedure created
-- 22 Feb 2012  MS      R11186  2       Added @pdtLastModifiedDate

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin

	Set @sSQLString = "Update JOURNAL
                set JOURNALNO = @psJournalNo,
		 JOURNALPAGE = @pnJournalPage,
		 JOURNALDATE = @pdJournalDate
	        Where CASEID = @pnCaseKey and
		SEQUENCE = @pnSequence and
		(LOGDATETIMESTAMP = @pdtLastModifiedDate or 
		(LOGDATETIMESTAMP is null and @pdtLastModifiedDate is null))"

	exec @nErrorCode=sp_executesql @sSQLString,
		      N'@pnCaseKey			int,
		        @pnSequence                     smallint,
			@psJournalNo			nvarchar(20),
			@pnJournalPage			int,
			@pdJournalDate		        datetime,
			@pdtLastModifiedDate		datetime',
			@pnCaseKey	 		= @pnCaseKey,
			@pnSequence                     = @pnSequence,
			@psJournalNo	 		= @psJournalNo,
			@pnJournalPage	 		= @pnJournalPage,
			@pdJournalDate	 	        = @pdJournalDate,
			@pdtLastModifiedDate		= @pdtLastModifiedDate			
End

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateJournal to public
GO