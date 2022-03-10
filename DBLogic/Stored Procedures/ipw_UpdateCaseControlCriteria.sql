-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateCaseControlCriteria
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateCaseControlCriteria]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateCaseControlCriteria.'
	Drop procedure [dbo].[ipw_UpdateCaseControlCriteria]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateCaseControlCriteria...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.ipw_UpdateCaseControlCriteria
(
	@pnUserIdentityId		int,
	@psCulture			nvarchar(10) 		= null,
	@pnCriteriaNo			int,		
	@pnCaseOfficeKey		int			= null,
	@psProgramID			nvarchar(8)		= null,
	@psCountryCode			nvarchar(3)		= null,
	@psCaseCategoryCode		nvarchar(2)		= null,
	@psSubTypeCode			nvarchar(2)		= null,
	@psPropertyTypeCode		nvarchar(1)		= null,
	@psCaseTypeCode			nvarchar(1)		= null,
	@psApplicationBasisCode		nvarchar(2)		= null,
	@pnUseCaseKey			int			= null,
	@psCriteriaName			nvarchar(254)		= null,
	@pnOldCaseOfficeKey		int			= null,
	@psOldProgramID			nvarchar(8)		= null,
	@psOldCountryCode		nvarchar(3)		= null,
	@psOldCaseCategoryCode		nvarchar(2)		= null,
	@psOldSubTypeCode		nvarchar(2)		= null,
	@psOldPropertyTypeCode		nvarchar(1)		= null,
	@psOldCaseTypeCode		nvarchar(1)		= null,
	@psOldApplicationBasisCode	nvarchar(2)		= null,
	@psOldCriteriaName		nvarchar(254)		= null,
	@pbOldRuleInUse			bit			=0,
	@pbCountryUnknown		bit			= null,
	@pbCategoryUnknown		bit			= null,
	@pbSubTypeUnknown		bit			= null,
	@pbPropertyUnknown		bit			= null,
	@pbRuleInUse			bit			= 0,
	@pbUserDefinedRule		bit			= 0,
	@pnIsCaseOfficeKeyInUse		bit			= 0,
	@psIsProgramIDInUse		bit			= 0,
	@psIsCountryCodeInUse		bit			= 0,
	@psIsCaseCategoryCodeInUse	bit			= 0,
	@psIsSubTypeCodeInUse		bit			= 0,
	@psIsPropertyTypeCodeInUse	bit			= 0,
	@psIsCaseTypeCodeInUse		bit			= 0,
	@psIsApplicationBasisCodeInUse	bit			= 0,
	@psIsCriteriaNameInUse		bit			= 0,
	@pbRuleInUseInUse		bit			= 0,
	@pnProfileKey			int			= null,
	@pnOldProfileKey		int			= null,
	@pbIsProfileKeyInUse		bit			= 0
)
as

-- PROCEDURE:	ipw_UpdateCaseControlCriteria
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update Case Windows Criteria if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 20 Nov 2008	NG	RFC6921	1	Procedure created
-- 04 Spe 2009  MS	RFC7085 2	Removed CriteriaName from If selection
-- 11 Sep 2009	LP	RFC8047	2	Added ProfileKey parameter.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sUpdateString 	nvarchar(4000)
Declare @sWhereString		nvarchar(4000)
Declare @sComma			nchar(1)
Declare @sAnd			nchar(5)
Declare @sAlertXML		nvarchar(400)

-- Initialise variables
Set @nErrorCode = 0
Set @sComma = " "
Set @sAnd = " and "
Set @sWhereString = CHAR(10)+" where "

