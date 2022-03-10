-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_DeleteBillFormatProfile
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_DeleteBillFormatProfile]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_DeleteBillFormatProfile.'
	Drop procedure [dbo].[biw_DeleteBillFormatProfile]
End
Print '**** Creating Stored Procedure dbo.biw_DeleteBillFormatProfile...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.biw_DeleteBillFormatProfile
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnFormatProfileKey		int,
	@pdtLogDateTimeStamp	datetime,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	biw_DeleteBillFormatProfile
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete an existing bill format profile. Use LOGDATETIMESTAMP for concurrency.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 08 Jul 2010	LP		RFC9289	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @nRowCount	int
declare @sSQLString	nvarchar(max)
declare @sAlertXML nvarchar(max)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	
	Set @sSQLString = "
	Delete from FORMATPROFILE
	where FORMATPROFILE.FORMATID = @pnFormatProfileKey
	and LOGDATETIMESTAMP = @pdtLogDateTimeStamp"
	
	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnFormatProfileKey	int,
				  @pdtLogDateTimeStamp	datetime',
				  @pnFormatProfileKey	= @pnFormatProfileKey,
				  @pdtLogDateTimeStamp	= @pdtLogDateTimeStamp	
				  
	Set @nRowCount = @@rowcount
	
End

If (@nRowCount = 0)
Begin	
	Set @sAlertXML = dbo.fn_GetAlertXML('SF29', 'Concurrency violation. Bill Format Profile may have been updated or deleted. Please reload and try again.',
										null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End

if (@nErrorCode = 0 and @nRowCount = 1)
Begin
		Select @pnFormatProfileKey as 'FormatProfileKey'		
End

Return @nErrorCode
GO

Grant execute on dbo.biw_DeleteBillFormatProfile to public
GO
