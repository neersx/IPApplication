    	/*** DR-63953 Apply new Security Task and Licensing for Task Planner access - Feature						***/
	IF NOT exists (select * from FEATURE where FEATUREID = 81)
		begin
		PRINT '**** DR-63953 Inserting FEATURE.FEATUREID = 81'
		INSERT INTO FEATURE (FEATUREID, FEATURENAME, CATEGORYID, ISEXTERNAL, ISINTERNAL)
		VALUES (81, N'Task Planner', 9806, 0, 1)
		PRINT '**** DR-63953 Data has been successfully added to FEATURE table.'
		PRINT ''
		END
	ELSE
		PRINT '**** DR-63953 FEATURE.FEATUREID = 81 already exists.'
		PRINT ''
 	go

    	/*** DR-63953 Apply new Security Task and Licensing for Task Planner access - Task						***/

	If NOT exists (select * from TASK where TASKID = 286)
        	BEGIN
         	 PRINT '**** DR-63953 Adding data TASK.TASKID = 286'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (286, N'Task Planner Application',N'Allows users to launch the Task Planner application, and run searches for due dates and reminders')
        	 PRINT '**** DR-63953 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-63953 TASK.TASKID = 286 already exists'
         	PRINT ''
    	go

    	/*** DR-63953 Apply new Security Task and Licensing for Task Planner access - FeatureTask						***/

	IF NOT exists (select * from FEATURETASK where FEATUREID = 81 AND TASKID = 286)
		begin
		PRINT '**** DR-63953 Inserting FEATURETASK.FEATUREID = 81, TASKID = 286'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (81, 286)
		PRINT '**** DR-63953 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** DR-63953 FEATURETASK.FEATUREID = 81, TASKID = 286 already exists.'
		PRINT ''
 	go

	/*** DR-63953 Apply new Security Task and Licensing for Task Planner access - Permission Definition						***/

	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 286
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** DR-63953 Adding TASK definition data PERMISSIONS.OBJECTKEY = 286'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 286, NULL, NULL, NULL, 32, 0)
        	 PRINT '**** DR-63953 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** DR-63953 TASK definition data PERMISSIONS.OBJECTKEY = 286 already exists'
		 PRINT ''
         	END
    	go

    	/*** DR-63953 Apply new Security Task and Licensing for Task Planner access - Task Permissions						***/

	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 286
				and LEVELTABLE = 'ROLE'
				and LEVELKEY = -1)
        	BEGIN
         	 PRINT '**** DR-63953 Adding TASK data PERMISSIONS.OBJECTKEY = 286'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 286, NULL, 'ROLE', -1, 32, 0)
        	 PRINT '**** DR-63953 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** DR-63953 TASK data PERMISSIONS.OBJECTKEY = 286 already exists'
		 PRINT ''
         	END
    	go
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 286
				and LEVELTABLE = 'ROLE'
				and LEVELKEY = -21)
        	BEGIN
         	 PRINT '**** DR-63953 Adding TASK data PERMISSIONS.OBJECTKEY = 286'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 286, NULL, 'ROLE', -21, 32, 0)
        	 PRINT '**** DR-63953 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** DR-63953 TASK data PERMISSIONS.OBJECTKEY = 286 already exists'
		 PRINT ''
         	END
    	go

    	/*** DR-63953 - ValidObject								***/
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82 962')
        	BEGIN
         	 PRINT '**** DR-63953 Adding data VALIDOBJECT.OBJECTDATA = 82 962'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82 962')
        	 PRINT '**** DR-63953 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-63953 VALIDOBJECT.OBJECTDATA = 82 962 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82 162')
        	BEGIN
         	 PRINT '**** DR-63953 Adding data VALIDOBJECT.OBJECTDATA = 82 162'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82 162')
        	 PRINT '**** DR-63953 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-63953 VALIDOBJECT.OBJECTDATA = 82 162 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82  62')
        	BEGIN
         	 PRINT '**** DR-63953 Adding data VALIDOBJECT.OBJECTDATA = 82  62'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82  62')
        	 PRINT '**** DR-63953 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-63953 VALIDOBJECT.OBJECTDATA = 82  62 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82 861')
        	BEGIN
         	 PRINT '**** DR-63953 Adding data VALIDOBJECT.OBJECTDATA = 82 861'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82 861')
        	 PRINT '**** DR-63953 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-63953 VALIDOBJECT.OBJECTDATA = 82 861 already exists'
         	PRINT ''
    	go
