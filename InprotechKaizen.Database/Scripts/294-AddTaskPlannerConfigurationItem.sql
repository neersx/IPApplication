    /**********************************************************************************************************/
		/*** DR-65868 Access Task Planner Column Maintenance from the Configuration page    ***/
    /**********************************************************************************************************/
    IF NOT EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 284)
    BEGIN TRY
	BEGIN TRANSACTION
        PRINT '**** DR-65868 Adding data CONFIGURATIONITEM.TASKID = 284'
	    INSERT INTO CONFIGURATIONITEM(TASKID, TITLE, DESCRIPTION, URL) VALUES(
	    284,
	    N'Task Planner Search Columns', 
		N'Maintain Task Planner Search Columns.', 
		N'/apps/#/search/columns?queryContextKey=970')
        PRINT '**** DR-65868 Data successfully added to CONFIGURATIONITEM table.'
        PRINT ''

		INSERT CONFIGURATIONITEMCOMPONENTS (CONFIGITEMID, COMPONENTID)
			SELECT CI.CONFIGITEMID, CO.COMPONENTID
				FROM CONFIGURATIONITEM CI
				JOIN COMPONENTS CO on CO.COMPONENTNAME = 'Task Planner'
				WHERE CI.TASKID = 284
		
		PRINT '**** DR-65868 Data successfully added to CONFIGURATIONITEMCOMPONENTS table.'
        PRINT ''
    COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK

		DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
		SELECT @ErrMsg = ERROR_MESSAGE(), @ErrSeverity = ERROR_SEVERITY()

		RAISERROR(@ErrMsg, @ErrSeverity, 1)
	END CATCH
    ELSE
         PRINT '**** DR-65868 CONFIGURATIONITEM.TASKID = 284 already exists'
         PRINT ''
    go
