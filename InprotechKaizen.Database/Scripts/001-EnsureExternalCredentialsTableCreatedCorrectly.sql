	If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'EXTERNALCREDENTIALS')
		BEGIN
			PRINT '**** RFC12988  Adding table EXTERNALCREDENTIALS.' 

			CREATE TABLE dbo.EXTERNALCREDENTIALS
			 (
 				ID  int  IDENTITY (1,1)  NOT FOR REPLICATION,
 				IDENTITYID  int  NOT NULL ,
 				PROVIDERNAME  nvarchar(30)  NOT NULL ,
 				USERNAME  nvarchar(100)  NOT NULL ,
 				PASSWORD  nvarchar(max)  NULL ,
 				LOGUSERID  nvarchar(50)  NULL ,
 				LOGIDENTITYID  int  NULL ,
 				LOGTRANSACTIONNO  int  NULL ,
 				LOGDATETIMESTAMP  datetime  NULL ,
 				LOGAPPLICATION  nvarchar(128)  NULL ,
 				LOGOFFICEID  int  NULL 
			 )

			exec sc_AssignTableSecurity 'EXTERNALCREDENTIALS'

			PRINT '**** RFC12988 EXTERNALCREDENTIALS table has been added.'
			PRINT ''
		END
	ELSE
			PRINT '**** RFC12988 EXTERNALCREDENTIALS already exists'
			PRINT ''
	go 
 
	/*** RFC12988 Adding primary key and foreign keys for table EXTERNALCREDENTIALS				***/	

	----Dropping Primary Key for table EXTERNALCREDENTIALS, created in web_version_update.sql for Release 8---- 

	declare @primaryKey nvarchar(50) 
	declare @sSqlString nvarchar(4000)

	select @primaryKey = name
	from sysobjects
	where xtype = 'PK'
	and parent_obj = (object_id('EXTERNALCREDENTIALS'))

	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'EXTERNALCREDENTIALS' and CONSTRAINT_NAME = @primaryKey)
		begin
			PRINT 'Dropping primary key constraint EXTERNALCREDENTIALS'
			Set @sSqlString = 'ALTER TABLE EXTERNALCREDENTIALS DROP CONSTRAINT ' + @primaryKey
			exec sp_executesql @sSqlString
		end
	go

	----Dropping Foreign Key for table EXTERNALCREDENTIALS, created in web_version_update.sql for Release 8---- 

	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'EXTERNALCREDENTIALS' and CONSTRAINT_NAME = 'FK_EXTERNALCREDENTIALS_USERIDENTITY')
		begin
			PRINT 'Dropping foreign key constraint EXTERNALCREDENTIALS.FK_EXTERNALCREDENTIALS_USERIDENTITY...'
			ALTER TABLE EXTERNALCREDENTIALS DROP CONSTRAINT FK_EXTERNALCREDENTIALS_USERIDENTITY
		end
	go

	----Create Primary Key and Foreign Key for table EXTERNALCREDENTIALS, through ERwin---- 

	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'EXTERNALCREDENTIALS' and CONSTRAINT_NAME = 'XPKEXTERNALCREDENTIALS')
		begin
			PRINT 'Dropping primary key constraint EXTERNALCREDENTIALS.XPKEXTERNALCREDENTIALS...'
			ALTER TABLE EXTERNALCREDENTIALS DROP CONSTRAINT XPKEXTERNALCREDENTIALS
		end
	go

	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'EXTERNALCREDENTIALS' and CONSTRAINT_NAME = 'R_81792')
		begin
			PRINT 'Dropping foreign key constraint EXTERNALCREDENTIALS.R_81792...'
			ALTER TABLE EXTERNALCREDENTIALS DROP CONSTRAINT R_81792
		end
	go

	PRINT 'Adding primary key constraint EXTERNALCREDENTIALS.XPKEXTERNALCREDENTIALS...'
	ALTER TABLE dbo.EXTERNALCREDENTIALS
		 WITH NOCHECK ADD CONSTRAINT  XPKEXTERNALCREDENTIALS PRIMARY KEY   NONCLUSTERED (ID  ASC)
	go

	PRINT 'Adding foreign key constraint EXTERNALCREDENTIALS.R_81792...'
	ALTER TABLE dbo.EXTERNALCREDENTIALS
		 WITH NOCHECK ADD CONSTRAINT  R_81792 FOREIGN KEY (IDENTITYID) REFERENCES dbo.USERIDENTITY(IDENTITYID)
			ON DELETE CASCADE
		 NOT FOR REPLICATION
	go

	/*** RFC12988 Adding Index for table EXTERNALCREDENTIALS				***/

	----Dropping Index for table EXTERNALCREDENTIALS, created in web_version_update.sql for Release 8---- 

	if exists (select * from sysindexes where name = 'IDX_EXTERNALCREDENTIALS_IDENTITYID_PROVIDERNAME')
	begin
		 PRINT 'Dropping index EXTERNALCREDENTIALS.IDX_EXTERNALCREDENTIALS_IDENTITYID_PROVIDERNAME ...'
		 DROP INDEX EXTERNALCREDENTIALS.IDX_EXTERNALCREDENTIALS_IDENTITYID_PROVIDERNAME
	end
	go

	----Create Index for table EXTERNALCREDENTIALS, through ERwin---- 

	if exists (select * from sysindexes where name = 'XAK1EXTERNALCREDENTIALS')
	begin
		 PRINT 'Dropping index EXTERNALCREDENTIALS.XAK1EXTERNALCREDENTIALS ...'
		 DROP INDEX EXTERNALCREDENTIALS.XAK1EXTERNALCREDENTIALS
	end
	go

	CREATE  UNIQUE INDEX XAK1EXTERNALCREDENTIALS ON EXTERNALCREDENTIALS
	(
		IDENTITYID  ASC,
		PROVIDERNAME  ASC
	)
	go
