/*** R73054 Add column COUNTRYGROUP.ASSOCIATEMEMBERDATE          ***/      

	If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'COUNTRYGROUP' AND COLUMN_NAME = 'ASSOCIATEMEMBERDATE')
	 BEGIN   
		PRINT '**** R73054 Adding column COUNTRYGROUP.ASSOCIATEMEMBERDATE.'           
		ALTER TABLE COUNTRYGROUP add ASSOCIATEMEMBERDATE  datetime NULL	 
		PRINT '**** R73054 COUNTRYGROUP.ASSOCIATEMEMBERDATE column has been added.'
	 END
	 ELSE   
		PRINT '**** R73054 COUNTRYGROUP.ASSOCIATEMEMBERDATE already exists'
		PRINT ''
	 GO
	 IF dbo.fn_IsAuditSchemaConsistent('COUNTRYGROUP') = 0
	 BEGIN
		EXEC ipu_UtilGenerateAuditTriggers 'COUNTRYGROUP'
	 END
	 GO