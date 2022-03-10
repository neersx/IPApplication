-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_GetBillDebtors] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_GetBillDebtors]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_GetBillDebtors].'
	drop procedure dbo.[biw_GetBillDebtors]
end
print '**** Creating procedure dbo.[biw_GetBillDebtors]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[biw_GetBillDebtors]
				@pnUserIdentityId	int,		-- Mandatory
				@psCulture		nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@pnItemEntityNo		int,
				@pnItemTransNo		int,
				@pnRaisedByStaffKey		int = null -- Used to get the actual Tax code
				
as
-- PROCEDURE :	biw_GetBillDebtors
-- VERSION :	27
-- DESCRIPTION:	A procedure that returns all of the debtors associated to an OpenItem
--
--		*******************************************
--		NOTE: If adding columns, you need to also add the same columns to biw_GetDebtorsFromCaseList and biw_GetDebtorDetails
--		*******************************************
--
-- COPYRIGHT:	Copyright 1993 - 2012 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC		Version Description
-- -----------	-------	------- -------	----------------------------------------------- 
-- 14-Oct-2009	AT	RFC3605		1	Procedure created.
-- 03-May-2010	AT	RFC9092		2	Use Translations.
-- 07-May-2010	AT	RFC9135		3	Return Bill Format Profile.
-- 25-May-2010	AT	RFC9092		4	Order by CASENAME.SEQUENCE.
-- 11-Jul-2010	AT	RFC7278		5	Return BillMapProfile
-- 15-Jul-2010	AT	RFC7273		6	Populate common IPNAME debtor details from biw_PopulateDebtorDetails
-- 15-Jul-2010	AT	RFC7271		7	Return AddressChangeReason
-- 14-Oct-2010	AT	RFC8982		8	Modified retrieval of copy to names to use stored proc.
-- 04-Jan-2012	AT	RFC9165		9	Return Buy Rate.
-- 02-Feb-2012	AT	RFC11864	10	Modified params for get debtor warnings.
-- 14-Jun-2012	KR	RFC12005	11	Linked CASETYPE and WIPCODE to DISCOUNT table.
-- 08-Aug-2012	AT	RFC12555	12	Return current exch rate instead of bill exch rate.
-- 29-Aug-2012	LP	RFC10474	13	Return IsClient flag.
-- 25-Apr-2013	MS	RFC11732	14	Return Reference from NAMEADDRESSSNAP if exists
--						Return table for casekey and their debtor reference
-- 01-May-2013  MS      RFC11732        15      Use fn_GetBillCases function rather than temporary table for cases list
-- 19-Aug-2013	vql	DR-641		16	Return both Renewal Debtors and Debtors depending on pbUseRenewalDebtor.
-- 12-Sep-2013	vql	DR-641		17	Change join to Name Type table to left join.
-- 23-Dec-2013	AT	RFC29436	18	Return debtor name type with debtor references.
-- 01 Jun 2015	MS	R35907	        19	Linked COUNTRYCODE to the Discount table
-- 20 Oct 2015  MS      R53933          20      Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols
-- 02 Nov 2015	vql	R53910		21	Adjust formatted names logic (DR-15543).
-- 24 Jan 2018	AK	R72409      22  Conditionally return Correspondence Instructions Billing then default instruction 
-- 26 Feb 2018  AK  R72937		23   Added logic to return effective tax code
-- 07 Mar 2018  AK  R73598		24   added HasOfficeInEu in resultset
-- 11 Oct 2018  MS      DR-43550        25      Return Office Entity 
-- 30 Oct 2019  MS      DR-53313        26      Return FormattedNameWithCode column
-- 23 Mar 2020  LP  DR-7536     27  Return LanguageKey and LanguageDescription.

set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF

Declare		@ErrorCode	int
Declare		@nRowCount	int
Declare		@sSQLString	nvarchar(MAX)
Declare		@sLookupCulture	nvarchar(10)

-- TODO: GET THE DEBTOR COUNTRY FOR TAXRATECOUNTRY

Declare @nRoundBilledValues tinyint
Declare @sCurrency nvarchar(3)
Declare @sHomeCurrency nvarchar(3)

