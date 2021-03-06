-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateTopicControl
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateTopicControl]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateTopicControl.'
	Drop procedure [dbo].[ipw_UpdateTopicControl]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateTopicControl...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[ipw_UpdateTopicControl]
(
	@pnUserIdentityId			int,		 -- Mandatory
	@psCulture					nvarchar(10) 	= null,
	@pnTopicControlNo			int,		 -- Mandatory
	@pnRowPosition				smallint,	 -- Mandatory
	@pnColPosition				smallint,	 -- Mandatory
	@pnTabControlNo				int				= null,
	@psTopicTitle				nvarchar(254)	= null,
	@psTopicShortTitle			nvarchar(254)	= null,
	@psTopicDescription			nvarchar(254)	= null,
	@pbDisplayDescription		bit				= 0,
	@psFilterName				nvarchar(50)	= null,
	@psFilterValue				nvarchar(254)	= null,
	@psScreenTip				nvarchar(254)	= null,
	@pbIsHidden					bit				= 0,
	@pbIsMandatory				bit				= 0,
	@pbIsInherited				bit				= 0,
	@pnOldRowPosition			smallint,	 -- Mandatory
	@pnOldColPosition			smallint,	 -- Mandatory	
	@pnOldTabControlNo			int				= null,
	@psOldTopicTitle			nvarchar(254)	= null,
	@psOldTopicShortTitle		nvarchar(254)	= null,
	@psOldTopicDescription		nvarchar(254)	= null,
	@pbOldDisplayDescription	bit				= 0,
	@psOldFilterName			nvarchar(50)	= null,
	@psOldFilterValue			nvarchar(254)	= null,
	@psOldScreenTip				nvarchar(254)	= null,
	@pbOldIsHidden				bit				= 0,
	@pbOldIsMandatory			bit				= 0,
	@pbOldIsInherited			bit				= 0,
	@pbApplyToDecendants		bit				= 0
	
)
as
-- PROCEDURE:	ipw_UpdateTopicControl
-- VERSION:	3
-- DESCRIPTION:	Update a Topic Control.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 29 Oct 2008	KR	RFC6732	1	Procedure created
-- 04 Feb 2009	JC	RFC6732	2	Fix Issues
-- 10 Oct 2013	vql	DR1271	3	User is not able to change properties of Case Names via Screen Designer.

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
	Update	TOPICCONTROL
	Set		ROWPOSITION		= @pnRowPosition,
			COLPOSITION		= @pnColPosition,
			TABCONTROLNO	= @pnTabControlNo,
			TOPICTITLE		= @psTopicTitle,
			TOPICSHORTTITLE	= @psTopicShortTitle,
			TOPICDESCRIPTION=@psTopicDescription,
			DISPLAYDESCRIPTION = @pbDisplayDescription,
			FILTERNAME		= @psFilterName,
			FILTERVALUE		= @psFilterValue,
			SCREENTIP		= @psScreenTip,
			ISHIDDEN		= @pbIsHidden,
			ISMANDATORY		= @pbIsMandatory,
			ISINHERITED		= @pbIsInherited
	Where	TOPICCONTROLNO	= @pnTopicControlNo"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTopicControlNo			int,
					  @pnRowPosition			smallint,
					  @pnColPosition			smallint,
					  @pnTabControlNo			int,
					  @psTopicTitle				nvarchar(254),
					  @psTopicShortTitle		nvarchar(254),
					  @psTopicDescription		nvarchar(254),
					  @pbDisplayDescription		smallint,
					  @psFilterName				nvarchar(50),
					  @psFilterValue			nvarchar(254),
					  @psScreenTip				nvarchar(254),
					  @pbIsHidden				bit,
					  @pbIsMandatory			bit,
					  @pbIsInherited			bit',
					  @pnTopicControlNo			= @pnTopicControlNo,
					  @pnRowPosition			= @pnRowPosition,
					  @pnColPosition			= @pnColPosition,
					  @pnTabControlNo			= @pnTabControlNo,
					  @psTopicTitle				= @psTopicTitle,
					  @psTopicShortTitle		= @psTopicShortTitle,
					  @psTopicDescription		= @psTopicDescription,
					  @pbDisplayDescription		= @pbDisplayDescription,
					  @psFilterName				= @psFilterName,
					  @psFilterValue			= @psFilterValue,
					  @psScreenTip				= @psScreenTip,
					  @pbIsHidden				= @pbIsHidden,
					  @pbIsMandatory			= @pbIsMandatory,
					  @pbIsInherited			= @pbIsInherited
