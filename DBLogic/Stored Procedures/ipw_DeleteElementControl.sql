-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteElementControl
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteElementControl]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteElementControl.'
	Drop procedure [dbo].[ipw_DeleteElementControl]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteElementControl...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ipw_DeleteElementControl]
(
	@pnUserIdentityId			int,			-- Mandatory
	@psCulture					nvarchar(10) 	= null,
	@pnElementControlNo			int,			-- Mandatory
	@pbApplyToDecendants		bit				= 0
)
as
-- PROCEDURE:	ipw_DeleteElementControl
-- VERSION:	2
-- DESCRIPTION:	Delete a ElementControl if the underlying values are as expected.

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

declare	@nErrorCode				int
declare @sSQLString 			nvarchar(4000)
declare @nCriteriaNo			int
declare @bIsNameCriteria		bit
declare @sWindowName			nvarchar(50)
declare @bIsExternal			bit
declare @sTabName				nvarchar(50)
declare @sTopicName				nvarchar(50)
declare @sTopicSuffix			nvarchar(50)
declare @sElementName			nvarchar(50)

-- Initialise variables
Set @nErrorCode	= 0
Set @bIsNameCriteria = 0
Set @bIsExternal = 0

If @nErrorCode = 0 and @pbApplyToDecendants = 1
Begin	

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

End

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	delete	ELEMENTCONTROL
	where	ELEMENTCONTROLNO	= @pnElementControlNo"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnElementControlNo	int',
					  @pnElementControlNo	= @pnElementControlNo
End


If @nErrorCode = 0 and @pbApplyToDecendants = 1
Begin	
	Set @sSQLString = " 
	Delete EC
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
								and EC.ELEMENTNAME = @sElementName)"

	exec @nErrorCode=sp_executesql @sSQLString,
		N'@nCriteriaNo				int,
		  @bIsNameCriteria			bit,
		  @bIsExternal				bit,
		  @sWindowName				nvarchar(50),
		  @sTabName					nvarchar(50),
		  @sTopicName				nvarchar(50),
		  @sTopicSuffix				nvarchar(50),
		  @sElementName				nvarchar(50)',
		  @nCriteriaNo				= @nCriteriaNo,
		  @bIsNameCriteria			= @bIsNameCriteria,
		  @bIsExternal				= @bIsExternal,
		  @sWindowName				= @sWindowName,
		  @sTabName					= @sTabName,
		  @sTopicName				= @sTopicName,
		  @sTopicSuffix				= @sTopicSuffix,
		  @sElementName				= @sElementName
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteElementControl to public
GO
