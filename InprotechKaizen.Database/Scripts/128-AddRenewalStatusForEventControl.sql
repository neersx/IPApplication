/**********************************************************************************************************/		
/****** RFC53615 Adding column EVENTCONTROL.RENEWALSTATUS ********/
/**********************************************************************************************************/

If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'EVENTCONTROL' AND COLUMN_NAME = 'RENEWALSTATUS')
BEGIN
PRINT 'RFC53615 Adding column EVENTCONTROL.RENEWALSTATUS ...'
ALTER TABLE EVENTCONTROL ADD RENEWALSTATUS smallint  NULL 
END
GO
 IF dbo.fn_IsAuditSchemaConsistent('EVENTCONTROL') = 0
 BEGIN
	exec ipu_UtilGenerateAuditTriggers 'EVENTCONTROL';
 END
GO

if not exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'EVENTCONTROL' and CONSTRAINT_NAME = 'R_81894')
	begin
		PRINT 'RFC53615 Adding foreign key constraint EVENTCONTROL.R_81894...'
		ALTER TABLE dbo.EVENTCONTROL
		WITH NOCHECK ADD CONSTRAINT R_81894 FOREIGN KEY (RENEWALSTATUS) REFERENCES dbo.STATUS(STATUSCODE)
		NOT FOR REPLICATION
	end
	ELSE
			PRINT '**** RFC53615 Foreign key constraint EVENTCONTROL.R_81894 already exists'
			PRINT ''
go



