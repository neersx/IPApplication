-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_DeleteAccessAccountName
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_DeleteAccessAccountName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_DeleteAccessAccountName.'
	Drop procedure [dbo].[ip_DeleteAccessAccountName]
End
Print '**** Creating Stored Procedure dbo.ip_DeleteAccessAccountName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ip_DeleteAccessAccountName
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnAccountKey		int,
	@pnOldNameKey		int
)
as
-- PROCEDURE:	ip_DeleteAccessAccountName
-- VERSION:	4
-- DESCRIPTION:	Delete the AccessAcountName if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30 Nov 2003	JEK	RFC407	1	Procedure created
-- 03 Dec 2003	JEK	RFC407	2	Add Validation
-- 27 Feb 2004	TM	RFC622	3	Use IdentityRole with RoleID = - 1 to check if the user has system 
--					administration privileges not the IsAdministrator flag.  
-- 23 Apr 2004	TM	RFC1339	4	Remove the logic that is using IDENTITYROLES.ROLEID = -1  for a particular 
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
	delete	ACCESSACCOUNTNAMES
	where	ACCOUNTID = @pnAccountKey
	and	NAMENO = @pnOldNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnAccountKey		int,
					  @pnOldNameKey		int',
					  @pnAccountKey		= @pnAccountKey,
					  @pnOldNameKey		= @pnOldNameKey
End

Return @nErrorCode
GO

Grant execute on dbo.ip_DeleteAccessAccountName to public
GO
