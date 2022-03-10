-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateChecklistControlCriteria
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateChecklistControlCriteria]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateChecklistControlCriteria.'
	Drop procedure [dbo].[ipw_UpdateChecklistControlCriteria]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateChecklistControlCriteria....'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.ipw_UpdateChecklistControlCriteria
(
	@pnUserIdentityId		int,
	@psCulture			nvarchar(10) 		= null,
	@pnCriteriaNo			int,		
	@pnCaseOfficeKey		int			= null,
	@pnChecklistTypeKey		int			= null,
	@psCountryCode			nvarchar(3)		= null,
	@psCaseCategoryCode		nvarchar(2)		= null,
	@psSubTypeCode			nvarchar(2)		= null,
	@psPropertyTypeCode		nvarchar(1)		= null,
	@psCaseTypeCode			nvarchar(1)		= null,
	@psApplicationBasisCode		nvarchar(2)		= null,
	@pnUseCaseKey			int			= null,
	@psCriteriaName			nvarchar(254)		= null,
	@pbLocalClientFlagYes		bit			= 0,
	@pbLocalClientFlagNo		bit			= 0,
	@pbRegisteredUsersOwners	bit			= 0,
	@pbRegisteredUsersOthers	bit			= 0,
	@pnOldCaseOfficeKey		int			= null,
	@pnOldChecklistTypeKey		int			= null,
	@psOldCountryCode		nvarchar(3)		= null,
	@psOldCaseCategoryCode		nvarchar(2)		= null,
	@psOldSubTypeCode		nvarchar(2)		= null,
	@psOldPropertyTypeCode		nvarchar(1)		= null,
	@psOldCaseTypeCode		nvarchar(1)		= null,
	@psOldApplicationBasisCode	nvarchar(2)		= null,
	@psOldCriteriaName		nvarchar(254)		= null,
	@pbOldRuleInUse			bit			= 0,
	@pbOldLocalClientFlagYes	bit			= 0,
	@pbOldLocalClientFlagNo		bit			= 0,
	@pbOldRegisteredUsersOwners	bit			= 0,
	@pbOldRegisteredUsersOthers	bit			= 0,
	@pbRuleInUse			bit			= 0,
	@pbUserDefinedRule		bit			= 0,
	@pnIsCaseOfficeKeyInUse		bit			= 0,
	@psIsCheckListTypeKeyInUse	bit			= 0,
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
	@pbIsProfileKeyInUse		bit			= 0,
	@pbIsLocalClientFlagYesInUse	bit			= 0,
	@pbIsLocalClientFlagNoInUse	bit			= 0,
	@pbIsRegisteredUsersOwnersInUse	bit			= 0,
	@pbIsRegisteredUsersOthersInUse	bit			= 0
)
as

-- PROCEDURE:	ipw_UpdateChecklistControlCriteria
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update Case Windows Criteria if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15 Oct 2010	KR	RFC9193	1	Procedure created
-- 24 Oct 2017	AK	R72645	2	Make compatible with case sensitive server with case insensitive database.

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
Declare @bLocalClientFlag	bit
Declare	@sRegisteredUsers	char(2)

-- Initialise variables
Set @nErrorCode = 0
Set @sComma = " "
Set @sAnd = " and "
Set @sWhereString = CHAR(10)+" where "

If @pbIsLocalClientFlagYesInUse = 1 or @pbIsLocalClientFlagNoInUse = 1
Begin
	If @pbLocalClientFlagYes = 1
		Set @bLocalClientFlag = 1
	else if @pbLocalClientFlagNo = 1
		Set  @bLocalClientFlag = 0
	else 
		Set @bLocalClientFlag = null
End

If @pbIsRegisteredUsersOwnersInUse = 1 or @pbIsRegisteredUsersOthersInUse = 1
Begin
	if @pbRegisteredUsersOwners = 1 and @pbRegisteredUsersOthers = 1
		Set @sRegisteredUsers = 'B'
	else if @pbRegisteredUsersOwners = 1
		Set @sRegisteredUsers = 'Y'
	else if @pbRegisteredUsersOthers = 1
		Set @sRegisteredUsers = 'N'
	else
		Set @sRegisteredUsers = null

End


