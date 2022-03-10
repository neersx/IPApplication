-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateMainTelecom
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateMainTelecom]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateMainTelecom.'
	Drop procedure [dbo].[naw_UpdateMainTelecom]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateMainTelecom...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_UpdateMainTelecom
(
	@pnUserIdentityId	int,
	@psCulture		nvarchar (10),
	@pnNameKey		int,
	@pnTelecomTypeKey	int,
	@pnTelecomKey		int =null
)
as
-- PROCEDURE:	naw_UpdateMainTelecom
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This procedure updates the pointers to the main phone/fax/email held on the NAME table.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 10 Apr 2006	SW	RFC3503	1	Procedure created
-- 23 July 2008	Ash	RFC6728	2	Assign Default value to @pnTelecomKey

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0 and @pnTelecomTypeKey in (1901, 1902, 1903)
Begin

	If @pnTelecomTypeKey = 1901
		Set @sSQLString = '
			Update	[NAME]
			set	MAINPHONE	= @pnTelecomKey
			where	NAMENO		= @pnNameKey'

	If @pnTelecomTypeKey = 1902
		Set @sSQLString = '
			Update	[NAME]
			set	FAX		= @pnTelecomKey
			where	NAMENO		= @pnNameKey'

	If @pnTelecomTypeKey = 1903
		Set @sSQLString = '
			Update	[NAME]
			set	MAINEMAIL	= @pnTelecomKey
			where	NAMENO		= @pnNameKey'

	exec @nErrorCode = sp_executesql @sSQLString,
		N'
		@pnTelecomKey		int,
		@pnNameKey		int',
		@pnTelecomKey		= @pnTelecomKey,
		@pnNameKey		= @pnNameKey

End

Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateMainTelecom to public
GO
