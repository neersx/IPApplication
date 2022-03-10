if not exists (select * from INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME = 'Status' and TABLE_NAME = 'Sponsorships')
begin
	ALTER TABLE [Sponsorships] ADD Status SMALLINT NOT NULL DEFAULT 0
end
GO
if not exists (select * from INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME = 'StatusDate' and TABLE_NAME = 'Sponsorships')
begin
	ALTER TABLE [Sponsorships] ADD StatusDate DATE NOT NULL DEFAULT GETDATE()
END
GO

IF not exists (select * from INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME = 'StatusMessage' and TABLE_NAME = 'Sponsorships')
begin
	ALTER TABLE [Sponsorships] ADD StatusMessage NVARCHAR(max) NULL
END
GO

