-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wp_DOFEESCALC
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[wp_DOFEESCALC]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.wp_DOFEESCALC.'
	Drop procedure [dbo].[wp_DOFEESCALC]
End
Print '**** Creating Stored Procedure dbo.wp_DOFEESCALC...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE procedure dbo.wp_DOFEESCALC 
(
			@pnUserIdentityId	int,		-- Mandatory
			@psCulture		nvarchar(10) 	= null,	-- The language in which output is to be expressed.
			@psIRN 			nvarchar(30)	= null,	-- The reference of the case selected.
			@pnRateNo 		int,		-- The key of the Rate Calculation selected
			@psAction 		nvarchar(2)	= NULL,	
			@pnCheckListType 	smallint	= NULL, 
			@pnCycle 		smallint	= NULL, 
			@pnEventNo 		int		= NULL, 
			@pdtLetterDate 		datetime	= NULL, 
			@pnProductCode		int 		= NULL,
			@pnEnteredQuantity	int		= NULL, 
			@pnEnteredAmount	decimal(11,2)	= NULL, 
			@pnARQuantity		smallint	= NULL, 
			@pnARAmount		decimal(11,2)	= NULL,
			@pnDebtor		int		= NULL,
			@pbIsChargeGeneration	bit		= 1,
			@pdtTransactionDate	datetime	= NULL,
			@pdtBillDate		datetime	= NULL,
			@pbAgentItem		bit		= 0,
			@pbIsQtyAmtChange	bit		= 0,	-- 0 when called by onchange of Calculation picklist or Case.
									-- 1 when called by onchange functions of Quantity and Amount.
			@pbCalledFromCentura    bit		= 0,
			@pnEmployee		int		= NULL,
			@pnCaseKey		int		= null,
			@pbCalledFromBilling	bit = 0
)
as

