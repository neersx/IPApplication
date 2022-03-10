-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateCase
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateCase.'
	Drop procedure [dbo].[csw_UpdateCase]
End
Print '**** Creating Stored Procedure dbo.csw_UpdateCase...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.csw_UpdateCase
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,	
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory
	@psCaseReference		nvarchar(30)	= null,
	@psCaseFamilyReference		nvarchar(20)	= null,
	@pnCaseStatusKey		smallint	= null,	
	@pnRenewalStatusKey		smallint	= null,	
	@psCaseTypeCode			nchar(1)	= null,
	@psPropertyTypeCode		nchar(1)	= null,
	@psCountryCode			nvarchar(3)	= null,
	@psCaseCategoryCode		nvarchar(2)	= null,
	@psSubTypeCode			nvarchar(2)	= null,
	@psApplicationBasisCode		nvarchar(2)	= null,
	@psTitle			nvarchar(254)	= null,
	@pbIsLocalClient		bit		= null,
	@pnEntitySizeKey		int		= null,
	@pnPredecessorCaseKey		int		= null,
	@pbFileCoverCaseKey		int		= null,
	@psPurchaseOrderNo		nvarchar(80)	= null,
	@psCurrentOfficialNumber	nvarchar(36)	= null,
	@psTaxRateCode			nvarchar(3)	= null,
	@pnCaseOfficeKey		int		= null,
	@pnNoOfClaims			smallint	= null,
	@pnIPOfficeDelay		int		= null,
	@pnApplicantDelay		int		= null,
	@pnIPOfficeAdjustment		int		= null,
	@psStem				nvarchar(30)	= null,
	@psLocalClasses			nvarchar(254)	= null,
	@psIntClasses			nvarchar(254)	= null,
	@psProfitCentreKey		nvarchar(6)	= null,
	@pnBudgetAmount			decimal(11,2)	= null,
	@pnBudgetRevisedAmt		decimal(11,2)	= null,
	@pnTypeOfMark			int		= null,
	@pnNoInSeries			int		= null,
	@pdtLastModifiedDate            datetime        = null,		
	@pbIgnoreConcurrency		bit		= 0	-- if equal to 1, do not check concurrency
)
as
-- PROCEDURE:	csw_UpdateCase
-- VERSION:	23
-- DESCRIPTION:	Update a case if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 29 Sep 2005	TM		1	Procedure created
-- 13 Dec 2005	TM	RFC3200	2	Update stored procedure accordingly to the CaseEntity.doc
-- 27 Apr 2006	AU	RFC3791	3	Made CASES.IPODELAY, CASES.APPLICANTDELAY, CASES.IPOPTA modifiable
-- 29 Sep 2006	SF	RFC3248	4	Made CASES.STEM modifiable
-- 28 Nov 2007	AT	RFC3208	5	Made Case Classes modifiable.
-- 06 Mar 2008	SF	RFC5776	6	update NoOfClasses if local classes have been changed.
-- 19 Mar 2008	vql	SQA14773 7      Make PurchaseOrderNo nvarchar(80)
-- 03 Jul 2008	AT	RFC5748	8	Insert/Update the date of last change event.
-- 09 Jul 2008	AT	RFC5748	9	Removed insert/update of date of last change. Handled in business entity.
-- 19 Aug 2008	AT	RFC6859	10	Add Case Profit Centre.
-- 27 Aug 2008	AT	RFC5712 11	Made Budget amounts modifiable.
-- 22 Sep 2008	As	RFC6445 12	Add New Parameters for TypesOfMarks ans Series and Modified the Update Query.
-- 10 Mar 2009	KR	RFC7731 13	Modified NULLIF to ISNULL while calling fn_Tokenise function
-- 28 Oct 2010	ASH	RFC9788 14	Maintain Title in foreign languages.
-- 12 Jul 2011	LP	RFC10908 15	Ignore concurrency checking if @pbIgnoreConcurrency = 0
--					i.e. When new case is being updated immediately after being created
--					and there are outstanding policing requests that could cause concurrency violations
--					Also fix Title Update logic as it was preventing concurrency errors from being reported.
-- 05 Nov 2011  DV      R11439  16      Check for Valid Property, Case Category and Sub Type
-- 28 Apr 2012	SF	R11318	17	Update Renewal Status
-- 11 Apr 2014  MS      R31303  18      Chek LastModifiedDate for concurrency rather than old params
-- 28 May 2014	AT	R34883	19	Fix syntax error inserting Property.
-- 06 Jan 2016	MF	R56530	20	Updating of the CURRENTOFFICIALNO should occur by calling csw_UpdateCurrentOfficalNumber
--					so that the correct logic for determining the number is applied.
-- 14 Sep 2016	MF	68322	21	As an interim solution to a concurrency issuer where the calling program was not correctly refreshing
--					the LOGDATETIMESTAMP of the CASES row being updated, also compare the LOGIDENTITYID against the connected
--					user.
-- 27 Jun 2019	MF	DR-49984 22	STOPPAYREASON should be set if there is one associated with the Status change.
-- 10 Sep 2019	BS	DR-28789 23	Trimmed leading and trailing blank spaces in IRN when creating new case.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode		int
declare @sSQLString		nvarchar(4000)
declare @sUpdateString 		nvarchar(4000)
declare @sWhereString		nvarchar(4000)
declare @sComma			nchar(1)
declare @nRowCount		int
declare @bPropertyExists	bit
declare @nNoOfClasses int
declare @dtCurrentDate	datetime
declare @nTitleTID		int
Declare @nTranCountStart	int
Declare @sLookupCulture		nvarchar(10)
Declare @sOldLocalClasses       nvarchar(254)
Declare @sOldTitle              nvarchar(254)
Declare @sOldApplicationBasisCode nvarchar(2)
Declare @nOldNoOfClaims         smallint
Declare @nOldRenewalStatusKey   smallint
		
