SET QUOTED_IDENTIFIER OFF
GO

-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ListUserIdentityData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_ListUserIdentityData.'
	Drop procedure [dbo].[ip_ListUserIdentityData]
	Print '**** Creating Stored Procedure dbo.ip_ListUserIdentityData...'
	Print ''
End
GO

CREATE PROCEDURE dbo.ip_ListUserIdentityData
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnIdentityKey		int		= null
)
-- PROCEDURE:	ip_ListUserIdentityData
-- VERSION :	8
-- DESCRIPTION:	The UserIdentityData dataset is used for creation and update of system users.
--		This stored procedure populates the UserIdentityData dataset.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 16-OCT-2002  SF		1	Procedure created
-- 17-OCT-2002	SF		2	ProfileKey and ProfileName are both ACCESSNAME.
-- 18-OCT-2002	SF		3	Use numeric IdentityKey.
-- 11-NOV-2002	JB		4	Now not returning password.
-- 03-MAR-2004	TM	RFC1003	6	Add new IsIncomplete column.
-- 15 Apr 2013	DV	R13270	7	Increase the length of nvarchar to 11 when casting or declaring integer
-- 02 Nov 2015	vql	R53910	8	Adjust formatted names logic (DR-15543).

as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Set @nErrorCode = 0

-- populate UserIdentityData.UserIdentity table
If @nErrorCode = 0
Begin
	Select 	cast(@pnIdentityKey as varchar(11))	as 'IdentityKey',
		U.LOGINID				as 'LoginID',
		cast(U.NAMENO as varchar(11))		as 'IdentityNameKey',
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)	
							as 'DisplayName',
		N.NAMECODE				as 'NameCode',
		ISEXTERNALUSER				as 'IsExternalUser',
		CASE WHEN U.ISVALIDINPROSTART=1 THEN cast(0 as bit) ELSE cast(1 as bit) END
							as 'IsIncomplete'
	from 	USERIDENTITY U
	left join NAME N on (N.NAMENO = U.NAMENO)
	where	IDENTITYID = @pnIdentityKey

	Set @nErrorCode = @@ERROR
End

-- populate UserIdentityData.IdentityProfile table
If @nErrorCode = 0
Begin

	Select 	cast(@pnIdentityKey as varchar(11)) + '^' + 
		ACCESSNAME 				as 'IdentityProfileRowKey',
		cast(@pnIdentityKey as varchar(11))	as 'IdentityKey',
		ACCESSNAME				as 'ProfileKey',
		ACCESSNAME				as 'ProfileName'
	from 	IDENTITYROWACCESS
	where	IDENTITYID = @pnIdentityKey

	Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.ip_ListUserIdentityData to public
GO

