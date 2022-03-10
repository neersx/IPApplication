
/**********************************************************************************************************/
/*** RFC73763 Add task security for the visibility of New Portal link - Task							***/
/**********************************************************************************************************/

	If NOT exists (select * from TASK where TASKID = 275)
        	BEGIN
         		PRINT '**** RFC73763 Adding data TASK.TASKID = 275'
			INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
			VALUES (275, N'Show Portal Link in Web',N'Ability to set visibility for New Portal link')
        		PRINT '**** RFC73763 Data successfully added to TASK table.'
			PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC73763 TASK.TASKID = 275 already exists'
         	PRINT ''
    	go

/**********************************************************************************************************/
/*** RFC73763 Add task security for the visibility of New Portal link - FeatureTask						***/
/**********************************************************************************************************/

	IF NOT exists (select * from FEATURETASK where FEATUREID = 21 AND TASKID = 275)
		begin
		PRINT '**** RFC73763 Inserting FEATURETASK.FEATUREID = 21, TASKID = 275'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (21, 275)
		PRINT '**** RFC73763 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** RFC73763 FEATURETASK.FEATUREID = 21, TASKID = 275 already exists.'
		PRINT ''
 	go

/**********************************************************************************************************/
/*** RFC73763 Add task security for the visibility of New Portal link - Permission Definition			***/
/**********************************************************************************************************/

	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 275
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         		PRINT '**** RFC73763 Adding TASK definition data PERMISSIONS.OBJECTKEY = 275'
			INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
			VALUES ('TASK', 275, NULL, NULL, NULL, 32, 0)
        		PRINT '**** RFC73763 Data successfully added to PERMISSIONS table.'
			PRINT ''
         	END
    	ELSE
         	BEGIN
         		PRINT '**** RFC73763 TASK definition data PERMISSIONS.OBJECTKEY = 275 already exists'
			PRINT ''
         	END
    	go

/**********************************************************************************************************/
/*** RFC73763 Add task security for the visibility of New Portal link - Task Permissions				***/
/**********************************************************************************************************/

	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 275
				and LEVELTABLE = 'ROLE'
				and LEVELKEY = -1)
        	BEGIN
         		PRINT '**** RFC73763 Adding TASK data PERMISSIONS.OBJECTKEY = 275'
			INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
			VALUES ('TASK', 275, NULL, 'ROLE', -1, 32, 0)
        		PRINT '**** RFC73763 Data successfully added to PERMISSIONS table.'
			PRINT ''
         	END
    	ELSE
         	BEGIN
         		PRINT '**** RFC73763 TASK data PERMISSIONS.OBJECTKEY = 275 already exists'
			PRINT ''
         	END
    	go
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 275
				and LEVELTABLE = 'ROLE'
				and LEVELKEY = -20)
        	BEGIN
         		PRINT '**** RFC73763 Adding TASK data PERMISSIONS.OBJECTKEY = 275'
			INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
			VALUES ('TASK', 275, NULL, 'ROLE', -20, 32, 0)
        		PRINT '**** RFC73763 Data successfully added to PERMISSIONS table.'
			PRINT ''
         	END
    	ELSE
         	BEGIN
         		PRINT '**** RFC73763 TASK data PERMISSIONS.OBJECTKEY = 275 already exists'
			PRINT ''
         	END
    	go
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 275
				and LEVELTABLE = 'ROLE'
				and LEVELKEY = -21)
        	BEGIN
         		PRINT '**** RFC73763 Adding TASK data PERMISSIONS.OBJECTKEY = 275'
			INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
			VALUES ('TASK', 275, NULL, 'ROLE', -21, 32, 0)
        		PRINT '**** RFC73763 Data successfully added to PERMISSIONS table.'
			PRINT ''
         	END
    	ELSE
         	BEGIN
         		PRINT '**** RFC73763 TASK data PERMISSIONS.OBJECTKEY = 275 already exists'
			PRINT ''
         	END
    	go
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 275
				and LEVELTABLE = 'ROLE'
				and LEVELKEY = -22)
        	BEGIN
         		PRINT '**** RFC73763 Adding TASK data PERMISSIONS.OBJECTKEY = 275'
			INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
			VALUES ('TASK', 275, NULL, 'ROLE', -22, 32, 0)
        		PRINT '**** RFC73763 Data successfully added to PERMISSIONS table.'
			PRINT ''
         	END
    	ELSE
         	BEGIN
         		PRINT '**** RFC73763 TASK data PERMISSIONS.OBJECTKEY = 275 already exists'
			PRINT ''
         	END
    	go

