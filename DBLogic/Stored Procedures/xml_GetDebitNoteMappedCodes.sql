-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xml_GetDebitNoteMappedCodes 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[xml_GetDebitNoteMappedCodes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.xml_GetDebitNoteMappedCodes.'
	drop procedure dbo.xml_GetDebitNoteMappedCodes
end
print '**** Creating procedure dbo.xml_GetDebitNoteMappedCodes...'
print ''
go

-- Quoted_Identifer must be on to use XML value() functions.
set QUOTED_IDENTIFIER on
go
set ANSI_NULLS ON
go

create procedure dbo.xml_GetDebitNoteMappedCodes	
		@pnUserIdentityId		int,			-- Mandatory
		@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed	
		@pnQueryContextKey		int		= 460,	-- The key for the context of the query (default output requests).
		@ptXMLFilterCriteria		nvarchar(max)		-- The filtering to be performed on the result set.		
as
---PROCEDURE :	xml_GetDebitNoteMappedCodes
-- VERSION :	36
-- DESCRIPTION:	A procedure that returns all of the details required on a formatted
--		open item such as a Debit or Credit Note.
--
--		The following details will be returned :
--			OpenItemNo
--			AccountNo
--			LawFirmID
--			YourRef
--			ItemDate
--			RefText
--			TaxLocal
--			TaxForeign
--			CurrencyL
--			LocalValue
--			LocalServiceChargeValue
--			LocalExpenseValue
--			LocalServiceChargeAdjust
--			LocalExpenseAdjust
--			CurrencyF
--			CurrencyF
--			ForeignValue
--			ForeignServiceChargeValue
--			ForeignExpenseValue
--			ForeignServiceChargeAdjust
--			ForeignExpenseAdjust
--			BillPercentage
--			TaxLabel
--			Tax
--			DebtorName
--			DebtorAddress
--			DebtorAttentionName
--			StatusText
--			CopyToList
--			CopyToAddress
--			CopyToAttention
--			OurRef
--			PurchaseOrderNo
--			StaffName
--			Regarding
--			BillScope
--			Reductions
--			CreditNoteFlag
--			ForeignReductions
--			TaxNumber
--			CopyLabel
--			Image
--			ForeignEquivCurrency
--			ForeignEquivExRate
--			PenaltyInterestRate
--			ItemTypeAbbreviation
--			DueDate
--			LocalTakenUp
--			ForeignTakenUp
--			OpenItemAction
--
--			DebtorAddress1
--			DebtorAddress2
--			DebtorCity
--			DebtorState
--			DebtorPostcode
--			DebtorCountry
--			DebtorCountryCode
--			DebtorPhoneNumber

--			LawFirmName
--			LawFirmAddress1
--			LawFirmAddress2
--			LawFirmCity
--			LawFirmState
--			LawFirmPostcode
--			LawFirmCountry
--			LawFirmCountryCode
--			LawFirmPhoneNumber
--
--			CaseStaffFirstName			First Case on Bill - First Name where NAMETYPE='EMP'
--			CaseStaffSurname			First Case on Bill -       Name where NAMETYPE='EMP'
--			CaseAttentionFirstName			First Case on Bill - Attention First Name where NAMETYPE='I'
--			CaseAttentionSurname			First Case on Bill - Attention       Name where NAMETYPE='I'
--			CaseTitle				First Case on Bill - Title
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
--			DetailWIPCategory
--			DetailCatDesc
--			DetailNarrative
--			DetailValue
--			DetailForeignValue
--			DetailChargeCurrency
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
--			DetailDebtorReference
--			DetailNumberOfUnits
--			DetailDiscountValue
--			DetailForeignDiscountValue
--			DetailForeignChargeOutRate
--			DetailGrossAmount
--			DetailForeignGrossAmount
--			DetailTaxType
--			DetailTaxRate
--			DetailForeignTaxAmount
--			DetailFirstApplicant
--			DetailNumberType_A
--			DetailNumberType_5
--
--			DetailFeeEarnerLastName		(surname of employee on the bill detail line)
--			DetailFeeEarnerFirstName	(first name of employee on the bill detail line)
--			DetailTaxTotal			(BILLLINE.LOCALTAX)
	
-- MODIFICATION
-- Date		Who	No	Version	Description
-- ====         ===	=== 	=======	=====================================================================
-- 15 Apr 2010	MF	7008	1	Procedure created starting from a copy of xml_GetDebitNoteDetails
-- 04 Aug 2010	AT	9556	2	Modify to return well-formed XML. Return saved mapped values if they exist.
-- 01 Sep 2010	AT	9556	3	Fixed return of copy to names.
-- 09 Nov 2010	AT	9940	4	Fixed return of law firm id.	
-- 18 Jan 2011	AT	8983	5	Fixed return of blank references from concat_null_yields_null.
-- 01 Apr 2011  DV      10041  	 6       Fixed return of PUBLISHNAME instead of ID when DOCITEM is not null
-- 21 Apr 2011	MF	10524	7	Add new columns required by LEDESBI
-- 02 May 2011	AT	10286	8	Extended narrative column to nvarchar(max)
-- 20 May 2011	MF	10658	9	Add new columns required for E-Filing
-- 02 Jun 2011	AT	10756	10	Fixed null check on bill line.
-- 15 Jun 2011	AT	10841	11	Removed restriction for bill map profile.
-- 15 Jun 2011	AT	10843	12	Fixed null concatenation issues with case ref data.
-- 17 Jun 2011	AT	10867	13	Export law firm street address instead of postal address to e-bill
-- 24 Jun 2011	AT	10901	14	Export RefText into CaseDocItem if empty in OpenItem.
-- 01 Jul 2011	MF	10899	15	Remove reference to DetailRefDocItem1 through 6 as these are now handle by an unlimited
--					set of user defined columns.
--					Also made a correction to the 10901 change. RefText needed to use a "like" instead of =.
-- 14 Jul 2011	MF	10978	16	Strip out line feed and/or carriage return from AddressLine1 and AddressLine2 fields. Also
--					ensure the correct bill line name is used for the First and Last Name as there are rules to handle
--					the situation when the name at the bill level is a department.
--					Flattened non-case bill line join to return 1 row per bill line.
-- 06 Jun 2012	MF	R12388	17	Do not repeat Your Ref, Our Ref or Purchase Order No for bills with multiple Cases.
-- 12 Jul 2012	MF	R12514	18	Additional data elements are to be returned.
-- 21 Sep 2012 DL	R12763	19	Fix collation error by adding 'collate database_default' to character based columns in temp table definition.
-- 04 Dec 2012	MF	R13002	20	Allow header to accept mapped fields (code changes supplied by DCC).
-- 27 Mar 2013	MF	S21327	21	The openitem may use LONGREFTEXT instead of REFERENCETEXT.
-- 08 Jul 2013	MF	R13641	22	Return the initials of the staff name associated with the bill lines.
-- 27 Feb 2014	DL	S21508	23	Change variables and temp table columns that reference namecode to 20 characters
-- 08 Sep 2014	MF	R39266	24	E-Bill details should only sort on columns that are explicitly defined to be used in Sort.
-- 18 Sep 2014	MF	R39597	25	Merged billed lines with different staff may result in the incorrect StaffCode for the StaffName being determined.
-- 09 Dec 2014	MF	R41091	26	Staff classification not always being returned.
-- 17 Mar 2015	MF	R45808	27	Revisit 39597 to handle the possibility of muliple names existing with identical SignOffName.
-- 20 Apr 2015	MF	R46357	28	Change manner in which Purchase Order is being extracted as it is sometime returning a value for the 
--					case when it should be Null and fall through to use the PO against the Name.
-- 14 May 2015	MF	47389	29	Return the debtor's reference in each bill line being returned.
-- 20 Oct 2015  MS      R53933  30      Changed size from decimal(8,4) to decimal(11,4) for rate cols
-- 02 Nov 2015	vql	R53910	31	Adjust formatted names logic (DR-15543).
-- 16 Dec 2015	MF	R56190	32	Add new column DetailNumberOfUnits to return ENTEREDQUANTITY for the WIP being billed.
-- 09 Jan 2016	MF	R56964	33	The DebtorReference being extracted should check the NAMEADDRESSSNAP table in case it was changed during billing.
-- 16 Aug 2016	MF	63072	34	Add new columns: DetailDiscountValue, DetailDiscountForeignValue, DetailForeignChargeOutRate, DetailGrossAmount,
--							 DetailForeignGrossAmount, DetailTaxType, DetailTaxRate, DetailForeignTaxAmount, DetailFirstApplicant,
--							 DetailNumberType_A, DetailNumberType_5
-- 22 Dec 2016	MF	70311	35	Correction to DetailGrossAmount & DetailForeignGrossAmount so as to also include the Discount amount.
-- 13 Apr 2017	MF	71192	36	Correction courtesy of Sjoerd Koneijnenburg. Problem with rules that utilise WIP Category in matching.
		
set nocount on
-- concat_null_yields_null must be on to use XML value() functions.
set concat_null_yields_null on

-- Store the Case details for each Case on the bill loaded from 
-- user defined queries and held in a Temporary Table (required because of dynamic SQL)
-- The size of the DocItem columns may need to be varied depending on 
-- the results to be loaded into these columns.
Create table #TEMPCASEDETAILS (
			CASEID			int		NOT NULL,
			IRN			nvarchar(30)	collate database_default NOT NULL,
			REFTEXT			nvarchar(max)	collate database_default NULL,
			ROWORDER		smallint	identity(1,1)
			)

-- Store the required information in a table variable
Create table #TEMPITEMHEADER (
			OpenItemNo		nvarchar(12)	collate database_default NULL,
			LawFirmID		nvarchar(60)	collate database_default NULL,
			LawFirmName		nvarchar(100)	collate database_default NULL,
			LawFirmAddress1		nvarchar(100)	collate database_default NULL,
			LawFirmAddress2		nvarchar(100)	collate database_default NULL,
			LawFirmCity		nvarchar(30)	collate database_default NULL,
			LawFirmState		nvarchar(20)	collate database_default NULL,
			LawFirmPostcode		nvarchar(10)	collate database_default NULL,
			LawFirmCountry		nvarchar(60)	collate database_default NULL,
			LawFirmCountryCode	nvarchar(3)	collate database_default NULL,
			LawFirmPhoneNumber	nvarchar(200)	collate database_default NULL,
			AccountNo		nvarchar(60)	collate database_default NULL,
			YourRef			nvarchar(1000)	collate database_default NULL,
			ItemDate		datetime	NULL,
			RefText			nvarchar(max)	collate database_default NULL,
			TaxLocal		decimal(11,2)	NULL,
			TaxForeign		decimal(11,2)	NULL,
			CurrencyLocal		nvarchar(3)	collate database_default NULL,
			LocalValue		decimal(11,2)	NULL,
			LocalServiceChargeValue	decimal(11,2)	NULL,
			LocalExpenseValue	decimal(11,2)	NULL,
			LocalServiceChargeAdjust decimal(11,2)	NULL,
			LocalExpenseAdjust	decimal(11,2)	NULL,
			CurrencyForeign		nvarchar(3)	collate database_default NULL,
			CurrencyFlag		bit		NULL,
			ForeignValue		decimal(11,2)	NULL,
			ForeignServiceChargeValue decimal(11,2)	NULL,
			ForeignExpenseValue	decimal(11,2)	NULL,
			ForeignServiceChargeAdjust decimal(11,2) NULL,
			ForeignExpenseAdjust	decimal(11,2)	NULL,
			BillPercentage		decimal(5,2)	NULL,
			TaxLabel		nvarchar(20)	collate database_default NULL,
			TaxFlag			bit		NULL,
			DebtorName		nvarchar(254)	collate database_default NULL,
			DebtorAddress		nvarchar(254)	collate database_default NULL,
			DebtorAttentionName	nvarchar(254)	collate database_default NULL,
			DebtorAddress1		nvarchar(100)	collate database_default NULL,
			DebtorAddress2		nvarchar(100)	collate database_default NULL,
			DebtorCity		nvarchar(30)	collate database_default NULL,
			DebtorState		nvarchar(20)	collate database_default NULL,
			DebtorPostcode		nvarchar(10)	collate database_default NULL,
			DebtorCountry		nvarchar(60)	collate database_default NULL,
			DebtorCountryCode	nvarchar(3)	collate database_default NULL,
			DebtorPhoneNumber	nvarchar(200)	collate database_default NULL,
			StatusText		nvarchar(50)	collate database_default NULL,
			OurRef			nvarchar(1000)	collate database_default NULL,
			PurchaseOrderNo		nvarchar(500)	collate database_default NULL,
			StaffName		nvarchar(100)	collate database_default NULL,
			Regarding		nvarchar(max)	collate database_default NULL,
			BillScope		nvarchar(254)	collate database_default NULL,
			Reductions		decimal(11,2)	NULL,
			CreditNoteFlag		bit		NULL,
			ForeignReductions	decimal(11,2)	NULL,
			TaxNumber		nvarchar(30)	collate database_default NULL,
			ImageId			int		NULL,
			ForeignEquivCurrency	nvarchar(40)	collate database_default NULL,
			ForeignEquivExRate	decimal(11,4)	NULL,
			PenaltyInterestRate	decimal(5,2)	NULL,
			DueDate			datetime	NULL,
			LocalTakenUp		decimal(11,2)	NULL,
			ForeignTakenUp		decimal(11,2)	NULL,
			OpenItemAction		nvarchar(20)	collate database_default NULL,
			CaseTitle		nvarchar(254)	collate database_default NULL,
			CaseStaffFirstName	nvarchar(50)	collate database_default NULL,
			CaseStaffSurname	nvarchar(254)	collate database_default NULL,
			CaseAttentionFirstName	nvarchar(50)	collate database_default NULL,
			CaseAttentionSurname	nvarchar(254)	collate database_default NULL
			)

