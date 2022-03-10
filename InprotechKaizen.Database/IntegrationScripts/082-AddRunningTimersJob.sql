IF NOT EXISTS(SELECT * FROM dbo.[Jobs] WHERE [Type] = 'RunningTimersJob')
BEGIN
	PRINT '**** DR-76633 Adding job to check for timers running overnight every 5 minutes'           
	INSERT dbo.[Jobs] ([Type], Recurrence, NextRun, IsActive)
	SELECT 'RunningTimersJob', 5, CONVERT(DATE,GETDATE()), 1
	PRINT '**** DR-76633 Added job to check for timers running overnight'           
END
ELSE
BEGIN
	PRINT '**** DR-76633 job to check for timers running overnight already exists.'
	PRINT ''
END
GO

