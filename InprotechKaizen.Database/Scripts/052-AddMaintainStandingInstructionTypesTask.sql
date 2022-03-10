    /**********************************************************************************************************/
    /*** RFC50904 New Security Task - Maintain Standing Instructions Definition - Task						***/
	/**********************************************************************************************************/
	
	If NOT exists (select * from TASK where TASKID = 244)
        BEGIN
         	PRINT '**** RFC50904 Adding data TASK.TASKID = 244'
		INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		VALUES (244, N'Maintain Standing Instruction Definitions',N'Ability to create and modify the characteristics of Standing Instruction Definitions that are used throughout the system')
        	PRINT '**** RFC50904 Data successfully added to TASK table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC50904 TASK.TASKID = 244 already exists'
        PRINT ''
    go
		
    /**********************************************************************************************************/
    /*** RFC50904 New Security Task - Maintain Standing Instructions Definition - FeatureTask				***/
	/**********************************************************************************************************/
	
	IF NOT exists (select * from FEATURETASK where FEATUREID = 51 AND TASKID = 244)
		begin
		PRINT '**** RFC50904 Inserting FEATURETASK.FEATUREID = 51, TASKID = 244'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (51, 244)
		PRINT '**** RFC50904 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** RFC50904 FEATURETASK.FEATUREID = 51, TASKID = 244 already exists.'
		PRINT ''
 	go
	
    /**********************************************************************************************************/
    /*** RFC50904 New Security Task - Maintain Standing Instructions Definition - Permission Definition		***/
	/**********************************************************************************************************/
	
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 244
				and LEVELTABLE is null
				and LEVELKEY is null)
        BEGIN
         	PRINT '**** RFC50904 Adding TASK definition data PERMISSIONS.OBJECTKEY = 244'
		INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		VALUES ('TASK', 244, NULL, NULL, NULL, 32, 0)
        	PRINT '**** RFC50904 Data successfully added to PERMISSIONS table.'
		PRINT ''
        END
    ELSE
        BEGIN
         	PRINT '**** RFC50904 TASK definition data PERMISSIONS.OBJECTKEY = 244 already exists'
		PRINT ''
        END
    go

    /**********************************************************************************************************/
    /*** RFC50904 New Security Task - Maintain Standing Instructions Definition - ValidObject				***/
	/**********************************************************************************************************/
	
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '42  42')
        BEGIN
         	PRINT '**** RFC50904 Adding data VALIDOBJECT.OBJECTDATA = 42  42'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '42  42')
        	PRINT '**** RFC50904 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC50904 VALIDOBJECT.OBJECTDATA = 42  42 already exists'
        PRINT ''
    go

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '42 142')
        BEGIN
         	PRINT '**** RFC50904 Adding data VALIDOBJECT.OBJECTDATA = 42 142'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '42 142')
        	PRINT '**** RFC50904 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC50904 VALIDOBJECT.OBJECTDATA = 42 142 already exists'
        PRINT ''
    go

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '42 842')
        BEGIN
         	PRINT '**** RFC50904 Adding data VALIDOBJECT.OBJECTDATA = 42 842'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '42 842')
        	PRINT '**** RFC50904 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC50904 VALIDOBJECT.OBJECTDATA = 42 842 already exists'
        PRINT ''
    go

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '42 942')
        BEGIN
         	PRINT '**** RFC50904 Adding data VALIDOBJECT.OBJECTDATA = 42 942'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '42 942')
        	PRINT '**** RFC50904 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC50904 VALIDOBJECT.OBJECTDATA = 42 942 already exists'
        PRINT ''
    go

	/**********************************************************************************************************/
	/*** RFC50904 Configuration item for Maintain Standing Instuction Types									***/
	/**********************************************************************************************************/
	IF NOT EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 244)
	BEGIN
		PRINT '**** RFC50904 Adding data CONFIGURATIONITEM.TASKID = 244'
		INSERT INTO CONFIGURATIONITEM(TASKID, TITLE, DESCRIPTION, URL) 
		VALUES(
		244,
		N'Maintain Standing Instruction Definitions',
		N'Ability to create and modify the characteristics of Standing Instruction Definitions that are used throughout the system',
		N'/apps/#/configuration/general/standinginstructions')
	PRINT '**** RFC50904 Data successfully added to CONFIGURATIONITEM table.'
	PRINT ''
	END
	ELSE
		PRINT '**** RFC50904 CONFIGURATIONITEM.TASKID = 244 already exists'
		PRINT ''
	go