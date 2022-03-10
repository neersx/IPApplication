-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xml_GetDebitNoteDetails 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[xml_GetDebitNoteDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.xml_GetDebitNoteDetails.'
	drop procedure dbo.xml_GetDebitNoteDetails
end
print '**** Creating procedure dbo.xml_GetDebitNoteDetails...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.xml_GetDebitNoteDetails
		@psXMLActivityRequestRow	ntext
as
---PROCEDURE :	xml_GetDebitNoteDetails
-- VERSION :	37
-- DESCRIPTION:	A procedure that returns all of the details required on a formatted
--		open item such as a Debit or Credit Note.
--
--		The following details will be returned :
--			OpenItemNo
--			AccountNo
--			YourRef
--			Date
--			RefText
--			TaxLocal
--			TaxForeign
--			CurrencyL
--			LocalValue
--			CurrencyF
--			CurrencyF
--			ForeignValue
--			BillPercentage
--			TaxLabel
--			Tax
--			FmtName
--			FmtAddress
--			FmtAttention
--			StatusText
--			CopyToList
--			CopyToAddress
--			CopyToAttention
--			OurRef
--			PurchaseOrderNo
--			SignOffName
--			Regarding
--			BillScope
--			Reductions
--			CreditNoteF
--			ReductionsForeign
--			TaxNo
--			CopyLabel
--			Image
--			ForeignEquivCurrency
--			ForeignEquivExRate
--			PenaltyInterestRate
--			ItemTypeAbbreviation
--			DueDate
--			LocalTakenUp
--			ForeignTakenUp
--			
--			TaxRate1
--			TaxableAmount1
--			TaxAmount1
--			TaxDescription1
--			TaxRate2
--			TaxableAmount2
--			TaxAmount2
--			TaxDescription2
--			TaxRate3
--			TaxableAmount3
--			TaxAmount3
--			TaxDescription3
--			TaxRate4
--			TaxableAmount4
--			TaxAmount4
--			TaxDescription4
--			
--
--			DisplaySequence
--			DetailChargeRate
--			DetailStaffName
--			DetailDate
--			DetailInternalRef
--			DetailYourRef
--			DetailTime
--			DetailWIPCode
--			DetailWIPTypeId
--			DetailCatDesc
--			DetailNarrative
--			DetailValue
--			DetailForeignValue
--			DetailChargeCurr
--			DetailCaseSequence
--			DetailStaffClass
--			DetailCaseCountryCode
--			DetailCaseCountry
--			DetailCaseTypeDesc
--			DetailPropertyType
--			DetailOfficialNo
--			DetailCaseTitle
--			DetailStaffCode
--			DetailStaffInit
--			DetailCasePurchaseOrder
--			DetailFeeEarnerName
--			DetailFeeEarnerStaffClass
--			DetailFeeEarnerStaffCode
--			DetailFeeEarnerStaffInit

--			DetailRefDocItem1
--			DetailRefDocItem2
--			DetailRefDocItem3
--			DetailRefDocItem4
--			DetailRefDocItem5
--			DetailRefDocItem6
	
-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 02 Dec 2003	MF	7074		Procedure created as bi_GetDebitNoteDetails
-- 09 Dec 2003  AvdA	7074		xml version created based on bi_GetDebitNoteDetails
-- 03 Jul 2004	MF	10253	2	Additional details to be returned
-- 06 Jul 2004	MF	10253	3	Revisit to correct problem with YourRef extraction.
-- 13 Jul 2004	MF	10275	4	Report the Employee Name Code for detail lines.
-- 22 Jul 2004	MF	10307	5	Report the Purchase Order No against the Case.
-- 26 Aug 2004	MF		6	Get Case details from Workhistory if the BillLine
--					details do not contain the IRN information.
-- 06 Aug 2004	AB	8035	6	Add collate database_default to temp table definitions
-- 26 Aug 2004	IB	10397	7	Check for a null value for @psXMLActivityRequestRow parameter
--					and raise an error before attempting to open the XML document.
-- 14 Sep 2004	MF	10461	8	Default the name on bill lines to the Case staff member if there is not
--					a specific name against the bill line.
-- 29-Sep-2004	TM	RFC1806	9	Pass the new parameter and to pass the country postal name instead of the country
--					name to the fn_FormatAddress.
-- 18 Nov 2004	MF	10670	10	Incorrect staff code was being returned because WorkHistory was not joined
---					to the BillLineNo.
-- 25 Nov 2004	MF	10708	11	If the no ReferenceText exists for the bill then attempt to generate it at this
--					time by using the DOCITEM approach.
-- 30 Nov 2004	MF	10708	12	When extracting the ReferenceText allow for a stored
--					procedure as an alternative to a DocItem.
-- 02 Dec 2004	MF	10760	13	Change the newly created Site Control from 'BILL REF-AUTOMATIC' to
--					'XML BILL REF-AUTOMATIC' as it is clashing with our BILLING program.
-- 08 Dec 2004	MF	10778	14	Do not extract time into bill lines if there is no charge out rate.
-- 24 Aug 2005	MF	11778	15	Doc Items that are pointing to a stored procedure are causing the extract of
--					data to fail.
-- 18 May 2006	MF	12688	16	Extract a real person that is associated with each detail line.  This is
--					because the Name may in fact be a department.  Additional fields are included.
-- 10 Oct 2006	MF	13589	17	Truncation error on Our Ref and Your Ref when large number of cases on one bill.
--					Increase columns to 1000 bytes.
-- 16 Jan 2008	Dw	9782	18	TaxNo moved from Organisation to Name table.
-- 19 Mar 2008	vql	SQA14773 19     Make PurchaseOrderNo nvarchar(80)
-- 17 Jul 2008	MF	16231	20	Determine the correct NameType to use by looking at the RENEWALDEBTORFLAG
--					on the OPENITEM table.  Also pass additional parameters to DocItems used for Bill details.
-- 15 Dec 2008	MF	17136	21	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID	
-- 25 Mar 2010	MF	18016	22	Take into consideration the billing percentage associated with the open item and report details
--					adjusted to that percentage.
-- 04 Jun 2010	MF	18703	23	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE which need to be null
-- 08 Feb 2012	MF	R11654	24	Wrong NameType was being used to get the Signatory against the Case.
-- 13 Feb 2012	MF	S20350	25	Name Code returned for Staff member against Bill Line is not always accurate.
-- 06 Jun 2012	MF	R12388	26	Do not repeat Your Ref, Our Ref or Purchase Order No for bills with multiple Cases.
-- 27 Mar 2013	MF	S21327	27	The openitem may use LONGREFTEXT instead of REFERENCETEXT.
-- 08 Jul 2013	MF	R13641	28	Return the initials of the staff name associated with the bill lines.
-- 27 Feb 2014	DL	21508	29	Change variables and temp table columns that reference namecode to 20 characters
-- 18 Jul 2014	MF	R37491	30	Initials displaying incorrectly for Bills with multiple fee earners.
-- 09 Dec 2014	MF	R41091	31	Staff classification not always being returned.
-- 17 Mar 2015	MF	R45808	32	Revisit 37491 to handle the possibility of multiple names existing with identical SignOffName.
-- 20 Apr 2015	MF	R46357	33	Change manner in which Purchase Order is being extracted as it is sometime returning a value for the 
--					case when it should be Null and fall through to use the PO against the Name.
-- 14 May 2015	MF	47389	34	Return the debtor's reference in each bill line being returned.
-- 20 Oct 2015  MS      R53933  35      Changed size from decimal(8,4) to decimal(11,4) for rate cols
-- 02 Nov 2015	vql	R53910	36	Adjust formatted names logic (DR-15543).
-- 17 Oct 2017	LP	R72494	37	Remove join to ACTIVITYHISTORY when Bill Line does not have IRN
		
set nocount on
set concat_null_yields_null off

-- Store the Case details for each Case on the bill loaded from 
-- user defined queries and held in a Temporary Table (required because of dynamic SQL)
-- The size of the DocItem columns may need to be varied depending on 
-- the results to be loaded into these columns.
Create table #TEMPCASEDETAILS (
			CASEID			int		NOT NULL,
			IRN			nvarchar(30)	collate database_default NOT NULL,
			DOCITEM1		nvarchar(1000)	collate database_default NULL,
			DOCITEM2		nvarchar(1000)	collate database_default NULL,
			DOCITEM3		nvarchar(500)	collate database_default NULL,
			DOCITEM4		nvarchar(500)	collate database_default NULL,
			DOCITEM5		nvarchar(500)	collate database_default NULL,
			DOCITEM6		nvarchar(400)	collate database_default NULL,
			REFTEXT			nvarchar(max)	collate database_default NULL,
			ROWORDER		smallint	identity(1,1)
			)