-- PROCEDURE :	wp_DOFEESCALC
-- VERSION :	19
-- DESCRIPTION:	This is a wrapper stored procedure.  It has the same input parameters as 
-- 		FEESCALC stored procedure.  The main task of DOFEESCALC is to execute 
-- 		FEESCALC and then publish its output parameters.
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICTIONS :
-- Date         Who  	Number	Version Change
-- ------------ ---- 	------	------- ------------------------------------------- 
-- 18 Mar 2009	MS	RFC6478		1		Newly Created 
-- 30 Apr 2009	MS	RFC7873		2	DisbNarrativeText and ServNarrativeText are returned in the selection
-- 14 May 2009	MS	RFC7853		3	Handles the Defaulting of Amount and Quantity fields.
-- 28 Jul 2009	MS	RFC8233		4	Added @pnEmployee as new input parameter
-- 08 Feb 2010	MS	RFC7281		5	Check Exempt Charges for Rate Calculation
-- 23 Apr 2010	AT	RFC8292		6	Return data required for consolidation of draft WIP
-- 23 Jun 2010	MS	RFC7269		7	Added Discounts on Margin in Select
-- 15 Jun 2011  MS  RFC9878 	8       Modify the defaulting of Source and Quantity based on MinFeeFlag for Disbursement and Service fees
-- 13 Sep 2012  MS  R12737      9       Change NarrativeText data length to nvarchar(max)
-- 13 Sep 2012  MS  R12737		10       Change NarrativeText data length to nvarchar(max)
-- 12 Oct 2012	Dw	R12839		11	Fixed NarrativeText translation issue
-- 13 Sep 2013	LP	R25124		12	Added @pnCaseKey input parameter rename field names for better compatibility with calling code
-- 26 Sep 2013	LP	R25124		13	Do not concatenate WIPCode into WIPDescription field							
-- 20 Oct 2015  MS  R53933		14      Changed size from decimal(8,4) to decimal(11,4) for rate cols
-- 17 Dec 2015  DV	R56145		15	Return separate source type for disbursement and service fees
-- 04 Jan 2016  MS  R56172		16  Added premargin discounts for service fees and disbursments
-- 15 Dec 2017	LP	R60840		17	Return flags to enable Amount and Quantity fields independent of each other;
--									Enable Quantity field if fee uses an Alternate Stored Procedure for calculation
-- 04 Jan 2017	MS	R47798		18	Set DisbSourceType and ServSourceType when SourceType is quantity
-- 23 FEB 2017	AK	R47798		19	Set IsAllowAdvanceBillForDesb and IsAllowAdvanceBillForServ in resultset
-- 18 Sep 2019	SR	DR-50616 	20	'Exempt Charges' be changed to Debtor Name rather than the instructor Name

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int, 
	@sLookupCulture		nvarchar(10),
	@sSQLString		nvarchar(4000),
	@prsDisbCurrency 	varchar(3),
	@prnDisbExchRate 	decimal(11,4), 
	@prsServCurrency 	varchar(3),
	@prnServExchRate 	decimal(11,4), 
	@prsBillCurrency 	varchar(3),
	@prnBillExchRate 	decimal(11,4), 
	@prsDisbTaxCode 	varchar(3),
	@prsServTaxCode 	varchar(3), 
	@prnDisbNarrativeNo 	int,
	@prnServNarrativeNo 	int,
	@prsDisbNarrative	nvarchar(50), 
	@prsServNarrative	nvarchar(50),
	@prsDisbNarrativeText	nvarchar(max), 
	@prsServNarrativeText	nvarchar(max), 
	@prsDisbWIPCode 	varchar(6),
	@prsServWIPCode 	varchar(6), 
	@prsDisbWIPDescription 	nvarchar(40),
	@prsServWIPDescription 	nvarchar(40), 
	@prnDisbAmount 		decimal(11,2),
	@prnDisbHomeAmount 	decimal(11,2),
	@prnDisbBillAmount 	decimal(11,2), 
	@prnServAmount 		decimal(11,2), 
	@prnServHomeAmount 	decimal(11,2), 
	@prnServBillAmount	decimal(11,2), 
	@prnTotHomeDiscount 	decimal(11,2),
	@prnTotBillDiscount	decimal(11,2), 
	@prnDisbTaxAmt 		decimal(11,2),
	@prnDisbTaxHomeAmt 	decimal(11,2),
	@prnDisbTaxBillAmt 	decimal(11,2), 
	@prnServTaxAmt 		decimal(11,2),
	@prnServTaxHomeAmt 	decimal(11,2),
	@prnServTaxBillAmt 	decimal(11,2),
	@prnDisbDiscOriginal	decimal(11,2),
	@prnDisbHomeDiscount 	decimal(11,2),
	@prnDisbBillDiscount 	decimal(11,2),
	@prnServDiscOriginal	decimal(11,2),
	@prnServHomeDiscount 	decimal(11,2),
	@prnServBillDiscount 	decimal(11,2),
	@prnDisbCostHome	decimal(11,2),
	@prnDisbCostOriginal	decimal(11,2),
	@prnDisbBasicAmount		decimal(11,2),
	@prnDisbExtendedAmount 		decimal(11,2),
	@prnDisbCostCalculation1	decimal(11,2),
	@prnDisbCostCalculation2	decimal(11,2),
	@prnServBasicAmount		decimal(11,2),
	@prnServExtendedAmount 		decimal(11,2),
	@prnServCostCalculation1	decimal(11,2),
	@prnServCostCalculation2	decimal(11,2),
	@prnVarBasicAmount		decimal(11,2),
	@prnVarExtendedAmount 		decimal(11,2),
	@prnVariableFeeAmt		decimal(11,2),
	@prnVarHomeFeeAmt		decimal(11,2),
	@prnVarBillFeeAmt		decimal(11,2),
	@prnVarTaxAmt			decimal(11,2),
	@prnVarTaxHomeAmt		decimal(11,2),
	@prnVarTaxBillAmt		decimal(11,2),
	@prsVarWIPCode			nvarchar(6),
	@prsVarTaxCode 			nvarchar(3),
	@prnDisbMargin			decimal(11,2),
	@prnDisbHomeMargin		decimal(11,2),
	@prnDisbBillMargin		decimal(11,2),
	@prnServMargin			decimal(11,2),
	@prnServHomeMargin		decimal(11,2),
	@prnServBillMargin		decimal(11,2),
	@prnFeeCriteriaNo		int,
	@prnFeeUniqueId			int,
	@prnServCostOriginal		decimal(11,2),
	@prnServCostHome		decimal(11,2),
	@prsDisbStateTaxCode 	nvarchar(3), 
	@prsServStateTaxCode 	nvarchar(3), 
	@prsVarStateTaxCode 	nvarchar(3),
	@prnDisbStateTaxAmt 	decimal(11,2), 
	@prnDisbStateTaxHomeAmt decimal(11,2), 
	@prnDisbStateTaxBillAmt decimal(11,2), 
	@prnServStateTaxAmt 	decimal(11,2), 
	@prnServStateTaxHomeAmt decimal(11,2), 
	@prnServStateTaxBillAmt decimal(11,2), 
	@prnVarStateTaxAmt	decimal(11,2), 
	@prnVarStateTaxHomeAmt	decimal(11,2), 
	@prnVarStateTaxBillAmt	decimal(11,2),
	@prnDisbMarginNo	int,
	@prnServMarginNo	int,
	@prsFeeType		nvarchar(6),
	@prsFeeType2		nvarchar(6),
	@sLocalCurrencyCode	nvarchar(3),
	@nLocalDecimalPlaces 	tinyint,
	@prbIsFeeType		bit,
	@prbIsFeeType2		bit,

	@pnDisbQuantity		int,
	@pnServQuantity		int,
	@dDisbBaseFee		decimal(11,2), 
	@dServBaseFee		decimal(11,2), 
	@dDisbVarFee		decimal(11,2),
	@dServVarFee		decimal(11,2),
	@nDisbBaseUnits		smallint, 
	@nServBaseUnits		smallint,			  
	@nDisbUnitSize		smallint, 
	@nServUnitSize		smallint, 
	@dDisbAddPercentage	decimal(5,4), 
	@dServAddPercentage	decimal(5,4),
	@bDisbMinFeeFlag        bit,
        @bServMinFeeFlag        bit,
	@sSourceType		nchar(1),	-- Represents whether Quantity or Amount is used for calculation
						-- value could be 'A' - Amount, 'Q' - Quantity.
	@sDisbSourceType	nchar(1),
	@sServSourceType	nchar(1),
	@nDefaultQuantity	int,

	@prsDisbWIPTypeId		nvarchar(6),
	@prsDisbWIPCategory		nvarchar(3),
	@prnDisbWIPCategorySort		int,
	@prsServWIPTypeId		nvarchar(6),
	@prsServWIPCategory		nvarchar(3),
	@prnServWIPCategorySort		int,
	
	-- RFC7269
	@nDisbDiscountForMargin		decimal(11,2),
	@nDisbHomeDiscountForMargin	decimal(11,2),
	@nDisbBillDiscountForMargin	decimal(11,2),
	@nServDiscountForMargin		decimal(11,2),
	@nServHomeDiscountForMargin	decimal(11,2),
	@nServBillDiscountForMargin	decimal(11,2),

	-- RFC12839
	@sTransDisbNarrativeText	nvarchar(MAX), 
	@sTransServNarrativeText	nvarchar(MAX), 
	@bIsTranslateNarrative		bit,		-- If the Narrative Translate site control is on, the text is obtained in the language in which the bill will be raised. 
	@nLanguageKey			int,		-- The language in which the narrative should be displayed.
	@nDebtorKey			int,		
	@nCaseKey			int,		

	@sAlertXML		nvarchar(400),

        -- RFC56172
        @nDisbPreMarginDiscount	        decimal(11,2),
	@nDisbHomePreMarginDiscount	decimal(11,2),
	@nDisbBillPreMarginDiscount	decimal(11,2),
	@nServPreMarginDiscount	        decimal(11,2),
	@nServHomePreMarginDiscount	decimal(11,2),
	@nServBillPreMarginDiscount	decimal(11,2),

	@bQuantityRequired	bit,
	@bAmountRequired	bit,
	@prsDisbAllowAdvanceBill 	bit,
	@prsServAllowAdvanceBill 	bit
	
		
-- Initialise variables
Set @nErrorCode 	= 0
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @bQuantityRequired = 0
Set @bAmountRequired = 0

