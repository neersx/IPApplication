	If EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Cases' AND COLUMN_NAME = 'CorrelationId') and 
	NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Cases' AND COLUMN_NAME = 'ApplicationNumber')
	BEGIN   
		PRINT '**** R42537 Rename column Cases.CorrelationId to Cases.ApplicationNumber.'           
		EXEC sp_rename 'Cases.CorrelationId', 'ApplicationNumber', 'COLUMN'
		PRINT '**** R42537 Cases.CorrelationId column has been renamed.'
	END
	ELSE
	BEGIN
		PRINT '**** R42537 Cases.CorrelationId already renamed'
		PRINT ''
	END
	go

	If EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Cases' AND COLUMN_NAME = 'ApplicationNumber' and IS_NULLABLE = 'NO')
	BEGIN   
		PRINT '**** R42537 Alter Cases.ApplicationNumber be nullable.'           
		ALTER TABLE Cases ALTER COLUMN ApplicationNumber nvarchar(512) collate database_default null
		PRINT '**** R42537 Cases.ApplicationNumber column has been altered.'
	END
	ELSE
	BEGIN
		PRINT '**** R42537 Cases.ApplicationNumber already nullable'
		PRINT ''
	END
	go
	
	If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Cases' AND COLUMN_NAME = 'RegistrationNumber')
	BEGIN   
		PRINT '**** R42537 Adding column Cases.RegistrationNumber.'           
		ALTER TABLE Cases ADD RegistrationNumber NVARCHAR(400) NULL
		PRINT '**** R42537 Cases.RegistrationNumber column has been added.'
	END
	ELSE
	BEGIN
		PRINT '**** R42537 Cases.RegistrationNumber already exists'
		PRINT ''
	END
	go

	If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Cases' AND COLUMN_NAME = 'PublicationNumber')
	BEGIN   
		PRINT '**** R42537 Adding column Cases.PublicationNumber.'           
		ALTER TABLE Cases ADD PublicationNumber NVARCHAR(400) NULL
		PRINT '**** R42537 Cases.PublicationNumber column has been added.'
	END
	ELSE
	BEGIN
		PRINT '**** R42537 Cases.PublicationNumber already exists'
		PRINT ''
	END
	go
	
	If EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_CorrelationId_CorrelationType_Source' AND object_id = object_id(N'[dbo].[Cases]', N'U'))
	BEGIN	
		PRINT '**** R42537 Drop IX_CorrelationId_CorrelationType_Source index.'		
		DROP INDEX IX_CorrelationId_CorrelationType_Source on Cases
		PRINT '**** R42537 IX_CorrelationId_CorrelationType_Source index has been dropped.'
	END
	ELSE
	BEGIN
		PRINT '**** R42537 IX_CorrelationId_CorrelationType_Source index already removed'
		PRINT ''
	END
	go
	 
	If EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Cases' AND COLUMN_NAME = 'CorrelationType')
	BEGIN	
		PRINT '**** R42537 Drop column Cases.CorrelationType.'
		ALTER TABLE Cases DROP COLUMN CorrelationType
		PRINT '**** R42537 Cases.CorrelationType column has been dropped.'
	END
	ELSE
	BEGIN
		PRINT '**** R42537 Cases.CorrelationType column already removed'
		PRINT ''
	END
	go

	If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Cases' AND COLUMN_NAME = 'CorrelationId')
	BEGIN   
		PRINT '**** R42537 Adding column Cases.CorrelationId.'           
		ALTER TABLE Cases ADD CorrelationId int NULL
		PRINT '**** R42537 Cases.CorrelationId column has been added.'
	END
	ELSE
	BEGIN
		PRINT '**** R42537 Cases.CorrelationId already exists'
		PRINT ''
	END
	go	 	 