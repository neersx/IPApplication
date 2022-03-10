SET QUOTED_IDENTIFIER OFF
GO

-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[in_AuthenticateUser]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.in_AuthenticateUser.'
	Drop procedure [dbo].[in_AuthenticateUser]
End
Print '**** Creating Stored Procedure dbo.in_AuthenticateUser...'
Print ''
GO

CREATE PROCEDURE dbo.in_AuthenticateUser
    @psLoginID		nvarchar(50),	-- Mandatory
    @pnPassword		binary(16),	-- Mandatory
    @pnUserIdentity 	int 		output,
    @pbIsLocked		bit		= 0 output,
    @psDisplayName	nvarchar(254)	= NULL output,
    @psEmail		nvarchar(50)	= NULL output
AS
-- PROCEDURE :	in_AuthenticateUser
-- VERSION :	11
-- DESCRIPTION:	Authenticates a user to check to see if they are who they say they are.
--				If Authenticated the identity of the user is returned

-- MODIFICATIONS :
-- Date		Who	Version	Change	Comment
-- ------------	-------	-------	------	----------------------------------------------- 
-- 04 Nov 2002	JB	3		Password is now binary (encrypted)
-- 11 Nov 2002	SF	4		Put a size to the binary parameter
-- 16 Mar 2004	TM	6		Increase size of @psLoginID from nvarchar(20) to nvarchar(50).
-- 25 Jan 2007	LP	7		Return new @pbIsLocked parameter
--					Update INVALIDLOGINS column depending on authentication status
-- 06 Feb 2007	LP	8		Return @psEmail and @psDisplayName when user is locked
-- 11 Apr 2008	LP	9	RFC6324	Return @pnUserIdentity when user is locked.
-- 11 Dec 2008	MF	10	17136	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 02 Nov 2015	vql	11	R53910	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @nInvalidLogins 	int
Declare @nMaxInvalidLogins 	int
Declare @sSQLString		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0
Set @pbIsLocked = 0 

If @nErrorCode = 0
Begin
	Select	@pnUserIdentity = IDENTITYID,
		@pbIsLocked = ISLOCKED
	from	USERIDENTITY
	where	upper(LOGINID) = upper(@psLoginID)
	and	[PASSWORD] = @pnPassword
	
	Set @nErrorCode = @@ERROR
End
-- Perform logic below if username and password are incorrect
If (@pnUserIdentity IS NULL or @pnUserIdentity = '')	
Begin
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Update USERIDENTITY
		Set INVALIDLOGINS = 
			CASE WHEN SC.COLINTEGER > 0 
				THEN UI.INVALIDLOGINS + 1 
				ELSE UI.INVALIDLOGINS 
			END,
		ISLOCKED = 
			CASE WHEN UI.INVALIDLOGINS + 1 >= SC.COLINTEGER 
				THEN 1 
				ELSE 0 
			END,
		@pbIsLocked = 
			CASE WHEN UI.INVALIDLOGINS + 1 >= SC.COLINTEGER 
				THEN 1 
				ELSE 0 
			END,
		@psDisplayName = dbo.fn_FormatNameUsingNameNo(N.NAMENO, default),
		@psEmail = dbo.fn_FormatTelecom(T.TELECOMTYPE, T.ISD, T.AREACODE, T.TELECOMNUMBER, T.EXTENSION),
		@pnUserIdentity = UI.IDENTITYID
		from USERIDENTITY UI
		join SITECONTROL SC on (SC.CONTROLID = 'Max Invalid Logins' AND ISNULL(SC.COLINTEGER,0) > 0)
		left join NAME N on (N.NAMENO = UI.NAMENO)
		left join TELECOMMUNICATION T on (T.TELECODE = N.MAINEMAIL)		
		Where upper(LOGINID) = upper(@psLoginID)"		 

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@psLoginID		nvarchar(50),
					  @pbIsLocked		bit	output,
					  @psDisplayName	nvarchar(254)	output,
					  @psEmail		nvarchar(50)	output,
					  @pnUserIdentity	int 	output',
					  @psLoginID	= @psLoginID,
					  @pbIsLocked	= @pbIsLocked	output,
					  @psDisplayName	= @psDisplayName	output,
					  @psEmail		= @psEmail		output,
					  @pnUserIdentity	= @pnUserIdentity	output
	End	
	If @nErrorCode = 0
	and @pbIsLocked = 0
	Begin
	    Set @pnUserIdentity = null
	End
End
Else 
Begin 
	If @nErrorCode = 0
	Begin
		-- Reset user account if not locked
		Set @sSQLString = "
		Update USERIDENTITY
		Set INVALIDLOGINS = 
			CASE WHEN UI.INVALIDLOGINS < ISNULL(SC.COLINTEGER,0) 
				THEN 0 
				ELSE UI.INVALIDLOGINS 
			END,
		@pbIsLocked = ISLOCKED
		From USERIDENTITY UI
		left join SITECONTROL SC on (SC.CONTROLID = 'Max Invalid Logins')
		Where IDENTITYID = @pnUserIdentity"		 

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnUserIdentity		nvarchar(50),
					  @pbIsLocked		bit	output',
					  @pnUserIdentity	= @pnUserIdentity,
					  @pbIsLocked		= @pbIsLocked	output
	End
End

Return @nErrorCode
GO

Grant execute on dbo.in_AuthenticateUser to public
GO
