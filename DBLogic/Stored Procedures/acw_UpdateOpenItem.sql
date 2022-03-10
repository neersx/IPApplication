-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_UpdateOpenItem									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_UpdateOpenItem]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_UpdateOpenItem.'
	Drop procedure [dbo].[acw_UpdateOpenItem]
End
Print '**** Creating Stored Procedure dbo.acw_UpdateOpenItem...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.acw_UpdateOpenItem
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnItemEntityNo		int,	-- Mandatory
	@pnItemTransNo		int,	-- Mandatory
	@pnAcctEntityNo		int,	-- Mandatory
	@pnAcctDebtorNo		int,	-- Mandatory
	@psAction	nvarchar(2)		 = null,
	@psOpenItemNo	nvarchar(12)		 = null,
	@pdtItemDate	datetime		 = null,

	@pdtPostDate	datetime		 = null,
	@pnPostPeriod	int		 = null,
	@pdtClosePostDate	datetime		 = null,
	@pnClosePostPeriod	int		 = null,
	@pnStatus	smallint		 = null,
	@pnBillPercentage	decimal(5,2)		 = null,
	@psCurrency	nvarchar(3)		 = null,

	@pnExchRate	decimal(11,4)		 = null,
	@pnItemPreTaxValue	decimal(11,2)		 = null,
	@pnLocalTaxAmt	decimal(11,2)		 = null,
	@pnLocalValue	decimal(11,2)		 = null,
	@pnForeignTaxAmt	decimal(11,2)		 = null,
	@pnForeignValue	decimal(11,2)		 = null,
	@pnLocalBalance	decimal(11,2)		 = null,
	@pnForeignBalance	decimal(11,2)		 = null,
	@pnExchVariance	decimal(11,2)		 = null,
	@psStatementRef	nvarchar(254)		 = null,

	@psReferenceText	nvarchar(max)		 = null,
	@pnNameSnapNo	int		 = null,
	@pnBillFormatId	smallint		 = null,
	@pbBillPrintedFlag	bit		 = null,
	@psRegarding	nvarchar(max)		 = null,
	@psScope	nvarchar(254)		 = null,
	@pnLanguage	int		 = null,
	@psAssocOpenItemNo	nvarchar(12)		 = null,

--	@ptLongRegarding	ntext		 = null,
--	@ptLongRefText	ntext		 = null,
	@pnImageId	int		 = null,
	@psForeignEquivCurrcy	nvarchar(3)		 = null,
	@pnForeignEquivExRate	decimal(11,4)		 = null,
	@pdtItemDueDate	datetime		 = null,
	@pnPenaltyInterest	decimal(5,2)		 = null,
	@pnLocalOrigTakenUp	decimal(11,2)		 = null,
	@pnForeignOrigTakenUp	decimal(11,2)		 = null,
	@psIncludeOnlyWIP	nvarchar(1)		 = null,
	@psPayForWIP	nvarchar(1)		 = null,
	@psPayPropertyType	nchar(1)		 = null,

	@pbRenewalDebtorFlag	bit		 = null,
	@psCaseProfitCentre	nvarchar(6)		 = null,
	@pnLockIdentityId	int		 = null,

	@psFormattedName	nvarchar(254) = null, -- formatted name/address details for NameSnapNo.
	@pnAddressKey	int = null,
	@psFormattedAddress nvarchar(254) = null,
	@pnAttnNameKey	int = null,
	@psFormattedAttention nvarchar(254) = null,
	@pnMainCaseKey		int = null,
	@pnAddressChangeReason	int = null,
	@pdtLogDateTimeStamp		datetime = null
)
as
-- PROCEDURE:	acw_UpdateOpenItem
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update OpenItem if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	---------------	-------	-----------------------------------------------
-- 08-Mar-2010	AT	RFC3605		1	Procedure created.
-- 26-May-2010	AT	RFC9092		2	Expanded Reference and Regarding params to nvarchar(max).
-- 15-Jul-2010	AT	RFC7271		3	Added address change reason.
-- 13-Apr-2012	AT	RFC12165	4	Recalculate and update due date.
-- 20 Oct 2015  MS      R53933          5       Changed parameters size from decimal(8,4) to decimal(11,4)

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sUpdateString 	nvarchar(4000)
Declare @sWhereString		nvarchar(4000)
Declare @sComma		nchar(1)
Declare @sAnd			nchar(5)
Declare @sAlertXML nvarchar(1000)
Declare @nRowCount int

