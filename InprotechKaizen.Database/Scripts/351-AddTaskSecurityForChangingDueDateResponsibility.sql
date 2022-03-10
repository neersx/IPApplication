  	/*** DR-75675 Create Security Task for changing Due Date Responsibility - Task						***/
	If NOT exists (select * from TASK where TASKID = 293)
        	BEGIN
         	 PRINT '**** DR-75675 Adding data TASK.TASKID = 293'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (293, N'Change Due Date Responsibility',N'Allows the changing of due date responsibility.')
        	 PRINT '**** DR-75675 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-75675 TASK.TASKID = 293 already exists'
         	PRINT ''
    	go

    	/*** DR-75675 Create Security Task for changing Due Date Responsibility - FeatureTask						***/
	
	IF NOT exists (select * from FEATURETASK where FEATUREID = 81 AND TASKID = 293)
		begin
		PRINT '**** DR-75675 Inserting FEATURETASK.FEATUREID = 81, TASKID = 293'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (81, 293)
		PRINT '**** DR-75675 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** DR-75675 FEATURETASK.FEATUREID = 81, TASKID = 293 already exists.'
		PRINT ''
 	go

    	/*** DR-75675 Create Security Task for changing Due Date Responsibility - Permission Definition						***/

	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 293
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** DR-75675 Adding TASK definition data PERMISSIONS.OBJECTKEY = 293'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 293, NULL, NULL, NULL, 32, 0)
        	 PRINT '**** DR-75675 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** DR-75675 TASK definition data PERMISSIONS.OBJECTKEY = 293 already exists'
		 PRINT ''
         	END
    	go

/*** DR-75675 Create Security Task for changing Due Date Responsibility - Task Permissions						***/

	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 293
				and LEVELTABLE = 'ROLE'
				and LEVELKEY = -1)
        	BEGIN
         	 PRINT '**** DR-75675 Adding TASK data PERMISSIONS.OBJECTKEY = 293'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 293, NULL, 'ROLE', -1, 32, 0)
        	 PRINT '**** DR-75675 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** DR-75675 TASK data PERMISSIONS.OBJECTKEY = 293 already exists'
		 PRINT ''
         	END
    	go

/**********************************************************************************************************/
    	/*** DR-75675 - ValidObject								***/

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '92  32')
        	BEGIN
         	 PRINT '**** DR-75675 Adding data VALIDOBJECT.OBJECTDATA = 92  32'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '92  32')
        	 PRINT '**** DR-75675 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-75675 VALIDOBJECT.OBJECTDATA = 92  32 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '92 831')
        	BEGIN
         	 PRINT '**** DR-75675 Adding data VALIDOBJECT.OBJECTDATA = 92 831'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '92 831')
        	 PRINT '**** DR-75675 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-75675 VALIDOBJECT.OBJECTDATA = 92 831 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '92 132')
        	BEGIN
         	 PRINT '**** DR-75675 Adding data VALIDOBJECT.OBJECTDATA = 92 132'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '92 132')
        	 PRINT '**** DR-75675 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-75675 VALIDOBJECT.OBJECTDATA = 92 132 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '92 932')
        	BEGIN
         	 PRINT '**** DR-75675 Adding data VALIDOBJECT.OBJECTDATA = 92 932'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '92 932')
        	 PRINT '**** DR-75675 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-75675 VALIDOBJECT.OBJECTDATA = 92 932 already exists'
         	PRINT ''
    	go


/*************Enable it by default if the user has 'Maintain Case Event' task permission. *************************************************/
If not exists (Select 1 from PERMISSIONS where OBJECTINTEGERKEY = 293 and LEVELTABLE = 'ROLE' and LEVELKEY <> -1)
Begin
    PRINT '**** DR-75675 Adding TASK definition data PERMISSIONS.OBJECTKEY = 293'
    INSERT PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION)
    SELECT 'TASK', 293, NULL, 'ROLE', P.LEVELKEY, 32, 0
    FROM PERMISSIONS P
    WHERE OBJECTINTEGERKEY = 142 and GRANTPERMISSION & 8 = 8 and LEVELTABLE = 'ROLE' and LEVELKEY <> -1
    PRINT '**** DR-75675 Data successfully added to PERMISSIONS table.'
    PRINT ''
END
ELSE
BEGIN
    PRINT '**** DR-75675 TASK definition data PERMISSIONS.OBJECTKEY = 293 already exists '
    PRINT ''
END
go