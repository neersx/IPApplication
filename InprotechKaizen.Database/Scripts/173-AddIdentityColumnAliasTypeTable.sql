/**********************************************************************************************************/       
/*** RFC72155 Add column ALIASTYPE.ID                                                                                    ***/      
/**                                                                                                      **/
/**********************************************************************************************************/
If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ALIASTYPE' AND COLUMN_NAME = 'ID')
       BEGIN        
             PRINT '**** RFC72155 Adding column ALIASTYPE.ID' 
             ALTER TABLE ALIASTYPE ADD ID int IDENTITY (1,1)  NOT FOR REPLICATION          
             PRINT '**** RFC72155 Column ALIASTYPE.ID added' 
       END
ELSE
       BEGIN
             PRINT '**** RFC72155 Column ALIASTYPE.ID exists already' 
       END
GO
IF dbo.fn_IsAuditSchemaConsistent('APPLICATIONBASIS') = 0
BEGIN
exec ipu_UtilGenerateAuditTriggers 'ALIASTYPE'
END
GO