Create table #TEMPBILLLINES (
			DetailDisplaySequence	smallint	NULL,
			DetailChargeOutRate	decimal(11,2)	NULL,
			DetailStaffName		nvarchar(60)	collate database_default NULL,
			DetailDate		datetime	NULL,
			DetailCaseReference	nvarchar(30)	collate database_default NULL,	
			DetailYourRef		nvarchar(80)	collate database_default NULL,
			DetailTime		nvarchar(30)	collate database_default NULL,
			DetailWIPCode		nvarchar(6)	collate database_default NULL,
			DetailWIPTypeId		nvarchar(6)	collate database_default NULL,
			DetailWIPCategory	nvarchar(3)	collate database_default NULL,
			DetailCatDesc		nvarchar(50)	collate database_default NULL,
			DetailNarrative		nvarchar(max)	collate database_default NULL,
			DetailValue		decimal(11,2)	NULL,
			DetailForeignValue	decimal(11,2)	NULL,
			DetailTaxTotal		decimal(11,2)	NULL, -- BILLLINE.LOCALTAX
			DetailChargeCurrency	nvarchar(3)	collate database_default NULL,
			DetailStaffClass	nvarchar(80)	collate database_default NULL,
			DetailStaffClassCode	int		NULL,
			DetailStaffCode		nvarchar(20)	collate database_default NULL,
			DetailStaffInit		nvarchar(10)	collate database_default NULL,
			DetailCaseCountryCode	nvarchar(3)	collate database_default NULL,
			DetailCaseCountry	nvarchar(60)	collate database_default NULL,
			DetailCaseTypeDesc	nvarchar(50)	collate database_default NULL,
			DetailPropertyType	nvarchar(50)	collate database_default NULL,
			DetailOfficialNo	nvarchar(36)	collate database_default NULL,
			DetailCaseTitle		nvarchar(254)	collate database_default NULL,
			DetailCasePurchaseOrder	nvarchar(80)	collate database_default NULL,
			DetailFeeEarnerName	   nvarchar(60)	collate database_default NULL,
			DetailFeeEarnerLastName	   nvarchar(60)	collate database_default NULL,
			DetailFeeEarnerFirstName   nvarchar(60)	collate database_default NULL,
			DetailFeeEarnerStaffClass  nvarchar(80)	collate database_default NULL,
			DetailFeeEarnerStaffCode   nvarchar(20)	collate database_default NULL,
			DetailFeeEarnerStaffInit   nvarchar(10)	collate database_default NULL,
			DetailDebtorReference      nvarchar(80)	collate database_default NULL,
			DetailNarrativeNo	   int			NULL,
			DetailNumberOfUnits	   int			NULL,
			DetailDiscountValue	   decimal(11,2)	NULL,
			DetailDiscountForeignValue decimal(11,2)	NULL,
			DetailForeignChargeOutRate decimal(11,2)	NULL,
			DetailGrossAmount	   decimal(11,2)	NULL,
			DetailForeignGrossAmount   decimal(11,2)	NULL,
			DetailTaxType		   nvarchar(30) collate database_default NULL,
			DetailTaxRate		   decimal(11,4)	NULL,
			DetailForeignTaxAmount	   decimal(11,2)	NULL,
			DetailFirstApplicant	   nvarchar(255)collate database_default NULL,
			DetailNumberType_A	   nvarchar(36) collate database_default NULL,
			DetailNumberType_5	   nvarchar(36) collate database_default NULL
			)

-- Store the tax summary information in a table variable
Create table #TEMPTAXDETAILS (
			TaxRate			decimal(11,4)	NULL,
			TaxableAmount		decimal(11,2)	NULL,
			TaxAmount		decimal(11,2)	NULL,
			TaxDescription		nvarchar(30)	collate database_default NULL
			)

-- Store the tax summary information in a table variable
Create table #TEMPCOPYTODETAILS (
			CopyToName		nvarchar(254)	collate database_default NULL,
			CopyToAttention		nvarchar(254)	collate database_default NULL,
			CopyToAddress		nvarchar(254)	collate database_default NULL
			)

-- @tblOutputRequests table variable is used to load the OutputRequests parameters 
Declare @tblOutputRequests table (
	 		ROWNUMBER		int 		identity(1,1),
    			ID			nvarchar(100)	collate database_default not null,
    			SORTORDER		tinyint		null,
    			SORTDIRECTION		nvarchar(1)	collate database_default null,
			PUBLISHNAME		nvarchar(100)	collate database_default null,
			QUALIFIER		nvarchar(100)	collate database_default null,				
			DOCITEMKEY		int		null,
			PROCEDURENAME		nvarchar(50)	collate database_default null,
			DATAFORMATID		int 		null,
			DATATYPE		nvarchar(20)	collate database_default null,
			FIELDCODE		int		null,
			DISPLAYSEQUENCE		int		null
		 	)
		 	
Declare	@idoc 			int		-- Document handle of the XML document in memory that is created by sp_xml_preparedocument.		
Declare	@ErrorCode		int
Declare	@nRowCount		int	
Declare	@nOutRequestsRowCount	int
Declare @nCount			int

Declare	@nColumnNo 		smallint
Declare	@nOrderPosition		smallint
Declare	@nDocItemKey		int
Declare @nRowNumber		int
Declare	@sColumn   		nvarchar(100)
Declare	@sPublishName 		nvarchar(100)
Declare	@sOrderDirection	nchar(1)
Declare	@sQualifier		nvarchar(100)
Declare @sLookupCulture		nvarchar(10)

Declare	@sSQLString		nvarchar(max)
Declare	@sSelectHeader		nvarchar(4000)
Declare	@sSelectCopyToDetails	nvarchar(4000)
Declare	@sSelectCaseDetails	nvarchar(4000)
Declare	@sSelectTaxDetails	nvarchar(4000)
Declare	@sSelectBillLines	nvarchar(4000)
Declare	@sOrderCopyToDetails	nvarchar(4000)
Declare	@sOrderCaseDetails	nvarchar(4000)
Declare	@sOrderTaxDetails	nvarchar(4000)
Declare	@sOrderBillLines	nvarchar(4000)

Declare	@sSQLDocItem		nvarchar(max)
Declare	@sItemName		nvarchar(254)
Declare	@sYourRef		nvarchar(1000)
Declare	@sOurRef		nvarchar(1000)
Declare	@sPurchaseNo		nvarchar(1000)

Declare	@hDocument 		int 		-- handle to the XML parameter which is the Activity Request row
Declare	@nPresentationId	int		-- the Presentation that holds the columns to be extracted
Declare	@nMapProfileId		int		-- The profile used to determine the mapping of codes.
Declare	@nFieldCode		int		-- User defined field to be extracted from mapping
Declare	@nEntityNo		int 		-- the entityno of the debitnote
Declare	@nLanguage		int 		-- the language of the debitnote
Declare	@nDebtorNo		int		-- the debtorno of the debitnote
Declare	@nHomeNameNo		int		-- NameNo of the firm using Inprotech
Declare	@sLocalCurrency		nvarchar(3)	-- default local currency code
Declare	@sTaxLiteral		nvarchar(30)	-- Literal for tax
Declare	@sClientAlias		nvarchar(3)	-- Alias used for extracting Client's code to report
Declare	@sFirmAlias		nvarchar(3)	-- Alias used for extracting the Inprotech Firm's code to report
Declare	@sOpenItemNo		nvarchar(12) 	-- the openitemno of the debitnote
Declare	@sNameType		nvarchar(3) 	-- the NameType of the debitnote
Declare	@nBillPercent		decimal(5,4)	-- the percentage of the original Billed items included in this debit note coverted to decimal
Declare @nOpenItemStatus		int
Declare	@nTransNo		int

Declare @bSavedBillLineMappingsExist	bit	-- flag to indicate the availability of saved mapped values.

Declare	@bRenewalFlag		bit		-- indicates the Renewal Debtor was used for bill

-----------------
-- Initialisation
-----------------
Set @ErrorCode			= 0
set @nOutRequestsRowCount	= 0
set @nCount			= 1

-------------------------------------------------
--
--    Get the FILTER of Item to be Extracted
--
-------------------------------------------------

-------------------------------------------------
-- Check for a null value or emptiness of the 
-- @ptXMLFilterCriteria parameter and raise an
-- error before attempting to open the XML document.
-------------------------------------------------
If isnull(@ptXMLFilterCriteria,'') = ''
Begin	
	Raiserror('Activity request row XML parameter is empty.', 16, 1)
	Set 	@ErrorCode = @@Error
End

-------------------------------------------------
-- Collect the key for the Activity Request row 
-- that has been passed as an XML parameter 
-- using OPENXML functionality.
-------------------------------------------------
If @ErrorCode = 0
Begin	
	Exec 	sp_xml_preparedocument  @hDocument OUTPUT, @ptXMLFilterCriteria
	Set 	@ErrorCode = @@Error
End
-------------------------------------------------
-- Now select the key from the xml, at the same 
-- time joining it to the ACTIVITYREQUEST table.
-------------------------------------------------
If @ErrorCode = 0
Begin
	Set @sSQLString='
	select 	@nEntityNo = ENTITYNO,
		@sOpenItemNo = DEBITNOTENO
		from openxml(@hDocument,''ACTIVITYREQUEST'',2)
		with ACTIVITYREQUEST'
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
	Set @ErrorCode = @@Error
End

-------------------------------------------------
-- Get the PresentationId associated with the
-- Bill Format Profile. This will be used to get 
-- the columns to be extracted.
-------------------------------------------------
If  @ErrorCode = 0
and @nEntityNo   is not null
and @sOpenItemNo is not null
Begin
	Set @sSQLString='
	Select	@nPresentationId=F.PRESENTATIONID,
		@nMapProfileId  =N.BILLMAPPROFILEID,
		@nTransNo	=O.ITEMTRANSNO
	from OPENITEM O
	left join BILLFORMAT B		on (B.BILLFORMATID=O.BILLFORMATID)
	left join FORMATPROFILE F	on (F.FORMATID=B.FORMATPROFILEID)
	left join IPNAME N		on (N.NAMENO=O.ACCTDEBTORNO)
	where O.ITEMENTITYNO=@nEntityNo
	and O.OPENITEMNO=@sOpenItemNo'

	Exec @ErrorCode=sp_executesql @sSQLString,
		N'@nPresentationId	int			OUTPUT,
		  @nMapProfileId	int			OUTPUT,
		  @nTransNo		int			OUTPUT,
		  @nEntityNo		int,
		  @sOpenItemNo		nvarchar(40)',
		  @nPresentationId	= @nPresentationId	OUTPUT,
		  @nMapProfileId	= @nMapProfileId	OUTPUT,
		  @nTransNo		= @nTransNo		OUTPUT,
		  @nEntityNo		= @nEntityNo,
		  @sOpenItemNo 		= @sOpenItemNo
End

-------------------------------------------------
--
--    Get the COLUMNS to be Extracted
--
-------------------------------------------------

-------------------------------------------------
-- Where a Bill Format Profile has been provided,
-- the columns to extract for that profile are to
-- be extracted and loaded into a table variable.
-------------------------------------------------
If  @nPresentationId is not null
and @ErrorCode=0
Begin
	set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)	

	If @sLookupCulture is not null
	and dbo.fn_GetTranslatedTIDColumn('QUERYCOLUMN','COLUMNLABEL') is not null
	Begin
		-----------------------
		-- Translation required
		-----------------------
		Insert into @tblOutputRequests (ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, DATAFORMATID, DATATYPE, FIELDCODE, DISPLAYSEQUENCE)
		select 	Distinct
			DI.PROCEDUREITEMID,
			T.SORTORDER,
			T.SORTDIRECTION,
			replace(CAST(dbo.fn_GetTranslation(C.COLUMNLABEL,null,C.COLUMNLABEL_TID,@sLookupCulture) as nvarchar(100)),' ','_'),
			C.QUALIFIER,
			C.DOCITEMID,
			DI.PROCEDURENAME,
			DI.DATAFORMATID,
			CASE(DI.DATAFORMATID)
				WHEN(9100) THEN 'nvarchar(255)'
				WHEN(9101) THEN 'int'
				WHEN(9102) THEN 'decimal(11,'+convert(varchar,isnull(DI.DECIMALPLACES,0))+')'
				WHEN(9103) THEN 'datetime'
				WHEN(9104) THEN 'datetime'
				WHEN(9105) THEN 'datetime'
				WHEN(9106) THEN 'bit'
				WHEN(9107) THEN 'nvarchar(max)'
				WHEN(9108) THEN 'decimal(11,2)'
				WHEN(9109) THEN 'decimal(11,2)'
				WHEN(9110) THEN 'int'
				WHEN(9111) THEN 'image'
				WHEN(9112) THEN 'nvarchar(100)'
				WHEN(9113) THEN 'nvarchar(100)'
			END,
			TC.TABLECODE,
			T.DISPLAYSEQUENCE
		from QUERYPRESENTATION P
		join QUERYCONTENT T		on (T.PRESENTATIONID = P.PRESENTATIONID)
		join QUERYCOLUMN C		on (C.COLUMNID = T.COLUMNID)
		join QUERYDATAITEM DI		on (DI.DATAITEMID = C.DATAITEMID)
		left join TABLECODES TC		on (TC.TABLETYPE=-500
						and TC.DESCRIPTION=C.COLUMNLABEL)
		WHERE P.PRESENTATIONID = @nPresentationId
		order by T.DISPLAYSEQUENCE
	
		Select @nOutRequestsRowCount = @@RowCount,
		       @ErrorCode = @@Error
	End
	Else Begin
		-----------------------
		-- No Translation
		-----------------------
		Insert into @tblOutputRequests(ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, DATAFORMATID, DATATYPE, FIELDCODE, DISPLAYSEQUENCE)
		select 	Distinct
			DI.PROCEDUREITEMID,
			T.SORTORDER,
			T.SORTDIRECTION,
			replace(C.COLUMNLABEL,' ','_'),
			C.QUALIFIER,
			C.DOCITEMID,
			DI.PROCEDURENAME,
			DI.DATAFORMATID,
			CASE(DI.DATAFORMATID)
				WHEN(9100) THEN 'nvarchar(255)'
				WHEN(9101) THEN 'int'
				WHEN(9102) THEN 'decimal(11,'+convert(varchar,isnull(DI.DECIMALPLACES,0))+')'
				WHEN(9103) THEN 'datetime'
				WHEN(9104) THEN 'datetime'
				WHEN(9105) THEN 'datetime'
				WHEN(9106) THEN 'bit'
				WHEN(9107) THEN 'nvarchar(max)'
				WHEN(9108) THEN 'decimal(11,2)'
				WHEN(9109) THEN 'decimal(11,2)'
				WHEN(9110) THEN 'int'
				WHEN(9111) THEN 'image'
				WHEN(9112) THEN 'nvarchar(100)'
				WHEN(9113) THEN 'nvarchar(100)'
			END,
			TC.TABLECODE,
			T.DISPLAYSEQUENCE
		from QUERYPRESENTATION P
		join QUERYCONTENT T		on (T.PRESENTATIONID = P.PRESENTATIONID)
		join QUERYCOLUMN C		on (C.COLUMNID = T.COLUMNID)
		join QUERYDATAITEM DI		on (DI.DATAITEMID = C.DATAITEMID)
		left join TABLECODES TC		on (TC.TABLETYPE=-500
						and TC.DESCRIPTION=C.COLUMNLABEL)
		WHERE P.PRESENTATIONID = @nPresentationId
		order by T.DISPLAYSEQUENCE
	
		Select @nOutRequestsRowCount = @@RowCount,
		       @ErrorCode = @@Error
	End
End

