   	/**********************************************************************************************************/
    /*** DR-70753 Maintain Recordal Type - Task																***/
	/**********************************************************************************************************/
	If NOT exists (select * from TASK where TASKID = 289)
        	BEGIN
         	 PRINT '**** DR-70753 Adding data TASK.TASKID = 289'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (289, N'Maintain Recordal Type',N'Configure Recordal Types for Affected Cases')
        	 PRINT '**** DR-70753 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-70753 TASK.TASKID = 289 already exists'
         	PRINT ''
    	go

   	/**********************************************************************************************************/
    /*** DR-70753 Maintain Recordal Type - FeatureTask														***/
	/**********************************************************************************************************/
	IF NOT exists (select * from FEATURETASK where FEATUREID = 51 AND TASKID = 289)
		begin
		PRINT '**** DR-70753 Inserting FEATURETASK.FEATUREID = 51, TASKID = 289'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (51, 289)
		PRINT '**** DR-70753 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** DR-70753 FEATURETASK.FEATUREID = 51, TASKID = 289 already exists.'
		PRINT ''
 	go

   	/**********************************************************************************************************/
    /*** DR-70753 Maintain Recordal Type - Permission Definition											***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 289
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** DR-70753 Adding TASK definition data PERMISSIONS.OBJECTKEY = 289'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 289, NULL, NULL, NULL, 26, 0)
        	 PRINT '**** DR-70753 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** DR-70753 TASK definition data PERMISSIONS.OBJECTKEY = 289 already exists'
		 PRINT ''
         	END
    	go

    /**********************************************************************************************************/
    /*** DR-70753 Maintain Recordal Type - Task Permissions													***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 289
				and LEVELTABLE = 'ROLE'
				and LEVELKEY = -1)
        	BEGIN
         	 PRINT '**** DR-70753 Adding TASK data PERMISSIONS.OBJECTKEY = 289'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 289, NULL, 'ROLE', -1, 26, 0)
        	 PRINT '**** DR-70753 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** DR-70753 TASK data PERMISSIONS.OBJECTKEY = 289 already exists'
		 PRINT ''
         	END
    	go

   	/**********************************************************************************************************/
    /*** DR-70753 - ValidObject																				***/
	/**********************************************************************************************************/
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82 992')
        	BEGIN
         	 PRINT '**** DR-70753 Adding data VALIDOBJECT.OBJECTDATA = 82 992'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82 992')
        	 PRINT '**** DR-70753 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-70753 VALIDOBJECT.OBJECTDATA = 82 992 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82  92')
        	BEGIN
         	 PRINT '**** DR-70753 Adding data VALIDOBJECT.OBJECTDATA = 82  92'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82  92')
        	 PRINT '**** DR-70753 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-70753 VALIDOBJECT.OBJECTDATA = 82  92 already exists'
         	PRINT ''
    	go
    If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82 192')
        	BEGIN
         	 PRINT '**** RFC70753 Adding data VALIDOBJECT.OBJECTDATA = 82 192'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82 192')
        	 PRINT '**** RFC70753 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC70753 VALIDOBJECT.OBJECTDATA = 82 192 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82 892')
        	BEGIN
         	 PRINT '**** RFC70753 Adding data VALIDOBJECT.OBJECTDATA = 82 892'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82 892')
        	 PRINT '**** RFC70753 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC70753 VALIDOBJECT.OBJECTDATA = 82 892 already exists'
         	PRINT ''
    	go


	/**********************************************************************************************************/
	/*** DR-70753 Configuration item and component for - Maintain Recordal Type								***/
    /**********************************************************************************************************/
    IF NOT EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 289)
    BEGIN TRY
	BEGIN TRANSACTION
        PRINT '**** DR-60394 Adding data CONFIGURATIONITEM.TASKID = 289'
	    INSERT INTO CONFIGURATIONITEM(TASKID, TITLE, DESCRIPTION, URL) VALUES(
	    289,
	    N'Recordal Types', 
		N'Configure Recordal Type steps for Affected Cases for Assignment/Recordal cases.', 
		N'/apps/#/configuration/recordal-types')
        PRINT '**** DR-70753 Data successfully added to CONFIGURATIONITEM table.'
        PRINT ''

		INSERT CONFIGURATIONITEMCOMPONENTS (CONFIGITEMID, COMPONENTID)
			SELECT CI.CONFIGITEMID, CO.COMPONENTID
				FROM CONFIGURATIONITEM CI
				JOIN COMPONENTS CO on CO.COMPONENTNAME = 'General Configuration'
				WHERE CI.TASKID = 289
		
		PRINT '**** DR-70753 Data successfully added to CONFIGURATIONITEMCOMPONENTS table.'
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
         PRINT '**** DR-70753 CONFIGURATIONITEM.TASKID = 289 already exists'
         PRINT ''
    go


