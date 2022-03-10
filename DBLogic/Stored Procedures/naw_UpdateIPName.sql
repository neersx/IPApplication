-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateIPName									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateIPName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateIPName.'
	Drop procedure [dbo].[naw_UpdateIPName]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateIPName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_UpdateIPName
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
	@psOldTaxCode					nvarchar(3)	= null,
	@pnOldDebtorRestrictionKey			smallint	= null,
	@psOldBillCurrencyCode				nvarchar(3)	= null,
	@pnOldDebitNoteCopies				smallint	= null,
	@pbOldHasMultiCaseBills				bit		= null,
	@pbOldHasMultiCaseBillsByOwner			bit		= null,
	@pnOldDebtorTypeKey				int		= null,
	@pnOldUseDebtorTypeKey				int		= null,
	@psOldDefaultCorrespondenceInstructions		nvarchar(254)	= null,
	@pnOldCategoryKey				int		= null,
	@psOldPurchaseOrderNo				nvarchar(80)	= null,
	@pbOldIsLocalClient				bit		= null,
	@psOldAirportCode				nvarchar(5)	= null,
	@pnOldReceivableTermsDays			int		= null,
	@pnOldBillingFrequencyKey			int		= null,
	@pnOldCreditLimit				decimal(12,2)	= null,
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
-- PROCEDURE:	naw_UpdateIPName
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update IPName if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 13 Apr 2006	IB	RFC3763	1	Procedure created
-- 19 Mar 2008	vql	SQA14773 2      Make PurchaseOrderNo nvarchar(80)
-- 15 Feb 2012  MS      RFC11912 3      Add ISNULL before checking CONSOLIDATION with old value

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sUpdateString 		nvarchar(4000)
Declare @sWhereString		nvarchar(4000)
Declare @sComma			nchar(1)
Declare @sAnd			nchar(5)
Declare @nConsolidation		tinyint
Declare @nOldConsolidation	tinyint

-- Initialise variables
Set @nErrorCode 	= 0
Set @sWhereString 	= CHAR(10)+" where "
Set @nConsolidation 	= 0
Set @nOldConsolidation 	= 0

