-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_GetBillAvailableWIP] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_GetBillAvailableWIP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_GetBillAvailableWIP].'
	drop procedure dbo.[biw_GetBillAvailableWIP]
end
print '**** Creating procedure dbo.[biw_GetBillAvailableWIP]...'
print ''
go

set QUOTED_IDENTIFIER on
go
set ANSI_NULLS on
go

create procedure dbo.[biw_GetBillAvailableWIP]
			@pnUserIdentityId		int,		-- Mandatory
			@psCulture			nvarchar(10) 	= null,
			@pbCalledFromCentura		bit		= 0,
			@pnItemEntityNo			int, -- Mandatory
			@pnItemTransNo			int = null,
			@psCaseKeyCSVList		nvarchar(max) = null,
			@pnDebtorKey			int = null, -- Debtor in Single Debtor and Debtor only bills
			@pnRaisedByStaffKey		int = null, -- Used to get the Tax Rate Country
			@pnItemType			int = null, -- The item type (510 / 511)
			@pdtItemDate			datetime = null,
			@psMergeXMLKeys			nvarchar(max) = null
as
-- PROCEDURE :	biw_GetBillAvailableWIP
-- VERSION :	63
-- DESCRIPTION:	A procedure that returns all of the selected and/or available wip for an OpenItem.
--
-- COPYRIGHT:	Copyright 1993 - 2012 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC		Version Description
-- -----------	-------	--------------	------- ----------------------------------------------- 
-- 19-Oct-2009	AT	RFC3605		1	Procedure created.
-- 04-May-2010	AT	RFC9092		2	Use Translations and return ReasonCode.
-- 14-May-2010	AT	RFC9092		3	Increase length of CaseKeyCSVList.
-- 21-Jun-2010	AT	RFC8291		4	Return WIP for Credit Notes.
-- 24-Jun-2010	MS	RFC7269		5	Added MarginFlag in select list
-- 28-Jul-2010	KR	RFC9080 	6	Added few sort columns
-- 06-Sep-2010	AT	RFC9740		7	Return Write down amount in same row as WIP Item.
-- 12-Oct-2010	KR	RFC9823		8	Added StaffSignOffName
-- 22-Oct-2010	AT	RFC8354		9	Return ForeignDecimalPlaces
-- 28-Oct-2010	MS	RFC7275		10	Added BillingDiscountFlag in select list
-- 03-Nov-2010	AT	RFC9907		11	Items duplicated on WIP Selection.
-- 04-Nov-2010	AT	RFC9780		12	Return discounts and standard WIP items for credit notes..
-- 08-Dec-2010	AT	RFC10036	13	Return null as variation for draft items
--						Reverse billed amount for non-draft credit wip
-- 21-Dec-2010	AT	RFC10042	14	Use debtor and item date to get actual tax code/rate.
-- 07-Jan-2011	AT	RFC8590		15	Return Prevent Write Down flag.
-- 02-Feb-2011  MS      RFC8297 		16      Change TABLETYPE to 50 from 44 for Source Country for Staff
-- 31 Mar 2011  LP      RFC8412		17      Return GeneratedFromTaxCode column (for stamp fees).
-- 29-Apr-2011	AT	RFC7956	18	Allow return of WIP from multiple bills. 
-- 04-May-2011	AT	RFC10555	19	Return 0 if billed item is null.
-- 24-May-2011	AT	RFC10696	20	Retrofitted return of finalised bill wip items.
-- 06-Jun-2011	AT	RFC10776	21	Undo change that includes WIP Variation in local billed amount on finalised items.
-- 06-Sep-2011	AT	RFC100582	22	Apply credit multipler to local/foreign variation 
-- 12-Sep-2011	AT	RFC10985	23	WIP Selection screen shows incorrect dates in finalised bills
-- 24-Oct-2011	AT	RFC10168	24	Remove Entity filter for inter-entity billing.
-- 02-Nov-2011	AT	RFC9451		25	Return Variable fee currency reason and Variable fee WIP Code.
-- 13-Dec-2011	KR	RFC10454	26	Added WriteDownPriority and WriteUpAllowed to the select
-- 21-Dec-2011	AT	RFC9160		27	Return Bill Exch Rate per WIP item.
-- 10-Jan-2012	AT	RFC10454	28	Fix return of WriteDownPriority to return priority sort instead of tablecode.
-- 10-Feb-2012	AT	RFC11910	29	Return exchange rate for every WIP item if it's a foreign bill.
-- 15-Mar-2012	AT	RFC12042	30	Fixed completely written off items not displaying in finalised bills.
-- 22-Mar-2012	AT	RFC12051	31	Fixed merged rows showing zero amount on finalised bill.
-- 02 May 2012	vql	RFC100635	32	Name Presentation not always used when displaying a name.
-- 14-May-2012	AT	RFC12149	33	Added logic for tax rates with source country.
-- 01-Jun-2012	AT	RFC12118	34	Fix return of bill in advance wip on finalised bills.
-- 12-Jun-2012	AT	RFC12149	35	Fix merged main case logic.
-- 13-Jun-2012	AT	RFC11594	36	Return IsHiddenOnDraft flag for stamp fees to be able to reconsolidate on a bill.
-- 04-Jul-2012	KR	RFC12395	37	Return availalbe WIP for the particular case when a case is passed not based on the transaction no.
-- 25-Jul-2012	AT	RFC11305	38	Return 0 for foreign balance for finalised bills.
-- 24-Aug-2012	AT	RFC12657	39	Fixed return of WIP items written off to zero.
-- 28-Aug-2012	AT	RFC12657	40	Fixed return of Debit WIP written off to zero on finalised bill.
-- 02-Oct-2012	AT	RFC12808	41	Fixed loading a bill with a large number of WIP items.
-- 17-Jan-2013	LP	RFC11614	42	Return ProfitCentre, WIPTypeDescription and WIPCategoryDescription in result set.
-- 11 Jul 2013	MF	RFC13654	43	Extend nvarchar(1000) field to nvarchar(max) to cater for large amount of WIP
-- 25 Jul 2013	KR	RFC13677	44	Extend the size of the WIP Description from 30 to 200 in the temp table AVAILABLEWIPRETURNTABLE
--									billed on large number of Cases.
-- 04 Sep 2013	vql	DR-145		45	Creating a bill for one debtor on a multi-debtor case.
-- 30 Oct 2013	SF	RFC24688	46	Return AcctClientNo 
-- 05 Feb 2014	KR	RFC13863	47	check @psCaseKeyCSVList for '' while checking for null
-- 15 Apr 2014	AT	RFC13863	48	Fixed erroneous quadruple quotes.
-- 29 Apr 2014	LP	R29312		49	Return ISADVANCEBILL flag when  
-- 01 May 2014	LP	R29312		50	Prevent credit WIP offset for BillInAdvance WIP from being displayed 
--						in draft bills where the BillInAdvance WIP was created.
-- 05 May 2014	LP	R13945		51	When 'WIP Split Multi Debtor' is ON, do not display Case WIP when viewing a debtor-only bill.
-- 12 May 2014	LP	R29312		52	Only filter credit WIP offset for BillInAdvance WIP when 'WIP Split Multi Debtor' is ON
--						Do not distinguish BillInAdvance WIP from other items on finalised bills.
-- 11 Sep 2014  SS	R39363		53	Modified the size of psCaseKeyCSVList to take as max.
-- 17 Oct 2014	SS	R40079		54	Modified the code to return DiscountDisconnected for the items where dicount is transferred
-- 09 Oct 2015	AT	R45612		55	Passed in item date overrides OPENITEM item date.
-- 20 Oct 2015  MS  R53933      56  Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols
-- 02 Nov 2015	vql	R53910		57	Adjust formatted names logic (DR-15543).
-- 02 Jan 2017	MS	R47798		58	Added FeeType and corresponding data in the result set
-- 11 Jul 2017  MS  R71176      59  Return exchange details for finalised bills as well

