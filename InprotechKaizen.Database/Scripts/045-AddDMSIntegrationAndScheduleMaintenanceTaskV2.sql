
/** RFC48206 Some apps features can be released solely from Apps installation **/

/* R37376 PTO Data Download Schedule Access **/
	
--- Translation Source columns should be added before adding a TID column(To generate audit triggers) ---	   
IF NOT exists (select * from TRANSLATIONSOURCE where TABLENAME = 'CONFIGURATIONITEMGROUP' and TIDCOLUMN = 'TITLE_TID')
begin
		PRINT '**** R37376 Inserting data into TRANSLATIONSOURCE.TABLENAME = CONFIGURATIONITEMGROUP'
		Insert into TRANSLATIONSOURCE (TABLENAME, SHORTCOLUMN , LONGCOLUMN, TIDCOLUMN, INUSE)
		Values ('CONFIGURATIONITEMGROUP', 'TITLE', NULL, 'TITLE_TID', 0)
		PRINT '**** R37376 Data has been successfully added to TRANSLATIONSOURCE table.'
		PRINT ''   
END
ELSE
PRINT '**** R37376 TRANSLATIONSOURCE.CONFIGURATIONITEMGROUP already exists.'
PRINT ''
go

IF NOT exists (select * from TRANSLATIONSOURCE where TABLENAME = 'CONFIGURATIONITEMGROUP' and TIDCOLUMN = 'DESCRIPTION_TID')
begin
		PRINT '**** R37376 Inserting data into TRANSLATIONSOURCE.TABLENAME = CONFIGURATIONITEMGROUP'
		Insert into TRANSLATIONSOURCE (TABLENAME, SHORTCOLUMN , LONGCOLUMN, TIDCOLUMN, INUSE)
		Values ('CONFIGURATIONITEMGROUP', 'DESCRIPTION', NULL, 'DESCRIPTION_TID', 0)
		PRINT '**** R37376 Data has been successfully added to TRANSLATIONSOURCE table.'
		PRINT ''   
END
ELSE
PRINT '**** R37376 TRANSLATIONSOURCE.CONFIGURATIONITEMGROUP already exists.'
PRINT ''
go


If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'CONFIGURATIONITEMGROUP')
	BEGIN
	PRINT '**** R37376  Adding table CONFIGURATIONITEMGROUP.' 
CREATE TABLE dbo.CONFIGURATIONITEMGROUP
		(
	ID  int  NOT NULL ,
	TITLE  nvarchar(512)  NOT NULL ,
	TITLE_TID  int  NULL ,
	DESCRIPTION  nvarchar(2000)  NULL ,
	LOGUSERID  varchar(50)  NULL ,
	DESCRIPTION_TID  int  NULL ,
	LOGIDENTITYID  int  NULL ,
	LOGTRANSACTIONNO  int  NULL ,
	LOGDATETIMESTAMP  datetime  NULL ,
	LOGAPPLICATION  nvarchar(128)  NULL ,
	LOGOFFICEID  int  NULL 
		)
exec sc_AssignTableSecurity 'CONFIGURATIONITEMGROUP'

	PRINT '**** R37376 CONFIGURATIONITEMGROUP table has been added.'
	PRINT ''
END
ELSE
	PRINT '**** R37376 CONFIGURATIONITEMGROUP already exists'
	PRINT ''
go 
	 
If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'CONFIGURATIONITEM' AND COLUMN_NAME = 'GROUPID')
	BEGIN   
	PRINT '**** R37376 Adding column CONFIGURATIONITEM.GROUPID.'           
	ALTER TABLE CONFIGURATIONITEM add  GROUPID  int  NULL 	 
	PRINT '**** R37376 CONFIGURATIONITEM.GROUPID column has been added.'
	END
	ELSE   
	PRINT '**** R37376 CONFIGURATIONITEM.GROUPID already exists'
	PRINT ''
GO
EXEC ipu_UtilGenerateAuditTriggers 'CONFIGURATIONITEM'
GO

