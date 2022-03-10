-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_GetDebtorDetails] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_GetDebtorDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_GetDebtorDetails].'
	drop procedure dbo.[biw_GetDebtorDetails]
end
print '**** Creating procedure dbo.[biw_GetDebtorDetails]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[biw_GetDebtorDetails]
				@pnUserIdentityId	int,		-- Mandatory
				@psCulture		nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@pnEntityKey		int=null,
				@pnDebtorKey		int=null,
				@pdtTransDate		datetime=null,
				@pnCaseKey		int=null,
				@pbUseRenewalDebtor	bit=0,	-- use renewal debtor, if true return renewal debtors, if false
								-- return debtors, if null return both
				@pbUseSendBillsTo	bit=1,	-- explicit instruction to return send bills to name if available.
                @psAction               nvarchar(2) = null, -- case action used in the bill
			    @pnRaisedByStaffKey		int = null -- Used to get the actual Tax code
as
-- PROCEDURE :	biw_GetDebtorDetails
-- VERSION :	45
-- DESCRIPTION:	A procedure that returns an individual debtor's details for a bill.
--
--		*******************************************
--		NOTE: If adding columns, you need to also add the same columns to biw_GetDebtorsFromCaseList and biw_GetBillDebtors
--		*******************************************
--
-- COPYRIGHT:	Copyright 1993 - 2012 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC		Version Description
-- -----------	-------	------		------- -----------------------------------------------------------
-- 02-Nov-2009	AT	RFC3605		1	Procedure created
-- 30-Apr-2010	AT	RFC9092		2	Modified to cater for returning all debtors from a case.
-- 07-May-2010	AT	RFC9135		3	Return Bill Format Profile.
-- 20-May-2010	AT	RFC9092		4	Return Bill Percentage.
-- 25-May-2010	AT	RFC9092		5	Return individual debtor details using cursor.
-- 11-Jul-2010	AT	RFC7278		6	Return E-Billling information.
-- 14-Jul-2010	AT	RFC7273		7	Return Billing Cap Warnings
-- 15-Jul-2010	AT	RFC7271		8	Return Address Change Reason
-- 10-Aug-2010	AT	RFC9403		9	Modified to cater for Renewal Debtor
-- 16-Aug-2010	AT	RFC100331	10	Return case name copy to if a case is passed.
-- 26-Aug-2010	AT	RFC100331	11	Return formatted debtor's bill contact if case debtor contact doesn't exist.
-- 01-Sep-2010	AT	RFC9556		12	Restrict expired copies to names.
-- 06-Sep-2010	AT	RFC9741		13	Fixed error retrieving copies to names.
-- 12-Oct-2010	AT	RFC8982		14	Fixed hard coding of copy to name.
-- 14-Oct-2010	AT	RFC8982		15	Modified retrieval of copy to names to use stored proc.
-- 12-Apr-2011	AT	RFC10473	16	Return Send Bills To name of debtor if available.
-- 20-May-2011	AT	RFC10679	17	Use fn_GetFormattedAddress to return the address.
-- 17-Aug-2011	AT	RFC11128	18	Use case name address if available.
-- 19-Aug-2011	AT	RFC11128	19	Use Bill to name over debtor name and only if its a Case related bill.
-- 21-Sep-2011	AT	RFC11132	20	Rewrite case debtor/attention/address logic to follow c/s.
-- 02-Nov-2011	AT	RFC9451		21	Make Entity Key parameter optional.
-- 04-Jan-2012	AT	RFC9165		22	Return Buy Rate.
-- 01-Feb-2012	AT	RFC11864	23	Return case-name details for send-bills-to of the name is the same as the debtor.
-- 02-May-2012	vql	RFC100635	24	Name Presentation not always used when displaying a name.
-- 14-Jun-2012	KR	RFC12005	25	Linked CASETYPE and WIPCODE to DISCOUNT table.
-- 29-Aug-2012	LP	RFC10474	26	Return IsClient flag for the debtor.
-- 30-Jan-2013	DV	RFC100777	27	Call fn_GetBestMatchAssociatedNameNo to get the best match Associated Name and added
--						a check to compare the debtorkey when both the debtorkey and casekey are provided
-- 13-Feb-2013	DV	RFC13175	28	Remove OfficeKey from the result set
-- 19-Aug-2013	vql	RFC25930	29	Return both Renewal Debtors and Debtors depending on pbUseRenewalDebtor.
-- 22-Oct-2013	AT	RFC13513	30	Return Assocaited Name details when debtor only and 'send bills to' associated name same as debtor name.
-- 01 Jun 2015	MS	R35907	    	31	Added COUNTRYCODE to the Discount table
-- 20 Oct 2015  MS  R53933  	32	Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols
-- 02 Nov 2015	vql	R53910		33	Adjust formatted names logic (DR-15543).
-- 13 Feb 2017	DV	R64225		34	Check if associated name has debotor name type classification
-- 23 Feb 2017	MF	ZLZYG8		35	Explicit ORDER BY required when returning debtors as we can't rely on the order rows were inserted into temp table.
-- 04 Apr 2017	MS	R71040      36  Added fn_GetBestMatchAssociatedNameWithSequence for fetching best match inherited associated name 
-- 24 Jan 2018	AK	R72409      37  Conditionally return Correspondence Instructions Billing then default instruction 
-- 07 Feb 2018  MS  R72578      38  Added case action logic for fetching best fit debtor
-- 26 Feb 2018  AK  R72937      39  Added logic to return effective tax code
-- 07 Mar 2018  AK  R73598      40  added HasOfficeInEu in resultset

