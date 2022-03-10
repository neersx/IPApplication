
    /**********************************************************************************************************/
    /*** RFC52058 New Security Task - Maintain Valid Combinations - Task									***/
	/**********************************************************************************************************/

	If NOT exists (select * from TASK where TASKID = 253)
        	BEGIN
         	 PRINT '**** RFC52058 Adding data TASK.TASKID = 253'
		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (253, N'Maintain Valid Combinations',N'View, add or edit Valid Combinations')
        	 PRINT '**** RFC52058 Data successfully added to TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC52058 TASK.TASKID = 253 already exists'
         	PRINT ''
    	go



    /**********************************************************************************************************/
    /*** RFC52058 New Security Task - Maintain Valid Combinations - FeatureTask								***/
	/**********************************************************************************************************/

	IF NOT exists (select * from FEATURETASK where FEATUREID = 51 AND TASKID = 253)
		begin
		PRINT '**** RFC52058 Inserting FEATURETASK.FEATUREID = 51, TASKID = 253'
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (51, 253)
		PRINT '**** RFC52058 Data has been successfully added to FEATURETASK table.'
		PRINT ''
		END
	ELSE
		PRINT '**** RFC52058 FEATURETASK.FEATUREID = 51, TASKID = 253 already exists.'
		PRINT ''
 	go


    /**********************************************************************************************************/
    /*** RFC52058 New Security Task - Maintain Valid Combinations - Permission Definition					***/
	/**********************************************************************************************************/

	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 253
				and LEVELTABLE is null
				and LEVELKEY is null)
        	BEGIN
         	 PRINT '**** RFC52058 Adding TASK definition data PERMISSIONS.OBJECTKEY = 253'
		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 253, NULL, NULL, NULL, 32, 0)
        	 PRINT '**** RFC52058 Data successfully added to PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** RFC52058 TASK definition data PERMISSIONS.OBJECTKEY = 253 already exists'
		 PRINT ''
         	END
    	go



    /**********************************************************************************************************/
    /*** RFC52058 - ValidObject																				***/
	/**********************************************************************************************************/

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52  32')
        	BEGIN
         	 PRINT '**** RFC52058 Adding data VALIDOBJECT.OBJECTDATA = 52  32'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52  32')
        	 PRINT '**** RFC52058 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC52058 VALIDOBJECT.OBJECTDATA = 52  32 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 132')
        	BEGIN
         	 PRINT '**** RFC52058 Adding data VALIDOBJECT.OBJECTDATA = 52 132'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 132')
        	 PRINT '**** RFC52058 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC52058 VALIDOBJECT.OBJECTDATA = 52 132 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 832')
        	BEGIN
         	 PRINT '**** RFC52058 Adding data VALIDOBJECT.OBJECTDATA = 52 832'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 832')
        	 PRINT '**** RFC52058 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC52058 VALIDOBJECT.OBJECTDATA = 52 832 already exists'
         	PRINT ''
    	go
	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '52 932')
        	BEGIN
         	 PRINT '**** RFC52058 Adding data VALIDOBJECT.OBJECTDATA = 52 932'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '52 932')
        	 PRINT '**** RFC52058 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC52058 VALIDOBJECT.OBJECTDATA = 52 932 already exists'
         	PRINT ''
    	go

	/**********************************************************************************************************/
	/*** RFC52058 Maintain Status - ConfigurationItem														***/
	/**********************************************************************************************************/

	If not exists (SELECT * FROM CONFIGURATIONITEM WHERE TASKID=253)
	Begin
		PRINT '**** RFC52058 Inserting CONFIGURATIONITEM WHERE TASKID=253 and TITLE = "Maintain Valid Combinations"'
		INSERT INTO CONFIGURATIONITEM(TASKID,TITLE,DESCRIPTION,URL) 
		VALUES(253,'Maintain Valid Combinations','View, add or edit Valid Combinations.','/apps/#/configuration/general/validcombination')		
		PRINT '**** RFC52058 Data successfully inserted in CONFIGURATIONITEM table.'
		PRINT ''			
	End
	Else
	Begin
		PRINT '**** RFC52058 CONFIGURATIONITEM WHERE TASKID=253 already exists'
		PRINT ''
	End
	go
