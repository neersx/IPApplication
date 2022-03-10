IF NOT EXISTS(SELECT * FROM dbo.[Jobs] WHERE [Type] = 'SchemaMappingTableCodesUpdate')
BEGIN
	PRINT '**** 45349 Adding SchemaMappingTableCodesUpdate job.'           
	INSERT dbo.[Jobs] ([Type], Recurrence, NextRun, IsActive)
	VALUES ('SchemaMappingTableCodesUpdate', 0, getdate(), 0)
	PRINT '**** 45349 Added SchemaMappingTableCodesUpdate job.'           
END
ELSE
BEGIN
	PRINT '**** 45349 SchemaMappingTableCodesUpdate job already exists'
	PRINT ''
END
GO