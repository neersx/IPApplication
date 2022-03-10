If NOT exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ServerAnalyticsData')
BEGIN
  CREATE TABLE [dbo].[ServerAnalyticsData](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Event] [nvarchar](500) NOT NULL,
	[Value] [nvarchar](max) NULL,
	[LastSent] [datetime2](7) NOT NULL
	CONSTRAINT [PK_ServerAnalyticsData] PRIMARY KEY CLUSTERED ([Id] ASC)
 )

 CREATE NONCLUSTERED INDEX [IX_ServerAnalyticsData_Event] ON [dbo].[ServerAnalyticsData]([Event] ASC)
END
GO

If NOT exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ServerTransactionalDataSink')
BEGIN
  CREATE TABLE [dbo].[ServerTransactionalDataSink](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Event] [nvarchar](500) NOT NULL,
	[Value] [nvarchar](max) NULL,
	[Entered] [datetime2](7) NOT NULL	
	CONSTRAINT [PK_ServerTransactionalDataSink] PRIMARY KEY CLUSTERED ([Id] ASC)
 )

 CREATE NONCLUSTERED INDEX [IX_ServerTransactionalDataSink_Event] ON [dbo].[ServerTransactionalDataSink]([Event] ASC)
END
GO