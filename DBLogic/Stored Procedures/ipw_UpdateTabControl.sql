-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateTabControl
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateTabControl]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateTabControl.'
	Drop procedure [dbo].[ipw_UpdateTabControl]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateTabControl...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[ipw_UpdateTabControl]
(
	@pnUserIdentityId			int,				-- Mandatory
	@psCulture				nvarchar(10) 			= null,
	@pnTabControlNo				int,				-- Mandatory	
	@pnDisplaySequence			smallint,			-- Mandatory
	@psTabTitle				nvarchar(254)			= null,
	@pbIsInherited				bit				= 0,	
	@pnOldDisplaySequence			smallint			= null,
	@psOldTabTitle				nvarchar(254)			= null,
	@pbOldIsInherited			bit				= 0,
	@pbApplyToDecendants			bit				= 0
)
as
-- PROCEDURE:	ipw_UpdateTabControl
-- VERSION:	3
-- DESCRIPTION:	Update a Tab Control.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 29 Oct 2008	KR	RFC6732	1	Procedure created
-- 03 Feb 2009	JC	RFC6732	2	Fix Issues
-- 06 mar 2012	KR	R12008	3	Make @pnOldDisplaySequence non mandatory and initialised to the value of @pnDisplaySequence if it is null.

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
	if @pnOldDisplaySequence = null
		Set @pnOldDisplaySequence = @pnDisplaySequence
End

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Update TABCONTROL
	Set	DISPLAYSEQUENCE		= @pnDisplaySequence,
		TABTITLE			= @psTabTitle,
		ISINHERITED			= @pbIsInherited
	Where	TABCONTROLNO	= @pnTabControlNo 
	And		DISPLAYSEQUENCE	= @pnOldDisplaySequence
	And		TABTITLE		= @psOldTabTitle
	And		ISINHERITED		= @pbOldIsInherited"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnTabControlNo				int,
			  @pnDisplaySequence			smallint,
			  @psTabTitle					nvarchar(254),
			  @pbIsInherited				bit,	
			  @pnOldDisplaySequence			smallint,
			  @psOldTabTitle				nvarchar(254),
			  @pbOldIsInherited				bit',					 
			  @pnTabControlNo				= @pnTabControlNo,
			  @pnDisplaySequence			= @pnDisplaySequence,
			  @psTabTitle					= @psTabTitle,
			  @pbIsInherited				= @pbIsInherited,
			  @pnOldDisplaySequence			= @pnOldDisplaySequence,
			  @psOldTabTitle				= @psOldTabTitle,
			  @pbOldIsInherited				= @pbOldIsInherited

End