if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'CONFIGURATIONITEM' and CONSTRAINT_NAME = 'R_81855')
		begin
			PRINT 'Dropping foreign key constraint CONFIGURATIONITEM.R_81855...'
			ALTER TABLE CONFIGURATIONITEM DROP CONSTRAINT R_81855
		end
		 

	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'CONFIGURATIONITEMGROUP' and CONSTRAINT_NAME = 'XPKCONFIGURATIONITEMGROUP')
	begin
		PRINT 'Dropping primary key constraint CONFIGURATIONITEMGROUP.XPKCONFIGURATIONITEMGROUP...'
		ALTER TABLE CONFIGURATIONITEMGROUP DROP CONSTRAINT XPKCONFIGURATIONITEMGROUP
	end
		PRINT 'Adding primary key constraint CONFIGURATIONITEMGROUP.XPKCONFIGURATIONITEMGROUP...'
		ALTER TABLE dbo.CONFIGURATIONITEMGROUP
				WITH NOCHECK ADD CONSTRAINT  XPKCONFIGURATIONITEMGROUP PRIMARY KEY   NONCLUSTERED (ID  ASC)
		go

			
if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'CONFIGURATIONITEMGROUP' and CONSTRAINT_NAME = 'R_81856')
	begin
		PRINT 'Dropping foreign key constraint CONFIGURATIONITEMGROUP.R_81856...'
		ALTER TABLE CONFIGURATIONITEMGROUP DROP CONSTRAINT R_81856
	end
		PRINT 'Adding foreign key constraint CONFIGURATIONITEMGROUP.R_81856...'
		ALTER TABLE dbo.CONFIGURATIONITEMGROUP
				WITH NOCHECK ADD CONSTRAINT  R_81856 FOREIGN KEY (TITLE_TID) REFERENCES dbo.TRANSLATEDITEMS(TID)
				NOT FOR REPLICATION
		go
			

if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'CONFIGURATIONITEMGROUP' and CONSTRAINT_NAME = 'R_81857')
	begin
		PRINT 'Dropping foreign key constraint CONFIGURATIONITEMGROUP.R_81857...'
		ALTER TABLE CONFIGURATIONITEMGROUP DROP CONSTRAINT R_81857
	end
		PRINT 'Adding foreign key constraint CONFIGURATIONITEMGROUP.R_81857...'
		ALTER TABLE dbo.CONFIGURATIONITEMGROUP
				WITH NOCHECK ADD CONSTRAINT  R_81857 FOREIGN KEY (DESCRIPTION_TID) REFERENCES dbo.TRANSLATEDITEMS(TID)
				NOT FOR REPLICATION
		go
			
		PRINT 'Adding foreign key constraint CONFIGURATIONITEM.R_81855...'
		ALTER TABLE dbo.CONFIGURATIONITEM
			WITH NOCHECK ADD CONSTRAINT  R_81855 FOREIGN KEY (GROUPID) REFERENCES dbo.CONFIGURATIONITEMGROUP(ID)
			NOT FOR REPLICATION
		go
			
	
/*** R47513 Add column CONFIGURATIONITEM.URL          ***/      

If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'CONFIGURATIONITEM' AND COLUMN_NAME = 'URL')
	BEGIN   
	PRINT '**** R47513 Adding column CONFIGURATIONITEM.URL.'           
	ALTER TABLE CONFIGURATIONITEM add  URL  nvarchar(2000)  NULL 	 
	PRINT '**** R47513 CONFIGURATIONITEM.URL column has been added.'
	END
	ELSE   
	PRINT '**** R47513 CONFIGURATIONITEM.URL already exists'
	PRINT ''
	GO
    EXEC ipu_UtilGenerateAuditTriggers 'CONFIGURATIONITEM'
	GO

/*** R47513 Add column CONFIGURATIONITEMGROUP.URL          ***/      

If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'CONFIGURATIONITEMGROUP' AND COLUMN_NAME = 'URL')
	BEGIN   
	PRINT '**** R47513 Adding column CONFIGURATIONITEMGROUP.URL.'           
	ALTER TABLE CONFIGURATIONITEMGROUP add  URL  nvarchar(2000)  NULL 	 
	PRINT '**** R47513 CONFIGURATIONITEMGROUP.URL column has been added.'
	END
	ELSE   
	PRINT '**** R47513 CONFIGURATIONITEMGROUP.URL already exists'
	PRINT ''
	GO
    EXEC ipu_UtilGenerateAuditTriggers 'CONFIGURATIONITEMGROUP'
	GO

         
