IF NOT EXISTS(SELECT * FROM dbo.[Jobs] WHERE [Type] = 'DailySystemVerification')
BEGIN
	PRINT '**** R47710 Adding daily system verification job.'           
	INSERT dbo.[Jobs] ([Type], Recurrence, NextRun, IsActive)
	SELECT 'DailySystemVerification', 1440, CONVERT(DATE,GETDATE()), 1
	PRINT '**** R47710 Added daily system verification job.'           
END
ELSE
BEGIN
	PRINT '**** R47710 daily system verification job already exists'
	PRINT ''
END
GO

