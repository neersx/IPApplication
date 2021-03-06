-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateWindowControl
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateWindowControl]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateWindowControl.'
	Drop procedure [dbo].[ipw_UpdateWindowControl]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateWindowControl...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[ipw_UpdateWindowControl]
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture					nvarchar(10) 	= null,
	@pnWindowControlNo			int,		-- Mandatory
	@pnDisplaySequence			smallint		= null,
	@psWindowTitle				nvarchar(254)	= null,
	@psWindowShortTitle			nvarchar(254)	= null,
	@pnEntryNumber				smallint		= null,
	@psTheme					nvarchar(50)	= null,
	@pbIsInherited				bit				= 0,
	@pnOldDisplaySequence		smallint		= null,
	@psOldWindowTitle			nvarchar(254)	= null,
	@psOldWindowShortTitle		nvarchar(254)	= null,
	@pnOldEntryNumber			smallint		= null,
	@psOldTheme					nvarchar(50)	= null,
	@pbOldIsInherited			bit				= 0,
	@pbApplyToDecendants		bit				= 0
)
as
-- PROCEDURE:	ipw_UpdateWindowControl
-- VERSION:	2
-- DESCRIPTION:	Update a Window Control.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 29 Oct 2008	KR	RFC6732	1	Procedure created
-- 03 Feb 2009	JC	RFC6732	2	Fix Issues

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
	Update	WINDOWCONTROL
	Set		DISPLAYSEQUENCE	= @pnDisplaySequence,
			WINDOWTITLE		= @psWindowTitle,
			WINDOWSHORTTITLE= @psWindowShortTitle,
			ENTRYNUMBER		= @pnEntryNumber,
			THEME			= @psTheme,
			ISINHERITED		= @pbIsInherited
	Where	WINDOWCONTROLNO = @pnWindowControlNo 
	And		DISPLAYSEQUENCE	= @pnOldDisplaySequence
	And		WINDOWTITLE		= @psOldWindowTitle
	And		WINDOWSHORTTITLE= @psOldWindowShortTitle
	And		ENTRYNUMBER		= @pnOldEntryNumber
	And		THEME			= @psOldTheme
	And		ISINHERITED		= @pbOldIsInherited"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnWindowControlNo		int,
					  @pnDisplaySequence		smallint,
					  @psWindowTitle			nvarchar(254),
					  @psWindowShortTitle		nvarchar(254),
					  @pnEntryNumber			smallint,
					  @psTheme					nvarchar(50),
					  @pbIsInherited			bit,
					  @pnOldDisplaySequence		smallint,
					  @psOldWindowTitle			nvarchar(254),
					  @psOldWindowShortTitle	nvarchar(254),
					  @pnOldEntryNumber			smallint,
					  @psOldTheme				nvarchar(50),
					  @pbOldIsInherited			bit',					 
					  @pnWindowControlNo		= @pnWindowControlNo,
					  @pnDisplaySequence		= @pnDisplaySequence,
					  @psWindowTitle			= @psWindowTitle,
					  @psWindowShortTitle		= @psWindowShortTitle,
					  @pnEntryNumber			= @pnEntryNumber,
					  @psTheme					= @psTheme,
					  @pbIsInherited			= @pbIsInherited,
					  @pnOldDisplaySequence		= @pnOldDisplaySequence,
					  @psOldWindowTitle			= @psOldWindowTitle,
					  @psOldWindowShortTitle	= @psOldWindowShortTitle,
					  @pnOldEntryNumber			= @pnOldEntryNumber,
					  @psOldTheme				= @psOldTheme,
					  @pbOldIsInherited			= @pbOldIsInherited

End

