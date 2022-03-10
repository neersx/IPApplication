-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fi_CreateInterEntityTransfer
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'dbo.fi_CreateInterEntityTransfer') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.fi_CreateInterEntityTransfer.'
	Drop procedure dbo.fi_CreateInterEntityTransfer
End
Print '**** Creating Stored Procedure dbo.fi_CreateInterEntityTransfer...'
Print ''

GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.fi_CreateInterEntityTransfer
(
	@pnUserIdentityId	int		= null,
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnItemEntityNo		int,
	@pnItemTransNo		int,
	@pnAcctEntityNo		int,
	@pnAcctDebtorNo		int,
	@pnHistoryLineNo	int,
	@pnRefEntityNo		int,
	@pnRefTransNo		int
	
)
as
-- PROCEDURE:	fi_CreateInterEntityTransfer
-- VERSION:	1	
-- SCOPE:	InPro
-- DESCRIPTION:	Called from AR and AP when a debtor invoice is posted (remitted, credit allocated, ar/ap offset or reversed) by another entity.
--		Creates an inter-entity transfer transaction and record the movement in debtorhistory and controltotal.
--
-- COPYRIGHT	Copyright 1993 - 2015 CPA GLOBAL
-- MODIFICATIONS :
-- Date		Who	RFC#	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 4/11/2015	DL	31343	1	Procedure created


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF



Declare	@nErrorCode			int,
	@nNewTransNo			int,
	@dtPostDate			datetime,
	@nPostPeriod			int,
	@nLocalValue			dec(11,2),
	@nMovementClass			int,
	@nNextHistoryLineNo		int
	



Set @nErrorCode = 0

