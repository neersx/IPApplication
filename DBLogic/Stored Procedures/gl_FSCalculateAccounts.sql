-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_FSCalculateAccounts
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[gl_FSCalculateAccounts]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.gl_FSCalculateAccounts.'
	drop procedure dbo.gl_FSCalculateAccounts
	print '**** Creating procedure dbo.gl_FSCalculateAccounts...'
	print ''
end
go

SET QUOTED_IDENTIfIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.gl_FSCalculateAccounts 
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(5)	= null, -- the language in which output is to be expressed
	@psOutputRequestTable		varchar(30),		-- name of table where column names are stored
	@psTempTableName		nvarchar(50),	 	-- is the name of the the global temporary table that will hold the filtered list of transactions.
	@pnPeriodFrom			int,			-- The start period.
	@pnPeriodTo			int,			-- The end period.
	@pnOutputRequestRowCount	int,			-- number of columns in the @psOutputRequestTable
	@pnYTDMinPeriod 		int,			-- The first period of the current financial year
	@pnPreviousYTDMinPeriod 	int,			-- The first period of the previous financial year
	@pnPreviousYTDMaxPeriod 	int,			-- The last period of the previous financial year
	@pnPreviousPeriodFrom		int,			-- The From Period in the previous financial year
	@pnPreviousPeriodTo		int,			-- The To Period in the previous financial year
	@psSelectClause1		nvarchar(4000) output,	-- The output select clause
	@psSelectClause2		nvarchar(4000) output	-- The output select clause
)
AS

-- PROCEDURE:	gl_FSCalculateAccounts
-- VERSION:	6
-- SCOPE:	Centura
-- DESCRIPTION:	Calculates the Accounts type line
--			
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 31-Aug-2004  MB	9658	1	Procedure created
-- 30 Sep 2004	JEK	RFC1695 2	Implement @pbCalledFromCentura in fn_GetQueryOutputRequests interface
-- 23-May-2005  MB	11278	3	Performance improvement
-- 15-Nov-2007	AT	15035	4	Added option to exclude 812 clearing transactions.
-- 13-Dec-2007	AT	15035	5	Exclude 812 clearing transactions for Account Movement columns as well.
-- 27 Mar 2012	DL	20439	6	Fix syntax error when column ‘Budget Movement’ is included


-- The following Column Ids have been hardcoded to return specIfic data from the database
-- NOTE: Update this list If any new columns are added
/*
418	AccountBalance
419	AccountBalanceForPreviousYear

420	AccountMovement
421	AccountMovementForPreviousYear
422	AccountMovementForPreviousYearYTD
423	AccountMovementYTD

424	BudgetBalance
425	BudgetBalanceForPreviousYear
426	BudgetMovement
427	BudgetMovementForPreviousYear
428	BudgetMovementForPreviousYearYTD
429	BudgetMovementYTD

430	ForecastBalance
431	ForecastBalanceForPreviousYear
432	ForecastMovement
433	ForecastMovementForPreviousYear
434	ForecastMovementForPreviousYearYTD
435	ForecastMovementYTD

436	Variance%AccountMovementVsBudgetMovement
437	Variance%AccountMovementVsForecastMovement
438	Variance%AccountMovementYTDVsBudgetMovementYTD
439	Variance%AccountMovementYTDVsForecastMovementYTD
440	VarianceAccountMovementVsBudgetMovement
441	VarianceAccountMovementVsForecastMovement
442	VarianceAccountMovementYTDVsBudgetMovementYTD
443	VarianceAccountMovementYTDVsForecastMovementYTD
*/

-- The following table correlation names have been used within this stored procedure
-- Take care when modIfying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list If new correlation names are assigned for any tables
--  LJL LEDGERJOURNALLINE
--	LJ 	LEDGERJOURNAL
--	T	TRANSACTIONHEADER



--  ATT ACCT_TRANS_TYPE

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare	@sSql			nvarchar(4000)
Declare @nColumnNo		tinyint
Declare @sColumn		nvarchar(100)
Declare @sTableColumn		nvarchar(1000)
Declare @nDataItemId 		int
Declare @sTempRelatedTable 	nvarchar(128)

