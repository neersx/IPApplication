if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'Jobs' and COLUMN_NAME = 'JobArguments')
begin
	ALTER TABLE [JOBS] ADD JobArguments nvarchar(max) NULL
end
go