-------------------------------------------
-- If the PresentationId was not found, the
-- @pnQueryContextKey is used to obtain the
-- default presentation from the database
-------------------------------------------
Else Begin
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, null)

	Insert into @tblOutputRequests (ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, DATAFORMATID, DATATYPE, FIELDCODE, DISPLAYSEQUENCE)
	Select  Distinct
		C.COLUMNID, C.SORTORDER, C.SORTDIRECTION, replace(C.PUBLISHNAME,' ','_'), C.QUALIFIER, C.DOCITEMKEY, C.PROCEDURENAME, C.DATAFORMATID,
		CASE(C.DATAFORMATID)
			WHEN(9100) THEN 'nvarchar(255)'
			WHEN(9101) THEN 'int'
			WHEN(9102) THEN 'decimal(11,4)'
			WHEN(9103) THEN 'datetime'
			WHEN(9104) THEN 'datetime'
			WHEN(9105) THEN 'datetime'
			WHEN(9106) THEN 'bit'
			WHEN(9107) THEN 'nvarchar(max)'
			WHEN(9108) THEN 'decimal(11,2)'
			WHEN(9109) THEN 'decimal(11,2)'
			WHEN(9110) THEN 'int'
			WHEN(9111) THEN 'image'
			WHEN(9112) THEN 'nvarchar(100)'
			WHEN(9113) THEN 'nvarchar(100)'
		END,
		TC.TABLECODE,
		C.ROWNUMBER
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, null, null,0,null) C
	left join TABLECODES TC		on (TC.TABLETYPE=-500
					and TC.DESCRIPTION=C.PUBLISHNAME)
	order by C.ROWNUMBER
  
	Select @nOutRequestsRowCount = @@rowcount,
		       @ErrorCode = @@Error
End
----------------------------------------------
-- Data will be extracted for each open item
-- as XML from the following populated tables:
--	#TEMPITEMHEADER
--	#TEMPBILLLINES
--	#TEMPTAXDETAILS
--	#TEMPCASEDETAILS
--	#TEMPCOPYTODETAILS
-- Formulate a SELECT list from the display
-- columns for each of these tables. These are
-- the columns to be extracted for this Bill
-- Format.
----------------------------------------------

if exists (select * from OPENITEMXML OIX 
	Join OPENITEM OI on (OI.ITEMENTITYNO = OIX.ITEMENTITYNO
			AND OI.ITEMTRANSNO = OIX.ITEMTRANSNO)
	Where OI.ITEMENTITYNO = @nEntityNo
	AND OI.OPENITEMNO = @sOpenItemNo
	AND XMLTYPE = 1)
Begin
	Set @bSavedBillLineMappingsExist = 1
End
Else
Begin
	Set @bSavedBillLineMappingsExist = 0
End

If @ErrorCode=0
Begin
	-------------------
	-- #TEMPITEMHEADER
	-------------------
	Select @sSelectHeader= isnull(@sSelectHeader,'')
			       +CASE WHEN(@sSelectHeader is NOT NULL) THEN ',' ELSE '' END 
	
			       +CASE WHEN(@bSavedBillLineMappingsExist = 1)
				     THEN CASE WHEN(ID='BillMapping') THEN 'BillLineMapped.value(N''(' + PUBLISHNAME + ')[1]'', N''nvarchar(254)'')' ELSE ID END
				     ELSE CASE WHEN(ID='BillMapping') THEN '['+PUBLISHNAME+']' ELSE ID END
				END
				
			       +CASE WHEN(PUBLISHNAME is NOT NULL)    THEN ' as ['+PUBLISHNAME+']' END
	from @tblOutputRequests
	where ID in 
	       ('AccountNo',
                'BillPercentage',
                'BillScope',
                'CreditNoteFlag',
                'CurrencyFlag',
                'CurrencyForeign',
                'CurrencyLocal',
                'DueDate',
                'DebtorAddress',
                'DebtorAttentionName',
                'DebtorName',
		'DebtorAddress1',
		'DebtorAddress2',
		'DebtorCity',
		'DebtorState',
		'DebtorPostcode',
		'DebtorCountry',
		'DebtorCountryCode',
		'DebtorPhoneNumber',
                'ForeignEquivCurrency',
                'ForeignEquivExRate',
                'ForeignTakenUp',
                'ForeignValue',
                'ForeignServiceChargeValue',
                'ForeignExpenseValue',
                'ForeignServiceChargeAdjust',
                'ForeignExpenseAdjust',
                'ImageId',
                'ItemDate',
		'LawFirmID',
		'LawFirmName',
		'LawFirmAddress1',
		'LawFirmAddress2',
		'LawFirmCity',
		'LawFirmState',
		'LawFirmPostcode',
		'LawFirmCountry',
		'LawFirmCountryCode',
		'LawFirmPhoneNumber',
                'LocalTakenUp',
                'LocalValue',
                'LocalServiceChargeValue',
                'LocalExpenseValue',
                'LocalServiceChargeAdjust',
                'LocalExpenseAdjust',
		'OpenItemAction',
                'OpenItemNo',
                'OurRef',
                'PenaltyInterestRate',
                'PurchaseOrderNo',
                'Reductions',
                'ForeignReductions',
                'RefText',
                'Regarding',
                'StaffName',
                'StatusText',
                'TaxFlag',
                'TaxForeign',
                'TaxLabel',
                'TaxLocal',
                'TaxNumber',
                'YourRef',
                'CaseTitle',
                'CaseStaffFirstName',
                'CaseStaffSurname',
                'CaseAttentionFirstName',
                'CaseAttentionSurname')
	order by ROWNUMBER

	Set @ErrorCode=@@Error
End

If @ErrorCode=0
Begin
	-------------------
	-- #TEMPBILLLINES
	-------------------
	Select @sSelectBillLines=isnull(@sSelectBillLines,'')
				+CASE WHEN(@sSelectBillLines is NOT NULL) THEN ',' ELSE '' END 
				
				+CASE WHEN(@bSavedBillLineMappingsExist = 1)
				      THEN CASE WHEN(ID='BillMapping') THEN 'BillLineMapped.value(N''(' + PUBLISHNAME + ')[1]'', N''nvarchar(254)'')' ELSE ID END
				      ELSE CASE WHEN(ID='BillMapping') THEN '['+PUBLISHNAME+']' ELSE ID END
				 END
				 
				+CASE WHEN(PUBLISHNAME       is NOT NULL) THEN ' as ['+PUBLISHNAME+']' END
	from @tblOutputRequests
	where ID in 
	       ('DetailCaseCountry',
                'DetailCaseCountryCode',
                'DetailCasePurchaseOrder',
                'DetailCaseTitle',
                'DetailCaseTypeDesc',
                'DetailCatDesc',
                'DetailChargeCurrency',
                'DetailChargeOutRate',
                'DetailDate',
                'DetailDisplaySequence',
                'DetailFeeEarnerName',
		'DetailFeeEarnerLastName',
		'DetailFeeEarnerFirstName',
                'DetailFeeEarnerStaffClass',
                'DetailFeeEarnerStaffCode',
                'DetailFeeEarnerStaffInit',
		'DetailDebtorReference',
                'DetailForeignValue',
                'DetailCaseReference',
                'DetailYourRef',
                'DetailNarrative',
                'DetailNumberOfUnits',
                'DetailDiscountValue',
                'DetailDiscountForeignValue',
                'DetailForeignChargeOutRate',
                'DetailGrossAmount',
                'DetailForeignGrossAmount',
                'DetailTaxType',
                'DetailTaxRate',
                'DetailForeignTaxAmount',
                'DetailFirstApplicant',
                'DetailNumberType_A',
                'DetailNumberType_5',
                'DetailOfficialNo',
                'DetailPropertyType',
                'DetailStaffClass',
                'DetailStaffCode',
                'DetailStaffInit',
                'DetailStaffName',
                'DetailTime',
                'DetailValue',
		'DetailTaxTotal',
                'DetailWIPCode',
                'DetailWIPTypeId',
		'BillMapping')		-- These are user defined fields extracted from mapping rules
	order by ROWNUMBER

	Set @ErrorCode=@@Error

	If @ErrorCode=0
	Begin
		----------------------------------
		-- Assemble the "Order By" clause.
		----------------------------------
	
		Select @sOrderBillLines=isnull(@sOrderBillLines,'')+CASE WHEN(@sOrderBillLines is not null) THEN ','     ELSE ''                   END
		
							+CASE When @bSavedBillLineMappingsExist = 1 and ID='BillMapping' THEN
								'BillLineMapped.value(N''(' + PUBLISHNAME + ')[1]'', N''nvarchar(254)'')'
							ELSE
								CASE WHEN(PUBLISHNAME   is null)        THEN ID      ELSE  '['+PUBLISHNAME+']' END
							END
							+CASE WHEN SORTDIRECTION = 'A'           THEN ' ASC ' ELSE ' DESC '             END
		from @tblOutputRequests
		where DATATYPE not in ('text','ntext') 
		AND SORTDIRECTION is not null	-- RFC39266
		AND ID in 
		       ('DetailCaseCountry',
			'DetailCaseCountryCode',
			'DetailCasePurchaseOrder',
			'DetailCaseTitle',
			'DetailCaseTypeDesc',
			'DetailCatDesc',
			'DetailChargeCurrency',
			'DetailChargeOutRate',
			'DetailDate',
			'DetailDisplaySequence',
			'DetailFeeEarnerName',
			'DetailFeeEarnerLastName',
			'DetailFeeEarnerFirstName',
			'DetailFeeEarnerStaffClass',
			'DetailFeeEarnerStaffCode',
			'DetailFeeEarnerStaffInit',
			'DetailDebtorReference',
			'DetailForeignValue',
			'DetailCaseReference',
			'DetailYourRef',
			'DetailNarrative',
			'DetailNumberOfUnits',
			'DetailDiscountValue',
			'DetailDiscountForeignValue',
			'DetailForeignChargeOutRate',
			'DetailGrossAmount',
			'DetailForeignGrossAmount',
			'DetailTaxType',
			'DetailTaxRate',
			'DetailForeignTaxAmount',
			'DetailFirstApplicant',
			'DetailNumberType_A',
			'DetailNumberType_5',
			'DetailOfficialNo',
			'DetailPropertyType',
			'DetailStaffClass',
			'DetailStaffCode',
			'DetailStaffInit',
			'DetailStaffName',
			'DetailTime',
			'DetailValue',
			'DetailTaxTotal',
			'DetailWIPCode',
			'DetailWIPTypeId',
			'BillMapping')		-- These are user defined fields extracted from mapping rules
		order by SORTORDER

		Set @ErrorCode=@@Error
	End
End

If @ErrorCode=0
Begin
	-------------------
	-- #TEMPTAXDETAILS
	-------------------
	Select @sSelectTaxDetails=isnull(@sSelectTaxDetails,'')+CASE WHEN(@sSelectTaxDetails is NOT NULL) THEN ',' ELSE '' END + ID +
							        CASE WHEN(PUBLISHNAME        is NOT NULL) THEN ' as ['+PUBLISHNAME+']' END
	from @tblOutputRequests
	where ID in 
	       ('TaxableAmount',
                'TaxAmount',
                'TaxDescription',
                'TaxRate')
	order by ROWNUMBER

	Set @ErrorCode=@@Error

	If @ErrorCode=0
	Begin
		----------------------------------
		-- Assemble the "Order By" clause.
		----------------------------------
		Select @sOrderTaxDetails=isnull(@sOrderTaxDetails,'')+CASE WHEN(@sOrderTaxDetails is not null) THEN ','     ELSE ''                   END 			
								     +CASE WHEN(PUBLISHNAME   is null)         THEN ID      ELSE  '['+PUBLISHNAME+']' END
								     +CASE WHEN SORTDIRECTION = 'A'            THEN ' ASC ' ELSE ' DESC '             END
		from @tblOutputRequests
		where DATATYPE not in ('text','ntext')
		AND ID in 
		       ('TaxableAmount',
			'TaxAmount',
			'TaxDescription',
			'TaxRate')
		order by SORTORDER

		Set @ErrorCode=@@Error
	End
End

If @ErrorCode=0
Begin

	-------------------
	-- #TEMPCASEDETAILS
	-------------------
	Select @sSelectCaseDetails=isnull(@sSelectCaseDetails,'')+CASE WHEN(@sSelectCaseDetails is NOT NULL) THEN ',' ELSE '' END +
	                                                          CASE WHEN(DOCITEMKEY is NOT NULL) THEN PUBLISHNAME ELSE ID END +
							          CASE WHEN(PUBLISHNAME         is NOT NULL) THEN ' as ['+PUBLISHNAME+']' END
	from @tblOutputRequests
	where DOCITEMKEY is not null -- User defined columns will be added to #TEMPCASEDETAILS
	OR ID in 
	       ('CASEID',
                'IRN',
                'REFTEXT')
	order by ROWNUMBER

	Set @ErrorCode=@@Error

	If @ErrorCode=0
	Begin
		----------------------------------
		-- Assemble the "Order By" clause.
		----------------------------------
		Select @sOrderCaseDetails=isnull(@sOrderCaseDetails,'')+CASE WHEN(@sOrderCaseDetails is not null) THEN ','     ELSE ''                   END 			
								       +CASE WHEN(PUBLISHNAME   is null)          THEN ID      ELSE  '['+PUBLISHNAME+']' END
								       +CASE WHEN SORTDIRECTION = 'A'             THEN ' ASC ' ELSE ' DESC '             END
		from @tblOutputRequests
		where DATATYPE not in ('text','ntext')
		AND(DOCITEMKEY is not null
		 OR ID in 
		       ('CASEID',
			'IRN',
			'REFTEXT'))
		order by SORTORDER

		Set @ErrorCode=@@Error
	End
End

If @ErrorCode=0
Begin
	---------------------
	-- #TEMPCOPYTODETAILS
	---------------------
	Select @sSelectCopyToDetails=isnull(@sSelectCopyToDetails,'')+CASE WHEN(@sSelectCopyToDetails is NOT NULL) THEN ',' ELSE '' END + ID +
							              CASE WHEN(PUBLISHNAME           is NOT NULL) THEN ' as ['+PUBLISHNAME+']' END
	from @tblOutputRequests
	where ID in 
	       ('CopyToAddress',
                'CopyToAttention',
                'CopyToName')
	order by ROWNUMBER

	Set @ErrorCode=@@Error

	If @ErrorCode=0
	Begin
		----------------------------------
		-- Assemble the "Order By" clause.
		----------------------------------
		Select @sOrderCopyToDetails=isnull(@sOrderCopyToDetails,'')+CASE WHEN(@sOrderCopyToDetails is not null) THEN ','     ELSE ''                   END 			
								           +CASE WHEN(PUBLISHNAME   is null)            THEN ID      ELSE  '['+PUBLISHNAME+']' END
								           +CASE WHEN SORTDIRECTION = 'A'               THEN ' ASC ' ELSE ' DESC '             END
		from @tblOutputRequests
		where DATATYPE not in ('text','ntext')
		AND ID in 
		       ('CopyToAddress',
			'CopyToAttention',
			'CopyToName')
		order by SORTORDER

		Set @ErrorCode=@@Error
	End
