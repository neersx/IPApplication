-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateMainAddress
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateMainAddress]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateMainAddress.'
	Drop procedure [dbo].[naw_UpdateMainAddress]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateMainAddress...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_UpdateMainAddress
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int,
	@pnAddressTypeKey	int,		-- Mandatory, expecting 301 or 302
	@pnAddressKey		int		= null


)
as
-- PROCEDURE:	naw_UpdateMainAddress
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This procedure updates the pointers to the main postal/street addresses held on the NAME table

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 Jun 2006	SW	RFC3787	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)

Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	-- do postal address
	If @pnAddressTypeKey = 301
	Begin
		Set @sSQLString = '
			Update	[NAME]
			Set	POSTALADDRESS = @pnAddressKey
			where	NAMENO = @pnNameKey'
	End
	
	-- do street address
	If @pnAddressTypeKey = 302
	Begin
		Set @sSQLString = '
			Update	[NAME]
			Set	STREETADDRESS = @pnAddressKey
			where	NAMENO = @pnNameKey'
	End
	
	If @sSQLString is not null
	Begin
		Exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @pnAddressKey		int',
					  @pnNameKey		= @pnNameKey,
					  @pnAddressKey		= @pnAddressKey
	End
End

Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateMainAddress to public
GO