Declare @nItemType int

-- Initialise variables
Set @nErrorCode = 0
Set @sAnd = ' and ' 
Set @sWhereString = CHAR(10)+" where "

Set @psFormattedName = case when @psFormattedName = '' then null else @psFormattedName end
Set @psFormattedAddress = case when @psFormattedAddress = '' then null else @psFormattedAddress end
Set @psFormattedAttention = case when @psFormattedAttention = '' then null else @psFormattedAttention end

If (@nErrorCode = 0)
Begin
	Select @nItemType = ITEMTYPE
	FROM OPENITEM
	WHERE ITEMENTITYNO = @pnItemEntityNo
	AND ITEMTRANSNO = @pnItemTransNo
	AND ACCTENTITYNO = @pnAcctEntityNo
	AND ACCTDEBTORNO = @pnAcctDebtorNo
End

If (@nErrorCode = 0)
Begin
	exec @nErrorCode = biw_DeriveNameSnap		
		@pnUserIdentityId =@pnUserIdentityId,
		@psCulture = @psCulture,
		@pbCalledFromCentura = @pbCalledFromCentura,
		@pnAcctDebtorNo = @pnAcctDebtorNo,
		@psFormattedName = @psFormattedName, -- formatted name/address details for NameSnapNo.
		@pnAddressKey	= @pnAddressKey,
		@psFormattedAddress = @psFormattedAddress,
		@pnAttnNameKey = @pnAttnNameKey,
		@psFormattedAttention = @psFormattedAttention,
		@pnAddressChangeReason = @pnAddressChangeReason,
		@pnNameSnapNo = @pnNameSnapNo OUTPUT
End

