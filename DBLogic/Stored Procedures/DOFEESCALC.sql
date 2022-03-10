-----------------------------------------------------------------------------------------------------------------------------
-- Creation of DOFEESCALC
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[DOFEESCALC]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.DOFEESCALC.'
	drop procedure dbo.DOFEESCALC
end
print '**** Creating procedure dbo.DOFEESCALC...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.DOFEESCALC 
			@psIRN 			nvarchar(30)	= NULL, 
			@pnRateNo 		int		= NULL, 
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
			@pnCriteriaNo		int		= NULL,
			@pnFeeUniqueId		smallint	= NULL,
			@pnEmployee		int		= NULL

as

-- PROCEDURE :	DOFEESCALC
-- VERSION :	19
-- DESCRIPTION:	This is a wrapper stored procedure.  It has the same input parameters as 
-- 		FEESCALC stored procedure.  The main task of DOFEESCALC is to execute 
-- 		FEESCALC and then publish its output parameters so that they can be 
-- 		retrieved by a Centura functional class.
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICTIONS :
-- Date         Who  	Number	Version Change
-- ------------ ---- 	------	------- ------------------------------------------- 
-- 28 Feb 2002	MF	SQA7182		Additional parameters for FEESCALC required 
-- 08 May 2002	IB	SQA7590		Changed the size of the @psIRN parameter from varchar(12) to varchar(20) 
-- 14 May 2004	DW	SQA9917		Pass debtor to FEESCALC with null value to preserve current functionality.
-- 25 Feb 2005	DW	11071		added new parameter Product Code
-- 08 Mar 2006	MF	12379	5	New parameters
-- 14 Mar 2006	MF	12379	6	Revisit.  Also return the Margin values 
-- 14 Jun 2006 	KR	11702	7	Added new parameters required for 11702 and 12108
-- 21 Sep 2006	MF	12361	8	Changes in parameters made to the FEESCALC procedure required new
--					parameters here.
-- 20 Nov 2006 	IB	13656	9	Defaulted @pbIsChargeGeneration parameter to 1.
-- 14 Feb 2007	CR	12400	10	Added new Bill Date parameter for use when deriving exchange rate for
--					Foreign Currency Bills.
-- 29 Mar 2007	MF	14644	11	Test input parameters for empty string '' as well as NULL
-- 28 Sep 2007	CR	14901	12	Changed Exchange Rate field sizes to (8,4)
-- 16 Oct 2007	CR	15383	13	Added new Agent Item parameter to indicate when an Agent Item is being processed.
-- 05 Dec 2007	CR	14649	14	Extended to include Multi-Tier Tax.
-- 03 Oct 2008	Dw	16917	15	Added logic to return and select margin identifiers for fee1 and fee2. 
-- 10 Jul 2009	MF	13811	16	Allow key of FEESCALCULATION table to be passed as input parameters so that Fee Calculation
--					is explicitly calculated for that particular row.
-- 21 Jul 2009	Dw	SQA9641	17	Added @pnEmployee as new input parameter
-- 29 Jun 2010	MS	RFC7269	17	Added Discount for Margin in Select
-- 20 Oct 2015  MS      R53933  18      Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols
-- 21 Jan 2016  Dw      R56418  19      Extended to include discounts for pre-margin amounts

set nocount on


