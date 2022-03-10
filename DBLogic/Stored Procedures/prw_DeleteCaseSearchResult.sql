-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_DeleteCaseSearchResult
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_DeleteCaseSearchResult]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_DeleteCaseSearchResult.'
	Drop procedure [dbo].[prw_DeleteCaseSearchResult]
End
Print '**** Creating Stored Procedure dbo.prw_DeleteCaseSearchResult...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.prw_DeleteCaseSearchResult
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnPriorArtKey		int,
	@pnCaseKey		int,
	@pdtLastModifiedDate	datetime	= null

)
as
-- PROCEDURE:	prw_DeleteCaseSearchResult
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update a Case Search Result

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 2  Mar 2011	JC	RFC6563	1	Procedure created
-- 18 Apr 2018	DV	R46111	2	Allow deletion of Case even if it referenced by a relationship

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin

	Set @sSQLString = "DELETE CASESEARCHRESULT
		where	PRIORARTID	= @pnPriorArtKey
		and	CASEID		= @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
	      		N'
		@pnPriorArtKey		int,
		@pnCaseKey		int',
		@pnPriorArtKey		= @pnPriorArtKey,
		@pnCaseKey		= @pnCaseKey

End

Return @nErrorCode
GO

Grant execute on dbo.prw_DeleteCaseSearchResult to public
GO