End


-----------------------------------------
-- Any user defined columns associated
-- with a Bill Mapping rules are to be 
-- added to the TEMPCASEDETAILS table.
-- A Mapping Profile is required.
----------------------------------------
If @ErrorCode=0
and @bSavedBillLineMappingsExist = 0
Begin
	-----------------------------------------------
	-- Generate the ALTER TABLE statement to add 
	-- the user defined columns to #TEMPBILLLINES
	-----------------------------------------------
	Set @sSQLString=null

	select @sSQLString=ISNULL(NULLIF(@sSQLString + ','+char(10), ','+char(10)),'') 
			   + '['+PUBLISHNAME+']'+CHAR(9)+DATATYPE+CASE WHEN(DATATYPE like '%char%') THEN ' collate database_default' END+' NULL'
	from @tblOutputRequests
	where ID='BillMapping'

	Set @ErrorCode=@@Error

	If @ErrorCode=0
	and @sSQLString is not null
	Begin
		set @sSQLString='Alter table #TEMPBILLLINES Add '+@sSQLString

		exec(@sSQLString)
		Set @ErrorCode=@@Error
	End
End

-----------------------------------------
-- Any user defined columns associated
-- with a DocItem are to be added to the
-- TEMPCASEDETAILS table.
----------------------------------------
If @ErrorCode=0
Begin
	-----------------------------------------------
	-- Generate the ALTER TABLE statement to add 
	-- the user defined columns to #TEMPCASEDETAILS
	-----------------------------------------------
	Set @sSQLString=null

	select @sSQLString=ISNULL(NULLIF(@sSQLString + ','+char(10), ','+char(10)),'') 
			   + '['+PUBLISHNAME+']'+CHAR(9)+DATATYPE+CASE WHEN(DATATYPE like '%char%') THEN ' collate database_default' END+' NULL'
	from @tblOutputRequests
	where DOCITEMKEY is not null

	Set @ErrorCode=@@Error

	If @ErrorCode=0
	and @sSQLString is not null
	Begin
		set @sSQLString='Alter table #TEMPCASEDETAILS Add '+@sSQLString

		exec(@sSQLString)
		Set @ErrorCode=@@Error
	End
End

If @ErrorCode = 0
Begin
	Set @sSQLString = 'Select @nOpenItemStatus = STATUS
			from OPENITEM
			where OPENITEMNO=@sOpenItemNo
			and ITEMENTITYNO=@nEntityNo'

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@nOpenItemStatus	int OUTPUT,
					  @sOpenItemNo		nvarchar(12),
					  @nEntityNo		int',
					  @nOpenItemStatus=@nOpenItemStatus OUTPUT,
					  @sOpenItemNo=@sOpenItemNo,
					  @nEntityNo=@nEntityNo
End

------------------------------------------------------
-- Get the Clients Reference, Our Reference and
-- Purchase Order Nos, Language, DebtorNo and NameType
-- for all Cases being billed separated by a comma.
------------------------------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString='
	Select @sYourRef =   CASE WHEN CN.REFERENCENO IS NULL THEN @sYourRef                   -- no reference, not change to string 
                                  WHEN CHARINDEX(CN.REFERENCENO, @sYourRef) > 0 THEN @sYourRef -- already in string don’t append 
                                  WHEN @sYourRef IS NULL THEN CN.REFERENCENO                   -- first time a ref found
                                  ELSE @sYourRef + '', ''  + CN.REFERENCENO                    -- append with a comma separator
			     END,
              @sOurRef =     CASE WHEN C.IRN IS NULL THEN @sOurRef
                                  WHEN CHARINDEX(C.IRN, @sOurRef) > 0 THEN @sOurRef
                                  WHEN @sOurRef is NULL THEN C.IRN
                                  ELSE @sOurRef + '', '' + C.IRN
			     END,
              @sPurchaseNo=  CASE WHEN C.PURCHASEORDERNO IS NULL THEN @sPurchaseNo
                                  WHEN CHARINDEX(C.PURCHASEORDERNO, @sPurchaseNo) > 0  THEN  @sPurchaseNo
                                  WHEN @sPurchaseNo IS NULL THEN  C.PURCHASEORDERNO
                                  ELSE @sPurchaseNo + '', ''+ C.PURCHASEORDERNO
			     END,
	       @bRenewalFlag=cast(O.RENEWALDEBTORFLAG as bit),
	       @nLanguage	=isnull(O.LANGUAGE,S.COLINTEGER),
	       @nDebtorNo	=O.ACCTDEBTORNO,
	       @sNameType	=CASE WHEN(O.RENEWALDEBTORFLAG=1) THEN ''Z'' ELSE ''D'' END,
	       @nBillPercent	=isnull(O.BILLPERCENTAGE,100)/100
	from OPENITEM O'
	
	-- draft cases won't necessarily have WORKHISTORY
	If (@nOpenItemStatus = 0)
	Begin
		Set @sSQLString= @sSQLString + char(10) + 
		'Left join ( select BI.ITEMENTITYNO AS REFENTITYNO, BI.ITEMTRANSNO AS REFTRANSNO, W.CASEID
				from BILLEDITEM BI
				join WORKINPROGRESS W ON (BI.WIPTRANSNO = W.TRANSNO
							AND BI.WIPENTITYNO = W.ENTITYNO
							AND BI.WIPSEQNO = W.WIPSEQNO)
				group by BI.ITEMENTITYNO, BI.ITEMTRANSNO, W.CASEID) WH'
	End
	Else
	Begin
		Set @sSQLString= @sSQLString + char(10) + 
		'Left join ( select  REFENTITYNO, REFTRANSNO, CASEID
			from WORKHISTORY
			group by REFENTITYNO, REFTRANSNO, CASEID) WH'
	End	
	
	-- OPENITEMs may not be related to any cases, but we still want to return language, debtor etc.
	Set @sSQLString= @sSQLString + char(10) + 
					'on (WH.REFENTITYNO=O.ITEMENTITYNO
					and WH.REFTRANSNO =O.ITEMTRANSNO)
	left join CASES C		on (C.CASEID=WH.CASEID)
	left join CASENAME CN	on (CN.CASEID=C.CASEID
				and CN.NAMENO=O.ACCTDEBTORNO
				and CN.NAMETYPE=CASE WHEN(O.RENEWALDEBTORFLAG=1) THEN ''Z'' ELSE ''D'' END)
	left join SITECONTROL S	on (S.CONTROLID=''LANGUAGE'')
	where O.OPENITEMNO=@sOpenItemNo
	and O.ITEMENTITYNO=@nEntityNo
	order by C.IRN'

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
					  @nBillPercent		decimal(5,2)	OUTPUT',
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
	Select	@nHomeNameNo	=S0.COLINTEGER,
		@sLocalCurrency =S1.COLCHARACTER,
		@sTaxLiteral	=S2.COLCHARACTER,
		@sClientAlias	=S3.COLCHARACTER,
		@sFirmAlias	=S4.COLCHARACTER
	From SITECONTROL S0
	left join SITECONTROL S1	on (S1.CONTROLID='CURRENCY')
	left join SITECONTROL S2	on (S2.CONTROLID='TAXLITERAL')
	left join SITECONTROL S3	on (S3.CONTROLID='E-Bill Client Alias Type')
	left join SITECONTROL S4	on (S4.CONTROLID='E-Bill Law Firm Alias Type')
	Where S0.CONTROLID='HOMENAMENO'

	Set @ErrorCode=@@Error
End

If @ErrorCode=0
Begin
	insert into #TEMPITEMHEADER (
			OpenItemNo,
			AccountNo,
			LawFirmID,
			LawFirmName,
			LawFirmAddress1,
			LawFirmAddress2,
			LawFirmCity,
			LawFirmState,
			LawFirmPostcode,
			LawFirmCountry,
			LawFirmCountryCode,
			LawFirmPhoneNumber,
			YourRef,
			ItemDate,
			RefText,
			TaxLocal,
			TaxForeign,
			CurrencyLocal,
			LocalValue,
			LocalServiceChargeValue,
			LocalExpenseValue,
			LocalServiceChargeAdjust,
			LocalExpenseAdjust,
			CurrencyForeign,
			CurrencyFlag,
			ForeignValue,
			ForeignServiceChargeValue,
			ForeignExpenseValue,
			ForeignServiceChargeAdjust,
			ForeignExpenseAdjust,
			BillPercentage,
			TaxLabel,
			TaxFlag,
			DebtorName,
			DebtorAddress,
			DebtorAttentionName,
			DebtorAddress1,
			DebtorAddress2,
			DebtorCity,
			DebtorState,
			DebtorPostcode,
			DebtorCountry,
			DebtorCountryCode,
			DebtorPhoneNumber,
			StatusText,
			OurRef,
			PurchaseOrderNo,
			StaffName,
			Regarding,
			BillScope,
			Reductions,
			CreditNoteFlag,
			ForeignReductions,
			TaxNumber,
			ImageId,
			ForeignEquivCurrency,
			ForeignEquivExRate,
			PenaltyInterestRate,
			DueDate,
			LocalTakenUp,
			ForeignTakenUp,
			OpenItemAction)
	select 		O.OPENITEMNO,
			isnull(NA.ALIAS,N.NAMECODE),
			coalesce(NF.ALIAS,NH.ALIAS,N1.NAMECODE),
			N1.NAME,
			replace(replace((select Parameter from dbo.fn_Tokenise (A1.STREET1,char(10)) where InsertOrder=1),char(10),''),char(13),''),	-- Strip out carriage return and line feed
			replace(replace((select Parameter from dbo.fn_Tokenise (A1.STREET1,char(10)) where InsertOrder=2),char(10),''),char(13),''),	-- Strip out carriage return and line feed
			A1.CITY,
			A1.STATE,
			A1.POSTCODE,
			C1.COUNTRY,
			C1.COUNTRYCODE,
			dbo.fn_FormatTelecom(T1.TELECOMTYPE, T1.ISD, T1.AREACODE, T1.TELECOMNUMBER, T1.EXTENSION),
			isnull(NS.FORMATTEDREFERENCE, @sYourRef),  -- Clients reference separated by semi colon
			O.ITEMDATE,
			coalesce(O.LONGREFTEXT,O.REFERENCETEXT),	-- SQA21327
			O.LOCALTAXAMT,
			O.FOREIGNTAXAMT,
			@sLocalCurrency,-- Local Currency
			O.LOCALVALUE,
			WH.LOCALSERVICEVALUE,
			WH.LOCALEXPENSEVALUE,
			WH.LOCALSERVICEADJUST,
			WH.LOCALEXPENSEADJUST,
			O.CURRENCY,
			CASE WHEN(O.CURRENCY<>@sLocalCurrency) THEN 1 ELSE 0 END, -- Flag indicates foreign currency
			O.FOREIGNVALUE,
			WH.FOREIGNSERVICEVALUE,
			WH.FOREIGNEXPENSEVALUE,
			WH.FOREIGNSERVICEADJUST,
			WH.FOREIGNEXPENSEADJUST,
			O.BILLPERCENTAGE,
			@sTaxLiteral,	-- Tax literal
			CASE WHEN(O.LOCALTAXAMT<>0) THEN 1 ELSE 0 END,
			NS.FORMATTEDNAME,
			NS.FORMATTEDADDRESS,
			NS.FORMATTEDATTENTION,
			replace(replace((select Parameter from dbo.fn_Tokenise (A2.STREET1,char(10)) where InsertOrder=1),char(10),''),char(13),''),	-- Strip out carriage return and line feed
			replace(replace((select Parameter from dbo.fn_Tokenise (A2.STREET1,char(10)) where InsertOrder=2),char(10),''),char(13),''),	-- Strip out carriage return and line feed
			A2.CITY,
			A2.STATE,
			A2.POSTCODE,
			C2.COUNTRY,
			C2.COUNTRYCODE,
			dbo.fn_FormatTelecom(T2.TELECOMTYPE, T2.ISD, T2.AREACODE, T2.TELECOMNUMBER, T2.EXTENSION),
			CASE WHEN(O.STATUS=0) THEN 'DRAFT' END,
			@sOurRef,	-- IRNs separated by Semi Colon
			isnull(@sPurchaseNo,IP.PURCHASEORDERNO),-- Purchase Orders from Cases separated by Semicolon OR Purchase Order from IPNAME
			E.SIGNOFFNAME,
			CASE WHEN(datalength(O.LONGREGARDING)>0) THEN O.LONGREGARDING ELSE O.REGARDING END,
			O.SCOPE,
			Null,		-- Reductions
			CASE WHEN(O.ITEMTYPE=511) THEN 1 ELSE 0 END,
			Null,		-- ForeignReductions
			N.TAXNO,
			O.IMAGEID,
			O.FOREIGNEQUIVCURRCY,
			O.FOREIGNEQUIVEXRATE,
			O.PENALTYINTEREST,
			O.ITEMDUEDATE,
			O.LOCALORIGTAKENUP,
			O.FOREIGNORIGTAKENUP,
			O.ACTION
	from OPENITEM O
	left join (SELECT WH.REFENTITYNO, WH.REFTRANSNO, 
			  SUM(CASE WHEN(WT.CATEGORYCODE ='SC' and WH.REASONCODE is null)     THEN isnull(WH.LOCALTRANSVALUE,0) *-1 ELSE 0 END) AS LOCALSERVICEVALUE, 
			  SUM(CASE WHEN(WT.CATEGORYCODE ='SC' and WH.REASONCODE is null)     THEN isnull(WH.FOREIGNTRANVALUE,0)*-1 ELSE 0 END) AS FOREIGNSERVICEVALUE, 
			  SUM(CASE WHEN(WT.CATEGORYCODE<>'SC' and WH.REASONCODE is null)     THEN isnull(WH.LOCALTRANSVALUE,0) *-1 ELSE 0 END) AS LOCALEXPENSEVALUE, 
			  SUM(CASE WHEN(WT.CATEGORYCODE<>'SC' and WH.REASONCODE is null)     THEN isnull(WH.FOREIGNTRANVALUE,0)*-1 ELSE 0 END) AS FOREIGNEXPENSEVALUE, 
			  SUM(CASE WHEN(WT.CATEGORYCODE ='SC' and WH.REASONCODE is not null) THEN isnull(WH.LOCALTRANSVALUE,0) *-1 ELSE 0 END) AS LOCALSERVICEADJUST, 
			  SUM(CASE WHEN(WT.CATEGORYCODE ='SC' and WH.REASONCODE is not null) THEN isnull(WH.FOREIGNTRANVALUE,0)*-1 ELSE 0 END) AS FOREIGNSERVICEADJUST, 
			  SUM(CASE WHEN(WT.CATEGORYCODE<>'SC' and WH.REASONCODE is not null) THEN isnull(WH.LOCALTRANSVALUE,0) *-1 ELSE 0 END) AS LOCALEXPENSEADJUST, 
			  SUM(CASE WHEN(WT.CATEGORYCODE<>'SC' and WH.REASONCODE is not null) THEN isnull(WH.FOREIGNTRANVALUE,0)*-1 ELSE 0 END) AS FOREIGNEXPENSEADJUST
	           from WORKHISTORY WH
	           join WIPTEMPLATE W	on (W.WIPCODE   =WH.WIPCODE)
	           join WIPTYPE WT	on (WT.WIPTYPEID=W.WIPTYPEID)
	           group by WH.REFENTITYNO, WH.REFTRANSNO) WH	on (WH.REFENTITYNO=O.ITEMENTITYNO
								and WH.REFTRANSNO =O.ITEMTRANSNO)
	join NAME N			on (N.NAMENO=O.ACCTDEBTORNO)
	left join IPNAME IP		on (IP.NAMENO=N.NAMENO)
	left join NAMEALIAS NA		on (NA.NAMENO=N.NAMENO
					and NA.ALIASTYPE=isnull(@sClientAlias,'D')
					and NA.COUNTRYCODE  is null
					and NA.PROPERTYTYPE is null)
	left join NAMEALIAS NF		on (NF.NAMENO=N.NAMENO
					and NF.ALIASTYPE=@sFirmAlias
					and NF.COUNTRYCODE  is null
					and NF.PROPERTYTYPE is null)
	     join NAME N1		on (N1.NAMENO=@nHomeNameNo)
	left join ADDRESS A1		on (A1.ADDRESSCODE=N1.STREETADDRESS)
	left join COUNTRY C1		on (C1.COUNTRYCODE=A1.COUNTRYCODE)
	left join TELECOMMUNICATION T1	on (T1.TELECODE   =N1.MAINPHONE)
	left join ASSOCIATEDNAME AN	on (AN.NAMENO=O.ACCTDEBTORNO
					and AN.RELATIONSHIP='BIL')
	left join ADDRESS A2		on (A2.ADDRESSCODE= isnull(AN.POSTALADDRESS,N.POSTALADDRESS))
	left join COUNTRY C2		on (C2.COUNTRYCODE=A2.COUNTRYCODE)
	left join TELECOMMUNICATION T2	on (T2.TELECODE   =isnull(AN.TELEPHONE,N.MAINPHONE))
	left join NAMEALIAS NH		on (NH.NAMENO=N1.NAMENO
					and NH.ALIASTYPE=@sFirmAlias
					and NH.COUNTRYCODE  is null
					and NH.PROPERTYTYPE is null)
	     join NAMEADDRESSSNAP NS	on (NS.NAMESNAPNO=O.NAMESNAPNO)
	left join EMPLOYEE E		on (E.EMPLOYEENO=O.EMPLOYEENO)
	where O.OPENITEMNO=@sOpenItemNo
	and O.ITEMENTITYNO=@nEntityNo

	Set @ErrorCode=@@Error
