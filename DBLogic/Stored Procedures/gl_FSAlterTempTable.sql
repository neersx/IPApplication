-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_FSAlterTempTable
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[gl_FSAlterTempTable]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.gl_FSAlterTempTable.'
	drop procedure dbo.gl_FSAlterTempTable
	print '**** Creating procedure dbo.gl_FSAlterTempTable...'
	print ''
end
go

SET QUOTED_IDENTIfIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.gl_FSAlterTempTable
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(5)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= null, -- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set. 
	@psTempTableName		nvarchar(50),	 -- is the name of the the global temporary table that will hold the filtered list of transactions.
	@psConsolidatedTempTable	nvarchar(50),	 -- is the name of the the global temporary table that will hold the final result.
	@psSelectClause			nvarchar(4000)  output,
	@psListOfColumns		nvarchar(4000)  output,
	@psListOfPercentageColumns	nvarchar(4000)  output,
	@pbCalledFromCentura	bit		= 1
	
AS


-- PROCEDURE:	gl_FSAlterTempTable
-- VERSION:	3
-- SCOPE:	Centura
-- DESCRIPTION:	Prepare the @psTempTableName tables for Accounts calculations
--			Prepare the @psConsolidatedTempTable tables for final outputs
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 31-Aug-2004  MB	9658	1	Procedure created
-- 30 Sep 2004	JEK	RFC1695 2	Implement @pbCalledFromCentura in fn_GetQueryOutputRequests interface
-- 06 Jun 2005	TM	RFC2630	3	Pass null as new @psPresentationType parameter in the fn_GetQueryOutputRequests function.


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
--	P	PERIOD

--  ATT ACCT_TRANS_TYPE

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @nDataItemId 		int
Declare @nMaxRequestedColumns 	int
Declare @idoc 			int 		
Declare @nOutRequestsRowCount	int
Declare @nCount			int
Declare @nColumnNo		tinyint
Declare	@sSql			nvarchar(4000)
Declare	@sSqlAlter		nvarchar(4000)
Declare @sColumnName 		nvarchar(50)
Declare @sTotalsColumnName	nvarchar(50)
Declare @sPercentageColumnId 	nvarchar(50)

Declare @tbJoinedTable table (TABLENAME nvarchar(100) collate database_default PRIMARY KEY)

-- @tblOutputRequests table variable is used to load the OutputRequests parameters 
Declare @tblOutputRequests table  (
			ROWNUMBER	int 	IDENTITY not null,
			PROCEDUREITEMID	nvarchar(100)	 collate database_default )

-- Initialisation

set @nErrorCode			= 0
set @nOutRequestsRowCount	= 0
set @nCount			= 1
Set @psListOfColumns 		= ''
Set @psListOfPercentageColumns = ''
Set @psSelectClause 		= ''


if @nErrorCode =  0
Begin
	-- Create an XML documwent in memory and then retrieve the information 
	-- from the rowset using OPENXML		
	Exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLOutputRequests
	
	Insert into @tblOutputRequests (PROCEDUREITEMID)
	( Select distinct COLUMNID
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, @ptXMLOutputRequests, @idoc,@pbCalledFromCentura,null) F 
	where F.PUBLISHNAME is not null
	)
	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Select  @nOutRequestsRowCount	= @@ROWCOUNT,
		@nErrorCode = @@ERROR

	-- deallocate the xml document handle when finished.
	Exec sp_xml_removedocument @idoc
End


