if not exists(select * from ConfigurationSettings where [Key] = 'Innography.Request.ChunkSize')
begin
	insert ConfigurationSettings ([Key], Value) values ('Innography.Request.ChunkSize', 1000)
end
go

if not exists(select * from ConfigurationSettings where [Key] = 'File.Request.ChunkSize')
begin
	insert ConfigurationSettings ([Key], Value) values ('File.Request.ChunkSize', 2000)
end
go

update ConfigurationSettings set Value = 1000
where [Key] = 'Innography.Request.ChunkSize'

go

update ConfigurationSettings set Value = 2000
where [Key] = 'File.Request.ChunkSize'

go