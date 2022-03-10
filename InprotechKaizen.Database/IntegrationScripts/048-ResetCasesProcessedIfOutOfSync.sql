/* for all on-demand schedules or regular running schedules which has completed 
   if any schedule execution artifacts were recorded against them
   set associated CasesProcessed = number schedule execution artefacts that has a case id */

update SE
set CasesProcessed = SEA1.CasesActuallyProcessed
from ScheduleExecutions SE
join (
		select SEA.ScheduleExecutionId, count(SEA.CaseId) as CasesActuallyProcessed
		from ScheduleExecutions SE 
		join ScheduleExecutionArtifacts SEA on SEA.ScheduleExecutionId  = SE.Id and SEA.CaseId is not null
		where SE.Finished is not null
		and exists (
			select * 
			from Schedules S 
			where S.[Type] in (0,1) 
			and (SE.ScheduleId = S.Id or SE.ScheduleId = S.Parent_Id)
		)
		group by SEA.ScheduleExecutionId) SEA1 on (SE.Id = SEA1.ScheduleExecutionId)
where SE.CasesProcessed <> SEA1.CasesActuallyProcessed

go

