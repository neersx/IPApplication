If not exists(select * from Jobs where Type = 'InvalidationOfTsdrItems')
begin

	/* stopper job */
	insert Jobs (Type, Recurrence, NextRun, IsActive)
	values ('InvalidationOfTsdrItems', 0, '20160421', 0)

	declare @fixTable 
	table
	(
		CaseId int not null
	)

	/* any TSDR cases updated since that date would potentially have an empty cpaxml file. */
	insert @fixTable(CaseId)
	select Id
	from Cases
	where UpdatedOn > '20160421' 
	and Source = 1

	if exists (select * from @fixTable) 
	begin
		update	C
		set 	Version = null, 
				UpdatedOn = '20160421'
		from Cases C
		join @fixTable f on C.Id = f.CaseId

		/* Invalidate those TSDR cases. */
		update	CN
		set		CN.Type = 1,
				CN.Body = 
		N'
		[
		  {
			"type": "Error",
			"category": "Error",
			"activityType": "Data Correction Required",
			"message": "On April 22, 2016, Trademark Status and Document Retrieval (TSDR) has updated its XML schema use from version ST-96 1_D3 to version ST-96 2.2.1. Consequently, this item is being invalidated for re-retrieval.",
			"data": {},
			"exceptionType": "Forced invalidation of TSDR items",
			"exceptionDetails": [
			  {
				"type": "Forced invalidation of TSDR items",
				"message": "Forced invalidation of TSDR items",
				"details": "On April 22, 2016, Trademark Status and Document Retrieval (TSDR) has updated its XML schema use from version ST-96 1_D3 to version ST-96 2.2.1. Consequently, this item is being invalidated for re-retrieval."
			  }
			],
			"dispatchCycle": 0,
			"date": "2016-04-21T00:00:00.000000"
		  }
		]'
		from CaseNotifications CN
		join @fixTable f on (CN.CaseId = f.CaseId)

		/* Build a recovery schedule, with an expired parent schedule. */
		declare @invalidatedCases nvarchar(max) = ''
		select @invalidatedCases = @invalidatedCases + case when @invalidatedCases = '' then '' else ',' end + cast(CaseId as nvarchar(12)) 
		from @fixTable

		declare @tempStorageId bigint
		declare @identityId int

		insert TempStorage(Data)
		values ('{"CaseIds":[' + @invalidatedCases + ']}')
		set @tempStorageId = scope_identity()
		
		/* The identity of this system recovery module should not matter, but find it from existing schedule anyway. */
		select top 1 @identityId = CreatedBy
		from Schedules S
		join ScheduleExecutions SE on SE.ScheduleId = S.Id or SE.ScheduleId = S.Parent_Id
		join ScheduleExecutionArtifacts SEA on SEA.ScheduleExecutionId = SE.Id
		join @fixTable f on SEA.CaseId = f.CaseId

		declare @extendedSettings nvarchar(max)
		set @extendedSettings = '{"SavedQueryId":0,"SavedQueryName":"system generated","RunAsUserId":0,"RunAsUserName":"system","TempStorageId":' + cast(@tempStorageId as nvarchar(12)) + '}'
		
		insert Schedules (Name, DataSourceType, DownloadType, StartTime, CreatedOn, CreatedBy, IsDeleted, LastRunStartOn, ExpiresAfter, State, Type, ExtendedSettings)
		values ('SYSTEM: Responding to USPTO/TSDR Schema change (April 2016)', 1, 0, '00:00:00', getdate(), isnull(@identityId,-1), 0, getdate(), getdate(), 1, 1, @extendedSettings)

		insert Schedules (Name, DataSourceType, DownloadType, StartTime, CreatedOn, CreatedBy, IsDeleted, LastRunStartOn, ExpiresAfter, State, Type, ExtendedSettings, Parent_Id)
		values ('SYSTEM: Responding to USPTO/TSDR Schema change (April 2016)', 1, 0, '00:00:00', getdate(), isnull(@identityId,-1), 0, getdate(), getdate(), 3, 2, @extendedSettings, SCOPE_IDENTITY())

	end
End
go

