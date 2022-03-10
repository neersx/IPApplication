IF object_id('[dbo].[CaseFiles]') IS NULL
Begin
Create table dbo.CaseFiles
(
	Id int identity (1,1) NOT FOR REPLICATION,
	[Type] int not null,
	CaseId int not null,
	FileStoreId int not null
)
End
go


if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'CaseFiles' and CONSTRAINT_NAME = 'XPKCaseFiles')
Begin
	ALTER TABLE CaseFiles DROP CONSTRAINT XPKCaseFiles
End
go

ALTER TABLE dbo.CaseFiles
	 WITH NOCHECK ADD CONSTRAINT  XPKCaseFiles PRIMARY KEY NONCLUSTERED (Id  ASC)
go

if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'CaseFiles' and CONSTRAINT_NAME = 'FK_CaseFiles_Cases')
begin
	ALTER TABLE CaseFiles DROP CONSTRAINT FK_CaseFiles_Cases
end
go

ALTER TABLE dbo.CaseFiles
	 WITH NOCHECK ADD CONSTRAINT  FK_CaseFiles_Cases FOREIGN KEY (CaseId) REFERENCES dbo.Cases(Id)
		ON DELETE CASCADE
	 NOT FOR REPLICATION
go

if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'CaseFiles' and CONSTRAINT_NAME = 'FK_CaseFiles_FileStores')
begin
	ALTER TABLE CaseFiles DROP CONSTRAINT FK_CaseFiles_FileStores
end
go

ALTER TABLE dbo.CaseFiles
	 WITH NOCHECK ADD CONSTRAINT FK_CaseFiles_FileStores FOREIGN KEY (FileStoreId) REFERENCES dbo.FileStores(Id)
		ON DELETE CASCADE
	 NOT FOR REPLICATION
go


if exists (select * from sysindexes where name='IX_CaseFiles')
begin
	drop INDEX [CaseFiles].[IX_CaseFiles]
end
go

CREATE unique clustered INDEX [IX_CaseFiles] ON [dbo].[CaseFiles]([CaseId],[FileStoreId])	
go
