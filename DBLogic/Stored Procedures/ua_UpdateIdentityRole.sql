-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_UpdateIdentityRole
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_UpdateIdentityRole]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_UpdateIdentityRole.'
	Drop procedure [dbo].[ua_UpdateIdentityRole]
End
Print '**** Creating Stored Procedure dbo.ua_UpdateIdentityRole...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ua_UpdateIdentityRole
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnIdentityKey		int,		-- Mandatory
	@pnRoleKey		int	= null,
	@pnOldRoleKey		int	= null
)
as
-- PROCEDURE:	ua_UpdateIdentityRole
-- VERSION:	4
-- DESCRIPTION:	Update the identity role as required

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

-- Update
If @nErrorCode = 0
and @pnRoleKey <> @pnOldRoleKey
Begin
	Set @sSQLString = " 
	update	IDENTITYROLES
	set	ROLEID 		= @pnRoleKey
	where	IDENTITYID 	= @pnIdentityKey
	and	ROLEID		= @pnOldRoleKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnIdentityKey	int,
					  @pnRoleKey		int,
					  @pnOldRoleKey		int',
					  @pnIdentityKey	= @pnIdentityKey,
					  @pnRoleKey		= @pnRoleKey,
					  @pnOldRoleKey		= @pnOldRoleKey
End

Return @nErrorCode
GO

Grant execute on dbo.ua_UpdateIdentityRole to public
GO
