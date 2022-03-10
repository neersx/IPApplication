delete C
from Cases C
join (select Source, CorrelationId
			from Cases 
			where Source > 0
			group by Source, CorrelationId 
			having count(CorrelationId) > 1) as Duplicates on (C.Source = Duplicates.Source and C.CorrelationId = Duplicates.CorrelationId)
GO

delete C
from Cases C
join (select Source, ApplicationNumber
			from Cases 
			where Source = 0
			group by Source, ApplicationNumber 
			having count(ApplicationNumber) > 1) as Duplicates on (C.Source = Duplicates.Source and C.ApplicationNumber = Duplicates.ApplicationNumber)
GO

delete C
from Cases C
join (	select count(*) as [count], Source, ApplicationNumber, PublicationNumber, RegistrationNumber
		from Cases
		group by Source, ApplicationNumber, PublicationNumber, RegistrationNumber
		having count(*) > 1) as Duplicates on (
				(C.ApplicationNumber = Duplicates.ApplicationNumber or C.ApplicationNumber is null and Duplicates.ApplicationNumber is null)
			and (C.PublicationNumber = Duplicates.PublicationNumber or C.PublicationNumber is null and Duplicates.PublicationNumber is null)
			and (C.RegistrationNumber = Duplicates.RegistrationNumber or C.RegistrationNumber is null and Duplicates.RegistrationNumber is null)
			and C.Source = Duplicates.Source)
GO

IF NOT EXISTS (select * from sys.indexes where name = N'IX_OfficialNumbers_Type' AND object_id = object_id(N'[dbo].[Cases]', N'U'))
BEGIN
    CREATE UNIQUE INDEX [IX_OfficialNumbers_Type] ON [dbo].[Cases]([Source], [ApplicationNumber], [RegistrationNumber], [PublicationNumber])
END
GO
