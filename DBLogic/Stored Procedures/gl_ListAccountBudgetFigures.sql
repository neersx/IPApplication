-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_ListAccountBudgetFigures
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[gl_ListAccountBudgetFigures]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.gl_ListAccountBudgetFigures.'
	Drop procedure [dbo].[gl_ListAccountBudgetFigures]
End
Print '**** Creating Stored Procedure dbo.gl_ListAccountBudgetFigures...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.gl_ListAccountBudgetFigures
(
	@pnUserIdentityId	int		= null,		
	@psCulture		nvarchar(10) 	= null,
	@pnEntityNo		int		= null, -- Optional when @pbConsolidated is 1
	@psProfitCentreCodes	ntext		= null, -- Optional when @pbConsolidated is 1
	@pnLedgerAccountId	int	 	      , -- Mandatory
	@pnFinancialYear	int		      , -- Mandatory
	@pbBudgetMovement	bit		      , -- Mandatory
	@pbConsolidated		bit		      , -- Mandatory
	@pnAnalysisTypeId	int		      ,
	@psAnalysisCodeIds	ntext		= null
)
as
-- PROCEDURE:	gl_ListAccountBudgetFigures
-- VERSION :	6
-- SCOPE:	InProma
-- DESCRIPTION:	List Account and Budget forecast informations.
--
-- MODIFICATIONS :
-- Date		Who	SQA	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 19-FEB-2004  SFOO	8851	1	Procedure created
-- 06 Aug 2004	AB	8035	2	Add collate database_default to temp table definitions
-- 23 Sep 2004	AT	10426	3	Return budget amounts based on account type.
-- 04 Feb 2005	MB	10822	4	Display Profit Centre Code and Description.
-- 19 SEP 2007	CR	14722	5	Change @psProfitCentreCodes and @psAnalysisCodeIds to ntext and added code 
--					to convert back to nvarchar before subsequently using.
-- 26 SEP 2007 CR	14722	6	Corrected reference in to @psProfitCentreCodes in logic to refer to 
--					new local variable @sProfitCentreCodes. Fixed clashing Table aliases


