-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_DeleteAssignedCases
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_DeleteAssignedCases]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_DeleteAssignedCases.'
	Drop procedure [dbo].[csw_DeleteAssignedCases]
End
Print '**** Creating Stored Procedure dbo.csw_DeleteAssignedCases...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_DeleteAssignedCases
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int,
	@pnRelationshipKey	int,
	@pdtLastModifiedDate	datetime	= null,
        @pnRelatedCaseKey       int             = null,
        @psRelationshipCode     nvarchar(3)     = null
)
as
-- PROCEDURE:	csw_DeleteAssignedCases
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Deletes a case assigned to an assignment recordal case.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 08 Aug 2011	KR	R7904	1	Procedure created
-- 29 Sep 2011	KR	R7904	2	LOGDATETIMESTAMP was not added.
-- 19 Sep 2017  MS      R72172  3       Delete Reverse Relationship Row for Related Case


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode	        int
Declare @sSQLString 	        nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0 and @pnRelatedCaseKey is not null
Begin
        exec @nErrorCode = dbo.csw_DeleteRelatedReciprocal
		        @pnUserIdentityId		= @pnUserIdentityId,
		        @psCulture			= @psCulture,
		        @pbCalledFromCentura		= 0,
		        @pnCaseKey			= @pnCaseKey,
		        @psRelationshipCode		= @psRelationshipCode,
		        @pnRelatedCaseKey		= @pnRelatedCaseKey
End

If @nErrorCode = 0
Begin

	Set @sSQLString = "DELETE RELATEDCASE
		where	CASEID		= @pnCaseKey
		and	RELATIONSHIPNO	= @pnRelationshipKey
		and	(LOGDATETIMESTAMP is null or LOGDATETIMESTAMP = @pdtLastModifiedDate)"

	exec @nErrorCode=sp_executesql @sSQLString,
	      		N'
		@pnCaseKey		int,
		@pnRelationshipKey	int,
		@pdtLastModifiedDate	datetime',
		@pnCaseKey		= @pnCaseKey,
		@pnRelationshipKey	= @pnRelationshipKey,
		@pdtLastModifiedDate	= @pdtLastModifiedDate

End

Return @nErrorCode
GO

Grant execute on dbo.csw_DeleteAssignedCases to public
GO