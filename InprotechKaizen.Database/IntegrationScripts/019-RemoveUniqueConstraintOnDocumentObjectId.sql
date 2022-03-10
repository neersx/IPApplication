IF exists (SELECT * FROM sysindexes WHERE name = 'IX_Source_DocumentObjectId')
	BEGIN
		PRINT 'Dropping index Documents.IX_Source_DocumentObjectId ...'
		DROP INDEX Documents.IX_Source_DocumentObjectId
	END
go