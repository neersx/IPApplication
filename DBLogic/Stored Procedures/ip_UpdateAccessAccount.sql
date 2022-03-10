-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_UpdateAccessAccount
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_UpdateAccessAccount]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_UpdateAccessAccount.'
	Drop procedure [dbo].[ip_UpdateAccessAccount]
End
Print '**** Creating Stored Procedure dbo.ip_UpdateAccessAccount...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ip_UpdateAccessAccount
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnAccountKey		int,
	@psAccountName		nvarchar(50),
	@pbIsInternal 		bit,		
	@psOldAccountName	nvarchar(50),
	@pbOldIsInternal 	bit
)
as
-- PROCEDURE:	ip_UpdateAccessAccount
-- VERSION:	4
-- DESCRIPTION:	Update the AccessAccount if the underlying values are still as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30 Nov 2003	JEK	RFC407	1	Procedure created
-- 04 Dec 2004	JEK	RFC407	2	Add validation.
-- 27 Feb 2004	TM	RFC622	3	Use IdentityRole with RoleID = - 1 to check if the user has system 
--					administration privileges not the IsAdministrator flag. Add the 
--					IsInternal information  
-- 23 Apr 2004	TM	RFC1339	4	Remove the logic that is using IDENTITYROLES.ROLEID = -1  for a particular 
--					user identity to determine if the user is System Administrator and raising 
--					an error if the user is not System Administrator.


SET CONCAT_NULL_YIELDS_NULL OFF

-- Declare variables
declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	update	ACCESSACCOUNT
	set	ACCOUNTNAME = @psAccountName,
		ISINTERNAL = @pbIsInternal
	where	ACCOUNTID = @pnAccountKey
	and	ACCOUNTNAME = @psOldAccountName
	and 	ISINTERNAL = @pbOldIsInternal"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnAccountKey		int,
					  @psAccountName	nvarchar(50),
					  @psOldAccountName	nvarchar(50),
					  @pbIsInternal		bit,
					  @pbOldIsInternal	bit',
					  @pnAccountKey		= @pnAccountKey,
					  @psAccountName	= @psAccountName,
					  @psOldAccountName	= @psOldAccountName,
					  @pbIsInternal		= @pbIsInternal,
					  @pbOldIsInternal	= @pbOldIsInternal
End

Return @nErrorCode
GO

Grant execute on dbo.ip_UpdateAccessAccount to public
GO
