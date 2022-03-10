-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fi_DeleteClientRefundTrans									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fi_DeleteClientRefundTrans]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.fi_DeleteClientRefundTrans.'
	Drop procedure [dbo].[fi_DeleteClientRefundTrans]
End
Print '**** Creating Stored Procedure dbo.fi_DeleteClientRefundTrans...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS off
GO

CREATE PROCEDURE dbo.fi_DeleteClientRefundTrans
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnEntityNo			int,	-- Mandatory
	@pnTransNo			int		-- Mandatory
)
as
-- PROCEDURE:	fi_DeleteClientRefundTrans
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete a payment transaction of type client refund. 
--
-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------------	-------	-----------------------------------------------
-- 07 Oct 2010	DL	SQA18901	1	Procedure created.
-- 07 Jul 2015	DL	RFC484451	2	Delete draft wippayment rows

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
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
		Delete CASHITEM
		where ENTITYNO = @pnEntityNo
		and TRANSNO = @pnTransNo

		Set @nErrorCode = @@error
	End

	If (@nErrorCode = 0)
	Begin
		Delete BANKHISTORY
		where REFENTITYNO = @pnEntityNo
		and REFTRANSNO = @pnTransNo

		Set @nErrorCode = @@error
	End

	
	If (@nErrorCode = 0)
	Begin
		Delete TAXHISTORY 
		where REFENTITYNO = @pnEntityNo
		and REFTRANSNO = @pnTransNo

		Set @nErrorCode = @@error
	End


	If (@nErrorCode = 0)
	Begin
		Delete DEBTORHISTORY 
		where REFENTITYNO = @pnEntityNo
		and REFTRANSNO = @pnTransNo

		Set @nErrorCode = @@error
	End
		

	If (@nErrorCode = 0)
	Begin
		Delete WIPPAYMENT
		where REFENTITYNO = @pnEntityNo
		and REFTRANSNO = @pnTransNo

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

Grant execute on dbo.fi_DeleteClientRefundTrans to public
GO