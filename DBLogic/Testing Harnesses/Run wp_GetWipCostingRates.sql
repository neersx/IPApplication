DECLARE @RC int
DECLARE @pnUserIdentityId int
DECLARE @pbCalledFromCentura bit
DECLARE @pbDebug bit
DECLARE @pdtTransactionDate datetime
DECLARE @pnEntityKey int
DECLARE @pnStaffKey int
DECLARE @pnNameKey int
DECLARE @pnCaseKey int
DECLARE @psDebtorNameTypeKey nvarchar(3)
DECLARE @psWipCode nvarchar(6)
DECLARE @pnProductKey int
DECLARE @psWipCategoryKey nvarchar(2)
DECLARE @pbExtractChargeOut bit
DECLARE @pnChargeRatePerHour decimal(10,2)
DECLARE @psChargeCurrencyCode nvarchar(3)
DECLARE @pbExtractMargin bit
DECLARE @pnMarginPercent decimal(6,2)
DECLARE @pnMarginAmount decimal(10,2)
DECLARE @psMarginCurrencyCode nvarchar(3)
DECLARE @pbExtractDiscount bit
DECLARE @pnDiscountPercent decimal(6,3)
DECLARE @pbIsDiscountBasedOnAmount bit
DECLARE @pbExtractCost bit
DECLARE @pnCostPercent1 decimal(6,2)
DECLARE @pnCostPercent2 decimal(6,2)
DECLARE @pnCostRatePerHour1 decimal(10,2)
DECLARE @pnCostRatePerHour2 decimal(10,2)
SELECT @pnUserIdentityId = 5
SELECT @pbCalledFromCentura = NULL
SELECT @pbDebug = 1
SELECT @pdtTransactionDate = GETDATE()
SELECT @pnEntityKey = -283575757
SELECT @pnStaffKey = -487
SELECT @pnNameKey = null
SELECT @pnCaseKey = -487
SELECT @psWipCode = N'DRAFT'
SELECT @pnProductKey = NULL
SELECT @psWipCategoryKey = NULL
SELECT @pbExtractChargeOut = 1
SELECT @pnChargeRatePerHour = NULL
SELECT @psChargeCurrencyCode = NULL
SELECT @pbExtractMargin = 1
SELECT @pnMarginPercent = NULL
SELECT @pnMarginAmount = NULL
SELECT @psMarginCurrencyCode = NULL
SELECT @pbExtractDiscount = 1
SELECT @pnDiscountPercent = NULL
SELECT @pbIsDiscountBasedOnAmount = NULL
SELECT @pbExtractCost = 1
SELECT @pnCostPercent1 = NULL
SELECT @pnCostPercent2 = NULL
SELECT @pnCostRatePerHour1 = NULL
SELECT @pnCostRatePerHour2 = NULL
EXEC @RC = [dbo].[wp_GetWipCostingRates] @pnUserIdentityId, @pbCalledFromCentura, @pbDebug, @pdtTransactionDate, @pnEntityKey, @pnStaffKey, @pnNameKey, @pnCaseKey, 'Z', @psWipCode, @pnProductKey, @psWipCategoryKey OUTPUT , @pbExtractChargeOut, @pnChargeRatePerHour OUTPUT , @psChargeCurrencyCode OUTPUT , @pbExtractMargin, @pnMarginPercent OUTPUT , @pnMarginAmount OUTPUT , @psMarginCurrencyCode OUTPUT , @pbExtractDiscount, @pnDiscountPercent OUTPUT , @pbIsDiscountBasedOnAmount OUTPUT , @pbExtractCost, @pnCostPercent1 OUTPUT , @pnCostPercent2 OUTPUT , @pnCostRatePerHour1 OUTPUT , @pnCostRatePerHour2 OUTPUT 
DECLARE @PrnLine nvarchar(4000)
PRINT 'Stored Procedure: IPMine.dbo.wp_GetWipCostingRates'
SELECT @PrnLine = '	Return Code = ' + CONVERT(nvarchar, @RC)
PRINT @PrnLine
PRINT '	Output Parameter(s): '
SELECT @PrnLine = '		@psWipCategoryKey = ' + isnull( CONVERT(nvarchar, @psWipCategoryKey), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnChargeRatePerHour = ' + isnull( CONVERT(nvarchar, @pnChargeRatePerHour), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@psChargeCurrencyCode = ' + isnull( CONVERT(nvarchar, @psChargeCurrencyCode), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnMarginPercent = ' + isnull( CONVERT(nvarchar, @pnMarginPercent), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnMarginAmount = ' + isnull( CONVERT(nvarchar, @pnMarginAmount), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@psMarginCurrencyCode = ' + isnull( CONVERT(nvarchar, @psMarginCurrencyCode), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnDiscountPercent = ' + isnull( CONVERT(nvarchar, @pnDiscountPercent), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pbIsDiscountBasedOnAmount = ' + isnull( CONVERT(nvarchar, @pbIsDiscountBasedOnAmount), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnCostPercent1 = ' + isnull( CONVERT(nvarchar, @pnCostPercent1), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnCostPercent2 = ' + isnull( CONVERT(nvarchar, @pnCostPercent2), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnCostRatePerHour1 = ' + isnull( CONVERT(nvarchar, @pnCostRatePerHour1), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnCostRatePerHour2 = ' + isnull( CONVERT(nvarchar, @pnCostRatePerHour2), '<NULL>' )
PRINT @PrnLine