End

---------------------------------
-- Get details for the first Case
-- associated with the Bill
---------------------------------
If @ErrorCode=0
Begin
	Update #TEMPITEMHEADER
	Set CaseTitle             =C.TITLE,
	    CaseStaffFirstName    =N1.FIRSTNAME,
	    CaseStaffSurname      =N1.NAME,
	    CaseAttentionFirstName=N2.FIRSTNAME,
	    CaseAttentionSurname  =N2.NAME
	From #TEMPITEMHEADER T
	join OPENITEM O		on (O.OPENITEMNO=@sOpenItemNo
				and O.ITEMENTITYNO=@nEntityNo)
	left join BILLLINE B	on (B.ITEMENTITYNO=O.ITEMENTITYNO
      		  		and B.ITEMTRANSNO =O.ITEMTRANSNO
      		  		and O.MAINCASEID is null
      		  		and B.ITEMLINENO  =(SELECT MIN(B1.ITEMLINENO)
      		  				    from BILLLINE B1
      		  				    where B1.ITEMENTITYNO=B.ITEMENTITYNO
      		  				    and   B1.ITEMTRANSNO =B.ITEMTRANSNO
      		  				    and   B1.IRN is not null))
	join CASES C		on (C.CASEID=O.MAINCASEID
				or  C.IRN   =B.IRN)
	join CASENAME CN1	on (CN1.CASEID=C.CASEID
				and CN1.NAMETYPE='EMP'
				and CN1.SEQUENCE= (SELECT MIN(CN.SEQUENCE)
						   from CASENAME CN
						   where CN.CASEID=CN1.CASEID
						   and CN.NAMETYPE=CN1.NAMETYPE
						   and CN.EXPIRYDATE is null))
        join NAME N1		on (N1.NAMENO=CN1.NAMENO)
	join CASENAME CN2	on (CN2.CASEID=C.CASEID
				and CN2.NAMETYPE='I'
				and CN2.SEQUENCE= (SELECT MIN(CN.SEQUENCE)
						   from CASENAME CN
						   where CN.CASEID=CN2.CASEID
						   and CN.NAMETYPE=CN2.NAMETYPE
						   and CN.EXPIRYDATE is null))
	join NAME N2		on (N2.NAMENO=CN2.CORRESPONDNAME)
	
	Set @ErrorCode=@@Error
				    
End

