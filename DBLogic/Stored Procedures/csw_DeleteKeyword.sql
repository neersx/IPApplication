-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_DeleteKeyword
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_DeleteKeyword]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_DeleteKeyword.'
	Drop procedure [dbo].[csw_DeleteKeyword]
End
Print '**** Creating Stored Procedure dbo.csw_DeleteKeyword...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_DeleteKeyword
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,	
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory	
	@pnKeywordKey			int,		-- Mandatory	
	@pdtLastModifiedDate		datetime	= null
)
as
-- PROCEDURE:	csw_DeleteKeyword
-- VERSION:	1
-- DESCRIPTION:	Delete an official number if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 Apr 2012	KR	R10134	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode 		= 0

If  @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Delete 
	from CASEWORDS	
	where	CASEID 		= @pnCaseKey
	and 	KEYWORDNO	= @pnKeywordKey"
	
	If (@pdtLastModifiedDate is not null)
	Begin
		Set @sSQLString = @sSQLString + "
		and	LOGDATETIMESTAMP = @pdtLastModifiedDate
		" 
	End

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnCaseKey		int,
				  @pnKeywordKey		int,
				  @pdtLastModifiedDate	datetime',
				  @pnCaseKey		= @pnCaseKey,
				  @pnKeywordKey		= @pnKeywordKey,
				  @pdtLastModifiedDate	= @pdtLastModifiedDate
End

Return @nErrorCode
GO

Grant execute on dbo.csw_DeleteKeyword to public
GO
