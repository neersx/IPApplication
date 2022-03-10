If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Schedules' AND COLUMN_NAME = 'NextRun')
	BEGIN		 
		ALTER TABLE Schedules ADD NextRun datetime
 	END
go

If exists(select * from sysobjects where id = object_id('dbo.fn_CalculateNextRun') and xtype='FN')
	BEGIN
		drop function dbo.fn_CalculateNextRun
	END
go

-- set this so the datepart(weekday) 
-- returns a deterministic value
set datefirst 1 -- Monday = 1
go

create function dbo.fn_CalculateNextRun(@pnScheduleId int)
returns datetime
as
begin
	
	declare @dtResult datetime

	declare @dtBaseDate datetime
	declare @dtStartDate datetime
	declare @dtEndDate datetime
	declare @dtStartTime datetime
	declare @dtLastRun datetime

	set @dtBaseDate = dateadd(dd, datediff(dd, 0, getdate()), 0)
	
	select @dtStartTime = convert(datetime, S.StartTime, 108),
		   @dtStartDate = @dtBaseDate + @dtStartTime,
		   @dtEndDate = dateadd(day, 14, @dtBaseDate) + @dtStartTime,
		   @dtLastRun = isnull(S.LastRunStartOn, @dtStartDate)
	from Schedules S
	where S.Id = @pnScheduleId
	and S.IsDeleted = 0

	;with Dates as (
     select @dtStartDate 'date'
     union all
     select dateadd(dd, 1, d.date) 
       from Dates d
      where dateadd(dd, 1, d.date) <= @dtEndDate)

	select top 1 @dtResult = d.date
	  from Dates d
	  left join Schedules S on (S.Id = @pnScheduleId)
	  where (	
		(DATEPART(weekday, d.date) = 1 and PatIndex('%Mon%', S.RunOnDays collate database_default) <> 0) or
		(DATEPART(weekday, d.date) = 2 and PatIndex('%Tue%', S.RunOnDays collate database_default) <> 0) or
		(DATEPART(weekday, d.date) = 3 and PatIndex('%Wed%', S.RunOnDays collate database_default) <> 0) or
		(DATEPART(weekday, d.date) = 4 and PatIndex('%Thu%', S.RunOnDays collate database_default) <> 0) or
		(DATEPART(weekday, d.date) = 5 and PatIndex('%Fri%', S.RunOnDays collate database_default) <> 0) or
		(DATEPART(weekday, d.date) = 6 and PatIndex('%Sat%', S.RunOnDays collate database_default) <> 0) or
		(DATEPART(weekday, d.date) = 7 and PatIndex('%Sun%', S.RunOnDays collate database_default) <> 0)
	  ) and d.date >= @dtLastRun

	return @dtResult
end
go

If exists(select * from sysobjects where id = object_id('dbo.fn_CalculateNextRun') and xtype='FN')
begin

	update Schedules
		set NextRun = dbo.fn_CalculateNextRun(Schedules.Id)
		from Schedules 
		where Schedules.IsDeleted = 0 and Schedules.NextRun is null

	drop function dbo.fn_CalculateNextRun

end
go