-- Store the required information in a table variable
Declare @tbItemHeader table (
			OpenItemNo		nvarchar(12)	collate database_default NULL,
			AccountNo		nvarchar(60)	collate database_default NULL,
			YourRef			nvarchar(1000)	collate database_default NULL,
			ItemDate		datetime	NULL,
			RefText			nvarchar(max)	NULL,
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
			PurchaseOrderNo		nvarchar(80)	collate database_default NULL,
			SignOffName		nvarchar(100)	collate database_default NULL,
			Regarding		nvarchar(max)	collate database_default NULL,
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
			ForeignTakenUp		decimal(11,2)	NULL
			)

Declare @tbBillLines table (
			DetailDisplaySequence	smallint	NULL,
			DetailChargeOutRate	decimal(11,2)	NULL,
			DetailStaffName		nvarchar(60)	collate database_default NULL,
			DetailDate		datetime	NULL,
			DetailIRN		nvarchar(30)	collate database_default NULL,	
			DetailYourRef		nvarchar(80)	collate database_default NULL,
			DetailTime		nvarchar(30)	collate database_default NULL,
			DetailWIPCode		nvarchar(6)	collate database_default NULL,
			DetailWIPTypeId		nvarchar(6)	collate database_default NULL,
			DetailCatDesc		nvarchar(50)	collate database_default NULL,
			DetailNarrative		nvarchar(3000)	collate database_default NULL,
			DetailValue		decimal(11,2)	NULL,
			DetailForeignValue	decimal(11,2)	NULL,
			DetailChargeCurr	nvarchar(3)	collate database_default NULL,
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
			DetailFeeEarnerName	  nvarchar(60)	collate database_default NULL,
			DetailFeeEarnerStaffClass nvarchar(80)	collate database_default NULL,
			DetailFeeEarnerStaffCode  nvarchar(20)	collate database_default NULL,
			DetailFeeEarnerStaffInit  nvarchar(10)	collate database_default NULL
			)

-- Store the tax summary information in a table variable
Declare @tbTaxDetails table (
			TaxRate			decimal(11,4)	NULL,
			TaxableAmount		decimal(11,2)	NULL,
			TaxAmount		decimal(11,2)	NULL,
			TaxDescription		nvarchar(30)	collate database_default NULL
			)

-- Store the tax summary information in a table variable
Declare @tbCopyToDetails table (
			CopyToName		nvarchar(254)	collate database_default NULL,
			CopyToAttention		nvarchar(254)	collate database_default NULL,
			CopyToAddress		nvarchar(254)	collate database_default NULL
			)

Declare		@ErrorCode	int
Declare		@nRowCount	int

Declare		@sSQLString	nvarchar(4000)
Declare		@sSQLDocItem	nvarchar(4000)
Declare		@sItemName	nvarchar(254)
Declare		@sYourRef	nvarchar(1000)
Declare		@sOurRef	nvarchar(1000)
Declare		@sPurchaseNo	nvarchar(1000)

