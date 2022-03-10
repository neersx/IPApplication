-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.na_ListBillingInstructions
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_ListBillingInstructions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.na_ListBillingInstructions.'
	Drop procedure [dbo].[na_ListBillingInstructions]
	Print '**** Creating Stored Procedure dbo.na_ListBillingInstructions...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.na_ListBillingInstructions
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int,		-- Mandatory
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	na_ListBillingInstructions
-- VERSION:	33
-- SCOPE:	Client WorkBench
-- DESCRIPTION:	Populates BillingInstructions dataset. 

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 09-Sep-2003  TM		1	Procedure created
-- 16-Sep-2003  TM 		2       Format Names as for presentation on an envelope. Replace
--					"and FN.USEDASFLAG = 4" with "and FN.USEDASFLAG&4 = 4".
-- 19-Sep-2003	JEK		3	NameKey should be returned whether the name is the debtor or not.
-- 10-Oct-2003	MF	RFC519	4	Performance improvements to fn_FilterUserCases & fn_FilterUserNames
-- 06-Dec-2003	JEK	RFC406	5	Topic level security
-- 10-Dec-2003	JEK	RFC720	6	Statement address should not be shown if there is no AssociatedName
-- 17-Dec-2003	TM	RFC621	7	Return the CreditLimit for internal users only.
-- 27-Jan-2004	TM	RFC879	8	Add a LocalCurrencyCode - for use in presentation of Credit Limit.
-- 19-Feb-2004	TM	RFC976	9	Add the @pbCalledFromCentura  = default parameter to the calling code 
--					for relevant functions.
-- 07-Apr-2004	TM	RFC1220	10	Obtain the Correspondence Instructions from the Billing specific instructions 
--					and if not found the (Default) instructions.
-- 06-Sep-2004	TM	RFC1158	11	Add new columns: IsLocalClient, DebtorType, UseDebtorType.
-- 13-Sep-2004	TM	RFC1158	12	Only implement the extra joins for DebtorType and UseDebtorType for internal 
--					users.
-- 16 Sep 2004	JEK	RFC886	13	Implement translation.
-- 29 Sep 2004	TM	RFC1806	14	Pass the new parameter and to pass the country postal name instead of the country
--					name to the fn_FormatAddress.		
-- 15 May 2005	JEK	RFC2508	15	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 06 Jul 2005	TM	RFC2654	16	Improve performance by using sp_executesql instead of exec.
-- 25 Nov 2005	LP	RFC1017	17	Extract @nCurrencyDecimalPlaces and @sCurrencyCode from 
--					ac_GetLocalCurrencyDetails and add to the Billing Instructions result set
-- 12 Dec 2005	LP	RFC1017	18	Fix null LocalCurrencyCode and LocalDecimalPlaces bug
-- 05 Jul 2006	AU	RFC3555	19	Add new columns: ExchangeRateSchedule, ExchangeRateScheduleCode
-- 17 Jul 2006	SW	RFC3828	20	Pass getdate() to fn_Permission..
-- 11 Sept 2006	SF	RFC4214	21	Add RowKey, and move logic from cwb_ListClientNameDetails regarding View Name Key to here. 
-- 13 Sept 2006 SF	RFC4394	22	Fix syntax error where @sLookupCulture should've been used instead of @psCulture
-- 15 Jan 2008	Dw	SQA9782	23	Tax No moved from Organisation to Name table.
-- 10 Sep 2009  MS	RFC8288 24	Added Restrcition and HasSameAddressAndAttention values in select query
-- 03 Feb 2010	MS	RFC7274	25	Billing Cap and Billing Cap period fields added in select query
-- 17 Mar 2010	MS	RFC7280	26	Bill Format Profile field added in select query
-- 23 Jun 2010	MS	RFC7269	27	Return Margin As Sepearte WIP Item column from IPNAME
-- 30 Jun 2010	MS	RFC7274	28	Billing Cap Start Date and Reset Flag fields added in select query
-- 09 Jul 2010	AT	RFC7278	29	Return Bill Map Profile
-- 11 Apr 2013	DV	R13270	30	Increase the length of nvarchar to 11 when casting or declaring integer 
-- 15-May-2013	SF	R13490	31	4000 characters not enough when translation is turned on.
-- 02 Nov 2015	vql	R53910	32	Adjust formatted names logic (DR-15543).
-- 26-May-2016	DV	R61454	33	Return Statement details even if there is billing data in the Associated Name

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @sSQLSelect 		nvarchar(max)
Declare @sSQLString		nvarchar(max)
Declare @sSelect		nvarchar(max)

Declare @bBillingData 		bit -- flags what information should be returned 
Declare @bIsExternalUser	bit -- indicates if user is external

Declare @nErrorCode		int

Declare @sLookupCulture		nvarchar(10)

Declare @nStatementAttentionKey	int
Declare @sStatementAttention	nvarchar(254)
Declare @nStatementNameKey	int
Declare @sStatementName		nvarchar(254)
Declare @sStatementAddress	nvarchar(254)
Declare @nBillingAttentionKey	int
Declare @sBillingAttention	nvarchar(254)
Declare @nBillingNameKey	int
Declare @sBillingName		nvarchar(254)
Declare @sBillingAddress	nvarchar(254)
Declare @bIsBillingAvailable	bit
Declare @bIsNameAvailable	bit
Declare @nViewNameKey		int

Declare @bIsDefaultBillingAttention	bit
Declare @bIsDefaultBillingAddress	bit
Declare @bIsDefaultStatementAttention	bit
Declare @bIsDefaultStatementAddress	bit
Declare @bIsMultiTier			bit

