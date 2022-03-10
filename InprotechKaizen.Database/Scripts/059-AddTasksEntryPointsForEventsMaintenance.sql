/*** RFC51206 Security task to control Maintain Workflow Rules (DR-14460) - Task	***/

If NOT exists (select * from TASK where TASKID = 250)
        BEGIN
         	PRINT '**** RFC51206 Adding data TASK.TASKID = 250'
		INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		VALUES (250, N'Maintain Workflow Rules',N'Create, update or delete Workflow rules.')
        	PRINT '**** RFC51206 Data successfully added to TASK table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC51206 TASK.TASKID = 250 already exists'
        PRINT ''
    go


/*** RFC51206 Security task to control Maintain Workflow Rules (DR-14460) - FeatureTask	***/

IF NOT exists (select * from FEATURETASK where FEATUREID = 56 AND TASKID = 250)
	begin
	PRINT '**** RFC51206 Inserting FEATURETASK.FEATUREID = 56, TASKID = 250'
	INSERT INTO FEATURETASK (FEATUREID, TASKID)
	VALUES (56, 250)
	PRINT '**** RFC51206 Data has been successfully added to FEATURETASK table.'
	PRINT ''
	END
ELSE
	PRINT '**** RFC51206 FEATURETASK.FEATUREID = 56, TASKID = 250 already exists.'
	PRINT ''
go


/*** RFC51206 Security task to control Maintain Workflow Rules (DR-14460) - Permission Definition	***/

If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
			and OBJECTINTEGERKEY = 250
			and LEVELTABLE is null
			and LEVELKEY is null)
        BEGIN
         	PRINT '**** RFC51206 Adding TASK definition data PERMISSIONS.OBJECTKEY = 250'
		INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		VALUES ('TASK', 250, NULL, NULL, NULL, 32, 0)
        	PRINT '**** RFC51206 Data successfully added to PERMISSIONS table.'
		PRINT ''
        END
    ELSE
        BEGIN
         	PRINT '**** RFC51206 TASK definition data PERMISSIONS.OBJECTKEY = 250 already exists'
		PRINT ''
        END
    go


/*** RFC51206 Security task to control Maintain Workflow Rules (DR-14460) - ValidObject	***/

If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                and OBJECTDATA = '52 902')
        BEGIN
         	PRINT '**** RFC51206 Adding data VALIDOBJECT.OBJECTDATA = 52 902'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '52 902')
        	PRINT '**** RFC51206 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC51206 VALIDOBJECT.OBJECTDATA = 52 902 already exists'
        PRINT ''
    go
    	
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                and OBJECTDATA = '52  02')
        BEGIN
         	PRINT '**** RFC51206 Adding data VALIDOBJECT.OBJECTDATA = 52  02'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '52  02')
        	PRINT '**** RFC51206 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC51206 VALIDOBJECT.OBJECTDATA = 52  02 already exists'
        PRINT ''
    go


/*** RFC51206 Security task to control Maintain Protected Workflow Rules (DR-14460) - Task	***/

If NOT exists (select * from TASK where TASKID = 251)
        BEGIN
         	PRINT '**** RFC51206 Adding data TASK.TASKID = 251'
		INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		VALUES (251, N'Maintain Protected Workflow Rules',N'Create, update or delete protected Workflow rules.')
        	PRINT '**** RFC51206 Data successfully added to TASK table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC51206 TASK.TASKID = 251 already exists'
        PRINT ''
    go


/*** RFC51206 Security task to control Maintain Protected Workflow Rules (DR-14460) - FeatureTask	***/

IF NOT exists (select * from FEATURETASK where FEATUREID = 56 AND TASKID = 251)
	begin
	PRINT '**** RFC51206 Inserting FEATURETASK.FEATUREID = 56, TASKID = 251'
	INSERT INTO FEATURETASK (FEATUREID, TASKID)
	VALUES (56, 251)
	PRINT '**** RFC51206 Data has been successfully added to FEATURETASK table.'
	PRINT ''
	END
ELSE
	PRINT '**** RFC51206 FEATURETASK.FEATUREID = 56, TASKID = 251 already exists.'
	PRINT ''
go


/*** RFC51206 Security task to control Maintain Protected Workflow Rules (DR-14460) - Permission Definition	***/

