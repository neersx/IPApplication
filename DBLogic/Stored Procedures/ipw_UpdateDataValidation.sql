-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateDataValidation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateDataValidation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateDataValidation.'
	Drop procedure [dbo].[ipw_UpdateDataValidation]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateDataValidation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_UpdateDataValidation
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) 	= null,			
	@pbCalledFromCentura	bit		= 0,
	@pnValidationID		int,			-- Mandatory
	@psFunctionalArea	nvarchar(1),	
	@psCaseTypeCode		nvarchar(1)	= null,		
	@psCaseCategoryCode	nvarchar(2)	= null,	
	@psNameCategoryCode	int	= null,	
	@psPropertyTypeCode	nvarchar(1)	= null,		
	@psCountryCode		nvarchar(3)	= null,		
	@psSubTypeCode		nvarchar(2)	= null,		
	@psBasis		nvarchar(2)	= null,	
	@pnStatus		smallint	= null,	
	@pnEventDateFlag	smallint	= null,	
	@pnEventNo		int		= null,	
	@pbInUseFlag		bit		= null,	
	@pbDeferredFlag		bit		= null,	
	@pnColumnName		int		= null,	
	@pnOfficeID		int		= null,	
	@pbLocalClientFlag	bit		= null,	
	@pnFamilyNo		smallint	= null,	
	@pnNameNo		int		= null,	
	@psNameType		nvarchar(3)	= null,	
	@psInstructionType	nvarchar(3)	= null,	
	@pnFlagNo		smallint	= null,	
	@pbWarningFlag		bit		= null,	
	@pnRoleID		int		= null,	
	@pnItemID		int		= null,	
	@psDisplayMessage	nvarchar(max)	= null,	
	@psNotes		nvarchar(max)	= null,	
	@psRuleDescription	nvarchar(254)	= null,	
	@pdtLastUpdatedDate	datetime	= null,
	@pbBulkUpdate		bit             = null,
	@pbNotCaseType          bit             = null,
    @pbNotPropertyType      bit             = null,
    @pbNotCountryCode       bit             = null,
    @pbNotCaseCategory      bit             = null,
    @pbNotBasis             bit             = null,
    @pbNotSubType           bit             = null,
    @pnUsedAsFlag   int     = null,
	@pbSupplierFlag  bit    = null		
)
as
-- PROCEDURE:	ipw_UpdateDataValidation
-- VERSION:	5
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Procedure to update Data Validation Rule
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 29 Sep 2010  DV	R9387	1	Procedure created
-- 17 May 2011  DV	R10157  2       Insert the value of NOT columns
-- 04 Aug 2011	MF	R11077	3	Correct the duplicate test to also check the Display Message and the ItemId associated.
-- 19 Jan 2012  DV      R11778  4       Fixed issue with save of Not values
-- 06 Jun 2012  ASH   R9757  5   Change the procedure to update Name data validation attributes.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(max)
Declare @message_string VARCHAR(255)  

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0

