-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_DeleteAccessAccount
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_DeleteAccessAccount]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_DeleteAccessAccount.'
	Drop procedure [dbo].[ip_DeleteAccessAccount]
End
Print '**** Creating Stored Procedure dbo.ip_DeleteAccessAccount...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ip_DeleteAccessAccount
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnAccountKey		int,
	@psOldAccountName	nvarchar(50),
	@pbOldIsInternal 	bit
)
as
-- PROCEDURE:	ip_DeleteAccessAccount
-- VERSION:	6
-- DESCRIPTION:	Delete the AccessAcount.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30 Nov 2003	JEK	RFC407	1	Procedure created
-- 04 Dec 2003	JEK	RFC407	2	Add validation.
-- 22 Dec 2003	JEK	RFC407	3	IdentityRoles does not have a casecade delete,
--					which is preventing deletion of the AccessAccount.
-- 13 Feb 2004	TM	RFC708	4	IdentityRoles now have a cascade delete, so remove 
--					the 'DELETE IDENTITYROLES...' code.
-- 27 Feb 2004	TM	RFC622	5	Use IdentityRole with RoleID = - 1 to check if the user has system 
--					administration privileges not the IsAdministrator flag. Add the IsInternal 
--					information. Check the old Account Name.
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
	delete	ACCESSACCOUNT
	where	ACCOUNTID = @pnAccountKey	
	and	ACCOUNTNAME = @psOldAccountName
	and 	ISINTERNAL = @pbOldIsInternal"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnAccountKey		int,
					  @psOldAccountName	nvarchar(50),
					  @pbOldIsInternal	bit',
					  @pnAccountKey		= @pnAccountKey,
					  @psOldAccountName	= @psOldAccountName,
					  @pbOldIsInternal	= @pbOldIsInternal
End

Return @nErrorCode
GO

Grant execute on dbo.ip_DeleteAccessAccount to public
GO