If @pdtLetterDate is NULL 
or @pdtLetterDate = ''
Begin
	Set @pdtLetterDate = getdate()
End

If @pdtTransactionDate is NULL 
or @pdtTransactionDate = ''
Begin
	Set @pdtTransactionDate = getdate()
End

If @psAction=''
	set @psAction = NULL

If @pdtBillDate=''
	set @pdtBillDate = NULL

-- Check if selected charge exist in Exempt charges for the debtor
If @nErrorCode=0 and exists (
		Select 1
        from CASES C
    left join CASENAME CN on (CN.CASEID = C.CASEID and CN.NAMETYPE = 'D'
            and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))
    left join CASENAME CNZ on (CNZ.CASEID = C.CASEID and CNZ.NAMETYPE = 'Z'
            and (CNZ.EXPIRYDATE is null or CNZ.EXPIRYDATE>getdate()))
    left join NAMEEXEMPTCHARGES NE on (NE.RATENO = @pnRateNo)
        left join RATES R on (NE.RATENO = R.RATENO)
    where C.IRN = @psIRN
        AND NE.NAMENO = CASE WHEN R.RATETYPE = 1601 THEN ISNULL(CNZ.NAMENO, CN.NAMENO) ELSE CN.NAMENO END)
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('AC27', 'The entered charge has been blocked for this client.', null, null, null, null, null)
	RAISERROR(@sAlertXML, 12, 1)
	Set @nErrorCode = @@ERROR
End

-- 
If @nErrorCode = 0 
and @pnCaseKey is not null
and @psIRN is null
Begin
	Select @psIRN = IRN
	from CASES
	where CASEID = @pnCaseKey
	
	Set @nErrorCode = @@ERROR
End

-- Retrieve Local Currency information
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= 0
End

If @nErrorCode=0
Begin
	exec @nErrorCode=dbo.FEESCALC 
			@psIRN			=@psIRN, 
			@pnRateNo		=@pnRateNo, 
			@psAction		=@psAction, 
			@pnCheckListType	=@pnCheckListType, 
			@pnCycle		=@pnCycle, 
			@pnEventNo		=@pnEventNo, 
			@pdtLetterDate		=@pdtLetterDate,
			@pnProductCode		=@pnProductCode, 
			@pnEnteredQuantity	=@pnEnteredQuantity, 
			@pnEnteredAmount	=@pnEnteredAmount, 
			@pnARQuantity		=@pnARQuantity, 
			@pnARAmount		=@pnARAmount,
			@pnDebtor		=@pnDebtor,
			@prsDisbCurrency 	=@prsDisbCurrency	output, 
			@prnDisbExchRate 	=@prnDisbExchRate	output, 
			@prsServCurrency 	=@prsServCurrency	output, 
			@prnServExchRate 	=@prnServExchRate	output, 
			@prsBillCurrency 	=@prsBillCurrency	output, 
			@prnBillExchRate 	=@prnBillExchRate	output, 
			@prsDisbTaxCode 	=@prsDisbTaxCode	output, 
			@prsServTaxCode 	=@prsServTaxCode	output, 
			@prnDisbNarrative 	=@prnDisbNarrativeNo	output, 
			@prnServNarrative 	=@prnServNarrativeNo	output, 
			@prsDisbWIPCode 	=@prsDisbWIPCode	output, 
			@prsServWIPCode 	=@prsServWIPCode	output, 
			@prnDisbAmount 		=@prnDisbAmount		output, 
			@prnDisbHomeAmount 	=@prnDisbHomeAmount	output, 
			@prnDisbBillAmount 	=@prnDisbBillAmount	output, 
			@prnServAmount 		=@prnServAmount		output, 
			@prnServHomeAmount 	=@prnServHomeAmount	output, 
			@prnServBillAmount 	=@prnServBillAmount	output, 
			@prnTotHomeDiscount 	=@prnTotHomeDiscount	output, 
			@prnTotBillDiscount 	=@prnTotBillDiscount	output, 
			@prnDisbTaxAmt 		=@prnDisbTaxAmt		output, 
			@prnDisbTaxHomeAmt 	=@prnDisbTaxHomeAmt	output, 
			@prnDisbTaxBillAmt 	=@prnDisbTaxBillAmt	output, 
			@prnServTaxAmt 		=@prnServTaxAmt		output, 
			@prnServTaxHomeAmt 	=@prnServTaxHomeAmt	output, 
			@prnServTaxBillAmt 	=@prnServTaxBillAmt	output,
			@prnDisbDiscOriginal	=@prnDisbDiscOriginal	output,
			@prnDisbHomeDiscount 	=@prnDisbHomeDiscount	output,
			@prnDisbBillDiscount 	=@prnDisbBillDiscount	output, 
			@prnServDiscOriginal	=@prnServDiscOriginal	output,
			@prnServHomeDiscount 	=@prnServHomeDiscount	output,
			@prnServBillDiscount 	=@prnServBillDiscount	output,
			@prnDisbCostHome	=@prnDisbCostHome	output,
			@prnDisbCostOriginal	=@prnDisbCostOriginal	output,
			@prnDisbMargin		=@prnDisbMargin		  output,
			@prnDisbHomeMargin	=@prnDisbHomeMargin	  output,
			@prnDisbBillMargin	=@prnDisbBillMargin	  output,
			@prnServMargin		=@prnServMargin		  output,
			@prnServHomeMargin	=@prnServHomeMargin	  output,
			@prnServBillMargin	=@prnServBillMargin	  output,
			@prnServCostOriginal	=@prnServCostOriginal	  output,
			@prnServCostHome	=@prnServCostHome	  output,			
			@prnDisbBasicAmount	=@prnDisbBasicAmount	  output,
			@prnDisbExtendedAmount 	=@prnDisbExtendedAmount	  output,
			@prnDisbCostCalculation1=@prnDisbCostCalculation1 output,
			@prnDisbCostCalculation2=@prnDisbCostCalculation2 output,
			@prnServBasicAmount	=@prnServBasicAmount	  output,
			@prnServExtendedAmount 	=@prnServExtendedAmount	  output,
			@prnServCostCalculation1=@prnServCostCalculation1 output,
			@prnServCostCalculation2=@prnServCostCalculation2 output,
			@prnVarBasicAmount	=@prnVarBasicAmount	  output,
			@prnVarExtendedAmount 	=@prnVarExtendedAmount	  output,
			@prnVariableFeeAmt	=@prnVariableFeeAmt	  output,
			@prnVarHomeFeeAmt	=@prnVarHomeFeeAmt	  output,
			@prnVarBillFeeAmt	=@prnVarBillFeeAmt	  output,
			@prnVarTaxAmt		=@prnVarTaxAmt		  output,
			@prnVarTaxHomeAmt	=@prnVarTaxHomeAmt	  output,
			@prnVarTaxBillAmt	=@prnVarTaxBillAmt	  output,
			@prsVarWIPCode		=@prsVarWIPCode		  output,
			@prsVarTaxCode 		=@prsVarTaxCode		  output,			
			@prnFeeCriteriaNo	=@prnFeeCriteriaNo	  output,
			@prnFeeUniqueId		=@prnFeeUniqueId	  output,
			@pbIsChargeGeneration	=@pbIsChargeGeneration,	
			@pdtTransactionDate	=@pdtTransactionDate,	
			@pdtBillDate		=@pdtBillDate,		
			@pbAgentItem		=@pbAgentItem,			
			@prsDisbStateTaxCode 	=@prsDisbStateTaxCode	  output, 
			@prsServStateTaxCode 	=@prsServStateTaxCode	  output, 
			@prsVarStateTaxCode 	=@prsVarStateTaxCode	  output,
			@prnDisbStateTaxAmt 	=@prnDisbStateTaxAmt	  output, 
			@prnDisbStateTaxHomeAmt =@prnDisbStateTaxHomeAmt  output, 
			@prnDisbStateTaxBillAmt =@prnDisbStateTaxBillAmt  output, 
			@prnServStateTaxAmt 	=@prnServStateTaxAmt	  output, 
			@prnServStateTaxHomeAmt =@prnServStateTaxHomeAmt  output,
			@prnServStateTaxBillAmt =@prnServStateTaxBillAmt  output,
			@prnVarStateTaxAmt	=@prnVarStateTaxAmt	  output,
			@prnVarStateTaxHomeAmt	=@prnVarStateTaxHomeAmt	  output,
			@prnVarStateTaxBillAmt	=@prnVarStateTaxBillAmt	  output,
			@prnDisbMarginNo	=@prnDisbMarginNo	  output,
			@prnServMarginNo	=@prnServMarginNo	  output,
			@prsFeeType		=@prsFeeType		  output,
			@prsFeeType2		=@prsFeeType2		  output,
			@pnDisbQuantity 	=@pnDisbQuantity	  output,	 -- Default Disbursement Quantity		
			@pnServQuantity		=@pnServQuantity	  output,	 -- Default Service Fee Quanitity
			--  RFC8233
			@pnEmployee		=@pnEmployee,
			-- RFC7269	
			@pnDisbDiscountForMargin	= @nDisbDiscountForMargin	output,
			@pnDisbHomeDiscountForMargin	= @nDisbHomeDiscountForMargin	output,
			@pnDisbBillDiscountForMargin	= @nDisbBillDiscountForMargin	output,
			@pnServDiscountForMargin	= @nServDiscountForMargin	output,
			@pnServHomeDiscountForMargin	= @nServHomeDiscountForMargin	output,
			@pnServBillDiscountForMargin	= @nServBillDiscountForMargin	output,
                        -- RFC56172
                        @pnDisbPreMarginDiscount	= @nDisbPreMarginDiscount	output,
	                @pnDisbHomePreMarginDiscount	= @nDisbHomePreMarginDiscount	output,
	                @pnDisbBillPreMarginDiscount	= @nDisbBillPreMarginDiscount	output,
	                @pnServPreMarginDiscount	= @nServPreMarginDiscount	output,
	                @pnServHomePreMarginDiscount	= @nServHomePreMarginDiscount	output,
	                @pnServBillPreMarginDiscount	= @nServBillPreMarginDiscount	output			

