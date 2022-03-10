-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fi_ApplyCreditForWip
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fi_ApplyCreditForWip]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.fi_ApplyCreditForWip.'
	Drop procedure [dbo].[fi_ApplyCreditForWip]
End
Print '**** Creating Stored Procedure dbo.fi_ApplyCreditForWip...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.fi_ApplyCreditForWip
(
	@pnUserIdentityId	int,		
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnItemEntityNo		int,		-- debtor history item entity number
	@pnItemTransNo		int		-- debtor history item transno
)
as
-- PROCEDURE:	fi_ApplyCreditForWip
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Creates WIPPAYMENT records when credit is allocated to WIP

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 Apr 2015	LP	R45860	1	Procedure created
-- 14 Apr 2015	vql	R45911	2	Handle multi-debtor bills (DR-11510).
-- 15 Apr 2015	vql	R45860	3	Fixed bug where prepayment not added correctly where multiple wip of same wip types added to bill.
-- 08 May 2016	DL	R60728	4	Incorrect GL Journal when a bill that has credit WIP items is 'paid off'
-- 30 Aug 2016	DL	R63741 	5	Zero amount WIPPAYMENT rows unnecessarily created for partial payments allocated to Invoices 



SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @nTransCount int

declare @nItemEntityNo int
declare @nItemTransNo int
declare @nAcctEntityNo int
declare @nAcctDebtorNo int
declare @nHistoryLineNo int
declare @sOpenItemNo nvarchar(12)
declare @dtTransDate datetime
declare @nTransType int
declare @nRefEntityNo int
declare @nRefTransNo int
declare @nAssocLineNo int

declare @nRefTransNoPrev int
declare @nwpEntityNo int
declare @nwpTransNo int
declare @nwpWIPSeqNo int
declare @nwpHistoryLineNo int
declare @nwpAcctDebtorNo int
declare @nwpPaymentSeqNo int
declare @sWipCode nvarchar(6)
declare @nLocalBalance decimal(11,2)
declare @nLocalValue decimal(11,2)
declare @nTotalAmountPaid  decimal(11,2)

declare @nBillPercentage decimal(11,2)
declare @bDiscountFlag decimal(5,1)
declare @nNewLocalTransValue decimal(11,2)
declare @nNewLocalBalance decimal(11,2)
declare @nRefTransNoReversal int
declare @sWipPaymentPreference nvarchar(254)

-- Create temp table
CREATE TABLE #TWIPPAYMENT
(
	ENTITYNO int NOT NULL,
	TRANSNO int NOT NULL,
	WIPSEQNO smallint NOT NULL,
	HISTORYLINENO smallint NOT NULL,
	ACCTDEBTORNO int NOT NULL,
	PAYMENTSEQNO smallint NOT NULL,
	WIPCODE nvarchar(6) NOT NULL,
	LOCALTRANSVALUE decimal(11, 2) NULL,
	FOREIGNTRANSVALUE decimal(11, 2) NULL,
	LOCALBALANCE decimal(11, 2) NULL,
	FOREIGNBALANCE decimal(11, 2) NULL,
	FOREIGNCURRENCY nvarchar(3) NULL,
	REFENTITYNO int NULL,
	REFTRANSNO int NULL,
	SeqOrder   int NULL,
	DISCOUNTFLAG decimal(5,1) NULL,
	CREDITWIP smallint null 
)

-- Initialise variables
Set @nErrorCode = 0
set @nTransCount = 0

If @nErrorCode = 0
Begin
Select @sWipPaymentPreference = COLCHARACTER
from SITECONTROL where CONTROLID = 'FI WIP Payment Preference'
End