Declare		@hDocument 	int 			-- handle to the XML parameter which is the Activity Request row
Declare		@nEntityNo	int 			-- the entityno of the debitnote
Declare		@nLanguage	int 			-- the language of the debitnote
Declare		@nDebtorNo	int			-- the debtorno of the debitnot
Declare		@sOpenItemNo	nvarchar(12) 		-- the openitemno of the debitnote
Declare		@sNameType	nvarchar(3) 		-- the NameType of the debitnote
Declare		@nBillPercent	decimal(5,4)		-- the percentage of the original Billed items included in this debit note coverted to decimal

Declare		@bRenewalFlag	bit			-- indicates the Renewal Debtor was used for bill
	
Set @ErrorCode = 0

-- First, check for a null value or emptiness of the @psXMLActivityRequestRow parameter
-- and raise an error before attempting to open the XML document.
If @psXMLActivityRequestRow is null or Substring(@psXMLActivityRequestRow, 1, 1) = ''
Begin	
	Raiserror('Activity request row XML parameter is empty.', 16, 1)
	Set 	@ErrorCode = @@Error
End

-- Second collect the key for the Activity Request row that has been passed as an XML parameter using OPENXML functionality.
If @ErrorCode = 0
Begin	
	Exec 	sp_xml_preparedocument  @hDocument OUTPUT, @psXMLActivityRequestRow
	Set 	@ErrorCode = @@Error
End
-- Now select the key from the xml, at the same time joining it to the ACTIVITYREQUEST table.
If @ErrorCode = 0
Begin
	Set @sSQLString="
	select 	@nEntityNo = ENTITYNO,
		@sOpenItemNo = DEBITNOTENO
		from openxml(@hDocument,'ACTIVITYREQUEST',2)
		with ACTIVITYREQUEST "
	Exec @ErrorCode=sp_executesql @sSQLString,
		N'@nEntityNo		int     		OUTPUT,
		  @sOpenItemNo		nvarchar(40)		OUTPUT,
		  @hDocument		int',
		  @nEntityNo		= @nEntityNo		OUTPUT,
		  @sOpenItemNo 		= @sOpenItemNo		OUTPUT,
		  @hDocument 		= @hDocument
End
If @ErrorCode = 0	
Begin	
	Exec sp_xml_removedocument @hDocument 
	Set @ErrorCode	  = @@Error
End

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode = 0

-- Get the Clients Reference, Our Reference and Purchase Order Nos,
-- Language, DebtorNo and NameType
-- for all Cases being billed separated by a comma
If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sYourRef =   CASE WHEN CN.REFERENCENO IS NULL THEN @sYourRef                   -- no reference, not change to string 
                                  WHEN CHARINDEX(CN.REFERENCENO, @sYourRef) > 0 THEN @sYourRef -- already in string don’t append 
                                  WHEN @sYourRef IS NULL THEN CN.REFERENCENO                   -- first time a ref found
                                  ELSE @sYourRef + ', '  + CN.REFERENCENO                      -- append with a comma separator
			     END,
              @sOurRef =     CASE WHEN C.IRN IS NULL THEN @sOurRef
                                  WHEN CHARINDEX(C.IRN, @sOurRef) > 0 THEN @sOurRef
                                  WHEN @sOurRef is NULL THEN C.IRN
                                  ELSE @sOurRef + ', ' + C.IRN
			     END,
              @sPurchaseNo=  CASE WHEN C.PURCHASEORDERNO IS NULL THEN @sPurchaseNo
                                  WHEN CHARINDEX(C.PURCHASEORDERNO, @sPurchaseNo) > 0  THEN  @sPurchaseNo
                                  WHEN @sPurchaseNo IS NULL THEN  C.PURCHASEORDERNO
                                  ELSE @sPurchaseNo + ', '+ C.PURCHASEORDERNO
			     END,
	       @bRenewalFlag=cast(O.RENEWALDEBTORFLAG as bit),
	       @nLanguage	=isnull(O.LANGUAGE,S.COLINTEGER),
	       @nDebtorNo	=O.ACCTDEBTORNO,
	       @sNameType	=CASE WHEN(O.RENEWALDEBTORFLAG=1) THEN 'Z' ELSE 'D' END,
	       @nBillPercent	=isnull(O.BILLPERCENTAGE,100)/100
	from OPENITEM O
	join (	select  REFENTITYNO, REFTRANSNO, CASEID
		from WORKHISTORY
		group by REFENTITYNO, REFTRANSNO, CASEID) WH
				on (WH.REFENTITYNO=O.ITEMENTITYNO
				and WH.REFTRANSNO =O.ITEMTRANSNO)
	join CASES C		on (C.CASEID=WH.CASEID)
	left join CASENAME CN	on (CN.CASEID=C.CASEID
				and CN.NAMENO=O.ACCTDEBTORNO
				and CN.NAMETYPE=CASE WHEN(O.RENEWALDEBTORFLAG=1) THEN 'Z' ELSE 'D' END)
	left join SITECONTROL S	on (S.CONTROLID='LANGUAGE')
	where O.OPENITEMNO=@sOpenItemNo
	and O.ITEMENTITYNO=@nEntityNo
	order by C.IRN"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sOpenItemNo		nvarchar(12),
					  @nEntityNo		int,
					  @sYourRef		nvarchar(1000)	OUTPUT,
					  @sOurRef		nvarchar(1000)	OUTPUT,
					  @sPurchaseNo		nvarchar(1000)	OUTPUT,
					  @bRenewalFlag		bit		OUTPUT,
					  @nLanguage		int		OUTPUT,
					  @nDebtorNo		int		OUTPUT,
					  @sNameType		nvarchar(3)	OUTPUT,
					  @nBillPercent		decimal(5,4)	OUTPUT',
					  @sOpenItemNo=@sOpenItemNo,
					  @nEntityNo=@nEntityNo,
					  @sYourRef=@sYourRef			OUTPUT,
					  @sOurRef=@sOurRef			OUTPUT,
					  @sPurchaseNo=@sPurchaseNo		OUTPUT,
					  @bRenewalFlag=@bRenewalFlag		OUTPUT,
					  @nLanguage=@nLanguage			OUTPUT,
					  @nDebtorNo=@nDebtorNo			OUTPUT,
					  @sNameType=@sNameType			OUTPUT,
					  @nBillPercent=@nBillPercent		OUTPUT