Begin
	SET NOCOUNT ON
	SET CONCAT_NULL_YIELDS_NULL OFF

	Declare @nErrorCode int,
		@sSql nvarchar(4000),
		@sMessage nvarchar(397),
		@sProfitCentreCodes	nvarchar(2000),
		@sAnalysisCodeIds	nvarchar(1000)
		

	Set @nErrorCode = 0
	
	Set @sProfitCentreCodes	= CAST(@psProfitCentreCodes AS nvarchar(2000))
	If  @sProfitCentreCodes	= ''
		Set @sProfitCentreCodes	= NULL

	Set @sAnalysisCodeIds = CAST(@psAnalysisCodeIds AS nvarchar(1000))
	If @sAnalysisCodeIds = ''
		Set @sAnalysisCodeIds = NULL

	-- Make sure Entity and Profit Centres are provided and consolidation is off
	If (@pbConsolidated = 0)
	Begin
		If (@pnEntityNo IS NULL)
		Begin
			Set @sMessage = 'gl_ListAccountBudgetFigures: Entity number must be provided ' +
					'when consolidation flag is turned off.'
			RAISERROR(@sMessage, 16, 1)
			Set @nErrorCode = @@Error
		End
	End
	Else If (@pbConsolidated = 1)
	Begin
		Set @pnEntityNo = Null
		Set @sProfitCentreCodes = Null
	End

	
	-- Build skeleton ( master table )
	If @nErrorCode = 0
	Begin
		CREATE TABLE #SKELETON
		( 
			ENTITYNO 		int, 
			PROFITCENTRECODE 	nvarchar(6) 	collate database_default, 
			PROFITCENTREDESC 	nvarchar(50)	collate database_default,
			ACCOUNTID 		int, 
			ACCOUNTCODE 		nvarchar(100) 	collate database_default,
			ACCOUNTDESC 		nvarchar(100) 	collate database_default,
			PERIODID 		int, 
			PERIODLABEL 		varchar(20)	collate database_default 
		)
		Set @nErrorCode = @@ERROR
	End

	If @nErrorCode = 0
	Begin
		Create index indexSKELETON_PERIODID on #SKELETON ( PERIODID )
		Set @nErrorCode = @@ERROR
	End

	If @nErrorCode = 0
	Begin
		Create index indexSKELETON_PROFITCENTRECODE on #SKELETON ( PROFITCENTRECODE )
		Set @nErrorCode = @@ERROR
	End

	If @nErrorCode = 0
	Begin
		Create index indexSKELETON_ACCOUNTID on #SKELETON ( ACCOUNTID )
		Set @nErrorCode = @@ERROR
	End

	If @nErrorCode = 0
	Begin
		If @pbConsolidated = 0
		Begin
			If @sProfitCentreCodes is not Null
			Begin
				Set @sSql = '
					Insert into #SKELETON
					Select PC.ENTITYNO, PC.PROFITCENTRECODE, PC.DESCRIPTION, 
						LA.ACCOUNTID, LA.ACCOUNTCODE, LA.DESCRIPTION,
						P.PERIODID, P.LABEL
					from
						PERIOD P
							cross join
  						PROFITCENTRE PC
							cross join
					 	LEDGERACCOUNT LA
					where CONVERT(int, LEFT(CONVERT(nvarchar(12), P.PERIODID), 4)) = @pnFinancialYear
					and   PC.PROFITCENTRECODE in (' + @sProfitCentreCodes + ')
					and   PC.ENTITYNO = @pnEntityNo
					and   LA.ACCOUNTID = @pnLedgerAccountId'

				Exec @nErrorCode=sp_executesql @sSql,
								N'@pnEntityNo int,
								  @pnFinancialYear int,
								  @pnLedgerAccountId int',
								@pnEntityNo,
								@pnFinancialYear,
								@pnLedgerAccountId
			End
    			Else
	    		Begin
				Set @sSql = '
					Insert into #SKELETON
					Select PC.ENTITYNO, PC.PROFITCENTRECODE, PC.DESCRIPTION, 
						LA.ACCOUNTID, LA.ACCOUNTCODE, LA.DESCRIPTION,
						P.PERIODID, P.LABEL
					from 
						PERIOD P
							cross join
						PROFITCENTRE PC
							cross join
						LEDGERACCOUNT LA
					where CONVERT(int, LEFT(CONVERT(nvarchar(12), P.PERIODID), 4)) = @pnFinancialYear
					and   PC.ENTITYNO = @pnEntityNo
					and   LA.ACCOUNTID = @pnLedgerAccountId'

				Exec @nErrorCode=sp_executesql @sSql,
								N'@pnEntityNo int,
								  @pnFinancialYear int,
								  @pnLedgerAccountId int',
								@pnEntityNo,
								@pnFinancialYear,
								@pnLedgerAccountId
			End			
		End
		Else If @pbConsolidated = 1
		Begin
			Set @sSql = '
				Insert into #SKELETON
				Select null, null, null, 
					LA.ACCOUNTID, LA.ACCOUNTCODE, LA.DESCRIPTION,
					P.PERIODID, P.LABEL
				from 
					LEDGERACCOUNT LA
						cross join
					PERIOD P
				where CONVERT(int, LEFT(CONVERT(nvarchar(12), P.PERIODID), 4)) = @pnFinancialYear
				and   LA.ACCOUNTID = @pnLedgerAccountId'

			Exec @nErrorCode=sp_executesql @sSql,
							N'@pnFinancialYear int,
							  @pnLedgerAccountId int',
							@pnFinancialYear,
							@pnLedgerAccountId
		End
	End

	--Debug
	--SELECT * FROM #SKELETON

	-- Prepare Account Movement/Balance
	If @nErrorCode = 0
	Begin
		Create table #ACCOUNTSUMMARY
		(
			ENTITYNO 		int,
			PROFITCENTRECODE 	nvarchar(6) collate database_default,
			LEDGERACCOUNTID 	int,
			PERIODID 		int,
			PREVIOUSYEARAMOUNT 	decimal(13, 2),
			SELECTEDYEARAMOUNT 	decimal(13, 2)
		)
		Set @nErrorCode = @@ERROR
	End

	If @nErrorCode = 0
	Begin
		Exec @nErrorCode=dbo.gl_PrepareAccountSummary @pnUserIdentityId,
								@psCulture,
								@pnEntityNo,
								@sProfitCentreCodes,
								@pnLedgerAccountId,
								@pnFinancialYear,
								@pbBudgetMovement,
								@pbConsolidated
	End

	--Select * from #ACCOUNTSUMMARY

	-- Prepare Budget Movement/Balance
	If @nErrorCode = 0
	Begin
		CREATE TABLE #BUDGETSUMMARY
		(
			ENTITYNO 		int,
			PROFITCENTRECODE 	nvarchar(6) collate database_default,
			LEDGERACCOUNTID 	int,
			PERIODID 		int,
			BUDGETAMOUNT 		decimal(13, 2), 
			FORECASTAMOUNT 		decimal(13, 2)
		)
		Set @nErrorCode = @@ERROR
	End

	If @nErrorCode = 0
	Begin
		Exec @nErrorCode=dbo.gl_PrepareBudgetSummary @pnUserIdentityId, @psCulture, @pbConsolidated
	End
	
	--Select * from #BUDGETSUMMARY

	-- Final Result
	If @nErrorCode = 0
	Begin
		Set @sSql = '
		Select ' + dbo.fn_IncludeProfitCentreAnalysis(@sProfitCentreCodes,
								@pnAnalysisTypeId,
								@sAnalysisCodeIds,
								'SELECT',
								NULL) + '
			SKEL.ENTITYNO,
			''{'' + SKEL.PROFITCENTRECODE + ''} '' + SKEL.PROFITCENTREDESC,
			SKEL.ACCOUNTCODE,
			SKEL.ACCOUNTDESC,
			SKEL.PERIODLABEL,
			(ACCTS.PREVIOUSYEARAMOUNT * cast(AT.USERCODE as smallint)),
			(ACCTS.SELECTEDYEARAMOUNT * cast(AT.USERCODE as smallint)),
			BS.BUDGETAMOUNT,
			BS.FORECASTAMOUNT
		from
			#SKELETON SKEL
				inner join
			#ACCOUNTSUMMARY ACCTS on (ISNULL(ACCTS.ENTITYNO, 0) = ISNULL(SKEL.ENTITYNO, 0) and
						  ISNULL(ACCTS.PROFITCENTRECODE, 0) = ISNULL(SKEL.PROFITCENTRECODE, 0) and
					       	  ACCTS.LEDGERACCOUNTID = SKEL.ACCOUNTID and
					       	  ACCTS.PERIODID = SKEL.PERIODID)
				inner join
			#BUDGETSUMMARY BS on (ISNULL(BS.ENTITYNO, 0) = ISNULL(SKEL.ENTITYNO, 0) and
					      ISNULL(BS.PROFITCENTRECODE, 0) = ISNULL(SKEL.PROFITCENTRECODE, 0) and
					      BS.LEDGERACCOUNTID = SKEL.ACCOUNTID and
					      BS.PERIODID = SKEL.PERIODID) 
			Left join
				LEDGERACCOUNT LA on (LA.ACCOUNTID = SKEL.ACCOUNTID)
			Left join
				TABLECODES AT on (AT.TABLECODE = LA.ACCOUNTTYPE) ' +
			dbo.fn_IncludeProfitCentreAnalysis(@sProfitCentreCodes,
								@pnAnalysisTypeId,
								@sAnalysisCodeIds,
								'FROM',
								'SKEL.PROFITCENTRECODE') + '
		order by ' + dbo.fn_IncludeProfitCentreAnalysis(@sProfitCentreCodes,
								@pnAnalysisTypeId,
								@sAnalysisCodeIds,
								'ORDER',
								NULL) + ' SKEL.PROFITCENTRECODE, SKEL.PERIODID '
		Exec @nErrorCode=sp_executesql @sSql
	End 

	Drop table #SKELETON
	Drop table #ACCOUNTSUMMARY
	Drop table #BUDGETSUMMARY

	Return @nErrorCode
End
GO
/* 
To Test:
Exec dbo.gl_ListAccountBudgetFigures null, null, null, null, '1', 2003, 0, 1, NULL, NULL -- consolidated
Exec dbo.gl_ListAccountBudgetFigures null, null, -283575757, "'PTELE', 'TM'", '1', 2003, 1, 0, NULL, NULL
Exec dbo.gl_ListAccountBudgetFigures null, null, -283575757, "'PTCHM', 'PTELE'", 27, 2003, 1, 0, 10273, '1' -- with analysis type and code.
*/
Grant execute on dbo.gl_ListAccountBudgetFigures to public
GO

