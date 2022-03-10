-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_ListAccountComparison
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[gl_ListAccountComparison]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.gl_ListAccountComparison.'
	drop procedure dbo.gl_ListAccountComparison
end
print '**** Creating procedure dbo.gl_ListAccountComparison...'
print ''
go

CREATE  PROCEDURE dbo.gl_ListAccountComparison (
	@pnRowCount			int output,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnAcctEntity 			int, 
	@psProfitCentreCodes 		ntext	 	= null,
	@psAccountIds 			ntext, 			-- 10821 changed from nvarchar(3000)
	@pnPeriodFrom 			int, 
	@pnPeriodTo 			int, 
	@pnMovBalanceInd 		int,
	@pnAnalysisTypeId		int 		= null,
	@psAnalysisCodeIds		ntext		= null
)
AS
-- PROCEDURE :	gl_ListAccountComparison
-- VERSION :	11
-- DESCRIPTION:	Compare ledger balance or movement entries in the specified criteria
-- CALLED BY :	FCDBLedgerJournalLineX (Centura)

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 2.5.03	MB			Created
-- 2.5.03	MB 	8385		Excluded clearing transactions (812)
-- 6.6.03	MB 			Included type 812 for Assets, Equity and Liability
-- 27.08.03	MB	8803
-- 01.09.03	SFOO			Incorporate Profit Centre Analysis to sort results.
-- 13.01.04	SFOO	9445		Allow large number of ledger account ids by using XML to temp table
-- 11.02.04	SFOO	9614		Change the way gl_TraverseAccount is called so that an unique global temp table 
--					is kept at this level.To prevent one or more user assessing the same global temp
--					table. Also removed the CURSOR for looping distinct periodids. 
-- 06 Aug 2004	AB	8035	8	Add collate database_default to temp table definitions
-- 04 Feb 2005	CR	10821	9	Changed the Account Id list received from comma separted list to XML
-- 19 Sep 2007	CR	14722	10	Change @psProfitCentreCodes and @psAnalysisCodeIds to ntext and added code 
--					to convert back to nvarchar before subsequently using.
-- 27 Feb 2014	DL	S21508	11	Change variables and temp table columns that reference namecode to 20 characters


