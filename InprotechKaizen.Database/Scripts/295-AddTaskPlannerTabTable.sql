﻿/*** DR-66895 Adding table TASKPLANNERTAB ***/

If NOT exists (SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'TASKPLANNERTAB')
		BEGIN
	PRINT '**** DR-66895  Adding table TASKPLANNERTAB.'
	CREATE TABLE dbo.TASKPLANNERTAB
	(
		ID int IDENTITY ( 1,1 ) NOT FOR REPLICATION NOT NULL ,
		QUERYID int NOT NULL ,
		IDENTITYID int NULL ,
		TABSEQUENCE int NOT NULL ,
		LOGUSERID nvarchar(50) NULL ,
		LOGIDENTITYID int NULL ,
		LOGTRANSACTIONNO int NULL ,
		LOGDATETIMESTAMP datetime NULL ,
		LOGAPPLICATION nvarchar(128) NULL ,
		LOGOFFICEID int NULL
	)
	exec sc_AssignTableSecurity 'TASKPLANNERTAB'
	PRINT '**** DR-66895 TASKPLANNERTAB table has been added.'
	PRINT ''
END
		ELSE
			PRINT '**** DR-66895 Table TASKPLANNERTAB already exists'
PRINT ''
go


if not exists (select *
from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
where TABLE_NAME = 'TASKPLANNERTAB' and CONSTRAINT_NAME = 'XPKTASKPLANNERTAB')
	begin
	PRINT 'Adding primary key constraint TASKPLANNERTAB.XPKTASKPLANNERTAB...'
	ALTER TABLE dbo.TASKPLANNERTAB
	 WITH NOCHECK ADD CONSTRAINT XPKTASKPLANNERTAB PRIMARY KEY  CLUSTERED (ID ASC)
end
go


if not exists (select *
from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
where TABLE_NAME = 'TASKPLANNERTAB' and CONSTRAINT_NAME = 'R_81939')
	begin
	PRINT 'Adding foreign key constraint TASKPLANNERTAB.R_81939...'
	ALTER TABLE dbo.TASKPLANNERTAB
	 WITH NOCHECK ADD CONSTRAINT R_81939 FOREIGN KEY (QUERYID) REFERENCES dbo.QUERY(QUERYID)
		ON DELETE CASCADE
	 NOT FOR REPLICATION
end
go


if not exists (select *
from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
where TABLE_NAME = 'TASKPLANNERTAB' and CONSTRAINT_NAME = 'R_81940')
	begin
	PRINT 'Adding foreign key constraint TASKPLANNERTAB.R_81940...'
	ALTER TABLE dbo.TASKPLANNERTAB
	 WITH NOCHECK ADD CONSTRAINT R_81940 FOREIGN KEY (IDENTITYID) REFERENCES dbo.USERIDENTITY(IDENTITYID)		
	 NOT FOR REPLICATION
end
go


/*** DR-66895 Genarating audit triggers ***/

IF dbo.fn_IsAuditSchemaConsistent('TASKPLANNERTAB') = 0
BEGIN
   EXEC ipu_UtilGenerateAuditTriggers 'TASKPLANNERTAB'
END
GO


/*** DR-66895 Add data into AUDITLOGTABLES.TABLENAME = TASKPLANNERTAB ***/

IF NOT exists (select *
from AUDITLOGTABLES
where TABLENAME = 'TASKPLANNERTAB')
		begin
	PRINT '**** DR-66895  Inserting data into AUDITLOGTABLE.TABLENAME = TASKPLANNERTAB'
	Insert AUDITLOGTABLES
		(TABLENAME, LOGFLAG, REPLICATEFLAG)
	Values
		('TASKPLANNERTAB', 0, 0)
	PRINT '**** DR-66895  Data has been successfully added to AUDITLOGTABLES table.'
	PRINT ''
END
	ELSE
		PRINT '**** DR-66895  AUDITLOGTABLES.TASKPLANNERTAB already exists.'
PRINT ''
	go