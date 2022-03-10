declare @now datetime
set @now = getdate()

update SE
	set SE.Finished = @now,
		SE.UpdatedOn = @now,
		SE.[Status] = 4, /* Cancelled */
		SE.IsTidiedUp = 1 /* do not delete this folder */
from	ScheduleExecutions SE
join	Schedules S on (S.Id = SE.ScheduleId 
					and S.DataSourceType = 0 
					and S.ExtendedSettings like '%"CertificateId":%')
where	SE.Finished is null 
	and SE.[Status] in (0, 3) /* Started and Cancelling */

update	Schedules
set		ExpiresAfter = @now,
		[STATE] = 1, /* expired */
		NextRun = NULL,
		[Name] = '[OBSOLETE] ' + [Name]
where	DataSourceType = 0  
and		IsDeleted <> 1 
/* schedule is one that contains the old settings */
and		ExtendedSettings like '%"CertificateId":%'
/* schedule is active, purgatory or run-now which hasn't got next run, or next run is in the future */
and		(NEXTRUN is null or NEXTRUN > @now or [STATE] IN (0,2,3)) 
and		[Name] not like '%OBSOLETE%'

update	Schedules
set		[Name] = '[OBSOLETE] ' + [Name]
where	DataSourceType = 0  
and		IsDeleted <> 1 
/* schedule is one that contains the old settings */
and		ExtendedSettings like '%"CertificateId":%'
and		[Name] not like '%OBSOLETE%'

/* delete DependableJobs that has a jobroot indicating it is a Private Pair schedule */
delete D
from DependableJobs D
join (
		select distinct RootId as 'JobRoot'
		from DependableJobs
				where [Type] like 'Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities%' 
					and Method in ('ScheduleByCustomer', 'Execute')
					and CreatedOn <= @now
	) as PrivatePairJobs
		on (D.RootId = PrivatePairJobs.JobRoot)

go