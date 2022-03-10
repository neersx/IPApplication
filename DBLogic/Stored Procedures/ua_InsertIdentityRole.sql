-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_InsertIdentityRole
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_InsertIdentityRole]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_InsertIdentityRole.'
	Drop procedure [dbo].[ua_InsertIdentityRole]
End
Print '**** Creating Stored Procedure dbo.ua_InsertIdentityRole...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ua_InsertIdentityRole
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnIdentityKey		int,		-- Mandatory
	@pnRoleKey		int	-- Mandatory
)
as
-- PROCEDURE:	ua_InsertIdentityRole
-- VERSION:	2
-- DESCRIPTION:	Insert the identity role as required

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 18 Jun 2004	TM	RFC1499	1	Procedure created
-- 03 Dec 2007	vql	RFC5909	2	Change RoleKey and DocumentDefId from smallint to int.


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

declare	@nErrorCode		int
declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode 		= 0

-- Insert
If @nErrorCode = 0
Begin

	Set @sSQLString = " 
	insert 	into IDENTITYROLES
		(IDENTITYID, 
		 ROLEID)
	values	(@pnIdentityKey, 
		 @pnRoleKey)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnIdentityKey	int,
					  @pnRoleKey		int',
					  @pnIdentityKey	= @pnIdentityKey,
					  @pnRoleKey		= @pnRoleKey
End

Return @nErrorCode
GO

Grant execute on dbo.ua_InsertIdentityRole to public
GO