/**********************************************************************************************************/
/*** RFC73763 - ValidObject																				***/
/**********************************************************************************************************/

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
									and OBJECTDATA = '72  52')
        	BEGIN
         		PRINT '**** RFC73763 Adding data VALIDOBJECT.OBJECTDATA = 72  52'
			declare @validObject int
      				Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
				INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
			VALUES (@validObject, 20, '72  52')
        		PRINT '**** RFC73763 Data successfully added to VALIDOBJECT table.'
			PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC73763 VALIDOBJECT.OBJECTDATA = 72  52 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
									and OBJECTDATA = '72 751')
        	BEGIN
         		PRINT '**** RFC73763 Adding data VALIDOBJECT.OBJECTDATA = 72 751'
			declare @validObject int
      				Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
				INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
			VALUES (@validObject, 20, '72 751')
        		PRINT '**** RFC73763 Data successfully added to VALIDOBJECT table.'
			PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC73763 VALIDOBJECT.OBJECTDATA = 72 751 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
									and OBJECTDATA = '72 851')
        	BEGIN
         		PRINT '**** RFC73763 Adding data VALIDOBJECT.OBJECTDATA = 72 851'
			declare @validObject int
      				Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
				INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
			VALUES (@validObject, 20, '72 851')
        		PRINT '**** RFC73763 Data successfully added to VALIDOBJECT table.'
			PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC73763 VALIDOBJECT.OBJECTDATA = 72 851 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
									and OBJECTDATA = '72 152')
        	BEGIN
         		PRINT '**** RFC73763 Adding data VALIDOBJECT.OBJECTDATA = 72 152'
			declare @validObject int
      				Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
				INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
			VALUES (@validObject, 20, '72 152')
        		PRINT '**** RFC73763 Data successfully added to VALIDOBJECT table.'
			PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC73763 VALIDOBJECT.OBJECTDATA = 72 152 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
									and OBJECTDATA = '72 852')
        	BEGIN
         		PRINT '**** RFC73763 Adding data VALIDOBJECT.OBJECTDATA = 72 852'
			declare @validObject int
      				Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
				INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
			VALUES (@validObject, 20, '72 852')
        		PRINT '**** RFC73763 Data successfully added to VALIDOBJECT table.'
			PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC73763 VALIDOBJECT.OBJECTDATA = 72 852 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
									and OBJECTDATA = '72 952')
        	BEGIN
         		PRINT '**** RFC73763 Adding data VALIDOBJECT.OBJECTDATA = 72 952'
			declare @validObject int
      				Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
				INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
			VALUES (@validObject, 20, '72 952')
        		PRINT '**** RFC73763 Data successfully added to VALIDOBJECT table.'
			PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC73763 VALIDOBJECT.OBJECTDATA = 72 952 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
									and OBJECTDATA = '72 353')
        	BEGIN
         		PRINT '**** RFC73763 Adding data VALIDOBJECT.OBJECTDATA = 72 353'
			declare @validObject int
      				Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
				INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
			VALUES (@validObject, 20, '72 353')
        		PRINT '**** RFC73763 Data successfully added to VALIDOBJECT table.'
			PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC73763 VALIDOBJECT.OBJECTDATA = 72 353 already exists'
         	PRINT ''
    	go

/**********************************************************************************************************/
/*** RFC73763 - Update 	'Try New Portal' text to 'New Portal'											***/
/**********************************************************************************************************/
	If exists (SELECT * FROM APPSLINK WHERE TITLE = 'Try New Portal' and TASKID is null)
		BEGIN
				PRINT '**** RFC73763 Update "Try New Portal" text to "New Portal"'
				UPDATE APPSLINK SET TITLE = 'New Portal', TASKID = 275, CHECKEXECUTE = 1 WHERE TITLE = 'Try New Portal'
		END
	ELSE
			PRINT '**** RFC73763 New Portal text already updated'
			PRINT ''
	
/**********************************************************************************************************/
/*** RFC73763 Update task security for the visibility of New Portal link - Task							***/
/**********************************************************************************************************/
	PRINT '**** RFC73763 Try update TASKNAME and DESCRIPTION for TASK 275'
	UPDATE TASK SET TASKNAME = 'Show New Portal Link', DESCRIPTION =' Controls visibility of the "New Portal" link on the Sidebar and the Case View link in the Case Details header'
	WHERE TASKID = 275
	GO
