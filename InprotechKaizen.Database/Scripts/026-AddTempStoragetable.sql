/*** RFC13898/RFC31258 Add table TEMPSTORAGE								***/	


	If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TEMPSTORAGE')
		BEGIN
			PRINT '**** RFC13898/RFC31258  Adding table TEMPSTORAGE.' 

			CREATE TABLE dbo.TEMPSTORAGE
			 (
				ID  bigint IDENTITY (1,1)  NOT FOR REPLICATION,
				DATA  nvarchar(max)  NOT NULL ,
				LOGUSERID  nvarchar(50)  NULL ,
				LOGIDENTITYID  int  NULL ,
				LOGTRANSACTIONNO  int  NULL ,
				LOGDATETIMESTAMP  datetime  NULL ,
				LOGAPPLICATION  nvarchar(128)  NULL ,
				LOGOFFICEID  int  NULL 
			 )

			exec sc_AssignTableSecurity 'TEMPSTORAGE'

			PRINT '**** RFC13898/RFC31258 TEMPSTORAGE table has been added.'
			PRINT ''
		END
	ELSE
			PRINT '**** RFC13898/RFC31258 TEMPSTORAGE already exists'
			PRINT ''
	go 
	 

	/*** RFC13898/RFC31258 Adding primary key for table TEMPSTORAGE				***/

	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'TEMPSTORAGE' and CONSTRAINT_NAME = 'XPKTEMPSTORAGE')
		begin
			PRINT 'Dropping primary key constraint TEMPSTORAGE.XPKTEMPSTORAGE...'
			ALTER TABLE TEMPSTORAGE DROP CONSTRAINT XPKTEMPSTORAGE
		end
	go

	PRINT 'Adding primary key constraint TEMPSTORAGE.XPKTEMPSTORAGE...'
	ALTER TABLE dbo.TEMPSTORAGE
		 WITH NOCHECK ADD CONSTRAINT  XPKTEMPSTORAGE PRIMARY KEY   NONCLUSTERED (ID  ASC)
	go


	/***  RFC13898/RFC31258  Add data into AUDITLOGTABLES.TABLENAME = TEMPSTORAGE									***/
   
	IF NOT exists (select * from AUDITLOGTABLES where TABLENAME = 'TEMPSTORAGE')
		begin
		 PRINT '**** RFC13898/RFC31258  Inserting data into AUDITLOGTABLE.TABLENAME = TEMPSTORAGE'
			Insert AUDITLOGTABLES (TABLENAME, LOGFLAG, REPLICATEFLAG)
			Values ('TEMPSTORAGE', 0, 0)
		 PRINT '**** RFC13898/RFC31258  Data has been successfully added to AUDITLOGTABLES table.'
		 PRINT ''	
		END
	ELSE
		PRINT '**** RFC13898/RFC31258  AUDITLOGTABLES.TEMPSTORAGE already exists.'
		PRINT ''
	go