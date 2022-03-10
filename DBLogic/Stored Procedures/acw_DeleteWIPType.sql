-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_DeleteWIPType 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_DeleteWIPType]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_DeleteWIPType.'
	Drop procedure [dbo].[acw_DeleteWIPType]
End
Print '**** Creating Stored Procedure dbo.acw_DeleteWIPType...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.acw_DeleteWIPType
(
	@pnResult		int		= null output,	-- just an example
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@psWIPTypeCode		nvarchar(12),
	@pdtLastModifiedDate	datetime
)
as
-- PROCEDURE:	acw_DeleteWIPType
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Programmer comments here

-- MODIFICATIONS :
-- Date		Who	Number	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28 Nov 2011	KR	R10454	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare	@sSQLString	nvarchar(2000)
Declare @sAlertXML	nvarchar(1000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin

	Set @sSQLString = 'Delete from WIPTYPE 
			   Where WIPTYPEID = @psWIPTypeCode
			   AND (LOGDATETIMESTAMP is null or LOGDATETIMESTAMP = @pdtLastModifiedDate)'
	
	exec @nErrorCode=sp_executesql @sSQLString,
	N'@psWIPTypeCode nvarchar(12),
	@pdtLastModifiedDate	datetime',
	@psWIPTypeCode = @psWIPTypeCode,
	@pdtLastModifiedDate = @pdtLastModifiedDate
	
	
	if (@@ROWCOUNT = 0)
	Begin
		-- Case List not found
		Set @sAlertXML = dbo.fn_GetAlertXML('CCF1', 'Concurrency error. WIP Type has been changed or deleted. Please reload and try again.',
							null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = 1
	End
End

Return @nErrorCode
GO

Grant execute on dbo.acw_DeleteWIPType to public
GO
