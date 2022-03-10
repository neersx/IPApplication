-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateBillingInstructions
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateBillingInstructions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateBillingInstructions.'
	Drop procedure [dbo].[naw_UpdateBillingInstructions]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateBillingInstructions...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_UpdateBillingInstructions
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura			bit		= 0,
	@pnNameKey				int,		 -- Mandatory

	@psPurchaseOrderNo			nvarchar(80)	= null,
	@psTaxCode				nvarchar(3)	= null,
	@psStateTaxCode				nvarchar(3)	= null,
	@psStateCode				nvarchar(20)	= null,
	@pnCreditLimit				decimal(12,2)	= null,
	@pnDebtorRestrictionKey			smallint	= null,
	@pnDebitCopies				int		= null,
	@pbHasMultiCaseBills			bit		= 0,
	@pbHasMultiCaseBillsPerOwner		bit		= 0,
	@pbHasSameAddressAndAttention		bit		= 0,
	@psTaxNumber				nvarchar(30)	= null,
	@psBillCurrencyCode			nvarchar(3)	= null,
	@pnBillingFrequencyCode			int		= null,
	@pnReceivableTermsDays			int		= null,
	@pbIsLocalClient			bit		= null,
	@pnDebtorTypeCode			int		= null,
	@pnUseDebtorTypeCode			int		= null,
	@pnExchangeRateScheduleKey		int		= null,
	@pnStatementAttentionKey		int		= null,
	@psStatementAttention			nvarchar(254)	= null,
	@pnStatementNameKey			int		= null,
	@psStatementName			nvarchar(254)	= null,
	@pnStatementSequence			int		= null,
	@pnStatementAddressKey			int		= null,
	@pnBillingAttentionKey			int		= null,
	@psBillingAttention			nvarchar(254)	= null,
	@pnBillingNameKey			int		= null,
	@psBillingName				nvarchar(254)	= null,
	@pnBillingSequence			int		= null,
	@pnBillingAddressKey			int		= null,
	@pnBillingCap				decimal(12,2)	= null,
	@pnBillingCapPeriod			int		= null,
	@pnBillingCapPeriodType			nvarchar(1)	= null,
	@pdBillingCapStartDate			datetime	= null,
	@pbBillingCapResetFlag			bit		= null,
	@pnBillFormatProfileKey			int		= null,
	@pbSeparateMarginFlag			bit		= 0,
	@pnBillMapProfileKey			int		= null,

	@psOldPurchaseOrderNo			nvarchar(80)	= null,
	@psOldTaxCode				nvarchar(3)	= null,
	@psOldStateTaxCode			nvarchar(3)	= null,
	@psOldStateCode				nvarchar(20)	= null,
	@pnOldCreditLimit			decimal(12,2)	= null,
	@pnOldDebtorRestrictionKey		smallint	= null,
	@pnOldDebitCopies			int		= null,
	@pbOldHasMultiCaseBills			bit		= 0,
	@pbOldHasMultiCaseBillsPerOwner		bit		= 0,
	@pbOldHasSameAddressAndAttention	bit		= 0,
	@psOldTaxNumber				nvarchar(30)	= null,
	@psOldBillCurrencyCode			nvarchar(3)	= null,
	@pnOldBillingFrequencyCode		int		= null,
	@pnOldReceivableTermsDays		int		= null,
	@pbOldIsLocalClient			decimal(1,0)	= 0,
	@pnOldDebtorTypeCode			int		= null,
	@pnOldUseDebtorTypeCode			int		= null,
	@pnOldExchangeRateScheduleKey		int		= null,
	@pnOldStatementAttentionKey		int		= null,
	@psOldStatementAttention		nvarchar(254)	= null,
	@pnOldStatementNameKey			int		= null,
	@psOldStatementName			nvarchar(254)	= null,
	@pnOldStatementSequence			int		= null,
	@pnOldStatementAddressKey		int		= null,
	@pnOldBillingAttentionKey		int		= null,
	@psOldBillingAttention			nvarchar(254)	= null,
	@pnOldBillingNameKey			int		= null,
	@psOldBillingName			nvarchar(254)	= null,
	@pnOldBillingSequence			int		= null,
	@pnOldBillingAddressKey			int		= null,
	@pnOldBillingCap			decimal(12,2)	= null,
	@pnOldBillingCapPeriod			int		= null,
	@pnOldBillingCapPeriodType		nvarchar(1)	= null,
	@pdOldBillingCapStartDate		datetime	= null,
	@pbOldBillingCapResetFlag		bit		= null,
	@pnOldBillFormatProfileKey		int		= null,
	@pbOldSeparateMarginFlag		bit		= 0,
	@pnOldBillMapProfileKey			int		= null
)
as
-- PROCEDURE:	naw_UpdateBillingInstructions
-- VERSION:	7
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update Name Billing Instructions

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 25 Aug 2009	MS	RFC8288	1	Procedure created
-- 16 Oct 2009  LP      RFC8540 2       Fix concurrency check for CONSOLIDATION column if NULL  
-- 03 Feb 2010	MS	RFC7274	3	Billing Cap and Billing Cap period fields added
-- 17 Mar 2010	MS	RFC7280	4	Bill Format Profile field added
-- 23 Jun 2010	MS	RFC7269	5	Added SepearteMarginFlag column in Update
-- 30 Jun 2010	MS	RFC7274	6	Billing Cap Start Date and Reset flag fields added
-- 09 Jul 2010	AT	RFC7278	7	Added Bill Map Profile

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode			int
Declare @sSQLString 			nvarchar(4000)
Declare @nConsolidation			tinyint
Declare @nOldConsolidation		tinyint
Declare @pnSequence			int
Declare @pnAddressKey			int
Declare @pnAttentionKey			int
Declare @IsMainContactAsAttention	bit

