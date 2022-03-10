	/* R54018 Add translation support to new site control tables **/
	
	--- Translation Source columns should be added before adding a TID column(To generate audit triggers) ---	   
	IF NOT exists (select * from TRANSLATIONSOURCE where TABLENAME = 'SITECONTROL' and TIDCOLUMN = 'NOTES_TID')
	begin
			PRINT '**** R54018 Inserting data into TRANSLATIONSOURCE.TABLENAME = SITECONTROL'
			Insert into TRANSLATIONSOURCE (TABLENAME, SHORTCOLUMN , LONGCOLUMN, TIDCOLUMN, INUSE)
			Values ('SITECONTROL', 'NOTES', NULL, 'NOTES_TID', 0)
			PRINT '**** R54018 Data has been successfully added to TRANSLATIONSOURCE table.'
			PRINT ''   
	END
	ELSE
	PRINT '**** R54018 TRANSLATIONSOURCE.SITECONTROL already exists.'
	PRINT ''
	go


		If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SITECONTROL' AND COLUMN_NAME = 'NOTES_TID')
		BEGIN   
		PRINT '**** R54018 Adding column SITECONTROL.NOTES_TID.'           
		ALTER TABLE SITECONTROL add  NOTES_TID  int  NULL 		 
		PRINT '**** R54018 SITECONTROL.NOTES_TID column has been added.'
		END
		ELSE   
		PRINT '**** R54018 SITECONTROL.NOTES_TID already exists'
		PRINT ''
	GO

	 IF dbo.fn_IsAuditSchemaConsistent('SITECONTROL') = 0
	 BEGIN
		EXEC ipu_UtilGenerateAuditTriggers 'SITECONTROL'
	 END
	GO
	
	--- Translation Source columns should be added before adding a TID column(To generate audit triggers) ---	   
	IF NOT exists (select * from TRANSLATIONSOURCE where TABLENAME = 'COMPONENTS' and TIDCOLUMN = 'COMPONENTNAME_TID')
	begin
			PRINT '**** R54018 Inserting data into TRANSLATIONSOURCE.TABLENAME = COMPONENTS'
			Insert into TRANSLATIONSOURCE (TABLENAME, SHORTCOLUMN , LONGCOLUMN, TIDCOLUMN, INUSE)
			Values ('COMPONENTS', 'COMPONENTNAME', NULL, 'COMPONENTNAME_TID', 0)
			PRINT '**** R54018 Data has been successfully added to TRANSLATIONSOURCE table.'
			PRINT ''   
	END
	ELSE
	PRINT '**** R54018 TRANSLATIONSOURCE.COMPONENTS already exists.'
	PRINT ''
	go


		If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'COMPONENTS' AND COLUMN_NAME = 'COMPONENTNAME_TID')
		BEGIN   
		PRINT '**** R54018 Adding column COMPONENTS.COMPONENTNAME_TID.'           
		ALTER TABLE COMPONENTS add  COMPONENTNAME_TID  int  NULL 		 
		PRINT '**** R54018 COMPONENTS.COMPONENTNAME_TID column has been added.'
		END
		ELSE   
		PRINT '**** R54018 COMPONENTS.COMPONENTNAME_TID already exists'
		PRINT ''
	GO
	 IF dbo.fn_IsAuditSchemaConsistent('COMPONENTS') = 0
	 BEGIN
		EXEC ipu_UtilGenerateAuditTriggers 'COMPONENTS'
	 END
	GO