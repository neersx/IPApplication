-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertUserIdentity
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertUserIdentity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertUserIdentity.'
	Drop procedure [dbo].[ipw_InsertUserIdentity]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertUserIdentity...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_InsertUserIdentity
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnIdentityKey		int		= null,	-- Included to provide a standard interface
	@psLoginID		nvarchar(50)	= null,
	@pnAccountKey		int		= null,
	@pnPassword		binary(16)	= null,
	@pnNameKey		int		= null,
	@psEmailAddress		nvarchar(100)	= null,
	@pnPortalKey		int		= null,
	@pbIsExternal 		bit		= null,
	@pnProfileKey           int             = null,
	@pbByPassEthicalWall	bit		= 0,
        @pdWriteDownLimit       decimal(11,2)   = null
)
as
-- PROCEDURE:	ipw_InsertUserIdentity
-- VERSION:	14
-- DESCRIPTION:	Add a new User Identity, returning the generated key.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 06 Dec 2003	JEK	RFC408	1	Procedure created
-- 22 Dec 2003	JEK	RFC408	2	Password parameter to sp_executesql is binary(15) instead of 16.
-- 27 Feb 2004	TM	RFC622	3	Use IdentityRole with RoleID = - 1 to check if the user has system 
--					administration privileges not the IsAdministrator flag. Use Name.MainEmail
--					to extract the Main Email of tne Name. Add a new @pbIsExternal parameter, 
--					and modify the logic to write this to the database. Check whether CPA Inprostart
--					row level security is in use. If so, set IsValidInprostart = 0, otherwise 1.
--					Implement validation to ensure that password is present. Mark user complete.
-- 06 Apr 2004	TM	RFC1294	4	Ensure that IsValidInprostart is set to 1.
-- 23 Apr 2004	TM	RFC1339	5	Remove the logic that is using IDENTITYROLES.ROLEID = -1  for a particular 
--					user identity to determine if the user is System Administrator and raising 
--					an error if the user is not System Administrator.
-- 18 Jun 2004	TM	RFC1499	6	Remove @pnRoleKey parameter and add @pnPortalKey. Remove call to 
--					ipw_MaintainIdentityRole stored procedure.
-- 15 Sep 2004	TM	RFC1822	7	Use IDENT_CURRENT('table_name') instead of the @@IDENTITY to publish the key.
-- 20 Sep 2004 	TM	RFC1822	8	Implement SCOPE_IDENTITY() IDENT_CURRENT and move this logic inside the
--					SQL string executed by sp_executesql.
-- 15 Apr 2005	TM	RFC1609	9	Remove mandatory password checking from the stored procedure, this now needs 
--					to be implemented in the business layer.
-- 23 Jan 2007	LP	RFC4981	10	Set ISLOCKED and INVALIDLOGINS columns to 0.
-- 22 Nov 2007	SW	RFC5967	11	Change TELECOMMUNICATION.TELECOMNUMBER from nvarchar(50) to nvarchar(100)
-- 09 Sep 2009  LP      RFC8047 12      Add PROFILEID column.
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

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	insert 	into USERIDENTITY
		(LOGINID, 
		PASSWORD, 
		NAMENO, 
		ISEXTERNALUSER, 
		ISADMINISTRATOR, 
		ACCOUNTID, 
		HASTEMPPASSWORD,
		ISVALIDINPROSTART,
		ISVALIDWORKBENCH,
		DEFAULTPORTALID,
		ISLOCKED,
		INVALIDLOGINS,
		PROFILEID,
		BYPASSETHICALWALL,
                WRITEDOWNLIMIT)
	values	(@psLoginID, 
		@pnPassword,
		@pnNameKey, 
		@pbIsExternal, 
		0,
		@pnAccountKey,
		0,
		1,
		1,
		@pnPortalKey,
		0,
		0,
		@pnProfileKey,
		@pbByPassEthicalWall,
                @pdWriteDownLimit)

		Set @pnIdentityKey = SCOPE_IDENTITY()"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnIdentityKey	int		OUTPUT,
					  @psLoginID		nvarchar(50),
					  @pnPassword		binary(16),
					  @pnAccountKey		int,
					  @pnNameKey		int,
					  @pbIsExternal		bit,
					  @pnPortalKey		int,
					  @pnProfileKey         int,
					  @pbByPassEthicalWall	bit,
                                          @pdWriteDownLimit     decimal(11,2)',
					  @pnIdentityKey	= @pnIdentityKey OUTPUT,
					  @psLoginID		= @psLoginID,
					  @pnPassword		= @pnPassword,
					  @pnAccountKey		= @pnAccountKey,
					  @pnNameKey		= @pnNameKey,
					  @pbIsExternal		= @pbIsExternal,
					  @pnPortalKey		= @pnPortalKey,
					  @pnProfileKey         = @pnProfileKey,
					  @pbByPassEthicalWall	= @pbByPassEthicalWall,
                                          @pdWriteDownLimit     = @pdWriteDownLimit

	-- Publish the key so that the dataset is updated
	Select @pnIdentityKey as IdentityKey
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertUserIdentity to public
GO