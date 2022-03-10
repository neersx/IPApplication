-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateAssignedCases
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateAssignedCases]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateAssignedCases.'
	Drop procedure [dbo].[csw_UpdateAssignedCases]
End
Print '**** Creating Stored Procedure dbo.csw_UpdateAssignedCases...'
Print ''
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.csw_UpdateAssignedCases
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnCaseKey			int,		-- Mandatory
	@pnRelationshipKey		int,		-- Mandatory
	@pbIsChangeOwner		bit		= 0,
	@pdtAssignedDate		datetime	= getdate,
	@pdtLastModifiedDate		datetime	= null OUTPUT
)
as
-- PROCEDURE:	csw_UpdateAssignedCases
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update an Assigned Case  attached to an assignmet recordal case.

-- MODIFICATIONS :
-- Date		Who		Number	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 08 Aug 2011	KR		R7904	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
SET NOCOUNT OFF
-- Reset so the next procedure gets the default
SET ANSI_NULLS ON

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
set @nErrorCode = 0

If @nErrorCode = 0
Begin

	Set @sSQLString = "UPDATE RELATEDCASE
			Set RECORDALFLAGS = @pbIsChangeOwner
			Where RELATIONSHIPNO = @pnRelationshipKey
			And   CASEID = @pnCaseKey
			And   LOGDATETIMESTAMP = @pdtLastModifiedDate
			
			Select	@pdtLastModifiedDate = LOGDATETIMESTAMP
			From	RELATEDCASE
			Where RELATIONSHIPNO = @pnRelationshipKey
			And   CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
	      	N'
		@pnCaseKey		int,			
		@pnRelationshipKey	int,
		@pbIsChangeOwner		bit,
		@pdtLastModifiedDate	datetime output',
		@pnCaseKey		= @pnCaseKey,			
		@pnRelationshipKey	= @pnRelationshipKey,
		@pbIsChangeOwner		= @pbIsChangeOwner,
		@pdtLastModifiedDate	= @pdtLastModifiedDate OUTPUT
End

If @nErrorCode = 0
Begin
	exec csw_ApplyAssignment
	@pnUserIdentityId = @pnUserIdentityId,
	@psCulture = @psCulture,
	@pnCaseKey = @pnCaseKey,
	@pnRelationshipKey = @pnRelationshipKey,
	@pdtAssignedDate = @pdtAssignedDate
	
End 

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateAssignedCases to public
GO