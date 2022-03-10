
  	/*** DR-60395 Create Configure Reporting Services Integration Security Task - Feature						***/

	IF NOT exists (select * from FEATURE where FEATUREID = 80)
		begin
		PRINT '**** DR-60395 Inserting FEATURE.FEATUREID = 80'
		INSERT INTO FEATURE (FEATUREID, FEATURENAME, CATEGORYID, ISEXTERNAL, ISINTERNAL)
		VALUES (80, N'Reporting Services Integration', 9804, 0, 1)
		PRINT '**** DR-60395 Data has been successfully added to FEATURE table.'
		PRINT ''
		END
	ELSE
		PRINT '**** DR-60395 FEATURE.FEATUREID = 80 already exists.'
		PRINT ''
 	go

    /*** DR-60395 Create Configure Reporting Services Integration Security Task - Task						***/

	If NOT exists (select * from TASK where TASKID = 283)
        	BEGIN
         	 PRINT '**** DR-60395 Adding data TASK.TASKID = 283'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (283, N'Configure Reporting Services Integration',N'Ability to configure settings to enable integration with Reporting Services.')
        	 PRINT '**** DR-60395 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-60395 TASK.TASKID = 283 already exists'
         	PRINT ''
    	go

   	/*** DR-60395 Create Configure Reporting Services Integration Security Task - FeatureTask						***/

	IF NOT exists (select * from FEATURETASK where FEATUREID = 80 AND TASKID = 283)
		begin
		PRINT '**** DR-60395 Inserting FEATURETASK.FEATUREID = 80, TASKID = 283'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (80, 283)
		PRINT '**** DR-60395 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** DR-60395 FEATURETASK.FEATUREID = 80, TASKID = 283 already exists.'
		PRINT ''
 	go
	
   	/*** DR-60395 Create Configure Reporting Services Integration Security Task - Permission Definition						***/

	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 283
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** DR-60395 Adding TASK definition data PERMISSIONS.OBJECTKEY = 283'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 283, NULL, NULL, NULL, 32, 0)
        	 PRINT '**** DR-60395 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** DR-60395 TASK definition data PERMISSIONS.OBJECTKEY = 283 already exists'
		 PRINT ''
         	END
    	go
			   		 
   	/*** DR-60395 Create Configure Reporting Services Integration Security Task - Task Permissions						***/

	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 283
				and LEVELTABLE = 'ROLE'
				and LEVELKEY = -1)
        	BEGIN
         	 PRINT '**** DR-60395 Adding TASK data PERMISSIONS.OBJECTKEY = 283'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 283, NULL, 'ROLE', -1, 32, 0)
        	 PRINT '**** DR-60395 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** DR-60395 TASK data PERMISSIONS.OBJECTKEY = 283 already exists'
		 PRINT ''
         	END
    	go
		
    	/*** DR-60395 - ValidObject								***/

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82 932')
        	BEGIN
         	 PRINT '**** DR-60395 Adding data VALIDOBJECT.OBJECTDATA = 82 932'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82 932')
        	 PRINT '**** DR-60395 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-60395 VALIDOBJECT.OBJECTDATA = 82 932 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82  32')
        	BEGIN
         	 PRINT '**** DR-60395 Adding data VALIDOBJECT.OBJECTDATA = 82  32'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82  32')
        	 PRINT '**** DR-60395 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-60395 VALIDOBJECT.OBJECTDATA = 82  32 already exists'
         	PRINT ''
    	go


		
	
    /**********************************************************************************************************/
		/*** DR-60394 Configuration item and component for - Reporting Services Integration Settings    ***/
    /**********************************************************************************************************/
    IF NOT EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 283)
    BEGIN TRY
	BEGIN TRANSACTION
        PRINT '**** DR-60394 Adding data CONFIGURATIONITEM.TASKID = 283'
	    INSERT INTO CONFIGURATIONITEM(TASKID, TITLE, DESCRIPTION, URL) VALUES(
	    283,
	    N'Reporting Services Integration Settings', 
		N'Configure required settings for Reporting Services integration.', 
		N'/apps/#/configuration/reporting-settings')
        PRINT '**** DR-60394 Data successfully added to CONFIGURATIONITEM table.'
        PRINT ''

		INSERT CONFIGURATIONITEMCOMPONENTS (CONFIGITEMID, COMPONENTID)
			SELECT CI.CONFIGITEMID, CO.COMPONENTID
				FROM CONFIGURATIONITEM CI
				JOIN COMPONENTS CO on CO.COMPONENTNAME = 'Integration'
				WHERE CI.TASKID = 283
		
		PRINT '**** DR-60394 Data successfully added to CONFIGURATIONITEMCOMPONENTS table.'
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
         PRINT '**** DR-60394 CONFIGURATIONITEM.TASKID = 283 already exists'
         PRINT ''
    go
