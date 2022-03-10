-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateUserIdentity
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateUserIdentity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateUserIdentity.'
	Drop procedure [dbo].[ipw_UpdateUserIdentity]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateUserIdentity...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_UpdateUserIdentity
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnIdentityKey		int,		-- Mandatory
	@psLoginID		nvarchar(50)	= null,
	@pnAccountKey		int		= null,
	@pnPassword		binary(16)	= null,
	@pnNameKey		int		= null,
	@psEmailAddress		nvarchar(100)	= null,
	@pnPortalKey		int		= null,
	@pbIsExternal 		bit		= null,
	@pbIsLocked		bit		= null,
	@pnProfileKey           int             = null,
	@pbByPassEthicalWall	bit		= 0,
        @pdWriteDownLimit       decimal(11,2)   = null,
	@psOldLoginID		nvarchar(50)	= null,
	@pnOldAccountKey	int		= null,
	@pnOldPassword		binary(16)	= null,
	@pnOldNameKey		int		= null,
	@psOldEmailAddress	nvarchar(100)	= null,
	@pnOldPortalKey		int		= null,
	@pbOldIsExternal 	bit		= null,
	@pbOldIsLocked		bit		= null,
	@pnOldProfileKey        int             = null,
	@pbOldByPassEthicalWall	bit		= null,
        @pdOldWriteDownLimit    decimal(11,2)   = null
)
as
-- PROCEDURE:	ipw_UpdateUserIdentity
-- VERSION:	14
-- DESCRIPTION:	Update a user identity if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 06 Dec 2003	JEK	RFC408	1	Procedure created
-- 22 Dec 2003	JEK	RFC408	2	Don't check concurrency on password, or update password.
-- 27 Feb 2004	TM	RFC622	3	Use IdentityRole with RoleID = - 1 to check if the user has system 
--					administration privileges not the IsAdministrator flag.Add new @pbIsExternal 
--					and @pbOldIsExternal parameters, and modify the logic to update 
--					UserIdentity.IsExternal. Implement validation to ensure that password is present.
-- 30 Mar 2004	TM	RFC1288	4	After the IdentityRole and/or EmailAddress is inserted, the IsValidWorkBench flag 
--					still needs to be set on the UserIdentity.
-- 06 Apr 2004	TM	RFC1294	5	Ensure that IsValidInprostart is set to 1
-- 23 Apr 2004	TM	RFC1339	6	Remove the logic that is using IDENTITYROLES.ROLEID = -1  for a particular 
--					user identity to determine if the user is System Administrator and raising 
--					an error if the user is not System Administrator.
-- 18 Jun 2004	TM	RFC1499	7	Remove the @pnRoleKey and @pnOldRoleKey parameters. Add a @pnPortalKey and 
--					@pnOldPortalKey parameters.
-- 15 Apr 2005	TM	RFC1609	8	Remove mandatory password checking from the stored procedure, this now needs 
--					to be implemented in the business layer.
-- 01 Jul 2005	JEK	RFC2770	9	Modify maintenance of email address where name has also changed.
-- 23 Jan 2007	LP	RFC4981	10	Update ISLOCKED and INVALIDLOGINS columns as necessary.
-- 22 Nov 2007	SW	RFC5967	11	Change TELECOMMUNICATION.TELECOMNUMBER from nvarchar(50) to nvarchar(100).
-- 09 Sep 2009  LP      RFC8047 12      Add PROFILEID field.
-- 03 May 2015	DV	R60353	13	Add column BYPASSETHICALWALL (DR-19934)
-- 23 Mar 2018  MS      R73454  14      Add UserIdentity.WriteDownLimit column

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode		int
declare @sSQLString 		nvarchar(4000)
declare @sAlertXML 		nvarchar(400)
declare @bIsDuplicateLoginID	bit
declare @sOldEmailAddress	nvarchar(100)

-- Initialise variables
Set @nErrorCode 		= 0
Set @bIsDuplicateLoginID	= 0

-- Is the LoginID a duplicate?
If @nErrorCode = 0
and @psOldLoginID <> @psLoginID
Begin
	Set @sSQLString = " 
	Select @bIsDuplicateLoginID = 1
	from USERIDENTITY 
	where upper(@psLoginID) = upper(LOGINID)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@psLoginID		nvarchar(50),
					  @bIsDuplicateLoginID	bit		output',
					  @psLoginID		= @psLoginID,
					  @bIsDuplicateLoginID	= @bIsDuplicateLoginID	output

End

If @nErrorCode = 0 
and @bIsDuplicateLoginID = 1
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('IP6', 'Login Id {0} is already in use.',
		'%s', null, null, null, null)
	RAISERROR(@sAlertXML, 12, 1, @psLoginID)
	Set @nErrorCode = @@ERROR
End

-- If the email address has changed, maintain it against the name.
If @nErrorCode = 0
and @psOldEmailAddress <> @psEmailAddress
and @pnOldNameKey = @pnNameKey
Begin
	exec @nErrorCode = naw_MaintainMainTelecom
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnNameKey		= @pnNameKey,
		@pnTelecomTypeKey	= 1903,
		@psTelecomNumber	= @psEmailAddress,
		@psOldTelecomNumber	= @psOldEmailAddress
End

