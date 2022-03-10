/**********************************************************************************************************/	
/*** RFC61919 Add column USERIDENTITY.PASSWORDSALT													        ***/  
/**********************************************************************************************************/
If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'USERIDENTITY' AND COLUMN_NAME = 'PASSWORDSALT')
	BEGIN		
		PRINT '**** R61919 Adding column USERIDENTITY.PASSWORDSALT' 
		ALTER TABLE USERIDENTITY ADD PASSWORDSALT char(32) NULL		
		PRINT '**** R61919 Column USERIDENTITY.PASSWORDSALT added' 
 	END
ELSE
	BEGIN
		PRINT '**** R61919 Column USERIDENTITY.PASSWORDSALT exists already' 
	END
GO

/**********************************************************************************************************/	
/*** RFC61919 Add column USERIDENTITY.PASSWORDSHA													        ***/  
/**********************************************************************************************************/

If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'USERIDENTITY' AND COLUMN_NAME = 'PASSWORDSHA')
	BEGIN		
		PRINT '**** R61919 Adding column USERIDENTITY.PASSWORDSHA' 
		ALTER TABLE USERIDENTITY ADD PASSWORDSHA binary(32) NULL		
		PRINT '**** R61919 Column USERIDENTITY.PASSWORDSHA added' 
 	END
ELSE
	BEGIN
		PRINT '**** R61919 Column USERIDENTITY.PASSWORDSHA exists already' 
	END
GO
 IF dbo.fn_IsAuditSchemaConsistent('USERIDENTITY') = 0
 BEGIN
	exec ipu_UtilGenerateAuditTriggers 'USERIDENTITY'
 END
GO