Declare @sSelect 		nvarchar(4000)
Declare @sFrom 			nvarchar(4000)
Declare @nCount			int

Declare @tbJoinedTable table (TABLENAME nvarchar(100) collate database_default PRIMARY KEY )

-- Initialisation
Set @nErrorCode	= 0
Set @nCount	= 1

Set @psSelectClause1 = ''
Set @psSelectClause2 = ''


If @nErrorCode = 0
	Exec @nErrorCode = gl_TraverseAccount 
				@psAccountTable 	= @psTempTableName, 
				@prsRelatedAcctTable 	= @sTempRelatedTable output


-- Loop through each column in order to construct the components of the SELECT
While @nCount < @pnOutputRequestRowCount + 1
and   @nErrorCode = 0
Begin

	Set  @sSql = 'Select	 @nDataItemId = DATAITEMID
	from	' + @psOutputRequestTable + '
	where	ROWNUMBER = @nCount'

	Exec @nErrorCode=sp_executesql @sSql, 
			N'@nDataItemId 	int Output,
			@nCount	int', 
			@nDataItemId Output,
			@nCount = @nCount


	-- Now test the value of the @nDataItemId to determine what table and column is required
	-- in the Select.  Note that If the PublishName is null then the column will not be
	-- returned in the result set however it is probably required for sorting.

	If @nErrorCode=0
	Begin
		If @nDataItemId is null
		Begin
			Set @sTableColumn='NULL'
		End
		Else If @nDataItemId = 418 -- AccountBalance
		Begin
			Set @sTableColumn= 'SUM( LJL.ACCOUNTBALANCE ) '
			Exec @nErrorCode = gl_RWCalculateAccountData 
				@psTempTableName 	= @psTempTableName, 
				@psTempRelatedTable	= @sTempRelatedTable, 
				@psColumnName	 	= 'ACCOUNTBALANCE', 
				@pnPeriodFrom 		= null, 
				@pnPeriodTo 		= @pnPeriodTo,
				@pbExcludePLClearing	= 0
		End
		Else If @nDataItemId = 419--AccountBalanceForPreviousYear
		Begin
			Set @sTableColumn= 'SUM( LJL.PREVIOUSACCOUNTBALANCE ) '		
			Exec @nErrorCode = gl_RWCalculateAccountData 
				@psTempTableName 	= @psTempTableName, 
				@psTempRelatedTable 	= @sTempRelatedTable, 
				@psColumnName 		= 'PREVIOUSACCOUNTBALANCE', 
				@pnPeriodFrom 		= null, 
				@pnPeriodTo 		= @pnPreviousPeriodTo,
				@pbExcludePLClearing	= 1
		End	


		Else If @nDataItemId= 420 -- 'AccountMovement'
		Begin
			Set @sTableColumn= 'SUM( LJL.ACCOUNTMOVEMENT ) '
			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'ACCOUNTMOVEMENT' )
			Begin
				Insert into @tbJoinedTable VALUES ('ACCOUNTMOVEMENT')	

				Exec @nErrorCode = gl_RWCalculateAccountData 
					@psTempTableName 	= @psTempTableName, 
					@psTempRelatedTable 	= @sTempRelatedTable, 
					@psColumnName 		= 'ACCOUNTMOVEMENT',
					@pnPeriodFrom 		= @pnPeriodFrom, 
					@pnPeriodTo 		= @pnPeriodTo,
					@pbExcludePLClearing	= 1
			End
		End
		Else If @nDataItemId= 421 -- 'AccountMovementForPreviousYear'
		Begin
			Set @sTableColumn= 'SUM( LJL.PREVIOUSACCOUNTMOVEMENT ) '	
			Exec @nErrorCode = gl_RWCalculateAccountData 
					@psTempTableName 	= @psTempTableName, 
					@psTempRelatedTable 	= @sTempRelatedTable, 
					@psColumnName 		= 'PREVIOUSACCOUNTMOVEMENT',
					@pnPeriodFrom 		= @pnPreviousPeriodFrom, 
					@pnPeriodTo 		= @pnPreviousPeriodTo,
					@pbExcludePLClearing	= 1

		End
		Else If @nDataItemId= 422 -- AccountMovementForPreviousYearYTD
		Begin

			Set @sTableColumn= 'SUM( LJL.PREVIOUSACCOUNTMOVEMENTYTD ) '	
			Exec @nErrorCode = gl_RWCalculateAccountData 
					@psTempTableName 	= @psTempTableName, 
					@psTempRelatedTable 	= @sTempRelatedTable, 
					@psColumnName 	= 'PREVIOUSACCOUNTMOVEMENTYTD',
					@pnPeriodFrom 		= @pnPreviousYTDMinPeriod, 
					@pnPeriodTo 		= @pnPreviousPeriodTo,
					@pbExcludePLClearing	= 1
		End
		Else If @nDataItemId= 423 -- 'AccountMovementYTD'
		Begin
			Set @sTableColumn= 'SUM( LJL.ACCOUNTMOVEMENTYTD) '
			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'ACCOUNTMOVEMENTYTD' )
			Begin
				Insert into @tbJoinedTable VALUES ('ACCOUNTMOVEMENTYTD')	
				Exec @nErrorCode = gl_RWCalculateAccountData   
					@psTempTableName 	= @psTempTableName, 
					@psTempRelatedTable 	= @sTempRelatedTable, 
					@psColumnName 		= 'ACCOUNTMOVEMENTYTD',
					@pnPeriodFrom 		= @pnYTDMinPeriod, 
					@pnPeriodTo 		= @pnPeriodTo,
					@pbExcludePLClearing	= 1
			End
		End

		Else If @nDataItemId= 424  -- BudgetBalance
		Begin
			Set @sTableColumn= 'SUM( LJL.BUDGETBALANCE) '
			Exec @nErrorCode = gl_RWCalculateBudgetData 
				@psTempTableName 	= @psTempTableName, 
				@psTempRelatedTable 	= @sTempRelatedTable, 
				@psColumnName 		= 'BUDGETBALANCE', 
				@pnPeriodFrom  		= null, 
				@pnPeriodTo 		= @pnPeriodTo
		End	

		Else If @nDataItemId= 425 -- BudgetBalanceForPreviousYear
		Begin
			Set @sTableColumn= 'SUM( LJL.PREVIOUSBUDGETBALANCE) '		
			Exec @nErrorCode = gl_RWCalculateBudgetData 
				@psTempTableName 	= @psTempTableName, 
				@psTempRelatedTable 	= @sTempRelatedTable, 
				@psColumnName 		= 'PREVIOUSBUDGETBALANCE', 
				@pnPeriodFrom  		= null, 
				@pnPeriodTo 		= @pnPreviousPeriodTo
		End	

		Else If @nDataItemId= 426 -- BudgetMovement
		Begin
			Set @sTableColumn= 'SUM( LJL.BUDGETMOVEMENT) '
			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'BUDGETMOVEMENT' )
			Begin
				Insert into @tbJoinedTable VALUES ('BUDGETMOVEMENT')	
				Exec @nErrorCode = gl_RWCalculateBudgetData 
					@psTempTableName 	= @psTempTableName, 
					@psTempRelatedTable 	= @sTempRelatedTable, 
					@psColumnName 		= 'BUDGETMOVEMENT', 
					@pnPeriodFrom  		= @pnPeriodFrom, 
					@pnPeriodTo 		= @pnPeriodTo
			End
		End

		Else If @nDataItemId= 427 -- BudgetMovementForPreviousYear
		Begin

			Set @sTableColumn= 'SUM( LJL.PREVIOUSBUDGETMOVEMENT ) '	
			Exec @nErrorCode = gl_RWCalculateBudgetData 
					@psTempTableName 	= @psTempTableName, 
					@psTempRelatedTable 	= @sTempRelatedTable, 
					@psColumnName 		= 'PREVIOUSBUDGETMOVEMENT', 
					@pnPeriodFrom  		= @pnPreviousPeriodFrom, 
					@pnPeriodTo 		= @pnPreviousPeriodTo
		End	
	
		Else If @nDataItemId= 428 -- BudgetMovementForPreviousYearYTD
		Begin
			Set @sTableColumn= 'SUM( LJL.PREVIOUSBUDGETMOVEMENTYTD ) '		
			Exec @nErrorCode = gl_RWCalculateBudgetData 
					@psTempTableName 	= @psTempTableName, 
					@psTempRelatedTable 	= @sTempRelatedTable, 
					@psColumnName 		= 'PREVIOUSBUDGETMOVEMENTYTD', 
					@pnPeriodFrom  		= @pnPreviousYTDMinPeriod, 
					@pnPeriodTo 		= @pnPreviousPeriodTo

		End

		Else If @nDataItemId= 429 -- BudgetMovementYTD
		Begin
			Set @sTableColumn= 'SUM( LJL.BUDGETMOVEMENTYTD) '
			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'BUDGETMOVEMENTYTD' )
			Begin
				Insert into @tbJoinedTable VALUES ('BUDGETMOVEMENTYTD')	
				Exec @nErrorCode = gl_RWCalculateBudgetData 
					@psTempTableName 	= @psTempTableName, 
					@psTempRelatedTable 	= @sTempRelatedTable, 
					@psColumnName 		= 'BUDGETMOVEMENTYTD', 
					@pnPeriodFrom  		= @pnYTDMinPeriod, 
					@pnPeriodTo 		= @pnPeriodTo
			End
		End

		Else If @nDataItemId= 430 --ForecastBalance 
		Begin
			Set @sTableColumn= 'SUM( LJL.FORECASTBALANCE ) '
			Exec @nErrorCode = gl_RWCalculateForecastData 
					@psTempTableName 	= @psTempTableName, 
					@psTempRelatedTable 	= @sTempRelatedTable, 
					@psColumnName 		= 'FORECASTBALANCE', 
					@pnPeriodFrom  		= null, 
					@pnPeriodTo 		= @pnPeriodTo

		End	
		Else If @nDataItemId= 431  -- ForecastBalanceForPreviousYear
		Begin
			Set @sTableColumn= 'SUM( LJL.PREVIOUSFORECASTBALANCE ) '		
			Exec @nErrorCode = gl_RWCalculateForecastData 
					@psTempTableName 	= @psTempTableName, 
					@psTempRelatedTable 	= @sTempRelatedTable, 
					@psColumnName 		= 'PREVIOUSFORECASTBALANCE', 
					@pnPeriodFrom  		= null, 
					@pnPeriodTo 		= @pnPreviousPeriodTo

		End	
		Else If @nDataItemId= 432  -- ForecastMovement
		Begin
			Set @sTableColumn= 'SUM( LJL.FORECASTMOVEMENT ) '
			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'FORECASTMOVEMENT' )
			Begin
				Insert into @tbJoinedTable VALUES ('FORECASTMOVEMENT')	
				Exec @nErrorCode = gl_RWCalculateForecastData 
					@psTempTableName 	= @psTempTableName, 
					@psTempRelatedTable 	= @sTempRelatedTable, 
					@psColumnName 		= 'FORECASTMOVEMENT', 
					@pnPeriodFrom  		= @pnPeriodFrom, 
					@pnPeriodTo 		= @pnPeriodTo

			End
		End

		Else If @nDataItemId= 433  -- ForecastMovementForPreviousYear
		Begin
			Set @sTableColumn= 'SUM( LJL.PREVIOUSFORECASTMOVEMENT ) '	
			Exec @nErrorCode = gl_RWCalculateForecastData 
					@psTempTableName 	= @psTempTableName, 
					@psTempRelatedTable 	= @sTempRelatedTable, 
					@psColumnName 		= 'PREVIOUSFORECASTMOVEMENT', 
					@pnPeriodFrom  		= @pnPreviousPeriodFrom, 
					@pnPeriodTo 		= @pnPreviousPeriodTo
		End	
	
		Else If @nDataItemId= 434  -- ForecastMovementForPreviousYearYTD
		Begin
			Set @sTableColumn= 'SUM( LJL.PREVIOUSFORECASTMOVEMENTYTD ) '		
			Exec @nErrorCode = gl_RWCalculateForecastData 
					@psTempTableName 	= @psTempTableName, 
					@psTempRelatedTable 	= @sTempRelatedTable, 
					@psColumnName 		= 'PREVIOUSFORECASTMOVEMENTYTD', 
					@pnPeriodFrom  		= @pnPreviousYTDMinPeriod, 
					@pnPeriodTo 		= @pnPreviousPeriodTo
		End	

		Else If @nDataItemId= 435  -- ForecastMovementYTD
		Begin
			Set @sTableColumn= 'SUM( LJL.FORECASTMOVEMENTYTD)'
			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'FORECASTMOVEMENTYTD' )
			Begin
				Insert into @tbJoinedTable VALUES ('FORECASTMOVEMENTYTD')	
				Exec @nErrorCode = gl_RWCalculateForecastData 
					@psTempTableName 	= @psTempTableName, 
					@psTempRelatedTable 	= @sTempRelatedTable, 
					@psColumnName 		= 'FORECASTMOVEMENTYTD', 
					@pnPeriodFrom  		= @pnYTDMinPeriod, 
					@pnPeriodTo 		= @pnPeriodTo
			End
		End

		Else If 	@nDataItemId= 436  -- Variance%AccountMovementVsBudgetMovement
			or 	@nDataItemId= 440  -- VarianceAccountMovementVsBudgetMovement
		Begin
			If @nDataItemId= 436 	-- Variance%AccountMovementVsBudgetMovement
			Begin
				Set @sTableColumn='SUM(LJL.VAR_PCT_ACCT_BUDG_MOVE)'
			End
			Else If @nDataItemId = 440	-- VarianceAccountMovementVsBudgetMovement
			Begin
				Set @sTableColumn='SUM(LJL.VAR_ACCT_BUDG_MOVE)'
			End
			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'ACCOUNTMOVEMENT' )
			Begin
				Insert into @tbJoinedTable VALUES ('ACCOUNTMOVEMENT')
				Set @sTableColumn=@sTableColumn + ', SUM(LJL.ACCOUNTMOVEMENT)'
				Exec @nErrorCode = gl_RWCalculateAccountData 
					@psTempTableName 	= @psTempTableName, 
					@psTempRelatedTable 	= @sTempRelatedTable, 
					@psColumnName 		= 'ACCOUNTMOVEMENT',
					@pnPeriodFrom 		= @pnPeriodFrom, 
					@pnPeriodTo 		= @pnPeriodTo,
					@pbExcludePLClearing	= 1
			End
			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'BUDGETMOVEMENT' )
			Begin
				Insert into @tbJoinedTable VALUES ('BUDGETMOVEMENT')	
				Set @sTableColumn=@sTableColumn + ', SUM(LJL.BUDGETMOVEMENT)'
				Exec @nErrorCode = gl_RWCalculateBudgetData 
					@psTempTableName 	= @psTempTableName, 
					@psTempRelatedTable 	= @sTempRelatedTable, 
					@psColumnName 		= 'BUDGETMOVEMENT', 
					@pnPeriodFrom  		= @pnPeriodFrom, 
					@pnPeriodTo 		= @pnPeriodTo
	

			End
			If @nDataItemId= 440 and @nErrorCode = 0  
			Begin
				Set @sSql = 'UPDATE ' + @psTempTableName + ' SET VAR_ACCT_BUDG_MOVE = 
					ISNULL (ACCOUNTMOVEMENT,0) - ISNULL(BUDGETMOVEMENT,0) '
				Exec @nErrorCode=sp_executesql @sSql
			End
		End		
		Else If 	@nDataItemId = 437  -- Variance%AccountMovementVsForecastMovement
			or 	@nDataItemId = 441  -- VarianceAccountMovementVsForecastMovement
		Begin
			
			If @nDataItemId= 437 	-- Variance%AccountMovementVsForecastMovement
			Begin
				Set @sTableColumn = 'SUM(LJL.VAR_PCT_ACCT_FORE_MOVE)'
			End
			Else If	@nDataItemId= 441	-- VarianceAccountMovementVsForecastMovement
			Begin
				Set @sTableColumn = 'SUM(LJL.VAR_ACCT_FORE_MOVE)'
			End

			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'ACCOUNTMOVEMENT' )
			Begin
				Insert into @tbJoinedTable VALUES ('ACCOUNTMOVEMENT')
				Set @sTableColumn=@sTableColumn + ', SUM(LJL.ACCOUNTMOVEMENT)'
				Exec @nErrorCode = gl_RWCalculateAccountData 
					@psTempTableName 	= @psTempTableName, 
					@psTempRelatedTable 	= @sTempRelatedTable, 
					@psColumnName 		= 'ACCOUNTMOVEMENT',
					@pnPeriodFrom 		= @pnPeriodFrom, 
					@pnPeriodTo 		= @pnPeriodTo,
					@pbExcludePLClearing	= 1

			End
			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'FORECASTMOVEMENT' )
			Begin
				Insert into @tbJoinedTable VALUES ('FORECASTMOVEMENT')
				Set @sTableColumn=@sTableColumn + ', SUM(LJL.FORECASTMOVEMENT)'
				Exec @nErrorCode = gl_RWCalculateForecastData 
					@psTempTableName 	= @psTempTableName, 
					@psTempRelatedTable 	= @sTempRelatedTable, 
					@psColumnName 		= 'FORECASTMOVEMENT', 
					@pnPeriodFrom  		= @pnPeriodFrom, 
					@pnPeriodTo 		= @pnPeriodTo

			End

			If @nDataItemId= 441 and @nErrorCode = 0
			Begin
				Set @sSql = ' UPDATE ' + @psTempTableName + ' SET VAR_ACCT_FORE_MOVE = 
					ISNULL (ACCOUNTMOVEMENT,0 ) - ISNULL(FORECASTMOVEMENT,0) '
				Exec @nErrorCode=sp_executesql @sSql
			End


		End		
		Else If 	@nDataItemId= 438 	-- Variance%AccountMovementYTDVsBudgetMovementYTD
			or	@nDataItemId= 442	-- VarianceAccountMovementYTDVsBudgetMovementYTD
		Begin
			If @nDataItemId= 438 	-- Variance%AccountMovementVsForecastMovement
			Begin
				Set @sTableColumn= 'SUM( LJL.VAR_PCT_ACCT_YTD_BUDG_MOVE)'
			End
			Else If @nDataItemId= 442	-- VarianceAccountMovementYTDVsBudgetMovementYTD
			Begin
				Set @sTableColumn= 'SUM( LJL.VAR_ACCT_YTD_BUDG_MOVE)'
			End

			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'ACCOUNTMOVEMENTYTD' )
			Begin
				Insert into @tbJoinedTable VALUES ('ACCOUNTMOVEMENTYTD')
				Set @sTableColumn=@sTableColumn + ', SUM(LJL.ACCOUNTMOVEMENTYTD)'
				Exec @nErrorCode = gl_RWCalculateAccountData   
					@psTempTableName 	= @psTempTableName, 
					@psTempRelatedTable 	= @sTempRelatedTable, 
					@psColumnName 		= 'ACCOUNTMOVEMENTYTD',
					@pnPeriodFrom 		= @pnYTDMinPeriod, 
					@pnPeriodTo 		= @pnPeriodTo,
					@pbExcludePLClearing	= 1
						   
			End
			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'BUDGETMOVEMENTYTD' )
			Begin
				Insert into @tbJoinedTable VALUES ('BUDGETMOVEMENTYTD')
				Set @sTableColumn=@sTableColumn + ', SUM(LJL.BUDGETMOVEMENTYTD)'	
				Exec @nErrorCode = gl_RWCalculateBudgetData 
					@psTempTableName 	= @psTempTableName, 
					@psTempRelatedTable 	= @sTempRelatedTable, 
					@psColumnName 		= 'BUDGETMOVEMENTYTD', 
					@pnPeriodFrom  		= @pnYTDMinPeriod, 
					@pnPeriodTo 		= @pnPeriodTo	   
			End
			If @nDataItemId= 442 and @nErrorCode = 0
			Begin
				Set @sSql = ' UPDATE ' + @psTempTableName + ' SET VAR_ACCT_YTD_BUDG_MOVE = 
					ISNULL (ACCOUNTMOVEMENTYTD,0 ) - ISNULL(BUDGETMOVEMENTYTD,0) '
				Exec @nErrorCode=sp_executesql @sSql
			End

		End		
		Else If 	@nDataItemId= 439  -- Variance%AccountMovementYTDVsForecastMovementYTD
			or	@nDataItemId= 443  -- VarianceAccountMovementYTDVsForecastMovementYTD
		Begin
			If @nDataItemId= 439  -- Variance%AccountMovementYTDVsForecastMovementYTD
			Begin
				Set @sTableColumn= 'SUM( LJL.VAR_PCT_ACCT_YTD_FORE_MOVE)'
			End
			Else If @nDataItemId= 443  -- VarianceAccountMovementYTDVsForecastMovementYTD
			Begin
				Set @sTableColumn= 'SUM( LJL.VAR_ACCT_YTD_FORE_MOVE)'
			End

			-- SQA20439  remove this line as it is implemented below
			-- Exec @nErrorCode=sp_executesql @sSql

			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'ACCOUNTMOVEMENTYTD' )
			Begin
				Insert into @tbJoinedTable VALUES ('ACCOUNTMOVEMENTYTD')
				Set @sTableColumn=@sTableColumn + ', SUM(LJL.ACCOUNTMOVEMENTYTD)'	
				Exec @nErrorCode = gl_RWCalculateAccountData   
					@psTempTableName 	= @psTempTableName, 
					@psTempRelatedTable 	= @sTempRelatedTable, 
					@psColumnName 		= 'ACCOUNTMOVEMENTYTD',
					@pnPeriodFrom 		= @pnYTDMinPeriod, 
					@pnPeriodTo 		= @pnPeriodTo,
					@pbExcludePLClearing	= 1
			End
			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'FORECASTMOVEMENTYTD' )
			Begin
				Insert into @tbJoinedTable VALUES ('FORECASTMOVEMENTYTD')
				Set @sTableColumn=@sTableColumn + ', SUM(LJL.FORECASTMOVEMENTYTD)'	
				Exec @nErrorCode = gl_RWCalculateForecastData 
					@psTempTableName 	= @psTempTableName, 
					@psTempRelatedTable 	= @sTempRelatedTable, 
					@psColumnName 		= 'FORECASTMOVEMENTYTD', 
					@pnPeriodFrom  		= @pnYTDMinPeriod, 
					@pnPeriodTo 		= @pnPeriodTo
		   
			End
			If @nDataItemId= 443  and @nErrorCode = 0 -- VarianceAccountMovementYTDVsForecastMovementYTD
			Begin
				Set @sSql = 'Update ' + @psTempTableName + ' set 
						VAR_ACCT_YTD_FORE_MOVE = ISNULL (ACCOUNTMOVEMENTYTD,0 ) - ISNULL(FORECASTMOVEMENTYTD,0) '
				Exec @nErrorCode = sp_executesql @sSql
			End
		End		
								
		-- If the column is being published then concatenate it to the Select list

		If @nCount = 1
			Set @sSelect = @sTableColumn 
		else
			Set @sSelect= ', ' +@sTableColumn


		Exec ip_ConcatenateSplitString
			 @psString1		= @psSelectClause1 output,
			 @psString2		= @psSelectClause1 output,
			 @psAppendString 	= @sSelect

	End
	-- Increment @nCount so it points to the next record in the @tblOutputRequests table 
	Set @nCount = @nCount + 1
	
End

If @nErrorCode = 0
Begin
	Set @sFrom = ' from ' + @psTempTableName + ' LJL '

	Exec ip_ConcatenateSplitString
		 @psString1		= @psSelectClause1 output,
		 @psString2		= @psSelectClause1 output,
		 @psAppendString 	= @sFrom
End


If @nErrorCode = 0
Begin	
	Set @sSql = 'Drop table ' + @sTempRelatedTable
	Exec @nErrorCode = sp_executesql @sSql
End

Return @nErrorCode
go

Grant execute on dbo.gl_FSCalculateAccounts  to public
go
