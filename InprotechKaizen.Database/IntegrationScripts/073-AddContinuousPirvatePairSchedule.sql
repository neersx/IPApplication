IF EXISTS (SELECT 1
FROM Schedules s
WHERE s.DataSourceType = 0 AND s.IsDeleted = 0 AND s.[Type] <> 3 AND s.Parent_Id IS NULL)
BEGIN
      BEGIN TRAN
      IF not EXISTS (SELECT 1
      from Schedules ss
      WHERE ss.[Type] = 3 AND ss.IsDeleted = 0)
      BEGIN
            INSERT INTO [dbo].[Schedules]
                  ([Name],[DownloadType],[RunOnDays],[StartTime],[CreatedOn],[CreatedBy],[IsDeleted]
                  ,[DeletedOn],[DeletedBy],[LastRunStartOn],[NextRun],[DataSourceType],[ExtendedSettings],[ExpiresAfter],[State],[Parent_Id],[Type])
            SELECT TOP 1
                  'USPTO Private PAIR Continuous', 0, null , '00:00:00', getdate(), [CreatedBy], 0
                        , null, null, null, null, 0, null, null, 0, null, 3
            from
            Schedules
            WHERE DataSourceType = 0 AND IsDeleted = 0 AND [Type] <> 3 AND Parent_Id is NULL
            order by Id desc
      END

      UPDATE Schedules SET [State] = 5, NextRun = NULL
      WHERE DataSourceType = 0 AND IsDeleted = 0 AND [Type] <> 3 AND Parent_Id is NULL

	  UPDATE Schedules SET [Name] = '[OBSOLETE] ' + [Name]
      WHERE DataSourceType = 0 AND IsDeleted = 0 AND [Type] <> 3 AND Parent_Id is NULL and [State] = 5 and [Name] not like '%OBSOLETE%'
      COMMIT TRAN
END