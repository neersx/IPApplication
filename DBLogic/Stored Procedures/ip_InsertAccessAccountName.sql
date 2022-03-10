-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_InsertAccessAccountName
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_InsertAccessAccountName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_InsertAccessAccountName.'
	Drop procedure [dbo].[ip_InsertAccessAccountName]
End
Print '**** Creating Stored Procedure dbo.ip_InsertAccessAccountName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ip_InsertAccessAccountName
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnAccountKey		int,
	@pnNameKey		int
)
as
-- PROCEDURE:	ip_InsertAccessAccountName
-- VERSION:	4
-- DESCRIPTION:	Add a new Access Account Name.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30 Nov 2003	JEK	RFC407	1	Procedure created
-- 03 Dec 2003	JEK	RFC407	2	Add validation.
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
	insert 	into ACCESSACCOUNTNAMES
		(ACCOUNTID, NAMENO)
	values	(@pnAccountKey, @pnNameKey)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnAccountKey	int,
					  @pnNameKey 	int',
					  @pnAccountKey	= @pnAccountKey,
					  @pnNameKey = @pnNameKey
End

Return @nErrorCode
GO

Grant execute on dbo.ip_InsertAccessAccountName to public
GO
