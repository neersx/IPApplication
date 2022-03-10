IF object_id('[dbo].[ScheduleExecutionArtifacts]') IS NULL
BEGIN
	PRINT '**** 46987 Add ScheduleExecutionArtifacts table.'           

    CREATE TABLE [dbo].ScheduleExecutionArtifacts (
        [Id] [bigint] IDENTITY (1,1) NOT FOR REPLICATION,
		[ScheduleExecutionId] [bigint] NOT NULL,
		[CaseId] int NULL,
        CONSTRAINT [PK_dbo.ScheduleExecutionArtifacts] PRIMARY KEY ([Id])
    )  
	
	ALTER TABLE [dbo].ScheduleExecutionArtifacts 
		ADD CONSTRAINT [FK_dbo.ScheduleExecutionArtifacts_dbo.ScheduleExecutions_Id] 
			FOREIGN KEY ([ScheduleExecutionId]) REFERENCES [dbo].[ScheduleExecutions] ([Id])
				ON DELETE CASCADE  
END
ELSE
BEGIN
	PRINT '**** 46987 ScheduleExecutionArtifacts table already exists.'           	
END
GO