-- 24 Dec 2017	AK	R72645		60	Make compatible with case sensitive server with case insensitive database.

-- 15 Feb 2018	AK	R72937	    60	passed staffKey in fn_GetDefaultTaxCodeForWIP..

-- 13 Mar 2018	AK	R73612	    61	Applied check to validate tax code entered in TaxCodeEUBilling sitecontrol.
-- 04 Oct 2018  AK  R74005		62  passed @pnEntityKey in fn_GetDefaultTaxCodeForWIP and fn_GetEffectiveTaxRate 


set nocount on
Set CONCAT_NULL_YIELDS_NULL on

Declare	@nErrorCode		int
Declare		@nRowCount	int
Declare		@sSQLString	nvarchar(max)
Declare @sXMLJoin	nvarchar(1000)
Declare	@nStatus	int
Declare	@nCreditMultiplier	int
Declare	@bRestrictCredits bit
Declare @sSourceCountry		nvarchar(3)
Declare @bInterEntityBilling	bit
Declare @nMainCaseId		int
Declare @bWIPSplitMultiDebtor	bit

Declare @sWIPType nvarchar(6)
Declare @sWIPCategory nvarchar(2)
Declare @sWIPCurrency nvarchar(3)
Declare @nBuyRate	decimal(11,4)
Declare @nSellRate	decimal(11,4)
Declare @bIsEuTaxTreatmentSatisfied bit = 0
Declare @sEUTaxCode nvarchar(3)
Declare @sAlertXML nvarchar(2000)

Declare @sBillCurrency nvarchar(3)

Declare @XMLKeys	XML

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @nErrorCode = 0

if (@pnItemType in (511,514))
Begin
	Set @nCreditMultiplier = -1
End
Else
Begin
	Set @nCreditMultiplier = 1
End

If (@nErrorCode = 0)
Begin
	Create table #AVAILABLEWIPRETURNTABLE
	(CASEID INT NULL,
	IRN NVARCHAR(30) COLLATE DATABASE_DEFAULT,
	ENTITYNO INT,
	TRANSNO INT,
	WIPSEQNO INT,
	WIPCODE NVARCHAR(6) COLLATE DATABASE_DEFAULT,
	WIPTYPEID NVARCHAR(6) COLLATE DATABASE_DEFAULT,
	WIPTYPEDESCRIPTION NVARCHAR(50) COLLATE DATABASE_DEFAULT NULL,
	WIPCATEGORYCODE NVARCHAR(2) COLLATE DATABASE_DEFAULT,
	WIPCATEGORYDESCRIPTION NVARCHAR(50) COLLATE DATABASE_DEFAULT NULL,
	WIPDESCRIPTION NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
	RENEWALFLAG BIT,
	NARRATIVENO INT NULL,
	NARRATIVETEXT NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
	TRANSDATE DATETIME,
	PROFITCENTRECODE NVARCHAR(6) COLLATE DATABASE_DEFAULT NULL,
	PROFITCENTRE NVARCHAR(50) COLLATE DATABASE_DEFAULT NULL,
	TOTALTIME DATETIME NULL,
	TOTALUNITS INT NULL,
	UNITSPERHOUR INT NULL,
	CHARGEOUTRATE DECIMAL(11,2) NULL,
	VARIABLEFEEAMT DECIMAL(11,2) NULL,
	VARIABLEFEETYPE INT NULL,
	VARIABLEFEECURR NVARCHAR(3) COLLATE DATABASE_DEFAULT NULL,
	WRITEUPREASON NVARCHAR(2) COLLATE DATABASE_DEFAULT NULL,
	VARWIPCODE NVARCHAR(6) COLLATE DATABASE_DEFAULT NULL,
	FEECRITERIANO INT NULL,
	FEEUNIQUEID INT NULL,
	BALANCE DECIMAL(11,2) NULL,
	LOCALBILLED DECIMAL(11,2) null,
	FOREIGNBALANCE DECIMAL(11,2) NULL,
	FOREIGNCURRENCY  NVARCHAR(3) COLLATE DATABASE_DEFAULT,
	FOREIGNDECIMALPLACES INT NULL,
	FOREIGNBILLED DECIMAL(11,2) null,
	STATUS INT,
	TAXCODE NVARCHAR(3) COLLATE DATABASE_DEFAULT NULL,
	TAXDESCRIPTION NVARCHAR(30) COLLATE DATABASE_DEFAULT NULL,
	TAXRATE DECIMAL(11,4) NULL,
	STATETAXCODE  NVARCHAR(3) COLLATE DATABASE_DEFAULT NULL,
	STAFFNAME NVARCHAR(500) COLLATE DATABASE_DEFAULT,
	SIGNOFFNAME NVARCHAR(50) COLLATE DATABASE_DEFAULT NULL,
	EMPLOYEENO INT,
	DISCOUNTFLAG BIT,
	COSTCALCULATION1 DECIMAL(11,2) NULL,
	COSTCALCULATION2 DECIMAL(11,2) NULL,
	MARGINNO INT NULL,
	CATEGORYSORT INT NULL,
	BILLLINENO INT NULL,
	REASONCODE NVARCHAR(3) COLLATE DATABASE_DEFAULT,
	MARGINFLAG BIT,
	RATENOSORT INT NULL,
	WIPTYPESORT smallint NULL,
	WIPCODESORT smallint NULL,
	TITLE NVARCHAR(256) COLLATE DATABASE_DEFAULT NULL,
	LOCALVARIATION DECIMAL(11,2) NULL,
	FOREIGNVARIATION DECIMAL(11,2) NULL,
	BILLINGDISCOUNTFLAG BIT NULL,
	PREVENTWRITEDOWNFLAG BIT NULL,
	GENERATEDFROMTAXCODE nvarchar(3) COLLATE DATABASE_DEFAULT NULL, 
	BILLITEMENTITYNO INT NULL,
	BILLITEMTRANSNO INT NULL,
	WRITEDOWNPRIORITY INT NULL, -- Priority of write down (RFC10454)
	WRITEUPALLOWED BIT,	-- Is write up allowed?
	WIPBUYRATE	decimal(11,4),
	WIPSELLRATE	decimal(11,4),
	BILLBUYRATE decimal(11,4),
	BILLSELLRATE decimal(11,4),
	ISHIDDENFORDRAFT BIT NULL,
	ACCTCLIENTNO INT NULL,
	ISADVANCEBILL BIT NULL,
	ISDISCOUNTDISCONNECTED BIT NULL,
	ISFEETYPE BIT NULL
	)
End


