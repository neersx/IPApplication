IF NOT EXISTS(SELECT * FROM dbo.[Jobs] WHERE [Type] = 'NotificationForInactiveInnographyLink')
BEGIN
	INSERT dbo.[Jobs] ([Type], Recurrence, NextRun, IsActive)
	SELECT 'NotificationForInactiveInnographyLink', 0, getdate(), 1	
END
GO