-- Initialise variables
Set @nErrorCode 	= 0
Set @nRowCount		= -1
Set @bPropertyExists	= 0

If @nErrorCode = 0
Begin
   Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
End

-- Maintain Property if Property attributes have changed
If   @nErrorCode = 0
Begin
	-- Is Property exists for the case?
	Set @sSQLString = "
	Select @bPropertyExists = 1,
	        @sOldApplicationBasisCode = BASIS,
	        @nOldNoOfClaims = NOOFCLAIMS,
	        @nOldRenewalStatusKey = RENEWALSTATUS
	from PROPERTY 
	where CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
			      N'@bPropertyExists	bit			output,
			        @sOldApplicationBasisCode       nvarchar(2)     output,
			        @nOldNoOfClaims         smallint                output,
			        @nOldRenewalStatusKey   smallint                output,
				@pnCaseKey		int',
				@bPropertyExists	= @bPropertyExists	output,
				@sOldApplicationBasisCode = @sOldApplicationBasisCode   output,
				@nOldNoOfClaims         = @nOldNoOfClaims       output,
				@nOldRenewalStatusKey   = @nOldRenewalStatusKey output,
				@pnCaseKey		= @pnCaseKey

        If   @nErrorCode = 0
                and (@psApplicationBasisCode <> @sOldApplicationBasisCode 
                or  @pnNoOfClaims <> @nOldNoOfClaims
                or  @pnRenewalStatusKey <> @nOldRenewalStatusKey)
        Begin
        
	        -- If Property exist for CaseKey then update it
	        If  @nErrorCode = 0
	        and @bPropertyExists = 1
	        Begin
	                DECLARE @psValidBasis nvarchar(2)
	                Select  @psValidBasis = VB.BASIS from  CASES C Left Join PROPERTY P on (P.CASEID=C.CASEID)
	                        JOIN VALIDBASIS VB on (VB.PROPERTYTYPE = C.PROPERTYTYPE
                                and VB.BASIS        = P.BASIS
                                and VB.COUNTRYCODE  = (select min(VB1.COUNTRYCODE)
                                                         from VALIDBASIS VB1
                                                         where VB1.PROPERTYTYPE = C.PROPERTYTYPE
                                                         and   VB1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
                                WHERE C.CASEID = @pnCaseKey
		        Set @sSQLString = "
		        Update  PROPERTY
		        Set     BASIS 		= @psApplicationBasisCode,
			        NOOFCLAIMS 	= @pnNoOfClaims,
			        RENEWALSTATUS	= @pnRenewalStatusKey
		                where   CASEID 		= @pnCaseKey
		                 and	NOOFCLAIMS	= @nOldNoOfClaims
		                 and	RENEWALSTATUS	= @nOldRenewalStatusKey"
		        if (@psValidBasis is not null)
		        BEGIN
		              Set @sSQLString = @sSQLString +  " and     BASIS 	= @sOldApplicationBasisCode "
		        END
        	
		        exec @nErrorCode=sp_executesql @sSQLString,
				              N'@pnCaseKey		int,
					        @psApplicationBasisCode	nvarchar(2),
					        @pnNoOfClaims		smallint,
					        @pnRenewalStatusKey	smallint,
					        @nOldRenewalStatusKey	smallint,
					        @sOldApplicationBasisCode nvarchar(2),
					        @nOldNoOfClaims	        smallint',
					        @pnCaseKey		= @pnCaseKey,
					        @psApplicationBasisCode	= @psApplicationBasisCode,
					        @pnNoOfClaims		= @pnNoOfClaims,
					        @pnRenewalStatusKey	= @pnRenewalStatusKey,
					        @sOldApplicationBasisCode = @sOldApplicationBasisCode,
					        @nOldNoOfClaims	        = @nOldNoOfClaims,
					        @nOldRenewalStatusKey	= @nOldRenewalStatusKey
        						
		        -- @nRowCount will be reset to 0 if there was a concurrency error
		        -- while updating property table
		        Set @nRowCount = @@RowCount
	        End
	        Else
	        -- If Property does not exists for CaseKey then insert it
	        If  @nErrorCode = 0
	        and @bPropertyExists = 0
	        Begin
        		
		        Set @sSQLString = "
		        Insert into PROPERTY(CASEID, BASIS, NOOFCLAIMS, RENEWALSTATUS)
		        Select @pnCaseKey, @psApplicationBasisCode, @pnNoOfClaims, @pnRenewalStatusKey" 
        		
		        exec @nErrorCode=sp_executesql @sSQLString,
					              N'@pnCaseKey		int,
						        @psApplicationBasisCode	nvarchar(2),
						        @pnNoOfClaims		smallint,
						        @pnRenewalStatusKey	smallint',
						        @pnCaseKey		= @pnCaseKey,
						        @psApplicationBasisCode	= @psApplicationBasisCode,
						        @pnNoOfClaims		= @pnNoOfClaims,
						        @pnRenewalStatusKey	= @pnRenewalStatusKey
	        End
	End
End

-- Retreive OldClasses and OldTitle
If @nErrorCode = 0
Begin
        Set @sSQLString = "
	Select  @sOldLocalClasses = LOCALCLASSES,
	        @sOldTitle = TITLE
	from CASES 
	where CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
			      N'@sOldLocalClasses	nvarchar(254)		output,
			        @sOldTitle              nvarchar(254)           output,
				@pnCaseKey		int',
				@sOldLocalClasses	= @sOldLocalClasses	output,
				@sOldTitle              = @sOldTitle            output,
				@pnCaseKey		= @pnCaseKey
End

If @nErrorCode = 0
-- Proceed updating case only if there was no concurrency error 
-- while updating Property table or if the Property table was
-- not updated at all
and (@nRowCount > 0 or @nRowCount = -1)
Begin		
	Set @sUpdateString = "SET ANSI_NULLS OFF"+char(10)+"Update CASES Set 
	                                IRN = LTRIM(RTRIM(@psCaseReference)),
	                                FAMILY = @psCaseFamilyReference,
	                                STATUSCODE = @pnCaseStatusKey,
					STOPPAYREASON=coalesce(R.STOPPAYREASON, S.STOPPAYREASON, C.STOPPAYREASON),
	                                CASETYPE = @psCaseTypeCode,
	                                PROPERTYTYPE = @psPropertyTypeCode,
	                                COUNTRYCODE = @psCountryCode,
	                                CASECATEGORY = @psCaseCategoryCode,
	                                SUBTYPE = @psSubTypeCode,
	                                TYPEOFMARK = @pnTypeOfMark,
	                                TITLE = @psTitle,
	                                NOINSERIES = @pnNoInSeries,
	                                LOCALCLIENTFLAG = @pbIsLocalClient,
	                                ENTITYSIZE = @pnEntitySizeKey,
	                                PREDECESSORID = @pnPredecessorCaseKey,
	                                FILECOVER = @pbFileCoverCaseKey,
	                                PURCHASEORDERNO = @psPurchaseOrderNo,
	                            /***CURRENTOFFICIALNO = @psCurrentOfficialNumber,***/ --RFC56530 CurrentOfficalNo to be updated using csw_UpdateCurrentOfficialNumber
	                                TAXCODE = @psTaxRateCode,
	                                OFFICEID = @pnCaseOfficeKey,
	                                IPODELAY = @pnIPOfficeDelay,
	                                APPLICANTDELAY = @pnApplicantDelay,
	                                IPOPTA = @pnIPOfficeAdjustment,
	                                STEM = @psStem,
	                                LOCALCLASSES = @psLocalClasses,
	                                INTCLASSES = @psIntClasses,
	                                PROFITCENTRECODE = @psProfitCentreKey,
	                                BUDGETAMOUNT = @pnBudgetAmount,
	                                BUDGETREVISEDAMT = @pnBudgetRevisedAmt"
	                                
	Set @sWhereString =     CHAR(10)+" From CASES C"+
				CHAR(10)+" Left Join STATUS R on (R.STATUSCODE=@pnRenewalStatusKey)"+
				CHAR(10)+" Left Join STATUS S on (S.STATUSCODE=@pnCaseStatusKey)"+
				CHAR(10)+" where CASEID = @pnCaseKey"
	If @pbIgnoreConcurrency = 0
	Begin				
	     	Set @sWhereString = @sWhereString+CHAR(10)+" and (C.LOGDATETIMESTAMP = @pdtLastModifiedDate or (C.LOGDATETIMESTAMP is null and @pdtLastModifiedDate is null) or C.LOGIDENTITYID = @pnUserIdentityId)"			
	End

	Set @sSQLString = @sUpdateString + @sWhereString

	exec @nErrorCode=sp_executesql @sSQLString,
				      N'@pnCaseKey		int,
					@psCaseReference	nvarchar(30),
					@psCaseFamilyReference	nvarchar(20),
					@pnCaseStatusKey	smallint,
					@pnRenewalStatusKey	smallint,
					@psCaseTypeCode		nchar(1),		
					@psPropertyTypeCode	nchar(1),
					@psCountryCode		nvarchar(3),
					@psCaseCategoryCode	nvarchar(2),
					@psSubTypeCode		nvarchar(2),
					@psTitle		nvarchar(254),
					@pbIsLocalClient	bit,
					@pnEntitySizeKey	int,
					@pnPredecessorCaseKey	int,
					@pbFileCoverCaseKey	int,
					@psPurchaseOrderNo	nvarchar(80),
					@psCurrentOfficialNumber nvarchar(36),
					@psTaxRateCode		nvarchar(3),
					@pnCaseOfficeKey	int,
					@pnIPOfficeDelay	int,
					@pnApplicantDelay	int,
					@pnIPOfficeAdjustment	int,
					@psStem			nvarchar(30),
					@psLocalClasses		nvarchar(254),
					@psIntClasses		nvarchar(254),
					@psProfitCentreKey	nvarchar(6),
					@pnBudgetAmount		decimal(11,2),
					@pnBudgetRevisedAmt	decimal(11,2),
					@pnTypeOfMark		int,
					@pnNoInSeries		int,
					@pdtLastModifiedDate    datetime,
					@pnUserIdentityId	int',
					@pnCaseKey		= @pnCaseKey,
					@psCaseReference	= @psCaseReference,
					@psCaseFamilyReference	= @psCaseFamilyReference,
					@pnCaseStatusKey	= @pnCaseStatusKey,
					@pnRenewalStatusKey	= @pnRenewalStatusKey,
					@psCaseTypeCode		= @psCaseTypeCode,		
					@psPropertyTypeCode	= @psPropertyTypeCode,
					@psCountryCode		= @psCountryCode,
					@psCaseCategoryCode	= @psCaseCategoryCode,
					@psSubTypeCode		= @psSubTypeCode,
					@psTitle		= @psTitle,
					@pbIsLocalClient	= @pbIsLocalClient,
					@pnEntitySizeKey	= @pnEntitySizeKey,
					@pnPredecessorCaseKey	= @pnPredecessorCaseKey,
					@pbFileCoverCaseKey	= @pbFileCoverCaseKey,
					@psPurchaseOrderNo	= @psPurchaseOrderNo,
					@psCurrentOfficialNumber= @psCurrentOfficialNumber,
					@psTaxRateCode		= @psTaxRateCode,
					@pnCaseOfficeKey	= @pnCaseOfficeKey,
					@pnIPOfficeDelay	= @pnIPOfficeDelay,
					@pnApplicantDelay	= @pnApplicantDelay,
					@pnIPOfficeAdjustment	= @pnIPOfficeAdjustment,
					@psStem			= @psStem,
					@psLocalClasses		= @psLocalClasses,
					@psIntClasses		= @psIntClasses,
					@psProfitCentreKey	= @psProfitCentreKey,
					@pnBudgetAmount		= @pnBudgetAmount,
					@pnBudgetRevisedAmt	= @pnBudgetRevisedAmt,
					@pnTypeOfMark		= @pnTypeOfMark,
					@pnNoInSeries		= @pnNoInSeries,
					@pdtLastModifiedDate    = @pdtLastModifiedDate,
					@pnUserIdentityId	= @pnUserIdentityId

	Set @nRowCount = @@RowCount
End
-------------------------------------------
-- Only apply following update if there was 
-- no concurrency error on Case update
-------------------------------------------
If @nRowCount > 0
Begin
	-- Only update NOOFCLASS if classes have changed
	If (@psLocalClasses <> @sOldLocalClasses)
	Begin
		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
			Select @nNoOfClasses = isnull(count(*), 0)
			From dbo.fn_Tokenise(@psLocalClasses, ',')"
			
			exec @nErrorCode=sp_executesql @sSQLString,
						  N'@nNoOfClasses		int out, 
							@psLocalClasses		nvarchar(254)',						
							@nNoOfClasses 		= @nNoOfClasses out,
							@psLocalClasses		= @psLocalClasses
		
		End	

		If @nErrorCode = 0 
		and not exists (select * from CASES where CASEID = @pnCaseKey and NOOFCLASSES = @nNoOfClasses)
		Begin
			Set @sSQLString = "UPDATE CASES 
					SET NOOFCLASSES = @nNoOfClasses 
					WHERE CASEID = @pnCaseKey"
					
			exec @nErrorCode=sp_executesql @sSQLString,
				      N'@pnCaseKey		int,
						@nNoOfClasses	int',
						@pnCaseKey	= @pnCaseKey,
						@nNoOfClasses 	= @nNoOfClasses
		End	
	End	

	-- Determine the CurrentOfficialNumber
	If @nErrorCode = 0
	Begin
		exec @nErrorCode = csw_UpdateCurrentOfficialNumber
					@pnUserIdentityId	= @pnUserIdentityId,
					@psCulture		= @psCulture,
					@pnCaseKey		= @pnCaseKey		
	End

	-- Update key words if required
	If   @nErrorCode = 0
	and (@psTitle <> @sOldTitle)
	Begin
		exec @nErrorCode = dbo.cs_InsertKeyWordsFromTitle 
			@nCaseId 		= @pnCaseKey
	End

	If @nErrorCode = 0 
	and @sLookupCulture is not null
	and (@psTitle <> @sOldTitle)
	Begin

		-- Get the TIDs if the exist
		Set @sSQLString = "
			select 	@nTitleTID = TITLE_TID
			FROM CASES
			WHERE CASEID = @pnCaseKey"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnCaseKey		int,
						@nTitleTID		int output',
						@pnCaseKey = @pnCaseKey,
						@nTitleTID = @nTitleTID	output

		If @nErrorCode = 0
		Begin
			-- if there is no TID, a new one will be generated
			exec @nErrorCode = ipn_UpdateTranslatedText	@pnUserIdentityId=@pnUserIdentityId,
									@psCulture=@sLookupCulture,
									@psTableName='CASES',
									@psTIDColumnName='TITLE_TID',
									@psText=@psTitle,
									@pnTID=@nTitleTID output

		End
	End	
End

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateCase to public
GO