End

-- Get the Default Quanitity and Source on which the Calculation is based upon.
If @nErrorCode = 0 
Begin
	If @pbIsQtyAmtChange = 0 and (@pnDisbQuantity > 0 or @pnServQuantity > 0)
	Begin
		Set @sSourceType = 'Q'  -- Quantity
		Set @bQuantityRequired = 1
		Set @sDisbSourceType = 'Q'
		Set @sServSourceType = 'Q'
		If @pnDisbQuantity > 0
		Begin
			Set @nDefaultQuantity = @pnDisbQuantity
		End
		Else 
		Begin
			Set @nDefaultQuantity = @pnServQuantity
		End
	End
	Else 
	Begin
		Set @sSQLString = "Select 
				@dDisbBaseFee   = isnull(DISBBASEFEE,0) ,
				@dServBaseFee	= isnull(SERVBASEFEE,0),				
				@dDisbVarFee	= isnull(DISBVARIABLEFEE,0),
				@dServVarFee	= isnull(SERVVARIABLEFEE,0),
				@nDisbBaseUnits	= isnull(DISBBASEUNITS,0),
				@nServBaseUnits	= isnull(SERVBASEUNITS,0),
				@nDisbUnitSize	= isnull(DISBUNITSIZE,0),
				@nServUnitSize	= isnull(SERVUNITSIZE,0),
				@dDisbAddPercentage = isnull(DISBADDPERCENTAGE,0),
				@dServAddPercentage = isnull(SERVADDPERCENTAGE ,0),
                                @bDisbMinFeeFlag   = isnull(DISBMINFEEFLAG ,0),
                                @bServMinFeeFlag   = isnull(SERVMINFEEFLAG ,0)
			FROM FEESCALCULATION 
			WHERE CRITERIANO = @prnFeeCriteriaNo
			AND UNIQUEID	 = @prnFeeUniqueId"

		Exec @nErrorCode=sp_executesql @sSQLString,
			N'@dDisbBaseFee		decimal(11,2)		OUTPUT, 
			  @dServBaseFee		decimal(11,2)		OUTPUT, 
			  @dDisbVarFee		decimal(11,2)		OUTPUT,
			  @dServVarFee		decimal(11,2)		OUTPUT,
			  @nDisbBaseUnits	smallint		OUTPUT, 
			  @nServBaseUnits	smallint		OUTPUT,			  
			  @nDisbUnitSize	smallint		OUTPUT, 
			  @nServUnitSize	smallint		OUTPUT, 
			  @dDisbAddPercentage	decimal(5,4)		OUTPUT, 
			  @dServAddPercentage	decimal(5,4)		OUTPUT, 
                          @bDisbMinFeeFlag      bit                     OUTPUT,
                          @bServMinFeeFlag      bit                     OUTPUT,
			  @prnFeeCriteriaNo	int,
			  @prnFeeUniqueId	int',
			  @dDisbBaseFee		= @dDisbBaseFee		OUTPUT,
			  @dServBaseFee		= @dServBaseFee		OUTPUT,
			  @dDisbVarFee		= @dDisbVarFee		OUTPUT,
			  @dServVarFee		= @dServVarFee		OUTPUT,
			  @nDisbBaseUnits	= @nDisbBaseUnits	OUTPUT,
			  @nServBaseUnits	= @nServBaseUnits	OUTPUT,
			  @nDisbUnitSize	= @nDisbUnitSize	OUTPUT,
			  @nServUnitSize	= @nServUnitSize	OUTPUT,
			  @dDisbAddPercentage	= @dDisbAddPercentage	OUTPUT,
			  @dServAddPercentage	= @dServAddPercentage	OUTPUT,
                          @bDisbMinFeeFlag      = @bDisbMinFeeFlag      OUTPUT,
                          @bServMinFeeFlag      = @bServMinFeeFlag      OUTPUT,
			  @prnFeeCriteriaNo	= @prnFeeCriteriaNo,
			  @prnFeeUniqueId	= @prnFeeUniqueId
	
		If @nErrorCode = 0 
		Begin
			If @dDisbAddPercentage > 0 or @dServAddPercentage > 0
			Begin
				Set @sSourceType = 'A' -- Amount
				Set @bAmountRequired = 1				
			End
			
			If @bDisbMinFeeFlag = 1 and @bServMinFeeFlag = 1 and @nDisbBaseUnits = 0 and @nServBaseUnits=0
                        and @nDisbUnitSize = 0 and @nServUnitSize = 0
                        Begin
                                Set @sSourceType = 'N' -- Minimum Quantity				
                        End
                        Else Begin
				If (@nDisbBaseUnits <> 0 and @dDisbBaseFee <> 0) OR (@nDisbUnitSize <> 0 and @dDisbVarFee <> 0)
				Begin
					Set @sSourceType = 'Q' -- Quantity
					Set @bQuantityRequired = 1
				End
				If (@nServBaseUnits <> 0 and @dServBaseFee <> 0) OR (@nServUnitSize <> 0 and @dServVarFee <> 0)
				Begin
					Set @sSourceType = 'Q' -- Quantity
					Set @bQuantityRequired = 1
				End	
                        End
			
			If @bQuantityRequired <> 1
			Begin
				if exists (select 1 from FEESCALCALT where CRITERIANO = @prnFeeCriteriaNo AND UNIQUEID = @prnFeeUniqueId and COMPONENTTYPE in (0,1))
				Begin
					Set @sSourceType = 'Q' -- Quantity
					Set @bQuantityRequired = 1
				End
			End
		End

	End
