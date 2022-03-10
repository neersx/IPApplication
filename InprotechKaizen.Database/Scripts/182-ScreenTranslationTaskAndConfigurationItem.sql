   	/**********************************************************************************************************/
    	/*** RFC70975 Task security for Maintain screen translations - Task						***/
	/**********************************************************************************************************/
	If NOT exists (select * from TASK where TASKID = 274)
        	BEGIN
         	 PRINT '**** RFC70975 Adding data TASK.TASKID = 274'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (274, N'Maintain Screen Translations',N'Maintain screen translations for different languages and cultures')
        	 PRINT '**** RFC70975 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC70975 TASK.TASKID = 274 already exists'
         	PRINT ''
    	go

   	/**********************************************************************************************************/
    	/*** RFC70975 Task security for Maintain screen translations - FeatureTask						***/
	/**********************************************************************************************************/
	IF NOT exists (select * from FEATURETASK where FEATUREID = 51 AND TASKID = 274)
		begin
		PRINT '**** RFC70975 Inserting FEATURETASK.FEATUREID = 51, TASKID = 274'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (51, 274)
		PRINT '**** RFC70975 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** RFC70975 FEATURETASK.FEATUREID = 51, TASKID = 274 already exists.'
		PRINT ''
 	go

   	/**********************************************************************************************************/
    	/*** RFC70975 Task security for Maintain screen translations - Permission Definition						***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 274
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** RFC70975 Adding TASK definition data PERMISSIONS.OBJECTKEY = 274'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 274, NULL, NULL, NULL, 32, 0)
        	 PRINT '**** RFC70975 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** RFC70975 TASK definition data PERMISSIONS.OBJECTKEY = 274 already exists'
		 PRINT ''
         	END
    	go

   	/**********************************************************************************************************/
    	/*** RFC70975 - ValidObject								***/
	/**********************************************************************************************************/
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '72  42')
        	BEGIN
         	 PRINT '**** RFC70975 Adding data VALIDOBJECT.OBJECTDATA = 72  42'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '72  42')
        	 PRINT '**** RFC70975 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC70975 VALIDOBJECT.OBJECTDATA = 72  42 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '72 142')
        	BEGIN
         	 PRINT '**** RFC70975 Adding data VALIDOBJECT.OBJECTDATA = 72 142'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '72 142')
        	 PRINT '**** RFC70975 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC70975 VALIDOBJECT.OBJECTDATA = 72 142 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '72 942')
        	BEGIN
         	 PRINT '**** RFC70975 Adding data VALIDOBJECT.OBJECTDATA = 72 942'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '72 942')
        	 PRINT '**** RFC70975 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC70975 VALIDOBJECT.OBJECTDATA = 72 942 already exists'
         	PRINT ''
    	go

    /**********************************************************************************************************/
		/*** DR-29825 Configuration item and component for - Maintain Screen Translations    ***/
    /**********************************************************************************************************/
    IF NOT EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 274)
    BEGIN TRY
	BEGIN TRANSACTION
        PRINT '**** DR-29825 Adding data CONFIGURATIONITEM.TASKID = 274'
	    INSERT INTO CONFIGURATIONITEM(TASKID, TITLE, DESCRIPTION, URL) VALUES(
	    274,
	    N'Screen Translations Utility',
	    N'Maintain screen translations for different languages and cultures.', '/apps/#/configuration/system/mui/screen-translations-utility')
        PRINT '**** DR-29825 Data successfully added to CONFIGURATIONITEM table.'
        PRINT ''

		INSERT CONFIGURATIONITEMCOMPONENTS (CONFIGITEMID, COMPONENTID)
			SELECT CI.CONFIGITEMID, CO.COMPONENTID
				FROM CONFIGURATIONITEM CI
				JOIN COMPONENTS CO on CO.COMPONENTNAME = 'General Configuration'
				WHERE CI.TASKID = 274
		
		PRINT '**** DR-29825 Data successfully added to CONFIGURATIONITEMCOMPONENTS table.'
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
         PRINT '**** DR-29825 CONFIGURATIONITEM.TASKID = 274 already exists'
         PRINT ''
    go
