-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_InsertIPName									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_InsertIPName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_InsertIPName.'
	Drop procedure [dbo].[naw_InsertIPName]
End
Print '**** Creating Stored Procedure dbo.naw_InsertIPName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_InsertIPName
(
	@pnUserIdentityId				int,		-- Mandatory
	@psCulture					nvarchar(10) 	= null,
	@pbCalledFromCentura				bit		= 0,
	@pnNameKey					int,		-- Mandatory
	@psTaxCode					nvarchar(3)	= null,
	@pnDebtorRestrictionKey				smallint	= null,
	@psBillCurrencyCode				nvarchar(3)	= null,
	@pnDebitNoteCopies				smallint	= null,
	@pbHasMultiCaseBills				bit		= null,
	@pbHasMultiCaseBillsByOwner			bit		= null,
	@pnDebtorTypeKey				int		= null,
	@pnUseDebtorTypeKey				int		= null,
	@psDefaultCorrespondenceInstructions		nvarchar(254)	= null,
	@pnCategoryKey					int		= null,
	@psPurchaseOrderNo				nvarchar(80)	= null,
	@pbIsLocalClient				bit		= null,
	@psAirportCode					nvarchar(5)	= null,
	@pnReceivableTermsDays				int		= null,
	@pnBillingFrequencyKey				int		= null,
	@pnCreditLimit					decimal(12,2)	= null,
	@pbIsTaxCodeInUse				bit	 	= 0,
	@pbIsDebtorRestrictionKeyInUse			bit	 	= 0,
	@pbIsBillCurrencyCodeInUse			bit	 	= 0,
	@pbIsDebitNoteCopiesInUse			bit	 	= 0,
	@pbIsHasMultiCaseBillsInUse			bit	 	= 0,
	@pbIsHasMultiCaseBillsByOwnerInUse		bit	 	= 0,
	@pbIsDebtorTypeKeyInUse				bit	 	= 0,
	@pbIsUseDebtorTypeKeyInUse			bit	 	= 0,
	@pbIsDefaultCorrespondenceInstructionsInUse	bit	 	= 0,
	@pbIsCategoryKeyInUse				bit	 	= 0,
	@pbIsPurchaseOrderNoInUse			bit	 	= 0,
	@pbIsIsLocalClientInUse				bit	 	= 0,
	@pbIsAirportCodeInUse				bit	 	= 0,
	@pbIsReceivableTermsDaysInUse			bit	 	= 0,
	@pbIsBillingFrequencyKeyInUse			bit	 	= 0,
	@pbIsCreditLimitInUse				bit	 	= 0
)
as
-- PROCEDURE:	naw_InsertIPName
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert IPName.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 13 Apr 2006	IB	RFC3763	1	Procedure created
-- 19 Mar 2008	vql	SQA14773 2      Make PurchaseOrderNo nvarchar(80)
-- 25 Mar 2008	Ash	RFC5438	3	Maintain data in different culture
-- 15 Apr 2008	SF	RFC6454	4	Backout changes made in RFC5438 temporarily

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 		nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma			nchar(1)
Declare @nConsolidation		tinyint
Declare @sDBCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("
Set @nConsolidation = 0

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into IPNAME
				("


	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"
			NAMENO
			"

	Set @sValuesString = @sValuesString+CHAR(10)+"
			@pnNameKey
			"

	If @pbIsTaxCodeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"TAXCODE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psTaxCode"
	End

	If @pbIsDebtorRestrictionKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"BADDEBTOR"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnDebtorRestrictionKey"
	End

	If @pbIsBillCurrencyCodeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CURRENCY"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psBillCurrencyCode"
	End

	If @pbIsDebitNoteCopiesInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"DEBITCOPIES"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnDebitNoteCopies"
	End

	If @pbIsHasMultiCaseBillsInUse = 1
	or @pbIsHasMultiCaseBillsByOwnerInUse = 1
	Begin

		If @pbIsHasMultiCaseBillsInUse = 1
		Begin
			If @pbHasMultiCaseBills is null
			Begin
				Set @pbHasMultiCaseBills = 0
			End
			Set @nConsolidation = @nConsolidation|@pbHasMultiCaseBills
		End

		If @pbIsHasMultiCaseBillsByOwnerInUse = 1
		Begin
			If @pbHasMultiCaseBillsByOwner is null
			Begin
				Set @pbHasMultiCaseBillsByOwner = 0
			End
			Set @nConsolidation = @nConsolidation|(2*@pbHasMultiCaseBillsByOwner)
		End

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CONSOLIDATION"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnConsolidation"
	End

	If @pbIsDebtorTypeKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"DEBTORTYPE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnDebtorTypeKey"
	End

	If @pbIsUseDebtorTypeKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"USEDEBTORTYPE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnUseDebtorTypeKey"
	End

	If @pbIsDefaultCorrespondenceInstructionsInUse = 1
	-- Only insert to base table if culture matches
	--and @psCulture = @sDBCulture
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CORRESPONDENCE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psDefaultCorrespondenceInstructions"
	End

	If @pbIsCategoryKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CATEGORY"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnCategoryKey"
	End

	If @pbIsPurchaseOrderNoInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PURCHASEORDERNO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psPurchaseOrderNo"
	End

	If @pbIsIsLocalClientInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"LOCALCLIENTFLAG"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pbIsLocalClient"
	End

	If @pbIsAirportCodeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"AIRPORTCODE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psAirportCode"
	End

	If @pbIsReceivableTermsDaysInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"TRADINGTERMS"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnReceivableTermsDays"
	End

	If @pbIsBillingFrequencyKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"BILLINGFREQUENCY"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnBillingFrequencyKey"
	End

	If @pbIsCreditLimitInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CREDITLIMIT"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnCreditLimit"
	End

	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnNameKey				int,
			@psTaxCode				nvarchar(3),
			@pnDebtorRestrictionKey			smallint,
			@psBillCurrencyCode			nvarchar(3),
			@pnDebitNoteCopies			smallint,
			@pnConsolidation			tinyint,
			@pnDebtorTypeKey			int,
			@pnUseDebtorTypeKey			int,
			@psDefaultCorrespondenceInstructions	nvarchar(254),
			@pnCategoryKey				int,
			@psPurchaseOrderNo			nvarchar(80),
			@pbIsLocalClient			bit,
			@psAirportCode				nvarchar(5),
			@pnReceivableTermsDays			int,
			@pnBillingFrequencyKey			int,
			@pnCreditLimit				decimal(12,2)',
			@pnNameKey	 			= @pnNameKey,
			@psTaxCode	 			= @psTaxCode,
			@pnDebtorRestrictionKey	 		= @pnDebtorRestrictionKey,
			@psBillCurrencyCode	 		= @psBillCurrencyCode,
			@pnDebitNoteCopies	 		= @pnDebitNoteCopies,
			@pnConsolidation	 		= @nConsolidation,
			@pnDebtorTypeKey	 		= @pnDebtorTypeKey,
			@pnUseDebtorTypeKey	 		= @pnUseDebtorTypeKey,
			@psDefaultCorrespondenceInstructions	= @psDefaultCorrespondenceInstructions,
			@pnCategoryKey	 			= @pnCategoryKey,
			@psPurchaseOrderNo	 		= @psPurchaseOrderNo,
			@pbIsLocalClient	 		= @pbIsLocalClient,
			@psAirportCode	 			= @psAirportCode,
			@pnReceivableTermsDays	 		= @pnReceivableTermsDays,
			@pnBillingFrequencyKey	 		= @pnBillingFrequencyKey,
			@pnCreditLimit	 			= @pnCreditLimit

End
	-- If culture doesn't match the database main culture, we need to maintain the translated data.
	/*
	If @nErrorCode = 0
	and @psCulture <> @sDBCulture
	Begin

		Set @sSQLString = "
			Insert into TRANSLATEDTEXT (TID, CULTURE, SHORTTEXT)
			select CORRESPONDENCE_TID, @psCulture, @psDefaultCorrespondenceInstructions
			from IPNAME
			where NAMENO=@pnNameKey "

		exec @nErrorCode=sp_executesql @sSQLString,
					N'
					@pnNameKey		int,
					@psCulture		nvarchar(10),
					@psDefaultCorrespondenceInstructions		nvarchar(254)',
					@pnNameKey		= @pnNameKey,
					@psCulture		= @psCulture,
					@psDefaultCorrespondenceInstructions= @psDefaultCorrespondenceInstructions
	End
	*/


Return @nErrorCode
GO

Grant execute on dbo.naw_InsertIPName to public
GO



