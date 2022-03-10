    /**********************************************************************************************************/
    /*** RFC26050 Configuration item for Maintain Application Link Security     			    ***/
    /**********************************************************************************************************/
    IF NOT EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 225)
    BEGIN
         PRINT '**** RFC26050 Adding data CONFIGURATIONITEM.TASKID = 225'
	    INSERT INTO CONFIGURATIONITEM(TASKID, TITLE, DESCRIPTION, URL) VALUES(
	    225,
	    N'Maintain Application Link Security',
	    N'Generate and update security tokens for application links.',
		N'/apps/#/integration/externalapplication')
        PRINT '**** RFC26050 Data successfully added to CONFIGURATIONITEM table.'
		PRINT ''
    END
    ELSE
		BEGIN
			UPDATE CONFIGURATIONITEM
				SET URL = '/apps/#/integration/externalapplication'
				WHERE TASKID = 225
			 PRINT '**** RFC26050 CONFIGURATIONITEM.TASKID = 225 already exists'
			 PRINT ''
		 END
    go
