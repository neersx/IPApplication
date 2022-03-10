
/*** RFC45828 Provide ability to view or maintain Site Controls based on task security - Task		***/

If NOT exists (select * from TASK where TASKID = 245)
BEGIN
	PRINT '**** RFC45828 Adding data TASK.TASKID = 245'
	INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
	VALUES (245, N'Maintain Site Controls',N'Allows maintenance of Site Controls')
	PRINT '**** RFC45828 Data successfully added to TASK table.'
	PRINT ''
END
ELSE
BEGIN
	PRINT '**** RFC45828 TASK.TASKID = 245 already exists'
	PRINT ''
END
go


/*** RFC45828 Provide ability to view or maintain Site Controls based on task security - FeatureTask	***/

IF NOT exists (select * from FEATURETASK where FEATUREID = 51 AND TASKID = 245)
BEGIN
	PRINT '**** RFC45828 Inserting FEATURETASK.FEATUREID = 51, TASKID = 245'
	INSERT INTO FEATURETASK (FEATUREID, TASKID)
	VALUES (51, 245)
	PRINT '**** RFC45828 Data has been successfully added to FEATURETASK table.'
	PRINT ''
END
ELSE
BEGIN
	PRINT '**** RFC45828 FEATURETASK.FEATUREID = 51, TASKID = 245 already exists.'
	PRINT ''
END
go


/*** RFC45828 Provide ability to view or maintain Site Controls based on task security - Permission Definition ***/

If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
			and OBJECTINTEGERKEY = 245
			and LEVELTABLE is null
			and LEVELKEY is null)
BEGIN
	PRINT '**** RFC45828 Adding TASK definition data PERMISSIONS.OBJECTKEY = 245'
	INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
	VALUES ('TASK', 245, NULL, NULL, NULL, 34, 0)
	PRINT '**** RFC45828 Data successfully added to PERMISSIONS table.'
	PRINT ''
END
ELSE
BEGIN
	PRINT '**** RFC45828 TASK definition data PERMISSIONS.OBJECTKEY = 245 already exists'
	PRINT ''
END
go


/*** RFC45828 - ValidObject										***/

If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                          and OBJECTDATA = '42  52')
BEGIN
	PRINT '**** RFC45828 Adding data VALIDOBJECT.OBJECTDATA = 42  52'

	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
	
	INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '42  52')
	PRINT '**** RFC45828 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
BEGIN
 	PRINT '**** RFC45828 VALIDOBJECT.OBJECTDATA = 42  52 already exists'
 	PRINT ''
END
go
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                          and OBJECTDATA = '42 952')
BEGIN
	PRINT '**** RFC45828 Adding data VALIDOBJECT.OBJECTDATA = 42 952'
	
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
	
	INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	VALUES (@validObject, 20, '42 952')
	PRINT '**** RFC45828 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
BEGIN
 	PRINT '**** RFC45828 VALIDOBJECT.OBJECTDATA = 42 952 already exists'
 	PRINT ''
END
go


/**********************************************************************************************************/
/*** DR-18965 Maintain Site Controls permission missing from some licences - Task						***/
/*** ValidObject																						***/
/**********************************************************************************************************/
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                and OBJECTDATA = '42 152')
        BEGIN
         	PRINT '**** DR-18965 Adding data VALIDOBJECT.OBJECTDATA = 42 152'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '42 152')
        	PRINT '**** DR-18965 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** DR-18965 VALIDOBJECT.OBJECTDATA = 42 152 already exists'
        PRINT ''
    go

/*** RFC45830 Maintain Site Control - ConfigurationItem						***/

If exists (SELECT * FROM CONFIGURATIONITEM WHERE TASKID=245)
Begin
	PRINT '**** RFC45830 CONFIGURATIONITEM WHERE TASKID=245 already exists'
	PRINT ''		
End
Else
Begin
	PRINT '**** RFC45830 Inserting CONFIGURATIONITEM WHERE TASKID=245 and TITLE = "Maintain Site Controls"'
	INSERT INTO CONFIGURATIONITEM(TASKID,TITLE,DESCRIPTION,URL) 
	VALUES(245,'Maintain Site Controls','Maintain Site Controls for the firm.','/apps/#/configuration/general/sitecontrols')		
	PRINT '**** RFC45830 Data successfully inserted in CONFIGURATIONITEM table.'
	PRINT ''
End
go