	  /** R43203 Allow selection of Event Note Type on the Event Note window **/

      --- Translation Source columns should be added before adding a TID column(To generate audit triggers) ---        
      IF NOT exists (select * from TRANSLATIONSOURCE where TABLENAME = 'EVENTTEXTTYPE' and TIDCOLUMN = 'DESCRIPTION_TID')
                  begin
                              PRINT '**** R43203 Inserting data into TRANSLATIONSOURCE.TABLENAME = EVENTTEXTTYPE'
                              Insert into TRANSLATIONSOURCE (TABLENAME, SHORTCOLUMN , LONGCOLUMN, TIDCOLUMN, INUSE)
                              Values ('EVENTTEXTTYPE', 'DESCRIPTION', NULL, 'DESCRIPTION_TID', 0)
                              PRINT '**** R43203 Data has been successfully added to TRANSLATIONSOURCE table.'
                              PRINT ''   
                  END
                  ELSE
                  PRINT '**** R43203 TRANSLATIONSOURCE.EVENTTEXTTYPE already exists.'
                  PRINT ''
                  go

      IF NOT exists (select * from TRANSLATIONSOURCE where TABLENAME = 'EVENTTEXT' and TIDCOLUMN = 'EVENTTEXT_TID')
            begin
                        PRINT '**** R43203 Inserting data into TRANSLATIONSOURCE.TABLENAME = EVENTTEXT'
                        Insert into TRANSLATIONSOURCE (TABLENAME, SHORTCOLUMN , LONGCOLUMN, TIDCOLUMN, INUSE)
                        Values ('EVENTTEXT', 'EVENTTEXT', NULL, 'EVENTTEXT_TID', 0)
                        PRINT '**** R43203 Data has been successfully added to TRANSLATIONSOURCE table.'
                        PRINT ''   
            END
            ELSE
            PRINT '**** R43203 TRANSLATIONSOURCE.EVENTTEXT already exists.'
            PRINT ''
            go


      If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'EVENTTEXTTYPE')
                  BEGIN
                  PRINT '**** R43203  Adding table EVENTTEXTTYPE.' 
                  CREATE TABLE dbo.EVENTTEXTTYPE
                  (
                        EVENTTEXTTYPEID  smallint  IDENTITY (1,1)  NOT FOR REPLICATION,
                        DESCRIPTION  nvarchar(250)  NOT NULL ,
                        DESCRIPTION_TID  int  NULL ,
                        ISEXTERNAL  bit  NOT NULL ,
                        LOGUSERID  nvarchar(50)  NULL ,
                        LOGIDENTITYID  int  NULL ,
                        LOGTRANSACTIONNO  int  NULL ,
                        LOGDATETIMESTAMP  datetime  NULL ,
                        LOGAPPLICATION  nvarchar(128)  NULL ,
                        LOGOFFICEID  int  NULL 
                   )                
                  exec sc_AssignTableSecurity 'EVENTTEXTTYPE'

                  PRINT '**** R43203 EVENTTEXTTYPE table has been added.'
                  PRINT ''
            END
            ELSE
                  PRINT '**** R43203 EVENTTEXTTYPE already exists'
                  PRINT ''
            go 

      If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'EVENTTEXT')
            BEGIN
            PRINT '**** R43203  Adding table EVENTTEXT.' 
                    CREATE TABLE dbo.EVENTTEXT
                  (
                        EVENTTEXTID  int  IDENTITY (1,1)  NOT FOR REPLICATION,
                        EVENTTEXT  nvarchar(max)  NOT NULL ,
                        EVENTTEXT_TID  int  NULL ,
                        EVENTTEXTTYPEID  smallint  NULL ,
                        LOGUSERID  nvarchar(50)  NULL ,
                        LOGIDENTITYID  int  NULL ,
                        LOGTRANSACTIONNO  int  NULL ,
                        LOGDATETIMESTAMP  datetime  NULL ,
                        LOGAPPLICATION  nvarchar(128)  NULL ,
                        LOGOFFICEID  int  NULL 
                   )                
                   exec sc_AssignTableSecurity 'EVENTTEXT'

                  PRINT '**** R43203 EVENTTEXT table has been added.'
                  PRINT ''
            END
            ELSE
                  PRINT '**** R43203 EVENTTEXT already exists'
                  PRINT ''
            go 

      If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'CASEEVENTTEXT')
                  BEGIN
                  PRINT '**** R43203  Adding table CASEEVENTTEXT.' 
                  CREATE TABLE dbo.CASEEVENTTEXT
                  (                       
                        CASEID  int  NOT NULL ,
                        EVENTNO  int  NOT NULL ,
                        CYCLE  smallint  NOT NULL ,
						EVENTTEXTID  int  NOT NULL ,
                        LOGUSERID  nvarchar(50)  NULL ,
                        LOGIDENTITYID  int  NULL ,
                        LOGTRANSACTIONNO  int  NULL ,
                        LOGDATETIMESTAMP  datetime  NULL ,
                        LOGAPPLICATION  nvarchar(128)  NULL ,
                        LOGOFFICEID  int  NULL 
                   )                
                  exec sc_AssignTableSecurity 'CASEEVENTTEXT'

                  PRINT '**** R43203 CASEEVENTTEXT table has been added.'
                  PRINT ''
            END
            ELSE
                  PRINT '**** R43203 CASEEVENTTEXT already exists'
                  PRINT ''
            go 

      if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'EVENTTEXT' and CONSTRAINT_NAME = 'R_81858')
            begin
                  PRINT 'Dropping foreign key constraint EVENTTEXT.R_81858...'
                  ALTER TABLE EVENTTEXT DROP CONSTRAINT R_81858
            end
                  go

      if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'CASEEVENTTEXT' and CONSTRAINT_NAME = 'R_81861')
            begin
                  PRINT 'Dropping foreign key constraint CASEEVENTTEXT.R_81861...'
                  ALTER TABLE CASEEVENTTEXT DROP CONSTRAINT R_81861
            end
                  go
                  
      if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'CASEEVENTTEXT' and CONSTRAINT_NAME = 'R_1863')
            begin
                  PRINT 'Dropping foreign key constraint CASEEVENTTEXT.R_1863...'
                  ALTER TABLE CASEEVENTTEXT DROP CONSTRAINT R_1863
            end
                  go
                  

      if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'EVENTTEXTTYPE' and CONSTRAINT_NAME = 'XPKEVENTTEXTTYPE')
            begin
                  PRINT 'Dropping primary key constraint EVENTTEXTTYPE.XPKEVENTTEXTTYPE...'
                  ALTER TABLE EVENTTEXTTYPE DROP CONSTRAINT XPKEVENTTEXTTYPE
            end
                  PRINT 'Adding primary key constraint EVENTTEXTTYPE.XPKEVENTTEXTTYPE...'
                  ALTER TABLE dbo.EVENTTEXTTYPE
                        WITH NOCHECK ADD CONSTRAINT  XPKEVENTTEXTTYPE PRIMARY KEY   NONCLUSTERED (EVENTTEXTTYPEID  ASC)
                  go
                                          
      if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'EVENTTEXT' and CONSTRAINT_NAME = 'XPKEVENTTEXT')
            begin
                  PRINT 'Dropping primary key constraint EVENTTEXT.XPKEVENTTEXT...'
                  ALTER TABLE EVENTTEXT DROP CONSTRAINT XPKEVENTTEXT
            end
                  PRINT 'Adding primary key constraint EVENTTEXT.XPKEVENTTEXT...'
                  ALTER TABLE dbo.EVENTTEXT
                        WITH NOCHECK ADD CONSTRAINT  XPKEVENTTEXT PRIMARY KEY   NONCLUSTERED (EVENTTEXTID  ASC)
                  go

      if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'CASEEVENTTEXT' and CONSTRAINT_NAME = 'XPKCASEEVENTTEXT')
            begin
                  PRINT 'Dropping primary key constraint CASEEVENTTEXT.XPKCASEEVENTTEXT...'
                  ALTER TABLE CASEEVENTTEXT DROP CONSTRAINT XPKCASEEVENTTEXT
            end
                  PRINT 'Adding primary key constraint CASEEVENTTEXT.XPKCASEEVENTTEXT...'             
                  ALTER TABLE dbo.CASEEVENTTEXT
                        WITH NOCHECK ADD CONSTRAINT  XPKCASEEVENTTEXT PRIMARY KEY   NONCLUSTERED (CASEID  ASC,EVENTNO  ASC,CYCLE  ASC,EVENTTEXTID  ASC)
                        
                  go

      IF exists (SELECT * FROM sysindexes WHERE name = 'XAK1EVENTTEXTTYPE')
      BEGIN
            PRINT 'Dropping index EVENTTEXTTYPE.XAK1EVENTTEXTTYPE ...'
            DROP INDEX EVENTTEXTTYPE.XAK1EVENTTEXTTYPE
      END
      IF not exists (SELECT * FROM sysindexes WHERE name = 'XAK1EVENTTEXTTYPE')
      BEGIN
            PRINT 'Adding index RELATEDCASE.XAK1EVENTTEXTTYPE ...'
            CREATE  UNIQUE INDEX XAK1EVENTTEXTTYPE ON EVENTTEXTTYPE
            (
                  DESCRIPTION  ASC
            )
      END
      go    

	  if exists (select * from sysindexes where name = 'XAK1CASEEVENTTEXT')
	  begin
		   PRINT 'Dropping index CASEEVENTTEXT.XAK1CASEEVENTTEXT ...'
		   DROP INDEX CASEEVENTTEXT.XAK1CASEEVENTTEXT
	  end
		  PRINT 'Creating index CASEEVENTTEXT.XAK1CASEEVENTTEXT ...'
		  CREATE  UNIQUE INDEX XAK1CASEEVENTTEXT ON CASEEVENTTEXT
		  (
		  EVENTTEXTID  ASC
		  )
	  go

      PRINT 'Adding foreign key constraint EVENTTEXT.R_81858...'
      ALTER TABLE dbo.EVENTTEXT
            WITH NOCHECK ADD CONSTRAINT  R_81858 FOREIGN KEY (EVENTTEXTTYPEID) REFERENCES dbo.EVENTTEXTTYPE(EVENTTEXTTYPEID)
                  ON DELETE CASCADE
            NOT FOR REPLICATION          
      go 

      PRINT 'Adding foreign key constraint CASEEVENTTEXT.R_81861...'
      ALTER TABLE dbo.CASEEVENTTEXT
            WITH NOCHECK ADD CONSTRAINT  R_81861 FOREIGN KEY (EVENTTEXTID) REFERENCES dbo.EVENTTEXT(EVENTTEXTID)
                  ON DELETE CASCADE
            NOT FOR REPLICATION
      go 
      
      PRINT 'Adding foreign key constraint CASEEVENTTEXT.R_1863...'
      ALTER TABLE dbo.CASEEVENTTEXT
            WITH NOCHECK ADD CONSTRAINT  R_1863 FOREIGN KEY (CASEID,EVENTNO,CYCLE) REFERENCES dbo.CASEEVENT(CASEID,EVENTNO,CYCLE)
                  ON DELETE CASCADE
            NOT FOR REPLICATION
      go          

      If exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'CASEEVENT' and COLUMN_NAME = 'EVENTLONGTEXT' and DATA_TYPE = 'ntext')
            BEGIN
            PRINT '****  Altering column CASEEVENT.EVENTLONGTEXT.'
            ALTER TABLE CASEEVENT ALTER COLUMN EVENTLONGTEXT nvarchar(max) null
            PRINT '****  CASEEVENT.EVENTLONGTEXT column has been altered.'
            PRINT ''
            END
      go

      EXEC ipu_UtilGenerateAuditTriggers 'CASEEVENTTEXT' 
      EXEC ipu_UtilGenerateAuditTriggers 'EVENTTEXT' 
      EXEC ipu_UtilGenerateAuditTriggers 'EVENTTEXTTYPE' 
      EXEC ipu_UtilGenerateAuditTriggers 'CASEEVENT'
      Go