If @nErrorCode = 0 and (@pbBulkUpdate is null or @pbBulkUpdate =0)
Begin
	If exists (	Select 1 
			from DATAVALIDATION 
			where	(CASETYPE        = @psCaseTypeCode      or (@psCaseTypeCode     is null and CASETYPE        is null))
			and	(CASECATEGORY    = @psCaseCategoryCode  or (@psCaseCategoryCode is null and CASECATEGORY    is null))
			and	(PROPERTYTYPE    = @psPropertyTypeCode  or (@psPropertyTypeCode is null and PROPERTYTYPE    is null))
			and	(COUNTRYCODE     = @psCountryCode       or (@psCountryCode      is null and COUNTRYCODE     is null))
			and	(SUBTYPE         = @psSubTypeCode       or (@psSubTypeCode      is null and SUBTYPE         is null))
			and	(BASIS           = @psSubTypeCode       or (@psSubTypeCode      is null and BASIS           is null))
			and	(STATUSFLAG      = @pnStatus            or (@pnStatus           is null and STATUSFLAG      is null))
			and	(EVENTDATEFLAG   = @pnEventDateFlag     or (@pnEventDateFlag    is null and EVENTDATEFLAG   is null))
			and	(EVENTNO         = @pnEventNo           or (@pnEventNo          is null and EVENTNO         is null))
			and	(INUSEFLAG       = @pbInUseFlag         or (@pbInUseFlag        is null and INUSEFLAG       is null))	
			and	(DEFERREDFLAG    = @pbDeferredFlag      or (@pbDeferredFlag     is null and DEFERREDFLAG    is null))
			and	(SUPPLIERFLAG	 = @pbSupplierFlag		or (@pbSupplierFlag		is null	and SUPPLIERFLAG is null))
			and	(USEDASFLAG		 = @pnUsedAsFlag	    or (@pnUsedAsFlag		is null	and USEDASFLAG is null))		
			and	(CATEGORY    =	   @psNameCategoryCode  or (@psNameCategoryCode is null and CATEGORY    is null))
			and	(COLUMNNAME      = @pnColumnName        or (@pnColumnName       is null and COLUMNNAME      is null))
			and	(OFFICEID        = @pnOfficeID          or (@pnOfficeID         is null and OFFICEID        is null))
			and	(LOCALCLIENTFLAG = @pbLocalClientFlag   or (@pbLocalClientFlag  is null and LOCALCLIENTFLAG is null))	
			and	(FAMILYNO        = @pnFamilyNo          or (@pnFamilyNo         is null and FAMILYNO        is null))	
			and	(NAMENO          = @pnNameNo            or (@pnNameNo           is null and NAMENO          is null))		
			and	(NAMETYPE        = @psNameType          or (@psNameType         is null and NAMETYPE        is null))
			and	(INSTRUCTIONTYPE = @psInstructionType   or (@psInstructionType  is null and INSTRUCTIONTYPE is null))	
			and	(FLAGNUMBER      = @pnFlagNo            or (@pnFlagNo           is null and FLAGNUMBER      is null))
			and	(ITEM_ID         = @pnItemID            or (@pnItemID           is null and ITEM_ID         is null))
			and	(DISPLAYMESSAGE  = @psDisplayMessage    or (@psDisplayMessage   is null and DISPLAYMESSAGE  is null))
			and	(NOTCASETYPE     = @pbNotCaseType       or (@pbNotCaseType      is null and NOTCASETYPE     is null))
			and	(NOTPROPERTYTYPE = @pbNotPropertyType   or (@pbNotPropertyType  is null and NOTPROPERTYTYPE is null))
			and	(NOTCASECATEGORY = @pbNotCaseCategory   or (@pbNotCaseCategory  is null and NOTCASECATEGORY is null))
			and	(NOTCOUNTRYCODE  = @pbNotCountryCode    or (@pbNotCountryCode   is null and NOTCOUNTRYCODE  is null))
			and	(NOTSUBTYPE      = @pbNotSubType        or (@pbNotSubType       is null and NOTSUBTYPE      is null))
			and	(NOTBASIS        = @pbNotBasis          or (@pbNotBasis         is null and NOTBASIS        is null))
			and	 VALIDATIONID   != @pnValidationID 
			and	 FUNCTIONALAREA  = @psFunctionalArea)
	Begin
		SET @message_string = 'Cannot insert duplicate DATAVALIDATION.'  
		RAISERROR(@message_string, 16, 1)
		Set @nErrorCode = @@Error
	End
