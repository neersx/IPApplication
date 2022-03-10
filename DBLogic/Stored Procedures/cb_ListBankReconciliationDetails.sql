﻿----------------------------------------------------------------------------------------------------------------------------
-- Creation of cb_ListBankReconciliationDetails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cb_ListBankReconciliationDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cb_ListBankReconciliationDetails.'
	Drop procedure [dbo].[cb_ListBankReconciliationDetails]
End
Print '**** Creating Stored Procedure dbo.cb_ListBankReconciliationDetails...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.cb_ListBankReconciliationDetails
(
	@pnRowCount		int output,
	@pnUserIdentityId	int		= null,	-- Included for use by .NET
	@psCulture		nvarchar(10) 	= null, -- The language in which output is to be expressed
	@pnAccountOwner		int,			-- Mandatory
	@pnBankNameNo		int,			-- Mandatory
	@pnSequenceNo		int,			-- Mandatory
	@pdtStatementEndFrom	datetime	= null,
	@pdtStatementEndTo	datetime	= null,
	@pbIncludeUnreconciled	bit		= 0,
	@pbFilterUnreconciled	bit		= 0,
	@pbDebug		bit		= 0
)
as
-- PROCEDURE:	cb_ListBankReconciliationDetails
-- VERSION:	12
-- SCOPE:	Cash Book via Centura
-- DESCRIPTION:	Returns details of the reconciliation performed on a specific bank account.
-- COPYRIGHT:	Copyright 1993 - 2010 CPA Software Solutions Australia Pty Ltd
-- MODIFICATIONS :
-- Date		Who		Change	Version	Description
-- -----------	-------	----------------------------------------------- 
-- 22-Oct-2003  SS		8800	1	Procedure created.
-- 27-Oct-2003	SS		8800	2	Modified SQL.
-- 21 Jun 2006	AT		11425	3	Show additional fields on report.
-- 19 Jul 2006	AT		13025	4	Change Joins on BANKINGCATEGORY to Left Joins for AP Transactions
-- 10 May 2007	AT		14762	5	Fixed reversed bank charges not displaying.
-- 19 Sep 2008	CR		16876	6	Return all unreconciled rows.
-- 09 Jan 2010	CR		17530	7	Extend to cater for Fee List Bank Entry
-- 31 Dec 2010	Dw		18381	8	Added new parameter @pbFilterUnreconciled
-- 11 Sep 2014	vql		R39140	9	Pick up the correct statement end date
-- 02 Nov 2015	vql		R53910	10	Adjust formatted names logic (DR-15543).
-- 18-Apr 2018	DL		R63334	11	Incorrect Bank Reconciliation report when using the 'Exclude Unreconciled Transactions' option
-- 14 Nov 2018  AV  75198/DR-45358	12   Date conversion errors when creating cases and opening names in Chinese DB

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int			-- A variable to hold @@Error
Declare @sSQLWhere	nVarchar(4000)		-- A variable to hold the SQL Where clause
Declare @sSQLOrderBy	nVarchar(4000)		-- A variable to hold the SQL Order By clause
Declare	@sSQLString	nVarchar(4000)
Declare @bAutoCreateAndFinalise	bit
Declare @sSQLWhereFilterUnrec nvarchar(100)		-- R63334

Set @nErrorCode = 0
Set @sSQLString = null

If (@pnAccountOwner is null) OR (@pnBankNameNo is null) OR (@pnSequenceNo is null)
Begin
	Set @nErrorCode = -1
End
Else
Begin
	Set @nErrorCode = 0
End

If (@nErrorCode = 0)
Begin

	-- Get FeesList AutoCreate & Finalise site control
	Set @sSQLString = "
	Select @bAutoCreateAndFinalise = isnull(COLBOOLEAN,0)
	From SITECONTROL
	Where UPPER(CONTROLID) ='FEESLIST AUTOCREATE & FINALISE'"
	
	exec @nErrorCode = sp_executesql @sSQLString,
			N'@bAutoCreateAndFinalise	bit 			OUTPUT',
			  @bAutoCreateAndFinalise = @bAutoCreateAndFinalise	OUTPUT
End

