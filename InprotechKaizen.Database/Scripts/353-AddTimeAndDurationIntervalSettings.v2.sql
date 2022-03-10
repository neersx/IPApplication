If not exists (Select * from SETTINGDEFINITION where SETTINGNAME = 'Time Interval in time picker' and SETTINGID = 39)
Begin
	Print '**** DR-76105 Inserting data SETTINGDEFINITION.SETTINGNAME = Time Interval in time picker'
	Insert Into SETTINGDEFINITION (SETTINGID,SETTINGNAME, DATATYPE, COMMENT, ISINTERNAL, ISEXTERNAL, VALUESPROVIDER)
		values (39, 'Time Interval in time picker', 'I',
		'Specify in minutes the time interval for Time Recording ''Start'' and ''Finish'' time picker. If greater than 1 minute, the NOW button will be disabled in time picker.', 1, 0, NULL)
	Print '**** DR-76105 Data successfully inserted in SETTINGDEFINITION table.'
	Print ''
End
Else
	If exists (Select 1 from SETTINGDEFINITION where SETTINGNAME = 'Time Interval in time picker' and SETTINGID = 39 and COMMENT like 'Specify in minutes the time interval for Time Recording ''Start'' and ''Finish'' time picker%')
	Begin
		Update SETTINGDEFINITION 
		set COMMENT = 'Specify in minutes the time interval for Time Recording ''Start'' and ''Finish'' time picker. If greater than 1 minute, the NOW button will be disabled in time picker.'
		where SETTINGNAME = 'Time Interval in time picker' 
		and SETTINGID = 39 
		and COMMENT like 'Specify in minutes the time interval for Time Recording ''Start'' and ''Finish'' time picker%'
	End
	Else Begin
		Print '**** DR-76105 SETTINGDEFINITION.SETTINGNAME = ''12-hour format'' already exists'
		Print ''
	End
go
If not exists (Select * from GROUPEDSETTINGS where GROUPID = 9 and SETTINGID = 39)
Begin
	Print '**** DR-76105 Inserting data into GROUPEDSETTINGS table'
	Insert Into GROUPEDSETTINGS (GROUPID,SETTINGID)
		values (9, 39)
	Print '**** DR-76105 Data successfully inserted in GROUPEDSETTINGS table.'
	Print ''
End
Else
	Print '**** DR-76105 Data already exists in GROUPEDSETTINGS table'
	Print ''
Go

If not exists (Select * from SETTINGVALUES where SETTINGID = 39)
Begin
	Print '**** DR-76105 Inserting data into SETTINGVALUES table'
	Insert Into SETTINGVALUES (SETTINGID)
		values (39)
	Print '**** DR-76105 Data successfully inserted in SETTINGVALUES table.'
	Print ''
End
Else
	Print '**** DR-76105 Data already exists in SETTINGVALUES table'
	Print ''
go

If not exists (Select * from SETTINGDEFINITION where SETTINGNAME = 'Time Interval in duration picker' and SETTINGID = 40)
Begin
	Print '**** DR-76105 Inserting data SETTINGDEFINITION.SETTINGNAME = Time Interval in duration picker'
	Insert Into SETTINGDEFINITION (SETTINGID,SETTINGNAME, DATATYPE,COMMENT, ISINTERNAL, ISEXTERNAL, VALUESPROVIDER)
		values (40, 'Time Interval in duration picker', 'I',
		'Specify in minutes the default duration interval for Time Recording ''Duration'' time picker', 1, 0, NULL)
	Print '**** DR-76105 Data successfully inserted in SETTINGDEFINITION table.'
	Print ''
End
Else
	Print '**** DR-76105 SETTINGDEFINITION.SETTINGNAME = ''12-hour format'' already exists'
	Print ''
go
If not exists (Select * from GROUPEDSETTINGS where GROUPID = 9 and SETTINGID = 40)
Begin
	Print '**** DR-76105 Inserting data into GROUPEDSETTINGS table'
	Insert Into GROUPEDSETTINGS (GROUPID,SETTINGID)
		values (9, 40)
	Print '**** DR-76105 Data successfully inserted in GROUPEDSETTINGS table.'
	Print ''
End
Else
	Print '**** DR-76105 Data already exists in GROUPEDSETTINGS table'
	Print ''
Go

If not exists (Select * from SETTINGVALUES where SETTINGID = 40)
Begin
	Print '**** DR-76105 Inserting data into SETTINGVALUES table'
	Insert Into SETTINGVALUES (SETTINGID)
		values (40)
	Print '**** DR-76105 Data successfully inserted in SETTINGVALUES table.'
	Print ''
End
Else
	Print '**** DR-76105 Data already exists in SETTINGVALUES table'
	Print ''
go