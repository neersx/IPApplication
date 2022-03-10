using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Analytics;

namespace Inprotech.Integration.GoogleAnalytics.EventProviders
{
    public class TaskPlannerAnalyticsProvider : IAnalyticsEventProvider
    {
        readonly IServerTransactionDataQueue _serverTransactionDataQueue;

        public TaskPlannerAnalyticsProvider(IServerTransactionDataQueue serverTransactionDataQueue)
        {
            _serverTransactionDataQueue = serverTransactionDataQueue;
        }

        public async Task<IEnumerable<AnalyticsEvent>> Provide(DateTime lastChecked)
        {
            var raw = await _serverTransactionDataQueue.Dequeue<TaskPlannerAnalytics>(TransactionalEventTypes.TaskPlannerAccessed);

            var taskPlannerAnalyticsEnumerable = raw as TaskPlannerAnalytics[] ?? raw.ToArray();
            var uniqueUsers = (from r in taskPlannerAnalyticsEnumerable
                               group r by r.UniqueId
                               into r1
                               select r1.Key
                ).Count();
            return new[]
            {
                new AnalyticsEvent
                {
                    Name = AnalyticsEventCategories.StatisticsTaskPlannerUsersPrefix,
                    Value = uniqueUsers.ToString()
                },
                new AnalyticsEvent
                {
                    Name = AnalyticsEventCategories.StatisticsTaskPlannerAccessedPrefix,
                    Value = taskPlannerAnalyticsEnumerable.Count().ToString()
                }
            };
        }

        internal class TaskPlannerAnalytics : RawEventData
        {
            public string UniqueId => Value;
        }
    }
}