/****************************************************************************/
/*** RFC61726 Adding table ROLESCONTROL ***/	
/****************************************************************************/

If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ROLESCONTROL')
		BEGIN
		PRINT '**** RFC61726  Adding table ROLESCONTROL.'
		CREATE TABLE dbo.ROLESCONTROL
		( 
			CRITERIANO           int  NOT NULL ,
			ENTRYNUMBER          smallint  NOT NULL ,
			ROLEID               int  NOT NULL ,
			INHERITED            bit  NULL ,
			LOGUSERID            nvarchar(50)  NULL ,
			LOGIDENTITYID        int  NULL ,
			LOGTRANSACTIONNO     int  NULL ,
			LOGDATETIMESTAMP     datetime  NULL ,
			LOGAPPLICATION       nvarchar(128)  NULL ,
			LOGOFFICEID          int  NULL 
		)
			exec sc_AssignTableSecurity 'ROLESCONTROL'			 
			PRINT '**** RFC61726 ROLESCONTROL table has been added.'
			PRINT ''
		END
		ELSE
			PRINT '**** RFC61726 ROLESCONTROL already exists'
			PRINT ''
go 


 if not exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'ROLESCONTROL' and CONSTRAINT_NAME = 'XPKROLESCONTROL')
	begin
		PRINT 'Adding primary key constraint ROLESCONTROL.XPKROLESCONTROL...'
		ALTER TABLE dbo.ROLESCONTROL
		WITH NOCHECK ADD CONSTRAINT XPKROLESCONTROL PRIMARY KEY  CLUSTERED (CRITERIANO ASC,ENTRYNUMBER ASC,ROLEID ASC)		
	end
	else
			PRINT '**** Primary key constraint ROLESCONTROL.XPKROLESCONTROL already exists'
			PRINT ''
go
 
 
 if not exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'ROLESCONTROL' and CONSTRAINT_NAME = 'R_81896')
	begin
		PRINT 'Adding foreign key constraint ROLESCONTROL.R_81896...'
		ALTER TABLE dbo.ROLESCONTROL
		WITH NOCHECK ADD CONSTRAINT R_81896 FOREIGN KEY (CRITERIANO,ENTRYNUMBER) REFERENCES dbo.DETAILCONTROL(CRITERIANO,ENTRYNUMBER)
		ON DELETE CASCADE
		NOT FOR REPLICATION
	end
else
			PRINT '**** foreign key constraint ROLESCONTROL.R_81896 already exists'
			PRINT ''
go 

 if not exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'ROLESCONTROL' and CONSTRAINT_NAME = 'R_81897')
	begin
		PRINT 'Adding foreign key constraint ROLESCONTROL.R_81897...'
		ALTER TABLE dbo.ROLESCONTROL
		WITH NOCHECK ADD CONSTRAINT R_81897 FOREIGN KEY (ROLEID) REFERENCES dbo.ROLE(ROLEID)
		ON DELETE CASCADE
		NOT FOR REPLICATION
	end
else
			PRINT '**** foreign key constraint ROLESCONTROL.R_81897 already exists'
			PRINT ''
GO

IF dbo.fn_IsAuditSchemaConsistent('ROLESCONTROL') = 0
BEGIN
   EXEC ipu_UtilGenerateAuditTriggers 'ROLESCONTROL'
END
GO