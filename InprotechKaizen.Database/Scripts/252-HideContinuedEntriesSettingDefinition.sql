	If exists (Select * from SETTINGDEFINITION where SETTINGNAME = 'Hide Continued Entries' and SETTINGID = 18 and COMMENT = 'Suppress the display of continued time entries in list view.')
	Begin
		Print '**** DR-48697 Updating data SETTINGDEFINITION.SETTINGNAME = Hide Continued Entries'
		Update SETTINGDEFINITION
		set COMMENT = N'Parent rows of continued time entries are not shown'
		where SETTINGID = 18 
		and COMMENT = 'Suppress the display of continued time entries in list view.'
		Print '**** DR-48697 Data successfully updated in SETTINGDEFINITION table.'
		Print ''
	End
	Else
	Begin
		Print '**** DR-48697 SETTINGDEFINITION.SETTINGNAME = ''Hide Continued Entries'' already up to date.'	
		Print ''
	End
	go