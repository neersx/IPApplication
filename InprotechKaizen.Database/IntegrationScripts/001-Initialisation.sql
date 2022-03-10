
IF object_id('[dbo].[Cases]') IS NULL
BEGIN
    CREATE TABLE [dbo].[Cases] (
        [Id] [int] NOT NULL IDENTITY,
        [CorrelationId] [nvarchar](400) NOT NULL,
        [CorrelationType] [int] NOT NULL,
        [Source] [int] NOT NULL,
        [Version] [nvarchar](max),
        [CreatedOn] [datetime] NOT NULL,
        [UpdatedOn] [datetime] NOT NULL,
        [Timestamp] rowversion NOT NULL,
        [FileStore_Id] [int],
        CONSTRAINT [PK_dbo.Cases] PRIMARY KEY ([Id])
    )   
 
    CREATE INDEX [IX_FileStore_Id] ON [dbo].[Cases]([FileStore_Id])   
END
GO
 
IF object_id('[dbo].[FileStores]') IS NULL
BEGIN
    CREATE TABLE [dbo].[FileStores] (
        [Id] [int] NOT NULL IDENTITY,
        [Path] [nvarchar](max) NOT NULL,
        [OriginalFileName] [nvarchar](max) NOT NULL,
        CONSTRAINT [PK_dbo.FileStores] PRIMARY KEY ([Id])
    )
END
GO
 
IF object_id('[dbo].[Documents]') IS NULL
BEGIN
    CREATE TABLE [dbo].[Documents] (
        [Id] [int] NOT NULL IDENTITY,
        [CorrelationId] [nvarchar](512) NOT NULL,
        [Status] [int] NOT NULL,
        [DocumentObjectId] [nvarchar](max) NOT NULL,
        [MailRoomDate] [datetime] NOT NULL,
        [DocumentDescription] [nvarchar](max),
        [DocumentCategory] [nvarchar](max),
        [FileWrapperDocumentCode] [nvarchar](max),
        [PageCount] [int],
        [CreatedOn] [datetime] NOT NULL,
        [UpdatedOn] [datetime] NOT NULL,
        [FileStore_Id] [int],
        [Reference] [uniqueidentifier] NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'
        CONSTRAINT [PK_dbo.Documents] PRIMARY KEY ([Id])
    )   
 
    CREATE INDEX [IX_FileStore_Id] ON [dbo].[Documents]([FileStore_Id])
END
GO
 
IF object_id('[dbo].[CaseNotifications]') IS NULL
BEGIN
    CREATE TABLE [dbo].[CaseNotifications] (
        [Id] [int] NOT NULL IDENTITY,
        [Type] [int] NOT NULL,
        [Body] [nvarchar](max),
        [CreatedOn] [datetime] NOT NULL,
        [UpdatedOn] [datetime] NOT NULL,
        [IsReviewed] [bit] NOT NULL,
        [ReviewedBy] [int],
        [CaseId] [int] NOT NULL,
        [Timestamp] rowversion NOT NULL,
        CONSTRAINT [PK_dbo.CaseNotifications] PRIMARY KEY ([Id])
    )
END
GO
 
IF object_id('[dbo].[Certificates]') IS NULL
BEGIN
    CREATE TABLE [dbo].[Certificates] (
        [Id] [int] NOT NULL IDENTITY,
        [Name] [nvarchar](max) NOT NULL,
        [FileName] [nvarchar](max) NOT NULL,
        [CustomerNumbers] [nvarchar](max) NOT NULL,
        [Password] [nvarchar](max) NOT NULL,
        [Content] [nvarchar](max) NOT NULL,
        [CreatedOn] [datetime] NOT NULL,
        [CreatedBy] [int] NOT NULL,
        [IsDeleted] [bit] NOT NULL,
        [DeletedOn] [datetime],
        [DeletedBy] [int],
        CONSTRAINT [PK_dbo.Certificates] PRIMARY KEY ([Id])
    )   
 
    CREATE INDEX [IX_CaseId] ON [dbo].[CaseNotifications]([CaseId])
END
GO
 
