-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_DeleteIdentityRowAccess
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_DeleteIdentityRowAccess]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_DeleteIdentityRowAccess.'
	Drop procedure [dbo].[ip_DeleteIdentityRowAccess]
	Print '**** Creating Stored Procedure dbo.ip_DeleteIdentityRowAccess...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ip_DeleteIdentityRowAccess
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psIdentityKey		nvarchar(11)	= null,
	@psProfileKey		nvarchar(30)	= null,
	@psProfileName		nvarchar(30)	= null

)
-- PROCEDURE:	ip_DeleteIdentityRowAccess
-- VERSION :	8
-- DESCRIPTION:	To remove a user from a Row Access Profile.
--		Only Administrator User can perform this operation.

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 17-OCT-2002  SF	1	Procedure created
-- 30-OCT-2002	SF	2	Change the way error is raised.
-- 10-MAR-2003	JEK	5	RFC82 Localise stored procedure errors.
-- 12-Jan-2010	LP	6	RFC8793 Use ProfileName instead of ProfileKey.
-- 10-Feb-2012	LP	7	RFC11542 Remove ISADMINISTATOR restriction.
--				This is now superceded by task security in Web version.
-- 15 Apr 2013	DV	8	R13270 Increase the length of nvarchar to 11 when casting or declaring integer
as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
declare @sAlertXML nvarchar(400)
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	If @psProfileKey is null 
		Set @nErrorCode = -1

	If @nErrorCode = 0
	Begin
		Delete 
		from 	IDENTITYROWACCESS 
		where	ACCESSNAME = @psProfileName
		and	IDENTITYID = Cast(@psIdentityKey as int)

		Set @nErrorCode = @@ERROR	
	End

End
Return @nErrorCode
GO

Grant execute on dbo.ip_DeleteIdentityRowAccess to public
GO
