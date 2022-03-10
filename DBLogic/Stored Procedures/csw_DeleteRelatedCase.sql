-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_DeleteRelatedCase
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_DeleteRelatedCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_DeleteRelatedCase.'
	Drop procedure [dbo].[csw_DeleteRelatedCase]
End
Print '**** Creating Stored Procedure dbo.csw_DeleteRelatedCase...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.csw_DeleteRelatedCase
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,	
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory
	@pnSequence			int,		-- Mandatory
	@pnPolicingBatchNumber		int		= null,
	@psOldRelationshipCode		nvarchar(3) 	= null,
	@pnOldRelatedCaseKey		int	 	= null,
	@psOldOfficialNumber		nvarchar(36) 	= null,
	@psOldCountryCode		nvarchar(3) 	= null,
	@pdtOldEventDate		datetime	= null,
	@pnOldCycle			smallint	= null,
	@psOldTitle			nvarchar(254) = null,
	@pbIsRelationshipCodeInUse	bit 		= 0,
	@pbIsRelatedCaseKeyInUse	bit	 	= 0,
	@pbIsOfficialNumberInUse	bit 		= 0,
	@pbIsCountryCodeInUse		bit	 	= 0,
	@pbIsEventDateInUse		bit		= 0,
	@pbIsCycleInUse			bit		= 0,
	@pbIsTitleInUse			bit     = 0,
	@pdtLastModifiedDate		datetime = null
)
as
-- PROCEDURE:	csw_DeleteRelatedCase
-- VERSION:	5
-- DESCRIPTION:	Delete a related case if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 29 Sep 2005	TM		1	Procedure created
-- 02 Dec 2005	TM	RFC3204	2	Adjust accordingly to the RelatedCaseEntity.doc.
-- 11 May 2006	IB	RFC3717	3	Add @pnPolicingBatchNumber parameter.
--					Add row(s) to Policing.
-- 15 Dec 2009	PS	RFC5607 4       Add @psOldTitle and @pbIsTitleInUse parameter.
-- 22 Sep 2017  AK      R72485  5       Added parameter @pdtLastModifiedDate and removed unwanted checks from where clause 

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sDeleteString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

-- Add row(s) to Policing
If   @nErrorCode = 0
Begin
	exec @nErrorCode = dbo.ip_PoliceRelatedCase
		@pnUserIdentityId		= @pnUserIdentityId,
		@psCulture			= @psCulture,
		@pbCalledFromCentura		= @pbCalledFromCentura,
		@pnCaseKey			= @pnCaseKey,
		@pnRelationshipNo		= @pnSequence,
		@pnPolicingBatchNo		= @pnPolicingBatchNumber
End

-- Delete reciprocal
If   @nErrorCode = 0
and  @pnOldRelatedCaseKey is not null 
Begin
	exec @nErrorCode = dbo.csw_DeleteRelatedReciprocal
		@pnUserIdentityId		= @pnUserIdentityId,
		@psCulture			= @psCulture,
		@pbCalledFromCentura		= @pbCalledFromCentura,
		@pnCaseKey			= @pnCaseKey,
		@psRelationshipCode		= @psOldRelationshipCode,
		@pnRelatedCaseKey		= @pnOldRelatedCaseKey,
		@pnPolicingBatchNumber		= @pnPolicingBatchNumber
End

If @nErrorCode = 0
Begin
	-- Set 'Old' values of OfficialNumber, CountryCode and EventDate to null.  
	-- This information is held on the related case itself.
	If @pnOldRelatedCaseKey is not null
	Begin
		Set @psOldOfficialNumber= null
		Set @psOldCountryCode	= null
		Set @pdtOldEventDate	= null	
		Set @psOldTitle = null
	End
	

	Set @sDeleteString = "
	Delete from RELATEDCASE
	where CASEID = @pnCaseKey and 
        (LOGDATETIMESTAMP = @pdtLastModifiedDate or @pdtLastModifiedDate is null)  
	and RELATIONSHIPNO = @pnSequence"	

	exec @nErrorCode=sp_executesql @sDeleteString,
				      N'@pnCaseKey			int,
                                        @pdtLastModifiedDate            datetime,			
					@pnSequence			int',
					@pnCaseKey			= @pnCaseKey,
                                        @pdtLastModifiedDate            = @pdtLastModifiedDate,		
					@pnSequence			= @pnSequence
End

Return @nErrorCode
GO

Grant execute on dbo.csw_DeleteRelatedCase to public
GO