-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_ReconcileDebtorItems] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_ReconcileDebtorItems]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_ReconcileDebtorItems].'
	drop procedure dbo.[biw_ReconcileDebtorItems]
end
print '**** Creating procedure dbo.[biw_ReconcileDebtorItems]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[biw_ReconcileDebtorItems]
		@pnUserIdentityId		int,			-- Mandatory
		@psCulture			nvarchar(10) 		= null,
		@pbCalledFromCentura		bit			= 0,
		@pnItemEntityNo			int,			-- Mandatory
	        @pnItemTransNo			int			-- Mandatory

as
-- PROCEDURE :	biw_ReconcileDebtorItems
-- VERSION :	3
-- DESCRIPTION:	A procedure that reverses the selected bill.
--
-- COPYRIGHT:	Copyright 1993 - 2014 CPA Global Software Solutions Australia Pty Limited
-- MODIFICATION
-- Date		Who	RFC		Version Description
-- -----------	-------	---------------	------- ----------------------------------------------- 
-- 08/03/2010	KR	RFC8299		1	Procedure created
-- 30/04/2012	AT	RFC12225	2	Added check for OPENITEMCASE before reconciling applied credits.
-- 05/12/2014	AT	RFC42122	3	Optimised queries for performance.

set nocount on

Declare @nErrorCode int
Declare @bDebug bit
Declare @sAlertXML nvarchar(256)

Set @nErrorCode = 0

If @nErrorCode = 0
Begin
		
