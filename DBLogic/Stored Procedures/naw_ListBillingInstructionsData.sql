-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListBillingInstructionsData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListBillingInstructionsData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListBillingInstructionsData.'
	Drop procedure [dbo].[naw_ListBillingInstructionsData]
End
Print '**** Creating Stored Procedure dbo.naw_ListBillingInstructionsData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_ListBillingInstructionsData
(
	@pnRowCount		int		= null output,	-- just an example
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int,		-- Mandatory
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	naw_ListBillingInstructionsData
-- VERSION:	10
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populates the NameBillingInstructionsData dataset

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 25 Aug 2009	MS	RFC8288	1	Procedure created
-- 03 Feb 2010	MS	RFC7274	2	Billing Cap and Billing Cap period fields added
-- 17 Mar 2010	MS	RFC7280	3	Bill Format Profile field added
-- 23 Jun 2010	MS	RFC7269	4	Return SeparateMarginFlag column from IPNAME
-- 30 Jun 2010	MS	RFC7274	5	Return Billing Cap StartDate and ResetFlag column from IPNAME
-- 09 Jul 2010	AT	RFC7278	6	Bill Map Profile field added
-- 14 Jul 2011	MF	R10976 	7	SQL Error resolved by changing @sSek
-- 11 Apr 2013	DV	R13270	8	Increase the length of nvarchar to 11 when casting or declaring integer
-- 17 Jul 2013	KR	R13640	9	Added RequireExemptTaxNo to the result set
-- 02 Nov 2015	vql	R53910	10	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @sSQLSelect 			nvarchar(max)
Declare @sSQLString			nvarchar(max)
Declare @nErrorCode			int
Declare @sLookupCulture			nvarchar(10)

Declare @nStatementAttentionKey		int
Declare @nStatementAttentionCode	nvarchar(10)
Declare @sStatementAttention		nvarchar(254)
Declare @nStatementNameKey		int
Declare @sStatementNameCode		nvarchar(10)
Declare @sStatementName			nvarchar(254)
Declare @sStatementAddress		nvarchar(254)
Declare @nStatementAddressKey		int
Declare @nBillingAttentionKey		int
Declare @nBillingAttentionCode		nvarchar(10)
Declare @sBillingAttention		nvarchar(254)
Declare @nBillingNameKey		int
Declare @sBillingNameCode		nvarchar(10)
Declare @sBillingName			nvarchar(254)
Declare @nBillingAddressKey		int
Declare @sBillingAddress		nvarchar(254)
Declare @bIsBillingAvailable		bit
Declare @nBillingSequence		int
Declare @nStatementSequence		int
Declare @bRequireExemptTaxNo		bit

--REQUIREEXEMPTTAXNO

Declare @sNameCode			nvarchar(10)
Declare @sName				nvarchar(254)
Declare @nAttentionKey			int
Declare @sAttention			nvarchar(254)
Declare @nAddressKey			int
Declare @sAddress			nvarchar(254)
Declare @sCountryKey			nvarchar(3)

Declare @sLocalCurrencyCode		nvarchar(3)
Declare @nLocalDecimalPlaces		tinyint
Declare @bIsMultiTier			bit

-- Initialize variables
Set @nErrorCode		= 0
Set @pnRowCount		= 0
set @sLookupCulture	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Retrieve Local Currency information
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	
		@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
		@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
		@pnUserIdentityId 	= @pnUserIdentityId,
		@pbCalledFromCentura	= @pbCalledFromCentura
End

-- Retrieve SITE Control value
If @nErrorCode=0
Begin
	Set @sSQLString = "Select @bIsMultiTier = COLBOOLEAN
				FROM SITECONTROL
				WHERE CONTROLID='Tax for HOMECOUNTRY Multi-Tier'"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@bIsMultiTier	bit output',
				  @bIsMultiTier	= @bIsMultiTier output
End

-- Retrieve SITE Control value
If @nErrorCode=0
Begin
	Set @sSQLString = "Select @sCountryKey = COLCHARACTER
				FROM SITECONTROL
				WHERE CONTROLID='HOMECOUNTRY'"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@sCountryKey	nvarchar(3) output',
				  @sCountryKey	= @sCountryKey output
End

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select  @sNameCode	= N.NAMECODE,
		@sName		= dbo.fn_FormatNameUsingNameNo(N.NAMENO, NULL),
		@nAttentionKey	= N.MAINCONTACT,
		@sAttention	= dbo.fn_FormatNameUsingNameNo(AN.NAMENO, NULL), 
		@nAddressKey	= A.ADDRESSCODE,
		@sAddress	= dbo.fn_FormatAddress(A.STREET1, A.STREET2, A.CITY, A.STATE, S.STATENAME, A.POSTCODE, 
			CASE WHEN C.COUNTRYCODE = @sCountryKey 
			THEN NULL ELSE C.POSTALNAME END, C.POSTCODEFIRST, C.STATEABBREVIATED, C.POSTCODELITERAL, C.ADDRESSSTYLE),
		@bRequireExemptTaxNo = cast(isnull(C.REQUIREEXEMPTTAXNO,0) as bit)
	from NAME N	
	left join NAME AN   on (AN.NAMENO     = N.MAINCONTACT)
	left join ADDRESS A on (A.ADDRESSCODE = N.POSTALADDRESS)
	left join COUNTRY C on (C.COUNTRYCODE = A.COUNTRYCODE)
	left Join STATE S   on (S.COUNTRYCODE = A.COUNTRYCODE and S.STATE = A.STATE)	
	where N.NAMENO = @pnNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@sNameCode		nvarchar(10)	output,
				  @sName		nvarchar(254)	output,
				  @nAttentionKey	int		output,
				  @sAttention		nvarchar(254)	output,
				  @nAddressKey		int		output,
				  @sAddress		nvarchar(254)	output,
				  @sCountryKey		nvarchar(3),				  	
				  @pnNameKey		int,
				  @bRequireExemptTaxNo bit output',
				  @sNameCode		= @sNameCode	output,
				  @sName		= @sName	output,
				  @nAttentionKey	= @nAttentionKey output,
				  @sAttention		= @sAttention	output,
				  @nAddressKey		= @nAddressKey	output,
				  @sAddress		= @sAddress	output,	
				  @bRequireExemptTaxNo = @bRequireExemptTaxNo output,
				  @sCountryKey		= @sCountryKey,			 
				  @pnNameKey		= @pnNameKey
End

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select  @pnNameKey 	as NameKey,
		@sNameCode	as NameCode,
		@sName		as Name,
		@nAttentionKey	as AttentionKey,
		@sAttention	as Attention, 
		@nAddressKey    as AddressKey,
		@sAddress	as Address,
		@sCountryKey	as CountryKey"	

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnNameKey		int,
				  @sNameCode		nvarchar(10),
				  @sName		nvarchar(254),
				  @nAttentionKey	int,
				  @sAttention		nvarchar(254),
				  @nAddressKey		int,
				  @sAddress		nvarchar(254),
				  @sCountryKey		nvarchar(3)',
				  @pnNameKey		= @pnNameKey,
				  @sNameCode		= @sNameCode,
				  @sName		= @sName,
				  @nAttentionKey	= @nAttentionKey,
				  @sAttention		= @sAttention,
				  @nAddressKey		= @nAddressKey,
				  @sAddress		= @sAddress,
				  @sCountryKey		= @sCountryKey
End

-- Populating Billing Instructions result set
If @nErrorCode = 0
Begin	
	-- Extract the Statement details and Billing details information to reduce the number 
	-- of joins in the main statement and to use sp_executesql:
	Set @sSQLString=
	"Select  @nStatementAttentionKey=STN.NAMENO,"+CHAR(10)+
	"@sStatementAttention=dbo.fn_FormatNameUsingNameNo(STN.NAMENO, NULL),"+CHAR(10)+		
	"@nStatementNameKey=RLN.NAMENO, @sStatementNameCode=RLN.NAMECODE,"+CHAR(10)+
	"@sStatementName=dbo.fn_FormatNameUsingNameNo(RLN.NAMENO, NULL),"+CHAR(10)+
	"@nStatementSequence = AN.SEQUENCE,"+CHAR(10)+
	"@nStatementAddressKey=SA.ADDRESSCODE,"+CHAR(10)+
	"@sStatementAddress=dbo.fn_FormatAddress(SA.STREET1, SA.STREET2, SA.CITY, SA.STATE, SS.STATENAME, SA.POSTCODE, CASE WHEN SC.COUNTRYCODE = HC.COLCHARACTER
			THEN NULL ELSE SC.POSTALNAME END, SC.POSTCODEFIRST, SC.STATEABBREVIATED, SC.POSTCODELITERAL, SC.ADDRESSSTYLE),"+CHAR(10)+
	"@nBillingAttentionKey=BLN.NAMENO,"+CHAR(10)+
	"@sBillingAttention=dbo.fn_FormatNameUsingNameNo(BLN.NAMENO, NULL),"+CHAR(10)+
	"@nBillingNameKey=RLN1.NAMENO, @sBillingNameCode=RLN1.NAMECODE,"+CHAR(10)+
	"@nBillingSequence = AN1.SEQUENCE,"+CHAR(10)+	
	"@sBillingName=dbo.fn_FormatNameUsingNameNo(RLN1.NAMENO, NULL),"+CHAR(10)+
	"@nBillingAddressKey=BA.ADDRESSCODE,"+CHAR(10)+
	"@sBillingAddress=dbo.fn_FormatAddress(BA.STREET1, BA.STREET2, BA.CITY, BA.STATE, BS.STATENAME, BA.POSTCODE, CASE WHEN BC.COUNTRYCODE = HC.COLCHARACTER
			THEN NULL ELSE BC.POSTALNAME END, BC.POSTCODEFIRST, BC.STATEABBREVIATED, BC.POSTCODELITERAL, BC.ADDRESSSTYLE)"+CHAR(10)+
			
	"from NAME N"+char(10)+	
	-- User must have access to the Billing Instructions topic	
	"left join ASSOCIATEDNAME AN	on (AN.NAMENO = N.NAMENO"+CHAR(10)+
	"				and AN.RELATIONSHIP = 'STM')"+char(10)+
	"left join NAME RLN		on (RLN.NAMENO = AN.RELATEDNAME)"+CHAR(10)+
	"left join COUNTRY RNN	        on (RNN.COUNTRYCODE = RLN.NATIONALITY)"+CHAR(10)+	
	"left join NAME STN		on (STN.NAMENO = AN.CONTACT)"+CHAR(10)+
	"left join COUNTRY SNN	        on (SNN.COUNTRYCODE = STN.NATIONALITY)"+CHAR(10)+
	-- Statement Address details 	
	"left join ADDRESS SA 		on (SA.ADDRESSCODE = AN.POSTALADDRESS)"+CHAR(10)+
	"left join COUNTRY SC		on (SC.COUNTRYCODE = SA.COUNTRYCODE)"+CHAR(10)+
	"left Join STATE SS		on (SS.COUNTRYCODE = SA.COUNTRYCODE"+CHAR(10)+
	" 	           	 	and SS.STATE = SA.STATE)"+CHAR(10)+
	-- Billing Details
	"left join ASSOCIATEDNAME AN1	on (AN1.NAMENO = N.NAMENO and AN1.RELATIONSHIP = 'BIL')"+CHAR(10)+
	"left join NAME RLN1		on (RLN1.NAMENO = AN1.RELATEDNAME)"+CHAR(10)+
	"left join COUNTRY RNN1	        on (RNN1.COUNTRYCODE = RLN1.NATIONALITY)"+CHAR(10)+	
	"left join NAME BLN		on (BLN.NAMENO = AN1.CONTACT)"+CHAR(10)+
	"left join COUNTRY BNN	        on (BNN.COUNTRYCODE = BLN.NATIONALITY)"+CHAR(10)+
	-- Billing Address details 	
	"left join ADDRESS BA 		on (BA.ADDRESSCODE = AN1.POSTALADDRESS)"+CHAR(10)+
	"left join COUNTRY BC		on (BC.COUNTRYCODE = BA.COUNTRYCODE)"+CHAR(10)+
	"left Join STATE BS		on (BS.COUNTRYCODE = BA.COUNTRYCODE"+CHAR(10)+
	" 	           	 	and BS.STATE = BA.STATE)"+CHAR(10)+
	"left join SITECONTROL HC	on (HC.CONTROLID = 'HOMECOUNTRY')"+CHAR(10)+

	"where N.NAMENO = @pnNameKey"+CHAR(10)+	
	"and N.USEDASFLAG&4 = 4"
	exec @nErrorCode=sp_executesql @sSQLString,
			N'@nStatementAttentionKey	int			output,
			@sStatementAttention		nvarchar(254)		output,
			@nStatementNameKey		int			output,
			@sStatementNameCode		nvarchar(10)		output,
			@sStatementName			nvarchar(254)		output,
			@nStatementSequence		int			output,
			@nStatementAddressKey		int			output,
			@sStatementAddress		nvarchar(254)		output,
			@nBillingAttentionKey		int			output,
			@sBillingAttention		nvarchar(254)		output,
			@nBillingNameKey		int			output,
			@sBillingNameCode		nvarchar(10)		output,
			@sBillingName			nvarchar(254)		output,
			@nBillingAddressKey		int			output,
			@sBillingAddress		nvarchar(254)		output,
			@nBillingSequence		int			output,
			@bIsBillingAvailable		bit			output,			
			@pnNameKey			int,
			@pnUserIdentityId		int,
			@sLocalCurrencyCode		nvarchar(3),
			@nLocalDecimalPlaces		tinyint',
			@nStatementAttentionKey		= @nStatementAttentionKey	output,
			@sStatementAttention		= @sStatementAttention		output,
			@nStatementNameKey		= @nStatementNameKey		output,
			@sStatementNameCode		= @sStatementNameCode		output,
			@sStatementName			= @sStatementName		output,
			@nStatementAddressKey		= @nStatementAddressKey		output,
			@sStatementAddress		= @sStatementAddress		output,
			@nStatementSequence		= @nStatementSequence		output,
			@nBillingAttentionKey		= @nBillingAttentionKey		output,
			@sBillingAttention		= @sBillingAttention		output,
			@nBillingNameKey		= @nBillingNameKey		output,
			@sBillingNameCode		= @sBillingNameCode		output,
			@sBillingName			= @sBillingName			output,
			@nBillingAddressKey		= @nBillingAddressKey		output,
			@sBillingAddress		= @sBillingAddress 		output,
			@nBillingSequence		= @nBillingSequence		output,
			@bIsBillingAvailable		= @bIsBillingAvailable		output,			
			@pnNameKey			= @pnNameKey,
			@pnUserIdentityId		= @pnUserIdentityId,
			@sLocalCurrencyCode		= @sLocalCurrencyCode,
			@nLocalDecimalPlaces		= @nLocalDecimalPlaces

			
