    	/*** DR-46174 Create new Security Task Save HMRC Settings - Task						***/

	If NOT exists (select * from TASK where TASKID = 281)
        	BEGIN
         	 PRINT '**** DR-46174 Adding data TASK.TASKID = 281'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (281, N'Store HMRC Settings',N'Store VAT API settings of the application in HMRC Developer Hub')
        	 PRINT '**** DR-46174 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-46174 TASK.TASKID = 281 already exists'
         	PRINT ''
    	go


    	/*** DR-46174 Create new Security Task Save HMRC Settings - FeatureTask						***/

	IF NOT exists (select * from FEATURETASK where FEATUREID = 79 AND TASKID = 281)
		begin
		PRINT '**** DR-46174 Inserting FEATURETASK.FEATUREID = 79, TASKID = 281'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (79, 281)
		PRINT '**** DR-46174 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** DR-46174 FEATURETASK.FEATUREID = 79, TASKID = 281 already exists.'
		PRINT ''
 	go


    	/*** DR-46174 Create new Security Task Save HMRC Settings - Permission Definition						***/

	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 281
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** DR-46174 Adding TASK definition data PERMISSIONS.OBJECTKEY = 281'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 281, NULL, NULL, NULL, 32, 0)
        	 PRINT '**** DR-46174 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** DR-46174 TASK definition data PERMISSIONS.OBJECTKEY = 281 already exists'
		 PRINT ''
         	END
    	go


    	/*** DR-46174 - ValidObject								***/

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82  12')
        	BEGIN
         	 PRINT '**** DR-46174 Adding data VALIDOBJECT.OBJECTDATA = 82  12'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82  12')
        	 PRINT '**** DR-46174 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-46174 VALIDOBJECT.OBJECTDATA = 82  12 already exists'
         	PRINT ''
    	go


	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82  19')
        	BEGIN
         	 PRINT '**** DR-46174 Adding data VALIDOBJECT.OBJECTDATA = 82  19'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82  19')
        	 PRINT '**** DR-46174 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-46174 VALIDOBJECT.OBJECTDATA = 82  19 already exists'
         	PRINT ''
    	go


	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82 011')
        	BEGIN
         	 PRINT '**** DR-46174 Adding data VALIDOBJECT.OBJECTDATA = 82 011'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82 011')
        	 PRINT '**** DR-46174 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-46174 VALIDOBJECT.OBJECTDATA = 82 011 already exists'
         	PRINT ''
    	go


	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82 111')
        	BEGIN
         	 PRINT '**** DR-46174 Adding data VALIDOBJECT.OBJECTDATA = 82 111'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82 111')
        	 PRINT '**** DR-46174 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-46174 VALIDOBJECT.OBJECTDATA = 82 111 already exists'
         	PRINT ''
    	go


	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82 211')
        	BEGIN
         	 PRINT '**** DR-46174 Adding data VALIDOBJECT.OBJECTDATA = 82 211'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82 211')
        	 PRINT '**** DR-46174 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-46174 VALIDOBJECT.OBJECTDATA = 82 211 already exists'
         	PRINT ''
    	go


	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82 112')
        	BEGIN
         	 PRINT '**** DR-46174 Adding data VALIDOBJECT.OBJECTDATA = 82 112'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82 112')
        	 PRINT '**** DR-46174 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-46174 VALIDOBJECT.OBJECTDATA = 82 112 already exists'
         	PRINT ''
    	go


	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82 712')
        	BEGIN
         	 PRINT '**** DR-46174 Adding data VALIDOBJECT.OBJECTDATA = 82 712'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82 712')
        	 PRINT '**** DR-46174 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-46174 VALIDOBJECT.OBJECTDATA = 82 712 already exists'
         	PRINT ''
    	go


	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82 812')
        	BEGIN
         	 PRINT '**** DR-46174 Adding data VALIDOBJECT.OBJECTDATA = 82 812'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82 812')
        	 PRINT '**** DR-46174 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-46174 VALIDOBJECT.OBJECTDATA = 82 812 already exists'
         	PRINT ''
    	go


	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82 912')
        	BEGIN
         	 PRINT '**** DR-46174 Adding data VALIDOBJECT.OBJECTDATA = 82 912'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82 912')
        	 PRINT '**** DR-46174 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-46174 VALIDOBJECT.OBJECTDATA = 82 912 already exists'
         	PRINT ''
    	go


	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82 113')
        	BEGIN
         	 PRINT '**** DR-46174 Adding data VALIDOBJECT.OBJECTDATA = 82 113'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82 113')
        	 PRINT '**** DR-46174 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-46174 VALIDOBJECT.OBJECTDATA = 82 113 already exists'
         	PRINT ''
    	go


	IF NOT EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 281)
	BEGIN
		PRINT '**** DR-46174 Adding data CONFIGURATIONITEM.TASKID = 281 ****'
		INSERT INTO CONFIGURATIONITEM(TASKID, TITLE, DESCRIPTION, URL)
		VALUES(281, N'HMRC Settings', N'Enter VAT API settings of the application in HMRC Developer Hub', N'/apps/#/accounting/vat/settings')
		PRINT '**** DR-46174 Data successfully added to CONFIGURATIONITEM table. ****'
		PRINT ''
	END
	ELSE
		PRINT '**** DR-46174 CONFIGURATIONITEM.TASKID = 225 already exists ****'
		PRINT ''
	go