End
If @nErrorCode = 0
Begin
	If not exists (Select 1 from DATAVALIDATION 
			   where VALIDATIONID = @pnValidationID and (LOGDATETIMESTAMP = @pdtLastUpdatedDate or LOGDATETIMESTAMP is NULL))
	Begin		
		
		SET @message_string = 'Concurrency violation: The Update command affected 0 records.'  
		RAISERROR(@message_string, 16, 1)
	End
	Else if (@pbBulkUpdate is null or @pbBulkUpdate =0)
	Begin	
		Set @sSQLString = "
				Update  DATAVALIDATION 
				Set	CASETYPE = @psCaseTypeCode	,		
					CASECATEGORY = @psCaseCategoryCode,		
					PROPERTYTYPE = @psPropertyTypeCode,		
					COUNTRYCODE = @psCountryCode,		
					SUBTYPE = @psSubTypeCode,		
					BASIS = @psBasis,
					STATUSFLAG = @pnStatus,
					EVENTDATEFLAG = @pnEventDateFlag,
					EVENTNO = @pnEventNo,
					INUSEFLAG = @pbInUseFlag,	
					DEFERREDFLAG = @pbDeferredFlag,
					CATEGORY = @psNameCategoryCode,
					COLUMNNAME = @pnColumnName,
					OFFICEID = @pnOfficeID,
					LOCALCLIENTFLAG = @pbLocalClientFlag,
					FAMILYNO = @pnFamilyNo,
					NAMENO = @pnNameNo,	
					NAMETYPE = @psNameType,
					INSTRUCTIONTYPE = @psInstructionType,
					FLAGNUMBER = @pnFlagNo,
					WARNINGFLAG = @pbWarningFlag,
					ROLEID	= @pnRoleID,
					ITEM_ID	= @pnItemID	,
					DISPLAYMESSAGE	= @psDisplayMessage,
					RULEDESCRIPTION	= @psRuleDescription,	
					NOTES = @psNotes,
					USEDASFLAG = @pnUsedAsFlag,
					SUPPLIERFLAG = @pbSupplierFlag,
					NOTCASETYPE = @pbNotCaseType,
					NOTPROPERTYTYPE = @pbNotPropertyType, 
					NOTCASECATEGORY = @pbNotCaseCategory, 
					NOTCOUNTRYCODE = @pbNotCountryCode,
					NOTSUBTYPE = @pbNotSubType,
					NOTBASIS = @pbNotBasis					
				where VALIDATIONID = @pnValidationID
				and FUNCTIONALAREA = @psFunctionalArea
				and (LOGDATETIMESTAMP = @pdtLastUpdatedDate or @pdtLastUpdatedDate is null)"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnValidationID	int,	
					@psFunctionalArea	nvarchar(1),
					@psCaseTypeCode		nvarchar(1),		
					@psCaseCategoryCode	nvarchar(2),		
					@psPropertyTypeCode	nvarchar(1),		
					@psCountryCode		nvarchar(3),		
					@psSubTypeCode		nvarchar(2),		
					@psBasis		nvarchar(2),
					@pnStatus     		smallint,
					@pnEventDateFlag	smallint,
					@pnEventNo		int,
					@pbInUseFlag		bit,
					@pbDeferredFlag		bit,
					@psNameCategoryCode int,
					@pnColumnName		int,
					@pnOfficeID		int,
					@pbLocalClientFlag	bit,
					@pnFamilyNo		smallint,
					@pnNameNo		int,
					@psNameType		nvarchar(3),
					@psInstructionType	nvarchar(3),
					@pnFlagNo		smallint,
					@pbWarningFlag		bit,
					@pnRoleID		int,
					@pnItemID		int,
					@psDisplayMessage	nvarchar(max),
					@psRuleDescription	nvarchar(254),
					@psNotes		nvarchar(254),
					@pnUsedAsFlag			smallint,
					@pbSupplierFlag			bit,
					@pbNotCaseType          bit,
					@pbNotPropertyType      bit,
					@pbNotCountryCode       bit,
					@pbNotCaseCategory      bit,
					@pbNotBasis             bit,
					@pbNotSubType           bit,
					@pdtLastUpdatedDate	datetime',		
					@pnValidationID		= @pnValidationID,	
					@psFunctionalArea       = @psFunctionalArea,			
					@psCaseTypeCode		= @psCaseTypeCode,		
					@psCaseCategoryCode	= @psCaseCategoryCode,		
					@psPropertyTypeCode	= @psPropertyTypeCode,		
					@psCountryCode		= @psCountryCode,		
					@psSubTypeCode		= @psSubTypeCode,		
					@psBasis		= @psBasis,
					@pnStatus		= @pnStatus,
					@pnEventDateFlag	= @pnEventDateFlag,
					@pnEventNo		= @pnEventNo,
					@pbInUseFlag		= @pbInUseFlag,
					@pbDeferredFlag		= @pbDeferredFlag,
					@psNameCategoryCode = @psNameCategoryCode,
					@pnColumnName		= @pnColumnName,
					@pnOfficeID		= @pnOfficeID,
					@pbLocalClientFlag	= @pbLocalClientFlag,
					@pnFamilyNo		= @pnFamilyNo,
					@pnNameNo		= @pnNameNo,
					@psNameType		= @psNameType,
					@psInstructionType	= @psInstructionType,
					@pnFlagNo		= @pnFlagNo,	
					@pbWarningFlag		= @pbWarningFlag,
					@pnRoleID		= @pnRoleID,
					@pnItemID		= @pnItemID	,
					@psDisplayMessage	= @psDisplayMessage,
					@psRuleDescription	= @psRuleDescription,	
					@psNotes		= @psNotes,
					@pnUsedAsFlag			= @pnUsedAsFlag,
					@pbSupplierFlag			= @pbSupplierFlag,
					@pbNotCaseType          = @pbNotCaseType,
					@pbNotPropertyType      = @pbNotPropertyType,
					@pbNotCountryCode       = @pbNotCountryCode,
					@pbNotCaseCategory      = @pbNotCaseCategory,
					@pbNotBasis             = @pbNotBasis,
					@pbNotSubType           = @pbNotSubType,
					@pdtLastUpdatedDate	= @pdtLastUpdatedDate		
	End
	Else if (@pbBulkUpdate = 1)
	Begin
		Set @sSQLString = "
				Update  DATAVALIDATION 
				Set INUSEFLAG = @pbInUseFlag,	
					DEFERREDFLAG = @pbDeferredFlag,
					WARNINGFLAG = @pbWarningFlag,
					SUPPLIERFLAG = @pbSupplierFlag"		
		if(@pbWarningFlag = 1)
		Begin 
			Set @sSQLString = @sSQLString + ",ROLEID = null"
		End
				
		Set @sSQLString = @sSQLString + " where VALIDATIONID = @pnValidationID
					and FUNCTIONALAREA = @psFunctionalArea
					and (LOGDATETIMESTAMP = @pdtLastUpdatedDate or @pdtLastUpdatedDate is null)"	
	
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnValidationID	int,
					@psFunctionalArea	nvarchar(1),	
					@pbInUseFlag		bit,
					@pbDeferredFlag		bit,
					@pbWarningFlag		bit,
					@pbSupplierFlag     bit,
					@pdtLastUpdatedDate	datetime',		
					@pnValidationID		= @pnValidationID,	
					@psFunctionalArea	= @psFunctionalArea,					
					@pbInUseFlag		= @pbInUseFlag,
					@pbDeferredFlag		= @pbDeferredFlag,				   
					@pbWarningFlag		= @pbWarningFlag,
					@pbSupplierFlag		= @pbSupplierFlag,					
					@pdtLastUpdatedDate	= @pdtLastUpdatedDate	
	End

End

Return @nErrorCode
go

Grant exec on dbo.ipw_UpdateDataValidation to Public
go