
   	/**********************************************************************************************************/
   	/*** RFC52340 Allow Policing Requests to be viewed, maintained and scheduled. - Task						***/
	/**********************************************************************************************************/
	If NOT exists (select * from TASK where TASKID = 259)
        	BEGIN
         	 PRINT '**** RFC52340 Adding data TASK.TASKID = 259'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (259, N'Maintain Policing Request',N'Ability to view and maintain policing requests, scheduling them to be run later or on demand.')
        	 PRINT '**** RFC52340 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC52340 TASK.TASKID = 259 already exists'
         	PRINT ''
    	go

   	/**********************************************************************************************************/
   	/*** RFC52340 Allow Policing Requests to be viewed, maintained and scheduled. - FeatureTask						***/
	/**********************************************************************************************************/
	IF NOT exists (select * from FEATURETASK where FEATUREID = 76 AND TASKID = 259)
		begin
		PRINT '**** RFC52340 Inserting FEATURETASK.FEATUREID = 76, TASKID = 259'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (76, 259)
		PRINT '**** RFC52340 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** RFC52340 FEATURETASK.FEATUREID = 76, TASKID = 259 already exists.'
		PRINT ''
 	go

   	/**********************************************************************************************************/
   	/*** RFC52340 Allow Policing Requests to be viewed, maintained and scheduled. - Permission Definition						***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 259
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** RFC52340 Adding TASK definition data PERMISSIONS.OBJECTKEY = 259'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 259, NULL, NULL, NULL, 32, 0)
        	 PRINT '**** RFC52340 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** RFC52340 TASK definition data PERMISSIONS.OBJECTKEY = 259 already exists'
		 PRINT ''
         	END
    	go

   	/**********************************************************************************************************/
   	/*** RFC52340 - ValidObject								***/
	/**********************************************************************************************************/
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52  92')
        	BEGIN
         	 PRINT '**** RFC52340 Adding data VALIDOBJECT.OBJECTDATA = 52  92'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52  92')
        	 PRINT '**** RFC52340 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC52340 VALIDOBJECT.OBJECTDATA = 52  92 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 891')
        	BEGIN
         	 PRINT '**** RFC52340 Adding data VALIDOBJECT.OBJECTDATA = 52 891'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 891')
        	 PRINT '**** RFC52340 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC52340 VALIDOBJECT.OBJECTDATA = 52 891 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 192')
        	BEGIN
         	 PRINT '**** RFC52340 Adding data VALIDOBJECT.OBJECTDATA = 52 192'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 192')
        	 PRINT '**** RFC52340 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC52340 VALIDOBJECT.OBJECTDATA = 52 192 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 792')
        	BEGIN
         	 PRINT '**** RFC52340 Adding data VALIDOBJECT.OBJECTDATA = 52 792'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 792')
        	 PRINT '**** RFC52340 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC52340 VALIDOBJECT.OBJECTDATA = 52 792 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 892')
        	BEGIN
         	 PRINT '**** RFC52340 Adding data VALIDOBJECT.OBJECTDATA = 52 892'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 892')
        	 PRINT '**** RFC52340 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC52340 VALIDOBJECT.OBJECTDATA = 52 892 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 992')
        	BEGIN
         	 PRINT '**** RFC52340 Adding data VALIDOBJECT.OBJECTDATA = 52 992'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 992')
        	 PRINT '**** RFC52340 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC52340 VALIDOBJECT.OBJECTDATA = 52 992 already exists'
         	PRINT ''
    	go