If @nErrorCode = 0 and @pbApplyToDecendants = 1
Begin	
	Declare @nCriteriaNo	int
	Declare @bIsNameCriteria	bit
	Declare @sWindowName	nvarchar(50)
	Declare @bIsExternal	bit
	Declare @sTabName	nvarchar(50)

	Set @bIsNameCriteria = 0
	Set @bIsExternal = 0

	Set @sSQLString = "
	Select	@nCriteriaNo = isnull(WC.CRITERIANO,WC.NAMECRITERIANO),
			@bIsNameCriteria = CASE WHEN (WC.CRITERIANO IS NOT NULL) THEN 0 ELSE 1 END,
			@bIsExternal = WC.ISEXTERNAL,
			@sWindowName = WC.WINDOWNAME,
			@sTabName = TC.TABNAME
	from TABCONTROL TC
	join WINDOWCONTROL WC on (WC.WINDOWCONTROLNO = TC.WINDOWCONTROLNO)
	where TC.TABCONTROLNO = @pnTabControlNo"

	Exec  @nErrorCode=sp_executesql @sSQLString,
			N'@nCriteriaNo			int OUTPUT,
			  @bIsNameCriteria		bit OUTPUT,
			  @bIsExternal			bit OUTPUT,
			  @sWindowName			nvarchar(50) OUTPUT,
			  @sTabName				nvarchar(50) OUTPUT,
			  @pnTabControlNo		int',
			  @nCriteriaNo = @nCriteriaNo OUTPUT,
			  @bIsNameCriteria  = @bIsNameCriteria	OUTPUT,
			  @bIsExternal = @bIsExternal OUTPUT,
			  @sWindowName = @sWindowName OUTPUT,
			  @sTabName = @sTabName OUTPUT,
			  @pnTabControlNo = @pnTabControlNo

	If @nErrorCode = 0
	Begin
		Set @sSQLString = " 
		Update TC
		Set	DISPLAYSEQUENCE		= @pnDisplaySequence,
			TABTITLE			= @psTabTitle
		From dbo.fn_GetChildCriteria (@nCriteriaNo,@bIsNameCriteria) C
		Join WINDOWCONTROL WC on ( ((@bIsNameCriteria = 0 and WC.CRITERIANO=C.CRITERIANO and WC.CRITERIANO != @nCriteriaNo) 
									or
									(@bIsNameCriteria = 1 and WC.NAMECRITERIANO=C.CRITERIANO and WC.NAMECRITERIANO != @nCriteriaNo))
									and WC.ISEXTERNAL = @bIsExternal
									and WC.WINDOWNAME = @sWindowName
								  )
		Join TABCONTROL TC ON (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
								and TC.TABNAME = @sTabName
								and TC.ISINHERITED = 1 
								and TC.TABCONTROLNO != @pnTabControlNo)
		Where	TC.DISPLAYSEQUENCE	= @pnOldDisplaySequence
		And		TC.TABTITLE		= @psOldTabTitle"

		exec @nErrorCode=sp_executesql @sSQLString,
			N'@nCriteriaNo			int,
			  @bIsNameCriteria		bit,
			  @bIsExternal			bit,
			  @sWindowName			nvarchar(50),
			  @sTabName				nvarchar(50),
			  @pnTabControlNo		int,
			  @pnDisplaySequence    smallint,
			  @psTabTitle           nvarchar(254),	
			  @pnOldDisplaySequence	smallint,				 
			  @psOldTabTitle		nvarchar(254)',
			  @nCriteriaNo			= @nCriteriaNo,
			  @bIsNameCriteria      = @bIsNameCriteria,
			  @bIsExternal			= @bIsExternal,
			  @sWindowName			= @sWindowName,
			  @sTabName				= @sTabName,
			  @pnTabControlNo		= @pnTabControlNo,
			  @pnDisplaySequence    = @pnDisplaySequence,
			  @psTabTitle			= @psTabTitle,
			  @pnOldDisplaySequence	= @pnOldDisplaySequence,
			  @psOldTabTitle		= @psOldTabTitle

	End
	
	-- If the DisplaySequence has changed, update the child topics sequence
	If @nErrorCode = 0 and @pnDisplaySequence != @pnOldDisplaySequence
	Begin
		If @pnDisplaySequence > @pnOldDisplaySequence
		Begin
			UPDATE TC2 SET TC2.DISPLAYSEQUENCE = TC2.DISPLAYSEQUENCE - 1
				from dbo.fn_GetChildCriteria (@nCriteriaNo,@bIsNameCriteria) C
				join WINDOWCONTROL WC on (WC.WINDOWNAME = @sWindowName
											and (
													(@bIsNameCriteria = 0 and WC.CRITERIANO=C.CRITERIANO and WC.CRITERIANO != @nCriteriaNo)
													or
													(@bIsNameCriteria = 1 and WC.NAMECRITERIANO=C.CRITERIANO and WC.NAMECRITERIANO != @nCriteriaNo)
												)
											and WC.ISEXTERNAL = @bIsExternal
										  )
				join TABCONTROL TC1 ON (TC1.WINDOWCONTROLNO = WC.WINDOWCONTROLNO --Check that the tab exists with IsInherits
										and TC1.TABNAME = @sTabName
										and TC1.ISINHERITED = 1)
				join TABCONTROL TC2 ON (TC2.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
										and TC2.TABNAME <> @sTabName
										and TC2.DISPLAYSEQUENCE > @pnOldDisplaySequence
										and TC2.DISPLAYSEQUENCE <= @pnDisplaySequence)
		End
		Else
		Begin
			UPDATE TC2 SET TC2.DISPLAYSEQUENCE = TC2.DISPLAYSEQUENCE + 1
				from dbo.fn_GetChildCriteria (@nCriteriaNo,@bIsNameCriteria) C
				join WINDOWCONTROL WC on (WC.WINDOWNAME = @sWindowName
											and (
													(@bIsNameCriteria = 0 and WC.CRITERIANO=C.CRITERIANO and WC.CRITERIANO != @nCriteriaNo)
													or
													(@bIsNameCriteria = 1 and WC.NAMECRITERIANO=C.CRITERIANO and WC.NAMECRITERIANO != @nCriteriaNo)
												)
											and WC.ISEXTERNAL = @bIsExternal
										  )
				join TABCONTROL TC1 ON (TC1.WINDOWCONTROLNO = WC.WINDOWCONTROLNO --Check that the tab exists with IsInherits
										and TC1.TABNAME = @sTabName
										and TC1.ISINHERITED = 1)
				join TABCONTROL TC2 ON (TC2.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
										and TC2.TABNAME <> @sTabName
										and TC2.DISPLAYSEQUENCE >= @pnDisplaySequence
										and TC2.DISPLAYSEQUENCE < @pnOldDisplaySequence)
		End
		set @nErrorCode = @@error
	End

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateTabControl to public
GO