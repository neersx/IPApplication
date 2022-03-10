-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_ListProfitAndLossDetails
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[gl_ListProfitAndLossDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.gl_ListProfitAndLossDetails.'
	drop procedure dbo.gl_ListProfitAndLossDetails
end
print '**** Creating procedure dbo.gl_ListProfitAndLossDetails...'
print ''
go 

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.gl_ListProfitAndLossDetails
(
	@pnRowCount		int output,
	@pnPeriodFrom 		int, 
	@pnPeriodTo 		int,
	@pnAcctEntity  		int		= null, 
	@pnUserIdentityId	int		= null,	-- included for use by .NET
	@psCulture		nvarchar(10)	= null, -- the language in which output is to be expressed
	@psProfitCentre		ntext	 	= null,
	@psCurrency		nvarchar(3)	= null,	-- the currency the result is to be displayed in
	@pnExchRate		decimal(11,4)	= null,	-- the exchange rate to use when converting to foreign value
	@pbRecalculateAll	bit		= null,	-- determines whether to recalculate to foreign currency
	@pbUseHistExchRate	bit		= null,	-- Indicates whether to use historical exchange rates or not.
	@pnExchRateType		tinyint		= 1,	-- Bank Rate = 1, Buy Rate = 2, Sell Rate = 4
	@pbDebug		bit		= 0
)
AS
-- PROCEDURE:	gl_ListProfitAndLossDetails
-- DESCRIPTION:	Provides information for Details Profit and Loss report
-- VERSION: 	18
-- CALLED BY:	Centura
-- DEPENDENICIES: gl_ArrangeAccountTree
-- COPYRIGHT:	Copyright 1993 - 2011 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 7.5.03	MB			Created
-- 6.6.03	MB 			Removed ABS function and replaced it with (-1) from Income
-- 27.08.03	MB	8803
-- 13.10.03	MB	9181
-- 06.02.04	SS	8857 	3.0.1	Modified to display results in a specific currency
-- 20.02.04	SS	8857	3.0.2	Modified length of currency columns from 6 to 3.
-- 01.03.04	SFOO	9614 	3.0.3	Modified to cater for variable and unique related account 
--					global temporary table name returned by gl_ArrangeAccountTree.
-- 06 Aug 2004	AB	8035	9	Add collate database_default to temp table definitions
-- 13.09.05	KR	11682	10	Foreign values to be made available to reports
-- 22.09.05	KR	11682	11	Added parameter for RecalculateAll and logic for the same
-- 24/03/05	AT	12005	12	Added gl_GetTotalAmountByType functionality for profit centre totalling
--					Revised transact-SQL joins to standard joins.
-- 19/12/06	CR	12605	13	Extended Foreign Currency logic to use Historical Exchange Rates
--					when requested.
-- 19/09/07	CR	14722	14	Change @psProfitCentreCodes to ntext and added code to convert back to
--					nvarchar(2000)
-- 27/09/07	CR	14722	15 	trying to reduce the size of the sql statement produced.
-- 28/07/11	CR	19827	14	Change the sort order to use AccountCode instead of Description and to include all 5 levels
-- 20 Oct 2015  MS      R53933  17      Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols
-- 11 Jul 2018	DL		R72999	18	P&L Report run with the Consolidation option is repeating GL Codes

Begin

	SET CONCAT_NULL_YIELDS_NULL OFF

	Declare	@ErrorCode		int
	Declare @sSql			nvarchar(4000)
	Declare @sWhere			nvarchar(4000)
	Declare @sRelAcctTableName 	nvarchar(128)
	Declare @bUseProfitCentre	bit
	Declare @sProfitCentreCodes	nvarchar(2000)

	Set @ErrorCode=0
	Set @sSql=''
	Set @sWhere=''


	Create Table #TEMPPROFITANDLOSS (
		PROFITCENTRECODE	nvarchar(6)	collate database_default,
		PROFITCENTREDESC	nvarchar(50)	collate database_default,
		PCTOTAL			decimal(13,2),
		PCTOTRECALCULATED	bit,	
		ACCTENTITYNO		int,
		ACCOUNTTYPEDESC		nvarchar(80)	collate database_default,	
		ACCOUNTID1		int,
		ACCOUNTCODE1		nvarchar(100)	collate database_default,
		ACCOUNTDESC1		nvarchar(100)	collate database_default,
		ACCOUNTID2		int,
		ACCOUNTCODE2		nvarchar(100)	collate database_default,
		ACCOUNTDESC2		nvarchar(100)	collate database_default,
		ACCOUNTID3		int,
		ACCOUNTCODE3		nvarchar(100)	collate database_default,
		ACCOUNTDESC3		nvarchar(100)	collate database_default,
		ACCOUNTID4		int,
		ACCOUNTCODE4		nvarchar(100)	collate database_default,
		ACCOUNTDESC4		nvarchar(100)	collate database_default,
		ACCOUNTID5		int,
		ACCOUNTCODE5		nvarchar(100)	collate database_default,
		ACCOUNTDESC5		nvarchar(100)	collate database_default,
		AMOUNT			decimal(13,2),
		RECALCULATED		bit
	)

	Create Table #TEMPACCOUNTS ( 
		ACCOUNTID		int, 
		CHARTOFACCOUNTSCODE	nvarchar(20) collate database_default, 
		CHARTOFACCOUNTSDESC	nvarchar(100) collate database_default
	)
	Create Index INDEXACCOUNTID on #TEMPACCOUNTS (ACCOUNTID)

	Insert Into #TEMPACCOUNTS
	Select LEDGERACCOUNT.ACCOUNTID, LEDGERACCOUNT.ACCOUNTCODE, LEDGERACCOUNT.[DESCRIPTION]
	from LEDGERACCOUNT
	where ACCOUNTTYPE in (8104, 8105)
		and ACCOUNTID not in (Select PARENTACCOUNTID 
		 			from LEDGERACCOUNT 
					where PARENTACCOUNTID is not null) 

	Set @ErrorCode=@@Error
	
	Set @sProfitCentreCodes = CAST(@psProfitCentre AS nvarchar(2000))

	If (@ErrorCode = 0)
		exec @ErrorCode = gl_ArrangeAccountTree @sRelAcctTableName output


	if (@pnExchRate is null or @pnExchRate = 0)
	Begin
		Set @pnExchRate = 1
	End


	If (@sProfitCentreCodes is null) or (@sProfitCentreCodes = '')
		Set @bUseProfitCentre = 0
	Else
		Set @bUseProfitCentre = 1


	Set @sSql ='INSERT INTO #TEMPPROFITANDLOSS (PROFITCENTRECODE, PCTOTAL, PCTOTRECALCULATED, ACCOUNTTYPEDESC,' 
		+char(10)+'ACCTENTITYNO, ACCOUNTID1, ACCOUNTID2, ACCOUNTID3,ACCOUNTID4, ACCOUNTID5, AMOUNT, RECALCULATED)' 
		+char(10)+'Select '

	-- R72999 consolidated report not require to select the entity column ACCTENTITYNO
	If @bUseProfitCentre = 1
		Set @sSql = @sSql + '
		pc.PROFITCENTRECODE, pctotal.PCTOTAL, pctotal.PCRECALCFLAG, att.[DESCRIPTION] as ACCOUNT_TYPE_DESC, jl.ACCTENTITYNO,'
	Else
		Set @sSql = @sSql + ' 
		NULL, NULL, NULL, att.[DESCRIPTION] as ACCOUNT_TYPE_DESC, NULL,'


	--Set @sSql = @sSql + 'att.[DESCRIPTION] as ACCOUNT_TYPE_DESC, jl.ACCTENTITYNO,' 
	Set @sSql = @sSql +'b.LEVEL1 as ACCTID1, b.LEVEL2 as ACCTID2, b.LEVEL3 as ACCTID3, b.LEVEL4 as ACCTID4, b.LEVEL5 as ACCTID5, ' 
		+char(10)+'sum(ISNULL((CASE WHEN @pbRecalculateAll = 0 THEN' 
		+char(10)+'CASE WHEN @psCurrency = jl.CURRENCY THEN jl.FOREIGNAMOUNT ELSE' 
		+char(10)+'((CASE WHEN @pbUseHistExchRate = 1 THEN' 
		+char(10)+'	dbo.fn_GetHistExchRate(tr.TRANSDATE, @psCurrency, @pnExchRateType)' 
		+char(10)+'Else @pnExchRate END) * jl.LOCALAMOUNT ) END' 
		+char(10)+'ELSE (CASE WHEN @pbUseHistExchRate = 1 THEN' 
		+char(10)+'dbo.fn_GetHistExchRate(tr.TRANSDATE, @psCurrency, @pnExchRateType)' 
		+char(10)+'Else @pnExchRate END) * jl.LOCALAMOUNT END)* ' 
		+char(10)+'(CASE la.ACCOUNTTYPE WHEN 8104 THEN (-1)' 
		+char(10)+'else (1) end),0)) as AMOUNT,' 
		+char(10)+'case when(sum(CASE WHEN @pbRecalculateAll = 0 THEN' 
		+char(10)+'CASE WHEN @psCurrency = jl.CURRENCY THEN 0 ELSE 1 END ELSE 0 END)) > 0 THEN 1 ELSE 0 END' 
		+char(10)+'from #TEMPACCOUNTS a' 
		+char(10)+'join ' + @sRelAcctTableName + ' b on (b.CHILDID = a.ACCOUNTID)' 
		+char(10)+'join LEDGERACCOUNT la on (la.ACCOUNTID = a.ACCOUNTID)' 
		+char(10)+'join LEDGERACCOUNT la1 on (la1.ACCOUNTID = b.LEVEL1)' 
		+char(10)+'join TABLECODES att on (att.TABLECODE = la.ACCOUNTTYPE)' 
		+char(10)+'join LEDGERJOURNALLINE jl on (jl.ACCOUNTID = a.ACCOUNTID)' 
		+char(10)+'join PROFITCENTRE pc on (pc.PROFITCENTRECODE = jl.PROFITCENTRECODE)'

	If @bUseProfitCentre = 1 
		Set @sSql = @sSql + 'join (Select Sum(ISNULL((CASE WHEN @pbRecalculateAll = 0 THEN' 
		+char(10)+'CASE WHEN @psCurrency = jl.CURRENCY THEN jl.FOREIGNAMOUNT ELSE' 
		+char(10)+'	(CASE WHEN @pbUseHistExchRate = 1 THEN' 
		+char(10)+'		dbo.fn_GetHistExchRate(tr.TRANSDATE, @psCurrency, @pnExchRateType)' 
		+char(10)+'	Else @pnExchRate END) * jl.LOCALAMOUNT END ELSE' 
		+char(10)+'	(CASE WHEN @pbUseHistExchRate = 1 THEN' 
		+char(10)+'		dbo.fn_GetHistExchRate(tr.TRANSDATE, @psCurrency, @pnExchRateType)' 
		+char(10)+'	Else @pnExchRate END) * jl.LOCALAMOUNT END), 0)) * -1 as PCTOTAL,' 
		+char(10)+'Sum(CASE WHEN @pbRecalculateAll = 0 THEN' 
		+char(10)+'	CASE WHEN @psCurrency = jl.CURRENCY THEN 0 ELSE 1 END' 
		+char(10)+'ELSE 0 END) as PCRECALCFLAG, jl.PROFITCENTRECODE' 
		+char(10)+'from LEDGERACCOUNT la' 
		+char(10)+'join LEDGERJOURNALLINE jl on (la.ACCOUNTID = jl.ACCOUNTID)' 
		+char(10)+'join TRANSACTIONHEADER tr on (tr.ENTITYNO = jl.ENTITYNO and tr.TRANSNO = jl.TRANSNO )' 
		+char(10)+'where tr.TRANSTATUS = 1 ' 
		+char(10)+'and tr.TRANSTYPE <> 812' 
		+char(10)+'and jl.PROFITCENTRECODE in ( ' +  @sProfitCentreCodes + ' )' 
		+char(10)+'and la.ACCOUNTTYPE IN ( 8105, 8104 )' 
		+char(10)+'and tr.TRANPOSTPERIOD between @pnPeriodFrom and @pnPeriodTo ' 
		+char(10)+'and jl.ACCTENTITYNO = @pnAcctEntity' 
		+char(10)+'group by jl.PROFITCENTRECODE) ' 
		+char(10)+'AS pctotal	on (pctotal.PROFITCENTRECODE = pc.PROFITCENTRECODE)'

	Set @sSql = @sSql + 'join TRANSACTIONHEADER tr on (tr.ENTITYNO = jl.ENTITYNO and tr.TRANSNO = jl.TRANSNO)' 
		+char(10)+'where tr.TRANSTATUS = 1' 
		+char(10)+'and tr.TRANSTYPE <> 812' 
		+char(10)+'and tr.TRANPOSTPERIOD between @pnPeriodFrom and @pnPeriodTo'
	If (@pnAcctEntity is not null)
		Set @sSql = @sSql + ' 
		and jl.ACCTENTITYNO = @pnAcctEntity' 

	If @bUseProfitCentre = 1  
		Set @sSql = @sSql + '
		and pc.PROFITCENTRECODE in ( ' +  @sProfitCentreCodes + ' )'

