/**************************************************************/
/*** DR-69247 Add Maintain Prior Art Attachments - Task		***/
/**************************************************************/
If NOT exists (select * from TASK where TASKID = 290)
BEGIN
	PRINT '**** DR-69247 Adding data TASK.TASKID = 290'
		INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		VALUES (290, N'Maintain Prior Art Attachments',N'Maintain Prior Art Attachments')
	PRINT '**** DR-69247 Data successfully added to TASK table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-69247 TASK.TASKID = 290 already exists'
	PRINT ''
go


/**************************************************************************************/
/*** DR-69247 Add Maintain Prior Art Attachments - FeatureTask						***/
/**************************************************************************************/
IF NOT exists (select * from FEATURETASK where FEATUREID = 68 AND TASKID = 290)
BEGIN
	PRINT '**** DR-69247 Inserting FEATURETASK.FEATUREID = 68, TASKID = 290'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (68, 290)
	PRINT '**** DR-69247 Data has been successfully added to FEATURETASK table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-69247 FEATURETASK.FEATUREID = 68, TASKID = 290 already exists.'
	PRINT ''
go


/******************************************************************************************/
/*** DR-69247 Add Maintain Prior Art Attachments - Permission Definition				***/
/******************************************************************************************/
If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 290
				and LEVELTABLE is null
				and LEVELKEY is null)
BEGIN
	PRINT '**** DR-69247 Adding TASK definition data PERMISSIONS.OBJECTKEY = '
		INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		VALUES ('TASK', 290, NULL, NULL, NULL, 26, 0)
	PRINT '**** DR-69247 Data successfully added to PERMISSIONS table.'
	PRINT ''
END
ELSE
BEGIN
	PRINT '**** DR-69247 TASK definition data PERMISSIONS.OBJECTKEY =  already exists'
	PRINT ''
END
go


/**********************************/
/*** DR-69247 - ValidObject		***/
/**********************************/
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20 and OBJECTDATA = '92 102')
BEGIN
	PRINT '**** DR-69247 Adding data VALIDOBJECT.OBJECTDATA = 92 102'
		declare @validObject int
		Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
		INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '92 102')
	PRINT '**** DR-69247 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-69247 VALIDOBJECT.OBJECTDATA = 92 102 already exists'
	PRINT ''
go

If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20 and OBJECTDATA = '92 801')
BEGIN
	PRINT '**** DR-69247 Adding data VALIDOBJECT.OBJECTDATA = 92 801'
		declare @validObject int
		Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
		INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '92 801')
	PRINT '**** DR-69247 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-69247 VALIDOBJECT.OBJECTDATA = 92 801 already exists'
	PRINT ''
go

If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20 and OBJECTDATA = '92 802')
BEGIN
	PRINT '**** DR-69247 Adding data VALIDOBJECT.OBJECTDATA = 92 802'
		declare @validObject int
		Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
		INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '92 802')
	PRINT '**** DR-69247 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-69247 VALIDOBJECT.OBJECTDATA = 92 802 already exists'
	PRINT ''
go

If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20 and OBJECTDATA = '92 902')
BEGIN
	PRINT '**** DR-69247 Adding data VALIDOBJECT.OBJECTDATA = 92 902'
		declare @validObject int
		Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
		INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '92 902')
	PRINT '**** DR-69247 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-69247 VALIDOBJECT.OBJECTDATA = 92 902 already exists'
	PRINT ''
go


/**********************************************************************************************/
/*** DR-69247 grant permission to new maintain prior art attachments security task			***/
/**********************************************************************************************/
if not exists (select * 
	from permissions p1
	join permissions p2 on (p1.leveltable = p2.leveltable 
				and p1.levelkey = p2.levelkey 
				and p1.objecttable = p2.objecttable
				and p2.objectintegerkey = 290)
	where p1.leveltable = 'role'
	and p1.objectintegerkey = 186
	and p1.objecttable = 'task')
begin
	print '**** DR-69247 grant permission to new maintain prior art attachments security task ****'
		insert into permissions (objecttable, objectintegerkey, leveltable, levelkey, grantpermission, denypermission)
		select objecttable, 290 objectintegerkey, leveltable, levelkey, grantpermission, denypermission
		from permissions
		where leveltable = 'role'
		and objectintegerkey = 186 
		and objecttable = 'task'
	print '**** DR-69247 grant permission has been added for new maintain prior art attachments security task ****'
	print ''		
end
else
	print '**** DR-69247 no roles require the new maintain prior art attachments security task to be granted.'
	print ''
go