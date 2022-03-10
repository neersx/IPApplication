IF NOT EXISTS(SELECT * FROM dbo.[Jobs] WHERE [Type] = 'IdentifyProcessIdsToCleanup')
BEGIN
	PRINT '**** DR-75312 Adding file cleanup job.'           
	INSERT dbo.[Jobs] ([Type], Recurrence, NextRun, IsActive)
	SELECT 'IdentifyProcessIdsToCleanup', 1440, getdate(), 1
	PRINT '**** DR-75312 Add IdentifyProcessIdsToCleanup job.'           
END
ELSE
BEGIN
	PRINT '**** DR-75312 IdentifyProcessIdsToCleanup already exists'
	PRINT ''
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ProcessIdsToCleanup')
BEGIN
	PRINT '**** DR-75312  Adding table ProcessIdsToCleanup.' 
		CREATE TABLE ProcessIdsToCleanup(
			ScheduleId INT PRIMARY KEY,	
			ProcessId BIGINT NOT NULL,
			IsCleanedUp BIT NOT NULL DEFAULT 0,
			AddedOn DATETIME NOT NULL,
			CleanupCompletedOn datetime NULL,
			FOREIGN KEY(ScheduleId) REFERENCES Schedules(Id) ON DELETE CASCADE)

	PRINT '**** DR-75312 ProcessIdsToCleanup table has been added.'
	PRINT ''
END
	ELSE
	PRINT '**** DR-75312 ProcessIdsToCleanup already exists'
	PRINT ''
GO 