/**********************************************************************************************************/
/*** RFC45001 Add Maintain Name Relationship Codes task security - Task					***/
/**********************************************************************************************************/
If NOT exists (select * from TASK where TASKID = 237)
BEGIN
	PRINT '**** RFC45001 Adding data TASK.TASKID = 237'
	INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
	VALUES (237, N'Maintain Name Relationship Codes',N'Create, update or delete Name Relationship Codes.')
	PRINT '**** RFC45001 Data successfully added to TASK table.'
	PRINT ''
END
ELSE
 	PRINT '**** RFC45001 TASK.TASKID = 237 already exists'
 	PRINT ''
go

/**********************************************************************************************************/
/*** RFC45001 Add Maintain Name Relationship Codes task security - FeatureTask				***/
/**********************************************************************************************************/
IF NOT exists (select * from FEATURETASK where FEATUREID = 51 AND TASKID = 237)
BEGIN
	PRINT '**** RFC45001 Inserting FEATURETASK.FEATUREID = 51, TASKID = 237'
	INSERT INTO FEATURETASK (FEATUREID, TASKID)
	VALUES (51, 237)
	PRINT '**** RFC45001 Data has been successfully added to FEATURETASK table.'
	PRINT ''
END
ELSE
	PRINT '**** RFC45001 FEATURETASK.FEATUREID = 51, TASKID = 237 already exists.'
	PRINT ''
go

/**********************************************************************************************************/
/*** RFC45001 Add Maintain Name Relationship Codes task security - Permission Definition		***/
/**********************************************************************************************************/
If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
			and OBJECTINTEGERKEY = 237
			and LEVELTABLE is null
			and LEVELKEY is null)
BEGIN
	PRINT '**** RFC45001 Adding TASK definition data PERMISSIONS.OBJECTKEY = 237'
	INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
	VALUES ('TASK', 237, NULL, NULL, NULL, 26, 0)
	PRINT '**** RFC45001 Data successfully added to PERMISSIONS table.'
	PRINT ''
END
ELSE
BEGIN
	PRINT '**** RFC45001 TASK definition data PERMISSIONS.OBJECTKEY = 237 already exists'
	PRINT ''
END
go

/**********************************************************************************************************/
/*** RFC45001 Add Maintain Name Relationship Codes task security - Task Permissions						***/
/**********************************************************************************************************/
If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
			and OBJECTINTEGERKEY = 237
			and LEVELTABLE = 'ROLE'
			and LEVELKEY = -1)
BEGIN
	PRINT '**** RFC45001 Adding TASK data PERMISSIONS.OBJECTKEY = 237'
	INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
	VALUES ('TASK', 237, NULL, 'ROLE', -1, 26, 0)
	PRINT '**** RFC45001 Data successfully added to PERMISSIONS table.'
	PRINT ''
END
ELSE
BEGIN
	PRINT '**** RFC45001 TASK data PERMISSIONS.OBJECTKEY = 237 already exists'
	PRINT ''
END
go

/**********************************************************************************************************/
/*** RFC45001 - ValidObject								***/
/**********************************************************************************************************/
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                          and OBJECTDATA = '32  72')
BEGIN
	PRINT '**** RFC45001 Adding data VALIDOBJECT.OBJECTDATA = 32  72'
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
	INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '32  72')
	PRINT '**** RFC45001 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
 	PRINT '**** RFC45001 VALIDOBJECT.OBJECTDATA = 32  72 already exists'
 	PRINT ''
go
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                          and OBJECTDATA = '32 172')
BEGIN
	PRINT '**** RFC45001 Adding data VALIDOBJECT.OBJECTDATA = 32 172'
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
	INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '32 172')
	PRINT '**** RFC45001 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
 	PRINT '**** RFC45001 VALIDOBJECT.OBJECTDATA = 32 172 already exists'
 	PRINT ''
go
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                          and OBJECTDATA = '32 572')
BEGIN
	PRINT '**** RFC45001 Adding data VALIDOBJECT.OBJECTDATA = 32 572'
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
	INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '32 572')
	PRINT '**** RFC45001 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
 	PRINT '**** RFC45001 VALIDOBJECT.OBJECTDATA = 32 572 already exists'
 	PRINT ''
go
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                          and OBJECTDATA = '32 972')
BEGIN
	PRINT '**** RFC45001 Adding data VALIDOBJECT.OBJECTDATA = 32 972'
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
	INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '32 972')
	PRINT '**** RFC45001 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
 	PRINT '**** RFC45001 VALIDOBJECT.OBJECTDATA = 32 972 already exists'
 	PRINT ''
go
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                          and OBJECTDATA = '32 273')
BEGIN
	PRINT '**** RFC45001 Adding data VALIDOBJECT.OBJECTDATA = 32 273'
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
	INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '32 273')
	PRINT '**** RFC45001 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
 	PRINT '**** RFC45001 VALIDOBJECT.OBJECTDATA = 32 273 already exists'
 	PRINT ''
go