If (@nErrorCode = 0)
Begin	
	-- If @pbIncludeUnreconciled = 1 the statement required would be far to big to run
	-- instead a temporary table will be used and the final report will be generated by 
	-- selecting what's in that.
	
	-- create temporary table
	CREATE TABLE #BANKRECREPORT (
		ACCOUNTOWNER 		int 			NOT NULL,
		BANKNAMENO 		int 			NOT NULL,
		BANKSEQUENCENO 		int 			NOT NULL,
		ENTITYNAME		nvarchar(254)		collate database_default NULL,
		BANKACCOUNT		nvarchar(80)		collate database_default NULL,
		BANKACCOUNTCURRENCY	[nvarchar] (3) 		collate database_default NULL,
		STATEMENTNO		int			NULL,
		STATEMENTENDDATE	[datetime] 		NULL,
		RECONCILEDDATE		[datetime] 		NULL,
		RECONCILEDBY		[nvarchar] (30) 	collate database_default NULL,
		OPENINGBALANCE		[decimal](13, 2)	NULL, 
		CLOSINGBALANCE		[decimal](13, 2) 	NULL,
		TRANSDATE		[datetime] 		NULL,
		POSTDATE		[datetime] 		NULL,
		TRANSACTIONDETAILS	[nvarchar] (254) 	collate database_default NULL,
		BANKAMOUNT		[decimal](13, 2) 	NULL,
		WITHDRAWALAMT		[decimal](13, 2) 	NULL,
		DEPOSITAMT		[decimal](13, 2) 	NULL,
		TOTOUTWITHDRAWALAMT	[decimal](13, 2) 	NULL,
		TOTOUTDEPOSITAMT	[decimal](13, 2) 	NULL,
		TRANSTYPEID		int			NULL,
		TRANSTYPE		[nvarchar] (50) 	collate database_default NULL,
		PAYMENTMETHOD		int			NULL,		
		PAYMENTMETHODDESC	nvarchar(30)		collate database_default NULL,
		REFERENCE		nvarchar(30)		collate database_default NULL,
		RECONCILEDONSTMT	[decimal](1, 0) 	NOT NULL,
		TRADER			nvarchar(254)		collate database_default NULL,
		REFENTITYNO		int		NULL,
		REFTRANSNO		int		NULL,
		FEETYPE			nvarchar(50)		collate database_default NULL, 
		IRN			nvarchar(30)			collate database_default NULL, 
		OWNERNAME			nvarchar(254)		collate database_default NULL, 
		OWNERNO			int		NULL, 
		OFFICALNO			nvarchar(36)			collate database_default NULL, 
		NUMBERTYPE			nvarchar(30)			collate database_default NULL)
	
	
	If @pbDebug = 1
	Begin
		print'-- create temporary table
		CREATE TABLE #BANKRECREPORT (
			ACCOUNTOWNER 		int 			NOT NULL,
			BANKNAMENO 		int 			NOT NULL,
			BANKSEQUENCENO 		int 			NOT NULL,
			ENTITYNAME		nvarchar(254)		collate database_default NULL,
			BANKACCOUNT		nvarchar(80)		collate database_default NULL,
			BANKACCOUNTCURRENCY	[nvarchar] (3) 		collate database_default NULL,
			STATEMENTNO		int			NULL,
			STATEMENTENDDATE	[datetime] 		NULL,
			RECONCILEDDATE		[datetime] 		NULL,
			RECONCILEDBY		[nvarchar] (30) 	collate database_default NULL,
			OPENINGBALANCE		[decimal](13, 2)	NULL, 
			CLOSINGBALANCE		[decimal](13, 2) 	NULL,
			TRANSDATE		[datetime] 		NULL,
			POSTDATE		[datetime] 		NULL,
			TRANSACTIONDETAILS	[nvarchar] (254) 	collate database_default NULL,
			BANKAMOUNT		[decimal](13, 2) 	NULL,
			WITHDRAWALAMT		[decimal](13, 2) 	NULL,
			DEPOSITAMT		[decimal](13, 2) 	NULL,
			TOTOUTWITHDRAWALAMT	[decimal](13, 2) 	NULL,
			TOTOUTDEPOSITAMT	[decimal](13, 2) 	NULL,
			TRANSTYPEID		int			NULL,
			TRANSTYPE		[nvarchar] (50) 	collate database_default NULL,
			PAYMENTMETHOD		int			NULL,		
			PAYMENTMETHODDESC	nvarchar(30)		collate database_default NULL,
			REFERENCE		nvarchar(30)		collate database_default NULL,
			RECONCILEDONSTMT	[decimal](1, 0) 	NOT NULL,
			TRADER			nvarchar(254)		collate database_default NULL,
			REFENTITYNO		int		NULL,
			REFTRANSNO		int		NULL,
			FEETYPE			nvarchar(50)		collate database_default NULL, 
			IRN			nvarchar(30)			collate database_default NULL, 
			OWNERNAME			nvarchar(254)		collate database_default NULL, 
			OWNERNO			int		NULL, 
			OFFICALNO			nvarchar(36)			collate database_default NULL, 
			NUMBERTYPE			nvarchar(30)			collate database_default NULL)'
		print ''
	End

	Set @nErrorCode = @@Error

	If (@nErrorCode = 0)
	Begin
		-- Set the SQL Where clause
		Set @sSQLWhere = "where BST.ACCOUNTOWNER = " + Cast(@pnAccountOwner as nVarchar) + nChar(10) +  
				 " and BST.BANKNAMENO = " + Cast(@pnBankNameNo as nVarchar) + nChar(10) +  
				 " and BST.ACCOUNTSEQUENCENO = " + Cast(@pnSequenceNo as nVarchar)
		
		If (@pdtStatementEndFrom is not null)
		Begin
			Set @sSQLWhere = @sSQLWhere + nChar(10) + 
					" and BST.STATEMENTENDDATE >= '" + Convert(nvarchar, @pdtStatementEndFrom, 112) + "'"
		End

		If (@pdtStatementEndTo is not null)
		Begin
			Set @sSQLWhere = @sSQLWhere + nChar(10) + 
					"and BST.STATEMENTENDDATE <= '" + Convert(nvarchar, @pdtStatementEndTo, 112) + "'"
		End
		
		-- Set the SQL Order By clause
		Set @sSQLOrderBy = "order by BST.STATEMENTENDDATE, BH.TRANSDATE"
		
		-- Insert reconciled bank transactions EXCLUDING bank charges
		-- as BANKHISTORY is JOINED with STATEMENTTRANS it is assumed that BH.STATUS <> 0
		Set @sSQLString = "INSERT INTO #BANKRECREPORT ([ACCOUNTOWNER], [BANKNAMENO], [BANKSEQUENCENO], " + nChar(10) +  
			" [ENTITYNAME], " + nChar(10) +  
			" [BANKACCOUNT], [BANKACCOUNTCURRENCY], [STATEMENTNO], [STATEMENTENDDATE], [RECONCILEDDATE], [RECONCILEDBY], " + nChar(10) +  
			" [OPENINGBALANCE], [CLOSINGBALANCE], [TRANSDATE], [POSTDATE], [TRANSACTIONDETAILS], " + nChar(10) +  
			" [BANKAMOUNT], [WITHDRAWALAMT], [DEPOSITAMT], " + nChar(10) +  
			" [TRANSTYPEID], [TRANSTYPE], [PAYMENTMETHOD], [PAYMENTMETHODDESC], " + nChar(10) +  
			" [REFERENCE], [RECONCILEDONSTMT], " + nChar(10) +  
			" [TRADER], [REFENTITYNO], [REFTRANSNO])" + nChar(10) +  
			" Select BST.ACCOUNTOWNER, BST.BANKNAMENO, BST.ACCOUNTSEQUENCENO, " + nChar(10) +  
			" dbo.fn_FormatNameUsingNameNo(ENTITY.NAMENO, null) + Case when ENTITY.NAMECODE is not null then ' {' + ENTITY.NAMECODE + '}' end, " + nChar(10) +  
			" BA.[DESCRIPTION], BA.CURRENCY, BST.STATEMENTNO, BST.STATEMENTENDDATE, BST.RECONCILEDDATE, BST.USERID, " + nChar(10) +  
			" BST.OPENINGBALANCE, BST.CLOSINGBALANCE, BH.TRANSDATE, BH.POSTDATE, BH.[DESCRIPTION], " + nChar(10) +  
			" BH.BANKAMOUNT, CASE WHEN BH.BANKAMOUNT < 0 THEN ABS( BH.BANKAMOUNT ) ELSE 0 END, CASE WHEN BH.BANKAMOUNT > 0 THEN ABS( BH.BANKAMOUNT ) ELSE 0 END," + nChar(10) +  
			" ATT.TRANS_TYPE_ID, ATT.[DESCRIPTION], PM.PAYMENTMETHOD, PM.PAYMENTDESCRIPTION, " + nChar(10) +  
			" isnull(BH.WITHDRAWALCHEQUENO, BH.REFERENCE), BH.ISRECONCILED," + nChar(10) +  
			" isnull(dbo.fn_FormatNameUsingNameNo(TRADER.NAMENO, null), CI.TRADER), " + nChar(10) +  
			" BH.REFENTITYNO, BH.REFTRANSNO" + nChar(10) +  
			" from BANKSTATEMENT BST " + nChar(10) +  
			" join STATEMENTTRANS TRANS	on (TRANS.STATEMENTNO = BST.STATEMENTNO)" + nChar(10) +  
			" join BANKHISTORY BH		on (BH.ENTITYNO = TRANS.ACCOUNTOWNER " + nChar(10) +  
			"				and BH.BANKNAMENO = TRANS.BANKNAMENO" + nChar(10) +  
			"				and BH.SEQUENCENO = TRANS.ACCOUNTSEQUENCENO" + nChar(10) +  
			"				and BH.HISTORYLINENO = TRANS.HISTORYLINENO" + nChar(10) +  
			"				and BH.ISRECONCILED = 1)" + nChar(10) +  
			" join BANKACCOUNT BA		on (BA.ACCOUNTOWNER = BST.ACCOUNTOWNER" + nChar(10) +  
			"				and BA.BANKNAMENO = BST.BANKNAMENO" + nChar(10) +  
			"				and BA.SEQUENCENO = BST.ACCOUNTSEQUENCENO)" + nChar(10) +  
			" join NAME ENTITY 		on (ENTITY.NAMENO = BST.ACCOUNTOWNER)" + nChar(10) +  
			" join ACCT_TRANS_TYPE ATT 	on (ATT.TRANS_TYPE_ID = BH.TRANSTYPE)" + nChar(10) +  
			" left join CASHITEM CI 	on (CI.ENTITYNO = BH.ENTITYNO" + nChar(10) +  
			"				and CI.BANKNAMENO = BH.BANKNAMENO" + nChar(10) +  
			"				and CI.SEQUENCENO = BH.SEQUENCENO" + nChar(10) +  
			"				and CI.BANKEDBYENTITYNO = BH.REFENTITYNO" + nChar(10) +  
			"				and CI.BANKEDBYTRANSNO = BH.REFTRANSNO" + nChar(10) +  
			"				and CI.TRANSENTITYNO = BH.REFENTITYNO" + nChar(10) +  
			"				and CI.TRANSNO = BH.REFTRANSNO)" + nChar(10) +  
			" left join NAME TRADER		on (TRADER.NAMENO = CI.ACCTNAMENO)" + nChar(10) +  
			" left join PAYMENTMETHODS PM 	on (PM.PAYMENTMETHOD = BH.PAYMENTMETHOD) "  
			
		Set @sSQLString = @sSQLString + nChar(10) + @sSQLWhere + nChar(10) + @sSQLOrderBy
	
		If @pbDebug = 1
		begin
			Print '-- Insert reconciled bank transactions EXCLUDING bank charges'
			Print @sSQLString
			print ''
		end
	
		exec sp_executesql @sSQLString
	
		Set @nErrorCode = @@Error
	end
	
	If (@nErrorCode = 0)
	Begin
		-- Insert reconciled bank transactions for bank charges
		Set @sSQLString = "INSERT INTO #BANKRECREPORT ([ACCOUNTOWNER], [BANKNAMENO], [BANKSEQUENCENO], " + nChar(10) +  
			" [ENTITYNAME], " + nChar(10) +  
			" [BANKACCOUNT], [BANKACCOUNTCURRENCY], [STATEMENTNO], [STATEMENTENDDATE], [RECONCILEDDATE], [RECONCILEDBY], " + nChar(10) +  
			" [OPENINGBALANCE], [CLOSINGBALANCE], [TRANSDATE], [POSTDATE], [TRANSACTIONDETAILS], " + nChar(10) +  
			" [BANKAMOUNT], [WITHDRAWALAMT], [DEPOSITAMT], " + nChar(10) +  
			" [TRANSTYPEID], [TRANSTYPE], [PAYMENTMETHOD], [PAYMENTMETHODDESC], " + nChar(10) +  
			" [REFERENCE], [RECONCILEDONSTMT], " + nChar(10) +  
			" [TRADER], [REFENTITYNO], [REFTRANSNO])" + nChar(10) +  
			" Select BST.ACCOUNTOWNER, BST.BANKNAMENO, BST.ACCOUNTSEQUENCENO, " + nChar(10) +  
			" dbo.fn_FormatNameUsingNameNo(ENTITY.NAMENO, null) + Case when ENTITY.NAMECODE is not null then ' {' + ENTITY.NAMECODE + '}' end, " + nChar(10) +  
			" BA.[DESCRIPTION], BA.CURRENCY, BST.STATEMENTNO, BST.STATEMENTENDDATE, BST.RECONCILEDDATE, BST.USERID, " + nChar(10) +  
			" BST.OPENINGBALANCE, BST.CLOSINGBALANCE, BH.TRANSDATE, BH.POSTDATE, 'Bank Charges'," + nChar(10) +  
			" (BH.BANKCHARGES * -1), BH.BANKCHARGES, 0, " + nChar(10) +  
			" ATT.TRANS_TYPE_ID, ATT.DESCRIPTION, PM.PAYMENTMETHOD, PM.PAYMENTDESCRIPTION, " + nChar(10) +  
			" isnull(BH.WITHDRAWALCHEQUENO, BH.REFERENCE), BH.ISRECONCILED," + nChar(10) +  
			" isnull(dbo.fn_FormatNameUsingNameNo(TRADER.NAMENO, null), CI.TRADER), " + nChar(10) +  
			" BH.REFENTITYNO, BH.REFTRANSNO" + nChar(10) +  
			" from BANKSTATEMENT BST" + nChar(10) +  
			" join STATEMENTTRANS TRANS	on (TRANS.STATEMENTNO = BST.STATEMENTNO)" + nChar(10) +  
			" join BANKHISTORY BH	 	on (BH.ENTITYNO = TRANS.ACCOUNTOWNER" + nChar(10) +  
			" 				and BH.BANKNAMENO = TRANS.BANKNAMENO" + nChar(10) +  
			"				and BH.SEQUENCENO = TRANS.ACCOUNTSEQUENCENO" + nChar(10) +  
			"				and BH.HISTORYLINENO = TRANS.HISTORYLINENO" + nChar(10) +  
			"				and BH.ISRECONCILED = 1" + nChar(10) +  
			"				and BH.BANKCHARGES <> 0)" + nChar(10) +  
			" join BANKACCOUNT BA 		on (BA.ACCOUNTOWNER = BST.ACCOUNTOWNER" + nChar(10) +  
			"				and BA.BANKNAMENO = BST.BANKNAMENO" + nChar(10) +  
			"				and BA.SEQUENCENO = BST.ACCOUNTSEQUENCENO)" + nChar(10) +  
			" join NAME ENTITY 		on (ENTITY.NAMENO = BST.ACCOUNTOWNER)" + nChar(10) +  
			" join ACCT_TRANS_TYPE ATT	on (ATT.TRANS_TYPE_ID = BH.TRANSTYPE)" + nChar(10) +  
			" left join CASHITEM CI 	on (CI.ENTITYNO = BH.ENTITYNO" + nChar(10) +  
			"				and CI.BANKNAMENO = BH.BANKNAMENO" + nChar(10) +  
			"				and CI.SEQUENCENO = BH.SEQUENCENO" + nChar(10) +  
			"				and CI.BANKEDBYENTITYNO = BH.REFENTITYNO" + nChar(10) +  
			"				and CI.BANKEDBYTRANSNO = BH.REFTRANSNO" + nChar(10) +  
			"				and CI.TRANSENTITYNO = BH.REFENTITYNO" + nChar(10) +  
			"				and CI.TRANSNO = BH.REFTRANSNO)" + nChar(10) +  
			" left join NAME TRADER		on (TRADER.NAMENO = CI.ACCTNAMENO)" + nChar(10) +  
			" left join PAYMENTMETHODS PM 	on (PM.PAYMENTMETHOD = BH.PAYMENTMETHOD)" 
			
		Set @sSQLString = @sSQLString + nChar(10) + @sSQLWhere + nChar(10) + @sSQLOrderBy
	
		If @pbDebug = 1
		Begin
			Print '--Insert reconciled bank transactions for bank charges'
			Print @sSQLString
			Print ''
		End
	
		exec sp_executesql @sSQLString
	
		Set @nErrorCode = @@Error
	end
	
	If (@nErrorCode = 0)
	Begin

		-- Set the SQL Where clause used for unreconciled transactions
		-- RFC63334  'Exclude Unreconciled Transactions' option applies to unreconciled transactions only.
		If (@pdtStatementEndTo is not null) and (@pbFilterUnreconciled = 1)
		Begin
			Set @sSQLWhereFilterUnrec = nChar(10) + " and (BH.TRANSDATE <= BST.STATEMENTENDDATE) "
		End

		-- Set @sSQLWhere = "where BH.ENTITYNO = " + Cast(@pnAccountOwner as nVarchar) + nChar(10) +  
		-- " and BH.BANKNAMENO = " + Cast(@pnBankNameNo as nVarchar) + nChar(10) +  
		-- " and BH.SEQUENCENO = " + Cast(@pnSequenceNo as nVarchar) + nChar(10) +  
		--" and BH.STATUS <> 0"
		
		-- Set the SQL Order By clause
		-- Set @sSQLOrderBy = "order by BH.TRANSDATE, BH.HISTORYLINENO, BH.TRANSTYPE"
		-- Insert unreconciled bank transactions so that the outstanding totals may be calculated from these rows.
		-- Insert unreconciled bank transactions EXCLUDING bank charges
		Set @sSQLString = "INSERT INTO #BANKRECREPORT ([ACCOUNTOWNER], [BANKNAMENO], [BANKSEQUENCENO], " + nChar(10) +  
			" [ENTITYNAME], " + nChar(10) +  
			" [BANKACCOUNT], [BANKACCOUNTCURRENCY], [STATEMENTNO], [STATEMENTENDDATE], [RECONCILEDDATE], [RECONCILEDBY], " + nChar(10) +  
			" [OPENINGBALANCE], [CLOSINGBALANCE], [TRANSDATE], [POSTDATE], [TRANSACTIONDETAILS], " + nChar(10) +  
			" [BANKAMOUNT], [WITHDRAWALAMT], [DEPOSITAMT], " + nChar(10) +  
			" [TRANSTYPEID], [TRANSTYPE], [PAYMENTMETHOD], [PAYMENTMETHODDESC], " + nChar(10) +  
			" [REFERENCE], [RECONCILEDONSTMT], " + nChar(10) +  
			" [TRADER], [REFENTITYNO], [REFTRANSNO])" + nChar(10) +  
			" Select BST.ACCOUNTOWNER, BST.BANKNAMENO, BST.ACCOUNTSEQUENCENO, " + nChar(10) +  
			" dbo.fn_FormatNameUsingNameNo(ENTITY.NAMENO, null) + Case when ENTITY.NAMECODE is not null then ' {' + ENTITY.NAMECODE + '}' end, " + nChar(10) +  
			" BA.[DESCRIPTION], BA.CURRENCY, BST.STATEMENTNO, BST.STATEMENTENDDATE, BST.RECONCILEDDATE, BST.USERID, " + nChar(10) +  
			" BST.OPENINGBALANCE, BST.CLOSINGBALANCE, BH.TRANSDATE, BH.POSTDATE, BH.[DESCRIPTION], " + nChar(10) +  
			" BH.BANKAMOUNT, CASE WHEN BH.BANKAMOUNT < 0 THEN ABS( BH.BANKAMOUNT ) ELSE 0 END, " + nChar(10) +  
			" CASE WHEN BH.BANKAMOUNT > 0 THEN ABS( BH.BANKAMOUNT ) ELSE 0 END," + nChar(10) +  
			" ATT.TRANS_TYPE_ID, ATT.[DESCRIPTION], PM.PAYMENTMETHOD, PM.PAYMENTDESCRIPTION, " + nChar(10) +  
			" isnull(BH.WITHDRAWALCHEQUENO, BH.REFERENCE), ISNULL(BH.ISRECONCILED, 0)," + nChar(10) +  
			" isnull(dbo.fn_FormatNameUsingNameNo(TRADER.NAMENO, null), CI.TRADER), " + nChar(10) +  
			" BH.REFENTITYNO, BH.REFTRANSNO" + nChar(10) +  
			" from BANKSTATEMENT BST" + nChar(10) +  
			" join NAME ENTITY 		on (ENTITY.NAMENO = BST.ACCOUNTOWNER)" + nChar(10) +  
			" join BANKACCOUNT BA 		on (BA.ACCOUNTOWNER = BST.ACCOUNTOWNER" + nChar(10) +  
			" 				and BA.BANKNAMENO = BST.BANKNAMENO" + nChar(10) +  
			" 				and BA.SEQUENCENO = BST.ACCOUNTSEQUENCENO)" + nChar(10) +
			" left join BANKHISTORY BH	on (BH.ENTITYNO = BST.ACCOUNTOWNER" + nChar(10) +  
			" 				and BH.BANKNAMENO = BST.BANKNAMENO" + nChar(10) +  
			" 				and BH.SEQUENCENO = BST.ACCOUNTSEQUENCENO)" + nChar(10) +    
			" join ACCT_TRANS_TYPE ATT	on (ATT.TRANS_TYPE_ID = BH.TRANSTYPE)" + nChar(10) +  
			" left join CASHITEM CI 	on (CI.ENTITYNO = BH.ENTITYNO" + nChar(10) +  
			" 				and CI.BANKNAMENO = BH.BANKNAMENO" + nChar(10) +  
			" 				and CI.SEQUENCENO = BH.SEQUENCENO" + nChar(10) +  
			" 				and CI.BANKEDBYENTITYNO = BH.REFENTITYNO" + nChar(10) +  
			" 				and CI.BANKEDBYTRANSNO = BH.REFTRANSNO" + nChar(10) +  
			" 				and CI.TRANSENTITYNO = BH.REFENTITYNO" + nChar(10) +  
			" 				and CI.TRANSNO = BH.REFTRANSNO)" + nChar(10) +  
			" left join NAME TRADER		on (TRADER.NAMENO = CI.ACCTNAMENO)" + nChar(10) +  
			" left join PAYMENTMETHODS PM 	on (PM.PAYMENTMETHOD = BH.PAYMENTMETHOD)" + nChar(10) +  
			@sSQLWhere + @sSQLWhereFilterUnrec + nChar(10) +  
			" and ((BH.ISRECONCILED = 0) or (BH.ISRECONCILED IS NULL))" + nChar(10) +  
			" and BH.POSTDATE <= BST.RECONCILEDDATE" 
			
			Set @sSQLString = @sSQLString + nChar(10) + @sSQLOrderBy
				
		If @pbDebug = 1
		Begin
			Print '--Insert unreconciled bank transactions EXCLUDING bank charges'
			Print @sSQLString
			Print ''
		End
		
		exec sp_executesql @sSQLString
		
		Set @nErrorCode = @@Error
		
		If @nErrorCode = 0
		Begin
			-- Insert unreconciled bank transactions for bank charges
			Set @sSQLString = "INSERT INTO #BANKRECREPORT ([ACCOUNTOWNER], [BANKNAMENO], [BANKSEQUENCENO], " + nChar(10) +  
				" [ENTITYNAME], " + nChar(10) +  
				" [BANKACCOUNT], [BANKACCOUNTCURRENCY], [STATEMENTNO], [STATEMENTENDDATE], [RECONCILEDDATE], [RECONCILEDBY], " + nChar(10) +  
				" [OPENINGBALANCE], [CLOSINGBALANCE], [TRANSDATE], [POSTDATE], [TRANSACTIONDETAILS], " + nChar(10) +  
				" [BANKAMOUNT], [WITHDRAWALAMT], [DEPOSITAMT], " + nChar(10) +  
				" [TRANSTYPEID], [TRANSTYPE], [PAYMENTMETHOD], [PAYMENTMETHODDESC], " + nChar(10) +  
				" [REFERENCE], [RECONCILEDONSTMT], " + nChar(10) +  
				" [TRADER], [REFENTITYNO], [REFTRANSNO])" + nChar(10) + 
				" Select BST.ACCOUNTOWNER, BST.BANKNAMENO, BST.ACCOUNTSEQUENCENO, " + nChar(10) +  
				" dbo.fn_FormatNameUsingNameNo(ENTITY.NAMENO, null) + Case when ENTITY.NAMECODE is not null then ' {' + ENTITY.NAMECODE + '}' end, " + nChar(10) +  
				" BA.[DESCRIPTION], BA.CURRENCY, BST.STATEMENTNO, BST.STATEMENTENDDATE, BST.RECONCILEDDATE, BST.USERID, " + nChar(10) +    
				" BST.OPENINGBALANCE, BST.CLOSINGBALANCE, BH.TRANSDATE, BH.POSTDATE, 'Bank Charges'," + nChar(10) +  
				" (BH.BANKCHARGES * -1), BH.BANKCHARGES, 0, " + nChar(10) +  
				" ATT.TRANS_TYPE_ID, ATT.DESCRIPTION, PM.PAYMENTMETHOD, PM.PAYMENTDESCRIPTION, " + nChar(10) +  
				" isnull(BH.WITHDRAWALCHEQUENO, BH.REFERENCE), ISNULL(BH.ISRECONCILED, 0)," + nChar(10) +  
				" isnull(dbo.fn_FormatNameUsingNameNo(TRADER.NAMENO, null), CI.TRADER), " + nChar(10) +  
				" BH.REFENTITYNO, BH.REFTRANSNO" + nChar(10) +  
				" from BANKSTATEMENT BST" + nChar(10) +
				" join NAME ENTITY 		on (ENTITY.NAMENO = BST.ACCOUNTOWNER)" + nChar(10) +  
				" join BANKACCOUNT BA 		on (BA.ACCOUNTOWNER = BST.ACCOUNTOWNER" + nChar(10) +  
				" 				and BA.BANKNAMENO = BST.BANKNAMENO" + nChar(10) +  
				" 				and BA.SEQUENCENO = BST.ACCOUNTSEQUENCENO)" + nChar(10) +    
				" left join BANKHISTORY BH	on (BH.ENTITYNO = BST.ACCOUNTOWNER" + nChar(10) +  
				" 				and BH.BANKNAMENO = BST.BANKNAMENO" + nChar(10) +  
				" 				and BH.SEQUENCENO = BST.ACCOUNTSEQUENCENO)" + nChar(10) +  
				" join ACCT_TRANS_TYPE ATT	on (ATT.TRANS_TYPE_ID = BH.TRANSTYPE)" + nChar(10) +  
				" left join CASHITEM CI 	on (CI.ENTITYNO = BH.ENTITYNO" + nChar(10) +  
				" 				and CI.BANKNAMENO = BH.BANKNAMENO" + nChar(10) +  
				" 				and CI.SEQUENCENO = BH.SEQUENCENO" + nChar(10) +  
				" 				and CI.BANKEDBYENTITYNO = BH.REFENTITYNO" + nChar(10) +  
				" 				and CI.BANKEDBYTRANSNO = BH.REFTRANSNO" + nChar(10) +  
				" 				and CI.TRANSENTITYNO = BH.REFENTITYNO" + nChar(10) +  
				" 				and CI.TRANSNO = BH.REFTRANSNO)" + nChar(10) +  
				" left join NAME TRADER		on (TRADER.NAMENO = CI.ACCTNAMENO)" + nChar(10) +  
				" left join PAYMENTMETHODS PM 	on (PM.PAYMENTMETHOD = BH.PAYMENTMETHOD)" + nChar(10) + 
				@sSQLWhere + @sSQLWhereFilterUnrec + nChar(10) +  
				" and ((BH.ISRECONCILED = 0) or (BH.ISRECONCILED IS NULL))" + nChar(10) +  
				" and BH.POSTDATE <= BST.RECONCILEDDATE " + nChar(10) +    
				" and BH.BANKCHARGES <> 0"
				
			Set @sSQLString = @sSQLString + nChar(10) + @sSQLOrderBy
			
			If @pbDebug = 1
			Begin
				Print '--Insert unreconciled bank transactions for bank charges'
				Print @sSQLString
				Print ''
			End
		
			exec sp_executesql @sSQLString
		
			Set @nErrorCode = @@Error
		End
		
		If @nErrorCode = 0
		Begin
			-- Insert bank transactions reconciled on a subsequent statement EXCLUDING bank charges
			Set @sSQLString = "INSERT INTO #BANKRECREPORT ([ACCOUNTOWNER], [BANKNAMENO], [BANKSEQUENCENO], " + nChar(10) +  
			" [ENTITYNAME], " + nChar(10) +  
			" [BANKACCOUNT], [BANKACCOUNTCURRENCY], [STATEMENTNO], [STATEMENTENDDATE], [RECONCILEDDATE], [RECONCILEDBY], " + nChar(10) +  
			" [OPENINGBALANCE], [CLOSINGBALANCE], [TRANSDATE], [POSTDATE], [TRANSACTIONDETAILS], " + nChar(10) +  
			" [BANKAMOUNT], [WITHDRAWALAMT], [DEPOSITAMT], " + nChar(10) +  
			" [TRANSTYPEID], [TRANSTYPE], [PAYMENTMETHOD], [PAYMENTMETHODDESC], " + nChar(10) +  
			" [REFERENCE], [RECONCILEDONSTMT], " + nChar(10) +  
			" [TRADER], [REFENTITYNO], [REFTRANSNO])" + nChar(10) +  
			" Select BST.ACCOUNTOWNER, BST.BANKNAMENO, BST.ACCOUNTSEQUENCENO, " + nChar(10) +  
			" dbo.fn_FormatNameUsingNameNo(ENTITY.NAMENO, null) + Case when ENTITY.NAMECODE is not null then ' {' + ENTITY.NAMECODE + '}' end, " + nChar(10) +  
			" BA.[DESCRIPTION], BA.CURRENCY, BST.STATEMENTNO, BST.STATEMENTENDDATE, BST.RECONCILEDDATE, BST.USERID, " + nChar(10) +  
			" BST.OPENINGBALANCE, BST.CLOSINGBALANCE, BH.TRANSDATE, BH.POSTDATE, BH.[DESCRIPTION], " + nChar(10) +  
			" BH.BANKAMOUNT, CASE WHEN BH.BANKAMOUNT < 0 THEN ABS( BH.BANKAMOUNT ) ELSE 0 END, " + nChar(10) +  
			" CASE WHEN BH.BANKAMOUNT > 0 THEN ABS( BH.BANKAMOUNT ) ELSE 0 END, " + nChar(10) +  
			" ATT.TRANS_TYPE_ID, ATT.[DESCRIPTION], PM.PAYMENTMETHOD, PM.PAYMENTDESCRIPTION, " + nChar(10) +  
			" isnull(BH.WITHDRAWALCHEQUENO, BH.REFERENCE), 0," + nChar(10) +  
			" isnull(dbo.fn_FormatNameUsingNameNo(TRADER.NAMENO, null), CI.TRADER), " + nChar(10) +  
			" BH.REFENTITYNO, BH.REFTRANSNO" + nChar(10) +  
			" from BANKSTATEMENT BST" + nChar(10) +  
			" join NAME ENTITY 			on (ENTITY.NAMENO = BST.ACCOUNTOWNER)" + nChar(10) +  
			" join BANKACCOUNT BA 			on (BA.ACCOUNTOWNER = BST.ACCOUNTOWNER" + nChar(10) +  
			" 					and BA.BANKNAMENO = BST.BANKNAMENO" + nChar(10) +  
			" 					and BA.SEQUENCENO = BST.ACCOUNTSEQUENCENO)" + nChar(10) +  
			" left join STATEMENTTRANS TRANS	on (TRANS.ACCOUNTOWNER = BST.ACCOUNTOWNER" + nChar(10) +  
			"					and TRANS.BANKNAMENO = BST.BANKNAMENO" + nChar(10) +  
			"					and TRANS.ACCOUNTSEQUENCENO = BST.ACCOUNTSEQUENCENO)" + nChar(10) +  
			" left join BANKHISTORY BH 		on (BH.ENTITYNO = TRANS.ACCOUNTOWNER" + nChar(10) +  
			"					and BH.BANKNAMENO = TRANS.BANKNAMENO" + nChar(10) +  
			"					and BH.SEQUENCENO = TRANS.ACCOUNTSEQUENCENO" + nChar(10) +  
			"					and BH.HISTORYLINENO = TRANS.HISTORYLINENO" + nChar(10) +  
			"					and BH.ISRECONCILED = 1)" + nChar(10) +  
			" join ACCT_TRANS_TYPE ATT		on (ATT.TRANS_TYPE_ID = BH.TRANSTYPE)" + nChar(10) +  
			" left join CASHITEM CI 		on (CI.ENTITYNO = BH.ENTITYNO" + nChar(10) +  
			" 					and CI.BANKNAMENO = BH.BANKNAMENO" + nChar(10) +  
			" 					and CI.SEQUENCENO = BH.SEQUENCENO" + nChar(10) +  
			" 					and CI.BANKEDBYENTITYNO = BH.REFENTITYNO" + nChar(10) +  
			" 					and CI.BANKEDBYTRANSNO = BH.REFTRANSNO" + nChar(10) +  
			" 					and CI.TRANSENTITYNO = BH.REFENTITYNO" + nChar(10) +  
			" 					and CI.TRANSNO = BH.REFTRANSNO)" + nChar(10) +  
			" left join NAME TRADER			on (TRADER.NAMENO = CI.ACCTNAMENO)" + nChar(10) +  
			" left join PAYMENTMETHODS PM 		on (PM.PAYMENTMETHOD = BH.PAYMENTMETHOD)" + nChar(10) +  
			@sSQLWhere + nChar(10) +  
			" and TRANS.STATEMENTNO > BST.STATEMENTNO " + nChar(10) +  
			" and BH.POSTDATE <= BST.RECONCILEDDATE" 
			
			Set @sSQLString = @sSQLString + nChar(10) + @sSQLOrderBy
					
			If @pbDebug = 1
			Begin
				Print '--Insert bank transactions reconciled on a subsequent statement EXCLUDING bank charges'
				Print @sSQLString
				Print ''
			End
			
			exec sp_executesql @sSQLString
			
			Set @nErrorCode = @@Error
		End
		
		If @nErrorCode = 0
		Begin
			-- Insert bank transactions reconciled on a subsequent statement for bank charges
			Set @sSQLString = "INSERT INTO #BANKRECREPORT ([ACCOUNTOWNER], [BANKNAMENO], [BANKSEQUENCENO], " + nChar(10) +  
				" [ENTITYNAME], " + nChar(10) +  
				" [BANKACCOUNT], [BANKACCOUNTCURRENCY], [STATEMENTNO], [STATEMENTENDDATE], [RECONCILEDDATE], [RECONCILEDBY], " + nChar(10) +  
				" [OPENINGBALANCE], [CLOSINGBALANCE], [TRANSDATE], [POSTDATE], [TRANSACTIONDETAILS], " + nChar(10) +  
				" [BANKAMOUNT], [WITHDRAWALAMT], [DEPOSITAMT], " + nChar(10) +  
				" [TRANSTYPEID], [TRANSTYPE], [PAYMENTMETHOD], [PAYMENTMETHODDESC], " + nChar(10) +  
				" [REFERENCE], [RECONCILEDONSTMT], " + nChar(10) +  
				" [TRADER], [REFENTITYNO], [REFTRANSNO])" + nChar(10) + 
				" Select BST.ACCOUNTOWNER, BST.BANKNAMENO, BST.ACCOUNTSEQUENCENO, " + nChar(10) +  
				" dbo.fn_FormatNameUsingNameNo(ENTITY.NAMENO, null) + Case when ENTITY.NAMECODE is not null then ' {' + ENTITY.NAMECODE + '}' end, " + nChar(10) +  
				" BA.[DESCRIPTION], BA.CURRENCY, BST.STATEMENTNO, BST.STATEMENTENDDATE, BST.RECONCILEDDATE, BST.USERID, " + nChar(10) +  
				" BST.OPENINGBALANCE, BST.CLOSINGBALANCE, BH.TRANSDATE, BH.POSTDATE, 'Bank Charges', " + nChar(10) +  
				" (BH.BANKCHARGES * -1), BH.BANKCHARGES, 0, " + nChar(10) +  
				" ATT.TRANS_TYPE_ID, ATT.DESCRIPTION, PM.PAYMENTMETHOD, PM.PAYMENTDESCRIPTION, " + nChar(10) +  
				" isnull(BH.WITHDRAWALCHEQUENO, BH.REFERENCE), 0," + nChar(10) +  
				" isnull(dbo.fn_FormatNameUsingNameNo(TRADER.NAMENO, null), CI.TRADER), " + nChar(10) +  
				" BH.REFENTITYNO, BH.REFTRANSNO" + nChar(10) +  
				" from BANKSTATEMENT BST" + nChar(10) +  
				" join NAME ENTITY 			on (ENTITY.NAMENO = BST.ACCOUNTOWNER)" + nChar(10) +  
				" join BANKACCOUNT BA 			on (BA.ACCOUNTOWNER = BST.ACCOUNTOWNER" + nChar(10) +  
				" 					and BA.BANKNAMENO = BST.BANKNAMENO" + nChar(10) +  
				" 					and BA.SEQUENCENO = BST.ACCOUNTSEQUENCENO)" + nChar(10) +  
				" left join STATEMENTTRANS TRANS	on (TRANS.ACCOUNTOWNER = BST.ACCOUNTOWNER" + nChar(10) +  
				"					and TRANS.BANKNAMENO = BST.BANKNAMENO" + nChar(10) +  
				"					and TRANS.ACCOUNTSEQUENCENO = BST.ACCOUNTSEQUENCENO)" + nChar(10) +  
				" left join BANKHISTORY BH 		on (BH.ENTITYNO = TRANS.ACCOUNTOWNER" + nChar(10) +  
				"					and BH.BANKNAMENO = TRANS.BANKNAMENO" + nChar(10) +  
				"					and BH.SEQUENCENO = TRANS.ACCOUNTSEQUENCENO" + nChar(10) +  
				"					and BH.HISTORYLINENO = TRANS.HISTORYLINENO" + nChar(10) +  
				"					and BH.ISRECONCILED = 1)" + nChar(10) +  
				" join ACCT_TRANS_TYPE ATT		on (ATT.TRANS_TYPE_ID = BH.TRANSTYPE)" + nChar(10) +  
				" left join CASHITEM CI 		on (CI.ENTITYNO = BH.ENTITYNO" + nChar(10) +  
				" 					and CI.BANKNAMENO = BH.BANKNAMENO" + nChar(10) +  
				" 					and CI.SEQUENCENO = BH.SEQUENCENO" + nChar(10) +  
				" 					and CI.BANKEDBYENTITYNO = BH.REFENTITYNO" + nChar(10) +  
				" 					and CI.BANKEDBYTRANSNO = BH.REFTRANSNO" + nChar(10) +  
				" 					and CI.TRANSENTITYNO = BH.REFENTITYNO" + nChar(10) +  
				" 					and CI.TRANSNO = BH.REFTRANSNO)" + nChar(10) +  
				" left join NAME TRADER			on (TRADER.NAMENO = CI.ACCTNAMENO)" + nChar(10) +  
				" left join PAYMENTMETHODS PM 		on (PM.PAYMENTMETHOD = BH.PAYMENTMETHOD)" + nChar(10) +  
				@sSQLWhere + nChar(10) +  
				" and TRANS.STATEMENTNO > BST.STATEMENTNO " + nChar(10) +  
				" and BH.POSTDATE <= BST.RECONCILEDDATE" + nChar(10) +  
				" and BH.BANKCHARGES <> 0"
				
			Set @sSQLString = @sSQLString + nChar(10) + @sSQLOrderBy
			
			If @pbDebug = 1
			Begin
				Print '-- Insert bank transactions reconciled on a subsequent statement for bank charges'
				Print @sSQLString
				Print ''
			End
		
			exec sp_executesql @sSQLString
		
			Set @nErrorCode = @@Error
		End
	End
		
	If @nErrorCode = 0
	Begin 
		-- Include total outstanding withdrawals and deposits for ALL unreconciled bank transactions 
		-- in the same way as the OPENING and CLOSINGBALANCEs i.e. set on each row returned.
		Set @sSQLString = "UPDATE #BANKRECREPORT" + nChar(10) +  
		"SET [TOTOUTWITHDRAWALAMT] = TOT.OUTSTANDINGWITHDRAWAL," + nChar(10) +  
		"[TOTOUTDEPOSITAMT] = TOT.OUTSTANDINGDEPOSIT" + nChar(10) +  
		"FROM #BANKRECREPORT BR" + nChar(10) +  
