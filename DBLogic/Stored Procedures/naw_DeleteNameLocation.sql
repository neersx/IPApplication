-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_DeleteNameLocation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_DeleteNameLocation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_DeleteNameLocation.'
	Drop procedure [dbo].[naw_DeleteNameLocation]
End
Print '**** Creating Stored Procedure dbo.naw_DeleteNameLocation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_DeleteNameLocation
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int,	        -- Mandatory
	@pnFileLocationKey	int,	        -- Mandatory
	@pdtLastModifiedDate	datetime        = null
)
as
-- PROCEDURE:	naw_DeleteNameLocation
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete Staff Location.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 28 Jul 2011	MS	R100503	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @sSQLString 	nvarchar(4000)
Declare @nErrorCode	int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Delete from NAMELOCATION
		where	NAMENO = @pnNameKey
		and	FILELOCATION = @pnFileLocationKey
		and	(LOGDATETIMESTAMP = @pdtLastModifiedDate or 
		        (LOGDATETIMESTAMP is null and @pdtLastModifiedDate is null))"

	exec @nErrorCode=sp_executesql @sSQLString,
		N'
		@pnNameKey		int,
		@pnFileLocationKey	int,
		@pdtLastModifiedDate	datetime',
		@pnNameKey		= @pnNameKey,
		@pnFileLocationKey	= @pnFileLocationKey,
		@pdtLastModifiedDate	= @pdtLastModifiedDate

End

Return @nErrorCode
GO

Grant execute on dbo.naw_DeleteNameLocation to public
GO