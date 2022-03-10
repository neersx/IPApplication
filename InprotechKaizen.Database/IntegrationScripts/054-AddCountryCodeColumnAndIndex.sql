if exists (select * from sys.indexes where name = N'IX_OfficialNumbers_Type' AND object_id = object_id(N'[dbo].[Cases]', N'U'))
begin
    drop index [Cases].[IX_OfficialNumbers_Type]
end
go

if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'Cases' and COLUMN_NAME = 'ApplicationNumber' and CHARACTER_MAXIMUM_LENGTH = 100)
begin
	ALTER TABLE [Cases] ALTER COLUMN [ApplicationNumber] nvarchar(100) NULL
end
go

if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'Cases' and COLUMN_NAME = 'RegistrationNumber' and CHARACTER_MAXIMUM_LENGTH = 100)
begin
	ALTER TABLE [Cases] ALTER COLUMN [RegistrationNumber] nvarchar(100) NULL
end
go

if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'Cases' and COLUMN_NAME = 'PublicationNumber' and CHARACTER_MAXIMUM_LENGTH = 100)
begin
	ALTER TABLE [Cases] ALTER COLUMN [PublicationNumber] nvarchar(100) NULL
end
go

if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'Cases' and COLUMN_NAME = 'Jurisdiction')
begin   
	ALTER TABLE Cases ADD Jurisdiction NVARCHAR(10) NULL
END
go

if not exists (select * from sys.indexes where name = N'IX_OfficialNumbers_Type' AND object_id = object_id(N'[dbo].[Cases]', N'U'))
begin
    create unique index [IX_OfficialNumbers_Type] ON [dbo].[Cases]([Source], [ApplicationNumber], [RegistrationNumber], [PublicationNumber], [Jurisdiction], [CorrelationId])
end
go

update Cases 
set Jurisdiction = case when Source = 1 then 'US'
						when Source = 2 then 'EP'
					end
where Jurisdiction is null and Source in (1, 2)
go