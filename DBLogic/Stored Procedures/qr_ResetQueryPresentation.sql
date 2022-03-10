-----------------------------------------------------------------------------------------------------------------------------
-- Creation of qr_ResetQueryPresentation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[qr_ResetQueryPresentation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.qr_ResetQueryPresentation.'
	Drop procedure [dbo].[qr_ResetQueryPresentation]
End
Print '**** Creating Stored Procedure dbo.qr_ResetQueryPresentation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.qr_ResetQueryPresentation
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnPresentationKey	int,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	qr_ResetQueryPresentation
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete the columns for the specified presentation.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 03 Nov 2010	LP	RFC9543	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(max)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	
	Set @sSQLString = " 
	Delete
	from	QUERYCONTENT
	where	PRESENTATIONID 	= @pnPresentationKey"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnPresentationKey		int',
					  @pnPresentationKey		= @pnPresentationKey
End

Return @nErrorCode
GO

Grant execute on dbo.qr_ResetQueryPresentation to public
GO
