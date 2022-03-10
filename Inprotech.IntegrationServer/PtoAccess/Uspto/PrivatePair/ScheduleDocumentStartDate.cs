using System;
using System.Linq;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Schedules.Extensions.Uspto.PrivatePair;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public interface IScheduleDocumentStartDate
    {
        DateTime Resolve(Session session);
    }

    public class ScheduleDocumentStartDate : IScheduleDocumentStartDate
    {
        readonly IRepository _repository;
        readonly Func<DateTime> _now;

        public ScheduleDocumentStartDate(IRepository repository, Func<DateTime> now)
        {
            _repository = repository;
            _now = now;
        }

        public DateTime Resolve(Session session)
        {
            if (session == null) throw new ArgumentNullException(nameof(session));

            var schedule = _repository.Set<Schedule>()
                                      .Single(_ => _.Id == session.ScheduleId);

            schedule = schedule.Parent ?? schedule;

            var firstExecution = schedule.Executions.Any()
                ? schedule.Executions.Min(_ => _.Started)
                : _now();

            var privatePairSchedule = schedule.GetExtendedSettings<PrivatePairSchedule>();

            return firstExecution.AddDays(-1*(privatePairSchedule.DaysWithinLast ?? 0)).Date;
        }
    }
}