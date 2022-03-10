-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fi_CreateDraftWippayment									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fi_CreateDraftWippayment]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.fi_CreateDraftWippayment.'
	Drop procedure [dbo].[fi_CreateDraftWippayment]
End
Print '**** Creating Stored Procedure dbo.fi_CreateDraftWippayment...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.fi_CreateDraftWippayment
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnEntityNo		int,
	@pnTransNo		int,
	@pbRecalcuateFlag	bit		= 0		
)
as
-- PROCEDURE:	fi_CreateDraftWippayment
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Create draft wippayment rows.
--		In Accounts Payable debtors credit notes or debit notes can be used to pay (refund / offset) a supplier invoice.
--		The amount used on the debtor item needs to be distributed to the wip level so that GL journal can be created based on this data.
--
-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	---------------	-------	-----------------------------------------------
-- 23 June 2015	DL	RFC48445	1	Procedure created.
-- 29 Jul 2015	DL	RFC48744	2	Handle AR/AP offset transactions
-- 08 Aug 2016	DL	RFC64172 	3	Added @pbRecalcuateFlag option



SET CONCAT_NULL_YIELDS_NULL OFF
SET NOCOUNT ON


Declare @nErrorCode	int


-- Initialise variables
Set @nErrorCode = 0


If @nErrorCode = 0 and 
exists (select * from SITECONTROL WHERE CONTROLID = 'Cash Accounting' AND COLBOOLEAN = 1) and 
exists (select 	1 
	from	SITECONTROL 
	where   CONTROLID = 'FI WIP Payment Preference'	
	and	case when isnull(PATINDEX('%PD%', COLCHARACTER), 0) > 0 then 1 else 0 end = 1)	
Begin
	-- Create initial balance of each wip
	If @nErrorCode = 0
	Begin
		exec @nErrorCode = dbo.fi_CreateWipPayment 	
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@pbCalledFromCentura	= 0,
			@pnEntityNo		= @pnEntityNo, 
			@pnRefTransNo		= @pnTransNo	
	End
	
	
	-- Create the allocation to each wip.
	If @nErrorCode = 0
	Begin
		exec @nErrorCode = dbo.fi_WippaymentAllocation
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pbCalledFromCentura	= 0,
		@pnEntityNo		= @pnEntityNo,
		@pnTransNo		= @pnTransNo,
		@pbRecalcuateFlag	= @pbRecalcuateFlag
	End
End



Return @nErrorCode
GO

Grant execute on dbo.fi_CreateDraftWippayment to public
GO