If @nErrorCode = 0
Begin
	If not(@pnCaseOfficeKey			= @pnOldCaseOfficeKey		
		and @psProgramID		= @psOldProgramID			 
		and @psCountryCode		= @psOldCountryCode			 
		and @psCaseCategoryCode		= @psOldCaseCategoryCode		 
		and @psSubTypeCode		= @psOldSubTypeCode			 
		and @psPropertyTypeCode		= @psOldPropertyTypeCode		 
		and @psCaseTypeCode		= @psOldCaseTypeCode			
		and @psApplicationBasisCode	= @psOldApplicationBasisCode	
		and (@psCriteriaName <> @psOldCriteriaName or @pbRuleInUse <> @pbOldRuleInUse)
		and @pnProfileKey		= @pnOldProfileKey
		)
	Begin
		If exists(select 1 from CRITERIA
				WHERE 
				(PURPOSECODE = 'W')
				and (CASETYPE = @psCaseTypeCode)
				and (PROGRAMID = @psProgramID)
				and (PROPERTYTYPE = @psPropertyTypeCode)
				and (COUNTRYCODE = @psCountryCode)
				and (CASECATEGORY = @psCaseCategoryCode)
				and (SUBTYPE = @psSubTypeCode)
				and (BASIS = @psApplicationBasisCode)
				and (CASEOFFICEID = @pnCaseOfficeKey)
				and (COUNTRYUNKNOWN = @pbCountryUnknown)
				and (PROPERTYUNKNOWN = @pbPropertyUnknown)
				and	(CATEGORYUNKNOWN = @pbCategoryUnknown)
				and (SUBTYPEUNKNOWN = @pbSubTypeUnknown)
				and (PROFILEID = @pnProfileKey))
		Begin
			Set @sAlertXML = dbo.fn_GetAlertXML('IP88', 'The criteria already exists.', null, null, null, null, null)
				RAISERROR(@sAlertXML, 12, 1)
				Set @nErrorCode = 1
		End
	End
End

