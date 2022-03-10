   /**********************************************************************************************************/
    /*** RFC43202 Configuration item for Maintain Application Link Security     			    ***/
    /**********************************************************************************************************/
    IF NOT EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 228)
    BEGIN
         PRINT '**** RFC43202 Adding data CONFIGURATIONITEM.TASKID = 228'
	    INSERT INTO CONFIGURATIONITEM(TASKID, TITLE, DESCRIPTION, URL) VALUES(
	    228,
	    N'Maintain Event Note Types',
	    N'Create, update or delete event note types in the system.',
		N'apps/configuration/events/eventnotetype/#/')
        PRINT '**** RFC43202 Data successfully added to CONFIGURATIONITEM table.'
        PRINT ''
    END
    ELSE
		BEGIN
			UPDATE CONFIGURATIONITEM
				SET URL = '/apps/configuration/events/eventnotetype/#/'
				WHERE TASKID = 228
			PRINT '**** RFC43202 CONFIGURATIONITEM.TASKID = 228 already exists'
			PRINT ''
		END
    go