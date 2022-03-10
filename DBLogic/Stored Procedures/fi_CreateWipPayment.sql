-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fi_CreateWipPayment									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fi_CreateWipPayment]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.fi_CreateWipPayment.'
	Drop procedure [dbo].[fi_CreateWipPayment]
End
Print '**** Creating Stored Procedure dbo.fi_CreateWipPayment...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS off
GO


CREATE PROCEDURE dbo.fi_CreateWipPayment
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnEntityNo			int,				-- Mandatory
	@pnTransNo			int		= null,		-- TRANSNO of the WORKHISTORY row
	@pnAcctDebtorNo			int		= null,		-- Mandatory
	@pnRefTransNo			int,				-- REFTRANSNO of the DEBTORHISTORY row
	@pnWipSeqNo			int		= null,		-- WH.WIPSEQNO
	@pnHistoryLineNo		int		= null		-- WH.HISTORYLINENO  (handle debit wip generated from credit note)	
)
as
-- PROCEDURE:	fi_CreateWipPayment
-- VERSION:	15
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert data into WIPPAYMENT. 
--				WIPPAYMENT stores payment distribution of bill to WIP.  This table enables the 
--				calculation of the remaining unpaid amount for each WIP in a bill.
--
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 23 Sep 2010	DL	SQA17959 1	Procedure created.
-- 15 Jan 2015	DL	42133	 2	Adjust rounding error when payments involve transactions with multi-debtors.
-- 12 Feb 2015	DL	44846	 3	Unable to pay an invoice with WIP disbursed from Account Payble
-- 18 Feb 2015  DL	44871    4	Track discounts and margins separately in WIPPAYMENT table
-- 02 Mar 2015	DL	44646	 5	Handle generated debit wip created from a credit note 
-- 01 Apr 2015	DL	46052	 6	Allow Financial interface to cater for apply credit functionality of Prepayment and Unallocated Cash in Billing when Cash Accounting is ON
-- 14 Apr 2015	vql	45860	 7	NULL out foreign values as they are not used in WIPPAYMENT.
-- 28 Apr 2015	DL	46647	 8	Performance improvement by using temp tables instead of joining to WORKHISTORY when performing bulk invoice payment from client server AR.
-- 26 Jun 2015	DL	48445	 9	Incorrect journal entries created for Client Refund transactions
-- 29 Jul 2015	DL	48744	 10	Incorrect journal entries created for AR/AP offset transactions
-- 09 Nov 2015  DL	31343	 11	Allow inter-entity receipts  
-- 28 Apr 2016	DL	59359	 12	Incorrect GL Journal for Debtor write-Off
-- 19 May 2016	DL	60728	 13	Incorrect GL Journal when a bill that has credit WIP items is 'paid off'
-- 05 Aug 2016	DL	64172	 14	Enhance performance - Get the initial balance of all wip involved in the transaction rather than individually.
-- 08 May 2017	DL	70444	 15	Invalid GL Journal for a receipt allocated to a split bill that has discounts (rounding issue - total wippayment does not match invoice amount due to split bill)


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
declare @nWipCountInBill int



set @nErrorCode = 0


If (@nErrorCode = 0)
Begin
	if not exists (	Select 1
			from  DEBTORHISTORY 
			where ITEMENTITYNO = @pnEntityNo
			and REFTRANSNO = @pnRefTransNo
			and (	TRANSTYPE  IN ( 520, 526, 714, 710, 528)	-- 520=Remittance; 526=Credit Allocation; 714=Client Refund; 710=AR/AP Offset; 528=Debtors Write-Off
				OR (TRANSTYPE = 510 AND LOCALVALUE < 0)))	-- Bill with apply credit
		return 0
End


Begin Transaction

