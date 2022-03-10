/**********************************************************************************************************/	
/*** RFC67005 Add column NUMBERTYPES.NUMBERTYPEID													***/      
/**                                                                                                      **/
/**********************************************************************************************************/
If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'NUMBERTYPES' AND COLUMN_NAME = 'NUMBERTYPEID')
	BEGIN		
		PRINT '**** R67005 Adding column NUMBERTYPES.NUMBERTYPEID' 
		ALTER TABLE NUMBERTYPES ADD NUMBERTYPEID int IDENTITY (1,1)  NOT FOR REPLICATION 		 
		PRINT '**** R67005 Column NUMBERTYPES.NUMBERTYPEID added' 
 	END
ELSE
	BEGIN
		PRINT '**** R67005 Column NUMBERTYPES.NUMBERTYPEID exists already' 
	END
GO
IF dbo.fn_IsAuditSchemaConsistent('NUMBERTYPES') = 0
BEGIN
	exec ipu_UtilGenerateAuditTriggers 'NUMBERTYPES'
END
GO
