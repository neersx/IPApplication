	/** R51117 Create new tables required for the site control changes **/
	
	If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'COMPONENTS')
	BEGIN
	PRINT '**** R51117  Adding table COMPONENTS.' 
        CREATE TABLE dbo.COMPONENTS
         (
 	        COMPONENTID  int  IDENTITY (1,1)  NOT FOR REPLICATION,
 	        COMPONENTNAME  nvarchar(100)  NOT NULL ,
 	        LOGUSERID  nvarchar(50)  NULL ,
 	        LOGIDENTITYID  int  NULL ,
 	        LOGTRANSACTIONNO  int  NULL ,
 	        LOGDATETIMESTAMP  datetime  NULL ,
 	        LOGAPPLICATION  nvarchar(128)  NULL ,
 	        LOGOFFICEID  int  NULL 
         )
         exec sc_AssignTableSecurity 'COMPONENTS'

		PRINT '**** R51117 COMPONENTS table has been added.'
		PRINT ''
	END
	ELSE
		PRINT '**** R51117 COMPONENTS already exists'
		PRINT ''
	go 

	If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SITECONTROLCOMPONENTS')
		BEGIN
		PRINT '**** R51117  Adding table SITECONTROLCOMPONENTS.'

			  CREATE TABLE dbo.SITECONTROLCOMPONENTS
			 (
				SITECONTROLID  int  NOT NULL ,
				COMPONENTID  int  NOT NULL ,
				LOGUSERID  nvarchar(50)  NULL ,
				LOGIDENTITYID  int  NULL ,
				LOGTRANSACTIONNO  int  NULL ,
				LOGDATETIMESTAMP  datetime  NULL ,
				LOGAPPLICATION  nvarchar(128)  NULL ,
				LOGOFFICEID  int  NULL 
			 )
			exec sc_AssignTableSecurity 'SITECONTROLCOMPONENTS'

			PRINT '**** R51117 SITECONTROLCOMPONENTS table has been added.'
			PRINT ''
		END
		ELSE
			PRINT '**** R51117 SITECONTROLCOMPONENTS already exists'
			PRINT ''
		go 
	 
	 
	If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TAGS')
		BEGIN
		PRINT '**** R51117  Adding table TAGS.'
			CREATE TABLE dbo.TAGS
			 (
				TAGID  int  IDENTITY (1,1)  NOT FOR REPLICATION,
				TAGNAME  nvarchar(30)  NULL ,
				LOGUSERID  nvarchar(50)  NULL ,
				LOGIDENTITYID  int  NULL ,
				LOGTRANSACTIONNO  int  NULL ,
				LOGDATETIMESTAMP  datetime  NULL ,
				LOGAPPLICATION  nvarchar(128)  NULL ,
				LOGOFFICEID  int  NULL 
			 )
			  exec sc_AssignTableSecurity 'TAGS'

			PRINT '**** R51117 TAGS table has been added.'
			PRINT ''
		END
		ELSE
			PRINT '**** R51117 TAGS already exists'
			PRINT ''
		go 
	 
	 If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SITECONTROLTAGS')
		BEGIN
		PRINT '**** R51117  Adding table SITECONTROLTAGS.' 
			CREATE TABLE dbo.SITECONTROLTAGS
			 (
				SITECONTROLID  int  NOT NULL ,
				TAGID  int  NOT NULL ,
				LOGUSERID  nvarchar(50)  NULL ,
				LOGIDENTITYID  int  NULL ,
				LOGTRANSACTIONNO  int  NULL ,
				LOGDATETIMESTAMP  datetime  NULL ,
				LOGAPPLICATION  nvarchar(128)  NULL ,
				LOGOFFICEID  int  NULL 
			 )
			exec sc_AssignTableSecurity 'SITECONTROLTAGS'

			PRINT '**** R51117 SITECONTROLTAGS table has been added.'
			PRINT ''
		END
		ELSE
			PRINT '**** R51117 SITECONTROLTAGS already exists'
			PRINT ''
		go 
	 
	 
	If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RELEASEVERSIONS')
		BEGIN
		PRINT '**** R51117  Adding table RELEASEVERSIONS.'
			 CREATE TABLE dbo.RELEASEVERSIONS
			 (
				VERSIONID  int  IDENTITY (1,1)  NOT FOR REPLICATION,
				VERSIONNAME  nvarchar(50)  NOT NULL ,
				RELEASEDATE  datetime  NULL ,
				SEQUENCE  int  NULL ,
				LOGUSERID  nvarchar(50)  NULL ,
				LOGIDENTITYID  int  NULL ,
				LOGTRANSACTIONNO  int  NULL ,
				LOGDATETIMESTAMP  datetime  NULL ,
				LOGAPPLICATION  nvarchar(128)  NULL ,
				LOGOFFICEID  int  NULL 
			 )
			 exec sc_AssignTableSecurity 'RELEASEVERSIONS'

			PRINT '**** R51117 RELEASEVERSIONS table has been added.'
			PRINT ''
		END
		ELSE
			PRINT '**** R51117 RELEASEVERSIONS already exists'
			PRINT ''
		go 
		 
		
	/*** R51117 Add column SITECONTROL.ID          ***/      

	If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SITECONTROL' AND COLUMN_NAME = 'ID')
			  BEGIN   
				PRINT '**** R51117 Adding column SITECONTROL.ID.'           
				ALTER TABLE SITECONTROL ADD ID  int  IDENTITY (1,1)  NOT FOR REPLICATION
				PRINT '**** R51117 SITECONTROL.ID column has been added.'
			 END
			 ELSE   
				PRINT '**** R51117 SITECONTROL.ID already exists'
				PRINT ''
			 go

	/*** R51117 Add column SITECONTROL.VERSIONID          ***/      

	If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SITECONTROL' AND COLUMN_NAME = 'VERSIONID')
			  BEGIN   
				PRINT '**** R51117 Adding column SEARCHRESULT.VERSIONID.'           
				ALTER TABLE SITECONTROL ADD VERSIONID int  NULL 
				PRINT '**** R51117 SITECONTROL.VERSIONID column has been added.'
			 END
			 ELSE   
				PRINT '**** R51117 SITECONTROL.VERSIONID already exists'
				PRINT ''
			 go


	/*** R51117 Add column SITECONTROL.NOTES                                                                                                    ***/      

	If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SITECONTROL' AND COLUMN_NAME = 'NOTES')
			  BEGIN   
				PRINT '**** R51117 Adding column SEARCHRESULT.NOTES.'           
				ALTER TABLE SITECONTROL ADD NOTES nvarchar(max)  NULL
				PRINT '**** R51117 SITECONTROL.NOTES column has been added.'
			 END
			 ELSE   
				PRINT '**** R51117 SITECONTROL.NOTES already exists'
				PRINT ''
			 go


	 /*** R51117 Add column SITECONTROL.INITIALVALUE                                                                                                    ***/      

	If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SITECONTROL' AND COLUMN_NAME = 'INITIALVALUE')
			  BEGIN   
				PRINT '**** R51117 Adding column SEARCHRESULT.INITIALVALUE.'           
				ALTER TABLE SITECONTROL ADD INITIALVALUE nvarchar(254)  NULL 				 
				PRINT '**** R51117 SITECONTROL.INITIALVALUE column has been added.'
			 END
			 ELSE   
				PRINT '**** R51117 SITECONTROL.INITIALVALUE already exists'
				PRINT ''
			 GO
             
			 EXEC ipu_UtilGenerateAuditTriggers 'SITECONTROL'
			 GO

     
   
     
     
	 
	 if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'SITECONTROL' and CONSTRAINT_NAME = 'R_81870')
		begin
			PRINT 'Dropping foreign key constraint SITECONTROL.R_81870...'
			ALTER TABLE SITECONTROL DROP CONSTRAINT R_81870
		end
	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'SITECONTROLCOMPONENTS' and CONSTRAINT_NAME = 'R_81866')
		begin
			PRINT 'Dropping foreign key constraint SITECONTROLCOMPONENTS.R_81866...'
			ALTER TABLE SITECONTROLCOMPONENTS DROP CONSTRAINT R_81866
		end
	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'SITECONTROLCOMPONENTS' and CONSTRAINT_NAME = 'R_81867')
		begin
			PRINT 'Dropping foreign key constraint SITECONTROLCOMPONENTS.R_81867...'
			ALTER TABLE SITECONTROLCOMPONENTS DROP CONSTRAINT R_81867
		end
	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'SITECONTROLTAGS' and CONSTRAINT_NAME = 'R_81868')
		begin
			PRINT 'Dropping foreign key constraint SITECONTROLTAGS.R_81868...'
			ALTER TABLE SITECONTROLTAGS DROP CONSTRAINT R_81868
		end
	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'SITECONTROLTAGS' and CONSTRAINT_NAME = 'R_881869')
		begin
			PRINT 'Dropping foreign key constraint SITECONTROLTAGS.R_881869...'
			ALTER TABLE SITECONTROLTAGS DROP CONSTRAINT R_881869
		end
			go
			
	 if exists (select * from sysindexes where name = 'XAK1SITECONTROL')
	begin
		 PRINT 'Dropping index SITECONTROL.XAK1SITECONTROL ...'
		 DROP INDEX SITECONTROL.XAK1SITECONTROL
	end
			PRINT 'Adding index SITECONTROL.XAK1SITECONTROL ...'
			CREATE  UNIQUE INDEX XAK1SITECONTROL ON SITECONTROL
			(
				ID  ASC
			)
			go

	 IF NOT EXISTS (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'COMPONENTS' and CONSTRAINT_NAME = 'XPKCOMPONENTS')
		BEGIN
        PRINT 'Adding primary key constraint COMPONENTS.XPKCOMPONENTS...'
			 ALTER TABLE dbo.COMPONENTS
				 WITH NOCHECK ADD CONSTRAINT  XPKCOMPONENTS PRIMARY KEY   NONCLUSTERED (COMPONENTID  ASC)
			
		END
        ELSE
			PRINT '...COMPONENTS.XPKCOMPONENTS primary key constraint already exists'
			GO


	IF NOT EXISTS (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'RELEASEVERSIONS' and CONSTRAINT_NAME = 'XPKRELEASEVERSIONS')
		BEGIN
        PRINT 'Adding primary key constraint RELEASEVERSIONS.XPKRELEASEVERSIONS...'
			ALTER TABLE dbo.RELEASEVERSIONS
				 WITH NOCHECK ADD CONSTRAINT  XPKRELEASEVERSIONS PRIMARY KEY   NONCLUSTERED (VERSIONID  ASC)			
		END
        ELSE
			PRINT '...RELEASEVERSIONS.XPKRELEASEVERSIONS primary key constraint already exists'			
			GO


	if NOT EXISTS (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'SITECONTROLCOMPONENTS' and CONSTRAINT_NAME = 'XPKSITECONTROLCOMPONENTS')
		begin
			PRINT 'Adding primary key constraint SITECONTROLCOMPONENTS.XPKSITECONTROLCOMPONENTS...'
			ALTER TABLE dbo.SITECONTROLCOMPONENTS
				 WITH NOCHECK ADD CONSTRAINT  XPKSITECONTROLCOMPONENTS PRIMARY KEY   NONCLUSTERED (COMPONENTID  ASC,SITECONTROLID  ASC)
		end
		 ELSE
			PRINT '...SITECONTROLCOMPONENTS.XPKSITECONTROLCOMPONENTS primary key constraint already exists'			
			GO

	if NOT EXISTS (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'SITECONTROLTAGS' and CONSTRAINT_NAME = 'XPKSITECONTROLTAGS')
		begin
			PRINT 'Adding primary key constraint SITECONTROLTAGS.XPKSITECONTROLTAGS...'
			ALTER TABLE dbo.SITECONTROLTAGS
				 WITH NOCHECK ADD CONSTRAINT  XPKSITECONTROLTAGS PRIMARY KEY   NONCLUSTERED (TAGID  ASC,SITECONTROLID  ASC)
		end
		ELSE
			PRINT '...SITECONTROLTAGS.XPKSITECONTROLTAGS primary key constraint already exists'			
			GO


	if NOT EXISTS (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'TAGS' and CONSTRAINT_NAME = 'XPKTAGS')
		BEGIN
        PRINT 'Adding primary key constraint TAGS.XPKTAGS...'
			ALTER TABLE dbo.TAGS
				 WITH NOCHECK ADD CONSTRAINT  XPKTAGS PRIMARY KEY   NONCLUSTERED (TAGID  ASC)
		end
			ELSE
			PRINT '...TAGS.XPKTAGS primary key constraint already exists'			
			GO

		PRINT 'Adding foreign key constraint SITECONTROL.R_81870...'
		ALTER TABLE dbo.SITECONTROL
			 WITH NOCHECK ADD CONSTRAINT  R_81870 FOREIGN KEY (VERSIONID) REFERENCES dbo.RELEASEVERSIONS(VERSIONID)
			 NOT FOR REPLICATION
		go
		
		PRINT 'Adding foreign key constraint SITECONTROLCOMPONENTS.R_81866...'
		ALTER TABLE dbo.SITECONTROLCOMPONENTS
			 WITH NOCHECK ADD CONSTRAINT  R_81866 FOREIGN KEY (SITECONTROLID) REFERENCES dbo.SITECONTROL(ID)
				ON DELETE CASCADE
				ON UPDATE CASCADE
			 NOT FOR REPLICATION
		go

		PRINT 'Adding foreign key constraint SITECONTROLCOMPONENTS.R_81867...'
		ALTER TABLE dbo.SITECONTROLCOMPONENTS
			 WITH NOCHECK ADD CONSTRAINT  R_81867 FOREIGN KEY (COMPONENTID) REFERENCES dbo.COMPONENTS(COMPONENTID)
				ON DELETE CASCADE
				ON UPDATE CASCADE
			 NOT FOR REPLICATION
		go

		PRINT 'Adding foreign key constraint SITECONTROLTAGS.R_81868...'
		ALTER TABLE dbo.SITECONTROLTAGS
			 WITH NOCHECK ADD CONSTRAINT  R_81868 FOREIGN KEY (TAGID) REFERENCES dbo.TAGS(TAGID)
				ON DELETE CASCADE
				ON UPDATE CASCADE
			 NOT FOR REPLICATION
		go

		PRINT 'Adding foreign key constraint SITECONTROLTAGS.R_881869...'
		ALTER TABLE dbo.SITECONTROLTAGS
			 WITH NOCHECK ADD CONSTRAINT  R_881869 FOREIGN KEY (SITECONTROLID) REFERENCES dbo.SITECONTROL(ID)
				ON DELETE CASCADE
				ON UPDATE CASCADE
			 NOT FOR REPLICATION
		go
		
	if exists (select * from sysindexes where name = 'XAK1COMPONENTS')
	begin
		 PRINT 'Dropping index COMPONENTS.XAK1COMPONENTS ...'
		 DROP INDEX COMPONENTS.XAK1COMPONENTS
	end
			PRINT 'Adding index COMPONENTS.XAK1COMPONENTS ...'
			CREATE  UNIQUE INDEX XAK1COMPONENTS ON COMPONENTS
			(
				COMPONENTNAME  ASC
			)
			go

	if exists (select * from sysindexes where name = 'XAK1RELEASEVERSIONS')
	begin
		 PRINT 'Dropping index RELEASEVERSIONS.XAK1RELEASEVERSIONS ...'
		 DROP INDEX RELEASEVERSIONS.XAK1RELEASEVERSIONS
	end
			PRINT 'Adding index RELEASEVERSIONS.XAK1RELEASEVERSIONS ...'
			CREATE  UNIQUE INDEX XAK1RELEASEVERSIONS ON RELEASEVERSIONS
			(
				VERSIONNAME  ASC
			)
			go


	if exists (select * from sysindexes where name = 'XAK1TAGS')
	begin
		 PRINT 'Dropping index TAGS.XAK1TAGS ...'
		 DROP INDEX TAGS.XAK1TAGS
	end
		PRINT 'Adding index TAGS.XAK1TAGS ...'
		CREATE  UNIQUE INDEX XAK1TAGS ON TAGS
		(
			TAGNAME  ASC
		)
		go


	/** DR-42320 Adding column COMPONENT.INTERNALNAME	**/

	If NOT exists (SELECT *
	FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'COMPONENTS'AND COLUMN_NAME = 'INTERNALNAME')
		BEGIN
			PRINT '**** DR-42320 Adding column COMPONENT.INTERNALNAME'
			ALTER TABLE COMPONENTS ADD INTERNALNAME nvarchar(100) NOT NULL default ''
			PRINT '**** DR-42320 Column COMPONENT.INTERNALNAME added'		
		END
	ELSE
		BEGIN
			PRINT '**** DR-42320 Column COMPONENT.INTERNALNAME exists already'
		END
	GO
	EXEC ipu_UtilGenerateAuditTriggers 'COMPONENTS'
	GO

	/** DR-42320 Updating column COMPONENT.INTERNALNAME	and removing default constraint**/

	If exists (SELECT 1 FROM COMPONENTS WHERE INTERNALNAME = '')
    BEGIN
    PRINT '**** DR-42320 Populating column COMPONENT.INTERNALNAME from COMPONENT.COMPONENTNAME'
    Update COMPONENTS set INTERNALNAME = COMPONENTNAME WHERE INTERNALNAME = ''
    Declare @ConstraintName nvarchar(200)
    Select @ConstraintName = d.Name
    from sys.tables t
      join sys.default_constraints d on (d.parent_object_id = t.object_id)
      join sys.columns c on (c.object_id = t.object_id
        and c.column_id = d.parent_column_id)
    where t.name = 'COMPONENTS'
      and c.name = 'INTERNALNAME'
    IF @ConstraintName IS NOT NULL
    
    EXEC('ALTER TABLE COMPONENTS DROP CONSTRAINT ' + @ConstraintName)
    PRINT '**** DR-42320 Column COMPONENT.INTERNALNAME populated' 

    EXEC ipu_UtilGenerateAuditTriggers 'COMPONENTS'
END
GO