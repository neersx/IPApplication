	If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'DataSourceAvailability')
		BEGIN
			CREATE TABLE dbo.DataSourceAvailability
			 (
				Id  bigint IDENTITY (1,1)  NOT FOR REPLICATION,
				Source int,
				UnavailableDays nvarchar(max) NOT NULL,
				StartTime nvarchar(max)  NOT NULL,
				EndTime nvarchar(max) NOT NULL,
				Timezone nvarchar(max) NOT NULL
			 )
		END
	go 
	 
	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'DataSourceAvailability' and CONSTRAINT_NAME = 'XPKDataSourceAvailability')
		begin
			ALTER TABLE DataSourceAvailability DROP CONSTRAINT XPKDataSourceAvailability
		end
	go

	ALTER TABLE dbo.DataSourceAvailability
		 WITH NOCHECK ADD CONSTRAINT  XPKDataSourceAvailability PRIMARY KEY   NONCLUSTERED (Id  ASC)
	go