End

-- Get WIP Description and Narrative for Disbursement
If @nErrorCode = 0 and @prnDisbHomeAmount != 0 and @prnDisbHomeAmount is not null
Begin		
	Set @sSQLString = "Select @prsDisbWIPDescription = " +
		dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'W',@sLookupCulture,@pbCalledFromCentura)+char(10)+",
		@prsDisbNarrative = "+ dbo.fn_SqlTranslatedColumn('NARRATIVE','NARRATIVETITLE',null,'N',@sLookupCulture,@pbCalledFromCentura)+char(10)+",	
		@prsDisbNarrativeText = "+ dbo.fn_SqlTranslatedColumn('NARRATIVE','NARRATIVETEXT',null,'N',@sLookupCulture,@pbCalledFromCentura)+char(10)+",
		@prsDisbAllowAdvanceBill = W.ENTERCREDITWIP		
		from WIPTEMPLATE W, NARRATIVE N
		Where WIPCODE = @prsDisbWIPCode
		and N.NARRATIVENO = @prnDisbNarrativeNo"
	
	Exec  @nErrorCode=sp_executesql @sSQLString,
			N'@prsDisbWIPDescription	nvarchar(40)	OUTPUT,
			  @prsDisbNarrative		nvarchar(50)	OUTPUT,
			  @prsDisbNarrativeText		nvarchar(max)   OUTPUT,
			  @prsDisbAllowAdvanceBill  bit OUTPUT,
			  @prsDisbWIPCode		varchar(6),
			  @prnDisbNarrativeNo		int',
			  @prsDisbWIPDescription	= @prsDisbWIPDescription OUTPUT,
			  @prsDisbNarrative		= @prsDisbNarrative OUTPUT,
			  @prsDisbNarrativeText		= @prsDisbNarrativeText OUTPUT,
			  @prsDisbAllowAdvanceBill  = @prsDisbAllowAdvanceBill OUTPUT,
			  @prsDisbWIPCode		= @prsDisbWIPCode,
			  @prnDisbNarrativeNo		= @prnDisbNarrativeNo
End

