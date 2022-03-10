-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_GetTotalAmountByType
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[gl_GetTotalAmountByType]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.gl_GetTotalAmountByType.'
	drop procedure dbo.gl_GetTotalAmountByType
end
print '**** Creating procedure dbo.gl_GetTotalAmountByType...'
print ''
go 

SET QUOTED_IDENTIFIER OFF 
GO

CREATE PROCEDURE dbo.gl_GetTotalAmountByType
(
	@prnAmount 		decimal(13,2) output,
	@prnRecalculated	int output,
	@pnPeriodFrom 		int,
	@pnPeriodTo 		int,
	@pnAccountType 		int,
	@pnAcctEntity 		int		= null, 
	@pnUserIdentityId	int		= null,	-- included for use by .NET
	@pbCalledFromCentura	tinyint		= 0,
	@psCulture		nvarchar(10)	= null, -- the language in which output is to be expressed
	@psProfitCentreCodes 	ntext		= null,
	@psCurrency		nvarchar(3)	= null,	-- the currency the result is to be displayed in
	@pnExchRate		decimal(11,4)	= null,	-- the exchange rate to use when converting to foreign value
	@pbRecalculateAll	bit		= null,	-- determines whether to recalculate to foreign currency
	@pbUseHistExchRate	bit		= null,	-- Indicates whether to use historical exchange rates or not.
	@pnExchRateType		tinyint		= 1,	-- Bank Rate = 1, Buy Rate = 2, Sell Rate = 4
	@pbDebug		bit		= 0
)
AS

-- PROCEDURE:	gl_GetTotalAmountByType
-- VERSION:	13
-- DESCRIPTION:	Returns the total general ledger amount using the specified parameters as selection criteria
-- CALLED BY:	FCDBLedgerJournalLineX (Centura)
-- COPYRIGHT:	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
-- Date         Who  	SQA#		Version  	Change
-- ------------ ----	---- 		-------- 	------------------------------------------- 
-- 8.5.03	MB					Created
-- 6.6.03	MB					Removed ABS
-- 27.08.03	MB	SQA8803
-- 13.10.03	MB	SQA9181
-- 06.02.04	SS	SQA8857 	3.0.1		Modified to display results in a specific currency
-- 20.02.04	SS	SQA8857		3.0.2		Modified length of currency columns from 6 to 3.
-- 22.09.05	KR	SQA11682 	8		Add new parameters for RecalculateAll and logic for foreign currency.
-- 25/03/06	AT	SQA12005	9		Converted transact-SQL joins to standard joins.
-- 28/08/06	AT	SQA13082	10		Modified to take a comma separated list of profit centres.
-- 04/01/07	CR	SQA12605	11		Extended Foreign Currency logic to use Historical Exchange Rates
--							when requested.
-- 12/09/07	CR	SQA14722	12		Increase the size of the @sWhere variable, converted @psProfitCentreCodes to ntext.
-- 20 Oct 2015  MS      R53933          13              Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols


Begin
	Declare	@ErrorCode		int
	Declare	@nTotalAmountOUT	decimal(13,2)
	Declare	@nTotalAmount		decimal(13,2)
	Declare @sSql			nvarchar(4000)
	Declare @sWhere			nvarchar(4000)
	Declare @nRecalculated		int
	Declare @nRecalculatedOUT	int
	Declare @sProfitCentreCodes 	nvarchar(2000)	
	
	Set @ErrorCode=0
	Set @sSql=''
	Set @sWhere =''
	Set @sProfitCentreCodes = CAST(@psProfitCentreCodes AS nvarchar(2000))
	If (@sProfitCentreCodes = '')
		Set @sProfitCentreCodes = NULL

	If (@sProfitCentreCodes IS NOT NULL) 
		Set @sWhere = ' and jl.PROFITCENTRECODE in (' + @sProfitCentreCodes + ')'

	If (@pnAcctEntity IS NOT NULL)
		Set @sWhere = @sWhere + ' and jl.ACCTENTITYNO = @pnAcctEntity'

	if (@pnExchRate IS NULL OR @pnExchRate = 0)
		Set @pnExchRate = 1


	
	Set @sSql =	'Select @nTotalAmountOUT = ISNULL(Sum(CASE WHEN @pbRecalculateAll = 0 THEN
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
				END), 0),
				@nRecalculatedOUT = Sum(CASE WHEN @pbRecalculateAll = 0 THEN
					CASE WHEN @psCurrency = jl.CURRENCY 
						THEN 0
						ELSE 1
					END
				ELSE 0
				END)
			from LEDGERACCOUNT la
			join LEDGERJOURNALLINE jl on (jl.ACCOUNTID = la.ACCOUNTID)
			join TRANSACTIONHEADER tr on (tr.ENTITYNO = jl.ENTITYNO
							and tr.TRANSNO = jl.TRANSNO)
			where tr.TRANSTATUS = 1
				and tr.TRANSTYPE <> 812
				and tr.TRANPOSTPERIOD between @pnPeriodFrom and @pnPeriodTo
				and la.ACCOUNTTYPE = @pnAccountType ' + @sWhere


		exec sp_executesql @sSql,
			N'@nTotalAmountOUT	decimal(13,2) output,
			@nRecalculatedOUT	int output,
			@pnExchRate		decimal(11,4),
			@pnAcctEntity		int,
			@pnPeriodFrom		int,
			@pnPeriodTo		int,
			@pnAccountType		int,
			@psCurrency		nvarchar(3),
			@pbRecalculateAll	bit,
			@pbUseHistExchRate	bit,
			@pnExchRateType		tinyint',
			@nTotalAmountOUT=@nTotalAmount output,
			@nRecalculatedOUT=@nRecalculated output,
			@pnExchRate=@pnExchRate,
			@pnAcctEntity=@pnAcctEntity,
			@pnPeriodFrom=@pnPeriodFrom,
			@pnPeriodTo=@pnPeriodTo,
			@pnAccountType=@pnAccountType,
			@psCurrency=@psCurrency,
			@pbRecalculateAll=@pbRecalculateAll,
			@pbUseHistExchRate=@pbUseHistExchRate,
			@pnExchRateType=@pnExchRateType


	Set @ErrorCode = @@Error

	if @pbDebug = 1
	Begin
		Print @sSql
		select @pnPeriodFrom 	AS PERIODFROM,
		@pnPeriodTo 		AS PERIODTO,
		@pnAccountType 		AS ACCOUNTTYPE,
		@pnAcctEntity 		AS ACCTENTITY, 
		@sProfitCentreCodes 	AS PROFITCENTRECODES,
		@psCurrency		AS CURRENCY,
		@pnExchRate		AS EXCHRATE,
		@pbRecalculateAll	AS RECALCULATEALL,
		@pbUseHistExchRate	AS USEHISTORICALEXCHRATE,
		@pnExchRateType		AS EXCHRATETYPE
	End
	
	Set @prnAmount = @nTotalAmount

	if (@nRecalculated > 0) 
		Set @prnRecalculated = 1
	else
		set @prnRecalculated = 0

	If (@pbCalledFromCentura = 1)
		Select @nTotalAmount, @prnRecalculated

	Return @ErrorCode
End
GO

grant execute on dbo.gl_GetTotalAmountByType to public
GO