-- Get inter-entity billing flag
If exists (select * from SITECONTROL WHERE CONTROLID = 'Inter-Entity Billing')
Begin
	Set @sSQLString = 'select @bInterEntityBilling = isnull(COLBOOLEAN,0)
	FROM SITECONTROL
	WHERE CONTROLID = ''Inter-Entity Billing'''
			
	exec @nErrorCode = sp_executesql @sSQLString,
				N'@bInterEntityBilling bit output',
				@bInterEntityBilling = @bInterEntityBilling output
End

-- Get WIP Split Multi Debtor Site Control
If @nErrorCode = 0
Begin
	Select @bWIPSplitMultiDebtor = ISNULL(COLBOOLEAN,0)
	from SITECONTROL
	where CONTROLID = 'WIP Split Multi Debtor'
End


if @psMergeXMLKeys is not null
Begin
	Set @XMLKeys = cast(@psMergeXMLKeys as XML)

	Set @sXMLJoin = char(10) + 'JOIN (
	select	K.value(N''ItemEntityNo[1]'',N''int'') as ItemEntityNo,
		K.value(N''ItemTransNo[1]'',N''int'') as ItemTransNo
	from @XMLKeys.nodes(N''/Keys/Key'') KEYS(K)
		) as XM on (XM.ItemEntityNo = BI.ITEMENTITYNO
			and XM.ItemTransNo = BI.ITEMTRANSNO)'
End

if (@pnItemTransNo is not null)
Begin
	-- Get the status of the bill
	Select @nStatus = [STATUS],
	@pnRaisedByStaffKey = EMPLOYEENO,
	@pdtItemDate = isnull(@pdtItemDate,ITEMDATE),
	@nMainCaseId = MAINCASEID
	From OPENITEM
	Where ITEMENTITYNO = @pnItemEntityNo
	and ITEMTRANSNO = @pnItemTransNo

	If (@psCaseKeyCSVList is null or @psCaseKeyCSVList = '')
	Begin
		--Get the cases (concatenate blank strings because concat_null_yields_null is on)
		Set @sSQLString = 'Select @psCaseKeyCSVList = isnull(@psCaseKeyCSVList, '''') + Case when (@psCaseKeyCSVList is not null and @psCaseKeyCSVList != '''')  then '','' else '''' end + cast(CASEID as nvarchar(12))
		FROM
			(select distinct WIP.CASEID
			From BILLEDITEM BI 
			Join WORKINPROGRESS WIP on (WIP.ENTITYNO = BI.WIPENTITYNO
						and WIP.TRANSNO = BI.WIPTRANSNO
						and WIP.WIPSEQNO = BI.WIPSEQNO)'
						
			if @sXMLJoin is not null
			Begin
				-- JOIN to the XML Keys
				Set @sSQLString = @sSQLString + char(10) + @sXMLJoin +
				char(10) + 'Where WIP.CASEID IS NOT NULL'
			End
			Else
			Begin
				Set @sSQLString = @sSQLString + char(10) + 'Where  BI.ITEMENTITYNO = @pnItemEntityNo
			and BI.ITEMTRANSNO = @pnItemTransNo
				and WIP.CASEID IS NOT NULL'
			End
			
			Set @sSQLString = @sSQLString + ') AS CASEIDS'
			
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnItemTransNo	int,
				  @pnItemEntityNo	int,
				  @psCaseKeyCSVList nvarchar(max) OUTPUT,
				  @XMLKeys		xml',
				  @pnItemTransNo=@pnItemTransNo,
				  @pnItemEntityNo=@pnItemEntityNo,
				  @psCaseKeyCSVList = @psCaseKeyCSVList OUTPUT,
				  @XMLKeys = @XMLKeys
		
	End

	-- Get the debtor if single debtor bill.
	if exists (select ITEMTRANSNO
			from OPENITEM
			Where  ITEMENTITYNO = @pnItemEntityNo
			and ITEMTRANSNO = @pnItemTransNo
			GROUP BY ITEMTRANSNO
			HAVING COUNT(*) = 1)
	Begin
		Set @sSQLString = 'Select @pnDebtorKey = ACCTDEBTORNO
			From OPENITEM
			Where  ITEMENTITYNO = @pnItemEntityNo
			and ITEMTRANSNO = @pnItemTransNo'

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnItemTransNo	int,
				  @pnItemEntityNo	int,
				  @pnDebtorKey int OUTPUT',
				  @pnItemTransNo=@pnItemTransNo,
				  @pnItemEntityNo=@pnItemEntityNo,
				  @pnDebtorKey = @pnDebtorKey OUTPUT
	End
End

If (@nErrorCode = 0)
Begin
	Select @sSourceCountry = dbo.fn_GetSourceCountry(@pnRaisedByStaffKey, @nMainCaseId)
End

If (@nErrorCode = 0 and @psCaseKeyCSVList is not null and @nMainCaseId is null)
Begin
	-- Get the Main Case Key for derivation of exchange rates per WIP item.
	Set @sSQLString = 'select @nMainCaseId = Parameter
		from dbo.fn_Tokenise(@psCaseKeyCSVList, '','')
		where InsertOrder = 1'
	
	exec @nErrorCode=sp_executesql @sSQLString,
		N'@psCaseKeyCSVList	nvarchar(max) output,
		  @nMainCaseId	int',
		  @psCaseKeyCSVList=@psCaseKeyCSVList output,
		  @nMainCaseId=@nMainCaseId
End
		
If (@nErrorCode = 0 and @pnDebtorKey is not null and @pnRaisedByStaffKey is not null)
Begin
	
	Set @sSQLString = 'Select @bIsEuTaxTreatmentSatisfied = dbo.fn_HasDebtorSatisfyEUBilling(@pnDebtorKey, @pnRaisedByStaffKey,@pnItemEntityNo)'
	
	exec @nErrorCode=sp_executesql @sSQLString,
		N'@bIsEuTaxTreatmentSatisfied	bit output,
		  @pnDebtorKey	int,
		  @pnItemEntityNo int,
		  @pnRaisedByStaffKey int',
		  @bIsEuTaxTreatmentSatisfied	= @bIsEuTaxTreatmentSatisfied output,
		  @pnDebtorKey	=	@pnDebtorKey,
		  @pnItemEntityNo = @pnItemEntityNo,
		  @pnRaisedByStaffKey = @pnRaisedByStaffKey

	If (@nErrorCode = 0 and @bIsEuTaxTreatmentSatisfied = 1)
	Begin
			Select @sEUTaxCode=COLCHARACTER
			from	SITECONTROL
			where	CONTROLID = 'Tax Code for EU billing'
			Set @nErrorCode = @@ERROR

			If @nErrorCode = 0 and Not Exists (SELECT TAXCODE FROM TAXRATES WHERE TAXCODE = @sEUTaxCode)
			Begin
				Set @sAlertXML = dbo.fn_GetAlertXML('AC154', 'The Tax Code specified in the ''Tax Code for EU billing'' site control is invalid. Contact your System Administrator to get the site control updated.',
												null, null, null, null, null)
				RAISERROR(@sAlertXML, 14, 1)
				Set @nErrorCode = @@ERROR
			End
	End

End


-- Get AvailableWIP
If @nErrorCode = 0
Begin
If (@nStatus is null or @nStatus = 0)
Begin
-- New bill - Return Available WIP only
		Set @sSQLString = '
			insert into #AVAILABLEWIPRETURNTABLE (CASEID, IRN, ENTITYNO, TRANSNO, WIPSEQNO, WIPCODE, WIPTYPEID, WIPTYPEDESCRIPTION, WIPCATEGORYCODE, WIPCATEGORYDESCRIPTION, WIPDESCRIPTION, RENEWALFLAG, 
			NARRATIVENO, NARRATIVETEXT, TRANSDATE, PROFITCENTRECODE, PROFITCENTRE, TOTALTIME, TOTALUNITS, UNITSPERHOUR, CHARGEOUTRATE, 
			VARIABLEFEEAMT, VARIABLEFEETYPE, VARIABLEFEECURR, WRITEUPREASON, VARWIPCODE, 
			FEECRITERIANO, FEEUNIQUEID, 
			BALANCE, LOCALBILLED, FOREIGNBALANCE, FOREIGNCURRENCY, FOREIGNDECIMALPLACES, FOREIGNBILLED, STATUS, 
			TAXCODE, TAXDESCRIPTION, TAXRATE, STATETAXCODE, STAFFNAME, SIGNOFFNAME, EMPLOYEENO, DISCOUNTFLAG, COSTCALCULATION1, COSTCALCULATION2, 
			MARGINNO, CATEGORYSORT, BILLLINENO, REASONCODE, MARGINFLAG, RATENOSORT, WIPTYPESORT, WIPCODESORT, TITLE, LOCALVARIATION, FOREIGNVARIATION, 
			BILLINGDISCOUNTFLAG, PREVENTWRITEDOWNFLAG, GENERATEDFROMTAXCODE, BILLITEMENTITYNO, BILLITEMTRANSNO, WRITEDOWNPRIORITY, WRITEUPALLOWED,
			ISHIDDENFORDRAFT,ACCTCLIENTNO, ISADVANCEBILL, ISFEETYPE)
			Select
			C.CASEID,
			C.IRN,
			WIP.ENTITYNO,
			WIP.TRANSNO,
			WIP.WIPSEQNO,
			WIP.WIPCODE,

			WT.WIPTYPEID,
			' + dbo.fn_SqlTranslatedColumn('WIPTYPE','DESCRIPTION',null,'WTP',@sLookupCulture,@pbCalledFromCentura) + ',
			WTP.CATEGORYCODE,
			' + dbo.fn_SqlTranslatedColumn('WIPCATEGORY','DESCRIPTION',null,'WC',@sLookupCulture,@pbCalledFromCentura) + ',
			' + dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'WT',@sLookupCulture,@pbCalledFromCentura) + ',
			WT.RENEWALFLAG,
			WIP.NARRATIVENO,
			' + dbo.fn_SqlTranslatedColumn('WORKINPROGRESS','SHORTNARRATIVE','LONGNARRATIVE','WIP',@sLookupCulture,@pbCalledFromCentura) + ',
			WIP.TRANSDATE,
			WIP.EMPPROFITCENTRE,
			' + dbo.fn_SqlTranslatedColumn('PROFITCENTRE','DESCRIPTION',null,'PC',@sLookupCulture,@pbCalledFromCentura) + ',
			WIP.TOTALTIME,
			WIP.TOTALUNITS,
			WIP.UNITSPERHOUR,
			WIP.CHARGEOUTRATE,
			WIP.VARIABLEFEEAMT,
			WIP.VARIABLEFEETYPE,
			WIP.VARIABLEFEECURR,
			
			FCA.WRITEUPREASON,
			FCA.VARWIPCODE,
			
			WIP.FEECRITERIANO,
			WIP.FEEUNIQUEID,
				WIP.BALANCE * @nCreditMultiplier,
			null,
				WIP.FOREIGNBALANCE * @nCreditMultiplier,
			WIP.FOREIGNCURRENCY ,
				isnull(FC.DECIMALPLACES,2),
			null,
			WIP.STATUS,
			TR.TAXCODE,
			' + dbo.fn_SqlTranslatedColumn('TAXRATES','DESCRIPTION',null,'TR',@sLookupCulture,@pbCalledFromCentura) + ',
			dbo.fn_GetEffectiveTaxRate(TR.TAXCODE, @sSourceCountry, @pdtItemDate, @pnItemEntityNo),
			WT.STATETAXCODE ,

			dbo.fn_FormatNameUsingNameNo(STAFF.NAMENO, COALESCE(STAFF.NAMESTYLE, STAFFCT.NAMESTYLE, 7101)) as "StaffName",
			E.SIGNOFFNAME,
			WIP.EMPLOYEENO,
			WIP.DISCOUNTFLAG,
			WIP.COSTCALCULATION1,
			WIP.COSTCALCULATION2,
			WIP.MARGINNO,
			WC.CATEGORYSORT,
			null,
			null,
			WIP.MARGINFLAG	as ''MarginFlag'',
			R.RATENOSORT,
			WTP.WIPTYPESORT,
			WT.WIPCODESORT,
			C.TITLE,
		null	as ''LocalVariation'',
		null	as ''ForeignVariation'',
        		WIP.BILLINGDISCOUNTFLAG,
			WT.PREVENTWRITEDOWNFLAG,
			null,
			null,
			null,
			CASE	WHEN isnumeric(WDP.DESCRIPTION) = 1 THEN CAST(WDP.DESCRIPTION AS INT)
				WHEN isnumeric(WDP.USERCODE) = 1 THEN CAST(WDP.USERCODE AS INT)
				ELSE NULL
				END,
			isnull(WTP.WRITEUPALLOWED, 0),
                null,
			WIP.ACCTCLIENTNO,
			WIP.GENERATEDINADVANCE,
			WIP.ADDTOFEELIST
		From WORKINPROGRESS WIP
		Join WIPTEMPLATE WT on (WIP.WIPCODE = WT.WIPCODE)
		Join WIPTYPE WTP on (WT.WIPTYPEID = WTP.WIPTYPEID)
		Join WIPCATEGORY WC on (WC.CATEGORYCODE = WTP.CATEGORYCODE)
		Left Join CASES C on (WIP.CASEID = C.CASEID)
		Left Join NAME STAFF on (WIP.EMPLOYEENO = STAFF.NAMENO)
		Left Join EMPLOYEE E on (E.EMPLOYEENO = WIP.EMPLOYEENO)
		Left Join TAXRATES TR on (TR.TAXCODE = dbo.fn_GetDefaultTaxCodeForWIP(WIP.CASEID, WIP.WIPCODE, @pnDebtorKey, @pnRaisedByStaffKey, @pnItemEntityNo))
		LEFT JOIN RATES R ON (WIP.RATENO = R.RATENO)
			Left Join CURRENCY FC ON (WIP.FOREIGNCURRENCY = FC.CURRENCY)
		left join COUNTRY STAFFCT on (STAFFCT.COUNTRY=STAFF.NATIONALITY)
		Left Join FEESCALCULATION FCA ON (FCA.CRITERIANO = WIP.FEECRITERIANO 
						and FCA.UNIQUEID = WIP.FEEUNIQUEID
						and FCA.VARFEEAPPLIES = 1)
			Left Join (SELECT TABLECODE, DESCRIPTION, USERCODE
					FROM TABLECODES
					WHERE TABLETYPE = 155) as WDP on (WDP.TABLECODE = WTP.WRITEDOWNPRIORITY)
		left join PROFITCENTRE PC on (PC.PROFITCENTRECODE = WIP.EMPPROFITCENTRE)
		Where WIP.STATUS = 1'
		
		if (@bInterEntityBilling != 1)
		Begin
			Set @sSQLString = @sSQLString + char(10) + 'and ISNULL(WIP.ACCTENTITYNO,WIP.ENTITYNO) = @pnItemEntityNo'
		End


		-- when wipsplit SC ON return split case wip for specified debtor and case only WIP
		If (@bWIPSplitMultiDebtor = 1)
		Begin
			If (nullif(@psCaseKeyCSVList,'') is not null)
			Begin
				-- Return Case WIP that is Debtor Allocated to @pnDebtorKey or Unallocated
				Set @sSQLString = @sSQLString + char(10) + 'and C.CASEID in (' + cast(@psCaseKeyCSVList as nvarchar(max)) + ') ' +
				'and (WIP.ACCTCLIENTNO = @pnDebtorKey or WIP.ACCTCLIENTNO is null)'
			End 
			Else If (@pnDebtorKey is not null)
			Begin
				-- Return Debtor-only WIP only
				Set @sSQLString = @sSQLString + char(10) + 'and WIP.ACCTCLIENTNO = @pnDebtorKey and WIP.CASEID IS NULL'
			End
		End
		Else
		Begin
			-- return available wip
			If (@psCaseKeyCSVList is not null and @psCaseKeyCSVList != '')
			Begin			
				-- Get WIP for a case bill
				Set @sSQLString = @sSQLString + char(10) + 'and C.CASEID in (' + cast(@psCaseKeyCSVList as nvarchar(max)) + ')'
			End
			Else If (@pnDebtorKey is not null)
			Begin
				-- Get WIP For debtor only bill
				Set @sSQLString = @sSQLString + char(10) + 'and WIP.ACCTCLIENTNO = @pnDebtorKey'
			End
		End
	End