-- Initialise variables
Set @nErrorCode 	= 0
Set @nConsolidation 	= 0
Set @nOldConsolidation 	= 0
Set @pnSequence		= 0

If @nErrorCode = 0
Begin
	Set @nConsolidation = @nConsolidation| ISNULL(@pbHasMultiCaseBills,0)|(2*ISNULL(@pbHasMultiCaseBillsPerOwner,0))|
		(4*ISNULL(@pbHasSameAddressAndAttention,0))
		
	Set @nOldConsolidation = @nOldConsolidation| ISNULL(@pbOldHasMultiCaseBills,0)|(2*ISNULL(@pbOldHasMultiCaseBillsPerOwner,0))|
		(4*ISNULL(@pbOldHasSameAddressAndAttention,0))
	
	Set @sSQLString = "Update IPNAME
			   set 	TAXCODE			= @psTaxCode,				
				PURCHASEORDERNO		= @psPurchaseOrderNo,				
				STATETAXCODE		= @psStateTaxCode,
				LOCALCLIENTFLAG		= @pbIsLocalClient,
				SERVPERFORMEDIN		= @psStateCode,
				BADDEBTOR		= @pnDebtorRestrictionKey,
				CURRENCY		= @psBillCurrencyCode,
				DEBITCOPIES		= @pnDebitCopies,
				DEBTORTYPE		= @pnDebtorTypeCode,
				USEDEBTORTYPE		= @pnUseDebtorTypeCode,
				CONSOLIDATION		= @pnConsolidation,
				CREDITLIMIT		= @pnCreditLimit,
				BILLINGFREQUENCY	= @pnBillingFrequencyCode,
				TRADINGTERMS		= @pnReceivableTermsDays,
				EXCHSCHEDULEID		= @pnExchangeRateScheduleKey,
				BILLINGCAP		= @pnBillingCap,
				BILLINGCAPPERIOD	= @pnBillingCapPeriod,
				BILLINGCAPPERIODTYPE	= @pnBillingCapPeriodType,
				BILLINGCAPSTARTDATE	= @pdBillingCapStartDate,
				BILLINGCAPRESETFLAG	= @pbBillingCapResetFlag,
				BILLFORMATID		= @pnBillFormatProfileKey,
				BILLMAPPROFILEID	= @pnBillMapProfileKey,
				SEPARATEMARGINFLAG	= @pbSeparateMarginFlag
			where 
				NAMENO			= @pnNameKey 
				and TAXCODE		= @psOldTaxCode				
				and STATETAXCODE	= @psOldStateTaxCode
				and PURCHASEORDERNO	= @psOldPurchaseOrderNo
				and LOCALCLIENTFLAG	= @pbOldIsLocalClient
				and SERVPERFORMEDIN	= @psOldStateCode
				and BADDEBTOR		= @pnOldDebtorRestrictionKey
				and CURRENCY		= @psOldBillCurrencyCode
				and DEBITCOPIES		= @pnOldDebitCopies
				and DEBTORTYPE		= @pnOldDebtorTypeCode
				and USEDEBTORTYPE	= @pnOldUseDebtorTypeCode
				and (CONSOLIDATION	= @pnOldConsolidation or CONSOLIDATION IS NULL)
				and CREDITLIMIT		= @pnOldCreditLimit
				and BILLINGFREQUENCY	= @pnOldBillingFrequencyCode
				and TRADINGTERMS	= @pnOldReceivableTermsDays
				and EXCHSCHEDULEID	= @pnOldExchangeRateScheduleKey
				and BILLINGCAP		= @pnOldBillingCap
				and BILLINGCAPPERIOD	= @pnOldBillingCapPeriod
				and BILLINGCAPPERIODTYPE = @pnOldBillingCapPeriodType
				and BILLINGCAPSTARTDATE	= @pdOldBillingCapStartDate
				and BILLINGCAPRESETFLAG	= @pbOldBillingCapResetFlag
				and BILLFORMATID	= @pnOldBillFormatProfileKey
				and BILLMAPPROFILEID	= @pnOldBillMapProfileKey
				and SEPARATEMARGINFLAG	= @pbOldSeparateMarginFlag"				

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnNameKey				int,
			@psTaxCode				nvarchar(3),
			@psStateTaxCode				nvarchar(3),
			@psStateCode				nvarchar(20),
			@pnDebtorRestrictionKey			smallint,
			@psBillCurrencyCode			nvarchar(3),
			@pnDebitCopies				smallint,
			@pnConsolidation			tinyint,
			@pnDebtorTypeCode			int,
			@pnUseDebtorTypeCode			int,
			@psPurchaseOrderNo			nvarchar(80),
			@pbIsLocalClient			bit,
			@pnReceivableTermsDays			int,
			@pnBillingFrequencyCode			int,
			@pnCreditLimit				decimal(12,2),
			@pnExchangeRateScheduleKey		int,
			@pnBillingCap				decimal(12,2),
			@pnBillingCapPeriod			int,
			@pnBillingCapPeriodType			nvarchar(1),
			@pdBillingCapStartDate			datetime,
			@pbBillingCapResetFlag			bit,
			@pnBillFormatProfileKey			int,
			@pnBillMapProfileKey			int,
			@pbSeparateMarginFlag			bit,
			@psOldTaxCode				nvarchar(3),
			@psOldStateTaxCode			nvarchar(3),
			@psOldStateCode				nvarchar(20),
			@pnOldDebtorRestrictionKey		smallint,
			@psOldBillCurrencyCode			nvarchar(3),
			@pnOldDebitCopies			smallint,
			@pnOldConsolidation			tinyint,
			@pnOldDebtorTypeCode			int,
			@pnOldUseDebtorTypeCode			int,
			@psOldPurchaseOrderNo			nvarchar(80),
			@pbOldIsLocalClient			bit,
			@pnOldReceivableTermsDays		int,
			@pnOldBillingFrequencyCode		int,
			@pnOldCreditLimit			decimal(12,2),
			@pnOldExchangeRateScheduleKey		int,
			@pnOldBillingCap			decimal(12,2),
			@pnOldBillingCapPeriod			int,
			@pnOldBillingCapPeriodType		nvarchar(1),
			@pdOldBillingCapStartDate		datetime,
			@pbOldBillingCapResetFlag		bit,
			@pnOldBillFormatProfileKey		int,
			@pnOldBillMapProfileKey			int,
			@pbOldSeparateMarginFlag		bit',
			@pnNameKey	 			= @pnNameKey,
			@psTaxCode	 			= @psTaxCode,
			@psStateTaxCode	 			= @psStateTaxCode,
			@psStateCode				= @psStateCode,
			@pnDebtorRestrictionKey	 		= @pnDebtorRestrictionKey,
			@psBillCurrencyCode	 		= @psBillCurrencyCode,
			@pnDebitCopies	 			= @pnDebitCopies,
			@pnConsolidation 			= @nConsolidation,
			@pnDebtorTypeCode	 		= @pnDebtorTypeCode,
			@pnUseDebtorTypeCode	 		= @pnUseDebtorTypeCode,
			@psPurchaseOrderNo	 		= @psPurchaseOrderNo,
			@pbIsLocalClient	 		= @pbIsLocalClient,
			@pnReceivableTermsDays	 		= @pnReceivableTermsDays,
			@pnBillingFrequencyCode	 		= @pnBillingFrequencyCode,
			@pnCreditLimit	 			= @pnCreditLimit,
			@pnExchangeRateScheduleKey		= @pnExchangeRateScheduleKey,
			@pnBillingCap				= @pnBillingCap,
			@pnBillingCapPeriod			= @pnBillingCapPeriod,
			@pnBillingCapPeriodType			= @pnBillingCapPeriodType,
			@pdBillingCapStartDate			= @pdBillingCapStartDate,
			@pbBillingCapResetFlag			= @pbBillingCapResetFlag,
			@pnBillFormatProfileKey			= @pnBillFormatProfileKey,
			@pnBillMapProfileKey			= @pnBillMapProfileKey,
			@pbSeparateMarginFlag			= @pbSeparateMarginFlag,
			@psOldTaxCode	 			= @psOldTaxCode,
			@psOldStateTaxCode	 		= @psOldStateTaxCode,
			@psOldStateCode				= @psOldStateCode,
			@pnOldDebtorRestrictionKey	 	= @pnOldDebtorRestrictionKey,
			@psOldBillCurrencyCode	 		= @psOldBillCurrencyCode,
			@pnOldDebitCopies	 		= @pnOldDebitCopies,
			@pnOldConsolidation 			= @nOldConsolidation,
			@pnOldDebtorTypeCode	 		= @pnOldDebtorTypeCode,
			@pnOldUseDebtorTypeCode	 		= @pnOldUseDebtorTypeCode,
			@psOldPurchaseOrderNo	 		= @psOldPurchaseOrderNo,
			@pbOldIsLocalClient	 		= @pbOldIsLocalClient,
			@pnOldReceivableTermsDays	 	= @pnOldReceivableTermsDays,
			@pnOldBillingFrequencyCode	 	= @pnOldBillingFrequencyCode,
			@pnOldCreditLimit	 		= @pnOldCreditLimit,
			@pnOldExchangeRateScheduleKey		= @pnOldExchangeRateScheduleKey,
			@pnOldBillingCap			= @pnOldBillingCap,
			@pnOldBillingCapPeriod			= @pnOldBillingCapPeriod,
			@pnOldBillingCapPeriodType		= @pnOldBillingCapPeriodType,
			@pdOldBillingCapStartDate		= @pdOldBillingCapStartDate,
			@pbOldBillingCapResetFlag		= @pbOldBillingCapResetFlag,
			@pnOldBillFormatProfileKey		= @pnOldBillFormatProfileKey,
			@pnOldBillMapProfileKey			= @pnOldBillMapProfileKey,
			@pbOldSeparateMarginFlag		= @pbOldSeparateMarginFlag
	
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "Update NAME
			  set 	 TAXNO	= @psTaxNumber
			  Where  NAMENO	= @pnNameKey  
			  and	TAXNO = @psOldTaxNumber"	
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'@psTaxNumber	nvarchar(30),
			@psOldTaxNumber nvarchar(30),
			@pnNameKey	int',
			@psTaxNumber	= @psTaxNumber,
			@psOldTaxNumber	= @psOldTaxNumber,
			@pnNameKey	= @pnNameKey
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select @pnAddressKey = POSTALADDRESS, 
				@pnAttentionKey = MAINCONTACT
			From NAME
			Where NAMENO = @pnNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnAddressKey	int output,
			@pnAttentionKey	int output,
			@pnNameKey	int',
			@pnAddressKey	= @pnAddressKey output,
			@pnAttentionKey	= @pnAttentionKey output,
			@pnNameKey	= @pnNameKey
