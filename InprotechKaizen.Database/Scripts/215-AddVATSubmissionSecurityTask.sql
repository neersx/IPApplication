    	/**********************************************************************************************************/
    	/*** DR-44835 HMRC VAT Submission - Feature Category						***/
	/**********************************************************************************************************/

	If NOT exists (select * from TABLECODES WHERE TABLECODE=9825)
        	BEGIN
         	 PRINT '**** DR-44835 Adding data TABLECODES.TABLECODE = 9825'
		 INSERT INTO TABLECODES (TABLECODE, TABLETYPE, [DESCRIPTION], USERCODE)
		 VALUES (9825, 98, N'Financial Management',null)
        	 PRINT '**** DR-44835 Data successfully added to TABLECODES table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-44835 TABLECODES.TABLECODE = 9825 already exists'
         	PRINT ''
    	go

    	/**********************************************************************************************************/
    	/*** DR-44835 HMRC VAT Submission - Feature						***/
	/**********************************************************************************************************/

	IF NOT exists (select * from FEATURE where FEATUREID = 79)
		begin
		PRINT '**** DR-44835 Inserting FEATURE.FEATUREID = 79'
		INSERT INTO FEATURE (FEATUREID, FEATURENAME, CATEGORYID, ISEXTERNAL, ISINTERNAL)
		VALUES (79, N'General Ledger', 9825, 0, 1)
		PRINT '**** DR-44835 Data has been successfully added to FEATURE table.'
		PRINT ''
		END
	ELSE
		PRINT '**** DR-44835 FEATURE.FEATUREID = 79 already exists.'
		PRINT ''
 	go

    	/**********************************************************************************************************/
    	/*** DR-44835 HMRC VAT Submission - Task						***/
	/**********************************************************************************************************/

	If NOT exists (select * from TASK where TASKID = 280)
        	BEGIN
         	 PRINT '**** DR-44835 Adding data TASK.TASKID = 280'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (280, N'Submit HMRC VAT Returns',N'Review and Submit VAT returns via HMRC online service')
        	 PRINT '**** DR-44835 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-44835 TASK.TASKID = 280 already exists'
         	PRINT ''
    	go

    	/**********************************************************************************************************/
    	/*** DR-44835 HMRC VAT Submission - FeatureTask						***/
	/**********************************************************************************************************/

	IF NOT exists (select * from FEATURETASK where FEATUREID = 79 AND TASKID = 280)
		begin
		PRINT '**** DR-44835 Inserting FEATURETASK.FEATUREID = 79, TASKID = 280'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (79, 280)
		PRINT '**** DR-44835 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** DR-44835 FEATURETASK.FEATUREID = 79, TASKID = 280 already exists.'
		PRINT ''
 	go

    	/**********************************************************************************************************/
    	/*** DR-44835 HMRC VAT Submission - Permission Definition						***/
	/**********************************************************************************************************/

	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 280
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** DR-44835 Adding TASK definition data PERMISSIONS.OBJECTKEY = 280'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 280, NULL, NULL, NULL, 32, 0)
        	 PRINT '**** DR-44835 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** DR-44835 TASK definition data PERMISSIONS.OBJECTKEY = 280 already exists'
		 PRINT ''
         	END
    	go

    	/**********************************************************************************************************/
    	/*** DR-44835 HMRC VAT Submission - ValidObject								***/
	/**********************************************************************************************************/

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82 001')
        	BEGIN
         	 PRINT '**** DR-44835 Adding data VALIDOBJECT.OBJECTDATA = 82 001'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82 001')
        	 PRINT '**** DR-44835 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-44835 VALIDOBJECT.OBJECTDATA = 82 001 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82 103')
        	BEGIN
         	 PRINT '**** DR-44835 Adding data VALIDOBJECT.OBJECTDATA = 82 103'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82 103')
        	 PRINT '**** DR-44835 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-44835 VALIDOBJECT.OBJECTDATA = 82 103 already exists'
         	PRINT ''
    	go

