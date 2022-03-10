-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fi_WippaymentAllocation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fi_WippaymentAllocation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.fi_WippaymentAllocation.'
	Drop procedure [dbo].[fi_WippaymentAllocation]
End
Print '**** Creating Stored Procedure dbo.fi_WippaymentAllocation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.fi_WippaymentAllocation
(
	@pnUserIdentityId	int,		
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnEntityNo		int,		
	@pnTransNo		int,
	@pbRecalcuateFlag	bit		= 0	
)
as
-- PROCEDURE:	fi_WippaymentAllocation
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Calculate the WIP allocation amount and record in WIPPAYMENT table when debtor credit or debit note is paid (i.e remittance) or offset another invoice (supplier or debtor).
--
-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	---------------	-------	-----------------------------------------------
-- 14 Jul 2015	DL	RFC48445	1	Procedure created.
-- 29 Jul 2015	DL	RFC48744	2	Handle AR/AP offset transactions
-- 12 Apr 2016	DL	RFC53420	3	Fix a bug when AR/AP from a debit note that based on multi-debtor with discount WIP.
-- 18 May 2016	DL	RFC60728	4	Incorrect GL Journal when a bill that has credit WIP items is 'paid off'
-- 05 Aug 2016	DL	RFC63741 	5	Zero amount WIPPAYMENT rows unnecessarily created for partial payments allocated to Invoices 
-- 24 Oct 2017	AK	R72645	        6	Make compatible with case sensitive server with case insensitive database.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @nEntityNo int
declare @nTransNo int
declare @nRefEntityNo int
declare @nRefTransNo int
declare @nAcctEntityNo int
declare @nAcctDebtorNo int
declare @nHistoryLineNo int
declare @sOpenItemNo nvarchar(12)
declare @sPrevOpenItemNo nvarchar(12)
declare @nWipSeqNo int
declare @sWipCode nvarchar(6)
declare @nLocalBalance decimal(11,2)
declare @nLocalValue decimal(11,2)
declare @nTotalAmountRemainder  decimal(11,2)
declare @nDiscountFlag decimal(5,1)
declare @nPaymentSeqNo int
declare @nNewLocalTransValue decimal(11,2)
declare @nNewLocalBalance decimal(11,2)
declare @sWipPaymentPreference nvarchar(30)
declare @nRowCount int
declare @nRowId int
declare @nCreditWip smallint
declare @nTransType smallint
declare @nDH_LOCALVALUE_ORIG decimal(11,2)


-- Holds the current wippayment details prior to the transaction.
CREATE TABLE #WIPITEMDETAIL(
	ROWID	int identity(1,1), 
	ENTITYNO int NULL,
	TRANSNO int NULL,
	WIPSEQNO smallint NULL,
	HISTORYLINENO smallint NULL,
	ACCTDEBTORNO int NULL,
	PAYMENTSEQNO smallint NULL,
	WIPCODE nvarchar(6) collate database_default NULL,
	WP_LOCALTRANSVALUE decimal(11, 2) NULL,
	WP_LOCALBALANCE decimal(11, 2) NULL,
	OPENITEMNO nvarchar(12) collate database_default NULL,
	InsertOrder smallint NULL,
	DH_LOCALVALUE decimal(11, 2) NULL, 
	DH_LOCALVALUE_ORIG decimal(11, 2) NULL, 	
	DISCOUNTFLAG decimal(5,1) NULL,
	CREDITWIP	smallint NULL,
	TRANSTYPE	smallint,
	NEWSEQNO	smallint NULL
) 

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Select @sWipPaymentPreference = COLCHARACTER
	from SITECONTROL 
	where CONTROLID = 'FI WIP Payment Preference'
	Select @nErrorCode = @@ERROR
End

