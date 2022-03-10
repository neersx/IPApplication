-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_ListAcctBudgetEntryDetails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[gl_ListAcctBudgetEntryDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.gl_ListAcctBudgetEntryDetails.'
	Drop procedure [dbo].[gl_ListAcctBudgetEntryDetails]
End
Print '**** Creating Stored Procedure dbo.gl_ListAcctBudgetEntryDetails...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.gl_ListAcctBudgetEntryDetails
(
	@pnUserIdentityId	Int		= null,
	@psCulture		nvarchar(10) 	= null,
	@pnEntityNo		Int,
	@psProfitCentreCode	nvarchar(6),
	@pnLedgerAccountId	Int,
	@pnFinancialYear	Int,
	@pbBudgetMovement	Bit
)
as
-- PROCEDURE:	gl_ListAcctBudgetEntryDetails
-- VERSION:	7
-- SCOPE:	InProma
-- DESCRIPTION:	Return the result that is required by the dlgBudgetForecastEntry window.
--		This SP uses the result set returned from gl_ListAccountBalance, therefore
--		if the result set returned by gl_ListAccountBalance is changed, the table
--		#LISTACCTBALTEMP is required to change accordingly as well.
--
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19-Feb-2004  SFoo	8848	1	Procedure created
-- 06 Aug 2004	AB	8035	2	Add collate database_default to temp table definitions
-- 23 Sep 2004	AT	10426	3	Return budget amounts based on account type.
-- 08 Feb 2005	MB	10555	4	Fixed an error in SQL
-- 15 Feb 2005	CR	10821	5	Updated calls to gl_ListAccountBalance
-- 20 Sep 2007	CR	14722	6	Updated calls to gl_ListAccountBalance so that @pnAccountId
-- 					is passed as nvarchar.
-- 23 Jun 2010	DL	17941	7	Sorting the result by period id.

Begin
	SET NOCOUNT ON
	SET CONCAT_NULL_YIELDS_NULL OFF
	
	Declare @nErrorCode 		Int,
		@nPeriodFrom 		Int,
		@nPeriodTo 		Int,
		@nMovBalInd		Int,
		@nRowCount		Int,
		@sSql			Nvarchar(4000),
		@sQuotedProfitCentre 	Nvarchar(30),
		@nPreviousFinancialYear Int,
		@sAccountId		nvarchar(30)

	Set @nErrorCode = 0
	Set @sAccountId = CAST(@pnLedgerAccountId AS nvarchar(30))
	
	If @nErrorCode = 0
	Begin
		/* local temp table use to store result set
		   returned from gl_ListAccountBalance. */
		CREATE TABLE #LISTACCTBALTEMP
		(
			ANALYSISTYPEID 		Int,
			ANALYSISTYPENAME 	Nvarchar(80) 	collate database_default,
			ANALYSISCODEID 		Int,
			ANALYSISCODENAME 	Nvarchar(40) 	collate database_default, 
			NAMENO 			Int, 
			NAMECODE 		varchar(10) 	collate database_default, 
			NAME 			varchar(254) 	collate database_default,
			PROFITCENTRECODE 	varchar(6) 	collate database_default, 
			PROFITCENTREDESC 	varchar(50) 	collate database_default,
			ACCOUNTID 		Int, 
			LEDGERACCOUNTCODE 	nvarchar(20) 	collate database_default, 
			LEDGERACCOUNTDESC 	nvarchar(100) 	collate database_default,
			PERIODID 		Int, 
			PERIODLABEL 		varchar(20) 	collate database_default, 
			AMOUNT 			dec(13,2)
		)
		Set @nErrorCode = @@ERROR
	End

	If @nErrorCode = 0
	Begin
		Set @nPreviousFinancialYear = @pnFinancialYear - 1
		Exec @nErrorCode=dbo.gl_FinancialYearToPeriodRange @nPreviousFinancialYear,
								   @pnFinancialYear,
								   @nPeriodFrom output,
								   @nPeriodTo output
	End

	If @nErrorCode = 0
	Begin
		Set @sQuotedProfitCentre = N''''+@psProfitCentreCode+N''''
		If @pbBudgetMovement = 1
			Set @nMovBalInd = 1
		Else If @pbBudgetMovement = 0
			Set @nMovBalInd = 2

		Insert into #LISTACCTBALTEMP
		Exec @nErrorCode=dbo.gl_ListAccountBalance
						@pnRowCount=@nRowCount,
						@pnUserIdentityId=@pnUserIdentityId,
						@psCulture=@psCulture,
						@pnAcctEntity=@pnEntityNo,
						@psProfitCentres=@sQuotedProfitCentre,
						@psAccountIds=NULL,
						@psAccounts=@sAccountId,
						@pnPeriodFrom=@nPeriodFrom,
						@pnPeriodTo=@nPeriodTo,
						@pnMovBalanceInd=@nMovBalInd

	End

	If @nErrorCode = 0
	Begin
		Set @sSql = N'
		Select  @pnEntityNo as ENTITYNO,
			@psProfitCentreCode as PROFITCENTRECODE,
		     	@pnLedgerAccountId as ACCOUNTID,
			P.PERIODID,
			P.LABEL,
			CONVERT(Int, SUBSTRING(CONVERT(Nvarchar(12), P.PERIODID), 5, 2)) as PERIODSEQUENCE,
			(PREV.AMOUNT * cast(TC.USERCODE as smallint)) as PREVAMOUNT,
			(CURR.AMOUNT * cast(TC.USERCODE as smallint)) as CURRAMOUNT,
			B.BUDGETAMOUNT,
			B.BUDGETLASTMODIFIED,
			B.BUDGETCREATIONDATE,
			B.FRCSTAMOUNT,
			B.FRCSTLASTMODIFIED,
			B.FRCSTCREATIONDATE
		From
			(
			 Select *
			 From PERIOD
			 Where CONVERT(Int, LEFT(CONVERT(Nvarchar(12), PERIODID), 4)) = @pnFinancialYear
			) P
		Left outer join
			(				-- Current year account figures
			 Select *
			 From #LISTACCTBALTEMP
			 Where LEFT(CONVERT(Nvarchar(12), PERIODID), 4) = 
				CONVERT(Nvarchar(12), @pnFinancialYear)
			) CURR on (CURR.PERIODID = P.PERIODID)
		Left outer join
			(				-- Previous year account figures
			 Select *
			 From #LISTACCTBALTEMP
			 Where LEFT(CONVERT(Nvarchar(12), PERIODID), 4) = 
				CONVERT(Nvarchar(12), @pnFinancialYear-1)
			) PREV on (SUBSTRING(CONVERT(Nvarchar(12), PREV.PERIODID), 5, 2)  = 	-- Join on Period sequence
					SUBSTRING(CONVERT(Nvarchar(12), P.PERIODID), 5, 2))
		Left outer join
			BUDGET B on (B.ENTITYNO = @pnEntityNo and
				     B.PROFITCENTRECODE = @psProfitCentreCode and
				     B.LEDGERACCOUNTID = @pnLedgerAccountId and
				     B.PERIODID = P.PERIODID)
		join
			LEDGERACCOUNT LA on (LA.ACCOUNTID = @pnLedgerAccountId)
		join
			TABLECODES TC on (TC.TABLECODE = LA.ACCOUNTTYPE)
		Order by 1,2,3,4 '

		--print @sSql
		Exec @nErrorCode=sp_executesql @sSql,
						N'@pnEntityNo int,
						  @psProfitCentreCode Nvarchar(6),
						  @pnLedgerAccountId Int,
						  @pnFinancialYear Int',
						@pnEntityNo,
						@psProfitCentreCode,
						@pnLedgerAccountId,
						@pnFinancialYear
	End

	Return @nErrorCode
End
GO

Grant execute on dbo.gl_ListAcctBudgetEntryDetails to public
GO

