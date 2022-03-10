-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateRelatedCase
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateRelatedCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateRelatedCase.'
	Drop procedure [dbo].[csw_UpdateRelatedCase]
End
Print '**** Creating Stored Procedure dbo.csw_UpdateRelatedCase...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.csw_UpdateRelatedCase
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,	
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory
	@pnSequence			int, 		-- Mandatory
	@pnPolicingBatchNumber		int		= null,
	@psRelationshipCode		nvarchar(3) 	= null,
	@pnRelatedCaseKey		int	 	= null,
	@psOfficialNumber		nvarchar(36) 	= null,
	@psCountryCode			nvarchar(3) 	= null,
	@pdtEventDate			datetime	= null,
	@pnCycle			smallint	= null,
	@psTitle			nvarchar(254) = null,
	@pnStatusCode			int		= null,
	@psComments			nvarchar(254)		= null,
	@psClasses			nvarchar(254)	= null,
	@dtDesignatedDate		datetime =null,
	@pbIsDefaultClasses		bit		= 0,
	@pdtLastModifiedDate	datetime	= null,
	@psOldComments		nvarchar(254)		= null,
	@pbUpdateComments	bit = 0
)
as
-- PROCEDURE:	csw_UpdateRelatedCase
-- VERSION:	12
-- DESCRIPTION:	Update a related case if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 29 Sep 2005	TM		1	Procedure created
-- 02 Dec 2005	TM	RFC3204	2	Adjust accordingly to the RelatedCaseEntity.doc.
-- 11 May 2006	IB	RFC3717	3	Add @pnPolicingBatchNumber parameter.
--					Add row(s) to Policing.
-- 20 Dec 2007	LP	RFC3210	4	Add new parameters to allow update of StatusCode and Comments.
-- 04 Jul 2008	Ash	RFC6590	5	Find the null values from RELATEDCASE table and compare it on Update command 
-- 15 Dec 2009	PS	RFC5607	6	Add new parameters to allow update of the Title.
-- 06 Oct 2011	MF	R11388	7	Ensure COUNTRYFLAGS column is updated with the StatusCode value.
-- 06 Jun 2013	MS	DR60	8	Added @psClasses parameter
-- 10 Jun 2013	AK	DR59	9	Added @dtDesignatedDate, @pbDesignatedDateInUse and @dtOldDesignatedDate parameter
-- 02 Jan 2014	DV	R27003	10	USe LOGDATETIMESTAMP for concurrency check
-- 13 Jan 2014	DV	R30022	11	Do not set the parameters to null for designated cases. 
-- 15 Jul 2014	AT	R33411	12	Use OUTPUT keyword when setting variables using sp_executesql

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare	@nRowCount	int
declare @nDummyStorage	int		-- to be used for selecting into when retrieving the updated row(s)		
declare @sSQLString	nvarchar(4000)
declare @sUpdateString 	nvarchar(4000)
declare @sWhereString	nvarchar(4000)
declare @sWhereString2	nvarchar(4000) 	-- to be used when retrieving the updated row(s)
declare @sOfficialNumber nvarchar(36)	
declare	@sCountryCode	nvarchar(3)	
declare	@sPriorityDate	datetime
declare @sCycle			smallint
declare @sTitle			nvarchar(254)
declare @sComma		nchar(1)
declare @nOldRelatedCaseKey	int
declare @sOldRelationshipCode nvarchar(3)

-- Initialise variables
Set @nErrorCode 	= 0
Set @nRowCount	 	= 0


If @pbUpdateComments = 1
Begin
		Set @sSQLString = "Update RELATEDCASE Set "+
						@sComma+CHAR(10)+"ACCEPTANCEDETAILS = @psComments"+
						CHAR(10)+" where CASEID = @pnCaseKey"+
						CHAR(10)+" and   RELATIONSHIPNO = @pnSequence"+
						CHAR(10)+" and	 ACCEPTANCEDETAILS = @psOldComments"						
		
		print @sSQLString
		exec @nErrorCode=sp_executesql @sSQLString,
						  N'@pnCaseKey			int,		
						@pnSequence			int,
						@psComments			nvarchar(254),
						@psOldComments		nvarchar(254)',
						@pnCaseKey			= @pnCaseKey,		
						@pnSequence			= @pnSequence,
						@psComments			= @psComments,
						@psOldComments		= @psOldComments
		
		Set @nRowCount = @@ROWCOUNT

						
