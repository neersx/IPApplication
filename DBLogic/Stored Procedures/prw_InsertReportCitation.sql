-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_InsertReportCitation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_InsertReportCitation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_InsertReportCitation.'
	Drop procedure [dbo].[prw_InsertReportCitation]
End
Print '**** Creating Stored Procedure dbo.prw_InsertReportCitation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.prw_InsertReportCitation
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnSearchReportKey	int,
	@pnCitedPriorArtKey	int,
	@pdtLastModifiedDate	datetime	= null	OUTPUT,
	@pbCheckIfExists	bit		= 0
)
as
-- PROCEDURE:	prw_InsertReportCitation
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert a Report Citation

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 2 Mar 2011	JC	RFC6563	1	Procedure created
-- 2 Mar 2011	JC	R11350	2	Add CheckIfExists

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode		= 0

If @nErrorCode = 0
and @pbCheckIfExists = 1
Begin

	Set @sSQLString = "
		Select	@pdtLastModifiedDate = LOGDATETIMESTAMP
		from	REPORTCITATIONS
		where	SEARCHREPORTID	= @pnSearchReportKey
		and	CITEDPRIORARTID	= @pnCitedPriorArtKey"

	exec @nErrorCode=sp_executesql @sSQLString,
	      		N'
		@pnSearchReportKey	int,
		@pnCitedPriorArtKey	int,
		@pdtLastModifiedDate	datetime output',
		@pnSearchReportKey	= @pnSearchReportKey,
		@pnCitedPriorArtKey	= @pnCitedPriorArtKey,
		@pdtLastModifiedDate	= @pdtLastModifiedDate OUTPUT

End

If @nErrorCode = 0
and @pdtLastModifiedDate is null
Begin

	Set @sSQLString = "Insert into REPORTCITATIONS
			(SEARCHREPORTID,
			 CITEDPRIORARTID)
		values (
			@pnSearchReportKey,
			@pnCitedPriorArtKey)
			
		Select	@pdtLastModifiedDate = LOGDATETIMESTAMP
		from	REPORTCITATIONS
		where	SEARCHREPORTID	= @pnSearchReportKey
		and	CITEDPRIORARTID	= @pnCitedPriorArtKey"

	exec @nErrorCode=sp_executesql @sSQLString,
	      		N'
		@pnSearchReportKey	int,
		@pnCitedPriorArtKey	int,
		@pdtLastModifiedDate	datetime output',
		@pnSearchReportKey	= @pnSearchReportKey,
		@pnCitedPriorArtKey	= @pnCitedPriorArtKey,
		@pdtLastModifiedDate	= @pdtLastModifiedDate OUTPUT

End

If @nErrorCode = 0
Begin
	Select @pdtLastModifiedDate as LastModifiedDate
End

Return @nErrorCode
GO

Grant execute on dbo.prw_InsertReportCitation to public
GO