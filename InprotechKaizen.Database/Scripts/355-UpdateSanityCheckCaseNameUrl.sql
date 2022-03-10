/**********************************************************************************************************/
/*** DR-76608 Sanity check cases configuration item to launch the apps version							***/
/**********************************************************************************************************/
	PRINT '**** DR-76608 Set APPs URL for task 158 - Maintain Sanity Check Rules for Cases ****'

	UPDATE CONFIGURATIONITEM set URL = '/apps/#/configuration/sanity-check/case',
	IEONLY=0
	WHERE TASKID = 158
	print '**** DR-76608 Set APPs URL for task 158 - Maintain Sanity Check Rules for Cases****'
	print ''
	go

/**********************************************************************************************************/
/*** DR-79303 Sanity check names configuration item to launch the apps version							***/
/**********************************************************************************************************/
	PRINT '**** DR-79303 Set APPs URL for task 207 - Maintain Sanity Check Rules for Names ****'

	UPDATE CONFIGURATIONITEM set URL = '/apps/#/configuration/sanity-check/name',
	IEONLY=0
	WHERE TASKID = 207
	print '**** DR-79303 Set APPs URL for task 207 - Maintain Sanity Check Rules for Names ****'
	print ''
	go