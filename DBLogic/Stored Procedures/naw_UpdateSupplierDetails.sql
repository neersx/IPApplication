-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateSupplierDetails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateSupplierDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateSupplierDetails.'
	Drop procedure [dbo].[naw_UpdateSupplierDetails]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateSupplierDetails...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_UpdateSupplierDetails
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura			bit		= 0,
	@pnNameKey				int,		-- Mandatory
	@pnSupplierTypeKey			int,            -- Mandatory
	@psPurchaseDesc				nvarchar(254)	= null,
	@psPurchaseCurrencyCode		        nvarchar(3)	= null,
	@psDefaultTaxCode			nvarchar(3)     = null,
	@pnTaxTreatmentCode			int             = null,
	@pnPaymentTermNo			int             = null,
	@psChequePayee				nvarchar(254)   = null,
	@psInstructionDesc			nvarchar(254)   = null		,
	@pnExpenseAccountKey			int             = null,
	@psProfitCentreCode			nvarchar(6)     = null,
	@pnPaymentMethodCode		        int             = null,
	@pnRestrictionCode		        int             = null,
	@psRestrictionReasonCode	        nvarchar(2)     = null,
	@psDisbWIPCode                          nvarchar(254)   = null,
	@psExchScheduleIdCode		        int             = null,	
	@pnPaymentAttentionKey		        int		= null,
	@pnPaymentNameKey			int		= null,
	@pnPaymentAddressKey		        int		= null,
        @pnPayToBankAccountOwner                int             = null,
        @pnPayToBankNameNo                      int             = null,
        @pnPayToBankAccountSeq                  int             = null,
        @pnOldPaymentAttentionKey		int		= null,
	@pnOldPaymentNameKey			int		= null,
        @pnOldPaymentSequence                   int             = null,
	@pnOldPaymentAddressKey		        int		= null,
        @pdLogDateTimeStamp		        datetime        = null
)
as
-- PROCEDURE:	naw_UpdateSupplierDetails
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update Supplier Details

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 12 May 2011	MS	RFC7998	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode			int
Declare @sSQLString 			nvarchar(4000)
Declare @nSequence			int
Declare @nAddressKey			int
Declare @nAttentionKey			int
Declare @IsMainContactAsAttention	bit

-- Initialise variables
Set @nErrorCode 	= 0
Set @nSequence		= 0

If @nErrorCode = 0
Begin
	
	Set @sSQLString = "UPDATE CREDITOR
			   SET 	SUPPLIERTYPE            = @pnSupplierTypeKey,
				PURCHASECURRENCY        = @psPurchaseCurrencyCode,
				DEFAULTTAXCODE          = @psDefaultTaxCode,
				TAXTREATMENT            = @pnTaxTreatmentCode,
				PAYMENTTERMNO           = @pnPaymentTermNo,
				CHEQUEPAYEE             = @psChequePayee,
				INSTRUCTIONS            = @psInstructionDesc,
				EXPENSEACCOUNT          = @pnExpenseAccountKey,
				PROFITCENTRE            = @psProfitCentreCode,
				PAYMENTMETHOD           = @pnPaymentMethodCode,
				RESTRICTIONID           = @pnRestrictionCode,
				RESTNREASONCODE         = @psRestrictionReasonCode,
				PURCHASEDESC            = @psPurchaseDesc,
				DISBWIPCODE             = @psDisbWIPCode,
				EXCHSCHEDULEID          = @psExchScheduleIdCode,
                                BANKACCOUNTOWNER        = @pnPayToBankAccountOwner,
                                BANKNAMENO              = @pnPayToBankNameNo,
                                BANKSEQUENCENO          = @pnPayToBankAccountSeq                                
			where 
				NAMENO		 = @pnNameKey
                                and ((LOGDATETIMESTAMP = @pdLogDateTimeStamp) or
                                     (@pdLogDateTimeStamp is null and LOGDATETIMESTAMP is null))"				

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnNameKey				int,
			  @pnSupplierTypeKey			int,
			  @psPurchaseDesc			nvarchar(254),
			  @psPurchaseCurrencyCode		nvarchar(3),
			  @psDefaultTaxCode			nvarchar(3),
			  @pnTaxTreatmentCode			int ,
			  @pnPaymentTermNo			int,
			  @psChequePayee			nvarchar(254),
			  @psInstructionDesc			nvarchar(254),
			  @pnExpenseAccountKey			int,
			  @psProfitCentreCode			nvarchar(6),
			  @pnPaymentMethodCode			int,
			  @pnRestrictionCode			int,
			  @psRestrictionReasonCode		nvarchar(2),
			  @psDisbWIPCode			nvarchar(254),
			  @psExchScheduleIdCode			int,
                          @pnPayToBankAccountOwner              int,
                          @pnPayToBankNameNo                    int,
                          @pnPayToBankAccountSeq                int,
                          @pdLogDateTimeStamp		        datetime',
			  @pnNameKey	 			= @pnNameKey,
			  @pnSupplierTypeKey		        = @pnSupplierTypeKey,
			  @psPurchaseCurrencyCode               = @psPurchaseCurrencyCode,
			  @psDefaultTaxCode                     = @psDefaultTaxCode,
			  @pnTaxTreatmentCode                   = @pnTaxTreatmentCode,
			  @pnPaymentTermNo                      = @pnPaymentTermNo,
			  @psChequePayee                        = @psChequePayee,
			  @psInstructionDesc                    = @psInstructionDesc,
			  @pnExpenseAccountKey                  = @pnExpenseAccountKey,
			  @psProfitCentreCode                   = @psProfitCentreCode,
			  @pnPaymentMethodCode                  = @pnPaymentMethodCode,
			  @pnRestrictionCode                    = @pnRestrictionCode,
			  @psRestrictionReasonCode              = @psRestrictionReasonCode,
			  @psPurchaseDesc                       = @psPurchaseDesc,
			  @psDisbWIPCode                        = @psDisbWIPCode,
			  @psExchScheduleIdCode                 = @psExchScheduleIdCode,
                          @pnPayToBankAccountOwner              = @pnPayToBankAccountOwner,
                          @pnPayToBankNameNo                    = @pnPayToBankNameNo,
                          @pnPayToBankAccountSeq                = @pnPayToBankAccountSeq,
			  @pdLogDateTimeStamp                   = @pdLogDateTimeStamp	
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select @nAddressKey = POSTALADDRESS, 
				@nAttentionKey = MAINCONTACT
			From NAME
			Where NAMENO = @pnNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@nAddressKey	int output,
			@nAttentionKey	int output,
			@pnNameKey	int',
			@nAddressKey	= @nAddressKey output,
			@nAttentionKey	= @nAttentionKey output,
			@pnNameKey	= @pnNameKey