If @nErrorCode = 0
Begin

	Set @sUpdateString = "Update CRITERIA
					set "
	
	Set @sWhereString = @sWhereString+CHAR(10)+"
				CRITERIANO = @pnCriteriaNo "

	If @pnIsCaseOfficeKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CASEOFFICEID = @pnCaseOfficeKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"CASEOFFICEID = @pnOldCaseOfficeKey"
		Set @sComma = ","
		Set @sAnd = " and "
	End	

	If @psIsProgramIDInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"PROGRAMID = @psProgramID"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"PROGRAMID = @psOldProgramID"
		Set @sComma = ","
		Set @sAnd = " and "
	End	

	If @psIsCountryCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"COUNTRYCODE = @psCountryCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"COUNTRYCODE = @psOldCountryCode"
		Set @sComma = ","
		Set @sAnd = " and "
	End	

	If @psIsCaseCategoryCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CASECATEGORY = @psCaseCategoryCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"CASECATEGORY = @psOldCaseCategoryCode"
		Set @sComma = ","
		Set @sAnd = " and "
	End	

	If @psIsSubTypeCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"SUBTYPE = @psSubTypeCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"SUBTYPE = @psOldSubTypeCode"
		Set @sComma = ","
		Set @sAnd = " and "
	End	

	If @psIsPropertyTypeCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"PROPERTYTYPE = @psPropertyTypeCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"PROPERTYTYPE = @psOldPropertyTypeCode"
		Set @sComma = ","
		Set @sAnd = " and "
	End	

	If @psIsCaseTypeCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CASETYPE = @psCaseTypeCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"CASETYPE = @psOldCaseTypeCode"
		Set @sComma = ","
		Set @sAnd = " and "
	End	

	If @psIsApplicationBasisCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"BASIS = @psApplicationBasisCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"BASIS = @psOldApplicationBasisCode"
		Set @sComma = ","
		Set @sAnd = " and "
	End	

	If @psIsCriteriaNameInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"DESCRIPTION = @psCriteriaName"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"DESCRIPTION = @psOldCriteriaName"
		Set @sComma = ","
		Set @sAnd = " and "
	End
	
	If @pbIsProfileKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"PROFILEID = @pnProfileKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"PROFILEID = @pnOldProfileKey"
		Set @sComma = ","
		Set @sAnd = " and "
	End	

	
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"COUNTRYUNKNOWN = @pbCountryUnknown"
		Set @sComma = ","
		Set @sAnd = " and "
	End	

	
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CATEGORYUNKNOWN = @pbCategoryUnknown"
		Set @sComma = ","
		Set @sAnd = " and "
	End	

	
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"SUBTYPEUNKNOWN = @pbSubTypeUnknown"
		Set @sComma = ","
		Set @sAnd = " and "
	End	

	
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"PROPERTYUNKNOWN = @pbPropertyUnknown"
		Set @sComma = ","
		Set @sAnd = " and "
	End	

	
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"RULEINUSE = @pbRuleInUse"
		Set @sComma = ","
		Set @sAnd = " and "
	End	

	
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"USERDEFINEDRULE = @pbUserDefinedRule"
		Set @sComma = ","
		Set @sAnd = " and "
	End	

	Set @sSQLString = @sUpdateString + @sWhereString

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnCriteriaNo			int,		
				@pnCaseOfficeKey		int,		
				@psProgramID			nvarchar(8),	
				@psCountryCode			nvarchar(3),		
				@psCaseCategoryCode		nvarchar(2),
				@psSubTypeCode			nvarchar(2),
				@psPropertyTypeCode		nvarchar(1),
				@psCaseTypeCode			nvarchar(1),
				@psApplicationBasisCode	nvarchar(2),
				@psCriteriaName			nvarchar(254),
				@pnProfileKey			int,
				@pnOldCaseOfficeKey		int,
				@psOldProgramID			nvarchar(8),
				@psOldCountryCode			nvarchar(3),
				@psOldCaseCategoryCode		nvarchar(2),
				@psOldSubTypeCode			nvarchar(2),
				@psOldPropertyTypeCode		nvarchar(1),
				@psOldCaseTypeCode			nvarchar(1),
				@psOldApplicationBasisCode	nvarchar(2),
				@psOldCriteriaName			nvarchar(254),
				@pnOldProfileKey		int,
				@pbCountryUnknown		bit,
				@pbCategoryUnknown		bit,
				@pbSubTypeUnknown		bit,
				@pbPropertyUnknown		bit,
				@pbRuleInUse			bit,
				@pbUserDefinedRule		bit',
				@pnCriteriaNo	=	@pnCriteriaNo,		
				@pnCaseOfficeKey = @pnCaseOfficeKey	,		
				@psProgramID	=	@psProgramID,	
				@psCountryCode	=	@psCountryCode,		
				@psCaseCategoryCode	= @psCaseCategoryCode,
				@psSubTypeCode		=	@psSubTypeCode,
				@psPropertyTypeCode	=	@psPropertyTypeCode	,
				@psCaseTypeCode		=	@psCaseTypeCode,
				@psApplicationBasisCode = @psApplicationBasisCode,
				@psCriteriaName			= @psCriteriaName,
				@pnProfileKey			= @pnProfileKey,
				@pnOldCaseOfficeKey		= @pnOldCaseOfficeKey,
				@psOldProgramID			= @psOldProgramID,
				@psOldCountryCode		=	@psOldCountryCode,
				@psOldCaseCategoryCode	=	@psOldCaseCategoryCode,
				@psOldSubTypeCode		=	@psOldSubTypeCode,
				@psOldPropertyTypeCode	=	@psOldPropertyTypeCode,
				@psOldCaseTypeCode		=	@psOldCaseTypeCode,
				@psOldApplicationBasisCode =	@psOldApplicationBasisCode,
				@psOldCriteriaName		=	@psOldCriteriaName,
				@pnOldProfileKey		= @pnOldProfileKey,
				@pbCountryUnknown		= @pbCountryUnknown	,
				@pbCategoryUnknown		= @pbCategoryUnknown,
				@pbSubTypeUnknown		=	@pbSubTypeUnknown,
				@pbPropertyUnknown		= @pbPropertyUnknown,
				@pbRuleInUse			=	@pbRuleInUse,
				@pbUserDefinedRule		= @pbUserDefinedRule

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateCaseControlCriteria to public
GO
