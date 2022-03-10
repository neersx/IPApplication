IF object_id('[dbo].[ExternalApplications]') IS NULL
BEGIN   

    CREATE TABLE [dbo].[ExternalApplications](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](max) NOT NULL,
	[Code] [nvarchar](max) NULL,
	[CreatedOn] [datetime] NULL,
	[CreatedBy] [int] NULL,
	CONSTRAINT [PK_dbo.ExternalApplications] PRIMARY KEY CLUSTERED([Id])
     )
END
GO

IF object_id('[dbo].[ExternalApplicationTokens]') IS NULL
BEGIN   

    CREATE TABLE [dbo].[ExternalApplicationTokens](
	[ExternalApplicationId] [int] NOT NULL,
	[Token] [nvarchar](max) NOT NULL,
	[ExpiryDate] [datetime] NULL,
	[IsActive] [bit] NOT NULL DEFAULT ((1)),
	[CreatedOn] [datetime] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	CONSTRAINT [PK_dbo.ExternalApplicationTokens] PRIMARY KEY CLUSTERED([ExternalApplicationId])
     )
END
GO

IF NOT EXISTS (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'ExternalApplicationTokens' and CONSTRAINT_NAME = 'FK_dbo.ExternalApplicationTokens_dbo.ExternalApplications_ExternalApplicationId')
BEGIN
	ALTER TABLE [dbo].[ExternalApplicationTokens]  ADD  CONSTRAINT [FK_dbo.ExternalApplicationTokens_dbo.ExternalApplications_ExternalApplicationId] FOREIGN KEY([ExternalApplicationId])
	REFERENCES [dbo].[ExternalApplications] ([Id])
	ON DELETE CASCADE
END
GO