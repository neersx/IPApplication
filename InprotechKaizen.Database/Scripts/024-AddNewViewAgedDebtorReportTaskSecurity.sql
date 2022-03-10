
    /**********************************************************************************************************/
    /*** RFC25327 Configure task security for the Aged Debtors excel report - Feature Category		    ***/
    /**********************************************************************************************************/
	If NOT exists (select * from TABLECODES WHERE TABLECODE=9822)
        	BEGIN
         	 PRINT '**** RFC25327 Adding data TABLECODES.TABLECODE = 9822'
		 INSERT INTO TABLECODES (TABLECODE, TABLETYPE, [DESCRIPTION], USERCODE)
		 VALUES (9822, 98, N'Accounts Receivable',null)
        	 PRINT '**** RFC25327 Data successfully added to TABLECODES table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC25327 TABLECODES.TABLECODE = 9822 already exists'
         	PRINT ''
    	go

    /**********************************************************************************************************/
    /*** RFC25327 Configure task security for the Aged Debtors excel report - Feature			    ***/
    /**********************************************************************************************************/
	IF NOT exists (select * from FEATURE where FEATUREID = 72)
		begin
		PRINT '**** RFC25327 Inserting FEATURE.FEATUREID = 72'
		INSERT INTO FEATURE (FEATUREID, FEATURENAME, CATEGORYID, ISEXTERNAL, ISINTERNAL)
		VALUES (72, N'Financial Reports', 9822, 0, 1)
		PRINT '**** RFC25327 Data has been successfully added to FEATURE table.'
		PRINT ''
		END
	ELSE
		PRINT '**** RFC25327 FEATURE.FEATUREID = 72 already exists.'
		PRINT ''
 	go


    /**********************************************************************************************************/
    /*** RFC25327 Configure task security for the Aged Debtors excel report - Task							***/
	/**********************************************************************************************************/
	If NOT exists (select * from TASK where TASKID = 217)
        	BEGIN
         	 PRINT '**** RFC25327 Adding data TASK.TASKID = 217'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (217, N'View Aged Debtors Report',N'Allows the user to view the Aged Debtors Financial Report')
        	 PRINT '**** RFC25327 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC25327 TASK.TASKID = 217 already exists'
         	PRINT ''
    	go

    /**********************************************************************************************************/
    /*** RFC25327 Configure task security for the Aged Debtors excel report - FeatureTask					***/
	/**********************************************************************************************************/
	IF NOT exists (select * from FEATURETASK where FEATUREID = 72 AND TASKID = 217)
		begin
		PRINT '**** RFC25327 Inserting FEATURETASK.FEATUREID = 72, TASKID = 217'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (72, 217)
		PRINT '**** RFC25327 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** RFC25327 FEATURETASK.FEATUREID = 72, TASKID = 217 already exists.'
		PRINT ''
 	go

   	/**********************************************************************************************************/
    /*** RFC25327 Configure task security for the Aged Debtors excel report - Permission Definition			***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 217
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** RFC25327 Adding TASK definition data PERMISSIONS.OBJECTKEY = 217'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 217, NULL, NULL, NULL, 32, 0)
        	 PRINT '**** RFC25327 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** RFC25327 TASK definition data PERMISSIONS.OBJECTKEY = 217 already exists'
		 PRINT ''
         	END
    	go

    /**********************************************************************************************************/
    /*** RFC25327 Configure task security for the Aged Debtors excel report - Task Permissions				***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 217
				and LEVELTABLE = 'ROLE'
				and LEVELKEY = -21)
        	BEGIN
         	 PRINT '**** RFC25327 Adding TASK data PERMISSIONS.OBJECTKEY = 217'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 217, NULL, 'ROLE', -21, 32, 0)
        	 PRINT '**** RFC25327 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** RFC25327 TASK data PERMISSIONS.OBJECTKEY = 217 already exists'
		 PRINT ''
         	END
    	go

    /**********************************************************************************************************/
    /*** RFC25327 - ValidObject																				***/
	/**********************************************************************************************************/
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '12  79')
        	BEGIN
         	 PRINT '**** RFC25327 Adding data VALIDOBJECT.OBJECTDATA = 12  79'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '12  79')
        	 PRINT '**** RFC25327 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC25327 VALIDOBJECT.OBJECTDATA = 12  79 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '12 173')
        	BEGIN
         	 PRINT '**** RFC25327 Adding data VALIDOBJECT.OBJECTDATA = 12 173'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '12 173')
        	 PRINT '**** RFC25327 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC25327 VALIDOBJECT.OBJECTDATA = 12 173 already exists'
         	PRINT ''
    	go

