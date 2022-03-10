/**********************************************************************************************************/
/*** RFC59306 Add task security for Maintain Data Items - Task						***/
/**********************************************************************************************************/
If NOT exists (select * from TASK where TASKID = 272)
BEGIN
    PRINT '**** RFC59306 Adding data TASK.TASKID = 272'
	INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
	VALUES (272, N'Maintain Data Items',N'Ability to maintain Data Items')
    PRINT '**** RFC59306 Data successfully added to TASK table.'
	PRINT ''
END
ELSE
	PRINT '**** RFC59306 TASK.TASKID = 272 already exists'
	PRINT ''
go

/**********************************************************************************************************/
/*** RFC59306 Add task security for Maintain Data Items - FeatureTask									***/
/**********************************************************************************************************/
IF NOT exists (select * from FEATURETASK where FEATUREID = 51 AND TASKID = 272)
begin
	PRINT '**** RFC68856 Inserting FEATURETASK.FEATUREID = 51, TASKID = 272'
	INSERT INTO FEATURETASK (FEATUREID, TASKID)
	VALUES (51, 272)
	PRINT '**** RFC68856 Data has been successfully added to FEATURETASK table.'
	PRINT ''
END
ELSE
	PRINT '**** RFC68856 FEATURETASK.FEATUREID = 51, TASKID = 272 already exists.'
	PRINT ''
go


/**********************************************************************************************************/
/*** RFC59306 Add task security for Maintain Data Items - Permission Definition							***/
/**********************************************************************************************************/
If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
		and OBJECTINTEGERKEY = 272
		and LEVELTABLE is null
		and LEVELKEY is null)
BEGIN
	PRINT '**** RFC59306 Adding TASK definition data PERMISSIONS.OBJECTKEY = 272'
	INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
	VALUES ('TASK', 272, NULL, NULL, NULL, 32, 0)
	PRINT '**** RFC59306 Data successfully added to PERMISSIONS table.'
	PRINT ''
END
ELSE
BEGIN
	PRINT '**** RFC59306 TASK definition data PERMISSIONS.OBJECTKEY = 272 already exists'
	PRINT ''
END
go

/**********************************************************************************************************/
/*** RFC59306 - ValidObject																				***/
/**********************************************************************************************************/


If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                        and OBJECTDATA = '72  22')
BEGIN
    PRINT '**** RFC59306 Adding data VALIDOBJECT.OBJECTDATA = 72  22'
	declare @validObject int
    Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
    INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '72  22')
    PRINT '**** RFC59306 Data successfully added to VALIDOBJECT table.'
PRINT ''
END
ELSE
	PRINT '**** RFC59306 VALIDOBJECT.OBJECTDATA = 72  22 already exists'
	PRINT ''
go

If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                        and OBJECTDATA = '72 922')
BEGIN
	PRINT '**** RFC59306 Adding data VALIDOBJECT.OBJECTDATA = 72 922'
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
	INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '72 922')
	PRINT '**** RFC59306 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** RFC59306 VALIDOBJECT.OBJECTDATA = 72 922 already exists'
	PRINT ''
go


/**********************************************************************************************************/
/*** RFC59306 Add task security for Maintain Data Items - ConfigurationItem							    ***/
/**********************************************************************************************************/
If exists (SELECT * FROM CONFIGURATIONITEM WHERE TASKID=272)
Begin
	PRINT '**** RFC59306 CONFIGURATIONITEM WHERE TASKID=272 already exists'
	PRINT ''		
End
Else
Begin
	PRINT '**** RFC59306 Inserting CONFIGURATIONITEM WHERE TASKID=272 and TITLE = "Maintain Data Items"'
	INSERT INTO CONFIGURATIONITEM(TASKID,TITLE,DESCRIPTION,URL) 
	VALUES(272,'Maintain Data Items','Create, update or delete Data Items.','/apps/#/configuration/general/dataitems')		
	PRINT '**** RFC59306 Data successfully inserted in CONFIGURATIONITEM table.'
	PRINT ''
End
go

/**********************************************************************************************************/
/*** DR-46382 Grant Maintain Data Items Task to other licenses - ValidObject							***/
/**********************************************************************************************************/
/*** DR-46382 Grant Maintain Data Items Task to other licenses - Cases and Names						***/
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                            and OBJECTDATA = '72 122')
    BEGIN
        PRINT '**** DR-46382 Adding data VALIDOBJECT.OBJECTDATA = 72 122'
	declare @validObject int
      	    Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
        INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '72 122')
        PRINT '**** DR-46382 Data successfully added to VALIDOBJECT table.'
	PRINT ''
    END
ELSE
    PRINT '**** DR-46382 VALIDOBJECT.OBJECTDATA = 72 122 already exists'
    PRINT ''
go
/*** DR-46382 Grant Maintain Data Items Task to other licenses - E-filing								***/
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                            and OBJECTDATA = '72 222')
    BEGIN
        PRINT '**** DR-46382 Adding data VALIDOBJECT.OBJECTDATA = 72 222'
	declare @validObject int
      	    Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
        INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '72 222')
        PRINT '**** DR-46382 Data successfully added to VALIDOBJECT table.'
	PRINT ''
    END
ELSE
    PRINT '**** DR-46382 VALIDOBJECT.OBJECTDATA = 72 222 already exists'
    PRINT ''
go
/*** DR-46382 Grant Maintain Data Items Task to other licenses - Administrator WorkBench				***/
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                            and OBJECTDATA = '72 722')
    BEGIN
        PRINT '**** DR-46382 Adding data VALIDOBJECT.OBJECTDATA = 72 722'
	declare @validObject int
      	    Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
        INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '72 722')
        PRINT '**** DR-46382 Data successfully added to VALIDOBJECT table.'
	PRINT ''
    END
ELSE
    PRINT '**** DR-46382 VALIDOBJECT.OBJECTDATA = 72 722 already exists'
    PRINT ''
go
/*** DR-46382 Grant Maintain Data Items Task to other licenses - Integration E-filing Module			***/
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                            and OBJECTDATA = '72 423')
    BEGIN
        PRINT '**** DR-46382 Adding data VALIDOBJECT.OBJECTDATA = 72 423'
	declare @validObject int
      	    Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
        INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '72 423')
        PRINT '**** DR-46382 Data successfully added to VALIDOBJECT table.'
	PRINT ''
    END
ELSE
    PRINT '**** DR-46382 VALIDOBJECT.OBJECTDATA = 72 423 already exists'
    PRINT ''
go

