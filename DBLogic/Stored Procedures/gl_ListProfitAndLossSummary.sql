-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_ListProfitAndLossSummary
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[gl_ListProfitAndLossSummary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.gl_ListProfitAndLossSummary'
	drop procedure dbo.gl_ListProfitAndLossSummary
end
print '**** Creating procedure dbo.gl_ListProfitAndLossSummary...'
print ''
go 

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE  PROCEDURE dbo.gl_ListProfitAndLossSummary
(
	@pnRowCount		int output,
	@pnPeriodFrom 		int, 
	@pnPeriodTo 		int,
	@pnAcctEntity  		int		= null, 
	@pnUserIdentityId	int		= null,	-- included for use by .NET
	@psCulture		nvarchar(10)	= null, -- the language in which output is to be expressed
	@psProfitCentreCodes 	ntext		= null ,
	@psCurrency		nvarchar(3)	= null,	-- the currency the result is to be displayed in
	@pnExchRate		decimal(11,4)	= null,	-- the exchange rate to use when converting to foreign value
	@pbRecalculateAll	bit		= null,	-- determines whether to recalculate to foreign currency
	@pbUseHistExchRate	bit		= null,	-- Indicates whether to use historical exchange rates or not.
	@pnExchRateType		tinyint		= 1,	-- Bank Rate = 1, Buy Rate = 2, Sell Rate = 4
	@pbDebug		bit		= 0
)
AS

-- PROCEDURE:	gl_ListProfitAndLossSummary
-- VERSION:	15
-- DESCRIPTION:	Provides information for Summary Profit and Loss report
-- CALLED BY:	Centura
-- DEPENDENICIES: gl_TraverseAccount
-- COPYRIGHT:	Copyright 1993 - 2011 CPA Software Solutions (Australia) Pty Limited
-- Date         Who  	SQA#	Version  	Change
-- ------------ ----	---- 	-------- 	------------------------------------------- 
-- 7.5.03	MB				Created
-- 6.6.03	MB 				Removed ABS function and replaced it with (-1) from Income
-- 27.03.08	MB	SQA8803
-- 13.10.03	MB	SQA9181
-- 06.02.04	SS	SQA8857 3.0.1		Modified to display results in a specific currency
-- 17.02.04	SFOO	SQA8851 3.0.2		Modified call to gl_TraverseAccount and change ##TEMPACCOUNTS
--						table to local #TEMPACCOUNTS table.
-- 20.02.04	SS	SQA8857	3.0.2		Modified length of currency columns from 6 to 3.
-- 13.09.05	KR	11682	8		Foreign values to be made available to reports
-- 22.09.05	KR	11682	9		Added parameter for RecalculateAll and logic for the same.
-- 24/03/05	AT	12005	10		Added gl_GetTotalAmountByType functionality for profit centre totalling
--						Revised transact-SQL joins to standard joins.
-- 19/12/06	CR	12605	11		Extended Foreign Currency logic to use Historical Exchange Rates
--						when requested.
-- 19/09/07	CR	14722	12		Change @psProfitCentreCodes to ntext and added code to convert back to
--						nvarchar(2000)
-- 27/09/07	CR	14722	13	 	trying to reduce the size of the sql statement produced.
-- 28/07/11	CR	19827	14		Change the sort order to use AccountCode instead of Description
-- 20 Oct 2015  MS      R53933  15              Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols

Begin

	SET CONCAT_NULL_YIELDS_NULL OFF

	Declare	@ErrorCode		int
	Declare @sSql			nvarchar(4000)
	Declare @sWhere			nvarchar(4000)
	Declare @sRelAcctTempTable 	nvarchar(128)
	Declare @sProfitCentreCodes	nvarchar(2000)

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
		and ACCOUNTTYPE in (8104, 8105)

	Set @ErrorCode=@@Error
	
	Set @sProfitCentreCodes = CAST(@psProfitCentreCodes AS nvarchar(2000))

	If (@ErrorCode = 0)
		exec @ErrorCode = gl_TraverseAccount '#TEMPACCOUNTS', @sRelAcctTempTable Output

	If (@pnAcctEntity is not null)
		Set @sWhere = ' and jl.ACCTENTITYNO = @pnAcctEntity'

	if (@pnExchRate is null or @pnExchRate = 0)
		Begin
			Set @pnExchRate = 1
		End

	If (@sProfitCentreCodes is null) or (@sProfitCentreCodes = '')
		Set @sSql = 'Select NULL, NULL, NULL, NULL, att.[DESCRIPTION] as ACCOUNT_TYPE_DESC,' 
		+char(10)+'la.ACCOUNTID, la.ACCOUNTCODE, la.[DESCRIPTION] as ACCOUNT_DESC,' 
		+char(10)+'sum(ISNULL((CASE WHEN @pbRecalculateAll = 0 THEN' 
		+char(10)+'	CASE WHEN @psCurrency = jl.CURRENCY THEN jl.FOREIGNAMOUNT ELSE' 
		+char(10)+'		(CASE WHEN @pbUseHistExchRate = 1 THEN' 
		+char(10)+'			dbo.fn_GetHistExchRate(tr.TRANSDATE, @psCurrency, @pnExchRateType)' 
		+char(10)+'		Else @pnExchRate END) * jl.LOCALAMOUNT END' 
		+char(10)+'ELSE
				(CASE WHEN @pbUseHistExchRate = 1 THEN' 
		+char(10)+'		dbo.fn_GetHistExchRate(tr.TRANSDATE, @psCurrency, @pnExchRateType)' 
		+char(10)+'	Else @pnExchRate END) * jl.LOCALAMOUNT' 
		+char(10)+'END)* (CASE la.ACCOUNTTYPE WHEN 8104 THEN (-1) ELSE (1) END),0)) AS AMOUNT,' 
		+char(10)+'CASE WHEN(SUM(CASE WHEN @pbRecalculateAll = 0 THEN' 
		+char(10)+'	CASE WHEN @psCurrency = jl.CURRENCY THEN 0 ELSE 1 END' 
		+char(10)+'ELSE 0 END)) > 0 THEN 1 ELSE 0 END' 
		+char(10)+'from #TEMPACCOUNTS a' 
		+char(10)+'join ' + @sRelAcctTempTable + ' b on (a.ACCOUNTID = b.PARENTID)' 
		+char(10)+'join LEDGERACCOUNT la on (la.ACCOUNTID = a.ACCOUNTID)' 
		+char(10)+'join TABLECODES att on (att.TABLECODE = la.ACCOUNTTYPE)' 
		+char(10)+'join LEDGERJOURNALLINE jl on (jl.ACCOUNTID = b.CHILDID)' 
		+char(10)+'join TRANSACTIONHEADER tr on (tr.ENTITYNO = jl.ENTITYNO and tr.TRANSNO = jl.TRANSNO)' 
		+char(10)+'where tr.TRANSTYPE <> 812' 
		+char(10)+'and tr.TRANSTATUS = 1' 
		+char(10)+'and tr.TRANPOSTPERIOD between @pnPeriodFrom and @pnPeriodTo ' + @sWhere + ' 
			group by att.[DESCRIPTION], la.ACCOUNTID, la.ACCOUNTCODE, la.[DESCRIPTION], la.ACCOUNTTYPE' 
		+char(10)+'order by att.[DESCRIPTION] DESC, la.ACCOUNTCODE'
	Else
		Set @sSql = 'Select pc.PROFITCENTRECODE, pc.[DESCRIPTION] as PROFITCENTRE_DESC, pctotal.PCTOTAL, pctotal.PCRECALCFLAG,' 
		+char(10)+'att.[DESCRIPTION] as ACCOUNT_TYPE_DESC, la.ACCOUNTID, la.ACCOUNTCODE, la.[DESCRIPTION] as ACCOUNT_DESC,' 
		+char(10)+'sum(ISNULL((CASE WHEN @pbRecalculateAll = 0 THEN' 
		+char(10)+'	CASE WHEN @psCurrency = jl.CURRENCY THEN jl.FOREIGNAMOUNT ELSE' 
		+char(10)+'		(CASE WHEN @pbUseHistExchRate = 1 THEN' 
		+char(10)+'			dbo.fn_GetHistExchRate(tr.TRANSDATE, @psCurrency, @pnExchRateType)' 
		+char(10)+'		Else @pnExchRate END) * jl.LOCALAMOUNT END ELSE' 
		+char(10)+'	(CASE WHEN @pbUseHistExchRate = 1 THEN' 
		+char(10)+'		dbo.fn_GetHistExchRate(tr.TRANSDATE, @psCurrency, @pnExchRateType)' 
		+char(10)+'	Else @pnExchRate END) * jl.LOCALAMOUNT' 
		+char(10)+'END)* (CASE la.ACCOUNTTYPE WHEN 8104 THEN (-1) ELSE (1) END),0)) as AMOUNT,' 
		+char(10)+'CASE WHEN(SUM(CASE WHEN @pbRecalculateAll = 0 THEN' 
		+char(10)+'	CASE WHEN @psCurrency = jl.CURRENCY THEN 0 ELSE 1 END ELSE 0 END)) > 0 ' 
		+char(10)+'THEN 1 ELSE 0 END' 
		+char(10)+'from #TEMPACCOUNTS a' 
		+char(10)+'join ' + @sRelAcctTempTable + ' b on (a.ACCOUNTID = b.PARENTID)' 
		+char(10)+'join LEDGERACCOUNT la on (la.ACCOUNTID = a.ACCOUNTID)' 
		+char(10)+'join TABLECODES att on (att.TABLECODE = la.ACCOUNTTYPE)' 
		+char(10)+'join LEDGERJOURNALLINE jl on (jl.ACCOUNTID = b.CHILDID)' 
		+char(10)+'join PROFITCENTRE pc on (pc.PROFITCENTRECODE = jl.PROFITCENTRECODE)' 
		+char(10)+'join (Select Sum(ISNULL((CASE WHEN @pbRecalculateAll = 0 THEN' 
		+char(10)+'		CASE WHEN @psCurrency = jl.CURRENCY THEN jl.FOREIGNAMOUNT ELSE' 
		+char(10)+'			(CASE WHEN @pbUseHistExchRate = 1 THEN' 
		+char(10)+'				dbo.fn_GetHistExchRate(tr.TRANSDATE, @psCurrency, @pnExchRateType)' 
		+char(10)+'			Else @pnExchRate END) * jl.LOCALAMOUNT END ELSE' 
		+char(10)+'		(CASE WHEN @pbUseHistExchRate = 1 THEN' 
		+char(10)+'			dbo.fn_GetHistExchRate(tr.TRANSDATE, @psCurrency, @pnExchRateType)' 
		+char(10)+'		Else @pnExchRate END) * jl.LOCALAMOUNT END), 0)) * -1 as PCTOTAL,' 
		+char(10)+'	Sum(CASE WHEN @pbRecalculateAll = 0 THEN' 
		+char(10)+'		CASE WHEN @psCurrency = jl.CURRENCY THEN 0 ELSE 1 END' 
		+char(10)+'	ELSE 0 END) as PCRECALCFLAG, jl.PROFITCENTRECODE' 
		+char(10)+'	from LEDGERACCOUNT la' 
		+char(10)+'	join LEDGERJOURNALLINE jl on (la.ACCOUNTID = jl.ACCOUNTID)' 
		+char(10)+'	join TRANSACTIONHEADER tr on (tr.ENTITYNO = jl.ENTITYNO and tr.TRANSNO = jl.TRANSNO )' 
		+char(10)+'	where tr.TRANSTATUS = 1 ' 
		+char(10)+'	and tr.TRANSTYPE <> 812' 
		+char(10)+'	and jl.PROFITCENTRECODE in ( ' +  @sProfitCentreCodes + ' )' 
		+char(10)+'	and la.ACCOUNTTYPE IN ( 8105, 8104 )' 
		+char(10)+'	and tr.TRANPOSTPERIOD between @pnPeriodFrom and @pnPeriodTo ' + @sWhere + '' 
		+char(10)+'	group by jl.PROFITCENTRECODE) ' 
		+char(10)+'AS pctotal on (pctotal.PROFITCENTRECODE = pc.PROFITCENTRECODE)' 
		+char(10)+'join TRANSACTIONHEADER tr on (tr.ENTITYNO = jl.ENTITYNO and tr.TRANSNO = jl.TRANSNO)' 
		+char(10)+'where tr.TRANSTYPE <> 812' 
		+char(10)+'and tr.TRANSTATUS = 1' 
		+char(10)+'and pc.PROFITCENTRECODE in ( ' +  @sProfitCentreCodes + ' )' 
		+char(10)+'and tr.TRANPOSTPERIOD between @pnPeriodFrom and @pnPeriodTo ' + @sWhere + '
			group by att.[DESCRIPTION], pc.PROFITCENTRECODE, pc.[DESCRIPTION], la.ACCOUNTID , la.ACCOUNTCODE, la.[DESCRIPTION],' 
		+char(10)+'la.ACCOUNTTYPE, pctotal.PCTOTAL, pctotal.PCRECALCFLAG' 
		+char(10)+'order by pc.[DESCRIPTION], att.[DESCRIPTION] DESC, la.ACCOUNTCODE'

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
		PRINT @sSql
	End

	Drop Table #TEMPACCOUNTS 

	Set @sSql = 'Drop Table ' + @sRelAcctTempTable
	Exec sp_executesql @sSql

	Return @ErrorCode
End
GO

grant execute on dbo.gl_ListProfitAndLossSummary to public
GO
