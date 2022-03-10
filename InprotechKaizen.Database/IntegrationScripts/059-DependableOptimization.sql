IF EXISTS(SELECT * FROM sys.indexes WHERE OBJECTPROPERTY(object_id, 'IsUserTable') = 1  AND type_desc='CLUSTERED' AND OBJECT_NAME(object_id) = N'DependableJobs' AND is_primary_key=1)
    BEGIN
	   Declare @sql NVARCHAR(500);
	   SELECT @sql = 'ALTER TABLE [DependableJobs] DROP CONSTRAINT ' + QUOTENAME(name) + ';ALTER TABLE [DependableJobs] ADD CONSTRAINT ' + QUOTENAME(name) + ' PRIMARY KEY NONCLUSTERED (Id)' 
	   FROM sys.key_constraints WHERE [type] = 'PK' AND [parent_object_id] = OBJECT_ID('DependableJobs');

	   EXEC sp_executesql @sql;
	   print '**** Changing Primary Key of DependableJobs to NONCLUSTERED...'
    END
GO

IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = DB_NAME() AND recovery_model_desc = 'SIMPLE')
    BEGIN
        DECLARE @sql NVARCHAR(500)= N'ALTER DATABASE '+QUOTENAME(DB_NAME())+' SET RECOVERY SIMPLE WITH NO_WAIT;';
        EXEC sp_executesql @sql;
	    print '**** Recovery Mode of Integration DB changed to SIMPLE...'
    END;
GO