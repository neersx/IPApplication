-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_DeleteFamilySearchResult
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_DeleteFamilySearchResult]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_DeleteFamilySearchResult.'
	Drop procedure [dbo].[prw_DeleteFamilySearchResult]
End
Print '**** Creating Stored Procedure dbo.prw_DeleteFamilySearchResult...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.prw_DeleteFamilySearchResult
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnPriorArtKey		int,
	@psFamilyCode		nvarchar(20),
	@pdtLastModifiedDate	datetime = null
)
as
-- PROCEDURE:	prw_DeleteFamilySearchResult
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete a Family Search Result

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 2 Mar 2011	JC	RFC6563	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin

	Set @sSQLString = "Delete from FAMILYSEARCHRESULT
		where	PRIORARTID		= @pnPriorArtKey
		and	FAMILY			= @psFamilyCode
		and	LOGDATETIMESTAMP	= @pdtLastModifiedDate"

	exec @nErrorCode=sp_executesql @sSQLString,
	      		N'
		@pnPriorArtKey		int,
		@psFamilyCode		nvarchar(30),
		@pdtLastModifiedDate	datetime',
		@pnPriorArtKey		= @pnPriorArtKey,
		@psFamilyCode		= @psFamilyCode,
		@pdtLastModifiedDate	= @pdtLastModifiedDate

End

Return @nErrorCode
GO

Grant execute on dbo.prw_DeleteFamilySearchResult to public
GO