-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_DeleteAccessAccountUser
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_DeleteAccessAccountUser]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_DeleteAccessAccountUser.'
	Drop procedure [dbo].[ip_DeleteAccessAccountUser]
End
Print '**** Creating Stored Procedure dbo.ip_DeleteAccessAccountUser...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ip_DeleteAccessAccountUser
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnAccountKey		int,
	@pnOldIdentityKey	int
)
as
-- PROCEDURE:	ip_DeleteAccessAccountUser
-- VERSION:	6
-- DESCRIPTION:	Delete the AccessAcount user if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30 Nov 2003	JEK	RFC407	1	Procedure created
-- 03 Dec 2003	JEK	RFC407	2	Add validation.
-- 22 Dec 2003	JEK	RFC407	3	There is no cascade delete to IdentityRoles.
-- 13 Feb 2004	TM	RFC708	4	Remove 'delete	IDENTITYROLES' as IdentityRoles now has cascade delete.  
-- 27 Feb 2004	TM	RFC622	5	Use IdentityRole with RoleID = - 1 to check if the user has system 
--					administration privileges not the IsAdministrator flag.  
-- 23 Apr 2004	TM	RFC1339	6	Remove the logic that is using IDENTITYROLES.ROLEID = -1  for a particular 
--					user identity to determine if the user is System Administrator and raising 
--					an error if the user is not System Administrator.


SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	delete	USERIDENTITY
	where	ACCOUNTID = @pnAccountKey
	and	IDENTITYID = @pnOldIdentityKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnAccountKey		int,
					  @pnOldIdentityKey	int',
					  @pnAccountKey		= @pnAccountKey,
					  @pnOldIdentityKey	= @pnOldIdentityKey
End

Return @nErrorCode
GO

Grant execute on dbo.ip_DeleteAccessAccountUser to public
GO
