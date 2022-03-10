-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_UpdateCaseSearchResult
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_UpdateCaseSearchResult]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_UpdateCaseSearchResult.'
	Drop procedure [dbo].[prw_UpdateCaseSearchResult]
End
Print '**** Creating Stored Procedure dbo.prw_UpdateCaseSearchResult...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.prw_UpdateCaseSearchResult
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnPriorArtKey		int,
	@pnCaseKey		int,
	@pnStatusKey		int		= null,
	@pbCaseFirstLinkedTo	bit		= 0,
	@pdtLastModifiedDate	datetime	= null

)
as
-- PROCEDURE:	prw_UpdateCaseSearchResult
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update a Case Search Result

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 2 Mar 2011	JC	RFC6563	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 	nvarchar(4000)
Declare @dToday			datetime

-- Initialise variables
Set @nErrorCode = 0
Set @dToday = getDate()

If @nErrorCode = 0
Begin

	Set @sSQLString = "UPDATE CASESEARCHRESULT
		set STATUS		= @pnStatusKey,
		    CASEFIRSTLINKEDTO	= CASE WHEN FAMILYPRIORARTID IS NULL AND CASELISTPRIORARTID IS NULL
						AND NAMEPRIORARTID IS NULL AND isnull(ISCASERELATIONSHIP,0) = 0
					THEN @pbCaseFirstLinkedTo ELSE CASEFIRSTLINKEDTO END,
		    UPDATEDDATE		= @dToday
		where	PRIORARTID	= @pnPriorArtKey
		and	CASEID		= @pnCaseKey
			"

	exec @nErrorCode=sp_executesql @sSQLString,
	      		N'
		@pnPriorArtKey		int,
		@pnCaseKey		int,
		@pnStatusKey		int,
		@pbCaseFirstLinkedTo	bit,
		@dToday			datetime',
		@pnPriorArtKey		= @pnPriorArtKey,
		@pnCaseKey		= @pnCaseKey,
		@pnStatusKey		= @pnStatusKey,
		@pbCaseFirstLinkedTo	= @pbCaseFirstLinkedTo,
		@dToday			= @dToday

End

Return @nErrorCode
GO

Grant execute on dbo.prw_UpdateCaseSearchResult to public
GO