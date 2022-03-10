	 
/**********************************************************************************************************/	
/*** RFC73454 Add column USERIDENTITY.WRITEDOWNLIMIT													***/
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