
  	/*** DR-60395 Create Configure Reporting Services Integration Security Task - Feature						***/
	IF NOT exists (select * from FEATURE where FEATUREID = 80)
	begin
		print '**** DR-60395 Inserting FEATURE.FEATUREID = 80'

		insert into FEATURE (FEATUREID, FEATURENAME, CATEGORYID, ISEXTERNAL, ISINTERNAL)
		values (80, N'Reporting Services Integration', 9804, 0, 1)
		
		print '**** DR-60395 Data has been successfully added to FEATURE table.'
		print ''
	end
	else
		print '**** DR-60395 FEATURE.FEATUREID = 80 already exists.'
	print ''
 	go

    /*** DR-60395 Create Configure Reporting Services Integration Security Task - Task						***/
	If NOT exists (select * from TASK where TASKID = 283)
	begin
		print '**** DR-60395 Adding data TASK.TASKID = 283'

		insert into TASK (TASKID, TASKNAME, DESCRIPTION)
		values (283, N'Configure Reporting Services Integration',N'Ability to configure settings to enable integration with Reporting Services.')

		print '**** DR-60395 Data successfully added to TASK table.'
		print ''
	end
	else
		print '**** DR-60395 TASK.TASKID = 283 already exists'
	print ''
	go

   	/*** DR-60395 Create Configure Reporting Services Integration Security Task - FeatureTask						***/
	IF NOT exists (select * from FEATURETASK where FEATUREID = 80 AND TASKID = 283)
	begin
		print '**** DR-60395 Inserting FEATURETASK.FEATUREID = 80, TASKID = 283'

		insert into FEATURETASK (FEATUREID, TASKID)
		values (80, 283)
		print '**** DR-60395 Data has been successfully added to FEATURETASK table.'
		print ''
	end
	else
		print '**** DR-60395 FEATURETASK.FEATUREID = 80, TASKID = 283 already exists.'
	print ''
 	go
	
   	/*** DR-60395 Create Configure Reporting Services Integration Security Task - Permission Definition						***/
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
					and OBJECTINTEGERKEY = 283
					and LEVELTABLE is null
					and LEVELKEY is null)
	begin
		print '**** DR-60395 Adding TASK definition data PERMISSIONS.OBJECTKEY = 283'

		insert	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		values ('TASK', 283, NULL, NULL, NULL, 32, 0)

		print '**** DR-60395 Data successfully added to PERMISSIONS table.'
		print ''
	end
	else
	begin
		print '**** DR-60395 TASK definition data PERMISSIONS.OBJECTKEY = 283 already exists'
		print ''
	end
	go
			   		 
   	/*** DR-60395 Create Configure Reporting Services Integration Security Task - Task Permissions						***/
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
					and OBJECTINTEGERKEY = 283
					and LEVELTABLE = 'ROLE'
					and LEVELKEY = -1)
	begin
		print '**** DR-60395 Adding TASK data PERMISSIONS.OBJECTKEY = 283'

		insert	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		values ('TASK', 283, NULL, 'ROLE', -1, 32, 0)

		print '**** DR-60395 Data successfully added to PERMISSIONS table.'
		print ''
	end
	else
	begin
		print '**** DR-60395 TASK data PERMISSIONS.OBJECTKEY = 283 already exists'
		print ''
	end
	go
		
	/*** DR-60395 - ValidObject								***/
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82 831')
	begin
		print '**** DR-60395 Adding data VALIDOBJECT.OBJECTDATA = 82 831'

		declare @validObject int
		Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT

		insert into VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		values (@validObject, 20, '82 831')

       print '**** DR-60395 Data successfully added to VALIDOBJECT table.'
		print ''
	end
	else
		print '**** DR-60395 VALIDOBJECT.OBJECTDATA = 82 831 already exists'
	print ''
	go

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82 132')
	begin
		print '**** DR-60395 Adding data VALIDOBJECT.OBJECTDATA = 82 132'

		declare @validObject int
		Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT

		insert into VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		values (@validObject, 20, '82 132')

       print '**** DR-60395 Data successfully added to VALIDOBJECT table.'
		print ''
	end
	else
		print '**** DR-60395 VALIDOBJECT.OBJECTDATA = 82 132 already exists'
	print ''
	go

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82 732')
	begin
		print '**** DR-60395 Adding data VALIDOBJECT.OBJECTDATA = 82 732'

		declare @validObject int
		Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT

		insert into VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		values (@validObject, 20, '82 732')

       print '**** DR-60395 Data successfully added to VALIDOBJECT table.'
		print ''
	end
	else
		print '**** DR-60395 VALIDOBJECT.OBJECTDATA = 82 732 already exists'
	print ''
	go

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82 832')
	begin
		print '**** DR-60395 Adding data VALIDOBJECT.OBJECTDATA = 82 832'

		declare @validObject int
		Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT

		insert into VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		values (@validObject, 20, '82 832')

       print '**** DR-60395 Data successfully added to VALIDOBJECT table.'
		print ''
	end
	else
		print '**** DR-60395 VALIDOBJECT.OBJECTDATA = 82 832 already exists'
	print ''
	go

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82 932')
	begin
		print '**** DR-60395 Adding data VALIDOBJECT.OBJECTDATA = 82 932'

		declare @validObject int
		Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT

		insert into VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		values (@validObject, 20, '82 932')

       print '**** DR-60395 Data successfully added to VALIDOBJECT table.'
		print ''
	end
	else
		print '**** DR-60395 VALIDOBJECT.OBJECTDATA = 82 932 already exists'
	print ''
	go

		
	
    /**********************************************************************************************************/
		/*** DR-60394 Configuration item and component for - Reporting Services Integration Settings    ***/
    /**********************************************************************************************************/
    IF NOT EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 283)
	begin try
	begin transaction
		print '**** DR-60394 Adding data CONFIGURATIONITEM.TASKID = 283'
		insert into CONFIGURATIONITEM(TASKID, TITLE, DESCRIPTION, URL) values (
			283,
			N'Reporting Services Integration Settings', 
			N'Configure required settings for Reporting Services integration.', 
			N'/apps/#/configuration/reporting-settings')
        print '**** DR-60394 Data successfully added to CONFIGURATIONITEM table.'
        print ''

		insert CONFIGURATIONITEMCOMPONENTS (CONFIGITEMID, COMPONENTID)
			select CI.CONFIGITEMID, CO.COMPONENTID
				from CONFIGURATIONITEM CI
				join COMPONENTS CO on CO.COMPONENTNAME = 'Integration'
				where CI.TASKID = 283
		
		print '**** DR-60394 Data successfully added to CONFIGURATIONITEMCOMPONENTS table.'
        print ''
    commit transaction
	end try
	begin catch
		if @@trancount > 0
			rollback

		declare @ErrMsg nvarchar(4000), @ErrSeverity int
		select @ErrMsg = ERROR_MESSAGE(), @ErrSeverity = ERROR_SEVERITY()

		raiserror(@ErrMsg, @ErrSeverity, 1)
	end catch
	else
		print '**** DR-60394 CONFIGURATIONITEM.TASKID = 283 already exists'
	print ''
    go
