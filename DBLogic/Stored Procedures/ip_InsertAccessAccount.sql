-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_InsertAccessAccount
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_InsertAccessAccount]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_InsertAccessAccount.'
	Drop procedure [dbo].[ip_InsertAccessAccount]
End
Print '**** Creating Stored Procedure dbo.ip_InsertAccessAccount...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ip_InsertAccessAccount
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnAccountKey		int		= null,	-- Included to provide a standard interface
	@psAccountName		nvarchar(50),	-- Mandatory
	@pbIsInternal 		bit		-- Mandatory
)
as
-- PROCEDURE:	ip_InsertAccessAccount
-- VERSION:	6
-- DESCRIPTION:	Add a new Access Account, returning the generated key.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30 Nov 2003	JEK	RFC407	1	Procedure created
-- 03 Dec 2003	JEK	RFC407	2	Add validation.
-- 26 Feb 2004	TM	RFC622	3	Use IdentityRole with RoleID = - 1 to check if the user has system 
--					administration privileges not the IsAdministrator flag. Include a new 
--					@pbIsInternal parameter and write this to the database.  
-- 23 Apr 2004	TM	RFC1339	4	Remove the logic that is using IDENTITYROLES.ROLEID = -1  for a particular 
--					user identity to determine if the user is System Administrator and raising 
--					an error if the user is not System Administrator.
-- 15 Sep 2004	TM	RFC1822	5	Use IDENT_CURRENT('table_name') instead of the @@IDENTITY to publish the key.
-- 17 Sep 2004	TM	RFC1822	6	Implement SCOPE_IDENTITY() IDENT_CURRENT and move this logic inside the
--					SQL string executed by sp_executesql. 

-- Row counts required by the data adapter
SET NOCOUNT OFF

SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	insert 	into ACCESSACCOUNT
		(ACCOUNTNAME, 
		 ISINTERNAL)
	values	(@psAccountName, 
		 @pbIsInternal)

	Set @pnAccountKey = SCOPE_IDENTITY()"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnAccountKey		int		OUTPUT,
					  @psAccountName	nvarchar(50),
				          @pbIsInternal		bit',
					  @psAccountName	= @psAccountName,
					  @pbIsInternal		= @pbIsInternal,
					  @pnAccountKey		= @pnAccountKey	OUTPUT

	-- Publish the account key so that the dataset is updated
	Select @pnAccountKey  as AccountKey 
End

Return @nErrorCode
GO

Grant execute on dbo.ip_InsertAccessAccount to public
GO
