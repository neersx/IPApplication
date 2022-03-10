    	/*** RFC51940 Security task for Maintain Event Category - Task (DR-14806)			***/

	If NOT exists (select * from TASK where TASKID = 267)
        	BEGIN
         	 PRINT '**** RFC51940 Adding data TASK.TASKID = 267'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (267, N'Maintain Event Category',N'Ability to maintain Event Category')
        	 PRINT '**** RFC51940 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC51940 TASK.TASKID = 267 already exists'
         	PRINT ''
    	go


    	/*** RFC51940 Security task for Maintain Event Category - FeatureTask (DR-14806)		***/

	IF NOT exists (select * from FEATURETASK where FEATUREID = 51 AND TASKID = 267)
		begin
		PRINT '**** RFC51940 Inserting FEATURETASK.FEATUREID = 51, TASKID = 267'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (51, 267)
		PRINT '**** RFC51940 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** RFC51940 FEATURETASK.FEATUREID = 51, TASKID = 267 already exists.'
		PRINT ''
 	go


    	/*** RFC51940 Security task for Maintain Event Category - Permission Definition (DR-14806)	***/

	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 267
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** RFC51940 Adding TASK definition data PERMISSIONS.OBJECTKEY = 267'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 267, NULL, NULL, NULL, 32, 0)
        	 PRINT '**** RFC51940 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** RFC51940 TASK definition data PERMISSIONS.OBJECTKEY = 267 already exists'
		 PRINT ''
         	END
    	go


    	/*** RFC51940 - ValidObject (DR-14806)								***/

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 871')
        	BEGIN
         	 PRINT '**** RFC51940 Adding data VALIDOBJECT.OBJECTDATA = 62 871'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 871')
        	 PRINT '**** RFC51940 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC51940 VALIDOBJECT.OBJECTDATA = 62 871 already exists'
         	PRINT ''
    	go


	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 072')
        	BEGIN
         	 PRINT '**** RFC51940 Adding data VALIDOBJECT.OBJECTDATA = 62 072'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 072')
        	 PRINT '**** RFC51940 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC51940 VALIDOBJECT.OBJECTDATA = 62 072 already exists'
         	PRINT ''
    	go
    	
    	
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 172')
        	BEGIN
         	 PRINT '**** RFC51940 Adding data VALIDOBJECT.OBJECTDATA = 62 172'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 172')
        	 PRINT '**** RFC51940 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC51940 VALIDOBJECT.OBJECTDATA = 62 172 already exists'
         	PRINT ''
    	go
    	
    	
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 572')
        	BEGIN
         	 PRINT '**** RFC51940 Adding data VALIDOBJECT.OBJECTDATA = 62 572'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 572')
        	 PRINT '**** RFC51940 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC51940 VALIDOBJECT.OBJECTDATA = 62 572 already exists'
         	PRINT ''
    	go
    	
    	
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 972')
        	BEGIN
         	 PRINT '**** RFC51940 Adding data VALIDOBJECT.OBJECTDATA = 62 972'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 972')
        	 PRINT '**** RFC51940 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC51940 VALIDOBJECT.OBJECTDATA = 62 972 already exists'
         	PRINT ''
    	go
    	
    	
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 273')
        	BEGIN
         	 PRINT '**** RFC51940 Adding data VALIDOBJECT.OBJECTDATA = 62 273'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 273')
        	 PRINT '**** RFC51940 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC51940 VALIDOBJECT.OBJECTDATA = 62 273 already exists'
         	PRINT ''
    	go
