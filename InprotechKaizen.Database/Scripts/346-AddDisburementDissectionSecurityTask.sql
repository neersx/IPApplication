    /**********************************************************************************************************/
    /*** DR-75077 Disbursement Dissection security task - Task												***/
	/**********************************************************************************************************/
	If NOT exists (select * from TASK where TASKID = 292)
    BEGIN
         PRINT '**** DR-75077 Adding data TASK.TASKID = 292'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (292, N'Disbursement Dissection',N'Allow users to execute Disbursement Dissection')
         PRINT '**** DR-75077 Data successfully added to TASK table.'
		 PRINT ''
    END
    ELSE
         PRINT '**** DR-75077 TASK.TASKID = 292 already exists'
         PRINT ''
    go

  	/**********************************************************************************************************/
    /*** DR-75077 Disbursement Dissection security task - FeatureTask										***/
	/**********************************************************************************************************/
	IF NOT exists (select * from FEATURETASK where FEATUREID = 69 AND TASKID = 292)
	BEGIN
		PRINT '**** DR-75077 Inserting FEATURETASK.FEATUREID = 69, TASKID = 292'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (69, 292)
		PRINT '**** DR-75077 Data has been successfully added to FEATURETASK table.'
		PRINT ''
	END
	ELSE
		PRINT '**** DR-75077 FEATURETASK.FEATUREID = 69, TASKID = 292 already exists.'
		PRINT ''
 	go

    /**********************************************************************************************************/
    /*** DR-75077 Disbursement Dissection security task - Permission Definition								***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 292
				and LEVELTABLE is null
				and LEVELKEY is null)
    BEGIN
		PRINT '**** DR-75077 Adding TASK definition data PERMISSIONS.OBJECTKEY = 292'
		INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		VALUES ('TASK', 292, NULL, NULL, NULL, 32, 0)
		PRINT '**** DR-75077 Data successfully added to PERMISSIONS table.'
		PRINT ''
    END
	ELSE
    BEGIN
		PRINT '**** DR-75077 TASK definition data PERMISSIONS.OBJECTKEY = 292 already exists'
		PRINT ''
    END
    go

   	/**********************************************************************************************************/
    /*** DR-75077 - ValidObject																				***/
	/**********************************************************************************************************/

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20 and OBJECTDATA = '92 821')
    BEGIN
		PRINT '**** DR-75077 Adding data VALIDOBJECT.OBJECTDATA = 92 821'
		declare @validObject int
      	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
        INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '92 821')
        PRINT '**** DR-75077 Data successfully added to VALIDOBJECT table.'
		PRINT ''
    END
    ELSE
        PRINT '**** DR-75077 VALIDOBJECT.OBJECTDATA = 92 821 already exists'
        PRINT ''
    go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20 and OBJECTDATA = '92 122')
    BEGIN
        PRINT '**** DR-75077 Adding data VALIDOBJECT.OBJECTDATA = 92 122'
		declare @validObject int
      	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
        INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '92 122')
       	PRINT '**** DR-75077 Data successfully added to VALIDOBJECT table.'
		PRINT ''
    END
    ELSE
         PRINT '**** DR-75077 VALIDOBJECT.OBJECTDATA = 92 122 already exists'
         PRINT ''
    go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20 and OBJECTDATA = '92 922')
    BEGIN
        PRINT '**** DR-75077 Adding data VALIDOBJECT.OBJECTDATA = 92 922'
		declare @validObject int
      	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
        INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '92 922')
        PRINT '**** DR-75077 Data successfully added to VALIDOBJECT table.'
		PRINT ''
    END
    ELSE
        PRINT '**** DR-75077 VALIDOBJECT.OBJECTDATA = 92 922 already exists'
        PRINT ''
    go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20 and OBJECTDATA = '92 023')
    BEGIN
        PRINT '**** DR-75077 Adding data VALIDOBJECT.OBJECTDATA = 92 023'
		declare @validObject int
      	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
        INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '92 023')
        PRINT '**** DR-75077 Data successfully added to VALIDOBJECT table.'
		PRINT ''
    END
    ELSE
        PRINT '**** DR-75077 VALIDOBJECT.OBJECTDATA = 92 023 already exists'
        PRINT ''
    go

	/**********************************************************************************************************/
    /*** DR-75077 - Give Execute rights to users having insert rights for Record Wip and site control WIP Dissection Restricted is false ***/
	/**********************************************************************************************************/
	If exists (Select 1 from SITECONTROL where CONTROLID = 'WIP Dissection Restricted' and COLBOOLEAN = 0) and 
		not exists (Select 1 from PERMISSIONS where OBJECTINTEGERKEY = 292 and LEVELTABLE = 'ROLE')
	Begin
		PRINT '**** DR-75077 Adding TASK definition data PERMISSIONS.OBJECTKEY = 292'
		INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		SELECT 'TASK', 292, NULL, 'ROLE', P.LEVELKEY, 32, 0
		FROM PERMISSIONS P
		WHERE OBJECTINTEGERKEY = 134 and GRANTPERMISSION & 8 = 8 and LEVELTABLE = 'ROLE'
		PRINT '**** DR-75077 Data successfully added to PERMISSIONS table.'
		PRINT ''
    END
	ELSE
    BEGIN
		PRINT '**** DR-75077 TASK definition data PERMISSIONS.OBJECTKEY = 292 already exists or site control WIP Dissection Restricted is true'
		PRINT ''
    END
    go
