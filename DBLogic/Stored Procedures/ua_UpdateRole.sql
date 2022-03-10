-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_UpdateRole
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_UpdateRole]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_UpdateRole.'
	Drop procedure [dbo].[ua_UpdateRole]
End
Print '**** Creating Stored Procedure dbo.ua_UpdateRole...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ua_UpdateRole
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	
	@pnRoleKey		int,	-- Mandatory	
	@psRoleName		nvarchar(254)	= null,	
	@ptDescription		nvarchar(1000)	= null,	
	@pbIsExternal 		bit		= null,
	@psOldRoleName		nvarchar(254)	= null,	
	@ptOldDescription	nvarchar(1000)	= null,		
	@pbOldIsExternal 	bit		= null	
)
as
-- PROCEDURE:	ua_UpdateRole
-- VERSION:	5
-- DESCRIPTION:	Update a role if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 Apr 2004	TM	RFC917	1	Procedure created
-- 15 Apr 2004  TM	RFC917	2	Remove parameters for _TID columns. Use the Key version of a name 
--					in the stored procedure parameters. Replace @pbDescriptionModified
--					with current and old versions of the data. Implement new fn_IsNtextEqual
--					function to compare ntext strings. 
-- 18 Jun 2004	TM	RFC1499	3	Remove the @pnDefaultPortalKey and @pnOldDefaultPortalKey parameters.
-- 20 Sep 2004	JEK	RFC1826	4	Change Description from ntext to nvarchar(1000).
--					Parameter prefix not change for backwards compatability.
-- 03 Dec 2007	vql	RFC5909	5	Change RoleKey and DocumentDefId from smallint to int.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode 		= 0

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	update 	ROLE
	set	ROLENAME 	 = @psRoleName, 
		DESCRIPTION 	 = @ptDescription, 		
		ISEXTERNAL 	 = @pbIsExternal
	where	ROLEID	 	 = @pnRoleKey
	and	ROLENAME 	 = @psOldRoleName	
	-- Use the fn_IsNtextEqual() function to compare ntext strings
	and 	dbo.fn_IsNtextEqual(DESCRIPTION, @ptOldDescription) = 1"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnRoleKey		int,
					  @psRoleName		nvarchar(254),
					  @ptDescription	nvarchar(1000),					 
					  @pbIsExternal 	bit,
					  @psOldRoleName	nvarchar(254),					
					  @ptOldDescription	nvarchar(1000)',
					  @pnRoleKey		= @pnRoleKey,
					  @psRoleName		= @psRoleName,
					  @ptDescription	= @ptDescription,					
					  @pbIsExternal		= @pbIsExternal,
					  @psOldRoleName 	= @psOldRoleName,					 
					  @ptOldDescription	= @ptOldDescription
End

Return @nErrorCode
GO

Grant execute on dbo.ua_UpdateRole to public
GO
