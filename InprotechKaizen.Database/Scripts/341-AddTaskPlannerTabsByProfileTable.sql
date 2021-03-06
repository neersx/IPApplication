/*******************************************************/
/*** DR-72138 Adding table TASKPLANNERTABSBYPROFILE ***/
/******************************************************/

If NOT exists (SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'TASKPLANNERTABSBYPROFILE')
		BEGIN
	PRINT '**** DR-72138  Adding table TASKPLANNERTABSBYPROFILE.'
	CREATE TABLE dbo.TASKPLANNERTABSBYPROFILE
	(
		ID int IDENTITY ( 1,1 ) NOT FOR REPLICATION NOT NULL ,
		PROFILEID int NULL ,
		TABSEQUENCE int NOT NULL ,
		QUERYID int NOT NULL ,
		LOGUSERID nvarchar(50) NULL ,
		LOGIDENTITYID int NULL ,
		LOGTRANSACTIONNO int NULL ,
		LOGDATETIMESTAMP datetime NULL ,
		LOGAPPLICATION nvarchar(128) NULL ,
		LOGOFFICEID int NULL
	)
	exec sc_AssignTableSecurity 'TASKPLANNERTABSBYPROFILE'
	PRINT '**** DR-72138 TASKPLANNERTABSBYPROFILE table has been added.'
	PRINT ''
END
		ELSE
			PRINT '**** DR-72138 Table TASKPLANNERTABSBYPROFILE already exists'
PRINT ''
go

/*** DR-72138 Adding primary key constraint TASKPLANNERTABSBYPROFILE.XPKTASKPLANNERTABSBYPROFILE ***/

if not exists (select *
from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
where TABLE_NAME = 'TASKPLANNERTABSBYPROFILE' and CONSTRAINT_NAME = 'XPKTASKPLANNERTABSBYPROFILE')
	begin
	PRINT 'Adding primary key constraint TASKPLANNERTABSBYPROFILE.XPKTASKPLANNERTABSBYPROFILE...'
	ALTER TABLE dbo.TASKPLANNERTABSBYPROFILE
	 WITH NOCHECK ADD CONSTRAINT XPKTASKPLANNERTABSBYPROFILE PRIMARY KEY  CLUSTERED (ID ASC)
end
go

/*** DR-72138 Adding foreign key constraint TASKPLANNERTABSBYPROFILE.R_81943 ***/

if not exists (select *
from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
where TABLE_NAME = 'TASKPLANNERTABSBYPROFILE' and CONSTRAINT_NAME = 'R_81943')
	begin
	PRINT 'Adding foreign key constraint TASKPLANNERTABSBYPROFILE.R_81943...'
	ALTER TABLE dbo.TASKPLANNERTABSBYPROFILE
	 WITH NOCHECK ADD CONSTRAINT R_81943 FOREIGN KEY (PROFILEID) REFERENCES dbo.PROFILES(PROFILEID)
	 NOT FOR REPLICATION
end
go

/*** DR-72138 Adding foreign key constraint TASKPLANNERTABSBYPROFILE.R_81944 ***/

if not exists (select *
from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
where TABLE_NAME = 'TASKPLANNERTABSBYPROFILE' and CONSTRAINT_NAME = 'R_81944')
	begin
	PRINT 'Adding foreign key constraint TASKPLANNERTABSBYPROFILE.R_81944...'
	ALTER TABLE dbo.TASKPLANNERTABSBYPROFILE
	 WITH NOCHECK ADD CONSTRAINT R_81944 FOREIGN KEY (QUERYID) REFERENCES dbo.QUERY(QUERYID)
	 NOT FOR REPLICATION
end
go

/*** DR-72138 Genarating audit triggers ***/

IF dbo.fn_IsAuditSchemaConsistent('TASKPLANNERTABSBYPROFILE') = 0
BEGIN
   PRINT 'DR-72138 Genarating audit triggers for table TASKPLANNERTABSBYPROFILE'
   EXEC ipu_UtilGenerateAuditTriggers 'TASKPLANNERTABSBYPROFILE'
   PRINT 'DR-72138 audit triggers generated successfully for table TASKPLANNERTABSBYPROFILE'
   PRINT ''
END
GO

/*** DR-72138 Add data into AUDITLOGTABLES.TABLENAME = TASKPLANNERTABSBYPROFILE ***/

IF NOT exists (select *
from AUDITLOGTABLES
where TABLENAME = 'TASKPLANNERTABSBYPROFILE')
		begin
	PRINT '**** DR-72138  Inserting data into AUDITLOGTABLE.TABLENAME = TASKPLANNERTABSBYPROFILE'
	Insert AUDITLOGTABLES
		(TABLENAME, LOGFLAG, REPLICATEFLAG)
	Values
		('TASKPLANNERTABSBYPROFILE', 0, 0)
	PRINT '**** DR-72138  Data has been successfully added to AUDITLOGTABLES table.'
	PRINT ''
END
	ELSE
		PRINT '**** DR-72138  AUDITLOGTABLES.TASKPLANNERTABSBYPROFILE already exists.'
PRINT ''
	go