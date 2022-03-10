-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListUserData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListUserData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListUserData.'
	Drop procedure [dbo].[ipw_ListUserData]
End
Print '**** Creating Stored Procedure dbo.ipw_ListUserData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListUserData
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnIdentityKey		int,
	@pbIsSummary		bit		= 0	
)
as
-- PROCEDURE:	ipw_ListUserData
-- VERSION:	21
-- DESCRIPTION:	Populate the UserData dataset.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 Dec 2003	JEK	RFC408	1	Procedure created
-- 01 Mar 2004	TM	RFC622	2	Obtain the main email address attached to name from Name.MainEmail.
--					Add new IsIncomplete column. 
-- 02 Mar 2004	TM	RFC622	3	Add new IsExternal column. 
-- 17 Jun 2004	TM	RFC1499	4	Add PortalKey and PortalName columns to the UserIdentity result set.
--					Implement new SelectedRole result set.
-- 23 Mar 2006	IB	RFC	5	Populate dataset with default values if @pnIdentityKey is not supplied. 
--					Note: the user is defaulted but no roles.
-- 22 Sep 2006	LP	RFC4340	6	Add a new RowKey column to Selected Roles result set.
-- 14 Nov 2006	LP	RFC4340	7	Order Selected Role result set by IsProtected and RoleName
-- 23 Jan 2007	LP	RFC4981	8	Add a new IsLocked column.
-- 01 Nov 2007	SW	RFC5892	9	Implement security.
-- 11 Apr 2007	SF	RFC6437	10	Fix syntax error
-- 07 Aug 2008  LP  RFC6891 11  Suppress UserIdentity result set if logged-in user does not have access to Users MODULE
--                              and is attempting to view details of another user
-- 09 Oct 2008	LP	RFC6891	11	Suppress UserIdentity result set from External Users for non-accessible names
-- 09 Sep 2009  LP      RFC8047 12      Add a new ProfileKey column.
-- 10 Nov 2009	LP	RFC6712	13	Add new Selected Access Profile result set.
-- 04 Mar 2010  PS    RFC100135	14	Add new column WindowModuleUserId on the result set.
-- 15 Apr 2010  JCLG    RFC9164	15	Remove duplicate call to fn_FilterUserViewNames
-- 24 Jan 2011	SF	R11826	16	Unnecessary validation at times of authentication, introduce @pbIsSummary
-- 02 Nov 2015	vql	R53910	17	Adjust formatted names logic (DR-15543).
-- 03 May 2015	DV	R60353	18	Return new column BYPASSETHICALWALL (DR-19934)
-- 23 Aug 2016	MF	63098	19	Cater for very large RoleKey values by CASTing as nvarchar(11).
-- 24 Mar 2017	SF 	70262	20 	Return whether the user has been linked to SSO or not
-- 23 Mar 2018  MS      R73454  21      Add UserIdentity.WriteDownLimit column

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(max)
declare @bIsExternalUser bit
declare @dtToday        datetime

Declare @sLocalCurrencyCode	nvarchar(3)
Declare @nLocalDecimalPlaces 	tinyint

-- Initialise variables
Set @nErrorCode = 0
Set @dtToday = getdate()

If @nErrorCode=0
Begin
	Set @sSQLString="
	Select	@bIsExternalUser=UI.ISEXTERNALUSER
	from	USERIDENTITY UI
	where	UI.IDENTITYID=@pnUserIdentityId"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser		bit			OUTPUT,
				  @pnUserIdentityId		int',
				  @bIsExternalUser		=@bIsExternalUser	OUTPUT,
				  @pnUserIdentityId		=@pnUserIdentityId

	If @bIsExternalUser is null
	Begin
		Set @bIsExternalUser=1
	End
End

-- Retrieve Local Currency information
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= 0
End

