-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertRelatedReciprocal
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertRelatedReciprocal]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_InsertRelatedReciprocal.'
	Drop procedure [dbo].[csw_InsertRelatedReciprocal]
End
Print '**** Creating Stored Procedure dbo.csw_InsertRelatedReciprocal...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.csw_InsertRelatedReciprocal
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,	
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory
	@pnSequence			int 		= null	output,
	@psRelationshipCode		nvarchar(3) 	= null,
	@pnRelatedCaseKey		int	 	= null,
	@pnPolicingBatchNumber		int		= null
)
as
-- PROCEDURE:	csw_InsertRelatedReciprocal
-- VERSION:	3
-- DESCRIPTION:	Create a new reciprocal relationship based on supplied forward relationship details.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 10 Nov 2005	TM	RFC3204	1	Procedure created
-- 11 Nov 2005	TM	RFC3204	2	Correct the comments and @pnSequence generation.
-- 11 May 2006	IB	RFC3717	3	Add @pnPolicingBatchNumber parameter.
--					Add row(s) to Policing.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare	@nErrorCode			int
Declare @sSQLString			nvarchar(4000)
Declare @sReciprocalRelationship 	nvarchar(3)

-- Initialise variables
Set @nErrorCode = 0
Set @pnSequence = 0

-- Create reciprocal Relationship if necessary
If @nErrorCode = 0
and @pnRelatedCaseKey is not null
Begin
	Set @sSQLString = "
	Select @sReciprocalRelationship = VR.RECIPRELATIONSHIP
	from CASES C
	join VALIDRELATIONSHIPS VR 
		on (VR.RELATIONSHIP = @psRelationshipCode
		and VR.PROPERTYTYPE = C.PROPERTYTYPE
		and VR.COUNTRYCODE  =  (select min(VR1.COUNTRYCODE)
					from VALIDRELATIONSHIPS VR1
					where VR1.COUNTRYCODE in ('ZZZ', C.COUNTRYCODE) 
					and VR1.PROPERTYTYPE=C.PROPERTYTYPE
					and VR1.RELATIONSHIP = VR.RELATIONSHIP))
	where C.CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
				      N'@sReciprocalRelationship	nvarchar(3)			OUTPUT,
					@pnCaseKey			int,
					@psRelationshipCode		nvarchar(3)',
					@sReciprocalRelationship	= @sReciprocalRelationship	OUTPUT,
					@pnCaseKey			= @pnCaseKey,
					@psRelationshipCode		= @psRelationshipCode		
	
	If @sReciprocalRelationship is not null
	and @nErrorCode = 0
	Begin
		-- Get the next sequence no for RelatedCaseKey:
		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
			Select @pnSequence = isnull(MAX(RELATIONSHIPNO)+1, 0)
			from RELATEDCASE
			where CASEID = @pnRelatedCaseKey"
		
			exec @nErrorCode=sp_executesql @sSQLString,	
						      N'@pnSequence		int		OUTPUT,
							@pnRelatedCaseKey	int',
							@pnSequence		= @pnSequence	OUTPUT,
							@pnRelatedCaseKey	= @pnRelatedCaseKey
		End

		If @nErrorCode = 0
		Begin		
			Set @sSQLString = "
			Insert into RELATEDCASE (CASEID, RELATIONSHIP, RELATEDCASEID, RELATIONSHIPNO)
			values (@pnRelatedCaseKey, @sReciprocalRelationship, @pnCaseKey, @pnSequence)"
			
			exec @nErrorCode=sp_executesql @sSQLString,
					      N'@pnRelatedCaseKey		int,
						@sReciprocalRelationship	nvarchar(3),
						@pnCaseKey			int,
						@pnSequence			int',
						@pnRelatedCaseKey		= @pnRelatedCaseKey,
						@sReciprocalRelationship	= @sReciprocalRelationship,
						@pnCaseKey			= @pnCaseKey,
						@pnSequence			= @pnSequence			
		End
	End
End

-- Add row(s) to Policing
If   @nErrorCode = 0
Begin
	exec @nErrorCode = dbo.ip_PoliceRelatedCase
		@pnUserIdentityId		= @pnUserIdentityId,
		@psCulture			= @psCulture,
		@pbCalledFromCentura		= @pbCalledFromCentura,
		@pnCaseKey			= @pnRelatedCaseKey,
		@pnRelationshipNo		= @pnSequence,
		@pnPolicingBatchNo		= @pnPolicingBatchNumber
End

Return @nErrorCode
GO

Grant execute on dbo.csw_InsertRelatedReciprocal to public
GO