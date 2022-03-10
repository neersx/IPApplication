if not exists(select * from information_schema.columns where table_name = 'APPSLINK' and column_name = 'NAME')
begin		 
	alter table APPSLINK add [NAME] nvarchar(256) collate database_default NOT NULL	 
end
GO
exec ipu_UtilGenerateAuditTriggers 'APPSLINK'
GO

if exists (select * from sysindexes where name = 'XAK1APPSLINK')
begin
	 drop index APPSLINK.XAK1APPSLINK
end
go

if not exists (select * from sysindexes where name = 'XAK1APPSLINK')
begin
	create unique index XAK1APPSLINK on APPSLINK ( [NAME] asc )
end
go