End

If @nErrorCode = 0
Begin
	Select @IsMainContactAsAttention = COLBOOLEAN
	FROM SITECONTROL 
	WHERE CONTROLID like 'Main Contact used as Attention'
End

-- Send Bills To 
If @nErrorCode = 0
Begin
	If @pnBillingNameKey <> @pnOldBillingNameKey or 
	@pnBillingAddressKey <> @pnOldBillingAddressKey
	or @pnBillingAttentionKey <> @pnOldBillingAttentionKey
	Begin
		-- If Billing name or address or contact different from the default then update or insert
		-- the new record otherwise delete the record.
		If @pnBillingNameKey <> @pnNameKey or @pnBillingAttentionKey <> @pnAttentionKey 
		or (@pnBillingAddressKey <> @pnAddressKey and @pnBillingAddressKey is not null)
		Begin
			If exists (Select 1 from ASSOCIATEDNAME where NAMENO = @pnNameKey and RELATIONSHIP = 'BIL' and 
				RELATEDNAME = @pnOldBillingNameKey and SEQUENCE = @pnOldBillingSequence)
			Begin					
				exec @nErrorCode = naw_UpdateAssociatedName
					@pnUserIdentityId		= @pnUserIdentityId,
					@psCulture			= @psCulture,
					@pbCalledFromCentura		= @pbCalledFromCentura,
					@pnNameKey			= @pnNameKey,
					@pnAssociatedNameKey		= @pnBillingNameKey,
					@pnAttentionKey			= @pnBillingAttentionKey,
					@pnPostalAddressKey		= @pnBillingAddressKey,
					@psRelationshipCode		= 'BIL',
					@pnSequence			= 0,	
					@pbIsReverse			= 0,
					@pnOldAssociatedNameKey		= @pnOldBillingNameKey,	
					@pnOldAttentionKey		= @pnOldBillingAttentionKey,	
					@pnOldPostalAddressKey		= @pnOldBillingAddressKey,		
					@psOldRelationshipCode		= 'BIL',
					@pbOldIsReverse			= 0,
					@pbIsRelationshipCodeInUse	= 1,
					@pbIsAssociatedNameKeyInUse	= 1,
					@pbIsAttentionKeyInUse		= 1,
					@pbIsPostalAddressKeyInUse	= 1	

				-- If Attention is changed, call cs_RecalculateDerivedAttention for recalculating 
				-- the Derived Attention
				If @nErrorCode = 0 and @IsMainContactAsAttention  = 0 and 
					@pnBillingAttentionKey <> @pnOldBillingAttentionKey
				Begin
					Exec @nErrorCode = dbo.cs_RecalculateDerivedAttention
						@pnMainNameKey 		= @pnBillingNameKey,
						@pnOldAttentionKey	= null,
						@pnNewAttentionKey	= @pnBillingAttentionKey,
						@pnAssociatedNameKey	= @pnNameKey,
						@psAssociatedRelation	= 'BIL',
						@pnAssociatedSequence	= 0							
					
				End
			End
			Else 
			Begin					
				exec @nErrorCode = naw_InsertAssociatedName
					@pnUserIdentityId		= @pnUserIdentityId,
					@psCulture			= @psCulture,
					@pbCalledFromCentura		= @pbCalledFromCentura,
					@pnNameKey			= @pnNameKey,
					@pnAssociatedNameKey		= @pnBillingNameKey,
					@pnAttentionKey			= @pnBillingAttentionKey,
					@pnPostalAddressKey		= @pnBillingAddressKey,
					@psRelationshipCode		= 'BIL',
					@pnSequence			= @pnSequence output,	
					@pbIsAttentionKeyInUse		= 1,
					@pbIsPostalAddressKeyInUse	= 1
			End
		End
		Else
		Begin			
			exec @nErrorCode = naw_DeleteAssociatedName
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@pbCalledFromCentura	= @pbCalledFromCentura,
			@pnNameKey		= @pnNameKey,
			@psRelationshipCode	= 'BIL',			
			@pnAssociatedNameKey	= @pnOldBillingNameKey,
			@pnSequence		= @pnOldBillingSequence	

			-- If Old Attention is not null, call cs_RecalculateDerivedAttention for recalculating 
				-- the Derived Attention
			If @nErrorCode = 0 and @IsMainContactAsAttention  = 0 and
				@pnOldBillingAttentionKey is not null
			Begin
				Exec @nErrorCode = dbo.cs_RecalculateDerivedAttention
					@pnMainNameKey 		= @pnBillingNameKey,
					@pnOldAttentionKey	= null,
					@pnNewAttentionKey	= null,
					@pnAssociatedNameKey	= @pnNameKey,
					@psAssociatedRelation	= 'BIL',
					@pnAssociatedSequence	= 0
			End
		End			
			
	End
