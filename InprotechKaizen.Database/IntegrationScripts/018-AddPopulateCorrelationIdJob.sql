If not exists(select * from Jobs where [Type] = 'BackFillCorrelationId')
begin
	insert Jobs ([Type], Recurrence, NextRun, IsActive)
	select 'BackFillCorrelationId', 1, getdate(), 1
end
go