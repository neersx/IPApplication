If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ScheduleExecutions' AND COLUMN_NAME = 'Status')
BEGIN   
	PRINT '**** R47712 Adding column ScheduleExecutions.Status.'           
	ALTER TABLE dbo.ScheduleExecutions ADD [Status] int NOT NULL DEFAULT (0)
	PRINT '**** R47712 ScheduleExecutions.Status column has been added.'
 
    PRINT '**** R47712 Updating the status for the existing records'
	DECLARE @SQL NVARCHAR(MAX)
    SET @SQL = 'UPDATE dbo.ScheduleExecutions SET [Status] = 1 WHERE [Finished] IS NOT NULL'
    EXECUTE (@SQL)
	SET @SQL = 'UPDATE dbo.ScheduleExecutions SET [Status] = 2 WHERE EXISTS (SELECT 1 FROM dbo.ScheduleFailures AS SF WHERE SF.ScheduleExecutionId = ScheduleExecutions.Id)'
	EXECUTE (@SQL)
    PRINT '**** R47712 Updated the status for the existing records'
END
ELSE
BEGIN
	PRINT '**** R47712 ScheduleExecutions.Status already exists'
	PRINT ''
END
go


