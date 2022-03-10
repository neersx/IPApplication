/**********************************************************************************************************/	
/*** DR-57285 Add column DIARY.ID																		***/      
/**********************************************************************************************************/
If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'DIARY' AND COLUMN_NAME = 'ID')
	BEGIN		
		PRINT '**** DR-57285 Adding Identity column DIARY.ID' 
		ALTER TABLE DIARY ADD ID int IDENTITY (1,1)  NOT FOR REPLICATION 		 
		PRINT '**** DR-57285 Column DIARY.ID successfully added.' 
 	END
ELSE
	BEGIN
		PRINT '**** DR-57285 Column DIARY.ID already exists.' 
	END
GO
IF dbo.fn_IsAuditSchemaConsistent('DIARY') = 0
BEGIN
exec ipu_UtilGenerateAuditTriggers 'DIARY'
END
GO
