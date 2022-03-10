
	/**********************************************************************************************************/
	/*** DR-61528 Configuration item for - Maintain Keywords								***/
    /**********************************************************************************************************/
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 206 and URL is null)
    BEGIN
        PRINT '**** DR-61528 Adding data CONFIGURATIONITEM.TASKID = 206'

	    UPDATE CONFIGURATIONITEM 
		Set URL = '/apps/#/configuration/keywords' 
		Where TASKID = 206;

        PRINT '**** DR-61528 Data successfully updated to CONFIGURATIONITEM table.'
        PRINT ''

	END
    ELSE
         PRINT '**** DR-61528 CONFIGURATIONITEM.TASKID = 206 URL already exists'
         PRINT ''
    go


