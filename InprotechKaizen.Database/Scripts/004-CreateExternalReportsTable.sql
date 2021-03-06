	/*** ST-142 Fixing naming issues for table EXTERNALREPORTS								***/	

	If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'EXTERNALREPORTS')
		BEGIN
			PRINT '**** RFC12508/ST-142  Adding table EXTERNALREPORTS.' 

				CREATE TABLE dbo.EXTERNALREPORTS
				 (
 					ID  int  IDENTITY (1,1)  NOT FOR REPLICATION,
 					TASKID  smallint  NOT NULL,
 					TITLE  nvarchar(256)  NOT NULL,
 					DESCRIPTION  nvarchar(1000)  NULL,
 					PATH  nvarchar(1000)  NOT NULL,
 					LOGUSERID  nvarchar(50)  NULL,
 					LOGIDENTITYID  int  NULL,
 					LOGTRANSACTIONNO  int  NULL,
 					LOGDATETIMESTAMP  datetime  NULL,
 					LOGAPPLICATION  nvarchar(128)  NULL,
 					LOGOFFICEID  int  NULL 
				 )
				
				exec sc_AssignTableSecurity 'EXTERNALREPORTS'

			PRINT '**** ST-142 EXTERNALREPORTS table has been added.'
			PRINT ''
		END
	ELSE
		PRINT '**** ST-142 EXTERNALREPORTS already exists'
	PRINT ''
	go 


	/*** ST-142 Adding primary key and foreign keys for table EXTERNALREPORTS				***/	


	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'EXTERNALREPORTS' and CONSTRAINT_NAME = 'XPKEXTERNALREPORTS')
		begin
			PRINT 'Dropping primary key constraint EXTERNALREPORTS.XPKEXTERNALREPORTS...'
			ALTER TABLE EXTERNALREPORTS DROP CONSTRAINT XPKEXTERNALREPORTS
		end
	go

	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'EXTERNALREPORTS' and CONSTRAINT_NAME = 'R_81794')
		begin
			PRINT 'Dropping foreign key constraint EXTERNALREPORTS.R_81794...'
			ALTER TABLE EXTERNALREPORTS DROP CONSTRAINT R_81794
		end
	go

	PRINT 'Adding primary key constraint EXTERNALREPORTS.XPKEXTERNALREPORTS...'
	ALTER TABLE dbo.EXTERNALREPORTS
		 WITH NOCHECK ADD CONSTRAINT  XPKEXTERNALREPORTS PRIMARY KEY   NONCLUSTERED (ID  ASC)
	go

	PRINT 'Adding foreign key constraint EXTERNALREPORTS.R_81794...'
	ALTER TABLE dbo.EXTERNALREPORTS
		 WITH NOCHECK ADD CONSTRAINT  R_81794 FOREIGN KEY (TASKID) REFERENCES dbo.TASK(TASKID)
			ON DELETE CASCADE
		 NOT FOR REPLICATION
	go
