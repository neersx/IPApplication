using System.Data.Entity;
using System.Linq;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.Schedules.Extensions
{
    public static class ScheduleExtensions
    {
        public static IQueryable<Schedule> SchedulesFor(this IQueryable<Schedule> schedules, DataSourceType dataSourceType)
        {
            return schedules.Where(s => s.DataSourceType == dataSourceType);
        }

        public static IQueryable<Schedule> WhereActive(this IDbSet<Schedule> schedules)
        {
            return schedules
                .WithoutDeleted()
                .Where(s => s.State != ScheduleState.Expired && s.State != ScheduleState.Disabled);
        }

        public static IQueryable<Schedule> WhereVisibleToUsers(this IDbSet<Schedule> schedules)
        {
            return schedules
                .WithoutDeleted()
                .Where(s => s.Parent == null);
        }
    }
}
