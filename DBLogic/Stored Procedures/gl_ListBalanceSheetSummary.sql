-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_ListBalanceSheetSummary
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[gl_ListBalanceSheetSummary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.gl_ListBalanceSheetSummary.'
	drop procedure dbo.gl_ListBalanceSheetSummary
end
print '**** Creating procedure dbo.gl_ListBalanceSheetSummary...'
print ''
go 

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE  PROCEDURE dbo.gl_ListBalanceSheetSummary
(
	@pnRowCount		int output,
	@pnPeriodTo 		int,
	@pnAcctEntity 		int		= null, 
	@pnUserIdentityId	int		= null,	-- included for use by .NET
	@psCulture		nvarchar(10)	= null, -- the language in which output is to be expressed
	@psCurrency		nvarchar(3)	= null,	-- the currency the result is to be displayed in
	@pnExchRate		decimal(11,4)	= null,	-- the exchange rate to use when converting to foreign value
	@pbRecalculateAll	bit		= null,	-- determines whether to recalculate to foreign currency
	@pbUseHistExchRate	bit		= null,	-- Indicates whether to use historical exchange rates or not.
	@pnExchRateType		tinyint		= 1,	-- Bank Rate = 1, Buy Rate = 2, Sell Rate = 4
	@pbDebug		bit		= 0
)
AS

-- PROCEDURE:	gl_ListBalanceSheetSummary
-- VERSION:	13
-- DESCRIPTION:	Returns a data stream to generate the Balance Sheet report. 
-- CALLED BY:	Centura
-- DEPENDENCIES: gl_TraverseAccount
-- COPYRIGHT:	Copyright 1993 - 2006 CPA Software Solutions (Australia) Pty Limited
-- Date         Who  	SQA#	Version  	Change
-- ------------ ----	---- 	-------- 	------------------------------------------- 
-- 12.5.03	MB				Created
-- 27.08.03	MB	SQA8803	
-- 13.10.03	MB	SQA9181
-- 06.02.04	SS	SQA8857 3.0.1		Modified to display results in a specific currency
-- 17.02.04	SFOO	SQA8851 3.0.2		Modified call to gl_TraverseAccount and change ##TEMPACCOUNTS
--						table to local #TEMPACCOUNTS table.
-- 20.02.04	SS	SQA8857	3.0.2		Modified length of currency columns from 6 to 3.
-- 13.09.05	KR	11682	7		Foreign values to be made available to reports
-- 22.09.05	KR	11682	8		Added parameter for RecalculateAll and logic for the same.
-- 19.12.06	CR	12605	9		Extended Foreign Currency logic to use Historical Exchange Rates
--						when requested.
-- 19/09/07	CR	15233	10		@pnAcctEntity should not be used to compare with EntityNo
-- 04.04.14	DL	21640	11		Balance Sheet should be displayed in Account Code order
-- 20 Oct 2015  MS      R53933  12              Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols
-- 02 Aug 2018	DL		R71180	13	Balance amount differences in Balance Sheet Reports

Begin
	SET NOCOUNT ON
	SET CONCAT_NULL_YIELDS_NULL OFF

	Declare	@ErrorCode		int
	Declare	@nPeriodStart		int
	Declare	@nPeriodStartOut	int
	Declare	@nTotalProfit		decimal(13,2)
	Declare @nRecalculated		int
	Declare @sSql			nvarchar(4000)
	Declare @sWhere			nvarchar(1000)	
	Declare @sRelAcctTempTable	nvarchar(128)
	
	Set @ErrorCode=0
	Set @sSql=''
	Set @sWhere=''
	
	Create Table #TEMPACCOUNTS ( 
		ACCOUNTID	int
	)
	
	Insert Into #TEMPACCOUNTS
	Select LEDGERACCOUNT.ACCOUNTID 
	from LEDGERACCOUNT
	where LEDGERACCOUNT.PARENTACCOUNTID is null
		and ACCOUNTTYPE in (8101, 8102, 8103)

	If (@ErrorCode=0)
	Begin
		exec gl_TraverseAccount '#TEMPACCOUNTS', @sRelAcctTempTable Output
	
		-- Get the very first period for the passed entity.
		-- SQA9181 

		Set @sSql =	'Select @nPeriodStartOut = Min(TRANPOSTPERIOD)
				from TRANSACTIONHEADER 
				join LEDGERJOURNAL	on (TRANSACTIONHEADER.ENTITYNO = LEDGERJOURNAL.ENTITYNO
							and TRANSACTIONHEADER.TRANSNO = LEDGERJOURNAL.TRANSNO)
				join LEDGERJOURNALLINE 	on (LEDGERJOURNALLINE.ENTITYNO = LEDGERJOURNAL.ENTITYNO
							and LEDGERJOURNALLINE.TRANSNO = LEDGERJOURNAL.TRANSNO)'

		If (@pnAcctEntity is not null)
			Set @sSql = @sSql + ' where LEDGERJOURNALLINE.ACCTENTITYNO = @pnAcctEntity'

		exec @ErrorCode = sp_executesql @sSql,
						N'@nPeriodStartOut	int output,
						@pnAcctEntity		int',
						@nPeriodStartOut=@nPeriodStart output,
						@pnAcctEntity=@pnAcctEntity

		If @pbDebug = 1
		Begin
			PRINT @sSql
		End
	End

	-- SELECT Total Profit
	If (@ErrorCode = 0)
		exec @ErrorCode = gl_GetTotalProfit @nTotalProfit output, @nRecalculated output, @nPeriodStart, @pnPeriodTo, @pnAcctEntity, @pnUserIdentityId, 0, @psCulture, @psCurrency, @pnExchRate, @pbRecalculateAll, @pbUseHistExchRate,	@pnExchRateType, @pbDebug
	if (@pnExchRate is null or @pnExchRate = 0)
		Begin
			Set @pnExchRate = 1
		End	

	
	If (@ErrorCode = 0)
	Begin
		If (@pnAcctEntity is not null)
			Set @sWhere = ' and jl.ACCTENTITYNO = @pnAcctEntity'

		Set @sSql =	'Select att.TABLECODE as ACCOUNT_TYPE_ID,
					att.[DESCRIPTION] as ACCOUNT_TYPE_DESC,
					la.ACCOUNTID, la.ACCOUNTCODE, la.[DESCRIPTION] as ACCOUNT_DESC,
					sum((CASE WHEN @pbRecalculateAll = 0 THEN
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
					END)*
					(Case la.ACCOUNTTYPE
						when 8102 then (-1)
						when 8103 then (-1)
						else (1)
					end)) as AMOUNT,
				case when(sum(CASE WHEN @pbRecalculateAll = 0 THEN
						CASE WHEN @psCurrency = jl.CURRENCY 
						THEN 0
						ELSE 1
						END
					ELSE 0
					END)) > 0 
				THEN 1 
				ELSE 0
				END		
 				from #TEMPACCOUNTS a, ' + @sRelAcctTempTable + ' b, 
					TRANSACTIONHEADER tr, LEDGERJOURNALLINE jl, 
					LEDGERACCOUNT la, TABLECODES att
 				where la.ACCOUNTID = a.ACCOUNTID 
					and la.ACCOUNTTYPE = att.TABLECODE
					and a.ACCOUNTID = b.PARENTID
					and tr.ENTITYNO = jl.ENTITYNO
					and tr.TRANSNO = jl.TRANSNO
					and (b.CHILDID = jl.ACCOUNTID or b.PARENTID = jl.ACCOUNTID )
					and tr.TRANSTATUS = 1
					and (tr.TRANSTYPE <> 812 OR (tr.TRANSTYPE = 812 AND
					   la.ACCOUNTTYPE NOT IN (8104,8105)))
					and tr.TRANPOSTPERIOD <= @pnPeriodTo ' + @sWhere + '
				group by att.TABLECODE,	att.[DESCRIPTION],
					la.ACCOUNTID, la.ACCOUNTCODE, la.[DESCRIPTION],
					la.ACCOUNTTYPE '
	
		If (@nTotalProfit is not null)
			Set @sSql = @sSql + ' UNION ALL
				Select att.TABLECODE as ACCOUNT_TYPE_ID,
					att.[DESCRIPTION] as ACCOUNT_TYPE_DESC,
					0, ''PP'', ''plus Profit'',
					@nTotalProfit, @nRecalculated
				from TABLECODES att
				where att.TABLECODE = 8103'

		-- Set @sSql = @sSql + ' order by 1, 5'
		Set @sSql = @sSql + ' order by 1, 4'		-- 21640
			

		exec @ErrorCode = sp_executesql @sSql,
						N'@pnPeriodTo		int,
						@pnAcctEntity		int,
						@psCurrency		nvarchar(3),
						@pnExchRate		decimal(11,4),
						@nTotalProfit		decimal(13,2),
						@nRecalculated		int,
						@pbRecalculateAll 	bit,
						@pbUseHistExchRate	bit,
						@pnExchRateType		tinyint',
						@pnPeriodTo=@pnPeriodTo,
						@pnAcctEntity=@pnAcctEntity,
						@psCurrency=@psCurrency,
						@pnExchRate=@pnExchRate,
						@nTotalProfit=@nTotalProfit,
						@pbRecalculateAll=@pbRecalculateAll,
						@nRecalculated=@nRecalculated,
						@pbUseHistExchRate=@pbUseHistExchRate,
						@pnExchRateType=@pnExchRateType

		Set @pnRowCount = @@Rowcount
		
		If @pbDebug = 1
		Begin
			PRINT @sSql
		End
	End

	Drop Table #TEMPACCOUNTS 

	Set @sSql = 'Drop Table ' + @sRelAcctTempTable
	Exec sp_executesql @sSql

	Return @ErrorCode
End

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


grant execute on dbo.gl_ListBalanceSheetSummary to public
GO