Declare @sLocalCurrencyCode		nvarchar(3)
Declare @nLocalDecimalPlaces		tinyint
Declare @dtToday			datetime

Set 	@nErrorCode		= 0
Set 	@pnRowCount		= 0
Set	@dtToday		= getdate()

-- Retrieve Local Currency information
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= @pbCalledFromCentura
End

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- We need to determine if the user is external 

If @nErrorCode=0
Begin
	Set @sSQLString="
	Select	@bIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser		bit	OUTPUT,
				  @pnUserIdentityId		int',
				  @bIsExternalUser=@bIsExternalUser	OUTPUT,
				  @pnUserIdentityId=@pnUserIdentityId
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

-- If the user is an External User then ensure the user has access to the name:
If @nErrorCode=0
and @bIsExternalUser=1
Begin
	Set @bIsNameAvailable = 0

	Set @sSQLString = "
	Select @bIsNameAvailable = 1 
	from dbo.fn_FilterUserNames(@pnUserIdentityId, 1) FN 
	where FN.NAMENO=@pnNameKey"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@bIsNameAvailable	bit			OUTPUT,
					  @pnUserIdentityId	int,
					  @pnNameKey		int',
					  @bIsNameAvailable	= @bIsNameAvailable	OUTPUT,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @pnNameKey		= @pnNameKey
End
Else Begin
	Set @bIsNameAvailable = 1
End

If @nErrorCode=0
Begin
	Set @nViewNameKey = null
	-- Check whether any name information is required
	
	If @nErrorCode = 0
	and @bIsExternalUser=1
	and @bIsNameAvailable=0 
	Begin
		Set @sSQLString = "
		select @nViewNameKey = NAMENO
		from   dbo.fn_FilterUserViewNames(@pnUserIdentityId) 
		where  NAMENO = @pnNameKey"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nViewNameKey	int			OUTPUT,
						@pnNameKey		int,
						@pnUserIdentityId	int',
						@nViewNameKey	= @nViewNameKey 	OUTPUT,
						@pnNameKey		= @pnNameKey,
						@pnUserIdentityId	= @pnUserIdentityId
	End
End

