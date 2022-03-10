If not exists(select * from Jobs where [Type] = 'SendTsdrDocumentsToDms')
begin
	insert Jobs ([Type], Recurrence, NextRun, IsActive)
	select 'SendTsdrDocumentsToDms', 0, getdate(), 0
end
go

If not exists(select * from Jobs where [Type] = 'SendPrivatePairDocumentsToDms')
begin
	insert Jobs ([Type], Recurrence, NextRun, IsActive)
	select 'SendPrivatePairDocumentsToDms', 0, getdate(), 0
end
go

If not exists(select * from Jobs where [Type] = 'SendSelectedDocumentsToDms')
begin
	insert Jobs ([Type], Recurrence, NextRun, IsActive)
	select 'SendSelectedDocumentsToDms', 5, getdate(), 1
end
go
