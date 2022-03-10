-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_ListAccountBalance
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[gl_ListAccountBalance]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.gl_ListAccountBalance.'
	drop procedure dbo.gl_ListAccountBalance
end
print '**** Creating procedure dbo.gl_ListAccountBalance...'
print ''
go

CREATE PROCEDURE dbo.gl_ListAccountBalance
(
	@pnRowCount			int output,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnAcctEntity 			int, 
	@psProfitCentres 		ntext		= null,
	@psAccountIds 			ntext		= null, -- 10821 changed from nvarchar(3000)
	@psAccounts 			ntext		= null, -- 10821 additional to cater for simplier 
								-- account enquiries
	@pnPeriodFrom 			int, 
	@pnPeriodTo 			int, 
	@pnMovBalanceInd 		int, 			-- 1 movement, 2 - balance
	@pnAnalysisTypeId		int 		= null,
	@psAnalysisCodeIds		ntext		= null
)
AS
-- PROCEDURE :	gl_ListAccountBalance
-- VERSION :	8
-- DESCRIPTION:	List ledger account balances for the specified criteria
-- CALLED BY :	FCDBLedgerJournalLineX (Centura), gl_PrepareAccountSummary, gl_ListAutoFillCopyAmounts,
--		gl_ListAcctBudgetEntryDetails

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 5.5.03	MB			Created
-- 5.5.03	MB 			Excluded clearing transactions (812) . See SQA 8385
-- 6.6.03	MB 			Included type 812 for Assets, Equity and Liability
-- 27.08.03	MB	8803
-- 01.09.03	SFOO			Incorporate Profit Centre Analysis. See SQA8805
-- 07/10/2003	AB			Reformat for Clear Case generation
-- 13/01/2004	SFOO			Allow large number of ledger account ids by using XML to temp table
-- 11.02.04	SFOO	9614		Change the way gl_TraverseAccount is called so that an unique global temp table 
--					is kept at this level. To prevent one or more user assessing the same global temp
--					table. Also removed the CURSOR for looping distinct periodids.
-- 05 Aug 2004	AB	8035	1	Add collate database_default to temp table definitions
-- 04 Feb 2005	CR	10821	2	Changed the Account Id list received from comma separted list to XML
-- 14 Feb 2005	MB	10554	3	Changed the select statement to be account type independent
-- 15 Feb 2005	CR	10821	4	Now may be used with either a comma separated list or an XML document of Account Ids.
--					So that this is backwards compatible with the other stored procedures that call it.
-- 19 Sep 2007	CR	14722	5	Change @psProfitCentreCodes, @psAccounts and @psAnalysisCodeIds to ntext and added code 
--					to convert back to nvarchar before subsequently using.
-- 08 Apr 2013	DL	21300	6	The Year End Rollover transaction are not showing in the Retained Earnings account
-- 27 Feb 2014	DL	S21508	7	Change variables and temp table columns that reference namecode to 20 characters
-- 30 Nov 2016	DL	70011	8	Account Balance is including balance from previous financial years incorrectly


