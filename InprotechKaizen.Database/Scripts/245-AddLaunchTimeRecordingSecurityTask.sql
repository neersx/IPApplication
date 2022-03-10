   	/**********************************************************************************************************/
   	/*** DR-54291 Restrict Access to Time Recording in Apps - Task						***/
	/**********************************************************************************************************/
	If NOT exists (select * from TASK where TASKID = 282)
        	BEGIN
         	 PRINT '**** DR-54291 Adding data TASK.TASKID = 282'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (282, N'Maintain Time in Time Recording', 'Access Time Recording to create, update or delete time entries')
        	 PRINT '**** DR-54291 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-54291 TASK.TASKID = 282 already exists'
         	PRINT ''
    	go

   	/**********************************************************************************************************/
   	/*** DR-54291 Restrict Access to Time Recording in Apps - FeatureTask						***/
	/**********************************************************************************************************/

	IF NOT exists (select * from FEATURETASK where FEATUREID = 26 AND TASKID = 282)
		begin
		PRINT '**** DR-54291 Inserting FEATURETASK.FEATUREID = 26, TASKID = 282'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (26, 282)
		PRINT '**** DR-54291 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** DR-54291 FEATURETASK.FEATUREID = 26, TASKID = 282 already exists.'
		PRINT ''
 	go

   	/**********************************************************************************************************/
   	/*** DR-54291 Restrict Access to Time Recording in Apps - Permission Definition						***/
	/**********************************************************************************************************/

	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 282
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** DR-54291 Adding TASK definition data PERMISSIONS.OBJECTKEY = 282'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 282, NULL, NULL, NULL, 32, 0)
        	 PRINT '**** DR-54291 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** DR-54291 TASK definition data PERMISSIONS.OBJECTKEY = 282 already exists'
		 PRINT ''
         	END
    	go

   	/**********************************************************************************************************/
   	/*** DR-54291 Restrict Access to Time Recording in Apps - ValidObject								***/
	/**********************************************************************************************************/

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82  26')
        	BEGIN
         	 PRINT '**** DR-54291 Adding data VALIDOBJECT.OBJECTDATA = 82  26'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82  26')
        	 PRINT '**** DR-54291 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-54291 VALIDOBJECT.OBJECTDATA = 82  26 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82 023')
        	BEGIN
         	 PRINT '**** DR-54291 Adding data VALIDOBJECT.OBJECTDATA = 82 023'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82 023')
        	 PRINT '**** DR-54291 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-54291 VALIDOBJECT.OBJECTDATA = 82 023 already exists'
         	PRINT ''
    	go
