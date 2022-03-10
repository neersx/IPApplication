/****************************************************************************/
/*** RFC72647 Adding table FILECASE ***/	
/****************************************************************************/

If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'FILECASE')
		BEGIN
		PRINT '**** RFC72647  Adding table FILECASE.'
		CREATE TABLE dbo.FILECASE
		( 
			ID                   int  NOT NULL  IDENTITY ( 1,1 )  NOT FOR REPLICATION,
			CASEID               int  NOT NULL,
			IPTYPE               NVARCHAR(50)  NOT NULL,
			COUNTRYCODE			 NVARCHAR(3) NULL,
			PARENTCASEID		 INT NULL,
			[STATUS]			 NVARCHAR(50)  NULL,
			LOGUSERID            NVARCHAR(50)  NULL ,
			LOGIDENTITYID        int  NULL ,
			LOGTRANSACTIONNO     int  NULL ,
			LOGDATETIMESTAMP     datetime  NULL ,
			LOGAPPLICATION       nvarchar(128)  NULL ,
			LOGOFFICEID          int  NULL 
		)
			exec sc_AssignTableSecurity 'FILECASE'			 
			PRINT '**** RFC72647 FILECASE table has been added.'
			PRINT ''
		END
		ELSE IF NOT EXISTS(SELECT *  FROM   INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_NAME = 'FILECASE' AND COLUMN_NAME = 'STATUS') 
		BEGIN
			ALTER TABLE FILECASE
			ADD [STATUS] NVARCHAR(50) NULL
			PRINT '**** RFC72367 Table FILECASE altered to add Status column'
			PRINT ''
		END
		ELSE 
			PRINT '**** RFC72647 Table FILECASE already exists'
			PRINT ''
go 

if not exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'FILECASE' and CONSTRAINT_NAME = 'R_81903')
	begin
		PRINT 'Adding foreign key constraint FILECASE.R_81903...'
		ALTER TABLE dbo.FILECASE
		WITH NOCHECK ADD CONSTRAINT R_81903 FOREIGN KEY (CASEID) REFERENCES dbo.CASES(CASEID)
		ON DELETE CASCADE
		NOT FOR REPLICATION
	end
	else
			PRINT '**** Foreign key constraint FILECASE.R_81903 already exists'
			PRINT ''
GO

if not exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'FILECASE' and CONSTRAINT_NAME = 'R_81905')
	begin
		PRINT 'Adding foreign key constraint FILECASE.R_81905...'
		ALTER TABLE dbo.FILECASE
		WITH NOCHECK ADD CONSTRAINT R_81905 FOREIGN KEY (PARENTCASEID) REFERENCES dbo.CASES(CASEID)
		NOT FOR REPLICATION
	end
	else
			PRINT '**** Foreign key constraint FILECASE.R_81905 already exists'
			PRINT ''
GO

if NOT EXISTS (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'FILECASE' and CONSTRAINT_NAME = 'R_81904')
	BEGIN
    PRINT 'Adding foreign key constraint FILECASE.R_81904...'
		
        ALTER TABLE dbo.FILECASE
		WITH NOCHECK ADD CONSTRAINT R_81904 FOREIGN KEY (COUNTRYCODE) REFERENCES dbo.COUNTRY(COUNTRYCODE)
		ON DELETE CASCADE
		NOT FOR REPLICATION
	end
	else
			PRINT '**** Foreign key constraint FILECASE.R_81904 already exists'
			PRINT ''
Go


/****************************************************************************/
/*** RFC72025 Add Unique Clustered index on FILECASE ***/	
/****************************************************************************/
if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'FILECASE' and CONSTRAINT_NAME = 'XPKFILECASE')
	begin
		PRINT 'Dropping primary key constraint FILECASE.XPKFILECASE...'
		ALTER TABLE FILECASE DROP CONSTRAINT XPKFILECASE
	end
go

PRINT 'Creating Nonclustered primary key constraint FILECASE.XPKFILECASE...'
ALTER TABLE dbo.FILECASE
	 WITH NOCHECK ADD CONSTRAINT XPKFILECASE PRIMARY KEY  CLUSTERED (ID ASC)
go


IF exists (SELECT * FROM sysindexes WHERE name = 'XAK1FILECASE')
BEGIN
    PRINT 'Dropping index FILECASE.XAK1FILECASE ...'
    DROP INDEX FILECASE.XAK1FILECASE
END
GO

if not exists (select * from sysindexes where name = 'XAK1FILECASE')
begin
	PRINT 'Creating index FILECASE.XAK1FILECASE ...'
CREATE UNIQUE NONCLUSTERED INDEX XAK1FILECASE ON FILECASE
	( 
		CASEID                ASC,
		IPTYPE                ASC
	)
end
go

IF exists (SELECT * FROM sysindexes WHERE name = 'XAK2FILECASE')
BEGIN
    PRINT 'Dropping index FILECASE.XAK2FILECASE ...'
    DROP INDEX FILECASE.XAK2FILECASE
END
GO
      
exec ipu_UtilGenerateAuditTriggers 'FILECASE'
GO


/***  RFC72647  Add data into AUDITLOGTABLES.TABLENAME = FILECASE		***/   
	
	IF NOT exists (select * from AUDITLOGTABLES where TABLENAME = 'FILECASE')
		begin
			PRINT '**** RFC72647  Inserting data into AUDITLOGTABLE.TABLENAME = FILECASE'
			Insert AUDITLOGTABLES (TABLENAME, LOGFLAG, REPLICATEFLAG)
			Values ('FILECASE', 0, 0)
			PRINT '**** RFC72647  Data has been successfully added to AUDITLOGTABLES table.'
			PRINT ''	
		END
	ELSE
		PRINT '**** RFC72647  AUDITLOGTABLES.FILECASE already exists.'
		PRINT ''
	go


