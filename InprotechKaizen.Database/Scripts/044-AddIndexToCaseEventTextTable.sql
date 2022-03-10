if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'CASEEVENTTEXT' and CONSTRAINT_NAME = 'XPKCASEEVENTTEXT')
begin
	PRINT 'Dropping primary key constraint CASEEVENTTEXT.XPKCASEEVENTTEXT...'
	ALTER TABLE CASEEVENTTEXT DROP CONSTRAINT XPKCASEEVENTTEXT
end
	PRINT 'Adding primary key constraint CASEEVENTTEXT.XPKCASEEVENTTEXT...'             
	ALTER TABLE dbo.CASEEVENTTEXT
	WITH NOCHECK ADD CONSTRAINT  XPKCASEEVENTTEXT PRIMARY KEY   NONCLUSTERED (CASEID  ASC,EVENTNO  ASC,CYCLE  ASC,EVENTTEXTID  ASC)
                        
go

if exists (select * from sysindexes where name = 'XAK1CASEEVENTTEXT')
begin
	PRINT 'Dropping index CASEEVENTTEXT.XAK1CASEEVENTTEXT ...'
	DROP INDEX CASEEVENTTEXT.XAK1CASEEVENTTEXT
end
	PRINT 'Creating index CASEEVENTTEXT.XAK1CASEEVENTTEXT ...'
	CREATE  UNIQUE INDEX XAK1CASEEVENTTEXT ON CASEEVENTTEXT
	(
	EVENTTEXTID  ASC
	)
go