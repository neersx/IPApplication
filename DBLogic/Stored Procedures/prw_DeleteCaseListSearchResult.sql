-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_DeleteCaseListSearchResult
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_DeleteCaseListSearchResult]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_DeleteCaseListSearchResult.'
	Drop procedure [dbo].[prw_DeleteCaseListSearchResult]
End
Print '**** Creating Stored Procedure dbo.prw_DeleteCaseListSearchResult...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.prw_DeleteCaseListSearchResult
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnPriorArtKey		int,
	@pnCaseListKey		int,
	@pdtLastModifiedDate	datetime = null
)
as
-- PROCEDURE:	prw_DeleteCaseListSearchResult
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete a Case List Search Result

-- MODIFICATIONS :
-- Date		Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 2 Mar 2011	JC		RFC6563	1		Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin

	Set @sSQLString = "Delete from CASELISTSEARCHRESULT
		where	PRIORARTID = @pnPriorArtKey
		and	CASELISTNO = @pnCaseListKey
		and	LOGDATETIMESTAMP	= @pdtLastModifiedDate"

	exec @nErrorCode=sp_executesql @sSQLString,
	      		N'
		@pnPriorArtKey			int,
		@pnCaseListKey			int,
		@pdtLastModifiedDate	datetime',
		@pnPriorArtKey		= @pnPriorArtKey,
		@pnCaseListKey		= @pnCaseListKey,
		@pdtLastModifiedDate	= @pdtLastModifiedDate

End

Return @nErrorCode
GO

Grant execute on dbo.prw_DeleteCaseListSearchResult to public
GO