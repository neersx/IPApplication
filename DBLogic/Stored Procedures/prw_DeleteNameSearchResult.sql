-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_DeleteNameSearchResult
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_DeleteNameSearchResult]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_DeleteNameSearchResult.'
	Drop procedure [dbo].[prw_DeleteNameSearchResult]
End
Print '**** Creating Stored Procedure dbo.prw_DeleteNameSearchResult...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.prw_DeleteNameSearchResult
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnPriorArtKey		int,
	@pnNameKey		int,
	@pdtLastModifiedDate	datetime = null
)
as
-- PROCEDURE:	prw_DeleteNameSearchResult
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete a Name Search Result

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

	Set @sSQLString = "Delete from NAMESEARCHRESULT
		where	PRIORARTID = @pnPriorArtKey
		and	NAMENO = @pnNameKey
		and	LOGDATETIMESTAMP	= @pdtLastModifiedDate"

	exec @nErrorCode=sp_executesql @sSQLString,
	      		N'
		@pnPriorArtKey		int,
		@pnNameKey		int,
		@pdtLastModifiedDate	datetime',
		@pnPriorArtKey		= @pnPriorArtKey,
		@pnNameKey		= @pnNameKey,
		@pdtLastModifiedDate	= @pdtLastModifiedDate

End

Return @nErrorCode
GO

Grant execute on dbo.prw_DeleteNameSearchResult to public
GO