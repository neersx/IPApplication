-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteChecklistLetter
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteChecklistLetter]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteChecklistLetter.'
	Drop procedure [dbo].[ipw_DeleteChecklistLetter]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteChecklistLetter...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_DeleteChecklistLetter
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura	bit				= 0,
	@pnCriteriaKey			int,		-- Mandatory
    @pnLetterKey			smallint,	-- Mandatory
    @pbPassToDescendants        bit                     = 0,
    @pdtLastModifiedDate	datetime		= null
)
as
-- PROCEDURE:	ipw_DeleteChecklistLetter
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete the specified checklist letter.  Used by the Web version.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 08 NOV 2010	SF	RFC9193	1	Procedure created
-- 20 JAN 2011	SF	RFC9193 2	Correction.
-- 04 Feb 2011  LP      RFC9193 3       Allow deletion of the same checklist letter from descendants.       

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
		DELETE	CHECKLISTLETTER
		WHERE	CRITERIANO			= @pnCriteriaKey
		and		LETTERNO			= @pnLetterKey
		and		LOGDATETIMESTAMP	= @pdtLastModifiedDate'
		
	exec @nErrorCode = sp_executesql @sSQLString,
		 		  N'@pnCriteriaKey			int,		
					@pnLetterKey			smallint,	
					@pdtLastModifiedDate	datetime',
					@pnCriteriaKey			= @pnCriteriaKey,		
					@pnLetterKey			= @pnLetterKey,	
					@pdtLastModifiedDate	= @pdtLastModifiedDate
					
	If @nErrorCode = 0
	and @pbPassToDescendants = 1
	Begin
	        Set @sSQLString = N'
		Delete CL
		from dbo.fn_GetChildCriteria (@pnCriteriaKey,0) C
                join CHECKLISTLETTER CL on (CL.CRITERIANO=C.CRITERIANO)
                Where CL.LETTERNO = @pnLetterKey'                
		
	        exec @nErrorCode = sp_executesql @sSQLString,
		 		  N'@pnCriteriaKey			int,		
					@pnLetterKey			smallint',
					@pnCriteriaKey			= @pnCriteriaKey,		
					@pnLetterKey			= @pnLetterKey
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteChecklistLetter to public
GO
