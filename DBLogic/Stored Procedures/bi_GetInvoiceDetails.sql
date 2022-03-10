-----------------------------------------------------------------------------------------------------------------------------
-- Creation of bi_GetInvoiceDetails 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[bi_GetInvoiceDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.bi_GetInvoiceDetails.'
	drop procedure dbo.bi_GetInvoiceDetails
end
print '**** Creating procedure dbo.bi_GetInvoiceDetails...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.bi_GetInvoiceDetails
		@pnUserIdentityId	int = null,
		@pnEntityNo		int,
		@psOpenItemNo		nvarchar(24),
		@psResultsRequired	nvarchar(max) = null,
		@pbCalledFromCentura	bit =	0	
as
---PROCEDURE :	bi_GetInvoiceDetails
-- VERSION :	48
-- DESCRIPTION:	A procedure that returns all of the details required for a
--		open item such as a Debit or Credit Note.
	
-- MODIFICATION
-- Date		Who	Change		Version Description
-- ===========  ===	===============	======= ===========
-- 23 Dec 2009	LP	RFC8744		1	Procedure created as bi_GetInvoiceDetails
-- 12 Jan 2010	MF	RFC8744		2	Allow details for draft Bills to also be returned.
-- 14 Jan 2010	LP	RFC8744		3	Return Foreign Currency Code for Bill Lines from OPENITEM.CURRENCY.
--						Return BILLLINE.LOCALTAX as DetailTax in BillLines result set.
-- 01 Apr 2011  LP     	RFC8412 	4       Hide Stamp Fees from draft invoices if specified.	
-- 30 May 2011	LP	RFC100524 	5	Fix BillLines not appearing for draft debtor-only invoices.
-- 02 Jun 2011	AT	RFC10756	6	Fixed null check on bill line.			
-- 14 Jul 2011	LP	RFC100562 	7	Display BillLine values as positive and discounts as negativ for Credit Notes.			
-- 17 Oct 2011	LP	RFC100644	8	Return BILLLINE.FOREIGNVALUE if BILLEDITEMS.FOREIGNVALUE is NULL for draft.
-- 22 Dec 2011	AT	RFC10458	9	Return TaxCode and Description.
-- 14 Feb 2012	LP	RFC100613 	10	Fix BillLines not appearing for draft debtor-only invoices (RFC100524)
-- 16 Feb 2012	AT	RFC11307	10	Enable return of stored procedure doc items using ipw_FetchDocItem.	
-- 21 Feb 2012	AT	RFC11836	11	Calculate groupings by WIP Category in bill line order
-- 06 Jun 2012	AT	RFC11594	12	Return bill line total for draft bills with hidden on draft rows.
-- 28 Jun 2012	KR	RFC11594	13	Fixed the total local and foreign value reutrned still avoiding hidden wip items on draft
-- 29 Jun 2012	KR	RFC12395	14	Stamp fee not showing on merged bills.
-- 02 Jul 2012	KR	RFC12395	15	Added logic to include stamp duty fee even if IRN is null in the bill line.
-- 09 Aug 2012	AT	RFC11860	16	Return long bill ref text column if applicable.
-- 21 Sep 2012	DL	R12763		17	Fix collation error by adding 'collate database_default' to character based columns in temp table definition.
-- 04 Oct 2012	LP	RFC12813	18	Fixed issue of duplicate bill lines in debtor-only invoices.
-- 29-Apr-2013	MS	RFC11732	19	YourRef is get from NAMEADDRESSSNAP is exists
-- 01-May-2013  MS	RFC11732	20	Return Cases from fn_GetBillCases
-- 08 Jul 2013	MF	R13641		21	Return the initials of the staff name associated with the bill lines.
-- 01 Aug 2013	vql	DR465		22	Group by Disb and Recoverables if billformat indicates so.
-- 27 Feb 2014	DL	S21508		23	Change variables and temp table columns that reference namecode to 20 characters
-- 18 Jul 2014	MF	R37491		24	Initials displaying incorrectly for Bills with multiple fee earners.
-- 09 Dec 2014	MF	R41890		25	Currency of reported billing lines should be PRINTCHARGECURRNCY.
-- 17 Mar 2015	JD	R45405		26	Fixed opposite sign issue for detail foreign values on finalised credit notes.
-- 17 Mar 2015	MF	R45808		27	Revisit 37491 to handle the possibility of multiple names existing with identical SignOffName.
-- 09 Jun 2015	MF	48413		28	Copy To name not being returned.  Expiry Date should be null.
-- 11 Jun 2015	MF	48473		29	Purchase Order Numbers on a multi Case bill can result in a string truncation error. When stringing these
--						together, remove any duplicates.
-- 20 Oct 2015  MS      R53933          29      Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE col
-- 02 Nov 2015	vql	R53910		30	Adjust formatted names logic (DR-15543).
-- 22 Mar 2016  vql     R56420          31	Incorrect bill lines presentation in invoices.
-- 04 Apr 2016	MF	R59264		32	Improve performance by extracting the data that is requested by the @psResultsRequired parameter.
-- 27 Apr 2016	MF	R60828		33	DetailNarrative being truncated. Changed to nvarchar(max).
-- 06 May 2016	MF	R61326		34	Extend the size of the columns provided for DOCITEM results to nvarchar(max).
-- 16 Dec 2016	MF	R70260		35	Add new columns: DetailDiscountValue, DetailDiscountForeignValue, DetailForeignChargeOutRate, DetailGrossAmount,
--						DetailForeignGrossAmount
-- 22 Dec 2016	MF	R70311		36	Correction to DetailGrossAmount & DetailForeignGrossAmount so as to also include the Discount amount.
-- 23 Feb 2016	MF	70707		37	Wrong nametype used for Signatory.
-- 17 May 2017	ECB	71533		38	Report the WIP Type description and provide grouping similar to WIP Category.
-- 01 Sep 2017	MS	72045		39	returned TaxRequired sitecontrol value in header.
-- 24 Jan 2018  MS      R73332          39      Use OpenItem.Currency than PrintChargeCurrency for foreign currency
-- 19 Apr 2018  MS   72343      40  Used left join for BilledItem and WorkHistory tables for bill lines 
-- 02 May 2018	MS	72343		41	Fix issue for wrong sign in bill lines for lines with no case ref
-- 03 May 2018	MS	R73695		42	Exclude movementclass 3 and 9 values from workhistory records
-- 03 May 2018  MS	R73776		43	Use BilledItem.BilledValue rather than WorkInProgress.LocalValue for DetailDiscountValue in draft bill
-- 31 Jul 2018  MS      74344           44      Remove duplicate lines logic for draft and finalised bills
-- 29 Aug 2018  MS      74055           45      Correction to DetailGrossAmount & DetailForeignGrossAmount for signs.
-- 27 Nov 2018  MS      DR-43955        46      Select PrintTime even if charge out rate is null
-- 31 May 2019  MS      DR-45655        47      Added columns ForeignTaxableAmount, ForeignTaxAmount and Currency for OPENITEMTAX
-- 20 Oct 2019  MS      DR-53398        48      Added movement class 5 for handling transfered wips for discounts

set nocount on
set concat_null_yields_null off

-- Store the Case details for each Case on the bill loaded from 
-- user defined queries and held in a Temporary Table (required because of dynamic SQL)
-- The size of the DocItem columns may need to be varied depending on 
-- the results to be loaded into these columns.
Create table #TEMPCASEDETAILS (
			CASEID			int		NOT NULL,
			IRN			nvarchar(30)	collate database_default NOT NULL,
			DOCITEM1		nvarchar(max)	collate database_default NULL,
			DOCITEM2		nvarchar(max)	collate database_default NULL,
			DOCITEM3		nvarchar(max)	collate database_default NULL,
			DOCITEM4		nvarchar(max)	collate database_default NULL,
			DOCITEM5		nvarchar(max)	collate database_default NULL,
			DOCITEM6		nvarchar(max)	collate database_default NULL,
			REFTEXT			nvarchar(max)	collate database_default NULL,
			ROWORDER		smallint	identity(1,1)
			)

