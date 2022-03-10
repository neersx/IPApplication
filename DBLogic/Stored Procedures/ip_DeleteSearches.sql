-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_DeleteSearches
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_DeleteSearches]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_DeleteSearches.'
	Drop procedure [dbo].[ip_DeleteSearches]
	Print '**** Creating Stored Procedure dbo.ip_DeleteSearches...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ip_DeleteSearches
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnQueryKey		int
)
-- PROCEDURE:	ip_DeleteSearches
-- VERSION :	4
-- DESCRIPTION:	This stored procedure deletes a saved query from the database.

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 02-OCT-2002  SF	1	Procedure created
-- 03-OCT-2002	SF	2	Changed some parameter names
as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int

Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Delete	
	from	[SEARCHES]
	where	SEARCHID = @pnQueryKey		

	Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.ip_DeleteSearches to public
GO
