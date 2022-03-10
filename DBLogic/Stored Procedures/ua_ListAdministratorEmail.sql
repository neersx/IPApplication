-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_ListAdministratorEmail
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_ListAdministratorEmail]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_ListAdministratorEmail.'
	Drop procedure [dbo].[ua_ListAdministratorEmail]
End
Print '**** Creating Stored Procedure dbo.ua_ListAdministratorEmail...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ua_ListAdministratorEmail
(
	@pnUserIdentityId	int	= NULL,		
	@pbIncludeExternal	int	= 0,	-- When set to 1 indicates that external users with administrator permissions should be returned.
						-- When set to 0 only internal users are returned.  
	@psUserId		nvarchar(100) = NULL
)
as
-- PROCEDURE:	ua_ListAdministratorEmail
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- SCOPE:	WorkBenches
-- DESCRIPTION:	Returns the email addresses of user administrators.
--		Used for sending email notification of user account lockouts and license expiry.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 20 Jul 2006	SW	RFC3828	1	Procedure created
-- 21 Jul 2006	SW	RFC3828	2	Changed tmp table to table variable and logic
-- 10 Aug 2006	JEK	RFC3828	3	Implement new function fn_PermissionsGrantedAll().
-- 25 Jan 2007	LP	RFC4981	4	Make @pnUserIdentityId optional.
-- 03 Apr 2008	LP	RFC6324	5	If @psUserId is specified and Internal return Internal Administrators.
--					If @psUserId is specified and External return Internal Administrators
--					and External Administrators belonging to the same Access Account.
--					If @psUserId is not specified, return all Administrators.	
--					Filter Administrators with NULL email addresses.
-- 28 Feb 2013	DV	RFC7398	6	Return the IdentityID along with the email.						

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @dtToday	datetime
Declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0
Set @dtToday = getdate()
Set @pbIncludeExternal = isnull(@pbIncludeExternal,0)

-- Retrieve IDENTITYID from UserIdentity is LOGINID specified.
If @nErrorCode=0
and @psUserId is not null
and @pnUserIdentityId is null
Begin		
	Set @sSQLString='
	Select @pnUserIdentityId=IDENTITYID
	from USERIDENTITY
	where LOGINID=@psUserId'

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@pnUserIdentityId	int	OUTPUT,
				  @psUserId		nvarchar(100)',
				  @pnUserIdentityId	=@pnUserIdentityId	OUTPUT,
				  @psUserId		=@psUserId
End

If @nErrorCode = 0
Begin
	If @pnUserIdentityId is null
	Begin
	    -- Return emails that have HASPERMISSION flag set.
	    Set @sSQLString = " 
	    Select T.TELECOMNUMBER as Email,
	    UI.IDENTITYID as UserIdentity
	    from dbo.fn_PermissionsGrantedAll('TASK',15,null,@dtToday) P
	    join USERIDENTITY UI	on (UI.IDENTITYID=P.IdentityKey)
	    join [NAME] N 		on (N.NAMENO = UI.NAMENO)
	    join TELECOMMUNICATION T on (T.TELECODE = N.MAINEMAIL)
	    where 	P.CanInsert | P.CanUpdate | P.CanDelete = 1
	    and	(UI.ISEXTERNALUSER=0 or
		     UI.ISEXTERNALUSER=@pbIncludeExternal)
	    and T.TELECOMNUMBER IS NOT NULL"

	    exec @nErrorCode=sp_executesql @sSQLString,
		    N'@pbIncludeExternal	bit,
		      @dtToday			datetime',
		      @pbIncludeExternal	= @pbIncludeExternal,
		      @dtToday			= @dtToday
	End
	Else
	Begin
	     Set @sSQLString = " 
	    Select T.TELECOMNUMBER as Email,
	    N.FIRSTNAME +' '+ N.NAME as Name,
	    UI.IDENTITYID as UserIdentity
	    from dbo.fn_PermissionsGrantedAll('TASK',15,null,@dtToday) P
	    join USERIDENTITY UI	on (UI.IDENTITYID=P.IdentityKey)
	    join [NAME] N 		on (N.NAMENO = UI.NAMENO)
	    join TELECOMMUNICATION T on (T.TELECODE = N.MAINEMAIL)
	    join USERIDENTITY UI2	on (UI2.IDENTITYID = @pnUserIdentityId)
	    where 	P.CanInsert | P.CanUpdate | P.CanDelete = 1
	    and ((UI.ISEXTERNALUSER=0) OR
		(UI.ACCOUNTID = UI2.ACCOUNTID 
		    AND UI.ISEXTERNALUSER=1))
	    and T.TELECOMNUMBER IS NOT NULL"

	    exec @nErrorCode=sp_executesql @sSQLString,
		    N'@pnUserIdentityId		int,
		      @pbIncludeExternal	bit,
		      @dtToday			datetime',
		      @pnUserIdentityId		= @pnUserIdentityId,
		      @pbIncludeExternal	= @pbIncludeExternal,
		      @dtToday			= @dtToday
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ua_ListAdministratorEmail to public
GO


