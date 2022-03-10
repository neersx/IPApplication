if not exists (select * from INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME = 'UpdatedOn' and TABLE_NAME = 'CaseFiles')
begin	
	ALTER TABLE [CaseFiles] ADD UpdatedOn datetime2(7) NULL DEFAULT GETDATE()
END
GO