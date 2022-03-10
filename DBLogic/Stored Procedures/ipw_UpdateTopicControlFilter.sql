-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateTopicControlFilter
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateTopicControlFilter]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateTopicControlFilter.'
	Drop procedure [dbo].[ipw_UpdateTopicControlFilter]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateTopicControlFilter...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ipw_UpdateTopicControlFilter]
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pnTopicControlKey			int,
	@psFilterName				nvarchar(50)	= null,
	@psFilterValue				nvarchar(254)	= null,
	@pbApplyToDecendants		        bit		= 0
)
as
-- PROCEDURE:	ipw_UpdateTopicControlFilter
-- VERSION:	1
-- DESCRIPTION:	Add a new TopicControl filter.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 20 Jun 2013	vql	RFC8511	1	Provide the ability to display Name Text of a given Name Type and Text Type within Case program.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode 	= 0

-- Insert new topic filter
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	update TOPICCONTROLFILTER
	set FILTERNAME = @psFilterName, FILTERVALUE = @psFilterValue
	where TOPICCONTROLNO = @pnTopicControlKey and FILTERNAME = @psFilterName"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTopicControlKey	int,
					  @psFilterName		nvarchar(50),
					  @psFilterValue	nvarchar(254)',					 
					  @pnTopicControlKey	= @pnTopicControlKey,					 
					  @psFilterName		= @psFilterName,
					  @psFilterValue	= @psFilterValue

	Select @pnTopicControlKey as TopicControlKey
End

-- Apply to all children
If @nErrorCode = 0 and @pbApplyToDecendants = 1
Begin	
	--Get information about TOPICCONTROLNO new TOPICCONTROLFILTER
	declare @nCriteriaNo		int
	declare @sTopicControlName	nvarchar(50)	

	Set @sSQLString = "
	Select	@nCriteriaNo = WC.CRITERIANO, @sTopicControlName = TC.TOPICNAME
	from WINDOWCONTROL WC
	join TOPICCONTROL TC on (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO)
	where TC.TOPICCONTROLNO = @pnTopicControlKey"

	Exec  @nErrorCode=sp_executesql @sSQLString,
			N'@nCriteriaNo		int OUTPUT,
			  @sTopicControlName	nvarchar(50) OUTPUT,
			  @pnTopicControlKey	int',
			  @nCriteriaNo		= @nCriteriaNo		OUTPUT,
			  @sTopicControlName	= @sTopicControlName	OUTPUT,
			  @pnTopicControlKey	= @pnTopicControlKey

	--Insert new topic to all children.
	update T
	set T.FILTERVALUE = @psFilterValue
	from TOPICCONTROLFILTER T
	join TOPICCONTROL TC on (TC.TOPICCONTROLNO = T.TOPICCONTROLNO and TC.TOPICNAME like @sTopicControlName)
	join WINDOWCONTROL WC on (WC.WINDOWNAME = 'CaseDetails' and WC.WINDOWCONTROLNO = TC.WINDOWCONTROLNO)
	join dbo.fn_GetChildCriteria (@nCriteriaNo,0) C on (WC.CRITERIANO = C.CRITERIANO and WC.CRITERIANO != @nCriteriaNo)
	where T.FILTERNAME = @psFilterName

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateTopicControlFilter to public
GO