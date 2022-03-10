-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pt_CalculateMargin
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[pt_CalculateMargin]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.pt_CalculateMargin.'
	Drop procedure [dbo].[pt_CalculateMargin]
End
Print '**** Creating Stored Procedure dbo.pt_CalculateMargin...'
Print ''
go


SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE dbo.pt_CalculateMargin
	@prnMarginValue		decimal(12,2)	output, -- The calculated margin
	@pnUserIdentityId	int,			-- included for use by .NET.
	@psCulture		nvarchar(10)	= null,	-- the language in which output is to be expressed.
	@pbServiceCharge	bit		= 0,	-- Whether the fee is a service charge or not
	@pnWIPAmount		decimal(12,2)	= 0,	
	@psWIPCurrency		nvarchar(3)	= null,	-- If not specified assume local
	@pnWIPExchRate		decimal(12,4)	= 1,	-- Exchange Rate of the WIP item. Use to convert local margin values to WIP Currency
	@pnMarginPercentage	decimal(12,2)	= null,	-- Amount OR Percentage must be passed
	@pnMarginAmount 	decimal(12,2)	= null,	-- Amount OR Percentage must be passed
	@psMarginCurrency	nvarchar(3)	= null,	-- Must be specified with @pnMarginAmount
	@pnWIPDecimalPlaces	int		= 2,
	@pdtTransactionDate	datetime	= null, -- Transaction date to be used to obtain historical exchange rate
	@pbCalledFromCentura	bit		= 0,
	@psWIPCategoryKey	nvarchar(2)	= null,	-- WIP Category for which the exchange rate to be determined.
	@pnNameKey		int		= null,	-- Only required if CaseKey not provided
	@pnCaseKey		int		= null,
	@psCaseType		nchar(1)	= null,	-- SQA12361 User entered CaseType
	@psCountryCode		nvarchar(3)	= null, -- SQA12361 User entered Country
	@psPropertyType		nchar(1)	= null, -- SQA12361 User entered Property Type
	@psCaseCategory		nvarchar(2)	= null, -- SQA12361 User entered Category
	@psSubType		nvarchar(2)	= null, -- SQA12361 User entered Sub Type
	@pnExchScheduleId	int		= null,	-- SQA12361 User entered Exchange Rate Schedule
	@pbDebug		bit		= 0,
	@pnSupplierKey		int		= null,
	@pbAgentItem		bit		= 0,
	@pnMarginCap	decimal(12,2)	= null, -- local currency (SQA18298)
	@psWIPTypeKey	nvarchar(6)	= null

AS
-- PROCEDURE:	pt_CalculateMargin
-- VERSION:	12
-- SCOPE:	Includes logic to convert foreign currency Amounts using default, 
--		Historical or Variations of exchange rates.
-- DESCRIPTION:	Calculates the margin based on either the Margin Amount or the 
--		Margin Percentage (whichever is supplied), returning the margin amount
-- 		in the requested WIP currency. 

-- MODIFICATIONS:
-- Date		Who	No.	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 13/05/2004	JB	SQA9917	1	Procedure created
-- 23 Mar 2006	JB	12378	2	New parameter to return local or fee currency
-- 29 Dec 2006	CR	13955	3	Extended to make use of Historical Exchange Rate 
--					and Exchange Rate Variations where applicable
-- 01 May 2006	MF	12439	4	Margin was not being calculated if the @pnWIPDecimalPlaces
--					was being explicitly passed with a null value.
-- 31 Aug 2007	CR	15276	5	Added additional Case Detail Parameters
-- 26 Sep 2007	KR	15076	6	Added code to initialise margin currecncy to null if it is the same as home currency.
-- 16 Oct 2007	CR	15383	7	Added new Agent Item parameter to indicate when an Agent Item is being processed.
-- 15 Dec 2008	MF	17136	8	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID	
-- 24 Feb 2010	Dw	18298	9	Added new parameter @pnMarginCap
-- 22 Dec 2011	AT	R9160	10	Added WIP Type in get exch rate logic
-- 20 Oct 2015  MS      R53933  11      Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols
-- 08 Jul 2019  MS      DR49444 12      Use bank rate for conversions to local currency if site control 'Bank Rate In Use for Service Charges' is true

Set NOCOUNT ON
Set CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare	@sSQLString		nvarchar(4000)
Declare	@bUseHistoricalRates	bit
Declare	@nBuyRate		dec(11,4)
Declare	@nSellRate		dec(11,4)
Declare	@sAlertXML		nvarchar(400)
Declare	@bUseSellRate		bit
Declare	@bIsSupplier		bit
Declare	@nMarginExchangeRate	decimal(11,4)
Declare	@nLocalDecimalPlaces	int
Declare	@sHomeCurrency		nvarchar(254)
Declare	@nExchDetailNameKey	int
Declare	@nSupplier		int
Declare	@nRowCount		int
declare @bUseBankRate           bit
declare @nBankRate              dec(11,4)

