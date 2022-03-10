-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_GetDebtorStatusPassword
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_GetDebtorStatusPassword]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_GetDebtorStatusPassword.'
	Drop procedure [dbo].[naw_GetDebtorStatusPassword]
End
Print '**** Creating Stored Procedure dbo.naw_GetDebtorStatusPassword...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_GetDebtorStatusPassword
(
	@psDebtorStatusPassword	nvarchar(10)	= null	output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnDebtorStatusKey		int	 -- Mandatory
)
as
-- PROCEDURE:	naw_GetDebtorStatusPassword
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the password corresponding to the Debtor Status key.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19 Jan 2009	PS	RFC7383	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = '
		Select		@psDebtorStatusPassword= CLEARPASSWORD 
		from		DEBTORSTATUS where BADDEBTOR = @pnDebtorStatusKey'

	Exec @nErrorCode = sp_executesql @sSQLString,
				N'@psDebtorStatusPassword		nvarchar(10) output,
				  @pnDebtorStatusKey		int',
				  @psDebtorStatusPassword		= @psDebtorStatusPassword output,
				  @pnDebtorStatusKey		= @pnDebtorStatusKey

End

Return @nErrorCode
GO

Grant execute on dbo.naw_GetDebtorStatusPassword to public
GO
