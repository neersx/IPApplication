declare @sql varchar(max)
set @sql = ''

select 
	@sql = @sql + 'alter table ' + a.name + ' add CreatedByE2E bit default 1' + char(13) + 'create index XI_' + a.name + '_CreatedByE2E on ' + a.name + ' (CreatedByE2E)' + char(13)
	from sys.tables as a
	where exists (
		select * from sys.columns as b
		where a.object_id = b.object_id and b.name = 'LOGDATETIMESTAMP')
		and 
		not exists (
		select * from sys.columns as b
		where a.object_id = b.object_id and b.name = 'CreatedByE2E')

exec(@sql)	