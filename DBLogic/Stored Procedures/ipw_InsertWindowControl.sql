-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertWindowControl
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertWindowControl]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertWindowControl.'
	Drop procedure [dbo].[ipw_InsertWindowControl]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertWindowControl...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ipw_InsertWindowControl]
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture					nvarchar(10) 	= null,
	@pnWindowControlKey			int				= null	output,
	@pnCriteriaNo				int				= null,
	@pnNameCriteriaNo			int				= null,
	@psWindowName				nvarchar(50)	= null,
	@pbIsExternal				bit				= 0,
	@pnDisplaySequence			smallint		= null,
	@psWindowTitle				nvarchar(254)	= null,
	@psWindowShortTitle			nvarchar(254)	= null,
	@pnEntryNumber				smallint		= null,
	@psTheme					nvarchar(50)	= null,
	@pbIsInherited				bit				= 0,
	@pbApplyToDecendants		bit				= 0
)
as
-- PROCEDURE:	ipw_InsertWindowControl
-- VERSION:	1
-- DESCRIPTION:	Add a new WindowControl.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 21 Oct 2008	KR	RFC6732	1	Procedure created
-- 03 Feb 2009	JC	RFC6732	2	Rename psDisplaySequence to pnDisplaySequence

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode 	= 0

-- Insert new Window Control
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	insert 	into WINDOWCONTROL
	  (	CRITERIANO, 
		NAMECRITERIANO,
		WINDOWNAME,
		ISEXTERNAL,
		DISPLAYSEQUENCE,
		WINDOWTITLE,
		WINDOWSHORTTITLE,
		ENTRYNUMBER,
		THEME,
		ISINHERITED
		)
	values	
	  (	@pnCriteriaNo,
		@pnNameCriteriaNo,
		@psWindowName,
		@pbIsExternal,
		@pnDisplaySequence,
		@psWindowTitle,
		@psWindowShortTitle,
		@pnEntryNumber,
		@psTheme,
		@pbIsInherited		
		)
	Set @pnWindowControlKey = SCOPE_IDENTITY()"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnWindowControlKey		int		output,
					  @pnCriteriaNo				int,
					  @pnNameCriteriaNo			int,
					  @psWindowName				nvarchar(50),
					  @pbIsExternal				bit,
					  @pnDisplaySequence		smallint,
					  @psWindowTitle			nvarchar(254),
					  @psWindowShortTitle		nvarchar(254),
					  @pnEntryNumber			smallint,
					  @psTheme					nvarchar(50),
					  @pbIsInherited			bit',
					  @pnWindowControlKey		= @pnWindowControlKey output,					 
					  @pnCriteriaNo				= @pnCriteriaNo,
					  @pnNameCriteriaNo			= @pnNameCriteriaNo,
					  @psWindowName				= @psWindowName,
					  @pbIsExternal				= @pbIsExternal,
					  @pnDisplaySequence		= @pnDisplaySequence,
					  @psWindowTitle			= @psWindowTitle,
					  @psWindowShortTitle		= @psWindowShortTitle,
					  @pnEntryNumber			= @pnEntryNumber,
					  @psTheme					= @psTheme,
					  @pbIsInherited			= @pbIsInherited
					  
	Select @pnWindowControlKey as WindowControlKey

End

-- Apply to all children
if @nErrorCode = 0 and @pbApplyToDecendants = 1
Begin
	Declare @nCriteriaNo int
	Declare @bIsNameCriteria bit
	Set @nCriteriaNo = @pnCriteriaNo
	Set @bIsNameCriteria = 0
	
	If @pnNameCriteriaNo IS NOT NULL
	Begin
		Set @nCriteriaNo = @pnNameCriteriaNo
		Set @bIsNameCriteria = 1
	End

	Set @sSQLString = "
	insert 	into WINDOWCONTROL
	  (	CRITERIANO, 
		NAMECRITERIANO,
		WINDOWNAME,
		ISEXTERNAL,
		DISPLAYSEQUENCE,
		WINDOWTITLE,
		WINDOWSHORTTITLE,
		ENTRYNUMBER,
		THEME,
		ISINHERITED
		)
	Select CASE WHEN (@bIsNameCriteria = 0) THEN C.CRITERIANO ELSE NULL END, 
		CASE WHEN (@bIsNameCriteria = 1) THEN C.CRITERIANO ELSE NULL END,
		@psWindowName,
		@pbIsExternal,
		@pnDisplaySequence,
		@psWindowTitle,
		@psWindowShortTitle,
		@pnEntryNumber,
		@psTheme,
		1
	from dbo.fn_GetChildCriteria (@nCriteriaNo,@bIsNameCriteria) C
	left join WINDOWCONTROL WC on ( ((@bIsNameCriteria = 0 and WC.CRITERIANO=C.CRITERIANO) 
									or
									(@bIsNameCriteria = 1 and WC.NAMECRITERIANO=C.CRITERIANO))
									and WC.WINDOWNAME = @psWindowName
									and WC.ISEXTERNAL = @pbIsExternal
								  )
	where WC.WINDOWCONTROLNO is null"
	
	exec @nErrorCode=sp_executesql @sSQLString,
		N'@nCriteriaNo			int,
		  @bIsNameCriteria		bit,
		  @pbIsExternal			bit,
		  @psWindowName			nvarchar(50),
		  @pnDisplaySequence    smallint,
		  @psWindowTitle        nvarchar(254),
		  @psWindowShortTitle   nvarchar(254),
		  @pnEntryNumber		smallint,
		  @psTheme				nvarchar(50)',					 
		  @nCriteriaNo			= @nCriteriaNo,
		  @bIsNameCriteria      = @bIsNameCriteria,
		  @pbIsExternal			= @pbIsExternal,
		  @psWindowName			= @psWindowName,
		  @pnDisplaySequence	= @pnDisplaySequence,
		  @psWindowTitle		= @psWindowTitle,
		  @psWindowShortTitle	= @psWindowShortTitle,
		  @pnEntryNumber		= @pnEntryNumber,
		  @psTheme				= @psTheme
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertWindowControl to public
GO