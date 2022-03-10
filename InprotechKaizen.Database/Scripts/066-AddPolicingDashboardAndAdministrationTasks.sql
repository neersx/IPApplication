   	/**********************************************************************************************************/
   	/*** RFC10495 Policing Dashboard - Feature Category						***/
	/**********************************************************************************************************/
	If NOT exists (select * from TABLECODES WHERE TABLECODE=9824)
        	BEGIN
         	 PRINT '**** RFC10495 Adding data TABLECODES.TABLECODE = 9824'
		 INSERT INTO TABLECODES (TABLECODE, TABLETYPE, [DESCRIPTION], USERCODE)
		 VALUES (9824, 98, N'Processing',null)
        	 PRINT '**** RFC10495 Data successfully added to TABLECODES table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC10495 TABLECODES.TABLECODE = 9824 already exists'
         	PRINT ''
    	go

   	/**********************************************************************************************************/
   	/*** RFC10495 Policing Dashboard - Feature						***/
	/**********************************************************************************************************/
	IF NOT exists (select * from FEATURE where FEATUREID = 76)
		begin
		PRINT '**** RFC10495 Inserting FEATURE.FEATUREID = 76'
		INSERT INTO FEATURE (FEATUREID, FEATURENAME, CATEGORYID, ISEXTERNAL, ISINTERNAL)
		VALUES (76, N'Policing', 9824, 0, 1)
		PRINT '**** RFC10495 Data has been successfully added to FEATURE table.'
		PRINT ''
		END
	ELSE
		PRINT '**** RFC10495 FEATURE.FEATUREID = 76 already exists.'
		PRINT ''
 	go

   	/**********************************************************************************************************/
   	/*** RFC10495 Policing Dashboard - Task						***/
	/**********************************************************************************************************/
	If NOT exists (select * from TASK where TASKID = 255)
        	BEGIN
         	 PRINT '**** RFC10495 Adding data TASK.TASKID = 255'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (255, N'Policing Administration',N'Ability to remove queued policing items, put items on hold, and ability to turn policing on and off.')
        	 PRINT '**** RFC10495 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC10495 TASK.TASKID = 255 already exists'
         	PRINT ''
    	go

	If NOT exists (select * from TASK where TASKID = 256)
        	BEGIN
         	 PRINT '**** RFC10495 Adding data TASK.TASKID = 256'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (256, N'View Policing Dashboard',N'Ability to view the policing dashboard and drill down to see items on the queue.')
        	 PRINT '**** RFC10495 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC10495 TASK.TASKID = 256 already exists'
         	PRINT ''
    	go

   	/**********************************************************************************************************/
   	/*** RFC10495 Policing Dashboard - FeatureTask						***/
	/**********************************************************************************************************/
	IF NOT exists (select * from FEATURETASK where FEATUREID = 76 AND TASKID = 255)
		begin
		PRINT '**** RFC10495 Inserting FEATURETASK.FEATUREID = 76, TASKID = 255'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (76, 255)
		PRINT '**** RFC10495 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** RFC10495 FEATURETASK.FEATUREID = 76, TASKID = 255 already exists.'
		PRINT ''
 	go

	IF NOT exists (select * from FEATURETASK where FEATUREID = 76 AND TASKID = 256)
		begin
		PRINT '**** RFC10495 Inserting FEATURETASK.FEATUREID = 76, TASKID = 256'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (76, 256)
		PRINT '**** RFC10495 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** RFC10495 FEATURETASK.FEATUREID = 76, TASKID = 256 already exists.'
		PRINT ''
 	go

	/**********************************************************************************************************/
    /*** RFC10495 Policing Dashboard - Permission Definition						***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 255
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** RFC10495 Adding TASK definition data PERMISSIONS.OBJECTKEY = 255'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 255, NULL, NULL, NULL, 32, 0)
        	 PRINT '**** RFC10495 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** RFC10495 TASK definition data PERMISSIONS.OBJECTKEY = 255 already exists'
		 PRINT ''
         	END
    	go

	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 256
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** RFC10495 Adding TASK definition data PERMISSIONS.OBJECTKEY = 256'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 256, NULL, NULL, NULL, 32, 0)
        	 PRINT '**** RFC10495 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** RFC10495 TASK definition data PERMISSIONS.OBJECTKEY = 256 already exists'
		 PRINT ''
         	END
    	go

   	/**********************************************************************************************************/
   	/*** RFC10495 - ValidObject								***/
	/**********************************************************************************************************/
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52  52')
        	BEGIN
         	 PRINT '**** RFC10495 Adding data VALIDOBJECT.OBJECTDATA = 52  52'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52  52')
        	 PRINT '**** RFC10495 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC10495 VALIDOBJECT.OBJECTDATA = 52  52 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 851')
        	BEGIN
         	 PRINT '**** RFC10495 Adding data VALIDOBJECT.OBJECTDATA = 52 851'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 851')
        	 PRINT '**** RFC10495 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC10495 VALIDOBJECT.OBJECTDATA = 52 851 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 152')
        	BEGIN
         	 PRINT '**** RFC10495 Adding data VALIDOBJECT.OBJECTDATA = 52 152'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 152')
        	 PRINT '**** RFC10495 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC10495 VALIDOBJECT.OBJECTDATA = 52 152 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 752')
        	BEGIN
         	 PRINT '**** RFC10495 Adding data VALIDOBJECT.OBJECTDATA = 52 752'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 752')
        	 PRINT '**** RFC10495 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC10495 VALIDOBJECT.OBJECTDATA = 52 752 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 852')
        	BEGIN
         	 PRINT '**** RFC10495 Adding data VALIDOBJECT.OBJECTDATA = 52 852'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 852')
        	 PRINT '**** RFC10495 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC10495 VALIDOBJECT.OBJECTDATA = 52 852 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 952')
        	BEGIN
         	 PRINT '**** RFC10495 Adding data VALIDOBJECT.OBJECTDATA = 52 952'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 952')
        	 PRINT '**** RFC10495 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC10495 VALIDOBJECT.OBJECTDATA = 52 952 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52  62')
        	BEGIN
         	 PRINT '**** RFC10495 Adding data VALIDOBJECT.OBJECTDATA = 52  62'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52  62')
        	 PRINT '**** RFC10495 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC10495 VALIDOBJECT.OBJECTDATA = 52  62 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 861')
        	BEGIN
         	 PRINT '**** RFC10495 Adding data VALIDOBJECT.OBJECTDATA = 52 861'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 861')
        	 PRINT '**** RFC10495 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC10495 VALIDOBJECT.OBJECTDATA = 52 861 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 162')
        	BEGIN
         	 PRINT '**** RFC10495 Adding data VALIDOBJECT.OBJECTDATA = 52 162'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 162')
        	 PRINT '**** RFC10495 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC10495 VALIDOBJECT.OBJECTDATA = 52 162 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 762')
        	BEGIN
         	 PRINT '**** RFC10495 Adding data VALIDOBJECT.OBJECTDATA = 52 762'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 762')
        	 PRINT '**** RFC10495 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC10495 VALIDOBJECT.OBJECTDATA = 52 762 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 862')
        	BEGIN
         	 PRINT '**** RFC10495 Adding data VALIDOBJECT.OBJECTDATA = 52 862'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 862')
        	 PRINT '**** RFC10495 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC10495 VALIDOBJECT.OBJECTDATA = 52 862 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 962')
        	BEGIN
         	 PRINT '**** RFC10495 Adding data VALIDOBJECT.OBJECTDATA = 52 962'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 962')
        	 PRINT '**** RFC10495 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC10495 VALIDOBJECT.OBJECTDATA = 52 962 already exists'
         	PRINT ''
    	go

