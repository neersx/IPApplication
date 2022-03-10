-- Set up Japanese currency
DELETE FROM EXCHANGERATEHIST WHERE CURRENCY='JPY' AND DATEEFFECTIVE>'09-JAN-2005'

UPDATE 	CURRENCY
SET 	BANKRATE = 69.1234,
	BUYFACTOR = 1.02,
	BUYRATE = BANKRATE * BUYFACTOR,
	SELLFACTOR = 1.2,
	SELLRATE = BANKRATE * SELLFACTOR,
	DATECHANGED = '10-JAN-2005',
	DECIMALPLACES = 0
WHERE 	CURRENCY = 'JPY'

-- Set up historical rates
INSERT INTO EXCHANGERATEHIST
	(CURRENCY,DATEEFFECTIVE, BANKRATE, BUYFACTOR, BUYRATE, SELLFACTOR, SELLRATE)
SELECT CURRENCY,DATECHANGED, BANKRATE, BUYFACTOR, BUYRATE, SELLFACTOR, SELLRATE
FROM CURRENCY
WHERE CURRENCY = 'JPY'

UPDATE 	CURRENCY
SET 	BANKRATE = 75.1234,
	BUYFACTOR = 1.02,
	BUYRATE = BANKRATE * BUYFACTOR,
	SELLFACTOR = 1.2,
	SELLRATE = BANKRATE * SELLFACTOR,
	DATECHANGED = '20-JAN-2005',
	DECIMALPLACES = 0
WHERE 	CURRENCY = 'JPY'

-- Set up historical rates
INSERT INTO EXCHANGERATEHIST
	(CURRENCY,DATEEFFECTIVE, BANKRATE, BUYFACTOR, BUYRATE, SELLFACTOR, SELLRATE)
SELECT CURRENCY,DATECHANGED, BANKRATE, BUYFACTOR, BUYRATE, SELLFACTOR, SELLRATE
FROM CURRENCY
WHERE CURRENCY = 'JPY'

DECLARE @RC int
DECLARE @pnBankRate decimal(11,4)
DECLARE @pnBuyRate decimal(11,4)
DECLARE @pnSellRate decimal(11,4)
DECLARE @pnDecimalPlaces tinyint
DECLARE @pnUserIdentityId int
DECLARE @pbCalledFromCentura bit
DECLARE @psCurrencyCode nvarchar(5)
DECLARE @pdtTransactionDate datetime
DECLARE @pbUseHistoricalRates bit

