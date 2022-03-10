    	/*** RFC46655 Provide entry point for jurisdiction maintenance - Task	***/

	If NOT exists (select * from TASK where TASKID = 254)
        	BEGIN
         	 PRINT '**** RFC46655 Adding data TASK.TASKID = 254'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (254, N'Maintain Jurisdictions',N'Allows maintenance of Jurisdictions')
        	 PRINT '**** RFC46655 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC46655 TASK.TASKID = 254 already exists'
         	PRINT ''
    	go


    	/*** RFC46655 Provide entry point for jurisdiction maintenance - FeatureTask	***/

	IF NOT exists (select * from FEATURETASK where FEATUREID = 51 AND TASKID = 254)
		begin
		PRINT '**** RFC46655 Inserting FEATURETASK.FEATUREID = 51, TASKID = 254'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (51, 254)
		PRINT '**** RFC46655 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** RFC46655 FEATURETASK.FEATUREID = 51, TASKID = 254 already exists.'
		PRINT ''
 	go


    	/*** RFC46655 Provide entry point for jurisdiction maintenance - Permission Definition	***/

	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 254
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** RFC46655 Adding TASK definition data PERMISSIONS.OBJECTKEY = 254'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 254, NULL, NULL, NULL, 32, 0)
        	 PRINT '**** RFC46655 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** RFC46655 TASK definition data PERMISSIONS.OBJECTKEY = 254 already exists'
		 PRINT ''
         	END
    	go


    	/*** RFC46655 Provide entry point for jurisdiction maintenance - ValidObject ***/

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 142')
        	BEGIN
         	 PRINT '**** RFC46655 Adding data VALIDOBJECT.OBJECTDATA = 52 142'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 142')
        	 PRINT '**** RFC46655 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC46655 VALIDOBJECT.OBJECTDATA = 52 142 already exists'
         	PRINT ''
    	go


    	/*** RFC46655 Provide entry point for jurisdiction maintenance - ValidObject ***/

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 842')
        	BEGIN
         	 PRINT '**** RFC46655 Adding data VALIDOBJECT.OBJECTDATA = 52 842'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 842')
        	 PRINT '**** RFC46655 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC46655 VALIDOBJECT.OBJECTDATA = 52 842 already exists'
         	PRINT ''
    	go


    	/*** RFC46655 Provide entry point for jurisdiction maintenance - ValidObject ***/

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52  42')
        	BEGIN
         	 PRINT '**** RFC46655 Adding data VALIDOBJECT.OBJECTDATA = 52  42'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52  42')
        	 PRINT '**** RFC46655 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC46655 VALIDOBJECT.OBJECTDATA = 52  42 already exists'
         	PRINT ''
    	go

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 942')
        	BEGIN
         	 PRINT '**** RFC46655 Adding data VALIDOBJECT.OBJECTDATA = 52 942'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 942')
        	 PRINT '**** RFC46655 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC46655 VALIDOBJECT.OBJECTDATA = 52 942 already exists'
         	PRINT ''
    	go
    	
    	
	/*** RFC46655 Maintain Jurisdictions - ConfigurationItem						***/

	If exists (SELECT * FROM CONFIGURATIONITEM WHERE TASKID=254)
	Begin
		PRINT '**** RFC46655 CONFIGURATIONITEM WHERE TASKID=254 already exists'
		PRINT ''		
	End
	Else
	Begin
		PRINT '**** RFC46655 Inserting CONFIGURATIONITEM WHERE TASKID=254 and TITLE = "Maintain Jurisdictions"'
		INSERT INTO CONFIGURATIONITEM(TASKID,TITLE,DESCRIPTION,URL) 
		VALUES(254,'Maintain Jurisdictions','Maintain Jurisdictions for the firm.','/apps/#/configuration/general/jurisdictions')		
		PRINT '**** RFC46655 Data successfully inserted in CONFIGURATIONITEM table.'
		PRINT ''
	End
	go
	