-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ac_GetExchangeDetails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ac_GetExchangeDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ac_GetExchangeDetails.'
	Drop procedure [dbo].[ac_GetExchangeDetails]
End
Print '**** Creating Stored Procedure dbo.ac_GetExchangeDetails...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ac_GetExchangeDetails
(
	-- All exchange rates relate to local currency;
	-- i.e. LocalAmount * ExchangeRate = ForeignAmount
	@pnBankRate		dec(11,4)	= null output,	-- As supplied by the bank
	@pnBuyRate		dec(11,4)	= null output,	-- Used when buying the currency from the bank; e.g. accounts payable
	@pnSellRate		dec(11,4)	= null output,	-- Used when selling the currency from the bank; e.g. accounts receivable
	@pnDecimalPlaces	tinyint		= null output,  -- The number of decimal places for calculations in this currency
	@pnUserIdentityId	int,		-- Mandatory
	@pbCalledFromCentura	bit		= 0,
	@psCurrencyCode		nvarchar(5)	= null, -- The currency the information is required for
	@pdtTransactionDate	datetime	= null, -- Required for historical exchange rates.
	@pbUseHistoricalRates	bit		= null, -- Indicates historical exchange rate to be used or not
	@pnCaseID		int		= null, -- CaseID used to obtain the correct exchange rate variation
	@pnNameNo		int		= null, -- NameNo used to obtain the correct exchange rate variation
	@pbIsSupplier		bit		= null,	-- Determines whether to get exchange rate variation from CREDITOR/IPNAME when NameNo is supplied
	@psCaseType		nchar(1)	= null,	-- SQA12361 User entered CaseType
	@psCountryCode		nvarchar(3)	= null, -- SQA12361 User entered Country
	@psPropertyType		nchar(1)	= null, -- SQA12361 User entered Property Type
	@psCaseCategory		nvarchar(2)	= null, -- SQA12361 User entered Category
	@psSubType		nvarchar(2)	= null, -- SQA12361 User entered Sub Type
	@pnExchScheduleId	int		= null,	-- SQA12361 User entered Exchange Rate Schedule
	@pnRoundBilledValues	smallint	= null output, -- The Round Billed Values for the Currency.
	@psWIPTypeId		nvarchar(6)	= null
)
as
-- PROCEDURE:	ac_GetExchangeDetails
-- VERSION:	9
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Obtain information necessary for calculations in a foreign currency
--
--		Exchange Rate priority:
--		1. Exchange Variation
--		2. Historical Rate
--		3. Standard Exch Rate

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19 Jun 2005	JEK	RFC2629	1	Procedure created 
-- 14 Jun 2006	KR	11702	2	added call to ac_GetExchangeVariation and 
--			12108		added code to determine historical exchange rate based on wipcategory
-- 23 Jun 2006	KR	12108	3	added code to obtain Debtor if applicable when not provided.
-- 27 Jun 2006	KR	12108	4	Added description to the parameters and fixed a few problems realted to supplier.
-- 06 Jul 2006	MF	12361	5	Allow user entered parameter to be used.
-- 12 Dec 2006	KR	13982	6	Added new parameter @pnRoundBilledValues
-- 18 Jan 2007	CR	12400	7	Updated call to ac_GetExchangeVariation to not include @pnDecimalPlaces.
--					Also removed some redundant repeated code. 
-- 27 Aug 2008	vql	16155	8	Fee calculation logic needs to be changed to handle lack of historical exchange rate data.
-- 20 Dec 2011	AT	R9160	9	Add WIP Type for exch rate variation calculation.
--					Simplified logic using isnull.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(4000)


-- Initialise variables
Set @nErrorCode = 0

