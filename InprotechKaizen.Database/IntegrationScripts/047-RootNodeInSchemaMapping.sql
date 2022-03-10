/*** RFC55562/DR-16715 Cater for more than one root element ***/	
PRINT '**** RFC55562/DR-16715 Cater for more than one root element ****'

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SchemaMappings' AND COLUMN_NAME = 'RootNode')
	BEGIN   
	PRINT '**** Adding column SchemaMappings.RootNode'           
	ALTER TABLE SchemaMappings add  RootNode  nvarchar(max) NULL 
	PRINT '**** SchemaMappings.RootNode column has been added.'
	END
	ELSE   
	PRINT '**** SchemaMappings.RootNode column already exists'
	PRINT ''
GO

PRINT '**** RFC55562/DR-16715 Cater for more than one root element Ended ****'