DECLARE @RC int
DECLARE @pnUserIdentityId int
DECLARE @psCulture nvarchar(10)
DECLARE @pbCalledFromCentura bit
DECLARE @pnStaffKey int
DECLARE @pnEntityKey int
DECLARE @pnNameKey int
DECLARE @pnCaseKey int
DECLARE @pnApplicationID smallint
DECLARE @pbDebug bit
SELECT @pnUserIdentityId = 5
SELECT @pbCalledFromCentura = 0
SELECT @pnStaffKey = -487
SELECT @pnEntityKey = NULL
SELECT @pnNameKey = NULL
SELECT @pnCaseKey = -487
SELECT @pnApplicationID = 4
SELECT @pbDebug = 1
EXEC @RC = [IPNet].[dbo].[wp_ListWipWarnings] @pnUserIdentityId, DEFAULT, @pbCalledFromCentura, @pnStaffKey, @pnEntityKey, @pnNameKey, @pnCaseKey, @pnApplicationID, @pbDebug
DECLARE @PrnLine nvarchar(4000)
PRINT 'Stored Procedure: IPNet.dbo.wp_ListWipWarnings'
SELECT @PrnLine = '	Return Code = ' + CONVERT(nvarchar, @RC)
PRINT @PrnLine