	/*** R60349 Add column NAMETYPE.ETHICALWALL          ***/      

	If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'NAMETYPE' AND COLUMN_NAME = 'ETHICALWALL')
	 BEGIN   
		PRINT '**** R60349 Adding column NAMETYPE.ETHICALWALL.'           
		ALTER TABLE NAMETYPE add ETHICALWALL tinyint NOT NULL DEFAULT  0		 
		PRINT '**** R60349 NAMETYPE.ETHICALWALL column has been added.'
	 END
	 ELSE   
		PRINT '**** R60349 NAMETYPE.ETHICALWALL already exists'
		PRINT ''
	 GO

	 IF dbo.fn_IsAuditSchemaConsistent('NAMETYPE') = 0
	 BEGIN
		EXEC ipu_UtilGenerateAuditTriggers 'NAMETYPE'
	 END
	 GO