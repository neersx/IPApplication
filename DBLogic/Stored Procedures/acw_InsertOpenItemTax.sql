-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_InsertOpenItemTax									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_InsertOpenItemTax]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_InsertOpenItemTax.'
	Drop procedure [dbo].[acw_InsertOpenItemTax]
End
Print '**** Creating Stored Procedure dbo.acw_InsertOpenItemTax...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.acw_InsertOpenItemTax
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnItemEntityNo		int,	-- Mandatory.
	@pnItemTransNo		int,	-- Mandatory.
	@pnAcctEntityNo		int,	-- Mandatory.
	@pnAcctDebtorNo		int,	-- Mandatory.
	@psTaxCode		nvarchar(3),	-- Mandatory.
	@pnTaxRate	        decimal(11,4)	 = null,
	@pnTaxableAmount	decimal(11,2)	 = null,
	@pnTaxAmount	        decimal(11,2)	 = null,
	@psCountryCode	        nvarchar(3)	 = null,
	@psState	        nvarchar(20)	 = null,
	@pbHarmonised	        bit		 = null,
	@pbTaxOnTax	        bit		 = null,
	@pbModified	        bit		 = null,
	@pnAdjustment	        decimal(11,2)	 = null,
        @pnForeignTaxableAmount decimal(11,2)	 = null,
        @pnForeignTaxAmount     decimal(11,2)	 = null,
        @psCurrency             nvarchar(3)      = null
)
as
-- PROCEDURE:	acw_InsertOpenItemTax
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert OpenItemTax.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 20 Jan 2009	AT	RFC3605	1	Procedure created
-- 20 Oct 2015  MS      R53933  2       Changed parameters size from decimal(8,4) to decimal(11,4)
-- 27 May 2019  MS      DR45655 3       Added columns @pnForeignTaxableAmount, @pnForeignTaxAmount and @psCurrency

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 	        nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma		        nchar(1)

Set @sComma = ","

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into OPENITEMTAX
				("


	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"
															ITEMENTITYNO,ITEMTRANSNO,ACCTENTITYNO,ACCTDEBTORNO,TAXCODE
			"

	Set @sValuesString = @sValuesString+CHAR(10)+"
															@pnItemEntityNo,@pnItemTransNo,@pnAcctEntityNo,@pnAcctDebtorNo,@psTaxCode
			"

	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"TAXRATE"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnTaxRate"

	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"TAXABLEAMOUNT"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnTaxableAmount"

	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"TAXAMOUNT"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnTaxAmount"

	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"COUNTRYCODE"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psCountryCode"

	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"STATE"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psState"

	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"HARMONISED"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pbHarmonised"

	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"TAXONTAX"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pbTaxOnTax"

	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"MODIFIED"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pbModified"

	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ADJUSTMENT"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnAdjustment"

        Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"FOREIGNTAXABLEAMOUNT"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnForeignTaxableAmount"

        Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"FOREIGNTAXAMOUNT"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnForeignTaxAmount"

        Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CURRENCY"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psCurrency"

	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnItemEntityNo		int,
			@pnItemTransNo		int,
			@pnAcctEntityNo		int,
			@pnAcctDebtorNo		int,
			@psTaxCode		nvarchar(3),
			@pnTaxRate		decimal(11,4),
			@pnTaxableAmount	decimal(11,2),
			@pnTaxAmount		decimal(11,2),
			@psCountryCode		nvarchar(3),
			@psState		nvarchar(20),
			@pbHarmonised		bit,
			@pbTaxOnTax		bit,
			@pbModified		bit,
			@pnAdjustment		decimal(11,2),
                        @pnForeignTaxableAmount decimal(11,2),
                        @pnForeignTaxAmount     decimal(11,2),
                        @psCurrency             nvarchar(3)',
			@pnItemEntityNo	 = @pnItemEntityNo,
			@pnItemTransNo	 = @pnItemTransNo,
			@pnAcctEntityNo	 = @pnAcctEntityNo,
			@pnAcctDebtorNo	 = @pnAcctDebtorNo,
			@psTaxCode	 = @psTaxCode,
			@pnTaxRate	 = @pnTaxRate,
			@pnTaxableAmount = @pnTaxableAmount,
			@pnTaxAmount	 = @pnTaxAmount,
			@psCountryCode	 = @psCountryCode,
			@psState	 = @psState,
			@pbHarmonised	 = @pbHarmonised,
			@pbTaxOnTax	 = @pbTaxOnTax,
			@pbModified	 = @pbModified,
			@pnAdjustment	 = @pnAdjustment,
                        @pnForeignTaxableAmount = @pnForeignTaxableAmount,
                        @pnForeignTaxAmount     = @pnForeignTaxAmount,
                        @psCurrency     = @psCurrency

End

Return @nErrorCode
GO

Grant execute on dbo.acw_InsertOpenItemTax to public
GO