-- Loop through each column in order to construct the components of the SELECT
While @nCount < @nOutRequestsRowCount + 1
and   @nErrorCode=0
Begin
	Set @sColumnName  = ''
	Set @sTotalsColumnName = ''
  
	Select	@nDataItemId = B.DATAITEMID
	from	@tblOutputRequests A join QUERYDATAITEM B on ( A.PROCEDUREITEMID = B.PROCEDUREITEMID )
	where	ROWNUMBER = @nCount

	Set @nErrorCode = @@ERROR

	If @nErrorCode=0
	Begin
		Set @sSql = ''

		If @nDataItemId = 418 -- AccountBalance
		Begin
			Set @sColumnName = 'ACCOUNTBALANCE'
			Set @sTotalsColumnName = @sColumnName
			Set @sSql = @sColumnName + ' DECIMAL(13,2)'
		End
		Else If @nDataItemId = 419--AccountBalanceForPreviousYear
		Begin
			Set @sColumnName = 'PREVIOUSACCOUNTBALANCE'
			Set @sTotalsColumnName = @sColumnName
			Set @sSql = @sColumnName + ' DECIMAL(13,2)'
		End	
		Else If @nDataItemId= 420 -- AccountMovement
		Begin
			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'ACCOUNTMOVEMENT' )
			Begin
				Insert into @tbJoinedTable VALUES ('ACCOUNTMOVEMENT')
				Set @sColumnName = 'ACCOUNTMOVEMENT'
				Set @sTotalsColumnName = @sColumnName
				Set @sSql = @sColumnName + ' DECIMAL(13,2)'
			End
		End
		Else If @nDataItemId= 421 -- 'AccountMovementForPreviousYear'
		Begin
			Set @sColumnName = 'PREVIOUSACCOUNTMOVEMENT'
			Set @sTotalsColumnName = @sColumnName
			Set @sSql = @sColumnName + ' DECIMAL(13,2)'
		End
		Else If @nDataItemId= 422 -- AccountMovementForPreviousYearYTD
		Begin
			Set @sColumnName = 'PREVIOUSACCOUNTMOVEMENTYTD'
			Set @sTotalsColumnName = @sColumnName
			Set @sSql = @sColumnName + ' DECIMAL(13,2)'
		End
		Else If @nDataItemId= 423 -- 'AccountMovementYTD'
		Begin
			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'ACCOUNTMOVEMENTYTD' )
			Begin
				Insert into @tbJoinedTable VALUES ('ACCOUNTMOVEMENTYTD')
				Set @sColumnName = 'ACCOUNTMOVEMENTYTD'
				Set @sTotalsColumnName = @sColumnName
				Set @sSql = @sColumnName + ' DECIMAL(13,2)'
			End
		End
		Else If @nDataItemId= 424  -- BudgetBalance
		Begin
			Set @sColumnName = 'BUDGETBALANCE'
			Set @sTotalsColumnName = @sColumnName
			Set @sSql = @sColumnName + ' DECIMAL(13,2)'
		End	
		Else If @nDataItemId= 425 -- BudgetBalanceForPreviousYear
		Begin
			Set @sColumnName = 'PREVIOUSBUDGETBALANCE'
			Set @sTotalsColumnName = @sColumnName
			Set @sSql = @sColumnName + ' DECIMAL(13,2)'
		End	
		Else If @nDataItemId= 426 -- BudgetMovement
		Begin
			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'BUDGETMOVEMENT' )
			Begin
				Insert into @tbJoinedTable VALUES ('BUDGETMOVEMENT')
				Set @sColumnName = 'BUDGETMOVEMENT'
				Set @sTotalsColumnName = @sColumnName
				Set @sSql = @sColumnName + ' DECIMAL(13,2)'
			End
		End
		Else If @nDataItemId= 427 -- BudgetMovementForPreviousYear
		Begin
			Set @sColumnName = 'PREVIOUSBUDGETMOVEMENT'
			Set @sTotalsColumnName = @sColumnName
			Set @sSql = @sColumnName + ' DECIMAL(13,2)'
		End		
		Else If @nDataItemId= 428 -- BudgetMovementForPreviousYearYTD
		Begin
			Set @sColumnName = 'PREVIOUSBUDGETMOVEMENTYTD'
			Set @sTotalsColumnName = @sColumnName
			Set @sSql =@sColumnName +  ' DECIMAL(13,2)'
		End
		Else If @nDataItemId= 429 -- BudgetMovementYTD
		Begin
			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'BUDGETMOVEMENTYTD' )
			Begin
				Insert into @tbJoinedTable VALUES ('BUDGETMOVEMENTYTD')
				Set @sColumnName = 'BUDGETMOVEMENTYTD'
				Set @sTotalsColumnName = @sColumnName
				Set @sSql = @sColumnName + ' DECIMAL(13,2)'
			End
		End
		Else If @nDataItemId= 430 --ForecastBalance 
		Begin
			Set @sColumnName = 'FORECASTBALANCE'
			Set @sTotalsColumnName = @sColumnName
			Set @sSql = @sColumnName + ' DECIMAL(13,2)'
		End	
		Else If @nDataItemId= 431  -- ForecastBalanceForPreviousYear
		Begin
			Set @sColumnName = 'PREVIOUSFORECASTBALANCE'
			Set @sTotalsColumnName = @sColumnName
			Set @sSql = @sColumnName + ' DECIMAL(13,2)'
		End	
		Else If @nDataItemId= 432  -- ForecastMovement
		Begin
			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'FORECASTMOVEMENT' )
			Begin
				Insert into @tbJoinedTable VALUES ('FORECASTMOVEMENT')
				Set @sColumnName = 'FORECASTMOVEMENT'
				Set @sTotalsColumnName = @sColumnName
				Set @sSql = @sColumnName + ' DECIMAL(13,2)'
			End
		End
		Else If @nDataItemId= 433  -- ForecastMovementForPreviousYear
		Begin
			Set @sColumnName = 'PREVIOUSFORECASTMOVEMENT'
			Set @sTotalsColumnName = @sColumnName
			Set @sSql = @sColumnName + ' DECIMAL(13,2)'
		End		
		Else If @nDataItemId= 434  -- ForecastMovementForPreviousYearYTD
		Begin
			Set @sColumnName = 'PREVIOUSFORECASTMOVEMENTYTD'
			Set @sTotalsColumnName = @sColumnName
			Set @sSql = @sColumnName + ' DECIMAL(13,2)'
		End	
		Else If @nDataItemId= 435  -- ForecastMovementYTD
		Begin
			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'FORECASTMOVEMENTYTD' )
			Begin
				Insert into @tbJoinedTable VALUES ('FORECASTMOVEMENTYTD')	
				Set @sColumnName = 'FORECASTMOVEMENTYTD'
				Set @sTotalsColumnName = @sColumnName
				Set @sSql = @sColumnName + ' DECIMAL(13,2)'
			End
		End
		Else If 	@nDataItemId= 436  -- Variance%AccountMovementVsBudgetMovement
			or 	@nDataItemId= 440  -- VarianceAccountMovementVsBudgetMovement
		Begin
			If @nDataItemId= 436 	-- Variance%AccountMovementVsBudgetMovement
			Begin
				Set @sColumnName = 'VAR_PCT_ACCT_BUDG_MOVE'
				Set @sSql = @sColumnName + ' DECIMAL(13,4)'
			End
			else If @nDataItemId = 440	-- VarianceAccountMovementVsBudgetMovement
			Begin
				Set @sColumnName = 'VAR_ACCT_BUDG_MOVE'
				Set @sTotalsColumnName = @sColumnName
				Set @sSql = @sColumnName + ' DECIMAL(13,2)'
			End
			
			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'ACCOUNTMOVEMENT' )
			Begin
				Insert into @tbJoinedTable VALUES ('ACCOUNTMOVEMENT')
				Set @sTotalsColumnName = @sColumnName
				Set @sSql = @sSql + ',' + '  ACCOUNTMOVEMENT DECIMAL(13,2)'
				If @sTotalsColumnName = ''
					Set @sTotalsColumnName = 'ACCOUNTMOVEMENT'
				else
					Set @sTotalsColumnName = @sTotalsColumnName + ',' + 'ACCOUNTMOVEMENT'
			End
			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'BUDGETMOVEMENT' )
			Begin
				Insert into @tbJoinedTable VALUES ('BUDGETMOVEMENT')	
				Set @sSql = @sSql + ',' + '  BUDGETMOVEMENT DECIMAL(13,2)'
				If @sTotalsColumnName = ''
					Set @sTotalsColumnName = 'BUDGETMOVEMENT'
				else
					Set @sTotalsColumnName = @sTotalsColumnName + ',' + 'BUDGETMOVEMENT'
			End
		End		
		Else If 	@nDataItemId= 437  -- Variance%AccountMovementVsForecastMovement
			or 	@nDataItemId= 441  -- VarianceAccountMovementVsForecastMovement
		Begin
			
			If @nDataItemId= 437 	-- Variance%AccountMovementVsForecastMovement
			Begin
				Set @sColumnName = 'VAR_PCT_ACCT_FORE_MOVE'
				Set @sSql =@sColumnName +  ' DECIMAL(13,4)'
			End
			else If	@nDataItemId= 441	-- VarianceAccountMovementVsForecastMovement
			Begin
				Set @sColumnName = 'VAR_ACCT_FORE_MOVE'
				Set @sTotalsColumnName = @sColumnName
				Set @sSql = @sColumnName + ' DECIMAL(13,2)'
			End

			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'ACCOUNTMOVEMENT' )
			Begin
				Insert into @tbJoinedTable VALUES ('ACCOUNTMOVEMENT')	
				Set @sSql = @sSql + ',' + ' ACCOUNTMOVEMENT DECIMAL(13,2)'
				If @sTotalsColumnName = ''
					Set @sTotalsColumnName = 'ACCOUNTMOVEMENT'
				else
					Set @sTotalsColumnName = @sTotalsColumnName + ',' + 'ACCOUNTMOVEMENT'
			End
			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'FORECASTMOVEMENT' )
			Begin
				Insert into @tbJoinedTable VALUES ('FORECASTMOVEMENT')	
				Set @sSql = @sSql + ',' + ' FORECASTMOVEMENT DECIMAL(13,2)'
				If @sTotalsColumnName = ''
					Set @sTotalsColumnName = 'FORECASTMOVEMENT'
				else
					Set @sTotalsColumnName = @sTotalsColumnName + ',' + 'FORECASTMOVEMENT'
			End
		End		
		Else If 	@nDataItemId= 438 	-- Variance%AccountMovementYTDVsBudgetMovementYTD
			or	@nDataItemId= 442	-- VarianceAccountMovementYTDVsBudgetMovementYTD
		Begin
			If @nDataItemId= 438 	-- Variance%AccountMovementVsForecastMovement
			Begin
				Set @sColumnName = 'VAR_PCT_ACCT_YTD_BUDG_MOVE'
				Set @sSql = @sColumnName + ' DECIMAL(13,4)'
			End
			else If @nDataItemId= 442	-- VarianceAccountMovementYTDVsBudgetMovementYTD
			Begin
				Set @sColumnName = 'VAR_ACCT_YTD_BUDG_MOVE'
				Set @sTotalsColumnName = @sColumnName
				Set @sSql = @sColumnName + ' DECIMAL(13,2)'
			End

			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'ACCOUNTMOVEMENTYTD' )
			Begin
				Insert into @tbJoinedTable VALUES ('ACCOUNTMOVEMENTYTD')	
				Set @sSql = @sSql + ',' + ' ACCOUNTMOVEMENTYTD DECIMAL(13,2)'
				If @sTotalsColumnName = ''
					Set @sTotalsColumnName = 'ACCOUNTMOVEMENTYTD'
				else
					Set @sTotalsColumnName = @sTotalsColumnName + ',' + 'ACCOUNTMOVEMENTYTD'
			End
			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'BUDGETMOVEMENTYTD' )
			Begin
				Insert into @tbJoinedTable VALUES ('BUDGETMOVEMENTYTD')	
				Set @sSql = @sSql + ',' + ' BUDGETMOVEMENTYTD DECIMAL(13,2)'
				If @sTotalsColumnName = ''
					Set @sTotalsColumnName = 'BUDGETMOVEMENTYTD'
				else
					Set @sTotalsColumnName = @sTotalsColumnName + ',' + 'BUDGETMOVEMENTYTD'

			End
		End		
		Else If 	@nDataItemId= 439  -- Variance%AccountMovementYTDVsForecastMovementYTD
			or	@nDataItemId= 443  -- VarianceAccountMovementYTDVsForecastMovementYTD
		Begin
			If @nDataItemId= 439  -- Variance%AccountMovementYTDVsForecastMovementYTD
			Begin
				Set @sColumnName = 'VAR_PCT_ACCT_YTD_FORE_MOVE'
				Set @sSql =@sColumnName +  ' DECIMAL(13,4)'
			End
			else If @nDataItemId= 443  -- VarianceAccountMovementYTDVsForecastMovementYTD
			Begin
				Set @sColumnName = 'VAR_ACCT_YTD_FORE_MOVE'
				Set @sTotalsColumnName = @sColumnName
				Set @sSql =@sColumnName +  ' DECIMAL(13,2)'
			End

			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'ACCOUNTMOVEMENTYTD' )
			Begin
				Insert into @tbJoinedTable VALUES ('ACCOUNTMOVEMENTYTD')	
				Set @sSql = @sSql + ',' + ' ACCOUNTMOVEMENTYTD DECIMAL(13,2)'
				If @sTotalsColumnName = ''
					Set @sTotalsColumnName = 'ACCOUNTMOVEMENTYTD'
				else
					Set @sTotalsColumnName = @sTotalsColumnName + ',' + 'ACCOUNTMOVEMENTYTD'
			End
			If not exists(select 1 from @tbJoinedTable where TABLENAME = 'FORECASTMOVEMENTYTD' )
			Begin
				Insert into @tbJoinedTable VALUES ('FORECASTMOVEMENTYTD')	
				Set @sSql = @sSql + ',' + ' FORECASTMOVEMENTYTD DECIMAL(13,2)'
				If @sTotalsColumnName = ''
					Set @sTotalsColumnName = 'FORECASTMOVEMENTYTD'
				else
					Set @sTotalsColumnName = @sTotalsColumnName + ',' + 'FORECASTMOVEMENTYTD'
			End
		End		
								
	End
	If @sSql <> ''
	Begin
		Set @sSqlAlter = 'Alter table ' + @psTempTableName + ' ADD ' + @sSql
	--	 select @sSql
		Exec @nErrorCode=sp_executesql @sSqlAlter

		Set @sSqlAlter = 'Alter table ' + @psConsolidatedTempTable + ' ADD ' + @sSql
	--	select @sSql
		Exec @nErrorCode=sp_executesql @sSqlAlter
	End
	If @sTotalsColumnName <> ''
	Begin
		If @nCount = 1
			Set @psListOfColumns = @sTotalsColumnName
		else
			Set @psListOfColumns = @psListOfColumns + ',' + @sTotalsColumnName
	End
	-- Increment @nCount so it points to the next record in the @tblOutputRequests table 
	Set @nCount = @nCount + 1
	
