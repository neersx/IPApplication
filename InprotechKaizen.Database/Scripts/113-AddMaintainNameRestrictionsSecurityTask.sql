/**********************************************************************************************************/
/*** RFC68856 Maintain Name Restrictions - Task															***/
/**********************************************************************************************************/
If NOT exists (select * from TASK where TASKID = 261)
BEGIN
	PRINT '**** RFC68856 Adding data TASK.TASKID = 261'
	INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
	VALUES (261, N'Maintain Name Restrictions',N'Allows maintenance of Name Restrictions')
	PRINT '**** RFC68856 Data successfully added to TASK table.'
	PRINT ''
END
ELSE
	PRINT '**** RFC68856 TASK.TASKID = 261 already exists'
	PRINT ''
go
/**********************************************************************************************************/
/*** RFC68856 Maintain Name Restrictions - FeatureTask													***/
/**********************************************************************************************************/
IF NOT exists (select * from FEATURETASK where FEATUREID = 51 AND TASKID = 261)
begin
	PRINT '**** RFC68856 Inserting FEATURETASK.FEATUREID = 51, TASKID = 261'
	INSERT INTO FEATURETASK (FEATUREID, TASKID)
	VALUES (51, 261)
	PRINT '**** RFC68856 Data has been successfully added to FEATURETASK table.'
	PRINT ''
END
ELSE
	PRINT '**** RFC68856 FEATURETASK.FEATUREID = 51, TASKID = 261 already exists.'
	PRINT ''
go
/**********************************************************************************************************/
/*** RFC68856 Maintain Name Restrictions - Permission Definition											***/
/**********************************************************************************************************/
If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
and OBJECTINTEGERKEY = 261
and LEVELTABLE is null
and LEVELKEY is null)
BEGIN
	PRINT '**** RFC68856 Adding TASK definition data PERMISSIONS.OBJECTKEY = 261'
	INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
	VALUES ('TASK', 261, NULL, NULL, NULL, 32, 0)
	PRINT '**** RFC68856 Data successfully added to PERMISSIONS table.'
	PRINT ''
END
ELSE
BEGIN
	PRINT '**** RFC68856 TASK definition data PERMISSIONS.OBJECTKEY = 261 already exists'
	PRINT ''
END
go


/**********************************************************************************************************/
/*** RFC68856 - ValidObject																				***/
/**********************************************************************************************************/
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                and OBJECTDATA = '62  12')
BEGIN
	PRINT '**** RFC68856 Adding data VALIDOBJECT.OBJECTDATA = 62  12'
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
	INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '62  12')
	PRINT '**** RFC68856 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** RFC68856 VALIDOBJECT.OBJECTDATA = 62  12 already exists'
	PRINT ''
go
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                and OBJECTDATA = '62 811')
BEGIN
	PRINT '**** RFC68856 Adding data VALIDOBJECT.OBJECTDATA = 62 811'
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
	INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '62 811')
	PRINT '**** RFC68856 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** RFC68856 VALIDOBJECT.OBJECTDATA = 62 811 already exists'
	PRINT ''
go
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                and OBJECTDATA = '62 012')
BEGIN
	PRINT '**** RFC68856 Adding data VALIDOBJECT.OBJECTDATA = 62 012'
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
	INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '62 012')
	PRINT '**** RFC68856 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** RFC68856 VALIDOBJECT.OBJECTDATA = 62 012 already exists'
	PRINT ''
go
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                and OBJECTDATA = '62 112')
BEGIN
	PRINT '**** RFC68856 Adding data VALIDOBJECT.OBJECTDATA = 62 112'
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
	INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '62 112')
	PRINT '**** RFC68856 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** RFC68856 VALIDOBJECT.OBJECTDATA = 62 112 already exists'
	PRINT ''
go
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                and OBJECTDATA = '62 512')
BEGIN
	PRINT '**** RFC68856 Adding data VALIDOBJECT.OBJECTDATA = 62 512'
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
	INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '62 512')
	PRINT '**** RFC68856 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** RFC68856 VALIDOBJECT.OBJECTDATA = 62 512 already exists'
	PRINT ''
go
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                and OBJECTDATA = '62 912')
BEGIN
	PRINT '**** RFC68856 Adding data VALIDOBJECT.OBJECTDATA = 62 912'
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
	INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '62 912')
	PRINT '**** RFC68856 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** RFC68856 VALIDOBJECT.OBJECTDATA = 62 912 already exists'
	PRINT ''
go
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                and OBJECTDATA = '62 213')
BEGIN
	PRINT '**** RFC68856 Adding data VALIDOBJECT.OBJECTDATA = 62 213'
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
	INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '62 213')
	PRINT '**** RFC68856 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** RFC68856 VALIDOBJECT.OBJECTDATA = 62 213 already exists'
	PRINT ''
go
/**********************************************************************************************************/
/*** RFC68856 Maintain Name Restrictions - ConfigurationItem										        ***/
/**********************************************************************************************************/
If exists (SELECT * FROM CONFIGURATIONITEM WHERE TASKID=261)
Begin
	PRINT '**** RFC68856 CONFIGURATIONITEM WHERE TASKID=261 already exists'
	PRINT ''		
End
Else
Begin
	PRINT '**** RFC68856 Inserting CONFIGURATIONITEM WHERE TASKID=261 and TITLE = "Maintain Name Restrictions"'
	INSERT INTO CONFIGURATIONITEM(TASKID,TITLE,DESCRIPTION,URL) 
	VALUES(261,'Maintain Name Restrictions','Create, update or delete Name Restrictions.','/apps/#/configuration/general/namerestrictions')		
	PRINT '**** RFC68856 Data successfully inserted in CONFIGURATIONITEM table.'
	PRINT ''
End
go
