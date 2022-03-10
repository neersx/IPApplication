SET QUOTED_IDENTIFIER OFF
GO

-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[in_GetAuthenticatedUser]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.in_GetAuthenticatedUser.'
	Drop procedure [dbo].[in_GetAuthenticatedUser]
End
Print '**** Creating Stored Procedure dbo.in_GetAuthenticatedUser...'
Print ''
GO

CREATE PROCEDURE dbo.in_GetAuthenticatedUser
    @psUserName		nvarchar(50),		-- Mandatory
    @pnPassword		binary(16) = null,
    @pnUserIdentity 	int output
AS    
-- PROCEDURE :	in_GetAuthenticatedUser
-- VERSION :	5
-- DESCRIPTION:	Authenticates a user to check to see if they are who they say they are.
--		If Authenticated the identity of the user is returned

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 04 Nov 2002	JB	3	Lookup of LoginId now case insensitive
-- 15 Apr 2005	TM	4	RFC1609 Compares user names in two passes. First pass to compare the user name as is, 
--				if not found then proceed to the second pass which is to compare the user name by 
--				stripping the domain prefix delimited by a backslash.  Return the matching identity 
--				key if found.	
-- 28 Jul 2011	SF	5	If password is provided then the password is validated
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @sLoginID		nvarchar(50)
Declare @bIsLocked		bit
Declare @sDisplayName		nvarchar(254)
Declare @sEmail			nvarchar(50)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Select	@pnUserIdentity = IDENTITYID,
		@sLoginID = LOGINID
	from	USERIDENTITY
	where	(upper(LOGINID) = upper(@psUserName)
	   -- stripping the domain prefix delimited by a backslash:
	   or    upper(LOGINID) = UPPER(substring(@psUserName, CHARINDEX('\', @psUserName)+1, 50)))
	and	ISLOCKED = 0
	   
	Set @nErrorCode = @@ERROR
End	   

If @nErrorCode = 0
and @pnUserIdentity is not null
and @pnPassword is null
Begin
	Update USERIDENTITY
	Set INVALIDLOGINS = 
		CASE WHEN UI.INVALIDLOGINS < ISNULL(SC.COLINTEGER,0) 
			THEN 0 
			ELSE UI.INVALIDLOGINS 
		END
	From USERIDENTITY UI
	left join SITECONTROL SC on (SC.CONTROLID = 'Max Invalid Logins')
	Where IDENTITYID = @pnUserIdentity
End

If @nErrorCode = 0
and @sLoginID is not null
and @pnPassword is not null
Begin
	-- reset @pnUserIdentity so it is revalidated with password
	Set @pnUserIdentity = null
	
	-- if password was provided, then validate the identity with password
	-- if password is incorrect the login may be locked.
	exec dbo.in_AuthenticateUser 
		@sLoginID, 
		@pnPassword, 
		@pnUserIdentity = @pnUserIdentity output, 
		@pbIsLocked = @bIsLocked output,
		@psDisplayName = @sDisplayName output,
		@psEmail = @sEmail output
	
	Set @nErrorCode = @@ERROR
End

RETURN @nErrorCode
GO

Grant execute on dbo.in_GetAuthenticatedUser to public
GO