If @nErrorCode = 0 
Begin
	Insert into WIPPAYMENT (ENTITYNO, TRANSNO, WIPSEQNO, HISTORYLINENO, ACCTDEBTORNO, PAYMENTSEQNO, WIPCODE,
	LOCALTRANSVALUE, LOCALBALANCE, REFENTITYNO, REFTRANSNO)

	Select DISTINCT WH.ENTITYNO, WH.TRANSNO, WH.WIPSEQNO, WH.HISTORYLINENO, DH.ACCTDEBTORNO,
	1 PAYMENTSEQNO, WH.WIPCODE,
	
	0 as LOCALTRANSVALUE, 

	-- LOCALBALANCE = 
	-- WIP - (Payment portion * WIP)) * BILLPERCENTAGE
	-- OR if transaction type is billing (510) with apply credit then LOCALBALANCE = WIP * BILLPERCENTAGE 
	-- where WIP = WH.LOCALTRANSVALUE (before discount)
	-- Note: LOCALBALANCE would be negative for Credit WIP
	Case when DH.TRANSTYPE = 510 then round(WH.LOCALTRANSVALUE * ISNULL(OI.BILLPERCENTAGE, 100) /100, 2) * -1 
	else
		ROUND( 
		(	WH.LOCALTRANSVALUE   
			- 	
			(  ((OI.LOCALVALUE 
					- case when DH.LOCALBALANCE is null then OI.LOCALBALANCE + DH2.LOCALVALUE else DH.LOCALBALANCE end 
					+ DH2.LOCALVALUE ) / OI.LOCALVALUE ) -- payment proportion
					* WH.LOCALTRANSVALUE ) -- wip amount 
		)					
		* (ISNULL(OI.BILLPERCENTAGE, 100) /100), 2) * -1
	end as LOCALBALANCE,
	
	DH.REFENTITYNO, DH.REFTRANSNO
	
	FROM DEBTORHISTORY DH
	-- There may be multiple debtorhistory rows against the credit note item (itemtransno) when it is applied to multiple invoices.
	-- Therefore we need to get the total allocated SUM(D.LOCALVALUE) of the item.
	JOIN (SELECT D.ITEMENTITYNO, D.ITEMTRANSNO, D.ACCTDEBTORNO, MAX(D.HISTORYLINENO) AS HISTORYLINENO
		, SUM(D.LOCALVALUE) LOCALVALUE, SUM(D.FOREIGNTRANVALUE) FOREIGNTRANVALUE 
		FROM DEBTORHISTORY  D
		WHERE 	 D.REFENTITYNO = @pnEntityNo
		and D.REFTRANSNO = @pnRefTransNo
		GROUP BY D.ITEMENTITYNO, D.ITEMTRANSNO, D.ACCTDEBTORNO ) DH2 ON DH2.ITEMENTITYNO = DH.ITEMENTITYNO
									AND DH2.ITEMTRANSNO = DH.ITEMTRANSNO 
									AND DH2.ACCTDEBTORNO = DH.ACCTDEBTORNO
									AND DH2.HISTORYLINENO = DH.HISTORYLINENO		
	INNER JOIN OPENITEM OI   ON OI.ITEMENTITYNO = DH.ITEMENTITYNO       
						AND OI.ITEMTRANSNO = DH.ITEMTRANSNO       
						AND OI.ACCTENTITYNO = DH.ACCTENTITYNO       
						AND OI.ACCTDEBTORNO = DH.ACCTDEBTORNO  
	INNER JOIN WORKHISTORY WH  ON WH.REFENTITYNO = DH.ITEMENTITYNO        
					AND WH.REFTRANSNO = DH.ITEMTRANSNO 
	LEFT JOIN WIPPAYMENT WP ON (WP.ENTITYNO = WH.ENTITYNO
				and WP.TRANSNO = WH.TRANSNO
				and WP.WIPSEQNO = WH.WIPSEQNO
				and WP.HISTORYLINENO = WH.HISTORYLINENO
				and WP.ACCTDEBTORNO = DH.ACCTDEBTORNO)							
	 							
	WHERE  DH.REFENTITYNO = @pnEntityNo 
	AND DH.REFTRANSNO = @pnRefTransNo
	AND WH.MOVEMENTCLASS = 2
	-- Only add wippayment that yet exist in the WIPPAYMENT table
	AND WP.TRANSNO is null

	Select @nErrorCode = @@ERROR
End