Begin
	SET CONCAT_NULL_YIELDS_NULL OFF
	
	declare	@ErrorCode		int
	declare @nPeriod 		int
	declare @nPrevPeriod 		int
	declare @sSql			nvarchar(4000)
	declare @sRelAcctTempTable	nvarchar(128)
	declare @sProfitCentreCodes 	nvarchar(2000)
	declare @sAnalysisCodeIds	nvarchar(1000)

	Set	@ErrorCode=0
	Set	@sSql = ''

	Set 	@sProfitCentreCodes = CAST(@psProfitCentreCodes AS nvarchar(2000))
	If (@sProfitCentreCodes = '')
		Set 	@sProfitCentreCodes = NULL

	Set 	@sAnalysisCodeIds = CAST(@psAnalysisCodeIds AS nvarchar(1000))
	If (@sAnalysisCodeIds = '')
		Set 	@sAnalysisCodeIds = NULL


	CREATE TABLE #LEDGERACCOUNTIDTOQUERY (
		Value int )
	Set @ErrorCode = @@ERROR

	if @ErrorCode = 0
	begin		
		CREATE TABLE dbo.#TEMPACCOUNTS ( 
			NAMENO 			Int, 
			NAMECODE 		varchar(20)	 collate database_default , 
			NAME 			varchar(254)	 collate database_default ,
			PROFITCENTRECODE 	varchar(6)	 collate database_default , 
			PROFITCENTREDESC 	varchar(50)	 collate database_default ,
			ACCOUNTID 		Int, 
			CHARTOFACCOUNTSCODE 	nvarchar(20)	 collate database_default , 
			CHARTOFACCOUNTSDESC 	nvarchar(100)	 collate database_default ,
			PERIODID 		Int, 
			PERIODLABEL 		varchar(20)	 collate database_default, 
			PREVPERIODID 		Int)
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
	
	-- Create temporary table to store Current Year amount - master table
	if @ErrorCode = 0
	begin
		CREATE TABLE #CURRENTTEMP ( 
			NAMENO 			Int, 
			NAMECODE 		varchar(20) collate database_default , 
			NAME 			varchar(254) collate database_default ,
			PROFITCENTRECODE 	varchar(6) collate database_default , 
			PROFITCENTREDESC 	varchar(50) collate database_default ,
			ACCOUNTID 		Int, 
			CHARTOFACCOUNTSCODE 	nvarchar(20) collate database_default , 
			CHARTOFACCOUNTSDESC 	nvarchar(100) collate database_default ,
			PERIODID 		Int, 
			PERIODLABEL 		varchar(20) collate database_default , 
			CURRENAMOUNT 		dec(13,2)) 
		Set @ErrorCode = @@ERROR
	end
	
	-- Create temporary table to store Previous Year amount
	if @ErrorCode = 0
	begin
		CREATE TABLE #PREVIOUSTEMP ( 
			NAMENO 			Int ,
			PROFITCENTRECODE 	varchar(6) collate database_default,  
			ACCOUNTID 		Int,  
			PERIODID 		Int,  
			PREVPERIODID 		Int, 
			PREVIOUSAMOUNT 		dec(13,2)) 
		set @ErrorCode=@@Error
	end
	
	if @ErrorCode = 0
	begin
		Exec @ErrorCode = gl_XMLToLedgerAcctTempTable @psLedgerAccountIds=@psAccountIds, 
								@psTempTableName=N'#LEDGERACCOUNTIDTOQUERY'
	end

	if @ErrorCode = 0
		begin
			if @sProfitCentreCodes is NOT NULL
				set @sSql = '			
						INSERT 	INTO #TEMPACCOUNTS 
							(NAMENO , NAMECODE , NAME ,
							PROFITCENTRECODE , PROFITCENTREDESC ,
							ACCOUNTID , CHARTOFACCOUNTSCODE , CHARTOFACCOUNTSDESC ,
							PERIODID , PERIODLABEL)
						SELECT 	
							N.NAMENO, N.NAMECODE, N.NAME,
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
							N.NAMENO = ' + CONVERT(nvarchar(13), @pnAcctEntity) + ' AND 
							PC.PROFITCENTRECODE in (' + @sProfitCentreCodes + ') AND 
							P.PERIODID >= ' + CONVERT(nvarchar(13), @pnPeriodFrom) + ' AND 
							P.PERIODID <= ' + CONVERT(nvarchar(13), @pnPeriodTo)
			else
				set @sSql = '	
						INSERT 	INTO #TEMPACCOUNTS 
							(NAMENO , NAMECODE , NAME ,
							PROFITCENTRECODE , PROFITCENTREDESC ,
							ACCOUNTID , CHARTOFACCOUNTSCODE , CHARTOFACCOUNTSDESC ,
							PERIODID , PERIODLABEL)
						SELECT 	
							N.NAMENO, N.NAMECODE, N.NAME,
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
							N.NAMENO = ' + CONVERT(nvarchar(13), @pnAcctEntity) + ' AND
							PC.ENTITYNO = ' + CONVERT(nvarchar(13), @pnAcctEntity) + ' AND							
							P.PERIODID >= ' + CONVERT(nvarchar(13), @pnPeriodFrom) + ' AND 
							P.PERIODID <= ' + CONVERT(nvarchar(13), @pnPeriodTo)
		end

		exec sp_executesql @sSql
		set @ErrorCode=@@Error
		
	if @ErrorCode = 0
		UPDATE #TEMPACCOUNTS SET PREVPERIODID = CAST( 
		CAST (
			CAST ( 
				LEFT (
					CAST( PERIODID as VARCHAR),4) as INt) - 1 AS CHAR(4))+ 
		RIGHT ( CAST (PERIODID AS VARCHAR),2)AS Int )
	
	set @ErrorCode=@@Error
	
	if @ErrorCode = 0
		exec @ErrorCode = gl_TraverseAccount '#TEMPACCOUNTS', @sRelAcctTempTable Output
		
	if @ErrorCode = 0
	begin
		if @pnMovBalanceInd = 1 -- Movement
		begin
			Set @sSql = '		
			INSERT INTO 
				#CURRENTTEMP 		(
				NAMENO, NAMECODE, NAME, 
				PROFITCENTRECODE, PROFITCENTREDESC,
				ACCOUNTID, CHARTOFACCOUNTSCODE, CHARTOFACCOUNTSDESC, 
				PERIODID, PERIODLABEL, CURRENAMOUNT )
			SELECT 
				a.NAMENO,  a.NAMECODE, a.NAME,
				a.PROFITCENTRECODE, a.PROFITCENTREDESC,
				a.ACCOUNTID, a.CHARTOFACCOUNTSCODE, a.CHARTOFACCOUNTSDESC,
				a.PERIODID, a.PERIODLABEL , SUM(LOCALAMOUNT) AS AMOUNT
		 	FROM 
				#TEMPACCOUNTS a, ' + @sRelAcctTempTable + ' b , 
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
				(tr.TRANSTYPE <> 812 OR (tr.TRANSTYPE = 812 AND 
						la.ACCOUNTTYPE NOT IN (8104,8105))) AND 
				tr.TRANSTATUS = 1 
			GROUP 
				BY a.NAMENO, a.NAME, a.NAMECODE, 
				a.PROFITCENTRECODE, a.PROFITCENTREDESC,
				a.ACCOUNTID, a.CHARTOFACCOUNTSCODE, a.CHARTOFACCOUNTSDESC,
				a.PERIODID, a.PERIODLABEL '
			exec @ErrorCode=sp_executesql @sSql	

			if @ErrorCode = 0
			begin
				set @sSql = '
				INSERT INTO #PREVIOUSTEMP (
					NAMENO,  PROFITCENTRECODE, 
					ACCOUNTID,  
					PERIODID, PREVPERIODID,  PREVIOUSAMOUNT )
				SELECT
					a.NAMENO, a.PROFITCENTRECODE,  
					a.ACCOUNTID,  
					a.PERIODID,  a.PREVPERIODID, SUM(LOCALAMOUNT) AS AMOUNT
			 	FROM 
					#TEMPACCOUNTS a, ' + @sRelAcctTempTable + ' b , 
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
					a.PREVPERIODID = tr.TRANPOSTPERIOD AND
					(tr.TRANSTYPE <> 812 OR (tr.TRANSTYPE = 812 AND 
					la.ACCOUNTTYPE NOT IN (8104,8105)))AND 
					tr.TRANSTATUS = 1 
				GROUP BY 
					a.NAMENO, a.PROFITCENTRECODE, 
					a.ACCOUNTID,  
					a.PERIODID, a.PREVPERIODID'
				exec @ErrorCode=sp_executesql @sSql
			end
		end
	 
		else 
		begin		-- Account Balance
			Select DISTINCT @nPeriod=MIN(a.PERIODID), 
					@nPrevPeriod=MIN(a.PREVPERIODID)
			from #TEMPACCOUNTS a
			Set @ErrorCode = @@ERROR
	
			WHILE (@nPeriod is not Null AND @nPrevPeriod is not Null) AND
				(@ErrorCode = 0)
			begin
				Set @sSql = '
				INSERT INTO 	#CURRENTTEMP 		(
					NAMENO, NAMECODE, NAME, 
					PROFITCENTRECODE, PROFITCENTREDESC,
					ACCOUNTID, CHARTOFACCOUNTSCODE, CHARTOFACCOUNTSDESC, 
					PERIODID, PERIODLABEL, CURRENAMOUNT )
				SELECT 
					a.NAMENO, a.NAMECODE, a.NAME,
					a.PROFITCENTRECODE, a.PROFITCENTREDESC,
					a.ACCOUNTID, a.CHARTOFACCOUNTSCODE, a.CHARTOFACCOUNTSDESC,
					a.PERIODID, a.PERIODLABEL , SUM(LOCALAMOUNT) AS AMOUNT
	 			FROM 
					#TEMPACCOUNTS a, ' + @sRelAcctTempTable + ' b , 
					TRANSACTIONHEADER tr, LEDGERJOURNALLINE jl,
					LEDGERACCOUNT la
	 			WHERE 
					jl.ACCOUNTID = la.ACCOUNTID AND
					a.ACCOUNTID = b.PARENTID AND 
					tr.ENTITYNO = jl.ENTITYNO AND 
					tr.TRANSNO = jl.TRANSNO AND 
					a.NAMENO = jl.ACCTENTITYNO AND  
					a.PROFITCENTRECODE = jl.PROFITCENTRECODE AND 
					b.CHILDID = jl.ACCOUNTID AND 
					la.ACCOUNTTYPE IN (8101,8102,8103 ) AND -- Assets, liability, equity
					a.PERIODID = @nPeriod AND
					tr.TRANPOSTPERIOD <= @nPeriod AND
					tr.TRANSTATUS = 1 
				GROUP BY 
					a.NAMENO, a.NAMECODE, a.NAME,
					a.PROFITCENTRECODE, a.PROFITCENTREDESC,
					a.ACCOUNTID, a.CHARTOFACCOUNTSCODE, a.CHARTOFACCOUNTSDESC,
					a.PERIODID, a.PERIODLABEL
				UNION ALL 
				SELECT 
					a.NAMENO, a.NAMECODE, a.NAME,
					a.PROFITCENTRECODE, a.PROFITCENTREDESC,
					a.ACCOUNTID, a.CHARTOFACCOUNTSCODE, a.CHARTOFACCOUNTSDESC,
					a.PERIODID, a.PERIODLABEL , SUM(LOCALAMOUNT) AS AMOUNT
	 			FROM 
					#TEMPACCOUNTS a, ' + @sRelAcctTempTable + ' b , 
					TRANSACTIONHEADER tr, LEDGERJOURNALLINE jl,
					LEDGERACCOUNT la
	 			WHERE 
					jl.ACCOUNTID = la.ACCOUNTID AND
					a.ACCOUNTID = b.PARENTID AND 
					tr.ENTITYNO = jl.ENTITYNO AND 
					tr.TRANSNO = jl.TRANSNO AND 
					a.NAMENO = jl.ACCTENTITYNO AND   
					a.PROFITCENTRECODE = jl.PROFITCENTRECODE AND 
					b.CHILDID = jl.ACCOUNTID AND 
					la.ACCOUNTTYPE IN (8104,8105 ) AND -- Income, Expense
					tr.TRANPOSTPERIOD <= a.PERIODID AND
					LEFT ( CAST (tr.TRANPOSTPERIOD as VARCHAR),4) = LEFT ( CAST (@nPeriod as VARCHAR),4) AND
					a.PERIODID = @nPeriod AND 
					tr.TRANSTYPE <> 812 AND 
					tr.TRANSTATUS = 1 
				GROUP BY 
					a.NAMENO, a.NAMECODE, a.NAME,
					a.PROFITCENTRECODE, a.PROFITCENTREDESC,
					a.ACCOUNTID, a.CHARTOFACCOUNTSCODE, a.CHARTOFACCOUNTSDESC,
					a.PERIODID, a.PERIODLABEL '
				--print @sSql
				Exec @ErrorCode=sp_executesql @sSql,
								N'@nPeriod int',
								@nPeriod
				if @ErrorCode= 0
				begin
					Set @sSql = '
					INSERT INTO #PREVIOUSTEMP (
						NAMENO,  PROFITCENTRECODE, 
						ACCOUNTID,  
						PERIODID, PREVPERIODID,  PREVIOUSAMOUNT )
					SELECT 
						a.NAMENO,  
						a.PROFITCENTRECODE,  
						a.ACCOUNTID, 
						a.PERIODID, a.PREVPERIODID , SUM(LOCALAMOUNT) AS AMOUNT
		 			FROM 
						#TEMPACCOUNTS a, ' + @sRelAcctTempTable + ' b , 
						TRANSACTIONHEADER tr, LEDGERJOURNALLINE jl,
						LEDGERACCOUNT la
		 			WHERE 
						jl.ACCOUNTID = la.ACCOUNTID AND
						a.ACCOUNTID = b.PARENTID AND 
						tr.ENTITYNO = jl.ENTITYNO AND 
						tr.TRANSNO = jl.TRANSNO AND 
						a.NAMENO = jl.ACCTENTITYNO AND  
						a.PROFITCENTRECODE = jl.PROFITCENTRECODE AND 
						b.CHILDID = jl.ACCOUNTID AND 
						la.ACCOUNTTYPE IN (8101,8102,8103 ) AND -- Assets, liability, equity
						tr.TRANPOSTPERIOD <= @nPrevPeriod AND 
						a.PERIODID = @nPeriod AND
						tr.TRANSTATUS = 1 
					GROUP BY 
						a.NAMENO, 
						a.PROFITCENTRECODE,  
						a.ACCOUNTID,  
						a.PERIODID, a.PREVPERIODID
					UNION ALL 
					SELECT 
						a.NAMENO, 
						a.PROFITCENTRECODE,  
						a.ACCOUNTID,  
						a.PERIODID, a.PREVPERIODID , SUM(LOCALAMOUNT) AS AMOUNT
					FROM 
						#TEMPACCOUNTS a, ' + @sRelAcctTempTable + ' b , 
						TRANSACTIONHEADER tr, LEDGERJOURNALLINE jl,
						LEDGERACCOUNT la
	 				WHERE 
						jl.ACCOUNTID = la.ACCOUNTID AND
						a.ACCOUNTID = b.PARENTID AND 
						tr.ENTITYNO = jl.ENTITYNO AND 
						tr.TRANSNO = jl.TRANSNO AND 
						a.NAMENO = jl.ACCTENTITYNO AND  
						a.PROFITCENTRECODE = jl.PROFITCENTRECODE AND 
						b.CHILDID = jl.ACCOUNTID AND 
						la.ACCOUNTTYPE IN (8104,8105 ) AND -- Income , Expense
						tr.TRANPOSTPERIOD <= @nPrevPeriod AND
						LEFT ( CAST (tr.TRANPOSTPERIOD as VARCHAR),4) = LEFT ( CAST (@nPrevPeriod as VARCHAR),4) AND 
						a.PERIODID = @nPeriod AND
						tr.TRANSTYPE <> 812 AND 
						tr.TRANSTATUS = 1 
					GROUP BY 
						a.NAMENO, 
						a.PROFITCENTRECODE,  
						a.ACCOUNTID,  
						a.PERIODID, a.PREVPERIODID '
					--print @sSql
					Exec @ErrorCode=sp_executesql @sSql, 
									N'@nPrevPeriod int,
									  @nPeriod int',
									@nPrevPeriod,
									@nPeriod
				end

				If @ErrorCode = 0
				begin
					Set @sSql = 'Select DISTINCT @nPeriod=MIN(a.PERIODID), 
								@nPrevPeriod=MIN(a.PREVPERIODID)
						     from #TEMPACCOUNTS a
						     where a.PERIODID > @nPeriod '
					Exec @ErrorCode=sp_executesql @sSql,
									N'@nPeriod int output,
									  @nPrevPeriod int output',
									@nPeriod output,
									@nPrevPeriod output
				end
			end 	-- end of while loop	
		end 		-- end of movement /balance
	end			-- end of error code validation

	-- final select
	if @ErrorCode = 0
		begin
			Set @sSql = '
					SELECT ' + dbo.fn_IncludeProfitCentreAnalysis(@sProfitCentreCodes,
					     						@pnAnalysisTypeId,
					     						@sAnalysisCodeIds,
					     						'SELECT',
					     						null) +
					      ' a.NAMENO, a.NAMECODE, a.NAME, a.PROFITCENTRECODE, a.PROFITCENTREDESC,
						a.ACCOUNTID, a.CHARTOFACCOUNTSCODE, a.CHARTOFACCOUNTSDESC, 
						a.PERIODID, a.PERIODLABEL, a.CURRENAMOUNT , b.PREVIOUSAMOUNT 
					FROM #CURRENTTEMP a LEFT OUTER JOIN  #PREVIOUSTEMP b 
						ON a.NAMENO = b.NAMENO AND
						   a.PROFITCENTRECODE = b.PROFITCENTRECODE AND
						   a.ACCOUNTID = b.ACCOUNTID AND
						   a.PERIODID = b.PERIODID ' +
					     dbo.fn_IncludeProfitCentreAnalysis(@sProfitCentreCodes,
					     					@pnAnalysisTypeId,
					     					@sAnalysisCodeIds,
					     					'FROM',
					     					'a.PROFITCENTRECODE') +
				      ' ORDER BY ' + dbo.fn_IncludeProfitCentreAnalysis(@sProfitCentreCodes,
					     						@pnAnalysisTypeId,
					     						@sAnalysisCodeIds,
					     						'ORDER',
					     						null) +
				      ' a.NAME, a.PROFITCENTREDESC, a.CHARTOFACCOUNTSDESC, a.PERIODID '
				      
			exec sp_executesql @sSql				
			Set @pnRowCount = @@Rowcount
			set @ErrorCode=@@Error
		end	
	
	drop table #TEMPACCOUNTS

	-- Drop related account global temporary table
	Set @sSql = 'Drop table ' + @sRelAcctTempTable
	Exec sp_executesql @sSql

	drop table #LEDGERACCOUNTIDTOQUERY

	return @ErrorCode
End
go

grant execute on dbo.gl_ListAccountComparison to public
go