/*** RFC47513 Ability to release an Apps only feature without changing Inprotech	***/

    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 215 AND URL IS NULL)
    Begin
	    print '***** RFC47513 Add URL to USPTO Certificates configuration item.'
	    UPDATE CONFIGURATIONITEM 
	    SET URL = '/i/integration/ptoaccess/#/uspto-private-pair-certificates'
	    WHERE TASKID = 215
	    print '***** RFC47513 URL added to USPTO Certificates configuration item.'
	    print ''
    End
    Else
    Begin
	    print '***** RFC47513 URL already exists on USPTO Certificates configuration item.'
	    print ''
    End
    go

/*** DR-45665 Ability to specify Practitioner sponsorship to enable automated USPTO download		***/
	
	print '***** DR-45665 Update TITLE, DESCRIPTION and URL to USPTO Certificates configuration item.'

	UPDATE CONFIGURATIONITEM set TITLE = 'USPTO Practitioner Sponsorship', 
	DESCRIPTION='Set up your USPTO Private PAIR Practitioner Sponsorship to allow Inprotech to access the USPTO on your firm''s behalf',
	URL = '/apps/#/integration/ptoaccess/uspto-private-pair-sponsorships' 
	WHERE TASKID = 215
	print '***** DR-45665 Updated TITLE, DESCRIPTION and URL to USPTO Certificates configuration item.'
	print ''
	go

/*** RFC36801 Create Schedules for USPTO TSDR Data download - Task						***/
	
If NOT exists (select * from TASK where TASKID = 227)
        BEGIN
         	PRINT '**** RFC36801 Adding data TASK.TASKID = 227'
		INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		VALUES (227, N'Schedule USPTO TSDR Data Download',N'Schedule tasks to download data from USPTO TSDR (Trademark Status & Document Retrieval) for use with case data comparison')
        	PRINT '**** RFC36801 Data successfully added to TASK table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC36801 TASK.TASKID = 227 already exists'
        PRINT ''
    go

   	
/*** RFC36801 Create Schedules for USPTO TSDR Data download - FeatureTask						***/
	
IF NOT exists (select * from FEATURETASK where FEATUREID = 32 AND TASKID = 227)
	begin
	PRINT '**** RFC36801 Inserting FEATURETASK.FEATUREID = 32, TASKID = 227'
	INSERT INTO FEATURETASK (FEATUREID, TASKID)
	VALUES (32, 227)
	PRINT '**** RFC36801 Data has been successfully added to FEATURETASK table.'
	PRINT ''
	END
ELSE
	PRINT '**** RFC36801 FEATURETASK.FEATUREID = 32, TASKID = 227 already exists.'
	PRINT ''
go

   	
/*** RFC36801 Create Schedules for USPTO TSDR Data download - Permission Definition						***/
	
If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
			and OBJECTINTEGERKEY = 227
			and LEVELTABLE is null
			and LEVELKEY is null)
        BEGIN
         	PRINT '**** RFC36801 Adding TASK definition data PERMISSIONS.OBJECTKEY = 227'
		INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		VALUES ('TASK', 227, NULL, NULL, NULL, 32, 0)
        	PRINT '**** RFC36801 Data successfully added to PERMISSIONS table.'
		PRINT ''
        END
    ELSE
        BEGIN
         	PRINT '**** RFC36801 TASK definition data PERMISSIONS.OBJECTKEY = 227 already exists'
		PRINT ''
        END
    go

   	