declare @ErrorCode		int, 
	@prsDisbCurrency 	varchar(3),
	@prnDisbExchRate 	decimal(11,4), 
	@prsServCurrency 	varchar(3),
	@prnServExchRate 	decimal(11,4), 
	@prsBillCurrency 	varchar(3),
	@prnBillExchRate 	decimal(11,4), 
	@prsDisbTaxCode 	varchar(3),
	@prsServTaxCode 	varchar(3), 
	@prnDisbNarrative 	int,
	@prnServNarrative 	int, 
	@prsDisbWIPCode 	varchar(6),
	@prsServWIPCode 	varchar(6), 
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
	-- SQA7182 Add new output parameters to return the new components of the calculation
	@prnDisbDiscOriginal	decimal(11,2),
	@prnDisbHomeDiscount 	decimal(11,2),
	@prnDisbBillDiscount 	decimal(11,2),
	@prnServDiscOriginal	decimal(11,2),
	@prnServHomeDiscount 	decimal(11,2),
	@prnServBillDiscount 	decimal(11,2),
	@prnDisbCostHome	decimal(11,2),
	@prnDisbCostOriginal	decimal(11,2),
	-- SQA12379 Add new output parameters required by Charge Generation
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
	@prnServCostOriginal		decimal(11,2),
	@prnServCostHome		decimal(11,2),
	-- 14649 Multi-tier Tax
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
	@prnDisbMarginNo		int,
	@prnServMarginNo		int,
	@prsFeeType2			nvarchar(6),
	@pnDisbDiscountForMargin	decimal(11,2),
	@pnDisbHomeDiscountForMargin	decimal(11,2),
	@pnDisbBillDiscountForMargin	decimal(11,2),
	@pnServDiscountForMargin	decimal(11,2),
	@pnServHomeDiscountForMargin	decimal(11,2),
	@pnServBillDiscountForMargin	decimal(11,2),
	-- RFC56418
        @pnDisbPreMarginDiscount	        decimal(11,2),
	@pnDisbHomePreMarginDiscount	decimal(11,2),
	@pnDisbBillPreMarginDiscount	decimal(11,2),
	@pnServPreMarginDiscount	        decimal(11,2),
	@pnServHomePreMarginDiscount	decimal(11,2),
	@pnServBillPreMarginDiscount	decimal(11,2)
	--

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

Select @ErrorCode=0

If @ErrorCode=0
Begin
	exec @ErrorCode=dbo.FEESCALC 
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
			@prnDisbNarrative 	=@prnDisbNarrative	output, 
			@prnServNarrative 	=@prnServNarrative	output, 
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
			-- SQA7182 Add new output parameters to return the new components of the calculation
			@prnDisbDiscOriginal	=@prnDisbDiscOriginal	output,
			@prnDisbHomeDiscount 	=@prnDisbHomeDiscount	output,
			@prnDisbBillDiscount 	=@prnDisbBillDiscount	output, 
			@prnServDiscOriginal	=@prnServDiscOriginal	output,
			@prnServHomeDiscount 	=@prnServHomeDiscount	output,
			@prnServBillDiscount 	=@prnServBillDiscount	output,
			@prnDisbCostHome	=@prnDisbCostHome	output,
			@prnDisbCostOriginal	=@prnDisbCostOriginal	output,
			-- SQA12379 Add new output parameters required by Charge Generation
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
			@prnDisbMargin		=@prnDisbMargin		  output,
			@prnDisbHomeMargin	=@prnDisbHomeMargin	  output,
			@prnDisbBillMargin	=@prnDisbBillMargin	  output,
			@prnServMargin		=@prnServMargin		  output,
			@prnServHomeMargin	=@prnServHomeMargin	  output,
			@prnServBillMargin	=@prnServBillMargin	  output,
			@prnServCostOriginal	=@prnServCostOriginal	  output,
			@prnServCostHome	=@prnServCostHome	  output,
			@prnFeeCriteriaNo	=@pnCriteriaNo		  output,
			@prnFeeUniqueId		=@pnFeeUniqueId		  output,
			@pbIsChargeGeneration	=@pbIsChargeGeneration,	-- SQA12379 New INPUT parameter
			@pdtTransactionDate	=@pdtTransactionDate,	-- SQA11702 new INPUT parameter
			@pdtBillDate		=@pdtBillDate,		-- sqa12400 new INPUT parameter
			@pbAgentItem		=@pbAgentItem,
			-- New Output parameters of 
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
			@prsFeeType2		=@prsFeeType2 output,
			@pnDisbDiscountForMargin	=@pnDisbDiscountForMargin	output,				
			@pnDisbHomeDiscountForMargin	=@pnDisbHomeDiscountForMargin	output,
			@pnDisbBillDiscountForMargin	=@pnDisbBillDiscountForMargin	output,
			@pnServDiscountForMargin	=@pnServDiscountForMargin	output,
			@pnServHomeDiscountForMargin	=@pnServHomeDiscountForMargin	output,
			@pnServBillDiscountForMargin	=@pnServBillDiscountForMargin	output,
			--  SQA9641
			@pnEmployee			= @pnEmployee,
			-- RFC56418
                        @pnDisbPreMarginDiscount	= @pnDisbPreMarginDiscount	output,
	                @pnDisbHomePreMarginDiscount	= @pnDisbHomePreMarginDiscount	output,
	                @pnDisbBillPreMarginDiscount	= @pnDisbBillPreMarginDiscount	output,
	                @pnServPreMarginDiscount	= @pnServPreMarginDiscount	output,
	                @pnServHomePreMarginDiscount	= @pnServHomePreMarginDiscount	output,
	                @pnServBillPreMarginDiscount	= @pnServBillPreMarginDiscount	output