If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
			and OBJECTINTEGERKEY = 251
			and LEVELTABLE is null
			and LEVELKEY is null)
        BEGIN
         	PRINT '**** RFC51206 Adding TASK definition data PERMISSIONS.OBJECTKEY = 251'
		INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		VALUES ('TASK', 251, NULL, NULL, NULL, 32, 0)
        	PRINT '**** RFC51206 Data successfully added to PERMISSIONS table.'
		PRINT ''
        END
    ELSE
        BEGIN
         	PRINT '**** RFC51206 TASK definition data PERMISSIONS.OBJECTKEY = 251 already exists'
		PRINT ''
        END
    go


/*** RFC51206 Security task to control Maintain Protected Workflow Rules (DR-14460) - ValidObject	***/

If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                and OBJECTDATA = '52 912')
        BEGIN
         	PRINT '**** RFC51206 Adding data VALIDOBJECT.OBJECTDATA = 52 912'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '52 912')
        	PRINT '**** RFC51206 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC51206 VALIDOBJECT.OBJECTDATA = 52 912 already exists'
        PRINT ''
    go

If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                and OBJECTDATA = '52  12')
        BEGIN
         	PRINT '**** RFC51206 Adding data VALIDOBJECT.OBJECTDATA = 52  12'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '52  12')
        	PRINT '**** RFC51206 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC51206 VALIDOBJECT.OBJECTDATA = 52  12 already exists'
        PRINT ''
    go


/*** RFC55999 Single entry point for Workflow search (DR-17049) - ConfigurationItemGroup	***/

IF NOT exists (select * FROM CONFIGURATIONITEMGROUP WHERE ID = 2)
Begin
	PRINT '**** RFC55999 Adding CONFIGURATIONITEMGROUP for Maintain Rules - Workflows'
	INSERT INTO CONFIGURATIONITEMGROUP (ID, TITLE, DESCRIPTION, URL)
	VALUES (2, 'Maintain Rules - Workflows', 'Create, update or delete Workflow rules for the firm.', '/apps/#/configuration/rules/workflows')
	PRINT '**** RFC55999 Data successfully added to CONFIGURATIONITEMGROUP table.'
	PRINT ''
End
Else
Begin	
	PRINT '**** RFC55999 CONFIGURATIONITEMGROUP Maintain Rules - Workflows already exists.'
	PRINT ''
End
go


/*** RFC45830 Security task to control Maintain Workflow Rules (DR-14460) - ConfigurationItem	***/

If exists (SELECT * FROM CONFIGURATIONITEM WHERE TASKID=250)
Begin
	PRINT '**** RFC51206 CONFIGURATIONITEM WHERE TASKID=250 and TITLE = "Maintain Rules - Workflows" already exists'
	PRINT ''		
End
Else
Begin
	PRINT '**** RFC51206 Inserting CONFIGURATIONITEM WHERE TASKID=250 and TITLE = "Maintain Rules - Workflows"'
	INSERT INTO CONFIGURATIONITEM(TASKID,TITLE,DESCRIPTION,GROUPID) 
	VALUES(250,'Maintain Rules - Workflows','Create, update or delete Workflow rules for the firm.',2)		
	PRINT '**** RFC51206 Data successfully inserted in CONFIGURATIONITEM table.'
	PRINT ''
End
go

	
/*** RFC45830 Security task to control Maintain Workflow Rules (DR-14460) - ConfigurationItem	***/

If exists (SELECT * FROM CONFIGURATIONITEM WHERE TASKID=251)
Begin
	PRINT '**** RFC51206 CONFIGURATIONITEM WHERE TASKID=251 and TITLE = "Maintain Protected Rules - Workflows" already exists'
	PRINT ''		
End
Else
Begin
	PRINT '**** RFC51206 Inserting CONFIGURATIONITEM WHERE TASKID=251 and TITLE = "Maintain Protected Rules - Workflows"'
	INSERT INTO CONFIGURATIONITEM(TASKID,TITLE,DESCRIPTION,GROUPID) 
	VALUES(251,'Maintain Protected Rules - Workflows','Create, update or delete protected Workflow rules for the firm.',2)
	PRINT '**** RFC51206 Data successfully inserted in CONFIGURATIONITEM table.'
	PRINT ''
End
go
