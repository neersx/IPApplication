IF NOT EXISTS(SELECT * FROM dbo.[Jobs] WHERE [Type] = 'InnographyIds')
BEGIN
	INSERT dbo.[Jobs] ([Type], Recurrence, NextRun, IsActive)
	SELECT 'InnographyIds', 1440, dateadd(day, 1, CONVERT(date, getdate())), 1	
END
GO
