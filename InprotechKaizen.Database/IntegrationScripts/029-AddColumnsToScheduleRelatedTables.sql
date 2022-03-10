IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Schedules' AND COLUMN_NAME = 'Type')
BEGIN   
	PRINT '**** R45407 Add column Schedules.Type'           	
	
	ALTER TABLE dbo.[Schedules] ADD [Type] INT NOT NULL DEFAULT (0)

	DECLARE @SQL NVARCHAR(MAX)
    SET @SQL = 'UPDATE dbo.[Schedules] SET [Type] = 1 WHERE Parent_Id IS NOT NULL'
    EXECUTE (@SQL)	
END
ELSE
BEGIN
	PRINT '**** R45407 Schedules.Type already exists'
	PRINT ''
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ScheduleExecutions' AND COLUMN_NAME = 'IsTidiedUp')
BEGIN   
	PRINT '**** R45407 Add column ScheduleExecutions.IsTidiedUp'
	
	ALTER TABLE dbo.[ScheduleExecutions] ADD [IsTidiedUp] BIT NOT NULL DEFAULT (0)
END
ELSE
BEGIN
	PRINT '**** R45407 ScheduleExecutions.IsTidiedUp already exists'
	PRINT ''
END
GO