--		"JOIN (SELECT SUM(CASE WHEN BH.BANKNET < 0 THEN ABS( BH.BANKNET ) ELSE 0 END) AS OUTSTANDINGWITHDRAWAL, " + nChar(10) +  
--		"	SUM(CASE WHEN BH.BANKNET > 0 THEN ABS( BH.BANKNET ) ELSE 0 END) AS OUTSTANDINGDEPOSIT, " + nChar(10) +  
		"JOIN (SELECT SUM(ISNULL(WITHDRAWALAMT,0)) AS OUTSTANDINGWITHDRAWAL, " + nChar(10) +  
		"	SUM(ISNULL(DEPOSITAMT,0)) AS OUTSTANDINGDEPOSIT, " + nChar(10) +  
		"	BH.ACCOUNTOWNER, BH.BANKNAMENO, BH.BANKSEQUENCENO, BH.STATEMENTNO " + nChar(10) +  
		"	from #BANKRECREPORT BH" + nChar(10) + 
		"	where RECONCILEDONSTMT = 0"  + nChar(10) + 
		"	Group By BH.ACCOUNTOWNER, BH.BANKNAMENO, BH.BANKSEQUENCENO, BH.STATEMENTNO ) AS TOT 	on (BR.ACCOUNTOWNER = TOT.ACCOUNTOWNER" + nChar(10) +  
		"												and BR.BANKNAMENO = TOT.BANKNAMENO" + nChar(10) +  
		"												and BR.BANKSEQUENCENO = TOT.BANKSEQUENCENO" + nChar(10) +  
		"												and BR.STATEMENTNO = TOT.STATEMENTNO)"
		
		If @pbDebug = 1
		Begin
			Print '-- set total outstanding withdrawals and deposits for ALL unreconciled bank transactions'
			Print @sSQLString
			Print ''
		End
		
		exec sp_executesql @sSQLString
		
		Set @nErrorCode = @@Error
	End

	If @nErrorCode = 0 AND @bAutoCreateAndFinalise = 1
	Begin 
		-- Update to include fee list details if required
		Set @sSQLString = "UPDATE #BANKRECREPORT" + nChar(10) +  
		"SET [FEETYPE] = FT.FEENAME," + nChar(10) +  
		"[IRN] = C.IRN," + nChar(10) +  
		"[OWNERNAME] = dbo.fn_FormatNameUsingNameNo(O.NAMENO, null) + Case when O.NAMECODE is not null then ' {' + O.NAMECODE + '}' end, " + nChar(10) +  
		"[OWNERNO] = O.NAMENO, " + nChar(10) +  
		"[OFFICALNO] = FLC.OFFICIALNUMBER," + nChar(10) +  
		"[NUMBERTYPE] = NT.DESCRIPTION" + nChar(10) +
		"FROM #BANKRECREPORT BR" + nChar(10) +  
		"LEFT JOIN (Select FLC1.REFENTITYNO, FLC1.REFTRANSNO, FLC1.CASEID, FLC1.FEETYPE, " + nChar(10) +  
		" 			FLC1.NUMBERTYPE, FLC1.OFFICIALNUMBER, COUNT(*) as FEELISTENTRYROWS" + nChar(10) +  
		" 		   from FEELISTCASE FLC1" + nChar(10) +  
		" 		   group by FLC1.REFENTITYNO, FLC1.REFTRANSNO, FLC1.CASEID, FLC1.FEETYPE," + nChar(10) +  
		" 			FLC1.NUMBERTYPE, FLC1.OFFICIALNUMBER) FLC	ON (FLC.REFENTITYNO = BR.REFENTITYNO" + nChar(10) +  
		" 														AND FLC.REFTRANSNO = BR.REFTRANSNO" + nChar(10) +  
		" 														AND FLC.FEELISTENTRYROWS = 1)" + nChar(10) +  
		"LEFT JOIN CASES C			ON (C.CASEID = FLC.CASEID)" + nChar(10) +  
		"LEFT JOIN FEETYPES FT		ON (FT.FEETYPE = FLC.FEETYPE)" + nChar(10) +  
		"LEFT JOIN NUMBERTYPES NT	ON (NT.NUMBERTYPE = FLC.NUMBERTYPE)" + nChar(10) +  
		"LEFT JOIN CASENAME CN		on (CN.CASEID = C.CASEID" + nChar(10) +  
		" 							and CN.EXPIRYDATE is null" + nChar(10) +  
		" 							and CN.NAMETYPE = 'O'" + nChar(10) +  
		" 							and CN.SEQUENCE = (	SELECT MIN(O2.SEQUENCE)" + nChar(10) +  
		" 												FROM CASENAME O2" + nChar(10) +  
		" 												WHERE O2.CASEID = C.CASEID" + nChar(10) +  
		" 												AND O2.NAMETYPE = 'O'" + nChar(10) +  
		" 												AND O2.EXPIRYDATE is null))" + nChar(10) +  
		"LEFT JOIN NAME O 				on (O.NAMENO = CN.NAMENO) "	
		
		If @pbDebug = 1
		Begin
			Print '-- set total outstanding withdrawals and deposits for ALL unreconciled bank transactions'
			Print @sSQLString
			Print ''
		End
		
		exec sp_executesql @sSQLString
		
		Set @nErrorCode = @@Error
	End
	
	If (@nErrorCode = 0)
	Begin
		-- select result set [BANKAMOUNT], 
		Set @sSQLString = "select [BANKACCOUNT], [BANKACCOUNTCURRENCY], [STATEMENTENDDATE], [RECONCILEDDATE], [RECONCILEDBY], " + nChar(10) +  
				" [OPENINGBALANCE], [CLOSINGBALANCE], [TRANSDATE], [TRANSACTIONDETAILS], " + nChar(10) +  
				" [WITHDRAWALAMT], [DEPOSITAMT], [TOTOUTWITHDRAWALAMT], [TOTOUTDEPOSITAMT], " + nChar(10) +  
				" [TRANSTYPE], [PAYMENTMETHODDESC], [REFERENCE], [RECONCILEDONSTMT], [ENTITYNAME], [TRADER]"

		If @bAutoCreateAndFinalise = 1
		Begin
			Set @sSQLString = @sSQLString + ", [FEETYPE], [IRN], [OWNERNAME], [OWNERNO], [OFFICALNO], [NUMBERTYPE]"	
		End
		Set @sSQLString = @sSQLString + nChar(10) +  
		"from #BANKRECREPORT" 

		If ( @pbIncludeUnreconciled = 0 )
		Begin
			Set @sSQLString = @sSQLString + nChar(10) +  
			" where RECONCILEDONSTMT <> 0"
		End 

		Set @sSQLString = @sSQLString + nChar(10) +  " order by STATEMENTENDDATE, RECONCILEDONSTMT desc, TRANSDATE, TRANSTYPEID "

		If @pbDebug = 1
		Begin
			Print '-- select result set'
			Print @sSQLString
			Print ''
			SELECT * 
			FROM #BANKRECREPORT
			order by STATEMENTNO, STATEMENTENDDATE, RECONCILEDONSTMT desc, TRANSDATE, TRANSTYPEID 
			Print ''
		End
		
		exec sp_executesql @sSQLString
			
		drop table #BANKRECREPORT
		
		Set @pnRowCount = @@RowCount
	End
End

Return @nErrorCode
GO

Grant execute on dbo.cb_ListBankReconciliationDetails to public
GO
