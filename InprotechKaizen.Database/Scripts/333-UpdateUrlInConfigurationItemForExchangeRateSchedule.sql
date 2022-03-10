	/**********************************************************************************************************/
	/*** DR-73604 CAbility to view the list of exchange rate schedules		    							***/
    /**********************************************************************************************************/
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 155 and URL is null)
    BEGIN 
		PRINT '**** DR-73604 Updating url for CONFIGURATIONITEM.TASKID = 155'

	    UPDATE CONFIGURATIONITEM
		SET URL = N'/apps/#/configuration/exchange-rate-schedule'
		WHERE TASKID = 155

        PRINT '**** DR-73604 Data successfully updated for CONFIGURATIONITEM table.'
        PRINT ''
	END
    ELSE
         PRINT '**** DR-73604 CONFIGURATIONITEM.TASKID = 155 url already sets'
         PRINT ''
    go
