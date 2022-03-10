-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_InsertTaxRate
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_InsertTaxRate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_InsertTaxRate.'
	Drop procedure [dbo].[acw_InsertTaxRate]
End
Print '**** Creating Stored Procedure dbo.acw_InsertTaxRate...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.acw_InsertTaxRate
(
	@pnUserIdentityId	int,		
	@psCulture		nvarchar(10) 	= null,
	@psTaxCode              nvarchar(3),
	@psDescription          nvarchar(30)    = null,
	@psWipCode              nvarchar(6)     = null,
	@psWipCategory          nvarchar(3)     = null,
	@pnNarrativeKey         smallint        = null,
	@psCurrencyCode         nvarchar(3)     = null,
	@pdMaxFreeAmount        decimal(12,2)   = null,
	@pdFeeAmount            decimal(12,2)   = null,
	@pdFeePercent           decimal(12,2)   = null,
	@pbHideForDraft         bit             = 0,
	@pbCalledFromCentura	bit		= 0,
	@pbOneFeePerDebtor		bit		= 0
)
as
-- PROCEDURE:	acw_InsertTaxRate
-- VERSION:		3
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Create a new Tax Code in the system
--              Raises an error for duplicate Tax Codes.

-- MODIFICATIONS :
-- Date			Who		Change		Version	Description
-- -----------	-------	-----------	-------	----------------------------------------------- 
-- 23 Mar 2011  LP      RFC8412		1		Procedure created
-- 05 Jul 2011	LP		RFC10907	2		Specified length and precision for decimal parameters as these values were being rounded up.
-- 14-Aug-2012	AT		RFC12431	3		Added ONEFEEPERDEBTOR column.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString     nvarchar(max)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
        If exists (Select 1 from TAXRATES where TAXCODE = @psTaxCode)
	Begin		
		DECLARE @message_string VARCHAR(255)  
		SET @message_string = 'Cannot insert duplicate TAXRATE.'  
		RAISERROR(@message_string, 16, 1)
	End
	Else
	Begin	
	        Set @sSQLString = "
	        INSERT INTO TAXRATES(TAXCODE, DESCRIPTION, WIPCODE, WIPCATEGORY, NARRATIVENO, CURRENCYCODE, MAXFREEAMOUNT, FEEAMOUNT, FEEPERCENTAGE, HIDEFEEINDRAFT, ONEFEEPERDEBTOR)
	        values (@psTaxCode,
	                @psDescription,
	                @psWipCode,
	                @psWipCategory,
	                @pnNarrativeKey,
	                @psCurrencyCode,
	                @pdMaxFreeAmount,
	                @pdFeeAmount,
	                @pdFeePercent,
	                @pbHideForDraft,
	                @pbOneFeePerDebtor)"
	 
	         exec @nErrorCode = sp_executesql @sSQLString,
	               N'@psTaxCode     nvarchar(3),
	               @psDescription   nvarchar(30),
	               @psWipCode       nvarchar(6),
	               @psWipCategory   nvarchar(3),
	               @pnNarrativeKey  smallint,
	               @psCurrencyCode  nvarchar(3),
	               @pdMaxFreeAmount decimal(12,2),
	               @pdFeeAmount     decimal(12,2),
	               @pdFeePercent    decimal(12,2),
	               @pbHideForDraft   bit,
	               @pbOneFeePerDebtor bit',
	               @psTaxCode       = @psTaxCode,
	               @psDescription   = @psDescription,
	               @psWipCode       = @psWipCode,
	               @psWipCategory   = @psWipCategory,
	               @pnNarrativeKey  = @pnNarrativeKey,
	               @psCurrencyCode  = @psCurrencyCode,
	               @pdMaxFreeAmount = @pdMaxFreeAmount,
	               @pdFeeAmount     = @pdFeeAmount,
	               @pdFeePercent    = @pdFeePercent,
	               @pbHideForDraft  = @pbHideForDraft,
	               @pbOneFeePerDebtor = @pbOneFeePerDebtor
	 End
	               
End

Return @nErrorCode
GO

Grant execute on dbo.acw_InsertTaxRate to public
GO