If @nErrorCode = 0
Begin
	If not(@pnCaseOfficeKey			= @pnOldCaseOfficeKey		
		and @pnChecklistTypeKey		= @pnOldChecklistTypeKey			 
		and @psCountryCode		= @psOldCountryCode			 
		and @psCaseCategoryCode		= @psOldCaseCategoryCode		 
		and @psSubTypeCode		= @psOldSubTypeCode			 
		and @psPropertyTypeCode		= @psOldPropertyTypeCode		 
		and @psCaseTypeCode		= @psOldCaseTypeCode			
		and @psApplicationBasisCode	= @psOldApplicationBasisCode	
		and (@psCriteriaName <> @psOldCriteriaName or @pbRuleInUse <> @pbOldRuleInUse)
		and @pbLocalClientFlagYes = @pbOldLocalClientFlagYes
		and @pbLocalClientFlagNo = @pbOldLocalClientFlagNo
		and @pbRegisteredUsersOwners = @pbOldRegisteredUsersOwners
		and @pbRegisteredUsersOthers = @pbOldRegisteredUsersOthers
		and @pnProfileKey		= @pnOldProfileKey
		)
	Begin
		If exists(select 1 from CRITERIA
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

	If @psIsCheckListTypeKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CHECKLISTTYPE = @pnChecklistTypeKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"CHECKLISTTYPE = @pnOldChecklistTypeKey"
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
	
	
	If @pbIsLocalClientFlagYesInUse = 1 or @pbIsLocalClientFlagNoInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"LOCALCLIENTFLAG = @bLocalClientFlag"
		Set @sComma = ","
		Set @sAnd = " and "
	End
	
	If @pbIsRegisteredUsersOwnersInUse = 1 or @pbIsRegisteredUsersOthersInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"REGISTEREDUSERS = @sRegisteredUsers"
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
				@pnChecklistTypeKey		int,
				@psCountryCode			nvarchar(3),		
				@psCaseCategoryCode		nvarchar(2),
				@psSubTypeCode			nvarchar(2),
				@psPropertyTypeCode		nvarchar(1),
				@psCaseTypeCode			nvarchar(1),
				@psApplicationBasisCode	nvarchar(2),
				@psCriteriaName			nvarchar(254),
				@pnProfileKey			int,				
				@bLocalClientFlag		bit,
				@sRegisteredusers		nchar(2),
				@pnOldCaseOfficeKey		int,
				@pnOldChecklistTypeKey		int,
				@psOldCountryCode			nvarchar(3),
				@psOldCaseCategoryCode		nvarchar(2),
				@psOldSubTypeCode			nvarchar(2),
				@psOldPropertyTypeCode		nvarchar(1),
				@psOldCaseTypeCode			nvarchar(1),
				@psOldApplicationBasisCode	nvarchar(2),
				@psOldCriteriaName			nvarchar(254),
				@pnOldProfileKey		int,
				@pbRuleInUse			bit,
				@pbUserDefinedRule		bit',
				@pnCriteriaNo		= @pnCriteriaNo,		
				@pnCaseOfficeKey	= @pnCaseOfficeKey	,		
				@pnChecklistTypeKey	= @pnChecklistTypeKey,	
				@psCountryCode		= @psCountryCode,		
				@psCaseCategoryCode	= @psCaseCategoryCode,
				@psSubTypeCode		= @psSubTypeCode,
				@psPropertyTypeCode	= @psPropertyTypeCode	,
				@psCaseTypeCode		= @psCaseTypeCode,
				@psApplicationBasisCode = @psApplicationBasisCode,
				@psCriteriaName			= @psCriteriaName,
				@pnProfileKey			= @pnProfileKey,				
				@bLocalClientFlag		= @bLocalClientFlag,
				@sRegisteredusers		= @sRegisteredUsers,
				@pnOldCaseOfficeKey		= @pnOldCaseOfficeKey,
				@pnOldChecklistTypeKey		= @pnOldChecklistTypeKey,
				@psOldCountryCode		=	@psOldCountryCode,
				@psOldCaseCategoryCode	=	@psOldCaseCategoryCode,
				@psOldSubTypeCode		=	@psOldSubTypeCode,
				@psOldPropertyTypeCode	=	@psOldPropertyTypeCode,
				@psOldCaseTypeCode		=	@psOldCaseTypeCode,
				@psOldApplicationBasisCode =	@psOldApplicationBasisCode,
				@psOldCriteriaName		=	@psOldCriteriaName,
				@pnOldProfileKey		= @pnOldProfileKey,
				@pbRuleInUse			= @pbRuleInUse,
				@pbUserDefinedRule		= @pbUserDefinedRule

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateChecklistControlCriteria to public
GO
