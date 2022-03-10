-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_ListTrialBalanceSummary
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[gl_ListTrialBalanceSummary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.gl_ListTrialBalanceSummary.'
	drop procedure dbo.gl_ListTrialBalanceSummary
end
print '**** Creating procedure dbo.gl_ListTrialBalanceSummary...'
print ''
go 

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE  PROCEDURE dbo.gl_ListTrialBalanceSummary (
	@pnRowCount		int output,	--Mandatory
	@pnPeriodFrom 		int, 		--Mandatory
	@pnPeriodTo 		int,		--Mandatory
	@pnAcctEntity 		int 		= null, 
	@psAccountIds		nText		= null,	--List of Account IDs
	@pnUserIdentityId	int		= null,	-- included for use by .NET
	@psCulture		nvarchar(10)	= null, -- the language in which output is to be expressed
	@psProfitCentreCode	nvarchar(6) 	= null,
	@psCurrency		nvarchar(3)	= null,	-- the currency the result is to be displayed in
	@pnExchRate		decimal(11,4)	= null,	-- the exchange rate to use when converting to foreign value
	@pnGroupBy		smallint,	--Mandatory - determines the group by columns
	@pbRecalculateAll	bit		= null,	-- determines whether to recalculate to foreign currency
	@pbUseHistExchRate	bit		= null,	-- Indicates whether to use historical exchange rates or not.
	@pnExchRateType		tinyint		= 1,	-- Bank Rate = 1, Buy Rate = 2, Sell Rate = 4
	@pbDebug		bit		= 0
)
AS

-- PROCEDURE:	gl_ListTrialBalanceSummary
-- VERSION:	18
-- DESCRIPTION:	Used in the trial balance report
-- COPYRIGHT:	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
-- Date         Who  	SQA	Version  	Change
-- ------------ ----	---- 	-------- 	------------------------------------------- 
-- 2.5.03	MB				Created
-- 2.5.03	MB				Excluded clearing transactions (812) . See SQA 8385
-- 13.10.03	MB				SQA9181
-- 06.02.04	SS	8857 	3.0.1		Modified to display results in a specific currency
-- 20.02.04	SS	8857	3.0.2		Modified length of currency columns from 6 to 3.
-- 04.08.04	AT	9045	3.1.0		Extended to return summary or detailed results
--						Fixed bugs with calculation of Net Change amounts
-- 12/08/04	AB	8035	3.1.1		Change temp tables to use collate database_default
-- 23/03/05	MB	11141	3.1.2		Output Profit Centre Code and Description separately
-- 07/09/05	KR	11118	3.2.2		Accept more than one Account Id
-- 13/09/05	KR	11016	3.2.2		Group by account
-- 13/09/05	KR	11682	3.2.2		Foreign values to be made available to reports
-- 15/09/05	KR	11118	3.2.2		Made Stored procedure accept XML string for Account IDs
-- 15/09/05	CR	11851	12		Changed the insert logic to also include Details of accounts
--						with an opening balance prior to the selected period.
-- 09/02/06     AT	11966   13		Split gl_ListTrialBalance into 2 stored procs and changed
--						joins to improve performance.
--		AT	11984			Changed to include child accounts when parent account selected.
--		AT	12145			Include 812 P&L Clearing journals for Equity Accounts.
--						Add profit centre filter for Group by Account Only.
-- 08/03/06	AT	11966   14		Fixed bug with Account Only grouping.
-- 19/12/06	CR	12605	15		Extended Foreign Currency logic to use Historical Exchange Rates
--						when requested.
-- 19/09/07	CR	15233	16		Join to TransactionHeader to use EntityNo instead of AcctEntityNo
-- 08/04/13	DL	21300	17		The Year End Rollover transaction are not showing in the Retained Earnings account
-- 20 Oct 2015  MS      R53933  18              Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols

Begin

	SET CONCAT_NULL_YIELDS_NULL OFF

	Declare	@ErrorCode		int
	Declare @sSql			nvarchar(4000)
	Declare @sWhere			nvarchar(4000)
	Declare @sOrderBy		nvarchar(4000)
	Declare @sRelAcctTempTable	nvarchar(128)

	Set @ErrorCode=0
	Set @sSql=''
	Set @sWhere=''
	Set @sOrderBy=''


	Set	@ErrorCode=0

	-- Account Selection 
	CREATE TABLE #LEDGERACCOUNTIDTOQUERY (
		ACCOUNTID int )
	Set @ErrorCode = @@ERROR

	if ((@ErrorCode = 0) AND (@psAccountIds IS NOT NULL))
	Begin
		Exec @ErrorCode = gl_XMLToLedgerAcctTempTable @psLedgerAccountIds=@psAccountIds, 
								@psTempTableName=N'#LEDGERACCOUNTIDTOQUERY'

		-- 11984 Get the child tables for the accounts entered.
		Exec @ErrorCode = gl_TraverseAccount '#LEDGERACCOUNTIDTOQUERY', @sRelAcctTempTable Output
	End


	-- Temp table for the Trial Balance report

	Create Table #TEMPTRIALBALANCE (
		PERIODFROM		int,
		ACCTENTITYNO		int, 
		PROFITCENTRECODE	nvarchar(6)	collate database_default,
		PROFITCENTREDESC	nvarchar(50)	collate database_default,
		ACCOUNTID		int,
		ACCOUNTCODE		nvarchar(100)	collate database_default,
		ACCOUNTDESC		nvarchar(100)	collate database_default,
		OPENBALANCE		decimal(13,2),
		DEBIT			decimal(13,2),
		CREDIT			decimal(13,2),
		NETCHANGE		decimal(13,2),
		CLOSEBALANCE		decimal(13,2),
		RECALCULATED		bit
	)

