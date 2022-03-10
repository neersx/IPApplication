-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wp_GetWipCost
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[wp_GetWipCost]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.wp_GetWipCost.'
	Drop procedure [dbo].[wp_GetWipCost]
End
Print '**** Creating Stored Procedure dbo.wp_GetWipCost...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.wp_GetWipCost
(
	@pnUserIdentityId		int,		-- Mandatory
	@pbCalledFromCentura		bit		= 0,

	-- Wip criteria
	@pdtTransactionDate		datetime	= null,
	@pnEntityKey			int		= null,
	@pnStaffKey			int		= null,
	@pnNameKey			int		= null,	-- Only required if CaseKey not provided
	@pnCaseKey			int		= null,
	@psDebtorNameTypeKey		nvarchar(3)	= 'D',
	@psWipCode			nvarchar(6)	= null,
	@pnProductKey			int		= null,
	-- Context of use
	@pbIsChargeGeneration		bit		= null,
	@pbIsServiceCharge		bit		= null, -- Extracted from WipCode if not provided
	@pbUseSuppliedValues		bit		= 0, 	-- Use supplied local & foreign pre-margin values to derive exchange rate

	-- Hours based services calculations
	-- Either @pdtHours or @pnTimeUnits should be provided, the other is derived.
	@pdtHours			datetime	= null	output, -- I/O The time worked
	@pnTimeUnits			int		= null	output, -- I/O Time expressed in units per hour
	@pnUnitsPerHour			smallint	= null	output,
	@pnChargeOutRate		dec(10,2)	= null	output,

	-- Calculations based on value supplied by the user.
	-- Either local or foreign (and @psCurrencyCode) should be provided.
	@pnLocalValueBeforeMargin	dec(11,2)	= null output,
	@pnForeignValueBeforeMargin	dec(11,2)	= null,

	-- Value of the WIP
	@psCurrencyCode			nvarchar(3)	= null	output, -- I/O Provide when calculating from a value.
	@pnExchangeRate			dec(11,4)	= null	output,
	@pnLocalValue			dec(11,2)	= null	output,
	@pnForeignValue			dec(11,2)	= null	output,

	-- Margin
	@pbMarginRequired		bit		= null, -- Should margin calculations be performed in this context?
	@pnMarginValue			dec(11,2)	= null	output, -- Expressed in @psCurrencyCode

	-- Discount
	@pnLocalDiscount		dec(11,2)	= null	output,
	@pnForeignDiscount		dec(11,2)	= null	output,

	-- Costs
	@pnLocalCost1			dec(11,2)	= null	output,
	@pnLocalCost2			dec(11,2)	= null	output,

	@pbDebug			bit		= null,
	@pnSupplierKey			int		= null,	-- This is used from Disbursement dissection window if associate field is filled.
	@pnStaffClassKey		int		= null,	-- option to provide the staff class rather than the staff
	@psActionKey			nvarchar(2)	= null,
	@pnMarginNo			int		= null output,
	
	-- Discounts for margin 
	@pnLocalDiscountForMargin	decimal(11,2)	= null	output,
	@pnForeignDiscountForMargin	decimal(11,2)	= null	output,
	--
	@pbSplitTimeByDebtor  bit		= 0, 	-- only used for time calculations in multi-debtor billing
											-- if 1, the premargin amount calculated from the input time value 
											-- is proportionally adjusted based on the debtor percentage.
	-- Discounts for pre-margin amounts 
	@pnLocalPreMarginDiscount	decimal(11,2)	= null	output,
	@pnForeignPreMarginDiscount	decimal(11,2)	= null	output,
        -- Margins to be created as separate items
	@pbSeparateMarginMode		bit		= 0  -- may affect some calculated values e.g. charge out rate and is used only for web											
)
as
-- PROCEDURE:	wp_GetWipCost
-- VERSION:	30
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Cost a piece of Work In Progress including charge out rates,
--		local/foreign values, margins, discounts and costs.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 18 Jun 2005	JEK	RFC2629	 1	Procedure created
-- 23 Nov 2005	DW	SQA12062 2	Added new parameter @pbUseSuppliedValues
-- 14 Jun 2006	KR	11702	 3	Added new parameters to the call ac_GetExchangeDetails
-- 23 Jun 2006	KR	12108	 4	Added @psDebtorNameTypeKey to the call to ac_GetExchangeDetails
-- 27 Jun 2006	KR	12108	 5	Removed @psDebtorNameTypeKey as a parameter to the call to ac_GetExchangeDetails.
--					Added @pnSupplierKey as parameter to wp_GetWIPCost
-- 21 Jul 2006	KR	13096	 6	@nExchDetailsNameKey is set to @pnNameKey when @pnCaseKey is not provided.
-- 23 Oct 2006	Dw	13126	 7	Added new parameter @pnStaffClassKey for use by budget calculator
-- 06 Dec 2006	AT	13768	 8	Modified check for Local values to include credits.
-- 15 Jan 2007	CR	13955	 9	Consolidated margin calculation logic into pt_CalculateMargin so that this and
--					pt_DoCalculation may use the same logic.
-- 16 Mar 2007	MF	14574	10	Allow Action to be passed as a parameter so that the WIP Costing considers this
--					explicit Action if it is passed rather than defaulting.
-- 16 Oct 2007	CR	15383	11	Update calls to pt_CalculateMargin to include Agent Item parameter and SupplierKey
-- 03 Oct 2008	Dw	16917	12	Added new parameter to return margin identifier
-- 15 Dec 2008	MF	17136	13	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 23 Feb 2010	MS	RFC7268	14	ChargeOutRate will be set as null rather than 0 if applicable charge is not found
-- 24 Feb 2010	Dw	18298	15	Pass new attribute MARGINCAP to pt_CalculateMargin
-- 23 Jun 2010	MS	RFC7269	16	Added new output parameters for Discounts on Margin
-- 06 Jul 2011	SF	RFC10910 17	Consider seconds when calculating units from hours if Site Control Consider Secs in Units Calc. is TRUE
-- 22 Dec 2011	AT	R9160	18	Add WIP Type for exch rate variation calculation.
-- 04 Jul 2013	Dw	R12904	19	Added parameter @pbSplitTimeByDebtor for use in time-based calculations for multi-debtor Cases.
-- 16 Aug 2013	KR	R13701	20	Made @pnLocalValueBeforeMargin an output parameter
-- 04 Sep 2013	AT	R12904	21	Fixed debtor percentage rounding error.
-- 26 Mar 2014	Dw	R13912	22	Fix to split COSTCALCULATION amounts in time-based calculations when @pbSplitTimeByDebtor applies.
-- 03 Nov 2014	Dw	R41055	23	Adjusted logic to differentiate between zero charge rate and scenario where there is no valid charge rate.
-- 11 Jun 2015  DV	R43487	24	Calculate decimal places even when no calculation is required
-- 20 Oct 2015  MS      R53933  25      Changed size from decimal(8,4) to decimal(11,4) for rate cols
-- 15 Dec 2015	Dw	R56172	26	Added 2 new output parameters @pnLocalPreMarginDiscount and @pnForeignPreMarginDiscount.
-- 20 Dec 2016	LP	R70261	27	Fixed bug where Case Name was not being derived when @psDebtorNameTypeKey is defaulted to 'D'
-- 08 Nov 2018	AV	75198/DR-45358	28	Date conversion errors when creating cases and opening names in Chinese DB.
-- 17 Apr 2019  MS      DR27273 29      Added parameter @pbSeparateMarginMode for calculating chargeout rate for web use only
-- 08 Jul 2019  MS      DR49444 30      Use bank rate for conversions to local currency if site control 'Bank Rate In Use for Service Charges' is true

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode			int
declare @nRowCount			int
declare @sSQLString			nvarchar(4000)
declare @sAlertXML			nvarchar(400)

