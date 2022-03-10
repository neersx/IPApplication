
/**** DR-58881 New User Preference */
	If not exists (Select * from SETTINGDEFINITION where SETTINGID = 35)
	Begin
		Print '**** DR-58881 Inserting data SETTINGDEFINITION.SETTINGNAME = Open document from iManage'
		Insert Into SETTINGDEFINITION (SETTINGID,SETTINGNAME, DATATYPE,COMMENT, ISINTERNAL, ISEXTERNAL, VALUESPROVIDER)
			values (35, 'Open document with iManage Work Link', 'B',
			'If set, the document will be opened with iManage Work Link; otherwise a copy of the document will be displayed or downloaded.', 1, 0, NULL)
		Print '**** DR-58881 Data successfully inserted in SETTINGDEFINITION table.'
		Print ''
	End
	Else
		Print '**** DR-58881 SETTINGDEFINITION.SETTINGNAME = ''Open document with iManage Work Link'' already exists'
		Print ''
	go
	
	If not exists (Select * from GROUPEDSETTINGS where GROUPID = 3 and SETTINGID = 35)
	Begin
		Print '**** DR-58881 Inserting data into GROUPEDSETTINGS table'
		Insert Into GROUPEDSETTINGS (GROUPID,SETTINGID)
			values (3, 35)
		Print '**** DR-58881 Data successfully inserted in GROUPEDSETTINGS table.'
		Print ''
	End
	Else
		Print '**** DR-58881 Data already exists in GROUPEDSETTINGS table'
		Print ''
	Go
	
	If not exists (Select * from SETTINGVALUES where SETTINGID = 35 AND IDENTITYID IS NULL)
	Begin
		Print '**** DR-58881 Inserting data into SETTINGVALUES table'
		Insert Into SETTINGVALUES (SETTINGID, COLBOOLEAN)
			values (35, 1)
		Print '**** DR-58881 Data successfully inserted in SETTINGVALUES table.'
		Print ''
	End
	Else
		Print '**** DR-58881 Data already exists in SETTINGVALUES table'
		Print ''
	go

	Update SETTINGGROUP
		SET [DESCRIPTION] = 'iManage Integration',
			NOTES = 'Controls management of integration with iManage Work or WorkSite'
	where GROUPID = 3
	and DESCRIPTION = 'WorkSite Integration'

	Update SETTINGDEFINITION
		SET SETTINGNAME = 'Login ID',
			COMMENT = 'The Login ID used for logging into iManage Work or WorkSite'
	where SETTINGID = 9
	and SETTINGNAME = 'WorkSite Login ID'

	Update SETTINGDEFINITION
		SET SETTINGNAME = 'Password',
			COMMENT = 'The Password used for logging into WorkSite or WorkSite'
	where SETTINGID = 10
	and SETTINGNAME = 'WorkSite Password'

	Update SETTINGDEFINITION
	SET SETTINGNAME = 'Open document with iManage Work Link'
	where SETTINGNAME = 'Open document from iManage'
	go