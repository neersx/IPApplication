-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_ReconcileWIPItems] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_ReconcileWIPItems]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_ReconcileWIPItems].'
	drop procedure dbo.[biw_ReconcileWIPItems]
end
print '**** Creating procedure dbo.[biw_ReconcileWIPItems]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[biw_ReconcileWIPItems]
				@pnUserIdentityId		int,				-- Mandatory
				@psCulture				nvarchar(10) 		= null,
				@pbCalledFromCentura	bit					= 0,
				@pnItemEntityNo			int,				-- Mandatory
				@pnItemTransNo			int				-- Mandatory

as
-- PROCEDURE :	biw_ReconcileWIPItems
-- VERSION :	2
-- DESCRIPTION:	A procedure that reverses the selected bill.
--
-- COPYRIGHT:	Copyright 1993 - 2014 CPA Global Software Solutions Australia Pty Limited
-- MODIFICATION
-- Date		Who	RFC		Version Description
-- -----------	-------	--------------- ------- ----------------------------------------------- 
-- 24/03/2010	KR	RFC8299		1	Procedure created
-- 10/10/2014	AT	R35990		2	Optimised query.

set nocount on

Declare @nErrorCode int
Declare @bDebug bit
Declare @sAlertXML nvarchar(256)


Set @nErrorCode = 0
	
-- Reconcile WIP Ledger

If (@bDebug = 1)
Begin
	Print 'Reconcile WIP Ledger.'
End

if not exists (
	Select * from WORKHISTORY 
	Where REFENTITYNO = @pnItemEntityNo
	and REFTRANSNO = @pnItemTransNo)
Begin
	-- Work history does not exist
	Set @sAlertXML = dbo.fn_GetAlertXML('AC7', 'No Work History records located.',null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End

If exists (Select * From 
		(Select WH1.WHTOTAL, WH2.ENTITYNO, WH2.TRANSNO, WH2.WIPSEQNO
			From  (SELECT SUM(LOCALTRANSVALUE) AS WHTOTAL, ENTITYNO, TRANSNO, WIPSEQNO
				FROM WORKHISTORY
				GROUP BY ENTITYNO, TRANSNO, WIPSEQNO) AS WH1
			Join (SELECT ENTITYNO, TRANSNO, WIPSEQNO 
				FROM WORKHISTORY 
				WHERE REFENTITYNO = @pnItemEntityNo
				AND REFTRANSNO = @pnItemTransNo) AS OT
					on OT.ENTITYNO = WH1.ENTITYNO
					and OT.TRANSNO = WH1.TRANSNO
					and OT.WIPSEQNO = WH1.WIPSEQNO
			Join WORKHISTORY WH2 on WH2.ENTITYNO = WH1.ENTITYNO
						and WH2.TRANSNO = WH1.TRANSNO
						and WH2.WIPSEQNO = WH1.WIPSEQNO
			Where WH2.STATUS != 0) AS WH
		Left Join WORKINPROGRESS WIP on (WIP.ENTITYNO = WH.ENTITYNO
						and WIP.TRANSNO = WH.TRANSNO
						and WIP.WIPSEQNO = WH.WIPSEQNO)
		Where (WH.WHTOTAL != 0 and WIP.TRANSNO IS NULL) -- WIP is gone, but WH row not fully consumed
		or (WH.WHTOTAL != WIP.BALANCE and WIP.TRANSNO is not null) -- WIP exists and balance is out of sync with WH
	)
Begin
	-- Work History Balances not calculated correctly
	Set @sAlertXML = dbo.fn_GetAlertXML('AC8', 'Work History records did not reconcile with Work in Progress records.',
										null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End

return @nErrorCode
go

grant execute on dbo.[biw_ReconcileWIPItems]  to public
go
