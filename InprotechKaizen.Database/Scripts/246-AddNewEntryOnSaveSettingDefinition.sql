	If not exists (Select * from SETTINGDEFINITION where SETTINGNAME = 'Automatically add new entry on save' and SETTINGID = 31)
	Begin
		Print '**** DR-50639 Inserting data SETTINGDEFINITION.SETTINGNAME = Automatically add new entry on save'
		Insert Into SETTINGDEFINITION (SETTINGID,SETTINGNAME, DATATYPE,COMMENT, ISINTERNAL, ISEXTERNAL, VALUESPROVIDER)
			values (31, 'Automatically add new entry on save', 'B',
			'Eliminates the need to click the Add button between multiple time entries by automatically initiating the next new entry.', 1, 0, NULL)
		Print '**** DR-50639 Data successfully inserted in SETTINGDEFINITION table.'
		Print ''
	End
	Else
		Print '**** DR-50639 SETTINGDEFINITION.SETTINGNAME = ''Automatically add new entry on save'' already exists'
		Print ''
	go
	If not exists (Select * from SETTINGGROUP where DESCRIPTION = 'Time Recording' and GROUPID = 9)
	Begin	
		Print '**** DR-50639 Inserting data SETTINGGROUP.DESCRIPTION = Time Recording'
		Insert Into SETTINGGROUP (GROUPID,DESCRIPTION, NOTES,OBJECTTABLE, OBJECTINTEGERKEY)
			values (9, 'Time Recording', 'Controls options for Time Recording', 'TASK', 282)
		Print '**** DR-50639 Data successfully inserted in SETTINGGROUP table.'
		Print ''
	End
	Else
		Print '**** DR-50639 SETTINGGROUP.DESCRIPTION = Event Notes already exists'
		Print ''
	go
	If not exists (Select * from GROUPEDSETTINGS where GROUPID = 9 and SETTINGID = 31)
	Begin
		Print '**** DR-50639 Inserting data into GROUPEDSETTINGS table'
		Insert Into GROUPEDSETTINGS (GROUPID,SETTINGID)
			values (9, 31)
		Print '**** DR-50639 Data successfully inserted in GROUPEDSETTINGS table.'
		Print ''
	End
	Else
		Print '**** DR-50639 Data already exists in GROUPEDSETTINGS table'
		Print ''
	Go

	If not exists (Select * from SETTINGVALUES where SETTINGID = 31)
	Begin
		Print '**** DR-50639 Inserting data into SETTINGVALUES table'
		Insert Into SETTINGVALUES (SETTINGID)
			values (31)
		Print '**** DR-50639 Data successfully inserted in SETTINGVALUES table.'
		Print ''
	End
	Else
		Print '**** DR-50639 Data already exists in SETTINGVALUES table'
		Print ''
	go