-----------------------------------------------
-- Get the Bill Line Details
-- Note that if the Bill Line does not contain 
-- the IRN details then revert to the 
-- WorkHistory rows to get the details required.
-----------------------------------------------
If @ErrorCode=0
and @sSelectBillLines is not null
Begin
	Set @sSQLString = '
	with CTE_FirstName (CASEID, NAMETYPE, SEQUENCE)
		as (	select CASEID, NAMETYPE, MIN(SEQUENCE)
			from CASENAME with (NOLOCK)
			where EXPIRYDATE is null or EXPIRYDATE>GETDATE()
			group by CASEID, NAMETYPE)
	Insert into #TEMPBILLLINES(DetailDisplaySequence, DetailChargeOutRate, 
				DetailStaffName, DetailDate, DetailCaseReference, DetailYourRef, DetailTime, 
				DetailWIPCode, DetailWIPTypeId, DetailWIPCategory, DetailCatDesc, 
				DetailNarrative, DetailValue, DetailForeignValue, DetailTaxTotal,
				DetailChargeCurrency, DetailStaffClass, DetailStaffClassCode,DetailStaffCode, DetailStaffInit,
				DetailCaseCountryCode, DetailCaseCountry, DetailCaseTypeDesc, 
				DetailPropertyType, DetailOfficialNo, DetailCaseTitle, DetailCasePurchaseOrder,
				DetailNarrativeNo, DetailDebtorReference, DetailNumberOfUnits,
				DetailDiscountValue, DetailDiscountForeignValue, DetailForeignChargeOutRate,
				DetailGrossAmount, DetailForeignGrossAmount, DetailTaxType, DetailTaxRate,
				DetailForeignTaxAmount, DetailFirstApplicant, DetailNumberType_A, DetailNumberType_5)
	select 	B.DISPLAYSEQUENCE, 
		B.PRINTCHARGEOUTRATE,
		isnull(B.PRINTNAME,dbo.fn_FormatNameUsingNameNo(N.NAMENO,7101)), 
		B.PRINTDATE, 
		C.IRN, 
		D.REFERENCENO,
		CASE WHEN(B.PRINTCHARGEOUTRATE IS NOT NULL) THEN B.PRINTTIME END,
		B.WIPCODE, 
		B.WIPTYPEID, 
		W.CATEGORYCODE,
		W.DESCRIPTION, 
		CASE WHEN(datalength(LONGNARRATIVE)>0) THEN convert(nvarchar(max),LONGNARRATIVE) ELSE SHORTNARRATIVE END,
		B.VALUE, 
		B.FOREIGNVALUE,
		B.LOCALTAX,
		B.PRINTCHARGECURRNCY,
		T.DESCRIPTION,	-- Staff Classification Description
		E.STAFFCLASS,	-- Staff Classification Code
		N.NAMECODE,
		N.INITIALS,
		C.COUNTRYCODE,
		CN.COUNTRY,
		CT.CASETYPEDESC,
		VP.PROPERTYNAME,
		C.CURRENTOFFICIALNO,
		C.TITLE,
		C.PURCHASEORDERNO,
		B.NARRATIVENO,
		REF.REFERENCENO,
		WH.ENTEREDQUANTITY,
		(-1 * isnull(WH.DISCOUNTVALUE, 0.00))                         as DetailDiscountValue,
		(-1 * isnull(WH.DISCOUNTVALUE * O.EXCHRATE, 0.00))            as DetailDiscountForeignValue,
		(O.EXCHRATE * isnull(B.PRINTCHARGEOUTRATE, WH.CHARGEOUTRATE)) as DetailForeignChargeOutRate,
		(B.VALUE + isnull(B.LOCALTAX,0) + isnull(WH.DISCOUNTVALUE, 0.00) ) 
									      as DetailGrossAmount,
		(B.FOREIGNVALUE + isnull((O.EXCHRATE * B.LOCALTAX),0) + isnull(WH.DISCOUNTVALUE * O.EXCHRATE, 0.00))
									      as DetailForeignGrossAmount,
		TR.DESCRIPTION                                                as DetailTaxType,
		X.TAXRATE						      as DetailTaxRate,
		(O.EXCHRATE * B.LOCALTAX)				      as DetailForeignTaxAmount,
		dbo.fn_FormatNameUsingNameNo(OW.NAMENO,7101)	              as DetailFirstApplicant,
		O_A.OFFICIALNUMBER					      as DetailNumberType_A,
		O_5.OFFICIALNUMBER					      as DetailNumberType_5
	from OPENITEM O
	join BILLLINE B		on (B.ITEMENTITYNO=O.ITEMENTITYNO
      		  		and B.ITEMTRANSNO =O.ITEMTRANSNO)
	left join CASES C	on (C.IRN=B.IRN)
	left join TAXRATES TR	on (TR.TAXCODE=B.TAXCODE)
	left join OPENITEMTAX X on (X.ITEMENTITYNO=O.ITEMENTITYNO
				and X.ITEMTRANSNO =O.ITEMTRANSNO
				and X.ACCTENTITYNO=O.ACCTENTITYNO
				and X.ACCTDEBTORNO=O.ACCTDEBTORNO
				and X.TAXCODE     =B.TAXCODE)
	left join OFFICIALNUMBERS O_A
				on (O_A.CASEID=C.CASEID
				and O_A.NUMBERTYPE=''A'')
	left join OFFICIALNUMBERS O_5
				on (O_5.CASEID=C.CASEID
				and O_5.NUMBERTYPE=''5'')
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
				and EMP.NAMETYPE=''EMP''
				and EMP.EXPIRYDATE is null
				and E1.EMPLOYEENO  is null)
	left join CASENAME OW	on (OW.CASEID=C.CASEID
				and OW.NAMETYPE=''O''
				and OW.SEQUENCE=(select SEQUENCE
						 from CTE_FirstName CTE
						 where CTE.CASEID  =OW.CASEID
						 and   CTE.NAMETYPE=''O''))
	left join WIPCATEGORY W	on (W.CATEGORYCODE=B.CATEGORYCODE)
	left join EMPLOYEE E	on (E.EMPLOYEENO=coalesce( E1.EMPLOYEENO, 
							  (select min(WH.EMPLOYEENO)
							   from WORKHISTORY WH
							   Where WH.REFENTITYNO=O.ITEMENTITYNO
							   and WH.REFTRANSNO =O.ITEMTRANSNO
							   and WH.BILLLINENO =B.ITEMLINENO
							   and WH.MOVEMENTCLASS=2	-- SQA20350 Use Billing movement class to exclude write ups/downs.
							   and WH.EMPLOYEENO is not null),
							   EMP.NAMENO))
	left join TABLECODES T	on (T.TABLECODE=isnull(E1.STAFFCLASS,E.STAFFCLASS))
	left join NAME N	on (N.NAMENO=E.EMPLOYEENO)
	left join COUNTRY CN	on (CN.COUNTRYCODE=C.COUNTRYCODE)
	left join CASETYPE CT	on (CT.CASETYPE=C.CASETYPE)
	left join VALIDPROPERTY VP	on (VP.PROPERTYTYPE=C.PROPERTYTYPE
					and VP.COUNTRYCODE=(	select min(VP1.COUNTRYCODE)
								from VALIDPROPERTY VP1
								where VP1.PROPERTYTYPE=VP.PROPERTYTYPE
								and VP1.COUNTRYCODE in (C.COUNTRYCODE, ''ZZZ'')))
	left join CASENAME D	on (D.CASEID  =C.CASEID
				and D.NAMETYPE=@sNameType
				and D.NAMENO  =@nDebtorNo)
	left join CASENAME REF	on (REF.CASEID=C.CASEID
				and REF.NAMETYPE=CASE WHEN(O.RENEWALDEBTORFLAG=1) THEN ''Z'' ELSE ''D'' END
				and REF.NAMENO=O.ACCTDEBTORNO
				and REF.EXPIRYDATE is null)'
      	
	-- Flatten the associated WIP join in case of merged rows	  		
	if @nOpenItemStatus = 0
	Begin
		-- Draft items retrieve from BILLEDITEM/WORKINPROGRESS
      		Set @sSQLString = @sSQLString + char(10) + '
      		left join (SELECT BL.ITEMENTITYNO, BL.ITEMTRANSNO, BL.ITEMLINENO, 
      				  sum(CASE WHEN(W.ENTEREDQUANTITY>0) THEN W.ENTEREDQUANTITY ELSE 0 END) as ENTEREDQUANTITY, 
      				  sum(CASE WHEN(W.DISCOUNTFLAG=1)    THEN W.LOCALVALUE      ELSE 0 END) as DISCOUNTVALUE,
      				  max(W.CHARGEOUTRATE)                                                  as CHARGEOUTRATE
			FROM BILLEDITEM BL 
			JOIN WORKINPROGRESS W ON (W.TRANSNO  = BL.WIPTRANSNO
					      and W.ENTITYNO = BL.WIPENTITYNO
					      and W.WIPSEQNO = BL.WIPSEQNO)
			WHERE BL.ITEMENTITYNO = @nEntityNo
			and BL.ITEMTRANSNO = @nTransNo
			and(W.ENTEREDQUANTITY>0 OR W.DISCOUNTFLAG=1 OR W.CHARGEOUTRATE is not null)
			GROUP BY BL.ITEMENTITYNO, BL.ITEMTRANSNO, BL.ITEMLINENO) AS WH on (WH.ITEMENTITYNO = B.ITEMENTITYNO
							and WH.ITEMTRANSNO = B.ITEMTRANSNO
							and WH.ITEMLINENO = B.ITEMLINENO)'
	End
	Else
	Begin
		-- Finalised items retrieve from WORKHISTORY
      		Set @sSQLString = @sSQLString + char(10) + '
      		left join (SELECT BL.ITEMENTITYNO, BL.ITEMTRANSNO, BL.ITEMLINENO, 
      				  sum(CASE WHEN(W1.ENTEREDQUANTITY>0) THEN W1.ENTEREDQUANTITY ELSE 0 END) as ENTEREDQUANTITY, 
      				  sum(CASE WHEN(W.DISCOUNTFLAG=1)     THEN W.LOCALTRANSVALUE  ELSE 0 END) as DISCOUNTVALUE,
      				  max(W1.CHARGEOUTRATE)                                                   as CHARGEOUTRATE
			FROM BILLLINE BL 
			join WORKHISTORY W	on (W.REFENTITYNO=BL.ITEMENTITYNO
						and W.REFTRANSNO =BL.ITEMTRANSNO
						and W.BILLLINENO =BL.ITEMLINENO)
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
								      and   W2.MOVEMENTCLASS in (1,4)))
			WHERE BL.ITEMENTITYNO = @nEntityNo
			and BL.ITEMTRANSNO = @nTransNo
			and(W1.ENTEREDQUANTITY>0 OR W.DISCOUNTFLAG=1 OR W1.CHARGEOUTRATE is not null)
			GROUP BY BL.ITEMENTITYNO, BL.ITEMTRANSNO, BL.ITEMLINENO) AS WH on (WH.ITEMENTITYNO = B.ITEMENTITYNO
							and WH.ITEMTRANSNO = B.ITEMTRANSNO
							and WH.ITEMLINENO = B.ITEMLINENO)'
	End
				
	Set @sSQLString = @sSQLString + char(10) + '
	where O.OPENITEMNO=@sOpenItemNo
	and O.ITEMENTITYNO=@nEntityNo
	and B.IRN IS NOT NULL AND B.IRN != '''''
	
	-------------------------------------------------------------
	-- When the BILLLINE does not specify the IRN then the 
	-- Case will be determined from either the WorkInProgress
	-- or WorkHistory depending on whether the bill is finalised.
	-------------------------------------------------------------
	Set @sSQLString = @sSQLString + char(10) + '
	UNION ALL
	select 	B.DISPLAYSEQUENCE, 
		B.PRINTCHARGEOUTRATE,
		isnull(B.PRINTNAME,dbo.fn_FormatNameUsingNameNo(N.NAMENO,7101)), 
		B.PRINTDATE,
		C.IRN,
		D.REFERENCENO,
		CASE WHEN(B.PRINTCHARGEOUTRATE IS NOT NULL) THEN B.PRINTTIME END,
		B.WIPCODE, 
		WT.WIPTYPEID, 
		W.CATEGORYCODE,
		W.DESCRIPTION, 
		isnull(B.LONGNARRATIVE, B.SHORTNARRATIVE),
		B.VALUE,
		B.FOREIGNVALUE,
		B.LOCALTAX,
		B.PRINTCHARGECURRNCY,
		T.DESCRIPTION,	-- Staff Classification Description
		E.STAFFCLASS,	-- Staff Classification Code
		N.NAMECODE,
		N.INITIALS,
		C.COUNTRYCODE,
		CN.COUNTRY,
		CT.CASETYPEDESC,
		VP.PROPERTYNAME,
		C.CURRENTOFFICIALNO,
		C.TITLE,
		C.PURCHASEORDERNO,
		B.NARRATIVENO,
		REF.REFERENCENO,
		Q.ENTEREDQUANTITY,
		(-1 * isnull(Q.DISCOUNTVALUE, 0.00))                         as DetailDiscountValue,
		(-1 * isnull(Q.DISCOUNTVALUE * O.EXCHRATE, 0.00))            as DetailDiscountForeignValue,
		(O.EXCHRATE * isnull(B.PRINTCHARGEOUTRATE, Q.CHARGEOUTRATE)) as DetailForeignChargeOutRate,
		(B.VALUE + isnull(B.LOCALTAX,0) + isnull(Q.DISCOUNTVALUE, 0.00))                            
									     as DetailGrossAmount,
		(B.FOREIGNVALUE + isnull((O.EXCHRATE * B.LOCALTAX),0) + isnull(Q.DISCOUNTVALUE * O.EXCHRATE, 0.00))       
									     as DetailForeignGrossAmount,
		TR.DESCRIPTION                                               as DetailTaxType,
		X.TAXRATE						     as DetailTaxRate,
		(O.EXCHRATE * B.LOCALTAX)				     as DetailForeignTaxAmount,
		dbo.fn_FormatNameUsingNameNo(OW.NAMENO,7101)	             as DetailFirstApplicant,
		O_A.OFFICIALNUMBER					     as DetailNumberType_A,
		O_5.OFFICIALNUMBER					     as DetailNumberType_5
	from OPENITEM O
	join BILLLINE B		on (B.ITEMENTITYNO=O.ITEMENTITYNO
      		  		and B.ITEMTRANSNO =O.ITEMTRANSNO)
	left join TAXRATES TR	on (TR.TAXCODE=B.TAXCODE)
	left join OPENITEMTAX X on (X.ITEMENTITYNO=O.ITEMENTITYNO
				and X.ITEMTRANSNO =O.ITEMTRANSNO
				and X.ACCTENTITYNO=O.ACCTENTITYNO
				and X.ACCTDEBTORNO=O.ACCTDEBTORNO
				and X.TAXCODE     =B.TAXCODE)'
      	
	-- Flatten the associated WIP join in case of merged rows	  		
	if @nOpenItemStatus = 0
	Begin
		-- Draft items retrieve from BILLEDITEM/WORKINPROGRESS
      		Set @sSQLString = @sSQLString + char(10) + '
      		join (SELECT BL.ITEMENTITYNO, BL.ITEMTRANSNO, BL.ITEMLINENO, MIN(W.CASEID) as CASEID
			FROM BILLEDITEM BL 
			JOIN WORKINPROGRESS W ON (W.TRANSNO  = BL.WIPTRANSNO
					      and W.ENTITYNO = BL.WIPENTITYNO
					      and W.WIPSEQNO = BL.WIPSEQNO)
			WHERE BL.ITEMENTITYNO = @nEntityNo
			and BL.ITEMTRANSNO = @nTransNo
			GROUP BY BL.ITEMENTITYNO, BL.ITEMTRANSNO, BL.ITEMLINENO) AS WH on (WH.ITEMENTITYNO = B.ITEMENTITYNO
							and WH.ITEMTRANSNO = B.ITEMTRANSNO
							and WH.ITEMLINENO = B.ITEMLINENO)
		join (SELECT BL.ITEMENTITYNO, BL.ITEMTRANSNO, BL.ITEMLINENO, MIN(W.EMPLOYEENO) as EMPLOYEENO
			FROM BILLEDITEM BL 
			JOIN WORKINPROGRESS W ON (W.TRANSNO  = BL.WIPTRANSNO
					      and W.ENTITYNO = BL.WIPENTITYNO
					      and W.WIPSEQNO = BL.WIPSEQNO)
			WHERE BL.ITEMENTITYNO = @nEntityNo
			and BL.ITEMTRANSNO = @nTransNo
			GROUP BY BL.ITEMENTITYNO, BL.ITEMTRANSNO, BL.ITEMLINENO) AS WHE on (WHE.ITEMENTITYNO = B.ITEMENTITYNO
						and WHE.ITEMTRANSNO = B.ITEMTRANSNO
						and WHE.ITEMLINENO = B.ITEMLINENO)
      		left join (SELECT BL.ITEMENTITYNO, BL.ITEMTRANSNO, BL.ITEMLINENO, 
      				  sum(CASE WHEN(W.ENTEREDQUANTITY>0) THEN W.ENTEREDQUANTITY ELSE 0 END) as ENTEREDQUANTITY, 
      				  sum(CASE WHEN(W.DISCOUNTFLAG=1)    THEN W.LOCALVALUE      ELSE 0 END) as DISCOUNTVALUE,
      				  max(W.CHARGEOUTRATE)                                                  as CHARGEOUTRATE
			FROM BILLEDITEM BL 
			JOIN WORKINPROGRESS W ON (W.TRANSNO  = BL.WIPTRANSNO
					      and W.ENTITYNO = BL.WIPENTITYNO
					      and W.WIPSEQNO = BL.WIPSEQNO)
			WHERE BL.ITEMENTITYNO = @nEntityNo
			and BL.ITEMTRANSNO = @nTransNo
			and(W.ENTEREDQUANTITY is not null OR W.DISCOUNTFLAG=1 OR W.CHARGEOUTRATE is not null)
			GROUP BY BL.ITEMENTITYNO, BL.ITEMTRANSNO, BL.ITEMLINENO) AS Q on (Q.ITEMENTITYNO = B.ITEMENTITYNO
							and Q.ITEMTRANSNO = B.ITEMTRANSNO
							and Q.ITEMLINENO = B.ITEMLINENO)'
	End
	Else
	Begin
		-- Finalised items retrieve from WORKHISTORY
      		Set @sSQLString = @sSQLString + char(10) + '
      		join (SELECT BL.ITEMENTITYNO, BL.ITEMTRANSNO, BL.ITEMLINENO, MIN(W.CASEID) as CASEID
			FROM BILLLINE BL 
			join WORKHISTORY W	on (W.REFENTITYNO=BL.ITEMENTITYNO
						and W.REFTRANSNO =BL.ITEMTRANSNO
						and W.BILLLINENO =BL.ITEMLINENO)
			WHERE BL.ITEMENTITYNO = @nEntityNo
			and BL.ITEMTRANSNO = @nTransNo
			GROUP BY BL.ITEMENTITYNO, BL.ITEMTRANSNO, BL.ITEMLINENO) AS WH on (WH.ITEMENTITYNO = B.ITEMENTITYNO
							and WH.ITEMTRANSNO = B.ITEMTRANSNO
							and WH.ITEMLINENO = B.ITEMLINENO)
		join (SELECT BL.ITEMENTITYNO, BL.ITEMTRANSNO, BL.ITEMLINENO, MIN(W.EMPLOYEENO) as EMPLOYEENO
			FROM BILLLINE BL
			join WORKHISTORY W	on (W.REFENTITYNO=BL.ITEMENTITYNO
						and W.REFTRANSNO =BL.ITEMTRANSNO
						and W.BILLLINENO =BL.ITEMLINENO)
			WHERE BL.ITEMENTITYNO = @nEntityNo
			and BL.ITEMTRANSNO = @nTransNo
			GROUP BY BL.ITEMENTITYNO, BL.ITEMTRANSNO, 
			BL.ITEMLINENO) AS WHE on (WHE.ITEMENTITYNO = B.ITEMENTITYNO
						and WHE.ITEMTRANSNO = B.ITEMTRANSNO
						and WHE.ITEMLINENO = B.ITEMLINENO)
      		left join (SELECT BL.ITEMENTITYNO, BL.ITEMTRANSNO, BL.ITEMLINENO, 
      				  sum(CASE WHEN(W1.ENTEREDQUANTITY>0) THEN W1.ENTEREDQUANTITY ELSE 0 END) as ENTEREDQUANTITY, 
      				  sum(CASE WHEN(W.DISCOUNTFLAG=1)     THEN W.LOCALTRANSVALUE  ELSE 0 END) as DISCOUNTVALUE,
      				  max(W1.CHARGEOUTRATE)                                                   as CHARGEOUTRATE
			FROM BILLLINE BL 
			join WORKHISTORY W	on (W.REFENTITYNO=BL.ITEMENTITYNO
						and W.REFTRANSNO =BL.ITEMTRANSNO
						and W.BILLLINENO =BL.ITEMLINENO)
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
								      and   W2.MOVEMENTCLASS in (1,4)))
			WHERE BL.ITEMENTITYNO = @nEntityNo
			and BL.ITEMTRANSNO = @nTransNo
			and(W1.ENTEREDQUANTITY>0 OR W.DISCOUNTFLAG=1 OR W1.CHARGEOUTRATE is not null)
			GROUP BY BL.ITEMENTITYNO, BL.ITEMTRANSNO, BL.ITEMLINENO) AS Q on (Q.ITEMENTITYNO = B.ITEMENTITYNO
							and Q.ITEMTRANSNO = B.ITEMTRANSNO
							and Q.ITEMLINENO = B.ITEMLINENO)'
	End
	
	Set @sSQLString = @sSQLString + char(10) + 'join WIPTEMPLATE WP	on (WP.WIPCODE    =B.WIPCODE)
	join WIPTYPE WT		on (WT.WIPTYPEID  =WP.WIPTYPEID)
	join WIPCATEGORY W	on (W.CATEGORYCODE=WT.CATEGORYCODE)
	left join CASENAME EMP	on (EMP.CASEID=WH.CASEID
				and EMP.NAMETYPE=''EMP''
				and EMP.EXPIRYDATE is null)
	left join CASENAME OW	on (OW.CASEID=WH.CASEID
				and OW.NAMETYPE=''O''
				and OW.SEQUENCE=(select SEQUENCE
						 from CTE_FirstName CTE
						 where CTE.CASEID  =OW.CASEID
						 and   CTE.NAMETYPE=''O''))
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
	left join EMPLOYEE E	on (E.EMPLOYEENO=coalesce(E1.EMPLOYEENO,WHE.EMPLOYEENO,EMP.NAMENO))
	left join CASES C	on (C.CASEID=WH.CASEID)
	left join OFFICIALNUMBERS O_A
				on (O_A.CASEID=C.CASEID
				and O_A.NUMBERTYPE=''A'')
	left join OFFICIALNUMBERS O_5
				on (O_5.CASEID=C.CASEID
				and O_5.NUMBERTYPE=''5'')
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
								and VP1.COUNTRYCODE in (C.COUNTRYCODE, ''ZZZ'')))
	left join CASENAME REF	on (REF.CASEID=C.CASEID
				and REF.NAMETYPE=CASE WHEN(O.RENEWALDEBTORFLAG=1) THEN ''Z'' ELSE ''D'' END
				and REF.NAMENO=O.ACCTDEBTORNO
				and REF.EXPIRYDATE is null)
	where O.OPENITEMNO=@sOpenItemNo
	and O.ITEMENTITYNO=@nEntityNo
	and (B.IRN is null OR B.IRN = '''')'

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sOpenItemNo		nvarchar(12),
					  @nEntityNo		int,
					  @nTransNo		int,
					  @sNameType		nvarchar(3),
					  @nDebtorNo		int',
					  @sOpenItemNo=@sOpenItemNo,
					  @nEntityNo=@nEntityNo,
					  @nTransNo=@nTransNo,
					  @sNameType=@sNameType,
					  @nDebtorNo=@nDebtorNo
End

