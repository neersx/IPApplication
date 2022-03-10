-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_UpdateBillMapProfile
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_UpdateBillMapProfile]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_UpdateBillMapProfile.'
	Drop procedure [dbo].[biw_UpdateBillMapProfile]
End
Print '**** Creating Stored Procedure dbo.biw_UpdateBillMapProfile...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.biw_UpdateBillMapProfile
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnBillMapProfileKey	int,
	@psBillMapDesc		nvarchar(200)	= null,
	@psSchemaName		nvarchar(200)	= null,
	@pdtLogDateTimeStamp	datetime
)
as
-- PROCEDURE:	biw_UpdateBillMapProfile
-- VERSION:	1
-- DESCRIPTION:	Update a bill map profile.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 01 Jul 2010	AT	RFC7271	1	Procedure created.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @sAlertXML	nvarchar(1000)

Set @nErrorCode = 0

If (@nErrorCode = 0)
Begin
	Set @sSQLString = "UPDATE BILLMAPPROFILE
			Set BILLMAPDESC = @psBillMapDesc,
			SCHEMANAME = @psSchemaName
			WHERE BILLMAPPROFILEID = @pnBillMapProfileKey
			AND LOGDATETIMESTAMP = @pdtLogDateTimeStamp"

	exec @nErrorCode = sp_executesql @sSQLString,
			N'@psBillMapDesc nvarchar(200),
			@psSchemaName		nvarchar(200),
			@pnBillMapProfileKey	int,
			@pdtLogDateTimeStamp	datetime',
			@psBillMapDesc=@psBillMapDesc,
			@psSchemaName=@psSchemaName,
			@pnBillMapProfileKey=@pnBillMapProfileKey,
			@pdtLogDateTimeStamp=@pdtLogDateTimeStamp
	if (@@ROWCOUNT = 0)
	Begin
		-- BillMapProfile not found
		Set @sAlertXML = dbo.fn_GetAlertXML('BI2', 'Concurrency error. Bill Map Profile has been changed or deleted. Please reload and try again.',
							null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = 1
	End
End

if (@nErrorCode = 0)
Begin
	Select @pnBillMapProfileKey as 'BillMapProfileKey',
	LOGDATETIMESTAMP as 'LogDateTimeStamp'
	from BILLMAPPROFILE 
	WHERE BILLMAPPROFILEID = @pnBillMapProfileKey
End

Return @nErrorCode
GO

Grant execute on dbo.biw_UpdateBillMapProfile to public
GO