Begin
	DECLARE @sSql 			nvarchar(4000)
	DECLARE @nPeriod 		int
	DECLARE	@ErrorCode		int
	DECLARE @sRelAcctTempTable	nvarchar(128)
	DECLARE @sProfitCentres 	nvarchar(2000)
	DECLARE @sAccounts 		nvarchar(3000)
	DECLARE @sAnalysisCodeIds	nvarchar(1000)
	
	
	Set	@ErrorCode=0

	Set @sProfitCentres = CAST( @psProfitCentres AS nvarchar(2000))
	If (@sProfitCentres = '')
		Set @sProfitCentres = NULL

	Set @sAccounts = CAST(@psAccounts AS nvarchar(3000))
	If (@sAccounts = '')
		Set @sAccounts = NULL

	Set @sAnalysisCodeIds = CAST(@psAnalysisCodeIds as nvarchar(1000))
	If (@sAnalysisCodeIds = '')
		Set @sAnalysisCodeIds = NULL

	CREATE TABLE #LEDGERACCOUNTIDTOQUERY (
		Value int )

	Set @ErrorCode = @@ERROR
	
	if @ErrorCode = 0
	begin
		CREATE TABLE #TEMPACCOUNTS ( 
			NAMENO 			Int, 
			NAMECODE 		varchar(20) collate database_default, 
			NAME 			varchar(254) collate database_default,
			PROFITCENTRECODE 	varchar(6) collate database_default, 
			PROFITCENTREDESC 	varchar(50) collate database_default,
			ACCOUNTID 		Int, 
			CHARTOFACCOUNTSCODE 	nvarchar(20) collate database_default, 
			CHARTOFACCOUNTSDESC 	nvarchar(100) collate database_default,
			PERIODID 		Int, 
			PERIODLABEL 		varchar(20) collate database_default)
		Set @ErrorCode = @@ERROR
	end

	if @ErrorCode = 0
	begin
		CREATE INDEX ind_TEMPACCOUNTSID
		ON #TEMPACCOUNTS ( ACCOUNTID ) 
		Set @ErrorCode = @@ERROR
	end

	if @ErrorCode = 0
	begin
		CREATE INDEX ind_TEMPACCOUNTSPERIODID
		ON #TEMPACCOUNTS ( PERIODID ) 
		Set @ErrorCode = @@ERROR
	end

	if @ErrorCode = 0
	begin
		CREATE TABLE #TEMPBALANCE ( 
			NAMENO 			Int, 
			NAMECODE 		varchar(20) collate database_default, 
			NAME 			varchar(254) collate database_default,
			PROFITCENTRECODE 	varchar(6) collate database_default, 
			PROFITCENTREDESC 	varchar(50) collate database_default,
			ACCOUNTID 		Int, 
			CHARTOFACCOUNTSCODE 	nvarchar(20) collate database_default, 
			CHARTOFACCOUNTSDESC 	nvarchar(100) collate database_default,
			PERIODID 		Int, 
			PERIODLABEL 		varchar(20) collate database_default, 
			AMOUNT 			dec(13,2)) 
		Set @ErrorCode = @@ERROR
	end

	if ((@ErrorCode = 0) AND (@psAccountIds IS NOT NULL))
	Begin
		Exec @ErrorCode = gl_XMLToLedgerAcctTempTable @psLedgerAccountIds=@psAccountIds, 
								@psTempTableName=N'#LEDGERACCOUNTIDTOQUERY'
	End
	Else If ((@ErrorCode = 0) AND (@sAccounts IS NOT NULL))
	Begin
		Exec @ErrorCode = gl_ListToLedgerAcctTempTable @psLedgerAccountIds=@sAccounts, 
								@psTempTableName=N'#LEDGERACCOUNTIDTOQUERY'
	End

	if @ErrorCode = 0
	Begin	
	  if @sProfitCentres is NOT NULL
		Set @sSql = '
			INSERT 
					INTO #TEMPACCOUNTS 
			SELECT 		N.NAMENO, N.NAMECODE, N.NAME,
	 				PC.PROFITCENTRECODE, PC.DESCRIPTION,
					LA.ACCOUNTID, LA.ACCOUNTCODE, LA.DESCRIPTION,
					P.PERIODID, P.LABEL 

			FROM 
					NAME N
						CROSS JOIN
					PROFITCENTRE PC
						CROSS JOIN
					#LEDGERACCOUNTIDTOQUERY LATQ
						INNER JOIN
					LEDGERACCOUNT LA ON (LA.ACCOUNTID = LATQ.Value)
						CROSS JOIN
					PERIOD P
			WHERE 
					N.NAMENO = ' + CAST (@pnAcctEntity AS varchar(20)) + ' AND 
					PC.PROFITCENTRECODE IN (' + @sProfitCentres + ' ) AND 
					P.PERIODID >= '  + CAST ( @pnPeriodFrom AS varchar(20)) + ' AND 
					P.PERIODID <=' + CAST (@pnPeriodTo AS varchar(20))
	  else
		Set @sSql = '
			INSERT 
					INTO #TEMPACCOUNTS 
			SELECT 		N.NAMENO, N.NAMECODE, N.NAME,
	 				PC.PROFITCENTRECODE, PC.DESCRIPTION,
					LA.ACCOUNTID, LA.ACCOUNTCODE, LA.DESCRIPTION,
					P.PERIODID, P.LABEL 
			FROM 
					NAME N
						CROSS JOIN
					PROFITCENTRE PC
						CROSS JOIN
					#LEDGERACCOUNTIDTOQUERY LATQ
						INNER JOIN
					LEDGERACCOUNT LA ON (LA.ACCOUNTID = LATQ.Value)
						CROSS JOIN
					PERIOD P
			WHERE 
					N.NAMENO = ' + CAST (@pnAcctEntity AS varchar(20)) + ' AND 
					PC.ENTITYNO = ' + CAST (@pnAcctEntity AS varchar(20)) + ' AND
					P.PERIODID >= '  + CAST ( @pnPeriodFrom AS varchar(20)) + ' AND 
					P.PERIODID <=' + CAST (@pnPeriodTo AS varchar(20))			
	  exec sp_executesql @sSql
	  set @ErrorCode=@@Error
	End
	
	if @ErrorCode = 0
		exec @ErrorCode = gl_TraverseAccount '#TEMPACCOUNTS', @sRelAcctTempTable OUTPUT

	if @ErrorCode = 0
	begin
		if @pnMovBalanceInd = 1 -- Movement
		begin
			Set @sSql = N'SELECT ' + 
					dbo.fn_IncludeProfitCentreAnalysis(@sProfitCentres,
									    @pnAnalysisTypeId,
									    @sAnalysisCodeIds,
									    N'SELECT',
									    NULL) +
					N' dt.NAMENO, dt.NAMECODE, dt.NAME,
					dt.PROFITCENTRECODE, dt.PROFITCENTREDESC,
					dt.ACCOUNTID, dt.CHARTOFACCOUNTSCODE, dt.CHARTOFACCOUNTSDESC,
					dt.PERIODID, dt.PERIODLABEL , dt.AMOUNT
				      FROM (
					SELECT 
					  a.NAMENO, a.NAMECODE, a.NAME,
					  a.PROFITCENTRECODE, a.PROFITCENTREDESC,
					  a.ACCOUNTID, a.CHARTOFACCOUNTSCODE, a.CHARTOFACCOUNTSDESC,
					  a.PERIODID, a.PERIODLABEL , SUM(LOCALAMOUNT) AS AMOUNT
			 		FROM 
					  #TEMPACCOUNTS  a, ' + @sRelAcctTempTable + ' b , 
					  TRANSACTIONHEADER tr, LEDGERJOURNALLINE jl,
					  LEDGERACCOUNT la
			 		WHERE 
					  a.ACCOUNTID = b.PARENTID AND 
					  tr.ENTITYNO = jl.ENTITYNO AND 
					  tr.TRANSNO = jl.TRANSNO AND 
					  a.NAMENO = jl.ACCTENTITYNO AND 
					  jl.ACCOUNTID = la.ACCOUNTID AND 
					  a.PROFITCENTRECODE = jl.PROFITCENTRECODE AND 
					  b.CHILDID = jl.ACCOUNTID AND 
					  a.PERIODID = tr.TRANPOSTPERIOD AND 

					  -- sqa21300 Exclude clearing transactions (812) except the default control account - Retained Earnings
					 -- (tr.TRANSTYPE <> 812 OR (tr.TRANSTYPE = 812 AND 
						--			la.ACCOUNTTYPE NOT IN (8104,8105))
						--OR (tr.TRANSTYPE = 812 AND tr.TRANPOSTPERIOD != a.PERIODID)) AND 
					 (not exists 
						(SELECT *
						FROM LEDGERJOURNALLINE LJL 
						LEFT JOIN DEFAULTACCOUNT DA  ON (DA.ACCOUNTID = LJL.ACCOUNTID AND DA.PROFITCENTRECODE = LJL.PROFITCENTRECODE)  
						WHERE LJL.TRANSNO = jl.TRANSNO
						and LJL.ENTITYNO = jl.ENTITYNO 
						and LJL.SEQNO = jl.SEQNO 
						and tr.TRANSTYPE = 812							-- clearing transactions (812)
						AND isnull(DA.CONTROLACCTYPEID, '''') <> 8707)	-- default control account - Retained Earnings						
					  
						OR (tr.TRANSTYPE = 812 AND la.ACCOUNTTYPE NOT IN (8104,8105))
						OR (tr.TRANSTYPE = 812 AND tr.TRANPOSTPERIOD != a.PERIODID)) AND  
						
					  tr.TRANSTATUS = 1 
					GROUP BY 
					  a.NAMENO, a.NAMECODE, a.NAME,
					  a.PROFITCENTRECODE, a.PROFITCENTREDESC,
					  a.ACCOUNTID, a.CHARTOFACCOUNTSCODE, a.CHARTOFACCOUNTSDESC,
					  a.PERIODID, a.PERIODLABEL
					) dt ' + dbo.fn_IncludeProfitCentreAnalysis(@sProfitCentres,
										    @pnAnalysisTypeId,
										    @sAnalysisCodeIds,
										    N'FROM',
										    N'dt.PROFITCENTRECODE') +
					N'ORDER BY ' + dbo.fn_IncludeProfitCentreAnalysis(@sProfitCentres,
											  @pnAnalysisTypeId,
											  @sAnalysisCodeIds,
											  N'ORDER',
											  NULL) +
					N' dt.NAME, dt.PROFITCENTREDESC, dt.CHARTOFACCOUNTSDESC, dt.PERIODID '
			
			exec sp_executesql @sSql
			
			Set @pnRowCount = @@Rowcount
			set @ErrorCode=@@Error
		end
		else
		begin
			SELECT @nPeriod=MIN(a.PERIODID)
			FROM #TEMPACCOUNTS a
			Set @ErrorCode = @@ERROR

			WHILE (@nPeriod is not NULL AND @ErrorCode = 0)
			begin
				Set @sSql = N'	
					INSERT INTO #TEMPBALANCE (
						NAMENO, NAMECODE, NAME,
						PROFITCENTRECODE, PROFITCENTREDESC,
						ACCOUNTID, CHARTOFACCOUNTSCODE, CHARTOFACCOUNTSDESC,
						PERIODID, PERIODLABEL, AMOUNT )
					SELECT 
						a.NAMENO,  a.NAMECODE, a.NAME,
						a.PROFITCENTRECODE, a.PROFITCENTREDESC,
						a.ACCOUNTID, a.CHARTOFACCOUNTSCODE, a.CHARTOFACCOUNTSDESC,
						a.PERIODID, a.PERIODLABEL , SUM(LOCALAMOUNT)  
		 			FROM 
						#TEMPACCOUNTS  a, ' + @sRelAcctTempTable + ' b , 
						TRANSACTIONHEADER tr, LEDGERJOURNALLINE jl 
					WHERE 
						a.ACCOUNTID = b.PARENTID AND 
						tr.ENTITYNO = jl.ENTITYNO AND 
						tr.TRANSNO = jl.TRANSNO AND 
						a.NAMENO = jl.ACCTENTITYNO AND 
						a.PROFITCENTRECODE = jl.PROFITCENTRECODE AND 
						b.CHILDID = jl.ACCOUNTID AND 
						a.PERIODID = @nPeriod AND 
						tr.TRANPOSTPERIOD <= a.PERIODID AND 
						
						-- sqa21300 Exclude clearing transactions (812) except the default control account - Retained Earnings
						--(tr.TRANSTYPE <> 812 OR (tr.TRANSTYPE = 812 AND 
						--tr.TRANPOSTPERIOD != a.PERIODID))  AND 
						(not exists 
						(SELECT *
						FROM LEDGERJOURNALLINE LJL 
						LEFT JOIN DEFAULTACCOUNT DA  ON (DA.ACCOUNTID = LJL.ACCOUNTID AND DA.PROFITCENTRECODE = LJL.PROFITCENTRECODE)  
						WHERE LJL.TRANSNO = jl.TRANSNO
						and LJL.ENTITYNO = jl.ENTITYNO 
						and LJL.SEQNO = jl.SEQNO 
						and tr.TRANSTYPE = 812							-- clearing transactions (812)
						AND isnull(DA.CONTROLACCTYPEID, '''') <> 8707)	-- default control account - Retained Earnings						
					  
						OR (tr.TRANSTYPE = 812 AND tr.TRANPOSTPERIOD != a.PERIODID)) AND  
						
						tr.TRANSTATUS = 1 
					GROUP BY 
						a.NAMENO, a.NAME, a.NAMECODE, 
						a.PROFITCENTRECODE, a.PROFITCENTREDESC,
						a.ACCOUNTID, a.CHARTOFACCOUNTSCODE, a.CHARTOFACCOUNTSDESC,
						a.PERIODID, a.PERIODLABEL'

				Exec @ErrorCode=sp_executesql @sSql, N'@nPeriod Int', @nPeriod 
		
				If @ErrorCode = 0
				begin
					Set @sSql = 'SELECT @nPeriod=MIN(a.PERIODID)
							FROM #TEMPACCOUNTS a
							WHERE a.PERIODID > @nPreviousPeriodId'
					Exec @ErrorCode=sp_executesql @sSql,
									N'@nPeriod int output,
									  @nPreviousPeriodId int',
									@nPeriod output,
									@nPeriod
				end	
			end

			Set @sSql = N'SELECT ' + 
					dbo.fn_IncludeProfitCentreAnalysis(@sProfitCentres,
									    @pnAnalysisTypeId,
									    @sAnalysisCodeIds,
									    N'SELECT',
									    NULL) +	
				     N' tb.NAMENO, tb.NAMECODE,	tb.NAME,
				        tb.PROFITCENTRECODE, tb.PROFITCENTREDESC,
					tb.ACCOUNTID, tb.CHARTOFACCOUNTSCODE, tb.CHARTOFACCOUNTSDESC,
					tb.PERIODID, tb.PERIODLABEL, 
					tb.AMOUNT
				      FROM #TEMPBALANCE tb ' + 
					dbo.fn_IncludeProfitCentreAnalysis(@sProfitCentres,
									   @pnAnalysisTypeId,
			 						   @sAnalysisCodeIds,
						  			   N'FROM',
			 						   N'tb.PROFITCENTRECODE') +
				  N' ORDER BY ' + dbo.fn_IncludeProfitCentreAnalysis(@sProfitCentres,
			 	    						     @pnAnalysisTypeId,
			 	    						     @sAnalysisCodeIds,
			 	    						     N'ORDER',
			 							     NULL) +
				  N' tb.NAME, tb.PROFITCENTREDESC, tb.CHARTOFACCOUNTSDESC, tb.PERIODID '

			exec @ErrorCode=sp_executesql @sSql
			Set @pnRowCount = @@Rowcount
				
			DROP TABLE #TEMPBALANCE
		end
	end

	DROP TABLE #TEMPACCOUNTS
	DROP TABLE #LEDGERACCOUNTIDTOQUERY 

	Set @sSql = N'DROP TABLE ' + @sRelAcctTempTable
	Exec @ErrorCode=sp_executesql @sSql

	RETURN @ErrorCode
End
go

/*
To Test:
Exec dbo.gl_ListAccountBalance @Row, null, null, -283575757, "'TM'", NULL, '10', 200201, 200312, 0, NULL, NULL
*/

grant execute on dbo.gl_ListAccountBalance to public
go

