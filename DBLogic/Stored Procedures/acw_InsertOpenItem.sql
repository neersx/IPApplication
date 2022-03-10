-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_InsertOpenItem									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_InsertOpenItem]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_InsertOpenItem.'
	Drop procedure [dbo].[acw_InsertOpenItem]
End
Print '**** Creating Stored Procedure dbo.acw_InsertOpenItem...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS off
GO

CREATE PROCEDURE dbo.acw_InsertOpenItem
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnItemEntityNo		int,	-- Mandatory.
	@pnItemTransNo		int,	-- Mandatory.
	@pnAcctEntityNo		int,	-- Mandatory.
	@pnAcctDebtorNo		int,	-- Mandatory.
	@psAction	nvarchar(2)		 = null,
	@psOpenItemNo	nvarchar(12)		 = null,
	@psEnteredOpenItemNo	nvarchar(12)		 = null,
	@pdtItemDate	datetime		 = null,

	@pdtPostDate	datetime		 = null,
	@pnPostPeriod	int		 = null,
	@pdtClosePostDate	datetime		 = null,
	@pnClosePostPeriod	int		 = null,
	@pnStatus	smallint		 = null,
	@pnItemType	int		 = null,
	@pnBillPercentage	decimal(5,2)		 = null,
	@pnEmployeeNo	int		 = null,
	@psEmpProfitCentre	nvarchar(6)		 = null,
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

	@psReferenceText	nvarchar(MAX)		 = null,
	@pnNameSnapNo	int		 = null,
	@pnBillFormatId	smallint		 = null,
	@pbBillPrintedFlag	bit		 = null,
	@psRegarding	nvarchar(MAX)		 = null,
	@psScope	nvarchar(254)		 = null,
	@pnLanguage	int		 = null,
	@psAssocOpenItemNo	nvarchar(12)		 = null,

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
	@pnAddressChangeReason	int		= null,
	@psFormattedReference	nvarchar(MAX)	= null
)
as
-- PROCEDURE:	acw_InsertOpenItem
-- VERSION:	13
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert OpenItem.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 16 Nov 2009	AT	RFC3605	1	Procedure created.
-- 25 May 2010	AT	RFC9092	2	Added MainCaseKey.
-- 26 May 2010	AT	RFC9092	3	Added Account foreign key check.
-- 23 Jun 2010	AT	RFC8291	4	Cater for Credit Notes.
-- 15-Jul-2010	AT	RFC7271	5	Add Address Change Reason.
-- 06-Oct-2010	KR	R100374 6	Fix bug with ForeignOrigTakenUp so that null is not saved as 0
-- 28-Dec-2010  MS      R8297 	7       Added Debit note number generation logic 
-- 30-Mar-2011  DV      R10041 	8       Added extra parameter @psEnteredOpenItemNo and do not generate the OpenItemNo if
--                                      			 @psEnteredOpenItemNo is not null.
-- 24-Jun-2011	AT	R10901	9	Insert References as null if empty.
-- 25-Apr-2013	MS	R11732	10	Added ReferenceNo for debtors
-- 20 Oct 2015  MS  R53933  11  Changed parameters size from decimal(8,4) to decimal(11,4)
-- 2  Feb 2017  SW	R58023  12	Removed @pdtItemDueDate null check in order for re-calculation to occur
-- 07 Feb 2018  MS      R73082  13      Added logic to use next available Draft OPENITEMNO 

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 	        nvarchar(4000)
Declare @sValuesString		nvarchar(MAX)
Declare @sComma		        nchar(1)
Declare @sItemNoPrefix          nvarchar(2)

Declare @sAlertXML nvarchar(2000)

set @nErrorCode = 0

If (@psOpenItemNo = '')
Begin
	Set @psOpenItemNo = null
End