End

If @nErrorCode = 0
Begin
	Select @IsMainContactAsAttention = COLBOOLEAN
	FROM SITECONTROL 
	WHERE CONTROLID like 'Main Contact used as Attention'
End


-- Send Payments To 
If @nErrorCode = 0
Begin
	If @pnPaymentNameKey <> @pnOldPaymentNameKey or 
	@pnPaymentAddressKey <> @pnOldPaymentAddressKey
	or @pnPaymentAttentionKey <> @pnOldPaymentAttentionKey
	Begin
		-- If Payment name or address or contact different from the default then update or insert
		-- the new record otherwise delete the record.
		If @pnPaymentNameKey <> @pnNameKey or @pnPaymentAttentionKey <> @nAttentionKey 
		or (@pnPaymentAddressKey <> @nAddressKey and @pnPaymentAddressKey is not null)
		Begin
			If exists (Select 1 from ASSOCIATEDNAME where NAMENO = @pnNameKey and RELATIONSHIP = 'PAY' and 
				RELATEDNAME = @pnOldPaymentNameKey and SEQUENCE = @pnOldPaymentSequence)
			Begin					
				exec @nErrorCode = naw_UpdateAssociatedName
					@pnUserIdentityId		= @pnUserIdentityId,
					@psCulture			= @psCulture,
					@pbCalledFromCentura		= @pbCalledFromCentura,
					@pnNameKey			= @pnNameKey,
					@pnAssociatedNameKey		= @pnPaymentNameKey,
					@pnAttentionKey			= @pnPaymentAttentionKey,
					@pnPostalAddressKey		= @pnPaymentAddressKey,
					@psRelationshipCode		= 'PAY',
					@pnSequence			= 0,	
					@pbIsReverse			= 0,
					@pnOldAssociatedNameKey		= @pnOldPaymentNameKey,	
					@pnOldAttentionKey		= @pnOldPaymentAttentionKey,	
					@pnOldPostalAddressKey		= @pnOldPaymentAddressKey,		
					@psOldRelationshipCode		= 'PAY',
					@pbOldIsReverse			= 0,
					@pbIsRelationshipCodeInUse	= 1,
					@pbIsAssociatedNameKeyInUse	= 1,
					@pbIsAttentionKeyInUse		= 1,
					@pbIsPostalAddressKeyInUse	= 1	

				-- If Attention is changed, call cs_RecalculateDerivedAttention for recalculating 
				-- the Derived Attention
				If @nErrorCode = 0 and @IsMainContactAsAttention  = 0 and 
					@pnPaymentAttentionKey <> @pnOldPaymentAttentionKey
				Begin
					Exec @nErrorCode = dbo.cs_RecalculateDerivedAttention
						@pnMainNameKey 		= @pnPaymentNameKey,
						@pnOldAttentionKey	= null,
						@pnNewAttentionKey	= @pnPaymentAttentionKey,
						@pnAssociatedNameKey	= @pnNameKey,
						@psAssociatedRelation	= 'PAY',
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
					@pnAssociatedNameKey		= @pnPaymentNameKey,
					@pnAttentionKey			= @pnPaymentAttentionKey,
					@pnPostalAddressKey		= @pnPaymentAddressKey,
					@psRelationshipCode		= 'PAY',
					@pnSequence			= @nSequence output,	
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
			@psRelationshipCode	= 'PAY',			
			@pnAssociatedNameKey	= @pnOldPaymentNameKey,
			@pnSequence		= @pnOldPaymentSequence	

			-- If Old Attention is not null, call cs_RecalculateDerivedAttention for recalculating 
				-- the Derived Attention
			If @nErrorCode = 0 and @IsMainContactAsAttention  = 0 and
				@pnOldPaymentAttentionKey is not null
			Begin
				Exec @nErrorCode = dbo.cs_RecalculateDerivedAttention
					@pnMainNameKey 		= @pnPaymentNameKey,
					@pnOldAttentionKey	= null,
					@pnNewAttentionKey	= null,
					@pnAssociatedNameKey	= @pnNameKey,
					@psAssociatedRelation	= 'PAY',
					@pnAssociatedSequence	= 0
			End
		End			
			
	End
End

Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateSupplierDetails to public
GO
