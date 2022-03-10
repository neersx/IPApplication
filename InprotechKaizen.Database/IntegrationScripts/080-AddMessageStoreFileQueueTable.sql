If NOT exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'MessageStoreFileQueue')
BEGIN
     CREATE TABLE [dbo].[MessageStoreFileQueue](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Path] [nvarchar](max) NOT NULL,
	[CreatedOn] DATETIME2(7) NOT NULL DEFAULT GETUTCDATE()
	CONSTRAINT [PK_MessageStoreFileQueue] PRIMARY KEY CLUSTERED ([Id] ASC)
 )
END
GO