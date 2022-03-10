	If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Documents' AND COLUMN_NAME = 'Errors')
	BEGIN   
		PRINT '**** R38151 Adding column Documents.Errors.'           
		ALTER TABLE Documents ADD Errors NVARCHAR(max) NULL
		PRINT '**** R38151 Documents.Errors column has been added.'
	END
	ELSE
	BEGIN
		PRINT '**** R38151 Documents.Errors already exists'
		PRINT ''
	END
	go
	 