If @nErrorCode = 0 and @pbApplyToDecendants = 1
Begin	
	Declare @nCriteriaNo	int
	Declare @bIsNameCriteria	bit
	Declare @sWindowName nvarchar(50)
	Declare @bIsExternal bit

	Set @bIsNameCriteria = 0
	Set @bIsExternal = 0

	Set @sSQLString = "
	Select	@nCriteriaNo = isnull(CRITERIANO,NAMECRITERIANO),
			@bIsNameCriteria = CASE WHEN (CRITERIANO IS NOT NULL) THEN 0 ELSE 1 END,
			@sWindowName = WINDOWNAME,
			@bIsExternal = ISEXTERNAL
	from WINDOWCONTROL
	where WINDOWCONTROLNO = @pnWindowControlNo"

	Exec  @nErrorCode=sp_executesql @sSQLString,
			N'@nCriteriaNo			int OUTPUT,
			  @bIsNameCriteria		bit OUTPUT,
			  @bIsExternal			bit OUTPUT,
			  @sWindowName			nvarchar(50) OUTPUT,
			  @pnWindowControlNo	int',
			  @nCriteriaNo = @nCriteriaNo OUTPUT,
			  @bIsNameCriteria  = @bIsNameCriteria	OUTPUT,
			  @bIsExternal = @bIsExternal OUTPUT,
			  @sWindowName = @sWindowName OUTPUT,
			  @pnWindowControlNo = @pnWindowControlNo

	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Update	WC
			Set		DISPLAYSEQUENCE	= @pnDisplaySequence,
					WINDOWTITLE		= @psWindowTitle,
					WINDOWSHORTTITLE= @psWindowShortTitle,
					ENTRYNUMBER		= @pnEntryNumber,
					THEME			= @psTheme
		from dbo.fn_GetChildCriteria (@nCriteriaNo,@bIsNameCriteria) C
		join WINDOWCONTROL WC on ( ((@bIsNameCriteria = 0 and WC.CRITERIANO=C.CRITERIANO) 
									or
									(@bIsNameCriteria = 1 and WC.NAMECRITERIANO=C.CRITERIANO))
									and WC.ISEXTERNAL = @bIsExternal
									and WC.WINDOWNAME = @sWindowName
									and WC.ISINHERITED = 1
								  ) 
		Where	WC.DISPLAYSEQUENCE	= @pnOldDisplaySequence
		And		WC.WINDOWTITLE		= @psOldWindowTitle
		And		WC.WINDOWSHORTTITLE	= @psOldWindowShortTitle
		And		WC.ENTRYNUMBER		= @pnOldEntryNumber
		And		WC.THEME			= @psOldTheme"
		
		exec @nErrorCode=sp_executesql @sSQLString,
			N'@nCriteriaNo			int,
			  @bIsNameCriteria		bit,
			  @bIsExternal			bit,
			  @sWindowName			nvarchar(50),
			  @pnDisplaySequence    smallint,
			  @psWindowTitle        nvarchar(254),
			  @psWindowShortTitle	nvarchar(254),
			  @pnEntryNumber		smallint,
			  @psTheme				nvarchar(50),
			  @pnOldDisplaySequence		smallint,
			  @psOldWindowTitle			nvarchar(254),
			  @psOldWindowShortTitle	nvarchar(254),
			  @pnOldEntryNumber			smallint,
			  @psOldTheme				nvarchar(50)',					 
			  @nCriteriaNo			= @nCriteriaNo,
			  @bIsNameCriteria      = @bIsNameCriteria,
			  @bIsExternal			= @bIsExternal,
			  @sWindowName			= @sWindowName,
			  @pnDisplaySequence    = @pnDisplaySequence,
			  @psWindowTitle		= @psWindowTitle,
			  @psWindowShortTitle	= @psWindowShortTitle,
			  @pnEntryNumber		= @pnEntryNumber,
			  @psTheme				= @psTheme,
			  @pnOldDisplaySequence		= @pnOldDisplaySequence,
			  @psOldWindowTitle			= @psOldWindowTitle,
			  @psOldWindowShortTitle	= @psOldWindowShortTitle,
			  @pnOldEntryNumber			= @pnOldEntryNumber,
			  @psOldTheme				= @psOldTheme
	End

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateWindowControl to public
GO