If @ErrorCode=0
Begin
	-- The staff member that may be recorded against the work performed may be a department
	-- rather than a real person.  The following additional fields are being populated
	-- with a real person by first looking at the Name associated with the work performed, 
	-- the Employee against the Case, and finally the signatory against the Case.
	Update #TEMPBILLLINES
	Set	DetailFeeEarnerName      =CASE WHEN(I1.SEX<>'D') THEN T.DetailStaffName
					       WHEN(I2.SEX<>'D') THEN dbo.fn_FormatNameUsingNameNo(N2.NAMENO, 7101)
					       WHEN(I3.SEX<>'D') THEN dbo.fn_FormatNameUsingNameNo(N3.NAMENO, 7101)
					  END,
		DetailFeeEarnerLastName  =CASE WHEN(I1.SEX<>'D') THEN N1.NAME
					       WHEN(I2.SEX<>'D') THEN N2.NAME
					       WHEN(I3.SEX<>'D') THEN N3.NAME
					  END,
		DetailFeeEarnerFirstName =CASE WHEN(I1.SEX<>'D') THEN N1.FIRSTNAME
					       WHEN(I2.SEX<>'D') THEN N2.FIRSTNAME
					       WHEN(I3.SEX<>'D') THEN N3.FIRSTNAME
					  END,
		DetailFeeEarnerStaffClass=CASE WHEN(I1.SEX<>'D') THEN T.DetailStaffClass
					       WHEN(I2.SEX<>'D') THEN S2.DESCRIPTION
					       WHEN(I3.SEX<>'D') THEN S3.DESCRIPTION
					  END,	
		DetailStaffClassCode	 =CASE WHEN(I1.SEX<>'D') THEN T.DetailStaffClassCode
					       WHEN(I2.SEX<>'D') THEN E2.STAFFCLASS
					       WHEN(I3.SEX<>'D') THEN E3.STAFFCLASS
					  END,		
		DetailFeeEarnerStaffCode =CASE WHEN(I1.SEX<>'D') THEN T.DetailStaffCode
					       WHEN(I2.SEX<>'D') THEN N2.NAMECODE
					       WHEN(I3.SEX<>'D') THEN N3.NAMECODE
					  END,
		DetailFeeEarnerStaffInit =CASE WHEN(I1.SEX<>'D') THEN T.DetailStaffInit
					       WHEN(I2.SEX<>'D') THEN N2.INITIALS
					       WHEN(I3.SEX<>'D') THEN N3.INITIALS
					  END
	from #TEMPBILLLINES T
	join CASES C		on (C.IRN=T.DetailCaseReference)

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
				and SIG.NAMETYPE='EMP'
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
	If exists(select * from #TEMPITEMHEADER where CreditNoteFlag=0)
		update #TEMPITEMHEADER
		set Reductions=R.ReductionTotal,
		    ForeignReductions=R.ReductionForeignTotal
		from #TEMPITEMHEADER T
		join (	select	sum(isnull(DetailValue,0)) as ReductionTotal, sum(isnull(DetailForeignValue,0)) as ReductionForeignTotal
			from #TEMPBILLLINES
			where DetailValue<0) R on (1=1)
	Else
		update #TEMPITEMHEADER
		set Reductions=R.ReductionTotal,
		    ForeignReductions=R.ReductionForeignTotal
		from #TEMPITEMHEADER T
		join (	select	sum(isnull(DetailValue,0)) as ReductionTotal, sum(isnull(DetailForeignValue,0)) as ReductionForeignTotal
			from #TEMPBILLLINES
			where DetailValue>0) R on (1=1)

	set @ErrorCode=@@Error
End

----------------------
-- Get the tax details
----------------------
If  @ErrorCode=0
and @sSelectTaxDetails is not null
Begin
	Insert into #TEMPTAXDETAILS (TaxRate, TaxableAmount, TaxAmount, TaxDescription)
	select OT.TAXRATE, OT.TAXABLEAMOUNT, OT.TAXAMOUNT, T.DESCRIPTION
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

-------------------------------
-- Get the user defined details
-- associated with each Case.
-------------------------------
If  @ErrorCode=0
and @sSelectCaseDetails is not null
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
		---------------------------------------------------------
		-- Firms can now define any number of their own columns
		-- that are linked to a Doc Item. We need to loop through
		-- each of these columns and extract the data for each
		-- case associated with the invoice.
		-- Get the first column linked to a Doc Item
		---------------------------------------------------------
		If @ErrorCode=0
		Begin
			set @sSQLDocItem=null
			set @nRowNumber =0

			select	@sSQLDocItem=I.SQL_QUERY,
				@sColumn    ='['+T.PUBLISHNAME+']',
				@nRowNumber =T.ROWNUMBER
			from @tblOutputRequests T
			join (	select min(ROWNUMBER) as ROWNUMBER
				from @tblOutputRequests
				where DOCITEMKEY is not null
				and ROWNUMBER>@nRowNumber) T1	on (T1.ROWNUMBER=T.ROWNUMBER)
			join ITEM I on (I.ITEM_ID=T.DOCITEMKEY)

			Set @ErrorCode=@@Error
		End

		------------------------------------------
		-- Now loop through each column and
		-- execute the Doc Item to get the result.
		------------------------------------------
		
		While(@sSQLDocItem is not null)
		and @ErrorCode=0
		Begin
			----------------------------------
			-- Within the Doc Item replace any
			-- parameters with specific values
			----------------------------------
			Set @sSQLDocItem=replace(@sSQLDocItem,':gstrEntryPoint','#TEMPCASEDETAILS.IRN')
			Set @sSQLDocItem=replace(@sSQLDocItem,':p1',isnull(cast(@nLanguage as nvarchar(13)), 'null'))
			Set @sSQLDocItem=replace(@sSQLDocItem,':p2',''''+isnull(@sNameType,'')+'''')
			Set @sSQLDocItem=replace(@sSQLDocItem,':p3',isnull(cast(@nDebtorNo as nvarchar(13)), 'null'))
			Set @sSQLDocItem=replace(@sSQLDocItem,':p4',''''+isnull(@sOpenItemNo,'')+'''')
		
		
			Set @sSQLString='
			Update #TEMPCASEDETAILS
			Set '+@sColumn+'=('+@sSQLDocItem+')
			From #TEMPCASEDETAILS'
		
			Exec @ErrorCode=sp_executesql @sSQLString

			-----------------------------------
			-- Get the next user defined column 
			-- linked to a Doc Item.
			-----------------------------------
			If @ErrorCode=0
			Begin
				set @sSQLDocItem=null

				select @sSQLDocItem=I.SQL_QUERY,
					@sColumn   ='['+T.PUBLISHNAME+']',
					@nRowNumber=T.ROWNUMBER
				from @tblOutputRequests T
				join (	select min(ROWNUMBER) as ROWNUMBER
					from @tblOutputRequests
					where DOCITEMKEY is not null
					and ROWNUMBER>@nRowNumber) T1	on (T1.ROWNUMBER=T.ROWNUMBER)
				join ITEM I on (I.ITEM_ID=T.DOCITEMKEY)

				Set @ErrorCode=@@Error
			End
		End
	End
End

-- If no Reference Text was extracted for the bill then attempt to get the 
-- details at this time 
If @ErrorCode=0
and exists(select * from #TEMPITEMHEADER where RefText is null or datalength(RefText) = 0)
Begin
	-- Get the docitem to use for extracting the Reference Text

	Set @sSQLString='
	Select 	@sSQLDocItem=convert(nvarchar(4000),SQL_QUERY),
		@sItemName=S.COLCHARACTER
	From SITECONTROL S
	left join ITEM I on (I.ITEM_NAME=S.COLCHARACTER)
	Where S.CONTROLID=''XML Bill Ref-Automatic'''

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
			Set @sSQLString='exec '+@sItemName

			exec @ErrorCode=sp_executesql @sSQLString
		end
		-- The DocItem is a SELECT statement that must return a single column
		-- and single row of data otherwise the UPDATE will fail.
		Else If @sSQLDocItem is not null
		Begin
			Set @sSQLDocItem=replace(@sSQLDocItem,':gstrEntryPoint','#TEMPCASEDETAILS.IRN')
		
			exec ('
			Update #TEMPCASEDETAILS
			Set REFTEXT=('+@sSQLDocItem+')
			From #TEMPCASEDETAILS
			Where ROWORDER=1')
		
			Set @ErrorCode=@@Error
		End
	
		If  @ErrorCode=0
		Begin
			Update #TEMPITEMHEADER
			Set RefText=T.REFTEXT
			From #TEMPITEMHEADER
			join #TEMPCASEDETAILS T on (T.ROWORDER=1)
			Where T.REFTEXT is not null
	
			Set @ErrorCode=@@Error
		End
	End
End

--------------------------
-- Get the Copy To Details
--------------------------
If  @ErrorCode=0
and @sSelectCopyToDetails is not null
Begin
	insert into #TEMPCOPYTODETAILS (CopyToName,CopyToAttention,CopyToAddress)
	select	distinct
		dbo.fn_FormatNameUsingNameNo(N1.NAMENO, COALESCE(N1.NAMESTYLE, C1.NAMESTYLE, 7101)),
		dbo.fn_FormatNameUsingNameNo(N2.NAMENO, COALESCE(N2.NAMESTYLE, C2.NAMESTYLE, 7101)),
		dbo.fn_FormatAddress(A.STREET1, A.STREET2, A.CITY, A.STATE, S.STATENAME, A.POSTCODE, CA.POSTALNAME, CA.POSTCODEFIRST, CA.STATEABBREVIATED,CA.POSTCODELITERAL,CA.ADDRESSSTYLE)
	from #TEMPCASEDETAILS T
	join CASENAME CN	on (CN.CASEID=T.CASEID
				and CN.NAMETYPE=CASE WHEN(@bRenewalFlag=1) THEN 'ZC' ELSE'CD' END
				and (CN.EXPIRYDATE is null
					OR CN.EXPIRYDATE > GETDATE())
					)
	join NAME N1		on (N1.NAMENO=CN.NAMENO)
	left join COUNTRY C1	on (C1.COUNTRYCODE=N1.NATIONALITY)
	left join ADDRESS A	on (A.ADDRESSCODE=N1.POSTALADDRESS)
	left join COUNTRY CA	on (CA.COUNTRYCODE=A.COUNTRYCODE)
	left join STATE S	on (S.COUNTRYCODE=A.COUNTRYCODE
				and S.STATE=A.STATE)
	left join NAME N2	on (N2.NAMENO=isnull(CN.CORRESPONDNAME,N1.MAINCONTACT))
	left join COUNTRY C2	on (C2.COUNTRYCODE=N2.NATIONALITY)

End

-------------------------------------------------
--
--    Translate the codes using the mapping rules
--
-------------------------------------------------
If  @nMapProfileId is not null
and @bSavedBillLineMappingsExist = 0
and @ErrorCode=0
Begin
	-----------------------------------------
	-- Loop through each user define column
	-- associated with the Bill Mapping rules
	-- and extract the data into the table
	-- #TEMPBILLLINES.
	-----------------------------------------
	
	If @ErrorCode=0
	Begin
		set @sColumn=null
		set @nRowNumber =0

		select	@sColumn    ='['+T.PUBLISHNAME+']',
			@nRowNumber =T.ROWNUMBER,
			@nFieldCode =T.FIELDCODE
		from @tblOutputRequests T
		join (	select min(ROWNUMBER) as ROWNUMBER
			from @tblOutputRequests
			where FIELDCODE is not null
			and ROWNUMBER>@nRowNumber) T1 
					on (T1.ROWNUMBER=T.ROWNUMBER)

		Set @ErrorCode=@@Error
	End

	------------------------------------------
	-- Now loop through each column associated
	-- with a Bill Mapping field and extract 
	-- the mapped value.
	------------------------------------------
	While @sColumn    is not null
	  and @nFieldCode is not null
	  and @ErrorCode=0
	Begin
		----------------------------------
		-- Update each user defined column
		-- with the mapped data defined 
		-- for that column.
		----------------------------------
		IF EXISTS (SELECT * FROM TempDB.INFORMATION_SCHEMA.COLUMNS where TABLE_NAME like '#TEMPBILLLINES%'  AND '['+COLUMN_NAME+']' = @sColumn )
		begin	
			Set @sSQLString='
			Update T
			Set '+@sColumn+'=
			       (SELECT 
				substring(
				max (    	
				CASE WHEN (B.WIPCODE       IS NULL) THEN ''0'' ELSE cast(len(B.WIPCODE)       as char(1)) END +	
				CASE WHEN (B.WIPTYPEID     IS NULL) THEN ''0'' ELSE cast(len(B.WIPTYPEID)     as char(1)) END +	
				CASE WHEN (B.WIPCATEGORY   IS NULL) THEN ''0'' ELSE ''1'' END +
				CASE WHEN (B.NARRATIVECODE IS NULL) THEN ''0'' ELSE cast(len(B.NARRATIVECODE) as char(1)) END +	
				CASE WHEN (B.STAFFCLASS    IS NULL) THEN ''0'' ELSE ''1'' END +
				CASE WHEN (B.ENTITYNO      IS NULL) THEN ''0'' ELSE ''1'' END +
				CASE WHEN (B.OFFICEID      IS NULL) THEN ''0'' ELSE ''1'' END +
				CASE WHEN (B.CASETYPE      IS NULL) THEN ''0'' ELSE ''1'' END +
				CASE WHEN (B.COUNTRYCODE   IS NULL) THEN ''0'' ELSE ''1'' END +
				CASE WHEN (B.PROPERTYTYPE  IS NULL) THEN ''0'' ELSE ''1'' END +
				CASE WHEN (B.CASECATEGORY  IS NULL) THEN ''0'' ELSE ''1'' END +
				CASE WHEN (B.SUBTYPE       IS NULL) THEN ''0'' ELSE ''1'' END +
				CASE WHEN (B.BASIS         IS NULL) THEN ''0'' ELSE ''1'' END +
				CASE WHEN (B.STATUS        IS NULL) THEN ''0'' ELSE ''1'' END +
				B.MAPPEDVALUE), 15,254)
				FROM BILLMAPRULES B 
				WHERE	B.BILLMAPPROFILEID	= @nMapProfileId
				AND	B.FIELDCODE		= @nFieldCode
				AND (	T.DetailWIPCode	     like B.WIPCODE		 OR B.WIPCODE		IS NULL ) -- inexact partial match allowed
				AND (	T.DetailWIPTypeId    like B.WIPTYPEID		 OR B.WIPTYPEID		IS NULL ) -- inexact partial match allowed
				AND (	T.DetailWIPCategory	= B.WIPCATEGORY		 OR B.WIPCATEGORY	IS NULL )
				AND (	N.NARRATIVECODE      like B.NARRATIVECODE	 OR B.NARRATIVECODE	IS NULL ) -- inexact partial match allowed
				AND (	B.STAFFCLASS		= T.DetailStaffClassCode OR B.STAFFCLASS        IS NULL )
				AND (	B.ENTITYNO 		= @nEntityNo	 	 OR B.ENTITYNO	 	IS NULL ) 
				AND (	B.OFFICEID 		= C.OFFICEID	 	 OR B.OFFICEID	 	IS NULL ) 
				AND (	B.CASETYPE 		= C.CASETYPE	 	 OR B.CASETYPE	 	IS NULL ) 
				AND (	B.COUNTRYCODE 		= C.COUNTRYCODE 	 OR B.COUNTRYCODE 	IS NULL ) 
				AND (	B.PROPERTYTYPE 		= C.PROPERTYTYPE 	 OR B.PROPERTYTYPE 	IS NULL ) 
				AND (	B.CASECATEGORY 		= C.CASECATEGORY 	 OR B.CASECATEGORY 	IS NULL ) 
				AND (	B.SUBTYPE 		= C.SUBTYPE 		 OR B.SUBTYPE 		IS NULL )
				AND (	B.BASIS 		= P.BASIS 		 OR B.BASIS 		IS NULL )
				AND (	B.STATUS 		= C.STATUSCODE           OR B.STATUS		IS NULL )
				)
			From #TEMPBILLLINES T
			left join CASES C	on (C.IRN=T.DetailCaseReference)
			left join PROPERTY P	on (P.CASEID=C.CASEID)
			left join NARRATIVE N	on (N.NARRATIVENO=T.DetailNarrativeNo)'
		
			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@nMapProfileId	int,
						  @nFieldCode		int,
						  @nEntityNo		int',
						  @nMapProfileId	=@nMapProfileId,
						  @nFieldCode		=@nFieldCode,
						  @nEntityNo		=@nEntityNo
		End
		-----------------------------------
		-- Get the next user defined column 
		-- for extraction of mapped data.
		-----------------------------------
		-----------------------------------
		-- Get the next user defined column 
		-- for extraction of mapped data.
		-----------------------------------
		If @ErrorCode=0
		Begin
			set @sColumn   =null
			set @nFieldCode=null

			select  @sColumn   ='['+T.PUBLISHNAME+']',
				@nRowNumber=T.ROWNUMBER,
				@nFieldCode=T.FIELDCODE
			from @tblOutputRequests T
			join (	select min(ROWNUMBER) as ROWNUMBER
				from @tblOutputRequests
				where FIELDCODE is not null
				and ROWNUMBER>@nRowNumber) T1 on (T1.ROWNUMBER=T.ROWNUMBER)

			Set @ErrorCode=@@Error
		End
	End
End

------------------------------------------------------
--  RFC13002 (code supplied by DCC)
--
--  Translate the HEADER codes using the mapping rules
------------------------------------------------------		
If  @nMapProfileId is not null
and @ErrorCode=0
Begin
	-----------------------------------------
	-- Loop through each user defined column
	-- associated with the Bill Mapping rules
	-- and extract the data into the table
	-- #TEMPITEMHEADER.
	-----------------------------------------
	
	If @ErrorCode=0
	Begin
		set @sColumn=null
		set @nRowNumber =0

		select	@sColumn    ='['+T.PUBLISHNAME+']',
			@nRowNumber =T.ROWNUMBER,
			@nFieldCode =T.FIELDCODE
		from @tblOutputRequests T
		join (	select min(ROWNUMBER) as ROWNUMBER
			from @tblOutputRequests
			where FIELDCODE is not null
			and ROWNUMBER>@nRowNumber) T1 
					on (T1.ROWNUMBER=T.ROWNUMBER)

		Set @ErrorCode=@@Error
	End

	------------------------------------------
	-- Now loop through each column associated
	-- with a Bill Mapping field and extract 
	-- the mapped value.
	------------------------------------------
	While @sColumn    is not null
	  and @nFieldCode is not null
	  and @ErrorCode=0
	Begin
		----------------------------------
		-- Update each user defined column
		-- with the mapped data defined 
		-- for that column.
		----------------------------------
		IF EXISTS (SELECT * FROM TempDB.INFORMATION_SCHEMA.COLUMNS where TABLE_NAME like '#TEMPITEMHEADER%' 
		 AND '['+COLUMN_NAME+']' = @sColumn )
		begin
			Set @sSQLString='
			Update H 
			Set '+@sColumn+'=
			       (SELECT 
				substring(
				max (    	
				CASE WHEN (B.WIPCODE       IS NULL) THEN ''0'' ELSE cast(len(B.WIPCODE)       as char(1)) END +	
				CASE WHEN (B.WIPTYPEID     IS NULL) THEN ''0'' ELSE cast(len(B.WIPTYPEID)     as char(1)) END +	
				CASE WHEN (B.WIPCATEGORY   IS NULL) THEN ''0'' ELSE ''1'' END +
				CASE WHEN (B.NARRATIVECODE IS NULL) THEN ''0'' ELSE cast(len(B.NARRATIVECODE) as char(1)) END +	
				CASE WHEN (B.STAFFCLASS    IS NULL) THEN ''0'' ELSE ''1'' END +
				CASE WHEN (B.ENTITYNO      IS NULL) THEN ''0'' ELSE ''1'' END +
				CASE WHEN (B.OFFICEID      IS NULL) THEN ''0'' ELSE ''1'' END +
				CASE WHEN (B.CASETYPE      IS NULL) THEN ''0'' ELSE ''1'' END +
				CASE WHEN (B.COUNTRYCODE   IS NULL) THEN ''0'' ELSE ''1'' END +
				CASE WHEN (B.PROPERTYTYPE  IS NULL) THEN ''0'' ELSE ''1'' END +
				CASE WHEN (B.CASECATEGORY  IS NULL) THEN ''0'' ELSE ''1'' END +
				CASE WHEN (B.SUBTYPE       IS NULL) THEN ''0'' ELSE ''1'' END +
				CASE WHEN (B.BASIS         IS NULL) THEN ''0'' ELSE ''1'' END +
				CASE WHEN (B.STATUS        IS NULL) THEN ''0'' ELSE ''1'' END +
				B.MAPPEDVALUE), 15,254)
				FROM BILLMAPRULES B 
				WHERE	B.BILLMAPPROFILEID	= @nMapProfileId
				AND	B.FIELDCODE		= @nFieldCode
				AND (	B.ENTITYNO 		= @nEntityNo	 	 OR B.ENTITYNO	 	IS NULL ) 
				AND (	B.OFFICEID 		= C.OFFICEID	 	 OR B.OFFICEID	 	IS NULL ) 
				AND (	B.CASETYPE 		= C.CASETYPE	 	 OR B.CASETYPE	 	IS NULL ) 
				AND (	B.COUNTRYCODE 		= C.COUNTRYCODE 	 OR B.COUNTRYCODE 	IS NULL ) 
				AND (	B.PROPERTYTYPE 		= C.PROPERTYTYPE 	 OR B.PROPERTYTYPE 	IS NULL ) 
				AND (	B.CASECATEGORY 		= C.CASECATEGORY 	 OR B.CASECATEGORY 	IS NULL ) 
				AND (	B.SUBTYPE 		= C.SUBTYPE 		 OR B.SUBTYPE 		IS NULL )
				AND (	B.BASIS 		= P.BASIS 		 OR B.BASIS 		IS NULL )
				AND (	B.STATUS 		= C.STATUSCODE           OR B.STATUS		IS NULL )
				)
			From #TEMPITEMHEADER H
			left join OPENITEM O on (O.OpenItemNo = H.OpenItemNo)
			left join CASES C	on (C.CaseID=O.MainCaseID)
			left join PROPERTY P	on (P.CASEID=C.CASEID)'

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@nMapProfileId	int,
						  @nFieldCode		int,
						  @nEntityNo		int',
						  @nMapProfileId	=@nMapProfileId,
						  @nFieldCode		=@nFieldCode,
						  @nEntityNo		=@nEntityNo
		end
		-----------------------------------
		-- Get the next user defined column 
		-- for extraction of mapped data.
		-----------------------------------
		If @ErrorCode=0
		Begin
			set @sColumn   =null
			set @nFieldCode=null

			select  @sColumn   ='['+T.PUBLISHNAME+']',
				@nRowNumber=T.ROWNUMBER,
				@nFieldCode=T.FIELDCODE
			from @tblOutputRequests T
			join (	select min(ROWNUMBER) as ROWNUMBER
				from @tblOutputRequests
				where FIELDCODE is not null
				and ROWNUMBER>@nRowNumber) T1 on (T1.ROWNUMBER=T.ROWNUMBER)

			Set @ErrorCode=@@Error
		End
	End
End

-------------------------------------------------
--
--    Return the requested columns as XML
--
-------------------------------------------------
If @ErrorCode=0
Begin
	If @sSelectHeader is not null
	Begin
		Set @sSQLString='Select ' + @sSelectHeader + ' from #TEMPITEMHEADER as ItemHeader
		for XML PATH(''ItemHeader''), ELEMENTS XSINIL, TYPE'

		exec(@sSQLString)
		
		Set @ErrorCode=@@Error
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
		DebtorName		nvarchar(254)	NULL,
		DebtorAddress		nvarchar(254)	NULL,
		DebtorAttentionName	nvarchar(254)	NULL,
		StatusText		nvarchar(50)	NULL,
		OurRef			nvarchar(500)	NULL,
		PurchaseOrderNo		nvarchar(80)	NULL,
		StaffName		nvarchar(100)	NULL,
		Regarding		nvarchar(max)	NULL,
		BillScope		nvarchar(254)	NULL,
		Reductions		decimal(11,2)	NULL,
		CreditNoteFlag		bit		NULL,
		ForeignReductions	decimal(11,2)	NULL,
		TaxNumber		nvarchar(30)	NULL,
		ImageId			int		NULL,
		ForeignEquivCurrency	nvarchar(40)	NULL,
		ForeignEquivExRate	decimal(11,4)	NULL,
		PenaltyInterestRate	decimal(5,2)	NULL,
		DueDate			datetime	NULL,
		LocalTakenUp		decimal(11,2)	NULL,
		ForeignTakenUp		decimal(11,2)	NULL
*/
	End
	If @sSelectBillLines is not null
	and @ErrorCode=0
	Begin
		if @bSavedBillLineMappingsExist = 1
		Begin
			-- Select from XML joined with #TEMPBILLLINES
			Set @sSQLString='Select ' + @sSelectBillLines + ' from #TEMPBILLLINES'+char(10)+
					'Join (select OPENITEMXML
						from OPENITEMXML OIX
						Join OPENITEM OI on (OI.ITEMENTITYNO = OIX.ITEMENTITYNO
									AND OI.ITEMTRANSNO = OIX.ITEMTRANSNO)
						Where OI.ITEMENTITYNO = @nEntityNo' + char(10) +
						'AND OI.OPENITEMNO = @sOpenItemNo' + CHAR(10) +
						'AND XMLTYPE = 1) as OIX CROSS APPLY OPENITEMXML.nodes(''/BillLines/BillLine'') BLM(BillLineMapped)' + char(10) +
					'on BillLineMapped.value(N''@BillLineNo'',N''int'') = #TEMPBILLLINES.DetailDisplaySequence' + char(10) +
					'order by ' + isnull(@sOrderBillLines,'DetailDisplaySequence') + char(10) +
					'for XML PATH(''BillLine''), ROOT(''BillLines''), ELEMENTS XSINIL, TYPE'

			Exec @ErrorCode=sp_executesql @sSQLString,
				N'@nEntityNo		int,
				@sOpenItemNo		nvarchar(12)',
				@nEntityNo = @nEntityNo,
				@sOpenItemNo = @sOpenItemNo
		End
		Else
		Begin
			-- Get all values from #TEMPBILLLINES
			Set @sSQLString='Select ' + @sSelectBillLines + ' from #TEMPBILLLINES'+char(10)+
					'order by ' + isnull(@sOrderBillLines,'DetailDisplaySequence') + char(10) +
					'for XML PATH(''BillLine''), ROOT(''BillLines''), ELEMENTS XSINIL, TYPE'

			exec(@sSQLString)

			Set @ErrorCode=@@Error
		End

/*
		DetailDisplaySequence	smallint	NULL,
		DetailChargeOutRate	decimal(11,2)	NULL,
		DetailStaffName		nvarchar(60)	NULL,
		DetailDate		datetime	NULL,
		DetailCaseReference		nvarchar(30)	NULL,	
		DetailTime		nvarchar(30)	NULL,
		DetailWIPCode		nvarchar(6)	NULL,
		DetailWIPTypeId		nvarchar(6)	NULL,
		DetailCatDesc		nvarchar(50)	NULL,
		DetailNarrative		nvarchar(max)	NULL,
		DetailValue		decimal(11,2)	NULL,
		DetailForeignValue	decimal(11,2)	NULL,
		DetailChargeCurrency	nvarchar(3)	NULL,
		DetailStaffClass	nvarchar(80)	NULL,
		DetailStaffCode		nvarchar(10)	NULL,
		DetailStaffInit		nvarchar(10)	NULL
*/
	End
	If @sSelectTaxDetails is not null
	and @ErrorCode=0
	Begin
		Set @sSQLString='Select ' + @sSelectTaxDetails + ' from #TEMPTAXDETAILS' + char(10) +
				'order by ' + isnull(@sOrderTaxDetails,'TaxRate, TaxDescription') + char(10) +
				'for XML PATH(''TaxDetail''), ROOT(''TaxDetails''), ELEMENTS XSINIL, TYPE'

		exec(@sSQLString)
		
		Set @ErrorCode=@@Error
/*
		TaxRate			decimal(11,4)	NULL,
		TaxableAmount		decimal(11,2)	NULL,
		TaxAmount		decimal(11,2)	NULL,
		TaxDescription		nvarchar(30)	NULL
*/
	End


	If @sSelectCaseDetails is not null
	and @ErrorCode=0
	Begin	
		Set @sSQLString='Select ' + @sSelectCaseDetails + ' from #TEMPCASEDETAILS' + char(10) +
				'order by ' + isnull(@sOrderCaseDetails,'IRN') + char(10) +
				'for XML PATH(''CaseDocItem''), ROOT(''CaseDocItems''), ELEMENTS XSINIL, TYPE'

		exec(@sSQLString)
		
		Set @ErrorCode=@@Error
/*
		CASEID			int		NOT NULL,
		IRN			nvarchar(30)	NOT NULL
*/
	End

	If @sSelectCopyToDetails is not null
	and @ErrorCode=0
	Begin
		Set @sSQLString='Select ' + @sSelectCopyToDetails + ' from #TEMPCOPYTODETAILS' + char(10) +
				'order by ' + isnull(@sOrderCopyToDetails,'CopyToName') + char(10) +
				'for XML PATH(''CopyToDetail''), ROOT(''CopyToDetails''), ELEMENTS XSINIL, TYPE'

		exec(@sSQLString)
		
		Set @ErrorCode=@@Error
/*
		CopyToName		nvarchar(254)	NULL,
		CopyToAttention		nvarchar(254)	NULL,
		CopyToAddress		nvarchar(254)	NULL
*/
	End


End

return @ErrorCode
go

grant execute on dbo.xml_GetDebitNoteMappedCodes  to public
go

