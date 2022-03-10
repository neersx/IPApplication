-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ac_ResetAccountBalances									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ac_ResetAccountBalances]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ac_ResetAccountBalances.'
	Drop procedure [dbo].[ac_ResetAccountBalances]
End
Print '**** Creating Stored Procedure dbo.ac_ResetAccountBalances...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ac_ResetAccountBalances
(
	@prnBalance		decimal(11,2)	= NULL output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnLedger		int		= null,
	@pnEntityNo		int		= null,
	@pbDebug		bit		= 0
)
as
-- PROCEDURE:	ac_ResetAccountBalances
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Corrects Account Balances so that they are in synch with corresponding accounting tables.
--		
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 Nov 2012	CR	SQA20367 1	Created based on existing Account Audit scripts
-- 13 Jan 2013	CR	SQA20367 2	Add return balance logic
-- 19 Feb 2013	CR	RFC13191 3	Fixed problem with using ENTITYNO for BANKACCOUNT
-- 15 Apr 2013	DV	R13270	    4	Increase the length of nvarchar to 11 when casting or declaring integer
-- 30 Jul 2013	DL	RFC13494 5	Fixed Creditor Ledger to filter by CRBALANCE

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0
Set @prnBalance = NULL


/*
2 - Debtors - ACCOUNT.BALANCE will be set based on OPENITEM.LOCALBALANCE
5 - Bank - BANKACCOUNT balances will be set based on BANKHISTORY
6 - Creditors - ACCOUNT.CRBALANCE will be set based on CREDITORITEM.LOCALBALANCE
8 - Trust - TRUSTACOUNT will be set based on TRUSTITEM.LOCALBALANCE
*/

-- Update for Debtor Ledger:
if (@pnLedger=2) or (@pnLedger is null)
Begin
	If @pbDebug = 1
	Begin 	
		print 'Update ACCOUNT from OPENITEM for Debtor Ledger' 
	End
	
	Set @sSQLString = "UPDATE AC
	SET BALANCE = OI.BALANCE
	FROM ACCOUNT AC
	JOIN (SELECT ACCTENTITYNO, ACCTDEBTORNO, isnull( SUM(LOCALBALANCE), 0 ) AS BALANCE
		FROM OPENITEM 
		WHERE STATUS <> 0
		GROUP BY ACCTENTITYNO, ACCTDEBTORNO) OI	ON (OI.ACCTENTITYNO = AC.ENTITYNO
							AND OI.ACCTDEBTORNO = AC.NAMENO)
	WHERE AC.BALANCE <> OI.BALANCE"
	
	If (@pnEntityNo is not NULL)
	Begin 
		Set @sSQLString = @sSQLString + "
		AND ACCTENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
	End

	exec @nErrorCode=sp_executesql @sSQLString,
	      	N'@pnEntityNo	int',
		@pnEntityNo	= @pnEntityNo
		
	If @pbDebug = 1
	Begin 	
		print @sSQLString 
	End
End

-- Update for Bank Ledger:
if (@pnLedger=5) or (@pnLedger is null)
Begin
	If @pbDebug = 1
	Begin 
		print 'Update BANKACCOUNT from BANKHISTORY'
	End
	
	Set @sSQLString = "UPDATE BA
	SET ACCOUNTBALANCE = BH.ACCOUNTBALANCE,
	LOCALBALANCE = BH.LOCALBALANCE
	FROM BANKACCOUNT BA
	JOIN (	SELECT ENTITYNO, BANKNAMENO, SEQUENCENO, 
		SUM(BANKNET) AS ACCOUNTBALANCE, 
		SUM(LOCALNET) AS LOCALBALANCE 
		FROM BANKHISTORY 
		WHERE STATUS<> 0 
		AND MOVEMENTCLASS<> 9
		GROUP BY ENTITYNO, BANKNAMENO, SEQUENCENO) BH	ON (BA.ACCOUNTOWNER = BH.ENTITYNO
								AND BA.BANKNAMENO = BH.BANKNAMENO
								AND BA.SEQUENCENO = BH.SEQUENCENO)
	WHERE (ISNULL(BA.ACCOUNTBALANCE, 0) <> BH.ACCOUNTBALANCE) 
	OR (ISNULL(BA.LOCALBALANCE, 0) <> BH.LOCALBALANCE)"
	
	If (@pnEntityNo is not NULL)
	Begin 
		Set @sSQLString = @sSQLString + "
		AND BA.ACCOUNTOWNER = " + CAST(@pnEntityNo as NVARCHAR(11))
	End

	exec @nErrorCode=sp_executesql @sSQLString,
	      	N'@pnEntityNo	int',
		@pnEntityNo	= @pnEntityNo 
		
	If @pbDebug = 1
	Begin 	
		print @sSQLString 
	End
End

-- Update for Creditor Ledger:
if (@pnLedger=6) or (@pnLedger is null)
Begin
	If @pbDebug = 1
	Begin 
		print 'Update ACCOUNT from CREDITORITEM for Creditor Ledger'
	End

	-- RFC13494 fixed Creditor Ledger to filter by AC.CRBALANCE <> CI.BALANCE instead of AC.BALANCE <> CI.BALANCE 
	Set @sSQLString = "UPDATE AC
	SET CRBALANCE = CI.BALANCE
	FROM ACCOUNT AC
	JOIN (SELECT ACCTENTITYNO, ACCTCREDITORNO, isnull( SUM(LOCALBALANCE), 0 ) AS BALANCE
		FROM CREDITORITEM 
		WHERE STATUS <> 0
		GROUP BY ACCTENTITYNO, ACCTCREDITORNO) CI	ON (CI.ACCTENTITYNO = AC.ENTITYNO
								AND CI.ACCTCREDITORNO = AC.NAMENO)
	WHERE AC.CRBALANCE <> CI.BALANCE"
	
	If (@pnEntityNo is not NULL)
	Begin 
		Set @sSQLString = @sSQLString + "
		AND AC.ENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
	End

	exec @nErrorCode=sp_executesql @sSQLString,
	      	N'@pnEntityNo	int',
		@pnEntityNo	= @pnEntityNo
		
	If @pbDebug = 1
	Begin 	
		print @sSQLString 
	End
