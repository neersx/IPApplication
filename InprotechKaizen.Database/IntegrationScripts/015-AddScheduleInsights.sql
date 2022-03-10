	If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ScheduleExecutions')
		BEGIN
			CREATE TABLE dbo.ScheduleExecutions
			 (
				Id  bigint IDENTITY (1,1)  NOT FOR REPLICATION,
				ScheduleId int not null,
				SessionGuid [uniqueidentifier] NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
				CorrelationId nvarchar(max) NULL,
				[Started] datetime not null,
				[Finished] datetime null,
				CasesIncluded int null,
				CasesProcessed int null,
				DocumentsIncluded int null,
				DocumentsProcessed int null,
				UpdatedOn datetime not null,
				AdditionalData nvarchar(max) NULL
			 )
		END
	go 

	If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ScheduleRecoverables')
		BEGIN
			CREATE TABLE dbo.ScheduleRecoverables
			 (
				Id  bigint IDENTITY (1,1)  NOT FOR REPLICATION,
				ScheduleExecutionId bigint not null,
				CaseId int null,
				DocumentId int null,
				LastUpdated datetime not null
			 )
		END
	go 

	If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'UnrecoverableArtefacts')
		BEGIN
			CREATE TABLE dbo.UnrecoverableArtefacts
			 (
				Id  bigint IDENTITY (1,1)  NOT FOR REPLICATION,
				ScheduleExecutionId bigint not null,
				Artefact nvarchar(max) not null,
				LastUpdated datetime not null
			 )
		END
	go 
	 
	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'ScheduleRecoverables' and CONSTRAINT_NAME = 'FK_ScheduleRecoverables_ScheduleExecutions')
		begin
			PRINT 'Dropping foreign key constraint ScheduleRecoverables.FK_ScheduleRecoverables_ScheduleExecutions...'
			ALTER TABLE ScheduleRecoverables DROP CONSTRAINT FK_ScheduleRecoverables_ScheduleExecutions
		end
	go

	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'ScheduleRecoverables' and CONSTRAINT_NAME = 'FK_ScheduleRecoverables_Cases')
		begin
			PRINT 'Dropping foreign key constraint ScheduleRecoverables.FK_ScheduleRecoverables_Cases...'
			ALTER TABLE ScheduleRecoverables DROP CONSTRAINT FK_ScheduleRecoverables_Cases
		end
	go
		
	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'ScheduleRecoverables' and CONSTRAINT_NAME = 'FK_ScheduleRecoverables_Documents')
		begin
			PRINT 'Dropping foreign key constraint ScheduleRecoverables.FK_ScheduleRecoverables_Documents...'
			ALTER TABLE ScheduleRecoverables DROP CONSTRAINT FK_ScheduleRecoverables_Documents
		end
	go
	
	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'UnrecoverableArtefacts' and CONSTRAINT_NAME = 'FK_UnrecoverableArtefacts_ScheduleExecutions')
		begin
			PRINT 'Dropping foreign key constraint ScheduleRecoverables.FK_UnrecoverableArtefacts_ScheduleExecutions...'
			ALTER TABLE UnrecoverableArtefacts DROP CONSTRAINT FK_UnrecoverableArtefacts_ScheduleExecutions
		end
	go
	
	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'ScheduleExecutions' and CONSTRAINT_NAME = 'XPKScheduleExecutions')
		begin
			ALTER TABLE ScheduleExecutions DROP CONSTRAINT XPKScheduleExecutions
		end
	go

	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'ScheduleExecutions' and CONSTRAINT_NAME = 'FK_ScheduleExecutions_Schedules')
		begin
			PRINT 'Dropping foreign key constraint ScheduleExecutions.FK_ScheduleExecutions_Schedules...'
			ALTER TABLE ScheduleExecutions DROP CONSTRAINT FK_ScheduleExecutions_Schedules
		end
	go

	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'ScheduleRecoverables' and CONSTRAINT_NAME = 'XPKScheduleRecoverables')
		begin
			ALTER TABLE ScheduleRecoverables DROP CONSTRAINT XPKScheduleRecoverables
		end
	go

	ALTER TABLE dbo.ScheduleExecutions
		 WITH NOCHECK ADD CONSTRAINT  XPKScheduleExecutions PRIMARY KEY   NONCLUSTERED (Id  ASC)
	go

	ALTER TABLE dbo.ScheduleExecutions
		 WITH NOCHECK ADD CONSTRAINT  FK_ScheduleExecutions_Schedules FOREIGN KEY (ScheduleId) REFERENCES dbo.Schedules(Id)
			ON DELETE CASCADE
		 NOT FOR REPLICATION
	go

	ALTER TABLE dbo.ScheduleRecoverables
		 WITH NOCHECK ADD CONSTRAINT  XPKScheduleRecoverables PRIMARY KEY   NONCLUSTERED (Id  ASC)
	go

	ALTER TABLE dbo.ScheduleRecoverables
		 WITH NOCHECK ADD CONSTRAINT  FK_ScheduleRecoverables_ScheduleExecutions FOREIGN KEY (ScheduleExecutionId) REFERENCES dbo.ScheduleExecutions(Id)
			ON DELETE CASCADE
		 NOT FOR REPLICATION
	go
	
	ALTER TABLE dbo.ScheduleRecoverables
		 WITH NOCHECK ADD CONSTRAINT  FK_ScheduleRecoverables_Cases FOREIGN KEY (CaseId) REFERENCES dbo.Cases(Id)
			ON DELETE CASCADE
		 NOT FOR REPLICATION
	go

	ALTER TABLE dbo.ScheduleRecoverables
		 WITH NOCHECK ADD CONSTRAINT  FK_ScheduleRecoverables_Documents FOREIGN KEY (DocumentId) REFERENCES dbo.Documents(Id)
			ON DELETE CASCADE
		 NOT FOR REPLICATION
	go

	ALTER TABLE dbo.UnrecoverableArtefacts
		 WITH NOCHECK ADD CONSTRAINT  FK_UnrecoverableArtefacts_ScheduleExecutions FOREIGN KEY (ScheduleExecutionId) REFERENCES dbo.ScheduleExecutions(Id)
			ON DELETE CASCADE
		 NOT FOR REPLICATION
	go
