/**********************************************************************************************************/	
/*** RFC9733 Add column INSTRUCTIONTYPE.ID																***/      
/**********************************************************************************************************/
If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'INSTRUCTIONTYPE' AND COLUMN_NAME = 'ID')
BEGIN   
	PRINT '**** R9733 Adding column INSTRUCTIONTYPE.ID.'           
	ALTER TABLE INSTRUCTIONTYPE ADD ID  int  IDENTITY (1,1)  NOT FOR REPLICATION	 
	PRINT '**** R9733 INSTRUCTIONTYPE.ID column has been added.'
END
ELSE   
	PRINT '**** R9733 INSTRUCTIONTYPE.ID already exists'
	PRINT ''
GO

IF dbo.fn_IsAuditSchemaConsistent('INSTRUCTIONTYPE') = 0
BEGIN
	EXEC ipu_UtilGenerateAuditTriggers 'INSTRUCTIONTYPE'
END
GO