-- Handling rounding error for split invoices
If @nErrorCode = 0
Begin
	-- Get split invoices of cases with multi debtor.  These invoices may need rounding adjustment to the wip amount recorded in wippayment 
	-- so that the wippayment total match the invoice amount.
	WITH MULTIDEBTOR (ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO)
	AS (
		SELECT DISTINCT DH.ITEMENTITYNO, DH.ITEMTRANSNO, DH.ACCTENTITYNO, DH.ACCTDEBTORNO
		FROM 
			(SELECT OI.ITEMENTITYNO, OI.ITEMTRANSNO
				FROM OPENITEM  OI
				JOIN (	SELECT DISTINCT ITEMENTITYNO, ITEMTRANSNO, ACCTDEBTORNO
						FROM  DEBTORHISTORY 
						WHERE REFENTITYNO = @pnEntityNo
						AND REFTRANSNO = @pnRefTransNo) DH ON DH.ITEMENTITYNO = OI.ITEMENTITYNO
															AND DH.ITEMTRANSNO  = OI.ITEMTRANSNO
				GROUP BY OI.ITEMENTITYNO, OI.ITEMTRANSNO
				HAVING COUNT(*) > 1) OI
			JOIN DEBTORHISTORY DH ON DH.ITEMENTITYNO = OI.ITEMENTITYNO
									AND DH.ITEMTRANSNO = OI.ITEMTRANSNO
									AND DH.REFENTITYNO = @pnEntityNo
									AND DH.REFTRANSNO = @pnRefTransNo)


	UPDATE WP
	SET WP.LOCALBALANCE = WP.LOCALBALANCE + TEMP.DIFF_LOCAL,
	WP.FOREIGNBALANCE = WP.FOREIGNBALANCE + TEMP.DIFF_FOREIGN
	FROM WIPPAYMENT WP
	JOIN (	Select DISTINCT 
		-- Exclude tax as WIP does not contain tax.
		OI.ITEMPRETAXVALUE - WP.LOCALBALANCE DIFF_LOCAL, 
		isnull(OI.FOREIGNVALUE,0) - isnull(OI.FOREIGNTAXAMT, 0) - WP.FOREIGNBALANCE DIFF_FOREIGN, 
		WP.ENTITYNO, WP.TRANSNO, WP.ACCTDEBTORNO, WP.WIPSEQNO, WP.HISTORYLINENO

		from MULTIDEBTOR MD
		-- Get the creditor total amount for each bill or credit note after splitting at wip level to compare with the OPTENITEM.LOCALVALUE to determine any rounding errors due to 
		-- multi-debtor splitting of wip amount.  
		-- Rounding differences is to be adjusted to the last wip item in the bill or credit note recorded in the WIPPAYMENT table.
		JOIN (	SELECT WP1.REFENTITYNO, WP1.REFTRANSNO, MD.ITEMENTITYNO, MD.ITEMTRANSNO, MD.ACCTDEBTORNO, 
				SUM(WP1.LOCALBALANCE) LOCALBALANCE, SUM(WP1.FOREIGNBALANCE) FOREIGNBALANCE,
				MAX(WP1.ENTITYNO) ENTITYNO, MAX(WP1.TRANSNO) TRANSNO, MAX(WP1.WIPSEQNO) WIPSEQNO, MAX(WP1.HISTORYLINENO) HISTORYLINENO, COUNT(1) WIPPAYMENTCOUNT
				from MULTIDEBTOR MD
				JOIN WORKHISTORY WH  ON WH.REFENTITYNO = MD.ITEMENTITYNO        
								AND WH.REFTRANSNO = MD.ITEMTRANSNO 
				JOIN WIPPAYMENT WP1 ON (WP1.ENTITYNO = WH.ENTITYNO
							and WP1.TRANSNO = WH.TRANSNO
							and WP1.WIPSEQNO = WH.WIPSEQNO
							and WP1.HISTORYLINENO = WH.HISTORYLINENO
							and WP1.ACCTDEBTORNO = MD.ACCTDEBTORNO)
				WHERE WP1.REFENTITYNO = @pnEntityNo
				AND WP1.REFTRANSNO = @pnRefTransNo
				AND WH.MOVEMENTCLASS = 2
				AND WP1.PAYMENTSEQNO = 1
				GROUP BY WP1.REFENTITYNO, WP1.REFTRANSNO, MD.ITEMENTITYNO, MD.ITEMTRANSNO, MD.ACCTDEBTORNO
				) AS WP ON WP.ITEMENTITYNO = MD.ITEMENTITYNO
						AND WP.ITEMTRANSNO = MD.ITEMTRANSNO
						AND WP.ACCTDEBTORNO = MD.ACCTDEBTORNO
		JOIN OPENITEM OI ON OI.ITEMENTITYNO = MD.ITEMENTITYNO
				AND OI.ITEMTRANSNO  = MD.ITEMTRANSNO
				AND OI.ACCTDEBTORNO = MD.ACCTDEBTORNO
		) TEMP ON TEMP.ENTITYNO = WP.ENTITYNO
					AND TEMP.TRANSNO = WP.TRANSNO
					AND TEMP.ACCTDEBTORNO = WP.ACCTDEBTORNO
					AND TEMP.WIPSEQNO = WP.WIPSEQNO
					AND TEMP.HISTORYLINENO = WP.HISTORYLINENO
	WHERE WP.PAYMENTSEQNO = 1

	Select @nErrorCode = @@ERROR
End


If (@nErrorCode = 0)
	Commit Transaction
else 
	Rollback Transaction	


Return @nErrorCode
GO

Grant execute on dbo.fi_CreateWipPayment to public
GO

