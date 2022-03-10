/*** R70004 Add column WINDOWCONTROL.ENTRYNUMBER          ***/

if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'WINDOWCONTROL' and COLUMN_NAME = 'ENTRYNUMBER')
begin
	PRINT '**** R70004 Adding column WINDOWCONTROL.ENTRYNUMBER.'
	alter table WINDOWCONTROL add  ENTRYNUMBER smallint NULL	
end
GO
IF dbo.fn_IsAuditSchemaConsistent('WINDOWCONTROL') = 0
BEGIN
	exec ipu_UtilGenerateAuditTriggers 'WINDOWCONTROL'
END
GO

if exists (select * from sysobjects where type='TR' and name = 'DeleteWindowControls_DetailsControl')
begin
	PRINT 'Refreshing trigger DeleteWindowControls_DetailsControl...'
	drop trigger DeleteWindowControls_DetailsControl
end
go

create trigger DeleteWindowControls_DetailsControl on DETAILCONTROL
for delete not for replication as

	delete W
	from WINDOWCONTROL W
	join deleted d on (d.ENTRYNUMBER = W.ENTRYNUMBER and d.CRITERIANO = W.CRITERIANO)

go

if exists (select * from sysobjects where type='TR' and name = 'DeleteScreenControls_DetailsControl')
begin
	PRINT 'Refreshing trigger DeleteScreenControls_DetailsControl...'
	drop trigger DeleteScreenControls_DetailsControl
end
go

create trigger DeleteScreenControls_DetailsControl on DETAILCONTROL
for delete not for replication as

	delete S
	from SCREENCONTROL S
	join deleted d on (d.ENTRYNUMBER = S.ENTRYNUMBER and d.CRITERIANO = S.CRITERIANO)

go