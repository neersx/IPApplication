	IF NOT exists (select * from TASK where TASKID = 215)
	BEGIN
       INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		 VALUES (215, N'Configure USPTO Private PAIR Certificate',N'Store USPTO Private PAIR certificate credentials to enable automatic connection to the USPTO when downloading case data')
	END
    go

    IF NOT exists (select * from FEATURETASK where FEATUREID = 32 AND TASKID = 215)
	BEGIN
		INSERT INTO FEATURETASK (FEATUREID, TASKID)
		VALUES (32, 215)
	END
	go

   	IF NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 215
				and LEVELTABLE is null
				and LEVELKEY is null)
	BEGIN
    	 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		 VALUES ('TASK', 215, NULL, NULL, NULL, 32, 0)
	END
    go
    IF NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '12 752')
    BEGIN
    	 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '12 752')
    END
    go

   	IF NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '12  52')
    BEGIN
    	 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '12  52')
	END
    go
	
	IF NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '12 851')
    BEGIN
    	 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '12 851')
    END
    go
	
	IF NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '12 152')
    BEGIN
    	 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '12 152')
    END
    go
	
	IF NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '12 852')
    BEGIN
    	 declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '12 852')
    END
    go
	
	IF NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                  and OBJECTDATA = '12 952')
    BEGIN
		declare @validObject int
      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		 VALUES (@validObject, 20, '12 952')
    END
    go

/**********************************************************************************************************/
/*** RFC73763 Update task security for the visibility of New Portal link - Task							***/
/**********************************************************************************************************/
	PRINT '**** DR-45665 Try update TASKNAME and DESCRIPTION for TASK 215'
	UPDATE TASK SET TASKNAME = 'Configure USPTO Practitioner Sponsorship', DESCRIPTION ='Store practitioner''s USPTO Private PAIR sponsorship details to enable automatic connection to the USPTO when downloading case data as a sponsored support staff.'
	WHERE TASKID = 215
	GO

	
	UPDATE CONFIGURATIONITEM set TITLE = 'USPTO Practitioner Sponsorship', 
	DESCRIPTION='Set up your USPTO Private PAIR Practitioner Sponsorship to allow Inprotech to access the USPTO on your firm''s behalf',
	URL = '/apps/#/integration/ptoaccess/uspto-private-pair-sponsorships' 
	WHERE TASKID = 215
	print '***** DR-45665 Updated TITLE, DESCRIPTION and URL to USPTO Certificates configuration item.'
	print ''
	go