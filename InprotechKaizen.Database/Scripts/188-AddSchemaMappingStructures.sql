/****************************************************************************/
/*** RFC73084 Schema Mapping data should be persisted in the main database ***/	
/****************************************************************************/


/*** RFC73084  Adding table SCHEMAPACKAGES ***/	

If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SCHEMAPACKAGES')
		BEGIN
		PRINT '**** RFC73084  Adding table SCHEMAPACKAGES.'
		CREATE TABLE dbo.SCHEMAPACKAGES
		( 
			ID                   int  NOT NULL  IDENTITY ( 1,1 )  NOT FOR REPLICATION,
			NAME                 nvarchar(max)  NOT NULL ,
			ISVALID              bit  NOT NULL ,
			LOGUSERID            nvarchar(50)  NULL ,
			LOGIDENTITYID        int  NULL ,
			LOGTRANSACTIONNO     int  NULL ,
			LOGDATETIMESTAMP     datetime  NULL ,
			LOGAPPLICATION       nvarchar(128)  NULL ,
			LOGOFFICEID          int  NULL 
		)
			exec sc_AssignTableSecurity 'SCHEMAPACKAGES'			 
			PRINT '**** RFC73084 SCHEMAPACKAGES table has been added.'
			PRINT ''
		END
		ELSE
			PRINT '**** RFC73084 Table SCHEMAPACKAGES already exists'
			PRINT ''
go 


if not exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'SCHEMAPACKAGES' and CONSTRAINT_NAME = 'XPKSCHEMAPACKAGES')
	begin
		PRINT 'Creating Nonclustered primary key constraint SCHEMAPACKAGES.XPKSCHEMAPACKAGES...'
		ALTER TABLE dbo.SCHEMAPACKAGES
		WITH NOCHECK ADD CONSTRAINT XPKSCHEMAPACKAGES PRIMARY KEY  CLUSTERED (ID ASC)
	end
go

IF dbo.fn_IsAuditSchemaConsistent('SCHEMAPACKAGES') = 0
BEGIN
   EXEC ipu_UtilGenerateAuditTriggers 'SCHEMAPACKAGES'
END
GO


/*** RFC73084  Adding table SCHEMAFILES ***/	

If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SCHEMAFILES')
		BEGIN
		PRINT '**** RFC73084  Adding table SCHEMAFILES.'
		CREATE TABLE dbo.SCHEMAFILES
		( 
			ID                   int  NOT NULL  IDENTITY ( 1,1 )  NOT FOR REPLICATION,
			NAME                 nvarchar(max)  NOT NULL ,
			CONTENT              nvarchar(max)  NOT NULL ,
			ISMAPPABLE           bit  NOT NULL ,
			SCHEMAPACKAGEID      int  NULL ,
			LOGUSERID            nvarchar(50)  NULL ,
			LOGIDENTITYID        int  NULL ,
			LOGTRANSACTIONNO     int  NULL ,
			LOGDATETIMESTAMP     datetime  NULL ,
			LOGAPPLICATION       nvarchar(128)  NULL ,
			LOGOFFICEID          int  NULL 
		)
			exec sc_AssignTableSecurity 'SCHEMAFILES'			 
			PRINT '**** RFC73084 SCHEMAFILES table has been added.'
			PRINT ''
		END
		ELSE
			PRINT '**** RFC73084 Table SCHEMAFILES already exists'
			PRINT ''
go 


if not exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'SCHEMAFILES' and CONSTRAINT_NAME = 'XPKSCHEMAFILES')
	begin
		PRINT 'Creating Nonclustered primary key constraint SCHEMAFILES.XPKSCHEMAFILES...'
		ALTER TABLE dbo.SCHEMAFILES
		WITH NOCHECK ADD CONSTRAINT XPKSCHEMAFILES PRIMARY KEY  CLUSTERED (ID ASC)
	end
go



if NOT EXISTS (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'SCHEMAFILES' and CONSTRAINT_NAME = 'R_81911')
	BEGIN
    PRINT 'Adding foreign key constraint SCHEMAFILES.R_81911...'
		
        ALTER TABLE dbo.SCHEMAFILES
		WITH NOCHECK ADD CONSTRAINT R_81911 FOREIGN KEY (SCHEMAPACKAGEID) REFERENCES dbo.SCHEMAPACKAGES(ID)		
		NOT FOR REPLICATION
	end
	else
			PRINT '**** Foreign key constraint SCHEMAFILES.R_81911 already exists'
			PRINT ''
Go

IF dbo.fn_IsAuditSchemaConsistent('SCHEMAFILES') = 0
BEGIN
   EXEC ipu_UtilGenerateAuditTriggers 'SCHEMAFILES'
END
GO

/*** RFC73084  Adding table SCHEMAMAPPINGS ***/	

