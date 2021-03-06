-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertElementControl
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertElementControl]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertElementControl.'
	Drop procedure [dbo].[ipw_InsertElementControl]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertElementControl...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ipw_InsertElementControl]
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture					nvarchar(10) 	= null,
	@pnElementControlKey		int				= null	output,
	@pnTopicControlNo			int,
	@psElementName				nvarchar(50),
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
	@pbApplyToDecendants		bit				= 0
)
as
-- PROCEDURE:	ipw_InsertElementControl
-- VERSION:	2
-- DESCRIPTION:	Add a new ElementControl.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 21 Oct 2008	KR	RFC6732	1	Procedure created
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

-- Insert new Element
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	insert 	into ELEMENTCONTROL
		(TOPICCONTROLNO,
		 ELEMENTNAME,
		 SHORTLABEL,
		 FULLLABEL,
		 BUTTON,
		 TOOLTIP,
		 LINK,
		 LITERAL,
		 DEFAULTVALUE,
		 FILTERNAME,
		 FILTERVALUE,
		 ISHIDDEN,
		 ISMANDATORY,
		 ISREADONLY,
		 ISINHERITED 
		)
	values
	  ( @pnTopicControlNo,
		@psElementName,
		@psShortLabel,
		@psFullLabel,
		@psButton,
		@psTooltip,
		@psLink,
		@psLiteral,
		@psDefaultValue,
		@psFilterName,
		@psFilterValue,
		@pbIsHidden,
		@pbIsMandatory,
		@pbIsReadOnly,
		@pbIsInherited
	  )
	Set @pnElementControlKey = SCOPE_IDENTITY()"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnElementControlKey		int		output,
					  @pnTopicControlNo			int,
					  @psElementName			nvarchar(50),
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
					  @pbIsInherited			bit',	
					  @pnElementControlKey		= @pnElementControlKey output,					 				 
					  @pnTopicControlNo			= @pnTopicControlNo,
					  @psElementName			= @psElementName,
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
					  @pbIsInherited			= @pbIsInherited

	Select @pnElementControlKey as ElementControlKey
End