/*** RFC36801 - ValidObject								***/
	
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                and OBJECTDATA = '22 871')
        BEGIN
         	PRINT '**** RFC36801 Adding data VALIDOBJECT.OBJECTDATA = 22 871'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '22 871')
        	PRINT '**** RFC36801 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC36801 VALIDOBJECT.OBJECTDATA = 22 871 already exists'
        PRINT ''
    go
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                and OBJECTDATA = '22 172')
        BEGIN
         	PRINT '**** RFC36801 Adding data VALIDOBJECT.OBJECTDATA = 22 172'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '22 172')
        	PRINT '**** RFC36801 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC36801 VALIDOBJECT.OBJECTDATA = 22 172 already exists'
        PRINT ''
    go
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                and OBJECTDATA = '22 772')
        BEGIN
         	PRINT '**** RFC36801 Adding data VALIDOBJECT.OBJECTDATA = 22 772'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '22 772')
        	PRINT '**** RFC36801 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC36801 VALIDOBJECT.OBJECTDATA = 22 772 already exists'
        PRINT ''
    go
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                and OBJECTDATA = '22 872')
        BEGIN
         	PRINT '**** RFC36801 Adding data VALIDOBJECT.OBJECTDATA = 22 872'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '22 872')
        	PRINT '**** RFC36801 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC36801 VALIDOBJECT.OBJECTDATA = 22 872 already exists'
        PRINT ''
    go
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                and OBJECTDATA = '22 972')
        BEGIN
         	PRINT '**** RFC36801 Adding data VALIDOBJECT.OBJECTDATA = 22 972'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '22 972')
        	PRINT '**** RFC36801 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC36801 VALIDOBJECT.OBJECTDATA = 22 972 already exists'
        PRINT ''
    go
	
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                and OBJECTDATA = '22  72')
        BEGIN
         	PRINT '**** RFC36801 Adding data VALIDOBJECT.OBJECTDATA = 22  72'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '22  72')
        	PRINT '**** RFC36801 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC36801 VALIDOBJECT.OBJECTDATA = 22  72 already exists'
        PRINT ''
    go

    /*** RFC42681 Create EPO Schedules for download - Task						***/
	
If NOT exists (select * from TASK where TASKID = 232)
        BEGIN
         	PRINT '**** RFC42681 Adding data TASK.TASKID = 232'
		INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		VALUES (232, N'Schedule EPO Data Download',N'Schedule tasks to download data from European Patent Office (Open Patent Services) for use with case data comparison')
        	PRINT '**** RFC42681 Data successfully added to TASK table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC42681 TASK.TASKID = 232 already exists'
        PRINT ''
    go

	
/*** RFC42681 Create EPO Schedules for download - FeatureTask						***/
	
IF NOT exists (select * from FEATURETASK where FEATUREID = 32 AND TASKID = 232)
	begin
	PRINT '**** RFC42681 Inserting FEATURETASK.FEATUREID = 32, TASKID = 232'
	INSERT INTO FEATURETASK (FEATUREID, TASKID)
	VALUES (32, 232)
	PRINT '**** RFC42681 Data has been successfully added to FEATURETASK table.'
	PRINT ''
	END
ELSE
	PRINT '**** RFC42681 FEATURETASK.FEATUREID = 32, TASKID = 232 already exists.'
	PRINT ''
go

	
/*** RFC42681 Create EPO Schedules for download - Permission Definition						***/
	
If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
			and OBJECTINTEGERKEY = 232
			and LEVELTABLE is null
			and LEVELKEY is null)
        BEGIN
         	PRINT '**** RFC42681 Adding TASK definition data PERMISSIONS.OBJECTKEY = 232'
		INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		VALUES ('TASK', 232, NULL, NULL, NULL, 32, 0)
        	PRINT '**** RFC42681 Data successfully added to PERMISSIONS table.'
		PRINT ''
        END
    ELSE
        BEGIN
         	PRINT '**** RFC42681 TASK definition data PERMISSIONS.OBJECTKEY = 232 already exists'
		PRINT ''
        END
    go

	
