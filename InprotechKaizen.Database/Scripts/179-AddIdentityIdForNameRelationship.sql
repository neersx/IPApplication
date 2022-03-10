/**********************************************************************************************************/	
/*** RFC72156 Add column NAMERELATION.ID													***/      
/**                                                                                                      **/
/**********************************************************************************************************/
If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'NAMERELATION' AND COLUMN_NAME = 'ID')
	BEGIN		
		PRINT '**** RFC72156 Adding column NAMERELATION.ID' 
		ALTER TABLE NAMERELATION ADD ID int IDENTITY (1,1)  NOT FOR REPLICATION 		 
		PRINT '**** RFC72156 Column NAMERELATION.ID added' 
 	END
ELSE
	BEGIN
		PRINT '**** RFC72156 Column NAMERELATION.ID exists already' 
	END
GO
IF dbo.fn_IsAuditSchemaConsistent('NAMERELATION') = 0
BEGIN
exec ipu_UtilGenerateAuditTriggers 'NAMERELATION'
END
GO
