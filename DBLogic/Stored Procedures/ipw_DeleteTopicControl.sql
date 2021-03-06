-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteTopicControl
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteTopicControl]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteTopicControl.'
	Drop procedure [dbo].[ipw_DeleteTopicControl]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteTopicControl...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ipw_DeleteTopicControl]
(
	@pnUserIdentityId			int,			-- Mandatory
	@psCulture					nvarchar(10) 	= null,
	@pnTopicControlNo			int,			-- Mandatory
	@pbApplyToDecendants		bit				= 0
)
as
-- PROCEDURE:	ipw_DeleteTopicControl
-- VERSION:	2
-- DESCRIPTION:	Delete a TopicControl if the underlying values are as expected.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 22 Oct 2008	KR		RFC6732	1		Procedure created
-- 05 Feb 2009	JC		RFC6732	2		Fix Issues


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode			int
declare @sSQLString 		nvarchar(4000)
declare @nCriteriaNo		int
declare @bIsNameCriteria	bit
declare @sWindowName		nvarchar(50)
declare @bIsExternal		bit
declare @sTabName			nvarchar(50)
declare @sTopicName			nvarchar(50)
declare @sTopicSuffix		nvarchar(50)

-- Initialise variables
Set @nErrorCode = 0
Set @bIsNameCriteria = 0
Set @bIsExternal = 0

If @nErrorCode = 0 and @pbApplyToDecendants = 1
Begin	
	-- Get information about the deleted topic
	Set @sSQLString = "
	Select	@nCriteriaNo = isnull(WC.CRITERIANO,WC.NAMECRITERIANO),
			@bIsNameCriteria = CASE WHEN (WC.CRITERIANO IS NOT NULL) THEN 0 ELSE 1 END,
			@bIsExternal = WC.ISEXTERNAL,
			@sWindowName = WC.WINDOWNAME,
			@sTabName = TC.TABNAME,
			@sTopicName = TP.TOPICNAME,
			@sTopicSuffix = TP.TOPICSUFFIX
	from TOPICCONTROL TP
	join WINDOWCONTROL WC on (WC.WINDOWCONTROLNO = TP.WINDOWCONTROLNO)
	left join TABCONTROL TC on (TC.TABCONTROLNO = TP.TABCONTROLNO)
	where TP.TOPICCONTROLNO = @pnTopicControlNo"

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
End

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	delete	TOPICCONTROL
	where	TOPICCONTROLNO		= @pnTopicControlNo"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTopicControlNo		int',
					  @pnTopicControlNo		= @pnTopicControlNo
End

If @nErrorCode = 0 and @pbApplyToDecendants = 1
Begin
	-- Update ROWPOSITION for all childs
	UPDATE TP2 SET TP2.ROWPOSITION = TP2.ROWPOSITION - 1
		from dbo.fn_GetChildCriteria (@nCriteriaNo,@bIsNameCriteria) C
		Join WINDOWCONTROL WC on ( ((@bIsNameCriteria = 0 and WC.CRITERIANO=C.CRITERIANO and WC.CRITERIANO != @nCriteriaNo) 
									or
									(@bIsNameCriteria = 1 and WC.NAMECRITERIANO=C.CRITERIANO and WC.NAMECRITERIANO != @nCriteriaNo))
									and WC.ISEXTERNAL = @bIsExternal
									and WC.WINDOWNAME = @sWindowName
								  )
		Left Join TABCONTROL TC ON (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
									and TC.TABNAME = @sTabName)
		Join TOPICCONTROL TP1 ON (TP1.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
								and (TC.TABCONTROLNO is null or TP1.TABCONTROLNO = TC.TABCONTROLNO)
								and TP1.TOPICNAME = @sTopicName
								and TP1.ISINHERITED = 1
								and (
										(@sTopicSuffix is null and TP1.TOPICSUFFIX is null)
									 or (@sTopicSuffix is not null and TP1.TOPICSUFFIX = @sTopicSuffix)
									))
		Join TOPICCONTROL TP2 ON (TP2.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
								and (TC.TABCONTROLNO is null or TP2.TABCONTROLNO = TC.TABCONTROLNO)
								and TP2.TOPICNAME != @sTopicName
								and (
										(@sTopicSuffix is null and TP2.TOPICSUFFIX is null)
									 or (@sTopicSuffix is not null and TP2.TOPICSUFFIX != @sTopicSuffix)
									)
								and TP2.ROWPOSITION > TP1.ROWPOSITION)

	set @nErrorCode = @@error

	If @nErrorCode = 0 
	Begin
		Set @sSQLString = " 
		Delete TP
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
								and TP.ISINHERITED = 1
								and (
										(@sTopicSuffix is null and TP.TOPICSUFFIX is null)
									 or (@sTopicSuffix is not null and TP.TOPICSUFFIX = @sTopicSuffix)
									)
								and not exists (SELECT EC.ELEMENTCONTROLNO FROM ELEMENTCONTROL EC WHERE EC.ISINHERITED=0 AND EC.TOPICCONTROLNO=TP.TOPICCONTROLNO)
								)"
								
		exec @nErrorCode=sp_executesql @sSQLString,
			N'@nCriteriaNo				int,
			  @bIsNameCriteria			bit,
			  @bIsExternal				bit,
			  @sWindowName				nvarchar(50),
			  @sTabName					nvarchar(50),
			  @sTopicName				nvarchar(50),
			  @sTopicSuffix				nvarchar(50)',
			  @nCriteriaNo				= @nCriteriaNo,
			  @bIsNameCriteria			= @bIsNameCriteria,
			  @bIsExternal				= @bIsExternal,
			  @sWindowName				= @sWindowName,
			  @sTabName					= @sTabName,
			  @sTopicName				= @sTopicName,
			  @sTopicSuffix				= @sTopicSuffix

	End
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteTopicControl to public
GO
