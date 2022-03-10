-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_UpdateAccessAccountName
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_UpdateAccessAccountName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_UpdateAccessAccountName.'
	Drop procedure [dbo].[ip_UpdateAccessAccountName]
End
Print '**** Creating Stored Procedure dbo.ip_UpdateAccessAccountName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ip_UpdateAccessAccountName
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnAccountKey		int,
	@pnNameKey		int,
	@psOldNameKey		int
)
as
-- PROCEDURE:	ip_UpdateAccessAccountName
-- VERSION:	4
-- DESCRIPTION:	Update the AccessAccountName if the underlying values are still as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30 Nov 2003	JEK	RFC407	1	Procedure created
-- 04 Dec 2003	JEK	RFC407	2	Add validation
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
	update	ACCESSACCOUNTNAMES
	set	NAMENO = @pnNameKey
	where	ACCOUNTID = @pnAccountKey
	and	NAMENO = @psOldNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnAccountKey		int,
					  @pnNameKey		int,
					  @psOldNameKey	int',
					  @pnAccountKey		= @pnAccountKey,
					  @pnNameKey		= @pnNameKey,
					  @psOldNameKey		= @psOldNameKey
End

Return @nErrorCode
GO

Grant execute on dbo.ip_UpdateAccessAccountName to public
GO
