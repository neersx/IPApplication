-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_DeleteIPName									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_DeleteIPName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_DeleteIPName.'
	Drop procedure [dbo].[naw_DeleteIPName]
End
Print '**** Creating Stored Procedure dbo.naw_DeleteIPName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_DeleteIPName
(
	@pnUserIdentityId				int,		-- Mandatory
	@psCulture					nvarchar(10) 	= null,
	@pbCalledFromCentura				bit		= 0,
	@pnNameKey					int,		-- Mandatory
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
-- PROCEDURE:	naw_DeleteIPName
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete IPName if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 13 Apr 2006	IB	RFC3763	1	Procedure created
-- 19 Mar 2008	vql	SQA14773 2      Make PurchaseOrderNo nvarchar(80)
-- 16 Feb 2012  MS      RFC11912 3      Add ISNULL before checking CONSOLIDATION with old value

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sDeleteString		nvarchar(4000)
Declare @sAnd			nchar(5)
Declare @nOldConsolidation	tinyint

-- Initialise variables
Set @nErrorCode 	= 0
Set @nOldConsolidation	= 0

If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from IPNAME
			   where "

	Set @sDeleteString = @sDeleteString+CHAR(10)+"
		NAMENO = @pnNameKey"

	Set @sAnd = " and "

	If @pbIsTaxCodeInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"TAXCODE = @psOldTaxCode"
	End

	If @pbIsDebtorRestrictionKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"BADDEBTOR = @pnOldDebtorRestrictionKey"
	End

	If @pbIsBillCurrencyCodeInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"CURRENCY = @psOldBillCurrencyCode"
	End

	If @pbIsDebitNoteCopiesInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"DEBITCOPIES = @pnOldDebitNoteCopies"
	End

	If @pbIsHasMultiCaseBillsInUse = 1
	or @pbIsHasMultiCaseBillsByOwnerInUse = 1
	Begin		
		If @pbOldHasMultiCaseBills is null
		Begin
			Set @pbOldHasMultiCaseBills = 0
		End
		If @pbOldHasMultiCaseBillsByOwner is null
		Begin
			Set @pbOldHasMultiCaseBillsByOwner = 0
		End
		Set @nOldConsolidation = @nOldConsolidation|@pbOldHasMultiCaseBills|(2*@pbOldHasMultiCaseBillsByOwner)

		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"ISNULL(CONSOLIDATION,0) = @pnOldConsolidation"
	End

	If @pbIsDebtorTypeKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"DEBTORTYPE = @pnOldDebtorTypeKey"
	End

	If @pbIsUseDebtorTypeKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"USEDEBTORTYPE = @pnOldUseDebtorTypeKey"
	End

	If @pbIsDefaultCorrespondenceInstructionsInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"CORRESPONDENCE = @psOldDefaultCorrespondenceInstructions"
	End

	If @pbIsCategoryKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"CATEGORY = @pnOldCategoryKey"
	End

	If @pbIsPurchaseOrderNoInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"PURCHASEORDERNO = @psOldPurchaseOrderNo"
	End

	If @pbIsIsLocalClientInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"LOCALCLIENTFLAG = @pbOldIsLocalClient"
	End

	If @pbIsAirportCodeInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"AIRPORTCODE = @psOldAirportCode"
	End

	If @pbIsReceivableTermsDaysInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"TRADINGTERMS = @pnOldReceivableTermsDays"
	End

	If @pbIsBillingFrequencyKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"BILLINGFREQUENCY = @pnOldBillingFrequencyKey"
	End

	If @pbIsCreditLimitInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"CREDITLIMIT = @pnOldCreditLimit"
	End

	exec @nErrorCode=sp_executesql @sDeleteString,
			      	N'
			@pnNameKey				int,
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

Grant execute on dbo.naw_DeleteIPName to public
GO

