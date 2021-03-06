-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteTabControl
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteTabControl]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteTabControl.'
	Drop procedure [dbo].[ipw_DeleteTabControl]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteTabControl...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ipw_DeleteTabControl]
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnTabControlNo			int,		-- Mandatory
	@pbApplyToDecendants		bit		= 0
)
as
-- PROCEDURE:	ipw_DeleteTabControl
-- VERSION:	6
-- DESCRIPTION:	Delete a TabControl if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 22 Oct 2008	KR	RFC6732	1	Procedure created
-- 05 Feb 2009	JC	RFC6732	2	Fix Issues
-- 13 May 2009	JC	RFC7880	3	Set IsInherited to false when @pbApplyToDecendants = 1
-- 22 Oct 2009	KR	RFC8009 4	Set IsInherited to false only to immediate children when @pbApplyToDecendants = 0
-- 28 Oct 2009	KR	RFC8009 5	bug fix
-- 09 May 2017	KR	71265	6	Delete the topics for a tab because we are unable to configure a cascade delete between
--					TOPICCONTROL and TABCONTROL

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode		int
declare @sSQLString 		nvarchar(4000)
declare @nCriteriaNo		int
declare @bIsNameCriteria	bit
declare @sWindowName		nvarchar(50)
declare @bIsExternal		bit
declare @sTabName		nvarchar(50)
declare @nDisplaySequence	smallint

-- Initialise variables
Set @nErrorCode 	= 0
Set @bIsNameCriteria	= 0
Set @bIsExternal	= 0
Set @nDisplaySequence	= 0

If @nErrorCode = 0
Begin	

	Set @sSQLString = "
	Select	@nCriteriaNo = isnull(WC.CRITERIANO,WC.NAMECRITERIANO),
			@bIsNameCriteria = CASE WHEN (WC.CRITERIANO IS NOT NULL) THEN 0 ELSE 1 END,
			@bIsExternal = WC.ISEXTERNAL,
			@sWindowName = WC.WINDOWNAME,
			@sTabName = TC.TABNAME,
			@nDisplaySequence = TC.DISPLAYSEQUENCE
	from TABCONTROL TC
	join WINDOWCONTROL WC on (WC.WINDOWCONTROLNO = TC.WINDOWCONTROLNO)
	where TC.TABCONTROLNO = @pnTabControlNo"

	Exec  @nErrorCode=sp_executesql @sSQLString,
			N'@nCriteriaNo			int OUTPUT,
			  @bIsNameCriteria		bit OUTPUT,
			  @bIsExternal			bit OUTPUT,
			  @sWindowName			nvarchar(50)	OUTPUT,
			  @sTabName			nvarchar(50)	OUTPUT,
			  @nDisplaySequence		smallint	OUTPUT,
			  @pnTabControlNo		int',
			  @nCriteriaNo		= @nCriteriaNo		OUTPUT,
			  @bIsNameCriteria	= @bIsNameCriteria	OUTPUT,
			  @bIsExternal		= @bIsExternal		OUTPUT,
			  @sWindowName		= @sWindowName		OUTPUT,
			  @sTabName		= @sTabName		OUTPUT,
			  @nDisplaySequence	= @nDisplaySequence	OUTPUT,
			  @pnTabControlNo	= @pnTabControlNo
End

--Delete the topics for the tab
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Delete	TOPICCONTROL
	Where	TABCONTROLNO	= @pnTabControlNo"
		
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTabControlNo	int',
					  @pnTabControlNo	= @pnTabControlNo
End

--Delete the tab
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Delete	TABCONTROL
	Where	TABCONTROLNO	= @pnTabControlNo"
		
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTabControlNo	int',
					  @pnTabControlNo	= @pnTabControlNo
End

