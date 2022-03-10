If exists (select 1 from SITECONTROL S where S.NOTES is null and S.VERSIONID is null and 
		S.CONTROLID like 'Image Type for Case Header')
Begin
	Print '**** RFC56467 Update Notes and Version in SITECONTROL table'
	update S  set S.VERSIONID = R.VERSIONID, S.INITIALVALUE = '1201',
		S.NOTES = 'Specifies the image type that needs to be displayed in Case Header when configured via Screen Designer. If the image type has several images associated with it for a case, the image with the lowest Order is displayed in the header.'
	from SITECONTROL S left join RELEASEVERSIONS R on (R.VERSIONNAME = 'Inprotech 11') 
	where S.CONTROLID = 'Image Type for Case Header'	
	Print '**** RFC56467 Notes and Version update successfully in SITECONTROL table'
End
Else
Begin
	Print '**** RFC56467 Notes and Version already exist in SITECONTROL'
	Print ''
End

If exists (select 1 from SITECONTROL S where S.NOTES is null and S.VERSIONID is null and 
		S.CONTROLID like 'Policing Email Profile')
Begin
	Print '**** RFC56467 Update Notes and Version in SITECONTROL table'
	update S  set S.VERSIONID = R.VERSIONID, S.INITIALVALUE = 'None',
		S.NOTES = 'Holds the name of the SQL Server Database Mail profile that is being used to send reminders via e-mail when events are policed.'
	from SITECONTROL S left join RELEASEVERSIONS R on (R.VERSIONNAME = 'Inprotech 9.2.6') 
	where S.CONTROLID = 'Policing Email Profile'	
	Print '**** RFC56467 Notes and Version update successfully in SITECONTROL table'
End
Else
Begin
	Print '**** RFC56467 Notes and Version already exist in SITECONTROL'
	Print ''
End
