-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteQuestion
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteQuestion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteQuestion.'
	Drop procedure [dbo].[ipw_DeleteQuestion]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteQuestion...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_DeleteQuestion
(
	@pnResult		int		= null output,	-- just an example
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnQuestionKey		int,
	@pdtLastModifiedDate	datetime
)
as
-- PROCEDURE:	ipw_DeleteQuestion
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Programmer comments here

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16 Nov 2010		KR		RFC9193	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare	@sSQLString	nvarchar(2000)
Declare @sAlertXML	nvarchar(1000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = 'Delete from QUESTION 
			   Where QUESTIONNO = @pnQuestionKey
			   AND (LOGDATETIMESTAMP is null or LOGDATETIMESTAMP = @pdtLastModifiedDate)'
	
	exec @nErrorCode=sp_executesql @sSQLString,
	N'@pnQuestionKey int,
	@pdtLastModifiedDate	datetime',
	@pnQuestionKey = @pnQuestionKey,
	@pdtLastModifiedDate = @pdtLastModifiedDate
	
	if (@@ROWCOUNT = 0)
	Begin
		-- BillMapProfile not found
		Set @sAlertXML = dbo.fn_GetAlertXML('CCQ1', 'Concurrency error. Question has been changed or deleted. Please reload and try again.',
							null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = 1
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteQuestion to public
GO
