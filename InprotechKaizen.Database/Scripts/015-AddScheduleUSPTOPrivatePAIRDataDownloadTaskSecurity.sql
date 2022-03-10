	IF NOT exists (select * from TASK where TASKID = 216)
    BEGIN
    	 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (216, N'Schedule USPTO Private PAIR Data Download',N'Schedule tasks to download data from USPTO Private PAIR for use with case data comparison')
    END
    go

	IF NOT exists (select * from FEATURETASK where FEATUREID = 32 AND TASKID = 216)
	BEGIN
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (32, 216)
	END
	go

	IF NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 216
				and LEVELTABLE is null
				and LEVELKEY is null)
    BEGIN
     	 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 216, NULL, NULL, NULL, 32, 0)
    END
    go
   	
	IF NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '12 762')
    BEGIN
    	 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '12 762')
    END
    go

	IF NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '12  62')
    BEGIN
    	 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '12  62')
    END
    go
	
	IF NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '12 861')
    BEGIN
    	 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '12 861')
    END
    go
	
	IF NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '12 162')
    BEGIN
    	 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '12 162')
    END
    go
	
	IF NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '12 862')
    BEGIN
    	 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '12 862')
    END
    go

	IF NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '12 962')
    BEGIN
		declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '12 962')
	END
    go
	