-- Get WIP Description and Narrative for Service Charge
If @nErrorCode = 0 and @prnServHomeAmount != 0 and @prnServHomeAmount is not null
Begin		
	Set @sSQLString = "Select @prsServWIPDescription = " +
		dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'W',@sLookupCulture,@pbCalledFromCentura)+char(10)+",
		@prsServNarrative = "+ dbo.fn_SqlTranslatedColumn('NARRATIVE','NARRATIVETITLE',null,'N',@sLookupCulture,@pbCalledFromCentura)+char(10)+",
		@prsServNarrativeText = "+ dbo.fn_SqlTranslatedColumn('NARRATIVE','NARRATIVETEXT',null,'N',@sLookupCulture,@pbCalledFromCentura)+char(10)+",	
		@prsServAllowAdvanceBill = W.ENTERCREDITWIP				
		from WIPTEMPLATE W, NARRATIVE N
		Where WIPCODE = @prsServWIPCode
		and N.NARRATIVENO = @prnServNarrativeNo"
	
	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@prsServWIPDescription	nvarchar(40)	OUTPUT,				
			        @prsServNarrative		nvarchar(50)	OUTPUT,
				@prsServNarrativeText		nvarchar(max)	OUTPUT,
				@prsServAllowAdvanceBill    bit OUTPUT,
				@prsServWIPCode			varchar(6),
				@prnServNarrativeNo		int',
				@prsServWIPDescription		= @prsServWIPDescription OUTPUT,
				@prsServNarrative		= @prsServNarrative	 OUTPUT,
				@prsServNarrativeText		= @prsServNarrativeText	 OUTPUT,
				@prsServAllowAdvanceBill  = @prsServAllowAdvanceBill OUTPUT,
				@prsServWIPCode			= @prsServWIPCode,
				@prnServNarrativeNo		= @prnServNarrativeNo
End


-- RFC12839 if translated narrative text exists in the NARRATIVETRANSLATE table
-- use this in preference to the translated narrative text stored in the NARRATIVE table.
If @nErrorCode = 0
Begin		
	Set @sTransDisbNarrativeText = null
	Set @sTransServNarrativeText = null
	Set @nDebtorKey = null
	
	If (@nErrorCode =0) and (@psIRN is not null)
	Begin
		Set @sSQLString = 
		"Select @nCaseKey   = CASEID
		 from CASES
		 where IRN = @psIRN"
		
		 exec @nErrorCode = sp_executesql @sSQLString,
					 N'@nCaseKey			int		output,
					 @psIRN				nvarchar(30)',
					 @nCaseKey			= @nCaseKey	output,
					 @psIRN				= @psIRN				 						
	End


	If @nErrorCode =0
	Begin
		Set @sSQLString = "
		Select @bIsTranslateNarrative = COLBOOLEAN
		from SITECONTROL where CONTROLID = 'Narrative Translate'"

		exec @nErrorCode=sp_executesql @sSQLString,
			N'@bIsTranslateNarrative	bit			 output',
			  @bIsTranslateNarrative	= @bIsTranslateNarrative output
	End


	If  (@nErrorCode =0 )
	and (@bIsTranslateNarrative = 1)
	and (@nCaseKey is not null)
	Begin
		exec @nErrorCode=dbo.bi_GetBillingLanguage
			@pnLanguageKey		= @nLanguageKey output,	
			@pnUserIdentityId	= @pnUserIdentityId,
			@pnDebtorKey		= @nDebtorKey,	
			@pnCaseKey		= @nCaseKey, 
			@pbDeriveAction		= 1					
		
	
		If  (@nErrorCode =0)
		and (@nLanguageKey is not null)
		Begin
			-- retrieve translated disbursement narrative
			Set @sSQLString = "Select @sTransDisbNarrativeText = TRANSLATEDTEXT
				from NARRATIVETRANSLATE 
				Where LANGUAGE = @nLanguageKey
				and NARRATIVENO = @prnDisbNarrativeNo"
			
			Exec  @nErrorCode=sp_executesql @sSQLString,
					N'@sTransDisbNarrativeText	nvarchar(MAX)   OUTPUT,
					  @nLanguageKey			int,
					  @prnDisbNarrativeNo		int',
					  @sTransDisbNarrativeText	= @sTransDisbNarrativeText OUTPUT,
					  @nLanguageKey			= @nLanguageKey,
					  @prnDisbNarrativeNo		= @prnDisbNarrativeNo
					  
			If (@sTransDisbNarrativeText is not null)
				Set @prsDisbNarrativeText = @sTransDisbNarrativeText
		
			-- retrieve translated service narrative
			Set @sSQLString = "Select @sTransServNarrativeText = TRANSLATEDTEXT
				from NARRATIVETRANSLATE 
				Where LANGUAGE = @nLanguageKey
				and NARRATIVENO = @prnServNarrativeNo"
			
			Exec  @nErrorCode=sp_executesql @sSQLString,
					N'@sTransServNarrativeText	nvarchar(MAX)   OUTPUT,
					  @nLanguageKey			int,
					  @prnServNarrativeNo		int',
					  @sTransServNarrativeText	= @sTransServNarrativeText OUTPUT,
					  @nLanguageKey			= @nLanguageKey,
					  @prnServNarrativeNo		= @prnServNarrativeNo
					  
			If (@sTransServNarrativeText is not null)
				Set @prsServNarrativeText = @sTransServNarrativeText
		End
	End
End


-- If Disbursment Currency is same as Local Currency
If @nErrorCode = 0 and @prsDisbCurrency = @sLocalCurrencyCode
Begin	
	Set @prsDisbCurrency = null
	Set @prnDisbExchRate = null
	Set @prnDisbAmount = null
	Set @prnDisbTaxAmt = null
	Set @prnDisbDiscOriginal = null
	Set @prnDisbCostOriginal = null
	Set @prnDisbMargin = null
	Set @prnDisbStateTaxAmt = null
	Set @nDisbDiscountForMargin = null
End

-- If Service Charge Currency is same as Local Currency
If @nErrorCode = 0 and @prsServCurrency =  @sLocalCurrencyCode
Begin	
	Set @prsServCurrency = null
	Set @prnServExchRate = null
	Set @prnServAmount = null
	Set @prnServTaxAmt = null
	Set @prnServDiscOriginal = null
	Set @prnServCostOriginal = null
	Set @prnServMargin = null
	Set @prnServStateTaxAmt = null
	Set @nServDiscountForMargin = null
End

-- Get the Fees Calculations
If @nErrorCode = 0 and @prnDisbHomeAmount != 0 and @prnDisbHomeAmount is not null
Begin
	Set @sSQLString = "SELECT @prbIsFeeType = case ISNULL(@prsFeeType,'0') when '0' then 0 else 1 end"
  
	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@prbIsFeeType		bit	OUTPUT,	
				@prsFeeType		nvarchar(6)',
				@prbIsFeeType		= @prbIsFeeType		OUTPUT,				
				@prsFeeType		= @prsFeeType
	