-- Dummy values - not used.
Declare	@nBankRate		decimal(11,4)
Declare @nBuyRate		decimal(11,4)
Declare @nSellRate		decimal(11,4)
Declare @nDecimalPlaces	        tinyint
-- END NOT USED

Declare @dtTransDate            datetime
Declare @nCaseKey               int
Declare @nDebtorKey             int
Declare @bUseRenewalDebtor      bit
Declare @sDebtorTableName	nvarchar(30)
Declare @nLanguageKey           int
Declare @sLanguageDescription   nvarchar(80)	

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @ErrorCode = 0
Set @sDebtorTableName = "##DebtorCurrencyDetails" + Cast(@@SPID as nvarchar(30))

If (@ErrorCode = 0)
Begin
	select  @dtTransDate = ITEMDATE,
	@nCaseKey = MAINCASEID,
	@bUseRenewalDebtor = isnull(RENEWALDEBTORFLAG, 0)
	From OPENITEM
	Where ITEMENTITYNO = @pnItemEntityNo
	and ITEMTRANSNO = @pnItemTransNo
	ORDER BY OPENITEMNO DESC
End

If @ErrorCode=0 and exists(select * from tempdb.dbo.sysobjects where name = @sDebtorTableName )
Begin 
	Set @sSQLString = 'DROP TABLE ' + @sDebtorTableName

	Exec @ErrorCode=sp_executesql @sSQLString
End

If @ErrorCode = 0
Begin
	Set @sSQLString = 
	"create table " + @sDebtorTableName + "
	(
		NAMENO			INT,
		SEQUENCE		NVARCHAR(12),
		BILLPERCENTAGE		DECIMAL(5,2) null,
		REFERENCENO		NVARCHAR(80) COLLATE database_default NULL,
		CORRESPONDNAME		INT null,
		INSTRUCTIONS		nvarchar(254) COLLATE database_default NULL,
		INSTRUCTIONSBILLING	ntext COLLATE database_default NULL,
		TAXCODE			nvarchar(3) COLLATE database_default NULL,
		TAXDESCRIPTION		nvarchar(30) COLLATE database_default NULL,
		TAXRATE			DECIMAL(11,4) null,
		ALLOWMULTICASE		bit,
		BILLFORMATPROFILEKEY	INT null,
		BILLMAPPROFILEKEY	INT null,
		CURRENCY		NVARCHAR(3) COLLATE database_default NULL,
		BANKRATE		DECIMAL(11,4) null,
		BUYRATE			DECIMAL(11,4) null,
		SELLRATE		DECIMAL(11,4) null,
		DECIMALPLACES		INT null,
		ROUNDBILLVALUES		INT null,
		BILLINGCAP		decimal(12,2),
		BILLEDAMOUNT		decimal(12,2),
		BILLINGCAPSTART		DATETIME,
		BILLINGCAPEND		DATETIME,
		ISCLIENT		bit NOT NULL default 0,
		HASOFFICEINEU	bit NOT NULL default 0,
		NAMETYPE		nvarchar(3) COLLATE database_default null,
		NAMETYPEDESCRIPTION	nvarchar(50) COLLATE database_default null
	)"
	
	Exec @ErrorCode=sp_executesql @sSQLString
End

If @ErrorCode = 0
Begin
	Set @sSQLString = "insert into " + @sDebtorTableName + " (NAMENO, SEQUENCE)
			SELECT ACCTDEBTORNO, OPENITEMNO
			FROM OPENITEM
			Where ITEMTRANSNO = @pnItemTransNo
			and ITEMENTITYNO= @pnItemEntityNo"
			
	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnItemTransNo	int,
				  @pnItemEntityNo	int',
				  @pnItemTransNo=@pnItemTransNo,
				  @pnItemEntityNo=@pnItemEntityNo
End

If @ErrorCode = 0
Begin
	EXEC dbo.[biw_PopulateDebtorDetails]
				@pnUserIdentityId	= @pnUserIdentityId,		-- Mandatory
				@psCulture		= @psCulture,
				@pbCalledFromCentura	= @pbCalledFromCentura,
				@sTempTable		= @sDebtorTableName,
				@pnEntityKey		= @pnItemEntityNo,
				@pdtTransDate		= @dtTransDate,
				@pnCaseKey		= @nCaseKey,
				@pnRaisedByStaffKey = @pnRaisedByStaffKey
