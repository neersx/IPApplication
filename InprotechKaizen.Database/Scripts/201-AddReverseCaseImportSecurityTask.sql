/**********************************************************************************************************/
/*** DR-12092 Ability to reverse Case Import batch - Task						***/
/**********************************************************************************************************/
If NOT exists (select * from TASK where TASKID = 276)
BEGIN
	PRINT '**** DR-12092 Adding data TASK.TASKID = 276'
	INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
	VALUES (276, N'Reverse Imported Cases',N'Reverse batch of imported cases')
	PRINT '**** DR-12092 Data successfully added to TASK table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-12092 TASK.TASKID = 276 already exists'
PRINT ''
go

/**********************************************************************************************************/
/*** DR-12092 Ability to reverse Case Import batch - FeatureTask						***/
/**********************************************************************************************************/
IF NOT exists (select * from FEATURETASK where FEATUREID = 29 AND TASKID = 276)
begin
	PRINT '**** DR-12092 Inserting FEATURETASK.FEATUREID = 29, TASKID = 276'
	INSERT INTO FEATURETASK (FEATUREID, TASKID)
	VALUES (29, 276)
	PRINT '**** DR-12092 Data has been successfully added to FEATURETASK table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-12092 FEATURETASK.FEATUREID = 29, TASKID = 276 already exists.'
PRINT ''
go

/**********************************************************************************************************/
/*** DR-12092 Ability to reverse Case Import batch - Permission Definition						***/
/**********************************************************************************************************/
If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 276
				and LEVELTABLE is null
				and LEVELKEY is null)
BEGIN
	PRINT '**** DR-12092 Adding TASK definition data PERMISSIONS.OBJECTKEY = 276'
	INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
	VALUES ('TASK', 276, NULL, NULL, NULL, 32, 0)
    PRINT '**** DR-12092 Data successfully added to PERMISSIONS table.'
	PRINT ''
END
ELSE
BEGIN
	PRINT '**** DR-12092 TASK definition data PERMISSIONS.OBJECTKEY = 276 already exists'
	PRINT ''
END
go

/**********************************************************************************************************/
/*** DR-12092 - ValidObject								***/
/**********************************************************************************************************/
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '72 861')
BEGIN
	PRINT '**** DR-12092 Adding data VALIDOBJECT.OBJECTDATA = 72 861'
	declare @validObject int
    Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
    INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '72 861')
    PRINT '**** DR-12092 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-12092 VALIDOBJECT.OBJECTDATA = 72 861 already exists'
PRINT ''
go

If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '72 162')
BEGIN
	PRINT '**** DR-12092 Adding data VALIDOBJECT.OBJECTDATA = 72 162'
	declare @validObject int
    Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
    INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '72 162')
    PRINT '**** DR-12092 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-12092 VALIDOBJECT.OBJECTDATA = 72 162 already exists'
PRINT ''
go

If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '72  62')
BEGIN
	PRINT '**** DR-12092 Adding data VALIDOBJECT.OBJECTDATA = 72  62'
	declare @validObject int
    Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
    INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '72  62')
    PRINT '**** DR-12092 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-12092 VALIDOBJECT.OBJECTDATA = 72  62 already exists'
PRINT ''
go

If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '72 062')
BEGIN
	PRINT '**** DR-12092 Adding data VALIDOBJECT.OBJECTDATA = 72 062'
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
	INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '72 062')
    PRINT '**** DR-12092 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-12092 VALIDOBJECT.OBJECTDATA = 72 062 already exists'
PRINT ''
go

If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '72 562')
BEGIN
	PRINT '**** DR-12092 Adding data VALIDOBJECT.OBJECTDATA = 72 562'
	declare @validObject int
    Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
    INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '72 562')
    PRINT '**** DR-12092 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-12092 VALIDOBJECT.OBJECTDATA = 72 562 already exists'
PRINT ''
go

If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '72 962')
BEGIN
	PRINT '**** DR-12092 Adding data VALIDOBJECT.OBJECTDATA = 72 962'
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
	INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '72 962')
	PRINT '**** DR-12092 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-12092 VALIDOBJECT.OBJECTDATA = 72 962 already exists'
PRINT ''
go
	
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '72 263')
BEGIN
	PRINT '**** DR-12092 Adding data VALIDOBJECT.OBJECTDATA = 72 263'
	declare @validObject int
    Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
    INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '72 263')
    PRINT '**** DR-12092 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-12092 VALIDOBJECT.OBJECTDATA = 72 263 already exists'
PRINT ''
go
