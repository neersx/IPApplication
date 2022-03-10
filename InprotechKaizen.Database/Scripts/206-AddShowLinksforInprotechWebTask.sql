
/**********************************************************************************************************/
/*** DR-44034 Link to Inprotech available based on security task - Task						***/
/**********************************************************************************************************/

	If NOT exists (select * from TASK where TASKID = 279)
        	BEGIN
         	 PRINT '**** DR-44034 Adding data TASK.TASKID = 279'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (279, N'Show Links for Inprotech Web',N'Controls visibility of links to Inprotech Web pages from the New Portal and Case View')
        	 PRINT '**** DR-44034 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-44034 TASK.TASKID = 279 already exists'
         	PRINT ''
    	go


/**********************************************************************************************************/
/*** DR-44034 Link to Inprotech available based on security task - FeatureTask						***/
/**********************************************************************************************************/

	IF NOT exists (select * from FEATURETASK where FEATUREID = 21 AND TASKID = 279)
		begin
		PRINT '**** DR-44034 Inserting FEATURETASK.FEATUREID = 21, TASKID = 279'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (21, 279)
		PRINT '**** DR-44034 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** DR-44034 FEATURETASK.FEATUREID = 21, TASKID = 279 already exists.'
		PRINT ''
 	go

/**********************************************************************************************************/
/*** DR-44034 Link to Inprotech available based on security task - Permission Definition						***/
/**********************************************************************************************************/

	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 279
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** DR-44034 Adding TASK definition data PERMISSIONS.OBJECTKEY = 279'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 279, NULL, NULL, NULL, 32, 0)
        	 PRINT '**** DR-44034 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** DR-44034 TASK definition data PERMISSIONS.OBJECTKEY = 279 already exists'
		 PRINT ''
         	END
    	go

/**********************************************************************************************************/
/*** DR-44034 Link to Inprotech available based on security task - Task Permissions						***/
/**********************************************************************************************************/

	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 279
				and LEVELTABLE = 'ROLE'
				and LEVELKEY = -21)
        	BEGIN
         	 PRINT '**** DR-44034 Adding TASK data PERMISSIONS.OBJECTKEY = 279'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 279, NULL, 'ROLE', -21, 32, 0)
        	 PRINT '**** DR-44034 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** DR-44034 TASK data PERMISSIONS.OBJECTKEY = 279 already exists'
		 PRINT ''
         	END
    	go

/**********************************************************************************************************/
/*** DR-44034 - ValidObject								***/
/**********************************************************************************************************/

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '72  92')
        	BEGIN
         	 PRINT '**** DR-44034 Adding data VALIDOBJECT.OBJECTDATA = 72  92'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '72  92')
        	 PRINT '**** DR-44034 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-44034 VALIDOBJECT.OBJECTDATA = 72  92 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '72 992')
        	BEGIN
         	 PRINT '**** DR-44034 Adding data VALIDOBJECT.OBJECTDATA = 72 992'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '72 992')
        	 PRINT '**** DR-44034 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-44034 VALIDOBJECT.OBJECTDATA = 72 992 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '72 791')
        	BEGIN
         	 PRINT '**** DR-44034 Adding data VALIDOBJECT.OBJECTDATA = 72 791'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '72 791')
        	 PRINT '**** DR-44034 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-44034 VALIDOBJECT.OBJECTDATA = 72 791 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '72 393')
        	BEGIN
         	 PRINT '**** DR-44034 Adding data VALIDOBJECT.OBJECTDATA = 72 393'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '72 393')
        	 PRINT '**** DR-44034 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-44034 VALIDOBJECT.OBJECTDATA = 72 393 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '72 192')
        	BEGIN
         	 PRINT '**** DR-44034 Adding data VALIDOBJECT.OBJECTDATA = 72 192'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '72 192')
        	 PRINT '**** DR-44034 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-44034 VALIDOBJECT.OBJECTDATA = 72 192 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '72 891')
        	BEGIN
         	 PRINT '**** DR-44034 Adding data VALIDOBJECT.OBJECTDATA = 72 891'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '72 891')
        	 PRINT '**** DR-44034 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-44034 VALIDOBJECT.OBJECTDATA = 72 891 already exists'
         	PRINT ''
    	go
