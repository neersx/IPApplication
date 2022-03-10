-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ac_DoExchangeDetails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ac_DoExchangeDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ac_DoExchangeDetails.'
	Drop procedure [dbo].[ac_DoExchangeDetails]
End
Print '**** Creating Stored Procedure dbo.ac_DoExchangeDetails...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ac_DoExchangeDetails
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
	@psWIPCategory		nvarchar(2)	= null, -- WIP Category used to determine whether to use historical exchange rate.
	@pnCaseID		int		= null, -- CaseID used to obtain the correct exchange rate variation
	@pnNameNo		int		= null, -- NameNo used to obtain the correct exchange rate variation
	@pbIsSupplier		bit		= 0,    -- Determines whether to get exchange rate variation from CREDITOR/IPNAME when NameNo is supplied
	@pnRoundBilledValues	smallint	= null output,
	@pnAccountingSystemID	int		= null,	-- System Id of the calling application
	@psWIPTypeId		nvarchar(6)	= null	-- The WIP Type ID used in determining the Exch Rate Schedule
)
as
-- PROCEDURE:	ac_DoExchangeDetails
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Wrapper stored procedure for ac_GetExchangeDetails to be used in Centura classes
--
--	Accounting system ids
-- 	1  Inprotech (i.e. charge generation)
--	2  Time and Billing
--	4  Accounts Receivable
-- 	8  Accounts Payable
-- 	16 Cash Book
--	32 General Ledger
--
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 09 Jun 2006	KR	11702	1	Procedure created
-- 27 Jun 2006	KR	12108	2	Added description to the parameters
-- 12 Dec 2006	KR	13982	3 	Added new parameter for round billed values
-- 18 Jan 2007 	CR	12400	4	New parameter to identify the calling application.
-- 24 Jan 2007	CR	12400	5	Removed the If @psWIPCategory is Not Null check as this is no longer the case
-- 21 Dec 2011	AT	R9160	6	Get Exch Rate Schedule from WIP Type if applicable

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @nExchScheduleId int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	-- determine if Historical Exch Rates are required and from which period
	exec @nErrorCode = dbo.ac_GetExchangeParameters
			@pbUseHistoricalRates	= @pbUseHistoricalRates output,
			@pdtTransactionDate	= @pdtTransactionDate output,
			@pnUserIdentityId	= @pnUserIdentityId,
			@pbCalledFromCentura	= @pbCalledFromCentura,
			@psWIPCategory		= @psWIPCategory,
			@pnAccountingSystemID	= @pnAccountingSystemID
			
	If (@nErrorCode = 0)
	Begin
		exec @nErrorCode = dbo.ac_GetExchangeDetails
			@pnBankRate		= @pnBankRate output,
			@pnBuyRate		= @pnBuyRate output,
			@pnSellRate		= @pnSellRate output,
			@pnDecimalPlaces	= @pnDecimalPlaces output,
			@pnUserIdentityId	= @pnUserIdentityId,
			@pbCalledFromCentura	= @pbCalledFromCentura,
			@psCurrencyCode		= @psCurrencyCode,
			@pdtTransactionDate	= @pdtTransactionDate,
			@pbUseHistoricalRates	= @pbUseHistoricalRates,
			@pnCaseID		= @pnCaseID,
			@pnNameNo		= @pnNameNo,
			@pbIsSupplier		= @pbIsSupplier,
			@pnExchScheduleId	= @nExchScheduleId,
			@pnRoundBilledValues	= @pnRoundBilledValues output,
			@psWIPTypeId		= @psWIPTypeId
	End
End

-- Centura has not implemented decimal places yet
If (@nErrorCode = 0) AND (@pbCalledFromCentura = 1)
Begin
	select    	@pnBankRate,
		  	@pnBuyRate,
		  	@pnSellRate,
        		@pnDecimalPlaces,
			@pnRoundBilledValues

End

Return @nErrorCode
GO

Grant execute on dbo.ac_DoExchangeDetails to public
GO