/*** RFC42681 - ValidObject								***/
	
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                and OBJECTDATA = '32  22')
        BEGIN
         	PRINT '**** RFC42681 Adding data VALIDOBJECT.OBJECTDATA = 32  22'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '32  22')
        	PRINT '**** RFC42681 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC42681 VALIDOBJECT.OBJECTDATA = 32  22 already exists'
        PRINT ''
    go
	
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                and OBJECTDATA = '32 821')
        BEGIN
         	PRINT '**** RFC42681 Adding data VALIDOBJECT.OBJECTDATA = 32 821'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '32 821')
        	PRINT '**** RFC42681 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC42681 VALIDOBJECT.OBJECTDATA = 32 821 already exists'
        PRINT ''
    go
	
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                and OBJECTDATA = '32 122')
        BEGIN
         	PRINT '**** RFC42681 Adding data VALIDOBJECT.OBJECTDATA = 32 122'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '32 122')
        	PRINT '**** RFC42681 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC42681 VALIDOBJECT.OBJECTDATA = 32 122 already exists'
        PRINT ''
    go
	
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                and OBJECTDATA = '32 722')
        BEGIN
         	PRINT '**** RFC42681 Adding data VALIDOBJECT.OBJECTDATA = 32 722'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '32 722')
        	PRINT '**** RFC42681 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC42681 VALIDOBJECT.OBJECTDATA = 32 722 already exists'
        PRINT ''
    go
	
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                and OBJECTDATA = '32 822')
        BEGIN
         	PRINT '**** RFC42681 Adding data VALIDOBJECT.OBJECTDATA = 32 822'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '32 822')
        	PRINT '**** RFC42681 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC42681 VALIDOBJECT.OBJECTDATA = 32 822 already exists'
        PRINT ''
    go
	
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                and OBJECTDATA = '32 922')
        BEGIN
         	PRINT '**** RFC42681 Adding data VALIDOBJECT.OBJECTDATA = 32 922'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '32 922')
        	PRINT '**** RFC42681 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC42681 VALIDOBJECT.OBJECTDATA = 32 922 already exists'
        PRINT ''
    go

IF NOT EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 232)
BEGIN
	INSERT INTO CONFIGURATIONITEM(TASKID, TITLE, DESCRIPTION) VALUES(
	232,
	N'Schedule EPO Data Download',
	N'Schedule tasks to automatically download selected case data from the European Patent Office.')
END
GO

    /*** RFC45624 Task Security for Configure DMS Integration - Task						***/

If NOT exists (select * from TASK where TASKID = 236)
        BEGIN
         	PRINT '**** RFC45624 Adding data TASK.TASKID = 236'
		INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)
		VALUES (236, N'Configure DMS Integration',N'Ability to configure settings to enable integration with a Document Management System.')
        	PRINT '**** RFC45624 Data successfully added to TASK table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC45624 TASK.TASKID = 236 already exists'
        PRINT ''
    go

    	
/*** RFC45624 Task Security for Configure DMS Integration - FeatureTask						***/

IF NOT exists (select * from FEATURETASK where FEATUREID = 60 AND TASKID = 236)
	begin
	PRINT '**** RFC45624 Inserting FEATURETASK.FEATUREID = 60, TASKID = 236'
	INSERT INTO FEATURETASK (FEATUREID, TASKID)
	VALUES (60, 236)
	PRINT '**** RFC45624 Data has been successfully added to FEATURETASK table.'
	PRINT ''
	END
ELSE
	PRINT '**** RFC45624 FEATURETASK.FEATUREID = 60, TASKID = 236 already exists.'
	PRINT ''
go
        
    	
/*** RFC45624 Task Security for Configure DMS Integration - Permission Definition		**/

If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
			and OBJECTINTEGERKEY = 236
			and LEVELTABLE is null
			and LEVELKEY is null)
        BEGIN
         	PRINT '**** RFC45624 Adding TASK definition data PERMISSIONS.OBJECTKEY = 236'
		INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) 
		VALUES ('TASK', 236, NULL, NULL, NULL, 32, 0)
        	PRINT '**** RFC45624 Data successfully added to PERMISSIONS table.'
		PRINT ''
        END
    ELSE
        BEGIN
         	PRINT '**** RFC45624 TASK definition data PERMISSIONS.OBJECTKEY = 236 already exists'
		PRINT ''
        END
    go
            	
/*** RFC45624 - ValidObject								***/

