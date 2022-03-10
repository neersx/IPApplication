-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_DeleteIdentityRole
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_DeleteIdentityRole]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_DeleteIdentityRole.'
	Drop procedure [dbo].[ua_DeleteIdentityRole]
End
Print '**** Creating Stored Procedure dbo.ua_DeleteIdentityRole...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ua_DeleteIdentityRole
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnIdentityKey		int,		-- Mandatory
	@pnOldRoleKey		int	-- Mandatory
)
as
-- PROCEDURE:	ua_DeleteIdentityRole
-- VERSION:	4
-- DESCRIPTION:	Delete the identity role as required

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 18 Jun 2004	TM	RFC1499	1	Procedure created
-- 21 Jun 2004	TM	RFC1499	2	In the substitution text in the error message use the role name not its key.
-- 01 Sep 2004	TM	RFC1712	3	Remove logic that produces alert IP36.
-- 03 Dec 2007	vql	RFC5909	4	Change RoleKey and DocumentDefId from smallint to int.


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

declare	@nErrorCode		int
declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode 		= 0

-- Delete
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	delete 	IDENTITYROLES
	where	IDENTITYID 	= @pnIdentityKey
	and	ROLEID		= @pnOldRoleKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnIdentityKey	int,
					  @pnOldRoleKey		int',
					  @pnIdentityKey	= @pnIdentityKey,
					  @pnOldRoleKey		= @pnOldRoleKey
End

Return @nErrorCode
GO

Grant execute on dbo.ua_DeleteIdentityRole to public
GO