-- Test 1
-- Decimal Places not default
-- Historical exchange rates
SELECT @pnBankRate = NULL
SELECT @pnBuyRate = NULL
SELECT @pnSellRate = NULL
SELECT @pnDecimalPlaces = NULL
SELECT @pnUserIdentityId = 5
SELECT @pbCalledFromCentura = 0
SELECT @psCurrencyCode = N'JPY'
SELECT @pdtTransactionDate = '20-JAN-2005 1:00pm'
SELECT @pbUseHistoricalRates = 1
EXEC @RC = [dbo].[ac_GetExchangeDetails] @pnBankRate OUTPUT , @pnBuyRate OUTPUT , @pnSellRate OUTPUT , @pnDecimalPlaces OUTPUT , @pnUserIdentityId, @pbCalledFromCentura, @psCurrencyCode, @pdtTransactionDate, @pbUseHistoricalRates
DECLARE @PrnLine nvarchar(4000)
PRINT 'Stored Procedure: IPMine.dbo.ac_GetExchangeDetails'
SELECT @PrnLine = '	Return Code = ' + CONVERT(nvarchar, @RC)
PRINT @PrnLine
print 'JPY: Historical exchange rates effective 20-JAN-2005 1:00pm (time ignored)'
print 'Bank: 75.1234, Buy: 70.5059, Sell 82.9481, Decimal Places: 0'
PRINT '	Output Parameter(s): '
SELECT @PrnLine = '		@pnBankRate = ' + isnull( CONVERT(nvarchar, @pnBankRate), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnBuyRate = ' + isnull( CONVERT(nvarchar, @pnBuyRate), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnSellRate = ' + isnull( CONVERT(nvarchar, @pnSellRate), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnDecimalPlaces = ' + isnull( CONVERT(nvarchar, @pnDecimalPlaces), '<NULL>' )
PRINT @PrnLine
-- Test 2
-- Historical effective dates
-- Called from Centura
SELECT @pnBankRate = NULL
SELECT @pnBuyRate = NULL
SELECT @pnSellRate = NULL
SELECT @pnDecimalPlaces = NULL
SELECT @pnUserIdentityId = 5
SELECT @pbCalledFromCentura = 1
SELECT @psCurrencyCode = N'JPY'
SELECT @pdtTransactionDate = '21-JAN-2005'
SELECT @pbUseHistoricalRates = 1
EXEC @RC = [dbo].[ac_GetExchangeDetails] @pnBankRate OUTPUT , @pnBuyRate OUTPUT , @pnSellRate OUTPUT , @pnDecimalPlaces OUTPUT , @pnUserIdentityId, @pbCalledFromCentura, @psCurrencyCode, @pdtTransactionDate, @pbUseHistoricalRates

PRINT 'Stored Procedure: IPMine.dbo.ac_GetExchangeDetails'
SELECT @PrnLine = '	Return Code = ' + CONVERT(nvarchar, @RC)
PRINT @PrnLine
print 'JPY: Historical exchange rates effective 21-JAN-2005 Centura'
print 'Bank: 75.1234, Buy: 70.5059, Sell 82.9481, Decimal Places: 2'
PRINT '	Output Parameter(s): '
SELECT @PrnLine = '		@pnBankRate = ' + isnull( CONVERT(nvarchar, @pnBankRate), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnBuyRate = ' + isnull( CONVERT(nvarchar, @pnBuyRate), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnSellRate = ' + isnull( CONVERT(nvarchar, @pnSellRate), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnDecimalPlaces = ' + isnull( CONVERT(nvarchar, @pnDecimalPlaces), '<NULL>' )
PRINT @PrnLine
-- Test 3
-- Historical effective dates
SELECT @pnBankRate = NULL
SELECT @pnBuyRate = NULL
SELECT @pnSellRate = NULL
SELECT @pnDecimalPlaces = NULL
SELECT @pnUserIdentityId = 5
SELECT @pbCalledFromCentura = NULL
SELECT @psCurrencyCode = N'JPY'
SELECT @pdtTransactionDate = '19-JAN-2005'
SELECT @pbUseHistoricalRates = 1
EXEC @RC = [dbo].[ac_GetExchangeDetails] @pnBankRate OUTPUT , @pnBuyRate OUTPUT , @pnSellRate OUTPUT , @pnDecimalPlaces OUTPUT , @pnUserIdentityId, @pbCalledFromCentura, @psCurrencyCode, @pdtTransactionDate, @pbUseHistoricalRates

PRINT 'Stored Procedure: IPMine.dbo.ac_GetExchangeDetails'
SELECT @PrnLine = '	Return Code = ' + CONVERT(nvarchar, @RC)
PRINT @PrnLine
print 'JPY: Historical exchange rates effective 19-JAN-2005'
print 'Bank: 69.1234, Buy: 76.6259, Sell 90.1481, Decimal Places: 0'
PRINT '	Output Parameter(s): '
SELECT @PrnLine = '		@pnBankRate = ' + isnull( CONVERT(nvarchar, @pnBankRate), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnBuyRate = ' + isnull( CONVERT(nvarchar, @pnBuyRate), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnSellRate = ' + isnull( CONVERT(nvarchar, @pnSellRate), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnDecimalPlaces = ' + isnull( CONVERT(nvarchar, @pnDecimalPlaces), '<NULL>' )
PRINT @PrnLine

-- Test 4
-- Current dates
SELECT @pnBankRate = NULL
SELECT @pnBuyRate = NULL
SELECT @pnSellRate = NULL
SELECT @pnDecimalPlaces = NULL
SELECT @pnUserIdentityId = 5
SELECT @pbCalledFromCentura = 0
SELECT @psCurrencyCode = N'JPY'
SELECT @pdtTransactionDate = '19-JAN-2005'
SELECT @pbUseHistoricalRates = NULL
EXEC @RC = [dbo].[ac_GetExchangeDetails] @pnBankRate OUTPUT , @pnBuyRate OUTPUT , @pnSellRate OUTPUT , @pnDecimalPlaces OUTPUT , @pnUserIdentityId, @pbCalledFromCentura, @psCurrencyCode, @pdtTransactionDate, @pbUseHistoricalRates

PRINT 'Stored Procedure: IPMine.dbo.ac_GetExchangeDetails'
SELECT @PrnLine = '	Return Code = ' + CONVERT(nvarchar, @RC)
PRINT @PrnLine
print 'JPY: Current rates'
print 'Bank: 75.1234, Buy: 70.5059, Sell 82.9481, Decimal Places: 0'
PRINT '	Output Parameter(s): '
SELECT @PrnLine = '		@pnBankRate = ' + isnull( CONVERT(nvarchar, @pnBankRate), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnBuyRate = ' + isnull( CONVERT(nvarchar, @pnBuyRate), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnSellRate = ' + isnull( CONVERT(nvarchar, @pnSellRate), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnDecimalPlaces = ' + isnull( CONVERT(nvarchar, @pnDecimalPlaces), '<NULL>' )
PRINT @PrnLine

