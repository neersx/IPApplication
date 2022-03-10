-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertKeywordSynonym 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertKeywordSynonym]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertKeywordSynonym.'
	Drop procedure [dbo].[ipw_InsertKeywordSynonym]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertKeywordSynonym...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

-- Allow comparison of null values
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_InsertKeywordSynonym
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnKeywordKey		int,			-- Mandatory
	@pnKeywordSynonymKey	int,			-- Mandatory
	@pdtLastModifiedDate	datetime	= null OUTPUT
)
as
-- PROCEDURE:	ipw_InsertKeywordSynonym
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Inserts the synonym for a keyword.  Used by the Web version.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15 MAR 2012	KR	R8562	1	Procedure created

SET NOCOUNT OFF
SET CONCAT_NULL_YIELDS_NULL OFF

-- Reset so that next procedure gets the default
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)
declare @nCaseListNo int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
		Set @sSQLString = "Insert into SYNONYMS
		(
		KEYWORDNO,
		KWSYNONYM
		)
		Values
		(
		@pnKeywordKey,
		@pnKeywordSynonymKey
		)
		
		Select	@pdtLastModifiedDate = LOGDATETIMESTAMP
		from	SYNONYMS
		where	KEYWORDNO	= @pnKeywordKey
		and	KWSYNONYM	= @pnKeywordSynonymKey"
		
		exec @nErrorCode = sp_executesql @sSQLString,
		 				N'@pnKeywordKey		int,
		 				@pnKeywordSynonymKey	int,
		 				@pdtLastModifiedDate	datetime output',
						@pnKeywordKey			= @pnKeywordKey,
						@pnKeywordSynonymKey		= @pnKeywordSynonymKey,
						@pdtLastModifiedDate = 		@pdtLastModifiedDate output
						
		Select @pdtLastModifiedDate		as LastModifiedDate
			

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertKeywordSynonym to public
GO
