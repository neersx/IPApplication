-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_UpdateTaxRate
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_UpdateTaxRate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_UpdateTaxRate.'
	Drop procedure [dbo].[acw_UpdateTaxRate]
End
Print '**** Creating Stored Procedure dbo.acw_UpdateTaxRate...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.acw_UpdateTaxRate
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psOldTaxCode           nvarchar(3),
	@psTaxCode              nvarchar(3),
	@psDescription          nvarchar(30)    = null,
	@psWipCode              nvarchar(6)     = null,
	@psWipCategory          nvarchar(3)     = null,
	@pnNarrativeKey         smallint        = null,
	@psCurrencyCode         nvarchar(3)     = null,
	@pdMaxFreeAmount        decimal(12,2)         = null,
	@pdFeeAmount            decimal(12,2)         = null,
	@pdFeePercent           decimal(11,4)         = null,
	@pbHideForDraft         bit             = 0,        
	@pbCalledFromCentura	bit		= 0,
	@pdtLastUpdatedDate     datetime        = null,
	@pbOneFeePerDebtor		bit		= 0
)
as
-- PROCEDURE:	acw_UpdateTaxRate
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update the details of an existing Tax Code

-- MODIFICATIONS :
-- Date		Who	Change	        Version	Description
-- -----------	-------	-----------	-------	----------------------------------------------- 
-- 23 Mar 2011  LP      RFC8412		1       Procedure created.
-- 15 Aug 2012	AT	RFC12431	2	Added ONEFEEPERDEBTOR option.
-- 20 Oct 2015  MS      R53933          3       Changed parameters size from decimal(8,4) to decimal(11,4)

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString     nvarchar(max)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
        If not exists (Select 1 from TAXRATES where TAXCODE = @psOldTaxCode and 
                (LOGDATETIMESTAMP = @pdtLastUpdatedDate or (LOGDATETIMESTAMP IS NULL and @pdtLastUpdatedDate is null)))
	Begin		
		DECLARE @message_string VARCHAR(255)  
		SET @message_string = 'Concurrency violation: The Update command affected 0 records.'  
		RAISERROR(@message_string, 16, 1)
	End
	Else
	Begin	
	        Set @sSQLString = "
	        UPDATE TAXRATES
	         Set TAXCODE = @psTaxCode,
	         DESCRIPTION = @psDescription,
	         WIPCODE = @psWipCode,
	         WIPCATEGORY = @psWipCategory,
	         NARRATIVENO = @pnNarrativeKey,
	         CURRENCYCODE = @psCurrencyCode,
	         MAXFREEAMOUNT = @pdMaxFreeAmount,
	         FEEAMOUNT = @pdFeeAmount,
	         FEEPERCENTAGE = @pdFeePercent,
	         HIDEFEEINDRAFT = @pbHideForDraft,
	         ONEFEEPERDEBTOR = @pbOneFeePerDebtor
	        where TAXCODE = @psOldTaxCode
	        and LOGDATETIMESTAMP = @pdtLastUpdatedDate"
	 
	         exec @nErrorCode = sp_executesql @sSQLString,
	               N'@psTaxCode     nvarchar(3),
	               @psOldTaxCode    nvarchar(3),
	               @psDescription   nvarchar(30),
	               @psWipCode       nvarchar(6),
	               @psWipCategory   nvarchar(3),
	               @pnNarrativeKey  smallint,
	               @psCurrencyCode  nvarchar(3),
	               @pdMaxFreeAmount decimal(12,2),
	               @pdFeeAmount     decimal(12,2),
	               @pdFeePercent    decimal(11,4),
	               @pbHideForDraft   bit,
	               @pdtLastUpdatedDate datetime,
	               @pbOneFeePerDebtor	bit',
	               @psTaxCode       = @psTaxCode,
	               @psOldTaxCode    = @psOldTaxCode,
	               @psDescription   = @psDescription,
	               @psWipCode       = @psWipCode,
	               @psWipCategory   = @psWipCategory,
	               @pnNarrativeKey  = @pnNarrativeKey,
	               @psCurrencyCode  = @psCurrencyCode,
	               @pdMaxFreeAmount = @pdMaxFreeAmount,
	               @pdFeeAmount     = @pdFeeAmount,
	               @pdFeePercent    = @pdFeePercent,
	               @pbHideForDraft  = @pbHideForDraft,
	               @pdtLastUpdatedDate = @pdtLastUpdatedDate,
	               @pbOneFeePerDebtor = @pbOneFeePerDebtor
	 End
	
End

Return @nErrorCode
GO

Grant execute on dbo.acw_UpdateTaxRate to public
GO