-- Get WIP item details to be allocated - Allocate based on the default payment preference order
If @nErrorCode = 0 and @pbRecalcuateFlag = 0
Begin
	Insert into #WIPITEMDETAIL(ENTITYNO, TRANSNO, WIPSEQNO, HISTORYLINENO, ACCTDEBTORNO, PAYMENTSEQNO, WIPCODE, WP_LOCALTRANSVALUE, WP_LOCALBALANCE,
		OPENITEMNO, InsertOrder, DISCOUNTFLAG, DH_LOCALVALUE, DH_LOCALVALUE_ORIG, CREDITWIP, TRANSTYPE) 
	Select distinct WP.ENTITYNO, WP.TRANSNO, WP.WIPSEQNO, WP.HISTORYLINENO, WP.ACCTDEBTORNO, WP.PAYMENTSEQNO, WP.WIPCODE,
	WP.LOCALTRANSVALUE, WP.LOCALBALANCE, OI.OPENITEMNO, T.InsertOrder, WH.DISCOUNTFLAG, 
	-- exclude tax amount
	ABS(DH.LOCALVALUE) - (CASE WHEN  ISNULL(OI.LOCALVALUE, 0)=0 THEN 0 ELSE ABS((DH.LOCALVALUE / OI.LOCALVALUE) * ISNULL(OI.LOCALTAXAMT, 0)) END) DH_LOCALVALUE,
	DH.LOCALVALUE DH_LOCALVALUE_ORIG,

	/*Sort by credit wip in debit note and debit wip in credit note first so that they get applied before other wips.  Applied to cash accounting only.*/
	case	when WH.DISCOUNTFLAG = 0 and sign(DH.LOCALVALUE) = sign(WP.LOCALBALANCE) then 1 
		when WH.DISCOUNTFLAG = 1 then 1 
		else 2 end as CREDITWIP,		

	DH.TRANSTYPE
	from 
	-- There can be multiple DEBTORHISTORY rows for a reftransno and itemtransno that is a credit note and being applied to multiple invoices.
	-- Each payment is a row against the credit note item within the same reftransno. 
	-- We need to get the debtor total payment amount (e.g. SUM(LOCALVALUE)) of the transaction to allocate to WIP items.
	(SELECT ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, REFENTITYNO, REFTRANSNO, TRANSTYPE,
	SUM(LOCALVALUE) LOCALVALUE, SUM(LOCALTAXAMT) LOCALTAXAMT, 
	SUM(FOREIGNTRANVALUE) FOREIGNTRANVALUE, SUM(FOREIGNTAXAMT) FOREIGNTAXAMT
	FROM DEBTORHISTORY 
	WHERE REFENTITYNO = @pnEntityNo 
	AND REFTRANSNO = @pnTransNo
	GROUP BY ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, REFENTITYNO, REFTRANSNO, TRANSTYPE) DH 
						
	JOIN OPENITEM OI on (	OI.ITEMENTITYNO = DH.ITEMENTITYNO 
				and OI.ITEMTRANSNO = DH.ITEMTRANSNO 
				and OI.ACCTENTITYNO = DH.ACCTENTITYNO 
				and OI.ACCTDEBTORNO = DH.ACCTDEBTORNO)

	JOIN (	Select WP.ENTITYNO, WP.TRANSNO, WP.WIPSEQNO, WP.HISTORYLINENO, WP.ACCTDEBTORNO, WH.REFENTITYNO, WH.REFTRANSNO, ISNULL(WH.DISCOUNTFLAG, 0) DISCOUNTFLAG , MAX(WP.PAYMENTSEQNO) PAYMENTSEQNO
		FROM DEBTORHISTORY DH
		JOIN WORKHISTORY WH ON (WH.REFENTITYNO = DH.ITEMENTITYNO
					AND WH.REFTRANSNO = DH.ITEMTRANSNO)			
		JOIN WIPPAYMENT WP ON (WP.ENTITYNO = WH.ENTITYNO
					and WP.TRANSNO = WH.TRANSNO
					and WP.WIPSEQNO = WH.WIPSEQNO
					and WP.HISTORYLINENO = WH.HISTORYLINENO
					and WP.ACCTDEBTORNO = DH.ACCTDEBTORNO) 
		Where DH.REFENTITYNO = @pnEntityNo 
		AND DH.REFTRANSNO = @pnTransNo
		AND WH.MOVEMENTCLASS = 2
		GROUP BY WP.ENTITYNO, WP.TRANSNO, WP.WIPSEQNO, WP.HISTORYLINENO, WP.ACCTDEBTORNO, WH.REFENTITYNO, WH.REFTRANSNO, WH.DISCOUNTFLAG) WH
		ON (WH.REFENTITYNO = DH.ITEMENTITYNO 
		and WH.REFTRANSNO = DH.ITEMTRANSNO )
		
	/* Get the current wip balance before applying the payment */
	JOIN WIPPAYMENT WP on	(WP.ENTITYNO = WH.ENTITYNO
				and WP.TRANSNO = WH.TRANSNO
				and WP.WIPSEQNO = WH.WIPSEQNO
				and WP.HISTORYLINENO = WH.HISTORYLINENO
				and WP.ACCTDEBTORNO = WH.ACCTDEBTORNO
				and WP.PAYMENTSEQNO = WH.PAYMENTSEQNO)	
				
	JOIN WIPTEMPLATE WT on WT.WIPCODE = WP.WIPCODE
	JOIN WIPTYPE WTT on WTT.WIPTYPEID = WT.WIPTYPEID
	JOIN dbo.fn_Tokenise(@sWipPaymentPreference, ',') T  on (T.parameter = WTT.CATEGORYCODE)
	Where DH.REFENTITYNO = @pnEntityNo 
	AND DH.REFTRANSNO = @pnTransNo
	-- Order by credit item then default payment category preferences.
	order by  OI.OPENITEMNO, CREDITWIP, T.InsertOrder, WP.TRANSNO, WP.WIPCODE, WP.WIPSEQNO desc

	Select @nRowCount = @@ROWCOUNT, @nErrorCode = @@ERROR
