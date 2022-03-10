using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Analytics;

namespace Inprotech.Integration.GoogleAnalytics.EventProviders
{
    public class PriorArtSearchAnalyticsProvider : IAnalyticsEventProvider
    {
        readonly IServerTransactionDataQueue _serverTransactionDataQueue;

        public PriorArtSearchAnalyticsProvider(IServerTransactionDataQueue serverTransactionDataQueue)
        {
            _serverTransactionDataQueue = serverTransactionDataQueue;
        }

        public async Task<IEnumerable<AnalyticsEvent>> Provide(DateTime lastChecked)
        {
            var rawEventData = (await _serverTransactionDataQueue.Dequeue<RawEventData>(TransactionalEventTypes.PriorArtIdsPdf, TransactionalEventTypes.PriorArtIdsDocuments, TransactionalEventTypes.PriorArtSearch)
                ).ToArray();
            var map = new Dictionary<string, string>
            {
                {TransactionalEventTypes.PriorArtIdsPdf, AnalyticsEventCategories.StatisticsInnographyIdsPdf},
                {TransactionalEventTypes.PriorArtIdsDocuments, AnalyticsEventCategories.StatisticsInnographyIdsDocuments},
                {TransactionalEventTypes.PriorArtSearch, AnalyticsEventCategories.StatisticsInnographyIdsSearch}
            };
            return from r in rawEventData
                   group r by r.Value
                   into r1
                   select new AnalyticsEvent
                   {
                       Name = map[r1.Key],
                       Value = r1.Count().ToString()
                   };
        }
    }
}