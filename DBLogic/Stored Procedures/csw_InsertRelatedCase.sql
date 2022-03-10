-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertRelatedCase
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertRelatedCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_InsertRelatedCase.'
	Drop procedure [dbo].[csw_InsertRelatedCase]
End
Print '**** Creating Stored Procedure dbo.csw_InsertRelatedCase...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_InsertRelatedCase
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,	
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory
	@pnSequence			int 		= null	output,
	@pnPolicingBatchNumber		int		= null,
	@psRelationshipCode		nvarchar(3) 	= null,
	@pnRelatedCaseKey		int	 	= null,
	@psOfficialNumber		nvarchar(36) 	= null,
	@psCountryCode			nvarchar(3) 	= null,	
	@pdtEventDate			datetime	= null,	
	@pnCycle			smallint	= null,
	@psTitle			nvarchar(254)	= null,
	@pnStatusCode			int		= null,
	@psClasses			nvarchar(254)	= null,	
	@psComments			nvarchar(254)	= null,
	@dtDesignatedDate	        datetime	=null,	
	@pbIsDefaultClasses		bit		= 0,
	@pbIsRelationshipCodeInUse	bit 		= 0,
	@pbIsRelatedCaseKeyInUse	bit	 	= 0,
	@pbIsOfficialNumberInUse	bit 		= 0,
	@pbIsCountryCodeInUse		bit	 	= 0,	
	@pbIsEventDateInUse		bit		= 0,
	@pbIsCycleInUse			bit		= 0,
	@pbIsTitleInUse			bit		= 0,
	@pbIsClassesInUse		bit		= 0,
	@pbIsCommentsInUse		bit		= 0,
	@pbAddForwardRelationshipOnly	bit		= 0,
	@pbDesignatedDateInUse	        bit		= 0	
)
as
-- PROCEDURE:	csw_InsertRelatedCase
-- VERSION:	11
-- DESCRIPTION:	Insert new related case.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30 Sep 2005	TM		1	Procedure created
-- 02 Dec 2005	TM	R3204	2	Adjust accordingly to the RelatedCaseEntity.doc.
-- 11 May 2006	IB	R3717	3	Add @pnPolicingBatchNumber parameter.
--					Add row(s) to Policing.
-- 10 Dec 2007	LP	R3210	4	Add @pnStatusCode parameter.
-- 07 Jan 2008	SF	R5708	5	Add @pbAddForwardRelationshipOnly parameter
-- 15 Dec 2009	PS      R5607	6	Add @psTitle and @pbIsTitleInUse paramteres.
-- 06 Oct 2011	MF	R11388	7	Ensure COUNTRYFLAGS column is initialised with the StatusCode value.
-- 06 Jun 2013	MS	R13408	8	Added @psClasses and @pbIsClassesInUse parameters.
-- 10 Jun 2013  AK	R13408	9	added @dtDesignatedDate and @pbDesignatedDateInUse parameter
-- 10 Jun 2013  DV	R13408	10	Added @psComments and @pbIsCommentsInUse parameters.
-- 23 Oct 2013  MS      R13708  11      Set countrycode to null only if RelatedCaseKey is not null and RelationshipCode <> 'DC1'

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString	nvarchar(4000)
declare @sSQLString2	nvarchar(4000)
declare @sInsertString 	nvarchar(4000)
declare @sValuesString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode 	= 0

-- Insert reciprocal relationship
If  @nErrorCode = 0
and @pnRelatedCaseKey is not null
and (@pbAddForwardRelationshipOnly = 0 or @pbAddForwardRelationshipOnly is null)
Begin
	 exec @nErrorCode = dbo.csw_InsertRelatedReciprocal
			@pnUserIdentityId		= @pnUserIdentityId,
			@psCulture			= @psCulture,
			@pbCalledFromCentura		= @pbCalledFromCentura,
			@pnCaseKey			= @pnCaseKey,
			@psRelationshipCode		= @psRelationshipCode,
			@pnRelatedCaseKey		= @pnRelatedCaseKey,
			@pnPolicingBatchNumber		= @pnPolicingBatchNumber
End

