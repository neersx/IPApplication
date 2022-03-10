    	/**********************************************************************************************************/
    	/*** RFC47117 Add Maintain Name Types security task - Task						***/
	/**********************************************************************************************************/
	If NOT exists (select * from TASK where TASKID = 252)
        	BEGIN
         	 PRINT '**** RFC47117 Adding data TASK.TASKID = 252'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (252, N'Maintain Name Types',N'Create, update or delete Name Types.')
        	 PRINT '**** RFC47117 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC47117 TASK.TASKID = 252 already exists'
         	PRINT ''
    	go

    	/**********************************************************************************************************/
    	/*** RFC47117 Add Maintain Name Types security task - FeatureTask					***/
	/**********************************************************************************************************/
	IF NOT exists (select * from FEATURETASK where FEATUREID = 51 AND TASKID = 252)
		begin
		PRINT '**** RFC47117 Inserting FEATURETASK.FEATUREID = 51, TASKID = 252'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (51, 252)
		PRINT '**** RFC47117 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** RFC47117 FEATURETASK.FEATUREID = 51, TASKID = 252 already exists.'
		PRINT ''
 	go

    	/**********************************************************************************************************/
    	/*** RFC47117 Add Maintain Name Types security task - Permission Definition				***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 252
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** RFC47117 Adding TASK definition data PERMISSIONS.OBJECTKEY = 252'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 252, NULL, NULL, NULL, 32, 0)
        	 PRINT '**** RFC47117 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** RFC47117 TASK definition data PERMISSIONS.OBJECTKEY = 252 already exists'
		 PRINT ''
         	END
    	go

    	/**********************************************************************************************************/
    	/*** RFC47117 - ValidObject								                ***/
	/**********************************************************************************************************/
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52  21')
        	BEGIN
         	 PRINT '**** RFC47117 Adding data VALIDOBJECT.OBJECTDATA = 52  21'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52  21')
        	 PRINT '**** RFC47117 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC47117 VALIDOBJECT.OBJECTDATA = 52  21 already exists'
         	PRINT ''
    	go
    If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52  22')
        	BEGIN
         	 PRINT '**** RFC47117 Adding data VALIDOBJECT.OBJECTDATA = 52  22'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52  22')
        	 PRINT '**** RFC47117 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC47117 VALIDOBJECT.OBJECTDATA = 52  22 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 821')
        	BEGIN
         	 PRINT '**** RFC47117 Adding data VALIDOBJECT.OBJECTDATA = 52 821'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 821')
        	 PRINT '**** RFC47117 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC47117 VALIDOBJECT.OBJECTDATA = 52 821 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 022')
        	BEGIN
         	 PRINT '**** RFC47117 Adding data VALIDOBJECT.OBJECTDATA = 52 022'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 022')
        	 PRINT '**** RFC47117 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC47117 VALIDOBJECT.OBJECTDATA = 52 022 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 122')
        	BEGIN
         	 PRINT '**** RFC47117 Adding data VALIDOBJECT.OBJECTDATA = 52 122'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 122')
        	 PRINT '**** RFC47117 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC47117 VALIDOBJECT.OBJECTDATA = 52 122 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 522')
        	BEGIN
         	 PRINT '**** RFC47117 Adding data VALIDOBJECT.OBJECTDATA = 52 522'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 522')
        	 PRINT '**** RFC47117 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC47117 VALIDOBJECT.OBJECTDATA = 52 522 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 922')
        	BEGIN
         	 PRINT '**** RFC47117 Adding data VALIDOBJECT.OBJECTDATA = 52 922'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 922')
        	 PRINT '**** RFC47117 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC47117 VALIDOBJECT.OBJECTDATA = 52 922 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 223')
        	BEGIN
         	 PRINT '**** RFC47117 Adding data VALIDOBJECT.OBJECTDATA = 52 223'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 223')
        	 PRINT '**** RFC47117 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC47117 VALIDOBJECT.OBJECTDATA = 52 223 already exists'
         	PRINT ''
    	go


        /**********************************************************************************************************/
        /*** RFC47117 Maintain Name Types - ConfigurationItem						        ***/
        /**********************************************************************************************************/

        If exists (SELECT * FROM CONFIGURATIONITEM WHERE TASKID=252)
        Begin
	        PRINT '**** RFC47117 CONFIGURATIONITEM WHERE TASKID=252 already exists'
	        PRINT ''		
        End
        Else
        Begin
	        PRINT '**** RFC47117 Inserting CONFIGURATIONITEM WHERE TASKID=252 and TITLE = "Maintain Name Types"'
	        INSERT INTO CONFIGURATIONITEM(TASKID,TITLE,DESCRIPTION,URL) 
	        VALUES(252,'Maintain Name Types','Create, update or delete Name Types.','/apps/#/configuration/general/nametypes')		
	        PRINT '**** RFC47117 Data successfully inserted in CONFIGURATIONITEM table.'
	        PRINT ''
        End
        go