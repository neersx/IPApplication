using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Analytics;

namespace Inprotech.Integration.GoogleAnalytics.EventProviders
{
    public class InprodocGenerationAnalyticsProvider : IAnalyticsEventProvider
    {
        readonly IServerTransactionDataQueue _serverTransactionDataQueue;

        public InprodocGenerationAnalyticsProvider(IServerTransactionDataQueue serverTransactionDataQueue)
        {
            _serverTransactionDataQueue = serverTransactionDataQueue;
        }

        public async Task<IEnumerable<AnalyticsEvent>> Provide(DateTime lastChecked)
        {
            var raw = await _serverTransactionDataQueue.Dequeue<InprodocAnalytics>(TransactionalEventTypes.InprodocAdHocGeneration);

            var interim = from r in raw
                          group r by r.Version
                          into r1
                          select new Interim
                          {
                              Version = r1.Key,
                              Count = (from c in r1
                                       group c by c.SessionId
                                       into c1
                                       select c1.Key).Count()
                          };

            return from i in interim
                   select new AnalyticsEvent
                   {
                       Name = AnalyticsEventCategories.StatisticsAdHocDocGeneratedInprodocPrefix + " (" + i.Version + ")",
                       Value = i.Count.ToString()
                   };
        }

        class Interim
        {
            public string Version { get; set; }

            public long Count { get; set; }
        }

        internal class InprodocAnalytics : RawEventData
        {
            public string Version => Value.Split('^')[0];

            public string SessionId => Value.Split('^')[1];
        }
    }
}