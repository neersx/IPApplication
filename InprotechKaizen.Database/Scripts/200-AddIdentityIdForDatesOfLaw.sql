/**********************************************************************************************************/	
/*** RFC73987 Add column VALIDACTDATES.ID													***/      
/**                                                                                                      **/
/**********************************************************************************************************/
If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'VALIDACTDATES' AND COLUMN_NAME = 'ID')
	BEGIN		
		PRINT '**** RFC73987 Adding column VALIDACTDATES.ID' 
		ALTER TABLE VALIDACTDATES ADD ID int IDENTITY (1,1)  NOT FOR REPLICATION 		 
		PRINT '**** RFC73987 Column VALIDACTDATES.ID added' 
 	END
ELSE
	BEGIN
		PRINT '**** RFC73987 Column VALIDACTDATES.ID exists already' 
	END
GO
IF dbo.fn_IsAuditSchemaConsistent('VALIDACTDATES') = 0
BEGIN
exec ipu_UtilGenerateAuditTriggers 'VALIDACTDATES'
END
GO
