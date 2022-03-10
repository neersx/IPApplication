-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdatePassword
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdatePassword]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdatePassword.'
	Drop procedure [dbo].[ipw_UpdatePassword]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdatePassword...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_UpdatePassword
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnIdentityKey		int,
	@pnOldPassword		binary(16)	= null,	-- Not required for system admininstrators
	@pnPassword		binary(16)
)
as
-- PROCEDURE:	ipw_UpdatePassword
-- VERSION:	5
-- DESCRIPTION:	Update the user's password.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 Dec 2003	JEK	RFC408	1	Procedure created
-- 06 Dec 2003	JEK	RFC408	2	Correct types.
-- 15 Mar 2004  TM	RFC1174	3	Test for the System Administrator Role (-1) instead of the IsAdministrator flag.
-- 23 Apr 2004	TM	RFC1339	4	Remove the logic that is using IDENTITYROLES.ROLEID = -1  for a particular 
--					user identity to determine if the user is System Administrator and raising 
--					an error if the user is not System Administrator.
-- 29 Oct 2007	LP	RFC5860	5	Implement logic to check user is in the same Access Account as external user
-- 30 Oct 2008  LP  RFC6891 6   Disable update for External Administrators attempting to update USERIDENTITY
--                              belonging to a different ACCESSACCOUNT


SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int
declare @sSQLString 	nvarchar(4000)
declare @sAlertXML 		nvarchar(400)
declare @bIsExternalUser	bit
declare @nHasMatch		int
declare @nCurrentAccessAccount	int

-- Initialise variables
Set @nErrorCode 	= 0

-- Extract the @pbIsExternalUser from UserIdentity if it has not been supplied.
If @nErrorCode=0
and @bIsExternalUser is null
Begin		
	Set @sSQLString='
	Select @bIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId'

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser	bit	OUTPUT,
				  @pnUserIdentityId	int',
				  @bIsExternalUser	=@bIsExternalUser	OUTPUT,
				  @pnUserIdentityId	=@pnUserIdentityId
End


If @nErrorCode = 0
Begin		
	Set @sSQLString="
	Select @bIsExternalUser=ISEXTERNALUSER,
	@nCurrentAccessAccount=ACCOUNTID
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser	bit	OUTPUT,
				  @pnUserIdentityId	int,
				  @nCurrentAccessAccount int OUTPUT',
				  @bIsExternalUser	=@bIsExternalUser	OUTPUT,
				  @pnUserIdentityId	=@pnUserIdentityId,
				  @nCurrentAccessAccount =@nCurrentAccessAccount OUTPUT
End

If @nErrorCode = 0
and @bIsExternalUser = 1
Begin
	Set @sSQLString="
	Select @nHasMatch = COUNT(IDENTITYID)
	from USERIDENTITY
	where ACCOUNTID = @nCurrentAccessAccount
	and IDENTITYID = @pnIdentityKey"

	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nHasMatch int OUTPUT,
			@pnIdentityKey int,
			@nCurrentAccessAccount int',
			@nHasMatch = @nHasMatch OUTPUT,
			@pnIdentityKey = @pnIdentityKey,
			@nCurrentAccessAccount = @nCurrentAccessAccount
End

If @nErrorCode = 0
and @nHasMatch = 0
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('IP5', 'You do not have sufficient security to update this password.',
		null, null, null, null, null)
	RAISERROR(@sAlertXML, 12, 1)
	Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	update 	USERIDENTITY
	set	PASSWORD = @pnPassword
	where	IDENTITYID = @pnIdentityKey
	and	((PASSWORD = @pnOldPassword) or (@pnOldPassword is null))"
	
	If @bIsExternalUser = 1 
    Begin 
        set @sSQLString = @sSQLString + char(10) + "and NAMENO in (SELECT NAMENO from dbo.fn_FilterUserViewNames("+convert(varchar,@pnUserIdentityId)+"))"
    End

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnIdentityKey	int,
					  @pnOldPassword	binary(16),
					  @pnPassword		binary(16)',
					  @pnIdentityKey	= @pnIdentityKey,
					  @pnOldPassword	= @pnOldPassword,
					  @pnPassword		= @pnPassword

End

If @nErrorCode = 0
and @@ROWCOUNT = 0
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('IP16', 'The old password is not correct.  Please re-enter.',
		null, null, null, null, null)
	RAISERROR(@sAlertXML, 12, 1)
	Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdatePassword to public
GO
