-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertDataValidation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertDataValidation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertDataValidation.'
	Drop procedure [dbo].[ipw_InsertDataValidation]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertDataValidation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_InsertDataValidation
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,			
	@pbCalledFromCentura	bit		= 0,
	@psFunctionalArea       nvarchar(1),    -- Mandatory
	@psCaseTypeCode		nvarchar(1)	= null,		
	@psCaseCategoryCode	nvarchar(2)	= null,		
	@psCategory int	= null,
	@psPropertyTypeCode	nvarchar(1)	= null,		
	@psCountryCode		nvarchar(3)	= null,		
	@psSubTypeCode		nvarchar(2)	= null,		
	@psBasis		nvarchar(2)     = null,	
	@pnStatus		smallint        = null,	
	@pnEventDateFlag	smallint        = null,	
	@pnEventNo		int		= null,	
	@pnUsedAsFlag   int     = null,
	@pbSupplierFlag  bit    = null,
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
	@psDisplayMessage	nvarchar(max)   = null,	
	@psNotes		nvarchar(max)   = null,	
	@psRuleDescription	nvarchar(254)   = null,
	@pbNotCaseType          bit             = null,
        @pbNotPropertyType      bit             = null,
        @pbNotCountryCode       bit             = null,
        @pbNotCaseCategory      bit             = null,
        @pbNotBasis             bit             = null,
        @pbNotSubType           bit             = null
)
as
-- PROCEDURE:	ipw_InsertDataValidation
-- VERSION:	4
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Procedure to insert Data Validation Rule
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 29 Sep 2010  DV	R9387	1	Procedure created
-- 17 May 2011  DV	R10157  2       Insert the value of NOT columns
-- 04 Aug 2011	MF	R11077	3	Correct the duplicate test to also check the Display Message and the ItemId associated.
-- 19 Jan 2012  DV   R11778  4       Fixed issue with save of Not values
-- 06 Jun 2012  ASH R9757   5    Insert values for Functional Area NAME.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(max)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0

