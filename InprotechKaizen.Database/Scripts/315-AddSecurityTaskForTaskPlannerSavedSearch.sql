	/****************************************************************************************************/
	/*** DR-66712 Create new security tasks for Task Planner Saved Searches - Task					 ***/
	/***************************************************************************************************/

		If NOT EXISTS (select * from TASK where TASKID = 288)
			BEGIN
				PRINT '**** DR-66712 Adding data TASK.TASKID = 288'
			INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
			VALUES (288, N'Maintain Task Planner Search', N'Create, update or delete task planner saved searches.')
			PRINT '**** DR-66712 Data successfully added to TASK table.'
			PRINT ''
			END
		ELSE
			PRINT '**** DR-66712 TASK.TASKID = 288 already exists'
			PRINT ''
		GO

	/********************************************************************************************************/
	/*** DR-66712 Create new security tasks for Task Planner Saved Searches - FeatureTask				 ***/
	/*******************************************************************************************************/
		IF NOT EXISTS (select * from FEATURETASK where FEATUREID = 81 AND TASKID = 288)
			begin
			PRINT '**** DR-66712 Inserting FEATURETASK.FEATUREID = 81, TASKID = 288'
			INSERT INTO FEATURETASK (FEATUREID, TASKID)
			VALUES (81, 288)
			PRINT '**** DR-66712 Data has been successfully added to FEATURETASK table.'
			PRINT ''
			END
		ELSE
			PRINT '**** DR-66712 FEATURETASK.FEATUREID = 81, TASKID = 288 already exists.'
			PRINT ''
		GO

	/**********************************************************************************************************/
	/*** DR-66712 Create new security tasks for Task Planner Saved Searches - Permission Definition						***/
	/**********************************************************************************************************/
		IF NOT EXISTS(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 288
				and LEVELTABLE is null
				and LEVELKEY is null)
			BEGIN
				PRINT '**** DR-66712 Adding TASK definition data PERMISSIONS.OBJECTKEY = 288'
			INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
			VALUES ('TASK', 288, NULL, NULL, NULL, 26, 0)
				PRINT '**** DR-66712 Data successfully added to PERMISSIONS table.'
			PRINT ''
			END
		ELSE
			BEGIN
				PRINT '**** DR-66712 TASK definition data PERMISSIONS.OBJECTKEY = 288 already exists'
			PRINT ''
			END
		GO
			   
		IF NOT EXISTS(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
			and OBJECTINTEGERKEY = 288
			and LEVELTABLE = 'ROLE'
			and LEVELKEY = -21)
		BEGIN
			PRINT '**** DR-66712 Adding TASK data PERMISSIONS.OBJECTKEY = 288'
			INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
			VALUES ('TASK', 288, NULL, 'ROLE', -21, 26, 0)
				PRINT '**** DR-66712 Data successfully added to PERMISSIONS table.'
			PRINT ''
			END
		ELSE
		BEGIN
			PRINT '**** DR-66712 TASK data PERMISSIONS.OBJECTKEY = 288 already exists'
			PRINT ''
		END
		GO
	/**********************************************************************************************************/
	/*** DR-66712 - ValidObject								***/
	/********************************************************************************************************/
		If NOT EXISTS (SELECT * FROM VALIDOBJECT WHERE TYPE = 20 and OBJECTDATA = '82  82')
			BEGIN
				PRINT '**** DR-66712 Adding data VALIDOBJECT.OBJECTDATA = 82  82'
				DECLARE @validObject int
      				Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
				INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
				VALUES (@validObject, 20, '82  82')
				PRINT '**** DR-66712 Data successfully added to VALIDOBJECT table.'
				PRINT ''
			END
		ELSE
			PRINT '**** DR-66712 VALIDOBJECT.OBJECTDATA = 82  82 already exists'
			PRINT ''
		go
		If NOT EXISTS (SELECT * FROM VALIDOBJECT WHERE TYPE = 20 and OBJECTDATA = '82 182')
			BEGIN
				PRINT '**** DR-66712 Adding data VALIDOBJECT.OBJECTDATA = 82 182'
				DECLARE @validObject int
      				Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
				INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
				VALUES (@validObject, 20, '82 182')
				PRINT '**** DR-66712 Data successfully added to VALIDOBJECT table.'
				PRINT ''
			END
		ELSE
			PRINT '**** DR-66712 VALIDOBJECT.OBJECTDATA = 82 182 already exists'
			PRINT ''
		GO
		If NOT EXISTS (SELECT * FROM VALIDOBJECT WHERE TYPE = 20 and OBJECTDATA = '82 982')
			BEGIN
				PRINT '**** DR-66712 Adding data VALIDOBJECT.OBJECTDATA = 82 982'
				DECLARE @validObject int
      				Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
				INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
				VALUES (@validObject, 20, '82 982')
				PRINT '**** DR-66712 Data successfully added to VALIDOBJECT table.'
				PRINT ''
			END
		ELSE
			PRINT '**** DR-66712 VALIDOBJECT.OBJECTDATA = 82 982 already exists'
			PRINT ''
		GO
		If NOT EXISTS (SELECT * FROM VALIDOBJECT WHERE TYPE = 20 and OBJECTDATA = '82 881')
			BEGIN
				PRINT '**** DR-66712 Adding data VALIDOBJECT.OBJECTDATA = 82 881'
				DECLARE @validObject int
      				Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
				INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
				VALUES (@validObject, 20, '82 881')
				PRINT '**** DR-66712 Data successfully added to VALIDOBJECT table.'
				PRINT ''
			END
		ELSE
			PRINT '**** DR-66712 VALIDOBJECT.OBJECTDATA = 82 881 already exists'
			PRINT ''
		GO