End

-- Populating Billing Instructions - Swnd Bills To result set 
If @nErrorCode = 0
Begin	
	If @nBillingNameKey is null or @nBillingNameKey = ''
	Begin
		Set @nBillingAttentionKey	= @nAttentionKey
		Set @sBillingAttention		= @sAttention
		Set @nBillingNameKey		= @pnNameKey
		Set @sBillingNameCode		= @sNameCode
		Set @sBillingName		= @sName
		Set @nBillingSequence		= 0
		Set @nBillingAddressKey		= @nAddressKey
		Set @sBillingAddress		= @sAddress	
		    		
	End

	If @nStatementNameKey is null or @nStatementNameKey = ''
	Begin
		Set @nStatementAttentionKey	= @nAttentionKey
		Set @sStatementAttention	= @sAttention
		Set @nStatementNameKey		= @pnNameKey
		Set @sStatementNameCode		= @sNameCode
		Set @sStatementName		= @sName
		Set @nStatementSequence		= 0
		Set @nStatementAddressKey	= @nAddressKey
		Set @sStatementAddress		= @sAddress	
	End
End

If @nErrorCode = 0
Begin
	Set @sSQLSelect =  
		"Select  N.NAMENO as 'NameKey',"+CHAR(10)+ 
		"IP.PURCHASEORDERNO as 'PurchaseOrderNo',"+CHAR(10)+
		"IP.TAXCODE as 'TaxRateCode',"+CHAR(10)+
		dbo.fn_SqlTranslatedColumn('TAXRATES','DESCRIPTION',null,'TR',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'TaxRateDescription',"+CHAR(10)+
		"IP.STATETAXCODE as 'TaxRateCodeProvinicial',"+CHAR(10)+
		dbo.fn_SqlTranslatedColumn('TAXRATES','DESCRIPTION',null,'TRS',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'TaxRateDescriptionProvinicial',"+CHAR(10)+
		"IP.SERVPERFORMEDIN as 'StateCode',"+CHAR(10)+
		dbo.fn_SqlTranslatedColumn('STATE','STATENAME',null,'ST',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'StateName',"+CHAR(10)+
		"IP.CREDITLIMIT as 'CreditLimit',"+CHAR(10)+
		"IP.DEBITCOPIES	as 'AdditionalBillCopies',"+CHAR(10)+
		"CASE WHEN(cast(IP.CONSOLIDATION as int)&1 = 1) THEN Cast(1 as bit) ELSE Cast(0 as bit) END"+CHAR(10)+
		"	as 'HasMultiCaseBills',"+CHAR(10)+
		"CASE WHEN(cast(IP.CONSOLIDATION as int)&2 = 2) THEN Cast(1 as bit) ELSE Cast(0 as bit) END"+CHAR(10)+
		"	as 'HasMultiCaseBillsPerOwner',"+CHAR(10)+
		"CASE WHEN(cast(IP.CONSOLIDATION as int)&4 = 4) THEN Cast(1 as bit) ELSE Cast(0 as bit) END"+CHAR(10)+
		"	as 'HasSameAddressAndAttention',"+CHAR(10)+
		"N.TAXNO	as 'TaxNumber',"+CHAR(10)+
		"IP.CURRENCY	as 'BillCurrencyCode',"+CHAR(10)+
		dbo.fn_SqlTranslatedColumn('CURRENCY','DESCRIPTION',null,'CUR',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'BillCurrency',"+CHAR(10)+
		"@sLocalCurrencyCode as 'LocalCurrencyCode',"+CHAR(10)+
		"@nLocalDecimalPlaces as 'LocalDecimalPlaces',"+CHAR(10)+
		"IP.BILLINGFREQUENCY as 'BillingFrequencyCode',"+CHAR(10)+
		dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'BF',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'BillingFrequencyDescription',"+CHAR(10)+
		"IP.TRADINGTERMS	as 'ReceivableTermDays',"+CHAR(10)+	
		"@nStatementAttentionKey as 'StatementAttentionKey',"+CHAR(10)+
		"@sStatementAttention as 'StatementAttention',"+CHAR(10)+
		"@nStatementNameKey as 'StatementNameKey',"+CHAR(10)+
		"@sStatementNameCode as 'StatementNameCode',"+CHAR(10)+
		"@sStatementName as 'StatementName',"+CHAR(10)+
		"@nStatementSequence as 'StatementSequence',"+CHAR(10)+
		"@nStatementAddressKey as 'StatementAddressKey',"+CHAR(10)+
		"@sStatementAddress as 'StatementAddress',"+CHAR(10)+
		"@nBillingAttentionKey as 'BillingAttentionKey',"+CHAR(10)+
		"@sBillingAttention as 'BillingAttention',"+CHAR(10)+
		"@nBillingNameKey as 'BillingNameKey',"+CHAR(10)+
		"@sBillingNameCode as 'BillingNameCode',"+CHAR(10)+
		"@sBillingName as 'BillingName',"+CHAR(10)+
		"@nBillingSequence as 'BillingSequence',"+CHAR(10)+
		"@nBillingAddressKey as 'BillingAddressKey',"+CHAR(10)+
		"@sBillingAddress as 'BillingAddress',"+CHAR(10)+
		"IP.LOCALCLIENTFLAG as 'IsLocalClient',"+CHAR(10)+
		"IP.DEBTORTYPE as 'DebtorTypeCode',"+CHAR(10)+
		dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'DT',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'DebtorType',"+CHAR(10)+
		"IP.USEDEBTORTYPE as 'UseDebtorTypeCode',"+CHAR(10)+
		dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'UDT',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'UseDebtorType',"+CHAR(10)+
		dbo.fn_SqlTranslatedColumn('EXCHRATESCHEDULE','DESCRIPTION',null,'ERS',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'ExchangeRateSchedule',"+CHAR(10)+
		"IP.EXCHSCHEDULEID as 'ExchangeRateScheduleKey',"+CHAR(10)+
		"ERS.EXCHSCHEDULECODE as 'ExchangeRateScheduleCode',"+CHAR(10)+
		"IP.BADDEBTOR as 'RestrictionActionKey',"+CHAR(10)+
		dbo.fn_SqlTranslatedColumn('DEBTORSTATUS','DEBTORSTATUS',null,'DS',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Restriction',"+CHAR(10)+
		"@bIsMultiTier	as 'IsMultiTierTax',"+CHAR(10)+
		"IP.BILLINGCAP as 'BillingCap',"+CHAR(10)+
		"IP.BILLINGCAPPERIOD as 'BillingCapPeriod',"+CHAR(10)+
		"IP.BILLINGCAPPERIODTYPE as 'PeriodTypeKey',"+CHAR(10)+
		"PT.DESCRIPTION as 'Period',"+CHAR(10)+
		"IP.BILLINGCAPSTARTDATE as 'BillingCapStartDate',"+CHAR(10)+
		"IP.BILLINGCAPRESETFLAG as 'BillingCapResetFlag',"+CHAR(10)+
		"IP.BILLFORMATID as 'BillFormatProfileKey',"+CHAR(10)+
		dbo.fn_SqlTranslatedColumn('FORMATPROFILE','FORMATDESC',null,'FP',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'BillFormatProfile',"+CHAR(10)+
		"IP.BILLMAPPROFILEID as 'BillMapProfileKey',"+CHAR(10)+
		"MP.BILLMAPDESC as 'BillMapProfile',"+CHAR(10)+
		"IP.SEPARATEMARGINFLAG as 'SeparateMarginFlag',"+CHAR(10)+
		"@bRequireExemptTaxNo as 'RequireExemptTaxNo',"+CHAR(10)+
		"cast(N.NAMENO as nvarchar(11)) as 'RowKey'"+CHAR(10)+
	"from NAME N"+char(10)+	
	"left join NAMETEXT NTX		on (NTX.NAMENO = N.NAMENO"+CHAR(10)+
	"				and NTX.TEXTTYPE = 'CB')"+CHAR(10)+
	dbo.fn_SqlTranslationFrom('NAMETEXT',null,'TEXT','NTX',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+ 
	"left join IPNAME IP		on (IP.NAMENO = N.NAMENO)"+CHAR(10)+
	"left join DEBTORSTATUS DS 	on (DS.BADDEBTOR = IP.BADDEBTOR)"+CHAR(10)+
	"left join TAXRATES TR		on (TR.TAXCODE = IP.TAXCODE)"+CHAR(10)+
	"left join TAXRATES TRS		on (TRS.TAXCODE = IP.STATETAXCODE)"+CHAR(10)+
	"left join STATE ST		on (ST.STATE = IP.SERVPERFORMEDIN)"+CHAR(10)+
	"left join TABLECODES BF	on (BF.TABLECODE = IP.BILLINGFREQUENCY"+CHAR(10)+
	"				and BF.TABLETYPE = 75)"+CHAR(10)+	
	"left join CURRENCY CUR		on (CUR.CURRENCY = ISNULL(IP.CURRENCY, @sLocalCurrencyCode))"+CHAR(10)+
	"left join EXCHRATESCHEDULE ERS on (ERS.EXCHSCHEDULEID = IP.EXCHSCHEDULEID)"+CHAR(10)+
	"left join FORMATPROFILE FP	on (FP.FORMATID = IP.BILLFORMATID)"+CHAR(10)+
	"left join BILLMAPPROFILE MP	on (MP.BILLMAPPROFILEID = IP.BILLMAPPROFILEID)"+CHAR(10)+
	"left join TABLECODES DT	on (DT.TABLECODE = IP.DEBTORTYPE)"+CHAR(10)+
	"left join TABLECODES UDT	on (UDT.TABLECODE = IP.USEDEBTORTYPE)"+CHAR(10)+
	"left join TABLECODES PT	on (PT.USERCODE	= IP.BILLINGCAPPERIODTYPE and PT.TABLETYPE = 127)"+CHAR(10)+	
	"where N.NAMENO = @pnNameKey"+CHAR(10)+	
	"and N.USEDASFLAG&4 = 4"

	Set @sSQLString = @sSQLSelect + @sSQLString
	exec @nErrorCode=sp_executesql @sSQLString,
				N'@nStatementAttentionKey	int,
				@sStatementAttention		nvarchar(254),
				@nStatementNameKey		int,
				@sStatementNameCode		nvarchar(10),
				@sStatementName			nvarchar(254),
				@nStatementSequence		int,
				@nStatementAddressKey		int,
				@sStatementAddress		nvarchar(254),
				@nBillingAttentionKey		int,
				@sBillingAttention		nvarchar(254),
				@nBillingNameKey		int,
				@sBillingNameCode		nvarchar(10),
				@sBillingName			nvarchar(254),
				@nBillingSequence		int,
				@nBillingAddressKey		int,
				@sBillingAddress		nvarchar(254),
				@bIsBillingAvailable		bit,				
				@pnNameKey			int,
				@bIsMultiTier			bit,
				@pnUserIdentityId		int,
				@sLocalCurrencyCode		nvarchar(3),
				@nLocalDecimalPlaces		tinyint,
				@bRequireExemptTaxNo		bit',
				@nStatementAttentionKey		= @nStatementAttentionKey,
				@sStatementAttention		= @sStatementAttention,
				@nStatementNameKey		= @nStatementNameKey,
				@sStatementNameCode		= @sStatementNameCode,
				@sStatementName			= @sStatementName,
				@nStatementSequence		= @nStatementSequence,
				@nStatementAddressKey		= @nStatementAddressKey,
				@sStatementAddress		= @sStatementAddress,
				@nBillingAttentionKey		= @nBillingAttentionKey,
				@sBillingAttention		= @sBillingAttention,
				@nBillingNameKey		= @nBillingNameKey,
				@sBillingNameCode		= @sBillingNameCode,
				@sBillingName			= @sBillingName,
				@nBillingSequence		= @nBillingSequence,
				@nBillingAddressKey		= @nBillingAddressKey,
				@sBillingAddress		= @sBillingAddress,
				@bIsBillingAvailable		= @bIsBillingAvailable,				
				@pnNameKey			= @pnNameKey,
				@bIsMultiTier			= @bIsMultiTier,
				@pnUserIdentityId		= @pnUserIdentityId,
				@sLocalCurrencyCode		= @sLocalCurrencyCode,
				@nLocalDecimalPlaces		= @nLocalDecimalPlaces,
				@bRequireExemptTaxNo	 = @bRequireExemptTaxNo

	Set @pnRowCount=@@Rowcount
End		

Return @nErrorCode
GO

Grant execute on dbo.naw_ListBillingInstructionsData to public
GO