End

-- Send Statement To 
If @nErrorCode = 0
Begin
	If @pnStatementNameKey <> @pnOldStatementNameKey or 
	@pnStatementAddressKey <> @pnOldStatementAddressKey
	or @pnStatementAttentionKey <> @pnOldStatementAttentionKey
	Begin
		-- If Statement name or address or contact different from the default then update or insert
		-- the new record otherwise delete the record.
		If @pnStatementNameKey <> @pnNameKey or @pnStatementAttentionKey <> @pnAttentionKey 
		or (@pnStatementAddressKey <> @pnAddressKey and @pnStatementAddressKey is not null)
		Begin
			If exists (Select 1 from ASSOCIATEDNAME where NAMENO = @pnNameKey and RELATIONSHIP = 'STM' and 
				RELATEDNAME = @pnOldStatementNameKey and SEQUENCE = @pnOldStatementSequence)
			Begin
				exec @nErrorCode = naw_UpdateAssociatedName
					@pnUserIdentityId		= @pnUserIdentityId,
					@psCulture			= @psCulture,
					@pbCalledFromCentura		= @pbCalledFromCentura,
					@pnNameKey			= @pnNameKey,
					@pnAssociatedNameKey		= @pnStatementNameKey,
					@pnAttentionKey			= @pnStatementAttentionKey,
					@pnPostalAddressKey		= @pnStatementAddressKey,
					@psRelationshipCode		= 'STM',
					@pnSequence			= 0,	
					@pbIsReverse			= 0,
					@pnOldAssociatedNameKey		= @pnOldStatementNameKey,	
					@pnOldAttentionKey		= @pnOldStatementAttentionKey,	
					@pnOldPostalAddressKey		= @pnOldStatementAddressKey,		
					@psOldRelationshipCode		= 'STM',
					@pbOldIsReverse			= 0,
					@pbIsRelationshipCodeInUse	= 1,
					@pbIsAssociatedNameKeyInUse	= 1,
					@pbIsAttentionKeyInUse		= 1,
					@pbIsPostalAddressKeyInUse	= 1	

				-- If Attention is changed, call cs_RecalculateDerivedAttention for recalculating 
				-- the Derived Attention
				If @nErrorCode=0 and @IsMainContactAsAttention  = 0 and 
					@pnStatementAttentionKey <> @pnOldStatementAttentionKey
				Begin
					Exec @nErrorCode = dbo.cs_RecalculateDerivedAttention
						@pnMainNameKey 		= @pnStatementNameKey,
						@pnOldAttentionKey	= null,
						@pnNewAttentionKey	= @pnStatementAttentionKey,
						@pnAssociatedNameKey	= @pnNameKey,
						@psAssociatedRelation	= 'STM',
						@pnAssociatedSequence	= 0							
					
				End			
			End
			Else 
			Begin
				exec @nErrorCode = naw_InsertAssociatedName
					@pnUserIdentityId		= @pnUserIdentityId,
					@psCulture			= @psCulture,
					@pbCalledFromCentura		= @pbCalledFromCentura,
					@pnNameKey			= @pnNameKey,
					@pnAssociatedNameKey		= @pnStatementNameKey,
					@pnAttentionKey			= @pnStatementAttentionKey,
					@pnPostalAddressKey		= @pnStatementAddressKey,
					@psRelationshipCode		= 'STM',
					@pnSequence			= @pnSequence output,	
					@pbIsAttentionKeyInUse		= 1,
					@pbIsPostalAddressKeyInUse	= 1
			End
		End
		Else
		Begin
			exec @nErrorCode = naw_DeleteAssociatedName
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@pbCalledFromCentura	= @pbCalledFromCentura,
			@pnNameKey		= @pnNameKey,
			@psRelationshipCode	= 'STM',			
			@pnAssociatedNameKey	= @pnOldStatementNameKey,
			@pnSequence		= @pnOldStatementSequence	

			-- If Old Attention is not null, call cs_RecalculateDerivedAttention for recalculating 
				-- the Derived Attention
			If @nErrorCode = 0 and @IsMainContactAsAttention  = 0 and
				@pnOldStatementAttentionKey is not null
			Begin
				Exec @nErrorCode = dbo.cs_RecalculateDerivedAttention
					@pnMainNameKey 		= @pnStatementNameKey,
					@pnOldAttentionKey	= null,
					@pnNewAttentionKey	= null,
					@pnAssociatedNameKey	= @pnNameKey,
					@psAssociatedRelation	= 'STM',
					@pnAssociatedSequence	= 0
			End
		End
	End
End



Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateBillingInstructions to public
GO
