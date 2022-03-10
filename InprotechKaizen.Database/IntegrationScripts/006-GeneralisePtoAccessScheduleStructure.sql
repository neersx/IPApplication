If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Schedules' AND COLUMN_NAME = 'DataSourceType')
	BEGIN		 
		ALTER TABLE [dbo].[Schedules] ADD [DataSourceType] int not null default 0
	END
go

If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Schedules' AND COLUMN_NAME = 'ExtendedSettings')
	BEGIN		 
		ALTER TABLE [dbo].[Schedules] ADD [ExtendedSettings] nvarchar(max) null
 	END
go

If exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Schedules' AND COLUMN_NAME = 'CustomerNumbers')
	BEGIN		 
		Update S
		Set [ExtendedSettings] = '{
			"CustomerNumbers": "' + S.CustomerNumbers + '",
			"CertificateId": ' + cast(CertificateId as nvarchar) + ',
			"CertificateName": "' + replace(C.Name,'"', '\"') + '",
			"DaysWithinLast": ' + cast(DaysWithinLast as nvarchar) + ',
			"UnviewedOnly": ' + case when UnviewedOnly = 1 then 'true' when UnviewedOnly = 0 then 'false' else 'null' end +' }'
		from Schedules S
		join Certificates C on (C.Id = S.CertificateId)
		where DataSourceType = 0
 	END
go

If exists (select * from sysindexes where name = 'IX_CertificateId')
	BEGIN
		DROP INDEX Schedules.IX_CertificateId
	END
go

If exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'Schedules' and CONSTRAINT_NAME = 'FK_dbo.Schedules_dbo.Certificates_CertificateId')
	BEGIN
		ALTER TABLE [dbo].[Schedules] DROP CONSTRAINT [FK_dbo.Schedules_dbo.Certificates_CertificateId]
	END
go

If exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Schedules' AND COLUMN_NAME = 'CustomerNumbers')
	BEGIN		 
		ALTER TABLE [dbo].[Schedules] DROP COLUMN [CustomerNumbers]
	END
go

If exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Schedules' AND COLUMN_NAME = 'CertificateId')
	BEGIN		 
		ALTER TABLE [dbo].[Schedules] DROP COLUMN [CertificateId]
	END
go

If exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Schedules' AND COLUMN_NAME = 'DaysWithinLast')
	BEGIN		 
		ALTER TABLE [dbo].[Schedules] DROP COLUMN [DaysWithinLast]
	END
go

If exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Schedules' AND COLUMN_NAME = 'UnviewedOnly')
	BEGIN		 
		ALTER TABLE [dbo].[Schedules] DROP COLUMN [UnviewedOnly]
	END
go