End
-- Get WIP item details to be allocated - Allocate based on the user override wip order 
Else If @nErrorCode = 0 and @pbRecalcuateFlag = 1
Begin
	Insert into #WIPITEMDETAIL(ENTITYNO, TRANSNO, WIPSEQNO, HISTORYLINENO, ACCTDEBTORNO, PAYMENTSEQNO, WIPCODE, WP_LOCALTRANSVALUE, WP_LOCALBALANCE,
		OPENITEMNO, InsertOrder, DISCOUNTFLAG, DH_LOCALVALUE, DH_LOCALVALUE_ORIG, CREDITWIP, TRANSTYPE, NEWSEQNO) 
	Select distinct WP.ENTITYNO, WP.TRANSNO, WP.WIPSEQNO, WP.HISTORYLINENO, WP.ACCTDEBTORNO, WP.PAYMENTSEQNO, WP.WIPCODE,
	WP.LOCALTRANSVALUE, WP.LOCALBALANCE, OI.OPENITEMNO, T.InsertOrder, WH.DISCOUNTFLAG, 
	-- exclude tax amount
	ABS(DH.LOCALVALUE) - (CASE WHEN  ISNULL(OI.LOCALVALUE, 0)=0 THEN 0 ELSE ABS((DH.LOCALVALUE / OI.LOCALVALUE) * ISNULL(OI.LOCALTAXAMT, 0)) END) DH_LOCALVALUE,
	DH.LOCALVALUE DH_LOCALVALUE_ORIG,

	/*Sort by credit wip in debit note and debit wip in credit note first so that they get applied before other wips.  Applied to cash accounting only.*/
	case	when WH.DISCOUNTFLAG = 0 and sign(DH.LOCALVALUE) = sign(WP.LOCALBALANCE) then 1 
		when WH.DISCOUNTFLAG = 1 then 1 
		else 2 end as CREDITWIP,		

	DH.TRANSTYPE, WA.NEWSEQNO
	from 
	-- There can be multiple DEBTORHISTORY rows for a reftransno and itemtransno that is a credit note and being applied to multiple invoices.
	-- Each payment is a row against the credit note item within the same reftransno. 
	-- We need to get the debtor total payment amount (e.g. SUM(LOCALVALUE)) of the transaction to allocate to WIP items.
	(SELECT ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, REFENTITYNO, REFTRANSNO, TRANSTYPE,
	SUM(LOCALVALUE) LOCALVALUE, SUM(LOCALTAXAMT) LOCALTAXAMT, 
	SUM(FOREIGNTRANVALUE) FOREIGNTRANVALUE, SUM(FOREIGNTAXAMT) FOREIGNTAXAMT
	FROM DEBTORHISTORY 
	WHERE REFENTITYNO = @pnEntityNo 
	AND REFTRANSNO = @pnTransNo
	GROUP BY ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, REFENTITYNO, REFTRANSNO, TRANSTYPE) DH 
	
	JOIN OPENITEM OI on (	OI.ITEMENTITYNO = DH.ITEMENTITYNO 
				and OI.ITEMTRANSNO = DH.ITEMTRANSNO 
				and OI.ACCTENTITYNO = DH.ACCTENTITYNO 
				and OI.ACCTDEBTORNO = DH.ACCTDEBTORNO)

	JOIN (	Select WP.ENTITYNO, WP.TRANSNO, WP.WIPSEQNO, WP.HISTORYLINENO, WP.ACCTDEBTORNO, WH.REFENTITYNO, WH.REFTRANSNO, ISNULL(WH.DISCOUNTFLAG, 0) DISCOUNTFLAG , MAX(WP.PAYMENTSEQNO) PAYMENTSEQNO
		FROM DEBTORHISTORY DH
		JOIN WORKHISTORY WH ON (WH.REFENTITYNO = DH.ITEMENTITYNO
					AND WH.REFTRANSNO = DH.ITEMTRANSNO)			
		JOIN WIPPAYMENT WP ON (WP.ENTITYNO = WH.ENTITYNO
					and WP.TRANSNO = WH.TRANSNO
					and WP.WIPSEQNO = WH.WIPSEQNO
					and WP.HISTORYLINENO = WH.HISTORYLINENO
					and WP.ACCTDEBTORNO = DH.ACCTDEBTORNO) 
		Where DH.REFENTITYNO = @pnEntityNo 
		AND DH.REFTRANSNO = @pnTransNo
		AND WH.MOVEMENTCLASS = 2
		GROUP BY WP.ENTITYNO, WP.TRANSNO, WP.WIPSEQNO, WP.HISTORYLINENO, WP.ACCTDEBTORNO, WH.REFENTITYNO, WH.REFTRANSNO, WH.DISCOUNTFLAG) WH
		ON (WH.REFENTITYNO = DH.ITEMENTITYNO 
		and WH.REFTRANSNO = DH.ITEMTRANSNO )
		
	/* Get the current wip balance before applying the payment */
	JOIN WIPPAYMENT WP on	(WP.ENTITYNO = WH.ENTITYNO
				and WP.TRANSNO = WH.TRANSNO
				and WP.WIPSEQNO = WH.WIPSEQNO
				and WP.HISTORYLINENO = WH.HISTORYLINENO
				and WP.ACCTDEBTORNO = WH.ACCTDEBTORNO
				and WP.PAYMENTSEQNO = WH.PAYMENTSEQNO)	
				
	-- Get the user override payment order
	-- WIPALLOC table created by the front end when user chooses different WIP payment order to the default.
	-- It determines the order of payment allocation to wip on a bill.	
	LEFT JOIN #WIPALLOC WA on (WA.ENTITYNO = WP.ENTITYNO
				and WA.TRANSNO = WP.TRANSNO
				and WA.WIPSEQNO = WP.WIPSEQNO
				and WA.HISTORYLINENO = WP.HISTORYLINENO
				and WA.ACCTDEBTORNO = WP.ACCTDEBTORNO)

	JOIN WIPTEMPLATE WT on WT.WIPCODE = WP.WIPCODE
	JOIN WIPTYPE WTT on WTT.WIPTYPEID = WT.WIPTYPEID
	JOIN dbo.fn_Tokenise(@sWipPaymentPreference, ',') T  on (T.parameter = WTT.CATEGORYCODE)
	Where DH.REFENTITYNO = @pnEntityNo 
	AND DH.REFTRANSNO = @pnTransNo
	AND WP.LOCALBALANCE <> 0
	-- Order by credit item then user override payment preference then default payment category preferences.
	order by  OI.OPENITEMNO, CREDITWIP, WA.NEWSEQNO, T.InsertOrder, WP.TRANSNO, WP.WIPCODE, WP.WIPSEQNO desc

	Select @nRowCount = @@ROWCOUNT, @nErrorCode = @@ERROR
