-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_InsertRole
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_InsertRole]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_InsertRole.'
	Drop procedure [dbo].[ua_InsertRole]
End
Print '**** Creating Stored Procedure dbo.ua_InsertRole...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ua_InsertRole
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnRoleKey		int	= null,	-- Included to provide a standard interface
	@psRoleName		nvarchar(254)	= null,
	@ptDescription		nvarchar(1000)	= null,	
	@pbIsExternal 		bit		= null
)
as
-- PROCEDURE:	ua_InsertRole
-- VERSION:	8
-- DESCRIPTION:	Add a new Role, returning the generated Role key.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 02 Apr 2004	TM	RFC917	1	Procedure created
-- 14 Apr 2004	TM	RFC917	2	Remove parameters for _TID columns. Use the Key version of a name 
--					in the stored procedure parameters.
-- 18 Jun 2004	TM	RFC1499	3	Remove @pnDefaultPortalKey parameter. Add @pnIsProtected parameter.
-- 15 Sep 2004	TM	RFC1822	4	Use IDENT_CURRENT('table_name') instead of the @@IDENTITY to publish the key.
-- 20 Sep 2004 	TM	RFC1822	5	Implement SCOPE_IDENTITY() IDENT_CURRENT and move this logic inside the
--					SQL string executed by sp_executesql.
-- 20 Sep 2004	JEK	RFC1826	6	Change Description from ntext to nvarchar(1000).
--					Parameter prefix not changed for backwards compatability.
-- 31 Jan 2005	TM	RFC2253	7	Modify @ptDescription datatype in the sp_executesql.
-- 03 Dec 2007	vql	RFC5909	8	Change RoleKey and DocumentDefId from smallint to int.


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode 	= 0

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	insert 	into ROLE
		(ROLENAME, 
		 DESCRIPTION, 		 
		 ISEXTERNAL)
	values	(@psRoleName,
		 @ptDescription, 		
		 @pbIsExternal)

	Set @pnRoleKey = SCOPE_IDENTITY()"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnRoleKey		int	OUTPUT,
					  @psRoleName		nvarchar(254),
					  @ptDescription	nvarchar(1000),					 
					  @pbIsExternal		bit',
					  @pnRoleKey		= @pnRoleKey	OUTPUT,
					  @psRoleName		= @psRoleName,
					  @ptDescription	= @ptDescription,					 
					  @pbIsExternal		= @pbIsExternal	

	-- Publish the key so that the dataset is updated
	Select @pnRoleKey as RoleKey
End

Return @nErrorCode
GO

Grant execute on dbo.ua_InsertRole to public
GO