If (@nErrorCode=0)
Begin
	exec @nErrorCode = dbo.ac_GetExchangeVariation
				@pnBankRate		= @pnBankRate output,
				@pnBuyRate		= @pnBuyRate output,
				@pnSellRate		= @pnSellRate output,
				@pnUserIdentityId	= @pnUserIdentityId,
				@pbCalledFromCentura	= @pbCalledFromCentura,
				@psCurrencyCode		= @psCurrencyCode,
				@pdtTransactionDate	= @pdtTransactionDate,
				@pnCaseID		= @pnCaseID,
				@pnNameNo		= @pnNameNo,
				@pbIsSupplier		= @pbIsSupplier,
				@psCaseType     	= @psCaseType,
				@psCountryCode		= @psCountryCode,
				@psPropertyType		= @psPropertyType,
				@psCaseCategory		= @psCaseCategory,
				@psSubType		= @psSubType,
				@pnExchScheduleId	= @pnExchScheduleId,
				@psWIPTypeId		= @psWIPTypeId
	
End

If @nErrorCode = 0
Begin
	If @pbUseHistoricalRates = 1
	Begin
		Set @sSQLString = "
		Select  @pnDecimalPlaces = isnull(DECIMALPLACES,2),
			@pnBankRate = dbo.fn_GetHistExchRate(@pdtTransactionDate, @psCurrencyCode, 1),
			@pnBuyRate = isnull(@pnBuyRate, dbo.fn_GetHistExchRate(@pdtTransactionDate, @psCurrencyCode, 2)),
			@pnSellRate = isnull(@pnSellRate, dbo.fn_GetHistExchRate(@pdtTransactionDate, @psCurrencyCode, 4)),
			@pnRoundBilledValues = ROUNDBILLEDVALUES
		from	CURRENCY C
		where	C.CURRENCY = @psCurrencyCode"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@psCurrencyCode	nvarchar(3),
						  @pdtTransactionDate	datetime,
						  @pnDecimalPlaces	tinyint			OUTPUT,
						  @pnBankRate		dec(11,4)		OUTPUT,
						  @pnBuyRate		dec(11,4)		OUTPUT,
						  @pnSellRate		dec(11,4)		OUTPUT,
						  @pnRoundBilledValues	smallint		OUTPUT',
						  @psCurrencyCode	= @psCurrencyCode,
						  @pdtTransactionDate	= @pdtTransactionDate,
						  @pnDecimalPlaces	= @pnDecimalPlaces	OUTPUT,
						  @pnBankRate		= @pnBankRate		OUTPUT,
						  @pnBuyRate		= @pnBuyRate		OUTPUT,
						  @pnSellRate		= @pnSellRate		OUTPUT,
						  @pnRoundBilledValues	= @pnRoundBilledValues	OUTPUT
	End
	Else
	Begin
		Set @sSQLString = "
		Select  @pnDecimalPlaces = isnull(C.DECIMALPLACES,2),
			@pnBankRate = C.BANKRATE,
			@pnBuyRate = isnull(@pnBuyRate, C.BUYRATE),
			@pnSellRate = isnull(@pnSellRate, C.SELLRATE),
			@pnRoundBilledValues = ROUNDBILLEDVALUES
		from	CURRENCY C
		where	C.CURRENCY = @psCurrencyCode"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@psCurrencyCode	nvarchar(3),
						  @pnDecimalPlaces	tinyint			OUTPUT,
						  @pnBankRate		dec(11,4)		OUTPUT,
						  @pnBuyRate		dec(11,4)		OUTPUT,
						  @pnSellRate		dec(11,4)		OUTPUT,	
						  @pnRoundBilledValues	smallint		OUTPUT',
						  @psCurrencyCode	= @psCurrencyCode,
						  @pnDecimalPlaces	= @pnDecimalPlaces	OUTPUT,
						  @pnBankRate		= @pnBankRate		OUTPUT,
						  @pnBuyRate		= @pnBuyRate		OUTPUT,
						  @pnSellRate		= @pnSellRate		OUTPUT,
						  @pnRoundBilledValues	= @pnRoundBilledValues	OUTPUT
	End
End

-- Centura has not implemented decimal places yet
If @pbCalledFromCentura = 1
Begin
	Set @pnDecimalPlaces = 2
End

Return @nErrorCode
GO

Grant execute on dbo.ac_GetExchangeDetails to public
GO