End


If @nErrorCode = 0
Begin
	Select @nRowId = min(ROWID)
	from #WIPITEMDETAIL

	Set @nRowCount = @nRowCount + @nRowId
	Set @sPrevOpenItemNo = null		
enD	


-- Allocate payment amount to each wip 				
While @nRowId < @nRowCount and @nErrorCode = 0
Begin 
	Select @nEntityNo=ENTITYNO, @nTransNo=TRANSNO, @nWipSeqNo=WIPSEQNO, @nHistoryLineNo=HISTORYLINENO, @nAcctDebtorNo=ACCTDEBTORNO, 
	@nPaymentSeqNo=PAYMENTSEQNO, @sWipCode=WIPCODE, @nLocalBalance=WP_LOCALBALANCE, @nLocalValue=DH_LOCALVALUE, @nDiscountFlag=DISCOUNTFLAG, @sOpenItemNo=OPENITEMNO, 
	@nCreditWip=CREDITWIP, @nTransType=TRANSTYPE, @nDH_LOCALVALUE_ORIG=DH_LOCALVALUE_ORIG
	from #WIPITEMDETAIL
	where ROWID = @nRowId

	Select @nErrorCode = @@ERROR
	
	-- Reset payment amount for each debtor item
	If @sPrevOpenItemNo <> @sOpenItemNo or @sPrevOpenItemNo is null
	Begin			
		Set @nTotalAmountRemainder = abs(@nLocalValue)
		Set @sPrevOpenItemNo = @sOpenItemNo
	End
	
	If @nErrorCode = 0 
	Begin	
		If (@nTotalAmountRemainder = 0)
		Begin
			set @nNewLocalTransValue = 0
			set @nNewLocalBalance = @nLocalBalance
		End
		
		Else If (@nLocalBalance = 0)
		Begin
			set @nNewLocalTransValue = 0
			set @nNewLocalBalance = 0
		End

		-- Handling credit items and discount.  Write down the full amount.
		Else If @nDiscountFlag = 1 or @nCreditWip = 1 
		Begin
			set @nNewLocalTransValue = @nLocalBalance * -1
			set @nNewLocalBalance = 0
			set @nTotalAmountRemainder = @nTotalAmountRemainder + @nLocalBalance * sign(@nDH_LOCALVALUE_ORIG)
		End
			
		Else If (abs(@nLocalBalance) >= @nTotalAmountRemainder)
		Begin
			set @nNewLocalTransValue = @nTotalAmountRemainder * -1 * sign(@nLocalBalance)
			set @nNewLocalBalance = (abs(@nLocalBalance) - @nTotalAmountRemainder) *  sign(@nLocalBalance)
			set @nTotalAmountRemainder = 0
		End
		Else
		Begin
			set @nNewLocalTransValue = @nLocalBalance * -1
			set @nNewLocalBalance = 0
			If @nLocalBalance < 0
				set @nTotalAmountRemainder = @nTotalAmountRemainder + @nLocalBalance
			else
				set @nTotalAmountRemainder = @nTotalAmountRemainder - @nLocalBalance
		End
		
	
		Update #WIPITEMDETAIL
		set WP_LOCALTRANSVALUE = @nNewLocalTransValue, 
		WP_LOCALBALANCE = @nNewLocalBalance,
		PAYMENTSEQNO = PAYMENTSEQNO + 1
		where ROWID = @nRowId
		Set @nErrorCode=@@Error
	End

	Set @nRowId = @nRowId + 1
End


-- Add the allocated payment to WIPPAYMENT rows
If @nErrorCode = 0
Begin
	Insert into WIPPAYMENT	(ENTITYNO, TRANSNO, WIPSEQNO, HISTORYLINENO, ACCTDEBTORNO, PAYMENTSEQNO, WIPCODE, LOCALTRANSVALUE, LOCALBALANCE, REFENTITYNO, REFTRANSNO) 
	select			 ENTITYNO, TRANSNO, WIPSEQNO, HISTORYLINENO, ACCTDEBTORNO, PAYMENTSEQNO, WIPCODE, WP_LOCALTRANSVALUE, WP_LOCALBALANCE, @pnEntityNo, @pnTransNo  
	from #WIPITEMDETAIL
	where isnull(WP_LOCALTRANSVALUE, 0) <> 0
	Set @nErrorCode=@@Error
End			



Return @nErrorCode
GO

Grant execute on dbo.fi_WippaymentAllocation to public
GO
