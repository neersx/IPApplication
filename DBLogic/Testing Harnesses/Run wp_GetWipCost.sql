DECLARE @RC int
DECLARE @pnUserIdentityId int
DECLARE @pbCalledFromCentura bit
DECLARE @pdtTransactionDate datetime
DECLARE @pnEntityKey int
DECLARE @pnStaffKey int
DECLARE @pnNameKey int
DECLARE @pnCaseKey int
DECLARE @psDebtorNameTypeKey nvarchar(3)
DECLARE @psWipCode nvarchar(6)
DECLARE @pnProductKey int
DECLARE @pbIsChargeGeneration bit
DECLARE @pbIsServiceCharge bit
DECLARE @pdtHours datetime
DECLARE @pnTimeUnits smallint
DECLARE @pnUnitsPerHour smallint
DECLARE @pnChargeOutRate decimal(10,2)
DECLARE @pnLocalValueBeforeMargin decimal(11,2)
DECLARE @pnForeignValueBeforeMargin decimal(11,2)
DECLARE @psCurrencyCode nvarchar(3)
DECLARE @pnExchangeRate decimal(8,4)
DECLARE @pnLocalValue decimal(11,2)
DECLARE @pnForeignValue decimal(11,2)
DECLARE @pbMarginRequired bit
DECLARE @pnMarginValue decimal(11,2)
DECLARE @pnLocalDiscount decimal(11,2)
DECLARE @pnForeignDiscount decimal(11,2)
DECLARE @pnLocalCost1 decimal(11,2)
DECLARE @pnLocalCost2 decimal(11,2)

SELECT @pnUserIdentityId = 5
SELECT @pbCalledFromCentura = 0
SELECT @pdtTransactionDate = '01-MAY-2005'
SELECT @pnEntityKey = -283575757
SELECT @pnStaffKey = -487
SELECT @pnNameKey = null
SELECT @pnCaseKey = -487
SELECT @psWipCode = N'HEAR'
SELECT @pnProductKey = NULL
SELECT @pbIsChargeGeneration = 0
SELECT @pbIsServiceCharge = null
SELECT @pdtHours = null
SELECT @pnTimeUnits = 100
SELECT @pnUnitsPerHour = NULL
SELECT @pnChargeOutRate = NULL
SELECT @pnLocalValueBeforeMargin = null
SELECT @pnForeignValueBeforeMargin = null
SELECT @psCurrencyCode = null
SELECT @pnExchangeRate = NULL
SELECT @pnLocalValue = NULL
SELECT @pnForeignValue = NULL
SELECT @pbMarginRequired = 1
SELECT @pnMarginValue = NULL
SELECT @pnLocalDiscount = NULL
SELECT @pnForeignDiscount = NULL
SELECT @pnLocalCost1 = NULL
SELECT @pnLocalCost2 = NULL
EXEC @RC = [dbo].[wp_GetWipCost] @pnUserIdentityId, @pbCalledFromCentura, @pdtTransactionDate, @pnEntityKey, @pnStaffKey, @pnNameKey, @pnCaseKey, @psDebtorNameTypeKey, @psWipCode, @pnProductKey, @pbIsChargeGeneration, @pbIsServiceCharge, @pdtHours OUTPUT , @pnTimeUnits OUTPUT , @pnUnitsPerHour OUTPUT , @pnChargeOutRate OUTPUT , @pnLocalValueBeforeMargin, @pnForeignValueBeforeMargin, @psCurrencyCode OUTPUT , @pnExchangeRate OUTPUT , @pnLocalValue OUTPUT , @pnForeignValue OUTPUT , @pbMarginRequired, @pnMarginValue OUTPUT , @pnLocalDiscount OUTPUT , @pnForeignDiscount OUTPUT , @pnLocalCost1 OUTPUT , @pnLocalCost2 OUTPUT ,
@pbDebug = 1
DECLARE @PrnLine nvarchar(4000)
PRINT 'Stored Procedure: IPMine.dbo.wp_GetWipCost'
SELECT @PrnLine = '	Return Code = ' + CONVERT(nvarchar, @RC)
PRINT @PrnLine
PRINT '	Output Parameter(s): '
SELECT @PrnLine = '		@pdtHours = ' + isnull( CONVERT(nvarchar, @pdtHours), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnTimeUnits = ' + isnull( CONVERT(nvarchar, @pnTimeUnits), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnUnitsPerHour = ' + isnull( CONVERT(nvarchar, @pnUnitsPerHour), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnChargeOutRate = ' + isnull( CONVERT(nvarchar, @pnChargeOutRate), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@psCurrencyCode = ' + isnull( CONVERT(nvarchar, @psCurrencyCode), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnExchangeRate = ' + isnull( CONVERT(nvarchar, @pnExchangeRate), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnLocalValue = ' + isnull( CONVERT(nvarchar, @pnLocalValue), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnForeignValue = ' + isnull( CONVERT(nvarchar, @pnForeignValue), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnMarginValue = ' + isnull( CONVERT(nvarchar, @pnMarginValue), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnLocalDiscount = ' + isnull( CONVERT(nvarchar, @pnLocalDiscount), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnForeignDiscount = ' + isnull( CONVERT(nvarchar, @pnForeignDiscount), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnLocalCost1 = ' + isnull( CONVERT(nvarchar, @pnLocalCost1), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnLocalCost2 = ' + isnull( CONVERT(nvarchar, @pnLocalCost2), '<NULL>' )
PRINT @PrnLine

