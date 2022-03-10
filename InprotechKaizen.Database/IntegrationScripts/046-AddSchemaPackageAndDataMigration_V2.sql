/*** RFC62539/DR-21570 Multiple root nodes and multiple mappings per Schema ***/	
PRINT '**** RFC62539/DR-21570 Multiple root nodes and multiple mappings per Schema Begin ****'
IF object_id('[dbo].[SchemaPackages]') IS NULL
BEGIN
	PRINT '**** Add table SchemaPackages.'		

    CREATE TABLE dbo.[SchemaPackages](
		Id int IDENTITY(1,1) NOT NULL,
		[Name] [nvarchar](max) NOT NULL,
		[CreatedOn] [datetime] NOT NULL,
		[UpdatedOn] [datetime] NOT NULL,
		[IsValid] [bit] DEFAULT '0'
		CONSTRAINT [PK_dbo.[SchemaPackages] PRIMARY KEY ([Id])
	)

	PRINT '**** SchemaPackages table has been added.'
END
ELSE
	PRINT '**** SchemaPackages already exists'
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SchemaFiles' AND COLUMN_NAME = 'SchemaPackageId')
	BEGIN   
	PRINT '**** Adding column SchemaFiles.SchemaPackageId'           
	ALTER TABLE SchemaFiles add  SchemaPackageId  int NULL 
	PRINT '**** SchemaFiles.SchemaPackageId column has been added.'
	END
	ELSE   
	PRINT '**** SchemaFiles.SchemaPackageId column already exists'
	PRINT ''
GO	

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE WHERE TABLE_NAME = 'SchemaFiles' AND CONSTRAINT_NAME = 'FK_dbo.SchemaFiles_dbo.SchemaPackages_SchemaPackage_Id')
BEGIN
	PRINT '**** Adding constraint FK_dbo.SchemaFiles_dbo.SchemaPackages_SchemaPackage_Id'           
    ALTER TABLE [dbo].[SchemaFiles] ADD CONSTRAINT [FK_dbo.SchemaFiles_dbo.SchemaPackages_SchemaPackage_Id] FOREIGN KEY ([SchemaPackageId]) REFERENCES [dbo].[SchemaPackages] ([Id])
	PRINT '**** Constraint FK_dbo.SchemaFiles_dbo.SchemaPackages_SchemaPackage_Id added'           
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SchemaMappings' AND COLUMN_NAME = 'SchemaPackageId')
	BEGIN   
	PRINT '**** Adding column SchemaMappings.SchemaPackageId'           
	ALTER TABLE SchemaMappings add  SchemaPackageId  int NULL 
	PRINT '**** SchemaMappings.SchemaPackageId column has been added.'
	END
	ELSE   
	PRINT '**** SchemaMappings.SchemaPackageId column already exists'
	PRINT ''
GO
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE WHERE TABLE_NAME = 'SchemaMappings' AND CONSTRAINT_NAME = 'FK_dbo.SchemaMappings_dbo.SchemaPackages_SchemaPackage_Id')
BEGIN
	PRINT '**** Adding constraint FK_dbo.SchemaMappings_dbo.SchemaPackages_SchemaPackage_Id'  
    ALTER TABLE [dbo].[SchemaMappings] ADD CONSTRAINT [FK_dbo.SchemaMappings_dbo.SchemaPackages_SchemaPackage_Id] FOREIGN KEY  ([SchemaPackageId]) REFERENCES [dbo].[SchemaPackages] ([Id])
	PRINT '**** Constraint FK_dbo.SchemaMappings_dbo.SchemaPackages_SchemaPackage_Id added'   
END
GO

BEGIN TRY
	BEGIN TRANSACTION

IF EXISTS (SELECT 1 FROM [dbo].[SchemaFiles] where IsMappable = '1')
BEGIN
	PRINT '**** Add Schema Packages for mappable schemas'		
        
	INSERT INTO [dbo].[SchemaPackages] (Name, CreatedOn, UpdatedOn,IsValid)
	SELECT Name, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP,0 FROM [dbo].[SchemaFiles] sf 
	WHERE IsMappable = '1' 
	AND NOT EXISTS (SELECT 1 FROM [dbo].[SchemaPackages] WHERE Name  = sf.Name)
   
	PRINT '**** Schema Packages for mappable schemas have been added'

	PRINT '**** Add schemaPackage key in schemafiles'		

	UPDATE sf
	SET SchemaPackageId  = sp.Id
	FROM [dbo].[SchemaPackages] sp 
	JOIN [dbo].[SchemaFiles] sf ON sf.Name = sp.Name
	
	PRINT '**** SchemaPackage key in schemafiles are added'
END
ELSE
	PRINT '**** No Mappable schemas exists. SchemaPackage Creation not required.'

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SchemaMappings' AND COLUMN_NAME = 'SchemaFileId') AND EXISTS (SELECT 1 FROM [dbo].[SchemaMappings]) 
BEGIN 
	DECLARE @SQL NVARCHAR(MAX)
	PRINT '**** Update Schema Packages id for mappings'		
	SET @SQL = 'UPDATE [dbo].[SchemaMappings] SET SchemaPackageId = ( SELECT SchemaPackageId FROM [dbo].[SchemaFiles] sf WHERE sf.Id = SchemaFileId)'
    EXECUTE (@SQL)
	PRINT '**** Schema Packages id for mappings are added'
END
ELSE
	PRINT '**** No mappingss exists. SchemaPackage Creation not required.'

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE WHERE TABLE_NAME = 'SchemaMappings' AND CONSTRAINT_NAME = 'FK_dbo.SchemaMappings_dbo.FileStores_SchemaFiles_Id')
BEGIN
	PRINT '**** Removing constraint FK_dbo.SchemaMappings_dbo.FileStores_SchemaFiles_Id'      
    ALTER TABLE [dbo].[SchemaMappings] DROP CONSTRAINT [FK_dbo.SchemaMappings_dbo.FileStores_SchemaFiles_Id] 
	PRINT '**** constraint FK_dbo.SchemaMappings_dbo.FileStores_SchemaFiles_Id is removed'      
END

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SchemaMappings' AND COLUMN_NAME = 'SchemaFileId')
	BEGIN   
	PRINT '**** Removing column SchemaMappings.SchemaFileId' 
	DECLARE @SQLDELETECOL NVARCHAR(MAX)
	SET @SQLDELETECOL = 'ALTER TABLE SchemaMappings DROP COLUMN SchemaFileId '
    EXECUTE (@SQLDELETECOL)          
	PRINT '**** SchemaMappings.SchemaFileId column has been removed.'
	END
	ELSE   
	PRINT '****  SchemaMappings.SchemaFileId column column does not exist'
	PRINT ''

IF NOT EXISTS (SELECT * FROM [dbo].[Jobs] WHERE Type = 'SchemaPackageMigration')
BEGIN
	PRINT '**** Adding Background job to process schemas'      
    INSERT INTO [dbo].[Jobs] VALUES('SchemaPackageMigration', 0 , GETDATE() , 1)
END


COMMIT TRANSACTION
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK

	DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
	SELECT @ErrMsg = ERROR_MESSAGE(), @ErrSeverity = ERROR_SEVERITY()

	RAISERROR(@ErrMsg, @ErrSeverity, 1)
END CATCH
GO

PRINT '**** RFC62539/DR-21570 Multiple root nodes and multiple mappings per Schema Ended ****'