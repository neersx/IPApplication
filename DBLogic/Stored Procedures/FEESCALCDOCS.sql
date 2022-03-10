-----------------------------------------------------------------------------------------------------------------------------
-- Creation of FEESCALCDOCS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[FEESCALCDOCS]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.FEESCALCDOCS.'
	drop procedure dbo.FEESCALCDOCS
	print '**** Creating procedure dbo.FEESCALCDOCS...'
	print ''
end
go

create proc dbo.FEESCALCDOCS 
		@psEntryPoint		varchar(254), 
		@psWhenRequested 	varchar(254),
		@psSqlUser 		nvarchar(40), 
		@psCaseId 		varchar(254), 
		@psRateNo 		varchar(12),	
		@psEnteredQuantity 	varchar(254), 
		@psEnteredAmount 	varchar(254) 	
as

-- PROCEDURE :	FEESCALCDOCS
-- VERSION :	14
-- DESCRIPTION:	Procedure used by Docitem to return fees & charges calculations for a Case and Rateno
--
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 16/11/2001	CS	HD #656		String that is getting passed to the @psWhenRequested has multiple
--					quotes appended to it, causing a conversion error when it was being
--					moved into a DateTime field.  The actual date time string is now
--					Substringed out of the this. 
-- 14/05/04	DW	SQA9917		Pass debtor to FEESCALC with null value to preserve current functionality.
-- 28/02/2005	Dw	11071		adjusted to pass new parameter (@nProductCode) to FEESCALC
-- 01 Dec 2006	MF	12361	10	Name the parameters in the call to FEESCALC to avoid problems when new
--					parameters are added to the procedure.
-- 28 Sep 2007	CR	14901	11	Changed Exchange Rate field sizes to (8,4)
-- 03 Oct 2008	Dw	16917	12	Added logic to return and select margin identifiers for fee1 and fee2.
-- 21 Oct 2011	DL	19708	13	Change @psSqlUser from varchar(20) to nvarchar(40) to match ACTIVITYREQUEST.SQLUSER
-- 20 Oct 2015  MS      R53933  14      Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols

set nocount on

declare @sIRN 			varchar(20) 
declare @nCycle 		smallint
declare @nCheckListType	 	smallint
declare @nQuestionNo 		smallint
declare @sAction		varchar(2)
declare @nEventNo 		int
declare @nARQuantity 		smallint
declare @nARAmount 		decimal(11,2)
declare @dtLetterDate 		datetime
declare @prsDisbCurrency 	varchar(3)
declare @prnDisbExchRate 	decimal(11,4)
declare @prsServCurrency 	varchar(3)
declare @prnServExchRate 	decimal(11,4)
declare @prsBillCurrency 	varchar(3)
declare @prnBillExchRate 	decimal(11,4)
declare @prsDisbTaxCode 	varchar(3) 
declare @prsServTaxCode 	varchar(3)
declare @prnDisbNarrative 	int 
declare @prnServNarrative 	int
declare @prsDisbWIPCode 	varchar(6)
declare @prsServWIPCode 	varchar(6)
declare @prnDisbAmount 		decimal(11,2)
declare @prnDisbHomeAmount 	decimal(11,2)
declare @prnDisbBillAmount 	decimal(11,2) 
declare @prnServAmount 		decimal(11,2) 
declare @prnServHomeAmount 	decimal(11,2) 
declare @prnServBillAmount 	decimal(11,2) 
declare @prnTotHomeDiscount 	decimal(11,2) 
declare @prnTotBillDiscount 	decimal(11,2)
declare @prnDisbTaxAmt 		decimal(11,2) 
declare @prnDisbTaxHomeAmt 	decimal(11,2) 
declare @prnDisbTaxBillAmt 	decimal(11,2)
declare @prnServTaxAmt 		decimal(11,2) 
declare @prnServTaxHomeAmt 	decimal(11,2) 
declare @prnServTaxBillAmt 	decimal(11,2) 
declare @prnDisbDiscOriginal	decimal(11,2)
declare @prnDisbHomeDiscount 	decimal(11,2)
declare @prnDisbBillDiscount 	decimal(11,2) 
declare @prnServDiscOriginal	decimal(11,2)
declare @prnServHomeDiscount 	decimal(11,2)
declare @prnServBillDiscount 	decimal(11,2)
declare @prnDisbCostHome	decimal(11,2)
declare @prnDisbCostOriginal	decimal(11,2)
declare @prnDisbMarginNo	int
declare @prnServMarginNo	int

declare @pnCaseId 		int
declare @pnRateNo 		int
declare @pnEnteredQuantity 	int
declare @pnEnteredAmount 	decimal(11,2) 
declare @pdtWhenRequested 	datetime
declare @nDebtor 		int
declare @nProductCode	 	int			/* Dw 28/02/2005	New variable added      */

declare @ErrorCode		int
declare @RowCount		int

	
select @pnCaseId 		= convert(int, @psCaseId)
select @pnRateNo 		= convert(int, @psRateNo)
select @pnEnteredQuantity 	= convert(int, @psEnteredQuantity) 
select @pnEnteredAmount 	= convert(decimal(11,2), @psEnteredAmount)
select @RowCount                = 0
select @nDebtor                	= null
select @nProductCode 		= null

If @psEntryPoint is not null
Begin
	select @sIRN      = @psEntryPoint
	select @ErrorCode = 0
End
Else Begin
	select @ErrorCode = -1
End

-- This is the old statement
--select @pdtWhenRequested = convert(datetime, @psWhenRequested)
-- This is the fix for HD #656

