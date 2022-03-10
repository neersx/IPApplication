	If not exists (Select * from SETTINGDEFINITION where SETTINGNAME = '12-hour format' and SETTINGID = 32)
	Begin
		Print '**** DR-51245 Inserting data SETTINGDEFINITION.SETTINGNAME = 12-hour format'
		Insert Into SETTINGDEFINITION (SETTINGID,SETTINGNAME, DATATYPE,COMMENT, ISINTERNAL, ISEXTERNAL, VALUESPROVIDER)
			values (32, '12-hour format', 'B',
			'Display all time entries in a 12-hour format', 1, 0, NULL)
		Print '**** DR-51245 Data successfully inserted in SETTINGDEFINITION table.'
		Print ''
	End
	Else
		Print '**** DR-51245 SETTINGDEFINITION.SETTINGNAME = ''12-hour format'' already exists'
		Print ''
	go
	If not exists (Select * from SETTINGGROUP where DESCRIPTION = 'Time Recording' and GROUPID = 9)
	Begin	
		Print '**** DR-51245 Inserting data SETTINGGROUP.DESCRIPTION = Time Recording'
		Insert Into SETTINGGROUP (GROUPID,DESCRIPTION, NOTES,OBJECTTABLE, OBJECTINTEGERKEY)
			values (9, 'Time Recording', 'Controls options for Time Recording', 'TASK', 282)
		Print '**** DR-51245 Data successfully inserted in SETTINGGROUP table.'
		Print ''
	End
	Else
		Print '**** DR-51245 SETTINGGROUP.DESCRIPTION = Event Notes already exists'
		Print ''
	go
	If not exists (Select * from GROUPEDSETTINGS where GROUPID = 9 and SETTINGID = 32)
	Begin
		Print '**** DR-51245 Inserting data into GROUPEDSETTINGS table'
		Insert Into GROUPEDSETTINGS (GROUPID,SETTINGID)
			values (9, 32)
		Print '**** DR-51245 Data successfully inserted in GROUPEDSETTINGS table.'
		Print ''
	End
	Else
		Print '**** DR-51245 Data already exists in GROUPEDSETTINGS table'
		Print ''
	Go

	If not exists (Select * from SETTINGVALUES where SETTINGID = 32)
	Begin
		Print '**** DR-51245 Inserting data into SETTINGVALUES table'
		Insert Into SETTINGVALUES (SETTINGID)
			values (32)
		Print '**** DR-51245 Data successfully inserted in SETTINGVALUES table.'
		Print ''
	End
	Else
		Print '**** DR-51245 Data already exists in SETTINGVALUES table'
		Print ''
	go

/**** DR-47996 Allow time valuation while entering based on a new User preference - Value time on entry*/
	If not exists (Select * from SETTINGDEFINITION where SETTINGNAME = 'Value time on entry' and SETTINGID = 33)
	Begin
		Print '**** DR-47996 Inserting data SETTINGDEFINITION.SETTINGNAME = Value time on entry'
		Insert Into SETTINGDEFINITION (SETTINGID,SETTINGNAME, DATATYPE,COMMENT, ISINTERNAL, ISEXTERNAL, VALUESPROVIDER)
			values (33, 'Value time on entry', 'B',
			'When set ON, time is valued on entry. When set OFF, time is valued on saving.', 1, 0, NULL)
		Print '**** DR-47996 Data successfully inserted in SETTINGDEFINITION table.'
		Print ''
	End
	Else
		Print '**** DR-47996 SETTINGDEFINITION.SETTINGNAME = ''Value time on entry'' already exists'
		Print ''
	go
	If not exists (Select * from SETTINGGROUP where DESCRIPTION = 'Time Recording' and GROUPID = 9)
	Begin	
		Print '**** DR-47996 Inserting data SETTINGGROUP.DESCRIPTION = Time Recording'
		Insert Into SETTINGGROUP (GROUPID,DESCRIPTION, NOTES,OBJECTTABLE, OBJECTINTEGERKEY)
			values (9, 'Time Recording', 'Controls options for Time Recording', 'TASK', 282)
		Print '**** DR-47996 Data successfully inserted in SETTINGGROUP table.'
		Print ''
	End
	Else
		Print '**** DR-47996 SETTINGGROUP.DESCRIPTION = Event Notes already exists'
		Print ''
	go
	If not exists (Select * from GROUPEDSETTINGS where GROUPID = 9 and SETTINGID = 33)
	Begin
		Print '**** DR-47996 Inserting data into GROUPEDSETTINGS table'
		Insert Into GROUPEDSETTINGS (GROUPID,SETTINGID)
			values (9, 33)
		Print '**** DR-47996 Data successfully inserted in GROUPEDSETTINGS table.'
		Print ''
	End
	Else
		Print '**** DR-47996 Data already exists in GROUPEDSETTINGS table'
		Print ''
	Go

	If not exists (Select * from SETTINGVALUES where SETTINGID = 33)
	Begin
		Print '**** DR-47996 Inserting data into SETTINGVALUES table'
		Insert Into SETTINGVALUES (SETTINGID)
			values (33)
		Print '**** DR-47996 Data successfully inserted in SETTINGVALUES table.'
		Print ''
	End
	Else
		Print '**** DR-47996 Data already exists in SETTINGVALUES table'
		Print ''
	go