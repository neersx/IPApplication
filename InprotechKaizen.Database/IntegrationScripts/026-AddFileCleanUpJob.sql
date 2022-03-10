IF NOT EXISTS(SELECT * FROM dbo.[Jobs] WHERE [Type] = 'FileCleanUp')
BEGIN
	PRINT '**** R47710 Adding file cleanup job.'           
	INSERT dbo.[Jobs] ([Type], Recurrence, NextRun, IsActive)
	SELECT 'FileCleanUp', 5, getdate(), 1
	PRINT '**** R47710 Added file cleanup job.'           
END
ELSE
BEGIN
	PRINT '**** R47710 File cleanup job already exists'
	PRINT ''
END
GO

