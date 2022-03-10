-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteKeywordSynonym 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteKeywordSynonym]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteKeywordSynonym.'
	Drop procedure [dbo].[ipw_DeleteKeywordSynonym]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteKeywordSynonym...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_DeleteKeywordSynonym
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnKeywordKey		int,
	@pnKeywordSynonymKey	int,
	@pdtLastModifiedDate	datetime
)
as
-- PROCEDURE:	ipw_DeleteKeywordSynonym
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Deletes cases list members

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15 MAR 2012	KR	RFC8562	1	Procedure created

SET NOCOUNT OFF
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare	@sSQLString	nvarchar(2000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = 'Delete from SYNONYMS 
			   Where KEYWORDNO = @pnKeywordKey
			   AND	KWSYNONYM = @pnKeywordSynonymKey
			   AND (LOGDATETIMESTAMP = @pdtLastModifiedDate or LOGDATETIMESTAMP is null)'
	
	exec @nErrorCode=sp_executesql @sSQLString,
	N'@pnKeywordKey		int,
	@pnKeywordSynonymKey	int,
	@pdtLastModifiedDate	datetime',
	@pnKeywordKey		= @pnKeywordKey,
	@pnKeywordSynonymKey	= @pnKeywordSynonymKey,
	@pdtLastModifiedDate	= @pdtLastModifiedDate
	
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteKeywordSynonym to public
GO
