If not exists(select * from Jobs where [Type] = 'FindMissingDocumentsJob')
begin
	insert Jobs ([Type], Recurrence, NextRun, IsActive)
	select 'FindMissingDocumentsJob', 0, getdate(), 1
end
Go