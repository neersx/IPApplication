   	/*** DR-62498 Create Task Planner Search Column Maintenance page - Task						***/

	If NOT exists (select * from TASK where TASKID = 284)
        	BEGIN
         	 PRINT '**** DR-62498 Adding data TASK.TASKID = 284'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (284, N'Maintain Task Planner Search Columns',N'Create, update or delete task planner search columns')
        	 PRINT '**** DR-62498 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62498 TASK.TASKID = 284 already exists'
         	PRINT ''
    	go

    	/*** DR-62498 Create Task Planner Search Column Maintenance page - FeatureTask						***/

	IF NOT exists (select * from FEATURETASK where FEATUREID = 81 AND TASKID = 284)
		begin
		PRINT '**** DR-62498 Inserting FEATURETASK.FEATUREID = 81, TASKID = 284'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (81, 284)
		PRINT '**** DR-62498 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** DR-62498 FEATURETASK.FEATUREID = 81, TASKID = 284 already exists.'
		PRINT ''
 	go
    	/*** DR-62498 Create Task Planner Search Column Maintenance page - Permission Definition						***/

	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 284
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** DR-62498 Adding TASK definition data PERMISSIONS.OBJECTKEY = 284'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 284, NULL, NULL, NULL, 26, 0)
        	 PRINT '**** DR-62498 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** DR-62498 TASK definition data PERMISSIONS.OBJECTKEY = 284 already exists'
		 PRINT ''
         	END
    	go

    	/*** DR-62498 Create Task Planner Search Column Maintenance page - Task Permissions						***/

	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 284
				and LEVELTABLE = 'ROLE'
				and LEVELKEY = -1)
        	BEGIN
         	 PRINT '**** DR-62498 Adding TASK data PERMISSIONS.OBJECTKEY = 284'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 284, NULL, 'ROLE', -1, 26, 0)
        	 PRINT '**** DR-62498 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** DR-62498 TASK data PERMISSIONS.OBJECTKEY = 284 already exists'
		 PRINT ''
         	END
    	go
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 284
				and LEVELTABLE = 'ROLE'
				and LEVELKEY = -21)
        	BEGIN
         	 PRINT '**** DR-62498 Adding TASK data PERMISSIONS.OBJECTKEY = 284'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 284, NULL, 'ROLE', -21, 26, 0)
        	 PRINT '**** DR-62498 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** DR-62498 TASK data PERMISSIONS.OBJECTKEY = 284 already exists'
		 PRINT ''
         	END
    	go

    	/*** DR-62498 - ValidObject								***/

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82 942')
        	BEGIN
         	 PRINT '**** DR-62498 Adding data VALIDOBJECT.OBJECTDATA = 82 942'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82 942')
        	 PRINT '**** DR-62498 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62498 VALIDOBJECT.OBJECTDATA = 82 942 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82  42')
        	BEGIN
         	 PRINT '**** DR-62498 Adding data VALIDOBJECT.OBJECTDATA = 82  42'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82  42')
        	 PRINT '**** DR-62498 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62498 VALIDOBJECT.OBJECTDATA = 82  42 already exists'
         	PRINT ''
    	go
