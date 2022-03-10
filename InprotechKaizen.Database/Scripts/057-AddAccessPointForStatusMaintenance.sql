/**********************************************************************************************************/
/*** RFC50853 Task for status maintenance - Task														***/
/**********************************************************************************************************/
If NOT exists (select * from TASK where TASKID = 246)
BEGIN
    PRINT '**** RFC50853 Adding data TASK.TASKID = 246'
	INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
	VALUES (246, N'Maintain Status',N'View, add, modify or delete Case and Renewal Status')
	PRINT '**** RFC50853 Data successfully added to TASK table.'
	PRINT ''
END
ELSE
	PRINT '**** RFC50853 TASK.TASKID = 246 already exists'
	PRINT ''
go


/**********************************************************************************************************/
/*** RFC50853 Task for status maintenance - FeatureTask													***/
/**********************************************************************************************************/
IF NOT exists (select * from FEATURETASK where FEATUREID = 51 AND TASKID = 246)
begin
	PRINT '**** RFC50853 Inserting FEATURETASK.FEATUREID = 51, TASKID = 246'
	INSERT INTO FEATURETASK (FEATUREID, TASKID)
	VALUES (51, 246)
	PRINT '**** RFC50853 Data has been successfully added to FEATURETASK table.'
	PRINT ''
END
ELSE
	PRINT '**** RFC50853 FEATURETASK.FEATUREID = 51, TASKID = 246 already exists.'
	PRINT ''
go

/**********************************************************************************************************/
/*** RFC50853 Task for status maintenance - Permission Definition					                    ***/
/**********************************************************************************************************/
If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
			and OBJECTINTEGERKEY = 246
			and LEVELTABLE is null
			and LEVELKEY is null)
BEGIN
	 PRINT '**** RFC50853 Adding TASK definition data PERMISSIONS.OBJECTKEY = 246'
	 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
	 VALUES ('TASK', 246, NULL, NULL, NULL, 58, 0)
	 PRINT '**** RFC50853 Data successfully added to PERMISSIONS table.'
     PRINT ''
END
ELSE
     BEGIN
	 PRINT '**** RFC50853 TASK definition data PERMISSIONS.OBJECTKEY = 246 already exists'
	 PRINT ''
END
go

/**********************************************************************************************************/
/*** RFC50853 - ValidObject								                                                ***/
/**********************************************************************************************************/
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
						  and OBJECTDATA = '42  62')
BEGIN
	PRINT '**** RFC50853 Adding data VALIDOBJECT.OBJECTDATA = 42  62'
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
 	INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '42  62')
    PRINT '**** RFC50853 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** RFC50853 VALIDOBJECT.OBJECTDATA = 42  62 already exists'
	PRINT ''
go

If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
						  and OBJECTDATA = '42 962')
BEGIN
    PRINT '**** RFC50853 Adding data VALIDOBJECT.OBJECTDATA = 42 962'
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
	INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '42 962')
	PRINT '**** RFC50853 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** RFC50853 VALIDOBJECT.OBJECTDATA = 42 962 already exists'
	PRINT ''
go


/**********************************************************************************************************/
/*** RFC50852 Maintain Status - ConfigurationItem						                            ***/
/**********************************************************************************************************/

If not exists (SELECT * FROM CONFIGURATIONITEM WHERE TASKID=246)
Begin
    PRINT '**** RFC50852 Inserting CONFIGURATIONITEM WHERE TASKID=246 and TITLE = "Maintain Status"'
	INSERT INTO CONFIGURATIONITEM(TASKID,TITLE,DESCRIPTION,URL) 
	VALUES(246,'Maintain Status','Create, update or delete Case and Renewal status for Cases.','/apps/#/configuration/general/status')		
	PRINT '**** RFC50852 Data successfully inserted in CONFIGURATIONITEM table.'
	PRINT ''			
End
Else
Begin
	PRINT '**** RFC50852 CONFIGURATIONITEM WHERE TASKID=246 already exists'
	PRINT ''
End
go

