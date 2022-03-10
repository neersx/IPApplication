-----------------------------------------------------------------------------------------------------------------------------
-- Creation of util_PublishQuery
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].util_PublishQuery') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.util_PublishQuery.'
	Drop procedure [dbo].util_PublishQuery
End
Print '**** Creating Stored Procedure dbo.util_PublishQuery...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.util_PublishQuery
(
	@pnQueryID		int	-- Query ID of a saved search that to be published to all external users.
)
as
-- PROCEDURE:	util_PublishQuery
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	A utility to allow an existing saved external search to be converted to a
--		public (protected) saved search available to all external users

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 May 2007	SW	RFC4795	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @pnQueryID is not null
Begin
	Set @sSQLString = "
		Update	QUERY
		set	ISPUBLICTOEXTERNAL = 1
		where	QUERYID = @pnQueryID 
		"

	Exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnQueryID		int',
				  @pnQueryID		= @pnQueryID
		
End


Return @nErrorCode
GO

Grant execute on dbo.util_PublishQuery to public
GO