If @nErrorCode = 0
Begin
	Set @sUpdateString = "Update IPNAME
			   set "

	Set @sWhereString = @sWhereString+CHAR(10)+"
		NAMENO = @pnNameKey"
	
	Set @sAnd = " and "

	If @pbIsTaxCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"TAXCODE = @psTaxCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"TAXCODE = @psOldTaxCode"
		Set @sComma = ","
	End

	If @pbIsDebtorRestrictionKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"BADDEBTOR = @pnDebtorRestrictionKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"BADDEBTOR = @pnOldDebtorRestrictionKey"
		Set @sComma = ","
	End

	If @pbIsBillCurrencyCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CURRENCY = @psBillCurrencyCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"CURRENCY = @psOldBillCurrencyCode"
		Set @sComma = ","
	End

	If @pbIsDebitNoteCopiesInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"DEBITCOPIES = @pnDebitNoteCopies"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"DEBITCOPIES = @pnOldDebitNoteCopies"
		Set @sComma = ","
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
		
		If @pbOldHasMultiCaseBills is null
		Begin
			Set @pbOldHasMultiCaseBills = 0
		End
		If @pbOldHasMultiCaseBillsByOwner is null
		Begin
			Set @pbOldHasMultiCaseBillsByOwner = 0
		End
		Set @nOldConsolidation = @nOldConsolidation|@pbOldHasMultiCaseBills|(2*@pbOldHasMultiCaseBillsByOwner)

		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CONSOLIDATION = @pnConsolidation"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"ISNULL(CONSOLIDATION,0) = @pnOldConsolidation"
		Set @sComma = ","
	End

	If @pbIsDebtorTypeKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"DEBTORTYPE = @pnDebtorTypeKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"DEBTORTYPE = @pnOldDebtorTypeKey"
		Set @sComma = ","
	End

	If @pbIsUseDebtorTypeKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"USEDEBTORTYPE = @pnUseDebtorTypeKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"USEDEBTORTYPE = @pnOldUseDebtorTypeKey"
		Set @sComma = ","
	End

	If @pbIsDefaultCorrespondenceInstructionsInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CORRESPONDENCE = @psDefaultCorrespondenceInstructions"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"CORRESPONDENCE = @psOldDefaultCorrespondenceInstructions"
		Set @sComma = ","
	End

	If @pbIsCategoryKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CATEGORY = @pnCategoryKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"CATEGORY = @pnOldCategoryKey"
		Set @sComma = ","
	End

	If @pbIsPurchaseOrderNoInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"PURCHASEORDERNO = @psPurchaseOrderNo"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"PURCHASEORDERNO = @psOldPurchaseOrderNo"
		Set @sComma = ","
	End

	If @pbIsIsLocalClientInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"LOCALCLIENTFLAG = @pbIsLocalClient"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"LOCALCLIENTFLAG = @pbOldIsLocalClient"
		Set @sComma = ","
	End

	If @pbIsAirportCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"AIRPORTCODE = @psAirportCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"AIRPORTCODE = @psOldAirportCode"
		Set @sComma = ","
	End

	If @pbIsReceivableTermsDaysInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"TRADINGTERMS = @pnReceivableTermsDays"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"TRADINGTERMS = @pnOldReceivableTermsDays"
		Set @sComma = ","
	End

	If @pbIsBillingFrequencyKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"BILLINGFREQUENCY = @pnBillingFrequencyKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"BILLINGFREQUENCY = @pnOldBillingFrequencyKey"
		Set @sComma = ","
	End

	If @pbIsCreditLimitInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CREDITLIMIT = @pnCreditLimit"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"CREDITLIMIT = @pnOldCreditLimit"
		Set @sComma = ","
	End

	Set @sSQLString = @sUpdateString + @sWhereString

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
			@pnCreditLimit				decimal(12,2),
			@psOldTaxCode				nvarchar(3),
			@pnOldDebtorRestrictionKey		smallint,
			@psOldBillCurrencyCode			nvarchar(3),
			@pnOldDebitNoteCopies			smallint,
			@pnOldConsolidation			tinyint,
			@pnOldDebtorTypeKey			int,
			@pnOldUseDebtorTypeKey			int,
			@psOldDefaultCorrespondenceInstructions	nvarchar(254),
			@pnOldCategoryKey			int,
			@psOldPurchaseOrderNo			nvarchar(80),
			@pbOldIsLocalClient			bit,
			@psOldAirportCode			nvarchar(5),
			@pnOldReceivableTermsDays		int,
			@pnOldBillingFrequencyKey		int,
			@pnOldCreditLimit			decimal(12,2)',
			@pnNameKey	 			= @pnNameKey,
			@psTaxCode	 			= @psTaxCode,
			@pnDebtorRestrictionKey	 		= @pnDebtorRestrictionKey,
			@psBillCurrencyCode	 		= @psBillCurrencyCode,
			@pnDebitNoteCopies	 		= @pnDebitNoteCopies,
			@pnConsolidation 			= @nConsolidation,
			@pnDebtorTypeKey	 		= @pnDebtorTypeKey,
			@pnUseDebtorTypeKey	 		= @pnUseDebtorTypeKey,
			@psDefaultCorrespondenceInstructions	= @psDefaultCorrespondenceInstructions,
			@pnCategoryKey	 			= @pnCategoryKey,
			@psPurchaseOrderNo	 		= @psPurchaseOrderNo,
			@pbIsLocalClient	 		= @pbIsLocalClient,
			@psAirportCode	 			= @psAirportCode,
			@pnReceivableTermsDays	 		= @pnReceivableTermsDays,
			@pnBillingFrequencyKey	 		= @pnBillingFrequencyKey,
			@pnCreditLimit	 			= @pnCreditLimit,
			@psOldTaxCode	 			= @psOldTaxCode,
			@pnOldDebtorRestrictionKey	 	= @pnOldDebtorRestrictionKey,
			@psOldBillCurrencyCode	 		= @psOldBillCurrencyCode,
			@pnOldDebitNoteCopies	 		= @pnOldDebitNoteCopies,
			@pnOldConsolidation 			= @nOldConsolidation,
			@pnOldDebtorTypeKey	 		= @pnOldDebtorTypeKey,
			@pnOldUseDebtorTypeKey	 		= @pnOldUseDebtorTypeKey,
			@psOldDefaultCorrespondenceInstructions	= @psOldDefaultCorrespondenceInstructions,
			@pnOldCategoryKey	 		= @pnOldCategoryKey,
			@psOldPurchaseOrderNo	 		= @psOldPurchaseOrderNo,
			@pbOldIsLocalClient	 		= @pbOldIsLocalClient,
			@psOldAirportCode	 		= @psOldAirportCode,
			@pnOldReceivableTermsDays	 	= @pnOldReceivableTermsDays,
			@pnOldBillingFrequencyKey	 	= @pnOldBillingFrequencyKey,
			@pnOldCreditLimit	 		= @pnOldCreditLimit


End

Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateIPName to public
GO