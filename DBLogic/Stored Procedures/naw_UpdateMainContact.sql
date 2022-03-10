-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateMainContact
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateMainContact]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateMainContact.'
	Drop procedure [dbo].[naw_UpdateMainContact]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateMainContact...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_UpdateMainContact
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int,		-- Mandatory
	@pnMainContactKey	int		= null
)
as
-- PROCEDURE:	naw_UpdateMainContact
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This procedure updates the pointer to the main contact held on the NAME table,
--		and recalculates any affected derived attention names on CASENAME

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 12 Apr 2006	SW	RFC3503	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode int
Declare @sSQLString nvarchar(4000)
Declare @nOldMainContactKey int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = N'
		Select	@nOldMainContactKey = MAINCONTACT
		from	NAME
		where	NAMENO = @pnNameKey'

	Exec @nErrorCode = sp_executesql @sSQLString, 
		N'@nOldMainContactKey	int		OUTPUT,
		  @pnNameKey		int',
		  @nOldMainContactKey			OUTPUT,
		  @pnNameKey		= @pnNameKey

End

If @nErrorCode = 0
Begin

	Set @sSQLString = N'
		Update	NAME
		set	MAINCONTACT = @pnMainContactKey
		where	NAMENO = @pnNameKey'

	Exec @nErrorCode = sp_executesql @sSQLString, 
		N'@pnMainContactKey	int,
		  @pnNameKey		int',
		  @pnMainContactKey	= @pnMainContactKey,
		  @pnNameKey		= @pnNameKey

End


If @nErrorCode = 0
Begin

	Exec @nErrorCode = dbo.cs_RecalculateDerivedAttention
				@pnMainNameKey = @pnNameKey,
				@pnOldAttentionKey = @nOldMainContactKey,
				@pnNewAttentionKey = @pnMainContactKey

End


Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateMainContact to public
GO
