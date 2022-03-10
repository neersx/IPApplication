
IF object_id('[dbo].[DocumentEvents]') IS NULL
BEGIN
    CREATE TABLE [dbo].[DocumentEvents] (
        [DocumentId] [int] NOT NULL,
		[CorrelationId] int NULL,
		[CorrelationEventId] int NULL,
		[CorrelationCycle] int NULL,
        [Status] [int] NOT NULL,
        [CreatedOn] [datetime] NOT NULL,
        [UpdatedOn] [datetime] NOT NULL,
        CONSTRAINT [PK_dbo.DocumentEvents] PRIMARY KEY ([DocumentId])
    )    
END
GO

IF NOT EXISTS (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE 
					where TABLE_NAME = 'DocumentEvents' 
					and CONSTRAINT_NAME = 'FK_dbo.DocumentsEvents_dbo.Documents_Id')
BEGIN
    ALTER TABLE [dbo].[DocumentEvents] 
		ADD CONSTRAINT [FK_dbo.DocumentsEvents_dbo.Documents_Id] 
			FOREIGN KEY ([DocumentId]) REFERENCES [dbo].[Documents] ([Id])
				ON DELETE CASCADE
END
GO

