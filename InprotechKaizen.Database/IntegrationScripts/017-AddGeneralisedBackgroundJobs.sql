	If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Jobs')
		BEGIN
			CREATE TABLE dbo.Jobs
			 (
				Id  bigint IDENTITY (1,1)  NOT FOR REPLICATION,
				[Type] nvarchar(max) not null,
				Recurrence int not null,
				NextRun datetime not null,
				IsActive bit not null default 1
			 )
		END
	go 


	If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'JobExecutions')
		BEGIN
			CREATE TABLE dbo.JobExecutions
			 (
				Id  bigint IDENTITY (1,1)  NOT FOR REPLICATION,
				JobId bigint not null,
				[Status] int NULL,
				[Started] datetime not null,
				[Finished] datetime null,
				Error nvarchar(max) NULL
			 )
		END
	go 
	
	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'JobExecutions' and CONSTRAINT_NAME = 'XPKJobExecutions')
		begin
			ALTER TABLE JobExecutions DROP CONSTRAINT XPKJobExecutions
		end
	go

	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'JobExecutions' and CONSTRAINT_NAME = 'FK_JobExecutions_Jobs')
		begin
			PRINT 'Dropping foreign key constraint JobExecutions.FK_JobExecutions_Jobs...'
			ALTER TABLE JobExecutions DROP CONSTRAINT FK_JobExecutions_Jobs
		end
	go

	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'Jobs' and CONSTRAINT_NAME = 'XPKJobs')
		begin
			ALTER TABLE Jobs DROP CONSTRAINT XPKJobs
		end
	go

	ALTER TABLE dbo.Jobs
		 WITH NOCHECK ADD CONSTRAINT  XPKJobs PRIMARY KEY   NONCLUSTERED (Id  ASC)
	go

	ALTER TABLE dbo.JobExecutions
		 WITH NOCHECK ADD CONSTRAINT  XPKJobExecutions PRIMARY KEY   NONCLUSTERED (Id  ASC)
	go

	ALTER TABLE dbo.JobExecutions
		 WITH NOCHECK ADD CONSTRAINT  FK_JobExecutions_Jobs FOREIGN KEY (JobId) REFERENCES dbo.Jobs(Id)
			ON DELETE CASCADE
		 NOT FOR REPLICATION
	go

