-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertChecklistControlCriteria
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertChecklistControlCriteria]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertChecklistControlCriteria.'
	Drop procedure [dbo].[ipw_InsertChecklistControlCriteria]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertChecklistControlCriteria...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_InsertChecklistControlCriteria
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,	
	@pnCriteriaNo			int			= null		output,
	@pnCaseOfficeKey		int			= null,
	@pnChecklistTypeKey		int			= null,
	@psCountryCode			nvarchar(3)		= null,
	@psCaseCategoryCode		nvarchar(2)		= null,
	@psSubTypeCode			nvarchar(2)		= null,
	@psPropertyTypeCode		nvarchar(1)		= null,
	@psCaseTypeCode			nvarchar(1)		= null,
	@psApplicationBasisCode	nvarchar(2)			= null,
	@pnUseCaseKey			int			= null,
	@psCriteriaName			nvarchar(254)		= null,
	@pbLocalClientFlagYes		bit			= 0,
	@pbLocalClientFlagNo		bit			= 0,
	@pbRegisteredUsersOwners	bit			= 0,
	@pbRegisteredUsersOthers	bit			= 0,
	@pbRuleInUse			bit			= 0,
	@pbIsCPASSRule			bit			= 0,
	@pnProfileKey			int			= null
)
as
-- PROCEDURE:	ipw_InsertChecklistControlCriteria
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert new records in CRITERIA

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 Oct 2010	KR	RFC9193	1	Procedure created



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
declare @bLocalClientFlag	bit
declare	@sRegisteredUsers	char(2)


-- Initialise variables
Set @nErrorCode 	= 0

If @pbIsCPASSRule = 0
	Set @bUserDefinedRule = 1
Else
	Set @bUserDefinedRule = 0

if @pbLocalClientFlagYes = 1
	Set @bLocalClientFlag = 1
else if @pbLocalClientFlagNo = 1
	Set @bLocalClientFlag = 0
else
	Set @bLocalClientFlag = NULL

if @pbRegisteredUsersOwners = 1 and @pbRegisteredUsersOthers = 1
	Set @sRegisteredUsers = 'B'
else if @pbRegisteredUsersOwners = 1
	Set @sRegisteredUsers = 'Y'
else if @pbRegisteredUsersOthers = 1
	Set @sRegisteredUsers = 'N'
else
	Set @sRegisteredUsers = null

	
If @nErrorCode = 0
Begin
	if exists(select 1 from CRITERIA
				WHERE 
				(PURPOSECODE = 'C')
				and (CASETYPE = @psCaseTypeCode)
				and (CHECKLISTTYPE = @pnChecklistTypeKey)
				and (PROPERTYTYPE = @psPropertyTypeCode)
				and (COUNTRYCODE = @psCountryCode)
				and (CASECATEGORY = @psCaseCategoryCode)
				and (SUBTYPE = @psSubTypeCode)
				and (BASIS = @psApplicationBasisCode)
				and (CASEOFFICEID = @pnCaseOfficeKey)
				and (LOCALCLIENTFLAG = @bLocalClientFlag)
				and (REGISTEREDUSERS = @sRegisteredUsers)
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
	Set @sValuesString = CHAR(10)+" values (@pnCriteriaNo,'C'"
	
	if @psCaseTypeCode is not null
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",CASETYPE"
		Set @sValuesString = @sValuesString+CHAR(10)+",@psCaseTypeCode"
	End

	if @pnChecklistTypeKey is not null
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",CHECKLISTTYPE"
		Set @sValuesString = @sValuesString+CHAR(10)+",@pnChecklistTypeKey"
	End

	if @psPropertyTypeCode is not null 
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",PROPERTYTYPE"
		Set @sValuesString = @sValuesString+CHAR(10)+",@psPropertyTypeCode"
	End



	if @psCountryCode is not null 
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",COUNTRYCODE"
		Set @sValuesString = @sValuesString+CHAR(10)+",@psCountryCode"
	End

	if @psCaseCategoryCode is not null 
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",CASECATEGORY"
		Set @sValuesString = @sValuesString+CHAR(10)+",@psCaseCategoryCode"
	End

	if @psSubTypeCode is not null 
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",SUBTYPE"
		Set @sValuesString = @sValuesString+CHAR(10)+",@psSubTypeCode"
	End

	if @psApplicationBasisCode is not null 
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",BASIS"
		Set @sValuesString = @sValuesString+CHAR(10)+",@psApplicationBasisCode"
	End


	Set @sInsertString = @sInsertString+CHAR(10)+",USERDEFINEDRULE"
	Set @sValuesString = @sValuesString+CHAR(10)+",@bUserDefinedRule"
	
	if @bLocalClientFlag is not null 
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",LOCALCLIENTFLAG"
		Set @sValuesString = @sValuesString+CHAR(10)+",@bLocalClientFlag"
	End
	
	if @sRegisteredUsers is not null 
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+",REGISTEREDUSERS"
		Set @sValuesString = @sValuesString+CHAR(10)+",@sRegisteredUsers"
	End	
	
	
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
					@pnChecklistTypeKey		int,
					@psCountryCode			nvarchar(3),
					@psCaseCategoryCode		nvarchar(2),
					@psSubTypeCode			nvarchar(2),
					@psPropertyTypeCode		nvarchar(1),
					@psCaseTypeCode			nvarchar(1),
					@psApplicationBasisCode	nvarchar(2),
					@psCriteriaName			nvarchar(254),
					@bLocalClientFlag		bit,
					@sRegisteredUsers		nchar(2),
					@pbRuleInUse			bit,
					@bUserDefinedRule		bit,
					@pnProfileKey			int',
					@pnCriteriaNo	= @pnCriteriaNo,
					@pnCaseOfficeKey = @pnCaseOfficeKey,
					@pnChecklistTypeKey = @pnChecklistTypeKey,
					@psCountryCode	= @psCountryCode,
					@psCaseCategoryCode	= @psCaseCategoryCode,
					@psSubTypeCode	= @psSubTypeCode,
					@psPropertyTypeCode	= @psPropertyTypeCode,
					@psCaseTypeCode	= @psCaseTypeCode,
					@psApplicationBasisCode	= @psApplicationBasisCode,
					@psCriteriaName	= @psCriteriaName,
					@bLocalClientFlag	= @bLocalClientFlag,
					@sRegisteredUsers	= @sRegisteredUsers,
					@pbRuleInUse= @pbRuleInUse,
					@bUserDefinedRule	= @bUserDefinedRule,
					@pnProfileKey	= @pnProfileKey	

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertChecklistControlCriteria to public
GO
