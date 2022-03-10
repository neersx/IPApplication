IF NOT EXISTS(SELECT * FROM dbo.[Jobs] WHERE [Type] = 'LegacyFileCleanUp')
BEGIN
	PRINT '**** 47722 Adding legacy file clean up job.'           
	INSERT dbo.[Jobs] ([Type], Recurrence, NextRun, IsActive)
	SELECT 'LegacyFileCleanUp', 0, getdate(), 1
	PRINT '**** 47722 Added legacy file clean up job.'           
END
ELSE
BEGIN
	PRINT '**** 47722 Legacy file clean up job already exists'
	PRINT ''
END
GO