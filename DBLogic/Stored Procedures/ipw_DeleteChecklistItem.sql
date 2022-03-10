-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteChecklistItem
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteChecklistItem]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteChecklistItem.'
	Drop procedure [dbo].[ipw_DeleteChecklistItem]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteChecklistItem...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE dbo.ipw_DeleteChecklistItem
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura	bit				= 0,
	@pnCriteriaKey			int,		-- Mandatory
    @pnQuestionKey			smallint,	-- Mandatory
    @pbPassToDescendants        bit                     = 0,
    @pdtLastModifiedDate	datetime		= null
)
as
-- PROCEDURE:	ipw_DeleteChecklistItem
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete the specified checklist item.  Used by the Web version.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 08 NOV 2010	SF		RFC9193	1		Procedure created
-- 21 JAN 2011	SF		RFC9193	2		Allow comparison of null values
-- 03 Feb 2011  LP      RFC9193 3       Allow deletion of ChecklistItem from descendants.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)


-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = N'
		DELETE	CHECKLISTITEM
		WHERE	CRITERIANO		= @pnCriteriaKey
		and	QUESTIONNO		= @pnQuestionKey
		and	LOGDATETIMESTAMP	= @pdtLastModifiedDate'
		
	exec @nErrorCode = sp_executesql @sSQLString,
		 		  N'@pnCriteriaKey			int,		
					@pnQuestionKey			smallint,	
					@pdtLastModifiedDate	datetime',
					@pnCriteriaKey			= @pnCriteriaKey,		
					@pnQuestionKey			= @pnQuestionKey,	
					@pdtLastModifiedDate	= @pdtLastModifiedDate
					
	If @nErrorCode = 0
	and @pbPassToDescendants = 1
	Begin
	        Set @sSQLString = N'
		Delete CI
		from dbo.fn_GetChildCriteria (@pnCriteriaKey,0) C
                join CHECKLISTITEM CI on (CI.CRITERIANO=C.CRITERIANO)
                Where CI.QUESTIONNO = @pnQuestionKey'
                
		
	        exec @nErrorCode = sp_executesql @sSQLString,
		 		  N'@pnCriteriaKey			int,		
					@pnQuestionKey			smallint',
					@pnCriteriaKey			= @pnCriteriaKey,		
					@pnQuestionKey			= @pnQuestionKey
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteChecklistItem to public
GO
