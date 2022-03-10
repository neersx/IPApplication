    /**********************************************************************************************************/
		/*** DR-72138 Insert default task planner profile tabs    ***/
    /**********************************************************************************************************/
    IF NOT EXISTS (SELECT * FROM TASKPLANNERTABSBYPROFILE WHERE PROFILEID IS NULL)
    BEGIN TRY
	BEGIN TRANSACTION
        PRINT '**** DR-72138 Adding default tab data for My Reminders'
	    INSERT INTO TASKPLANNERTABSBYPROFILE(TABSEQUENCE, QUERYID) VALUES(1,-31)
        PRINT '**** DR-72138 Adding default tab data for My Due Dates'
	    INSERT INTO TASKPLANNERTABSBYPROFILE(TABSEQUENCE, QUERYID) VALUES(2,-29)
        PRINT '**** DR-72138 Adding default tab data for My Team''s Tasks'
	    INSERT INTO TASKPLANNERTABSBYPROFILE(TABSEQUENCE, QUERYID) VALUES(3,-28)
        PRINT '**** DR-72138 default tabs data successfully added to TASKPLANNERTABSBYPROFILE table.'
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
         PRINT '**** DR-72138 Default tabs data already exists'
         PRINT ''
    go
