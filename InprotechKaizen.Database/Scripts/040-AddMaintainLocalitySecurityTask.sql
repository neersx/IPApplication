    	/**********************************************************************************************************/
    	/*** RFC44844 Add Maintain Locality task security - Task						***/
	/**********************************************************************************************************/
	If NOT exists (select * from TASK where TASKID = 234)
        BEGIN
         	 PRINT '**** RFC44844 Adding data TASK.TASKID = 234'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (234, N'Maintain Locality',N'Create, update or delete Locality.')
        	 PRINT '**** RFC44844 Data successfully added to TASK table.'
		 PRINT ''
        END
    	ELSE
         	PRINT '**** RFC44844 TASK.TASKID = 234 already exists'
         	PRINT ''
    	go

    	/**********************************************************************************************************/
    	/*** RFC44844 Add Maintain Locality task security - FeatureTask						***/
	/**********************************************************************************************************/
	IF NOT exists (select * from FEATURETASK where FEATUREID = 51 AND TASKID = 234)
	begin
		PRINT '**** RFC44844 Inserting FEATURETASK.FEATUREID = 51, TASKID = 234'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (51, 234)
		PRINT '**** RFC44844 Data has been successfully added to FEATURETASK table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC44844 FEATURETASK.FEATUREID = 51, TASKID = 234 already exists.'
		PRINT ''
 	go

   	/**********************************************************************************************************/
    	/*** RFC44844 Add Maintain Locality task security - Permission Definition						***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 234
				and LEVELTABLE is null
				and LEVELKEY is null)
        BEGIN
         	 PRINT '**** RFC44844 Adding TASK definition data PERMISSIONS.OBJECTKEY = 234'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 234, NULL, NULL, NULL, 26, 0)
        	 PRINT '**** RFC44844 Data successfully added to PERMISSIONS table.'
		 PRINT ''
        END
    	ELSE
        BEGIN
         	 PRINT '**** RFC44844 TASK definition data PERMISSIONS.OBJECTKEY = 234 already exists'
		 PRINT ''
        END
    	go

   	/**********************************************************************************************************/
    	/*** RFC44844 Add Maintain Locality task security - Task Permissions						***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 234
				and LEVELTABLE = 'ROLE'
				and LEVELKEY = -1)
        BEGIN
         	 PRINT '**** RFC44844 Adding TASK data PERMISSIONS.OBJECTKEY = 234'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 234, NULL, 'ROLE', -1, 26, 0)
        	 PRINT '**** RFC44844 Data successfully added to PERMISSIONS table.'
		 PRINT ''
        END
    	ELSE
        BEGIN
         	 PRINT '**** RFC44844 TASK data PERMISSIONS.OBJECTKEY = 234 already exists'
		 PRINT ''
        END
    	go

    	/**********************************************************************************************************/
    	/*** RFC44844 - ValidObject								***/
	/**********************************************************************************************************/
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '32  42')
        BEGIN
         	 PRINT '**** RFC44844 Adding data VALIDOBJECT.OBJECTDATA = 32  42'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                 INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '32  42')
        	 PRINT '**** RFC44844 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
        END
    	ELSE
         	PRINT '**** RFC44844 VALIDOBJECT.OBJECTDATA = 32  42 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '32 142')
        BEGIN
         	 PRINT '**** RFC44844 Adding data VALIDOBJECT.OBJECTDATA = 32 142'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                 INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '32 142')
        	 PRINT '**** RFC44844 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
        END
    	ELSE
         	PRINT '**** RFC44844 VALIDOBJECT.OBJECTDATA = 32 142 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '32 542')
        BEGIN
         	 PRINT '**** RFC44844 Adding data VALIDOBJECT.OBJECTDATA = 32 542'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                 INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '32 542')
        	 PRINT '**** RFC44844 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
        END
    	ELSE
         	PRINT '**** RFC44844 VALIDOBJECT.OBJECTDATA = 32 542 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '32 942')
        BEGIN
         	 PRINT '**** RFC44844 Adding data VALIDOBJECT.OBJECTDATA = 32 942'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                 INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '32 942')
        	 PRINT '**** RFC44844 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
        END
    	ELSE
         	PRINT '**** RFC44844 VALIDOBJECT.OBJECTDATA = 32 942 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '32 243')
        BEGIN
         	 PRINT '**** RFC44844 Adding data VALIDOBJECT.OBJECTDATA = 32 243'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                 INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '32 243')
        	 PRINT '**** RFC44844 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
        END
    	ELSE
         	PRINT '**** RFC44844 VALIDOBJECT.OBJECTDATA = 32 243 already exists'
         	PRINT ''
    	go

