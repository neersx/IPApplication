    	/**********************************************************************************************************/
    	/*** RFC45031 Add Maintain Number Types task security - Task						***/
	/**********************************************************************************************************/
	If NOT exists (select * from TASK where TASKID = 241)
        	BEGIN
         	 PRINT '**** RFC45031 Adding data TASK.TASKID = 241'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (241, N'Maintain Number Types',N'Create, update or delete Number Types.')
        	 PRINT '**** RFC45031 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC45031 TASK.TASKID = 241 already exists'
         	PRINT ''
    	go

    	/**********************************************************************************************************/
    	/*** RFC45031 Add Maintain Number Types task security - FeatureTask					***/
	/**********************************************************************************************************/
	IF NOT exists (select * from FEATURETASK where FEATUREID = 51 AND TASKID = 241)
		begin
		PRINT '**** RFC45031 Inserting FEATURETASK.FEATUREID = 51, TASKID = 241'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (51, 241)
		PRINT '**** RFC45031 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** RFC45031 FEATURETASK.FEATUREID = 51, TASKID = 241 already exists.'
		PRINT ''
 	go

    	/**********************************************************************************************************/
    	/*** RFC45031 Add Maintain Number Types task security - Permission Definition				***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 241
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** RFC45031 Adding TASK definition data PERMISSIONS.OBJECTKEY = 241'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 241, NULL, NULL, NULL, 26, 0)
        	 PRINT '**** RFC45031 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** RFC45031 TASK definition data PERMISSIONS.OBJECTKEY = 241 already exists'
		 PRINT ''
         	END
    	go

    	/**********************************************************************************************************/
    	/*** RFC45031 Add Maintain Number Types task security - Task Permissions				***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 241
				and LEVELTABLE = 'ROLE'
				and LEVELKEY = -1)
        	BEGIN
         	 PRINT '**** RFC45031 Adding TASK data PERMISSIONS.OBJECTKEY = 241'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 241, NULL, 'ROLE', -1, 26, 0)
        	 PRINT '**** RFC45031 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** RFC45031 TASK data PERMISSIONS.OBJECTKEY = 241 already exists'
		 PRINT ''
         	END
    	go

    	/**********************************************************************************************************/
    	/*** RFC45031 - ValidObject								                ***/
	/**********************************************************************************************************/
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '42  12')
        	BEGIN
         	 PRINT '**** RFC45031 Adding data VALIDOBJECT.OBJECTDATA = 42  12'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '42  12')
        	 PRINT '**** RFC45031 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC45031 VALIDOBJECT.OBJECTDATA = 42  12 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '42 811')
        	BEGIN
         	 PRINT '**** RFC45031 Adding data VALIDOBJECT.OBJECTDATA = 42 811'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '42 811')
        	 PRINT '**** RFC45031 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC45031 VALIDOBJECT.OBJECTDATA = 42 811 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '42 012')
        	BEGIN
         	 PRINT '**** RFC45031 Adding data VALIDOBJECT.OBJECTDATA = 42 012'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '42 012')
        	 PRINT '**** RFC45031 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC45031 VALIDOBJECT.OBJECTDATA = 42 012 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '42 112')
        	BEGIN
         	 PRINT '**** RFC45031 Adding data VALIDOBJECT.OBJECTDATA = 42 112'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '42 112')
        	 PRINT '**** RFC45031 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC45031 VALIDOBJECT.OBJECTDATA = 42 112 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '42 512')
        	BEGIN
         	 PRINT '**** RFC45031 Adding data VALIDOBJECT.OBJECTDATA = 42 512'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '42 512')
        	 PRINT '**** RFC45031 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC45031 VALIDOBJECT.OBJECTDATA = 42 512 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '42 912')
        	BEGIN
         	 PRINT '**** RFC45031 Adding data VALIDOBJECT.OBJECTDATA = 42 912'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '42 912')
        	 PRINT '**** RFC45031 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC45031 VALIDOBJECT.OBJECTDATA = 42 912 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '42 213')
        	BEGIN
         	 PRINT '**** RFC45031 Adding data VALIDOBJECT.OBJECTDATA = 42 213'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '42 213')
        	 PRINT '**** RFC45031 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC45031 VALIDOBJECT.OBJECTDATA = 42 213 already exists'
         	PRINT ''
    	go

