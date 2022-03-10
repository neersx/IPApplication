using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Schedules.Extensions;
using Inprotech.IntegrationServer.BackgroundProcessing;

namespace Inprotech.IntegrationServer.Scheduling
{
    public class PendingScheduleInterrupter : IInterrupter
    {
        readonly IScheduleRunner _scheduleRunner;
        readonly IPopulateNextRun _populateNextRun;
        readonly IUpdateScheduleState _updateScheduleState;
        readonly Func<DateTime> _now;
        readonly IRepository _repository;

        public PendingScheduleInterrupter(
            IRepository repository,
            Func<DateTime> now,
            IScheduleRunner scheduleRunner, IPopulateNextRun populateNextRun,
            IUpdateScheduleState updateScheduleState)
        {
            _repository = repository;
            _now = now;
            _scheduleRunner = scheduleRunner;
            _populateNextRun = populateNextRun;
            _updateScheduleState = updateScheduleState;
        }

        public async Task Interrupt()
        {
            if (!_scheduleRunner.IsReady) return;

            var schedules = await _repository.Set<Schedule>().WhereActive().ToListAsync();
            var now = _now();

            foreach (var s in schedules.Where(s => ShouldExecute(now, s)))
            {
                s.LastRunStartOn = _now();
                _populateNextRun.For(s);
                _updateScheduleState.For(s);
                await _repository.SaveChangesAsync();

                if (s.State != ScheduleState.Expired)
                    _scheduleRunner.Run(s);
            }
        }

        static bool ShouldExecute(DateTime now, Schedule s)
        {
            return s.State != ScheduleState.Disabled && s.Type != ScheduleType.Continuous && (s.NextRun == null || now >= s.NextRun);
        }
    }
}