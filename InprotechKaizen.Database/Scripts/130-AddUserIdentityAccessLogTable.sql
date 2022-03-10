﻿/****************************************************************************/
/*** RFC70601 Adding table USERIDENTITYACCESSLOG ***/	
/****************************************************************************/

If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'USERIDENTITYACCESSLOG')
		BEGIN
		PRINT '**** RFC70601  Adding table USERIDENTITYACCESSLOG.'
		CREATE TABLE dbo.USERIDENTITYACCESSLOG
		( 
			LOGID                bigint  NOT NULL  IDENTITY ( 1,1 )  NOT FOR REPLICATION,
			IDENTITYID           int  NULL ,
			PROVIDER             nvarchar(30)  NOT NULL ,
			LOGINTIME            datetime  NOT NULL ,
			LOGOUTTIME           datetime  NULL ,
			LASTEXTENSION        datetime  NULL ,
			TOTALEXTENSIONS      int  NULL ,
			DATA                 nvarchar(max)  NULL ,
			APPLICATION          nvarchar(128)  NULL ,
			LOGUSERID            nvarchar(50)  NULL ,
			LOGIDENTITYID        int  NULL ,
			LOGTRANSACTIONNO     int  NULL ,
			LOGDATETIMESTAMP     datetime  NULL ,
			LOGAPPLICATION       nvarchar(128)  NULL ,
			LOGOFFICEID          int  NULL 
		)
			exec sc_AssignTableSecurity 'USERIDENTITYACCESSLOG'			 
			PRINT '**** RFC70601 USERIDENTITYACCESSLOG table has been added.'
			PRINT ''
		END
		ELSE
			PRINT '**** RFC70601 Table USERIDENTITYACCESSLOG already exists'
			PRINT ''
go 



if not exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'USERIDENTITYACCESSLOG' and CONSTRAINT_NAME = 'XPKUSERIDENTITYACCESSLOG')
	begin
		PRINT 'Adding primary key constraint USERIDENTITYACCESSLOG.XPKUSERIDENTITYACCESSLOG...'
		ALTER TABLE dbo.USERIDENTITYACCESSLOG
		WITH NOCHECK ADD CONSTRAINT XPKUSERIDENTITYACCESSLOG PRIMARY KEY  CLUSTERED (LOGID ASC)		
	end
	else
			PRINT '**** Primary key constraint USERIDENTITYACCESSLOG.XPKUSERIDENTITYACCESSLOG already exists'
			PRINT ''
GO

IF dbo.fn_IsAuditSchemaConsistent('USERIDENTITYACCESSLOG') = 0
BEGIN
   EXEC ipu_UtilGenerateAuditTriggers 'USERIDENTITYACCESSLOG'
END
GO

if not exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'USERIDENTITYACCESSLOG' and CONSTRAINT_NAME = 'R_81898')
	begin
		PRINT 'Adding foreign key constraint USERIDENTITYACCESSLOG.R_81898...'
		ALTER TABLE dbo.USERIDENTITYACCESSLOG
		WITH NOCHECK ADD CONSTRAINT R_81898 FOREIGN KEY (IDENTITYID) REFERENCES dbo.USERIDENTITY(IDENTITYID)
		ON DELETE CASCADE
		NOT FOR REPLICATION
	end
	else
			PRINT '**** Foreign key constraint USERIDENTITYACCESSLOG.R_81898 already exists'
			PRINT ''
go




if not exists (select * from sysindexes where name = 'XAK1USERIDENTITYACCESSLOG')
begin
	 PRINT 'Adding index USERIDENTITYACCESSLOG.XAK1USERIDENTITYACCESSLOG ...'
	 CREATE UNIQUE NONCLUSTERED INDEX XAK1USERIDENTITYACCESSLOG ON USERIDENTITYACCESSLOG
	( 
		LOGID                 ASC,
		IDENTITYID            ASC,
		PROVIDER              ASC,
		LOGINTIME             ASC
	)
	end
	else
			PRINT '**** Index USERIDENTITYACCESSLOG.XAK1USERIDENTITYACCESSLOG already exists'
			PRINT ''
go
