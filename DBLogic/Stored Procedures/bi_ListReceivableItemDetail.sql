-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.bi_ListReceivableItemDetail  
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[bi_ListReceivableItemDetail  ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.bi_ListReceivableItemDetail  .'
	Drop procedure [dbo].[bi_ListReceivableItemDetail  ]
End
Print '**** Creating Stored Procedure dbo.bi_ListReceivableItemDetail  ...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.bi_ListReceivableItemDetail  
(
	@pnRowCount		int		= null	output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnItemEntityNo		int,		-- Mandatory
	@pnItemTransNo 		int,		-- Mandatory
	@pnAcctEntityNo 	int,		-- Mandatory		
	@pnAcctDebtorNo 	int,		-- Mandatory
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	bi_ListReceivableItemDetail  
-- VERSION:	22
-- SCOPE:	Client WorkBench
-- DESCRIPTION:	Populates ReceivableItemDetailData dataset. Lists details regarding
--		a receivable item.
-- COPYRIGHT:	Copyright 1993 - 2009 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 23-Sep-2003  TM		1	Procedure created
-- 03-Oct-2003	TM		2	RFC404 Itemised Account web part. Remove the table variable
--					and additional Select from the @sPurchaseOrderNo constructing.
--					Add new @pnRowCount output parameter and return the number of 
--					rows in the ItemLine result set. 
-- 10-Oct-2003	MF	RFC519	3	Performance improvements to fn_FilterUserCases & fn_FilterUserNames
-- 13-Oct-2003	MF	RFC533	4	If the user is not on USERIDENTITY table then treat as if External User
-- 28-Nov-2003	JEK	RFC404	5	Tax figures should be null if the item was not taxable.
-- 04-Dec-2003	JEK	RFC699	6	Foreign tax amount suppressed incorrectly.
-- 06-Dec-2003	JEK	RFC406	7	Implement topic level security.
-- 12-Dec-2003	JEK	RFC732	8	NameKey value is incorrect.
-- 18-Dec-2003	JEK	RFC732	9	NameKey missing for debit journals.
-- 06-Jan-2004	TM	RFC733	10	Return PurchaseOrderNo only if the Debtor_Item_Type.UsedByBilling = 1. 
-- 18-Feb-2004	TM	RFC976	11	Add the @pbCalledFromCentura  = default parameter to the calling code 
--					for relevant functions.
-- 13-Sep-2004	TM	RFC886	12	Implement Translation.
-- 15 May 2005	JEK	RFC2508	13	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 23 May 2005	TM	RFC2594	14	Only perform one lookup of the Billing History subject.
-- 24 Nov 2005	LP	RFC1017	15	Extract @nCurrencyDecimalPlaces and @sCurrencyCode from 
--					ac_GetLocalCurrencyDetails and add to the ReceivableItem result set
-- 14 Jul 2006	SW	RFC3828	16	Pass getdate() to fn_Permission..
-- 07 Sep 2006	AU	RFC4269	17	Return RowKey column in ReceivableItem and ItemLine result-sets.
-- 11 Dec 2008	MF	17136	18	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 18 Mar 2009	AT	RFC769	19	Return ItemLine Number from Bill Line.
-- 15 Apr 2013	DV	R13270	20	Increase the length of nvarchar to 11 when casting or declaring integer
-- 02 Nov 2015	vql	R53910	21	Adjust formatted names logic (DR-15543).
-- 10 Nov 2015  MS      R51395  22      Fix narrative length being cut off issue

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int

Declare @sSQLString 		nvarchar(max)
Declare @sPurchaseOrderNo	nvarchar(max)

Declare @bBalanceRequired	bit
Declare @bIsBillingRequired	bit
Declare @bIsExternalUser	bit
Declare	@bIsTaxable		bit
Declare @sLocalCurrencyCode		nvarchar(3)
Declare @nLocalDecimalPlaces		tinyint

Declare @sLookupCulture		nvarchar(10)
Declare	@dtToday		datetime

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
set @dtToday = getdate()

Set 	@nErrorCode 		= 0
Set 	@pnRowCount		= 0

-- Retrieve Local Currency information
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= @pbCalledFromCentura
End

-- We need to determine if the user is external and 
-- check whether the Billing History information is required

If @nErrorCode=0
Begin
	Set @sSQLString="
	Select	@bIsExternalUser=UI.ISEXTERNALUSER,
		@bIsBillingRequired=CASE WHEN TS.IsAvailable = 1 THEN 1 ELSE 0 END
	from USERIDENTITY UI
	left join dbo.fn_GetTopicSecurity(@pnUserIdentityId, 101, default, @dtToday) TS
					on (TS.IsAvailable=1)
	where UI.IDENTITYID=@pnUserIdentityId"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser		bit			OUTPUT,
				  @bIsBillingRequired		bit			OUTPUT,
				  @pnUserIdentityId		int,
				  @dtToday			datetime',
				  @bIsExternalUser		=@bIsExternalUser	OUTPUT,
				  @bIsBillingRequired		=@bIsBillingRequired 	OUTPUT,
				  @pnUserIdentityId		=@pnUserIdentityId,
				  @dtToday			=@dtToday

	If @bIsExternalUser is null
		Set @bIsExternalUser=1
End

-- Determine whether the item is taxable

If @nErrorCode=0
Begin
	Set @sSQLString="
	Select	@bIsTaxable=1
	from 	OPENITEMTAX
	where ITEMENTITYNO 	= @pnItemEntityNo
	and ITEMTRANSNO  	= @pnItemTransNo
	and ACCTENTITYNO 	= @pnAcctEntityNo
	and ACCTDEBTORNO   	= @pnAcctDebtorNo"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@bIsTaxable		bit	OUTPUT,
					  @pnAcctDebtorNo	int,
					  @pnItemEntityNo	int,
					  @pnAcctEntityNo	int,
					  @pnItemTransNo	int',
					  @bIsTaxable		= @bIsTaxable	OUTPUT,
					  @pnAcctDebtorNo	= @pnAcctDebtorNo,
					  @pnItemEntityNo       = @pnItemEntityNo,
					  @pnAcctEntityNo       = @pnAcctEntityNo,
					  @pnItemTransNo	= @pnItemTransNo

	set @bIsTaxable = isnull(@bIsTaxable, 0)

End

-- Set the @bBalanceRequired to 1 if the user has access to the Receivable Items topic.  
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select @bBalanceRequired = IsAvailable
	from dbo.fn_GetTopicSecurity(@pnUserIdentityId, 200, default, @dtToday)"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@bBalanceRequired	bit			OUTPUT,
					  @pnUserIdentityId	int,
					  @dtToday		datetime',
					  @bBalanceRequired	= @bBalanceRequired	OUTPUT,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @dtToday		= @dtToday

	
End

-- Extract the Purchase Order Nos from the CASES table. If more then one are found 
-- concatenate them together with semi-colons(;) 
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select @sPurchaseOrderNo = ISNULL(NULLIF(@sPurchaseOrderNo + ';', ';'),'') + P.PURCHASEORDERNO
	from (select distinct C.PURCHASEORDERNO
	      from WORKHISTORY WH	
	      join CASES C on (C.CASEID = WH.CASEID)
	      where WH.REFENTITYNO = @pnItemEntityNo
	      and   WH.REFTRANSNO = @pnItemTransNo) P"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@sPurchaseOrderNo nvarchar(4000)	OUTPUT,
					  @pnItemEntityNo   int,
					  @pnItemTransNo    int',
					  @sPurchaseOrderNo = @sPurchaseOrderNo	OUTPUT,
					  @pnItemEntityNo   = @pnItemEntityNo,
					  @pnItemTransNo    = @pnItemTransNo 
End

-- Populating ReceivableItem Result Set
If @nErrorCode = 0
Begin
	Set @sSQLString = 
	"Select CAST(O.ITEMENTITYNO as nvarchar(11))+'^'+"+CHAR(10)+
	"	CAST(O.ITEMTRANSNO as nvarchar(11))+'^'+"+CHAR(10)+
	"	CAST(O.ACCTENTITYNO as nvarchar(11))+'^'+"+CHAR(10)+
	"	CAST(O.ACCTDEBTORNO as nvarchar(11))"+CHAR(10)+
	"						as 'RowKey',"+CHAR(10)+
	"	O.ITEMENTITYNO				as 'ItemEntityNo',"+CHAR(10)+
	"       O.ITEMTRANSNO				as 'ItemTransNo',"+CHAR(10)+
	"	O.ACCTENTITYNO				as 'AcctEntityNo',"+CHAR(10)+
	"	O.ACCTDEBTORNO				as 'AcctDebtorNo',"+CHAR(10)+
	"	O.OPENITEMNO				as 'OpenItemNo',"+CHAR(10)+
	"	O.ITEMDATE				as 'ItemDate',"+CHAR(10)+
	dbo.fn_SqlTranslatedColumn('DEBTOR_ITEM_TYPE','DESCRIPTION',null,'DIT',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
						       "as 'ItemTypeDescription',"+CHAR(10)+
	"	ISNULL(O.REFERENCETEXT, O.LONGREFTEXT)	as 'Description',"+CHAR(10)+
	"	ISNULL(NA.NAMENO, N.NAMENO)		as 'NameKey',"+CHAR(10)+
		-- For Items raised by Accounts Receiveble return null for the Address and Attention and format the Name 
		-- from @pnAcctDebtorNo as for an envelope.
	"	ISNULL(NA.FORMATTEDNAME, dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, CF.NAMESTYLE, 7101)))"+CHAR(10)+  
	"						as 'Name',"+CHAR(10)+
	"	NA.FORMATTEDADDRESS			as 'Address',"+CHAR(10)+
	"	NA.FORMATTEDATTENTION			as 'AttentionName',"+CHAR(10)+
	"	CASE WHEN DIT.USEDBYBILLING = 1 THEN ISNULL(@sPurchaseOrderNo, IP.PURCHASEORDERNO) ELSE NULL END"+CHAR(10)+
	"						as 'PurchaseOrderNo',"+CHAR(10)+
	"	O.EMPLOYEENO				as 'RaisedByKey',"+CHAR(10)+
	"	dbo.fn_FormatNameUsingNameNo(EM.NAMENO, COALESCE(EM.NAMESTYLE, CN.NAMESTYLE, 7101))"+CHAR(10)+ 
	" 						as 'RaisedByName',"+CHAR(10)+
	"	@sLocalCurrencyCode			as 'LocalCurrencyCode',"+CHAR(10)+
	"	@nLocalDecimalPlaces			as 'LocalDecimalPlaces',"+CHAR(10)+
	"	ISNULL(O.CURRENCY, @sLocalCurrencyCode)"+CHAR(10)+
	"						as 'ItemCurrencyCode',"+CHAR(10)+
	"	O.ITEMDUEDATE				as 'ItemDueDate',"+CHAR(10)+
	"	O.BILLPERCENTAGE			as 'BillPercentage',"+CHAR(10)+
		-- Untaxed items such as unallocated cash don't have an ItemPreTaxValue.
	"	CASE WHEN @bIsTaxable = 1 THEN O.ITEMPRETAXVALUE ELSE O.LOCALVALUE END"+CHAR(10)+
	"						as 'LocalPreTax',"+CHAR(10)+
		-- If 'Bill Foreign Equiv' site control is on (SC2.COLBOOLEAN = 1) then return null 
		-- for all foreign currency values.
	"	CASE WHEN O.FOREIGNVALUE IS NULL OR SC2.COLBOOLEAN = 1"+CHAR(10)+
	"	     THEN NULL"+CHAR(10)+
	"	     ELSE O.FOREIGNVALUE - O.FOREIGNTAXAMT"+CHAR(10)+
	"	END 					as 'ForeignPreTax',"+CHAR(10)+
		-- Ensure that tax is displayed as null if the item is not taxable.
	"	CASE WHEN @bIsTaxable = 1 THEN O.LOCALTAXAMT ELSE NULL END"+CHAR(10)+
	"		 				as 'LocalTax',"+CHAR(10)+ 
		-- Ensure that foreign tax is displayed as null if the item is not taxable
		-- or the Bill Foreign Equiv is on.
	"	CASE WHEN (SC2.COLBOOLEAN = 1) or (@bIsTaxable = 0)"+CHAR(10)+
	"	     THEN NULL"+CHAR(10)+
	"	     ELSE O.FOREIGNTAXAMT"+CHAR(10)+ 	
	"	END					as 'ForeignTax',"+CHAR(10)+ 
	"	O.LOCALVALUE 				as 'LocalAfterTax',"+CHAR(10)+ 
	"	CASE WHEN SC2.COLBOOLEAN = 1"+CHAR(10)+ 
	"	     THEN NULL"+CHAR(10)+
	"	     ELSE O.FOREIGNVALUE"+CHAR(10)+
	"	END	 				as 'ForeignAfterTax',"+CHAR(10)+
	"	O.LOCALORIGTAKENUP 			as 'LocalTakenUp',"+CHAR(10)+ 
	"	CASE WHEN SC2.COLBOOLEAN = 1"+CHAR(10)+ 
	"	     THEN NULL"+CHAR(10)+
	"	     ELSE O.FOREIGNORIGTAKENUP"+CHAR(10)+
	"	END 		          		as 'ForeignTakenUp',"+CHAR(10)+
	"	CASE WHEN O.LOCALORIGTAKENUP IS NULL"+CHAR(10)+
	"	     THEN O.LOCALVALUE"+CHAR(10)+
	"	     ELSE O.LOCALVALUE - O.LOCALORIGTAKENUP"+CHAR(10)+
	"	END  					as 'LocalOriginalValue',"+CHAR(10)+ 
	"	CASE WHEN O.FOREIGNORIGTAKENUP IS NULL		AND (SC2.COLBOOLEAN = 0 OR SC2.COLBOOLEAN IS NULL) THEN O.FOREIGNVALUE"+CHAR(10)+ 
	"	     WHEN O.FOREIGNORIGTAKENUP IS NOT NULL 	AND (SC2.COLBOOLEAN = 0 OR SC2.COLBOOLEAN IS NULL) THEN O.FOREIGNVALUE - O.FOREIGNORIGTAKENUP"+CHAR(10)+ 
	"	     WHEN SC2.COLBOOLEAN = 1						THEN NULL"+CHAR(10)+ 
	"	END  					as 'ForeignOriginalValue',"+CHAR(10)+
		-- LocalBalance and ForeignBalance are set to null if Accounts Receivable
		-- is not implemented
	"	CASE WHEN @bBalanceRequired = 1"+CHAR(10)+
	"	     THEN O.LOCALBALANCE"+CHAR(10)+
	"	     ELSE NULL"+CHAR(10)+
	"	END  					as 'LocalBalance',"+CHAR(10)+
	"	CASE WHEN @bBalanceRequired = 1 AND (SC2.COLBOOLEAN = 0 OR SC2.COLBOOLEAN IS NULL)"+CHAR(10)+ 
	"	     THEN O.FOREIGNBALANCE"+CHAR(10)+	
	"	     ELSE NULL"+CHAR(10)+
	"	END  					as 'ForeignBalance'"+CHAR(10)+
	"from NAME N"+char(10)+
	
	-- If the user is an External User then require an additional join to the Filtered Names to
	-- ensure the user has access
	CASE WHEN(@bIsExternalUser=1)
		THEN char(10)+"	join dbo.fn_FilterUserNames(@pnUserIdentityId, 1) FN on (FN.NAMENO=N.NAMENO)"+char(10)
	END+

	"join OPENITEM O		on (O.ACCTDEBTORNO = N.NAMENO"+CHAR(10)+
	"				and O.STATUS <> 0)"+CHAR(10)+
	"join DEBTOR_ITEM_TYPE DIT 	on (DIT.ITEM_TYPE_ID = O.ITEMTYPE)"+CHAR(10)+   
	"left join NAMEADDRESSSNAP NA 	on (NA.NAMESNAPNO = O.NAMESNAPNO)"+CHAR(10)+
	"left join COUNTRY CF		on (CF.COUNTRYCODE = N.NATIONALITY)"+CHAR(10)+
	-- If 'Bill Foreign Equiv' site control is on then return null for all foreign
	-- currency values.
	"left join SITECONTROL SC2	on (SC2.CONTROLID = 'Bill Foreign Equiv')"+CHAR(10)+  
	"left join IPNAME IP		on (IP.NAMENO = O.ACCTDEBTORNO)"+CHAR(10)+
	"left join NAME EM		on (EM.NAMENO = O.EMPLOYEENO)"+CHAR(10)+
	"left join COUNTRY CN		on (CN.COUNTRYCODE = EM.NATIONALITY)"+CHAR(10)+
	"where N.NAMENO    = @pnAcctDebtorNo"+CHAR(10)+ 
	"and O.ITEMENTITYNO = @pnItemEntityNo"+CHAR(10)+
	"and O.ACCTENTITYNO = @pnAcctEntityNo"+CHAR(10)+ 
	"and O.ITEMTRANSNO  = @pnItemTransNo"+CHAR(10)+ 
	-- An empty result set is required if the user has access to neither the Billing History
	-- nor Accounts Receivable (@bBalanceRequired) topics.
	"and    (@bIsBillingRequired=1 or @bBalanceRequired=1)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					  @sPurchaseOrderNo     nvarchar(4000),
					  @pnAcctDebtorNo	int,
					  @pnItemEntityNo	int,
					  @pnAcctEntityNo	int,
					  @pnItemTransNo	int,
					  @bBalanceRequired	bit,
					  @bIsTaxable		bit,
					  @bIsBillingRequired	bit,
					  @sLocalCurrencyCode	nvarchar(3),
					  @nLocalDecimalPlaces	tinyint',
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @sPurchaseOrderNo	= @sPurchaseOrderNo,
					  @pnAcctDebtorNo	= @pnAcctDebtorNo,
					  @pnItemEntityNo       = @pnItemEntityNo,
					  @pnAcctEntityNo       = @pnAcctEntityNo,
					  @pnItemTransNo	= @pnItemTransNo,
				    	  @bBalanceRequired	= @bBalanceRequired,
					  @bIsTaxable		= @bIsTaxable,
					  @bIsBillingRequired	= @bIsBillingRequired,
					  @sLocalCurrencyCode	= @sLocalCurrencyCode,
					  @nLocalDecimalPlaces	= @nLocalDecimalPlaces
End	

-- Populating ItemLine Result Set

If @nErrorCode=0
Begin
	Set @sSQLString = "
	Select  CAST(B.ITEMENTITYNO as nvarchar(11))+'^'+
		CAST(B.ITEMTRANSNO as nvarchar(11))+'^'+
		CAST(B.ITEMLINENO as nvarchar(10))
				as 'RowKey',
		B.ITEMENTITYNO	as 'ItemEntityNo',
		B.ITEMTRANSNO	as 'ItemTransNo',  
		B.PRINTDATE	as 'Date',
		ISNULL(B.LONGNARRATIVE, B.SHORTNARRATIVE)
				as 'Narrative',
		B.IRN		as 'CaseReference',
		B.PRINTNAME	as 'StaffName',
		B.VALUE		as 'LocalValue',
		-- If 'Bill Foreign Equiv' site control is on then return null for all foreign
		-- currency values.
		CASE WHEN SC.COLBOOLEAN = 1 THEN NULL 
		     ELSE B.FOREIGNVALUE
		END		as 'ForeignValue',
		ITEMLINENO	as 'ItemLineNo'
	from BILLLINE B "+

	-- If the user is an External User then require an additional join to the Filtered Names to
	-- ensure the user has access
	CASE WHEN(@bIsExternalUser=1)
		THEN char(10)+"	join dbo.fn_FilterUserNames(@pnUserIdentityId, 1) FN on (FN.NAMENO=@pnAcctDebtorNo)"
	END
	+" 
	left join SITECONTROL SC	on (SC.CONTROLID = 'Bill Foreign Equiv') 
	where  B.ITEMENTITYNO = @pnItemEntityNo
	and    B.ITEMTRANSNO = @pnItemTransNo 
	-- An empty result set is required if the user has access to neither the Billing History
	-- nor Accounts Receivable (@bBalanceRequired) topics.
	and    (@bIsBillingRequired=1 or @bBalanceRequired=1)
	order by B.DISPLAYSEQUENCE"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId int,
					  @pnItemEntityNo   int,
					  @pnItemTransNo    int,
					  @pnAcctDebtorNo   int,
					  @bBalanceRequired bit,
					  @bIsBillingRequired bit',
					  @pnUserIdentityId = @pnUserIdentityId,
					  @pnItemEntityNo   = @pnItemEntityNo,
					  @pnItemTransNo    = @pnItemTransNo,
					  @pnAcctDebtorNo   = @pnAcctDebtorNo,
					  @bBalanceRequired = @bBalanceRequired,
					  @bIsBillingRequired = @bIsBillingRequired

	Set @pnRowCount = @@Rowcount
		
End

Return @nErrorCode
GO

Grant execute on dbo.bi_ListReceivableItemDetail   to public
GO
