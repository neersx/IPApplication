if not exists (select * from INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME = 'SourceUrl' and TABLE_NAME = 'Documents')
begin
	ALTER TABLE [Documents] ADD SourceUrl nvarchar(4000) NULL 
end
go