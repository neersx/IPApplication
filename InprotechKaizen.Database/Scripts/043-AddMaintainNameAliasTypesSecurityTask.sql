/**********************************************************************************************************/
/*** RFC45352 Add Maintain Name Alias Types task security - Task					***/
/**********************************************************************************************************/
If NOT exists (select * from TASK where TASKID = 238)
BEGIN
	PRINT '**** RFC45352 Adding data TASK.TASKID = 238'
	INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
	VALUES (238, N'Maintain Name Alias Types',N'Create, update or delete Name Alias Types.')
	PRINT '**** RFC45352 Data successfully added to TASK table.'
	PRINT ''
END
ELSE
	PRINT '**** RFC45352 TASK.TASKID = 238 already exists'
	PRINT ''
go

/**********************************************************************************************************/
/*** RFC45352 Add Maintain Name Alias Types task security - FeatureTask					***/
/**********************************************************************************************************/
IF NOT exists (select * from FEATURETASK where FEATUREID = 51 AND TASKID = 238)
BEGIN
	PRINT '**** RFC45352 Inserting FEATURETASK.FEATUREID = 51, TASKID = 238'
	INSERT INTO FEATURETASK (FEATUREID, TASKID)
	VALUES (51, 238)
	PRINT '**** RFC45352 Data has been successfully added to FEATURETASK table.'
	PRINT ''
END
ELSE
	PRINT '**** RFC45352 FEATURETASK.FEATUREID = 51, TASKID = 238 already exists.'
	PRINT ''
go

/**********************************************************************************************************/
/*** RFC45352 Add Maintain Name Alias Types task security - Permission Definition			***/
/**********************************************************************************************************/
If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
	and OBJECTINTEGERKEY = 238
	and LEVELTABLE is null
	and LEVELKEY is null)
BEGIN
	PRINT '**** RFC45352 Adding TASK definition data PERMISSIONS.OBJECTKEY = 238'
	INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
	VALUES ('TASK', 238, NULL, NULL, NULL, 26, 0)
	PRINT '**** RFC45352 Data successfully added to PERMISSIONS table.'
	PRINT ''
END
ELSE
BEGIN
	PRINT '**** RFC45352 TASK definition data PERMISSIONS.OBJECTKEY = 238 already exists'
	PRINT ''
END
go

/**********************************************************************************************************/
/*** RFC45352 Add Maintain Name Alias Types task security - Task Permissions				***/
/**********************************************************************************************************/
If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
	and OBJECTINTEGERKEY = 238
	and LEVELTABLE = 'ROLE'
	and LEVELKEY = -1)
BEGIN
	PRINT '**** RFC45352 Adding TASK data PERMISSIONS.OBJECTKEY = 238'
	INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
	VALUES ('TASK', 238, NULL, 'ROLE', -1, 26, 0)
	PRINT '**** RFC45352 Data successfully added to PERMISSIONS table.'
	PRINT ''
END
ELSE
BEGIN
	PRINT '**** RFC45352 TASK data PERMISSIONS.OBJECTKEY = 238 already exists'
	PRINT ''
END
go

/**********************************************************************************************************/
/*** RFC45352 - ValidObject										***/
/**********************************************************************************************************/
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
          and OBJECTDATA = '32  82')
BEGIN
	PRINT '**** RFC45352 Adding data VALIDOBJECT.OBJECTDATA = 32  82'
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
	INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '32  82')
	PRINT '**** RFC45352 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** RFC45352 VALIDOBJECT.OBJECTDATA = 32  82 already exists'
	PRINT ''
go
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
          and OBJECTDATA = '32 182')
BEGIN
	PRINT '**** RFC45352 Adding data VALIDOBJECT.OBJECTDATA = 32 182'
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
	INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '32 182')
	PRINT '**** RFC45352 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** RFC45352 VALIDOBJECT.OBJECTDATA = 32 182 already exists'
	PRINT ''
go
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
          and OBJECTDATA = '32 582')
BEGIN
	PRINT '**** RFC45352 Adding data VALIDOBJECT.OBJECTDATA = 32 582'
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
	INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '32 582')
	PRINT '**** RFC45352 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** RFC45352 VALIDOBJECT.OBJECTDATA = 32 582 already exists'
	PRINT ''
go
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
          and OBJECTDATA = '32 982')
BEGIN
	PRINT '**** RFC45352 Adding data VALIDOBJECT.OBJECTDATA = 32 982'
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
	INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '32 982')
	PRINT '**** RFC45352 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** RFC45352 VALIDOBJECT.OBJECTDATA = 32 982 already exists'
	PRINT ''
go
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
          and OBJECTDATA = '32 283')
BEGIN
	PRINT '**** RFC45352 Adding data VALIDOBJECT.OBJECTDATA = 32 283'
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
	INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '32 283')
	PRINT '**** RFC45352 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** RFC45352 VALIDOBJECT.OBJECTDATA = 32 283 already exists'
	PRINT ''
go

