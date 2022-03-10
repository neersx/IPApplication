-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertCaseControlCriteria
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertCaseControlCriteria]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertCaseControlCriteria.'
	Drop procedure [dbo].[ipw_InsertCaseControlCriteria]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertCaseControlCriteria...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_InsertCaseControlCriteria
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,	
	@pnCriteriaNo			int				= null		output,
	@pnCaseOfficeKey		int				= null,
	@psProgramID			nvarchar(8)		= null,
	@psCountryCode			nvarchar(3)		= null,
	@psCaseCategoryCode		nvarchar(2)		= null,
	@psSubTypeCode			nvarchar(2)		= null,
	@psPropertyTypeCode		nvarchar(1)		= null,
	@psCaseTypeCode			nvarchar(1)		= null,
	@psApplicationBasisCode	nvarchar(2)		= null,
	@pnUseCaseKey			int				= null,
	@psCriteriaName			nvarchar(254)		= null,
	@pbCountryUnknown		bit				= 0,
	@pbCategoryUnknown		bit				= 0,
	@pbSubTypeUnknown		bit				= 0,
	@pbPropertyUnknown		bit				= 0,
	@pbRuleInUse			bit				= 0,
	@pbIsCPASSRule			bit				= 0,
	@pnProfileKey			int			= null
)
as
-- PROCEDURE:	ipw_InsertCaseControlCriteria
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert new records in CRITERIA

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 20 Nov 2008	NG	RFC6921	1	Procedure created
-- 11 Sep 2009	LP	RFC8047	2	Added new ProfileKey parameter
-- 21 Dec 2009	KR	RFC8704 3	Added USERDEFINEDRULE to the duplicate check list


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString	nvarchar(4000)
declare @sInsertString 	nvarchar(4000)
declare @sValuesString	nvarchar(4000)
declare @bUserDefinedRule	bit
declare @sAlertXML		nvarchar(400)


-- Initialise variables
Set @nErrorCode 	= 0

If @pbIsCPASSRule = 0
	Set @bUserDefinedRule = 1
Else
	Set @bUserDefinedRule = 0
	
If @nErrorCode = 0
Begin
	if exists(select 1 from CRITERIA
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
				and (CATEGORYUNKNOWN = @pbCategoryUnknown)
				and (SUBTYPEUNKNOWN = @pbSubTypeUnknown)
				and (PROFILEID = @pnProfileKey)
				and (USERDEFINEDRULE = @bUserDefinedRule))
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('IP88', 'The criteria already exists.', null, null, null, null, null)
			RAISERROR(@sAlertXML, 12, 1)
			Set @nErrorCode = 1
	End
End


If @nErrorCode = 0 and @pbIsCPASSRule = 0
Begin
	exec @nErrorCode = dbo.ip_GetLastInternalCode
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@psTable		= N'CRITERIA',
			@pnLastInternalCode	= @pnCriteriaNo OUTPUT	
End

Else if @nErrorCode = 0 and @pbIsCPASSRule = 1
Begin
	exec @nErrorCode = dbo.ip_GetLastInternalCode
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@psTable		= N'CRITERIA_MAXIM',
			@pbIsInternalCodeNegative	= 1,
			@pnLastInternalCode	= @pnCriteriaNo OUTPUT	
End 

