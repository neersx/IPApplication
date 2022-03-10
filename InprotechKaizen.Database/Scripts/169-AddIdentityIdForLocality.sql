/**********************************************************************************************************/	
/*** RFC72154 Add column NUMBERTYPES.NUMBERTYPEID													***/      
/**                                                                                                      **/
/**********************************************************************************************************/
If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'AIRPORT' AND COLUMN_NAME = 'ID')
	BEGIN		
		PRINT '**** R72154 Adding column AIRPORT.ID' 
		ALTER TABLE AIRPORT ADD ID int IDENTITY (1,1)  NOT FOR REPLICATION 		 
		PRINT '**** R72154 Column AIRPORT.ID added' 
 	END
ELSE
	BEGIN
		PRINT '**** R72154 Column AIRPORT.ID exists already' 
	END
GO
IF dbo.fn_IsAuditSchemaConsistent('AIRPORT') = 0
BEGIN
	exec ipu_UtilGenerateAuditTriggers 'AIRPORT'
END
GO
