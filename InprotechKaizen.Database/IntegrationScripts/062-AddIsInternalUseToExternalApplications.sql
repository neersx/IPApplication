if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'ExternalApplications' and COLUMN_NAME = 'IsInternalUse')
begin   
	alter table [ExternalApplications] add [IsInternalUse] bit not null default 0
end
go

update [ExternalApplications] set [IsInternalUse] = 0 where [IsInternalUse] is null
go

if not exists(SELECT * from ExternalApplications where Code = 'INPROTECHSERVER')
begin
	insert EXTERNALAPPLICATIONS ([NAME], CODE, [IsInternalUse], CREATEDON) 
	values ('INPROTECHSERVER', 'INPROTECHSERVER', 1, getdate())
end
go

if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'ExternalApplications' and COLUMN_NAME = 'IsInternalUse')
begin   
	alter table [ExternalApplications] add [IsInternalUse] bit not null default 0
end
go

if exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'ExternalApplications' and COLUMN_NAME = 'Name' and CHARACTER_MAXIMUM_LENGTH <> 254)
begin   
	alter table [ExternalApplications] alter column [Name] nvarchar(254) not null
end
go

if not exists (select * from sysindexes where name = 'XAK1ExternalApplicationName')
begin
	create unique nonclustered index [XAK1ExternalApplicationName] on [dbo].[ExternalApplications] 
	(
		[Name] asc
	)
	with (
		PAD_INDEX  = OFF, 
		STATISTICS_NORECOMPUTE  = OFF, 
		SORT_IN_TEMPDB = OFF, 
		IGNORE_DUP_KEY = OFF, 
		DROP_EXISTING = OFF, 
		ONLINE = OFF, 
		ALLOW_ROW_LOCKS  = ON, 
		ALLOW_PAGE_LOCKS  = ON) on [PRIMARY]	 
end
go

if object_id('[dbo].[OneTimeTokens]') IS NULL
begin   

    CREATE TABLE [dbo].[OneTimeTokens]
	(
		[Id] bigint not null identity(1,1),
		[ExternalApplicationName] nvarchar(254) NOT NULL,
		[Token] uniqueidentifier NOT NULL,
		[ExpiryDate] [datetime] NOT NULL,
		[CreatedOn] [datetime] NOT NULL,
		[CreatedBy] [int] NOT NULL,
	
		constraint [XPKOneTimeTokens] primary key nonclustered ([Id])
     )
end
go

if not exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'OneTimeTokens' and CONSTRAINT_NAME = 'XFK1OneTimeTokens')
begin
	alter table [dbo].[OneTimeTokens]  
		with nocheck add constraint XFK1OneTimeTokens foreign key ([ExternalApplicationName])
	references [dbo].[ExternalApplications] ([Name])
	on delete cascade
	on update no action
end
go

if not exists (select * from sysindexes where name = 'XAK1OneTimeTokens')
begin
	create unique nonclustered index [XAK1OneTimeTokens] on [dbo].[OneTimeTokens] 
	(
		[ExternalApplicationName] asc,
		[Token] asc
	)
	with (
		PAD_INDEX  = OFF, 
		STATISTICS_NORECOMPUTE  = OFF, 
		SORT_IN_TEMPDB = OFF, 
		IGNORE_DUP_KEY = OFF, 
		DROP_EXISTING = OFF, 
		ONLINE = OFF, 
		ALLOW_ROW_LOCKS  = ON, 
		ALLOW_PAGE_LOCKS  = ON) on [PRIMARY]	 
end
go
