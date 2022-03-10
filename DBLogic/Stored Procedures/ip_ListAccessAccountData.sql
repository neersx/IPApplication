-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ListAccessAccountData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ListAccessAccountData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_ListAccessAccountData.'
	Drop procedure [dbo].[ip_ListAccessAccountData]
End
Print '**** Creating Stored Procedure dbo.ip_ListAccessAccountData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ip_ListAccessAccountData
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnAccessAccountKey	int
)
as
-- PROCEDURE:	ip_ListAccessAccountData
-- VERSION:	5
-- DESCRIPTION:	Lists the details for a particular AccessAccount.
--		Populates the AccessAccountData dataset.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30 Nov 2003	JEK	RFC407	1	Procedure created
-- 27 Feb 2004	TM	RFC622	2	Add IsIncomplete and IsInternal columns. Use 'left join' for AccountUsers 
--					so that incomplete data is shown. 
-- 18 Jun 2004	TM	RFC1499	3	Remove RoleName column and add PortalName column in the AccountUsers result set.
-- 01 Nov 2006	LP	RFC4339	4	Add new RowKey column to all result sets
-- 02 Nov 2015	vql	R53910	5	Adjust formatted names logic (DR-15543).


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

-- AccessAccount result set
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	select	ACCOUNTNAME	as AccountName,
		ACCOUNTID	as AccountKey,
		ISINTERNAL	as IsInternal,
		CAST(ACCOUNTID as nvarchar)	as RowKey
	from	ACCESSACCOUNT
	where	ACCOUNTID = @pnAccessAccountKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnAccessAccountKey		int',
					  @pnAccessAccountKey		= @pnAccessAccountKey

End

-- AccountNames result set
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	select	A.ACCOUNTID	as AccountKey,
		A.NAMENO	as NameKey,
		N.NAMECODE	as NameCode,
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, default)
				as DisplayName,
		CAST(A.ACCOUNTID as nvarchar)+'^'+CAST(A.NAMENO as nvarchar) as RowKey
	from	ACCESSACCOUNTNAMES A
	join	NAME N		on (N.NAMENO = A.NAMENO)
	where	A.ACCOUNTID = @pnAccessAccountKey
	order by DisplayName, NameCode, NameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnAccessAccountKey		int',
					  @pnAccessAccountKey		= @pnAccessAccountKey

End

-- AccountUsers result set
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	select	U.ACCOUNTID	as AccountKey,
		U.IDENTITYID	as IdentityKey,
		U.LOGINID	as LoginID,
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, default)
				as DisplayName,
		N.NAMECODE	as NameCode,
		N.NAMENO	as NameKey,
		P.NAME		as PortalName,
		CASE WHEN U.ISVALIDWORKBENCH = 1 THEN cast(0 as bit) ELSE cast(1 as bit) END
				as IsIncomplete,
		CAST(U.ACCOUNTID as nvarchar)+'^'+CAST(U.IDENTITYID as nvarchar) as RowKey
	from	USERIDENTITY U
	join NAME N			on (N.NAMENO = U.NAMENO)
	left join PORTAL P 		on (P.PORTALID = U.DEFAULTPORTALID)
	where	U.ACCOUNTID = @pnAccessAccountKey
	order by U.LOGINID"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnAccessAccountKey		int',
					  @pnAccessAccountKey		= @pnAccessAccountKey

End

Return @nErrorCode
GO

Grant execute on dbo.ip_ListAccessAccountData to public
GO
