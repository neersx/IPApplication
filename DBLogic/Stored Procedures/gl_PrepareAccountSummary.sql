-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_PrepareAccountSummary
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[gl_PrepareAccountSummary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.gl_PrepareAccountSummary.'
	Drop procedure [dbo].[gl_PrepareAccountSummary]
End
Print '**** Creating Stored Procedure dbo.gl_PrepareAccountSummary...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.gl_PrepareAccountSummary
(
	@pnUserIdentityId	int		= null,		
	@psCulture		nvarchar(10) 	= null,
	@pnEntityNo		int		= null, -- Optional when @pbConsolidated is 1
	@psProfitCentreCodes	nvarchar(2000)	= null, -- Optional when @pbConsolidated is 1
	@pnLedgerAccountId	int	 	      , -- Mandatory
	@pnFinancialYear	int		      , -- Mandatory
	@pbBudgetMovement	bit		      , -- Mandatory
	@pbConsolidated		bit		        -- Mandatory
)
as
-- PROCEDURE:	gl_PrepareAccountSummary
-- VERSION :	4
-- SCOPE:	InProma
-- DESCRIPTION:	Prepare Account Summary information.
--		Must have #ACCOUNTSUMMARY table created first before 
-- 		calling this stored procedure. See gl_ListAccountBudgetFigures for details.
--		This SP uses the result set returned from gl_ListAccountBalance, therefore
--		if the result set returned by gl_ListAccountBalance is changed, the table
--		#LISTACCTBALTEMP is required to change accordingly as well.
--
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19-FEB-2004  SFoo	8851	1.0.0	Procedure created
-- 06 Aug 2004	AB	8035	2	Add collate database_default to temp table definitions
-- 15 Feb 2005	CR	10821	3	Updated calls to gl_ListAccountBalance
-- 20 Sep 2007	CR	14722	4	Updated calls to gl_ListAccountBalance so that @pnAccountId
-- 					is passed as nvarchar.

Begin
	SET NOCOUNT ON
	SET CONCAT_NULL_YIELDS_NULL OFF

	Declare @nErrorCode 		int,
		@nPeriodFrom 		int,
		@nPeriodTo 		int,
		@nDummyRowCount 	int,
		@nMovBalanceInd		int,
		@nEntityNo 		int,
		@nPreviousFinancialYear	int,
		@sSql 			nvarchar(1000),
		@sLedgerAccountId	nvarchar(12)

	Set @nErrorCode = 0
	Set @sLedgerAccountId = CONVERT(nvarchar(12), @pnLedgerAccountId)

	If @nErrorCode = 0
	Begin
		CREATE TABLE #LISTACCTBALTEMP
		(
			ANALYSISTYPEID 		Int,
			ANALYSISTYPENAME 	Varchar(80)	collate database_default,
			ANALYSISCODEID 		Int,
			ANALYSISCODENAME 	Nvarchar(40)	collate database_default, 
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
	End
	
	If @nErrorCode = 0
	Begin
		Set @nPreviousFinancialYear = @pnFinancialYear-1
		Exec @nErrorCode=dbo.gl_FinancialYearToPeriodRange @pnFinancialYearFrom=@nPreviousFinancialYear,
								   @pnFinancialYearTo=@pnFinancialYear,
								   @pnPeriodFrom=@nPeriodFrom output,
								   @pnPeriodTo=@nPeriodTo output
	End

	If @nErrorCode = 0
	Begin
		If @pbConsolidated = 0 -- Not consolidated
		Begin
			-- Prepare Actual Account Balances/Movements.
			If @pbBudgetMovement = 1
				Set @nMovBalanceInd = 1
			Else If @pbBudgetMovement = 0
				Set @nMovBalanceInd = 2

			Insert into #LISTACCTBALTEMP
				exec gl_ListAccountBalance @nDummyRowCount, @pnUserIdentityId, @psCulture,
								@pnEntityNo, @psProfitCentreCodes, 
								NULL, @sLedgerAccountId,
								@nPeriodFrom, @nPeriodTo, @nMovBalanceInd
			Set @nErrorCode = @@ERROR

			If @nErrorCode = 0
			Begin
				Insert into #ACCOUNTSUMMARY
				Select SKEL.ENTITYNO, SKEL.PROFITCENTRECODE, SKEL.ACCOUNTID, SKEL.PERIODID,
					PREV.AMOUNT, SEL.AMOUNT
				from
					#SKELETON SKEL
						left outer join
					(
					 Select *
					 from #LISTACCTBALTEMP
					 where CONVERT(int, LEFT(CONVERT(nvarchar(12), PERIODID), 4)) = @pnFinancialYear-1
					) PREV on (PREV.NAMENO = SKEL.ENTITYNO and
						   PREV.PROFITCENTRECODE = SKEL.PROFITCENTRECODE and
						   PREV.LEDGERACCOUNTID = SKEL.ACCOUNTID and
						   SUBSTRING(CONVERT(nvarchar(12), PREV.PERIODID), 5, 2) = 
							SUBSTRING(CONVERT(nvarchar(12), SKEL.PERIODID), 5, 2) )
		    				left outer join				    
					(
					 Select *
					 from #LISTACCTBALTEMP
					 where CONVERT(int, LEFT(CONVERT(nvarchar(12), PERIODID), 4)) = @pnFinancialYear
					) SEL on (SEL.NAMENO = SKEL.ENTITYNO and
						  SEL.PROFITCENTRECODE = SKEL.PROFITCENTRECODE and
						  SEL.LEDGERACCOUNTID = SKEL.ACCOUNTID and
						  SEL.PERIODID = SKEL.PERIODID)
				Set @nErrorCode = @@ERROR				
			End
		End
		Else If @pbConsolidated = 1
		Begin
			If @nErrorCode = 0
			Begin
				CREATE TABLE #PREVIOUSYEARACCTSUMMARY
				(
					ACCOUNTID 	int,
					PERIODID 	int,
					AMOUNT 		decimal(13, 2),
				)
				Set @nErrorCode = @@ERROR
			End

			If @nErrorCode = 0
			Begin
				CREATE TABLE #SELECTEDYEARACCTSUMMARY
				(
					ACCOUNTID 	int,
					PERIODID 	int,
					AMOUNT 		decimal(13, 2),
				)
				Set @nErrorCode = @@ERROR
			End

			If @nErrorCode = 0
			Begin			
				Select @nEntityNo=MIN(NAMENO)
				from SPECIALNAME
				where ENTITYFLAG = 1
				Set @nErrorCode = @@ERROR
			End

			While (@nEntityNo is not NULL) and (@nErrorCode = 0)
			Begin
				-- Prepare Actual Account Balances/Movements.
				If @pbBudgetMovement = 1
					Set @nMovBalanceInd = 1
		        	Else If @pbBudgetMovement = 0
		        		Set @nMovBalanceInd = 2
				
				Insert into #LISTACCTBALTEMP
				Exec dbo.gl_ListAccountBalance @nDummyRowCount, @pnUserIdentityId, @psCulture,
								@nEntityNo, NULL, 
								NULL, @sLedgerAccountId,
								@nPeriodFrom, @nPeriodTo, @nMovBalanceInd
				Set @nErrorCode = @@ERROR

				If @nErrorCode = 0
				Begin
					Set @sSql = 'Select @nEntityNo=MIN(NAMENO)
							from SPECIALNAME
							where ENTITYFLAG = 1
							and NAMENO > @nPreviousEntityNo'
					Exec @nErrorCode=sp_executesql @sSql, 
									N'@nEntityNo int output,
									  @nPreviousEntityNo int',
									@nEntityNo output,
									@nEntityNo
				End				
			End

			If @nErrorCode = 0
			Begin
				Insert into #PREVIOUSYEARACCTSUMMARY
				Select LEDGERACCOUNTID, PERIODID, SUM(AMOUNT)
				from
					#LISTACCTBALTEMP
				where CONVERT(int, LEFT(CONVERT(nvarchar(12), PERIODID), 4)) = @pnFinancialYear-1
				group by LEDGERACCOUNTID, PERIODID 
				Set @nErrorCode = @@ERROR
			End

			If @nErrorCode = 0
			Begin
				Insert into #SELECTEDYEARACCTSUMMARY
				Select LEDGERACCOUNTID, PERIODID, SUM(AMOUNT)
				from
					#LISTACCTBALTEMP
				where CONVERT(int, LEFT(CONVERT(nvarchar(12), PERIODID), 4)) = @pnFinancialYear
				group by LEDGERACCOUNTID, PERIODID 
				Set @nErrorCode = @@ERROR
			End

			If @nErrorCode = 0
			Begin
				Insert into #ACCOUNTSUMMARY
				select null, null, SKEL.ACCOUNTID, SKEL.PERIODID, PREV.AMOUNT, SEL.AMOUNT
				from 
					#SKELETON SKEL
						left outer join
					#PREVIOUSYEARACCTSUMMARY PREV on (PREV.ACCOUNTID = SKEL.ACCOUNTID and
									  SUBSTRING(CONVERT(nvarchar(12), PREV.PERIODID), 5, 2) = 
										SUBSTRING(CONVERT(nvarchar(12), SKEL.PERIODID), 5, 2))
						left outer join
					#SELECTEDYEARACCTSUMMARY SEL on (SEL.ACCOUNTID = SKEL.ACCOUNTID and
									 SEL.PERIODID = SKEL.PERIODID)
				
			End

			Drop table #PREVIOUSYEARACCTSUMMARY
			Drop table #SELECTEDYEARACCTSUMMARY
		End		    
	End

	Drop table #LISTACCTBALTEMP

	Return @nErrorCode
End
GO

Grant execute on dbo.gl_PrepareAccountSummary to public
GO

