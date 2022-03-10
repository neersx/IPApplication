If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Schedules' AND COLUMN_NAME = 'ExpiresAfter')
BEGIN
	PRINT '**** R44625 Adding column Schedules.ExpiresAfter.'
	ALTER TABLE Schedules ADD ExpiresAfter datetime NULL
	PRINT '**** R44625 Schedules.ExpiresAfter column has been added.'
END
ELSE
BEGIN
	PRINT '**** R44625 Schedules.ExpiresAfter already exists'
	PRINT ''
END
go

If EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Schedules' AND COLUMN_NAME = 'RunOnDays' and IS_NULLABLE = 'NO')
BEGIN
	PRINT '**** R44625 Alter Schedules.RunOnDays be nullable.'           
	ALTER TABLE Schedules ALTER COLUMN RunOnDays nvarchar(max) collate database_default null
	PRINT '**** R44625 Schedules.RunOnDays column has been altered.'
END
ELSE
BEGIN
	PRINT '**** R44625 Schedules.RunOnDays already nullable'
	PRINT ''
END
go