-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_GetTotalProfit
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[gl_GetTotalProfit]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.gl_GetTotalProfit.'
	drop procedure dbo.gl_GetTotalProfit
end
print '**** Creating procedure dbo.gl_GetTotalProfit...'
print ''
go 

CREATE PROCEDURE dbo.gl_GetTotalProfit 
(
	@prnTotalProfit 	decimal(13,2) output,
	@prnRecalculated	int output,
	@pnPeriodFrom 		int, 
	@pnPeriodTo 		int,
	@pnAcctEntity 		int		= null, 
	@pnUserIdentityId	int		= null,	-- included for use by .NET
	@pbCalledFromCentura	tinyint		= 0,
	@psCulture		nvarchar(10)	= null, -- the language in which output is to be expressed
	@psCurrency		nvarchar(3)	= null,	-- the currency the result is to be displayed in
	@pnExchRate		decimal(11,4)	= null,	-- the exchange rate to use when converting to foreign value
	@pbRecalculateAll	bit		= null,	-- determines whether to recalculate to foreign currency
	@pbUseHistExchRate	bit		= null,	-- Indicates whether to use historical exchange rates or not.
	@pnExchRateType		tinyint		= 1,	-- Bank Rate = 1, Buy Rate = 2, Sell Rate = 4
	@pbDebug		bit		= 0
)
AS

-- PROCEDURE:	gl_GetTotalProfit
-- VERSION:	9
-- DESCRIPTION:	Returns the total general ledger amount using the specified parameters as selection criteria
-- CALLED BY:	gl_ListBalanceSheetSummary
-- COPYRIGHT:	Copyright 1993 - 2006 CPA Software Solutions (Australia) Pty Limited
-- Date         Who  	SQA#	Version  	Change
-- ------------ ----	---- 	-------- 	------------------------------------------- 
-- 8.5.03	MB				Created
-- 27.08.03	MB	SQA8803
-- 13.10.03	MB	SQA9181
-- 06.02.04	SS	SQA8857 3.0.1		Modified to display results in a specific currency
-- 20.02.04	SS	SQA8857	3.0.2		Modified length of currency columns from 6 to 3.
-- 23.09.05	KR	SQA11682 7		Added parameters for Recalculate All and logic for foreign currency.
-- 19.12.06	CR	12605	8		Extended Foreign Currency logic to use Historical Exchange Rates
--						when requested.
-- 20 Oct 2015  MS      R53933  9               Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols

Begin
	SET NOCOUNT ON
	SET CONCAT_NULL_YIELDS_NULL OFF

	Declare	@ErrorCode		int
	Declare @nPeriodFrom		int
	Declare @nPeriodTo		int
	Declare	@nTotalIncome		decimal(13,2)
	Declare	@nTotalExpense		decimal(13,2)
	Declare	@nTotalIncomeOUT	decimal(13,2)
	Declare	@nTotalExpenseOUT	decimal(13,2)
	Declare @sSql			nvarchar(4000)
	Declare @sWhere			nvarchar(4000)
	Declare @nRecalculatedIncome	int
	Declare @nRecalculatedExpense	int
	Declare @nRecalculatedIncomeOUT	int
	Declare @nRecalculatedExpenseOUT int
	
	Set @ErrorCode=0
	Set @sSql=''
	Set @sWhere=''
	

	if (@pnExchRate is null or @pnExchRate = 0)
		Begin
			Set @pnExchRate = 1
		End

	-- Total Income
	
	Set @sSql =	'Select @nTotalIncomeOUT = -1 * Sum(ISNULL((CASE WHEN @pbRecalculateAll = 0 THEN
					CASE WHEN @psCurrency = jl.CURRENCY THEN
						jl.FOREIGNAMOUNT
					ELSE
						(CASE WHEN @pbUseHistExchRate = 1 THEN
							dbo.fn_GetHistExchRate(tr.TRANSDATE, @psCurrency, @pnExchRateType)
						Else
							@pnExchRate 
						END) * jl.LOCALAMOUNT
					END
					ELSE
						(CASE WHEN @pbUseHistExchRate = 1 THEN
							dbo.fn_GetHistExchRate(tr.TRANSDATE, @psCurrency, @pnExchRateType)
						Else
							@pnExchRate 
						END) * jl.LOCALAMOUNT
				END), 0)),
				@nRecalculatedIncomeOUT = sum(CASE WHEN @pbRecalculateAll = 0 THEN
					CASE WHEN @psCurrency = jl.CURRENCY 
						THEN 0
						ELSE 1
					END
				ELSE 0
				END)
			from TRANSACTIONHEADER tr, LEDGERJOURNALLINE jl, LEDGERACCOUNT la
			where tr.ENTITYNO = jl.ENTITYNO
				and tr.TRANSNO = jl.TRANSNO
				and la.ACCOUNTID = jl.ACCOUNTID
				and tr.TRANSTATUS = 1
				and tr.TRANPOSTPERIOD between @nPeriodFrom and @nPeriodTo
				and la.ACCOUNTTYPE = 8104'

	If (@pnAcctEntity is not null)
		Set @sSql = @sSql + ' and jl.ACCTENTITYNO = @pnAcctEntity'
	
	exec @ErrorCode = sp_executesql @sSql,
					N'@nTotalIncomeOUT	decimal(14,2) output,
					@nRecalculatedIncomeOUT	int output,
					@pnExchRate		decimal(11,4),
					@nPeriodFrom		int,
					@nPeriodTo		int,
					@pnAcctEntity		int,
					@psCurrency		nvarchar(3),
					@pbRecalculateAll	bit,
					@pbUseHistExchRate	bit,
					@pnExchRateType		tinyint',
					@nTotalIncomeOUT=@nTotalIncome output,
					@nRecalculatedIncomeOUT=@nRecalculatedIncome output,
					@pnExchRate=@pnExchRate,
					@nPeriodFrom=@pnPeriodFrom,
					@nPeriodTo=@pnPeriodTo,
					@pnAcctEntity=@pnAcctEntity,
					@psCurrency=@psCurrency,
					@pbRecalculateAll=@pbRecalculateAll,
					@pbUseHistExchRate=@pbUseHistExchRate,
					@pnExchRateType=@pnExchRateType

	If @pbDebug = 1
	Begin
		Print @sSql 
		SELECT @nTotalIncome AS TotalIncome
	End

	If (@ErrorCode = 0)
	Begin
		-- Total Expense
		Set @sSql =	'Select @nTotalExpenseOUT = Sum(ISNULL((CASE WHEN @pbRecalculateAll = 0 THEN
					CASE WHEN @psCurrency = jl.CURRENCY THEN
						jl.FOREIGNAMOUNT
					ELSE
						(CASE WHEN @pbUseHistExchRate = 1 THEN
							dbo.fn_GetHistExchRate(tr.TRANSDATE, @psCurrency, @pnExchRateType)
						Else
							@pnExchRate 
						END) * jl.LOCALAMOUNT
					END
					ELSE
						(CASE WHEN @pbUseHistExchRate = 1 THEN
							dbo.fn_GetHistExchRate(tr.TRANSDATE, @psCurrency, @pnExchRateType)
						Else
							@pnExchRate 
						END) * jl.LOCALAMOUNT
				END), 0)),
				@nRecalculatedExpenseOUT = sum(CASE WHEN @pbRecalculateAll = 0 THEN
					CASE WHEN @psCurrency = jl.CURRENCY 
						THEN 0
						ELSE 1
					END
				ELSE 0
				END)
					from TRANSACTIONHEADER tr, LEDGERJOURNALLINE jl, LEDGERACCOUNT la
					where tr.ENTITYNO = jl.ENTITYNO
						and tr.TRANSNO = jl.TRANSNO
						and la.ACCOUNTID = jl.ACCOUNTID
						and tr.TRANSTATUS = 1

						and tr.TRANPOSTPERIOD between @nPeriodFrom and @nPeriodTo
						and la.ACCOUNTTYPE = 8105'

		If (@pnAcctEntity is not null)
			Set @sSql = @sSql + ' and jl.ACCTENTITYNO = @pnAcctEntity'
			
		exec @ErrorCode = sp_executesql @sSql,
						N'@nTotalExpenseOUT	decimal(14,2) output,
						@nRecalculatedExpenseOUT	int output,
						@pnExchRate		decimal(11,4),
						@nPeriodFrom		int,
						@nPeriodTo		int,
						@pnAcctEntity		int,
						@psCurrency		nvarchar(3),
						@pbRecalculateAll	bit,
						@pbUseHistExchRate	bit,
						@pnExchRateType		tinyint',
						@nTotalExpenseOUT=@nTotalExpense output,
						@nRecalculatedExpenseOUT=@nRecalculatedExpense output,
						@pnExchRate=@pnExchRate,
						@nPeriodFrom=@pnPeriodFrom,
						@nPeriodTo=@pnPeriodTo,
						@pnAcctEntity=@pnAcctEntity,
						@psCurrency=@psCurrency,
						@pbRecalculateAll=@pbRecalculateAll,
						@pbUseHistExchRate=@pbUseHistExchRate,
						@pnExchRateType=@pnExchRateType

	If @pbDebug = 1
	Begin
		Print @sSql
		SELECT @nTotalExpense AS TotalExpense
	End

	End

	Set @prnTotalProfit = ISNULL(@nTotalIncome, 0) - ISNULL(@nTotalExpense, 0)

	if (@nRecalculatedExpense > 0) 
		Set @prnRecalculated = 1
	else
		if (@nRecalculatedIncome > 0)
			set @prnRecalculated = 1
		else
			set @prnRecalculated = 0

	If (@pbCalledFromCentura = 1)
		Select  @prnTotalProfit, @prnRecalculated

	Return @ErrorCode
End

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.gl_GetTotalProfit to public
GO