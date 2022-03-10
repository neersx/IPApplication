-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fi_DeleteRemittance									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fi_DeleteRemittance]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.fi_DeleteRemittance.'
	Drop procedure [dbo].[fi_DeleteRemittance]
End
Print '**** Creating Stored Procedure dbo.fi_DeleteRemittance...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS off
GO

CREATE PROCEDURE dbo.fi_DeleteRemittance
(
	@pnUserIdentityId		int,		
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura	bit				= 0,
	@pnEntityNo				int,	
	@pnTransNo				int		
)
as
-- PROCEDURE:	fi_DeleteRemittance
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	When a receipt is created in Accounts Receivable, it can be partially 
--				disected to pay a bill (Credit Allocation)
--				and allocate the rest as prepayment or unallocated cash (Remittance).  
--				The user may cancel the Remittance and Credit Allocation if the ledger distribution is not 
--				correct.  This stored procedure is called when this occurs to delete the Remittance and 
--				Credit Allocation.
--				
--
-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	--------	-------	-----------------------------------------------
-- 10 Nov 2010	DL	SQA17959	1	Procedure created.
-- 08 Jan 2015	DL	42133		2	Credit allocation of Credit Note to a Bill is currently not handled by the application

SET CONCAT_NULL_YIELDS_NULL OFF
SET NOCOUNT OFF

Declare @nErrorCode		int

set @nErrorCode = 0

Begin Transaction

-- delete the children rows first
If (@nErrorCode = 0)
Begin
	If (@nErrorCode = 0)
	Begin
		Delete CASHHISTORY
		where REFENTITYNO = @pnEntityNo
		and REFTRANSNO = @pnTransNo

		Set @nErrorCode = @@error
	End

	If (@nErrorCode = 0)
	Begin
		Delete TAXHISTORY 
		where ITEMENTITYNO = @pnEntityNo
		and ITEMTRANSNO = @pnTransNo

		Set @nErrorCode = @@error
	End


	-- 42133 remove wippayment rows associated with the cancelling remittance transaction
	If (@nErrorCode = 0)
	Begin
		Delete WIPPAYMENT
		where REFENTITYNO = @pnEntityNo
		and REFTRANSNO = @pnTransNo

		Set @nErrorCode = @@error
	End

	-- Use REFTRANSNO to delete rows from the remittance and bills
	If (@nErrorCode = 0)
	Begin
		Delete DEBTORHISTORY 
		where REFENTITYNO = @pnEntityNo
		and REFTRANSNO = @pnTransNo

		Set @nErrorCode = @@error
	End

	If (@nErrorCode = 0)
	Begin
		Delete DEBTORHISTORYCASE
		where ITEMENTITYNO = @pnEntityNo
		and ITEMTRANSNO = @pnTransNo

		Set @nErrorCode = @@error
	End

	If (@nErrorCode = 0)
	Begin
		Delete OPENITEMCASE
		where ITEMENTITYNO = @pnEntityNo
		and ITEMTRANSNO = @pnTransNo

		Set @nErrorCode = @@error
	End


	If (@nErrorCode = 0)
	Begin
		Delete OPENITEMTAX
		where ITEMENTITYNO = @pnEntityNo
		and ITEMTRANSNO = @pnTransNo

		Set @nErrorCode = @@error
	End


	If (@nErrorCode = 0)
	Begin
		Delete OPENITEM
		where ITEMENTITYNO = @pnEntityNo
		and ITEMTRANSNO = @pnTransNo

		Set @nErrorCode = @@error
	End

	
	
	If (@nErrorCode = 0)
	Begin
		Delete TRANSACTIONHEADER 
		where ENTITYNO = @pnEntityNo
		and TRANSNO = @pnTransNo

		Set @nErrorCode = @@error
	End

End

If (@nErrorCode = 0)
	Commit Transaction
else 
	Rollback Transaction	

If @pbCalledFromCentura = 1
	select @nErrorCode
	


Return @nErrorCode
GO

Grant execute on dbo.fi_DeleteRemittance to public
GO