-- Reconcile Debtors Ledger (PostCondition)
If (@nErrorCode = 0)
Begin
	If (@bDebug = 1)
	Begin
		Print 'Reconcile Debtors Ledger.'
	End

	if not exists (
	Select * from DEBTORHISTORY
	Where REFENTITYNO = @pnItemEntityNo
	and REFTRANSNO = @pnItemTransNo)
	Begin
		-- Debtor history does not exist
		Set @sAlertXML = dbo.fn_GetAlertXML('AC9', 'No Debtor History records located.',
											null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR
	End

	-- Check OPENITEM/DEBTORHISTORY balances
	If exists (select * from 
			(Select SUM(LOCALVALUE) AS LOCALTOTAL, SUM(ISNULL(FOREIGNTRANVALUE,0)) AS FOREIGNTOTAL,
				DH.ITEMENTITYNO, DH.ITEMTRANSNO, DH.ACCTENTITYNO, DH.ACCTDEBTORNO
				FROM DEBTORHISTORY DH
				join (SELECT DISTINCT ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO
					FROM DEBTORHISTORY
					WHERE REFENTITYNO = @pnItemEntityNo
					AND REFTRANSNO = @pnItemTransNo) RDH 	ON RDH.ITEMENTITYNO = DH.ITEMENTITYNO
										AND RDH.ITEMTRANSNO = DH.ITEMTRANSNO
										AND RDH.ACCTENTITYNO = DH.ACCTENTITYNO
										AND RDH.ACCTDEBTORNO = DH.ACCTDEBTORNO
				WHERE DH.STATUS != 0
				GROUP BY DH.ITEMENTITYNO, DH.ITEMTRANSNO, DH.ACCTENTITYNO, DH.ACCTDEBTORNO) AS DH
			Left Join OPENITEM OI ON (OI.ITEMENTITYNO = DH.ITEMENTITYNO
						AND OI.ITEMTRANSNO = DH.ITEMTRANSNO
						AND OI.ACCTENTITYNO = DH.ACCTENTITYNO
						AND OI.ACCTDEBTORNO = DH.ACCTDEBTORNO)
			Where OI.ITEMTRANSNO IS NULL -- OI does not exist
			or (DH.LOCALTOTAL != OI.LOCALBALANCE and OI.ITEMTRANSNO is not null) -- OI exists and balance is out of sync with DH
			or (DH.FOREIGNTOTAL != OI.FOREIGNBALANCE and OI.ITEMTRANSNO is not null)
	)
	Begin
		-- Debtor History Balances have not calculated correctly
		Set @sAlertXML = dbo.fn_GetAlertXML('AC133', 'Debtor History records did not reconcile with Open Item balance.',
											null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR
	End

	-- Compare to cases
	If exists( select * from OPENITEMCASE OIC
			JOIN OPENITEM OI ON OI.ITEMENTITYNO = OIC.ITEMENTITYNO
					and OI.ITEMTRANSNO = OIC.ITEMTRANSNO
					and OI.ACCTENTITYNO = OIC.ACCTENTITYNO
					and OI.ACCTDEBTORNO = OIC.ACCTDEBTORNO
			WHERE OI.ITEMENTITYNO = @pnItemEntityNo
			and OI.ITEMTRANSNO = @pnItemTransNo )
	and exists (
		Select *
		from (SELECT DISTINCT ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO
					from DEBTORHISTORY
					Where REFENTITYNO = @pnItemEntityNo
					and REFTRANSNO = @pnItemTransNo
					and STATUS != 0) as DH
		Join OPENITEM OI on (OI.ITEMENTITYNO = DH.ITEMENTITYNO
								and OI.ITEMTRANSNO = DH.ITEMTRANSNO
								and OI.ACCTENTITYNO = DH.ACCTENTITYNO
								and OI.ACCTDEBTORNO = DH.ACCTDEBTORNO)
		Left Join (SELECT SUM(LOCALBALANCE) AS LOCALVALUETOTAL, ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO
							FROM OPENITEMCASE
							GROUP BY ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO) as OIC
									on (OIC.ITEMENTITYNO = OI.ITEMENTITYNO
										and OIC.ITEMTRANSNO = OI.ITEMTRANSNO
										and OIC.ACCTENTITYNO = OI.ACCTENTITYNO
										and OIC.ACCTDEBTORNO = OI.ACCTDEBTORNO)
		Left Join (SELECT SUM(LOCALVALUE) AS LOCALVALUETOTAL, ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO
							FROM DEBTORHISTORYCASE
							GROUP BY ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO) as DHC
									on (DHC.ITEMENTITYNO = OI.ITEMENTITYNO
										and DHC.ITEMTRANSNO = OI.ITEMTRANSNO
										and DHC.ACCTENTITYNO = OI.ACCTENTITYNO
										and DHC.ACCTDEBTORNO = OI.ACCTDEBTORNO)
		-- check OPENITEMCASE / DEBTORHISTORYCASE balance with OPENITEM'S LOCALBALANCE
		Where ((OI.LOCALBALANCE != OIC.LOCALVALUETOTAL AND OIC.ITEMTRANSNO IS NOT NULL)
			or
			(OI.LOCALBALANCE != DHC.LOCALVALUETOTAL AND DHC.ITEMTRANSNO IS NOT NULL))
	)	
	Begin
		-- OPENITEMCASE / DEBTORHISTORYCASE does not balance with OPENITEM
		Set @sAlertXML = dbo.fn_GetAlertXML('AC134', 'Open Item Case / Debtor History Case records did not reconcile with Open Item balance.',
											null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR
	End

	-- Compare to Accounts
	If exists(
		Select *
		from DEBTORHISTORY DH
		Join (Select sum(LOCALBALANCE) AS LOCALBALANCETOTAL, ACCTENTITYNO, ACCTDEBTORNO
			From OPENITEM
			Where STATUS IN (1,2)
			Group by ACCTENTITYNO, ACCTDEBTORNO) AS OIAB
						on (OIAB.ACCTENTITYNO = DH.ACCTENTITYNO
							and OIAB.ACCTDEBTORNO = DH.ACCTDEBTORNO)
		Left join ACCOUNT A on (A.ENTITYNO = DH.ACCTENTITYNO and A.NAMENO = DH.ACCTDEBTORNO)
		
		Where DH.REFENTITYNO = @pnItemEntityNo
		and DH.REFTRANSNO = @pnItemTransNo
		and (A.NAMENO IS NULL -- THERE MUST BE AN ACCOUNT
			or OIAB.LOCALBALANCETOTAL != A.BALANCE -- BALANCES MUST BE EQUAL
			)
	)	
	Begin
		-- OPENITEMCASE / DEBTORHISTORYCASE does not balance with OPENITEM
		Set @sAlertXML = dbo.fn_GetAlertXML('AC135', 'Total OpenItem balance does not match Account Balance.',
											null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR
	End
End



End

return @nErrorCode
go

grant execute on dbo.[biw_ReconcileDebtorItems]  to public
go