declare @sWIPTypeKey			nvarchar(6)
declare	@sWipCategoryKey		nvarchar(2)

-- Charge Out Rates
declare	@bExtractChargeOut		bit
declare	@nChargeRatePerHour		decimal(10,2)
declare	@sChargeCurrencyCode		nvarchar(3) -- Null for local currency
declare @bIsRoundUp			bit
declare @nDecimalUnits			decimal(5,2)
declare @nUnitsPerHour			tinyint
declare @nHours				smallint
declare @nMinutes			smallint

-- Margins
declare	@nMarginPercent			decimal(6,2) -- 10% expressed as value 10
declare	@nMarginAmount			decimal(10,2)
declare	@sMarginCurrencyCode		nvarchar(3) -- Null for local currency
declare @nMarginExchangeRate		decimal(11,4)
declare @nMarginCap				decimal(10,2)

-- Discounts
declare @bExtractDiscount		bit
declare	@nDiscountPercent		decimal(6,3) -- 10% expressed as value 10
declare	@bIsDiscountBasedOnAmount	bit -- True if before margin calculation required
-- R56172
declare @nMarginDiscountPercent		decimal(6,3) -- 10% expressed as value 10

-- Cost Rates
declare	@nCostPercent1			decimal(6,2) -- 10% expressed as value 10
declare	@nCostPercent2			decimal(6,2) -- 10% expressed as value 10
declare	@nCostRatePerHour1		decimal(10,2)
declare	@nCostRatePerHour2		decimal(10,2)

-- Currency
declare	@nLocalDecimalPlaces		tinyint
declare @nForeignDecimalPlaces		tinyint
declare @bUseSellRate			bit
declare @bUseHistoricalRates		bit
declare	@nBuyRate			dec(11,4)
declare	@nSellRate			dec(11,4)

-- exchange rate schedules or variation details
declare @bIsSupplier			bit
declare @nSupplier			int
declare @nExchDetailsNameKey		int
declare	@sDebtorNameTypeKey		varchar(3)
declare @nValueBeforeMargin		dec(11,2)
declare @pdtExchTransDate		datetime
-- 12904
declare @bWIPSplitMultiDebtor		bit
declare	@nDebtorPercent			decimal(8,5)
declare @bUseBankRate                   bit
declare @nBankRate                      dec(11,4)

-- Initialise variables
Set @nErrorCode = 0
Set @nDebtorPercent = 1

-- Is the 'WIP Split Multi Debtor' site control set
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select  @bWIPSplitMultiDebtor = isnull(S.COLBOOLEAN,0 )
	from	SITECONTROL S
	WHERE 	S.CONTROLID = 'WIP Split Multi Debtor'"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@bWIPSplitMultiDebtor	bit		OUTPUT',
			  @bWIPSplitMultiDebtor	= @bWIPSplitMultiDebtor	OUTPUT
End

If @nErrorCode = 0
and (@pnCaseKey is not null)
and (@bWIPSplitMultiDebtor = 0)
Begin
	Set @pnNameKey = null
End