-- Insert forward relationship
If @nErrorCode = 0
Begin
	-- Set OfficialNumber, CountryCode and EventDate to null.  
	-- This information is held on the related case itself.
	If @pnRelatedCaseKey is not null
	Begin
		Set @psOfficialNumber	= null
		Set @pdtEventDate	= null	
		Set @psTitle		= null
		Set @psClasses		= null
		
		If @psRelationshipCode <> 'DC1'
		Begin
		        Set @psCountryCode	= null
		End
	End

	If @psClasses = '' 
	Begin
		Set @psClasses = null
	End 

	Set @sInsertString = "insert into RELATEDCASE (CASEID, RELATIONSHIPNO"
	Set @sValuesString = CHAR(10)+" values (@pnCaseKey, @pnSequence"

	If @pbIsRelationshipCodeInUse = 1 
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",RELATIONSHIP"			
		Set @sValuesString = @sValuesString+CHAR(10)+",@psRelationshipCode"
	End

	If @pbIsRelatedCaseKeyInUse = 1 
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",RELATEDCASEID"			
		Set @sValuesString = @sValuesString+CHAR(10)+",@pnRelatedCaseKey"
	End

	If @pbIsOfficialNumberInUse = 1 
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",OFFICIALNUMBER"			
		Set @sValuesString = @sValuesString+CHAR(10)+",@psOfficialNumber"
	End

	If @pbIsCountryCodeInUse = 1 
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",COUNTRYCODE"			
		Set @sValuesString = @sValuesString+CHAR(10)+",@psCountryCode"
	End

	If @pbIsEventDateInUse = 1 
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",PRIORITYDATE"			
		Set @sValuesString = @sValuesString+CHAR(10)+",@pdtEventDate"
	End

	If @pbIsCycleInUse = 1 
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",CYCLE"			
		Set @sValuesString = @sValuesString+CHAR(10)+",@pnCycle"
	End
	
	If @pbIsTitleInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",TITLE"			
		Set @sValuesString = @sValuesString+CHAR(10)+",@psTitle"
	End

	If @pnStatusCode is not null
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",CURRENTSTATUS, COUNTRYFLAGS"			
		Set @sValuesString = @sValuesString+CHAR(10)+",@pnStatusCode, @pnStatusCode"
	End

	If @pbIsClassesInUse = 1 and @pbIsDefaultClasses = 0
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",CLASS"			
		Set @sValuesString = @sValuesString+CHAR(10)+",REPLACE(@psClasses, ', ', ',')"
	End
	
	If @pbIsCommentsInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",ACCEPTANCEDETAILS"			
		Set @sValuesString = @sValuesString+CHAR(10)+",@psComments"
	End

	IF @pbDesignatedDateInUse=1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",PRIORITYDATE"			
		Set @sValuesString = @sValuesString+CHAR(10)+",REPLACE(@dtDesignatedDate, ', ', ',')"
	End

	Set @sInsertString = @sInsertString+CHAR(10)+")"			
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

	-- Get the next sequence no
	If @nErrorCode = 0
	Begin
		Set @sSQLString2 = "
		Select @pnSequence = isnull(MAX(RELATIONSHIPNO)+1, 0)
		from RELATEDCASE
		where CASEID = @pnCaseKey"
	
		exec @nErrorCode=sp_executesql @sSQLString2,	
					      N'@pnSequence	int		output,
						@pnCaseKey	int',
						@pnSequence	= @pnSequence	output,
						@pnCaseKey	= @pnCaseKey
	End

	exec @nErrorCode=sp_executesql @sSQLString,
				      N'@pnCaseKey			int,		
					@pnSequence			int,
					@psRelationshipCode		nvarchar(3), 	
					@pnRelatedCaseKey		int,	 	
					@psOfficialNumber		nvarchar(36), 	
					@psCountryCode			nvarchar(3), 	
					@pdtEventDate			datetime,	
					@pnCycle			smallint,
					@psTitle			nvarchar(254),
					@pnStatusCode			int,	
					@psClasses			nvarchar(254),
					@psComments			nvarchar(254),
					@dtDesignatedDate		datetime,
					@pbIsRelationshipCodeInUse 	bit, 		
					@pbIsRelatedCaseKeyInUse 	bit,	 	
					@pbIsOfficialNumberInUse 	bit, 		
					@pbIsCountryCodeInUse		bit,	 	
					@pbIsEventDateInUse		bit,		
					@pbIsCycleInUse			bit,
					@pbIsTitleInUse			bit,
					@pbDesignatedDateInUse	bit',					
					@pnCaseKey			= @pnCaseKey,		
					@pnSequence			= @pnSequence,
					@psRelationshipCode		= @psRelationshipCode, 	
					@pnRelatedCaseKey		= @pnRelatedCaseKey,	 	
					@psOfficialNumber		= @psOfficialNumber, 	
					@psCountryCode			= @psCountryCode, 	
					@pdtEventDate			= @pdtEventDate,	
					@pnCycle			= @pnCycle,	
					@psTitle			= @psTitle,
					@pnStatusCode			= @pnStatusCode,
					@psClasses			= @psClasses,
					@psComments			= @psComments,
					@dtDesignatedDate		=@dtDesignatedDate,
					@pbIsRelationshipCodeInUse 	= @pbIsRelationshipCodeInUse, 		
					@pbIsRelatedCaseKeyInUse 	= @pbIsRelatedCaseKeyInUse,	 	
					@pbIsOfficialNumberInUse 	= @pbIsOfficialNumberInUse, 		
					@pbIsCountryCodeInUse		= @pbIsCountryCodeInUse,	 	
					@pbIsEventDateInUse		= @pbIsEventDateInUse,		
					@pbIsCycleInUse			= @pbIsCycleInUse,
					@pbIsTitleInUse			= @pbIsTitleInUse,
					@pbDesignatedDateInUse	=@pbDesignatedDateInUse
End

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

If @nErrorCode = 0
Begin
	Select @pnSequence as 'RelationshipNo'
End

Return @nErrorCode
GO

Grant execute on dbo.csw_InsertRelatedCase to public
GO