/*** DR-72138 Create 'Maintain Task Planner Configuration' security task - Task						***/
		If NOT exists (select * from TASK where TASKID = 291)
        	BEGIN
         	 PRINT '**** DR-72138 Adding data TASK.TASKID = 291'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (291, N'Maintain Task Planner Configuration',N'View and update Task Planner configuration.')
        	 PRINT '**** DR-72138 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-72138 TASK.TASKID = 291 already exists'
         	PRINT ''
    	go

    	/*** DR-72138 Create 'Maintain Task Planner Configuration' security task - FeatureTask						***/
	IF NOT exists (select * from FEATURETASK where FEATUREID = 81 AND TASKID = 291)
		begin
		PRINT '**** DR-72138 Inserting FEATURETASK.FEATUREID = 81, TASKID = 291'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (81, 291)
		PRINT '**** DR-72138 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** DR-72138 FEATURETASK.FEATUREID = 81, TASKID = 291 already exists.'
		PRINT ''
 	go
/*** DR-72138 Create 'Maintain Task Planner Configuration' security task - Permission Definition						***/
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 291
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** DR-72138 Adding TASK definition data PERMISSIONS.OBJECTKEY = 291'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 291, NULL, NULL, NULL, 32, 0)
        	 PRINT '**** DR-72138 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** DR-72138 TASK definition data PERMISSIONS.OBJECTKEY = 291 already exists'
		 PRINT ''
         	END
    	go

/*** DR-72138 Create 'Maintain Task Planner Configuration' security task - Task Permissions						***/
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 291
				and LEVELTABLE = 'ROLE'
				and LEVELKEY = -1)
        	BEGIN
         	 PRINT '**** DR-72138 Adding TASK data PERMISSIONS.OBJECTKEY = 291'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 291, NULL, 'ROLE', -1, 32, 0)
        	 PRINT '**** DR-72138 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** DR-72138 TASK data PERMISSIONS.OBJECTKEY = 291 already exists'
		 PRINT ''
         	END
    	go

/*** DR-72138 - ValidObject								***/
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '92  12')
        	BEGIN
         	 PRINT '**** DR-72138 Adding data VALIDOBJECT.OBJECTDATA = 92  12'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '92  12')
        	 PRINT '**** DR-72138 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-72138 VALIDOBJECT.OBJECTDATA = 92  12 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '92 811')
        	BEGIN
         	 PRINT '**** DR-72138 Adding data VALIDOBJECT.OBJECTDATA = 92 811'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '92 811')
        	 PRINT '**** DR-72138 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-72138 VALIDOBJECT.OBJECTDATA = 92 811 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '92 112')
        	BEGIN
         	 PRINT '**** DR-72138 Adding data VALIDOBJECT.OBJECTDATA = 92 112'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '92 112')
        	 PRINT '**** DR-72138 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-72138 VALIDOBJECT.OBJECTDATA = 92 112 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '92 912')
        	BEGIN
         	 PRINT '**** DR-72138 Adding data VALIDOBJECT.OBJECTDATA = 92 912'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '92 912')
        	 PRINT '**** DR-72138 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-72138 VALIDOBJECT.OBJECTDATA = 92 912 already exists'
         	PRINT ''
    	go