If (@nStatus = 0 or @nStatus = 9)
Begin
-- Return Selected WIP
	If (@nStatus = 0)
	Begin
		Set @sSQLString = @sSQLString + char(10) + 'UNION' + char(10)
	End

	Set @sSQLString = @sSQLString + char(10) + '
		Select
			C.CASEID,
			C.IRN,
			WIP.ENTITYNO,
			WIP.TRANSNO,
			WIP.WIPSEQNO,
			WIP.WIPCODE,

			WT.WIPTYPEID,
			' + dbo.fn_SqlTranslatedColumn('WIPTYPE','DESCRIPTION',null,'WTP',@sLookupCulture,@pbCalledFromCentura) + ',
			WTP.CATEGORYCODE,
			' + dbo.fn_SqlTranslatedColumn('WIPCATEGORY','DESCRIPTION',null,'WC',@sLookupCulture,@pbCalledFromCentura) + ',
			' + dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'WT',@sLookupCulture,@pbCalledFromCentura) + ',
			WT.RENEWALFLAG,
			WIP.NARRATIVENO,
					' + dbo.fn_SqlTranslatedColumn('WORKINPROGRESS','SHORTNARRATIVE','LONGNARRATIVE','WIP',@sLookupCulture,@pbCalledFromCentura) + ',
			WIP.TRANSDATE,
			WIP.EMPPROFITCENTRE,
			' + dbo.fn_SqlTranslatedColumn('PROFITCENTRE','DESCRIPTION',null,'PC',@sLookupCulture,@pbCalledFromCentura) + ',
			WIP.TOTALTIME,
			WIP.TOTALUNITS,
			WIP.UNITSPERHOUR,
			WIP.CHARGEOUTRATE,
			WIP.VARIABLEFEEAMT,
			WIP.VARIABLEFEETYPE,
			WIP.VARIABLEFEECURR,
			
			FCA.WRITEUPREASON,
			FCA.VARWIPCODE,
			
			WIP.FEECRITERIANO,
			WIP.FEEUNIQUEID,
			Case When WIP.STATUS = 0 then 1 else @nCreditMultiplier END * ISNULL(WIP.BALANCE, 0),
			Case When WIP.STATUS = 0 then 1 else @nCreditMultiplier END * BI.BILLEDVALUE,
			Case When WIP.STATUS = 0 then 1 else @nCreditMultiplier END * WIP.FOREIGNBALANCE,
			BI.FOREIGNCURRENCY ,
				isnull(FC.DECIMALPLACES,2),
			Case When WIP.STATUS = 0 then 1 else @nCreditMultiplier END * BI.FOREIGNBILLEDVALUE,
			WIP.STATUS,
			TR.TAXCODE,
			' + dbo.fn_SqlTranslatedColumn('TAXRATES','DESCRIPTION',null,'TR',@sLookupCulture,@pbCalledFromCentura) + ',
			dbo.fn_GetEffectiveTaxRate(TR.TAXCODE, @sSourceCountry, @pdtItemDate, @pnItemEntityNo),
			WT.STATETAXCODE ,
			dbo.fn_FormatNameUsingNameNo(STAFF.NAMENO, COALESCE(STAFF.NAMESTYLE, STAFFCT.NAMESTYLE, 7101)) as "StaffName",
			E.SIGNOFFNAME,
			WIP.EMPLOYEENO,
			WIP.DISCOUNTFLAG,
			WIP.COSTCALCULATION1,
			WIP.COSTCALCULATION2,
			WIP.MARGINNO,
			WC.CATEGORYSORT,
			BI.ITEMLINENO,
				BI.REASONCODE,
				WIP.MARGINFLAG	as ''MarginFlag'',
				R.RATENOSORT,
				WTP.WIPTYPESORT,
				WT.WIPCODESORT,
				C.TITLE,
			Case When WIP.STATUS = 0 THEN NULL ELSE @nCreditMultiplier * BI.ADJUSTEDVALUE END,
			Case When WIP.STATUS = 0 THEN NULL ELSE @nCreditMultiplier * BI.FOREIGNADJUSTEDVALUE END,
                        			WIP.BILLINGDISCOUNTFLAG,
			WT.PREVENTWRITEDOWNFLAG,
			BI.GENERATEDFROMTAXCODE,
			BI.ITEMENTITYNO,
			BI.ITEMTRANSNO,
			CASE	WHEN isnumeric(WDP.DESCRIPTION) = 1 THEN CAST(WDP.DESCRIPTION AS INT)
				WHEN isnumeric(WDP.USERCODE) = 1 THEN CAST(WDP.USERCODE AS INT)
				ELSE NULL
				END,
			isnull(WTP.WRITEUPALLOWED, 0),
                BL.ISHIDDENFORDRAFT,
             BI.ACCTDEBTORNO,
		WIP.GENERATEDINADVANCE,
		WIP.ADDTOFEELIST
		From BILLEDITEM BI
		LEFT JOIN BILLLINE BL ON BI.ITEMENTITYNO = BL.ITEMENTITYNO
				AND BI.ITEMTRANSNO = BL.ITEMTRANSNO
				AND BL.ITEMLINENO = BI.ITEMLINENO
		Join WORKINPROGRESS WIP on (WIP.TRANSNO = BI.WIPTRANSNO
					and WIP.ENTITYNO = BI.WIPENTITYNO
					and WIP.WIPSEQNO = BI.WIPSEQNO)
		Join WIPTEMPLATE WT on (WIP.WIPCODE = WT.WIPCODE)
		Join WIPTYPE WTP on (WT.WIPTYPEID = WTP.WIPTYPEID)
		Join WIPCATEGORY WC on (WC.CATEGORYCODE = WTP.CATEGORYCODE)
		Left Join CASES C on (WIP.CASEID = C.CASEID)
		Left Join NAME STAFF on (WIP.EMPLOYEENO = STAFF.NAMENO)
		left join COUNTRY STAFFCT on (STAFFCT.COUNTRY=STAFF.NATIONALITY)
		Left Join EMPLOYEE E on (E.EMPLOYEENO = WIP.EMPLOYEENO)
		Left Join TAXRATES TR on (TR.TAXCODE = dbo.fn_GetDefaultTaxCodeForWIP(WIP.CASEID, WIP.WIPCODE, @pnDebtorKey, @pnRaisedByStaffKey, @pnItemEntityNo))
		LEFT JOIN RATES R ON (WIP.RATENO = R.RATENO)
		Left Join CURRENCY FC ON (FC.CURRENCY = BI.FOREIGNCURRENCY)
		Left Join FEESCALCULATION FCA ON (FCA.CRITERIANO = WIP.FEECRITERIANO 
						and FCA.UNIQUEID = WIP.FEEUNIQUEID
							and FCA.VARFEEAPPLIES = 1)
			Left Join (SELECT TABLECODE, DESCRIPTION, USERCODE
					FROM TABLECODES
					WHERE TABLETYPE = 155) as WDP on (WDP.TABLECODE = WTP.WRITEDOWNPRIORITY)
		Left Join PROFITCENTRE PC on (PC.PROFITCENTRECODE = WIP.EMPPROFITCENTRE)'
			
		if @sXMLJoin is not null
		Begin
			-- JOIN to the XML Keys
			-- Don't return stamp fees because it will be regenerated.
			Set @sSQLString = @sSQLString + char(10) + @sXMLJoin 
						+ char(10) + 'WHERE BI.GENERATEDFROMTAXCODE IS NULL'
		End
		Else
		Begin
			Set @sSQLString = @sSQLString + char(10) + 'Where BI.ITEMENTITYNO = @pnItemEntityNo
			and BI.ITEMTRANSNO = @pnItemTransNo'
			
			If (@psCaseKeyCSVList is not null and @psCaseKeyCSVList != '')
			Begin				
				-- Get WIP for a case bill
				Set @sSQLString = @sSQLString + char(10) + 'and C.CASEID in (' + cast(@psCaseKeyCSVList as nvarchar(max)) + ')'
			End
			
			Set @sSQLString = @sSQLString + ' order by 55' -- Show stamp fees at the bottom
		End
