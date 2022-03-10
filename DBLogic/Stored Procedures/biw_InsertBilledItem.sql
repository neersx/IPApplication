-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_InsertBilledItem									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_InsertBilledItem]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_InsertBilledItem.'
	Drop procedure [dbo].[biw_InsertBilledItem]
End
Print '**** Creating Stored Procedure dbo.biw_InsertBilledItem...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.biw_InsertBilledItem
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnEntityNo		int,	-- Mandatory.
	@pnTransNo		int,	-- Mandatory.
	@pnWIPEntityNo		int,	-- Mandatory.
	@pnWIPTransNo		int,	-- Mandatory.
	@pnWIPSeqNo		smallint,	-- Mandatory.
	@pnBilledValue		decimal(11,2)		 = null,
	@pnAdjustedValue	decimal(11,2)		 = null,
	@psReasonCode		nvarchar(2)		 = null,
	@pnItemEntityNo		int		 = null,
	@pnItemTransNo		int		 = null,
	@pnItemLineNo		smallint		 = null,
	@pnAcctEntityNo		int		 = null,
	@pnAcctDebtorNo		int		 = null,
	@psForeignCurrency	nvarchar(3)		 = null,
	@pnForeignBilledValue	decimal(11,2)		 = null,
	@pnForeignAdjustedValue	decimal(11,2)		 = null,
	@psGeneratedFromTaxCode nvarchar(3)             = null
)
as
-- PROCEDURE:	biw_InsertBilledItem
-- VERSION:	12
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert BilledItem.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	-------------	-------	-----------------------------------------------
-- 16 Nov 2009	AT	RFC3605		1	Procedure created.
-- 23 Apr 2010	AT	RFC8292		2	Update bill in advance wip with negative values.
-- 26 May 2010	AT	RFC9092		3	Don't update BillLineNo on WH rows.
-- 23 Jun 2010	AT	RFC8291		4	UpdateBillLineNo for Credit Notes.
-- 31 Mar 2011  LP      RFC8412 	5       Add GeneratedFromTaxCode input parameter.
-- 04 May 2011	AT	RFC10555 	6	Allow zero billed value for write offs.
-- 11 May 2011	KR	RFC10616	7	fixing merge issues
-- 26 Oct 2011	AT	RFC10168	8	Add Account for referrential integrity.
-- 05 Jan 2012	AT	RFC9165	9	Insert foreign adjustment if local adjustment has a value.
-- 29 May 2012	AT	RFC12251	10	Added validation to ensure WIP item is still available.
-- 30 May 2012	AT	RFC12118	11	Set BillLineNo on draft items that are consumed by this open item.
-- 03 Jan 2013  MS      R100832         12      Set ForeignValue and ForeignBalance in WORKINPROGRESS and WORKHISTORY tables

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 		nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma			nchar(1)
Declare @nItemType		int
Declare @sAlertXML		nvarchar(2000)

If (@psGeneratedFromTaxCode = '' or @psGeneratedFromTaxCode is null)
and not (@pnEntityNo = @pnWIPEntityNo
	and @pnTransNo = @pnWIPTransNo)
and exists (select * from WORKINPROGRESS
		Where ENTITYNO = @pnWIPEntityNo
		and TRANSNO = @pnWIPTransNo
		and WIPSEQNO = @pnWIPSeqNo
		and STATUS = 2)
