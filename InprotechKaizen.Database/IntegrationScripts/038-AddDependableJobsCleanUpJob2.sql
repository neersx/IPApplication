IF NOT EXISTS(SELECT * FROM dbo.[Jobs] WHERE [Type] = 'DependableJobsCleanUp')
BEGIN
	PRINT '**** R53531 Adding dependable jobs clean up job.'           
	INSERT dbo.[Jobs] ([Type], Recurrence, NextRun, IsActive)
	SELECT 'DependableJobsCleanUp', 20160, DATEADD(d,1,DATEDIFF(d,0,GETDATE())), 1
	PRINT '**** R53531 Added dependable jobs clean up job.'           
END
ELSE
BEGIN
	PRINT '**** R59831 Update Dependable jobs clean up job to longer recurrence schedule (fortnightly)'
	UPDATE dbo.[Jobs] SET Recurrence = 20160 WHERE [Type] = 'DependableJobsCleanUp'
	PRINT '**** R59831 Dependable jobs clean up is updated to fortnightly'
END
GO