End		
		
If (@nStatus = 1)
Begin
	-- Get billed wip only from WorkHistory.
	
		Set @sSQLString = 'insert into #AVAILABLEWIPRETURNTABLE (CASEID, IRN, ENTITYNO, TRANSNO, WIPSEQNO, WIPCODE, WIPTYPEID, WIPTYPEDESCRIPTION, WIPCATEGORYCODE, WIPCATEGORYDESCRIPTION, WIPDESCRIPTION, RENEWALFLAG, 
			NARRATIVENO, NARRATIVETEXT, TRANSDATE, PROFITCENTRECODE, PROFITCENTRE, TOTALTIME, TOTALUNITS, UNITSPERHOUR, CHARGEOUTRATE, 
			VARIABLEFEEAMT, VARIABLEFEETYPE, VARIABLEFEECURR, WRITEUPREASON, VARWIPCODE, 
			FEECRITERIANO, FEEUNIQUEID, 
			BALANCE, LOCALBILLED, FOREIGNBALANCE, FOREIGNCURRENCY, FOREIGNDECIMALPLACES, FOREIGNBILLED, STATUS, 
			TAXCODE, TAXDESCRIPTION, TAXRATE, STATETAXCODE, STAFFNAME, SIGNOFFNAME, EMPLOYEENO, DISCOUNTFLAG, COSTCALCULATION1, COSTCALCULATION2, 
			MARGINNO, CATEGORYSORT, BILLLINENO, REASONCODE, MARGINFLAG, RATENOSORT, WIPTYPESORT, WIPCODESORT, TITLE, LOCALVARIATION, FOREIGNVARIATION, 
			BILLINGDISCOUNTFLAG, PREVENTWRITEDOWNFLAG, GENERATEDFROMTAXCODE, BILLITEMENTITYNO, BILLITEMTRANSNO, WRITEDOWNPRIORITY, WRITEUPALLOWED,
			ISHIDDENFORDRAFT, ACCTCLIENTNO, ISADVANCEBILL)
		Select
		C.CASEID,
		C.IRN,
		WIP.ENTITYNO,
		WIP.TRANSNO,
		WIP.WIPSEQNO,
		WIP.WIPCODE,
		WT.WIPTYPEID,
		' + dbo.fn_SqlTranslatedColumn('WIPTYPE','DESCRIPTION',null,'WTP',@sLookupCulture,@pbCalledFromCentura) + ',
		WTP.CATEGORYCODE,
		' + dbo.fn_SqlTranslatedColumn('WIPCATEGORY','DESCRIPTION',null,'WC',@sLookupCulture,@pbCalledFromCentura) + ',
		' + dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'WT',@sLookupCulture,@pbCalledFromCentura) + ',
		WT.RENEWALFLAG,
		WIP.NARRATIVENO,
		' + dbo.fn_SqlTranslatedColumn('WORKINPROGRESS','SHORTNARRATIVE','LONGNARRATIVE','WIP',@sLookupCulture,@pbCalledFromCentura) + ',
		WO.TRANSDATE,
		WIP.EMPPROFITCENTRE,
		' + dbo.fn_SqlTranslatedColumn('PROFITCENTRE','DESCRIPTION',null,'PC',@sLookupCulture,@pbCalledFromCentura) + ',
		WIP.TOTALTIME,
		WIP.TOTALUNITS,
		WIP.UNITSPERHOUR,
		WIP.CHARGEOUTRATE,
		WIP.VARIABLEFEEAMT,
		WIP.VARIABLEFEETYPE,
		WIP.VARIABLEFEECURR,
		FCA.WRITEUPREASON,
		FCA.VARWIPCODE,
		WIP.FEECRITERIANO,
		WIP.FEEUNIQUEID,
		CAST(0 as decimal(11,2)),
		(WIP.LOCALTRANSVALUE * -1 * @nCreditMultiplier) +
			CASE WHEN WIP.HISTORYLINENO = WIP1.HISTORYLINENO 
			THEN (isnull(WIP1.LOCALVARIATION,0) * @nCreditMultiplier) 
			ELSE 0 END,
		NULL,
		WIP.FOREIGNCURRENCY ,
		isnull(FC.DECIMALPLACES,2),
		(WIP.FOREIGNTRANVALUE * -1 * @nCreditMultiplier) +
			CASE WHEN WIP.HISTORYLINENO = WIP1.HISTORYLINENO 
			THEN (isnull(WIP1.FOREIGNVARIATION,0) * @nCreditMultiplier) 
			ELSE 0 END,
		WIP.STATUS,
		WT.TAXCODE,
		' + dbo.fn_SqlTranslatedColumn('TAXRATES','DESCRIPTION',null,'TR',@sLookupCulture,@pbCalledFromCentura) + ',
		dbo.fn_GetEffectiveTaxRate(TR.TAXCODE, @sSourceCountry, @pdtItemDate,@pnItemEntityNo),
		WT.STATETAXCODE ,
		dbo.fn_FormatNameUsingNameNo(STAFF.NAMENO, COALESCE(STAFF.NAMESTYLE, STAFFCT.NAMESTYLE, 7101)) as "StaffName",
		E.SIGNOFFNAME,
		WIP.EMPLOYEENO,
		WIP.DISCOUNTFLAG,
		WIP.COSTCALCULATION1,
		WIP.COSTCALCULATION2,
		WIP.MARGINNO,
		WC.CATEGORYSORT,
		WIP.BILLLINENO,
		WIP1.REASONCODE,
		WIP.MARGINFLAG,
		R.RATENOSORT,
		WTP.WIPTYPESORT,
		WT.WIPCODESORT,
		C.TITLE,
		WIP1.LOCALVARIATION * @nCreditMultiplier,
		WIP1.FOREIGNVARIATION * @nCreditMultiplier,
                NULL,
		WT.PREVENTWRITEDOWNFLAG,		
		null,
		WIP.REFENTITYNO,
		WIP.REFTRANSNO,                
		NULL,
		isnull(WTP.WRITEUPALLOWED, 0),
                null,
		WIP.ACCTCLIENTNO, 
		0    
		From WORKHISTORY WIP
		JOIN WORKHISTORY WO on (WO.ENTITYNO = WIP.ENTITYNO
						AND WO.TRANSNO = WIP.TRANSNO
						AND WO.WIPSEQNO = WIP.WIPSEQNO
						AND WO.ITEMIMPACT = 1)
		Join WIPTEMPLATE WT on (WIP.WIPCODE = WT.WIPCODE)
		Join WIPTYPE WTP on (WT.WIPTYPEID = WTP.WIPTYPEID)
		Join WIPCATEGORY WC on (WC.CATEGORYCODE = WTP.CATEGORYCODE)
		left Join (SELECT LOCALTRANSVALUE AS LOCALVARIATION, FOREIGNTRANVALUE as FOREIGNVARIATION, REFENTITYNO, REFTRANSNO, ENTITYNO, TRANSNO, WIPSEQNO, HISTORYLINENO, REASONCODE, MOVEMENTCLASS
					FROM WORKHISTORY 
					WHERE BILLLINENO IS NOT NULL
					AND MOVEMENTCLASS IN (3,9)) as WIP1 ON 
								(WIP1.REFENTITYNO = WIP.REFENTITYNO
								and WIP1.REFTRANSNO = WIP.REFTRANSNO
								and WIP1.ENTITYNO = WIP.ENTITYNO 
								and WIP1.TRANSNO = WIP.TRANSNO
								and WIP1.WIPSEQNO = WIP.WIPSEQNO)
			Left Join CASES C on (WIP.CASEID = C.CASEID)
			Left Join NAME STAFF on (WIP.EMPLOYEENO = STAFF.NAMENO)
			LEFT JOIN RATES R ON (WIP.RATENO = R.RATENO)
			Left Join EMPLOYEE E on (E.EMPLOYEENO = WIP.EMPLOYEENO)
		Left Join TAXRATES TR on (TR.TAXCODE = dbo.fn_GetDefaultTaxCodeForWIP(WIP.CASEID, WIP.WIPCODE, @pnDebtorKey, @pnRaisedByStaffKey, @pnItemEntityNo))
			Left Join CURRENCY FC on (FC.CURRENCY = WIP.FOREIGNCURRENCY)
		left join COUNTRY STAFFCT on (STAFFCT.COUNTRY=STAFF.NATIONALITY)		
		Left Join FEESCALCULATION FCA ON (FCA.CRITERIANO = WIP.FEECRITERIANO 
						and FCA.UNIQUEID = WIP.FEEUNIQUEID
						and FCA.VARFEEAPPLIES = 1)
		Left Join PROFITCENTRE PC on (PC.PROFITCENTRECODE = WIP.EMPPROFITCENTRE)
		WHERE WIP.REFENTITYNO = @pnItemEntityNo
		and WIP.REFTRANSNO = @pnItemTransNo 
		AND (WIP.MOVEMENTCLASS = 2 -- BILLED
			-- INCLUDE COMPLETELY WRITTEN OFF ITEMS
			OR ((WIP.MOVEMENTCLASS = 3 or WIP.MOVEMENTCLASS = 9)
				AND NOT EXISTS (SELECT * FROM WORKHISTORY WHX 
						WHERE WHX.TRANSNO = WIP.TRANSNO 
						AND WHX.ENTITYNO = WIP.ENTITYNO
						AND WHX.WIPSEQNO = WIP.WIPSEQNO
						AND WHX.REFENTITYNO = @pnItemEntityNo
						AND WHX.REFTRANSNO = @pnItemTransNo 
						AND WHX.MOVEMENTCLASS = 2)
			)
		)
		AND WIP.TRANSTYPE != 600'
		
