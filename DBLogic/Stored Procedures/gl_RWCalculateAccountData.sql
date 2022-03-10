-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_RWCalculateAccountData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[gl_RWCalculateAccountData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.gl_RWCalculateAccountData.'
	Drop procedure [dbo].[gl_RWCalculateAccountData]
End
Print '**** Creating Stored Procedure dbo.gl_RWCalculateAccountData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.gl_RWCalculateAccountData
(
	@psTempTableName 	nvarchar(128),  -- A temporary table that stores the ledger accounts and profit centres to be queried.
	@psTempRelatedTable 	nvarchar(128), 	-- A temporary table that stores the ledger accounts to be queried and their corresponding children.
	@psColumnName 		nvarchar(128),	-- A column name in @psTempTableName, which stores the sum of account movements
	@pnPeriodFrom 		int,		-- Indicates from which period the Account data will be returned.
	@pnPeriodTo 		int,		-- Indicates to which period the Account data will be returned.
	@pbExcludePLClearing	bit = 0		-- Indicates that 812 transactions should be excluded from account balances
)
as
-- PROCEDURE:	gl_RWCalculateAccountData
-- VERSION:	7
-- SCOPE:	InPro
-- DESCRIPTION:	Calculates account related data: movement, balance and etc

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19 Mar 2004	MB	8809	1	Procedure created
-- 30 Aug 2004	MB	9658	2	Added *(-1) for Income, Liability and Equity account types
-- 02 Sep 2004	JEK	RFC1377	3	Pass new Centura parameter to fn_WrapQuotes and fn_ConstructOperator
-- 23 Sep 2004	MB	9658	4	Modified select clause to pick up child accounts
-- 23-May-2005  MB	11278	5	Performance improvement
-- 22-May-2006	AT	12563	6	Added isnulls to cater for NULL LocalAmountBalances
-- 14-Nov-2007	AT	15035	7	Add P&L Clearing amounts back into balance for Previous Year columns

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSql nvarchar(4000)


-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSql = 'Update ' + @psTempTableName + ' 
		set ' + @psColumnName + ' = (
		select 
			isnull(SUM (
				(Case la.ACCOUNTTYPE
						when 8104 then (-1)
						when 8102 then (-1)
						when 8103 then (-1)
						else (1)
					end)*
				  isnull(LOCALAMOUNTBALANCE, 0)), 0) 
		from  	LEDGERJOURNALLINEBALANCE LJL,' + 
			@psTempRelatedTable + ' RA ,
			LEDGERACCOUNT la
		where
			 	la.ACCOUNTID = LJL.ACCOUNTID
			and 	LJL.ACCOUNTID= RA.CHILDID 
			and 	LJL.ACCTENTITYNO =  TMP.ENTITYNO
			and	LJL.PROFITCENTRECODE = TMP.PROFITCENTRECODE
			and	LJL.TRANPOSTPERIOD ' + dbo.fn_ConstructOperator(7 ,'N' ,cast ( @pnPeriodFrom as varchar),cast ( @pnPeriodTo as varchar) ,0) + '
			and 	RA.PARENTID = TMP.ACCOUNTID) 
		from ' + @psTempTableName + ' TMP '

	Exec @nErrorCode=sp_executesql @sSql
End

If @nErrorCode = 0
Begin
	If @pbExcludePLClearing = 1
	Begin
	     -- This logic applies to a rolled over year:
		-- LJL.LOCALAMOUNT will return the movement for the entire year.
		-- We are going to add it back to the balance/movement.
		Set @sSql = 'Update ' + @psTempTableName + ' 
			set ' + @psColumnName + ' = ' + @psColumnName + ' + (
				Select 
					isnull(SUM (
						(Case LA.ACCOUNTTYPE
						 When 8105 then (-1)
						 Else 1
						 End)*
						 (isnull(LJL.LOCALAMOUNT, 0)
						)
					), 0)
				From LEDGERACCOUNT LA
				join ' + @psTempRelatedTable + ' RA on (RA.CHILDID = LA.ACCOUNTID)
				join LEDGERJOURNALLINE LJL on (LJL.ACCOUNTID = RA.CHILDID)
				join TRANSACTIONHEADER TR on (TR.TRANSNO = LJL.TRANSNO AND TR.ENTITYNO = LJL.ENTITYNO)
				Where TR.TRANSTYPE = 812
				and TR.TRANPOSTPERIOD '

		If (cast(@pnPeriodFrom as varchar) = '' or cast(@pnPeriodFrom as varchar) is null)
		Begin
			Set @sSql = @sSql + ' = ' + cast(@pnPeriodTo as varchar)
		End
		Else
		Begin
			Set @sSql = @sSql + dbo.fn_ConstructOperator(7 ,'N' ,cast ( @pnPeriodFrom as varchar),cast ( @pnPeriodTo as varchar) ,0)
		End

		Set @sSql = @sSql + 'and LA.ACCOUNTTYPE IN (8104,8105)
				and RA.PARENTID = TMP.ACCOUNTID
				and LJL.ACCTENTITYNO =  TMP.ENTITYNO
				and LJL.PROFITCENTRECODE = TMP.PROFITCENTRECODE
			)
			from ' + @psTempTableName + ' TMP'

		Exec @nErrorCode=sp_executesql @sSql
	End
End
Return @nErrorCode
GO

Grant execute on dbo.gl_RWCalculateAccountData to public
GO