Begin transaction 
DECLARE DH_cursor CURSOR FOR  
	Select distinct DH.ITEMENTITYNO, DH.ITEMTRANSNO, DH.ACCTENTITYNO, DH.ACCTDEBTORNO, DH.HISTORYLINENO,
	DH.OPENITEMNO, DH.TRANSDATE, DH.TRANSTYPE, 
	
	-- DH.LOCALVALUE is the amount to be disected among the WIP.  We need to exclude tax as WIP does not include tax.
	ABS(ABS(DH.LOCALVALUE) - (CASE WHEN  ISNULL(OI.LOCALVALUE, 0)=0 THEN 0 ELSE ABS((DH.LOCALVALUE / OI.LOCALVALUE)) * ISNULL(OI.LOCALTAXAMT, 0) END)) 
		* SIGN(DH.LOCALVALUE)  AS DH_LOCALVALUE,
	
	DH.REFENTITYNO, DH.REFTRANSNO, OI.BILLPERCENTAGE, DH.ASSOCLINENO
	FROM DEBTORHISTORY DH 
	join OPENITEM OI on (OI.ITEMENTITYNO = DH.ITEMENTITYNO and OI.ITEMTRANSNO = DH.ITEMTRANSNO and
				OI.ACCTENTITYNO = DH.ACCTENTITYNO and OI.ACCTDEBTORNO = DH.ACCTDEBTORNO)
	join TRANSACTIONHEADER TH ON (TH.ENTITYNO = DH.ITEMENTITYNO 
				and TH.TRANSNO = DH.ITEMTRANSNO 
				and TH.TRANSTYPE in (510) ) 
	where 
	DH.ITEMENTITYNO = @pnItemEntityNo
	and DH.ITEMTRANSNO = @pnItemTransNo
	and DH.TRANSTYPE = 510 and DH.LOCALVALUE < 0
	order by DH.ITEMENTITYNO,DH.ITEMTRANSNO,DH.ACCTENTITYNO,DH.ACCTDEBTORNO,DH.HISTORYLINENO        

