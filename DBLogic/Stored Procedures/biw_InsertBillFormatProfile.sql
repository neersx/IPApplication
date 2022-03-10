-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_InsertBillFormatProfile
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_InsertBillFormatProfile]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_InsertBillFormatProfile.'
	Drop procedure [dbo].[biw_InsertBillFormatProfile]
End
Print '**** Creating Stored Procedure dbo.biw_InsertBillFormatProfile...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.biw_InsertBillFormatProfile
(
	@pnUserIdentityId			int,							-- Mandatory
	@psCulture					nvarchar(10) 	= null,
	@psFormatProfileDescription nvarchar(100),
	@pnPresentationKey			int				= null,
	@pbIsConsolidated			bit				= 0,
	@pbIsSingleDiscount			bit				= 0,
	@psWebService				nvarchar(254)	= null,
	@pbCalledFromCentura		bit				= 0
)
as
-- PROCEDURE:	biw_InsertBillFormatProfile
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Create a new Bill Format Profile

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 06 Jul 2010	LP		RFC9289	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(max)
declare @nFormatProfileKey int
declare @nRowCount	int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = 
		"INSERT INTO FORMATPROFILE(PRESENTATIONID, CONSOLIDATIONFLAG, SINGLEDISCOUNT, FORMATDESC, WEBSERVICE)
		VALUES (@pnPresentationKey, @pbIsConsolidated, @pbIsSingleDiscount, @psFormatProfileDescription, @psWebService)
		
		Set @nFormatProfileKey = SCOPE_IDENTITY()"
		
		exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnPresentationKey	int,
				  @pbIsConsolidated		bit,
				  @pbIsSingleDiscount	bit,
				  @psFormatProfileDescription nvarchar(100),
				  @psWebService			nvarchar(254),
				  @nFormatProfileKey	int output',
				  @pnPresentationKey	= @pnPresentationKey,
				  @pbIsConsolidated		= @pbIsConsolidated,
				  @pbIsSingleDiscount	= @pbIsSingleDiscount,
				  @psFormatProfileDescription = @psFormatProfileDescription,
				  @psWebService			= @psWebService,
				  @nFormatProfileKey	= @nFormatProfileKey output
				  
		Set @nRowCount = @@rowcount
End

-- Publish new LOGDATETIMESTAMP
if (@nErrorCode = 0 and @nRowCount = 1)
Begin
		Select @nFormatProfileKey as 'FormatProfileKey',
		LOGDATETIMESTAMP as 'LogDateTimeStamp'
		from FORMATPROFILE
		WHERE FORMATID = @nFormatProfileKey
End

Return @nErrorCode
GO

Grant execute on dbo.biw_InsertBillFormatProfile to public
GO
