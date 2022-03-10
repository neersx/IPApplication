-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_UpdateBillFormatProfile
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_UpdateBillFormatProfile]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_UpdateBillFormatProfile.'
	Drop procedure [dbo].[biw_UpdateBillFormatProfile]
End
Print '**** Creating Stored Procedure dbo.biw_UpdateBillFormatProfile...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.biw_UpdateBillFormatProfile
(
	@pnUserIdentityId			int,			-- Mandatory
	@psCulture					nvarchar(10) 	= null,
	@pnFormatProfileKey			int,
	@psFormatProfileDescription nvarchar(100),
	@pnPresentationKey			int				= null,
	@pbIsConsolidated			bit				= 0,
	@pbIsSingleDiscount			bit				= 0,
	@psWebService				nvarchar(254)	= null,	
	@pdtLogDateTimeStamp		datetime		= null,
	@pbCalledFromCentura		bit				= 0
)
as
-- PROCEDURE:	biw_UpdateBillFormatProfile
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Updates values and properties of an existing bill format profile.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 Jul 2010	LP		RFC9289	1		Procedure created

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
	Update FORMATPROFILE
	set FORMATDESC = @psFormatProfileDescription,
	CONSOLIDATIONFLAG = @pbIsConsolidated,
	SINGLEDISCOUNT = @pbIsSingleDiscount,
	WEBSERVICE = @psWebService,
	PRESENTATIONID = @pnPresentationKey
	where FORMATPROFILE.FORMATID = @pnFormatProfileKey
	and LOGDATETIMESTAMP = @pdtLogDateTimeStamp"
	
	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnFormatProfileKey	int,
				  @pnPresentationKey	int,
				  @pbIsConsolidated		bit,
				  @pbIsSingleDiscount	bit,
				  @psFormatProfileDescription nvarchar(100),
				  @psWebService			nvarchar(254),
				  @pdtLogDateTimeStamp	datetime',
				  @pnFormatProfileKey	= @pnFormatProfileKey,
				  @pnPresentationKey	= @pnPresentationKey,
				  @pbIsConsolidated		= @pbIsConsolidated,
				  @pbIsSingleDiscount	= @pbIsSingleDiscount,
				  @psFormatProfileDescription = @psFormatProfileDescription,
				  @psWebService			= @psWebService,
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

-- Publish new LOGDATETIMESTAMP
if (@nErrorCode = 0)
Begin
		Select @pnFormatProfileKey as 'FormatProfileKey',
		LOGDATETIMESTAMP as 'LogDateTimeStamp'
		from FORMATPROFILE
		WHERE FORMATID = @pnFormatProfileKey
End

Return @nErrorCode
GO

Grant execute on dbo.biw_UpdateBillFormatProfile to public
GO
