-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateElementControl
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateElementControl]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateElementControl.'
	Drop procedure [dbo].[ipw_UpdateElementControl]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateElementControl...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[ipw_UpdateElementControl]
(
	@pnUserIdentityId			int,		 -- Mandatory
	@psCulture					nvarchar(10) 	= null,
	@pnElementControlNo			int,		 -- Mandatory
	@psShortLabel				nvarchar(254)	= null,
	@psFullLabel				nvarchar(254)	= null,
	@psButton					nvarchar(254)	= null,
	@psTooltip					nvarchar(254)	= null,
	@psLink						nvarchar(254)	= null,
	@psLiteral					nvarchar(254)	= null,
	@psDefaultValue				nvarchar(254)	= null,
	@psFilterName				nvarchar(50)	= null,
	@psFilterValue				nvarchar(254)	= null,
	@pbIsHidden					bit				= 0,
	@pbIsMandatory				bit				= 0,
	@pbIsReadOnly				bit				= 0,
	@pbIsInherited				bit				= 0,
	@psOldShortLabel			nvarchar(254)	= null,
	@psOldFullLabel				nvarchar(254)	= null,
	@psOldButton				nvarchar(254)	= null,
	@psOldTooltip				nvarchar(254)	= null,
	@psOldLink					nvarchar(254)	= null,
	@psOldLiteral				nvarchar(254)	= null,
	@psOldDefaultValue			nvarchar(254)	= null,
	@psOldFilterName			nvarchar(50)	= null,
	@psOldFilterValue			nvarchar(254)	= null,
	@pbOldIsHidden				bit				= 0,
	@pbOldIsMandatory			bit				= 0,
	@pbOldIsReadOnly			bit				= 0,
	@pbOldIsInherited			bit				= 0,
	@pbApplyToDecendants		bit				= 0
)
as
-- PROCEDURE:	ipw_UpdateElementControl
-- VERSION:	2
-- DESCRIPTION:	Update an Element Control.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 29 Oct 2008	KR	RFC6732	1	Procedure created
-- 05 Feb 2009	JC	RFC6732	2	Fix Issues

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode 	= 0

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Update	ELEMENTCONTROL
	Set		SHORTLABEL		= @psShortLabel,
			FULLLABEL		= @psFullLabel,
			BUTTON			= @psButton,
			TOOLTIP			= @psTooltip,
			LINK			= @psLink,
			LITERAL			= @psLiteral,
			DEFAULTVALUE	= @psDefaultValue,
			FILTERNAME		= @psFilterName,
			FILTERVALUE		= @psFilterValue,
			ISHIDDEN		= @pbIsHidden,
			ISMANDATORY		= @pbIsMandatory,
			ISREADONLY		= @pbIsReadOnly,
			ISINHERITED		= @pbIsInherited
	Where	ELEMENTCONTROLNO= @pnElementControlNo
	And		SHORTLABEL		= @psOldShortLabel
	And		FULLLABEL		= @psOldFullLabel
	And		BUTTON			= @psOldButton
	And		TOOLTIP			= @psOldTooltip
	And		LINK			= @psOldLink
	And		LITERAL			= @psOldLiteral
	And		DEFAULTVALUE	= @psOldDefaultValue
	And		FILTERNAME		= @psOldFilterName
	And		FILTERVALUE		= @psOldFilterValue
	And		ISHIDDEN		= @pbOldIsHidden
	And		ISMANDATORY		= @pbOldIsMandatory
	And		ISREADONLY		= @pbOldIsReadOnly
	And		ISINHERITED		= @pbOldIsInherited"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnElementControlNo		int,
					  @psShortLabel				nvarchar(254),
					  @psFullLabel				nvarchar(254),
					  @psButton					nvarchar(254),
					  @psTooltip				nvarchar(254),
					  @psLink					nvarchar(254),
					  @psLiteral				nvarchar(254),
					  @psDefaultValue			nvarchar(254),
					  @psFilterName				nvarchar(50),
					  @psFilterValue			nvarchar(254),
					  @pbIsHidden				bit,
					  @pbIsMandatory			bit,
					  @pbIsReadOnly				bit,
					  @pbIsInherited			bit,
					  @psOldShortLabel			nvarchar(254),
					  @psOldFullLabel			nvarchar(254),
					  @psOldButton				nvarchar(254),
					  @psOldTooltip				nvarchar(254),
					  @psOldLink				nvarchar(254),
					  @psOldLiteral				nvarchar(254),
					  @psOldDefaultValue		nvarchar(254),
					  @psOldFilterName			nvarchar(50),
					  @psOldFilterValue			nvarchar(254),
					  @pbOldIsHidden			bit,
					  @pbOldIsMandatory			bit,
					  @pbOldIsReadOnly			bit,
					  @pbOldIsInherited			bit',
					  @pnElementControlNo	= @pnElementControlNo,
					  @psShortLabel			= @psShortLabel,
					  @psFullLabel			= @psFullLabel,
					  @psButton				= @psButton,
					  @psTooltip			= @psTooltip,
					  @psLink				= @psLink,
					  @psLiteral			= @psLiteral,
					  @psDefaultValue		= @psDefaultValue,
					  @psFilterName			= @psFilterName,
					  @psFilterValue		= @psFilterValue,
					  @pbIsHidden			= @pbIsHidden,
					  @pbIsMandatory		= @pbIsMandatory,
					  @pbIsReadOnly			= @pbIsReadOnly,
					  @pbIsInherited		= @pbIsInherited,
					  @psOldShortLabel		= @psOldShortLabel,
					  @psOldFullLabel		= @psOldFullLabel,
					  @psOldButton			= @psOldButton,
					  @psOldTooltip			= @psOldTooltip,
					  @psOldLink			= @psOldLink,
					  @psOldLiteral			= @psOldLiteral,
					  @psOldDefaultValue	= @psOldDefaultValue,
					  @psOldFilterName		= @psOldFilterName,
					  @psOldFilterValue		= @psOldFilterValue,
					  @pbOldIsHidden		= @pbOldIsHidden,
					  @pbOldIsMandatory		= @pbOldIsMandatory,
					  @pbOldIsReadOnly		= @pbOldIsReadOnly,
					  @pbOldIsInherited		= @pbOldIsInherited
					  
