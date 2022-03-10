	/**********************************************************************************************************/
	/*** DR-73597 Configuration item for Maintain Currencies													***/
    /**********************************************************************************************************/
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 154 and URL is null)
    BEGIN 
		PRINT '**** DR-73597 Updating url for CONFIGURATIONITEM.TASKID = 154'

	    UPDATE CONFIGURATIONITEM
		SET URL = N'/apps/#/configuration/currencies'
		WHERE TASKID = 154

        PRINT '**** DR-73597 Data successfully updated for CONFIGURATIONITEM table.'
        PRINT ''
	END
    ELSE
         PRINT '**** DR-73597 CONFIGURATIONITEM.TASKID = 154 url already sets'
         PRINT ''
    go