-- Store the required information in a table variable
Declare @tbItemHeader table (
			OpenItemNo		nvarchar(12)	collate database_default NULL,
			AccountNo		nvarchar(60)	collate database_default NULL,
			YourRef			nvarchar(1000)	collate database_default NULL,
			ItemDate		datetime	NULL,
			RefText			ntext		collate database_default NULL,
			TaxLocal		decimal(11,2)	NULL,
			TaxForeign		decimal(11,2)	NULL,
			CurrencyLocal		nvarchar(3)	collate database_default NULL,
			LocalValue		decimal(11,2)	NULL,
			CurrencyForeign		nvarchar(3)	collate database_default NULL,
			CurrencyFlag		bit		NULL,
			ForeignValue		decimal(11,2)	NULL,
			BillPercentage		decimal(5,2)	NULL,
			TaxLabel		nvarchar(20)	collate database_default NULL,
			TaxFlag			bit		NULL,
			FmtName			nvarchar(254)	collate database_default NULL,
			FmtAddress		nvarchar(254)	collate database_default NULL,
			FmtAttention		nvarchar(254)	collate database_default NULL,
			StatusText		nvarchar(50)	collate database_default NULL,
			OurRef			nvarchar(1000)	collate database_default NULL,
			PurchaseOrderNo		nvarchar(1000)	collate database_default NULL,	--RFC48473 length increased from 80.
			SignOffName		nvarchar(100)	collate database_default NULL,
			Regarding		ntext		collate database_default NULL,
			BillScope		nvarchar(254)	collate database_default NULL,
			Reductions		decimal(11,2)	NULL,
			CreditNoteFlag		bit		NULL,
			ReductionsForeign	decimal(11,2)	NULL,
			TaxNo			nvarchar(30)	collate database_default NULL,
			ImageId			int		NULL,
			ForeignEquivCurrency	nvarchar(40)	collate database_default NULL,
			ForeignEquivExRate	decimal(11,4)	NULL,
			PenaltyInterestRate	decimal(5,2)	NULL,
			DueDate			datetime	NULL,
			LocalTakenUp		decimal(11,2)	NULL,
			ForeignTakenUp		decimal(11,2)	NULL,
			TaxRequired		bit NULL
			)

Declare @tbBillLines table (
			DetailDisplaySequence	smallint	NULL,
			DetailChargeOutRate	decimal(11,2)	NULL,
			DetailStaffName		nvarchar(60)	collate database_default NULL,
			DetailDate		datetime	NULL,
			DetailIRN		nvarchar(30)	collate database_default NULL,	
			DetailTime		nvarchar(30)	collate database_default NULL,
			DetailWIPCode		nvarchar(6)	collate database_default NULL,
			DetailWIPTypeId		nvarchar(6)	collate database_default NULL,
			DetailCatDesc		nvarchar(50)	collate database_default NULL,
			DetailWIPTypeDesc	nvarchar(50)	collate database_default NULL,
			DetailNarrative		nvarchar(max)	collate database_default NULL,
			DetailValue		decimal(11,2)	NULL,
			DetailForeignValue	decimal(11,2)	NULL,
			DetailChargeCurr	nvarchar(3)	collate database_default NULL,
                        DetailForeignCurr       nvarchar(3)	collate database_default NULL,
			DetailStaffClass	nvarchar(80)	collate database_default NULL,
			DetailStaffCode		nvarchar(20)	collate database_default NULL,
			DetailStaffInit		nvarchar(10)	collate database_default NULL,
			DetailCaseCountryCode	nvarchar(3)	collate database_default NULL,
			DetailCaseCountry	nvarchar(60)	collate database_default NULL,
			DetailCaseTypeDesc	nvarchar(50)	collate database_default NULL,
			DetailPropertyType	nvarchar(50)	collate database_default NULL,
			DetailOfficialNo	nvarchar(36)	collate database_default NULL,
			DetailCaseTitle		nvarchar(254)	collate database_default NULL,
			DetailCasePurchaseOrder	nvarchar(80)	collate database_default NULL,
			-- SQA12688 new columns
			DetailFeeEarnerName	   nvarchar(60)	collate database_default NULL,
			DetailFeeEarnerStaffClass  nvarchar(80)	collate database_default NULL,
			DetailFeeEarnerStaffCode   nvarchar(20)	collate database_default NULL,
			DetailFeeEarnerStaffInit   nvarchar(10)	collate database_default NULL,
			DetailCaseKey		   int					 NULL,
			DetailTax		   decimal(11,2)			 NULL,
			DetailTaxCode		   nvarchar(3)	collate database_default NULL,
			DetailTaxDescription	   nvarchar(30)	collate database_default NULL,
			DetailWIPCatGroup	   int,
			DetailWIPTypeGroup	   int,
			DetailDiscountValue	   decimal(11,2)			 NULL,
			DetailDiscountForeignValue decimal(11,2)			 NULL,
			DetailForeignChargeOutRate decimal(11,2)			 NULL,
			DetailGrossAmount	   decimal(11,2)			 NULL,
			DetailForeignGrossAmount   decimal(11,2)			 NULL
			)

-- Store the tax summary information in a table variable
Declare @tbTaxDetails table (
			TaxRate			decimal(11,4)	NULL,
			TaxableAmount		decimal(11,2)	NULL,
			TaxAmount		decimal(11,2)	NULL,
			TaxDescription		nvarchar(30)	collate database_default NULL,
                        ForeignTaxableAmount    decimal(11,2)	NULL,
                        ForeignTaxAmount        decimal(11,2)	NULL,
                        Currency                nvarchar(3)     collate database_default NULL
			)

-- Store the tax summary information in a table variable
Declare @tbCopyToDetails table (
			CopyToName		nvarchar(254)	collate database_default NULL,
			CopyToAttention		nvarchar(254)	collate database_default NULL,
			CopyToAddress		nvarchar(254)	collate database_default NULL
			)

Declare		@ErrorCode	int
Declare		@nRowCount	int

Declare		@sSQLString	nvarchar(max)
Declare		@sSQLDocItem	nvarchar(max)
Declare		@sItemName	nvarchar(max)
Declare		@sYourRef	nvarchar(max)
Declare		@sOurRef	nvarchar(max)
Declare		@sPurchaseNo	nvarchar(max)

Declare		@hDocument 	int 			-- handle to the XML parameter which is the Activity Request row
Declare		@nLanguage	int 			-- the language of the debitnote
Declare		@nDebtorNo	int			-- the debtorno of the debitnote
Declare		@sNameType	nvarchar(3) 		-- the NameType of the debitnote
Declare		@sDisbRecGroup	nvarchar(254)		-- the Disbursement and Recoverables group from Bill Format if applicable.
Declare		@nTransNo	int			-- the item transaction no of the debitnot

Declare		@bRenewalFlag	bit			-- indicates the Renewal Debtor was used for bill
Declare		@bFinalisedBill	bit			-- indicates if the bill is finalised or draft
Declare		@bIsDebtorOnly	bit			-- indicates if the bill is debtor only

-- Doc Item Variables
Declare		@nCounter	int
Declare		@sDocItemName	nvarchar(40)
Declare		@sCaseIRN	nvarchar(30)
	
Set @ErrorCode = 0

-- Get the Language, DebtorNo and NameType
If @ErrorCode=0
Begin
	Set @sSQLString="
	select @bRenewalFlag=cast(O.RENEWALDEBTORFLAG as bit),
	       @nLanguage	=isnull(O.LANGUAGE,S.COLINTEGER),
	       @nDebtorNo	=O.ACCTDEBTORNO,
	       @nTransNo	=O.ITEMTRANSNO,
	       @bFinalisedBill	=isnull(O.STATUS,0),
	       @sDisbRecGroup	=B.EXPENSEGROUPTITLE,
	       @sNameType	=CASE WHEN(O.RENEWALDEBTORFLAG=1) THEN 'Z' ELSE 'D' END	--RFC48473
	from OPENITEM O
	left join SITECONTROL S	on (S.CONTROLID='LANGUAGE')
	left join BILLFORMAT B on (B.BILLFORMATID=O.BILLFORMATID)
	where O.OPENITEMNO=@psOpenItemNo
	and O.ITEMENTITYNO=@pnEntityNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOpenItemNo		nvarchar(12),
					  @pnEntityNo		int,
					  @bRenewalFlag		bit		OUTPUT,
					  @nLanguage		int		OUTPUT,
					  @nDebtorNo		int		OUTPUT,
					  @nTransNo		int		OUTPUT,
					  @bFinalisedBill	bit		OUTPUT,
					  @sDisbRecGroup	nvarchar(254)	OUTPUT,
					  @sNameType		nvarchar(3)	OUTPUT',
					  @psOpenItemNo=@psOpenItemNo,
					  @pnEntityNo=@pnEntityNo,
					  @bRenewalFlag=@bRenewalFlag		OUTPUT,
					  @nLanguage=@nLanguage			OUTPUT,
					  @nDebtorNo=@nDebtorNo			OUTPUT,
					  @nTransNo =@nTransNo			OUTPUT,
					  @bFinalisedBill=@bFinalisedBill	OUTPUT,
					  @sDisbRecGroup=@sDisbRecGroup		OUTPUT,
					  @sNameType=@sNameType			OUTPUT