If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SCHEMAMAPPINGS')
		BEGIN
		PRINT '**** RFC73084  Adding table SCHEMAMAPPINGS.'
		CREATE TABLE dbo.SCHEMAMAPPINGS
		( 
			ID                   int  NOT NULL  IDENTITY ( 1,1 )  NOT FOR REPLICATION,
			VERSION              int  NOT NULL ,
			NAME                 nvarchar(max)  NOT NULL ,
			CONTENT              nvarchar(max)  NULL ,
			SCHEMAPACKAGEID      int  NULL ,
			ROOTNODE             nvarchar(max)  NULL ,
			LOGUSERID            nvarchar(50)  NULL ,
			LOGIDENTITYID        int  NULL ,
			LOGTRANSACTIONNO     int  NULL ,
			LOGDATETIMESTAMP     datetime  NULL ,
			LOGAPPLICATION       nvarchar(128)  NULL ,
			LOGOFFICEID          int  NULL 
		)
			exec sc_AssignTableSecurity 'SCHEMAMAPPINGS'			 
			PRINT '**** RFC73084 SCHEMAMAPPINGS table has been added.'
			PRINT ''
		END
		ELSE
			PRINT '**** RFC73084 Table SCHEMAMAPPINGS already exists'
			PRINT ''
go 


if not exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'SCHEMAMAPPINGS' and CONSTRAINT_NAME = 'XPKSCHEMAMAPPINGS')
	begin
		PRINT 'Creating Nonclustered primary key constraint SCHEMAMAPPINGS.XPKSCHEMAMAPPINGS...'
		ALTER TABLE dbo.SCHEMAMAPPINGS
		WITH NOCHECK ADD CONSTRAINT XPKSCHEMAMAPPINGS PRIMARY KEY  CLUSTERED (ID ASC)
	end
go


if NOT EXISTS (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'SCHEMAMAPPINGS' and CONSTRAINT_NAME = 'R_81912')
	BEGIN
    PRINT 'Adding foreign key constraint SCHEMAMAPPINGS.R_81912...'
		
        ALTER TABLE dbo.SCHEMAMAPPINGS
		WITH NOCHECK ADD CONSTRAINT R_81912 FOREIGN KEY (SCHEMAPACKAGEID) REFERENCES dbo.SCHEMAPACKAGES(ID)	
		NOT FOR REPLICATION
	end
	else
			PRINT '**** Foreign key constraint SCHEMAMAPPINGS.R_81912 already exists'
			PRINT ''
Go

IF dbo.fn_IsAuditSchemaConsistent('SCHEMAMAPPINGS') = 0
BEGIN
   EXEC ipu_UtilGenerateAuditTriggers 'SCHEMAMAPPINGS'
END
GO


/***  RFC73084  Add data into AUDITLOGTABLES.TABLENAME = SCHEMAPACKAGES		***/   
	
	IF NOT exists (select * from AUDITLOGTABLES where TABLENAME = 'SCHEMAPACKAGES')
		begin
			PRINT '**** RFC73084  Inserting data into AUDITLOGTABLE.TABLENAME = SCHEMAPACKAGES'
			Insert AUDITLOGTABLES (TABLENAME, LOGFLAG, REPLICATEFLAG)
			Values ('SCHEMAPACKAGES', 0, 0)
			PRINT '**** RFC73084  Data has been successfully added to AUDITLOGTABLES table.'
			PRINT ''	
		END
	ELSE
		PRINT '**** RFC73084  AUDITLOGTABLES.SCHEMAPACKAGES already exists.'
		PRINT ''
	go	
	
/***  RFC73084  Add data into AUDITLOGTABLES.TABLENAME = SCHEMAFILES		***/   
	
	IF NOT exists (select * from AUDITLOGTABLES where TABLENAME = 'SCHEMAFILES')
		begin
			PRINT '**** RFC73084  Inserting data into AUDITLOGTABLE.TABLENAME = SCHEMAFILES'
			Insert AUDITLOGTABLES (TABLENAME, LOGFLAG, REPLICATEFLAG)
			Values ('SCHEMAFILES', 0, 0)
			PRINT '**** RFC73084  Data has been successfully added to AUDITLOGTABLES table.'
			PRINT ''	
		END
	ELSE
		PRINT '**** RFC73084  AUDITLOGTABLES.SCHEMAFILES already exists.'
		PRINT ''
	go	

/***  RFC73084  Add data into AUDITLOGTABLES.TABLENAME = SCHEMAMAPPINGS		***/   
	
	IF NOT exists (select * from AUDITLOGTABLES where TABLENAME = 'SCHEMAMAPPINGS')
		begin
			PRINT '**** RFC73084  Inserting data into AUDITLOGTABLE.TABLENAME = SCHEMAMAPPINGS'
			Insert AUDITLOGTABLES (TABLENAME, LOGFLAG, REPLICATEFLAG)
			Values ('SCHEMAMAPPINGS', 0, 0)
			PRINT '**** RFC73084  Data has been successfully added to AUDITLOGTABLES table.'
			PRINT ''	
		END
	ELSE
		PRINT '**** RFC73084  AUDITLOGTABLES.SCHEMAMAPPINGS already exists.'
		PRINT ''
	go		




