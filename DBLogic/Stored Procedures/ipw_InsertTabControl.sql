-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertTabControl
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertTabControl]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertTabControl.'
	Drop procedure [dbo].[ipw_InsertTabControl]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertTabControl...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ipw_InsertTabControl]
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture					nvarchar(10) 	= null,
	@pnTabControlKey			int				= null	output,
	@pnWindowControlNo			int,
	@psTabName					nvarchar(50),
	@pnDisplaySequence			smallint,
	@psTabTitle					nvarchar(254),
	@pbIsInherited				bit				= 0,
	@pbApplyToDecendants		bit				= 0
)
as
-- PROCEDURE:	ipw_InsertTabControl
-- VERSION:	2
-- DESCRIPTION:	Add a new TabControl.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 22 Oct 2008	KR	RFC6732	1	Procedure created
-- 03 Feb 2009	JC	RFC6732	2	Fix issues

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode 	= 0

-- Insert new Tab
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	insert 	into TABCONTROL
	  (	WINDOWCONTROLNO, 
		TABNAME,
		DISPLAYSEQUENCE,
		TABTITLE,
		ISINHERITED
		)
	values	
	  (	@pnWindowControlNo,
		@psTabName,
		@pnDisplaySequence,
		@psTabTitle,
		@pbIsInherited	
		)
	Set @pnTabControlKey = SCOPE_IDENTITY()"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTabControlKey			int		output,
					  @pnWindowControlNo		int,
					  @psTabName				nvarchar(50),
					  @pnDisplaySequence		smallint,
					  @psTabTitle				nvarchar(254),
					  @pbIsInherited			bit',
					  @pnTabControlKey			= @pnTabControlKey output,					 
					  @pnWindowControlNo		= @pnWindowControlNo,
					  @psTabName				= @psTabName,
					  @pnDisplaySequence		= @pnDisplaySequence,
					  @psTabTitle				= @psTabTitle,
					  @pbIsInherited			= @pbIsInherited
					  
	Select @pnTabControlKey as TabControlKey

End

-- Apply to all children
If @nErrorCode = 0 and @pbApplyToDecendants = 1
Begin	
	--Retrieve information about the WINDOWCONTROL
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
	
	-- Insert new tab to all children. Condition: WINDOWCONTROL.ISINHERITED=1
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		insert 	into TABCONTROL
		  (	WINDOWCONTROLNO, 
			TABNAME,
			DISPLAYSEQUENCE,
			TABTITLE,
			ISINHERITED
			)
		Select WC.WINDOWCONTROLNO, 
			@psTabName,
			@pnDisplaySequence,
			@psTabTitle,
			1
		from dbo.fn_GetChildCriteria (@nCriteriaNo,@bIsNameCriteria) C
		join WINDOWCONTROL WC on ( ((@bIsNameCriteria = 0 and WC.CRITERIANO=C.CRITERIANO and WC.CRITERIANO != @nCriteriaNo) 
									or
									(@bIsNameCriteria = 1 and WC.NAMECRITERIANO=C.CRITERIANO and WC.NAMECRITERIANO != @nCriteriaNo))
									and WC.ISEXTERNAL = @bIsExternal
									and WC.WINDOWNAME = @sWindowName
									and WC.ISINHERITED = 1
								  )
		Left Join TABCONTROL TC ON (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
									and TC.TABNAME = @psTabName ) 
		where TC.WINDOWCONTROLNO is null"
		
		exec @nErrorCode=sp_executesql @sSQLString,
			N'@nCriteriaNo			int,
			  @bIsNameCriteria		bit,
			  @bIsExternal			bit,
			  @sWindowName			nvarchar(50),
			  @psTabName			nvarchar(50),
			  @pnDisplaySequence    smallint,
			  @psTabTitle           nvarchar(254)',					 
			  @nCriteriaNo			= @nCriteriaNo,
			  @bIsNameCriteria      = @bIsNameCriteria,
			  @bIsExternal			= @bIsExternal,
			  @sWindowName			= @sWindowName,
			  @psTabName			= @psTabName,
			  @pnDisplaySequence    = @pnDisplaySequence,
			  @psTabTitle			= @psTabTitle
	End

	-- Update all children tabs DISPLAYSEQUENCE
	If @nErrorCode = 0
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
										and WC.ISINHERITED = 1
									  )
			join TABCONTROL TC1 ON (TC1.WINDOWCONTROLNO = WC.WINDOWCONTROLNO -- Get TABCONTROL which has been just inserted
									 and TC1.TABNAME = @psTabName
									 and TC1.ISINHERITED = 1)
			join TABCONTROL TC2 ON (TC2.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
									and TC2.TABNAME <> @psTabName
									and TC2.DISPLAYSEQUENCE >= TC1.DISPLAYSEQUENCE)
			
		set @nErrorCode = @@error

	End
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertTabControl to public
GO