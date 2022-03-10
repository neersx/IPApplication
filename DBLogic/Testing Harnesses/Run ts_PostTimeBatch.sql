DECLARE @RC int
DECLARE @pnRowsPosted int
DECLARE @pnUserIdentityId int
DECLARE @psCulture nvarchar(10)
DECLARE @pbCalledFromCentura bit
DECLARE @pnEntityKey int
DECLARE @psWhereClause nvarchar(4000)
DECLARE @pnBatchSize int
DECLARE @pnDebugFlag tinyint
SELECT @pnRowsPosted = NULL
SELECT @pnUserIdentityId = 5
SELECT @psCulture = NULL
SELECT @pbCalledFromCentura = NULL
SELECT @pnEntityKey = 24
SELECT @psWhereClause = N'FROM DIARY XD WHERE 1=1'
SELECT @pnBatchSize = 2
SELECT @pnDebugFlag = 2
EXEC @RC = [dbo].[ts_PostTimeBatch] @pnRowsPosted OUTPUT , @pnUserIdentityId, @psCulture, @pbCalledFromCentura, @pnEntityKey, @psWhereClause, @pnBatchSize, @pnDebugFlag
DECLARE @PrnLine nvarchar(4000)
PRINT 'Stored Procedure: IPNet.dbo.ts_PostTimeBatch'
SELECT @PrnLine = '	Return Code = ' + CONVERT(nvarchar, @RC)
PRINT @PrnLine
PRINT '	Output Parameter(s): '
SELECT @PrnLine = '		@pnRowsPosted = ' + isnull( CONVERT(nvarchar, @pnRowsPosted), '<NULL>' )
PRINT @PrnLine