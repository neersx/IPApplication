-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_DeleteRelatedReciprocal
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_DeleteRelatedReciprocal]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_DeleteRelatedReciprocal.'
	Drop procedure [dbo].[csw_DeleteRelatedReciprocal]
End
Print '**** Creating Stored Procedure dbo.csw_DeleteRelatedReciprocal...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.csw_DeleteRelatedReciprocal
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,	
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory
	@psRelationshipCode		nvarchar(3) 	= null,
	@pnRelatedCaseKey		int	 	= null,
	@pnPolicingBatchNumber		int		= null
)
as
-- PROCEDURE:	csw_DeleteRelatedReciprocal
-- VERSION:	5
-- DESCRIPTION:	Remove a reciprocal relationship based on the supplied forward relationship details.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	---------------	-------	----------------------------------------------- 
-- 10 Nov 2005	TM	RFC3204		1	Procedure created
-- 11 Nov 2005  TM	RFC3204		2	Correct comments and parameters names.
-- 11 May 2006	IB	RFC3717		3	Add @pnPolicingBatchNumber parameter.
--						Add row(s) to Policing.
-- 06 Feb 2008	SF	RFC6180		4 	Fix syntax errors
-- 18 Jul 2014	AT	RFC33411	5	Find reverse reciprocal relationship if valid relationship not found.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare	@nErrorCode			int
Declare @sSQLString			nvarchar(4000)
Declare @sReciprocalRelationship 	nvarchar(3)
Declare	@nReciprocalRelationshipNo	int

-- Initialise variables
Set @nErrorCode = 0
Set @sReciprocalRelationship = null
Set @nReciprocalRelationshipNo = null

-- Remove reciprocal Relationship if necessary
If @nErrorCode = 0
and @pnRelatedCaseKey is not null
Begin

	Set @sSQLString = "
	Select @sReciprocalRelationship = VR.RECIPRELATIONSHIP
	From CASES C
	Join VALIDRELATIONSHIPS VR 
		On (VR.RELATIONSHIP = @psRelationshipCode
		and VR.PROPERTYTYPE = C.PROPERTYTYPE
		and VR.COUNTRYCODE  =  (Select min(VR1.COUNTRYCODE)
					From VALIDRELATIONSHIPS VR1
					Where VR1.COUNTRYCODE in ('ZZZ', C.COUNTRYCODE) 
					and VR1.PROPERTYTYPE = C.PROPERTYTYPE
					and VR1.RELATIONSHIP = VR.RELATIONSHIP))
	Where C.CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
				      N'@sReciprocalRelationship	nvarchar(3)			OUTPUT,
					@pnCaseKey			int,
					@psRelationshipCode		nvarchar(3)',
					@sReciprocalRelationship	= @sReciprocalRelationship	OUTPUT,
					@pnCaseKey			= @pnCaseKey,
					@psRelationshipCode		= @psRelationshipCode
					
					
	if (@nErrorCode = 0 and
		(@sReciprocalRelationship is null or @sReciprocalRelationship = ''))
	Begin
		-- check for the reverse reciprocal
		Set @sSQLString = "
			SELECT @sReciprocalRelationship = VR.RELATIONSHIP
			FROM CASES RELCASE 
			JOIN VALIDRELATIONSHIPS VR 
				on (VR.RECIPRELATIONSHIP = @psRelationshipCode
				and VR.PROPERTYTYPE = RELCASE.PROPERTYTYPE
				and VR.COUNTRYCODE  =  (select min(VR1.COUNTRYCODE)
							from VALIDRELATIONSHIPS VR1
							where VR1.COUNTRYCODE in ('ZZZ', RELCASE.COUNTRYCODE) 
							and VR1.PROPERTYTYPE= RELCASE.PROPERTYTYPE
							and VR1.RELATIONSHIP = VR.RELATIONSHIP))
			where RELCASE.CASEID = @pnRelatedCaseKey"
			
		exec @nErrorCode=sp_executesql @sSQLString,
					      N'@sReciprocalRelationship	nvarchar(3)			OUTPUT,
						@pnRelatedCaseKey		int,
						@psRelationshipCode		nvarchar(3)',
						@sReciprocalRelationship	= @sReciprocalRelationship	OUTPUT,
						@pnRelatedCaseKey		= @pnRelatedCaseKey,
						@psRelationshipCode		= @psRelationshipCode
	End
	
	-- Find RELATIONSHIPNO of the reciprocal relationship
	If @sReciprocalRelationship is not null
	and @nErrorCode = 0
	Begin	
		Set @sSQLString = "
		Select @nReciprocalRelationshipNo = RELATIONSHIPNO
		from RELATEDCASE
		where CASEID = @pnRelatedCaseKey
		and RELATIONSHIP = @sReciprocalRelationship
		and RELATEDCASEID = @pnCaseKey"
		
		exec @nErrorCode=sp_executesql @sSQLString,
				      N'@nReciprocalRelationshipNo	int		output,
					@pnRelatedCaseKey		int,
					@sReciprocalRelationship	nvarchar(3),
					@pnCaseKey			int',
					@nReciprocalRelationshipNo	= @nReciprocalRelationshipNo	output,
					@pnRelatedCaseKey		= @pnRelatedCaseKey,
					@sReciprocalRelationship	= @sReciprocalRelationship,
					@pnCaseKey			= @pnCaseKey
	End

	-- Add row(s) to Policing
	If @nReciprocalRelationshipNo is not null
	and @nErrorCode = 0
	Begin
		exec @nErrorCode = dbo.ip_PoliceRelatedCase
			@pnUserIdentityId		= @pnUserIdentityId,
			@psCulture			= @psCulture,
			@pbCalledFromCentura		= @pbCalledFromCentura,
			@pnCaseKey			= @pnRelatedCaseKey,
			@pnRelationshipNo		= @nReciprocalRelationshipNo,
			@pnPolicingBatchNo		= @pnPolicingBatchNumber
	End	
	
	If @nReciprocalRelationshipNo is not null
	and @nErrorCode = 0
	Begin	
		Set @sSQLString = "
		Delete from RELATEDCASE
		where CASEID = @pnRelatedCaseKey
		and   RELATIONSHIPNO = @nReciprocalRelationshipNo"
		
		exec @nErrorCode=sp_executesql @sSQLString,
				      N'@pnRelatedCaseKey		int,
					@nReciprocalRelationshipNo	int',
					@pnRelatedCaseKey		= @pnRelatedCaseKey,
					@nReciprocalRelationshipNo	= @nReciprocalRelationshipNo	
	End
End

Return @nErrorCode
GO

Grant execute on dbo.csw_DeleteRelatedReciprocal to public
GO