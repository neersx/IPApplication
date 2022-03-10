/****************************************************************************/
/*** RFC70516 Adding table CPAGLOBALIDENTIFIER ***/	
/****************************************************************************/

If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'CPAGLOBALIDENTIFIER')
		BEGIN
		PRINT '**** RFC70516  Adding table CPAGLOBALIDENTIFIER.'
		CREATE TABLE dbo.CPAGLOBALIDENTIFIER
		( 
			ID                   int  NOT NULL  IDENTITY ( 1,1 )  NOT FOR REPLICATION,
			CASEID               int  NOT NULL,
			INNOGRAPHYID         nvarchar(50)  NOT NULL ,
			ISACTIVE             bit  NOT NULL DEFAULT  1,
			LOGUSERID            nvarchar(50)  NULL ,
			LOGIDENTITYID        int  NULL ,
			LOGTRANSACTIONNO     int  NULL ,
			LOGDATETIMESTAMP     datetime  NULL ,
			LOGAPPLICATION       nvarchar(128)  NULL ,
			LOGOFFICEID          int  NULL 
		)
			exec sc_AssignTableSecurity 'CPAGLOBALIDENTIFIER'			 
			PRINT '**** RFC70516 CPAGLOBALIDENTIFIER table has been added.'
			PRINT ''
		END
		ELSE
			PRINT '**** RFC70516 Table CPAGLOBALIDENTIFIER already exists'
			PRINT ''
go 

if not exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'CPAGLOBALIDENTIFIER' and CONSTRAINT_NAME = 'R_81900')
	begin
		PRINT 'Adding foreign key constraint CPAGLOBALIDENTIFIER.R_81900...'
		ALTER TABLE dbo.CPAGLOBALIDENTIFIER
		WITH NOCHECK ADD CONSTRAINT R_81900 FOREIGN KEY (CASEID) REFERENCES dbo.CASES(CASEID)
		ON DELETE CASCADE
		NOT FOR REPLICATION
	end
	else
			PRINT '**** Foreign key constraint CPAGLOBALIDENTIFIER.R_81900 already exists'
			PRINT ''
GO

/****************************************************************************/
/*** RFC72025 Add Unique Clustered index on CPAGlobalIdentifier ***/	
/****************************************************************************/
if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'CPAGLOBALIDENTIFIER' and CONSTRAINT_NAME = 'XPKCPAGLOBALIDENTIFIER')
	begin
		PRINT 'Dropping primary key constraint CPAGLOBALIDENTIFIER.XPKCPAGLOBALIDENTIFIER...'
		ALTER TABLE CPAGLOBALIDENTIFIER DROP CONSTRAINT XPKCPAGLOBALIDENTIFIER
	end
go

PRINT 'Creating Nonclustered primary key constraint CPAGLOBALIDENTIFIER.XPKCPAGLOBALIDENTIFIER...'
ALTER TABLE dbo.CPAGLOBALIDENTIFIER
	 WITH NOCHECK ADD CONSTRAINT XPKCPAGLOBALIDENTIFIER PRIMARY KEY  NONCLUSTERED (ID ASC)
go


if not exists (select * from sysindexes where name = 'XAK1CPAGLOBALIDENTIFIER')
begin
	PRINT 'Creating index CPAGLOBALIDENTIFIER.XAK1CPAGLOBALIDENTIFIER ...'

	CREATE UNIQUE CLUSTERED INDEX XAK1CPAGLOBALIDENTIFIER ON CPAGLOBALIDENTIFIER
	( 
		CASEID          ASC
	)
end
go

if not exists (select * from sysindexes where name = 'XIE1CPAGLOBALIDENTIFIER')
begin
	 PRINT 'Creating index CPAGLOBALIDENTIFIER.XIE1CPAGLOBALIDENTIFIER ...'

	 CREATE NONCLUSTERED INDEX XIE1CPAGLOBALIDENTIFIER ON CPAGLOBALIDENTIFIER
	( 
		INNOGRAPHYID          ASC
	)
end
go

IF dbo.fn_IsAuditSchemaConsistent('CPAGLOBALIDENTIFIER') = 0
BEGIN
   EXEC ipu_UtilGenerateAuditTriggers 'CPAGLOBALIDENTIFIER'
END
GO
