-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_ReverseBillValidation] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_ReverseBillValidation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_ReverseBillValidation].'
	drop procedure dbo.[biw_ReverseBillValidation]
end
print '**** Creating procedure dbo.[biw_ReverseBillValidation]...'
print ''
go


set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[biw_ReverseBillValidation]
				@pnUserIdentityId		int,				-- Mandatory
				@psCulture				nvarchar(10) 		= null,
				@pbCalledFromCentura	bit					= 0,
				@pnItemEntityNo			int,				-- Mandatory
				@pnItemTransNo			int,				-- Mandatory
				@pnAcctEntityNo			int,				-- Mandatory
				@pnAcctDebtorNo			int,				-- Mandatory
				@psOpenItemNo		nvarchar(12)		= null,
				@pdtItemDate			datetime			= null
				
				
as
-- PROCEDURE :	biw_ReverseBillValidation
-- VERSION :	5
-- DESCRIPTION:	A procedure that validates the selected bill for reversal.
--
-- COPYRIGHT:	Copyright 1993 - 2010 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC		Version Description
-- -----------	-------	------		------- ----------------------------------------------- 
-- 02/03/2010	KR	RFC8299		1	Procedure created
-- 22/06/2011	KR	RFC10820	2	syntax error fixed while executing fn_GetPostPeriod	
-- 12/10/2011	KR	RFC10774	3	Validate for multiple debtor before paid bills (moved logic above).
-- 15/05/2015	KR	R47534		4	Adjusted the SQL so that it checks correctly for multi debtor bill
-- 25/07/2017	DV	RFC71750	5	Added check for ItemEntityNo and ItemTransNo when checking for openitem.

set nocount on

Declare		@ErrorCode	int
Declare		@nRowCount	int
Declare		@sSQLString	nvarchar(4000)
Declare		@sAlertXML nvarchar(400)
Declare		@bFIStopsBillReversal bit
Declare		@nBillReversalDisabled smallint
Declare		@nPostPeriod int
Declare		@nTransPeriod int
Declare		@nItemEntityNo int
Declare		@nItemTransNo int
Declare		@nAcctDebtorNo int
Declare		@nItemType		int
Declare		@nBillPercentage int
Declare		@nOpenItemCount int
Declare		@nAcctEntityNo int
Declare		@sAssocOpenItemNo nvarchar(12)



Set @ErrorCode = 0

