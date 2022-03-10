/*** DR-70778 Add 'Task Planner Search Column Maintenance' Security Task to Clerical Workbench and Professional Workbench licence models - Feature Module						***/

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82 142')
        	BEGIN
         	 PRINT '**** DR-70778 Adding data VALIDOBJECT.OBJECTDATA = 82 142'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82 142')
        	 PRINT '**** DR-70778 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-70778 VALIDOBJECT.OBJECTDATA = 82 142 already exists'
         	PRINT ''
    	go

	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '82 841')
        	BEGIN
         	 PRINT '**** DR-70778 Adding data VALIDOBJECT.OBJECTDATA = 82 841'
		 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '82 841')
        	 PRINT '**** DR-70778 Data successfully added to VALIDOBJECT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-70778 VALIDOBJECT.OBJECTDATA = 82 841 already exists'
         	PRINT ''
    	go
