
	/**********************************************************************************************************/
	/*** DR-59969 Configuration item for - Maintain Office File Locations									***/
    /**********************************************************************************************************/
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 208 and URL is null)
    BEGIN
        PRINT '**** DR-59969 Adding data CONFIGURATIONITEM.TASKID = 208'

	    UPDATE CONFIGURATIONITEM 
		Set URL = '/apps/#/configuration/file-location-office' 
		Where TASKID = 208;

        PRINT '**** DR-59969 Data successfully updated to CONFIGURATIONITEM table.'
        PRINT ''

	END
    ELSE
         PRINT '**** DR-59969 CONFIGURATIONITEM.TASKID = 208 URL already exists'
         PRINT ''
    go


