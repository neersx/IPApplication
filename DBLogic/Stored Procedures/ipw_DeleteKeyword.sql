-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteKeyword 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteKeyword]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteKeyword.'
	Drop procedure [dbo].[ipw_DeleteKeyword]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteKeyword...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_DeleteKeyword
(
	@pnResult		int		= null output,	-- just an example
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnKeywordKey		int,
	@pdtLastModifiedDate	datetime
)
as
-- PROCEDURE:	ipw_DeleteKeyword
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delates a keyword from teh KEYWORDS table.

-- MODIFICATIONS :
-- Date			Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15 MAR 2012		KR	R8562	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare	@sSQLString	nvarchar(2000)
Declare @sAlertXML	nvarchar(1000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin

	Set @sSQLString = 'Delete from KEYWORDS 
			   Where KEYWORDNO = @pnKeywordKey
			   AND (LOGDATETIMESTAMP is null or LOGDATETIMESTAMP = @pdtLastModifiedDate)'
		
	exec @nErrorCode=sp_executesql @sSQLString,
	N'@pnKeywordKey		int,
	@pdtLastModifiedDate	datetime',
	@pnKeywordKey		= @pnKeywordKey,
	@pdtLastModifiedDate	= @pdtLastModifiedDate
End
	
if (@@ROWCOUNT = 0)
Begin
	-- Keyword not found
	Set @sAlertXML = dbo.fn_GetAlertXML('CCF1', 'Concurrency error. Keyword has been changed or deleted. Please reload and try again.',
						null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = 1
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteKeyword to public
GO