End

If @nErrorCode = 0 and @prnServHomeAmount != 0 and @prnServHomeAmount is not null
Begin
	Set @sSQLString = "SELECT @prbIsFeeType2 = case ISNULL(@prsFeeType2,'0') when '0' then 0 else 1 end"
  
	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@prbIsFeeType2	bit	OUTPUT,
				@prsFeeType2		nvarchar(6)',
				@prbIsFeeType2		= @prbIsFeeType2	OUTPUT,				
				@prsFeeType2		= @prsFeeType2
End


If (@nErrorCode = 0 and @prsDisbWIPCode is not null)
Begin
	Set @sSQLString = "Select @prsDisbWIPTypeId = WTP.WIPTYPEID,
		@prsDisbWIPCategory = WC.CATEGORYCODE,
		@prnDisbWIPCategorySort = WC.CATEGORYSORT
		From WIPTEMPLATE WT
		join WIPTYPE WTP on WTP.WIPTYPEID = WT.WIPTYPEID
		join WIPCATEGORY WC on WC.CATEGORYCODE = WTP.CATEGORYCODE
		Where WT.WIPCODE = @prsDisbWIPCode"

	Exec  @nErrorCode=sp_executesql @sSQLString,
					N'@prsDisbWIPTypeId		nvarchar(6)	OUTPUT,
					@prsDisbWIPCategory		nvarchar(3)	OUTPUT,
					@prnDisbWIPCategorySort		int		OUTPUT,
					@prsDisbWIPCode			nvarchar(6)',
					@prsDisbWIPTypeId		= @prsDisbWIPTypeId	OUTPUT,
					@prsDisbWIPCategory		= @prsDisbWIPCategory	OUTPUT,
					@prnDisbWIPCategorySort		= @prnDisbWIPCategorySort	OUTPUT,
					@prsDisbWIPCode			= @prsDisbWIPCode
End

If (@nErrorCode = 0 and @prsServWIPCode is not null)
Begin
	Set @sSQLString = "Select @prsServWIPTypeId = WTP.WIPTYPEID,
		@prsServWIPCategory = WC.CATEGORYCODE,
		@prnServWIPCategorySort = WC.CATEGORYSORT
		From WIPTEMPLATE WT
		join WIPTYPE WTP on WTP.WIPTYPEID = WT.WIPTYPEID
		join WIPCATEGORY WC on WC.CATEGORYCODE = WTP.CATEGORYCODE
		Where WT.WIPCODE = @prsServWIPCode"

	Exec  @nErrorCode=sp_executesql @sSQLString,
					N'@prsServWIPTypeId		nvarchar(6)	OUTPUT,
					@prsServWIPCategory		nvarchar(3)	OUTPUT,
					@prnServWIPCategorySort		int		OUTPUT,
					@prsServWIPCode			nvarchar(6)',
					@prsServWIPTypeId		= @prsServWIPTypeId	OUTPUT,
					@prsServWIPCategory		= @prsServWIPCategory	OUTPUT,
					@prnServWIPCategorySort		= @prnServWIPCategorySort	OUTPUT,
					@prsServWIPCode			= @prsServWIPCode
End