IF object_id('[dbo].[Schedules]') IS NULL
BEGIN
    CREATE TABLE [dbo].[Schedules] (
        [Id] [int] NOT NULL IDENTITY,
        [Name] [nvarchar](max) NOT NULL,
        [CustomerNumbers] [nvarchar](max) NOT NULL,
        [CertificateId] [int] NOT NULL,
        [DownloadType] [int] NOT NULL,
        [DaysWithinLast] [int],
        [RunOnDays] [nvarchar](max) NOT NULL,
        [StartTime] [nvarchar](max) NOT NULL,
        [UnviewedOnly] [bit] NOT NULL,
        [CreatedOn] [datetime] NOT NULL,
        [CreatedBy] [int] NOT NULL,
        [IsDeleted] [bit] NOT NULL,
        [DeletedOn] [datetime],
        [DeletedBy] [int],
        [LastRunStartOn] [datetime],
        CONSTRAINT [PK_dbo.Schedules] PRIMARY KEY ([Id])
    )   
 
    CREATE INDEX [IX_CertificateId] ON [dbo].[Schedules]([CertificateId])
END
GO

IF object_id('[dbo].[ScheduleFailures]') IS NULL
BEGIN
	CREATE TABLE [dbo].[ScheduleFailures] (
		[Id] [int] NOT NULL IDENTITY,
		[Date] [datetime] NOT NULL,
		[Log] [nvarchar](max) NOT NULL,
		[Schedule_Id] [int] NOT NULL,
		CONSTRAINT [PK_dbo.ScheduleFailures] PRIMARY KEY ([Id])
	)
	
	CREATE INDEX [IX_Schedule_Id] ON [dbo].[ScheduleFailures]([Schedule_Id])
END
GO
 
IF NOT EXISTS (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'Documents' and CONSTRAINT_NAME = 'FK_dbo.Documents_dbo.FileStores_FileStore_Id')
BEGIN
    ALTER TABLE [dbo].[Documents] ADD CONSTRAINT [FK_dbo.Documents_dbo.FileStores_FileStore_Id] FOREIGN KEY ([FileStore_Id]) REFERENCES [dbo].[FileStores] ([Id])
END
GO
 
IF NOT EXISTS (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'CaseNotifications' and CONSTRAINT_NAME = 'FK_dbo.CaseNotifications_dbo.Cases_CaseId')
BEGIN
    ALTER TABLE [dbo].[CaseNotifications] ADD CONSTRAINT [FK_dbo.CaseNotifications_dbo.Cases_CaseId] FOREIGN KEY ([CaseId]) REFERENCES [dbo].[Cases] ([Id]) ON DELETE CASCADE
END
GO
 
IF NOT EXISTS (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'Schedules' and CONSTRAINT_NAME = 'FK_dbo.Schedules_dbo.Certificates_CertificateId')
BEGIN
    ALTER TABLE [dbo].[Schedules] ADD CONSTRAINT [FK_dbo.Schedules_dbo.Certificates_CertificateId] FOREIGN KEY ([CertificateId]) REFERENCES [dbo].[Certificates] ([Id]) ON DELETE CASCADE
END
GO

IF NOT EXISTS (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'ScheduleFailures' and CONSTRAINT_NAME = 'FK_dbo.ScheduleFailures_dbo.Schedules_Schedule_Id')
BEGIN
	ALTER TABLE [dbo].[ScheduleFailures] ADD CONSTRAINT [FK_dbo.ScheduleFailures_dbo.Schedules_Schedule_Id] FOREIGN KEY ([Schedule_Id]) REFERENCES [dbo].[Schedules] ([Id]) ON DELETE CASCADE
END
GO
 
IF NOT EXISTS (select * from sys.indexes where name = N'IX_CorrelationId_CorrelationType_Source' AND object_id = object_id(N'[dbo].[Cases]', N'U'))
BEGIN
    CREATE UNIQUE INDEX [IX_CorrelationId_CorrelationType_Source] ON [dbo].[Cases]([CorrelationId], [CorrelationType], [Source])
END
GO
 
IF NOT EXISTS (select * from sys.indexes where name = N'IX_CaseId_Type' AND object_id = object_id(N'[dbo].[CaseNotifications]', N'U'))
BEGIN
    CREATE UNIQUE INDEX [IX_CaseId_Type] ON [dbo].[CaseNotifications]([CaseId], [Type])
END
GO

IF NOT EXISTS (select * from sys.indexes where name = N'IX_Reference' AND object_id = object_id(N'[dbo].[Documents]', N'U'))
BEGIN
	CREATE UNIQUE INDEX [IX_Reference] ON [dbo].[Documents]([Reference])
END
GO
