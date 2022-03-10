	If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ScheduleRecoverables' AND COLUMN_NAME = 'Blob')
	BEGIN   
		ALTER TABLE ScheduleRecoverables ADD [Blob] varbinary(max) null
	END
	go
	