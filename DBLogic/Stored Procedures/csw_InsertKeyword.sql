-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertKeyword
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertKeyword]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_InsertKeyword.'
	Drop procedure [dbo].[csw_InsertKeyword]
End
Print '**** Creating Stored Procedure dbo.csw_InsertKeyword...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_InsertKeyword
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,	
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory	
	@pnKeywordKey			int,		-- Mandatory
	@pdtLastModifiedDate		datetime	= null output,
	@psRowKey			nvarchar(50)	= null output
)
as
-- PROCEDURE:	csw_InsertKeyword
-- VERSION:	1
-- DESCRIPTION:	Insert new official number.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	------- --------------------------------------- 
-- 04 Apr 2012	KR	R10134	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(max)

-- Initialise variables
Set @nErrorCode 	= 0

If @nErrorCode = 0
Begin
	
	Set @sSQLString = " 
	insert 	into CASEWORDS
		(CASEID, 
		 KEYWORDNO)
	values	(@pnCaseKey,
		 @pnKeywordKey)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pdtLastModifiedDate	datetime output,
					  @psRowKey		nvarchar(50) output,
					  @pnCaseKey		int,
					  @pnKeywordKey		int',
					  @pdtLastModifiedDate	= @pdtLastModifiedDate output,
					  @psRowKey		= @psRowKey output,
					  @pnCaseKey		= @pnCaseKey,
					  @pnKeywordKey		= @pnKeywordKey		
	
End

Return @nErrorCode
GO

Grant execute on dbo.csw_InsertKeyword to public
GO