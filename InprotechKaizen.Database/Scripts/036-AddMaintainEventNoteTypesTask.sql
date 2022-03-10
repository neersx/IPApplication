
   	/**********************************************************************************************************/
    /*** RFC43202 Allow the user to maintain Event Note Types - Feature										***/
	/**********************************************************************************************************/


	IF NOT exists (select * from FEATURE where FEATUREID = 75)
		begin
		PRINT '**** RFC43202 Inserting FEATURE.FEATUREID = 75'
		INSERT INTO FEATURE (FEATUREID, FEATURENAME, CATEGORYID, ISEXTERNAL, ISINTERNAL)
		VALUES (75, N'Event Note Types', 9801, 0, 1)
		PRINT '**** RFC43202 Data has been successfully added to FEATURE table.'
		PRINT ''
		END
	ELSE
		PRINT '**** RFC43202 FEATURE.FEATUREID = 75 already exists.'
		PRINT ''
 	go


    	/**********************************************************************************************************/
    	/*** RFC43202 Allow the user to maintain Event Note Types - Task									***/
	/**********************************************************************************************************/

	If NOT exists (select * from TASK where TASKID = 228)
        	BEGIN
         	 PRINT '**** RFC43202 Adding data TASK.TASKID = 228'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (228, N'Maintain Event Note Types',N'Create, update or delete event note types in the system.')
        	 PRINT '**** RFC43202 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC43202 TASK.TASKID = 228 already exists'
         	PRINT ''
    	go


    	/**********************************************************************************************************/
    	/*** RFC43202 Allow the user to maintain Event Note Types - FeatureTask				        ***/
	/**********************************************************************************************************/

	IF NOT exists (select * from FEATURETASK where FEATUREID = 75 AND TASKID = 228)
		begin
		PRINT '**** RFC43202 Inserting FEATURETASK.FEATUREID = 75, TASKID = 228'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (75, 228)
		PRINT '**** RFC43202 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** RFC43202 FEATURETASK.FEATUREID = 75, TASKID = 228 already exists.'
		PRINT ''
 	go


    	/**********************************************************************************************************/
    	/*** RFC43202 Allow the user to maintain Event Note Types - Permission Definition			***/
	/**********************************************************************************************************/


	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 228
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** RFC43202 Adding TASK definition data PERMISSIONS.OBJECTKEY = 228'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 228, NULL, NULL, NULL, 26, 0)
        	 PRINT '**** RFC43202 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** RFC43202 TASK definition data PERMISSIONS.OBJECTKEY = 228 already exists'
		 PRINT ''
         	END
    	go


    	/**********************************************************************************************************/
    	/*** RFC43202 Allow the user to maintain Event Note Types - Task Permissions				***/
	/**********************************************************************************************************/

	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 228
				and LEVELTABLE = 'ROLE'
				and LEVELKEY = -1)
        	BEGIN
         	 PRINT '**** RFC43202 Adding TASK data PERMISSIONS.OBJECTKEY = 228'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 228, NULL, 'ROLE', -1, 26, 0)
        	 PRINT '**** RFC43202 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** RFC43202 TASK data PERMISSIONS.OBJECTKEY = 228 already exists'
		 PRINT ''
         	END
    	go


    	/**********************************************************************************************************/
    	/*** RFC43202 - ValidObject								                ***/
	/**********************************************************************************************************/


	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '22  82')
        	BEGIN
         	 PRINT '**** RFC43202 Adding data VALIDOBJECT.OBJECTDATA = 22  82'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '22  82')
        	 PRINT '**** RFC43202 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC43202 VALIDOBJECT.OBJECTDATA = 22  82 already exists'
         	PRINT ''
    	go

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '22 881')
        	BEGIN
         	 PRINT '**** RFC43202 Adding data VALIDOBJECT.OBJECTDATA = 22 881'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '22 881')
        	 PRINT '**** RFC43202 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC43202 VALIDOBJECT.OBJECTDATA = 22 881 already exists'
         	PRINT ''
    	go

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '22 182')
        	BEGIN
         	 PRINT '**** RFC43202 Adding data VALIDOBJECT.OBJECTDATA = 22 182'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '22 182')
        	 PRINT '**** RFC43202 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC43202 VALIDOBJECT.OBJECTDATA = 22 182 already exists'
         	PRINT ''
    	go

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '22 982')
        	BEGIN
         	 PRINT '**** RFC43202 Adding data VALIDOBJECT.OBJECTDATA = 22 982'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '22 982')
        	 PRINT '**** RFC43202 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC43202 VALIDOBJECT.OBJECTDATA = 22 982 already exists'
         	PRINT ''
    	go

