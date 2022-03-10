/**********************************************************************************************************/
    /*** DR-61388 Create Configure Attachments Integration Security Task - Task                                                                                              ***/
/**********************************************************************************************************/
If NOT exists (select * from TASK where TASKID = 285)
begin
    print '**** DR-61388 Adding data TASK.TASKID = 285'

    insert into TASK (TASKID, TASKNAME, DESCRIPTION)
    values (285, N'Configure Attachments Service',N'Ability to configure Attachments Service to enable physical files that are attached as references to Case,Name and Contact Activity.')

    print '**** DR-61388 Data successfully added to TASK table.'
    print ''
end
else
    print '**** DR-61388 TASK.TASKID = 285 already exists'
print ''
go

/**********************************************************************************************************/
    /*** DR-61388 Create Configure Attachments Integration Security Task - FeatureTask                                                                                              ***/
/**********************************************************************************************************/
IF NOT exists (select * from FEATURETASK where FEATUREID = 51 AND TASKID = 285)
begin
    print '**** DR-61388 Inserting FEATURETASK.FEATUREID = 51, TASKID = 285'

    insert into FEATURETASK (FEATUREID, TASKID)
    values (51, 285)

    print '**** DR-61388 Data has been successfully added to FEATURETASK table.'
    print ''
end
else
    print '**** DR-61388 FEATURETASK.FEATUREID = 51, TASKID = 285 already exists.'
print ''
go

/**********************************************************************************************************/
    /*** DR-61388 Create Configure Attachments Integration Security Task - Permission Definition                                                                                            ***/
/**********************************************************************************************************/
If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
                                                and OBJECTINTEGERKEY = 285
                                                and LEVELTABLE is null
                                                and LEVELKEY is null)
begin
    print '**** DR-61388 Adding TASK definition data PERMISSIONS.OBJECTKEY = 285'

    insert PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
    values ('TASK', 285, NULL, NULL, NULL, 32, 0)

    print '**** DR-61388 Data successfully added to PERMISSIONS table.'
    print ''
end
else
begin
    print '**** DR-61388 TASK definition data PERMISSIONS.OBJECTKEY = 285 already exists'
print ''
end

/**********************************************************************************************************/
/*** DR-61388 Create Configure Attachments Integration Security Task - Task Permissions                                                                                     ***/
/**********************************************************************************************************/
IF NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
                                                and OBJECTINTEGERKEY = 285
                                                and LEVELTABLE = 'ROLE'
                                                and LEVELKEY = -1)
begin
    print '**** DR-61388 Adding TASK data PERMISSIONS.OBJECTKEY = 285'
    insert PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
    values ('TASK', 285, NULL, 'ROLE', -1, 32, 0)
    print '**** DR-61388 Data successfully added to PERMISSIONS table.'
    print ''
end
else
begin
    print '**** DR-61388 TASK data PERMISSIONS.OBJECTKEY = 285 already exists'
    print ''
end
go

/**********************************************************************************************************/
    /*** DR-61388 - ValidObject                                                                                                                   ***/
/**********************************************************************************************************/
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20 and OBJECTDATA = '82 851')
begin
    print '**** DR-61388 Adding data VALIDOBJECT.OBJECTDATA = 82 851'

    declare @validObject int
    Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT

    insert into VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA) values (@validObject, 20, '82 851')
    
    print '**** DR-61388 Data successfully added to VALIDOBJECT table.'
print ''
end
else
    print '**** DR-61388 VALIDOBJECT.OBJECTDATA = 82 851 already exists'
print ''
go

If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                            and OBJECTDATA = '82 152')
begin
    print '**** DR-61388 Adding data VALIDOBJECT.OBJECTDATA = 82 152'

    declare @validObject int
    Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT

    insert into VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA) values (@validObject, 20, '82 152')

    print '**** DR-61388 Data successfully added to VALIDOBJECT table.'
print ''
end
else
    print '**** DR-61388 VALIDOBJECT.OBJECTDATA = 82 152 already exists'
print ''
go

If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                            and OBJECTDATA = '82 752')
begin
    print '**** DR-61388 Adding data VALIDOBJECT.OBJECTDATA = 82 752'

    declare @validObject int
    Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT

    insert into VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA) values (@validObject, 20, '82 752')

    print '**** DR-61388 Data successfully added to VALIDOBJECT table.'
print ''
end
else
    print '**** DR-61388 VALIDOBJECT.OBJECTDATA = 82 752 already exists'
    print ''
go

If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                            and OBJECTDATA = '82 852')
begin
    print '**** DR-61388 Adding data VALIDOBJECT.OBJECTDATA = 82 852'

    declare @validObject int
    Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT

    insert into VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA) values (@validObject, 20, '82 852')

    print '**** DR-61388 Data successfully added to VALIDOBJECT table.'
print ''
end
else
    print '**** DR-61388 VALIDOBJECT.OBJECTDATA = 82 852 already exists'
print ''
go

If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                            and OBJECTDATA = '82 952')
begin
    print '**** DR-61388 Adding data VALIDOBJECT.OBJECTDATA = 82 952'

    declare @validObject int
    Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
    
    insert into VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA) values (@validObject, 20, '82 952')

    print '**** DR-61388 Data successfully added to VALIDOBJECT table.'
    print ''
end
else
    print '**** DR-61388 VALIDOBJECT.OBJECTDATA = 82 952 already exists'
print ''
go


/**********************************************************************************************************/
	/*** DR-60394 Configuration item and component for - Attachments Integration Settings    ***/
/**********************************************************************************************************/
IF NOT EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 285)
BEGIN TRY
BEGIN TRANSACTION
    PRINT '**** DR-60394 Adding data CONFIGURATIONITEM.TASKID = 285'
	INSERT INTO CONFIGURATIONITEM(TASKID, TITLE, DESCRIPTION, URL) VALUES(
	285,
	N'Attachments Service Settings', 
	N'Configure required settings for Attachments Service.', 
	N'/apps/#/configuration/attachments')
    PRINT '**** DR-60394 Data successfully added to CONFIGURATIONITEM table.'
    PRINT ''

	INSERT CONFIGURATIONITEMCOMPONENTS (CONFIGITEMID, COMPONENTID)
		SELECT CI.CONFIGITEMID, CO.COMPONENTID
			FROM CONFIGURATIONITEM CI
			JOIN COMPONENTS CO on CO.COMPONENTNAME = 'Integration'
			WHERE CI.TASKID = 285
		
	PRINT '**** DR-60394 Data successfully added to CONFIGURATIONITEMCOMPONENTS table.'
    PRINT ''
COMMIT TRANSACTION
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK

	DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
	SELECT @ErrMsg = ERROR_MESSAGE(), @ErrSeverity = ERROR_SEVERITY()

	RAISERROR(@ErrMsg, @ErrSeverity, 1)
END CATCH
ELSE
    PRINT '**** DR-60394 CONFIGURATIONITEM.TASKID = 285 already exists'
    PRINT ''
go