-- 06-Aug-2018	AK	R74677		41	Use fn_GetFormattedBillingAddress to return the address with local country.
-- 11 Oct 2018  MS      DR-43550        42      Return Office Entity 
-- 05 Apr 2019  MS      DR-48006        43      Display debtor code with the Debtor Name 
-- 30 Oct 2019  MS      DR-53313        44      Return FormattedNameWithCode column
-- 24 Mar 2020	LP	DR-7536		45	Return Language columns

set concat_null_yields_null off

set nocount on

Declare		@ErrorCode	int
Declare		@nRowCount	int
Declare		@sSQLString	nvarchar(MAX)
Declare		@sAlertXML	nvarchar(2000)
Declare		@sLookupCulture	nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set @ErrorCode = 0

-- CaseName
Declare @nBillPercentage	decimal(5,2)
Declare @sReferenceNo		nvarchar(80)
Declare @nCorrespondNameKey	int

Declare @bRenewalDebtorInUse	bit

Set @bRenewalDebtorInUse = 0

-- Currency
Declare @sCurrency nvarchar(3)
Declare	@nBankRate		decimal(11,4)
Declare @nBuyRate		decimal(11,4)
Declare @nSellRate		decimal(11,4)
Declare @nDecimalPlaces	tinyint
Declare @nRoundBilledValues tinyint
Declare @sHomeCurrency nvarchar(3)

-- IPName
Declare @sInstructions		nvarchar(254)
Declare @sTaxCode		nvarchar(3)
Declare @sTaxDescription	nvarchar(30)
Declare @nTaxRate		decimal(11,4)
Declare @bAllowMultiCase	bit
Declare @nBillFormatProfileKey	int
Declare @nBillMapProfileKey	int
Declare @nBillingCap		decimal(12,2)
Declare @nBilledAmount		decimal(12,2)
Declare	@bDebtorHasSameNameType bit
Declare @nLanguageKey           int
Declare @sLanguageDescription   nvarchar(80)	

Declare @sDebtorTableName	nvarchar(30)

Set @sDebtorTableName = "##DebtorCurrencyDetails" + Cast(@@SPID as nvarchar(30))

If @ErrorCode=0 and exists(select * from tempdb.dbo.sysobjects where name = @sDebtorTableName )
Begin 
	Set @sSQLString = 'DROP TABLE ' + @sDebtorTableName

	Exec @ErrorCode=sp_executesql @sSQLString
End

If @ErrorCode = 0
Begin 
	Set @sSQLString="
				Select @bDebtorHasSameNameType= CASE WHEN PICKLISTFLAGS & 16 = 16 then 1 else 0 end 
				from NAMETYPE 
				where NAMETYPE='D'"

				exec @ErrorCode = sp_executesql @sSQLString,
							N'@bDebtorHasSameNameType	bit			output',
							  @bDebtorHasSameNameType	= @bDebtorHasSameNameType	output
End

