IF exists(SELECT * FROM dbo.[Jobs] WHERE [Type] = 'InnographyIds')
BEGIN
	delete from dbo.[Jobs] WHERE [Type] = 'InnographyIds'	
END
GO