If @nErrorCode = 0
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
			and	(COLUMNNAME      = @pnColumnName        or (@pnColumnName       is null and COLUMNNAME      is null))
			and	(OFFICEID        = @pnOfficeID          or (@pnOfficeID         is null and OFFICEID        is null))
			and	(LOCALCLIENTFLAG = @pbLocalClientFlag   or (@pbLocalClientFlag  is null and LOCALCLIENTFLAG is null))
			and	(CATEGORY =        @psCategory			or	(@psCategory			is null and CATEGORY is null))
			and	(SUPPLIERFLAG	 = @pbSupplierFlag		or (@pbSupplierFlag		is null	and SUPPLIERFLAG is null))
			and	(USEDASFLAG		 = @pnUsedAsFlag	    or (@pnUsedAsFlag		is null	and USEDASFLAG is null))		
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
			and	 FUNCTIONALAREA  = @psFunctionalArea)			
					
	Begin		
		DECLARE @message_string VARCHAR(255)  
		SET @message_string = 'Cannot insert duplicate DATAVALIDATION.'  
		RAISERROR(@message_string, 16, 1)
	End
	Else
	Begin	
		Set @sSQLString = "
				Insert into  DATAVALIDATION 
						(CASETYPE,CASECATEGORY,PROPERTYTYPE, COUNTRYCODE, SUBTYPE, 
						BASIS, STATUSFLAG, EVENTDATEFLAG, EVENTNO, INUSEFLAG, DEFERREDFLAG,
						COLUMNNAME, OFFICEID, LOCALCLIENTFLAG,CATEGORY, USEDASFLAG, SUPPLIERFLAG, FAMILYNO, NAMENO, NAMETYPE,
						INSTRUCTIONTYPE, FLAGNUMBER, WARNINGFLAG, ROLEID, ITEM_ID, DISPLAYMESSAGE,
						RULEDESCRIPTION, NOTES, FUNCTIONALAREA, NOTCASETYPE, NOTPROPERTYTYPE, 
						NOTCASECATEGORY, NOTCOUNTRYCODE, NOTSUBTYPE, NOTBASIS)
				values (@psCaseTypeCode, @psCaseCategoryCode, @psPropertyTypeCode, @psCountryCode, @psSubTypeCode,
						@psBasis, @pnStatus, @pnEventDateFlag, @pnEventNo, @pbInUseFlag, @pbDeferredFlag, 
						@pnColumnName, @pnOfficeID, @pbLocalClientFlag, @psCategory, @pnUsedAsFlag, @pbSupplierFlag, @pnFamilyNo, @pnNameNo, @psNameType,
						@psInstructionType, @pnFlagNo, @pbWarningFlag, @pnRoleID, @pnItemID, @psDisplayMessage,
						@psRuleDescription, @psNotes, @psFunctionalArea, @pbNotCaseType, @pbNotPropertyType, 
						@pbNotCaseCategory, @pbNotCountryCode, @pbNotSubType, @pbNotBasis)"
				
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@psFunctionalArea		nvarchar(1),
						@psCaseTypeCode			nvarchar(1),		
						@psCaseCategoryCode			nvarchar(2),		
						@psPropertyTypeCode			nvarchar(1),		
						@psCountryCode				nvarchar(3),		
						@psSubTypeCode				nvarchar(2),		
						@psBasis				nvarchar(2),
						@pnStatus     				smallint,
						@pnEventDateFlag			smallint,
						@pnEventNo				int,
						@pbInUseFlag				bit,
						@pbDeferredFlag				bit,
						@pnColumnName				int,
						@pnOfficeID				int,
						@pbLocalClientFlag			bit,
						@psCategory				int,
						@pnUsedAsFlag			smallint,
						@pbSupplierFlag			bit,
						@pnFamilyNo				smallint,
						@pnNameNo				int,
						@psNameType				nvarchar(3),
						@psInstructionType			nvarchar(3),
						@pnFlagNo				smallint,
						@pbWarningFlag				bit,
						@pnRoleID				int,
						@pnItemID				int,
						@psDisplayMessage			nvarchar(max),
						@psRuleDescription			nvarchar(254),
						@psNotes				nvarchar(254),
						@pbNotCaseType                          bit,
						@pbNotPropertyType                      bit,
						@pbNotCountryCode                       bit,
						@pbNotCaseCategory                      bit,
						@pbNotBasis                             bit,
						@pbNotSubType                           bit',						
						@psFunctionalArea           = @psFunctionalArea,		
						@psCaseTypeCode				= @psCaseTypeCode,		
						@psCaseCategoryCode			= @psCaseCategoryCode,		
						@psPropertyTypeCode			= @psPropertyTypeCode,		
						@psCountryCode				= @psCountryCode,		
						@psSubTypeCode				= @psSubTypeCode,		
						@psBasis				= @psBasis,
						@pnStatus				= @pnStatus,
						@pnEventDateFlag			= @pnEventDateFlag,
						@pnEventNo				= @pnEventNo,
						@pbInUseFlag				= @pbInUseFlag,
						@pbDeferredFlag				= @pbDeferredFlag,
						@pnColumnName				= @pnColumnName,
						@pnOfficeID				= @pnOfficeID,
						@pbLocalClientFlag			= @pbLocalClientFlag,
						@psCategory				= @psCategory,
						@pnUsedAsFlag			= @pnUsedAsFlag,
						@pbSupplierFlag			= @pbSupplierFlag,
						@pnFamilyNo				= @pnFamilyNo,
						@pnNameNo				= @pnNameNo,
						@psNameType				= @psNameType,
						@psInstructionType			= @psInstructionType,
						@pnFlagNo				= @pnFlagNo,	
						@pbWarningFlag				= @pbWarningFlag,
						@pnRoleID				= @pnRoleID,
						@pnItemID				= @pnItemID	,
						@psDisplayMessage			= @psDisplayMessage,
						@psRuleDescription			= @psRuleDescription,
						@psNotes				= @psNotes,
						@pbNotCaseType                          = @pbNotCaseType,
						@pbNotPropertyType                      = @pbNotPropertyType,
						@pbNotCountryCode                       = @pbNotCountryCode ,
						@pbNotCaseCategory                      = @pbNotCaseCategory,
						@pbNotBasis                             = @pbNotBasis,
						@pbNotSubType                           = @pbNotSubType		
	End

End

Return @nErrorCode
go

Grant exec on dbo.ipw_InsertDataValidation to Public
go