Begin
	-- The WIP is already on a bill, we can't bill it again.
	Set @sAlertXML = dbo.fn_GetAlertXML('BI23', 'One or more WIP item(s) have been included on a different bill. Please reload billing to refresh the Available WIP list.',
							null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End

if @pnAcctEntityNo is not null and @pnAcctDebtorNo is not null
Begin
	exec @nErrorCode = dbo.acw_UpdateAccount
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@pbCalledFromCentura	= @pbCalledFromCentura,
			@pnEntityKey	= @pnAcctEntityNo,
			@pnNameKey	= @pnAcctDebtorNo,
			@pnDRAdjustment	= 0,
			@pnCRAdjustment	= 0
End

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into BILLEDITEM
				("


	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"
					ENTITYNO,TRANSNO,WIPENTITYNO,WIPTRANSNO,WIPSEQNO
			"

	Set @sValuesString = @sValuesString+CHAR(10)+"
					@pnEntityNo,@pnTransNo,@pnWIPEntityNo,@pnWIPTransNo,@pnWIPSeqNo
			"


	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"BILLEDVALUE"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnBilledValue"

	if (@pnAdjustedValue is not null and @pnAdjustedValue != 0)
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ADJUSTEDVALUE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnAdjustedValue"
	End

	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"REASONCODE"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psReasonCode"

	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ITEMENTITYNO"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnItemEntityNo"

	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ITEMTRANSNO"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnItemTransNo"

	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ITEMLINENO"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnItemLineNo"

	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ACCTENTITYNO"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnAcctEntityNo"

	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ACCTDEBTORNO"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnAcctDebtorNo"

	if (@psForeignCurrency is not null and @psForeignCurrency != '')
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"FOREIGNCURRENCY"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psForeignCurrency"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"FOREIGNBILLEDVALUE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnForeignBilledValue"
		
		if (ISNULL(@pnForeignAdjustedValue,0) !=0 OR ISNULL(@pnAdjustedValue,0) != 0)
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"FOREIGNADJUSTEDVALUE"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"ISNULL(@pnForeignAdjustedValue,0)"
		End
	End
	
		if (@psGeneratedFromTaxCode is not null and @psGeneratedFromTaxCode != '')
		Begin
				Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"GENERATEDFROMTAXCODE"
				Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psGeneratedFromTaxCode"
		End


		Set @sInsertString = @sInsertString+CHAR(10)+")"
		Set @sValuesString = @sValuesString+CHAR(10)+")"

		Set @sSQLString = @sInsertString + @sValuesString

		exec @nErrorCode=sp_executesql @sSQLString,
			      		N'
				@pnEntityNo		int,
				@pnTransNo		int,
				@pnWIPEntityNo		int,
				@pnWIPTransNo		int,
				@pnWIPSeqNo		smallint,
				@pnBilledValue		decimal(11,2),
				@pnAdjustedValue		decimal(11,2),
				@psReasonCode		nvarchar(2),
				@pnItemEntityNo		int,
				@pnItemTransNo		int,
				@pnItemLineNo		smallint,
				@pnAcctEntityNo		int,
				@pnAcctDebtorNo		int,
				@psForeignCurrency		nvarchar(3),
				@pnForeignBilledValue		decimal(11,2),
				@pnForeignAdjustedValue		decimal(11,2),
				@psGeneratedFromTaxCode      nvarchar(3)',
				@pnEntityNo	 = @pnEntityNo,
				@pnTransNo	 = @pnTransNo,
				@pnWIPEntityNo	 = @pnWIPEntityNo,
				@pnWIPTransNo	 = @pnWIPTransNo,
				@pnWIPSeqNo	 = @pnWIPSeqNo,
				@pnBilledValue	 = @pnBilledValue,
				@pnAdjustedValue	 = @pnAdjustedValue,
				@psReasonCode	 = @psReasonCode,
				@pnItemEntityNo	 = @pnItemEntityNo,
				@pnItemTransNo	 = @pnItemTransNo,
				@pnItemLineNo	 = @pnItemLineNo,
				@pnAcctEntityNo	 = @pnAcctEntityNo,
				@pnAcctDebtorNo	 = @pnAcctDebtorNo,
				@psForeignCurrency	 = @psForeignCurrency,
				@pnForeignBilledValue	 = @pnForeignBilledValue,
				@pnForeignAdjustedValue	 = @pnForeignAdjustedValue,
				@psGeneratedFromTaxCode      = @psGeneratedFromTaxCode
	
End	

If (@nErrorCode = 0)
Begin
	-- update the WIP Statuses to Locked on draft bill
	Set @sSQLString = "Update WORKINPROGRESS
					Set STATUS = 2
					Where ENTITYNO = @pnWIPEntityNo
					and TRANSNO = @pnWIPTransNo
					and WIPSEQNO = @pnWIPSeqNo
					and STATUS = 1" -- Don't update status of draft wip (0)

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'@pnWIPEntityNo		int,
						@pnWIPTransNo		int,
						@pnWIPSeqNo		smallint',
						@pnWIPEntityNo	 = @pnWIPEntityNo,
						@pnWIPTransNo	 = @pnWIPTransNo,
						@pnWIPSeqNo	 = @pnWIPSeqNo
End


If (@nErrorCode = 0)
Begin
	-- update the WIP Balances on Draft WIP
	Set @sSQLString = "Update WIP
			Set LOCALVALUE = Case when LOCALVALUE < 0 Then ABS(BI.BILLEDVALUE) * -1 Else ABS(BI.BILLEDVALUE) End,
			BALANCE = Case when BALANCE < 0 Then ABS(BI.BILLEDVALUE) * -1 Else ABS(BI.BILLEDVALUE) End,
			FOREIGNVALUE = Case when FOREIGNBILLEDVALUE is null then null when FOREIGNVALUE < 0 Then ABS(BI.FOREIGNBILLEDVALUE) * -1 Else ABS(BI.FOREIGNBILLEDVALUE) End,
			FOREIGNBALANCE = Case when FOREIGNBILLEDVALUE is null then null when FOREIGNBALANCE < 0 Then ABS(BI.FOREIGNBILLEDVALUE) * -1 Else ABS(BI.FOREIGNBILLEDVALUE) End
			From BILLEDITEM BI
			Join WORKINPROGRESS WIP on (WIP.ENTITYNO = BI.WIPENTITYNO
						and WIP.TRANSNO = BI.WIPTRANSNO
						and WIP.WIPSEQNO = BI.WIPSEQNO)
			Where WIP.ENTITYNO = @pnWIPEntityNo
			and WIP.TRANSNO = @pnWIPTransNo
			and WIP.WIPSEQNO = @pnWIPSeqNo
			and WIP.STATUS = 0"

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'@pnWIPEntityNo		int,
				@pnWIPTransNo		int,
				@pnWIPSeqNo		smallint',
				@pnWIPEntityNo	 = @pnWIPEntityNo,
				@pnWIPTransNo	 = @pnWIPTransNo,
				@pnWIPSeqNo	 = @pnWIPSeqNo
End

If (@nErrorCode = 0)
Begin
	Set @sSQLString = "Select @nItemType = ITEMTYPE
				FROM OPENITEM
				WHERE ITEMENTITYNO = @pnItemEntityNo
				AND ITEMTRANSNO = @pnItemTransNo
				AND ACCTENTITYNO = @pnAcctEntityNo
				AND ACCTDEBTORNO = @pnAcctDebtorNo"
			
	exec @nErrorCode=sp_executesql @sSQLString,
		      	N'	@nItemType	int OUTPUT,
				@pnItemEntityNo	int,
				@pnItemTransNo	int,
				@pnAcctEntityNo	int,
				@pnAcctDebtorNo	int',
			@nItemType	=@nItemType OUTPUT,
			@pnItemEntityNo	=@pnItemEntityNo,
			@pnItemTransNo	=@pnItemTransNo,
			@pnAcctEntityNo	=@pnAcctEntityNo,
			@pnAcctDebtorNo	=@pnAcctDebtorNo	
End

If (@nErrorCode = 0)
Begin
	-- update the WIP Balances on Draft WIP's Work History
	Set @sSQLString = "Update WH
				Set LOCALTRANSVALUE = Case when LOCALTRANSVALUE < 0 Then ABS(BI.BILLEDVALUE) * -1 Else ABS(BI.BILLEDVALUE) End,
				FOREIGNTRANVALUE = Case when FOREIGNTRANVALUE < 0 Then ABS(BI.FOREIGNBILLEDVALUE)* -1 Else ABS(BI.FOREIGNBILLEDVALUE) End,
				BILLLINENO = case WHEN WH.MOVEMENTCLASS = 2 THEN BI.ITEMLINENO ELSE NULL END "

	Set @sSQLString = @sSQLString + char(10) + "From BILLEDITEM BI
				Join WORKHISTORY WH on (WH.ENTITYNO = BI.WIPENTITYNO
							and WH.TRANSNO = BI.WIPTRANSNO
							and WH.WIPSEQNO = BI.WIPSEQNO)
				Join WORKINPROGRESS WIP on (WIP.ENTITYNO = BI.WIPENTITYNO
							and WIP.TRANSNO = BI.WIPTRANSNO
							and WIP.WIPSEQNO = BI.WIPSEQNO)
				Where WIP.ENTITYNO = @pnWIPEntityNo
				and WIP.TRANSNO = @pnWIPTransNo
				and WIP.WIPSEQNO = @pnWIPSeqNo
				and WIP.STATUS = 0 "
				--and WIP.DISCOUNTFLAG = 0" -- C/S has no bill Line no on Discounts until posted.

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'@pnWIPEntityNo		int,
				@pnWIPTransNo		int,
				@pnWIPSeqNo		smallint',
				@pnWIPEntityNo	 = @pnWIPEntityNo,
				@pnWIPTransNo	 = @pnWIPTransNo,
				@pnWIPSeqNo	 = @pnWIPSeqNo
End


Return @nErrorCode
GO

Grant execute on dbo.biw_InsertBilledItem to public
GO