End

If @nErrorCode = 0 and @pbApplyToDecendants = 1
Begin	
	Declare @nCriteriaNo	int
	Declare @bIsNameCriteria	bit
	Declare @sWindowName nvarchar(50)
	Declare @bIsExternal bit
	Declare @sTabName nvarchar(50)
	Declare @sTopicName nvarchar(50)
	Declare @sTopicSuffix nvarchar(50)
	Declare @sElementName nvarchar(50)

	Set @bIsNameCriteria = 0
	Set @bIsExternal = 0

	Set @sSQLString = "
	Select	@nCriteriaNo = isnull(WC.CRITERIANO,WC.NAMECRITERIANO),
			@bIsNameCriteria = CASE WHEN (WC.CRITERIANO IS NOT NULL) THEN 0 ELSE 1 END,
			@sWindowName = WC.WINDOWNAME,
			@bIsExternal = WC.ISEXTERNAL,
			@sTabName = TC.TABNAME,
			@sTopicName = TP.TOPICNAME,
			@sTopicSuffix = TP.TOPICSUFFIX,
			@sElementName = EC.ELEMENTNAME
	from ELEMENTCONTROL EC
	join TOPICCONTROL TP on (TP.TOPICCONTROLNO = EC.TOPICCONTROLNO)
	left join TABCONTROL TC on (TC.TABCONTROLNO = TP.TABCONTROLNO)
	join WINDOWCONTROL WC on (WC.WINDOWCONTROLNO = TP.WINDOWCONTROLNO)
	where EC.ELEMENTCONTROLNO = @pnElementControlNo"

	Exec  @nErrorCode=sp_executesql @sSQLString,
			N'@nCriteriaNo			int OUTPUT,
			  @bIsNameCriteria		bit OUTPUT,
			  @bIsExternal			bit OUTPUT,
			  @sWindowName			nvarchar(50) OUTPUT,
			  @sTabName				nvarchar(50) OUTPUT,
			  @sTopicName			nvarchar(50) OUTPUT,
			  @sTopicSuffix			nvarchar(50) OUTPUT,
			  @sElementName			nvarchar(50) OUTPUT,
			  @pnElementControlNo	int',
			  @nCriteriaNo = @nCriteriaNo OUTPUT,
			  @bIsNameCriteria  = @bIsNameCriteria	OUTPUT,
			  @bIsExternal = @bIsExternal OUTPUT,
			  @sWindowName = @sWindowName OUTPUT,
			  @sTabName = @sTabName OUTPUT,
			  @sTopicName = @sTopicName OUTPUT,
			  @sTopicSuffix = @sTopicSuffix OUTPUT,
			  @sElementName = @sElementName OUTPUT,
			  @pnElementControlNo = @pnElementControlNo

	If @nErrorCode = 0
	Begin
		Set @sSQLString = " 
		Update EC
		Set	SHORTLABEL		= @psShortLabel,
			FULLLABEL		= @psFullLabel,
			BUTTON			= @psButton,
			TOOLTIP			= @psTooltip,
			LINK			= @psLink,
			LITERAL			= @psLiteral,
			DEFAULTVALUE	= @psDefaultValue,
			FILTERNAME		= @psFilterName,
			FILTERVALUE		= @psFilterValue,
			ISHIDDEN		= @pbIsHidden,
			ISMANDATORY		= @pbIsMandatory,
			ISREADONLY		= @pbIsReadOnly
		From dbo.fn_GetChildCriteria (@nCriteriaNo,@bIsNameCriteria) C
		Join WINDOWCONTROL WC on ( ((@bIsNameCriteria = 0 and WC.CRITERIANO=C.CRITERIANO and WC.CRITERIANO != @nCriteriaNo) 
									or
									(@bIsNameCriteria = 1 and WC.NAMECRITERIANO=C.CRITERIANO and WC.NAMECRITERIANO != @nCriteriaNo))
									and WC.ISEXTERNAL = @bIsExternal
									and WC.WINDOWNAME = @sWindowName
								  )
		Left Join TABCONTROL TC ON (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
									and TC.TABNAME = @sTabName)
		Join TOPICCONTROL TP ON (TP.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
								and (TC.TABCONTROLNO is null or TP.TABCONTROLNO = TC.TABCONTROLNO)
								and TP.TOPICNAME = @sTopicName
								and (
										(@sTopicSuffix is null and TP.TOPICSUFFIX is null)
									 or (@sTopicSuffix is not null and TP.TOPICSUFFIX = @sTopicSuffix)
									)
								) 
		Join ELEMENTCONTROL EC ON (EC.TOPICCONTROLNO = TP.TOPICCONTROLNO
									and EC.ISINHERITED = 1
									and EC.ELEMENTNAME = @sElementName)
		Where	EC.SHORTLABEL	= @psOldShortLabel
			And	EC.FULLLABEL	= @psOldFullLabel
			And	EC.BUTTON		= @psOldButton
			And	EC.TOOLTIP		= @psOldTooltip
			And	EC.LINK			= @psOldLink
			And	EC.LITERAL		= @psOldLiteral
			And	EC.DEFAULTVALUE	= @psOldDefaultValue
			And	EC.FILTERNAME	= @psOldFilterName
			And	EC.FILTERVALUE	= @psOldFilterValue
			And	EC.ISHIDDEN		= @pbOldIsHidden
			And	EC.ISMANDATORY	= @pbOldIsMandatory
			And	EC.ISREADONLY	= @pbOldIsReadOnly"

		exec @nErrorCode=sp_executesql @sSQLString,
			N'@nCriteriaNo				int,
			  @bIsNameCriteria			bit,
			  @bIsExternal				bit,
			  @sWindowName				nvarchar(50),
			  @sTabName					nvarchar(50),
			  @sTopicName				nvarchar(50),
			  @sTopicSuffix				nvarchar(50),
			  @sElementName				nvarchar(50),
			  @psShortLabel				nvarchar(254),
			  @psFullLabel				nvarchar(254),
			  @psButton					nvarchar(254),
			  @psTooltip				nvarchar(254),
			  @psLink					nvarchar(254),
			  @psLiteral				nvarchar(254),
			  @psDefaultValue			nvarchar(254),
			  @psFilterName				nvarchar(50),
			  @psFilterValue			nvarchar(254),
			  @pbIsHidden				bit,
			  @pbIsMandatory			bit,
			  @pbIsReadOnly				bit,
			  @psOldShortLabel			nvarchar(254),
			  @psOldFullLabel			nvarchar(254),
			  @psOldButton				nvarchar(254),
			  @psOldTooltip				nvarchar(254),
			  @psOldLink				nvarchar(254),
			  @psOldLiteral				nvarchar(254),
			  @psOldDefaultValue		nvarchar(254),
			  @psOldFilterName			nvarchar(50),
			  @psOldFilterValue			nvarchar(254),
			  @pbOldIsHidden			bit,
			  @pbOldIsMandatory			bit,
			  @pbOldIsReadOnly			bit',
			  @nCriteriaNo				= @nCriteriaNo,
			  @bIsNameCriteria			= @bIsNameCriteria,
			  @bIsExternal				= @bIsExternal,
			  @sWindowName				= @sWindowName,
			  @sTabName					= @sTabName,
			  @sTopicName				= @sTopicName,
			  @sTopicSuffix				= @sTopicSuffix,
			  @sElementName				= @sElementName,
			  @psShortLabel				= @psShortLabel,
			  @psFullLabel				= @psFullLabel,
			  @psButton					= @psButton,
			  @psTooltip				= @psTooltip,
			  @psLink					= @psLink,
			  @psLiteral				= @psLiteral,
			  @psDefaultValue			= @psDefaultValue,
			  @psFilterName				= @psFilterName,
			  @psFilterValue			= @psFilterValue,
			  @pbIsHidden				= @pbIsHidden,
			  @pbIsMandatory			= @pbIsMandatory,
			  @pbIsReadOnly				= @pbIsReadOnly,
			  @psOldShortLabel			= @psOldShortLabel,
			  @psOldFullLabel			= @psOldFullLabel,
			  @psOldButton				= @psOldButton,
			  @psOldTooltip				= @psOldTooltip,
			  @psOldLink				= @psOldLink,
			  @psOldLiteral				= @psOldLiteral,
			  @psOldDefaultValue		= @psOldDefaultValue,
			  @psOldFilterName			= @psOldFilterName,
			  @psOldFilterValue			= @psOldFilterValue,
			  @pbOldIsHidden			= @pbOldIsHidden,
			  @pbOldIsMandatory			= @pbOldIsMandatory,
			  @pbOldIsReadOnly			= @pbOldIsReadOnly
	End
End
Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateElementControl to public
GO

