-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ap_RollbackStandingPayment
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ap_RollbackStandingPayment]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ap_RollbackStandingPayment.'
	Drop procedure [dbo].[ap_RollbackStandingPayment]
End
Print '**** Creating Stored Procedure dbo.ap_RollbackStandingPayment...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ap_RollbackStandingPayment
(
	@pnEntityNo		int,
	@pnTransNo		int		
)
as
-- PROCEDURE:	ap_RollbackStandingPayment
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions Australia Pty Limited
-- DESCRIPTION:	Rollback payment transaction created by the auto payment generation program.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------		
-- 6 Sep 2010	DL		10311	1		Procedure created


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode			int
declare @nTranCountStart	int

-- Initialise variables
Set @nErrorCode = 0

Set @nTranCountStart = @@TranCount

BEGIN TRANSACTION

If @nErrorCode = 0
Begin
	DELETE CASHHISTORY WHERE ENTITYNO = @pnEntityNo and TRANSNO = @pnTransNo 
	DELETE CASHITEM WHERE ENTITYNO = @pnEntityNo and TRANSNO = @pnTransNo 
	DELETE BANKHISTORY WHERE REFENTITYNO = @pnEntityNo and REFTRANSNO = @pnTransNo 

	DELETE CREDITORITEM WHERE ITEMENTITYNO = @pnEntityNo and ITEMTRANSNO = @pnTransNo 
	DELETE CREDITORHISTORY WHERE ITEMENTITYNO = @pnEntityNo and ITEMTRANSNO = @pnTransNo 

	DELETE TAXPAIDITEM WHERE ITEMENTITYNO = @pnEntityNo and ITEMTRANSNO = @pnTransNo 
	DELETE TAXPAIDHISTORY WHERE ITEMENTITYNO = @pnEntityNo and ITEMTRANSNO = @pnTransNo 

	DELETE LEDGERJOURNALLINE WHERE ENTITYNO = @pnEntityNo and TRANSNO = @pnTransNo 
	DELETE LEDGERJOURNAL WHERE ENTITYNO = @pnEntityNo and TRANSNO = @pnTransNo 

	DELETE TRANSACTIONHEADER WHERE ENTITYNO = @pnEntityNo and TRANSNO = @pnTransNo 
End



If @@TranCount > @nTranCountStart
Begin
	If @nErrorCode = 0
		COMMIT TRANSACTION
	Else 
		ROLLBACK TRANSACTION
End


Return @nErrorCode
GO

Grant execute on dbo.ap_RollbackStandingPayment to public
GO
