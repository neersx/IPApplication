-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListTopicDefaultSettings
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListTopicDefaultSettings]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListTopicDefaultSettings.'
	Drop procedure [dbo].[ipw_ListTopicDefaultSettings]
End
Print '**** Creating Stored Procedure dbo.ipw_ListTopicDefaultSettings...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[ipw_ListTopicDefaultSettings]
(
	@pnRowCount		int		= null output,	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCriteriaNo		int		= null,
	@pnNameCriteriaNo	int		= null
)
as
-- PROCEDURE:	ipw_ListTopicDefaultSettings
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List Default Settings for Case Criteria / Name Criteria

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 18 Dec 2009	MS	RFC8469	1	Procedure created
-- 16 Jun 2011	LP	RFC10851 2	Add FILTERVALUE to the RowKey to make it unique.
-- 08 Jul 2011  MS      RFC10851 3      USe DEFAULTSETTINGNO as RowKey  
-- 29 Aug 2011  MS      RFC11024 4      Get ISINHERITED in resultset              

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET ANSI_NULLS OFF

declare	@nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @bHasChildren   bit

-- Initialise variables
Set @nErrorCode = 0
Set @bHasChildren = 0

If @nErrorCode = 0
Begin
        If @pnCriteriaNo is not null
        Begin
                Set @sSQLString = "Select @bHasChildren = 1 from INHERITS where FROMCRITERIA = @pnCriteriaNo"
                
                exec @nErrorCode=sp_executesql @sSQLString,
			N'@bHasChildren		bit     output,
			  @pnCriteriaNo	        int',
			  @bHasChildren		= @bHasChildren         output,
			  @pnCriteriaNo	        = @pnCriteriaNo
        End
        Else
        Begin
                Select @bHasChildren = 1 from NAMECRITERIAINHERITS where FROMNAMECRITERIANO = @pnNameCriteriaNo
                
                exec @nErrorCode=sp_executesql @sSQLString,
			N'@bHasChildren		bit     output,
			  @pnNameCriteriaNo	int',
			  @bHasChildren		= @bHasChildren         output,
			  @pnNameCriteriaNo	= @pnNameCriteriaNo
        End
End

If @nErrorCode = 0
Begin
	
	Set @sSQLString = "Select 
		DEFAULTSETTINGNO as 'RowKey',
		CRITERIANO      as 'CriteriaNo',
	        NAMECRITERIANO	as 'NameCriteriaNo',
		TOPICNAME	as 'TopicName',
		FILTERNAME	as 'FilterName',
		FILTERVALUE	as 'FilterValue',
		ISINHERITED     as 'IsInherited'
		from TOPICDEFAULTSETTINGS
		where CRITERIANO = @pnCriteriaNo
		and NAMECRITERIANO = @pnNameCriteriaNo"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnCriteriaNo		int,
			  @pnNameCriteriaNo	int',
			  @pnCriteriaNo		= @pnCriteriaNo,
			  @pnNameCriteriaNo	= @pnNameCriteriaNo
End

If @nErrorCode = 0
Begin
       Select ISNULL(@pnCriteriaNo, @pnNameCriteriaNo) as RowKey,          
              @bHasChildren   as 'HasChildren'
                
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListTopicDefaultSettings to public
GO