If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                and OBJECTDATA = '32  62')
        BEGIN
         	PRINT '**** RFC45624 Adding data VALIDOBJECT.OBJECTDATA = 32  62'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '32  62')
        	PRINT '**** RFC45624 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC45624 VALIDOBJECT.OBJECTDATA = 32  62 already exists'
        PRINT ''
    go
		
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                and OBJECTDATA = '32 861')
        BEGIN
         	PRINT '**** RFC45624 Adding data VALIDOBJECT.OBJECTDATA = 32 861'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '32 861')
        	PRINT '**** RFC45624 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC45624 VALIDOBJECT.OBJECTDATA = 32 861 already exists'
        PRINT ''
    go
		
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                and OBJECTDATA = '32 162')
        BEGIN
         	PRINT '**** RFC45624 Adding data VALIDOBJECT.OBJECTDATA = 32 162'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '32 162')
        	PRINT '**** RFC45624 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC45624 VALIDOBJECT.OBJECTDATA = 32 162 already exists'
        PRINT ''
    go
		
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                and OBJECTDATA = '32 762')
        BEGIN
         	PRINT '**** RFC45624 Adding data VALIDOBJECT.OBJECTDATA = 32 762'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '32 762')
        	PRINT '**** RFC45624 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC45624 VALIDOBJECT.OBJECTDATA = 32 762 already exists'
        PRINT ''
    go
		
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                and OBJECTDATA = '32 862')
        BEGIN
         	PRINT '**** RFC45624 Adding data VALIDOBJECT.OBJECTDATA = 32 862'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '32 862')
        	PRINT '**** RFC45624 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC45624 VALIDOBJECT.OBJECTDATA = 32 862 already exists'
        PRINT ''
    go
		
If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20
                                and OBJECTDATA = '32 962')
        BEGIN
         	PRINT '**** RFC45624 Adding data VALIDOBJECT.OBJECTDATA = 32 962'
		declare @validObject int
      	        Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
            INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)
		VALUES (@validObject, 20, '32 962')
        	PRINT '**** RFC45624 Data successfully added to VALIDOBJECT table.'
		PRINT ''
        END
    ELSE
        PRINT '**** RFC45624 VALIDOBJECT.OBJECTDATA = 32 962 already exists'
        PRINT ''
    go
		