Set @nErrorCode = 0

-- SQA12439
-- Explicitly set the decimal places to 2
-- if null is passed in this parameter.
If @pnWIPDecimalPlaces is null
	Set @pnWIPDecimalPlaces=2

If @pnWIPExchRate is null
	Set @pnWIPExchRate=1

Set @sSQLString = "
select  @nLocalDecimalPlaces = case when W.COLBOOLEAN = 1 then 0 else isnull(CY.DECIMALPLACES,2) end
from	SITECONTROL C
left join CURRENCY CY	on (CY.CURRENCY = C.COLCHARACTER
			-- Decimal places implemented in Centura
			and isnull(@pbCalledFromCentura,0) = 0 )
left join SITECONTROL W on (W.CONTROLID = 'Currency Whole Units')
WHERE 	C.CONTROLID = 'CURRENCY'"

exec @nErrorCode=sp_executesql @sSQLString,
		N'@pbCalledFromCentura	bit,
		  @nLocalDecimalPlaces	tinyint			OUTPUT',
		  @pbCalledFromCentura 	= @pbCalledFromCentura,
		  @nLocalDecimalPlaces	= @nLocalDecimalPlaces	OUTPUT

Set @sSQLString = "
Select  @sHomeCurrency = COLCHARACTER
from	SITECONTROL C
WHERE 	C.CONTROLID = 'CURRENCY'"

exec @nErrorCode=sp_executesql @sSQLString,
		N'@sHomeCurrency	nvarchar(254)	OUTPUT',
		@sHomeCurrency	= @sHomeCurrency	OUTPUT

If @nErrorCode=0
Begin
	--Set Margin Currency to null if it is the same as Home Currency.
	If (@psMarginCurrency = @sHomeCurrency)
	Begin
		Set @psMarginCurrency = NULL
	End

	-- Always use sell rate for services
	If @pbServiceCharge = 1
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

