/**********************************************************************************************************/	
/*** RFC59208 Add column HOLIDAYS.ID																	***/      
/**                                                                                                      **/
/**********************************************************************************************************/
If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'HOLIDAYS' AND COLUMN_NAME = 'ID')
	BEGIN		
		PRINT '**** R59208 Adding column HOLIDAYS.ID' 
		ALTER TABLE HOLIDAYS ADD ID int IDENTITY (1,1)  NOT FOR REPLICATION 		 
		PRINT '**** R59208 Column HOLIDAYS.ID added' 
 	END
ELSE
	BEGIN
		PRINT '**** R59208 Column HOLIDAYS.ID exists already' 
	END
GO
IF dbo.fn_IsAuditSchemaConsistent('HOLIDAYS') = 0
BEGIN
exec ipu_UtilGenerateAuditTriggers 'HOLIDAYS'
END
GO