-- Add an Account if it doesn't exist
If not exists (select * from ACCOUNT WHERE ENTITYNO = @pnAcctEntityNo AND NAMENO = @pnAcctDebtorNo)
Begin
	If not exists (select * from IPNAME WHERE NAMENO = @pnAcctDebtorNo)
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('AC14', 'The selected debtor is not a client or is not configured for Billing.',
											null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR
	End
	Else
	Begin
		Set @sSQLString = "Insert into ACCOUNT (ENTITYNO, NAMENO, BALANCE, CRBALANCE)
							VALUES (@pnAcctEntityNo, @pnAcctDebtorNo, 0, 0)"
		
		exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnAcctEntityNo int,
				  @pnAcctDebtorNo int',
				  @pnAcctEntityNo = @pnAcctEntityNo,
				  @pnAcctDebtorNo = @pnAcctDebtorNo
	End
End

If (@nErrorCode = 0)
Begin
	-- Check if we have an office setup to generate OI numbers
	Set @sSQLString = "Select @sItemNoPrefix = O.ITEMNOPREFIX
			FROM TABLEATTRIBUTES TA
			join OFFICE O on (O.OFFICEID = TA.TABLECODE)
			Where	O.ITEMNOPREFIX is not null
			and	TABLETYPE = 44
			and	PARENTTABLE = 'NAME'
			and	GENERICKEY = @pnEmployeeNo"
	
	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@sItemNoPrefix        nvarchar(2) OUTPUT,
				  @pnEmployeeNo         int',				 
				  @sItemNoPrefix        = @sItemNoPrefix OUTPUT,				  
				  @pnEmployeeNo         = @pnEmployeeNo
End

-- Generate an Open item Number
If (@nErrorCode = 0 and @psOpenItemNo is null and @psEnteredOpenItemNo is null)
Begin
        Declare @sDraftPrefix nvarchar(10)
        Declare @nCounter int

        If @nErrorCode = 0
        Begin
                Set @sSQLString = "
			        Select @nCounter = SN.LASTDRAFTNO + 1,
                                @psOpenItemNo = isnull(SC.COLCHARACTER, 'D') + isnull(@sItemNoPrefix,'') + CAST((SN.LASTDRAFTNO + 1) AS NVARCHAR(15)),
                                @sDraftPrefix = isnull(SC.COLCHARACTER, 'D') + isnull(@sItemNoPrefix,'')
			        FROM SPECIALNAME SN, SITECONTROL SC
			        WHERE SN.NAMENO = @pnItemEntityNo
                                AND SC.CONTROLID = 'DRAFTPREFIX'"

	         exec @nErrorCode=sp_executesql @sSQLString, 
				        N'@psOpenItemNo nvarchar(12) OUTPUT,
                                          @sDraftPrefix nvarchar(10) OUTPUT,
                                          @nCounter int OUTPUT,
                                          @sItemNoPrefix  nvarchar(2),
                                          @pnItemEntityNo int',
				          @psOpenItemNo = @psOpenItemNo OUTPUT,
                                          @sDraftPrefix = @sDraftPrefix OUTPUT,
                                          @nCounter     = @nCounter OUTPUT,
                                          @sItemNoPrefix = @sItemNoPrefix,
                                          @pnItemEntityNo = @pnItemEntityNo
        End

        While exists (Select 1 from OPENITEM where OPENITEMNO = @psOpenItemNo and ITEMENTITYNO = @pnItemEntityNo)
        Begin
	        Set @nCounter = @nCounter + 1
                Select @psOpenItemNo = @sDraftPrefix + CAST(@nCounter AS NVARCHAR(15))                
        End 

        Set @sSQLString = "
			UPDATE SPECIALNAME
			SET LASTDRAFTNO = @nCounter
			WHERE NAMENO = @pnItemEntityNo"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@nCounter  int,
				  @pnItemEntityNo int',
				  @nCounter = @nCounter,
				  @pnItemEntityNo = @pnItemEntityNo
End
Else if (@nErrorCode = 0 and @psEnteredOpenItemNo is not null)
Begin
        Set @psOpenItemNo = @psEnteredOpenItemNo
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
		@pnAddressChangeReason	= @pnAddressChangeReason,
		@psFormattedReference = @psFormattedReference,
		@pnNameSnapNo = @pnNameSnapNo OUTPUT
End

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into OPENITEM
				("

	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"
				ITEMENTITYNO,ITEMTRANSNO,ACCTENTITYNO,ACCTDEBTORNO,OPENITEMNO
			"

	Set @sValuesString = @sValuesString+CHAR(10)+"
				@pnItemEntityNo,@pnItemTransNo,@pnAcctEntityNo,@pnAcctDebtorNo,@psOpenItemNo
			"


	If (@psAction is not null and @psAction != '')
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ACTION"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psAction"
	End

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ITEMDATE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pdtItemDate"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"POSTDATE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pdtPostDate"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"POSTPERIOD"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnPostPeriod"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CLOSEPOSTDATE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pdtClosePostDate"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CLOSEPOSTPERIOD"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnClosePostPeriod"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"STATUS"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnStatus"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ITEMTYPE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnItemType"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"BILLPERCENTAGE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnBillPercentage"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"EMPLOYEENO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnEmployeeNo"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"EMPPROFITCENTRE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psEmpProfitCentre"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CURRENCY"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psCurrency"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"EXCHRATE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnExchRate"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ITEMPRETAXVALUE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnItemPreTaxValue"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"LOCALTAXAMT"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnLocalTaxAmt"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"LOCALVALUE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnLocalValue"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"FOREIGNTAXAMT"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnForeignTaxAmt"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"FOREIGNVALUE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnForeignValue"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"LOCALBALANCE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnLocalBalance"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"FOREIGNBALANCE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnForeignBalance"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"EXCHVARIANCE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnExchVariance"

		if (@psStatementRef != '' and @psStatementRef is not null)
		Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"STATEMENTREF"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psStatementRef"
		End
		
		if (@psReferenceText != '' and @psReferenceText is not null)
		Begin
		if (len(@psReferenceText) <= 254)
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"REFERENCETEXT"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psReferenceText"
		End
		Else
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"LONGREFTEXT"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psReferenceText"
		End
		End

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"NAMESNAPNO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnNameSnapNo"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"BILLFORMATID"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnBillFormatId"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"BILLPRINTEDFLAG"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pbBillPrintedFlag"

		if (@psRegarding != '' and @psRegarding is not null)
		Begin
		if (len(@psRegarding) <= 254)
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"REGARDING"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psRegarding"
		End
		else
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"LONGREGARDING"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psRegarding"
		End
		End
	
		if (@psScope != '' and @psScope is not null)
		Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"SCOPE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psScope"
		End

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"LANGUAGE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnLanguage"

		if (@psAssocOpenItemNo is not null and @psAssocOpenItemNo != '')
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ASSOCOPENITEMNO"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psAssocOpenItemNo"
		End

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"IMAGEID"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnImageId"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"FOREIGNEQUIVCURRCY"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psForeignEquivCurrcy"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"FOREIGNEQUIVEXRATE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnForeignEquivExRate"

		if (@pnItemType in (510, 513))
		Begin
			-- Calculate the item due date
			Select @pdtItemDueDate = @pdtItemDate + isnull(IPN.TRADINGTERMS, SC.COLINTEGER)
			From IPNAME IPN, SITECONTROL SC
			WHERE IPN.NAMENO = @pnAcctDebtorNo
			AND SC.CONTROLID = 'Trading Terms'
		End
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ITEMDUEDATE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pdtItemDueDate"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PENALTYINTEREST"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnPenaltyInterest"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"LOCALORIGTAKENUP"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnLocalOrigTakenUp"

		if (@pnForeignOrigTakenUp != 0)
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"FOREIGNORIGTAKENUP"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnForeignOrigTakenUp"
		End

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"INCLUDEONLYWIP"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psIncludeOnlyWIP"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PAYFORWIP"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psPayForWIP"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PAYPROPERTYTYPE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psPayPropertyType"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"RENEWALDEBTORFLAG"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pbRenewalDebtorFlag"

		if (@psCaseProfitCentre is not null and @psCaseProfitCentre != '')
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CASEPROFITCENTRE"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psCaseProfitCentre"
		End

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"LOCKIDENTITYID"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnLockIdentityId"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"MAINCASEID"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnMainCaseKey"




	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

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
			@pnItemType		int,
			@pnBillPercentage		decimal(5,2),
			@pnEmployeeNo		int,
			@psEmpProfitCentre		nvarchar(6),
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
			@pnMainCaseKey			int',
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
			@pnItemType	 = @pnItemType,
			@pnBillPercentage	 = @pnBillPercentage,
			@pnEmployeeNo	 = @pnEmployeeNo,
			@psEmpProfitCentre	 = @psEmpProfitCentre,
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
--			@ptLongRegarding	 = @ptLongRegarding,
--			@ptLongRefText	 = @ptLongRefText,
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
			@pnMainCaseKey		 = @pnMainCaseKey
End

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

Grant execute on dbo.acw_InsertOpenItem to public
GO