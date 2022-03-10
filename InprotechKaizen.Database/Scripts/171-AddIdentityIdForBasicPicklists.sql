/**********************************************************************************************************/	
/*** RFC72432 Add column PROPERTYTYPE.ID																***/      
/**                                                                                                      **/
/**********************************************************************************************************/
If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'PROPERTYTYPE' AND COLUMN_NAME = 'ID')
	BEGIN		
		PRINT '**** R72432 Adding column PROPERTYTYPE.ID' 
		ALTER TABLE PROPERTYTYPE ADD ID int IDENTITY (1,1)  NOT FOR REPLICATION 		 
		PRINT '**** R72432 Column PROPERTYTYPE.ID added' 
 	END
ELSE
	BEGIN
		PRINT '**** R72432 Column PROPERTYTYPE.ID exists already' 
	END
GO
IF dbo.fn_IsAuditSchemaConsistent('PROPERTYTYPE') = 0
BEGIN
	exec ipu_UtilGenerateAuditTriggers 'PROPERTYTYPE'
END
GO

/**********************************************************************************************************/	
/*** RFC72432 Add column CASETYPE.ID																	***/      
/**                                                                                                      **/
/**********************************************************************************************************/
If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'CASETYPE' AND COLUMN_NAME = 'ID')
	BEGIN		
		PRINT '**** R72432 Adding column CASETYPE.ID' 
		ALTER TABLE CASETYPE ADD ID int IDENTITY (1,1)  NOT FOR REPLICATION 		 
		PRINT '**** R72432 Column CASETYPE.ID added' 
 	END
ELSE
	BEGIN
		PRINT '**** R72432 Column CASETYPE.ID exists already' 
	END
GO
IF dbo.fn_IsAuditSchemaConsistent('CASETYPE') = 0
BEGIN
exec ipu_UtilGenerateAuditTriggers 'CASETYPE'
END
GO

/**********************************************************************************************************/	
/*** RFC72432 Add column ACTIONS.ID																		***/      
/**                                                                                                      **/
/**********************************************************************************************************/
If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ACTIONS' AND COLUMN_NAME = 'ID')
	BEGIN		
		PRINT '**** R72432 Adding column ACTIONS.ID' 
		ALTER TABLE ACTIONS ADD ID int IDENTITY (1,1)  NOT FOR REPLICATION 		 
		PRINT '**** R72432 Column ACTIONS.ID added' 
 	END
ELSE
	BEGIN
		PRINT '**** R72432 Column ACTIONS.ID exists already' 
	END
GO
IF dbo.fn_IsAuditSchemaConsistent('ACTIONS') = 0
BEGIN
exec ipu_UtilGenerateAuditTriggers 'ACTIONS'
END
GO


/**********************************************************************************************************/	
/*** RFC72432 Add column SUBTYPE.ID																		***/      
/**                                                                                                      **/
/**********************************************************************************************************/
If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SUBTYPE' AND COLUMN_NAME = 'ID')
	BEGIN		
		PRINT '**** R72432 Adding column SUBTYPE.ID' 
		ALTER TABLE SUBTYPE ADD ID int IDENTITY (1,1)  NOT FOR REPLICATION 		 
		PRINT '**** R72432 Column SUBTYPE.ID added' 
 	END
ELSE
	BEGIN
		PRINT '**** R72432 Column SUBTYPE.ID exists already' 
	END
GO
IF dbo.fn_IsAuditSchemaConsistent('SUBTYPE') = 0
BEGIN
exec ipu_UtilGenerateAuditTriggers 'SUBTYPE'
END
GO

/**********************************************************************************************************/	
/*** RFC72432 Add column APPLICATIONBASIS.ID															***/      
/**                                                                                                      **/
/**********************************************************************************************************/
If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'APPLICATIONBASIS' AND COLUMN_NAME = 'ID')
	BEGIN		
		PRINT '**** R72432 Adding column APPLICATIONBASIS.ID' 
		ALTER TABLE APPLICATIONBASIS ADD ID int IDENTITY (1,1)  NOT FOR REPLICATION 		 
		PRINT '**** R72432 Column APPLICATIONBASIS.ID added' 
 	END
ELSE
	BEGIN
		PRINT '**** R72432 Column APPLICATIONBASIS.ID exists already' 
	END
GO
IF dbo.fn_IsAuditSchemaConsistent('APPLICATIONBASIS') = 0
BEGIN
exec ipu_UtilGenerateAuditTriggers 'APPLICATIONBASIS'
END
GO