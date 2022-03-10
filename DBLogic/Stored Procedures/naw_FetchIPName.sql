-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_FetchIPName									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_FetchIPName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_FetchIPName.'
	Drop procedure [dbo].[naw_FetchIPName]
End
Print '**** Creating Stored Procedure dbo.naw_FetchIPName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_FetchIPName
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int,		-- Mandatory
	@pbNewRow		bit		= 0,
	@psCountryCode		nvarchar(3)	= null,
	@pbIsAgent		bit		= null
)
as
-- PROCEDURE:	naw_FetchIPName
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the IPName business entity.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 13 Apr 2006	IB	RFC3763	1	Procedure created
-- 11 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 09 Sep 2009	MS	RFC8288 3	Return Default Debit Copies for New Name
-- 11 Apr 2013	DV	R13270	4	Increase the length of nvarchar to 11 when casting or declaring integer 

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

Declare @sTaxCode		nvarchar(3)
Declare @sTaxDescription	nvarchar(30)
Declare @sBillCurrencyCode	nvarchar(3)
Declare @sBillCurrency		nvarchar(40)
Declare @bIsLocalClient		bit
Declare	@nCategoryKey		int
Declare @sCategory		nvarchar(80)
Declare @nDebitCopies		smallint

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	If @pbNewRow = 1
	Begin
		Set @sSQLString = "
		Select 
			@sTaxCode 		= C.DEFAULTTAXCODE,
			@sTaxDescription	= "+
			dbo.fn_SqlTranslatedColumn('TAXRATES','DESCRIPTION',null,'TR',
						@sLookupCulture,@pbCalledFromCentura)+",
			@sBillCurrencyCode	= C.DEFAULTCURRENCY,
			@sBillCurrency		= "+
			dbo.fn_SqlTranslatedColumn('CURRENCY','DESCRIPTION',null,'CUR',
						@sLookupCulture,@pbCalledFromCentura)+"			

		from	COUNTRY C
		left join TAXRATES 	TR 	on (TR.TAXCODE 			= C.DEFAULTTAXCODE) 
		left join CURRENCY 	CUR	on (CUR.CURRENCY 		= C.DEFAULTCURRENCY)

		where	C.COUNTRYCODE = @psCountryCode"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@sTaxCode		nvarchar(3)		output,
				@sTaxDescription	nvarchar(30)		output,
				@sBillCurrencyCode	nvarchar(3)		output,
				@sBillCurrency		nvarchar(40)		output,
				@psCountryCode		nvarchar(3)',
				@sTaxCode		= @sTaxCode		output,
				@sTaxDescription	= @sTaxDescription	output,
				@sBillCurrencyCode	= @sBillCurrencyCode	output,
				@sBillCurrency		= @sBillCurrency	output,
				@psCountryCode		= @psCountryCode

		If @nErrorCode = 0 
		and @psCountryCode is null
		Begin
			Set @bIsLocalClient = 1
		End

		If @nErrorCode = 0 
		and @psCountryCode is not null
		Begin
			Set @sSQLString = "
			Select
				@bIsLocalClient	= CASE
						  WHEN @psCountryCode <> SCHC.COLCHARACTER then 0
						  ELSE 1
						  END				
			from SITECONTROL SCHC	
			where SCHC.CONTROLID = 'HOMECOUNTRY'"

			exec @nErrorCode=sp_executesql @sSQLString,
					N'
					@bIsLocalClient		bit			output,
					@psCountryCode		nvarchar(3)',
					@bIsLocalClient		= @bIsLocalClient	output,
					@psCountryCode		= @psCountryCode
		End

		If @nErrorCode = 0 
		and @pbIsAgent = 1
		Begin
			Set @sSQLString = "
			Select
				@nCategoryKey		= SCAC.COLINTEGER,
				@sCategory		= "+
				dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCC',
							@sLookupCulture,@pbCalledFromCentura)+"
			from SITECONTROL SCAC	
			left join TABLECODES 	TCC 	on (TCC.TABLECODE 	= SCAC.COLINTEGER)

			where SCAC.CONTROLID	= 'Agent Category'"

			exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@nCategoryKey		int			output,
				@sCategory		nvarchar(80)		output',
				@nCategoryKey		= @nCategoryKey		output,
				@sCategory		= @sCategory		output

		End

		If @nErrorCode = 0 
		Begin
			Set @sSQLString = "
			Select 	@nDebitCopies	= COLINTEGER
			from SITECONTROL
			where CONTROLID	= 'DEFAULTDEBITCOPIES'"

			exec @nErrorCode=sp_executesql @sSQLString,
				N'@nDebitCopies		smallint		output',
				@nDebitCopies		= @nDebitCopies		output
		End

		Select
			@pnNameKey		as NameKey,
			@sTaxCode 		as TaxCode,
			@sTaxDescription	as TaxDescription,
			@sBillCurrencyCode	as BillCurrencyCode,
			@sBillCurrency		as BillCurrency,
			@bIsLocalClient		as IsLocalClient,
			@nCategoryKey		as CategoryKey,
			@sCategory		as Category,
			@nDebitCopies		as DebitNoteCopies	

	End
	Else
	Begin
		Set @sSQLString = "
		Select
		cast(I.NAMENO as nvarchar(11)) 	as RowKey,
		I.NAMENO			as NameKey,
		I.TAXCODE			as TaxCode,
		"+dbo.fn_SqlTranslatedColumn('TAXRATES','DESCRIPTION',null,'TR',
						@sLookupCulture,@pbCalledFromCentura)+"
						as TaxDescription,
		I.BADDEBTOR			as DebtorRestrictionKey,
		"+dbo.fn_SqlTranslatedColumn('DEBTORSTATUS','DEBTORSTATUS',null,'DS',
						@sLookupCulture,@pbCalledFromCentura)+"
						as DebtorRestriction,
		I.CURRENCY			as BillCurrencyCode,
		"+dbo.fn_SqlTranslatedColumn('CURRENCY','DESCRIPTION',null,'C',
						@sLookupCulture,@pbCalledFromCentura)+"
						as BillCurrency,
		I.DEBITCOPIES			as DebitNoteCopies,
		CASE cast(I.CONSOLIDATION as int)&1	
		WHEN 1 THEN 1
		ELSE 0
		END				as HasMultiCaseBills,
		CASE cast(I.CONSOLIDATION as int)&2	
		WHEN 2 THEN 1
		ELSE 0
		END				as HasMultiCaseBillsByOwner,
		I.DEBTORTYPE			as DebtorTypeKey,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCDT',
						@sLookupCulture,@pbCalledFromCentura)+"
						as DebtorType,
		I.USEDEBTORTYPE			as UseDebtorTypeKey,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCUDT',
						@sLookupCulture,@pbCalledFromCentura)+"
						as UseDebtorType,
		I.CORRESPONDENCE		as DefaultCorrespondenceInstructions,
		I.CATEGORY			as CategoryKey,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCC',
						@sLookupCulture,@pbCalledFromCentura)+"
						as Category,
		I.PURCHASEORDERNO		as PurchaseOrderNo,
		I.LOCALCLIENTFLAG		as IsLocalClient,
		I.AIRPORTCODE			as AirportCode,
		"+dbo.fn_SqlTranslatedColumn('AIRPORT','AIRPORTNAME',null,'A',
						@sLookupCulture,@pbCalledFromCentura)+"
						as AirportName,
		I.TRADINGTERMS			as ReceivableTermsDays,
		I.BILLINGFREQUENCY		as BillingFrequencyKey,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCBF',
						@sLookupCulture,@pbCalledFromCentura)+"
						as BillingFrequency,
		I.CREDITLIMIT			as CreditLimit
	
		from IPNAME I
		left join TAXRATES 	TR 	on (TR.TAXCODE 		= I.TAXCODE)
		left join DEBTORSTATUS 	DS 	on (DS.BADDEBTOR 	= I.BADDEBTOR)
		left join CURRENCY 	C 	on (C.CURRENCY 		= I.CURRENCY)
		left join TABLECODES 	TCDT 	on (TCDT.TABLECODE 	= I.DEBTORTYPE)
		left join TABLECODES 	TCUDT 	on (TCUDT.TABLECODE 	= I.USEDEBTORTYPE)
		left join TABLECODES 	TCC 	on (TCC.TABLECODE 	= I.CATEGORY)
		left join AIRPORT 	A 	on (A.AIRPORTCODE 	= I.AIRPORTCODE)
		left join TABLECODES 	TCBF 	on (TCBF.TABLECODE 	= I.BILLINGFREQUENCY)

		where 
		I.NAMENO = @pnNameKey"
	
		exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@pnNameKey	int',
				@pnNameKey	= @pnNameKey
	End
End

Return @nErrorCode
GO

Grant execute on dbo.naw_FetchIPName to public
GO