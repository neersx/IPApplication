If not exists(select * from Jobs where [Type] = 'DequeueUsptoMessagesJob')
begin
	insert Jobs ([Type], Recurrence, NextRun, IsActive)
	select 'DequeueUsptoMessagesJob', 10, getdate(), 1
end
Go