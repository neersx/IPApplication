if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'Jobs' and COLUMN_NAME = 'RunOnInstanceName')
begin
	ALTER TABLE [JOBS] ADD RunOnInstanceName nvarchar(max) NULL
end
go