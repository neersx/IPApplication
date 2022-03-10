If not exists(select * from Jobs where [Type] = 'ServerAnalyticsJob')
begin
	insert Jobs ([Type], Recurrence, NextRun, IsActive)
	select 'ServerAnalyticsJob', 10080, getdate(), 0
end
Go