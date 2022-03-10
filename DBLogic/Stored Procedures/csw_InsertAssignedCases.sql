-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertAssignedCases
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertAssignedCases]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_InsertAssignedCases.'
	Drop procedure [dbo].[csw_InsertAssignedCases]
End
Print '**** Creating Stored Procedure dbo.csw_InsertAssignedCases...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_InsertAssignedCases
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnCaseKey			int,
	@pnRelatedCaseKey		int,
	@psOfficialNumber		nvarchar(72)	= null,
        @psCountry                      nvarchar(6)     = null,
	@pbIsAssigned			bit		= 0,
	@pdtLastModifiedDate		datetime

)
as
-- PROCEDURE:	csw_InsertAssignedCases
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert an Assigned Case to an assignment recordal case

-- MODIFICATIONS :
-- Date		Who	Number	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 8 Aug 2011	KR	R7904	1	Procedure created
-- 19 Sep 2017  MS      R72172  2       Insert Reverse Relationship Row for Related Case
-- 26 Sep 2018  AK      R61299  3       Included Country in insert statement

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode			int
Declare @sSQLString 			nvarchar(4000)
Declare @nRelationshipKey		int

-- Initialise variables
Set @nErrorCode			= 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "select  @nRelationshipKey = Max (RELATIONSHIPNO) + 1
		from	RELATEDCASE
		where	CASEID		= @pnCaseKey"
	
	exec @nErrorCode=sp_executesql @sSQLString,
	      	N'
		@pnCaseKey		int,
		@nRelationshipKey	int OUTPUT',
		@pnCaseKey	= @pnCaseKey,
		@nRelationshipKey	= @nRelationshipKey    OUTPUT		
		
End

If @nErrorCode = 0
Begin

	Set @sSQLString = "Insert into RELATEDCASE
				(CASEID,
				 RELATIONSHIPNO,
				 RELATIONSHIP,
				 RELATEDCASEID,
				 OFFICIALNUMBER,
				 RECORDALFLAGS, COUNTRYCODE)
			values (
				@pnCaseKey,
				ISNULL(@nRelationshipKey, 0),
				'ASG',
				@pnRelatedCaseKey,
				@psOfficialNumber,
				@pbIsAssigned, @psCountry)"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
		@pnCaseKey			int,
		@nRelationshipKey		int,
		@pnRelatedCaseKey		int,
		@psOfficialNumber		nvarchar(72),
                @psCountry                      nvarchar(6),
		@pbIsAssigned			bit',
		@pnCaseKey		= @pnCaseKey,
		@nRelationshipKey	= @nRelationshipKey,
		@pnRelatedCaseKey	= @pnRelatedCaseKey,
		@psOfficialNumber	= @psOfficialNumber,
                @psCountry              = @psCountry,
		@pbIsAssigned		= @pbIsAssigned


End

If @nErrorCode = 0
Begin
        exec @nErrorCode = dbo.csw_InsertRelatedReciprocal
			@pnUserIdentityId		= @pnUserIdentityId,
			@psCulture			= @psCulture,
			@pbCalledFromCentura		= 0,
			@pnCaseKey			= @pnCaseKey,
			@psRelationshipCode		= 'ASG',
			@pnRelatedCaseKey		= @pnRelatedCaseKey
End

Return @nErrorCode
GO

Grant execute on dbo.csw_InsertAssignedCases to public
GO