If @ErrorCode = 0
Begin
	Set @sSQLString = 
	"create table " + @sDebtorTableName + "
	(
		NAMENO			INT,
		SEQUENCE		INT,
		BILLPERCENTAGE		DECIMAL(5,2) null,
		REFERENCENO		NVARCHAR(80) COLLATE database_default NULL,
		CORRESPONDNAME		INT null,
		INSTRUCTIONS		nvarchar(254) COLLATE database_default NULL,
		INSTRUCTIONSBILLING ntext COLLATE database_default NULL,
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
		ADDRESSCODE		INT,
		ISCLIENT		bit NOT NULL default 0,
		HASOFFICEINEU	bit NOT NULL default 0,
		NAMETYPE		nvarchar(3) COLLATE database_default null,
		NAMETYPEDESCRIPTION	nvarchar(50) COLLATE database_default null
	)"
	
	Exec @ErrorCode=sp_executesql @sSQLString
End

If ((@pnDebtorKey is null and @pnCaseKey is null)
	OR (@pnCaseKey is not null and not exists (select * from CASENAME WHERE CASEID = @pnCaseKey and NAMETYPE = CASE WHEN @pbUseRenewalDebtor = 1 THEN 'Z' else '' END OR NAMETYPE= 'D' )))
Begin	
	-- Debtor not provided or not found.
	Set @sAlertXML = dbo.fn_GetAlertXML('AC15', 'Debtor could not be determined from case.',
										null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @ErrorCode = @@ERROR
End

If @ErrorCode = 0
Begin
	If (@pnCaseKey is not null)
	Begin
		-- Check if we can actually use the Renewal Debtor
		If (@pbUseRenewalDebtor = 1
		and exists (select *
			from CASENAME
			where NAMETYPE = 'Z'
			and CASEID = @pnCaseKey))
		Begin
			Set @bRenewalDebtorInUse = 1
		End			
		
		-- Debtor/name/address/contact logic:
			-- If Bill To Name exists and is different from debtor, 
				-- Debtor = Bill to Name
				-- get in attention/address in priority order (FCDBOpenItemTransaction.cfConstructBillToAddress)
					-- Bill To contact/address (ASSOCIATEDNAME)
					-- Debtor main contact name/address (NAME)
			-- else use Get Billing name/address in priority order (FCDBOpenItemTransaction.cfConstructBillingAddress)
				-- CaseName contact/address (CASENAME)
				-- If Debtor is inherited
					-- Parent name's contact/address (ASSOCIATEDNAME)
				-- Else
					-- Bill To name/address (ASSOCIATEDNAME) <- C/S CHECKS THIS, BUT IT WILL NEVER OCCUR SINCE CONDITION WILL BE MET ABOVE
					-- Debtor main contact name/address (NAME)
		Set @sSQLString = "insert into " + @sDebtorTableName + " (NAMENO, SEQUENCE, BILLPERCENTAGE, REFERENCENO, CORRESPONDNAME, ADDRESSCODE, ISCLIENT, NAMETYPE, NAMETYPEDESCRIPTION)
				Select NAMENO, SEQUENCE, BILLPERCENTAGE, REFERENCENO, CORRESPONDNAME, ADDRESSCODE, ISCLIENT, NAMETYPE, DESCRIPTION
				FROM "
								
			Set @sSQLString = @sSQLString + char(10) + "(SELECT DISTINCT 
				case when (@pbUseSendBillsTo = 1 and ANDEB.RELATEDNAME IS NOT NULL and ANDEB.RELATEDNAME != CND.NAMENO)
					then ANDEB.RELATEDNAME 
					else CND.NAMENO
					end AS NAMENO, 
				CND.SEQUENCE AS SEQUENCE, 
				CND.BILLPERCENTAGE AS BILLPERCENTAGE,
				CND.REFERENCENO AS REFERENCENO,
							
				CASE WHEN (@pbUseSendBillsTo = 1 and ANDEB.RELATEDNAME IS NOT NULL and ANDEB.RELATEDNAME != CND.NAMENO)
					THEN isnull(ANDEB.CONTACT,N.MAINCONTACT) -- use send bills to explcitly
				WHEN (ANDEB.RELATEDNAME = CND.NAMENO)
					THEN COALESCE(CND.CORRESPONDNAME,INDEB.CONTACT,ANDEB.CONTACT,N.MAINCONTACT) -- Use debtor/sendbillsto
					ELSE COALESCE(CND.CORRESPONDNAME,INDEB.CONTACT,N.MAINCONTACT) -- use debtor
				END AS CORRESPONDNAME,
				
				CASE WHEN (@pbUseSendBillsTo = 1 and ANDEB.RELATEDNAME IS NOT NULL and ANDEB.RELATEDNAME != CND.NAMENO)
					THEN isnull(ANDEB.POSTALADDRESS,N.POSTALADDRESS)
				WHEN (ANDEB.RELATEDNAME = CND.NAMENO)
					THEN COALESCE(CND.ADDRESSCODE,INDEB.POSTALADDRESS,ANDEB.POSTALADDRESS,N.POSTALADDRESS)
				ELSE COALESCE(CND.ADDRESSCODE,INDEB.POSTALADDRESS,N.POSTALADDRESS)
				END AS ADDRESSCODE,
				case when (@pbUseSendBillsTo = 1 and ANDEB.RELATEDNAME IS NOT NULL and ANDEB.RELATEDNAME != CND.NAMENO)
					then ISNULL((SELECT 1 from IPNAME where NAMENO = ANDEB.RELATEDNAME), 0) 
					else ISNULL((SELECT 1 from IPNAME where NAMENO = CND.NAMENO), 0)
					end AS ISCLIENT,
				NT.NAMETYPE,"
				+dbo.fn_SqlTranslatedColumn('NT','DESCRIPTION',null,null,@sLookupCulture,@pbCalledFromCentura) + "
				FROM CASENAME CND        
                                OUTER APPLY dbo.fn_GetBestMatchAssociatedNameNo(CND.NAMENO,CND.CASEID,'BIL', @psAction, @bDebtorHasSameNameType, @bRenewalDebtorInUse)  ANDEB 
				Left Join ASSOCIATEDNAME INDEB ON (ISNULL(CND.INHERITED,0) = 1
								AND INDEB.NAMENO = CND.INHERITEDNAMENO
								AND INDEB.RELATIONSHIP = CND.INHERITEDRELATIONS
								AND INDEB.SEQUENCE = CND.INHERITEDSEQUENCE
                                                                AND INDEB.RELATEDNAME = dbo.fn_GetBestMatchAssociatedNameWithSequence(CND.INHERITEDNAMENO, CND.CASEID, CND.INHERITEDRELATIONS, CND.INHERITEDSEQUENCE, @psAction))
				join NAME N ON (N.NAMENO = case when (@pbUseSendBillsTo = 1 and ANDEB.RELATEDNAME IS NOT NULL and ANDEB.RELATEDNAME != CND.NAMENO)
								then ANDEB.RELATEDNAME 
								else CND.NAMENO
								end)
				left join NAMETYPE NT on (NT.NAMETYPE = CND.NAMETYPE)
				WHERE CND.CASEID = @pnCaseKey"
				If ( @pbUseRenewalDebtor is null)
				Begin
					set @sSQLString = @sSQLString + " and CND.NAMETYPE in ('Z','D')"
				End
				Else
				Begin
					set @sSQLString = @sSQLString + " and CND.NAMETYPE = case when ISNULL(@bRenewalDebtorInUse,0) = 1 then 'Z' else 'D' end"
				End
				
				
				if(@pnDebtorKey is not null)
				Begin
					Set @sSQLString = @sSQLString + char(10) + "and CND.NAMENO = @pnDebtorKey"
				End
				Set @sSQLString = @sSQLString + char(10) + ") AS CN ORDER BY CN.SEQUENCE"	
							
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		int,
					@bRenewalDebtorInUse	bit,
					@pbUseSendBillsTo	bit,
					@pnDebtorKey	        int,
					@bDebtorHasSameNameType bit,
                                        @psAction       nvarchar(2)',
					@pnCaseKey = @pnCaseKey,
					@bRenewalDebtorInUse = @bRenewalDebtorInUse,
					@pbUseSendBillsTo = @pbUseSendBillsTo,
					@pnDebtorKey = @pnDebtorKey,
					@bDebtorHasSameNameType = @bDebtorHasSameNameType,
                                        @psAction = @psAction


	End
	Else If (@pnDebtorKey is not null)
	Begin
		if exists (select * from ASSOCIATEDNAME 
					WHERE NAMENO = @pnDebtorKey 
					AND RELATEDNAME = @pnDebtorKey
					AND RELATIONSHIP = 'BIL')
		Begin
			Set @sSQLString = "insert into " + @sDebtorTableName + " (NAMENO, SEQUENCE, BILLPERCENTAGE, REFERENCENO, CORRESPONDNAME, ADDRESSCODE, ISCLIENT)
					Select @pnDebtorKey, 0, 100, null, ISNULL(AN.CONTACT, N.MAINCONTACT), ISNULL(AN.POSTALADDRESS, N.POSTALADDRESS), cast(ISNULL(I.NAMENO, 0) as bit)
					FROM NAME N
					join ASSOCIATEDNAME AN on (AN.NAMENO = N.NAMENO 
											AND AN.RELATEDNAME = N.NAMENO
											AND AN.RELATIONSHIP = 'BIL')
					left join IPNAME I on (I.NAMENO = N.NAMENO)
					WHERE N.NAMENO = @pnDebtorKey"
		End
		else
		Begin
			Set @sSQLString = "insert into " + @sDebtorTableName + " (N.NAMENO, SEQUENCE, BILLPERCENTAGE, REFERENCENO, CORRESPONDNAME, ADDRESSCODE, ISCLIENT)
					Select @pnDebtorKey, 0, 100, null, MAINCONTACT, POSTALADDRESS, cast(ISNULL(I.NAMENO, 0) as bit)				
					FROM NAME N
					left join IPNAME I on (I.NAMENO = N.NAMENO)				
					WHERE N.NAMENO = @pnDebtorKey"
		End
				
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnDebtorKey	int',
					@pnDebtorKey = @pnDebtorKey
	End
End

If @ErrorCode = 0
Begin

	EXEC @ErrorCode =  dbo.[biw_PopulateDebtorDetails]
				@pnUserIdentityId	= @pnUserIdentityId,		-- Mandatory
				@psCulture		= @psCulture,
				@pbCalledFromCentura	= @pbCalledFromCentura,
				@sTempTable		= @sDebtorTableName,
				@pnEntityKey		= @pnEntityKey,
				@pdtTransDate		= @pdtTransDate,
				@pnCaseKey		= @pnCaseKey,
				@pnRaisedByStaffKey = @pnRaisedByStaffKey
				
End

If (@ErrorCode = 0)
Begin
	If (@pnCaseKey is not null)
	Begin
		If (@psAction is not null)
		Begin
			exec @ErrorCode = bi_GetBillingLanguage
						@pnLanguageKey = @nLanguageKey output,
						@pnUserIdentityId = @pnUserIdentityId,
						@pnDebtorKey = null,
						@pnCaseKey = @pnCaseKey,
						@psActionKey = @psAction,
						@pbDeriveAction = 0
		End
		Else Begin
			exec @ErrorCode = bi_GetBillingLanguage
						@pnLanguageKey = @nLanguageKey output,
						@pnUserIdentityId = @pnUserIdentityId,
						@pnDebtorKey = null,
						@pnCaseKey = @pnCaseKey,
						@psActionKey = null,
						@pbDeriveAction = 1
		End
	End
	Else Begin
		exec @ErrorCode = bi_GetBillingLanguage
						@pnLanguageKey = @nLanguageKey output,
						@pnUserIdentityId = @pnUserIdentityId,
						@pnDebtorKey = @pnDebtorKey,
						@pnCaseKey = null,
						@psActionKey = null,
						@pbDeriveAction = 0
	End

    if (@ErrorCode = 0 and @nLanguageKey is not null)
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


If @ErrorCode = 0
Begin
	Set @sSQLString = "
		Select 
		N.NAMENO as NameNo,
                dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, CN.NAMESTYLE, 7101)) as FormattedName,
		dbo.fn_ApplyNameCodeStyle(dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, CN.NAMESTYLE, 7101)),
		                        NT.SHOWNAMECODE, N.NAMECODE) as FormattedNameWithCode,
		ISNULL(D.BILLPERCENTAGE, 100) as BillPercentage,
		D.CURRENCY as Currency,
		D.BUYRATE as BuyExchangeRate,
		D.SELLRATE as SellExchangeRate,
		isnull(D.DECIMALPLACES,2)	as DecimalPlaces,
		D.ROUNDBILLVALUES as RoundBilledValues,
		D.REFERENCENO as 'ReferenceNo',
		dbo.fn_FormatNameUsingNameNo(ATTN.NAMENO, COALESCE(ATTN.NAMESTYLE, CNATTN.NAMESTYLE, 7101)) as 'AttentionName',
		dbo.fn_GetFormattedBillingAddress(D.ADDRESSCODE, @psCulture, null, null, 0) as 'Address',
		TC.TOTALCREDITS as 'TotalCredits',
		ISNULL(D.INSTRUCTIONSBILLING,D.INSTRUCTIONS) as 'Instructions',
		D.TAXCODE as 'TaxCode',
		D.TAXDESCRIPTION as 'TaxDescription',
		D.TAXRATE AS 'TaxRate',
		ATTN.NAMENO AS 'AttentionNameKey',
		COALESCE(D.ADDRESSCODE,N.POSTALADDRESS) AS 'AddressKey',
		@pnCaseKey AS 'CaseKey',
		null as 'OpenItemNo',
		null as 'LogDateTimeStamp',
		isnull(D.ALLOWMULTICASE, 0) as 'AllowMultiCase',
		D.BILLFORMATPROFILEKEY as 'BillFormatProfileKey',
		D.BILLMAPPROFILEKEY	as 'BillMapProfileKey',
		BMP.BILLMAPDESC		as 'BillMapProfileDescription',
		D.BILLINGCAP		as 'BillingCap',
		D.BILLEDAMOUNT		as 'BilledAmount',
		D.BILLINGCAPSTART	as 'BillingCapStart',
		D.BILLINGCAPEND		as 'BillingCapEnd',
		null			as 'AddressChangeReason',
		null			as 'BillToNameKey',
		null			as 'BillToFormattedName',
		D.ISCLIENT		as 'IsClient',
		D.HASOFFICEINEU as HasOfficeInEu,
		D.NAMETYPEDESCRIPTION	as 'NameTypeDescription',
		D.NAMETYPE		as 'NameType',
        SN.NAMENO               as 'OfficeEntity',
		@nLanguageKey	as 'LanguageKey',
		@sLanguageDescription as 'LanguageDescription'
		From " + @sDebtorTableName + " D
		Join NAME N on (N.NAMENO = D.NAMENO)
		Left Join (Select (sum(OI.LOCALBALANCE) * -1) as TOTALCREDITS, OI.ACCTENTITYNO, OI.ACCTDEBTORNO
				From OPENITEM OI
				left join OPENITEMCASE OIC on (OI.ITEMENTITYNO = OIC.ITEMENTITYNO
						and OI.ITEMTRANSNO = OIC.ITEMTRANSNO
						and OI.ACCTENTITYNO = OIC.ACCTENTITYNO
						and OI.ACCTDEBTORNO = OIC.ACCTDEBTORNO) 
				Where OIC.ITEMENTITYNO IS NULL
				and OI.STATUS IN (1, 2) 
				and OI.ITEMTYPE IN (SELECT ITEM_TYPE_ID
						FROM DEBTOR_ITEM_TYPE
						WHERE TAKEUPONBILL = 1)
				Group By OI.ACCTENTITYNO, OI.ACCTDEBTORNO"
		
				if @pnEntityKey is not null
				Begin
					Set @sSQLString = @sSQLString + char(10) + "Having OI.ACCTENTITYNO = @pnEntityKey"
				End
				
				Set @sSQLString = @sSQLString + char(10) + ") as TC on (TC.ACCTDEBTORNO = N.NAMENO)
		Left Join NAME ATTN on (ATTN.NAMENO = D.CORRESPONDNAME)
		Left Join BILLMAPPROFILE BMP on (BMP.BILLMAPPROFILEID = D.BILLMAPPROFILEKEY)
		left join COUNTRY CN on (CN.COUNTRYCODE=N.NATIONALITY)
		left join COUNTRY CNATTN on (CNATTN.COUNTRYCODE=ATTN.NATIONALITY)
                left join TABLEATTRIBUTES TA on (TA.PARENTTABLE = 'NAME' and TA.GENERICKEY = N.NAMENO and TA.TABLETYPE = 44)
                left join OFFICE O on (O.OFFICEID = TA.TABLECODE)
                left join SPECIALNAME SN on (O.ORGNAMENO = SN.NAMENO and SN.ENTITYFLAG = 1)
                left join NAMETYPE NT on (NT.NAMETYPE = CASE WHEN @pbUseRenewalDebtor = 1 THEN 'Z' ELSE 'D' END)
		ORDER BY D.SEQUENCE"


		exec @ErrorCode=sp_executesql @sSQLString,
				N'	@pnEntityKey int,
					@pnCaseKey int,
					@psCulture nvarchar(10),
					@pbUseRenewalDebtor     bit,
					@nLanguageKey	int,
					@sLanguageDescription	nvarchar(80)',
					@pnEntityKey = @pnEntityKey,
					@pnCaseKey = @pnCaseKey,
					@psCulture = @psCulture,
					@pbUseRenewalDebtor = @pbUseRenewalDebtor,
					@nLanguageKey = @nLanguageKey,
					@sLanguageDescription = @sLanguageDescription
End

-- Return Copies To names
If (@ErrorCode = 0)
Begin
	exec dbo.biw_GetCopyToNames
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pbCalledFromCentura	= @pbCalledFromCentura,
		@pnEntityKey		= null,
		@pnTransKey		= null,
		@pnDebtorKey		= @pnDebtorKey,
		@pnCaseKey		= @pnCaseKey,
		@pbUseRenewalDebtor	= @pbUseRenewalDebtor,
		@psResultTable		= null
End

-- Return Discounts applicable
If (@ErrorCode = 0)
Begin
	Set @sSQLString = "Select DISCOUNT.NAMENO AS NameKey,
			DISCOUNT.SEQUENCE as Sequence,
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
			dbo.fn_FormatNameUsingNameNo(CON.NAMENO, COALESCE(CON.NAMESTYLE, CN.NAMESTYLE, 7101)) as CaseOwnerName,
			EN.NAMENO as EmployeeKey,
			dbo.fn_FormatNameUsingNameNo(EN.NAMENO, COALESCE(EN.NAMESTYLE, CNEN.NAMESTYLE, 7101)) as EmployeeName,
			Case when DISCOUNTRATE > 0 then 'Discount' else 'Surcharge' end as ApplyAs,
			BASEDONAMOUNT as BasedOnAmount,
			CT.CASETYPE as CaseTypeKey,
			" + dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CT',@sLookupCulture,@pbCalledFromCentura) + " as 'CaseTypeDescription',
			WIPT.WIPCODE as WIPCodeKey,
			" + dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'WIPT',@sLookupCulture,@pbCalledFromCentura) + " as 'WIPCodeDescription',
                        CNT.COUNTRYCODE as CountryCode,
			" + dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CNT',@sLookupCulture,@pbCalledFromCentura) + " as 'Country'
			From " + @sDebtorTableName + " D
			JOIN DISCOUNT on (D.NAMENO = DISCOUNT.NAMENO)
			Left Join WIPTYPE WT ON (DISCOUNT.WIPTYPEID = WT.WIPTYPEID)
			Left Join WIPCATEGORY WC ON (DISCOUNT.WIPCATEGORY = WC.CATEGORYCODE)
			Left Join PROPERTYTYPE PT ON (DISCOUNT.PROPERTYTYPE = PT.PROPERTYTYPE)
			Left Join ACTIONS A ON (DISCOUNT.ACTION = A.ACTION)
			Left Join NAME CON ON (DISCOUNT.CASEOWNER = CON.NAMENO)
			left join COUNTRY CN on (CN.COUNTRYCODE=CON.NATIONALITY)
			Left Join NAME EN ON (DISCOUNT.EMPLOYEENO = EN.NAMENO)
			left join COUNTRY CNEN on (CNEN.COUNTRYCODE=EN.NATIONALITY)
			Left Join CASETYPE CT on (DISCOUNT.CASETYPE = CT.CASETYPE)
			Left Join WIPTEMPLATE WIPT on (DISCOUNT.WIPCODE = WIPT.WIPCODE)
                        Left Join COUNTRY CNT on (DISCOUNT.COUNTRYCODE = CNT.COUNTRYCODE)
			ORDER BY D.SEQUENCE, DISCOUNT.SEQUENCE"

	exec @ErrorCode=sp_executesql @sSQLString
End

If (@ErrorCode = 0)
Begin
	-- Return debtor warnings
	exec biw_ListDebtorWarnings @pnUserIdentityId = @pnUserIdentityId,
				@psCulture = @psCulture,
				@pbCalledFromCentura = @pbCalledFromCentura,
				@pnItemEntityNo	= @pnEntityKey,
				@pnItemTransNo = null,
				@pdtTransDate	= @pdtTransDate,
				@psDebtorTableName = @sDebtorTableName
				
End

If @ErrorCode=0 and exists(select * from tempdb.dbo.sysobjects where name = @sDebtorTableName )
Begin 
	Set @sSQLString = 'DROP TABLE ' + @sDebtorTableName

	Exec @ErrorCode=sp_executesql @sSQLString
End


return @ErrorCode
go

grant execute on dbo.[biw_GetDebtorDetails]  to public
go
