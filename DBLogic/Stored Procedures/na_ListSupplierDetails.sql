-----------------------------------------------------------------------------------------------------------------------------
-- Creation of na_ListSupplierDetails 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_ListSupplierDetails ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.na_ListSupplierDetails .'
	Drop procedure [dbo].[na_ListSupplierDetails ]
	Print '**** Creating Stored Procedure dbo.na_ListSupplierDetails ...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.na_ListSupplierDetails 
(
	@pnRowCount			int		= null output,
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnNameKey 			int,
	@pbCanViewSupplierDetails	bit		= 0,
	@pbCalledFromCentura		bit		= 0,
	@psResultsetsRequired		nvarchar(4000)	= null		-- comma seperated list to describe which resultset to return
)
AS
-- PROCEDURE:	na_ListSupplierDetails 
-- VERSION:	20
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Populates the Supplier and SupplierEntity result sets.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 07 Sep 2004  TM		1	Procedure created
-- 18 Sep 2004	JEK		2	RFC886	Implement translation.
-- 21 Sep 2004	JEK		3	RFC886	Correct syntax error when Suppler topic not available
-- 29 Sep 2004	TM	RFC1806	8	Pass the new parameter and to pass the country postal name instead of the country
--					name to the fn_FormatAddress.		
-- 15 Oct 2004	TM	RFC1158	9	Remove PaymentBEI column from the Supplier result set.
-- 15 May 2005	JEK	RFC2508	10	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 08 Jul 2005	TM	RFC2654	11	Extract Payment and Payment attention details in a separate SQL statement into
--					the local variables using sp_executesql and pass them to the main 'Select'. 
-- 20 Jun 2006	AU	RFC3814	12	Corrected ExpenseAccountCode
-- 05 Jul 2006	AU	RFC3555	13	Add two columns to Supplier result set: ExchangeRateSchedule, ExchangeRateScheduleCode
-- 17 Jul 2006	SW	RFC3828	14	Pass getdate() to fn_Permission..
-- 29 Aug 2006	SF	RFC4214	15	Add RowKey, Add ResultsetsRequired parameter
-- 14 Jun 2011	JC	RFC100151	16	Improve performance by removing fn_GetTopicSecurity: authorisation is now given by the caller
-- 25 Aug 2011  MS	RFC7998 17      Add IsDefaultPaymentAttention and IsDefaultPaymentAddress
-- 11 Apr 2013	DV	R13270	18	Increase the length of nvarchar to 11 when casting or declaring integer
-- 02 Nov 2015	vql	R53910	19	Adjust formatted names logic (DR-15543).
-- 05 May 2020	vql	DR-59405	22	Increase the length of Variables related to Bank Account No and Branch code in Apps.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int

Declare @sSQLString		nvarchar(4000)
Declare @sSQLString2		nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

Declare @nPaymentAttentionKey	int
Declare @sPaymentAttention	nvarchar(254)
Declare @sPaymentAttentionCode	nvarchar(10)
Declare @nPaymentNameKey	int
Declare	@sPaymentName		nvarchar(254)
Declare @sPaymentNameCode	nvarchar(10)
Declare @sPaymentAddress	nvarchar(254)

Declare @bIsDefaultPaymentAttention	bit
Declare @bIsDefaultPaymentAddress	bit

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- add comma at the end so the last field also have a comma when doing charindex later on
-- and strip off spaces.
-- @psResultsetsRequired become ',' if @psResultsetsRequired is originally null
Set	@psResultsetsRequired = upper(replace(isnull(@psResultsetsRequired, ''), ' ', '')) + ','

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

