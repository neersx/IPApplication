using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Analytics;

namespace Inprotech.Integration.GoogleAnalytics.EventProviders
{
    class TimeRecordingAnalyticsProvider : IAnalyticsEventProvider
    {
        readonly IServerTransactionDataQueue _serverTransactionDataQueue;

        public TimeRecordingAnalyticsProvider(IServerTransactionDataQueue serverTransactionDataQueue)
        {
            _serverTransactionDataQueue = serverTransactionDataQueue;
        }

        public async Task<IEnumerable<AnalyticsEvent>> Provide(DateTime lastChecked)
        {
            var raw = await _serverTransactionDataQueue.Dequeue<TimeRecordingAnalytics>(TransactionalEventTypes.TimeRecordingAccessed);

            var timeRecordingUserAccess = raw as TimeRecordingAnalytics[] ?? raw.ToArray();
            var uniqueTimeRecordingUsers = (from r in timeRecordingUserAccess
                               group r by r.AnonymisedUserIdentifier
                               into r1
                               select r1.Key
                ).Count();
            return new[]
            {
                new AnalyticsEvent
                {
                    Name = AnalyticsEventCategories.StatisticsTimeRecordingUsersPrefix,
                    Value = uniqueTimeRecordingUsers.ToString()
                },
                new AnalyticsEvent
                {
                    Name = AnalyticsEventCategories.StatisticsTimeRecordingAccessedPrefix,
                    Value = timeRecordingUserAccess.Length.ToString()
                }
            };
        }

        internal class TimeRecordingAnalytics : RawEventData
        {
            public string AnonymisedUserIdentifier => Value;
        }
    }
}
