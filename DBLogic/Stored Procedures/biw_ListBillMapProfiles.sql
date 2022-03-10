-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_ListBillMapProfiles
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_ListBillMapProfiles]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_ListBillMapProfiles.'
	Drop procedure [dbo].[biw_ListBillMapProfiles]
End
Print '**** Creating Stored Procedure dbo.biw_ListBillMapProfiles...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.biw_ListBillMapProfiles
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0

)
as
-- PROCEDURE:	biw_ListBillMapProfiles
-- VERSION:	1
-- DESCRIPTION:	Return available bill map profiles.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30 Jun 2010	AT	RFC7271	1	Procedure created.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode				int
Declare @sSQLString				nvarchar(4000)
Declare @sLookupCulture				nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set @nErrorCode = 0

If (@nErrorCode = 0)
Begin
	Set @sSQLString = "SELECT 
	BILLMAPPROFILEID as 'BillMapProfileKey',
	BILLMAPDESC as 'BillMapDescription',
	SCHEMANAME as 'SchemaName',
	LOGDATETIMESTAMP as 'LogDateTimeStamp'
	FROM BILLMAPPROFILE
	ORDER BY BILLMAPDESC"

	exec @nErrorCode = sp_executesql @sSQLString
End

Return @nErrorCode
GO

Grant execute on dbo.biw_ListBillMapProfiles to public
GO
