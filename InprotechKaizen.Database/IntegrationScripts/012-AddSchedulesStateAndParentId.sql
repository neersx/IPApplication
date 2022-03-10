	If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Schedules' AND COLUMN_NAME = 'State')
	BEGIN   
		PRINT '**** R37817 Adding column Schedules.State.'           
		ALTER TABLE Schedules ADD [State] int default 0
		PRINT '**** R37817 Schedules.State column has been added.'
	END
	ELSE
	BEGIN
		PRINT '**** R37817 Schedules.State already exists'
		PRINT ''
	END
	go


	If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Schedules' AND COLUMN_NAME = 'Parent_Id')
	BEGIN   
		PRINT '**** R37817 Adding column Schedules.Parent_Id.'           
		ALTER TABLE Schedules ADD Parent_Id int NULL
		PRINT '**** R37817 Schedules.Parent_Id column has been added.'
	END
	ELSE
	BEGIN
		PRINT '**** R37817 Schedules.Parent_Id already exists'
		PRINT ''
	END
	go

	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'Schedules' and CONSTRAINT_NAME = 'FK_dbo.Schedules_Id_dbo.Schedules_Parent_Id')
	begin
		PRINT '**** R37817 Dropping foreign key constraint Schedules.[FK_dbo.Schedules_Id_dbo.Schedules_Parent_Id]...'
		ALTER TABLE Schedules DROP CONSTRAINT [FK_dbo.Schedules_Id_dbo.Schedules_Parent_Id]
	end
	go

	PRINT '**** R37817 Adding foreign key constraint Schedules.[FK_dbo.Schedules_Id_dbo.Schedules_Parent_Id]...'
	ALTER TABLE dbo.Schedules
	WITH NOCHECK ADD CONSTRAINT [FK_dbo.Schedules_Id_dbo.Schedules_Parent_Id] FOREIGN KEY (Parent_Id) REFERENCES dbo.Schedules(Id)
	NOT FOR REPLICATION
	go

	if exists (select * from Schedules where [State] is null)
	Begin
		PRINT '**** R37817 Initialising Schedule States...'
		declare @dtToday datetime
		set @dtToday = DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))

		update Schedules set [State] = 1 where IsDeleted = 1
		update Schedules set [State] = 1 where NextRun is null and ExpiresAfter is not null and @dtToday > DATEADD(dd, 0, DATEDIFF(dd, 0, ExpiresAfter))
		update Schedules set [State] = 2 where NextRun is null and ExpiresAfter is not null and @dtToday < DATEADD(dd, 0, DATEDIFF(dd, 0, ExpiresAfter))
		update Schedules set [State] = 0 where [State] is null
		PRINT '**** R37817 Schedule States initialised.'
	End
	Else
	Begin
		PRINT '**** R37817 Schedule States already initialised.'
	End
	go