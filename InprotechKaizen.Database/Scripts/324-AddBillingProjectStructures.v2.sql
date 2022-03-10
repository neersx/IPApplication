/**********************************************************************************************************/	
/*** RFC73454 (13.1) Add column USERIDENTITY.WRITEDOWNLIMIT													***/
/**********************************************************************************************************/

If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'USERIDENTITY' AND COLUMN_NAME = 'WRITEDOWNLIMIT')
	BEGIN		
		PRINT '**** R73454 Adding column USERIDENTITY.WRITEDOWNLIMIT' 
		ALTER TABLE USERIDENTITY ADD WRITEDOWNLIMIT decimal(11,2)  NULL
		PRINT '**** R73454 Column USERIDENTITY.WRITEDOWNLIMIT added' 
 	END
ELSE
	BEGIN
		PRINT '**** R73454 Column USERIDENTITY.WRITEDOWNLIMIT exists already' 
	END
GO

IF dbo.fn_IsAuditSchemaConsistent('USERIDENTITY') = 0
BEGIN
   EXEC ipu_UtilGenerateAuditTriggers 'USERIDENTITY'
END
GO
 

/**********************************************************************************************************/	
/*** RFC74296 (14) Add column OPENITEM.CONVERSIONEXCHRATE          ***/
/**********************************************************************************************************/	

If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'OPENITEM' AND COLUMN_NAME = 'CONVERSIONEXCHRATE')
	BEGIN
		PRINT '**** R74296 Adding column OPENITEM.CONVERSIONEXCHRATE.'
		ALTER TABLE OPENITEM add CONVERSIONEXCHRATE   decimal(8,4)  NULL
		PRINT '**** R74296 OPENITEM.CONVERSIONEXCHRATE column has been added.'
	END
ELSE   
	BEGIN
		PRINT '**** R74296 OPENITEM.CONVERSIONEXCHRATE already exists'
	END

PRINT ''
GO

IF dbo.fn_IsAuditSchemaConsistent('OPENITEM') = 0
BEGIN
   EXEC ipu_UtilGenerateAuditTriggers 'OPENITEM'
END
GO