-- if this a time-based multi-debtor calculation (RFC12904)
-- (@pbSplitTimeByDebtor is always 0 when called from Billing)
If @nErrorCode = 0
and ((@pdtHours is not null) or (@pnTimeUnits is not null))
and (@pnLocalValueBeforeMargin is null)
and (@pnForeignValueBeforeMargin is null)
and (@pnCaseKey is not null)
and (@pnNameKey is not null)
and (@bWIPSplitMultiDebtor = 1)
and (@pbSplitTimeByDebtor = 1)
Begin
	Set @psDebtorNameTypeKey = isnull(@psDebtorNameTypeKey, 'D')
	
	-- get the billing percentage of this debtor
	Set @sSQLString = "
	select 	@nDebtorPercent = CN.BILLPERCENTAGE
	from CASENAME CN	
	where	CN.NAMETYPE = @psDebtorNameTypeKey
	and	(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
	and CN.NAMENO=@pnNameKey
	and CN.CASEID=@pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnCaseKey		int,
		@pnNameKey		int,
		@psDebtorNameTypeKey	nvarchar(3),
		@nDebtorPercent 	decimal(8,5)	OUTPUT',
		@pnCaseKey		= @pnCaseKey,
		@pnNameKey		= @pnNameKey,
		@psDebtorNameTypeKey	= @psDebtorNameTypeKey,
		@nDebtorPercent		= @nDebtorPercent OUTPUT
		
	-- convert to percentage
	If @nErrorCode = 0
	and (@nDebtorPercent is not null)
	and (@nDebtorPercent > 0)
	and (@nDebtorPercent < 100)
	Begin
		Set @nDebtorPercent = @nDebtorPercent/100
	End
	Else
	Begin
		Set @nDebtorPercent = 1
	End
End
	


Set @pdtExchTransDate = @pdtTransactionDate

-- Look up rates
-- Charge out rates required?
If @nErrorCode = 0
and (@pdtHours is not null or 
     @pnTimeUnits is not null)
Begin
	Set @bExtractChargeOut = 1
End

-- Discounts required?
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select  @bExtractDiscount =
		case	when(D.COLBOOLEAN = 1)
			then
				-- Suppress discounts in billing
				case 	when (isnull(@pbIsChargeGeneration,0) = 0
					      and isnull(B.COLBOOLEAN,0) = 1)
					then 0
					else 1
					end
			else 0
			end
	from	SITECONTROL D
	left join SITECONTROL B	on (B.CONTROLID = 'DiscountNotInBilling')
	WHERE 	D.CONTROLID = 'Discounts'"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pbIsChargeGeneration	bit,
			  @bExtractDiscount	bit		OUTPUT',
			  @pbIsChargeGeneration	= @pbIsChargeGeneration,
			  @bExtractDiscount	= @bExtractDiscount	OUTPUT
End

-- Get rates if there is something to calculate
If @nErrorCode = 0
and (@bExtractChargeOut = 1 or
     @pnLocalValueBeforeMargin != 0 or
     @pnForeignValueBeforeMargin != 0)
Begin
	exec @nErrorCode = dbo.wp_GetWipCostingRates
		@pnUserIdentityId		= @pnUserIdentityId,
		@pbCalledFromCentura		= @pbCalledFromCentura,
		-- Wip criteria
		@pdtTransactionDate		= @pdtTransactionDate,
		@pnEntityKey			= @pnEntityKey,
		@pnStaffKey			= @pnStaffKey,
		@pnNameKey			= @pnNameKey,
		@pnCaseKey			= @pnCaseKey,
		@psDebtorNameTypeKey		= @psDebtorNameTypeKey,
		@psWipCode			= @psWipCode,
		@pnProductKey			= @pnProductKey,
	
		@psWipCategoryKey		= @sWipCategoryKey output,
		-- Charge Out Rates
		@pbExtractChargeOut		= @bExtractChargeOut,
		@pnChargeRatePerHour		= @nChargeRatePerHour output,
		@psChargeCurrencyCode		= @sChargeCurrencyCode output,
		-- Margins
		@pbExtractMargin		= @pbMarginRequired,
		@pnMarginPercent		= @nMarginPercent output,
		@pnMarginAmount			= @nMarginAmount output,
		@psMarginCurrencyCode		= @sMarginCurrencyCode output,
		-- Discounts
		@pbExtractDiscount		= @bExtractDiscount,
		@pnDiscountPercent		= @nDiscountPercent output,
		@pbIsDiscountBasedOnAmount	= @bIsDiscountBasedOnAmount output,
		-- Cost Rates
		@pbExtractCost			= 1,
		@pnCostPercent1			= @nCostPercent1 output,
		@pnCostPercent2			= @nCostPercent2 output, 
		@pnCostRatePerHour1		= @nCostRatePerHour1 output,
		@pnCostRatePerHour2		= @nCostRatePerHour2 output,
		-- additional input parameters
		@pnStaffClassKey		= @pnStaffClassKey,
		@psActionKey			= @psActionKey,
		-- additional output parameters
		@prnMarginNo			= @pnMarginNo output,
		@prnMarginCap			= @nMarginCap output,
		@prsWIPTypeKey			= @sWIPTypeKey output,
		@pnMarginDiscountPercent	= @nMarginDiscountPercent output	

		If @pbDebug = 1
		Begin
			PRINT 'wp_GetWipCostingRates'
			Select @sWipCategoryKey		AS WIPCATEGORY,
			-- Charge Out Rates
			@bExtractChargeOut		AS EXACTCHARGEOUTRATE,
			@nChargeRatePerHour 		AS CHARGERATEPERHOUR,
			@sChargeCurrencyCode 		AS CHARGECURRENCY,
			-- Margins
			@pbMarginRequired 		AS MARGINREQ,
			@nMarginPercent 		AS MARGINPERCENT,
			@nMarginAmount			AS MARGINAMT,
			@sMarginCurrencyCode		AS MARGINCURRENCY,
			@nMarginCap				AS MARGINCAP,
			-- Discounts
			@bExtractDiscount		AS EXTRACTDISC,
			@nDiscountPercent		AS DISCPERCENT,
			@bIsDiscountBasedOnAmount	AS ISDISCBASEDONAMT,
			-- Cost Rates
			@nCostPercent1			AS COSTPERCENT1,
			@nCostPercent2			AS COSTPERCENT2, 
			@nCostRatePerHour1		AS COSTRATEPERHR1,
			@nCostRatePerHour2		AS COSTRATEPERHR2,
			@pnMarginNo			AS MARGINNO,
			@pnLocalValueBeforeMargin	AS LOCALVALUEBEFOREMARGIN
		End	

End

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select  @nLocalDecimalPlaces = case when W.COLBOOLEAN = 1 then 0 else isnull(CY.DECIMALPLACES,2) end,
		@nUnitsPerHour = isnull(U.COLINTEGER,10),
		@bIsRoundUp = isnull(R.COLBOOLEAN,0)
	from	SITECONTROL C
	left join CURRENCY CY	on (CY.CURRENCY = C.COLCHARACTER
				-- Decimal places implemented in Centura
				and isnull(@pbCalledFromCentura,0) = 0 )
	left join SITECONTROL W on (W.CONTROLID = 'Currency Whole Units')
	left join SITECONTROL U on (U.CONTROLID = 'Units Per Hour')
	left join SITECONTROL R	on (R.CONTROLID = 'Round Up')
	WHERE 	C.CONTROLID = 'CURRENCY'"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pbCalledFromCentura	bit,
			  @nLocalDecimalPlaces	tinyint			OUTPUT,
			  @nUnitsPerHour	smallint		OUTPUT,
			  @bIsRoundUp		bit			OUTPUT',
			  @pbCalledFromCentura 	= @pbCalledFromCentura,
			  @nLocalDecimalPlaces	= @nLocalDecimalPlaces	OUTPUT,
			  @nUnitsPerHour	= @nUnitsPerHour	OUTPUT,
			  @bIsRoundUp		= @bIsRoundUp		OUTPUT
End

if @nErrorCode = 0
Begin

	If (@pnSupplierKey is not null)
	Begin
		
		Set @sSQLString = "Select @nSupplier = 1 From CREDITOR
			   Where  NAMENO = @pnSupplierKey"
 
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@nSupplier	int,
					@pnSupplierKey	int',
					@nSupplier	= @nSupplier,
					@pnSupplierKey 	=	@pnSupplierKey

		select @nRowCount = @@ROWCOUNT

		If (@nRowCount = 1)
		Begin
			Set @nExchDetailsNameKey = @pnSupplierKey
			Set @bIsSupplier = 1
		End
		Else
		Begin
			
			Set @sSQLString = "Select @nSupplier = 1 From IPNAME
			Where  NAMENO = @pnSupplierKey"
 
			exec @nErrorCode=sp_executesql @sSQLString,
					N'@nSupplier	int,
					@pnSupplierKey	int',
					@nSupplier	= @nSupplier,
					@pnSupplierKey 	=	@pnSupplierKey

			select @nRowCount = @@ROWCOUNT
			If (@nRowCount = 1)
			Begin
				Set @nExchDetailsNameKey = @pnSupplierKey
				Set @bIsSupplier = 0
			End
		End
	End
	Else
	Begin

		If (@pnNameKey is not null)
		Begin
			Set @nExchDetailsNameKey = @pnNameKey
			-- because the @nExchDetailsNameKey is a debtor
			Set @bIsSupplier = 0
		End
		Else
		Begin

			-- Get the Debtor number if supplier is not provided based on the CaseID.
			If (@psDebtorNameTypeKey is null)
				Set @psDebtorNameTypeKey = 'D'
	
			Set @sSQLString = "
			select 	@nExchDetailsNameKey = CN.NAMENO
			from CASENAME CN
			left join NAME N		on (N.NAMENO=CN.NAMENO)
			where	CN.NAMETYPE = @psDebtorNameTypeKey
			and	(CN.EXPIRYDATE is null or CN.EXPIRYDATE > getdate())
			and	CN.SEQUENCE =
					(select min(SEQUENCE) 
					from CASENAME CN1
			                where CN1.CASEID=CN.CASEID
			          	and CN1.NAMETYPE=CN.NAMETYPE
					and(CN1.EXPIRYDATE is null or CN1.EXPIRYDATE > getdate()))
			AND CN.CASEID=@pnCaseKey"
		
			exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnCaseKey			int,
				  @psDebtorNameTypeKey		nvarchar(3),
				  @nExchDetailsNameKey			int		OUTPUT',
				  @pnCaseKey			= @pnCaseKey,
				  @psDebtorNameTypeKey		= @psDebtorNameTypeKey,
				  @nExchDetailsNameKey		= @nExchDetailsNameKey	OUTPUT
			if (@nErrorCode = 0)
				-- because the @nExchDetailsNameKey is a debtor 
				Set @bIsSupplier = 0
		End
	End
		
End


-- Get currency information
If @nErrorCode = 0
Begin
	Set @psCurrencyCode = isnull(@psCurrencyCode,@sChargeCurrencyCode)
	Set @pbIsServiceCharge = isnull(@pbIsServiceCharge, case when @sWipCategoryKey = 'SC'
								then 1 else 0 end)
	
	If @psCurrencyCode is null
	and @pnForeignValueBeforeMargin is not null
	Begin
  		Set @sAlertXML = dbo.fn_GetAlertXML('AC9', 'Currency must be supplied for foreign value {0}.',
    						cast(@pnForeignValueBeforeMargin as nvarchar(20)), null, null, null, null)
  		RAISERROR(@sAlertXML, 12, 1)
  		Set @nErrorCode = @@ERROR
	End

	If @nErrorCode = 0
	and (@psCurrencyCode is not null or
	     @sMarginCurrencyCode is not null)
	Begin
		If (@pbIsServiceCharge = 1)
		Begin
                        Set @sSQLString = "
			select  @bUseBankRate = isnull(COLBOOLEAN,0)
			from	SITECONTROL
			WHERE 	CONTROLID = 'Bank Rate In Use for Service Charges'"
		
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@bUseBankRate		bit			OUTPUT',
							  @bUseBankRate		= @bUseBankRate		OUTPUT

			If @bUseBankRate = 0
			Begin
				Set @bUseSellRate = 1
			End
		End
		-- Expenses may use either sell or buy rates
		-- Only expenses use historical rates at the moment
		Else
		Begin
			Set @sSQLString = "
			select  @bUseSellRate = isnull(COLBOOLEAN,0)
			from	SITECONTROL
			WHERE 	CONTROLID = 'Sell Rate Only for New WIP'"
		
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@bUseSellRate		bit			OUTPUT',
							  @bUseSellRate		= @bUseSellRate		OUTPUT

                        Set @bUseBankRate = 0

		End
	End

	If (@nErrorCode = 0)
	and (@psCurrencyCode is not null)
	Begin
		--Get parameters required by ac_GetExchangeDetails for the given WIPCategory
		exec @nErrorCode = dbo.ac_GetExchangeParameters
			@pbUseHistoricalRates	= @bUseHistoricalRates output,
			@pdtTransactionDate	= @pdtExchTransDate output,
			@pnUserIdentityId	= @pnUserIdentityId,
			@pbCalledFromCentura	= @pbCalledFromCentura,
			@psWIPCategory		= @sWipCategoryKey,
			@pnAccountingSystemID	= 2
		
		If @pbDebug = 1
		Begin
			Print 'ac_GetExchangeParameters'
			Select @bUseHistoricalRates as USEHISTEXCH, @pdtTransactionDate AS TRANSDATE, @pdtExchTransDate AS EXCHTRANSDATE 
		End

		If (@nErrorCode = 0)
		Begin
			exec @nErrorCode = dbo.ac_GetExchangeDetails
                                @pnBankRate		= @nBankRate output,
				@pnBuyRate		= @nBuyRate output,
				@pnSellRate		= @nSellRate output,
				@pnDecimalPlaces	= @nForeignDecimalPlaces output,
				@pnUserIdentityId	= @pnUserIdentityId,
				@pbCalledFromCentura	= @pbCalledFromCentura,
				@psCurrencyCode		= @psCurrencyCode,
				@pdtTransactionDate	= @pdtExchTransDate,
				@pbUseHistoricalRates	= @bUseHistoricalRates,
				@pnCaseID		= @pnCaseKey,
				@pnNameNo		= @nExchDetailsNameKey,
				@pbIsSupplier		= @bIsSupplier,
				@psWIPTypeId 		= @sWIPTypeKey


			If @pbDebug = 1
			Begin
				Print 'ac_GetExchangeDetails'
				Select @nBankRate       AS BANKRATE,
                                @nBuyRate	        AS BUYRATE,
				@nSellRate		AS SELLRATE,
				@nForeignDecimalPlaces	AS FOREIGNDECIMALPLACES,
				@psCurrencyCode		AS CURRENCYCODE,
				@pdtExchTransDate	AS TRANSDATE,
				@bUseHistoricalRates	AS USEHISTRATES,
				@pnCaseKey		AS CASEID,
				@nExchDetailsNameKey	AS CASENAME,
				@bIsSupplier		AS ISSUPPLIER,
				@sWIPTypeKey		as WIPTYPEID
			End
		End	


		If @nErrorCode = 0
		Begin
			-- use supplied pre-margin values
			If @pbUseSuppliedValues = 1
			Begin
				If ((@pnForeignValueBeforeMargin is null) or (@pnLocalValueBeforeMargin is null) or (@pnLocalValueBeforeMargin = 0) or (@psCurrencyCode is null))
				Begin
			  		Set @sAlertXML = dbo.fn_GetAlertXML('AC17', 'Both local and foreign values must be supplied.',
			    						null, null, null, null, null)
			  		RAISERROR(@sAlertXML, 14, 1)
			  		Set @nErrorCode = @@ERROR
				End
				Else
				Begin
					Set @pnExchangeRate = round((round (@pnForeignValueBeforeMargin,@nForeignDecimalPlaces) / round(@pnLocalValueBeforeMargin, @nLocalDecimalPlaces)),4)
				End
			End
			Else If @bUseSellRate = 1
			Begin
				If isnull(@nSellRate,0) = 0
				Begin
			  		Set @sAlertXML = dbo.fn_GetAlertXML('AC5', 'Sell Rate is not available for currency {0}.',
			    						@psCurrencyCode, null, null, null, null)
			  		RAISERROR(@sAlertXML, 14, 1)
			  		Set @nErrorCode = @@ERROR
				End
				Else
				Begin
					Set @pnExchangeRate = @nSellRate
				End
			End
                        Else If @bUseBankRate = 1
			Begin
				If isnull(@nBankRate,0) = 0
				Begin
			  		Set @sAlertXML = dbo.fn_GetAlertXML('AC234', 'Bank Rate is not available for currency {0}.',
			    						@psCurrencyCode, null, null, null, null)
			  		RAISERROR(@sAlertXML, 14, 1)
			  		Set @nErrorCode = @@ERROR
				End
				Else
				Begin
					Set @pnExchangeRate = @nBankRate
				End
			End
			Else
			Begin
				If isnull(@nBuyRate,0) = 0
				Begin
			  		Set @sAlertXML = dbo.fn_GetAlertXML('AC4', 'Buy Rate is not available for currency {0}.',
			    						@psCurrencyCode, null, null, null, null)
			  		RAISERROR(@sAlertXML, 14, 1)
			  		Set @nErrorCode = @@ERROR
				End
				Else
				Begin
					Set @pnExchangeRate = @nBuyRate
				End
			End
		End
	End
End

If @pbDebug = 1
Begin
	Print 'Extract Charge Out = ' + cast(@bExtractChargeOut as nvarchar(10))
	Print 'Extract Discount = ' + cast(@bExtractDiscount as nvarchar(10))
	Print '@sWipCategoryKey = ' + @sWipCategoryKey
	Print '@nChargeRatePerHour = ' + cast(@nChargeRatePerHour as nvarchar(20))
	Print '@nUnitsPerHour = ' + cast(@nUnitsPerHour as nvarchar(20))
	Print '@sChargeCurrencyCode = ' + @sChargeCurrencyCode
	Print '@bIsRoundUp = ' + cast(@bIsRoundUp as nvarchar(20))
	Print '@pbIsServiceCharge = ' + cast(@pbIsServiceCharge as nvarchar(20))
	Print '@nMarginPercent = ' + cast(@nMarginPercent as nvarchar(20))
	Print '@nMarginAmount = ' + cast(@nMarginAmount as nvarchar(20))
	Print '@sMarginCurrencyCode = ' + @sMarginCurrencyCode
	Print '@nMarginCap = ' + cast(@nMarginCap as nvarchar(20))
	Print '@nDiscountPercent = ' + cast(@nDiscountPercent as nvarchar(20))
	Print '@bIsDiscountBasedOnAmount = ' + cast(@bIsDiscountBasedOnAmount as nvarchar(20))
	Print '@nCostPercent1 = ' + cast(@nCostPercent1 as nvarchar(20))
	Print '@nCostPercent2 = ' + cast(@nCostPercent2 as nvarchar(20))
	Print '@nCostRatePerHour1 = ' + cast(@nCostRatePerHour1 as nvarchar(20))
	Print '@nCostRatePerHour2 = ' + cast(@nCostRatePerHour2 as nvarchar(20))
	Print '@nLocalDecimalPlaces = ' + cast(@nLocalDecimalPlaces as nvarchar(20))
	Print '@bUseSellRate = ' + cast(@bUseSellRate as nvarchar(20))
	Print '@bUseHistoricalRates = ' + cast(@bUseHistoricalRates as nvarchar(20))
	Print '@nForeignDecimalPlaces = ' + cast(@nForeignDecimalPlaces as nvarchar(20))
End

-- Calculate Time
If @nErrorCode = 0
and (@pdtHours is not null or 
     @pnTimeUnits is not null)
Begin
	Set @pnUnitsPerHour = @nUnitsPerHour
	
	If isnull(@pbCalledFromCentura,0)=0 
		and @nChargeRatePerHour is null and 
		exists (Select 1 from SITECONTROL where CONTROLID = 'Rate mandatory on time items' and COLBOOLEAN = 1)
	Begin
		Set @pnChargeOutRate = null 
	End
	else
	Begin
		-- RFC41055 we need to differentiate between zero and null (0=Zero-rated charge, null=no valid charge rate).
		--Set @pnChargeOutRate = isnull(@nChargeRatePerHour,0)
		Set @pnChargeOutRate = @nChargeRatePerHour
	End

	-- Calculate units
	If (@pdtHours is not null
	and @pnTimeUnits is null)
	Begin
	
		If isnull(@pbCalledFromCentura,0)=0 
		and exists (Select 1 from SITECONTROL where CONTROLID = 'Consider Secs in Units Calc.' and COLBOOLEAN = 1)
		Begin
			Set @nDecimalUnits = cast(((isnull(DATEPART(HOUR,@pdtHours ),0) * 60)
						  + isnull(DATEPART(MINUTE, @pdtHours),0) 
						  + (cast(isnull(DATEPART(SECOND, @pdtHours),0) as decimal) / 60)) 
						* @nUnitsPerHour
					     as float)
					     /60
		End
		else
		Begin
			Set @nDecimalUnits = cast(((isnull(DATEPART(HOUR,@pdtHours ),0) * 60)
						  + isnull(DATEPART(MINUTE, @pdtHours),0)) 
						* @nUnitsPerHour
					     as float)
					     /60
		End
		If @pbDebug = 1
		Begin
			Print '@nDecimalUnits = ' + cast(@nDecimalUnits as nvarchar(15))
		End

		If @bIsRoundUp = 1
		Begin
			-- If there is a decimal portion, round up to the next whole unit
			Set @pnTimeUnits = ceiling(@nDecimalUnits)
		End
		Else
		Begin
			Set @pnTimeUnits = round(@nDecimalUnits,0)
		End
	End

	-- Calculate hours
	If (@pdtHours is null
	and @pnTimeUnits is not null)
	Begin
		Set @nHours = round((@pnTimeUnits / @nUnitsPerHour),0,1) -- truncated
		Set @nMinutes = (@pnTimeUnits * 60 / @nUnitsPerHour) - (@nHours * 60)

		If @pbDebug = 1
		Begin
			Print 'Hours string = ' + '01-JAN-1899 ' + cast(@nHours as nvarchar)+':'+cast(@nMinutes as nvarchar)
		End
		-- Centura stores with date 01-JAN-1899
		-- SQA13126
		If (@pdtHours < 24)
		Begin
			Set @pdtHours = convert(datetime, '18990101 ' + cast(@nHours as nvarchar)+':'+cast(@nMinutes as nvarchar),108)
		End
		Else
		Begin
			Set @pdtHours = null
		End
	End
End

-- Calculate time value if user has not already supplied it
If @nErrorCode = 0
and @pnTimeUnits > 0
and @pnLocalValueBeforeMargin is null
and @pnForeignValueBeforeMargin is null
Begin
	If @psCurrencyCode is null
	Begin
		Set @pnLocalValueBeforeMargin = 
			round((@pnTimeUnits * @pnChargeOutRate * @nDebtorPercent
				 / @nUnitsPerHour),
				@nLocalDecimalPlaces)
	End
	Else
	Begin
		Set @pnForeignValueBeforeMargin = 
			round((@pnTimeUnits * @pnChargeOutRate * @nDebtorPercent
				 / @nUnitsPerHour),
				@nForeignDecimalPlaces)
		Set @pnLocalValueBeforeMargin = 
			round((@pnForeignValueBeforeMargin / @pnExchangeRate),
				@nLocalDecimalPlaces)
	End	
End

-- Calculate values before margin
Else If @nErrorCode = 0
and (@pbUseSuppliedValues = 0)
Begin
	If @pbDebug = 1
	Begin
		Print '@pnLocalValueBeforeMargin before = ' + cast(@pnLocalValueBeforeMargin as nvarchar(10))
		Print '@pnForeignValueBeforeMargin before = ' + cast(@pnForeignValueBeforeMargin as nvarchar(10))
	End

	-- Note: these values may have been supplied by the user
	If @pnForeignValueBeforeMargin is not null
	Begin
		Set @pnForeignValueBeforeMargin = round(@pnForeignValueBeforeMargin,@nForeignDecimalPlaces)
		-- If both foreign and local have been supplied, foreign takes precedence
		Set @pnLocalValueBeforeMargin = round((@pnForeignValueBeforeMargin / @pnExchangeRate),@nLocalDecimalPlaces)
	End
	Else If @pnLocalValueBeforeMargin is not null
	Begin
		Set @pnLocalValueBeforeMargin = round(@pnLocalValueBeforeMargin,@nLocalDecimalPlaces)

		If @pnForeignValueBeforeMargin is null
		and @psCurrencyCode is not null
		Begin
			Set @pnForeignValueBeforeMargin = round((@pnLocalValueBeforeMargin * @pnExchangeRate),@nForeignDecimalPlaces)
		End

	End

	If @pnLocalValueBeforeMargin is null
	and @pnForeignValueBeforeMargin is not null
	Begin
		Set @pnLocalValueBeforeMargin = round((@pnForeignValueBeforeMargin / @pnExchangeRate),@nLocalDecimalPlaces)
	End
End

If @pbDebug = 1
Begin
	Print '@pnLocalValueBeforeMargin = ' + cast(@pnLocalValueBeforeMargin as nvarchar(10))
	Print '@pnForeignValueBeforeMargin = ' + cast(@pnForeignValueBeforeMargin as nvarchar(10))
End

-- Calculate Margin
If @nErrorCode = 0
and @pbMarginRequired = 1
and @pnLocalValueBeforeMargin != 0
and (@nMarginPercent is not null or
     @nMarginAmount is not null)
Begin

	Set @nValueBeforeMargin = ISNULL(@pnForeignValueBeforeMargin,@pnLocalValueBeforeMargin)

	exec @nErrorCode = dbo.pt_CalculateMargin 
				@prnMarginValue 	= @pnMarginValue OUTPUT, 
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= null, 
				@pbServiceCharge	= @pbIsServiceCharge, 
				@pnWIPAmount		= @nValueBeforeMargin,
				@psWIPCurrency		= @psCurrencyCode, 
				@pnWIPExchRate		= @pnExchangeRate, 
				@pnMarginPercentage	= @nMarginPercent, 
				@pnMarginAmount		= @nMarginAmount, 
				@psMarginCurrency	= @sMarginCurrencyCode, 
				@pnWIPDecimalPlaces	= @nForeignDecimalPlaces, 
				@pdtTransactionDate	= @pdtTransactionDate,
				@pbCalledFromCentura	= @pbCalledFromCentura, 
				@psWIPCategoryKey	= @sWipCategoryKey, 
				@pnNameKey		= @nExchDetailsNameKey, 
				@pnCaseKey		= @pnCaseKey, 
				@pbDebug		= @pbDebug,
				@pnSupplierKey 		= @pnSupplierKey,
				@pbAgentItem		= @bIsSupplier,
				@pnMarginCap		= @nMarginCap

	-- Calculate values after margin
	If @nErrorCode = 0
	and @pnMarginValue is not null
	Begin
		If @psCurrencyCode is not null
		Begin
			Set @pnForeignValue = @pnForeignValueBeforeMargin + @pnMarginValue
			Set @pnLocalValue = round((@pnForeignValue / @pnExchangeRate),@nLocalDecimalPlaces)
		End
		Else
		Begin
			Set @pnLocalValue = @pnLocalValueBeforeMargin + @pnMarginValue
		End
	End
End
Else
Begin
	Set @pnForeignValue = @pnForeignValueBeforeMargin
	Set @pnLocalValue = @pnLocalValueBeforeMargin
End

-- Discounts
If @nErrorCode = 0
and @pnLocalValueBeforeMargin != 0
and @nDiscountPercent is not null 
Begin
	If @psCurrencyCode is null
	Begin
		Set @pnLocalDiscount = round((case 	when @bIsDiscountBasedOnAmount = 1
							then @pnLocalValueBeforeMargin
							else @pnLocalValue
							end
						* @nDiscountPercent/100),
						@nLocalDecimalPlaces)
	End
	Else
	Begin
		Set @pnForeignDiscount = round((case 	when @bIsDiscountBasedOnAmount = 1
							then @pnForeignValueBeforeMargin
							else @pnForeignValue
							end
						* @nDiscountPercent/100),
						@nForeignDecimalPlaces)
		Set @pnLocalDiscount = round((@pnForeignDiscount / @pnExchangeRate),@nLocalDecimalPlaces)

	End
End

-- Discount on margin component
If @nErrorCode = 0
and @pnLocalValueBeforeMargin != 0
and @nMarginDiscountPercent is not null 
Begin		
	If @psCurrencyCode is null
	Begin
		Set @pnLocalDiscountForMargin = round((case when @bIsDiscountBasedOnAmount = 1
							then 0
							else (@pnLocalValue - @pnLocalValueBeforeMargin)
							end
						* @nMarginDiscountPercent/100), @nLocalDecimalPlaces)
	End
	Else
	Begin
		Set @pnForeignDiscountForMargin = round((case 	when @bIsDiscountBasedOnAmount = 1
							then 0
							else (@pnForeignValue - @pnForeignValueBeforeMargin)
							end
						* @nMarginDiscountPercent/100), @nForeignDecimalPlaces)
		Set @pnLocalDiscountForMargin = round((@pnForeignDiscountForMargin / @pnExchangeRate),@nLocalDecimalPlaces)

	End
End

-- Discount on pre-margin component
If @nErrorCode = 0
and @pnLocalValueBeforeMargin != 0
and @nDiscountPercent is not null 
Begin
	If @psCurrencyCode is null
	Begin
		Set @pnLocalPreMarginDiscount = round((@pnLocalValueBeforeMargin * @nDiscountPercent/100),
						@nLocalDecimalPlaces)
	End
	Else
	Begin
		Set @pnForeignPreMarginDiscount = round((@pnForeignValueBeforeMargin * @nDiscountPercent/100),
						@nForeignDecimalPlaces)
		Set @pnLocalPreMarginDiscount = round((@pnForeignDiscount / @pnExchangeRate),@nLocalDecimalPlaces)

	End
End

-- Cost Calculation 1
If @nErrorCode = 0
and @pnLocalValue != 0
and (@nCostPercent1 is not null or
     @nCostRatePerHour1 is not null)
Begin
	If @pbIsServiceCharge = 1
	and @nCostRatePerHour1 is not null
	Begin
		Set @pnLocalCost1 = 
			round((isnull(@pnTimeUnits,1) * @nCostRatePerHour1 * @nDebtorPercent
				 / @nUnitsPerHour),
				@nLocalDecimalPlaces)
	End

	If @pbIsServiceCharge = 0
	and @nCostPercent1 is not null
	Begin
		Set @pnLocalCost1 = 
			round((@pnLocalValue * @nCostPercent1 / 100),
				@nLocalDecimalPlaces)

	End
End

-- Cost Calculation 2
If @nErrorCode = 0
and @pnLocalValue != 0
and (@nCostPercent2 is not null or
     @nCostRatePerHour2 is not null)
Begin
	If @pbIsServiceCharge = 1
	and @nCostRatePerHour2 is not null
	Begin
		Set @pnLocalCost2 = 
			round((isnull(@pnTimeUnits,1) * @nCostRatePerHour2 * @nDebtorPercent
				 / @nUnitsPerHour),
				@nLocalDecimalPlaces)
	End

	If @pbIsServiceCharge = 0
	and @nCostPercent2 is not null
	Begin
		Set @pnLocalCost2 = 
			round((@pnLocalValue * @nCostPercent2 / 100),
				@nLocalDecimalPlaces)

	End
End

-- DR-27273
-- R70252
If (@nErrorCode = 0) 
and (@pbCalledFromCentura = 0) 
and (@pbSeparateMarginMode = 0) 
and (@pnChargeOutRate is not null)
Begin
	If (@nMarginPercent > 0)
	Begin
		If (@sChargeCurrencyCode is null)
		Begin
			Set @pnChargeOutRate = round(@pnChargeOutRate *(100 + @nMarginPercent)/100,@nLocalDecimalPlaces)
		End
		Else
		Begin
			Set @pnChargeOutRate = round(@pnChargeOutRate *(100 + @nMarginPercent)/100,@nForeignDecimalPlaces)
		End
	End
	Else If (@nMarginAmount > 0) and (@nHours > 0)	
	Begin
		If (@sChargeCurrencyCode is null)
		Begin
			Set @pnChargeOutRate = round(@pnLocalValue/@nHours,@nLocalDecimalPlaces)
		End
		Else
		Begin
			Set @pnChargeOutRate = round(@pnForeignValue/@nHours,@nForeignDecimalPlaces)
		End
	End
End


If @pbCalledFromCentura = 1
Begin
	Select 	@nErrorCode, 
		@pdtHours,
		@pnTimeUnits,
		@pnUnitsPerHour,
		@pnChargeOutRate,
		@pnLocalValueBeforeMargin,
		@pnForeignValueBeforeMargin,
		@psCurrencyCode,
		@pnExchangeRate,
		@pnLocalValue,
		@pnForeignValue,
		@pnMarginValue,
		@pnLocalDiscount,
		@pnForeignDiscount,
		@pnLocalCost1,
		@pnLocalCost2,
		@pnMarginNo,
		@pnLocalDiscountForMargin,
		@pnForeignDiscountForMargin,
		@pnLocalPreMarginDiscount,
		@pnForeignPreMarginDiscount	
End

Return @nErrorCode
GO

Grant execute on dbo.wp_GetWipCost to public
GO