End

If (@ErrorCode = 0)
Begin
	-- Get the main debtor
	Set @sSQLString = "select @nDebtorKey = NAMENO FROM " + @sDebtorTableName + "
		WHERE SEQUENCE = (SELECT MIN(SEQUENCE) FROM " + @sDebtorTableName + ")"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nDebtorKey	int OUTPUT',
				  @nDebtorKey=@nDebtorKey OUTPUT
End

If (@ErrorCode = 0)
Begin
	If (@nCaseKey is not null)
	Begin
		exec @ErrorCode = dbo.bi_GetBillingLanguage
				@pnLanguageKey = @nLanguageKey output,
				@pnUserIdentityId = @pnUserIdentityId,
				@pnDebtorKey = null,
				@pnCaseKey = @nCaseKey,
				@psActionKey = null,
				@pbDeriveAction = 1
	End 
	Else Begin
		exec @ErrorCode = dbo.bi_GetBillingLanguage
				@pnLanguageKey = @nLanguageKey output,
				@pnUserIdentityId = @pnUserIdentityId,
				@pnDebtorKey = @nDebtorKey,
				@pnCaseKey = null,
				@psActionKey = null,
				@pbDeriveAction = 0
	End

    If (@ErrorCode = 0 and @nLanguageKey is not null)
	Begin
        Set @sSQLString = "Select @sLanguageDescription = " + dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,NULL,@sLookupCulture,@pbCalledFromCentura) + "
					From TABLECODES
					Where TABLECODE = @nLanguageKey"

        exec @ErrorCode=sp_executesql @sSQLString,
					N'@sLanguageDescription	nvarchar(80) output,
						@nLanguageKey int',
						@sLanguageDescription = @sLanguageDescription output,
						@nLanguageKey = @nLanguageKey
    End
End

