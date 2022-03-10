-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_InsertSupplier									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_InsertSupplier]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_InsertSupplier.'
	Drop procedure [dbo].[naw_InsertSupplier]
End
Print '**** Creating Stored Procedure dbo.naw_InsertSupplier...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_InsertSupplier
(
	@pnUserIdentityId		        int,		        -- Mandatory
	@psCulture			        nvarchar(10) 	        = null,
	@pbCalledFromCentura		        bit		        = 0,
	@pnNameKey			        int,		        -- Mandatory.
	@pnSupplierTypeKey		        int                     = null,
        @psDefaultTaxTreatmentCode              nvarchar(3)             = null,
        @pnPurchaseTaxTreatmentCode             int                     = null,
        @psPurchaseCurrencyCode                 nvarchar(3)             = null,
        @pnPaymentTermsCode                     int                     = null,
        @psChequePayee                          nvarchar(254)           = null,
        @psInstructions                         nvarchar(254)           = null,
        @psExpenseAccountKey                    int                     = null,
        @pnProfitCentreCode                     nvarchar(6)             = null,
        @pnPaymentMethodCode                    int                     = null,
        @psBankName                             nvarchar(60)            = null,
        @psBankBranchNo                         nvarchar(10)            = null,  
        @psBankAccountNo                        nvarchar(20)            = null, 
        @psBankAccountName                      nvarchar(60)            = null,
        @pnBankAccountOwner                     int                     = null,
        @pnBankNameKey                          int                     = null,
        @pnBankSeqNo                            int                     = null,
        @pnRestrictionKey                       int                     = null,
        @psRestrictionReasonKey                 nvarchar(2)             = null,
        @psPurchaseDescription                  nvarchar(254)           = null,
        @psWIPDisbursementCode                  nvarchar(6)             = null,
        @pnExchangeRateScheduleCode             int                     = null, 
	@pbIsSupplierTypeKeyInUse	        bit		        = 0,
        @pbIsDefaultTaxTreatmentCodeInUse       bit                     = 0,
        @pbIsPurchaseTaxTreatmentCodeInUse      bit                     = 0,
        @pbIsPurchaseCurrencyCodeInUse          bit                     = 0,
        @pbIsPaymentTermsCodeInUse              bit                     = 0,
        @pbIsChequePayeeInUse                   bit                     = 0,
        @pbIsInstructionsInUse                  bit                     = 0,
        @pbIsExpenseAccountKeyInUse             bit                     = 0,
        @pbIsProfitCentreCodeInUse              bit                     = 0,
        @pbIsPaymentMethodCodeInUse             bit                     = 0,
        @pbIsBankNameInUse                      bit                     = 0,
        @pbIsBankBranchNoInUse                  bit                     = 0,  
        @pbIsBankAccountNoInUse                 bit                     = 0, 
        @pbIsBankAccountNameInUse               bit                     = 0,
        @pbIsBankAccountOwnerInUse              bit                     = 0,
        @pbIsBankNameKeyInUse                   bit                     = 0,
        @pbIsBankSeqNoInUse                     bit                     = 0,
        @pbIsRestrictionKeyInUse                bit                     = 0,
        @pbIsRestrictionReasonKeyInUse          bit                     = 0,
        @pbIsPurchaseDescriptionInUse           bit                     = 0,
        @pbIsWIPDisbursementCodeInUse           bit                     = 0,    
        @pbIsExchangeRateScheduleCodeInUse      bit                     = 0              
        
)
as
-- PROCEDURE:	naw_InsertSupplier
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert NameAddress.

