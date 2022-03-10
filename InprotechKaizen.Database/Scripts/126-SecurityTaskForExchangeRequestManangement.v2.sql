    /**********************************************************************************************************/
    /*** RFC59311 Access Exchange Integration page in Apps from Inprotech Web - Task			***/
	/**********************************************************************************************************/
	If NOT exists (select * from TASK where TASKID = 264)
        	BEGIN
         	 PRINT '**** RFC59311 Adding data TASK.TASKID = 264'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (264, N'Exchange Integration Administration',N'Configure Exchange Integration and manage the Exchange Request queue')
        	 PRINT '**** RFC59311 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC59311 TASK.TASKID = 264 already exists'
         	PRINT ''
    	go

	/**********************************************************************************************************/
	/*** RFC59311 Exchange Integration - Feature						***/
	/**********************************************************************************************************/
	IF NOT exists (select * from FEATURE where FEATUREID = 77)
		begin
		PRINT '**** RFC59311 Inserting FEATURE.FEATUREID = 77'
		INSERT INTO FEATURE (FEATUREID, FEATURENAME, CATEGORYID, ISEXTERNAL, ISINTERNAL)
		VALUES (77, N'Exchange Integration', 9824, 0, 1)
		PRINT '**** RFC59311 Data has been successfully added to FEATURE table.'
		PRINT ''
		END
	ELSE
		PRINT '**** RFC59311 FEATURE.FEATUREID = 77 already exists.'
		PRINT ''
	go

	/**********************************************************************************************************/
	/*** RFC59311 Access Exchange Integration page in Apps from Inprotech Web - FeatureTask			***/
	/**********************************************************************************************************/
	IF NOT exists (select * from FEATURETASK where FEATUREID = 77 AND TASKID = 264)
		begin
		PRINT '**** RFC59311 Inserting FEATURETASK.FEATUREID = 77, TASKID = 264'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (77, 264)
		PRINT '**** RFC59311 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** RFC59311 FEATURETASK.FEATUREID = 77, TASKID = 264 already exists.'
		PRINT ''
 	go

    /**********************************************************************************************************/
    /*** RFC59311 Access Exchange Integration page in Apps from Inprotech Web - FeatureTask			***/
	/**********************************************************************************************************/
	IF NOT exists (select * from FEATURETASK where FEATUREID = 66 AND TASKID = 264)
		begin
		PRINT '**** RFC59311 Inserting FEATURETASK.FEATUREID = 66, TASKID = 264'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (66, 264)
		PRINT '**** RFC59311 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** RFC59311 FEATURETASK.FEATUREID = 66, TASKID = 264 already exists.'
		PRINT ''
 	go

    /**********************************************************************************************************/
    /*** RFC59311 Access Exchange Integration page in Apps from Inprotech Web - Permission Definition	***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 264
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** RFC59311 Adding TASK definition data PERMISSIONS.OBJECTKEY = 264'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 264, NULL, NULL, NULL, 32, 0)
        	 PRINT '**** RFC59311 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** RFC59311 TASK definition data PERMISSIONS.OBJECTKEY = 264 already exists'
		 PRINT ''
         	END
    	go

    /**********************************************************************************************************/
    /*** RFC59311 - ValidObject										***/
	/**********************************************************************************************************/
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 841')
        	BEGIN
         	 PRINT '**** RFC59311 Adding data VALIDOBJECT.OBJECTDATA = 62 841'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 841')
        	 PRINT '**** RFC59311 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC59311 VALIDOBJECT.OBJECTDATA = 62 841 already exists'
         	PRINT ''
    	go

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 042')
        	BEGIN
         	 PRINT '**** RFC59311 Adding data VALIDOBJECT.OBJECTDATA = 62 042'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 042')
        	 PRINT '**** RFC59311 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC59311 VALIDOBJECT.OBJECTDATA = 62 042 already exists'
         	PRINT ''
    	go

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 142')
        	BEGIN
         	 PRINT '**** RFC59311 Adding data VALIDOBJECT.OBJECTDATA = 62 142'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 142')
        	 PRINT '**** RFC59311 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC59311 VALIDOBJECT.OBJECTDATA = 62 142 already exists'
         	PRINT ''
    	go

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 542')
        	BEGIN
         	 PRINT '**** RFC59311 Adding data VALIDOBJECT.OBJECTDATA = 62 542'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 542')
        	 PRINT '**** RFC59311 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC59311 VALIDOBJECT.OBJECTDATA = 62 542 already exists'
         	PRINT ''
    	go
    	
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 942')
        	BEGIN
         	 PRINT '**** RFC59311 Adding data VALIDOBJECT.OBJECTDATA = 62 942'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 942')
        	 PRINT '**** RFC59311 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC59311 VALIDOBJECT.OBJECTDATA = 62 942 already exists'
         	PRINT ''
    	go
    	
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 243')
        	BEGIN
         	 PRINT '**** RFC59311 Adding data VALIDOBJECT.OBJECTDATA = 62 243'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 243')
        	 PRINT '**** RFC59311 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC59311 VALIDOBJECT.OBJECTDATA = 62 243 already exists'
         	PRINT ''
    	go
    	
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 240')
        	BEGIN
         	 PRINT '**** RFC59311 Adding data VALIDOBJECT.OBJECTDATA = 62 240'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '62 240')
        	 PRINT '**** RFC59311 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC59311 VALIDOBJECT.OBJECTDATA = 62 240 already exists'
         	PRINT ''
    	go      	


    /**********************************************************************************************************/
	/*** DR-68357 - ValidObject                                                                    ***/
	/**********************************************************************************************************/


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '5 712')
	begin
		print '**** DR-68357 Adding data VALIDOBJECT.OBJECTDATA = 5 712'

		declare @validObject int
		Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT

		insert into VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		values (@validObject, 20, '5 712')

       print '**** DR-68357 Data successfully added to VALIDOBJECT table.'
		print ''
	end
	else
		print '**** DR-68357 VALIDOBJECT.OBJECTDATA = 5 712 already exists'
	print ''
	go

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '5 812')
	begin
		print '**** DR-68357 Adding data VALIDOBJECT.OBJECTDATA = 5 812'

		declare @validObject int
		Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT

		insert into VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		values (@validObject, 20, '5 812')

       print '**** DR-68357 Data successfully added to VALIDOBJECT table.'
		print ''
	end
	else
		print '**** DR-68357 VALIDOBJECT.OBJECTDATA = 5 812 already exists'
	print ''
	go

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 742')
	begin
		print '**** DR-68357 Adding data VALIDOBJECT.OBJECTDATA = 62 742'

		declare @validObject int
		Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT

		insert into VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		values (@validObject, 20, '62 742')

       print '**** DR-68357 Data successfully added to VALIDOBJECT table.'
		print ''
	end
	else
		print '**** DR-68357 VALIDOBJECT.OBJECTDATA = 62 742 already exists'
	print ''
	go

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '62 842')
	begin
		print '**** DR-68357 Adding data VALIDOBJECT.OBJECTDATA = 62 842'

		declare @validObject int
		Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT

		insert into VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		values (@validObject, 20, '62 842')

       print '**** DR-68357 Data successfully added to VALIDOBJECT table.'
		print ''
	end
	else
		print '**** DR-68357 VALIDOBJECT.OBJECTDATA = 62 842 already exists'
	print ''
	go