-- Apply to all children
If @nErrorCode = 0 and @pbApplyToDecendants = 1
Begin	
	-- Get information about the WINDOWCONTROL, TABCONTROL, TOPICCONTROL for this new Element
	Declare @nCriteriaNo	int
	Declare @bIsNameCriteria	bit
	Declare @sWindowName nvarchar(50)
	Declare @bIsExternal bit
	Declare @sTabName nvarchar(50)
	Declare @sTopicName nvarchar(50)
	Declare @sTopicSuffix nvarchar(50)

	Set @bIsNameCriteria = 0
	Set @bIsExternal = 0

	Set @sSQLString = "
	Select	@nCriteriaNo = isnull(WC.CRITERIANO,WC.NAMECRITERIANO),
			@bIsNameCriteria = CASE WHEN (WC.CRITERIANO IS NOT NULL) THEN 0 ELSE 1 END,
			@sWindowName = WC.WINDOWNAME,
			@bIsExternal = WC.ISEXTERNAL,
			@sTabName = TC.TABNAME,
			@sTopicName = TP.TOPICNAME,
			@sTopicSuffix = TP.TOPICSUFFIX
	from TOPICCONTROL TP
	left join TABCONTROL TC on (TC.TABCONTROLNO = TP.TABCONTROLNO)
	join WINDOWCONTROL WC on (WC.WINDOWCONTROLNO = TP.WINDOWCONTROLNO)
	where TP.TOPICCONTROLNO = @pnTopicControlNo"

	-- Insert element to all children at the condition that the Topic has ISINHERITED=1
	Exec  @nErrorCode=sp_executesql @sSQLString,
			N'@nCriteriaNo			int OUTPUT,
			  @bIsNameCriteria		bit OUTPUT,
			  @bIsExternal			bit OUTPUT,
			  @sWindowName			nvarchar(50) OUTPUT,
			  @sTabName				nvarchar(50) OUTPUT,
			  @sTopicName			nvarchar(50) OUTPUT,
			  @sTopicSuffix			nvarchar(50) OUTPUT,
			  @pnTopicControlNo		int',
			  @nCriteriaNo = @nCriteriaNo OUTPUT,
			  @bIsNameCriteria  = @bIsNameCriteria	OUTPUT,
			  @bIsExternal = @bIsExternal OUTPUT,
			  @sWindowName = @sWindowName OUTPUT,
			  @sTabName = @sTabName OUTPUT,
			  @sTopicName = @sTopicName OUTPUT,
			  @sTopicSuffix = @sTopicSuffix OUTPUT,
			  @pnTopicControlNo = @pnTopicControlNo

	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		insert 	into ELEMENTCONTROL
				(TOPICCONTROLNO,
				 ELEMENTNAME,
				 SHORTLABEL,
				 FULLLABEL,
				 BUTTON,
				 TOOLTIP,
				 LINK,
				 LITERAL,
				 DEFAULTVALUE,
				 FILTERNAME,
				 FILTERVALUE,
				 ISHIDDEN,
				 ISMANDATORY,
				 ISREADONLY,
				 ISINHERITED 
				)
		Select TP.TOPICCONTROLNO, 
			@psElementName,
			@psShortLabel,
			@psFullLabel,
			@psButton,
			@psTooltip,
			@psLink,
			@psLiteral,
			@psDefaultValue,
			@psFilterName,
			@psFilterValue,
			@pbIsHidden,
			@pbIsMandatory,
			@pbIsReadOnly,
			1
		from dbo.fn_GetChildCriteria (@nCriteriaNo,@bIsNameCriteria) C
		join WINDOWCONTROL WC on ( ((@bIsNameCriteria = 0 and WC.CRITERIANO=C.CRITERIANO and WC.CRITERIANO != @nCriteriaNo) 
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
									and TP.ISINHERITED = 1
									and (
											(@sTopicSuffix is null and TP.TOPICSUFFIX is null)
										 or (@sTopicSuffix is not null and TP.TOPICSUFFIX = @sTopicSuffix)
										)
									) 
		Left Join ELEMENTCONTROL EC ON (EC.TOPICCONTROLNO = TP.TOPICCONTROLNO
									and EC.ELEMENTNAME = @psElementName ) 
		where EC.TOPICCONTROLNO is null"
		
		exec @nErrorCode=sp_executesql @sSQLString,
			N'@nCriteriaNo			int,
			  @bIsNameCriteria		bit,
			  @bIsExternal			bit,
			  @sWindowName			nvarchar(50),
			  @sTabName				nvarchar(50),
			  @sTopicName			nvarchar(50),
			  @sTopicSuffix			nvarchar(50),
			  @psElementName		nvarchar(50),
			  @psShortLabel			nvarchar(254),
			  @psFullLabel			nvarchar(254),
			  @psButton				nvarchar(254),
			  @psTooltip			nvarchar(254),
			  @psLink				nvarchar(254),
			  @psLiteral			nvarchar(254),
			  @psDefaultValue		nvarchar(254),
			  @psFilterName			nvarchar(50),
			  @psFilterValue		nvarchar(254),
			  @pbIsHidden			bit,
			  @pbIsMandatory		bit,
			  @pbIsReadOnly			bit',
			  @nCriteriaNo			= @nCriteriaNo,
			  @bIsNameCriteria      = @bIsNameCriteria,
			  @bIsExternal			= @bIsExternal,
			  @sWindowName			= @sWindowName,
			  @sTabName				= @sTabName,
			  @sTopicName			= @sTopicName,
			  @sTopicSuffix			= @sTopicSuffix,
			  @psElementName		= @psElementName,
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
			  @pbIsReadOnly			= @pbIsReadOnly
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertElementControl to public
GO