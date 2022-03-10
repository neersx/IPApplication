﻿If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ScheduleExecutions' AND COLUMN_NAME = 'CancellationData')
	BEGIN		 
		ALTER TABLE ScheduleExecutions ADD CancellationData VARCHAR(MAX)
 	END
go