
IF NOT EXISTS(SELECT 1
FROM sys.indexes
WHERE name = 'IX_JobExcutions_JobId' AND object_id = OBJECT_ID('JobExecutions'))
    BEGIN
    PRINT '**** DR-64417 Adding Index for Performance'
    CREATE NONCLUSTERED INDEX [IX_JobExcutions_JobId] ON [dbo].[JobExecutions]
    (
        [JobId] ASC,
		[Started] ASC
    )
    PRINT '**** DR-64417 Adding Index for Performance Finished'
END

GO