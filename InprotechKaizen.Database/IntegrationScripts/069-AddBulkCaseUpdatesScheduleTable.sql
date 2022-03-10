If NOT exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'BulkCaseUpdatesSchedule')
BEGIN
    CREATE TABLE [dbo].[BulkCaseUpdatesSchedule] (
        Id  bigint IDENTITY (1,1)  NOT FOR REPLICATION,
		[JobArguments] nvarchar(max) NULL,
        CONSTRAINT [PK_dbo.BulkCaseUpdatesSchedule] PRIMARY KEY (Id)
    )    
END
GO