-- UserIdentity result set
If @nErrorCode = 0
Begin	
	If @pnIdentityKey is not null
	Begin 
		Set @sSQLString = " 
		Select 	U.IDENTITYID	as IdentityKey,
			U.LOGINID	as LoginID,
			A.ACCOUNTID	as AccessAccountKey,
			A.ACCOUNTNAME	as AccessAccountName,
			N.NAMENO	as NameKey,
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, default)
					as DisplayName,
			-- If Name.NameStyle is not null then pass the @pnNameStyle = Name.NameStyle to the
			-- fn_FormatNameUsingNameNo, else use Country.NameStyle. If still null, use 7101 NameStyle (Name Last)   
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, NN.NAMESTYLE, 7101))
					as FormalName,
			N.NAMECODE	as NameCode,
			dbo.fn_FormatTelecom(E.TELECOMTYPE, E.ISD, E.AREACODE, E.TELECOMNUMBER, E.EXTENSION)					
					as EmailAddress,
			U.ISEXTERNALUSER 
					as IsExternal,
			CASE WHEN U.ISVALIDWORKBENCH=1 THEN cast(0 as bit) ELSE cast(1 as bit) END
					as IsIncomplete,
			USERS.USERID 
					as WindowModuleUserId,
			P.PORTALID 	as PortalKey,
			P.NAME		as PortalName,
			U.ISLOCKED	as IsLocked,
			U.PROFILEID     as ProfileKey,
			PR.PROFILENAME  as ProfileName,
			U.BYPASSETHICALWALL as ByPassEthicalWall,
			CASE WHEN U.CPAGLOBALUSERID is not null THEN cast(1 as bit) ELSE cast(0 as bit) END
					 as IsLinkedToIPPlatform,
                        U.WRITEDOWNLIMIT        as WriteDownLimit,
                        @sLocalCurrencyCode     as LocalCurrencyCode,
                        @nLocalDecimalPlaces    as LocalDecimalPlaces
		from 	USERIDENTITY U
		join 	NAME N			on (N.NAMENO = U.NAMENO) "+
		Case
			when @bIsExternalUser = 1 and @pbIsSummary = 0
			then
				"join dbo.fn_FilterUserViewNames(@pnUserIdentityId) FIL on (FIL.NAMENO = N.NAMENO)"
			Else
				""
		End
		+" left join USERS on (USERS.IDENTITYID = U.IDENTITYID)  
		left join ACCESSACCOUNT A	on (A.ACCOUNTID = U.ACCOUNTID)
		left join COUNTRY NN	        on (NN.COUNTRYCODE  = N.NATIONALITY)
		left join TELECOMMUNICATION E 	on (E.TELECODE = N.MAINEMAIL)
		left join PORTAL P		on (P.PORTALID = U.DEFAULTPORTALID)
		left join PROFILES PR           on (PR.PROFILEID = U.PROFILEID)
		where 	U.IDENTITYID = @pnIdentityKey"
		 
		If @pnIdentityKey <> @pnUserIdentityId
		Begin
	        set @sSQLString = @sSQLString + char(10) + " and exists (select 1 from dbo.fn_PermissionsGranted(@pnUserIdentityId, 'MODULE', null, null, @dtToday) PF where PF.ObjectIntegerKey = -9 and PF.CanSelect = 1)"
        End
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnIdentityKey	int,
						  @pnUserIdentityId     int,
						  @bIsExternalUser	bit,
						  @dtToday              datetime,
                                                  @sLocalCurrencyCode	nvarchar(3),
                                                  @nLocalDecimalPlaces  tinyint',
						  @pnIdentityKey	= @pnIdentityKey,
						  @pnUserIdentityId     = @pnUserIdentityId,
						  @bIsExternalUser	= @bIsExternalUser,
						  @dtToday              = @dtToday,
                                                  @sLocalCurrencyCode   = @sLocalCurrencyCode,
                                                  @nLocalDecimalPlaces  = @nLocalDecimalPlaces
	End
	Else
	Begin
		Set @sSQLString = " 
		Select 	A.ACCOUNTID	as AccessAccountKey,
			A.ACCOUNTNAME	as AccessAccountName,
			U.ISEXTERNALUSER 
					as IsExternal,
			0		as IsIncomplete,
			0		as IsLocked
		from 	USERIDENTITY U "+
		Case
			when @bIsExternalUser = 1
			then
				"join dbo.fn_FilterUserViewNames(@pnIdentityKey) FIL on (FIL.NAMENO = U.NAMENO)"
			Else
				""
		End
		+" left join ACCESSACCOUNT A	on (A.ACCOUNTID = U.ACCOUNTID)
		where 	U.IDENTITYID = @pnIdentityKey"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnIdentityKey	int',
						  @pnIdentityKey	= @pnUserIdentityId
	End

	Set @pnRowCount = @@ROWCOUNT
