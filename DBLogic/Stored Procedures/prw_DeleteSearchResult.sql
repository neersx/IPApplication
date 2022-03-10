-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_DeleteSearchResult
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_DeleteSearchResult]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_DeleteSearchResult.'
	Drop procedure [dbo].[prw_DeleteSearchResult]
End
Print '**** Creating Stored Procedure dbo.prw_DeleteSearchResult...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.prw_DeleteSearchResult
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnPriorArtKey		int,
	@pdtLastModifiedDate	datetime = null
)
as
-- PROCEDURE:	prw_DeleteSearchResult
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete a Search Result

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
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

	Set @sSQLString = "Delete from SEARCHRESULTS
		where	PRIORARTID = @pnPriorArtKey
		and	LOGDATETIMESTAMP	= @pdtLastModifiedDate"

	exec @nErrorCode=sp_executesql @sSQLString,
	      		N'
		@pnPriorArtKey			int,
		@pdtLastModifiedDate	datetime',
		@pnPriorArtKey		= @pnPriorArtKey,
		@pdtLastModifiedDate	= @pdtLastModifiedDate

End

Return @nErrorCode
GO

Grant execute on dbo.prw_DeleteSearchResult to public
GO