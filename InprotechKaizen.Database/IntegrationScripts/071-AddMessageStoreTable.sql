If NOT exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'MessageStore')
BEGIN
  CREATE TABLE [dbo].[MessageStore](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ServiceId] [nvarchar](100) NOT NULL,
	[ServiceType] [nvarchar](100) NOT NULL,
	[MessageTimestamp] [datetime2](7) NOT NULL,
	[MessageStatus] [nvarchar](max) NULL,
	[MessageTransactionId] [nvarchar](100) NULL,
	[MessageText] [nvarchar](max) NULL,
	[LinkFileName] [nvarchar](max) NULL,
	[LinkStatus] [nvarchar](max) NULL,
	[LinkApplicationId] [nvarchar](max) NULL,
	[MessageData] [nvarchar](max) NOT NULL,
	[ProcessId] [bigint] NOT NULL,
	CONSTRAINT [PK_Messages] PRIMARY KEY CLUSTERED ([Id] ASC)
 )

 CREATE NONCLUSTERED INDEX [IX_MessageStore_ProcessID] ON [dbo].[MessageStore]([ProcessId] ASC)
END
GO