If @ErrorCode=0
begin

	select @pdtWhenRequested =  CONVERT(DATETIME, SUBSTRING(@psWhenRequested,7,23),121)

 
	SELECT	@nCycle		=CYCLE, 
		@sAction	=ACTION, 
		@nQuestionNo	=QUESTIONNO, 
		@nEventNo	=EVENTNO,
		@nARQuantity	=ENTEREDQUANTITY, 
		@nARAmount	=ENTEREDAMOUNT, 
		@dtLetterDate	=LETTERDATE,
		@nProductCode	=PRODUCTCODE
	FROM  ACTIVITYREQUEST 
	WHERE CASEID        = @pnCaseId
	AND   WHENREQUESTED = @pdtWhenRequested 
	AND   SQLUSER       = @psSqlUser 
	
	Select @ErrorCode=@@Error,
	       @RowCount =@@Rowcount
End

-- Terminate if no ACTIVITYREQUEST row was found

If @RowCount=0
	Select @ErrorCode=-1
	
If  @ErrorCode=0
and @nQuestionNo is not null
Begin		
	exec @ErrorCode=pt_GetChecklistType 
				@pnCaseId, 
				@nQuestionNo, 
				@nCheckListType output
End

If @ErrorCode=0							
Begin
	exec @ErrorCode=FEESCALC
				@psIRN			=@sIRN, 
				@pnRateNo		=@pnRateNo, 
				@psAction		=@sAction,
				@pnCheckListType	=@nCheckListType, 
				@pnCycle		=@nCycle, 
				@pnEventNo		=@nEventNo, 
				@pdtLetterDate		=@dtLetterDate,
				@pnProductCode		=@nProductCode, 
				@pnEnteredQuantity	=@pnEnteredQuantity, 
				@pnEnteredAmount	=@pnEnteredAmount, 
				@pnARQuantity		=@nARQuantity, 
				@pnARAmount		=@nARAmount, 
				@pnDebtor		=@nDebtor,
				@prsDisbCurrency	=@prsDisbCurrency	output, 
				@prnDisbExchRate	=@prnDisbExchRate	output, 
				@prsServCurrency	=@prsServCurrency	output, 
				@prnServExchRate	=@prnServExchRate	output,
				@prsBillCurrency	=@prsBillCurrency	output, 
				@prnBillExchRate	=@prnBillExchRate	output, 
				@prsDisbTaxCode		=@prsDisbTaxCode	output, 
				@prsServTaxCode		=@prsServTaxCode	output, 
				@prnDisbNarrative	=@prnDisbNarrative	output, 
				@prnServNarrative	=@prnServNarrative	output,
				@prsDisbWIPCode		=@prsDisbWIPCode	output, 
				@prsServWIPCode		=@prsServWIPCode	output,
				@prnDisbAmount		=@prnDisbAmount		output, 
				@prnDisbHomeAmount	=@prnDisbHomeAmount	output, 
				@prnDisbBillAmount	=@prnDisbBillAmount	output, 
				@prnServAmount		=@prnServAmount		output, 
				@prnServHomeAmount	=@prnServHomeAmount	output, 
				@prnServBillAmount	=@prnServBillAmount	output, 
				@prnTotHomeDiscount	=@prnTotHomeDiscount	output, 
				@prnTotBillDiscount	=@prnTotBillDiscount	output,
				@prnDisbTaxAmt		=@prnDisbTaxAmt		output, 
				@prnDisbTaxHomeAmt	=@prnDisbTaxHomeAmt	output, 
				@prnDisbTaxBillAmt	=@prnDisbTaxBillAmt	output, 
				@prnServTaxAmt		=@prnServTaxAmt		output, 
				@prnServTaxHomeAmt	=@prnServTaxHomeAmt	output, 
				@prnServTaxBillAmt	=@prnServTaxBillAmt	output,
				@prnDisbDiscOriginal	=@prnDisbDiscOriginal	output,
				@prnDisbHomeDiscount	=@prnDisbHomeDiscount 	output,
				@prnDisbBillDiscount	=@prnDisbBillDiscount 	output, 
				@prnServDiscOriginal	=@prnServDiscOriginal	output,
				@prnServHomeDiscount	=@prnServHomeDiscount 	output,
				@prnServBillDiscount	=@prnServBillDiscount 	output,
				@prnDisbCostHome	=@prnDisbCostHome	output,
				@prnDisbCostOriginal	=@prnDisbCostOriginal	output,
				@prnDisbMarginNo	=@prnDisbMarginNo	output,
				@prnServMarginNo	=@prnServMarginNo	output

End

select 	@prsDisbCurrency, 	@prnDisbExchRate,
	@prsServCurrency, 	@prnServExchRate,
	@prsBillCurrency,	@prnBillExchRate,
	@prsDisbTaxCode,	@prsServTaxCode,
	@prnDisbNarrative,	@prnServNarrative,
	@prsDisbWIPCode,	@prsServWIPCode,
	@prnDisbAmount,		@prnDisbHomeAmount,	@prnDisbBillAmount,
	@prnServAmount,		@prnServHomeAmount,	@prnServBillAmount,
	@prnTotHomeDiscount,	@prnTotBillDiscount,
	@prnDisbTaxAmt,		@prnDisbTaxHomeAmt,	@prnDisbTaxBillAmt,
	@prnServTaxAmt,		@prnServTaxHomeAmt,	@prnServTaxBillAmt,
	@prnDisbDiscOriginal,	@prnDisbHomeDiscount,	@prnDisbBillDiscount,
	@prnServDiscOriginal,	@prnServHomeDiscount,	@prnServBillDiscount,
	@prnDisbCostHome,	@prnDisbCostOriginal,
	@prnDisbMarginNo,	@prnServMarginNo

return @ErrorCode
go

grant exec on dbo.FEESCALCDOCS to public
go