If @nErrorCode = 0
Begin
	Set @sUpdateString = "Update OPENITEM
			   set "

	Set @sWhereString = @sWhereString+CHAR(10)+"
		ITEMENTITYNO = @pnItemEntityNo and
		ITEMTRANSNO = @pnItemTransNo and
		ACCTENTITYNO = @pnAcctEntityNo and
		ACCTDEBTORNO = @pnAcctDebtorNo and
		LOGDATETIMESTAMP = @pdtLogDateTimeStamp"

	if (@psAction = '')
	Begin
		Set @psAction = null
	End
	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ACTION = @psAction"

	Set @sComma = ","

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"OPENITEMNO = @psOpenItemNo"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ITEMDATE = @pdtItemDate"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"POSTDATE = @pdtPostDate"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"POSTPERIOD = @pnPostPeriod"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CLOSEPOSTDATE = @pdtClosePostDate"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CLOSEPOSTPERIOD = @pnClosePostPeriod"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"STATUS = @pnStatus"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"BILLPERCENTAGE = @pnBillPercentage"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CURRENCY = @psCurrency"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"EXCHRATE = @pnExchRate"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ITEMPRETAXVALUE = @pnItemPreTaxValue"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"LOCALTAXAMT = @pnLocalTaxAmt"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"LOCALVALUE = @pnLocalValue"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"FOREIGNTAXAMT = @pnForeignTaxAmt"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"FOREIGNVALUE = @pnForeignValue"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"LOCALBALANCE = @pnLocalBalance"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"FOREIGNBALANCE = @pnForeignBalance"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"EXCHVARIANCE = @pnExchVariance"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"STATEMENTREF = case when @psStatementRef = '' then null else @psStatementRef end"

	if (len(@psReferenceText) <= 254)
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"REFERENCETEXT = case when @psReferenceText = '' then null else @psReferenceText end"
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"LONGREFTEXT = null"
	End
	Else
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"REFERENCETEXT = null"
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"LONGREFTEXT = case when @psReferenceText = '' then null else @psReferenceText end"
	End


	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"NAMESNAPNO = @pnNameSnapNo"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"BILLFORMATID = @pnBillFormatId"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"BILLPRINTEDFLAG = @pbBillPrintedFlag"

	if (len(@psRegarding) <= 254)
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"REGARDING = case when @psRegarding = '' then null else @psRegarding end"
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"LONGREGARDING = null"
	End
	Else
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"REGARDING = null"
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"LONGREGARDING = case when @psRegarding = '' then null else @psRegarding end"
	End

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"SCOPE = case when @psScope = '' then null else @psScope end"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"LANGUAGE = @pnLanguage"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ASSOCOPENITEMNO = case when @psAssocOpenItemNo = '' then null else @psAssocOpenItemNo end"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"IMAGEID = @pnImageId"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"FOREIGNEQUIVCURRCY = @psForeignEquivCurrcy"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"FOREIGNEQUIVEXRATE = @pnForeignEquivExRate"

	if (@nItemType in (510, 513))
	Begin
		-- ReCalculate the item due date
		Select @pdtItemDueDate = @pdtItemDate + isnull(IPN.TRADINGTERMS, SC.COLINTEGER)
		From IPNAME IPN, SITECONTROL SC
		WHERE IPN.NAMENO = @pnAcctDebtorNo
		AND SC.CONTROLID = 'Trading Terms'
	End
	
	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ITEMDUEDATE = @pdtItemDueDate"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"PENALTYINTEREST = @pnPenaltyInterest"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"LOCALORIGTAKENUP = @pnLocalOrigTakenUp"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"FOREIGNORIGTAKENUP = @pnForeignOrigTakenUp"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"INCLUDEONLYWIP = @psIncludeOnlyWIP"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"PAYFORWIP = @psPayForWIP"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"PAYPROPERTYTYPE = @psPayPropertyType"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"RENEWALDEBTORFLAG = @pbRenewalDebtorFlag"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CASEPROFITCENTRE = @psCaseProfitCentre"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"LOCKIDENTITYID = @pnLockIdentityId"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"MAINCASEID = @pnMainCaseKey"	

	Set @sSQLString = @sUpdateString + char(10) + @sWhereString

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnItemEntityNo		int,
			@pnItemTransNo		int,
			@pnAcctEntityNo		int,
			@pnAcctDebtorNo		int,
			@psAction		nvarchar(2),
			@psOpenItemNo		nvarchar(12),
			@pdtItemDate		datetime,
			@pdtPostDate		datetime,
			@pnPostPeriod		int,
			@pdtClosePostDate		datetime,
			@pnClosePostPeriod		int,
			@pnStatus		smallint,
			@pnBillPercentage		decimal(5,2),
			@psCurrency		nvarchar(3),
			@pnExchRate		decimal(11,4),
			@pnItemPreTaxValue		decimal(11,2),
			@pnLocalTaxAmt		decimal(11,2),
			@pnLocalValue		decimal(11,2),
			@pnForeignTaxAmt		decimal(11,2),
			@pnForeignValue		decimal(11,2),
			@pnLocalBalance		decimal(11,2),
			@pnForeignBalance		decimal(11,2),
			@pnExchVariance		decimal(11,2),
			@psStatementRef		nvarchar(254),
			@psReferenceText		nvarchar(MAX),
			@pnNameSnapNo		int,
			@pnBillFormatId		smallint,
			@pbBillPrintedFlag		bit,
			@psRegarding		nvarchar(MAX),
			@psScope		nvarchar(254),
			@pnLanguage		int,
			@psAssocOpenItemNo		nvarchar(12),
			@pnImageId		int,
			@psForeignEquivCurrcy		nvarchar(3),
			@pnForeignEquivExRate		decimal(11,4),
			@pdtItemDueDate		datetime,
			@pnPenaltyInterest		decimal(5,2),
			@pnLocalOrigTakenUp		decimal(11,2),
			@pnForeignOrigTakenUp		decimal(11,2),
			@psIncludeOnlyWIP		nvarchar(1),
			@psPayForWIP		nvarchar(1),
			@psPayPropertyType		nchar(1),
			@pbRenewalDebtorFlag		bit,
			@psCaseProfitCentre		nvarchar(6),
			@pnLockIdentityId		int,
			@pdtLogDateTimeStamp	datetime,
			@pnMainCaseKey		int',
			@pnItemEntityNo	 = @pnItemEntityNo,
			@pnItemTransNo	 = @pnItemTransNo,
			@pnAcctEntityNo	 = @pnAcctEntityNo,
			@pnAcctDebtorNo	 = @pnAcctDebtorNo,
			@psAction	 = @psAction,
			@psOpenItemNo	 = @psOpenItemNo,
			@pdtItemDate	 = @pdtItemDate,
			@pdtPostDate	 = @pdtPostDate,
			@pnPostPeriod	 = @pnPostPeriod,
			@pdtClosePostDate	 = @pdtClosePostDate,
			@pnClosePostPeriod	 = @pnClosePostPeriod,
			@pnStatus	 = @pnStatus,
			@pnBillPercentage	 = @pnBillPercentage,
			@psCurrency	 = @psCurrency,
			@pnExchRate	 = @pnExchRate,
			@pnItemPreTaxValue	 = @pnItemPreTaxValue,
			@pnLocalTaxAmt	 = @pnLocalTaxAmt,
			@pnLocalValue	 = @pnLocalValue,
			@pnForeignTaxAmt	 = @pnForeignTaxAmt,
			@pnForeignValue	 = @pnForeignValue,
			@pnLocalBalance	 = @pnLocalBalance,
			@pnForeignBalance	 = @pnForeignBalance,
			@pnExchVariance	 = @pnExchVariance,
			@psStatementRef	 = @psStatementRef,
			@psReferenceText	 = @psReferenceText,
			@pnNameSnapNo	 = @pnNameSnapNo,
			@pnBillFormatId	 = @pnBillFormatId,
			@pbBillPrintedFlag	 = @pbBillPrintedFlag,
			@psRegarding	 = @psRegarding,
			@psScope	 = @psScope,
			@pnLanguage	 = @pnLanguage,
			@psAssocOpenItemNo	 = @psAssocOpenItemNo,
			@pnImageId	 = @pnImageId,
			@psForeignEquivCurrcy	 = @psForeignEquivCurrcy,
			@pnForeignEquivExRate	 = @pnForeignEquivExRate,
			@pdtItemDueDate	 = @pdtItemDueDate,
			@pnPenaltyInterest	 = @pnPenaltyInterest,
			@pnLocalOrigTakenUp	 = @pnLocalOrigTakenUp,
			@pnForeignOrigTakenUp	 = @pnForeignOrigTakenUp,
			@psIncludeOnlyWIP	 = @psIncludeOnlyWIP,
			@psPayForWIP	 = @psPayForWIP,
			@psPayPropertyType	 = @psPayPropertyType,
			@pbRenewalDebtorFlag	 = @pbRenewalDebtorFlag,
			@psCaseProfitCentre	 = @psCaseProfitCentre,
			@pnLockIdentityId	 = @pnLockIdentityId,
			@pdtLogDateTimeStamp = @pdtLogDateTimeStamp,
			@pnMainCaseKey = @pnMainCaseKey

		Set @nRowCount = @@rowcount
End

If (@nRowCount = 0)
Begin
	-- Draft OpenItem not found
	Set @sAlertXML = dbo.fn_GetAlertXML('AC14', 'Concurrency error. Open Item has been changed or deleted. Please reload and try again.',
										null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End

-- Publish new LOGDATETIMESTAMP
if (@nErrorCode = 0)
Begin
		Select @psOpenItemNo as 'OpenItemNo',
		LOGDATETIMESTAMP as 'LogDateTimeStamp'
		from OPENITEM
		WHERE OPENITEMNO = @psOpenItemNo
		and ITEMENTITYNO = @pnItemEntityNo
End

Return @nErrorCode
GO

Grant execute on dbo.acw_UpdateOpenItem to public
GO