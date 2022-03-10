
    /**********************************************************************************************************/
		/*** DR-60883 Access Case List Maintenance from Apps and Hybrid Configuration Pages    ***/
    /**********************************************************************************************************/
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 188)
    BEGIN TRY
	BEGIN TRANSACTION
        PRINT '**** DR-60883 Updating data CONFIGURATIONITEM.TASKID = 188'
	    UPDATE CONFIGURATIONITEM
		SET URL = N'/apps/#/configuration/caselist-maintenance'
		WHERE TASKID = 188 
        PRINT '**** DR-60883 Data successfully updated'
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
         PRINT '**** DR-60883 CONFIGURATIONITEM.TASKID = 188 does not exist'
         PRINT ''
    go
