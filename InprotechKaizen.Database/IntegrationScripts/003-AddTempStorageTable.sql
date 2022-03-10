	If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TempStorage')
		BEGIN
			CREATE TABLE dbo.TempStorage
			 (
				Id  bigint IDENTITY (1,1)  NOT FOR REPLICATION,
				Data nvarchar(max)  NOT NULL
			 )
		END
	go 
	 
	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'TempStorage' and CONSTRAINT_NAME = 'XPKTempStorage')
		begin
			ALTER TABLE TempStorage DROP CONSTRAINT XPKTempStorage
		end
	go

	ALTER TABLE dbo.TempStorage
		 WITH NOCHECK ADD CONSTRAINT  XPKTempStorage PRIMARY KEY   NONCLUSTERED (Id  ASC)
	go