If (@ErrorCode = 0)
Begin
	Set @sSQLString = "
		Select 
		N.NAMENO as NameNo,
		ISNULL(NAS.FORMATTEDNAME, dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)) as FormattedName,
                dbo.fn_ApplyNameCodeStyle(ISNULL(NAS.FORMATTEDNAME, dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, CT.NAMESTYLE, 7101))), 
                        NT.SHOWNAMECODE, N.NAMECODE) as FormattedNameWithCode,
		OI.BILLPERCENTAGE  as BillPercentage,
		TN.CURRENCY as Currency,
		TN.BUYRATE as BuyExchangeRate,
		TN.SELLRATE as SellExchangeRate,
                2 as DecimalPlaces,
		TN.ROUNDBILLVALUES as 'RoundBilledValues',
		NAS.FORMATTEDREFERENCE as ReferenceNo,
		ISNULL(NAS.FORMATTEDATTENTION, dbo.fn_FormatNameUsingNameNo(ATTN.NAMENO, null)) as AttentionName,
		ISNULL(NAS.FORMATTEDADDRESS, dbo.fn_FormatAddress(AD.STREET1, AD.STREET2, AD.CITY, AD.STATE, ADS.STATENAME, AD.POSTCODE, ADC.POSTALNAME, ADC.POSTCODEFIRST, ADC.STATEABBREVIATED, ADC.POSTCODELITERAL, ADC.ADDRESSSTYLE)) as Address,
		TC.TOTALCREDITS as TotalCredits,
		ISNULL(TN.INSTRUCTIONSBILLING,TN.INSTRUCTIONS) as 'Instructions',
		TN.TAXCODE as 'TaxCode',
		TN.TAXDESCRIPTION as 'TaxDescription',
		TN.TAXRATE AS 'TaxRate',
		null as 'OfficeKey',
		ISNULL(NAS.ATTNNAMENO, ATTN.NAMENO) AS 'AttentionNameKey',
		ISNULL(NAS.ADDRESSCODE, AD.ADDRESSCODE) AS 'AddressKey',
		null AS 'CaseKey',
		OI.OPENITEMNO AS 'OpenItemNo',
		OI.LOGDATETIMESTAMP AS 'LogDateTimeStamp',
		TN.ALLOWMULTICASE as 'AllowMultiCase',
		TN.BILLFORMATPROFILEKEY AS 'BillFormatProfileKey',
		TN.BILLMAPPROFILEKEY as 'BillMapProfileKey',
		BMP.BILLMAPDESC as 'BillMapProfileDescription',
		TN.BILLINGCAP		as 'BillingCap',
		TN.BILLEDAMOUNT		as 'BilledAmount',
		TN.BILLINGCAPSTART	as 'BillingCapStart',
		TN.BILLINGCAPEND	as 'BillingCapEnd',
		NAS.REASONCODE		as 'AddressChangeReason',
		null			as 'BillToNameKey',
		null			as 'BillToFormattedName',
		TN.HASOFFICEINEU as HasOfficeInEu,
		case when I.NAMENO IS NULL then 0 else 1 end as 'IsClient',"
		+dbo.fn_SqlTranslatedColumn('NT','DESCRIPTION',null,null,@sLookupCulture,@pbCalledFromCentura) + " as 'NameTypeDescription',
		NT.NAMETYPE as 'NameType',
                SN.NAMENO   as 'OfficeEntity',
        @nLanguageKey   as 'LanguageKey',
        @sLanguageDescription as 'LanguageDescription'
		From " + @sDebtorTableName + " TN
		JOIN NAME N on (N.NAMENO = TN.NAMENO)
		Join OPENITEM OI ON (OI.ACCTDEBTORNO = N.NAMENO)
                left join COUNTRY CT on (CT.COUNTRYCODE=N.NATIONALITY)
		-- Get a case associated with the OpenItem
		Left Join (Select top 1
				C.CASEID, REFTRANSNO, REFENTITYNO
				From WORKHISTORY WH
				Join CASES C on (WH.CASEID = C.CASEID)
				Where WH.REFTRANSNO = @pnItemTransNo
				and WH.REFENTITYNO = @pnItemEntityNo
				) AS C on (C.REFENTITYNO = OI.ITEMENTITYNO
						and C.REFTRANSNO = OI.ITEMTRANSNO)
		-- Get attention details from case
		Left join CASENAME CN on (CN.CASEID = ISNULL(@nCaseKey, C.CASEID)
					and CN.NAMENO = N.NAMENO
					and CN.NAMETYPE = case when ISNULL(@bUseRenewalDebtor,0) = 1 AND EXISTS(SELECT * FROM CASENAME CNZ WHERE NAMETYPE = 'Z' AND CNZ.CASEID = ISNULL(@nCaseKey, C.CASEID))
					then 'Z' ELSE 'D' END)
		Left Join NAME ATTN on (ATTN.NAMENO = CN.CORRESPONDNAME)
		Left Join ADDRESS AD on (AD.ADDRESSCODE = ISNULL(CN.ADDRESSCODE, N.POSTALADDRESS))
		Left join COUNTRY ADC		on (ADC.COUNTRYCODE = AD.COUNTRYCODE)
		Left Join STATE ADS		on (ADS.COUNTRYCODE = AD.COUNTRYCODE
							and ADS.STATE = AD.STATE)
		Left Join NAMEADDRESSSNAP NAS on (NAS.NAMESNAPNO = OI.NAMESNAPNO)

		-- Get the total credits.
		Left Join (Select sum(OIC.LOCALBALANCE) as TOTALCREDITS, OI.ACCTENTITYNO, OI.ACCTDEBTORNO, OIC.CASEID
					From OPENITEMCASE OIC 
					join OPENITEM OI on (OI.ITEMENTITYNO = OIC.ITEMENTITYNO
						and OI.ITEMTRANSNO = OIC.ITEMTRANSNO
						and OI.ACCTENTITYNO = OIC.ACCTENTITYNO
						and OI.ACCTDEBTORNO = OIC.ACCTDEBTORNO)
					Where OI.STATUS IN (1, 2) 
					and OI.ITEMTYPE IN (SELECT ITEM_TYPE_ID
										FROM DEBTOR_ITEM_TYPE
										WHERE TAKEUPONBILL = 1)
				Group By OI.ACCTENTITYNO, OI.ACCTDEBTORNO, OIC.CASEID
				Having OI.ACCTENTITYNO = @pnItemEntityNo
				) as TC on (TC.ACCTDEBTORNO = N.NAMENO
							and C.CASEID = TC.CASEID)
		Left Join CURRENCY CUR ON (CUR.CURRENCY = TN.CURRENCY)
		Left Join BILLMAPPROFILE BMP on (BMP.BILLMAPPROFILEID = TN.BILLMAPPROFILEKEY)
		Left Join IPNAME I on (I.NAMENO = N.NAMENO)
		left join NAMETYPE NT on (NT.NAMETYPE = CN.NAMETYPE)	
                left join TABLEATTRIBUTES TA on (TA.PARENTTABLE = 'NAME' and TA.GENERICKEY = N.NAMENO and TA.TABLETYPE = 44)
                left join OFFICE O on (O.OFFICEID = TA.TABLECODE)
                left join SPECIALNAME SN on (O.ORGNAMENO = SN.NAMENO and SN.ENTITYFLAG = 1)	
		Where OI.ITEMTRANSNO = @pnItemTransNo
		and OI.ITEMENTITYNO= @pnItemEntityNo
		order by NT.NAMETYPE, CN.SEQUENCE"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnItemTransNo	int,
				  @pnItemEntityNo	int,
				  @nCaseKey		int,
				  @bUseRenewalDebtor bit,
                  @sLanguageDescription	nvarchar(80),
				  @nLanguageKey		int',
				  @pnItemTransNo	= @pnItemTransNo,
				  @pnItemEntityNo	= @pnItemEntityNo,
				  @nCaseKey		= @nCaseKey,
				  @bUseRenewalDebtor = @bUseRenewalDebtor,
                  @sLanguageDescription = @sLanguageDescription,
                  @nLanguageKey = @nLanguageKey	
