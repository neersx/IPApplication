-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_PrepareBudgetSummary
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[gl_PrepareBudgetSummary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.gl_PrepareBudgetSummary.'
	Drop procedure [dbo].[gl_PrepareBudgetSummary]
End
Print '**** Creating Stored Procedure dbo.gl_PrepareBudgetSummary...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.gl_PrepareBudgetSummary
(
	@pnUserIdentityId	int		= null,		
	@psCulture		nvarchar(10) 	= null,
	@pbConsolidated		bit		        -- Mandatory
)
as
-- PROCEDURE:	gl_PrepareBudgetSummary
-- VERSION:	2
-- SCOPE:	InProma
-- DESCRIPTION:	Prepare budget summary. Must have #BUDGETSUMMARY table created
--		before calling this sp. See gl_ListAccountBalanceFilter for details.
--
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 19-FEB-2004  SFoo	8851	1	Procedure created
-- 26-SEP-2007	CR		14722	2	Modified logic to prevent Null value is eliminated by an 
--										aggregate Warnings
Begin
	SET NOCOUNT ON
	SET CONCAT_NULL_YIELDS_NULL OFF

	Declare @nErrorCode int,
		@sSql nvarchar(3000),
		@sRelatedAcctTable nvarchar(128)
	Set @nErrorCode = 0

	If @nErrorCode = 0
	Begin
	    exec @nErrorCode=gl_TraverseAccount '#SKELETON', @sRelatedAcctTable Output
	End

	If @nErrorCode = 0
	Begin
		-- Calcalute sum of budget movements/balances.
		-- Construct Insert statement
		Set @sSql = 'Insert into #BUDGETSUMMARY '

		-- Construct Select
		Set @sSql = @sSql + ' Select '

		-- Exclude profit centre, when consolidated, include otherwise.
		If @pbConsolidated = 0
			Set @sSql = @sSql + 'SKEL.ENTITYNO, SKEL.PROFITCENTRECODE, '
		Else
			Set @sSql = @sSql + 'NULL, NULL, '
		
		Set @sSql = @sSql + 'SKEL.ACCOUNTID, SKEL.PERIODID, SUM(ISNULL(B.BUDGETAMOUNT, 0)), SUM(ISNULL(B.FRCSTAMOUNT, 0)) '

		-- Construct From
		Set @sSql = @sSql + 'from #SKELETON SKEL
					     inner join ' +
					   @sRelatedAcctTable + ' RA on (RA.PARENTID = SKEL.ACCOUNTID)
					     left outer join
					   BUDGET B on (B.LEDGERACCOUNTID = RA.CHILDID and '

		-- Include profit centre, when not consolidated.
		If @pbConsolidated = 0
			Set @sSql = @sSql + 'B.ENTITYNO = SKEL.ENTITYNO and
					     B.PROFITCENTRECODE = SKEL.PROFITCENTRECODE and '
	        Set @sSql = @sSql + 'B.PERIODID = SKEL.PERIODID) '

		-- Construct Group by
		Set @sSql = @sSql + 'group by SKEL.ACCOUNTID, '
		If @pbConsolidated = 0
			Set @sSql = @sSql + 'SKEL.ENTITYNO, SKEL.PROFITCENTRECODE, '
		Set @sSql = @sSql + 'SKEL.PERIODID '

		--print @sSql
		Exec @nErrorCode=sp_executesql @sSql
	End
	
	Set @sSql = 'Drop table ' + @sRelatedAcctTable
	Exec sp_executesql @sSql

	Return @nErrorCode
End
GO

Grant execute on dbo.gl_PrepareBudgetSummary to public
GO