If @nErrorCode = 0
Begin
	if @nViewNameKey is not null
	Begin
		Set @sSQLString =  "
		Select  N.NAMENO as 'NameKey',
			null as 'PurchaseOrderNo',		
			null as 'TaxTreatment',
			null as 'TaxTreatmentProvincial',
			null as 'ServPerformedIn',
			null as 'CreditLimit',
			null as 'Restriction',			
			null as 'AdditionalBillCopies',
			null as 'HasMultiCaseBills',
			null as 'HasMultiCaseBillsPerOwner',
			null as 'HasSameAddressAndAttention',
			null as 'TaxNumber',"+CHAR(10)+
			dbo.fn_SqlTranslatedColumn('CURRENCY','DESCRIPTION',null,'CUR',@sLookupCulture,@pbCalledFromCentura)
			+ " as 'BillCurrency',"+CHAR(10)+
			"null as 'LocalCurrencyCode',
			null as 'LocalDecimalPlaces',
			null as 'BillingFrequencyDescription',
			null as 'ReceivableTermDays',
			null as 'CorrespondenceInstructions',
			null as 'StatementAttentionKey',
			null as 'StatementAttention',
			null as 'StatementNameKey',
			null as 'StatementName',
			null as 'StatementAddress',
			null as 'BillingAttentionKey',
			null as 'BillingAttention',
			null as 'BillingNameKey',
			null as 'BillingName',
			null as 'BillingAddress',
			@bIsMultiTier as 'IsMultiTierTax',
			null as 'BillingCap',
			null as 'BillingCapPeriod',
			null as 'BillingCapPeriodType',
			null as 'BillingCapPeriodTypeDesc',
			null as 'BillingCapStartDate',
			null as 'BillingCapResetFlag',
			null as 'BillFormatProfile',
			null as 'BillMapProfile',
			null as 'SeparateMarginFlag',
			cast(N.NAMENO as nvarchar(11)) as 'RowKey'
		from NAME N"+char(10)+	
		-- User must have access to the Billing Instructions topic
		"join dbo.fn_GetTopicSecurity(@pnUserIdentityId, 100, default, @dtToday) TS on (TS.IsAvailable=1)"+CHAR(10)+
		"left join IPNAME IP		on (IP.NAMENO = N.NAMENO)"+CHAR(10)+
		"left join CURRENCY CUR		on (CUR.CURRENCY = ISNULL(IP.CURRENCY, @sLocalCurrencyCode))"+CHAR(10)+
		"where N.NAMENO = @pnNameKey"+CHAR(10)+
		"and N.USEDASFLAG&4 = 4"
		
		exec @nErrorCode = sp_executesql @sSQLString,
						N'@pnNameKey		int,
						@pnUserIdentityId	int,
						@sLocalCurrencyCode 	nvarchar(3),
						@bIsMultiTier		bit,
						@dtToday		datetime',
						@pnNameKey		= @pnNameKey,
						@pnUserIdentityId	= @pnUserIdentityId,
						@sLocalCurrencyCode 	= @sLocalCurrencyCode,
						@bIsMultiTier		= @bIsMultiTier,
						@dtToday		= @dtToday

	End
	Else
	Begin

		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
			Select @bBillingData = CASE WHEN NAMENO <> RELATEDNAME THEN 1
							WHEN NAMENO =  RELATEDNAME THEN 0
							WHEN NAMENO IS NULL        THEN NULL
						END 
			from ASSOCIATEDNAME
			where NAMENO = @pnNameKey 
			and RELATIONSHIP = 'BIL'"

			exec @nErrorCode = sp_executesql @sSQLString,
							N'@pnNameKey		int,
							@bBillingData		bit		OUTPUT',
							@pnNameKey		= @pnNameKey,
							@bBillingData		= @bBillingData OUTPUT
		End

		If @nErrorCode = 0
		Begin
			-- If there is no row in the AssociatedName for a Namekey and Relationship = 'BIL' 
			-- return all information except for billing details (because billing information is the
			-- same as cwb_ListClientNameDetail returns for a Name)
			If @bBillingData is null
			Begin 
				If @bIsNameAvailable = 1
				Begin
					-- Extract the Statement details and Billing details information to reduce the number 
					-- of joins in the main statement and to use sp_executesql:
					Set @sSQLString=
					"Select  @nStatementAttentionKey=STN.NAMENO,"+CHAR(10)+
						"@sStatementAttention=dbo.fn_FormatNameUsingNameNo(STN.NAMENO, COALESCE(STN.NAMESTYLE, SNN.NAMESTYLE, 7101)),"+CHAR(10)+
						"@nStatementNameKey=RLN.NAMENO,"+CHAR(10)+
						"@sStatementName=dbo.fn_FormatNameUsingNameNo(RLN.NAMENO, COALESCE(RLN.NAMESTYLE, RNN.NAMESTYLE, 7101)),"+CHAR(10)+
						"@sStatementAddress=dbo.fn_FormatAddress(SA.STREET1, SA.STREET2, SA.CITY, SA.STATE, SS.STATENAME, SA.POSTCODE, SC.POSTALNAME, SC.POSTCODEFIRST, SC.STATEABBREVIATED, SC.POSTCODELITERAL, SC.ADDRESSSTYLE),"+CHAR(10)+
						"@bIsDefaultStatementAttention=CASE WHEN ISNULL(AN.CONTACT,0)=0 THEN 1 ELSE 0 END,"+CHAR(10)+
						"@bIsDefaultStatementAddress=CASE WHEN ISNULL(AN.POSTALADDRESS,0)=0 THEN 1 ELSE 0 END,"+CHAR(10)+
						"@bIsBillingAvailable=TS.IsAvailable"+CHAR(10)+
					"from NAME N"+char(10)+	
					-- User must have access to the Billing Instructions topic
					"join dbo.fn_GetTopicSecurity(@pnUserIdentityId, 100, default, @dtToday) TS on (TS.IsAvailable=1)"+CHAR(10)+
					-- Statement Details
					"left join ASSOCIATEDNAME AN	on (AN.NAMENO = N.NAMENO"+CHAR(10)+
					"				and AN.RELATIONSHIP = 'STM')"+char(10)+
					-- For both Billing details and Statement details, when there is an associated name
					-- record that points to a different related name key, the attention and address 
					-- information may not be on the associated name record so extract them from the 
					-- related name.
					-- If there is no associated name row for either statement or billing details,
					-- do not return any information as we only want to show information that is
					-- different from the default contact details for the name.
					"left join NAME RLN		on (RLN.NAMENO = AN.RELATEDNAME)"+CHAR(10)+
					"left join COUNTRY RNN	        on (RNN.COUNTRYCODE = RLN.NATIONALITY)"+CHAR(10)+
					"left join NAME STN		on (STN.NAMENO = ISNULL(AN.CONTACT, RLN.MAINCONTACT))"+CHAR(10)+
					"left join COUNTRY SNN	        on (SNN.COUNTRYCODE = STN.NATIONALITY)"+CHAR(10)+
					-- Statement Address details 
					"left join ADDRESS SA 		on (SA.ADDRESSCODE = ISNULL(AN.POSTALADDRESS, RLN.POSTALADDRESS))"+CHAR(10)+
					"left join COUNTRY SC		on (SC.COUNTRYCODE = SA.COUNTRYCODE)"+CHAR(10)+
					"left Join STATE SS		on (SS.COUNTRYCODE = SA.COUNTRYCODE"+CHAR(10)+
					" 	           	 	and SS.STATE = SA.STATE)"+CHAR(10)+
					"where N.NAMENO = @pnNameKey"+CHAR(10)+
					"and N.USEDASFLAG&4 = 4"

					exec @nErrorCode=sp_executesql @sSQLString,
							N'@nStatementAttentionKey	int			output,
							@sStatementAttention		nvarchar(254)		output,
							@nStatementNameKey		int			output,
							@sStatementName			nvarchar(254)		output,
							@sStatementAddress		nvarchar(254)		output,
							@bIsDefaultStatementAddress	bit			output,
							@bIsDefaultStatementAttention	bit			output,
							@bIsBillingAvailable		bit			output,
							@pnNameKey			int,
							@pnUserIdentityId		int,
							@dtToday			datetime',
							@nStatementAttentionKey		= @nStatementAttentionKey output,
							@sStatementAttention		= @sStatementAttention	output,
							@nStatementNameKey		= @nStatementNameKey	output,
							@sStatementName			= @sStatementName	output,
							@sStatementAddress		= @sStatementAddress	output,
							@bIsDefaultStatementAttention	= @bIsDefaultStatementAttention output,
							@bIsDefaultStatementAddress	= @bIsDefaultStatementAddress	output,
							@bIsBillingAvailable		= @bIsBillingAvailable	output,
							@pnNameKey			= @pnNameKey,
							@pnUserIdentityId		= @pnUserIdentityId,
							@dtToday			= @dtToday
				End
			
				If @nErrorCode=0
				Begin
					Set @sSQLSelect =  
					"Select  N.NAMENO as 'NameKey',"+CHAR(10)+ 
					"IP.PURCHASEORDERNO as 'PurchaseOrderNo',"+CHAR(10)+
					dbo.fn_SqlTranslatedColumn('TAXRATES','DESCRIPTION',null,'TR',@sLookupCulture,@pbCalledFromCentura)
							+ " as 'TaxTreatment',"+CHAR(10)+
					dbo.fn_SqlTranslatedColumn('TAXRATES','DESCRIPTION',null,'TRS',@sLookupCulture,@pbCalledFromCentura)
							+ " as 'TaxTreatmentProvincial',"+CHAR(10)+
					dbo.fn_SqlTranslatedColumn('STATE','STATENAME',null,'ST',@sLookupCulture,@pbCalledFromCentura)
							+ " as 'ServPerformedIn',"+CHAR(10)+
					CASE WHEN @bIsExternalUser = 0 THEN "IP.CREDITLIMIT" ELSE "null" END+CHAR(10)+	
					"	as 'CreditLimit',"+CHAR(10)+					
					"IP.DEBITCOPIES as 'AdditionalBillCopies',"+CHAR(10)+
					"CASE WHEN(IP.CONSOLIDATION>0) THEN Cast(1 as bit) ELSE Cast(0 as bit) END"+CHAR(10)+
					"	as 'HasMultiCaseBills',"+CHAR(10)+
					"CASE WHEN(cast(IP.CONSOLIDATION as int)&2 = 2) THEN Cast(1 as bit) ELSE Cast(0 as bit) END"+CHAR(10)+
					"	as 'HasMultiCaseBillsPerOwner',"+CHAR(10)+
					"CASE WHEN(cast(IP.CONSOLIDATION as int)&4 = 4) THEN Cast(1 as bit) ELSE Cast(0 as bit) END"+CHAR(10)+
					"	as 'HasSameAddressAndAttention',"+CHAR(10)+
					"N.TAXNO	as 'TaxNumber',"+CHAR(10)+
					dbo.fn_SqlTranslatedColumn('CURRENCY','DESCRIPTION',null,'CUR',@sLookupCulture,@pbCalledFromCentura)
							+ " as 'BillCurrency',"+CHAR(10)+
					"@sLocalCurrencyCode as 'LocalCurrencyCode',"+CHAR(10)+
					"@nLocalDecimalPlaces as 'LocalDecimalPlaces',"+CHAR(10)+
					dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'BF',@sLookupCulture,@pbCalledFromCentura)
							+ " as 'BillingFrequencyDescription',"+CHAR(10)+
					"IP.TRADINGTERMS	as 'ReceivableTermDays',"+CHAR(10)+
					"ISNULL("+dbo.fn_SqlTranslationSelect('NAMETEXT',null,'TEXT','NTX',@sLookupCulture,@pbCalledFromCentura)+", 
						"+dbo.fn_SqlTranslatedColumn('IPNAME','CORRESPONDENCE',null,'IP',@sLookupCulture,@pbCalledFromCentura)+")"+CHAR(10)+
					"	as 'CorrespondenceInstructions',"+CHAR(10)+
					"@nStatementAttentionKey as 'StatementAttentionKey',"+CHAR(10)+
					"@sStatementAttention as 'StatementAttention',"+CHAR(10)+
					"@nStatementNameKey as 'StatementNameKey',"+CHAR(10)+
					"@sStatementName as 'StatementName',"+CHAR(10)+
					"@sStatementAddress as 'StatementAddress',"+CHAR(10)+
					"@bIsDefaultStatementAttention as 'IsDefaultStatementAttention',"+CHAR(10)+
					"@bIsDefaultStatementAddress as 'IsDefaultStatementAddress',"+CHAR(10)+
					"null	as 'BillingAttentionKey',"+CHAR(10)+
					"null	as 'BillingAttention',"+CHAR(10)+
					"null	as 'BillingNameKey',"+CHAR(10)+
					"null	as 'BillingName',"+CHAR(10)+
					"null	as 'BillingAddress',"+CHAR(10)+
					"null	as 'IsDefaultBillingAttention',"+CHAR(10)+
					"null	as 'IsDefaultBillingAddress'"+
					CASE WHEN(@bIsExternalUser=0)
						THEN ","+CHAR(10)+
					"IP.LOCALCLIENTFLAG as 'IsLocalClient',"+CHAR(10)+
					dbo.fn_SqlTranslatedColumn('DEBTORSTATUS','DEBTORSTATUS',null,'DS',@sLookupCulture,@pbCalledFromCentura)
							+ " as 'Restriction',"+CHAR(10)+
					dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'DT',@sLookupCulture,@pbCalledFromCentura)
							+ " as 'DebtorType',"+CHAR(10)+
					dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'UDT',@sLookupCulture,@pbCalledFromCentura)
							+ " as 'UseDebtorType',"+CHAR(10)+
					dbo.fn_SqlTranslatedColumn('EXCHRATESCHEDULE','DESCRIPTION',null,'ERS',@sLookupCulture,@pbCalledFromCentura)
							+ " as 'ExchangeRateSchedule',"+CHAR(10)+
					"ERS.EXCHSCHEDULECODE as 'ExchangeRateScheduleCode'"
					END+","+CHAR(10)+"
					@bIsMultiTier	as 'IsMultiTierTax',"+CHAR(10)+
					"IP.BILLINGCAP as 'BillingCap',"+CHAR(10)+
					"IP.BILLINGCAPPERIOD as 'BillingCapPeriod',"+CHAR(10)+
					"IP.BILLINGCAPPERIODTYPE as 'BillingCapPeriodType',"+CHAR(10)+
					dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'PT',@sLookupCulture,@pbCalledFromCentura)
							+ " as 'BillingCapPeriodTypeDesc',"+CHAR(10)+				
					"IP.BILLINGCAPSTARTDATE as 'BillingCapStartDate',"+CHAR(10)+
					"IP.BILLINGCAPRESETFLAG as 'BillingCapResetFlag',"+CHAR(10)+
					dbo.fn_SqlTranslatedColumn('FORMATPROFILE','FORMATDESC',null,'FP',@sLookupCulture,@pbCalledFromCentura)
							+ " as 'BillFormatProfile',"+CHAR(10)+
					"BM.BILLMAPDESC AS 'BillMapProfile',"+CHAR(10)+
					"IP.SEPARATEMARGINFLAG as 'SeparateMarginFlag',"+CHAR(10)+
					"cast(N.NAMENO as nvarchar(11)) as 'RowKey'"
				End
			End
			-- If there is a row in the AssociatedName for a Namekey, Relationship = 'BIL'
			-- and NameNo = RelatedName then return all the details (current NameNo 
			-- gets billed)
			Else  
			Begin  
				If @bIsNameAvailable = 1
				Begin
					-- Extract the Statement details and Billing details information to reduce the number 
					-- of joins in the main statement and to use sp_executesql:
					Set @sSQLString=
					"Select  @nStatementAttentionKey=STN.NAMENO,"+CHAR(10)+
						"@sStatementAttention=dbo.fn_FormatNameUsingNameNo(STN.NAMENO, COALESCE(STN.NAMESTYLE, SNN.NAMESTYLE, 7101)),"+CHAR(10)+
						"@nStatementNameKey=RLN.NAMENO,"+CHAR(10)+
						"@sStatementName=dbo.fn_FormatNameUsingNameNo(RLN.NAMENO, COALESCE(RLN.NAMESTYLE, RNN.NAMESTYLE, 7101)),"+CHAR(10)+
						"@sStatementAddress=dbo.fn_FormatAddress(SA.STREET1, SA.STREET2, SA.CITY, SA.STATE, SS.STATENAME, SA.POSTCODE, SC.POSTALNAME, SC.POSTCODEFIRST, SC.STATEABBREVIATED, SC.POSTCODELITERAL, SC.ADDRESSSTYLE),"+CHAR(10)+
						"@bIsDefaultStatementAttention=CASE WHEN ISNULL(AN.CONTACT,0)=0 THEN 1 ELSE 0 END,"+CHAR(10)+
						"@bIsDefaultStatementAddress=CASE WHEN ISNULL(AN.POSTALADDRESS,0)=0 THEN 1 ELSE 0 END,"+CHAR(10)+
						"@nBillingAttentionKey=BLN.NAMENO,"+CHAR(10)+
						"@sBillingAttention=dbo.fn_FormatNameUsingNameNo(BLN.NAMENO, COALESCE(BLN.NAMESTYLE, BNN.NAMESTYLE, 7101)),"+CHAR(10)+
						"@nBillingNameKey=RLN1.NAMENO,"+CHAR(10)+
						"@sBillingName=dbo.fn_FormatNameUsingNameNo(RLN1.NAMENO, COALESCE(RLN1.NAMESTYLE, RNN1.NAMESTYLE, 7101)),"+CHAR(10)+
						"@sBillingAddress=dbo.fn_FormatAddress(BA.STREET1, BA.STREET2, BA.CITY, BA.STATE, BS.STATENAME, BA.POSTCODE, BC.POSTALNAME, BC.POSTCODEFIRST, BC.STATEABBREVIATED, BC.POSTCODELITERAL, BC.ADDRESSSTYLE),"+CHAR(10)+
						"@bIsDefaultBillingAttention=CASE WHEN ISNULL(AN1.CONTACT,0)=0 THEN 1 ELSE 0 END,"+CHAR(10)+
						"@bIsDefaultBillingAddress=CASE WHEN ISNULL(AN1.POSTALADDRESS,0)=0 THEN 1 ELSE 0 END,"+CHAR(10)+
						"@bIsBillingAvailable=TS.IsAvailable"+CHAR(10)+
					"from NAME N"+char(10)+	
					-- User must have access to the Billing Instructions topic
					"join dbo.fn_GetTopicSecurity(@pnUserIdentityId, 100, default, @dtToday) TS on (TS.IsAvailable=1)"+CHAR(10)+
					-- Statement Details
					"left join ASSOCIATEDNAME AN	on (AN.NAMENO = N.NAMENO"+CHAR(10)+
					"				and AN.RELATIONSHIP = 'STM')"+char(10)+
					-- For both Billing details and Statement details, when there is an associated name
					-- record that points to a different related name key, the attention and address 
					-- information may not be on the associated name record so extract them from the 
					-- related name.
					-- If there is no associated name row for either statement or billing details,
					-- do not return any information as we only want to show information that is
					-- different from the default contact details for the name.
					"left join NAME RLN		on (RLN.NAMENO = AN.RELATEDNAME)"+CHAR(10)+
					"left join COUNTRY RNN	        on (RNN.COUNTRYCODE = RLN.NATIONALITY)"+CHAR(10)+
					"left join NAME STN		on (STN.NAMENO = ISNULL(AN.CONTACT, RLN.MAINCONTACT))"+CHAR(10)+
					"left join COUNTRY SNN	        on (SNN.COUNTRYCODE = STN.NATIONALITY)"+CHAR(10)+
					-- Statement Address details 
					"left join ADDRESS SA 		on (SA.ADDRESSCODE = ISNULL(AN.POSTALADDRESS, RLN.POSTALADDRESS))"+CHAR(10)+
					"left join COUNTRY SC		on (SC.COUNTRYCODE = SA.COUNTRYCODE)"+CHAR(10)+
					"left Join STATE SS		on (SS.COUNTRYCODE = SA.COUNTRYCODE"+CHAR(10)+
					" 	           	 	and SS.STATE = SA.STATE)"+CHAR(10)+
					-- Billing Details
					"left join ASSOCIATEDNAME AN1	on (AN1.NAMENO = N.NAMENO"+CHAR(10)+
					"				and AN1.RELATIONSHIP = 'BIL')"+CHAR(10)+
					"left join NAME RLN1		on (RLN1.NAMENO = AN1.RELATEDNAME)"+CHAR(10)+
					"left join COUNTRY RNN1	        on (RNN1.COUNTRYCODE = RLN1.NATIONALITY)"+CHAR(10)+
					"left join NAME BLN		on (BLN.NAMENO = ISNULL(AN1.CONTACT, RLN1.MAINCONTACT))"+CHAR(10)+
					"left join COUNTRY BNN	        on (BNN.COUNTRYCODE = BLN.NATIONALITY)"+CHAR(10)+
					-- Billing Address details 
					"left join ADDRESS BA 		on (BA.ADDRESSCODE = ISNULL(AN1.POSTALADDRESS, RLN1.POSTALADDRESS))"+CHAR(10)+
					"left join COUNTRY BC		on (BC.COUNTRYCODE = BA.COUNTRYCODE)"+CHAR(10)+
					"left Join STATE BS		on (BS.COUNTRYCODE = BA.COUNTRYCODE"+CHAR(10)+
					" 	           	 	and BS.STATE = BA.STATE)"+CHAR(10)+	
					"where N.NAMENO = @pnNameKey"+CHAR(10)+
					"and N.USEDASFLAG&4 = 4"

					exec @nErrorCode=sp_executesql @sSQLString,
							N'@nStatementAttentionKey	int			output,
							@sStatementAttention		nvarchar(254)		output,
							@nStatementNameKey		int			output,
							@sStatementName			nvarchar(254)		output,
							@sStatementAddress		nvarchar(254)		output,
							@nBillingAttentionKey		int			output,
							@sBillingAttention		nvarchar(254)		output,
							@nBillingNameKey		int			output,
							@sBillingName			nvarchar(254)		output,
							@sBillingAddress		nvarchar(254)		output,
							@bIsDefaultStatementAttention	bit			output,
							@bIsDefaultStatementAddress	bit			output,
							@bIsDefaultBillingAttention	bit			output,
							@bIsDefaultBillingAddress	bit			output,
							@bIsBillingAvailable		bit			output,
							@pnNameKey			int,
							@pnUserIdentityId		int,
							@sLocalCurrencyCode		nvarchar(3),
							@nLocalDecimalPlaces		tinyint,
							@dtToday			datetime',
							@nStatementAttentionKey		= @nStatementAttentionKey output,
							@sStatementAttention		= @sStatementAttention	output,
							@nStatementNameKey		= @nStatementNameKey	output,
							@sStatementName			= @sStatementName	output,
							@sStatementAddress		= @sStatementAddress	output,
							@nBillingAttentionKey		= @nBillingAttentionKey	output,
							@sBillingAttention		= @sBillingAttention	output,
							@nBillingNameKey		= @nBillingNameKey	output,
							@sBillingName			= @sBillingName		output,
							@sBillingAddress		= @sBillingAddress 	output,
							@bIsDefaultStatementAttention	= @bIsDefaultStatementAttention output,
							@bIsDefaultStatementAddress	= @bIsDefaultStatementAddress	output,
							@bIsDefaultBillingAttention	= @bIsDefaultBillingAttention	output,
							@bIsDefaultBillingAddress	= @bIsDefaultBillingAddress	output,
							@bIsBillingAvailable		= @bIsBillingAvailable	output,
							@pnNameKey			= @pnNameKey,
							@pnUserIdentityId		= @pnUserIdentityId,
							@sLocalCurrencyCode		= @sLocalCurrencyCode,
							@nLocalDecimalPlaces		= @nLocalDecimalPlaces,
							@dtToday			= @dtToday
				End

				If @nErrorCode = 0
				Begin
					Set @sSQLSelect =  
					"Select  N.NAMENO as 'NameKey',"+CHAR(10)+ 
					"IP.PURCHASEORDERNO as 'PurchaseOrderNo',"+CHAR(10)+
					dbo.fn_SqlTranslatedColumn('TAXRATES','DESCRIPTION',null,'TR',@sLookupCulture,@pbCalledFromCentura)
							+ " as 'TaxTreatment',"+CHAR(10)+
					dbo.fn_SqlTranslatedColumn('TAXRATES','DESCRIPTION',null,'TRS',@sLookupCulture,@pbCalledFromCentura)
							+ " as 'TaxTreatmentProvincial',"+CHAR(10)+
					dbo.fn_SqlTranslatedColumn('STATE','STATENAME',null,'ST',@sLookupCulture,@pbCalledFromCentura)
							+ " as 'ServPerformedIn',"+CHAR(10)+
					CASE WHEN @bIsExternalUser = 0 THEN "IP.CREDITLIMIT" ELSE "null" END+CHAR(10)+	
					"	as 'CreditLimit',"+CHAR(10)+					
					"IP.DEBITCOPIES	as 'AdditionalBillCopies',"+CHAR(10)+
					"CASE WHEN(IP.CONSOLIDATION>0) THEN Cast(1 as bit) ELSE Cast(0 as bit) END"+CHAR(10)+
					"	as 'HasMultiCaseBills',"+CHAR(10)+
					"CASE WHEN(cast(IP.CONSOLIDATION as int)&2 = 2) THEN Cast(1 as bit) ELSE Cast(0 as bit) END"+CHAR(10)+
					"	as 'HasMultiCaseBillsPerOwner',"+CHAR(10)+
					"CASE WHEN(cast(IP.CONSOLIDATION as int)&4 = 4) THEN Cast(1 as bit) ELSE Cast(0 as bit) END"+CHAR(10)+
					"	as 'HasSameAddressAndAttention',"+CHAR(10)+
					"N.TAXNO	as 'TaxNumber',"+CHAR(10)+
					dbo.fn_SqlTranslatedColumn('CURRENCY','DESCRIPTION',null,'CUR',@sLookupCulture,@pbCalledFromCentura)
							+ " as 'BillCurrency',"+CHAR(10)+
					"@sLocalCurrencyCode as 'LocalCurrencyCode',"+CHAR(10)+
					"@nLocalDecimalPlaces as 'LocalDecimalPlaces',"+CHAR(10)+
					dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'BF',@sLookupCulture,@pbCalledFromCentura)
							+ " as 'BillingFrequencyDescription',"+CHAR(10)+
					"IP.TRADINGTERMS	as 'ReceivableTermDays',"+CHAR(10)+
					"ISNULL("+dbo.fn_SqlTranslationSelect('NAMETEXT',null,'TEXT','NTX',@sLookupCulture,@pbCalledFromCentura)+", 
						"+dbo.fn_SqlTranslatedColumn('IPNAME','CORRESPONDENCE',null,'IP',@sLookupCulture,@pbCalledFromCentura)+")"+CHAR(10)+
					"	as 'CorrespondenceInstructions',"+CHAR(10)+
					"@nStatementAttentionKey as 'StatementAttentionKey',"+CHAR(10)+
					"@sStatementAttention as 'StatementAttention',"+CHAR(10)+
					"@nStatementNameKey as 'StatementNameKey',"+CHAR(10)+
					"@sStatementName as 'StatementName',"+CHAR(10)+
					"@sStatementAddress as 'StatementAddress',"+CHAR(10)+
					"@bIsDefaultStatementAttention as 'IsDefaultStatementAttention',"+CHAR(10)+
					"@bIsDefaultStatementAddress as 'IsDefaultStatementAddress',"+CHAR(10)+
					"@nBillingAttentionKey as 'BillingAttentionKey',"+CHAR(10)+
					"@sBillingAttention as 'BillingAttention',"+CHAR(10)+
					"@nBillingNameKey as 'BillingNameKey',"+CHAR(10)+
					"@sBillingName as 'BillingName',"+CHAR(10)+
					"@sBillingAddress as 'BillingAddress',"+
					"@bIsDefaultBillingAttention as 'IsDefaultBillingAttention',"+CHAR(10)+
					"@bIsDefaultBillingAddress as 'IsDefaultBillingAddress'"+CHAR(10)+
					CASE WHEN(@bIsExternalUser=0)
						THEN ","+CHAR(10)+
					"IP.LOCALCLIENTFLAG as 'IsLocalClient',"+CHAR(10)+
					dbo.fn_SqlTranslatedColumn('DEBTORSTATUS','DEBTORSTATUS',null,'DS',@sLookupCulture,@pbCalledFromCentura)
							+ " as 'Restriction',"+CHAR(10)+
					dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'DT',@sLookupCulture,@pbCalledFromCentura)
							+ " as 'DebtorType',"+CHAR(10)+
					dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'UDT',@sLookupCulture,@pbCalledFromCentura)
							+ " as 'UseDebtorType',"+CHAR(10)+
					dbo.fn_SqlTranslatedColumn('EXCHRATESCHEDULE','DESCRIPTION',null,'ERS',@sLookupCulture,@pbCalledFromCentura)
							+ " as 'ExchangeRateSchedule',"+CHAR(10)+
					"ERS.EXCHSCHEDULECODE as 'ExchangeRateScheduleCode'"
					END+","+CHAR(10)+"
					@bIsMultiTier	as 'IsMultiTierTax',"+CHAR(10)+
					"IP.BILLINGCAP as 'BillingCap',"+CHAR(10)+
					"IP.BILLINGCAPPERIOD as 'BillingCapPeriod',"+CHAR(10)+
					"IP.BILLINGCAPPERIODTYPE as 'BillingCapPeriodType',"+CHAR(10)+
					dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'PT',@sLookupCulture,@pbCalledFromCentura)
							+ " as 'BillingCapPeriodTypeDesc',"+CHAR(10)+
					"IP.BILLINGCAPSTARTDATE as 'BillingCapStartDate',"+CHAR(10)+
					"IP.BILLINGCAPRESETFLAG as 'BillingCapResetFlag',"+CHAR(10)+
					dbo.fn_SqlTranslatedColumn('FORMATPROFILE','FORMATDESC',null,'FP',@sLookupCulture,@pbCalledFromCentura)
							+ " as 'BillFormatProfile',"+CHAR(10)+
					"BM.BILLMAPDESC AS 'BillMapProfile',"+CHAR(10)+
					"IP.SEPARATEMARGINFLAG as 'SeparateMarginFlag',"+CHAR(10)+
					"cast(N.NAMENO as nvarchar(11)) as 'RowKey'"
				End
			End
		End					 				 
			
		If @nErrorCode = 0
		Begin
			-- Construct SQL statement from the From clause down.

			Set @sSQLString = "from NAME N"+char(10)+	
			"left join NAMETEXT NTX		on (NTX.NAMENO = N.NAMENO"+CHAR(10)+
			"				and NTX.TEXTTYPE = 'CB')"+CHAR(10)+
			dbo.fn_SqlTranslationFrom('NAMETEXT',null,'TEXT','NTX',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+ 
			"left join IPNAME IP		on (IP.NAMENO = N.NAMENO)"+CHAR(10)+
			"left join DEBTORSTATUS DS 	on (DS.BADDEBTOR = IP.BADDEBTOR)"+CHAR(10)+
			"left join TAXRATES TR		on (TR.TAXCODE = IP.TAXCODE)"+CHAR(10)+
			"left join TAXRATES TRS		on (TRS.TAXCODE = IP.STATETAXCODE)"+CHAR(10)+
			"left join STATE ST		on (ST.STATE = IP.SERVPERFORMEDIN)"+CHAR(10)+
			"left join FORMATPROFILE FP	on (FP.FORMATID = IP.BILLFORMATID)"+CHAR(10)+
			"left join BILLMAPPROFILE BM	on (BM.BILLMAPPROFILEID = IP.BILLMAPPROFILEID)"+CHAR(10)+
			"left join TABLECODES BF	on (BF.TABLECODE = IP.BILLINGFREQUENCY"+CHAR(10)+
			"				and BF.TABLETYPE = 75)"+CHAR(10)+	
			"left join CURRENCY CUR		on (CUR.CURRENCY = ISNULL(IP.CURRENCY, @sLocalCurrencyCode))"+CHAR(10)+
			"left join EXCHRATESCHEDULE ERS on (ERS.EXCHSCHEDULEID = IP.EXCHSCHEDULEID)"+CHAR(10)+
			"left join TABLECODES PT	on (PT.USERCODE	= IP.BILLINGCAPPERIODTYPE and PT.TABLETYPE = 127)"+CHAR(10)+
			CASE 	WHEN(@bIsExternalUser=0)
				THEN 	"left join TABLECODES DT	on (DT.TABLECODE = IP.DEBTORTYPE)"+CHAR(10)+
					"left join TABLECODES UDT	on (UDT.TABLECODE = IP.USEDEBTORTYPE)"+CHAR(10)	
			END+
			"where N.NAMENO = @pnNameKey"+CHAR(10)+
			-- User must have access to the Billing Instructions topic
			"and @bIsBillingAvailable = 1"+CHAR(10)+
			"and @bIsNameAvailable = 1"+CHAR(10)+
			"and N.USEDASFLAG&4 = 4"

			Set @sSQLString = @sSQLSelect + @sSQLString

			exec @nErrorCode=sp_executesql @sSQLString,
							N'@nStatementAttentionKey	int,
							@sStatementAttention		nvarchar(254),
							@nStatementNameKey		int,
							@sStatementName			nvarchar(254),
							@sStatementAddress		nvarchar(254),
							@nBillingAttentionKey		int,
							@sBillingAttention		nvarchar(254),
							@nBillingNameKey		int,
							@sBillingName			nvarchar(254),
							@sBillingAddress		nvarchar(254),
							@bIsDefaultStatementAttention	bit,
							@bIsDefaultStatementAddress	bit,
							@bIsDefaultBillingAttention	bit,
							@bIsDefaultBillingAddress	bit,
							@bIsBillingAvailable		bit,
							@bIsNameAvailable		bit,
							@bIsMultiTier			bit,
							@pnNameKey			int,
							@pnUserIdentityId		int,
							@sLocalCurrencyCode		nvarchar(3),
							@nLocalDecimalPlaces		tinyint',
							@nStatementAttentionKey		= @nStatementAttentionKey,
							@sStatementAttention		= @sStatementAttention,
							@nStatementNameKey		= @nStatementNameKey,
							@sStatementName			= @sStatementName,
							@sStatementAddress		= @sStatementAddress,
							@nBillingAttentionKey		= @nBillingAttentionKey,
							@sBillingAttention		= @sBillingAttention,
							@nBillingNameKey		= @nBillingNameKey,
							@sBillingName			= @sBillingName,
							@sBillingAddress		= @sBillingAddress,
							@bIsDefaultStatementAttention	= @bIsDefaultStatementAttention,
							@bIsDefaultStatementAddress	= @bIsDefaultStatementAddress,
							@bIsDefaultBillingAttention	= @bIsDefaultBillingAttention,
							@bIsDefaultBillingAddress	= @bIsDefaultBillingAddress,
							@bIsBillingAvailable		= @bIsBillingAvailable,
							@bIsNameAvailable		= @bIsNameAvailable,
							@bIsMultiTier			= @bIsMultiTier,
							@pnNameKey			= @pnNameKey,
							@pnUserIdentityId		= @pnUserIdentityId,
							@sLocalCurrencyCode		= @sLocalCurrencyCode,
							@nLocalDecimalPlaces		= @nLocalDecimalPlaces

			Set @pnRowCount=@@Rowcount
		End
	End
End

Return @nErrorCode
GO

Grant execute on dbo.na_ListBillingInstructions to public
GO



