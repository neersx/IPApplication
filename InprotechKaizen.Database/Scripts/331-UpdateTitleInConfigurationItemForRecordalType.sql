/**********************************************************************************************************/
	/*** DR-74543 Remove 'Maintain' text from 'Maintain Recordal Types' link in Configuration				***/
    /**********************************************************************************************************/
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 289 AND TITLE = 'Maintain Recordal Types')
    BEGIN 
        PRINT '**** DR-74543 Update title for CONFIGURATIONITEM.TASKID = 289'
		UPDATE CONFIGURATIONITEM SET TITLE = 'Recordal Types'
		WHERE TASKID = 289 AND TITLE = 'Maintain Recordal Types'
        PRINT '**** DR-74543 Data successfully updated to CONFIGURATIONITEM table.'
        PRINT ''

	END
    ELSE
         PRINT '**** DR-74543 CONFIGURATIONITEM.TASKID = 289 Title already updated'
         PRINT ''
    go