End

If @ErrorCode=0
Begin
	insert into @tbItemHeader
	select 		O.OPENITEMNO,
			isnull(NA.ALIAS,N.NAMECODE),
			@sYourRef,  -- Clients reference separated by semi colon
			O.ITEMDATE,
			coalesce(O.LONGREFTEXT,O.REFERENCETEXT),	-- SQA21327
			O.LOCALTAXAMT,
			O.FOREIGNTAXAMT,
			S1.COLCHARACTER, -- Local Currency
			O.LOCALVALUE,
			O.CURRENCY,
			CASE WHEN(O.CURRENCY<>S1.COLCHARACTER) THEN 1 ELSE 0 END, -- Flag indicates foreign currency
			O.FOREIGNVALUE,
			O.BILLPERCENTAGE,
			S2.COLCHARACTER, -- Tax literal
			CASE WHEN(O.LOCALTAXAMT<>0) THEN 1 ELSE 0 END,
			NS.FORMATTEDNAME,
			NS.FORMATTEDADDRESS,
			NS.FORMATTEDATTENTION,
			CASE WHEN(O.STATUS=0) THEN 'DRAFT' END,
			@sOurRef,	-- IRNs separated by Semi Colon
			isnull(@sPurchaseNo,IP.PURCHASEORDERNO),-- Purchase Orders from Cases separated by Semicolon OR Purchase Order from IPNAME
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
			O.FOREIGNORIGTAKENUP
	from OPENITEM O
	join NAME N			on (N.NAMENO=O.ACCTDEBTORNO)
	left join IPNAME IP		on (IP.NAMENO=N.NAMENO)
	left join NAMEALIAS NA		on (NA.NAMENO=N.NAMENO
					and NA.ALIASTYPE='D'
					and NA.COUNTRYCODE  is null
					and NA.PROPERTYTYPE is null)
	left join SITECONTROL S1	on (S1.CONTROLID='CURRENCY')
	left join SITECONTROL S2	on (S2.CONTROLID='TAXLITERAL')
	     join NAMEADDRESSSNAP NS	on (NS.NAMESNAPNO=O.NAMESNAPNO)
	left join EMPLOYEE E		on (E.EMPLOYEENO=O.EMPLOYEENO)
	where O.OPENITEMNO=@sOpenItemNo
	and O.ITEMENTITYNO=@nEntityNo

	Set @ErrorCode=@@Error
End

