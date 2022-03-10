IF NOT EXISTS(SELECT * FROM dbo.[Jobs] WHERE [Type] = 'PctCasesCleanUp')
BEGIN
	PRINT '**** R48995 Adding Pct Cases Clean up job.'           
	INSERT dbo.[Jobs] ([Type], Recurrence, NextRun, IsActive)
	SELECT 'PctCasesCleanUp', 0, getdate(), 1
	PRINT '**** R48995 Added Pct Cases Clean up job.'           
END
ELSE
BEGIN
	PRINT '**** R48995 Pct Cases Clean up job already exists'
	PRINT ''
END
GO