End

-- Get the Clients Reference, Our Reference and Purchase Order Nos,
-- for all Cases being billed separated by a comma
If @ErrorCode=0
Begin
	-- RFC48473
	-- Remove duplicate references and purchase orders while stringing
	-- together as a comma separated list.			
	set @sSQLString="
		With BillCases AS
		(
			select	BC.CASEID as CASEID
			from	OPENITEM O
			cross	apply	dbo.fn_GetBillCases(O.ITEMTRANSNO, O.ITEMENTITYNO) BC
			where O.OPENITEMNO=@psOpenItemNo
			and O.ITEMENTITYNO=@pnEntityNo
		)
		select	@sPurchaseNo =	STUFF((	select	distinct
							', ' + C.PURCHASEORDERNO
						from	BillCases B
						join	CASES C	on (C.CASEID = B.CASEID
								and C.PURCHASEORDERNO > '')
						order	by ', ' + C.PURCHASEORDERNO
						for	xml path('')),1,2,''),
			@sYourRef =	STUFF((	select	distinct
							', ' + CN.REFERENCENO
						from	BillCases B
						join	CASENAME CN on (CN.CASEID   = B.CASEID
								    and	CN.NAMETYPE = @sNameType
								    and	CN.NAMENO   = @nDebtorNo
								    and	CN.REFERENCENO > '')
						order	by ', ' + CN.REFERENCENO
						for	xml path('')),1,2,''),
			@sOurRef =	STUFF((	select	distinct
							', ' + C.IRN
						from	BillCases B
						join	CASES C on (C.CASEID = B.CASEID)
						order	by ', ' + C.IRN
						for	xml path('')),1,2,'')"
		
	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOpenItemNo		nvarchar(12),
					  @pnEntityNo		int,
					  @nDebtorNo		int,
					  @sNameType		nvarchar(3),
					  @sYourRef		nvarchar(1000)	OUTPUT,
					  @sOurRef		nvarchar(1000)	OUTPUT,
					  @sPurchaseNo		nvarchar(1000)	OUTPUT',
					  @psOpenItemNo=@psOpenItemNo,
					  @pnEntityNo  =@pnEntityNo,
					  @nDebtorNo   =@nDebtorNo,
					  @sNameType   =@sNameType,
					  @sYourRef    =@sYourRef		OUTPUT,
					  @sOurRef     =@sOurRef		OUTPUT,
					  @sPurchaseNo =@sPurchaseNo		OUTPUT
End

select @bIsDebtorOnly = case when ISNULL(@sOurRef, '') = '' then 1 else 0 end

If @ErrorCode=0
and @psResultsRequired in ('Header', 'BillLines')
Begin
	insert into @tbItemHeader
	select 		O.OPENITEMNO,
			isnull(NA.ALIAS,N.NAMECODE),
			isnull(NS.FORMATTEDREFERENCE, @sYourRef),  -- Clients reference separated by semi colon
			O.ITEMDATE,
			CASE WHEN(datalength(O.LONGREFTEXT)>0) THEN O.LONGREFTEXT ELSE O.REFERENCETEXT END,
			CASE WHEN(O.ITEMTYPE=511) THEN O.LOCALTAXAMT * -1 ELSE O.LOCALTAXAMT END,
			CASE WHEN(O.ITEMTYPE=511) THEN O.FOREIGNTAXAMT * -1 ELSE O.FOREIGNTAXAMT END,
			S1.COLCHARACTER, -- Local Currency
			CASE WHEN(O.ITEMTYPE=511) THEN O.LOCALVALUE * -1 ELSE O.LOCALVALUE END,
			O.CURRENCY,
			CASE WHEN(O.CURRENCY<>S1.COLCHARACTER) THEN 1 ELSE 0 END, -- Flag indicates foreign currency
			CASE WHEN(O.ITEMTYPE=511) THEN O.FOREIGNVALUE * -1 ELSE O.FOREIGNVALUE END,
			O.BILLPERCENTAGE,
			S2.COLCHARACTER, -- Tax literal
			CASE WHEN(O.LOCALTAXAMT<>0) THEN 1 ELSE 0 END,
			NS.FORMATTEDNAME,
			NS.FORMATTEDADDRESS,
			NS.FORMATTEDATTENTION,
			CASE WHEN(O.STATUS=0) THEN 'DRAFT' END,
			@sOurRef,	-- IRNs separated by Semi Colon
			isnull(@sPurchaseNo,IP.PURCHASEORDERNO),-- Purchase Orders from Cases separated by comma OR Purchase Order from IPNAME
			E.SIGNOFFNAME,
			CASE WHEN(datalength(O.LONGREGARDING)>0) THEN O.LONGREGARDING ELSE O.REGARDING END,
			O.SCOPE,
			Null,		-- Reductions
			CASE WHEN(O.ITEMTYPE=511) THEN 1 ELSE 0 END,
			Null,		-- ReductionsForeign
			N.TAXNO,
			O.IMAGEID,
			O.FOREIGNEQUIVCURRCY,
			O.FOREIGNEQUIVEXRATE,
			O.PENALTYINTEREST,
			O.ITEMDUEDATE,
			O.LOCALORIGTAKENUP,
			O.FOREIGNORIGTAKENUP,
			ST.COLBOOLEAN
	from OPENITEM O
	join NAME N			on (N.NAMENO=O.ACCTDEBTORNO)
	left join IPNAME IP		on (IP.NAMENO=N.NAMENO)
	left join NAMEALIAS NA		on (NA.NAMENO=N.NAMENO
					and NA.ALIASTYPE='D')
	left join SITECONTROL S1	on (S1.CONTROLID='CURRENCY')
	left join SITECONTROL S2	on (S2.CONTROLID='TAXLITERAL')
	     join NAMEADDRESSSNAP NS	on (NS.NAMESNAPNO=O.NAMESNAPNO)
	left join EMPLOYEE E		on (E.EMPLOYEENO=O.EMPLOYEENO)
	
	left join SITECONTROL ST	on (ST.CONTROLID = 'TAXREQUIRED')
	where O.OPENITEMNO=@psOpenItemNo
	and O.ITEMENTITYNO=@pnEntityNo

	Set @ErrorCode=@@Error
End