End

-- Update for Trust Ledger:
if (@pnLedger=8) or (@pnLedger is null)
Begin
	If @pbDebug = 1
	Begin 
		print 'Update TRUSTACCOUNT from TRUSTITEM for Trust Ledger'
	End
	
	Set @sSQLString = "UPDATE AC
	SET BALANCE = TI.BALANCE
	-- SELECT *
	FROM TRUSTACCOUNT AC
	JOIN (SELECT TACCTENTITYNO, TACCTNAMENO, isnull( SUM(LOCALBALANCE), 0 ) AS BALANCE
		FROM TRUSTITEM 
		WHERE STATUS <> 0
		GROUP BY TACCTENTITYNO, TACCTNAMENO) TI	ON (TI.TACCTENTITYNO = AC.ENTITYNO
							AND TI.TACCTNAMENO = AC.NAMENO)
	WHERE AC.BALANCE <> TI.BALANCE"
	
	If (@pnEntityNo is not NULL)
	Begin 
		Set @sSQLString = @sSQLString + "
		AND AC.ENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
	End

	If @pbDebug = 1
	Begin 	
		print @sSQLString 
	End

	exec @nErrorCode=sp_executesql @sSQLString,
	      	N'@pnEntityNo	int',
		@pnEntityNo	= @pnEntityNo
End

If (@pnLedger is NOT NULL) AND (@pnEntityNo is NOT NULL)
Begin
	If (@pnLedger = 2)
	Begin
		-- Debtors - ACCOUNT.BALANCE will be set based on OPENITEM.LOCALBALANCE
		Set @sSQLString = "SELECT @prnBalance = isnull( SUM(BALANCE), 0 )
		FROM ACCOUNT"
		
		If (@pnEntityNo is not NULL)
		Begin 
			Set @sSQLString = @sSQLString + "
			WHERE ENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
		End
		
		If @pbDebug = 1
		Begin 	
			print @sSQLString 
		End   
		
		exec @nErrorCode=sp_executesql @sSQLString,
	      		N'@prnBalance	decimal(11,2) output,
	      		@pnEntityNo	int',
			@prnBalance	= @prnBalance	OUTPUT,
			@pnEntityNo	= @pnEntityNo
			
	End
	Else If (@pnLedger = 5)
	Begin
		-- Bank - BANKACCOUNT balances will be set based on BANKHISTORY
		Set @sSQLString = "SELECT @prnBalance = isnull( SUM(LOCALBALANCE), 0)
		FROM BANKACCOUNT 
		WHERE ISOPERATIONAL > 0"
				
		If (@pnEntityNo is not NULL)
		Begin 
			Set @sSQLString = @sSQLString + "
			AND ACCOUNTOWNER = " + CAST(@pnEntityNo as NVARCHAR(11))
		End
		
		If @pbDebug = 1
		Begin 	
			print @sSQLString 
		End   
		
		exec @nErrorCode=sp_executesql @sSQLString,
	      		N'@prnBalance	decimal(11,2) output,
	      		@pnEntityNo	int',
			@prnBalance	= @prnBalance	OUTPUT,
			@pnEntityNo	= @pnEntityNo     
	End
	Else If (@pnLedger = 6)
	Begin
		-- Creditors - ACCOUNT.CRBALANCE will be set based on CREDITORITEM.LOCALBALANCE
		Set @sSQLString = "SELECT @prnBalance = isnull( SUM(CRBALANCE), 0)
		FROM ACCOUNT"
		
		If (@pnEntityNo is not NULL)
		Begin 
			Set @sSQLString = @sSQLString + "
			WHERE ENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
		End
		
		If @pbDebug = 1
		Begin 	
			print @sSQLString 
		End   
		
		exec @nErrorCode=sp_executesql @sSQLString,
	      		N'@prnBalance	decimal(11,2) output,
	      		@pnEntityNo	int',
			@prnBalance	= @prnBalance	OUTPUT,
			@pnEntityNo	= @pnEntityNo   
	End
	Else If (@pnLedger = 8)
	Begin
		-- Trust - TRUSTACOUNT will be set based on TRUSTITEM.LOCALBALANCE
		Set @sSQLString = "SELECT @prnBalance = isnull( SUM(BALANCE), 0)
		FROM TRUSTACCOUNT"
		
		If (@pnEntityNo is not NULL)
		Begin 
			Set @sSQLString = @sSQLString + "
			WHERE ENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
		End
		
		If @pbDebug = 1
		Begin 	
			print @sSQLString 
		End   
		
		exec @nErrorCode=sp_executesql @sSQLString,
	      		N'@prnBalance	decimal(11,2) output,
	      		@pnEntityNo	int',
			@prnBalance	= @prnBalance	OUTPUT,
			@pnEntityNo	= @pnEntityNo     
	End
End

Select @prnBalance as ACCOUNTBALANCE

Return @nErrorCode
GO

Grant execute on dbo.ac_ResetAccountBalances to public
GO