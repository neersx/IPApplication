	If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ScheduleExecutionArtifacts' AND COLUMN_NAME = 'Blob')
	BEGIN   
		ALTER TABLE ScheduleExecutionArtifacts ADD [Blob] varbinary(max) null
	END
	go
	