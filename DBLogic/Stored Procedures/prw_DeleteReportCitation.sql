-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_DeleteReportCitation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_DeleteReportCitation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_DeleteReportCitation.'
	Drop procedure [dbo].[prw_DeleteReportCitation]
End
Print '**** Creating Stored Procedure dbo.prw_DeleteReportCitation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.prw_DeleteReportCitation
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnSearchReportKey	int,
	@pnCitedPriorArtKey	int,
	@pdtLastModifiedDate	datetime = null
)
as
-- PROCEDURE:	prw_DeleteReportCitation
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete a Report Citation

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

	Set @sSQLString = "Delete from REPORTCITATIONS
		where	SEARCHREPORTID		= @pnSearchReportKey
		and	CITEDPRIORARTID		= @pnCitedPriorArtKey
		and	LOGDATETIMESTAMP	= @pdtLastModifiedDate"

	exec @nErrorCode=sp_executesql @sSQLString,
	      		N'
		@pnSearchReportKey	int,
		@pnCitedPriorArtKey	int,
		@pdtLastModifiedDate	datetime',
		@pnSearchReportKey	= @pnSearchReportKey,
		@pnCitedPriorArtKey	= @pnCitedPriorArtKey,
		@pdtLastModifiedDate	= @pdtLastModifiedDate

End

Return @nErrorCode
GO

Grant execute on dbo.prw_DeleteReportCitation to public
GO