If @nErrorCode=0
Begin
	If @pnMarginPercentage is not null
	Begin
		If @psWIPCurrency is null
		Begin
			Set @prnMarginValue = round((@pnWIPAmount*@pnMarginPercentage/100),@nLocalDecimalPlaces)
			-- 18298 @prnMarginValue & @pnMarginCap both in local currency
			If @prnMarginValue > @pnMarginCap
			Begin
				Set @prnMarginValue = @pnMarginCap
			End
		End
		Else
		Begin
			Set @prnMarginValue = round((@pnWIPAmount*@pnMarginPercentage/100),@pnWIPDecimalPlaces)
			-- 18298 @prnMarginValue is in WIP currency so convert Margin Cap to same currency
			Set @pnMarginCap = round((@pnMarginCap*@pnWIPExchRate),@pnWIPDecimalPlaces)
			If @prnMarginValue > @pnMarginCap
			Begin
				Set @prnMarginValue = @pnMarginCap
			End
		End

	End
	Else If @pnMarginAmount is not null
	Begin
		-- Same currency
		If @psWIPCurrency = @psMarginCurrency
		or (@psWIPCurrency is null and
		    @psMarginCurrency is null)
		Begin
			Set @prnMarginValue = round(@pnMarginAmount,
						case when @psWIPCurrency is null 
						then @nLocalDecimalPlaces 
						else @pnWIPDecimalPlaces end)
						
		End
		-- Margin in local convert to WIP Currency
		Else If @psMarginCurrency is null
		Begin
			Set @prnMarginValue = round((@pnMarginAmount*@pnWIPExchRate),@pnWIPDecimalPlaces)
		End
		-- Margin is in a different foreign currency
		Else
		Begin
			-- Figure out if Exchange Details should be retrieved from CREDITOR or IPNAME
			If ( @pbAgentItem = 1 ) AND ( @pnSupplierKey IS NOT NULL )
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
					Set @nExchDetailNameKey = @pnSupplierKey
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
						Set @nExchDetailNameKey = @pnSupplierKey
						Set @bIsSupplier = 0
					End
				End
			End
			Else
			Begin
				Set @nExchDetailNameKey = @pnNameKey
				Set @bIsSupplier = 0
			End

			
			--Get parameters required by ac_GetExchangeDetails for the given WIPCategory
			--NOTE: Doesn't matter that @pdtTransactionDate is used here as this is not 
			--saved to the database. 
			exec @nErrorCode = dbo.ac_GetExchangeParameters
			@pbUseHistoricalRates	= @bUseHistoricalRates output,
			@pdtTransactionDate	= @pdtTransactionDate output,
			@pnUserIdentityId	= @pnUserIdentityId,
			@pbCalledFromCentura	= @pbCalledFromCentura,
			@psWIPCategory		= @psWIPCategoryKey,
			@pnAccountingSystemID	= 2 --	2  Time and Billing
			
			If @pbDebug = 1
			Begin
				Select @bUseHistoricalRates AS USEHISTEXCHRATE, 
					@pdtTransactionDate AS TRANSDATE, 
					@psWIPCategoryKey AS WIPCATEGORY
			End
			
			If (@nErrorCode = 0)
			Begin
			-- Get exchange details
			exec @nErrorCode = dbo.ac_GetExchangeDetails
                                @pnBankRate		= @nBankRate output,
				@pnBuyRate		= @nBuyRate output,
				@pnSellRate		= @nSellRate output,
				@pnUserIdentityId	= @pnUserIdentityId,
				@pbCalledFromCentura	= @pbCalledFromCentura,
				@psCurrencyCode		= @psMarginCurrency,
				@pdtTransactionDate	= @pdtTransactionDate,
				@pbUseHistoricalRates	= @bUseHistoricalRates,
				@pnCaseID		= @pnCaseKey,
				@pnNameNo		= @nExchDetailNameKey,
				@pbIsSupplier		= @bIsSupplier,
				@psCaseType     	= @psCaseType,
				@psCountryCode		= @psCountryCode,
				@psPropertyType		= @psPropertyType,
				@psCaseCategory		= @psCaseCategory,
				@psSubType		= @psSubType,
				@pnExchScheduleId	= @pnExchScheduleId,
				@psWIPTypeId		= @psWIPTypeKey
			End
			
			If @pbDebug = 1
			Begin
				Select @nBankRate       AS BANKRATE,
                                @nBuyRate 	        AS BUYRATE,
				@nSellRate 		AS SELLRATE,
				@psMarginCurrency 	AS MARGINCURRENCY,
				@pdtTransactionDate 	AS TRANSDATE,
				@bUseHistoricalRates	AS USEHISTRATE,
				@pnCaseKey 		AS CASEID,
				@pnNameKey 		AS DEBTORNO,
				@bIsSupplier 		AS ISSUPPLIER,
				@psCaseType     	AS CaseType,
				@psCountryCode		AS CountryCode,
				@psPropertyType		AS PropertyType,
				@psCaseCategory		AS CaseCategory,
				@psSubType		AS SubType,
				@pnExchScheduleId	AS ExchScheduleId,
				@psWIPTypeKey		AS WIPTYPE
			End
			
			If @nErrorCode = 0
			Begin
				If @bUseSellRate = 1
				Begin
					If isnull(@nSellRate,0) = 0
					Begin
				  		Set @sAlertXML = dbo.fn_GetAlertXML('AC5', 'Sell Rate is not available for currency {0}.',
				    						@psMarginCurrency, null, null, null, null)
				  		RAISERROR(@sAlertXML, 14, 1)
				  		Set @nErrorCode = @@ERROR
					End
					Else
					Begin
						Set @nMarginExchangeRate = @nSellRate
					End
				End
                                Else If @bUseBankRate = 1
			        Begin
				        If isnull(@nBankRate,0) = 0
				        Begin
			  		        Set @sAlertXML = dbo.fn_GetAlertXML('AC234', 'Bank Rate is not available for currency {0}.',
			    						        @psMarginCurrency, null, null, null, null)
			  		        RAISERROR(@sAlertXML, 14, 1)
			  		        Set @nErrorCode = @@ERROR
				        End
				        Else
				        Begin
					        Set @nMarginExchangeRate = @nBankRate
				        End
			        End
				Else
				Begin
					If isnull(@nBuyRate,0) = 0
					Begin
				  		Set @sAlertXML = dbo.fn_GetAlertXML('AC4', 'Buy Rate is not available for currency {0}.',
				    						@psMarginCurrency, null, null, null, null)
				  		RAISERROR(@sAlertXML, 14, 1)
				  		Set @nErrorCode = @@ERROR
					End
					Else
					Begin
						Set @nMarginExchangeRate = @nBuyRate
					End
				End
			End
					
			If @pbDebug = 1
			Begin
				Print 'Margin @nBuyRate = ' + cast(@nBuyRate as nvarchar(10))
				Print 'Margin @nSellRate = ' + cast(@nSellRate as nvarchar(10))
				Print 'Margin @nBankRate = ' + cast(@nBankRate as nvarchar(10))
				Print '@nMarginExchangeRate = ' + cast(@nMarginExchangeRate as nvarchar(10))
			End
			
			-- Value is local or margin should be in local
			If @nErrorCode = 0
			and @psWIPCurrency is null -- or @pbFixedInLocal = 1
			Begin
				Set @prnMarginValue = round((@pnMarginAmount/@nMarginExchangeRate),
							@nLocalDecimalPlaces)
			End
			-- Both margin and value are foreign
			Else
			Begin
							-- First convert to local
				Set @prnMarginValue = round((@pnMarginAmount/@nMarginExchangeRate
							-- then to foreign value currency
							* @pnWIPExchRate),
							-- then round
							@pnWIPDecimalPlaces)
			End
		End		
	End
End


Return @nErrorCode
GO

Grant execute on dbo.pt_CalculateMargin to public
GO