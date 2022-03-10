/********* DR-77612 Add index CASEEVENT.XAK1CASEEVENT ********************/
if not exists (select * from sysindexes where name = 'XAK1CASEEVENT')
begin
	PRINT 'Adding index CASEEVENT.XAK1CASEEVENT ...'
	CREATE UNIQUE NONCLUSTERED INDEX XAK1CASEEVENT ON CASEEVENT
	( 
		ID ASC
	)
	PRINT 'Added index CASEEVENT.XAK1CASEEVENT ...'
end
else 
begin
	PRINT 'Index CASEEVENT.XAK1CASEEVENT already exists...'
end
go
