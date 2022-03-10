/**********************************************************************************************************/	
/***  Add column FILECASE.ID													***/      
/**                                                                                                      **/
/**********************************************************************************************************/
If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'FILECASE' AND COLUMN_NAME = 'INSTRUCTIONID')
	BEGIN		
		PRINT '**** RFC72156 Adding column FILECASE.INSTRUCTIONID' 
		ALTER TABLE FILECASE ADD [INSTRUCTIONID] [uniqueidentifier] NULL
		PRINT '**** RFC72156 Column FILECASE.INSTRUCTIONID added' 
 	END
ELSE
	BEGIN
		PRINT '**** Column FILECASE.INSTRUCTIONID exists already' 
	END
GO
IF dbo.fn_IsAuditSchemaConsistent('FILECASE') = 0
BEGIN
exec ipu_UtilGenerateAuditTriggers 'FILECASE'
END
GO