End
Else
Begin	
	-- Add row(s) to Policing before update
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
		Set @sSQLString = "SELECT 
			@sOfficialNumber = C.OFFICIALNUMBER,
			@sCountryCode = C.COUNTRYCODE,
			@sPriorityDate= C.PRIORITYDATE,
			@sCycle=C.CYCLE,
			@sTitle = C.TITLE,
			@nOldRelatedCaseKey = RELATEDCASEID,
			@sOldRelationshipCode = RELATIONSHIP
			FROM RELATEDCASE C
			WHERE C.CASEID = @pnCaseKey
			and   C.RELATIONSHIPNO = @pnSequence
			and	  (LOGDATETIMESTAMP = @pdtLastModifiedDate 
					or (@pdtLastModifiedDate is null and LOGDATETIMESTAMP is null))"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@sOfficialNumber	nvarchar(36) output, 	
				@sCountryCode		nvarchar(3) output, 	
				@sPriorityDate		datetime output,	
				@sCycle			smallint output,
				@sTitle			nvarchar(254) output,
				@nOldRelatedCaseKey	int output,
				@sOldRelationshipCode	nvarchar(3) output,
				@pnCaseKey              int,
				@pnSequence             int,
				@pdtLastModifiedDate	datetime',
				@sOfficialNumber        = @sOfficialNumber output,
				@sCountryCode           = @sCountryCode output,
				@sPriorityDate          = @sPriorityDate output,
				@sCycle		        = @sCycle output,
				@sTitle			= @sTitle output,
				@nOldRelatedCaseKey	= @nOldRelatedCaseKey output,
				@sOldRelationshipCode	= @sOldRelationshipCode output,
				@pnCaseKey              = @pnCaseKey,
				@pnSequence             = @pnSequence,
				@pdtLastModifiedDate	= @pdtLastModifiedDate

	End

	-- Remove old reciprocal
	If   @nErrorCode = 0
	and  @nOldRelatedCaseKey is not null 
	and (@nOldRelatedCaseKey <> @pnRelatedCaseKey 
	 or  @sOldRelationshipCode <> @psRelationshipCode)
	Begin
		exec @nErrorCode = dbo.csw_DeleteRelatedReciprocal
			@pnUserIdentityId		= @pnUserIdentityId,
			@psCulture			= @psCulture,
			@pbCalledFromCentura		= @pbCalledFromCentura,
			@pnCaseKey			= @pnCaseKey,
			@psRelationshipCode		= @sOldRelationshipCode,
			@pnRelatedCaseKey		= @nOldRelatedCaseKey
	End

	-- Add new reciprocal
	If   @nErrorCode = 0
	and  @pnRelatedCaseKey is not null 
	and (@nOldRelatedCaseKey <> @pnRelatedCaseKey 
	 or  @sOldRelationshipCode <> @psRelationshipCode)
	Begin
		 exec @nErrorCode = dbo.csw_InsertRelatedReciprocal
			@pnUserIdentityId		= @pnUserIdentityId,
			@psCulture			= @psCulture,
			@pbCalledFromCentura		= @pbCalledFromCentura,
			@pnCaseKey			= @pnCaseKey,
			@psRelationshipCode		= @psRelationshipCode,
			@pnRelatedCaseKey		= @pnRelatedCaseKey
	End

	If @nErrorCode = 0
	Begin
		-- Set OfficialNumber, CountryCode and EventDate to null.  
		-- This information is held on the related case itself.
		If @pnRelatedCaseKey is not null and @psRelationshipCode <> 'DC1'
		Begin
			Set @psOfficialNumber	= null
			Set @psCountryCode	= null
			Set @pdtEventDate	= null	
			Set @psTitle = null				
		Set @psClasses		= null			
		End

		Set @sComma =','
		Set @sUpdateString = "Update RELATEDCASE Set "+
							+CHAR(10)+"RELATIONSHIP = @psRelationshipCode"+
							@sComma+CHAR(10)+"RELATEDCASEID = @pnRelatedCaseKey"+
							@sComma+CHAR(10)+"OFFICIALNUMBER = @psOfficialNumber"+
							@sComma+CHAR(10)+"COUNTRYCODE = @psCountryCode"+
						@sComma+CHAR(10)+"PRIORITYDATE = isnull(@pdtEventDate,@dtDesignatedDate)"+
							@sComma+CHAR(10)+"CYCLE = @pnCycle"+
							@sComma+CHAR(10)+"TITLE = @psTitle"+
							@sComma+CHAR(10)+"CURRENTSTATUS = @pnStatusCode"+
							@sComma+CHAR(10)+"ACCEPTANCEDETAILS = @psComments"
		If @pnStatusCode is not null
			Begin
				-----------------------------------------------------------------
				-- A boolean OR will be used to combine the latest StatusCode
				-- with the historical record of previous StatusCodes and store
				-- them all in the COUNTRYFLAGS column.  This can be done because
				-- the StatusCode values are all values to the power of 2.
				-----------------------------------------------------------------
				Set @sUpdateString = @sUpdateString+@sComma+CHAR(10)+"COUNTRYFLAGS = isnull(COUNTRYFLAGS,0) | @pnStatusCode"	
			End
							
	If @pbIsDefaultClasses = 0
	Begin
		Set @sUpdateString = @sUpdateString+@sComma+CHAR(10)+"CLASS = REPLACE(@psClasses, ', ', ',')"
	End						
							
		Set @sWhereString = CHAR(10)+" where CASEID = @pnCaseKey"+
					CHAR(10)+" and   RELATIONSHIPNO = @pnSequence"+
					CHAR(10)+" and	  (LOGDATETIMESTAMP = @pdtLastModifiedDate or (@pdtLastModifiedDate is null and LOGDATETIMESTAMP is null))"

		Set @sSQLString = @sUpdateString + @sWhereString
		
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
						@psComments			nvarchar(254),
					@psClasses			nvarchar(254),
					@dtDesignatedDate		datetime,
						@pdtLastModifiedDate	datetime',
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
						@psComments			= @psComments,
					@psClasses			= @psClasses,
					@dtDesignatedDate	= @dtDesignatedDate,
						@pdtLastModifiedDate=@pdtLastModifiedDate
		
		Set @nRowCount = @@ROWCOUNT
	End

	-- Add row(s) to Policing after update
	-- provided there were no concurrency errors (@nRowCount > 0) and any other errors (@nErrorCode = 0).
	If  @nErrorCode = 0
	and @nRowCount > 0
	Begin
		exec @nErrorCode = dbo.ip_PoliceRelatedCase
			@pnUserIdentityId		= @pnUserIdentityId,
			@psCulture			= @psCulture,
			@pbCalledFromCentura		= @pbCalledFromCentura,
			@pnCaseKey			= @pnCaseKey,
			@pnRelationshipNo		= @pnSequence,
			@pnPolicingBatchNo		= @pnPolicingBatchNumber
	End

	-- Ensure that the correct row count is returned to a caller by selecting the updated row
	-- provided there were no concurrency errors (@nRowCount > 0) and any other errors (@nErrorCode = 0).
	If  @nErrorCode = 0
	and @nRowCount > 0
	Begin
		Set @sSQLString = "
			Select @nDummyStorage = 1
			from RELATEDCASE"+ 
			CHAR(10)+" where CASEID = @pnCaseKey"+
			CHAR(10)+" and   RELATIONSHIPNO = @pnSequence"

		exec @nErrorCode=sp_executesql @sSQLString,
			  N'@pnCaseKey			int,		
			@pnSequence			int,
			@psRelationshipCode		nvarchar(3), 	
			@pnRelatedCaseKey		int,
			@pnStatusCode			int,	 	
			@psOfficialNumber		nvarchar(36), 	
			@psCountryCode			nvarchar(3), 	
			@pdtEventDate			datetime,	
			@pnCycle			smallint,
			@psTitle			nvarchar(254),
			@psComments			nvarchar(254),
		@psClasses			nvarchar(254),
			@nDummyStorage			int			output',
			@pnCaseKey			= @pnCaseKey,		
			@pnSequence			= @pnSequence,
			@psRelationshipCode		= @psRelationshipCode, 	
			@pnRelatedCaseKey		= @pnRelatedCaseKey,	
			@pnStatusCode			= @pnStatusCode, 	
			@psOfficialNumber		= @psOfficialNumber, 	
			@psCountryCode			= @psCountryCode, 	
			@pdtEventDate			= @pdtEventDate,	
			@pnCycle			= @pnCycle,
			@psTitle			= @psTitle,
			@psComments			= @psComments,
		@psClasses			= @psClasses,
			@nDummyStorage			= @nDummyStorage	output
	End
End

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateRelatedCase to public
GO