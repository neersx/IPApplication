-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteUserIdentity
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteUserIdentity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteUserIdentity.'
	Drop procedure [dbo].[ipw_DeleteUserIdentity]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteUserIdentity...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_DeleteUserIdentity
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnIdentityKey		int		= null,
	@psOldLoginID		nvarchar(50)	= null,
	@pnOldAccountKey	int		= null,
	@pnOldPassword		binary(16)	= null,
	@pnOldNameKey		int		= null,
	@psOldEmailAddress	nvarchar(50)	= null,
	@pnOldPortalKey		int		= null,
	@pbOldIsExternal 	bit		= null,
	@pbOldIsLocked		bit		= null,
	@pnOldProfileKey        int             = null,
	@pbOldByPassEthicalWall	bit		= null
)
as
-- PROCEDURE:	ipw_DeleteUserIdentity
-- VERSION:	12
-- DESCRIPTION:	Delete a user identity if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 06 Dec 2003	JEK	RFC408	1	Procedure created
-- 22 Dec 2003	JEK	RFC408	2	Don't check concurrency on password.
-- 13 Feb 2004	TM	RFC708	3	Remove call to the ipw_MaintainIdentityRole stored procedure to delete the row 
--					from the IdentityRole because there is now cascade delete on IdentityRoles.  
-- 27 Feb 2004	TM	RFC622	4	Use IdentityRole with RoleID = - 1 to check if the user has system 
--					administration privileges not the IsAdministrator flag. Add a new @pbOldIsExternal  
--					parameter, and modify the logic to delete the UserIdentity provided that the value 
--					is unchanged. Also check if the Role Key value id unchanged. Add validation logic 
--					to ensure that the user with IsAdministrator = 1 is not deleted.   
-- 23 Apr 2004	TM	RFC1339	5	Remove the logic that is using IDENTITYROLES.ROLEID = -1  for a particular 
--					user identity to determine if the user is System Administrator and raising 
--					an error if the user is not System Administrator.
-- 18 Jun 2004	TM	RFC1499	6	Remove the @pnOldRoleKey parameter. Add a @pnOldPortalKey parameter.
-- 24 Jan 2007	LP	RFC4981	7	Add @pbOldIsLocked parameter.
-- 11 Aug 2008	PS      RFC6103 8       Delete rows from MODULECONFIGURATION table where IDENTITYID is equal to the 
--                                      @pnIdentityKey, before deleting user from USERIDENTITY table. 
-- 09 Sep 2009  LP      RFC8047 9       Add @pnOldProfileKey parameter.
-- 23 Feb 2011	DV	RFC10132 10     Delete all roes from SESSION table for the passed IDENTITYID
-- 31 Jan 2012  MS      RFC11786 11     Delete rows from MODULECONFIGURATION table where TABID is equal to the 
--                                      TABID from PORTALTAB where IDENTITYID is @pnIdentityKey
-- 03 May 2015	DV	R60353	13	Add check for column BYPASSETHICALWALL (DR-19934)



SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode			int
declare @sSQLString 			nvarchar(4000)
declare @sAlertXML 			nvarchar(400)
declare @bIsCPAInprostartAdministrator	bit

-- Initialise variables
Set @nErrorCode 		= 0

-- Is the user to be deleted is Special Administrator user for CPA Inprostart?
If @nErrorCode = 0 
Begin
	Set @sSQLString = " 
	Select @bIsCPAInprostartAdministrator = ISADMINISTRATOR
 	from USERIDENTITY 		
	where IDENTITYID = @pnIdentityKey"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnIdentityKey		 int,		
					  @bIsCPAInprostartAdministrator bit				  OUTPUT',				
					  @pnIdentityKey		 = @pnIdentityKey,
					  @bIsCPAInprostartAdministrator = @bIsCPAInprostartAdministrator OUTPUT					  
End

If @nErrorCode = 0 
and @bIsCPAInprostartAdministrator = 1 
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('IP25', 'The administrator user cannot be deleted.',
		null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	delete SESSION				  
	where	IDENTITYID	= @pnIdentityKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnIdentityKey	int',
					  @pnIdentityKey	= @pnIdentityKey
End

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	delete MODULECONFIGURATION				  
	where  TABID in (Select TABID from PORTALTAB where IDENTITYID = @pnIdentityKey)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnIdentityKey	int',
					  @pnIdentityKey	= @pnIdentityKey
End


If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	delete USERIDENTITY				  
	where	IDENTITYID	= @pnIdentityKey
	and	LOGINID 	= @psOldLoginID
	and	NAMENO 		= @pnOldNameKey
	and	ACCOUNTID 	= @pnOldAccountKey
	and 	ISEXTERNALUSER 	= @pbOldIsExternal	
	and	DEFAULTPORTALID	= @pnOldPortalKey
	and 	ISLOCKED	= @pbOldIsLocked
	and     PROFILEID       = @pnOldProfileKey
	and	BYPASSETHICALWALL = @pbOldByPassEthicalWall"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnIdentityKey	int,
					  @psOldLoginID		nvarchar(50),					  
					  @pnOldNameKey		int,
					  @pnOldAccountKey 	int,
					  @pbOldIsExternal	bit,					 
					  @pnOldPortalKey	int,
					  @pbOldIsLocked	bit,
					  @pnOldProfileKey      int,
					  @pbOldByPassEthicalWall bit',
					  @pnIdentityKey	= @pnIdentityKey,
					  @psOldLoginID		= @psOldLoginID,					 
					  @pnOldNameKey		= @pnOldNameKey,
					  @pnOldAccountKey	= @pnOldAccountKey,
					  @pbOldIsExternal	= @pbOldIsExternal,
					  @pnOldPortalKey	= @pnOldPortalKey,
					  @pbOldIsLocked	= @pbOldIsLocked,
					  @pnOldProfileKey      = @pnOldProfileKey,
					  @pbOldByPassEthicalWall = @pbOldByPassEthicalWall
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteUserIdentity to public
GO
