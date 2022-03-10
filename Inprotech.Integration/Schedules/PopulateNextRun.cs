using System;
using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Integration.Schedules
{
    public interface IPopulateNextRun
    {
        void For(Schedule schedule);
    }

    public class PopulateNextRun : IPopulateNextRun
    {
        readonly Func<DateTime> _now;

        public PopulateNextRun(Func<DateTime> now)
        {
            if (now == null) throw new ArgumentNullException("now");
            _now = now;
        }

        public void For(Schedule schedule)
        {
            if (schedule == null) throw new ArgumentNullException("schedule");
            if (schedule.IsDeleted)
                throw new InvalidOperationException("deleted schedules need not have a next run date.");

            if (schedule.IsRunOnce())
            {
                schedule.NextRun = null;
                return;
            }

            var candidates = RunDaysFor(schedule).ToArray();

            var nextRun = schedule.LastRunStartOn == null
                ? candidates.First()
                : candidates.First(s => s > schedule.LastRunStartOn);

            if (schedule.ExpiresAfter != null && Nullable.Compare(nextRun.Date, schedule.ExpiresAfter) > 0)
                schedule.NextRun = null;
            else
                schedule.NextRun = nextRun;
        }

        IEnumerable<DateTime> RunDaysFor(Schedule schedule)
        {
            var startDate = schedule.LastRunStartOn ?? _now();
            var endDate = _now().AddDays(14);
            var currentDate = startDate;
            var scheduledDays = schedule.GetRunDaysOfWeek().ToArray();

            while (currentDate.Date != endDate.Date)
            {
                if (scheduledDays.Contains(currentDate.DayOfWeek))
                    yield return currentDate.Date + schedule.StartTime;

                currentDate = currentDate.AddDays(1);
            }
        }
    }
}