-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateKeyword									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateKeyword]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateKeyword.'
	Drop procedure [dbo].[csw_UpdateKeyword]
End
Print '**** Creating Stored Procedure dbo.csw_UpdateKeyword...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_UpdateKeyword
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnCaseKey			int,		-- Mandatory
	@pnKeywordKey			int,		-- Mandatory
	@pnOldKeywordKey		int,		-- Mandatory
	@pdtLastModifiedDate		datetime	= null output
)
as
-- PROCEDURE:	csw_UpdateKeyword
-- VERSION:	1
-- DESCRIPTION:	Update an official number if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 Apr 2012	KR	R10134	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sUpdateString 		nvarchar(4000)
Declare @sWhereString		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0
Set @sWhereString = CHAR(10)+" where "

If @nErrorCode = 0
Begin
	Set @sUpdateString = "Update CASEWORDS
				   set	KEYWORDNO = @pnKeywordKey"

	Set @sWhereString = @sWhereString+CHAR(10)+"
		    CASEID = @pnCaseKey 
		and KEYWORDNO = @pnOldKeywordKey"

	If @pdtLastModifiedDate is not null
	Begin
		Set @sWhereString = @sWhereString+" and LOGDATETIMESTAMP = @pdtLastModifiedDate"
	End
	
	Set @sSQLString = @sUpdateString + @sWhereString

	exec @nErrorCode=sp_executesql @sSQLString,
		      N'@pdtLastModifiedDate	datetime output,
			@pnCaseKey		int,
			@pnKeywordKey		int,
			@pnOldKeywordKey	int',
			@pdtLastModifiedDate	= @pdtLastModifiedDate output,
			@pnCaseKey	 	= @pnCaseKey,
			@pnKeywordKey		= @pnKeywordKey,
			@pnOldKeywordKey	= @pnOldKeywordKey
End

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateKeyword to public
GO