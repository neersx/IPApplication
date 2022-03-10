-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_ListBalanceSheetDetails
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[gl_ListBalanceSheetDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.gl_ListBalanceSheetDetails.'
	drop procedure dbo.gl_ListBalanceSheetDetails
end
print '**** Creating procedure dbo.gl_ListBalanceSheetDetails...'
print ''
go 

CREATE PROCEDURE dbo.gl_ListBalanceSheetDetails
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
-- PROCEDURE:	gl_ListBalanceSheetDetails
-- DESCRIPTION:	Returns a data stream to generate the Balance Sheet report. 
-- VERSION: 	12
-- CALLED BY:	Centura
-- DEPENDENCIES: gl_ArrangeAccountTree
-- COPYRIGHT:	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 12.5.03	MB			Created
-- 21.7.03	TM	RFC293 		Stored procedure synatx problems
-- 27.08.03	MB	8803
-- 13.10.03	MB	9181
-- 06.02.04	SS	8857 	3.0.1	Modified to display results in a specific currency
-- 20.02.04	SS	8857	3.0.2	Modified length of currency columns from 6 to 3.
-- 01.03.04	SFOO	9614 	3.0.3	Modified to cater for variable and unique related account global temporary table 
--					name returned by gl_ArrangeAccountTree.
-- 06 Aug 2004	AB	8035	4	Add collate database_default to temp table definitions
-- 13.09.05	KR	11682	5	Foreign values to be made available to reports
-- 22.09.05	KR	11682	6	Added RecalculateAll parameter and logic for the foreign currency.
-- 19.12.06	CR	12605	7	Extended Foreign Currency logic to use Historical Exchange Rates
--					when requested.
-- 24.04.07	CR	14653	8	Restore changes made: -Oct-06	PY	12784	Sql92 join syntax
-- 19.09.07	CR	15233	9	Join to TransactionHeader to use EntityNo instead of AcctEntityNo
-- 04.04.14	DL	21640	10	Balance Sheet should be displayed in Account Code order
-- 20 Oct 2015  MS      R53933  11      Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols
-- 31 Jul 2018	DL		R71180	12	Balance amount differences in Balance Sheet Reports

Begin
	SET NOCOUNT ON
	SET CONCAT_NULL_YIELDS_NULL OFF
	
	Declare	@ErrorCode		int
	Declare @nPeriodStart		int
	Declare @nPeriodStartOut	int
	Declare @nTotalProfit		decimal(13,2)
	Declare @nRecalculated		int
	Declare @sSql			nvarchar(4000)
	Declare @sWhere			nvarchar(1000)	
	Declare @sRelAcctTableName	nvarchar(128)

	Set @ErrorCode=0
	Set @sSql=''
	Set @sWhere=''

	Create Table #TEMPACCOUNTS ( 
		ACCOUNTID		int,
		CHARTOFACCOUNTSCODE	nvarchar(20) collate database_default, 
		CHARTOFACCOUNTSDESC	nvarchar(100) collate database_default
	)
	Create Index INDEXACCOUNTID on #TEMPACCOUNTS (ACCOUNTID)

	Insert Into #TEMPACCOUNTS 
	Select LEDGERACCOUNT.ACCOUNTID, LEDGERACCOUNT.ACCOUNTCODE, LEDGERACCOUNT.[DESCRIPTION]
	from LEDGERACCOUNT
	where ACCOUNTTYPE in (8101, 8102, 8103)
		-- R71180 include parent accounts
		--and ACCOUNTID not in (Select PARENTACCOUNTID 
		--			from LEDGERACCOUNT 
		--			where PARENTACCOUNTID is not null) 

	exec @ErrorCode = gl_ArrangeAccountTree @sRelAcctTableName output
	
	--  Get the very first period for the passed entity.
	Set @sSql =	'Select @nPeriodStartOut = Min(TRANPOSTPERIOD)
			from TRANSACTIONHEADER
			join LEDGERJOURNAL on (TRANSACTIONHEADER.ENTITYNO = LEDGERJOURNAL.ENTITYNO
						and TRANSACTIONHEADER.TRANSNO = LEDGERJOURNAL.TRANSNO)
			join LEDGERJOURNALLINE on (LEDGERJOURNALLINE.ENTITYNO = LEDGERJOURNAL.ENTITYNO
						and LEDGERJOURNALLINE.TRANSNO = LEDGERJOURNAL.TRANSNO)'

	If (@pnAcctEntity is not null)
		Set @sSql = @sSql +  ' where LEDGERJOURNALLINE.ACCTENTITYNO = @pnAcctEntity'
	
	exec @ErrorCode = sp_executesql @sSql,
					N'@nPeriodStartOut	int output,
					@pnAcctEntity		int',
					@nPeriodStartOut=@nPeriodStart output,
					@pnAcctEntity=@pnAcctEntity

	If @pbDebug = 1
	Begin
		PRINT @sSql
	End
	
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

		Set @sSql =	'Select att.TABLECODE as ACCOUNT_TYPE_ID, att.DESCRIPTION as ACCOUNT_TYPE_DESC,
					la1.ACCOUNTID as ACCOUNTID_LEVEL1, la1.ACCOUNTCODE AS ACCOUNTCODE_LEVEL1, 
					la1.DESCRIPTION as ACCOUNTDESC_LEVEL1, 
					la2.ACCOUNTID as ACCOUNTID_LEVEL2, la2.ACCOUNTCODE AS ACCOUNTCODE_LEVEL2, 
					la2.DESCRIPTION as ACCOUNTDESC_LEVEL2,
					la3.ACCOUNTID as ACCOUNTID_LEVEL3, la3.ACCOUNTCODE AS ACCOUNTCODE_LEVEL3, 
					la3.DESCRIPTION as ACCOUNTDESC_LEVEL3,
					la4.ACCOUNTID as ACCOUNTID_LEVEL4, la4.ACCOUNTCODE AS ACCOUNTCODE_LEVEL4, 
					la4.DESCRIPTION as ACCOUNTDESC_LEVEL4,
					la5.ACCOUNTID as ACCOUNTID_LEVEL5, la5.ACCOUNTCODE AS ACCOUNTCODE_LEVEL5, 
					la5.DESCRIPTION as ACCOUNTDESC_LEVEL5,
					sum(ISNULL((CASE WHEN @pbRecalculateAll = 0 THEN
					CASE WHEN @psCurrency = jl.CURRENCY THEN
						jl.FOREIGNAMOUNT
					ELSE
						(CASE WHEN @pbUseHistExchRate = 1 THEN
							dbo.fn_GetHistExchRate(tr.TRANSDATE, @psCurrency, @pnExchRateType)
						ELSE
							@pnExchRate 
						END) * jl.LOCALAMOUNT
					END
					ELSE
						(CASE WHEN @pbUseHistExchRate = 1 THEN
							dbo.fn_GetHistExchRate(tr.TRANSDATE, @psCurrency, @pnExchRateType)
						ELSE
							@pnExchRate 
						END) * jl.LOCALAMOUNT
					END)*
					(Case la.ACCOUNTTYPE
						when 8102 then (-1)
						when 8103 then (-1)
						else (1)
					end), 0)) as AMOUNT,
					
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
				FROM #TEMPACCOUNTS a
				INNER JOIN ' + @sRelAcctTableName + ' b ON b.CHILDID = a.ACCOUNTID 
				INNER JOIN LEDGERACCOUNT la1 ON la1.ACCOUNTID = b.LEVEL1 
				INNER JOIN LEDGERACCOUNT la ON la.ACCOUNTID = a.ACCOUNTID
				INNER JOIN TABLECODES att ON att.TABLECODE = la.ACCOUNTTYPE 
				INNER JOIN LEDGERJOURNALLINE jl ON jl.ACCOUNTID = a.ACCOUNTID
				INNER JOIN TRANSACTIONHEADER tr ON tr.ENTITYNO = jl.ENTITYNO AND tr.TRANSNO = jl.TRANSNO 
				LEFT OUTER JOIN LEDGERACCOUNT la2 ON la2.ACCOUNTID = b.LEVEL2
				LEFT OUTER JOIN LEDGERACCOUNT la3 ON la3.ACCOUNTID = b.LEVEL3
				LEFT OUTER JOIN LEDGERACCOUNT la4 ON la4.ACCOUNTID = b.LEVEL4
				LEFT OUTER JOIN LEDGERACCOUNT la5 ON la5.ACCOUNTID = b.LEVEL5
				WHERE (tr.TRANSTATUS = 1) 
				AND (tr.TRANSTYPE <> 812 OR (tr.TRANSTYPE = 812 AND la.ACCOUNTTYPE NOT IN (8104, 8105)))
				AND tr.TRANPOSTPERIOD <= @pnPeriodTo ' + @sWhere + '
				group by att.TABLECODE, att.DESCRIPTION,
				la1.ACCOUNTID , la1.ACCOUNTCODE , la1.DESCRIPTION ,
				la2.ACCOUNTID , la2.ACCOUNTCODE , la2.DESCRIPTION ,
				la3.ACCOUNTID , la3.ACCOUNTCODE , la3.DESCRIPTION ,
				la4.ACCOUNTID , la4.ACCOUNTCODE , la4.DESCRIPTION ,
				la5.ACCOUNTID , la5.ACCOUNTCODE , la5.DESCRIPTION,
				la.ACCOUNTTYPE' 

		If (@nTotalProfit is not null)
			Set @sSql = @sSql + ' UNION ALL
				Select att.TABLECODE AS ACCOUNT_TYPE_ID,
				att.DESCRIPTION As ACCOUNT_TYPE_DESC,
				-1, ''PP'', ''plus Profit'', 
				NULL, NULL, NULL,
				NULL, NULL, NULL,
				NULL, NULL, NULL,
				NULL, NULL, NULL,
				@nTotalProfit, @nRecalculated
				from TABLECODES att
				where att.TABLECODE = 8103'

		--Set @sSql = @sSql + ' order by 1, 5, 8, 11, 14, 17'
		Set @sSql = @sSql + ' order by 1, 4, 7'		--  21640 
		

		exec @ErrorCode = sp_executesql @sSql,
				N'@pnPeriodTo	int,
				@pnAcctEntity	int,
				@psCurrency	nvarchar(3),
				@pnExchRate	decimal(11,4),
				@nTotalProfit	decimal(13,2),
				@nRecalculated	int,
				@pbRecalculateAll	bit,
				@pbUseHistExchRate	bit,
				@pnExchRateType		tinyint',
				@pnPeriodTo=@pnPeriodTo,
				@pnAcctEntity=@pnAcctEntity,
				@psCurrency=@psCurrency,
				@pnExchRate=@pnExchRate,
				@nTotalProfit=@nTotalProfit,
				@nRecalculated=@nRecalculated,
				@pbRecalculateAll=@pbRecalculateAll,
				@pbUseHistExchRate=@pbUseHistExchRate,
				@pnExchRateType=@pnExchRateType
	
		Set @pnRowCount = @@Rowcount

		If @pbDebug = 1
		Begin
			PRINT @sSql
		End

	End

	Drop Table #TEMPACCOUNTS 

	Set @sSql = 'Drop Table ' + @sRelAcctTableName
	Exec @ErrorCode=sp_executesql @sSql
	
	Return @ErrorCode
End

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant Execute on dbo.gl_ListBalanceSheetDetails to public
go
