    /**********************************************************************************************************/
		/*** DR-72138 Access Task Planner Configuration from the Configuration page    ***/
    /**********************************************************************************************************/
    IF NOT EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 291)
    BEGIN TRY
	BEGIN TRANSACTION
        PRINT '**** DR-72138 Adding data CONFIGURATIONITEM.TASKID = 291'
	    INSERT INTO CONFIGURATIONITEM(TASKID, TITLE, DESCRIPTION, URL) VALUES(
	    291,
	    N'Task Planner Configuration', 
		N'View and update configuration for the Task Planner module, including setting the saved search that will display by default on each tab.', 
		N'/apps/#/configuration/task-planner-configuration')
        PRINT '**** DR-72138 Data successfully added to CONFIGURATIONITEM table.'
        PRINT ''

		INSERT CONFIGURATIONITEMCOMPONENTS (CONFIGITEMID, COMPONENTID)
			SELECT CI.CONFIGITEMID, CO.COMPONENTID
				FROM CONFIGURATIONITEM CI
				JOIN COMPONENTS CO on CO.COMPONENTNAME = 'Task Planner'
				WHERE CI.TASKID = 291
		
		PRINT '**** DR-72138 Data successfully added to CONFIGURATIONITEMCOMPONENTS table.'
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
         PRINT '**** DR-72138 CONFIGURATIONITEM.TASKID = 291 already exists'
         PRINT ''
    go