-- If the name has changed, check whether the email address needs to be maintained.
If @nErrorCode = 0
and @pnNameKey <> @pnOldNameKey
Begin
	-- Get the current email address against the name
	If @nErrorCode = 0
	Begin
		Set @sSQLString = " 
		Select  @sOldEmailAddress = dbo.fn_FormatTelecom(E.TELECOMTYPE, E.ISD, E.AREACODE, E.TELECOMNUMBER, E.EXTENSION)	
		from 	NAME N
		join 	TELECOMMUNICATION E on (E.TELECODE = N.MAINEMAIL)			 	
		where N.NAMENO = @pnNameKey"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnNameKey		int,
						  @sOldEmailAddress	nvarchar(100)		output',
						  @pnNameKey		= @pnNameKey,
						  @sOldEmailAddress	= @sOldEmailAddress	output
	
	End
	
	-- If the email address has changed, maintain it against the name.
	If @nErrorCode = 0
	and @sOldEmailAddress <> @psEmailAddress
	Begin
		exec @nErrorCode = naw_MaintainMainTelecom
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@pnNameKey		= @pnNameKey,
			@pnTelecomTypeKey	= 1903,
			@psTelecomNumber	= @psEmailAddress,
			@psOldTelecomNumber	= @sOldEmailAddress
	End
End

If @nErrorCode = 0
and (	@psLoginID 	<> @psOldLoginID or
	@pnNameKey 	<> @pnOldNameKey or
	@pnAccountKey 	<> @pnOldAccountKey or
	@pbIsExternal	<> @pbOldIsExternal or
	@psEmailAddress <> @psOldEmailAddress or
	@pnOldPortalKey <> @pnPortalKey or
	@pbIsLocked	<> @pbOldIsLocked or
	@pnProfileKey   <> @pnOldProfileKey or
	@pbByPassEthicalWall <> @pbOldByPassEthicalWall or 
        @pdWriteDownLimit <> @pdOldWriteDownLimit
    )
Begin

	Set @sSQLString = " 
	update 	USERIDENTITY
	set	LOGINID 	 = @psLoginID, 
		NAMENO		 = @pnNameKey, 
		ISEXTERNALUSER	 = @pbIsExternal, 
		ACCOUNTID	 = @pnAccountKey,
		ISVALIDINPROSTART= 1,
		ISVALIDWORKBENCH = 1,
		DEFAULTPORTALID	 = @pnPortalKey,
		ISLOCKED	 = @pbIsLocked,
		PROFILEID        = @pnProfileKey,
		BYPASSETHICALWALL = @pbByPassEthicalWall,
		INVALIDLOGINS	 = CASE WHEN @pbIsLocked = 0 THEN 0 ELSE INVALIDLOGINS END,
                WRITEDOWNLIMIT   = @pdWriteDownLimit 
	where	IDENTITYID	 = @pnIdentityKey
	and	LOGINID 	 = @psOldLoginID
	and	NAMENO 		 = @pnOldNameKey
	and	ACCOUNTID 	 = @pnOldAccountKey
	and     ISEXTERNALUSER	 = @pbOldIsExternal
	and     DEFAULTPORTALID  = @pnOldPortalKey
	and     PROFILEID        = @pnOldProfileKey
	and 	ISLOCKED	 = @pbOldIsLocked
	and	BYPASSETHICALWALL = @pbOldByPassEthicalWall
        and     WRITEDOWNLIMIT   = @pdOldWriteDownLimit"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnIdentityKey	int,
					  @psLoginID		nvarchar(50),
					  @pnAccountKey		int,
					  @pnNameKey		int,
					  @pnPortalKey		int,
					  @psOldLoginID		nvarchar(50),
					  @pnOldAccountKey 	int,
					  @pnOldNameKey		int,
					  @pbIsExternal		bit,					  
					  @pbOldIsExternal	bit,
					  @pnOldPortalKey	int,
					  @pbIsLocked		bit,
					  @pbOldIsLocked	bit,
					  @pnProfileKey         int,
					  @pnOldProfileKey      int,
					  @pbByPassEthicalWall	bit,
					  @pbOldByPassEthicalWall	bit,
                                          @pdWriteDownLimit     decimal(11,2),
                                          @pdOldWriteDownLimit  decimal(11,2)',
					  @pnIdentityKey	= @pnIdentityKey,
					  @psLoginID		= @psLoginID,
					  @pnAccountKey		= @pnAccountKey,
					  @pnNameKey		= @pnNameKey,
					  @pnPortalKey		= @pnPortalKey,
					  @psOldLoginID		= @psOldLoginID,
					  @pnOldAccountKey	= @pnOldAccountKey,
					  @pnOldNameKey		= @pnOldNameKey,
					  @pbIsExternal 	= @pbIsExternal,
					  @pbOldIsExternal	= @pbOldIsExternal,
					  @pnOldPortalKey	= @pnOldPortalKey,
					  @pbIsLocked		= @pbIsLocked,
					  @pbOldIsLocked	= @pbOldIsLocked,
					  @pnProfileKey         = @pnProfileKey,
					  @pnOldProfileKey      = @pnOldProfileKey,
					  @pbByPassEthicalWall	= @pbByPassEthicalWall,
					  @pbOldByPassEthicalWall = @pbOldByPassEthicalWall,
                                          @pdWriteDownLimit     = @pdWriteDownLimit,
                                          @pdOldWriteDownLimit  = @pdOldWriteDownLimit

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateUserIdentity to public
GO
