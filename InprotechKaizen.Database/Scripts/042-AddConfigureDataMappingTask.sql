   	/**********************************************************************************************************/
   	/*** RFC45627 Introduce of data mapping configuration functionality - Task						***/
	/**********************************************************************************************************/
	If NOT exists (select * from TASK where TASKID = 239)
        	BEGIN
         	 PRINT '**** RFC45627 Adding data TASK.TASKID = 239'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (239, N'Configure Data Mapping',N'Map descriptions and codes from external data sources to values in your system.')
        	 PRINT '**** RFC45627 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC45627 TASK.TASKID = 239 already exists'
         	PRINT ''
    	go

   	/**********************************************************************************************************/
   	/*** RFC45627 Introduce of data mapping configuration functionality - FeatureTask						***/
	/**********************************************************************************************************/
	IF NOT exists (select * from FEATURETASK where FEATUREID = 51 AND TASKID = 239)
		begin
		PRINT '**** RFC45627 Inserting FEATURETASK.FEATUREID = 51, TASKID = 239'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (51, 239)
		PRINT '**** RFC45627 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** RFC45627 FEATURETASK.FEATUREID = 51, TASKID = 239 already exists.'
		PRINT ''
 	go

   	/**********************************************************************************************************/
   	/*** RFC45627 Introduce of data mapping configuration functionality - Permission Definition						***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 239
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** RFC45627 Adding TASK definition data PERMISSIONS.OBJECTKEY = 239'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 239, NULL, NULL, NULL, 32, 0)
        	 PRINT '**** RFC45627 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** RFC45627 TASK definition data PERMISSIONS.OBJECTKEY = 239 already exists'
		 PRINT ''
         	END
    	go

   	/**********************************************************************************************************/
   	/*** RFC45627 - ValidObject								***/
	/**********************************************************************************************************/
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '32  92')
        	BEGIN
         	 PRINT '**** RFC45627 Adding data VALIDOBJECT.OBJECTDATA = 32  92'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '32  92')
        	 PRINT '**** RFC45627 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC45627 VALIDOBJECT.OBJECTDATA = 32  92 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '32 891')
        	BEGIN
         	 PRINT '**** RFC45627 Adding data VALIDOBJECT.OBJECTDATA = 32 891'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '32 891')
        	 PRINT '**** RFC45627 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC45627 VALIDOBJECT.OBJECTDATA = 32 891 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '32 192')
        	BEGIN
         	 PRINT '**** RFC45627 Adding data VALIDOBJECT.OBJECTDATA = 32 192'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '32 192')
        	 PRINT '**** RFC45627 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC45627 VALIDOBJECT.OBJECTDATA = 32 192 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '32 792')
        	BEGIN
         	 PRINT '**** RFC45627 Adding data VALIDOBJECT.OBJECTDATA = 32 792'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '32 792')
        	 PRINT '**** RFC45627 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC45627 VALIDOBJECT.OBJECTDATA = 32 792 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '32 892')
        	BEGIN
         	 PRINT '**** RFC45627 Adding data VALIDOBJECT.OBJECTDATA = 32 892'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '32 892')
        	 PRINT '**** RFC45627 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC45627 VALIDOBJECT.OBJECTDATA = 32 892 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '32 992')
        	BEGIN
         	 PRINT '**** RFC45627 Adding data VALIDOBJECT.OBJECTDATA = 32 992'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '32 992')
        	 PRINT '**** RFC45627 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC45627 VALIDOBJECT.OBJECTDATA = 32 992 already exists'
         	PRINT ''
    	go

