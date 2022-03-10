-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertCase
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_InsertCase.'
	Drop procedure [dbo].[csw_InsertCase]
End
Print '**** Creating Stored Procedure dbo.csw_InsertCase...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_InsertCase
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,	
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int		= null	output,
	@psCaseReference		nvarchar(30)	= null,
	@psCaseFamilyReference		nvarchar(20)	= null,
	@pnCaseStatusKey		smallint	= null,	
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
	@pnFileCoverCaseKey		int		= null,
	@psPurchaseOrderNo		nvarchar(80)	= null,
	@psCurrentOfficialNumber	nvarchar(36)	= null,
	@psTaxRateCode			nvarchar(3)	= null,
	@pnCaseOfficeKey		int		= null,
	@pnNoOfClaims			smallint	= null,
	@pdtInstructionsReceivedDate	datetime	= null,
	@pnIPOfficeDelay		int		= null,
	@pnApplicantDelay		int		= null,
	@pnIPOfficeAdjustment		int		= null,
	@psStem				nvarchar(30)	= null,
	@psLocalClasses			nvarchar(254)	= null,
	@psIntClasses			nvarchar(254)	= null,
	@pnBudgetAmount			decimal(11,2)	= null,
	@pnBudgetRevisedAmt		decimal(11,2)	= null,
	@pbIsCaseReferenceInUse		bit		= 0,
	@pbIsCaseFamilyReferenceInUse	bit		= 0,	
	@pbIsCaseStatusKeyInUse		bit		= 0,
	@pbIsCaseTypeCodeInUse		bit		= 0,		
	@pbIsPropertyTypeCodeInUse	bit		= 0,
	@pbIsCountryCodeInUse		bit		= 0,
	@pbIsCaseCategoryCodeInUse	bit		= 0,
	@pbIsSubTypeCodeInUse		bit		= 0,
	@pbIsApplicationBasisCodeInUse	bit		= 0,	-- Not in use; included to provide a standard interface
	@pbIsTitleInUse			bit		= 0,
	@pbIsLocalClientInUse		bit		= 0,
	@pbIsEntitySizeKeyInUse		bit		= 0,
	@pbIsPredecessorCaseKeyInUse	bit		= 0,
	@pbIsFileCoverCaseKeyInUse	bit		= 0,
	@pbIsPurchaseOrderNoInUse	bit		= 0,
	@pbIsCurrentOfficialNumberInUse	bit		= 0,
	@pbIsTaxRateCodeInUse		bit		= 0,
	@pbIsCaseOfficeKeyInUse		bit		= 0,
	@pbIsNoOfClaimsInUse		bit		= 0,	-- Not in use; included to provide a standard interface
	@pbIsInstructionsReceivedDateInUse bit		= 0,	-- Not in use; included to provide a standard interface
	@pbIsIPOfficeDelayInUse		bit		= 0,
	@pbIsApplicantDelayInUse	bit		= 0,
	@pbIsIPOfficeAdjustmentInUse	bit		= 0,
	@pbIsStemInUse			bit		= 0,
	@pbIsLocalClassesInUse		bit		= 0,
	@pbIsIntClassesInUse		bit		= 0,
	@pbIsBudgetAmountInUse		bit		= 0,
	@pbIsBudgetRevisedAmtInUse	bit		= 0
)
as
-- PROCEDURE:	csw_InsertCase
-- VERSION:	14
-- DESCRIPTION:	Insert new case.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 29 Sep 2005	TM		1	Procedure created
-- 13 Dec 2005	TM	RFC3200	2	Update stored procedure accordingly to the CaseEntity.doc
-- 27 Apr 2006	AU	RFC3791	3	Insert data into CASES.IPODELAY, CASES.APPLICANTDELAY, CASES.IPOPTA
-- 29 Sep 2006	SF	RFC3248	4	Insert data into CASES.STEM
-- 28 Nov 2007	AT	RFC3208	5	Insert data into CASES.LOCALCLASSES and CASES.INTCLASSES.
-- 19/03/2008	vql	SQA14773 6      Make PurchaseOrderNo nvarchar(80)
-- 03 Jul 2008	AT	RFC5748	7	Automatically add create date event to case.
-- 09 Jul 2008	AT	RFC5748	8	Removed create event date. Handled by business entity.
-- 27 Aug 2008	AT	RFC5712	9	Added Budget Amount and Budget Revised Amount.
-- 13 Nov 2009	LP	RFC7612	10	Check row access security.
-- 28 Oct 2010	ASH	RFC9788 11      Maintain Title in foreign languages.
-- 28 Apr 2013	KR	R13937	12	Made it to use cs_GetSecurityForCase in order to get row access security
-- 01 Jul 2014	LP	R33261	13	Fixed row access security logic.
--					Previously does not trigger because of multiple ROWACCESSDETAIL matches.
-- 05 Sep 2019	BS	DR-28789 14	Trimmed leading and trailing blank spaces in IRN when creating new case.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString	nvarchar(max)
declare @sInsertString 	nvarchar(max)
declare @sValuesString	nvarchar(max)
declare @dtCurrentDate	datetime
declare	@bHasRowAccessSecurity bit
declare @bUseOfficeSecurity bit
declare @nSecurityFlag	int
declare @sAlertXML	nvarchar(max)
Declare @sLookupCulture		nvarchar(10)
Declare @nTranCountStart 	int
declare @nTitleTID		int
Declare @pnTid                  int
DECLARE @sCaseReference nvarchar(30)

