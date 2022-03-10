/**********************************************************************************************************/	
/*** RFC50203 Add column CASECATEGORY.CASECATEGORYID																***/      
/**                                                                                                      **/
/**********************************************************************************************************/
If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'CASECATEGORY' AND COLUMN_NAME = 'CASECATEGORYID')
	BEGIN		
		PRINT '**** R50203 Adding column CASECATEGORY.CASECATEGORYID' 
		ALTER TABLE CASECATEGORY ADD CASECATEGORYID int IDENTITY (1,1)  NOT FOR REPLICATION 		 
		PRINT '**** R50203 Column CASECATEGORY.CASECATEGORYID added' 
 	END
ELSE
	BEGIN
		PRINT '**** R50203 Column CASECATEGORY.CASECATEGORYID exists already' 
	END
GO
IF dbo.fn_IsAuditSchemaConsistent('CASECATEGORY') = 0
BEGIN
 exec ipu_UtilGenerateAuditTriggers 'CASECATEGORY'
END
GO