/*** RFC47310 Configuration item for Configure DMS Integration     					    ***/
    
        IF NOT EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 236)
        BEGIN
                PRINT '**** RFC47310 Adding data CONFIGURATIONITEM.TASKID = 236'
	        INSERT INTO CONFIGURATIONITEM(TASKID, TITLE, DESCRIPTION) VALUES(
	        236,
	        N'Configure DMS Integration',
	        N'Configure settings to enable integration with a Document Management System.')
            PRINT '**** RFC47310 Data successfully added to CONFIGURATIONITEM table.'
	    PRINT ''
        END
        ELSE
                PRINT '**** RFC47310 CONFIGURATIONITEM.TASKID = 236 already exists'
                PRINT ''
        go

    /*** RFC37376 PTO Data Download Schedule Access ***/

    /***  RFC37376  Add data into AUDITLOGTABLES.TABLENAME = CONFIGURATIONITEMGROUP									***/   
    IF NOT exists (select * from AUDITLOGTABLES where TABLENAME = 'CONFIGURATIONITEMGROUP')
	    begin
		    PRINT '**** RFC37376  Inserting data into AUDITLOGTABLE.TABLENAME = CONFIGURATIONITEMGROUP'
		    Insert AUDITLOGTABLES (TABLENAME, LOGFLAG, REPLICATEFLAG)
		    Values ('CONFIGURATIONITEMGROUP', 0, 0)
		    PRINT '**** RFC37376  Data has been successfully added to AUDITLOGTABLES table.'
		    PRINT ''	
	    END
    ELSE
	    PRINT '**** RFC37376  AUDITLOGTABLES.CONFIGURATIONITEMGROUP already exists.'
	    PRINT ''
    go

    IF NOT exists (select * FROM CONFIGURATIONITEMGROUP WHERE ID = 1)
    Begin
        PRINT '**** RFC37376 Adding CONFIGURATIONITEMGROUP for Schedule a Download'
	    INSERT INTO CONFIGURATIONITEMGROUP (ID, TITLE, DESCRIPTION)
	    VALUES (1, 'Schedule Data Download', 'Schedule tasks to download data from external sources for use with case data comparison')
	    PRINT '**** RFC37376 Data successfully added to CONFIGURATIONITEMGROUP table.'
	    PRINT ''
    End
    Else
    Begin	
		UPDATE CONFIGURATIONITEMGROUP
		SET TITLE = 'Schedule Data Download',
			DESCRIPTION = 'Schedule tasks to download data from external sources for use with case data comparison'
		WHERE ID = 1
        PRINT '**** DR-31053 Change terminology to generically refer to data download.'
	    PRINT ''
    End

    IF NOT exists (select * FROM CONFIGURATIONITEM WHERE TASKID = 227)
    Begin
            PRINT '**** RFC37376 Adding CONFIGURATIONITEM for Schedule USPTO TSDR Data Download'
	    INSERT into CONFIGURATIONITEM (TASKID,CONTEXTID,TITLE,TITLE_TID,DESCRIPTION,DESCRIPTION_TID,GENERICPARAM,GROUPID)
	    VALUES(227,NULL,'Schedule USPTO TSDR Data Download',NULL,'Schedule tasks to automatically download selected case data from the USPTO TSDR.',NULL,NULL,1)
	    PRINT '**** RFC37376 Data successfully added to CONFIGURATIONITEM table.'
	    PRINT ''
    End
    Else
    Begin
            PRINT '**** RFC37376 CONFIGURATIONITEM Schedule USPTO TSDR Data Download already exists.'
	    PRINT ''
    End

    IF exists (select * FROM CONFIGURATIONITEM WHERE TASKID = 216 and GROUPID IS NULL)
    Begin
	    PRINT '**** RFC37376 Updating CONFIGURATIONITEM for Schedule USPTO Private PAIR Data Download'
	    UPDATE CONFIGURATIONITEM 
	    SET GROUPID = 1,
	    TITLE = 'Schedule USPTO Private PAIR Data Download'
	    WHERE TASKID = 216
	    PRINT '**** RFC37376 Data successfully updated on CONFIGURATIONITEM table.'
	    PRINT ''
    End
    Else
    Begin
            PRINT '**** RFC37376 CONFIGURATIONITEM Schedule USPTO Private PAIR Data Download already up to date.'
	    PRINT ''
    End
    Go

        
    IF EXISTS (SELECT * FROM CONFIGURATIONITEMGROUP WHERE ID = 1 AND URL IS NULL)
    Begin
	    print '***** RFC47513 Add URL to PTO Schedule maintenance group.'
	    UPDATE CONFIGURATIONITEMGROUP 
	    SET URL = '/i/integration/ptoaccess/#/schedules'
	    WHERE ID = 1
	    print '***** RFC47513 URL added to PTO Schedule maintenance group.'
	    print ''
    End
    Else
    Begin
	    print '***** RFC47513 URL already exists on PTO Schedule maintenance group.'
	    print ''
    End
    go

	IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 232 AND URL IS NULL)
	Begin
		print '***** RFC47513 Add URL to EPO Integration configuration item.'
		UPDATE CONFIGURATIONITEM
		SET URL = '/i/integration/ptoaccess/#/schedules'
		WHERE TASKID = 232
		print '***** RFC47513 URL added to EPO Integration configuration item.'
		print ''
	End
	Else
	Begin
		print '***** RFC47513 URL already exists on EPO Integration configuration item.'
		print ''
	End
	go
   
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 236 AND URL IS NULL)
    Begin
	    print '***** RFC47513 Add URL to DMS Integration configuration item.'
	    UPDATE CONFIGURATIONITEM
	    SET URL = '/apps/configuration/dmsintegration/#'
	    WHERE TASKID = 236
	    print '***** RFC47513 URL added to DMS Integration configuration item.'
	    print ''
    End
    Else
    Begin
	    print '***** RFC47513 URL already exists on DMS Integration configuration item.'
	    print ''
    End
    go