If @nErrorCode = 0
Begin
	If @pbApplyToDecendants = 1
	Begin
		-- Decrement DISPLAYSEQUENCE for children
		UPDATE TC2 SET TC2.DISPLAYSEQUENCE = TC2.DISPLAYSEQUENCE - 1
			from dbo.fn_GetChildCriteria (@nCriteriaNo,@bIsNameCriteria) C
			join WINDOWCONTROL WC	on (WC.WINDOWNAME = @sWindowName
						and (
							(@bIsNameCriteria = 0 and WC.CRITERIANO=C.CRITERIANO and WC.CRITERIANO != @nCriteriaNo)
							or
							(@bIsNameCriteria = 1 and WC.NAMECRITERIANO=C.CRITERIANO and WC.NAMECRITERIANO != @nCriteriaNo)
							)
						and WC.ISEXTERNAL = @bIsExternal
						and WC.ISINHERITED = 1
						)
			join TABCONTROL TC1	ON (TC1.WINDOWCONTROLNO = WC.WINDOWCONTROLNO -- Get TABCONTROL which has been just deleted
						and TC1.TABNAME = @sTabName
						and TC1.ISINHERITED = 1)
			join TABCONTROL TC2	ON (TC2.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
						and TC2.TABNAME <> @sTabName
						and TC2.DISPLAYSEQUENCE >= TC1.DISPLAYSEQUENCE)
			
		set @nErrorCode = @@error

		If @nErrorCode = 0
		Begin
			Set @sSQLString = " 
			Delete TC
			from dbo.fn_GetChildCriteria (@nCriteriaNo,@bIsNameCriteria) C
			Join WINDOWCONTROL WC on ( ((@bIsNameCriteria = 0 and WC.CRITERIANO=C.CRITERIANO and WC.CRITERIANO != @nCriteriaNo) 
							or
							(@bIsNameCriteria = 1 and WC.NAMECRITERIANO=C.CRITERIANO and WC.NAMECRITERIANO != @nCriteriaNo))
							and WC.ISEXTERNAL = @bIsExternal
							and WC.WINDOWNAME = @sWindowName
							)
			Join TABCONTROL TC	ON (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
						and TC.TABNAME = @sTabName
						and TC.ISINHERITED = 1 
						and TC.TABCONTROLNO != @pnTabControlNo)"

			exec @nErrorCode=sp_executesql @sSQLString,
				N'@nCriteriaNo			int,
				  @bIsNameCriteria		bit,
				  @bIsExternal			bit,
				  @sWindowName			nvarchar(50),
				  @sTabName			nvarchar(50),
				  @pnTabControlNo		int',
				  @nCriteriaNo			= @nCriteriaNo,
				  @bIsNameCriteria		= @bIsNameCriteria,
				  @bIsExternal			= @bIsExternal,
				  @sWindowName			= @sWindowName,
				  @sTabName			= @sTabName,
				  @pnTabControlNo		= @pnTabControlNo

		End
	End
	Else
	Begin
		
		UPDATE TC1 SET TC1.ISINHERITED = 0
			from (select * from dbo.fn_GetChildCriteria (@nCriteriaNo,@bIsNameCriteria) where DEPTH = 2) C
			join WINDOWCONTROL WC	on (WC.WINDOWNAME = @sWindowName
						and (
							(@bIsNameCriteria = 0 and WC.CRITERIANO=C.CRITERIANO and WC.CRITERIANO != @nCriteriaNo)
							or
							(@bIsNameCriteria = 1 and WC.NAMECRITERIANO=C.CRITERIANO and WC.NAMECRITERIANO != @nCriteriaNo)
							)
						and WC.ISEXTERNAL = @bIsExternal
						and WC.ISINHERITED = 1
						)
			join TABCONTROL TC1	ON (TC1.WINDOWCONTROLNO = WC.WINDOWCONTROLNO -- Get TABCONTROL which has been just deleted
						and TC1.TABNAME = @sTabName
						and TC1.ISINHERITED = 1)
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteTabControl to public
GO
