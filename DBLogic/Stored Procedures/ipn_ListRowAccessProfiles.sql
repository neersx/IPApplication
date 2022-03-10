-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.ipn_ListRowAccessProfiles
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_ListRowAccessProfiles]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipn_ListRowAccessProfiles.'
	Drop procedure [dbo].[ipn_ListRowAccessProfiles]
	Print '**** Creating Stored Procedure dbo.ipn_ListRowAccessProfiles...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipn_ListRowAccessProfiles
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null
)
-- PROCEDURE:	ipn_ListRowAccessProfiles
-- VERSION :	3
-- DESCRIPTION:	Support for Row Access

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 17-OCT-2002  SF	1	Procedure created

as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int

Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Select 	ACCESSNAME 	as ProfileKey,
		ACCESSNAME	as ProfileName,
		ACCESSDESC	as ProfileDescription
	from	ROWACCESS

	Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.ipn_ListRowAccessProfiles to public
GO