-- Add Group By and Order By Clause
	If @bUseProfitCentre = 1  
		Set @sSql = @sSql + 'group by jl.ACCTENTITYNO, att.[DESCRIPTION], pc.PROFITCENTRECODE, b.LEVEL1, b.LEVEL2, b.LEVEL3, ' 
		+char(10)+'b.LEVEL4, b.LEVEL5, la.ACCOUNTTYPE, pctotal.PCTOTAL, pctotal.PCRECALCFLAG'
	Else
		-- R72999 consolidated report not require to select the entity column ACCTENTITYNO
		Set @sSql = @sSql + '
		group by  att.[DESCRIPTION], b.LEVEL1, b.LEVEL2, b.LEVEL3, b.LEVEL4, b.LEVEL5, la.ACCOUNTTYPE'
		--group by jl.ACCTENTITYNO, att.[DESCRIPTION], b.LEVEL1, b.LEVEL2, b.LEVEL3, b.LEVEL4, b.LEVEL5, la.ACCOUNTTYPE'

	If (@ErrorCode = 0)
		exec @ErrorCode = sp_executesql @sSql,
						N'@pnPeriodFrom		int,
						@pnPeriodTo		int,
						@pnAcctEntity		int,
						@sProfitCentreCodes	nvarchar(2000),
						@psCurrency		nvarchar(3),
						@pnExchRate		decimal(11,4),
						@pbRecalculateAll	bit,
						@pbUseHistExchRate	bit,
						@pnExchRateType		tinyint',
						@pnPeriodFrom=@pnPeriodFrom,
						@pnPeriodTo=@pnPeriodTo,
						@pnAcctEntity=@pnAcctEntity,
						@sProfitCentreCodes=@sProfitCentreCodes,
						@psCurrency=@psCurrency,
						@pnExchRate=@pnExchRate,
						@pbRecalculateAll=@pbRecalculateAll,
						@pbUseHistExchRate=@pbUseHistExchRate,
						@pnExchRateType=@pnExchRateType

	Set @pnRowCount = @@Rowcount

	If @pbDebug = 1
	Begin
		PRINT '** INSERT STATEMENT **'
		PRINT @sSql
	End
		SET @sSql = 'UPDATE #TEMPPROFITANDLOSS' 
		+char(10)+'SET PROFITCENTREDESC = pc.DESCRIPTION, ' 
		+char(10)+'ACCOUNTCODE1 = la1.ACCOUNTCODE, ACCOUNTDESC1 = la1.DESCRIPTION, ' 
		+char(10)+'ACCOUNTCODE2 = la2.ACCOUNTCODE, ACCOUNTDESC2 = la2.DESCRIPTION,' 
		+char(10)+'ACCOUNTCODE3 = la3.ACCOUNTCODE, ACCOUNTDESC3 = la3.DESCRIPTION,' 
		+char(10)+'ACCOUNTCODE4 = la4.ACCOUNTCODE, ACCOUNTDESC4 = la4.DESCRIPTION,' 
		+char(10)+'ACCOUNTCODE5 = la5.ACCOUNTCODE, ACCOUNTDESC5 = la5.DESCRIPTION' 
		+char(10)+'FROM #TEMPPROFITANDLOSS TPL' 
		+char(10)+'left join PROFITCENTRE pc	on (pc.PROFITCENTRECODE = TPL.PROFITCENTRECODE)' 
		-- R72999 PROFITCENTRE.PROFITCENTRECODE is the primary key so not require to join by ACCTENTITYNO
		--+char(10)+'				and pc.ENTITYNO = TPL.ACCTENTITYNO)' 
		+char(10)+'left join LEDGERACCOUNT la1	on (la1.ACCOUNTID = TPL.ACCOUNTID1)' 
		+char(10)+'left join LEDGERACCOUNT la2	on (la2.ACCOUNTID = TPL.ACCOUNTID2)' 
		+char(10)+'left join LEDGERACCOUNT la3	on (la3.ACCOUNTID = TPL.ACCOUNTID3)' 
		+char(10)+'left join LEDGERACCOUNT la4	on (la4.ACCOUNTID = TPL.ACCOUNTID4)' 
		+char(10)+'left join LEDGERACCOUNT la5	on (la5.ACCOUNTID = TPL.ACCOUNTID5)'


	If (@ErrorCode = 0)
		exec @ErrorCode = sp_executesql @sSql

	Set @pnRowCount = @@Rowcount

	If @pbDebug = 1
	Begin
		PRINT '** UPDATE STATEMENT **'
		PRINT @sSql
	End

	Set @sSql = 'Select PROFITCENTRECODE, PROFITCENTREDESC, PCTOTAL, PCTOTRECALCULATED,' 
		+char(10)+'ACCOUNTTYPEDESC, ACCOUNTID1, ACCOUNTCODE1, ACCOUNTDESC1, ' 
		+char(10)+'ACCOUNTID2, ACCOUNTCODE2, ACCOUNTDESC2, ACCOUNTID3, ACCOUNTCODE3, ACCOUNTDESC3,' 
		+char(10)+'ACCOUNTID4, ACCOUNTCODE4, ACCOUNTDESC4, ACCOUNTID5, ACCOUNTCODE5, ACCOUNTDESC5,' 
		+char(10)+'AMOUNT, RECALCULATED' 
		+char(10)+'from #TEMPPROFITANDLOSS'

	-- Add Group By and Order By Clause
	If @bUseProfitCentre = 1  
		Set @sSql = @sSql + '
		order by PROFITCENTREDESC, ACCOUNTTYPEDESC DESC, ACCOUNTCODE1, ACCOUNTCODE2, ACCOUNTCODE3, ACCOUNTCODE4, ACCOUNTCODE5'
	Else
		Set @sSql = @sSql + '
		order by ACCOUNTTYPEDESC DESC, ACCOUNTCODE1, ACCOUNTCODE2, ACCOUNTCODE3, ACCOUNTCODE4, ACCOUNTCODE5'

	If @pbDebug = 1
	Begin
		PRINT '** STATEMENT USED TO RETURN THE RESULTS **'
		PRINT @sSql
	End

	Exec @ErrorCode = sp_executesql @sSql
	
	Set @pnRowCount = @@Rowcount


	Drop Table #TEMPACCOUNTS
	
	Drop Table #TEMPPROFITANDLOSS

	Set @sSql = 'Drop Table ' + @sRelAcctTableName
	Exec @ErrorCode=sp_executesql @sSql

	Return @ErrorCode
End
GO

grant execute on dbo.gl_ListProfitAndLossDetails to public
GO
