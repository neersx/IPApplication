/*** RFC46053/DR-11564 Add Schema Info SchemaFiles ***/	
IF object_id('[dbo].[SchemaFiles]') IS NULL
BEGIN
	PRINT '**** RFC46053/DR-11564 Add table SchemaFiles.'		

    CREATE TABLE dbo.[SchemaFiles](
		Id int IDENTITY(1,1) NOT NULL,
		[Name] [nvarchar](max) NOT NULL,
		MetadataId uniqueidentifier NOT NULL,
		IsMappable bit NOT NULL,
		[CreatedOn] [datetime] NOT NULL,
		[UpdatedOn] [datetime] NOT NULL,
		CONSTRAINT [PK_dbo.SchemaFiles] PRIMARY KEY ([Id])
	)

	PRINT '**** RFC46053/DR-11564 SchemaFiles table has been added.'
END
ELSE
	PRINT '**** RFC46053/DR-11564 SchemaFiles already exists'
GO

/*** RFC43708/DR-10435 Add table SchemaMappings ***/	
IF object_id('[dbo].[SchemaMappings]') IS NULL
BEGIN
	PRINT '**** RFC43708/DR-10435 Add table SchemaMappings.'		
        
    CREATE TABLE [dbo].[SchemaMappings](
		[Id] [int] IDENTITY(1,1) NOT NULL,
		[Version] [int] NOT NULL,
		[Name] [nvarchar](max) NOT NULL,
		[SchemaFileId] [int] NOT NULL,
		[Content] [nvarchar](max) NULL,
		[CreatedOn] [datetime] NOT NULL,
		[UpdatedOn] [datetime] NOT NULL,
		CONSTRAINT [PK_dbo.SchemaMappings] PRIMARY KEY ([Id])
	)

	PRINT '**** RFC43708/DR-10435 SchemaMappings table has been added.'
END
ELSE
	PRINT '**** RFC43708/DR-10435 SchemaMappings already exists'
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE WHERE TABLE_NAME = 'SchemaMappings' AND CONSTRAINT_NAME = 'FK_dbo.SchemaMappings_dbo.FileStores_SchemaFiles_Id')
BEGIN
    ALTER TABLE [dbo].[SchemaMappings] ADD CONSTRAINT [FK_dbo.SchemaMappings_dbo.FileStores_SchemaFiles_Id] FOREIGN KEY ([SchemaFileId]) REFERENCES [dbo].[SchemaFiles] ([Id])
END
GO