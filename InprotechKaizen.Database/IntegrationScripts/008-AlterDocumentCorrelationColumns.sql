	If EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Documents' AND COLUMN_NAME = 'CorrelationId') and 
	NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Documents' AND COLUMN_NAME = 'ApplicationNumber')
	BEGIN   
		PRINT '**** R38151 Rename column Documents.CorrelationId to Document.ApplicationNumber.'           
		EXEC sp_rename 'Documents.CorrelationId', 'ApplicationNumber', 'COLUMN'
		PRINT '**** R38151 Documents.CorrelationId column has been renamed.'
	END
	ELSE
	BEGIN
		PRINT '**** R38151 Documents.CorrelationId already renamed'
		PRINT ''
	END
	go

	If EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Documents' AND COLUMN_NAME = 'ApplicationNumber' and IS_NULLABLE = 'NO')
	BEGIN   
		PRINT '**** R38151 Alter Documents.ApplicationNumber be nullable.'           
		ALTER TABLE Documents ALTER COLUMN ApplicationNumber nvarchar(512) collate database_default null
		PRINT '**** R38151 Documents.ApplicationNumber column has been altered.'
	END
	ELSE
	BEGIN
		PRINT '**** R38151 Documents.ApplicationNumber already nullable'
		PRINT ''
	END
	go
	
	If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Documents' AND COLUMN_NAME = 'RegistrationNumber')
	BEGIN   
		PRINT '**** R38151 Adding column Documents.RegistrationNumber.'           
		ALTER TABLE Documents ADD RegistrationNumber NVARCHAR(512) NULL
		PRINT '**** R38151 Documents.RegistrationNumber column has been added.'
	END
	ELSE
	BEGIN
		PRINT '**** R38151 Documents.RegistrationNumber already exists'
		PRINT ''
	END
	go

	If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Documents' AND COLUMN_NAME = 'PublicationNumber')
	BEGIN   
		PRINT '**** R38151 Adding column Documents.PublicationNumber.'           
		ALTER TABLE Documents ADD PublicationNumber NVARCHAR(512) NULL
		PRINT '**** R38151 Documents.PublicationNumber column has been added.'
	END
	ELSE
	BEGIN
		PRINT '**** R38151 Documents.PublicationNumber already exists'
		PRINT ''
	END
	go
	
	If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Documents' AND COLUMN_NAME = 'Source')
	BEGIN   
		PRINT '**** R38151 Adding column Documents.Source.'           
		ALTER TABLE Documents ADD [Source] int NULL
		PRINT '**** R38151 Documents.Source column has been added.'
	END
	ELSE
	BEGIN
		PRINT '**** R38151 Documents.Source already exists'
		PRINT ''
	END
	go	
	
	If EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Documents' AND COLUMN_NAME = 'Source' AND IS_NULLABLE = 'YES')
	BEGIN
		 PRINT '**** R38151 Change column Documents.Sourceto be NOT NULL.'
			UPDATE Documents SET Source = 0 where Source is null   

			ALTER TABLE Documents ALTER COLUMN Source int NOT NULL 
		 PRINT '****  R38151 Documents.Source column has been changed to NOT NULL.'
		 PRINT ''
 		END
	ELSE
 		PRINT '**** R38151 Documents.Source already is not nullable'
 		PRINT ''
	go	
	
	If exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Documents' AND COLUMN_NAME = 'DocumentObjectId' and CHARACTER_MAXIMUM_LENGTH = -1)
		BEGIN
		 PRINT '**** R38151 Change column Documents.DocumentObjectId to be nvarchar(256)'
		 ALTER TABLE Documents ALTER COLUMN DocumentObjectId nvarchar(256) NOT NULL
		 PRINT '**** R38151 Documents.DocumentObjectId column has been changed to NOT NULL.'
		 PRINT ''
 		END
	ELSE
	Begin
 		PRINT '**** R38151 Documents.DocumentObjectId already nvarchar(256).'
 		PRINT ''
	End
	go

	IF exists (SELECT * FROM sysindexes WHERE name = 'IX_Source_DocumentObjectId')
	BEGIN
		PRINT 'Dropping index Documents.IX_Source_DocumentObjectId ...'
		DROP INDEX Documents.IX_Source_DocumentObjectId
	END
	IF not exists (SELECT * FROM sysindexes WHERE name = 'IX_Source_DocumentObjectId')
	BEGIN
		PRINT 'Adding index Documents.IX_Source_DocumentObjectId ...'
		CREATE unique INDEX IX_Source_DocumentObjectId ON Documents
		(
			[Source] ASC,
			DocumentObjectId  ASC
		)
	END
	go	 