-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_FetchSupplier
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_FetchSupplier]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_FetchSupplier.'
	Drop procedure [dbo].[naw_FetchSupplier]
End
Print '**** Creating Stored Procedure dbo.naw_FetchSupplier...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_FetchSupplier
(
	@pnRowCount		int		= null          output,	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int,		-- Mandatory
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	naw_FetchSupplier
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populates the SupplierEntity of NameEntity dataset

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 Jun 2011	MS	RFC7998	1	Procedure created
-- 11 Apr 2013	DV	R13270	2	Increase the length of nvarchar to 11 when casting or declaring integer 
-- 02 Nov 2015	vql	R53910	3	Adjust formatted names logic (DR-15543).


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		        int
Declare @sSQLString		        nvarchar(max)
Declare @sLookupCulture		        nvarchar(10)

Declare @nPaymentAttentionKey	        int
Declare @sPaymentAttention	        nvarchar(254)
Declare @sPaymentAttentionCode	        nvarchar(10)
Declare @nPaymentNameKey	        int
Declare	@sPaymentName		        nvarchar(254)
Declare @sPaymentNameCode	        nvarchar(10)
Declare @sPaymentAddress	        nvarchar(254)
Declare @sPaymentAddressCode            int
Declare @nPaymentNameSequence           int
Declare @dtToday		        datetime

Declare @sNameCode			nvarchar(10)
Declare @sName				nvarchar(254)
Declare @nAttentionKey			int
Declare @sAttention			nvarchar(254)
Declare @nAddressKey			int
Declare @sAddress			nvarchar(254)
Declare @sCountryKey			nvarchar(3)
Declare @bIsIndividual                  bit
Declare @bIsPaymentNameIndividual       bit

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
set @dtToday = getdate()

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

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
                @bIsIndividual  = cast((isnull(N.USEDASFLAG, 0) & 1) as bit),
		@nAttentionKey	= N.MAINCONTACT,
		@sAttention	= dbo.fn_FormatNameUsingNameNo(AN.NAMENO, NULL), 
		@nAddressKey	= A.ADDRESSCODE,
		@sAddress	= dbo.fn_FormatAddress(A.STREET1, A.STREET2, A.CITY, A.STATE, S.STATENAME, A.POSTCODE, 
			CASE WHEN C.COUNTRYCODE = @sCountryKey 
			THEN NULL ELSE C.POSTALNAME END, C.POSTCODEFIRST, C.STATEABBREVIATED, C.POSTCODELITERAL, C.ADDRESSSTYLE)		
	from NAME N	
	left join NAME AN   on (AN.NAMENO     = N.MAINCONTACT)
	left join ADDRESS A on (A.ADDRESSCODE = N.POSTALADDRESS)
	left join COUNTRY C on (C.COUNTRYCODE = A.COUNTRYCODE)
	left Join STATE S   on (S.COUNTRYCODE = A.COUNTRYCODE and S.STATE = A.STATE)	
	where N.NAMENO = @pnNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@sNameCode		nvarchar(10)	        output,
				  @sName		nvarchar(254)	        output,
                                  @bIsIndividual        bit                     output,
				  @nAttentionKey	int		        output,
				  @sAttention		nvarchar(254)	        output,
				  @nAddressKey		int		        output,
				  @sAddress		nvarchar(254)	        output,
				  @sCountryKey		nvarchar(3),				  	
				  @pnNameKey		int',
				  @sNameCode		= @sNameCode	        output,
				  @sName		= @sName	        output,
                                  @bIsIndividual        = @bIsIndividual        output,
				  @nAttentionKey	= @nAttentionKey        output,
				  @sAttention		= @sAttention	        output,
				  @nAddressKey		= @nAddressKey	        output,
				  @sAddress		= @sAddress	        output,	
				  @sCountryKey		= @sCountryKey,			 
				  @pnNameKey		= @pnNameKey
End

-- Populating Supplier result set
If @nErrorCode = 0 
Begin		
	-- Extract Payment and Payment attention details in a separate SQL statement into the local
	-- variables using sp_executesql and pass them to the main 'Select' statement:
	Set @sSQLString = 
	"Select top 1  
                @nPaymentAttentionKey 	= PAY.NAMENO,                
		@sPaymentAttention	= dbo.fn_FormatNameUsingNameNo(PAY.NAMENO, null),
		@sPaymentAttentionCode	= PAY.NAMECODE,
		@nPaymentNameKey	= RLN1.NAMENO,
		@sPaymentName		= dbo.fn_FormatNameUsingNameNo(RLN1.NAMENO, null),
		@sPaymentNameCode	= RLN1.NAMECODE,
                @nPaymentNameSequence   = AN1.SEQUENCE,
                @bIsPaymentNameIndividual = cast((isnull(RLN1.USEDASFLAG, 0) & 1) as bit),
		@sPaymentAddressCode	= PA.ADDRESSCODE,
		@sPaymentAddress	= dbo.fn_FormatAddress(PA.STREET1, PA.STREET2, PA.CITY, PA.STATE, PS.STATENAME, PA.POSTCODE, PB.POSTALNAME, PB.POSTCODEFIRST, PB.STATEABBREVIATED, PB.POSTCODELITERAL, PB.ADDRESSSTYLE)
	from  CREDITOR CR
	-- Extract Payment and Payment attention details:
	left join ASSOCIATEDNAME AN1	on (AN1.NAMENO = CR.NAMENO
					and AN1.RELATIONSHIP = 'PAY')
	left join NAME RLN1		on (RLN1.NAMENO = AN1.RELATEDNAME)
	left join COUNTRY RNN1	        on (RNN1.COUNTRYCODE = RLN1.NATIONALITY)
	left join NAME PAY		on (PAY.NAMENO = AN1.CONTACT)
	left join COUNTRY PNN	        on (PNN.COUNTRYCODE = PAY.NATIONALITY)
	left join ADDRESS PA 		on (PA.ADDRESSCODE = AN1.POSTALADDRESS)
	left join COUNTRY PB		on (PB.COUNTRYCODE = PA.COUNTRYCODE)
	left Join STATE PS		on (PS.COUNTRYCODE = PA.COUNTRYCODE
	 	           	 	and PS.STATE = PA.STATE)
	where CR.NAMENO = @pnNameKey" 

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@nPaymentAttentionKey		int			        output,
				  @sPaymentAttention		nvarchar(254)		        output,
				  @sPaymentAttentionCode	nvarchar(10)		        output,
			          @nPaymentNameKey		int			        output,
				  @sPaymentName			nvarchar(254) 		        output,
				  @sPaymentNameCode		nvarchar(10)		        output,
                                  @bIsPaymentNameIndividual     bit                             output,
				  @sPaymentAddress		nvarchar(254) 		        output,
				  @sPaymentAddressCode	        int 		                output,
                                  @nPaymentNameSequence         int                             output,
				  @pnNameKey			int',
				  @nPaymentAttentionKey		= @nPaymentAttentionKey	        output,
				  @sPaymentAttention		= @sPaymentAttention	        output,
				  @sPaymentAttentionCode	= @sPaymentAttentionCode        output,
				  @nPaymentNameKey		= @nPaymentNameKey	        output,
				  @sPaymentName			= @sPaymentName		        output,
				  @sPaymentNameCode		= @sPaymentNameCode	        output,
                                  @bIsPaymentNameIndividual     = @bIsPaymentNameIndividual     output,
				  @sPaymentAddress		= @sPaymentAddress	        output,
				  @sPaymentAddressCode          = @sPaymentAddressCode          output,
                                  @nPaymentNameSequence         = @nPaymentNameSequence         output,
				  @pnNameKey			= @pnNameKey
End

-- Populating Supplier - Send Payments To result set 
If @nErrorCode = 0 and @nPaymentNameKey is null
Begin
	Set @nPaymentAttentionKey	= @nAttentionKey
	Set @sPaymentAttention		= @sAttention        
	Set @nPaymentNameKey		= @pnNameKey
	Set @sPaymentNameCode		= @sNameCode
	Set @sPaymentName		= @sName
        Set @nPaymentNameSequence       = 0	
	Set @sPaymentAddressCode	= @nAddressKey
	Set @sPaymentAddress		= @sAddress
        Set @bIsPaymentNameIndividual   = @bIsIndividual
End

If @nErrorCode=0
Begin
	Set @sSQLString = "
	Select 	CR.NAMENO	as 'NameKey',"+CHAR(10)+ 
        "@sNameCode             as 'NameCode',"+CHAR(10)+
        "@sName                 as 'DisplayName',"+CHAR(10)+
        "@nAttentionKey         as 'DefaultAttentionKey',"+CHAR(10)+       
        "@nAddressKey           as 'DefaultAddressKey',"+CHAR(10)+      
	"cast(CR.NAMENO as nvarchar(11)) as 'RowKey',"+CHAR(10)+
        "CR.SUPPLIERTYPE        as 'SupplierTypeKey',"+CHAR(10)+
	+ dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TS',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
				+ " as 'SupplierType',"+CHAR(10)+
        "CR.RESTRICTIONID       as 'RestrictionKey',"+CHAR(10)+
	+ dbo.fn_SqlTranslatedColumn('CRRESTRICTION','CRRESTRICTIONDESC',null,'RST',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
				+ " as 'Restriction',	"+CHAR(10)+
	"RST.ACTIONFLAG		as 'RestrictionActionKey',"+CHAR(10)+
        + dbo.fn_SqlTranslatedColumn('REASON','DESCRIPTION',null,'R',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
				+ " as 'RestrictionReason',"+CHAR(10)+
	"R.REASONCODE		as 'RestrictionReasonKey',"+CHAR(10)+
	"CR.PURCHASEDESC	as 'PurchaseDescription',"+CHAR(10)+
	"CUR.CURRENCY		as 'PurchaseCurrencyCode',"+CHAR(10)+
	+ dbo.fn_SqlTranslatedColumn('CURRENCY','DESCRIPTION',null,'CUR',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
				+ " as 'PurchaseCurrency',"+CHAR(10)+
	+ dbo.fn_SqlTranslatedColumn('EXCHRATESCHEDULE','DESCRIPTION',null,'ERS',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
				+ " as 'ExchangeRateSchedule',"+CHAR(10)+
	"ERS.EXCHSCHEDULEID 	as 'ExchangeRateScheduleCode',"+CHAR(10)+
	"TXR.TAXCODE		as 'DefaultTaxTreatmentCode',"+CHAR(10)+
	+ dbo.fn_SqlTranslatedColumn('TAXRATES','DESCRIPTION',null,'TXR',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
				+ " as 'DefaultTaxTreatment',"+CHAR(10)+
	"TX.TABLECODE		as 'PurchaseTaxTreatmentCode',"+CHAR(10)+
	+ dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TX',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
				+ " as 'PurchaseTaxTreatment',"+CHAR(10)+
	"FR.FREQUENCYNO		as 'PaymentTermsCode',"+CHAR(10)+
	+ dbo.fn_SqlTranslatedColumn('FREQUENCY','DESCRIPTION',null,'FR',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
				+ " as 'PaymentTerms',"+CHAR(10)+
	"CR.PROFITCENTRE	as 'ProfitCentreCode',"+CHAR(10)+
	+ dbo.fn_SqlTranslatedColumn('PROFITCENTRE','DESCRIPTION',null,'PC',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
				+ " as 'ProfitCentre',"+CHAR(10)+
        "LA.ACCOUNTID   	as 'ExpenseAccountKey',"+CHAR(10)+
	"LA.ACCOUNTCODE 	as 'ExpenseAccountCode',"+CHAR(10)+
	"LA.DESCRIPTION		as 'ExpenseAccount',"+CHAR(10)+
        "CR.DISBWIPCODE		as 'WIPDisbursementCode',"+CHAR(10)+
	+ dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'WT',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
				+ " as 'WIPDisbursement',"+CHAR(10)+
	"@nPaymentAttentionKey	as 'PaymentAttentionKey',"+CHAR(10)+	
	"@sPaymentAttention	as 'PaymentAttention',"+CHAR(10)+
	"@sPaymentAttentionCode	as 'PaymentAttentionCode',"+CHAR(10)+
	"@nPaymentNameKey	as 'PaymentNameKey',"+CHAR(10)+
	"@sPaymentName		as 'PaymentName',"+CHAR(10)+
	"@sPaymentNameCode	as 'PaymentNameCode',"+CHAR(10)+
	"@sPaymentAddress	as 'PaymentAddress',"+CHAR(10)+
	"@sPaymentAddressCode	as 'PaymentAddressCode',"+CHAR(10)+
        "@nPaymentNameSequence  as 'PaymentNameSequence',"+CHAR(10)+
        "@bIsPaymentNameIndividual      as 'IsIndividual',"+CHAR(10)+	
	+ dbo.fn_SqlTranslatedColumn('CREDITOR','INSTRUCTIONS',null,'CR',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
				+ " as 'Instructions',"+CHAR(10)+
        "CR.PAYMENTMETHOD       as 'PaymentMethodCode',"+CHAR(10)+
	+ dbo.fn_SqlTranslatedColumn('PAYMENTMETHODS','PAYMENTDESCRIPTION',null,'PM',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
				+ " as 'PaymentMethod',"+CHAR(10)+
	"CR.CHEQUEPAYEE		as 'ChequePayee',"+CHAR(10)+
        "CR.BANKNAME            as 'BankName',"+CHAR(10)+
        "CR.BANKBRANCHNO        as 'BankBranchNo',"+CHAR(10)+
        "CR.BANKACCOUNTNO       as 'BankAccountNo',"+CHAR(10)+
        "CR.BANKACCOUNTNAME     as 'BankAccountName',"+CHAR(10)+
        "CR.BANKACCOUNTOWNER    as 'BankAccountOwner',"+CHAR(10)+
        "CR.BANKNAMENO          as 'BankNameKey',"+CHAR(10)+
        "CR.BANKSEQUENCENO      as 'BankSeqNo',"+CHAR(10)+        
	"CASE WHEN BA.ACCOUNTOWNER is not null 
                then cast(BA.ACCOUNTOWNER as nvarchar(10)) + '^' + cast(BA.BANKNAMENO as nvarchar(10)) + '^' + cast(BA.SEQUENCENO as nvarchar(10))
                else null end   as 'PayToBankAccountCode',"+CHAR(10)+
	"BA.DESCRIPTION 	as 'PayToBankAccount',"+CHAR(10)+
        "CR.LOGDATETIMESTAMP    as 'LogDateTimeStamp'"+CHAR(10)+
	"from  CREDITOR CR"+CHAR(10)+        
	"join TABLECODES TS		on (TS.TABLECODE = CR.SUPPLIERTYPE)"+CHAR(10)+
	"left join CRRESTRICTION RST 	on (RST.CRRESTRICTIONID = CR.RESTRICTIONID)"+CHAR(10)+
	"left join REASON R		on (R.REASONCODE = CR.RESTNREASONCODE)"+CHAR(10)+
	"left join CURRENCY CUR		on (CUR.CURRENCY = CR.PURCHASECURRENCY)"+CHAR(10)+
	"left join TAXRATES TXR		on (TXR.TAXCODE = CR.DEFAULTTAXCODE)"+CHAR(10)+
	"left join TABLECODES TX	on (TX.TABLECODE = CR.TAXTREATMENT)"+CHAR(10)+
	"left join FREQUENCY FR		on (FR.FREQUENCYNO = CR.PAYMENTTERMNO)"+CHAR(10)+
	"left join PROFITCENTRE PC	on (PC.PROFITCENTRECODE = CR.PROFITCENTRE)"+CHAR(10)+
	"left join LEDGERACCOUNT LA	on (LA.ACCOUNTID = CR.EXPENSEACCOUNT)"+CHAR(10)+
	"left join WIPTEMPLATE WT	on (WT.WIPCODE = CR.DISBWIPCODE)"+CHAR(10)+	
	"left join PAYMENTMETHODS PM	on (PM.PAYMENTMETHOD = CR.PAYMENTMETHOD)"+CHAR(10)+
	"left join BANKACCOUNT BA	on (BA.ACCOUNTOWNER = CR.BANKACCOUNTOWNER"+CHAR(10)+
	"				and BA.BANKNAMENO = CR.BANKNAMENO"+CHAR(10)+
	"				and BA.SEQUENCENO = CR.BANKSEQUENCENO)"+CHAR(10)+
	"left join EXCHRATESCHEDULE ERS on (ERS.EXCHSCHEDULEID = CR.EXCHSCHEDULEID)"+CHAR(10)+
	"where CR.NAMENO = @pnNameKey"


        exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey			int,
                                          @sNameCode                    nvarchar(10), 
                                          @sName                        nvarchar(254),
                                          @nAttentionKey                int,
                                          @nAddressKey                  int,
                                          @nPaymentAttentionKey		int,
					  @sPaymentAttention		nvarchar(254),
					  @sPaymentAttentionCode	nvarchar(10),
				          @nPaymentNameKey		int,
					  @sPaymentName			nvarchar(254),
					  @sPaymentNameCode		nvarchar(10),
					  @sPaymentAddress		nvarchar(254),
					  @sPaymentAddressCode		int,
                                          @nPaymentNameSequence         int,
                                          @bIsPaymentNameIndividual     bit',
                                          @pnNameKey			= @pnNameKey,
                                          @sNameCode                    = @sNameCode,
                                          @sName                        = @sName,
                                          @nAttentionKey                = @nAttentionKey,
                                          @nAddressKey                  = @nAddressKey,
					  @nPaymentAttentionKey		= @nPaymentAttentionKey,
					  @sPaymentAttention		= @sPaymentAttention,
					  @sPaymentAttentionCode	= @sPaymentAttentionCode,
					  @nPaymentNameKey		= @nPaymentNameKey,
					  @sPaymentName			= @sPaymentName,
					  @sPaymentNameCode		= @sPaymentNameCode,
					  @sPaymentAddress		= @sPaymentAddress,
					  @sPaymentAddressCode          = @sPaymentAddressCode,
                                          @nPaymentNameSequence         = @nPaymentNameSequence,
                                          @bIsPaymentNameIndividual     = @bIsPaymentNameIndividual
End


Return @nErrorCode
GO

Grant execute on dbo.naw_FetchSupplier to public
GO
