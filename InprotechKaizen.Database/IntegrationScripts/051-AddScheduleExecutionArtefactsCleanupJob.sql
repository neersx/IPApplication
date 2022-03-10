IF NOT EXISTS(SELECT * FROM dbo.[Jobs] WHERE [Type] = 'ScheduleExecutionArtefactsCleanUp')
BEGIN
	PRINT '**** R65366 Adding ScheduleExecutionArtefacts clean up job.'           
	INSERT dbo.[Jobs] ([Type], Recurrence, NextRun, IsActive)
	SELECT 'ScheduleExecutionArtefactsCleanUp', 10080, GETDATE(), 1
	PRINT '**** R65366 Added ScheduleExecutionArtefactsCleanUp.'           
END