End


Set @nCount = 1

if @nErrorCode =  0
Begin
	Delete from @tblOutputRequests
	-- Create an XML documwent in memory and then retrieve the information 
	-- from the rowset using OPENXML		
	Exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLOutputRequests
	
	Insert into @tblOutputRequests (PROCEDUREITEMID)
	( Select COLUMNID
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, @ptXMLOutputRequests, @idoc,@pbCalledFromCentura,null) F 
	where F.PUBLISHNAME is not null
	)
	select @nCount = @@ROWCOUNT - 1, 
		@nErrorCode = @@ERROR,
		@nMaxRequestedColumns	= @@IDENTITY
	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   

	-- deallocate the xml document handle when finished.
	Exec sp_xml_removedocument @idoc
End
Set @nCount = @nMaxRequestedColumns  - @nCount


While @nCount <= @nMaxRequestedColumns
and   @nErrorCode=0
Begin
	Set @sColumnName		= ''
	Set @sPercentageColumnId 	= ''

	Select	@nDataItemId = B.DATAITEMID
	from	@tblOutputRequests A join QUERYDATAITEM B on (A.PROCEDUREITEMID = B.PROCEDUREITEMID)
	where	ROWNUMBER = @nCount

	Set @nErrorCode = @@ERROR

	If @nErrorCode=0
	Begin

		If @nDataItemId is null
			Set @sColumnName=''
		Else If @nDataItemId = 418 -- AccountBalance
			Set @sColumnName ='ACCOUNTBALANCE'
		Else If @nDataItemId = 419--AccountBalanceForPreviousYear
			Set @sColumnName ='PREVIOUSACCOUNTBALANCE'
		Else If @nDataItemId= 420 -- AccountMovement
			Set @sColumnName ='ACCOUNTMOVEMENT'
		Else If @nDataItemId= 421 -- 'AccountMovementForPreviousYear'
			Set @sColumnName ='PREVIOUSACCOUNTMOVEMENT'
		Else If @nDataItemId= 422 -- AccountMovementForPreviousYearYTD
			Set @sColumnName ='PREVIOUSACCOUNTMOVEMENTYTD'
		Else If @nDataItemId= 423 -- 'AccountMovementYTD'
			Set @sColumnName ='ACCOUNTMOVEMENTYTD'
		Else If @nDataItemId= 424  -- BudgetBalance
			Set @sColumnName ='BUDGETBALANCE'
		Else If @nDataItemId= 425 -- BudgetBalanceForPreviousYear
			Set @sColumnName ='PREVIOUSBUDGETBALANCE'
		Else If @nDataItemId= 426 -- BudgetMovement
			Set @sColumnName ='BUDGETMOVEMENT'			
		Else If @nDataItemId= 427 -- BudgetMovementForPreviousYear
			Set @sColumnName ='PREVIOUSBUDGETMOVEMENT'
		Else If @nDataItemId= 428 -- BudgetMovementForPreviousYearYTD
			Set @sColumnName ='PREVIOUSBUDGETMOVEMENTYTD'
		Else If @nDataItemId= 429 -- BudgetMovementYTD
			Set @sColumnName ='BUDGETMOVEMENTYTD'
		Else If @nDataItemId= 430 --ForecastBalance 
			Set @sColumnName ='FORECASTBALANCE'
		Else If @nDataItemId= 431  -- ForecastBalanceForPreviousYear
			Set @sColumnName ='PREVIOUSFORECASTBALANCE'
		Else If @nDataItemId= 432  -- ForecastMovement
			Set @sColumnName ='FORECASTMOVEMENT'
		Else If @nDataItemId= 433  -- ForecastMovementForPreviousYear
			Set @sColumnName ='PREVIOUSFORECASTMOVEMENT'
		Else If @nDataItemId= 434  -- ForecastMovementForPreviousYearYTD
			Set @sColumnName ='PREVIOUSFORECASTMOVEMENTYTD'
		Else If @nDataItemId= 435  -- ForecastMovementYTD
			Set @sColumnName ='FORECASTMOVEMENTYTD'
		Else If @nDataItemId= 436 	-- Variance%AccountMovementVsBudgetMovement
		Begin
			Set @sColumnName ='VAR_PCT_ACCT_BUDG_MOVE'
			Set @sPercentageColumnId = '436'
		End
		Else If @nDataItemId = 437	-- Variance%AccountMovementVsForecastMovement
		Begin	
			Set @sColumnName ='VAR_PCT_ACCT_FORE_MOVE'
			Set @sPercentageColumnId = '437'
		End
		Else If 	@nDataItemId= 438  -- Variance%AccountMovementYTDVsBudgetMovementYTD
		Begin
			Set @sColumnName ='VAR_PCT_ACCT_YTD_BUDG_MOVE'
			Set @sPercentageColumnId = '438'
		End
		Else if	@nDataItemId= 439  -- Variance%AccountMovementYTDVsForecastMovementYTD
		Begin
			Set @sColumnName ='VAR_PCT_ACCT_YTD_FORE_MOVE'
			Set @sPercentageColumnId = '439'
		End
		Else If @nDataItemId= 440 -- VarianceAccountMovementVsBudgetMovement
			Set @sColumnName ='VAR_ACCT_BUDG_MOVE'
		Else If @nDataItemId= 441	-- VarianceAccountMovementVsForecastMovement
			Set @sColumnName ='VAR_ACCT_FORE_MOVE'
		Else If @nDataItemId= 442  -- VarianceAccountMovementYTDVsBudgetMovementYTD
			Set @sColumnName ='VAR_ACCT_YTD_BUDG_MOVE'
		Else If @nDataItemId= 443  -- VarianceAccountMovementYTDVsForecastMovementYTD
			Set @sColumnName ='VAR_ACCT_YTD_FORE_MOVE'

		If @psSelectClause = ''
			set @psSelectClause = @sColumnName
		Else
			Set @psSelectClause = @psSelectClause + ', ' + @sColumnName

		If @sPercentageColumnId <> ''
		Begin
			If @psListOfPercentageColumns = ''
				Set @psListOfPercentageColumns = @sPercentageColumnId 
			Else
				Set @psListOfPercentageColumns = @psListOfPercentageColumns + ', ' + @sPercentageColumnId 
		End
	End

	Set @nCount = @nCount + 1
End

Return @nErrorCode
go

Grant execute on dbo.gl_FSAlterTempTable  to public
go
