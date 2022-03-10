-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_InsertBillLine									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_InsertBillLine]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_InsertBillLine.'
	Drop procedure [dbo].[biw_InsertBillLine]
End
Print '**** Creating Stored Procedure dbo.biw_InsertBillLine...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.biw_InsertBillLine
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnItemEntityNo		int,	-- Mandatory.
	@pnItemTransNo		int,	-- Mandatory.
	@pnItemLineNo		smallint = null,
	@psIRN		nvarchar(30) = NULL,
	@psWIPCode	nvarchar(6)		 = null,
	@psWIPTypeId	nvarchar(6)		 = null,
	@psCategoryCode	nvarchar(3)		 = null,
	@pnValue	decimal(11,2)		 = null,
	@pnDisplaySequence	smallint		 = null,
	@pdtPrintDate	datetime		 = null,
	@psPrintName	nvarchar(60)		 = null,
	@pnPrintChargeOutRate	decimal(11,2)		 = null,
	@pnPrintTotalUnits	smallint		 = null,
	@pnUnitsPerHour	smallint		 = null,
	@pnNarrativeNo	smallint		 = null,
	@psShortNarrative	nvarchar(254)		 = null,
	@ptLongNarrative	ntext		 = null,
	@pnForeignValue	decimal(11,2)		 = null,
	@psPrintChargeCurrncy	nvarchar(3)		 = null,
	@psPrintTime	nvarchar(30)		 = null,
	@pnLocalTax	decimal(11,2)		 = null,
	@psGeneratedFromTaxCode nvarchar(3)      = null,
	@pbIsHiddenForDraft bit                   = null,
	@psTaxCode	nvarchar(3)		= null
)
as
-- PROCEDURE:	biw_InsertBillLine
-- VERSION:	7
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert BillLine.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- 16 Nov 2009	AT	RFC3605		1	Procedure created
-- 31 Mar 2011  LP	RFC8412 	2	Add GeneratedFromTaxCode and IsHiddenForDraft parameters       
-- 18 May 2011	AT	RFC10654	3	Corrected print charge currency null check.    
-- 02 Jun 2011	AT	RFC10756	4	Corrected IRN null check.
-- 22 Dec 2011	AT	RFC10458	5	Save Tax Code.
-- 21 Oct 2014	AT	RFC40101	6	Don't Save foreign unless there's a print charge currency.
-- 22 Jan 2017  MS      RFC73332        7       Save foreign values without print charge currency check

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 	nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma		nchar(1)

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("

-- Generate ITEMLINENO
if (@nErrorCode = 0 and @pnItemLineNo is null)
Begin
	Set @sSQLString = "
		Select @pnItemLineNo = (max(ITEMLINENO) + 1)
		from BILLLINE
		where ITEMENTITYNO = @pnItemEntityNo
		and ITEMTRANSNO = @pnItemTransNo"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnItemLineNo int OUTPUT,
					@pnItemEntityNo int,
					@pnItemTransNo int',
					@pnItemLineNo = @pnItemLineNo OUTPUT,
					@pnItemEntityNo = @pnItemEntityNo,
					@pnItemTransNo = @pnItemTransNo

End

If (@pnItemLineNo is null)
Begin
	Set @pnItemLineNo = 1
End

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into BILLLINE
				("


	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"
									ITEMENTITYNO,ITEMTRANSNO,ITEMLINENO
			"

	Set @sValuesString = @sValuesString+CHAR(10)+"
									@pnItemEntityNo,@pnItemTransNo,@pnItemLineNo
			"

		if (@psWIPCode != '' and @psWIPCode is not null)
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"WIPCODE"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psWIPCode"
		End

		if (@psWIPTypeId != '' and @psWIPTypeId is not null)
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"WIPTYPEID"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psWIPTypeId"
		End

		if (@psCategoryCode != '' and @psCategoryCode is not null)
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CATEGORYCODE"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psCategoryCode"
		End

		If (@psIRN != '' and @psIRN is not null)
		Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"IRN"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psIRN"
		End

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"VALUE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnValue"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"DISPLAYSEQUENCE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnDisplaySequence"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PRINTDATE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pdtPrintDate"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PRINTNAME"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psPrintName"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PRINTCHARGEOUTRATE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnPrintChargeOutRate"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PRINTTOTALUNITS"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnPrintTotalUnits"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"UNITSPERHOUR"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnUnitsPerHour"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"NARRATIVENO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnNarrativeNo"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"SHORTNARRATIVE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psShortNarrative"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"LONGNARRATIVE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@ptLongNarrative"

                Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"FOREIGNVALUE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnForeignValue"

		if (@psPrintChargeCurrncy is not null and @psPrintChargeCurrncy != "")
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PRINTCHARGECURRNCY"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psPrintChargeCurrncy"
		End

		If (@psPrintTime != '' and @psPrintTime is not null)
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PRINTTIME"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psPrintTime"
		End

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"LOCALTAX"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnLocalTax"

		if (@psGeneratedFromTaxCode is not null and @psGeneratedFromTaxCode != '')
		Begin
		        Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"GENERATEDFROMTAXCODE"
		        Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psGeneratedFromTaxCode"
		End
		
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ISHIDDENFORDRAFT"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pbIsHiddenForDraft"
		
		if (@psTaxCode is not null and @psTaxCode != "")
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"TAXCODE"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psTaxCode"
		End

	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnItemEntityNo		int,
			@pnItemTransNo		int,
			@pnItemLineNo		smallint,
			@psIRN		nvarchar(30),
			@psWIPCode		nvarchar(6),
			@psWIPTypeId		nvarchar(6),
			@psCategoryCode		nvarchar(3),
			@pnValue		decimal(11,2),
			@pnDisplaySequence		smallint,
			@pdtPrintDate		datetime,
			@psPrintName		nvarchar(60),
			@pnPrintChargeOutRate		decimal(11,2),
			@pnPrintTotalUnits		smallint,
			@pnUnitsPerHour		smallint,
			@pnNarrativeNo		smallint,
			@psShortNarrative		nvarchar(254),
			@ptLongNarrative		ntext,
			@pnForeignValue		decimal(11,2),
			@psPrintChargeCurrncy		nvarchar(3),
			@psPrintTime		nvarchar(30),
			@pnLocalTax		decimal(11,2),
			@psGeneratedFromTaxCode nvarchar(3),
			@pbIsHiddenForDraft     bit,
			@psTaxCode		nvarchar(3)',
			@pnItemEntityNo	 = @pnItemEntityNo,
			@pnItemTransNo	 = @pnItemTransNo,
			@pnItemLineNo	 = @pnItemLineNo,
			@psIRN	 = @psIRN,
			@psWIPCode	 = @psWIPCode,
			@psWIPTypeId	 = @psWIPTypeId,
			@psCategoryCode	 = @psCategoryCode,
			@pnValue	 = @pnValue,
			@pnDisplaySequence	 = @pnDisplaySequence,
			@pdtPrintDate	 = @pdtPrintDate,
			@psPrintName	 = @psPrintName,
			@pnPrintChargeOutRate	 = @pnPrintChargeOutRate,
			@pnPrintTotalUnits	 = @pnPrintTotalUnits,
			@pnUnitsPerHour	 = @pnUnitsPerHour,
			@pnNarrativeNo	 = @pnNarrativeNo,
			@psShortNarrative	 = @psShortNarrative,
			@ptLongNarrative	 = @ptLongNarrative,
			@pnForeignValue	 = @pnForeignValue,
			@psPrintChargeCurrncy	 = @psPrintChargeCurrncy,
			@psPrintTime	 = @psPrintTime,
			@pnLocalTax	 = @pnLocalTax,
			@psGeneratedFromTaxCode = @psGeneratedFromTaxCode,
			@pbIsHiddenForDraft = @pbIsHiddenForDraft,
			@psTaxCode = @psTaxCode

End

Return @nErrorCode
GO

Grant execute on dbo.biw_InsertBillLine to public
GO