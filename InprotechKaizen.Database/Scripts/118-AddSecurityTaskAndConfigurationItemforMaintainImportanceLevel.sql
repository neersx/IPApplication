   

    /**********************************************************************************************************/
    /*** RFC51939 Add Importance Level security task - Task													***/
	/**********************************************************************************************************/
	If NOT exists (select * from TASK where TASKID = 262)
        	BEGIN
         	 PRINT '**** RFC51939 Adding data TASK.TASKID = 262'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (262, N'Maintain Importance Level',N'Create, update or delete Importance Level.')
        	 PRINT '**** RFC51939 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC51939 TASK.TASKID = 262 already exists'
         	PRINT ''
    	go



    /**********************************************************************************************************/
    /*** RFC51939 Add Importance Level security task - FeatureTask											***/
	/**********************************************************************************************************/
	IF NOT exists (select * from FEATURETASK where FEATUREID = 51 AND TASKID = 262)
		begin
		PRINT '**** RFC51939 Inserting FEATURETASK.FEATUREID = 51, TASKID = 262'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (51, 262)
		PRINT '**** RFC51939 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** RFC51939 FEATURETASK.FEATUREID = 51, TASKID = 262 already exists.'
		PRINT ''
 	go



    /**********************************************************************************************************/
    /*** RFC51939 Add Importance Level security task - Permission Definition								***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 262
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** RFC51939 Adding TASK definition data PERMISSIONS.OBJECTKEY = 262'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 262, NULL, NULL, NULL, 32, 0)
        	 PRINT '**** RFC51939 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** RFC51939 TASK definition data PERMISSIONS.OBJECTKEY = 262 already exists'
		 PRINT ''
         	END
    	go



    /**********************************************************************************************************/
    /*** RFC51939 - ValidObject																				***/
	/**********************************************************************************************************/
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62  22')
        	BEGIN
         	 PRINT '**** RFC51939 Adding data VALIDOBJECT.OBJECTDATA = 62  22'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62  22')
        	 PRINT '**** RFC51939 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC51939 VALIDOBJECT.OBJECTDATA = 62  22 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 821')
        	BEGIN
         	 PRINT '**** RFC51939 Adding data VALIDOBJECT.OBJECTDATA = 62 821'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 821')
        	 PRINT '**** RFC51939 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC51939 VALIDOBJECT.OBJECTDATA = 62 821 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 022')
        	BEGIN
         	 PRINT '**** RFC51939 Adding data VALIDOBJECT.OBJECTDATA = 62 022'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 022')
        	 PRINT '**** RFC51939 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC51939 VALIDOBJECT.OBJECTDATA = 62 022 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 122')
        	BEGIN
         	 PRINT '**** RFC51939 Adding data VALIDOBJECT.OBJECTDATA = 62 122'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 122')
        	 PRINT '**** RFC51939 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC51939 VALIDOBJECT.OBJECTDATA = 62 122 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 522')
        	BEGIN
         	 PRINT '**** RFC51939 Adding data VALIDOBJECT.OBJECTDATA = 62 522'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 522')
        	 PRINT '**** RFC51939 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC51939 VALIDOBJECT.OBJECTDATA = 62 522 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 922')
        	BEGIN
         	 PRINT '**** RFC51939 Adding data VALIDOBJECT.OBJECTDATA = 62 922'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 922')
        	 PRINT '**** RFC51939 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC51939 VALIDOBJECT.OBJECTDATA = 62 922 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 223')
        	BEGIN
         	 PRINT '**** RFC51939 Adding data VALIDOBJECT.OBJECTDATA = 62 223'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 223')
        	 PRINT '**** RFC51939 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC51939 VALIDOBJECT.OBJECTDATA = 62 223 already exists'
         	PRINT ''
    	go


		
	/**********************************************************************************************************/
	/*** RFC51939 Maintain Importance Level - ConfigurationItem						                        ***/
	/**********************************************************************************************************/

	If not exists (SELECT * FROM CONFIGURATIONITEM WHERE TASKID=262)
	Begin
		PRINT '**** RFC51939 Inserting CONFIGURATIONITEM WHERE TASKID=262 and TITLE = "Maintain Importance Level"'
		INSERT INTO CONFIGURATIONITEM(TASKID, TITLE, DESCRIPTION, URL) 
		VALUES(262,'Maintain Importance Level','Create, update or delete Importance Level.','/apps/#/configuration/general/importancelevel')		
		PRINT '**** RFC51939 Data successfully inserted in CONFIGURATIONITEM table.'
		PRINT ''			
	End
	Else
	Begin
		PRINT '**** RFC51939 CONFIGURATIONITEM WHERE TASKID=262 already exists'
		PRINT ''
	End

