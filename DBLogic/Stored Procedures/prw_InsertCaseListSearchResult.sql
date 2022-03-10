-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_InsertCaseListSearchResult
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_InsertCaseListSearchResult]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_InsertCaseListSearchResult.'
	Drop procedure [dbo].[prw_InsertCaseListSearchResult]
End
Print '**** Creating Stored Procedure dbo.prw_InsertCaseListSearchResult...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.prw_InsertCaseListSearchResult
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnPriorArtKey		int,
	@pnCaseListKey		int,
	@pdtLastModifiedDate	datetime	= null	OUTPUT
)
as
-- PROCEDURE:	prw_InsertCaseListSearchResult
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert a Case List Search Result

-- MODIFICATIONS :
-- Date		Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 2 Mar 2011	JC		RFC6563	1		Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin

	Set @sSQLString = "Insert into CASELISTSEARCHRESULT
			(PRIORARTID,
			 CASELISTNO)
		values (
			@pnPriorArtKey,
			@pnCaseListKey)

		Select	@pdtLastModifiedDate = LOGDATETIMESTAMP
		from	CASELISTSEARCHRESULT
		where	PRIORARTID	= @pnPriorArtKey
		and	CASELISTNO	= @pnCaseListKey
		"

	exec @nErrorCode=sp_executesql @sSQLString,
	      		N'
		@pnPriorArtKey		int,
		@pnCaseListKey		int,
		@pdtLastModifiedDate	datetime output',
		@pnPriorArtKey		= @pnPriorArtKey,
		@pnCaseListKey		= @pnCaseListKey,
		@pdtLastModifiedDate	= @pdtLastModifiedDate output

	Select @pdtLastModifiedDate		as LastModifiedDate
End

Return @nErrorCode
GO

Grant execute on dbo.prw_InsertCaseListSearchResult to public
GO