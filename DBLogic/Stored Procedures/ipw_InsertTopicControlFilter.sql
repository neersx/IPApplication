-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertTopicControlFilter
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertTopicControlFilter]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertTopicControlFilter.'
	Drop procedure [dbo].[ipw_InsertTopicControlFilter]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertTopicControlFilter...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ipw_InsertTopicControlFilter]
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pnTopicControlKey			int,
	@psFilterName				nvarchar(50)	= null,
	@psFilterValue				nvarchar(254)	= null,
	@pbApplyToDecendants		        bit		= 0
)
as
-- PROCEDURE:	ipw_InsertTopicControlFilter
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
	insert 	into TOPICCONTROLFILTER (TOPICCONTROLNO,FILTERNAME,FILTERVALUE)
	values (@pnTopicControlKey,@psFilterName,@psFilterValue)"

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
	insert into TOPICCONTROLFILTER (TOPICCONTROLNO, FILTERNAME, FILTERVALUE)
	select TC.TOPICCONTROLNO, @psFilterName, @psFilterValue
	from dbo.fn_GetChildCriteria (@nCriteriaNo,0) C
	join WINDOWCONTROL WC on (WC.CRITERIANO = C.CRITERIANO and WC.CRITERIANO != @nCriteriaNo and WC.WINDOWNAME = 'CaseDetails')
	join TOPICCONTROL TC on (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO and TC.TOPICNAME like @sTopicControlName)
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertTopicControlFilter to public
GO