-- Only create inter-entity transfer data if multiple entities are involved in a transaction
If (@pnItemEntityNo IS NOT NULL) AND (@pnRefEntityNo IS NOT NULL) AND (@pnItemEntityNo <> @pnRefEntityNo)
Begin
	If @nErrorCode = 0
	Begin	
		Select @nNextHistoryLineNo = Max (HISTORYLINENO) + 1               
		from DEBTORHISTORY 
		where ITEMENTITYNO = @pnItemEntityNo
		AND ITEMTRANSNO	= @pnItemTransNo
		AND ACCTENTITYNO = @pnAcctEntityNo
		AND ACCTDEBTORNO = @pnAcctDebtorNo

		Select @nErrorCode = @@Error
	End

	-- Create the Inter-Entity transfer movement to Adjust the main entity  (Adjust up for credit allocation or adjust down for reversal)
	If @nErrorCode = 0
	Begin	
		Insert into DEBTORHISTORY( ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, HISTORYLINENO, OPENITEMNO, TRANSDATE, POSTDATE, POSTPERIOD, TRANSTYPE, 
		MOVEMENTCLASS, COMMANDID, ITEMPRETAXVALUE, LOCALTAXAMT, LOCALVALUE, EXCHVARIANCE, FOREIGNTAXAMT, FOREIGNTRANVALUE, REFERENCETEXT, REASONCODE, REFENTITYNO, 
		REFTRANSNO, REFSEQNO, REFACCTENTITYNO, REFACCTDEBTORNO, LOCALBALANCE, FOREIGNBALANCE, TOTALEXCHVARIANCE, FORCEDPAYOUT, CURRENCY, EXCHRATE, STATUS, ASSOCLINENO, ITEMIMPACT, LONGREFTEXT, GLMOVEMENTNO )
		
		Select ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, @nNextHistoryLineNo  as 'HISTORYLINENO', OPENITEMNO, TRANSDATE, POSTDATE, POSTPERIOD, 600 as 'TRANSTYPE' /*INTER-ENTITY TRANSFER*/, 
		
		case when isnull(LOCALVALUE * -1, 0) < LOCALVALUE then
			5 -- ADJUST DOWN MOVEMENTCLASS
		else
			4 -- ADJUST UP MOVEMENTCLASS
		end AS 'MOVEMENTCLASS', 
				
		case when isnull(LOCALVALUE * -1,0) < LOCALVALUE then
			6 -- ADJUST DOWN COMMANDID
		else
			5 -- ADJUST UP COMMANDID
		end as 'COMMANDID',
		
		ITEMPRETAXVALUE * -1, LOCALTAXAMT * -1, LOCALVALUE * -1  AS  'LOCALVALUE', EXCHVARIANCE, FOREIGNTAXAMT * -1, FOREIGNTRANVALUE * -1 as 'FOREIGNTRANVALUE', REFERENCETEXT, '_E' as 'REASONCODE', REFENTITYNO, 
		REFTRANSNO, REFSEQNO, REFACCTENTITYNO, REFACCTDEBTORNO, 
		(LOCALBALANCE + LOCALVALUE*-1) as 'LOCALBALANCE', (FOREIGNBALANCE + FOREIGNTRANVALUE * -1), TOTALEXCHVARIANCE, FORCEDPAYOUT, CURRENCY, EXCHRATE, STATUS, HISTORYLINENO + 2 'ASSOCLINENO', ITEMIMPACT, LONGREFTEXT, GLMOVEMENTNO 
		from DEBTORHISTORY
		where ITEMENTITYNO = @pnItemEntityNo
		AND ITEMTRANSNO	= @pnItemTransNo
		AND ACCTENTITYNO = @pnAcctEntityNo
		AND ACCTDEBTORNO = @pnAcctDebtorNo
		AND HISTORYLINENO = @pnHistoryLineNo
	
		Select @nErrorCode = @@Error
	End

	-- Get the transaction details for updating CONTROLTOTALS
	If @nErrorCode = 0
	Begin
		Select @dtPostDate = POSTDATE, @nPostPeriod = POSTPERIOD, @nLocalValue = LOCALVALUE, @nMovementClass = MOVEMENTCLASS
		from DEBTORHISTORY
		where ITEMENTITYNO = @pnItemEntityNo
		AND ITEMTRANSNO	= @pnItemTransNo
		AND ACCTENTITYNO = @pnAcctEntityNo
		AND ACCTDEBTORNO = @pnAcctDebtorNo
		AND HISTORYLINENO = @nNextHistoryLineNo
		Select @nErrorCode = @@Error
	End


	-- Update CONTROLTOTAL for the debtor movement 
	If @nErrorCode = 0
	Begin
		exec @nErrorCode = dbo.acw_UpdateControlTotal
			@pnUserIdentityId = @pnUserIdentityId,
			@psCulture = @psCulture,
			@pbCalledFromCentura = @pbCalledFromCentura,
			@pnLedger	= 2,			-- Debtor Ledger
			@pnCategory	= @nMovementClass,
			@pnType		= 600,			-- Inter-Entity Transfer
			@pnPeriodId	= @nPostPeriod,
			@pnEntityNo	= @pnRefEntityNo,	-- The entity that performed the credit allocation.  (i.e. the entity of the credit item, not the entity of the invoices)
			@pnAmountToAdd	= @nLocalValue
	End


	-- Create Inter-Entity Transaction (600)
	If @nErrorCode = 0
	Begin	

		-- Get a new Transaction Key
		If @nErrorCode = 0
		Begin
			Exec @nErrorCode = dbo.ip_GetLastInternalCode
					@pnUserIdentityId	= @pnUserIdentityId,
					@psCulture		= @psCulture,
					@psTable		= N'TRANSACTIONHEADER',
					@pnLastInternalCode	= @nNewTransNo OUTPUT
		End

	
		If @nErrorCode = 0
		Begin
			Insert into TRANSACTIONHEADER( ENTITYNO, TRANSNO, TRANSDATE, TRANSTYPE, BATCHNO, EMPLOYEENO, USERID, ENTRYDATE, SOURCE, TRANSTATUS, GLSTATUS, TRANPOSTPERIOD, TRANPOSTDATE, IDENTITYID )
			Select @pnAcctEntityNo as ENTITYNO, @nNewTransNo AS 'TRANSNO', TRANSDATE, 600 AS 'TRANSTYPE', BATCHNO, EMPLOYEENO, USERID, ENTRYDATE, SOURCE, 1 as 'TRANSTATUS', 1 as 'GLSTATUS', @nPostPeriod as 'TRANPOSTPERIOD', @dtPostDate as 'TRANPOSTDATE', IDENTITYID 
			from TRANSACTIONHEADER
			where ENTITYNO = @pnRefEntityNo
			and TRANSNO = @pnRefTransNo
		
			Select @nErrorCode = @@Error
		End
	End


	-- Create the Inter-Entity transfer movement to Adjust the inter entity
	If @nErrorCode = 0
	Begin	
		Insert into DEBTORHISTORY( ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, HISTORYLINENO, OPENITEMNO, TRANSDATE, POSTDATE, POSTPERIOD, TRANSTYPE, 
		MOVEMENTCLASS, COMMANDID, ITEMPRETAXVALUE, LOCALTAXAMT, LOCALVALUE, EXCHVARIANCE, FOREIGNTAXAMT, FOREIGNTRANVALUE, REFERENCETEXT, REASONCODE, REFENTITYNO, 
		REFTRANSNO, REFSEQNO, REFACCTENTITYNO, REFACCTDEBTORNO, LOCALBALANCE, FOREIGNBALANCE, TOTALEXCHVARIANCE, FORCEDPAYOUT, CURRENCY, EXCHRATE, STATUS, ASSOCLINENO, ITEMIMPACT, LONGREFTEXT, GLMOVEMENTNO )
		
		Select ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, HISTORYLINENO + 1  as 'HISTORYLINENO', OPENITEMNO, TRANSDATE, POSTDATE, POSTPERIOD, 600 as 'TRANSTYPE' /*INTER-ENTITY TRANSFER*/, 
		
		case when isnull(LOCALVALUE * -1, 0) < LOCALVALUE then
			5 -- ADJUST DOWN MOVEMENTCLASS
		else
			4 -- ADJUST UP MOVEMENTCLASS
		end AS 'MOVEMENTCLASS', 
				
		case when isnull(LOCALVALUE * -1,0) < LOCALVALUE then
			6 -- ADJUST DOWN COMMANDID
		else
			5 -- ADJUST UP COMMANDID
		end as 'COMMANDID',
		
		ITEMPRETAXVALUE * -1, LOCALTAXAMT * -1, LOCALVALUE * -1  AS  'LOCALVALUE', EXCHVARIANCE, FOREIGNTAXAMT * -1, FOREIGNTRANVALUE * -1 as 'FOREIGNTRANVALUE', REFERENCETEXT, '_E' as 'REASONCODE', ACCTENTITYNO as 'REFENTITYNO',  
		@nNewTransNo as 'REFTRANSNO', REFSEQNO, REFACCTENTITYNO, REFACCTDEBTORNO, 
		(LOCALBALANCE + LOCALVALUE*-1) as 'LOCALBALANCE', (FOREIGNBALANCE + FOREIGNTRANVALUE * -1), TOTALEXCHVARIANCE, FORCEDPAYOUT, CURRENCY, EXCHRATE, STATUS, HISTORYLINENO 'ASSOCLINENO', ITEMIMPACT, LONGREFTEXT, GLMOVEMENTNO 
		from DEBTORHISTORY
		where ITEMENTITYNO = @pnItemEntityNo
		AND ITEMTRANSNO	= @pnItemTransNo
		AND ACCTENTITYNO = @pnAcctEntityNo
		AND ACCTDEBTORNO = @pnAcctDebtorNo
		AND HISTORYLINENO = @nNextHistoryLineNo
	
	
		Select @nErrorCode = @@Error
	End


	-- Get the transaction details for updating CONTROLTOTALS
	If @nErrorCode = 0
	Begin
		Select @dtPostDate = POSTDATE, @nPostPeriod = POSTPERIOD, @nLocalValue = LOCALVALUE, @nMovementClass = MOVEMENTCLASS
		from DEBTORHISTORY
		where ITEMENTITYNO = @pnItemEntityNo
		AND ITEMTRANSNO	= @pnItemTransNo
		AND ACCTENTITYNO = @pnAcctEntityNo
		AND ACCTDEBTORNO = @pnAcctDebtorNo
		AND HISTORYLINENO = @pnHistoryLineNo + 2
		Select @nErrorCode = @@Error
	End


	-- Update CONTROLTOTAL for the debtor movement 
	If @nErrorCode = 0
	Begin
		exec @nErrorCode = dbo.acw_UpdateControlTotal
			@pnUserIdentityId = @pnUserIdentityId,
			@psCulture = @psCulture,
			@pbCalledFromCentura = @pbCalledFromCentura,
			@pnLedger	= 2,			-- Debtor Ledger
			@pnCategory	= @nMovementClass,
			@pnType		= 600,			-- Inter-Entity Transfer
			@pnPeriodId	= @nPostPeriod,
			@pnEntityNo	= @pnAcctEntityNo,
			@pnAmountToAdd	= @nLocalValue
	End


End


If @pbCalledFromCentura = 1
	Select @nErrorCode as ERRORCODE



Return @nErrorCode
GO

Grant execute on dbo.fi_CreateInterEntityTransfer to public
GO
