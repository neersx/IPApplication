/**** DR-58525 Add a Configuration Setting for Search Export Execution Time Limit */
	If not exists (Select * from SETTINGDEFINITION where SETTINGNAME = 'Search Reports generation timeout' and SETTINGID = 34)
	Begin
		Print '**** DR-58525 Inserting data SETTINGDEFINITION.SETTINGNAME = Search Export generation timeout'
		Insert Into SETTINGDEFINITION (SETTINGID, SETTINGNAME, DATATYPE, COMMENT, ISINTERNAL, ISEXTERNAL, VALUESPROVIDER)
			values (34, 'Search Reports generation timeout', 'I',
			'Specify the time duration (in seconds) from initial request, for which to push the generation of exported Search Report to the background. Default value is 15. Maximum valid value is 90.', 1, 1, NULL)
		Print '**** DR-58525 Data successfully inserted in SETTINGDEFINITION table.'
		Print ''
	End
	Else
		Print '**** DR-58525 SETTINGDEFINITION.SETTINGNAME = ''Search Reports generation timeout'' already exists'
		Print ''
	go
	
	If not exists (Select * from SETTINGVALUES where SETTINGID = 34)
	Begin
		Print '**** DR-58525 Inserting data into SETTINGVALUES table'
		Insert Into SETTINGVALUES (SETTINGID, COLINTEGER)
			values (34, 15)
		Print '**** DR-58525 Data successfully inserted in SETTINGVALUES table.'
		Print ''
	End
	Else
		Print '**** DR-58525 Data already exists in SETTINGVALUES table'
		Print ''
	go