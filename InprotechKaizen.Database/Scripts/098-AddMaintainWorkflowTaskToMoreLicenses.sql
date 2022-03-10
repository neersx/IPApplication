
/*** RFC69526 Enable access to Maintain Workflow Rules tasks additional licenses ***/

If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                          and OBJECTDATA = '52 102')
	BEGIN
 	 PRINT '**** RFC69526 Adding data VALIDOBJECT.OBJECTDATA = 52 102'
	 declare @validObject int
         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
        INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	 VALUES (@validObject, 20, '52 102')
	 PRINT '**** RFC69526 Data successfully added to VALIDOBJECT table.'
	 PRINT ''
 	END
ELSE
 	PRINT '**** RFC69526 VALIDOBJECT.OBJECTDATA = 52 102 already exists'
 	PRINT ''
go
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                          and OBJECTDATA = '52 702')
	BEGIN
 	 PRINT '**** RFC69526 Adding data VALIDOBJECT.OBJECTDATA = 52 702'
	 declare @validObject int
         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
        INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	 VALUES (@validObject, 20, '52 702')
	 PRINT '**** RFC69526 Data successfully added to VALIDOBJECT table.'
	 PRINT ''
 	END
ELSE
 	PRINT '**** RFC69526 VALIDOBJECT.OBJECTDATA = 52 702 already exists'
 	PRINT ''
go
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                          and OBJECTDATA = '52 802')
	BEGIN
 	 PRINT '**** RFC69526 Adding data VALIDOBJECT.OBJECTDATA = 52 802'
	 declare @validObject int
         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
        INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	 VALUES (@validObject, 20, '52 802')
	 PRINT '**** RFC69526 Data successfully added to VALIDOBJECT table.'
	 PRINT ''
 	END
ELSE
 	PRINT '**** RFC69526 VALIDOBJECT.OBJECTDATA = 52 802 already exists'
 	PRINT ''
go
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                          and OBJECTDATA = '52 112')
	BEGIN
 	 PRINT '**** RFC69526 Adding data VALIDOBJECT.OBJECTDATA = 52 112'
	 declare @validObject int
         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
        INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	 VALUES (@validObject, 20, '52 112')
	 PRINT '**** RFC69526 Data successfully added to VALIDOBJECT table.'
	 PRINT ''
 	END
ELSE
 	PRINT '**** RFC69526 VALIDOBJECT.OBJECTDATA = 52 112 already exists'
 	PRINT ''
go
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                          and OBJECTDATA = '52 712')
	BEGIN
 	 PRINT '**** RFC69526 Adding data VALIDOBJECT.OBJECTDATA = 52 712'
	 declare @validObject int
         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
        INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	 VALUES (@validObject, 20, '52 712')
	 PRINT '**** RFC69526 Data successfully added to VALIDOBJECT table.'
	 PRINT ''
 	END
ELSE
 	PRINT '**** RFC69526 VALIDOBJECT.OBJECTDATA = 52 712 already exists'
 	PRINT ''
go
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                          and OBJECTDATA = '52 812')
	BEGIN
 	 PRINT '**** RFC69526 Adding data VALIDOBJECT.OBJECTDATA = 52 812'
	 declare @validObject int
         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
        INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
	 VALUES (@validObject, 20, '52 812')
	 PRINT '**** RFC69526 Data successfully added to VALIDOBJECT table.'
	 PRINT ''
 	END
ELSE
 	PRINT '**** RFC69526 VALIDOBJECT.OBJECTDATA = 52 812 already exists'
 	PRINT ''
go