-- Get the Bill Line Details
-- Note that if the Bill Line does not contain the IRN details then revert to the 
-- WorkHistory rows to get the details required.
If @ErrorCode=0
Begin
	Insert into @tbBillLines(DetailDisplaySequence, DetailChargeOutRate, 
				DetailStaffName, DetailDate, DetailIRN, DetailYourRef, DetailTime, 
				DetailWIPCode, DetailWIPTypeId, DetailCatDesc, 
				DetailNarrative, DetailValue, DetailForeignValue, 
				DetailChargeCurr, DetailStaffClass, DetailStaffCode,DetailStaffInit,
				DetailCaseCountryCode, DetailCaseCountry, DetailCaseTypeDesc, 
				DetailPropertyType, DetailOfficialNo, DetailCaseTitle, DetailCasePurchaseOrder)
	select 	B.DISPLAYSEQUENCE, 
		B.PRINTCHARGEOUTRATE,
		isnull(dbo.fn_FormatNameUsingNameNo(N.NAMENO, 7101),B.PRINTNAME), -- SQA20350 Swapped the order of ISNULL around to avoid possible mismatch
		B.PRINTDATE, 
		C.IRN, 
		D.REFERENCENO,
		CASE WHEN(B.PRINTCHARGEOUTRATE IS NOT NULL) THEN B.PRINTTIME END,
		B.WIPCODE, 
		B.WIPTYPEID, 
		W.DESCRIPTION, 
		CASE WHEN(datalength(LONGNARRATIVE)>0) THEN convert(nvarchar(3500),LONGNARRATIVE) ELSE SHORTNARRATIVE END,
		@nBillPercent * isnull(B.VALUE,0), 
		@nBillPercent * isnull(B.FOREIGNVALUE,0),
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
		C.PURCHASEORDERNO
	from OPENITEM O
	join BILLLINE B		on (B.ITEMENTITYNO=O.ITEMENTITYNO
      		  		and B.ITEMTRANSNO =O.ITEMTRANSNO)
	join CASES C		on (C.IRN=B.IRN)
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
	left join CASENAME D	on (D.CASEID  =C.CASEID
				and D.NAMETYPE=@sNameType
				and D.NAMENO  =@nDebtorNo)
	left join WIPCATEGORY W	on (W.CATEGORYCODE=B.CATEGORYCODE)
	left join EMPLOYEE E	on (E.EMPLOYEENO=isnull((select min(WH.EMPLOYEENO)
							from WORKHISTORY WH
							Where WH.REFENTITYNO=O.ITEMENTITYNO
							and WH.REFTRANSNO =O.ITEMTRANSNO
							and WH.BILLLINENO =B.ITEMLINENO
							and WH.MOVEMENTCLASS=2	-- SQA20350 Use Billing movement class to exclude write ups/downs.
							and WH.EMPLOYEENO is not null),EMP.NAMENO)
				and E1.EMPLOYEENO  is null)
	left join TABLECODES T	on (T.TABLECODE=isnull(E1.STAFFCLASS,E.STAFFCLASS))
	left join NAME N	on (N.NAMENO=isnull(E1.EMPLOYEENO,E.EMPLOYEENO))
	left join COUNTRY CN	on (CN.COUNTRYCODE=C.COUNTRYCODE)
	left join CASETYPE CT	on (CT.CASETYPE=C.CASETYPE)
	left join VALIDPROPERTY VP	on (VP.PROPERTYTYPE=C.PROPERTYTYPE
					and VP.COUNTRYCODE=(	select min(VP1.COUNTRYCODE)
								from VALIDPROPERTY VP1
								where VP1.PROPERTYTYPE=VP.PROPERTYTYPE
								and VP1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
	where O.OPENITEMNO=@sOpenItemNo
	and O.ITEMENTITYNO=@nEntityNo
	UNION ALL
	select 	B.DISPLAYSEQUENCE, 
		B.PRINTCHARGEOUTRATE,
		isnull(B.PRINTNAME,dbo.fn_FormatNameUsingNameNo(N.NAMENO, 7101)),
		isnull(B.PRINTDATE,WH.TRANSDATE), 
		C.IRN,
		D.REFERENCENO,
		CASE WHEN(B.PRINTCHARGEOUTRATE IS NOT NULL) THEN B.PRINTTIME END,
		WH.WIPCODE, 
		WT.WIPTYPEID, 
		W.DESCRIPTION, 
		CASE WHEN(datalength(isnull(B.LONGNARRATIVE,WH.LONGNARRATIVE))>0) THEN convert(nvarchar(3500),isnull(B.LONGNARRATIVE,WH.LONGNARRATIVE)) ELSE isnull(B.SHORTNARRATIVE,WH.SHORTNARRATIVE) END,
		@nBillPercent * isnull(B.VALUE,0) *-1, 
		@nBillPercent * isnull(B.FOREIGNVALUE,0),
		O.CURRENCY,
		T.DESCRIPTION,
		N.NAMECODE,
		N.INITIALS,
		C.COUNTRYCODE,
		CN.COUNTRY,
		CT.CASETYPEDESC,
		VP.PROPERTYNAME,
		C.CURRENTOFFICIALNO,
		C.TITLE,
		C.PURCHASEORDERNO
	from OPENITEM O
	join BILLLINE B		on (B.ITEMENTITYNO=O.ITEMENTITYNO
      		  		and B.ITEMTRANSNO =O.ITEMTRANSNO)
	join WORKHISTORY WH	on (WH.REFENTITYNO=O.ITEMENTITYNO
				and WH.REFTRANSNO =O.ITEMTRANSNO
				and WH.BILLLINENO =B.ITEMLINENO)
	join WIPTEMPLATE WP	on (WP.WIPCODE    =WH.WIPCODE)
	join WIPTYPE WT		on (WT.WIPTYPEID  =WP.WIPTYPEID)
	join WIPCATEGORY W	on (W.CATEGORYCODE=WT.CATEGORYCODE)	
	left join CASENAME EMP	on (EMP.CASEID=WH.CASEID
				and EMP.NAMETYPE='EMP'
				and EMP.EXPIRYDATE is null)
	left join EMPLOYEE E	on (E.EMPLOYEENO=isnull(WH.EMPLOYEENO,EMP.NAMENO))
	left join CASES C	on (C.CASEID=WH.CASEID)
	left join CASENAME D	on (D.CASEID  =C.CASEID
				and D.NAMETYPE=@sNameType
				and D.NAMENO  =@nDebtorNo)
	left join TABLECODES T	on (T.TABLECODE=E.STAFFCLASS)
	left join NAME N	on (N.NAMENO=E.EMPLOYEENO)
	left join COUNTRY CN	on (CN.COUNTRYCODE=C.COUNTRYCODE)
	left join CASETYPE CT	on (CT.CASETYPE=C.CASETYPE)
	left join VALIDPROPERTY VP	on (VP.PROPERTYTYPE=C.PROPERTYTYPE
					and VP.COUNTRYCODE=(	select min(VP1.COUNTRYCODE)
								from VALIDPROPERTY VP1
								where VP1.PROPERTYTYPE=VP.PROPERTYTYPE
								and VP1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
	where O.OPENITEMNO=@sOpenItemNo
	and O.ITEMENTITYNO=@nEntityNo
	and (B.IRN is null OR B.IRN = '')

	Set @ErrorCode=@@Error
End

If @ErrorCode=0
Begin
	-- The staff member that may be recorded against the work performed may be a department
	-- rather than a real person.  The following additional fields are being populated
	-- with a real person by first looking at the Name associated with the work performed, 
	-- the Employee against the Case, and finally the signatory against the Case.
	Update @tbBillLines
	Set	DetailFeeEarnerName      =CASE WHEN(I1.SEX<>'D') THEN T.DetailStaffName
					       WHEN(I2.SEX<>'D') THEN dbo.fn_FormatNameUsingNameNo(N2.NAMENO, 7101)
					       WHEN(I3.SEX<>'D') THEN dbo.fn_FormatNameUsingNameNo(N3.NAMENO, 7101)
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
				and SIG.NAMETYPE='SIG'		-- RFC11654
				and SIG.EXPIRYDATE is null)
	left join EMPLOYEE E3	on (E3.EMPLOYEENO=SIG.NAMENO)
	left join INDIVIDUAL I3	on (I3.NAMENO=SIG.NAMENO)
	left join NAME N3	on (N3.NAMENO=SIG.NAMENO)
	left join TABLECODES S3 on (S3.TABLECODE=E3.STAFFCLASS)

	Set @ErrorCode=@@Error
End
				

-- Get the total of the lines that reduce the overall
-- value of the Open Item.
If @ErrorCode=0
Begin
	If exists(select * from @tbItemHeader where CreditNoteFlag=0)
		update @tbItemHeader
		set Reductions       =@nBillPercent * isnull(R.ReductionTotal,0),
		    ReductionsForeign=@nBillPercent * isnull(R.ReductionForeignTotal,0)
		from @tbItemHeader T
		join (	select	sum(DetailValue) as ReductionTotal, sum(DetailForeignValue) as ReductionForeignTotal
			from @tbBillLines
			where DetailValue<0) R on (1=1)
	Else
		update @tbItemHeader
		set Reductions       =@nBillPercent * isnull(R.ReductionTotal,0),
		    ReductionsForeign=@nBillPercent * isnull(R.ReductionForeignTotal,0)
		from @tbItemHeader T
		join (	select	sum(DetailValue) as ReductionTotal, sum(DetailForeignValue) as ReductionForeignTotal
			from @tbBillLines
			where DetailValue>0) R on (1=1)

	set @ErrorCode=@@Error
End

-- Get the tax details
If @ErrorCode=0
Begin
	Insert into @tbTaxDetails (TaxRate, TaxableAmount, TaxAmount, TaxDescription)
	select	OT.TAXRATE, 
		@nBillPercent * isnull(OT.TAXABLEAMOUNT, 0),
		@nBillPercent * isnull(OT.TAXAMOUNT, 0),
		T.DESCRIPTION
	from OPENITEM O
	join OPENITEMTAX OT	on (OT.ITEMENTITYNO=O.ITEMENTITYNO
        			and OT.ITEMTRANSNO =O.ITEMTRANSNO
        			and OT.ACCTENTITYNO=O.ACCTENTITYNO
       				and OT.ACCTDEBTORNO=O.ACCTDEBTORNO)
	join TAXRATES T		on (T.TAXCODE=OT.TAXCODE)
	where O.OPENITEMNO=@sOpenItemNo
	and O.ITEMENTITYNO=@nEntityNo

	Set @ErrorCode=@@Error
End

-- Get the user defined details associated with each Case.

If @ErrorCode=0
Begin
	insert into #TEMPCASEDETAILS(CASEID, IRN)
	Select C.CASEID, C.IRN 
	from OPENITEM O
	join BILLLINE B		on (B.ITEMENTITYNO=O.ITEMENTITYNO
      		  		and B.ITEMTRANSNO =O.ITEMTRANSNO)
	join CASES C		on (C.IRN=B.IRN)
	where O.OPENITEMNO=@sOpenItemNo
	and O.ITEMENTITYNO=@nEntityNo
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
		insert into #TEMPCASEDETAILS(CASEID, IRN)
		Select distinct C.CASEID, C.IRN 
		from OPENITEM O
		join WORKHISTORY WH	on (WH.REFENTITYNO=O.ITEMENTITYNO
	      		  		and WH.REFTRANSNO =O.ITEMTRANSNO)
		join CASES C		on (C.CASEID=WH.CASEID)
		where O.OPENITEMNO=@sOpenItemNo
		and O.ITEMENTITYNO=@nEntityNo
		order by C.IRN
	
		Select	@ErrorCode=@@Error,
			@nRowCount=@@Rowcount
	End

	-- If there are Cases against the Bill now see if any user defined
	-- Doc Items have been defined.
	If  @ErrorCode=0
	and @nRowCount>0
	Begin
		-- Get Doc Item 1
		Set @sSQLString="
		Select @sSQLDocItem=convert(nvarchar(4000),SQL_QUERY)
		From SITECONTROL S
		join ITEM I on (I.ITEM_NAME=S.COLCHARACTER
		            and I.ITEM_TYPE=0)
		Where S.CONTROLID='Bill Ref Doc Item 1'"
	
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@sSQLDocItem		nvarchar(4000)	Output',
					  @sSQLDocItem=@sSQLDocItem		Output
		set @nRowCount=@@Rowcount

		If  @ErrorCode=0
		and @nRowCount>0
		Begin
			Set @sSQLDocItem=replace(@sSQLDocItem,':gstrEntryPoint','#TEMPCASEDETAILS.IRN')
			If @nLanguage is not null
				Set @sSQLDocItem=replace(@sSQLDocItem,':p1',@nLanguage)
			Set @sSQLDocItem=replace(@sSQLDocItem,':p2',''''+@sNameType+'''')
			Set @sSQLDocItem=replace(@sSQLDocItem,':p3',@nDebtorNo)
			Set @sSQLDocItem=replace(@sSQLDocItem,':p4',''''+@sOpenItemNo+'''')
		
			Set @sSQLString="
			Update #TEMPCASEDETAILS
			Set DOCITEM1=("+@sSQLDocItem+")
			From #TEMPCASEDETAILS"

			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- Get Doc Item 2
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Select @sSQLDocItem=convert(nvarchar(4000),SQL_QUERY)
			From SITECONTROL S
			join ITEM I on (I.ITEM_NAME=S.COLCHARACTER
		                    and I.ITEM_TYPE=0)
			Where S.CONTROLID='Bill Ref Doc Item 2'"
		
			exec @ErrorCode=sp_executesql @sSQLString,
						N'@sSQLDocItem		nvarchar(4000)	Output',
						  @sSQLDocItem=@sSQLDocItem		Output
			set @nRowCount=@@Rowcount
		End

		If  @ErrorCode=0
		and @nRowCount>0
		Begin
			Set @sSQLDocItem=replace(@sSQLDocItem,':gstrEntryPoint','#TEMPCASEDETAILS.IRN')
			If @nLanguage is not null
				Set @sSQLDocItem=replace(@sSQLDocItem,':p1',@nLanguage)
			Set @sSQLDocItem=replace(@sSQLDocItem,':p2',''''+@sNameType+'''')
			Set @sSQLDocItem=replace(@sSQLDocItem,':p3',@nDebtorNo)
			Set @sSQLDocItem=replace(@sSQLDocItem,':p4',''''+@sOpenItemNo+'''')
		
			Set @sSQLString="
			Update #TEMPCASEDETAILS
			Set DOCITEM2=("+@sSQLDocItem+")
			From #TEMPCASEDETAILS"
		
			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- Get Doc Item 3
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Select @sSQLDocItem=convert(nvarchar(4000),SQL_QUERY)
			From SITECONTROL S
			join ITEM I on (I.ITEM_NAME=S.COLCHARACTER
		                    and I.ITEM_TYPE=0)
			Where S.CONTROLID='Bill Ref Doc Item 3'"
		
			exec @ErrorCode=sp_executesql @sSQLString,
						N'@sSQLDocItem		nvarchar(4000)	Output',
						  @sSQLDocItem=@sSQLDocItem		Output
			set @nRowCount=@@Rowcount
		End

		If  @ErrorCode=0
		and @nRowCount>0
		Begin
			Set @sSQLDocItem=replace(@sSQLDocItem,':gstrEntryPoint','#TEMPCASEDETAILS.IRN')
			If @nLanguage is not null
				Set @sSQLDocItem=replace(@sSQLDocItem,':p1',@nLanguage)
			Set @sSQLDocItem=replace(@sSQLDocItem,':p2',''''+@sNameType+'''')
			Set @sSQLDocItem=replace(@sSQLDocItem,':p3',@nDebtorNo)
			Set @sSQLDocItem=replace(@sSQLDocItem,':p4',''''+@sOpenItemNo+'''')
		
			Set @sSQLString="
			Update #TEMPCASEDETAILS
			Set DOCITEM3=("+@sSQLDocItem+")
			From #TEMPCASEDETAILS"
		
			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- Get Doc Item 4
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Select @sSQLDocItem=convert(nvarchar(4000),SQL_QUERY)
			From SITECONTROL S
			join ITEM I on (I.ITEM_NAME=S.COLCHARACTER
		                    and I.ITEM_TYPE=0)
			Where S.CONTROLID='Bill Ref Doc Item 4'"
		
			exec @ErrorCode=sp_executesql @sSQLString,
						N'@sSQLDocItem		nvarchar(4000)	Output',
						  @sSQLDocItem=@sSQLDocItem		Output
			set @nRowCount=@@Rowcount
		End

		If  @ErrorCode=0
		and @nRowCount>0
		Begin
			Set @sSQLDocItem=replace(@sSQLDocItem,':gstrEntryPoint','#TEMPCASEDETAILS.IRN')
			If @nLanguage is not null
				Set @sSQLDocItem=replace(@sSQLDocItem,':p1',@nLanguage)
			Set @sSQLDocItem=replace(@sSQLDocItem,':p2',''''+@sNameType+'''')
			Set @sSQLDocItem=replace(@sSQLDocItem,':p3',@nDebtorNo)
			Set @sSQLDocItem=replace(@sSQLDocItem,':p4',''''+@sOpenItemNo+'''')
		
			Set @sSQLString="
			Update #TEMPCASEDETAILS
			Set DOCITEM4=("+@sSQLDocItem+")
			From #TEMPCASEDETAILS"
		
			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- Get Doc Item 5
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Select @sSQLDocItem=convert(nvarchar(4000),SQL_QUERY)
			From SITECONTROL S
			join ITEM I on (I.ITEM_NAME=S.COLCHARACTER
		                    and I.ITEM_TYPE=0)
			Where S.CONTROLID='Bill Ref Doc Item 5'"
		
			exec @ErrorCode=sp_executesql @sSQLString,
						N'@sSQLDocItem		nvarchar(4000)	Output',
						  @sSQLDocItem=@sSQLDocItem		Output
			set @nRowCount=@@Rowcount
		End

		If  @ErrorCode=0
		and @nRowCount>0
		Begin
			Set @sSQLDocItem=replace(@sSQLDocItem,':gstrEntryPoint','#TEMPCASEDETAILS.IRN')
			If @nLanguage is not null
				Set @sSQLDocItem=replace(@sSQLDocItem,':p1',@nLanguage)
			Set @sSQLDocItem=replace(@sSQLDocItem,':p2',''''+@sNameType+'''')
			Set @sSQLDocItem=replace(@sSQLDocItem,':p3',@nDebtorNo)
			Set @sSQLDocItem=replace(@sSQLDocItem,':p4',''''+@sOpenItemNo+'''')
		
			Set @sSQLString="
			Update #TEMPCASEDETAILS
			Set DOCITEM5=("+@sSQLDocItem+")
			From #TEMPCASEDETAILS"
		
			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- Get Doc Item 6
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Select @sSQLDocItem=convert(nvarchar(4000),SQL_QUERY)
			From SITECONTROL S
			join ITEM I on (I.ITEM_NAME=S.COLCHARACTER
		                    and I.ITEM_TYPE=0)
			Where S.CONTROLID='Bill Ref Doc Item 6'"
		
			exec @ErrorCode=sp_executesql @sSQLString,
						N'@sSQLDocItem		nvarchar(4000)	Output',
						  @sSQLDocItem=@sSQLDocItem		Output
			set @nRowCount=@@Rowcount
		End

		If  @ErrorCode=0
		and @nRowCount>0
		Begin
			Set @sSQLDocItem=replace(@sSQLDocItem,':gstrEntryPoint','#TEMPCASEDETAILS.IRN')
			If @nLanguage is not null
				Set @sSQLDocItem=replace(@sSQLDocItem,':p1',@nLanguage)
			Set @sSQLDocItem=replace(@sSQLDocItem,':p2',''''+@sNameType+'''')
			Set @sSQLDocItem=replace(@sSQLDocItem,':p3',@nDebtorNo)
			Set @sSQLDocItem=replace(@sSQLDocItem,':p4',''''+@sOpenItemNo+'''')
		
			Set @sSQLString="
			Update #TEMPCASEDETAILS
			Set DOCITEM6=("+@sSQLDocItem+")
			From #TEMPCASEDETAILS"
		
			Exec @ErrorCode=sp_executesql @sSQLString
		End
	End
End

-- If no Reference Text was extracted for the bill then attempt to get the 
-- details at this time 
If @ErrorCode=0
and exists(select * from @tbItemHeader where RefText is null)
Begin
	-- Get the docitem to use for extracting the Reference Text

	Set @sSQLString="
	Select 	@sSQLDocItem=convert(nvarchar(4000),SQL_QUERY),
		@sItemName=S.COLCHARACTER
	From SITECONTROL S
	left join ITEM I on (I.ITEM_NAME=S.COLCHARACTER)
	Where S.CONTROLID='XML Bill Ref-Automatic'"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@sSQLDocItem		nvarchar(4000)	Output,
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
Begin
	insert into @tbCopyToDetails (CopyToName,CopyToAttention,CopyToAddress)
	select	distinct
		dbo.fn_FormatNameUsingNameNo(N1.NAMENO, COALESCE(N1.NAMESTYLE, C1.NAMESTYLE, 7101)),
		dbo.fn_FormatNameUsingNameNo(N2.NAMENO, COALESCE(N2.NAMESTYLE, C2.NAMESTYLE, 7101)),
		dbo.fn_FormatAddress(A.STREET1, A.STREET2, A.CITY, A.STATE, S.STATENAME, A.POSTCODE, CA.POSTALNAME, CA.POSTCODEFIRST, CA.STATEABBREVIATED,CA.POSTCODELITERAL,CA.ADDRESSSTYLE)
	from #TEMPCASEDETAILS T
	join CASENAME CN	on (CN.CASEID=T.CASEID
				and CN.NAMETYPE=CASE WHEN(@bRenewalFlag=1) THEN 'ZC' ELSE'CD' END
				and CN.EXPIRYDATE is not null)
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
	Select * from @tbItemHeader as ItemHeader
	for XML AUTO, ELEMENTS,BINARY BASE64
/*
	OpenItemNo		nvarchar(12)	NULL,
	AccountNo		nvarchar(60)	NULL,
	YourRef			nvarchar(500)	NULL,
	ItemDate		datetime	NULL,
	RefText			nvarchar(max)	NULL,
	TaxLocal		decimal(11,2)	NULL,
	TaxForeign		decimal(11,2)	NULL,
	CurrencyLocal		nvarchar(3)	NULL,
	LocalValue		decimal(11,2)	NULL,
	CurrencyForeign		nvarchar(3)	NULL,
	CurrencyFlag		bit		NULL,
	ForeignValue		decimal(11,2)	NULL,
	BillPercentage		decimal(5,2)	NULL,
	TaxLabel		nvarchar(20)	NULL,
	TaxFlag			bit		NULL,
	FmtName			nvarchar(254)	NULL,
	FmtAddress		nvarchar(254)	NULL,
	FmtAttention		nvarchar(254)	NULL,
	StatusText		nvarchar(50)	NULL,
	OurRef			nvarchar(500)	NULL,
	PurchaseOrderNo		nvarchar(80)	NULL,
	SignOffName		nvarchar(100)	NULL,
	Regarding		nvarchar(max)	NULL,
	BillScope		nvarchar(254)	NULL,
	Reductions		decimal(11,2)	NULL,
	CreditNoteFlag		bit		NULL,
	ReductionsForeign	decimal(11,2)	NULL,
	TaxNo			nvarchar(30)	NULL,
	ImageId			int		NULL,
	ForeignEquivCurrency	nvarchar(40)	NULL,
	ForeignEquivExRate	decimal(11,4)	NULL,
	PenaltyInterestRate	decimal(5,2)	NULL,
	DueDate			datetime	NULL,
	LocalTakenUp		decimal(11,2)	NULL,
	ForeignTakenUp		decimal(11,2)	NULL
*/
	Select * from @tbBillLines AS BillLines
	order by DetailDisplaySequence
	for XML AUTO, ELEMENTS,BINARY BASE64
/*
	DetailDisplaySequence	smallint	NULL,
	DetailChargeOutRate	decimal(11,2)	NULL,
	DetailStaffName		nvarchar(60)	NULL,
	DetailDate		datetime	NULL,
	DetailIRN		nvarchar(30)	NULL,	
	DetailTime		nvarchar(30)	NULL,
	DetailWIPCode		nvarchar(6)	NULL,
	DetailWIPTypeId		nvarchar(6)	NULL,
	DetailCatDesc		nvarchar(50)	NULL,
	DetailNarrative		nvarchar(3500)	NULL,
	DetailValue		decimal(11,2)	NULL,
	DetailForeignValue	decimal(11,2)	NULL,
	DetailChargeCurr	nvarchar(3)	NULL,
	DetailStaffClass	nvarchar(80)	NULL,
	DetailStaffCode		nvarchar(10)	NULL,
	DetailStaffInit		nvarchar(10)	NULL
*/
	Select * from @tbTaxDetails as TaxDetails
	order by TaxRate, TaxDescription
	for XML AUTO, ELEMENTS, BINARY BASE64
/*
	TaxRate			decimal(11,4)	NULL,
	TaxableAmount		decimal(11,2)	NULL,
	TaxAmount		decimal(11,2)	NULL,
	TaxDescription		nvarchar(30)	NULL
*/

	Select * from #TEMPCASEDETAILS as CaseDocItems
	order by IRN
	for XML AUTO, ELEMENTS,BINARY BASE64
/*
	CASEID			int		NOT NULL,
	IRN			nvarchar(30)	NOT NULL,
	DOCITEM1		nvarchar(1000)	NULL,
	DOCITEM2		nvarchar(1000)	NULL,
	DOCITEM3		nvarchar(500)	NULL,
	DOCITEM4		nvarchar(500)	NULL,
	DOCITEM5		nvarchar(500)	NULL,
	DOCITEM6		nvarchar(400)	NULL
*/
	Select * from @tbCopyToDetails as CopyToDetails
	order by CopyToName
	for XML AUTO, ELEMENTS,BINARY BASE64
/*
	CopyToName		nvarchar(254)	NULL,
	CopyToAttention		nvarchar(254)	NULL,
	CopyToAddress		nvarchar(254)	NULL
*/


End

return @ErrorCode
go

grant execute on dbo.xml_GetDebitNoteDetails  to public
go

