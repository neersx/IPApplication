    	/**********************************************************************************************************/
    	/*** RFC26050 Security task for generating Application Link Security Token - Feature Category		***/
	/**********************************************************************************************************/
	If NOT exists (select * from TABLECODES WHERE TABLECODE=9823)
        	BEGIN
         	 PRINT '**** RFC26050 Adding data TABLECODES.TABLECODE = 9823'
		 INSERT INTO TABLECODES (TABLECODE, TABLETYPE, [DESCRIPTION], USERCODE)
		 VALUES (9823, 98, N'Application Links',null)
        	 PRINT '**** RFC26050 Data successfully added to TABLECODES table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC26050 TABLECODES.TABLECODE = 9823 already exists'
         	PRINT ''
    	go

    	/**********************************************************************************************************/
    	/*** RFC26050 Security task for generating Application Link Security Token - Feature				***/
	/**********************************************************************************************************/
	IF NOT exists (select * from FEATURE where FEATUREID = 74)
		begin
		PRINT '**** RFC26050 Inserting FEATURE.FEATUREID = 74'
		INSERT INTO FEATURE (FEATUREID, FEATURENAME, CATEGORYID, ISEXTERNAL, ISINTERNAL)
		VALUES (74, N'Application Link Security', 9823, 0, 1)
		PRINT '**** RFC26050 Data has been successfully added to FEATURE table.'
		PRINT ''
		END
	ELSE
		PRINT '**** RFC26050 FEATURE.FEATUREID = 74 already exists.'
		PRINT ''
 	go

    	/**********************************************************************************************************/
    	/*** RFC26050 Security task for generating Application Link Security Token - Task				***/
	/**********************************************************************************************************/
	If NOT exists (select * from TASK where TASKID = 225)
        	BEGIN
         	 PRINT '**** RFC26050 Adding data TASK.TASKID = 225'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (225, N'Maintain Application Link Security',N'Allow users to generate security tokens for application links')
        	 PRINT '**** RFC26050 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC26050 TASK.TASKID = 225 already exists'
         	PRINT ''
    	go

    	/**********************************************************************************************************/
    	/*** RFC26050 Security task for generating Application Link Security Token - FeatureTask			***/
	/**********************************************************************************************************/
	IF NOT exists (select * from FEATURETASK where FEATUREID = 74 AND TASKID = 225)
		begin
		PRINT '**** RFC26050 Inserting FEATURETASK.FEATUREID = 74, TASKID = 225'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (74, 225)
		PRINT '**** RFC26050 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** RFC26050 FEATURETASK.FEATUREID = 74, TASKID = 225 already exists.'
		PRINT ''
 	go

   	/**********************************************************************************************************/
    	/*** RFC26050 Security task for generating Application Link Security Token - Permission Definition		***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 225
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** RFC26050 Adding TASK definition data PERMISSIONS.OBJECTKEY = 225'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 225, NULL, NULL, NULL, 32, 0)
        	 PRINT '**** RFC26050 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** RFC26050 TASK definition data PERMISSIONS.OBJECTKEY = 225 already exists'
		 PRINT ''
         	END
    	go

    	/**********************************************************************************************************/
    	/*** RFC26050 Security task for generating Application Link Security Token - Task Permissions		***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 225
				and LEVELTABLE = 'ROLE'
				and LEVELKEY = -1)
        	BEGIN
         	 PRINT '**** RFC26050 Adding TASK data PERMISSIONS.OBJECTKEY = 225'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 225, NULL, 'ROLE', -1, 0, 0)
        	 PRINT '**** RFC26050 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** RFC26050 TASK data PERMISSIONS.OBJECTKEY = 225 already exists'
		 PRINT ''
         	END
    	go

	/**********************************************************************************************************/
    	/*** RFC26050 - ValidObject										***/
	/**********************************************************************************************************/
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '22 552')
        	BEGIN
         	 PRINT '**** RFC26050 Adding data VALIDOBJECT.OBJECTID = 2063'
			    declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
				VALUES (@validObject, 20, '22 552')
        	 PRINT '**** RFC26050 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC26050 VALIDOBJECT.OBJECTID = 2063 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '22 752')
        	BEGIN
         	 PRINT '**** RFC26050 Adding data VALIDOBJECT.OBJECTID = 2064'
		     	 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
				VALUES (@validObject, 20, '22 752')
        	 PRINT '**** RFC26050 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC26050 VALIDOBJECT.OBJECTID = 2064 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '22 952')
        	BEGIN
         	 PRINT '**** RFC26050 Adding data VALIDOBJECT.OBJECTID = 2065'
		     	 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
				VALUES (@validObject, 20, '22 952')
        	 PRINT '**** RFC26050 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC26050 VALIDOBJECT.OBJECTID = 2065 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '22 253')
        	BEGIN
         	 PRINT '**** RFC26050 Adding data VALIDOBJECT.OBJECTID = 2066'
		     	 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
				INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
				VALUES (@validObject, 20, '22 253')
        	 PRINT '**** RFC26050 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC26050 VALIDOBJECT.OBJECTID = 2066 already exists'
         	PRINT ''
    	go