/*
--		No longer required here as this is stored procedure is for Summary only 
-- 		these columns are only for Detail reports

		TRANSDATE		datetime,
		TRANSTYPE		nvarchar(50)	collate database_default,
		REFERENCE		nvarchar(20)	collate database_default,
		DESCRIPTION		nvarchar(254)	collate database_default,
*/


	-- Set the dynamic filter criteria
	If (@psProfitCentreCode is not null)
	Begin
		Set @sWhere = @sWhere + '
				and jl.PROFITCENTRECODE = ''' + @psProfitCentreCode + ''''
	End

	-- This allows an empty XML document being passed without affecting the results.
	If exists (SELECT * FROM #LEDGERACCOUNTIDTOQUERY)
	Begin
		Set @sWhere = @sWhere + '
				and jl.ACCOUNTID in ( Select CHILDID from ' + @sRelAcctTempTable + ')'
	End
	
	
	If (@pnAcctEntity is not null)	
	Begin
		Set @sWhere = @sWhere + '
				and jl.ACCTENTITYNO = @pnAcctEntity'
	End

	if (@pnExchRate is null or @pnExchRate = 0)
	Begin
		Set @pnExchRate = 1
	End
	

	-- Set the Order and Group By (where necessary) for the Insert Statements
	If (@pnGroupBy = 0) -- Profit Centre/Acct = 0
	Begin
		Set @sOrderBy = @sOrderBy + '
		group by jl.ACCTENTITYNO, pc.PROFITCENTRECODE, pc.[DESCRIPTION], la.ACCOUNTID, la.ACCOUNTCODE, la.[DESCRIPTION]'
	End
	Else If (@pnGroupBy = 1) -- Acct/Profit Centre = 1
	Begin
		Set @sOrderBy = @sOrderBy + '
		group by jl.ACCTENTITYNO, la.ACCOUNTID, la.ACCOUNTCODE, la.[DESCRIPTION], pc.PROFITCENTRECODE, pc.[DESCRIPTION]'
	End
	Else -- Account Only = 2
	Begin
		Set @sOrderBy = @sOrderBy + '
		group by jl.ACCTENTITYNO, la.ACCOUNTID, la.ACCOUNTCODE, la.[DESCRIPTION]'
	End

	
	If (@pnGroupBy = 0) -- Profit Centre/Acct = 0
	Begin
		Set @sOrderBy = @sOrderBy + '
			order by pc.PROFITCENTRECODE, la.ACCOUNTCODE'
	End
	Else If (@pnGroupBy = 1) -- Acct/Profit Centre = 1
	Begin
		Set @sOrderBy = @sOrderBy + '
			order by la.ACCOUNTCODE, pc.PROFITCENTRECODE'
	End
	Else -- Account Only = 2
	Begin
		Set @sOrderBy = @sOrderBy + '
			order by la.ACCOUNTCODE'
	End

	-- Set the Insert Select clause 
	If @ErrorCode = 0
	Begin
		If (@pnGroupBy = 2)  -- Summary, Group By Account Only
		Begin
			Set @sSql = 'Insert Into #TEMPTRIALBALANCE(PERIODFROM, ACCTENTITYNO, ACCOUNTID, ACCOUNTCODE, ACCOUNTDESC, RECALCULATED)
			Select 	@pnPeriodFrom, jl.ACCTENTITYNO, la.ACCOUNTID, la.ACCOUNTCODE, la.[DESCRIPTION],'
		End
		Else
		Begin

			Set @sSql = 'Insert Into #TEMPTRIALBALANCE(PERIODFROM, ACCTENTITYNO, PROFITCENTRECODE, PROFITCENTREDESC, ACCOUNTID, ACCOUNTCODE, ACCOUNTDESC, RECALCULATED)
			Select 	@pnPeriodFrom, jl.ACCTENTITYNO, pc.PROFITCENTRECODE, pc.[DESCRIPTION], la.ACCOUNTID, la.ACCOUNTCODE, la.[DESCRIPTION],'
		End		


		Set @sSql = @sSql + 'MAX(CASE WHEN @pbRecalculateAll = 0 THEN
					CASE WHEN @psCurrency = jl.CURRENCY THEN 0 ELSE 1 END
				ELSE 0 END)'
				
		Set @sSql = @sSql + '
			from LEDGERJOURNAL l
			join LEDGERJOURNALLINE as jl 	on (l.ENTITYNO = jl.ENTITYNO 
							and l.TRANSNO = jl.TRANSNO)
			join LEDGERACCOUNT as la 	on (la.ACCOUNTID = jl.ACCOUNTID)
			join (select ENTITYNO, TRANSNO, TRANSTYPE, TRANSDATE 
				FROM TRANSACTIONHEADER
				WHERE TRANSTATUS = 1

				-- sqa21300 Exclude clearing transactions (812) except the default control account - Retained Earnings
				-- AND TRANSTYPE <> 812 
				
				and TRANPOSTPERIOD between @pnPeriodFrom and @pnPeriodTo)
				as tr on (l.ENTITYNO = tr.ENTITYNO and l.TRANSNO = tr.TRANSNO)
			left join PROFITCENTRE as pc 	on (jl.PROFITCENTRECODE = pc.PROFITCENTRECODE)
			where 1=1 
			-- sqa21300 Exclude clearing transactions (812) except the default control account - Retained Earnings
			and not exists 
				(SELECT *
				FROM LEDGERJOURNALLINE LJL 
				LEFT JOIN DEFAULTACCOUNT DA  ON (DA.ACCOUNTID = LJL.ACCOUNTID AND DA.PROFITCENTRECODE = LJL.PROFITCENTRECODE)  
				WHERE LJL.TRANSNO = jl.TRANSNO
				and LJL.ENTITYNO = jl.ENTITYNO 
				and LJL.SEQNO = jl.SEQNO 
				and tr.TRANSTYPE = 812							-- clearing transactions (812)
				AND isnull(DA.CONTROLACCTYPEID, '''') <> 8707)	-- default control account - Retained Earnings						
			' + @sWhere
		

		-- now add the Order By clause
		Set @sSql = @sSql + @sOrderBy		

		Exec @ErrorCode = sp_executesql @sSql,
						N'@pnPeriodFrom		int,
						@pnPeriodTo		int,
						@pnAcctEntity		int,
						@psCurrency		nvarchar(3),
						@pnExchRate		decimal(11,4),
						@pbRecalculateAll	bit,
						@pbUseHistExchRate	bit,
						@pnExchRateType		tinyint',
						@pnPeriodFrom=@pnPeriodFrom,
						@pnPeriodTo=@pnPeriodTo,
						@pnAcctEntity=@pnAcctEntity,
						@psCurrency=@psCurrency,
						@pnExchRate=@pnExchRate,
						@pbRecalculateAll=@pbRecalculateAll,
						@pbUseHistExchRate=@pbUseHistExchRate,
						@pnExchRateType=@pnExchRateType
		
		Set @pnRowCount = @@Rowcount
		
		If @pbDebug = 1
		Begin
			PRINT 'INSERT ACCOUNT DETAILS WITH MOVEMENT'
			PRINT @sSql
			SELECT * FROM #TEMPTRIALBALANCE
		End

	End

	-- SQA12605 separate update statements for the DEBIT, CREDIT and NETCHANGE figures.
	-- Update DEBIT value
	If (@ErrorCode = 0)
	Begin
	Set @sSql = 'Update #TEMPTRIALBALANCE  
			Set DEBIT = ISNULL(ACCT.DEBIT, 0)
			from #TEMPTRIALBALANCE
			join
			(
			select	jl.ACCTENTITYNO, jl.ACCOUNTID, ISNULL(SUM(CASE WHEN @pbRecalculateAll = 0 THEN
					CASE WHEN @psCurrency = jl.CURRENCY THEN
						CASE WHEN (jl.FOREIGNAMOUNT > 0) THEN ISNULL(jl.FOREIGNAMOUNT, 0) END
					ELSE
						CASE WHEN (jl.LOCALAMOUNT > 0) THEN (CASE WHEN @pbUseHistExchRate = 1 THEN
								dbo.fn_GetHistExchRate(tr.TRANSDATE, @psCurrency, @pnExchRateType)
							Else
								@pnExchRate END) * ISNULL(jl.LOCALAMOUNT,0)
						END
					END
				ELSE
					CASE WHEN (jl.LOCALAMOUNT > 0)
						THEN (CASE WHEN @pbUseHistExchRate = 1 THEN
							dbo.fn_GetHistExchRate(tr.TRANSDATE, @psCurrency, @pnExchRateType)
						Else
							@pnExchRate END) * ISNULL(jl.LOCALAMOUNT,0)
					END
				END), 0) AS DEBIT'
	
		If (@pnGroupBy <> 2)
		Begin
			Set @sSql = @sSql + ', jl.PROFITCENTRECODE'
		End

		Set @sSql = @sSql + '
			from LEDGERJOURNAL l
			join LEDGERJOURNALLINE as jl 	on (l.ENTITYNO = jl.ENTITYNO 
							and l.TRANSNO = jl.TRANSNO)
			join LEDGERACCOUNT as la 	on (la.ACCOUNTID = jl.ACCOUNTID)
			join (select ENTITYNO, TRANSNO, TRANSTYPE, TRANSDATE 
				FROM TRANSACTIONHEADER
				WHERE TRANSTATUS = 1
				-- sqa21300 Exclude clearing transactions (812) except the default control account - Retained Earnings
				--AND TRANSTYPE <> 812 
				and TRANPOSTPERIOD between @pnPeriodFrom and @pnPeriodTo)
				as tr on (l.ENTITYNO = tr.ENTITYNO and l.TRANSNO = tr.TRANSNO)
			left join PROFITCENTRE as pc 	on (jl.PROFITCENTRECODE = pc.PROFITCENTRECODE)
			where 1=1 
			-- sqa21300 Exclude clearing transactions (812) except the default control account - Retained Earnings
			and not exists 
				(SELECT *
				FROM LEDGERJOURNALLINE LJL 
				LEFT JOIN DEFAULTACCOUNT DA  ON (DA.ACCOUNTID = LJL.ACCOUNTID AND DA.PROFITCENTRECODE = LJL.PROFITCENTRECODE)  
				WHERE LJL.TRANSNO = jl.TRANSNO
				and LJL.ENTITYNO = jl.ENTITYNO 
				and LJL.SEQNO = jl.SEQNO 
				and tr.TRANSTYPE = 812							-- clearing transactions (812)
				and isnull(DA.CONTROLACCTYPEID, '''') <> 8707)	-- default control account - Retained Earnings						

			' + @sWhere + '
			group by jl.ACCTENTITYNO'

		If (@pnGroupBy <> 2)
		Begin
			Set @sSql = @sSql + ', jl.PROFITCENTRECODE'
		End

		Set @sSql = @sSql + ', jl.ACCOUNTID) AS ACCT
			on ACCT.ACCOUNTID = #TEMPTRIALBALANCE.ACCOUNTID
			and ACCT.ACCTENTITYNO = #TEMPTRIALBALANCE.ACCTENTITYNO'
		
		If (@pnGroupBy <> 2)
		Begin
			Set @sSql = @sSql + '
				and ISNULL(ACCT.PROFITCENTRECODE,0) = ISNULL(#TEMPTRIALBALANCE.PROFITCENTRECODE,0)'
		End

			Exec @ErrorCode = sp_executesql @sSql,
						N'@pnPeriodFrom		int,
						@pnPeriodTo		int,
						@pnAcctEntity		int,
						@psCurrency		nvarchar(3),
						@pnExchRate		decimal(11,4),
						@pbRecalculateAll	bit,
						@pbUseHistExchRate	bit,
						@pnExchRateType		tinyint',
						@pnPeriodFrom=@pnPeriodFrom,
						@pnPeriodTo=@pnPeriodTo,
						@pnAcctEntity=@pnAcctEntity,
						@psCurrency=@psCurrency,
						@pnExchRate=@pnExchRate,
						@pbRecalculateAll=@pbRecalculateAll,
						@pbUseHistExchRate=@pbUseHistExchRate,
						@pnExchRateType=@pnExchRateType
		
		Set @pnRowCount = @@Rowcount

		If @pbDebug = 1
		Begin
			PRINT 'UPDATE DEBIT values'
			PRINT @sSql
			SELECT * FROM #TEMPTRIALBALANCE
		End

	END


	-- Update CREDIT value
	If (@ErrorCode = 0)
	Begin
	Set @sSql = 'Update #TEMPTRIALBALANCE  
			Set CREDIT = ISNULL(ACCT.CREDIT, 0)
			from #TEMPTRIALBALANCE
			join
			(
			select	jl.ACCTENTITYNO, jl.ACCOUNTID, ISNULL(ABS(SUM(CASE WHEN @pbRecalculateAll = 0 THEN
					CASE WHEN @psCurrency = jl.CURRENCY THEN
						CASE WHEN (jl.FOREIGNAMOUNT < 0)
							THEN ISNULL(jl.FOREIGNAMOUNT, 0)
						END
					ELSE
						CASE WHEN (jl.LOCALAMOUNT < 0)THEN 
							(CASE WHEN @pbUseHistExchRate = 1 THEN
								dbo.fn_GetHistExchRate(tr.TRANSDATE, @psCurrency, @pnExchRateType)
							Else
								@pnExchRate END) * ISNULL(jl.LOCALAMOUNT,0)
						END
					END
				ELSE
					CASE WHEN (jl.LOCALAMOUNT < 0)
						THEN (CASE WHEN @pbUseHistExchRate = 1 THEN
							dbo.fn_GetHistExchRate(tr.TRANSDATE, @psCurrency, @pnExchRateType)
						Else
							@pnExchRate END) * ISNULL(jl.LOCALAMOUNT,0)
					END
				END)), 0) AS CREDIT'
	
		If (@pnGroupBy <> 2)
		Begin
			Set @sSql = @sSql + ', jl.PROFITCENTRECODE'
		End

		Set @sSql = @sSql + '
			from LEDGERJOURNAL l
			join LEDGERJOURNALLINE as jl 	on (l.ENTITYNO = jl.ENTITYNO 
							and l.TRANSNO = jl.TRANSNO)
			join LEDGERACCOUNT as la 	on (la.ACCOUNTID = jl.ACCOUNTID)
			join (select ENTITYNO, TRANSNO, TRANSTYPE, TRANSDATE 
				FROM TRANSACTIONHEADER
				WHERE TRANSTATUS = 1
				-- sqa21300 Exclude clearing transactions (812) except the default control account - Retained Earnings
				-- AND TRANSTYPE <> 812 
				and TRANPOSTPERIOD between @pnPeriodFrom and @pnPeriodTo)
				as tr on (l.ENTITYNO = tr.ENTITYNO and l.TRANSNO = tr.TRANSNO)
			left join PROFITCENTRE as pc 	on (jl.PROFITCENTRECODE = pc.PROFITCENTRECODE)
			where 1=1 
			-- sqa21300 Exclude clearing transactions (812) except the default control account - Retained Earnings
			and not exists 
				(SELECT *
				FROM LEDGERJOURNALLINE LJL 
				LEFT JOIN DEFAULTACCOUNT DA  ON (DA.ACCOUNTID = LJL.ACCOUNTID AND DA.PROFITCENTRECODE = LJL.PROFITCENTRECODE)  
				WHERE LJL.TRANSNO = jl.TRANSNO
				and LJL.ENTITYNO = jl.ENTITYNO 
				and LJL.SEQNO = jl.SEQNO 
				and tr.TRANSTYPE = 812							-- clearing transactions (812)
				and isnull(DA.CONTROLACCTYPEID, '''') <> 8707)	-- default control account - Retained Earnings						
			
			' + @sWhere + '
			group by jl.ACCTENTITYNO'

		If (@pnGroupBy <> 2)
		Begin
			Set @sSql = @sSql + ', jl.PROFITCENTRECODE'
		End

		Set @sSql = @sSql + ', jl.ACCOUNTID) AS ACCT
			on ACCT.ACCOUNTID = #TEMPTRIALBALANCE.ACCOUNTID
			and ACCT.ACCTENTITYNO = #TEMPTRIALBALANCE.ACCTENTITYNO'
		
		If (@pnGroupBy <> 2)
		Begin
			Set @sSql = @sSql + '
				and ISNULL(ACCT.PROFITCENTRECODE,0) = ISNULL(#TEMPTRIALBALANCE.PROFITCENTRECODE,0)'
		End

			Exec @ErrorCode = sp_executesql @sSql,
						N'@pnPeriodFrom		int,
						@pnPeriodTo		int,
						@pnAcctEntity		int,
						@psCurrency		nvarchar(3),
						@pnExchRate		decimal(11,4),
						@pbRecalculateAll	bit,
						@pbUseHistExchRate	bit,
						@pnExchRateType		tinyint',
						@pnPeriodFrom=@pnPeriodFrom,
						@pnPeriodTo=@pnPeriodTo,
						@pnAcctEntity=@pnAcctEntity,
						@psCurrency=@psCurrency,
						@pnExchRate=@pnExchRate,
						@pbRecalculateAll=@pbRecalculateAll,
						@pbUseHistExchRate=@pbUseHistExchRate,
						@pnExchRateType=@pnExchRateType

		Set @pnRowCount = @@Rowcount

		If @pbDebug = 1
		Begin
			PRINT 'UPDATE CREDIT values'		
			PRINT @sSql
			SELECT * FROM #TEMPTRIALBALANCE
		End
		
	END

	-- Update NETCHANGE value
	If (@ErrorCode = 0)
	Begin
	Set @sSql = 'Update #TEMPTRIALBALANCE  
			Set NETCHANGE = ISNULL(ACCT.NETCHANGE, 0)
			from #TEMPTRIALBALANCE
			join
			(
			select	jl.ACCTENTITYNO, jl.ACCOUNTID, (ISNULL(SUM(CASE WHEN @pbRecalculateAll = 0 THEN
					CASE WHEN @psCurrency = jl.CURRENCY THEN
						CASE WHEN (jl.FOREIGNAMOUNT > 0) THEN ISNULL(jl.FOREIGNAMOUNT, 0) END
					ELSE
						CASE WHEN (jl.LOCALAMOUNT > 0)
							THEN (CASE WHEN @pbUseHistExchRate = 1 THEN
								dbo.fn_GetHistExchRate(tr.TRANSDATE, @psCurrency, @pnExchRateType)
							Else
								@pnExchRate END) * ISNULL(jl.LOCALAMOUNT,0)
						END
					END
				ELSE
					CASE WHEN (jl.LOCALAMOUNT > 0)
						THEN (CASE WHEN @pbUseHistExchRate = 1 THEN
							dbo.fn_GetHistExchRate(tr.TRANSDATE, @psCurrency, @pnExchRateType)
						Else
							@pnExchRate END) * ISNULL(jl.LOCALAMOUNT,0)
					END
				END),0) + ISNULL(SUM(CASE WHEN @pbRecalculateAll = 0 THEN
					CASE WHEN @psCurrency = jl.CURRENCY THEN
						CASE WHEN (jl.FOREIGNAMOUNT < 0)
							THEN ISNULL(jl.FOREIGNAMOUNT, 0) END
					ELSE
						CASE WHEN (jl.LOCALAMOUNT < 0)
							THEN (CASE WHEN @pbUseHistExchRate = 1 THEN
								dbo.fn_GetHistExchRate(tr.TRANSDATE, @psCurrency, @pnExchRateType)
							Else
								@pnExchRate END) * ISNULL(jl.LOCALAMOUNT,0)
						END
					END
				ELSE
					CASE WHEN (jl.LOCALAMOUNT < 0)
						THEN (CASE WHEN @pbUseHistExchRate = 1 THEN
							dbo.fn_GetHistExchRate(tr.TRANSDATE, @psCurrency, @pnExchRateType)
						Else
							@pnExchRate END) * ISNULL(jl.LOCALAMOUNT,0)
					END
				END),0)) AS NETCHANGE'
	
		If (@pnGroupBy <> 2)
		Begin
			Set @sSql = @sSql + ', jl.PROFITCENTRECODE'
		End

		Set @sSql = @sSql + '
			from LEDGERJOURNAL l
			join LEDGERJOURNALLINE as jl 	on (l.ENTITYNO = jl.ENTITYNO 
							and l.TRANSNO = jl.TRANSNO)
			join LEDGERACCOUNT as la 	on (la.ACCOUNTID = jl.ACCOUNTID)
			join (select ENTITYNO, TRANSNO, TRANSTYPE, TRANSDATE 
				FROM TRANSACTIONHEADER
				WHERE TRANSTATUS = 1
				-- sqa21300 Exclude clearing transactions (812) except the default control account - Retained Earnings
				--AND TRANSTYPE <> 812 
				and TRANPOSTPERIOD between @pnPeriodFrom and @pnPeriodTo)
				as tr on (l.ENTITYNO = tr.ENTITYNO and l.TRANSNO = tr.TRANSNO)
			left join PROFITCENTRE as pc 	on (jl.PROFITCENTRECODE = pc.PROFITCENTRECODE)
			where 1=1 
			-- sqa21300 Exclude clearing transactions (812) except the default control account - Retained Earnings
			and not exists 
				(SELECT *
				FROM LEDGERJOURNALLINE LJL 
				LEFT JOIN DEFAULTACCOUNT DA  ON (DA.ACCOUNTID = LJL.ACCOUNTID AND DA.PROFITCENTRECODE = LJL.PROFITCENTRECODE)  
				WHERE LJL.TRANSNO = jl.TRANSNO
				and LJL.ENTITYNO = jl.ENTITYNO 
				and LJL.SEQNO = jl.SEQNO 
				and tr.TRANSTYPE = 812							-- clearing transactions (812)
				and isnull(DA.CONTROLACCTYPEID, '''') <> 8707)	-- default control account - Retained Earnings						

			' + @sWhere + '
			group by jl.ACCTENTITYNO'

		If (@pnGroupBy <> 2)
		Begin
			Set @sSql = @sSql + ', jl.PROFITCENTRECODE'
		End

		Set @sSql = @sSql + ', jl.ACCOUNTID) AS ACCT
			on ACCT.ACCOUNTID = #TEMPTRIALBALANCE.ACCOUNTID
			and ACCT.ACCTENTITYNO = #TEMPTRIALBALANCE.ACCTENTITYNO'
		
		If (@pnGroupBy <> 2)
		Begin
			Set @sSql = @sSql + '
				and ISNULL(ACCT.PROFITCENTRECODE,0) = ISNULL(#TEMPTRIALBALANCE.PROFITCENTRECODE,0)'
		End

			Exec @ErrorCode = sp_executesql @sSql,
						N'@pnPeriodFrom		int,
						@pnPeriodTo		int,
						@pnAcctEntity		int,
						@psCurrency		nvarchar(3),
						@pnExchRate		decimal(11,4),
						@pbRecalculateAll	bit,
						@pbUseHistExchRate	bit,
						@pnExchRateType		tinyint',
						@pnPeriodFrom=@pnPeriodFrom,
						@pnPeriodTo=@pnPeriodTo,
						@pnAcctEntity=@pnAcctEntity,
						@psCurrency=@psCurrency,
						@pnExchRate=@pnExchRate,
						@pbRecalculateAll=@pbRecalculateAll,
						@pbUseHistExchRate=@pbUseHistExchRate,
						@pnExchRateType=@pnExchRateType
		
		Set @pnRowCount = @@Rowcount

		If @pbDebug = 1
		Begin
			PRINT 'UPDATE NETCHANGE values'		
			PRINT @sSql
			SELECT * FROM #TEMPTRIALBALANCE
		End

	END

	--** SQA12605 **--

	-- Insert a single row for Accounts that had an opening balance prior to the selected period but have
	-- had no movement in the selected period i.e. not included in the previous insert statement.
	If @ErrorCode = 0
	Begin

		If (@pnGroupBy = 2) -- Account Only = 2
		Begin
			Set @sSql = 'Insert Into #TEMPTRIALBALANCE(
						PERIODFROM,
						ACCTENTITYNO,
						ACCOUNTID,
						ACCOUNTCODE,
						ACCOUNTDESC,
						RECALCULATED)
			Select 	distinct @pnPeriodFrom, 
				jl.ACCTENTITYNO,
				la.ACCOUNTID, 
				la.ACCOUNTCODE, 
				la.[DESCRIPTION],'
		End
		Else
		Begin
			Set @sSql = 'Insert Into #TEMPTRIALBALANCE(
						PERIODFROM,
						ACCTENTITYNO,
						PROFITCENTRECODE,
						PROFITCENTREDESC,
						ACCOUNTID,
						ACCOUNTCODE,
						ACCOUNTDESC,
						RECALCULATED)
			Select 	distinct @pnPeriodFrom, 
				jl.ACCTENTITYNO,
				pc.PROFITCENTRECODE, 
				pc.[DESCRIPTION],
				la.ACCOUNTID, 
				la.ACCOUNTCODE, 
				la.[DESCRIPTION],'
		End


		Set @sSql = @sSql + '
				MAX(CASE WHEN @pbRecalculateAll = 0 THEN
					CASE WHEN @psCurrency = jl.CURRENCY THEN 0
					ELSE 1
					END
				ELSE 0
				END)
			from LEDGERACCOUNT la 
			join LEDGERJOURNALLINE as jl	on (jl.ACCOUNTID = la.ACCOUNTID)
			join TRANSACTIONHEADER as tr	on (tr.ENTITYNO = jl.ENTITYNO 
							and tr.TRANSNO = jl.TRANSNO)'
		If (@pnGroupBy <> 2) 
		Begin
			Set @sSql = @sSql + '
			left join PROFITCENTRE as pc 	on (jl.PROFITCENTRECODE = pc.PROFITCENTRECODE)'
		End

		Set @sSql = @sSql + '
			where tr.TRANSTATUS = 1' + @sWhere + ' 
			and tr.TRANPOSTPERIOD < @pnPeriodFrom
			and NOT EXISTS (SELECT 1
					FROM #TEMPTRIALBALANCE TEMP
					WHERE TEMP.ACCTENTITYNO = jl.ACCTENTITYNO
					AND TEMP.ACCOUNTID = jl.ACCOUNTID'
		
		
		If (@pnGroupBy <> 2)
		Begin
		-- Only join the profit centre if it's included in the grouping, 
		-- otherwise these not exist rows will not be excluded.
			Set @sSql = @sSql + '
					AND TEMP.PROFITCENTRECODE = jl.PROFITCENTRECODE'
		End

		-- now add the Order By clause
		Set @sSql = @sSql + ')' + @sOrderBy		

		Exec @ErrorCode = sp_executesql @sSql,
						N'@pnPeriodFrom		int,
						@pnAcctEntity		int,
						@psCurrency		nvarchar(3),
						@pnExchRate		decimal(11,4),
						@pbRecalculateAll	bit',
						@pnPeriodFrom=@pnPeriodFrom,
						@pnAcctEntity=@pnAcctEntity,
						@psCurrency=@psCurrency,
						@pnExchRate=@pnExchRate,
						@pbRecalculateAll=@pbRecalculateAll
		
		Set @pnRowCount = @@Rowcount

		If @pbDebug = 1
		Begin
			PRINT 'INSERT ACCOUNT DETAILS WITH OPENING BALANCE ONLY'
			PRINT @sSql
			SELECT * FROM #TEMPTRIALBALANCE
		End

	End



	-- Update opening balance for all accounts
	If (@ErrorCode = 0)
	Begin
	Set @sSql = 'Update #TEMPTRIALBALANCE  
			Set OPENBALANCE = ISNULL(BAL.OPENINGBALANCE, 0)
			from #TEMPTRIALBALANCE
			join
			(
			select	jl.ACCTENTITYNO, jl.ACCOUNTID, ISNULL(SUM(
				CASE WHEN @pbRecalculateAll = 0 THEN
					CASE WHEN @psCurrency = jl.CURRENCY THEN
						ISNULL(jl.FOREIGNAMOUNT, 0)
					ELSE
						(CASE WHEN @pbUseHistExchRate = 1 THEN
							dbo.fn_GetHistExchRate(tr.TRANSDATE, @psCurrency, @pnExchRateType)
						Else
							@pnExchRate 
						END) * ISNULL(jl.LOCALAMOUNT,0)
					END
				ELSE
					(CASE WHEN @pbUseHistExchRate = 1 THEN
						dbo.fn_GetHistExchRate(tr.TRANSDATE, @psCurrency, @pnExchRateType)
					Else
						@pnExchRate 
					END) * ISNULL(jl.LOCALAMOUNT,0)
				END
			), 0) AS OPENINGBALANCE'
	
		If (@pnGroupBy <> 2)
		Begin
			Set @sSql = @sSql + ', jl.PROFITCENTRECODE'
		End

		Set @sSql = @sSql + '
			from LEDGERACCOUNT as la
			join LEDGERJOURNALLINE jl	on (jl.ACCOUNTID = la.ACCOUNTID)
			join TRANSACTIONHEADER tr	on (tr.ENTITYNO = jl.ENTITYNO 
							and tr.TRANSNO = jl.TRANSNO)
			where tr.TRANPOSTPERIOD < @pnPeriodFrom
			AND 	( 	(tr.TRANSTYPE <> 812 
					AND Left(Cast(tr.TRANPOSTPERIOD as VARCHAR), 4) = Left(Cast(@pnPeriodFrom as VARCHAR), 4)
					AND la.ACCOUNTTYPE in (8104, 8105))
				or
					(la.ACCOUNTTYPE in (8101, 8102, 8103))
				)
			' + @sWhere + '
			group by jl.ACCTENTITYNO'

		If (@pnGroupBy <> 2)
		Begin
			Set @sSql = @sSql + ', jl.PROFITCENTRECODE'
		End

		Set @sSql = @sSql + ', jl.ACCOUNTID) AS BAL
			on BAL.ACCOUNTID = #TEMPTRIALBALANCE.ACCOUNTID
			and BAL.ACCTENTITYNO = #TEMPTRIALBALANCE.ACCTENTITYNO'
		
		If (@pnGroupBy <> 2)
		Begin
			Set @sSql = @sSql + '
				and ISNULL(BAL.PROFITCENTRECODE,0) = ISNULL(#TEMPTRIALBALANCE.PROFITCENTRECODE,0)'
		End

			Exec @ErrorCode = sp_executesql @sSql,
						N'@pbRecalculateAll	bit,
						@psCurrency		nvarchar(3),
						@pnExchRate		decimal(11,4),
						@pnPeriodFrom		int,
						@pnAcctEntity		int,
						@pbUseHistExchRate	bit,
						@pnExchRateType		tinyint',
						@pbRecalculateAll=@pbRecalculateAll,
						@psCurrency=@psCurrency,
						@pnExchRate=@pnExchRate,
						@pnPeriodFrom=@pnPeriodFrom,
						@pnAcctEntity=@pnAcctEntity,
						@pbUseHistExchRate=@pbUseHistExchRate,
						@pnExchRateType=@pnExchRateType
		
		Set @pnRowCount = @@Rowcount

		If @pbDebug = 1
		Begin
			PRINT 'UPDATE OPENING BALANCES'
			PRINT @sSql
			SELECT * FROM #TEMPTRIALBALANCE
		End

	END

	If (@ErrorCode = 0)
	Begin
		Set @sSql = 'Update #TEMPTRIALBALANCE
		Set OPENBALANCE = 0
		WHERE OPENBALANCE is null'
		
		Exec @ErrorCode = sp_executesql @sSql
		
		Set @pnRowCount = @@Rowcount


		If @pbDebug = 1
		Begin
			PRINT 'SET NULL OPENING BALANCES TO 0'
			PRINT @sSql	
			SELECT * FROM #TEMPTRIALBALANCE
		End

	End

	-- Calculate the closing balance for each row
	If (@ErrorCode = 0)
	Begin
		Set @sSql = 'Update #TEMPTRIALBALANCE 
		Set CLOSEBALANCE = ISNULL(CB.CLOSEBALANCE, 0)'
		If (@pnGroupBy = 2)
		Begin
			Set @sSql = @sSql + '
			from (SELECT ACCTENTITYNO, ACCOUNTID, (OPENBALANCE + SUM(ISNULL(NETCHANGE, 0))) AS CLOSEBALANCE
				from #TEMPTRIALBALANCE
				group by ACCTENTITYNO, ACCOUNTID, OPENBALANCE) AS CB
		where #TEMPTRIALBALANCE.ACCTENTITYNO = CB.ACCTENTITYNO'
		End
		Else
		Begin
			Set @sSql = @sSql + '
			from (SELECT ACCTENTITYNO, PROFITCENTRECODE, ACCOUNTID, (OPENBALANCE + SUM(ISNULL(NETCHANGE, 0))) AS CLOSEBALANCE
				from #TEMPTRIALBALANCE
				group by ACCTENTITYNO, PROFITCENTRECODE, ACCOUNTID, OPENBALANCE) AS CB
		where #TEMPTRIALBALANCE.ACCTENTITYNO = CB.ACCTENTITYNO
		and #TEMPTRIALBALANCE.PROFITCENTRECODE = CB.PROFITCENTRECODE'
		End

		Set @sSql = @sSql + '
				and #TEMPTRIALBALANCE.ACCOUNTID = CB.ACCOUNTID'

		Exec @ErrorCode = sp_executesql @sSql
		
		Set @pnRowCount = @@Rowcount

		If @pbDebug = 1
		Begin
			PRINT 'UPDATE CLOSING BALANCES'
			PRINT @sSql
			SELECT * FROM #TEMPTRIALBALANCE
		End

	End

	-- delete any rows where all figures = 0 or NULL 
	If (@ErrorCode = 0)
	Begin
		Set @sSql = 'Delete 
		From #TEMPTRIALBALANCE
		Where (OPENBALANCE = 0 OR OPENBALANCE IS NULL)
		and (DEBIT = 0 OR DEBIT IS NULL)
		and (CREDIT = 0 OR CREDIT IS NULL)
		and (NETCHANGE = 0 OR NETCHANGE IS NULL)
		and (CLOSEBALANCE = 0 OR CLOSEBALANCE IS NULL)'
		
		Exec @ErrorCode = sp_executesql @sSql
		
		Set @pnRowCount = @@Rowcount


		If @pbDebug = 1
		Begin
			PRINT 'DELETE ROWS WHERE OPENING BALANCE IS 0 OR NULL'
			PRINT @sSql
			SELECT * FROM #TEMPTRIALBALANCE
		End
	End


	-- Return results
	-- Reuse the orderby local variable
	If (@ErrorCode = 0)
	Begin

		If (@pnGroupBy = 2)
		Begin
			Set @sOrderBy = 'order by ACCOUNTCODE'
		End
		Else If (@pnGroupBy = 1)
		Begin
			Set @sOrderBy = 'order by ACCOUNTCODE, PROFITCENTREDESC'
		End
		Else
		Begin
			Set @sOrderBy = 'order by PROFITCENTREDESC, ACCOUNTCODE'
		End


		Set @sSql = 'Select PROFITCENTRECODE, PROFITCENTREDESC,
				 + ''{'' + ACCOUNTCODE + ''} ''+ ACCOUNTDESC, 
				OPENBALANCE,
				DEBIT,
				CREDIT,
				NETCHANGE,
				CLOSEBALANCE,
				RECALCULATED
				from #TEMPTRIALBALANCE
				' + @sOrderBy	


		Exec @ErrorCode = sp_executesql @sSql
		
		Set @pnRowCount = @@Rowcount

		If @pbDebug = 1
		Begin
			PRINT 'RETURN RESULTS'
			PRINT @sSql
		End

	End


	DROP TABLE #TEMPTRIALBALANCE
	DROP TABLE #LEDGERACCOUNTIDTOQUERY

	If @sRelAcctTempTable is not null
	Begin
		set @sSql  = 'Drop Table ' + @sRelAcctTempTable
		Exec sp_executesql @sSql
	End

	Return @ErrorCode
End
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.gl_ListTrialBalanceSummary to public
GO