-- Initialise variables
Set @nErrorCode 	= 0
Set @bHasRowAccessSecurity = 0
Set @bUseOfficeSecurity = 0
Set @nSecurityFlag	= 15

If @nErrorCode = 0
Begin
   Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
End

-- -------------------
-- Row level security
-- -------------------
If @nErrorCode = 0
and exists (
	select 1
	from IDENTITYROWACCESS U WITH (NOLOCK) 
	join ROWACCESSDETAIL R WITH (NOLOCK) on (R.ACCESSNAME = U.ACCESSNAME) 
	where R.RECORDTYPE = 'C')
Begin
	Set @bHasRowAccessSecurity = 1
End

If @nErrorCode = 0
Begin
	Select @bUseOfficeSecurity = ISNULL(SC.COLBOOLEAN, 0)
	from SITECONTROL SC WITH (NOLOCK) where SC.CONTROLID = 'Row Security Uses Case Office'	
End

If  @nErrorCode = 0 
and @bHasRowAccessSecurity = 1
Begin
	Set @nSecurityFlag = 0		-- Set to 0 since we know that Row Access has been applied
	set @sSQLString = "
		SELECT @nSecurityFlag = S.SECURITYFLAG
		from (SELECT TOP 1 SECURITYFLAG as SECURITYFLAG,(1- isnull( (R.OFFICE * 0), 1 ) ) * 1000 
			+  CASE WHEN R.CASETYPE IS NULL THEN 0 ELSE 1 END  * 100 
			+  CASE WHEN R.PROPERTYTYPE IS NULL THEN 0 ELSE 1 END  * 10 
			+  CASE WHEN R.NAMETYPE IS NULL THEN 0 ELSE 1 END  * 1 as BESTFIT
			FROM ROWACCESSDETAIL R, IDENTITYROWACCESS U
			WHERE R.RECORDTYPE = 'C'" + CHAR(10) +
		CASE WHEN @bUseOfficeSecurity = 1 THEN
			"AND (R.OFFICE = @pnCaseOfficeKey OR R.OFFICE IS NULL)" END
			+ CHAR(10)+
			"AND (R.CASETYPE = @psCaseTypeCode OR R.CASETYPE IS NULL)
			AND (R.PROPERTYTYPE = @psPropertyTypeCode OR R.PROPERTYTYPE IS NULL)
			AND R.NAMETYPE IS NULL
			AND U.IDENTITYID = @pnUserIdentityId 
			AND U.ACCESSNAME = R.ACCESSNAME 
			ORDER BY BESTFIT DESC, SECURITYFLAG ASC) S
	"
	exec @nErrorCode=sp_executesql @sSQLString,
		N'@nSecurityFlag	int output,
		@pnCaseOfficeKey	int,
		@psCaseTypeCode		nvarchar(1),
		@psPropertyTypeCode	nvarchar(1),
		@pnUserIdentityId	int',
		@nSecurityFlag		= @nSecurityFlag output,
		@pnCaseOfficeKey	= @pnCaseOfficeKey,
		@psCaseTypeCode		= @psCaseTypeCode,
		@psPropertyTypeCode	= @psPropertyTypeCode,
		@pnUserIdentityId	= @pnUserIdentityId
