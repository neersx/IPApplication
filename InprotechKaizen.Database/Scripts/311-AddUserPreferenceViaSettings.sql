If exists (SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'SETTINGVALUES' AND COLUMN_NAME = 'COLCHARACTER' and UPPER(DATA_TYPE) = 'NVARCHAR' and CHARACTER_MAXIMUM_LENGTH <> -1)
Begin
	ALTER TABLE SETTINGVALUES DISABLE TRIGGER ALL
	PRINT '*** DR-67235 Altering COLUMN SETTINGVALUES.COLCHARACTER ***'
	ALTER TABLE SETTINGVALUES ALTER COLUMN COLCHARACTER nvarchar(max) NULL
	PRINT '*** DR-67235 SETTINGVALUES.COLCHARACTER column has been altered to nvarchar(max)***'
	PRINT ''

	ALTER TABLE SETTINGVALUES ENABLE TRIGGER ALL

End
Else
Begin
	PRINT '*** DR-67235 SETTINGVALUES.COLCHARACTER has already been converted to nvarchar(max) ***'
End
GO

-- Regenerate audit trigger on OPENITEM table
IF dbo.fn_IsAuditSchemaConsistent('SETTINGVALUES') = 0
BEGIN
   EXEC ipu_UtilGenerateAuditTriggers 'SETTINGVALUES'
END
GO

If not exists (Select * from SETTINGDEFINITION where SETTINGNAME = 'Inprotech Web Applications Home Page' and SETTINGID = 36)
Begin
	Print '**** DR-67235 Inserting data SETTINGDEFINITION.SETTINGNAME = ''Inprotech Web Applications Home Page'''
	Insert Into SETTINGDEFINITION (SETTINGID,SETTINGNAME, DATATYPE,COMMENT, ISINTERNAL, ISEXTERNAL, VALUESPROVIDER)
		values (36, 'Inprotech Web Applications Home Page', 'C',
		'The home page for the user when Inprotech Web Apps is loaded.', 1, 1, NULL)
	Print '**** DR-67235 Data successfully inserted in SETTINGDEFINITION table.'
	Print ''
End
Else
	Print '**** DR-67235 SETTINGDEFINITION.SETTINGNAME = ''Inprotech Web Applications Home Page'' already exists'
	Print ''
go

If not exists (Select * from SETTINGDEFINITION where SETTINGNAME = 'Working hours' and SETTINGID = 37)
Begin
	Print '**** DR-67234 Inserting data SETTINGDEFINITION.SETTINGNAME = ''Working Hours'''
	Insert Into SETTINGDEFINITION (SETTINGID,SETTINGNAME, DATATYPE,COMMENT, ISINTERNAL, ISEXTERNAL, VALUESPROVIDER)
		values (37, 'Working Hours', 'C',
		'Specify preference for working hours. This is currently utilized to determine time range for the Time Gaps.', 1, 0, NULL)
	Print '**** DR-67234 Data successfully inserted in SETTINGDEFINITION table.'
	Print ''
End
Else
	Print '**** DR-67234 SETTINGDEFINITION.SETTINGNAME = ''Inprotech Web Applications Home Page'' already exists'
	Print ''
go

If not exists (Select * from SETTINGVALUES where SETTINGID = 37)
Begin
	Print '**** DR-67234 Inserting data into SETTINGVALUES table'
	Print '*** Setting FromSeconds to 08:00 and ToSeconds to 18:00... '
	Insert Into SETTINGVALUES (SETTINGID, COLCHARACTER) values (37, '{ "FromSeconds": 28800, "ToSeconds": 64800 }')
	Print '**** DR-67234 Data successfully inserted in SETTINGVALUES table.'
	Print ''
End
Else
	Print '**** DR-67234 Data already exists in SETTINGVALUES table'
	Print ''
go