End

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnItemTransNo	int,
				  @pnItemEntityNo	int,
				  @pnDebtorKey		int,
				  @nCreditMultiplier	int,
				  @sSourceCountry	nvarchar(3),
				  @pdtItemDate		datetime,
				  @pnRaisedByStaffKey	int,
				  @XMLKeys		XML',
				  @pnItemTransNo=@pnItemTransNo,
				  @pnItemEntityNo=@pnItemEntityNo,
				  @pnDebtorKey = @pnDebtorKey,
				  @nCreditMultiplier = @nCreditMultiplier,
				  @sSourceCountry = @sSourceCountry,
				  @pdtItemDate = @pdtItemDate,
				  @pnRaisedByStaffKey = @pnRaisedByStaffKey,
				  @XMLKeys = @XMLKeys
End

--Check if the discount item is disconnected
if ( @nStatus = 0 or @nStatus is null )
Begin
	Update temp
	Set ISDISCOUNTDISCONNECTED = 1
	From #AVAILABLEWIPRETURNTABLE temp
	JOIN TRANSADJUSTMENT trans ON ((temp.ENTITYNO = trans.ENTITYNO and temp.TRANSNO = trans.TRANSNO) 
	OR (temp.ENTITYNO = trans.ADJENTITYNO and temp.TRANSNO = trans.ADJTRANSNO))
	JOIN WORKHISTORY wh ON wh.ENTITYNO = trans.ADJENTITYNO and wh.TRANSNO = trans.ADJTRANSNO
	where ISNULL( wh.DISCOUNTFLAG , 0) = 1
