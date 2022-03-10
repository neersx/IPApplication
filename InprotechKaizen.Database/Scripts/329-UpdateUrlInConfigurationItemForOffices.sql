	/**********************************************************************************************************/
	/*** DR-59534 Configuration item for Maintain Offices													***/
    /**********************************************************************************************************/
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 181 and URL is null)
    BEGIN 
		PRINT '**** DR-59534 Updating url for CONFIGURATIONITEM.TASKID = 181'

	    UPDATE CONFIGURATIONITEM
		SET URL = N'/apps/#/configuration/offices'
		WHERE TASKID = 181

        PRINT '**** DR-59534 Data successfully updated for CONFIGURATIONITEM table.'
        PRINT ''
	END
    ELSE
         PRINT '**** DR-59534 CONFIGURATIONITEM.TASKID = 181 url already sets'
         PRINT ''
    go