OPEN DH_cursor   
FETCH NEXT FROM DH_cursor INTO @nItemEntityNo,@nItemTransNo, @nAcctEntityNo, @nAcctDebtorNo, @nHistoryLineNo,
				@sOpenItemNo, @dtTransDate, @nTransType, @nLocalValue, @nRefEntityNo, @nRefTransNo, @nBillPercentage, @nAssocLineNo
	
	WHILE @@FETCH_STATUS = 0 and @nErrorCode = 0
	Begin 
			Insert into #TWIPPAYMENT (ENTITYNO, TRANSNO, WIPSEQNO, HISTORYLINENO, ACCTDEBTORNO, PAYMENTSEQNO, WIPCODE, LOCALTRANSVALUE, LOCALBALANCE, REFENTITYNO, REFTRANSNO, DISCOUNTFLAG, CREDITWIP)
			Select			  WP.ENTITYNO, WP.TRANSNO, WP.WIPSEQNO, WP.HISTORYLINENO, WP.ACCTDEBTORNO, WP.PAYMENTSEQNO, WP.WIPCODE, 
						  WP.LOCALTRANSVALUE, WP.LOCALBALANCE, WP.REFENTITYNO, @nRefTransNo, WH.DISCOUNTFLAG,
						  case	when WH.DISCOUNTFLAG = 0 and sign(@nLocalValue) = sign(WP.LOCALBALANCE) then 1 
							when WH.DISCOUNTFLAG = 1  then 1 
							else 2 end as CREDITWIP
			from WORKHISTORY WH
			join WIPPAYMENT WP on	(WP.ENTITYNO = WH.ENTITYNO
						and WP.TRANSNO = WH.TRANSNO
						and WP.WIPSEQNO = WH.WIPSEQNO
						and WP.HISTORYLINENO = WH.HISTORYLINENO
						and WP.ACCTDEBTORNO = @nAcctDebtorNo
						and WP.REFENTITYNO = @nRefEntityNo
						and WP.REFTRANSNO = @nRefTransNo)	
			join WIPTEMPLATE WT on WP.WIPCODE = WT.WIPCODE
			join WIPTYPE WTT on WTT.WIPTYPEID = WT.WIPTYPEID
			join dbo.fn_Tokenise(@sWipPaymentPreference, ',') T  on (T.parameter = WTT.CATEGORYCODE)
			where WH.REFENTITYNO = @nItemEntityNo 
			and WH.REFTRANSNO = @nItemTransNo
			and  WH.MOVEMENTCLASS = 2
			order by  CREDITWIP, T.InsertOrder, WP.TRANSNO, WH.WIPSEQNO desc
			
			Set @nErrorCode=@@Error		
			
			DECLARE WP_cursor CURSOR FOR 	
			select ENTITYNO, TRANSNO, WIPSEQNO, HISTORYLINENO, ACCTDEBTORNO, PAYMENTSEQNO, WIPCODE, LOCALBALANCE, DISCOUNTFLAG	
			from #TWIPPAYMENT
			
			OPEN WP_cursor   
			FETCH NEXT FROM WP_cursor INTO @nwpEntityNo, @nwpTransNo, @nwpWIPSeqNo, @nwpHistoryLineNo, 
			@nwpAcctDebtorNo, @nwpPaymentSeqNo, @sWipCode, @nLocalBalance, @bDiscountFlag
						
			Set @nTotalAmountPaid = @nLocalValue * -1
			
			WHILE @@FETCH_STATUS = 0  and @nErrorCode = 0 
			BEGIN	
				if (@nTotalAmountPaid = 0)
				Begin
					set @nNewLocalTransValue = 0
					set @nNewLocalBalance = @nLocalBalance
				End
				
				-- Handling discount
				else if (@bDiscountFlag = 1)
				Begin
					if abs(@nLocalBalance) = 0
					begin
						set @nNewLocalTransValue = 0
						set @nNewLocalBalance = 0
					end
					else if abs(@nLocalBalance) >= @nTotalAmountPaid
					begin
						set @nNewLocalTransValue = @nTotalAmountPaid
						set @nNewLocalBalance = @nLocalBalance + @nTotalAmountPaid
						set @nTotalAmountPaid = 0
					end
					else 
					begin
						set @nNewLocalTransValue = @nLocalBalance * -1
						set @nNewLocalBalance = 0
						set @nTotalAmountPaid = @nTotalAmountPaid + @nLocalBalance * -1
					end
				End
				else if (@nLocalBalance = 0)
				Begin
					set @nNewLocalTransValue = 0
					set @nNewLocalBalance = 0
				End
					
				else if (@nLocalBalance >= @nTotalAmountPaid)
				Begin
					set @nNewLocalTransValue = @nTotalAmountPaid * -1
					set @nNewLocalBalance = @nLocalBalance - @nTotalAmountPaid
					set @nTotalAmountPaid = 0
				end
				else
				begin
					set @nNewLocalTransValue = @nLocalBalance * -1
					set @nNewLocalBalance = 0
					set @nTotalAmountPaid = @nTotalAmountPaid - @nLocalBalance
				end
				
				Update #TWIPPAYMENT
				set LOCALTRANSVALUE = @nNewLocalTransValue,
				LOCALBALANCE = @nNewLocalBalance
				Where ENTITYNO = @nwpEntityNo
				and TRANSNO = @nwpTransNo
				and WIPSEQNO = @nwpWIPSeqNo
				and HISTORYLINENO = @nwpHistoryLineNo
				and PAYMENTSEQNO = @nwpPaymentSeqNo
				and ACCTDEBTORNO = @nwpAcctDebtorNo

				Set @nErrorCode=@@Error
				
				FETCH NEXT FROM WP_cursor INTO @nwpEntityNo, @nwpTransNo, @nwpWIPSeqNo, @nwpHistoryLineNo, 
				@nwpAcctDebtorNo, @nwpPaymentSeqNo, @sWipCode, @nLocalBalance, @bDiscountFlag	
			END   

			CLOSE WP_cursor   
			DEALLOCATE WP_cursor
			
			if @nErrorCode = 0
			begin
				Update #TWIPPAYMENT 
				set PAYMENTSEQNO = PAYMENTSEQNO + 1
				Set @nErrorCode=@@Error
			end	

			if @nErrorCode = 0
			begin
				Insert into WIPPAYMENT	(ENTITYNO, TRANSNO, WIPSEQNO, HISTORYLINENO, ACCTDEBTORNO, PAYMENTSEQNO, WIPCODE, LOCALTRANSVALUE, FOREIGNTRANSVALUE, LOCALBALANCE, FOREIGNBALANCE, FOREIGNCURRENCY, REFENTITYNO, REFTRANSNO) 
				select			 ENTITYNO, TRANSNO, WIPSEQNO, HISTORYLINENO, ACCTDEBTORNO, PAYMENTSEQNO, WIPCODE, LOCALTRANSVALUE, FOREIGNTRANSVALUE, LOCALBALANCE, FOREIGNBALANCE, FOREIGNCURRENCY, REFENTITYNO, REFTRANSNO  
				from #TWIPPAYMENT
				where isnull(LOCALTRANSVALUE, 0) <> 0
				Set @nErrorCode=@@Error
			end			
		
			delete from #TWIPPAYMENT
		
	FETCH NEXT FROM DH_cursor INTO @nItemEntityNo,@nItemTransNo, @nAcctEntityNo, @nAcctDebtorNo, @nHistoryLineNo,
		@sOpenItemNo, @dtTransDate, @nTransType, @nLocalValue, @nRefEntityNo, @nRefTransNo, @nBillPercentage, @nAssocLineNo
	END

CLOSE DH_cursor   
DEALLOCATE DH_cursor

If @nErrorCode = 0 and @@TRANCOUNT > 0
begin
					commit transaction 	
end
Else
Begin
	rollback transaction
End

If (select OBJECT_ID('tempdb..#TWIPPAYMENT')) is not null
Begin
	DROP TABLE #TWIPPAYMENT
End

Return @nErrorCode
GO

Grant execute on dbo.fi_ApplyCreditForWip to public
GO