End

If @nErrorCode = 0 and @pbApplyToDecendants = 1
Begin	
	Declare @nCriteriaNo	int
	Declare @bIsNameCriteria	bit
	Declare @sWindowName	nvarchar(50)
	Declare @bIsExternal	bit
	Declare @sNewTabName	nvarchar(50)
	Declare @sOldTabName	nvarchar(50)
	Declare @sTopicName		nvarchar(50)
	Declare @sTopicSuffix	nvarchar(50)

	Set @bIsNameCriteria = 0
	Set @bIsExternal = 0

	Set @sSQLString = "
	Select	@nCriteriaNo = isnull(WC.CRITERIANO,WC.NAMECRITERIANO),
			@bIsNameCriteria = CASE WHEN (WC.CRITERIANO IS NOT NULL) THEN 0 ELSE 1 END,
			@bIsExternal = WC.ISEXTERNAL,
			@sWindowName = WC.WINDOWNAME,
			@sNewTabName = NEW.TABNAME,
			@sOldTabName = OLD.TABNAME,
			@sTopicName = TP.TOPICNAME,
			@sTopicSuffix = TP.TOPICSUFFIX
	from TOPICCONTROL TP
	join WINDOWCONTROL WC on (WC.WINDOWCONTROLNO = TP.WINDOWCONTROLNO)
	left join TABCONTROL NEW on (NEW.TABCONTROLNO = @pnTabControlNo)
	left join TABCONTROL OLD on (OLD.TABCONTROLNO = @pnOldTabControlNo)
	where TP.TOPICCONTROLNO = @pnTopicControlNo"

	Exec  @nErrorCode=sp_executesql @sSQLString,
			N'@nCriteriaNo			int OUTPUT,
			  @bIsNameCriteria		bit OUTPUT,
			  @bIsExternal			bit OUTPUT,
			  @sWindowName			nvarchar(50) OUTPUT,
			  @sNewTabName			nvarchar(50) OUTPUT,
			  @sOldTabName			nvarchar(50) OUTPUT,
			  @sTopicName			nvarchar(50) OUTPUT,
			  @sTopicSuffix			nvarchar(50) OUTPUT,
			  @pnTabControlNo		int,
			  @pnOldTabControlNo	int,
			  @pnTopicControlNo		int',
			  @nCriteriaNo = @nCriteriaNo OUTPUT,
			  @bIsNameCriteria  = @bIsNameCriteria	OUTPUT,
			  @bIsExternal = @bIsExternal OUTPUT,
			  @sWindowName = @sWindowName OUTPUT,
			  @sNewTabName = @sNewTabName OUTPUT,
			  @sOldTabName = @sOldTabName OUTPUT,
			  @sTopicName = @sTopicName OUTPUT,
			  @sTopicSuffix = @sTopicSuffix OUTPUT,
			  @pnTabControlNo = @pnTabControlNo,
			  @pnOldTabControlNo = @pnOldTabControlNo,
			  @pnTopicControlNo = @pnTopicControlNo

	If @nErrorCode = 0
	Begin
		Set @sSQLString = " 
		Update TP
		Set	ROWPOSITION		= @pnRowPosition,
			COLPOSITION		= @pnColPosition,
			TABCONTROLNO	= NEW.TABCONTROLNO,
			TOPICTITLE		= @psTopicTitle,
			TOPICSHORTTITLE	= @psTopicShortTitle,
			TOPICDESCRIPTION=@psTopicDescription,
			DISPLAYDESCRIPTION = @pbDisplayDescription,
			FILTERNAME		= @psFilterName,
			FILTERVALUE		= @psFilterValue,
			SCREENTIP		= @psScreenTip,
			ISHIDDEN		= @pbIsHidden,
			ISMANDATORY		= @pbIsMandatory
		From dbo.fn_GetChildCriteria (@nCriteriaNo,@bIsNameCriteria) C
		Join WINDOWCONTROL WC on ( ((@bIsNameCriteria = 0 and WC.CRITERIANO=C.CRITERIANO and WC.CRITERIANO != @nCriteriaNo) 
									or
									(@bIsNameCriteria = 1 and WC.NAMECRITERIANO=C.CRITERIANO and WC.NAMECRITERIANO != @nCriteriaNo))
									and WC.ISEXTERNAL = @bIsExternal
									and WC.WINDOWNAME = @sWindowName
								  )
		Left Join TABCONTROL OLD ON (OLD.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
									and OLD.TABNAME = @sOldTabName)
		Left Join TABCONTROL NEW ON (NEW.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
									and NEW.TABNAME = @sNewTabName)
		Join TOPICCONTROL TP ON (TP.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
								and (OLD.TABCONTROLNO is null or TP.TABCONTROLNO = OLD.TABCONTROLNO)
								and TP.TOPICNAME = @sTopicName
								and TP.ISINHERITED = 1
								and (
										(@sTopicSuffix is null and TP.TOPICSUFFIX is null)
									 or (@sTopicSuffix is not null and TP.TOPICSUFFIX = @sTopicSuffix)
									)
								) 
		Where	TP.TABCONTROLNO		= OLD.TABCONTROLNO
			And TP.ROWPOSITION		= @pnOldRowPosition
			And	TP.COLPOSITION		= @pnOldColPosition
			And	TP.TOPICTITLE		= @psOldTopicTitle
			And	TP.TOPICSHORTTITLE	= @psOldTopicShortTitle
			And	TP.TOPICDESCRIPTION	=@psOldTopicDescription
			And	TP.DISPLAYDESCRIPTION = @pbOldDisplayDescription
			And	TP.FILTERNAME		= @psOldFilterName
			And	TP.FILTERVALUE		= @psOldFilterValue
			And	TP.SCREENTIP		= @psOldScreenTip
			And	TP.ISHIDDEN			= @pbOldIsHidden
			And	TP.ISMANDATORY		= @pbOldIsMandatory"

		exec @nErrorCode=sp_executesql @sSQLString,
			N'@nCriteriaNo				int,
			  @bIsNameCriteria			bit,
			  @bIsExternal				bit,
			  @sWindowName				nvarchar(50),
			  @sOldTabName				nvarchar(50),
			  @sNewTabName				nvarchar(50),
			  @sTopicName				nvarchar(50),
			  @sTopicSuffix				nvarchar(50),
			  @pnRowPosition			smallint,
			  @pnColPosition			smallint,
			  @psTopicTitle				nvarchar(254),	
			  @psTopicShortTitle		nvarchar(254),
			  @psTopicDescription		nvarchar(254),
			  @pbDisplayDescription		bit,				 
			  @psFilterName				nvarchar(50),
			  @psFilterValue			nvarchar(254),
			  @psScreenTip				nvarchar(254),
			  @pbIsHidden				bit,
			  @pbIsMandatory			bit,
			  @pnOldRowPosition			smallint,
			  @pnOldColPosition			smallint,	
			  @psOldTopicTitle			nvarchar(254),
			  @psOldTopicShortTitle		nvarchar(254),
			  @psOldTopicDescription	nvarchar(254),
			  @pbOldDisplayDescription	bit,
			  @psOldFilterName			nvarchar(50),
			  @psOldFilterValue			nvarchar(254),
			  @psOldScreenTip			nvarchar(254),
			  @pbOldIsHidden			bit,
			  @pbOldIsMandatory			bit',
			  @nCriteriaNo				= @nCriteriaNo,
			  @bIsNameCriteria			= @bIsNameCriteria,
			  @bIsExternal				= @bIsExternal,
			  @sWindowName				= @sWindowName,
			  @sOldTabName				= @sOldTabName,
			  @sNewTabName				= @sNewTabName,
			  @sTopicName				= @sTopicName,
			  @sTopicSuffix				= @sTopicSuffix,
			  @pnRowPosition			= @pnRowPosition,
			  @pnColPosition			= @pnColPosition,
			  @psTopicTitle				= @psTopicTitle,
			  @psTopicShortTitle		= @psTopicShortTitle,
			  @psTopicDescription		= @psTopicDescription,
			  @pbDisplayDescription		= @pbDisplayDescription,
			  @psFilterName				= @psFilterName,
			  @psFilterValue			= @psFilterValue,
			  @psScreenTip				= @psScreenTip,
			  @pbIsHidden				= @pbIsHidden,
			  @pbIsMandatory			= @pbIsMandatory,
			  @pnOldRowPosition			= @pnOldRowPosition,
			  @pnOldColPosition			= @pnOldColPosition,	
			  @psOldTopicTitle			= @psOldTopicTitle,
			  @psOldTopicShortTitle		= @psOldTopicShortTitle,
			  @psOldTopicDescription	= @psOldTopicDescription,
			  @pbOldDisplayDescription	= @pbOldDisplayDescription,
			  @psOldFilterName			= @psOldFilterName,
			  @psOldFilterValue			= @psOldFilterValue,
			  @psOldScreenTip			= @psOldScreenTip,
			  @pbOldIsHidden			= @pbOldIsHidden,
			  @pbOldIsMandatory			= @pbOldIsMandatory
	End

	If @nErrorCode = 0 and @pnRowPosition != @pnOldRowPosition
	Begin
		If @pnRowPosition > @pnOldRowPosition
		Begin
			UPDATE TP2 SET TP2.ROWPOSITION = TP2.ROWPOSITION - 1
				from dbo.fn_GetChildCriteria (@nCriteriaNo,@bIsNameCriteria) C
				Join WINDOWCONTROL WC on ( ((@bIsNameCriteria = 0 and WC.CRITERIANO=C.CRITERIANO and WC.CRITERIANO != @nCriteriaNo) 
											or
											(@bIsNameCriteria = 1 and WC.NAMECRITERIANO=C.CRITERIANO and WC.NAMECRITERIANO != @nCriteriaNo))
											and WC.ISEXTERNAL = @bIsExternal
											and WC.WINDOWNAME = @sWindowName
										  )
				Left Join TABCONTROL TC ON (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
											and TC.TABNAME = @sNewTabName)
				Join TOPICCONTROL TP1 ON (TP1.WINDOWCONTROLNO = WC.WINDOWCONTROLNO -- Check the topic exists with IsInherits
										and (TC.TABCONTROLNO is null or TP1.TABCONTROLNO = TC.TABCONTROLNO)
										and TP1.TOPICNAME = @sTopicName
										and TP1.ISINHERITED = 1
										and (
												(@sTopicSuffix is null and TP1.TOPICSUFFIX is null)
											 or (@sTopicSuffix is not null and TP1.TOPICSUFFIX = @sTopicSuffix)
											)
										)
				Join TOPICCONTROL TP2 ON (TP2.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
										and (TC.TABCONTROLNO is null or TP2.TABCONTROLNO = TC.TABCONTROLNO)
										and TP2.TOPICNAME != @sTopicName
										and (
												(@sTopicSuffix is null and TP2.TOPICSUFFIX is null)
											 or (@sTopicSuffix is not null and TP2.TOPICSUFFIX != @sTopicSuffix)
											)
										and TP2.ROWPOSITION > @pnOldRowPosition
										and TP2.ROWPOSITION <= @pnRowPosition)
		End
		Else
		Begin
			UPDATE TP2 SET TP2.ROWPOSITION = TP2.ROWPOSITION + 1
				from dbo.fn_GetChildCriteria (@nCriteriaNo,@bIsNameCriteria) C
				Join WINDOWCONTROL WC on ( ((@bIsNameCriteria = 0 and WC.CRITERIANO=C.CRITERIANO and WC.CRITERIANO != @nCriteriaNo) 
											or
											(@bIsNameCriteria = 1 and WC.NAMECRITERIANO=C.CRITERIANO and WC.NAMECRITERIANO != @nCriteriaNo))
											and WC.ISEXTERNAL = @bIsExternal
											and WC.WINDOWNAME = @sWindowName
										  )
				Left Join TABCONTROL TC ON (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
											and TC.TABNAME = @sNewTabName)
				Join TOPICCONTROL TP1 ON (TP1.WINDOWCONTROLNO = WC.WINDOWCONTROLNO -- Check the topic exists with IsInherits
										and (TC.TABCONTROLNO is null or TP1.TABCONTROLNO = TC.TABCONTROLNO)
										and TP1.TOPICNAME = @sTopicName
										and TP1.ISINHERITED = 1
										and (
												(@sTopicSuffix is null and TP1.TOPICSUFFIX is null)
											 or (@sTopicSuffix is not null and TP1.TOPICSUFFIX = @sTopicSuffix)
											)
										)
				Join TOPICCONTROL TP2 ON (TP2.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
										and (TC.TABCONTROLNO is null or TP2.TABCONTROLNO = TC.TABCONTROLNO)
										and TP2.TOPICNAME != @sTopicName
										and (
												(@sTopicSuffix is null and TP2.TOPICSUFFIX is null)
											 or (@sTopicSuffix is not null and TP2.TOPICSUFFIX != @sTopicSuffix)
											)
										and TP2.ROWPOSITION >= @pnRowPosition
										and TP2.ROWPOSITION < @pnOldRowPosition)
		End
		set @nErrorCode = @@error
	End
	-- If the topic has moved from one tab to another, then re-order the topic of the old tab.
	If @nErrorCode = 0 and @pnTabControlNo is not null and @pnOldTabControlNo is not null and @pnTabControlNo != @pnOldTabControlNo
	Begin
		UPDATE TP2 SET TP2.ROWPOSITION = TP2.ROWPOSITION - 1
			from dbo.fn_GetChildCriteria (@nCriteriaNo,@bIsNameCriteria) C
			Join WINDOWCONTROL WC on ( ((@bIsNameCriteria = 0 and WC.CRITERIANO=C.CRITERIANO and WC.CRITERIANO != @nCriteriaNo) 
										or
										(@bIsNameCriteria = 1 and WC.NAMECRITERIANO=C.CRITERIANO and WC.NAMECRITERIANO != @nCriteriaNo))
										and WC.ISEXTERNAL = @bIsExternal
										and WC.WINDOWNAME = @sWindowName
									  )
			Join TABCONTROL TC ON (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
										and TC.TABNAME = @sOldTabName)
			Join TOPICCONTROL TP1 ON (TP1.WINDOWCONTROLNO = WC.WINDOWCONTROLNO -- Check the topic exists with IsInherits
									and (TC.TABCONTROLNO is null or TP1.TABCONTROLNO = TC.TABCONTROLNO)
									and TP1.TOPICNAME = @sTopicName
									and TP1.ISINHERITED = 1
									and (
											(@sTopicSuffix is null and TP1.TOPICSUFFIX is null)
										 or (@sTopicSuffix is not null and TP1.TOPICSUFFIX = @sTopicSuffix)
										)
									)
			Join TOPICCONTROL TP2 ON (TP2.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
									and (TC.TABCONTROLNO is null or TP2.TABCONTROLNO = TC.TABCONTROLNO)
									and TP2.TOPICNAME != @sTopicName
									and (
											(@sTopicSuffix is null and TP2.TOPICSUFFIX is null)
										 or (@sTopicSuffix is not null and TP2.TOPICSUFFIX != @sTopicSuffix)
										)
									and TP2.ROWPOSITION > @pnOldRowPosition)
		set @nErrorCode = @@error

	End
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateTopicControl to public
GO