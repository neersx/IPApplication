-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_ListAutoFillCopyAmounts
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[gl_ListAutoFillCopyAmounts]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.gl_ListAutoFillCopyAmounts.'
	Drop procedure [dbo].[gl_ListAutoFillCopyAmounts]
End
Print '**** Creating Stored Procedure dbo.gl_ListAutoFillCopyAmounts...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.gl_ListAutoFillCopyAmounts
(
	@pnUserIdentityId	int		= null,
	@psCulture		nvarchar(10) 	= null,
	@pnEntityNo		int,
	@psProfitCentreCode	nvarchar(6),
	@pnLedgerAccountId	int,
	@pnFinancialYear	int,
	@pnItemToCopy		int, -- 1: Actual, 2: Budget, 3: Forecast
	@pbMovement		int  -- 1: Movement, 0: Balance
)
as
-- PROCEDURE:	gl_ListAutoFillCopyAmounts
-- VERSION :	3
-- SCOPE:	InProma
-- DESCRIPTION:	Returns a result set that contains either 
--		Actual / Budget / Forecast amounts (balance/movement)
--		depending on the parameters supplied.
--		This SP uses the result set returned from gl_ListAccountBalance, therefore
--		if the result set returned by gl_ListAccountBalance is changed, the table
--		#LISTACCTBALTEMP is required to change accordingly as well.
--
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 12-02-2004  	SFOO	8849	1	Procedure created
-- 06 Aug 2004	AB	8035	2	Add collate database_default to temp table definitions
-- 15 Feb 2005	CR	10821	3	Updated calls to gl_ListAccountBalance

