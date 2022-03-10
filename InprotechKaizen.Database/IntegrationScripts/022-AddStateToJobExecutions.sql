If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'JobExecutions' AND COLUMN_NAME = 'State')
BEGIN   
	PRINT '**** R45804 Adding column JobExecutions.State.'           
	ALTER TABLE dbo.[JobExecutions] ADD [State] NVARCHAR(max) NULL
	PRINT '**** R45804 JobExecutions.State column has been added.'
END
ELSE
BEGIN
	PRINT '**** R45804 JobExecutions.State already exists'
	PRINT ''
END
go

IF EXISTS (SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'JobExecutions' AND COLUMN_NAME = 'Started' AND IS_NULLABLE = 'NO')
BEGIN
    PRINT '**** R45804 Changing JobExecutions.Started column to nullable'
    ALTER TABLE [dbo].[JobExecutions] ALTER COLUMN [Started] DATETIME NULL 
END
GO
