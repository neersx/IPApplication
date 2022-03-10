-----------------------------------------------------------------------------------------------------------------------------
-- Creation of na_UpdateLastChanged
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_UpdateLastChanged]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.na_UpdateLastChanged.'
	Drop procedure [dbo].[na_UpdateLastChanged]
End
Print '**** Creating Stored Procedure dbo.na_UpdateLastChanged...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.na_UpdateLastChanged
(
	@pnUserIdentityId	int,		-- Mandatory
	@pnNameKey		int,
	@pdtLastChanged		datetime	= null
)
as
-- PROCEDURE:	na_UpdateLastChanged
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update the last date changed on NAME

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 11 Apr 2006	SW	RFC3503	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0 and @pdtLastChanged is null
Begin
	Exec @nErrorCode = dbo.ip_GetCurrentDate
		@pdtCurrentDate 	= @pdtLastChanged OUTPUT, 
		@pnUserIdentityId 	= @pnUserIdentityId,
		@psDateType 		= 'A',
		@pbIncludeTime		= 1

End

If @nErrorCode = 0
Begin
	Set @sSQLString = N'
		Update	NAME
		set	DATECHANGED = @pdtLastChanged
		where	NAMENO = @pnNameKey'

	Exec @nErrorCode = sp_executesql @sSQLString,
				N'@pdtLastChanged	datetime,
				  @pnNameKey		int',
				  @pdtLastChanged	= @pdtLastChanged,
				  @pnNameKey		= @pnNameKey
End

Return @nErrorCode
GO

Grant execute on dbo.na_UpdateLastChanged to public
GO
