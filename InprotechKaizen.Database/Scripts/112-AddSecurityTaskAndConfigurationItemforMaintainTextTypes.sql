   	/**********************************************************************************************************/
    	/*** RFC64868 Add Task Security for Maintain Text Type - Task						***/
	/**********************************************************************************************************/

	If NOT exists (select * from TASK where TASKID = 260)
        	BEGIN
         	 PRINT '**** RFC64868 Adding data TASK.TASKID = 260'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (260, N'Maintain Text Types',N'Create, update or delete Text Types.')
        	 PRINT '**** RFC64868 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC64868 TASK.TASKID = 260 already exists'
         	PRINT ''
    	go

   	/**********************************************************************************************************/
    	/*** RFC64868 Add Task Security for Maintain Text Type - FeatureTask						***/
	/**********************************************************************************************************/

	IF NOT exists (select * from FEATURETASK where FEATUREID = 51 AND TASKID = 260)
		begin
		PRINT '**** RFC64868 Inserting FEATURETASK.FEATUREID = 51, TASKID = 260'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (51, 260)
		PRINT '**** RFC64868 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** RFC64868 FEATURETASK.FEATUREID = 51, TASKID = 260 already exists.'
		PRINT ''
 	go

    /**********************************************************************************************************/
    	/*** RFC64868 Add Task Security for Maintain Text Type - Permission Definition						***/
	/**********************************************************************************************************/

	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 260
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** RFC64868 Adding TASK definition data PERMISSIONS.OBJECTKEY = 260'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 260, NULL, NULL, NULL, 32, 0)
        	 PRINT '**** RFC64868 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** RFC64868 TASK definition data PERMISSIONS.OBJECTKEY = 260 already exists'
		 PRINT ''
         	END
    	go

    
	/**********************************************************************************************************/
    	/*** RFC64868 - ValidObject								***/
	/**********************************************************************************************************/

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62  02')
        	BEGIN
         	 PRINT '**** RFC64868 Adding data VALIDOBJECT.OBJECTDATA = 62  02'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62  02')
        	 PRINT '**** RFC64868 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC64868 VALIDOBJECT.OBJECTDATA = 62  02 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 801')
        	BEGIN
         	 PRINT '**** RFC64868 Adding data VALIDOBJECT.OBJECTDATA = 62 801'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 801')
        	 PRINT '**** RFC64868 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC64868 VALIDOBJECT.OBJECTDATA = 62 801 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 002')
        	BEGIN
         	 PRINT '**** RFC64868 Adding data VALIDOBJECT.OBJECTDATA = 62 002'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 002')
        	 PRINT '**** RFC64868 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC64868 VALIDOBJECT.OBJECTDATA = 62 002 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 102')
        	BEGIN
         	 PRINT '**** RFC64868 Adding data VALIDOBJECT.OBJECTDATA = 62 102'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 102')
        	 PRINT '**** RFC64868 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC64868 VALIDOBJECT.OBJECTDATA = 62 102 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 502')
        	BEGIN
         	 PRINT '**** RFC64868 Adding data VALIDOBJECT.OBJECTDATA = 62 502'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 502')
        	 PRINT '**** RFC64868 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC64868 VALIDOBJECT.OBJECTDATA = 62 502 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 902')
        	BEGIN
         	 PRINT '**** RFC64868 Adding data VALIDOBJECT.OBJECTDATA = 62 902'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 902')
        	 PRINT '**** RFC64868 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC64868 VALIDOBJECT.OBJECTDATA = 62 902 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 203')
        	BEGIN
         	 PRINT '**** RFC64868 Adding data VALIDOBJECT.OBJECTDATA = 62 203'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 203')
        	 PRINT '**** RFC64868 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC64868 VALIDOBJECT.OBJECTDATA = 62 203 already exists'
         	PRINT ''
    	go


	/**********************************************************************************************************/
	/*** RFC64868 Maintain Text Types - ConfigurationItem						                            ***/
	/**********************************************************************************************************/

	If not exists (SELECT * FROM CONFIGURATIONITEM WHERE TASKID=260)
	Begin
		PRINT '**** RFC64868 Inserting CONFIGURATIONITEM WHERE TASKID=260 and TITLE = "Maintain Text Types"'
		INSERT INTO CONFIGURATIONITEM(TASKID, TITLE, DESCRIPTION, URL) 
		VALUES(260,'Maintain Text Types','Create, update or delete Text Types.','/apps/#/configuration/general/texttypes')		
		PRINT '**** RFC64868 Data successfully inserted in CONFIGURATIONITEM table.'
		PRINT ''			
	End
	Else
	Begin
		PRINT '**** RFC64868 CONFIGURATIONITEM WHERE TASKID=260 already exists'
		PRINT ''
	End