If @ErrorCode = 0
Begin

	If exists(Select * 
					From DEBTOR_ITEM_TYPE DI
					Join OPENITEM OI on (OI.ITEMENTITYNO	= @pnItemEntityNo and
										 OI.ITEMTRANSNO		= @pnItemTransNo and
										 OI.ACCTENTITYNO	= @pnAcctEntityNo and
										 OI.ACCTDEBTORNO	= @pnAcctDebtorNo and
										 OI.ITEMTYPE		= DI.ITEM_TYPE_ID)
					Where DI.DESCRIPTION is null)
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('AC101', 'The open item - item type has no description. Not possible to reverse the bill',
										null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @ErrorCode = @@ERROR
	End

	If @ErrorCode = 0
	Begin
		Set @sSQLString = "
		Select @bFIStopsBillReversal = isnull(COLBOOLEAN,0)
		From SITECONTROL
		Where CONTROLID = 'FIStopsBillReversal'"
		
		exec	@ErrorCode = sp_executesql @sSQLString,
				N'@bFIStopsBillReversal	bit 			OUTPUT',
				@bFIStopsBillReversal = @bFIStopsBillReversal	OUTPUT
	End
	
	If (@ErrorCode = 0 and @bFIStopsBillReversal = 1)
	Begin
			If exists (Select * from GLJOURNAL WHERE 
							ENTITYNO = @pnItemEntityNo and
							TRANSNO = @pnItemTransNo and 
							STATUS = 6712)
			Begin
				Set @sAlertXML = dbo.fn_GetAlertXML('AC102', 'Selected bill has already been exported via the Financial Interface.  Not possible to reverse the bill.',
													null, null, null, null, null)
				RAISERROR(@sAlertXML, 14, 1)
				Set @ErrorCode = @@ERROR
			End
		
	End
	
	If @ErrorCode = 0
	Begin
		Set @sSQLString = "
		Select @nBillReversalDisabled = isnull(COLINTEGER,0)
		From SITECONTROL
		Where CONTROLID = 'BillReversalDisabled'"
		
		exec	@ErrorCode = sp_executesql @sSQLString,
				N'@nBillReversalDisabled	int 			OUTPUT',
				@nBillReversalDisabled = @nBillReversalDisabled	OUTPUT
	End
	
	If (@ErrorCode = 0 and @nBillReversalDisabled = 2)
	Begin
		-- Get Post and Trans Period.
		-- Get Post Period.
		if (@ErrorCode = 0)
		Begin
			Set @sSQLString = "Select @nPostPeriod = dbo.fn_GetPostPeriod(@pdtItemDate, 2) "
			exec @ErrorCode = sp_executesql @sSQLString,
					N'@nPostPeriod int OUTPUT,
					@pdtItemDate datetime',
					@nPostPeriod	= @nPostPeriod	output, 
					@pdtItemDate  = @pdtItemDate
		End
		
		-- Get Trans Period.		
		exec @ErrorCode = dbo.biw_GetTransPeriod
				@pnTransPeriod	= @nTransPeriod output, -- trans period to be returned to the caller
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture	= @psCulture,
				@pbCalledFromCentura = @pbCalledFromCentura,
				@pdtItemDate  = @pdtItemDate
			
		-- if the transaction period is not the same as post period, reversal should not happen

		If (@ErrorCode = 0 and @nPostPeriod != @nTransPeriod)
		Begin
					Set @sAlertXML = dbo.fn_GetAlertXML('AC103', 'The selected bill was posted prior to the current period and cannot be reversed. Please raise a credit note for this bill.',
														null, null, null, null, null)
					RAISERROR(@sAlertXML, 14, 1)
					Set @ErrorCode = @@ERROR
		End
	End
	
	if (@ErrorCode = 0)
	Begin
			Set @sSQLString = "Select @nItemEntityNo = ITEMENTITYNO, @nItemTransNo = ITEMTRANSNO, 
									  @nAcctEntityNo = ACCTENTITYNO, @nAcctDebtorNo = ACCTDEBTORNO,
									  @nItemType = ITEMTYPE, @sAssocOpenItemNo = ASSOCOPENITEMNO
							   From OPENITEM
							   Where OPENITEMNO = @psOpenItemNo
							   and ITEMENTITYNO = @pnItemEntityNo
							   and ITEMTRANSNO = @pnItemTransNo"
			exec	@ErrorCode = sp_executesql @sSQLString,
				N'@nItemEntityNo	int	OUTPUT,
				  @nItemTransNo		int	OUTPUT,
				  @nAcctEntityNo	int OUTPUT,
				  @nAcctDebtorNo	int	OUTPUT,
				  @nItemType		int	OUTPUT,
				  @sAssocOpenItemNo	nvarchar(12) OUTPUT,
				  @psOpenItemNo		nvarchar(12),
				  @pnItemTransNo	int,
				  @pnItemEntityNo	int',
				  @nItemEntityNo	= @nItemEntityNo	OUTPUT,
				  @nItemTransNo		= @nItemTransNo		OUTPUT,
				  @nAcctEntityNo	= @nAcctEntityNo	 OUTPUT,
				  @nAcctDebtorNo	= @nAcctDebtorNo	OUTPUT,
				  @nItemType		= @nItemType		OUTPUT,
				  @sAssocOpenItemNo	= @sAssocOpenItemNo	OUTPUT,
				  @psOpenItemNo		= @psOpenItemNo,
				  @pnItemTransNo	= @pnItemTransNo,
				  @pnItemEntityNo	= @pnItemEntityNo
	End
	
	if (@ErrorCode = 0)
	Begin
	
	-- If the item has been written down or the item has bene used by another bill, Reversal will not be possible.
	If exists (Select 1 from TRANSACTIONHEADER WHERE 
							ENTITYNO = @pnItemEntityNo and
							TRANSNO = @pnItemTransNo and 
							TRANSTYPE = 511)
	Begin
		if exists (Select 1 from WORKHISTORY where REFENTITYNO = @pnItemEntityNo and
								REFTRANSNO = @pnItemTransNo and 
								MOVEMENTCLASS = 3 and
								COMMANDID = 4)
		Begin
		

			if (@ErrorCode = 0)
			Begin
				  
				If exists (Select 1 from WORKHISTORY WH
							Join WORKINPROGRESS WIP on (WIP.ENTITYNO = WH.ENTITYNO and WIP.TRANSNO = WH.TRANSNO
														and WIP.WIPSEQNO = WH.WIPSEQNO)
							Where WH.REFENTITYNO = @nItemEntityNo
							And   WH.REFTRANSNO = @nItemTransNo
							And	  (WH.LOCALTRANSVALUE * -1) > WIP.LOCALVALUE)
				Begin
						Set @sAlertXML = dbo.fn_GetAlertXML('AC104', 'The Credit Full Bill cannot be reversed.  At least one WIP item of the associated Debit Note has been used by another Bill.',
															null, null, null, null, null)
						RAISERROR(@sAlertXML, 14, 1)
						Set @ErrorCode = @@ERROR
				End 
			End
		End
	End
	End
	
		-- check if the bill has a credit note issued
		If (@ErrorCode = 0 and (@nItemType = 510 or @nItemType = 513) and @sAssocOpenItemNo is not null)
		Begin
			Set @sAlertXML = dbo.fn_GetAlertXML('AC105', 'Debit Note has been credited. A reversal cannot be performed.',
													null, null, null, null, null)
				RAISERROR(@sAlertXML, 14, 1)
				Set @ErrorCode = @@ERROR 
		End
			
		-- check if bill is partially paid
		
		If (@ErrorCode = 0)
		Begin
		
			Set @sSQLString = "Select @nBillPercentage = sum(BILLPERCENTAGE), @nItemEntityNo = ITEMENTITYNO, @nItemTransNo = ITEMTRANSNO, 
								@nOpenItemCount = count(*)
				   From OPENITEM
				   Where 
				   CASE WHEN LOCALORIGTAKENUP IS NULL THEN LOCALVALUE ELSE LOCALVALUE - LOCALORIGTAKENUP END = LOCALBALANCE 
					and ITEMTYPE IN (510,513, 511, 514) 
					and ITEMENTITYNO = @pnItemEntityNo
					and ITEMTRANSNO = @pnItemTransNo
					group by ITEMENTITYNO, ITEMTRANSNO"
			exec	@ErrorCode = sp_executesql @sSQLString,
				N'@nBillPercentage int OUTPUT,
				  @nItemEntityNo int OUTPUT,
				  @nItemTransNo int OUTPUT,
				  @nOpenItemCount int OUTPUT,
				  @pnItemEntityNo int,
				  @pnItemTransNo varchar(12)',
				@nBillPercentage = @nBillPercentage OUTPUT,
				  @nItemEntityNo	= @nItemEntityNo	OUTPUT,
				  @nItemTransNo		= @nItemTransNo	OUTPUT,
				  @nOpenItemCount	= @nOpenItemCount OUTPUT,
				  @pnItemEntityNo	= @pnItemEntityNo,
				  @pnItemTransNo	= @pnItemTransNo
				  
		End
		
		If (@ErrorCode = 0 and @nOpenItemCount > 1)
		Begin
			Set @sAlertXML = dbo.fn_GetAlertXML('AC107', 'The bill selected for reversal is part of a multi debtor bill. This process will reverse all bills that make up this multi debtor.',
													null, null, null, null, null)
			RAISERROR(@sAlertXML, 14, 1)
			Set @ErrorCode = @@ERROR 
			
		End
		
		
		If (@ErrorCode = 0 and (@nBillPercentage != 100 or @nBillPercentage is null))
		Begin
			Set @sAlertXML = dbo.fn_GetAlertXML('AC106', 'This bill may not be reversed because either the selected bill or its related multiple debtor bill has been partly or fully paid. Reverse all credits/debits to enable the bill to be reversed.',
													null, null, null, null, null)
			RAISERROR(@sAlertXML, 14, 1)
			Set @ErrorCode = @@ERROR  
		End
	 

					


End

return @ErrorCode
go

grant execute on dbo.[biw_ReverseBillValidation]  to public
go
