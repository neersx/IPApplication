using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;

namespace Inprotech.IntegrationServer.PtoAccess.CleanUp
{
    public class ScheduleExecutionStatusUpdater : IUpdateScheduleExecutionStatus
    {
        readonly IRepository _repository;

        public ScheduleExecutionStatusUpdater(IRepository repository)
        {
            _repository = repository;
        }

        public Task SetToTidiedUp(Guid sessionGuid)
        {
            var scheduleExection = _repository.Set<ScheduleExecution>()
                .Include(se => se.Schedule)
                .Single(se => se.SessionGuid == sessionGuid);

            scheduleExection.IsTidiedUp = true;
            _repository.SaveChanges();

            return Task.FromResult(0);
        }
    }
}