End


If (@ErrorCode = 0)
Begin
	exec dbo.biw_GetCopyToNames
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pbCalledFromCentura	= @pbCalledFromCentura,
		@pnEntityKey		= @pnItemEntityNo,
		@pnTransKey		= @pnItemTransNo,
		@pnDebtorKey		= @nDebtorKey,
		@pnCaseKey		= @nCaseKey,
		@pbUseRenewalDebtor	= @bUseRenewalDebtor,
		@psResultTable		= null
End

-- Return Discounts applicable
If (@ErrorCode = 0)
Begin
	Set @sSQLString = "Select DISCOUNT.NAMENO AS NameKey,
			SEQUENCE as Sequence,
			DISCOUNTRATE as DiscountRate,
			WT.WIPTYPEID as WIPTypeKey,
			" + dbo.fn_SqlTranslatedColumn('WIPTYPE','DESCRIPTION',null,'WT',@sLookupCulture,@pbCalledFromCentura) + " as 'WIPTypeDescription',
			WC.CATEGORYCODE as WIPCategoryKey,
			" + dbo.fn_SqlTranslatedColumn('WIPCATEGORY','DESCRIPTION',null,'WC',@sLookupCulture,@pbCalledFromCentura) + " as 'WIPCategoryDescription',
			PT.PROPERTYTYPE as PropertyTypeKey,
			" + dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'PT',@sLookupCulture,@pbCalledFromCentura) + " as 'PropertyTypeDescription',
			A.ACTION as 'ActionKey',
			" + dbo.fn_SqlTranslatedColumn('ACTIONS','ACTIONNAME',null,'A',@sLookupCulture,@pbCalledFromCentura) + " as 'ActionDescription',
			CON.NAMENO as CaseOwnerKey,
			dbo.fn_FormatNameUsingNameNo(CON.NAMENO, null) as CaseOwnerName,
			EN.NAMENO as EmployeeKey,
			dbo.fn_FormatNameUsingNameNo(EN.NAMENO, null) as EmployeeName,
			Case when DISCOUNTRATE > 0 then 'Discount' else 'Surcharge' end as ApplyAs,
			BASEDONAMOUNT as BasedOnAmount,
			CT.CASETYPE as CaseTypeKey,
			" + dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CT',@sLookupCulture,@pbCalledFromCentura) + " as 'CaseTypeDescription',
			WIPT.WIPCODE as WIPCodeKey,
			" + dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'WIPT',@sLookupCulture,@pbCalledFromCentura) + " as 'WIPCodeDescription',
                        CNT.COUNTRYCODE as CountryCode,
			" + dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CNT',@sLookupCulture,@pbCalledFromCentura) + " as 'Country'
			From DISCOUNT
			Join OPENITEM OI on (OI.ACCTDEBTORNO = DISCOUNT.NAMENO)
			Left Join WIPTYPE WT ON (DISCOUNT.WIPTYPEID = WT.WIPTYPEID)
			Left Join WIPCATEGORY WC ON (DISCOUNT.WIPCATEGORY = WC.CATEGORYCODE)
			Left Join PROPERTYTYPE PT ON (DISCOUNT.PROPERTYTYPE = PT.PROPERTYTYPE)
			Left Join ACTIONS A ON (DISCOUNT.ACTION = A.ACTION)
			Left Join NAME CON ON (DISCOUNT.CASEOWNER = CON.NAMENO)
			Left Join NAME EN ON (DISCOUNT.EMPLOYEENO = EN.NAMENO)
			Left Join CASETYPE CT on (DISCOUNT.CASETYPE = CT.CASETYPE)
			Left Join WIPTEMPLATE WIPT on (DISCOUNT.WIPCODE = WIPT.WIPCODE)
                        Left Join COUNTRY CNT on (DISCOUNT.COUNTRYCODE = CNT.COUNTRYCODE)
			Where OI.ITEMTRANSNO = @pnItemTransNo
			and OI.ITEMENTITYNO= @pnItemEntityNo"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnItemTransNo	int,
				  @pnItemEntityNo int',
				  @pnItemTransNo = @pnItemTransNo,
				  @pnItemEntityNo = @pnItemEntityNo
