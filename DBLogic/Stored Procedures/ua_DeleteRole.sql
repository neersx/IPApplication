-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_DeleteRole
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_DeleteRole]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_DeleteRole.'
	Drop procedure [dbo].[ua_DeleteRole]
End
Print '**** Creating Stored Procedure dbo.ua_DeleteRole...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ua_DeleteRole
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnRoleKey		int,	-- Mandatory
	@psOldRoleName		nvarchar(254)	= null,		
	@ptOldDescription	nvarchar(1000)	= null,
	@pbOldIsExternal 	bit		= null
)
as
-- PROCEDURE:	ua_DeleteRole
-- VERSION:	6
-- DESCRIPTION:	Delete a role if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 02 Apr 2004	TM	RFC917	1	Procedure created
-- 15 Apr 2004  TM	RFC917	2	Remove parameters for _TID columns. Use the Key version of a name 
--					in the stored procedure parameters. Replace @pbDescriptionModified
--					with current and old versions of the data. Implement new fn_IsNtextEqual
--					function to compare ntext strings. 
-- 18 Jun 2004	TM	RFC1499	3	Remove the @pnOldDefaultPortalKey parameter. Produce a user error if 
--					an attempt is made to delete a system role (IsProtected).
-- 21 Jun 2004	TM	RFC1499	4	In the substitution text in the error message use the role name not its key.
-- 20 Sep 2004	JEK	RFC1826	5	Change Description from ntext to nvarchar(1000).
--					Parameter prefix not changed for backwards compatability.
-- 03 Dec 2007	vql	RFC5909	6	Change RoleKey and DocumentDefId from smallint to int.
-- 18 Sep 2008	MS	RFC6779 7 Check if the users are present for the Role. If yes, 
--														then raise an XML Alert

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode		int
declare @sSQLString 		nvarchar(4000)

declare @sAlertXML 		nvarchar(400)
declare @bIsProtectedSystemRole bit

Declare @nRowCount		  int
Declare @sTranslatedRoleName    nvarchar(50)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode 		= 0
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)

-- Are users associated with this Role?
If ((Select count(*) from IDENTITYROLES where ROLEID = @pnRoleKey) > 0)
Begin
		-- Get the translated RoleName
	  Set @sSQLString = "
				SELECT @sTranslatedRoleName = "+dbo.fn_SqlTranslatedColumn('ROLE','ROLENAME',null,null,@sLookupCulture,0)+
				" from ROLE 
				where ROLEID = @pnRoleKey"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@sTranslatedRoleName  nvarchar(50)		OUTPUT,
						@pnRoleKey		int',
						@sTranslatedRoleName = @sTranslatedRoleName OUTPUT,
					  @pnRoleKey	= @pnRoleKey

		-- Raise an alert	
		Set @sAlertXML = dbo.fn_GetAlertXML('IP87', 'Role "{0}" cannot be deleted as it is assigned to one or more users. 
Please ensure that there are no users assigned to a Role before attempting to delete it.',
						'%s', null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1, @sTranslatedRoleName)
		Set @nErrorCode = @@ERROR
End


-- Is the role is a protected system role?
If @nErrorCode = 0 
Begin
	Set @sSQLString = " 
	Select @bIsProtectedSystemRole = ISPROTECTED
 	from ROLE 
	where ROLEID = @pnRoleKey"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@bIsProtectedSystemRole 	bit			  OUTPUT,
					  @pnRoleKey			int',	
					  @bIsProtectedSystemRole 	= @bIsProtectedSystemRole OUTPUT,				
					  @pnRoleKey			= @pnRoleKey					  				  
End

If @nErrorCode = 0 
and @bIsProtectedSystemRole = 1 
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('IP36', 'Role {0} is a protected system role and cannot be deleted.',
		@psOldRoleName, null, null, null, null)
	RAISERROR(@sAlertXML, 12, 1)
	Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	delete ROLE
	where	ROLEID 		= @pnRoleKey
	and	ROLENAME 	= @psOldRoleName		
	and	ISEXTERNAL 	= @pbOldIsExternal
	-- Use the fn_IsNtextEqual() function to compare ntext strings
	and 	dbo.fn_IsNtextEqual(DESCRIPTION, @ptOldDescription) = 1"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnRoleKey		int,
					  @psOldRoleName	nvarchar(254),					
					  @ptOldDescription	nvarchar(1000),
					  @pbOldIsExternal	bit',
					  @pnRoleKey		= @pnRoleKey,
					  @psOldRoleName	= @psOldRoleName,	
					  @ptOldDescription	= @ptOldDescription,					  
					  @pbOldIsExternal	= @pbOldIsExternal
End

Return @nErrorCode
GO

Grant execute on dbo.ua_DeleteRole to public
GO
