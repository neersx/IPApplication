/************** DR-78003 Add index ALERT.XAK1ALERT **************************/
if not exists (select *
from sysindexes
where name = 'XAK1ALERT')
begin
	PRINT 'Adding index ALERT.XAK1ALERT ...'
	PRINT ''
	CREATE UNIQUE NONCLUSTERED INDEX XAK1ALERT ON ALERT
( 
	ID ASC
)
end
else 
begin
	PRINT 'Index ALERT.XAK1ALERT already exists...'
	PRINT ''
end
go

/******* DR-78003 Add index EMPLOYEEREMINDER.XAK2EMPLOYEEREMINDER ***********/

if not exists (select *
from sysindexes
where name = 'XAK2EMPLOYEEREMINDER')
begin
	PRINT 'Adding index EMPLOYEEREMINDER.XAK2EMPLOYEEREMINDER ...'
	PRINT ''
	CREATE UNIQUE NONCLUSTERED INDEX XAK2EMPLOYEEREMINDER ON EMPLOYEEREMINDER
( 
	ID ASC
)
end
else 
begin
	PRINT 'Index EMPLOYEEREMINDER.XAK2EMPLOYEEREMINDER already exists...'
	PRINT ''
end
go