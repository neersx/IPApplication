    	/*** RFC64748 Add View Jurisdiction Task - Task		***/

	If NOT exists (select * from TASK where TASKID = 268)
        	BEGIN
         	 PRINT '**** RFC64748 Adding data TASK.TASKID = 268'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (268, N'View Jurisdiction',N'Ability to view Jurisdictions')
        	 PRINT '**** RFC64748 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC64748 TASK.TASKID = 268 already exists'
         	PRINT ''
    	go


    	/*** RFC64748 Add View Jurisdiction Task - FeatureTask	***/

	IF NOT exists (select * from FEATURETASK where FEATUREID = 51 AND TASKID = 268)
		begin
		PRINT '**** RFC64748 Inserting FEATURETASK.FEATUREID = 51, TASKID = 268'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (51, 268)
		PRINT '**** RFC64748 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** RFC64748 FEATURETASK.FEATUREID = 51, TASKID = 268 already exists.'
		PRINT ''
 	go


    	/*** RFC64748 Add View Jurisdiction Task - Permission Definition	***/

	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 268
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** RFC64748 Adding TASK definition data PERMISSIONS.OBJECTKEY = 268'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 268, NULL, NULL, NULL, 32, 0)
        	 PRINT '**** RFC64748 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** RFC64748 TASK definition data PERMISSIONS.OBJECTKEY = 268 already exists'
		 PRINT ''
         	END
    	go


    	/*** RFC64748 Add View Jurisdiction Task - ValidObject	***/
		If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62  82')
        	BEGIN
         	 PRINT '**** RFC64748 Adding data VALIDOBJECT.OBJECTDATA = 62  82'
				declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
				INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
				VALUES (@validObject, 20, '62  82')
			PRINT '**** RFC64748 Data successfully added to VALIDOBJECT table.'
			PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC64748 VALIDOBJECT.OBJECTDATA = 62  82 already exists'
         	PRINT ''
    	go

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 182')
        	BEGIN
         	 PRINT '**** RFC64748 Adding data VALIDOBJECT.OBJECTDATA = 62 182'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 182')
        	 PRINT '**** RFC64748 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC64748 VALIDOBJECT.OBJECTDATA = 62 182 already exists'
         	PRINT ''
    	go

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 882')
        	BEGIN
         	 PRINT '**** RFC64748 Adding data VALIDOBJECT.OBJECTDATA = 62 882'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 882')
        	 PRINT '**** RFC64748 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC64748 VALIDOBJECT.OBJECTDATA = 62 882 already exists'
         	PRINT ''
    	go

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 982')
        	BEGIN
         	 PRINT '**** RFC64748 Adding data VALIDOBJECT.OBJECTDATA = 62 982'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 982')
        	 PRINT '**** RFC64748 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC64748 VALIDOBJECT.OBJECTDATA = 62 982 already exists'
         	PRINT ''
    	go


	/*** RFC64748 View Jurisdictions - ConfigurationItem						***/

	If exists (SELECT * FROM CONFIGURATIONITEM WHERE TASKID=268)
	Begin
		PRINT '**** RFC64748 CONFIGURATIONITEM WHERE TASKID=268 already exists'
		PRINT ''		
	End
	Else
	Begin
		PRINT '**** RFC64748 Inserting CONFIGURATIONITEM WHERE TASKID=268 and TITLE = "View Jurisdictions"'
		INSERT INTO CONFIGURATIONITEM(TASKID,TITLE,DESCRIPTION,URL) 
		VALUES(268,'View Jurisdictions','View Jurisdictions for the firm.','/apps/#/configuration/general/jurisdictions')		
		PRINT '**** RFC64748 Data successfully inserted in CONFIGURATIONITEM table.'
		PRINT ''
	End
	go