End

If @nErrorCode = 0
and ((@bHasRowAccessSecurity = 0) or
     (@bHasRowAccessSecurity = 1 and @nSecurityFlag&4=4)
)
Begin
	If @nErrorCode = 0
	Begin
		exec @nErrorCode = dbo.ip_GetLastInternalCode
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,
				@psTable		= N'CASES',
				@pnLastInternalCode	= @pnCaseKey OUTPUT	
	End

	If @nErrorCode = 0
	Begin
		Set @sInsertString = "insert into CASES (CASEID"
		Set @sValuesString = CHAR(10)+" values (@pnCaseKey"

		If @pbIsCaseReferenceInUse = 1 
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+",IRN"
			Set @sValuesString = @sValuesString+CHAR(10)+",@psCaseReference"
            Set @sCaseReference = LTRIM(RTRIM(@psCaseReference))
		End

		If @pbIsCaseFamilyReferenceInUse = 1 
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+",FAMILY"
			Set @sValuesString = @sValuesString+CHAR(10)+",@psCaseFamilyReference"
		End

		If @pbIsCaseStatusKeyInUse = 1 
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+",STATUSCODE"
			Set @sValuesString = @sValuesString+CHAR(10)+",@pnCaseStatusKey"
		End

		If @pbIsCaseTypeCodeInUse = 1 
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+",CASETYPE"
			Set @sValuesString = @sValuesString+CHAR(10)+",@psCaseTypeCode"
		End

		If @pbIsPropertyTypeCodeInUse = 1 
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+",PROPERTYTYPE"
			Set @sValuesString = @sValuesString+CHAR(10)+",@psPropertyTypeCode"
		End

		If @pbIsCountryCodeInUse = 1 
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+",COUNTRYCODE"
			Set @sValuesString = @sValuesString+CHAR(10)+",@psCountryCode"
		End

		If @pbIsCaseCategoryCodeInUse = 1 
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+",CASECATEGORY"		
			Set @sValuesString = @sValuesString+CHAR(10)+",@psCaseCategoryCode"
		End

		If @pbIsSubTypeCodeInUse = 1 
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+",SUBTYPE"		
			Set @sValuesString = @sValuesString+CHAR(10)+",@psSubTypeCode"
		End

		If @pbIsTitleInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+",TITLE"
			Set @sValuesString = @sValuesString+CHAR(10)+",@psTitle"
		End

		If @pbIsLocalClientInUse = 1 
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+",LOCALCLIENTFLAG"
			Set @sValuesString = @sValuesString+CHAR(10)+",@pbIsLocalClient"
		End

		If @pbIsEntitySizeKeyInUse = 1 
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+",ENTITYSIZE"
			Set @sValuesString = @sValuesString+CHAR(10)+",@pnEntitySizeKey"
		End

		If @pbIsPredecessorCaseKeyInUse = 1 
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+",PREDECESSORID"
			Set @sValuesString = @sValuesString+CHAR(10)+",@pnPredecessorCaseKey"
		End

		If @pbIsFileCoverCaseKeyInUse = 1 
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+",FILECOVER"
			Set @sValuesString = @sValuesString+CHAR(10)+",@pnFileCoverCaseKey"
		End

		If @pbIsPurchaseOrderNoInUse = 1 
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+",PURCHASEORDERNO"
			Set @sValuesString = @sValuesString+CHAR(10)+",@psPurchaseOrderNo"
		End

		If @pbIsCurrentOfficialNumberInUse = 1 
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+",CURRENTOFFICIALNO"
			Set @sValuesString = @sValuesString+CHAR(10)+",@psCurrentOfficialNumber"
		End

		If @pbIsTaxRateCodeInUse = 1 
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+",TAXCODE"
			Set @sValuesString = @sValuesString+CHAR(10)+",@psTaxRateCode"
		End

		If @pbIsCaseOfficeKeyInUse = 1 
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+",OFFICEID"
			Set @sValuesString = @sValuesString+CHAR(10)+",@pnCaseOfficeKey"
		End

		If @pbIsIPOfficeDelayInUse = 1 
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+",IPODELAY"
			Set @sValuesString = @sValuesString+CHAR(10)+",@pnIPOfficeDelay"
		End

		If @pbIsApplicantDelayInUse = 1 
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+",APPLICANTDELAY"
			Set @sValuesString = @sValuesString+CHAR(10)+",@pnApplicantDelay"
		End

		If @pbIsIPOfficeAdjustmentInUse = 1 
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+",IPOPTA"
			Set @sValuesString = @sValuesString+CHAR(10)+",@pnIPOfficeAdjustment"
		End
		
		If @pbIsStemInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+",STEM"
			Set @sValuesString = @sValuesString+CHAR(10)+",@psStem"
		End

		If @pbIsLocalClassesInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+",LOCALCLASSES"
			Set @sValuesString = @sValuesString+CHAR(10)+",@psLocalClasses"
		End

		If @pbIsIntClassesInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+",INTCLASSES"
			Set @sValuesString = @sValuesString+CHAR(10)+",@psIntClasses"
		End

		If @pbIsBudgetAmountInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+",BUDGETAMOUNT"
			Set @sValuesString = @sValuesString+CHAR(10)+",@pnBudgetAmount"
		End

		If @pbIsBudgetRevisedAmtInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+",BUDGETREVISEDAMT"
			Set @sValuesString = @sValuesString+CHAR(10)+",@pnBudgetRevisedAmt"
		End

	        If @pbIsTitleInUse = 1
	        Begin
		        Set @sInsertString = @sInsertString+CHAR(10)+",TITLE_TID"
		        Set @sValuesString = @sValuesString+CHAR(10)+",@nTitleTID"
	        End

		Set @sInsertString = @sInsertString+CHAR(10)+")"
		Set @sValuesString = @sValuesString+CHAR(10)+")"

		Set @sSQLString = @sInsertString + @sValuesString

		-- Insert CASES row
		exec @nErrorCode=sp_executesql @sSQLString,
					      N'@pnCaseKey		int,
						@psCaseReference	nvarchar(30),
						@psCaseFamilyReference	nvarchar(20),
						@pnCaseStatusKey	smallint,
						@psCaseTypeCode		nchar(1),		
						@psPropertyTypeCode	nchar(1),
						@psCountryCode		nvarchar(3),
						@psCaseCategoryCode	nvarchar(2),
						@psSubTypeCode		nvarchar(2),
						@psTitle		nvarchar(254),
						@pbIsLocalClient	bit,
						@pnEntitySizeKey	int,
						@pnPredecessorCaseKey	int,
						@pnFileCoverCaseKey	int,
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
						@pnBudgetAmount		decimal(11,2),
						@pnBudgetRevisedAmt	decimal(11,2),
                                                @nTitleTID			int',
						@pnCaseKey		= @pnCaseKey,
						@psCaseReference	= @sCaseReference,
						@psCaseFamilyReference	= @psCaseFamilyReference,
						@pnCaseStatusKey	= @pnCaseStatusKey,
						@psCaseTypeCode		= @psCaseTypeCode,		
						@psPropertyTypeCode	= @psPropertyTypeCode,
						@psCountryCode		= @psCountryCode,
						@psCaseCategoryCode	= @psCaseCategoryCode,
						@psSubTypeCode		= @psSubTypeCode,
						@psTitle		= @psTitle,
						@pbIsLocalClient	= @pbIsLocalClient,
						@pnEntitySizeKey	= @pnEntitySizeKey,
						@pnPredecessorCaseKey	= @pnPredecessorCaseKey,
						@pnFileCoverCaseKey	= @pnFileCoverCaseKey,
						@psPurchaseOrderNo	= @psPurchaseOrderNo,
						@psCurrentOfficialNumber= @psCurrentOfficialNumber,
						@psTaxRateCode		= @psTaxRateCode,
						@pnCaseOfficeKey	= @pnCaseOfficeKey,
						@pnIPOfficeDelay	= @pnIPOfficeDelay,
						@pnApplicantDelay	= @pnApplicantDelay,
						@pnIPOfficeAdjustment	= @pnIPOfficeAdjustment,
						@psStem			= @psStem,
						@psLocalClasses 	= @psLocalClasses,
						@psIntClasses 		= @psIntClasses,
						@pnBudgetAmount		= @pnBudgetAmount,
						@pnBudgetRevisedAmt	= @pnBudgetRevisedAmt,
                                                @nTitleTID              = @nTitleTID
	End

	-- Publish CASEID as CaseKey
	If @nErrorCode = 0
	Begin
		Select @pnCaseKey as 'CaseKey'	
	End

	-- Create Property if required
	If   @nErrorCode = 0
	and (@psApplicationBasisCode is not null
	 or  @pnNoOfClaims is not null)
	Begin
		Set @sSQLString = "
		Insert into PROPERTY(CASEID, BASIS, NOOFCLAIMS)
		Select @pnCaseKey, @psApplicationBasisCode, @pnNoOfClaims"

		exec @nErrorCode=sp_executesql @sSQLString,
					      N'@pnCaseKey		int,
						@psApplicationBasisCode	nvarchar(2),
						@pnNoOfClaims		smallint',
						@pnCaseKey		= @pnCaseKey,
						@psApplicationBasisCode	= @psApplicationBasisCode,
						@pnNoOfClaims		= @pnNoOfClaims
	End

	-- Generate key words if required
	If @nErrorCode = 0
	and @psTitle is not null
	Begin
		exec @nErrorCode = dbo.cs_InsertKeyWordsFromTitle 
			@nCaseId 		= @pnCaseKey
	End

	-- Create Instructions Received Event if required
	If @nErrorCode = 0
	and @pdtInstructionsReceivedDate is not null
	Begin
		exec @nErrorCode = dbo.csw_InsertCaseEvent
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@pnCaseKey 		= @pnCaseKey,
			@pnEventKey 		=-16, -- (Instructions Received)
			@pnCycle		= 1,
			@pdtEventDate		= @pdtInstructionsReceivedDate,
			@pbIsPolicedEvent 	= 0
	End
End
Else
Begin
	-- User does not have row access security for insert
		Set @nErrorCode = 1
		Set @sAlertXML = dbo.fn_GetAlertXML('SF49', 'You do not have the correct privileges to create this case.',
						null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
End

If @nErrorCode = 0 and @sLookupCulture is not null
Begin

        Set @sSQLString = "
	Select 	@pnTid = TITLE_TID
	from  	CASES
	where 	CASEID = @pnCaseKey "

      
	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'@pnTid	        int		OUTPUT,
				  @pnCaseKey		int',
				  @pnTid	= @pnTid	OUTPUT,
				  @pnCaseKey		= @pnCaseKey
End

If @nErrorCode = 0 and @sLookupCulture is not null and @psTitle is not null
Begin
	-- Insert into translation tables.
	exec @nErrorCode = ipn_InsertTranslatedText	@pnUserIdentityId=@pnUserIdentityId,
							@psCulture=@sLookupCulture,
							@psTableName= N'CASES',
							@psTIDColumnName='TITLE_TID',
							@psText=@psTitle,
							@pnTID=@pnTid output
End

Return @nErrorCode
GO

Grant execute on dbo.csw_InsertCase to public
GO