End

Select 	@prsDisbCurrency		as DisbCurrency, 
	@prnDisbExchRate		as DisbExchRate, 
	@prsServCurrency		as ServCurrency, 
	@prnServExchRate		as ServExchRate,
	@prsBillCurrency		as BillCurrency,
	@prnBillExchRate		as BillExchRate,
	@prsDisbTaxCode			as DisbTaxCode,
	@prsServTaxCode			as ServTaxCode,
	@prnDisbNarrative		as DisbNarrative,
	@prnServNarrative		as ServNarrative,
	@prsDisbWIPCode			as DisbWIPCode,
	@prsServWIPCode			as ServWIPCode, 
	@prnDisbAmount			as DisbAmount,
	@prnDisbHomeAmount		as DisbHomeAmount,
	@prnDisbBillAmount		as DisbBillAmount,
	@prnServAmount			as ServAmount,
	@prnServHomeAmount		as ServHomeAmount,
	@prnServBillAmount		as ServBillAmount, 
	@prnTotHomeDiscount		as TotHomeDiscount,
	@prnTotBillDiscount		as TotBillDiscount, 
	@prnDisbTaxAmt			as DisbTaxAmt, 
	@prnDisbTaxHomeAmt		as DisbTaxHomeAmt,
	@prnDisbTaxBillAmt		as DisbTaxBillAmt, 
	@prnServTaxAmt			as ServTaxAmt, 
	@prnServTaxHomeAmt		as ServTaxHomeAmt, 
	@prnServTaxBillAmt		as ServTaxBillAmt,
	-- SQA7182 Add new output parameters to return the new components of the calculation
	@prnDisbDiscOriginal		as DisbDiscOriginal,
	@prnDisbHomeDiscount		as DisbHomeDiscount,
	@prnDisbBillDiscount		as DisbBillDiscount,
	@prnServDiscOriginal		as ServDiscOriginal,
	@prnServHomeDiscount		as ServHomeDiscount,
	@prnServBillDiscount		as ServBillDiscount,
	@prnDisbCostHome		as DisbCostHome,
	@prnDisbCostOriginal		as DisbCostOriginal,
	-- SQA12379 Add new output parameters required by Charge Generation
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
	@prnDisbMargin			as DisbMargin,
	@prnDisbHomeMargin		as DisbHomeMargin,
	@prnDisbBillMargin		as DisbBillMargin,
	@prnServMargin			as ServMargin,
	@prnServHomeMargin		as ServHomeMargin,
	@prnServBillMargin		as ServBillMargin,
	@pnCriteriaNo			as FeeCriteriaNo,
	@pnFeeUniqueId			as FeeUniqueId,
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
	@pnDisbDiscountForMargin	as DisbDiscountForMargin,
	@pnDisbHomeDiscountForMargin	as DisbHomeDiscountForMargin,
	@pnDisbBillDiscountForMargin	as DisbBillDiscountForMargin,
	@pnServDiscountForMargin	as ServDiscountForMargin,
	@pnServHomeDiscountForMargin	as ServHomeDiscountForMargin,
	@pnServBillDiscountForMargin	as ServBillDiscountForMargin,
	@pnDisbPreMarginDiscount	as DisbPreMarginDiscount,
        @pnDisbHomePreMarginDiscount	as DisbHomePreMarginDiscount,
        @pnDisbBillPreMarginDiscount	as DisbBillPreMarginDiscount,
        @pnServPreMarginDiscount	as ServPreMarginDiscount,
        @pnServHomePreMarginDiscount	as ServHomePreMarginDiscount,
        @pnServBillPreMarginDiscount	as ServBillPreMarginDiscount

return @ErrorCode
go

grant execute on dbo.DOFEESCALC to public
go
