/**********************************************************************************************************/	
/*** RFC72675 Add column TMCLASS.ID													***/      
/**                                                                                                      **/
/**********************************************************************************************************/
If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TMCLASS' AND COLUMN_NAME = 'ID')
	BEGIN		
		PRINT '**** R72675 Adding column TMCLASS.ID' 
		ALTER TABLE TMCLASS ADD ID int IDENTITY (1,1)  NOT FOR REPLICATION 		 
		PRINT '**** R72675 Column TMCLASS.ID added' 
 	END
ELSE
	BEGIN
		PRINT '**** R72675 Column TMCLASS.ID exists already' 
	END
GO
IF dbo.fn_IsAuditSchemaConsistent('TMCLASS') = 0
BEGIN
exec ipu_UtilGenerateAuditTriggers 'TMCLASS'
END
GO