Begin
	SET NOCOUNT ON
	SET CONCAT_NULL_YIELDS_NULL OFF

	Declare @nErrorCode		int,
		@nRowCount 		int,
		@nPeriodFrom		int,
		@nPeriodTo		int,
		@nMovBalanceInd		int,
		-- CONSTANTS
		@ACTUAL			int,
		@BUDGET			int,
		@FORECAST		int,
		--
		@sQuotedProfitCentre	nvarchar(9),
		@sAccountIdInString	nvarchar(12),
		@sSql			nvarchar(3000),
		@sMessage		nvarchar(397)
		
	Set @nErrorCode = 0

	-- CONSTANTS
	Set @ACTUAL = 1
	Set @BUDGET = 2
	Set @FORECAST = 3

	If (@pnEntityNo is Null) OR
		(@psProfitCentreCode is Null) OR
		(@pnLedgerAccountId is Null) OR 
		(@pnFinancialYear is Null) OR
		(@pnItemToCopy is Null) OR 
		(@pbMovement is Null)
	Begin
		Set @sMessage = N'gl_ListAutoFillCopyAmounts: Missing mandatory ' +
				N'parameters. Please make sure all mandatory parameters ' +
				N'are supplied.'
		RAISERROR(@sMessage, 16, 1)
		Set @nErrorCode = @@Error
	End

	If @nErrorCode = 0
	Begin
	  If (@pnItemToCopy = @ACTUAL) -- Actual
	  Begin
		CREATE TABLE #LISTACCTBALTEMP
		(
			ANALYSISTYPEID 		Int,
			ANALYSISTYPENAME 	Varchar(80)	collate database_default,
			ANALYSISCODEID 		Int,
			ANALYSISCODENAME 	nvarchar(40)	collate database_default, 
			NAMENO 			Int, 
			NAMECODE 		varchar(10)	collate database_default, 
			NAME 			varchar(254)	collate database_default,
			PROFITCENTRECODE 	varchar(6)	collate database_default, 
			PROFITCENTREDESC 	varchar(50)	collate database_default,
			LEDGERACCOUNTID 	Int, 
			LEDGERACCOUNTCODE 	nvarchar(20)	collate database_default, 
			LEDGERACCOUNTDESC 	nvarchar(100)	collate database_default,
			PERIODID 		Int, 
			PERIODLABEL 		varchar(20)	collate database_default, 
			AMOUNT 			dec(13,2)
		)
		Set @nErrorCode = @@ERROR

		If @nErrorCode = 0
		Begin
			Exec @nErrorCode=dbo.gl_FinancialYearToPeriodRange @pnFinancialYear, 
									   @pnFinancialYear,
									   @nPeriodFrom output,
									   @nPeriodTo output
		End

		If @nErrorCode = 0
		Begin
			Set @sQuotedProfitCentre = N'''' + @psProfitCentreCode + N''''
			Set @sAccountIdInString = CONVERT(nvarchar(12), @pnLedgerAccountId)
			If @pbMovement = 1
				Set @nMovBalanceInd = 1
			Else If @pbMovement = 0
				Set @nMovBalanceInd = 2

			Insert into #LISTACCTBALTEMP
			Exec dbo.gl_ListAccountBalance @pnRowCount=@nRowCount,
							@pnUserIdentityId=@pnUserIdentityId,
							@psCulture=@psCulture,
							@pnAcctEntity=@pnEntityNo,
							@psProfitCentres=@sQuotedProfitCentre,
							@psAccountIds=NULL,
							@psAccounts=@sAccountIdInString,
							@pnPeriodFrom=@nPeriodFrom,
							@pnPeriodTo=@nPeriodTo,
							@pnMovBalanceInd=@nMovBalanceInd
			Set @nErrorCode = @@ERROR
		End
		
		If @nErrorCode = 0
		Begin
			Set @sSql = N'
				Select 
					CONVERT(int, SUBSTRING(CONVERT(Nvarchar(12), TP.PERIODID), 5, 2)) as PERIODSEQUENCE,
					AMOUNT
				from 
					(
					 Select *
					 from PERIOD 
					 where LEFT( CONVERT(nvarchar(12), PERIODID), 4) =
						CONVERT(nvarchar(12), @pnFinancialYear)
					) TP
				    Left Outer Join
					#LISTACCTBALTEMP LAB
				    on (LAB.PERIODID = TP.PERIODID)
				order by TP.PERIODID '
			Exec @nErrorCode=sp_executesql @sSql,
							N'@pnFinancialYear int',
							@pnFinancialYear
		End	
	  End
	  Else If (@pnItemToCopy = @BUDGET OR @pnItemToCopy = @FORECAST) -- Budget/Forecast
	  Begin
		Set @sSql = N'
			Select
			      CONVERT(int, SUBSTRING(CONVERT(Nvarchar(12), DTP.PERIODID), 5, 2)) as PERIODSEQUENCE,
			       Case @pnItemToCopy
				when @BUDGET then DTB.BUDGETAMOUNT
				when @FORECAST then DTB.FRCSTAMOUNT
			       End as AMOUNT			       
			from
				(
				 Select P.*
				 From PERIOD P
				 Where LEFT(CONVERT(nvarchar(12), P.PERIODID), 4) = 
						CONVERT(nvarchar(12), @pnFinancialYear)
				 ) DTP
			    Left outer join
				(
				 Select B.*
				 From BUDGET B 
				 Where B.ENTITYNO = @pnEntityNo
				 And B.PROFITCENTRECODE = @psProfitCentreCode
				 And B.LEDGERACCOUNTID = @pnLedgerAccountId
				 And LEFT(CONVERT(nvarchar(12), B.PERIODID), 4) =
						CONVERT(nvarchar(12), @pnFinancialYear)
				 ) DTB
			    ON (DTB.PERIODID = DTP.PERIODID)
			Order by DTP.PERIODID '

		--print @sSql
		Exec @nErrorCode=sp_executesql @sSql,
						N'@pnItemToCopy       int,
						  @BUDGET	      int,
						  @FORECAST           int,
						  @pnEntityNo	      int,
						  @psProfitCentreCode nvarchar(6),
						  @pnLedgerAccountId  int,
						  @pnFinancialYear    int',
						@pnItemToCopy,
						@BUDGET,
						@FORECAST,
						@pnEntityNo,
						@psProfitCentreCode,
						@pnLedgerAccountId,
						@pnFinancialYear
   	  End
	End

	Return @nErrorCode
End	
GO

Grant execute on dbo.gl_ListAutoFillCopyAmounts to public
GO

