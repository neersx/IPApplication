-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_DeleteJournal									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_DeleteJournal]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_DeleteJournal.'
	Drop procedure [dbo].[csw_DeleteJournal]
End
Print '**** Creating Stored Procedure dbo.csw_DeleteJournal...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_DeleteJournal
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory
	@pnSequence			smallint,	-- Mandatory
	@pdtLastModifiedDate            datetime        = null        
)
as
-- PROCEDURE:	csw_DeleteJournal
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete Journal if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 30 Sep 2010	MS	RFC9759	1	Procedure created
-- 23 Jan 2012  MS      R11186  2       Modified to add @LastModifiedDate

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sDeleteString		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from JOURNAL
			   where CASEID = @pnCaseKey and
		           SEQUENCE = @pnSequence and
		           (LOGDATETIMESTAMP = @pdtLastModifiedDate or 
		           (LOGDATETIMESTAMP is null and @pdtLastModifiedDate is null))"

	exec @nErrorCode=sp_executesql @sDeleteString,
		      N'@pnCaseKey			int,
		        @pnSequence                     smallint,
			@pdtLastModifiedDate		datetime',
			@pnCaseKey	 		= @pnCaseKey,
			@pnSequence                     = @pnSequence,
			@pdtLastModifiedDate	 	= @pdtLastModifiedDate
End

Return @nErrorCode
GO

Grant execute on dbo.csw_DeleteJournal to public
GO