end 

If @nErrorCode = 0 and @pnDebtorKey is not null
Begin
	-- Figure out the currency of the bill.
	Set @sSQLString = 'select @sBillCurrency = CURRENCY
		FROM IPNAME
		WHERE NAMENO = @pnDebtorKey
		and CURRENCY != (SELECT COLCHARACTER FROM SITECONTROL WHERE CONTROLID = ''CURRENCY'')'

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@sBillCurrency	NVARCHAR(3) OUTPUT,
				  @pnDebtorKey		int',
				  @sBillCurrency=@sBillCurrency OUTPUT,
				  @pnDebtorKey=@pnDebtorKey
End

If @nErrorCode = 0 
	and exists (SELECT * FROM #AVAILABLEWIPRETURNTABLE where FOREIGNCURRENCY IS NOT NULL OR @sBillCurrency IS NOT NULL)
Begin
	-- Evaluate exchange rate for each item where the WIP Type has an exchange rate schedule.
	DECLARE AvailableWIP_Cursor cursor FOR 
		select DISTINCT WT.WIPTYPEID, WT.CATEGORYCODE, A.FOREIGNCURRENCY 
		from #AVAILABLEWIPRETURNTABLE A
		JOIN WIPTYPE WT ON WT.WIPTYPEID = A.WIPTYPEID
		WHERE (A.FOREIGNCURRENCY IS NOT NULL OR @sBillCurrency IS NOT NULL)
	
	OPEN AvailableWIP_Cursor
	FETCH NEXT FROM AvailableWIP_Cursor 
	INTO @sWIPType, @sWIPCategory, @sWIPCurrency
	
	WHILE (@@FETCH_STATUS = 0 and @nErrorCode = 0)
	Begin
		Set @nBuyRate = null
		Set @nSellRate = null
		
		if @sWIPCurrency is not null
		Begin
			exec @nErrorCode = dbo.ac_DoExchangeDetails
				@pnBankRate		= null,
				@pnBuyRate		= @nBuyRate output,
				@pnSellRate		= @nSellRate output,
				@pnDecimalPlaces	= null,
				@pnUserIdentityId	= @pnUserIdentityId,
				@pbCalledFromCentura	= @pbCalledFromCentura,
				@psCurrencyCode		= @sWIPCurrency,
				@pdtTransactionDate	= @pdtItemDate,
				@pbUseHistoricalRates	= null,
				@psWIPCategory		= @sWIPCategory,
				@pnCaseID		= @nMainCaseId,
				@pnNameNo		= @pnDebtorKey,
				@pbIsSupplier		= 0,
				@pnRoundBilledValues	= null,
				@pnAccountingSystemID	= 2,
				@psWIPTypeId		= @sWIPType
			
			If @nErrorCode = 0
			Begin
				Set @sSQLString = '
				Update #AVAILABLEWIPRETURNTABLE
				set WIPBUYRATE = @nBuyRate,
				WIPSELLRATE = @nSellRate'
				
				if (@sBillCurrency = @sWIPCurrency)
				Begin
					Set @sSQLString = @sSQLString + ',
						BILLBUYRATE = @nBuyRate,
						BILLSELLRATE = @nSellRate'
				End
				
				Set @sSQLString = @sSQLString + char(10) + 'WHERE WIPTYPEID = @sWIPType
				AND FOREIGNCURRENCY = @sWIPCurrency'
				
				exec @nErrorCode=sp_executesql @sSQLString,
					N'@nBuyRate	decimal(11,4),
					  @nSellRate	decimal(11,4),
					  @sWIPType	nvarchar(6),
					  @sWIPCurrency	nvarchar(3)',
					  @nBuyRate = @nBuyRate,
					  @nSellRate = @nSellRate,
					  @sWIPType = @sWIPType,
					  @sWIPCurrency = @sWIPCurrency
			End
		End
		
		Set @nBuyRate = null
		Set @nSellRate = null
		if (@sBillCurrency != @sWIPCurrency or (@sBillCurrency is not null and @sWIPCurrency is null))
		Begin
			exec @nErrorCode = dbo.ac_DoExchangeDetails
				@pnBankRate		= null,
				@pnBuyRate		= @nBuyRate output,
				@pnSellRate		= @nSellRate output,
				@pnDecimalPlaces	= null,
				@pnUserIdentityId	= @pnUserIdentityId,
				@pbCalledFromCentura	= @pbCalledFromCentura,
				@psCurrencyCode		= @sBillCurrency,
				@pdtTransactionDate	= @pdtItemDate,
				@pbUseHistoricalRates	= null,
				@psWIPCategory		= @sWIPCategory,
				@pnCaseID		= @nMainCaseId,
				@pnNameNo		= @pnDebtorKey,
				@pbIsSupplier		= 0,
				@pnRoundBilledValues	= null,
				@pnAccountingSystemID	= 2,
				@psWIPTypeId		= @sWIPType
			
			If @nErrorCode = 0
			Begin
				Update #AVAILABLEWIPRETURNTABLE
				set BILLBUYRATE = @nBuyRate,
				BILLSELLRATE = @nSellRate
				WHERE WIPTYPEID = @sWIPType
			End
		End
		

		FETCH NEXT FROM AvailableWIP_Cursor 
		INTO @sWIPType, @sWIPCategory, @sWIPCurrency
	End
	
	CLOSE AvailableWIP_Cursor
	DEALLOCATE AvailableWIP_Cursor
End

-- For draft bills, do not display credit WIP previously created to offset BillInAdvance WIP
If @nErrorCode = 0 
and @bWIPSplitMultiDebtor = 1
and @nStatus is null or @nStatus = 0
Begin
	delete CRWIP
	from #AVAILABLEWIPRETURNTABLE CRWIP
	where CRWIP.ISADVANCEBILL IS NULL
	AND EXISTS (SELECT 1 FROM #AVAILABLEWIPRETURNTABLE DBWIP 
			where DBWIP.TRANSNO = CRWIP.TRANSNO
			and DBWIP.ISADVANCEBILL = 1)
	
	Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0
Begin
	-- return the results
	Set @sSQLString = 'select
		CASEID as CaseKey,
		IRN as IRN,
		ENTITYNO as EntityNo,
		TRANSNO as TransNo,
		WIPSEQNO as WIPSeqNo,
		WIPCODE as WIPCode,
		WIPTYPEID as WIPTypeId,
		WIPTYPEDESCRIPTION as WIPTypeDescription,
		WIPCATEGORYCODE as WIPCategory,
		WIPCATEGORYDESCRIPTION as WIPCategoryDescription,
		WIPDESCRIPTION Description,
		RENEWALFLAG as RenewalFlag,
		NARRATIVENO as NarrativeNo,
		NARRATIVETEXT as ShortNarrative,
		TRANSDATE as TransDate,
		PROFITCENTRECODE as EmpProfitCentre,
		PROFITCENTRE as ProfitCentreDescription,
		TOTALTIME as TotalTime,
		TOTALUNITS as TotalUnits,
		UNITSPERHOUR as UnitsPerHour,
		CHARGEOUTRATE as ChargeOutRate,
		VARIABLEFEEAMT as VariableFeeAmt,
		VARIABLEFEETYPE as VariableFeeType,
		VARIABLEFEECURR as VariableFeeCurr,
		WRITEUPREASON as VariableFeeReason,
		VARWIPCODE as VariableFeeWIPCode,
		FEECRITERIANO as FeeCriteriaNo,
		FEEUNIQUEID as FeeUniqueId,
		BALANCE as Balance,
		LOCALBILLED as LocalBilled,
		FOREIGNBALANCE as ForeignBalance,
		FOREIGNCURRENCY  as ForeignCurrency,
		FOREIGNDECIMALPLACES as ForeignDecimalPlaces,
		FOREIGNBILLED as ForeignBilled,
		STATUS as Status,
		TAXCODE as TaxCode,
		TAXDESCRIPTION as TaxDescription,
		TAXRATE as TaxRate,
		STATETAXCODE  as StateTaxCode,
		STAFFNAME as StaffName,
		SIGNOFFNAME as StaffSignOffName,
		EMPLOYEENO as EmployeeNo,
		DISCOUNTFLAG as DiscountFlag,
		COSTCALCULATION1 as CostCalculation1,
		COSTCALCULATION2 as CostCalculation2,
		MARGINNO as MarginNo,
		CATEGORYSORT as WIPCatSortOrder,
		BILLLINENO as BillLineNo,
		REASONCODE as ReasonCode,
		MARGINFLAG as MarginFlag,
		RATENOSORT as RateNoSortOrder,
		WIPTYPESORT as WIPTypeSortOrder,
		WIPCODESORT as WIPCodeSortOrder,
		TITLE as Title,
		LOCALVARIATION LocalVariation,
		FOREIGNVARIATION ForeignVariation,
		BILLINGDISCOUNTFLAG as BillingDiscountFlag,
		PREVENTWRITEDOWNFLAG AS PreventWriteDownFlag,                
		GENERATEDFROMTAXCODE as GeneratedFromTaxCode,
		BILLITEMENTITYNO as BillItemEntityNo,
		BILLITEMTRANSNO as BillItemTransNo,                
		WRITEDOWNPRIORITY as WriteDownPriority,
		WRITEUPALLOWED as WriteUpAllowed,
		WIPBUYRATE as WIPBuyRate,
		WIPSELLRATE as WIPSellRate,
		BILLBUYRATE as BillBuyRate,
		BILLSELLRATE as BillSellRate,
		ISHIDDENFORDRAFT as IsHiddenForDraft,
		ACCTCLIENTNO as AcctClientNo,
		ISADVANCEBILL as IsAdvanceBill,
		ISDISCOUNTDISCONNECTED as IsDiscountDisconnected,
		ISFEETYPE as IsFeeType
		FROM #AVAILABLEWIPRETURNTABLE
		order by GENERATEDFROMTAXCODE'
		
	exec @nErrorCode=sp_executesql @sSQLString
End

DROP table #AVAILABLEWIPRETURNTABLE

return @nErrorCode
go

grant execute on dbo.[biw_GetBillAvailableWIP]  to public
go
