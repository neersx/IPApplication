/***************************************************************************/
/*** 		DR-46191  Adding table VATRETURN 			***/
/**************************************************************************/

If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'VATRETURN')
BEGIN
	PRINT '**** DR-46191  Adding table VATRETURN.'
	CREATE TABLE dbo.VATRETURN
	(
		ID int NOT NULL IDENTITY ( 1,1 )  NOT FOR REPLICATION,
		NAMENO int NOT NULL ,
		OBLIGATIONPERIODID nvarchar(100) NOT NULL ,
		DATA nvarchar(max) NULL ,
		SUBMITTED bit NOT NULL DEFAULT 0,
		LOGUSERID nvarchar(50) NULL ,
		LOGIDENTITYID int NULL ,
		LOGTRANSACTIONNO int NULL ,
		LOGDATETIMESTAMP datetime NULL ,
		LOGAPPLICATION nvarchar(128) NULL ,
		LOGOFFICEID int NULL
	)
	exec sc_AssignTableSecurity 'VATRETURN'
	PRINT '**** DR-46191 VATRETURN table has been added.'
	PRINT ''
END
ELSE
	PRINT '**** DR-46191 Table VATRETURN already exists'
	PRINT ''
go


if not exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'VATRETURN' and CONSTRAINT_NAME = 'XPKVATRETURN')
begin
	PRINT 'Adding primary key constraint VATRETURN.XPKVATRETURN...'
	ALTER TABLE dbo.VATRETURN
	WITH NOCHECK ADD CONSTRAINT XPKVATRETURN PRIMARY KEY  CLUSTERED (ID ASC)
end
go


if not exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'VATRETURN' and CONSTRAINT_NAME = 'R_81930')
begin
	PRINT 'Adding foreign key constraint VATRETURN.R_81930...'
	ALTER TABLE dbo.VATRETURN
	WITH NOCHECK ADD CONSTRAINT R_81930 FOREIGN KEY (NAMENO) REFERENCES dbo.NAME(NAMENO)
	NOT FOR REPLICATION
end
go


/****************************************************************************/
/*** DR-46191 Add data into AUDITLOGTABLES.TABLENAME = VATRETURN ***/
/****************************************************************************/

IF NOT exists (select * from AUDITLOGTABLES where TABLENAME = 'VATRETURN')
begin
	PRINT '**** DR-46191  Inserting data into AUDITLOGTABLE.TABLENAME = VATRETURN'

	Insert AUDITLOGTABLES(TABLENAME, LOGFLAG, REPLICATEFLAG)
	Values ('VATRETURN', 0, 0)
	
	PRINT '**** DR-46191  Data has been successfully added to AUDITLOGTABLES table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-46191  AUDITLOGTABLES.VATRETURN already exists.'
PRINT ''
go