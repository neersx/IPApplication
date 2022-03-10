-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_GetDefaultQuery
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_GetDefaultQuery]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_GetDefaultQuery.'
	Drop procedure [dbo].[ip_GetDefaultQuery]
	Print '**** Creating Stored Procedure dbo.ip_GetDefaultQuery...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ip_GetDefaultQuery
(
	@pnQueryKey		int 		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psCategory		nvarchar(50)	= null
)
-- PROCEDURE:	ip_GetDefaultQuery
-- VERSION :	3
-- DESCRIPTION:	This stored procedure returns a single query detail to be transformed into useable format in the Data Access.

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 03-OCT-2002  SF	1	Procedure created

as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int

Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set 	@pnQueryKey = null

	Select 	@pnQueryKey = SEARCHID
	from	SEARCHES
	where	CATEGORY = @psCategory
	and	IDENTITYID = @pnUserIdentityId
	and	USEASDEFAULT = 1

	Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.ip_GetDefaultQuery to public
GO
