/**********************************************************************************************************/	
/*** RFC46702 Add column STATE.ID													***/      
/**                                                                                                      **/
/**********************************************************************************************************/
If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'STATE' AND COLUMN_NAME = 'ID')
	BEGIN		
		PRINT '**** R46702 Adding column STATE.ID' 
		ALTER TABLE STATE ADD ID int IDENTITY (1,1)  NOT FOR REPLICATION 		 
		PRINT '**** R46702 Column STATE.ID added' 
 	END
ELSE
	BEGIN
		PRINT '**** R46702 Column STATE.ID exists already' 
	END
GO

IF dbo.fn_IsAuditSchemaConsistent('STATE') = 0
BEGIN
exec ipu_UtilGenerateAuditTriggers 'STATE'
END
GO
