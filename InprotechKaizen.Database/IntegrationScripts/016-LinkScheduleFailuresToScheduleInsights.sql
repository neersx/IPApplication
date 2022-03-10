	if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'ScheduleFailures' and COLUMN_NAME = 'ScheduleExecutionId')
	begin   
		ALTER TABLE ScheduleFailures ADD ScheduleExecutionId bigint NULL
	end
	go

	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'ScheduleFailures' and CONSTRAINT_NAME = 'FK_ScheduleFailures_ScheduleExecutions')
		begin
			PRINT 'Dropping foreign key constraint ScheduleFailures.FK_ScheduleFailures_ScheduleExecutions...'
			ALTER TABLE ScheduleFailures DROP CONSTRAINT FK_ScheduleFailures_ScheduleExecutions
		end
	go

	ALTER TABLE dbo.ScheduleFailures
		 WITH NOCHECK ADD CONSTRAINT  FK_ScheduleFailures_ScheduleExecutions FOREIGN KEY (ScheduleExecutionId) REFERENCES dbo.ScheduleExecutions(Id)
			ON DELETE NO ACTION
		 NOT FOR REPLICATION
	go
	