End

If (@ErrorCode = 0)
Begin
	-- Return debtor warnings
	exec biw_ListDebtorWarnings @pnUserIdentityId = @pnUserIdentityId,
				@psCulture = @psCulture,
				@pbCalledFromCentura = @pbCalledFromCentura,
				@pnItemEntityNo = @pnItemEntityNo,
				@pnItemTransNo = @pnItemTransNo,
				@pdtTransDate = @dtTransDate,
				@psDebtorTableName = null
End

If @ErrorCode = 0
Begin
	-- Return debtor references
	Set @sSQLString = "Select DISTINCT 
	                        BC.CASEID as CaseKey, 
                            OI.ACCTDEBTORNO as DebtorKey, 
                            CN.REFERENCENO as ReferenceNo,
                            CN.NAMETYPE as 'NameType'
			From OPENITEM OI
			cross apply dbo.fn_GetBillCases(OI.ITEMTRANSNO, OI.ITEMENTITYNO) BC
			join CASENAME CN on (CN.CASEID=BC.CASEID
						and CN.NAMENO=OI.ACCTDEBTORNO
						and CN.NAMETYPE=case when ISNULL(OI.RENEWALDEBTORFLAG, 0) = 1
											AND EXISTS(SELECT * FROM CASENAME CNZ WHERE NAMETYPE = 'Z' AND CNZ.CASEID = BC.CASEID)
										THEN 'Z' ELSE 'D' END
						and (CN.EXPIRYDATE is null OR CN.EXPIRYDATE > GetDate()))
			Where OI.ITEMENTITYNO = @pnItemEntityNo
			and OI.ITEMTRANSNO = @pnItemTransNo"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnItemTransNo	int,
					  @pnItemEntityNo	int',
					  @pnItemTransNo	= @pnItemTransNo,
					  @pnItemEntityNo	= @pnItemEntityNo
End

If @ErrorCode=0 and exists(select * from tempdb.dbo.sysobjects where name = @sDebtorTableName )
Begin 
	Set @sSQLString = 'DROP TABLE ' + @sDebtorTableName

	Exec @ErrorCode=sp_executesql @sSQLString
End

return @ErrorCode
go

grant execute on dbo.[biw_GetBillDebtors]  to public
go
