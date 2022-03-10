-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_DeleteBillMapRule
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_DeleteBillMapRule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_DeleteBillMapRule.'
	Drop procedure [dbo].[biw_DeleteBillMapRule]
End
Print '**** Creating Stored Procedure dbo.biw_DeleteBillMapRule...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.biw_DeleteBillMapRule
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnBillMapRuleKey	int,
	@pdtLogDateTimeStamp	datetime
)
as
-- PROCEDURE:	biw_DeleteBillMapRule
-- VERSION:	1
-- DESCRIPTION:	Delete a bill map rule.

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
	Set @sSQLString = "DELETE FROM BILLMAPRULES
			WHERE MAPRULEID = @pnBillMapRuleKey
			AND LOGDATETIMESTAMP = @pdtLogDateTimeStamp"

	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnBillMapRuleKey	int,
			@pdtLogDateTimeStamp	datetime',
			@pnBillMapRuleKey=@pnBillMapRuleKey,
			@pdtLogDateTimeStamp=@pdtLogDateTimeStamp

	if (@@ROWCOUNT = 0)
	Begin
		-- BillMapProfile not found
		Set @sAlertXML = dbo.fn_GetAlertXML('BI3', 'Concurrency error. Bill Map Rule has been changed or deleted. Please reload and try again.',
							null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = 1
	End
End

Return @nErrorCode
GO

Grant execute on dbo.biw_DeleteBillMapRule to public
GO