If ISNULL(@pbCalledFromBilling,0) = 0
Begin
Select 	-1				as RowKey,
	@prsDisbCurrency		as DisbCurrency, 
	@prnDisbExchRate		as DisbExchRate, 
	@prsServCurrency		as ServCurrency, 
	@prnServExchRate		as ServExchRate,
	@prsBillCurrency		as BillCurrency,
	@prnBillExchRate		as BillExchRate,
	@prsDisbTaxCode			as DisbTaxCode,
	@prsServTaxCode			as ServTaxCode,
	@prnDisbNarrativeNo		as DisbNarrativeKey,
	@prsDisbNarrative		as DisbNarrativeTitle,
	@prsDisbNarrativeText	as DisbNarrativeText,
	@prnServNarrativeNo		as ServNarrativeKey,
	@prsServNarrative		as ServNarrativeTitle,
	@prsServNarrativeText		as ServNarrativeText,
	@prsDisbWIPCode			as DisbWIPCode,
	@prsDisbWIPDescription		as DisbWIPDescription,
	@prsServWIPCode			as ServWIPCode, 
	@prsServWIPDescription		as ServWIPDescription,
	@prnDisbAmount			as DisbAmount,
	@prnDisbHomeAmount		as DisbHomeAmount,
	@prnDisbBillAmount		as DisbBillAmount,
	@prnServAmount			as ServAmount,
	@prnServHomeAmount		as ServHomeAmount,
	@prnServBillAmount		as ServBillAmount, 
	@prnTotHomeDiscount		as TotalHomeDiscount,
	@prnTotBillDiscount		as TotalBillDiscount, 
	@prnDisbTaxAmt			as DisbTaxAmount, 
	@prnDisbTaxHomeAmt		as DisbTaxHomeAmount,
	@prnDisbTaxBillAmt		as DisbTaxBillAmount, 
	@prnServTaxAmt			as ServTaxAmount, 
	@prnServTaxHomeAmt		as ServTaxHomeAmount, 
	@prnServTaxBillAmt		as ServTaxBillAmount,	
	@prnDisbDiscOriginal		as DisbDiscOriginal,
	@prnDisbHomeDiscount		as DisbHomeDiscount,
	@prnDisbBillDiscount		as DisbBillDiscount,
	@prnServDiscOriginal		as ServDiscOriginal,
	@prnServHomeDiscount		as ServHomeDiscount,
	@prnServBillDiscount		as ServBillDiscount,
	@prnDisbCostHome		as DisbCostHome,
	@prnDisbCostOriginal		as DisbCostOriginal,
	@prnServCostHome		as ServCostHome,
	@prnServCostOriginal		as ServCostOriginal,	
	@prnDisbBasicAmount		as DisbBasicAmount,
	@prnDisbExtendedAmount		as DisbExtendedAmount,
	@prnDisbCostCalculation1	as DisbCostCalculation1,
	@prnDisbCostCalculation2	as DisbCostCalculation2,
	@prnServBasicAmount		as ServBasicAmount,
	@prnServExtendedAmount		as ServExtendedAmount,
	@prnServCostCalculation1	as ServCostCalculation1,
	@prnServCostCalculation2	as ServCostCalculation2,
	@prnVarBasicAmount		as VarBasicAmount,
	@prnVarExtendedAmount		as VarExtendedAmount,
	@prnVariableFeeAmt		as VariableFeeAmt,
	@prnVarHomeFeeAmt		as VarHomeFeeAmt,
	@prnVarBillFeeAmt		as VarBillFeeAmt,
	@prnVarTaxAmt			as VarTaxAmt,
	@prnVarTaxHomeAmt		as VarTaxHomeAmt,
	@prnVarTaxBillAmt		as VarTaxBillAmt,
	@prsVarWIPCode			as VarWIPCode,
	@prsVarTaxCode			as VarTaxCode,
	@prsDisbAllowAdvanceBill as IsAllowAdvanceBillDisb,
	@prsServAllowAdvanceBill as IsAllowAdvanceBillServ,
	@prnDisbMargin			as DisbMargin,
	@prnDisbHomeMargin		as DisbHomeMargin,
	@prnDisbBillMargin		as DisbBillMargin,
	@prnServMargin			as ServMargin,
	@prnServHomeMargin		as ServHomeMargin,
	@prnServBillMargin		as ServBillMargin,
	@prnFeeCriteriaNo		as FeeCriteriaNo,
	@prnFeeUniqueId			as FeeUniqueId,
	@prsDisbStateTaxCode 		as DisbStateTaxCode,
	@prsServStateTaxCode 		as ServStateTaxCode,
	@prsVarStateTaxCode 		as VarStateTaxCode,
	@prnDisbStateTaxAmt 		as DisbStateTaxAmt,
	@prnDisbStateTaxHomeAmt 	as DisbStateTaxHomeAmt,
	@prnDisbStateTaxBillAmt 	as DisbStateTaxBillAmt,
	@prnServStateTaxAmt 		as ServStateTaxAmt,
	@prnServStateTaxHomeAmt 	as ServStateTaxHomeAmt,
	@prnServStateTaxBillAmt 	as ServStateTaxBillAmt,
	@prnVarStateTaxAmt		as VarStateTaxAmt,
	@prnVarStateTaxHomeAmt		as VarStateTaxHomeAmt,
	@prnVarStateTaxBillAmt		as VarStateTaxBillAmt,
	@prnDisbMarginNo		as DisbMarginNo,
	@prnServMarginNo		as ServMarginNo,
	@prsFeeType			as FeeType,
	@prsFeeType2			as FeeType2,
	@prbIsFeeType			as IsFeeType,
	@prbIsFeeType2			as IsFeeType2,	
	@nDefaultQuantity 		as DefaultQuantity,	
	@sSourceType			as SourceType,
	@prsDisbWIPTypeId		as DisbWIPTypeKey,
	@prsDisbWIPCategory		as DisbWIPCategoryKey,
	@prnDisbWIPCategorySort		as DisbWIPCategorySort,
	@prsServWIPTypeId		as ServWIPTypeKey,
	@prsServWIPCategory		as ServWipCategoryKey,
	@prnServWIPCategorySort		as ServWIPCategorySort,
	@nDisbDiscountForMargin		as DisbDiscountForMargin,
	@nDisbHomeDiscountForMargin	as DisbHomeDiscountForMargin,
	@nDisbBillDiscountForMargin	as DisbBillDiscountForMargin,
	@nServDiscountForMargin		as ServDiscountForMargin,
	@nServHomeDiscountForMargin	as ServHomeDiscountForMargin,
	@nServBillDiscountForMargin	as ServBillDiscountForMargin,
	@sServSourceType		as ServSourceType, -- may be obsolete?
	@sDisbSourceType		as DisbSourceType, -- may be obsolete?
        @nDisbPreMarginDiscount         as DisbPreMarginDiscount,
        @nDisbHomePreMarginDiscount     as DisbHomePreMarginDiscount,
        @nDisbBillPreMarginDiscount     as DisbBillPreMarginDiscount,
        @nServPreMarginDiscount         as ServPreMarginDiscount,
        @nServHomePreMarginDiscount     as ServHomePreMarginDiscount,
        @nServBillPreMarginDiscount     as ServBillPreMarginDiscount,
        @bQuantityRequired		as IsQuantityRequired,
		@bAmountRequired		as IsAmountRequired
End
Else
Begin
	Select 	
	@prsDisbWIPCode			as DisbWIPCode,
	@prsServWIPCode			as ServWIPCode, 
	@prsDisbCurrency		as DisbCurrency, 
	@prsServCurrency		as ServCurrency, 
	@prnDisbAmount			as DisbAmount,
	@prnDisbHomeAmount		as DisbHomeAmount,
	@prnServAmount			as ServAmount,
	@prnServHomeAmount		as ServHomeAmount,
	@prsDisbTaxCode			as DisbTaxCode,
	@prsServTaxCode			as ServTaxCode,
	@prnDisbTaxAmt			as DisbTaxAmount, 
	@prnDisbTaxHomeAmt		as DisbTaxHomeAmount,
	@prnServTaxAmt			as ServTaxAmount, 
	@prnServTaxHomeAmt		as ServTaxHomeAmount, 	
	@prnDisbBasicAmount		as DisbBasicAmount,
	@prnDisbExtendedAmount	as DisbExtendedAmount,
	@prnServBasicAmount		as ServBasicAmount,
	@prnServExtendedAmount	as ServExtendedAmount,
	@prnFeeCriteriaNo		as FeeCriteriaNo,
	@prnFeeUniqueId			as FeeUniqueId,
	@prsFeeType				as FeeType,
	@prsFeeType2			as FeeType2,
	@sServSourceType		as ServSourceType,
	@sDisbSourceType		as DisbSourceType,
	@pnCaseKey				as CaseKey
End

Return @nErrorCode
GO

Grant execute on dbo.wp_DOFEESCALC to public
GO

