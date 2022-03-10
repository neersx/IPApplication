/**********************************************************************************************************/
/***      DR-61320 Add new column ID in TAXRATES table							***/
/**********************************************************************************************************/

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TAXRATES' AND COLUMN_NAME = 'ID')
	BEGIN		 
		ALTER TABLE TAXRATES ADD ID int IDENTITY (1,1)  NOT FOR REPLICATION 		 
 	END
GO
exec ipu_UtilGenerateAuditTriggers 'TAXRATES'
GO