If @nErrorCode = 0
Begin
	Set @sInsertString = "insert into CRITERIA (CRITERIANO,PURPOSECODE"
	Set @sValuesString = CHAR(10)+" values (@pnCriteriaNo,'W'"
	
	if @psCaseTypeCode is not null
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",CASETYPE"
		Set @sValuesString = @sValuesString+CHAR(10)+",@psCaseTypeCode"
	End

	if @psProgramID is not null
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",PROGRAMID"
		Set @sValuesString = @sValuesString+CHAR(10)+",@psProgramID"
	End

	if @psPropertyTypeCode is not null 
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",PROPERTYTYPE"
		Set @sValuesString = @sValuesString+CHAR(10)+",@psPropertyTypeCode"
	End

	if @pbPropertyUnknown is not null 
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",PROPERTYUNKNOWN"
		Set @sValuesString = @sValuesString+CHAR(10)+",@pbPropertyUnknown"
	End

	if @psCountryCode is not null 
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",COUNTRYCODE"
		Set @sValuesString = @sValuesString+CHAR(10)+",@psCountryCode"
	End

	if @pbCountryUnknown is not null 
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",COUNTRYUNKNOWN"
		Set @sValuesString = @sValuesString+CHAR(10)+",@pbCountryUnknown"
	End

	if @psCaseCategoryCode is not null 
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",CASECATEGORY"
		Set @sValuesString = @sValuesString+CHAR(10)+",@psCaseCategoryCode"
	End

	if @pbCategoryUnknown is not null  
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",CATEGORYUNKNOWN"
		Set @sValuesString = @sValuesString+CHAR(10)+",@pbCategoryUnknown"
	End

	if @psSubTypeCode is not null 
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",SUBTYPE"
		Set @sValuesString = @sValuesString+CHAR(10)+",@psSubTypeCode"
	End

	if @pbSubTypeUnknown is not null 
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",SUBTYPEUNKNOWN"
		Set @sValuesString = @sValuesString+CHAR(10)+",@pbSubTypeUnknown"
	End

	if @psApplicationBasisCode is not null 
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",BASIS"
		Set @sValuesString = @sValuesString+CHAR(10)+",@psApplicationBasisCode"
	End


	Set @sInsertString = @sInsertString+CHAR(10)+",USERDEFINEDRULE"
	Set @sValuesString = @sValuesString+CHAR(10)+",@bUserDefinedRule"
	

	Set @sInsertString = @sInsertString+CHAR(10)+",RULEINUSE"
	Set @sValuesString = @sValuesString+CHAR(10)+",@pbRuleInUse"
	

	if @psCriteriaName is not null 
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",DESCRIPTION"
		Set @sValuesString = @sValuesString+CHAR(10)+",@psCriteriaName"
	End

	if @pnCaseOfficeKey is not null 
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",CASEOFFICEID"
		Set @sValuesString = @sValuesString+CHAR(10)+",@pnCaseOfficeKey"
	End
	
	if @pnProfileKey is not null 
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",PROFILEID"
		Set @sValuesString = @sValuesString+CHAR(10)+",@pnProfileKey"
	End

	
	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

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
					@pbCountryUnknown		bit,
					@pbCategoryUnknown		bit,
					@pbSubTypeUnknown		bit,
					@pbPropertyUnknown		bit,
					@pbRuleInUse			bit,
					@bUserDefinedRule		bit,
					@pnProfileKey			int',
					@pnCriteriaNo	= @pnCriteriaNo,
					@pnCaseOfficeKey = @pnCaseOfficeKey,
					@psProgramID = @psProgramID,
					@psCountryCode	= @psCountryCode,
					@psCaseCategoryCode	= @psCaseCategoryCode,
					@psSubTypeCode	= @psSubTypeCode,
					@psPropertyTypeCode	= @psPropertyTypeCode,
					@psCaseTypeCode	= @psCaseTypeCode,
					@psApplicationBasisCode	= @psApplicationBasisCode,
					@psCriteriaName	= @psCriteriaName,
					@pbCountryUnknown	= @pbCountryUnknown,
					@pbCategoryUnknown	= @pbCategoryUnknown,
					@pbSubTypeUnknown	= @pbSubTypeUnknown,
					@pbPropertyUnknown	= @pbPropertyUnknown,
					@pbRuleInUse= @pbRuleInUse,
					@bUserDefinedRule	= @bUserDefinedRule,
					@pnProfileKey	= @pnProfileKey	

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertCaseControlCriteria to public
GO