-- Populating Supplier result set
If @nErrorCode = 0
and (   @psResultsetsRequired = ','
or CHARINDEX('SUPPLIER,', @psResultsetsRequired) <> 0)
Begin	
	If @pbCanViewSupplierDetails = 1
	Begin
		-- Extract Payment and Payment attention details in a separate SQL statement into the local
		-- variables using sp_executesql and pass them to the main 'Select' statement:
		Set @sSQLString = 
		"Select top 1  @nPaymentAttentionKey 	= PAY.NAMENO,"+CHAR(10)+
			"@sPaymentAttention	= dbo.fn_FormatNameUsingNameNo(PAY.NAMENO, COALESCE(PAY.NAMESTYLE, PNN.NAMESTYLE, 7101)),"+CHAR(10)+
			"@sPaymentAttentionCode	= PAY.NAMECODE,"+CHAR(10)+
			"@nPaymentNameKey	= RLN1.NAMENO,"+CHAR(10)+
			"@sPaymentName		= dbo.fn_FormatNameUsingNameNo(RLN1.NAMENO, COALESCE(RLN1.NAMESTYLE, RNN1.NAMESTYLE, 7101)),"+CHAR(10)+
			"@sPaymentNameCode	= RLN1.NAMECODE,"+CHAR(10)+
			"@sPaymentAddress	= dbo.fn_FormatAddress(PA.STREET1, PA.STREET2, PA.CITY, PA.STATE, PS.STATENAME, PA.POSTCODE, PB.POSTALNAME, PB.POSTCODEFIRST, PB.STATEABBREVIATED, PB.POSTCODELITERAL, PB.ADDRESSSTYLE),"+CHAR(10)+
			"@bIsDefaultPaymentAttention=CASE WHEN ISNULL(AN1.CONTACT,0)=0 THEN 1 ELSE 0 END,"+CHAR(10)+
			"@bIsDefaultPaymentAddress=CASE WHEN ISNULL(AN1.POSTALADDRESS,0)=0 THEN 1 ELSE 0 END"+CHAR(10)+
		"from  CREDITOR CR"+CHAR(10)+
		-- Extract Payment and Payment attention details:
		"left join ASSOCIATEDNAME AN1	on (AN1.NAMENO = CR.NAMENO"+CHAR(10)+
		"				and AN1.RELATIONSHIP = 'PAY')"+CHAR(10)+
		"left join NAME RLN1		on (RLN1.NAMENO = AN1.RELATEDNAME)"+CHAR(10)+
		"left join COUNTRY RNN1	        on (RNN1.COUNTRYCODE = RLN1.NATIONALITY)"+CHAR(10)+
		"left join NAME PAY		on (PAY.NAMENO = ISNULL(AN1.CONTACT, RLN1.MAINCONTACT))"+CHAR(10)+
		"left join COUNTRY PNN	        on (PNN.COUNTRYCODE = PAY.NATIONALITY)"+CHAR(10)+
		"left join ADDRESS PA 		on (PA.ADDRESSCODE = ISNULL(AN1.POSTALADDRESS, RLN1.POSTALADDRESS))"+CHAR(10)+
		"left join COUNTRY PB		on (PB.COUNTRYCODE = PA.COUNTRYCODE)"+CHAR(10)+
		"left Join STATE PS		on (PS.COUNTRYCODE = PA.COUNTRYCODE"+CHAR(10)+
		" 	           	 	and PS.STATE = PA.STATE)"+CHAR(10)+
		"where CR.NAMENO = @pnNameKey"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@nPaymentAttentionKey		int			output,
					  @sPaymentAttention		nvarchar(254)		output,
					  @sPaymentAttentionCode	nvarchar(10)		output,
				    	  @nPaymentNameKey		int			output,
					  @sPaymentName			nvarchar(254) 		output,
					  @sPaymentNameCode		nvarchar(10)		output,
					  @sPaymentAddress		nvarchar(254) 		output,
					  @bIsDefaultPaymentAttention   bit                     output,
					  @bIsDefaultPaymentAddress     bit                     output,
					  @pnNameKey			int',
					  @nPaymentAttentionKey		= @nPaymentAttentionKey	output,
					  @sPaymentAttention		= @sPaymentAttention	output,
					  @sPaymentAttentionCode	= @sPaymentAttentionCode output,
					  @nPaymentNameKey		= @nPaymentNameKey	output,
					  @sPaymentName			= @sPaymentName		output,
					  @sPaymentNameCode		= @sPaymentNameCode	output,
					  @sPaymentAddress		= @sPaymentAddress	output,
					  @bIsDefaultPaymentAttention   = @bIsDefaultPaymentAttention   output,
					  @bIsDefaultPaymentAddress     = @bIsDefaultPaymentAddress     output,
					  @pnNameKey			= @pnNameKey
	End

	If @nErrorCode=0
	Begin
		Set @sSQLString = "
		Select 	CR.NAMENO		as 'NameKey',"+CHAR(10)+
		"	"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TS',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
					+ " as 'SupplierType',"+CHAR(10)+
		"	"+dbo.fn_SqlTranslatedColumn('CRRESTRICTION','CRRESTRICTIONDESC',null,'RST',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
					+ " as 'Restriction',	"+CHAR(10)+
		"	RST.ACTIONFLAG		as 'RestrictionActionKey',"+CHAR(10)+
		"	"+dbo.fn_SqlTranslatedColumn('REASON','DESCRIPTION',null,'R',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
					+ " as 'RestrictionReason',"+CHAR(10)+
		"	CR.PURCHASEDESC		as 'PurchaseDescription',"+CHAR(10)+
		"	"+dbo.fn_SqlTranslatedColumn('CURRENCY','DESCRIPTION',null,'CUR',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
					+ " as 'PurchaseCurrency',"+CHAR(10)+
		"	"+dbo.fn_SqlTranslatedColumn('EXCHRATESCHEDULE','DESCRIPTION',null,'ERS',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
					+ " as 'ExchangeRateSchedule',"+CHAR(10)+
		"	ERS.EXCHSCHEDULECODE 	as 'ExchangeRateScheduleCode',"+CHAR(10)+
		"	"+dbo.fn_SqlTranslatedColumn('TAXRATES','DESCRIPTION',null,'TXR',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
					+ " as 'DefaultTaxTreatment',"+CHAR(10)+
		"	"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TX',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
					+ " as 'PurchaseTaxTreatment',"+CHAR(10)+
		"	"+dbo.fn_SqlTranslatedColumn('FREQUENCY','DESCRIPTION',null,'FR',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
					+ " as 'PaymentTerms',"+CHAR(10)+
		"	CR.PROFITCENTRE		as 'ProfitCentreCode',"+CHAR(10)+
		"	"+dbo.fn_SqlTranslatedColumn('PROFITCENTRE','DESCRIPTION',null,'PC',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
					+ " as 'ProfitCentre',"+CHAR(10)+
		"	LA.ACCOUNTCODE 		as 'ExpenseAccountCode',"+CHAR(10)+
		"	LA.DESCRIPTION		as 'ExpenseAccount',"+CHAR(10)+
		"	"+dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'WT',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
					+ " as 'WIPDisbursement',"+CHAR(10)+
		"	@nPaymentAttentionKey	as 'PaymentAttentionKey',"+CHAR(10)+	
		"	@sPaymentAttention	as 'PaymentAttention',"+CHAR(10)+
		"	@sPaymentAttentionCode	as 'PaymentAttentionCode',"+CHAR(10)+
		"	@nPaymentNameKey	as 'PaymentNameKey',"+CHAR(10)+
		"	@sPaymentName		as 'PaymentName',"+CHAR(10)+
		"	@sPaymentNameCode	as 'PaymentNameCode',"+CHAR(10)+
		"	@sPaymentAddress	as 'PaymentAddress',"+CHAR(10)+
		"       @bIsDefaultPaymentAttention as 'IsDefaultPaymentAttention',"+CHAR(10)+
		"       @bIsDefaultPaymentAddress   as 'IsDefaultPaymentAddress',"+CHAR(10)+    
		"	"+dbo.fn_SqlTranslatedColumn('CREDITOR','INSTRUCTIONS',null,'CR',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
					+ " as 'Instructions',"+CHAR(10)+
		"	"+dbo.fn_SqlTranslatedColumn('PAYMENTMETHODS','PAYMENTDESCRIPTION',null,'PM',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
					+ " as 'PaymentMethod',"+CHAR(10)+
		"	CR.CHEQUEPAYEE		as 'ChequePayee',"+CHAR(10)+
		"	ISNULL(cast(BA.IBAN as nvarchar(50)), BA.ACCOUNTNO)"+CHAR(10)+
		"				as 'PayToBankAccountCode',"+CHAR(10)+
		"	BA.DESCRIPTION 		as 'PayToBankAccount',"+CHAR(10)+
		"	cast(CR.NAMENO as nvarchar(11))		as 'RowKey'"+CHAR(10)+
		"from  CREDITOR CR"+CHAR(10)+
		"join TABLECODES TS		on (TS.TABLECODE = CR.SUPPLIERTYPE)"+CHAR(10)+
		"left join CRRESTRICTION RST 	on (RST.CRRESTRICTIONID = CR.RESTRICTIONID)"+CHAR(10)+
		"left join REASON R		on (R.REASONCODE = CR.RESTNREASONCODE)"+CHAR(10)+
		"left join CURRENCY CUR		on (CUR.CURRENCY = CR.PURCHASECURRENCY)"+CHAR(10)+
		"left join TAXRATES TXR		on (TXR.TAXCODE = CR.DEFAULTTAXCODE)"+CHAR(10)+
		"left join TABLECODES TX		on (TX.TABLECODE = CR.TAXTREATMENT)"+CHAR(10)+
		"left join FREQUENCY FR		on (FR.FREQUENCYNO = CR.PAYMENTTERMNO)"+CHAR(10)+
		"left join PROFITCENTRE PC	on (PC.PROFITCENTRECODE = CR.PROFITCENTRE)"+CHAR(10)+
		"left join LEDGERACCOUNT LA	on (LA.ACCOUNTID = CR.EXPENSEACCOUNT)"+CHAR(10)+
		"left join WIPTEMPLATE WT	on (WT.WIPCODE = CR.DISBWIPCODE)"+CHAR(10)+	
		"left join PAYMENTMETHODS PM	on (PM.PAYMENTMETHOD = CR.PAYMENTMETHOD)"+CHAR(10)+
		"left join BANKACCOUNT BA	on (BA.ACCOUNTOWNER = CR.BANKACCOUNTOWNER"+CHAR(10)+
		"				and BA.BANKNAMENO = CR.BANKNAMENO"+CHAR(10)+
		"				and BA.SEQUENCENO = CR.BANKSEQUENCENO)"+CHAR(10)+
		"left join EXCHRATESCHEDULE ERS on (ERS.EXCHSCHEDULEID = CR.EXCHSCHEDULEID)"+CHAR(10)+
		"where CR.NAMENO = @pnNameKey"+CHAR(10)+
		"and isnull(@pbCanViewSupplierDetails,0) = 1"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nPaymentAttentionKey		int,
						  @sPaymentAttention		nvarchar(254),
						  @sPaymentAttentionCode	nvarchar(10),
					    	  @nPaymentNameKey		int,
						  @sPaymentName			nvarchar(254),
						  @sPaymentNameCode		nvarchar(10),
						  @sPaymentAddress		nvarchar(254),
						  @pnNameKey			int,
						  @bIsDefaultPaymentAttention   bit,
						  @bIsDefaultPaymentAddress     bit,
						  @pbCanViewSupplierDetails	bit',
						  @nPaymentAttentionKey		= @nPaymentAttentionKey,
						  @sPaymentAttention		= @sPaymentAttention,
						  @sPaymentAttentionCode	= @sPaymentAttentionCode,
						  @nPaymentNameKey		= @nPaymentNameKey,
						  @sPaymentName			= @sPaymentName,
						  @sPaymentNameCode		= @sPaymentNameCode,
						  @sPaymentAddress		= @sPaymentAddress,
						  @pnNameKey			= @pnNameKey,
						  @bIsDefaultPaymentAttention   = @bIsDefaultPaymentAttention,
						  @bIsDefaultPaymentAddress     = @bIsDefaultPaymentAddress,
						  @pbCanViewSupplierDetails	= @pbCanViewSupplierDetails
	End
End

-- Populating SupplierEntity result set
If @nErrorCode = 0
and (   @psResultsetsRequired = ','
     or CHARINDEX('SUPPLIERENTITY,', @psResultsetsRequired) <> 0)
Begin	
	Set @sSQLString = "
	Select 	CRE.NAMENO		as 'NameKey',
		CRE.ENTITYNAMENO	as 'EntityNameKey',	
		N.NAMECODE		as 'EntityNameCode',
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
					as 'EntityName',
		CRE.SUPPLIERACCOUNTNO	as 'SupplierAccountNo',
		ISNULL(cast (BA.IBAN as nvarchar(50)), BA.ACCOUNTNO)
					as 'PayFromBankAccountCode',
		BA.DESCRIPTION 		as 'PayFromBankAccount',
		CAST(CRE.NAMENO as nvarchar(11)) + '^' + CAST(CRE.ENTITYNAMENO as nvarchar(11))
					as 'RowKey'
	from CRENTITYDETAIL CRE
	join NAME N 		on (N.NAMENO = CRE.ENTITYNAMENO)	
	join BANKACCOUNT BA	on (BA.ACCOUNTOWNER = CRE.ENTITYNAMENO
				and BA.BANKNAMENO = CRE.BANKNAMENO
				and BA.SEQUENCENO = CRE.SEQUENCENO)
	where CRE.NAMENO = @pnNameKey
	and @pbCanViewSupplierDetails = 1
	order by 'EntityName'"

	exec sp_executesql @sSQLString,
				N'@pnNameKey			int,
				  @pbCanViewSupplierDetails	bit',
				  @pnNameKey			= @pnNameKey,
				  @pbCanViewSupplierDetails	= @pbCanViewSupplierDetails

	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.na_ListSupplierDetails  to public
GO