-- Get the Bill Line Details
-- Note that if the Bill Line does not contain the IRN details then revert to the 
-- WorkHistory rows to get the details required.
If @ErrorCode=0
and @psResultsRequired in ('Header', 'BillLines')
Begin
	If @bFinalisedBill=1
	Begin
		If @bIsDebtorOnly = 1
		Begin
			Insert into @tbBillLines(DetailDisplaySequence, DetailChargeOutRate, 
						DetailStaffName, DetailDate, DetailTime, 
						DetailWIPCode, DetailWIPTypeId, DetailCatDesc, DetailWIPTypeDesc,
						DetailNarrative, DetailValue, DetailForeignValue, DetailForeignCurr,
						DetailChargeCurr, DetailStaffClass, DetailStaffCode, DetailStaffInit,
						DetailTax, DetailTaxCode, DetailTaxDescription)
			select 	DISTINCT B.DISPLAYSEQUENCE, 
				B.PRINTCHARGEOUTRATE,
				isnull(B.PRINTNAME,dbo.fn_FormatName(N.NAME,N.FIRSTNAME,default,7101)), 
				isnull(B.PRINTDATE,WH.TRANSDATE), 
				B.PRINTTIME,
				B.WIPCODE, 
				B.WIPTYPEID, 
				case 
				when @sDisbRecGroup is not null and W.CATEGORYCODE in ('OR','PD') then @sDisbRecGroup
				else W.DESCRIPTION
				end, 
				WT.DESCRIPTION,
				CASE WHEN(datalength(isnull(B.LONGNARRATIVE,WH.LONGNARRATIVE))>0) 
					THEN convert(nvarchar(max),isnull(B.LONGNARRATIVE,WH.LONGNARRATIVE)) 
					ELSE isnull(B.SHORTNARRATIVE,WH.SHORTNARRATIVE) END,
				CASE WHEN (O.ITEMTYPE = 511) THEN B.VALUE*-1 ELSE B.VALUE END, 
				CASE WHEN (O.ITEMTYPE = 511) THEN B.FOREIGNVALUE * -1 ELSE B.FOREIGNVALUE END,
                                O.CURRENCY,
                                B.PRINTCHARGECURRNCY,				
				T.DESCRIPTION,
				N.NAMECODE,
				N.INITIALS,
				CASE WHEN (O.ITEMTYPE = 511) THEN B.LOCALTAX * -1 ELSE B.LOCALTAX END,
				B.TAXCODE, TR.DESCRIPTION
			from OPENITEM O
			join BILLLINE B		on (B.ITEMENTITYNO=O.ITEMENTITYNO
      		  				and B.ITEMTRANSNO =O.ITEMTRANSNO)
			left join WORKHISTORY WH	on (WH.REFENTITYNO=O.ITEMENTITYNO
						and WH.REFTRANSNO =O.ITEMTRANSNO
						and WH.BILLLINENO =B.ITEMLINENO)
			left join WIPTYPE WT		on (WT.WIPTYPEID  =B.WIPTYPEID)
			left join WIPCATEGORY W	on (W.CATEGORYCODE=B.CATEGORYCODE)
			left join EMPLOYEE E	on (E.EMPLOYEENO=WH.EMPLOYEENO
						and 1 = (select COUNT(*) from WORKHISTORY 
								where REFENTITYNO = B.ITEMENTITYNO 
								and REFTRANSNO = B.ITEMTRANSNO 
								and BILLLINENO = B.ITEMLINENO))
			left join TABLECODES T	on (T.TABLECODE=E.STAFFCLASS)
			left join NAME N	on (N.NAMENO=E.EMPLOYEENO)
			left join SITECONTROL S1	on (S1.CONTROLID='CURRENCY')
			left join TAXRATES TR	on (TR.TAXCODE = B.TAXCODE)
			where O.OPENITEMNO=@psOpenItemNo
			and O.ITEMENTITYNO=@pnEntityNo
			and O.MAINCASEID is NULL
		End
		Else Begin
			Insert into @tbBillLines(DetailDisplaySequence, DetailChargeOutRate, 
					DetailStaffName, DetailDate, DetailIRN, DetailTime, 
					DetailWIPCode, DetailWIPTypeId, DetailCatDesc, DetailWIPTypeDesc,
					DetailNarrative, DetailValue, DetailForeignValue, DetailForeignCurr,
					DetailChargeCurr, DetailStaffClass, DetailStaffCode, DetailStaffInit,
					DetailCaseCountryCode, DetailCaseCountry, DetailCaseTypeDesc, 
					DetailPropertyType, DetailOfficialNo, DetailCaseTitle, DetailCasePurchaseOrder,DetailCaseKey,
					DetailTax, DetailTaxCode, DetailTaxDescription,
					DetailDiscountValue, DetailDiscountForeignValue, DetailForeignChargeOutRate,
					DetailGrossAmount, DetailForeignGrossAmount)
			select 	B.DISPLAYSEQUENCE, 
				B.PRINTCHARGEOUTRATE,
				isnull(B.PRINTNAME,dbo.fn_FormatName(N.NAME,N.FIRSTNAME,default,7101)), 
				B.PRINTDATE, 
				C.IRN, 
				B.PRINTTIME,
				B.WIPCODE, 
				B.WIPTYPEID, 
				case 
				when @sDisbRecGroup is not null and W.CATEGORYCODE in ('OR','PD') then @sDisbRecGroup
				else W.DESCRIPTION
				end, 
				WT.DESCRIPTION,
				CASE WHEN(datalength(LONGNARRATIVE)>0) THEN convert(nvarchar(3500),LONGNARRATIVE) ELSE SHORTNARRATIVE END,
				CASE WHEN (O.ITEMTYPE = 511) THEN B.VALUE * -1 ELSE B.VALUE END, 
				CASE WHEN (O.ITEMTYPE = 511) THEN ISNULL(B.FOREIGNVALUE, O.EXCHRATE * B.VALUE) * -1 ELSE ISNULL(B.FOREIGNVALUE, O.EXCHRATE * B.VALUE) END,
                                O.CURRENCY,
                                B.PRINTCHARGECURRNCY,
				T.DESCRIPTION,
				N.NAMECODE,
				N.INITIALS,
				C.COUNTRYCODE,
				CN.COUNTRY,
				CT.CASETYPEDESC,
				VP.PROPERTYNAME,
				C.CURRENTOFFICIALNO,
				C.TITLE,
				C.PURCHASEORDERNO,
				C.CASEID,
				CASE WHEN (O.ITEMTYPE = 511) THEN B.LOCALTAX * -1 ELSE B.LOCALTAX END,
				B.TAXCODE, TR.DESCRIPTION,
				(-1 * isnull(WH.DISCOUNTVALUE, 0.00))                         as DetailDiscountValue,
				(-1 * isnull(WH.DISCOUNTVALUE * O.EXCHRATE, 0.00))            as DetailDiscountForeignValue,
				(O.EXCHRATE * isnull(B.PRINTCHARGEOUTRATE, WH.CHARGEOUTRATE)) as DetailForeignChargeOutRate,
				(B.VALUE + isnull(B.LOCALTAX,0) + isnull(WH.DISCOUNTVALUE, 0.00))                           
											      as DetailGrossAmount,
				(B.FOREIGNVALUE + isnull((O.EXCHRATE * B.LOCALTAX),0) + isnull(WH.DISCOUNTVALUE * O.EXCHRATE, 0.00)) 
											      as DetailForeignGrossAmount
			from OPENITEM O
			join BILLLINE B		on (B.ITEMENTITYNO=O.ITEMENTITYNO
	      		  			and B.ITEMTRANSNO =O.ITEMTRANSNO)
			LEFT join CASES C	on (C.IRN=B.IRN)
			------------------------------------------------------
			-- Return the Employee that matches the PRINTNAME on
			-- the billline only if there is only one Employee
			-- that matches that PRINTNAME. If nothing is returned
			-- use Employee associated with the WorkHistory.
			------------------------------------------------------
			left join EMPLOYEE E1	on (E1.SIGNOFFNAME=B.PRINTNAME
						and not exists (select 1
								from EMPLOYEE E2
								where E2.SIGNOFFNAME=B.PRINTNAME
								and E2.EMPLOYEENO<>E1.EMPLOYEENO))
			left join CASENAME EMP	on (EMP.CASEID=C.CASEID
						and EMP.NAMETYPE='EMP'
						and EMP.EXPIRYDATE is null
						and E1.EMPLOYEENO is null)
			left join WIPTYPE WT	on (WT.WIPTYPEID=B.WIPTYPEID)
			left join WIPCATEGORY W	on (W.CATEGORYCODE=B.CATEGORYCODE)
			left join EMPLOYEE E	on (E.EMPLOYEENO=isnull((select min(WH.EMPLOYEENO)
									from WORKHISTORY WH
									Where WH.REFENTITYNO=O.ITEMENTITYNO
									and WH.REFTRANSNO =O.ITEMTRANSNO
									and WH.BILLLINENO =B.ITEMLINENO
                                    and WH.MOVEMENTCLASS not in (3,9)
									and WH.EMPLOYEENO is not null and B.IRN is not null),EMP.NAMENO)
						and E1.EMPLOYEENO is null)
			left join TABLECODES T	on (T.TABLECODE=isnull(E1.STAFFCLASS,E.STAFFCLASS))
			left join NAME N	on (N.NAMENO=isnull(E1.EMPLOYEENO,E.EMPLOYEENO))
			left join COUNTRY CN	on (CN.COUNTRYCODE=C.COUNTRYCODE)
			left join CASETYPE CT	on (CT.CASETYPE=C.CASETYPE)
			left join VALIDPROPERTY VP	on (VP.PROPERTYTYPE=C.PROPERTYTYPE
							and VP.COUNTRYCODE=(	select min(VP1.COUNTRYCODE)
										from VALIDPROPERTY VP1
										where VP1.PROPERTYTYPE=VP.PROPERTYTYPE
										and VP1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
			left join TAXRATES TR	on (TR.TAXCODE = B.TAXCODE)
			-- Finalised items retrieve from WORKHISTORY
	      		left join (SELECT BL.ITEMENTITYNO, BL.ITEMTRANSNO, BL.ITEMLINENO, 
	      				  sum(CASE WHEN(W1.ENTEREDQUANTITY>0) THEN W1.ENTEREDQUANTITY ELSE 0 END) as ENTEREDQUANTITY, 
	      				  sum(CASE WHEN(W.DISCOUNTFLAG=1)     THEN W.LOCALTRANSVALUE  ELSE 0 END) as DISCOUNTVALUE,
	      				  max(W1.CHARGEOUTRATE)                                                   as CHARGEOUTRATE
				FROM BILLLINE BL 
				join WORKHISTORY W	on (W.REFENTITYNO=BL.ITEMENTITYNO
							and W.REFTRANSNO =BL.ITEMTRANSNO
							and W.BILLLINENO =BL.ITEMLINENO
							and W.MOVEMENTCLASS not in (3,9))
				join WORKHISTORY W1	on (W1.ENTITYNO  =W.ENTITYNO
							and W1.TRANSNO   =W.TRANSNO
							and W1.WIPSEQNO  =W.WIPSEQNO
							and W1.STATUS    =1
							and W1.MOVEMENTCLASS=(select min(W2.MOVEMENTCLASS)
									      from WORKHISTORY W2
									      where W2.ENTITYNO=W.ENTITYNO
									      and   W2.TRANSNO =W.TRANSNO
									      and   W2.WIPSEQNO=W.WIPSEQNO
									      and   W2.STATUS  =1
									      and   W2.MOVEMENTCLASS in (1,4,5)))
				WHERE BL.ITEMENTITYNO = @pnEntityNo
				and BL.ITEMTRANSNO = @nTransNo
				and(W1.ENTEREDQUANTITY>0 OR W.DISCOUNTFLAG=1 OR W1.CHARGEOUTRATE is not null)
				GROUP BY BL.ITEMENTITYNO, BL.ITEMTRANSNO, BL.ITEMLINENO) AS WH on (WH.ITEMENTITYNO = B.ITEMENTITYNO
								and WH.ITEMTRANSNO = B.ITEMTRANSNO
								and WH.ITEMLINENO = B.ITEMLINENO)
			where O.OPENITEMNO=@psOpenItemNo
			and O.ITEMENTITYNO=@pnEntityNo

			Set @ErrorCode=@@Error
		End
	End
	Else Begin
		If @bIsDebtorOnly=1
		Begin
			Insert into @tbBillLines(DetailDisplaySequence, DetailChargeOutRate, 
				DetailStaffName, DetailDate, DetailTime, 
				DetailWIPCode, DetailWIPTypeId, DetailCatDesc, DetailWIPTypeDesc, 
				DetailNarrative, DetailValue, DetailForeignValue, DetailForeignCurr,
				DetailChargeCurr, DetailStaffClass, DetailStaffCode,DetailStaffInit,
				DetailTax, DetailTaxCode, DetailTaxDescription)
			select DISTINCT 	B.DISPLAYSEQUENCE, 
				B.PRINTCHARGEOUTRATE,
				isnull(B.PRINTNAME,dbo.fn_FormatName(N.NAME,N.FIRSTNAME,default,7101)), 
				isnull(B.PRINTDATE,WH.TRANSDATE),
				B.PRINTTIME,
				B.WIPCODE, 
				B.WIPTYPEID,
				case 
				when @sDisbRecGroup is not null and W.CATEGORYCODE in ('OR','PD') then @sDisbRecGroup
				else W.DESCRIPTION
				end, 
				WT.DESCRIPTION,
				CASE WHEN(datalength(isnull(B.LONGNARRATIVE,WH.LONGNARRATIVE))>0) 
					THEN convert(nvarchar(max),isnull(B.LONGNARRATIVE,WH.LONGNARRATIVE)) 
					ELSE isnull(B.SHORTNARRATIVE,WH.SHORTNARRATIVE) END,
				CASE WHEN (O.ITEMTYPE = 511) THEN B.VALUE * -1 ELSE B.VALUE END,
				CASE WHEN (O.ITEMTYPE = 511) THEN B.FOREIGNVALUE * -1 ELSE B.FOREIGNVALUE END, 
				O.CURRENCY,
                                B.PRINTCHARGECURRNCY,
				T.DESCRIPTION,
				N.NAMECODE,
				N.INITIALS,
				CASE WHEN (O.ITEMTYPE = 511) THEN B.LOCALTAX * -1 ELSE B.LOCALTAX END,
				B.TAXCODE, 
				TR.DESCRIPTION
			from OPENITEM O
			join BILLLINE B		on (B.ITEMENTITYNO=O.ITEMENTITYNO
  						and B.ITEMTRANSNO =O.ITEMTRANSNO)
			left join BILLEDITEM BI on (BI.ITEMENTITYNO = B.ITEMENTITYNO
						and BI.ITEMTRANSNO =B.ITEMTRANSNO
						and BI.ITEMLINENO  =B.ITEMLINENO)
			left join WORKHISTORY WH	on (WH.ENTITYNO=BI.WIPENTITYNO
						and WH.TRANSNO =BI.WIPTRANSNO
						and WH.WIPSEQNO=BI.WIPSEQNO)
			left join WIPTYPE WT	on (WT.WIPTYPEID=B.WIPTYPEID)
			left join WIPCATEGORY W	on (W.CATEGORYCODE=B.CATEGORYCODE)
			left join EMPLOYEE E	on (E.EMPLOYEENO=WH.EMPLOYEENO
						and 1 = (select COUNT(*) from BILLEDITEM 
								where ITEMENTITYNO = B.ITEMENTITYNO 
								and ITEMTRANSNO = B.ITEMTRANSNO 
								and ITEMLINENO = B.ITEMLINENO))
			left join TABLECODES T	on (T.TABLECODE=E.STAFFCLASS)
			left join NAME N	on (N.NAMENO=E.EMPLOYEENO)
			left join TAXRATES TR	on (TR.TAXCODE = B.TAXCODE)
			where O.OPENITEMNO=@psOpenItemNo
			and O.ITEMENTITYNO=@pnEntityNo
			and O.MAINCASEID is null
			and (B.ISHIDDENFORDRAFT <> 1 or B.ISHIDDENFORDRAFT IS NULL)
			order by 1
		End
		Else Begin
			Insert into @tbBillLines(DetailDisplaySequence, DetailChargeOutRate, 
						DetailStaffName, DetailDate, DetailIRN, DetailTime, 
						DetailWIPCode, DetailWIPTypeId, DetailCatDesc,  DetailWIPTypeDesc,
					DetailNarrative, DetailValue, DetailForeignValue, DetailForeignCurr,
					DetailChargeCurr, DetailStaffClass, DetailStaffCode,DetailStaffInit,
					DetailCaseCountryCode, DetailCaseCountry, DetailCaseTypeDesc, 
					DetailPropertyType, DetailOfficialNo, DetailCaseTitle, DetailCasePurchaseOrder,DetailCaseKey,
					DetailTax, DetailTaxCode, DetailTaxDescription,
					DetailDiscountValue, DetailDiscountForeignValue, DetailForeignChargeOutRate,
					DetailGrossAmount, DetailForeignGrossAmount)
			select 	B.DISPLAYSEQUENCE, 
				B.PRINTCHARGEOUTRATE,
				isnull(B.PRINTNAME,dbo.fn_FormatName(N.NAME,N.FIRSTNAME,default,7101)), 
				B.PRINTDATE, 
				C.IRN, 
				B.PRINTTIME,
				B.WIPCODE, 
				B.WIPTYPEID, 
				case 
				when @sDisbRecGroup is not null and W.CATEGORYCODE in ('OR','PD') then @sDisbRecGroup
				else W.DESCRIPTION
				end, 
				WT.DESCRIPTION,
				CASE WHEN(datalength(LONGNARRATIVE)>0) THEN convert(nvarchar(3500),LONGNARRATIVE) ELSE SHORTNARRATIVE END,
				CASE WHEN (O.ITEMTYPE = 511) THEN B.VALUE * -1 ELSE B.VALUE END, 
				CASE WHEN (O.ITEMTYPE = 511) THEN ISNULL(B.FOREIGNVALUE, O.EXCHRATE * B.VALUE) * -1 ELSE ISNULL(B.FOREIGNVALUE, O.EXCHRATE * B.VALUE) END, 
				O.CURRENCY,
                                B.PRINTCHARGECURRNCY,
				T.DESCRIPTION,
				N.NAMECODE,
				N.INITIALS,
				C.COUNTRYCODE,
				CN.COUNTRY,
				CT.CASETYPEDESC,
				VP.PROPERTYNAME,
				C.CURRENTOFFICIALNO,
				C.TITLE,
				C.PURCHASEORDERNO,
				C.CASEID,
				CASE WHEN (O.ITEMTYPE = 511) THEN B.LOCALTAX * -1 ELSE B.LOCALTAX END,
				B.TAXCODE, TR.DESCRIPTION,
				isnull(WH.DISCOUNTVALUE, 0.00)                         as DetailDiscountValue,
				isnull(WH.DISCOUNTVALUE * O.EXCHRATE, 0.00)            as DetailDiscountForeignValue,
				(O.EXCHRATE * isnull(B.PRINTCHARGEOUTRATE, WH.CHARGEOUTRATE)) as DetailForeignChargeOutRate,
				(B.VALUE + isnull(B.LOCALTAX,0) - isnull(WH.DISCOUNTVALUE, 0.00))
								                              as DetailGrossAmount,
				(B.FOREIGNVALUE + isnull((O.EXCHRATE * B.LOCALTAX),0) - isnull(WH.DISCOUNTVALUE * O.EXCHRATE, 0.00))
											      as DetailForeignGrossAmount
			from OPENITEM O
			join BILLLINE B		on (B.ITEMENTITYNO=O.ITEMENTITYNO
	      		  			and B.ITEMTRANSNO =O.ITEMTRANSNO)
			LEFT join CASES C	on (C.IRN=B.IRN)
			------------------------------------------------------
			-- Return the Employee that matches the PRINTNAME on
			-- the billline only if there is only one Employee
			-- that matches that PRINTNAME. If nothing is returned
			-- use Employee associated with the WorkHistory.
			------------------------------------------------------
			left join EMPLOYEE E1	on (E1.SIGNOFFNAME=B.PRINTNAME
						and not exists (select 1
								from EMPLOYEE E2
								where E2.SIGNOFFNAME=B.PRINTNAME
								and E2.EMPLOYEENO<>E1.EMPLOYEENO))
			left join CASENAME EMP	on (EMP.CASEID=C.CASEID
						and EMP.NAMETYPE='EMP'
						and EMP.EXPIRYDATE is null
						and E1.EMPLOYEENO  is null)
			left join WIPTYPE WT	on (WT.WIPTYPEID=B.WIPTYPEID)
			left join WIPCATEGORY W	on (W.CATEGORYCODE=B.CATEGORYCODE)
			left join EMPLOYEE E	on (E.EMPLOYEENO=isnull((select min(WIP.EMPLOYEENO)
									from BILLEDITEM BI
									join WORKINPROGRESS WIP	on (WIP.ENTITYNO=BI.WIPENTITYNO
												and WIP.TRANSNO =BI.WIPTRANSNO)
									Where BI.ITEMENTITYNO=B.ITEMENTITYNO
									and BI.ITEMTRANSNO   =B.ITEMTRANSNO
									and BI.ITEMLINENO    =B.ITEMLINENO
									and WIP.EMPLOYEENO is not null and B.IRN is not null),EMP.NAMENO)
						and E1.EMPLOYEENO  is null)
			left join TABLECODES T	on (T.TABLECODE=isnull(E1.STAFFCLASS,E.STAFFCLASS))
			left join NAME N	on (N.NAMENO=isnull(E1.EMPLOYEENO, E.EMPLOYEENO))
			left join COUNTRY CN	on (CN.COUNTRYCODE=C.COUNTRYCODE)
			left join CASETYPE CT	on (CT.CASETYPE=C.CASETYPE)
			left join VALIDPROPERTY VP	on (VP.PROPERTYTYPE=C.PROPERTYTYPE
							and VP.COUNTRYCODE=(	select min(VP1.COUNTRYCODE)
										from VALIDPROPERTY VP1
										where VP1.PROPERTYTYPE=VP.PROPERTYTYPE
										and VP1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
			left join TAXRATES TR	on (TR.TAXCODE = B.TAXCODE)
	      		left join (SELECT BL.ITEMENTITYNO, BL.ITEMTRANSNO, BL.ITEMLINENO, 
	      				  sum(CASE WHEN(W.ENTEREDQUANTITY>0) THEN W.ENTEREDQUANTITY ELSE 0 END) as ENTEREDQUANTITY, 
	      				  sum(CASE WHEN(W.DISCOUNTFLAG=1)    THEN BL.BILLEDVALUE    ELSE 0 END) as DISCOUNTVALUE,
	      				  max(W.CHARGEOUTRATE)                                                  as CHARGEOUTRATE
				FROM BILLEDITEM BL 
				JOIN WORKINPROGRESS W ON (W.TRANSNO  = BL.WIPTRANSNO
						      and W.ENTITYNO = BL.WIPENTITYNO
						      and W.WIPSEQNO = BL.WIPSEQNO)
				WHERE BL.ITEMENTITYNO = @pnEntityNo
				and BL.ITEMTRANSNO = @nTransNo
				and(W.ENTEREDQUANTITY>0 OR W.DISCOUNTFLAG=1 OR W.CHARGEOUTRATE is not null)
				GROUP BY BL.ITEMENTITYNO, BL.ITEMTRANSNO, BL.ITEMLINENO) AS WH on (WH.ITEMENTITYNO = B.ITEMENTITYNO
								and WH.ITEMTRANSNO = B.ITEMTRANSNO
								and WH.ITEMLINENO = B.ITEMLINENO)
			where O.OPENITEMNO=@psOpenItemNo
			and O.ITEMENTITYNO=@pnEntityNo
			and (B.ISHIDDENFORDRAFT <> 1 or B.ISHIDDENFORDRAFT IS NULL)
		
			Set @ErrorCode=@@Error
		End
	End
End

If @ErrorCode=0
Begin
	-- The staff member that may be recorded against the work performed may be a department
	-- rather than a real person.  The following additional fields are being populated
	-- with a real person by first looking at the Name associated with the work performed, 
	-- the Employee against the Case, and finally the signatory against the Case.
	Update @tbBillLines
	Set	DetailFeeEarnerName      =CASE WHEN(I1.SEX<>'D') THEN T.DetailStaffName
					       WHEN(I2.SEX<>'D') THEN dbo.fn_FormatName(N2.NAME,N2.FIRSTNAME,default,7101)
					       WHEN(I3.SEX<>'D') THEN dbo.fn_FormatName(N3.NAME,N3.FIRSTNAME,default,7101)
					  END,					
		DetailFeeEarnerStaffClass=CASE WHEN(I1.SEX<>'D') THEN T.DetailStaffClass
					       WHEN(I2.SEX<>'D') THEN S2.DESCRIPTION
					       WHEN(I3.SEX<>'D') THEN S3.DESCRIPTION
					  END,					
		DetailFeeEarnerStaffCode =CASE WHEN(I1.SEX<>'D') THEN T.DetailStaffCode
					       WHEN(I2.SEX<>'D') THEN N2.NAMECODE
					       WHEN(I3.SEX<>'D') THEN N3.NAMECODE
					  END,
		DetailFeeEarnerStaffInit =CASE WHEN(I1.SEX<>'D') THEN T.DetailStaffInit
					       WHEN(I2.SEX<>'D') THEN N2.INITIALS
					       WHEN(I3.SEX<>'D') THEN N3.INITIALS
					  END
	from @tbBillLines T
	join CASES C		on (C.IRN=T.DetailIRN)

		left join NAME N1	on (N1.NAMECODE=T.DetailStaffCode)
		left join INDIVIDUAL I1	on (I1.NAMENO=N1.NAMENO)

		left join CASENAME EMP	on (EMP.CASEID=C.CASEID
					and EMP.NAMETYPE='EMP'
					and EMP.EXPIRYDATE is null)
		left join EMPLOYEE E2	on (E2.EMPLOYEENO=EMP.NAMENO)
		left join INDIVIDUAL I2	on (I2.NAMENO=EMP.NAMENO)
		left join NAME N2	on (N2.NAMENO=EMP.NAMENO)
		left join TABLECODES S2 on (S2.TABLECODE=E2.STAFFCLASS)

		left join CASENAME SIG	on (SIG.CASEID=C.CASEID
					and SIG.NAMETYPE='SIG'
					and SIG.EXPIRYDATE is null)
		left join EMPLOYEE E3	on (E3.EMPLOYEENO=SIG.NAMENO)
		left join INDIVIDUAL I3	on (I3.NAMENO=SIG.NAMENO)
		left join NAME N3	on (N3.NAMENO=SIG.NAMENO)
		left join TABLECODES S3 on (S3.TABLECODE=E3.STAFFCLASS)

		Set @ErrorCode=@@Error
	End
				
-- Calculate groupings by WIP Category in bill line order
If @ErrorCode=0
Begin
	DECLARE @nGroup int
	Set @nGroup = 0
	
	-- I've used an inner merge join to TRY and ensure @tbBillLines is updated in DetailDisplaySequence order.
	-- If it doesn't update in the expected order, the @nGroup counter won't work properly.
	Update T
	set	@nGroup = @nGroup + (case when BILLLINESCAT.CatDesc != BILLLINESCAT.PrevCatDesc or 
				BILLLINESCAT.CatDesc IS NULL AND BILLLINESCAT.PrevCatDesc IS NOT NULL 
				OR BILLLINESCAT.PrevCatDesc IS NULL AND BILLLINESCAT.CatDesc IS NOT NULL then 1 else 0 end),
		DetailWIPCatGroup = @nGroup
	from @tbBillLines T
	inner merge join (SELECT T.DetailDisplaySequence, T.DetailCatDesc as CatDesc, T1.DetailCatDesc as PrevCatDesc
		from @tbBillLines T
		LEFT JOIN @tbBillLines T1 ON (T1.DetailDisplaySequence = T.DetailDisplaySequence - 1)) as BILLLINESCAT
		on T.DetailDisplaySequence = BILLLINESCAT.DetailDisplaySequence
End				
				
-- Calculate groupings by WIP Type in bill line order
If @ErrorCode=0
Begin
	Set @nGroup = 0
		
	-- I've used an inner merge join to TRY and ensure @tbBillLines is updated in DetailDisplaySequence order.
	-- If it doesn't update in the expected order, the @nGroup counter won't work properly.
	Update T
	set	@nGroup = @nGroup + (case when BILLLINESTYPE.TypeDesc != BILLLINESTYPE.PrevTypeDesc or 
				BILLLINESTYPE.TypeDesc IS NULL AND BILLLINESTYPE.PrevTypeDesc IS NOT NULL 
				OR BILLLINESTYPE.PrevTypeDesc IS NULL AND BILLLINESTYPE.TypeDesc IS NOT NULL then 1 else 0 end),
		DetailWIPTypeGroup = @nGroup
	from @tbBillLines T
	inner merge join (SELECT T.DetailDisplaySequence, T.DetailWIPTypeDesc as TypeDesc, T1.DetailWIPTypeDesc as PrevTypeDesc
		from @tbBillLines T
		LEFT JOIN @tbBillLines T1 ON (T1.DetailDisplaySequence = T.DetailDisplaySequence - 1)) as BILLLINESTYPE
		on T.DetailDisplaySequence = BILLLINESTYPE.DetailDisplaySequence
End
	
-- Get the total of the lines that reduce the overall
-- value of the Open Item.
If @ErrorCode=0
Begin
	If exists(select * from @tbItemHeader where CreditNoteFlag=0)
		update @tbItemHeader
		set Reductions=R.ReductionTotal,
		    ReductionsForeign=R.ReductionForeignTotal
		from @tbItemHeader T
		join (	select	sum(DetailValue) as ReductionTotal, sum(DetailForeignValue) as ReductionForeignTotal
			from @tbBillLines
			where DetailValue<0) R on (1=1)
	Else
		update @tbItemHeader
		set Reductions=R.ReductionTotal,
		    ReductionsForeign=R.ReductionForeignTotal
		from @tbItemHeader T
		join (	select	sum(DetailValue) as ReductionTotal, sum(DetailForeignValue) as ReductionForeignTotal
			from @tbBillLines
			where DetailValue>0) R on (1=1)

	set @ErrorCode=@@Error
End

-- Update the bill totals to use the bill line values if we have a bill line that is going to be hidden.
If @ErrorCode=0 and @bFinalisedBill=0
	and exists (select * from OPENITEM O
			join BILLLINE B	on (B.ITEMENTITYNO=O.ITEMENTITYNO
	  				and B.ITEMTRANSNO =O.ITEMTRANSNO)
			WHERE O.OPENITEMNO=@psOpenItemNo
			and O.ITEMENTITYNO=@pnEntityNo
			and B.ISHIDDENFORDRAFT = 1)
Begin
	UPDATE @tbItemHeader 
	SET 	LocalValue = O.LOCALVALUE - B.SUMLOCAL,
		ForeignValue = O.FOREIGNVALUE - B.SUMFOREIGN
		from OPENITEM O
		JOIN (SELECT ITEMENTITYNO, ITEMTRANSNO,
			SUM(VALUE) AS SUMLOCAL,
			SUM(ISNULL(FOREIGNVALUE,0)) AS SUMFOREIGN
			FROM BILLLINE
			WHERE (ISHIDDENFORDRAFT = 1)
			GROUP BY ITEMTRANSNO, ITEMENTITYNO) AS B	on (B.ITEMENTITYNO=O.ITEMENTITYNO
  									and B.ITEMTRANSNO =O.ITEMTRANSNO)
		WHERE O.OPENITEMNO=@psOpenItemNo
		and O.ITEMENTITYNO=@pnEntityNo
End

-- Get the tax details
If @ErrorCode=0
and @psResultsRequired = 'Tax'
Begin
	Insert into @tbTaxDetails (TaxRate, TaxableAmount, TaxAmount, TaxDescription, ForeignTaxableAmount, ForeignTaxAmount, Currency)
	select OT.TAXRATE, 
	CASE WHEN (O.ITEMTYPE = 511) THEN OT.TAXABLEAMOUNT * -1 ELSE OT.TAXABLEAMOUNT END, 
	CASE WHEN (O.ITEMTYPE = 511) THEN OT.TAXAMOUNT * -1 ELSE OT.TAXAMOUNT END, 
	T.DESCRIPTION,
        CASE WHEN (O.ITEMTYPE = 511) THEN OT.FOREIGNTAXABLEAMOUNT * -1 ELSE OT.FOREIGNTAXABLEAMOUNT END, 
	CASE WHEN (O.ITEMTYPE = 511) THEN OT.FOREIGNTAXAMOUNT * -1 ELSE OT.FOREIGNTAXAMOUNT END,
        OT.CURRENCY
	from OPENITEM O
	join OPENITEMTAX OT	on (OT.ITEMENTITYNO=O.ITEMENTITYNO
        			and OT.ITEMTRANSNO =O.ITEMTRANSNO
        			and OT.ACCTENTITYNO=O.ACCTENTITYNO
       				and OT.ACCTDEBTORNO=O.ACCTDEBTORNO)
	join TAXRATES T		on (T.TAXCODE=OT.TAXCODE)
	where O.OPENITEMNO=@psOpenItemNo
	and O.ITEMENTITYNO=@pnEntityNo

	Set @ErrorCode=@@Error
End

-- Get the user defined details associated with each Case.
-- Not required for @psResultsRequired = 'Tax'
Else If @ErrorCode=0
Begin
	insert into #TEMPCASEDETAILS(CASEID, IRN)
	Select C.CASEID, C.IRN 
	from OPENITEM O
	join BILLLINE B		on (B.ITEMENTITYNO=O.ITEMENTITYNO
      		  		and B.ITEMTRANSNO =O.ITEMTRANSNO)
	join CASES C		on (C.IRN=B.IRN)
	where O.OPENITEMNO=@psOpenItemNo
	and O.ITEMENTITYNO=@pnEntityNo
	and B.DISPLAYSEQUENCE=(select min(B1.DISPLAYSEQUENCE)
				from BILLLINE B1
				where B1.ITEMENTITYNO=B.ITEMENTITYNO
				and   B1.ITEMTRANSNO =B.ITEMTRANSNO
				and   B1.IRN         =B.IRN)
	order by B.DISPLAYSEQUENCE

	Select	@ErrorCode=@@Error,
		@nRowCount=@@Rowcount

	-- If no rows found in BILLLINE then get the Case details
	-- from the WORKHISTORY table

	If @ErrorCode=0
	and @nRowCount=0
	Begin
		If @bFinalisedBill=1
		Begin
			insert into #TEMPCASEDETAILS(CASEID, IRN)
			Select distinct C.CASEID, C.IRN 
			from OPENITEM O
			join WORKHISTORY WH	on (WH.REFENTITYNO=O.ITEMENTITYNO
	      		  			and WH.REFTRANSNO =O.ITEMTRANSNO)
			join CASES C		on (C.CASEID=WH.CASEID)
			where O.OPENITEMNO=@psOpenItemNo
			and O.ITEMENTITYNO=@pnEntityNo
			order by C.IRN
		
			Select	@ErrorCode=@@Error,
				@nRowCount=@@Rowcount
		End
		Else Begin
			insert into #TEMPCASEDETAILS(CASEID, IRN)
			Select distinct C.CASEID, C.IRN 
			from OPENITEM O
			join BILLEDITEM BI	on (BI.ENTITYNO=O.ITEMENTITYNO
						and BI.TRANSNO =O.ITEMTRANSNO)
			join WORKHISTORY WH	on (WH.ENTITYNO=BI.WIPENTITYNO
						and WH.TRANSNO =BI.WIPTRANSNO
						and WH.WIPSEQNO=BI.WIPSEQNO)
			join CASES C		on (C.CASEID=WH.CASEID)
			where O.OPENITEMNO=@psOpenItemNo
			and O.ITEMENTITYNO=@pnEntityNo
			order by C.IRN
			
			Select	@ErrorCode=@@Error,
				@nRowCount=@@Rowcount
		End
	End

	-- If there are Cases against the Bill now see if any user defined
	-- Doc Items have been defined.
	If  @ErrorCode = 0 and @nRowCount > 0
	Begin
		-- loop through each case
		DECLARE InvoiceDocItem_Cursor cursor FOR 
		select DISTINCT IRN
		from #TEMPCASEDETAILS
	
		OPEN InvoiceDocItem_Cursor
		FETCH NEXT FROM InvoiceDocItem_Cursor 
		INTO @sCaseIRN
		
		WHILE (@@FETCH_STATUS = 0 and @ErrorCode = 0)
		Begin
			Set @nCounter = 1
			
			-- loop through each doc item (1-6) for this case
			While @ErrorCode = 0 and @nCounter <= 6
			Begin
				Set @sSQLDocItem = null
				Set @sDocItemName = null
				
				Set @sSQLString = "Select @sDocItemName = COLCHARACTER
						From SITECONTROL
						Where CONTROLID='Bill Ref Doc Item " + CAST(@nCounter as nvarchar(1)) + "'"

				exec @ErrorCode=sp_executesql @sSQLString,
							N'@sDocItemName		nvarchar(40)	Output',
							  @sDocItemName = @sDocItemName		Output
				
				If @ErrorCode = 0 and @sDocItemName is not null and @sDocItemName != ''
						and exists (select * from ITEM WHERE ITEM_NAME = @sDocItemName)
				Begin  
					exec @ErrorCode=dbo.[ipw_FetchDocItem]
								@pnUserIdentityId	= @pnUserIdentityId,		-- Mandatory
								@psCulture		= null,
								@pbCalledFromCentura	= 0,
								@psDocItem		= @sDocItemName,
								@psEntryPoint		= @sCaseIRN, -- CASE
								@psEntryPointP1		= @nLanguage, -- LANGUAGE
								@psEntryPointP2		= @sNameType, --	DEBTOR NAME TYPE
								@psEntryPointP3		= @nDebtorNo, -- DEBTORNO
								@psEntryPointP4		= @psOpenItemNo, -- OPENITEMNO
								@bIsCSVEntryPoint	= 0,
								@pbOutputToVariable	= 1,
								@psOutputString		= @sSQLDocItem output
				End
				
				If @ErrorCode = 0 and @sSQLDocItem is not null and @sSQLDocItem != ''
				Begin
					Set @sSQLString="Update #TEMPCASEDETAILS
							Set DOCITEM" + cast(@nCounter as nvarchar(1)) + " = @sSQLDocItem
							From #TEMPCASEDETAILS where IRN = @sCaseIRN"

					Exec @ErrorCode=sp_executesql @sSQLString,
								N'@sSQLDocItem	nvarchar(max),
								@sCaseIRN	nvarchar(30)',
								@sSQLDocItem	= @sSQLDocItem,
								@sCaseIRN	= @sCaseIRN
				End

				Set @nCounter = @nCounter + 1
			End
			
			FETCH NEXT FROM InvoiceDocItem_Cursor 
			INTO @sCaseIRN
		End
		
		CLOSE InvoiceDocItem_Cursor
		DEALLOCATE InvoiceDocItem_Cursor
	End
End

-- If no Reference Text was extracted for the bill then attempt to get the 
-- details at this time 
If @ErrorCode=0
and exists(select * from @tbItemHeader where RefText is null)
Begin
	-- Get the docitem to use for extracting the Reference Text

	Set @sSQLString="
	Select 	@sSQLDocItem=convert(nvarchar(max),SQL_QUERY),
		@sItemName=S.COLCHARACTER
	From SITECONTROL S
	left join ITEM I on (I.ITEM_NAME=S.COLCHARACTER)
	Where S.CONTROLID='XML Bill Ref-Automatic'"
	
	exec @ErrorCode=sp_executesql @sSQLString,
				N'@sSQLDocItem		nvarchar(max)	Output,
				  @sItemName		nvarchar(254)	Output',
				  @sSQLDocItem=@sSQLDocItem		Output,
				  @sItemName=@sItemName			Output
	set @nRowCount=@@Rowcount

	If @nRowCount>0
	and @ErrorCode=0
	Begin
		-- Check to see if the Site Control is pointing to a Stored Procedure
		-- If it is then the Stored procedure must accept the IRN as an input
		-- and must update the #TEMPCASEDETAILS temporary table with the
		-- Reference Text for the first IRN (ROWORDER=1)

		if exists (select * from sysobjects where id = object_id(@sItemName) 
						    and OBJECTPROPERTY(id, N'IsProcedure') = 1)
		begin
			Set @sSQLString="exec "+@sItemName

			exec @ErrorCode=sp_executesql @sSQLString
		end
		-- The DocItem is a SELECT statement that must return a single column
		-- and single row of data otherwise the UPDATE will fail.
		Else If @sSQLDocItem is not null
		Begin
			Set @sSQLDocItem=replace(@sSQLDocItem,':gstrEntryPoint','#TEMPCASEDETAILS.IRN')
		
			exec ("
			Update #TEMPCASEDETAILS
			Set REFTEXT=("+@sSQLDocItem+")
			From #TEMPCASEDETAILS
			Where ROWORDER=1")
		
			Set @ErrorCode=@@Error
		End
	
		If  @ErrorCode=0
		Begin
			Update @tbItemHeader
			Set RefText=T.REFTEXT
			From @tbItemHeader
			join #TEMPCASEDETAILS T on (T.ROWORDER=1)
			Where T.REFTEXT is not null
	
			Set @ErrorCode=@@Error
		End
	End
End
	

-- Get the Copy To Details
If @ErrorCode=0
and @psResultsRequired = 'Copies'
Begin
	insert into @tbCopyToDetails (CopyToName,CopyToAttention,CopyToAddress)
	select	distinct
		dbo.fn_FormatName(N1.NAME, N1.FIRSTNAME, N1.TITLE, COALESCE(N1.NAMESTYLE, C1.NAMESTYLE, 7101)),
		dbo.fn_FormatName(N2.NAME, N2.FIRSTNAME, N2.TITLE, COALESCE(N2.NAMESTYLE, C2.NAMESTYLE, 7101)),
		dbo.fn_FormatAddress(A.STREET1, A.STREET2, A.CITY, A.STATE, S.STATENAME, A.POSTCODE, CA.POSTALNAME, CA.POSTCODEFIRST, CA.STATEABBREVIATED,CA.POSTCODELITERAL,CA.ADDRESSSTYLE)
	from #TEMPCASEDETAILS T
	join CASENAME CN	on (CN.CASEID=T.CASEID
				and CN.NAMETYPE=CASE WHEN(@bRenewalFlag=1) THEN 'ZC' ELSE'CD' END
				and CN.EXPIRYDATE is null)
	join NAME N1		on (N1.NAMENO=CN.NAMENO)
	left join COUNTRY C1	on (C1.COUNTRYCODE=N1.NATIONALITY)
	left join ADDRESS A	on (A.ADDRESSCODE=N1.POSTALADDRESS)
	left join COUNTRY CA	on (CA.COUNTRYCODE=A.COUNTRYCODE)
	left join STATE S	on (S.COUNTRYCODE=A.COUNTRYCODE
				and S.STATE=A.STATE)
	left join NAME N2	on (N2.NAMENO=isnull(CN.CORRESPONDNAME,N1.MAINCONTACT))
	left join COUNTRY C2	on (C2.COUNTRYCODE=N2.NATIONALITY)

End

If @ErrorCode=0
Begin
	If @psResultsRequired = 'Header'
	Begin 
		Select * from @tbItemHeader
	End
	Else If @psResultsRequired = 'BillLines'
	Begin
		Select * from @tbBillLines TB
		left join #TEMPCASEDETAILS TC on (TC.CASEID = TB.DetailCaseKey)
		order by TB.DetailDisplaySequence
	End
	Else If @psResultsRequired = 'Tax'
	Begin
		Select * from @tbTaxDetails 
		order by TaxRate, TaxDescription
	End
	Else If @psResultsRequired = 'Copies'
	Begin
		Select * from @tbCopyToDetails
		order by CopyToName
	End
End

return @ErrorCode
go

grant execute on dbo.bi_GetInvoiceDetails  to public
go

