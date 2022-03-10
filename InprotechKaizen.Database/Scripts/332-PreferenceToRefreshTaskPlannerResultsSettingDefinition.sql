	If not exists (Select * from SETTINGDEFINITION where SETTINGNAME = 'Automatically refresh Task Planner Results' and SETTINGID = 38)
	Begin
		Print '**** DR-70054 Inserting data SETTINGDEFINITION.SETTINGNAME = Automatically refresh Task Planner Results'
		Insert Into SETTINGDEFINITION (SETTINGID,SETTINGNAME, DATATYPE,COMMENT, ISINTERNAL, ISEXTERNAL, VALUESPROVIDER)
			values (38, 'Automatically refresh Task Planner Results', 'B',
			'Task Planner results will be automatically refreshed  after a change is made via the Bulk or Tasks menus that will affect the list.', 1, 0, NULL)
		Print '**** DR-70054 Data successfully inserted in SETTINGDEFINITION table.'
		Print ''
	End
	Else
		Print '**** DR-70054 SETTINGDEFINITION.SETTINGNAME = ''Automatically refresh Task Planner Results'' already exists'
		Print ''
	go
	If not exists (Select * from SETTINGGROUP where DESCRIPTION = 'Task Planner' and GROUPID = 10)
	Begin	
		Print '**** DR-70054 Inserting data SETTINGGROUP.DESCRIPTION = Task Planner'
		Insert Into SETTINGGROUP (GROUPID,DESCRIPTION, NOTES,OBJECTTABLE, OBJECTINTEGERKEY)
			values (10, 'Task Planner', 'Controls options for Task Planner Results', 'TASK', NULL)
		Print '**** DR-70054 Data successfully inserted in SETTINGGROUP table.'
		Print ''
	End
	Else
		Print '**** DR-70054 SETTINGGROUP.DESCRIPTION = Task Planner already exists'
		Print ''
	go
	If not exists (Select * from GROUPEDSETTINGS where GROUPID = 10 and SETTINGID = 38)
	Begin
		Print '**** DR-70054 Inserting data into GROUPEDSETTINGS table'
		Insert Into GROUPEDSETTINGS (GROUPID,SETTINGID)
			values (10, 38)
		Print '**** DR-70054 Data successfully inserted in GROUPEDSETTINGS table.'
		Print ''
	End
	Else
		Print '**** DR-70054 Data already exists in GROUPEDSETTINGS table'
		Print ''
	Go

	If not exists (Select * from SETTINGVALUES where SETTINGID = 38)
	Begin
		Print '**** DR-70054 Inserting data into SETTINGVALUES table'
		Insert Into SETTINGVALUES (SETTINGID,COLBOOLEAN)
			values (38,1)
		Print '**** DR-70054 Data successfully inserted in SETTINGVALUES table.'
		Print ''
	End
	Else
		Print '**** DR-70054 Data already exists in SETTINGVALUES table'
		Print ''
	go