End

-- SelectedRole result set, return only when @pnIdentityKey is not nulls
If @nErrorCode = 0
and @pnIdentityKey is not null
and @pbIsSummary = 0
Begin
	Set @sSQLString = " 
	Select 	IR.IDENTITYID	as IdentityKey,
		IR.ROLEID	as RoleKey,
		R.ROLENAME	as RoleName,
		R.DESCRIPTION	as RoleDescription,
		R.ISPROTECTED	as IsProtected,
		CAST(IR.IDENTITYID as nvarchar(12)) +'^'+ CAST(IR.ROLEID as nvarchar(11)) as RowKey
	from 	IDENTITYROLES IR "+
	Case
		when @bIsExternalUser = 1
		then
			"join USERIDENTITY U on (U.IDENTITYID = IR.IDENTITYID)
			join dbo.fn_FilterUserViewNames(@pnUserIdentityId) FIL on (FIL.NAMENO = U.NAMENO)"
		Else
			""
	End
	+" 
	join ROLE R		on (R.ROLEID = IR.ROLEID)
	where 	IR.IDENTITYID = @pnIdentityKey
	order by IsProtected desc, RoleName"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnIdentityKey	int,
					  @pnUserIdentityId	int',
					  @pnIdentityKey	= @pnIdentityKey,
					  @pnUserIdentityId	= @pnUserIdentityId

	Set @pnRowCount = @@ROWCOUNT
End

-- SelectedAccessProfile result set, return only when @pnIdentityKey is not nulls
If @nErrorCode = 0
and @pnIdentityKey is not null
and @pbIsSummary = 0
Begin

	Set @sSQLString = " 
	Select 	IR.IDENTITYID	as IdentityKey,
		dbo.fn_StripNonAlphaNumerics(IR.ACCESSNAME)	as AccessProfileKey,
		R.ACCESSNAME	as AccessProfileName,
		R.ACCESSDESC	as AccessProfileDescription,
		CAST(IR.IDENTITYID as nvarchar(12))+'^'+dbo.fn_StripNonAlphaNumerics(IR.ACCESSNAME) as RowKey
	from 	IDENTITYROWACCESS IR "+
	Case
		when @bIsExternalUser = 1
		then
			"join USERIDENTITY U on (U.IDENTITYID = IR.IDENTITYID)
			join dbo.fn_FilterUserViewNames(@pnUserIdentityId) FIL on (FIL.NAMENO = U.NAMENO)"
		Else 
			""		
	End
	+" 
	join ROWACCESS R on (R.ACCESSNAME = IR.ACCESSNAME)
	where 	IR.IDENTITYID = @pnIdentityKey
	order by AccessProfileName"

	Print @sSQLString
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnIdentityKey	int,
					  @pnUserIdentityId	int',
					  @pnIdentityKey	= @pnIdentityKey,
					  @pnUserIdentityId	= @pnUserIdentityId

	Set @pnRowCount = @@ROWCOUNT
End


Return @nErrorCode
GO

Grant execute on dbo.ipw_ListUserData to public
GO
