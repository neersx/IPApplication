	
/****** RFC64418 Adding column EVENTS.NOTEGROUP ********/

If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'EVENTS' AND COLUMN_NAME = 'NOTEGROUP')
Begin
	PRINT '**** RFC64418 Adding column EVENTS.NOTEGROUP.' 
	ALTER TABLE EVENTS ADD NOTEGROUP int  NULL
	PRINT '**** RFC64418 EVENTS.NOTEGROUP column has been added.'
	PRINT ''
End
Else
	PRINT '**** RFC64418 EVENTS.NOTEGROUP already exists'
	PRINT ''
go

/****** RFC64418 Adding column EVENTS.NOTESSHAREDACROSSCYCLES ********/
If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'EVENTS' AND COLUMN_NAME = 'NOTESSHAREDACROSSCYCLES')
Begin
	PRINT '**** RFC64418 Adding column EVENTS.NOTESSHAREDACROSSCYCLES.' 
	ALTER TABLE EVENTS ADD NOTESSHAREDACROSSCYCLES bit  NULL
	PRINT '**** RFC64418 EVENTS.NOTESSHAREDACROSSCYCLES column has been added.'
	PRINT ''
End
Else
	PRINT '**** RFC64418 EVENTS.NOTESSHAREDACROSSCYCLES already exists'
	PRINT ''
go

/****** RFC64418 Adding Constraint R_81886  ********/

If NOT exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'EVENTS' and CONSTRAINT_NAME = 'R_81886')
	begin
		PRINT 'Adding foreign key constraint EVENTS.R_81886...'
		ALTER TABLE dbo.EVENTS
		WITH NOCHECK ADD CONSTRAINT R_81886 FOREIGN KEY (NOTEGROUP) REFERENCES dbo.TABLECODES(TABLECODE)
		NOT FOR REPLICATION
	end
go

/****** RFC64418 Regenerate EVENTS Audit Triggers ********/
if NOT exists (	Select *
		from syscomments s
		join sysobjects o on (o.id=s.id)
		where s.text like '%NOTESSHAREDACROSSCYCLES%' 
		and   s.text like '%NOTEGROUP%' 
		and o.name like 't%EVENTS_Audit'
		and o.type='TR')
Begin
	PRINT '**** RFC64418 Regenerating EVENTS Audit triggers' 
	exec ipu_UtilGenerateAuditTriggers 'EVENTS'
	PRINT ''
End
go

/****** RFC64418 Adding index XIE6EVENTS on EVENTS ********/
if not exists (select * from sysindexes where name = 'XIE6EVENTS')
begin
	 PRINT 'Creating index EVENTS.XIE6EVENTS ...'
	 CREATE NONCLUSTERED INDEX XIE6EVENTS ON EVENTS
	 ( 
		NOTEGROUP           ASC
	 )
	 INCLUDE ( [EVENTNO]) WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
end	
go