-- MODIFICATIONS :
-- Date			Who   Change   Version   Description
-- ---------	----- -------  --------  --------------------------------------
-- 12 May 2011	MS    RFC7998  1		 Procedure created
-- 23 Aug 2017	KR	  R63137   2		 @psDefaultTaxTreatmentCode has been set to nvarchar(3) instead of int

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 		nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma			nchar(1)

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("


If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into CREDITOR ("

	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"NAMENO"

	Set @sValuesString = @sValuesString+CHAR(10)+"@pnNameKey"

	If @pbIsSupplierTypeKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"SUPPLIERTYPE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnSupplierTypeKey"		
	End

        If @pbIsDefaultTaxTreatmentCodeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"DEFAULTTAXCODE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psDefaultTaxTreatmentCode"		
	End

        If @pbIsPurchaseTaxTreatmentCodeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"TAXTREATMENT"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnPurchaseTaxTreatmentCode"		
	End

        If @pbIsPurchaseCurrencyCodeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PURCHASECURRENCY"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psPurchaseCurrencyCode"		
	End

        If @pbIsPaymentTermsCodeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PAYMENTTERMNO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnPaymentTermsCode"		
	End

        If @pbIsChequePayeeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CHEQUEPAYEE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psChequePayee"		
	End

        If @pbIsInstructionsInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"INSTRUCTIONS"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psInstructions"		
	End

        If @pbIsExpenseAccountKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"EXPENSEACCOUNT"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psExpenseAccountKey"		
	End
        
        If @pbIsProfitCentreCodeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PROFITCENTRE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnProfitCentreCode"		
	End

        If @pbIsPaymentMethodCodeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PAYMENTMETHOD"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnPaymentMethodCode"		
	End
        
        If @pbIsBankNameInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"BANKNAME"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psBankName"		
	End

        If @pbIsBankBranchNoInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"BANKBRANCHNO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psBankBranchNo"		
	End

        If @pbIsBankAccountNoInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"BANKACCOUNTNO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psBankAccountNo"		
	End

        If @pbIsBankAccountNameInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"BANKACCOUNTNAME"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psBankAccountName"		
	End

        If @pbIsBankAccountOwnerInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"BANKACCOUNTOWNER"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnBankAccountOwner"		
	End

        If @pbIsBankNameKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"BANKNAMENO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnBankNameKey"		
	End

        If @pbIsBankSeqNoInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"BANKSEQUENCENO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnBankSeqNo"		
	End

        If @pbIsRestrictionKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"RESTRICTIONID"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnRestrictionKey"		
	End

        If @pbIsRestrictionReasonKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"RESTNREASONCODE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psRestrictionReasonKey"		
	End

        If @pbIsPurchaseDescriptionInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PURCHASEDESC"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psPurchaseDescription"		
	End

        If @pbIsWIPDisbursementCodeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"DISBWIPCODE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psWIPDisbursementCode"		
	End

        If @pbIsExchangeRateScheduleCodeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"EXCHSCHEDULEID"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnExchangeRateScheduleCode"		
	End
	
	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

	exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@pnNameKey		        int,
				@pnSupplierTypeKey	        int,
                                @psDefaultTaxTreatmentCode      nvarchar(3),
                                @pnPurchaseTaxTreatmentCode     int,
                                @psPurchaseCurrencyCode         nvarchar(3),
                                @pnPaymentTermsCode             int,
                                @psChequePayee                  nvarchar(254),
                                @psInstructions                 nvarchar(254),
                                @psExpenseAccountKey            int,
                                @pnProfitCentreCode             nvarchar(3),
                                @pnPaymentMethodCode            int,
                                @psBankName                     nvarchar(60),
                                @psBankBranchNo                 nvarchar(10),
                                @psBankAccountNo                nvarchar(20),
                                @psBankAccountName              nvarchar(60),
                                @pnBankAccountOwner             int,
                                @pnBankNameKey                  int,
                                @pnBankSeqNo                    int,
                                @pnRestrictionKey               int,  
                                @psRestrictionReasonKey         nvarchar(2),
                                @psPurchaseDescription          nvarchar(254),
                                @psWIPDisbursementCode          nvarchar(6),
                                @pnExchangeRateScheduleCode     int',
				@pnNameKey		        = @pnNameKey,
				@pnSupplierTypeKey	        = @pnSupplierTypeKey,
                                @psDefaultTaxTreatmentCode      = @psDefaultTaxTreatmentCode,
                                @pnPurchaseTaxTreatmentCode     = @pnPurchaseTaxTreatmentCode,
                                @psPurchaseCurrencyCode         = @psPurchaseCurrencyCode,
                                @pnPaymentTermsCode             = @pnPaymentTermsCode,
                                @psChequePayee                  = @psChequePayee,
                                @psInstructions                 = @psInstructions,
                                @psExpenseAccountKey            = @psExpenseAccountKey,
                                @pnProfitCentreCode             = @pnProfitCentreCode,
                                @pnPaymentMethodCode            = @pnPaymentMethodCode,
                                @psBankName                     = @psBankName,
                                @psBankBranchNo                 = @psBankBranchNo,
                                @psBankAccountNo                = @psBankAccountNo,
                                @psBankAccountName              = @psBankAccountName,
                                @pnBankAccountOwner             = @pnBankAccountOwner,
                                @pnBankNameKey                  = @pnBankNameKey,
                                @pnBankSeqNo                    = @pnBankSeqNo,
                                @pnRestrictionKey               = @pnRestrictionKey,
                                @psRestrictionReasonKey         = @psRestrictionReasonKey,
                                @psPurchaseDescription          = @psPurchaseDescription,
                                @psWIPDisbursementCode          = @psWIPDisbursementCode,
                                @pnExchangeRateScheduleCode     = @pnExchangeRateScheduleCode

End


Return @nErrorCode
GO

Grant execute on dbo.naw_InsertSupplier to public
GO